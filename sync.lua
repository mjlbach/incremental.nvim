local M = {}

---@private
-- Given a line, byte idx, and offset_encoding convert to the
-- utf-8, utf-16, or utf-32 index.
function M.convert_byte_to_utf(line, idx, offset_encoding)
  -- convert to 0 based indexing
  idx = idx - 1

  local utf_idx
  local _
  -- Convert the byte range to utf-{8,16,32} and convert 1-based (lua) indexing to 0-based
  if offset_encoding == 'utf-16' then
    _, utf_idx = vim.str_utfindex(line, idx)
  elseif offset_encoding == 'utf-32' then
    utf_idx, _ = vim.str_utfindex(line, idx)
  else
    utf_idx = idx
  end

  -- convert to 1 based indexing
  return utf_idx + 1
end

---@private
-- Given a line, byte idx, alignment, and offset_encoding convert to the
-- utf-8 index and either the utf-16, or utf-32 index.
---@param line string
---@param byte integer
---@param align string
---@param offset_encoding string utf-8|utf-16|utf-32|nil (fallback to utf-8)
---@returns table<int, int> line_idx, byte_idx, and char_idx of first change position
function M.byte_to_codepoint(line, byte, align, offset_encoding)
  local char
  -- Set the byte range to start at the last codepoint
  if byte == 1 or #line == 0 then
    -- if start_byte is first byte, or the length of the string is 0, we are done
    char = byte
  elseif byte == #line + 1 then
    -- If extending the line, the range will be the length of the last line + 1 and fall on a codepoint
    byte = byte
    -- Extending line, find the nearest utf codepoint for the last valid character then add 1
    char = M.convert_byte_to_utf(line, #line, offset_encoding) + 1
  else
    -- Modifying line, find the nearest utf codepoint
    if align == 'start' then
      byte = byte + vim.str_utf_start(line, byte)
      char = M.convert_byte_to_utf(line, byte, offset_encoding)
    elseif align == 'end' then
      local offset = vim.str_utf_end(line, byte)
      if offset > 0 then
        char = M.convert_byte_to_utf(line, byte, offset_encoding) + 1
        byte = byte + offset
      else
        char = M.convert_byte_to_utf(line, byte, offset_encoding)
        byte = byte + offset
      end
    else
      assert(false, '`align` must be start or end.')
    end
    -- Extending line, find the nearest utf codepoint for the last valid character
  end
  return byte, char
end

-- Generic warnings about byte level changes in neovim
-- This handles whole line operations (line wiped or added)
-- Join operation (2 op): extends line 1 with the contents of line 2, delete line 2
-- lastline = 3
-- test 1    test 1 test 2    test 1 test 2
-- test 2 -> test 2        -> test 3
-- test 3    test 3
--
-- Deleting (and undoing) two middle lines (1 op)
-- test 1    test 1
-- test 2 -> test 4
-- test 3
-- test 4
--
-- Delete between asterisks (5 op)
-- test *1   test *    test *     test *    test *4    test *4*
-- test 2 -> test 2 -> test *4 -> *4     -> *4      ->
-- test 3    test 3
-- test *4   test 4

---@private
--- Finds the first line, byte, and char index of the difference between the previous and current lines buffer normalized to the previous codepoint.
---@param prev_lines table list of lines from previous buffer
---@param curr_lines table list of lines from current buffer
---@param firstline integer firstline from on_lines, adjusted to 1-index
---@param lastline integer lastline from on_lines, adjusted to 1-index
---@param new_lastline integer new_lastline from on_lines, adjusted to 1-index
---@param offset_encoding string utf-8|utf-16|utf-32|nil (fallback to utf-8)
---@returns table<int, int> line_idx, byte_idx, and char_idx of first change position
function M.compute_start_range(prev_lines, curr_lines, firstline, lastline, new_lastline, offset_encoding)
  -- If firstline == lastline, no existing text is changed. All edit operations
  -- occur on a new line pointed to by lastline. This occurs during insertion of
  -- new lines(O), the new newline is inserted at the line indicated by
  -- new_lastline.
  -- If firstline == new_lastline, the first change occured on a line that was deleted.
  -- In this case, the first byte change is also at the first byte of firstline
  if firstline == new_lastline or firstline == lastline then
    return { line_idx = firstline, byte_idx = 1, char_idx = 1 }
  end

  local prev_line = prev_lines[firstline]
  local curr_line = curr_lines[firstline]

  -- Iterate across previous and current line containing first change
  -- to find the first different byte. Note:
  -- *about -> a*about will register the second a as the first difference,
  -- regardless of edit since we can't distinguish the first column of
  -- the edit from on_lines
  local start_byte_idx = 1
  for idx = 1, #prev_line + 1 do
    start_byte_idx = idx
    if string.byte(prev_line, idx) ~= string.byte(curr_line, idx) then
      break
    end
  end

  -- Convert byte to codepoint if applicable
  local byte_idx, char_idx = M.byte_to_codepoint(prev_line, start_byte_idx, 'start', offset_encoding)

  -- Return the start difference (shared for new and prev lines)
  return { line_idx = firstline, byte_idx = byte_idx, char_idx = char_idx }
end

---@private
--- Finds the last line and byte index of the differences between prev and new lines>
--- Normalized to the next codepoint.
---@param prev_lines table list of lines
---@param curr_lines table list of lines
---@param start_range table
---@param lastline integer
---@param new_lastline integer
---@param offset_encoding string
---@returns (int, int) end_line_idx and end_col_idx of range
function M.compute_end_range(prev_lines, curr_lines, start_range, lastline, new_lastline, offset_encoding)
  -- Compare on last line, at minimum will be the start range
  local start_line_idx = start_range.line_idx

  -- lastline and new_lastline were last lines that were *not* replaced, compare previous lines
  local prev_line_idx = lastline - 1
  local curr_line_idx = new_lastline - 1

  local prev_line = prev_lines[lastline - 1]
  local curr_line = curr_lines[new_lastline - 1]

  local prev_line_length = #prev_line
  local curr_line_length = #curr_line
  print(vim.inspect {
    prev_line = prev_line,
    prev_line_idx = prev_line_idx,
    curr_line = curr_line,
    curr_line_idx = curr_line_idx,
    start_range = start_range,
  })

  local byte_offset = 0
  -- Buffer has increased in line count
  -- if new_lastline > lastline then
  -- -- Buffer has decreased in line count
  -- elseif new_lastline < lastline then
  -- elseif
  -- end
  -- Editing the same line
  -- If the byte offset is zero, that means there is a difference on the last byte (not newline)
  if prev_line_idx == curr_line_idx then
    local max_length
    if start_line_idx == prev_line_idx then
      -- Search until beginning of difference
      max_length = math.min(prev_line_length - start_range.byte_idx, curr_line_length - start_range.byte_idx)
    else
      max_length = math.min(prev_line_length, curr_line_length) + 1
    end
    for idx = 0, max_length do
      byte_offset = idx
      if
        string.byte(prev_line, prev_line_length - byte_offset) ~= string.byte(curr_line, curr_line_length - byte_offset)
      then
        break
      end
    end
  end

  -- Iterate from end to beginning of shortest line
  local prev_end_byte_idx = prev_line_length - byte_offset + 1
  local prev_byte_idx, prev_char_idx = M.byte_to_codepoint(prev_line, prev_end_byte_idx, 'end', offset_encoding)
  local prev_end_range = { line_idx = prev_line_idx, byte_idx = prev_byte_idx, char_idx = prev_char_idx }

  local curr_end_range
  -- Deletion event, new_range cannot be before start
  if curr_line_idx < start_line_idx then
    curr_end_range = { line_idx = start_line_idx, byte_idx = 1, char_idx = 1 }
  else
    local curr_end_byte_idx = curr_line_length - byte_offset + 1
    local curr_byte_idx, curr_char_idx = M.byte_to_codepoint(curr_line, curr_end_byte_idx, 'end', offset_encoding)
    curr_end_range = { line_idx = curr_line_idx, byte_idx = curr_byte_idx, char_idx = curr_char_idx }
  end

  return prev_end_range, curr_end_range
end

---@private
--- Get the text of the range defined by start and end line/column
---@param lines table list of lines
---@param start_range table table returned by first_difference
---@param end_range table new_end_range returned by last_difference
---@returns string text extracted from defined region
function M.extract_text(lines, start_range, end_range, line_ending)
  -- Add the fragment of the first line
  if start_range.line_idx == end_range.line_idx then
    return string.sub(lines[start_range.line_idx], start_range.byte_idx, end_range.byte_idx - 1)
  else
    local result = { string.sub(lines[start_range.line_idx], start_range.byte_idx) }
    -- print(vim.inspect(result))

    -- The first and last range of the line idx may be partial lines
    for idx = start_range.line_idx + 1, end_range.line_idx - 1 do
      table.insert(result, lines[idx])
    end

    -- TODO: Join all lines with newline (should read from whatever the encoding is in the file)
    result = table.concat(result, line_ending) .. line_ending

    -- Add the fragment of the last line
    local line = lines[end_range.line_idx]
    if end_range.byte_idx > 1 then
      result = result .. string.sub(line, 1, end_range.byte_idx)
    end

    return result
  end
end

---@private
function M.compute_range_length(lines, start_range, end_range, offset_encoding)
  -- Single line case
  if start_range.line_idx == end_range.line_idx then
    return start_range.char_idx - end_range.char_idx
  end

  local start_line = lines[start_range.line_idx]
  local range_length
  if #start_line > 0 then
    range_length = M.convert_byte_to_utf(start_line, #start_line, offset_encoding) - start_range.char_idx + 1
  else
    -- Length of newline character
    range_length = 1
  end

  -- The first and last range of the line idx may be partial lines
  for idx = start_range.line_idx + 1, end_range.line_idx - 1 do
    -- Length full line plus newline character
    range_length = range_length + M.convert_byte_to_utf(lines[idx], #lines[idx], offset_encoding) + 1
  end

  local end_line = lines[end_range.line_idx]
  if #end_line > 0 then
    range_length = range_length + M.convert_byte_to_utf(end_line, #end_line, offset_encoding) - end_range.char_idx
  end

  return range_length
end

--- Returns the range table for the difference between prev and curr lines
---@param prev_lines table list of lines
---@param curr_lines table list of lines
---@param firstline number line to begin search for first difference
---@param lastline number line to begin search in old_lines for last difference
---@param new_lastline number line to begin search in new_lines for last difference
---@param offset_encoding string encoding requested by language server
---@returns table TextDocumentContentChangeEvent see https://microsoft.github.io/language-server-protocol/specifications/specification-3-17/#textDocumentContentChangeEvent
function M.compute_diff(prev_lines, curr_lines, firstline, lastline, new_lastline, offset_encoding, line_ending)
  -- Find the start of changes between the previous and current buffer. Common between both.
  -- Sent to the server as the start of the changed range.
  -- Used to grab the changed text from the latest buffer.
  local start_range = M.compute_start_range(
    prev_lines,
    curr_lines,
    firstline + 1,
    lastline + 1,
    new_lastline + 1,
    offset_encoding
  )
  -- Find the last position changed in the previous and current buffer.
  -- prev_end_range is sent to the server as as the end of the changed range.
  -- curr_end_range is used to grab the changed text from the latest buffer.
  local prev_end_range, curr_end_range = M.compute_end_range(
    prev_lines,
    curr_lines,
    start_range,
    lastline + 1,
    new_lastline + 1,
    offset_encoding
  )

  -- Grab the changed text of from start_range to curr_end_range in the current buffer.
  -- The text range is "" if entire range is deleted.
  local text = M.extract_text(curr_lines, start_range, curr_end_range, line_ending)

  -- Compute the range of the replaced text. Deprecated but still required for certain language servers
  local range_length = M.compute_range_length(prev_lines, start_range, prev_end_range, offset_encoding)

  -- convert to 0 based indexing
  local result = {
    range = {
      ['start'] = { line = start_range.line_idx - 1, character = start_range.char_idx - 1 },
      ['end'] = { line = prev_end_range.line_idx - 1, character = prev_end_range.char_idx - 1 },
    },
    text = text,
    rangeLength = range_length,
  }

  return result
end

return M

local last_buf = vim.api.nvim_create_buf(true, true)
local curr_buf = vim.api.nvim_create_buf(true, true)
local log_buf = vim.api.nvim_create_buf(true, true)
local edit_buf = vim.api.nvim_create_buf(true, true)

Clear = function()
  vim.api.nvim_buf_set_lines(last_buf, 0, -1, true, { '' })
  vim.api.nvim_buf_set_lines(curr_buf, 0, -1, true, { '' })
  vim.api.nvim_buf_set_lines(log_buf, 0, -1, true, { '' })
end
vim.cmd [[
  command! Clear  execute 'lua Clear()'
]]

vim.cmd [[ split ]]
vim.cmd [[ vsplit ]]
vim.api.nvim_set_current_buf(edit_buf)
vim.cmd [[ wincmd w ]]
vim.api.nvim_set_current_buf(log_buf)
vim.cmd [[ wincmd w ]]
vim.api.nvim_set_current_buf(last_buf)
vim.cmd [[ vsplit ]]
vim.cmd [[ wincmd w ]]
vim.api.nvim_set_current_buf(curr_buf)
vim.cmd [[ wincmd w ]]

vim.api.nvim_buf_set_lines(edit_buf, 0, -1, true, {
'module Scratch where',
'',
'data Foo = FooConstructor String String',
'',
'--bar :: [Foo]',
'--bar =',
'--  (FooConstructor <$> ["hello, neovim!"] <* ["⊕" :: String])',
'--    <*> ["goodbye, neovim!"]',
'',
'baz :: String',
'baz = "this should stay as is"',
  })

local prev_lines = vim.api.nvim_buf_get_lines(edit_buf, 0, -1, true)

local callback = function(
  _,
  _,
  tick,
  start_row,
  start_col,
  byte_offset,
  prev_end_row,
  prev_end_col,
  prev_end_byte_length,
  curr_end_row,
  curr_end_col,
  curr_end_byte
)
  local curr_lines = vim.api.nvim_buf_get_lines(edit_buf, 0, -1, true)
  local change = {
    ['start'] = {
      row = start_row,
      col = start_col,
    },
    ['prev_end'] = {
      row = prev_end_row,
      col = prev_end_col,
    },
    ['curr_end'] = {
      row = curr_end_row,
      col = curr_end_col,
    },
    tick = tick,
    prev_lines = prev_lines,
    curr_lines = curr_lines,
  }
  change = vim.deepcopy(change)
  -- local prev_end_range, curr_end_range = sync.compute_end_range(last_lines, lines, start_range, lastline+1, new_lastline+1, offset_encoding)

  -- local text = extract_text(lines, start_range, new_end_range)

  local to_schedule = function()
    vim.api.nvim_buf_set_lines(last_buf, 0, 0, true, change.prev_lines)
    vim.api.nvim_buf_set_lines(last_buf, 0, 0, true, { '', 'last buffer state: ' .. tostring(change.tick) })
    vim.api.nvim_buf_set_lines(curr_buf, 0, 0, true, change.curr_lines)
    vim.api.nvim_buf_set_lines(curr_buf, 0, 0, true, { '', 'current buffer state: ' .. tostring(tick) })

    vim.api.nvim_buf_set_lines(log_buf, 0, 0, true, {
      string.format('tick %d', change.tick),
      string.format '{range',
      string.format '  {start: ',
      string.format('    line: %d', change.start.row),
      string.format('    char: %d', change.start.col),
      string.format '    }',
      string.format '  {prev end:',
      string.format('    line: %d', change.prev_end.row),
      string.format('    char: %d', change.prev_end.col),
      string.format '    }',
      string.format '  {curr end:',
      string.format('    line: %d', change.curr_end.row),
      string.format('    char: %d', change.curr_end.col),
      string.format '    }',
      string.format('  byte_offset: %d', byte_offset),
      string.format('  prev_end_byte_length: %d', prev_end_byte_length),
      string.format('  curr_end_byte: %d', curr_end_byte),
      '',
    })
  end
  vim.schedule(to_schedule)
end

vim.api.nvim_buf_attach(edit_buf, false, { on_bytes = callback })

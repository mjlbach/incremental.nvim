local sync = require 'sync'

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
-- vim.cmd [[ autocmd cursorhold * echo line('.') col('.')]]

vim.api.nvim_buf_set_lines(edit_buf, 0, -1, true, {
'a🔥',
'b🔥',
'c🔥',
'd🔥',
  })

local last_lines = vim.api.nvim_buf_get_lines(edit_buf, 0, -1, true)
local last_changed_tick = vim.deepcopy(vim.b.changedtick)

local line_ending = '\n'

local callback = function(_, _, tick, firstline, lastline, new_lastline, _, _, _)
  local curr_lines = vim.api.nvim_buf_get_lines(edit_buf, 0, -1, true)
  local copied_last_lines = vim.deepcopy(last_lines)
  local copied_firstline = vim.deepcopy(firstline)
  local copied_lastline = vim.deepcopy(lastline)
  local copied_new_lastline = vim.deepcopy(new_lastline)
  local copied_last_tick = vim.deepcopy(last_changed_tick)
  local copied_tick = vim.deepcopy(tick)

  local offset_encoding = 'utf-16'
  local start_range = sync.compute_start_range(
    last_lines,
    curr_lines,
    firstline + 1,
    lastline + 1,
    new_lastline + 1,
    offset_encoding
  )
  local prev_end_range, curr_end_range = sync.compute_end_range(last_lines, curr_lines, start_range, firstline+1, lastline+1, new_lastline+1, offset_encoding, line_ending)
  -- print(vim.inspect({firstline=firstline, lastline=lastline, new_lastline=new_lastline, last_lines=last_lines, curr_lines=curr_lines, start_range=start_range, prev_end_range=prev_end_range, curr_end_range=curr_end_range}))

  local text = sync.extract_text(curr_lines, start_range, curr_end_range, line_ending)

  local range_length = sync.compute_range_length(last_lines, start_range, prev_end_range, offset_encoding, line_ending)

  local to_schedule = function()
    local ur
    if copied_tick - copied_last_tick > 1 then
      ur = true
    else
      ur = false
    end
    vim.api.nvim_buf_set_lines(last_buf, 0, 0, true, copied_last_lines)
    vim.api.nvim_buf_set_lines(last_buf, 0, 0, true, { '', 'last buffer state: ' .. tostring(tick) })
    vim.api.nvim_buf_set_lines(curr_buf, 0, 0, true, curr_lines)
    vim.api.nvim_buf_set_lines(curr_buf, 0, 0, true, { '', 'current buffer state: ' .. tostring(tick) })

    vim.api.nvim_buf_set_lines(log_buf, 0, 0, true, {
      string.format('tick %d, undo/redo: %s', copied_tick, ur),
      -- string.format("{range"),
      -- string.format("  {start: "),
      -- string.format("    line: %d", start_range.line_idx - 1),
      -- string.format("    char: %d", start_range.char_idx - 1),
      -- string.format("    }"),
      -- string.format("  {end:"),
      -- string.format("    line: %d", old_end_range.line_idx - 1),
      -- string.format("    char: %d", old_end_range.char_idx - 1),
      -- string.format("    }"),
      string.format '{range',
      string.format '  {start: ',
      string.format('    line: %d', start_range.line_idx-1),
      string.format('    char: %d', start_range.char_idx-1),
      string.format '    }',
      string.format '  {end:',
      string.format("    line: %d", prev_end_range.line_idx-1),
      string.format("    char: %d", prev_end_range.char_idx-1),
      string.format("    }"),
      string.format("  {new text end:"),
      string.format("    line: %d", curr_end_range.line_idx-1),
      string.format("    char: %d", curr_end_range.char_idx-1),
      string.format '    }',
      -- string.format("start_range_char %d", start_range.char_idx),
      -- string.format("start_range_line %d", start_range.line_idx),
      -- string.format("start_range_byte %d", start_range.byte_idx),
      -- string.format("start_range_char %d", start_range.char_idx),
      -- string.format("old_end_range_line %d", old_end_range.line_idx),
      -- string.format("old_end_range_byte %d", old_end_range.byte_idx),
      -- string.format("old_end_range_char %d", old_end_range.char_idx),
      -- string.format("new_end_range_line %d", new_end_range.line_idx),
      -- string.format("new_end_range_byte %d", new_end_range.byte_idx),
      -- string.format("new_end_range_char %d", new_end_range.char_idx),
      string.format("text '%s'", vim.fn.join(vim.split(text, '\n'), '\\n')),
      string.format("range_length '%d'", range_length),
      string.format('firstline (1-indexed): %d', copied_firstline),
      string.format('lastline (1-indexed): %d', copied_lastline),
      string.format('newlastline (1-indexed): %d', copied_new_lastline),
      '',
    })
  end
  vim.schedule(to_schedule)
  last_lines = curr_lines
  last_changed_tick = tick
end

vim.api.nvim_buf_attach(edit_buf, false, { on_lines = callback })

local sync = require 'sync_bytes'

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

vim.api.nvim_buf_set_lines(edit_buf, 0, -1, true, { 'test1 test2', 'test2' })
local prev_lines = vim.api.nvim_buf_get_lines(edit_buf, 0, -1, true)

local offset_encoding = 'utf-8'
local line_ending = '\n'

local callback =
  function(_, _, tick, start_row, start_col, _, prev_end_row, prev_end_col, _, curr_end_row, curr_end_col, _)
    local curr_lines = vim.api.nvim_buf_get_lines(edit_buf, 0, -1, true)
    local change = sync.compute_diff(prev_lines, curr_lines, {
      start_row = start_row,
      start_col = start_col,
      prev_end_row = prev_end_row,
      prev_end_col = prev_end_col,
      curr_end_row = curr_end_row,
      curr_end_col = curr_end_col,
    }, offset_encoding, line_ending)
    change.prev_lines = prev_lines
    change.curr_lines = curr_lines
    change.tick = tick
    change = vim.deepcopy(change)
    -- local prev_end_range, curr_end_range = sync.compute_end_range(last_lines, lines, start_range, lastline+1, new_lastline+1, offset_encoding)

    -- local text = extract_text(lines, start_range, new_end_range)

    local to_schedule = function()
      local ur
      vim.api.nvim_buf_set_lines(last_buf, 0, 0, true, change.prev_lines)
      vim.api.nvim_buf_set_lines(last_buf, 0, 0, true, { '', 'last buffer state: ' .. tostring(change.tick) })
      vim.api.nvim_buf_set_lines(curr_buf, 0, 0, true, change.curr_lines)
      vim.api.nvim_buf_set_lines(curr_buf, 0, 0, true, { '', 'current buffer state: ' .. tostring(tick) })

      -- print(vim.inspect(change))
      vim.api.nvim_buf_set_lines(log_buf, 0, 0, true, {
        string.format('tick %d, undo/redo: %s', change.tick, ur),
        string.format('{range'),
        string.format('  {start: '),
        string.format('    line: %d', change.range.start.line),
        string.format('    char: %d', change.range.start.character),
        string.format '    }',
        string.format '  {end:',
        string.format('    line: %d', change.range['end'].line),
        string.format('    char: %d', change.range['end'].character),
        string.format '    }',
        string.format('  text : %s', vim.fn.join(vim.split(change.text, '\n'), '\\n')),
        '',
      })
    end
    vim.schedule(to_schedule)
  end

vim.api.nvim_buf_attach(edit_buf, false, { on_bytes = callback })

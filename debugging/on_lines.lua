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
vim.cmd [[ autocmd cursorhold * echo line('.') col('.')]]

vim.api.nvim_buf_set_lines(edit_buf, 0, -1, true, { 'test1 test2', 'test2' })

local last_lines = vim.api.nvim_buf_get_lines(edit_buf, 0, -1, true)
local last_changed_tick = vim.deepcopy(vim.b.changedtick)

local callback = function(_, _, tick, firstline, lastline, new_lastline, _, _, _)
  local lines = vim.api.nvim_buf_get_lines(edit_buf, 0, -1, true)
  local copied_last_lines = vim.deepcopy(last_lines)
  local copied_firstline = vim.deepcopy(firstline)
  local copied_lastline = vim.deepcopy(lastline)
  local copied_new_lastline = vim.deepcopy(new_lastline)
  local copied_last_tick = vim.deepcopy(last_changed_tick)
  local copied_tick = vim.deepcopy(tick)

  local to_schedule = function()
    local ur
    if copied_tick - copied_last_tick > 1 then
      ur = true
    else
      ur = false
    end
    vim.api.nvim_buf_set_lines(last_buf, 0, 0, true, copied_last_lines)
    vim.api.nvim_buf_set_lines(last_buf, 0, 0, true, { '', 'last buffer state: ' .. tostring(tick) })
    vim.api.nvim_buf_set_lines(curr_buf, 0, 0, true, lines)
    vim.api.nvim_buf_set_lines(curr_buf, 0, 0, true, { '', 'current buffer state: ' .. tostring(tick) })

    vim.api.nvim_buf_set_lines(log_buf, 0, 0, true, {
      string.format('tick %d, undo/redo: %s', copied_tick, ur),
      string.format('firstline (1-indexed): %d', copied_firstline + 1),
      string.format('lastline (1-indexed): %d', copied_lastline + 1),
      string.format('newlastline (1-indexed): %d', copied_new_lastline + 1),
      '',
    })
  end
  vim.schedule(to_schedule)
  last_lines = lines
  last_changed_tick = tick
end

vim.api.nvim_buf_attach(edit_buf, false, { on_lines = callback })

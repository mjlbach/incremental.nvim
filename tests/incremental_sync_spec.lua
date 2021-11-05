local sync = require('sync')

describe("One edit operations", function()
  it("Append a character on the current line at the 0th position", function()
    local prev_lines = {
      '',
    }
    local curr_lines = {
      'a',
    }
    local firstline = 0
    local lastline = 1
    local new_lastline = 1
    local offset_encoding="utf-8"
    local line_ending="\n"
    local text_edit = sync.compute_diff(prev_lines, curr_lines, firstline, lastline, new_lastline, offset_encoding, line_ending)

    -- Hacky adapter to old sync assumptions
    local startline =  math.min(firstline + 1, math.min(#prev_lines, #curr_lines))
    local endline =  math.min(-(#curr_lines - new_lastline), -1)
    local text_edit_original = vim.lsp.util.compute_diff(prev_lines, curr_lines, startline, endline, offset_encoding)
    assert.are.same(text_edit, text_edit_original)
  end)

  it("Remove a character on the current line at the 0th position", function()
    local prev_lines = {
      'a',
    }
    local curr_lines = {
      '',
    }
    local firstline = 0
    local lastline = 1
    local new_lastline = 1
    local offset_encoding="utf-8"
    local line_ending="\n"
    local text_edit = sync.compute_diff(prev_lines, curr_lines, firstline, lastline, new_lastline, offset_encoding, line_ending)

    -- Hacky adapter to old sync assumptions
    local startline =  math.min(firstline + 1, math.min(#prev_lines, #curr_lines))
    local endline =  math.min(-(#curr_lines - new_lastline), -1)
    local text_edit_original = vim.lsp.util.compute_diff(prev_lines, curr_lines, startline, endline, offset_encoding)
    assert.are.same(text_edit, text_edit_original)
  end)

end)

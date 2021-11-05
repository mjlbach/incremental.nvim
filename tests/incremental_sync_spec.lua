local sync = require 'sync'

describe('Single line operations', function()
  local firstline = 0
  local lastline = 1
  local new_lastline = 1
  local offset_encoding = 'utf-8'
  local line_ending = '\n'

  it('Append a character on the current line at the 0th position', function()
    local prev_lines = {
      '',
    }
    local curr_lines = {
      'a',
    }
    local text_edit = sync.compute_diff(
      prev_lines,
      curr_lines,
      firstline,
      lastline,
      new_lastline,
      offset_encoding,
      line_ending
    )

    -- Hacky adapter to old sync assumptions
    local startline = math.min(firstline + 1, math.min(#prev_lines, #curr_lines))
    local endline = math.min(-(#curr_lines - new_lastline), -1)
    local text_edit_original = vim.lsp.util.compute_diff(prev_lines, curr_lines, startline, endline, offset_encoding)
    assert.are.same(text_edit, text_edit_original)
  end)

  it('Append a character on the current line at the 0th position', function()
    local prev_lines = {
      'a',
    }
    local curr_lines = {
      'b',
    }
    local text_edit = sync.compute_diff(
      prev_lines,
      curr_lines,
      firstline,
      lastline,
      new_lastline,
      offset_encoding,
      line_ending
    )

    -- Hacky adapter to old sync assumptions
    local startline = math.min(firstline + 1, math.min(#prev_lines, #curr_lines))
    local endline = math.min(-(#curr_lines - new_lastline), -1)
    local text_edit_original = vim.lsp.util.compute_diff(prev_lines, curr_lines, startline, endline, offset_encoding)
    assert.are.same(text_edit, text_edit_original)
  end)

  it('Add a character in the middle of the current line', function()
    local prev_lines = {
      'ac',
    }
    local curr_lines = {
      'abc',
    }
    local text_edit = sync.compute_diff(
      prev_lines,
      curr_lines,
      firstline,
      lastline,
      new_lastline,
      offset_encoding,
      line_ending
    )

    -- Hacky adapter to old sync assumptions
    local startline = math.min(firstline + 1, math.min(#prev_lines, #curr_lines))
    local endline = math.min(-(#curr_lines - new_lastline), -1)
    local text_edit_original = vim.lsp.util.compute_diff(prev_lines, curr_lines, startline, endline, offset_encoding)
    assert.are.same(text_edit, text_edit_original)
  end)

  it('Remove a character on the current line at the 0th position', function()
    local prev_lines = {
      'a',
    }
    local curr_lines = {
      '',
    }
    local text_edit = sync.compute_diff(
      prev_lines,
      curr_lines,
      firstline,
      lastline,
      new_lastline,
      offset_encoding,
      line_ending
    )

    -- Hacky adapter to old sync assumptions
    local startline = math.min(firstline + 1, math.min(#prev_lines, #curr_lines))
    local endline = math.min(-(#curr_lines - new_lastline), -1)
    local text_edit_original = vim.lsp.util.compute_diff(prev_lines, curr_lines, startline, endline, offset_encoding)
    assert.are.same(text_edit, text_edit_original)
  end)

  it('Remove a character in the middle of the current line', function()
    local prev_lines = {
      'abc',
    }
    local curr_lines = {
      'ac',
    }
    local text_edit = sync.compute_diff(
      prev_lines,
      curr_lines,
      firstline,
      lastline,
      new_lastline,
      offset_encoding,
      line_ending
    )

    -- Hacky adapter to old sync assumptions
    local startline = math.min(firstline + 1, math.min(#prev_lines, #curr_lines))
    local endline = math.min(-(#curr_lines - new_lastline), -1)
    local text_edit_original = vim.lsp.util.compute_diff(prev_lines, curr_lines, startline, endline, offset_encoding)
    assert.are.same(text_edit, text_edit_original)
  end)

  it('Remove a character at the end of the current line', function()
    local prev_lines = {
      'abc',
    }
    local curr_lines = {
      'ab',
    }
    local text_edit = sync.compute_diff(
      prev_lines,
      curr_lines,
      firstline,
      lastline,
      new_lastline,
      offset_encoding,
      line_ending
    )

    -- Hacky adapter to old sync assumptions
    local startline = math.min(firstline + 1, math.min(#prev_lines, #curr_lines))
    local endline = math.min(-(#curr_lines - new_lastline), -1)
    local text_edit_original = vim.lsp.util.compute_diff(prev_lines, curr_lines, startline, endline, offset_encoding)
    assert.are.same(text_edit, text_edit_original)
  end)
end)

describe('2 edit operations', function()
  local offset_encoding = 'utf-8'
  local line_ending = '\n'

  it('Remove a character at the end of the current line', function()
    local edit_sequence = {
      {
        prev_lines = {
          'test1',
          'test2',
        },
        curr_lines = {
          'test1 test2',
          'test2',
        },
        firstline = 0,
        lastline = 1,
        new_lastline = 1,
      },
      {
        prev_lines = {
          'test1 test2',
          'test2',
        },
        curr_lines = {
          'test1 test2',
        },
        firstline = 1,
        lastline = 2,
        new_lastline = 1,
      },
    }

    for _, edit in ipairs(edit_sequence) do
      local prev_lines = edit.prev_lines
      local curr_lines = edit.curr_lines
      local firstline = edit.firstline
      local lastline = edit.lastline
      local new_lastline = edit.new_lastline

      local text_edit = sync.compute_diff(
        prev_lines,
        curr_lines,
        firstline,
        lastline,
        new_lastline,
        offset_encoding,
        line_ending
      )

      -- Hacky adapter to old sync assumptions
      local startline = math.min(firstline + 1, math.min(#prev_lines, #curr_lines))
      local endline = math.min(-(#curr_lines - new_lastline), -1)
      local text_edit_original = vim.lsp.util.compute_diff(prev_lines, curr_lines, startline, endline, offset_encoding)
      assert.are.same(text_edit, text_edit_original)
    end
  end)
end)

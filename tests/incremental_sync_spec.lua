-- Note on incremental sync:
--  Per the protocol, the text range should be:
--
--  A position inside a document (see Position definition below) is expressed as
--  a zero-based line and character offset. The offsets are based on a UTF-16
--  string representation. So a string of the form a𐐀b the character offset
--  of the character a is 0, the character offset of 𐐀 is 1 and the character
--  offset of b is 3 since 𐐀 is represented using two code units in UTF-16.
--
--  To ensure that both client and server split the string into the same line
--  representation the protocol specifies the following end-of-line sequences: ‘\n’, ‘\r\n’ and ‘\r’.
--
--  Positions are line end character agnostic. So you can not specify a position that denotes \r|\n or \n| where | represents the character offset. This means *no* defining a range than ends on the same line after a terminating character

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

describe('Multi line operations', function()
  local offset_encoding = 'utf-8'
  local line_ending = '\n'

  it('Remove the middle two lines', function()
    local prev_lines = {
      'test1',
      'test2',
      'test3',
      'test4',
    }
    local curr_lines = {
      'test1',
      'test4',
    }
    local firstline = 1
    local lastline = 3
    local new_lastline = 1

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

  it('2 line join operation', function()
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
  it('3 line join operation (join first to second line)', function()
    local edit_sequence = {
      {
        prev_lines = {
          'test1',
          'test2',
          'test3',
        },
        curr_lines = {
          'test1 test2',
          'test2',
          'test3',
        },
        firstline = 0,
        lastline = 1,
        new_lastline = 1,
      },
      {
        prev_lines = {
          'test1 test2',
          'test2',
          'test3',
        },
        curr_lines = {
          'test1 test2',
          'test3',
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
  it('3 line join operation (join second to third line)', function()
    local edit_sequence = {
      {
        prev_lines = {
          'test1',
          'test2',
          'test3',
        },
        curr_lines = {
          'test1',
          'test2 test 3',
          'test3',
        },
        firstline = 1,
        lastline = 2,
        new_lastline = 2,
      },
      {
        prev_lines = {
          'test1',
          'test2 test3',
          'test3',
        },
        curr_lines = {
          'test1',
          'test2 test3',
        },
        firstline = 2,
        lastline = 3,
        new_lastline = 2,
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

-- unicode that has previously failed
-- aб -> б
-- aб -> б

-- TODO:
-- * undo operations
-- * redo operations
-- * utf-8 vs utf-16
-- * multibyte characters
-- * newline with O/o
-- * deleting first line of buffer
-- * deleting last line of buffer
-- * deleting multiple lines including the first line of buffer
-- * deleting multiple lines including the last line of buffer
-- * deleting the entire buffer
-- * multiline deletion with X
-- *  
-- * delete partial line across mutliple lines
-- * add validation set scraped from vscode (careful, emulation of vim motions isn't perfect so some commands will be different)

-- delete line 1 (1-indexed)
local function test_delete_first_line()
  local old_lines = {
    'test1',
    'test2',
    'test3',
    'test4',
  }

  local new_lines = {
    'test2',
    'test3',
    'test4',
  }
end

-- delete line 2 (1-indexed)
local old_lines = {
  'test1',
  'test2',
  'test3',
  'test4',
}

local new_lines = {
  'test1',
  'test3',
  'test4',
}

-- delete line 4 (1-indexed)
local old_lines = {
  'test1',
  'test2',
  'test3',
  'test4',
}

local new_lines = {
  'test1',
  'test2',
  'test3',
}

-- The following will not map directly onto vscode due to ambiguity from the diffing mechanism
-- Delete from test*1 to test*3
-- Partial line deletion --Ambiguous
local old_lines = {
  'test1',
  'test2',
  'test3',
  'test4',
}

local new_lines = {
  'test3',
  'test4',
}

-- The following will not map directly onto vscode due to ambiguity from the diffing mechanism
-- Insert t at second position
local old_lines = {
  'test1',
}

local new_lines = {
  'ttest1',
}

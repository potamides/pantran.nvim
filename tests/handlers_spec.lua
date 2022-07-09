local handlers = require("pantran.handlers")
local async = require("pantran.async")

local text = [[Lorem ipsum dolor sit amet, officia excepteur ex fugiat
reprehenderit enim labore culpa sint ad nisi Lorem pariatur mollit ex esse
exercitation amet. Nisi anim cupidatat excepteur officia. Reprehenderit nostrud
nostrud ipsum Lorem est aliquip amet voluptate voluptate dolor minim nulla est
proident. Nostrud officia pariatur ut officia. Sit irure elit esse ea nulla
sunt ex occaecat reprehenderit commodo officia dolor Lorem duis laboris
cupidatat officia voluptate. Culpa proident adipisicing id nulla nisi laboris
ex in Lorem sunt duis officia eiusmod. Aliqua reprehenderit commodo ex non
excepteur duis sunt velit enim. Voluptate laboris sint cupidatat ullamco ut ea
consectetur et est culpa et culpa duis.]]

local line = "The quick brown fox jumped over the lazy dog."

local co = async.run(describe, "handler", function()
  before_each(function()
    vim.cmd("new")
    vim.api.nvim_buf_set_lines(0, 0, -1, true, vim.split(text, "\n"))
  end)

  after_each(function()
    vim.cmd("bdelete!")
  end)

  it('can yank text', function()
    local reg = vim.fn.getreg
    handlers.yank(line)
    assert.is_true(vim.tbl_contains({reg('"'), reg("*"), reg("+")}, line))
  end)

  it('can append text', function()
    handlers.append(line, {erow = 5})
    assert.are.equal(vim.api.nvim_buf_get_lines(0, 6, 7, true)[1], line)
  end)

  it('can replace text', function()
    local erow = #vim.split(text, "\n") - 1
    local ecol = #table.remove(vim.split(text, "\n")) - 1
    handlers.replace(line, {ecol = ecol, erow = erow, scol = 0, srow = 0})
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
    assert.are.equal(#lines, 1)
    assert.are.equal(lines[1], line)
  end)
end)

async.join(co)

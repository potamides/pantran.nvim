local engines = require("pantran.engines")
local ui = require("pantran.ui")
local async = require("pantran.async")

local example = "Hello World!"

describe("ui", function()
  async.run(it, 'can be started', function()
    local coords = {srow = -1, scol = -1, erow = -1, ecol = -1}
    assert.has_not.errors(function() ui = ui.new(engines.default, nil, nil, coords, example) end)
    assert.are.equal(vim.fn.exists(":Pantran"), 2)
  end)

  local co = async.run(it, 'can be locked', function()
    assert.are_not.equal(ui._mutex._owner, coroutine.running())
    ui:lock()
    assert.are.equal(ui._mutex.active, true)
    assert.are.equal(ui._mutex._owner, coroutine.running())
    ui:unlock()
  end)
  async.join(co)

  co = async.run(it, 'sets text fields correctly', function()
    ui:lock()
    assert.are.equal(ui.input, example)
    assert.are_not.equal(ui.translation, "")
    ui:unlock()
  end)
  async.join(co)

  it('uses correct languages', function()
    assert.are.equal(ui.source, engines.default.config.default_source)
    assert.are.equal(ui.target, engines.default.config.default_target)
  end)

  it('uses engine name as title', function()
    assert.are.equal(ui._win.languagebar._title, engines.default.name)
  end)

  it('closes when leaving buffer', function()
    vim.cmd("wincmd p")
    for _, win in pairs(ui._win) do
      assert.is_true(win.closed)
    end
    assert.are.equal(#vim.api.nvim_list_bufs(), 1)
    assert.are.equal(#vim.api.nvim_list_wins(), 1)
    collectgarbage()
    -- since current coroutine is still running this is 1 and not 0
    assert.are.equal(vim.tbl_count(async.mutex._owned), 1)
  end)
end)

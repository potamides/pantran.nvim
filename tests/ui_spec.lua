local engines = require("pantran.engines")
local ui = require("pantran.ui")
local async = require("pantran.async")

local example = "Hello World!"

local co = async.run(describe, "ui", function()
    it('can be started', function()
      local coords = {srow = -1, scol = -1, erow = -1, ecol = -1}
      assert.has_not.errors(function() ui = ui.new(engines.default, nil, nil, coords, example) end)
    end)

    it('sets source text', function()
      assert.are.equal(ui.input, example)
    end)

    it('uses correct languages', function()
      assert.are.equal(ui.source, engines.default.config.default_source)
      assert.are.equal(ui.target, engines.default.config.default_target)
    end)

    it('uses engine name as title', function()
      assert.are.equal(ui._win.languagebar._title, engines.default.name)
    end)
end)

async.join(co)

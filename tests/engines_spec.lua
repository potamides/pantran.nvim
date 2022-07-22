local pantran = require("pantran")
local async = require("pantran.async")

pantran.setup{
  -- be more lenient with timeouts (looking at you, Apertium)
  curl = {
    retry = 10,
    timeout = 0
  },
  engines = {
    -- this instance seems less timeout prone than beta one
    apertium = {
      url = "https://apertium.org/apy"
    }
  }
}

-- since some engines return fallback tables internally we want to only test
-- unique engines. To do this we simply use engines as table keys.
local engines = {
  [require("pantran.engines.apertium")] = true,
  [require("pantran.engines.argos")] = true,
  [require("pantran.engines.deepl")] = true,
  [require("pantran.engines.google")] = true,
  [require("pantran.engines.yandex")] = true,
  [require("pantran.engines.fallback.google")] = true,
  [require("pantran.engines.fallback.yandex")] = true,
}

local example = "Hello World!"

for engine, dotest in pairs(engines) do
  if dotest then
    local co = async.run(describe, engine.name, function()
        it('implements all required functions', function()
            assert.is_function(engine.setup)
            assert.is_function(engine.languages)
            assert.is_function(engine.switch)
            assert.is_function(engine.detect)
            assert.is_function(engine.translate)
        end)

        -- caveat: with github actions this only tests engines which do not require
        -- additional setup steps. On the bright side these are the most likely to
        -- fail.
        if pcall(engine.setup) then
          it('supports multiple languages', function()
            local languages = engine.languages()
            assert.are_not.equal(vim.tbl_count(languages.source), 0)
            assert.are_not.equal(vim.tbl_count(languages.target), 0)
          end)

          it('can switch languages', function()
            local runs, maxruns = 0, 100
            for src, _ in pairs(engine.languages().source) do
              for tgt, _ in pairs(engine.languages().target) do
                local new_src, new_tgt = engine.switch(src, tgt)
                assert.is_true(new_src == vim.NIL or type(new_src) == "string")
                assert.is_true(type(new_tgt) == "string")
                runs = runs + 1
                if runs > maxruns then
                  return
                end
              end
            end
          end)

          it('can detect languages', function()
            local detected = engine.detect(example)
            assert.is_true(vim.tbl_contains(vim.tbl_keys(engine.languages().source), detected))
          end)

          it('can translate', function()
            local translation = engine.translate(example)
            assert.are_not.equal(translation, "") -- it should return something
          end)
        end
    end)

    async.join(co)
  end
end

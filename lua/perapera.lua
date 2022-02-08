local engines = require("perapera.engines")

local perapera = {
  _mt = {},
  engines = {
    _mt = {}
  },
  default = {
    config = {
      default_engine = "argos",
      default_action = "replace",
    }
  }
}

function perapera._mt.__index(tbl, key)
  local ok, value = pcall(require, ("perapera.%s"):format(key))

  if ok then
    rawset(tbl, key, value)
    return value
  end
end

function perapera.engines._mt.__index(tbl, key)
  if not perapera.config then
    perapera.setup()
  end

  return tbl[key]
end

function perapera.setup(config)
  perapera.config = vim.tbl_deep_extend("force", perapera.default.config, config or {})

  for name, engine in pairs(engines) do
    perapera.engines[name] = engine.new(perapera.config[name])
    if name == perapera.config.default_engine then
      perapera.engines.default = perapera.engines[name]
    end
  end
end

setmetatable(perapera.engines, perapera.engines._mt)
return setmetatable(perapera, perapera._mt)

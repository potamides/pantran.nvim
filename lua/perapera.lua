local config = require("perapera.config")
local perapera = {
  _mt = {}
}

function perapera.setup(userconf)
  config.set(userconf)
end

function perapera._mt.__index(tbl, key)
  local ok, value = pcall(require, ("perapera.%s"):format(key))

  if ok then
    rawset(tbl, key, value)
    return value
  end
end

function perapera.translate(...)
  return perapera.command.translate(...)
end

function perapera.operator(...)
  return perapera.command.operator(...)
end

return setmetatable(perapera, perapera._mt)

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

return setmetatable(perapera, perapera._mt)

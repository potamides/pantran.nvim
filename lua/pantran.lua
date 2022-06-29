local config = require("pantran.config")
local pantran = {
  _mt = {}
}

function pantran.setup(userconf)
  config.set(userconf)
end

function pantran._mt.__index(tbl, key)
  local ok, value = pcall(require, ("pantran.%s"):format(key))

  if ok then
    rawset(tbl, key, value)
    return value
  end
end

function pantran.range_translate(...)
  return pantran.command.range_translate(...)
end

function pantran.motion_translate(...)
  return pantran.command.motion_translate(...)
end

return setmetatable(pantran, pantran._mt)

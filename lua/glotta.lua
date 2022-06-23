local config = require("glotta.config")
local glotta = {
  _mt = {}
}

function glotta.setup(userconf)
  config.set(userconf)
end

function glotta._mt.__index(tbl, key)
  local ok, value = pcall(require, ("glotta.%s"):format(key))

  if ok then
    rawset(tbl, key, value)
    return value
  end
end

function glotta.range_translate(...)
  return glotta.command.range_translate(...)
end

function glotta.motion_translate(...)
  return glotta.command.motion_translate(...)
end

return setmetatable(glotta, glotta._mt)

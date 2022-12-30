local lazy = {}

-- require modules lazily, i.e., only require them when they are actually used
function lazy.require(module)
  return setmetatable({}, {
    __index = function(_, k) return require(module)[k] end,
    __newindex = function(_, k, v) require(module)[k] = v end,
    -- A problem arises when we want to iterate over a module as the table is
    -- technically empty. In Lua 5.2+ we could use __pairs or __ipairs, but not
    -- in Lua 5.1. As a workaround we use __call to get the whole table.
    __call = function() return require(module) end
  })
end

return lazy

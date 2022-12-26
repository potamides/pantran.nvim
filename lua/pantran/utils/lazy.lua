local lazy = {}

-- require modules lazily, i.e., only require them when they are actually used
function lazy.require(module)
  return setmetatable({}, {
    __index = function(_, k) return require(module)[k] end,
    __newindex = function(_, k, v) require(module)[k] = v end
  })
end

return lazy

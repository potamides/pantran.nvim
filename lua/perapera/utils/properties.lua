local properties = {}

function properties.make(tbl, noself)
  local mt, proxy = {}, {
    prop = {
      set = {},
      get = {}
    }
  }

  for kind, funcs in pairs(tbl.prop) do
    for name, func in pairs(funcs) do
      if noself then
        proxy.prop[kind][name] = func
      else
        proxy.prop[kind][name] = function(...) return func(tbl, ...) end
      end
    end
  end

  mt.__index = function(_, key)
    if tbl.prop.get and tbl.prop.get[key] then
      return tbl.prop.get[key](noself and nil or tbl)
    else
      return tbl[key]
    end
  end

  mt.__newindex = function(_, key, value)
    if tbl.prop.set and tbl.prop.set[key] then
      tbl.prop.set[key](unpack(noself and {value} or {tbl, value}))
    else
      rawset(tbl, key, value)
    end
  end

  return setmetatable(proxy, mt)
end


return properties

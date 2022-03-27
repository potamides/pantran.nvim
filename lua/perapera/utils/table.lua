local table = {}

function table.pop(tbl, key)
  if type(key) == "number" then
    return table.remove(tbl, key)
  else
    local value = tbl[key]
    tbl[key] = nil
    return value
  end
end

function table.defaulttable(default, weak_keys)
  local tbl, mt = {}, {}

  function mt.__index(_, key)
    local val = rawget(tbl, key)
    if val then
      return val
    else
      rawset(tbl, key, vim.deepcopy(default))
      return rawget(tbl, key)
    end
  end

  if weak_keys then
    mt.__mode = "k"
  end

  return setmetatable(tbl, mt)
end

return table

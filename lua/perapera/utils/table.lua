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

return table

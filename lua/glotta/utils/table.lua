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

-- Python-like zip() iterator (see https://stackoverflow.com/a/36096338)
function table.zip(...)
  local arrays, ans = {...}, {}
  local index = 0
  return function()
    index = index + 1
    for i,t in ipairs(arrays) do
      if type(t) == 'function' then ans[i] = t() else ans[i] = t[index] end
      if ans[i] == nil then return end
    end
    return unpack(ans)
  end
end

return table

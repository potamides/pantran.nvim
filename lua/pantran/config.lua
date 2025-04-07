local config = {
  _mt = {},
  user = {}
}

local function deep_setmetatable(tbl, meta)
  for _, value in pairs(setmetatable(tbl, meta)) do
    if type(value) == "table" then
      deep_setmetatable(value, meta)
    end
  end
  return tbl
end

function config.set(userconf)
  config.user = deep_setmetatable(userconf, config._mt)
end

function config.apply(userconf, object)
  -- vim.tbl_deep_extend doesn't like custom metatables
  userconf = deep_setmetatable(vim.deepcopy(userconf))
  object.config = vim.tbl_deep_extend("force", object.config, userconf)
  return object
end

function config._mt.__index()
  return setmetatable({}, config._mt)
end

setmetatable(config.user, config._mt)
return config

local async = require("perapera.async")

local curl = {
  default = {
    args = {
      cmd = "curl",
      auth = {}
    }
  }
}

function curl:_spawn(request, path, data, callback)
  local stdout, response, handle = vim.loop.new_pipe(), ""
  local args = {
    "--request", request,
    "--header", "accept: application/json",
    tostring(self._url / path)
  }

  for key, value in pairs(vim.tbl_extend("error", self._auth, data)) do
    table.insert(args, 1, ("%s=%s"):format(key, value))
    table.insert(args, 1, "--data-urlencode")
  end

  handle = vim.loop.spawn(self._cmd, {
      args = args,
      stdio = {nil, stdout, nil}
    },
    vim.schedule_wrap(function(code) -- on exit
      if code ~= 0 then
        vim.notify(("%q exited with error code %d!"):format(self._cmd, code), vim.log.levels.ERROR)
      elseif callback then
        local ok, decoded = pcall(vim.fn.json_decode, response)
        if ok then
          callback(decoded)
        else
          vim.notify("Couldn't decode JSON response.", vim.log.levels.ERROR)
        end
      end
      handle:close()
      stdout:close()
  end))

  if handle then
    stdout:read_start(vim.schedule_wrap(function(err, chunk)
      if err then
        vim.notify(err, vim.log.levels.ERROR)
      elseif chunk then
        response = response .. chunk
      end
    end))
  else
    vim.notify(("Something went wrong. Make sure that %q is installed."):format(self._cmd), vim.log.levels.ERROR)
  end
end

function curl:post(path, data)
  return async.wrap(curl._spawn, self, "POST", path, data or {})
end

function curl:put(path, data)
  return async.wrap(curl._spawn, self, "PUT", path, data or {})
end

function curl:get(path)
  return async.wrap(curl._spawn, self, "PUT", path)
end

function curl:delete(path)
  return async.wrap(curl._spawn, self, "DELETE", path)
end

function curl.url(uri)
  local url = {url = uri, _mt = {}}

  function url._mt.__tostring(self)
    return self.url
  end

  function url._mt.__div(dividend, divisor)
    local separator = vim.endswith(dividend.url, "/") and "" or "/"
    return curl.url(("%s%s%s"):format(dividend.url, separator, divisor))
  end

  return setmetatable(url, url._mt)
end

function curl.new(args)
  args = vim.tbl_deep_extend("force", curl.default.args, args or {})
  local self = {
    _url = curl.url(args.url),
    _auth = args.auth,
    _cmd = args.cmd
  }

  return setmetatable(self, {__index = curl})
end

return curl

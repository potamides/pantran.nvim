local async = require("glotta.async")
local config = require("glotta.config")

local curl = {
  config = {
    cmd = "curl",
    retry = 3,
    timeout = 15
  }
}

function curl:_spawn(request, path, data, callback)
  local cmd, stdout, response, handle = self.config.cmd, vim.loop.new_pipe(), ""
  local args = {
    "--fail-with-body",
    "--retry", self.config.retry,
    "--max-time", self.config.timeout,
    "--retry-max-time", self.config.timeout,
    "--request", request,
    "--header", "accept: application/json",
    tostring(self._url / path)
  }

  for key, value in pairs(vim.tbl_extend("error", self._data, data)) do
    table.insert(args, 1, ("%s=%s"):format(key, value))
    table.insert(args, 1, "--data-urlencode")
  end

  for key, value in pairs(self._headers) do
    table.insert(args, 1, ("%s: %s"):format(key, value))
    table.insert(args, 1, "--header")
  end

  if self._cache[table.concat(args)] then
    callback(true, self._cache[table.concat(args)])
    return
  end

  handle = vim.loop.spawn(cmd, {
      args = args,
      stdio = {nil, stdout, nil}
    },
    vim.schedule_wrap(function(code) -- on exit
      local ok, decoded = pcall(vim.fn.json_decode, response)
      if code ~= 0 then
        if ok then
          callback(false, self._fmt_error(decoded))
        else
          callback(false, ("%q exited with error code %d!"):format(cmd, code))
        end
      elseif callback then
        if ok then
          if vim.tbl_contains(self._static_paths, path) then
            self._cache[table.concat(args)] = decoded
          end
          callback(true, decoded)
        else
          callback(false, "Couldn't decode JSON response.")
        end
      end
      handle:close()
      stdout:close()
  end))

  if handle then
    stdout:read_start(vim.schedule_wrap(function(err, chunk)
      if err then
        callback(false, err)
      elseif chunk then
        response = response .. chunk
      end
    end))
  else
    callback(false, ("Something went wrong. Make sure that %q is installed."):format(cmd))
  end
end

function curl:post(path, data)
  local ok, response = async.suspend(curl._spawn, self, "POST", path, data or {})
  if ok then return response end
  error(response, 0)
end

function curl:put(path, data)
  local ok, response = async.suspend(curl._spawn, self, "PUT", path, data or {})
  if ok then return response end
  error(response, 0)
end

function curl:get(path, data)
  local ok, response = async.suspend(curl._spawn, self, "GET", path, data or {})
  if ok then return response end
  error(response, 0)
end

function curl:delete(path, data)
  local ok, response = async.suspend(curl._spawn, self, "DELETE", path, data or {})
  if ok then return response end
  error(response, 0)
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
  local self = {
    _url = curl.url(args.url),
    _data = args.data or {},
    _headers = args.headers or {},
    _static_paths = args.static_paths or {},
    _fmt_error = args.fmt_error or function(rsp) return tostring(rsp) end,
    _cache = {}
  }

  return setmetatable(self, {__index = curl})
end

return config.apply(config.user.curl, curl)

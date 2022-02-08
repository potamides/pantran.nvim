local curl = require("perapera.curl")

local argos = {
  name = "Argos Translate",
  default = {
    args = {
      url = "https://translate.argosopentech.com",
      auth = {api_key = nil} -- optional for many libretranslate instances
    },
    source = "auto",
    target = "en"
  }
}

function argos:detect(text)
  return self._api:post("detect", {q = text})
end

function argos:languages()
  return self._api:get("languages")
end

function argos:translate(text, source, target)
  local translation = self._api:post("translate", {
    q = text,
    source = source or self.default.source,
    target = target or self.default.target
  })

  return translation.translatedText
end

function argos.new(args)
  args = vim.tbl_deep_extend("force", argos.default.args, args or {})
  local self = {
    _api = curl.new{
      url = args.url,
      auth = args.auth
    }
  }

  return setmetatable(self, {__index = argos})
end

return argos

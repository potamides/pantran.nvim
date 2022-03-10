local curl = require("perapera.curl")

local argos = {
  name = "Argos Translate",
  default = {
    args = {
      url = "https://translate.argosopentech.com",
      auth = {api_key = vim.NIL} -- optional for many libretranslate instances
    },
    source = "auto",
    target = "en"
  }
}

function argos:detect(text)
  return self._api:post("detect", {q = text})[1].language
end

function argos:languages()
  if not self._languages then
    local languages = {
      source = {
        auto = "Auto"
      },
      target = {}
    }

    for _, lang in pairs(self._api:get("languages")) do
      languages.source[lang.code] = lang.name
      languages.target[lang.code] = lang.name
    end
    self._languages = languages
  end

  return self._languages
end

function argos:switch(source, target)
  if source == "auto" then
    return source, target
  else
    return target, source
  end
end

function argos:translate(text, source, target)
  local translation = self._api:post("translate", {
    q = text,
    source = source or self.default.source,
    target = target or self.default.target
  })

  return {
    text = translation.translatedText,
    detected = source == "auto" and self:detect(text) or nil
  }
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

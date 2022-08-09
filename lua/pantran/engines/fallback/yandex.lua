local curl = require("pantran.curl")
local config = require("pantran.config")

-- implementation based on https://github.com/Animenosekai/translate
local yandex = {
  name = "Yandex Translate v1",
  url = "https://translate.yandex.net/api/v1/tr.json",
  config = {
    default_source = "auto",
    default_target = "en"
  }
}

function yandex.uuid()
  -- taken from https://gist.github.com/jrus/3197011
  local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
  return string.gsub(template, '[xy]', function (c)
    local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
    return string.format('%x', v)
  end)
end

function yandex.detect(text)
  local detected = yandex._api:get("detect", {
    text = text,
    ucid = yandex.uuid():gsub("-", ""),
  })

  return detected.lang
end

function yandex.languages()
  -- without ui parameter this does not return codes.langs
  local codes = yandex._api:get("getLangs", {ui = true})

  local languages = {
    source = vim.tbl_extend("error", {auto = "Auto"}, codes.langs),
    target = codes.langs
  }

  return languages
end

function yandex.switch(source, target)
  local langs = yandex.languages()
  if source == "auto" or not langs.target[source] or not langs.source[target] then
    return source, target
  else
    return target, source
  end
end

function yandex.translate(text, source, target)
  source, target = source or yandex.config.default_source, target or yandex.config.default_target
  local resolved_source = source == "auto" and yandex.detect(text) or source

  local translation = yandex._api:post("translate", {
    text = text,
    ucid = yandex.uuid():gsub("-", ""),
    lang = ("%s-%s"):format(resolved_source, target),
  })

  return {
    text = translation.text[1],
    detected = source == "auto" and resolved_source or nil
  }
end

function yandex.setup()
  yandex._api = curl.new{
    url = yandex.url,
    static_paths = {"getLangs"},
    fmt_error = function(response) return response.message end,
    data = {
      srv = "android",
      format = "text"
    }
  }
end

return config.apply(config.user.engines.yandex.fallback, yandex)

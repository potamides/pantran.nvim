local curl = require("pantran.curl")
local config = require("pantran.config")
local fallback = require("pantran.engines.fallback.google")

local google = {
  name = "Google Translate v2",
  url = "https://translation.googleapis.com/language/translate/v2",
  config = {
    api_key = vim.env.GOOGLE_API_KEY,
    bearer_token = vim.env.GOOGLE_BEARER_TOKEN,
    default_source = vim.NIL,
    default_target = "en",
    format = "text",
  }
}

function google.detect(text)
  local detected = google._api:post("detect", {
    q = text,
  })

  return detected.data.detections[1].language
end

function google.languages()
  local languages = {
    source = {
      [vim.NIL] = "Auto"
    },
    target = {}
  }

  local google_langs = google._api:get("languages", {
    target = "en"
  })

  for _, lang in pairs(google_langs.data.languages) do
    languages.source[lang.language] = lang.name
    languages.target[lang.language] = lang.name
  end

  return languages
end

function google.switch(source, target)
  local langs = google.languages()
  if source == vim.NIL or not langs.target[source] or not langs.source[target] then
    return source, target
  else
    return target, source
  end
end

function google.translate(text, source, target)
  source, target = source or google.config.default_source, target or google.config.default_target

  local translation = google._api:post("translate", {
    q = text,
    source = source ~= vim.NIL and source or nil,
    target = target,
    format = google.config.format,
  }).data.translations[1]

  return {
    text = translation.translatedText,
    detected = translation.detectedSourceLanguage
  }
end

function google.setup()
  local c = google.config

  google._api = curl.new{
    url = google.url,
    static_paths = {"languages"},
    fmt_error = function(response) return response.error.message end,
    headers = {
      authorization = not c.api_key and ("Bearer %s"):format(c.bearer_token) or nil
    },
    data = {
      key = google.config.api_key,
    }
  }
end

if google.config.bearer_token or google.config.api_key then
  return config.apply(config.user.engines.google, google)
end
return fallback

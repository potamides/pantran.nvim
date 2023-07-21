local curl = require("pantran.curl")
local config = require("pantran.config")
local fallback = require("pantran.engines.fallback.yandex")

-- implementation based on https://github.com/Animenosekai/translate
local yandex = {
  name = "Yandex Translate v2",
  url = "https://translate.api.cloud.yandex.net/translate/v2",
  config = {
    api_key = vim.env.YANDEX_API_KEY,
    iam_token = vim.env.YANDEX_IAM_TOKEN,
    folder_id = vim.env.YANDEX_FOLDER_ID, -- only required for user accounts
    default_source = vim.NIL,
    default_target = "en",
    format = "PLAIN_TEXT",
  }
}

function yandex.detect(text)
  local detected = yandex._api:post("detect", {
    text = text,
  })

  return detected.languageCode
end

function yandex.languages()
  local languages = {
    source = {
      [vim.NIL] = "Auto"
    },
    target = {}
  }

  local langs = yandex._api:post("languages").languages
  for _, lang in pairs(langs) do
    languages.source[lang.code] = lang.name
    languages.target[lang.code] = lang.name
  end

  return languages
end

function yandex.switch(source, target)
  local langs = yandex.languages()
  if source == vim.NIL or not langs.target[source] or not langs.source[target] then
    return source, target
  else
    return target, source
  end
end

function yandex.translate(text, source, target)
  source, target = source or yandex.config.default_source, target or yandex.config.default_target

  local translation = yandex._api:post("translate", {
    texts = {text},
    sourceLanguageCode = source ~= vim.NIL and source or nil,
    targetLanguageCode = target,
    format = yandex.config.format,
  }).translations[1]

  return {
    text = translation.text,
    detected = source == vim.NIL and translation.detectedLanguageCode or nil
  }
end

function yandex.setup()
  local c = yandex.config

  yandex._api = curl.new{
    url = yandex.url,
    static_paths = {"languages"},
    fmt_error = function(response) return response.message end,
    headers = {
      ["Content-Type"] = "application/json",
      ["Authorization"] = c.api_key and ("Api-Key %s"):format(c.api_key) or ("Bearer %s"):format(c.iam_token)
    },
    data = {
      folderId = c.folder_id,
    }
  }
end

config.apply(config.user.engines.yandex, yandex)
if yandex.config.iam_token or yandex.config.api_key then
  return yandex
end
return fallback

-- PVP99 - DEMON ORAMOND INSTALLER
local PRODUCT_LABEL = "DEMON ORAMOND"
local REMOTE_ROOT = "Demon-Oramond"
local TARGET_NAME = "Demon-Oramond"
local OWNER = "oficiallpvp99"
local REPO = "PVP99-Dist"
local BRANCH = "main"
local MAX_RETRIES = 3

local function encodeUrlPath(path)
  return tostring(path or ""):gsub("([^%w%-%._~/])", function(c)
    return string.format("%%%02X", string.byte(c))
  end)
end

local BASE_URL = "https://raw.githubusercontent.com/" .. OWNER .. "/" .. REPO ..
  "/refs/heads/" .. BRANCH .. "/" .. encodeUrlPath(REMOTE_ROOT) .. "/"

local MANIFEST_URL = BASE_URL .. "manifest.lua"
local VIRTUAL_ROOT = "/bot/" .. TARGET_NAME
local COMPLETE_MARKER = VIRTUAL_ROOT .. "/.pvp99_complete"

local oldTimeout = HTTP.timeout
HTTP.timeout = math.max(HTTP.timeout or 5, 15)

local function restoreTimeout()
  HTTP.timeout = oldTimeout or 5
end

local function safeRelativePath(path)
  if type(path) ~= "string" or path == "" then return false end
  if path:sub(1,1) == "/" or path:find("\\",1,true) or path:find(":",1,true) then return false end
  for part in path:gmatch("[^/]+") do
    if part == "." or part == ".." or part == "" then return false end
  end
  return true
end

local function ensureDir(path)
  if not g_resources.directoryExists(path) then g_resources.makeDir(path) end
  return g_resources.directoryExists(path)
end

local function prepareDirectories(manifest)
  if not ensureDir("/bot") then return false end
  if not ensureDir(VIRTUAL_ROOT) then return false end
  for _, rel in ipairs(manifest.directories or {}) do
    if not safeRelativePath(rel) then return false end
    local current = VIRTUAL_ROOT
    for part in rel:gmatch("[^/]+") do
      current = current .. "/" .. part
      if not ensureDir(current) then return false end
    end
  end
  return true
end

local function findRootLua(manifest)
  for _, rel in ipairs(manifest.files or {}) do
    if not rel:find("/",1,true) and rel:lower():match("%.lua$") then return rel end
  end
end

local function install(manifest)
  if type(manifest) ~= "table" or type(manifest.files) ~= "table" then restoreTimeout() return end
  local rootLua = findRootLua(manifest)
  if not rootLua then restoreTimeout() print("[PVP99] ERRO: nenhum Lua na raiz.") return end
  if not prepareDirectories(manifest) then restoreTimeout() print("[PVP99] ERRO criando pastas.") return end
  if g_resources.fileExists(COMPLETE_MARKER) then g_resources.deleteFile(COMPLETE_MARKER) end

  local list, index = manifest.files, 1
  local total = #list

  local function nextFile(retry)
    local rel = list[index]
    if not rel then
      restoreTimeout()
      if not g_resources.fileExists(VIRTUAL_ROOT .. "/" .. rootLua) then
        print("[PVP99] ERRO: Lua principal ausente.")
        return
      end
      g_resources.writeFileContents(COMPLETE_MARKER, "PVP99_OK")
      print("[PVP99] " .. PRODUCT_LABEL .. " instalado com sucesso.")
      print("[PVP99] Desligue e ligue o Bot.")
      return
    end

    retry = retry or 0
    local url = BASE_URL .. encodeUrlPath(rel)
    local target = VIRTUAL_ROOT .. "/" .. rel
    print("[PVP99] " .. index .. "/" .. total .. " - " .. rel)

    HTTP.get(url, function(data, err)
      if err or data == nil then
        if retry < MAX_RETRIES then
          schedule(300, function() nextFile(retry + 1) end)
        else
          restoreTimeout()
          print("[PVP99] ERRO baixando: " .. rel)
        end
        return
      end

      local ok = pcall(function() g_resources.writeFileContents(target, data) end)
      if not ok or not g_resources.fileExists(target) then
        restoreTimeout()
        print("[PVP99] ERRO gravando: " .. rel)
        return
      end

      index = index + 1
      schedule(10, function() nextFile(0) end)
    end)
  end

  nextFile(0)
end

HTTP.get(MANIFEST_URL, function(data, err)
  if err or not data or data == "" then restoreTimeout() print("[PVP99] Erro manifest.") return end
  local chunk, loadErr = loadstring(data)
  if not chunk then restoreTimeout() print("[PVP99] Manifest Lua invalido: " .. tostring(loadErr)) return end
  local ok, manifest = pcall(chunk)
  if not ok then restoreTimeout() print("[PVP99] Erro executando manifest.") return end
  install(manifest)
end)

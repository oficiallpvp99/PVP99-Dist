-- ============================================================
-- PVP99 - BDS INSTALLER
-- BOT MANAGER / OTCv8
-- ============================================================

local PRODUCT_LABEL = "BDS"
local REMOTE_ROOT = "Bds"
local TARGET_NAME = "Bds"

local OWNER = "oficiallpvp99"
local REPO = "PVP99-Dist"
local BRANCH = "main"
local MAX_RETRIES = 3

local function encodeUrlPath(path)
  return tostring(path or ""):gsub("([^%w%-%._~/])", function(c)
    return string.format("%%%02X", string.byte(c))
  end)
end

local BASE_URL =
  "https://raw.githubusercontent.com/"
  .. OWNER .. "/"
  .. REPO .. "/refs/heads/"
  .. BRANCH .. "/"
  .. encodeUrlPath(REMOTE_ROOT) .. "/"

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
  if path:sub(1, 1) == "/" then return false end
  if path:find("\\", 1, true) then return false end
  if path:find(":", 1, true) then return false end

  for part in path:gmatch("[^/]+") do
    if part == "." or part == ".." or part == "" then
      return false
    end
  end

  return true
end

local function ensureDir(path)
  if not g_resources.directoryExists(path) then
    g_resources.makeDir(path)
  end
  return g_resources.directoryExists(path)
end

local function prepareDirectories(manifest)
  if not ensureDir("/bot") then
    return false, "Nao foi possivel criar /bot"
  end

  if not ensureDir(VIRTUAL_ROOT) then
    return false, "Nao foi possivel criar " .. VIRTUAL_ROOT
  end

  for _, rel in ipairs(manifest.directories or {}) do
    if not safeRelativePath(rel) then
      return false, "Diretorio invalido: " .. tostring(rel)
    end

    local current = VIRTUAL_ROOT

    for part in rel:gmatch("[^/]+") do
      current = current .. "/" .. part

      if not ensureDir(current) then
        return false, "Falha ao criar pasta: " .. current
      end
    end
  end

  return true
end

local function removeOldMarker()
  if g_resources.fileExists(COMPLETE_MARKER) then
    g_resources.deleteFile(COMPLETE_MARKER)
  end
end

local function writeMarker()
  local value = "PVP99_OK"

  if os.time then
    value = value .. ":" .. tostring(os.time())
  end

  g_resources.writeFileContents(COMPLETE_MARKER, value)
  return g_resources.fileExists(COMPLETE_MARKER)
end

local function findRootLua(manifest)
  for _, rel in ipairs(manifest.files or {}) do
    if type(rel) == "string"
      and not rel:find("/", 1, true)
      and rel:lower():match("%.lua$") then
      return rel
    end
  end
  return nil
end

local function install(manifest)
  if type(manifest) ~= "table" or type(manifest.files) ~= "table" then
    restoreTimeout()
    print("[PVP99] Manifest invalido.")
    return
  end

  local rootLua = findRootLua(manifest)

  if not rootLua then
    restoreTimeout()
    print("[PVP99] ERRO: nenhum arquivo Lua na raiz do bot.")
    return
  end

  local ok, dirErr = prepareDirectories(manifest)

  if not ok then
    restoreTimeout()
    print("[PVP99] " .. tostring(dirErr))
    return
  end

  removeOldMarker()

  local list = manifest.files
  local total = #list
  local index = 1

  print("[PVP99] Instalando " .. PRODUCT_LABEL .. "...")
  print("[PVP99] Arquivos: " .. total)

  local function downloadNext(retry)
    local rel = list[index]

    if not rel then
      restoreTimeout()

      if not g_resources.fileExists(VIRTUAL_ROOT .. "/" .. rootLua) then
        print("[PVP99] ERRO: arquivo Lua principal nao foi instalado.")
        return
      end

      if not writeMarker() then
        print("[PVP99] ERRO: nao foi possivel criar .pvp99_complete.")
        return
      end

      print("[PVP99] " .. PRODUCT_LABEL .. " instalado com sucesso.")
      print("[PVP99] Pasta: " .. VIRTUAL_ROOT)
      print("[PVP99] Desligue e ligue o Bot.")
      return
    end

    if not safeRelativePath(rel) then
      restoreTimeout()
      print("[PVP99] Caminho invalido: " .. tostring(rel))
      return
    end

    retry = retry or 0

    local url = BASE_URL .. encodeUrlPath(rel)
    local target = VIRTUAL_ROOT .. "/" .. rel

    print("[PVP99] " .. index .. "/" .. total .. " - " .. rel)

    HTTP.get(url, function(data, err)
      if err or data == nil then
        if retry < MAX_RETRIES then
          schedule(300, function()
            downloadNext(retry + 1)
          end)
          return
        end

        restoreTimeout()
        print("[PVP99] ERRO baixando: " .. rel)
        print("[PVP99] " .. tostring(err))
        return
      end

      local writeOk, writeErr = pcall(function()
        g_resources.writeFileContents(target, data)
      end)

      if not writeOk or not g_resources.fileExists(target) then
        restoreTimeout()
        print("[PVP99] ERRO gravando: " .. target)
        print("[PVP99] " .. tostring(writeErr))
        return
      end

      index = index + 1

      schedule(10, function()
        downloadNext(0)
      end)
    end)
  end

  downloadNext(0)
end

print("[PVP99] Buscando manifest de " .. PRODUCT_LABEL .. "...")

HTTP.get(MANIFEST_URL, function(data, err)
  if err or not data or data == "" then
    restoreTimeout()
    print("[PVP99] Nao foi possivel baixar o manifest.")
    print("[PVP99] " .. tostring(err))
    return
  end

  local chunk, loadErr = loadstring(data)

  if not chunk then
    restoreTimeout()
    print("[PVP99] Manifest com erro Lua:")
    print("[PVP99] " .. tostring(loadErr))
    return
  end

  local ok, manifest = pcall(chunk)

  if not ok then
    restoreTimeout()
    print("[PVP99] Erro executando manifest:")
    print("[PVP99] " .. tostring(manifest))
    return
  end

  install(manifest)
end)

-- ============================================================
-- PVP99 - BOOK WORLD INSTALLER / UPDATER V3
-- OTCv8
--
-- CORRECAO:
-- O HTTP.download do OTC baixa para a area de downloads.
-- Para instalar uma CONFIG em /bot corretamente, usamos HTTP.get
-- + g_resources.writeFileContents diretamente no /bot/Book-World.
--
-- Ao concluir 100%, cria:
--   /bot/Book-World/.pvp99_complete
-- ============================================================

local OWNER = "oficiallpvp99"
local REPO = "PVP99-Dist"
local BRANCH = "main"
local REMOTE_ROOT = "Book-World"

local TARGET_NAME = "Book-World"
local MAX_RETRIES = 3

local BASE_URL =
  "https://raw.githubusercontent.com/"
  .. OWNER .. "/"
  .. REPO .. "/refs/heads/"
  .. BRANCH .. "/"
  .. REMOTE_ROOT .. "/"

local MANIFEST_URL = BASE_URL .. "manifest.lua"

local VIRTUAL_ROOT = "/bot/" .. TARGET_NAME
local COMPLETE_MARKER = VIRTUAL_ROOT .. "/.pvp99_complete"

local oldTimeout = HTTP.timeout
HTTP.timeout = math.max(HTTP.timeout or 5, 15)

local function finishTimeout()
  HTTP.timeout = oldTimeout or 5
end

local function safeRelativePath(path)
  if type(path) ~= "string" or path == "" then return false end
  if path:sub(1, 1) == "/" then return false end
  if path:find("\\", 1, true) then return false end
  if path:find(":", 1, true) then return false end

  for part in path:gmatch("[^/]+") do
    if part == ".." or part == "." or part == "" then
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
      return false, "Diretorio invalido no manifest: " .. tostring(rel)
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

local function writeCompleteMarker()
  local value = "PVP99_OK"

  if os.time then
    value = value .. ":" .. tostring(os.time())
  end

  g_resources.writeFileContents(COMPLETE_MARKER, value)
  return g_resources.fileExists(COMPLETE_MARKER)
end

local function installManifest(manifest)
  if type(manifest) ~= "table" or type(manifest.files) ~= "table" then
    finishTimeout()
    print("[PVP99] Manifest invalido.")
    return
  end

  local ok, dirErr = prepareDirectories(manifest)

  if not ok then
    finishTimeout()
    print("[PVP99] " .. tostring(dirErr))
    return
  end

  removeOldMarker()

  local files = manifest.files
  local total = #files
  local index = 1

  print("[PVP99] Instalando Book-World...")
  print("[PVP99] Arquivos: " .. total)

  local function downloadNext(retry)
    local rel = files[index]

    if not rel then
      finishTimeout()

      -- Verificacao importante: uma config OTC precisa ter Lua no topo.
      if not g_resources.fileExists(VIRTUAL_ROOT .. "/_Loader.lua")
        and not g_resources.fileExists(VIRTUAL_ROOT .. "/a.lua") then
        print("[PVP99] ERRO: arquivos Lua principais nao foram instalados.")
        return
      end

      if not writeCompleteMarker() then
        print("[PVP99] ERRO: nao foi possivel gravar confirmacao de instalacao.")
        return
      end

      print("[PVP99] Book-World instalado com sucesso.")
      print("[PVP99] Pasta: " .. VIRTUAL_ROOT)
      print("[PVP99] Download confirmado.")
      print("[PVP99] Desligue e ligue o Bot para selecionar o seu script.")
      return
    end

    if not safeRelativePath(rel) then
      finishTimeout()
      print("[PVP99] Caminho invalido: " .. tostring(rel))
      return
    end

    retry = retry or 0

    print(
      "[PVP99] "
      .. index .. "/" .. total
      .. " - " .. rel
    )

    local url = BASE_URL .. rel
    local target = VIRTUAL_ROOT .. "/" .. rel

    HTTP.get(url, function(data, err)
      if err or data == nil then
        if retry < MAX_RETRIES then
          print(
            "[PVP99] Tentando novamente "
            .. rel
            .. " (" .. (retry + 1) .. "/" .. MAX_RETRIES .. ")"
          )

          schedule(300, function()
            downloadNext(retry + 1)
          end)

          return
        end

        finishTimeout()
        print("[PVP99] ERRO baixando: " .. rel)
        print("[PVP99] " .. tostring(err))
        return
      end

      local writeOk, writeErr = pcall(function()
        g_resources.writeFileContents(target, data)
      end)

      if not writeOk or not g_resources.fileExists(target) then
        finishTimeout()
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

print("[PVP99] Buscando manifest Book-World...")

HTTP.get(MANIFEST_URL, function(data, err)
  if err or not data or data == "" then
    finishTimeout()
    print("[PVP99] Nao foi possivel baixar o manifest.")
    print("[PVP99] " .. tostring(err))
    return
  end

  local chunk, loadErr = loadstring(data)

  if not chunk then
    finishTimeout()
    print("[PVP99] Manifest com erro Lua:")
    print("[PVP99] " .. tostring(loadErr))
    return
  end

  local ok, manifest = pcall(chunk)

  if not ok then
    finishTimeout()
    print("[PVP99] Erro executando manifest:")
    print("[PVP99] " .. tostring(manifest))
    return
  end

  installManifest(manifest)
end)

-- PVP99 - BANDIT INSTALLER
local PRODUCT_LABEL = "BANDIT"
local REMOTE_ROOT = "Bandit"
local TARGET_NAME = "Bandit"
local OWNER = "oficiallpvp99"
local REPO = "PVP99-Dist"
local BRANCH = "main"
local MAX_RETRIES = 3

local function encodeUrlPath(path)
  return tostring(path or ""):gsub("([^%w%-%._~/])", function(c)
    return string.format("%%%02X", string.byte(c))
  end)
end

local BASE_URL = "https://raw.githubusercontent.com/" .. OWNER .. "/" .. REPO .. "/refs/heads/" .. BRANCH .. "/" .. encodeUrlPath(REMOTE_ROOT) .. "/"
local MANIFEST_URL = BASE_URL .. "manifest.lua"
local VIRTUAL_ROOT = "/bot/" .. TARGET_NAME
local COMPLETE_MARKER = VIRTUAL_ROOT .. "/.pvp99_complete"
local oldTimeout = HTTP.timeout
HTTP.timeout = math.max(HTTP.timeout or 5, 15)

local function restoreTimeout() HTTP.timeout = oldTimeout or 5 end
local function safeRelativePath(path)
  if type(path) ~= "string" or path == "" or path:sub(1,1)=="/" or path:find("\\",1,true) or path:find(":",1,true) then return false end
  for part in path:gmatch("[^/]+") do if part=="." or part==".." or part=="" then return false end end
  return true
end
local function ensureDir(path)
  if not g_resources.directoryExists(path) then g_resources.makeDir(path) end
  return g_resources.directoryExists(path)
end
local function prepareDirectories(manifest)
  if not ensureDir("/bot") or not ensureDir(VIRTUAL_ROOT) then return false end
  for _, rel in ipairs(manifest.directories or {}) do
    if not safeRelativePath(rel) then return false end
    local current=VIRTUAL_ROOT
    for part in rel:gmatch("[^/]+") do current=current.."/"..part; if not ensureDir(current) then return false end end
  end
  return true
end
local function removeOldMarker() if g_resources.fileExists(COMPLETE_MARKER) then g_resources.deleteFile(COMPLETE_MARKER) end end
local function writeMarker()
  g_resources.writeFileContents(COMPLETE_MARKER, "PVP99_OK:" .. tostring((os.time and os.time()) or 0))
  return g_resources.fileExists(COMPLETE_MARKER)
end
local function findRootLua(manifest)
  for _, rel in ipairs(manifest.files or {}) do if type(rel)=="string" and not rel:find("/",1,true) and rel:lower():match("%.lua$") then return rel end end
end
local function install(manifest)
  if type(manifest)~="table" or type(manifest.files)~="table" then restoreTimeout(); print("[PVP99] Manifest invalido."); return end
  local rootLua=findRootLua(manifest); if not rootLua then restoreTimeout(); print("[PVP99] ERRO: nenhum Lua na raiz."); return end
  if not prepareDirectories(manifest) then restoreTimeout(); print("[PVP99] ERRO criando pastas."); return end
  removeOldMarker()
  local list=manifest.files; local total=#list; local index=1
  print("[PVP99] Instalando "..PRODUCT_LABEL.."...")
  local function nextFile(retry)
    local rel=list[index]
    if not rel then
      restoreTimeout()
      if not g_resources.fileExists(VIRTUAL_ROOT.."/"..rootLua) then print("[PVP99] ERRO: Lua principal ausente."); return end
      if not writeMarker() then print("[PVP99] ERRO criando marcador."); return end
      print("[PVP99] "..PRODUCT_LABEL.." instalado com sucesso.")
      print("[PVP99] Desligue e ligue o Bot.")
      return
    end
    if not safeRelativePath(rel) then restoreTimeout(); print("[PVP99] Caminho invalido: "..tostring(rel)); return end
    retry=retry or 0
    HTTP.get(BASE_URL..encodeUrlPath(rel), function(data, err)
      if err or data==nil then
        if retry<MAX_RETRIES then schedule(300,function() nextFile(retry+1) end); return end
        restoreTimeout(); print("[PVP99] ERRO baixando: "..rel); return
      end
      local ok=pcall(function() g_resources.writeFileContents(VIRTUAL_ROOT.."/"..rel,data) end)
      if not ok or not g_resources.fileExists(VIRTUAL_ROOT.."/"..rel) then restoreTimeout(); print("[PVP99] ERRO gravando: "..rel); return end
      index=index+1; schedule(10,function() nextFile(0) end)
    end)
  end
  nextFile(0)
end
HTTP.get(MANIFEST_URL, function(data, err)
  if err or not data or data=="" then restoreTimeout(); print("[PVP99] Erro manifest: "..tostring(err)); return end
  local chunk, loadErr=loadstring(data); if not chunk then restoreTimeout(); print("[PVP99] Manifest Lua: "..tostring(loadErr)); return end
  local ok, manifest=pcall(chunk); if not ok then restoreTimeout(); print("[PVP99] Manifest exec: "..tostring(manifest)); return end
  install(manifest)
end)

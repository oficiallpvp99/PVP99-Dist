-- ============================================================
-- PVP99 BOT MANAGER V2 - COMPACTO
-- Lista remota via catalog.lua
-- Nao altera o cliente OTCv8.
-- ============================================================

local BASE_URL =
  "https://raw.githubusercontent.com/oficiallpvp99/PVP99-Dist/refs/heads/main/"

local CATALOG_URL = BASE_URL .. "catalog.lua"

-- Fallback: se catalog.lua ainda nao estiver no GitHub,
-- o Book World continua aparecendo.
local FALLBACK_CATALOG = {
  {
    name = "BOOK WORLD",
    folder = "Book-World",
    version = "1.0",
    installer = "Book-World/installer.lua",
    enabled = true
  }
}

local root = g_ui.getRootWidget()
if not root then return end

local old = root:recursiveGetChildById("pvp99BotManagerV2")
if old then
  old:destroy()
end

g_ui.loadUIFromString([[
PVP99CompactRow < Panel
  height: 38
  margin-top: 3
  margin-bottom: 3
  background-color: #17131f
  border-width: 1
  border-color: #4b315f

  Label
    id: botName
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    margin-left: 12
    color: #e486ff
    font: verdana-11px-rounded
    text-auto-resize: true

  Label
    id: botVersion
    anchors.right: action.left
    anchors.verticalCenter: parent.verticalCenter
    margin-right: 10
    color: #7f7188
    font: verdana-11px-rounded
    text-auto-resize: true

  Button
    id: action
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    margin-right: 6
    size: 112 28
    text: BAIXAR
    color: #ffffff
    background-color: #43245d
    border-width: 1
    border-color: #a85fd1

PVP99ManagerWindowV2 < MainWindow
  id: pvp99BotManagerV2
  size: 460 360
  text: PVP99 BOT MANAGER
  @onEscape: self:hide()

  Panel
    id: topBar
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: 52
    margin-top: 32
    margin-left: 12
    margin-right: 12
    background-color: #17131f
    border-width: 1
    border-color: #6b3f8f

    Label
      id: brand
      anchors.top: parent.top
      anchors.horizontalCenter: parent.horizontalCenter
      margin-top: 7
      text: PVP99
      color: #d96cff
      font: verdana-11px-rounded
      text-auto-resize: true

    Label
      id: subtitle
      anchors.bottom: parent.bottom
      anchors.horizontalCenter: parent.horizontalCenter
      margin-bottom: 7
      text: BOTS DISPONIVEIS
      color: #c9b6d8
      font: verdana-11px-rounded
      text-auto-resize: true

  Panel
    id: licenseBar
    anchors.top: topBar.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    height: 34
    margin-top: 8
    margin-left: 12
    margin-right: 12
    background-color: #121018
    border-width: 1
    border-color: #3f3150

    Label
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      margin-left: 10
      text: LICENCA
      color: #e486ff
      font: verdana-11px-rounded
      text-auto-resize: true

    Label
      id: licenseStatus
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      margin-right: 10
      text: NAO VINCULADA
      color: #ffd36b
      font: verdana-11px-rounded
      text-auto-resize: true

  VerticalList
    id: botList
    anchors.top: licenseBar.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: statusBar.top
    margin-top: 8
    margin-left: 12
    margin-right: 12
    margin-bottom: 8
    background-color: #0e0b12
    border-width: 1
    border-color: #3f3150
    padding: 4

  Panel
    id: statusBar
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: closeButton.top
    height: 28
    margin-left: 12
    margin-right: 12
    margin-bottom: 7
    background-color: #121018
    border-width: 1
    border-color: #3f3150

    Label
      id: status
      anchors.centerIn: parent
      text: CARREGANDO CATALOGO...
      color: #ffd36b
      font: verdana-11px-rounded
      text-auto-resize: true

  Button
    id: closeButton
    anchors.bottom: parent.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    margin-bottom: 10
    size: 120 30
    text: FECHAR
    color: #ffffff
    background-color: #2b2134
    border-width: 1
    border-color: #6b3f8f
]])

local window = UI.createWindow("PVP99ManagerWindowV2", root)
if not window then return end

local botList = window:recursiveGetChildById("botList")
local status = window:recursiveGetChildById("status")
local closeButton = window:recursiveGetChildById("closeButton")

local busy = false
local catalog = {}

local function setStatus(text, color)
  if not status then return end
  status:setText(text)
  if color then
    status:setColor(color)
  end
end

local function isInstalled(folder)
  if type(folder) ~= "string" or folder == "" then
    return false
  end
  return g_resources.directoryExists("/bot/" .. folder)
end

local function installBot(entry, button)
  if busy then return end
  if not entry or not entry.installer then return end

  busy = true

  if button then
    button:setText("AGUARDE...")
    button:setEnabled(false)
  end

  setStatus("BAIXANDO " .. entry.name .. "...", "#ffd36b")

  HTTP.get(BASE_URL .. entry.installer, function(script, err)
    if err or not script or script == "" then
      busy = false

      if button then
        button:setText(isInstalled(entry.folder) and "ATUALIZAR" or "BAIXAR")
        button:setEnabled(true)
      end

      setStatus("ERRO AO BAIXAR " .. entry.name, "#ff6b8a")
      print("[PVP99] " .. tostring(err))
      return
    end

    local fn, loadErr = loadstring(script)

    if not fn then
      busy = false

      if button then
        button:setText(isInstalled(entry.folder) and "ATUALIZAR" or "BAIXAR")
        button:setEnabled(true)
      end

      setStatus("ERRO NO INSTALADOR", "#ff6b8a")
      print("[PVP99] " .. tostring(loadErr))
      return
    end

    local ok, runErr = pcall(fn)
    busy = false

    if not ok then
      if button then
        button:setText(isInstalled(entry.folder) and "ATUALIZAR" or "BAIXAR")
        button:setEnabled(true)
      end

      setStatus("ERRO AO EXECUTAR", "#ff6b8a")
      print("[PVP99] " .. tostring(runErr))
      return
    end

    if button then
      button:setText("ATUALIZAR")
      button:setEnabled(true)
    end

    setStatus(entry.name .. " - INSTALADOR INICIADO", "#64ffb5")
  end)
end

local function renderCatalog(items)
  catalog = items or {}

  if not botList then return end
  botList:destroyChildren()

  local visibleCount = 0

  for _, entry in ipairs(catalog) do
    if entry.enabled ~= false
      and type(entry.name) == "string"
      and type(entry.folder) == "string"
      and type(entry.installer) == "string" then

      local row = g_ui.createWidget("PVP99CompactRow", botList)
      row.botWidget = true

      local name = row:recursiveGetChildById("botName")
      local version = row:recursiveGetChildById("botVersion")
      local action = row:recursiveGetChildById("action")

      if name then
        name:setText(entry.name)
      end

      if version then
        if entry.version and entry.version ~= "" then
          version:setText("V" .. entry.version)
        else
          version:setText("")
        end
      end

      if action then
        action:setText(isInstalled(entry.folder) and "ATUALIZAR" or "BAIXAR")

        action.onClick = function()
          installBot(entry, action)
        end
      end

      visibleCount = visibleCount + 1
    end
  end

  if visibleCount == 0 then
    setStatus("NENHUM BOT DISPONIVEL", "#ff6b8a")
  else
    setStatus(visibleCount .. " BOT(S) DISPONIVEL(IS)", "#64ffb5")
  end
end

local function loadCatalog()
  setStatus("CARREGANDO CATALOGO...", "#ffd36b")

  HTTP.get(CATALOG_URL, function(data, err)
    if err or not data or data == "" then
      print("[PVP99] catalog.lua indisponivel. Usando fallback.")
      renderCatalog(FALLBACK_CATALOG)
      return
    end

    local fn, loadErr = loadstring(data)

    if not fn then
      print("[PVP99] Erro no catalog.lua: " .. tostring(loadErr))
      renderCatalog(FALLBACK_CATALOG)
      return
    end

    local ok, remoteCatalog = pcall(fn)

    if not ok or type(remoteCatalog) ~= "table" then
      print("[PVP99] catalog.lua invalido.")
      renderCatalog(FALLBACK_CATALOG)
      return
    end

    renderCatalog(remoteCatalog)
  end)
end

if closeButton then
  closeButton.onClick = function()
    if window then
      window:destroy()
      window = nil
    end
  end
end

window:show()
window:raise()
window:focus()

loadCatalog()

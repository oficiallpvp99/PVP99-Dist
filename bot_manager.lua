-- ============================================================
-- PVP99 BOT MANAGER V10 NEON REGISTRA ATIVACAO
-- Firebase Auth + chave de liberacao + 1 instalacao por chave
-- Painel gratuito / downloads liberados por produto
-- ============================================================

local FIREBASE_API_KEY = "AIzaSyBlYZxdTlLeVYmnvX0bkwISq3OzEuxNIdU"
local DATABASE_URL = "https://pvp99-bot-premium-default-rtdb.firebaseio.com"
local DIST_BASE = "https://raw.githubusercontent.com/oficiallpvp99/PVP99-Dist/refs/heads/main/"

local PURCHASE_URLS = {
  book_world = "https://www.pvp99.com.br/2026/09/book-world.html"
}

local AUTH_SIGNUP =
  "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=" .. FIREBASE_API_KEY

local AUTH_SIGNIN =
  "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=" .. FIREBASE_API_KEY

local SETTINGS_EMAIL = "pvp99_bot_device_email"
local SETTINGS_PASSWORD = "pvp99_bot_device_password"
local SETTINGS_LICENSE = "pvp99_bot_license_key"

local root = g_ui.getRootWidget()
if not root then return end

local old = root:recursiveGetChildById("pvp99BotManagerV10")
if old then
  old:destroy()
end

g_ui.loadUIFromString([[
PVP99PremiumRow < Panel
  height: 40
  margin-top: 3
  margin-bottom: 3
  background-color: #100b16
  border-width: 1
  border-color: #7338a0

  Panel
    anchors.left: parent.left
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    width: 3
    background-color: #d96cff

  Label
    id: botName
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    margin-left: 12
    color: #f09bff
    font: verdana-11px-rounded
    text-auto-resize: true

  Label
    id: botPrice
    anchors.right: action.left
    anchors.verticalCenter: parent.verticalCenter
    margin-right: 10
    color: #ffd66b
    font: verdana-11px-rounded
    text-auto-resize: true

  Button
    id: action
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    margin-right: 6
    size: 105 28
    text: COMPRAR
    color: #ffffff
    background-color: #2a2130
    border-width: 1
    border-color: #9b52c7

PVP99ManagerWindowV10 < MainWindow
  id: pvp99BotManagerV10
  size: 480 430
  text: PVP99 BOT MANAGER
  @onEscape: self:hide()

  Panel
    id: topBar
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: 58
    margin-top: 32
    margin-left: 12
    margin-right: 12
    background-color: #0d0813
    border-width: 1
    border-color: #b14ee0

    Label
      anchors.top: parent.top
      anchors.horizontalCenter: parent.horizontalCenter
      margin-top: 7
      text: BOT PREMIUM 2027
      color: #e86fff
      font: verdana-11px-rounded
      text-auto-resize: true

    Label
      id: expiryInfo
      anchors.bottom: parent.bottom
      anchors.horizontalCenter: parent.horizontalCenter
      margin-bottom: 9
      text: LICENCA NAO ATIVADA
      color: #cbb5d9
      font: verdana-11px-rounded
      text-auto-resize: true

    Panel
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      height: 2
      background-color: #d96cff

  Panel
    id: licensePanel
    anchors.top: topBar.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    height: 76
    margin-top: 8
    margin-left: 12
    margin-right: 12
    background-color: #100b16
    border-width: 1
    border-color: #70408b

    Panel
      anchors.left: parent.left
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      width: 3
      background-color: #8d44b5

    Label
      id: licenseLabel
      anchors.top: parent.top
      anchors.left: parent.left
      margin-top: 8
      margin-left: 12
      text: CODIGO DE LIBERACAO
      color: #f09bff
      font: verdana-11px-rounded
      text-auto-resize: true

    Label
      id: licenseStatus
      anchors.top: parent.top
      anchors.right: parent.right
      margin-top: 8
      margin-right: 10
      text: NAO ATIVADO
      color: #ffd36b
      font: verdana-11px-rounded
      text-auto-resize: true

    TextEdit
      id: licenseInput
      anchors.left: parent.left
      anchors.bottom: parent.bottom
      margin-left: 10
      margin-bottom: 10
      size: 310 28
      text: ""
      color: #272727

    Button
      id: activateButton
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      margin-right: 10
      margin-bottom: 10
      size: 120 28
      text: ATIVAR
      color: #ffffff
      background-color: #53276d
      border-width: 1
      border-color: #e86fff

  VerticalList
    id: botList
    anchors.top: licensePanel.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: statusBar.top
    margin-top: 8
    margin-left: 12
    margin-right: 12
    margin-bottom: 8
    background-color: #09060d
    border-width: 1
    border-color: #713a91
    padding: 4

  Panel
    id: statusBar
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: closeButton.top
    height: 30
    margin-left: 12
    margin-right: 12
    margin-bottom: 7
    background-color: #0d0a12
    border-width: 1
    border-color: #5d3374

    Label
      id: status
      anchors.centerIn: parent
      text: CONECTANDO AO FIREBASE...
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
    background-color: #241a2c
    border-width: 1
    border-color: #a950d1
]])

local window = UI.createWindow("PVP99ManagerWindowV10", root)
if not window then return end

local botList = window:recursiveGetChildById("botList")
local status = window:recursiveGetChildById("status")
local licenseInput = window:recursiveGetChildById("licenseInput")
local licenseStatus = window:recursiveGetChildById("licenseStatus")
local expiryInfo = window:recursiveGetChildById("expiryInfo")
local activateButton = window:recursiveGetChildById("activateButton")
local closeButton = window:recursiveGetChildById("closeButton")

local auth = {
  token = nil,
  uid = nil
}

local products = {}
local rows = {}
local activeLicense = nil
local activeLicenseKey = nil
local busy = false

local function setStatus(text, color)
  if not status then return end
  status:setText(text)
  if color then status:setColor(color) end
end

local function setLicenseStatus(text, color)
  if not licenseStatus then return end
  licenseStatus:setText(text)
  if color then licenseStatus:setColor(color) end
end

local function formatExpiryDate(expiresAt)
  expiresAt = tonumber(expiresAt) or 0

  if expiresAt <= 0 then
    return "USO: PERMANENTE"
  end

  local now = os.time and os.time() or 0
  local remaining = expiresAt - now

  if remaining <= 0 then
    return "LICENCA EXPIRADA"
  end

  local days = math.ceil(remaining / 86400)

  if days <= 1 then
    if os.date then
      return "EXPIRA EM 1 DIA - " .. os.date("%d/%m/%Y", expiresAt)
    end
    return "EXPIRA EM 1 DIA"
  end

  if os.date then
    return "EXPIRA EM " .. days .. " DIAS - " .. os.date("%d/%m/%Y", expiresAt)
  end

  return "EXPIRA EM " .. days .. " DIAS"
end

local function refreshExpiryInfo()
  if not expiryInfo then return end

  if type(activeLicense) ~= "table" then
    expiryInfo:setText("LICENCA NAO ATIVADA")
    expiryInfo:setColor("#cbb5d9")
    return
  end

  local expiresAt = tonumber(activeLicense.expiresAt) or 0

  if expiresAt > 0 and os.time and os.time() >= expiresAt then
    expiryInfo:setText("LICENCA EXPIRADA")
    expiryInfo:setColor("#ff6b8a")
    return
  end

  expiryInfo:setText(formatExpiryDate(expiresAt))
  if expiresAt == 0 then
    expiryInfo:setColor("#64ffb5")
  else
    expiryInfo:setColor("#ffd36b")
  end
end

local function normalizeKey(value)
  value = tostring(value or "")
  value = value:gsub("%s+", "")
  value = value:upper()

  if value == "" then
    return nil
  end

  if not value:match("^[A-Z0-9_%%-]+$") then
    return nil
  end

  return value
end

local function makeRandomId()
  local raw = nil

  if g_crypt and g_crypt.genUUID then
    raw = g_crypt.genUUID()
  end

  if not raw or raw == "" then
    local stamp = os.time and os.time() or 0
    raw = tostring(stamp) .. "-" .. tostring(math.random(100000, 999999))
  end

  raw = raw:gsub("[^%w]", "")
  return raw:lower()
end

local function getDeviceCredentials()
  local email = g_settings.getString(SETTINGS_EMAIL)
  local password = g_settings.getString(SETTINGS_PASSWORD)

  if email and email ~= "" and password and password ~= "" then
    return email, password
  end

  local id = makeRandomId()
  email = "device_" .. id .. "@pvp99bot.com"
  password = "Pvp99!" .. makeRandomId() .. "A9"

  g_settings.set(SETTINGS_EMAIL, email)
  g_settings.set(SETTINGS_PASSWORD, password)
  g_settings.save()

  return email, password
end

local function setAuth(data)
  if type(data) ~= "table" then return false end
  if not data.idToken or not data.localId then return false end

  auth.token = data.idToken
  auth.uid = data.localId
  return true
end

local function firebasePath(path)
  return DATABASE_URL .. "/" .. path .. ".json?auth=" .. auth.token
end

local function installMarker(folder)
  return "/bot/" .. tostring(folder or "") .. "/.pvp99_complete"
end

local function isInstalled(folder)
  if type(folder) ~= "string" or folder == "" then
    return false
  end

  return g_resources.directoryExists("/bot/" .. folder)
    and g_resources.fileExists(installMarker(folder))
end

local function priceText(price)
  local value = tonumber(price) or 65
  return string.format("R$ %.2f", value):gsub("%.", ",")
end

local function getBindingUid(license)
  if type(license) ~= "table" or type(license.binding) ~= "table" then
    return nil
  end

  for _, binding in pairs(license.binding) do
    if type(binding) == "table" and binding.uid then
      return tostring(binding.uid)
    end
  end

  return nil
end

local function licenseExpired(license)
  if type(license) ~= "table" then return true end

  local expiresAt = tonumber(license.expiresAt) or 0

  if expiresAt == 0 then
    return false
  end

  if os.time then
    return os.time() >= expiresAt
  end

  return false
end

local function productAllowed(productId)
  if type(activeLicense) ~= "table" then
    return false
  end

  if activeLicense.active ~= true then
    return false
  end

  if licenseExpired(activeLicense) then
    return false
  end

  if getBindingUid(activeLicense) ~= auth.uid then
    return false
  end

  return type(activeLicense.products) == "table"
    and activeLicense.products[productId] == true
end

local function getPurchaseUrl(productId)
  local entry = products[productId]

  if type(entry) == "table"
    and type(entry.buyUrl) == "string"
    and entry.buyUrl ~= "" then
    return entry.buyUrl
  end

  return PURCHASE_URLS[productId]
end

local function openPurchasePage(productId)
  local url = getPurchaseUrl(productId)

  if not url or url == "" then
    setStatus("PAGINA DE COMPRA AINDA NAO CONFIGURADA", "#ffd36b")
    return
  end

  setStatus("ABRINDO PAGINA DE COMPRA...", "#64ffb5")

  if g_platform and g_platform.openUrl then
    g_platform.openUrl(url)
  else
    setStatus("NAO FOI POSSIVEL ABRIR O NAVEGADOR", "#ff6b8a")
  end
end

local function hasDownloadedAllowedProduct()
  for productId, entry in pairs(products) do
    if productAllowed(productId)
      and type(entry) == "table"
      and isInstalled(entry.folder) then
      return true
    end
  end

  return false
end

local function refreshRows()
  for productId, item in pairs(rows) do
    local entry = products[productId]
    local allowed = productAllowed(productId)

    if item and item.action and entry then
      if allowed then
        item.action:setEnabled(true)

        if isInstalled(entry.folder) then
          item.action:setText("BAIXADO")
          item.action:setColor("#64ffb5")
          item.action:setBackgroundColor("#173326")
        else
          item.action:setText("BAIXAR")
          item.action:setColor("#ffffff")
          item.action:setBackgroundColor("#43245d")
        end
      else
        item.action:setEnabled(true)
        item.action:setText("COMPRAR")
        item.action:setColor("#ffffff")
        item.action:setBackgroundColor("#53276d")
      end
    end
  end
end

local function waitForInstallComplete(productId, entry, attempts)
  attempts = attempts or 0

  if isInstalled(entry.folder) then
    busy = false
    refreshRows()
    setStatus("BAIXADO COM SUCESSO - DESLIGUE O BOT", "#64ffb5")
    return
  end

  if attempts >= 240 then
    busy = false
    refreshRows()
    setStatus("DOWNLOAD AINDA NAO FOI CONFIRMADO", "#ffd36b")
    return
  end

  schedule(500, function()
    waitForInstallComplete(productId, entry, attempts + 1)
  end)
end

local function runInstaller(productId)
  local entry = products[productId]

  if not entry or not productAllowed(productId) then
    setStatus("ATIVE UMA CHAVE QUE LIBERE ESTE BOT", "#ff6b8a")
    return
  end

  if isInstalled(entry.folder) then
    setStatus("JA BAIXADO - DESLIGUE O BOT", "#64ffb5")
    return
  end

  if busy then return end
  busy = true

  local row = rows[productId]
  if row and row.action then
    row.action:setEnabled(false)
    row.action:setColor("#ffd36b")
    row.action:setText("BAIXANDO...")
  end

  setStatus("INICIANDO DOWNLOAD DE " .. tostring(entry.name or productId) .. "...", "#ffd36b")

  HTTP.get(DIST_BASE .. tostring(entry.installer or ""), function(script, err)
    if err or not script or script == "" then
      busy = false
      setStatus("ERRO AO BAIXAR INSTALADOR", "#ff6b8a")
      refreshRows()
      return
    end

    local fn, loadErr = loadstring(script)

    if not fn then
      busy = false
      print("[PVP99] " .. tostring(loadErr))
      setStatus("ERRO NO INSTALADOR", "#ff6b8a")
      refreshRows()
      return
    end

    local ok, runErr = pcall(fn)

    if not ok then
      busy = false
      print("[PVP99] " .. tostring(runErr))
      setStatus("ERRO AO EXECUTAR INSTALADOR", "#ff6b8a")
      refreshRows()
      return
    end

    setStatus("BAIXANDO ARQUIVOS... AGUARDE", "#ffd36b")
    waitForInstallComplete(productId, entry, 0)
  end)
end

local function renderProducts(data)
  products = type(data) == "table" and data or {}
  rows = {}

  if not botList then return end
  botList:destroyChildren()

  local ordered = {}

  for id, entry in pairs(products) do
    if type(entry) == "table" and entry.active ~= false then
      table.insert(ordered, {
        id = id,
        data = entry
      })
    end
  end

  table.sort(ordered, function(a, b)
    return tostring(a.data.name or a.id) < tostring(b.data.name or b.id)
  end)

  for _, item in ipairs(ordered) do
    local productId = item.id
    local entry = item.data
    local row = g_ui.createWidget("PVP99PremiumRow", botList)
    row.botWidget = true

    local name = row:recursiveGetChildById("botName")
    local price = row:recursiveGetChildById("botPrice")
    local action = row:recursiveGetChildById("action")

    if name then
      name:setText(tostring(entry.name or productId))
    end

    if price then
      price:setText(priceText(entry.price))
    end

    rows[productId] = {
      row = row,
      action = action
    }

    if action then
      action.onClick = function()
        if productAllowed(productId) then
          runInstaller(productId)
        else
          openPurchasePage(productId)
        end
      end
    end
  end

  refreshRows()

  if #ordered == 0 then
    setStatus("NENHUM BOT DISPONIVEL", "#ff6b8a")
  else
    setStatus(#ordered .. " BOT(S) DISPONIVEL(IS)", "#64ffb5")
  end
end

local function loadProducts(done)
  HTTP.getJSON(firebasePath("products"), function(data, err)
    if err or type(data) ~= "table" then
      print("[PVP99] Erro products: " .. tostring(err))
      setStatus("ERRO AO CARREGAR CATALOGO", "#ff6b8a")
      return
    end

    renderProducts(data)

    if done then done() end
  end)
end

local function applyAuthorizedLicense(key, license)
  activeLicenseKey = key
  activeLicense = license

  g_settings.set(SETTINGS_LICENSE, key)
  g_settings.save()

  if licenseInput then
    licenseInput:setText(key)
  end

  setLicenseStatus("ATIVA", "#64ffb5")
  refreshExpiryInfo()
  refreshRows()

  if hasDownloadedAllowedProduct() then
    setStatus("BAIXADO COM SUCESSO - DESLIGUE O BOT", "#64ffb5")
  else
    setStatus("LICENCA LIBERADA NESTA INSTALACAO", "#64ffb5")
  end
end

local function checkLicense(key, allowBind)
  if not auth.token or not auth.uid then
    setStatus("FIREBASE AINDA NAO CONECTADO", "#ff6b8a")
    return
  end

  key = normalizeKey(key)

  if not key then
    setLicenseStatus("CODIGO INVALIDO", "#ff6b8a")
    setStatus("DIGITE UMA CHAVE VALIDA", "#ff6b8a")
    return
  end

  setLicenseStatus("VERIFICANDO...", "#ffd36b")

  HTTP.getJSON(firebasePath("licenses/" .. key), function(license, err)
    if err or type(license) ~= "table" then
      setLicenseStatus("INVALIDA", "#ff6b8a")
      setStatus("CHAVE NAO ENCONTRADA", "#ff6b8a")
      return
    end

    if license.active ~= true then
      setLicenseStatus("INATIVA", "#ff6b8a")
      setStatus("LICENCA INATIVA", "#ff6b8a")
      return
    end

    if licenseExpired(license) then
      setLicenseStatus("EXPIRADA", "#ff6b8a")
      setStatus("LICENCA EXPIRADA", "#ff6b8a")
      return
    end

    local boundUid = getBindingUid(license)

    if boundUid then
      if boundUid == auth.uid then
        applyAuthorizedLicense(key, license)
      else
        activeLicense = nil
        activeLicenseKey = nil
        refreshExpiryInfo()
        setLicenseStatus("OUTRO DISPOSITIVO", "#ff6b8a")
        setStatus("CHAVE JA VINCULADA A OUTRA INSTALACAO", "#ff6b8a")
        refreshRows()
      end

      return
    end

    if not allowBind then
      setLicenseStatus("NAO ATIVADA", "#ffd36b")
      return
    end

    setLicenseStatus("VINCULANDO...", "#ffd36b")

    local activationTime = 0
    if os.time then
      activationTime = os.time()
    end

    HTTP.postJSON(
      firebasePath("licenses/" .. key .. "/binding"),
      {
        uid = auth.uid,
        activatedAt = activationTime
      },
      function(result, bindErr)
        if bindErr then
          print("[PVP99] Erro binding: " .. tostring(bindErr))
          setLicenseStatus("BLOQUEADA", "#ff6b8a")
          setStatus("NAO FOI POSSIVEL VINCULAR A CHAVE", "#ff6b8a")
          return
        end

        -- Reconsulta para confirmar o vinculo salvo no servidor.
        HTTP.getJSON(firebasePath("licenses/" .. key), function(updated, readErr)
          if readErr or type(updated) ~= "table" then
            setLicenseStatus("ERRO", "#ff6b8a")
            setStatus("ERRO AO CONFIRMAR ATIVACAO", "#ff6b8a")
            return
          end

          if getBindingUid(updated) == auth.uid then
            applyAuthorizedLicense(key, updated)
          else
            setLicenseStatus("BLOQUEADA", "#ff6b8a")
            setStatus("ATIVACAO RECUSADA", "#ff6b8a")
          end
        end)
      end
    )
  end)
end

local function loadSavedLicense()
  local saved = g_settings.getString(SETTINGS_LICENSE)

  if saved and saved ~= "" then
    if licenseInput then
      licenseInput:setText(saved)
    end

    checkLicense(saved, false)
  else
    refreshExpiryInfo()
    setLicenseStatus("NAO ATIVADO", "#ffd36b")
  end
end

local function authenticateDevice(done)
  local email, password = getDeviceCredentials()

  local payload = {
    email = email,
    password = password,
    returnSecureToken = true
  }

  setStatus("AUTENTICANDO DISPOSITIVO...", "#ffd36b")

  HTTP.postJSON(AUTH_SIGNIN, payload, function(data, err)
    if not err and setAuth(data) then
      setStatus("DISPOSITIVO AUTENTICADO", "#64ffb5")
      done()
      return
    end

    -- Primeiro uso: cria a conta tecnica desta instalacao.
    HTTP.postJSON(AUTH_SIGNUP, payload, function(signupData, signupErr)
      if signupErr or not setAuth(signupData) then
        print("[PVP99] Auth error: " .. tostring(signupErr or err))
        setStatus("ERRO NA AUTENTICACAO FIREBASE", "#ff6b8a")
        setLicenseStatus("OFFLINE", "#ff6b8a")
        refreshExpiryInfo()
        return
      end

      setStatus("DISPOSITIVO REGISTRADO", "#64ffb5")
      done()
    end)
  end)
end

if activateButton then
  activateButton.onClick = function()
    if busy then return end
    checkLicense(licenseInput and licenseInput:getText() or "", true)
  end
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
refreshExpiryInfo()

authenticateDevice(function()
  loadProducts(function()
    loadSavedLicense()
  end)
end)

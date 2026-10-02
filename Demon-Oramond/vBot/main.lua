local version = "4.8"
local currentVersion
local available = false

storage.checkVersion = storage.checkVersion or 0

-- check max once per 12hours
if os.time() > storage.checkVersion + (12 * 60 * 60) then

    storage.checkVersion = os.time()

end

UI.Label("Comprem scripts no site")
UI.Button("www.pvp99.com.br", function() g_platform.openUrl("https://www.pvp99.com.br/") end)
UI.Separator()

schedule(5000, function()

    if not available then return end
    if currentVersion ~= version then
        
        UI.Separator()
        UI.Label("New vBot is available for download! v"..currentVersion)
        UI.Button("Buy Script", function() g_platform.openUrl("https://www.pvp99.com.br/") end)
        UI.Separator()
        
    end

end)

setDefaultTab("MAIN")

local name = UI.Label(">> Script Demon Oramond Atualizado<<")

macro(800, function()
  local rainbowDelay = 0 

  for k, color in ipairs({"#990af2", "#9200b3", "#0077b3", "#005c99", "#5e0080", "#e80036"}) do
    schedule(rainbowDelay, function()
      name:setColor(color) 
    end)

    rainbowDelay = rainbowDelay + 100
  end
end, SpellsTab)

UI.Separator()

local name = UI.Label(">>CURAS<<")

-- ============================================================
-- PVP99 - HEALING SYSTEM
-- Mantém a lógica original / 3 curas / 250ms
-- ============================================================

-- Efeito de cor do título
macro(800, function()
  local colors = {
    "#990af2",
    "#9200b3",
    "#0077b3",
    "#005c99",
    "#5e0080",
    "#e80036"
  }

  local rainbowDelay = 0

  for _, color in ipairs(colors) do
    schedule(rainbowDelay, function()
      if name then
        name:setColor(color)
      end
    end)

    rainbowDelay = rainbowDelay + 100
  end
end, SpellsTab)


-- ============================================================
-- CONFIGURAÇÕES
-- ============================================================

if type(storage.healing1) ~= "table" then
  storage.healing1 = {
    on = false,
    title = "HP%",
    text = "exura ico",
    min = 51,
    max = 90
  }
end

if type(storage.healing2) ~= "table" then
  storage.healing2 = {
    on = false,
    title = "HP%",
    text = "exura ico",
    min = 0,
    max = 50
  }
end

if type(storage.healing3) ~= "table" then
  storage.healing3 = {
    on = false,
    title = "HP%",
    text = "exura med ico",
    min = 0,
    max = 50
  }
end


-- ============================================================
-- SISTEMA DE CURA
-- ============================================================

local healingConfigs = {
  storage.healing1,
  storage.healing2,
  storage.healing3
}

for _, config in ipairs(healingConfigs) do

  -- Mantém uma configuração separada para cada macro
  local healingInfo = config

  local healingMacro = macro(250, function()

    if not player then
      return
    end

    local hp = player:getHealthPercent()

    if hp >= healingInfo.min and hp <= healingInfo.max then

      if healingInfo.text and healingInfo.text ~= "" then

        if TargetBot and TargetBot.saySpell then
          TargetBot.saySpell(healingInfo.text)
        else
          say(healingInfo.text)
        end

      end
    end
  end)

  healingMacro.setOn(healingInfo.on)


  -- Painel de configuração
  UI.DualScrollPanel(healingInfo, function(widget, newParams)

    healingInfo = newParams

    healingMacro.setOn(healingInfo.on)

  end)
end

UI.Separator()

local name = UI.Label(">>CURA CAV PESADA<<")

-- ============================================================
-- PVP99 POTIONS - COMPACT
-- 1 HP + 1 MANA
-- ============================================================

local potionTitle = UI.Label("PVP99 POTIONS")
potionTitle:setColor("#00E5FF")

-- Efeito de cor no título
local titleColors = {
  "#00E5FF",
  "#009DFF",
  "#7A38FF",
  "#C52BFF",
  "#FF2D8D"
}

local colorIndex = 1

macro(400, function()
  if potionTitle then
    potionTitle:setColor(titleColors[colorIndex])

    colorIndex = colorIndex + 1

    if colorIndex > #titleColors then
      colorIndex = 1
    end
  end
end)


-- ============================================================
-- CONFIGURACAO HP
-- ============================================================

if type(storage.pvp99HpPotion) ~= "table" then
  storage.pvp99HpPotion = {
    on = false,
    title = "HP%",
    item = 3160,
    min = 0,
    max = 70
  }
end


-- ============================================================
-- CONFIGURACAO MANA
-- ============================================================

if type(storage.pvp99ManaPotion) ~= "table" then
  storage.pvp99ManaPotion = {
    on = false,
    title = "MP%",
    item = 268,
    min = 0,
    max = 35
  }
end


-- ============================================================
-- PAINEL HP
-- ============================================================

UI.DualScrollItemPanel(
  storage.pvp99HpPotion,
  function(widget, newParams)
    storage.pvp99HpPotion = newParams
  end
)


-- ============================================================
-- PAINEL MANA
-- ============================================================

UI.DualScrollItemPanel(
  storage.pvp99ManaPotion,
  function(widget, newParams)
    storage.pvp99ManaPotion = newParams
  end
)


-- ============================================================
-- SISTEMA
-- ============================================================

local POTION_DELAY = 250
local EMERGENCY_HP = 30

local lastPotion = 0


-- ============================================================
-- MANA %
-- ============================================================

local function getManaPercent()

  if not player then
    return 100
  end

  local mana = player:getMana()
  local maxMana = player:getMaxMana()

  if not maxMana or maxMana <= 0 then
    return 100
  end

  return math.min(
    100,
    math.floor((mana / maxMana) * 100)
  )
end


-- ============================================================
-- USAR POTION
-- ============================================================

local function usePotion(info)

  if not player then
    return false
  end

  if not info or
     not info.item or
     info.item <= 100 then
    return false
  end


  -- TargetBot
  if TargetBot and TargetBot.useItem then

    TargetBot.useItem(
      info.item,
      info.subType,
      player
    )

    return true
  end


  -- Uso normal
  local thing = g_things.getThingType(info.item)

  local subType =
    g_game.getClientVersion() >= 1100 and 0 or 1


  if thing and thing:isFluidContainer() then
    subType = info.subType
  end


  g_game.useInventoryItemWith(
    info.item,
    player,
    subType
  )

  return true
end


-- ============================================================
-- CONTROLADOR
-- ============================================================

macro(POTION_DELAY, function()

  if not player then
    return
  end


  -- Delay
  if now and lastPotion > 0 then

    if now - lastPotion < POTION_DELAY then
      return
    end

  end


  local hp = player:getHealthPercent()
  local mana = getManaPercent()


  -- ==========================================================
  -- HP PRIMEIRO
  -- ==========================================================

  local hpPotion = storage.pvp99HpPotion

  if hpPotion.on and
     hpPotion.item and
     hpPotion.item > 100 and
     hp >= hpPotion.min and
     hp <= hpPotion.max then

    if usePotion(hpPotion) then

      if now then
        lastPotion = now
      end

      return
    end
  end


  -- ==========================================================
  -- EMERGENCIA HP <= 30%
  -- NAO USA MANA
  -- ==========================================================

  if hp <= EMERGENCY_HP then
    return
  end


  -- ==========================================================
  -- MANA
  -- ==========================================================

  local manaPotion = storage.pvp99ManaPotion

  if manaPotion.on and
     manaPotion.item and
     manaPotion.item > 100 and
     mana >= manaPotion.min and
     mana <= manaPotion.max then

    if usePotion(manaPotion) then

      if now then
        lastPotion = now
      end

      return
    end
  end
end)


local colorTable = {
  ["Werelion"] = "white",
  ["Werelioness"] = "white",
  ["White Lion"] = "white",
  ["Blightwalker"] = "white",
  ["Demon Outcast"] = "white",
  ["Dark Torturer"] = "white",
  ["Lost Soul"] = "white",
  ["Choking Fear"] = "white",
  ["Juggernaut"] = "white",
  ["Retching Horror"] = "white",
  ["Silencer"] = "white",
  ["Retching Horror"] = "white",
  ["Guzzlemaw"] = "white",
  ["Plaguesmith"] = "white",
  ["Juggernaut"] = "orange",
  ["Hellflayer"] = "orange",
}
local monstercolor = macro(10000, function() end)
onCreatureAppear(function(creature)
  if monstercolor:isOff() then creature:setInformationColor('#00cc00') return end
  if creature:isMonster() or creature:isPlayer() then
    local name = creature:getName()
    local color = colorTable[name]

    if color then
      creature:setInformationColor(color)
    end
  end
end)

local qw = modules.game_bot.contentsPanel.config
macro(500, function()
qw:setText("Demon Oramond")
qw:setColor("white")
qw:setFont("verdana-11px-rounded")
schedule(600, function()
  qw:setColor("red")
end)
schedule(800, function()
  qw:setColor("yellow")
end)
schedule(1200, function()
  qw:setColor("orange")
end)
schedule(1400, function()
  qw:setColor("#00FFFF")
end)
end)



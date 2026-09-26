local version = "4.8"
local currentVersion
local available = false

storage.checkVersion = storage.checkVersion or 0

-- check max once per 12hours
if os.time() > storage.checkVersion + (12 * 60 * 60) then

    storage.checkVersion = os.time()
end

UI.Label("Instagram \n @oficialpvp99")
UI.Button("Official Site PVP99!", function() g_platform.openUrl("https://www.pvp99.com.br/") end)
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

local name = UI.Label(">>Book World Profissional<<")

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

macro(800, function()
  local rainbowDelay = 0 

  for k, color in ipairs({"#990af2", "#9200b3", "#0077b3", "#005c99", "#5e0080", "#e80036"}) do
    schedule(rainbowDelay, function()
      name:setColor(color) 
    end)

    rainbowDelay = rainbowDelay + 100
  end
end, SpellsTab)

if type(storage.healing1) ~= "table" then
  storage.healing1 = {
    on=false,
    title="HP%",
    text="exura ico",
    min=51,
    max=90
  }
end

if type(storage.healing2) ~= "table" then
  storage.healing2 = {
    on=false,
    title="HP%",
    text="exura ico",
    min=0,
    max=50
  }
end

if type(storage.healing3) ~= "table" then
  storage.healing3 = {
    on=false,
    title="HP%",
    text="exura med ico",
    min=0,
    max=50
  }
end


-- evita duas curas serem disparadas praticamente juntas
local lastSpellUse = 0


-- create 3 healing widgets
for _, healingInfo in ipairs({
  storage.healing1,
  storage.healing2,
  storage.healing3
}) do

  local healingmacro = macro(250, function()

    local hp = player:getHealthPercent()

    if healingInfo.max >= hp and hp >= healingInfo.min then

      local currentTime = now

      -- evita spam excessivo
      if currentTime - lastSpellUse < 250 then
        return
      end

      lastSpellUse = currentTime

      if TargetBot then 
        TargetBot.saySpell(healingInfo.text)
      else
        say(healingInfo.text)
      end
    end
  end)

  healingmacro.setOn(healingInfo.on)

  UI.DualScrollPanel(healingInfo, function(widget, newParams) 
    healingInfo = newParams
    healingmacro.setOn(healingInfo.on)
  end)
end


UI.Separator()


local name = UI.Label(">>POTIONS<<")

macro(800, function()
  local rainbowDelay = 0 

  for k, color in ipairs({"#990af2", "#9200b3", "#0077b3", "#005c99", "#5e0080", "#e80036"}) do
    schedule(rainbowDelay, function()
      name:setColor(color) 
    end)

    rainbowDelay = rainbowDelay + 100
  end
end, SpellsTab)


if type(storage.hpitem1) ~= "table" then
  storage.hpitem1 = {
    on=false,
    title="HP%",
    item=266,
    min=51,
    max=90
  }
end

if type(storage.hpitem2) ~= "table" then
  storage.hpitem2 = {
    on=false,
    title="HP%",
    item=3160,
    min=0,
    max=50
  }
end

if type(storage.manaitem1) ~= "table" then
  storage.manaitem1 = {
    on=false,
    title="MP%",
    item=268,
    min=51,
    max=90
  }
end

if type(storage.manaitem2) ~= "table" then
  storage.manaitem2 = {
    on=false,
    title="MP%",
    item=3157,
    min=0,
    max=50
  }
end


-- ultimo uso de cada potion
local lastUsed = {}


for i, healingInfo in ipairs({
  storage.hpitem1,
  storage.hpitem2,
  storage.manaitem1,
  storage.manaitem2
}) do

  local healingmacro = macro(250, function()

    local currentTime = now
    local key = healingInfo.item .. "-" .. i

    -- HP ou MP
    local hp

    if i <= 2 then
      hp = player:getHealthPercent()
    else
      hp = math.min(
        100,
        math.floor(
          100 * (player:getMana() / player:getMaxMana())
        )
      )
    end


    -- verifica porcentagem e tempo desde o ultimo uso
    if healingInfo.max >= hp
      and hp >= healingInfo.min
      and (not lastUsed[key] or currentTime - lastUsed[key] >= 250) then

      lastUsed[key] = currentTime


      if TargetBot then 

        TargetBot.useItem(
          healingInfo.item,
          healingInfo.subType,
          player
        )

      else

        local thing = g_things.getThingType(
          healingInfo.item
        )

        local subType =
          g_game.getClientVersion() >= 1100
          and 0
          or 1


        if thing and thing:isFluidContainer() then
          subType = healingInfo.subType
        end


        g_game.useInventoryItemWith(
          healingInfo.item,
          player,
          subType
        )

      end
    end
  end)


  healingmacro.setOn(healingInfo.on)


  UI.DualScrollItemPanel(
    healingInfo,
    function(widget, newParams) 

      healingInfo = newParams

      healingmacro.setOn(
        healingInfo.on and healingInfo.item > 100
      )

    end
  )
end


local colorTable = {
  ["Lion Hydra"] = "yellow",
  ["Bluebeak"] = "yellow",
  ["Headwalker"] = "white",
  ["Arachnophobica"] = "white",
  ["Crusader"] = "yellow",
  ["Hawk Hopper"] = "yellow",
  ["Bramble Wyrmling"] = "yellow",
  ["Crazed Winter Vanguard"] = "blue",
  ["Carniphila"] = "red",
  ["Snake "] = "red",
  ["Wasp"] = "red",
  ["Tarantula"] = "red",
  ["Bug"] = "red",
  ["Tiger"] = "red",
  ["Spider"] = "red",
  ["Cobra"] = "red",
  ["Bat"] = "red",
  ["Fire Elemental"] = "red",
  ["Massive Fire Elemental "] = "red",
  ["Medusa"] = "white",
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

UI.Separator()

local qw = modules.game_bot.contentsPanel.config
macro(500, function()
qw:setText("Book World")
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
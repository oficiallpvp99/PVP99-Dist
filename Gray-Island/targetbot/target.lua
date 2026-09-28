local targetbotMacro = nil
local config = nil
local lastAction = 0
local cavebotAllowance = 0
local lureEnabled = true
local dangerValue = 0
local looterStatus = ""

-- =========================================================
-- TARGET LOCK
-- =========================================================

local lockedTargetId = nil
local lockedTargetLastValid = 0

-- tolerância caso o path falhe rapidamente
local targetLockGrace = 1000


-- =========================================================
-- LOOT PRIORITY
-- =========================================================

-- tempo durante o qual Looting terá prioridade absoluta
-- depois que o monstro morrer/desaparecer
local lootPriorityUntil = 0

-- 900ms costuma ser suficiente para:
-- servidor criar corpse
-- cliente receber corpse
-- looter abrir o corpo
local lootPriorityTime = 900


local function startLootPriority()
  lootPriorityUntil = now + lootPriorityTime
end


local function isLootPriority()
  return lootPriorityUntil > now
end


-- =========================================================
-- UI
-- =========================================================

local configWidget = UI.Config()
local ui = UI.createWidget("TargetBotPanel")

ui.list = ui.listPanel.list

TargetBot.targetList = ui.list

TargetBot.Looting.setup()


ui.status.left:setText("Status:")
ui.status.right:setText("Off")

ui.target.left:setText("Target:")
ui.target.right:setText("-")

ui.config.left:setText("Config:")
ui.config.right:setText("-")

ui.danger.left:setText("Danger:")
ui.danger.right:setText("0")


ui.editor.debug.onClick = function()

  local on = ui.editor.debug:isOn()

  ui.editor.debug:setOn(not on)

  if on then

    for _, spec in ipairs(getSpectators()) do
      spec:clearText()
    end

  end

end


local oldTibia =
  g_game.getClientVersion() < 960


-- =========================================================
-- MAIN LOOP
-- =========================================================

targetbotMacro = macro(100, function()

  local pos = player:getPosition()

  local specs =
    g_map.getSpectatorsInRange(
      pos,
      false,
      6,
      6
    )


  local creatureCount = 0


  for _, spec in ipairs(specs) do

    if spec:isMonster() then
      creatureCount = creatureCount + 1
    end

  end


  -- =====================================================
  -- LIMITA ÁREA QUANDO TEM MUITOS MONSTROS
  -- =====================================================

  local creatures


  if creatureCount > 10 then

    creatures =
      g_map.getSpectatorsInRange(
        pos,
        false,
        3,
        3
      )

  else

    creatures = specs

  end


  -- =====================================================
  -- PROCURA TARGET TRAVADO
  -- =====================================================

  local lockedCreature = nil


  if lockedTargetId then

    for _, spec in ipairs(specs) do

      if spec:isMonster() then

        local hp =
          spec:getHealthPercent()


        if hp
          and hp > 0
          and spec:getId() == lockedTargetId then

          lockedCreature = spec

          break

        end

      end

    end


    -- ===================================================
    -- TARGET AINDA EXISTE
    -- ===================================================

    if lockedCreature then

      local found = false


      for _, creature in ipairs(creatures) do

        if creature:getId() == lockedTargetId then

          found = true

          break

        end

      end


      -- mantém o target travado mesmo se saiu
      -- da área reduzida 3x3

      if not found then

        table.insert(
          creatures,
          lockedCreature
        )

      end


    else

      -- =================================================
      -- TARGET SUMIU
      -- provavelmente morreu
      --
      -- ATIVA PRIORIDADE DO AUTOLOOT
      -- =================================================

      lockedTargetId = nil

      lockedTargetLastValid = 0

      startLootPriority()

    end

  end


  -- =====================================================
  -- CALCULA TARGETS
  -- =====================================================

  local dangerLevel = 0
  local targets = 0

  local highestPriorityParams = nil

  local lockedParams = nil

  local bestParams = nil

  local bestPriority = 0


  for _, creature in ipairs(creatures) do

    local hppc =
      creature:getHealthPercent()


    if hppc and hppc > 0 then

      local path =
        findPath(
          player:getPosition(),
          creature:getPosition(),
          7,
          {
            ignoreLastCreature = true,
            ignoreNonPathable = true,
            ignoreCost = true,
            ignoreCreatures = true
          }
        )


      if creature:isMonster()
        and
        (oldTibia or creature:getType() < 3)
        and
        path then


        local params =
          TargetBot.Creature.calculateParams(
            creature,
            path
          )


        dangerLevel =
          dangerLevel + params.danger


        -- =================================================
        -- TARGET LOCK
        -- =================================================

        if lockedTargetId
          and creature:getId() == lockedTargetId then

          lockedParams = params

          lockedTargetLastValid = now

        end


        -- =================================================
        -- TARGET NORMAL
        -- =================================================

        if params.priority > 0 then

          targets = targets + 1


          if params.priority > bestPriority then

            bestPriority =
              params.priority

            bestParams =
              params

          end


          if ui.editor.debug:isOn() then

            creature:setText(
              params.config.name ..
              "\n" ..
              params.priority
            )

          end

        end

      end

    end

  end


  -- =====================================================
  -- ESCOLHE TARGET TRAVADO
  -- =====================================================

  if lockedTargetId then


    if lockedParams then

      highestPriorityParams =
        lockedParams


    elseif lockedCreature
      and
      lockedTargetLastValid + targetLockGrace > now then

      -- falha momentânea no path
      -- NÃO troca de target

      highestPriorityParams = nil


    else

      lockedTargetId = nil

      lockedTargetLastValid = 0

    end

  end


  -- =====================================================
  -- NÃO ESCOLHE NOVO TARGET DURANTE LOOT PRIORITY
  -- =====================================================

  if not lockedTargetId
    and
    not isLootPriority()
    and
    bestParams then


    highestPriorityParams =
      bestParams

    lockedTargetId =
      bestParams.creature:getId()

    lockedTargetLastValid =
      now

  end


  -- =====================================================
  -- RESET WALKING
  -- =====================================================

  TargetBot.walkTo(nil)


  -- =====================================================
  -- AUTOLOOT
  -- =====================================================

  local looting


  -- =====================================================
  -- LOOT PRIORITY
  --
  -- Durante esses milissegundos fingimos para o Looter
  -- que não existem monstros/danger.
  --
  -- Assim o cadáver é aberto rapidamente mesmo durante
  -- lure com vários monstros vivos.
  -- =====================================================

  if isLootPriority() then

    looting =
      TargetBot.Looting.process(
        0,
        0
      )

  else

    looting =
      TargetBot.Looting.process(
        targets,
        dangerLevel
      )

  end


  local lootingStatus =
    TargetBot.Looting.getStatus()


  looterStatus =
    lootingStatus


  dangerValue =
    dangerLevel


  ui.danger.right:setText(
    dangerLevel
  )


  -- =====================================================
  -- PRIORIDADE ABSOLUTA PARA LOOT
  -- =====================================================

  if isLootPriority() then

    -- durante esse período:
    --
    -- NÃO ataca próximo monster
    -- NÃO libera CaveBot
    -- NÃO começa lure
    --
    -- deixa exclusivamente o Looting trabalhar


    if looting then

      TargetBot.walk()

      lastAction = now

    end


    if lootingStatus
      and
      lootingStatus:len() > 0 then

      TargetBot.setStatus(
        "Looting Priority - " ..
        lootingStatus
      )

    else

      TargetBot.setStatus(
        "Looting Priority"
      )

    end


    return

  end


  -- =====================================================
  -- SE LOOTING JÁ ESTIVER TRABALHANDO
  -- DÁ PREFERÊNCIA PARA ELE
  -- =====================================================

  if looting
    and
    lootingStatus
    and
    lootingStatus:len() > 0 then


    TargetBot.setStatus(
      lootingStatus
    )


    TargetBot.walk()


    lastAction = now


    return

  end


  -- =====================================================
  -- ATTACK
  -- =====================================================

  if highestPriorityParams
    and
    not isInPz() then


    ui.target.right:setText(
      highestPriorityParams.creature:getName()
    )


    ui.config.right:setText(
      highestPriorityParams.config.name
    )


    TargetBot.Creature.attack(
      highestPriorityParams,
      targets,
      looting
    )


    if lootingStatus:len() > 0 then

      TargetBot.setStatus(
        "Attack & " ..
        lootingStatus
      )


    elseif cavebotAllowance > now then

      TargetBot.setStatus(
        "Luring using CaveBot"
      )


    else

      TargetBot.setStatus(
        "Attacking"
      )


      if not lureEnabled then

        TargetBot.setStatus(
          "Attacking (luring off)"
        )

      end

    end


    TargetBot.walk()


    lastAction = now


    return

  end


  -- =====================================================
  -- TARGET LOCK SEM PATH
  -- =====================================================

  if lockedTargetId
    and
    lockedCreature then


    ui.target.right:setText(
      lockedCreature:getName()
    )


    TargetBot.setStatus(
      "Target Locked"
    )


    return

  end


  -- =====================================================
  -- SEM TARGET
  -- =====================================================

  ui.target.right:setText("-")

  ui.config.right:setText("-")


  if looting then

    TargetBot.walk()

    lastAction = now

  end


  if lootingStatus:len() > 0 then

    TargetBot.setStatus(
      lootingStatus
    )

  else

    TargetBot.setStatus(
      "Waiting"
    )

  end

end)


-- =========================================================
-- CONFIG
-- =========================================================

config =
  Config.setup(
    "targetbot_configs",
    configWidget,
    "json",

    function(name, enabled, data)


      if not data then

        ui.status.right:setText(
          "Off"
        )


        lockedTargetId = nil

        lockedTargetLastValid = 0

        lootPriorityUntil = 0


        return targetbotMacro.setOff()

      end


      TargetBot.Creature.resetConfigs()


      for _, value in ipairs(
        data["targeting"] or {}
      ) do

        TargetBot.Creature.addConfig(
          value
        )

      end


      TargetBot.Looting.update(
        data["looting"] or {}
      )


      if enabled then

        ui.status.right:setText(
          "On"
        )

      else

        ui.status.right:setText(
          "Off"
        )


        lockedTargetId = nil

        lockedTargetLastValid = 0

        lootPriorityUntil = 0

      end


      targetbotMacro.setOn(
        enabled
      )


      targetbotMacro.delay = nil

      lureEnabled = true

    end
  )


-- =========================================================
-- UI BUTTONS
-- =========================================================

ui.editor.buttons.add.onClick = function()

  TargetBot.Creature.edit(
    nil,

    function(newConfig)

      TargetBot.Creature.addConfig(
        newConfig,
        true
      )

      TargetBot.save()

    end
  )

end


ui.editor.buttons.edit.onClick = function()

  local entry =
    ui.list:getFocusedChild()


  if not entry then
    return
  end


  TargetBot.Creature.edit(
    entry.value,

    function(newConfig)

      entry:setText(
        newConfig.name
      )


      entry.value =
        newConfig


      TargetBot.Creature.resetConfigsCache()


      TargetBot.save()

    end
  )

end


ui.editor.buttons.remove.onClick = function()

  local entry =
    ui.list:getFocusedChild()


  if not entry then
    return
  end


  entry:destroy()


  TargetBot.Creature.resetConfigsCache()


  TargetBot.save()

end


-- =========================================================
-- PUBLIC FUNCTIONS
-- =========================================================

TargetBot.isActive = function()

  return lastAction + 300 > now

end


TargetBot.isCaveBotActionAllowed = function()

  -- =====================================================
  -- IMPORTANTE
  --
  -- CaveBot fica BLOQUEADO enquanto o Looting
  -- estiver na janela de prioridade.
  --
  -- Isso impede ele de sair andando e abandonar corpse.
  -- =====================================================

  if isLootPriority() then
    return false
  end


  return cavebotAllowance > now

end


TargetBot.setStatus = function(text)

  return ui.status.right:setText(
    text
  )

end


TargetBot.getStatus = function()

  return ui.status.right:getText()

end


TargetBot.isOn = function()

  return config.isOn()

end


TargetBot.isOff = function()

  return config.isOff()

end


TargetBot.setOn = function(val)

  if val == false then

    return TargetBot.setOff(
      true
    )

  end


  config.setOn()

end


TargetBot.setOff = function(val)

  if val == false then

    return TargetBot.setOn(
      true
    )

  end


  lockedTargetId = nil

  lockedTargetLastValid = 0

  lootPriorityUntil = 0


  config.setOff()

end


TargetBot.getCurrentProfile = function()

  return storage._configs.targetbot_configs.selected

end


local botConfigName =
  modules.game_bot.contentsPanel.config:getCurrentOption().text


TargetBot.setCurrentProfile = function(name)

  if not g_resources.fileExists(
    "/bot/" ..
    botConfigName ..
    "/targetbot_configs/" ..
    name ..
    ".json"
  ) then

    return warn(
      "there is no targetbot profile with that name!"
    )

  end


  TargetBot.setOff()


  storage._configs.targetbot_configs.selected =
    name


  TargetBot.setOn()

end


TargetBot.delay = function(value)

  targetbotMacro.delay =
    now + value

end


TargetBot.save = function()

  local data = {
    targeting = {},
    looting = {}
  }


  for _, entry in ipairs(
    ui.list:getChildren()
  ) do

    table.insert(
      data.targeting,
      entry.value
    )

  end


  TargetBot.Looting.save(
    data.looting
  )


  config.save(
    data
  )

end


TargetBot.allowCaveBot = function(time)

  cavebotAllowance =
    now + time

end


TargetBot.disableLuring = function()

  lureEnabled = false

end


TargetBot.enableLuring = function()

  lureEnabled = true

end


TargetBot.Danger = function()

  return dangerValue

end


TargetBot.lootStatus = function()

  return looterStatus

end


-- =========================================================
-- ATTACKS
-- =========================================================

local lastSpell = 0
local lastAttackSpell = 0


TargetBot.saySpell = function(text, delay)

  if type(text) ~= "string"
    or
    text:len() < 1 then

    return

  end


  if not delay then
    delay = 500
  end


  if g_game.getProtocolVersion() < 1090 then

    lastAttackSpell = now

  end


  if lastSpell + delay < now then

    say(text)

    lastSpell = now

    return true

  end


  return false

end


TargetBot.sayAttackSpell = function(text, delay)

  if type(text) ~= "string"
    or
    text:len() < 1 then

    return

  end


  if not delay then
    delay = 2000
  end


  if lastAttackSpell + delay < now then

    say(text)

    lastAttackSpell = now

    return true

  end


  return false

end


local lastItemUse = 0
local lastRuneAttack = 0


TargetBot.useItem = function(
  item,
  subType,
  target,
  delay
)

  if not delay then
    delay = 200
  end


  if lastItemUse + delay < now then

    local thing =
      g_things.getThingType(
        item
      )


    if not thing
      or
      not thing:isFluidContainer() then

      subType =
        g_game.getClientVersion() >= 860
        and 0
        or 1

    end


    if g_game.getClientVersion() < 780 then

      local tmpItem =
        g_game.findPlayerItem(
          item,
          subType
        )


      if not tmpItem then
        return
      end


      g_game.useWith(
        tmpItem,
        target,
        subType
      )


    else

      g_game.useInventoryItemWith(
        item,
        target,
        subType
      )

    end


    lastItemUse = now

  end

end


TargetBot.useAttackItem = function(
  item,
  subType,
  target,
  delay
)

  if not delay then
    delay = 2000
  end


  if lastRuneAttack + delay < now then

    local thing =
      g_things.getThingType(
        item
      )


    if not thing
      or
      not thing:isFluidContainer() then

      subType =
        g_game.getClientVersion() >= 860
        and 0
        or 1

    end


    if g_game.getClientVersion() < 780 then

      local tmpItem =
        g_game.findPlayerItem(
          item,
          subType
        )


      if not tmpItem then
        return
      end


      g_game.useWith(
        tmpItem,
        target,
        subType
      )


    else

      g_game.useInventoryItemWith(
        item,
        target,
        subType
      )

    end


    lastRuneAttack = now

  end

end


TargetBot.canLure = function()

  return lureEnabled

end
CaveBot.Extensions.Imbuing = {}

AutoImbuingControl = AutoImbuingControl or {
  busy = false,
  completedItemId = 0,
  reequipItemId = 0
}

local SHRINES = {25060, 25061, 25182, 25183}

local currentIndex = 1
local shrine = nil
local item = nil
local currentId = 0
local triedToTakeOff = false
local destination = nil
local currentItemWasEquipped = false

local waitingForCompletion = false
local waitingItemId = 0
local completionRetries = 0

local function isItemEquipped(itemId)
  for slot = 1, 10 do
    local equippedItem = player:getInventoryItem(slot)

    if equippedItem and equippedItem:getId() == itemId then
      return true
    end
  end

  return false
end

local function reset()
  EquipManager.setOn()

  shrine = nil
  currentIndex = 1
  item = nil
  currentId = 0
  triedToTakeOff = false
  destination = nil
  currentItemWasEquipped = false

  waitingForCompletion = false
  waitingItemId = 0
  completionRetries = 0

  AutoImbuingControl.busy = false
  AutoImbuingControl.completedItemId = 0
  AutoImbuingControl.reequipItemId = 0
end

CaveBot.Extensions.Imbuing.setup = function()
  CaveBot.registerAction("imbuing", "red", function(value, retries)
    local data = string.split(value, ",")
    local ids = {}

    if #data == 0 and value ~= "name" then
      warn("CaveBot[Imbuing] no items added, proceeding")
      reset()
      return false
    end

    EquipManager.setOff()

    if value == "name" then
      local imbuData = AutoImbueTable[player:getName()]

      if not imbuData then
        warn("CaveBot[Imbuing] character not found")
        reset()
        return false
      end

      for id, imbues in pairs(imbuData) do
        id = tonumber(id)

        if id and not table.find(ids, id) then
          table.insert(ids, id)
        end
      end
    else
      for _, id in ipairs(data) do
        id = tonumber(id)

        if id and not table.find(ids, id) then
          table.insert(ids, id)
        end
      end
    end

    -- Espera o segundo script fechar a janela e reequipar.
    if waitingForCompletion then
      if AutoImbuingControl.completedItemId == waitingItemId then
        warn(
          "CaveBot[Imbuing] item completed: "
            .. waitingItemId
        )

        waitingForCompletion = false
        waitingItemId = 0
        completionRetries = 0

        AutoImbuingControl.completedItemId = 0
        AutoImbuingControl.reequipItemId = 0

        currentItemWasEquipped = false
        currentIndex = currentIndex + 1
        item = nil
        shrine = nil

        delay(500)
        return "retry"
      end

      completionRetries = completionRetries + 1

      if completionRetries > 60 then
        warn(
          "CaveBot[Imbuing] timeout waiting for item: "
            .. waitingItemId
        )

        reset()
        return false
      end

      delay(500)
      return "retry"
    end

    -- Todos os itens foram concluídos.
    if currentIndex > #ids then
      warn("CaveBot[Imbuing] all items completed")
      reset()
      return true
    end

    -- Procura o shrine.
    shrine = nil

    for _, tile in ipairs(g_map.getTiles(posz())) do
      for _, tileItem in ipairs(tile:getItems()) do
        local tileItemId = tileItem:getId()

        if table.find(SHRINES, tileItemId) then
          shrine = tileItem
          break
        end
      end

      if shrine then
        break
      end
    end

    if not shrine then
      warn("CaveBot[Imbuing] shrine not found")
      reset()
      return false
    end

    destination = shrine:getPosition()
    currentId = ids[currentIndex]
    item = findItem(currentId)

    -- Se não encontrou na mochila, verifica se está equipado.
    if not item then
      if triedToTakeOff then
        warn(
          "CaveBot[Imbuing] item not found after unequip: "
            .. currentId
        )

        triedToTakeOff = false
        currentItemWasEquipped = false
        currentIndex = currentIndex + 1

        delay(500)
        return "retry"
      end

      if isItemEquipped(currentId) then
        triedToTakeOff = true
        currentItemWasEquipped = true

        warn(
          "CaveBot[Imbuing] taking off item: "
            .. currentId
        )

        g_game.equipItemId(currentId)

        delay(1000)
        return "retry"
      end

      warn(
        "CaveBot[Imbuing] item unavailable, skipping: "
          .. currentId
      )

      currentItemWasEquipped = false
      currentIndex = currentIndex + 1

      delay(500)
      return "retry"
    end

    triedToTakeOff = false

    -- Aproxima-se do shrine.
    if not CaveBot.MatchPosition(destination, 1) then
      CaveBot.GoTo(destination, 1)

      delay(200)
      return "retry"
    end

    -- Informa ao segundo script se deve reequipar.
    AutoImbuingControl.busy = true
    AutoImbuingControl.completedItemId = 0

    if currentItemWasEquipped then
      AutoImbuingControl.reequipItemId = currentId
    else
      AutoImbuingControl.reequipItemId = 0
    end

    waitingForCompletion = true
    waitingItemId = currentId
    completionRetries = 0

    warn(
      "CaveBot[Imbuing] using shrine on item: "
        .. currentId
    )

    useWith(shrine, item)

    delay(500)
    return "retry"
  end)

  CaveBot.Editor.registerAction("imbuing", "imbuing", {
    value = "name",
    title = "Auto Imbuing",
    description = "insert below item ids to be imbued, separated by comma\nor 'name' to load from file",
  })
end
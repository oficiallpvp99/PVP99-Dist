local imbuementsData = {
  ["Hashirama Dellas"] = {
    [10385] = {21}
  },

  ["Ryzzensix"] = {
    [31577] = {21},
    [3387] = {18, 48},
    [3388] = {18, 21}
  },

  ["Boromir Dellas"] = {
    [30396] = {18, 21},
    [30397] = {21},
    [34157] = {18}
  },

  ["Gil-galad Dellas"] = {
    [39155] = {18, 21},
    [31577] = {21},
    [34157] = {18}
  },

  ["Piquiinha"] = {
    [34086] = {18, 21},
    [3366] = {18, 39},
    [22726] = {39},
    [10385] = {21}
  }
}

local SECONDS = 1
local MINUTES = 60 * SECONDS
local HOURS = 60 * MINUTES

local SAFE_IMBUEMENT_TIME = 2 * HOURS

local SLOT_SWITCH_DELAY = 1200
local CLEAR_DELAY = 600
local APPLY_DELAY = 900
local REEQUIP_DELAY = 700

AutoImbuingControl = AutoImbuingControl or {
  busy = false,
  completedItemId = 0,
  reequipItemId = 0
}

local processingImbuement = false
local currentImbuementItemId = nil

local function finishImbuement(itemId)
  -- Esta é a função correta que corresponde ao botão Close.
  g_game.closeImbuementWindow()

  print(
    "[Auto Imbue] Janela fechada para o item: "
      .. itemId
  )

  schedule(REEQUIP_DELAY, function()
    if AutoImbuingControl.reequipItemId == itemId then
      local itemToEquip = findItem(itemId)

      if itemToEquip then
        g_game.equipItemId(itemId)

        print(
          "[Auto Imbue] Item reequipado: "
            .. itemId
        )
      else
        print(
          "[Auto Imbue] Item não encontrado para reequipar: "
            .. itemId
        )
      end
    else
      print(
        "[Auto Imbue] Item não estava equipado anteriormente: "
          .. itemId
      )
    end

    AutoImbuingControl.completedItemId = itemId
    AutoImbuingControl.busy = false

    currentImbuementItemId = nil
    processingImbuement = false
  end)
end

onImbuementWindow(function(
  itemId,
  slots,
  activeSlots,
  imbuements,
  needItems
)
  -- Evita processar novamente quando a janela atualizar
  -- depois de limpar ou aplicar um imbuement.
  if processingImbuement then
    return
  end

  local data = imbuementsData[name()]

  if not data or not data[itemId] then
    print(
      "[Auto Imbue] Item sem configuração: "
        .. itemId
    )

    processingImbuement = true
    currentImbuementItemId = itemId

    schedule(500, function()
      finishImbuement(itemId)
    end)

    return
  end

  processingImbuement = true
  currentImbuementItemId = itemId
  AutoImbuingControl.busy = true

  print(
    "[Auto Imbue] Processando item: "
      .. itemId
  )

  if slots == 0 then
    schedule(500, function()
      finishImbuement(itemId)
    end)

    return
  end

  for i = 0, slots - 1 do
    schedule(i * SLOT_SWITCH_DELAY, function()
      local activeSlot = activeSlots[i]
      local imbuementId = data[itemId][i + 1]
      local mustApply = false

      if activeSlot then
        local timeLeft = activeSlot[2]

        if timeLeft < SAFE_IMBUEMENT_TIME then
          g_game.clearImbuement(i)
          mustApply = true

          print(
            "[Auto Imbue] Limpando slot "
              .. i
              .. " do item "
              .. itemId
          )
        end
      else
        mustApply = true
      end

      if mustApply and imbuementId then
        schedule(CLEAR_DELAY, function()
          g_game.applyImbuement(
            i,
            imbuementId,
            true
          )

          print(
            "[Auto Imbue] Aplicando imbuement "
              .. imbuementId
              .. " no slot "
              .. i
          )
        end)
      end
    end)
  end

  -- Aguarda o último slot terminar.
  local finishDelay =
    ((slots - 1) * SLOT_SWITCH_DELAY)
    + CLEAR_DELAY
    + APPLY_DELAY

  schedule(finishDelay, function()
    finishImbuement(itemId)
  end)
end)
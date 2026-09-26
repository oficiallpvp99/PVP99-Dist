-- a janela de imbui deve ser tratada separadamente
-- o reequipamento deve ser tratado separadamente (por exemplo, gerente de equipamentos)

CaveBot.Extensions.CheckImbuing = {}

local currentIndex = 3
local label
local timeLeft

local function reset()
  currentIndex = 3
  label = nil
  timeLeft = nil
end

CaveBot.Extensions.CheckImbuing.setup = function()
  CaveBot.registerAction("check imbue", "red", function(value, retries)
    local data = string.split(value, ",")

    if #data < 3 then
      print("CaveBot[Check Imbuements] invalid data, proceeding")
      reset()
      return false
    end
 
    if currentIndex > #data then
      print("CaveBot[Check Imbuements] checked all items, proceeding")
      reset()
      return true
    end
	
    label = data[1]
    timeLeft = tonumber(data[2])
	
    local name = data[currentIndex]
    local item
	
    if name == "helmet" and getHead() then
      item = getHead()
    elseif name == "armor" and getBody() then
      item = getBody()
    elseif name == "boots" and getFeet() then
      item = getFeet()
    elseif name == "left" and getLeft() then
      item = getLeft()
    elseif name == "right" and getRight() then
      item = getRight()
    end
	
    if not item then
      print("CaveBot[Check Imbuements] cannot find item on slot: " .. name .. ", proceeding")
      currentIndex = currentIndex + 1
      return "retry"
    end
	
    g_game.look(item)
    currentIndex = currentIndex + 1
	
    print("CaveBot[Check Imbuements] checking item on slot: " .. name)
    delay(1000)
    return "retry"
  end)

  CaveBot.Editor.registerAction("check imbue", "check imbue", {
    value="label,minutes,items",
    title="Check Imbue",
    description="Label - label para ir\nMinutes - minutos restantes do imbui para ir para a label\nItems: helmet,armor,boots,left,right",
  })
end

local regex = [[(\d{1,2}:\d{1,2}|\d{1,2})(?:h|H|min)]]

onTextMessage(function(mode, text)
  if not text:find("Imbuements: ") then return end
  if not label or not timeLeft then return end

  text = text:lower()

  -- Pega somente o conteúdo dentro dos parênteses
  local imbuements = text:match("imbuements:%s*%((.-)%)")
  if not imbuements then return end

  -- Pega SOMENTE o primeiro slot.
  -- Tudo depois da primeira vírgula é ignorado.
  local firstSlot = imbuements:match("^%s*(.-)%s*,")
  
  -- Caso exista apenas um slot e não tenha vírgula
  if not firstSlot then
    firstSlot = imbuements:match("^%s*(.-)%s*$")
  end

  if not firstSlot then return end

  -- ============================================================
  -- PRIMEIRO SLOT = FREE SLOT
  -- ============================================================
  if firstSlot:find("free slot", 1, true) then
    print("CaveBot[Check Imbuements] first slot is Free Slot")
    CaveBot.gotoLabel(label)
    reset()
    return
  end

  -- ============================================================
  -- VERIFICA O TEMPO SOMENTE DO PRIMEIRO SLOT
  -- ============================================================
  local result = regexMatch(firstSlot, regex)

  if #result > 0 then
    local value = result[1][2]
    local time

    -- Exemplo: 19:32h
    if value:match(":") then
      local data = string.split(value, ":")
      time = (tonumber(data[1]) * 60) + tonumber(data[2])
    else
      time = tonumber(value)

      -- Se tiver "h", converte horas para minutos
      if firstSlot:find(value .. "h", 1, true) then
        time = time * 60
      end
    end

    print("CaveBot[Check Imbuements] first slot time: " .. time .. " minutes")

    if timeLeft > time then
      print("CaveBot[Check Imbuements] first slot below required time")
      CaveBot.gotoLabel(label)
      reset()
    end
  end
end)
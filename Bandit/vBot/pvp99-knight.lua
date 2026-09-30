local ropeId = 3003  -- ID da Rope
local useOnSelf = true  -- Variável para usar em você mesmo

corda = macro(1000, function()
  if useOnSelf then
    usewith(ropeId, player)  -- Usa a Rope no personagem
  end
end)

addIcon("Co", {item=3003, text="ropa",}, function(icon, isOn) 
  corda.setOn(isOn) 
end)

local function hideAllIcon()
  for i, child in ipairs(modules.game_interface.gameMapPanel:getChildren()) do
    if child:getStyleName() == "BotIcon" then
      if icon then
        child:hide()
      else
        child:show()
      end
    end
  end
end

hotkey("F2", "Esconder Iconos", function() 
  icon = not icon
  hideAllIcon()
end)

UI.Label("Stack")

local STACK_DELAY = 100 -- velocidade do macro
local MAX_STACK = 100

macro(STACK_DELAY, "Stack items", function()

  local containers = g_game.getContainers()
  local stacks = {}

  -- 1. Mapeia todos os itens stackáveis
  for _, container in pairs(containers) do

    -- Ignora loot containers de monstros
    if not container.lootContainer then

      local items = container:getItems()

      for slot, item in ipairs(items) do

        if item:isStackable() and item:getCount() < MAX_STACK then

          local id = item:getId()

          if not stacks[id] then
            stacks[id] = {}
          end

          table.insert(stacks[id], {
            item = item,
            count = item:getCount(),
            position = container:getSlotPosition(slot - 1)
          })

        end
      end
    end
  end

  -- 2. Procura itens iguais que podem ser unidos
  for id, itemList in pairs(stacks) do

    if #itemList >= 2 then

      -- Deixa as pilhas mais cheias primeiro
      table.sort(itemList, function(a, b)
        return a.count > b.count
      end)

      -- Destino = pilha mais cheia
      local destination = itemList[1]

      -- Procura uma pilha para completar o destino
      for i = 2, #itemList do

        local source = itemList[i]

        if destination.count < MAX_STACK and source.count > 0 then

          local missing = MAX_STACK - destination.count
          local amount = math.min(missing, source.count)

          if amount > 0 then
            g_game.move(
              source.item,
              destination.position,
              amount
            )

            return
          end
        end
      end
    end
  end
end)

local ms = 0 -- Garante que a variável existe antes do primeiro uso


local ignoreNames = {
  ["Grovebeast"] = true,
  ["Skullfrost"] = true,
  ["Omniphant"] = true,
  ["Emberwing"] = true,
  ["Thundergiant"] = true
}

atkAll = macro(100, function()
  if not g_game.isOnline() then return end

  -- se já tem target, mantém fixo
  if g_game.getAttackingCreature() then return end

  local myPos = player:getPosition()
  local closest
  local closestDist

  for _, creature in ipairs(getSpectators()) do
    if creature
      and creature:isMonster()
      and not creature:isDead()
      and not creature:isNpc()
      and not creature:isPlayer()
      and creature:getPosition().z == myPos.z
      and not ignoreNames[creature:getName()]
    then
      local dist = getDistanceBetween(myPos, creature:getPosition())

      if not closest or dist < closestDist then
        closest = creature
        closestDist = dist
      end
    end
  end

  if closest then
    attack(closest)
  end
end)

addIcon("AtkAll", { item = 12692, text = "target" }, function(icon, isOn)
  atkAll.setOn(isOn)
end)

-- =========================================================
-- CAVE BOT + TARGET BOT ICONS
-- =========================================================

local CAVE_ICON_ITEM   = 16770 -- troque pelo ID do item que quiser
local TARGET_ICON_ITEM = 50158 -- troque pelo ID do item que quiser

-- =========================================================
-- CAVE BOT
-- =========================================================

local cIcon = addIcon("cI", {
  item = CAVE_ICON_ITEM,
  text = "CAVE",
  switchable = false,
  moveable = true
}, function()

  if CaveBot.isOff() then
    CaveBot.setOn()
  else
    CaveBot.setOff()
  end

end)

cIcon:setSize({
  height = 50,
  width = 60
})

cIcon.text:setFont("verdana-11px-rounded")


-- =========================================================
-- TARGET BOT
-- =========================================================

local tIcon = addIcon("tI", {
  item = TARGET_ICON_ITEM,
  text = "TARGET",
  switchable = false,
  moveable = true
}, function()

  if TargetBot.isOff() then
    TargetBot.setOn()
  else
    TargetBot.setOff()
  end

end)

tIcon:setSize({
  height = 50,
  width = 60
})

tIcon.text:setFont("verdana-11px-rounded")


-- =========================================================
-- ATUALIZAÇÃO VISUAL
-- =========================================================

macro(100, function()

  -- CAVE BOT
  if CaveBot.isOn() then

    cIcon.text:setColoredText({
      "cave\n", "yellow",
      "on", "green"
    })

  else

    cIcon.text:setColoredText({
      "cave\n", "yellow",
      "off", "red"
    })

  end


  -- TARGET BOT
  if TargetBot.isOn() then

    tIcon.text:setColoredText({
      "target\n", "yellow",
      "on", "green"
    })

  else

    tIcon.text:setColoredText({
      "target\n", "yellow",
      "off", "red"
    })

  end

end)

local countMP = addIcon("HP", {text="HP", item = 23375}, 
function(widget,isOn)
   local id =  23375
   local contar = macro(1000,function() 
      local countItem = itemAmount(id)
      widget.text:setText(countItem.."\n")
      widget.text:setColor("green")
   end)
   contar:setOn()
end)

local countMP = addIcon("MP", {text="MP", item = 53164}, 
function(widget,isOn)
   local id = 53164
   local contar = macro(1000,function() 
      local countItem = itemAmount(id)
      widget.text:setText(countItem.."\n")
      widget.text:setColor("green")
   end)
   contar:setOn()
end)


-- ============================================================
-- EK AURERA / TELARIA - STANCES + ROTACAO V5
--
-- BLOOD RAGE = utito tempo
-- PROTECTOR   = utamo tempo
--
-- ICONES NATIVOS DO CLIENTE:
-- usa sprites do proprio .dat/.spr do servidor (sem PNG externo)
--
-- Blood Rage:
-- prioridade exori > exori gran > exori mas
--
-- Protector:
-- com escudo:
-- 1 Shield Slam
-- 2 Shield Bash
-- 3 Inflict Wound
-- 4 rotacao normal do Knight
-- com arma 2H/sem escudo:
-- Inflict Wound + rotacao normal
-- e mantem utamo tempo ativo
-- ============================================================

setDefaultTab('MAIN')

storage.ekAureraV1 = storage.ekAureraV1 or {}
local cfg = storage.ekAureraV1

local function default(k, v)
  if cfg[k] == nil then
    cfg[k] = v
  end
end

default('gap', 2100)

-- ============================================================
-- SHIELD BASH
-- ============================================================

default('bashWords', 'exori ico scu')
default('bashCD', 4)
default('bashMana', 30)
default('bashLevel', 18)
default('bashRange', 1)
default('bashOn', true)

-- ============================================================
-- SHIELD SLAM
-- ============================================================

default('slamWords', 'exori scu')
default('slamCD', 6)
default('slamMana', 110)
default('slamLevel', 30)
default('slamRange', 1)
default('slamOn', true)

default('shieldSpells', true)

-- ============================================================
-- ICONES NATIVOS DO SERVIDOR / CLIENTE
--
-- O addIcon desenha o sprite diretamente do .dat/.spr carregado
-- pelo OTClient. Nao precisa criar pasta, copiar PNG ou editar APK.
--
-- Se o Aurera alterar algum sprite, basta trocar somente os IDs.
-- ============================================================

local SERVER_ICONS = {
  -- Soulshredder / ATAQUE
  attack = 34083,

  -- Soulbastion / DEFESA
  defense = 34099,

  -- Icone da rotacao
  rotation = 47375
}

-- ============================================================
-- ESTADO
-- ============================================================

local function clock()
  return now or g_clock.millis()
end

-- ============================================================
-- DETECCAO 2H / ESCUDO
--
-- No OTCv8:
-- SlotRight = mao direita
-- SlotLeft  = mao esquerda
--
-- Com arma 1H + escudo, os dois slots ficam ocupados.
-- Com arma 2H, apenas um slot de mao fica ocupado.
-- ============================================================

local function hasShieldSetup()
  local left = nil
  local right = nil

  if getLeft then
    left = getLeft()
  elseif player and player.getInventoryItem then
    left = player:getInventoryItem(InventorySlotLeft)
  end

  if getRight then
    right = getRight()
  elseif player and player.getInventoryItem then
    right = player:getInventoryItem(InventorySlotRight)
  end

  return left ~= nil and right ~= nil
end

local last = {}
local globalNext = 0

local stance = 'unknown'
local pending = nil
local pendingAt = 0

local icons = {}

-- ============================================================
-- TEXTO DO ICONE
-- ============================================================

local function label(icon, text, color)

  if icon and icon.text then
    icon.text:setText(text)
    icon.text:setColor(color)
  end
end

-- ============================================================
-- TEXTOS FIXOS DOS ICONES
-- ============================================================

local function refreshStances()
  -- Texto fixo, sem ON/OFF. A cor mostra o estado confirmado pelo servidor.
  label(
    icons.attack,
    'utito tempo',
    stance == 'attack' and '#55ff55' or '#ff5555'
  )

  label(
    icons.defense,
    'utamo tempo',
    stance == 'defense' and '#55ff55' or '#ff5555'
  )
end

-- ============================================================
-- TROCA DE STANCE
-- ============================================================

local function choose(wanted, words)

  if not g_game.isOnline() then
    return
  end

  -- Já esperando confirmação
  if pending then
    return
  end

  -- Se clicar na stance que ja esta ativa, envia a mesma fala
  -- novamente para o servidor desativar. Caso contrario, ativa/troca.
  local togglingOff = (stance == wanted)

  pending = togglingOff and 'off' or wanted
  pendingAt = clock()

  -- RESPOSTA VISUAL INSTANTANEA:
  -- nao espera a mensagem do servidor para trocar a cor.
  -- Ativou/trocou -> fica verde na hora.
  -- Desativou     -> fica vermelho na hora.
  if togglingOff then
    stance = 'unknown'
  else
    stance = wanted
  end

  refreshStances()

  globalNext =
    math.max(
      globalNext,
      clock() + cfg.gap
    )

  say(words)
end

-- ============================================================
-- ICONE ATAQUE
-- BLOOD RAGE / UTITO TEMPO
-- ============================================================

icons.attack = addIcon(
  'ekAureraAttack',
  {
    item = { id = SERVER_ICONS.attack, count = 1 },
    text = 'utito tempo',
    switchable = false,
    moveable = true
  },
  function()

    choose(
      'attack',
      'utito tempo'
    )

  end
)

icons.attack:setSize({
  width = 64,
  height = 64
})


-- ============================================================
-- ICONE DEFESA
-- PROTECTOR / UTAMO TEMPO
-- ============================================================

icons.defense = addIcon(
  'ekAureraDefense',
  {
    item = { id = SERVER_ICONS.defense, count = 1 },
    text = 'utamo tempo',
    switchable = false,
    moveable = true
  },
  function()

    choose(
      'defense',
      'utamo tempo'
    )

  end
)

icons.defense:setSize({
  width = 64,
  height = 64
})


-- ============================================================
-- CONFIRMACAO DAS STANCES PELO SERVIDOR
-- ============================================================

onTextMessage(function(mode, text)

  text =
    (text or ''):lower()

  -- ==========================================================
  -- BLOOD RAGE ATIVADO
  -- ==========================================================

  if text:find(
    'you have activated the blood rage',
    1,
    true
  ) then

    stance = 'attack'
    pending = nil

  -- ==========================================================
  -- PROTECTOR ATIVADO
  -- ==========================================================

  elseif text:find(
    'you have activated the protector',
    1,
    true
  ) then

    stance = 'defense'
    pending = nil

  -- ==========================================================
  -- STANCE DESATIVADA
  -- ==========================================================

  elseif
    text:find(
      'deactivated',
      1,
      true
    )
    and
    (
      text:find(
        'blood rage',
        1,
        true
      )
      or
      text:find(
        'protector',
        1,
        true
      )
    )
  then

    stance = 'unknown'
    pending = nil

  else

    return

  end

  refreshStances()
end)

-- ============================================================
-- MAGIAS DA STANCE ATAQUE
--
-- PRIORIDADE:
--
-- 1 - exori
-- 2 - exori gran
-- 3 - exori mas
-- 4 - exori min
-- 5 - exori gran ico
-- 6 - exori ico
-- 7 - exori hur
-- ============================================================

local spells = {

  {
    words = 'exori',
    mana = 125,
    level = 35,
    range = 1,
    mobs = 1,
    cd = 4000,
    area = true
  },

  {
    words = 'exori gran',
    mana = 360,
    level = 90,
    range = 1,
    mobs = 1,
    cd = 6000,
    area = true
  },

  {
    words = 'exori mas',
    mana = 200,
    level = 33,
    range = 2,
    mobs = 1,
    cd = 8000,
    area = true
  },

  {
    words = 'exori min',
    mana = 200,
    level = 70,
    range = 1,
    mobs = 2,
    cd = 6000,
    area = true,
    turning = true
  },

  {
    words = 'exori gran ico',
    mana = 300,
    level = 110,
    range = 1,
    mobs = 1,
    cd = 30000
  },

  {
    words = 'exori ico',
    mana = 30,
    level = 16,
    range = 1,
    mobs = 1,
    cd = 6000
  },

  {
    words = 'exori hur',
    mana = 40,
    level = 28,
    range = 5,
    mobs = 1,
    cd = 6000
  }

}

-- ============================================================
-- MAGIA EXTRA DO KNIGHT
-- Inflict Wound = utori kor
-- Level 40 / 30 mana / 30s / alcance 1 SQM
-- ============================================================

local inflictWound = {
  words = 'utori kor',
  mana = 30,
  level = 40,
  range = 1,
  mobs = 1,
  cd = 30000
}

-- ============================================================
-- FAMILIARES / SUMMONS IGNORADOS
-- ============================================================

local ignore = {

  Emberwing = true,

  Skullfrost = true,

  Snowbash = true,

  Grovebeast = true,

  Mossmasher = true,

  Groovebeast = true,

  Thundergiant = true,

  Bladespark = true,

  Sandscourge = true,

  Omniphant = true,

  Moonhunter = true

}

-- ============================================================
-- DISTANCIA
-- ============================================================

local function distance(a, b)

  if not a or not b then
    return 999
  end

  if a.z ~= b.z then
    return 999
  end

  return math.max(
    math.abs(a.x - b.x),
    math.abs(a.y - b.y)
  )
end

-- ============================================================
-- SCAN DE CRIATURAS
-- ============================================================

local function makeSnapshot(p)
  local data = {
    monsters = {}
  }

  for _, creature in ipairs(getSpectators()) do
    local cp = creature:getPosition()

    if cp and cp.z == p.z and creature:getId() ~= player:getId() then
      local d = distance(p, cp)

      if
        creature:isMonster()
        and not ignore[creature:getName()]
      then
        data.monsters[#data.monsters + 1] = d
      end
    end
  end

  return data
end

local function countMonsters(snapshot, range)
  local count = 0

  for _, d in ipairs(snapshot.monsters) do
    if d <= range then
      count = count + 1
    end
  end

  return count
end


-- ============================================================
-- ROTACAO
-- ============================================================

local rotation = macro(
  100,
  'EK Rotacao',
  function()

    -- Offline
    if not g_game.isOnline() then
      return
    end

    -- Player inexistente
    if not player then
      return
    end

    -- Esperando stance
    if pending then
      return
    end

    -- Global delay
    if clock() < globalNext then
      return
    end

    -- ========================================================
    -- PRECISA TER STANCE CONFIRMADA
    -- ========================================================

    if
      stance ~= 'attack'
      and
      stance ~= 'defense'
    then

      return

    end

    -- ========================================================
    -- TARGET
    -- ========================================================

    local target =
      g_game.getAttackingCreature()

    if
      not target
      or
      not target:isMonster()
    then

      return

    end

    local p =
      player:getPosition()

    local tp =
      target:getPosition()

    if
      not p
      or
      not tp
      or
      p.z ~= tp.z
    then

      return

    end

    local time =
      clock()

    local list = {}

    -- Faz apenas UM scan de criaturas por ciclo.
    -- Isso reduz bastante o trabalho no mobile.
    local snapshot = makeSnapshot(p)

    -- ========================================================
    -- STANCE DEFESA / PROTECTOR
    --
    -- COM ESCUDO:
    -- 1 - Shield Slam
    -- 2 - Shield Bash
    -- 3 - Inflict Wound
    -- 4 - Rotacao normal do Knight
    --
    -- 2H:
    -- Inflict Wound + Rotacao normal
    -- ========================================================

    if stance == 'defense' then

      -- ======================================================
      -- PROTECTOR COM ESCUDO
      -- Prioridade:
      -- 1 - Shield Slam
      -- 2 - Shield Bash
      -- ======================================================

      if hasShieldSetup() then

        for _, key in ipairs({

          'slam',

          'bash'

        }) do

          if
            cfg.shieldSpells
            and
            cfg[key .. 'On']
            and
            cfg[key .. 'Words'] ~= ''
            and
            cfg[key .. 'CD'] > 0
          then

            list[#list + 1] = {

              words =
                cfg[key .. 'Words'],

              mana =
                cfg[key .. 'Mana'],

              level =
                cfg[key .. 'Level'],

              range =
                cfg[key .. 'Range'],

              mobs =
                (
                  key == 'slam'
                  and 2
                  or 1
                ),

              cd =
                cfg[key .. 'CD']
                * 1000,

              area =
                (
                  key == 'slam'
                )

            }

          end

        end

        -- Depois das magias de escudo, continua atacando normalmente.
        list[#list + 1] = inflictWound

        for _, spell in ipairs(spells) do
          list[#list + 1] = spell
        end

      -- ======================================================
      -- PROTECTOR COM ARMA 2H / SEM ESCUDO
      --
      -- Mantem utamo tempo ativo, mas nao tenta Shield Slam
      -- ou Shield Bash, pois essas magias exigem escudo.
      -- Usa a mesma rotacao ofensiva como fallback.
      -- ======================================================

      else

        list[#list + 1] = inflictWound

        for _, spell in ipairs(
          spells
        ) do

          list[#list + 1] =
            spell

        end

      end

    -- ========================================================
    -- BLOOD RAGE / STANCE ATAQUE
    -- ========================================================

    else

      list[#list + 1] = inflictWound

      for _, spell in ipairs(
        spells
      ) do

        list[#list + 1] =
          spell

      end

    end

    -- ========================================================
    -- PROCURA PRIMEIRA MAGIA DISPONIVEL
    -- ========================================================

    for _, spell in ipairs(
      list
    ) do

      local count =
        countMonsters(
          snapshot,
          spell.range
        )

      if

        distance(
          p,
          tp
        ) <= spell.range

        and

        count >= spell.mobs

        and

        mana() >= spell.mana

        and

        lvl() >= spell.level

        and

        time >= (
          last[spell.words]
          or 0
        )

      then

        -- ====================================================
        -- EXORI MIN
        -- VIRA PARA O MONSTRO
        -- ====================================================

        if spell.turning then

          local dx =
            tp.x - p.x

          local dy =
            tp.y - p.y

          local direction

          if
            dx ~= 0
            or
            dy ~= 0
          then

            if
              math.abs(dx)
              >
              math.abs(dy)
            then

              direction =
                dx > 0
                and 1
                or 3

            else

              direction =
                dy > 0
                and 2
                or 0

            end

            if
              player:getDirection()
              ~=
              direction
            then

              turn(
                direction
              )

              globalNext =
                time + 150

              return

            end

          end

        end

        -- ====================================================
        -- CAST
        -- ====================================================

        last[spell.words] =
          time
          +
          spell.cd

        globalNext =
          time
          +
          cfg.gap

        say(
          spell.words
        )

        -- Uma magia por ciclo
        return

      end
    end
  end
)

-- Começa desligada
rotation.setOff()

-- ============================================================
-- ICONE ROTACAO
-- ============================================================

icons.rotation = addIcon(
  'ekAureraRotation',
  {
    item = { id = SERVER_ICONS.rotation, count = 1 },
    text = 'atack',
    moveable = true
  },
  rotation
)

icons.rotation:setSize({
  width = 64,
  height = 64
})


-- ============================================================
-- LOGIN / LOGOUT / TIMEOUT
-- ============================================================

local wasOnline =
  g_game.isOnline()

macro(
  250,
  function()

    local online =
      g_game.isOnline()

    -- ========================================================
    -- DESLOGOU
    -- ========================================================

    if not online then

      stance =
        'unknown'

      pending =
        nil

      last = {}
      globalNext = 0

    -- ========================================================
    -- LOGOU NOVAMENTE
    -- ========================================================

    elseif not wasOnline then

      stance =
        'unknown'

      pending =
        nil

      last = {}
      globalNext = 0

    end

    wasOnline =
      online

    -- ========================================================
    -- SERVIDOR NAO CONFIRMOU STANCE
    -- ========================================================

    if
      pending
      and
      clock() - pendingAt > 5000
    then

      pending =
        nil

      stance =
        'unknown'

    end

    refreshStances()

  end
)

-- ============================================================
-- INICIALIZA TEXTOS
-- ============================================================

refreshStances()

-- by pvp99 V5: cor instantanea no clique. Ativar deixa verde imediatamente;
-- desativar deixa vermelho imediatamente. A mensagem do servidor continua
-- confirmando/corrigindo o estado depois. Sem ON/OFF escrito.


-- PVP99 - NPC SYSTEM V2 COMPLETO
-- Banco + Viagem + Balsas + Tapetes + Trade + Serviços
-- Base original preservada + NPCs oficiais adicionais do Tibia
-- Detector rápido, alvo estável e sem janela/macro duplicado

local npcGroups = {

  -- BANCO

  Banco = {
    final = "yes",

    npcs = {
      ["Naji"] = {"deposit all"},
      ["Anya"] = {"deposit all"},
      ["Eva"] = {"deposit all"},
      ["Kepar"] = {"deposit all"},

      ["Suzy"] = {"deposit all"},
      ["Paulie"] = {"deposit all"},
      ["Finarfin"] = {"deposit all"},
      ["Atur"] = {"deposit all"},
      ["Sissek"] = {"deposit all"},
      ["Gerib"] = {"deposit all"},
      ["Flavius"] = {"deposit all"},
      ["Adrian"] = {"deposit all"},
      ["Hector the Mentor"] = {"deposit all"},

      -- ADICIONE NOVOS NPCs DE BANCO AQUI
      -- ["Nome NPC"] = {"deposit all"},
    }
  },


  -- VIAGENS

  Cidades = {
    final = "yes",

    npcs = {

      ["Captain Bluebear"] = {
        "Carlin",
        "Ab'Dendriel",
        "Venore",
        "Port Hope",
        "Liberty Bay",
        "Svargrond",
        "Yalahar",
        "Roshamuul",
        "Oramond",
        "Edron",
        "Krailos",
        "Rangiroa",
        "Arcadia"
      },

      ["Captain Greyhound"] = {
        "Thais",
        "Ab'Dendriel",
        "Venore",
        "Svargrond",
        "Yalahar",
        "Edron",
        "Arcadia"
      },

      ["Captain Fearless"] = {
        "Issavi",
        "Thais",
        "Carlin",
        "Ab'Dendriel",
        "Port Hope",
        "Edron",
        "Darashia",
        "Liberty Bay",
        "Svargrond",
        "Yalahar",
        "Gray Island",
        "Ankrahmun",
        "Rangiroa",
        "Arcadia"
      },

      ["Captain Seagull"] = {
        "Thais",
        "Carlin",
        "Venore",
        "Yalahar",
        "Edron",
        "Gray Island"
      },

      ["Captain Cookie"] = {
        "Liberty Bay"
      },

      ["Jack Fate"] = {
        "Edron",
        "Thais",
        "Venore",
        "Darashia",
        "Ankrahmun",
        "Yalahar",
        "Port Hope"
      },

      ["Charles"] = {
        "Thais",
        "Darashia",
        "Venore",
        "Liberty Bay",
        "Ankrahmun",
        "Yalahar",
        "Edron"
      },

      ["Karith"] = {
        "Ab'Dendriel",
        "Darashia",
        "Venore",
        "Ankrahmun",
        "Port Hope",
        "Thais",
        "Liberty Bay",
        "Carlin",
        "Arcadia"
      },

      ["Captain Max"] = {
        "Calassa",
        "Yalahar",
        "Liberty Bay"
      },

      ["Captain Seahorse"] = {
        "Thais",
        "Carlin",
        "Ab'Dendriel",
        "Venore",
        "Port Hope",
        "Ankrahmun",
        "Liberty Bay",
        "Gray Island",
        "Cormaya"
      },

      ["Pemaret"] = {
        "Edron",
        "Eremo"
      },

      ["Eremo"] = {
        "passage"
      },

      ["Captain Pelagia"] = {
        "Edron",
        "Darashia",
        "Oramond",
        "Venore",
        "Issavi"
      },

      ["Captain Gulliver"] = {
        "Thais",
        "Krailos"
      },

      ["Captain Chelop"] = {
        "Thais"
      },

      ["Captain Harava"] = {
        "Oramond",
        "Krailos",
        "Venore",
        "Darashia"
      },

      ["Captain Grenald"] = {
        "Carlin",
        "Thais",
        "Venore",
        "Yalahar",
        "Svargrond"
      },

      ["Gurbasch"] = {
        "Kazordoon",
        "Farmine",
        "Gnomprona"
      },

      ["Thorgrin"] = {
        "Cormaya",
        "Kazordoon"
      },

      ["Brodrosch"] = {
        "Cormaya",
        "Farmine",
        "Gnomprona",
        "Ticket"
      },

      ["Melian"] = {
        "Darashia",
        "Femor Hills",
        "Svargrond",
        "Edron",
        "Issavi"
      },

      ["Chemar"] = {
        "Farmine",
        "Femor Hills",
        "Svargrond",
        "Edron",
        "Issavi",
        "Marapur",
        "Kazordoon"
      },

      ["Gewen"] = {
        "Farmine",
        "Femor Hills",
        "Svargrond",
        "Edron",
        "Issavi",
        "Marapur",
        "Darashia",
        "Ticket"
      },

      ["Uzon"] = {
        "Farmine",
        "Kazordoon",
        "Svargrond",
        "Edron",
        "Issavi",
        "Marapur",
        "Darashia"
      },

      ["Tanyt"] = {
        "Farmine",
        "Femor Hills",
        "Svargrond",
        "Edron",
        "Issavi",
        "Marapur",
        "Darashia",
        "Kazordoon",
        "Arcadia"
      },

      ["Alfrida"] = {
        "Farmine",
        "Femor Hills",
        "Svargrond",
        "Edron",
        "Issavi",
        "Marapur",
        "Darashia",
        "Kazordoon"
      },

      ["Iyad"] = {
        "Farmine",
        "Femor Hills",
        "Edron",
        "Issavi",
        "Marapur",
        "Darashia",
        "Kazordoon"
      },

      ["Petros"] = {
        "Venore",
        "Ankrahmun",
        "Yalahar",
        "Port Hope",
        "Issavi",
        "Gray Island"
      },

      ["Captain Sinbeard"] = {
        "Darashia",
        "Yalahar",
        "Port Hope",
        "Edron",
        "Venore",
        "Liberty Bay"
      },

      ["Lorek"] = {
        "Center",
        "West",
        "Banuta",
        "Chor",
        "Darama"
      },

      ["Imbul"] = {
        "Centre",
        "east"
      },

      ["Old Adall"] = {
        "east",
        "west"
      },

      ["Pino"] = {
        "Farmine",
        "Femor Hills",
        "Edron",
        "Issavi",
        "Marapur",
        "Darashia",
        "Kazordoon"
      },

      ["Captain Frank"] = {
        "Venore"
      },

      ["Captain Breezelda"] = {
        "Carlin",
        "Venore",
        "Thais",
        "Arcadia"
      },

      ["Quentin"] = {
        "twist of fate"
      },

      ["Scrutinon"] = {
        "Ab'Dendriel",
        "Darashia",
        "Edron",
        "Venore"
      },

      ["Stutchs"] = {"Ab'Dendriel"},


      -- ===== CAPITÃES / ROTAS OFICIAIS ADICIONAIS =====

      ["Anna"] = {
        options = {"passage"},
        final = "yes"
      },

      ["Captain Dreadnought"] = {
        options = {"passage"},
        final = false
      },

      ["Captain Indigo"] = {
        "Thais"
      },

      ["Captain Jack"] = {
        options = {"passage"},
        final = "yes"
      },

      ["Captain Jack Rat"] = {
        options = {"passage"},
        final = false
      },

      ["Captain Kurt"] = {
        options = {"passage"},
        final = false
      },

      ["Captain Tiberius"] = {
        options = {"passage"},
        final = "yes"
      },

      ["Captain Waverider"] = {
        options = {"peg leg"},
        final = "yes"
      },

      ["Dalbrect"] = {
        "Isle of the Kings"
      },

      ["Harlow"] = {
        "Vengoth",
        "Yalahar"
      },

      ["Hawkhurst"] = {
        "Ingol"
      },

      ["Junkar"] = {
        "Kazordoon",
        "Thais",
        "Eyes of the Deep",
        "Underground Isle"
      },

      ["Kendra"] = {
        "Vigintia",
        "Thais"
      },

      ["Maris"] = {
        "Yalahar",
        "Fenrock",
        "Mistrock"
      },

      ["Sebastian"] = {
        "Liberty Bay",
        "Nargor"
      },

      ["Urks The Mute"] = {
        "Cormaya"
      },

      ["Zurak"] = {
        "Chazorai"
      },

      -- ===== BALSAS =====

      ["Buddel"] = {
        "Tyrsung",
        "Okolnir",
        "Svargrond",
        "Raider Camp",
        "Helheim"
      },

      ["Anderson"] = {
        "Carlin",
        "Senja"
      },

      ["Carlson"] = {
        "Carlin",
        "Vega"
      },

      ["Cornell"] = {
        "Edron",
        "Grimvale"
      },

      ["Ferryman Kamil"] = {
        "Fibula",
        "Meluna"
      },

      ["Nielson"] = {
        options = {"passage"},
        final = false
      },

      ["Rascalio"] = {
        "Banor's Eye",
        "Fryclops Island",
        "Meriana",
        "Reokon's Tundra"
      },

      ["Svenson"] = {
        "Carlin",
        "Folda"
      },

      ["Tarak"] = {
        "Yalahar",
        "Monument Tower"
      },

      -- ===== TAPETE MÁGICO / TRANSPORTE AÉREO =====

      ["Ziyad"] = {
        "Darashia",
        "Edron",
        "Farmine",
        "Femor Hills",
        "Issavi",
        "Kazordoon",
        "Svargrond"
      },

      -- ADICIONE NOVOS NPCs DE VIAGEM AQUI
      -- ["Novo Captain"] = {"Thais", "Carlin", "Venore"},
    }
  },


  -- TRADE

  Servicos = {
    final = "yes",
    npcs = {
      ["King Tibianus"] = {
        options = {"promotion"},
        hello = "hail king"
      }
    }
  },

  Trade = {
    final = "trade",

    npcs = {

      ["Yasir"] = {"sell"},
      ["Sarina"] = {"buy/sell"},
      ["Imalas"] = {"sell"},
      ["Cornelia"] = {"buy/sell"},
      ["Liane"] = {"buy"},
      ["Legola"] = {"buy"},
      ["Nydala"] = {"buy"},
      ["Perac"] = {"buy/sell"},
      ["Rowenna"] = {"buy/sell"},
      ["Florentine"] = {"buy"},
      ["Benjamin"] = {"buy"},
      ["Furry"] = {"buy/sell"},
      ["Urd"] = {"buy/sell"},
      ["Frodo"] = {"buy"},
      ["Quero"] = {"buy"},
      ["Xodet"] = {"buy/sell"},
      ["Hanna"] = {"buy/sell"},
      ["Gorn"] = {"buy"},
      ["Sam"] = {"buy/sell"},
      ["Turvy"] = {"buy/sell"},
      ["Topsy"] = {"buy/sell"},
      ["Gamon"] = {"buy"},
      ["Baxter"] = {"buy/sell"},
      ["Lubo"] = {"buy/sell"},
      ["Enpa-Deia Pema"] = {"buy/sell"},
      ["Zethra"] = {"buy"},
      ["Alesar"] = {"buy/sell"},
      ["Yaman"] = {"buy/sell"},
      ["Rashid"] = {"buy/sell"},
      ["Nah'Bob"] = {"buy/sell"},
      ["Haroun"] = {"buy/sell"},
      ["Nelliem"] = {"buy"},
      ["Shiantis"] = {"buy/sell"},
      ["Chephan"] = {"buy"},
      ["Julian"] = {"buy"},
      ["Rachel"] = {"buy/sell"},

      -- COMERCIANTES ADICIONAIS (hi -> trade)
      ["Alexander"] = {options = {"trade"}, final = false},
      ["Asima"] = {options = {"trade"}, final = false},
      ["Sandra"] = {options = {"trade"}, final = false},
      ["Tandros"] = {options = {"trade"}, final = false},
      ["Lily"] = {options = {"trade"}, final = false},
      ["Nelly"] = {options = {"trade"}, final = false},
      ["Faloriel"] = {options = {"trade"}, final = false},
      ["Ghorza"] = {options = {"trade"}, final = false},
      ["Nipuna"] = {options = {"trade"}, final = false},
      ["Sundara"] = {options = {"trade"}, final = false},
      ["Rock In A Hard Place"] = {options = {"trade"}, final = false},
      ["Uzgod"] = {options = {"trade"}, final = false},
      ["Shanar"] = {options = {"trade"}, final = false},
      ["Morpel"] = {options = {"trade"}, final = false},
      ["H.L."] = {options = {"trade"}, final = false},
      ["Gamel"] = {options = {"trade"}, final = false},
      ["Ulrik"] = {options = {"trade"}, final = false},
      ["Flint"] = {options = {"trade"}, final = false},
      ["Cedrik"] = {options = {"trade"}, final = false},
      ["Dario"] = {options = {"trade"}, final = false},
      ["Silas"] = {options = {"trade"}, final = false},
      ["Vincent"] = {options = {"trade"}, final = false},
      ["Willard"] = {options = {"trade"}, final = false},
      ["Xed"] = {options = {"trade"}, final = false},
      ["Aurelia"] = {options = {"trade"}, final = false},
      ["Bertha"] = {options = {"trade"}, final = false},
      ["Gnomally"] = {options = {"trade"}, final = false},
      ["Timur"] = {options = {"trade"}, final = false},
      ["Valentina"] = {options = {"trade"}, final = false},
      ["Wes The Blacksmith"] = {options = {"trade"}, final = false},
      ["Zora"] = {options = {"trade"}, final = false},
      ["Black Bert"] = {options = {"trade"}, final = false},
      ["Azil"] = {options = {"trade"}, final = false},
      ["Rudolph"] = {options = {"trade"}, final = false},
      ["Eliyas"] = {options = {"trade"}, final = false},
      ["The Librarian"] = {options = {"trade"}, final = false},
      ["Yonan"] = {options = {"trade"}, final = false},
      ["Inkaef"] = {options = {"trade"}, final = false},
      ["Avriel"] = {options = {"trade"}, final = false},

      -- ADICIONE NOVOS NPCs DE TRADE AQUI
      -- ["Novo NPC"] = {"buy/sell"},
    }
  }
}

local NPC_DISTANCE = 2
local DETECT_DELAY = 50
local DELAY_OPTION = 200
local DELAY_FINAL = 500
local DELAY_RESET = 800

-- Índice único dos NPCs
local npcIndex = {}

for categoryName, category in pairs(npcGroups) do
  for npcName, npcData in pairs(category.npcs) do
    local options = npcData
    local finalCommand = category.final
    local hello = "hi"

    if npcData.options then
      options = npcData.options

      if npcData.final ~= nil then
        finalCommand = npcData.final
      end

      if npcData.hello then
        hello = npcData.hello
      end
    end

    if type(options) ~= "table" then
      options = {tostring(options)}
    end

    npcIndex[npcName] = {
      category = categoryName,
      options = options,
      final = finalCommand,
      hello = hello
    }
  end
end

g_ui.loadUIFromString([[
Pvp99NpcWindow < MainWindow
  id: pvp99NpcWindow
  text: By Pvp99
  size: 155 85

  Label
    id: npcName
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    margin-top: 1
    text: NPC

  ComboBox
    id: travelOptions
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: npcName.bottom
    margin-top: 6
    width: 125
    height: 20

  HorizontalSeparator
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: travelOptions.bottom
    margin-top: 5
]])

local rootWidget = g_ui.getRootWidget()

if rootWidget then
  local oldWindow = rootWidget:recursiveGetChildById("pvp99NpcWindow")
  if oldWindow then
    oldWindow:destroy()
  end

  local npcWindow = UI.createWindow("Pvp99NpcWindow", rootWidget)
  local combo = npcWindow:recursiveGetChildById("travelOptions")
  local npcLabel = npcWindow:recursiveGetChildById("npcName")

  local currentNpc
  local updatingOptions = false
  local busy = false

  npcWindow:hide()

  local function npcSay(text)
    if not text then return end

    if g_game.getClientVersion() >= 810 then
      g_game.talkChannel(11, 0, text)
    else
      say(text)
    end
  end

  local function npcIsNear(npcName)
    local creature = npcName and getCreatureByName(npcName)
    return creature
      and getDistanceBetween(pos(), creature:getPosition()) <= NPC_DISTANCE
  end

  local function findNearbyNpc()
    local playerPos = pos()
    local bestName
    local bestDistance

    for npcName in pairs(npcIndex) do
      local creature = getCreatureByName(npcName)

      if creature then
        local distance = getDistanceBetween(playerPos, creature:getPosition())

        if distance <= NPC_DISTANCE
          and (not bestDistance or distance < bestDistance) then
          bestName = npcName
          bestDistance = distance
        end
      end
    end

    return bestName
  end

  local function updateNpcOptions(npcName)
    local data = npcIndex[npcName]
    if not data then return end

    updatingOptions = true
    combo:clearOptions()
    combo:addOption(data.category)

    for _, option in ipairs(data.options) do
      combo:addOption(option)
    end

    npcLabel:setText(npcName)
    updatingOptions = false
  end

  local function actionStillValid(npcName)
    return currentNpc == npcName and npcIsNear(npcName)
  end

  macro(DETECT_DELAY, "PVP99 NPC", function()
    -- Enquanto o mesmo NPC continuar perto, evita varrer a lista inteira.
    local npcName =
      currentNpc and npcIsNear(currentNpc)
      and currentNpc
      or findNearbyNpc()

    if not npcName then
      currentNpc = nil
      busy = false

      if npcWindow:isVisible() then
        npcWindow:hide()
      end

      return
    end

    if currentNpc ~= npcName then
      currentNpc = npcName
      busy = false
      updateNpcOptions(npcName)
    end

    if not npcWindow:isVisible() then
      npcWindow:show()
    end
  end)

  combo.onOptionChange = function(widget, option, data)
    if updatingOptions or busy or not currentNpc then
      return
    end

    local actionNpc = currentNpc
    local actionData = npcIndex[actionNpc]

    if not actionData
      or option == actionData.category
      or not npcIsNear(actionNpc) then
      return
    end

    busy = true
    say(actionData.hello or "hi")

    schedule(DELAY_OPTION, function()
      if actionStillValid(actionNpc) then
        npcSay(option)
      end
    end)

    schedule(DELAY_FINAL, function()
      if actionStillValid(actionNpc) and actionData.final then
        npcSay(actionData.final)
      end
    end)

    schedule(DELAY_RESET, function()
      busy = false

      if actionStillValid(actionNpc) then
        updateNpcOptions(actionNpc)
      end
    end)
  end
end


-- CraftETA: reading the open profession window (recipes, materials) and crafting.
local _, ns = ...

local Plain = ns.Plain
-- Forever's client has no global GetItemCount any more: C_Item first (the craft button stayed grey without it)
local ItemCount = (C_Item and C_Item.GetItemCount) or GetItemCount
local recipes = {}   -- recipe name -> { id, learned, mats = { name, count, ... } }
local openID         -- the profession whose recipes are in `recipes`

local function Ready()
  local ui = C_TradeSkillUI
  if not ui or not ui.GetAllRecipeIDs or not ui.GetBaseProfessionInfo then return false end
  if ui.IsTradeSkillLinked and ui.IsTradeSkillLinked() then return false end
  if ui.IsTradeSkillGuild and ui.IsTradeSkillGuild() then return false end
  if ui.IsNPCCrafting and ui.IsNPCCrafting() then return false end
  if ui.IsTradeSkillReady and not ui.IsTradeSkillReady() then return false end
  return true
end

-- the game's profession window, whichever one this client has
function ns.ProfessionFrame()
  for _, name in ipairs({ "ProfessionsFrame", "TradeSkillFrame" }) do
    local f = _G[name]
    if f and f.IsShown and f:IsShown() then return f end
  end
  return nil
end

-- the profession in the open window: { id, rank, max, name } or nil
function ns.OpenProfession()
  if not ns.ProfessionFrame() or not Ready() then return nil end
  local ok, base = pcall(C_TradeSkillUI.GetBaseProfessionInfo)
  if not ok or type(base) ~= "table" then return nil end
  local id = Plain(base.professionID)
  if type(id) ~= "number" or not ns.GUIDES[id] then
    id = ns.SKILL_BY_NAME[Plain(base.professionName) or ""] or id
  end
  if not ns.GUIDES[id] then return nil end
  return { id = id, rank = Plain(base.skillLevel) or 0, max = Plain(base.maxSkillLevel) or 300, name = Plain(base.professionName) }
end

local NameByID = (C_Item and C_Item.GetItemNameByID) or function(id)
  local get = (C_Item and C_Item.GetItemInfo) or GetItemInfo
  return (get(id))
end

-- reads every recipe of the open window: names, IDs, materials
function ns.ReadRecipes()
  local open = ns.OpenProfession()
  if not open then return end
  local ok, ids = pcall(C_TradeSkillUI.GetAllRecipeIDs)
  if not ok or type(ids) ~= "table" then return end
  wipe(recipes)
  openID = open.id
  local book = {}
  for _, id in ipairs(ids) do
    local okInfo, info = pcall(C_TradeSkillUI.GetRecipeInfo, id)
    local name = okInfo and type(info) == "table" and Plain(info.name)
    if name and not info.isDummyRecipe then
      -- the trainer can teach a recipe before the window's own data catches up: the spellbook knows it at once
      local known = info.learned and true or false
      if not known and IsPlayerSpell then
        local okK, k = pcall(IsPlayerSpell, id)
        known = okK and Plain(k) == true
      end
      local entry = { id = id, learned = known, mats = {} }
      local okS, schematic = pcall(C_TradeSkillUI.GetRecipeSchematic, id, false)
      if okS and type(schematic) == "table" then
        for _, slot in ipairs(schematic.reagentSlotSchematics or {}) do
          local first = slot.reagents and slot.reagents[1]
          local itemID = first and Plain(first.itemID)
          local count = Plain(slot.quantityRequired)
          if itemID and count and count > 0 then
            -- by ID always (like Mastercraft): an item whose name isn't loaded yet still counts
            entry.matList = entry.matList or {}
            entry.matList[#entry.matList + 1] = { itemID, count }
            local itemName = NameByID(itemID)
            if not itemName and C_Item and C_Item.RequestLoadItemDataByID then pcall(C_Item.RequestLoadItemDataByID, itemID) end
            if itemName then
              ns.LearnItem(itemName, itemID)
              entry.mats[#entry.mats + 1] = itemName
              entry.mats[#entry.mats + 1] = count
              entry.matIDs = entry.matIDs or {}
              entry.matIDs[itemName] = itemID
            end
          end
        end
        local out = Plain(schematic.outputItemID)
        if out then
          entry.out = out
          local outName = NameByID(out)
          if outName then ns.LearnItem(outName, out) end
        end
        local made = Plain(schematic.quantityMin)
        entry.yield = type(made) == "number" and made > 0 and made or 1
      end
      entry.icon = Plain(info.icon)
      entry.diff = Plain(info.relativeDifficulty)
      if not entry.learned and C_TradeSkillUI.GetRecipeSourceText then
        local okSrc, text = pcall(C_TradeSkillUI.GetRecipeSourceText, id)
        if okSrc and type(Plain(text)) == "string" then entry.source = text end
      end
      book[#book + 1] = { name = name, entry = entry }
      -- a learned recipe wins over an unlearned one of the same name
      if not recipes[name] or (entry.learned and not recipes[name].learned) then
        recipes[name] = entry
      end
    end
  end
  ns.NoteSkill(open.id, open.rank)
  if ns.SaveBook then ns.SaveBook(open, book) end
end

function ns.Recipe(name)
  local entry = recipes[name]
  if not entry then return nil end
  return entry
end

-- how many of an item are in your bags: the game's count, else counted slot by slot
local function BagCount(id)
  if ItemCount then
    local ok, n = pcall(ItemCount, id)
    n = ok and tonumber(Plain(n)) or nil
    if n and n > 0 then return n end
  end
  local C = C_Container
  if not (C and C.GetContainerNumSlots and C.GetContainerItemInfo) then return 0 end
  local total = 0
  for bag = 0, 5 do   -- backpack, 4 bags, reagent bag
    local okN, slots = pcall(C.GetContainerNumSlots, bag)
    for slot = 1, (okN and tonumber(Plain(slots)) or 0) do
      local okI, info = pcall(C.GetContainerItemInfo, bag, slot)
      if okI and type(info) == "table" and Plain(info.itemID) == id then
        total = total + (tonumber(Plain(info.stackCount)) or 1)
      end
    end
  end
  return total
end
ns.BagCount = BagCount

-- how many you can craft now with what is in your bags
-- (the game's own number first; Forever often leaves it at 0, so then counted from your bags)
function ns.CanMake(name)
  local entry = recipes[name]
  if not entry or not entry.learned then return 0 end
  local ok, info = pcall(C_TradeSkillUI.GetRecipeInfo, entry.id)
  local n = tonumber(ok and type(info) == "table" and Plain(info.numAvailable)) or 0
  if n > 0 then return n end
  if entry.matList and #entry.matList > 0 then
    local can = math.huge
    for _, m in ipairs(entry.matList) do
      can = math.min(can, math.floor(BagCount(m[1]) / math.max(1, m[2])))
    end
    return can == math.huge and 0 or can
  end
  local mats = entry.mats or {}
  if #mats == 0 then return 0 end
  if not ItemCount then return 0 end
  local can = math.huge
  for i = 1, #mats, 2 do
    local id = (entry.matIDs and entry.matIDs[mats[i]]) or ns.ItemID(mats[i])
    local okC, have = pcall(ItemCount, id or mats[i])   -- bags only: what crafting can use
    have = okC and tonumber(Plain(have)) or 0
    can = math.min(can, math.floor(have / math.max(1, mats[i + 1] or 1)))
  end
  return can == math.huge and 0 or can
end

-- the materials of a guide craft: the game's when its recipe is known, else the guide's (per craft)
function ns.MatsPerCraft(entry)
  local recipe = recipes[entry[1]]
  if recipe and #recipe.mats > 0 then
    return recipe.mats, true
  end
  local per, list = {}, entry[3]
  for i = 1, #list, 2 do
    per[#per + 1] = list[i]
    per[#per + 1] = math.max(1, math.floor(list[i + 1] / math.max(1, entry[2]) + 0.5))
  end
  return per, false
end

function ns.Craft(name, count)
  local entry = recipes[name]
  if not entry or not entry.learned or count < 1 then return end
  if C_TradeSkillUI.CraftRecipe then
    local ok, err = pcall(C_TradeSkillUI.CraftRecipe, entry.id, count)
    if not ok then
      -- older form of the call: select the recipe, then craft
      if C_TradeSkillUI.OpenRecipe then pcall(C_TradeSkillUI.OpenRecipe, entry.id) end
      ok = pcall(C_TradeSkillUI.CraftRecipe, entry.id, count, {})
      if not ok then ns.Print("CraftETA: " .. tostring(err)) end
    end
  end
end

local function Changed()
  ns.ReadRecipes()
  if ns.Refresh then ns.Refresh() end
end
-- read again a moment later too: right after a trainer or a reopen the game's recipe data lags behind
local function Soon()
  Changed()
  C_Timer.After(0.5, Changed)
  C_Timer.After(2, Changed)
end
for _, event in ipairs({ "NEW_RECIPE_LEARNED", "LEARNED_SPELL_IN_TAB", "TRAINER_UPDATE", "TRAINER_CLOSED" }) do
  ns.Register(event)
  ns.On(event, Soon)
end
for _, event in ipairs({ "TRADE_SKILL_SHOW", "TRADE_SKILL_LIST_UPDATE", "TRADE_SKILL_DATA_SOURCE_CHANGED", "SKILL_LINES_CHANGED",
    "BAG_UPDATE_DELAYED", "TRADE_SKILL_CLOSE" }) do
  ns.Register(event)
  ns.On(event, function()
    if event == "TRADE_SKILL_CLOSE" then
      C_Timer.After(0, function() if ns.Refresh then ns.Refresh() end end)
    elseif event == "BAG_UPDATE_DELAYED" then
      if ns.Refresh then ns.Refresh() end
    elseif event == "TRADE_SKILL_SHOW" then
      Soon()
    else
      Changed()
    end
  end)
end

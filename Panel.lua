-- CraftETA: the panel next to the profession window. Your step in the route, what you still need,
-- Craft 1 / Craft all, and how far it is to your next rank and to 300.
local _, ns = ...
local T = ns.T

local WIDTH = 300
local MAX_MATS = 7
local P = ns.Window("CraftETAPanel", WIDTH)
ns.Panel = P

local profIcon = P:CreateTexture(nil, "ARTWORK")
profIcon:SetSize(16, 16)
profIcon:SetPoint("TOPLEFT", 14, -36)
profIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
local profText = ns.Font(P, true, 12, 1, 1, 1)
profText:SetPoint("LEFT", profIcon, "RIGHT", 6, 0)

local listButton = ns.IconButton(P, "Interface\\Icons\\INV_Misc_Note_05", 16, function() return T("list") end)
listButton:SetPoint("TOPRIGHT", -34, -10)
listButton:SetScript("OnClick", function() ns.ToggleList() end)
local hubButton = ns.IconButton(P, "Interface\\Icons\\INV_Misc_Book_09", 16, function() return T("hub") end)
hubButton:SetPoint("RIGHT", listButton, "LEFT", -6, 0)
hubButton:SetScript("OnClick", function() ns.ToggleHub() end)
local gearButton = ns.IconButton(P, "Interface\\Icons\\INV_Misc_Gear_01", 16, function() return T("settings") end)
gearButton:SetPoint("RIGHT", hubButton, "LEFT", -6, 0)
gearButton:SetScript("OnClick", function() ns.ToggleSettings() end)

local bar = ns.Bar(P, WIDTH - 28)
bar:SetPoint("TOPLEFT", 14, -58)

local etaRank = ns.Font(P, false, 11)
etaRank:SetPoint("TOPLEFT", 14, -70)
etaRank:SetPoint("RIGHT", P, "RIGHT", -14, 0)
local etaAll = ns.Font(P, false, 11, 0.65, 0.67, 0.72)
etaAll:SetPoint("TOPLEFT", etaRank, "BOTTOMLEFT", 0, -3)
etaAll:SetPoint("RIGHT", P, "RIGHT", -14, 0)

local warn = ns.Font(P, true, 11, 1, 0.6, 0.35)
warn:SetPoint("TOPLEFT", etaAll, "BOTTOMLEFT", 0, -8)
warn:SetPoint("RIGHT", P, "RIGHT", -14, 0)
warn:SetWordWrap(true)

-- the step
local stepHead = ns.Font(P, true, 10, 0.55, 0.58, 0.64)
local recipeIcon = P:CreateTexture(nil, "ARTWORK")
recipeIcon:SetSize(30, 30)
recipeIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
local recipeName = ns.Font(P, true, 13, 1, 0.82, 0.3)
recipeName:SetWordWrap(false)
local recipeCount = ns.Font(P, false, 11)
local prevChoice = ns.IconButton(P, "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up", 18)
local nextChoice = ns.IconButton(P, "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up", 18)
prevChoice.icon:SetTexCoord(0, 1, 0, 1)
nextChoice.icon:SetTexCoord(0, 1, 0, 1)

local matRows = {}
for i = 1, MAX_MATS do
  local r = ns.Row(P, 18)
  r:SetWidth(WIDTH - 28)
  r:SetScript("OnEnter", function(self)
    if self.itemID then
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetItemByID(self.itemID)
      GameTooltip:Show()
    end
  end)
  r:SetScript("OnLeave", function() GameTooltip:Hide() end)
  matRows[i] = r
end

local note = ns.Font(P, false, 10, 0.75, 0.72, 0.6)
note:SetWordWrap(true)
note:SetWidth(WIDTH - 28)

local craft1 = ns.Button(P, T("craft1"), 78, 22)
local craftAll = ns.Button(P, T("craftAll"), 78, 22)
local addList = ns.Button(P, T("addList"), 104, 22)
local status = ns.Font(P, false, 10, 0.65, 0.67, 0.72)
status:SetWordWrap(true)
status:SetWidth(WIDTH - 28)
local nextLine = ns.Font(P, false, 10, 0.55, 0.58, 0.64)
nextLine:SetWordWrap(false)
nextLine:SetWidth(WIDTH - 28)
local source = ns.Font(P, false, 9, 0.42, 0.43, 0.47)

local state = {}

craft1:SetScript("OnClick", function()
  if state.recipe then ns.Craft(state.recipe, 1) end
end)
craftAll:SetScript("OnClick", function()
  if state.recipe then ns.Craft(state.recipe, math.max(1, math.min(state.canMake or 0, state.left or 0))) end
end)
addList.tip = "Click: to next rank\nShift-click: this step\nRight-click: to 300"
addList:RegisterForClicks("LeftButtonUp", "RightButtonUp")
addList:SetScript("OnClick", function(_, button)
  if not state.prof then return end
  local target = state.target
  if button == "RightButton" then
    target = 300
  elseif IsShiftKeyDown() and state.step then
    target = math.min(state.step[2], state.target)
  end
  ns.AddToList(nil, nil, state.prof, target)
  ns.Print(T("addedList"))
end)

local function SwitchChoice(delta)
  local step, index = state.step, state.index
  if not step then return end
  local entries = ns.Entries(step)
  if #entries < 2 then return end
  local key = state.prof .. ":" .. index
  local current = ns.db.choice[key] or state.pick or 1
  ns.db.choice[key] = ((current - 1 + delta) % #entries) + 1
  ns.Refresh()
end
prevChoice:SetScript("OnClick", function() SwitchChoice(-1) end)
nextChoice:SetScript("OnClick", function() SwitchChoice(1) end)

ns.PROF_ICON = {
  [171] = "Interface\\Icons\\Trade_Alchemy", [164] = "Interface\\Icons\\Trade_BlackSmithing",
  [333] = "Interface\\Icons\\Trade_Engraving", [202] = "Interface\\Icons\\Trade_Engineering",
  [165] = "Interface\\Icons\\Trade_LeatherWorking", [197] = "Interface\\Icons\\Trade_Tailoring",
  [129] = "Interface\\Icons\\Spell_Holy_SealOfSacrifice", [185] = "Interface\\Icons\\INV_Misc_Food_15",
}
local PROF_ICON = ns.PROF_ICON

local function RecipeIcon(name, entry)
  local recipe = ns.Recipe(name)
  if recipe and C_TradeSkillUI and C_TradeSkillUI.GetRecipeInfo then
    local ok, info = pcall(C_TradeSkillUI.GetRecipeInfo, recipe.id)
    if ok and type(info) == "table" and info.icon then return info.icon end
  end
  return ns.ItemIcon(name) ~= 134400 and ns.ItemIcon(name) or (entry and ns.ItemIcon(entry[3][1])) or 134400
end

-- which profession the panel shows: the open window's, else the last one, else one you have
local function PickProfession(skills)
  local open = ns.OpenProfession()
  if open then
    ns.db.lastProf = open.id
    return open.id, open
  end
  if ns.db.lastProf and skills[ns.db.lastProf] then
    return ns.db.lastProf
  end
  for id in pairs(skills) do
    return id
  end
  return nil
end

function ns.RefreshPanel()
  if not P:IsShown() or not ns.db then return end
  local skills = ns.Skills()
  local profID, open = PickProfession(skills)
  local guide = profID and ns.GUIDES[profID]
  local y = -36
  for _, r in ipairs(matRows) do r:Hide() end
  prevChoice:Hide(); nextChoice:Hide()
  wipe(state)
  if not guide then
    profIcon:Hide()
    profText:SetText(T("noProf"))
    for _, w in ipairs({ bar, etaRank, etaAll, warn, stepHead, recipeName, recipeCount, note, craft1, craftAll, addList, status, nextLine, source }) do w:Hide() end
    recipeIcon:Hide()
    P:SetHeight(80)
    return
  end
  local skill = skills[profID] or { rank = open and open.rank or 1, max = open and open.max or 75 }
  local rank, max = skill.rank, skill.max
  ns.NoteSkill(profID, rank)
  state.prof, state.rank = profID, rank
  state.target = ns.Target(profID, rank, max)
  profIcon:SetTexture(PROF_ICON[profID]); profIcon:Show()
  profText:SetText(("%s  |cffffd24a%d|r / %d"):format(open and open.name or guide.name, rank, max))
  bar:SetValue(rank); bar:Show()

  -- how far: to the rank cap and to 300
  local function etaLine(target, label)
    local crafts, mats = ns.Plan(profID, rank, target)
    local cost, unknown = ns.Cost(mats)
    local time = ns.Duration(ns.TimeFor(profID, target - rank, crafts))
    local parts = { label, T("crafts", crafts) }
    if cost > 0 or not unknown then parts[#parts + 1] = ns.Money(cost) .. (unknown and "+" or "") end
    if time then parts[#parts + 1] = T("eta", time) end
    return table.concat(parts, "  ·  ")
  end
  etaRank:Show(); etaAll:Show()
  if rank >= 300 then
    etaRank:SetText("|cff4dcc66" .. T("done") .. "|r")
    etaAll:SetText("")
  else
    etaRank:SetText(etaLine(state.target, "|cffffffff" .. T("toRank", state.target) .. "|r"))
    local rate = ns.PerHour(profID)
    etaAll:SetText(state.target < 300 and etaLine(300, T("to300")) or (rate and T("perHour", rate) or ""))
  end
  y = -70 - 32

  -- a rank to learn
  local nextRank = ns.NextRank(profID, rank, max)
  if nextRank and rank >= nextRank.need then
    local names = { [75] = "Journeyman", [150] = "Expert", [225] = "Artisan" }
    warn:SetText(T("learnRank", names[nextRank.at] or "") .. ": " .. (nextRank[ns.Faction()] or "")
      .. ((UnitLevel("player") or 0) < nextRank.lvl and ("  (level " .. nextRank.lvl .. ")") or ""))
    warn:Show()
    y = y - 8 - warn:GetStringHeight() - 4
  else
    warn:SetText(""); warn:Hide()
  end

  -- the step
  local index = ns.StepIndex(guide, rank)
  if not index then
    for _, w in ipairs({ stepHead, recipeName, recipeCount, note, craft1, craftAll, addList, status, nextLine }) do w:Hide() end
    recipeIcon:Hide()
    source:ClearAllPoints(); source:SetPoint("TOPLEFT", 14, y - 6); source:SetText(T("source", ns.SOURCE)); source:Show()
    P:SetHeight(-y + 32)
    return
  end
  local step = guide.steps[index]
  local entries, pick = ns.Chosen(profID, index, step)
  state.step, state.index, state.pick = step, index, pick
  y = y - 6
  stepHead:ClearAllPoints(); stepHead:SetPoint("TOPLEFT", 14, y)
  stepHead:SetText(string.upper(T("stepOf", index, #guide.steps) .. "  ·  " .. step[1] .. "-" .. step[2])); stepHead:Show()
  y = y - 16

  -- in a step of several crafts, the first one not done (in order); a done one has its points
  local all = ns.Entries(step)
  local show = step.any and (pick or 1) or (ns.db.choice[profID .. ":" .. index] or 1)
  if not all[show] then show = 1 end
  state.pick = show
  local entry = all[show]
  local share = math.min(1, (step[2] - math.max(step[1], rank)) / math.max(1, step[2] - step[1]))
  local left = math.ceil(entry[2] * share)
  state.recipe, state.left = entry[1], left

  recipeIcon:ClearAllPoints(); recipeIcon:SetPoint("TOPLEFT", 14, y)
  recipeIcon:SetTexture(RecipeIcon(entry[1], entry)); recipeIcon:Show()
  recipeName:ClearAllPoints(); recipeName:SetPoint("TOPLEFT", recipeIcon, "TOPRIGHT", 8, 0)
  recipeName:SetPoint("RIGHT", P, "RIGHT", #all > 1 and -54 or -14, 0)
  recipeName:SetText(entry[1]); recipeName:Show()
  recipeCount:ClearAllPoints(); recipeCount:SetPoint("BOTTOMLEFT", recipeIcon, "BOTTOMRIGHT", 8, 0)
  recipeCount:SetText(T("make", entry[2]) .. "  ·  |cffffffff" .. T("left", left) .. "|r"); recipeCount:Show()
  if #all > 1 then
    nextChoice:ClearAllPoints(); nextChoice:SetPoint("TOPRIGHT", -14, y - 6); nextChoice:Show()
    prevChoice:ClearAllPoints(); prevChoice:SetPoint("RIGHT", nextChoice, "LEFT", -2, 0); prevChoice:Show()
  end
  y = y - 38

  -- materials for what is left of the step
  local per, fromGame = ns.MatsPerCraft(entry)
  local shown = 0
  for i = 1, #per, 2 do
    shown = shown + 1
    local r = matRows[shown]
    if not r then break end
    local name, need = per[i], per[i + 1] * left
    local have = ns.Have(name)
    r.itemID = ns.ItemID(name)
    r.icon:SetTexture(ns.ItemIcon(name))
    r.name:SetText(name)
    r.value:SetText((have >= need and "|cff4dcc66" or "|cffe8574a") .. have .. "|r / " .. need)
    r:ClearAllPoints(); r:SetPoint("TOPLEFT", 14, y); r:Show()
    y = y - 19
  end

  if step.note then
    note:ClearAllPoints(); note:SetPoint("TOPLEFT", 14, y - 4); note:SetText(step.note); note:Show()
    y = y - 4 - note:GetStringHeight() - 2
  else
    note:Hide()
  end

  -- crafting
  y = y - 8
  craft1:ClearAllPoints(); craft1:SetPoint("TOPLEFT", 14, y)
  craftAll:ClearAllPoints(); craftAll:SetPoint("LEFT", craft1, "RIGHT", 6, 0)
  addList:ClearAllPoints(); addList:SetPoint("LEFT", craftAll, "RIGHT", 6, 0)
  craft1:Show(); craftAll:Show(); addList:Show()
  local recipe = ns.Recipe(entry[1])
  state.canMake = ns.CanMake(entry[1])
  local text
  if not open then
    text = T("openWindow")
  elseif not recipe or not recipe.learned then
    text = T("needRecipe")
  end
  if text or state.canMake < 1 then
    craft1:Disable(); craftAll:Disable()
  else
    craft1:Enable(); craftAll:Enable()
    craftAll:SetText(T("craftAll") .. " (" .. math.min(state.canMake, left) .. ")")
  end
  y = y - 28
  if text then
    status:ClearAllPoints(); status:SetPoint("TOPLEFT", 14, y); status:SetText(text); status:Show()
    y = y - status:GetStringHeight() - 4
  else
    status:Hide()
  end

  -- the next step
  local after = guide.steps[index + 1]
  if ns.db.showNext and after then
    local names = {}
    for _, e in ipairs(ns.Entries(after)) do names[#names + 1] = e[1] end
    nextLine:ClearAllPoints(); nextLine:SetPoint("TOPLEFT", 14, y - 2)
    nextLine:SetText(T("next", after[1] .. "-" .. after[2] .. "  " .. table.concat(names, after.any and " / " or " + ")))
    nextLine:Show()
    y = y - 16
  else
    nextLine:Hide()
  end
  source:ClearAllPoints(); source:SetPoint("TOPLEFT", 14, y - 4); source:SetText(T("source", ns.SOURCE)); source:Show()
  y = y - 16
  P:SetHeight(-y + 22)
end

-- docked to the right of the profession window while it is open; free otherwise
function ns.PlacePanel()
  local frame = ns.ProfessionFrame()
  if frame and ns.db.panel then
    P.docked = true
    P:ClearAllPoints()
    P:SetPoint("TOPLEFT", frame, "TOPRIGHT", 4, 0)
  else
    P.docked = false
    ns.PlaceSaved(P, "CraftETAPanel", "CENTER", UIParent, "CENTER", 300, 0)
  end
end

local pending
function ns.Refresh()
  if pending then return end
  pending = true
  C_Timer.After(0.1, function()
    pending = false
    if ns.RefreshPanel then ns.RefreshPanel() end
    if ns.RefreshList then ns.RefreshList() end
  end)
end

P:SetScript("OnShow", function() ns.PlacePanel(); ns.RefreshPanel() end)

-- opens and closes with the profession window
ns.Register("TRADE_SKILL_SHOW")
ns.On("TRADE_SKILL_SHOW", function()
  if not ns.db or not ns.db.panel then return end
  C_Timer.After(0.05, function()
    P.byWindow = true
    P:Show()
    ns.PlacePanel()
    ns.Refresh()
  end)
end)
ns.Register("TRADE_SKILL_CLOSE")
ns.On("TRADE_SKILL_CLOSE", function()
  if P.byWindow then
    P.byWindow = false
    P:Hide()
  end
end)

function ns.TogglePanel()
  if P:IsShown() then
    P:Hide()
  else
    P.byWindow = false
    P:Show()
  end
end

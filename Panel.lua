-- CraftETA: the panel next to the profession window. Your step in the route, what you still need,
-- Craft 1 / Craft all, and how far it is to your next rank and to 300.
local _, ns = ...
local T = ns.T

local WIDTH = 300
local MAX_MATS = 7
local P = ns.Window("CraftETAPanel", WIDTH)
ns.Panel = P

-- 2.0 look: the profession and your skill big at the top, the step in a card of its own
local function Fill(parent, layer, r, g, b, a)
  local t = parent:CreateTexture(nil, layer or "BACKGROUND", nil, 1)
  t:SetColorTexture(r, g, b, a or 1)
  return t
end

local profIcon = P:CreateTexture(nil, "ARTWORK")
profIcon:SetSize(28, 28)
profIcon:SetPoint("TOPLEFT", 14, -40)
profIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
local profText = ns.Font(P, true, 14, 0.9, 0.91, 0.94)
profText:SetPoint("TOPLEFT", profIcon, "TOPRIGHT", 9, 1)
profText:SetPoint("RIGHT", P, "RIGHT", -70, 0)
profText:SetWordWrap(false)
local profSub = ns.Font(P, false, 10, 0.5, 0.52, 0.57)
profSub:SetPoint("BOTTOMLEFT", profIcon, "BOTTOMRIGHT", 9, 0)
local bigRank = ns.Font(P, true, 20, 1, 0.82, 0.29)
bigRank:SetPoint("TOPRIGHT", P, "TOPRIGHT", -14, -38)
bigRank:SetJustifyH("RIGHT")
local bigOf = ns.Font(P, false, 9, 0.36, 0.38, 0.42)
bigOf:SetPoint("TOPRIGHT", bigRank, "BOTTOMRIGHT", 0, -1)
bigOf:SetJustifyH("RIGHT")

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
bar:SetPoint("TOPLEFT", 14, -80)

local etaRank = ns.Font(P, false, 10, 0.85, 0.87, 0.9)
etaRank:SetPoint("TOPLEFT", 14, -93)
etaRank:SetPoint("RIGHT", P, "RIGHT", -14, 0)
local etaAll = ns.Font(P, false, 10, 0.5, 0.52, 0.57)
etaAll:SetPoint("TOPLEFT", etaRank, "BOTTOMLEFT", 0, -3)
etaAll:SetPoint("RIGHT", P, "RIGHT", -14, 0)

local warnBg = Fill(P, "BACKGROUND", 0.2, 0.149, 0.086)
warnBg:Hide()
local warn = ns.Font(P, true, 10, 1, 0.69, 0.38)
warn:SetPoint("RIGHT", P, "RIGHT", -40, 0)
warn:SetWordWrap(true)
-- the map button beside it: an arrow to the trainer (Places.lua)
local warnPin = ns.MapButton(P, function()
  return (ns.db and ns.db.lang == "da") and "Vis træneren på kortet" or "Show the trainer on the map"
end, function() if ns.panelState and ns.panelState.prof then ns.ShowTrainer(ns.panelState.prof) end end)
warnPin:SetPoint("TOPRIGHT", P, "TOPRIGHT", -14, 0)
warnPin:Hide()

-- the step, in its card
local card = Fill(P, "BACKGROUND", 0.086, 0.094, 0.122)
card:Hide()
local stepHead = ns.Font(P, true, 9, 0.36, 0.38, 0.42)
local recipeIcon = P:CreateTexture(nil, "ARTWORK")
recipeIcon:SetSize(36, 36)
recipeIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
local recipeName = ns.Font(P, true, 14, 1, 0.82, 0.29)
recipeName:SetWordWrap(false)
local diffDot = P:CreateTexture(nil, "ARTWORK")
diffDot:SetSize(7, 7)
local recipeCount = ns.Font(P, false, 10, 0.5, 0.52, 0.57)
-- "2 left" as a small green pill
local leftPill = CreateFrame("Frame", nil, P)
leftPill:SetSize(52, 18)
local leftBg = Fill(leftPill, "BACKGROUND", 0.118, 0.204, 0.141)
leftBg:SetAllPoints()
local leftText = ns.Font(leftPill, true, 10, 0.36, 0.84, 0.49)
leftText:SetPoint("CENTER")
local DIFF_COLOR = { [0] = { 1, 0.55, 0.25 }, [1] = { 1, 0.9, 0.3 }, [2] = { 0.35, 0.8, 0.4 }, [3] = { 0.5, 0.5, 0.5 } }
local prevChoice = ns.IconButton(P, "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up", 18)
local nextChoice = ns.IconButton(P, "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up", 18)
prevChoice.icon:SetTexCoord(0, 1, 0, 1)
nextChoice.icon:SetTexCoord(0, 1, 0, 1)

local matRows = {}
for i = 1, MAX_MATS do
  local r = ns.Row(P, 20)
  r:SetWidth(WIDTH - 52)
  r.name:ClearAllPoints()
  r.name:SetPoint("TOPLEFT", r.icon, "TOPRIGHT", 8, 1)
  r.name:SetPoint("RIGHT", r.value, "LEFT", -6, 0)
  r.value:ClearAllPoints()
  r.value:SetPoint("TOPRIGHT", 0, 1)
  r.track = Fill(r, "ARTWORK", 0.133, 0.145, 0.184)
  r.track:SetHeight(3)
  r.track:SetPoint("BOTTOMLEFT", r.icon, "BOTTOMRIGHT", 8, 0)
  r.track:SetPoint("RIGHT", r, "RIGHT", 0, 0)
  r.fillBar = Fill(r, "OVERLAY", 0.36, 0.84, 0.49)
  r.fillBar:SetHeight(3)
  r.fillBar:SetPoint("LEFT", r.track, "LEFT")
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

local note = ns.Font(P, false, 10, 0.78, 0.72, 0.58)
note:SetWordWrap(true)
note:SetWidth(WIDTH - 52)

-- one Craft button that follows the guide: what the step still needs, and first any material for it
-- that you can make yourself (a grinding stone, a bolt) but don't have enough of
local craftBtn = ns.Button(P, T("craft"), WIDTH - 52 - 34, 28)
local craftFill = craftBtn:CreateTexture(nil, "BACKGROUND", nil, 2)
craftFill:SetAllPoints()
craftFill:SetColorTexture(1, 0.82, 0.29, 1)
craftBtn.label:SetFont(ns.F_BOLD, 13, "")
craftBtn.label:SetShadowOffset(0, 0)
local function CraftLook(on)
  craftFill:SetColorTexture(on and 1 or 0.2, on and 0.82 or 0.19, on and 0.29 or 0.15, 1)
  craftBtn.label:SetTextColor(on and 0.1 or 0.45, on and 0.08 or 0.45, on and 0.03 or 0.47)
end
hooksecurefunc(craftBtn, "Enable", function() CraftLook(true) end)
hooksecurefunc(craftBtn, "Disable", function() CraftLook(false) end)
CraftLook(true)
local addList = ns.Button(P, "+", 28, 28)
addList.label:SetFont(ns.F_BOLD, 16, "")
addList.label:SetTextColor(0.85, 0.87, 0.9)
hooksecurefunc(addList, "Enable", function() addList.label:SetTextColor(0.85, 0.87, 0.9) end)
local status = ns.Font(P, false, 10, 0.6, 0.62, 0.67)
status:SetWordWrap(true)
status:SetWidth(WIDTH - 52)
local nextHead = ns.Font(P, true, 8, 0.36, 0.38, 0.42)
local nextLine = ns.Font(P, false, 10, 0.5, 0.52, 0.57)
nextLine:SetWordWrap(false)
nextLine:SetWidth(WIDTH - 66)
local source = ns.Font(P, false, 9, 0.42, 0.43, 0.47)

local state = {}
ns.panelState = state

-- skip a step (or go back to the one your skill is on)
local skipBack = ns.IconButton(P, "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up", 16, function() return T("stepBack") end)
local skipNext = ns.IconButton(P, "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up", 16, function() return T("stepSkip") end)
skipBack.icon:SetTexCoord(0, 1, 0, 1)
skipNext.icon:SetTexCoord(0, 1, 0, 1)
local function Skip(delta)
  if not state.prof or not state.index then return end
  local guide = ns.GUIDES[state.prof]
  local base = ns.StepIndex(guide, state.rank)
  local to = math.max(base, math.min(#guide.steps, state.index + delta))
  ns.db.view = ns.db.view or {}
  ns.db.view[state.prof] = to > base and to or nil
  ns.Refresh()
end
skipBack:SetScript("OnClick", function() Skip(-1) end)
skipNext:SetScript("OnClick", function() Skip(1) end)
ns.SkipStep = Skip


craftBtn:SetScript("OnClick", function()
  -- Mining: smelt the best smelt right now (see RefreshGatherPanel)
  if state.smelt and C_TradeSkillUI and C_TradeSkillUI.CraftRecipe then
    local ok, err = pcall(C_TradeSkillUI.CraftRecipe, state.smelt.id, state.smelt.count)
    if not ok then ns.Print(tostring(err)) end
    return
  end
  local job = state.job
  if job then ns.Craft(job.name, job.count) end
end)

addList:RegisterForClicks("LeftButtonUp", "RightButtonUp")
addList:SetScript("OnClick", function(_, button)
  if not state.prof then return end
  local target = state.target
  if button == "RightButton" then
    target = 300
  elseif not IsShiftKeyDown() and state.step then
    target = math.min(state.step[2], state.target)
  end
  ns.AddToList(nil, nil, state.prof, target)
  ns.Print(T("addedList") .. " (" .. (state.rank or "") .. " - " .. target .. ")")
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

-- a gathering profession in the open window (Mining, with its smelting): its guide is a gathering route
local function OpenGather()
  if not ns.ProfessionFrame() or not (C_TradeSkillUI and C_TradeSkillUI.GetBaseProfessionInfo) then return nil end
  local ok, base = pcall(C_TradeSkillUI.GetBaseProfessionInfo)
  if not ok or type(base) ~= "table" then return nil end
  local Plain = ns.Plain
  local id = Plain(base.professionID)
  if not (ns.GATHER and ns.GATHER[id]) then id = ns.GATHER_BY_NAME and ns.GATHER_BY_NAME[Plain(base.professionName) or ""] end
  if not (id and ns.GATHER and ns.GATHER[id]) then return nil end
  return { id = id, rank = Plain(base.skillLevel) or 0, max = Plain(base.maxSkillLevel) or 300, name = Plain(base.professionName), gather = true }
end

-- which profession the panel shows: the open window's, else the last one, else one you have
local function PickProfession(skills)
  local g = OpenGather()
  if g then return g.id, g end
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
  if open and open.gather then return ns.RefreshGatherPanel(open) end
  if not guide then
    warnPin:Hide()
    profIcon:Hide()
    profText:SetText(T("noProf"))
    for _, w in ipairs({ bar, etaRank, etaAll, warn, warnBg, card, stepHead, recipeName, recipeCount, diffDot, leftPill, note, craftBtn, addList, status, nextHead, nextLine, source, profSub, bigRank, bigOf }) do w:Hide() end
    recipeIcon:Hide()
    P:SetHeight(90)
    return
  end
  local skill = skills[profID] or { rank = open and open.rank or 1, max = open and open.max or 75 }
  local rank, max = skill.rank, skill.max
  ns.NoteSkill(profID, rank)
  state.prof, state.rank = profID, rank
  state.target = ns.Target(profID, rank, max)
  profIcon:SetTexture(PROF_ICON[profID]); profIcon:Show()
  profText:SetText(open and open.name or guide.name)
  local RANKS = { [75] = "Apprentice", [150] = "Journeyman", [225] = "Expert", [300] = "Artisan" }
  local idx = ns.StepIndex(guide, rank)
  profSub:SetText((RANKS[max] or "") .. (idx and ("  ·  " .. T("stepOf", idx, #guide.steps)) or "")); profSub:Show()
  bigRank:SetText(rank); bigRank:Show()
  bigOf:SetText("/ " .. max); bigOf:Show()
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
  y = -93 - 30

  -- a rank to learn
  local nextRank = ns.NextRank(profID, rank, max)
  if nextRank and rank >= nextRank.need then
    local names = { [75] = "Journeyman", [150] = "Expert", [225] = "Artisan" }
    warn:SetText(T("learnRank", names[nextRank.at] or "") .. ": " .. (nextRank[ns.Faction()] or "")
      .. ((UnitLevel("player") or 0) < nextRank.lvl and ("  (level " .. nextRank.lvl .. ")") or ""))
    warn:ClearAllPoints(); warn:SetPoint("TOPLEFT", 24, y - 14); warn:SetPoint("RIGHT", P, "RIGHT", -40, 0)
    warn:Show()
    local h = warn:GetStringHeight() + 14
    warnBg:ClearAllPoints(); warnBg:SetPoint("TOPLEFT", 14, y - 7); warnBg:SetPoint("RIGHT", P, "RIGHT", -14, 0)
    warnBg:SetHeight(h); warnBg:Show()
    warnPin:ClearAllPoints(); warnPin:SetPoint("RIGHT", warnBg, "RIGHT", -8, 0); warnPin:Show()
    y = y - 7 - h - 2
  else
    warn:SetText(""); warn:Hide(); warnPin:Hide(); warnBg:Hide()
  end

  -- the step: the one your skill is on, or one you skipped ahead to
  local index = ns.StepIndex(guide, rank)
  local base = index
  local view = ns.db.view and ns.db.view[profID]
  if index and view then
    if view > index and guide.steps[view] then index = view else ns.db.view[profID] = nil end
  end
  if not index then
    for _, w in ipairs({ card, stepHead, recipeName, recipeCount, diffDot, leftPill, note, craftBtn, addList, status, nextHead, nextLine, skipBack, skipNext }) do w:Hide() end
    recipeIcon:Hide()
    source:Hide()
    P:SetHeight(-y + 32)
    return
  end
  local step = guide.steps[index]
  local entries, pick = ns.Chosen(profID, index, step)
  state.step, state.index, state.pick = step, index, pick
  y = y - 8
  local cardTop = y
  y = y - 12
  stepHead:ClearAllPoints(); stepHead:SetPoint("TOPLEFT", 26, y)
  stepHead:SetText(string.upper(step[1] .. " - " .. step[2] .. "  ·  " .. T("stepOf", index, #guide.steps)
    .. (index > base and ("  ·  " .. T("skippedAhead")) or ""))); stepHead:Show()
  skipNext:ClearAllPoints(); skipNext:SetPoint("TOPRIGHT", -24, y + 3)
  skipBack:ClearAllPoints(); skipBack:SetPoint("RIGHT", skipNext, "LEFT", -2, 0)
  skipNext:SetShown(index < #guide.steps)
  skipBack:SetShown(index > base)
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

  y = y - 4
  recipeIcon:ClearAllPoints(); recipeIcon:SetPoint("TOPLEFT", 26, y)
  recipeIcon:SetTexture(RecipeIcon(entry[1], entry)); recipeIcon:Show()
  recipeName:ClearAllPoints(); recipeName:SetPoint("TOPLEFT", recipeIcon, "TOPRIGHT", 10, -1)
  recipeName:SetPoint("RIGHT", P, "RIGHT", -86, 0)
  recipeName:SetText(entry[1]); recipeName:Show()
  -- the skill-up colour as a dot (orange, yellow, green, grey), when the game knows it
  local rec = ns.Recipe(entry[1])
  local c = rec and DIFF_COLOR[rec.diff or -1]
  diffDot:ClearAllPoints(); diffDot:SetPoint("BOTTOMLEFT", recipeIcon, "BOTTOMRIGHT", 10, 4)
  if c then diffDot:SetColorTexture(c[1], c[2], c[3], 1); diffDot:Show() else diffDot:Hide() end
  recipeCount:ClearAllPoints()
  recipeCount:SetPoint("LEFT", diffDot, c and "RIGHT" or "LEFT", c and 6 or 0, 0)
  local countText = T("make", entry[2])
  -- the chance of a skill-up on it now
  if rec and rec.id and rec.learned and ns.SkillUpChance then
    local chance, col = ns.SkillUpChance(rec.id, rank, rec.diff)
    if chance and col ~= 3 then countText = countText .. "  ·  " .. ns.ChanceText(chance, col) end
  end
  recipeCount:SetText(countText); recipeCount:Show()
  leftText:SetText(T("left", left))
  leftPill:SetWidth(math.max(44, leftText:GetStringWidth() + 18))
  leftPill:ClearAllPoints(); leftPill:SetPoint("TOPRIGHT", P, "TOPRIGHT", -26, y - 3); leftPill:Show()
  if #all > 1 then
    nextChoice:ClearAllPoints(); nextChoice:SetPoint("TOPRIGHT", P, "TOPRIGHT", -26, y - 22); nextChoice:Show()
    prevChoice:ClearAllPoints(); prevChoice:SetPoint("RIGHT", nextChoice, "LEFT", -2, 0); prevChoice:Show()
  end
  y = y - 46

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
    local ok = have >= need
    r.value:SetText((ok and "|cff5cd67c" or "|cffe8574a") .. have .. " / " .. need .. "|r")
    r:ClearAllPoints(); r:SetPoint("TOPLEFT", 26, y); r:Show()
    r.track:Show(); r.fillBar:Show()
    local w = r.track:GetWidth()
    if not w or w < 10 then w = WIDTH - 52 - 28 end
    r.fillBar:SetWidth(math.max(1, w * math.min(1, need > 0 and have / need or 1)))
    if ok then r.fillBar:SetColorTexture(0.36, 0.84, 0.49, 1) else r.fillBar:SetColorTexture(0.91, 0.34, 0.29, 1) end
    y = y - 26
  end

  if step.note then
    note:ClearAllPoints(); note:SetPoint("TOPLEFT", 26, y - 4); note:SetText(step.note); note:Show()
    y = y - 4 - note:GetStringHeight() - 2
  else
    note:Hide()
  end

  -- crafting
  y = y - 8
  craftBtn:ClearAllPoints(); craftBtn:SetPoint("TOPLEFT", 26, y)
  craftBtn:SetWidth(WIDTH - 52 - 34)
  addList:ClearAllPoints(); addList:SetPoint("LEFT", craftBtn, "RIGHT", 6, 0)
  craftBtn:Show(); addList:Show()
  addList.tip = T("addListTip")
  local recipe = ns.Recipe(entry[1])
  state.canMake = ns.CanMake(entry[1])
  local text
  if not open then
    text = T("openWindow")
  elseif not recipe or not recipe.learned then
    text = T("needRecipe")
  end
  -- what the button makes: the step's craft, or first a material for it you can make yourself
  state.job = nil
  if not text and left > 0 then
    if state.canMake >= left then
      state.job = { name = entry[1], count = left }
    else
      local per = ns.MatsPerCraft(entry)
      for i = 1, #per, 2 do
        local mat, need = per[i], per[i + 1] * left
        local short = need - ns.Have(mat)
        local sub = short > 0 and ns.Recipe(mat)
        if sub and sub.learned and ns.CanMake(mat) > 0 then
          state.job = { name = mat, count = math.min(short, ns.CanMake(mat)), sub = true }
          break
        end
      end
      if not state.job and state.canMake > 0 then state.job = { name = entry[1], count = state.canMake } end
    end
    -- like Mastercraft: the recipe is learned and the window is open, so the button always works.
    -- If our count of your bags is off, the game itself crafts what your materials allow.
    if not state.job then state.job = { name = entry[1], count = left, unsure = true } end
  end
  state.why = text or (left <= 0 and "step done") or nil
  local job = state.job
  if job then
    craftBtn:Enable()
    craftBtn:SetText(job.sub and T("craftSub", job.count) or T("craftN", job.count))
    craftBtn.tip = job.sub and T("craftFirst", job.count, job.name) or T("craftTip", job.count, job.name)
  else
    craftBtn:Disable()
    craftBtn:SetText(T("craft"))
    craftBtn.tip = nil
  end
  y = y - 34
  if text then
    status:ClearAllPoints(); status:SetPoint("TOPLEFT", 26, y); status:SetText(text); status:Show()
    y = y - status:GetStringHeight() - 4
  else
    status:Hide()
  end
  -- the card around the step
  y = y - 8
  card:ClearAllPoints(); card:SetPoint("TOPLEFT", 14, cardTop); card:SetPoint("RIGHT", P, "RIGHT", -14, 0)
  card:SetHeight(cardTop - y); card:Show()

  -- the next step
  local after = guide.steps[index + 1]
  if ns.db.showNext and after then
    local names = {}
    for _, e in ipairs(ns.Entries(after)) do names[#names + 1] = e[1] end
    nextHead:ClearAllPoints(); nextHead:SetPoint("TOPLEFT", 14, y - 12)
    nextHead:SetText((ns.db.lang == "da") and "NÆSTE" or "NEXT"); nextHead:Show()
    nextLine:ClearAllPoints(); nextLine:SetPoint("LEFT", nextHead, "RIGHT", 10, 0)
    nextLine:SetText(after[1] .. " - " .. after[2] .. "   " .. table.concat(names, after.any and " / " or " + "))
    nextLine:Show()
    y = y - 22
  else
    nextLine:Hide(); nextHead:Hide()
  end
  source:Hide()
  P:SetHeight(-y + 22)
end

-- docked to the right of the profession window while it is open; free otherwise
function ns.PlacePanel()
  local frame = ns.ProfessionFrame()
  if frame and ns.db.panel then
    P.docked = true
    P:ClearAllPoints()
    -- right of the profession window, unless that covers the bars and trackers along the right edge
    -- of the screen (about 260 px kept free): then on its left. The setting can fix the side.
    local side = ns.db.panelSide or "auto"
    if side == "auto" then
      local screenR = UIParent:GetRight() or 0
      local scale = frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
      local right, left = (frame:GetRight() or 0) * scale, (frame:GetLeft() or 0) * scale
      local w = P:GetWidth() + 8
      side = (screenR - right < w + 260 and left > w) and "left" or "right"
    end
    if side == "left" then
      P:SetPoint("TOPRIGHT", frame, "TOPLEFT", -14, 0)
    else
      P:SetPoint("TOPLEFT", frame, "TOPRIGHT", 56, 0)   -- clear of the profession tabs along its right edge
    end
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

-- opens and closes with the profession window: on the game's event and when the window itself shows
-- (Forever can show the window before or after the event), placed again once it has its size
local function OpenWithWindow()
  if not ns.db or not ns.db.panel then return end
  C_Timer.After(0.05, function()
    if not ns.ProfessionFrame() then return end
    P.byWindow = true
    P:Show()
    ns.PlacePanel()
    ns.Refresh()
  end)
  C_Timer.After(0.4, function() if P:IsShown() then ns.PlacePanel(); ns.Refresh() end end)
end
ns.Register("TRADE_SKILL_SHOW")
ns.On("TRADE_SKILL_SHOW", OpenWithWindow)
local hooked = {}
local function HookWindows()
  for _, name in ipairs({ "ProfessionsFrame", "TradeSkillFrame" }) do
    local f = _G[name]
    if f and not hooked[name] then
      hooked[name] = true
      f:HookScript("OnShow", OpenWithWindow)
      f:HookScript("OnHide", function()
        if P.byWindow then P.byWindow = false; P:Hide() end
      end)
    end
  end
end
HookWindows()
ns.Register("ADDON_LOADED")
ns.On("ADDON_LOADED", function(name)
  if name == "Blizzard_Professions" or name == "Blizzard_TradeSkillUI" then HookWindows() end
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

-- Mining (or another gathering profession) open in the window: the gathering route in the same look.
-- The step card says what to gather and where (your faction's zones), and the guide's tip.
function ns.RefreshGatherPanel(open)
  local guide = ns.GATHER[open.id]
  local rank, max = open.rank, open.max
  state.prof, state.rank = open.id, rank
  for _, w in ipairs({ diffDot, leftPill, craftBtn, addList, status, skipBack, skipNext, source }) do w:Hide() end
  profIcon:SetTexture(guide.icon or 134400); profIcon:Show()
  profText:SetText(open.name or guide.name)
  local RANKS = { [75] = "Apprentice", [150] = "Journeyman", [225] = "Expert", [300] = "Artisan" }
  local index = ns.StepIndex(guide, rank)
  profSub:SetText((RANKS[max] or "") .. (index and ("  ·  " .. T("stepOf", index, #guide.steps)) or "")); profSub:Show()
  bigRank:SetText(rank); bigRank:Show()
  bigOf:SetText("/ " .. max); bigOf:Show()
  bar:SetValue(rank); bar:Show()
  local rate = ns.PerHour and ns.PerHour(open.id)
  etaRank:SetText(rank >= 300 and ("|cff4dcc66" .. T("done") .. "|r") or ("|cffffffff" .. T("toRank", math.min(300, max)) .. "|r  ·  " .. math.max(0, math.min(300, max) - rank) .. " skill"))
  etaAll:SetText(rate and T("perHour", rate) or "")
  etaRank:Show(); etaAll:Show()
  local y = -93 - 30

  -- a rank to learn, with the map button
  local nextRank = ns.NextRank(open.id, rank, max)
  if nextRank and rank >= nextRank.need then
    local names = { [75] = "Journeyman", [150] = "Expert", [225] = "Artisan" }
    warn:SetText(T("learnRank", names[nextRank.at] or "") .. ": " .. (nextRank[ns.Faction()] or ""))
    warn:ClearAllPoints(); warn:SetPoint("TOPLEFT", 24, y - 14); warn:SetPoint("RIGHT", P, "RIGHT", -40, 0)
    warn:Show()
    local h = warn:GetStringHeight() + 14
    warnBg:ClearAllPoints(); warnBg:SetPoint("TOPLEFT", 14, y - 7); warnBg:SetPoint("RIGHT", P, "RIGHT", -14, 0)
    warnBg:SetHeight(h); warnBg:Show()
    warnPin:ClearAllPoints(); warnPin:SetPoint("RIGHT", warnBg, "RIGHT", -8, 0); warnPin:Show()
    y = y - 7 - h - 2
  else
    warn:Hide(); warnPin:Hide(); warnBg:Hide()
  end

  local step = index and guide.steps[index]
  if not step then
    for _, w in ipairs({ card, stepHead, recipeName, recipeCount, note, nextHead, nextLine }) do w:Hide() end
    recipeIcon:Hide()
    P:SetHeight(-y + 32)
    return
  end
  y = y - 8
  local cardTop = y
  y = y - 12
  stepHead:ClearAllPoints(); stepHead:SetPoint("TOPLEFT", 26, y)
  stepHead:SetText(string.upper(step[1] .. " - " .. step[2] .. "  ·  " .. T("stepOf", index, #guide.steps))); stepHead:Show()
  y = y - 20
  recipeIcon:ClearAllPoints(); recipeIcon:SetPoint("TOPLEFT", 26, y)
  local first = step.what and string.match(step.what, "^([^,(]+)")
  first = first and string.gsub(first, "%s+$", "")
  local icon = first and ns.ItemIcon(first)
  recipeIcon:SetTexture((icon and icon ~= 134400) and icon or guide.icon or 134400); recipeIcon:Show()
  recipeName:ClearAllPoints(); recipeName:SetPoint("TOPLEFT", recipeIcon, "TOPRIGHT", 10, -1)
  recipeName:SetPoint("RIGHT", P, "RIGHT", -26, 0)
  recipeName:SetText(step.what or ""); recipeName:Show()
  recipeCount:ClearAllPoints(); recipeCount:SetPoint("BOTTOMLEFT", recipeIcon, "BOTTOMRIGHT", 10, 2)
  recipeCount:SetPoint("RIGHT", P, "RIGHT", -26, 0)
  recipeCount:SetWordWrap(false)
  recipeCount:SetText(step[ns.Faction()] or step.h or ""); recipeCount:Show()
  y = y - 46
  if step.note then
    note:ClearAllPoints(); note:SetPoint("TOPLEFT", 26, y); note:SetText(step.note); note:Show()
    y = y - note:GetStringHeight() - 4
  else
    note:Hide()
  end
  -- smelting: the best smelt you can do now (orange first, then yellow, then green) with the ore in your bags
  local smelt = ns.BestSmelt and ns.BestSmelt()
  state.smelt = nil
  if smelt then
    local r = matRows[1]
    r.itemID = smelt.out
    r.icon:SetTexture(smelt.icon or 134400)
    local c = DIFF_COLOR[smelt.diff] or DIFF_COLOR[3]
    r.name:SetText(("|cff%02x%02x%02x%s|r"):format(math.floor(c[1] * 255), math.floor(c[2] * 255), math.floor(c[3] * 255), smelt.name))
    r.value:SetText(smelt.can > 0 and ("|cff5cd67c" .. smelt.can .. "|r") or "|cffe8574a0|r")
    r.fillBar:SetWidth(1); r.track:Hide(); r.fillBar:Hide()
    r:ClearAllPoints(); r:SetPoint("TOPLEFT", 26, y - 4); r:Show()
    y = y - 30
    craftBtn:ClearAllPoints(); craftBtn:SetPoint("TOPLEFT", 26, y)
    craftBtn:SetWidth(P:GetWidth() - 52)
    if smelt.can > 0 then
      state.smelt = { id = smelt.id, count = smelt.can }
      craftBtn:SetText(((ns.db.lang == "da") and "Smelt %d" or "Smelt %d"):format(smelt.can))
      craftBtn.tip = smelt.name
      craftBtn:Enable()
    else
      craftBtn:SetText((ns.db.lang == "da") and "Ingen malm til at smelte" or "No ore to smelt")
      craftBtn.tip = nil
      craftBtn:Disable()
    end
    craftBtn:Show()
    y = y - 36
  end
  y = y - 10
  card:ClearAllPoints(); card:SetPoint("TOPLEFT", 14, cardTop); card:SetPoint("RIGHT", P, "RIGHT", -14, 0)
  card:SetHeight(cardTop - y); card:Show()

  local after = guide.steps[index + 1]
  if ns.db.showNext and after then
    nextHead:ClearAllPoints(); nextHead:SetPoint("TOPLEFT", 14, y - 12)
    nextHead:SetText((ns.db.lang == "da") and "NÆSTE" or "NEXT"); nextHead:Show()
    nextLine:ClearAllPoints(); nextLine:SetPoint("LEFT", nextHead, "RIGHT", 10, 0)
    nextLine:SetText(after[1] .. " - " .. after[2] .. "   " .. (after.what or ""))
    nextLine:Show()
    y = y - 22
  else
    nextLine:Hide(); nextHead:Hide()
  end
  P:SetHeight(-y + 22)
end

-- the best smelt in the open Mining window: learned, gives skill (orange 0, yellow 1, green 2), most points
-- first, and how many your ore makes now
function ns.BestSmelt()
  local ui = C_TradeSkillUI
  if not (ui and ui.GetAllRecipeIDs and ui.GetRecipeInfo) then return nil end
  local Plain = ns.Plain
  local okI, ids = pcall(ui.GetAllRecipeIDs)
  if not okI or type(ids) ~= "table" then return nil end
  local best
  for _, id in ipairs(ids) do
    local ok, info = pcall(ui.GetRecipeInfo, id)
    if ok and type(info) == "table" and Plain(info.learned) then
      local diff = Plain(info.relativeDifficulty)
      if type(diff) == "number" and diff <= 2 then
        -- how many: the game's number, else counted from the ore in your bags
        local can = tonumber(Plain(info.numAvailable)) or 0
        local out
        local okS, sch = pcall(ui.GetRecipeSchematic, id, false)
        if okS and type(sch) == "table" then
          out = Plain(sch.outputItemID)
          if can == 0 then
            local n = math.huge
            for _, slot in ipairs(sch.reagentSlotSchematics or {}) do
              local first = slot.reagents and slot.reagents[1]
              local item, need = first and Plain(first.itemID), Plain(slot.quantityRequired)
              if item and need and need > 0 then n = math.min(n, math.floor((ns.BagCount and ns.BagCount(item) or 0) / need)) end
            end
            can = n == math.huge and 0 or n
          end
        end
        local cand = { id = id, name = Plain(info.name) or "?", icon = Plain(info.icon), diff = diff, can = can, out = out }
        -- something you can smelt beats something you can't; then the better colour
        if not best or (can > 0 and best.can == 0) or ((can > 0) == (best.can > 0) and diff < best.diff) then best = cand end
      end
    end
  end
  return best
end

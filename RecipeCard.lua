-- CraftETA: a card inside the profession window, under the recipe you picked:
-- your guide (is this the step's craft, and how many more), skill-ups (the colour, the chance and
-- where the colours change) and materials (how many you can make, what it costs, what it sells for).
local _, ns = ...
local T, Plain = ns.T, ns.Plain

local PAD, W_BAR, BAR_H = 10, 0, 8
local card, form

local COLORS = {
  [0] = { 1, 0.5, 0.25 },     -- orange: always
  [1] = { 1, 1, 0.25 },       -- yellow: sometimes
  [2] = { 0.25, 0.75, 0.25 }, -- green: rarely
  [3] = { 0.5, 0.5, 0.5 },    -- grey: never
}

local function Section(parent, y, text)
  local fs = ns.Font(parent, true, 9, 0.55, 0.58, 0.64)
  fs:SetPoint("TOPLEFT", PAD, y)
  fs:SetText(text)
  return fs
end

local function Build(parent)
  local f = CreateFrame("Frame", nil, parent)
  f:SetPoint("BOTTOMLEFT", 8, 30)    -- above the window's Track Recipe box
  f:SetPoint("BOTTOMRIGHT", -8, 30)
  f:SetHeight(150)
  f:SetFrameLevel(parent:GetFrameLevel() + 5)
  local bg = f:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetColorTexture(0.04, 0.045, 0.06, 0.82)
  local stripe = f:CreateTexture(nil, "BORDER")
  stripe:SetPoint("TOPLEFT"); stripe:SetPoint("BOTTOMLEFT")
  stripe:SetWidth(2)
  stripe:SetColorTexture(1, 0.82, 0.3, 0.9)

  f.logo = f:CreateTexture(nil, "ARTWORK")
  f.logo:SetTexture(ns.TEX .. "Logo")
  f.logo:SetSize(16, 16)
  f.logo:SetPoint("TOPLEFT", PAD, -7)
  f.title = ns.Font(f, true, 11)
  f.title:SetPoint("LEFT", f.logo, "RIGHT", 6, 0)
  f.title:SetText("|cffffffffCraft|r|cffffd24aETA|r")
  f.rule = f:CreateTexture(nil, "ARTWORK")
  f.rule:SetHeight(1)
  f.rule:SetPoint("LEFT", f.title, "RIGHT", 8, 0)
  f.rule:SetPoint("RIGHT", f, "RIGHT", -PAD, 0)
  f.rule:SetColorTexture(1, 0.82, 0.3, 0.35)

  f.guideHead = Section(f, -30, "")
  f.guide = ns.Font(f, false, 11, 0.45, 0.85, 0.5)
  f.guide:SetPoint("TOPLEFT", PAD, -42)
  f.guide:SetPoint("RIGHT", f, "RIGHT", -PAD - 70, 0)
  f.guide:SetJustifyH("LEFT"); f.guide:SetWordWrap(false)
  f.show = ns.Button(f, "", 62, 18)
  f.show:SetPoint("TOPRIGHT", -PAD, -38)

  f.upHead = Section(f, -62, "")
  f.up = ns.Font(f, false, 11)
  f.up:SetPoint("TOPLEFT", PAD, -74)
  f.up:SetPoint("RIGHT", f, "RIGHT", -PAD, 0)
  f.up:SetJustifyH("LEFT")
  -- the bar: where the recipe turns orange, yellow, green and grey, and your skill on it
  f.bar = CreateFrame("Frame", nil, f)
  f.bar:SetPoint("TOPLEFT", PAD, -90)
  f.bar:SetPoint("RIGHT", f, "RIGHT", -PAD, 0)
  f.bar:SetHeight(BAR_H)
  f.segs, f.labs = {}, {}
  for i = 1, 4 do
    local s = f.bar:CreateTexture(nil, "ARTWORK")
    s:SetHeight(BAR_H)
    f.segs[i] = s
    local l = ns.Font(f.bar, false, 8, 0.6, 0.62, 0.68)
    f.labs[i] = l
  end
  f.mark = f.bar:CreateTexture(nil, "OVERLAY")
  f.mark:SetSize(2, BAR_H + 6)
  f.mark:SetColorTexture(1, 1, 1, 1)

  f.matHead = Section(f, -112, "")
  f.mat = ns.Font(f, false, 10, 0.85, 0.86, 0.9)
  f.mat:SetPoint("TOPLEFT", PAD, -124)
  f.mat:SetPoint("RIGHT", f, "RIGHT", -PAD, 0)
  f.mat:SetJustifyH("LEFT"); f.mat:SetWordWrap(true)
  return f
end

-- the recipe the window shows
local function Selected()
  if form and form.GetRecipeInfo then
    local ok, info = pcall(form.GetRecipeInfo, form)
    if ok and type(info) == "table" then return info end
  end
  if form and type(form.currentRecipeInfo) == "table" then return form.currentRecipeInfo end
  return nil
end

local function Chance(r, skill)
  -- yellow and green: (grey - skill) / (grey - yellow)
  local yellow, grey = r[2], r[4]
  if not yellow or not grey or grey <= yellow then return nil end
  return math.max(0, math.min(1, (grey - skill) / (grey - yellow)))
end

local function ColorAt(r, skill)
  if skill >= r[4] then return 3 end
  if skill >= r[3] then return 2 end
  if skill >= r[2] then return 1 end
  return 0
end

local function DrawBar(f, r, skill)
  local w = f.bar:GetWidth()
  if not w or w < 10 then w = 260 end
  local lo = (r[1] and r[1] > 0) and r[1] or math.max(1, r[2] - 10)
  local hi = r[4] + math.max(5, math.floor((r[4] - lo) * 0.15))
  local function X(v) return (math.max(lo, math.min(hi, v)) - lo) / math.max(1, hi - lo) * w end
  local edges = { lo, r[2], r[3], r[4], hi }
  for i = 1, 4 do
    local s, l = f.segs[i], f.labs[i]
    local x1, x2 = X(edges[i]), X(edges[i + 1])
    s:ClearAllPoints()
    s:SetPoint("TOPLEFT", f.bar, "TOPLEFT", x1, 0)
    s:SetWidth(math.max(1, x2 - x1))
    local c = COLORS[i - 1]
    s:SetColorTexture(c[1], c[2], c[3], 0.9)
    s:SetShown(x2 - x1 >= 1)
    l:ClearAllPoints()
    l:SetPoint("TOPLEFT", f.bar, "TOPLEFT", x1, -BAR_H - 2)
    l:SetText(edges[i])
    l:SetShown(x2 - x1 >= 1 and (i == 1 or edges[i] ~= edges[i - 1]))
  end
  f.mark:ClearAllPoints()
  f.mark:SetPoint("TOPLEFT", f.bar, "TOPLEFT", math.max(0, X(skill) - 1), 3)
  f.bar:Show()
end

local function Update()
  if not card then return end
  local info = Selected()
  local open = ns.OpenProfession and ns.OpenProfession()
  if not info or not open or not ns.db or ns.db.recipeCard == false then card:Hide(); return end
  local id = Plain(info.recipeID)
  local name = Plain(info.name)
  if type(id) ~= "number" or type(name) ~= "string" then card:Hide(); return end
  local skill = open.rank or 0

  -- your guide
  card.guideHead:SetText(string.upper(T("rcGuide")))
  local st = ns.panelState or {}
  card.show:Hide()
  if st.prof == open.id and st.recipe and st.step then
    if st.recipe == name then
      card.guide:SetText(T("rcStepNow", st.left or 0, st.step[2]))
      card.guide:SetTextColor(0.45, 0.85, 0.5)
    else
      card.guide:SetText(T("rcGuideNow", st.recipe, st.step[1], st.step[2]))
      card.guide:SetTextColor(0.85, 0.86, 0.9)
      local target = ns.Recipe(st.recipe)
      if target and target.id and C_TradeSkillUI and C_TradeSkillUI.OpenRecipe then
        card.show:SetText(T("rcShow"))
        card.show:SetScript("OnClick", function() pcall(C_TradeSkillUI.OpenRecipe, target.id) end)
        card.show:Show()
      end
    end
  else
    card.guide:SetText(skill >= 300 and T("done") or T("rcNoGuide"))
    card.guide:SetTextColor(0.6, 0.62, 0.68)
  end

  -- skill-ups
  card.upHead:SetText(string.upper(T("rcUps")))
  local r = ns.SKILLUP and ns.SKILLUP[id]
  local color = Plain(info.relativeDifficulty)
  if type(color) ~= "number" and r then color = ColorAt(r, skill) end
  local learned = Plain(info.learned)
  local text, c
  if learned == false then
    text, c = T("rcNotLearned"), { 0.6, 0.62, 0.68 }
  elseif type(color) == "number" and COLORS[color] then
    c = COLORS[color]
    text = T("rcColor" .. color)
    local chance = r and (color == 1 or color == 2) and Chance(r, skill)
    if chance then text = text .. ("  (%d%%)"):format(math.floor(chance * 100 + 0.5)) end
  else
    text, c = T("rcUnknown"), { 0.6, 0.62, 0.68 }
  end
  card.up:SetText(text)
  card.up:SetTextColor(c[1], c[2], c[3])
  if r then DrawBar(card, r, skill) else card.bar:Hide() end

  -- materials
  card.matHead:SetText(string.upper(T("rcMats")))
  local parts = {}
  local can = tonumber(Plain(info.numAvailable)) or 0
  parts[#parts + 1] = can > 0 and ("|cff73d973" .. T("rcCanMake", can) .. "|r") or ("|cff8c8f96" .. T("rcCantMake") .. "|r")
  local me = ns.Me and ns.Me()
  local entry = me and me.book and me.book[open.id] and me.book[open.id][id]
  if entry then
    local cost, missing = ns.CraftCost(entry)
    local yield = entry.y or 1
    local sell = entry.o and ns.PriceID(entry.o)
    local money = {}
    if cost > 0 then money[#money + 1] = T("rcCost", (missing and "~" or "") .. ns.Money(cost)) end
    if sell then
      money[#money + 1] = T("rcSells", ns.Money(sell * yield))
      if cost > 0 then
        local profit = sell * yield - cost
        money[#money + 1] = (profit >= 0 and "|cff73d973" or "|cffe6594d") .. T("rcProfit", (profit < 0 and "-" or "") .. ns.Money(math.abs(profit))) .. "|r"
      end
    end
    if #money > 0 then parts[#parts + 1] = table.concat(money, "  ·  ") end
  end
  card.mat:SetText(table.concat(parts, "\n"))
  card:SetHeight(r and 160 or 140)
  if r then
    card.matHead:SetPoint("TOPLEFT", PAD, -116); card.mat:SetPoint("TOPLEFT", PAD, -128)
  else
    card.matHead:SetPoint("TOPLEFT", PAD, -94); card.mat:SetPoint("TOPLEFT", PAD, -106)
  end
  card:Show()
end
ns.UpdateRecipeCard = Update

local function Soon()
  Update()
  C_Timer.After(0.15, Update)
end

local function MastercraftOn()
  local loaded = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
  local ok, on = pcall(loaded, "Mastercraft")
  return ok and on and true or false
end

local function Setup()
  if card then return end
  -- Mastercraft puts its own card in the same place: then ours stays away (say so once)
  if MastercraftOn() then
    if ns.db and not ns.db.toldMC then ns.db.toldMC = true; ns.Print(T("rcMastercraft")) end
    return
  end
  local page = ProfessionsFrame and ProfessionsFrame.CraftingPage
  if not (page and page.SchematicForm) then return end
  form = page.SchematicForm
  card = Build(form)
  card:Hide()
  if form.Init then hooksecurefunc(form, "Init", Soon) end
  form:HookScript("OnShow", Soon)
  form:HookScript("OnHide", function() card:Hide() end)
end

ns.Register("ADDON_LOADED")
ns.On("ADDON_LOADED", function(name) if name == "Blizzard_Professions" then Setup() end end)
ns.Register("TRADE_SKILL_SHOW")
ns.On("TRADE_SKILL_SHOW", function() Setup(); C_Timer.After(0.2, Update) end)
ns.Register("BAG_UPDATE_DELAYED")
ns.On("BAG_UPDATE_DELAYED", function() if card and card:IsShown() then C_Timer.After(0.3, Update) end end)

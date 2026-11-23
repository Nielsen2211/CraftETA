-- CraftETA: a card inside the profession window, under the recipe you picked:
-- your guide (is this the step's craft, and how many more), skill-ups (the colour, the chance and
-- where the colours change) and materials (how many you can make, what it costs, what it sells for).
local _, ns = ...
local T, Plain = ns.T, ns.Plain
local function L(en, da) return (ns.db and ns.db.lang == "da") and da or en end

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
  f.rule:SetPoint("RIGHT", f, "RIGHT", -PAD - 96, 0)
  -- the recipe's materials on the shopping list (shift: 5)
  f.list = ns.Primary(ns.Button(f, "", 88, 18), 10)
  f.list:SetPoint("TOPRIGHT", -PAD, -6)
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

-- Other addons (AuctionMaster, aux, Auctionator ...) put their own lines and buttons on the same
-- recipe window. We remember what Blizzard built, and treat every frame that turns up later as theirs.
local known, anchored
local function Kids(parent, out)
  if not parent or not parent.GetChildren then return out end
  for _, c in ipairs({ parent:GetChildren() }) do out[#out + 1] = c end
  return out
end
local function Containers()
  local page = ProfessionsFrame and ProfessionsFrame.CraftingPage
  local out = Kids(form, {})
  if page and page ~= form then Kids(page, out) end
  return out
end
local function Snapshot()
  known = {}
  for _, c in ipairs(Containers()) do known[c] = true end
  known[card] = true
end

-- Keep the card clear of those frames: lift it above them, and if there is no room, hang it
-- beside the window instead. Runs after every update, so it also follows addons that load late.
local function KeepClear()
  if not card or not card:IsShown() or not known or not form then return end
  local base = 30
  local top = card:GetTop()
  local bottom = card:GetBottom()
  local fb = form:GetBottom()
  if not (top and bottom and fb) then return end
  local want = base
  local h = card:GetHeight()
  local left, right = card:GetLeft(), card:GetRight()
  for _, c in ipairs(Containers()) do
    if not known[c] and c ~= card and c:IsShown() and c:GetNumPoints() > 0 then
      local ok, ct, cb, cl, cr = pcall(function() return c:GetTop(), c:GetBottom(), c:GetLeft(), c:GetRight() end)
      if ok and ct and cb and cl and cr and cr > left and cl < right then
        local cTop = ct - fb          -- how far up from the form's bottom their frame reaches
        local cBot = cb - fb
        -- only frames that sit in the strip where the card lives (the bottom of the form)
        if cBot < base + h and cTop > base then want = math.max(want, cTop + 4) end
      end
    end
  end
  local formH = form:GetHeight() or 0
  card:ClearAllPoints()
  if want + h > formH * 0.8 and ProfessionsFrame then
    -- no room inside: dock to the right of the window
    card:SetPoint("TOPLEFT", ProfessionsFrame, "TOPRIGHT", 4, -60)
    card:SetWidth(math.max(300, form:GetWidth() - 16))
    anchored = "side"
  else
    card:SetPoint("BOTTOMLEFT", form, "BOTTOMLEFT", 8, want)
    card:SetPoint("BOTTOMRIGHT", form, "BOTTOMRIGHT", -8, want)
    anchored = "in"
  end
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
  local color = Plain(info.relativeDifficulty)
  local chance, r
  chance, color, r = ns.SkillUpChance(id, skill, type(color) == "number" and color or nil)
  local learned = Plain(info.learned)
  local me0 = ns.Me and ns.Me()
  local bookEntry = me0 and me0.book and me0.book[open.id] and me0.book[open.id][id]
  local text, c
  if learned == false then
    text, c = T("rcNotLearned"), { 0.6, 0.62, 0.68 }
  elseif type(color) == "number" and COLORS[color] then
    c = COLORS[color]
    text = T("rcColor" .. color)
    if chance and (color == 1 or color == 2) then text = text .. ("  (%d%%)"):format(math.floor(chance * 100 + 0.5)) end
    -- what a point costs in materials, or a green + when the craft earns
    if bookEntry and chance and chance > 0 then
      local _, missing, _, profit = ns.CraftNet(bookEntry)
      local per = ns.CostPerPoint(bookEntry, chance)
      if profit and profit >= 0 then
        text = text .. "  |cff73d973+ " .. L("earns while you level", "tjener mens du lever") .. "|r"
      elseif per then
        text = text .. "  |cffc0c2c8" .. L("%s per skill-up", "%s pr. skill-up"):format((missing and "~" or "") .. ns.Money(per)) .. "|r"
      end
    end
  else
    text, c = T("rcUnknown"), { 0.6, 0.62, 0.68 }
  end
  card.up:SetText(text)
  card.up:SetTextColor(c[1], c[2], c[3])
  if r and r[2] and r[4] then DrawBar(card, r, skill) else card.bar:Hide(); r = nil end

  -- materials
  card.matHead:SetText(string.upper(T("rcMats")))
  local parts = {}
  local lines = 0
  local can = tonumber(Plain(info.numAvailable)) or 0
  if can == 0 and ns.CanMake then can = ns.CanMake(name) end
  parts[#parts + 1] = can > 0 and ("|cff73d973" .. T("rcCanMake", can) .. "|r") or ("|cff8c8f96" .. T("rcCantMake") .. "|r")
  local me = ns.Me and ns.Me()
  local entry = me and me.book and me.book[open.id] and me.book[open.id][id]
  if entry then
    local cost, missing = ns.CraftCost(entry)
    local yield = entry.y or 1
    local sell = entry.o and ((ns.SellUnit and ns.SellUnit(entry.o)) or ns.PriceID(entry.o))
    local money = {}
    if cost > 0 then money[#money + 1] = T("rcCost", (missing and "~" or "") .. ns.Money(cost)) end
    if sell then
      money[#money + 1] = T("rcSells", ns.Money(sell * yield))
      if cost > 0 then
        local profit = math.floor(sell * yield * 0.95) - cost   -- the auction house keeps 5%
        money[#money + 1] = (profit >= 0 and "|cff73d973" or "|cffe6594d") .. T("rcProfit", (profit < 0 and "-" or "") .. ns.Money(math.abs(profit))) .. "|r"
      end
    end
    if #money > 0 then parts[#parts + 1] = table.concat(money, "  ·  ") end

    -- what you are short of for one craft: have / need
    local mats = entry.m or {}
    local short = {}
    for i = 1, #mats, 2 do
      local have, need = ns.Have(mats[i]), mats[i + 1]
      if have < need then
        local icon = ns.ItemIcon(mats[i])
        short[#short + 1] = ("|T%s:12:12:0:0:64:64:5:59:5:59|t %s  |cffe6594d%d|r|cff8c8f96/%d|r"):format(icon or 134400, mats[i], have, need)
      end
    end
    if #short > 0 then
      parts[#parts + 1] = "|cffffd24a" .. L("You're short on materials", "Du mangler materialer") .. "|r\n" .. table.concat(short, "\n")
      lines = lines + 1 + #short
    end

    -- the cheapest way: a material you (or an alt) can make for less than it costs to buy
    local best
    for i = 1, #mats, 2 do
      local id = ns.ItemID(mats[i])
      local buy = ns.MatPrice(mats[i])
      for _, m in ipairs(id and ns.Makers and ns.Makers(id) or {}) do
        local own = ns.CraftCost(m.recipe) / (m.recipe.y or 1)
        if buy and own > 0 and own < buy then
          local save = (buy - own) * mats[i + 1]
          if not best or save > best.save then best = { mat = mats[i], save = save, char = m.char } end
        end
      end
    end
    if best then
      parts[#parts + 1] = "|cff73d973" .. L("Cheapest way: make your own %s (%s) and save %s", "Billigste vej: lav selv %s (%s) og spar %s"):format(best.mat, best.char, ns.Money(best.save)) .. "|r"
      lines = lines + 1
    end

    card.list:SetText(L("Shopping list", "Indkøbsliste"))
    card.list:SetScript("OnClick", function()
      local n = IsShiftKeyDown() and 5 or 1
      local want, order = {}, {}
      for i = 1, #mats, 2 do
        if not want[mats[i]] then order[#order + 1] = mats[i] end
        want[mats[i]] = (want[mats[i]] or 0) + mats[i + 1] * n
      end
      if #order > 0 and ns.AddToList then
        ns.AddToList(want, order)
        ns.Print(L("Materials for %d %s on the shopping list.", "Mats til %d %s er på indkøbslisten."):format(n, name))
      end
    end)
    card.list.tip = L("The materials for one on the shopping list (shift: 5).", "Mats til én på indkøbslisten (shift: 5).")
    card.list:SetShown(#mats > 0)
  else
    card.list:Hide()
  end
  card.mat:SetText(table.concat(parts, "\n"))
  card:SetHeight((r and 160 or 140) + lines * 14)
  if r then
    card.matHead:SetPoint("TOPLEFT", PAD, -116); card.mat:SetPoint("TOPLEFT", PAD, -128)
  else
    card.matHead:SetPoint("TOPLEFT", PAD, -94); card.mat:SetPoint("TOPLEFT", PAD, -106)
  end
  card:Show()
  KeepClear()
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
  Snapshot()
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

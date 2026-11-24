-- CraftETA: the profit scanner. Everything your characters can craft, what it sells for on the auction
-- house right now, what its materials cost, and what is left after the auction house's 5%.
local _, ns = ...
local function L(en, da) return (ns.db and ns.db.lang == "da") and da or en end

local H, X, CW = ns.Hub, ns.HUB_X, ns.HUB_CW
local AH_CUT = 0.95
local GOLD = { 1, 0.82, 0.29 }

local page = CreateFrame("Frame", nil, H)
page:SetPoint("TOPLEFT", X, -20)
page:SetPoint("BOTTOMRIGHT", -18, 16)
page:Hide()
ns.HubCustom.profit = page

local function Fill(parent, r, g, b, a, layer)
  local t = parent:CreateTexture(nil, layer or "BACKGROUND")
  t:SetColorTexture(r, g, b, a or 1)
  return t
end
local function Card(parent, edge)
  local f = CreateFrame("Frame", nil, parent)
  Fill(f, 0.086, 0.094, 0.122):SetAllPoints()
  local e = edge or { 0.2, 0.21, 0.25 }
  for _, p in ipairs({ { "TOPLEFT", "TOPRIGHT", true }, { "BOTTOMLEFT", "BOTTOMRIGHT", true }, { "TOPLEFT", "BOTTOMLEFT" }, { "TOPRIGHT", "BOTTOMRIGHT" } }) do
    local t = f:CreateTexture(nil, "BORDER")
    t:SetPoint(p[1]); t:SetPoint(p[2])
    if p[3] then t:SetHeight(1) else t:SetWidth(1) end
    t:SetColorTexture(e[1], e[2], e[3], 1)
  end
  return f
end
local function Icon(parent, size)
  local t = parent:CreateTexture(nil, "ARTWORK")
  t:SetSize(size, size)
  t:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  return t
end
local function Signed(v)
  if math.abs(v) < 0.5 then return "0c" end
  return (v >= 0 and "+" or "-") .. ns.Money(math.abs(v))
end

-- the state of the page
local filterProf, sortBy, onlyNow, scroll = nil, "profit", false, 0

---------------------------------------------------------------------------
-- The best one now
---------------------------------------------------------------------------
local top = Card(page)
top:SetPoint("TOPLEFT"); top:SetPoint("RIGHT"); top:SetHeight(84)
local tIcon = Icon(top, 48); tIcon:SetPoint("LEFT", 16, 0)
local tHead = ns.Font(top, true, 9, 0.62, 0.55, 0.36); tHead:SetPoint("TOPLEFT", tIcon, "TOPRIGHT", 12, 0)
local tName = ns.Font(top, true, 16, 0.9, 0.91, 0.94); tName:SetPoint("TOPLEFT", tHead, "BOTTOMLEFT", 0, -3)
local tSub = ns.Font(top, false, 10, 0.6, 0.62, 0.67); tSub:SetPoint("TOPLEFT", tName, "BOTTOMLEFT", 0, -3)
local tGain = ns.Font(top, true, 20, 0.35, 0.9, 0.4); tGain:SetPoint("TOPRIGHT", -16, -18); tGain:SetJustifyH("RIGHT")
local tGainSub = ns.Font(top, false, 10, 0.6, 0.62, 0.67); tGainSub:SetPoint("TOPRIGHT", tGain, "BOTTOMRIGHT", 0, -3); tGainSub:SetJustifyH("RIGHT")
tName:SetPoint("RIGHT", tGain, "LEFT", -12, 0); tName:SetWordWrap(false)

---------------------------------------------------------------------------
-- Filters: profession, sort, only what you can make now
---------------------------------------------------------------------------
local profBtns = {}
for i = 1, 8 do
  local b = ns.Button(page, "", 90, 20)
  b.grow = true
  b:SetScript("OnClick", function(self) filterProf = self.prof; scroll = 0; page:Refresh() end)
  profBtns[i] = b
end
local sortBtns = {}
for i, key in ipairs({ "profit", "margin" }) do
  local b = ns.Button(page, "", 70, 20)
  b:SetPoint("TOPLEFT", 0, -122)
  b:SetPoint("TOPLEFT", (i - 1) * 74, -122)
  b.key = key
  b:SetScript("OnClick", function() sortBy = key; scroll = 0; page:Refresh() end)
  sortBtns[i] = b
end
local nowSwitch = ns.Switch(page, function() onlyNow = not onlyNow; scroll = 0; page:Refresh() end)
nowSwitch:SetPoint("TOPRIGHT", 0, -124)
local nowLabel = ns.Font(page, false, 10, 0.6, 0.62, 0.67); nowLabel:SetPoint("RIGHT", nowSwitch, "LEFT", -6, 0)

---------------------------------------------------------------------------
-- The list
---------------------------------------------------------------------------
local list = Card(page)
list:SetPoint("TOPLEFT", 0, -150); list:SetPoint("BOTTOMRIGHT", 0, 30)
local ROW_H = 40
local rows = {}
local function Row(i)
  if rows[i] then return rows[i] end
  local r = CreateFrame("Button", nil, list)
  r:SetHeight(ROW_H - 4)
  r:SetPoint("TOPLEFT", 10, -8 - (i - 1) * ROW_H); r:SetPoint("RIGHT", list, "RIGHT", -10, 0)
  r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  Fill(r, 1, 1, 1, 0.025):SetAllPoints()
  local hl = r:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints(); hl:SetColorTexture(1, 1, 1, 0.05)
  r.icon = Icon(r, 28); r.icon:SetPoint("LEFT", 6, 0)
  r.gain = ns.Font(r, true, 12, 0.35, 0.9, 0.4); r.gain:SetPoint("TOPRIGHT", -8, -4); r.gain:SetJustifyH("RIGHT")
  r.money = ns.Font(r, false, 9, 0.6, 0.62, 0.67); r.money:SetPoint("BOTTOMRIGHT", -8, 5); r.money:SetJustifyH("RIGHT")
  r.name = ns.Font(r, true, 11, 0.9, 0.91, 0.94); r.name:SetPoint("TOPLEFT", r.icon, "TOPRIGHT", 9, 1)
  r.name:SetPoint("RIGHT", r.gain, "LEFT", -10, 0); r.name:SetWordWrap(false)
  r.sub = ns.Font(r, false, 9, 0.5, 0.52, 0.57); r.sub:SetPoint("BOTTOMLEFT", r.icon, "BOTTOMRIGHT", 9, -1)
  r.sub:SetPoint("RIGHT", r.money, "LEFT", -10, 0); r.sub:SetWordWrap(false)
  r:SetScript("OnLeave", function() GameTooltip:Hide() end)
  rows[i] = r
  return r
end
local empty = ns.Font(list, false, 11, 0.6, 0.62, 0.67)
empty:SetPoint("TOPLEFT", 16, -16); empty:SetPoint("RIGHT", list, "RIGHT", -16, 0)
empty:SetWordWrap(true); empty:SetJustifyH("LEFT")
list:EnableMouseWheel(true)
list:SetScript("OnMouseWheel", function(_, d) scroll = math.max(0, scroll - d * 3); page:Refresh() end)

local foot = ns.Font(page, false, 9, 0.45, 0.47, 0.52); foot:SetPoint("BOTTOMLEFT", 2, 8)
local more = ns.Font(page, false, 9, 0.45, 0.47, 0.52); more:SetPoint("BOTTOMRIGHT", -2, 8); more:SetJustifyH("RIGHT")

---------------------------------------------------------------------------
-- The numbers
---------------------------------------------------------------------------
local function CanMakeNow(r)
  local n
  local mats = r.m or {}
  for i = 1, #mats, 2 do
    local can = math.floor(ns.Have(mats[i]) / math.max(1, mats[i + 1]))
    n = n and math.min(n, can) or can
  end
  return n or 0
end

local function Entries()
  local out = {}
  for _, r in ipairs(ns.KnownRecipes()) do
    local sell, none = ns.SellUnit(r.o)
    local cost, missing = ns.CraftCost(r)
    if sell and cost > 0 and not missing then
      local y = r.y or 1
      local gain = sell * AH_CUT * y - cost
      out[#out + 1] = { r = r, sell = sell, cost = cost, gain = gain, margin = cost > 0 and gain / cost or 0,
        supply = ns.SupplyOf(r.o), now = CanMakeNow(r), y = y }
    elseif none and cost > 0 and not missing then
      out[#out + 1] = { r = r, cost = cost, none = true, gain = -math.huge, margin = -math.huge, supply = 0, now = CanMakeNow(r), y = r.y or 1 }
    end
  end
  return out
end

local function Tip(self, e)
  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
  local ok = e.r.o and pcall(GameTooltip.SetItemByID, GameTooltip, e.r.o)
  if not ok then GameTooltip:SetText(e.r.n, 1, 1, 1) end
  GameTooltip:AddLine(" ")
  GameTooltip:AddLine(("%s · %s"):format(e.r.char, ns.ProfName(e.r.prof)), 0.7, 0.72, 0.76)
  if e.none then
    GameTooltip:AddLine(L("Nobody sells it on the auction house: you set the price.", "Ingen sælger den på AH: du sætter prisen."), 1, 0.82, 0.3, true)
  else
    GameTooltip:AddDoubleLine(L("Sells for", "Sælger for") .. (e.y > 1 and (" (" .. e.y .. ")") or ""), ns.Money(e.sell * e.y), 0.85, 0.87, 0.9, 1, 1, 1)
    GameTooltip:AddDoubleLine(L("Auction house 5%", "AH tager 5%"), "-" .. ns.Money(e.sell * e.y * (1 - AH_CUT)), 0.85, 0.87, 0.9, 1, 1, 1)
  end
  GameTooltip:AddDoubleLine(L("Materials", "Materialer"), "-" .. ns.Money(e.cost), 0.85, 0.87, 0.9, 1, 1, 1)
  if not e.none then GameTooltip:AddDoubleLine(L("Profit", "Profit"), Signed(e.gain), 1, 0.82, 0.3, 1, 1, 1) end
  local mats = e.r.m or {}
  if #mats > 0 then GameTooltip:AddLine(" ") end
  for i = 1, #mats, 2 do
    local p = ns.MatPrice(mats[i])
    GameTooltip:AddDoubleLine(mats[i + 1] .. " x " .. mats[i] .. "  |cff8c8f96(" .. L("have", "har") .. " " .. ns.Have(mats[i]) .. ")|r",
      p and ns.Money(p * mats[i + 1]) or "?", 0.85, 0.87, 0.9, 1, 1, 1)
  end
  GameTooltip:AddLine(" ")
  GameTooltip:AddLine(L("Click: materials for 1 on the shopping list  ·  Shift: 5  ·  Right-click: search the AH",
    "Klik: mats til 1 på indkøbslisten  ·  Shift: 5  ·  Højreklik: søg på AH"), 0.55, 0.58, 0.64, true)
  GameTooltip:Show()
end

local function ToList(e, n)
  local mats, order = {}, {}
  local m = e.r.m or {}
  for i = 1, #m, 2 do
    if not mats[m[i]] then order[#order + 1] = m[i] end
    mats[m[i]] = (mats[m[i]] or 0) + m[i + 1] * n
  end
  if #order > 0 then
    ns.AddToList(mats, order)
    ns.Print(L("Materials for %d %s on the shopping list.", "Mats til %d %s er på indkøbslisten."):format(n, e.r.n))
  end
end

local function Ago(t)
  local m = math.floor((time() - t) / 60)
  if m < 1 then return L("just now", "lige nu") end
  if m < 60 then return L("%d min ago", "for %d min siden"):format(m) end
  return L("%d h ago", "for %d t siden"):format(math.floor(m / 60))
end

function page:Refresh()
  if not ns.db then return end
  local all = Entries()

  -- the professions there are, as buttons
  local profs, seen = {}, {}
  for _, e in ipairs(all) do
    if not seen[e.r.prof] then seen[e.r.prof] = true; profs[#profs + 1] = e.r.prof end
  end
  table.sort(profs, function(a, b) return ns.ProfName(a) < ns.ProfName(b) end)
  local tabs = { { nil, L("All", "Alle") } }
  for _, p in ipairs(profs) do tabs[#tabs + 1] = { p, ns.ProfName(p) } end
  local x = 0
  for i, b in ipairs(profBtns) do
    local t = tabs[i]
    if t then
      b.prof = t[1]
      b:SetWidth(90); b:SetText(t[2])
      local w = math.max(60, (b.label:GetStringWidth() or 0) + 20)
      b:SetWidth(w); b:ClearAllPoints(); b:SetPoint("TOPLEFT", x, -94)
      x = x + w + 4
      local on = filterProf == t[1]
      b.label:SetTextColor(on and 1 or 0.6, on and 0.82 or 0.62, on and 0.3 or 0.68)
      b:Show()
    else
      b:Hide()
    end
  end
  for _, b in ipairs(sortBtns) do
    b:SetText(b.key == "profit" and L("Profit", "Profit") or L("Margin", "Margin"))
    local on = sortBy == b.key
    b.label:SetTextColor(on and 1 or 0.6, on and 0.82 or 0.62, on and 0.3 or 0.68)
  end
  nowSwitch:SetOn(onlyNow)
  nowLabel:SetText(L("Only what I can make now", "Kun det jeg kan lave nu"))

  -- filter and sort
  local shown = {}
  for _, e in ipairs(all) do
    if (not filterProf or e.r.prof == filterProf) and (not onlyNow or e.now > 0) then shown[#shown + 1] = e end
  end
  table.sort(shown, function(a, b)
    local ka, kb = a[sortBy], b[sortBy]
    if ka ~= kb then return ka > kb end
    return a.r.n < b.r.n
  end)

  -- the best one
  local best
  for _, e in ipairs(shown) do if not e.none then best = e; break end end
  tHead:SetText(L("BEST PROFIT RIGHT NOW", "BEDSTE PROFIT LIGE NU"))
  if best then
    tIcon:SetTexture(best.r.i or 134400)
    tName:SetText(best.r.n)
    tSub:SetText(("%s · %s"):format(best.r.char, ns.ProfName(best.r.prof))
      .. (best.now > 0 and ("  ·  |cff73d973" .. L("you can make %d now", "du kan lave %d nu"):format(best.now) .. "|r") or ""))
    tGain:SetText(Signed(best.gain))
    tGain:SetTextColor(best.gain >= 0 and 0.35 or 1, best.gain >= 0 and 0.9 or 0.4, best.gain >= 0 and 0.4 or 0.35)
    tGainSub:SetText(L("per craft  ·  %d%% margin", "pr. craft  ·  %d%% margin"):format(math.floor(best.margin * 100 + 0.5)))
  else
    tIcon:SetTexture("Interface\\Icons\\INV_Misc_Coin_17")
    tName:SetText(L("No prices yet", "Ingen priser endnu"))
    tSub:SetText(L("Open your professions once, then press Scan AH at the auction house.", "Åbn dine professions én gang, og tryk Scan AH ved auktionshuset."))
    tGain:SetText(""); tGainSub:SetText("")
  end

  -- the rows
  local room = math.max(1, math.floor(((list:GetHeight() or 300) - 12) / ROW_H))
  scroll = math.min(scroll, math.max(0, #shown - room))
  for _, r in ipairs(rows) do r:Hide() end
  for i = 1, math.min(room, #shown - scroll) do
    local e, r = shown[scroll + i], Row(i)
    r.icon:SetTexture(e.r.i or 134400)
    r.name:SetText(e.r.n .. (e.y > 1 and ("  |cff8c8f96x" .. e.y .. "|r") or ""))
    local supply = e.supply and (e.supply == 0 and ("|cffffd24a" .. L("none on the AH", "ingen på AH") .. "|r")
      or L("%d on the AH", "%d på AH"):format(e.supply)) or L("not scanned", "ikke scannet")
    r.sub:SetText(("%s · %s  ·  %s"):format(e.r.char, ns.ProfName(e.r.prof), supply)
      .. (e.now > 0 and ("  ·  |cff73d973" .. L("%d now", "%d nu"):format(e.now) .. "|r") or ""))
    if e.none then
      r.gain:SetText(L("you set the price", "du sætter prisen")); r.gain:SetTextColor(1, 0.82, 0.3)
      r.money:SetText(L("materials %s", "mats %s"):format(ns.MoneyShort(e.cost)))
    else
      r.gain:SetText(Signed(e.gain))
      r.gain:SetTextColor(e.gain >= 0 and 0.35 or 1, e.gain >= 0 and 0.9 or 0.4, e.gain >= 0 and 0.4 or 0.35)
      r.money:SetText(L("sells %s  ·  mats %s  ·  %d%%", "sælger %s  ·  mats %s  ·  %d%%"):format(ns.MoneyShort(e.sell * e.y), ns.MoneyShort(e.cost), math.floor(e.margin * 100 + 0.5)))
    end
    r:SetScript("OnEnter", function(self) Tip(self, e) end)
    r:SetScript("OnClick", function(_, button)
      if button == "RightButton" then
        if ns.AHSearch then ns.AHSearch(e.r.o, e.r.n) end
      else
        ToList(e, IsShiftKeyDown() and 5 or 1)
      end
    end)
    r:Show()
  end
  empty:SetShown(#shown == 0)
  empty:SetText(#all == 0 and L("CraftETA knows your recipes once you have opened each profession window, and their prices once you press Scan AH at the auction house.",
      "CraftETA kender dine opskrifter, når du har åbnet hvert profession vindue, og deres priser, når du trykker Scan AH ved auktionshuset.")
    or L("Nothing here with these filters.", "Intet her med disse filtre."))
  local last = ns.db.lastQuickScan
  foot:SetText((last and L("Prices from your scan %s", "Priser fra din scan %s"):format(Ago(last)) or L("Not scanned yet: Scan AH at the auction house", "Ikke scannet endnu: Scan AH ved auktionshuset"))
    .. "  ·  " .. L("after the AH's 5%", "efter AH's 5%"))
  more:SetText(#shown > room and L("%d-%d of %d  ·  scroll", "%d til %d af %d  ·  scroll"):format(scroll + 1, math.min(#shown, scroll + room), #shown) or "")
end
page:SetScript("OnShow", function(self) C_Timer.After(0, function() if self:IsShown() then self:Refresh() end end) end)

-- CraftETA: Waylaid Crates and Merchant's Favor. Fill a crate with ONE bundle from its list, seal it, and hand
-- it in for Merchant's Favor (Dokimi, Crossroads for the Horde; Marcy Baker, Three Corners for the Alliance).
-- This page finds the cheapest way to a goal ("200 favor"): crates in your bags first, then crates on the
-- auction house, each filled with its cheapest bundle, counting the materials you already have.
-- Crates and bundles from WoW-Professions.com (https://www.wow-professions.com/forever), used with permission.
local _, ns = ...
local T, Plain = ns.T, ns.Plain

local function L(en, da) return (ns.db and ns.db.lang == "da") and da or en end

-- material IDs (checked against the game's own name before use; a wrong one falls back to the name)
local ID = {
  ["Linen Cloth"] = 2589, ["Light Leather"] = 2318, ["Copper Ore"] = 2770, ["Tin Ore"] = 2771, ["Peacebloom"] = 2447,
  ["Silverleaf"] = 765, ["Earthroot"] = 2449, ["Mageroyal"] = 785, ["Briarthorn"] = 2450, ["Strange Dust"] = 10940,
  ["Greater Magic Essence"] = 10939, ["Small Glimmering Shard"] = 10978, ["Large Glimmering Shard"] = 11084,
  ["Cured Light Hide"] = 4231, ["Bolt of Linen Cloth"] = 2996, ["Copper Bar"] = 2840, ["Tin Bar"] = 3576, ["Bronze Bar"] = 2841,
  ["Handful of Copper Bolts"] = 4359, ["Copper Tube"] = 4361, ["Copper Modulator"] = 4363, ["Wool Cloth"] = 2592,
  ["Silk Cloth"] = 4306, ["Medium Leather"] = 2319, ["Silver Ore"] = 2775, ["Iron Ore"] = 2772, ["Stranglekelp"] = 3820,
  ["Bruiseweed"] = 2453, ["Wild Steelbloom"] = 3355, ["Grave Moss"] = 3369, ["Kingsblood"] = 3356, ["Soul Dust"] = 11083,
  ["Greater Astral Essence"] = 11082, ["Small Glowing Shard"] = 11138, ["Large Glowing Shard"] = 11139,
  ["Bolt of Woolen Cloth"] = 2997, ["Bolt of Silk Cloth"] = 4305, ["Cured Medium Hide"] = 4233, ["Silver Bar"] = 2842,
  ["Iron Bar"] = 3575, ["Bronze Tube"] = 4371, ["Whirring Bronze Gizmo"] = 4375, ["Bronze Framework"] = 4382,
  ["Gold Power Core"] = 10558, ["Mageweave Cloth"] = 4338, ["Heavy Leather"] = 4234, ["Gold Ore"] = 2776, ["Mithril Ore"] = 3858,
  ["Liferoot"] = 3357, ["Fadeleaf"] = 3818, ["Goldthorn"] = 3821, ["Khadgar's Whisker"] = 3358, ["Wintersbite"] = 3819,
  ["Firebloom"] = 4625, ["Purple Lotus"] = 8831, ["Arthas' Tears"] = 8836, ["Vision Dust"] = 11137,
  ["Greater Mystic Essence"] = 11135, ["Small Radiant Shard"] = 11174, ["Large Radiant Shard"] = 11178,
  ["Bolt of Mageweave"] = 4339, ["Cured Heavy Hide"] = 4236, ["Mithril Bar"] = 3860, ["Steel Bar"] = 3859, ["Gold Bar"] = 3577,
  ["Iron Strut"] = 4387, ["Mithril Tube"] = 10559, ["Unstable Trigger"] = 10560, ["Mithril Casing"] = 10561,
  ["Runecloth"] = 14047, ["Thick Leather"] = 4304, ["Rugged Leather"] = 8170, ["Truesilver Ore"] = 7911, ["Thorium Ore"] = 10620,
  ["Dark Iron Ore"] = 11370, ["Golden Sansam"] = 13464, ["Sungrass"] = 8838, ["Blindweed"] = 8839, ["Ghost Mushroom"] = 8845,
  ["Gromsblood"] = 8846, ["Dreamfoil"] = 13463, ["Mountain Silversage"] = 13465, ["Plaguebloom"] = 13466, ["Icecap"] = 13467,
  ["Dream Dust"] = 11176, ["Greater Nether Essence"] = 11175, ["Small Brilliant Shard"] = 14343, ["Large Brilliant Shard"] = 14344,
  ["Bolt of Runecloth"] = 14048, ["Cured Thick Hide"] = 8172, ["Dark Iron Bar"] = 11371, ["Truesilver Bar"] = 6037,
  ["Thorium Bar"] = 12359, ["Thorium Widget"] = 15994,
}

-- { tier, type, favor (nil: not known yet), level, { material, count }, ... }
local LVL = { Apprentice = 10, Journeyman = 10, Expert = 20, Artisan = 35 }
ns.CRATES = {
  { "Apprentice", "Textiles", 5, { "Linen Cloth", 40 }, { "Light Leather", 20 } },
  { "Apprentice", "Ore", 5, { "Copper Ore", 20 }, { "Tin Ore", 20 } },
  { "Apprentice", "Herbs", 5, { "Peacebloom", 20 }, { "Silverleaf", 20 }, { "Earthroot", 10 }, { "Mageroyal", 10 }, { "Briarthorn", 10 } },
  { "Apprentice", "Curiosities", 5, { "Strange Dust", 20 }, { "Greater Magic Essence", 4 }, { "Small Glimmering Shard", 6 }, { "Large Glimmering Shard", 2 } },
  { "Apprentice", "Fabrics", 10, { "Cured Light Hide", 2 }, { "Bolt of Linen Cloth", 20 } },
  { "Apprentice", "Ingots", 10, { "Copper Bar", 20 }, { "Tin Bar", 20 }, { "Bronze Bar", 10 } },
  { "Apprentice", "Parts", 10, { "Handful of Copper Bolts", 16 }, { "Copper Tube", 16 }, { "Copper Modulator", 4 } },
  { "Journeyman", "Textiles", 10, { "Wool Cloth", 40 }, { "Silk Cloth", 40 }, { "Medium Leather", 20 } },
  { "Journeyman", "Ore", 10, { "Silver Ore", 10 }, { "Iron Ore", 20 } },
  { "Journeyman", "Herbs", 10, { "Stranglekelp", 10 }, { "Bruiseweed", 10 }, { "Wild Steelbloom", 10 }, { "Grave Moss", 10 }, { "Kingsblood", 10 } },
  { "Journeyman", "Curiosities", 10, { "Soul Dust", 20 }, { "Greater Astral Essence", 4 }, { "Small Glowing Shard", 6 }, { "Large Glowing Shard", 2 } },
  { "Journeyman", "Fabrics", 20, { "Bolt of Woolen Cloth", 6 }, { "Bolt of Silk Cloth", 10 }, { "Cured Medium Hide", 2 } },
  { "Journeyman", "Ingots", 20, { "Silver Bar", 10 }, { "Iron Bar", 20 } },
  { "Journeyman", "Parts", 20, { "Bronze Tube", 8 }, { "Whirring Bronze Gizmo", 7 }, { "Bronze Framework", 4 }, { "Gold Power Core", 45 } },
  { "Expert", "Textiles", 15, { "Mageweave Cloth", 40 }, { "Heavy Leather", 20 } },
  { "Expert", "Ore", 15, { "Gold Ore", 10 }, { "Mithril Ore", 20 } },
  { "Expert", "Earthly Herbs", 15, { "Liferoot", 20 }, { "Fadeleaf", 10 }, { "Goldthorn", 10 }, { "Khadgar's Whisker", 10 } },
  { "Expert", "Flowering Herbs", 15, { "Wintersbite", 10 }, { "Firebloom", 10 }, { "Purple Lotus", 20 }, { "Arthas' Tears", 10 } },
  { "Expert", "Curiosities", 15, { "Vision Dust", 20 }, { "Greater Mystic Essence", 4 }, { "Small Radiant Shard", 6 }, { "Large Radiant Shard", 2 } },
  { "Expert", "Fabrics", 30, { "Bolt of Mageweave", 8 }, { "Cured Heavy Hide", 2 } },
  { "Expert", "Ingots", 30, { "Mithril Bar", 20 }, { "Steel Bar", 15 }, { "Gold Bar", 10 } },
  { "Expert", "Parts", 30, { "Iron Strut", 8 }, { "Mithril Tube", 5 }, { "Unstable Trigger", 12 }, { "Mithril Casing", 5 } },
  { "Artisan", "Textiles", nil, { "Runecloth", 40 }, { "Thick Leather", 20 }, { "Rugged Leather", 20 } },
  { "Artisan", "Ore", nil, { "Truesilver Ore", 10 }, { "Thorium Ore", 20 }, { "Dark Iron Ore", 20 } },
  { "Artisan", "Earthly Herbs", nil, { "Golden Sansam", 10 }, { "Sungrass", 20 }, { "Blindweed", 10 }, { "Ghost Mushroom", 10 }, { "Gromsblood", 10 } },
  { "Artisan", "Flowering Herbs", nil, { "Dreamfoil", 20 }, { "Mountain Silversage", 20 }, { "Plaguebloom", 20 }, { "Icecap", 20 } },
  { "Artisan", "Curiosities", nil, { "Dream Dust", 20 }, { "Greater Nether Essence", 4 }, { "Small Brilliant Shard", 6 }, { "Large Brilliant Shard", 2 } },
  { "Artisan", "Fabrics", nil, { "Bolt of Runecloth", 8 }, { "Cured Thick Hide", 2 } },
  { "Artisan", "Ingots", nil, { "Dark Iron Bar", 2 }, { "Truesilver Bar", 10 }, { "Thorium Bar", 20 } },
  { "Artisan", "Parts", nil, { "Thorium Widget", 5 }, { "Truesilver Transformer", 5 }, { "Thorium Tube", 2 } },
}
local function CrateName(c) return c[1] .. " " .. c[2] end

-- an item ID for a material: the built-in one when the game agrees on its name, else the name lookup
local checked = {}
local function MatID(name)
  if checked[name] ~= nil then return checked[name] or nil end
  local id = ID[name]
  if id and C_Item and C_Item.GetItemNameByID then
    local ok, n = pcall(C_Item.GetItemNameByID, id)
    n = ok and Plain(n) or nil
    if n and n ~= name then id = nil end          -- the game says it's another item
    if not n then return id end                   -- not loaded yet: use it, check again later
  end
  id = id or ns.ItemID(name)
  checked[name] = id or false
  return id
end
local function Price(name) return ns.PriceID(MatID(name), name) end
local function Have(name)
  local id = MatID(name)
  if id and ns.BagCount then return ns.BagCount(id) end
  return ns.Have(name)
end

---------------------------------------------------------------------------
-- Which crate is it? From its name and tooltip: the tier word and the type word, or else the bundle list
---------------------------------------------------------------------------
local TYPES = { "Earthly", "Flowering", "Textiles", "Curiosities", "Fabrics", "Ingots", "Parts", "Herbs", "Ore" }
function ns.CrateFromText(text)
  if type(text) ~= "string" or text == "" then return nil end
  local tier
  for t in pairs(LVL) do if string.find(text, t, 1, true) then tier = t end end
  local kind
  for _, k in ipairs(TYPES) do
    if string.find(text, k, 1, true) then kind = k break end
  end
  if tier and kind then
    for _, c in ipairs(ns.CRATES) do
      if c[1] == tier and string.find(c[2], kind, 1, true) then return c end
    end
  end
  -- no words to go on: the crate whose bundles are all named in the text
  local best, hits = nil, 0
  for _, c in ipairs(ns.CRATES) do
    local n = 0
    for i = 4, #c do if string.find(text, c[i][1], 1, true) then n = n + 1 end end
    if n == #c - 3 and n > hits then best, hits = c, n end
  end
  return best
end

local function TooltipText(get, ...)
  if not (C_TooltipInfo and C_TooltipInfo[get]) then return "" end
  local ok, data = pcall(C_TooltipInfo[get], ...)
  if not ok or type(data) ~= "table" or type(data.lines) ~= "table" then return "" end
  local parts = {}
  for _, line in ipairs(data.lines) do
    local l, r = Plain(line.leftText), Plain(line.rightText)
    if type(l) == "string" then parts[#parts + 1] = l end
    if type(r) == "string" then parts[#parts + 1] = r end
  end
  return table.concat(parts, "\n")
end

-- the crates in your bags: { crate, name, id, sealed }
function ns.BagCrates()
  local out = {}
  local C = C_Container
  if not (C and C.GetContainerNumSlots and C.GetContainerItemInfo) then return out end
  for bag = 0, 5 do
    local okN, slots = pcall(C.GetContainerNumSlots, bag)
    for slot = 1, (okN and tonumber(Plain(slots)) or 0) do
      local ok, info = pcall(C.GetContainerItemInfo, bag, slot)
      local link = ok and type(info) == "table" and Plain(info.hyperlink)
      local name = link and string.match(link, "%[(.-)%]")
      if name and (string.find(name, "Waylaid", 1, true) or string.find(name, "Crate", 1, true)) then
        local text = name .. "\n" .. TooltipText("GetBagItem", bag, slot)
        out[#out + 1] = { crate = ns.CrateFromText(text), name = name, id = Plain(info.itemID),
          count = tonumber(Plain(info.stackCount)) or 1, sealed = string.find(name, "Sealed", 1, true) ~= nil }
      end
    end
  end
  return out
end

---------------------------------------------------------------------------
-- Crates on the auction house: one search for "Waylaid" (and "Crate"), kept with the time
---------------------------------------------------------------------------
local ahScan
function ns.ScanCrates()
  if not (C_AuctionHouse and C_AuctionHouse.SendBrowseQuery) then return end
  if not (AuctionHouseFrame and AuctionHouseFrame:IsShown()) then
    ns.Print(L("Open the auction house first.", "Åbn auktionshuset først."))
    return
  end
  ahScan = { words = { "Waylaid", "Crate" }, i = 1, found = {} }
  ns.Print(L("Looking for Waylaid Crates on the auction house...", "Leder efter Waylaid Crates på auktionshuset..."))
  pcall(C_AuctionHouse.SendBrowseQuery, { searchString = ahScan.words[1], sorts = {}, filters = {}, itemClassFilters = {} })
end

local function OnCrateBrowse()
  if not ahScan then return end
  for _, result in ipairs(C_AuctionHouse.GetBrowseResults() or {}) do
    local key = result.itemKey
    local ok, info = pcall(C_AuctionHouse.GetItemKeyInfo, key)
    local name = ok and info and Plain(info.itemName)
    if name and not ahScan.found[key.itemID] and (string.find(name, "Waylaid", 1, true) or string.find(name, "Crate", 1, true))
        and not string.find(name, "Sealed", 1, true) then
      local text = name .. "\n" .. TooltipText("GetItemByID", key.itemID)
      ahScan.found[key.itemID] = { id = key.itemID, name = name, price = Plain(result.minPrice) or 0,
        qty = Plain(result.totalQuantity) or 1, crate = nil, text = text }
    end
  end
  if C_AuctionHouse.HasFullBrowseResults and not C_AuctionHouse.HasFullBrowseResults() then
    pcall(C_AuctionHouse.RequestMoreBrowseResults)
    return
  end
  ahScan.i = ahScan.i + 1
  if ahScan.words[ahScan.i] then
    pcall(C_AuctionHouse.SendBrowseQuery, { searchString = ahScan.words[ahScan.i], sorts = {}, filters = {}, itemClassFilters = {} })
    return
  end
  local list = {}
  for _, f in pairs(ahScan.found) do
    local c = ns.CrateFromText(f.text)
    list[#list + 1] = { id = f.id, name = f.name, price = f.price, qty = f.qty, key = c and CrateName(c) or nil }
  end
  ns.db.crateAH = { t = time(), list = list }
  ns.Print(L("Found %d kinds of crates on the auction house.", "Fandt %d slags kasser på auktionshuset."):format(#list))
  ahScan = nil
  if ns.RefreshHub then ns.RefreshHub() end
end
ns.Register("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED")
ns.On("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED", function() pcall(OnCrateBrowse) end)
ns.Register("AUCTION_HOUSE_BROWSE_RESULTS_ADDED")
ns.On("AUCTION_HOUSE_BROWSE_RESULTS_ADDED", function() pcall(OnCrateBrowse) end)

---------------------------------------------------------------------------
-- The cheapest bundle for a crate, using what you have (stock is changed as the plan uses it)
---------------------------------------------------------------------------
local function BestBundle(c, stock)
  local best
  for i = 4, #c do
    local mat, count = c[i][1], c[i][2]
    local have = math.min(count, stock[mat] or 0)
    local unit = Price(mat)
    local spend = unit and (count - have) * unit or (have >= count and 0 or nil)
    if spend and (not best or spend < best.spend) then
      best = { mat = mat, count = count, have = have, buy = count - have, spend = spend, unit = unit }
    end
  end
  return best
end

local function StockNow()
  local stock = {}
  for _, c in ipairs(ns.CRATES) do
    for i = 4, #c do local m = c[i][1]; if stock[m] == nil then stock[m] = Have(m) end end
  end
  return stock
end

-- the plan to reach `goal` favor: crates in your bags first, then the auction house's, cheapest favor first
function ns.FavorPlan(goal)
  local level = UnitLevel("player") or 1
  local stock = StockNow()
  local byKey = {}
  for _, c in ipairs(ns.CRATES) do byKey[CrateName(c)] = c end
  local sources = {}
  for _, b in ipairs(ns.BagCrates()) do
    if b.crate and not b.sealed and b.crate[3] and level >= LVL[b.crate[1]] then
      for _ = 1, b.count do sources[#sources + 1] = { crate = b.crate, from = "bag", cost = 0, name = b.name } end
    end
  end
  local ah = ns.db.crateAH and ns.db.crateAH.list or {}
  for _, a in ipairs(ah) do
    local c = a.key and byKey[a.key]
    if c and c[3] and level >= LVL[c[1]] then
      for _ = 1, math.min(a.qty or 1, 20) do
        sources[#sources + 1] = { crate = c, from = "ah", cost = a.price or 0, name = a.name, id = a.id }
      end
    end
  end
  local steps, got, gold = {}, 0, 0
  while got < goal and #sources > 0 do
    -- the source with the lowest gold per favor right now (bundles get dearer as your stock runs out)
    local bestI, bestV, bestB
    for i, s in ipairs(sources) do
      local b = BestBundle(s.crate, stock)
      if b then
        local v = (s.cost + b.spend) / s.crate[3]
        if not bestV or v < bestV then bestI, bestV, bestB = i, v, b end
      end
    end
    if not bestI then break end
    local s = table.remove(sources, bestI)
    stock[bestB.mat] = (stock[bestB.mat] or 0) - bestB.have
    got = got + s.crate[3]
    gold = gold + s.cost + bestB.spend
    steps[#steps + 1] = { crate = s.crate, from = s.from, cost = s.cost, bundle = bestB, id = s.id, name = s.name }
  end
  return steps, got, gold
end

-- your Merchant's Favor, when the game shows it as a currency
function ns.FavorNow()
  local C = C_CurrencyInfo
  if not (C and C.GetCurrencyListSize and C.GetCurrencyListInfo) then return nil end
  local ok, n = pcall(C.GetCurrencyListSize)
  for i = 1, (ok and tonumber(Plain(n)) or 0) do
    local okI, info = pcall(C.GetCurrencyListInfo, i)
    if okI and type(info) == "table" and Plain(info.name) == "Merchant's Favor" then return Plain(info.quantity) end
  end
  return nil
end

---------------------------------------------------------------------------
-- The Favor page of the main window
---------------------------------------------------------------------------
local function Head(data, text, click) data[#data + 1] = { head = true, name = text, click = click } end
local TURN_IN = { h = "Dokimi, Crossroads (The Barrens), west gate", a = "Marcy Baker, Three Corners (Redridge Mountains)" }

ns.HubBuilders.favor = function(data, state, Control)
  ns.db.favorGoal = ns.db.favorGoal or 200
  local X = ns.HUB_X
  local function Btn(i, x, w, text, fn, tip)
    local b = Control(i)
    b:SetPoint("TOPLEFT", X + x, -22); b:SetWidth(w)
    b:SetText(text); b.tip = tip
    b.label:SetTextColor(0.85, 0.87, 0.9)
    b:SetScript("OnClick", fn); b:Show()
  end
  local goal = ns.db.favorGoal
  Btn(1, 0, 30, "-", function() ns.db.favorGoal = math.max(5, goal - (IsShiftKeyDown() and 10 or 50)); ns.RefreshHub() end, L("Shift: 10", "Shift: 10"))
  Btn(2, 34, 110, L("Goal: %d favor", "Mål: %d favor"):format(goal), function() end)
  Btn(3, 148, 30, "+", function() ns.db.favorGoal = goal + (IsShiftKeyDown() and 10 or 50); ns.RefreshHub() end, L("Shift: 10", "Shift: 10"))
  Btn(4, 190, 130, L("Scan AH crates", "Scan kasser på AH"), function() ns.ScanCrates() end,
    L("At the auction house: finds every Waylaid Crate for sale and its price.", "Ved auktionshuset: finder alle Waylaid Crates til salg og deres pris."))
  local steps, got, gold = ns.FavorPlan(goal)
  Btn(5, 324, 140, L("Mats to shopping list", "Mats på indkøbslisten"), function()
    local mats, order = {}, {}
    for _, s in ipairs(steps) do
      local b = s.bundle
      if b.buy > 0 then
        if not mats[b.mat] then order[#order + 1] = b.mat end
        mats[b.mat] = (mats[b.mat] or 0) + b.buy
      end
    end
    if #order > 0 then ns.AddToList(mats, order); ns.Print(L("Added the plan's materials to the shopping list.", "Planens materialer er lagt på indkøbslisten.")) end
  end)

  local f = ns.Faction()
  Head(data, L("Plan: %d of %d favor  ·  %s", "Plan: %d af %d favor  ·  %s"):format(got, goal, ns.Money(gold)))
  if #steps == 0 then
    data[#data + 1] = { indent = 8, name = L("No crates to plan with yet: scan the auction house, or loot some crates.",
      "Ingen kasser at planlægge med endnu: scan auktionshuset, eller find nogle kasser."), r = 0.6, g = 0.62, b = 0.67 }
  end
  for _, s in ipairs(steps) do
    local b = s.bundle
    local where = s.from == "bag" and L("in your bags", "i dine tasker") or (L("AH ", "AH ") .. ns.Money(s.cost))
    local fill = b.count .. " " .. b.mat .. (b.have > 0 and L(" (have %d)", " (har %d)"):format(b.have) or "")
    data[#data + 1] = {
      indent = 8, icon = ns.ItemIcon(b.mat), name = CrateName(s.crate) .. "  |cff8c8f96" .. where .. "  ·  " .. fill .. "|r",
      value = "+" .. s.crate[3] .. "  " .. ns.Money(s.cost + b.spend), vr = 1, vg = 0.82, vb = 0.3,
      click = function()
        if s.id and ns.AHSearch then ns.AHSearch(s.id, s.name) end
      end,
      tip = function(tip)
        tip:SetText(CrateName(s.crate), 1, 0.82, 0.3)
        tip:AddLine(L("Fill with: ", "Fyld med: ") .. fill, 0.85, 0.87, 0.9, true)
        if b.buy > 0 then tip:AddDoubleLine(L("Buy", "Køb"), b.buy .. " x " .. (b.unit and ns.Money(b.unit) or "?"), 0.85, 0.87, 0.9, 1, 1, 1) end
        if s.cost > 0 then tip:AddDoubleLine(L("Crate", "Kasse"), ns.Money(s.cost), 0.85, 0.87, 0.9, 1, 1, 1) end
        tip:AddDoubleLine(L("Per favor", "Pr. favor"), ns.Money((s.cost + b.spend) / s.crate[3]), 0.85, 0.87, 0.9, 1, 0.82, 0.3)
        if s.id then tip:AddLine(L("Click: find it on the auction house", "Klik: find den på auktionshuset"), 0.55, 0.58, 0.64) end
      end,
    }
  end

  -- every crate type, cheapest favor first (with the materials you have now)
  Head(data, L("Every crate, cheapest favor first (bundle only)", "Alle kasser, billigste favor først (kun bundtet)"))
  local stock, rows = StockNow(), {}
  for _, c in ipairs(ns.CRATES) do
    local b = BestBundle(c, stock)
    rows[#rows + 1] = { c = c, b = b, per = (b and c[3]) and b.spend / c[3] or math.huge }
  end
  table.sort(rows, function(x, y) return x.per < y.per end)
  local level = UnitLevel("player") or 1
  for _, r in ipairs(rows) do
    local c, b = r.c, r.b
    local locked = level < LVL[c[1]]
    data[#data + 1] = {
      indent = 8, icon = b and ns.ItemIcon(b.mat) or 134400,
      name = CrateName(c) .. "  |cff8c8f96" .. (b and (b.count .. " " .. b.mat) or "?") .. (locked and L("  ·  level %d", "  ·  level %d"):format(LVL[c[1]]) or "") .. "|r",
      r = locked and 0.5 or 0.85, g = locked and 0.52 or 0.87, b = locked and 0.57 or 0.9,
      value = (c[3] and ("+" .. c[3] .. "  ") or "?  ") .. (b and ns.Money(b.spend) or "?"),
      vr = 0.85, vg = 0.87, vb = 0.9,
      tip = function(tip)
        tip:SetText(CrateName(c), 1, 0.82, 0.3)
        tip:AddLine(L("Any ONE of:", "En af disse:"), 0.55, 0.58, 0.64)
        for i = 4, #c do
          local p = Price(c[i][1])
          tip:AddDoubleLine(c[i][2] .. " " .. c[i][1], p and ns.Money(p * c[i][2]) or "?", 0.85, 0.87, 0.9, 1, 1, 1)
        end
        if not c[3] then tip:AddLine(L("Favor for Artisan crates isn't known yet.", "Favor for Artisan-kasser kendes ikke endnu."), 0.6, 0.62, 0.67, true) end
      end,
    }
  end
  local fav = ns.FavorNow()
  state.footer = (fav and (L("You have %d Merchant's Favor.  ", "Du har %d Merchant's Favor.  "):format(fav)) or "")
    .. L("Hand in: ", "Aflever: ") .. TURN_IN[f]
end

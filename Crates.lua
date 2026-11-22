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

-- CraftETA learns these IDs at once, so icons and prices work before the game has loaded the items
ns.Register("ADDON_LOADED")
ns.On("ADDON_LOADED", function(name)
  if name ~= "CraftETA" or not ns.db then return end
  ns.db.ids = ns.db.ids or {}
  for n, id in pairs(ID) do
    if not ns.db.ids[n] then ns.LearnItem(n, id) end
  end
end)

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
-- the silver a crate gives back with its favor, by its colour (1 white, 2 green); blue and Elite crates are
-- not known yet, so the plan leaves them out
local BACK = { Apprentice = { 250, 500 }, Journeyman = { 500, 1000 }, Expert = { 750, 1500 } }
local function Back(c, quality) return (BACK[c[1]] and BACK[c[1]][quality or 1]) or 0 end

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
local function IconOf(name, id)
  id = id or MatID(name)
  if id and C_Item and C_Item.GetItemIconByID then
    local ok, tex = pcall(C_Item.GetItemIconByID, id)
    if ok and Plain(tex) then return Plain(tex) end
  end
  local tex = ns.ItemIcon(name)
  return (tex and tex ~= 134400) and tex or "Interface\\Icons\\INV_Crate_01"
end
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
        out[#out + 1] = { crate = ns.CrateFromText(text), name = name, id = Plain(info.itemID), quality = tonumber(Plain(info.quality)) or 1, bag = bag, slot = slot,
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
      ahScan.found[key.itemID] = { id = key.itemID, name = name, price = Plain(result.minPrice) or 0, quality = tonumber(Plain(info.quality)) or 1,
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
    list[#list + 1] = { id = f.id, name = f.name, price = f.price, qty = f.qty, quality = f.quality, key = c and CrateName(c) or nil }
  end
  ns.db.crateAH = { t = time(), list = list }
  ns.Print(L("Found %d kinds of crates on the auction house.", "Fandt %d slags kasser på auktionshuset."):format(#list))
  ahScan = nil
  if ns.RefreshHub then ns.RefreshHub() end
end
-- the Favor page shows its scan button only while the auction house is open
for _, e in ipairs({ "AUCTION_HOUSE_SHOW", "AUCTION_HOUSE_CLOSED" }) do
  ns.Register(e)
  ns.On(e, function() C_Timer.After(0, function() if ns.RefreshHub then ns.RefreshHub() end end) end)
end
ns.Register("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED")
ns.On("AUCTION_HOUSE_BROWSE_RESULTS_UPDATED", function() pcall(OnCrateBrowse) end)
ns.Register("AUCTION_HOUSE_BROWSE_RESULTS_ADDED")
ns.On("AUCTION_HOUSE_BROWSE_RESULTS_ADDED", function() pcall(OnCrateBrowse) end)

---------------------------------------------------------------------------
-- The cheapest bundle for a crate, using what you have (stock is changed as the plan uses it)
---------------------------------------------------------------------------
-- what `n` more of a material cost when the plan has already bought `before`: the auctions themselves when the
-- house showed them lately (the cheapest go first, so each crate pays a little more), else one price
local function Spend(mat, before, n)
  if n <= 0 then return 0 end
  if ns.BuyCost then
    local a = ns.BuyCost(mat, before + n)
    local b = ns.BuyCost(mat, before)
    if a and b then return a - b end
  end
  local unit = Price(mat)
  return unit and unit * n or nil
end

local function BestBundle(c, stock, bought)
  local best
  for i = 4, #c do
    local mat, count = c[i][1], c[i][2]
    local have = math.min(count, stock[mat] or 0)
    local spend = Spend(mat, bought[mat] or 0, count - have)
    local unit = spend and count > have and spend / (count - have) or Price(mat)
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
    if b.crate and not b.sealed and b.crate[3] and level >= LVL[b.crate[1]] and (b.quality or 1) <= 2 then
      for _ = 1, b.count do sources[#sources + 1] = { crate = b.crate, from = "bag", cost = 0, name = b.name, id = b.id, back = Back(b.crate, b.quality) } end
    end
  end
  local ah = ns.db.crateAH and ns.db.crateAH.list or {}
  for _, a in ipairs(ah) do
    local c = a.key and byKey[a.key]
    if c and c[3] and level >= LVL[c[1]] and (a.quality or 1) <= 2 then
      for _ = 1, math.min(a.qty or 0, 20) do
        sources[#sources + 1] = { crate = c, from = "ah", cost = a.price or 0, name = a.name, id = a.id, back = Back(c, a.quality) }
      end
    end
  end
  local steps, got, gold, bought = {}, 0, 0, {}
  while got < goal and #sources > 0 do
    -- the source with the lowest gold per favor right now (bundles get dearer as your stock runs out)
    local bestI, bestV, bestB
    for i, s in ipairs(sources) do
      local b = BestBundle(s.crate, stock, bought)
      if b then
        local v = (s.cost + b.spend - s.back) / s.crate[3]
        if not bestV or v < bestV then bestI, bestV, bestB = i, v, b end
      end
    end
    if not bestI then break end
    local s = table.remove(sources, bestI)
    stock[bestB.mat] = (stock[bestB.mat] or 0) - bestB.have
    bought[bestB.mat] = (bought[bestB.mat] or 0) + bestB.buy
    got = got + s.crate[3]
    gold = gold + s.cost + bestB.spend - s.back
    steps[#steps + 1] = { crate = s.crate, from = s.from, cost = s.cost, bundle = bestB, id = s.id, name = s.name, back = s.back }
  end
  return steps, got, gold
end

-- what the favor plan needs on the shopping list: { [name] = count }, ordered names, and which are crates.
-- Whole counts: the list takes off what you have (crates in your bags included)
function ns.FavorNeeds(goal)
  local steps = ns.FavorPlan(math.max(0, goal - (ns.FavorNow() or 0)))
  local mats, order, crates = {}, {}, {}
  local function Add(name, n, id)
    if not name or n <= 0 then return end
    if id and ns.LearnItem and not (ns.db.ids and ns.db.ids[name]) then ns.LearnItem(name, id) end
    if not mats[name] then order[#order + 1] = name end
    mats[name] = (mats[name] or 0) + n
  end
  for _, st in ipairs(steps) do
    if st.name then Add(st.name, 1, st.id); crates[st.name] = true end
    Add(st.bundle.mat, st.bundle.count)
  end
  return mats, order, crates
end

-- a crate's price from the last crate scan (the cheapest of that name)
function ns.CratePrice(name)
  local ah = ns.db and ns.db.crateAH
  local best
  for _, a in ipairs(ah and ah.list or {}) do
    if a.name == name and a.price and a.price > 0 and (not best or a.price < best) then best = a.price end
  end
  return best
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
local TURN_IN = { h = "Dokimi, Crossroads (The Barrens), west gate", a = "Marcy Baker, Three Corners (Redridge Mountains)" }

---------------------------------------------------------------------------
-- What the favor vendors sell: read when you open one (any vendor whose prices are in Merchant's Favor),
-- kept per faction: { [itemID] = { n = name, i = icon, c = favor, v = vendor, u = you can use it, t = seen } }
---------------------------------------------------------------------------
-- the favor vendors (who sells what, per faction): which you have opened shows with a check
local FAVOR_VENDORS = {
  { prof = 171, h = "Apothecary Durelle", a = "Nina Surefire" },
  { prof = 164, h = "Gor'mak", a = "Stondry Darkhammer" },
  { prof = 185, h = "Aza'bek", a = "Kalsey Sanden" },
  { prof = 333, h = "Beneris", a = "Alynsia" },
  { prof = 202, h = "Fizzlefuse", a = "Fritz Fizzle" },
  { prof = 165, h = "Pawani", a = "Daniel Stitchsong" },
  { prof = 197, h = "Jim'bek", a = "Mivin Shadowweave" },
  { icon = "Interface\\Icons\\Ability_Mount_Kodo_01", what = { "Mount", "Mount" }, h = "Okamache", a = "Huey Sunnydale" },
  { icon = "Interface\\Icons\\INV_Shirt_GuildTabard_01", what = { "Tabard, pet treat and more", "Tabard, pet treat og mere" }, h = "Gishah", a = "Tamelyn Aldridge" },
}
-- vendor name -> its place in the list (1-9): the same on both factions
local FAVOR_NPCS = {}
for k, v in ipairs(FAVOR_VENDORS) do FAVOR_NPCS[v.h] = k; FAVOR_NPCS[v.a] = k end
-- a price in Merchant's Favor: its currency link or name, or any currency at one of the favor vendors
local function IsFavor(name, link, npc)
  if type(link) == "string" and link:find("currency:3402", 1, true) then return true end
  if type(name) == "string" and name:find("Favor", 1, true) then return true end
  return npc and FAVOR_NPCS[npc] and type(link) == "string" and link:find("currency:", 1, true) and true or false
end
local function ReadFavorShop()
  if not ns.db or not GetMerchantNumItems then return end
  local okN, n = pcall(GetMerchantNumItems)
  n = okN and tonumber(Plain(n)) or 0
  local npc = Plain(UnitName("npc"))
  local f = ns.Faction()
  local found = {}
  for i = 1, n do
    local okL, link = pcall(GetMerchantItemLink, i)
    link = okL and Plain(link)
    local id = type(link) == "string" and tonumber(link:match("item:(%d+)"))
    local name, icon, usable
    if C_MerchantFrame and C_MerchantFrame.GetItemInfo then
      local ok, info = pcall(C_MerchantFrame.GetItemInfo, i)
      if ok and type(info) == "table" then name, icon, usable = Plain(info.name), Plain(info.texture), Plain(info.isUsable) end
    end
    if not name then
      local ok, nm, tex, _, _, _, _, us = pcall(GetMerchantItemInfo, i)
      if ok then name, icon, usable = Plain(nm), Plain(tex), Plain(us) end
    end
    local okC, count = pcall(GetMerchantItemCostInfo, i)
    count = okC and tonumber(Plain(count)) or 0
    for j = 1, count do
      local ok, _, value, clink, cname = pcall(GetMerchantItemCostItem, i, j)
      if ok and IsFavor(Plain(cname), Plain(clink), npc) and id and name then
        found[id] = { n = name, i = icon, c = tonumber(Plain(value)) or 0, v = npc, u = usable ~= false, t = time() }
      end
    end
  end
  if next(found) then
    ns.db.favorShop = ns.db.favorShop or {}
    ns.db.favorShop[f] = ns.db.favorShop[f] or {}
    for id, e in pairs(found) do ns.db.favorShop[f][id] = e end
    if ns.RefreshHub then ns.RefreshHub() end
    -- tell the guild (once per vendor visit)
    if ns.ShareFavorVendor then ns.ShareFavorVendor(f, npc, found) end
  end
end
for _, e in ipairs({ "MERCHANT_SHOW", "MERCHANT_UPDATE" }) do
  ns.Register(e)
  ns.On(e, function() C_Timer.After(0.4, function() pcall(ReadFavorShop) end) end)
end

---------------------------------------------------------------------------
-- Shared with the guild: one guild member who has opened the favor vendors is enough for everyone.
-- "F?\th"                      who knows what the Horde favor vendors sell?
-- "F\th\t3\t1234:45,1235:120"  vendor 3 of the list sells item 1234 for 45 favor and 1235 for 120
-- What you saw at a vendor yourself always wins over what the guild told you.
---------------------------------------------------------------------------
local PREFIX = "CraftETA"
local function CanSend() return C_ChatInfo and C_ChatInfo.SendAddonMessage and IsInGuild and IsInGuild() end

-- one vendor's things, in messages short enough for the game
local function SendVendor(f, k, items, delay)
  local parts, line = {}, ""
  for id, e in pairs(items) do
    local bit = id .. ":" .. e.c
    if #line + #bit + 1 > 200 then parts[#parts + 1] = line; line = "" end
    line = line == "" and bit or (line .. "," .. bit)
  end
  if line ~= "" then parts[#parts + 1] = line end
  for n, part in ipairs(parts) do
    C_Timer.After((delay or 0) + n * 0.4, function()
      pcall(C_ChatInfo.SendAddonMessage, PREFIX, "F\t" .. f .. "\t" .. k .. "\t" .. part, "GUILD")
    end)
  end
  return #parts
end

-- everything you saw yourself for a faction, vendor by vendor
local function SendAll(f)
  if not (CanSend() and ns.db.guildShare and ns.db.favorShop and ns.db.favorShop[f]) then return end
  local byVendor = {}
  for id, e in pairs(ns.db.favorShop[f]) do
    local k = e.v and FAVOR_NPCS[e.v]
    if k and not e.shared then byVendor[k] = byVendor[k] or {}; byVendor[k][id] = e end
  end
  local delay = 0
  for k, items in pairs(byVendor) do delay = delay + SendVendor(f, k, items, delay) * 0.4 end
end
ns.ShareFavorShop = SendAll
-- after a visit: that vendor's things to the guild (once per visit, not on every update of the window)
local lastShared
function ns.ShareFavorVendor(f, npc, items)
  local k = npc and FAVOR_NPCS[npc]
  if not (k and ns.db.guildShare and CanSend()) or lastShared == npc then return end
  lastShared = npc
  SendVendor(f, k, items, 0)
end
ns.Register("MERCHANT_CLOSED")
ns.On("MERCHANT_CLOSED", function() lastShared = nil end)

-- a vendor's profession decides whether you can use what it sells (shared things have no "usable" of yours)
local function Usable(k)
  local v = FAVOR_VENDORS[k]
  if not v or not v.prof then return true end
  return ns.Skills(true)[v.prof] ~= nil
end

local lastHeard, asked = 0, {}
ns.Register("CHAT_MSG_ADDON")
ns.On("CHAT_MSG_ADDON", function(prefix, msg, channel, sender)
  prefix, msg, sender = Plain(prefix), Plain(msg), Plain(sender)
  if prefix ~= PREFIX or type(msg) ~= "string" or not ns.db then return end
  local kind, f, k, list = strsplit("\t", msg)
  local me = Plain(UnitName("player"))
  local short = type(sender) == "string" and string.match(sender, "^[^-]+")
  if short == me then return end
  if kind == "F?" and (f == "h" or f == "a") then
    -- answer after a little while, unless someone else in the guild already did
    if asked[f] and GetTime() - asked[f] < 30 then return end
    asked[f] = GetTime()
    C_Timer.After(1 + math.random() * 5, function()
      if GetTime() - lastHeard > 4 then SendAll(f) end
    end)
  elseif kind == "F" and (f == "h" or f == "a") and tonumber(k) and list then
    lastHeard = GetTime()
    local v = FAVOR_VENDORS[tonumber(k)]
    if not v then return end
    ns.db.favorShop = ns.db.favorShop or {}
    ns.db.favorShop[f] = ns.db.favorShop[f] or {}
    local shop = ns.db.favorShop[f]
    for id, cost in string.gmatch(list, "(%d+):(%d+)") do
      id, cost = tonumber(id), tonumber(cost)
      local mine = shop[id]
      if not mine or mine.shared then
        local name = C_Item and C_Item.GetItemNameByID and Plain(C_Item.GetItemNameByID(id))
        if not name and C_Item and C_Item.RequestLoadItemDataByID then pcall(C_Item.RequestLoadItemDataByID, id) end
        local icon = C_Item and C_Item.GetItemIconByID and Plain(C_Item.GetItemIconByID(id))
        shop[id] = { n = name, i = icon, c = cost, v = v[f], u = Usable(tonumber(k)), t = time(), shared = short or true }
      end
    end
    if ns.RefreshFavorShop then C_Timer.After(0.3, ns.RefreshFavorShop) end
  end
end)

-- after login: ask the guild when you don't know all the vendors yet
ns.On("PLAYER_LOGIN", function()
  C_Timer.After(20, function()
    if not (ns.db and ns.db.guildAsk and CanSend()) then return end
    local f = ns.Faction()
    local known = {}
    for _, e in pairs(ns.db.favorShop and ns.db.favorShop[f] or {}) do if e.v then known[e.v] = true end end
    local n = 0
    for _ in pairs(known) do n = n + 1 end
    if n < #FAVOR_VENDORS then pcall(C_ChatInfo.SendAddonMessage, PREFIX, "F?\t" .. f, "GUILD") end
  end)
end)

---------------------------------------------------------------------------
-- The Favor page: your favor and goal on top, the plan as numbered steps (buy crates, buy materials,
-- fill, hand in), and the crates that give favor cheapest at the bottom
---------------------------------------------------------------------------
local H, X, CW = ns.Hub, ns.HUB_X, ns.HUB_CW
local page = CreateFrame("Frame", nil, H)
page:SetPoint("TOPLEFT", X, -20)
page:SetPoint("BOTTOMRIGHT", -18, 16)
page:Hide()
ns.HubCustom.favor = page

local GOLD = { 1, 0.82, 0.29 }
local favorScroll = 0   -- the first item shown on the "Buy for favor" tab
local function Fill(parent, r, g, b, a, layer, sub)
  local t = parent:CreateTexture(nil, layer or "BACKGROUND", nil, sub or 1)
  t:SetColorTexture(r, g, b, a or 1)
  return t
end
local function Card(parent, edge)
  local f = CreateFrame("Frame", nil, parent)
  Fill(f, 0.086, 0.094, 0.122):SetAllPoints()
  local e = edge or { 0.2, 0.21, 0.25, 1 }
  for _, p in ipairs({ { "TOPLEFT", "TOPRIGHT", true }, { "BOTTOMLEFT", "BOTTOMRIGHT", true }, { "TOPLEFT", "BOTTOMLEFT" }, { "TOPRIGHT", "BOTTOMRIGHT" } }) do
    local t = f:CreateTexture(nil, "BORDER")
    t:SetPoint(p[1]); t:SetPoint(p[2])
    if p[3] then t:SetHeight(1) else t:SetWidth(1) end
    t:SetColorTexture(e[1], e[2], e[3], e[4] or 1)
  end
  return f
end
local function Icon(parent, size)
  local t = parent:CreateTexture(nil, "ARTWORK")
  t:SetSize(size, size)
  t:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  return t
end
local function Tip(frame, fn)
  frame:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    fn(GameTooltip)
    GameTooltip:Show()
  end)
  frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

-- top: your favor, the bar to your goal, the goal box and presets
local top = Card(page, { 0.47, 0.38, 0.16, 1 })
top:SetPoint("TOPLEFT"); top:SetPoint("RIGHT"); top:SetHeight(92)
local topIcon = Icon(top, 44); topIcon:SetPoint("TOPLEFT", 16, -16); topIcon:SetTexture("Interface\\Icons\\INV_Crate_01")
local topHead = ns.Font(top, true, 9, 0.62, 0.55, 0.36); topHead:SetPoint("TOPLEFT", topIcon, "TOPRIGHT", 12, 0)
local topBig = ns.Font(top, true, 20, GOLD[1], GOLD[2], GOLD[3]); topBig:SetPoint("TOPLEFT", topHead, "BOTTOMLEFT", 0, -4)
local topSub = ns.Font(top, false, 10, 0.6, 0.62, 0.67); topSub:SetPoint("LEFT", topBig, "RIGHT", 8, -2)
local barBg = Fill(top, 0.05, 0.055, 0.07, 1, "ARTWORK")
barBg:SetPoint("TOPLEFT", topIcon, "BOTTOMLEFT", 0, -10); barBg:SetPoint("RIGHT", top, "RIGHT", -230, 0); barBg:SetHeight(6)
local bar = Fill(top, GOLD[1], GOLD[2], GOLD[3], 1, "ARTWORK", 2)
bar:SetPoint("TOPLEFT", barBg); bar:SetPoint("BOTTOMLEFT", barBg); bar:SetWidth(1)

local goalHead = ns.Font(top, true, 9, 0.36, 0.38, 0.42); goalHead:SetPoint("TOPRIGHT", -48, -14); goalHead:SetJustifyH("RIGHT")
local goalBox = ns.NumberBox(top, 70, 24, 15, function(n)
  ns.db.favorGoal = math.max(1, n)
  ns.RefreshHub()
end)
goalBox:SetPoint("TOPRIGHT", -48, -28)
local goalUnit = ns.Font(top, false, 10, 0.6, 0.62, 0.67); goalUnit:SetPoint("RIGHT", goalBox, "LEFT", -6, 0)
local presets = {}
for i, v in ipairs({ 50, 100, 200, 500 }) do
  local b = ns.Button(top, tostring(v), 44, 18)
  b:SetPoint("TOPRIGHT", -48 - (4 - i) * 48, -60)
  b.label:SetFont(ns.F_BOLD, 10, "")
  b:SetScript("OnClick", function() ns.db.favorGoal = v; ns.RefreshHub() end)
  b.value = v
  presets[i] = b
end

-- the plan
local plan = Card(page)
plan:SetPoint("TOPLEFT", top, "BOTTOMLEFT", 0, -8); plan:SetPoint("RIGHT")
local planHead = ns.Font(plan, true, 9, 0.36, 0.38, 0.42); planHead:SetPoint("TOPLEFT", 16, -12)
local planTotal = ns.Font(plan, true, 17, GOLD[1], GOLD[2], GOLD[3]); planTotal:SetPoint("TOPRIGHT", -16, -10); planTotal:SetJustifyH("RIGHT")
local planPer = ns.Font(plan, false, 10, 0.6, 0.62, 0.67); planPer:SetPoint("TOPRIGHT", planTotal, "BOTTOMRIGHT", 0, -2); planPer:SetJustifyH("RIGHT")
local planEmpty = ns.Font(plan, false, 11, 0.6, 0.62, 0.67); planEmpty:SetPoint("TOPLEFT", 16, -40)
planEmpty:SetPoint("RIGHT", plan, "RIGHT", -16, 0); planEmpty:SetWordWrap(true)
local listBtn = ns.Primary(ns.Button(plan, "", 190, 26), 12)
listBtn:SetPoint("BOTTOMRIGHT", -16, 12)
local scanBtn = ns.Button(plan, "", 150, 26)
scanBtn:SetPoint("RIGHT", listBtn, "LEFT", -8, 0)
scanBtn.label:SetTextColor(0.85, 0.87, 0.9)
scanBtn:SetScript("OnClick", function() ns.ScanCrates() end)
local scanAge = ns.Font(plan, false, 9, 0.45, 0.47, 0.52); scanAge:SetPoint("BOTTOMLEFT", 16, 44)

-- fill a crate: a click uses the next crate in your bags that you have the materials for (the game seals it).
-- Using an item needs a secure button, and its target can't change in combat
local fillBtn = CreateFrame("Button", "CraftETAFillCrate", plan, "SecureActionButtonTemplate")
fillBtn:SetSize(220, 26); fillBtn:SetPoint("BOTTOMLEFT", 16, 12)
fillBtn:RegisterForClicks("AnyUp", "AnyDown")
fillBtn:SetAttribute("type", "item")
fillBtn.bg = fillBtn:CreateTexture(nil, "BACKGROUND"); fillBtn.bg:SetAllPoints()
fillBtn.label = ns.Font(fillBtn, true, 11, 0.1, 0.08, 0.03); fillBtn.label:SetPoint("CENTER"); fillBtn.label:SetShadowOffset(0, 0)
local fillHl = fillBtn:CreateTexture(nil, "HIGHLIGHT"); fillHl:SetAllPoints(); fillHl:SetColorTexture(1, 1, 1, 0.12)
local function FillLook(on)
  fillBtn.bg:SetColorTexture(on and 0.35 or 0.2, on and 0.78 or 0.19, on and 0.42 or 0.15, 1)
  fillBtn.label:SetTextColor(on and 0.04 or 0.45, on and 0.1 or 0.45, on and 0.05 or 0.47)
end
FillLook(false)
fillBtn:HookScript("OnEnter", function(self)
  GameTooltip:SetOwner(self, "ANCHOR_TOP")
  GameTooltip:SetText(L("Fill a crate", "Fyld en kasse"), 1, 0.82, 0.3)
  if self.crate then
    GameTooltip:AddLine(L("Click: uses %s. With the materials in your bags the game seals it.", "Klik: bruger %s. Med materialerne i tasken forsegler spillet den."):format(self.crate), 0.85, 0.87, 0.9, true)
  else
    GameTooltip:AddLine(L("No crate in your bags that you have the materials for.", "Ingen kasse i tasken, som du har materialerne til."), 0.85, 0.87, 0.9, true)
  end
  GameTooltip:Show()
end)
fillBtn:HookScript("OnLeave", function() GameTooltip:Hide() end)

-- the crates you can fill now: { name, bag, slot }
local function Fillable()
  local out = {}
  local level = UnitLevel("player") or 1
  for _, b in ipairs(ns.BagCrates()) do
    local c = b.crate
    if c and not b.sealed and b.bag and level >= (LVL[c[1]] or 1) then
      for k = 4, #c do
        if Have(c[k][1]) >= c[k][2] then out[#out + 1] = { name = b.name, bag = b.bag, slot = b.slot }; break end
      end
    end
  end
  return out
end
function page:UpdateFill()
  if InCombatLockdown and InCombatLockdown() then return end
  local list = Fillable()
  local first = list[1]
  if first then
    fillBtn:SetAttribute("item", first.bag .. " " .. first.slot)
    fillBtn.crate = first.name
    fillBtn.label:SetText(L("Fill crate (%d ready)", "Fyld kasse (%d klar)"):format(#list))
    FillLook(true)
  else
    fillBtn:SetAttribute("item", nil)
    fillBtn.crate = nil
    fillBtn.label:SetText(L("No crate to fill", "Ingen kasse at fylde"))
    FillLook(false)
  end
end
ns.Register("BAG_UPDATE_DELAYED")
ns.On("BAG_UPDATE_DELAYED", function() if page:IsVisible() then page:Refresh() end end)
ns.Register("PLAYER_REGEN_ENABLED")
ns.On("PLAYER_REGEN_ENABLED", function() if page:IsVisible() then page:UpdateFill() end end)

-- a numbered step: a badge, its title, and up to 3 lines under it
local STEP_LINES = 3
local steps = {}
local function Step(i)
  if steps[i] then return steps[i] end
  local s = CreateFrame("Frame", nil, plan)
  s:SetWidth(CW - 32)
  s.badge = CreateFrame("Frame", nil, s); s.badge:SetSize(18, 18); s.badge:SetPoint("TOPLEFT")
  Fill(s.badge, GOLD[1], GOLD[2], GOLD[3]):SetAllPoints()
  s.num = ns.Font(s.badge, true, 10, 0.08, 0.06, 0.02); s.num:SetPoint("CENTER"); s.num:SetShadowOffset(0, 0)
  s.title = ns.Font(s, true, 11, 0.9, 0.91, 0.94); s.title:SetPoint("LEFT", s.badge, "RIGHT", 8, 0)
  s.right = ns.Font(s, true, 11, 1, 1, 1); s.right:SetPoint("TOPRIGHT", 0, -3); s.right:SetJustifyH("RIGHT")
  s.lines = {}
  for l = 1, STEP_LINES do
    local r = CreateFrame("Frame", nil, s); r:SetSize(CW - 58, 18)
    r:SetPoint("TOPLEFT", 26, -22 - (l - 1) * 19)
    r.icon = Icon(r, 16); r.icon:SetPoint("LEFT")
    r.value = ns.Font(r, false, 10, 0.85, 0.87, 0.9); r.value:SetPoint("RIGHT"); r.value:SetJustifyH("RIGHT")
    r.text = ns.Font(r, false, 10, 0.78, 0.8, 0.84); r.text:SetPoint("LEFT", r.icon, "RIGHT", 6, 0)
    r.text:SetPoint("RIGHT", r.value, "LEFT", -8, 0); r.text:SetWordWrap(false)
    r:EnableMouse(true)
    s.lines[l] = r
  end
  steps[i] = s
  return s
end

-- the cheapest crates
local cheap = Card(page)
cheap:SetPoint("TOPLEFT", plan, "BOTTOMLEFT", 0, -8); cheap:SetPoint("BOTTOMRIGHT")
local cheapHead = ns.Font(cheap, true, 9, 0.36, 0.38, 0.42); cheapHead:SetPoint("TOPLEFT", 16, -12); cheapHead:Hide()
-- two tabs: the cheapest crates, and what the favor vendors sell
local tabs = {}
for i, key in ipairs({ "crates", "shop" }) do
  local b = ns.Button(cheap, "", 150, 20)
  b:SetPoint("TOPLEFT", 12 + (i - 1) * 156, -8)
  b.key = key
  b:SetScript("OnClick", function()
    if key == "shop" then ns.ToggleFavorShop() else ns.db.favorTab = key; page:Refresh() end
  end)
  tabs[i] = b
end
-- the basket: what you want from the favor vendors, and what reaching it costs
local cartBar = CreateFrame("Frame", nil, cheap)
cartBar:SetPoint("BOTTOMLEFT", 12, 8); cartBar:SetPoint("BOTTOMRIGHT", -12, 8); cartBar:SetHeight(30)
local cartBg = cartBar:CreateTexture(nil, "BACKGROUND"); cartBg:SetAllPoints(); cartBg:SetColorTexture(1, 0.82, 0.3, 0.08)
local cartIcon = cartBar:CreateTexture(nil, "ARTWORK"); cartIcon:SetSize(18, 18); cartIcon:SetPoint("LEFT", 8, 0)
cartIcon:SetTexture("Interface\\Icons\\INV_Misc_Bag_10_Blue"); cartIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
local cartText = ns.Font(cartBar, true, 10, 0.9, 0.91, 0.94); cartText:SetPoint("LEFT", cartIcon, "RIGHT", 8, 0)
local cartGoal = ns.Primary(ns.Button(cartBar, "", 110, 22), 11); cartGoal:SetPoint("RIGHT", -4, 0)
local cartClear = ns.Button(cartBar, "", 56, 22); cartClear:SetPoint("RIGHT", cartGoal, "LEFT", -6, 0)
cartClear.label:SetTextColor(0.85, 0.87, 0.9)
cartText:SetPoint("RIGHT", cartClear, "LEFT", -8, 0); cartText:SetWordWrap(false)
local function Cart()
  local f = ns.Faction()
  ns.db.favorCart = ns.db.favorCart or {}
  ns.db.favorCart[f] = ns.db.favorCart[f] or {}
  return ns.db.favorCart[f]
end

local usableSwitch = ns.Switch(cheap, function() ns.db.favorAll = not ns.db.favorAll; favorScroll = 0; page:Refresh() end)
usableSwitch:SetPoint("TOPRIGHT", -16, -10)
local usableLabel = ns.Font(cheap, false, 9, 0.6, 0.62, 0.67); usableLabel:SetPoint("RIGHT", usableSwitch, "LEFT", -6, 0)
cheap:EnableMouseWheel(true)
cheap:SetScript("OnMouseWheel", function(_, delta)
  favorScroll = math.max(0, (favorScroll or 0) - delta * 2)
  page:Refresh()
end)
local cheapNote = ns.Font(cheap, false, 9, 0.45, 0.47, 0.52); cheapNote:SetPoint("TOPRIGHT", -16, -12); cheapNote:SetJustifyH("RIGHT")
local COLS, CHEAP_H = 2, 34
local CHEAP_W = math.floor((CW - 32 - 8) / COLS)
local tiles = {}
local function Tile(i)
  if tiles[i] then return tiles[i] end
  local t = CreateFrame("Frame", nil, cheap)
  t:SetSize(CHEAP_W, CHEAP_H - 4)
  Fill(t, 0.11, 0.122, 0.157):SetAllPoints()
  t.icon = Icon(t, 22); t.icon:SetPoint("LEFT", 8, 0)
  t.name = ns.Font(t, true, 10, 0.9, 0.91, 0.94); t.name:SetPoint("TOPLEFT", t.icon, "TOPRIGHT", 8, 1)
  t.sub = ns.Font(t, false, 9, 0.5, 0.52, 0.57); t.sub:SetPoint("BOTTOMLEFT", t.icon, "BOTTOMRIGHT", 8, -1)
  t.per = ns.Font(t, true, 10, GOLD[1], GOLD[2], GOLD[3]); t.per:SetPoint("TOPRIGHT", -8, -5); t.per:SetJustifyH("RIGHT")
  t.fav = ns.Font(t, false, 9, 0.5, 0.52, 0.57); t.fav:SetPoint("BOTTOMRIGHT", -8, 5); t.fav:SetJustifyH("RIGHT")
  t.name:SetPoint("RIGHT", t.per, "LEFT", -6, 0); t.name:SetWordWrap(false)
  t.sub:SetPoint("RIGHT", t.fav, "LEFT", -6, 0); t.sub:SetWordWrap(false)
  t:EnableMouse(true)
  tiles[i] = t
  return t
end

local function Ago(t)
  if not t then return nil end
  local m = math.floor((time() - t) / 60)
  if m < 1 then return L("just now", "lige nu") end
  if m < 60 then return L("%d min ago", "for %d min siden"):format(m) end
  return L("%d h ago", "for %d t siden"):format(math.floor(m / 60))
end

function page:Refresh()
  ns.db.favorGoal = ns.db.favorGoal or 200
  local goal = ns.db.favorGoal
  local have = ns.FavorNow()
  local f = ns.Faction()

  -- top
  topHead:SetText(L("MERCHANT'S FAVOR", "MERCHANT'S FAVOR"))
  topBig:SetText((have or 0) .. " / " .. goal)
  local left = math.max(0, goal - (have or 0))
  topSub:SetText(have and (left > 0 and L("%d to go", "%d mangler"):format(left) or L("goal reached", "mål nået"))
    or L("(open the currency tab once to read it)", "(åbn currency-fanen én gang, så kan den læses)"))
  local w = math.max(1, barBg:GetWidth() or 1)
  bar:SetWidth(math.max(1, w * math.min(1, (have or 0) / math.max(1, goal))))
  goalHead:SetText(L("YOUR GOAL", "DIT MÅL"))
  goalUnit:SetText(L("favor", "favor"))
  goalBox:SetNumberValue(goal)
  for _, b in ipairs(presets) do
    local on = b.value == goal
    b.label:SetTextColor(on and GOLD[1] or 0.85, on and GOLD[2] or 0.87, on and GOLD[3] or 0.9)
  end

  -- the plan, grouped into steps
  local list, got, gold = ns.FavorPlan(left)
  local buyCrates, bagCrates, mats, fills, back = {}, {}, {}, {}, 0
  local cOrder, mOrder, fOrder = {}, {}, {}
  for _, st in ipairs(list) do
    local name = CrateName(st.crate)
    if st.from == "ah" then
      local k = name .. "|" .. st.cost
      if not buyCrates[k] then buyCrates[k] = { name = name, item = st.name, id = st.id, n = 0, each = st.cost }; cOrder[#cOrder + 1] = buyCrates[k] end
      buyCrates[k].n = buyCrates[k].n + 1
    else
      bagCrates[name] = (bagCrates[name] or 0) + 1
    end
    local b = st.bundle
    if not mats[b.mat] then mats[b.mat] = { mat = b.mat, buy = 0, have = 0, spend = 0 }; mOrder[#mOrder + 1] = mats[b.mat] end
    mats[b.mat].buy = mats[b.mat].buy + b.buy
    mats[b.mat].have = mats[b.mat].have + b.have
    mats[b.mat].spend = mats[b.mat].spend + b.spend
    local fk = name .. "|" .. b.mat
    if not fills[fk] then fills[fk] = { name = name, mat = b.mat, count = b.count, n = 0, crate = st.crate }; fOrder[#fOrder + 1] = fills[fk] end
    fills[fk].n = fills[fk].n + 1
    back = back + (st.back or 0)
  end

  planHead:SetText(L("YOUR PLAN  ·  THE CHEAPEST WAY TO %d FAVOR", "DIN PLAN  ·  BILLIGSTE VEJ TIL %d FAVOR"):format(goal))
  local atAH = ns.AH and ns.AH.open
  scanBtn:SetShown(atAH)
  scanBtn:SetText(L("Scan AH crates", "Scan kasser på AH"))
  Tip(scanBtn, function(tip) tip:SetText(L("Finds every Waylaid Crate for sale and its price.", "Finder alle Waylaid Crates til salg og deres pris."), 1, 1, 1, 1, true) end)
  local scanned = ns.db.crateAH and ns.db.crateAH.t
  scanAge:SetText(scanned and L("Crates scanned %s", "Kasser scannet %s"):format(Ago(scanned)) or L("Crates not scanned yet", "Kasser ikke scannet endnu"))

  for _, s in ipairs(steps) do s:Hide() end
  local y = -40
  if left == 0 then
    planTotal:SetText(""); planPer:SetText("")
    planEmpty:SetText(L("Goal reached. Set a higher goal to plan more.", "Mål nået. Sæt et højere mål for at planlægge mere."))
    planEmpty:Show(); y = -64
    listBtn:Hide()
  elseif #list == 0 then
    planTotal:SetText(""); planPer:SetText("")
    planEmpty:SetText(L("No crates to plan with yet. Go to the auction house and press Scan AH crates, or loot some crates.",
      "Ingen kasser at planlægge med endnu. Gå til auktionshuset og tryk Scan kasser på AH, eller find nogle kasser."))
    planEmpty:Show(); y = -72
    listBtn:Hide()
  else
    planEmpty:Hide()
    planTotal:SetText(ns.Money(math.max(0, gold)))
    planPer:SetText(L("+%d favor  ·  %s per favor", "+%d favor  ·  %s pr. favor"):format(got, ns.Money(math.max(0, gold) / math.max(1, got))))
    listBtn:Show()
    listBtn:SetText(L("Plan to shopping list", "Planen på indkøbslisten"))
    listBtn:SetScript("OnClick", function()
      if ns.SetFavorPlan then ns.SetFavorPlan(goal) end
      ns.Print(L("Favor plan on the shopping list: %d favor. The crates are bought with the buy button at the auction house.",
        "Favor-planen er på indkøbslisten: %d favor. Kasserne købes med køb-knappen ved auktionshuset."):format(goal))
    end)
    Tip(listBtn, function(tip)
      tip:SetText(L("Plan to shopping list", "Planen på indkøbslisten"), 1, 0.82, 0.3)
      tip:AddLine(L("The crates and materials go on the list and stay up to date as you buy and hand in. At the auction house the buy button buys them.",
        "Kasser og mats kommer på listen og holder sig opdateret, mens du køber og afleverer. Ved auktionshuset køber køb-knappen dem."), 0.85, 0.87, 0.9, true)
    end)

    local n = 0
    local function AddStep(title, right, lines)
      n = n + 1
      local s = Step(n)
      s:ClearAllPoints(); s:SetPoint("TOPLEFT", 16, y)
      s.num:SetText(n); s.title:SetText(title); s.right:SetText(right or "")
      local shown = math.min(#lines, STEP_LINES)
      for l = 1, STEP_LINES do
        local r, d = s.lines[l], lines[l]
        if d and l <= shown then
          if l == STEP_LINES and #lines > STEP_LINES then
            d = { icon = d.icon, text = d.text .. L("  ·  +%d more", "  ·  +%d mere"):format(#lines - STEP_LINES), value = d.value, tip = d.tip }
          end
          -- an atlas (the blue "?" of a repeatable quest) or a texture
          local okA, set = false, nil
          if d.atlas and r.icon.SetAtlas then okA, set = pcall(r.icon.SetAtlas, r.icon, d.atlas) end
          if not (okA and set ~= false) then
            r.icon:SetTexture(d.icon or 134400)
            r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
          end
          r.text:SetText(d.text); r.value:SetText(d.value or "")
          if d.tip then Tip(r, d.tip) else r:SetScript("OnEnter", nil); r:SetScript("OnLeave", nil) end
          r:Show()
        else
          r:Hide()
        end
      end
      s:SetHeight(22 + shown * 19)
      s:Show()
      y = y - (22 + shown * 19) - 8
    end

    -- 1: crates
    local lines, cost = {}, 0
    for name, c in pairs(bagCrates) do
      lines[#lines + 1] = { icon = "Interface\\Icons\\INV_Crate_01", text = c .. " x " .. name, value = "|cff73d973" .. L("in your bags", "i dine tasker") .. "|r" }
    end
    for _, c in ipairs(cOrder) do
      cost = cost + c.n * c.each
      lines[#lines + 1] = { icon = IconOf(c.item, c.id), text = c.n .. " x " .. c.name .. "  |cff8c8f96" .. L("AH, %s each", "AH, %s stk"):format(ns.Money(c.each)) .. "|r",
        value = ns.Money(c.n * c.each),
        tip = function(tip)
          tip:SetText(c.item or c.name, 1, 0.82, 0.3)
          tip:AddLine(L("The price is the cheapest listing from your last scan. At the auction house the shopping list's buy button buys the cheapest one.",
            "Prisen er den billigste fra din seneste scan. Ved auktionshuset køber indkøbslistens køb-knap den billigste."), 0.85, 0.87, 0.9, true)
        end }
    end
    AddStep(#cOrder > 0 and L("Buy the crates", "Køb kasserne") or L("Your crates", "Dine kasser"), cost > 0 and ns.Money(cost) or "", lines)

    -- 2: materials
    lines, cost = {}, 0
    for _, m in ipairs(mOrder) do
      cost = cost + m.spend
      local unit = m.buy > 0 and m.spend / m.buy or nil
      lines[#lines + 1] = { icon = IconOf(m.mat),
        text = (m.buy > 0 and (m.buy .. " x " .. m.mat) or m.mat) .. "  |cff8c8f96" .. (m.have > 0 and L("you have %d", "du har %d"):format(m.have) or "") .. "|r",
        value = m.buy > 0 and ns.Money(m.spend) or ("|cff73d973" .. L("have them", "har dem") .. "|r"),
        tip = function(tip)
          tip:SetText(m.mat, 1, 0.82, 0.3)
          if m.buy > 0 then tip:AddDoubleLine(L("Buy", "Køb"), m.buy .. " x " .. (unit and ns.Money(unit) or "?"), 0.85, 0.87, 0.9, 1, 1, 1) end
          if m.have > 0 then tip:AddDoubleLine(L("From your bags", "Fra dine tasker"), m.have, 0.85, 0.87, 0.9, 1, 1, 1) end
        end }
    end
    AddStep(L("Get the materials", "Skaf materialerne"), cost > 0 and ns.Money(cost) or "", lines)

    -- 3: fill and seal
    lines = {}
    for _, fl in ipairs(fOrder) do
      lines[#lines + 1] = { icon = IconOf(fl.mat), text = L("%s: %d %s in each", "%s: %d %s i hver"):format(fl.name, fl.count, fl.mat),
        value = fl.n .. (fl.n == 1 and L(" crate", " kasse") or L(" crates", " kasser")) }
    end
    AddStep(L("Fill and seal them", "Fyld og forsegl dem"), "", lines)

    -- 4: hand in
    AddStep(L("Hand them in", "Aflever dem"), "|cffffd24a+" .. got .. " favor|r", {
      { atlas = "QuestRepeatableTurnin", icon = "Interface\\GossipFrame\\DailyActiveQuestIcon", text = TURN_IN[f], value = back > 0 and ("|cff73d973+" .. ns.Money(back) .. L(" back", " tilbage") .. "|r") or "" },
    })
  end
  plan:SetHeight(-y + 76)
  page:UpdateFill()

  -- the bottom card: the cheapest crates, or what you can buy for favor
  local tab = "crates"
  local shopList = ns.db.favorShop and ns.db.favorShop[f] or {}
  local shopN = 0
  for _ in pairs(shopList) do shopN = shopN + 1 end
  tabs[1]:SetText(L("Cheapest crates", "Billigste kasser"))
  tabs[2]:SetText(L("Buy for favor", "Køb for favor") .. (shopN > 0 and (" (" .. shopN .. ")") or "") .. "  »")
  for _, b in ipairs(tabs) do
    local on = b.key == tab
    b.label:SetTextColor(on and 1 or 0.6, on and 0.82 or 0.62, on and 0.3 or 0.68)
  end
  for _, t in ipairs(tiles) do t:Hide() end
  cheapNote:Hide()
  usableSwitch:SetShown(tab == "shop"); usableLabel:SetShown(tab == "shop")
  cartBar:SetShown(tab == "shop")
  local room = math.floor(((cheap:GetHeight() or 200) - 34 - (tab == "shop" and 40 or 0)) / CHEAP_H)
  local fit = math.max(0, room) * COLS
  local function Place(t, k)
    t:ClearAllPoints()
    t:SetPoint("TOPLEFT", 16 + ((k - 1) % COLS) * (CHEAP_W + 8), -34 - math.floor((k - 1) / COLS) * CHEAP_H)
  end


  -- the cheapest crates per favor
  local stock, rows = StockNow(), {}
  local level = UnitLevel("player") or 1
  for _, c in ipairs(ns.CRATES) do
    if c[3] and level >= LVL[c[1]] then
      local b = BestBundle(c, stock, {})
      if b then rows[#rows + 1] = { c = c, b = b, per = b.spend / c[3] } end
    end
  end
  table.sort(rows, function(a, b) return a.per < b.per end)
  for i = 1, math.min(#rows, fit) do
    local r, t = rows[i], Tile(i)
    Place(t, i)
    t:SetScript("OnMouseUp", nil)
    t.name:SetTextColor(0.9, 0.91, 0.94)
    t.icon:SetTexture(IconOf(r.b.mat))
    t.name:SetText(CrateName(r.c))
    t.sub:SetText(r.b.count .. " " .. r.b.mat)
    t.per:SetText(ns.Money(r.per) .. L("/favor", "/favor"))
    t.fav:SetText("+" .. r.c[3] .. "  ·  " .. ns.Money(r.b.spend))
    local c = r.c
    Tip(t, function(tip)
      tip:SetText(CrateName(c), 1, 0.82, 0.3)
      tip:AddLine(L("Any ONE of:", "En af disse:"), 0.55, 0.58, 0.64)
      for k = 4, #c do
        local p = Price(c[k][1])
        tip:AddDoubleLine(c[k][2] .. " " .. c[k][1], p and ns.Money(p * c[k][2]) or "?", 0.85, 0.87, 0.9, 1, 1, 1)
      end
    end)
    t:Show()
  end
end
page:SetScript("OnShow", function(self) C_Timer.After(0, function() if self:IsShown() then self:Refresh() end end) end)

---------------------------------------------------------------------------
-- Buy for favor: a window of its own. What the favor vendors sell (learned when you open them), a basket,
-- and what reaching the basket's favor costs the cheapest way
---------------------------------------------------------------------------
local SW, SH = 620, 540
local win = ns.Window("CraftETAFavorShop", SW, "|cffffffffBuy for|r |cffffd24afavor|r")
win:SetHeight(SH)
win:SetFrameStrata("DIALOG")
local wHave = ns.Font(win, true, 12, 1, 0.82, 0.3); wHave:SetPoint("TOPRIGHT", -40, -13); wHave:SetJustifyH("RIGHT")
local wSwitch = ns.Switch(win, function() ns.db.favorAll = not ns.db.favorAll; favorScroll = 0; win:Refresh() end)
wSwitch:SetPoint("TOPRIGHT", -14, -78)
local wSwitchLabel = ns.Font(win, false, 10, 0.6, 0.62, 0.67); wSwitchLabel:SetPoint("RIGHT", wSwitch, "LEFT", -6, 0)
local wCount = ns.Font(win, false, 10, 0.5, 0.52, 0.57); wCount:SetPoint("TOPLEFT", 16, -80)
local wEmpty = ns.Font(win, false, 11, 0.6, 0.62, 0.67); wEmpty:SetPoint("TOPLEFT", 16, -104); wEmpty:SetPoint("RIGHT", win, "RIGHT", -16, 0)
wEmpty:SetWordWrap(true); wEmpty:SetJustifyH("LEFT")

local wVend = {}
for k, v in ipairs(FAVOR_VENDORS) do
  local b = CreateFrame("Frame", nil, win)
  b:SetSize(28, 28)
  b:SetPoint("TOPLEFT", 16 + (k - 1) * 34, -42)
  b.icon = b:CreateTexture(nil, "ARTWORK"); b.icon:SetAllPoints(); b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  b.check = b:CreateTexture(nil, "OVERLAY"); b.check:SetSize(14, 14); b.check:SetPoint("BOTTOMRIGHT", 3, -3)
  b.check:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
  b:EnableMouse(true)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  b.v = v
  wVend[k] = b
end
local wVendNote = ns.Font(win, false, 10, 0.6, 0.62, 0.67)
wVendNote:SetPoint("LEFT", wVend[#wVend], "RIGHT", 12, 0)

-- the big rewards, known from the start (from Warcraft Wiki, "Merchant's Favor", CC BY-SA 4.0:
-- https://warcraft.wiki.gg/wiki/Merchant's_Favor). Everything else is learned at the vendors themselves.
local FAVOR_REWARDS = {
  { key = "kodo", n = "Reins of the Pack Kodo", c = 6000, v = { h = "Okamache", a = "Huey Sunnydale" }, i = "Interface\\Icons\\Ability_Mount_Kodo_01" },
  { key = "mule", n = "Packmule Treat", c = 1500, v = { h = "Gishah", a = "Tamelyn Aldridge" }, i = "Interface\\Icons\\INV_Misc_Food_19" },
  { key = "license", n = "Advertising License Application", c = 1200, v = { h = "Gishah", a = "Tamelyn Aldridge" }, i = "Interface\\Icons\\INV_Scroll_03" },
  { key = "title", n = { "A profession title", "En profession-titel" }, c = 1000, v = { h = "Gishah", a = "Tamelyn Aldridge" }, i = "Interface\\Icons\\INV_Misc_Note_02" },
  { key = "tabard", n = { h = "Durotar Supply and Logistics Tabard", a = "Azeroth Commerce Authority Tabard" }, c = 200, v = { h = "Gishah", a = "Tamelyn Aldridge" }, i = "Interface\\Icons\\INV_Shirt_GuildTabard_01" },
}
-- everything you can buy: the rewards above, and what the vendors showed you (that wins, it is the live price)
local function FavorItems(f)
  local all, byName = {}, {}
  for id, e in pairs(ns.db.favorShop and ns.db.favorShop[f] or {}) do
    if not e.n and type(id) == "number" then
      -- told by the guild: the name and icon come from the game once it has loaded the item
      e.n = C_Item and C_Item.GetItemNameByID and Plain(C_Item.GetItemNameByID(id)) or nil
      e.i = e.i or (C_Item and C_Item.GetItemIconByID and Plain(C_Item.GetItemIconByID(id))) or nil
    end
    local shown = e.n and e or setmetatable({ n = "...", }, { __index = e })
    all[id] = shown
    if e.n then byName[e.n] = true end
  end
  for _, r in ipairs(FAVOR_REWARDS) do
    local name = type(r.n) == "table" and (r.n[f] or (ns.db.lang == "da" and r.n[2] or r.n[1])) or r.n
    if not byName[name] then
      all[r.key] = { n = name, c = r.c, v = r.v[f], i = r.i, u = true, wiki = true }
    end
  end
  return all
end

local WCOLS, WT_H = 2, 46
local WT_W = math.floor((SW - 32 - 8) / WCOLS)
local WROWS = 7
local wTiles = {}
local function WTile(i)
  if wTiles[i] then return wTiles[i] end
  local t = CreateFrame("Button", nil, win)
  t:SetSize(WT_W, WT_H - 6)
  t:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  t.bg = t:CreateTexture(nil, "BACKGROUND"); t.bg:SetAllPoints(); t.bg:SetColorTexture(0.086, 0.094, 0.122, 1)
  t.mark = t:CreateTexture(nil, "BORDER"); t.mark:SetPoint("TOPLEFT"); t.mark:SetPoint("BOTTOMLEFT"); t.mark:SetWidth(2)
  t.icon = t:CreateTexture(nil, "ARTWORK"); t.icon:SetSize(30, 30); t.icon:SetPoint("LEFT", 8, 0); t.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  t.cost = ns.Font(t, true, 11, 1, 0.82, 0.3); t.cost:SetPoint("TOPRIGHT", -10, -6); t.cost:SetJustifyH("RIGHT")
  t.state = ns.Font(t, false, 9, 0.5, 0.52, 0.57); t.state:SetPoint("BOTTOMRIGHT", -10, 6); t.state:SetJustifyH("RIGHT")
  t.name = ns.Font(t, true, 11, 0.9, 0.91, 0.94); t.name:SetPoint("TOPLEFT", t.icon, "TOPRIGHT", 9, 0)
  t.name:SetPoint("RIGHT", t.cost, "LEFT", -8, 0); t.name:SetWordWrap(false)
  t.sub = ns.Font(t, false, 9, 0.5, 0.52, 0.57); t.sub:SetPoint("BOTTOMLEFT", t.icon, "BOTTOMRIGHT", 9, 0)
  t.sub:SetPoint("RIGHT", t.state, "LEFT", -8, 0); t.sub:SetWordWrap(false)
  local hl = t:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints(); hl:SetColorTexture(1, 1, 1, 0.05)
  t:SetScript("OnLeave", function() GameTooltip:Hide() end)
  wTiles[i] = t
  return t
end
local wMore = ns.Font(win, false, 9, 0.45, 0.47, 0.52); wMore:SetPoint("TOPRIGHT", -16, -100 - WROWS * WT_H); wMore:SetJustifyH("RIGHT")

-- the basket card
local basket = CreateFrame("Frame", nil, win)
basket:SetPoint("BOTTOMLEFT", 12, 12); basket:SetPoint("BOTTOMRIGHT", -12, 12); basket:SetHeight(66)
local bBg = basket:CreateTexture(nil, "BACKGROUND"); bBg:SetAllPoints(); bBg:SetColorTexture(0.086, 0.094, 0.122, 1)
local bEdge = basket:CreateTexture(nil, "BORDER"); bEdge:SetPoint("TOPLEFT"); bEdge:SetPoint("TOPRIGHT"); bEdge:SetHeight(1)
bEdge:SetColorTexture(0.47, 0.38, 0.16, 1)
local bIcon = basket:CreateTexture(nil, "ARTWORK"); bIcon:SetSize(34, 34); bIcon:SetPoint("LEFT", 14, 0)
bIcon:SetTexture("Interface\\Icons\\INV_Misc_Bag_10_Blue"); bIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
local bTitle = ns.Font(basket, true, 14, 0.9, 0.91, 0.94); bTitle:SetPoint("TOPLEFT", bIcon, "TOPRIGHT", 12, 0)
local bSub = ns.Font(basket, false, 10, 0.6, 0.62, 0.67); bSub:SetPoint("BOTTOMLEFT", bIcon, "BOTTOMRIGHT", 12, 1)
local bPlan = ns.Primary(ns.Button(basket, "", 140, 30), 12); bPlan:SetPoint("RIGHT", -14, 0)
local bClear = ns.Button(basket, "", 64, 30); bClear:SetPoint("RIGHT", bPlan, "LEFT", -8, 0)
bClear.label:SetTextColor(0.85, 0.87, 0.9)
bTitle:SetPoint("RIGHT", bClear, "LEFT", -10, 0); bSub:SetPoint("RIGHT", bClear, "LEFT", -10, 0)
bTitle:SetWordWrap(false); bSub:SetWordWrap(false)

win:EnableMouseWheel(true)
win:SetScript("OnMouseWheel", function(_, delta)
  favorScroll = math.max(0, favorScroll - delta * WCOLS)
  win:Refresh()
end)

function win:Refresh()
  if not self:IsShown() or not ns.db then return end
  local f = ns.Faction()
  local have = ns.FavorNow() or 0
  local learned = ns.db.favorShop and ns.db.favorShop[f] or {}
  local shopN = 0
  for _ in pairs(learned) do shopN = shopN + 1 end
  local shopList = FavorItems(f)
  self.title:SetText(L("|cffffffffBuy for|r |cffffd24afavor|r", "|cffffffffKøb for|r |cffffd24afavor|r"))
  wHave:SetText(L("You have %d favor", "Du har %d favor"):format(have))
  -- the vendors: opened (a check and how many things) or still to open
  local byVendor, opened = {}, 0
  for _, e in pairs(learned) do if e.v then byVendor[e.v] = (byVendor[e.v] or 0) + 1 end end
  local camp = f == "h" and "Crossroads, The Barrens" or "Three Corners, Redridge Mountains"
  for _, b in ipairs(wVend) do
    local v = b.v
    local npc = v[f] or v.h
    local n = byVendor[npc]
    if n then opened = opened + 1 end
    b.icon:SetTexture(v.icon or ns.ProfIcon(v.prof))
    b.icon:SetDesaturated(not n)
    b.icon:SetAlpha(n and 1 or 0.55)
    b.check:SetShown(n ~= nil)
    b:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
      GameTooltip:SetText(npc, 1, 0.82, 0.3)
      GameTooltip:AddLine(v.prof and ns.ProfName(v.prof) or (ns.db.lang == "da" and v.what[2] or v.what[1]), 0.85, 0.87, 0.9)
      GameTooltip:AddLine(camp, 0.6, 0.62, 0.67)
      GameTooltip:AddLine(n and L("Known: %d things", "Kendt: %d ting"):format(n) or L("Not opened yet: open it once and CraftETA remembers what it sells.", "Ikke åbnet endnu: åbn den én gang, så husker CraftETA, hvad den sælger."),
        n and 0.35 or 1, n and 0.9 or 0.82, n and 0.4 or 0.3, true)
      GameTooltip:Show()
    end)
  end
  wVendNote:SetText(opened == #wVend and L("All vendors known", "Alle handlere kendt")
    or L("%d of %d vendors known  ·  open the grey ones once", "%d af %d handlere kendt  ·  åbn de grå én gang"):format(opened, #wVend))
  wSwitch:SetOn(not ns.db.favorAll)
  wSwitchLabel:SetText(L("Only what I can use", "Kun det jeg kan bruge"))

  local list = {}
  for id, e in pairs(shopList) do
    if ns.db.favorAll or e.u then list[#list + 1] = { id = id, e = e } end
  end
  table.sort(list, function(a, b) if a.e.c ~= b.e.c then return a.e.c < b.e.c end return a.e.n < b.e.n end)
  wEmpty:ClearAllPoints()
  wEmpty:SetPoint("TOPLEFT", 16, -100 - math.ceil(#list / WCOLS) * WT_H - 6); wEmpty:SetPoint("RIGHT", win, "RIGHT", -16, 0)
  wCount:SetText(L("%d things  ·  click: in the basket  ·  right-click: out", "%d ting  ·  klik: i kurven  ·  højreklik: ud"):format(#list))
  local fit = WROWS * WCOLS
  favorScroll = math.min(favorScroll, math.max(0, #list - fit))
  favorScroll = favorScroll - favorScroll % WCOLS
  wEmpty:SetShown(shopN == 0 or #list == 0)
  wEmpty:SetText(shopN == 0 and L("The recipes come in once you have opened the vendors (%s): open each of them once and CraftETA remembers what they sell and what it costs.",
      "Opskrifterne kommer med, når du har åbnet handlerne (%s): åbn hver af dem én gang, så husker CraftETA, hvad de sælger, og hvad det koster."):format(f == "h" and "Crossroads, The Barrens" or "Three Corners, Redridge Mountains")
    or L("Nothing you can use. Switch off \"Only what I can use\" to see everything.", "Intet du kan bruge. Slå \"Kun det jeg kan bruge\" fra for at se alt."))
  local cart = Cart()
  for _, t in ipairs(wTiles) do t:Hide() end
  for k = 1, math.min(#list - favorScroll, fit) do
    local it, t = list[favorScroll + k], WTile(k)
    local e, id = it.e, it.id
    t:ClearAllPoints()
    t:SetPoint("TOPLEFT", 16 + ((k - 1) % WCOLS) * (WT_W + 8), -100 - math.floor((k - 1) / WCOLS) * WT_H)
    t.icon:SetTexture(e.i or 134400)
    t.name:SetText(e.n)
    t.name:SetTextColor(e.u and 0.9 or 0.6, e.u and 0.91 or 0.42, e.u and 0.94 or 0.4)
    t.sub:SetText(e.v or "")
    t.cost:SetText(e.c .. " favor")
    local inCart = cart[id]
    local short = e.c - have
    t.state:SetText(inCart and ("|cffffd24a" .. L("%d in basket", "%d i kurven"):format(inCart) .. "|r")
      or (short <= 0 and ("|cff73d973" .. L("you can buy it", "du kan købe den") .. "|r") or L("%d to go", "%d mangler"):format(short)))
    t.mark:SetColorTexture(1, 0.82, 0.3, inCart and 1 or 0)
    t.bg:SetColorTexture(inCart and 0.13 or 0.086, inCart and 0.12 or 0.094, inCart and 0.1 or 0.122, 1)
    t:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      if type(id) == "number" then GameTooltip:SetItemByID(id) else GameTooltip:SetText(e.n, 1, 1, 1) end
      if e.shared then GameTooltip:AddLine(L("From your guild (%s)", "Fra din guild (%s)"):format(type(e.shared) == "string" and e.shared or "?"), 0.55, 0.58, 0.64) end
      if e.wiki then GameTooltip:AddLine(L("Price from Warcraft Wiki; the vendor's own price replaces it once you open the vendor.", "Pris fra Warcraft Wiki; handlerens egen pris erstatter den, når du åbner handleren."), 0.55, 0.58, 0.64, true) end
      GameTooltip:AddLine(" ")
      GameTooltip:AddDoubleLine(L("Costs", "Koster"), e.c .. " Merchant's Favor", 0.85, 0.87, 0.9, 1, 0.82, 0.3)
      if e.v then GameTooltip:AddDoubleLine(L("Sold by", "Sælges af"), e.v, 0.85, 0.87, 0.9, 1, 1, 1) end
      GameTooltip:AddLine(L("Click: in the basket  ·  Right-click: out", "Klik: i kurven  ·  Højreklik: ud"), 0.55, 0.58, 0.64)
      GameTooltip:Show()
    end)
    t:SetScript("OnClick", function(_, button)
      if button == "RightButton" then
        cart[id] = (cart[id] or 0) > 1 and cart[id] - 1 or nil
      else
        cart[id] = (cart[id] or 0) + 1
      end
      win:Refresh()
    end)
    t:Show()
  end
  wMore:SetText(#list > fit and L("%d-%d of %d  ·  scroll for more", "%d til %d af %d  ·  scroll for flere"):format(favorScroll + 1, math.min(#list, favorScroll + fit), #list) or "")

  -- the basket
  local n, need = 0, 0
  for id, q in pairs(cart) do
    local e = shopList[id]
    if e then n = n + q; need = need + e.c * q end
  end
  local missing = math.max(0, need - have)
  if n == 0 then
    bTitle:SetText(L("Your basket is empty", "Din kurv er tom"))
    bSub:SetText(L("Click the things you want: it adds up the favor and what getting it costs.", "Klik på det, du vil have: så lægger den favor sammen, og hvad det koster at skaffe."))
  else
    bTitle:SetText(L("%d in the basket  ·  %d favor", "%d i kurven  ·  %d favor"):format(n, need))
    if missing > 0 then
      local _, got, g = ns.FavorPlan(missing)
      bSub:SetText(L("You need %d more  ·  the cheapest way: %s%s on the auction house", "Du mangler %d  ·  billigste vej: %s%s på AH"):format(
        missing, got < missing and "~" or "", ns.Money(math.max(0, g))) .. (got < missing and L("  (not enough crates scanned)", "  (for få kasser scannet)") or ""))
    else
      bSub:SetText("|cff73d973" .. L("You have the favor for it all. Go buy it.", "Du har favor nok til det hele. Gå ud og køb det.") .. "|r")
    end
  end
  bPlan:SetText(L("Plan it", "Planlæg det"))
  bPlan:SetEnabled(n > 0 and missing > 0)
  bPlan:SetScript("OnClick", function()
    ns.db.favorGoal = need
    win:Hide()
    ns.ToggleHub("favor")
    if ns.RefreshHub then ns.RefreshHub() end
  end)
  bPlan.tip = L("Makes the basket's favor your goal: the Favor page shows the crates and materials to buy.", "Gør kurvens favor til dit mål: Favor-siden viser kasser og mats, du skal købe.")
  bClear:SetText(L("Empty", "Tøm"))
  bClear:SetEnabled(n > 0)
  bClear:SetScript("OnClick", function() wipe(cart); win:Refresh() end)
end
win:SetScript("OnShow", function(self) ns.PlaceSaved(self, "CraftETAFavorShop", "CENTER", UIParent, "CENTER", 0, 0); self:Refresh() end)
function ns.RefreshFavorShop() if win:IsShown() then win:Refresh() end end
local infoPending = false
ns.Register("GET_ITEM_INFO_RECEIVED")
ns.On("GET_ITEM_INFO_RECEIVED", function()
  if win:IsShown() and not infoPending then
    infoPending = true
    C_Timer.After(0.5, function() infoPending = false; win:Refresh() end)
  end
end)
function ns.ToggleFavorShop()
  if win:IsShown() then win:Hide() else win:Show() end
end
-- new prices from a vendor, more favor: the window follows
for _, e in ipairs({ "MERCHANT_SHOW", "CURRENCY_DISPLAY_UPDATE" }) do
  ns.Register(e)
  ns.On(e, function() C_Timer.After(0.6, function() if win:IsShown() then win:Refresh() end end) end)
end

---------------------------------------------------------------------------
-- Buying crates on the auction house: a crate you click in the plan, the cheapest first.
-- A stack (commodity) is bought in one go; single auctions one per click (the game wants a click each).
---------------------------------------------------------------------------
local buy
local function AHOpen() return AuctionHouseFrame and AuctionHouseFrame:IsShown() end

function ns.BuyCrate(id, name, n)
  if not AHOpen() then
    ns.Print(L("Open the auction house to buy crates.", "Åbn auktionshuset for at købe kasser."))
    return
  end
  -- the cheapest auction is found: this click buys it
  if buy and buy.id == id and buy.auction then
    local a = buy.auction
    if GetMoney() < a.price then ns.Print(L("Not enough gold.", "Ikke guld nok.")); return end
    local ok = pcall(C_AuctionHouse.PlaceBid, a.auctionID, a.price)
    if ok then
      ns.Print(L("Bought %s for %s.", "Købte %s for %s."):format(name, ns.Money(a.price)))
      buy.left = buy.left - 1
      buy.auction = nil
    end
    if buy.left > 0 then
      C_Timer.After(0.6, function()
        if buy then pcall(C_AuctionHouse.SendSearchQuery, C_AuctionHouse.MakeItemKey(id), {}, false) end
      end)
    else
      buy = nil
    end
    return
  end
  buy = { id = id, name = name, left = n or 1 }
  ns.Print(L("Looking up %s...", "Slår %s op..."):format(name))
  pcall(C_AuctionHouse.SendSearchQuery, C_AuctionHouse.MakeItemKey(id), {}, false)
end

-- a stack: buy as many as the plan wants, at today's price
ns.Register("COMMODITY_SEARCH_RESULTS_UPDATED")
ns.On("COMMODITY_SEARCH_RESULTS_UPDATED", function(itemID)
  if not buy or itemID ~= buy.id or buy.commodity then return end
  buy.commodity = true
  pcall(C_AuctionHouse.StartCommoditiesPurchase, buy.id, buy.left)
end)
ns.Register("COMMODITY_PRICE_UPDATED")
ns.On("COMMODITY_PRICE_UPDATED", function(unit, total)
  if not buy or not buy.commodity then return end
  if GetMoney() < (total or 0) then ns.Print(L("Not enough gold.", "Ikke guld nok.")); buy = nil; return end
  pcall(C_AuctionHouse.ConfirmCommoditiesPurchase, buy.id, buy.left)
  ns.Print(L("Bought %d %s for %s.", "Købte %d %s for %s."):format(buy.left, buy.name, ns.Money(total or 0)))
  buy = nil
end)

-- single auctions: the cheapest buyout, ready for the next click
ns.Register("ITEM_SEARCH_RESULTS_UPDATED")
ns.On("ITEM_SEARCH_RESULTS_UPDATED", function(itemKey)
  if not buy or buy.commodity or not itemKey or itemKey.itemID ~= buy.id then return end
  local okN, num = pcall(C_AuctionHouse.GetNumItemSearchResults, itemKey)
  local best
  for i = 1, (okN and tonumber(num) or 0) do
    local ok, r = pcall(C_AuctionHouse.GetItemSearchResultInfo, itemKey, i)
    local price = ok and r and Plain(r.buyoutAmount)
    if price and price > 0 and not (r.containsOwnerItem) and (not best or price < best.price) then
      best = { auctionID = r.auctionID, price = price }
    end
  end
  if best then
    buy.auction = best
    ns.Print(L("%s: %s. Click it again to buy (%d to go).", "%s: %s. Klik igen for at købe (%d tilbage)."):format(buy.name, ns.Money(best.price), buy.left))
  else
    ns.Print(L("No %s for sale right now.", "Ingen %s til salg lige nu."):format(buy.name))
    buy = nil
  end
end)
ns.Register("AUCTION_HOUSE_CLOSED")
ns.On("AUCTION_HOUSE_CLOSED", function() buy = nil end)

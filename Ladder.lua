-- CraftETA: what buying a number of something really costs. Every time the auction house shows a
-- commodity (CraftETA's own scan, aux, Auctionator or your own search), the auctions are kept as a price
-- ladder: the cheapest first. 200 of something then costs what the 200 cheapest cost, not 200 times
-- the lowest price.
local _, ns = ...

local FRESH = 2 * 3600      -- a ladder older than this is not used: aux or Auctionator's price instead
local KEEP = 2 * 86400      -- forgotten after two days
local RUNGS = 40

local function Ladders()
  if not ns.db then return nil end
  ns.db.ladder = ns.db.ladder or {}
  return ns.db.ladder
end

ns.Register("COMMODITY_SEARCH_RESULTS_UPDATED")
ns.On("COMMODITY_SEARCH_RESULTS_UPDATED", function(itemID)
  local all = Ladders()
  itemID = ns.Plain and ns.Plain(itemID) or itemID
  if not all or type(itemID) ~= "number" or not C_AuctionHouse then return end
  local ok, n = pcall(C_AuctionHouse.GetNumCommoditySearchResults, itemID)
  if not ok or not n or n == 0 then return end
  local p, total = {}, 0
  for i = 1, n do
    local okR, r = pcall(C_AuctionHouse.GetCommoditySearchResultInfo, itemID, i)
    if okR and r and r.unitPrice and r.quantity then
      local qty = r.quantity - (r.numOwnerItems or 0)      -- your own auctions you can't buy
      if qty > 0 then
        local last = #p
        if last > 0 and p[last - 1] == r.unitPrice then
          p[last] = p[last] + qty
        elseif last < RUNGS * 2 then
          p[last + 1], p[last + 2] = r.unitPrice, qty
        end
        total = total + qty
      end
    end
  end
  if #p == 0 then return end
  local okF, full = pcall(C_AuctionHouse.HasFullCommoditySearchResults, itemID)
  all[itemID] = { t = time(), p = p, total = total, full = okF and full or false }
end)

ns.On("PLAYER_LOGIN", function()
  local all = Ladders()
  if not all then return end
  local now = time()
  for id, l in pairs(all) do
    if not l.t or now - l.t > KEEP then all[id] = nil end
  end
end)

local function Fresh(id)
  local all = Ladders()
  local l = all and id and all[id]
  if l and l.t and time() - l.t < FRESH then return l end
  return nil
end

-- how much price data CraftETA has: { fresh, known, newest } over the ladders and the browse prices
function ns.PriceStats()
  local now, fresh, known, newest = time(), 0, 0, nil
  local seen = {}
  local function Count(id, t)
    if not t or seen[id] then return end
    seen[id] = true
    known = known + 1
    if now - t < FRESH then fresh = fresh + 1 end
    if not newest or t > newest then newest = t end
  end
  for id, l in pairs(Ladders() or {}) do Count(id, l.t) end
  for id, b in pairs(ns.db and ns.db.browse or {}) do if b.p then Count(id, b.t) end end
  return fresh, known, newest, FRESH
end

-- one unit at today's price: a fresh ladder, else the auction addons (Sources.lua: their latest scan,
-- then usual), else CraftETA's own scan
function ns.BuyUnit(name)
  local id = ns.ItemID(name)
  local l = Fresh(id)
  if l then return l.p[1] end
  local b = id and ns.db and ns.db.browse and ns.db.browse[id]
  if b and b.t and time() - b.t < FRESH then return b.p end
  local price = ns.SourcePrice(id, "today")
  if price then return price end
  return ns.Price(name) or (ns.CratePrice and ns.CratePrice(name))
end

-- what `count` cost on the auction house. Second value: "ladder" (from the auctions themselves),
-- "short" (fewer are listed than you need: the rest at the dearest price seen) or "unit" (one price
-- times count)
function ns.BuyCost(name, count)
  if count <= 0 then return 0, "ladder" end
  local l = Fresh(ns.ItemID(name))
  if l then
    local cost, got, p = 0, 0, l.p
    for i = 1, #p, 2 do
      local take = math.min(p[i + 1], count - got)
      cost, got = cost + take * p[i], got + take
      if got >= count then return cost, "ladder" end
    end
    return cost + (count - got) * p[#p - 1], "short"
  end
  local unit = ns.BuyUnit(name)
  if unit then return unit * count, "unit" end
  return nil
end

-- what `count` of a material cost the way you get it: a vendor when Settings say vendor, else the auction
-- house (a vendor's price when nobody sells it there)
function ns.MatCost(name, count)
  local vendor = ns.VendorSells(name) and ns.VendorCost(name)
  if vendor and ns.AtVendor(name) then return vendor * count, "vendor" end
  local cost, how = ns.BuyCost(name, count)
  if cost then return cost, how end
  if vendor then return vendor * count, "vendor" end
  return nil
end

---------------------------------------------------------------------------
-- Quick scan: only what CraftETA uses (the shopping list, the rest of your professions' routes, the favor
-- crates' materials and the crates), one search each. Every answer goes into the price ladders above.
---------------------------------------------------------------------------
local quick       -- { ids = { {id, name} }, i, token, waiting }
local lastScan

local function AHOpen() return AuctionHouseFrame and AuctionHouseFrame:IsShown() end

function ns.QuickScanItems()
  local seen, out = {}, {}
  local function Add(name)
    if not name or seen[name] then return end
    seen[name] = true
    if ns.VendorSells and ns.VendorSells(name) and ns.AtVendor and ns.AtVendor(name) then return end
    local id = ns.ItemID(name)
    if id then out[#out + 1] = { id = id, name = name } end
  end
  for _, item in ipairs(ns.ListItems and ns.ListItems() or {}) do
    if not item.crate then Add(item.name) end
  end
  for profID, s in pairs(ns.Skills()) do
    if ns.GUIDES[profID] and s.rank < 300 then
      local _, mats, names = ns.Plan(profID, s.rank, 300)
      for _, name in ipairs(names or {}) do Add(name) end
    end
  end
  local level = UnitLevel("player") or 1
  local LV = { Apprentice = 10, Journeyman = 10, Expert = 20, Artisan = 35 }
  for _, c in ipairs(ns.CRATES or {}) do
    if level >= (LV[c[1]] or 1) then
      for k = 4, #c do Add(c[k][1]) end
    end
  end
  return out
end

-- step 1: one browse of all Trade Goods (a few pages) gives the lowest price of every material at once.
-- Step 2: only what your shopping list still needs is looked up one by one, for the whole price ladder.
local function Finish(stopped)
  local n = quick and quick.priced or 0
  quick = nil
  if not stopped then
    lastScan = time()
    ns.db.lastQuickScan = lastScan
    if ns.ScanCrates and AHOpen() then ns.ScanCrates() end
    ns.Print(((ns.db.lang == "da") and "Scan færdig: %d priser opdateret." or "Scan done: %d prices updated."):format(n))
  end
  if ns.UpdateScanButton then ns.UpdateScanButton() end
  if ns.Refresh then ns.Refresh() end
  if ns.RefreshHub then ns.RefreshHub() end
end

local function Ready()
  return not (C_AuctionHouse.IsThrottledMessageSystemReady and not C_AuctionHouse.IsThrottledMessageSystemReady())
end

local Next
local function Send()
  if not quick then return end
  if not AHOpen() then Finish(true) return end
  if not Ready() then quick.waiting = true return end      -- AUCTION_HOUSE_THROTTLED_SYSTEM_READY sends it
  quick.waiting = false
  local token = {}
  quick.token = token
  if quick.phase == "browse" then
    if quick.more then
      pcall(C_AuctionHouse.RequestMoreBrowseResults)
    else
      local class = quick.classes[quick.ci]
      pcall(C_AuctionHouse.SendBrowseQuery, { searchString = "", sorts = {}, filters = {}, itemClassFilters = { { classID = class } } })
    end
  else
    local e = quick.deep[quick.i]
    pcall(C_AuctionHouse.SendSearchQuery, C_AuctionHouse.MakeItemKey(e.id), {}, true)
  end
  C_Timer.After(4, function() if quick and quick.token == token then Next() end end)   -- no answer: go on
end
Next = function()
  if not quick then return end
  if quick.phase == "browse" then
    -- the browse is done (or gave up): the deep look-ups
    quick.phase, quick.i = "deep", 0
  end
  quick.i = quick.i + 1
  if ns.UpdateScanButton then ns.UpdateScanButton() end
  if quick.i > #quick.deep then Finish() return end
  Send()
end

-- the browse results: the lowest price of each material we want
local function OnBrowse()
  if not (quick and quick.phase == "browse") then return end
  local ok, results = pcall(C_AuctionHouse.GetBrowseResults)
  ns.db.browse = ns.db.browse or {}
  for _, r in ipairs(ok and results or {}) do
    local id = r.itemKey and ns.Plain(r.itemKey.itemID)
    local price = ns.Plain(r.minPrice)
    if id and quick.want[id] and price and price > 0 and not quick.got[id] then
      quick.got[id] = true
      quick.priced = quick.priced + 1
      ns.db.browse[id] = { p = price, q = ns.Plain(r.totalQuantity) or 0, t = time() }
    end
  end
  if ns.UpdateScanButton then ns.UpdateScanButton() end
  local okF, full = pcall(C_AuctionHouse.HasFullBrowseResults)
  if okF and not full then
    quick.more = true
    Send()
  elseif quick.ci < #quick.classes then
    -- the next kind of item (what you craft: consumables, armor, weapons...)
    quick.ci, quick.more = quick.ci + 1, false
    Send()
  else
    -- what you craft that nobody sells: noted, so the profit page can say "none on the AH"
    for id in pairs(quick.outputs) do
      if not quick.got[id] then ns.db.browse[id] = { q = 0, t = time() } end
    end
    quick.token = nil
    C_Timer.After(0.05, Next)
  end
end
for _, ev in ipairs({ "AUCTION_HOUSE_BROWSE_RESULTS_UPDATED", "AUCTION_HOUSE_BROWSE_RESULTS_ADDED" }) do
  ns.Register(ev)
  ns.On(ev, function() pcall(OnBrowse) end)
end

function ns.QuickScan()
  if quick then Finish(true) return end      -- a second click stops it
  if not AHOpen() then
    ns.Print((ns.db.lang == "da") and "Åbn auktionshuset for at scanne." or "Open the auction house to scan.")
    return
  end
  local want = {}
  for _, e in ipairs(ns.QuickScanItems()) do want[e.id] = e.name end
  -- what your characters craft, and its materials: the profit page's prices. Their kinds of item are
  -- browsed after Trade Goods
  local outputs, classes, seenClass = {}, { (Enum and Enum.ItemClass and Enum.ItemClass.Tradegoods) or 7 }, {}
  seenClass[classes[1]] = true
  for _, r in ipairs(ns.KnownRecipes and ns.KnownRecipes() or {}) do
    outputs[r.o] = true
    want[r.o] = want[r.o] or true
    local mats = r.m or {}
    for i = 1, #mats, 2 do
      local id = ns.ItemID(mats[i])
      if id then want[id] = mats[i] end
    end
    local ok, _, _, _, _, _, class = pcall(GetItemInfoInstant, r.o)
    if ok and class and not seenClass[class] then seenClass[class] = true; classes[#classes + 1] = class end
  end
  -- one by one: only what the shopping list still has to buy on the auction house
  local deep = {}
  for _, item in ipairs(ns.ListItems and ns.ListItems() or {}) do
    local id = ns.ItemID(item.name)
    if id and item.still > 0 and not item.vendor and not item.crate then deep[#deep + 1] = { id = id, name = item.name } end
  end
  quick = { phase = "browse", want = want, got = {}, priced = 0, deep = deep, i = 0, classes = classes, ci = 1, outputs = outputs }
  Send()
end
function ns.QuickScanState()
  if quick then
    if quick.phase == "browse" then return "browse", quick.priced end
    return quick.i, #quick.deep
  end
  return nil, nil, lastScan or (ns.db and ns.db.lastQuickScan)
end

ns.Register("AUCTION_HOUSE_THROTTLED_SYSTEM_READY")
ns.On("AUCTION_HOUSE_THROTTLED_SYSTEM_READY", function() if quick and quick.waiting then Send() end end)
ns.On("COMMODITY_SEARCH_RESULTS_UPDATED", function(itemID)
  local e = quick and quick.phase == "deep" and quick.deep[quick.i]
  if e and ns.Plain(itemID) == e.id then
    if not quick.got[e.id] then quick.got[e.id] = true; quick.priced = quick.priced + 1 end
    quick.token = nil
    C_Timer.After(0.05, Next)
  end
end)
ns.Register("ITEM_SEARCH_RESULTS_UPDATED")
ns.On("ITEM_SEARCH_RESULTS_UPDATED", function(key)
  local e = quick and quick.phase == "deep" and quick.deep[quick.i]
  if e and type(key) == "table" and key.itemID == e.id then quick.token = nil; C_Timer.After(0.05, Next) end
end)
for _, ev in ipairs({ "AUCTION_HOUSE_SHOW", "AUCTION_HOUSE_CLOSED" }) do
  ns.Register(ev)
  ns.On(ev, function()
    if ev == "AUCTION_HOUSE_CLOSED" and quick then quick = nil end
    C_Timer.After(0.1, function() if ns.UpdateScanButton then ns.UpdateScanButton() end end)
  end)
end

-- every recipe your characters know that makes an item (one per item): { o = item, m = mats, y = yield, ... ,
-- char, prof }
function ns.KnownRecipes()
  local seen, out = {}, {}
  for key, c in pairs(ns.db and ns.db.chars or {}) do
    for profID, book in pairs(c.book or {}) do
      for _, r in pairs(book) do
        if r.l and r.o and not seen[r.o] then
          seen[r.o] = true
          out[#out + 1] = setmetatable({ char = c.name or key, charKey = key, prof = profID }, { __index = r })
        end
      end
    end
  end
  return out
end

-- what one sells for now: the auctions (a fresh ladder or the browse), else aux or Auctionator
function ns.SellUnit(id)
  local l = Fresh(id)
  if l then return l.p[1] end
  local b = id and ns.db and ns.db.browse and ns.db.browse[id]
  if b and b.t and time() - b.t < FRESH then
    if b.p then return b.p end
    return nil, "none"            -- browsed lately and nobody sells it
  end
  return ns.PriceID(id)
end
-- how many are for sale, when the scan saw it lately
function ns.SupplyOf(id)
  local l = Fresh(id)
  if l then return l.total end
  local b = id and ns.db and ns.db.browse and ns.db.browse[id]
  if b and b.t and time() - b.t < FRESH then return b.q or 0 end
  return nil
end

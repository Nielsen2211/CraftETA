-- CraftETA: where auction house prices come from. Each auction addon is one small adapter in the list
-- below; CraftETA asks them in order and uses the first real price. Without any of them, CraftETA's own
-- scan is used (Ladder.lua and Core.lua).
--
-- To add an addon: ns.AddPriceSource({ key, name, present, today, usual, search }).
--   present()       true when the addon is loaded and ready to answer
--   installed()     optional: true when it is installed, even before it is ready (shown in Settings)
--   today(id)       price of one now, from its latest scan (copper), or nil
--   usual(id)       its normal price over the last days, or nil
--   search(id,name) optional: search for the item in that addon's window; return true when it did
-- Every call goes through pcall: an addon that changes or breaks never breaks CraftETA.
local ADDON, ns = ...

ns.PRICE_SOURCES = {}

function ns.AddPriceSource(src)
  ns.PRICE_SOURCES[#ns.PRICE_SOURCES + 1] = src
end

local function Loaded(name)
  local f = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
  if not f then return false end
  local ok, loaded = pcall(f, name)
  return ok and loaded and true or false
end
ns.AddonLoaded = Loaded

-- a price only when it is a real positive number
local function Good(fn, ...)
  if type(fn) ~= "function" then return nil end
  local ok, price = pcall(fn, ...)
  price = ok and tonumber(price)
  if price and price > 0 then return math.floor(price + 0.5) end
  return nil
end
ns.GoodPrice = Good

local function Present(src)
  local ok, yes = pcall(src.present)
  return ok and yes and true or false
end

-- the sources you have, in order
function ns.ActiveSources()
  local out = {}
  for _, src in ipairs(ns.PRICE_SOURCES) do
    if Present(src) then out[#out + 1] = src end
  end
  return out
end

-- a price from the auction addons. want = "today" (latest scan first, then usual) or "usual" (usual
-- first, then latest). Second value: the addon's name.
function ns.SourcePrice(id, want)
  if type(id) ~= "number" then return nil end
  for _, src in ipairs(ns.ActiveSources()) do
    local a, b = src.today, src.usual
    if want == "usual" then a, b = b, a end
    local price = Good(a, id) or Good(b, id)
    if price then return price, src.name end
  end
  return nil
end

-- which auction addons you have: "aux", "aux + Auctionator", ... or nil
function ns.AHAddon()
  local names = {}
  for _, src in ipairs(ns.PRICE_SOURCES) do
    local ok, yes = pcall(src.installed or src.present)
    if ok and yes then names[#names + 1] = src.name end
  end
  return #names > 0 and table.concat(names, " + ") or nil
end
-- the addon prices and searches go to first, else "CraftETA"
function ns.AHName()
  local src = ns.ActiveSources()[1]
  return src and src.name or "CraftETA"
end

-- search for an item in the first addon that can
function ns.SourceSearch(itemID, name)
  for _, src in ipairs(ns.ActiveSources()) do
    if type(src.search) == "function" then
      local ok, did = pcall(src.search, itemID, name)
      if ok and did then return true end
    end
  end
  return false
end

---------------------------------------------------------------------------
-- aux (auxForever): its public AuxForeverAPI
---------------------------------------------------------------------------
local function Aux()
  local api = _G.AuxForeverAPI
  if api and type(api.IsReady) == "function" then
    local ok, ready = pcall(api.IsReady)
    if ok and ready then return api end
  end
  return nil
end
function ns.HasAux() return _G.AuxForeverAPI ~= nil or Loaded("auxForever") or Loaded("aux-addon") end

ns.AddPriceSource({
  key = "aux", name = "aux",
  present = function() return Aux() ~= nil end,
  installed = function() return ns.HasAux() end,
  today = function(id) local api = Aux(); return api and Good(api.GetLatestPrice, id) end,
  usual = function(id) local api = Aux(); return api and Good(api.GetUsualPrice, id) end,
  search = function(itemID)
    if not (_G.aux_frame and _G.aux_frame:IsShown() and ns.AuxSearch) then return false end
    ns.AuxSearch(itemID)
    return true
  end,
})

---------------------------------------------------------------------------
-- Auctionator: Auctionator.API.v1, and its price history (allowed by Auctionator)
---------------------------------------------------------------------------
local function Atr() return _G.Auctionator and Auctionator.API and Auctionator.API.v1 end
function ns.HasAuctionator() return Atr() ~= nil or Loaded("Auctionator") end

-- the usual price over its last days, newer days counting more. nil if it isn't there or looks different.
local function AtrUsual(id)
  local db = _G.Auctionator and Auctionator.Database
  if not (db and db.GetPriceHistory) then return nil end
  local ok, hist = pcall(db.GetPriceHistory, db, tostring(id))
  if not ok or type(hist) ~= "table" or #hist == 0 then return nil end
  local days = {}
  for _, e in ipairs(hist) do
    local p = type(e) == "table" and tonumber(e.minSeen or e.price)
    if p and p > 0 then days[#days + 1] = { day = tonumber(e.rawDay) or 0, p = p } end
  end
  if #days == 0 then return nil end
  table.sort(days, function(a, b) return a.day > b.day end)
  local sum, weights = 0, 0
  for i = 1, math.min(7, #days) do
    local w = 8 - i          -- the newest day counts 7 times, the 7th day once
    sum, weights = sum + days[i].p * w, weights + w
  end
  return weights > 0 and math.floor(sum / weights + 0.5) or nil
end

ns.AddPriceSource({
  key = "auctionator", name = "Auctionator",
  present = function() return Atr() ~= nil end,
  installed = function() return ns.HasAuctionator() end,
  today = function(id) local api = Atr(); return api and Good(api.GetAuctionPriceByItemID, ADDON, id) end,
  usual = AtrUsual,
  search = function(itemID, name)
    local api = Atr()
    name = name or (C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(itemID))
    if not (api and api.MultiSearchExact and name) then return false end
    pcall(api.MultiSearchExact, ADDON, { name })
    return true
  end,
})

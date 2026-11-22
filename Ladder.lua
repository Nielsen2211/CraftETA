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

-- one unit at today's price: a fresh ladder, else aux (today, then usual), else Auctionator (its last
-- scan, then its week), else CraftETA's own scan
function ns.BuyUnit(name)
  local id = ns.ItemID(name)
  local l = Fresh(id)
  if l then return l.p[1] end
  local aux = _G.AuxForeverAPI
  if id and aux and aux.IsReady and aux.IsReady() then
    for _, fn in ipairs({ aux.GetLatestPrice, aux.GetUsualPrice }) do
      if type(fn) == "function" then
        local ok, price = pcall(fn, id)
        if ok and type(price) == "number" and price > 0 then return price end
      end
    end
  end
  local atr = _G.Auctionator and Auctionator.API and Auctionator.API.v1
  if id and atr and atr.GetAuctionPriceByItemID then
    local ok, price = pcall(atr.GetAuctionPriceByItemID, "CraftETA", id)
    if ok and type(price) == "number" and price > 0 then return price end
  end
  return ns.Price(name)
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

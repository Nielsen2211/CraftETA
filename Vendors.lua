-- CraftETA: materials a vendor sells (thread, vials, flux, dyes, spices...). On the shopping list they
-- say where to get them, and at a vendor that has them one button buys what the list still needs.
-- Settings: get them at a vendor (default), or buy everything on the auction house.
local _, ns = ...
local T, Plain = ns.T, ns.Plain

local TRADE = "trade"        -- Trade Supplies / General Goods: every capital and most towns
local TAILOR = "tailor"      -- Tailoring and Leatherworking supplies
local ALCH = "alch"          -- Alchemy and Reagent vendors
local SMITH = "smith"        -- Blacksmithing and Mining supplies
local ENCH = "ench"          -- Enchanting supplies
local COOK = "cook"          -- Cooking supplies and innkeepers

ns.VENDOR_ITEMS = {
  ["Coarse Thread"] = TAILOR, ["Fine Thread"] = TAILOR, ["Silken Thread"] = TAILOR,
  ["Heavy Silken Thread"] = TAILOR, ["Rune Thread"] = TAILOR, ["Bleach"] = TAILOR,
  ["Gray Dye"] = TAILOR, ["Red Dye"] = TAILOR, ["Blue Dye"] = TAILOR, ["Green Dye"] = TAILOR, ["Yellow Dye"] = TAILOR,
  ["Salt"] = TAILOR,
  ["Empty Vial"] = ALCH, ["Leaded Vial"] = ALCH, ["Crystal Vial"] = ALCH,
  ["Weak Flux"] = SMITH, ["Strong Flux"] = SMITH,
  ["Copper Rod"] = ENCH, ["Simple Wood"] = ENCH, ["Star Wood"] = ENCH,
  ["Mild Spices"] = COOK, ["Hot Spices"] = COOK, ["Soothing Spices"] = COOK, ["Simple Flour"] = COOK,
  ["Refreshing Spring Water"] = COOK, ["Ice Cold Milk"] = COOK,
}

-- what one costs at a vendor, in copper (the vendor list price; a vendor you have seen wins)
ns.VENDOR_PRICE = {
  ["Coarse Thread"] = 10, ["Fine Thread"] = 100, ["Heavy Silken Thread"] = 2000, ["Rune Thread"] = 5000,
  ["Red Dye"] = 50, ["Blue Dye"] = 50, ["Green Dye"] = 100, ["Yellow Dye"] = 500, ["Salt"] = 50,
  ["Empty Vial"] = 4, ["Leaded Vial"] = 40, ["Crystal Vial"] = 500,
  ["Weak Flux"] = 100, ["Strong Flux"] = 2000, ["Copper Rod"] = 124,
  ["Mild Spices"] = 2, ["Hot Spices"] = 40, ["Soothing Spices"] = 160,
}

-- where, by faction
local WHERE = {
  trade = { h = "Trade Supplies in Orgrimmar, Undercity, Thunder Bluff and most towns",
            a = "Trade Supplies in Stormwind, Ironforge, Darnassus and most towns" },
  tailor = { h = "Tailoring or Leatherworking supplies: Orgrimmar, Undercity, Thunder Bluff, and Trade Supplies in most towns",
             a = "Tailoring or Leatherworking supplies: Stormwind, Ironforge, Darnassus, and Trade Supplies in most towns" },
  alch = { h = "Alchemy or Reagent vendor: Orgrimmar, Undercity, Thunder Bluff",
           a = "Alchemy or Reagent vendor: Stormwind, Ironforge, Darnassus" },
  smith = { h = "Blacksmithing supplies: Orgrimmar, Undercity, Thunder Bluff, and smiths in most towns",
            a = "Blacksmithing supplies: Stormwind, Ironforge, Darnassus, and smiths in most towns" },
  ench = { h = "Enchanting supplies: Orgrimmar, Undercity, Thunder Bluff",
           a = "Enchanting supplies: Stormwind, Ironforge, Darnassus" },
  cook = { h = "Cooking supplies or an innkeeper: every capital and most towns",
           a = "Cooking supplies or an innkeeper: every capital and most towns" },
}

local function Learned(name) return ns.db and ns.db.vendors and ns.db.vendors[name] end

-- a vendor sells it (from the list, or because you have seen one sell it)
function ns.VendorSells(name)
  return ns.VENDOR_ITEMS[name] ~= nil or Learned(name) ~= nil
end

-- get it at a vendor: a vendor sells it, and Settings say vendor
function ns.AtVendor(name)
  return ns.db and ns.db.vendorMode ~= "ah" and ns.VendorSells(name) or false
end

-- what one costs at the vendor: the price you saw there, else the list, else 4 times what a vendor pays
-- (the game's usual mark-up). Second value: true when it is that guess
function ns.VendorCost(name)
  local v = Learned(name)
  if v and v.price then return v.price end
  if ns.VENDOR_PRICE[name] then return ns.VENDOR_PRICE[name] end
  if not ns.VendorSells(name) then return nil end
  local sell = ns.VendorPrice and ns.VendorPrice(ns.ItemID(name))
  return sell and sell * 4 or nil, true
end

-- the price of a material the way you get it: at a vendor when Settings say vendor (or nobody sells it on
-- the auction house), else the auction house
function ns.MatPrice(name)
  local vendor = ns.VendorSells(name) and ns.VendorCost(name)
  if vendor and ns.AtVendor(name) then return vendor end
  return (ns.BuyUnit and ns.BuyUnit(name)) or ns.Price(name) or vendor or nil
end

-- the tooltip lines: where it is sold, and the vendor you last saw it at
function ns.VendorWhere(name)
  local lines = {}
  local v = Learned(name)
  if v and v.npc then
    lines[#lines + 1] = T("vendLast", v.npc, v.zone or "?")
  end
  local kind = ns.VENDOR_ITEMS[name]
  local w = kind and WHERE[kind]
  if w then lines[#lines + 1] = w[ns.Faction()] or w.h end
  return lines
end

---------------------------------------------------------------------------
-- At a vendor: remember what it sells, and buy what the list still needs (the button is in the
-- shopping list, like the buy guide at the auction house: Shop.lua)
---------------------------------------------------------------------------
-- one thing on the vendor: name, copper for one, items per purchase, how many it has left (-1: no limit)
local function MerchantItem(i)
  local name, price, stack, avail
  if C_MerchantFrame and C_MerchantFrame.GetItemInfo then
    local ok, info = pcall(C_MerchantFrame.GetItemInfo, i)
    if ok and type(info) == "table" then
      name, price, stack, avail = info.name, info.price, info.stackCount, info.numAvailable
    end
  end
  if name == nil and GetMerchantItemInfo then
    local ok, n, _, p, st, a = pcall(GetMerchantItemInfo, i)
    if ok then name, price, stack, avail = n, p, st, a end
  end
  name, price, stack, avail = Plain(name), Plain(price), tonumber(Plain(stack)), tonumber(Plain(avail))
  if type(name) ~= "string" and GetMerchantItemLink then
    -- not loaded yet: the name from its link
    local ok, link = pcall(GetMerchantItemLink, i)
    link = ok and Plain(link)
    if type(link) == "string" then name = link:match("%[(.-)%]") end
  end
  if type(name) ~= "string" or type(price) ~= "number" or price <= 0 then return nil end
  stack = math.max(1, stack or 1)
  return name, price / stack, stack, avail or -1
end

local function MerchantItems()
  local out = {}
  local okN, n = pcall(GetMerchantNumItems or function() return 0 end)
  n = okN and tonumber(Plain(n)) or 0
  for i = 1, n do
    local name, unit, stack, avail = MerchantItem(i)
    if name and not out[name] then
      out[name] = { index = i, price = unit, stack = stack, avail = avail }
    end
  end
  return out
end

local function MerchantOpen()
  return MerchantFrame and MerchantFrame:IsShown() and ns.db and true or false
end

-- what bought here is on its way into the bags (a click before the bags update must not buy it twice)
local justBought = {}

-- at an open vendor: what this vendor sells from the list, { name, count, price } with the count it can
-- buy now (stock and gold), the number of items and what it costs
function ns.VendorNeed()
  if not MerchantOpen() then return nil end
  local sold = MerchantItems()
  local need, n, total = {}, 0, 0
  local money = GetMoney and GetMoney() or 0
  for _, item in ipairs(ns.ListItems and ns.ListItems() or {}) do
    local s = sold[item.name]
    local count = s and (item.still - (justBought[item.name] or 0)) or 0
    if count > 0 then
      -- whole purchases: a vendor that sells 5 at a time gets 5, 10, 15...
      local buys = math.ceil(count / s.stack)
      if s.avail >= 0 then buys = math.min(buys, s.avail) end
      local each = s.price * s.stack
      buys = math.min(buys, math.floor((money - total) / math.max(1, each)))
      if buys > 0 then
        local qty = buys * s.stack
        need[#need + 1] = { name = item.name, count = qty, buys = buys, s = s, cost = math.ceil(each * buys) }
        n, total = n + qty, total + math.ceil(each * buys)
      end
    end
  end
  return need, n, total
end

-- buys it (from a click: the vendor wants a hardware event)
function ns.VendorBuy()
  local need = ns.VendorNeed()
  if not need or #need == 0 then return end
  for _, e in ipairs(need) do
    if e.s.stack > 1 then
      -- sold in bundles: one purchase per bundle
      for _ = 1, e.buys do pcall(BuyMerchantItem, e.s.index, 1) end
    else
      local maxStack = (GetMerchantItemMaxStack and tonumber(Plain(GetMerchantItemMaxStack(e.s.index)))) or 20
      maxStack = math.max(1, maxStack)
      local left = e.count
      while left > 0 do
        local take = math.min(left, maxStack)
        pcall(BuyMerchantItem, e.s.index, take)
        left = left - take
      end
    end
    justBought[e.name] = (justBought[e.name] or 0) + e.count
    ns.Print(T("vendBought", e.count, e.name, ns.Money(e.cost)))
  end
  -- the bags tell from here on
  C_Timer.After(3, function() wipe(justBought); if ns.Refresh then ns.Refresh() end end)
  if ns.Refresh then ns.Refresh() end
end

ns.Register("MERCHANT_SHOW")
ns.On("MERCHANT_SHOW", function()
  if not ns.db then return end
  wipe(justBought)
  -- remember who sells what we use
  ns.db.vendors = ns.db.vendors or {}
  local npc = Plain(UnitName("npc"))
  local zone = Plain(GetZoneText and GetZoneText())
  local spot = ns.PlayerSpot and ns.PlayerSpot()   -- for the map arrow (Places.lua)
  local list = {}
  for _, item in ipairs(ns.ListItems and ns.ListItems() or {}) do list[item.name] = true end
  for name, s in pairs(MerchantItems()) do
    if ns.VENDOR_ITEMS[name] or list[name] then
      ns.db.vendors[name] = { npc = npc, zone = zone, price = s.price, spot = spot }
    end
  end
  -- item info can come a moment later: look again then
  C_Timer.After(0.3, function() if ns.OnVendor then ns.OnVendor(true) end end)
end)
ns.Register("MERCHANT_CLOSED")
ns.On("MERCHANT_CLOSED", function() wipe(justBought); if ns.OnVendor then ns.OnVendor(false) end end)
for _, e in ipairs({ "MERCHANT_UPDATE", "BAG_UPDATE_DELAYED" }) do
  ns.Register(e)
  ns.On(e, function()
    if MerchantOpen() then C_Timer.After(0.2, function() if ns.Refresh then ns.Refresh() end end) end
  end)
end

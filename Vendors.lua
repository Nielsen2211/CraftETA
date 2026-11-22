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
-- At a vendor: remember what it sells, and a button that buys what the list needs
---------------------------------------------------------------------------
local button

local function MerchantItems()
  local out = {}
  local n = GetMerchantNumItems and GetMerchantNumItems() or 0
  for i = 1, n do
    local ok, name, _, price, stack = pcall(GetMerchantItemInfo, i)
    if ok and C_MerchantFrame and C_MerchantFrame.GetItemInfo then
      local okI, info = pcall(C_MerchantFrame.GetItemInfo, i)
      if okI and type(info) == "table" then name, price, stack = info.name, info.price, info.stackCount end
    end
    name, price, stack = Plain(name), Plain(price), Plain(stack)
    if type(name) == "string" and type(price) == "number" then
      out[name] = { index = i, price = price / math.max(1, tonumber(stack) or 1), stack = tonumber(stack) or 1 }
    end
  end
  return out
end

local function Needed(sold)
  local need, total = {}, 0
  for _, item in ipairs(ns.ListItems and ns.ListItems() or {}) do
    local s = sold[item.name]
    if s and item.still > 0 and ns.db.vendorMode ~= "ah" then
      need[#need + 1] = { name = item.name, count = item.still, s = s }
      total = total + s.price * item.still
    end
  end
  return need, total
end

local function Update()
  if not button then return end
  if not (MerchantFrame and MerchantFrame:IsShown()) or not ns.db then button:Hide(); return end
  local need, total = Needed(MerchantItems())
  if #need == 0 then button:Hide(); return end
  local n = 0
  for _, e in ipairs(need) do n = n + e.count end
  button:SetText(T("vendBuy", n, ns.Money(math.ceil(total))))
  button.need = need
  button:Show()
end
ns.UpdateVendorButton = Update

local function Buy(self)
  if not self.need or GetMoney() < 1 then return end
  for _, e in ipairs(self.need) do
    local left = e.count
    -- in stack-sized purchases where the vendor sells stacks, else one call per max stack
    local maxStack = (GetMerchantItemMaxStack and GetMerchantItemMaxStack(e.s.index)) or 20
    if e.s.stack > 1 then
      local stacks = math.ceil(left / e.s.stack)
      for _ = 1, stacks do pcall(BuyMerchantItem, e.s.index, 1) end
    else
      while left > 0 do
        local take = math.min(left, maxStack)
        pcall(BuyMerchantItem, e.s.index, take)
        left = left - take
      end
    end
  end
  C_Timer.After(1, Update)
end

ns.Register("MERCHANT_SHOW")
ns.On("MERCHANT_SHOW", function()
  if not ns.db then return end
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
  if not button and MerchantFrame then
    button = ns.Button(MerchantFrame, "", 230, 24)
    button:SetPoint("TOPLEFT", MerchantFrame, "BOTTOMLEFT", 4, -4)
    button:SetScript("OnClick", Buy)
    button.tip = T("vendBuyTip")
  end
  C_Timer.After(0.2, Update)
end)
for _, e in ipairs({ "MERCHANT_UPDATE", "BAG_UPDATE_DELAYED", "MERCHANT_CLOSED" }) do
  ns.Register(e)
  ns.On(e, function() C_Timer.After(0.2, Update) end)
end

-- CraftETA: the shopping list and the buy guide at the auction house.
--
-- The list is made of plans ("Alchemy up to 150"), so it follows you while you craft: what you still
-- need is always the route's materials from your skill now, minus your bags and bank, minus the mail.
--
-- At the auction house: Scan prices looks up every item and works out what buying it all would cost.
-- Then one button buys one item at a time ("Buy 12 Copper Bar"). The game wants a click of yours for
-- every purchase; the price is checked again right before it, and above the estimate it asks first.
local ADDON, ns = ...
local T = ns.T

local WIDTH, ROWS = 360, 14
local S = ns.Window("CraftETAList", WIDTH)
ns.List = S

---------------------------------------------------------------------------
-- The list
---------------------------------------------------------------------------
-- plans: { prof, target } each; skip: items you get yourself
local function Plans()
  ns.db.plans = ns.db.plans or {}
  ns.db.skip = ns.db.skip or {}
  return ns.db.plans
end

function ns.AddToList(mats, order, prof, target)
  local plans = Plans()
  prof = prof or (ns.Panel and ns.db.lastProf)
  if prof and target then
    for _, p in ipairs(plans) do
      if p.prof == prof then p.target = math.max(p.target, target); ns.Refresh(); return end
    end
    plans[#plans + 1] = { prof = prof, target = target }
  else
    ns.db.extra = ns.db.extra or {}
    for _, name in ipairs(order) do
      ns.db.extra[name] = (ns.db.extra[name] or 0) + mats[name]
    end
  end
  if not S:IsShown() then S:Show() end
  ns.Refresh()
end

local function CharKey()
  return (UnitName("player") or "?") .. "-" .. (GetRealmName() or "?")
end

local function MailCount(name)
  local mail = ns.db.mail[CharKey()]
  local pending = ns.db.pending and ns.db.pending[name] or 0
  return (mail and mail[name] or 0) + pending
end
ns.MailCount = MailCount

-- every item on the list: { name, need, have, mail, still }
function ns.ListItems()
  local skills = ns.Skills()
  local total, order = {}, {}
  for _, plan in ipairs(Plans()) do
    local skill = skills[plan.prof]
    local rank = skill and skill.rank or 1
    local _, mats, names = ns.Plan(plan.prof, rank, plan.target)
    for _, name in ipairs(names) do
      if not total[name] then order[#order + 1] = name end
      total[name] = (total[name] or 0) + mats[name]
    end
  end
  for name, count in pairs(ns.db.extra or {}) do
    if not total[name] then order[#order + 1] = name end
    total[name] = (total[name] or 0) + count
  end
  local items = {}
  for _, name in ipairs(order) do
    if not ns.db.skip[name] then
      local have, mail = ns.Have(name), MailCount(name)
      local still = math.max(0, total[name] - have - mail)
      items[#items + 1] = { name = name, need = total[name], have = have, mail = mail, still = still }
    end
  end
  return items
end

function ns.ClearList()
  wipe(Plans())
  ns.db.extra = {}
  wipe(ns.db.skip)
  ns.Refresh()
end

---------------------------------------------------------------------------
-- The window
---------------------------------------------------------------------------
local head = ns.Font(S, true, 10, 0.55, 0.58, 0.64)
head:SetPoint("TOPLEFT", 14, -36)
local headStill = ns.Font(S, true, 10, 0.55, 0.58, 0.64)
headStill:SetPoint("TOPRIGHT", -120, -36)
local headMail = ns.Font(S, true, 10, 0.55, 0.58, 0.64)
headMail:SetPoint("TOPRIGHT", -78, -36)
local headEst = ns.Font(S, true, 10, 0.55, 0.58, 0.64)
headEst:SetPoint("TOPRIGHT", -14, -36)

local rows = {}
for i = 1, ROWS do
  local r = ns.Row(S, 18)
  r:SetWidth(WIDTH - 28)
  r:SetPoint("TOPLEFT", 14, -50 - (i - 1) * 19)
  r.name:ClearAllPoints()
  r.name:SetPoint("LEFT", r.icon, "RIGHT", 6, 0)
  r.name:SetPoint("RIGHT", r, "RIGHT", -150, 0)
  r.still = ns.Font(r, true, 11)
  r.still:SetPoint("RIGHT", r, "RIGHT", -106, 0)
  r.still:SetJustifyH("RIGHT")
  r.mail = ns.Font(r, false, 11, 0.55, 0.7, 1)
  r.mail:SetPoint("RIGHT", r, "RIGHT", -64, 0)
  r.mail:SetJustifyH("RIGHT")
  r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  r:SetScript("OnClick", function(self, button)
    if button == "RightButton" then
      -- you get this one yourself: off the list
      ns.db.skip[self.item] = true
      ns.Refresh()
    elseif self.itemID then
      ns.AHSearch(self.itemID, self.item)
    end
  end)
  r:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if self.itemID then GameTooltip:SetItemByID(self.itemID) else GameTooltip:SetText(self.item or "") end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(T("searchAux") .. "  ·  Right-click: remove", 0.62, 0.6, 0.56)
    GameTooltip:Show()
  end)
  r:SetScript("OnLeave", function() GameTooltip:Hide() end)
  rows[i] = r
end

local emptyText = ns.Font(S, false, 11, 0.55, 0.58, 0.64)
emptyText:SetPoint("TOPLEFT", 14, -56)
local totalText = ns.Font(S, true, 11, 1, 1, 1)
local boughtText = ns.Font(S, false, 10, 0.65, 0.67, 0.72)
local scanButton = ns.Button(S, T("scan"), 96, 22)
local atrButton = ns.Button(S, T("auctionator"), 110, 22)
local clearButton = ns.Button(S, T("clear"), 60, 22)
local buyButton = ns.Button(S, "", WIDTH - 28 - 74, 30)
buyButton.label:SetFont(ns.F_BOLD, 13, "")
local skipButton = ns.Button(S, T("next2"), 68, 30)
local guide = ns.Font(S, false, 10, 0.75, 0.72, 0.6)
guide:SetWordWrap(true)
guide:SetWidth(WIDTH - 28)

clearButton:SetScript("OnClick", function() ns.ClearList() end)
S.buyButton, S.skipButton = buyButton, skipButton

---------------------------------------------------------------------------
-- The auction house
---------------------------------------------------------------------------
local AH = { open = false, queue = {}, skip = {} }
ns.AH = AH

local function Throttled(fn)
  table.insert(AH.queue, fn)
  AH.Pump()
end
function AH.Pump()
  if not AH.open or AH.busy or #AH.queue == 0 then return end
  if C_AuctionHouse.IsThrottledMessageSystemReady and not C_AuctionHouse.IsThrottledMessageSystemReady() then return end
  local fn = table.remove(AH.queue, 1)
  fn()
end

-- the cheapest way to buy `count` of a commodity from the results the game sent
local function CommodityCost(itemID, count)
  local n = C_AuctionHouse.GetNumCommoditySearchResults(itemID) or 0
  local cost, got, unit = 0, 0, nil
  for i = 1, n do
    local r = C_AuctionHouse.GetCommoditySearchResultInfo(itemID, i)
    if r and r.unitPrice and r.quantity then
      unit = unit or r.unitPrice
      local take = math.min(r.quantity, count - got)
      cost = cost + take * r.unitPrice
      got = got + take
      if got >= count then break end
    end
  end
  local available = 0
  for i = 1, n do
    local r = C_AuctionHouse.GetCommoditySearchResultInfo(itemID, i)
    if r and r.quantity then available = available + r.quantity end
  end
  return cost, got, unit, available
end

local scanning   -- { items, index, current }
local function ScanNext()
  if not scanning then return end
  scanning.index = scanning.index + 1
  local item = scanning.items[scanning.index]
  if not item then
    scanning = nil
    ns.Refresh()
    return
  end
  scanning.current = item
  ns.Refresh()
  local token = {}
  scanning.token = token
  C_Timer.After(6, function()
    -- no answer: next item
    if scanning and scanning.token == token then
      ns.db.scanned[item.name] = { t = time(), none = true }
      ScanNext()
    end
  end)
  local id = ns.ItemID(item.name)
  if id then
    Throttled(function()
      scanning.wantID = id
      C_AuctionHouse.SendSearchQuery(C_AuctionHouse.MakeItemKey(id), {}, true)
    end)
  else
    -- the item's ID isn't known yet: find it by name first
    Throttled(function()
      scanning.wantName = item.name
      C_AuctionHouse.SendBrowseQuery({ searchString = item.name, sorts = {}, filters = {}, itemClassFilters = {} })
    end)
  end
end

function ns.ScanPrices()
  if not AH.open then return end
  local items = {}
  for _, item in ipairs(ns.ListItems()) do
    if item.still > 0 then items[#items + 1] = item end
  end
  if #items == 0 then return end
  scanning = { items = items, index = 0 }
  ScanNext()
end
scanButton:SetScript("OnClick", function() ns.ScanPrices() end)
scanButton.tip = "Optional with aux: aux's Full scan already gives the estimate. A scan here reads the exact price for the amount you need."

local function OnBrowse()
  if not scanning or not scanning.wantName then return end
  local name = scanning.wantName
  for _, result in ipairs(C_AuctionHouse.GetBrowseResults() or {}) do
    local key = result.itemKey
    local info = key and C_AuctionHouse.GetItemKeyInfo(key)
    if info and info.itemName == name then
      scanning.wantName = nil
      ns.LearnItem(name, key.itemID)
      Throttled(function()
        scanning.wantID = key.itemID
        C_AuctionHouse.SendSearchQuery(C_AuctionHouse.MakeItemKey(key.itemID), {}, true)
      end)
      return
    end
  end
  if C_AuctionHouse.HasFullBrowseResults and C_AuctionHouse.HasFullBrowseResults() then
    scanning.wantName = nil
    ns.db.scanned[name] = { t = time(), none = true }
    ScanNext()
  end
end

local function OnCommodity(itemID)
  if not scanning or scanning.wantID ~= itemID then return end
  scanning.wantID = nil
  local item = scanning.current
  local cost, got, unit, available = CommodityCost(itemID, item.still)
  ns.db.scanned[item.name] = { t = time(), est = cost, qty = got, unit = unit, avail = available, commodity = true }
  ScanNext()
end

local function OnItemResults(itemKey)
  if not scanning or not itemKey or scanning.wantID ~= itemKey.itemID then return end
  scanning.wantID = nil
  ns.db.scanned[scanning.current.name] = { t = time(), commodity = false }
  ScanNext()
end

-- aux's price from your last Full scan (today's look first, else its usual price): no scan needed here
local function AuxPrice(name)
  local api, id = _G.AuxForeverAPI, ns.ItemID(name)
  if not api or not id or not api.IsReady or not api.IsReady() then return nil end
  local ok, price = pcall(api.GetLatestPrice, id)
  if ok and type(price) == "number" and price > 0 then return price end
  ok, price = pcall(api.GetUsualPrice, id)
  if ok and type(price) == "number" and price > 0 then return price end
  return nil
end
-- aux first, then Auctionator's last scan
local function AuxOrAtrPrice(name)
  local price = AuxPrice(name)
  if price then return price end
  local atr = _G.Auctionator and Auctionator.API and Auctionator.API.v1
  local id = ns.ItemID(name)
  if atr and atr.GetAuctionPriceByItemID and id then
    local ok, p = pcall(atr.GetAuctionPriceByItemID, ADDON, id)
    if ok and type(p) == "number" and p > 0 then return p end
  end
  return nil
end
ns.AuxPrice = AuxOrAtrPrice

-- a stackable item the auction house sells by the unit (or not known yet)
local function Commodity(id)
  local status = C_AuctionHouse.GetItemCommodityStatus and C_AuctionHouse.GetItemCommodityStatus(id)
  local item = Enum and Enum.ItemCommodityStatus and Enum.ItemCommodityStatus.Item
  return not (item and status == item)
end

-- what buying `qty` costs: CraftETA's own scan when there is one, else aux's price
local function Estimate(s, qty, name)
  if s and s.est and s.qty and s.qty > 0 and s.t and time() - s.t < 900 then
    return s.est * qty / s.qty
  end
  local unit = name and AuxOrAtrPrice(name)
  if unit then return unit * qty end
  if s and s.est and s.qty and s.qty > 0 then return s.est * qty / s.qty end
  return nil
end

-- buying: the item the guide is on
local buying   -- { name, id, qty, quote }
local function Current(items)
  for _, item in ipairs(items) do
    local s = ns.db.scanned[item.name]
    local id = ns.ItemID(item.name)
    if item.still > 0 and not AH.skip[item.name] and id then
      local fresh = s and s.t and time() - s.t < 900
      if fresh and s.commodity and (s.avail or 0) > 0 then
        return item, s
      elseif not fresh and AuxOrAtrPrice(item.name) and Commodity(id) then
        return item, nil
      end
    end
  end
  return nil
end

buyButton:SetScript("OnClick", function()
  if buying and buying.quote then
    -- a price above the estimate: this click says yes
    C_AuctionHouse.ConfirmCommoditiesPurchase(buying.id, buying.qty)
    buying.confirming = true
    ns.Refresh()
    return
  end
  if buying then return end
  local item, s = Current(ns.ListItems())
  if not item then return end
  local id = ns.ItemID(item.name)
  if not id then return end
  local qty = math.min(item.still, (s and s.avail) or item.still)
  buying = { name = item.name, id = id, qty = qty }
  -- asks for today's price; the answer is COMMODITY_PRICE_UPDATED
  C_AuctionHouse.StartCommoditiesPurchase(id, qty)
  ns.Refresh()
end)

skipButton:SetScript("OnClick", function()
  if buying then
    if C_AuctionHouse.CancelCommoditiesPurchase then C_AuctionHouse.CancelCommoditiesPurchase() end
    buying = nil
  end
  local item = Current(ns.ListItems())
  if item then AH.skip[item.name] = true end
  ns.Refresh()
end)

local function OnPrice(unitPrice, totalPrice)
  if not buying or buying.confirming then return end
  local est = Estimate(ns.db.scanned[buying.name], buying.qty, buying.name)
  local over = est and est > 0 and (totalPrice - est) / est * 100 or 0
  buying.total, buying.over = totalPrice, over
  if ns.db.autoBuy and est and over <= ns.db.guard then
    buying.confirming = true
    C_AuctionHouse.ConfirmCommoditiesPurchase(buying.id, buying.qty)
  else
    buying.quote = true
  end
  ns.Refresh()
end

local function OnBought()
  if not buying then return end
  local b = buying
  buying = nil
  ns.db.pending = ns.db.pending or {}
  ns.db.pending[b.name] = (ns.db.pending[b.name] or 0) + b.qty
  local session = ns.db.bought
  session.count = (session.count or 0) + 1
  session.cost = (session.cost or 0) + (b.total or 0)
  session.est = (session.est or 0) + (Estimate(ns.db.scanned[b.name], b.qty, b.name) or b.total or 0)
  session.items = session.items or {}
  session.items[b.name] = (session.items[b.name] or 0) + b.qty
  ns.Print(T("boughtMsg", b.qty, b.name, ns.Money(b.total)))
  ns.Refresh()
end

local function OnFailed()
  if not buying then return end
  buying = nil
  ns.Print(T("failed") .. " " .. T("scanHint"))
  ns.Refresh()
end

for event, fn in pairs({
  AUCTION_HOUSE_SHOW = function()
    AH.open = true
    wipe(AH.skip)
    ns.db.bought = {}
    if ns.db.ah and #ns.ListItems() > 0 then
      C_Timer.After(0.2, function() S.byAH = true; S:Show(); ns.PlaceList() end)
      -- a quick look at today's prices of what is on the list (aux's price stands in meanwhile)
      if ns.db.autoScan then
        C_Timer.After(1.5, function()
          if AH.open and not scanning then ns.ScanPrices() end
        end)
      end
    end
  end,
  AUCTION_HOUSE_CLOSED = function()
    AH.open = false
    wipe(AH.queue)
    scanning, buying = nil, nil
    if S.byAH then S.byAH = false; S:Hide() end
  end,
  AUCTION_HOUSE_THROTTLED_SYSTEM_READY = function() AH.Pump() end,
  AUCTION_HOUSE_BROWSE_RESULTS_UPDATED = OnBrowse,
  AUCTION_HOUSE_BROWSE_RESULTS_ADDED = OnBrowse,
  COMMODITY_SEARCH_RESULTS_UPDATED = OnCommodity,
  ITEM_SEARCH_RESULTS_UPDATED = OnItemResults,
  COMMODITY_PRICE_UPDATED = OnPrice,
  COMMODITY_PRICE_UNAVAILABLE = OnFailed,
  COMMODITY_PURCHASE_SUCCEEDED = OnBought,
  COMMODITY_PURCHASE_FAILED = OnFailed,
}) do
  ns.Register(event)
  ns.On(event, fn)
end

---------------------------------------------------------------------------
-- The mailbox: what you bought waits there
---------------------------------------------------------------------------
local function ReadMail()
  if not GetInboxNumItems or not GetInboxItem then return end
  local counts = {}
  local max = ATTACHMENTS_MAX_RECEIVE or 16
  for i = 1, GetInboxNumItems() do
    for a = 1, max do
      local name, itemID, _, count = GetInboxItem(i, a)
      if name and count then
        counts[name] = (counts[name] or 0) + count
        if itemID then ns.LearnItem(name, itemID) end
      end
    end
  end
  ns.db.mail[CharKey()] = counts
  ns.db.pending = {}   -- the mailbox itself tells now
  ns.Refresh()
end
for _, event in ipairs({ "MAIL_INBOX_UPDATE", "MAIL_SHOW" }) do
  ns.Register(event)
  ns.On(event, ReadMail)
end

---------------------------------------------------------------------------
-- aux and Auctionator
---------------------------------------------------------------------------
-- searches for an item at the auction house: in aux when its window is open, else with Auctionator
function ns.AHSearch(itemID, name)
  if _G.aux_frame and _G.aux_frame:IsShown() then return ns.AuxSearch(itemID) end
  local atr = _G.Auctionator and Auctionator.API and Auctionator.API.v1
  name = name or (C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(itemID))
  if atr and atr.MultiSearchExact and name then
    pcall(atr.MultiSearchExact, ADDON, { name })
  end
end

-- searches for an item on aux's Search tab, while aux's window is open
function ns.AuxSearch(itemID)
  local api = _G.AuxForeverAPI
  local frame = _G.aux_frame
  if not api or not frame or not frame:IsShown() or type(getfenv) ~= "function" then return end
  local ok, env = pcall(getfenv, api.GetLatestPrice)
  if not ok or type(env) ~= "table" or type(env.require) ~= "function" then return end
  pcall(function()
    local aux, search = env.require("aux"), env.require("aux.tabs.search")
    aux.set_tab(1)
    search.search_item(itemID)
  end)
end

atrButton:SetScript("OnClick", function()
  local api = _G.Auctionator and Auctionator.API and Auctionator.API.v1
  if not api or not api.CreateShoppingList then return end
  local terms = {}
  for _, item in ipairs(ns.ListItems()) do
    if item.still > 0 then
      local ok, text = pcall(api.ConvertToSearchString, ADDON, { searchString = item.name, isExact = true, quantity = item.still })
      terms[#terms + 1] = ok and text or ('"' .. item.name .. '"')
    end
  end
  if #terms > 0 then
    pcall(api.CreateShoppingList, ADDON, "CraftETA", terms)
    ns.Print(T("auctionatorDone"))
  end
end)

---------------------------------------------------------------------------
-- Drawing
---------------------------------------------------------------------------
function ns.RefreshList()
  if not S:IsShown() or not ns.db then return end
  head:SetText(string.upper(T("item")))
  headStill:SetText(string.upper(T("still")))
  headMail:SetText(string.upper(T("inMail")))
  headEst:SetText(string.upper(T("est")))
  local items = ns.ListItems()
  local total, unknown, shown = 0, false, 0
  for _, item in ipairs(items) do
    if shown < ROWS then
      shown = shown + 1
      local r = rows[shown]
      r.item, r.itemID = item.name, ns.ItemID(item.name)
      r.icon:SetTexture(ns.ItemIcon(item.name))
      r.name:SetText(item.name)
      r.still:SetText(item.still > 0 and ("|cffffffff" .. item.still .. "|r") or "|cff4dcc66✓|r")
      r.mail:SetText(item.mail > 0 and item.mail or "")
      local s = ns.db.scanned[item.name]
      local est
      if item.still > 0 then
        if s and s.commodity and s.qty and s.qty > 0 and s.t and time() - s.t < 900 then
          est = Estimate(s, math.min(item.still, s.qty))
        elseif AuxOrAtrPrice(item.name) then
          est = AuxOrAtrPrice(item.name) * item.still
        elseif ns.Price(item.name) then
          est = ns.Price(item.name) * item.still
        end
      end
      if item.still == 0 then
        r.value:SetText("")
      elseif s and s.none and not AuxOrAtrPrice(item.name) then
        r.value:SetText("|cffe8574a" .. T("notListed") .. "|r")
      elseif s and s.commodity == false then
        r.value:SetText("|cffaaaaaa" .. T("vendor") .. "?|r")
      else
        r.value:SetText(est and ns.Money(est) or ("|cff888888" .. T("unknownPrice") .. "|r"))
      end
      if est then total = total + est elseif item.still > 0 then unknown = true end
      r:Show()
    end
  end
  for i = shown + 1, ROWS do rows[i]:Hide() end
  emptyText:SetShown(#items == 0)
  emptyText:SetText(T("empty"))

  local y = -50 - math.max(1, shown) * 19 - 8
  totalText:ClearAllPoints(); totalText:SetPoint("TOPLEFT", 14, y)
  totalText:SetText(T("total") .. ": " .. ns.Money(total) .. (unknown and "+" or ""))
  y = y - 20

  -- the buy guide, at the auction house
  local atAH = AH.open and ns.db.ah
  scanButton:SetShown(atAH)
  buyButton:SetShown(atAH); skipButton:SetShown(atAH); guide:SetShown(atAH)
  atrButton:SetShown(atAH and _G.Auctionator ~= nil)
  clearButton:ClearAllPoints()
  if atAH then
    scanButton:ClearAllPoints(); scanButton:SetPoint("TOPLEFT", 14, y)
    atrButton:ClearAllPoints(); atrButton:SetPoint("LEFT", scanButton, "RIGHT", 6, 0)
    clearButton:SetPoint("TOPRIGHT", -14, y)
    y = y - 30
    if scanning then
      scanButton:Disable()
      scanButton:SetText(T("scanning", scanning.index, #scanning.items))
    else
      scanButton:Enable()
      scanButton:SetText(T("scan"))
    end
    local item, s = Current(items)
    local text
    if buying and buying.quote then
      buyButton:SetText(T("confirm", ns.Money(buying.total), T("priceUp", math.floor(buying.over + 0.5))))
      buyButton:Enable()
    elseif buying then
      buyButton:SetText("...")
      buyButton:Disable()
    elseif item then
      local qty = math.min(item.still, (s and s.avail) or item.still)
      local est = Estimate(s, qty, item.name)
      buyButton:SetText(T("buy", qty, item.name) .. (est and ("  ≈ " .. ns.Money(est)) or ""))
      buyButton:Enable()
    else
      local anyLeft = false
      for _, it in ipairs(items) do if it.still > 0 then anyLeft = true end end
      buyButton:SetText(anyLeft and T("scan") or T("allBought"))
      buyButton:Disable()
      text = not anyLeft and #items > 0 and T("allBought") or nil
    end
    buyButton:ClearAllPoints(); buyButton:SetPoint("TOPLEFT", 14, y)
    skipButton:ClearAllPoints(); skipButton:SetPoint("LEFT", buyButton, "RIGHT", 6, 0)
    y = y - 38
    local b = ns.db.bought
    if (b.count or 0) > 0 then
      local diff = (b.cost or 0) - (b.est or 0)
      boughtText:SetText(T("bought") .. ": " .. b.count .. "  ·  " .. ns.Money(b.cost)
        .. (diff ~= 0 and ("  (" .. (diff > 0 and "+" or "-") .. ns.Money(math.abs(diff)) .. ")") or ""))
      boughtText:ClearAllPoints(); boughtText:SetPoint("TOPLEFT", 14, y); boughtText:Show()
      y = y - 16
    else
      boughtText:Hide()
    end
    if text then
      guide:SetText(text)
      guide:ClearAllPoints(); guide:SetPoint("TOPLEFT", 14, y)
      y = y - guide:GetStringHeight() - 4
    else
      guide:SetText("")
    end
  else
    boughtText:Hide()
    clearButton:SetPoint("TOPLEFT", 14, y)
    y = y - 30
  end
  S:SetHeight(-y + 18)
end

-- docked to the auction house (aux's window or Blizzard's) while you are there
function ns.PlaceList()
  local aux, blizz = _G.aux_frame, _G.AuctionHouseFrame
  local frame = (aux and aux:IsShown() and aux) or (blizz and blizz:IsShown() and blizz) or nil
  if frame and S.byAH then
    S.docked = true
    S:ClearAllPoints()
    S:SetPoint("TOPLEFT", frame, "TOPRIGHT", 4, 0)
  else
    S.docked = false
    ns.PlaceSaved(S, "CraftETAList", "CENTER", UIParent, "CENTER", -200, 0)
  end
end

S:SetScript("OnShow", function() ns.PlaceList(); ns.RefreshList() end)
S:SetScript("OnHide", function() S.byAH = false end)

function ns.ToggleList()
  if S:IsShown() then S:Hide() else S.byAH = AH.open; S:Show() end
end

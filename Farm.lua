-- CraftETA: the farming tracker. Start it, gather or kill, and see what you got, what it is worth
-- (aux or Auctionator prices, else the vendor) and your gold per hour.
local _, ns = ...
local T, Plain = ns.T, ns.Plain

local F = ns.Window("CraftETAFarm", 270, "|cffffffffFarm|r|cffffd24aETA|r")
ns.FarmWindow = F

local session -- { start, stopped, items = { [id] = count }, money }

local function Elapsed()
  if not session then return 0 end
  return (session.stopped or time()) - session.start
end

local function Value(id, count)
  local price = ns.PriceID(id)
  local vendor = ns.VendorPrice(id)
  local each = price or vendor or 0
  return each * count, price ~= nil
end

-- "You receive loot: [Item]x3." in this client's language
local function Pattern(fmt)
  if type(fmt) ~= "string" then return nil end
  fmt = fmt:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
  fmt = fmt:gsub("%%%%s", "(.+)"):gsub("%%%%d", "(%%d+)")
  return "^" .. fmt .. "$"
end
local LOOT_ONE, LOOT_MANY = Pattern(LOOT_ITEM_SELF), Pattern(LOOT_ITEM_SELF_MULTIPLE)
local PUSH_ONE, PUSH_MANY = Pattern(LOOT_ITEM_PUSHED_SELF), Pattern(LOOT_ITEM_PUSHED_SELF_MULTIPLE)

local function OnLoot(msg)
  if not session or session.stopped then return end
  msg = Plain(msg)
  if type(msg) ~= "string" then return end
  local link, count
  for _, p in ipairs({ LOOT_MANY, PUSH_MANY }) do
    if p and not link then link, count = msg:match(p) end
  end
  for _, p in ipairs({ LOOT_ONE, PUSH_ONE }) do
    if p and not link then link = msg:match(p); count = 1 end
  end
  local id = link and tonumber(link:match("item:(%d+)"))
  if not id then return end
  session.items[id] = (session.items[id] or 0) + (tonumber(count) or 1)
  ns.RefreshFarm()
end
ns.Register("CHAT_MSG_LOOT")
ns.On("CHAT_MSG_LOOT", OnLoot)

local lastMoney
ns.Register("PLAYER_MONEY")
ns.On("PLAYER_MONEY", function()
  local now = Plain(GetMoney())
  if session and not session.stopped and lastMoney and now and now > lastMoney then
    session.money = session.money + (now - lastMoney)
    ns.RefreshFarm()
  end
  lastMoney = now
end)

function ns.FarmStart()
  session = { start = time(), items = {}, money = 0 }
  lastMoney = Plain(GetMoney())
  F:Show()
  ns.RefreshFarm()
end
function ns.FarmStop()
  if session and not session.stopped then session.stopped = time() end
  ns.RefreshFarm()
end
function ns.FarmActive() return session ~= nil and not session.stopped end
function ns.ToggleFarm()
  if ns.FarmActive() then ns.FarmStop() else ns.FarmStart() end
end

-- the window
local timeText = ns.Font(F, true, 20, 1, 1, 1)
timeText:SetPoint("TOPLEFT", 14, -38)
local perHour = ns.Font(F, true, 13, 1, 0.82, 0.3)
perHour:SetPoint("TOPRIGHT", -14, -40)
perHour:SetJustifyH("RIGHT")
local totalText = ns.Font(F, false, 11, 0.7, 0.72, 0.76)
totalText:SetPoint("TOPLEFT", timeText, "BOTTOMLEFT", 0, -4)
totalText:SetPoint("RIGHT", F, "RIGHT", -14, 0)

local startButton = ns.Button(F, "", 110, 22)
startButton:SetPoint("TOPLEFT", 14, -86)
startButton:SetScript("OnClick", function() ns.ToggleFarm() end)
local resetButton = ns.Button(F, "", 110, 22)
resetButton:SetPoint("LEFT", startButton, "RIGHT", 8, 0)
resetButton:SetScript("OnClick", function() ns.FarmStart() end)

local rows = {}
local function Row(i)
  local r = rows[i]
  if r then return r end
  r = ns.Row(F, 18)
  r:SetWidth(242)
  r:SetScript("OnEnter", function(self)
    if not self.id then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetItemByID(self.id)
    GameTooltip:Show()
  end)
  r:SetScript("OnLeave", function() GameTooltip:Hide() end)
  rows[i] = r
  return r
end
local empty = ns.Font(F, false, 11, 0.55, 0.58, 0.64)
empty:SetPoint("TOPLEFT", 14, -122)
empty:SetWidth(242)

local ticker
function ns.RefreshFarm()
  if not F:IsShown() then return end
  local secs = Elapsed()
  timeText:SetText(("%d:%02d:%02d"):format(secs / 3600, secs / 60 % 60, secs % 60))
  startButton:SetText(ns.FarmActive() and T("farmStop") or T("farmStart"))
  resetButton:SetText(T("farmReset"))
  resetButton:SetShown(session ~= nil)
  local list, total, guess = {}, session and session.money or 0, false
  for id, count in pairs(session and session.items or {}) do
    local value, priced = Value(id, count)
    total = total + value
    if not priced then guess = true end
    list[#list + 1] = { id = id, count = count, value = value }
  end
  table.sort(list, function(a, b) return a.value > b.value end)
  local hours = secs / 3600
  perHour:SetText(secs >= 60 and (ns.Money(total / hours) .. "|cff8c8f96/h|r") or "")
  totalText:SetText(T("farmTotal", ns.Money(total)) .. (session and session.money > 0 and ("  ·  " .. T("farmMoney", ns.Money(session.money))) or "")
    .. (guess and ("  |cff8c8f96" .. T("farmVendor") .. "|r") or ""))
  local y = -122
  for i, e in ipairs(list) do
    if i > 14 then break end
    local r = Row(i)
    local okI, _, _, _, _, icon = pcall(C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant, e.id)
    local name = (C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(e.id)) or ("item " .. e.id)
    r.id = e.id
    r:ClearAllPoints(); r:SetPoint("TOPLEFT", 14, y)
    r.icon:SetTexture(okI and icon or 134400)
    r.name:SetText(("%s |cff8c8f96x%d|r"):format(name, e.count))
    r.value:SetText(ns.Money(e.value))
    r:Show()
    y = y - 20
  end
  for i = math.min(#list, 14) + 1, #rows do rows[i]:Hide() end
  empty:SetShown(#list == 0)
  empty:SetText(session and T("farmWaiting") or T("farmHint"))
  if #list == 0 then y = y - 36 end
  F:SetHeight(-y + 16)
end

F:SetScript("OnShow", function()
  ns.PlaceSaved(F, "CraftETAFarm", "RIGHT", UIParent, "RIGHT", -220, -120)
  if not ticker then ticker = C_Timer.NewTicker(1, function() if F:IsShown() and ns.FarmActive() then ns.RefreshFarm() end end) end
  ns.RefreshFarm()
end)

function ns.ToggleFarmWindow()
  if F:IsShown() then F:Hide() else F:Show() end
end

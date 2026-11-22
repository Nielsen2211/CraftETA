-- CraftETA: character facts for Home and Alts (durability, bags, time played), profession cooldowns,
-- the gathering tracking reminder and the item tracker.
local _, ns = ...
local T, Plain = ns.T, ns.Plain

---------------------------------------------------------------------------
-- Character facts
---------------------------------------------------------------------------
function ns.Durability()
  local cur, max = 0, 0
  for slot = 1, 19 do
    local ok, c, m = pcall(GetInventoryItemDurability, slot)
    c, m = ok and Plain(c), ok and Plain(m)
    if type(c) == "number" and type(m) == "number" and m > 0 then
      cur, max = cur + c, max + m
    end
  end
  if max == 0 then return 1 end
  return cur / max
end

function ns.BagSpace()
  local free, total = 0, 0
  local C = C_Container
  for bag = 0, 4 do
    local okS, slots = pcall(C and C.GetContainerNumSlots or GetContainerNumSlots, bag)
    local okF, nfree = pcall(C and C.GetContainerNumFreeSlots or GetContainerNumFreeSlots, bag)
    if okS and type(Plain(slots)) == "number" then total = total + slots end
    if okF and type(Plain(nfree)) == "number" then free = free + nfree end
  end
  return free, total
end

function ns.HasSpell(id)
  if IsPlayerSpell then
    local ok, known = pcall(IsPlayerSpell, id)
    if ok and known then return true end
  end
  if IsSpellKnown then
    local ok, known = pcall(IsSpellKnown, id)
    if ok and known then return true end
  end
  return false
end

local function SpellName(id)
  if C_Spell and C_Spell.GetSpellName then
    local ok, name = pcall(C_Spell.GetSpellName, id)
    if ok and name then return Plain(name) end
  end
  if GetSpellInfo then
    local ok, name = pcall(GetSpellInfo, id)
    if ok and name then return Plain(name) end
  end
  return nil
end
ns.SpellName = SpellName

-- time played: asked once a session, without the chat line
local askedPlayed
function ns.AskPlayed()
  if askedPlayed or not RequestTimePlayed then return end
  askedPlayed = true
  ns.hidePlayed = true
  pcall(RequestTimePlayed)
  C_Timer.After(10, function() ns.hidePlayed = false end)
end
ns.Register("TIME_PLAYED_MSG")
ns.On("TIME_PLAYED_MSG", function(total, level)
  if ns.hidePlayed then C_Timer.After(0.5, function() ns.hidePlayed = false end) end
  local c = ns.Me()
  if c then
    c.played, c.playedLevel, c.playedAt = Plain(total), Plain(level), time()
  end
  if ns.RefreshHub then ns.RefreshHub() end
end)
ns.On("PLAYER_LOGIN", function()
  -- the chat line "Total time played" only when you typed /played yourself
  local original = _G.ChatFrame_DisplayTimePlayed
  if type(original) == "function" then
    _G.ChatFrame_DisplayTimePlayed = function(...)
      if ns.hidePlayed then return end
      return original(...)
    end
  end
  local util = _G.ChatFrameUtil
  if type(util) == "table" and type(util.DisplayTimePlayed) == "function" then
    local utilOriginal = util.DisplayTimePlayed
    util.DisplayTimePlayed = function(...)
      if ns.hidePlayed then return end
      return utilOriginal(...)
    end
  end
  C_Timer.After(5, ns.AskPlayed)
end)

function ns.Played(c)
  if not c or not c.played then return nil end
  local extra = c.playedAt and (c == ns.Me() and (time() - c.playedAt) or 0) or 0
  return c.played + extra
end

function ns.PlayedText(seconds)
  if not seconds then return "?" end
  local d, h, m = math.floor(seconds / 86400), math.floor(seconds / 3600) % 24, math.floor(seconds / 60) % 60
  if d > 0 then return ("%dd %dh"):format(d, h) end
  return ("%dh %dm"):format(h, m)
end

-- what else Alts shows
local function Facts()
  local c = ns.Me()
  if not c then return end
  local okR, race = pcall(UnitRace, "player")
  c.race = okR and Plain(race) or c.race
  local okZ, zone = pcall(GetRealZoneText)
  c.zone = okZ and Plain(zone) or c.zone
  c.xp, c.xpMax = Plain(UnitXP("player")), Plain(UnitXPMax("player"))
  c.rested = Plain(GetXPExhaustion and GetXPExhaustion() or 0)
  local free, total = ns.BagSpace()
  c.bags, c.bagsTotal = free, total
  c.dura = ns.Durability()
end
ns.Facts = Facts
for _, e in ipairs({ "PLAYER_LOGIN", "ZONE_CHANGED_NEW_AREA", "PLAYER_XP_UPDATE", "PLAYER_LOGOUT", "BAG_UPDATE_DELAYED", "UPDATE_INVENTORY_DURABILITY" }) do
  ns.Register(e)
  ns.On(e, function() Facts(); if ns.RefreshHome then ns.RefreshHome() end end)
end

---------------------------------------------------------------------------
-- Profession cooldowns (Transmute, Mooncloth, Salt Shaker): when each character's is ready
---------------------------------------------------------------------------
local function Cooldown(entry)
  if entry.item then
    local count = (C_Item and C_Item.GetItemCount or GetItemCount)(entry.item)
    if not count or count == 0 then return nil end
    local get = (C_Container and C_Container.GetItemCooldown) or GetItemCooldown
    local ok, start, dur = pcall(get, entry.item)
    if ok then return Plain(start) or 0, Plain(dur) or 0 end
    return nil
  end
  for _, id in ipairs(entry[2]) do
    if ns.HasSpell(id) then
      if C_Spell and C_Spell.GetSpellCooldown then
        local ok, info = pcall(C_Spell.GetSpellCooldown, id)
        if ok and type(info) == "table" then return Plain(info.startTime) or 0, Plain(info.duration) or 0, id end
      elseif GetSpellCooldown then
        local ok, start, dur = pcall(GetSpellCooldown, id)
        if ok then return Plain(start) or 0, Plain(dur) or 0, id end
      end
    end
  end
  return nil
end

function ns.ReadCooldowns()
  local c = ns.Me()
  if not c then return end
  c.cd = c.cd or {}
  for _, entry in ipairs(ns.COOLDOWNS) do
    local start, dur = Cooldown(entry)
    if start then
      -- a global cooldown (1.5 s) is not the real one
      local left = (dur > 2 and start > 0) and (start + dur - GetTime()) or 0
      local was = c.cd[entry[1]]
      local now = time()
      local ready = now + math.max(0, left)
      -- the game sometimes answers 0 while the cooldown runs (the global cooldown, a hidden value):
      -- a cooldown we know is still running stays as it is
      if left <= 0 and was and was.ready > now + 5 then ready = was.ready end
      local told
      if not was then
        told = ready <= now or nil              -- seen ready the first time: nothing to tell
      elseif ready > was.ready + 60 then
        told = nil                              -- a new cooldown started: tell once when it is ready
      else
        told = was.told                         -- the same cooldown: told stays told
      end
      c.cd[entry[1]] = { ready = ready, told = told }
    else
      c.cd[entry[1]] = nil
    end
  end
end
for _, e in ipairs({ "PLAYER_LOGIN", "SPELL_UPDATE_COOLDOWN", "BAG_UPDATE_COOLDOWN", "TRADE_SKILL_SHOW" }) do
  ns.Register(e)
  ns.On(e, function() pcall(ns.ReadCooldowns) end)
end

-- tells you once when a cooldown on any of your characters is ready
local function CheckReady()
  if not ns.db or not ns.db.cdAlert then return end
  local now = time()
  for key, c in pairs(ns.db.chars) do
    for name, cd in pairs(c.cd or {}) do
      if cd.ready <= now and not cd.told then
        cd.told = true
        ns.Print(T("cdReady", name, c.name or key))
      end
    end
  end
end
ns.On("PLAYER_LOGIN", function()
  C_Timer.After(8, function()
    -- at login, cooldowns that were already ready before don't need telling again
    CheckReady()
    C_Timer.NewTicker(30, CheckReady)
  end)
end)

---------------------------------------------------------------------------
-- Gathering tracking reminder: "Find Minerals is off"
---------------------------------------------------------------------------
local TRACK = { { prof = 186, spell = 2580 }, { prof = 182, spell = 2383 } }

local function TrackingActive()
  if C_Minimap and C_Minimap.GetNumTrackingTypes and C_Minimap.GetTrackingInfo then
    local ok, n = pcall(C_Minimap.GetNumTrackingTypes)
    if ok and type(n) == "number" then
      local found = {}
      for i = 1, n do
        local okI, a, b, c = pcall(C_Minimap.GetTrackingInfo, i)
        if okI then
          local name, active = a, c
          if type(a) == "table" then name, active = a.name, a.active end
          if Plain(name) and Plain(active) then found[name] = true end
        end
      end
      return found
    end
  end
  local found = {}
  if GetTrackingTexture then
    local ok, tex = pcall(GetTrackingTexture)
    if ok and tex then found.texture = tex end
  end
  return found
end

local banner
local function Banner()
  if banner then return banner end
  local b = CreateFrame("Frame", "CraftETATrackBanner", UIParent)
  b:SetSize(520, 34)
  -- below the top bars (LevelETA and others); drag it where you want it
  ns.PlaceSaved(b, "CraftETATrackBanner", "TOP", UIParent, "TOP", 0, -130)
  b:SetFrameStrata("MEDIUM")
  b:SetClampedToScreen(true)
  b:SetMovable(true)
  b:EnableMouse(true)
  b:RegisterForDrag("LeftButton")
  b:SetScript("OnDragStart", b.StartMoving)
  b:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    ns.db.point_CraftETATrackBanner = { self:GetLeft(), self:GetTop() }
  end)
  local bg = b:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetColorTexture(0.06, 0.065, 0.08, 0.94)
  local line = b:CreateTexture(nil, "BORDER")
  line:SetPoint("BOTTOMLEFT"); line:SetPoint("BOTTOMRIGHT"); line:SetHeight(2)
  line:SetColorTexture(1, 0.82, 0.3, 0.9)
  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetSize(22, 22)
  b.icon:SetPoint("LEFT", 8, 0)
  b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  b.text = ns.Font(b, false, 12)
  b.text:SetPoint("LEFT", b.icon, "RIGHT", 10, 0)
  -- the game only lets a click cast a spell through a secure button
  local on = CreateFrame("Button", nil, b, "SecureActionButtonTemplate")
  on:SetSize(84, 22)
  on:SetPoint("RIGHT", -34, 0)
  on:RegisterForClicks("AnyUp", "AnyDown")
  on:SetAttribute("type", "spell")
  local onBg = on:CreateTexture(nil, "BACKGROUND")
  onBg:SetAllPoints()
  onBg:SetColorTexture(1, 0.82, 0.3, 0.9)
  local onText = ns.Font(on, true, 11, 0.08, 0.08, 0.1)
  onText:SetPoint("CENTER")
  onText:SetShadowOffset(0, 0)
  b.on, b.onText = on, onText
  local close = CreateFrame("Button", nil, b)
  close:SetSize(20, 20)
  close:SetPoint("RIGHT", -8, 0)
  local x = ns.Font(close, true, 14, 0.6, 0.62, 0.68)
  x:SetPoint("CENTER"); x:SetText("×")
  close:SetScript("OnClick", function() ns.trackDismissed = true; b:Hide() end)
  b:Hide()
  banner = b
  return b
end

function ns.UpdateTrackBanner()
  if InCombatLockdown and InCombatLockdown() then return end
  if not ns.db then return end
  local b = Banner()
  if not ns.db.trackReminder or ns.trackDismissed or UnitIsDeadOrGhost("player") then b:Hide() return end
  local active = TrackingActive()
  local want
  for _, t in ipairs(TRACK) do
    local name = SpellName(t.spell)
    if name and ns.HasSpell(t.spell) then
      if active[name] then b:Hide() return end
      if active.texture then
        local okT, tex = pcall(C_Spell and C_Spell.GetSpellTexture or GetSpellTexture, t.spell)
        if okT and tex == active.texture then b:Hide() return end
      end
      want = want or { spell = t.spell, name = name }
    end
  end
  if not want then b:Hide() return end
  local okT, tex = pcall(C_Spell and C_Spell.GetSpellTexture or GetSpellTexture, want.spell)
  b.icon:SetTexture(okT and tex or 136025)
  b.text:SetText(("|cffffd24a" .. T("trackOff") .. "|r  " .. T("trackHint")):format(want.name))
  b.on:SetAttribute("spell", want.name)
  b.onText:SetText(T("turnOn"))
  b:Show()
end
for _, e in ipairs({ "PLAYER_ENTERING_WORLD", "MINIMAP_UPDATE_TRACKING", "PLAYER_REGEN_ENABLED", "PLAYER_ALIVE", "PLAYER_UNGHOST", "SKILL_LINES_CHANGED" }) do
  ns.Register(e)
  ns.On(e, function() C_Timer.After(0.5, ns.UpdateTrackBanner) end)
end

---------------------------------------------------------------------------
-- Item tracker: a small window with items you are collecting, and how close you are
---------------------------------------------------------------------------
local TR = ns.Window("CraftETATracker", 230, "|cffffffffItem|r |cffffd24atracker|r")
ns.Tracker = TR
local trRows = {}
local trEmpty = ns.Font(TR, false, 11, 0.55, 0.58, 0.64)
trEmpty:SetPoint("TOPLEFT", 14, -40)
trEmpty:SetWidth(202)
local function TrRow(i)
  local r = trRows[i]
  if r then return r end
  r = ns.Row(TR, 18)
  r:SetWidth(202)
  r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  r:EnableMouseWheel(true)
  r.bar = r:CreateTexture(nil, "BACKGROUND")
  r.bar:SetPoint("BOTTOMLEFT", r.icon, "BOTTOMRIGHT", 4, -1)
  r.bar:SetHeight(2)
  r.bar:SetColorTexture(1, 0.82, 0.3, 0.8)
  r:SetScript("OnClick", function(self, which)
    if which == "RightButton" then
      ns.db.track[self.itemName] = nil
      ns.RefreshTracker()
    end
  end)
  r:SetScript("OnMouseWheel", function(self, delta)
    local goal = ns.db.track[self.itemName]
    if goal then
      ns.db.track[self.itemName] = math.max(1, goal + delta * 5)
      ns.RefreshTracker()
    end
  end)
  r:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    local id = ns.ItemID(self.itemName)
    if id then GameTooltip:SetItemByID(id) else GameTooltip:SetText(self.itemName) end
    GameTooltip:AddLine(T("trackerHint"), 0.55, 0.58, 0.64, true)
    GameTooltip:Show()
  end)
  r:SetScript("OnLeave", function() GameTooltip:Hide() end)
  trRows[i] = r
  return r
end

function ns.RefreshTracker()
  if not ns.db then return end
  if not TR:IsShown() then return end
  local names = {}
  for name in pairs(ns.db.track) do names[#names + 1] = name end
  table.sort(names)
  local y = -38
  for i, name in ipairs(names) do
    local r = TrRow(i)
    local goal, have = ns.db.track[name], ns.Have(name)
    r.itemName = name
    r:ClearAllPoints()
    r:SetPoint("TOPLEFT", 14, y)
    r.icon:SetTexture(ns.ItemIcon(name))
    r.name:SetText(name)
    local done = have >= goal
    r.value:SetText(("%d/%d"):format(have, goal))
    r.value:SetTextColor(done and 0.35 or 1, done and 0.9 or 1, done and 0.4 or 1)
    r.bar:SetWidth(math.max(1, 180 * math.min(1, have / goal)))
    r:Show()
    y = y - 22
  end
  for i = #names + 1, #trRows do trRows[i]:Hide() end
  if #names == 0 then
    trEmpty:SetText(T("trackerEmpty"))
    trEmpty:Show()
    y = y - 40
  else
    trEmpty:Hide()
  end
  TR:SetHeight(-y + 14)
end
TR:SetScript("OnShow", function()
  ns.PlaceSaved(TR, "CraftETATracker", "RIGHT", UIParent, "RIGHT", -220, 60)
  ns.RefreshTracker()
end)
ns.Register("BAG_UPDATE_DELAYED")
ns.On("BAG_UPDATE_DELAYED", function() ns.RefreshTracker() end)

function ns.ToggleTracker()
  if TR:IsShown() then TR:Hide() else TR:Show() end
end

function ns.TrackItem(name, goal)
  if not name or not ns.db then return end
  if ns.db.track[name] then
    ns.db.track[name] = nil
  else
    ns.db.track[name] = goal or 20
    TR:Show()
  end
  ns.RefreshTracker()
end

ns.On("ADDON_LOADED", function(name)
  if name ~= "CraftETA" then return end   -- only when CraftETA itself has loaded
  ns.db.track = ns.db.track or {}
  if ns.db.cdAlert == nil then ns.db.cdAlert = true end
  if ns.db.trackReminder == nil then ns.db.trackReminder = true end
end)

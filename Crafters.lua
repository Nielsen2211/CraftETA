-- CraftETA: the Crafters page. On the left everyone who can craft for you (your own characters,
-- guild members with CraftETA, and players advertising in trade chat), with a search over player,
-- profession, recipe and item. On the right the crafter you picked: professions, recipes, advert.
local _, ns = ...
local T = ns.T

local H, X, CW = ns.Hub, ns.HUB_X, ns.HUB_CW
local Card = ns.Card

local page = CreateFrame("Frame", nil, H)
page:SetPoint("TOPLEFT", X, -20)
page:SetPoint("BOTTOMRIGHT", -18, 16)
page:Hide()
ns.HubCustom.crafters = page

local PAD, ROW_H, GAP = 12, 50, 12
local LW = math.floor(CW * 0.58)
local RW = CW - LW - GAP
local TRADE_FRESH = 15 * 60   -- an advert this new counts as "online"

local picked, offset = nil, 0

local function Upper(s) return string.upper(s or "") end
local function Low(s) return type(s) == "string" and string.lower(s) or "" end
local function Short(name) return type(name) == "string" and (string.match(name, "^[^-]+") or name) or "?" end
local function ClassColor(class)
  local c = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
  if c then return c.r, c.g, c.b end
  return 0.92, 0.93, 0.95
end
local function Ago(t)
  local s = math.max(0, time() - (t or time()))
  if s < 3600 then return math.max(1, math.floor(s / 60)) .. " min" end
  if s < 86400 then return math.floor(s / 3600) .. " h" end
  return math.floor(s / 86400) .. " d"
end

---------------------------------------------------------------------------
-- Who: one entry per player, from all three sources
---------------------------------------------------------------------------
local function GuildRoster()
  local out = {}
  if not (IsInGuild and IsInGuild() and GetNumGuildMembers and GetGuildRosterInfo) then return out end
  local n = GetNumGuildMembers() or 0
  for i = 1, n do
    local ok, name, _, _, level, _, zone, _, _, online, _, classFile = pcall(GetGuildRosterInfo, i)
    name = ok and ns.Plain(name)
    if type(name) == "string" then
      out[name] = { level = ns.Plain(level), zone = ns.Plain(zone), online = ns.Plain(online) and true or false, class = ns.Plain(classFile) }
      out[Short(name)] = out[name]
    end
  end
  return out
end

local function People()
  local list, byKey = {}, {}
  local roster = GuildRoster()
  local meKey = ns.CharKey and ns.CharKey()
  -- your own characters are not crafters you need to find: leave them out
  local mine = {}
  for key, c in pairs(ns.db.chars or {}) do
    mine[Low(Short(key))] = true
    if c.name then mine[Low(c.name)] = true end
  end
  -- guild members with CraftETA
  for sender, g in pairs(ns.guildPeers or {}) do
   if not mine[Low(Short(sender))] then
    local r = roster[sender] or roster[Short(sender)] or {}
    local p = { key = sender, name = Short(sender), whisper = sender, class = g.class or r.class, level = g.level or r.level,
      profs = g.profs or {}, recipes = {}, source = "guild", online = r.online, zone = r.zone, seen = g.seen }
    for name, prof in pairs(g.recipes or {}) do p.recipes[name] = { prof = prof ~= true and prof or nil } end
    list[#list + 1] = p; byKey[sender] = p
   end
  end
  -- trade chat adverts
  for _, a in ipairs(ns.Adverts and ns.Adverts() or {}) do
    local p = byKey[a.sender]
    if mine[Low(a.short)] then
      -- one of your own characters
    elseif p then
      p.ad, p.adAt = a.text, a.t
    else
      local r = roster[a.sender] or roster[a.short] or {}
      p = { key = a.sender, name = a.short, whisper = a.sender, class = r.class, level = r.level, profs = {}, recipes = {},
        source = "trade", ad = a.text, adAt = a.t, online = time() - a.t <= TRADE_FRESH, zone = r.zone }
      list[#list + 1] = p; byKey[a.sender] = p
    end
  end
  -- what your guild answered to a search
  for _, res in ipairs(ns.crafterResults or {}) do
    if res.sender and byKey[res.sender] then
      byKey[res.sender].recipes[res.recipe] = byKey[res.sender].recipes[res.recipe] or { prof = res.prof }
    end
  end
  return list
end

-- does this player match the search, and on what (for the info line)
local GetItemNameByID = C_Item and C_Item.GetItemNameByID
local function ItemName(id)
  if not id then return nil end
  local ok, n = pcall(GetItemNameByID or GetItemInfo, id)
  return ok and ns.Plain(n) or nil
end
local function Match(p, q)
  if q == "" then return true end
  if string.find(Low(p.name), q, 1, true) then return true end
  for prof in pairs(p.profs) do
    if string.find(Low(prof), q, 1, true) then return true end
  end
  for name, r in pairs(p.recipes) do
    if string.find(Low(name), q, 1, true) or string.find(Low(ItemName(r.item)), q, 1, true) then return true, name end
  end
  if p.ad and string.find(Low(p.ad), q, 1, true) then return true end
  return false
end

local ORDER = { mine = 1, guild = 2, trade = 3 }
local function Sorted(q)
  local out = {}
  for _, p in ipairs(People()) do
    local ok, hit = Match(p, q)
    if ok then p.hit = hit; out[#out + 1] = p end
  end
  table.sort(out, function(a, b)
    if (a.online and true or false) ~= (b.online and true or false) then return a.online and true or false end
    if ORDER[a.source] ~= ORDER[b.source] then return ORDER[a.source] < ORDER[b.source] end
    return Low(a.name) < Low(b.name)
  end)
  return out
end

local function ProfLine(p)
  local parts = {}
  for prof, skill in pairs(p.profs) do parts[#parts + 1] = { prof, skill } end
  table.sort(parts, function(a, b) return (a[2] or 0) > (b[2] or 0) end)
  for i, e in ipairs(parts) do parts[i] = e[1] .. " |cffffd24a" .. (e[2] or 0) .. "|r" end
  return table.concat(parts, "   ")
end

local function Clean(text)
  text = (text or ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|H.-|h(.-)|h", "%1")
  return text
end

local function Invite(who)
  if not who then return end
  if C_PartyInfo and C_PartyInfo.InviteUnit then pcall(C_PartyInfo.InviteUnit, who)
  elseif InviteUnit then pcall(InviteUnit, who) end
end

---------------------------------------------------------------------------
-- Left: the list
---------------------------------------------------------------------------
local list = Card(page)
list:SetPoint("TOPLEFT")
list:SetPoint("BOTTOMLEFT")
list:SetWidth(LW)

local head = ns.Font(list, true, 10, 0.55, 0.58, 0.64)
head:SetPoint("TOPLEFT", PAD, -16)
local count = ns.Font(list, false, 10, 0.42, 0.44, 0.48)
count:SetPoint("LEFT", head, "RIGHT", 8, 0)

local find = CreateFrame("EditBox", nil, list)
find:SetSize(176, 24)
find:SetPoint("TOPRIGHT", -PAD, -9)
find:SetAutoFocus(false)
find:SetMaxLetters(40)
find:SetFont(ns.F_SEMI, 11, "")
find:SetTextColor(1, 1, 1)
find:SetTextInsets(8, 8, 0, 0)
local findBg = find:CreateTexture(nil, "BACKGROUND")
findBg:SetAllPoints()
findBg:SetColorTexture(0.08, 0.09, 0.11, 0.95)
local findHint = ns.Font(find, false, 10, 0.45, 0.47, 0.52)
findHint:SetPoint("LEFT", 8, 0)
findHint:SetPoint("RIGHT", -8, 0)
findHint:SetJustifyH("LEFT")
findHint:SetWordWrap(false)
find:SetScript("OnEscapePressed", function(self) self:SetText(""); self:ClearFocus() end)
find:SetScript("OnEnterPressed", function(self)
  self:ClearFocus()
  ns.FindCrafters(self:GetText())   -- asks your guild too
end)
find:SetScript("OnEditFocusGained", function() findHint:Hide() end)
find:SetScript("OnEditFocusLost", function(self) findHint:SetShown((self:GetText() or "") == "") end)
find:SetScript("OnTextChanged", function(self, user)
  findHint:SetShown((self:GetText() or "") == "" and not self:HasFocus())
  if user then offset = 0; page:Refresh() end
end)

local line = list:CreateTexture(nil, "ARTWORK")
line:SetPoint("TOPLEFT", PAD, -42)
line:SetPoint("TOPRIGHT", -PAD, -42)
line:SetHeight(1)
line:SetColorTexture(1, 1, 1, 0.06)

local empty = ns.Font(list, false, 11, 0.55, 0.58, 0.64)
empty:SetPoint("TOPLEFT", PAD, -60)
empty:SetPoint("RIGHT", list, "RIGHT", -PAD, 0)
empty:SetJustifyH("LEFT")

local foot = ns.Font(list, false, 9, 0.45, 0.47, 0.52)
foot:SetPoint("BOTTOMLEFT", PAD, 10)
foot:SetPoint("RIGHT", list, "RIGHT", -PAD, 0)
foot:SetJustifyH("LEFT")

local rows = {}
page.rows = rows
local function Dot(parent)
  local d = parent:CreateTexture(nil, "OVERLAY", nil, 3)
  d:SetTexture("Interface\\COMMON\\Indicator-Gray")
  d:SetSize(14, 14)
  return d
end
local function SetDot(d, p)
  if p.online then d:SetTexture("Interface\\COMMON\\Indicator-Green")
  elseif p.source == "trade" then d:SetTexture("Interface\\COMMON\\Indicator-Yellow")
  else d:SetTexture("Interface\\COMMON\\Indicator-Gray") end
end

local function Row(i)
  if rows[i] then return rows[i] end
  local r = CreateFrame("Button", nil, list)
  r:SetHeight(ROW_H)
  r:SetPoint("TOPLEFT", PAD - 6, -46 - (i - 1) * ROW_H)
  r:SetPoint("RIGHT", list, "RIGHT", -PAD + 6, 0)
  r.sel = r:CreateTexture(nil, "BACKGROUND")
  r.sel:SetAllPoints()
  r.sel:SetColorTexture(1, 0.82, 0.3, 0.08)
  r.hl = r:CreateTexture(nil, "HIGHLIGHT")
  r.hl:SetAllPoints()
  r.hl:SetColorTexture(1, 1, 1, 0.04)
  r.av = r:CreateTexture(nil, "ARTWORK")
  r.av:SetSize(34, 34)
  r.av:SetPoint("LEFT", 6, 0)
  r.dot = Dot(r)
  r.dot:SetPoint("BOTTOMRIGHT", r.av, "BOTTOMRIGHT", 4, -4)
  r.whisper = ns.Button(r, "", 68, 20)
  r.whisper:SetPoint("TOPRIGHT", -6, -5)
  r.whisper:SetScript("OnClick", function(b) ns.Whisper(b:GetParent().p.whisper) end)
  r.invite = ns.Button(r, "", 68, 20)
  r.invite:SetPoint("TOPRIGHT", r.whisper, "BOTTOMRIGHT", 0, -2)
  r.invite:SetScript("OnClick", function(b) Invite(b:GetParent().p.whisper) end)
  r.name = ns.Font(r, true, 12)
  r.name:SetPoint("TOPLEFT", r.av, "TOPRIGHT", 10, 2)
  r.name:SetPoint("RIGHT", r.whisper, "LEFT", -8, 0)
  r.name:SetJustifyH("LEFT"); r.name:SetWordWrap(false)
  r.profs = ns.Font(r, false, 10, 0.78, 0.8, 0.84)
  r.profs:SetPoint("TOPLEFT", r.name, "BOTTOMLEFT", 0, -3)
  r.profs:SetPoint("RIGHT", r.whisper, "LEFT", -8, 0)
  r.profs:SetJustifyH("LEFT"); r.profs:SetWordWrap(false)
  r.info = ns.Font(r, false, 10, 0.5, 0.52, 0.56)
  r.info:SetPoint("TOPLEFT", r.profs, "BOTTOMLEFT", 0, -3)
  r.info:SetPoint("RIGHT", r.whisper, "LEFT", -8, 0)
  r.info:SetJustifyH("LEFT"); r.info:SetWordWrap(false)
  r:SetScript("OnClick", function(self) picked = self.p.key; page:Refresh() end)
  rows[i] = r
  return r
end

local function FillRow(r, p)
  r.p = p
  if p.class then
    ns.ClassIcon(r.av, p.class)
  else
    r.av:SetTexture(p.source == "trade" and "Interface\\Icons\\INV_Misc_Note_02" or "Interface\\Icons\\INV_Letter_15")
    r.av:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  end
  SetDot(r.dot, p)
  local tag = p.source == "mine" and T("cfMine") or (p.source == "guild" and T("cfGuild") or T("cfTrade"))
  local cr, cg, cb = ClassColor(p.class)
  r.name:SetText(("|cff%02x%02x%02x%s|r%s  |cff8c8f96%s|r"):format(cr * 255, cg * 255, cb * 255, p.name,
    p.level and ("  |cff8c8f96" .. p.level .. "|r") or "", tag))
  local profs = ProfLine(p)
  if profs == "" and p.ad then profs = "|cffbfb899\"" .. Clean(p.ad) .. "\"|r" end
  r.profs:SetText(profs)
  local info = {}
  if p.hit then info[#info + 1] = "|cff73bf73" .. p.hit .. "|r" end
  if p.zone and p.zone ~= "" then info[#info + 1] = p.zone end
  if p.ad and profs:sub(1, 10) ~= "|cffbfb899" then info[#info + 1] = "\"" .. Clean(p.ad) .. "\"" end
  if p.source == "trade" and p.adAt then info[#info + 1] = T("cfSeen", Ago(p.adAt)) end
  if not p.online and p.source ~= "trade" then info[#info + 1] = T("cfOffline") end
  r.info:SetText(table.concat(info, "  ·  "))
  local other = p.source ~= "mine"
  r.whisper:SetShown(other); r.invite:SetShown(other)
  r.whisper:SetText(T("cfWhisper")); r.invite:SetText(T("cfInvite"))
  r.whisper:SetAlpha(p.online and 1 or 0.6); r.invite:SetAlpha(p.online and 1 or 0.6)
  r.sel:SetShown(picked == p.key)
end

list:EnableMouseWheel(true)
list:SetScript("OnMouseWheel", function(_, delta)
  offset = math.max(0, offset - delta)
  page:Refresh()
end)

---------------------------------------------------------------------------
-- Right: the crafter you picked
---------------------------------------------------------------------------
local card = Card(page)
card:SetPoint("TOPRIGHT")
card:SetPoint("BOTTOMRIGHT")
card:SetWidth(RW)

local dHead = ns.Font(card, true, 10, 0.55, 0.58, 0.64)
dHead:SetPoint("TOPLEFT", PAD, -16)
local dAv = card:CreateTexture(nil, "ARTWORK")
dAv:SetSize(44, 44)
dAv:SetPoint("TOPLEFT", PAD, -40)
local dDot = Dot(card)
dDot:SetPoint("BOTTOMRIGHT", dAv, "BOTTOMRIGHT", 4, -4)
local dName = ns.Font(card, true, 15)
dName:SetPoint("TOPLEFT", dAv, "TOPRIGHT", 10, -2)
dName:SetPoint("RIGHT", card, "RIGHT", -PAD, 0)
dName:SetJustifyH("LEFT"); dName:SetWordWrap(false)
local dSub = ns.Font(card, false, 10, 0.6, 0.62, 0.68)
dSub:SetPoint("TOPLEFT", dName, "BOTTOMLEFT", 0, -4)
dSub:SetPoint("RIGHT", card, "RIGHT", -PAD, 0)
dSub:SetJustifyH("LEFT"); dSub:SetWordWrap(false)
local dWhisper = ns.Button(card, "", math.floor((RW - PAD * 2 - 8) / 2), 22)
dWhisper:SetPoint("TOPLEFT", PAD, -96)
local dInvite = ns.Button(card, "", math.floor((RW - PAD * 2 - 8) / 2), 22)
dInvite:SetPoint("LEFT", dWhisper, "RIGHT", 8, 0)

local dBody = ns.Font(card, false, 11, 0.85, 0.86, 0.9)
dBody:SetPoint("TOPLEFT", PAD, -132)
dBody:SetPoint("RIGHT", card, "RIGHT", -PAD, 0)
dBody:SetJustifyH("LEFT")
dBody:SetJustifyV("TOP")
dBody:SetSpacing(3)
local dHint = ns.Font(card, false, 11, 0.55, 0.58, 0.64)
dHint:SetPoint("TOPLEFT", PAD, -40)
dHint:SetPoint("RIGHT", card, "RIGHT", -PAD, 0)
dHint:SetJustifyH("LEFT")

local recipeOffset = 0
card:EnableMouseWheel(true)
card:SetScript("OnMouseWheel", function(_, delta)
  recipeOffset = math.max(0, recipeOffset - delta * 3)
  page:Refresh()
end)

local function Detail(p, q)
  local show = p ~= nil
  for _, w in ipairs({ dAv, dDot, dName, dSub, dBody }) do w:SetShown(show) end
  dWhisper:SetShown(show and p.source ~= "mine"); dInvite:SetShown(show and p.source ~= "mine")
  dHint:SetShown(not show)
  dHead:SetText(Upper(T("cfCrafter")))
  if not show then dHint:SetText(T("cfPick")); return end
  if p.class then ns.ClassIcon(dAv, p.class) else
    dAv:SetTexture(p.source == "trade" and "Interface\\Icons\\INV_Misc_Note_02" or "Interface\\Icons\\INV_Letter_15")
    dAv:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  end
  SetDot(dDot, p)
  dName:SetText(p.name)
  dName:SetTextColor(ClassColor(p.class))
  local sub = {}
  if p.level then sub[#sub + 1] = "Level " .. p.level end
  if p.class and LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[p.class] then sub[#sub + 1] = LOCALIZED_CLASS_NAMES_MALE[p.class] end
  sub[#sub + 1] = p.source == "mine" and T("cfMine") or (p.source == "guild" and T("cfGuild") or T("cfTrade"))
  if p.zone and p.zone ~= "" then sub[#sub + 1] = p.zone end
  dSub:SetText(table.concat(sub, "  ·  "))
  dWhisper:SetText(T("cfWhisper")); dInvite:SetText(T("cfInvite"))
  dWhisper:SetScript("OnClick", function() ns.Whisper(p.whisper) end)
  dInvite:SetScript("OnClick", function() Invite(p.whisper) end)
  dBody:ClearAllPoints()
  dBody:SetPoint("TOPLEFT", PAD, p.source == "mine" and -100 or -132)
  dBody:SetPoint("RIGHT", card, "RIGHT", -PAD, 0)
  -- the text: professions, advert, recipes (matching ones first)
  local out = {}
  local profs = ProfLine(p)
  if profs ~= "" then
    out[#out + 1] = "|cff8c8f96" .. Upper(T("cfProfs")) .. "|r"
    out[#out + 1] = profs
    out[#out + 1] = " "
  end
  if p.ad then
    out[#out + 1] = "|cff8c8f96" .. Upper(T("cfAdvert")) .. "|r  |cff6b6e75" .. T("cfSeen", Ago(p.adAt)) .. "|r"
    out[#out + 1] = "|cffbfb899\"" .. Clean(p.ad) .. "\"|r"
    out[#out + 1] = " "
  end
  local names = {}
  for name, r in pairs(p.recipes) do
    local hit = q ~= "" and (string.find(Low(name), q, 1, true) or string.find(Low(ItemName(r.item)), q, 1, true))
    names[#names + 1] = { name = name, prof = r.prof, hit = hit and true or false }
  end
  table.sort(names, function(a, b)
    if a.hit ~= b.hit then return a.hit end
    return a.name < b.name
  end)
  out[#out + 1] = "|cff8c8f96" .. Upper(T("cfRecipes")) .. "|r  |cff6b6e75" .. #names .. "|r"
  if #names == 0 then
    out[#out + 1] = "|cff6b6e75" .. T("cfNoRecipes") .. "|r"
  else
    local room = math.max(4, math.floor((page:GetHeight() - 160 - (#out * 17)) / 17))
    recipeOffset = math.min(recipeOffset, math.max(0, #names - room))
    for i = recipeOffset + 1, math.min(#names, recipeOffset + room) do
      local e = names[i]
      out[#out + 1] = (e.hit and "|cff73bf73" or "|cffe6e7eb") .. e.name .. "|r" .. (e.prof and ("  |cff6b6e75" .. e.prof .. "|r") or "")
    end
    if #names > room then out[#out + 1] = "|cff6b6e75" .. T("cfMore", recipeOffset + 1, math.min(#names, recipeOffset + room), #names) .. "|r" end
  end
  dBody:SetText(table.concat(out, "\n"))
end

---------------------------------------------------------------------------
function page:Refresh()
  if not ns.db then return end
  if GuildRoster and C_GuildInfo and C_GuildInfo.GuildRoster and (not page.rosterAt or GetTime() - page.rosterAt > 30) then
    page.rosterAt = GetTime()
    pcall(C_GuildInfo.GuildRoster)
  end
  head:SetText(Upper(T("cfHead")))
  findHint:SetText(T("cfSearch"))
  findHint:SetShown((find:GetText() or "") == "" and not find:HasFocus())
  local q = Low(string.match(find:GetText() or "", "^%s*(.-)%s*$"))
  local people = Sorted(q)
  local online = 0
  for _, p in ipairs(people) do if p.online then online = online + 1 end end
  count:SetText(T("cfCount", online, #people))
  local room = math.floor((page:GetHeight() - 46 - 30) / ROW_H)
  if room < 1 then room = 9 end
  offset = math.min(offset, math.max(0, #people - room))
  for i = 1, room do
    local p = people[offset + i]
    local r = Row(i)
    if p then FillRow(r, p); r:Show() else r:Hide() end
  end
  for i = room + 1, #rows do rows[i]:Hide() end
  empty:SetShown(#people == 0)
  empty:SetText(q ~= "" and T("cfNoMatch") or T("cfNone"))
  local res = ns.crafterResults
  if res and res.asked and not res.waited and res.query and res.query ~= "" then
    foot:SetText(T("asking"))
  else
    foot:SetText(T("cfFoot"))
  end
  -- the picked crafter (the first one if none)
  local sel
  for _, p in ipairs(people) do if p.key == picked then sel = p end end
  if not sel and people[1] and q ~= "" then sel = people[1]; picked = sel.key end
  for i = 1, room do if rows[i]:IsShown() then rows[i].sel:SetShown(picked == rows[i].p.key) end end
  Detail(sel, q)
end

page:SetScript("OnShow", function() page:Refresh() end)

-- CraftETA: your characters, their recipe books, item tooltips and "who can craft it" in your guild.
-- Everything here is saved for the whole account, so your alts know what each other can make.
local ADDON, ns = ...
local T, Plain = ns.T, ns.Plain

local PREFIX = "CraftETA"
local GetItemInfoInstant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant

---------------------------------------------------------------------------
-- Characters
---------------------------------------------------------------------------
local function Realm()
  local ok, realm = pcall(GetNormalizedRealmName)
  realm = ok and Plain(realm)
  if type(realm) ~= "string" then return "" end
  return realm
end

function ns.CharKey()
  local name = Plain(UnitName("player"))
  if type(name) ~= "string" then return nil end
  local realm = Realm()
  return realm ~= "" and (name .. "-" .. realm) or name
end

function ns.Me()
  local key = ns.CharKey()
  if not key or not ns.db then return nil end
  local c = ns.db.chars[key]
  if not c then
    c = { profs = {}, book = {} }
    ns.db.chars[key] = c
  end
  c.profs, c.book = c.profs or {}, c.book or {}
  return c, key
end

function ns.UpdateMe()
  local c = ns.Me()
  if not c then return end
  c.name = Plain(UnitName("player"))
  local _, class = UnitClass("player")
  c.class = Plain(class)
  c.level = Plain(UnitLevel("player"))
  c.money = Plain(GetMoney())
  c.faction = ns.Faction()
  c.seen = time()
  local skills = ns.Skills(true)
  if next(skills) then
    wipe(c.profs)
    for id, s in pairs(skills) do c.profs[id] = { rank = s.rank, max = s.max } end
  end
end

for _, event in ipairs({ "PLAYER_LOGIN", "PLAYER_MONEY", "PLAYER_LEVEL_UP", "SKILL_LINES_CHANGED", "PLAYER_LOGOUT" }) do
  ns.Register(event)
  ns.On(event, function() ns.UpdateMe() end)
end

---------------------------------------------------------------------------
-- Recipe books: profession ID -> recipe ID -> { n = name, l = learned, i = icon, o = output item,
--   y = yield, m = { name, count, ... }, d = difficulty, s = where to learn it }
---------------------------------------------------------------------------
function ns.SaveBook(open, list)
  local c = ns.Me()
  if not c or not open or #list == 0 then return end
  local book = {}
  for _, r in ipairs(list) do
    local e = r.entry
    book[e.id] = { n = r.name, l = e.learned or nil, i = e.icon, o = e.out, y = e.yield ~= 1 and e.yield or nil,
      m = e.mats, d = e.diff, s = e.source }
  end
  c.book[open.id] = book
  c.profs[open.id] = { rank = open.rank, max = open.max }
  ns.indexDirty = true
end

-- the cost of one craft from its materials, and whether every price was known
function ns.CraftCost(r)
  local cost, missing = 0, false
  local mats = r.m or {}
  for i = 1, #mats, 2 do
    local price = ns.Price(mats[i])
    if price then cost = cost + price * mats[i + 1] else missing = true end
  end
  return cost, missing
end

-- item ID -> who on your account makes it, and which recipes use it
local makers, users = {}, {}
local function Index()
  if not ns.indexDirty or not ns.db then return end
  ns.indexDirty = false
  wipe(makers); wipe(users)
  for key, c in pairs(ns.db.chars) do
    for profID, book in pairs(c.book or {}) do
      for _, r in pairs(book) do
        if r.o and r.l then
          makers[r.o] = makers[r.o] or {}
          makers[r.o][#makers[r.o] + 1] = { char = c.name or key, recipe = r }
        end
        local mats = r.m or {}
        for i = 1, #mats, 2 do
          local id = ns.ItemID(mats[i])
          if id then
            users[id] = users[id] or {}
            users[id][profID] = (users[id][profID] or 0) + 1
          end
        end
      end
    end
  end
end
function ns.Makers(itemID) Index(); return makers[itemID] end
function ns.Users(itemID) Index(); return users[itemID] end

local function ProfName(id)
  local g = ns.GUIDES[id] or ns.GATHER[id]
  return g and g.name or tostring(id)
end
ns.ProfName = ProfName

---------------------------------------------------------------------------
-- Item tooltips
---------------------------------------------------------------------------
local function AddLines(tooltip, itemID)
  if not ns.db or not ns.db.tooltip or not itemID then return end
  local added = false
  local function head()
    if not added then tooltip:AddLine(" "); tooltip:AddLine("Craft|cffffd24aETA|r"); added = true end
  end
  local list = ns.Makers(itemID)
  if list then
    local names, seen = {}, {}
    for _, m in ipairs(list) do
      if not seen[m.char] then seen[m.char] = true; names[#names + 1] = m.char end
    end
    head()
    tooltip:AddDoubleLine(T("ttMade"), table.concat(names, ", "), 0.7, 0.72, 0.76, 1, 1, 1)
    local cost, missing = ns.CraftCost(list[1].recipe)
    if cost > 0 then
      tooltip:AddDoubleLine(T("ttCost"), (missing and "~" or "") .. ns.Money(cost / (list[1].recipe.y or 1)), 0.7, 0.72, 0.76, 1, 1, 1)
    end
  end
  local used = ns.Users(itemID)
  if used then
    for profID, n in pairs(used) do
      head()
      tooltip:AddDoubleLine(T("ttUsed"), T("ttRecipes", ProfName(profID), n), 0.7, 0.72, 0.76, 1, 1, 1)
    end
  end
end

local function ItemFromTooltip(tooltip, data)
  local id = data and Plain(data.id)
  if type(id) == "number" then return id end
  if tooltip.GetItem then
    local ok, _, link = pcall(tooltip.GetItem, tooltip)
    if ok and type(link) == "string" and GetItemInfoInstant then
      local okID, found = pcall(GetItemInfoInstant, link)
      if okID and type(found) == "number" then return found end
    end
  end
  return nil
end

local hooked
ns.On("PLAYER_LOGIN", function()
  if hooked then return end
  hooked = true
  if TooltipDataProcessor and Enum and Enum.TooltipDataType then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
      if tooltip == GameTooltip or tooltip == ItemRefTooltip then
        pcall(AddLines, tooltip, ItemFromTooltip(tooltip, data))
      end
    end)
  elseif GameTooltip.HookScript then
    GameTooltip:HookScript("OnTooltipSetItem", function(tooltip)
      pcall(AddLines, tooltip, ItemFromTooltip(tooltip))
    end)
  end
end)

---------------------------------------------------------------------------
-- Who can craft it: your own characters first, then everyone in your guild with CraftETA
---------------------------------------------------------------------------
local results, lastAsk = {}, 0
ns.crafterResults = results

-- the made item's name too, so "Copper Bar" finds "Smelt Copper"
local GetItemNameByID = C_Item and C_Item.GetItemNameByID
local function ItemNameHas(itemID, want)
  if not itemID then return false end
  local name
  if GetItemNameByID then
    local ok, n = pcall(GetItemNameByID, itemID)
    if ok then name = Plain(n) end
  end
  if type(name) ~= "string" and GetItemInfo then
    local ok, n = pcall(GetItemInfo, itemID)
    if ok then name = Plain(n) end
  end
  return type(name) == "string" and string.find(string.lower(name), want, 1, true) ~= nil
end

---------------------------------------------------------------------------
-- Trade chat: people advertising crafting ("LFW", "WTS", "can craft", "your mats"),
-- so you find crafters even when nobody in your guild has CraftETA
---------------------------------------------------------------------------
local ads = {}
local AD_WORDS = { "lfw", "wts", "craft", "can make", "can do", "your mats", "ur mats", "own mats", "tips", "enchant", "lf work", "pst", "/w me" }
local AD_KEEP = 45 * 60
local function IsAd(low)
  for _, w in ipairs(AD_WORDS) do
    if string.find(low, w, 1, true) then return true end
  end
  return false
end
local function OnChat(text, sender)
  text, sender = Plain(text), Plain(sender)
  if type(text) ~= "string" or type(sender) ~= "string" or ns.db and ns.db.chatAds == false then return end
  local low = string.lower(text)
  if not IsAd(low) then return end
  local short = string.match(sender, "^[^-]+") or sender
  if short == Plain(UnitName("player")) then return end
  for i = #ads, 1, -1 do
    if ads[i].sender == sender then table.remove(ads, i) end   -- newest ad per person
  end
  ads[#ads + 1] = { sender = sender, short = short, text = text, low = low, t = time() }
  while #ads > 300 or (ads[1] and time() - ads[1].t > AD_KEEP) do table.remove(ads, 1) end
end
for _, event in ipairs({ "CHAT_MSG_CHANNEL", "CHAT_MSG_SAY", "CHAT_MSG_YELL" }) do
  ns.Register(event)
  ns.On(event, function(text, sender) pcall(OnChat, text, sender) end)
end

function ns.Adverts()
  local out, now = {}, time()
  if ns.db and ns.db.chatAds == false then return out end
  for _, a in ipairs(ads) do
    if now - a.t <= AD_KEEP then out[#out + 1] = a end
  end
  return out
end

local function AdMatches(text, found)
  local words = {}
  for w in string.gmatch(string.lower(text), "%S+") do words[#words + 1] = w end
  if #words == 0 then return end
  local now = time()
  for i = #ads, 1, -1 do
    local a = ads[i]
    if now - a.t <= AD_KEEP then
      local all = true
      for _, w in ipairs(words) do
        if not string.find(a.low, w, 1, true) then all = false; break end
      end
      if all then
        local line = a.text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|H.-|h(.-)|h", "%1")
        if #line > 70 then line = string.sub(line, 1, 67) .. "..." end
        found[#found + 1] = { recipe = line, char = a.short, sender = a.sender, ad = true,
          prof = T("adAgo", math.max(1, math.floor((now - a.t) / 60))) }
      end
    end
  end
end

local function Matches(text)
  local found = {}
  if not ns.db or text == "" then return found end
  local want = string.lower(text)
  for key, c in pairs(ns.db.chars) do
    for profID, book in pairs(c.book or {}) do
      for _, r in pairs(book) do
        if r.l and r.n and (string.find(string.lower(r.n), want, 1, true) or ItemNameHas(r.o, want)) then
          found[#found + 1] = { recipe = r.n, char = c.name or key, prof = ProfName(profID), mine = true, icon = r.i, item = r.o }
        end
      end
    end
  end
  table.sort(found, function(a, b) return a.recipe < b.recipe end)
  return found
end

function ns.FindCrafters(text)
  text = string.match(text or "", "^%s*(.-)%s*$") or ""
  wipe(results)
  results.query = text
  for _, r in ipairs(Matches(text)) do results[#results + 1] = r end
  if #text >= 3 then AdMatches(text, results) end
  results.waited = nil
  if #text >= 3 and ns.db.guildAsk and IsInGuild and IsInGuild() and C_ChatInfo and GetTime() - lastAsk > 2 then
    lastAsk = GetTime()
    pcall(C_ChatInfo.SendAddonMessage, PREFIX, "Q\t" .. string.sub(text, 1, 60), "GUILD")
    results.asked = true
    local query = text
    C_Timer.After(4, function()
      if results.query == query then
        results.waited = true
        if ns.RefreshHub then ns.RefreshHub() end
      end
    end)
  end
  if ns.RefreshHub then ns.RefreshHub() end
end

local answered = {}
ns.Register("CHAT_MSG_ADDON")
ns.On("CHAT_MSG_ADDON", function(prefix, msg, channel, sender)
  prefix, msg, sender = Plain(prefix), Plain(msg), Plain(sender)
  if prefix ~= PREFIX or type(msg) ~= "string" or type(sender) ~= "string" then return end
  local me = Plain(UnitName("player"))
  local short = string.match(sender, "^[^-]+")
  local kind, a, b, c = strsplit("\t", msg)
  if kind == "Q" and a and short ~= me and ns.db.guildShare then
    if answered[sender] and GetTime() - answered[sender] < 3 then return end
    answered[sender] = GetTime()
    local list = Matches(a)
    for i = 1, math.min(5, #list) do
      local line = string.sub(("A\t%s\t%s\t%s"):format(list[i].recipe, list[i].char, list[i].prof), 1, 250)
      pcall(C_ChatInfo.SendAddonMessage, PREFIX, line, "WHISPER", sender)
    end
  elseif kind == "P" and short ~= me then
    if a == "?" then
      if ns.db.guildShare and channel == "GUILD" then ns.SendProfile(sender) end
    else
      ns.guildPeers = ns.guildPeers or {}
      local p = ns.guildPeers[sender] or { recipes = {} }
      p.name, p.short, p.profs = sender, short, {}
      for name, skill in string.gmatch(a or "", "([^:,]+):(%d+)") do p.profs[name] = tonumber(skill) end
      p.class, p.level, p.seen = b ~= "" and b or p.class, tonumber(c) or p.level, time()
      ns.guildPeers[sender] = p
      if ns.RefreshHub then ns.RefreshHub() end
    end
  elseif kind == "A" and a and b and results.query then
    for _, r in ipairs(results) do
      if r.recipe == a and r.char == b then return end
    end
    results[#results + 1] = { recipe = a, char = b, prof = c, sender = sender }
    ns.guildPeers = ns.guildPeers or {}
    local p = ns.guildPeers[sender] or { name = sender, short = short, profs = {}, recipes = {} }
    p.recipes[a] = c or true
    ns.guildPeers[sender] = p
    if ns.RefreshHub then ns.RefreshHub() end
  end
end)

-- your professions to the guild, so guild members with CraftETA see you on their Crafters page
local lastProfile = 0
function ns.SendProfile(target)
  if not (ns.db and ns.db.guildShare and IsInGuild and IsInGuild() and C_ChatInfo) then return end
  if not target and GetTime() - lastProfile < 60 then return end
  local c = ns.Me()
  if not c then return end
  local parts = {}
  for id, s in pairs(c.profs or {}) do parts[#parts + 1] = ProfName(id) .. ":" .. (s.rank or 0) end
  if #parts == 0 then return end
  table.sort(parts)
  local line = ("P\t%s\t%s\t%s"):format(table.concat(parts, ","), c.class or "", c.level or 0)
  if target then
    pcall(C_ChatInfo.SendAddonMessage, PREFIX, line, "WHISPER", target)
  else
    lastProfile = GetTime()
    pcall(C_ChatInfo.SendAddonMessage, PREFIX, line, "GUILD")
  end
end
ns.On("PLAYER_LOGIN", function()
  C_Timer.After(12, function()
    ns.SendProfile()
    if ns.db and ns.db.guildAsk and IsInGuild and IsInGuild() and C_ChatInfo then
      pcall(C_ChatInfo.SendAddonMessage, PREFIX, "P\t?", "GUILD")
    end
  end)
end)
ns.On("SKILL_LINES_CHANGED", function() if C_Timer then C_Timer.After(5, function() ns.SendProfile() end) end end)

function ns.Whisper(target)
  if not target then return end
  if ChatFrame_SendTell then
    ChatFrame_SendTell(target)
  elseif ChatFrameUtil and ChatFrameUtil.SendTell then
    ChatFrameUtil.SendTell(target)
  end
end

ns.On("ADDON_LOADED", function()
  ns.db.chars = ns.db.chars or {}
  if ns.db.tooltip == nil then ns.db.tooltip = true end
  if ns.db.guildShare == nil then ns.db.guildShare = true end
  if ns.db.guildAsk == nil then ns.db.guildAsk = true end
  if ns.db.chatAds == nil then ns.db.chatAds = true end
  for _, m in ipairs(ns.MATERIALS) do
    if not ns.db.ids[m[1]] then ns.db.ids[m[1]] = m[2] end
  end
  ns.indexDirty = true
  if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
    pcall(C_ChatInfo.RegisterAddonMessagePrefix, PREFIX)
  end
end)

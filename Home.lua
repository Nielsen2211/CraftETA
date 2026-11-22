-- CraftETA: the Home and Alts pages of the main window, and the smaller list pages
-- (Specializations, Camping, Cooldowns, Codex materials).
local _, ns = ...
local T = ns.T

local H, X, CW = ns.Hub, ns.HUB_X, ns.HUB_CW

local function L(en, da) return (ns.db and ns.db.lang == "da") and da or en end

local function Card(parent)
  local f = CreateFrame("Frame", nil, parent)
  local bg = f:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  -- the same flat card as the step in the profession panel: no edges, a shade lighter than the window
  bg:SetColorTexture(0.086, 0.094, 0.122, 1)
  return f
end
ns.Card = Card

local function Label(parent, text)
  local l = ns.Font(parent, true, 9, 0.55, 0.58, 0.64)
  l:SetText(string.upper(text or ""))
  return l
end

local function Page()
  local p = CreateFrame("Frame", nil, H)
  p:SetPoint("TOPLEFT", X, -20)
  p:SetPoint("BOTTOMRIGHT", -18, 16)
  p:Hide()
  return p
end

function ns.ClassIcon(tex, class)
  local coords = class and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class]
  if coords then
    tex:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
    tex:SetTexCoord(unpack(coords))
  else
    tex:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  end
end

-- a small bar for a profession: 0-300 with ticks at each rank
local function MiniBar(parent, width)
  local b = CreateFrame("Frame", nil, parent)
  b:SetSize(width, 5)
  local bg = b:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetColorTexture(1, 1, 1, 0.08)
  b.cap = b:CreateTexture(nil, "BORDER")
  b.cap:SetPoint("TOPLEFT"); b.cap:SetPoint("BOTTOMLEFT")
  b.cap:SetColorTexture(1, 1, 1, 0.08)
  b.fill = b:CreateTexture(nil, "ARTWORK")
  b.fill:SetPoint("TOPLEFT"); b.fill:SetPoint("BOTTOMLEFT")
  b.fill:SetColorTexture(1, 0.82, 0.3, 1)
  function b:SetRank(rank, max)
    max = max or 300
    self.cap:SetWidth(math.max(1, width * math.min(1, max / 300)))
    self.fill:SetWidth(math.max(1, width * math.min(1, rank / 300)))
    local done = rank >= 300
    self.fill:SetColorTexture(done and 0.35 or 1, done and 0.9 or 0.82, done and 0.4 or 0.3, 1)
  end
  return b
end

local PROF_ROW_H = 26
local function ProfRow(parent, width)
  local r = CreateFrame("Frame", nil, parent)
  r:SetSize(width, PROF_ROW_H - 2)
  r.icon = r:CreateTexture(nil, "ARTWORK")
  r.icon:SetSize(20, 20)
  r.icon:SetPoint("LEFT")
  r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  r.value = ns.Font(r, true, 10, 0.75, 0.77, 0.8)
  r.value:SetPoint("TOPRIGHT", 0, -2)
  r.value:SetJustifyH("RIGHT")
  r.name = ns.Font(r, false, 11)
  r.name:SetPoint("TOPLEFT", r.icon, "TOPRIGHT", 7, 0)
  r.name:SetPoint("RIGHT", r.value, "LEFT", -6, 0)
  r.name:SetWordWrap(false)
  r.bar = MiniBar(r, width - 27)
  r.bar:SetPoint("BOTTOMLEFT", r.icon, "BOTTOMRIGHT", 7, 1)
  return r
end

local ORDER = { 171, 164, 333, 202, 165, 197, 186, 182, 393, 185, 129, 356 }
local function SortedProfs(profs)
  local list = {}
  for _, id in ipairs(ORDER) do
    if profs and profs[id] then list[#list + 1] = { id = id, rank = profs[id].rank, max = profs[id].max } end
  end
  return list
end

---------------------------------------------------------------------------
-- Next steps: what to do now, best first
---------------------------------------------------------------------------
function ns.NextSteps()
  local out = {}
  local skills = ns.Skills(true)
  local f = ns.Faction()
  for _, p in ipairs(SortedProfs(skills)) do
    local id, rank, max = p.id, p.rank, p.max or 300
    local guide = ns.GUIDES[id] or ns.GATHER[id]
    local icon = ns.ProfIcon(id)
    local train, rankName, where = ns.TrainNow(id, rank, max)
    if train then
      local lvl = UnitLevel("player") or 0
      table.insert(out, 1, { icon = icon, title = T("trainNow", rankName, guide.name),
        sub = T("trainWhere", where) .. (lvl < train.lvl and ("  ·  " .. T("trainLevel", train.lvl)) or ""),
        r = 1, g = 0.82, b = 0.3, prof = id })
    elseif max < 300 and max - rank <= 10 then
      local nextRank
      for _, r in ipairs(guide.ranks) do
        if max <= r.at then nextRank = r; break end
      end
      if nextRank then
        out[#out + 1] = { icon = icon, title = T("almostCapped", guide.name), sub = T("learnRankAt", nextRank.lvl, nextRank[f]), r = 1, g = 0.82, b = 0.3 }
      end
    end
    if rank < 300 then
      for i, step in ipairs(guide.steps) do
        if rank < step[2] then
          if ns.GUIDES[id] then
            local entry = (ns.Chosen(id, i, step))[1]
            out[#out + 1] = { icon = ns.ItemIcon(entry[1], icon), title = T("levelWith", guide.name, entry[1]),
              sub = ("%d/%d · %d-%d · %s"):format(rank, max, step[1], step[2], T("crafts", entry[2])), r = 0.45, g = 0.75, b = 1, prof = id }
          else
            out[#out + 1] = { icon = icon, title = T("levelWith", guide.name, step.what), sub = ("%d/%d · %s"):format(rank, max, step[f]), r = 0.45, g = 0.75, b = 1, prof = id }
          end
          break
        end
      end
    end
  end
  -- specializations you can take now
  for profID, list in pairs(ns.SPECS) do
    local s = skills[profID]
    if s then
      for _, spec in ipairs(list) do
        if s.rank >= spec[4] and (UnitLevel("player") or 0) >= spec[3] and not ns.HasSpell(spec[2]) and spec[4] < 250 then
          out[#out + 1] = { icon = ns.ProfIcon(profID), title = T("specReady", spec[1]), sub = spec[f], r = 0.75, g = 0.55, b = 1 }
          break
        end
      end
    end
  end
  local dura = ns.Durability()
  if dura < 0.3 then
    out[#out + 1] = { icon = "Interface\\Icons\\INV_Hammer_20", title = T("repair"), sub = T("duraLeft", math.floor(dura * 100)), r = 1, g = 0.4, b = 0.35 }
  end
  local free = ns.BagSpace()
  if free <= 4 then
    out[#out + 1] = { icon = "Interface\\Icons\\INV_Misc_Bag_08", title = T("bagsFull"), sub = T("bagsLeft", free), r = 1, g = 0.6, b = 0.35 }
  end
  local me = ns.Me()
  for name, cd in pairs(me and me.cd or {}) do
    if cd.ready <= time() then
      out[#out + 1] = { icon = "Interface\\Icons\\INV_Misc_PocketWatch_01", title = T("cdReadyShort", name), sub = T("cdUse"), r = 0.35, g = 0.9, b = 0.4 }
    end
  end
  return out
end

---------------------------------------------------------------------------
-- Home
---------------------------------------------------------------------------
local home = Page()
ns.HubCustom.home = home
local GOLD = { 1, 0.82, 0.29 }

local function Edge(f, r, g, b, a)
  for _, p in ipairs({ { "TOPLEFT", "TOPRIGHT", true }, { "BOTTOMLEFT", "BOTTOMRIGHT", true }, { "TOPLEFT", "BOTTOMLEFT" }, { "TOPRIGHT", "BOTTOMRIGHT" } }) do
    local t = f:CreateTexture(nil, "BORDER")
    t:SetPoint(p[1]); t:SetPoint(p[2])
    if p[3] then t:SetHeight(1) else t:SetWidth(1) end
    t:SetColorTexture(r, g, b, a or 1)
  end
end
local function Tip(frame, fn)
  frame:EnableMouse(true)
  frame:SetScript("OnEnter", function(self) GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); fn(GameTooltip, self); GameTooltip:Show() end)
  frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

---------------------------------------------------------------------------
-- Hero: who you are, your experience and your gold
---------------------------------------------------------------------------
local hero = Card(home)
hero:SetPoint("TOPLEFT"); hero:SetPoint("RIGHT"); hero:SetHeight(92)
Edge(hero, 0.47, 0.38, 0.16)
local glow = hero:CreateTexture(nil, "BACKGROUND", nil, 2)
glow:SetPoint("TOPLEFT", 1, -1); glow:SetPoint("BOTTOMLEFT", 1, 1); glow:SetWidth(260)
glow:SetColorTexture(1, 1, 1, 1)
if glow.SetGradient and CreateColor then
  pcall(glow.SetGradient, glow, "HORIZONTAL", CreateColor(1, 0.82, 0.3, 0.1), CreateColor(1, 0.82, 0.3, 0))
else
  glow:SetColorTexture(1, 0.82, 0.3, 0.04)
end
local classIcon = hero:CreateTexture(nil, "ARTWORK")
classIcon:SetSize(50, 50); classIcon:SetPoint("TOPLEFT", 16, -12)
local nameText = ns.Font(hero, true, 22, 0.9, 0.91, 0.94)
nameText:SetPoint("TOPLEFT", classIcon, "TOPRIGHT", 14, 2)
local subText = ns.Font(hero, false, 11, 0.7, 0.72, 0.76)
subText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -4)
local goldLabel = Label(hero, ""); goldLabel:SetPoint("TOPRIGHT", -16, -16); goldLabel:SetJustifyH("RIGHT")
local goldText = ns.Font(hero, true, 20, 1, 1, 1); goldText:SetPoint("TOPRIGHT", goldLabel, "BOTTOMRIGHT", 0, -4); goldText:SetJustifyH("RIGHT")
local accountText = ns.Font(hero, false, 10, 0.5, 0.52, 0.57); accountText:SetPoint("TOPRIGHT", goldText, "BOTTOMRIGHT", 0, -3); accountText:SetJustifyH("RIGHT")
-- experience along the bottom of the card
local xpBar = CreateFrame("Frame", nil, hero)
xpBar:SetPoint("TOPLEFT", classIcon, "BOTTOMRIGHT", 14, -6); xpBar:SetPoint("RIGHT", hero, "RIGHT", -190, 0); xpBar:SetHeight(5)
local xpBg = xpBar:CreateTexture(nil, "BACKGROUND"); xpBg:SetAllPoints(); xpBg:SetColorTexture(1, 1, 1, 0.08)
local xpRest = xpBar:CreateTexture(nil, "BORDER"); xpRest:SetPoint("TOPLEFT"); xpRest:SetPoint("BOTTOMLEFT"); xpRest:SetColorTexture(0.3, 0.55, 1, 0.55)
local xpFill = xpBar:CreateTexture(nil, "ARTWORK"); xpFill:SetPoint("TOPLEFT"); xpFill:SetPoint("BOTTOMLEFT"); xpFill:SetColorTexture(1, 0.82, 0.3, 1)
local xpValue = ns.Font(hero, false, 9, 0.6, 0.62, 0.67); xpValue:SetPoint("BOTTOMLEFT", xpBar, "TOPLEFT", 0, 5)
Tip(xpBar, function(tip)
  local me = ns.Me()
  tip:SetText(T("experience"), 1, 0.82, 0.3)
  if me and (me.xpMax or 0) > 0 then
    tip:AddDoubleLine(L("Now", "Nu"), (me.xp or 0) .. " / " .. me.xpMax, 0.85, 0.87, 0.9, 1, 1, 1)
    tip:AddDoubleLine(T("rested"), me.rested or 0, 0.85, 0.87, 0.9, 0.44, 0.61, 1)
  end
end)

---------------------------------------------------------------------------
-- Four tiles: durability, bags, time played, favor
---------------------------------------------------------------------------
local TILE_ICONS = { "Interface\\Icons\\INV_Chest_Chain_05", "Interface\\Icons\\INV_Misc_Bag_08",
  "Interface\\Icons\\INV_Misc_PocketWatch_01", "Interface\\Icons\\INV_Crate_01" }
local TW = math.floor((CW - 3 * 8) / 4)
local tiles = {}
for i = 1, 4 do
  local c = Card(home)
  c:SetSize(TW, 54)
  c:SetPoint("TOPLEFT", (i - 1) * (TW + 8), -100)
  c.accent = c:CreateTexture(nil, "BORDER"); c.accent:SetPoint("TOPLEFT"); c.accent:SetPoint("BOTTOMLEFT"); c.accent:SetWidth(2)
  c.icon = c:CreateTexture(nil, "ARTWORK"); c.icon:SetSize(30, 30); c.icon:SetPoint("LEFT", 12, 0)
  c.icon:SetTexture(TILE_ICONS[i]); c.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  c.label = Label(c, ""); c.label:SetPoint("TOPLEFT", c.icon, "TOPRIGHT", 10, -2)
  c.value = ns.Font(c, true, 14, 0.9, 0.91, 0.94); c.value:SetPoint("BOTTOMLEFT", c.icon, "BOTTOMRIGHT", 10, 0)
  tiles[i] = c
end
tiles[4]:EnableMouse(true)
tiles[4]:SetScript("OnMouseUp", function() ns.ToggleHub("favor") end)

---------------------------------------------------------------------------
-- Professions (left) and next steps (right)
---------------------------------------------------------------------------
local COLW = math.floor((CW - 8) / 2)
local profCard = Card(home)
profCard:SetPoint("TOPLEFT", 0, -162); profCard:SetPoint("BOTTOMLEFT"); profCard:SetWidth(COLW)
local profLabel = Label(profCard, ""); profLabel:SetPoint("TOPLEFT", 14, -12)
local PROF_H = 46
local BAR_W = COLW - 28 - 34

-- a profession: icon, name, rank, and its route as a bar of steps you can hover
local profRows = {}
local function ProfCard(i)
  if profRows[i] then return profRows[i] end
  local r = CreateFrame("Button", nil, profCard)
  r:SetSize(COLW - 28, PROF_H - 6)
  r:SetPoint("TOPLEFT", 14, -32 - (i - 1) * PROF_H)
  r.icon = r:CreateTexture(nil, "ARTWORK"); r.icon:SetSize(28, 28); r.icon:SetPoint("TOPLEFT", 0, -2)
  r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  r.value = ns.Font(r, true, 11, 1, 1, 1); r.value:SetPoint("TOPRIGHT", 0, -2); r.value:SetJustifyH("RIGHT")
  r.name = ns.Font(r, true, 11, 0.9, 0.91, 0.94); r.name:SetPoint("TOPLEFT", r.icon, "TOPRIGHT", 8, -1)
  r.rank = ns.Font(r, false, 9, 0.5, 0.52, 0.57); r.rank:SetPoint("LEFT", r.name, "RIGHT", 6, 0)
  r.bar = CreateFrame("Frame", nil, r); r.bar:SetSize(BAR_W, 6)
  r.bar:SetPoint("BOTTOMLEFT", r.icon, "BOTTOMRIGHT", 8, 2)
  r.bg = r.bar:CreateTexture(nil, "BACKGROUND"); r.bg:SetAllPoints(); r.bg:SetColorTexture(1, 1, 1, 0.07)
  r.cap = r.bar:CreateTexture(nil, "BORDER"); r.cap:SetPoint("TOPLEFT"); r.cap:SetPoint("BOTTOMLEFT"); r.cap:SetColorTexture(1, 1, 1, 0.07)
  r.fill = r.bar:CreateTexture(nil, "ARTWORK"); r.fill:SetPoint("TOPLEFT"); r.fill:SetPoint("BOTTOMLEFT")
  r.segs = {}
  local hl = r:CreateTexture(nil, "HIGHLIGHT"); hl:SetPoint("TOPLEFT", -6, 2); hl:SetPoint("BOTTOMRIGHT", 6, -2); hl:SetColorTexture(1, 1, 1, 0.03)
  r:SetScript("OnClick", function(self) if self.prof then ns.hubState.guide = self.prof; ns.ToggleHub("guide") end end)
  profRows[i] = r
  return r
end

-- the steps of a route as hover areas over the bar (with a thin gap between them)
local function Segments(r, id, rank, max)
  local guide = ns.GUIDES[id] or ns.GATHER[id]
  for _, sg in ipairs(r.segs) do sg:Hide() end
  if not guide or not guide.steps then return end
  local f = ns.Faction()
  for k, step in ipairs(guide.steps) do
    local sg = r.segs[k]
    if not sg then
      sg = CreateFrame("Frame", nil, r.bar)
      sg.gap = sg:CreateTexture(nil, "OVERLAY"); sg.gap:SetPoint("TOPRIGHT"); sg.gap:SetPoint("BOTTOMRIGHT"); sg.gap:SetWidth(1)
      sg.gap:SetColorTexture(0.05, 0.055, 0.07, 1)
      sg.hl = sg:CreateTexture(nil, "HIGHLIGHT"); sg.hl:SetAllPoints(); sg.hl:SetColorTexture(1, 1, 1, 0.35)
      r.segs[k] = sg
    end
    local x1, x2 = BAR_W * math.max(0, step[1]) / 300, BAR_W * math.min(300, step[2]) / 300
    sg:ClearAllPoints()
    sg:SetPoint("TOPLEFT", r.bar, "TOPLEFT", x1, 4); sg:SetSize(math.max(2, x2 - x1), 14)
    sg:SetPoint("TOPLEFT", r.bar, "TOPLEFT", x1, 4)
    sg.gap:ClearAllPoints(); sg.gap:SetPoint("TOPRIGHT", 0, -4); sg.gap:SetPoint("BOTTOMRIGHT", 0, 4)
    Tip(sg, function(tip)
      local done, now = rank >= step[2], rank >= step[1] and rank < step[2]
      tip:SetText(("%d - %d"):format(step[1], step[2]), now and 1 or 0.85, now and 0.82 or 0.87, now and 0.3 or 0.9)
      if ns.GUIDES[id] then
        local entry = (ns.Chosen(id, k, step))[1]
        tip:AddLine(L("Craft %d %s", "Lav %d %s"):format(entry[2], entry[1]), 1, 1, 1)
        local mats = entry[3]
        for m = 1, #mats, 2 do tip:AddLine(mats[m + 1] .. " x " .. mats[m], 0.6, 0.62, 0.67) end
      else
        tip:AddLine(step.what or "", 1, 1, 1, true)
        if step[f] then tip:AddLine(step[f], 0.6, 0.62, 0.67, true) end
      end
      if step.note then tip:AddLine(step.note, 0.78, 0.72, 0.58, true) end
      tip:AddLine(done and L("Done", "Klaret") or (now and L("You are here", "Du er her") or ""), done and 0.35 or 1, done and 0.9 or 0.82, done and 0.4 or 0.3)
    end)
    sg:Show()
  end
end

local stepCard = Card(home)
stepCard:SetPoint("TOPRIGHT", 0, -162); stepCard:SetPoint("BOTTOMRIGHT"); stepCard:SetWidth(COLW)
local stepLabel = Label(stepCard, ""); stepLabel:SetPoint("TOPLEFT", 14, -12)
local pageText = ns.Font(stepCard, true, 10, 0.75, 0.77, 0.8)
pageText:SetPoint("TOPRIGHT", -32, -11)
local prevPage = ns.IconButton(stepCard, "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up", 16)
prevPage.icon:SetTexCoord(0, 1, 0, 1)
prevPage:SetPoint("RIGHT", pageText, "LEFT", -4, 0)
local nextPage = ns.IconButton(stepCard, "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up", 16)
nextPage.icon:SetTexCoord(0, 1, 0, 1)
nextPage:SetPoint("LEFT", pageText, "RIGHT", 4, 0)
local stepPage, STEPS_PER = 1, 6
local STEP_H = 50
prevPage:SetScript("OnClick", function() stepPage = stepPage - 1; home:Refresh() end)
nextPage:SetScript("OnClick", function() stepPage = stepPage + 1; home:Refresh() end)
local stepRows = {}
for i = 1, 9 do
  local r = CreateFrame("Button", nil, stepCard)
  r:SetSize(COLW - 28, STEP_H - 6)
  r:SetPoint("TOPLEFT", 14, -32 - (i - 1) * STEP_H)
  local bg = r:CreateTexture(nil, "BACKGROUND"); bg:SetAllPoints(); bg:SetColorTexture(1, 1, 1, 0.025)
  r.accent = r:CreateTexture(nil, "BORDER"); r.accent:SetPoint("TOPLEFT"); r.accent:SetPoint("BOTTOMLEFT"); r.accent:SetWidth(2)
  r.icon = r:CreateTexture(nil, "ARTWORK"); r.icon:SetSize(28, 28); r.icon:SetPoint("LEFT", 10, 0)
  r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  r.title = ns.Font(r, true, 11, 0.9, 0.91, 0.94)
  r.title:SetPoint("TOPLEFT", r.icon, "TOPRIGHT", 10, 0); r.title:SetPoint("RIGHT", r, "RIGHT", -8, 0); r.title:SetWordWrap(false)
  r.sub = ns.Font(r, false, 9, 0.5, 0.52, 0.57)
  r.sub:SetPoint("BOTTOMLEFT", r.icon, "BOTTOMRIGHT", 10, 0); r.sub:SetPoint("RIGHT", r, "RIGHT", -8, 0); r.sub:SetWordWrap(false)
  local hl = r:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints(); hl:SetColorTexture(1, 1, 1, 0.04)
  r:SetScript("OnClick", function(self)
    if self.prof then ns.hubState.guide = self.prof; ns.ToggleHub("guide") end
  end)
  stepRows[i] = r
end

function home:Refresh()
  ns.Facts()
  local me = ns.Me()
  local color = me.class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[me.class]
  ns.ClassIcon(classIcon, me.class)
  nameText:SetText(me.name or "")
  nameText:SetTextColor(color and color.r or 1, color and color.g or 1, color and color.b or 1)
  subText:SetText(T("levelLine", me.level or 0, me.race or "", UnitClass("player") or "") .. (me.zone and ("  |cff8c8f96·  " .. me.zone .. "|r") or ""))
  -- gold: yours, and the whole account's
  local account, n = 0, 0
  for _, c in pairs(ns.db.chars) do account = account + (c.money or 0); n = n + 1 end
  goldLabel:SetText(string.upper(T("gold")))
  goldText:SetText(ns.Money(GetMoney()))
  accountText:SetText(n > 1 and L("Account: %s", "Konto: %s"):format(ns.Money(account)) or "")
  -- experience
  local xp, max, rested = me.xp or 0, me.xpMax or 0, me.rested or 0
  local w = xpBar:GetWidth() or (CW - 32)
  if max > 0 and (me.level or 0) < (GetMaxPlayerLevel and GetMaxPlayerLevel() or 60) then
    xpFill:SetWidth(math.max(1, w * xp / max))
    xpRest:SetWidth(math.max(1, w * math.min(1, (xp + rested) / max)))
    xpValue:SetText(("%s  %d%%   |cff6f9cff%s %d%%|r"):format(string.upper(T("experience")), xp / max * 100, T("rested"), math.floor(rested / max * 100)))
  else
    xpFill:SetWidth(w); xpRest:SetWidth(w)
    xpValue:SetText(string.upper(T("experience")) .. "  ·  " .. T("maxLevel"))
  end
  -- tiles
  local free, total = ns.BagSpace()
  local played = ns.Played(me)
  local dura = ns.Durability()
  local favor = ns.FavorNow and ns.FavorNow()
  local values = {
    { T("durability"), ("%d%%"):format(dura * 100), dura < 0.3 and { 1, 0.4, 0.35 } or (dura < 0.6 and GOLD or { 0.35, 0.9, 0.4 }) },
    { T("bagSpace"), T("bagsFree", free, total), free <= 4 and { 1, 0.4, 0.35 } or (free <= 10 and GOLD or { 0.35, 0.9, 0.4 }) },
    { T("timePlayed"), played and ns.PlayedText(played) or "...", { 0.45, 0.75, 1 } },
    { "Merchant's Favor", favor and tostring(favor) or "-", GOLD },
  }
  for i, c in ipairs(tiles) do
    c.label:SetText(string.upper(values[i][1]))
    c.value:SetText(values[i][2])
    local a = values[i][3]
    c.accent:SetColorTexture(a[1], a[2], a[3], 1)
  end
  -- professions
  profLabel:SetText(string.upper(T("t_guide")))
  local list = SortedProfs(ns.Skills(true))
  local room = math.max(1, math.floor(((profCard:GetHeight() or 390) - 36) / PROF_H))
  for i, r in ipairs(profRows) do r:Hide() end
  for i = 1, math.min(#list, room) do
    local p, r = list[i], ProfCard(i)
    local maxR = p.max or 300
    local done = p.rank >= 300
    r.prof = p.id
    r.icon:SetTexture(ns.ProfIcon(p.id))
    r.name:SetText(ns.ProfName(p.id))
    local rankName = ({ [75] = "Apprentice", [150] = "Journeyman", [225] = "Expert", [300] = "Artisan" })[maxR] or ""
    r.rank:SetText(rankName)
    r.value:SetText(("%d |cff8c8f96/ %d|r"):format(p.rank, maxR))
    r.cap:SetWidth(math.max(1, BAR_W * math.min(1, maxR / 300)))
    r.fill:SetWidth(math.max(1, BAR_W * math.min(1, p.rank / 300)))
    r.fill:SetColorTexture(done and 0.35 or 1, done and 0.9 or 0.82, done and 0.4 or 0.3, 1)
    Segments(r, p.id, p.rank, maxR)
    r:Show()
  end
  if #list == 0 then
    local r = ProfCard(1)
    r.icon:SetTexture(134400); r.name:SetText(T("noProfs")); r.rank:SetText(""); r.value:SetText("")
    r.fill:SetWidth(1); r.cap:SetWidth(1); Segments(r, 0, 0, 0); r:Show()
  end
  -- next steps
  STEPS_PER = math.max(2, math.min(#stepRows, math.floor(((stepCard:GetHeight() or 390) - 36) / STEP_H)))
  stepLabel:SetText(string.upper(T("nextSteps")))
  local steps = ns.NextSteps()
  local pages = math.max(1, math.ceil(#steps / STEPS_PER))
  stepPage = math.max(1, math.min(pages, stepPage))
  pageText:SetText(("%d / %d"):format(stepPage, pages))
  prevPage:SetEnabled(stepPage > 1); nextPage:SetEnabled(stepPage < pages)
  prevPage:SetAlpha(stepPage > 1 and 1 or 0.3); nextPage:SetAlpha(stepPage < pages and 1 or 0.3)
  for i, r in ipairs(stepRows) do
    local s = i <= STEPS_PER and steps[(stepPage - 1) * STEPS_PER + i]
    if s then
      r.icon:SetTexture(s.icon)
      r.title:SetText(s.title)
      r.title:SetTextColor(0.9, 0.91, 0.94)
      r.accent:SetColorTexture(s.r or 1, s.g or 1, s.b or 1, 1)
      r.sub:SetText(s.sub or "")
      r.prof = s.prof
      r:Show()
    else
      r:Hide()
    end
  end
  if #steps == 0 then
    local r = stepRows[1]
    r:Show(); r.icon:SetTexture("Interface\\Icons\\Achievement_Quests_Completed_08")
    r.title:SetText(T("allGood")); r.title:SetTextColor(0.35, 0.9, 0.4); r.sub:SetText(""); r.accent:SetColorTexture(0.35, 0.9, 0.4, 1)
  end
end
function ns.RefreshHome()
  if home:IsVisible() then home:Refresh() end
end

---------------------------------------------------------------------------
-- Alts: a card per character, and the whole account
---------------------------------------------------------------------------
local alts = Page()
ns.HubCustom.alts = alts
local altsHead = ns.Font(alts, true, 14, 1, 1, 1)
altsHead:SetPoint("TOPLEFT", 0, -4)
local altsSub = ns.Font(alts, false, 11, 0.6, 0.62, 0.68)
altsSub:SetPoint("TOPLEFT", altsHead, "BOTTOMLEFT", 0, -4)
local AW = math.floor((CW - 12) / 2)
local AH = 132
local cards = {}
local altOffset = 0
local function AltCard(i)
  if cards[i] then return cards[i] end
  local c = Card(alts)
  c:SetSize(AW, AH)
  c:EnableMouse(true)
  c.class = c:CreateTexture(nil, "ARTWORK")
  c.class:SetSize(36, 36)
  c.class:SetPoint("TOPLEFT", 10, -10)
  c.name = ns.Font(c, true, 13)
  c.name:SetPoint("TOPLEFT", c.class, "TOPRIGHT", 10, -1)
  c.sub = ns.Font(c, false, 10, 0.6, 0.62, 0.68)
  c.sub:SetPoint("TOPLEFT", c.name, "BOTTOMLEFT", 0, -3)
  c.sub:SetPoint("RIGHT", c, "RIGHT", -10, 0)
  c.sub:SetWordWrap(false)
  c.gold = ns.Font(c, true, 12)
  c.gold:SetPoint("TOPRIGHT", -10, -11)
  c.gold:SetJustifyH("RIGHT")
  c.me = ns.Font(c, true, 9, 1, 0.82, 0.3)
  c.me:SetPoint("TOPRIGHT", c.gold, "BOTTOMRIGHT", 0, -4)
  c.profs = {}
  local pw = math.floor((AW - 34) / 2)
  for j = 1, 4 do
    local r = ProfRow(c, pw)
    r:SetPoint("TOPLEFT", 10 + ((j - 1) % 2) * (pw + 14), -54 - math.floor((j - 1) / 2) * PROF_ROW_H)
    c.profs[j] = r
  end
  c.foot = ns.Font(c, false, 9, 0.5, 0.52, 0.56)
  c.foot:SetPoint("BOTTOMLEFT", 10, 8)
  c:SetScript("OnMouseUp", function(self, which)
    if which == "RightButton" and self.key and not self.isMe then
      ns.db.chars[self.key] = nil
      ns.indexDirty = true
      alts:Refresh()
    end
  end)
  c:SetScript("OnEnter", function(self)
    if self.isMe then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(T("rightRemove"), 0.75, 0.77, 0.8)
    GameTooltip:Show()
  end)
  c:SetScript("OnLeave", function() GameTooltip:Hide() end)
  cards[i] = c
  return c
end
alts:EnableMouseWheel(true)
alts:SetScript("OnMouseWheel", function(_, delta)
  altOffset = math.max(0, altOffset - delta * 2)
  alts:Refresh()
end)

local function Ago(t)
  if not t then return "?" end
  local s = time() - t
  if s < 120 then return T("now") end
  if s < 3600 then return T("minAgo", math.floor(s / 60)) end
  if s < 86400 then return T("hAgo", math.floor(s / 3600)) end
  return T("dAgo", math.floor(s / 86400))
end

function alts:Refresh()
  ns.Facts()
  local keys, gold, played = {}, 0, 0
  for key, c in pairs(ns.db.chars) do
    keys[#keys + 1] = key
    gold = gold + (c.money or 0)
    played = played + (ns.Played(c) or 0)
  end
  local _, myKey = ns.Me()
  table.sort(keys, function(a, b)
    if a == myKey then return true elseif b == myKey then return false end
    return (ns.db.chars[a].level or 0) > (ns.db.chars[b].level or 0)
  end)
  altsHead:SetText(T("account"))
  altsSub:SetText(T("accountLine", #keys, ns.Money(gold), ns.PlayedText(played)))
  local perPage = 6
  altOffset = math.min(altOffset, math.max(0, #keys - perPage))
  altOffset = altOffset - altOffset % 2
  for i = 1, math.max(#cards, perPage) do
    local key = keys[altOffset + i]
    local c = AltCard(i)
    if key and i <= perPage then
      local ch = ns.db.chars[key]
      c.key, c.isMe = key, key == myKey
      c:ClearAllPoints()
      c:SetPoint("TOPLEFT", ((i - 1) % 2) * (AW + 12), -44 - math.floor((i - 1) / 2) * (AH + 10))
      ns.ClassIcon(c.class, ch.class)
      local color = ch.class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[ch.class]
      c.name:SetText(ch.name or key)
      c.name:SetTextColor(color and color.r or 1, color and color.g or 1, color and color.b or 1)
      c.sub:SetText(T("levelLine", ch.level or 0, ch.race or "", ch.class and (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[ch.class]) or "")
        .. (ch.zone and ("  ·  " .. ch.zone) or ""))
      c.gold:SetText(ns.Money(ch.money or 0))
      c.me:SetText(c.isMe and string.upper(T("online")) or "")
      local list = SortedProfs(ch.profs)
      for j, r in ipairs(c.profs) do
        local p = list[j]
        if p then
          r.icon:SetTexture(ns.ProfIcon(p.id)); r.name:SetText(ns.ProfName(p.id))
          r.value:SetText(("%d/%d"):format(p.rank, p.max or 300)); r.bar:SetRank(p.rank, p.max)
          r:Show()
        else
          r:Hide()
        end
      end
      local p = ns.Played(ch)
      c.foot:SetText(T("altFoot", p and ns.PlayedText(p) or "?", c.isMe and T("now") or Ago(ch.seen),
        ch.bags and T("bagsFree", ch.bags, ch.bagsTotal or 0) or "?"))
      c:Show()
    else
      c:Hide()
    end
  end
end

---------------------------------------------------------------------------
-- List pages: Specializations, Camping, Cooldowns, Codex materials
---------------------------------------------------------------------------
local function Head(data, text) data[#data + 1] = { head = true, name = text } end

ns.HubBuilders.specs = function(data, state)
  local skills = ns.Skills(true)
  local f = ns.Faction()
  local level = UnitLevel("player") or 0
  for _, profID in ipairs({ 164, 202, 165 }) do
    local s = skills[profID]
    Head(data, ns.ProfName(profID) .. (s and ("  " .. s.rank .. "/" .. (s.max or 300)) or ""))
    for _, spec in ipairs(ns.SPECS[profID]) do
      local have = ns.HasSpell(spec[2])
      local ready = s and s.rank >= spec[4] and level >= spec[3]
      local value, vr, vg, vb
      if have then value, vr, vg, vb = T("learned"), 0.35, 0.9, 0.4
      elseif ready then value, vr, vg, vb = T("canLearn"), 1, 0.82, 0.3
      else value, vr, vg, vb = T("needs", spec[3], spec[4]), 0.6, 0.62, 0.68 end
      data[#data + 1] = {
        icon = ns.ProfIcon(profID), name = spec[1], value = value, vr = vr, vg = vg, vb = vb, indent = 8,
        r = have and 0.35 or 0.85, g = have and 0.9 or 0.87, b = have and 0.4 or 0.9,
        tip = function(tip)
          tip:SetText(spec[1], 1, 0.82, 0.3)
          tip:AddLine(spec.what, 1, 1, 1, true)
          tip:AddLine(T("needs", spec[3], spec[4]), 0.75, 0.77, 0.8)
          tip:AddLine(T("startAt") .. " " .. spec[f], 0.85, 0.87, 0.9, true)
          tip:AddLine(T("oneSpec"), 0.55, 0.58, 0.64, true)
        end,
      }
    end
  end
  state.footer = T("specFoot")
end

ns.HubBuilders.camping = function(data, state)
  local skills = ns.Skills(true)
  local ids = {}
  for _, id in ipairs(ORDER) do if skills[id] then ids[#ids + 1] = id end end
  for _, id in ipairs(ORDER) do if not skills[id] then ids[#ids + 1] = id end end
  for _, id in ipairs(ids) do
    local s = skills[id]
    Head(data, ns.ProfName(id) .. (s and ("  " .. s.rank .. "/" .. (s.max or 300)) or ("  ·  " .. T("notYours"))))
    for _, item in ipairs(ns.CAMP[id] or {}) do
      local ok = s and s.rank >= item[1]
      data[#data + 1] = {
        icon = ns.ProfIcon(id), name = item[2] .. "  |cff8c8f96" .. item[3] .. "|r", indent = 8,
        r = s and 0.85 or 0.5, g = s and 0.87 or 0.52, b = s and 0.9 or 0.56,
        value = ok and T("skillOk", item[1]) or T("skillNeed", item[1]),
        vr = ok and 0.35 or 0.6, vg = ok and 0.9 or 0.62, vb = ok and 0.4 or 0.68,
        tip = function(tip)
          tip:SetText(item[2], 1, 0.82, 0.3)
          tip:AddLine(item[3], 1, 1, 1, true)
          tip:AddDoubleLine(T("skill"), item[1], 0.75, 0.77, 0.8, 1, 1, 1)
          tip:AddLine(T("matsCost") .. ": " .. item[4], 0.85, 0.87, 0.9, true)
          tip:AddLine(item[5], 0.85, 0.87, 0.9, true)
        end,
      }
    end
  end
  state.footer = T("campFoot")
end

local function Left(seconds)
  if seconds <= 0 then return nil end
  local d, h, m = math.floor(seconds / 86400), math.floor(seconds / 3600) % 24, math.floor(seconds / 60) % 60
  if d > 0 then return ("%dd %dh"):format(d, h) end
  if h > 0 then return ("%dh %dm"):format(h, m) end
  return ("%dm"):format(math.max(1, m))
end

ns.HubBuilders.cooldowns = function(data, state)
  pcall(ns.ReadCooldowns)
  local keys = {}
  for key, c in pairs(ns.db.chars) do
    if c.cd and next(c.cd) then keys[#keys + 1] = key end
  end
  table.sort(keys)
  for _, key in ipairs(keys) do
    local c = ns.db.chars[key]
    Head(data, c.name or key)
    for _, entry in ipairs(ns.COOLDOWNS) do
      local cd = c.cd[entry[1]]
      if cd then
        local left = Left(cd.ready - time())
        local icon = entry.icon
        if entry.item then
          local okI, tex = pcall(C_Item and C_Item.GetItemIconByID or GetItemIcon, entry.item)
          if okI and tex then icon = tex end
        end
        data[#data + 1] = {
          icon = icon, name = entry[1], indent = 8,
          value = left or T("ready"), vr = left and 1 or 0.35, vg = left and 1 or 0.9, vb = left and 1 or 0.4,
        }
      end
    end
  end
  state.footer = #keys > 0 and T("cdFoot") or T("noCd")
end

-- where a raw material comes from
local function Where(m)
  if not m[3] then return T("fromMobs") end
  local guide = ns.GATHER[m[3]]
  local base = string.match(m[1], "^(.-) Ore$") or string.match(m[1], "^(.-) Bar$") or m[1]
  local f = ns.Faction()
  for _, step in ipairs(guide.steps) do
    if string.find(step.what, base, 1, true) then
      local how = string.find(m[1], " Bar$") and T("smeltFrom", base) .. "  " or ""
      return how .. ("%s %d-%d: %s"):format(guide.name, step[1], step[2], step[f])
    end
  end
  if m[3] == 393 then return T("skinBeasts") end
  return guide.name
end

ns.HubBuilders.materials = function(data, state)
  local me = ns.Me()
  local current
  for _, m in ipairs(ns.MATERIALS) do
    local group = m[3] and ns.ProfName(m[3]) or T("cloth")
    if group ~= current then Head(data, group); current = group end
    local price = ns.PriceID(m[2], m[1])
    local tracked = ns.db.track[m[1]]
    local mine = not m[3] or (me and me.profs[m[3]])
    local okI, _, _, _, _, icon = pcall(C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant, m[2])
    data[#data + 1] = {
      icon = okI and icon or 134400, name = m[1] .. (tracked and "  |cffffd24a•|r" or ""), indent = 8, item = m[2],
      r = mine and 0.85 or 0.6, g = mine and 0.87 or 0.62, b = mine and 0.9 or 0.66,
      value = price and ns.Money(price) or "",
      hint = Where(m) .. "\n" .. T("rightTrack"),
      click = function(which) if which == "RightButton" then ns.TrackItem(m[1]); ns.RefreshHub() end end,
    }
  end
  state.footer = T("matsFoot")
end

---------------------------------------------------------------------------
-- The route as one bar, 1 to 300: a segment per step (done, now, to come), each step's icon,
-- where you are, where your rank stops you, and where you learn the next ranks
---------------------------------------------------------------------------
local TL_H = 128
local tl = Card(H)
tl:SetPoint("TOPLEFT", X, -58)
tl:SetSize(CW, TL_H)
tl:Hide()
local BX, BW = 16, CW - 32          -- the bar
local BAR_Y = -78                   -- its top, from the card's top
local function Pos(v) return BX + (math.max(1, math.min(300, v)) - 1) / 299 * BW end

local tlName = ns.Font(tl, true, 16, 0.9, 0.91, 0.94)
tlName:SetPoint("TOPLEFT", 14, -12)
local tlRank = ns.Font(tl, false, 10, 0.5, 0.52, 0.57)
tlRank:SetPoint("BOTTOMLEFT", tlName, "BOTTOMRIGHT", 10, 1)
local tlSkill = ns.Font(tl, true, 18, 1, 0.82, 0.29)
tlSkill:SetPoint("BOTTOMLEFT", tlRank, "BOTTOMRIGHT", 10, -2)
local tlAction = ns.Primary(ns.Button(tl, "", 120, 26))
tlAction:SetPoint("TOPRIGHT", -12, -10)
local tlCount = ns.Font(tl, false, 10, 0.55, 0.58, 0.64)
-- between the skill number and the button: never on top of either (cut short with "..." if needed)
tlCount:SetPoint("LEFT", tlSkill, "RIGHT", 12, 0)
tlCount:SetPoint("RIGHT", tlAction, "LEFT", -12, 0)
tlCount:SetJustifyH("RIGHT")
tlCount:SetWordWrap(false)
-- "Learn Expert now" can be clicked: an arrow to the trainer (Places.lua)
local tlTrain = CreateFrame("Button", nil, tl)
tlTrain:SetAllPoints(tlCount)
tlTrain:SetScript("OnEnter", function(self)
  GameTooltip:SetOwner(self, "ANCHOR_TOP")
  GameTooltip:SetText(self.where or "", 1, 0.82, 0.3, 1, true)
  GameTooltip:AddLine((ns.db and ns.db.lang == "da") and "Klik: vis på kortet" or "Click: show on the map", 0.55, 0.58, 0.64)
  GameTooltip:Show()
end)
tlTrain:SetScript("OnLeave", function() GameTooltip:Hide() end)
tlTrain:Hide()

-- opens the profession window (the panel then shows the step with Craft 1 / Craft all)
function ns.OpenProfessionWindow(id)
  local ui = C_TradeSkillUI
  if not (ui and ui.OpenTradeSkill) then ns.Print(T("openFromBook")); return end
  -- the game's profession window is its own addon: load it first, or OpenTradeSkill opens nothing you can see
  local loaded = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
  local load = (C_AddOns and C_AddOns.LoadAddOn) or LoadAddOn
  if loaded and load and not loaded("Blizzard_Professions") then pcall(load, "Blizzard_Professions") end
  -- already open on another profession: close it first so the new one shows
  if ns.ProfessionFrame() and ui.CloseTradeSkill then pcall(ui.CloseTradeSkill) end
  local ok = pcall(ui.OpenTradeSkill, id)
  -- check it really opened (Forever can accept the call and still show nothing)
  C_Timer.After(0.5, function()
    if not ns.ProfessionFrame() then ns.Print(T("openFromBook")) end
  end)
  if not ok then return end
end

local barBg = tl:CreateTexture(nil, "BACKGROUND")
barBg:SetPoint("TOPLEFT", BX, BAR_Y)
barBg:SetSize(BW, 10)
barBg:SetColorTexture(1, 1, 1, 0.05)

local segs, icons, ticks = {}, {}, {}
local function Seg(i)
  local s = segs[i]
  if s then return s end
  s = CreateFrame("Frame", nil, tl)
  s:SetHeight(10)
  s.base = s:CreateTexture(nil, "ARTWORK")
  s.base:SetAllPoints()
  s.fill = s:CreateTexture(nil, "OVERLAY")
  s.fill:SetPoint("TOPLEFT"); s.fill:SetPoint("BOTTOMLEFT")
  s.fill:SetColorTexture(0.3, 0.72, 0.4, 1)
  s:EnableMouse(true)
  s:SetScript("OnEnter", function(self)
    local d = self.data and self.data[self.index]
    if d and d.tip then
      GameTooltip:SetOwner(self, "ANCHOR_TOP")
      d.tip(GameTooltip)
      GameTooltip:Show()
    end
  end)
  s:SetScript("OnLeave", function() GameTooltip:Hide() end)
  segs[i] = s
  return s
end
local function Icon(i)
  local t = icons[i]
  if t then return t end
  t = CreateFrame("Frame", nil, tl)
  t:SetSize(20, 20)
  t.tex = t:CreateTexture(nil, "ARTWORK")
  t.tex:SetAllPoints()
  t.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  t:EnableMouse(true)
  t:SetScript("OnEnter", segs[1] and segs[1]:GetScript("OnEnter") or nil)
  t:SetScript("OnLeave", function() GameTooltip:Hide() end)
  icons[i] = t
  return t
end
local function Tick(i)
  local k = ticks[i]
  if k then return k end
  k = {}
  k.line = tl:CreateTexture(nil, "OVERLAY")
  k.line:SetSize(1, 16)
  k.text = ns.Font(tl, false, 9)
  ticks[i] = k
  return k
end

-- where you are: a line through the bar and the number over it
local now = tl:CreateTexture(nil, "OVERLAY", nil, 2)
now:SetSize(2, 18)
now:SetColorTexture(1, 1, 1, 0.95)
local badge = CreateFrame("Frame", nil, tl)
badge:SetSize(34, 16)
badge:SetFrameLevel(tl:GetFrameLevel() + 6)
local badgeBg = badge:CreateTexture(nil, "BACKGROUND")
badgeBg:SetAllPoints()
badgeBg:SetColorTexture(1, 0.82, 0.3, 1)
local badgeText = ns.Font(badge, true, 10, 0.08, 0.08, 0.1)
badgeText:SetPoint("CENTER")
badgeText:SetShadowOffset(0, 0)
-- where your rank stops you
local cap = tl:CreateTexture(nil, "OVERLAY", nil, 1)
cap:SetSize(2, 18)
cap:SetColorTexture(1, 0.42, 0.32, 1)
local capText = ns.Font(tl, true, 9, 1, 0.42, 0.32)
local axis = {}
for i, v in ipairs({ 1, 75, 150, 225, 300 }) do
  local a = ns.Font(tl, false, 9, 0.42, 0.44, 0.48)
  a:SetPoint("TOP", tl, "TOPLEFT", Pos(v), BAR_Y - 30)
  a:SetText(v)
  axis[v] = a
end

local RANK_NAMES = { [75] = "Apprentice", [150] = "Journeyman", [225] = "Expert", [300] = "Artisan" }

function ns.ShowTimeline(id, guide, skill, current, data, below)
  tl:ClearAllPoints()
  tl:SetPoint("TOPLEFT", X, -58 - (below or 0))
  local rank = skill and skill.rank or 0
  local max = skill and skill.max or 0
  tlName:SetText(guide.name)
  tlRank:SetText(skill and (RANK_NAMES[max] or "") or T("notYours"))
  local near = skill and max < 300 and max - rank <= 10
  tlSkill:SetText(skill and ("%d / %d"):format(rank, max) or "")
  tlSkill:SetTextColor(near and 1 or 1, near and 0.42 or 0.82, near and 0.32 or 0.3)
  -- (not "skill and ns.TrainNow(...)": "and" keeps only the first of its three results)
  local train, rankName, where
  if skill then train, rankName, where = ns.TrainNow(id, rank, max) end
  if train then
    -- short here: the trainer and price stand right under the bar
    tlCount:SetText("|cffffd24a" .. T("trainShort", rankName) .. "  |TInterface\\Icons\\INV_Misc_Map_01:12|t|r")
    tlTrain.where = where
    tlTrain:SetScript("OnClick", function() ns.ShowTrainer(id) end)
    tlTrain:Show()
  else
    tlCount:SetText(T("steps", #guide.steps))
    tlTrain:Hide()
  end
  -- the button on the bar: craft for a crafting profession, start farming for a gathering one
  if skill and rank < 300 and ns.GUIDES[id] then
    tlAction:SetText(T("craftNow"))
    tlAction:SetScript("OnClick", function()
      -- the window is already open on this profession: craft the step right away, like the panel's button
      local st = ns.panelState or {}
      if ns.ProfessionFrame() and st.prof == id and st.job then
        ns.Craft(st.job.name, st.job.count)
      else
        ns.OpenProfessionWindow(id)
      end
    end)
    tlAction:Show()
  else
    tlAction:Hide()
  end
  -- segments
  local lastIconX, row = -100, 0
  for i, s in ipairs(guide.steps) do
    local seg = Seg(i)
    local x1, x2 = Pos(s[1]), Pos(s[2])
    seg:ClearAllPoints()
    seg:SetPoint("TOPLEFT", tl, "TOPLEFT", x1, BAR_Y)
    seg:SetWidth(math.max(2, x2 - x1 - 1))
    seg.data, seg.index = data, i
    if rank >= s[2] then
      seg.base:SetColorTexture(0.3, 0.72, 0.4, 1); seg.fill:Hide()
    elseif i == current then
      seg.base:SetColorTexture(0.55, 0.42, 0.15, 1)
      local w = (rank - s[1]) / math.max(1, s[2] - s[1]) * (x2 - x1 - 1)
      seg.fill:SetShown(w > 0.5); seg.fill:SetWidth(math.max(1, w))
    else
      seg.base:SetColorTexture(0.27, 0.22, 0.11, 1); seg.fill:Hide()
    end
    seg:Show()
    -- the step's icon over its start, a second row when two are close
    local ic = Icon(i)
    ic:SetScript("OnEnter", seg:GetScript("OnEnter"))
    ic.data, ic.index = data, i
    -- one row of icons; a step too close to the last icon shown gets none (its segment still has the tooltip)
    local fits = x1 - lastIconX >= 22
    if fits then lastIconX = x1 end
    ic:ClearAllPoints()
    ic:SetPoint("BOTTOMLEFT", tl, "TOPLEFT", x1, BAR_Y + 4)
    local entry = ns.GUIDES[id] and (ns.Chosen(id, i, s))[1]
    ic.tex:SetTexture(entry and ns.ItemIcon(entry[1], ns.ProfIcon(id)) or guide.icon or ns.ProfIcon(id))
    ic.tex:SetDesaturated(rank >= s[2])
    ic:SetAlpha(rank >= s[2] and 0.55 or 1)
    ic:SetShown(fits)
  end
  for i = #guide.steps + 1, #segs do segs[i]:Hide(); icons[i]:Hide() end
  -- where you learn the next ranks
  for i, r in ipairs(guide.ranks) do
    local k = Tick(i)
    local learned = max > r.at
    local nextOne = not learned and max == r.at
    local col = learned and { 0.42, 0.44, 0.48 } or (nextOne and { 1, 0.82, 0.3 } or { 0.65, 0.5, 0.3 })
    k.line:ClearAllPoints()
    k.line:SetPoint("TOP", tl, "TOPLEFT", Pos(r.need), BAR_Y + 3)
    k.line:SetColorTexture(col[1], col[2], col[3], 0.9)
    k.text:ClearAllPoints()
    k.text:SetPoint("TOP", tl, "TOPLEFT", Pos(r.need), BAR_Y - 14)
    k.text:SetText(RANK_NAMES[r.at + 75] or "")
    k.text:SetTextColor(col[1], col[2], col[3])
    k.line:Show(); k.text:Show()
  end
  for i = #guide.ranks + 1, #ticks do ticks[i].line:Hide(); ticks[i].text:Hide() end
  -- you, and your cap
  if skill then
    now:ClearAllPoints(); now:SetPoint("TOP", tl, "TOPLEFT", Pos(rank), BAR_Y + 4); now:Show()
    badge:ClearAllPoints(); badge:SetPoint("BOTTOM", tl, "TOPLEFT", Pos(rank), BAR_Y + 3); badge:Show()
    badgeText:SetText(rank)
    if max < 300 then
      cap:ClearAllPoints(); cap:SetPoint("TOP", tl, "TOPLEFT", Pos(max), BAR_Y + 4); cap:Show()
      capText:ClearAllPoints(); capText:SetPoint("TOP", tl, "TOPLEFT", Pos(max), BAR_Y - 30)
      capText:SetText(T("yourCap", max)); capText:Show()
    else
      cap:Hide(); capText:Hide()
    end
  else
    now:Hide(); badge:Hide(); cap:Hide(); capText:Hide()
  end
  for v, a in pairs(axis) do a:SetShown(not (skill and max < 300 and math.abs(v - max) < 30)) end
  tl:Show()
  return TL_H
end

function ns.HideTimeline() tl:Hide() end

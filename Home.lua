-- CraftETA: the Home and Alts pages of the main window, and the smaller list pages
-- (Specializations, Camping, Cooldowns, Codex materials).
local _, ns = ...
local T = ns.T

local H, X, CW = ns.Hub, ns.HUB_X, ns.HUB_CW

local function L(en, da) return (ns.db and ns.db.lang == "da") and da or en end

local function Card(parent)
  local f = CreateFrame("Frame", nil, parent)
  -- the same flat card as the step in the profession panel: no edges, a shade lighter than the window,
  -- rounded like every box in the ETA family
  f.bg = ns.RoundBox(f, 0.086, 0.094, 0.122, 1)
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
  r.value = ns.Font(r, true, 9, 0.75, 0.77, 0.8)
  r.value:SetPoint("BOTTOMRIGHT", 0, -1)
  r.value:SetJustifyH("RIGHT")
  r.name = ns.Font(r, false, 10)
  r.name:SetPoint("TOPLEFT", r.icon, "TOPRIGHT", 7, -1)
  r.name:SetPoint("RIGHT", r, "RIGHT", 0, 0)
  r.name:SetWordWrap(false)
  r.bar = MiniBar(r, width - 27 - 46)
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
            local entry = ns.StepEntry(id, i, step, rank)
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
  local line = ns.Round(f, "BORDER", 0, nil, true)
  line:SetAllPoints(f)
  line:SetColorTexture(r, g, b, a or 1)
  return line
end
local function Tip(frame, fn)
  frame:EnableMouse(true)
  frame:SetScript("OnEnter", function(self) GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); fn(GameTooltip, self); GameTooltip:Show() end)
  frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

---------------------------------------------------------------------------
-- The next step: one big card with what to do now, chosen by CraftETA: a trainer that stops you,
-- else the step of the profession you work on (the open window's, the last one, or the first)
---------------------------------------------------------------------------
local RANK_NAME = { [75] = "Journeyman", [150] = "Expert", [225] = "Artisan" }

local hero = Card(home)
hero:SetPoint("TOPLEFT"); hero:SetPoint("RIGHT"); hero:SetHeight(132)
Edge(hero, 0.43, 0.35, 0.13)
local heroIcon = hero:CreateTexture(nil, "ARTWORK")
heroIcon:SetSize(60, 60); heroIcon:SetPoint("LEFT", 18, 0); heroIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
local heroLabel = ns.Font(hero, true, 10, 1, 0.82, 0.29)
heroLabel:SetPoint("TOPLEFT", heroIcon, "TOPRIGHT", 16, 4)
local heroTitle = ns.Font(hero, true, 18, 0.95, 0.96, 0.98)
heroTitle:SetPoint("TOPLEFT", heroLabel, "BOTTOMLEFT", 0, -7); heroTitle:SetPoint("RIGHT", hero, "RIGHT", -186, 0)
heroTitle:SetWordWrap(false)
local heroSub = ns.Font(hero, false, 12, 0.66, 0.68, 0.73)
heroSub:SetPoint("TOPLEFT", heroTitle, "BOTTOMLEFT", 0, -6); heroSub:SetPoint("RIGHT", hero, "RIGHT", -186, 0)
heroSub:SetWordWrap(true); heroSub:SetMaxLines(2); heroSub:SetJustifyH("LEFT")
local HB_W = CW - 18 - 60 - 16 - 186   -- the bar's width: from after the icon to before the buttons
local heroBar = CreateFrame("Frame", nil, hero)
heroBar:SetHeight(6); heroBar:SetPoint("BOTTOMLEFT", heroIcon, "BOTTOMRIGHT", 16, -12); heroBar:SetPoint("RIGHT", hero, "RIGHT", -186, 0)
local heroBarBg = heroBar:CreateTexture(nil, "BACKGROUND"); heroBarBg:SetAllPoints(); heroBarBg:SetColorTexture(1, 1, 1, 0.08)
local heroFill = heroBar:CreateTexture(nil, "ARTWORK"); heroFill:SetPoint("TOPLEFT"); heroFill:SetPoint("BOTTOMLEFT")
heroFill:SetColorTexture(1, 0.82, 0.3, 1)
local heroBtn = ns.Primary(ns.Button(hero, "", 152, 34), 13)
heroBtn:SetPoint("TOPRIGHT", -18, -30)
local heroBtn2 = ns.Button(hero, "", 152, 24)
heroBtn2:SetPoint("TOP", heroBtn, "BOTTOM", 0, -8)

---------------------------------------------------------------------------
-- Three small cards under it: shopping, the next trainer, and a heads-up (or what to keep for later)
---------------------------------------------------------------------------
local SMALL_W = math.floor((CW - 2 * 10) / 3)
local small = {}
for i = 1, 3 do
  local s = CreateFrame("Button", nil, home)
  s:SetSize(SMALL_W, 96)
  s:SetPoint("TOPLEFT", (i - 1) * (SMALL_W + 10), -142)
  ns.RoundBox(s, 0.086, 0.094, 0.122, 1)
  local hl = ns.Round(s, "HIGHLIGHT", 0); hl:SetAllPoints(); hl:SetColorTexture(1, 1, 1, 0.03)
  s.icon = s:CreateTexture(nil, "ARTWORK"); s.icon:SetSize(30, 30); s.icon:SetPoint("TOPLEFT", 14, -14)
  s.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  s.label = ns.Font(s, true, 9, 0.55, 0.58, 0.64); s.label:SetPoint("TOPLEFT", s.icon, "TOPRIGHT", 10, -1)
  s.label:SetPoint("RIGHT", s, "RIGHT", -10, 0); s.label:SetWordWrap(false)
  s.title = ns.Font(s, true, 14, 0.92, 0.93, 0.96); s.title:SetPoint("TOPLEFT", s.label, "BOTTOMLEFT", 0, -5)
  s.title:SetPoint("RIGHT", s, "RIGHT", -10, 0); s.title:SetWordWrap(true); s.title:SetMaxLines(2); s.title:SetJustifyH("LEFT")
  s.sub = ns.Font(s, false, 11, 0.66, 0.68, 0.73); s.sub:SetPoint("TOPLEFT", s.icon, "BOTTOMLEFT", 0, -10)
  s.sub:SetPoint("RIGHT", s, "RIGHT", -12, 0); s.sub:SetJustifyH("LEFT"); s.sub:SetWordWrap(true); s.sub:SetMaxLines(2)
  s:SetScript("OnClick", function(self) if self.click then self.click() end end)
  small[i] = s
end
local function Small(i, icon, label, title, sub, click, lr, lg, lb)
  local s = small[i]
  s.icon:SetTexture(icon)
  s.label:SetText(string.upper(label or ""))
  s.label:SetTextColor(lr or 0.55, lg or 0.58, lb or 0.64)
  s.title:SetText(title or "")
  -- a long title takes two lines ("You can become a Tribal Leatherworker"): the line under it moves down
  local two = (s.title:GetStringHeight() or 0) > 20
  s.sub:ClearAllPoints()
  s.sub:SetPoint("TOPLEFT", s, "TOPLEFT", 14, two and -68 or -54)
  s.sub:SetPoint("RIGHT", s, "RIGHT", -12, 0)
  s.sub:SetMaxLines(two and 1 or 2)
  s.sub:SetText(sub or "")
  s.click = click
end

---------------------------------------------------------------------------
-- Your professions, full width
---------------------------------------------------------------------------
local COLW = CW
local profCard = Card(home)
profCard:SetPoint("TOPLEFT", 0, -248); profCard:SetPoint("BOTTOMRIGHT")
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
  r.rank = ns.Font(r, false, 10, 0.55, 0.58, 0.64); r.rank:SetPoint("LEFT", r.name, "RIGHT", 6, 0)
  r.bar = CreateFrame("Frame", nil, r); r.bar:SetSize(BAR_W, 6)
  r.bar:SetPoint("BOTTOMLEFT", r.icon, "BOTTOMRIGHT", 8, 2)
  r.bg = r.bar:CreateTexture(nil, "BACKGROUND"); r.bg:SetAllPoints(); r.bg:SetColorTexture(1, 1, 1, 0.07)
  r.cap = r.bar:CreateTexture(nil, "BORDER"); r.cap:SetPoint("TOPLEFT"); r.cap:SetPoint("BOTTOMLEFT"); r.cap:SetColorTexture(1, 1, 1, 0.07)
  r.fill = r.bar:CreateTexture(nil, "ARTWORK"); r.fill:SetPoint("TOPLEFT"); r.fill:SetPoint("BOTTOMLEFT")
  r.segs = {}
  local hl = ns.Round(r, "HIGHLIGHT", 0); hl:SetPoint("TOPLEFT", -6, 2); hl:SetPoint("BOTTOMRIGHT", 6, -2); hl:SetColorTexture(1, 1, 1, 0.03)
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

-- the profession the big card is about
local function MainProf(skills)
  local open = ns.OpenProfession and ns.OpenProfession()
  if open and skills[open.id] then return open.id end
  local last = ns.db.lastProf and skills[ns.db.lastProf]
  if last and last.rank < 300 then return ns.db.lastProf end
  local list = SortedProfs(skills)
  for _, p in ipairs(list) do if p.rank < 300 and ns.GUIDES[p.id] then return p.id end end
  for _, p in ipairs(list) do if p.rank < 300 then return p.id end end
  return list[1] and list[1].id or nil
end

local function ShopCost(items)
  local n, cost, names = 0, 0, {}
  for _, item in ipairs(items) do
    if item.still > 0 then
      n = n + 1
      if #names < 3 then names[#names + 1] = item.name end
      local c
      if item.vendor and ns.VendorCost then
        local v = ns.VendorCost(item.name); c = v and v * item.still
      end
      if not c and ns.BuyCost then local ok, v = pcall(ns.BuyCost, item.name, item.still); c = ok and v or nil end
      if not c then local p = ns.Price(item.name); c = p and p * item.still end
      cost = cost + (c or 0)
    end
  end
  return n, cost, names
end

local function FillHero(skills)
  heroBtn2:Hide(); heroBar:Show(); heroBtn:Show()
  heroBtn:SetScript("OnClick", nil); heroBtn2:SetScript("OnClick", nil)
  local id = MainProf(skills)
  if not id then
    heroIcon:SetTexture(134400); heroLabel:SetText("")
    heroTitle:SetText(T("noProfs")); heroSub:SetText(L("Learn a profession at a trainer, and CraftETA shows the way to 300.", "Lær et fag hos en træner, så viser CraftETA vejen til 300."))
    heroBar:Hide(); heroBtn:Hide()
    return id
  end
  local s = skills[id]
  local rank, max = s.rank, s.max or 300
  local guide = ns.GUIDES[id] or ns.GATHER[id]
  local f = ns.Faction()
  heroLabel:SetText(L("NEXT STEP", "NÆSTE SKRIDT") .. "  ·  " .. string.upper(ns.ProfName(id)) .. "  " .. rank .. " / " .. max)
  local idx = ns.StepIndex(guide, rank)
  local step = idx and guide.steps[idx]
  local train, rankName, where = ns.TrainNow(id, rank, max)
  if rank >= 300 or not step then
    heroIcon:SetTexture("Interface\\Icons\\Achievement_Quests_Completed_08")
    heroTitle:SetText(L("%s is done: 300", "%s er færdig: 300"):format(ns.ProfName(id)))
    heroSub:SetText(L("Pick another profession below.", "Vælg et andet fag nedenfor."))
    heroFill:SetWidth(HB_W)
    heroBtn:Hide()
  elseif train then
    local lvl = UnitLevel("player") or 0
    heroIcon:SetTexture(ns.ProfIcon(id))
    heroTitle:SetText(T("trainNow", rankName, guide.name))
    heroSub:SetText(T("trainWhere", where) .. (lvl < (train.lvl or 0) and ("  ·  " .. T("trainLevel", train.lvl)) or ""))
    heroFill:SetWidth(math.max(1, HB_W * math.min(1, rank / math.max(1, max))))
    heroBtn:SetText(L("Show on map", "Vis på kortet"))
    heroBtn:SetScript("OnClick", function() ns.ShowTrainer(id) end)
  elseif ns.GUIDES[id] then
    local entry, left, _, fix = ns.StepEntry(id, idx, step, rank)
    heroIcon:SetTexture(ns.ItemIcon(entry[1], ns.ProfIcon(id)))
    heroTitle:SetText(L("Craft %d %s", "Lav %d %s"):format(left, entry[1]))
    local nxt = guide.steps[idx + 1]
    local nextName = nxt and ((ns.Chosen(id, idx + 1, nxt))[1] or {})[1]
    if fix then
      heroSub:SetText("|cffffb060" .. T("fixShort", fix.short, fix.name, fix.forName) .. "|r")
    else
      -- "Then ..." only when the next step makes something else
      local thenText = nextName and nextName ~= entry[1] and (" " .. L("Then %s.", "Så %s."):format(nextName)) or ""
      heroSub:SetText(L("Up to %d.", "Op til %d."):format(step[2]) .. thenText .. (step.note and ("  " .. step.note) or ""))
    end
    local span = math.max(1, step[2] - step[1])
    heroFill:SetWidth(math.max(1, HB_W * math.min(1, math.max(0, rank - step[1]) / span)))
    local st = ns.panelState or {}
    local ready = ns.ProfessionFrame and ns.ProfessionFrame() and st.prof == id and st.job
    heroBtn:SetText(ready and T("craftN", st.job.count) or L("Open %s", "Åbn %s"):format(guide.name))
    heroBtn:SetScript("OnClick", function()
      local j = ns.panelState or {}
      if ns.ProfessionFrame() and j.prof == id and j.job then ns.Craft(j.job.name, j.job.count) else ns.OpenProfessionWindow(id) end
    end)
    -- what you are missing for the crafts that are left
    local per = ns.MatsPerCraft and ns.MatsPerCraft(entry) or {}
    local miss, firstName, firstN = 0, nil, 0
    for m = 1, #per, 2 do
      local short = per[m + 1] * left - ns.Have(per[m])
      if short > 0 then
        miss = miss + 1
        if not firstName then firstName, firstN = per[m], short end
      end
    end
    if miss > 0 then
      -- short enough for the button: the count and the item's icon; the name is in the tooltip
      local icon = ns.ItemIcon(firstName, 134400)
      heroBtn2:SetText(miss == 1 and (L("Missing %d", "Mangler %d"):format(firstN) .. "  |T" .. icon .. ":14:14:0:0:64:64:5:59:5:59|t")
        or L("Missing %d things", "Mangler %d ting"):format(miss))
      local names = {}
      for m = 1, #per, 2 do
        local short = per[m + 1] * left - ns.Have(per[m])
        if short > 0 then names[#names + 1] = short .. " " .. per[m] end
      end
      heroBtn2.tip = table.concat(names, "\n") .. "\n\n" .. L("Click: put them on the shopping list", "Klik: læg dem på indkøbslisten")
      heroBtn2:SetScript("OnClick", function()
        ns.AddToList(nil, nil, id, step[2])
        ns.Print(T("addedList") .. " (" .. rank .. " - " .. step[2] .. ")")
        if not (ns.ListShown and ns.ListShown()) then ns.ToggleList() end
      end)
      heroBtn2:Show()
    end
  else
    heroIcon:SetTexture(guide.icon or ns.ProfIcon(id))
    heroTitle:SetText(step.what or "")
    heroSub:SetText(step[f] or "")
    local span = math.max(1, step[2] - step[1])
    heroFill:SetWidth(math.max(1, HB_W * math.min(1, math.max(0, rank - step[1]) / span)))
    heroBtn:SetText(L("Open the guide", "Åbn guiden"))
    heroBtn:SetScript("OnClick", function() ns.hubState.guide = id; ns.ToggleHub("guide") end)
  end
  return id
end

local function FillSmall(skills, id)
  -- 1: shopping
  local okL, items = pcall(ns.ListItems)
  local n, cost, names = ShopCost(okL and items or {})
  Small(1, "Interface\\Icons\\INV_Misc_Note_05", L("Shopping", "Indkøb"),
    n > 0 and (L("%d to buy", "%d at købe"):format(n) .. "  ·  " .. ns.Money(cost)) or L("Nothing to buy", "Intet at købe"),
    n > 0 and table.concat(names, ", ") or L("Add a step with + in the profession panel.", "Læg et trin på med + i profession-panelet."),
    function() ns.ToggleList() end)
  -- 2: the next trainer
  local s = id and skills[id]
  local r = s and ns.NextRank(id, s.rank, s.max or 300)
  if r then
    local who = r[ns.Faction()] or ""
    Small(2, ns.ProfIcon(id), L("Next stop", "Næste stop") .. "  ·  " .. r.at,
      L("Train %s", "Træn %s"):format(RANK_NAME[r.at] or ""), who .. ((r.lvl or 0) > 0 and ("  ·  " .. L("level %d", "level %d"):format(r.lvl)) or ""),
      function() ns.ShowTrainer(id) end, 1, 0.69, 0.38)
  else
    Small(2, "Interface\\Icons\\INV_Misc_Book_11", L("Next stop", "Næste stop"),
      L("No trainer needed", "Ingen træner nødvendig"), L("You can level all the way.", "Du kan levle hele vejen."), nil)
  end
  -- 3: a heads-up (repair, bags, a cooldown that is ready, a specialization), else what to keep for later
  for _, st in ipairs(ns.NextSteps()) do
    if not st.prof then
      Small(3, st.icon, L("Heads up", "Obs"), st.title, st.sub, nil, st.r, st.g, st.b)
      return
    end
  end
  local keep, kn = {}, 0
  if ns.LaterUse then
    for name, u in pairs(ns.LaterUse()) do
      if u.prof and not u.now then
        local iid = ns.ItemID(name)
        if iid and ns.BagCount and ns.BagCount(iid) > 0 then
          kn = kn + 1
          if #keep < 3 then keep[#keep + 1] = name end
        end
      end
    end
  end
  if kn > 0 then
    Small(3, "Interface\\Icons\\INV_Misc_Bag_08", L("Keep for later", "Gem til senere"),
      L("%d in your bags", "%d i tasken"):format(kn), table.concat(keep, ", ") .. ". " .. L("Bank them at the bank.", "Bank dem i banken."), nil)
    return
  end
  -- your next cooldown
  local me = ns.Me()
  local best
  for name, cd in pairs(me and me.cd or {}) do
    if not best or (cd.ready or 0) < best.ready then best = { name = name, ready = cd.ready or 0 } end
  end
  if best then
    local secs = best.ready - time()
    Small(3, "Interface\\Icons\\INV_Misc_PocketWatch_01", L("Cooldown", "Cooldown"), best.name,
      secs > 0 and L("Ready in %s", "Klar om %s"):format(ns.Duration(secs) or "") or L("Ready now", "Klar nu"),
      function() ns.ToggleHub("cooldowns") end)
  else
    Small(3, "Interface\\Icons\\INV_Misc_Coin_02", L("Gold", "Guld"), ns.Money(GetMoney()), "", function() ns.ToggleHub("gold") end)
  end
end

function home:Refresh()
  ns.Facts()
  local skills = ns.Skills(true)
  local id = FillHero(skills)
  FillSmall(skills, id)
  -- professions
  profLabel:SetText(string.upper(L("Your professions", "Dine fag")))
  local list = SortedProfs(skills)
  local room = math.max(1, math.floor(((profCard:GetHeight() or 330) - 36) / PROF_H))
  for _, r in ipairs(profRows) do r:Hide() end
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
  c.me:SetPoint("LEFT", c.name, "RIGHT", 8, 0)
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
  s.hl = s:CreateTexture(nil, "HIGHLIGHT"); s.hl:SetPoint("TOPLEFT", 0, 3); s.hl:SetPoint("BOTTOMRIGHT", 0, -3)
  s.hl:SetColorTexture(1, 1, 1, 0.3)
  s:SetScript("OnEnter", function(self)
    local d = self.data and self.data[self.index]
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    if d and d.tip then
      d.tip(GameTooltip)
    elseif self.step then
      -- the step itself: what to make, its materials, and where you are
      local st, id, rank = self.step, self.prof, self.rank or 0
      local done, here = rank >= st[2], rank >= st[1] and rank < st[2]
      GameTooltip:SetText(("%d - %d"):format(st[1], st[2]), here and 1 or 0.85, here and 0.82 or 0.87, here and 0.3 or 0.9)
      if ns.GUIDES[id] then
        local entry = (ns.Chosen(id, self.index, st))[1]
        GameTooltip:AddLine(L("Craft %d %s", "Lav %d %s"):format(entry[2], entry[1]), 1, 1, 1)
        local mats = entry[3]
        for m = 1, #mats, 2 do
          local have = ns.Have(mats[m])
          GameTooltip:AddDoubleLine(mats[m + 1] .. " x " .. mats[m], have > 0 and (L("have ", "har ") .. have) or "",
            0.6, 0.62, 0.67, 0.45, 0.85, 0.5)
        end
      else
        GameTooltip:AddLine(st.what or "", 1, 1, 1, true)
        local f = ns.Faction()
        if st[f] then GameTooltip:AddLine(st[f], 0.6, 0.62, 0.67, true) end
      end
      if st.note then GameTooltip:AddLine(st.note, 0.78, 0.72, 0.58, true) end
      if done then GameTooltip:AddLine(L("Done", "Klaret"), 0.35, 0.9, 0.4)
      elseif here then GameTooltip:AddLine(L("You are here", "Du er her"), 1, 0.82, 0.3) end
    end
    GameTooltip:Show()
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
local badgeBg = ns.Round(badge, "BACKGROUND", 0, 4)
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
    seg.step, seg.prof, seg.rank = s, id, rank
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
    ic.step, ic.prof, ic.rank = s, id, rank
    -- one row of icons; a step too close to the last icon shown gets none (its segment still has the tooltip)
    local fits = x1 - lastIconX >= 22
    if fits then lastIconX = x1 end
    ic:ClearAllPoints()
    ic:SetPoint("BOTTOMLEFT", tl, "TOPLEFT", x1, BAR_Y + 4)
    local entry = ns.GUIDES[id] and (ns.Chosen(id, i, s))[1]
    ic.tex:SetTexture(entry and ns.ItemIcon(entry[1], ns.ProfIcon(id)) or guide.icon or ns.ProfIcon(id))
    ic.tex:SetDesaturated(rank >= s[2])
    ic:SetAlpha(rank >= s[2] and 0.55 or 1)
    -- the badge with your skill sits above the bar: no icon under it
    local underBadge = skill and x1 + 20 > Pos(rank) - 19 and x1 < Pos(rank) + 19
    ic:SetShown(fits and not underBadge)
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

---------------------------------------------------------------------------
-- Cooldowns: a card per character, a bar toward ready, and when it is ready
---------------------------------------------------------------------------
local cdPage = Page()
ns.HubCustom.cooldowns = cdPage
local cdHead = ns.Font(cdPage, true, 14, 1, 1, 1)
cdHead:SetPoint("TOPLEFT", 0, -4)
local cdSub = ns.Font(cdPage, false, 11, 0.6, 0.62, 0.68)
cdSub:SetPoint("TOPLEFT", cdHead, "BOTTOMLEFT", 0, -4)
local cdEmpty = ns.Font(cdPage, false, 11, 0.6, 0.62, 0.67)
cdEmpty:SetPoint("TOPLEFT", 0, -60); cdEmpty:SetWidth(CW)
cdEmpty:SetWordWrap(true); cdEmpty:SetJustifyH("LEFT")
local cdFoot = ns.Font(cdPage, false, 10, 0.45, 0.47, 0.52)
cdFoot:SetPoint("BOTTOMLEFT", 0, 0)
local CDW = math.floor((CW - 12) / 2)
local cdCards = {}

local function Span(seconds)
  local d, h, m = math.floor(seconds / 86400), math.floor(seconds / 3600) % 24, math.floor(seconds / 60) % 60
  if d > 0 then return ("%dd %dh"):format(d, h) end
  if h > 0 then return ("%dh %dm"):format(h, m) end
  return ("%dm"):format(math.max(1, m))
end

local function CdCard(i)
  if cdCards[i] then return cdCards[i] end
  local c = Card(cdPage)
  c:SetWidth(CDW)
  c.mark = c:CreateTexture(nil, "BORDER")
  c.mark:SetPoint("TOPLEFT"); c.mark:SetPoint("BOTTOMLEFT"); c.mark:SetWidth(2); c.mark:SetAlpha(0)
  c.mark:SetColorTexture(1, 0.82, 0.3, 1)
  c.class = c:CreateTexture(nil, "ARTWORK")
  c.class:SetSize(26, 26); c.class:SetPoint("TOPLEFT", 14, -12)
  c.name = ns.Font(c, true, 13, 0.9, 0.91, 0.94); c.name:SetPoint("TOPLEFT", c.class, "TOPRIGHT", 10, 1)
  c.sub = ns.Font(c, false, 10, 0.55, 0.58, 0.64); c.sub:SetPoint("TOPLEFT", c.name, "BOTTOMLEFT", 0, -2)
  c.rows = {}
  cdCards[i] = c
  return c
end

local function CdRow(c, j)
  if c.rows[j] then return c.rows[j] end
  local r = CreateFrame("Frame", nil, c)
  r:SetPoint("TOPLEFT", 14, -(52 + (j - 1) * 50))
  r:SetPoint("TOPRIGHT", -14, -(52 + (j - 1) * 50))
  r:SetHeight(44)
  r.icon = r:CreateTexture(nil, "ARTWORK")
  r.icon:SetSize(32, 32); r.icon:SetPoint("TOPLEFT", 0, 0); r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  r.name = ns.Font(r, true, 11, 0.9, 0.91, 0.94); r.name:SetPoint("TOPLEFT", r.icon, "TOPRIGHT", 9, 0)
  r.state = ns.Font(r, true, 11, 1, 1, 1); r.state:SetPoint("TOPRIGHT", 0, 0); r.state:SetJustifyH("RIGHT")
  r.when = ns.Font(r, false, 9, 0.5, 0.52, 0.57); r.when:SetPoint("TOPLEFT", r.name, "BOTTOMLEFT", 0, -3)
  r.bg = r:CreateTexture(nil, "BACKGROUND"); r.bg:SetPoint("BOTTOMLEFT", 0, 0); r.bg:SetPoint("BOTTOMRIGHT", 0, 0); r.bg:SetHeight(5)
  r.bg:SetColorTexture(1, 1, 1, 0.08)
  r.fill = r:CreateTexture(nil, "ARTWORK"); r.fill:SetPoint("BOTTOMLEFT", 0, 0); r.fill:SetHeight(5)
  c.rows[j] = r
  return r
end

function cdPage:Refresh()
  pcall(ns.ReadCooldowns)
  local now = time()
  local keys = {}
  for key, ch in pairs(ns.db.chars) do
    if ch.cd and next(ch.cd) then keys[#keys + 1] = key end
  end
  table.sort(keys, function(a, b)
    local ca, cb = ns.db.chars[a], ns.db.chars[b]
    return (ca.name or a) < (cb.name or b)
  end)
  cdHead:SetText(L("Cooldowns", "Cooldowns"))
  local ready, running = 0, 0
  for _, c in ipairs(cdCards) do c:Hide() end
  local colH = { 0, 0 }
  for n, key in ipairs(keys) do
    local ch = ns.db.chars[key]
    local card = CdCard(n)
    local list = {}
    for _, entry in ipairs(ns.COOLDOWNS) do
      if ch.cd[entry[1]] then list[#list + 1] = entry end
    end
    local col = colH[1] <= colH[2] and 1 or 2
    local h = 52 + #list * 50 + 4
    card:ClearAllPoints()
    card:SetPoint("TOPLEFT", (col - 1) * (CDW + 12), -48 - colH[col])
    card:SetHeight(h)
    colH[col] = colH[col] + h + 10
    ns.ClassIcon(card.class, ch.class)
    local color = ch.class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[ch.class]
    card.name:SetText(ch.name or key)
    if color then card.name:SetTextColor(color.r, color.g, color.b) end
    card.sub:SetText(ch.level and L("Level %d", "Level %d"):format(ch.level) or "")
    local allReady = true
    for j, entry in ipairs(list) do
      local cd = ch.cd[entry[1]]
      local r = CdRow(card, j)
      local left = cd.ready - now
      local icon = entry.icon
      if entry.item then
        local okI, tex = pcall(C_Item and C_Item.GetItemIconByID or GetItemIcon, entry.item)
        if okI and tex then icon = tex end
      end
      r.icon:SetTexture(icon)
      r.name:SetText(entry[1])
      local total = entry.dur or 86400
      local w = r:GetWidth()
      if w <= 1 then w = CDW - 28 end
      if left <= 0 then
        ready = ready + 1
        r.state:SetText(L("Ready", "Klar")); r.state:SetTextColor(0.35, 0.9, 0.4)
        r.when:SetText(L("Ready to use", "Klar til brug"))
        r.fill:SetColorTexture(0.35, 0.9, 0.4, 1)
        r.fill:SetWidth(w)
      else
        running = running + 1
        allReady = false
        r.state:SetText(Span(left)); r.state:SetTextColor(1, 1, 1)
        r.when:SetText(L("Ready ", "Klar ") .. date("%a %H:%M", cd.ready))
        r.fill:SetColorTexture(1, 0.82, 0.3, 1)
        r.fill:SetWidth(math.max(1, w * math.min(1, math.max(0, 1 - left / total))))
      end
      r:Show()
    end
    for j = #list + 1, #card.rows do card.rows[j]:Hide() end
    card.mark:SetColorTexture(allReady and 0.35 or 1, allReady and 0.9 or 0.82, allReady and 0.4 or 0.3, 1)
    card:Show()
  end
  cdEmpty:SetShown(#keys == 0)
  cdEmpty:SetText(T("noCd") .. "\n" .. L("Open the profession window once so CraftETA can read the real time.", "Åbn fagvinduet én gang, så CraftETA kan læse den rigtige tid."))
  cdSub:SetText(#keys > 0 and L("%d ready  ·  %d running", "%d klar  ·  %d i gang"):format(ready, running) or "")
  cdFoot:SetText(T("cdFoot"))
end
local cdAcc = 0
cdPage:SetScript("OnUpdate", function(self, dt)
  cdAcc = cdAcc + dt
  if cdAcc > 20 then cdAcc = 0; if self:IsShown() then self:Refresh() end end
end)

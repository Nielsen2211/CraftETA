-- CraftETA: the Professions page under the route bar. The step you are on as a big card (what to make,
-- what it needs, what it costs), your goal with presets and what each costs, what stops you (a trainer) and
-- what comes next. "All steps" shows the whole route as a list instead.
local _, ns = ...
local T = ns.T

local function L(en, da) return (ns.db and ns.db.lang == "da") and da or en end
local H, X, CW = ns.Hub, ns.HUB_X, ns.HUB_CW

local function Fill(parent, r, g, b, a, layer)
  local t = parent:CreateTexture(nil, layer or "BACKGROUND", nil, 1)
  t:SetColorTexture(r, g, b, a or 1)
  return t
end
local function Card(parent, r, g, b, edge)
  local f = CreateFrame("Frame", nil, parent)
  f.bg = ns.RoundBox(f, r or 0.086, g or 0.094, b or 0.122, 1, edge)
  return f
end
local function Head(parent, text, r, g, b)
  local h = ns.Font(parent, true, 9, r or 0.36, g or 0.38, b or 0.42)
  h:SetText(text)
  return h
end
local function Icon(parent, size)
  local t = parent:CreateTexture(nil, "ARTWORK")
  t:SetSize(size, size)
  t:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  return t
end

local gv = CreateFrame("Frame", nil, H)
gv:SetWidth(CW)
gv:Hide()
local cur = {}

---------------------------------------------------------------------------
-- The NOW card
---------------------------------------------------------------------------
local now = Card(gv, nil, nil, nil, { 0.2, 0.21, 0.25, 1 })
now:SetPoint("TOPLEFT"); now:SetPoint("RIGHT")
now:SetHeight(196)
local nowIcon = Icon(now, 48); nowIcon:SetPoint("TOPLEFT", 16, -16)
local badge = CreateFrame("Frame", nil, now); badge:SetSize(36, 15); badge:SetPoint("TOPLEFT", nowIcon, "TOPRIGHT", 12, 0)
ns.RoundBox(badge, 1, 0.82, 0.29, 1)
local badgeText = ns.Font(badge, true, 9, 0.08, 0.06, 0.02); badgeText:SetPoint("CENTER"); badgeText:SetShadowOffset(0, 0)
local nowRange = ns.Font(now, true, 10, 0.5, 0.52, 0.57); nowRange:SetPoint("LEFT", badge, "RIGHT", 8, 0)
local nowTitle = ns.Font(now, true, 17, 1, 0.82, 0.29)
nowTitle:SetPoint("TOPLEFT", badge, "BOTTOMLEFT", 0, -5); nowTitle:SetPoint("RIGHT", now, "RIGHT", -184, 0); nowTitle:SetWordWrap(false)
local nowSub = ns.Font(now, false, 10, 0.5, 0.52, 0.57)
nowSub:SetPoint("TOPLEFT", nowTitle, "BOTTOMLEFT", 0, -4); nowSub:SetPoint("RIGHT", now, "RIGHT", -184, 0); nowSub:SetWordWrap(false)
local nowNote = ns.Font(now, false, 10, 0.78, 0.72, 0.58)
nowNote:SetPoint("TOPLEFT", nowSub, "BOTTOMLEFT", 0, -4); nowNote:SetPoint("RIGHT", now, "RIGHT", -184, 0)
nowNote:SetWordWrap(true); nowNote:SetMaxLines(2)

local craft = ns.Primary(ns.Button(now, "", 152, 30), 13)
craft:SetPoint("TOPRIGHT", -16, -16)
local listBtn = ns.Button(now, "+ " .. "List", 74, 22); listBtn:SetPoint("TOPLEFT", craft, "BOTTOMLEFT", 0, -6)
local mapBtn = ns.Button(now, "Map", 74, 22); mapBtn:SetPoint("TOPRIGHT", craft, "BOTTOMRIGHT", 0, -6)
for _, b in ipairs({ listBtn, mapBtn }) do b.label:SetTextColor(0.85, 0.87, 0.9) end

-- three small cards: needs, cost, your goal
local SUB_W = math.floor((CW - 32 - 16) / 3)
local subs = {}
for i = 1, 3 do
  local c = Card(now, 0.11, 0.122, 0.157)
  c:SetSize(SUB_W, 84)
  c:SetPoint("TOPLEFT", 16 + (i - 1) * (SUB_W + 8), -98)
  c.head = Head(c, ""); c.head:SetPoint("TOPLEFT", 12, -9)
  subs[i] = c
end
-- needs
local needRows = {}
for i = 1, 3 do
  local r = CreateFrame("Frame", nil, subs[1]); r:SetSize(SUB_W - 24, 18)
  r:SetPoint("TOPLEFT", 12, -26 - (i - 1) * 19)
  r.icon = Icon(r, 16); r.icon:SetPoint("LEFT")
  r.name = ns.Font(r, false, 10, 0.85, 0.87, 0.9); r.name:SetPoint("LEFT", r.icon, "RIGHT", 6, 0); r.name:SetWordWrap(false)
  r.value = ns.Font(r, true, 10); r.value:SetPoint("RIGHT"); r.value:SetJustifyH("RIGHT")
  r.name:SetPoint("RIGHT", r.value, "LEFT", -4, 0)
  needRows[i] = r
end
-- cost
local costBig = ns.Font(subs[2], true, 16, 1, 0.82, 0.29); costBig:SetPoint("TOPLEFT", 12, -21)
local costSub = ns.Font(subs[2], false, 9, 0.5, 0.52, 0.57); costSub:SetPoint("TOPLEFT", costBig, "BOTTOMLEFT", 0, -3)
costSub:SetPoint("RIGHT", subs[2], "RIGHT", -8, 0); costSub:SetWordWrap(false)
local costGoal = ns.Font(subs[2], false, 9, 0.85, 0.87, 0.9); costGoal:SetPoint("TOPLEFT", costSub, "BOTTOMLEFT", 0, -3)
costGoal:SetPoint("RIGHT", subs[2], "RIGHT", -8, 0); costGoal:SetWordWrap(false)
local costNet = ns.Font(subs[2], false, 9, 0.85, 0.87, 0.9); costNet:SetPoint("TOPLEFT", costGoal, "BOTTOMLEFT", 0, -3)
costNet:SetPoint("RIGHT", subs[2], "RIGHT", -8, 0); costNet:SetWordWrap(false)
-- hover the card: what 1 to 300 costs on the AH, what the crafts sell back for, and the net
subs[2]:EnableMouse(true)
subs[2]:SetScript("OnEnter", function(self)
  local id = cur.id
  if not id or not ns.GUIDES[id] then return end
  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
  GameTooltip:SetText(L("Prices from your latest scan", "Priser fra din seneste scan"), 1, 1, 1)
  if cur.entry then
    local net = ns.EntryNet(cur.entry)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(L("One craft of %s", "Ét craft af %s"):format(cur.entry[1]), 1, 0.82, 0.3)
    GameTooltip:AddDoubleLine(L("Materials", "Materialer"), (net.costMissing and "~" or "") .. ns.Money(net.cost), 0.85, 0.87, 0.9, 1, 1, 1)
    if net.sell then
      GameTooltip:AddDoubleLine(L("Sells for", "Sælger for"), ns.Money(net.sell * net.y), 0.85, 0.87, 0.9, 1, 1, 1)
    end
    GameTooltip:AddDoubleLine(L("Profit after the AH's 5%", "Profit efter AH's 5%"), (ns.ProfitText(net)), 0.85, 0.87, 0.9, 1, 1, 1)
  end
  ns.AddRouteTip(GameTooltip, L("Skill 1 to 300, everything bought", "Skill 1 til 300, alt købt"), ns.RouteNet(id, 1, 300))
  if cur.rank and cur.goal and cur.rank > 1 then
    ns.AddRouteTip(GameTooltip, L("Skill %d to %d, what you still need", "Skill %d til %d, det du mangler"):format(cur.rank, cur.goal), ns.RouteNet(id, cur.rank, cur.goal, true))
  end
  GameTooltip:Show()
end)
subs[2]:SetScript("OnLeave", function() GameTooltip:Hide() end)
-- your goal: a number you set, and presets with what each costs
local goalSub = subs[3]
-- type the skill you want to reach (Enter sets it)
local goalNum
goalNum = ns.NumberBox(goalSub, 52, 24, 16, function(n) if goalNum.onSet then goalNum.onSet(n) end end)
goalNum:SetPoint("TOPLEFT", 10, -20)
goalNum:SetScript("OnEnter", function(self)
  GameTooltip:SetOwner(self, "ANCHOR_TOP")
  GameTooltip:SetText(L("Type your goal, then Enter", "Skriv dit mål og tryk Enter"))
  GameTooltip:Show()
end)
goalNum:SetScript("OnLeave", function() GameTooltip:Hide() end)
local goalInfo = ns.Font(goalSub, false, 9, 0.5, 0.52, 0.57); goalInfo:SetPoint("LEFT", goalNum, "RIGHT", 8, 0)
goalInfo:SetPoint("RIGHT", goalSub, "RIGHT", -8, 0); goalInfo:SetWordWrap(false); goalInfo:SetJustifyH("RIGHT")
local presets = {}
local PW = math.floor((SUB_W - 24 - 9) / 4)
for i = 1, 4 do
  local b = ns.Button(goalSub, "", PW, 18)
  b:SetPoint("TOPLEFT", 12 + (i - 1) * (PW + 3), -50)
  b.label:SetFont(ns.F_BOLD, 10, "")
  b.cost = ns.Font(goalSub, false, 8, 0.45, 0.47, 0.52); b.cost:SetPoint("TOP", b, "BOTTOM", 0, -2)
  presets[i] = b
end

---------------------------------------------------------------------------
-- Under it: what stops you (a trainer), and what comes next
---------------------------------------------------------------------------
local HALF = math.floor((CW - 8) / 2)
local stop = Card(gv, nil, nil, nil, { 0.2, 0.21, 0.25, 1 })
stop:SetSize(HALF, 84); stop:SetPoint("TOPLEFT", now, "BOTTOMLEFT", 0, -8)
local stopHead = Head(stop, "", 1, 0.69, 0.38); stopHead:SetPoint("TOPLEFT", 14, -11)
local stopTitle = ns.Font(stop, true, 12, 0.9, 0.91, 0.94); stopTitle:SetPoint("TOPLEFT", stopHead, "BOTTOMLEFT", 0, -6)
local stopWho = ns.Font(stop, false, 10, 0.82, 0.67, 0.47); stopWho:SetPoint("TOPLEFT", stopTitle, "BOTTOMLEFT", 0, -4)
stopWho:SetPoint("RIGHT", stop, "RIGHT", -110, 0); stopWho:SetWordWrap(true); stopWho:SetMaxLines(2)  -- long trainer names take a second line
local stopMap = ns.Button(stop, "", 96, 22); stopMap:SetPoint("BOTTOMRIGHT", -12, 12)
stopMap.label:SetTextColor(1, 0.84, 0.63)

local after = Card(gv)
after:SetSize(HALF, 84); after:SetPoint("TOPRIGHT", now, "BOTTOMRIGHT", 0, -8)
local afterHead = Head(after, ""); afterHead:SetPoint("TOPLEFT", 14, -11)
local afterIcon = Icon(after, 30); afterIcon:SetPoint("TOPLEFT", afterHead, "BOTTOMLEFT", 0, -8)
local afterName = ns.Font(after, true, 12, 0.9, 0.91, 0.94); afterName:SetPoint("TOPLEFT", afterIcon, "TOPRIGHT", 10, 0)
afterName:SetPoint("RIGHT", after, "RIGHT", -12, 0); afterName:SetWordWrap(false)
local afterSub = ns.Font(after, false, 10, 0.5, 0.52, 0.57); afterSub:SetPoint("BOTTOMLEFT", afterIcon, "BOTTOMRIGHT", 10, 0)
afterSub:SetPoint("RIGHT", after, "RIGHT", -12, 0); afterSub:SetWordWrap(false)

-- footer: the whole list, and the shopping list
local allBtn = ns.Button(gv, "", 124, 26); allBtn:SetPoint("TOPLEFT", stop, "BOTTOMLEFT", 0, -10)
allBtn.label:SetTextColor(0.85, 0.87, 0.9)
local shopBtn = ns.Primary(ns.Button(gv, "", 124, 26), 11); shopBtn:SetPoint("LEFT", allBtn, "RIGHT", 8, 0)
local hint = ns.Font(gv, false, 9, 0.36, 0.38, 0.42); hint:SetPoint("RIGHT", gv, "RIGHT", 0, 0); hint:SetPoint("TOP", allBtn, "TOP", 0, -8)

---------------------------------------------------------------------------
-- Your goal
---------------------------------------------------------------------------
function ns.Goal(id, rank, max)
  local g = ns.db and ns.db.goals and ns.db.goals[id]
  local base = ns.Target(id, rank or 1, max or 300)
  if not g then return base end
  return math.max((rank or 0) + 1, math.min(300, g))
end
local function SetGoal(id, v)
  ns.db.goals = ns.db.goals or {}
  ns.db.goals[id] = v
  ns.RefreshHub()
  if ns.Refresh then ns.Refresh() end
end

local function PlanCost(id, from, to)
  local crafts, mats = ns.Plan(id, from, to)
  local cost, unknown = ns.Cost(mats)
  return crafts, cost, unknown, ns.Duration(ns.TimeFor(id, to - from, crafts))
end

local RANK = { [75] = "Journeyman", [150] = "Expert", [225] = "Artisan" }

-- draws the page; y is the top, from the window's top. Returns nothing: the page has no list rows
function ns.ShowGuideView(id, guide, skill, current, y)
  local crafting = ns.GUIDES[id] ~= nil
  local rank = skill and skill.rank or 0
  local max = skill and skill.max or 75
  local goal = ns.Goal(id, rank, max)
  local step = current and guide.steps[current]
  cur.id = id
  cur.entry, cur.left = nil, nil
  gv:ClearAllPoints(); gv:SetPoint("TOPLEFT", H, "TOPLEFT", X, y)
  gv:SetHeight(196 + 8 + 84 + 10 + 26)
  gv:Show()

  -- NOW
  badgeText:SetText(L("NOW", "NU"))
  if rank >= 300 or not step then
    nowIcon:SetTexture(ns.ProfIcon(id)); nowRange:SetText("")
    nowTitle:SetText(rank >= 300 and T("done") or (skill and "" or T("notKnown", guide.name)))
    nowSub:SetText(""); nowNote:SetText("")
  elseif crafting then
    local chosen = ns.Chosen(id, current, step)
    local entry, left, _, fix = ns.StepEntry(id, current, step, rank)
    nowIcon:SetTexture(ns.ItemIcon(entry[1], ns.ProfIcon(id)))
    nowRange:SetText(step[1] .. " - " .. step[2])
    nowTitle:SetText(L("Craft %d %s", "Lav %d %s"):format(left, entry[1]))
    nowSub:SetText(L("Skill %d - %d  ·  about %d crafts", "Skill %d - %d  ·  cirka %d crafts"):format(math.max(step[1], rank), step[2], left)
      .. (#chosen > 1 and chosen[1] == entry and ("  ·  + " .. chosen[2][1]) or ""))
    nowNote:SetText(fix and ("|cffffb060" .. T("fixShort", fix.short, fix.name, fix.forName) .. "|r") or step.note or "")
    cur.entry, cur.left = entry, left
  else
    nowIcon:SetTexture(guide.icon or ns.ProfIcon(id))
    nowRange:SetText(step[1] .. " - " .. step[2])
    nowTitle:SetText(step.what or "")
    nowSub:SetText(step[ns.Faction()] or "")
    nowNote:SetText(step.note or "")
  end
  -- the big button: craft when the window is open on this profession, else open it
  craft:SetShown(crafting and step ~= nil and rank < 300)
  local st = ns.panelState or {}
  local ready = ns.ProfessionFrame and ns.ProfessionFrame() and st.prof == id and st.job
  -- the window is open on this profession and the step's recipe isn't learned: say so, like the panel
  local noRecipe = ns.ProfessionFrame and ns.ProfessionFrame() and st.prof == id and cur.entry and st.needRecipe == cur.entry[1]
  craft:SetText(ready and T("craftN", st.job.count) or noRecipe and T("needRecipe") or T("craftNow"))
  if noRecipe then craft:Disable() else craft:Enable() end
  craft:SetScript("OnClick", function()
    local s = ns.panelState or {}
    if ns.ProfessionFrame() and s.prof == id and s.job then ns.Craft(s.job.name, s.job.count) else ns.OpenProfessionWindow(id) end
  end)
  listBtn:SetShown(crafting and rank < 300)
  listBtn:SetText(L("+ List", "+ Liste"))
  listBtn.tip = L("Shopping list up to your goal (%d)", "Indkøbsliste op til dit mål (%d)"):format(goal)
  listBtn:SetScript("OnClick", function() ns.AddToList(nil, nil, id, goal); ns.Print(T("addedList") .. " (" .. rank .. " - " .. goal .. ")") end)
  mapBtn:SetText(L("Map", "Kort"))
  mapBtn.tip = L("Show the next trainer on the map", "Vis næste træner på kortet")
  mapBtn:SetScript("OnClick", function() ns.ShowTrainer(id) end)

  -- needs
  subs[1].head:SetText(crafting and L("NEEDS", "SKAL BRUGE") or L("WHERE", "HVOR"))
  for _, r in ipairs(needRows) do r:Hide() end
  if crafting and cur.entry and step then
    local per = ns.MatsPerCraft(cur.entry)
    -- up to the step's end or your goal, whichever comes first: the same range as the cost next to it
    local stop = math.min(step[2], goal)
    local _, planMats = ns.Plan(id, rank, stop)
    if stop < step[2] then
      subs[1].head:SetText(L("NEEDS TO %d", "SKAL BRUGE TIL %d"):format(stop))
    end
    local n = 0
    for i = 1, #per, 2 do
      n = n + 1
      local r = needRows[n]
      if not r then break end
      local name, need = per[i], per[i + 1] * cur.left
      if stop < step[2] and planMats then need = planMats[name] or 0 end
      local have = ns.Have(name)
      r.icon:SetTexture(ns.ItemIcon(name)); r.name:SetText(name)
      r.value:SetText((have >= need and "|cff5cd67c" or "|cffe8574a") .. have .. " / " .. need .. "|r")
      r:Show()
    end
  end

  -- cost
  subs[2].head:SetText(L("COST OF THIS STEP", "PRIS FOR TRINNET"))
  if crafting and step then
    local _, cost, unknown = PlanCost(id, rank, math.min(step[2], goal))
    costBig:SetText(cost > 0 and ((unknown and "~" or "") .. ns.MoneyShort(cost)) or (unknown and L("No price yet", "Ingen pris endnu") or L("Nothing to buy", "Intet at købe")))
    local crafts, gcost, gunk, eta = PlanCost(id, rank, goal)
    local toGoal = L("To %d: ", "Til %d: "):format(goal) .. (gunk and "~" or "") .. ns.MoneyShort(gcost) .. "  ·  " .. T("crafts", crafts)
    ns.Fit(costGoal, toGoal .. (eta and ("  ·  " .. eta) or ""), toGoal)
    -- plus or minus on this craft, and what selling the crafts gives back on the way to the goal
    cur.rank, cur.goal = rank, goal
    if cur.entry then
      costSub:SetText(L("This craft: ", "Dette craft: ") .. ns.ProfitText(ns.EntryNet(cur.entry), true))
    else
      costSub:SetText("")
    end
    local rn = ns.RouteNet(id, rank, goal, true)
    ns.Fit(costNet, ns.RouteNetText(rn, true), ns.RouteNetText(rn, true, true))
  else
    cur.rank, cur.goal = nil, nil
    costBig:SetText(""); costSub:SetText(crafting and "" or L("Gathering costs nothing but time.", "Samling koster kun tid.")); costGoal:SetText(""); costNet:SetText("")
  end

  -- your goal
  subs[3].head:SetText(L("YOUR GOAL", "DIT MÅL"))
  goalNum:SetNumberValue(goal)
  goalNum.onSet = function(n) SetGoal(id, math.max(rank + 1, math.min(300, n))) end
  goalInfo:SetText("")
  local vals = { math.max(rank + 1, math.min(300, max)), 150, 225, 300 }
  local labels = { L("Cap", "Loft"), "150", "225", "300" }
  for i, b in ipairs(presets) do
    local v = vals[i]
    local okv = v > rank
    b:SetText(labels[i])
    b.label:SetTextColor(v == goal and 1 or 0.85, v == goal and 0.82 or 0.87, v == goal and 0.3 or 0.9)
    b:SetEnabled(okv)
    if okv and crafting then
      local _, c, unk = PlanCost(id, rank, v)
      b.cost:SetText(c > 0 and ((unk and "~" or "") .. ns.MoneyShort(c)) or "")
    else
      b.cost:SetText("")
    end
    b.tip = L("Goal %d", "Mål %d"):format(v)
    b:SetScript("OnClick", function() SetGoal(id, v) end)
  end

  -- what stops you
  local r = ns.NextRank(id, rank, max)
  if r and goal > r.at then
    stop:Show()
    stopHead:SetText(L("STOPS YOU AT %d", "STOPPER DIG VED %d"):format(r.at))
    stopTitle:SetText(L("Train %s %s", "Træn %s %s"):format(RANK[r.at] or "", guide.name))
    local who, lvl = r[ns.Faction()] or "", L("level %d", "level %d"):format(r.lvl or 1)
    if (r.lvl or 1) <= 1 then ns.Fit(stopWho, who)
    else ns.Fit(stopWho, who .. "  ·  " .. lvl, who .. "\n" .. lvl, who) end  -- a long trainer name puts the level on its own line, or wraps
    stopMap:SetText(L("Show on map", "Vis på kort"))
    stopMap:SetScript("OnClick", function() ns.ShowTrainer(id) end)
    stopMap.label:SetTextColor(1, 0.84, 0.63)
  else
    stop:Show()
    stopHead:SetText(L("TRAINER", "TRÆNER"))
    stopTitle:SetText(rank >= 300 and "" or L("No trainer visit needed up to %d", "Ingen træner nødvendig op til %d"):format(goal))
    stopWho:SetText(rank >= 300 and "" or L("You can train all the way to your goal.", "Du kan træne hele vejen til dit mål."))
    stopMap:SetText(""); stopMap:SetScript("OnClick", nil)
  end
  stopMap:SetShown(r ~= nil and goal > r.at)

  -- what comes next (or: the goal is reached)
  afterHead:SetText(L("THEN", "SÅ"))
  local nxt = current and guide.steps[current + 1]
  if step and step[2] >= goal then
    afterIcon:SetTexture("Interface\\Icons\\Achievement_Quests_Completed_08")
    afterName:SetText(L("Goal reached at %d", "Mål nået ved %d"):format(goal))
    afterSub:SetText(L("Raise your goal to keep going.", "Hæv dit mål for at fortsætte."))
  elseif nxt then
    local name, sub
    if crafting then
      local ch = ns.Chosen(id, current + 1, nxt)
      name = ch[1][1]
      local mats = ch[1][3]
      sub = mats and (mats[2] .. " " .. mats[1] .. L("  ·  you have %d", "  ·  du har %d"):format(ns.Have(mats[1]))) or ""
      afterIcon:SetTexture(ns.ItemIcon(name, ns.ProfIcon(id)))
    else
      name, sub = nxt.what, nxt[ns.Faction()]
      afterIcon:SetTexture(guide.icon or ns.ProfIcon(id))
    end
    afterName:SetText(name .. "  |cff5c6070" .. nxt[1] .. " - " .. nxt[2] .. "|r")
    afterSub:SetText(sub or "")
  else
    afterIcon:SetTexture(ns.ProfIcon(id)); afterName:SetText(""); afterSub:SetText("")
  end

  allBtn:SetText(L("All steps (%d)", "Alle trin (%d)"):format(#guide.steps))
  allBtn:SetScript("OnClick", function() ns.hubState.stepsOpen = true; ns.RefreshHub() end)
  shopBtn:SetText(L("Shopping list", "Indkøbsliste"))
  shopBtn:SetScript("OnClick", function() ns.ToggleList() end)
  hint:SetText(L("Hover the route for any step", "Hold musen over ruten for et trin"))
end

function ns.HideGuideView() gv:Hide() end

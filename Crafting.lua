-- CraftETA: Crafting. "I want 20 Iron Grenades": CraftETA works out everything behind it (the
-- materials, and the ones you can make yourself first), takes off what you already have, and gives
-- you the steps in order with a Craft button, a shopping list for the rest, and what it costs next to
-- buying the finished item. It lives in the panel beside the profession window, as its own tab.
local _, ns = ...
local T, Plain = ns.T, ns.Plain
local function L(en, da) return (ns.db and ns.db.lang == "da") and da or en end

-- ---------------------------------------------------------------------------------------- data
-- ns.db.orders = { { name = "Iron Grenade", want = 20, made = 0 }, ... };  ns.db.orderAt = the one shown
local function Orders()
  ns.db.orders = ns.db.orders or {}
  return ns.db.orders
end
local function Current()
  local list = Orders()
  if #list == 0 then return nil end
  ns.db.orderAt = math.max(1, math.min(#list, ns.db.orderAt or 1))
  return list[ns.db.orderAt], ns.db.orderAt, #list
end

-- how many you have: bags and bank
local ItemCount = (C_Item and C_Item.GetItemCount) or GetItemCount
local function Count(name)
  local id = ns.ItemID(name)
  if not id or not ItemCount then return 0 end
  local ok, n = pcall(ItemCount, id, true)
  n = ok and tonumber(Plain(n)) or 0
  return n
end

-- a recipe this character knows that makes `name`: its profession, recipe ID and book entry
local function MyRecipe(name, any)
  local me = ns.Me()
  if not me or not name then return nil end
  local id = ns.ItemID(name)
  local found
  for prof, book in pairs(me.book or {}) do
    for rid, r in pairs(book) do
      if r.n == name or (id and r.o == id) then
        if r.l then return prof, rid, r end
        if any and not found then found = { prof, rid, r } end
      end
    end
  end
  if found then return found[1], found[2], found[3] end
end
ns.MyRecipe = MyRecipe

-- the plan: steps in the order you make them (materials first) and what to buy
local function Plan(o)
  local still = math.max(0, (o.want or 0) - (o.made or 0))
  local steps, byName, buy, buyOrder, avail = {}, {}, {}, {}, {}
  local function availOf(name)
    if avail[name] == nil then avail[name] = Count(name) end
    return avail[name]
  end
  local function need(name, qty, depth, top)
    if qty <= 0 then return end
    if not top then
      local a = availOf(name)
      local use = math.min(a, qty)
      avail[name] = a - use
      qty = qty - use
      if qty <= 0 then return end
    end
    local prof, rid, r = MyRecipe(name, top)
    if r and (top or depth < 4) and r.m and #r.m > 0 then
      local yield = r.y or 1
      local crafts = math.ceil(qty / yield)
      for i = 1, #r.m, 2 do need(r.m[i], r.m[i + 1] * crafts, depth + 1, false) end
      local s = byName[r.n]
      if s then s.crafts = s.crafts + crafts
      else
        s = { name = r.n, crafts = crafts, prof = prof, id = rid, yield = yield, top = top, learned = r.l }
        byName[r.n] = s; steps[#steps + 1] = s
      end
    else
      if not buy[name] then buyOrder[#buyOrder + 1] = name end
      buy[name] = (buy[name] or 0) + qty
    end
  end
  need(o.name, still, 0, true)
  return { still = still, steps = steps, buy = buy, buyOrder = buyOrder }
end
ns.CraftPlan = Plan

-- what the plan costs to buy, and what the finished items cost on the auction house
local function Costs(o, plan)
  local cost, unknown = 0, false
  for _, name in ipairs(plan.buyOrder) do
    local c = ns.MatCost and ns.MatCost(name, plan.buy[name])
    if not c then local u = ns.MatPrice and ns.MatPrice(name); c = u and u * plan.buy[name] end
    if c then cost = cost + c else unknown = true end
  end
  local unit = ns.BuyUnit and ns.BuyUnit(o.name)
  return cost, unknown, unit and unit * plan.still or nil
end

function ns.AddOrder(name, want)
  want = math.floor(tonumber(want) or 0)
  if not name or want < 1 then return end
  local list = Orders()
  for i, o in ipairs(list) do
    if o.name == name then o.want = (o.made or 0) + want; ns.db.orderAt = i; ns.db.panelTab = "craft"; ns.Refresh(); return end
  end
  list[#list + 1] = { name = name, want = want, made = 0, added = time() }
  ns.db.orderAt = #list
  ns.db.panelTab = "craft"
  ns.Refresh()
  if ns.RefreshHub then ns.RefreshHub() end
  ns.Print(L("Crafting: %d %s.", "Crafting: %d %s."):format(want, name))
end

-- count what you make: the order's own recipe being cast
ns.Register("UNIT_SPELLCAST_SUCCEEDED")
ns.On("UNIT_SPELLCAST_SUCCEEDED", function(unit, _, spellID)
  if unit ~= "player" or not ns.db then return end
  spellID = Plain(spellID)
  if type(spellID) ~= "number" then return end
  for i = #Orders(), 1, -1 do
    local o = Orders()[i]
    local _, rid, r = MyRecipe(o.name, true)
    if rid == spellID then
      o.made = (o.made or 0) + (r and r.y or 1)
      if o.made >= o.want then
        ns.Print(L("Crafting done: %d %s.", "Crafting færdig: %d %s."):format(o.want, o.name))
        table.remove(Orders(), i)
      end
      ns.Refresh()
      if ns.RefreshHub then ns.RefreshHub() end
    end
  end
end)

-- ask how many: the recipe card's "Craft…" button
StaticPopupDialogs["CRAFTETA_ORDER"] = {
  text = "%s",
  button1 = OKAY, button2 = CANCEL,
  hasEditBox = true, maxLetters = 5,
  OnShow = function(self)
    local eb = self.editBox or (self.GetEditBox and self:GetEditBox())
    if eb then eb:SetNumeric(true); eb:SetText(tostring(ns.db.lastOrder or 20)); eb:HighlightText(); eb:SetFocus() end
  end,
  OnAccept = function(self, name)
    local eb = self.editBox or (self.GetEditBox and self:GetEditBox())
    local n = eb and tonumber(eb:GetText())
    if n and n > 0 then ns.db.lastOrder = n; ns.AddOrder(name, n) end
  end,
  EditBoxOnEnterPressed = function(self)
    local parent = self:GetParent()
    local n = tonumber(self:GetText())
    if n and n > 0 then ns.db.lastOrder = n; ns.AddOrder(parent.data, n) end
    parent:Hide()
  end,
  EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
  timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}
function ns.AskOrder(name)
  if not name then return end
  StaticPopup_Show("CRAFTETA_ORDER", L("How many %s do you want to make?", "Hvor mange %s vil du lave?"):format(name), nil, name)
end

-- /ceta craft 20 Iron Grenade
function ns.OrderCommand(rest)
  local n, name = string.match(rest or "", "^%s*(%d+)%s+(.-)%s*$")
  if not n then name = string.match(rest or "", "^%s*(.-)%s*$"); n = 1 end
  if not name or name == "" then ns.Print(L("Write: /ceta craft 20 Iron Grenade", "Skriv: /ceta craft 20 Iron Grenade")); return end
  local me = ns.Me()
  local lower, found = string.lower(name), nil
  for _, book in pairs(me and me.book or {}) do
    for _, r in pairs(book) do
      if r.n and string.lower(r.n) == lower and (r.l or not found) then found = r.n end
    end
  end
  if not found then ns.Print(L("No recipe called \"%s\" on this character. Open the profession once so CraftETA knows its recipes.", "Ingen opskrift der hedder \"%s\" på denne karakter. Åbn faget én gang, så CraftETA kender opskrifterne."):format(name)); return end
  ns.AddOrder(found, tonumber(n))
end

-- ---------------------------------------------------------------------------------------- the view
-- One view, drawn twice: in the panel beside the profession window (its Crafting tab) and on the
-- Crafting page of the main window. Both show the order picked in ns.db.orderAt.
local function MakeView(parent, width, maxRows)
  local v = {}
  local V = CreateFrame("Frame", nil, parent)
  V:SetWidth(width); V:SetHeight(10); V:Hide()
  v.frame = V

  local empty = ns.Font(V, false, 11, 0.6, 0.62, 0.67)
  empty:SetPoint("TOPLEFT", 14, -10); empty:SetPoint("RIGHT", V, "RIGHT", -14, 0)
  empty:SetJustifyH("LEFT"); empty:SetWordWrap(true)

  local card = ns.Round(V, "BACKGROUND", 1); card:SetColorTexture(0.086, 0.094, 0.122, 1)
  local icon = V:CreateTexture(nil, "ARTWORK"); icon:SetSize(36, 36); icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  local title = ns.Font(V, true, 14, 1, 0.82, 0.29); title:SetWordWrap(false)
  local madeText = ns.Font(V, false, 10, 0.6, 0.62, 0.67)
  local track = V:CreateTexture(nil, "ARTWORK"); track:SetHeight(4); track:SetColorTexture(0.16, 0.17, 0.21, 1)
  local fill = V:CreateTexture(nil, "OVERLAY"); fill:SetHeight(4); fill:SetPoint("LEFT", track, "LEFT"); fill:SetColorTexture(0.36, 0.84, 0.49, 1)
  local wantBox = ns.NumberBox(V, 46, 20, 12, function(n)
    local o = Current()
    if o then o.want = math.max((o.made or 0) + 1, n); ns.Refresh(); if ns.RefreshHub then ns.RefreshHub() end end
  end)
  local remove = CreateFrame("Button", nil, V); remove:SetSize(18, 18)
  local rx = ns.Font(remove, true, 14, 0.55, 0.58, 0.64); rx:SetPoint("CENTER"); rx:SetText("×")
  remove:SetScript("OnEnter", function(self) rx:SetTextColor(1, 0.45, 0.4); GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetText(L("Remove", "Fjern"), 1, 1, 1); GameTooltip:Show() end)
  remove:SetScript("OnLeave", function() rx:SetTextColor(0.55, 0.58, 0.64); GameTooltip:Hide() end)
  remove:SetScript("OnClick", function()
    local _, at = Current()
    if at then table.remove(Orders(), at); ns.Refresh(); if ns.RefreshHub then ns.RefreshHub() end end
  end)
  local prev = ns.IconButton(V, "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up", 16)
  local nextB = ns.IconButton(V, "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up", 16)
  prev.icon:SetTexCoord(0, 1, 0, 1); nextB.icon:SetTexCoord(0, 1, 0, 1)
  local pageText = ns.Font(V, false, 10, 0.5, 0.52, 0.57)
  local function Page(d)
    local _, at, n = Current()
    if not at then return end
    ns.db.orderAt = ((at - 1 + d) % n) + 1
    ns.Refresh(); if ns.RefreshHub then ns.RefreshHub() end
  end
  prev:SetScript("OnClick", function() Page(-1) end)
  nextB:SetScript("OnClick", function() Page(1) end)

  local function Head() return ns.Font(V, true, 9, 0.36, 0.38, 0.42) end
  local stepHead, buyHead = Head(), Head()
  local function MakeRows()
    local rows = {}
    for i = 1, maxRows do
      local r = ns.Row(V, 18); r:SetWidth(width - 52)
      r:SetScript("OnEnter", function(self)
        if self.itemID then GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetItemByID(self.itemID); if self.extra then GameTooltip:AddLine(self.extra, 0.6, 0.8, 0.6, true) end; GameTooltip:Show() end
      end)
      r:SetScript("OnLeave", function() GameTooltip:Hide() end)
      rows[i] = r
    end
    return rows
  end
  local stepRows, buyRows = MakeRows(), MakeRows()
  local more = ns.Font(V, false, 10, 0.5, 0.52, 0.57)
  local costLine = ns.Font(V, false, 10, 0.85, 0.87, 0.9); costLine:SetWordWrap(true)
  local status = ns.Font(V, false, 10, 1, 0.69, 0.38); status:SetWordWrap(true)

  local craftBtn = ns.Button(V, T("craft"), width - 52 - 34, 28)
  local craftFill = ns.Round(craftBtn, "BACKGROUND", 2); craftFill:SetAllPoints()
  craftBtn.label:SetFont(ns.F_BOLD, 13, ""); craftBtn.label:SetShadowOffset(0, 0)
  local function Look(on)
    craftFill:SetColorTexture(on and 1 or 0.2, on and 0.82 or 0.19, on and 0.29 or 0.15, 1)
    craftBtn.label:SetTextColor(on and 0.1 or 0.45, on and 0.08 or 0.45, on and 0.03 or 0.47)
  end
  hooksecurefunc(craftBtn, "Enable", function() Look(true) end)
  hooksecurefunc(craftBtn, "Disable", function() Look(false) end)
  craftBtn.primaryFill = function(on) if craftBtn:IsEnabled() then craftFill:SetColorTexture(1, on and 0.88 or 0.82, on and 0.5 or 0.29, 1) end end
  Look(true)
  local job, plan
  craftBtn:SetScript("OnClick", function() if job then ns.Craft(job.name, job.count) end end)
  local listBtn = ns.Button(V, "+", 28, 28)
  listBtn.label:SetFont(ns.F_BOLD, 16, "")
  listBtn:SetScript("OnClick", function()
    if not plan or #plan.buyOrder == 0 then return end
    local mats = {}
    for _, n in ipairs(plan.buyOrder) do mats[n] = plan.buy[n] end
    ns.AddToList(mats, plan.buyOrder)
    ns.Print(T("addedList"))
  end)

  local parts = { card, icon, title, madeText, track, fill, wantBox, remove, prev, nextB, pageText, stepHead, buyHead, more, costLine, status, craftBtn, listBtn }
  function v.Hide() V:Hide() end
  -- draws it; returns its height
  function v.Draw()
    local o, at, n = Current()
    local y = -6
    for _, w in ipairs(parts) do w:Hide() end
    for _, r in ipairs(stepRows) do r:Hide() end
    for _, r in ipairs(buyRows) do r:Hide() end
    empty:Hide()
    V:Show()
    if not o then
      empty:SetText(v.emptyText or "")
      empty:Show()
      local h = empty:GetStringHeight() + 24
      V:SetHeight(h)
      return h
    end
    plan = Plan(o)
    local cardTop = y
    y = y - 10
    icon:ClearAllPoints(); icon:SetPoint("TOPLEFT", 26, y)
    icon:SetTexture(ns.ItemIcon(o.name)); icon:Show()
    title:ClearAllPoints(); title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, -1); title:SetPoint("RIGHT", V, "RIGHT", -48, 0)
    title:SetText(o.name); title:Show()
    remove:ClearAllPoints(); remove:SetPoint("TOPRIGHT", V, "TOPRIGHT", -20, y + 2); remove:Show()
    madeText:ClearAllPoints(); madeText:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", 10, 1)
    madeText:SetText(L("Made %d of", "Lavet %d af"):format(o.made or 0)); madeText:Show()
    wantBox:ClearAllPoints(); wantBox:SetPoint("LEFT", madeText, "RIGHT", 6, 0); wantBox:SetNumberValue(o.want); wantBox:Show()
    y = y - 42
    track:ClearAllPoints(); track:SetPoint("TOPLEFT", 26, y); track:SetPoint("RIGHT", V, "RIGHT", -26, 0); track:Show()
    fill:SetWidth(math.max(1, (width - 52) * math.min(1, (o.made or 0) / math.max(1, o.want)))); fill:Show()
    y = y - 10
    if n > 1 and v.pager then
      nextB:ClearAllPoints(); nextB:SetPoint("TOPRIGHT", V, "TOPRIGHT", -24, y); nextB:Show()
      pageText:ClearAllPoints(); pageText:SetPoint("RIGHT", nextB, "LEFT", -4, 0); pageText:SetText(at .. " / " .. n); pageText:Show()
      prev:ClearAllPoints(); prev:SetPoint("RIGHT", pageText, "LEFT", -4, 0); prev:Show()
      y = y - 18
    end

    -- the steps
    stepHead:ClearAllPoints(); stepHead:SetPoint("TOPLEFT", 26, y - 4)
    stepHead:SetText(string.upper(L("Make, in this order", "Lav i denne rækkefølge"))); stepHead:Show()
    y = y - 18
    job = nil
    local open = ns.OpenProfession and ns.OpenProfession()
    local first, shown = nil, 0
    for _, s in ipairs(plan.steps) do
      if s.crafts > 0 and shown < maxRows then
        shown = shown + 1
        local r = stepRows[shown]
        r.itemID = ns.ItemID(s.name); r.extra = nil
        r.icon:SetTexture(ns.ItemIcon(s.name))
        local isNext = not first
        if isNext then first = s end
        r.name:SetText((isNext and "|cffffd24a" or "|cffd9dbe0") .. s.name .. "|r")
        local count = s.crafts * (s.yield or 1)
        if s.learned then r.value:SetText((isNext and "|cffffd24a" or "|cffb0b3ba") .. L("make %d", "lav %d"):format(count) .. "|r")
        else r.value:SetText("|cffe8574a" .. L("not learned", "ikke lært") .. "|r") end
        r:ClearAllPoints(); r:SetPoint("TOPLEFT", 26, y); r:Show()
        y = y - 20
      end
    end
    local s, why = first, nil
    if s then
      if not open or open.id ~= s.prof then
        why = L("Open %s to craft %s.", "Åbn %s for at lave %s."):format(ns.ProfName and ns.ProfName(s.prof) or "?", s.name)
      else
        local can = ns.CanMake(s.name)
        local rec = ns.Recipe(s.name)
        if can > 0 then job = { name = s.name, count = math.min(s.crafts, can) }
        elseif rec and rec.learned then job = { name = s.name, count = s.crafts }   -- the game crafts what you have
        else why = L("You don't know this recipe on this character.", "Du kender ikke opskriften på denne karakter.") end
      end
    end

    -- what to buy
    if #plan.buyOrder > 0 then
      buyHead:ClearAllPoints(); buyHead:SetPoint("TOPLEFT", 26, y - 6)
      buyHead:SetText(string.upper(L("Buy", "Køb"))); buyHead:Show()
      y = y - 20
      for i, name in ipairs(plan.buyOrder) do
        if i > maxRows then break end
        local r = buyRows[i]
        local id = ns.ItemID(name)
        r.itemID = id
        r.icon:SetTexture(ns.ItemIcon(name))
        r.name:SetText(name)
        local c = ns.MatCost and ns.MatCost(name, plan.buy[name])
        r.value:SetText("|cffe8574a" .. plan.buy[name] .. "|r" .. (c and ("  |cffb0b3ba" .. ns.MoneyShort(c) .. "|r") or ""))
        local makers = id and ns.Makers and ns.Makers(id)
        r.extra = (makers and makers[1]) and L("%s can make this", "%s kan lave den"):format(makers[1].char) or nil
        r:ClearAllPoints(); r:SetPoint("TOPLEFT", 26, y); r:Show()
        y = y - 20
      end
      if #plan.buyOrder > maxRows then
        more:ClearAllPoints(); more:SetPoint("TOPLEFT", 26, y); more:SetText(L("+ %d more on the shopping list", "+ %d mere på indkøbslisten"):format(#plan.buyOrder - maxRows)); more:Show()
        y = y - 16
      end
    end

    -- cost: the materials you buy next to buying the finished items
    local cost, unknown, ah = Costs(o, plan)
    local bits = {}
    if #plan.buyOrder > 0 then bits[#bits + 1] = L("Materials", "Materialer") .. " " .. (unknown and "~" or "") .. ns.MoneyShort(cost) end
    if ah then
      bits[#bits + 1] = L("%d on the AH", "%d på AH"):format(plan.still) .. " " .. ns.MoneyShort(ah)
      if #plan.buyOrder > 0 and not unknown then bits[#bits + 1] = cost < ah and ("|cff5cd67c" .. L("crafting is cheaper", "billigere at lave") .. "|r") or ("|cffe8574a" .. L("buying is cheaper", "billigere at købe") .. "|r") end
    end
    if #bits > 0 then
      costLine:ClearAllPoints(); costLine:SetPoint("TOPLEFT", 26, y - 6); costLine:SetPoint("RIGHT", V, "RIGHT", -26, 0)
      costLine:SetText(table.concat(bits, "  ·  ")); costLine:Show()
      y = y - 6 - costLine:GetStringHeight() - 2
    end

    y = y - 8
    craftBtn:ClearAllPoints(); craftBtn:SetPoint("TOPLEFT", 26, y); craftBtn:Show()
    listBtn:ClearAllPoints(); listBtn:SetPoint("LEFT", craftBtn, "RIGHT", 6, 0); listBtn:Show()
    listBtn.tip = L("Put what you need to buy on the shopping list.", "Læg det, du skal købe, på indkøbslisten.")
    if #plan.buyOrder > 0 then listBtn:Enable() else listBtn:Disable() end
    if job then
      craftBtn:Enable()
      craftBtn:SetText(L("Craft %d %s", "Lav %d %s"):format(job.count * (s.yield or 1), job.name))
    else
      craftBtn:Disable()
      craftBtn:SetText(plan.still <= 0 and L("Done", "Færdig") or T("craft"))
    end
    y = y - 34
    if why then
      status:ClearAllPoints(); status:SetPoint("TOPLEFT", 26, y); status:SetPoint("RIGHT", V, "RIGHT", -26, 0)
      status:SetText(why); status:Show()
      y = y - status:GetStringHeight() - 4
    end
    y = y - 8
    card:ClearAllPoints(); card:SetPoint("TOPLEFT", 14, cardTop); card:SetPoint("RIGHT", V, "RIGHT", -14, 0)
    card:SetHeight(cardTop - y); card:Show()
    V:SetHeight(-y + 4)
    return -y + 4
  end
  return v
end

local HOWTO = function() return L("Pick a recipe in the profession window and press |cffffd24aCraft...|r on the CraftETA card, say 20.\n\nCraftETA works out the materials (and makes the ones you can make first), takes off what you have, and gives you the steps, a shopping list and the cost.\n\nOr type |cffffffff/ceta craft 20 Iron Grenade|r.",
  "Vælg en opskrift i profession-vinduet og tryk |cffffd24aCraft...|r på CraftETA-kortet, fx 20.\n\nCraftETA regner materialerne ud (og laver dem, du selv kan lave, først), trækker det fra, du har, og giver dig trinene, en indkøbsliste og prisen.\n\nEller skriv |cffffffff/ceta craft 20 Iron Grenade|r.") end

-- the panel's Crafting tab
local P = ns.Panel
local panelView = MakeView(P, P:GetWidth(), 6)
panelView.frame:SetPoint("TOPLEFT", 0, -62)
panelView.pager = true
function ns.RefreshCraftView() panelView.emptyText = HOWTO(); return panelView.Draw() end
function ns.HideCraftView() panelView.Hide() end

-- ---------------------------------------------------------------------------------------- main window page
local H, X, CW = ns.Hub, ns.HUB_X, ns.HUB_CW
if H and ns.HubCustom then
  local page = CreateFrame("Frame", nil, H)
  page:SetPoint("TOPLEFT", X, -20)
  page:SetPoint("BOTTOMRIGHT", -18, 16)
  page:Hide()
  ns.HubCustom.craft = page
  local LW = 250
  local RW = CW - LW - 12

  -- left: add one (a recipe name and a number), then every order
  local addCard = CreateFrame("Frame", nil, page)
  addCard:SetPoint("TOPLEFT", 0, 0); addCard:SetSize(LW, 118)
  ns.RoundBox(addCard, 0.086, 0.094, 0.122, 1)
  local addHead = ns.Font(addCard, true, 9, 0.36, 0.38, 0.42); addHead:SetPoint("TOPLEFT", 12, -12)
  local nameBox = CreateFrame("EditBox", nil, addCard)
  nameBox:SetSize(LW - 24, 24); nameBox:SetPoint("TOPLEFT", 12, -28)
  nameBox:SetAutoFocus(false); nameBox:SetFont(ns.F_SEMI, 12, ""); nameBox:SetTextColor(0.91, 0.92, 0.94); nameBox:SetTextInsets(8, 8, 0, 0)
  ns.RoundBox(nameBox, 0.08, 0.09, 0.11, 0.95, { 0.25, 0.27, 0.32, 1 }, "BACKGROUND", 0)
  local hint = ns.Font(nameBox, false, 11, 0.42, 0.43, 0.47); hint:SetPoint("LEFT", 8, 0)
  local countBox = ns.NumberBox(addCard, 56, 24, 12, function() end)
  countBox:SetPoint("TOPLEFT", 12, -60); countBox:SetNumberValue(20)
  local addBtn = ns.Primary(ns.Button(addCard, "", LW - 24 - 62, 24), 11)
  addBtn:SetPoint("LEFT", countBox, "RIGHT", 6, 0)
  local addNote = ns.Font(addCard, false, 10, 0.5, 0.52, 0.57); addNote:SetPoint("TOPLEFT", 12, -92); addNote:SetPoint("RIGHT", addCard, "RIGHT", -12, 0); addNote:SetWordWrap(false)

  -- suggestions under the name box: your learned recipes that match
  local sugg = CreateFrame("Frame", nil, page)
  sugg:SetPoint("TOPLEFT", nameBox, "BOTTOMLEFT", 0, -2); sugg:SetWidth(LW - 24); sugg:SetFrameLevel(page:GetFrameLevel() + 20)
  ns.RoundBox(sugg, 0.06, 0.065, 0.085, 0.98, { 0.25, 0.27, 0.32, 1 })
  sugg:Hide()
  local suggRows = {}
  for i = 1, 8 do
    local r = ns.Row(sugg, 18); r:SetPoint("TOPLEFT", 6, -4 - (i - 1) * 19); r:SetPoint("RIGHT", sugg, "RIGHT", -6, 0)
    r:SetScript("OnClick", function(self) nameBox:SetText(self.recipe); nameBox:ClearFocus(); sugg:Hide() end)
    suggRows[i] = r
  end
  local function Learned()
    local me, out, seen = ns.Me(), {}, {}
    for prof, book in pairs(me and me.book or {}) do
      for _, r in pairs(book) do
        if r.l and r.n and not seen[r.n] then seen[r.n] = true; out[#out + 1] = { name = r.n, icon = r.i, prof = prof } end
      end
    end
    table.sort(out, function(a, b) return a.name < b.name end)
    return out
  end
  local function Suggest()
    local text = string.lower(nameBox:GetText() or "")
    hint:SetShown(text == "")
    if text == "" or not nameBox:HasFocus() then sugg:Hide(); return end
    local n = 0
    for _, r in ipairs(Learned()) do
      if string.find(string.lower(r.name), text, 1, true) then
        n = n + 1
        if n > 8 then break end
        local row = suggRows[n]
        row.recipe = r.name
        row.icon:SetTexture(r.icon or ns.ItemIcon(r.name)); row.name:SetText(r.name)
        row.value:SetText("|cff8c8f96" .. (ns.ProfName and ns.ProfName(r.prof) or "") .. "|r")
        row:Show()
      end
    end
    for i = math.min(n, 8) + 1, 8 do suggRows[i]:Hide() end
    if n == 0 then sugg:Hide() else sugg:SetHeight(math.min(n, 8) * 19 + 8); sugg:Show() end
  end
  nameBox:SetScript("OnTextChanged", Suggest)
  nameBox:SetScript("OnEditFocusGained", Suggest)
  nameBox:SetScript("OnEditFocusLost", function() C_Timer.After(0.2, function() if not nameBox:HasFocus() then sugg:Hide() end end) end)
  nameBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  local function Add()
    local name = nameBox:GetText()
    local want = tonumber(countBox:GetText()) or countBox.value or 1
    if not name or name == "" then return end
    -- the right letters: the recipe as your book has it
    local lower = string.lower(name)
    for _, r in ipairs(Learned()) do if string.lower(r.name) == lower then name = r.name end end
    if not MyRecipe(name, true) then addNote:SetText("|cffe8574a" .. L("You don't know that recipe.", "Den opskrift kender du ikke.") .. "|r"); return end
    ns.AddOrder(name, want)
    nameBox:SetText(""); nameBox:ClearFocus()
  end
  nameBox:SetScript("OnEnterPressed", Add)
  addBtn:SetScript("OnClick", Add)

  -- the orders
  local listHead = ns.Font(page, true, 9, 0.36, 0.38, 0.42); listHead:SetPoint("TOPLEFT", 4, -134)
  local orderRows = {}
  for i = 1, 10 do
    local r = CreateFrame("Button", nil, page)
    r:SetSize(LW, 40); r:SetPoint("TOPLEFT", 0, -150 - (i - 1) * 44)
    r.bg, r.edge = ns.RoundBox(r, 0.086, 0.094, 0.122, 1, { 0.137, 0.149, 0.184, 1 })
    r.icon = r:CreateTexture(nil, "ARTWORK"); r.icon:SetSize(26, 26); r.icon:SetPoint("LEFT", 8, 0); r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    r.name = ns.Font(r, true, 12); r.name:SetPoint("TOPLEFT", r.icon, "TOPRIGHT", 8, -1); r.name:SetPoint("RIGHT", r, "RIGHT", -60, 0); r.name:SetWordWrap(false)
    r.sub = ns.Font(r, false, 10, 0.55, 0.58, 0.64); r.sub:SetPoint("BOTTOMLEFT", r.icon, "BOTTOMRIGHT", 8, 1)
    r.count = ns.Font(r, true, 12, 1, 0.82, 0.29); r.count:SetPoint("RIGHT", -10, 0); r.count:SetJustifyH("RIGHT")
    r:SetScript("OnClick", function(self) ns.db.orderAt = self.index; ns.Refresh(); ns.RefreshHub() end)
    orderRows[i] = r
  end

  -- right: the picked order
  local view = MakeView(page, RW, 10)
  view.frame:SetPoint("TOPLEFT", LW + 12 - 14, 6)

  function page:Refresh()
    addHead:SetText(string.upper(L("Make a number of something", "Lav et antal af noget")))
    hint:SetText(L("Recipe, e.g. Iron Grenade", "Opskrift, fx Iron Grenade"))
    hint:SetShown((nameBox:GetText() or "") == "")
    addBtn:SetText(L("Add", "Tilføj"))
    addNote:SetText(L("Only recipes this character knows.", "Kun opskrifter denne karakter kan."))
    listHead:SetText(string.upper(L("Your crafting", "Din crafting")))
    local list = Orders()
    local _, at = Current()
    for i, r in ipairs(orderRows) do
      local o = list[i]
      if o then
        r.index = i
        r.icon:SetTexture(ns.ItemIcon(o.name)); r.name:SetText(o.name)
        local plan = Plan(o)
        r.sub:SetText(#plan.buyOrder > 0 and L("%d things to buy", "%d ting at købe"):format(#plan.buyOrder) or ("|cff5cd67c" .. L("you have everything", "du har det hele") .. "|r"))
        r.count:SetText((o.made or 0) .. " / " .. o.want)
        local sel = i == at
        r.edge:SetColorTexture(sel and 0.43 or 0.137, sel and 0.35 or 0.149, sel and 0.13 or 0.184, 1)
        r:Show()
      else r:Hide() end
    end
    view.emptyText = L("Nothing yet. Type a recipe on the left and how many you want, or press |cffffd24aCraft...|r on the CraftETA card in the profession window.\n\nCraftETA works out the materials (and makes the ones you can make first), takes off what you have, and gives you the steps, a shopping list and the cost.",
      "Intet endnu. Skriv en opskrift til venstre og hvor mange du vil have, eller tryk |cffffd24aCraft...|r på CraftETA-kortet i profession-vinduet.\n\nCraftETA regner materialerne ud (og laver dem, du selv kan lave, først), trækker det fra, du har, og giver dig trinene, en indkøbsliste og prisen.")
    view.Draw()
  end
end

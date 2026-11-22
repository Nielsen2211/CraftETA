-- CraftETA: the main window. Recipes, Profit, Crafters, Characters and Gathering, in tabs.
local _, ns = ...
local T = ns.T
local GetItemInfoInstant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant

local WIDTH, ROWS, ROW_H = 480, 15, 20
local H = ns.Window("CraftETAHub", WIDTH)
ns.Hub = H
H:SetHeight(110 + ROWS * ROW_H)

local state = { tab = "recipes", filter = "all", profitMode = "craft", offset = 0 }
local data = {}
ns.hubState = state

local function ProfIcon(id)
  local g = ns.GATHER[id]
  return (ns.PROF_ICON and ns.PROF_ICON[id]) or (g and g.icon) or 134400
end
ns.ProfIcon = ProfIcon

---------------------------------------------------------------------------
-- Tabs and the control row
---------------------------------------------------------------------------
local TABS = { "recipes", "profit", "crafters", "chars", "gather" }
local tabButtons = {}
for i, key in ipairs(TABS) do
  local b = ns.Button(H, "", 88, 22)
  b:SetPoint("TOPLEFT", 14 + (i - 1) * 91, -36)
  b:SetScript("OnClick", function()
    state.tab, state.offset = key, 0
    ns.RefreshHub()
  end)
  b.key = key
  tabButtons[i] = b
end
local tabLine = H:CreateTexture(nil, "ARTWORK")
tabLine:SetHeight(2)
tabLine:SetColorTexture(1, 0.82, 0.3, 1)

-- up to 5 small buttons under the tabs (professions, filters, modes)
local controls = {}
local function Control(i)
  local b = controls[i]
  if not b then
    b = ns.Button(H, "", 86, 20)
    controls[i] = b
  end
  return b
end

local search = CreateFrame("EditBox", nil, H)
search:SetSize(300, 20)
search:SetPoint("TOPLEFT", 14, -64)
search:SetAutoFocus(false)
search:SetFont(ns.F_SEMI, 11, "")
search:SetTextInsets(6, 6, 0, 0)
search:SetTextColor(1, 1, 1)
local searchBg = search:CreateTexture(nil, "BACKGROUND")
searchBg:SetAllPoints()
searchBg:SetColorTexture(0.08, 0.09, 0.11, 0.95)
local searchHint = ns.Font(search, false, 11, 0.45, 0.47, 0.52)
searchHint:SetPoint("LEFT", 6, 0)
search:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
search:SetScript("OnEnterPressed", function(self)
  self:ClearFocus()
  ns.FindCrafters(self:GetText())
end)
search:SetScript("OnTextChanged", function(self)
  searchHint:SetShown(self:GetText() == "")
end)
local searchButton = ns.Button(H, "", 86, 20)
searchButton:SetPoint("LEFT", search, "RIGHT", 8, 0)
searchButton:SetScript("OnClick", function()
  search:ClearFocus()
  ns.FindCrafters(search:GetText())
end)

-- the gathering tab's step text
local detail = ns.Font(H, false, 11)
ns.hubDetail = detail
detail:SetPoint("TOPLEFT", 14, -94)
detail:SetWidth(WIDTH - 28)
detail:SetWordWrap(true)
detail:SetSpacing(2)

---------------------------------------------------------------------------
-- The list
---------------------------------------------------------------------------
local rows = {}
for i = 1, ROWS do
  local r = ns.Row(H, ROW_H - 2)
  r:SetWidth(WIDTH - 28)
  r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  r:SetScript("OnEnter", function(self)
    local d = self.data
    if not d then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if d.tip then
      d.tip(GameTooltip)
    elseif d.item then
      GameTooltip:SetItemByID(d.item)
    end
    if d.hint then GameTooltip:AddLine(d.hint, 0.55, 0.58, 0.64) end
    GameTooltip:Show()
  end)
  r:SetScript("OnLeave", function() GameTooltip:Hide() end)
  r:SetScript("OnClick", function(self, which)
    if self.data and self.data.click then self.data.click(which) end
  end)
  rows[i] = r
end
ns.hubRows = rows
local footer = ns.Font(H, false, 10, 0.55, 0.58, 0.64)
footer:SetPoint("BOTTOMLEFT", 14, 14)
footer:SetPoint("RIGHT", H, "RIGHT", -14, 0)

H:EnableMouseWheel(true)
H:SetScript("OnMouseWheel", function(_, delta)
  local top = math.max(0, #data - ROWS)
  state.offset = math.max(0, math.min(top, state.offset - delta * 3))
  ns.DrawHub()
end)

local listTop = -94
function ns.DrawHub()
  for i = 1, ROWS do
    local r, d = rows[i], data[i + state.offset]
    local y = listTop - (i - 1) * ROW_H
    if d and y > -(H:GetHeight() - 34) then
      r:ClearAllPoints()
      r:SetPoint("TOPLEFT", 14 + (d.indent or 0), y)
      r:SetWidth(WIDTH - 28 - (d.indent or 0))
      r.data = d
      r.icon:SetTexture(d.icon)
      r.icon:SetShown(d.icon ~= nil)
      r.name:SetText(d.name or "")
      r.name:SetTextColor(d.r or 0.85, d.g or 0.87, d.b or 0.9)
      r.value:SetText(d.value or "")
      r.value:SetTextColor(d.vr or 1, d.vg or 1, d.vb or 1)
      r:Show()
    else
      r:Hide()
      r.data = nil
    end
  end
  local more = #data - ROWS - state.offset
  local text = state.footer or ""
  if more > 0 then text = text .. (text ~= "" and "   " or "") .. T("more", more) end
  footer:SetText(text)
end

---------------------------------------------------------------------------
-- Recipes
---------------------------------------------------------------------------
local DIFF_COLOR = {
  [0] = { 1, 0.5, 0.25 }, [1] = { 1, 1, 0 }, [2] = { 0.25, 0.75, 0.25 }, [3] = { 0.5, 0.5, 0.5 },
}

local function MatsTip(tip, r)
  local mats = r.m or {}
  for i = 1, #mats, 2 do
    local name, n = mats[i], mats[i + 1]
    local price = ns.Price(name)
    local have = ns.Have(name)
    tip:AddDoubleLine(("%dx %s |cff8c8f96(%s %d)|r"):format(n, name, T("have"), have),
      price and ns.Money(price * n) or T("unknownPrice"), 0.85, 0.87, 0.9, 1, 1, 1)
  end
end

local function BuildRecipes()
  local me = ns.Me()
  local profs = {}
  for id in pairs(me and me.book or {}) do profs[#profs + 1] = id end
  table.sort(profs)
  if not state.prof or not (me and me.book[state.prof]) then state.prof = profs[1] end
  local n = 0
  for i, id in ipairs(profs) do
    if i > 3 then break end
    local b = Control(i)
    b:SetText(ns.ProfName(id))
    b:SetPoint("TOPLEFT", 14 + (i - 1) * 90, -64)
    b.label:SetTextColor(id == state.prof and 1 or 0.6, id == state.prof and 0.82 or 0.62, id == state.prof and 0.3 or 0.68)
    b:SetScript("OnClick", function() state.prof, state.offset = id, 0; ns.RefreshHub() end)
    b:Show()
    n = i
  end
  local f = Control(n + 1)
  f:SetPoint("TOPLEFT", 14 + n * 90 + 10, -64)
  f:SetText(T("f_" .. state.filter))
  f:SetScript("OnClick", function()
    state.filter = ({ all = "learned", learned = "missing", missing = "all" })[state.filter]
    state.offset = 0
    ns.RefreshHub()
  end)
  f:Show()
  if not state.prof then
    state.footer = T("noBook")
    return
  end
  local list = {}
  for _, r in pairs(me.book[state.prof]) do
    if state.filter == "all" or (state.filter == "learned" and r.l) or (state.filter == "missing" and not r.l) then
      list[#list + 1] = r
    end
  end
  table.sort(list, function(a, b)
    if (a.l and 1 or 0) ~= (b.l and 1 or 0) then return a.l and true or false end
    if (a.d or 9) ~= (b.d or 9) then return (a.d or 9) < (b.d or 9) end
    return a.n < b.n
  end)
  for _, r in ipairs(list) do
    local cost, missing = ns.CraftCost(r)
    local color = r.l and (DIFF_COLOR[r.d] or { 0.85, 0.87, 0.9 }) or { 0.5, 0.55, 0.65 }
    data[#data + 1] = {
      icon = r.i or 134400, name = r.n, r = color[1], g = color[2], b = color[3],
      value = cost > 0 and ((missing and "~" or "") .. ns.Money(cost)) or "",
      tip = function(tip)
        tip:SetText(r.n, color[1], color[2], color[3])
        if not r.l then
          tip:AddLine(T("notLearned"), 1, 0.6, 0.35)
          if r.s then tip:AddLine(r.s, 1, 1, 1, true) end
        end
        tip:AddLine(" ")
        MatsTip(tip, r)
        if cost > 0 then tip:AddDoubleLine(T("total"), ns.Money(cost), 1, 0.82, 0.3, 1, 1, 1) end
        local makers = r.o and ns.Makers(r.o)
        if makers then
          local names = {}
          for _, m in ipairs(makers) do names[#names + 1] = m.char end
          tip:AddDoubleLine(T("ttMade"), table.concat(names, ", "), 0.7, 0.72, 0.76, 1, 1, 1)
        end
      end,
    }
  end
  state.footer = T("recipeCount", #list)
end

---------------------------------------------------------------------------
-- Profit: what to craft and sell, and what is worth farming
---------------------------------------------------------------------------
local AH_CUT = 0.95

local function BuildProfit()
  local modes = { "craft", "farm" }
  for i, mode in ipairs(modes) do
    local b = Control(i)
    b:SetPoint("TOPLEFT", 14 + (i - 1) * 90, -64)
    b:SetText(T("p_" .. mode))
    local on = state.profitMode == mode
    b.label:SetTextColor(on and 1 or 0.6, on and 0.82 or 0.62, on and 0.3 or 0.68)
    b:SetScript("OnClick", function() state.profitMode, state.offset = mode, 0; ns.RefreshHub() end)
    b:Show()
  end
  if state.profitMode == "farm" then
    local me = ns.Me()
    local list = {}
    for _, m in ipairs(ns.MATERIALS) do
      local price = ns.PriceID(m[2], m[1])
      if price then list[#list + 1] = { m = m, price = price } end
    end
    table.sort(list, function(a, b) return a.price > b.price end)
    for _, e in ipairs(list) do
      local m = e.m
      local mine = not m[3] or (me and me.profs[m[3]])
      data[#data + 1] = {
        icon = select(5, GetItemInfoInstant(m[2])) or 134400, name = m[1],
        r = mine and 0.85 or 0.5, g = mine and 0.87 or 0.52, b = mine and 0.9 or 0.56,
        value = ns.Money(e.price), item = m[2],
        hint = m[3] and (mine and T("youGather", ns.ProfName(m[3])) or T("needProf", ns.ProfName(m[3]))) or T("fromMobs"),
      }
    end
    state.footer = #list > 0 and T("farmFoot") or T("noPrices")
    return
  end
  local seen, list = {}, {}
  for key, c in pairs(ns.db.chars) do
    for profID, book in pairs(c.book or {}) do
      for _, r in pairs(book) do
        if r.l and r.o and not seen[r.o] then
          local sell = ns.PriceID(r.o)
          local cost, missing = ns.CraftCost(r)
          if sell and cost > 0 and not missing then
            seen[r.o] = true
            local gain = sell * AH_CUT * (r.y or 1) - cost
            list[#list + 1] = { r = r, gain = gain, sell = sell, cost = cost, char = c.name or key, prof = profID }
          end
        end
      end
    end
  end
  table.sort(list, function(a, b) return a.gain > b.gain end)
  for _, e in ipairs(list) do
    local up = e.gain >= 0
    data[#data + 1] = {
      icon = e.r.i or 134400, name = e.r.n,
      value = (up and "+" or "-") .. ns.Money(math.abs(e.gain)),
      vr = up and 0.35 or 1, vg = up and 0.9 or 0.4, vb = up and 0.4 or 0.35,
      tip = function(tip)
        tip:SetText(e.r.n, 1, 0.82, 0.3)
        tip:AddLine(("%s · %s"):format(e.char, ns.ProfName(e.prof)), 0.7, 0.72, 0.76)
        tip:AddLine(" ")
        tip:AddDoubleLine(T("sellsFor", e.r.y or 1), ns.Money(e.sell * (e.r.y or 1)), 0.85, 0.87, 0.9, 1, 1, 1)
        tip:AddDoubleLine(T("ahCut"), "-" .. ns.Money(e.sell * (e.r.y or 1) * (1 - AH_CUT)), 0.85, 0.87, 0.9, 1, 1, 1)
        tip:AddDoubleLine(T("matsCost"), "-" .. ns.Money(e.cost), 0.85, 0.87, 0.9, 1, 1, 1)
        tip:AddDoubleLine(T("profit"), (e.gain >= 0 and "+" or "-") .. ns.Money(math.abs(e.gain)), 1, 0.82, 0.3, 1, 1, 1)
        local vendor = ns.VendorPrice(e.r.o)
        if vendor then tip:AddDoubleLine(T("vendor"), ns.Money(vendor * (e.r.y or 1)), 0.6, 0.62, 0.68, 0.6, 0.62, 0.68) end
        tip:AddLine(" ")
        MatsTip(tip, e.r)
      end,
    }
  end
  state.footer = #list > 0 and T("profitFoot") or T("noProfit")
end

---------------------------------------------------------------------------
-- Crafters
---------------------------------------------------------------------------
local function BuildCrafters()
  search:Show(); searchButton:Show()
  searchButton:SetText(T("search"))
  searchHint:SetText(T("searchHint"))
  searchHint:SetShown(search:GetText() == "")
  local res = ns.crafterResults
  for _, r in ipairs(res) do
    data[#data + 1] = {
      icon = r.icon or (r.mine and 134400) or "Interface\\Icons\\INV_Letter_15", name = r.recipe,
      value = r.mine and (r.char .. " |cff8c8f96(" .. T("yours") .. ")|r") or r.char,
      vr = r.mine and 1 or 0.35, vg = r.mine and 0.82 or 0.9, vb = r.mine and 0.3 or 0.4,
      hint = not r.mine and T("clickWhisper") or nil,
      tip = function(tip)
        tip:SetText(r.recipe, 1, 0.82, 0.3)
        tip:AddLine(("%s · %s"):format(r.char, r.prof or ""), 1, 1, 1)
      end,
      click = function() if not r.mine then ns.Whisper(r.sender) end end,
    }
  end
  if not res.query or res.query == "" then
    state.footer = T("craftersFoot")
  elseif #res == 0 then
    state.footer = res.asked and T("asking") or T("noneFound")
  else
    state.footer = res.asked and T("guildAnswers") or ""
  end
end

---------------------------------------------------------------------------
-- Characters
---------------------------------------------------------------------------
local function BuildChars()
  local keys, total = {}, 0
  for key in pairs(ns.db.chars) do keys[#keys + 1] = key end
  table.sort(keys)
  local _, myKey = ns.Me()
  for _, key in ipairs(keys) do
    local c = ns.db.chars[key]
    total = total + (c.money or 0)
    local color = c.class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[c.class]
    data[#data + 1] = {
      icon = c.faction == "h" and "Interface\\Icons\\INV_BannerPVP_01" or "Interface\\Icons\\INV_BannerPVP_02",
      name = (c.name or key) .. "  |cff8c8f96" .. T("lvl", c.level or 0) .. "|r",
      r = color and color.r or 1, g = color and color.g or 1, b = color and color.b or 1,
      value = ns.Money(c.money or 0),
      hint = key ~= myKey and T("rightRemove") or nil,
      click = function(which)
        if which == "RightButton" and key ~= myKey then
          ns.db.chars[key] = nil
          ns.indexDirty = true
          ns.RefreshHub()
        end
      end,
    }
    local profs = {}
    for id, p in pairs(c.profs or {}) do profs[#profs + 1] = { id = id, p = p } end
    table.sort(profs, function(a, b) return a.p.rank > b.p.rank end)
    for _, e in ipairs(profs) do
      local done = e.p.rank >= 300
      data[#data + 1] = {
        indent = 18, icon = ProfIcon(e.id), name = ns.ProfName(e.id),
        value = ("%d/%d"):format(e.p.rank, e.p.max or 300),
        vr = done and 0.35 or 1, vg = done and 0.9 or 1, vb = done and 0.4 or 1,
      }
    end
  end
  state.footer = T("charsFoot", #keys, ns.Money(total))
end

---------------------------------------------------------------------------
-- Gathering
---------------------------------------------------------------------------
local GATHER_ORDER = { 186, 182, 393, 356 }

local function BuildGather()
  local skills = ns.Skills(true)
  if not state.gather then
    for _, id in ipairs(GATHER_ORDER) do
      if skills[id] then state.gather = id; break end
    end
    state.gather = state.gather or 186
  end
  for i, id in ipairs(GATHER_ORDER) do
    local b = Control(i)
    b:SetPoint("TOPLEFT", 14 + (i - 1) * 90, -64)
    b:SetText(ns.ProfName(id))
    local on = id == state.gather
    b.label:SetTextColor(on and 1 or 0.6, on and 0.82 or 0.62, on and 0.3 or 0.68)
    b:SetScript("OnClick", function() state.gather, state.offset = id, 0; ns.RefreshHub() end)
    b:Show()
  end
  local guide = ns.GATHER[state.gather]
  local skill = skills[state.gather]
  local rank = skill and skill.rank or 0
  local f = ns.Faction()
  local current
  for i, step in ipairs(guide.steps) do
    if rank < step[2] then current = i; break end
  end
  local lines = {}
  if not skill then
    lines[#lines + 1] = "|cffff9a59" .. T("notKnown", guide.name) .. "|r"
  else
    lines[#lines + 1] = ("|cffffffff%s %d/%d|r"):format(guide.name, rank, skill.max or 300)
    for _, r in ipairs(guide.ranks) do
      if (skill.max or 0) <= r.at and rank >= r.need - 25 then
        lines[#lines + 1] = "|cffff9a59" .. T("learnAt", r.need, r.lvl, r[f]) .. "|r"
        break
      end
    end
  end
  local step = guide.steps[current or 1]
  if rank >= 300 then
    lines[#lines + 1] = "|cff59e566" .. T("done") .. "|r"
  else
    lines[#lines + 1] = ("|cffffd24a%d-%d:|r %s"):format(step[1], step[2], step.what)
    lines[#lines + 1] = "|cff8c8f96" .. T("where") .. "|r " .. step[f]
    if step.note then lines[#lines + 1] = "|cffbfb899" .. step.note .. "|r" end
  end
  detail:SetText(table.concat(lines, "\n"))
  detail:Show()
  listTop = -94 - detail:GetStringHeight() - 10
  for i, s in ipairs(guide.steps) do
    local now, past = i == current, rank >= s[2]
    data[#data + 1] = {
      icon = guide.icon, name = ("%d-%d  %s"):format(s[1], s[2], s.what),
      r = now and 1 or (past and 0.45 or 0.85), g = now and 0.82 or (past and 0.47 or 0.87), b = now and 0.3 or (past and 0.5 or 0.9),
      tip = function(tip)
        tip:SetText(("%d-%d"):format(s[1], s[2]), 1, 0.82, 0.3)
        tip:AddLine(s.what, 1, 1, 1, true)
        tip:AddLine(T("where") .. " " .. s[f], 0.85, 0.87, 0.9, true)
        if s.note then tip:AddLine(s.note, 0.75, 0.72, 0.6, true) end
      end,
    }
  end
  state.footer = T("source", ns.SOURCE)
end

---------------------------------------------------------------------------
function ns.RefreshHub()
  if not H:IsShown() or not ns.db then return end
  wipe(data)
  for _, b in ipairs(controls) do b:Hide() end
  search:Hide(); searchButton:Hide(); detail:Hide()
  listTop = -94
  state.footer = nil
  for i, b in ipairs(tabButtons) do
    b:SetText(T("t_" .. b.key))
    local on = b.key == state.tab
    b.label:SetTextColor(on and 1 or 0.6, on and 0.82 or 0.62, on and 0.3 or 0.68)
    if on then
      tabLine:ClearAllPoints()
      tabLine:SetPoint("TOPLEFT", b, "BOTTOMLEFT", 0, 0)
      tabLine:SetPoint("TOPRIGHT", b, "BOTTOMRIGHT", 0, 0)
    end
  end
  ns.UpdateMe()
  local build = ({ recipes = BuildRecipes, profit = BuildProfit, crafters = BuildCrafters, chars = BuildChars, gather = BuildGather })[state.tab]
  build()
  state.offset = math.min(state.offset, math.max(0, #data - ROWS))
  ns.DrawHub()
end

H:SetScript("OnShow", function()
  ns.PlaceSaved(H, "CraftETAHub", "CENTER")
  ns.RefreshHub()
end)

function ns.ToggleHub(tab)
  if tab then state.tab, state.offset = tab, 0 end
  if H:IsShown() and not tab then H:Hide() else H:Show(); ns.RefreshHub() end
end

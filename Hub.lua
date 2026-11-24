-- CraftETA: the main window. A menu on the left (Home, Alts, Professions, Specializations, Crafters,
-- Gold, Codex, Camping, Cooldowns, Settings) and the page on the right.
local _, ns = ...
local T = ns.T
local GetItemInfoInstant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant

local WIDTH, HEIGHT, SIDE, ROWS, ROW_H = 900, 620, 196, 23, 20
local X = SIDE + 16           -- where the page starts
local CW = WIDTH - X - 18     -- page width
local H = ns.Window("CraftETAHub", WIDTH)
ns.Hub = H
H:SetHeight(HEIGHT)
H.title:Hide()
H.close:ClearAllPoints()
H.close:SetPoint("TOPRIGHT", -6, -6)
H.close:SetSize(16, 16)
H.close:SetHitRectInsets(-4, -4, -4, -4)
-- no square behind the x: it cut a notch into the rounded corner. The x turns gold on hover instead.
ns.HUB_X, ns.HUB_CW = X, CW

local state = { tab = "home", codex = "recipes", filter = "all", profitMode = "craft", offset = 0 }
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
local MENU = {
  { "home", "Interface\\Icons\\INV_Misc_Note_01" },
  { "alts", "Interface\\Icons\\INV_Misc_GroupLooking" },
  { "guide", "Interface\\Icons\\INV_Misc_Book_11" },
  { "specs", "Interface\\Icons\\INV_Misc_Note_06" },
  { "crafters", "Interface\\Icons\\INV_Letter_15" },
  { "gold", "Interface\\Icons\\INV_Misc_Coin_02" },
  { "profit", "Interface\\Icons\\INV_Misc_Coin_17" },
  { "codex", "Interface\\Icons\\INV_Scroll_03" },
  { "camping", "Interface\\Icons\\Spell_Fire_Fire" },
  { "cooldowns", "Interface\\Icons\\INV_Misc_PocketWatch_01" },
  { "favor", "Interface\\Icons\\INV_Crate_01" },
  { "settings", "Interface\\Icons\\INV_Misc_Gear_01", function() ns.ToggleSettings() end },
}
-- the menu column: its own darker card, like the rest of the ETA family
local side = CreateFrame("Frame", nil, H)
side:SetPoint("TOPLEFT", 10, -10)
side:SetPoint("BOTTOMLEFT", 10, 10)
side:SetWidth(SIDE - 10)
local sideBg = side:CreateTexture(nil, "BORDER")
sideBg:SetAllPoints()
sideBg:SetColorTexture(0, 0, 0, 0.28)
local logo = side:CreateTexture(nil, "ARTWORK")
logo:SetSize(26, 26)
logo:SetPoint("TOPLEFT", 12, -14)
logo:SetTexture(ns.TEX .. "Logo")
local logoText = ns.Font(side, true, 15)
logoText:SetPoint("TOPLEFT", logo, "TOPRIGHT", 9, 1)
logoText:SetText("|cffffffffCraft|r|cffffd24aETA|r")
local logoSub = ns.Font(side, false, 10, 0.55, 0.58, 0.64)
logoSub:SetPoint("TOPLEFT", logoText, "BOTTOMLEFT", 0, -2)
logoSub:SetText("by Xtreamcoder")

local menuButtons = {}
local my = -62
for _, item in ipairs(MENU) do
  local key, icon, action = item[1], item[2], item[3]
  local b = CreateFrame("Button", nil, side)
  b:SetSize(SIDE - 26, 28)
  b:SetPoint("TOPLEFT", 8, my)
  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetSize(18, 18)
  b.icon:SetPoint("LEFT", 10, 0)
  b.icon:SetTexture(icon)
  b.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  b.text = ns.Font(b, true, 12)
  b.text:SetPoint("LEFT", b.icon, "RIGHT", 10, 0)
  b.sel = b:CreateTexture(nil, "BACKGROUND")
  b.sel:SetAllPoints()
  b.sel:SetColorTexture(1, 0.82, 0.3, 0.11)
  b.bar = b:CreateTexture(nil, "ARTWORK")
  b.bar:SetPoint("TOPLEFT"); b.bar:SetPoint("BOTTOMLEFT"); b.bar:SetWidth(3); b.bar:SetAlpha(0)
  b.bar:SetColorTexture(1, 0.82, 0.3, 1)
  local hl = b:CreateTexture(nil, "HIGHLIGHT")
  hl:SetAllPoints()
  hl:SetColorTexture(1, 1, 1, 0.04)
  b.key, b.action = key, action
  b:SetScript("OnClick", function()
    if action then action() return end
    state.tab, state.offset = key, 0
    ns.RefreshHub()
  end)
  menuButtons[#menuButtons + 1] = b
  my = my - 30
end

-- the bottom of the menu: item tracker, shopping list, and who you are
local farmButton = ns.Button(side, "", SIDE - 34, 22)
farmButton:SetPoint("BOTTOMLEFT", 12, 80)
farmButton:SetScript("OnClick", function()
  ns.ToggleFarm()
  ns.RefreshHub()
end)
local trackerButton = ns.Button(side, "", SIDE - 62, 22)
trackerButton:SetPoint("BOTTOMLEFT", 12, 52)
trackerButton:SetScript("OnClick", function() ns.ToggleTracker() end)
-- Start farming and Item tracker are not used here any more: hidden (still under /ceta farm and /ceta track)
farmButton:Hide()
trackerButton:Hide()
local listButton = ns.IconButton(side, "Interface\\Icons\\INV_Misc_Note_05", 22, function() return T("list") end)
listButton:SetPoint("BOTTOMLEFT", 12, 52)
listButton:SetScript("OnClick", function() ns.ToggleList() end)
-- scan the auction house: only what CraftETA uses, fast (Ladder.lua)
local scanBtn = ns.Primary(ns.Button(side, "", SIDE - 52, 22), 11)
scanBtn:SetPoint("LEFT", listButton, "RIGHT", 6, 0)
scanBtn:SetScript("OnClick", function() if ns.QuickScan then ns.QuickScan() end end)
local function Ago(t)
  local m = math.floor((time() - t) / 60)
  if m < 1 then return (ns.db.lang == "da") and "lige nu" or "just now" end
  if m < 60 then return ((ns.db.lang == "da") and "for %d min siden" or "%d min ago"):format(m) end
  return ((ns.db.lang == "da") and "for %d t siden" or "%d h ago"):format(math.floor(m / 60))
end
function ns.UpdateScanButton()
  if not ns.db then return end
  local da = ns.db.lang == "da"
  local i, n, last = ns.QuickScanState()
  local atAH = AuctionHouseFrame and AuctionHouseFrame:IsShown()
  if i == "browse" then
    scanBtn:SetText((da and "Henter priser... %d" or "Getting prices... %d"):format(n or 0))
    scanBtn:Enable()
  elseif i then
    scanBtn:SetText((da and "Indkøbsliste %d / %d" or "Shopping list %d / %d"):format(math.min(i, n), n))
    scanBtn:Enable()
  else
    scanBtn:SetText(da and "Scan AH" or "Scan AH")
    scanBtn:SetEnabled(atAH and true or false)
  end
  scanBtn.tip = (i and (da and "Klik for at stoppe." or "Click to stop.") or
    ((da and "Scanner kun det CraftETA bruger: din indkøbsliste, resten af dine professions ruter og favor-kassernes mats. Hurtigt, ikke en fuld scan."
      or "Scans only what CraftETA uses: your shopping list, the rest of your professions' routes and the favor crates' materials. Fast, not a full scan.")
    .. (atAH and "" or ("\n" .. (da and "Åbn auktionshuset først." or "Open the auction house first.")))))
    .. (last and ("\n" .. (da and "Sidste scan: " or "Last scan: ") .. Ago(last)) or "")
end
local meName = ns.Font(side, true, 12)
meName:SetPoint("BOTTOMLEFT", 14, 28)
local meSub = ns.Font(side, false, 10, 0.55, 0.58, 0.64)
meSub:SetPoint("BOTTOMLEFT", 14, 14)
local version = ns.Font(side, false, 9, 0.42, 0.44, 0.48)
version:SetPoint("BOTTOMRIGHT", -10, 14)
version:SetJustifyH("RIGHT")
version:SetText("v" .. ((C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata)("CraftETA", "Version") or ""))

-- up to 5 small buttons under the tabs (professions, filters, modes)
local controls = {}
local function Control(i)
  local b = controls[i]
  if not b then
    b = ns.Button(H, "", 86, 20)
    b.grow = true
    controls[i] = b
  end
  b:ClearAllPoints() -- each page places its own
  b.grow = true
  if b.baseSize and b.label then                 -- a squeezed row last time: its normal font back
    local font, _, flags = b.label:GetFont()
    if font then b.label:SetFont(font, b.baseSize, flags) end
  end
  b:SetWidth(86)
  return b
end

-- every button wide enough for its text (Leatherworking, Blacksmithing); the ones after it on the same row
-- move along so nothing overlaps
local function FitControls()
  local byRow = {}
  for _, b in ipairs(controls) do
    if b:IsShown() then
      local point, rel, _, x, y = b:GetPoint(1)
      if point == "TOPLEFT" and (rel == H or rel == nil) and x and y then
        local w = b.label and b.label:GetStringWidth() or 0
        if w + 20 > b:GetWidth() then b:SetWidth(math.ceil(w + 20)) end
        local key = math.floor(y + 0.5)
        byRow[key] = byRow[key] or {}
        table.insert(byRow[key], { b = b, x = x, y = y })
      end
    end
  end
  -- where a row must end: the content's right edge, or the left of a button pinned top right on that row
  -- (All professions / My professions, Back)
  local function Limit(y)
    local limit = X + CW
    for _, f in ipairs(ns.hubRightFrames or {}) do
      if f:IsShown() then
        local fp, _, _, fx, fy = f:GetPoint(1)
        if fp == "TOPRIGHT" and fy and math.abs(fy - y) < 4 then
          limit = math.min(limit, (H:GetWidth() or 0) + (fx or 0) - f:GetWidth() - 8)
        end
      end
    end
    return limit
  end
  for _, row in pairs(byRow) do
    table.sort(row, function(a, b) return a.x < b.x end)
    local shift, right = 0, nil
    for _, e in ipairs(row) do
      local x = e.x + shift
      if right and x < right + 4 then shift = shift + (right + 4 - x); x = right + 4 end
      e.nx = x
      right = x + e.b:GetWidth()
    end
    -- too wide for the room: every button in the row gets narrower (a smaller font where needed)
    local limit = Limit(row[1].y)
    if right and right > limit then
      local start, gaps, sum = row[1].x, 4 * (#row - 1), 0
      for _, e in ipairs(row) do sum = sum + e.b:GetWidth() end
      local scale = math.max(0.4, (limit - start - gaps) / sum)
      local x = start
      for _, e in ipairs(row) do
        e.b.grow = false
        e.b:SetWidth(math.floor(e.b:GetWidth() * scale))
        e.nx = x
        x = x + e.b:GetWidth() + 4
      end
    end
    for _, e in ipairs(row) do
      if e.nx ~= e.x then e.b:ClearAllPoints(); e.b:SetPoint("TOPLEFT", H, "TOPLEFT", e.nx, e.y) end
    end
  end
end

local search = CreateFrame("EditBox", nil, H)
search:SetSize(CW - 96, 20)
search:SetPoint("TOPLEFT", X, -22)
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
detail:SetPoint("TOPLEFT", X, -48)
detail:SetWidth(CW)
detail:SetWordWrap(true)
detail:SetSpacing(3)
local detailBg = H:CreateTexture(nil, "BACKGROUND", nil, 1)
detailBg:SetPoint("TOPLEFT", detail, "TOPLEFT", -10, 8)
detailBg:SetPoint("BOTTOMRIGHT", detail, "BOTTOMRIGHT", 10, -8)
detailBg:SetColorTexture(0, 0, 0, 0.26)
detailBg:Hide()

---------------------------------------------------------------------------
-- The list
---------------------------------------------------------------------------
local rows = {}
for i = 1, ROWS do
  local r = ns.Row(H, ROW_H - 2)
  r:SetWidth(CW)
  -- each row is a small card; a section heading is text with a line under it
  r.card = r:CreateTexture(nil, "BACKGROUND", nil, -1)
  r.card:SetAllPoints()
  r.card:SetColorTexture(0.086, 0.094, 0.122, 1)
  r.line = r:CreateTexture(nil, "BORDER")
  r.line:SetPoint("BOTTOMLEFT", 0, 2); r.line:SetPoint("BOTTOMRIGHT", 0, 2); r.line:SetHeight(1)
  r.line:SetColorTexture(0.2, 0.21, 0.25, 1)
  r.sub = ns.Font(r, false, 9, 0.5, 0.52, 0.57)
  r.sub:SetWordWrap(false)
  r.bg = r:CreateTexture(nil, "BACKGROUND")
  r.bg:SetAllPoints()
  r.bar = r:CreateTexture(nil, "BORDER")
  r.bar:SetPoint("TOPLEFT"); r.bar:SetPoint("BOTTOMLEFT"); r.bar:SetWidth(2); r.bar:SetAlpha(0)
  r.bar:SetColorTexture(1, 0.82, 0.3, 1)
  r.check = r:CreateTexture(nil, "ARTWORK")
  r.check:SetSize(12, 12)
  r.check:SetPoint("LEFT", 8, 0)
  r.check:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
  r.range = ns.Font(r, true, 10)
  r.range:SetPoint("LEFT", 24, 0)
  r.range:SetWidth(54)
  r.range:SetJustifyH("LEFT")
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
footer:SetPoint("BOTTOMLEFT", X, 16)
footer:SetPoint("RIGHT", H, "RIGHT", -14, 0)

H:EnableMouseWheel(true)
H:SetScript("OnMouseWheel", function(_, delta)
  local top = math.max(0, #data - 6)
  state.offset = math.max(0, math.min(top, state.offset - delta * 3))
  ns.DrawHub()
end)

local TOP = -58
local listTop = TOP
-- a row's name with a grey part at the end ("Name  |cff8c8f96details|r"): the details go on a second line
local function Split(d)
  local name = d.name or ""
  if d.head or type(name) ~= "string" then return name, nil end
  local a, b = name:match("^(.-)%s%s+|cff8c8f96(.-)|r%s*$")
  if a and a ~= "" and b and b ~= "" then return a, b end
  return name, nil
end

function ns.DrawHub()
  local bottom = -(H:GetHeight() - 40)
  local y, shown = listTop, 0
  for i = 1, ROWS do
    local r, d = rows[i], data[i + state.offset]
    local name, sub
    if d then name, sub = Split(d) end
    local h = d and (d.head and 30 or (sub and 34 or 26)) or 0
    if d and y - h + 3 >= bottom then
      local indent = d.indent or 0
      if not d.head then indent = math.max(0, indent - 8) end
      r:ClearAllPoints()
      r:SetPoint("TOPLEFT", X + indent, y)
      r:SetWidth(CW - indent)
      r:SetHeight(h - 3)
      r.data = d
      r.card:SetShown(not d.head)
      r.line:SetShown(d.head and true or false)
      local size = sub and 24 or 18
      r.icon:SetSize(size, size)
      r.icon:SetTexture(d.icon)
      r.icon:SetShown(d.icon ~= nil and not d.head)
      r.icon:ClearAllPoints()
      r.icon:SetPoint("LEFT", d.range and 82 or 8, 0)
      r.icon:SetDesaturated(d.done and true or false)
      r.icon:SetAlpha(d.done and 0.6 or 1)
      r.range:SetText(d.range or "")
      r.range:SetTextColor(d.current and 1 or 0.5, d.current and 0.82 or 0.52, d.current and 0.3 or 0.56)
      r.check:SetShown(d.done and true or false)
      r.bar:SetShown(d.current and true or false)
      if d.current then
        r.bg:SetColorTexture(1, 0.82, 0.3, 0.09); r.bg:Show()
      else
        r.bg:Hide()
      end
      -- where the text starts: after the icon, or at the card's edge
      r.name:ClearAllPoints(); r.sub:ClearAllPoints()
      local anchorX = d.head and 2 or ((d.icon and (d.range and 82 or 8) + size + 8) or (d.range and 82 or 10))
      if d.head then
        r.name:SetPoint("BOTTOMLEFT", r, "BOTTOMLEFT", 2, 7)
        r.name:SetFont(ns.F_BOLD, 10, "")
        r.name:SetTextColor(0.62, 0.55, 0.36)
      elseif sub then
        r.name:SetPoint("TOPLEFT", r, "TOPLEFT", anchorX, -4)
        r.sub:SetPoint("BOTTOMLEFT", r, "BOTTOMLEFT", anchorX, 5)
        r.sub:SetPoint("RIGHT", r.value, "LEFT", -8, 0)
        r.name:SetFont(ns.F_SEMI, 11, "")
      else
        r.name:SetPoint("LEFT", r, "LEFT", anchorX, 0)
        r.name:SetFont(ns.F_SEMI, 11, "")
      end
      r.name:SetPoint("RIGHT", r.value, "LEFT", -8, 0)
      r.name:SetText(d.head and string.upper(name) or name)
      if not d.head then r.name:SetTextColor(d.r or 0.85, d.g or 0.87, d.b or 0.9) end
      r.sub:SetText(sub or ""); r.sub:SetShown(sub ~= nil)
      r.value:ClearAllPoints(); r.value:SetPoint("RIGHT", r, "RIGHT", d.head and -2 or -10, d.head and -2 or 0)
      r.value:SetText(d.value or "")
      r.value:SetTextColor(d.vr or 1, d.vg or 1, d.vb or 1)
      r:Show()
      y = y - h
      shown = shown + 1
    else
      r:Hide()
      r.data = nil
    end
  end
  local more = #data - shown - state.offset
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
    local price = ns.MatPrice(name)
    local have = ns.Have(name)
    tip:AddDoubleLine(("%dx %s |cff8c8f96(%s %d)|r"):format(n, name, T("have"), have),
      price and ns.Money(price * n) or T("unknownPrice"), 0.85, 0.87, 0.9, 1, 1, 1)
  end
end

local function BuildRecipes(first)
  first = first or 0
  local me = ns.Me()
  local profs = {}
  for id in pairs(me and me.book or {}) do profs[#profs + 1] = id end
  table.sort(profs)
  if not state.prof or not (me and me.book[state.prof]) then state.prof = profs[1] end
  local n = 0
  for i, id in ipairs(profs) do
    if i > 3 then break end
    local b = Control(first + i)
    b:SetText(ns.ProfName(id))
    b:SetPoint("TOPLEFT", X + (i - 1) * 90 + (state.ctrlShift or 0), -22)
    b.label:SetTextColor(id == state.prof and 1 or 0.6, id == state.prof and 0.82 or 0.62, id == state.prof and 0.3 or 0.68)
    b:SetScript("OnClick", function() state.prof, state.offset = id, 0; ns.RefreshHub() end)
    b:Show()
    n = i
  end
  local f = Control(first + n + 1)
  f:SetPoint("TOPLEFT", X + (state.ctrlShift or 0) + n * 90 + 10, -22)
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
      value = cost > 0 and ((missing and "~" or "") .. ns.MoneyShort(cost)) or "",
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
    b:SetPoint("TOPLEFT", X + (i - 1) * 90 + (state.ctrlShift or 0), -22)
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
        hint = (m[3] and (mine and T("youGather", ns.ProfName(m[3])) or T("needProf", ns.ProfName(m[3]))) or T("fromMobs")) .. "\n" .. T("rightTrack"),
        click = function(which) if which == "RightButton" then ns.TrackItem(m[1]) end end,
      }
    end
    state.footer = #list > 0 and T("farmFoot") or T("noPrices", ns.AHName())
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
    local even = math.abs(e.gain) < 0.5   -- less than a copper either way: no "-0c"
    data[#data + 1] = {
      icon = e.r.i or 134400, name = e.r.n,
      value = even and "0c" or ((up and "+" or "-") .. ns.Money(math.abs(e.gain))),
      vr = even and 0.6 or (up and 0.35 or 1), vg = even and 0.62 or (up and 0.9 or 0.4), vb = even and 0.67 or (up and 0.4 or 0.35),
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
  state.footer = #list > 0 and T("profitFoot", ns.AHName()) or T("noProfit")
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
      icon = r.icon or (r.mine and 134400) or (r.ad and "Interface\\Icons\\INV_Misc_Note_02") or "Interface\\Icons\\INV_Letter_15", name = r.recipe,
      value = r.mine and (r.char .. " |cff8c8f96(" .. T("yours") .. ")|r") or (r.ad and (r.char .. " |cff8c8f96(" .. T("adTrade") .. ")|r")) or r.char,
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
    state.footer = (res.asked and not res.waited) and T("asking") or T("noneFoundHelp")
  else
    state.footer = (res.asked and not res.waited) and T("guildAnswers") or ""
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
-- Professions: your crafting and gathering professions, the step you are on and the route 1-300
---------------------------------------------------------------------------
local ORDER = { 171, 164, 333, 202, 165, 197, 186, 182, 393, 185, 129, 356 }

local function Guide(id) return ns.GUIDES[id] or ns.GATHER[id] end

local RANK_NAME = { [75] = "Journeyman", [150] = "Expert", [225] = "Artisan" }
local function RankLine(guide, skill, f)
  for _, r in ipairs(guide.ranks) do
    if (skill.max or 0) <= r.at and skill.rank >= r.need - 25 then
      local name = RANK_NAME[r.at] or ""
      local text = skill.rank >= r.need and T("learnNow", name, r.lvl, r[f]) or T("learnAt2", name, r.need, r.lvl, r[f])
      return "|cffff9a59" .. text .. "|r"
    end
  end
end

local function CraftStepText(id, index, step)
  local parts = {}
  for _, e in ipairs((ns.Chosen(id, index, step))) do
    parts[#parts + 1] = ("%s x%d"):format(e[1], e[2])
  end
  return table.concat(parts, step.any and " / " or ", ")
end

local function BuildGuide()
  local skills = ns.Skills(true)
  local mine = {}
  for _, id in ipairs(ORDER) do
    if skills[id] then mine[#mine + 1] = id end
  end
  if #mine == 0 then state.allProfs = true end
  -- your professions, or all twelve: follow a route you haven't learned yet
  local list = state.allProfs and ORDER or mine
  local found = false
  for _, id in ipairs(list) do if id == state.guide then found = true end end
  if not found then state.guide = list[1] end
  local PER_ROW = state.stepsOpen and 4 or 5
  for i, id in ipairs(list) do
    local b = Control(i)
    b:ClearAllPoints()
    b:SetPoint("TOPLEFT", X + ((i - 1) % PER_ROW) * 90, -22 - math.floor((i - 1) / PER_ROW) * 26)
    b:SetText(ns.ProfName(id))
    local on = id == state.guide
    local have = skills[id] ~= nil
    b.label:SetTextColor(on and 1 or (have and 0.75 or 0.5), on and 0.82 or (have and 0.77 or 0.52), on and 0.3 or (have and 0.8 or 0.56))
    b:SetScript("OnClick", function() state.guide, state.offset = id, 0; ns.RefreshHub() end)
    b:Show()
  end
  local toggle = Control(#list + 1)
  toggle:ClearAllPoints()
  toggle:SetPoint("TOPRIGHT", H, "TOPRIGHT", -48, -22)
  ns.hubRightFrames = ns.hubRightFrames or {}
  if not toggle.listed then toggle.listed = true; table.insert(ns.hubRightFrames, toggle) end
  toggle:SetWidth(124)
  toggle:SetText(state.allProfs and T("myProfs") or T("allProfs"))
  toggle.label:SetTextColor(1, 0.82, 0.3)
  toggle:SetScript("OnClick", function()
    state.allProfs = not state.allProfs
    state.offset = 0
    ns.RefreshHub()
  end)
  toggle:SetShown(#mine > 0)
  local extra = (math.ceil(#list / PER_ROW) - 1) * 26
  local id = state.guide
  local guide = Guide(id)
  local crafting = ns.GUIDES[id] ~= nil
  local skill = skills[id]
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
    local warn = RankLine(guide, skill, f)
    if warn then lines[#lines + 1] = warn end
  end
  if rank >= 300 then
    lines[#lines + 1] = "|cff59e566" .. T("done") .. "|r"
  elseif current then
    local step = guide.steps[current]
    if crafting then
      lines[#lines + 1] = ("|cffffd24a%d-%d:|r %s"):format(step[1], step[2], CraftStepText(id, current, step))
      if skill then
        local target = ns.Target(id, rank, skill.max)
        local crafts, mats = ns.Plan(id, rank, target)
        local cost, unknown = ns.Cost(mats)
        local eta = ns.Duration(ns.TimeFor(id, target - rank, crafts))
        lines[#lines + 1] = "|cff8c8f96" .. T("toRank", target) .. ":|r " .. T("crafts", crafts)
          .. (cost > 0 and ("  ·  " .. (unknown and "~" or "") .. ns.MoneyShort(cost)) or "") .. (eta and ("  ·  " .. T("eta", eta)) or "")
      end
      if not skill then
        -- a profession you don't have: what the whole route takes
        local crafts, mats = ns.Plan(id, 1, 300)
        local cost, unknown = ns.Cost(mats)
        lines[#lines + 1] = "|cff8c8f96" .. T("wholeRoute") .. ":|r " .. T("crafts", crafts)
          .. (cost > 0 and ("  ·  " .. (unknown and "~" or "") .. ns.MoneyShort(cost)) or "")
      end
    else
      lines[#lines + 1] = ("|cffffd24a%d-%d:|r %s"):format(step[1], step[2], step.what)
      lines[#lines + 1] = "|cff8c8f96" .. T("where") .. "|r " .. step[f]
    end
    if step.note then lines[#lines + 1] = "|cffbfb899" .. step.note .. "|r" end
  end
  -- the route as a bar on top (Home.lua draws it), the step text under it, then the steps
  local tlH = (ns.ShowTimeline and ns.ShowTimeline(id, guide, skill, current, data, extra) or 0) + extra
  -- the step as cards (GuideView.lua); "All steps" shows the whole route as a list instead
  if ns.ShowGuideView and not state.stepsOpen then
    ns.ShowGuideView(id, guide, skill, current, TOP - tlH - 10)
    listTop = -2000
    state.footer = ""
    return
  end
  if ns.ShowGuideView then
    local back = Control(#list + 2)
    back:ClearAllPoints()
    back:SetPoint("TOPRIGHT", H, "TOPRIGHT", -178, -22)
    ns.hubRightFrames = ns.hubRightFrames or {}
    if not back.listed then back.listed = true; table.insert(ns.hubRightFrames, back) end
    back:SetWidth(124)
    back:SetText((ns.db.lang == "da") and "Tilbage til trinnet" or "Back to the step")
    back.label:SetTextColor(1, 0.82, 0.3)
    back:SetScript("OnClick", function() state.stepsOpen = nil; state.offset = 0; ns.RefreshHub() end)
    back:Show()
  end
  detail:ClearAllPoints()
  detail:SetPoint("TOPLEFT", X + 10, TOP - tlH - 20)
  detail:SetWidth(CW - 20)
  detail:SetText(table.concat(lines, "\n"))
  detail:Show(); detailBg:Show()
  listTop = TOP - tlH - 20 - detail:GetStringHeight() - 20
  for i, s in ipairs(guide.steps) do
    local now, past = i == current, rank >= s[2]
    local chosen = crafting and (ns.Chosen(id, i, s)) or nil
    local name, count = s.what, nil
    local stepNet = chosen and not past and ns.StepNet(id, i, s) or nil
    if chosen then
      name, count = chosen[1][1], chosen[1][2]
      if #chosen > 1 then name = name .. " |cff8c8f96+" .. (#chosen - 1) .. "|r" end
    end
    data[#data + 1] = {
      icon = chosen and ns.ItemIcon(chosen[1][1], ProfIcon(id)) or guide.icon or ProfIcon(id),
      range = ("%d-%d"):format(s[1], s[2]), name = name, current = now, done = past, zebra = i % 2 == 0,
      value = count and ("x" .. count .. (stepNet and (stepNet.unpriced < stepNet.crafts and ("  " .. ns.StepProfitShort(stepNet)) or "") or "")) or "",
      vr = past and 0.45 or (now and 1 or 0.75), vg = past and 0.47 or (now and 0.82 or 0.77), vb = past and 0.5 or (now and 0.3 or 0.8),
      r = now and 1 or (past and 0.45 or 0.85), g = now and 0.82 or (past and 0.47 or 0.87), b = now and 0.3 or (past and 0.5 or 0.9),
      tip = function(tip)
        tip:SetText(("%d-%d"):format(s[1], s[2]), 1, 0.82, 0.3)
        if crafting then
          for _, e in ipairs(ns.Entries(s)) do
            tip:AddLine(("%s x%d"):format(e[1], e[2]), 1, 1, 1)
            local mats = e[3]
            for m = 1, #mats, 2 do
              tip:AddDoubleLine("   " .. mats[m], ("%d  |cff8c8f96(%s %d)|r"):format(mats[m + 1], T("have"), ns.Have(mats[m])), 0.85, 0.87, 0.9, 1, 1, 1)
            end
          end
          if s.any then tip:AddLine(T("anyOne"), 0.6, 0.62, 0.68) end
          local sn = ns.StepNet(id, i, s)
          for _, e in ipairs(sn.entries) do
            tip:AddLine(" ")
            tip:AddDoubleLine(("%s x%d"):format(e.entry[1], e.n), ns.ProfitText(e.net), 1, 1, 1, 1, 1, 1)
            if e.net.sell then
              tip:AddDoubleLine("   " .. (ns.db.lang == "da" and "Materialer / sælger" or "Materials / sells"),
                ns.Money(e.net.cost) .. " / " .. ns.Money(e.net.sell * e.net.y), 0.7, 0.72, 0.76, 0.85, 0.87, 0.9)
            end
          end
          if sn.unpriced < sn.crafts then
            tip:AddDoubleLine(ns.db.lang == "da" and "Hele trinnet (efter AH's 5%)" or "Whole step (after the AH's 5%)", (sn.profit >= 0 and "|cff5cd67c" or "|cffe6594d") .. ns.SignedMoney(sn.profit) .. "|r", 1, 0.82, 0.3, 1, 1, 1)
          end
          if sn.unpriced > 0 then
            tip:AddLine(ns.db.lang == "da" and ("Ingen pris på " .. sn.unpriced .. " crafts: scan AH") or (sn.unpriced .. " crafts have no price: scan the AH"), 0.9, 0.35, 0.3, true)
          end
        else
          tip:AddLine(s.what, 1, 1, 1, true)
          tip:AddLine(T("where") .. " " .. s[f], 0.85, 0.87, 0.9, true)
        end
        if s.note then tip:AddLine(s.note, 0.75, 0.72, 0.6, true) end
      end,
    }
  end
  state.footer = nil
end

---------------------------------------------------------------------------
ns.HubCustom = {}      -- pages with their own layout (Home, Alts): key -> frame with :Refresh()
ns.HubBuilders = {}    -- list pages from other files

function ns.RefreshHub()
  if not H:IsShown() or not ns.db then return end
  -- the close button stays on top of every page (Favor and Crafters have cards up there)
  H.close:SetFrameLevel(H:GetFrameLevel() + 60)
  wipe(data)
  for _, b in ipairs(controls) do b:Hide() end
  search:Hide(); searchButton:Hide(); detail:Hide(); detailBg:Hide()
  if ns.HideTimeline then ns.HideTimeline() end
  if ns.HideGuideView then ns.HideGuideView() end
  listTop = TOP
  state.footer = nil
  state.ctrlShift = 0
  for _, b in ipairs(menuButtons) do
    b.text:SetText(T("t_" .. b.key))
    local on = b.key == state.tab
    b.sel:SetShown(on); b.bar:SetShown(on)
    b.text:SetTextColor(on and 1 or 0.78, on and 0.82 or 0.8, on and 0.3 or 0.84)
  end
  ns.UpdateMe()
  local me = ns.Me()
  local color = me and me.class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[me.class]
  meName:SetText(me and me.name or "")
  if color then meName:SetTextColor(color.r, color.g, color.b) end
  meSub:SetText(me and T("lvlClass", me.level or 0, UnitClass("player") or "") or "")
  if ns.UpdateScanButton then ns.UpdateScanButton() end
  trackerButton:SetText(T("tracker"))
  farmButton:SetText(ns.FarmActive and ns.FarmActive() and T("farmStop") or T("farmStart"))
  for key, frame in pairs(ns.HubCustom) do frame:SetShown(key == state.tab) end
  local custom = ns.HubCustom[state.tab]
  if custom then
    for _, r in ipairs(rows) do r:Hide() end
    footer:SetText("")
    custom:Refresh()
    return
  end
  local build = ({ guide = BuildGuide, crafters = BuildCrafters, gold = BuildProfit,
    codex = function()
      -- Codex: recipes or materials
      for i, mode in ipairs({ "recipes", "materials" }) do
        local b = Control(i)
        b:SetPoint("TOPLEFT", X + (i - 1) * 90, -22)
        b:SetText(T("c_" .. mode))
        local on = state.codex == mode
        b.label:SetTextColor(on and 1 or 0.6, on and 0.82 or 0.62, on and 0.3 or 0.68)
        b:SetScript("OnClick", function() state.codex, state.offset = mode, 0; ns.RefreshHub() end)
        b:Show()
      end
      state.ctrlShift = 2 * 90 + 14
      if state.codex == "materials" then
        ns.HubBuilders.materials(data, state, Control)
      else
        BuildRecipes(2)
      end
    end })[state.tab] or ns.HubBuilders[state.tab]
  if build then build(data, state, Control) end
  FitControls()
  state.offset = math.min(state.offset, math.max(0, #data - ROWS))
  ns.DrawHub()
end

H:SetScript("OnShow", function()
  ns.PlaceSaved(H, "CraftETAHub", "CENTER")
  if ns.AskPlayed then ns.AskPlayed() end
  ns.RefreshHub()
end)

function ns.ToggleHub(tab)
  if tab then state.tab, state.offset = tab, 0 end
  if H:IsShown() and not tab then H:Hide() else H:Show(); ns.RefreshHub() end
end

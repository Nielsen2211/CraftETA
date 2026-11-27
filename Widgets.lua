-- CraftETA: the ETA family look (dark panel, Inter, gold accent) for every window.
local _, ns = ...

function ns.Font(parent, bold, size, r, g, b)
  local t = parent:CreateFontString(nil, "OVERLAY")
  t:SetFont(bold and ns.F_BOLD or ns.F_SEMI, math.max(size or 11, 10), "")
  t:SetShadowOffset(0, 0)
  t:SetTextColor(r or 0.85, g or 0.87, b or 0.9)
  t:SetJustifyH("LEFT")
  return t
end

-- width of the text on one line, without the "..." the client adds when it is too long
function ns.TextWidth(fs)
  if fs.GetUnboundedStringWidth then return fs:GetUnboundedStringWidth() end
  return fs:GetStringWidth()
end

-- set the first text that fits on the font string's line (the last one is used anyway)
function ns.Fit(fs, ...)
  local w = fs:GetWidth() or 0
  local n = select("#", ...)
  for i = 1, n do
    local t = select(i, ...)
    fs:SetText(t)
    if i == n or w <= 0 or ns.TextWidth(fs) <= w + 0.5 then return end
  end
end

-- a list "a, b, c, d" that does not fit becomes "a, b +2" instead of being cut in the middle of a word
function ns.FitList(fs, text)
  fs:SetText(text or "")
  local w = fs:GetWidth() or 0
  if w <= 0 or not text or ns.TextWidth(fs) <= w + 0.5 then return end
  local head, list = text:match("^(.-)(%f[%w][^·]-,.*)$")
  if not list then return end
  local items = {}
  for part in (list .. ","):gmatch("%s*(.-),") do items[#items + 1] = part end
  for keep = #items - 1, 1, -1 do
    fs:SetText(head .. table.concat(items, ", ", 1, keep) .. " +" .. (#items - keep))
    if ns.TextWidth(fs) <= w + 0.5 then return end
  end
end

-- the ETA panel, cut in nine: the rounded corners keep their shape at any window size
function ns.Skin(frame)
  local TW, TH = 1024, 64         -- texture size
  local PW, PH, R = 520, 40, 16   -- the panel in the texture, and its corner
  local S = 0.5                   -- drawn at half size: 20 px top and bottom, 8 px corners
  local function part(name, l, r, layer)
    local t = frame:CreateTexture(nil, layer or "BACKGROUND")
    t:SetTexture(ns.TEX .. name)
    t:SetTexCoord(l / TW, r / TW, 0, PH / TH)
    return t
  end
  local h, c = PH * S, R * S
  local tl = part("PanelTop", 0, R); tl:SetSize(c, h); tl:SetPoint("TOPLEFT")
  local tr = part("PanelTop", PW - R, PW); tr:SetSize(c, h); tr:SetPoint("TOPRIGHT")
  local tm = part("PanelTop", R, PW - R); tm:SetPoint("TOPLEFT", tl, "TOPRIGHT"); tm:SetPoint("BOTTOMRIGHT", tr, "BOTTOMLEFT")
  local bl = part("PanelBottom", 0, R); bl:SetSize(c, h); bl:SetPoint("BOTTOMLEFT")
  local br = part("PanelBottom", PW - R, PW); br:SetSize(c, h); br:SetPoint("BOTTOMRIGHT")
  local bm = part("PanelBottom", R, PW - R); bm:SetPoint("TOPLEFT", bl, "TOPRIGHT"); bm:SetPoint("BOTTOMRIGHT", br, "BOTTOMLEFT")
  local mid = part("PanelMid", 0, PW)
  mid:SetPoint("TOPLEFT", tl, "BOTTOMLEFT")
  mid:SetPoint("BOTTOMRIGHT", br, "TOPRIGHT")
end

-- One corner shape for every box, card, button and tag: Round.tga (fill) or RoundLine.tga (a thin edge),
-- cut in nine so the corners keep their shape at any size. ns.RADIUS is the corner in UI units.
-- The result works like a texture: SetColorTexture, SetVertexColor, SetPoint, SetAllPoints, Show, Hide...
ns.RADIUS = 6
local ROUND_PARTS = {
  -- texcoords (of 64 px, corner 16) and the two anchors of each part on the box
  { 0, .25, 0, .25, "TOPLEFT" }, { .75, 1, 0, .25, "TOPRIGHT" },
  { 0, .25, .75, 1, "BOTTOMLEFT" }, { .75, 1, .75, 1, "BOTTOMRIGHT" },
  { .25, .75, 0, .25, "TOP" }, { .25, .75, .75, 1, "BOTTOM" },
  { 0, .25, .25, .75, "LEFT" }, { .75, 1, .25, .75, "RIGHT" },
  { .25, .75, .25, .75, "CENTER" },
}
function ns.Round(parent, layer, sub, radius, line)
  local box = parent:CreateTexture(nil, layer or "BACKGROUND", nil, sub or 0)
  local rad = radius or ns.RADIUS
  local parts = {}
  for i, p in ipairs(ROUND_PARTS) do
    local t = parent:CreateTexture(nil, layer or "BACKGROUND", nil, sub or 0)
    t:SetTexture(ns.TEX .. (line and "RoundLine" or "Round"))
    t:SetTexCoord(p[1], p[2], p[3], p[4])
    parts[i] = t
  end
  local tl, tr, bl, br, top, bot, left, right, mid = unpack(parts)
  tl:SetPoint("TOPLEFT", box); tr:SetPoint("TOPRIGHT", box)
  bl:SetPoint("BOTTOMLEFT", box); br:SetPoint("BOTTOMRIGHT", box)
  top:SetPoint("TOPLEFT", tl, "TOPRIGHT"); top:SetPoint("BOTTOMRIGHT", tr, "BOTTOMLEFT")
  bot:SetPoint("TOPLEFT", bl, "TOPRIGHT"); bot:SetPoint("BOTTOMRIGHT", br, "BOTTOMLEFT")
  left:SetPoint("TOPLEFT", tl, "BOTTOMLEFT"); left:SetPoint("BOTTOMRIGHT", bl, "TOPRIGHT")
  right:SetPoint("TOPLEFT", tr, "BOTTOMLEFT"); right:SetPoint("BOTTOMRIGHT", br, "TOPRIGHT")
  mid:SetPoint("TOPLEFT", tl, "BOTTOMRIGHT"); mid:SetPoint("BOTTOMRIGHT", br, "TOPLEFT")
  local o = { box = box, parts = parts }
  -- a box lower than two corners (a 10 px tag) gets a smaller corner, never a broken one
  function o.Fit()
    local w, h = box:GetWidth() or 0, box:GetHeight() or 0
    local r = rad
    if w > 0 and h > 0 then r = math.max(1, math.min(rad, math.floor(math.min(w, h) / 2))) end
    for i = 1, 4 do parts[i]:SetSize(r, r) end
  end
  o.Fit()
  if parent.HookScript then parent:HookScript("OnSizeChanged", o.Fit) end
  local function each(method)
    return function(_, ...) for _, t in ipairs(parts) do t[method](t, ...) end end
  end
  o.SetVertexColor = each("SetVertexColor")
  o.SetAlpha = each("SetAlpha")
  o.SetDrawLayer = each("SetDrawLayer")
  o.SetBlendMode = each("SetBlendMode")
  function o:SetColorTexture(r, g, b, a) for _, t in ipairs(parts) do t:SetVertexColor(r, g, b, a or 1) end end
  function o:Show() for _, t in ipairs(parts) do t:Show() end end
  function o:Hide() for _, t in ipairs(parts) do t:Hide() end end
  function o:SetShown(on) if on then o:Show() else o:Hide() end end
  function o:IsShown() return mid:IsShown() end
  function o:IsVisible() return mid:IsVisible() end
  function o:SetPoint(...) box:SetPoint(...); o.Fit() end
  function o:SetAllPoints(...) box:SetAllPoints(...); o.Fit() end
  function o:ClearAllPoints() box:ClearAllPoints() end
  function o:SetSize(...) box:SetSize(...); o.Fit() end
  function o:SetWidth(...) box:SetWidth(...); o.Fit() end
  function o:SetHeight(...) box:SetHeight(...); o.Fit() end
  function o:GetWidth() return box:GetWidth() end
  function o:GetHeight() return box:GetHeight() end
  function o:GetParent() return parent end
  -- a gradient cannot follow nine parts: the start colour is used
  function o:SetGradient() end
  -- anything else (GetTop, GetPoint...) is asked of the box the nine parts sit on
  return setmetatable(o, { __index = function(_, k)
    local m = box[k]
    if type(m) == "function" then return function(_, ...) return m(box, ...) end end
    return m
  end })
end
-- a rounded box with an optional rounded edge on top of it
function ns.RoundBox(parent, r, g, b, a, edge, layer, sub)
  local fill = ns.Round(parent, layer or "BACKGROUND", sub or 1)
  fill:SetAllPoints(parent)
  fill:SetColorTexture(r or 0.086, g or 0.094, b or 0.122, a or 1)
  local line
  if edge then
    line = ns.Round(parent, "BORDER", 0, nil, true)
    line:SetAllPoints(parent)
    line:SetColorTexture(edge[1], edge[2], edge[3], edge[4] or 1)
  end
  return fill, line
end

-- a window in the ETA look: title, close (×), drag to move, remembered position
function ns.Window(name, width, title)
  local f = CreateFrame("Frame", name, UIParent)
  f:SetSize(width, 200)
  f:SetFrameStrata("HIGH")
  -- the window you click or open comes in front of the other CraftETA windows
  f:SetToplevel(true)
  -- a high base level, so another addon's window at the same strata never lands between our parts
  f:SetFrameLevel(40)
  f:HookScript("OnShow", function(self) self:Raise() end)
  f:HookScript("OnMouseDown", function(self) self:Raise() end)
  f:SetClampedToScreen(true)
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", function(self)
    if not self.docked then self:StartMoving() end
  end)
  f:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    if ns.db then
      local left, top = self:GetLeft(), self:GetTop()
      ns.db["point_" .. name] = { left, top }
    end
  end)
  -- a solid fill under the (slightly see-through) skin, so nothing behind shows through the text
  -- rounded like the skin, so no square corner shows behind its round ones
  local solid = ns.Round(f, "BACKGROUND", -8, 8)
  solid:SetPoint("TOPLEFT", 1, -1)
  solid:SetPoint("BOTTOMRIGHT", -1, 1)
  solid:SetColorTexture(0.043, 0.047, 0.063, 1)
  ns.Skin(f)
  f.title = ns.Font(f, true, 15)
  f.title:SetPoint("LEFT", f, "TOPLEFT", 14, -20)
  f.title:SetText(title or "|cffffffffCraft|r|cffffd24aETA|r")
  -- the ETA gold stroke under the title
  local stroke = f:CreateTexture(nil, "ARTWORK")
  stroke:SetSize(22, 2)
  stroke:SetPoint("TOPLEFT", f.title, "BOTTOMLEFT", 0, -5)
  stroke:SetColorTexture(1, 0.8, 0.35, 0.9)
  f.stroke = stroke
  local close = CreateFrame("Button", nil, f)
  close:SetSize(20, 20)
  close:SetPoint("TOPRIGHT", -8, -8)
  local x = ns.Font(close, true, 16, 0.55, 0.58, 0.64)
  x:SetPoint("CENTER")
  x:SetText("×")
  close:SetScript("OnEnter", function() x:SetTextColor(1, 0.82, 0.3) end)
  close:SetScript("OnLeave", function() x:SetTextColor(0.55, 0.58, 0.64) end)
  close:SetScript("OnClick", function() f:Hide() end)
  f.close = close
  f:Hide()
  tinsert(UISpecialFrames, name)
  return f
end

function ns.PlaceSaved(f, name, ...)
  local p = ns.db and ns.db["point_" .. name]
  f:ClearAllPoints()
  if type(p) == "table" and p[1] then
    f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", p[1], p[2])
  else
    f:SetPoint(...)
  end
end

-- a flat button: dark, a thin edge that turns gold under the mouse
function ns.Button(parent, text, width, height)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(width or 80, height or 22)
  local bg, line = ns.RoundBox(b, 0.12, 0.13, 0.16, 0.95, { 0.25, 0.27, 0.32, 1 }, "BACKGROUND", 0)
  local edges = { line }
  b.bg = bg
  local label = ns.Font(b, true, 11, 0.91, 0.92, 0.94)
  label:SetPoint("CENTER")
  label:SetJustifyH("CENTER")
  b.label = label
  b:SetFontString(label)
  b:SetText(text or "")
  local function color(r, g, bl)
    for _, t in ipairs(edges) do t:SetColorTexture(r, g, bl, 1) end
  end
  -- while the mouse is over the button its text is gold; a colour set meanwhile (a tab that was clicked)
  -- is kept and shown when the mouse leaves, so hovering never loses a tab's state
  local rawColor = label.SetTextColor
  function label:SetTextColor(r, g, bl, a)
    if b.hovering then b.keepR, b.keepG, b.keepB = r, g, bl; return end
    rawColor(self, r, g, bl, a)
  end
  b:SetScript("OnEnter", function(self)
    if self:IsEnabled() then
      b.keepR, b.keepG, b.keepB = label:GetTextColor()
      if b.primaryFill then
        -- a gold button: gold text would vanish on it, so the button lightens and the text stays dark
        b.primaryFill(true)
      else
        rawColor(label, 1, 0.82, 0.3); b.hovering = true
        bg:SetColorTexture(0.16, 0.17, 0.21, 0.95)
      end
    end
    if self.tip then
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetText(self.tip, 1, 1, 1, 1, true)
      GameTooltip:Show()
    end
  end)
  b:SetScript("OnLeave", function()
    if b.primaryFill then b.primaryFill(false) else bg:SetColorTexture(0.12, 0.13, 0.16, 0.95) end
    if b.hovering then b.hovering = false; if b.keepR then rawColor(label, b.keepR, b.keepG, b.keepB) end end
    GameTooltip:Hide()
  end)
  hooksecurefunc(b, "Disable", function() b.hovering = false; label:SetTextColor(0.42, 0.43, 0.47) end)
  hooksecurefunc(b, "Enable", function() label:SetTextColor(0.91, 0.92, 0.94) end)
  -- text too long for the button (Leatherworking): a smaller font until it fits (not below 8).
  -- b.grow = true: the button grows instead (the main window's page buttons)
  local function Fit()
    if b.grow then return end
    local font, size, flags = label:GetFont()
    if not font then return end
    if size ~= b.fitSize then b.baseSize = size end          -- the caller set a font: that is the size to aim for
    local want = b.baseSize or size
    local room = b:GetWidth() - 10
    local s = want
    label:SetFont(font, s, flags)
    while s > 10 and label:GetStringWidth() > room do
      s = s - 1
      label:SetFont(font, s, flags)
    end
    b.fitSize = s
  end
  hooksecurefunc(b, "SetText", Fit)
  hooksecurefunc(b, "SetWidth", Fit)
  hooksecurefunc(b, "SetSize", Fit)
  Fit()
  return b
end

-- the main button of a view: gold fill, dark bold text (the CraftETA panel's Craft button)
function ns.Primary(b, size)
  b.label:SetFont(ns.F_BOLD, math.max(size or 12, 11), "")
  local function Look(on)
    b.label:SetTextColor(on and 1 or 0.42, on and 0.82 or 0.43, on and 0.3 or 0.47)
  end
  hooksecurefunc(b, "Enable", function() Look(true) end)
  hooksecurefunc(b, "Disable", function() Look(false) end)
  Look(b:IsEnabled())
  return b
end

-- a small square button with a real game icon
function ns.IconButton(parent, icon, size, tip)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(size or 18, size or 18)
  local t = b:CreateTexture(nil, "ARTWORK")
  t:SetAllPoints()
  t:SetTexture(icon)
  t:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  local hl = b:CreateTexture(nil, "HIGHLIGHT")
  hl:SetAllPoints()
  hl:SetColorTexture(1, 0.82, 0.3, 0.25)
  b.icon = t
  b:SetScript("OnEnter", function(self)
    if tip then
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetText(type(tip) == "function" and tip() or tip, 1, 1, 1, 1, true)
      GameTooltip:Show()
    end
  end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  return b
end

-- one line of a list: icon, name on the left, a value on the right
function ns.Row(parent, height)
  local r = CreateFrame("Button", nil, parent)
  r:SetHeight(height or 18)
  r.icon = r:CreateTexture(nil, "ARTWORK")
  r.icon:SetSize((height or 18) - 2, (height or 18) - 2)
  r.icon:SetPoint("LEFT", 0, 0)
  r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  r.name = ns.Font(r, false, 11)
  r.name:SetPoint("LEFT", r.icon, "RIGHT", 6, 0)
  r.name:SetWordWrap(false)
  r.value = ns.Font(r, true, 11)
  r.value:SetPoint("RIGHT", 0, 0)
  r.value:SetJustifyH("RIGHT")
  r.name:SetPoint("RIGHT", r.value, "LEFT", -6, 0)
  local hl = ns.Round(r, "HIGHLIGHT", 0)
  hl:SetAllPoints()
  hl:SetColorTexture(1, 1, 1, 0.04)
  return r
end

-- a thin bar with ticks
function ns.Bar(parent, width)
  local bar = CreateFrame("Frame", nil, parent)
  bar:SetSize(width, 6)
  local bg = bar:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetColorTexture(0.16, 0.17, 0.21, 1)
  bar.fill = bar:CreateTexture(nil, "ARTWORK")
  bar.fill:SetPoint("TOPLEFT"); bar.fill:SetPoint("BOTTOMLEFT")
  bar.fill:SetColorTexture(1, 0.82, 0.3, 1)
  bar.ticks = {}
  for i, at in ipairs({ 75, 150, 225 }) do
    local t = bar:CreateTexture(nil, "OVERLAY")
    t:SetSize(1, 8)
    t:SetPoint("CENTER", bar, "LEFT", width * at / 300, 0)
    t:SetColorTexture(0.05, 0.05, 0.06, 1)
    bar.ticks[i] = t
  end
  function bar:SetValue(v)
    self.fill:SetWidth(math.max(1, width * math.min(1, v / 300)))
  end
  return bar
end

-- a box you type a number in: Enter (or clicking away) sets it, Escape puts the old one back
-- onSet(n) gets the number; box:SetNumberValue(n) shows one without calling onSet
function ns.NumberBox(parent, width, height, size, onSet)
  local box = CreateFrame("EditBox", nil, parent)
  box:SetSize(width, height)
  box:SetAutoFocus(false)
  box:SetNumeric(true)
  box:SetMaxLetters(6)
  box:SetFont(ns.F_BOLD, size or 12, "")
  box:SetTextColor(1, 0.82, 0.29)
  box:SetJustifyH("CENTER")
  box:SetTextInsets(4, 4, 0, 0)
  ns.RoundBox(box, 0.08, 0.09, 0.11, 0.95, { 0.25, 0.27, 0.32, 1 }, "BACKGROUND", 0)
  local function Apply(self)
    local n = tonumber(self:GetText())
    if n and n ~= self.value then onSet(n) else self:SetText(self.value or "") end
  end
  box:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
  box:SetScript("OnEscapePressed", function(self) self:SetText(self.value or ""); self:ClearFocus() end)
  box:SetScript("OnEditFocusLost", Apply)
  box:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
  function box:SetNumberValue(n)
    self.value = n
    if not self:HasFocus() then self:SetText(n or "") end
  end
  return box
end

-- an on/off switch: a track with a knob that slides to the right when on (gold) and left when off (grey)
function ns.Switch(parent, onClick)
  local b = CreateFrame("Button", nil, parent)
  -- the same round switch as LevelETA (ToggleOn / ToggleOff)
  b:SetSize(32, 18)
  b.off = b:CreateTexture(nil, "ARTWORK"); b.off:SetAllPoints()
  b.off:SetTexture(ns.TEX .. "ToggleOff"); b.off:SetTexCoord(0, 1, 0, 36 / 64)
  b.onTex = b:CreateTexture(nil, "ARTWORK"); b.onTex:SetAllPoints()
  b.onTex:SetTexture(ns.TEX .. "ToggleOn"); b.onTex:SetTexCoord(0, 1, 0, 36 / 64)
  function b:SetOn(on)
    self.on = on and true or false
    self.onTex:SetShown(self.on)
    self.off:SetShown(not self.on)
  end
  b:SetScript("OnClick", function(self) if onClick then onClick(self) end end)
  b:SetOn(false)
  return b
end

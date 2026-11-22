-- CraftETA: the ETA family look (dark panel, Inter, gold accent) for every window.
local _, ns = ...

function ns.Font(parent, bold, size, r, g, b)
  local t = parent:CreateFontString(nil, "OVERLAY")
  t:SetFont(bold and ns.F_BOLD or ns.F_SEMI, size or 11, "")
  t:SetShadowOffset(1, -1)
  t:SetShadowColor(0, 0, 0, 0.6)
  t:SetTextColor(r or 0.85, g or 0.87, b or 0.9)
  t:SetJustifyH("LEFT")
  return t
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

-- a window in the ETA look: title, close (×), drag to move, remembered position
function ns.Window(name, width, title)
  local f = CreateFrame("Frame", name, UIParent)
  f:SetSize(width, 200)
  f:SetFrameStrata("HIGH")
  -- the window you click or open comes in front of the other CraftETA windows
  f:SetToplevel(true)
  f:HookScript("OnShow", function(self) self:Raise() end)
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
  local solid = f:CreateTexture(nil, "BACKGROUND", nil, -8)
  solid:SetPoint("TOPLEFT", 3, -3)
  solid:SetPoint("BOTTOMRIGHT", -3, 3)
  solid:SetColorTexture(0.043, 0.047, 0.063, 1)
  ns.Skin(f)
  f.title = ns.Font(f, true, 14)
  f.title:SetPoint("TOPLEFT", 14, -12)
  f.title:SetText(title or "|cffffffffCraft|r|cffffd24aETA|r")
  local close = CreateFrame("Button", nil, f)
  close:SetSize(20, 20)
  close:SetPoint("TOPRIGHT", -8, -8)
  local x = ns.Font(close, true, 14, 0.6, 0.62, 0.68)
  x:SetPoint("CENTER")
  x:SetText("×")
  close:SetScript("OnEnter", function() x:SetTextColor(1, 0.82, 0.3) end)
  close:SetScript("OnLeave", function() x:SetTextColor(0.6, 0.62, 0.68) end)
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
  local bg = b:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints()
  bg:SetColorTexture(0.12, 0.13, 0.16, 0.95)
  local edges = {}
  local function edge(p1, p2, horizontal)
    local t = b:CreateTexture(nil, "BORDER")
    t:SetPoint(p1); t:SetPoint(p2)
    if horizontal then t:SetHeight(1) else t:SetWidth(1) end
    t:SetColorTexture(0.25, 0.27, 0.32, 1)
    edges[#edges + 1] = t
  end
  edge("TOPLEFT", "TOPRIGHT", true); edge("BOTTOMLEFT", "BOTTOMRIGHT", true)
  edge("TOPLEFT", "BOTTOMLEFT"); edge("TOPRIGHT", "BOTTOMRIGHT")
  local label = ns.Font(b, true, 11, 1, 0.82, 0.3)
  label:SetPoint("CENTER")
  label:SetJustifyH("CENTER")
  b.label = label
  b:SetFontString(label)
  b:SetText(text or "")
  local function color(r, g, bl)
    for _, t in ipairs(edges) do t:SetColorTexture(r, g, bl, 1) end
  end
  b:SetScript("OnEnter", function(self)
    if self:IsEnabled() then color(1, 0.82, 0.3) end
    if self.tip then
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetText(self.tip, 1, 1, 1, 1, true)
      GameTooltip:Show()
    end
  end)
  b:SetScript("OnLeave", function()
    color(0.25, 0.27, 0.32)
    GameTooltip:Hide()
  end)
  hooksecurefunc(b, "Disable", function() label:SetTextColor(0.42, 0.43, 0.47) end)
  hooksecurefunc(b, "Enable", function() label:SetTextColor(1, 0.82, 0.3) end)
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
  local hl = r:CreateTexture(nil, "HIGHLIGHT")
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

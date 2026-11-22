-- CraftETA: minimap button and the addon compartment entry.
-- Click: the main window. Right-click: the shopping list. Shift-click: settings. Drag: move it.
local _, ns = ...
local T = ns.T
local ICON = "Interface\\Icons\\Trade_BlackSmithing"

local button

local function Place()
  local angle = math.rad(ns.db.minimapAngle or 220)
  local radius = Minimap:GetWidth() / 2 + 10
  button:ClearAllPoints()
  button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

local function Drag()
  local mx, my = Minimap:GetCenter()
  local cx, cy = GetCursorPosition()
  local scale = Minimap:GetEffectiveScale()
  ns.db.minimapAngle = math.deg(math.atan2(cy / scale - my, cx / scale - mx)) % 360
  Place()
end

local function Click(which)
  if not ns.db then return end
  if IsShiftKeyDown() then ns.ToggleSettings()
  elseif which == "RightButton" then ns.ToggleList()
  else ns.ToggleHub() end
end

local function Tip(owner)
  GameTooltip:SetOwner(owner, "ANCHOR_LEFT")
  GameTooltip:AddLine("Craft|cffffd24aETA|r")
  GameTooltip:AddLine(T("mmLeft"), 1, 1, 1)
  GameTooltip:AddLine(T("mmRight"), 1, 1, 1)
  GameTooltip:AddLine(T("mmShift"), 1, 1, 1)
  GameTooltip:AddLine(T("mmDrag"), 0.6, 0.6, 0.6)
  GameTooltip:Show()
end

local function Create()
  if button or not Minimap then return button end
  local b = CreateFrame("Button", "CraftETAMinimapButton", Minimap)
  button = b
  b:SetSize(31, 31)
  b:SetFrameStrata("MEDIUM")
  b:SetFrameLevel(8)
  b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  b:RegisterForDrag("LeftButton")
  b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
  local bg = b:CreateTexture(nil, "BACKGROUND")
  bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
  bg:SetSize(20, 20); bg:SetPoint("TOPLEFT", 7, -5)
  local icon = b:CreateTexture(nil, "ARTWORK")
  icon:SetTexture(ICON)
  icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
  icon:SetSize(17, 17); icon:SetPoint("TOPLEFT", 7, -6)
  local border = b:CreateTexture(nil, "OVERLAY")
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  border:SetSize(53, 53); border:SetPoint("TOPLEFT")
  b:SetScript("OnClick", function(_, which) Click(which) end)
  b:SetScript("OnDragStart", function(self) self:SetScript("OnUpdate", Drag) end)
  b:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
  b:SetScript("OnEnter", Tip)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  Place()
  return b
end

function ns.UpdateMinimapButton()
  local b = Create()
  if b then b:SetShown(ns.db.minimap ~= false) end
end

ns.Register("PLAYER_LOGIN")
ns.On("PLAYER_LOGIN", function() ns.UpdateMinimapButton() end)

function CraftETA_OnCompartmentClick(_, which)
  Click(which)
end

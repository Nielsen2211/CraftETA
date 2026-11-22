-- CraftETA: settings (everything can be turned off) and the slash command.
local _, ns = ...
local T = ns.T

local W = ns.Window("CraftETASettings", 330)
-- on top of every other CraftETA window, and fully solid so nothing behind it shows through
W:SetFrameStrata("DIALOG")
W:SetToplevel(true)
local solid = W:CreateTexture(nil, "BACKGROUND", nil, -8)
solid:SetPoint("TOPLEFT", 4, -4)
solid:SetPoint("BOTTOMRIGHT", -4, 4)
solid:SetColorTexture(0.043, 0.047, 0.063, 1)
-- a shade over the main window while settings are open, click it to close settings
local shade = CreateFrame("Button", nil, UIParent)
shade:SetFrameStrata("DIALOG")
shade:Hide()
local shadeTex = shade:CreateTexture(nil, "BACKGROUND")
shadeTex:SetAllPoints()
shadeTex:SetColorTexture(0, 0, 0, 0.55)
shade:SetScript("OnClick", function() W:Hide() end)
W:HookScript("OnHide", function() shade:Hide() end)
local rowPool, heads = {}, {}
local info

local function Head(i)
  local h = heads[i]
  if not h then h = ns.Font(W, true, 10, 0.55, 0.58, 0.64); heads[i] = h end
  return h
end

local function Toggle(i)
  local r = rowPool[i]
  if r then return r end
  r = CreateFrame("Button", nil, W)
  r:SetHeight(22)
  local box = r:CreateTexture(nil, "ARTWORK"); box:SetSize(14, 14); box:SetPoint("LEFT", 0, 0)
  local fill = r:CreateTexture(nil, "OVERLAY"); fill:SetSize(8, 8); fill:SetPoint("CENTER", box, "CENTER"); fill:SetColorTexture(1, 0.82, 0.3)
  local tx = ns.Font(r, false, 11); tx:SetPoint("LEFT", box, "RIGHT", 8, 0); tx:SetPoint("RIGHT", r, "RIGHT", 0, 0)
  local hl = r:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints(); hl:SetColorTexture(1, 1, 1, 0.04)
  r.box, r.fill, r.tx = box, fill, tx
  r:SetScript("OnClick", function(self) self.set(); W.Build(); ns.Refresh(); if ns.RefreshHub then ns.RefreshHub() end end)
  rowPool[i] = r
  return r
end

function W.Build()
  if not ns.db then return end
  local y, n, h = -40, 0, 0
  local function section(text)
    h = h + 1
    local hd = Head(h); hd:ClearAllPoints(); hd:SetPoint("TOPLEFT", 14, y); hd:SetText(string.upper(text)); hd:Show()
    y = y - 18
  end
  local function add(text, on, set)
    n = n + 1
    local r = Toggle(n)
    r:ClearAllPoints(); r:SetPoint("TOPLEFT", 14, y); r:SetPoint("RIGHT", W, "RIGHT", -14, 0)
    r.set = set
    r.fill:SetShown(on)
    r.box:SetColorTexture(on and 0.3 or 0.16, on and 0.25 or 0.17, on and 0.12 or 0.21)
    r.tx:SetText(text)
    r:Show()
    y = y - 22
  end
  local db = ns.db
  section(T("settings"))
  add(T("panelOpt"), db.panel, function() db.panel = not db.panel end)
  add(T("nextOpt"), db.showNext, function() db.showNext = not db.showNext end)
  add(T("sideOpt", T("side_" .. (db.panelSide or "auto"))), true, function()
    db.panelSide = ({ auto = "left", left = "right", right = "auto" })[db.panelSide or "auto"]
    ns.PlacePanel()
  end)
  add(T("minimapOpt"), db.minimap, function() db.minimap = not db.minimap; ns.UpdateMinimapButton() end)
  add(T("tooltipOpt"), db.tooltip, function() db.tooltip = not db.tooltip end)
  add(T("cdAlertOpt"), db.cdAlert, function() db.cdAlert = not db.cdAlert end)
  add(T("trackReminderOpt"), db.trackReminder, function() db.trackReminder = not db.trackReminder; ns.trackDismissed = nil; ns.UpdateTrackBanner() end)
  add(T("guildAskOpt"), db.guildAsk, function() db.guildAsk = not db.guildAsk end)
  add(T("guildShareOpt"), db.guildShare, function() db.guildShare = not db.guildShare end)
  add(T("chatAds"), db.chatAds ~= false, function() db.chatAds = not (db.chatAds ~= false) end)
  add(T("ahOpt"), db.ah, function() db.ah = not db.ah end)
  add(T("autoScanOpt"), db.autoScan, function() db.autoScan = not db.autoScan end)
  add(T("autoOpt"), db.autoBuy, function() db.autoBuy = not db.autoBuy end)
  -- the price guard: click to go 10, 20, 30, 50 %
  add(T("guardOpt") .. "  |cffffd24a" .. db.guard .. "%|r", true, function()
    local steps = { 10, 20, 30, 50 }
    local nextValue = steps[1]
    for i, v in ipairs(steps) do if v == db.guard then nextValue = steps[i % #steps + 1] end end
    db.guard = nextValue
  end)
  -- which auction house addon CraftETA found and uses
  info = info or ns.Font(W, false, 10, 0.6, 0.62, 0.68)
  info:ClearAllPoints(); info:SetPoint("TOPLEFT", 14, y - 4)
  info:SetText(T("ahAddon", ns.AHAddon() or T("noAhAddon")))
  y = y - 20
  y = y - 6
  section(T("lang"))
  add("English", db.lang == "en", function() db.lang = "en" end)
  add("Dansk", db.lang == "da", function() db.lang = "da" end)
  for i = n + 1, #rowPool do rowPool[i]:Hide() end
  for i = h + 1, #heads do heads[i]:Hide() end
  W:SetHeight(-y + 24)
end
W:SetScript("OnShow", function()
  W:ClearAllPoints()
  local hub = _G.CraftETAHub
  if hub and hub:IsShown() then
    W:SetPoint("CENTER", hub, "CENTER")
    shade:ClearAllPoints()
    shade:SetAllPoints(hub)
    shade:SetFrameLevel(10)
    shade:Show()
    W:SetFrameLevel(20)
  else
    W:SetPoint("CENTER")
  end
  W:Raise()
  W.Build()
end)

function ns.ToggleSettings()
  if W:IsShown() then W:Hide() else W:Show() end
end

SLASH_CRAFTETA1 = "/ceta"
SLASH_CRAFTETA2 = "/crafteta"
SlashCmdList.CRAFTETA = function(msg)
  msg = string.lower(string.match(msg or "", "^%s*(.-)%s*$") or "")
  if not ns.db then return end
  if msg == "" or msg == "hub" then ns.ToggleHub()
  elseif msg == "panel" or msg == "show" then ns.TogglePanel()
  elseif msg == "list" then ns.ToggleList()
  elseif msg == "track" then ns.ToggleTracker()
  elseif msg == "farm" then ns.ToggleFarmWindow()
  elseif msg == "config" or msg == "settings" then ns.ToggleSettings()
  elseif msg == "reset" then
    ns.db.point_CraftETAPanel, ns.db.point_CraftETAList = nil, nil
    ns.PlacePanel(); ns.PlaceList()
  elseif msg == "da" or msg == "en" then ns.db.lang = msg; ns.Refresh(); if ns.RefreshHub then ns.RefreshHub() end
  else ns.Print(T("help")) end
end

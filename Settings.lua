-- CraftETA: settings (everything can be turned off) and the slash command.
local _, ns = ...
local T = ns.T

local W = ns.Window("CraftETASettings", 380)
-- on top of every other CraftETA window, and fully solid so nothing behind it shows through
W:SetFrameStrata("DIALOG")
W:SetToplevel(true)
local solid = ns.Round(W, "BACKGROUND", -8, 8)
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
  local function Click(self) self.set(); W.Build(); ns.Refresh(); if ns.RefreshHub then ns.RefreshHub() end end
  -- on/off: a switch on the right. A setting you click through (side, price guard): its value on the right.
  -- A choice (language): a dot
  local sw = ns.Switch(r, function() Click(r) end); sw:SetPoint("RIGHT", 0, 0)
  local val = ns.Font(r, true, 10, 1, 0.82, 0.3); val:SetPoint("RIGHT", 0, 0); val:SetJustifyH("RIGHT")
  local dot = r:CreateTexture(nil, "ARTWORK"); dot:SetTexture(ns.TEX .. "Dot"); dot:SetSize(8, 8); dot:SetPoint("RIGHT", -11, 0)
  local tx = ns.Font(r, false, 11); tx:SetPoint("LEFT", 0, 0); tx:SetPoint("RIGHT", r, "RIGHT", -44, 0)
  local hl = ns.Round(r, "HIGHLIGHT", 0); hl:SetAllPoints(); hl:SetColorTexture(1, 1, 1, 0.04)
  r.sw, r.val, r.dot, r.tx = sw, val, dot, tx
  r:SetScript("OnClick", Click)
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
  -- kind: nil (on/off), "cycle" (value: what it is set to), "choice" (one of a few)
  local function add(text, on, set, kind, value)
    n = n + 1
    local r = Toggle(n)
    r:ClearAllPoints(); r:SetPoint("TOPLEFT", 14, y); r:SetPoint("RIGHT", W, "RIGHT", -14, 0)
    r.set = set
    r.sw:SetShown(kind == nil); r.sw:SetOn(on)
    r.val:SetShown(kind == "cycle"); r.val:SetText(value or "")
    r.dot:SetShown(kind == "choice")
    r.dot:SetVertexColor(on and 1 or 0.25, on and 0.82 or 0.26, on and 0.3 or 0.3, 1)
    r.tx:SetPoint("RIGHT", r, "RIGHT", kind == "cycle" and -(r.val:GetStringWidth() + 12) or -44, 0)
    r.tx:SetText(text)
    -- a long text wraps onto two lines: the row grows with it instead of squeezing the lines together
    local rh = math.max(22, math.ceil(r.tx:GetStringHeight()) + 8)
    r:SetHeight(rh)
    r:Show()
    y = y - rh
  end
  local db = ns.db
  section(T("settings"))
  add(T("panelOpt"), db.panel, function() db.panel = not db.panel end)
  add(T("nextOpt"), db.showNext, function() db.showNext = not db.showNext end)
  add((T("sideOpt", ""):gsub("[:%s]+$", "")), true, function()
    db.panelSide = ({ auto = "left", left = "right", right = "auto" })[db.panelSide or "auto"]
    ns.PlacePanel()
  end, "cycle", T("side_" .. (db.panelSide or "auto")))
  add(T("minimapOpt"), db.minimap, function() db.minimap = not db.minimap; ns.UpdateMinimapButton() end)
  add(T("tooltipOpt"), db.tooltip, function() db.tooltip = not db.tooltip end)
  add(T("cdAlertOpt"), db.cdAlert, function() db.cdAlert = not db.cdAlert end)
  add(T("trainerOpt"), db.trainerButton ~= false, function() db.trainerButton = not (db.trainerButton ~= false) end)
  add(T("rankRemindOpt"), db.rankRemind ~= false, function() db.rankRemind = not (db.rankRemind ~= false) end)
  add(T("scanRemindOpt"), db.scanRemind ~= false, function() db.scanRemind = not (db.scanRemind ~= false) end)
  add(T("listRemindOpt"), db.listRemind ~= false, function() db.listRemind = not (db.listRemind ~= false) end)
  add(T("trackReminderOpt"), db.trackReminder, function() db.trackReminder = not db.trackReminder; ns.trackDismissed = nil; ns.UpdateTrackBanner() end)
  add(T("guildAskOpt"), db.guildAsk, function() db.guildAsk = not db.guildAsk end)
  add(T("guildShareOpt"), db.guildShare, function() db.guildShare = not db.guildShare end)
  add(T("chatAds"), db.chatAds ~= false, function() db.chatAds = not (db.chatAds ~= false) end)
  add(T("shareListOpt"), db.shareList, function() db.shareList = not db.shareList end)
  add(T("vendOpt"), db.vendorMode ~= "ah", function() db.vendorMode = (db.vendorMode ~= "ah") and "ah" or "vendor"; if ns.UpdateVendorButton then ns.UpdateVendorButton() end end)
  add((db.lang == "da") and "Skill-up chance på hver opskrift i profession vinduet" or "Skill-up chance on every recipe in the profession window",
    db.skillChance ~= false, function() db.skillChance = not (db.skillChance ~= false); if ns.RefreshSkillChance then ns.RefreshSkillChance() end end)
  add(T("rcCardOpt"), db.recipeCard ~= false, function() db.recipeCard = not (db.recipeCard ~= false); if ns.UpdateRecipeCard then ns.UpdateRecipeCard() end end)
  add(T("ahOpt"), db.ah, function() db.ah = not db.ah end)
  add(T("autoScanOpt"), db.autoScan, function() db.autoScan = not db.autoScan end)
  add(T("autoOpt"), db.autoBuy, function() db.autoBuy = not db.autoBuy end)
  -- the price guard: click to go 10, 20, 30, 50 %
  add(T("guardOpt"), true, function()
    local steps = { 10, 20, 30, 50 }
    local nextValue = steps[1]
    for i, v in ipairs(steps) do if v == db.guard then nextValue = steps[i % #steps + 1] end end
    db.guard = nextValue
  end, "cycle", db.guard .. "%")
  -- which auction house addon CraftETA found and uses
  info = info or ns.Font(W, false, 10, 0.6, 0.62, 0.68)
  info:ClearAllPoints(); info:SetPoint("TOPLEFT", 14, y - 4)
  info:SetText(T("ahAddon", ns.AHAddon() or T("noAhAddon")))
  y = y - 20
  y = y - 6
  section(T("lang"))
  add("English", db.lang == "en", function() db.lang = "en" end, "choice")
  add("Dansk", db.lang == "da", function() db.lang = "da" end, "choice")
  for i = n + 1, #rowPool do rowPool[i]:Hide() end
  for i = h + 1, #heads do heads[i]:Hide() end
  W:SetHeight(-y + 24)
end
function ns.RefreshSettings() if W:IsShown() then W.Build() end end
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
  elseif msg == "debug" then
    -- why the Craft button is (not) working
    local st = ns.panelState or {}
    local r = st.recipe and ns.Recipe(st.recipe)
    ns.Print(("CraftETA debug: window=%s recipe=%s found=%s learned=%s id=%s left=%s canMake=%s job=%s why=%s"):format(
      tostring(ns.ProfessionFrame() ~= nil), tostring(st.recipe), tostring(r ~= nil), tostring(r and r.learned),
      tostring(r and r.id), tostring(st.left), tostring(st.canMake),
      st.job and (st.job.name .. " x" .. st.job.count) or "none", tostring(st.why)))
    if r and r.matList then
      for _, m in ipairs(r.matList) do ns.Print(("  item %d: need %d, in bags %d"):format(m[1], m[2], ns.BagCount(m[1]))) end
    end
  elseif msg == "da" or msg == "en" then ns.db.lang = msg; ns.Refresh(); if ns.RefreshHub then ns.RefreshHub() end
  else ns.Print(T("help")) end
end

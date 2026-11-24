-- CraftETA: things your guide needs later. Their tooltip says to keep them, and when you open the bank
-- a small window lists what in your bags the later steps use, with a button that banks it, so nobody
-- sells or deletes them by mistake.
local _, ns = ...
local Plain = ns.Plain

local function L(en, da) return (ns.db and ns.db.lang == "da") and da or en end

-- item name -> { prof, at, recipe, need }: the first later step of your professions that uses it, and how
-- many all later steps use. Items the step you are on uses are marked now = true (keep them in your bags).
local cache, cacheAt = nil, 0
function ns.LaterUse()
  if cache and GetTime() - cacheAt < 5 then return cache end
  local out = {}
  local skills = ns.Skills and ns.Skills() or {}
  for id, s in pairs(skills) do
    local guide = ns.GUIDES[id]
    local cur = guide and s.rank < 300 and ns.StepIndex(guide, s.rank)
    if cur then
      for i = cur, #guide.steps do
        local step = guide.steps[i]
        for _, e in ipairs((ns.Chosen(id, i, step))) do
          local mats = e[3]
          for m = 1, #mats, 2 do
            local name = mats[m]
            local u = out[name]
            if i == cur then
              if u then u.now = true else out[name] = { now = true, need = 0 } end
            else
              if not u or not u.prof then
                u = u or { need = 0 }
                u.prof, u.at, u.recipe = guide.name, step[1], e[1]
                out[name] = u
              end
              u.need = u.need + mats[m + 1]
            end
          end
        end
      end
    end
  end
  cache, cacheAt = out, GetTime()
  return out
end

-- the tooltip: "Keep it: Engineering uses 30 from 160 (Explosive Sheep)"
local byID
local function UseOfID(id)
  local later = ns.LaterUse()
  if not byID or byID.src ~= later then
    byID = { src = later }
    for name, u in pairs(later) do
      local itemID = ns.ItemID(name)
      if itemID then byID[itemID] = u end
    end
  end
  return byID[id]
end

local function AddKeep(tooltip, data)
  if not ns.db or ns.db.tooltip == false or ns.db.keepHint == false then return end
  local id = data and Plain(data.id)
  if type(id) ~= "number" then return end
  local u = UseOfID(id)
  if not u or not u.prof then return end
  tooltip:AddLine(L("CraftETA: keep it. %s uses %d from %d (%s)", "CraftETA: gem den. %s bruger %d fra %d (%s)")
    :format(u.prof, u.need, u.at, u.recipe), 1, 0.82, 0.3, true)
end

ns.Register("PLAYER_LOGIN")
ns.On("PLAYER_LOGIN", function()
  if TooltipDataProcessor and Enum and Enum.TooltipDataType then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tooltip, data)
      if tooltip == GameTooltip or tooltip == ItemRefTooltip then pcall(AddKeep, tooltip, data) end
    end)
  end
end)

-- at the bank: a small window with what in your bags only later steps use (not the step you are on),
-- each ticked, and a "Bank it" button that puts the ticked ones in the bank
local win, rows, skip = nil, {}, {}
local ROW_H, MAX_ROWS = 24, 10

local function BankList()
  local list = {}
  for name, u in pairs(ns.LaterUse()) do
    if u.prof and not u.now then
      local id = ns.ItemID(name)
      local n = id and ns.BagCount and ns.BagCount(id) or 0
      if n > 0 then list[#list + 1] = { name = name, id = id, n = n, u = u } end
    end
  end
  table.sort(list, function(a, b) if a.u.at ~= b.u.at then return a.u.at < b.u.at end return a.name < b.name end)
  return list
end

local function BankOpen()
  return (BankFrame and BankFrame:IsShown()) or (ns.bankOpen and true) or false
end

-- moves every stack of the item from your bags into the bank (the game's own right-click)
local function Deposit(id)
  local C = C_Container
  if not (C and C.GetContainerNumSlots and C.GetContainerItemInfo and C.UseContainerItem) then return 0 end
  local moved = 0
  for bag = 0, 5 do
    local okN, slots = pcall(C.GetContainerNumSlots, bag)
    for slot = 1, (okN and tonumber(Plain(slots)) or 0) do
      local ok, info = pcall(C.GetContainerItemInfo, bag, slot)
      if ok and type(info) == "table" and Plain(info.itemID) == id and not Plain(info.isLocked) then
        if pcall(C.UseContainerItem, bag, slot) then moved = moved + (tonumber(Plain(info.stackCount)) or 1) end
      end
    end
  end
  return moved
end

local Refresh
local function Build()
  win = ns.Window("CraftETABank", 340, "Craft|cffffd24aETA|r  |cff9ca3af" .. L("Bank for later", "Gem til senere") .. "|r")
  win:SetFrameStrata("HIGH")
  win.sub = ns.Font(win, false, 10, 0.55, 0.58, 0.64)
  win.sub:SetPoint("TOPLEFT", 14, -40)
  win.sub:SetPoint("RIGHT", win, "RIGHT", -14, 0)
  win.sub:SetJustifyH("LEFT")
  win.sub:SetWordWrap(true)
  for i = 1, MAX_ROWS do
    local r = CreateFrame("Button", nil, win)
    r:SetHeight(ROW_H)
    r:SetPoint("TOPLEFT", 10, -66 - (i - 1) * ROW_H)
    r:SetPoint("RIGHT", win, "RIGHT", -10, 0)
    local hl = r:CreateTexture(nil, "HIGHLIGHT"); hl:SetAllPoints(); hl:SetColorTexture(1, 1, 1, 0.04)
    r.box = r:CreateTexture(nil, "ARTWORK"); r.box:SetSize(14, 14); r.box:SetPoint("LEFT", 4, 0)
    r.box:SetColorTexture(0.16, 0.17, 0.21, 1)
    r.check = r:CreateTexture(nil, "OVERLAY"); r.check:SetSize(18, 18); r.check:SetPoint("CENTER", r.box, "CENTER", 1, 0)
    r.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    r.icon = r:CreateTexture(nil, "ARTWORK"); r.icon:SetSize(18, 18); r.icon:SetPoint("LEFT", r.box, "RIGHT", 8, 0)
    r.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    r.where = ns.Font(r, false, 10, 0.55, 0.58, 0.64); r.where:SetPoint("RIGHT", -4, 0); r.where:SetJustifyH("RIGHT")
    r.name = ns.Font(r, true, 11, 0.91, 0.92, 0.94); r.name:SetPoint("LEFT", r.icon, "RIGHT", 8, 0)
    r.name:SetPoint("RIGHT", r.where, "LEFT", -8, 0); r.name:SetJustifyH("LEFT"); r.name:SetWordWrap(false)
    r:SetScript("OnClick", function(self)
      if self.item then skip[self.item.id] = not skip[self.item.id]; Refresh() end
    end)
    r:SetScript("OnEnter", function(self)
      if not self.item then return end
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetText(self.item.name, 1, 1, 1)
      local u = self.item.u
      GameTooltip:AddLine(L("%s uses %d from skill %d (%s).", "%s bruger %d fra skill %d (%s)."):format(u.prof, u.need, u.at, u.recipe), 0.8, 0.82, 0.86, true)
      GameTooltip:AddLine(L("Click: tick or untick", "Klik: sæt eller fjern flueben"), 0.55, 0.58, 0.64)
      GameTooltip:Show()
    end)
    r:SetScript("OnLeave", function() GameTooltip:Hide() end)
    rows[i] = r
  end
  win.bank = ns.Primary(ns.Button(win, "", 150, 28), 12)
  win.later = ns.Button(win, L("Not now", "Ikke nu"), 90, 28)
  win.later:SetScript("OnClick", function() win:Hide() end)
  win.bank:SetScript("OnClick", function()
    local moved, kinds = 0, 0
    for _, item in ipairs(win.list or {}) do
      if not skip[item.id] then
        local n = Deposit(item.id)
        if n > 0 then moved, kinds = moved + n, kinds + 1 end
      end
    end
    if moved > 0 then ns.Print(L("Banked %d items for later in your guide.", "Lagde %d ting i banken til senere i guiden."):format(moved)) end
    C_Timer.After(0.6, function() if win:IsShown() then Refresh() end end)
  end)
end

function Refresh()
  if not win then return end
  local list = BankList()
  win.list = list
  if #list == 0 or not BankOpen() then win:Hide(); return end
  win.sub:SetText(L("Your guide uses these later. Put them in the bank so they are not sold or deleted by mistake.",
    "Din guide bruger disse senere. Læg dem i banken, så de ikke bliver solgt eller slettet ved en fejl."))
  local ticked = 0
  for i, r in ipairs(rows) do
    local item = list[i]
    r.item = item
    if item then
      r.icon:SetTexture(ns.ItemIcon(item.name, 134400))
      r.name:SetText(item.n .. "  " .. item.name)
      r.where:SetText(item.u.prof .. " " .. item.u.at)
      r.check:SetShown(not skip[item.id])
      r:SetAlpha(skip[item.id] and 0.5 or 1)
      if not skip[item.id] then ticked = ticked + 1 end
      r:Show()
    else
      r:Hide()
    end
  end
  local shown = math.min(#list, MAX_ROWS)
  for i = MAX_ROWS + 1, #list do if not skip[list[i].id] then ticked = ticked + 1 end end
  local y = -66 - shown * ROW_H - 12
  win.bank:ClearAllPoints(); win.bank:SetPoint("TOPLEFT", 14, y)
  win.later:ClearAllPoints(); win.later:SetPoint("LEFT", win.bank, "RIGHT", 8, 0)
  win.bank:SetText(L("Bank it (%d)", "Bank det (%d)"):format(ticked))
  if ticked > 0 then win.bank:Enable() else win.bank:Disable() end
  win:SetHeight(-y + 28 + 14)
  win:ClearAllPoints()
  if BankFrame and BankFrame:IsShown() then
    win:SetPoint("TOPLEFT", BankFrame, "TOPRIGHT", 8, 0)
  else
    win:SetPoint("TOP", UIParent, "TOP", 0, -140)
  end
  win:Show()
end

local function OnBank()
  if not ns.db or ns.db.keepHint == false then return end
  ns.bankOpen = true
  if not win then Build() end
  C_Timer.After(0.3, Refresh)
end
local function OnBankClosed()
  ns.bankOpen = false
  if win then win:Hide() end
end
ns.Register("BANKFRAME_OPENED")
ns.On("BANKFRAME_OPENED", OnBank)
ns.Register("BANKFRAME_CLOSED")
ns.On("BANKFRAME_CLOSED", OnBankClosed)
ns.Register("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
ns.On("PLAYER_INTERACTION_MANAGER_FRAME_SHOW", function(kind)
  local banker = Enum and Enum.PlayerInteractionType and Enum.PlayerInteractionType.Banker
  if banker and Plain(kind) == banker then OnBank() end
end)
ns.Register("PLAYER_INTERACTION_MANAGER_FRAME_HIDE")
ns.On("PLAYER_INTERACTION_MANAGER_FRAME_HIDE", function(kind)
  local banker = Enum and Enum.PlayerInteractionType and Enum.PlayerInteractionType.Banker
  if banker and Plain(kind) == banker then OnBankClosed() end
end)
ns.Register("BAG_UPDATE_DELAYED")
ns.On("BAG_UPDATE_DELAYED", function() if win and win:IsShown() then Refresh() end end)

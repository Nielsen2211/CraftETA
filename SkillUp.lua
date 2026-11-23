-- CraftETA: the skill-up chance of every recipe. Where a recipe turns yellow, green and grey, your chance of a
-- point on it now, and what a point costs in materials (or earns, when the craft sells for more).
-- Shown on each recipe in the profession window's list, in its tooltip and on the recipe card.
-- The guide still decides the route: this is extra information next to it.
local _, ns = ...
local Plain = ns.Plain
local function L(en, da) return (ns.db and ns.db.lang == "da") and da or en end

-- recipe (spell) ID -> { orange, yellow, green, grey }, filled from the game's data in SkillUpData.lua
ns.SKILLUP = ns.SKILLUP or {}

local COLORS = {
  [0] = { 1, 0.5, 0.25 },     -- orange
  [1] = { 1, 1, 0.25 },       -- yellow
  [2] = { 0.25, 0.75, 0.25 }, -- green
  [3] = { 0.5, 0.5, 0.5 },    -- grey
}
ns.SKILL_COLORS = COLORS
local HEX = { [0] = "ff8040", [1] = "ffff40", [2] = "40c040", [3] = "808080" }

---------------------------------------------------------------------------
-- What CraftETA sees itself: the colour of every recipe at every skill you have been on.
-- seen[recipeID] = { [colour] = { lowest skill, highest skill } }. Where one colour ends and the next starts
-- on the skill right after, that limit is exact. Green always starts halfway between yellow and grey,
-- so any two limits give the third.
---------------------------------------------------------------------------
local function Seen()
  if not ns.db then return nil end
  ns.db.skillSeen = ns.db.skillSeen or {}
  return ns.db.skillSeen
end

function ns.NoteColor(id, skill, color)
  local seen = Seen()
  if not seen or type(id) ~= "number" or type(skill) ~= "number" or type(color) ~= "number" or not COLORS[color] then return end
  local s = seen[id] or {}
  -- a colour seen above a later colour means the window was read before it caught up: start over
  for c = 0, 3 do
    local r = s[c]
    if r and ((c < color and r[1] >= skill) or (c > color and r[2] <= skill)) then s = {}; break end
  end
  local r = s[color]
  if r then
    r[1], r[2] = math.min(r[1], skill), math.max(r[2], skill)
  else
    s[color] = { skill, skill }
  end
  seen[id] = s
end

-- the limits CraftETA has seen: { nil, yellow, green, grey } (any may be nil)
local function Learned(id)
  local seen = Seen()
  local s = seen and seen[id]
  if not s then return nil end
  local edge = {}
  for c = 1, 3 do
    local before, now = s[c - 1], s[c]
    if before and now and now[1] == before[2] + 1 then edge[c] = now[1] end
  end
  local y, g, x = edge[1], edge[2], edge[3]
  if y and x and not g then g = math.floor((y + x) / 2) end
  if y and g and not x then x = 2 * g - y end
  if g and x and not y then y = 2 * g - x end
  if not (y or g or x) then return nil end
  return { nil, y, g, x }
end

-- where the recipe changes colour: { orange, yellow, green, grey } and where it came from ("data" or "seen"),
-- or nil. The game's data first, then what CraftETA has seen.
function ns.SkillUpRange(id)
  local r = id and ns.SKILLUP[id]
  if r then return r, "data" end
  r = id and Learned(id)
  if r and r[2] and r[4] then return r, "seen" end
  return nil
end

-- the colour at a skill: 0 orange, 1 yellow, 2 green, 3 grey
function ns.ColorAt(r, skill)
  if skill >= r[4] then return 3 end
  if skill >= r[3] then return 2 end
  if skill >= r[2] then return 1 end
  return 0
end

-- the chance of a point now: orange 1, grey 0, yellow and green (grey - skill) / (grey - yellow)
-- color: the game's colour, when known (it wins over the limits)
function ns.SkillUpChance(id, skill, color)
  local r = ns.SkillUpRange(id)
  if type(color) ~= "number" then
    if not r then return nil end
    color = ns.ColorAt(r, skill)
  end
  if color == 0 then return 1, color, r end
  if color == 3 then return 0, color, r end
  if not r or not r[2] or not r[4] or r[4] <= r[2] then return nil, color, r end
  return math.max(0, math.min(1, (r[4] - skill) / (r[4] - r[2]))), color, r
end

-- a craft's money: cost of the materials, what it sells for, profit after the AH's 5% (nil without a price)
function ns.CraftNet(r)
  local cost, missing = ns.CraftCost(r)
  local sell = r.o and ((ns.SellUnit and ns.SellUnit(r.o)) or ns.PriceID(r.o)) or nil
  local profit
  if sell and cost > 0 and not missing then profit = math.floor(sell * (r.y or 1) * 0.95) - cost end
  return cost, missing, sell, profit
end

-- materials per point: the cost of a craft divided by the chance (nil when there is no point to get)
function ns.CostPerPoint(r, chance)
  if not chance or chance <= 0 then return nil end
  local cost, missing = ns.CraftCost(r)
  if cost <= 0 then return nil end
  return cost / chance, missing
end

-- "62%" in the recipe's colour
function ns.ChanceText(chance, color)
  local hex = HEX[color] or "c0c0c0"
  return ("|cff%s%d%%|r"):format(hex, math.floor(chance * 100 + 0.5))
end

---------------------------------------------------------------------------
-- The bar for a tooltip: the four colours from orange to grey, and a white mark where your skill is
---------------------------------------------------------------------------
local BAR_W = 200
local function Block(w, c)
  if w < 1 then return "" end
  return ("|TInterface\\Buttons\\WHITE8X8:8:%d:0:0:8:8:0:8:0:8:%d:%d:%d|t"):format(w, c[1] * 255, c[2] * 255, c[3] * 255)
end
function ns.SkillBarText(r, skill)
  local lo = (r[1] and r[1] > 0) and r[1] or math.max(1, r[2] - 10)
  local hi = r[4] + math.max(5, math.floor((r[4] - lo) * 0.15))
  local function X(v) return math.floor((math.max(lo, math.min(hi, v)) - lo) / math.max(1, hi - lo) * BAR_W + 0.5) end
  local edges = { lo, r[2], r[3], r[4], hi }
  local at = X(skill)
  local parts = {}
  for i = 1, 4 do
    local x1, x2 = X(edges[i]), X(edges[i + 1])
    local c = COLORS[i - 1]
    if at >= x1 and at < x2 then
      parts[#parts + 1] = Block(at - x1, c)
      parts[#parts + 1] = Block(2, { 1, 1, 1 })
      parts[#parts + 1] = Block(x2 - at - 2, c)
    else
      parts[#parts + 1] = Block(x2 - x1, c)
    end
  end
  if at >= X(hi) then parts[#parts + 1] = Block(2, { 1, 1, 1 }) end
  return table.concat(parts)
end

-- the skill-up lines for a tooltip
function ns.AddSkillUpTip(tip, id, skill, color, book)
  local chance, c, r = ns.SkillUpChance(id, skill, color)
  if c == nil then return end
  tip:AddLine(" ")
  local head = ({ [0] = L("Always a skill-up", "Altid et skill-up"), [1] = L("Sometimes a skill-up", "Nogle gange et skill-up"),
    [2] = L("Rarely a skill-up", "Sjældent et skill-up"), [3] = L("No skill-ups any more", "Ingen skill-ups mere") })[c]
  local col = COLORS[c]
  tip:AddDoubleLine("|cffffffffCraft|r|cffffd24aETA|r  " .. head, chance and ns.ChanceText(chance, c) or "?", col[1], col[2], col[3], 1, 1, 1)
  if r and r[2] and r[4] then
    tip:AddLine(ns.SkillBarText(r, skill))
    tip:AddLine(("|cffff8040%s|r  |cffffff40%d|r  |cff40c040%d|r  |cff808080%d|r   %s %d"):format(r[1] or "", r[2], r[3], r[4],
      L("you", "dig"), skill), 0.8, 0.8, 0.8)
  elseif c == 1 or c == 2 then
    tip:AddLine(L("CraftETA learns where this recipe changes colour as you level it.",
      "CraftETA lærer hvor denne opskrift skifter farve, mens du lever den."), 0.55, 0.58, 0.64, true)
  end
  if book then
    local _, missing, _, profit = ns.CraftNet(book)
    local per = ns.CostPerPoint(book, chance)
    if profit and profit >= 0 then
      tip:AddDoubleLine(L("Each craft earns", "Hvert craft tjener"), "|cff73d973+" .. ns.Money(profit) .. "|r", 0.85, 0.87, 0.9, 1, 1, 1)
    elseif per then
      tip:AddDoubleLine(L("Materials per skill-up", "Mats pr. skill-up"), (missing and "~" or "") .. ns.Money(per), 0.85, 0.87, 0.9, 1, 1, 1)
      if profit then
        tip:AddDoubleLine(L("After selling the crafts", "Efter salg af crafts"), (missing and "~" or "") .. ns.Money(-profit / chance), 0.85, 0.87, 0.9, 1, 1, 1)
      end
    end
  end
end

---------------------------------------------------------------------------
-- The profession window's recipe list: the chance on every learned recipe, a green + on one that earns
---------------------------------------------------------------------------
local function BookEntry(profID, id)
  local me = ns.Me and ns.Me()
  local book = me and me.book and me.book[profID]
  return book and book[id]
end

local function Decorate(frame, elementData)
  if not frame or not elementData then return end
  local ok, data = pcall(function() return elementData.GetData and elementData:GetData() or elementData end)
  local info = ok and type(data) == "table" and data.recipeInfo
  local text = ""
  local open = info and ns.db and ns.db.skillChance ~= false and ns.OpenProfession and ns.OpenProfession()
  local id = info and Plain(info.recipeID)
  if open and type(id) == "number" and Plain(info.learned) ~= false then
    local color = Plain(info.relativeDifficulty)
    local chance, c = ns.SkillUpChance(id, open.rank or 0, color)
    if chance and c ~= 3 then
      text = ns.ChanceText(chance, c)
      local e = BookEntry(open.id, id)
      local _, _, _, profit = e and ns.CraftNet(e)
      if profit and profit >= 0 then text = text .. " |cff73d973+|r" end
    end
    frame.cetaID, frame.cetaColor, frame.cetaProf = id, color, open.id
  else
    frame.cetaID = nil
  end
  if not frame.ceta then
    if text == "" then return end
    local fs = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetPoint("RIGHT", frame, "RIGHT", -4, 0)
    fs:SetJustifyH("RIGHT")
    frame.ceta = fs
    frame:HookScript("OnEnter", function(self)
      if not self.cetaID or not (ns.db and ns.db.skillChance ~= false) then return end
      local o = ns.OpenProfession and ns.OpenProfession()
      if not o then return end
      if GameTooltip:GetOwner() ~= self then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local okI, ri = pcall(C_TradeSkillUI.GetRecipeInfo, self.cetaID)
        GameTooltip:SetText(okI and type(ri) == "table" and Plain(ri.name) or "", 1, 1, 1)
      end
      ns.AddSkillUpTip(GameTooltip, self.cetaID, o.rank or 0, self.cetaColor, BookEntry(self.cetaProf, self.cetaID))
      GameTooltip:Show()
    end)
    frame:HookScript("OnLeave", function(self) if GameTooltip:GetOwner() == self then GameTooltip:Hide() end end)
  end
  frame.ceta:SetText(text)
end

local box
local function RefreshList()
  if not box or not box.ForEachFrame then return end
  pcall(box.ForEachFrame, box, function(frame, elementData) Decorate(frame, elementData) end)
end
ns.RefreshSkillChance = RefreshList

-- note the colour of every learned recipe at your skill now
local function NoteAll()
  local open = ns.OpenProfession and ns.OpenProfession()
  if not open or not C_TradeSkillUI.GetAllRecipeIDs then return end
  local ok, ids = pcall(C_TradeSkillUI.GetAllRecipeIDs)
  if not ok or type(ids) ~= "table" then return end
  for _, id in ipairs(ids) do
    local okI, info = pcall(C_TradeSkillUI.GetRecipeInfo, id)
    if okI and type(info) == "table" and info.learned then
      ns.NoteColor(id, open.rank, Plain(info.relativeDifficulty))
    end
  end
end

local function Setup()
  if box then return end
  local page = ProfessionsFrame and ProfessionsFrame.CraftingPage
  local list = page and page.RecipeList
  box = list and list.ScrollBox
  if not box then return end
  if ScrollUtil and ScrollUtil.AddAcquiredFrameCallback then
    pcall(ScrollUtil.AddAcquiredFrameCallback, box, function(_, frame, elementData)
      C_Timer.After(0, function() if frame:IsShown() then Decorate(frame, frame.GetElementData and frame:GetElementData() or elementData) end end)
    end, box, true)
  end
  if box.RegisterCallback and ScrollBoxListMixin and ScrollBoxListMixin.Event and ScrollBoxListMixin.Event.OnDataRangeChanged then
    pcall(box.RegisterCallback, box, ScrollBoxListMixin.Event.OnDataRangeChanged, RefreshList, ns)
  end
end

-- a moment after the window settles: its colours lag behind a skill-up
local pending
local function Later()
  if pending then return end
  pending = true
  C_Timer.After(0.4, function()
    pending = nil
    Setup()
    NoteAll()
    RefreshList()
    if ns.UpdateRecipeCard then ns.UpdateRecipeCard() end
  end)
end

ns.Register("ADDON_LOADED")
ns.On("ADDON_LOADED", function(name) if name == "Blizzard_Professions" then Setup() end end)
for _, event in ipairs({ "TRADE_SKILL_SHOW", "TRADE_SKILL_LIST_UPDATE", "SKILL_LINES_CHANGED", "BAG_UPDATE_DELAYED", "AUCTION_HOUSE_CLOSED" }) do
  ns.Register(event)
  ns.On(event, Later)
end

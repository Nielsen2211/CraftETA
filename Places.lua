-- CraftETA: where things are. Trainers and vendors get a map pin (the game's own arrow), and at a trainer
-- one button learns what your guide still needs there.
-- Places are learned as you play: every trainer and vendor you talk to (or target) is remembered with its
-- map spot, for all your characters. Until then a click opens the world map on the right city.
local _, ns = ...
local Plain = ns.Plain

local function L(en, da) return (ns.db and ns.db.lang == "da") and da or en end

---------------------------------------------------------------------------
-- Map spots
---------------------------------------------------------------------------
local function Spots()
  ns.db.spots = ns.db.spots or {}
  return ns.db.spots
end

-- where you stand now: { m = uiMapID, x, y (0-1), zone }
function ns.PlayerSpot()
  if not (C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition) then return nil end
  local okM, map = pcall(C_Map.GetBestMapForUnit, "player")
  map = okM and Plain(map) or nil
  if type(map) ~= "number" then return nil end
  local okP, pos = pcall(C_Map.GetPlayerMapPosition, map, "player")
  if not okP or not pos or not pos.GetXY then return nil end
  local x, y = pos:GetXY()
  x, y = Plain(x), Plain(y)
  if type(x) ~= "number" or type(y) ~= "number" or (x == 0 and y == 0) then return nil end
  return { m = map, x = x, y = y, zone = Plain(GetZoneText and GetZoneText()) or "" }
end

-- remember an NPC where you stand (you are next to it when you talk to it)
function ns.RememberNPC(name)
  name = Plain(name)
  if type(name) ~= "string" or name == "" or not ns.db then return end
  local spot = ns.PlayerSpot()
  if spot then Spots()[name] = spot end
  return spot
end

function ns.SpotOf(name) return ns.db and ns.db.spots and ns.db.spots[name] end

-- the game's own arrow to a spot
function ns.Pin(spot, label)
  if not spot or not (C_Map and C_Map.SetUserWaypoint and UiMapPoint) then return false end
  if C_Map.CanSetUserWaypointOnMap then
    local okC, can = pcall(C_Map.CanSetUserWaypointOnMap, spot.m)
    if okC and can == false then return false end
  end
  local ok = pcall(function()
    C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(spot.m, spot.x, spot.y))
    if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then C_SuperTrack.SetSuperTrackedUserWaypoint(true) end
  end)
  if ok then
    ns.Print(("%s  |cffffd24a%s (%.1f, %.1f)|r"):format(L("arrow to", "pil til") .. " " .. (label or ""),
      spot.zone or "", spot.x * 100, spot.y * 100))
  end
  return ok
end

-- a map by its name ("Orgrimmar", "Stranglethorn Vale"), found once and kept
local mapCache = {}
local function MapByName(name)
  if mapCache[name] ~= nil then return mapCache[name] or nil end
  local found = false
  if C_Map and C_Map.GetMapInfo then
    for id = 1, 2600 do
      local ok, info = pcall(C_Map.GetMapInfo, id)
      if ok and type(info) == "table" and Plain(info.name) == name and (Plain(info.mapType) or 0) >= 3 then
        found = id
        break
      end
    end
  end
  mapCache[name] = found
  return found or nil
end

-- the places named in the guides' trainer texts, and the map each one is on
local TOWNS = {
  "Orgrimmar", "Undercity", "Thunder Bluff", "Stormwind", "Ironforge", "Darnassus", "Silvermoon", "Exodar",
  "Booty Bay", "Gadgetzan", "Ratchet", "Everlook", "Tarren Mill", "Hammerfall", "Stonard", "Theramore",
  "Menethil Harbor", "Southshore", "Astranaar", "Crossroads", "Thelsamar", "Lakeshire", "Sentinel Hill", "Darkshire",
}
local MAP_OF = {
  Stormwind = "Stormwind City", ["Booty Bay"] = "Stranglethorn Vale", Gadgetzan = "Tanaris", Ratchet = "The Barrens",
  Crossroads = "The Barrens", Everlook = "Winterspring", ["Tarren Mill"] = "Hillsbrad Foothills", Southshore = "Hillsbrad Foothills",
  Hammerfall = "Arathi Highlands", Stonard = "Swamp of Sorrows", Theramore = "Dustwallow Marsh", ["Menethil Harbor"] = "Wetlands",
  Astranaar = "Ashenvale", Thelsamar = "Loch Modan", Lakeshire = "Redridge Mountains", ["Sentinel Hill"] = "Westfall",
  Darkshire = "Duskwood", Silvermoon = "Silvermoon City", Exodar = "The Exodar",
}

local function OpenMap(town)
  local map = MapByName(MAP_OF[town] or town) or MapByName(town)
  if not map then return false end
  if OpenWorldMap then
    return pcall(OpenWorldMap, map)
  elseif WorldMapFrame and WorldMapFrame.SetMapID then
    if not WorldMapFrame:IsShown() and ToggleWorldMap then ToggleWorldMap() end
    return pcall(WorldMapFrame.SetMapID, WorldMapFrame, map)
  end
  return false
end

-- "Nogg (Orgrimmar), Franklin Lloyd (Undercity)" or "Saru Steelfury, Orgrimmar (50s)": an arrow to the one you
-- have met (on your map first), else the map of the first town named
function ns.ShowPlace(text)
  if type(text) ~= "string" or text == "" then return end
  local here = ns.PlayerSpot()
  local best
  for name, spot in pairs(ns.db and ns.db.spots or {}) do
    if string.find(text, name, 1, true) then
      if not best or (here and spot.m == here.m and best.spot.m ~= here.m) then best = { name = name, spot = spot } end
    end
  end
  if best and ns.Pin(best.spot, best.name) then return end
  local first, at = nil, math.huge
  for _, town in ipairs(TOWNS) do
    local i = string.find(text, town, 1, true)
    if i and i < at then first, at = town, i end
  end
  ns.Print("|cffffd24a" .. text .. "|r")
  if first and OpenMap(first) then
    ns.Print(L("The map shows " .. first .. ". Talk to them once, and next time you get an arrow.",
      "Kortet viser " .. first .. ". Tal med dem én gang, så får du en pil næste gang."))
  end
end

-- where to learn a profession's next rank
function ns.ShowTrainer(profID)
  local skills = ns.Skills and ns.Skills() or {}
  local s = skills[profID]
  local r = ns.NextRank(profID, s and s.rank or 1, s and s.max or 75)
  if r then ns.ShowPlace(r[ns.Faction()]) end
end

-- where to buy a vendor material: the vendor you saw sell it, else the kind of vendor and the towns
function ns.ShowVendor(item)
  local v = ns.db and ns.db.vendors and ns.db.vendors[item]
  if v and v.npc then
    local spot = v.spot or ns.SpotOf(v.npc)
    if spot and ns.Pin(spot, v.npc) then return end
  end
  local lines = ns.VendorWhere and ns.VendorWhere(item) or {}
  ns.ShowPlace(lines[#lines] or "")
end

-- a small map button
function ns.MapButton(parent, tip, onClick)
  local b = ns.IconButton(parent, "Interface\\Icons\\INV_Misc_Map_01", 14, tip)
  b:SetScript("OnClick", onClick)
  return b
end

---------------------------------------------------------------------------
-- Learning places as you play
---------------------------------------------------------------------------
-- every trainer name in the guides (so targeting one is enough)
local trainerNames
local function IsTrainer(name)
  if not trainerNames then
    trainerNames = {}
    local function Add(text)
      for part in string.gmatch(text or "", "[^,]+") do
        local n = string.match(part, "^%s*(.-)%s*%(") or string.match(part, "^%s*(.-)%s*$")
        if n and n ~= "" then trainerNames[n] = true end
      end
    end
    for _, set in ipairs({ ns.GUIDES or {}, ns.GATHER or {} }) do
      for _, guide in pairs(set) do
        for _, r in ipairs(guide.ranks or {}) do Add(r.h); Add(r.a) end
      end
    end
  end
  return trainerNames[name]
end

for _, e in ipairs({ "TRAINER_SHOW", "MERCHANT_SHOW", "GOSSIP_SHOW" }) do
  ns.Register(e)
  ns.On(e, function()
    if not ns.db then return end
    local name = Plain(UnitName("npc"))
    if e ~= "GOSSIP_SHOW" or (name and IsTrainer(name)) then ns.RememberNPC(name) end
  end)
end
ns.Register("PLAYER_TARGET_CHANGED")
ns.On("PLAYER_TARGET_CHANGED", function()
  if not ns.db or not UnitExists("target") or UnitIsPlayer("target") then return end
  local name = Plain(UnitName("target"))
  if name and IsTrainer(name) and CheckInteractDistance and Plain(CheckInteractDistance("target", 4)) then
    ns.RememberNPC(name)
  end
end)

---------------------------------------------------------------------------
-- At a trainer: learn what the guide needs in one click
---------------------------------------------------------------------------
local guideRecipes
local function GuideRecipe(name)
  if not guideRecipes then
    guideRecipes = {}
    for profID, guide in pairs(ns.GUIDES or {}) do
      for _, step in ipairs(guide.steps) do
        for _, e in ipairs(ns.Entries(step)) do guideRecipes[e[1]] = profID end
      end
    end
  end
  return guideRecipes[name]
end

local learnBtn
local function TrainerList()
  local out, cost = {}, 0
  if not (GetNumTrainerServices and GetTrainerServiceInfo) then return out, cost end
  local okN, n = pcall(GetNumTrainerServices)
  for i = 1, (okN and tonumber(Plain(n)) or 0) do
    local ok, name, sub, kind = pcall(GetTrainerServiceInfo, i)
    name, kind = Plain(name), Plain(kind)
    if ok and kind == "available" and type(name) == "string" then
      -- a recipe the guide uses, or the next rank itself (the service carries the profession's name)
      local rankUp = false
      for _, guide in pairs(ns.GUIDES or {}) do
        if guide.name == name then rankUp = true end
      end
      if GuideRecipe(name) or rankUp then
        local okC, c = pcall(GetTrainerServiceCost, i)
        c = okC and tonumber(Plain(c)) or 0
        out[#out + 1] = { index = i, name = name, rank = rankUp and Plain(sub) or nil, cost = c }
        cost = cost + c
      end
    end
  end
  return out, cost
end

local function UpdateTrainer()
  if not learnBtn then return end
  if not ns.trainerOpen then learnBtn:Hide(); return end
  local frame = ClassTrainerFrame and ClassTrainerFrame:IsShown() and ClassTrainerFrame or nil
  local list, cost = TrainerList()
  if #list == 0 then learnBtn:Hide(); return end
  learnBtn:SetText(L("CraftETA: learn %d for the guide (%s)", "CraftETA: lær %d til guiden (%s)"):format(#list, ns.MoneyShort(cost)))
  local names = {}
  for _, s in ipairs(list) do names[#names + 1] = s.rank and (s.name .. " (" .. s.rank .. ")") or s.name end
  learnBtn.tip = L("What your guide still needs from this trainer:\n", "Det guiden mangler fra denne træner:\n") .. table.concat(names, "\n")
  learnBtn.list = list
  learnBtn:ClearAllPoints()
  if frame then learnBtn:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 4, -4) else learnBtn:SetPoint("TOP", UIParent, "TOP", 0, -120) end
  learnBtn:Show()
end

local function LearnAll(self)
  if not self.list then return end
  -- highest index first, so the ones before keep their place in the list
  for i = #self.list, 1, -1 do
    local s = self.list[i]
    if GetMoney() >= s.cost then pcall(BuyTrainerService, s.index) end
  end
  C_Timer.After(0.6, UpdateTrainer)
end

ns.Register("TRAINER_SHOW")
ns.On("TRAINER_SHOW", function()
  ns.trainerOpen = true
  if not ns.db or ns.db.trainerButton == false then return end
  if not learnBtn then
    learnBtn = ns.Button(UIParent, "", 260, 24)
    learnBtn:SetFrameStrata("HIGH")
    learnBtn:SetScript("OnClick", LearnAll)
  end
  C_Timer.After(0.2, UpdateTrainer)
end)
for _, e in ipairs({ "TRAINER_UPDATE", "TRAINER_CLOSED" }) do
  ns.Register(e)
  ns.On(e, function()
    if e == "TRAINER_CLOSED" then ns.trainerOpen = false end
    C_Timer.After(0.2, UpdateTrainer)
  end)
end

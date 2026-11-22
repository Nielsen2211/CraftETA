-- CraftETA core: saved data, text, skills, prices, items and the leveling route.
-- Same family and look as LevelETA, GoldETA, LayerETA and TrackETA.
local ADDON, ns = ...

ns.PATH = "Interface\\AddOns\\" .. ADDON .. "\\"
ns.TEX = ns.PATH .. "Textures\\"
ns.F_SEMI = ns.PATH .. "Fonts\\Inter-SemiBold.ttf"
ns.F_BOLD = ns.PATH .. "Fonts\\Inter-Bold.ttf"
ns.GOLD = { 1, 0.82, 0.3 }

---------------------------------------------------------------------------
-- Text
---------------------------------------------------------------------------
local LOC = {
  en = {
    toRank = "To %d", to300 = "To 300", crafts = "%d crafts", left = "%d left", make = "Make %d",
    craft1 = "Craft 1", craftAll = "Craft all", addList = "+ Shopping list", addedList = "Added to the shopping list.",
    learnRank = "Learn %s now", rankAt = "%s at %d (level %d)", needRecipe = "Learn this recipe first",
    openWindow = "Open your profession window to craft", done = "300: you're done!", noGuide = "No guide for this profession.",
    noProf = "Open a profession window, or learn a profession.", next = "Next: %s", note = "Note",
    other = "Other choice: click the arrows", have = "have", need = "need", stepOf = "Step %d of %d",
    list = "Shopping list", empty = "The shopping list is empty.", clear = "Clear", item = "Item", still = "Still",
    bought = "Bought", inMail = "In mail", est = "Estimate", total = "Total", scan = "Scan prices", scanning = "Scanning %d/%d...",
    buy = "Buy %d %s", confirm = "Confirm %s (%s)", next2 = "Next", allBought = "Everything is bought. Get it from your mailbox.",
    notListed = "None for sale", notCommodity = "Buy by hand (not a stackable item)", priceUp = "+%d%% over the estimate",
    boughtMsg = "Bought %d %s for %s.", failed = "The purchase failed; try again.", scanHint = "Maybe fewer are listed: Scan prices shows how many.", auctionator = "To Auctionator",
    auctionatorDone = "Shopping list \"CraftETA\" made in Auctionator.", searchAux = "Click: search in aux",
    settings = "Settings", panelOpt = "Panel next to the profession window", ahOpt = "Buy guide at the auction house",
    autoOpt = "Buy right away when the price is close to the estimate", autoScanOpt = "Check today's prices when the auction house opens", guardOpt = "Ask first above the estimate by", nextOpt = "Show the next step", minimapOpt = "Minimap button",
    mmLeft = "Click: the panel", mmRight = "Right-click: shopping list", mmShift = "Shift-click: settings", mmDrag = "Drag: move the button",
    lang = "Language", stepMode = "This step", rankMode = "To next rank", allMode = "To 300", addWhat = "Add to the list:",
    eta = "~%s", perHour = "%d skill/hour", unknownPrice = "no price", vendor = "vendor", source = "Route: %s",
    help = "/ceta: panel  ·  /ceta list  ·  /ceta config  ·  /ceta reset  ·  /ceta da|en",
  },
  da = {
    toRank = "Til %d", to300 = "Til 300", crafts = "%d crafts", left = "%d tilbage", make = "Lav %d",
    craft1 = "Craft 1", craftAll = "Craft alle", addList = "+ Indkøbsliste", addedList = "Lagt på indkøbslisten.",
    learnRank = "Lær %s nu", rankAt = "%s ved %d (level %d)", needRecipe = "Lær opskriften først",
    openWindow = "Åbn dit fagvindue for at crafte", done = "300: du er færdig!", noGuide = "Ingen guide til det fag.",
    noProf = "Åbn et fagvindue, eller lær et fag.", next = "Næste: %s", note = "Note",
    other = "Andet valg: klik på pilene", have = "har", need = "skal bruge", stepOf = "Trin %d af %d",
    list = "Indkøbsliste", empty = "Indkøbslisten er tom.", clear = "Ryd", item = "Vare", still = "Mangler",
    bought = "Købt", inMail = "I posten", est = "Overslag", total = "I alt", scan = "Scan priser", scanning = "Scanner %d/%d...",
    buy = "Køb %d %s", confirm = "Bekræft %s (%s)", next2 = "Næste", allBought = "Alt er købt. Hent det i postkassen.",
    notListed = "Ingen til salg", notCommodity = "Køb selv (ikke en samlet vare)", priceUp = "+%d%% over overslaget",
    boughtMsg = "Købte %d %s for %s.", failed = "Købet fejlede, prøv igen.", scanHint = "Måske er der færre til salg: Scan priser viser hvor mange.", auctionator = "Til Auctionator",
    auctionatorDone = "Indkøbslisten \"CraftETA\" er lavet i Auctionator.", searchAux = "Klik: søg i aux",
    settings = "Indstillinger", panelOpt = "Panel ved siden af fagvinduet", ahOpt = "Købsguide i auktionshuset",
    autoOpt = "Køb med det samme, når prisen er tæt på overslaget", autoScanOpt = "Tjek dagens priser, når auktionshuset åbner", guardOpt = "Spørg først over overslaget med", nextOpt = "Vis næste trin", minimapOpt = "Knap ved minimappet",
    mmLeft = "Klik: panelet", mmRight = "Højreklik: indkøbsliste", mmShift = "Shift-klik: indstillinger", mmDrag = "Træk: flyt knappen",
    lang = "Sprog", stepMode = "Dette trin", rankMode = "Til næste rank", allMode = "Til 300", addWhat = "Læg på listen:",
    eta = "~%s", perHour = "%d skill/time", unknownPrice = "ingen pris", vendor = "vendor", source = "Rute: %s",
    help = "/ceta: panel  ·  /ceta list  ·  /ceta config  ·  /ceta reset  ·  /ceta da|en",
  },
}
function ns.T(key, ...)
  local lang = (ns.db and ns.db.lang) or "en"
  local text = (LOC[lang] or LOC.en)[key] or LOC.en[key] or key
  if select("#", ...) > 0 then
    return text:format(...)
  end
  return text
end

function ns.Print(text)
  print("|cffffffffCraft|r|cffffd24aETA|r: " .. tostring(text))
end

local DEFAULTS = {
  lang = "en", panel = true, ah = true, autoScan = true, autoBuy = true, guard = 20, showNext = true, minimap = true, minimapAngle = 220,
  list = {}, ids = {}, mail = {}, bought = {}, choice = {}, points = {},
}

---------------------------------------------------------------------------
-- Small helpers
---------------------------------------------------------------------------
local function secret(v)
  return type(issecretvalue) == "function" and issecretvalue(v) or false
end
function ns.Plain(v)
  if secret(v) then return nil end
  return v
end

function ns.Money(copper)
  if not copper then return "?" end
  copper = math.floor(copper + 0.5)
  local g, s, c = math.floor(copper / 10000), math.floor(copper / 100) % 100, copper % 100
  local gold, silver, cop = "|cffffd24ag|r", "|cffc7c7cfs|r", "|cffeda55fc|r"
  if g > 0 then
    return ("%d%s %d%s"):format(g, gold, s, silver)
  elseif s > 0 then
    return ("%d%s %d%s"):format(s, silver, c, cop)
  end
  return ("%d%s"):format(c, cop)
end

function ns.Duration(seconds)
  if not seconds or seconds <= 0 then return nil end
  if seconds < 60 then return "1 min" end
  local m = math.floor(seconds / 60 + 0.5)
  if m < 60 then return m .. " min" end
  return ("%dt %02dm"):format(math.floor(m / 60), m % 60)
end

function ns.Faction()
  local f = UnitFactionGroup and UnitFactionGroup("player")
  return f == "Horde" and "h" or "a"
end

---------------------------------------------------------------------------
-- Items: names to IDs (learned from recipes, the auction house and bags)
---------------------------------------------------------------------------
local GetItemInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
local GetItemInfoInstant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
local GetItemCount = (C_Item and C_Item.GetItemCount) or GetItemCount

function ns.LearnItem(name, itemID)
  if ns.db and type(name) == "string" and type(itemID) == "number" then
    ns.db.ids[name] = itemID
  end
end

function ns.ItemID(name)
  if not name then return nil end
  local id = ns.db and ns.db.ids[name]
  if id then return id end
  if GetItemInfoInstant then
    local ok, found = pcall(GetItemInfoInstant, name)
    if ok and type(found) == "number" then
      ns.LearnItem(name, found)
      return found
    end
  end
  return nil
end

function ns.ItemIcon(name)
  local id = ns.ItemID(name)
  if id and GetItemInfoInstant then
    local ok, _, _, _, _, icon = pcall(GetItemInfoInstant, id)
    if ok and icon then return icon end
  end
  return 134400 -- the question mark icon
end

-- bags and bank
function ns.Have(name)
  local id = ns.ItemID(name)
  if not id or not GetItemCount then return 0 end
  local ok, count = pcall(GetItemCount, id, true)
  return ok and tonumber(count) or 0
end

---------------------------------------------------------------------------
-- Prices: aux first, then Auctionator, then the last auction house scan of CraftETA
---------------------------------------------------------------------------
function ns.Price(name)
  local id = ns.ItemID(name)
  local scanned = ns.db and ns.db.scanned and ns.db.scanned[name]
  if id then
    local aux = _G.AuxForeverAPI
    if aux and aux.IsReady and aux.IsReady() then
      local ok, price = pcall(aux.GetUsualPrice, id)
      if ok and type(price) == "number" and price > 0 then return price end
    end
    local atr = _G.Auctionator and Auctionator.API and Auctionator.API.v1
    if atr and atr.GetAuctionPriceByItemID then
      local ok, price = pcall(atr.GetAuctionPriceByItemID, ADDON, id)
      if ok and type(price) == "number" and price > 0 then return price end
    end
  end
  if scanned and scanned.unit then return scanned.unit end
  return nil
end

---------------------------------------------------------------------------
-- Skills
---------------------------------------------------------------------------
-- skill line ID -> { rank, max }, from the skills list (and the open profession window)
function ns.Skills()
  local found = {}
  local function add(id, rank, max)
    id, rank, max = ns.Plain(id), ns.Plain(rank), ns.Plain(max)
    if type(id) == "number" and ns.GUIDES[id] and type(rank) == "number" then
      found[id] = { rank = rank, max = type(max) == "number" and max or 300 }
    end
  end
  if C_SkillInfo and C_SkillInfo.GetSkillLineInfoByID then
    for id in pairs(ns.GUIDES) do
      local ok, info = pcall(C_SkillInfo.GetSkillLineInfoByID, id)
      if ok and type(info) == "table" then add(id, info.rank, info.maxRank) end
    end
  end
  if GetProfessions and GetProfessionInfo then
    local slots = { GetProfessions() }
    for i = 1, 8 do
      if slots[i] then
        local ok, _, _, rank, max, _, _, line = pcall(GetProfessionInfo, slots[i])
        if ok then add(line, rank, max) end
      end
    end
  end
  if not next(found) and GetNumSkillLines and GetSkillLineInfo then
    for i = 1, GetNumSkillLines() do
      local name, header, _, rank, _, _, max = GetSkillLineInfo(i)
      if not header and ns.SKILL_BY_NAME[name] then add(ns.SKILL_BY_NAME[name], rank, max) end
    end
  end
  local open = ns.OpenProfession and ns.OpenProfession()
  if open then
    add(open.id, open.rank, open.max)
  end
  return found
end

---------------------------------------------------------------------------
-- The route
---------------------------------------------------------------------------
-- the craft entries of a step: { recipe, crafts, mats }
local function Entries(step)
  local list = {}
  for i = 3, #step do
    list[#list + 1] = step[i]
  end
  return list
end
ns.Entries = Entries

function ns.StepIndex(guide, skill)
  for i, step in ipairs(guide.steps) do
    if skill < step[2] then
      return i
    end
  end
  return nil
end

-- which craft of an "any" step: the player's pick, else one you know or have materials for
function ns.Chosen(profID, index, step)
  local entries = Entries(step)
  if not step.any then
    return entries
  end
  local pick = ns.db.choice[profID .. ":" .. index]
  if pick and entries[pick] then
    return { entries[pick] }, pick
  end
  local best, bestScore = 1, -1
  for i, entry in ipairs(entries) do
    local score = 0
    local recipe = ns.Recipe and ns.Recipe(entry[1])
    if recipe and recipe.learned then score = score + 100 end
    local mats = entry[3]
    for m = 1, #mats, 2 do
      if ns.Have(mats[m]) > 0 then score = score + 10 end
    end
    if score > bestScore then best, bestScore = i, score end
  end
  return { entries[best] }, best
end

-- how much of a step is still to do from this skill (1: all of it)
local function Share(step, skill)
  local from, to = step[1], step[2]
  if skill >= to then return 0 end
  if skill <= from or to <= from then return 1 end
  return (to - skill) / (to - from)
end

-- crafts and materials from the skill you have up to `target`
-- returns crafts, mats { [name] = count }, ordered names
function ns.Plan(profID, skill, target)
  local guide = ns.GUIDES[profID]
  local crafts, mats, order, made = 0, {}, {}, {}
  if not guide then return 0, mats, order end
  for index, step in ipairs(guide.steps) do
    if step[1] < target and skill < step[2] then
      local share = Share(step, skill)
      if step[2] > target then
        share = share * (target - math.max(step[1], skill)) / math.max(1, step[2] - math.max(step[1], skill))
      end
      for _, entry in ipairs((ns.Chosen(profID, index, step))) do
        local n = math.ceil(entry[2] * share)
        crafts = crafts + n
        -- what the route makes itself (bolts, grinding stones, oils) isn't bought later
        made[entry[1]] = (made[entry[1]] or 0) + n * (entry[4] or 1)
        local list = entry[3]
        for m = 1, #list, 2 do
          local name = list[m]
          if not mats[name] then order[#order + 1] = name end
          mats[name] = (mats[name] or 0) + math.ceil(list[m + 1] * share)
        end
      end
    end
  end
  -- the route's own products it doesn't make enough of (Bolt of Runecloth for the last steps): their
  -- materials instead, from the step that makes them
  local recipes = {}
  for _, step in ipairs(guide.steps) do
    for _, entry in ipairs(Entries(step)) do
      recipes[entry[1]] = recipes[entry[1]] or entry
    end
  end
  for pass = 1, 2 do
    for _, name in ipairs(order) do
      local short = (mats[name] or 0) - (made[name] or 0)
      local entry = recipes[name]
      if short > 0 and entry then
        local runs = math.ceil(short / (entry[4] or 1))
        made[name] = (made[name] or 0) + runs * (entry[4] or 1)
        local list = entry[3]
        for m = 1, #list, 2 do
          local mat = list[m]
          if not mats[mat] then order[#order + 1] = mat end
          mats[mat] = (mats[mat] or 0) + math.ceil(runs * list[m + 1] / math.max(1, entry[2]))
        end
      end
    end
  end
  local kept = {}
  for _, name in ipairs(order) do
    mats[name] = math.max(0, mats[name] - (made[name] or 0))
    if mats[name] > 0 then
      kept[#kept + 1] = name
    else
      mats[name] = nil
    end
  end
  return crafts, mats, kept
end

-- what the materials cost, counting what you already have
function ns.Cost(mats)
  local total, unknown = 0, false
  for name, count in pairs(mats) do
    local missing = math.max(0, count - ns.Have(name))
    if missing > 0 then
      local price = ns.Price(name)
      if price then total = total + price * missing else unknown = true end
    end
  end
  return total, unknown
end

-- the next rank you have to learn: { at, need, lvl, where } or nil
function ns.NextRank(profID, rank, max)
  local guide = ns.GUIDES[profID]
  if not guide then return nil end
  for _, r in ipairs(guide.ranks) do
    if max <= r.at then
      return r
    end
  end
  return nil
end

-- the cap you are working toward: what your rank lets you reach (75, 150, 225 or 300)
function ns.Target(profID, rank, max)
  return math.min(300, math.max(max or 300, 1))
end

---------------------------------------------------------------------------
-- Pace: skill points per hour while you craft (this session)
---------------------------------------------------------------------------
local pace = {}
function ns.NoteSkill(profID, rank)
  local p = pace[profID]
  local now = GetTime()
  if not p then
    pace[profID] = { first = now, rank = rank, start = rank, last = now }
    return
  end
  if rank > p.rank then
    -- a long break doesn't count as crafting time
    if now - p.last > 300 then
      p.first = p.first + (now - p.last)
    end
    p.rank, p.last = rank, now
  end
end

function ns.PerHour(profID)
  local p = pace[profID]
  if not p or p.rank - p.start < 3 then return nil end
  local hours = (p.last - p.first) / 3600
  if hours <= 0 then return nil end
  return (p.rank - p.start) / hours
end

-- time for this many points and crafts: your pace, or about 3.5 seconds a craft
function ns.TimeFor(profID, points, crafts)
  local rate = ns.PerHour(profID)
  if rate and rate > 0 then
    return points / rate * 3600
  end
  return crafts * 3.5
end

---------------------------------------------------------------------------
-- Start
---------------------------------------------------------------------------
ns.listeners = {}
function ns.On(event, fn)
  ns.listeners[event] = ns.listeners[event] or {}
  table.insert(ns.listeners[event], fn)
end

local events = CreateFrame("Frame")
ns.events = events
events:SetScript("OnEvent", function(_, event, ...)
  if event == "ADDON_LOADED" then
    if ... ~= ADDON then return end
    CraftETADB = CraftETADB or {}
    ns.db = CraftETADB
    for key, value in pairs(DEFAULTS) do
      if ns.db[key] == nil then
        ns.db[key] = type(value) == "table" and {} or value
      end
    end
    ns.db.scanned = ns.db.scanned or {}
  end
  for _, fn in ipairs(ns.listeners[event] or {}) do
    local ok, err = pcall(fn, ...)
    if not ok then
      geterrorhandler()(err)
    end
  end
end)
function ns.Register(event)
  pcall(events.RegisterEvent, events, event)
end
ns.Register("ADDON_LOADED")

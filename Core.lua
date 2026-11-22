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
    craft = "Craft", craftN = "Craft %d", craftSub = "Craft %d (material)", craftFirst = "First %d %s: the step needs them, and you can make them.", craftTip = "Crafts %d %s: what this step still needs, or as many as your bags allow.", addList = "+ Shopping list", addedList = "Added to the shopping list.",
    learnRank = "Learn %s now", rankAt = "%s at %d (level %d)", needRecipe = "Learn this recipe first",
    openWindow = "Open your profession window to craft", done = "300: you're done!", noGuide = "No guide for this profession.",
    noProf = "Open a profession window, or learn a profession.", next = "Next: %s", note = "Note",
    other = "Other choice: click the arrows", have = "have", need = "need", stepOf = "Step %d of %d",
    list = "Shopping list", empty = "The shopping list is empty.", clear = "Clear", item = "Item", still = "Still",
    bought = "Bought", inMail = "In mail", est = "Estimate", total = "Total", scan = "Scan prices", scanning = "Scanning %d/%d...",
    buy = "Buy %d %s", confirm = "Confirm %s (%s)", next2 = "Next", allBought = "Everything is bought. Get it from your mailbox.",
    notListed = "None for sale", notCommodity = "Buy by hand (not a stackable item)", priceUp = "+%d%% over the estimate",
    boughtMsg = "Bought %d %s for %s.", failed = "The purchase failed; try again.", scanHint = "Maybe fewer are listed: Scan prices shows how many.", auctionator = "To Auctionator",
    auctionatorDone = "Shopping list \"CraftETA\" made in Auctionator.", searchAux = "Click: search in %s",
    settings = "Settings", panelOpt = "Panel next to the profession window", ahOpt = "Buy guide at the auction house",
    autoOpt = "Buy right away when the price is close to the estimate", autoScanOpt = "Check today's prices when the auction house opens", guardOpt = "Ask first above the estimate by", nextOpt = "Show the next step", minimapOpt = "Minimap button",
    mmLeft = "Click: CraftETA", mmRight = "Right-click: shopping list", mmShift = "Shift-click: settings", mmDrag = "Drag: move the button",
    lang = "Language", stepMode = "This step", rankMode = "To next rank", allMode = "To 300", addWhat = "Add to the list:",
    eta = "~%s", perHour = "%d skill/hour", unknownPrice = "no price", vendor = "vendor", source = "Route: %s",
    anyOne = "One of these is enough", t_guide = "Professions", t_recipes = "Recipes", t_profit = "Profit", t_crafters = "Crafters", t_chars = "Characters", t_list = "Shopping list", t_settings = "Settings",
    more = "+%d more (scroll)", f_all = "All", f_learned = "Learned", f_missing = "Not learned",
    noBook = "Open your profession windows once so CraftETA can read your recipes.", notLearned = "Not learned yet",
    ttMade = "Made by", ttCost = "Craft cost", ttUsed = "Used in", ttRecipes = "%s: %d recipes", recipeCount = "%d recipes",
    p_craft = "Craft", p_farm = "Farm", youGather = "You can gather it (%s)", needProf = "Needs %s", fromMobs = "Drops from humanoids",
    farmFoot = "Auction house price for one, highest first", noPrices = "No prices yet: scan the auction house with %s.",
    sellsFor = "Sells for (%d)", ahCut = "Auction house cut (5%)", matsCost = "Materials", profit = "Profit",
    profitFoot = "Recipes your characters know, best first. Prices from %s.", noProfit = "No prices yet, or no recipes read: open your profession windows and scan the auction house.",
    search = "Search", searchHint = "Recipe name, e.g. Mithril", yours = "yours", clickWhisper = "Click: whisper",
    craftersFoot = "Your characters answer right away, guild members with CraftETA in a moment.", asking = "Asking your guild...",
    noneFound = "Nobody found.", noneFoundHelp = "Nobody found. Only guild members with CraftETA answer, so trade chat is read too: try again when people advertise.", adTrade = "trade chat", adAgo = "trade chat, %d min ago", chatAds = "Read trade chat for crafters", guildAnswers = "Guild answers keep coming in for a few seconds.",
    lvl = "level %d", rightRemove = "Right-click: remove this character", charsFoot = "%d characters · %s in all",
    notKnown = "You don't have %s.", learnAt = "Learn the next rank at %d (level %d): %s", where = "Where:",
    tooltipOpt = "CraftETA lines in item tooltips", guildShareOpt = "Answer when guild members search for crafters",
    guildAskOpt = "Ask my guild when I search for crafters", hub = "CraftETA",
    wholeRoute = "1-300", farmStart = "Start farming", farmStop = "Stop farming", farmReset = "New session", farmTotal = "Worth %s", farmMoney = "%s in coins", farmVendor = "(some at vendor price)", farmWaiting = "Loot something: it shows up here.", farmHint = "Press Start farming, then gather or kill.", craftNow = "Craft now", openFromBook = "Open your profession from the spellbook to craft.", ahAddon = "Auction house addon: %s", noAhAddon = "none found (CraftETA scans itself)", allProfs = "All professions", myProfs = "My professions", learnNow = "Learn %s now (level %d): %s", learnAt2 = "Learn %s at %d (level %d): %s", stepSkip = "Skip this step", stepBack = "Back to the step your skill is on", skippedAhead = "skipped ahead", steps = "%d steps", yourCap = "%d = your cap", t_home = "Home", t_alts = "Alts", t_specs = "Specializations", t_gold = "Gold", t_codex = "Codex", t_camping = "Camping", t_cooldowns = "Cooldowns",
    c_recipes = "Recipes", c_materials = "Materials", lvlClass = "Level %d %s", tracker = "Item tracker",
    cdReady = "%s is ready on %s.", trackOff = "%s is off", trackHint = "turn it on to see it on your minimap.", turnOn = "Turn on",
    trackerHint = "Mouse wheel: change the goal. Right-click: stop tracking.", trackerEmpty = "Right-click a material in Codex or Gold to track it.",
    cfHead = "Crafters", cfCount = "%d online · %d in all", cfSearch = "Search a player, an item or a recipe...", cfWhisper = "Whisper", cfInvite = "Invite", cfMine = "your character", cfGuild = "guild", cfTrade = "trade chat", cfOffline = "offline", cfSeen = "%s ago", cfCrafter = "Crafter", cfPick = "Click a crafter to see their professions, recipes and advert.", cfProfs = "Professions", cfAdvert = "Advert", cfRecipes = "Recipes", cfNoRecipes = "Not known yet. Search for an item and press Enter to ask your guild.", cfMore = "%d-%d of %d, scroll for more", cfNone = "Nobody yet. Your characters show up once you open a profession window, guild members once they have CraftETA, and players advertising in trade chat as they post.", cfNoMatch = "Nobody matches. Press Enter to ask your guild too.", cfFoot = "Green: online. Yellow: advertised in trade chat lately. Enter asks your guild.", vendTag = "· vendor", vendHead = "Sold by vendors", vendLast = "Last seen at %s, %s", vendBuy = "CraftETA: buy %d for the list (%s)", vendBuyTip = "Buys what your shopping list still needs from this vendor.", vendOpt = "Buy vendor materials at a vendor (off: buy them on the auction house too)", rcGuide = "Your guide", rcStepNow = "Your step now: craft about %d more, up to skill %d", rcGuideNow = "Now: %s (%d-%d)", rcShow = "Show it", rcNoGuide = "Nothing from the guide here", rcUps = "Skill-ups", rcColor0 = "Always a skill-up", rcColor1 = "Sometimes a skill-up", rcColor2 = "Rarely a skill-up", rcColor3 = "No skill-ups any more", rcNotLearned = "Not learned yet", rcUnknown = "Unknown", rcMats = "Materials", rcCanMake = "You can craft %d", rcCantMake = "Not enough materials for one", rcCost = "Materials %s", rcSells = "sells for %s", rcProfit = "profit %s", rcCardOpt = "Card in the profession window (guide, skill-ups, profit)", rcMastercraft = "CraftETA: Mastercraft shows its card in the profession window, so CraftETA's stays hidden. Turn Mastercraft off to see CraftETA's.", shareListOpt = "One shopping list for all my characters", addListTip = "Click: this step\nShift-click: to your next rank\nRight-click: to 300", almostCapped = "%s is almost capped", trainNow = "Train %s %s", trainWhere = "Trainer: %s", trainLevel = "you need level %d", trainBar = "Learn %s now: %s", learnRankAt = "Learn the next rank (level %d): %s", levelWith = "Level %s: %s",
    specReady = "You can become a %s", repair = "Repair your gear", duraLeft = "%d%% durability left", bagsFull = "Your bags are almost full",
    bagsLeft = "%d free slots", cdReadyShort = "%s is ready", cdUse = "Use it before you log off", dragRotate = "Drag to rotate  ·  wheel to zoom",
    levelLine = "Level %d %s %s", experience = "Experience", rested = "rested", maxLevel = "Max level", gold = "Gold",
    durability = "Durability", bagSpace = "Bag space", timePlayed = "Time played", bagsFree = "%d / %d free",
    noProfs = "No professions yet", nextSteps = "Next steps", allGood = "Nothing to do right now", account = "Your account",
    accountLine = "%d characters  ·  %s  ·  %s played", online = "online", altFoot = "Played %s  ·  seen %s  ·  bags %s",
    now = "now", minAgo = "%d min ago", hAgo = "%d h ago", dAgo = "%d days ago", learned = "Learned", canLearn = "You can take it",
    needs = "Level %d, skill %d", startAt = "Start:", oneSpec = "You can only have one specialization per profession (the Weaponsmith masters count on their own).",
    specFoot = "Hover a specialization for where to start it.", notYours = "not yours", skillOk = "%d  ok", skillNeed = "needs %d", skill = "Skill",
    campFoot = "A campfire holds 3, 5 or 10 items. Sit by it a minute for Camp Benefits (1 hour). From WoW-Professions.com.",
    ready = "Ready", cdFoot = "CraftETA tells you in chat when a cooldown is ready.", noCd = "None of your characters has a profession cooldown yet.",
    smeltFrom = "Smelt it from %s Ore.", skinBeasts = "Skinning: skin beasts", cloth = "Cloth", rightTrack = "Right-click: track it in the item tracker",
    matsFoot = "Hover a material for where it comes from.", cdAlertOpt = "Tell me when a profession cooldown is ready",
    trackReminderOpt = "Remind me when Find Minerals or Find Herbs is off",
    help = "/ceta: CraftETA  ·  /ceta panel  ·  /ceta farm  ·  /ceta list  ·  /ceta config  ·  /ceta reset  ·  /ceta da|en",
  },
  da = {
    toRank = "Til %d", to300 = "Til 300", crafts = "%d crafts", left = "%d tilbage", make = "Lav %d",
    craft = "Craft", craftN = "Craft %d", craftSub = "Craft %d (materiale)", craftFirst = "Først %d %s: trinnet skal bruge dem, og du kan lave dem.", craftTip = "Crafter %d %s: det trinnet mangler, eller så mange dine tasker rækker til.", addList = "+ Indkøbsliste", addedList = "Lagt på indkøbslisten.",
    learnRank = "Lær %s nu", rankAt = "%s ved %d (level %d)", needRecipe = "Lær opskriften først",
    openWindow = "Åbn dit fagvindue for at crafte", done = "300: du er færdig!", noGuide = "Ingen guide til det fag.",
    noProf = "Åbn et fagvindue, eller lær et fag.", next = "Næste: %s", note = "Note",
    other = "Andet valg: klik på pilene", have = "har", need = "skal bruge", stepOf = "Trin %d af %d",
    list = "Indkøbsliste", empty = "Indkøbslisten er tom.", clear = "Ryd", item = "Vare", still = "Mangler",
    bought = "Købt", inMail = "I posten", est = "Overslag", total = "I alt", scan = "Scan priser", scanning = "Scanner %d/%d...",
    buy = "Køb %d %s", confirm = "Bekræft %s (%s)", next2 = "Næste", allBought = "Alt er købt. Hent det i postkassen.",
    notListed = "Ingen til salg", notCommodity = "Køb selv (ikke en samlet vare)", priceUp = "+%d%% over overslaget",
    boughtMsg = "Købte %d %s for %s.", failed = "Købet fejlede, prøv igen.", scanHint = "Måske er der færre til salg: Scan priser viser hvor mange.", auctionator = "Til Auctionator",
    auctionatorDone = "Indkøbslisten \"CraftETA\" er lavet i Auctionator.", searchAux = "Klik: søg i %s",
    settings = "Indstillinger", panelOpt = "Panel ved siden af fagvinduet", ahOpt = "Købsguide i auktionshuset",
    autoOpt = "Køb med det samme, når prisen er tæt på overslaget", autoScanOpt = "Tjek dagens priser, når auktionshuset åbner", guardOpt = "Spørg først over overslaget med", nextOpt = "Vis næste trin", minimapOpt = "Knap ved minimappet",
    mmLeft = "Klik: CraftETA", mmRight = "Højreklik: indkøbsliste", mmShift = "Shift-klik: indstillinger", mmDrag = "Træk: flyt knappen",
    lang = "Sprog", stepMode = "Dette trin", rankMode = "Til næste rank", allMode = "Til 300", addWhat = "Læg på listen:",
    eta = "~%s", perHour = "%d skill/time", unknownPrice = "ingen pris", vendor = "vendor", source = "Rute: %s",
    anyOne = "Én af dem er nok", t_guide = "Fag", t_recipes = "Opskrifter", t_profit = "Profit", t_crafters = "Craftere", t_chars = "Karakterer", t_list = "Indkøbsliste", t_settings = "Indstillinger",
    more = "+%d mere (scroll)", f_all = "Alle", f_learned = "Lært", f_missing = "Ikke lært",
    noBook = "Åbn dine fagvinduer én gang, så CraftETA kan læse dine opskrifter.", notLearned = "Ikke lært endnu",
    ttMade = "Laves af", ttCost = "Craft-pris", ttUsed = "Bruges i", ttRecipes = "%s: %d opskrifter", recipeCount = "%d opskrifter",
    p_craft = "Craft", p_farm = "Farm", youGather = "Du kan samle det (%s)", needProf = "Kræver %s", fromMobs = "Dropper fra humanoider",
    farmFoot = "Auktionspris for én, højeste først", noPrices = "Ingen priser endnu: scan auktionshuset med %s.",
    sellsFor = "Sælges for (%d)", ahCut = "Auktionshusets andel (5%)", matsCost = "Materialer", profit = "Profit",
    profitFoot = "Opskrifter dine karakterer kan, bedste først. Priser fra %s.", noProfit = "Ingen priser endnu, eller ingen opskrifter læst: åbn dine fagvinduer og scan auktionshuset.",
    search = "Søg", searchHint = "Opskrift, fx Mithril", yours = "din", clickWhisper = "Klik: whisper",
    craftersFoot = "Dine karakterer svarer med det samme, guild-medlemmer med CraftETA om lidt.", asking = "Spørger din guild...",
    noneFound = "Ingen fundet.", noneFoundHelp = "Ingen fundet. Kun guild-medlemmer med CraftETA svarer, så trade chat bliver også læst: prøv igen når folk reklamerer.", adTrade = "trade chat", adAgo = "trade chat, for %d min siden", chatAds = "Læs trade chat for crafters", guildAnswers = "Svar fra guilden kommer de næste par sekunder.",
    lvl = "level %d", rightRemove = "Højreklik: fjern denne karakter", charsFoot = "%d karakterer · %s i alt",
    notKnown = "Du har ikke %s.", learnAt = "Lær næste rank ved %d (level %d): %s", where = "Hvor:",
    tooltipOpt = "CraftETA-linjer i item-tooltips", guildShareOpt = "Svar når guild-medlemmer søger craftere",
    guildAskOpt = "Spørg min guild når jeg søger craftere", hub = "CraftETA",
    wholeRoute = "1-300", farmStart = "Start farming", farmStop = "Stop farming", farmReset = "Ny runde", farmTotal = "Værdi %s", farmMoney = "%s i mønter", farmVendor = "(noget til vendorpris)", farmWaiting = "Loot noget: det kommer her.", farmHint = "Tryk Start farming, og saml eller dræb.", craftNow = "Craft nu", openFromBook = "Åbn dit fag fra spellbook for at crafte.", ahAddon = "Auktionshus-addon: %s", noAhAddon = "ingen fundet (CraftETA scanner selv)", allProfs = "Alle fag", myProfs = "Mine fag", learnNow = "Lær %s nu (level %d): %s", learnAt2 = "Lær %s ved %d (level %d): %s", stepSkip = "Spring dette trin over", stepBack = "Tilbage til trinnet din skill er på", skippedAhead = "sprunget frem", steps = "%d trin", yourCap = "%d = dit loft", t_home = "Hjem", t_alts = "Alts", t_specs = "Specialiseringer", t_gold = "Guld", t_codex = "Codex", t_camping = "Camping", t_cooldowns = "Cooldowns",
    c_recipes = "Opskrifter", c_materials = "Materialer", lvlClass = "Level %d %s", tracker = "Item tracker",
    cdReady = "%s er klar på %s.", trackOff = "%s er slået fra", trackHint = "slå det til for at se det på dit minimap.", turnOn = "Slå til",
    trackerHint = "Musehjul: skift målet. Højreklik: stop med at følge.", trackerEmpty = "Højreklik et materiale i Codex eller Guld for at følge det.",
    cfHead = "Crafters", cfCount = "%d online · %d i alt", cfSearch = "Søg efter spiller, item eller opskrift...", cfWhisper = "Whisper", cfInvite = "Inviter", cfMine = "din karakter", cfGuild = "guild", cfTrade = "trade chat", cfOffline = "offline", cfSeen = "for %s siden", cfCrafter = "Crafter", cfPick = "Klik på en crafter for at se fag, opskrifter og reklame.", cfProfs = "Fag", cfAdvert = "Reklame", cfRecipes = "Opskrifter", cfNoRecipes = "Ikke kendt endnu. Søg på et item og tryk Enter for at spørge din guild.", cfMore = "%d til %d af %d, scroll for flere", cfNone = "Ingen endnu. Dine karakterer kommer, når du har åbnet et profession vindue, guildmedlemmer når de har CraftETA, og folk der reklamerer i trade chat, når de skriver.", cfNoMatch = "Ingen passer. Tryk Enter for også at spørge din guild.", cfFoot = "Grøn: online. Gul: har reklameret i trade chat for nylig. Enter spørger din guild.", vendTag = "· vendor", vendHead = "Sælges af vendors", vendLast = "Sidst set hos %s, %s", vendBuy = "CraftETA: køb %d til listen (%s)", vendBuyTip = "Køber det, din indkøbsliste mangler, hos denne vendor.", vendOpt = "Køb vendor materialer hos en vendor (fra: køb dem også på AH)", rcGuide = "Din guide", rcStepNow = "Dit trin nu: lav ca. %d mere, op til skill %d", rcGuideNow = "Nu: %s (%d til %d)", rcShow = "Vis den", rcNoGuide = "Intet fra guiden her", rcUps = "Skill-ups", rcColor0 = "Altid et skill-up", rcColor1 = "Nogle gange et skill-up", rcColor2 = "Sjældent et skill-up", rcColor3 = "Ingen skill-ups mere", rcNotLearned = "Ikke lært endnu", rcUnknown = "Ukendt", rcMats = "Materialer", rcCanMake = "Du kan lave %d", rcCantMake = "Ikke nok materialer til én", rcCost = "Materialer %s", rcSells = "sælges for %s", rcProfit = "profit %s", rcCardOpt = "Kort i profession vinduet (guide, skill-ups, profit)", rcMastercraft = "CraftETA: Mastercraft viser sit kort i profession vinduet, så CraftETA's er skjult. Slå Mastercraft fra for at se CraftETA's.", shareListOpt = "Én indkøbsliste for alle mine karakterer", addListTip = "Klik: dette trin\nShift-klik: til næste rank\nHøjreklik: til 300", almostCapped = "%s er næsten på loftet", trainNow = "Træn %s %s", trainWhere = "Træner: %s", trainLevel = "du skal være level %d", trainBar = "Lær %s nu: %s", learnRankAt = "Lær næste rank (level %d): %s", levelWith = "Level %s: %s",
    specReady = "Du kan blive %s", repair = "Reparer dit udstyr", duraLeft = "%d%% holdbarhed tilbage", bagsFull = "Dine tasker er næsten fulde",
    bagsLeft = "%d ledige pladser", cdReadyShort = "%s er klar", cdUse = "Brug den før du logger af", dragRotate = "Træk for at dreje  ·  hjul for zoom",
    levelLine = "Level %d %s %s", experience = "Erfaring", rested = "rested", maxLevel = "Max level", gold = "Guld",
    durability = "Holdbarhed", bagSpace = "Taskeplads", timePlayed = "Spilletid", bagsFree = "%d / %d ledige",
    noProfs = "Ingen fag endnu", nextSteps = "Næste skridt", allGood = "Intet at gøre lige nu", account = "Din konto",
    accountLine = "%d karakterer  ·  %s  ·  %s spillet", online = "online", altFoot = "Spillet %s  ·  set %s  ·  tasker %s",
    now = "nu", minAgo = "for %d min siden", hAgo = "for %d t siden", dAgo = "for %d dage siden", learned = "Lært", canLearn = "Du kan tage den",
    needs = "Level %d, skill %d", startAt = "Start:", oneSpec = "Du kan kun have én specialisering per fag (Weaponsmith-mestrene tæller for sig).",
    specFoot = "Hold musen over en specialisering for at se hvor den starter.", notYours = "ikke dit fag", skillOk = "%d  ok", skillNeed = "kræver %d", skill = "Skill",
    campFoot = "Et bål har plads til 3, 5 eller 10 ting. Sid ved det et minut for Camp Benefits (1 time). Fra WoW-Professions.com.",
    ready = "Klar", cdFoot = "CraftETA siger til i chatten, når en cooldown er klar.", noCd = "Ingen af dine karakterer har en fag-cooldown endnu.",
    smeltFrom = "Smelt den af %s Ore.", skinBeasts = "Skinning: flå dyr", cloth = "Stof", rightTrack = "Højreklik: følg den i item trackeren",
    matsFoot = "Hold musen over et materiale for at se hvor det kommer fra.", cdAlertOpt = "Sig til når en fag-cooldown er klar",
    trackReminderOpt = "Mind mig om det når Find Minerals eller Find Herbs er slået fra",
    help = "/ceta: CraftETA  ·  /ceta panel  ·  /ceta farm  ·  /ceta list  ·  /ceta config  ·  /ceta reset  ·  /ceta da|en",
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

-- an item's icon: from its ID, else from a recipe of that name in your recipe books, else the fallback
function ns.ItemIcon(name, fallback)
  local id = ns.ItemID(name)
  if id and GetItemInfoInstant then
    local ok, _, _, _, _, icon = pcall(GetItemInfoInstant, id)
    if ok and icon then return icon end
  end
  if ns.db and ns.db.chars and name then
    for _, c in pairs(ns.db.chars) do
      for _, book in pairs(c.book or {}) do
        for _, r in pairs(book) do
          if r.n == name and r.i then return r.i end
        end
      end
    end
  end
  return fallback or 134400 -- the question mark icon
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
-- which auction house addon you have: "aux", "Auctionator", both ("aux + Auctionator") or nil
local function Loaded(name)
  local f = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
  if not f then return false end
  local ok, loaded = pcall(f, name)
  return ok and loaded and true or false
end
function ns.HasAux() return _G.AuxForeverAPI ~= nil or Loaded("auxForever") or Loaded("aux-addon") end
function ns.HasAuctionator() return (_G.Auctionator and Auctionator.API and Auctionator.API.v1) ~= nil or Loaded("Auctionator") end
function ns.AHAddon()
  local aux, atr = ns.HasAux(), ns.HasAuctionator()
  if aux and atr then return "aux + Auctionator" end
  return (aux and "aux") or (atr and "Auctionator") or nil
end
-- the addon prices and searches go to: aux when you have it, else Auctionator
function ns.AHName()
  return ns.HasAux() and "aux" or (ns.HasAuctionator() and "Auctionator") or "CraftETA"
end

-- a price by item ID: aux first, then Auctionator, then CraftETA's own scan (by name)
function ns.PriceID(id, name)
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
  local scanned = name and ns.db and ns.db.scanned and ns.db.scanned[name]
  if scanned and scanned.unit then return scanned.unit end
  return nil
end

function ns.Price(name)
  return ns.PriceID(ns.ItemID(name), name)
end

-- what a vendor pays for one
function ns.VendorPrice(id)
  if not id then return nil end
  local ok, _, _, _, _, _, _, _, _, _, _, sell = pcall(GetItemInfo, id)
  if ok and type(sell) == "number" and sell > 0 then return sell end
  return nil
end

---------------------------------------------------------------------------
-- Skills
---------------------------------------------------------------------------
-- skill line ID -> { rank, max }, from the skills list (and the open profession window)
-- all = true: gathering professions too
function ns.Skills(all)
  local found = {}
  local function known(id) return ns.GUIDES[id] or (all and ns.GATHER[id]) end
  local function add(id, rank, max)
    id, rank, max = ns.Plain(id), ns.Plain(rank), ns.Plain(max)
    if type(id) == "number" and known(id) and type(rank) == "number" then
      found[id] = { rank = rank, max = type(max) == "number" and max or 300 }
    end
  end
  if C_SkillInfo and C_SkillInfo.GetSkillLineInfoByID then
    for _, list in ipairs({ ns.GUIDES, all and ns.GATHER or {} }) do
      for id in pairs(list) do
        local ok, info = pcall(C_SkillInfo.GetSkillLineInfoByID, id)
        if ok and type(info) == "table" then add(id, info.rank, info.maxRank) end
      end
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
      local id = not header and (ns.SKILL_BY_NAME[name] or (all and ns.GATHER_BY_NAME[name]))
      if id then add(id, rank, max) end
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
ns.Share = Share

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
  local guide = ns.GUIDES[profID] or (ns.GATHER and ns.GATHER[profID])
  if not guide then return nil end
  for _, r in ipairs(guide.ranks) do
    if max <= r.at then
      return r
    end
  end
  return nil
end

-- the rank you can go and learn right now, with its name and where: r, "Expert", "Doctor Herbert Halsey, Undercity"
local RANK_AT = { [75] = "Journeyman", [150] = "Expert", [225] = "Artisan" }
function ns.TrainNow(profID, rank, max)
  if not rank or not max or max >= 300 then return nil end
  local r = ns.NextRank(profID, rank, max)
  if not r or rank < r.need then return nil end
  return r, RANK_AT[r.at] or "", r[ns.Faction()] or ""
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

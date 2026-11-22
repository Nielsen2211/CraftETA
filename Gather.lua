-- CraftETA: gathering routes 1-300 for WoW Forever (Mining, Herbalism, Skinning, Fishing).
-- Routes from WoW-Professions.com (https://www.wow-professions.com/forever), used with permission.
--
-- One step: { from, to, what = "what to gather", a = "Alliance zones", h = "Horde zones", note = "..." }
-- ranks: { at = skill you can't pass without it, need = skill to learn it, lvl = level, h = Horde, a = Alliance }
local _, ns = ...

ns.GATHER = {
  -- Mining
  [186] = {
    name = "Mining", icon = "Interface\\Icons\\Trade_Mining",
    ranks = {
      { at = 75, need = 50, lvl = 10, h = "Makaru (Orgrimmar), Krunn (Razor Hill)", a = "Gelman Stonehand (Stormwind), Geofram Bouldertoe (Ironforge)" },
      { at = 150, need = 125, lvl = 20, h = "Makaru (Orgrimmar), Brom Killian (Undercity)", a = "Gelman Stonehand (Stormwind), Geofram Bouldertoe (Ironforge)" },
      { at = 225, need = 200, lvl = 35, h = "Makaru (Orgrimmar), Brom Killian (Undercity)", a = "Gelman Stonehand (Stormwind), Geofram Bouldertoe (Ironforge)" },
    },
    steps = {
      { 1, 65, what = "Copper Ore", a = "Elwynn Forest, Dun Morogh, Teldrassil, Zephras Isle", h = "Durotar, Mulgore, Tirisfal Glades, Zephras Isle",
        note = "Smelt Copper as you go (120-140 times) and keep 70 Copper Bars for Bronze. Durotar's cave respawns fast." },
      { 65, 125, what = "Tin Ore, Copper Ore, Silver Ore (75)", a = "Wetlands (best), Westfall, Hillsbrad Foothills, The Barrens", h = "Silverpine Forest (cave), Hillsbrad Foothills, The Barrens, Stonetalon Mountains",
        note = "Learn Smelt Tin and Smelt Bronze at 65. Smelt 70 Bronze from 75 to 105, then Smelt Silver at 105." },
      { 125, 175, what = "Iron Ore, Gold Ore (155), Tin Ore", a = "Thousand Needles (safest), Arathi Highlands, Desolace", h = "Thousand Needles (safest), Arathi Highlands, Desolace",
        note = "Learn Smelt Gold at 155: about 22 Gold Ore takes you to 175. Low level: skip the four Arathi caves." },
      { 175, 245, what = "Mithril Ore, Truesilver Ore (230)", a = "The Hinterlands, Tanaris", h = "The Hinterlands, Tanaris",
        note = "Learn Artisan at 200. Below 60, skip the four Tanaris caves and the elite area in The Hinterlands." },
      { 245, 275, what = "Small Thorium Veins, Mithril, Truesilver", a = "Un'Goro Crater, Blasted Lands, Felwood", h = "Un'Goro Crater, Blasted Lands, Felwood",
        note = "In Felwood, skip Shadow Hold and the Jaedenar cave." },
      { 275, 300, what = "Rich Thorium (275), Small Thorium, Mithril", a = "Un'Goro Crater, Eastern Plaguelands, Burning Steppes", h = "Un'Goro Crater, Eastern Plaguelands, Burning Steppes",
        note = "Winterspring's gorge has many elites. In Burning Steppes, the two caves have level 50 mobs." },
    },
  },
  -- Herbalism
  [182] = {
    name = "Herbalism", icon = "Interface\\Icons\\Trade_Herbalism",
    ranks = {
      { at = 75, need = 50, lvl = 10, h = "Jandi (Orgrimmar), Mishiki (Sen'jin Village), Faruza (Brill)", a = "Tannysa (Stormwind), Herbalist Pomeroy (Elwynn), Malorne Bladeleaf (Dolanaar)" },
      { at = 150, need = 125, lvl = 20, h = "Jandi (Orgrimmar), Martha Alliestar (Undercity), Komin Winterhoof (Thunder Bluff)", a = "Tannysa (Stormwind), Reyna Stonebranch (Ironforge), Firodren Mooncaller (Darnassus)" },
      { at = 225, need = 200, lvl = 35, h = "Jandi (Orgrimmar), Martha Alliestar (Undercity), Komin Winterhoof (Thunder Bluff). None in Tanaris or Searing Gorge", a = "Tannysa (Stormwind), Reyna Stonebranch (Ironforge), Firodren Mooncaller (Darnassus). None in Tanaris or Searing Gorge" },
    },
    steps = {
      { 1, 70, what = "Peacebloom, Silverleaf, Earthroot (15)", a = "Elwynn Forest, Dun Morogh, Teldrassil, Zephras Isle", h = "Durotar, Mulgore, Tirisfal Glades, Zephras Isle",
        note = "Starting zones are full of herbs and respawn fast." },
      { 70, 115, what = "Mageroyal, Briarthorn, Stranglekelp (85)", a = "Darkshore, Loch Modan", h = "Silverpine Forest",
        note = "Darkshore and Silverpine respawn fast, so small loops work." },
      { 115, 170, what = "Bruiseweed, Wild Steelbloom, Kingsblood (125), Liferoot (150)", a = "Hillsbrad Foothills, Stonetalon Mountains", h = "Hillsbrad Foothills, Stonetalon Mountains",
        note = "Learn Expert at 125." },
      { 170, 205, what = "Kingsblood, Liferoot, Fadeleaf, Goldthorn, Khadgar's Whisker (185)", a = "Stranglethorn Vale, Arathi Highlands", h = "Stranglethorn Vale, Arathi Highlands" },
      { 205, 230, what = "Purple Lotus, Firebloom", a = "Tanaris, Searing Gorge", h = "Tanaris, Searing Gorge",
        note = "Learn Artisan at 200 before you go: there is no trainer in these zones." },
      { 230, 270, what = "Sungrass, Purple Lotus, Golden Sansam, Ghost Mushroom (245)", a = "The Hinterlands", h = "The Hinterlands",
        note = "Ghost Mushrooms grow in a cave and need 245." },
      { 270, 300, what = "Sungrass, Gromsblood, Golden Sansam, Dreamfoil, Mountain Silversage, Plaguebloom", a = "Felwood", h = "Felwood" },
    },
  },
  -- Skinning
  [393] = {
    name = "Skinning", icon = "Interface\\Icons\\INV_Misc_Pelt_Wolf_01",
    ranks = {
      { at = 75, need = 50, lvl = 10, h = "Thuwd (Orgrimmar), Yonn Deepcut (Bloodhoof Village)", a = "Maris Granger (Stormwind), Helene Peltskinner (Goldshire)" },
      { at = 150, need = 125, lvl = 20, h = "Thuwd (Orgrimmar), Killian Sanatha (Undercity), Mooranta (Thunder Bluff)", a = "Maris Granger (Stormwind), Balthus Stoneflayer (Ironforge), Radnaal Maneweaver (Darnassus)" },
      { at = 225, need = 200, lvl = 35, h = "Thuwd (Orgrimmar), Killian Sanatha (Undercity), Mooranta (Thunder Bluff)", a = "Maris Granger (Stormwind), Balthus Stoneflayer (Ironforge), Radnaal Maneweaver (Darnassus)" },
    },
    steps = {
      { 1, 75, what = "Level 1-10 beasts", a = "Northshire Valley: Young and Timber Wolves", h = "Valley of Trials: Mottled Boars",
        note = "Any starting zone works. Keep a Skinning Knife in your bags." },
      { 75, 130, what = "Elder Mountain Boar, Black Bear Patriarch, Loch Crocolisk (16-17)", a = "Loch Modan", h = "Loch Modan",
        note = "Or The Barrens: the raptor camp west of Northwatch Hold, level 16-18, all the way to 150." },
      { 130, 150, what = "Mottled Scytheclaw, Mottled Razormaw (25-27)", a = "Whelgar's Excavation Site, Wetlands", h = "Whelgar's Excavation Site, Wetlands" },
      { 150, 160, what = "Vicious Gray Bear, Starving Mountain Lion (22-24)", a = "Outside Foothill Caverns, Hillsbrad (from Southshore)", h = "Outside Foothill Caverns, Hillsbrad (from Tarren Mill)",
        note = "Or Duskwood: Nightbane worgen at Roland's Doom and the Rotting Orchard (26-29), all the way to 225." },
      { 160, 225, what = "Cave Yeti, Ferocious Yeti (30-32)", a = "Foothill Caverns, Hillsbrad Foothills", h = "Foothill Caverns, Hillsbrad Foothills",
        note = "The yetis respawn fast, so you can stay inside the cave." },
      { 225, 280, what = "Feral Scar Yetis (43-46)", a = "Feral Scar Vale cave, Feralas (from Feathermoon)", h = "Feral Scar Vale cave, Feralas (from Camp Mojache)",
        note = "Learn Artisan at 200 first." },
      { 280, 300, what = "Diemetradon, Pterrordax (50-55)", a = "Western Un'Goro Crater", h = "Western Un'Goro Crater" },
    },
  },
  -- Fishing
  [356] = {
    name = "Fishing", icon = "Interface\\Icons\\Trade_Fishing",
    ranks = {
      { at = 75, need = 50, lvl = 10, h = "Lumak (Orgrimmar), Armand Cromwell (Undercity), Kah Mistrunner (Thunder Bluff)", a = "Arnold Leland (Stormwind), Grimnur Stonebrand (Ironforge), Astaia (Darnassus)" },
      { at = 150, need = 125, lvl = 20, h = "Book from Old Man Heming, Booty Bay (or the AH)", a = "Book from Old Man Heming, Booty Bay (or the AH)" },
      { at = 225, need = 225, lvl = 35, h = "Quest: Nat Pagle, Angler Extreme (Dustwallow Marsh)", a = "Quest: Nat Pagle, Angler Extreme (Dustwallow Marsh)" },
    },
    steps = {
      { 1, 75, what = "Any water", a = "Elwynn Forest, Dun Morogh, Teldrassil, Zephras Isle", h = "Durotar, Mulgore, Tirisfal Glades, Zephras Isle",
        note = "Use a Shiny Bauble." },
      { 75, 150, what = "Any water", a = "Stormwind, Ironforge, Darnassus, Loch Modan, Westfall, Darkshore", h = "Orgrimmar, Undercity, Thunder Bluff, The Barrens, Silverpine Forest",
        note = "Use Nightcrawlers if fish escape." },
      { 150, 225, what = "Any water", a = "Dustwallow Marsh (best), Arathi Highlands, Stranglethorn Vale, Desolace", h = "Dustwallow Marsh (best), Arathi Highlands, Stranglethorn Vale, Desolace",
        note = "Use Bright Baubles. At 225, take Nat Pagle's quest: one fish each from Stranglethorn, Desolace, Swamp of Sorrows and Feralas." },
      { 225, 300, what = "Any water", a = "Felwood, Feralas, The Hinterlands, Tanaris, Un'Goro Crater, Western Plaguelands", h = "Felwood, Feralas, The Hinterlands, Tanaris, Un'Goro Crater, Western Plaguelands",
        note = "Bright Baubles are needed here." },
    },
  },
}

ns.GATHER_BY_NAME = {}
for id, guide in pairs(ns.GATHER) do
  ns.GATHER_BY_NAME[guide.name] = id
end

-- raw materials with their item IDs, so prices work before the item has been seen
-- prof: which gathering profession brings it (nil: cloth, from mobs)
ns.MATERIALS = {
  { "Copper Ore", 2770, 186 }, { "Tin Ore", 2771, 186 }, { "Iron Ore", 2772, 186 }, { "Silver Ore", 2775, 186 },
  { "Gold Ore", 2776, 186 }, { "Mithril Ore", 3858, 186 }, { "Truesilver Ore", 7911, 186 }, { "Thorium Ore", 10620, 186 },
  { "Rough Stone", 2835, 186 }, { "Coarse Stone", 2836, 186 }, { "Heavy Stone", 2838, 186 }, { "Solid Stone", 7912, 186 },
  { "Dense Stone", 12365, 186 },
  { "Copper Bar", 2840, 186 }, { "Tin Bar", 3576, 186 }, { "Bronze Bar", 2841, 186 }, { "Iron Bar", 3575, 186 },
  { "Silver Bar", 2842, 186 }, { "Gold Bar", 3577, 186 }, { "Steel Bar", 3859, 186 }, { "Mithril Bar", 3860, 186 },
  { "Truesilver Bar", 6037, 186 }, { "Thorium Bar", 12359, 186 },
  { "Peacebloom", 2447, 182 }, { "Silverleaf", 765, 182 }, { "Earthroot", 2449, 182 }, { "Mageroyal", 785, 182 },
  { "Briarthorn", 2450, 182 }, { "Swiftthistle", 2452, 182 }, { "Stranglekelp", 3820, 182 }, { "Bruiseweed", 2453, 182 },
  { "Wild Steelbloom", 3355, 182 }, { "Grave Moss", 3369, 182 }, { "Kingsblood", 3356, 182 }, { "Liferoot", 3357, 182 },
  { "Fadeleaf", 3818, 182 }, { "Goldthorn", 3821, 182 }, { "Khadgar's Whisker", 3358, 182 }, { "Wintersbite", 3819, 182 },
  { "Firebloom", 4625, 182 }, { "Purple Lotus", 8831, 182 }, { "Arthas' Tears", 8836, 182 }, { "Sungrass", 8838, 182 },
  { "Blindweed", 8839, 182 }, { "Ghost Mushroom", 8845, 182 }, { "Gromsblood", 8846, 182 }, { "Golden Sansam", 13464, 182 },
  { "Dreamfoil", 13463, 182 }, { "Mountain Silversage", 13465, 182 }, { "Plaguebloom", 13466, 182 }, { "Icecap", 13467, 182 },
  { "Black Lotus", 13468, 182 },
  { "Ruined Leather Scraps", 2934, 393 }, { "Light Leather", 2318, 393 }, { "Medium Leather", 2319, 393 },
  { "Heavy Leather", 4234, 393 }, { "Thick Leather", 4304, 393 }, { "Rugged Leather", 8170, 393 },
  { "Light Hide", 783, 393 }, { "Medium Hide", 4232, 393 }, { "Heavy Hide", 4235, 393 }, { "Thick Hide", 8169, 393 },
  { "Rugged Hide", 8171, 393 },
  { "Linen Cloth", 2589 }, { "Wool Cloth", 2592 }, { "Silk Cloth", 4306 }, { "Mageweave Cloth", 4338 }, { "Runecloth", 14047 },
}

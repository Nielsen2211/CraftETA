-- CraftETA: camp items and profession specializations for WoW Forever.
-- Camp items from WoW-Professions.com (https://www.wow-professions.com/forever/camping-guide), used with permission.
-- One camp item: { skill, name, effect, materials, how to get }
local _, ns = ...

local TRAINER = "Trainer or the quest Camping 101"

ns.CAMP = {
  [171] = {
    { 20, "Mana Well", "Mana regeneration", "1 Peacebloom, 1 Empty Vial", TRAINER },
    { 140, "Fermenter", "Needed for some Alchemy recipes", "1 Leaded Vial, 1 Kingsblood, 1 Swiftthistle", "Blueprint: Rath'mael, Ruins of Lordaeron" },
    { 300, "Alchemy Laboratory", "Needed for some Alchemy recipes", "1 Lich's Index Finger, 1 Crystal Vial, 2 Dreamfoil", "Blueprint: Ras Frostwhisper, Scholomance" },
  },
  [164] = {
    { 20, "Sharpening Wheel", "Strength", "1 Rough Stone, 1 Copper Bar", TRAINER },
    { 140, "Anvil", "An anvil for crafting", "5 Bronze Bar, 2 Coarse Grinding Stone, 2 Medium Leather", "Blueprint: Gilnid, The Deadmines" },
    { 300, "Master Forge", "Needed for many Blacksmithing recipes", "1 Golem Heart, 5 Thorium Bar, 2 Rugged Leather", "Blueprint: Golem Lord Argelmach, Blackrock Depths" },
  },
  [333] = {
    { 20, "Enchanted Lute", "Armor, stats and resistances", "1 Simple Wood, 1 Strange Dust", TRAINER },
    { 140, "Arcane Salvager", "Better disenchanting", "2 Vision Dust, 1 Lesser Nether Essence", "Blueprint: Shade of the Archmage, City of Dalaran" },
    { 300, "Arcane Forge", "Needed for some Enchanting recipes", "1 Maker's Spark, 2 Large Brilliant Shard, 4 Greater Eternal Essence", "Blueprint: Nanaya, Kalimdor" },
  },
  [202] = {
    { 20, "Reagent Bot", "A vendor for reagents and profession supplies", "1 Handful of Copper Bolts, 1 Copper Tube", TRAINER },
    { 140, "Repair Bot", "Repairs for everyone at the camp", "2 Whirring Bronze Gizmo, 1 Bronze Tube, 1 Heavy Leather", "Blueprint: Sneed, The Deadmines" },
    { 300, "Anarchist's Workbench", "Needed for some Engineering recipes", "1 Essence of Anarchy, 2 Thorium Widget", "Blueprint: Ezra Grimm, Stratholme" },
  },
  [165] = {
    { 20, "Camp Tent", "Rested XP, up to 5% of a level once an hour", "5 Light Leather", TRAINER },
    { 125, "Tanning Rack", "Needed for many Leatherworking recipes", "5 Medium Leather, 3 Fine Thread, 2 Simple Wood", "Blueprint: Razorclaw the Butcher, Shadowfang Keep" },
    { 300, "Sewing Machine", "Needed for many Leatherworking recipes", "1 Undeath Engine, 5 Rugged Leather, 1 Rune Thread", "Blueprint: Vectus, Scholomance" },
  },
  [197] = {
    { 20, "Faction Banner", "Spirit for your faction", "1 Bolt of Linen Cloth, 1 Coarse Thread", TRAINER },
    { 140, "Spinning Wheel", "Needed for many Tailoring recipes", "2 Simple Wood, 5 Bolt of Silk Cloth, 3 Fine Thread", "Blueprint: Unstable Sentinel, City of Dalaran" },
    { 300, "Loom", "Needed for many Tailoring recipes", "1 Bottled Screams, 4 Bolt of Runecloth, 4 Simple Wood", "Blueprint: Baroness Anastari, Stratholme" },
  },
  [182] = {
    { 20, "Incense Candle", "Intellect", "1 Peacebloom, 1 Silverleaf", TRAINER },
    { 140, "Greenhouse", "Grows herbs from seeds you plant", "2 Simple Wood, 1 Arthas' Tears, 1 Purple Lotus", "Blueprint: Shadetooth, Excavation Site (Wetlands)" },
    { 300, "Seed Hybridizer", "Multiplies seeds or combines them into rarer ones", "4 Mountain Silversage, 1 Crystal Vial, 2 Runecloth", "Blueprint source not known yet" },
  },
  [186] = {
    { 20, "Lodestone", "Melee attack power", "1 Rough Stone, 1 Copper Bar", TRAINER },
    { 140, "Rock Garden", "Spawns a mining node over time", "2 Heavy Stone, 1 Iron Ore, 1 Silver Bar", "Blueprint: Relic Guardian, Excavation Site (Wetlands)" },
    { 300, "Molten Foundry", "Needed for Smelt Heavy Thorium", "5 Thorium Bar, 2 Dense Stone, 1 Truesilver Bar", "Blueprint: Ambassador Flamelash, Blackrock Depths" },
  },
  [393] = {
    { 20, "Camp Chair", "+2% critical strike", "3 Light Leather, 2 Simple Wood", TRAINER },
    { 140, "Field Guide", "Anyone can read it to learn Track Beasts", "3 Medium Leather, 2 Slimy Murloc Scale, 1 Fine Thread", "Blueprint: Lady Anacondra, Wailing Caverns" },
    { 300, "Trapper's Workbench", "A workbench with a trap", "2 Simple Wood, 4 Heavy Leather, 1 Iron Bar", "Blueprint: The Beast (UBRS) or Houndmaster Loksey (Scarlet Monastery)" },
  },
  [185] = {
    { 1, "Basic Campfire", "The campfire itself, from a Basic Campfire Kit", "Basic Campfire Kit", "Cooking teaches it at skill 1" },
    { 140, "Cookie's Feast", "Stamina food for everyone at the camp", "2 Mystery Meat, 1 Heavy Kodo Meat, 1 Soothing Spices", "Blueprint: Cookie, The Deadmines" },
    { 300, "Iron Oven", "Needed for the best Cooking recipes", "10 Simple Flour, 5 Refreshing Spring Water, 4 Soothing Spices", "Blueprint: Quartermaster Zigris, Lower Blackrock Spire" },
  },
  [129] = {
    { 20, "First Aid Kit", "Stamina", "3 Linen Bandage, 1 Refreshing Spring Water", TRAINER },
    { 140, "Toxin Study", "Healing potions and anti-venom", "1 Anti-Venom, 2 Mageweave Bandage, 2 Simple Wood", "Blueprint: Commander Springvale, Shadowfang Keep" },
    { 300, "Plague Doctor's Laboratory", "Healing potions and poultices", "2 Simple Wood, 2 Strong Anti-Venom, 5 Heavy Runecloth Bandage", "Blueprint: Doctor Theolen Krastinov, Scholomance" },
  },
  [356] = {
    { 20, "Fish Bowl", "+8% all stats", "1 Raw Brilliant Smallfish, 1 Empty Vial", TRAINER },
    { 140, "Fishing Rack", "Uncommon fish for an hour, plus lures", "2 Simple Wood, 1 Crystal Vial, 2 Raw Mithril Head Trout", "Blueprint: Gelihast, Blackfathom Deeps" },
    { 300, "Fishing Hut", "Rare fish for an hour, plus lures", "5 Simple Wood, 2 Bolt of Runecloth, 1 Seasonal Fish Steaks", "Blueprint: Jammal'an the Prophet, Sunken Temple" },
  },
}
ns.CAMP_NOTE = "A campfire holds 3, 5 or 10 items. Sit by it for a minute for Camp Benefits (1 hour). Camp buffs don't stack with class buffs."

-- Specializations: { name, spell ID (to see if you have it), level, skill, how to start (h, a), what it gives }
ns.SPECS = {
  [164] = {
    { "Armorsmith", 9788, 40, 200, h = "Quest: The Art of the Armorsmith, Okothos Ironrager (Orgrimmar)", a = "Quest: The Art of the Armorsmith, Grumnus Steelshaper (Ironforge)",
      what = "Plate and mail armor plans" },
    { "Weaponsmith", 9787, 40, 200, h = "Quest: The Way of the Weaponsmith, Borgosh Corebender (Orgrimmar)", a = "Quest: The Way of the Weaponsmith, Ironus Coldsteel (Ironforge)",
      what = "Weapon plans, and at 250 a master path" },
    { "Master Swordsmith", 17039, 40, 250, h = "Seril Scourgebane, Everlook (Winterspring)", a = "Seril Scourgebane, Everlook (Winterspring)", what = "Sword plans (Weaponsmiths)" },
    { "Master Axesmith", 17041, 40, 250, h = "Kilram, Everlook (Winterspring)", a = "Kilram, Everlook (Winterspring)", what = "Axe plans (Weaponsmiths)" },
    { "Master Hammersmith", 17040, 40, 250, h = "Lilith the Lithe, Everlook (Winterspring)", a = "Lilith the Lithe, Everlook (Winterspring)", what = "Mace plans (Weaponsmiths)" },
  },
  [202] = {
    { "Gnomish Engineering", 20219, 30, 200, h = "Oglethorpe Obnoticus, Booty Bay", a = "Lilliam Sparkspindle, Stormwind", what = "Gadgets, Ultrasafe Transporter, World Enlarger" },
    { "Goblin Engineering", 20222, 30, 200, h = "Nixx Sprocketspring, Gadgetzan", a = "Nixx Sprocketspring, Gadgetzan", what = "Explosives, Dimensional Ripper" },
  },
  [165] = {
    { "Dragonscale Leatherworking", 10656, 40, 225, h = "Thorkaf Dragoneye, Badlands", a = "Peter Galen, Azshara", what = "Mail armor with resistances" },
    { "Elemental Leatherworking", 10658, 40, 225, h = "Brumn Winterhoof, Arathi Highlands", a = "Sarah Tanner, Searing Gorge", what = "Leather with elemental stats" },
    { "Tribal Leatherworking", 10660, 40, 225, h = "Se'Jib, Stranglethorn Vale", a = "Caryssia Moonhunter, Feralas", what = "Leather for druids and hunters" },
  },
}

-- profession cooldowns: { name, spell IDs that share it (or item = ID), icon }
ns.COOLDOWNS = {
  { "Transmute", { 17187, 11479, 11480, 17559, 17560, 17561, 17562, 17563, 17564, 17565, 17566 }, icon = "Interface\\Icons\\Trade_Alchemy" },
  { "Mooncloth", { 18560 }, icon = "Interface\\Icons\\Trade_Tailoring" },
  { "Salt Shaker", item = 15846, icon = "Interface\\Icons\\INV_Misc_Food_15" },
}

-- CraftETA: leveling routes 1-300 for WoW Forever.
-- Routes from WoW-Professions.com (https://www.wow-professions.com/forever), used with permission.
--
-- One step:  { from, to, { recipe, crafts, { material, total, material, total, ... }, yield? }, ..., any = true?, note = "..." }
--   every craft entry of a step is made in order; with any = true, one of them is enough (pick what you have)
--   totals are for the whole step. When the profession window is open, the game's own recipe decides
--   the materials, so a material that differs on your client is read from the game instead.
-- ranks: { at = skill you can't pass without it, need = skill to learn it, lvl = level, h = Horde, a = Alliance }
local _, ns = ...

ns.SOURCE = "WoW-Professions.com"
ns.SOURCE_URL = "wow-professions.com/forever"

ns.GUIDES = {
  -- Alchemy
  [171] = {
    name = "Alchemy",
    ranks = {
      { at = 75, need = 50, lvl = 10, h = "Yelmak (Orgrimmar), Doctor Marsh (Undercity), Bena Winterhoof (Thunder Bluff)", a = "Lilyssia Nightbreeze (Stormwind), Tally Berryfizz (Ironforge), Sylvanna Forestmoon (Darnassus)" },
      { at = 150, need = 125, lvl = 20, h = "Doctor Herbert Halsey, Undercity (50s)", a = "Ainethil, Darnassus (50s)" },
      { at = 225, need = 200, lvl = 35, h = "Rogvar, Stonard (Swamp of Sorrows)", a = "Kylanna Windwhisper, Feathermoon Stronghold (Feralas)" },
    },
    steps = {
      { 1, 10, { "Elixir of Minor Force", 9, { "Silverleaf", 9, "Empty Vial", 9 } }, note = "Empty Vial: Alchemy or Trade Supply vendors." },
      { 10, 55, { "Elixir of Minor Defense", 45, { "Silverleaf", 45, "Peacebloom", 45, "Empty Vial", 45 } } },
      { 55, 65, { "Minor Mana Potion", 10, { "Mageroyal", 10, "Peacebloom", 10, "Empty Vial", 10 } } },
      { 65, 90, { "Elixir of Minor Fortitude", 28, { "Earthroot", 56, "Peacebloom", 28, "Empty Vial", 28 } } },
      { 90, 120, { "Elixir of Wisdom", 30, { "Mageroyal", 30, "Briarthorn", 60, "Empty Vial", 30 } },
        note = "Keep them if you also level Tailoring (Gloves of Meditation)." },
      { 120, 130, { "Lesser Mana Potion", 10, { "Mageroyal", 10, "Stranglekelp", 10, "Empty Vial", 10 } } },
      { 130, 150, { "Fire Oil", 20, { "Firefin Snapper", 40, "Empty Vial", 20 }, 2 },
        note = "Makes 2 each. Keep 30 for Elixir of Fire Power." },
      { 150, 165, { "Elixir of Fire Power", 15, { "Fire Oil", 30, "Kingsblood", 15, "Leaded Vial", 15 } } },
      { 165, 195, { "Mana Potion", 36, { "Stranglekelp", 36, "Kingsblood", 36, "Leaded Vial", 36 } } },
      { 195, 235, { "Nature Protection Potion", 62, { "Liferoot", 62, "Stranglekelp", 62, "Leaded Vial", 62 } },
        note = "Recipe is bind on pickup: Bronk or Logannas (Feralas), Glyx Brewright (Stranglethorn), Alchemist Pestlezugg (Tanaris)." },
      { 235, 250, { "Elixir of Greater Intellect", 15, { "Blindweed", 15, "Khadgar's Whisker", 15, "Crystal Vial", 15 } } },
      { 250, 260, { "Stonescale Oil", 47, { "Stonescale Eel", 47, "Leaded Vial", 47 }, 2 },
        note = "Makes 2 each. Keep them all for 265-300. Eels too expensive? Skip this: Elixir of Greater Intellect to 265, then Superior Mana Potion to 300 (recipe: Algernon, Undercity or Ulthir, Darnassus)." },
      { 260, 265, { "Elixir of Greater Intellect", 10, { "Blindweed", 10, "Khadgar's Whisker", 10, "Crystal Vial", 10 } } },
      { 265, 300, { "Elixir of Greater Defense", 44, { "Stonescale Oil", 88, "Sungrass", 44, "Crystal Vial", 44 } },
        note = "Recipe: Kor'geld (Orgrimmar) or Soolie Berryfizz (Ironforge). Yellow from 280: make a few extra if needed." },
    },
  },

  -- Blacksmithing
  [164] = {
    name = "Blacksmithing",
    ranks = {
      { at = 75, need = 50, lvl = 10, h = "Snarl (Orgrimmar), James Van Brunt (Undercity), Karn Stonehoof (Thunder Bluff), Angus Hammerhand (Tirisfal Glades), Daeann Steelwind (Valanaar)", a = "Therum Deepforge (Stormwind), Rotgath Stonebeard (Ironforge), Daeann Steelwind (Valanaar)" },
      { at = 150, need = 125, lvl = 20, h = "Saru Steelfury, Orgrimmar (50s)", a = "Bengus Deepforge, Ironforge (50s)" },
      { at = 225, need = 200, lvl = 35, h = "Brikk Keencraft, Booty Bay", a = "Brikk Keencraft, Booty Bay" },
    },
    steps = {
      { 1, 25, { "Rough Sharpening Stone", 30, { "Rough Stone", 30 } }, note = "Buy a Blacksmith Hammer when you learn it." },
      { 25, 50, { "Rough Grinding Stone", 30, { "Rough Stone", 60 } }, note = "Keep 10 for Silver Rods at 75." },
      { 50, 75, { "Coarse Grinding Stone", 36, { "Coarse Stone", 72 } }, note = "Keep all 36 for the bracers at 95 and 112." },
      { 75, 80, { "Silver Rod", 5, { "Silver Bar", 5, "Rough Grinding Stone", 10 } }, note = "Learn Journeyman first. Silver Bar costs more than 10 Copper Bar? Make 5 Runed Copper Belt instead." },
      { 80, 95, { "Rough Bronze Leggings", 15, { "Bronze Bar", 90 } } },
      { 95, 100, { "Patterned Bronze Bracers", 5, { "Bronze Bar", 25, "Coarse Grinding Stone", 10 } } },
      { 100, 112, { "Heavy Grinding Stone", 20, { "Heavy Stone", 60 } }, note = "Keep all 20 for Golden Scale Bracers at 180." },
      { 112, 125, { "Patterned Bronze Bracers", 13, { "Bronze Bar", 65, "Coarse Grinding Stone", 26 } } },
      { 125, 140, { "Bronze Shortsword", 24, { "Bronze Bar", 120, "Weak Flux", 96, "Medium Leather", 48 } }, note = "Sells for twice as much as the bracers. You disenchant greens? Make 24 Patterned Bronze Bracers instead." },
      { 140, 175, { "Green Iron Bracers", 40, { "Iron Bar", 240, "Green Dye", 40 } }, note = "Learn Expert first: no skill-ups above 150 without it, so don't craft AFK. Green Dye: Tamar (Orgrimmar) or Bombus Finespindle (Ironforge)." },
      { 175, 180, { "Solid Grinding Stone", 8, { "Solid Stone", 32 } }, note = "Keep 6 for Heavy Mithril Axes at 210." },
      { 180, 195, { "Golden Scale Bracers", 20, { "Steel Bar", 100, "Heavy Grinding Stone", 40 } }, note = "Use your 20 Heavy Grinding Stones and make 20 more. Mining 165: smelt Steel from Iron Bar and Coal (Blacksmithing Supply)." },
      { 195, 210, { "Mithril Plate Pants", 17, { "Mithril Bar", 204 } } },
      { 210, 215, { "Heavy Mithril Axe", 6, { "Mithril Bar", 72, "Citrine", 12, "Solid Grinding Stone", 6, "Heavy Leather", 24 } } },
      { 215, 225, { "Mithril Coif", 10, { "Mithril Bar", 100, "Mageweave Cloth", 60 } }, note = "Only Brikk Keencraft (Booty Bay) teaches it. Have Plans: Mithril Spurs? 10 of those work too." },
      { 225, 235, { "Dense Sharpening Stone", 16, { "Dense Stone", 16 } } },
      { 235, 240, { "Heavy Mithril Boots", 11, { "Mithril Bar", 154, "Thick Leather", 44 } } },
      { 240, 245, { "Imperial Plate Belt", 5, { "Thorium Bar", 110, "Rugged Leather", 30, "Aquamarine", 5 } },
        note = "Quest from Derotain Mudsipper, Tanaris (level 50). Finish \"A Blue Light Bargain\" first. Bring 140 Thorium Bar for all four of his plans." },
      { 245, 270, { "Imperial Plate Bracers", 27, { "Thorium Bar", 540, "Star Ruby", 27 } }, note = "Plans: quest from Derotain Mudsipper, Tanaris (20 Thorium Bar)." },
      { 270, 290, { "Imperial Plate Boots", 20, { "Thorium Bar", 680, "Star Ruby", 20, "Aquamarine", 20 } }, note = "Plans: Derotain Mudsipper's quest (40 Thorium Bar). Have Plans: Radiant Boots? 22 of those instead." },
      { 290, 300, { "Imperial Plate Leggings", 10, { "Thorium Bar", 440, "Star Ruby", 20 } }, note = "Plans: Derotain Mudsipper's quest (60 Thorium Bar). Have Plans: Radiant Leggings? Those stay orange to 300." },
    },
  },

  -- Enchanting
  [333] = {
    name = "Enchanting",
    ranks = {
      { at = 75, need = 50, lvl = 10, h = "Godan (Orgrimmar), Lavinia Crowe (Undercity), Teg Dawnstrider (Thunder Bluff)", a = "Lucan Cordell (Stormwind), Gimble Thistlefuzz (Ironforge), Taladan (Darnassus)" },
      { at = 150, need = 125, lvl = 20, h = "Hgarth, Sun Rock Retreat (Stonetalon) (50s)", a = "Kitta Firewind, Tower of Azora (Elwynn) (50s)" },
      { at = 225, need = 200, lvl = 35, h = "Annora, Uldaman", a = "Annora, Uldaman" },
    },
    steps = {
      { 1, 2, { "Runed Copper Rod", 1, { "Copper Rod", 1, "Mote of Magic", 1 } }, note = "Mote of Magic is sold by Enchanting vendors." },
      { 2, 20, { "Enchant Bracer - Inferior Stamina", 18, { "Mote of Magic", 18 } } },
      { 20, 70, { "Enchant Chest - Inferior Stamina", 50, { "Strange Dust", 50 } },
        { "Enchant Bracer - Minor Deflect", 50, { "Lesser Magic Essence", 50 } }, any = true,
        note = "Pick the dust or essence you have. Right-click a Greater Magic Essence for 3 Lesser." },
      { 70, 85, { "Enchant Chest - Inferior Stamina", 21, { "Strange Dust", 21 } } },
      { 85, 100, { "Enchant Bracer - Minor Stamina", 15, { "Strange Dust", 30 } } },
      { 100, 109, { "Enchant Cloak - Minor Protection", 9, { "Strange Dust", 18 } } },
      { 109, 110, { "Runed Silver Rod", 1, { "Silver Rod", 1, "Strange Dust", 3, "Lesser Magic Essence", 4, "Shadowgem", 1 } } },
      { 110, 130, { "Enchant Cloak - Minor Protection", 29, { "Strange Dust", 58 } } },
      { 130, 150, { "Enchant Boots - Minor Stamina", 20, { "Strange Dust", 80 } },
        note = "Buy Formula: Minor Mana Oil and Formula: Lesser Wizard Oil now." },
      { 150, 151, { "Runed Golden Rod", 1, { "Golden Rod", 1, "Iridescent Pearl", 1, "Greater Astral Essence", 1, "Soul Dust", 1 } } },
      { 151, 165, { "Minor Mana Oil", 16, { "Soul Dust", 16, "Maple Seed", 32, "Leaded Vial", 16 } } },
      { 165, 200, { "Enchant Boots - Lesser Agility", 44, { "Soul Dust", 44 } }, note = "Yellow from 180." },
      { 200, 201, { "Runed Truesilver Rod", 1, { "Truesilver Rod", 1, "Black Pearl", 1, "Greater Mystic Essence", 1, "Vision Dust", 1 } } },
      { 201, 220, { "Lesser Wizard Oil", 25, { "Vision Dust", 25, "Stranglethorn Seed", 50, "Leaded Vial", 25 } } },
      { 220, 225, { "Enchant Cloak - Greater Defense", 5, { "Vision Dust", 5 } } },
      { 225, 250, { "Enchant Gloves - Agility", 34, { "Vision Dust", 34 } }, note = "Annora (Uldaman) teaches it. She shows up once her area is cleared: bring a group, and learn ALL her recipes, the ones from 230 are taught nowhere else." },
      { 250, 270, { "Lesser Mana Oil", 26, { "Dream Dust", 26, "Purple Lotus", 26, "Crystal Vial", 26 } },
        note = "Formulas: Lesser Mana Oil and Wizard Oil from Kania, Silithus (level 40). No Purple Lotus? Enchant Bracer - Greater Strength instead." },
      { 270, 275, { "Enchant Shield - Greater Stamina", 5, { "Dream Dust", 30 } },
        note = "Formula: Daniel Bartlett (Undercity) or Mythrin'dir (Darnassus)." },
      { 275, 295, { "Wizard Oil", 26, { "Illusion Dust", 78, "Firebloom", 52, "Crystal Vial", 26 } }, note = "Illusion Dust expensive? Make 23 Enchant Shield - Greater Stamina instead." },
      { 295, 299, { "Enchant Shield - Greater Stamina", 8, { "Dream Dust", 48 } } },
      { 299, 300, { "Runed Arcanite Rod", 1, { "Arcanite Rod", 1, "Golden Pearl", 1, "Illusion Dust", 10, "Greater Eternal Essence", 4, "Small Brilliant Shard", 4, "Large Brilliant Shard", 2 } },
        note = "Formula: Lorelae Wintersong, Nighthaven (Moonglade)." },
    },
  },

  -- Engineering
  [202] = {
    name = "Engineering",
    ranks = {
      { at = 75, need = 50, lvl = 10, h = "Nogg (Orgrimmar), Franklin Lloyd (Undercity)", a = "Lilliam Sparkspindle (Stormwind), Trixie Quikswitch (Ironforge), Finbus Geargrind (Duskwood)" },
      { at = 150, need = 125, lvl = 20, h = "Roxxik, Orgrimmar (50s)", a = "Springspindle Fizzlegear, Ironforge (50s)" },
      { at = 225, need = 200, lvl = 35, h = "Buzzek Bracketswing, Gadgetzan", a = "Buzzek Bracketswing, Gadgetzan" },
    },
    steps = {
      { 1, 35, { "Rough Blasting Powder", 52, { "Rough Stone", 52 } }, note = "Keep them for bombs. Buy a Blacksmith Hammer." },
      { 35, 55, { "Handful of Copper Bolts", 26, { "Copper Bar", 26 } } },
      { 55, 56, { "Arclight Spanner", 1, { "Copper Bar", 6 } } },
      { 56, 75, { "Rough Copper Bomb", 26, { "Copper Bar", 26, "Handful of Copper Bolts", 26, "Rough Blasting Powder", 52, "Linen Cloth", 26 } }, note = "Yellow from 60. Learn Journeyman before you craft AFK." },
      { 75, 90, { "Coarse Blasting Powder", 51, { "Coarse Stone", 51 } } },
      { 90, 100, { "Coarse Dynamite", 17, { "Coarse Blasting Powder", 51, "Linen Cloth", 17 } } },
      { 100, 105, { "Silver Contact", 5, { "Silver Bar", 5 } }, note = "Silver Bar expensive? Make 5 Flying Tiger Goggles instead." },
      { 105, 125, { "Bronze Tube", 25, { "Bronze Bar", 50, "Weak Flux", 25 } } },
      { 125, 135, { "Standard Scope", 10, { "Bronze Tube", 10, "Moss Agate", 10 } }, note = "No Moss Agate? Make Heavy Blasting Powder instead." },
      { 135, 150, { "Heavy Blasting Powder", 30, { "Heavy Stone", 30 } },
        { "Whirring Bronze Gizmo", 15, { "Bronze Bar", 30, "Wool Cloth", 15 } }, note = "Make both, in this order." },
      { 150, 160, { "Bronze Framework", 15, { "Bronze Bar", 30, "Medium Leather", 15, "Wool Cloth", 15 } } },
      { 160, 175, { "Explosive Sheep", 15, { "Heavy Blasting Powder", 30, "Whirring Bronze Gizmo", 15, "Bronze Framework", 15, "Wool Cloth", 30 } }, note = "Keep 5 if you go Goblin Engineering." },
      { 175, 194, { "Solid Blasting Powder", 60, { "Solid Stone", 120 } } },
      { 194, 195, { "Gyromatic Micro-Adjustor", 1, { "Steel Bar", 4 } } },
      { 195, 200, { "Mithril Tube", 6, { "Mithril Bar", 18 } }, note = "Choose Gnomish or Goblin Engineering at 200 (level 30)." },
      { 200, 215, { "Unstable Trigger", 20, { "Mithril Bar", 20, "Mageweave Cloth", 20, "Solid Blasting Powder", 20 } }, note = "Learn Artisan at 200 from Buzzek Bracketswing (Gadgetzan): he teaches these recipes too. Keep all 20." },
      { 215, 238, { "Mithril Casing", 40, { "Mithril Bar", 120 } } },
      { 238, 250, { "Hi-Explosive Bomb", 20, { "Mithril Casing", 40, "Unstable Trigger", 20, "Solid Blasting Powder", 40 } } },
      { 250, 260, { "Dense Blasting Powder", 44, { "Dense Stone", 88 } } },
      { 260, 280, { "Thorium Widget", 20, { "Thorium Bar", 60, "Runecloth", 20 } },
        note = "Schematic: Sovik (Orgrimmar) or Gearcutter Cogspinner (Ironforge)." },
      { 280, 300, { "Thorium Tube", 21, { "Thorium Bar", 126 } },
        note = "Schematic (bind on pickup): Xizzer Fizzbolt, Everlook. Yellow from 295." },
    },
  },

  -- Leatherworking
  [165] = {
    name = "Leatherworking",
    ranks = {
      { at = 75, need = 50, lvl = 10, h = "Karolek (Orgrimmar), Arthur Moore (Undercity), Tarn (Thunder Bluff)", a = "Simon Tanner (Stormwind), Fimble Finespindle (Ironforge), Faldron (Darnassus)" },
      { at = 150, need = 125, lvl = 20, h = "Una, Thunder Bluff (50s)", a = "Telonis, Darnassus (50s)" },
      { at = 225, need = 200, lvl = 35, h = "Hahrana Ironhide, Camp Mojache (Feralas)", a = "Drakk Stonehand, Aerie Peak (Hinterlands)" },
    },
    steps = {
      { 1, 30, { "Light Leather", 35, { "Ruined Leather Scraps", 105 } } },
      { 30, 50, { "Cured Light Hide", 20, { "Light Hide", 20, "Salt", 20 } }, note = "Keep the hides for Embossed Leather Pants. No Light Hides? 24 Light Armor Kits to 45, then 5 Embossed Leather Gloves." },
      { 50, 60, { "Embossed Leather Gloves", 10, { "Light Leather", 30, "Coarse Thread", 20 } } },
      { 60, 80, { "Embossed Leather Pants", 20, { "Cured Light Hide", 20, "Light Leather", 120, "Coarse Thread", 40 } } },
      { 80, 95, { "Cured Medium Hide", 20, { "Medium Hide", 20, "Salt", 20 } }, note = "Keep all 20 for Dark Leather Belts." },
      { 95, 105, { "Fine Leather Belt", 22, { "Light Leather", 132, "Coarse Thread", 44 } }, note = "Keep 20 belts for Dark Leather Belts." },
      { 105, 125, { "Dark Leather Belt", 20, { "Fine Leather Belt", 20, "Cured Medium Hide", 20, "Fine Thread", 40, "Gray Dye", 20 } } },
      { 125, 130, { "Heavy Leather", 7, { "Medium Leather", 35 } } },
      { 130, 143, { "Cured Heavy Hide", 25, { "Heavy Hide", 25, "Salt", 75 } }, note = "Keep 15 for Barbaric Shoulders and 10 for Guardian Gloves." },
      { 143, 150, { "Hillman's Leather Gloves", 8, { "Medium Leather", 112, "Fine Thread", 32 } } },
      { 150, 165, { "Barbaric Shoulders", 15, { "Heavy Leather", 120, "Cured Heavy Hide", 15, "Fine Thread", 30 } }, note = "Only Expert trainers teach it." },
      { 165, 175, { "Guardian Gloves", 10, { "Heavy Leather", 40, "Cured Heavy Hide", 10, "Silken Thread", 10 } } },
      { 175, 185, { "Barbaric Harness", 10, { "Heavy Leather", 140, "Fine Thread", 20, "Iron Buckle", 10 } }, note = "Iron Buckles: auction house (blacksmiths make them). None? 10 Thick Armor Kits instead." },
      { 185, 205, { "Nightscape Headband", 22, { "Thick Leather", 110, "Silken Thread", 44 } } },
      { 205, 235, { "Nightscape Pants", 36, { "Thick Leather", 504, "Silken Thread", 144 } }, note = "Only Artisan trainers teach it." },
      { 235, 265, { "Wicked Leather Gauntlets", 36, { "Rugged Leather", 288, "Black Dye", 36, "Rune Thread", 36 } },
        note = "Pattern: Werg Thickblade (Tirisfal) or Leonard Porter (Western Plaguelands). Have Pattern: Blue Suede Shoes? Those are cheaper." },
      { 265, 300, { "Runic Leather Headband", 49, { "Rugged Leather", 686, "Runecloth", 490, "Rune Thread", 49 } },
        note = "Pattern: Jase Farlane, Light's Hope Chapel. Yellow at 285, green at 295." },
    },
  },

  -- Tailoring
  [197] = {
    name = "Tailoring",
    ranks = {
      { at = 75, need = 50, lvl = 10, h = "Magar (Orgrimmar), Rhiannon Davis (Undercity), Tepa (Thunder Bluff)", a = "Sellandus (Stormwind), Jormund Stonebrow (Ironforge), Me'lynn (Darnassus)" },
      { at = 150, need = 125, lvl = 20, h = "Josef Gregorian, Undercity (50s)", a = "Georgio Bolero, Stormwind (50s)" },
      { at = 225, need = 200, lvl = 35, h = "Daryl Stack, Tarren Mill", a = "Timothy Worthington, Theramore" },
    },
    steps = {
      { 1, 30, { "Bolt of Linen Cloth", 30, { "Linen Cloth", 60 } } },
      { 30, 55, { "Linen Belt", 28, { "Bolt of Linen Cloth", 28, "Coarse Thread", 28 } } },
      { 55, 80, { "Bolt of Woolen Cloth", 45, { "Wool Cloth", 135 } }, note = "You need 57 bolts until 125: make them all now." },
      { 80, 95, { "Woolen Cape", 22, { "Bolt of Woolen Cloth", 22, "Fine Thread", 22 } } },
      { 95, 100, { "Double-stitched Woolen Shoulders", 5, { "Bolt of Woolen Cloth", 15, "Fine Thread", 10 } } },
      { 100, 120, { "Bolt of Silk Cloth", 54, { "Silk Cloth", 216 } }, note = "You need 193 bolts until 185: make them all now." },
      { 120, 125, { "Gloves of Meditation", 5, { "Bolt of Woolen Cloth", 20, "Fine Thread", 15, "Elixir of Wisdom", 5 } }, note = "Elixir of Wisdom: auction house or an alchemist." },
      { 125, 140, { "Small Silk Pack", 15, { "Bolt of Silk Cloth", 45, "Heavy Leather", 30, "Fine Thread", 45 } } },
      { 140, 150, { "Bolt of Mageweave", 23, { "Mageweave Cloth", 115 } }, note = "Only Expert trainers teach it. You need 144 bolts until 225." },
      { 150, 170, { "Crimson Silk Vest", 20, { "Bolt of Silk Cloth", 80, "Red Dye", 40, "Fine Thread", 40 } } },
      { 170, 185, { "Crimson Silk Pantaloons", 17, { "Bolt of Silk Cloth", 68, "Red Dye", 34, "Silken Thread", 34 } } },
      { 185, 200, { "Black Mageweave Leggings", 22, { "Bolt of Mageweave", 44, "Silken Thread", 66 } }, note = "Yellow the whole way." },
      { 200, 205, { "Black Mageweave Shoulders", 5, { "Bolt of Mageweave", 15, "Heavy Silken Thread", 10 } }, note = "Only Artisan trainers teach it." },
      { 205, 215, { "Bolt of Runecloth", 23, { "Runecloth", 115 } }, note = "You need 311 bolts until 280." },
      { 215, 225, { "Red Mageweave Bag", 17, { "Bolt of Mageweave", 85, "Red Dye", 34, "Heavy Silken Thread", 34 } } },
      { 225, 240, { "Runecloth Belt", 24, { "Bolt of Runecloth", 72, "Rune Thread", 24 } } },
      { 240, 250, { "Runecloth Gloves", 11, { "Bolt of Runecloth", 44, "Rugged Leather", 44, "Rune Thread", 11 } },
        note = "Pattern: Qia, Winterspring." },
      { 250, 280, { "Runecloth Cuffs", 39, { "Bolt of Runecloth", 195, "Ironweb Spider Silk", 39, "Rune Thread", 39 } },
        note = "Pattern: Horde quest \"Threading a Solution\" (Kal'tinzan, Mount Hyjal) or Pexmit, Mount Hyjal (bind on pickup). No pattern? Runecloth Gloves to 260, then Runecloth Shoulders." },
      { 280, 300, { "Runecloth Shoulders", 58, { "Bolt of Runecloth", 406, "Ironweb Spider Silk", 116, "Rugged Leather", 232 } },
        note = "Pattern: world drop, from the auction house. Alternative: Wizardweave Turban." },
    },
  },

  -- First Aid
  [129] = {
    name = "First Aid",
    ranks = {
      { at = 75, need = 50, lvl = 1, h = "Arnok (Orgrimmar), Mary Edras (Undercity), Pand Stonebinder (Thunder Bluff)", a = "Shaina Fuller (Stormwind), Nissa Firestone (Ironforge), Dannelor (Darnassus)" },
      { at = 150, need = 125, lvl = 1, h = "Book Expert First Aid - Under Wraps: Balai Lok'Wein, Dustwallow Marsh", a = "Book Expert First Aid - Under Wraps: Deneb Walker, Arathi Highlands" },
      { at = 225, need = 225, lvl = 35, h = "Quest Triage: Doctor Gregory Victor, Hammerfall", a = "Quest Triage: Doctor Gustaf VanHowzen, Theramore" },
    },
    steps = {
      { 1, 40, { "Linen Bandage", 50, { "Linen Cloth", 50 } } },
      { 40, 80, { "Heavy Linen Bandage", 60, { "Linen Cloth", 120 } } },
      { 80, 115, { "Wool Bandage", 52, { "Wool Cloth", 52 } } },
      { 115, 150, { "Heavy Wool Bandage", 51, { "Wool Cloth", 102 } } },
      { 150, 180, { "Silk Bandage", 44, { "Silk Cloth", 44 } }, note = "Learn Silk Bandage before you leave the trainer." },
      { 180, 210, { "Heavy Silk Bandage", 44, { "Silk Cloth", 88 } }, note = "Manual from the Expert book vendor." },
      { 210, 240, { "Mageweave Bandage", 45, { "Mageweave Cloth", 45 } }, note = "Manual from the Expert book vendor. At 225: the Triage quest. Use the doctor's bandages, save 15 patients, and turn it in at once." },
      { 240, 260, { "Heavy Mageweave Bandage", 30, { "Mageweave Cloth", 60 } }, note = "The Triage doctor teaches it." },
      { 260, 290, { "Runecloth Bandage", 44, { "Runecloth", 44 } }, note = "Alternative from 275: Major Healing Potion (Manual: auction house or Pexmit, Mount Hyjal)." },
      { 290, 300, { "Heavy Runecloth Bandage", 12, { "Runecloth", 24 } } },
    },
  },

  -- Cooking
  [185] = {
    name = "Cooking",
    ranks = {
      { at = 75, need = 50, lvl = 1, h = "Zamja (Orgrimmar), Eunice Burch (Undercity), Aska Mistrunner (Thunder Bluff)", a = "Stephen Ryback (Stormwind), Daryl Riknussun (Ironforge), Alegorn (Darnassus)" },
      { at = 150, need = 125, lvl = 1, h = "Expert Cookbook: Wulan, Shadowprey Village (Desolace)", a = "Expert Cookbook: Shandrina, Mystral Lake (Ashenvale)" },
      { at = 225, need = 225, lvl = 35, h = "Quest Clamlette Surprise: Dirge Quikcleave, Gadgetzan", a = "Quest Clamlette Surprise: Dirge Quikcleave, Gadgetzan" },
    },
    steps = {
      { 1, 50, { "Brilliant Smallfish", 55, { "Raw Brilliant Smallfish", 55 } },
        { "Slitherskin Mackerel", 55, { "Raw Slitherskin Mackerel", 55 } },
        { "Charred Wolf Meat", 55, { "Stringy Wolf Meat", 55 } },
        { "Roasted Boar Meat", 55, { "Chunk of Boar Meat", 55 } }, any = true },
      { 50, 100, { "Longjaw Mud Snapper", 55, { "Raw Longjaw Mud Snapper", 55 } },
        { "Rainbow Fin Albacore", 55, { "Raw Rainbow Fin Albacore", 55 } },
        { "Smoked Bear Meat", 70, { "Bear Meat", 70 } },
        { "Strider Stew", 55, { "Strider Meat", 55, "Shiny Red Apple", 55 } }, any = true },
      { 100, 130, { "Bristle Whisker Catfish", 30, { "Raw Bristle Whisker Catfish", 30 } },
        { "Cooked Crab Claw", 35, { "Crawler Claw", 35, "Mild Spices", 35 } }, any = true },
      { 130, 150, { "Bristle Whisker Catfish", 25, { "Raw Bristle Whisker Catfish", 25 } },
        { "Goblin Deviled Clams", 25, { "Tangy Clam Meat", 25, "Hot Spices", 25 } },
        { "Curiously Tasty Omelet", 20, { "Raptor Egg", 20, "Hot Spices", 20 } },
        { "Hot Lion Chops", 25, { "Lion Meat", 25, "Hot Spices", 25 } }, any = true },
      { 150, 175, { "Goblin Deviled Clams", 30, { "Tangy Clam Meat", 30, "Hot Spices", 30 } },
        { "Curiously Tasty Omelet", 30, { "Raptor Egg", 30, "Hot Spices", 30 } },
        { "Hot Lion Chops", 25, { "Lion Meat", 25, "Hot Spices", 25 } }, any = true },
      { 175, 225, { "Roast Raptor", 55, { "Raptor Flesh", 55, "Hot Spices", 55 } },
        { "Mithril Headed Trout", 55, { "Raw Mithril Head Trout", 55 } },
        { "Soothing Turtle Bisque", 55, { "Turtle Meat", 55, "Soothing Spices", 55 } }, any = true,
        note = "For Artisan at 225 bring 12 Giant Egg, 10 Zesty Clam Meat and 20 Alterac Swiss to Dirge Quikcleave, Gadgetzan." },
      { 225, 285, { "Spotted Yellowtail", 72, { "Raw Spotted Yellowtail", 72 } },
        { "Filet of Redgill", 72, { "Raw Redgill", 72 } }, any = true,
        note = "Recipes: Gikkix, Steamwheedle Port (Tanaris), Kelsey Yance (Stranglethorn)." },
      { 285, 300, { "Nightfin Soup", 18, { "Raw Nightfin Snapper", 18, "Refreshing Spring Water", 18 } },
        note = "Recipe: Gikkix, Steamwheedle Port (Tanaris). Refreshing Spring Water from a vendor." },
    },
  },
}

-- the game's skill line IDs by English name, for professions found by name
ns.SKILL_BY_NAME = {}
for id, guide in pairs(ns.GUIDES) do
  ns.SKILL_BY_NAME[guide.name] = id
end

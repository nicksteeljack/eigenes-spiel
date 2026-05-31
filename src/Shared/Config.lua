-- Config.lua
-- Alle einstellbaren Werte zentral an einem Ort.
-- Dieses Modul wird von Server und Client gleichermassen genutzt.

local Config = {}

-- ============================================================
-- BRAINROTS
-- ============================================================

Config.Brainrots = {
	-- { Name, Seltenheit, Spawnchance (0-1), DollarProStunde, Verkaufswert, Mutation }
	{ name = "Tralalelo Tralala",    rarity = "Common",      chance = 0.20, dph = 10,   sell = 50,   mutation = "Nass" },
	{ name = "Bombardiro Crocodilo", rarity = "Common",      chance = 0.18, dph = 12,   sell = 60,   mutation = "Fliegend" },
	{ name = "Tung Tung Tung Sahur", rarity = "Common",      chance = 0.15, dph = 15,   sell = 75,   mutation = "Gross" },
	{ name = "Cappuccino Assassino", rarity = "Common",      chance = 0.12, dph = 18,   sell = 90,   mutation = "Scharf" },
	{ name = "Brrr Brrr Patapim",    rarity = "Rare",        chance = 0.10, dph = 35,   sell = 200,  mutation = "Funkelnd" },
	{ name = "Lirilì Larilà",        rarity = "Rare",        chance = 0.08, dph = 40,   sell = 250,  mutation = "Klein" },
	{ name = "Glorbo Fruttodrillo",  rarity = "Rare",        chance = 0.07, dph = 50,   sell = 300,  mutation = "Unsichtbar" },
	{ name = "Frigo Camelo",         rarity = "Secret Rare", chance = 0.04, dph = 120,  sell = 800,  mutation = "Gefroren" },
	{ name = "Bobritto Bandito",     rarity = "Secret Rare", chance = 0.03, dph = 150,  sell = 1000, mutation = "Bandit" },
	{ name = "La Vaca Saturno",      rarity = "Secret Rare", chance = 0.01, dph = 200,  sell = 1500, mutation = "Kosmisch" },
	{ name = "Trippi Troppi",        rarity = "OG",          chance = 0.015, dph = 500, sell = 5000, mutation = "Psychedelisch" },
	{ name = "Il Cacto con Cappello",rarity = "OG",          chance = 0.005, dph = 800, sell = 8000, mutation = "Legendaer" },
}

-- Seltenheitsstufen — Anzeige-Farbe und Bonus-Multiplikator
Config.Rarities = {
	Common      = { color = Color3.fromRGB(200, 200, 200), multiplier = 1.0 },
	Rare        = { color = Color3.fromRGB(100, 150, 255), multiplier = 1.5 },
	["Secret Rare"] = { color = Color3.fromRGB(255, 100, 220), multiplier = 2.5 },
	OG          = { color = Color3.fromRGB(255, 215, 0),   multiplier = 5.0 },
}

-- ============================================================
-- ZONEN
-- ============================================================

Config.Zones = {
	Runway   = { pvp = true,  description = "Brainrots laufen hier von A nach B" },
	Wald     = { pvp = true,  description = "Pilze sammeln" },
	Strand   = { pvp = true,  description = "Muscheln graben" },
	Wasser   = { pvp = true,  description = "Angeln" },
	Shop     = { pvp = false, description = "Werkzeug und Items kaufen" },
	Krankenhaus = { pvp = false, description = "Respawn-Zone, Safe" },
	Park     = { pvp = false, description = "Safe-Zone in der Mitte" },
}

-- ============================================================
-- SPIELER-BASE
-- ============================================================

Config.Base = {
	startSlots    = 10,
	maxSlots      = 20,
	-- Kosten pro Slot-Upgrade (Index = aktuelle Slot-Zahl -> naechste)
	slotUpgradeCost = {
		[10] = 500,
		[11] = 750,
		[12] = 1000,
		[13] = 1500,
		[14] = 2000,
		[15] = 3000,
		[16] = 4500,
		[17] = 6500,
		[18] = 9000,
		[19] = 12500,
	},
	cashTickerInterval = 60, -- Sekunden zwischen automatischen Einnahmen
}

-- ============================================================
-- SAMMELN
-- ============================================================

Config.Pilze = {
	{ name = "Steinpilz",     sell = 10,  rebirthPoints = 2 },
	{ name = "Pfifferling",   sell = 15,  rebirthPoints = 3 },
	{ name = "Fliegenpilz",   sell = 25,  rebirthPoints = 5 },
	{ name = "Trueffle",      sell = 80,  rebirthPoints = 15 },
	{ name = "Goldpilz",      sell = 200, rebirthPoints = 40 },
}

Config.Fische = {
	{ name = "Barsch",        sell = 12,  rebirthPoints = 2 },
	{ name = "Hecht",         sell = 20,  rebirthPoints = 4 },
	{ name = "Lachs",         sell = 35,  rebirthPoints = 7 },
	{ name = "Thunfisch",     sell = 60,  rebirthPoints = 12 },
	{ name = "Goldfisch",     sell = 150, rebirthPoints = 30 },
}

Config.Muscheln = {
	{ name = "Strandmuschel", sell = 8,   rebirthPoints = 1 },
	{ name = "Austernmuschel",sell = 18,  rebirthPoints = 3 },
	{ name = "Meeresschnecke",sell = 30,  rebirthPoints = 6 },
	{ name = "Perlmuschel",   sell = 100, rebirthPoints = 20 },
	{ name = "Regenbogenmuschel", sell = 250, rebirthPoints = 50 },
}

Config.Werkzeuge = {
	Pilzmesser = { price = 50,  consumable = false, breakAfter = nil },
	Korb       = { price = 30,  consumable = false, breakAfter = nil, maxCapacity = 100 },
	Angelrute  = { price = 75,  consumable = false, breakAfter = nil },
	Koeder     = { price = 5,   consumable = true,  breakAfter = 1 }, -- pro Wurf
	Schaufel   = { price = 100, consumable = false, breakAfter = 25 }, -- kaputt nach 25 Verwendungen
}

-- ============================================================
-- TRAITS & INCUBATOR
-- ============================================================

Config.Traits = {
	-- Standard-Traits (immer waehlbar)
	{ name = "Staerke+",     type = "Standard", chance = 0.60, costMultiplier = 1.0 },
	{ name = "Glück+",       type = "Standard", chance = 0.50, costMultiplier = 1.2 },
	{ name = "Schnelligkeit",type = "Standard", chance = 0.45, costMultiplier = 1.3 },
	{ name = "Ausdauer",     type = "Standard", chance = 0.40, costMultiplier = 1.4 },
	{ name = "Reich",        type = "Standard", chance = 0.30, costMultiplier = 1.8 },
	{ name = "Doppel-$",     type = "Standard", chance = 0.20, costMultiplier = 2.5 },

	-- Gesperrte Traits (muessen freigeschaltet werden)
	{ name = "Unsterblich",  type = "Locked",   chance = 0.15, costMultiplier = 3.0 },
	{ name = "Schattenklon", type = "Locked",   chance = 0.10, costMultiplier = 4.0 },

	-- Event-Traits (nur waehrend aktivem Snap)
	{ name = "Disco-Move",   type = "Event",    chance = 0.35, costMultiplier = 1.5, snapName = "Disco" },
	{ name = "Feuer-Aura",   type = "Event",    chance = 0.25, costMultiplier = 2.0, snapName = "Feuer" },
}

Config.Incubator = {
	slots        = 1,
	durationSecs = 3600,        -- 1 Stunde
	traitCostPct = 0.20,        -- 20% des Brainrot-Verkaufswerts pro Trait
	runwayWindowSecs = 180,     -- 3-Minuten-Fenster auf dem Runway
}

-- ============================================================
-- REBIRTH
-- ============================================================

Config.Rebirth = {
	maxLevel = 10,
	-- Kosten verdoppeln sich jede Stufe: 50 * 2^(level-1)
	levels = {
		{ level = 1,  points = 50,    multiplier = 1 },
		{ level = 2,  points = 100,   multiplier = 2 },
		{ level = 3,  points = 200,   multiplier = 3 },
		{ level = 4,  points = 400,   multiplier = 4 },
		{ level = 5,  points = 800,   multiplier = 5 },
		{ level = 6,  points = 1600,  multiplier = 6 },
		{ level = 7,  points = 3200,  multiplier = 7 },
		{ level = 8,  points = 6400,  multiplier = 8 },
		{ level = 9,  points = 12800, multiplier = 9 },
		{ level = 10, points = 25600, multiplier = 10 },
	},
}

-- ============================================================
-- PVP & WAFFEN
-- ============================================================

Config.DeathFee = 0.10 -- 10% des stündlichen Einkommens bei Tod

Config.Waffen = {
	{ name = "Lichtschwert", type = "Nahkampf",   damage = 25, priceCash = 500,  priceCoin = 0  },
	{ name = "Pistole",      type = "Fernkampf",  damage = 30, priceCash = 800,  priceCoin = 0  },
	{ name = "Laser-Saebel", type = "Nahkampf",   damage = 40, priceCash = 1500, priceCoin = 0  },
	{ name = "Sniper",       type = "Fernkampf",  damage = 75, priceCash = 0,    priceCoin = 50 },
}

Config.PlayerHP = 100

-- ============================================================
-- SNAPS / EVENTS
-- ============================================================

Config.Snaps = {
	{
		name    = "Disco",
		effects = { "Discokugeln", "Disco-Beleuchtung" },
		songs   = { "rbxassetid://DISCO_SONG_ID" },
		traits  = { "Disco-Move" },
	},
	{
		name    = "Feuer",
		effects = { "Feuerregen", "Lava-Boden" },
		songs   = { "rbxassetid://FIRE_SONG_ID" },
		traits  = { "Feuer-Aura" },
	},
}

-- ============================================================
-- GAMEPASSES
-- ============================================================

Config.Gamepasses = {
	Pilze   = { id = 0, speedMultiplier = 1.25 }, -- ID eintragen sobald bekannt
	Muscheln= { id = 0, speedMultiplier = 1.25 },
	Angel   = { id = 0, speedMultiplier = 1.25 },
}

-- ============================================================
-- ADMIN
-- ============================================================

Config.AdminUserIds = {
	-- Roblox-UserID des Owners hier eintragen
	-- Beispiel: 123456789
}

-- ============================================================
-- SPAWN
-- ============================================================

Config.BrainrotSpawnInterval = 15 -- Sekunden zwischen Spawns

return Config

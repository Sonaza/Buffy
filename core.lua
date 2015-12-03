------------------------------------------------------------
-- Buffy by Sonaza
------------------------------------------------------------

local ADDON_NAME, SHARED_DATA = ...;

local _G = getfenv(0);

local LibStub = LibStub;
local A = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME, "AceEvent-3.0");
_G[ADDON_NAME], SHARED_DATA[1] = A, A;

local E = {};
SHARED_DATA[2] = E;

local _;

-- Text Strings
BUFFY_SET_BINDING_TEXT 		= "|cffeed028Set Buffy Cast Keybind|r";
BUFFY_CHOOSE_BINDING_TEXT	= "Choose a Binding";
BUFFY_PRESS_BUTTON_TEXT		= "Press a key to use it as the binding";
BUFFY_TEMPORARY_BIND_TEXT	= "Buffy will set a temporary binding when required and you can use any key you want without overwriting existing ones."
BUFFY_CANCEL_BINDING_TEXT 	= "Press Escape to Cancel";
BUFFY_ACCEPT_TEXT			= "Save";

local ALERT_TYPE_SPELL		= 0x01;
local ALERT_TYPE_ITEM		= 0x02;
local ALERT_TYPE_SPECIAL	= 0xFF;

local SPECIAL_FOOD		= 0x1;
local SPECIAL_EATING	= 0x2;
local SPECIAL_UNLOCKED	= 0x3;

-- Some buff category data
local BUFF_STATS 		= 0x001; -- RAID_BUFF_1 Stats
local BUFF_STAMINA 		= 0x002; -- RAID_BUFF_2 Stamina
local BUFF_ATTACK_POWER	= 0x004; -- RAID_BUFF_3 Attack Power
local BUFF_HASTE		= 0x008; -- RAID_BUFF_4 Haste
local BUFF_SPELL_POWER	= 0x010; -- RAID_BUFF_5 Spell Power
local BUFF_CRIT			= 0x020; -- RAID_BUFF_6 Critical Strike
local BUFF_MASTERY		= 0x040; -- RAID_BUFF_7 Mastery
local BUFF_MULTISTRIKE	= 0x080; -- RAID_BUFF_8 Multistrike
local BUFF_VERSATILITY	= 0x100; -- RAID_BUFF_9 Versatility

local BUFF_SPECIAL		= 0xFFF;

local BUFF_TYPES = {
	BUFF_STATS,
	BUFF_STAMINA,
	BUFF_ATTACK_POWER,
	BUFF_HASTE,
	BUFF_SPELL_POWER,
	BUFF_CRIT,
	BUFF_MASTERY,
	BUFF_MULTISTRIKE,
	BUFF_VERSATILITY,
};
A.BUFF_TYPES = BUFF_TYPES;

E.BUFF_TYPE_NAMES = {
	[BUFF_STATS] 		= RAID_BUFF_1,
	[BUFF_STAMINA] 		= RAID_BUFF_2,
	[BUFF_ATTACK_POWER] = RAID_BUFF_3,
	[BUFF_HASTE] 		= RAID_BUFF_4,
	[BUFF_SPELL_POWER] 	= RAID_BUFF_5,
	[BUFF_CRIT] 		= RAID_BUFF_6,
	[BUFF_MASTERY] 		= RAID_BUFF_7,
	[BUFF_MULTISTRIKE] 	= RAID_BUFF_8,
	[BUFF_VERSATILITY] 	= RAID_BUFF_9,	
};

local BUFF_SPELL_CATEGORIES = {
	[BUFF_STATS] 		= {},
	[BUFF_STAMINA] 		= {},
	[BUFF_ATTACK_POWER] = {},
	[BUFF_HASTE] 		= {},
	[BUFF_SPELL_POWER] 	= {},
	[BUFF_CRIT] 		= {},
	[BUFF_MASTERY] 		= {},
	[BUFF_MULTISTRIKE] 	= {},
	[BUFF_VERSATILITY] 	= {},
};
A.BUFF_SPELL_CATEGORIES = BUFF_SPELL_CATEGORIES;

local BUFFS = {};
local BUFF_CATEGORY_BY_SPELL = {};
local AURA_BUFFS = {};

local function AddBuffSpell(spell, categories, name, isAura)
	if(not spell or not categories) then return end
	
	if(name) then
		BUFFS[name] = spell;
	end
	
	BUFF_CATEGORY_BY_SPELL[spell] = categories;
	
	if(isAura) then
		AURA_BUFFS[name] = true;
		AURA_BUFFS[spell] = true;
	end
	
	if(categories == BUFF_SPECIAL) then return end
	
	for _, category in pairs(BUFF_TYPES) do
		if(bit.band(categories, category) > 0) then
			tinsert(BUFF_SPELL_CATEGORIES[category], spell);
		end
	end
end

local function GetBuffCategory(spell)
	if(not spell) then return end
	return BUFF_CATEGORY_BY_SPELL[spell];
end

AddBuffSpell(20217,		BUFF_STATS, "BLESSING_OF_KINGS");
AddBuffSpell(115921,	BUFF_STATS, "LEGACY_OF_THE_EMPEROR");
AddBuffSpell(1126,		BUFF_STATS + BUFF_VERSATILITY, "MARK_OF_THE_WILD");
AddBuffSpell(116781,	BUFF_STATS + BUFF_CRIT, "LEGACY_OF_THE_WHITE_TIGER");
AddBuffSpell(160206,	BUFF_STATS, "LONEWOLF_PRIMATES", true);
AddBuffSpell(159988,	BUFF_STATS, "PET_DOG", true);
AddBuffSpell(160017,	BUFF_STATS, "PET_GORILLA", true);
AddBuffSpell(90363,		BUFF_STATS + BUFF_CRIT, "PET_SHALE_SPIDER", true);
AddBuffSpell(160077,	BUFF_STATS + BUFF_VERSATILITY, "PET_WORM", true);

AddBuffSpell(469, 		BUFF_STAMINA, "COMMANDING_SHOUT");
AddBuffSpell(21562,		BUFF_STAMINA, "POWER_WORD_FORTITUDE");
AddBuffSpell(166928,	BUFF_STAMINA, "BLOOD_PACT", true);
AddBuffSpell(160199,	BUFF_STAMINA, "LONEWOLF_BEAR", true);
AddBuffSpell(50256,		BUFF_STAMINA, "PET_BEAR", true);
AddBuffSpell(160014,	BUFF_STAMINA, "PET_GOAT", true);
AddBuffSpell(160003,	BUFF_STAMINA + BUFF_HASTE, "PET_RYLAK", true);
AddBuffSpell(90364,		BUFF_STAMINA + BUFF_SPELL_POWER, "PET_SILITHID", true);

AddBuffSpell(6673, 		BUFF_ATTACK_POWER, "BATTLE_SHOUT");
AddBuffSpell(57330, 	BUFF_ATTACK_POWER, "HORN_OF_WINTER");
AddBuffSpell(19506, 	BUFF_ATTACK_POWER, "TRUESHOT_AURA", true);

AddBuffSpell(55610,		BUFF_HASTE + BUFF_VERSATILITY, "UNHOLY_AURA", true);
AddBuffSpell(49868,		BUFF_HASTE + BUFF_MULTISTRIKE, "MIND_QUICKENING", true);
AddBuffSpell(116956,	BUFF_HASTE + BUFF_MASTERY, "GRACE_OF_AIR", true);
AddBuffSpell(113742,	BUFF_HASTE + BUFF_MULTISTRIKE, "SWIFTBLADES_CUNNING", true);
AddBuffSpell(160203,	BUFF_HASTE, "LONEWOLF_HYENA", true);
AddBuffSpell(128432,	BUFF_HASTE, "PET_HYENA", true);
AddBuffSpell(135678,	BUFF_HASTE, "PET_SPOREBAT", true);
AddBuffSpell(160074,	BUFF_HASTE, "PET_WASP", true);

AddBuffSpell(1459,		BUFF_SPELL_POWER + BUFF_CRIT, "ARCANE_BRILLIANCE");
AddBuffSpell(61316,		BUFF_SPELL_POWER + BUFF_CRIT, "DALARAN_BRILLIANCE");
AddBuffSpell(109773,	BUFF_SPELL_POWER + BUFF_MULTISTRIKE, "DARK_INTENT");
AddBuffSpell(160205,	BUFF_SPELL_POWER, "LONEWOLF_SERPENT", true);
AddBuffSpell(126309,	BUFF_SPELL_POWER, "PET_WATER_STRIDER", true);
AddBuffSpell(128433,	BUFF_SPELL_POWER, "PET_SERPENT", true);

AddBuffSpell(17007,		BUFF_CRIT, "LEADER_OF_THE_PACK", true);
AddBuffSpell(160200,	BUFF_CRIT, "LONEWOLF_RAPTOR", true);
AddBuffSpell(160052,	BUFF_CRIT, "PET_RAPTOR", true);
AddBuffSpell(24604,		BUFF_CRIT, "PET_WOLF", true);
AddBuffSpell(90309,		BUFF_CRIT, "PET_DEVILSAUR", true);
AddBuffSpell(126373,	BUFF_CRIT, "PET_QUILEN", true);

AddBuffSpell(155522, 	BUFF_MASTERY, "POWER_OF_THE_GRAVE", true);
AddBuffSpell(19740, 	BUFF_MASTERY, "BLESSING_OF_MIGHT");
AddBuffSpell(24907, 	BUFF_MASTERY, "MOONKIN_AURA", true);
AddBuffSpell(160198, 	BUFF_MASTERY, "LONEWOLF_CAT", true);
AddBuffSpell(93435, 	BUFF_MASTERY, "PET_CAT", true);
AddBuffSpell(160039, 	BUFF_MASTERY, "PET_HYDRA", true);
AddBuffSpell(160073, 	BUFF_MASTERY, "PET_TALLSTRIDER", true);
AddBuffSpell(128997, 	BUFF_MASTERY, "PET_SPIRIT_BEAST", true);

AddBuffSpell(166916,	BUFF_MULTISTRIKE, "WINDFLURRY", true);
AddBuffSpell(172968, 	BUFF_MULTISTRIKE, "LONEWOLF_DRAGONHAWK", true);
AddBuffSpell(50519, 	BUFF_MULTISTRIKE, "PET_BAT", true);
AddBuffSpell(34889, 	BUFF_MULTISTRIKE, "PET_DRAGONHAWK", true);
AddBuffSpell(24844, 	BUFF_MULTISTRIKE, "PET_WIND_SERPENT", true);
AddBuffSpell(58604, 	BUFF_MULTISTRIKE, "PET_CORE_HOUND", true);
AddBuffSpell(57386, 	BUFF_MULTISTRIKE + BUFF_VERSATILITY, "PET_CLEFTHOOF", true);

AddBuffSpell(167188,	BUFF_VERSATILITY, "INSPIRING_PRESENCE", true);
AddBuffSpell(167187,	BUFF_VERSATILITY, "SANCTITY_AURA", true);
AddBuffSpell(172967,	BUFF_VERSATILITY, "LONEWOLF_RAVAGER", true);
AddBuffSpell(50518,		BUFF_VERSATILITY, "PET_RAVAGER", true);
AddBuffSpell(159735,	BUFF_VERSATILITY, "PET_BIRD_OF_PREY", true);
AddBuffSpell(35290,		BUFF_VERSATILITY, "PET_BOAR", true);
AddBuffSpell(160045,	BUFF_VERSATILITY, "PET_PORCUPINE", true);
AddBuffSpell(173035,	BUFF_VERSATILITY, "PET_STAG", true);

AddBuffSpell(324, 		BUFF_SPECIAL, "SHAMAN_LIGHTNING_SHIELD");

AddBuffSpell(2823, 		BUFF_SPECIAL, "ROGUE_DEADLY_POISON");
AddBuffSpell(8679, 		BUFF_SPECIAL, "ROGUE_WOUND_POISON");
AddBuffSpell(3408, 		BUFF_SPECIAL, "ROGUE_CRIPPLING_POISON");
AddBuffSpell(108211,	BUFF_SPECIAL, "ROGUE_LEECHING_POISON");

AddBuffSpell(15473,		BUFF_SPECIAL, "PRIEST_SHADOWFORM");

AddBuffSpell(25780,		BUFF_SPECIAL, "PALADIN_RIGHTEOUS_FURY");

AddBuffSpell(20707,		BUFF_SPECIAL, "WARLOCK_SOULSTONE");
AddBuffSpell(108503,	BUFF_SPECIAL, "WARLOCK_GRIMOIRE_OF_SACRIFICE");

AddBuffSpell(48263,		BUFF_SPECIAL, "DEATHKNIGHT_BLOOD_PRESENCE");
AddBuffSpell(48266,		BUFF_SPECIAL, "DEATHKNIGHT_FROST_PRESENCE");
AddBuffSpell(48265,		BUFF_SPECIAL, "DEATHKNIGHT_UNHOLY_PRESENCE");

AddBuffSpell(5487,		BUFF_SPECIAL, "DRUID_BEAR_FORM");
AddBuffSpell(768,		BUFF_SPECIAL, "DRUID_CAT_FORM");
AddBuffSpell(24858,		BUFF_SPECIAL, "DRUID_MOONKIN_FORM");

AddBuffSpell(13159,		BUFF_SPECIAL, "HUNTER_ASPECT_OF_THE_PACK");

AddBuffSpell(2457,		BUFF_SPECIAL, "WARRIOR_BATTLE_STANCE");
AddBuffSpell(156291,	BUFF_SPECIAL, "WARRIOR_GLADIATOR_STANCE");
AddBuffSpell(71,		BUFF_SPECIAL, "WARRIOR_DEFENSIVE_STANCE");

AddBuffSpell(181943,	BUFF_SPECIAL, "PEPE");
local PEPE_TOY_ITEM_ID = 122293;

local function CanPoisonWeapons()
	local mainhand = GetInventoryItemLink("player", 16);
	local mhSlot = mainhand and select(9, GetItemInfo(mainhand)) or "";
	
	local offhand = GetInventoryItemLink("player", 17);
	local ohSlot = offhand and select(9, GetItemInfo(offhand)) or "";
	
	return mhSlot == "INVTYPE_WEAPON" or mhSlot == "INVTYPE_WEAPONMAINHAND" or
		   ohSlot == "INVTYPE_WEAPON" or ohSlot == "INVTYPE_WEAPONOFFHAND";
end

local function GetGCD()
	local start, duration = GetSpellCooldown(61304);
	if(start > 0 and duration > 0) then
		return start + duration - GetTime();
	end
	
	return 0;
end

local function ltinsert(table, list)
	if(not table or type(table) ~= "table") then return false end
	if(not list or type(list) ~= "table") then return false end
	
	for key, value in ipairs(list) do
		table[key] = value;
	end
end

local function tmerge(table, other)
	for key, value in ipairs(other) do
		tinsert(table, value);
	end
	
	return table;
end

function A:IsSpellReady(spellID)
	local start, duration, enable = GetSpellCooldown(BUFFS.WARLOCK_SOULSTONE);
	if(start ~= nil and duration ~= nil) then
		if((start + duration - GetTime()) - GetGCD() <= 0.0) then
			return true
		end
	end
	
	return false;
end

-- Category designations
-- passive = only passively casted buffs
-- all = Always active for all specs
-- special = Some special thing for all specs, not necessarily always enabled
-- [0] = Base buffs for all specs
-- [x] = Override to previous on per spec basis where x is spec number

local CLASS_CASTABLE_BUFFS = {
	["WARRIOR"]	= {
		all	= {
			{
				raidbuff = { BUFFS.BATTLE_SHOUT, BUFFS.COMMANDING_SHOUT, },
			},
		},
		[0] = {
			{
				selfbuff = { BUFFS.WARRIOR_BATTLE_STANCE },
				skipBuffCheck = true,
				condition = function()
					if(not A.db.global.Class.Warrior.StanceAlert) then return false end
					if(A.db.global.Class.Warrior.OnlyInCombat and not InCombatLockdown()) then return false end
					
					return GetShapeshiftForm() ~= E.WARRIOR_STANCE.BATTLE;
				end,
				description = function()
					if(GetShapeshiftForm() == 0) then
						return "Not in any stance";
					end
					
					return "Currently in wrong stance";
				end,
			},
		},
		[3] = {
			{
				selfbuff = { BUFFS.WARRIOR_DEFENSIVE_STANCE },
				skipBuffCheck = true,
				condition = function()
					if(not A.db.global.Class.Warrior.StanceAlert) then return false end
					if(A.db.global.Class.Warrior.OnlyInCombat and not InCombatLockdown()) then return false end
					
					if(A:PlayerHasTalent(7, 3)) then
						return not InCombatLockdown() and A.db.global.Class.Warrior.ProtectionStance == 1 and GetShapeshiftForm() ~= E.WARRIOR_STANCE.DEFENSIVE;
					end
					
					return GetShapeshiftForm() ~= E.WARRIOR_STANCE.DEFENSIVE;
				end,
				description = function()
					if(GetShapeshiftForm() == 0) then
						return "Not in any stance";
					end
					
					return "Currently in wrong stance";
				end,
			},
			{
				selfbuff = { BUFFS.WARRIOR_GLADIATOR_STANCE },
				skipBuffCheck = true,
				condition = function()
					if(not A.db.global.Class.Warrior.StanceAlert) then return false end
					if(InCombatLockdown()) then return false end
					if(not A:PlayerHasTalent(7, 3)) then return false end
					
					return A.db.global.Class.Warrior.ProtectionStance == 2 and GetShapeshiftForm() ~= E.WARRIOR_STANCE.GLADIATOR;
				end,
				description = function()
					if(GetShapeshiftForm() == 0) then
						return "Not in any stance";
					end
					
					return "Currently in wrong stance";
				end,
			},
		},
	},
	["DEATHKNIGHT"]	= {
		passive = {
			BUFFS.UNHOLY_AURA, BUFFS.POWER_OF_THE_GRAVE
		},
		all	= {
			{
				raidbuff = { BUFFS.HORN_OF_WINTER },
			},
		},
		special = {
			{
				selfbuff = { BUFFS.DEATHKNIGHT_BLOOD_PRESENCE },
				condition = function()
					if(not A.db.global.Class.DeathKnight.PresenceAlert) then return false end
					if(A.db.global.Class.DeathKnight.OnlyInCombat and not InCombatLockdown()) then return false end
					
					local presence = A.db.global.Class.DeathKnight.Presences[GetSpecialization()];
					return presence == 1 and GetShapeshiftForm() ~= presence;
				end,
				description = "Currently in wrong presence",
			},
			{
				selfbuff = { BUFFS.DEATHKNIGHT_FROST_PRESENCE },
				condition = function()
					if(not A.db.global.Class.DeathKnight.PresenceAlert) then return false end
					if(A.db.global.Class.DeathKnight.OnlyInCombat and not InCombatLockdown()) then return false end
					
					local presence = A.db.global.Class.DeathKnight.Presences[GetSpecialization()];
					return presence == 2 and GetShapeshiftForm() ~= presence;
				end,
				description = "Currently in wrong presence",
			},
			{
				selfbuff = { BUFFS.DEATHKNIGHT_UNHOLY_PRESENCE },
				condition = function()
					if(not A.db.global.Class.DeathKnight.PresenceAlert) then return false end
					if(A.db.global.Class.DeathKnight.OnlyInCombat and not InCombatLockdown()) then return false end
					
					local presence = A.db.global.Class.DeathKnight.Presences[GetSpecialization()];
					return presence == 3 and GetShapeshiftForm() ~= presence;
				end,
				description = "Currently in wrong presence",
			},
		},
	},
	["PALADIN"]	= {
		passive = {
			BUFFS.SANCTITY_AURA,
		},
		all	= {
			{ 
				raidbuff = { BUFFS.BLESSING_OF_KINGS, BUFFS.BLESSING_OF_MIGHT },
			},
		},
		[2]	= {
			{
				selfbuff = { BUFFS.PALADIN_RIGHTEOUS_FURY, },
				condition = function()
					return A.db.global.Class.Paladin.RemindRighteousFury;
				end,
				description = "Missing Righteous Fury",
			},
		},
	},
	["MONK"] = {
		passive = {
			BUFFS.WINDFLURRY,
		},
		[1]	= {
			{
				raidbuff = { BUFFS.LEGACY_OF_THE_WHITE_TIGER, },
			},
		},
		[2]	= {
			{
				raidbuff = { BUFFS.LEGACY_OF_THE_EMPEROR, },
			},
		},
		[3]	= {
			{
				raidbuff = { BUFFS.LEGACY_OF_THE_WHITE_TIGER, },
			},
		},
	},
	["PRIEST"] = {
		all	= {
			{
				raidbuff = { BUFFS.POWER_WORD_FORTITUDE, },
			},
		},
		[3]	= {
			{
				selfbuff = { BUFFS.PRIEST_SHADOWFORM },
				condition = function()
					return A.db.global.Class.Priest.RemindShadowform and GetShapeshiftForm() ~= 1;
				end,
				description = "Not in Shadowform",
			},
		},
	},
	["SHAMAN"] = {
		passive = {
			BUFFS.GRACE_OF_AIR,	
		},
		all	= {
			{
				selfbuff = { BUFFS.SHAMAN_LIGHTNING_SHIELD, },
				condition = function()
					return A.db.global.Class.Shaman.RemindShield;
				end,
			},
		},
	},
	["DRUID"] = {
		passive = {
			BUFFS.LEADER_OF_THE_PACK,
			BUFFS.MOONKIN_AURA,
		},
		all	= {
			{
				raidbuff = { BUFFS.MARK_OF_THE_WILD, },
			},
		},
		[1] = {
			{
				selfbuff = { BUFFS.DRUID_MOONKIN_FORM },
				condition = function()
					if(not A.db.global.Class.Druid.FormAlert) then return false end
					if(A.db.global.Class.Druid.OnlyInCombat and not InCombatLockdown()) then return false end
					
					return GetShapeshiftForm() ~= E.DRUID_FORM.MOONKIN;
				end,
				description = "Not in a form",
			},
		},
		[2] = {
			{
				selfbuff = { BUFFS.DRUID_CAT_FORM },
				condition = function()
					if(not A.db.global.Class.Druid.FormAlert) then return false end
					if(A.db.global.Class.Druid.OnlyInCombat and not InCombatLockdown()) then return false end
					
					return GetShapeshiftForm() ~= E.DRUID_FORM.CAT;
				end,
				description = "Not in a form",
			},
		},
		[3] = {
			{
				selfbuff = { BUFFS.DRUID_BEAR_FORM },
				condition = function()
					if(not A.db.global.Class.Druid.FormAlert) then return false end
					if(A.db.global.Class.Druid.OnlyInCombat and not InCombatLockdown()) then return false end
					
					return GetShapeshiftForm() ~= E.DRUID_FORM.BEAR;
				end,
				description = "Not in a form",
			},
		},
	},
	["ROGUE"] = {
		passive = {
			BUFFS.SWIFTBLADES_CUNNING,
		},
		all = {
			{
				selfbuff = { BUFFS.ROGUE_DEADLY_POISON, BUFFS.ROGUE_WOUND_POISON, },
				condition = function()
					return CanPoisonWeapons() and A.db.global.Class.Rogue.EnableLethal and not A.db.global.Class.Rogue.WoundPoisonPriority;
				end,
				description = "Missing Lethal Poison",
			},
			{
				selfbuff = { BUFFS.ROGUE_WOUND_POISON, BUFFS.ROGUE_DEADLY_POISON, },
				condition = function()
					return CanPoisonWeapons() and A.db.global.Class.Rogue.EnableLethal and A.db.global.Class.Rogue.WoundPoisonPriority;
				end,
				description = "Missing Lethal Poison",
			},
			{
				noTalent = {3, 2},
				selfbuff = { BUFFS.ROGUE_CRIPPLING_POISON, },
				condition = function()
					return CanPoisonWeapons() and A.db.global.Class.Rogue.EnableNonlethal and not A.db.global.Class.Rogue.SkipCrippling;
				end,
				description = "Missing Non-Lethal Poison",
			},
			{
				hasTalent = {3, 2},
				selfbuff = { BUFFS.ROGUE_LEECHING_POISON, },
				condition = function()
					return CanPoisonWeapons() and A.db.global.Class.Rogue.EnableNonlethal;
				end,
				description = "Missing Non-Lethal Poison",
			},
			{
				noTalent = {3, 2},
				selfbuff = { BUFFS.ROGUE_CRIPPLING_POISON },
				skipBuffCheck = true,
				condition = function()
					if(not CanPoisonWeapons() or not A.db.global.Class.Rogue.EnableNonlethal or A.db.global.Class.Rogue.SkipCrippling) then return end
					
					local _, hasBuff, remainingNonLethal, remainingLethal, duration;
					
					hasBuff, _, _, remainingNonLethal, duration = A:UnitHasBuff("player", BUFFS.ROGUE_CRIPPLING_POISON);
					if(not hasBuff or A:WillBuffExpireSoon(remainingNonLethal)) then return false end
					
					hasBuff, _, _, remainingLethal, duration = A:UnitHasSomeBuff("player", { BUFFS.ROGUE_WOUND_POISON, BUFFS.ROGUE_DEADLY_POISON });
					
					local remainingDiff = math.abs(remainingNonLethal - remainingLethal);
					return A.db.global.Class.Rogue.RefreshBoth and hasBuff and remainingLethal >= duration - 20 and remainingDiff > 20;
				end,
				description = "Refresh Non-Lethal Poison Too",
			},
			{
				hasTalent = {3, 2},
				selfbuff = { BUFFS.ROGUE_LEECHING_POISON, },
				skipBuffCheck = true,
				condition = function()
					if(not CanPoisonWeapons() or not A.db.global.Class.Rogue.EnableNonlethal) then return end
					
					local _, hasBuff, remainingNonLethal, remainingLethal, duration;
					
					hasBuff, _, _, remainingNonLethal, duration = A:UnitHasBuff("player", BUFFS.ROGUE_LEECHING_POISON);
					if(not hasBuff or A:WillBuffExpireSoon(remainingNonLethal)) then return false end
					
					hasBuff, _, _, remainingLethal, duration = A:UnitHasSomeBuff("player", { BUFFS.ROGUE_WOUND_POISON, BUFFS.ROGUE_DEADLY_POISON });
					
					local remainingDiff = math.abs(remainingNonLethal - remainingLethal);
					return A.db.global.Class.Rogue.RefreshBoth and hasBuff and remainingLethal >= duration - 20 and remainingDiff > 20;
				end,
				description = "Refresh Non-Lethal Poison Too",
			},
		},
	},
	["MAGE"] = {
		all	= {
			{
				raidbuff = { BUFFS.DALARAN_BRILLIANCE, BUFFS.ARCANE_BRILLIANCE },
			},
		},
	},
	["WARLOCK"] = {
		passive = {
			BUFFS.BLOOD_PACT,
		},
		special = {
			{
				selfbuff = { BUFFS.WARLOCK_SOULSTONE, },
				condition = function()
					if(A:IsSpellReady(BUFFS.WARLOCK_SOULSTONE) and A.db.global.Class.Warlock.EnableSoulstone) then
						if(A.db.global.Class.Warlock.OnlyEnableSolo and A:GetGroupType() ~= E.GROUP_TYPE.SOLO) then return false end
						if(A.db.global.Class.Warlock.OnlyEnableOutside and A:PlayerInInstance()) then return false end
						
						if(A.db.global.Class.Warlock.ExpiryOverride and A:GetBuffRemaining("player", BUFFS.WARLOCK_SOULSTONE) > 300) then
							return false;
						end
						
						return true;
					end
					return false;
				end,
			},
			{
				hasTalent = {5, 3},
				selfbuff = 	{ BUFFS.WARLOCK_GRIMOIRE_OF_SACRIFICE, },
				condition = function()
					-- This talet location has something else for demonology
					if(GetSpecialization() == 2) then return false end
					
					return A.db.global.Class.Warlock.EnableGrimoireSacrificeAlert;
				end,
				description = function()
					if(UnitName("pet") == nil) then
						return "Summon a demon to sacrifice";
					end
					
					return "Sacrifice your demon";
				end,
			},
		},
		all	= {
			{
				raidbuff = { BUFFS.DARK_INTENT },
			},
		},
	},
	["HUNTER"] = {
		passive = {
			BUFFS.TRUESHOT_AURA,	
		},
		special = {
			{
				selfbuff = { BUFFS.HUNTER_ASPECT_OF_THE_PACK, },
				skipBuffCheck = true,
				noCast = true,
				condition = function()
					if(not A.db.global.Class.Hunter.CancelPackAlert or not InCombatLockdown()) then return false end
					
					local hasBuff, castByPlayer = A:UnitHasBuff("player", BUFFS.HUNTER_ASPECT_OF_THE_PACK);
					if(hasBuff and castByPlayer) then
						return true;
					end
				end,
				primary = "Cancel",
				description = "|cffffa842Please, just do it!|r",
			},
		},
		[0]	= {
			{
				hasTalent = {7, 3},
				raidbuff = {
					BUFFS.LONEWOLF_PRIMATES,
					BUFFS.LONEWOLF_DRAGONHAWK,
					BUFFS.LONEWOLF_RAPTOR,
					BUFFS.LONEWOLF_CAT,
					BUFFS.LONEWOLF_HYENA,
					BUFFS.LONEWOLF_RAVAGER,
					BUFFS.LONEWOLF_SERPENT,
					BUFFS.LONEWOLF_BEAR,
				},
				condition = function()
					return A.db.global.Class.Hunter.EnableLoneWolf;
				end,
			},
		},
		[1]	= {
			-- Beast Mastery doesn't have Lone Wolf
		},
	},
};

function A:GetClassCastableBuffs(class, spec)
	local merged = {};
	
	if(CLASS_CASTABLE_BUFFS[class].all) then
		tmerge(merged, CLASS_CASTABLE_BUFFS[class].all);
	end
	
	if(CLASS_CASTABLE_BUFFS[class].special) then
		tmerge(merged, CLASS_CASTABLE_BUFFS[class].special);
	end
	
	if(spec and CLASS_CASTABLE_BUFFS[class][spec]) then
		tmerge(merged, CLASS_CASTABLE_BUFFS[class][spec]);
	elseif(CLASS_CASTABLE_BUFFS[class][0]) then
		tmerge(merged, CLASS_CASTABLE_BUFFS[class][0]);
	end
	
	if(CLASS_CASTABLE_BUFFS["ALL"]) then
		tmerge(merged, CLASS_CASTABLE_BUFFS["ALL"]);
	end
	
	return merged;
end

-- Miscellaneous category, low priority selfbuffs or other stuff
local MISC_CASTABLE_BUFFS = {
	{
		selfbuff = { BUFFS.PEPE },
		skipBuffCheck = true,
		condition = function()
			if(not A.db.global.PepeReminderEnabled or InCombatLockdown()) then return false end
			if(not PlayerHasToy(PEPE_TOY_ITEM_ID)) then return false end
			
			local hasBuff = A:UnitHasBuff("player", BUFFS.PEPE);
			if(hasBuff) then return false end
			
			local start, duration, enable = GetItemCooldown(PEPE_TOY_ITEM_ID);
			return start == 0 and duration == 0;
		end,
		description = function()
			local quotes = {
				"You've not got a friend! :(",
				"Put a birb on it!",
				"It's dangerous to go alone!",
				"Pepe is love, Pepe is life",
				"It's a rough neighborhood",
				"Pepe for Warchief!",
			};
			return quotes[math.floor(GetTime() / 120) % (#quotes) + 1];
		end,
		info = {
			type = "toy",
			id = PEPE_TOY_ITEM_ID,
		},
	},
}

----------------------------------------------------------

local CONSUMABLE_FLASK	= 0x01;
local CONSUMABLE_RUNE	= 0x02;
local CONSUMABLE_FOOD	= 0x03;

E.STAT = {
	AGILITY 	= 0x001,
	STRENGTH 	= 0x002,
	INTELLECT	= 0x004,
	STAMINA		= 0x008,
	
	HASTE		= 0x010,
	MULTISTRIKE	= 0x020,
	MASTERY		= 0x040,
	CRIT		= 0x080,
	VERSATILITY	= 0x100,
	
	FELMOUTH	= 0x200,
	
	AUTOMATIC 	= 0xFFF,
};

local BUFF_ITEM_SPELLS = {};
local FLASKS = {};
local RUNES = {};
local FOODS = {};

local function AddBuffItems(item_table, stat_type, items)
	if(not item_table or type(item_table) ~= "table") then return end
	if(not items or not stat_type) then return end
	
	item_table[stat_type] = items;
end

local function AddItemSpell(item, spell)
	if(not item or not spell) then return end
	
	BUFF_ITEM_SPELLS[item] = spell;
end

AddBuffItems(FLASKS, E.STAT.AGILITY, 	{ 109153, 109145, 118922 });
AddItemSpell(109153, 156064); -- Greater Draenic Agility Flask
AddItemSpell(109145, 156073); -- Draenic Agility Flask

AddBuffItems(FLASKS, E.STAT.STRENGTH,	{ 109156, 109148, 118922 });
AddItemSpell(109156, 156080); -- Greater Draenic Strength Flask
AddItemSpell(109148, 156071); -- Draenic Strength Flask

AddBuffItems(FLASKS, E.STAT.INTELLECT, { 109155, 109147, 118922 });
AddItemSpell(109155, 156079); -- Greater Draenic Intellect Flask
AddItemSpell(109147, 156070); -- Draenic Intellect Flask

AddBuffItems(FLASKS, E.STAT.STAMINA, { 109160, 109152 });
AddItemSpell(109160, 156084); -- Greater Draenic Stamina Flask
AddItemSpell(109152, 156077); -- Draenic Stamina Flask

AddItemSpell(118922, 176151); -- Oralius' Crystal

-- Non-consumable runes are listed first
AddBuffItems(RUNES, E.STAT.AGILITY, 	{ 128482, 128475, 118630 });
AddItemSpell(118630, 175456);

AddBuffItems(RUNES, E.STAT.STRENGTH,	{ 128482, 128475, 118631 });
AddItemSpell(118631, 175439);

AddBuffItems(RUNES, E.STAT.INTELLECT,	{ 128482, 128475, 118632 });
AddItemSpell(118632, 175457);

AddBuffItems(FOODS, E.STAT.HASTE, 		{ 122348, 111450, 118428, 111434, 111442, });
AddBuffItems(FOODS, E.STAT.MULTISTRIKE, { 122344, 111453, 118428, 111445, 111437, });
AddBuffItems(FOODS, E.STAT.MASTERY, 	{ 122343, 111452, 118428, 111436, 111444, });
AddBuffItems(FOODS, E.STAT.CRIT,		{ 122345, 111449, 118428, 111433, 111441, });
AddBuffItems(FOODS, E.STAT.VERSATILITY, { 122346, 111454, 118428, 111438, 111446, });
AddBuffItems(FOODS, E.STAT.STAMINA, 	{ 122347, 111447, 111431, 111439, });
AddBuffItems(FOODS, E.STAT.FELMOUTH,	{ 127991, });

local FEASTS = {
	[175215] = { -- Savage Feast
		item = 118576,
		duration = 180,
		stats = 100,
	},
	[160740] = { -- Feast of Waters
		item = 111458,
		duration = 180,
		stats = 75,
	},
	[160740] = { -- Feast of Blood
		item = 111457,
		duration = 180,
		stats = 75,
	},
};

A.SummonedFeasts = {};

-- Reference table for main stats for classes and specs
local CLASS_STAT_PREFS = {
	["WARRIOR"]	= {
		[0] = { E.STAT.STRENGTH },
		[3] = function()
			if(A:PlayerHasTalent(7, 3) and GetShapeshiftForm() == 1) then
				return { E.STAT.STRENGTH };
			end
			
			return { E.STAT.STAMINA, E.STAT.STRENGTH };
		end,
	},
	["DEATHKNIGHT"]	= {
		[0] = { E.STAT.STRENGTH },
		[1] = { E.STAT.STAMINA, E.STAT.STRENGTH },
	},
	["PALADIN"]	= {
		[1] = { E.STAT.INTELLECT },
		[2] = { E.STAT.STAMINA, E.STAT.STRENGTH },
		[3] = { E.STAT.STRENGTH },
	},
	["MONK"] = {
		[1] = { E.STAT.STAMINA, E.STAT.AGILITY },
		[2] = { E.STAT.INTELLECT },
		[3] = { E.STAT.AGILITY },
	},
	["PRIEST"] = {
		[0] = { E.STAT.INTELLECT },
	},
	["SHAMAN"] = {
		[0] = { E.STAT.INTELLECT },
		[2] = { E.STAT.AGILITY },
	},
	["DRUID"] = {
		[1] = { E.STAT.INTELLECT },
		[2] = { E.STAT.AGILITY },
		[3] = { E.STAT.STAMINA, E.STAT.AGILITY },
		[4] = { E.STAT.INTELLECT },
	},
	["ROGUE"] = {
		[0] = { E.STAT.AGILITY },
	},
	["MAGE"] = {
		[0] = { E.STAT.INTELLECT },
	},
	["WARLOCK"] = {
		[0] = { E.STAT.INTELLECT },
	},
	["HUNTER"] = {
		[0] = { E.STAT.AGILITY },
	},
};

function A:GetStatPreference(class, spec_index)
	if(not class or not spec_index) then return -1; end
	
	local statTypes = CLASS_STAT_PREFS[class][spec_index] or CLASS_STAT_PREFS[class][0];
	if(type(statTypes) == "function") then
		statTypes = statTypes();
	end
	
	local stats = {};
	ltinsert(stats, statTypes);
	
	if(#stats == 2 and stats[1] == E.STAT.STAMINA and self.db.global.ConsumablesRemind.SkipStamina) then
		-- Swap stats
		stats[1], stats[2] = stats[2], stats[1]
	end
	
	return stats;
end

E.RATING_NAMES = {
	[E.STAT.STAMINA]		= "Stamina",
	
	[E.STAT.HASTE]			= "Haste",
	[E.STAT.MULTISTRIKE]	= "Multistrike",
	[E.STAT.MASTERY]		= "Mastery",
	[E.STAT.CRIT]			= "Crit",
	[E.STAT.VERSATILITY]	= "Versatility",
};

local RATING_IDENTIFIERS = {
	[E.STAT.HASTE]		= function()
		return GetCombatRatingBonus(CR_HASTE_SPELL);
	end,
	[E.STAT.MULTISTRIKE]	= function()
		return GetCombatRatingBonus(CR_MULTISTRIKE);
	end,
	[E.STAT.MASTERY]		= function()
		local mastery, bonusCoeff = GetMasteryEffect();
		return GetCombatRatingBonus(CR_MASTERY) * bonusCoeff;
	end,
	[E.STAT.CRIT]			= function()
		return GetCombatRatingBonus(CR_CRIT_SPELL);
	end,
	[E.STAT.VERSATILITY]	= function()
		return GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE);
	end,
};

function A:GetFoodPreference(skip_custom)
	local ratings_list = {};
	
	for stat, ratingFunction in pairs(RATING_IDENTIFIERS) do
		tinsert(ratings_list, {
			stat = stat,
			rating = ratingFunction(),
		});
	end
	
	table.sort(ratings_list, function(a, b)
		if(a == nil and b == nil) then return false end
		if(a == nil) then return true end
		if(b == nil) then return false end
		
		return a.rating > b.rating;
	end);
	
	local activeSpec = GetActiveSpecGroup();
	local customFood = self.db.char.FoodPriority[activeSpec];
	
	local sorted = {};
	
	if(not skip_custom and customFood ~= E.STAT.AUTOMATIC) then
		tinsert(sorted, customFood);
	end
	
	-- Stam food for tanks?
	if(A:PlayerInTankSpec() and not self.db.global.ConsumablesRemind.SkipStamina and (skip_custom or customFood ~= E.STAT.STAMINA)) then
		tinsert(sorted, E.STAT.STAMINA);
	end
	
	for _, data in ipairs(ratings_list) do
		if(skip_custom or customFood ~= data.stat) then
			tinsert(sorted, data.stat);
		end
	end
	
	return sorted;
end

function A:IsPlayerEating()
	-- Find localized name for the eating food buff, there are too many buff ids to manually check
	local localizedFood = GetSpellInfo(33264);
	local name, _, icon, _, _, duration, expirationTime, _, _, _, spellId = UnitBuff("player", localizedFood);
	
	if(name) then
		return true, duration - (expirationTime - GetTime()), spellId;
	end
end

function A:IsPlayerWellFed()
	-- Find localized name for the food buff, there are too many buff ids to manually check
	local localizedFood = GetSpellInfo(180748);
	local name, _, icon, _, _, _, expirationTime, _, _, _, spellId = UnitBuff("player", localizedFood);
	
	if(name) then
		return true, A:WillBuffExpireSoon(expirationTime - GetTime()), spellId;
	end
	
	return false, false, nil;
end

--------------------------------------------

function A:OnInitialize()
	SLASH_BUFFY1	= "/bf";
	SLASH_BUFFY2	= "/buffy";
	SlashCmdList["BUFFY"] = function(message)
		A:SlashHandler(message);
	end
	
	A:InitializeDatabase();
end

function A:OnEnable()
	A:RegisterEvent("UNIT_AURA");
	A:RegisterEvent("BAG_UPDATE_DELAYED");
	A:RegisterEvent("PLAYER_ALIVE");
	A:RegisterEvent("PLAYER_UNGHOST", "PLAYER_ALIVE");
	A:RegisterEvent("PLAYER_TALENT_UPDATE");
	A:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED");
	A:RegisterEvent("PLAYER_EQUIPMENT_CHANGED");
	A:RegisterEvent("PLAYER_REGEN_DISABLED");
	A:RegisterEvent("PLAYER_REGEN_ENABLED");
	A:RegisterEvent("ZONE_CHANGED");
	A:RegisterEvent("ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED");
	A:RegisterEvent("COMPANION_UPDATE");
	A:RegisterEvent("READY_CHECK");
	
	local _, PLAYER_CLASS = UnitClass("player");
	if(PLAYER_CLASS == "WARLOCK") then
		A:RegisterEvent("UNIT_PET");
	end
	
	A:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
	
	A:RegisterEvent("PLAYER_STARTED_MOVING");
	A:RegisterEvent("PLAYER_STOPPED_MOVING");
	
	A:InitializeDatabroker();

	A.IsFrameLocked = true;
	
	A:ScanTalents();
	A:UpdateBuffs();
	
	CreateFrame("Frame"):SetScript("OnUpdate", function(self, elapsed)
		self.elapsed = (self.elapsed or 0) + elapsed;
		
		if(self.elapsed >= 5.0 or (A.ShowingAlert and self.elapsed >= 1.0)) then
			A:UpdateBuffs();
			self.elapsed = 0;
		end
		
		if(not IsFalling() and (A.PlayerStoppedMoving or self.fallFlagged) and A.PlayerIsMoving) then
			A:PLAYER_STOPPED_MOVING_FINISH();
			self.fallFlagged = false;
		elseif(IsFalling() and not A.PlayerIsMoving) then
			A:PLAYER_STARTED_MOVING();
			self.fallFlagged = true;
		end
	end);
end

function A:PLAYER_STARTED_MOVING()
	A.PlayerStoppedMoving = false;
	
	if(A.PlayerIsMoving) then return end
	A.PlayerIsMoving = true;
	
	if(BuffyFrame:IsVisible()) then
		if(self.db.global.AlertMoveFade) then
			if(BuffyFrame.fadeout:IsPlaying() or BuffyFrame.fadeout:IsPlaying() or BuffyFrame.movefadein:IsPlaying()) then return end
			
			local alpha = BuffyFrame:GetAlpha();
			
			BuffyFrame.fadein:Stop();
			BuffyFrame.movefadeout:Stop();
			
			local animation = BuffyFrame.movefadein:GetAnimations();
			animation:SetFromAlpha(alpha);
			
			BuffyFrame.movefadein:Play();
		end
		
		if(self.db.global.UnbindWhenMoving) then
			A:ClearTempBind();
		end
	end
end

function A:PLAYER_STOPPED_MOVING()
	A.PlayerStoppedMoving = true;
end

function A:PLAYER_STOPPED_MOVING_FINISH()
	A.PlayerIsMoving = false;
	
	if(BuffyFrame:IsVisible()) then
		if(self.db.global.AlertMoveFade) then
			if(BuffyFrame.fadeout:IsPlaying() or BuffyFrame.movefadeout:IsPlaying()) then return end
			
			local alpha = BuffyFrame:GetAlpha();
			
			BuffyFrame.fadein:Stop();
			BuffyFrame.movefadein:Stop();
			
			local animation = BuffyFrame.movefadeout:GetAnimations();
			animation:SetFromAlpha(alpha);
			
			BuffyFrame.movefadeout:Play();
		end
		
		if(self.db.global.UnbindWhenMoving) then
			A:RestoreLastTempBind();
		end
	end
end

E.GROUP_TYPE = {
	SOLO 	= 0x1,
	PARTY 	= 0x2,
	RAID	= 0x3,
};

function A:GetGroupType()
	if(IsInRaid()) then
		return E.GROUP_TYPE.RAID;
	elseif(IsInGroup()) then
		return E.GROUP_TYPE.PARTY;
	end
	
	return E.GROUP_TYPE.SOLO;
end

function A:GetRealSpellID(spell_id)
	local spell_name = GetSpellInfo(spell_id);
	local name, _, _, _, _, _, realSpellID = GetSpellInfo(spell_name);
	
	return realSpellID or spell_id;
end

function A:ZONE_CHANGED()
	A:UpdateBuffs();
end

function A:UNIT_AURA()
	A:UpdateBuffs();
end

function A:UNIT_PET()
	A:UpdateBuffs();
end

function A:COMPANION_UPDATE(event, companiontype)
	if(companiontype == "MOUNT") then
		A:UpdateBuffs();
	end
end

function A:PLAYER_SPECIALIZATION_CHANGED()
	A:PLAYER_TALENT_UPDATE();
end

function A:BAG_UPDATE_DELAYED()
	if(self.db.global.ConsumablesRemind.Enabled) then
		A:UpdateBuffs();
	end
end

function A:PLAYER_EQUIPMENT_CHANGED()
	A:UpdateBuffs();
end

function A:PLAYER_REGEN_DISABLED()
	A:UpdateBuffs(true);
	A.IsFrameLocked = true;
	BuffyFrame:EnableMouse(false);
	
	BuffySpellButtonFrame:SetAttribute("type1", nil);
	
	-- No need to scan feasts in combat
	A:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
end

function A:PLAYER_REGEN_ENABLED()
	A:UpdateBuffs(true);
	BuffyFrame:EnableMouse(true);
	
	-- Register event again for feast scanning
	A:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
end

function A:PLAYER_TALENT_UPDATE()
	A:ScanTalents();
	A:UpdateBuffs();
end

function A:PLAYER_ALIVE()
	A:UpdateBuffs();
end

function A:ScanTalents()
	A.ActiveTalents = {};
	
	local numTiers = GetMaxTalentTier();
	local group = GetActiveSpecGroup();
	for tier = 1, numTiers do
		for column = 1, 3 do
			local talentID, _, _, selected = GetTalentInfo(tier, column, group);
			if(selected) then
				A.ActiveTalents[tier] = column;
				break;
			end
		end
	end	
end

function A:PlayerHasTalent(tier, column)
	-- return A.ActiveTalents and A.ActiveTalents[tier] and A.ActiveTalents[tier] == column;
	local talentID, _, _, selected = GetTalentInfo(tier, column, GetActiveSpecGroup());
	return talentID and selected;
end

-- Special abstraction hack to give fake info about player's hidden passive buffs as if they had them visible
function A:UnitAura(unit, spell_name, rank, flags)
	local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster = UnitAura(unit, spell_name, rank, flags);
	
	if(A:GetGroupType() == E.GROUP_TYPE.SOLO and unit == "player" and name == nil) then
		local _, PLAYER_CLASS = UnitClass("player");
		local passiveBuffs = CLASS_CASTABLE_BUFFS[PLAYER_CLASS].passive;
		
		if(passiveBuffs ~= nil) then
			for i, spell_id in pairs(passiveBuffs) do
				if(IsSpellKnown(spell_id)) then
					local name, rank, icon = GetSpellInfo(spell_id);
					if(name == spell_name) then
						return name, rank, icon, 0, nil, 0, 0, "player";
					end
				end
			end
		end
	end
	
	return name, rank, icon, count, debuffType, duration, expirationTime, unitCaster;
end

function A:UnitHasBuff(unit, spell)
	if(not unit or not spell) then return false end
	
	local realSpellID = A:GetRealSpellID(spell);
	local spell_name = GetSpellInfo(realSpellID);
	if(not spell_name) then return false end
	
	local name, _, _, _, _, duration, expirationTime, unitCaster = A:UnitAura(unit, spell_name, nil, "HELPFUL");
	if(not name) then
		return false;
	end
	
	return true, unitCaster == "player", unitCaster, expirationTime - GetTime(), duration, AURA_BUFFS[spell];
end

function A:UnitInRange(unit, extended)
	if(not unit) then return false end
	
	if(unit == "player") then return not UnitIsDeadOrGhost(unit) end
	
	if(not UnitIsVisible(unit) or not UnitIsConnected(unit) or UnitIsDeadOrGhost(unit)) then
		return false;
	end
	
	local rangeThreshold = 900; -- Roughly 30yd radius
	if(extended) then
		rangeThreshold = 10000; -- Roughly 100yd radius
	end
	
	local unitInRange = nil;
	local distance, distanceChecked = UnitDistanceSquared(unit);
	if(distanceChecked) then
		unitInRange = distance <= rangeThreshold;
	end
	
	return unitInRange;
end

local partyUnitID = { "player", "party1", "party2", "party3", "party4" };

function A:GetUnitID(group_type, index)
	if(group_type == E.GROUP_TYPE.SOLO or group_type == E.GROUP_TYPE.PARTY) then
		return partyUnitID[index];
	elseif(group_type == E.GROUP_TYPE.RAID) then
		return string.format("raid%d", index);
	end
	
	return nil;
end

local function GroupIterator()
	local index = 0;
	local groupType = A:GetGroupType();
	local numGroupMembers = GetNumGroupMembers();
	if(groupType == E.GROUP_TYPE.SOLO) then numGroupMembers = 1 end
	
	return function()
		index = index + 1;
		if(index <= numGroupMembers) then
			return index, A:GetUnitID(groupType, index);
		end
	end
end

function A:UnitIsPet(searchunit)
	if(not searchunit) then return false end
	
	local pets = {};
	for index, unit in GroupIterator() do
		if(UnitExists(unit .. "pet") and UnitIsUnit(searchunit, unit .. "pet")) then
			return true, UnitName(unit), UnitName(unit .. "pet");
		end
	end
	
	return false;
end

function A:ScanBuffs()
	local missingBuffs, foundBuffs = {}, {};
	
	for category, spells in pairs(BUFF_SPELL_CATEGORIES) do
		for index, unit in GroupIterator() do
			local buffFound = false;
			local buffIsAura = false;
			
			for _, spell in ipairs(spells) do
				local hasBuff = A:UnitHasBuff(unit, spell);
				
				if(hasBuff) then
					buffFound = true;
					buffIsAura = A:IsSpellAura(spell);
					break;
				end
			end
			
			if(not buffFound) then
				if(not missingBuffs[unit]) then
					missingBuffs[unit] = {};
				end
				
				tinsert(missingBuffs[unit], category);
			else
				if(not foundBuffs[unit]) then
					foundBuffs[unit] = {};
				end
				
				foundBuffs[unit][category] = buffIsAura;
				-- tinsert(foundBuffs[unit], category);
			end
		end
	end
	
	return missingBuffs, foundBuffs;
end

function A:ScanCurrentBuffs()
	local buffs = {};
	
	for category, spells in pairs(BUFF_SPELL_CATEGORIES) do
		local hasBuff, isCastByPlayer, buff_spell, caster = A:UnitHasCategoryBuff("player", category);
		
		if(not hasBuff) then
			buffs[category] = false;
		else
			local name, class;
			if(caster ~= nil) then
				name = UnitName(caster);
				_, class = UnitClass(caster);
			else
				name = "Unknown";
				class = "PRIEST";
			end
			
			buffs[category] = {
				buff = buff_spell,
				casterName = name,
				casterClass = class,
			};
		end
	end
	
	return buffs;
end

function A:GetNumPartyMembers()
	if(A:GetGroupType() == E.GROUP_TYPE.SOLO) then
		return 1;
	end
	
	return GetNumGroupMembers();
end

function A:GetRaidBuffStatus()
	local buffStatus = {};
	local _, foundBuffs = A:ScanBuffs();
	
	local numPartyMembersInRange = 0;
	
	for unit, data in pairs(foundBuffs) do
		local unitInRange = A:UnitInRange(unit, true);
		if(unitInRange) then
			numPartyMembersInRange = numPartyMembersInRange + 1;
		end
		
		for category, hasAura in pairs(data) do
			if(not buffStatus[category]) then
				buffStatus[category] = {
					total = 0,
					inRange = 0,
					hasAura = hasAura,
				};
			else
				buffStatus[category].hasAura = buffStatus[category].hasAura or hasAura;
			end
			
			if(unitInRange) then
				buffStatus[category].inRange = buffStatus[category].inRange + 1;
			end
			
			buffStatus[category].total = buffStatus[category].total + 1;
		end
	end
	
	return buffStatus, A:GetNumPartyMembers(), numPartyMembersInRange;
end

-- function A:

function A:ScanPartySpecs()
	A:RegisterEvent("INSPECT_READY");
	
	A.InspectUnits = {};
	
	for index, unit in GroupIterator() do
		local guid = UnitGUID(unit);
		A.InspectUnits[guid] = unit;
		
		NotifyInspect(unit);
	end
end

function A:INSPECT_READY(event, unitguid)
	local unit = A.InspectUnits[unitguid];
	-- print(unitguid, UnitName(unit), GetInspectSpecialization(unit));
end

function A:ScanWhoCanCast()
	local castables = {};
	local active = {};
	
	for index, unit in GroupIterator() do
		-- print(unit);
		
		local _, unitClass = UnitClass(unit);
		local unitSpec = A:GetUnitSpecialization(unit);
		
		-- local playerHasCategory, isCastByPlayer, buffSpell, caster = A:UnitHasCategoryBuff("player", category);
		
		if(unitSpec > 0) then
			local castableBuffs = A:GetClassCastableBuffs(unitClass, unitSpec);
			for _, data in ipairs(castableBuffs) do
				if(data.raidbuff) then
					for _, spell in ipairs(data.raidbuff) do
						local category = GetBuffCategory(spell);
						
						if(not castables[category]) then
							castables[category] = {
								units = {},
							};
						end
						
						tinsert(castables[category].units, unit);
					end
				end
			end
		end
	end
	
	return castables;
end

function A:ScanMissingBuff(spell)
	if(not spell) then return nil end
	
	local spellCategory = BUFF_CATEGORY_BY_SPELL[spell];
	if(not spellCategory) then return nil end
	
	local checkCategories = {};
	
	for _, category in pairs(BUFF_TYPES) do
		if(bit.band(spellCategory, category) > 0) then
			tinsert(checkCategories, category);
		end
	end
	
	local unitsMissingBuffs = {};
	local buffCastByPlayer;
	
	for _, category in ipairs(checkCategories) do
		for index, unit in GroupIterator() do
			local buffFound = false;
			local isCastByPlayer;
			
			for _, spell in ipairs(BUFF_SPELL_CATEGORIES[category]) do
				local hasBuff;
				hasBuff, isCastByPlayer = A:UnitHasBuff(unit, spell);
				
				if(hasBuff) then
					buffFound = true;
					buffCastByPlayer = isCastByPlayer;
					break;
				end
			end
			
			if(not buffFound and A:UnitInRange(unit)) then
				tinsert(unitsMissingBuffs, unit);
			end
		end
	end
	
	return unitsMissingBuffs, buffCastByPlayer;
end

local BUFF_AURATYPE_NON_AURA = 1;
local BUFF_AURATYPE_AURA = 1;

function A:UnitHasCategoryBuff(unit, category)
	if(not unit or not category) then return nil end
	if(not A:UnitInRange(unit)) then return nil end
	
	local buffs = {
		[BUFF_AURATYPE_NON_AURA] = nil,
		[BUFF_AURATYPE_AURA] = nil, 
	};
	
	local hasBuff, isCastByPlayer, remaining, duration, buffIsAura;
	
	for _, spell in ipairs(BUFF_SPELL_CATEGORIES[category]) do
		hasBuff, isCastByPlayer, caster, remaining, duration, buffIsAura = A:UnitHasBuff(unit, spell);
		if(hasBuff) then
			if(not buffIsAura) then
				buffs[BUFF_AURATYPE_NON_AURA] = { hasBuff, isCastByPlayer, spell, caster, A:WillBuffExpireSoon(remaining or 0), buffIsAura, };
				break;
			else
				buffs[BUFF_AURATYPE_AURA] = { hasBuff, isCastByPlayer, spell, caster, A:WillBuffExpireSoon(remaining or 0), buffIsAura, };
			end
		end
	end
	
	-- return hasBuff, isCastByPlayer, buffSpell, caster, A:WillBuffExpireSoon(remaining or 0), buffIsAura;
	if(buffs[BUFF_AURATYPE_NON_AURA]) then return unpack(buffs[BUFF_AURATYPE_NON_AURA]) end
	if(buffs[BUFF_AURATYPE_AURA]) then return unpack(buffs[BUFF_AURATYPE_AURA]) end
	
	return false;
end

function A:UnitHasNonAuraCategoryBuff(unit, category)
	if(not unit or not category) then return nil end
	if(not A:UnitInRange(unit)) then return nil end
	
	local hasBuff, isCastByPlayer, buffSpell, remaining, duration, buffIsAura;
	
	for _, spell in ipairs(BUFF_SPELL_CATEGORIES[category]) do
		hasBuff, isCastByPlayer, caster, remaining, duration, buffIsAura = A:UnitHasBuff(unit, spell);
		if(hasBuff and not A:IsSpellAura(spell)) then
			return hasBuff, isCastByPlayer, buffSpell, caster, A:WillBuffExpireSoon(remaining or 0);
		end
	end
	
	return false;
end

E.BUFF_STATE = {
	NO_BUFF 			= 0,
	HAS_BUFF 			= 1,
	HAS_BUFF_BY_PLAYER  = 2,
};

function A:ScanBuffList(bufflist)
	if(not bufflist or type(bufflist) ~= "table") then return nil end
	
	local partyBuffState = {};
	
	for _, spell in ipairs(bufflist) do
		if(not spell) then return nil end
		
		local spellCategory = BUFF_CATEGORY_BY_SPELL[spell];
		if(not spellCategory) then return nil end
		
		local checkCategories = {};
		
		for _, category in pairs(BUFF_TYPES) do
			if(bit.band(spellCategory, category) > 0) then
				tinsert(checkCategories, category);
			end
		end
		
		for _, category in ipairs(checkCategories) do
			if(not partyBuffState[category]) then
				partyBuffState[category] = {};
			end
			
			for index, unit in GroupIterator() do
				local hasBuff, isCastByPlayer, buffSpell, caster, willExpireSoon, buffIsAura = A:UnitHasCategoryBuff(unit, category);
				
				if(hasBuff ~= nil) then
					local buffState = E.BUFF_STATE.NO_BUFF;
					
					if(hasBuff) then
						if(not isCastByPlayer) then
							buffState = E.BUFF_STATE.HAS_BUFF;
						else
							buffState = E.BUFF_STATE.HAS_BUFF_BY_PLAYER;
						end
					end
					
					partyBuffState[category][unit] = {
						state = buffState,
						expiring = willExpireSoon,
						isAura = buffIsAura,
					};
				end
			end
		end
	end
	
	return partyBuffState;
end

-- Buffy:GetPlayerRaidBuffByCategory(1)
function A:GetPlayerRaidBuffByCategory(search_category)
	local _, PLAYER_CLASS = UnitClass("player");
	local PLAYER_SPEC = GetSpecialization();
	
	-- Try to find a spec based list and if not found default to basic list
	local buffs = A:GetClassCastableBuffs(PLAYER_CLASS, PLAYER_SPEC);
	if(not buffs) then return false end
	
	for _, data in ipairs(buffs) do
		if(data.raidbuff) then
			for _, spell in ipairs(data.raidbuff) do
				local spellCategory = BUFF_CATEGORY_BY_SPELL[spell];
				if(not spellCategory) then return nil end
				
				if(bit.band(spellCategory, search_category) > 0 and IsSpellKnown(spell)) then
					return spell;
				end
			end
		end
	end
	
	return nil;
end 

function A:UnitHasSomeBuff(unit, bufflist)
	for _, buff in ipairs(bufflist) do
		if(IsSpellKnown(buff)) then
			local hasBuff, isCastByPlayer, caster, remaining, duration = A:UnitHasBuff(unit, buff);
			if(hasBuff) then
				return true, buff, A:WillBuffExpireSoon(remaining), remaining, duration;
			end
		end
	end
	
	return false, bufflist[1], false, nil, nil;
end

local function IsReallyMounted()
	-- IsMounted() or 
	return IsFlying() or UnitOnTaxi("player") or UnitInVehicle("player");
end

function A:WillBuffExpireSoon(remaining)
	return remaining > 0 and remaining <= self.db.global.ExpirationAlertThreshold;
end

function A:PlayerHasConsumableBuff(consumable_type, preferredStat)
	local hasBuff, consumableID, buffExpiring;
	
	local consumablesList = nil;
	
	if(consumable_type == CONSUMABLE_FLASK) then
		consumablesList = FLASKS;
	elseif(consumable_type == CONSUMABLE_RUNE) then
		consumablesList = RUNES;
	end
	
	if(consumablesList ~= nil and type(consumablesList) == "table") then
		for _, itemID in ipairs(consumablesList[preferredStat]) do
			local spellID = BUFF_ITEM_SPELLS[itemID];
			local hasBuff, _, _, remaining = A:UnitHasBuff("player", spellID);
			if(hasBuff) then
				return true, itemID, spellID, A:WillBuffExpireSoon(remaining);
			end
		end
	end
	
	return false, nil, nil, false;
end

local INSTANCETYPE_RAID 	= 0x1;
local INSTANCETYPE_DUNGEON 	= 0x2;

function A:PlayerInValidDraenorInstance(includeDungeons, includeLFR)
	local includeDungeons = includeDungeons or false;
	if(includeDungeons == nil) then includeDungeons = false end
	
	local includeLFR = includeLFR;
	if(includeLFR == nil) then includeLFR = true end
	
	local name, instanceType, difficultyID, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, mapID, instanceGroupSize = GetInstanceInfo();
	
	if(instanceType ~= "raid" and instanceType ~= "party") then return false end
	if(not includeLFR and (difficultyID == 7 or difficultyID == 17)) then return false end
	
	local instanceMapIDs = {
		[1228] = INSTANCETYPE_RAID, -- Highmaul
		[1205] = INSTANCETYPE_RAID, -- Blackrock Foundry
		[1448] = INSTANCETYPE_RAID, -- Hellfire Citadel
		
		[1182] = INSTANCETYPE_DUNGEON, -- Auchindoun
		[1175] = INSTANCETYPE_DUNGEON, -- Bloodmaul Slag Mines
		[1208] = INSTANCETYPE_DUNGEON, -- Grimrail Depot
		[1195] = INSTANCETYPE_DUNGEON, -- Iron Docks
		[1176] = INSTANCETYPE_DUNGEON, -- Shadowmoon Burial Grounds
		[1209] = INSTANCETYPE_DUNGEON, -- Skyreach
		[1279] = INSTANCETYPE_DUNGEON, -- The Everbloom
		[1358] = INSTANCETYPE_DUNGEON, -- Upper Blackrock Spire
	};
	
	if(instanceMapIDs[mapID] ~= nil) then
		return instanceMapIDs[mapID] == INSTANCETYPE_RAID or (includeDungeons and instanceMapIDs[mapID] == INSTANCETYPE_DUNGEON);
	end
	
	return false;
end

function A:IsPlayerInLFR()
	local name, instanceType, difficultyID = GetInstanceInfo();
	if(instanceType == "raid" and (difficultyID == 7 or difficultyID == 17)) then return true end
	
	return false;
end

function A:FindBestConsumableItem(consumable_type, preferredStat)
	local consumablesList = nil;
	
	if(consumable_type == CONSUMABLE_FLASK) then
		consumablesList = FLASKS;
	elseif(consumable_type == CONSUMABLE_RUNE) then
		consumablesList = RUNES;
	elseif(consumable_type == CONSUMABLE_FOOD) then
		consumablesList = FOODS;
	end
	
	if(consumablesList ~= nil and type(consumablesList) == "table") then
		for _, itemID in ipairs(consumablesList[preferredStat]) do
			local skip = false;
			
			if(consumable_type == CONSUMABLE_FLASK and self.db.global.ConsumablesRemind.OnlyInfiniteFlask and not A:PlayerInInstance() and itemID ~= 118922) then
				skip = true;
			end
			
			if(not skip) then
				local count = GetItemCount(itemID);
				if(count > 0) then
					return itemID, count;
				end
			end
		end
	end
	
	return nil, 0;
end

function A:IsUnitInParty(sourceName)
	if(not sourceName) then return false end
	
	for index, unit in GroupIterator() do
		if(UnitIsUnit(unit, sourceName)) then return true end
	end
	
	return false;
end

function A:COMBAT_LOG_EVENT_UNFILTERED(_, timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)
	-- Check if someone in raid group created something
	if(event == "SPELL_CREATE" and A:IsUnitInParty(sourceName)) then
		local spellId, spellName, spellSchool = ...;
		-- print(timestamp, event, sourceGUID, sourceName, destGUID, destName, ...)
		
		if(FEASTS[spellId] ~= nil) then
			local x, y, _, instance = UnitPosition(sourceName);
			
			A.SummonedFeasts[spellId] = {
				position = { x = x, y = y },
				instance = instance,
				time = GetTime(),
			};
			
			A:UpdateBuffs();
		end
	end
end

function A:GetPlayerDistanceToPoint(pinstance, px, py)
	local x, y, _, instance = UnitPosition("player");
	return instance == pinstance and (((px - x) ^ 2 + (py - y) ^ 2) ^ 0.5) / 1.098;
end

function A:IsFeastUp()
	for _, data in pairs(A.SummonedFeasts) do
		return true;
	end
	
	return false;
end

function A:IsSpellAura(spell)
	if(not spell) then return end
	return AURA_BUFFS[spell] or false;
end

A.LastBuffsUpdate = 0;
function A:ShouldDoUpdate()
	return not InCombatLockdown() or debugprofilestop() >= A.LastBuffsUpdate + 950;
end

function A:UpdateBuffs(forceUpdate)
	if(A:ShouldDoUpdate() or forceUpdate) then
		A:UpdateDatabrokerText();
	elseif(InCombatLockdown()) then
		return;
	end
	
	A.LastBuffsUpdate = debugprofilestop();
	
	if(not self.db.global.ShowInCombat and InCombatLockdown()) then
		A:HideBuffyAlert();
		return;
	end
	
	local inInstance, instanceType = A:PlayerInInstance();
	
	local hideAlert = not self.db.global.Enabled or UnitIsDeadOrGhost("player") or
					  (self.db.global.DisableOutside and not inInstance) or
					  (self.db.global.DisableWhenResting and IsResting()) or
					  (not self.db.global.ShowWhileMounted and IsReallyMounted()) or
					  C_PetBattles.IsInBattle();
	
	if(hideAlert) then
		A:HideBuffyAlert();
		return;
	end
	
	local canShowExpiration = not InCombatLockdown() or (InCombatLockdown() and not self.db.global.NoExpirationAlertInCombat);
	
	local _, PLAYER_CLASS = UnitClass("player");
	local PLAYER_SPEC = GetSpecialization();
	local PLAYER_LEVEL = UnitLevel("player");
	
	-- Try to find a spec based list and if not found default to basic list
	local buffs = A:GetClassCastableBuffs(PLAYER_CLASS, PLAYER_SPEC);
	if(not buffs) then return false end
	
	local playerCastExists = false;
	local shouldCastSpell = false;
	local castSpellID;
	
	local infoUnits = {};
	
	for _, data in ipairs(buffs) do
		local valid = true;
		
		if(data.hasTalent) then
			valid = valid and A:PlayerHasTalent(data.hasTalent[1], data.hasTalent[2]);
		end
		
		if(data.noTalent) then
			valid = valid and not A:PlayerHasTalent(data.noTalent[1], data.noTalent[2]);
		end
		
		if(data.condition and type(data.condition) == "function") then
			valid = valid and data.condition();
		end
		
		if(valid) then
			if(data.raidbuff) then
				local buffStates = A:ScanBuffList(data.raidbuff);
				
				local playerBuffCategory = 0;
				local playerBuffExists = false;
				local playerBuffExpiring = false;
				local playerBuffIsAura = false;
				
				local someoneHasAuraOnly = false;
				local numUnitsHasAura = 0;
				
				for category, unitBuffs in pairs(buffStates) do
					for unit, buffState in pairs(unitBuffs) do
						if(buffState.state == E.BUFF_STATE.HAS_BUFF_BY_PLAYER) then
							playerBuffExists = true;
							playerBuffCategory = category;
							
							playerBuffExpiring = buffState.expiring;
							someoneHasAuraOnly = buffState.isAura;
							playerBuffIsAura = buffState.isAura;
							
							break;
						elseif(buffState.state == E.BUFF_STATE.HAS_BUFF) then
							someoneHasAuraOnly = buffState.isAura or someoneHasAuraOnly;
							
							if(someoneHasAuraOnly) then
								numUnitsHasAura = numUnitsHasAura + 1;
							end
						end
					end
					
					if(playerBuffExists) then break end
				end
				
				local buffCategory = 0;
				local everybodyHasBuff = true;
				
				if(playerBuffExists) then
					for unit, buffState in pairs(buffStates[playerBuffCategory]) do
						if((not playerBuffIsAura and buffState.state ~= E.BUFF_STATE.HAS_BUFF_BY_PLAYER) or (playerBuffIsAura and buffState.state == E.BUFF_STATE.NO_BUFF)) then
							everybodyHasBuff = false;
							buffCategory = playerBuffCategory;
							infoUnits[unit] = unit;
						end
					end
					
					if(not everybodyHasBuff) then
						for category, unitBuffs in pairs(buffStates) do
							if(category ~= buffCategory) then
								for unit, buffState in pairs(unitBuffs) do
									if((not playerBuffIsAura and buffState.state == E.BUFF_STATE.HAS_BUFF_BY_PLAYER) or (playerBuffIsAura and (buffState.state == E.BUFF_STATE.HAS_BUFF or buffState.state == E.BUFF_STATE.HAS_BUFF_BY_PLAYER))) then
										infoUnits[unit] = nil;
									end
								end
							end
						end
						
						local unitsMissing = 0;
						for _, _ in pairs(infoUnits) do
							unitsMissing = unitsMissing + 1;
						end
						
						if(unitsMissing == 0) then
							everybodyHasBuff = true;
						end
					end
				else
					for category, unitBuffs in pairs(buffStates) do
						for unit, buffState in pairs(unitBuffs) do
							if(buffState.state == E.BUFF_STATE.NO_BUFF) then
								everybodyHasBuff = false;
								buffCategory = category;
								infoUnits[unit] = unit;
							elseif(buffState.state == E.BUFF_STATE.HAS_BUFF and buffState.isAura and not A:UnitHasNonAuraCategoryBuff(unit, category)) then
								buffCategory = category;
								infoUnits[unit] = unit;
							end
						end
						
						if(not everybodyHasBuff) then break end
					end
				end
				
				if(not everybodyHasBuff) then
					local buffSpell = A:GetPlayerRaidBuffByCategory(buffCategory);
					
					local units = {};
					for unit, _ in pairs(infoUnits) do
						tinsert(units, unit);
					end
					
					A:ShowBuffyAlert(ALERT_TYPE_SPELL, buffSpell, {
						units = units,
						category = buffCategory,
						expiring = playerBuffExpiring,
						remaining = A:GetBuffRemaining("player", buffSpell),
					});
					
					return;
				elseif(self.db.global.OverrideAuras and someoneHasAuraOnly and buffCategory ~= 0) then
					local buffSpell = A:GetPlayerRaidBuffByCategory(buffCategory);
					
					if(buffSpell and not A:IsSpellAura(buffSpell)) then
						local units = {};
						for unit, _ in pairs(infoUnits) do
							tinsert(units, unit);
						end
						
						A:ShowBuffyAlert(ALERT_TYPE_SPELL, buffSpell, {
							category = buffCategory,
							auraAlert = true,
							units = units,
						});
						return;
					end
				elseif(playerBuffExpiring and canShowExpiration) then
					local buffSpell = A:GetPlayerRaidBuffByCategory(playerBuffCategory);
					
					A:ShowBuffyAlert(ALERT_TYPE_SPELL, buffSpell, {
						category = playerBuffCategory,
						expiring = playerBuffExpiring,
						remaining = A:GetBuffRemaining("player", buffSpell),
					});
					return;
				end
			end
			
			if(data.selfbuff and not UnitIsDeadOrGhost("player")) then
				if(type(data.selfbuff) == "function") then
					local shouldAlert, buffSpell = data.selfbuff();
					
					if(data.skipBuffCheck or shouldAlert and IsSpellKnown(buffSpell)) then
						local alertType = ALERT_TYPE_SPELL;
						local alertID = buffSpell;
						
						if(data.info) then
							if(data.info.type == "item" or data.info.type == "toy") then
								alertType = ALERT_TYPE_ITEM;
							elseif(data.info.type == "spell") then
								alertType = ALERT_TYPE_SPELL;
							end
							
							alertID = data.info.id;
						end
							
						A:ShowBuffyAlert(alertType, alertID, {
							primary = data.primary,
							secondary = data.secondary,
							description = data.description,
							info = data.info,
						});
						return;
					end
				else
					local hasBuff, buffSpell, buffExpiring = A:UnitHasSomeBuff("player", data.selfbuff);
					
					if(data.skipBuffCheck or (not hasBuff or (buffExpiring and canShowExpiration)) and IsSpellKnown(buffSpell)) then
						A:ShowBuffyAlert(ALERT_TYPE_SPELL, buffSpell, {
							primary = data.primary,
							secondary = data.secondary,
							description = data.description,
							info = data.info,
							expiring = buffExpiring,
							remaining = A:GetBuffRemaining("player", buffSpell),
						});
						
						return;
					end
				end
			end
		end
	end
	
	-- Clear binds before flask remind since user may not have keybinds enabled
	A:ClearTempBind();
	
	--------------------------------------------------
	-- Consumables check
	
	local canShowConsumableAlert = not InCombatLockdown() or not self.db.global.ConsumablesRemind.NotInCombat;
	if(canShowConsumableAlert and self.db.global.ConsumablesRemind.Enabled and PLAYER_LEVEL >= 90) then
		local inValidInstance;
		if(self.db.global.ConsumablesRemind.Mode == E.RAID_CONSUMABLES.EVERYWHERE) then
			inValidInstance = true;
		else
			local enableDungeons = self.db.global.ConsumablesRemind.Mode == E.RAID_CONSUMABLES.RAIDS_AND_DUNGEONS;
			inValidInstance = A:PlayerInValidDraenorInstance(enableDungeons, not self.db.global.ConsumablesRemind.DisableInLFR);
		end
		
		if(self.db.global.ConsumablesRemind.DisableInLFR and A:IsPlayerInLFR()) then
			inValidInstance = false;
		end
		
		local inValidGroup = not self.db.global.ConsumablesRemind.DisableOutsideGroup or (IsInGroup() or IsInRaid());
		
		if(inValidInstance and inValidGroup) then
			local preferredStats = A:GetStatPreference(PLAYER_CLASS, PLAYER_SPEC);
			
			if(self.db.global.ConsumablesRemind.Flasks) then
				-- Loop through preferred stat types
				for _, preferredStat in ipairs(preferredStats) do
					local playerHasFlask, itemID, spellID, buffExpiring = A:PlayerHasConsumableBuff(CONSUMABLE_FLASK, preferredStat);
					
					if(not playerHasFlask or (buffExpiring and canShowExpiration)) then
						-- Check if player has any flasks in their inventory
						local bestFlaskID, count = A:FindBestConsumableItem(CONSUMABLE_FLASK, preferredStat);
						
						local isInfiniteFlask = (bestFlaskID == 118922);
						local cooldownExpired = true;
						
						-- Cooldown check for the non-consumable "flask" which has one
						if(isInfiniteFlask) then
							local startTime, duration = GetItemCooldown(bestFlaskID);
							cooldownExpired = (startTime == 0 and duration == 0);
							
							-- Reset count since the "crystal flask" is not consumed
							count = nil;
						end
						
						if(bestFlaskID and cooldownExpired) then
							A:ShowBuffyAlert(ALERT_TYPE_ITEM, bestFlaskID, {
								spellID = spellID,
								expiring = buffExpiring,
								count = count,
								remaining = A:GetBuffRemaining("player", spellID),
							});
							return;
						end
					end
					
					if(playerHasFlask and not buffExpiring) then break end
				end
			end
			
			if(self.db.global.ConsumablesRemind.Runes and PLAYER_LEVEL >= 100 and not C_Scenario.IsChallengeMode()) then
				local checkForRunes = true;
				if(self.db.global.ConsumablesRemind.OnlyInfiniteRune and GetItemCount(128482) == 0 and GetItemCount(128475) == 0) then
					checkForRunes = false;
				end
				
				if(checkForRunes) then
					-- Loop through preferred stat types
					for _, preferredStat in ipairs(preferredStats) do
						-- There are no stamina runes, skip!
						if(preferredStat ~= E.STAT.STAMINA) then
							local playerHasRune, itemID, spellID, buffExpiring = A:PlayerHasConsumableBuff(CONSUMABLE_RUNE, preferredStat);
							
							if(not playerHasRune or (buffExpiring and canShowExpiration)) then
								-- Check if player has any runes in their inventory
								local bestRuneID, count = A:FindBestConsumableItem(CONSUMABLE_RUNE, preferredStat);
								
								local isInfiniteRune = (bestRuneID == 128482 or bestRuneID == 128475);
								local cooldownExpired = true;
								
								-- Cooldown check for the non-consumable rune which has one
								if(isInfiniteRune) then
									local startTime, duration = GetItemCooldown(bestRuneID);
									cooldownExpired = (startTime == 0 and duration == 0);
									
									-- Reset count since infinite rune is not consumed
									count = nil;
								end
								
								if(bestRuneID and cooldownExpired) then
									A:ShowBuffyAlert(ALERT_TYPE_ITEM, bestRuneID, {
										spellID = spellID,
										expiring = buffExpiring,
										count = count,
										remaining = A:GetBuffRemaining("player", spellID),
									});
									return;
								end
							end
						
							if(playerHasRune and not buffExpiring) then break end
						end
					end
				end
			end
			
			local isEating, timeEaten = A:IsPlayerEating();
			
			if(self.db.global.ConsumablesRemind.Food) then
				local isWellFed, buffExpiring, spellID = A:IsPlayerWellFed();
				
				if(not isEating and (not isWellFed or (buffExpiring and canShowExpiration))) then
					local showInventoryFoodAlert = self.db.global.ConsumablesRemind.FeastsMode == E.FEASTS_MODE.OWN_FOOD or
												   (not A:IsFeastUp() and self.db.global.ConsumablesRemind.FeastsMode == E.FEASTS_MODE.PRIORITY_FEASTS);
					
					if(showInventoryFoodAlert) then
						local preferredFoodStats = A:GetFoodPreference();
						
						-- Loop through preferred stat types
						for _, preferredStat in ipairs(preferredFoodStats) do
							-- Check if player has any food in their inventory
							local bestFoodID, count = A:FindBestConsumableItem(CONSUMABLE_FOOD, preferredStat);
							
							if(bestFoodID) then
								A:ShowBuffyAlert(ALERT_TYPE_ITEM, bestFoodID, {
									spellID = spellID,
									expiring = buffExpiring,
									count = count,
									primary = "Eat",
									remaining = A:GetBuffRemaining("player", spellID),
								});
								return;
							end
						end
					end
					
					if(A:IsFeastUp() and PLAYER_LEVEL >= 91) then
						local sorted_feasts = {};
						for spell, data in pairs(A.SummonedFeasts) do
							local tableExpires = (data.time + FEASTS[spell].duration) - GetTime();
							
							if(tableExpires > 0) then
								local feastRange = A:GetPlayerDistanceToPoint(data.instance, data.position.x, data.position.y);
								if(feastRange and feastRange <= 75) then
									tinsert(sorted_feasts, { spell = spell, stats = FEASTS[spell].stats, range = feastRange, });
								end
							else
								A.SummonedFeasts[spell] = nil;
							end
						end
						
						if(#sorted_feasts > 0) then
							table.sort(sorted_feasts, function(a, b)
								if(a == nil and b == nil) then return false end
								if(a == nil) then return true end
								if(b == nil) then return false end
								
								return a.stats > b.stats;
							end);
							
							local spellId = sorted_feasts[1].spell;
							-- local range = sorted_feasts[1].range;
							
							local feast = A.SummonedFeasts[spellId];
							local data = FEASTS[spellId];
							
							local tableExpires = (feast.time + data.duration) - GetTime();
							
							local description = string.format("Feast Expires in %s", A:FormatTime(tableExpires));
							local itemName, _, _, _, _, _, _, _, _, icon = GetItemInfo(data.item);
							
							A:ShowBuffyAlert(ALERT_TYPE_SPECIAL, SPECIAL_FOOD, {
								primary = "Eat",
								secondary = string.format("Nearby %s", itemName or "Feast"),
								icon = icon,
								description = description,
							});
							return;
						end
					end
				end
			end
			
			if(isEating and timeEaten <= 10 and self.db.global.ConsumablesRemind.EatingTimer) then
				A:ShowBuffyAlert(ALERT_TYPE_SPECIAL, SPECIAL_EATING, {
					icon = "Interface\\Icons\\inv_misc_fork&knife",
					primary = "Eating...",
					secondary = "Nom nom nom!",
					description = string.format("Well Fed in |cfff1da54%d|r seconds", 10 - timeEaten),
				});
				return;
			end
		end
	end
	
	--------------------------------------------------
	-- Miscellaneous low priority selfbuffs
	
	for _, data in ipairs(MISC_CASTABLE_BUFFS) do
		local valid = true;
		
		if(data.hasTalent) then
			valid = valid and A:PlayerHasTalent(data.hasTalent[1], data.hasTalent[2]);
		end
		
		if(data.noTalent) then
			valid = valid and not A:PlayerHasTalent(data.noTalent[1], data.noTalent[2]);
		end
		
		if(data.condition and type(data.condition) == "function") then
			valid = valid and data.condition();
		end
		
		if(valid and data.selfbuff and not UnitIsDeadOrGhost("player")) then
			if(type(data.selfbuff) == "function") then
				local shouldAlert, buffSpell = data.selfbuff();
				
				if(data.skipBuffCheck or shouldAlert and IsSpellKnown(buffSpell)) then
					local alertType = ALERT_TYPE_SPELL;
					local alertID = buffSpell;
					
					if(data.info) then
						if(data.info.type == "item" or data.info.type == "toy") then
							alertType = ALERT_TYPE_ITEM;
						elseif(data.info.type == "spell") then
							alertType = ALERT_TYPE_SPELL;
						end
						
						alertID = data.info.id;
					end
						
					A:ShowBuffyAlert(alertType, alertID, {
						primary = data.primary,
						secondary = data.secondary,
						description = data.description,
						info = data.info,
					});
					return;
				end
			else
				local hasBuff, buffSpell, buffExpiring = A:UnitHasSomeBuff("player", data.selfbuff);
				
				if(data.skipBuffCheck or (not hasBuff or (buffExpiring and canShowExpiration)) and IsSpellKnown(buffSpell)) then
					A:ShowBuffyAlert(ALERT_TYPE_SPELL, buffSpell, {
						primary = data.primary,
						secondary = data.secondary,
						description = data.description,
						info = data.info,
						expiring = buffExpiring,
						remaining = A:GetBuffRemaining("player", buffSpell),
					});
					
					return;
				end
			end
		end
	end
	
	if(not self.IsFrameLocked) then
		A:ShowBuffyAlert(ALERT_TYPE_SPECIAL, SPECIAL_UNLOCKED, {
			icon = "Interface\\Icons\\ability_garrison_orangebird",
			primary = "Buffy",
			secondary = "The frame is currently unlocked",
			description = "Right-click to view options",
		});
		return;
	end
	
	A:HideBuffyAlert();
end

function A:GetBuffRemaining(unit, spellID)
	if(not unit or not spellID) then return 0 end
	
	local realSpellID = A:GetRealSpellID(spellID);
	local spellName = GetSpellInfo(realSpellID);
	
	local name, _, _, _, _, _, expirationTime = UnitAura(unit, spellName, nil, "HELPFUL");
	if(name) then
		return expirationTime - GetTime();
	end
	
	return 0;
end

function A:FormatTime(t, literal)
	if(not t or not tonumber(t)) then return tostring(t) end
	
	local t = math.floor(t);
	
	local seconds = t % 60;
	local minutes = math.floor(t / 60);
	
	local timestr = "";
	
	local M  = "%d|cfff1da54m|r";
	local  S = "%d|cfff1da54s|r";
	local MS = string.format("%s %s", M, S);
	
	if(literal) then
		M  = "%d minute" .. (minutes ~= 1 and "s" or "");
		 S = "%d second" .. (seconds ~= 1 and "s" or "");
		
		MS = string.format("%s %s", M, S);
	end
	
	if(minutes > 0 and seconds == 0 and literal) then
		return string.format(M, minutes);
	elseif(minutes > 0) then
		return string.format(MS, minutes, seconds);
	else
		return string.format(S, seconds);
	end
end

function A:ShowBuffyAlert(alert_type, id, data)
	if(not id) then return end
	
	SBA = { alert_type, id, data };
	
	local doAnimatedSwitch = false;
	local alertSignature = alert_type .. "@" .. id;
	
	if(A.CurrentAlert ~= alertSignature and BuffyFrame:IsShown()) then
		A:CopyAlertToSwitchFrame();
		doAnimatedSwitch = true;
	end
	
	A.CurrentAlert = alertSignature;
	
	A.ShowingAlert = true;
	BuffyFrame.Tooltip = nil;
	
	local _;
	local name, icon;
	
	if(data.info and not data.noCast) then
		name, _, _, _, _, _, _, _, _, icon = GetItemInfo(data.info.id);
		BuffyFrame.icon.texture:SetTexture(icon);
		
		BuffyFrame.Tooltip = {
			type = ALERT_TYPE_ITEM,
			id = data.info.id,
		};
		
		if(not InCombatLockdown() and not data.noCast) then
			A:SetTempBind(data.info.type, data.info.id);
		end
		
		BuffyFrame.title:SetFormattedText("|cfff1da54%s|r|n%s", data.primary or "Use", data.secondary or name or "<Error>");
	elseif(alert_type == ALERT_TYPE_SPELL) then
		local realSpellID = A:GetRealSpellID(id);
		name, _, icon = GetSpellInfo(realSpellID);
		BuffyFrame.icon.texture:SetTexture(icon);
		
		BuffyFrame.Tooltip = {
			type = ALERT_TYPE_SPELL,
			id = realSpellID,
		};
		
		if(not InCombatLockdown() and not data.noCast) then
			A:SetTempBind("spell", name);
		end
		
		BuffyFrame.title:SetFormattedText("|cfff1da54%s|r|n%s", data.primary or "Cast", data.secondary or name or "<Error>");
	elseif(alert_type == ALERT_TYPE_ITEM) then
		name, _, _, _, _, _, _, _, _, icon = GetItemInfo(id);
		BuffyFrame.icon.texture:SetTexture(icon);
		
		BuffyFrame.Tooltip = {
			type = ALERT_TYPE_ITEM,
			id = id,
		};
		
		if(not InCombatLockdown() and self.db.global.ConsumablesRemind.KeybindEnabled and not data.noCast) then
			A:SetTempBind("item", name);
		end
		
		BuffyFrame.title:SetFormattedText("|cfff1da54%s|r|n%s", data.primary or "Use", data.secondary or name or "<Error>");
	end
	
	BuffyFrame.description:SetText("");
	BuffyFrame.description:Hide();
	
	if(data) then
		if(alert_type == ALERT_TYPE_SPECIAL) then
			BuffyFrame.icon.texture:SetTexture(data.icon);
			BuffyFrame.title:SetFormattedText("|cfff1da54%s|r|n%s", data.primary or "", data.secondary or "");
		end
		
		if(not data.expiring and data.units and A:GetGroupType() ~= E.GROUP_TYPE.SOLO and data.category and not data.auraAlert) then
			local numUnits = #data.units;
			BuffyFrame.description:SetFormattedText("%d player%s missing %s", numUnits, numUnits == 1 and "" or "s", E.BUFF_TYPE_NAMES[data.category]);
			BuffyFrame.description:Show();
		elseif(data.expiring and data.remaining) then
			if(alert_type == ALERT_TYPE_ITEM and tonumber(data.count)) then
				BuffyFrame.description:SetFormattedText("Expiring in %s / You have |cfff1da54%d|r", A:FormatTime(data.remaining), data.count);
			else
				BuffyFrame.description:SetFormattedText("Expiring in %s", A:FormatTime(data.remaining));
			end
			BuffyFrame.description:Show();
		elseif(data.auraAlert) then
			local numUnits = #data.units;
			if(numUnits == 1) then
				BuffyFrame.description:SetFormattedText("1 player only has an |cff37dcffaura|r for %s", E.BUFF_TYPE_NAMES[data.category]);
			else
				BuffyFrame.description:SetFormattedText("%d players only have an |cff37dcffaura|r for %s", numUnits, E.BUFF_TYPE_NAMES[data.category]);
			end
			
			BuffyFrame.description:Show();
		elseif(alert_type == ALERT_TYPE_ITEM and tonumber(data.count)) then
			BuffyFrame.description:SetFormattedText("You have |cfff1da54%d|r in your inventory", tonumber(data.count));
			BuffyFrame.description:Show();
		elseif(data.description) then
			local text;
			if(type(data.description) == "function") then
				text = data.description();
			else
				text = data.description;
			end
			BuffyFrame.description:SetText(text);
			BuffyFrame.description:Show();
		end
	end
	
	if(not BuffyFrame:IsShown()) then
		BuffyFrame.fadein:Play();
		
		if(A.PlayerIsMoving) then
			A:PLAYER_STARTED_MOVING();
		end
	end
	
	if(doAnimatedSwitch) then
		A:PlayAnimatedSwitch();
	end
end

function A:CopyAlertToSwitchFrame()
	local icon = BuffyFrame.icon.texture:GetTexture();
	local title = BuffyFrame.title:GetText();
	local description = BuffyFrame.description:GetText();
	
	if(icon) then
		BuffySwitchAnimationFrame.icon.texture:SetTexture(icon);
	end
	
	if(title) then
		BuffySwitchAnimationFrame.text.title:SetText(title);
	else
		BuffySwitchAnimationFrame.text.title:SetText("");
	end
	
	if(description) then
		BuffySwitchAnimationFrame.text.description:SetText(description);
	else
		BuffySwitchAnimationFrame.text.description:SetText("");
	end
	
	BuffySwitchAnimationFrame:SetAlpha(BuffyFrame:GetAlpha());
end

function A:PlayAnimatedSwitch()
	local alpha = BuffyFrame:GetAlpha();
	
	local animation = BuffyFrame.fadeinex:GetAnimations();
	animation:SetToAlpha(alpha);
	BuffyFrame.fadeinex:Play();
	
	BuffySwitchAnimationFrame:Show();
	
	animation = BuffySwitchAnimationFrame.fadeout:GetAnimations();
	animation:SetFromAlpha(alpha);
	BuffySwitchAnimationFrame.fadeout:Play();
end

function BuffyIconFrame_OnEnter(self)
	if(InCombatLockdown()) then return end
	if(not A.db.global.ShowTooltips) then return end
	if(not BuffyFrame.Tooltip) then return end
	
	GameTooltip:SetOwner(self, "ANCHOR_PRESERVE");
	GameTooltip:ClearAllPoints();
	GameTooltip:SetPoint("RIGHT", self, "LEFT", -6, 0);
	
	if(BuffyFrame.Tooltip.type == ALERT_TYPE_SPELL) then
		GameTooltip:SetSpellByID(BuffyFrame.Tooltip.id);
	elseif(BuffyFrame.Tooltip.type == ALERT_TYPE_ITEM) then
		GameTooltip:SetItemByID(BuffyFrame.Tooltip.id);
	end
	
	GameTooltip:Show();
	
	BuffyFrame.ShowingTip = true;
end

function BuffyIconFrame_OnLeave(self)
	GameTooltip:Hide();
	
	BuffyFrame.ShowingTip = false;
end

function A:HideBuffyAlert()
	A.ShowingAlert = false;
	BuffyFrame.Tooltip = nil;
	
	if(BuffyFrame.ShowingTip) then
		GameTooltip:Hide();
	end
	
	if(not InCombatLockdown()) then
		BuffySpellButtonFrame:SetAttribute("type1", nil);
		A:ClearTempBind();
	end
	
	if(BuffyFrame:IsShown()) then
		local alpha = BuffyFrame:GetAlpha();
		local animation = BuffyFrame.fadeout:GetAnimations();
		animation:SetFromAlpha(alpha);
		
		BuffyFrame.fadeout:Play();
	end
end

function A:PlayerInInstance()
	local name, instanceType = GetInstanceInfo();
	
	if(instanceType == "none" or C_Garrison.IsOnGarrisonMap()) then
		return false;
	end
	
	return true, instanceType;
end

function BuffyFrame_OnShow(self)
	local scale = UIParent:GetEffectiveScale();
	self:SetScale(1.0 / scale * 0.92);
	BuffySwitchAnimationFrame:SetScale(1.0 / scale * 0.92);
	
	BuffyFrame_RestorePosition();
	
	-- self:ClearAllPoints();
	-- self:SetPoint("LEFT", UIParent, "CENTER", -22, GetScreenHeight() * 0.18);
end


function BuffyFrame_OnMouseDown(self, button)
	if(A.IsFrameLocked) then return end
	
	if(button == "LeftButton") then
		CloseMenus();
		
		BuffyFrame:StartMoving();
		BuffyFrame:SetUserPlaced(false);
		BuffyFrame.IsMoving = true;
	end
end

function BuffyFrame_OnMouseUp()
	if(BuffyFrame.IsMoving) then
		BuffyFrame:StopMovingOrSizing();
		BuffyFrame.IsMoving = false;
		BuffyFrame_SavePosition();
	end
end

function BuffyFrame_SavePosition()
	local point, _, relativePoint, x, y = BuffyFrame:GetPoint();
	
	A.db.global.Position = {
		x = x,
		y = y,
		Point = point,
		RelativePoint = relativePoint,
		DefaultPosition = false,
	};
end

function BuffyFrame_RestorePosition()
	BuffyFrame:ClearAllPoints();
	
	if(not A.db.global or A.db.global.Position.DefaultPosition) then
		BuffyFrame:SetPoint("LEFT", UIParent, "CENTER", -22, GetScreenHeight() * 0.18);
	else
		local p = A.db.global.Position;
		BuffyFrame:SetPoint(p.Point, UIParent, p.RelativePoint, p.x, p.y);
	end
end

function BuffyFrame_ResetPosition()
	BuffyFrame:ClearAllPoints();
	BuffyFrame:SetPoint("LEFT", UIParent, "CENTER", -22, GetScreenHeight() * 0.18);
	
	local point, _, relativePoint, x, y = BuffyFrame:GetPoint();
	
	A.db.global.Position = {
		x = x,
		y = y,
		Point = point,
		RelativePoint = relativePoint,
		DefaultPosition = true,
	};
	
	BuffyFrame_RestorePosition();
end

function A:ResetPosition()
	BuffyFrame_ResetPosition();
end

local MESSAGE_PATTERN = "|cff3ebfeaBuffy|r %s";
function A:AddMessage(pattern, ...)
	DEFAULT_CHAT_FRAME:AddMessage(MESSAGE_PATTERN:format(string.format(pattern, ...)));
end

function A:GetBinding()
	return A.db.global.Keybind;
end

function A:SetTempBind(bindType, name)
	if(not bindType or not name) then return end
	if(InCombatLockdown()) then return end
	
	if(self.db.global.UnbindWhenMoving and A.PlayerIsMoving) then return end
	
	local key = A:GetBinding();
	if(key) then
		BuffySpellButtonFrame:SetAttribute("type1", bindType);
		
		if(bindType == "item" or bindType == "spell" or bindType == "toy") then
			BuffySpellButtonFrame:SetAttribute(bindType .. "1", name);
		end
		
		BuffySpellButtonFrame:SetAttribute("unit", "player");
		
		SetOverrideBindingClick(BuffyFrame, true, key, "BuffySpellButtonFrame", "LeftButton");
		
		A.LastTempBind = {bindType, name};
	end
end

function A:RestoreLastTempBind()
	if(not A.LastTempBind) then return end
	
	A:SetTempBind(unpack(A.LastTempBind));
end

function A:ClearTempBind()
	if(not InCombatLockdown()) then
		ClearOverrideBindings(BuffyFrame);
	end
end

function BuffyKeybindingFrame_OnShow()
	BuffyKeybindingFrame.bindkey = A:GetBinding();
	
	if(not BuffyKeybindingFrame.bindkey) then
		BuffyKeybindingFrame.currentBinding:SetText(BUFFY_CHOOSE_BINDING_TEXT);
	else
		BuffyKeybindingFrame.currentBinding:SetText(BuffyKeybindingFrame.bindkey);
	end
end

function BuffyKeybindingFrame_OnKeydown(self, key)
	if(key == "ESCAPE") then
		BuffyKeybindingFrameOuter:Hide();
	end
	
	if(strfind(key, "SHIFT") or strfind(key, "CTRL") or strfind(key, "ALT")) then
		return;
	end
	
	if(IsShiftKeyDown()) then key = "SHIFT-" .. key; end
	if(IsControlKeyDown()) then key = "CTRL-" .. key; end
	if(IsAltKeyDown()) then key = "ALT-" .. key; end
	
	BuffyKeybindingFrame.bindkey = key;
	BuffyKeybindingFrame.currentBinding:SetText(key);
end

function BuffyKeybindingFrame_OnMouseWheel(self, delta)
	if(delta >= 1) then
		BuffyKeybindingFrame_OnKeydown(self, "MOUSEWHEELUP");
	elseif(delta <= -1) then
		BuffyKeybindingFrame_OnKeydown(self, "MOUSEWHEELDOWN");
	end
end

function BuffyKeybindingFrame_OnMouseDown(self, button)
	if(button == "LeftButton") then
		BuffyKeybindingFrame_OnKeydown(self, "BUTTON1");
	elseif(button == "RightButton") then
		BuffyKeybindingFrame_OnKeydown(self, "BUTTON2");
	elseif(button == "MiddleButton") then
		BuffyKeybindingFrame_OnKeydown(self, "BUTTON3");
	else
		BuffyKeybindingFrame_OnKeydown(self, button);
	end
end

function BuffyKeybindingFrameAcceptButton_OnClick()
	if(A:GetBinding()) then A:ClearTempBind(); end
	
	A.db.global.Keybind = BuffyKeybindingFrame.bindkey;
	A:UpdateBuffs();
	
	BuffyKeybindingFrameOuter:Hide();
end

function BuffySpellButtonFrame_OnClick()
	if(InCombatLockdown()) then
		A:AddMessage("Cannot cast recommended buff while in combat");
	end
end

function BuffyFrame_OnClick(self, button)
	if(button == "RightButton") then
		A:OpenContextMenu(BuffyFrame);
	end
end

function BuffyFrame_OnFadeInPlay(self)
	BuffyFrame:Show();
end

function BuffyFrame_OnFadeOutFinished(self)
	BuffyFrame:Hide();
end
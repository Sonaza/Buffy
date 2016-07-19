------------------------------------------------------------
-- Buffy by Sonaza
------------------------------------------------------------

local ADDON_NAME, Addon = ...;
local LE = Addon.LE;
local _;

-- Text Strings
BUFFY_SET_BINDING_TEXT 		= "|cffeed028Set Buffy Cast Keybind|r";
BUFFY_CHOOSE_BINDING_TEXT	= "Choose a Binding";
BUFFY_PRESS_BUTTON_TEXT		= "Press a key to use it as the binding";
BUFFY_TEMPORARY_BIND_TEXT	= "Buffy will set a temporary binding when required and you can use any key you want without overwriting existing ones."
BUFFY_CANCEL_BINDING_TEXT 	= "Press Escape to Cancel";
BUFFY_ACCEPT_TEXT			= "Save"

-- Enums
LE.STAT = {
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

LE.RATING_NAMES = {
	[LE.STAT.STAMINA]		= "Stamina",
	[LE.STAT.HASTE]			= "Haste",
	[LE.STAT.MASTERY]		= "Mastery",
	[LE.STAT.CRIT]			= "Crit",
	[LE.STAT.VERSATILITY]	= "Versatility",
};

LE.RATING_IDENTIFIERS = {
	[LE.STAT.HASTE]			= function()
		return GetCombatRatingBonus(CR_HASTE_SPELL);
	end,
	[LE.STAT.MASTERY]		= function()
		local mastery, bonusCoeff = GetMasteryEffect();
		return GetCombatRatingBonus(CR_MASTERY) * bonusCoeff;
	end,
	[LE.STAT.CRIT]			= function()
		return GetCombatRatingBonus(CR_CRIT_SPELL);
	end,
	[LE.STAT.VERSATILITY]	= function()
		return GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE);
	end,
};

LE.BUFF_SPECIAL			= 0xFFF;

LE.CONSUMABLE_FLASK		= 0x01;
LE.CONSUMABLE_RUNE		= 0x02;
LE.CONSUMABLE_FOOD		= 0x03;

LE.ALERT_TYPE_SPELL		= 0x01;
LE.ALERT_TYPE_ITEM		= 0x02;
LE.ALERT_TYPE_SPECIAL	= 0xFF;

LE.SPECIAL_FOOD			= 0x1;
LE.SPECIAL_EATING		= 0x2;
LE.SPECIAL_UNLOCKED		= 0x3;

-----------------------------------------------------------------
-- Buff spells

Addon:AddBuffSpell(2823,	LE.BUFF_SPECIAL, "ROGUE_DEADLY_POISON");
Addon:AddBuffSpell(8679, 	LE.BUFF_SPECIAL, "ROGUE_WOUND_POISON");
Addon:AddBuffSpell(200802, 	LE.BUFF_SPECIAL, "ROGUE_AGONIZING_POISON");
Addon:AddBuffSpell(3408, 	LE.BUFF_SPECIAL, "ROGUE_CRIPPLING_POISON");
Addon:AddBuffSpell(108211,	LE.BUFF_SPECIAL, "ROGUE_LEECHING_POISON");

Addon:AddBuffSpell(20707,	LE.BUFF_SPECIAL, "WARLOCK_SOULSTONE");
Addon:AddBuffSpell(108503,	LE.BUFF_SPECIAL, "WARLOCK_GRIMOIRE_OF_SACRIFICE");
Addon:AddBuffSpell(196099,	LE.BUFF_SPECIAL, "WARLOCK_GRIMOIRE_OF_SACRIFICE_EFFECT");

Addon:AddBuffSpell(5487,	LE.BUFF_SPECIAL, "DRUID_BEAR_FORM");
Addon:AddBuffSpell(768,		LE.BUFF_SPECIAL, "DRUID_CAT_FORM");
Addon:AddBuffSpell(24858,	LE.BUFF_SPECIAL, "DRUID_MOONKIN_FORM");

Addon:AddBuffSpell(181943,	LE.BUFF_SPECIAL, "PEPE");

local function CanPoisonWeapons()
	local mainhand = GetInventoryItemLink("player", 16);
	local mhSlot = mainhand and select(9, GetItemInfo(mainhand)) or "";
	
	local offhand = GetInventoryItemLink("player", 17);
	local ohSlot = offhand and select(9, GetItemInfo(offhand)) or "";
	
	return mhSlot == "INVTYPE_WEAPON" or mhSlot == "INVTYPE_WEAPONMAINHAND" or
		   ohSlot == "INVTYPE_WEAPON" or ohSlot == "INVTYPE_WEAPONOFFHAND";
end

LE.DRUID_FORM = {
	BEAR 	= 1,
	CAT 	= 2,
	TRAVEL 	= 3,
	MOONKIN = 4,
};

-- Category designations
-- passive = only passively casted buffs
-- all = Always active for all specs
-- special = Some special thing for all specs, not necessarily always enabled
-- [0] = Base buffs for all specs
-- [x] = Override to previous on per spec basis where x is spec number
local CLASS_CASTABLE_BUFFS = {
	["WARRIOR"]	= {
		
	},
	["DEATHKNIGHT"]	= {
		
	},
	["PALADIN"]	= {
		[3]	= {
		
		},
	},
	["MONK"] = {
		
	},
	["PRIEST"] = {
		
	},
	["SHAMAN"] = {
		
	},
	["DRUID"] = {
		[1] = {
			{
				selfbuff = { LE.BUFFS.DRUID_MOONKIN_FORM },
				condition = function()
					if(not Addon.db.global.Class.Druid.FormAlert) then return false end
					if(Addon.db.global.Class.Druid.OnlyInCombat and not InCombatLockdown()) then return false end
					
					return GetShapeshiftForm() ~= LE.DRUID_FORM.MOONKIN;
				end,
				description = "Not in a form",
			},
		},
		[2] = {
			{
				selfbuff = { LE.BUFFS.DRUID_CAT_FORM },
				condition = function()
					if(not Addon.db.global.Class.Druid.FormAlert) then return false end
					if(Addon.db.global.Class.Druid.OnlyInCombat and not InCombatLockdown()) then return false end
					
					return GetShapeshiftForm() ~= LE.DRUID_FORM.CAT;
				end,
				description = "Not in a form",
			},
		},
		[3] = {
			{
				selfbuff = { LE.BUFFS.DRUID_BEAR_FORM },
				condition = function()
					if(not Addon.db.global.Class.Druid.FormAlert) then return false end
					if(Addon.db.global.Class.Druid.OnlyInCombat and not InCombatLockdown()) then return false end
					
					return GetShapeshiftForm() ~= LE.DRUID_FORM.BEAR;
				end,
				description = "Not in a form",
			},
		},
	},
	["ROGUE"] = {
		[1] = {
			{
				selfbuff = { LE.BUFFS.ROGUE_AGONIZING_POISON, LE.BUFFS.ROGUE_DEADLY_POISON, LE.BUFFS.ROGUE_WOUND_POISON },
				condition = function()
					return CanPoisonWeapons() and Addon.db.global.Class.Rogue.EnableLethal and not Addon.db.global.Class.Rogue.WoundPoisonPriority;
				end,
				description = "Missing Lethal Poison",
			},
			{
				selfbuff = { LE.BUFFS.ROGUE_WOUND_POISON, LE.BUFFS.ROGUE_AGONIZING_POISON, LE.BUFFS.ROGUE_DEADLY_POISON, },
				condition = function()
					return CanPoisonWeapons() and Addon.db.global.Class.Rogue.EnableLethal and Addon.db.global.Class.Rogue.WoundPoisonPriority;
				end,
				description = "Missing Lethal Poison",
			},
			{
				noTalent = { 4, 1 },
				selfbuff = { LE.BUFFS.ROGUE_CRIPPLING_POISON, },
				condition = function()
					return CanPoisonWeapons() and Addon.db.global.Class.Rogue.EnableNonlethal and not Addon.db.global.Class.Rogue.SkipCrippling;
				end,
				description = "Missing Non-Lethal Poison",
			},
			{
				hasTalent = { 4, 1 },
				selfbuff = { LE.BUFFS.ROGUE_LEECHING_POISON, },
				condition = function()
					return CanPoisonWeapons() and Addon.db.global.Class.Rogue.EnableNonlethal;
				end,
				description = "Missing Non-Lethal Poison",
			},
			{
				noTalent = { 4, 1 },
				selfbuff = { LE.BUFFS.ROGUE_CRIPPLING_POISON },
				skipBuffCheck = true,
				condition = function()
					if(not CanPoisonWeapons() or not Addon.db.global.Class.Rogue.EnableNonlethal or Addon.db.global.Class.Rogue.SkipCrippling) then return end
					
					local _, hasBuff, remainingNonLethal, remainingLethal, duration;
					
					hasBuff, _, _, remainingNonLethal, duration = Addon:UnitHasBuff("player", LE.BUFFS.ROGUE_CRIPPLING_POISON);
					if(not hasBuff or Addon:WillBuffExpireSoon(remainingNonLethal)) then return false end
					
					hasBuff, _, _, remainingLethal, duration = Addon:UnitHasSomeBuff("player", { LE.BUFFS.ROGUE_AGONIZING_POISON, LE.BUFFS.ROGUE_WOUND_POISON, LE.BUFFS.ROGUE_DEADLY_POISON });
					
					local remainingDiff = math.abs(remainingNonLethal - remainingLethal);
					return Addon.db.global.Class.Rogue.RefreshBoth and hasBuff and remainingLethal >= duration - 20 and remainingDiff > 20;
				end,
				description = "Refresh Non-Lethal Poison Too",
			},
			{
				hasTalent = { 4, 1 },
				selfbuff = { LE.BUFFS.ROGUE_LEECHING_POISON, },
				skipBuffCheck = true,
				condition = function()
					if(not CanPoisonWeapons() or not Addon.db.global.Class.Rogue.EnableNonlethal) then return end
					
					local _, hasBuff, remainingNonLethal, remainingLethal, duration;
					
					hasBuff, _, _, remainingNonLethal, duration = Addon:UnitHasBuff("player", LE.BUFFS.ROGUE_LEECHING_POISON);
					if(not hasBuff or Addon:WillBuffExpireSoon(remainingNonLethal)) then return false end
					
					hasBuff, _, _, remainingLethal, duration = Addon:UnitHasSomeBuff("player", { LE.BUFFS.ROGUE_AGONIZING_POISON, LE.BUFFS.ROGUE_WOUND_POISON, LE.BUFFS.ROGUE_DEADLY_POISON });
					
					local remainingDiff = math.abs(remainingNonLethal - remainingLethal);
					return Addon.db.global.Class.Rogue.RefreshBoth and hasBuff and remainingLethal >= duration - 20 and remainingDiff > 20;
				end,
				description = "Refresh Non-Lethal Poison Too",
			},
		},
	},
	["MAGE"] = {
		
	},
	["WARLOCK"] = {
		special = {
			{
				selfbuff = { LE.BUFFS.WARLOCK_SOULSTONE, },
				condition = function()
					if(Addon:IsSpellReady(LE.BUFFS.WARLOCK_SOULSTONE) and Addon.db.global.Class.Warlock.EnableSoulstone) then
						if(Addon.db.global.Class.Warlock.OnlyEnableSolo and Addon:GetGroupType() ~= LE.GROUP_TYPE.SOLO) then return false end
						if(Addon.db.global.Class.Warlock.OnlyEnableOutside and Addon:PlayerInInstance()) then return false end
						
						if(Addon.db.global.Class.Warlock.ExpiryOverride and Addon:GetBuffRemaining("player", LE.BUFFS.WARLOCK_SOULSTONE) > 300) then
							return false;
						end
						
						return true;
					end
					return false;
				end,
			},
			{
				hasTalent = { 6, 3 },
				selfbuff = { LE.BUFFS.WARLOCK_GRIMOIRE_OF_SACRIFICE },
				condition = function()
					-- This talent location has something else for demonology
					if(GetSpecialization() == 2) then return false end
					
					local hasBuff = Addon:UnitHasBuff("player", LE.BUFFS.WARLOCK_GRIMOIRE_OF_SACRIFICE_EFFECT);
					return not hasBuff and Addon.db.global.Class.Warlock.EnableGrimoireSacrificeAlert;
				end,
				description = function()
					if(UnitName("pet") == nil) then
						return "Summon a demon to sacrifice";
					end
					
					return "Sacrifice your demon";
				end,
			},
		},
	},
	["HUNTER"] = {
		
	},
};

local function tmerge(table, other)
	for key, value in ipairs(other) do
		tinsert(table, value);
	end
	
	return table;
end

function Addon:GetClassCastableBuffs(class, spec)
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

local PEPE_TOY_ITEM_ID = 122293;

-- Miscellaneous category, low priority selfbuffs or other stuff
LE.MISC_CASTABLE_BUFFS = {
	{
		selfbuff = { LE.BUFFS.PEPE },
		skipBuffCheck = true,
		condition = function()
			if(not Addon.db.global.PepeReminderEnabled or InCombatLockdown()) then return false end
			if(not PlayerHasToy(PEPE_TOY_ITEM_ID)) then return false end
			
			local hasBuff = Addon:UnitHasBuff("player", LE.BUFFS.PEPE);
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
				"You found Pepe!",
				"The Lil' Tangerine Traveller",
			};
			return quotes[math.floor(GetTime() / 120) % (#quotes) + 1];
		end,
		info = {
			type = "toy",
			id = PEPE_TOY_ITEM_ID,
		},
	},
}

-----------------------------------------------------------------
-- Consumable spells

BUFFY_CONSUMABLES = {
	FLASKS 		= {},
	RUNES 		= {},
	FOODS 		= {},
};

BUFFY_ITEM_SPELLS = {};

Addon:AddBuffItems(BUFFY_CONSUMABLES.FLASKS, LE.STAT.AGILITY, 		{ 109153, 109145, 118922, 86569 });
Addon:AddItemSpell(109153, 156064); -- Greater Draenic Agility Flask
Addon:AddItemSpell(109145, 156073); -- Draenic Agility Flask

Addon:AddBuffItems(BUFFY_CONSUMABLES.FLASKS, LE.STAT.STRENGTH,		{ 109156, 109148, 118922, 86569 });
Addon:AddItemSpell(109156, 156080); -- Greater Draenic Strength Flask
Addon:AddItemSpell(109148, 156071); -- Draenic Strength Flask

Addon:AddBuffItems(BUFFY_CONSUMABLES.FLASKS, LE.STAT.INTELLECT, 	{ 109155, 109147, 118922, 86569 });
Addon:AddItemSpell(109155, 156079); -- Greater Draenic Intellect Flask
Addon:AddItemSpell(109147, 156070); -- Draenic Intellect Flask

Addon:AddBuffItems(BUFFY_CONSUMABLES.FLASKS, LE.STAT.STAMINA, 		{ 109160, 109152 });
Addon:AddItemSpell(109160, 156084); -- Greater Draenic Stamina Flask
Addon:AddItemSpell(109152, 156077); -- Draenic Stamina Flask

Addon:AddItemSpell(118922, 176151); -- Oralius' Crystal
Addon:AddItemSpell(86569,  127230); -- Crystal of Insanity

-- Non-consumable runes are listed first
Addon:AddBuffItems(BUFFY_CONSUMABLES.RUNES, LE.STAT.AGILITY, 		{ 128482, 128475, 118630 });
Addon:AddItemSpell(118630, 175456);

Addon:AddBuffItems(BUFFY_CONSUMABLES.RUNES, LE.STAT.STRENGTH,		{ 128482, 128475, 118631 });
Addon:AddItemSpell(118631, 175439);

Addon:AddBuffItems(BUFFY_CONSUMABLES.RUNES, LE.STAT.INTELLECT,		{ 128482, 128475, 118632 });
Addon:AddItemSpell(118632, 175457);

Addon:AddBuffItems(BUFFY_CONSUMABLES.FOODS, LE.STAT.HASTE, 			{ 122348, 111450, 118428, 111434, 111442, });
Addon:AddBuffItems(BUFFY_CONSUMABLES.FOODS, LE.STAT.MASTERY, 		{ 122343, 111452, 118428, 111436, 111444, });
Addon:AddBuffItems(BUFFY_CONSUMABLES.FOODS, LE.STAT.CRIT,			{ 122345, 111449, 118428, 111433, 111441, });
Addon:AddBuffItems(BUFFY_CONSUMABLES.FOODS, LE.STAT.VERSATILITY, 	{ 122346, 111454, 118428, 111438, 111446, });
Addon:AddBuffItems(BUFFY_CONSUMABLES.FOODS, LE.STAT.STAMINA, 		{ 122347, 111447, 111431, 111439, });
Addon:AddBuffItems(BUFFY_CONSUMABLES.FOODS, LE.STAT.FELMOUTH,		{ 127991, });

BUFFY_CONSUMABLES.FEASTS = {
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

-----------------------------------------------------------------

local function ltinsert(table, list)
	if(not table or type(table) ~= "table") then return false end
	if(not list or type(list) ~= "table") then return false end
	
	for key, value in ipairs(list) do
		table[key] = value;
	end
end

-- Reference table for main stats for classes and specs
local CLASS_STAT_PREFS = {
	["WARRIOR"]	= {
		[0] = { LE.STAT.STRENGTH },
		[3] = { LE.STAT.STAMINA, LE.STAT.STRENGTH };
	},
	["DEATHKNIGHT"]	= {
		[0] = { LE.STAT.STRENGTH },
		[1] = { LE.STAT.STAMINA, LE.STAT.STRENGTH },
	},
	["PALADIN"]	= {
		[1] = { LE.STAT.INTELLECT },
		[2] = { LE.STAT.STAMINA, LE.STAT.STRENGTH },
		[3] = { LE.STAT.STRENGTH },
	},
	["MONK"] = {
		[1] = { LE.STAT.STAMINA, LE.STAT.AGILITY },
		[2] = { LE.STAT.INTELLECT },
		[3] = { LE.STAT.AGILITY },
	},
	["PRIEST"] = {
		[0] = { LE.STAT.INTELLECT },
	},
	["SHAMAN"] = {
		[0] = { LE.STAT.INTELLECT },
		[2] = { LE.STAT.AGILITY },
	},
	["DRUID"] = {
		[1] = { LE.STAT.INTELLECT },
		[2] = { LE.STAT.AGILITY },
		[3] = { LE.STAT.STAMINA, LE.STAT.AGILITY },
		[4] = { LE.STAT.INTELLECT },
	},
	["ROGUE"] = {
		[0] = { LE.STAT.AGILITY },
	},
	["MAGE"] = {
		[0] = { LE.STAT.INTELLECT },
	},
	["WARLOCK"] = {
		[0] = { LE.STAT.INTELLECT },
	},
	["HUNTER"] = {
		[0] = { LE.STAT.AGILITY },
	},
	["DEMONHUNTER"] = {
		[0] = { LE.STAT.AGILITY },
		[2] = { LE.STAT.STAMINA, LE.STAT.AGILITY }
	},
};

function Addon:GetStatPreference(class, spec_index)
	if(not class or not spec_index) then return -1; end
	
	local statTypes = CLASS_STAT_PREFS[class][spec_index] or CLASS_STAT_PREFS[class][0];
	
	local stats = {};
	ltinsert(stats, statTypes);
	
	if(#stats == 2 and stats[1] == LE.STAT.STAMINA and self.db.global.ConsumablesRemind.SkipStamina) then
		-- Swap stats
		stats[1], stats[2] = stats[2], stats[1]
	end
	
	return stats;
end

local TANK_SPECS = {
	["WARRIOR"]	= {
		[3] = true,
	},
	["DEATHKNIGHT"]	= {
		[1] = true,
	},
	["PALADIN"]	= {
		[2] = true,
	},
	["MONK"] = {
		[1] = true,
	},
	["DRUID"] = {
		[3] = true,
	},
	["DEMONHUNTER"] = {
		[2] = true,
	},
};

function Addon:PlayerInTankSpec()
	local _, PLAYER_CLASS = UnitClass("player");
	local spec = GetSpecialization();
	
	if(not TANK_SPECS[PLAYER_CLASS] or not TANK_SPECS[PLAYER_CLASS][spec]) then
		return false;
	end
	
	return TANK_SPECS[PLAYER_CLASS] and TANK_SPECS[PLAYER_CLASS][spec];
end

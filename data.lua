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

LE.CONSUMABLE_CATEGORY = {
	GENERIC = 0,
	DRAENOR = 5,
	LEGION  = 6,
	BFA     = 7,
};

LE.EXPANSION = {
	VANILLA     = 0,
	TBC         = 1,
	WRATH       = 2,
	CATACLYSM   = 3,
	PANDARIA    = 4,
	DRAENOR     = 5,
	LEGION      = 6,
	BFA         = 7,
};
LE.CURRENT_EXPANSION = LE.EXPANSION.BFA;

LE.INSTANCETYPE_RAID 	= 0x1;
LE.INSTANCETYPE_DUNGEON = 0x2;
LE.INSTANCE_MAP_IDS = {
	[LE.EXPANSION.DRAENOR] = {
		[1228] = LE.INSTANCETYPE_RAID, -- Highmaul
		[1205] = LE.INSTANCETYPE_RAID, -- Blackrock Foundry
		[1448] = LE.INSTANCETYPE_RAID, -- Hellfire Citadel
		
		[1182] = LE.INSTANCETYPE_DUNGEON, -- Auchindoun
		[1175] = LE.INSTANCETYPE_DUNGEON, -- Bloodmaul Slag Mines
		[1208] = LE.INSTANCETYPE_DUNGEON, -- Grimrail Depot
		[1195] = LE.INSTANCETYPE_DUNGEON, -- Iron Docks
		[1176] = LE.INSTANCETYPE_DUNGEON, -- Shadowmoon Burial Grounds
		[1209] = LE.INSTANCETYPE_DUNGEON, -- Skyreach
		[1279] = LE.INSTANCETYPE_DUNGEON, -- The Everbloom
		[1358] = LE.INSTANCETYPE_DUNGEON, -- Upper Blackrock Spire
	},
	
	[LE.EXPANSION.LEGION] = {
		[1520] = LE.INSTANCETYPE_RAID, -- The Emerald Nightmare
		[1530] = LE.INSTANCETYPE_RAID, -- The Nighthold
		[1648] = LE.INSTANCETYPE_RAID, -- Trial of Valor
		[1676] = LE.INSTANCETYPE_RAID, -- Tomb of Sargeras
		[1712] = LE.INSTANCETYPE_RAID, -- Antorus, the Burning Throne
		
		[1456] = LE.INSTANCETYPE_DUNGEON, -- Eye of Azshara
		[1458] = LE.INSTANCETYPE_DUNGEON, -- Neltharion's Lair
		[1466] = LE.INSTANCETYPE_DUNGEON, -- Darkheart Thicket
		[1477] = LE.INSTANCETYPE_DUNGEON, -- Halls of Valor
		[1492] = LE.INSTANCETYPE_DUNGEON, -- Maw of Souls
		[1493] = LE.INSTANCETYPE_DUNGEON, -- Vault of the Wardens
		[1501] = LE.INSTANCETYPE_DUNGEON, -- Black Rook Hold
		[1544] = LE.INSTANCETYPE_DUNGEON, -- Violet Hold
		[1516] = LE.INSTANCETYPE_DUNGEON, -- The Arcway
		[1571] = LE.INSTANCETYPE_DUNGEON, -- Court of Stars
		[1677] = LE.INSTANCETYPE_DUNGEON, -- Cathedral of Eternal Night
	},
	
	[LE.EXPANSION.BFA] = {
		-- TODO	
	},
};

-- Enums
LE.STAT = {
	AGILITY 	= 0x001,
	STRENGTH 	= 0x002,
	INTELLECT	= 0x004,
	STAMINA		= 0x008,
	
	HASTE		= 0x010,
	MASTERY		= 0x020,
	CRIT		= 0x040,
	VERSATILITY	= 0x080,
	
	SPECIAL     = 0x0F0,
	CUSTOM		= 0x100,
	
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
LE.ALERT_TYPE_CUSTOM	= 0x03;
LE.ALERT_TYPE_SPECIAL	= 0xFF;

LE.SPECIAL_FOOD			= 0x1;
LE.SPECIAL_EATING		= 0x2;
LE.SPECIAL_UNLOCKED		= 0x3;

-----------------------------------------------------------------
-- Buff spells

Addon:AddBuffSpell(2823,	LE.BUFF_SPECIAL, "ROGUE_DEADLY_POISON");
Addon:AddBuffSpell(8679, 	LE.BUFF_SPECIAL, "ROGUE_WOUND_POISON");
Addon:AddBuffSpell(3408, 	LE.BUFF_SPECIAL, "ROGUE_CRIPPLING_POISON");
Addon:AddBuffSpell(108211,	LE.BUFF_SPECIAL, "ROGUE_LEECHING_POISON");

Addon:AddBuffSpell(20707,	LE.BUFF_SPECIAL, "WARLOCK_SOULSTONE");
Addon:AddBuffSpell(108503,	LE.BUFF_SPECIAL, "WARLOCK_GRIMOIRE_OF_SACRIFICE");
Addon:AddBuffSpell(196099,	LE.BUFF_SPECIAL, "WARLOCK_GRIMOIRE_OF_SACRIFICE_EFFECT");

Addon:AddBuffSpell(205022,	LE.BUFF_SPECIAL, "MAGE_ARCANE_FAMILIAR");

Addon:AddBuffSpell(192106,	LE.BUFF_SPECIAL, "SHAMAN_LIGHTNING_SHIELD");

Addon:AddBuffSpell(5487,	LE.BUFF_SPECIAL, "DRUID_BEAR_FORM");
Addon:AddBuffSpell(768,		LE.BUFF_SPECIAL, "DRUID_CAT_FORM");
Addon:AddBuffSpell(24858,	LE.BUFF_SPECIAL, "DRUID_MOONKIN_FORM");

Addon:AddBuffSpell(203538,	LE.BUFF_SPECIAL, "PALADIN_GREATER_BLESSING_OF_KINGS");
Addon:AddBuffSpell(203539,	LE.BUFF_SPECIAL, "PALADIN_GREATER_BLESSING_OF_WISDOM");

Addon:AddBuffSpell(181943,	LE.BUFF_SPECIAL, "PEPE");

Addon:AddBuffSpell(6673, 	LE.STAT.STRENGTH + LE.STAT.AGILITY, "BATTLE_SHOUT");
Addon:AddBuffSpell(21562,	LE.STAT.STAMINA, "POWER_WORD_FORTITUDE");
Addon:AddBuffSpell(1459,	LE.STAT.INTELLECT, "ARCANE_INTELLECT");

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
		all = {
			{
				raidbuff = LE.BUFFS.BATTLE_SHOUT,
			},
		},
	},
	["DEATHKNIGHT"]	= {
		
	},
	["PALADIN"]	= {
		[3]	= {
			{
				vars = {
					buffs = {
						LE.BUFFS.PALADIN_GREATER_BLESSING_OF_KINGS,
						LE.BUFFS.PALADIN_GREATER_BLESSING_OF_WISDOM,
					},
					roleBuffs = { -- Priorities for roles
						["DAMAGER"] = { LE.BUFFS.PALADIN_GREATER_BLESSING_OF_KINGS, LE.BUFFS.PALADIN_GREATER_BLESSING_OF_WISDOM },
						["TANK"]    = { LE.BUFFS.PALADIN_GREATER_BLESSING_OF_KINGS, LE.BUFFS.PALADIN_GREATER_BLESSING_OF_WISDOM },
						["HEALER"]  = { LE.BUFFS.PALADIN_GREATER_BLESSING_OF_WISDOM, LE.BUFFS.PALADIN_GREATER_BLESSING_OF_KINGS },
						["NONE"]    = { LE.BUFFS.PALADIN_GREATER_BLESSING_OF_KINGS, LE.BUFFS.PALADIN_GREATER_BLESSING_OF_WISDOM },
					},
					roleOrder = { "TANK", "HEALER", "DAMAGER", "NONE" },
					buffsRemaining = 1337,
					getNumBlessings = function()
						local knownSpells = 0;
						if(IsSpellKnown(LE.BUFFS.PALADIN_GREATER_BLESSING_OF_KINGS)) then knownSpells = knownSpells + 1 end
						if(IsSpellKnown(LE.BUFFS.PALADIN_GREATER_BLESSING_OF_WISDOM)) then knownSpells = knownSpells + 1 end
						return knownSpells;
					end,
				},
				bufflist = function(self)
					local buffStatus = Addon:ScanExclusiveBuffList(self.buffs);
					local buffsRemaining = self.getNumBlessings() - #buffStatus["player"];
					
					self.buffsRemaining = buffsRemaining;
					
					if(Addon.db.global.Class.Paladin.OnlyRemind) then
						return buffsRemaining > 0, LE.BUFFS.PALADIN_GREATER_BLESSING_OF_KINGS;
					end
					
					if(buffsRemaining > 0) then
						local isSolo = Addon:GetGroupType() == LE.GROUP_TYPE.SOLO;
						
						local buffToCast = nil;
						
						if(isSolo or Addon.db.global.Class.Paladin.SelfCastBlessings) then
							for _, spell in ipairs(self.buffs) do
								local hasBuff = Addon:UnitHasBuff("player", spell);
								if(not hasBuff) then
									buffToCast = {
										spell = spell,
										target = "player",
									};
									break;
								end
							end
						else
							local remainingBuffs = {};
							for _, buffSpellId in ipairs(self.buffs) do
								local found = false;
								for index, data in ipairs(buffStatus["player"]) do
									if(data.spell == buffSpellId) then
										found = true;
										break;
									end
								end
								if(not found) then
									remainingBuffs[buffSpellId] = true;
								end
							end
							
							local remainingRoleBuffs = {};
							for role, roleBuffs in pairs(self.roleBuffs) do
								if(not remainingRoleBuffs[role]) then remainingRoleBuffs[role] = {} end
								for _, buffSpellId in ipairs(roleBuffs) do
									if(remainingBuffs[buffSpellId]) then
										tinsert(remainingRoleBuffs[role], buffSpellId);
									end
								end
							end
						
							local missingBuffs = Addon:ScanMissingPartyBuffsByRole(remainingRoleBuffs);
							local playerUnitID = Addon:GetPlayerUnitID();
							
							local buffPriorities = {};
							
							for rolePriority, role in ipairs(self.roleOrder) do
								if(missingBuffs[role]) then
									for unit, buffs in pairs(missingBuffs[role]) do
										local spell = buffs[1];
										local priority = #buffs;
										
										local totalPriority = priority * (5-rolePriority);
										
										if(unit == playerUnitID) then
											totalPriority = totalPriority * 1.1;
										end
										
										if(spell == LE.BUFFS.PALADIN_GREATER_BLESSING_OF_WISDOM) then
											if(UnitPowerType(unit) == SPELL_POWER_MANA) then
												totalPriority = totalPriority * 1.1;
											else
												totalPriority = totalPriority * 0.5;
											end
										end
										
										tinsert(buffPriorities, {
											spell = spell,
											target = unit,
											priority = totalPriority,
										});
									end
								end
							end
							
							table.sort(buffPriorities, function(a, b)
								if(a == nil and b == nil) then return false end
								if(a == nil) then return true end
								if(b == nil) then return false end
								
								return a.priority > b.priority;
							end);
							
							if(buffPriorities[1]) then
								buffToCast = {
									spell = buffPriorities[1].spell,
									target = buffPriorities[1].target,
								};
							end
						end
						
						if(buffToCast) then
							self.target = buffToCast.target;
							return true, buffToCast.spell, buffToCast.target;
						end
					end
					
					return false;
				end,
				condition = function(self)
					return Addon.db.global.Class.Paladin.EnableBlessings and not InCombatLockdown();
				end,
				description = function(self)
					return string.format("Missing %d blessing%s", self.buffsRemaining, self.buffsRemaining == 1 and "" or "s");
				end,
				secondary = function(self)
					if(Addon.db.global.Class.Paladin.OnlyRemind) then
						return "A Greater Blessing";
					end
				end,
				icon = function()
					if(Addon.db.global.Class.Paladin.OnlyRemind) then
						return 135993; -- Blessing of Kings icon
					end
				end,
				noCast = function()
					return Addon.db.global.Class.Paladin.OnlyRemind;
				end,
			},
		},
	},
	["MONK"] = {
		
	},
	["PRIEST"] = {
		all = {
			{
				raidbuff = LE.BUFFS.POWER_WORD_FORTITUDE,
			}
		},
	},
	["SHAMAN"] = {
		[2]	= {
			{
				hasTalent = { 1, 3 },
				bufflist = { LE.BUFFS.SHAMAN_LIGHTNING_SHIELD, },
				condition = function()
					return Addon.db.global.Class.Shaman.EnableLightningShield;
				end,
			},
		},
	},
	["DRUID"] = {
		[1] = {
			{
				bufflist = { LE.BUFFS.DRUID_MOONKIN_FORM },
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
				bufflist = { LE.BUFFS.DRUID_CAT_FORM },
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
				bufflist = { LE.BUFFS.DRUID_BEAR_FORM },
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
				bufflist = { LE.BUFFS.ROGUE_DEADLY_POISON, LE.BUFFS.ROGUE_WOUND_POISON },
				condition = function()
					return CanPoisonWeapons() and Addon.db.global.Class.Rogue.EnableLethal and not Addon.db.global.Class.Rogue.WoundPoisonPriority;
				end,
				description = "Missing Lethal Poison",
			},
			{
				bufflist = { LE.BUFFS.ROGUE_WOUND_POISON, LE.BUFFS.ROGUE_DEADLY_POISON, },
				condition = function()
					return CanPoisonWeapons() and Addon.db.global.Class.Rogue.EnableLethal and Addon.db.global.Class.Rogue.WoundPoisonPriority;
				end,
				description = "Missing Lethal Poison",
			},
			{
				noTalent = { 4, 1 },
				bufflist = { LE.BUFFS.ROGUE_CRIPPLING_POISON, },
				condition = function()
					return CanPoisonWeapons() and Addon.db.global.Class.Rogue.EnableNonlethal and not Addon.db.global.Class.Rogue.SkipCrippling;
				end,
				description = "Missing Non-Lethal Poison",
			},
			{
				hasTalent = { 4, 1 },
				bufflist = { LE.BUFFS.ROGUE_LEECHING_POISON, },
				condition = function()
					return CanPoisonWeapons() and Addon.db.global.Class.Rogue.EnableNonlethal;
				end,
				description = "Missing Non-Lethal Poison",
			},
			{
				noTalent = { 4, 1 },
				bufflist = { LE.BUFFS.ROGUE_CRIPPLING_POISON },
				skipBuffCheck = true,
				condition = function()
					if(not CanPoisonWeapons() or not Addon.db.global.Class.Rogue.EnableNonlethal or Addon.db.global.Class.Rogue.SkipCrippling) then return end
					
					local _, hasBuff, remainingNonLethal, remainingLethal, duration;
					
					hasBuff, _, _, remainingNonLethal, duration = Addon:UnitHasBuff("player", LE.BUFFS.ROGUE_CRIPPLING_POISON);
					if(not hasBuff or Addon:WillBuffExpireSoon(remainingNonLethal)) then return false end
					
					hasBuff, _, _, remainingLethal, duration = Addon:UnitHasSomeBuff("player", { LE.BUFFS.ROGUE_WOUND_POISON, LE.BUFFS.ROGUE_DEADLY_POISON });
					
					local remainingDiff = math.abs((remainingNonLethal or 0) - (remainingLethal or 0));
					return Addon.db.global.Class.Rogue.RefreshBoth and hasBuff and remainingLethal >= duration - 20 and remainingDiff > 20;
				end,
				description = "Refresh Non-Lethal Poison Too",
			},
			{
				hasTalent = { 4, 1 },
				bufflist = { LE.BUFFS.ROGUE_LEECHING_POISON, },
				skipBuffCheck = true,
				condition = function()
					if(not CanPoisonWeapons() or not Addon.db.global.Class.Rogue.EnableNonlethal) then return end
					
					local _, hasBuff, remainingNonLethal, remainingLethal, duration;
					
					hasBuff, _, _, remainingNonLethal, duration = Addon:UnitHasBuff("player", LE.BUFFS.ROGUE_LEECHING_POISON);
					if(not hasBuff or Addon:WillBuffExpireSoon(remainingNonLethal)) then return false end
					
					hasBuff, _, _, remainingLethal, duration = Addon:UnitHasSomeBuff("player", { LE.BUFFS.ROGUE_WOUND_POISON, LE.BUFFS.ROGUE_DEADLY_POISON });
					
					local remainingDiff = math.abs((remainingNonLethal or 0) - (remainingLethal or 0));
					return Addon.db.global.Class.Rogue.RefreshBoth and hasBuff and remainingLethal >= duration - 20 and remainingDiff > 20;
				end,
				description = "Refresh Non-Lethal Poison Too",
			},
		},
		[2] = {
			{
				skipBuffCheck = true,
				condition = function()
					if(not Addon.db.global.Class.Rogue.EnableFindTreasure) then return end
					if(InCombatLockdown()) then return end
					
					local numTrackingTypes = GetNumTrackingTypes();
					for i=1, numTrackingTypes do 
						local name, icon, active = GetTrackingInfo(i);
						if(icon == 1064187) then
							return not active;
						end
					end
					
					return false;
				end,
				info = {
					id = 199736,
					type = "custom",
				},
				cast = function()
					local numTrackingTypes = GetNumTrackingTypes();
					for i=1, numTrackingTypes do 
						local name, icon, active = GetTrackingInfo(i);
						if(icon == 1064187) then
							SetTracking(i, true);
							return;
						end
					end
				end,
				primary = "Cast",
				description = "Yarr, ye treasures be mine!",
			},
		},
	},
	["MAGE"] = {
		all = {
			{	
				raidbuff = LE.BUFFS.ARCANE_INTELLECT,
			}
		},
		[1]	= {
			{
				hasTalent = { 1, 3 },
				bufflist = { LE.BUFFS.MAGE_ARCANE_FAMILIAR, },
				condition = function()
					return Addon.db.global.Class.Mage.EnableArcaneFamiliar;
				end,
			},
		},
	},
	["WARLOCK"] = {
		special = {
			{
				bufflist = { LE.BUFFS.WARLOCK_SOULSTONE, },
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
				bufflist = { LE.BUFFS.WARLOCK_GRIMOIRE_OF_SACRIFICE },
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
	["DEMONHUNTER"] = {
		
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
		bufflist = { LE.BUFFS.PEPE },
		skipBuffCheck = true,
		condition = function()
			if(not Addon.db.global.PepeReminderEnabled or InCombatLockdown()) then return false end
			if(not PlayerHasToy(PEPE_TOY_ITEM_ID)) then return false end
			
			local inInstance, instanceType = Addon:PlayerInInstance();
			if(inInstance and (instanceType == "pvp" or instanceType == "arena")) then return false end
			
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

-------------------------------
-- Generic consumables

Addon:AddBuffItems(BUFFY_CONSUMABLES.FLASKS, LE.CONSUMABLE_CATEGORY.GENERIC, LE.STAT.AGILITY, 		{ 147707, 129192, 118922, 86569 });
Addon:AddBuffItems(BUFFY_CONSUMABLES.FLASKS, LE.CONSUMABLE_CATEGORY.GENERIC, LE.STAT.STRENGTH, 		{ 147707, 118922, 86569 });
Addon:AddBuffItems(BUFFY_CONSUMABLES.FLASKS, LE.CONSUMABLE_CATEGORY.GENERIC, LE.STAT.INTELLECT, 	{ 147707, 118922, 86569 });
Addon:AddBuffItems(BUFFY_CONSUMABLES.FLASKS, LE.CONSUMABLE_CATEGORY.GENERIC, LE.STAT.STAMINA, 		{ 147707, 129192, 118922, });

Addon:AddItemSpell(147707, 242551); -- Repurposed Fel Focuser
Addon:AddItemSpell(118922, 176151); -- Oralius' Crystal
Addon:AddItemSpell(86569,  127230); -- Crystal of Insanity
Addon:AddItemSpell(129192, 193456); -- Inquisitor's Menacing Eye

Addon:AddBuffItems(BUFFY_CONSUMABLES.FOODS, LE.CONSUMABLE_CATEGORY.GENERIC, LE.STAT.CUSTOM, 		{ });

-------------------------------
-- Draenor consumables

Addon:AddBuffItems(BUFFY_CONSUMABLES.FLASKS, LE.CONSUMABLE_CATEGORY.DRAENOR, LE.STAT.AGILITY, 		{ 109153, 109145, });
Addon:AddItemSpell(109153, 156064); -- Greater Draenic Agility Flask
Addon:AddItemSpell(109145, 156073); -- Draenic Agility Flask

Addon:AddBuffItems(BUFFY_CONSUMABLES.FLASKS, LE.CONSUMABLE_CATEGORY.DRAENOR, LE.STAT.STRENGTH,		{ 109156, 109148, });
Addon:AddItemSpell(109156, 156080); -- Greater Draenic Strength Flask
Addon:AddItemSpell(109148, 156071); -- Draenic Strength Flask

Addon:AddBuffItems(BUFFY_CONSUMABLES.FLASKS, LE.CONSUMABLE_CATEGORY.DRAENOR, LE.STAT.INTELLECT, 	{ 109155, 109147, });
Addon:AddItemSpell(109155, 156079); -- Greater Draenic Intellect Flask
Addon:AddItemSpell(109147, 156070); -- Draenic Intellect Flask

Addon:AddBuffItems(BUFFY_CONSUMABLES.FLASKS, LE.CONSUMABLE_CATEGORY.DRAENOR, LE.STAT.STAMINA, 		{ 109160, 109152, });
Addon:AddItemSpell(109160, 156084); -- Greater Draenic Stamina Flask
Addon:AddItemSpell(109152, 156077); -- Draenic Stamina Flask

-- Non-consumable runes are listed first
Addon:AddBuffItems(BUFFY_CONSUMABLES.RUNES, LE.CONSUMABLE_CATEGORY.DRAENOR, LE.STAT.AGILITY, 		{ 128482, 128475, 118630 });
Addon:AddItemSpell(118630, 175456);

Addon:AddBuffItems(BUFFY_CONSUMABLES.RUNES, LE.CONSUMABLE_CATEGORY.DRAENOR, LE.STAT.STRENGTH,		{ 128482, 128475, 118631 });
Addon:AddItemSpell(118631, 175439);

Addon:AddBuffItems(BUFFY_CONSUMABLES.RUNES, LE.CONSUMABLE_CATEGORY.DRAENOR, LE.STAT.INTELLECT,		{ 128482, 128475, 118632 });
Addon:AddItemSpell(118632, 175457);

Addon:AddBuffItems(BUFFY_CONSUMABLES.FOODS, LE.CONSUMABLE_CATEGORY.DRAENOR, LE.STAT.HASTE, 			{ 122348, 111450, 118428, 111434, 111442, });
Addon:AddBuffItems(BUFFY_CONSUMABLES.FOODS, LE.CONSUMABLE_CATEGORY.DRAENOR, LE.STAT.MASTERY, 		{ 122343, 111452, 118428, 111436, 111444, });
Addon:AddBuffItems(BUFFY_CONSUMABLES.FOODS, LE.CONSUMABLE_CATEGORY.DRAENOR, LE.STAT.CRIT,			{ 122345, 111449, 118428, 111433, 111441, });
Addon:AddBuffItems(BUFFY_CONSUMABLES.FOODS, LE.CONSUMABLE_CATEGORY.DRAENOR, LE.STAT.VERSATILITY, 	{ 122346, 111454, 118428, 111438, 111446, });
Addon:AddBuffItems(BUFFY_CONSUMABLES.FOODS, LE.CONSUMABLE_CATEGORY.DRAENOR, LE.STAT.STAMINA, 		{ 122347, 111447, 111431, 111439, });
Addon:AddBuffItems(BUFFY_CONSUMABLES.FOODS, LE.CONSUMABLE_CATEGORY.DRAENOR, LE.STAT.SPECIAL,		{ 127991, }); -- Felmouth

-------------------------------
-- Legion consumables

Addon:AddBuffItems(BUFFY_CONSUMABLES.FLASKS, LE.CONSUMABLE_CATEGORY.LEGION, LE.STAT.AGILITY, 		{ 127858, 127848, });
Addon:AddItemSpell(127848, 188033); -- Flask of the Seventh Demon

Addon:AddBuffItems(BUFFY_CONSUMABLES.FLASKS, LE.CONSUMABLE_CATEGORY.LEGION, LE.STAT.STRENGTH,		{ 127858, 127849, });
Addon:AddItemSpell(127849, 188034); -- Flask of the Countless Armies

Addon:AddBuffItems(BUFFY_CONSUMABLES.FLASKS, LE.CONSUMABLE_CATEGORY.LEGION, LE.STAT.INTELLECT, 		{ 127858, 109147, });
Addon:AddItemSpell(127847, 188031); -- Flask of the Whispered Pact

Addon:AddBuffItems(BUFFY_CONSUMABLES.FLASKS, LE.CONSUMABLE_CATEGORY.LEGION, LE.STAT.STAMINA, 		{ 127858, 127850, });
Addon:AddItemSpell(127850, 188035); -- Flask of Ten Thousand Scars

-- Non-consumable rune is listed first
Addon:AddBuffItems(BUFFY_CONSUMABLES.RUNES, LE.CONSUMABLE_CATEGORY.LEGION, LE.STAT.AGILITY, 		{ 153023, 140587 });
Addon:AddBuffItems(BUFFY_CONSUMABLES.RUNES, LE.CONSUMABLE_CATEGORY.LEGION, LE.STAT.STRENGTH,		{ 153023, 140587 });
Addon:AddBuffItems(BUFFY_CONSUMABLES.RUNES, LE.CONSUMABLE_CATEGORY.LEGION, LE.STAT.INTELLECT,		{ 153023, 140587 });
Addon:AddItemSpell(140587, 224001);
Addon:AddItemSpell(153023, 224001);

Addon:AddBuffItems(BUFFY_CONSUMABLES.FOODS, LE.CONSUMABLE_CATEGORY.LEGION, LE.STAT.HASTE, 			{ 133571, 133566, 133561, });
Addon:AddBuffItems(BUFFY_CONSUMABLES.FOODS, LE.CONSUMABLE_CATEGORY.LEGION, LE.STAT.MASTERY, 		{ 133572, 133567, 133562, });
Addon:AddBuffItems(BUFFY_CONSUMABLES.FOODS, LE.CONSUMABLE_CATEGORY.LEGION, LE.STAT.CRIT,			{ 133570, 133565, 133557, });
Addon:AddBuffItems(BUFFY_CONSUMABLES.FOODS, LE.CONSUMABLE_CATEGORY.LEGION, LE.STAT.VERSATILITY, 	{ 133573, 133568, 133563, });
-- Addon:AddBuffItems(BUFFY_CONSUMABLES.FOODS, LE.CONSUMABLE_CATEGORY.LEGION, LE.STAT.STAMINA, 		{  }); -- No stamina foods
Addon:AddBuffItems(BUFFY_CONSUMABLES.FOODS, LE.CONSUMABLE_CATEGORY.LEGION, LE.STAT.SPECIAL,			{ 133574, 133569, 133564, }); -- Pepper Breath foods

-------------------------------
-- BFA consumables

Addon:AddBuffItems(BUFFY_CONSUMABLES.FLASKS, LE.CONSUMABLE_CATEGORY.BFA, LE.STAT.AGILITY, 		{ 162518, 152638, });
Addon:AddItemSpell(127848, 188033); -- Flask of the Seventh Demon

Addon:AddBuffItems(BUFFY_CONSUMABLES.FLASKS, LE.CONSUMABLE_CATEGORY.BFA, LE.STAT.STRENGTH,		{ 162518, 152641, });
Addon:AddItemSpell(127849, 188034); -- Flask of the Countless Armies

Addon:AddBuffItems(BUFFY_CONSUMABLES.FLASKS, LE.CONSUMABLE_CATEGORY.BFA, LE.STAT.INTELLECT, 	{ 162518, 152639, });
Addon:AddItemSpell(127847, 188031); -- Flask of the Whispered Pact

Addon:AddBuffItems(BUFFY_CONSUMABLES.FLASKS, LE.CONSUMABLE_CATEGORY.BFA, LE.STAT.STAMINA, 		{ 162518, 152640, });
Addon:AddItemSpell(127850, 188035); -- Flask of Ten Thousand Scars

-- Non-consumable rune is listed first
Addon:AddBuffItems(BUFFY_CONSUMABLES.RUNES, LE.CONSUMABLE_CATEGORY.BFA, LE.STAT.AGILITY, 		{ 153023, });
Addon:AddBuffItems(BUFFY_CONSUMABLES.RUNES, LE.CONSUMABLE_CATEGORY.BFA, LE.STAT.STRENGTH,		{ 153023, });
Addon:AddBuffItems(BUFFY_CONSUMABLES.RUNES, LE.CONSUMABLE_CATEGORY.BFA, LE.STAT.INTELLECT,		{ 153023, });
Addon:AddItemSpell(153023, 270058);

Addon:AddBuffItems(BUFFY_CONSUMABLES.FOODS, LE.CONSUMABLE_CATEGORY.BFA, LE.STAT.HASTE, 			{ 154884, 154883, });
Addon:AddBuffItems(BUFFY_CONSUMABLES.FOODS, LE.CONSUMABLE_CATEGORY.BFA, LE.STAT.MASTERY, 		{ 154888, 154887, });
Addon:AddBuffItems(BUFFY_CONSUMABLES.FOODS, LE.CONSUMABLE_CATEGORY.BFA, LE.STAT.CRIT,			{ 154882, 154881, });
Addon:AddBuffItems(BUFFY_CONSUMABLES.FOODS, LE.CONSUMABLE_CATEGORY.BFA, LE.STAT.VERSATILITY, 	{ 154886, 154885, });
-- Addon:AddBuffItems(BUFFY_CONSUMABLES.FOODS, LE.CONSUMABLE_CATEGORY.BFA, LE.STAT.STAMINA, 		{  }); -- No stamina foods
--Addon:AddBuffItems(BUFFY_CONSUMABLES.FOODS, LE.CONSUMABLE_CATEGORY.BFA, LE.STAT.SPECIAL,			{  }); -- No special foods

-------------------------------
-- Feasts

BUFFY_CONSUMABLES.FEASTS = {
	[LE.CONSUMABLE_CATEGORY.DRAENOR] = {
		[175215] = { -- Savage Feast
			item = 118576,
			duration = 180,
			stats = 80,
		},
		[160740] = { -- Feast of Waters
			item = 111458,
			duration = 180,
			stats = 12,
		},
		[160740] = { -- Feast of Blood
			item = 111457,
			duration = 180,
			stats = 12,
		},
	},
	
	[LE.CONSUMABLE_CATEGORY.LEGION] = {
		[201352] = { -- Lavish Suramar Feast
			item = 133579,
			duration = 180,
			stats = 22,
		},
		[201351] = { -- Hearty Feast
			item = 133578,
			duration = 180,
			stats = 18,
		},
	},
	
	[LE.CONSUMABLE_CATEGORY.BFA] = {
		[259410] = { -- Bountiful Captain's Feast
			item = 156526,
			duration = 180,
			stats = 100,
		},
		[259409] = { -- Galley Banquet
			item = 156525,
			duration = 180,
			stats = 75,
		},
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

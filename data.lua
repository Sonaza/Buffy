------------------------------------------------------------
-- Buffy by Sonaza
------------------------------------------------------------

local ADDON_NAME, SHARED_DATA = ...;

local LibStub = LibStub;
local A, E = unpack(SHARED_DATA);

local _;

E.DRUID_FORM = {
	BEAR 	= 1,
	CAT 	= 2,
	TRAVEL 	= 3,
	MOONKIN = 4,
};

E.WARRIOR_STANCE = {
	BATTLE 		= 1,
	GLADIATOR	= 1,
	DEFENSIVE 	= 2,
};

local INSPECT_SPECIALIZATIONS = {
	-- Death Knight
	[250] = 1, -- Blood
	[251] = 2, -- Frost
	[252] = 3, -- Unholy

	-- Druid
	[102] = 1, -- Balance
	[103] = 2, -- Feral
	[104] = 3, -- Guardian
	[105] = 4, -- Restoration

	-- Hunter
	[253] = 1, -- Beast Mastery
	[254] = 2, -- Marksmanship
	[255] = 3, -- Survival

	-- Mage
	[62] = 1, -- Arcane
	[63] = 2, -- Fire
	[64] = 3, -- Frost

	-- Monk
	[268] = 1, -- Brewmaster
	[270] = 2, -- Mistweaver
	[269] = 3, -- Windwalker

	-- Paladin
	[65] = 1, -- Holy
	[66] = 2, -- Protection
	[70] = 3, -- Retribution

	-- Priest
	[256] = 1, -- Discipline
	[257] = 2, -- Holy
	[258] = 3, -- Shadow

	-- Rogue
	[259] = 1, -- Assassination
	[260] = 2, -- Combat
	[261] = 3, -- Subtlety

	-- Shaman
	[262] = 1, -- Elemental
	[263] = 2, -- Enhancement
	[264] = 3, -- Restoration

	-- Warlock
	[265] = 1, -- Affliction
	[266] = 2, -- Demonology
	[267] = 3, -- Destruction

	-- Warrior
	[71] = 1, -- Arms
	[72] = 2, -- Fury
	[73] = 3, -- Protection
};

local TANK_SPECS = {
	["WARRIOR"]	= {
		[3] = function()
			if(A:PlayerHasTalent(7, 3) and GetShapeshiftForm() == 1) then
				return false;
			end
			
			return true;
		end,
	},
	["DEATHKNIGHT"]	= {
		[1] = function() return true; end,
	},
	["PALADIN"]	= {
		[2] = function() return true; end,
	},
	["MONK"] = {
		[1] = function() return true; end,
	},
	["DRUID"] = {
		[3] = function() return true; end,
	},
};

function A:GetUnitSpecialization(unit)
	if(not unit) then return 0 end
	if(unit == "player") then return GetSpecialization(); end
	
	local inspectSpec = GetInspectSpecialization(unit);
	if(inspectSpec == 0) then return 0 end
	
	return INSPECT_SPECIALIZATIONS[inspectSpec];
end

function A:PlayerInTankSpec()
	local _, PLAYER_CLASS = UnitClass("player");
	local spec = GetSpecialization();
	
	if(not TANK_SPECS[PLAYER_CLASS] or not TANK_SPECS[PLAYER_CLASS][spec]) then
		return false;
	end
	
	return TANK_SPECS[PLAYER_CLASS][spec]();
end

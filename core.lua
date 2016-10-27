------------------------------------------------------------
-- Buffy by Sonaza
-- All rights reserved
-- http://sonaza.com
------------------------------------------------------------


local ADDON_NAME = ...;
local Addon = LibStub("AceAddon-3.0"):NewAddon(select(2, ...), ADDON_NAME, "AceEvent-3.0");
_G[ADDON_NAME] = Addon;

local _;
local ADDON_NAME, SHARED_DATA = ...;

-- RELOAD UI short command
SLASH_RELOADUI1 = "/rl"
SlashCmdList["RELOADUI"] = ReloadUI

local LE = {};
Addon.LE = LE;

LE.BUFFS = {};

function Addon:AddBuffSpell(spell, categories, name)
	if(not spell or not categories) then return end
	
	if(name) then
		LE.BUFFS[name] = spell;
	end
end

local function GetGCD()
	local start, duration = GetSpellCooldown(61304);
	if(start > 0 and duration > 0) then
		return start + duration - GetTime();
	end
	
	return 0;
end

function Addon:IsSpellReady(spellID)
	local start, duration, enable = GetSpellCooldown(LE.BUFFS.WARLOCK_SOULSTONE);
	if(start ~= nil and duration ~= nil) then
		if((start + duration - GetTime()) - GetGCD() <= 0.0) then
			return true
		end
	end
	
	return false;
end

function Addon:GetItemID(itemLink)
	if(not itemLink) then return end
	
	local itemID = strmatch(itemLink, "item:(%d+)");
	return itemID and tonumber(itemID) or nil;
end

----------------------------------------------------------

function Addon:AddBuffItems(item_table, expansion, stat_type, items)
	if(not item_table or type(item_table) ~= "table") then return end
	if(not items or not stat_type) then return end
	
	item_table[expansion] = item_table[expansion] or {};
	item_table[expansion][stat_type] = items;
end

function Addon:AddItemSpell(item, spell)
	if(not item or not spell) then return end
	BUFFY_ITEM_SPELLS[item] = spell; 
end

Addon.SummonedFeasts = {};

function Addon:GetFoodPreference(skip_custom)
	local ratings_list = {};
	
	for stat, ratingFunction in pairs(LE.RATING_IDENTIFIERS) do
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
	
	local specIndex = GetSpecialization();
	
	-- Reset player selection of stamina food because there is no stamina food anymore
	if(UnitLevel("player") >= 110 and self.db.char.FoodPriority[specIndex] == LE.STAT.STAMINA) then
		self.db.char.FoodPriority[specIndex] = LE.STAT.AUTOMATIC;
	end
	
	local customFood = self.db.char.FoodPriority[specIndex];
	
	local sorted = {};
	
	if(not skip_custom and customFood ~= LE.STAT.AUTOMATIC) then
		tinsert(sorted, customFood);
	end
	
	-- Stam food for tanks?
	if(UnitLevel("player") < 109 and Addon:PlayerInTankSpec() and not self.db.global.ConsumablesRemind.SkipStamina and (skip_custom or customFood ~= LE.STAT.STAMINA)) then
		tinsert(sorted, LE.STAT.STAMINA);
	end
	
	for _, data in ipairs(ratings_list) do
		if(skip_custom or customFood ~= data.stat) then
			tinsert(sorted, data.stat);
		end
	end
	
	return sorted;
end

local function GetSpellName(spell)
	local name = GetSpellInfo(spell);
	return name;
end

function Addon:IsPlayerEating()
	-- Find localized name for the eating food buff, there are too many buff ids to manually check
	local localizedFoods = {
		GetSpellName(33264),
		GetSpellName(192002),
	};
	
	for _, localizedFood in ipairs(localizedFoods) do
		local name, _, icon, _, _, duration, expirationTime, _, _, _, spellId = UnitBuff("player", localizedFood);
		
		if(name) then
			return true, duration - (expirationTime - GetTime()), spellId;
		end
	end
	
	return false;
end

function Addon:IsPlayerWellFed()
	-- Find localized name for the food buff, there are too many buff ids to manually check
	local localizedFood = GetSpellInfo(180748);
	local name, _, icon, _, _, _, expirationTime, _, _, _, spellId = UnitBuff("player", localizedFood);
	
	if(name) then
		return true, Addon:WillBuffExpireSoon(expirationTime - GetTime()), spellId;
	end
	
	return false, false, nil;
end

--------------------------------------------

function Addon:OnInitialize()
	SLASH_BUFFY1	= "/bf";
	SLASH_BUFFY2	= "/buffy";
	SlashCmdList["BUFFY"] = function(message)
		Addon:SlashHandler(message);
	end
	
	SLASH_BUFFYINTERNAL1	= "/buffy_cast_custom_alert";
	SlashCmdList["BUFFYINTERNAL"] = function(message)
		Addon:CastCurrentCustom();
	end
	
	Addon:InitializeDatabase();
end

function Addon:OnEnable()
	Addon:RegisterEvent("UNIT_AURA");
	Addon:RegisterEvent("BAG_UPDATE_DELAYED");
	Addon:RegisterEvent("PLAYER_ALIVE");
	Addon:RegisterEvent("PLAYER_UNGHOST", "PLAYER_ALIVE");
	Addon:RegisterEvent("PLAYER_TALENT_UPDATE");
	Addon:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED");
	Addon:RegisterEvent("PLAYER_EQUIPMENT_CHANGED");
	Addon:RegisterEvent("PLAYER_REGEN_DISABLED");
	Addon:RegisterEvent("PLAYER_REGEN_ENABLED");
	Addon:RegisterEvent("ZONE_CHANGED");
	Addon:RegisterEvent("ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED");
	Addon:RegisterEvent("COMPANION_UPDATE");
	
	local _, PLAYER_CLASS = UnitClass("player");
	if(PLAYER_CLASS == "WARLOCK") then
		Addon:RegisterEvent("UNIT_PET");
	end
	
	Addon:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
	
	Addon:RegisterEvent("PLAYER_STARTED_MOVING");
	Addon:RegisterEvent("PLAYER_STOPPED_MOVING");
	
	Addon:InitializeDatabroker();

	Addon.IsFrameLocked = true;
	
	Addon:UpdateBuffs();
	
	CreateFrame("Frame"):SetScript("OnUpdate", function(self, elapsed)
		self.elapsed = (self.elapsed or 0) + elapsed;
		
		if(self.elapsed >= 5.0 or (Addon.ShowingAlert and self.elapsed >= 1.0)) then
			Addon:UpdateBuffs();
			self.elapsed = 0;
		end
		
		if(not IsFalling() and (Addon.PlayerStoppedMoving or self.fallFlagged) and Addon.PlayerIsMoving) then
			Addon:PLAYER_STOPPED_MOVING_FINISH();
			self.fallFlagged = false;
		elseif(IsFalling() and not Addon.PlayerIsMoving) then
			Addon:PLAYER_STARTED_MOVING();
			self.fallFlagged = true;
		end
	end);
end

function Addon:PLAYER_STARTED_MOVING()
	Addon.PlayerStoppedMoving = false;
	
	if(Addon.PlayerIsMoving) then return end
	Addon.PlayerIsMoving = true;
	
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
			Addon:ClearTempBind();
		end
	end
end

function Addon:PLAYER_STOPPED_MOVING()
	Addon.PlayerStoppedMoving = true;
end

function Addon:PLAYER_STOPPED_MOVING_FINISH()
	Addon.PlayerIsMoving = false;
	
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
			Addon:RestoreLastTempBind();
		end
	end
end

LE.GROUP_TYPE = {
	SOLO 	= 0x1,
	PARTY 	= 0x2,
	RAID	= 0x3,
};

function Addon:GetGroupType()
	if(IsInRaid()) then
		return LE.GROUP_TYPE.RAID;
	elseif(IsInGroup()) then
		return LE.GROUP_TYPE.PARTY;
	end
	
	return LE.GROUP_TYPE.SOLO;
end

function Addon:GetRealSpellID(spell_id)
	local spell_name = GetSpellInfo(spell_id);
	local name, _, _, _, _, _, realSpellID = GetSpellInfo(spell_name);
	
	return realSpellID or spell_id;
end

function Addon:ZONE_CHANGED()
	Addon:UpdateBuffs();
end

function Addon:UNIT_AURA()
	Addon:UpdateBuffs();
end

function Addon:UNIT_PET()
	Addon:UpdateBuffs();
end

function Addon:COMPANION_UPDATE(event, companiontype)
	if(companiontype == "MOUNT") then
		Addon:UpdateBuffs();
	end
end

function Addon:PLAYER_SPECIALIZATION_CHANGED()
	Addon:PLAYER_TALENT_UPDATE();
end

function Addon:BAG_UPDATE_DELAYED()
	if(self.db.global.ConsumablesRemind.Enabled) then
		Addon:UpdateBuffs();
	end
end

function Addon:PLAYER_EQUIPMENT_CHANGED()
	Addon:UpdateBuffs();
end

function Addon:PLAYER_REGEN_DISABLED()
	Addon:UpdateBuffs(true);
	Addon.IsFrameLocked = true;
	BuffyFrame:EnableMouse(false);
	
	BuffySpellButtonFrame:SetAttribute("type1", nil);
	
	-- No need to scan feasts in combat
	Addon:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
end

function Addon:PLAYER_REGEN_ENABLED()
	Addon:UpdateBuffs(true);
	BuffyFrame:EnableMouse(true);
	
	-- Register event again for feast scanning
	Addon:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
end

function Addon:PLAYER_TALENT_UPDATE()
	Addon:UpdateBuffs();
end

function Addon:PLAYER_ALIVE()
	Addon:UpdateBuffs();
end

function Addon:PlayerHasTalent(tier, column)
	local talentID, _, _, selected = GetTalentInfo(tier, column, 1);
	return talentID and selected;
end

function Addon:UnitAura(unit, spell_name, rank, flags)
	return UnitAura(unit, spell_name, rank, flags);
end

function Addon:UnitHasBuff(unit, spell)
	if(not unit or not spell) then return false end
	
	local realSpellID = Addon:GetRealSpellID(spell);
	local spell_name = GetSpellInfo(realSpellID);
	if(not spell_name) then return false end
	
	local name, _, _, _, _, duration, expirationTime, unitCaster = Addon:UnitAura(unit, spell_name, nil, "HELPFUL");
	if(not name) then
		return false;
	end
	
	return true, unitCaster == "player", unitCaster, expirationTime - GetTime(), duration;
end

function Addon:UnitInRange(unit, extended)
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

function Addon:GetUnitID(group_type, index)
	if(group_type == LE.GROUP_TYPE.SOLO or group_type == LE.GROUP_TYPE.PARTY) then
		return partyUnitID[index];
	elseif(group_type == LE.GROUP_TYPE.RAID) then
		return string.format("raid%d", index);
	end
	
	return nil;
end

local function GroupIterator()
	local index = 0;
	local groupType = Addon:GetGroupType();
	local numGroupMembers = GetNumGroupMembers();
	if(groupType == LE.GROUP_TYPE.SOLO) then numGroupMembers = 1 end
	
	return function()
		index = index + 1;
		if(index <= numGroupMembers) then
			return index, Addon:GetUnitID(groupType, index);
		end
	end
end

function Addon:GetPlayerUnitID()
	local groupType = Addon:GetGroupType();
	if(groupType == LE.GROUP_TYPE.SOLO or groupType == LE.GROUP_TYPE.PARTY) then
		return "player";
	elseif(groupType == LE.GROUP_TYPE.RAID) then
		for index, unit in GroupIterator() do
			if(UnitIsUnit(unit, "player")) then
				return Addon:GetUnitID(groupType, index);
			end
		end
	end
	
	return nil;
end

function Addon:UnitIsPet(searchunit)
	if(not searchunit) then return false end
	
	local pets = {};
	for index, unit in GroupIterator() do
		if(UnitExists(unit .. "pet") and UnitIsUnit(searchunit, unit .. "pet")) then
			return true, UnitName(unit), UnitName(unit .. "pet");
		end
	end
	
	return false;
end

function Addon:GetNumPartyMembers()
	if(Addon:GetGroupType() == LE.GROUP_TYPE.SOLO) then
		return 1;
	end
	
	return GetNumGroupMembers();
end

function Addon:UnitHasSomeBuff(unit, bufflist)
	for _, buff in ipairs(bufflist) do
		if(IsSpellKnown(buff)) then
			local hasBuff, isCastByPlayer, caster, remaining, duration = Addon:UnitHasBuff(unit, buff);
			if(hasBuff) then
				return true, buff, Addon:WillBuffExpireSoon(remaining), remaining, duration;
			end
		end
	end
	
	return false, bufflist[1], false, nil, nil;
end

local function IsReallyMounted()
	return IsFlying() or UnitOnTaxi("player") or UnitInVehicle("player");
end

function Addon:WillBuffExpireSoon(remaining)
	return remaining > 0 and remaining <= self.db.global.ExpirationAlertThreshold;
end

function Addon:GetConsumableCategories()
	local categories = {};
	
	local level = UnitLevel("player");
	
	if(level > 100) then
		tinsert(categories, LE.CONSUMABLE_CATEGORY.LEGION);
	end
	
	if(level <= 100 or self.db.global.ConsumablesRemind.OutdatedConsumables) then
		tinsert(categories, LE.CONSUMABLE_CATEGORY.DRAENOR);
	end
	
	tinsert(categories, LE.CONSUMABLE_CATEGORY.GENERIC);
	
	return categories;
end

function Addon:GetConsumableExpansionLevel()
	local level = UnitLevel("player");
	if(level > 100) then
		return LE.EXPANSION.LEGION;
	end
	
	return LE.EXPANSION.DRAENOR;
end

function Addon:GetConsumablesTable(tableName, categories)
	if(not tableName or not BUFFY_CONSUMABLES[tableName]) then
		error("Addon:GetConsumablesTable(tableName, categories): Invalid table name", 2);
		return nil;
	end
	
	if(type(categories) ~= "table" and type(categories) ~= "number") then
		error("Addon:GetConsumablesTable(tableName, categories): Invalid category, must be a number or a table", 2);
		return nil;
	end
	
	local result = {};
	
	if(type(categories) == "number") then
		categories = { categories };
	end
	
	for _, category in ipairs(categories) do
		if(BUFFY_CONSUMABLES[tableName][category]) then
			for subcategory, consumables in pairs(BUFFY_CONSUMABLES[tableName][category]) do
				result[subcategory] = result[subcategory] or {};
				
				for _, item in ipairs(consumables) do
					tinsert(result[subcategory], item);
				end
			end
		end
	end
	
	return result;
end

function Addon:PlayerHasConsumableBuff(consumable_type, preferredStat)
	local hasBuff, consumableID, buffExpiring;
	
	local consumablesList = nil;
	
	local categories = Addon:GetConsumableCategories();
	if(consumable_type == LE.CONSUMABLE_FLASK) then
		consumablesList = Addon:GetConsumablesTable("FLASKS", categories);
	elseif(consumable_type == LE.CONSUMABLE_RUNE) then
		consumablesList = Addon:GetConsumablesTable("RUNES", categories);
	end
	
	if(consumablesList ~= nil and type(consumablesList) == "table") then
		for _, itemID in ipairs(consumablesList[preferredStat]) do
			local spellID = BUFFY_ITEM_SPELLS[itemID]; 
			local hasBuff, _, _, remaining = Addon:UnitHasBuff("player", spellID);
			if(hasBuff) then
				return true, itemID, spellID, Addon:WillBuffExpireSoon(remaining);
			end
		end
	end
	
	return false, nil, nil, false;
end

local INSTANCETYPE_RAID 	= 0x1;
local INSTANCETYPE_DUNGEON 	= 0x2;

function Addon:PlayerInValidInstance(expansionLevel, includeDungeons, includeLFR)
	local expansionLevel = expansionLevel or LE.EXPANSION.LEGION;
	
	local includeDungeons = includeDungeons or false;
	if(includeDungeons == nil) then includeDungeons = false end
	
	local includeLFR = includeLFR;
	if(includeLFR == nil) then includeLFR = true end
	
	local name, instanceType, difficultyID, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, mapID, instanceGroupSize = GetInstanceInfo();
	
	if(instanceType ~= "raid" and instanceType ~= "party") then return false end
	if(not includeLFR and (difficultyID == 7 or difficultyID == 17)) then return false end
	
	local instanceMapIDs = {
		[LE.EXPANSION.DRAENOR] = {
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
		},
		
		[LE.EXPANSION.LEGION] = {
			[1520] = INSTANCETYPE_RAID, -- The Emerald Nightmare
			[1530] = INSTANCETYPE_RAID, -- The Nighthold
			
			[1456] = INSTANCETYPE_DUNGEON, -- Eye of Azshara
			[1458] = INSTANCETYPE_DUNGEON, -- Neltharion's Lair
			[1466] = INSTANCETYPE_DUNGEON, -- Darkheart Thicket
			[1477] = INSTANCETYPE_DUNGEON, -- Halls of Valor
			[1492] = INSTANCETYPE_DUNGEON, -- Maw of Souls
			[1493] = INSTANCETYPE_DUNGEON, -- Vault of the Wardens
			[1501] = INSTANCETYPE_DUNGEON, -- Black Rook Hold
			[1544] = INSTANCETYPE_DUNGEON, -- Violet Hold
			[1516] = INSTANCETYPE_DUNGEON, -- The Arcway
			[1571] = INSTANCETYPE_DUNGEON, -- Court of Stars
			
		},
	};
	
	if(instanceMapIDs[expansionLevel] and instanceMapIDs[expansionLevel][mapID]) then
		return instanceMapIDs[expansionLevel][mapID] == INSTANCETYPE_RAID or (includeDungeons and instanceMapIDs[expansionLevel][mapID] == INSTANCETYPE_DUNGEON);
	end
	
	-- Hacky area map id fallback
	-- local areaMapIDs = {
	-- 	[LE.EXPANSION.LEGION] = {
	-- 		[1094] = INSTANCETYPE_RAID, -- The Emerald Nightmare
	-- 		[1088] = INSTANCETYPE_RAID, -- The Nighthold
	-- 	},
	-- };
	
	-- if(not areaMapIDs[expansionLevel]) then return false end
	
	-- local areaMapID = GetCurrentMapAreaID();
	-- local hasAreaMapIDMatch = areaMapIDs[expansionLevel][areaMapID] ~= nil;
	
	-- if(not hasAreaMapIDMatch) then
	-- 	local zoneText = GetZoneText();
		
	-- 	for mapID, instanceType in pairs(areaMapIDs) do
	-- 		if(zoneText == GetMapNameByID(mapID)) then
	-- 			areaMapID = mapID;
	-- 			hasAreaMapIDMatch = true;
	-- 			break;
	-- 		end
	-- 	end
	-- end
	
	-- if(hasAreaMapIDMatch) then
	-- 	return areaMapIDs[expansionLevel][areaMapID] == INSTANCETYPE_RAID or (includeDungeons and areaMapIDs[expansionLevel][areaMapID] == INSTANCETYPE_DUNGEON);
	-- end
	
	return false;
end

function Addon:IsPlayerInLFR()
	local name, instanceType, difficultyID = GetInstanceInfo();
	if(instanceType == "raid" and (difficultyID == 7 or difficultyID == 17)) then return true end
	
	return false;
end

function Addon:FlaskIsNonConsumable(itemID)
	return itemID == 118922 or itemID == 86569 or itemID == 129192;
end

function Addon:RuneIsNonConsumable(itemID)
	return itemID == 128482 or itemID == 128475;
end

-- Buffy:GetConsumablesTable("RUNES", Buffy:GetConsumableCategories())
-- Buffy:FindBestConsumableItem(2, 1)

function Addon:FindBestConsumableItem(consumable_type, preferredStat)
	local consumablesList = nil;
	
	local categories = Addon:GetConsumableCategories();
	
	if(consumable_type == LE.CONSUMABLE_FLASK) then
		consumablesList = Addon:GetConsumablesTable("FLASKS", categories);
	elseif(consumable_type == LE.CONSUMABLE_RUNE) then
		consumablesList = Addon:GetConsumablesTable("RUNES", categories);
	elseif(consumable_type == LE.CONSUMABLE_FOOD) then
		consumablesList = Addon:GetConsumablesTable("FOODS", categories);
		
		local specIndex = GetSpecialization();
		if(self.db.char.FoodPriority[specIndex] == LE.STAT.CUSTOM) then
			consumablesList[LE.STAT.CUSTOM] = {
			 	self.db.char.CustomFoods[specIndex],
			}
		end
	end
	
	if(consumablesList ~= nil and type(consumablesList) == "table") then
		local PLAYER_LEVEL = UnitLevel("player");
		for _, itemID in ipairs(consumablesList[preferredStat]) do
			local skip = false;
			
			if(consumable_type == LE.CONSUMABLE_FLASK and self.db.global.ConsumablesRemind.OnlyInfiniteFlask and not Addon:PlayerInInstance() and not Addon:FlaskIsNonConsumable(itemID)) then
				skip = true;
			end
			
			if(consumable_type == LE.CONSUMABLE_RUNE and PLAYER_LEVEL == 110 and Addon:RuneIsNonConsumable(itemID)) then
				skip = true;
			end
			
			if(not skip) then
				local count = GetItemCount(itemID);
				if(count > 0) then
					local _, _, _, _, reqLevel = GetItemInfo(itemID);
					if((reqLevel or 0) <= PLAYER_LEVEL) then
						return itemID, count;
					end
				end
			end
		end
	end
	
	return nil, 0;
end

function Addon:IsUnitInParty(sourceName)
	if(not sourceName) then return false end
	
	for index, unit in GroupIterator() do
		if(UnitIsUnit(unit, sourceName)) then return true end
	end
	
	return false;
end

function Addon:COMBAT_LOG_EVENT_UNFILTERED(_, timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)
	-- Check if someone in raid group created something
	if(event == "SPELL_CREATE" and Addon:IsUnitInParty(sourceName)) then
		local spellId, spellName, spellSchool = ...;
		
		local expansionLevel = Addon:GetConsumableExpansionLevel();
		
		if(BUFFY_CONSUMABLES.FEASTS[expansionLevel][spellId] ~= nil) then
			local _, _, _, instance = UnitPosition(sourceName);
			
			Addon.SummonedFeasts[spellId] = {
				instance = instance,
				time = GetTime(),
			};
			
			Addon:UpdateBuffs();
		end
	end
end

function Addon:GetPlayerDistanceToPoint(pinstance, px, py)
	-- local x, y, _, instance = UnitPosition("player");
	-- return instance == pinstance and (((px - x) ^ 2 + (py - y) ^ 2) ^ 0.5) / 1.098;
	return -1;
end

function Addon:IsFeastUp()
	for _, data in pairs(Addon.SummonedFeasts) do
		return true;
	end
	
	return false;
end

Addon.LastBuffsUpdate = 0;
function Addon:ShouldDoUpdate()
	return not InCombatLockdown() or debugprofilestop() >= Addon.LastBuffsUpdate + 950;
end

LE.BUFF_STATE = {
	NO_BUFF 			= 0,
	HAS_BUFF 			= 1,
	HAS_BUFF_BY_PLAYER  = 2,
};

function Addon:ScanBuffList(bufflist)
	if(not bufflist or type(bufflist) ~= "table") then return nil end
	
	local partyBuffState = {};
	
	for _, spell in ipairs(bufflist) do
		if(not spell) then return nil end
		
		for index, unit in GroupIterator() do
			local buffState = LE.BUFF_STATE.NO_BUFF;
			
			local hasBuff, isCastByPlayer, unitCaster, remaining, duration = Addon:UnitHasBuff(unit, spell);
			local willExpireSoon = nil;
			
			if(hasBuff) then
				willExpireSoon = Addon:WillBuffExpireSoon(remaining);
				
				if(not isCastByPlayer) then
					buffState = LE.BUFF_STATE.HAS_BUFF;
				else
					buffState = LE.BUFF_STATE.HAS_BUFF_BY_PLAYER;
				end
			end
				
			partyBuffState[unit] = {
				state       = buffState,
				remaining   = remaining,
				expiring    = willExpireSoon,
				caster      = unitCaster,
			};
		end
	end
	
	return partyBuffState;
end

-- Buffy:ScanExclusiveBuffList({ 203528, 203538, 203539 })
function Addon:ScanExclusiveBuffList(bufflist)
	if(not bufflist or type(bufflist) ~= "table") then return nil end
	
	local partyBuffs = {
		["player"] = {},
	};
	
	for _, spell in ipairs(bufflist) do
		if(not spell) then return nil end
		
		for index, unit in GroupIterator() do
			local hasBuff, isCastByPlayer, unitCaster, remaining, duration = Addon:UnitHasBuff(unit, spell);
			unitCaster = unitCaster or "unknown";
			
			if(hasBuff) then
				partyBuffs[unitCaster] = partyBuffs[unitCaster] or {};
				
				tinsert(partyBuffs[unitCaster], {
					spell       = spell,
					unit        = unit,
					remaining   = remaining,
					expiring    = Addon:WillBuffExpireSoon(remaining),
				});
			end
		end
	end
	
	return partyBuffs;
end

-- Buffy:UnitMissingSomeBuff({ 203528, 203538, 203539 })
function Addon:UnitMissingSomeBuff(unit, bufflist)
	if(not bufflist or type(bufflist) ~= "table") then return nil end
	
	for index, spell in ipairs(bufflist) do
		local hasBuff = Addon:UnitHasBuff(unit, spell);
		if(not hasBuff) then return true, spell, index end
	end
	
	return false;
end

-- Buffy:ScanMissingPartyBuffsByRole({["DAMAGER"]= { 203528, 203538, 203539 },["TANK"]= { 203538, 203539, 203528 },["HEALER"]= { 203538, 203539, 203528 },["NONE"]= { 203538, 203528, 203539 },})
-- Buffy:ScanMissingPartyBuffsByRole({ 203528, 203538, 203539 })
function Addon:ScanMissingPartyBuffsByRole(bufflist)
	if(not bufflist or type(bufflist) ~= "table") then return nil end
	
	local missingBuffs = {};
	
	for index, unit in GroupIterator() do
		if(Addon:UnitInRange(unit)) then
			local unitRole = UnitGroupRolesAssigned(unit);
			
			for _, spell in ipairs(bufflist[unitRole]) do
				if(not spell) then return nil end
				
				local hasBuff = Addon:UnitHasBuff(unit, spell);
				
				if(not hasBuff) then
					missingBuffs[unitRole]       = missingBuffs[unitRole] or {};
					missingBuffs[unitRole][unit] = missingBuffs[unitRole][unit] or {};
					
					tinsert(missingBuffs[unitRole][unit], spell);
				end
			end
		end
	end
	
	return missingBuffs;
end

function Addon:InArray(haystack, needle)
	for _, value in pairs(haystack) do
		if(value == needle) then return true end
	end
	return false;
end

function Addon:UpdateBuffs(forceUpdate)
	if(Addon:ShouldDoUpdate() or forceUpdate) then
		Addon:UpdateDatabrokerText();
	elseif(InCombatLockdown()) then
		return;
	end
	
	Addon.LastBuffsUpdate = debugprofilestop();
	
	if(not self.db.global.ShowInCombat and InCombatLockdown()) then
		Addon:HideBuffyAlert();
		return;
	end
	
	local inInstance, instanceType = Addon:PlayerInInstance();
	
	local hideAlert = not self.db.global.Enabled or UnitIsDeadOrGhost("player") or
					  (self.db.global.DisableOutside and not inInstance) or
					  (self.db.global.DisableWhenResting and IsResting()) or
					  (not self.db.global.ShowWhileMounted and IsReallyMounted()) or
					  C_PetBattles.IsInBattle();
	
	if(hideAlert) then
		Addon:HideBuffyAlert();
		return;
	end
	
	local canShowExpiration = not InCombatLockdown() or (InCombatLockdown() and not self.db.global.NoExpirationAlertInCombat);
	
	local _, PLAYER_CLASS = UnitClass("player");
	local PLAYER_SPEC = GetSpecialization();
	local PLAYER_LEVEL = UnitLevel("player");
	
	-- Try to find a spec based list and if not found default to basic list
	local buffs = Addon:GetClassCastableBuffs(PLAYER_CLASS, PLAYER_SPEC);
	if(not buffs) then return false end
	
	local playerCastExists = false;
	local shouldCastSpell = false;
	local castSpellID;
	
	local infoUnits = {};
	
	for _, data in ipairs(buffs) do
		data.vars = data.vars or {};
		
		local valid = true;
		
		if(data.hasTalent) then
			valid = valid and Addon:PlayerHasTalent(data.hasTalent[1], data.hasTalent[2]);
		end
		
		if(data.noTalent) then
			valid = valid and not Addon:PlayerHasTalent(data.noTalent[1], data.noTalent[2]);
		end
		
		if(data.condition and type(data.condition) == "function") then
			valid = valid and data.condition(data.vars);
		end
		
		if(valid) then
			if(not UnitIsDeadOrGhost("player")) then
				if(not data.bufflist and data.skipBuffCheck) then
					local alertType;
					local alertID;
					
					if(data.info) then
						if(data.info.type == "item" or data.info.type == "toy") then
							alertType = LE.ALERT_TYPE_ITEM;
						elseif(data.info.type == "spell") then
							alertType = LE.ALERT_TYPE_SPELL;
						elseif(data.info.type == "custom") then
							alertType = LE.ALERT_TYPE_CUSTOM;
						end
						
						alertID = data.info.id;
					end
					
					if(alertType and alertID) then
						Addon:ShowBuffyAlert(alertType, alertID, {
								primary     = data.primary,
								secondary   = data.secondary,
								description = data.description,
								info        = data.info,
								noCast      = data.noCast,
								cast        = data.cast,
								icon        = data.icon,
							},
							data.vars
						);
						return;
					end
				elseif(type(data.bufflist) == "function") then
					local shouldAlert, buffSpell, buffTarget = data.bufflist(data.vars);
					
					if(data.skipBuffCheck or shouldAlert and IsSpellKnown(buffSpell)) then
						local alertType = LE.ALERT_TYPE_SPELL;
						local alertID = buffSpell;
						
						if(data.info) then
							if(data.info.type == "item" or data.info.type == "toy") then
								alertType = LE.ALERT_TYPE_ITEM;
							elseif(data.info.type == "spell") then
								alertType = LE.ALERT_TYPE_SPELL;
							end
							
							alertID = data.info.id;
						end
							
						Addon:ShowBuffyAlert(alertType, alertID, {
								primary     = data.primary,
								secondary   = data.secondary,
								description = data.description,
								target      = buffTarget,
								info        = data.info,
								noCast      = data.noCast,
								icon        = data.icon,
							},
							data.vars
						);
						return;
					end
				else
					local hasBuff, buffSpell, buffExpiring = Addon:UnitHasSomeBuff("player", data.bufflist);
					
					if(data.skipBuffCheck or (not hasBuff or (buffExpiring and canShowExpiration)) and buffSpell and IsSpellKnown(buffSpell)) then
						Addon:ShowBuffyAlert(LE.ALERT_TYPE_SPELL, buffSpell, {
								primary     = data.primary,
								secondary   = data.secondary,
								description = data.description,
								info        = data.info,
								expiring    = buffExpiring,
								remaining   = Addon:GetBuffRemaining("player", buffSpell),
								noCast      = data.noCast,
								icon        = data.icon,
							},
							data.vars
						);
						
						return;
					end
				end
			end
		end
	end
	
	-- Clear binds before flask remind since user may not have keybinds enabled
	Addon:ClearTempBind();
	
	--------------------------------------------------
	-- Consumables check
	
	local canShowConsumableAlert = not InCombatLockdown() or not self.db.global.ConsumablesRemind.NotInCombat;
	if(canShowConsumableAlert and self.db.global.ConsumablesRemind.Enabled and PLAYER_LEVEL >= 90) then
		local expansionLevel = Addon:GetConsumableExpansionLevel();
		
		local inValidInstance;
		if(self.db.global.ConsumablesRemind.Mode == LE.RAID_CONSUMABLES.EVERYWHERE) then
			inValidInstance = true;
		elseif(self.db.global.ConsumablesRemind.Mode == LE.RAID_CONSUMABLES.EVERYWHERE_NOT_RESTING and not IsResting()) then
			inValidInstance = true;
		else
			local enableDungeons = self.db.global.ConsumablesRemind.Mode == LE.RAID_CONSUMABLES.RAIDS_AND_DUNGEONS;
			inValidInstance = Addon:PlayerInValidInstance(expansionLevel, enableDungeons, not self.db.global.ConsumablesRemind.DisableInLFR);
			
			if(self.db.global.ConsumablesRemind.DisableInLFR and Addon:IsPlayerInLFR()) then
				inValidInstance = false;
			end
		end
		
		local inValidGroup = not self.db.global.ConsumablesRemind.DisableOutsideGroup or (IsInGroup() or IsInRaid());
		
		if(inValidInstance and inValidGroup) then
			local preferredStats = Addon:GetStatPreference(PLAYER_CLASS, PLAYER_SPEC);
			
			if(self.db.global.ConsumablesRemind.Flasks) then
				-- Loop through preferred stat types
				for _, preferredStat in ipairs(preferredStats) do
					local playerHasFlask, itemID, spellID, buffExpiring = Addon:PlayerHasConsumableBuff(LE.CONSUMABLE_FLASK, preferredStat);
					
					if(not playerHasFlask or (buffExpiring and canShowExpiration)) then
						-- Check if player has any flasks in their inventory
						local bestFlaskID, count = Addon:FindBestConsumableItem(LE.CONSUMABLE_FLASK, preferredStat);
						
						local cooldownExpired = true;
						
						-- Cooldown check for the non-consumable "flask" which has one
						if(Addon:FlaskIsNonConsumable(bestFlaskID)) then
							local startTime, duration = GetItemCooldown(bestFlaskID);
							cooldownExpired = (startTime == 0 and duration == 0);
							
							-- Reset count since the "flask" is not consumed
							count = nil;
						end
						
						if(bestFlaskID and cooldownExpired) then
							Addon:ShowBuffyAlert(LE.ALERT_TYPE_ITEM, bestFlaskID, {
								spellID = spellID,
								expiring = buffExpiring,
								count = count,
								remaining = Addon:GetBuffRemaining("player", spellID),
							});
							return;
						end
					end
					
					if(playerHasFlask and not buffExpiring) then break end
				end
			end
			
			if(self.db.global.ConsumablesRemind.Runes and PLAYER_LEVEL >= 100) then
				local checkForRunes = true;
				
				-- Nonconsumable rune has max level of 109
				if(PLAYER_LEVEL < 110 and self.db.global.ConsumablesRemind.OnlyInfiniteRune and GetItemCount(128482) == 0 and GetItemCount(128475) == 0) then
					checkForRunes = false;
				end
				
				if(checkForRunes) then
					-- Loop through preferred stat types
					for _, preferredStat in ipairs(preferredStats) do
						-- There are no stamina runes, skip!
						if(preferredStat ~= LE.STAT.STAMINA) then
							local playerHasRune, itemID, spellID, buffExpiring = Addon:PlayerHasConsumableBuff(LE.CONSUMABLE_RUNE, preferredStat);
							
							if(not playerHasRune or (buffExpiring and canShowExpiration)) then
								-- Check if player has any runes in their inventory
								local bestRuneID, count = Addon:FindBestConsumableItem(LE.CONSUMABLE_RUNE, preferredStat);
								
								local isInfiniteRune = Addon:RuneIsNonConsumable(bestRuneID);
								local cooldownExpired = true;
								
								-- Cooldown check for the non-consumable rune which has one
								if(isInfiniteRune) then
									local startTime, duration = GetItemCooldown(bestRuneID);
									cooldownExpired = (startTime == 0 and duration == 0);
									
									-- Reset count since infinite rune is not consumed
									count = nil;
								end
								
								if(bestRuneID and cooldownExpired) then
									Addon:ShowBuffyAlert(LE.ALERT_TYPE_ITEM, bestRuneID, {
										spellID = spellID,
										expiring = buffExpiring,
										count = count,
										remaining = Addon:GetBuffRemaining("player", spellID),
									});
									return;
								end
							end
						
							if(playerHasRune and not buffExpiring) then break end
						end
					end
				end
			end
			
			local isEating, timeEaten = Addon:IsPlayerEating();
			
			if(self.db.global.ConsumablesRemind.Food) then
				local isWellFed, buffExpiring, spellID = Addon:IsPlayerWellFed();
				
				if(not isEating and (not isWellFed or (buffExpiring and canShowExpiration))) then
					local showInventoryFoodAlert = self.db.global.ConsumablesRemind.FeastsMode == LE.FEASTS_MODE.OWN_FOOD or
												   (not Addon:IsFeastUp() and self.db.global.ConsumablesRemind.FeastsMode == LE.FEASTS_MODE.PRIORITY_FEASTS);
					
					if(showInventoryFoodAlert) then
						local preferredFoodStats = Addon:GetFoodPreference();
						
						-- Loop through preferred stat types
						for _, preferredStat in ipairs(preferredFoodStats) do
							-- Check if player has any food in their inventory
							local bestFoodID, count = Addon:FindBestConsumableItem(LE.CONSUMABLE_FOOD, preferredStat);
							
							if(bestFoodID) then
								Addon:ShowBuffyAlert(LE.ALERT_TYPE_ITEM, bestFoodID, {
									spellID = spellID,
									expiring = buffExpiring,
									count = count,
									primary = "Eat",
									remaining = Addon:GetBuffRemaining("player", spellID),
								});
								return;
							end
						end
					end
					
					if(Addon:IsFeastUp() and PLAYER_LEVEL >= 91) then
						local sorted_feasts = {};
						for spell, data in pairs(Addon.SummonedFeasts) do
							local tableExpires = (data.time + BUFFY_CONSUMABLES.FEASTS[expansionLevel][spell].duration) - GetTime();
							
							if(tableExpires > 0) then
								local _, _, _, instance = UnitPosition("player");
								-- Verify player and feast are at least in same instance
								if(instance == data.instance) then
									tinsert(sorted_feasts, { spell = spell, stats = BUFFY_CONSUMABLES.FEASTS[expansionLevel][spell].stats, });
								end
							else
								Addon.SummonedFeasts[spell] = nil;
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
							
							local feast = Addon.SummonedFeasts[spellId];
							local data = BUFFY_CONSUMABLES.FEASTS[expansionLevel][spellId];
							
							local tableExpires = (feast.time + data.duration) - GetTime();
							
							local description = string.format("Feast Expires in %s", Addon:FormatTime(tableExpires));
							local itemName, _, _, _, _, _, _, _, _, icon = GetItemInfo(data.item);
							
							Addon:ShowBuffyAlert(LE.ALERT_TYPE_SPECIAL, LE.SPECIAL_FOOD, {
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
				Addon:ShowBuffyAlert(LE.ALERT_TYPE_SPECIAL, LE.SPECIAL_EATING, {
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
	
	for _, data in ipairs(LE.MISC_CASTABLE_BUFFS) do
		local valid = true;
		
		if(data.hasTalent) then
			valid = valid and Addon:PlayerHasTalent(data.hasTalent[1], data.hasTalent[2]);
		end
		
		if(data.noTalent) then
			valid = valid and not Addon:PlayerHasTalent(data.noTalent[1], data.noTalent[2]);
		end
		
		if(data.condition and type(data.condition) == "function") then
			valid = valid and data.condition(data.vars);
		end
		
		if(valid and data.bufflist and not UnitIsDeadOrGhost("player")) then
			
			if(type(data.bufflist) == "function") then
				local shouldAlert, buffSpell = data.bufflist(data.vars);
				
				if(data.skipBuffCheck or shouldAlert and IsSpellKnown(buffSpell)) then
					local alertType = LE.ALERT_TYPE_SPELL;
					local alertID = buffSpell;
					
					if(data.info) then
						if(data.info.type == "item" or data.info.type == "toy") then
							alertType = LE.ALERT_TYPE_ITEM;
						elseif(data.info.type == "spell") then
							alertType = LE.ALERT_TYPE_SPELL;
						end
						
						alertID = data.info.id;
					end
						
					Addon:ShowBuffyAlert(alertType, alertID, {
						primary = data.primary,
						secondary = data.secondary,
						description = data.description,
						info = data.info,
					});
					return;
				end
			else
				local hasBuff, buffSpell, buffExpiring = Addon:UnitHasSomeBuff("player", data.bufflist);
				
				if(data.skipBuffCheck or (not hasBuff or (buffExpiring and canShowExpiration)) and IsSpellKnown(buffSpell)) then
					Addon:ShowBuffyAlert(LE.ALERT_TYPE_SPELL, buffSpell, {
						primary = data.primary,
						secondary = data.secondary,
						description = data.description,
						info = data.info,
						expiring = buffExpiring,
						remaining = Addon:GetBuffRemaining("player", buffSpell),
					});
					
					return;
				end
			end
		end
	end
	
	if(not self.IsFrameLocked) then
		Addon:ShowBuffyAlert(LE.ALERT_TYPE_SPECIAL, LE.SPECIAL_UNLOCKED, {
			icon = "Interface\\Icons\\ability_garrison_orangebird",
			primary = "Buffy",
			secondary = "The frame is currently unlocked",
			description = "Right-click to view options",
		});
		return;
	end
	
	Addon:HideBuffyAlert();
end

function Addon:GetBuffRemaining(unit, spellID)
	if(not unit or not spellID) then return 0 end
	
	local realSpellID = Addon:GetRealSpellID(spellID);
	local spellName = GetSpellInfo(realSpellID);
	
	local name, _, _, _, _, _, expirationTime = UnitAura(unit, spellName, nil, "HELPFUL");
	if(name) then
		return expirationTime - GetTime();
	end
	
	return 0;
end

function Addon:FormatTime(t, literal)
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

function Addon:GetMultiValue(value, vars)
	if(type(value) == "function") then
		return value(vars);
	end
	return value;
end

function Addon:GetColorizedUnitName(unit)
	local name, server = UnitFullName(unit);
	if(server and server ~= GetRealmName()) then
		name = ("%s-%s"):format(name, string.sub(server, 1, 3));
	end
	
	local _, class = UnitClass(unit);
	local color = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[class or 'PRIEST'];
	
	return string.format("|c%s%s|r", color.colorStr, name);
end

function Addon:ShowBuffyAlert(alert_type, id, data, vars)
	if(not id) then return end
	
	local doAnimatedSwitch = false;
	local alertSignature = alert_type .. "@" .. id .. "@" .. (data.target or "notarget");
	
	if(Addon.CurrentAlert ~= alertSignature and BuffyFrame:IsShown()) then
		Addon:CopyAlertToSwitchFrame();
		doAnimatedSwitch = true;
	end
	
	Addon.CurrentAlert = alertSignature;
	
	Addon.ShowingAlert = true;
	BuffyFrame.Tooltip = nil;
	
	local _;
	local name, icon;
	
	local primaryText = Addon:GetMultiValue(data.primary, vars);
	local secondaryText = Addon:GetMultiValue(data.secondary, vars);
	local priorityIcon = Addon:GetMultiValue(data.icon, vars);
	
	local noCast = Addon:GetMultiValue(data.noCast, vars) or false;
	if(not InCombatLockdown()) then
		Addon:ClearTempBind();
	end
	
	local targetNameText = "";
	if(data.target) then
		targetNameText = string.format(" on %s", Addon:GetColorizedUnitName(data.target));
	end
	
	Addon.CurrentCustomCastFunction = nil;
	
	if(alert_type == LE.ALERT_TYPE_CUSTOM) then
		local realSpellID = Addon:GetRealSpellID(id);
		name, _, icon = GetSpellInfo(realSpellID);
		BuffyFrame.icon.texture:SetTexture(priorityIcon or icon);
		
		BuffyFrame.Tooltip = {
			type = LE.ALERT_TYPE_SPELL,
			id = realSpellID,
		};
		
		if(not InCombatLockdown() and not noCast and data.cast) then
			Addon.CurrentCustomCastFunction = data.cast;
			Addon:SetTempBind("custom");
		end
		
		BuffyFrame.title:SetFormattedText("|cfff1da54%s|r%s|n%s", primaryText or "Use", targetNameText, secondaryText or name or "<Error>");
	elseif(data.info and not data.noCast) then
		name, _, _, _, _, _, _, _, _, icon = GetItemInfo(data.info.id);
		BuffyFrame.icon.texture:SetTexture(priorityIcon or icon);
		
		BuffyFrame.Tooltip = {
			type = LE.ALERT_TYPE_ITEM,
			id = data.info.id,
		};
		
		if(not InCombatLockdown() and not noCast) then
			Addon:SetTempBind(data.info.type, data.info.id, data.target);
		end
		
		BuffyFrame.title:SetFormattedText("|cfff1da54%s|r%s|n%s", primaryText or "Use", targetNameText, secondaryText or name or "<Error>");
	elseif(alert_type == LE.ALERT_TYPE_SPELL) then
		local realSpellID = Addon:GetRealSpellID(id);
		name, _, icon = GetSpellInfo(realSpellID);
		BuffyFrame.icon.texture:SetTexture(priorityIcon or icon);
		
		BuffyFrame.Tooltip = {
			type = LE.ALERT_TYPE_SPELL,
			id = realSpellID,
		};
		
		if(not InCombatLockdown() and not noCast) then
			Addon:SetTempBind("spell", name, data.target);
		end
		
		BuffyFrame.title:SetFormattedText("|cfff1da54%s|r%s|n%s", primaryText or "Cast", targetNameText, secondaryText or name or "<Error>");
	elseif(alert_type == LE.ALERT_TYPE_ITEM) then
		name, _, _, _, _, _, _, _, _, icon = GetItemInfo(id);
		BuffyFrame.icon.texture:SetTexture(priorityIcon or icon);
		
		BuffyFrame.Tooltip = {
			type = LE.ALERT_TYPE_ITEM,
			id = id,
		};
		
		if(not InCombatLockdown() and self.db.global.ConsumablesRemind.KeybindEnabled and not noCast) then
			Addon:SetTempBind("item", name, data.target);
		end
		
		BuffyFrame.title:SetFormattedText("|cfff1da54%s|r%s|n%s", primaryText or "Use", targetNameText, secondaryText or name or "<Error>");
	elseif(alert_type == LE.ALERT_TYPE_SPECIAL) then
		BuffyFrame.icon.texture:SetTexture(priorityIcon);
		BuffyFrame.title:SetFormattedText("|cfff1da54%s|r|n%s", primaryText or "", secondaryText or "");
	end
	
	BuffyFrame.description:SetText("");
	BuffyFrame.description:Hide();
	
	if(data) then
		if(data.expiring and data.remaining) then
			if(alert_type == LE.ALERT_TYPE_ITEM and tonumber(data.count)) then
				BuffyFrame.description:SetFormattedText("Expiring in %s / You have |cfff1da54%d|r", Addon:FormatTime(data.remaining), data.count);
			else
				BuffyFrame.description:SetFormattedText("Expiring in %s", Addon:FormatTime(data.remaining));
			end
			BuffyFrame.description:Show();
		elseif(alert_type == LE.ALERT_TYPE_ITEM and tonumber(data.count)) then
			BuffyFrame.description:SetFormattedText("You have |cfff1da54%d|r in your inventory", tonumber(data.count));
			BuffyFrame.description:Show();
		elseif(data.description) then
			local text = Addon:GetMultiValue(data.description, vars);
			BuffyFrame.description:SetText(text);
			BuffyFrame.description:Show();
		end
	end
	
	if(not BuffyFrame:IsShown()) then
		BuffyFrame.fadein:Play();
		
		if(Addon.PlayerIsMoving) then
			Addon:PLAYER_STARTED_MOVING();
		end
	end
	
	if(doAnimatedSwitch) then
		Addon:PlayAnimatedSwitch();
	end
end

function Addon:CopyAlertToSwitchFrame()
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

function Addon:PlayAnimatedSwitch()
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
	if(not Addon.db.global.ShowTooltips) then return end
	if(not BuffyFrame.Tooltip) then return end
	
	GameTooltip:SetOwner(self, "ANCHOR_PRESERVE");
	GameTooltip:ClearAllPoints();
	GameTooltip:SetPoint("RIGHT", self, "LEFT", -6, 0);
	
	if(BuffyFrame.Tooltip.type == LE.ALERT_TYPE_SPELL) then
		GameTooltip:SetSpellByID(BuffyFrame.Tooltip.id);
	elseif(BuffyFrame.Tooltip.type == LE.ALERT_TYPE_ITEM) then
		GameTooltip:SetItemByID(BuffyFrame.Tooltip.id);
	end
	
	GameTooltip:Show();
	
	BuffyFrame.ShowingTip = true;
end

function BuffyIconFrame_OnLeave(self)
	GameTooltip:Hide();
	
	BuffyFrame.ShowingTip = false;
end

function Addon:HideBuffyAlert()
	Addon.ShowingAlert = false;
	BuffyFrame.Tooltip = nil;
	
	if(BuffyFrame.ShowingTip) then
		GameTooltip:Hide();
	end
	
	if(not InCombatLockdown()) then
		BuffySpellButtonFrame:SetAttribute("type1", nil);
		Addon:ClearTempBind();
	end
	
	if(BuffyFrame:IsShown()) then
		local alpha = BuffyFrame:GetAlpha();
		local animation = BuffyFrame.fadeout:GetAnimations();
		animation:SetFromAlpha(alpha);
		
		BuffyFrame.fadeout:Play();
	end
	
	Addon.LastTempBind = nil;
end

function Addon:PlayerInInstance()
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
	if(Addon.IsFrameLocked) then return end
	
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
	
	Addon.db.global.Position = {
		x = x,
		y = y,
		Point = point,
		RelativePoint = relativePoint,
		DefaultPosition = false,
	};
end

function BuffyFrame_RestorePosition()
	BuffyFrame:ClearAllPoints();
	
	if(not Addon.db.global or Addon.db.global.Position.DefaultPosition) then
		BuffyFrame:SetPoint("LEFT", UIParent, "CENTER", -22, GetScreenHeight() * 0.18);
	else
		local p = Addon.db.global.Position;
		BuffyFrame:SetPoint(p.Point, UIParent, p.RelativePoint, p.x, p.y);
	end
end

function BuffyFrame_ResetPosition()
	BuffyFrame:ClearAllPoints();
	BuffyFrame:SetPoint("LEFT", UIParent, "CENTER", -22, GetScreenHeight() * 0.18);
	
	local point, _, relativePoint, x, y = BuffyFrame:GetPoint();
	
	Addon.db.global.Position = {
		x = x,
		y = y,
		Point = point,
		RelativePoint = relativePoint,
		DefaultPosition = true,
	};
	
	BuffyFrame_RestorePosition();
end

function Addon:ResetPosition()
	BuffyFrame_ResetPosition();
end

local MESSAGE_PATTERN = "|cff3ebfeaBuffy|r %s";
function Addon:AddMessage(pattern, ...)
	DEFAULT_CHAT_FRAME:AddMessage(MESSAGE_PATTERN:format(string.format(pattern, ...)));
end

function Addon:GetBinding()
	return Addon.db.global.Keybind;
end

function Addon:CastCurrentCustom()
	if(not Addon.CurrentCustomCastFunction) then return end
	if(InCombatLockdown()) then return end
	pcall(Addon.CurrentCustomCastFunction);
end

function Addon:SetTempBind(bindType, name, target)
	if(not bindType) then return end
	if(bindType ~= "custom" and not name) then return end
	if(InCombatLockdown()) then return end
	
	if(self.db.global.UnbindWhenMoving and Addon.PlayerIsMoving) then return end
	
	BuffySpellButtonFrame:SetAttribute("type1", nil);
	BuffySpellButtonFrame:SetAttribute("macrotext1", nil);
	BuffySpellButtonFrame:SetAttribute("item1", nil);
	BuffySpellButtonFrame:SetAttribute("spell1", nil);
	BuffySpellButtonFrame:SetAttribute("unit1", "player");
	
	local key = Addon:GetBinding();
	if(key) then
		
		if(bindType == "custom") then
			BuffySpellButtonFrame:SetAttribute("type1", "macro");
			BuffySpellButtonFrame:SetAttribute("macrotext1", "/buffy_cast_custom_alert");
		else
			BuffySpellButtonFrame:SetAttribute("type1", bindType);
			
			if(bindType == "item" or bindType == "spell" or bindType == "toy") then
				BuffySpellButtonFrame:SetAttribute(bindType .. "1", name);
			end
			
			BuffySpellButtonFrame:SetAttribute("unit1", target or "player");
		end
		
		SetOverrideBindingClick(BuffyFrame, true, key, "BuffySpellButtonFrame", "LeftButton");
		
		Addon.LastTempBind = { bindType, name, target };
	end
end

function Addon:RestoreLastTempBind()
	if(not Addon.LastTempBind) then return end
	
	Addon:SetTempBind(unpack(Addon.LastTempBind));
end

function Addon:ClearTempBind()
	if(not InCombatLockdown()) then
		ClearOverrideBindings(BuffyFrame);
	end
end

function BuffyKeybindingFrame_OnShow()
	BuffyKeybindingFrame.bindkey = Addon:GetBinding();
	
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
	if(Addon:GetBinding()) then Addon:ClearTempBind(); end
	
	Addon.db.global.Keybind = BuffyKeybindingFrame.bindkey;
	Addon:UpdateBuffs();
	
	BuffyKeybindingFrameOuter:Hide();
end

function BuffySpellButtonFrame_OnClick()
	if(InCombatLockdown()) then
		Addon:AddMessage("Cannot cast recommended buff while in combat");
	end
end

function BuffyFrame_OnClick(self, button)
	if(button == "RightButton") then
		Addon:OpenContextMenu(BuffyFrame);
	end
end

function BuffyFrame_OnFadeInPlay(self)
	BuffyFrame:Show();
end

function BuffyFrame_OnFadeOutFinished(self)
	BuffyFrame:Hide();
end
------------------------------------------------------------
-- Buffy by Sonaza
------------------------------------------------------------

local ADDON_NAME, Addon = ...;
local LE = Addon.LE;
local _;

local LibDataBroker = LibStub:GetLibrary("LibDataBroker-1.1");
local AceDB = LibStub("AceDB-3.0")

local ICON_PATTERN_14 = "|T%s:14:14:0:0|t";
local BUFFY_ICON = "Interface\\Icons\\spell_arcane_invocation";

local TEX_BUFFY_ICON = ICON_PATTERN_14:format(BUFFY_ICON);

LE.FEASTS_MODE = {
	OWN_FOOD 		= 0x1,
	PRIORITY_FEASTS	= 0x2,
	ONLY_FEASTS		= 0x3,
}

LE.RAID_CONSUMABLES = {
	RAIDS_ONLY 					= 1,
	RAIDS_AND_DUNGEONS			= 2,
	EVERYWHERE 					= 3,
	EVERYWHERE_NOT_RESTING 		= 4,
};

function Addon:SlashHandler(message)
	local action, param1, param2 = strsplit(" ", strtrim(strlower(message or "")));
	
	if(not action or action == "") then
		Addon:OpenContextMenu(UIParent);
	elseif(action == "toggle") then
		self.db.global.Enabled = not self.db.global.Enabled;
		Addon:UpdateBuffs();
	elseif(action == "lock") then
		self.IsFrameLocked = true;
		Addon:UpdateBuffs();
	elseif(action == "unlock") then
		self.IsFrameLocked = false;
		Addon:UpdateBuffs();
	elseif(action == "help" or action == "halp" or action == "?") then
		Addon:AddChatMessage("Chat Command Usage");
		Addon:AddChatMessage("Available by typing /bf or /buffy");
		Addon:AddChatMessage("|cffffdc3b/buffy|r \124 Opens Options Menu Dialog");
		Addon:AddChatMessage("|cffffdc3b/buffy|r toggle \124 Toggles Buffy Notifications");
		Addon:AddChatMessage("|cffffdc3b/buffy|r lock and |cffffdc3b/buffy|r unlock \124 Lock/Unlock Frame");
	end
end

function Addon:InitializeDatabase()
	local defaults = {
		char = {
			FoodPriority = {
				[1] = LE.STAT.AUTOMATIC,
				[2] = LE.STAT.AUTOMATIC,
				[3] = LE.STAT.AUTOMATIC,
				[4] = LE.STAT.AUTOMATIC,
			},
			CustomFoods = {
				[1] = nil,
				[2] = nil,
				[3] = nil,
				[4] = nil,
			}
		},
		global = {
			Enabled = true,
			ShowInCombat = false,
			ShowWhileMounted = false,
			DisableOutside = false,
			DisableWhenResting = false,
			Keybind = nil,
			
			OverrideAuras = true,
			
			ShowTooltips = true,
			
			AlertMoveFade = true,
			UnbindWhenMoving = false,
			
			PepeReminderEnabled = false,
			
			Position = {
				DefaultPosition = true,
				x = nil,
				y = nil,
				Point = nil,
				RelativePoint = nil,
			},
			
			ExpirationAlertThreshold = 300,
			NoExpirationAlertInCombat = true,
			
			ConsumablesRemind = {
				Enabled = true,
				
				Mode = LE.RAID_CONSUMABLES.RAIDS_ONLY,
				
				Flasks = true,
				Runes = false,
				Food = true,
				
				OnlyInfiniteFlask = false,
				OnlyInfiniteRune = false,
				
				FeastsMode = LE.FEASTS_MODE.OWN_FOOD,
				EatingTimer = true,
				
				DisableInLFR = false,
				DisableOutsideGroup = false,
				
				SkipStamina = true,
				KeybindEnabled = false,
				NotInCombat = true,
				
				OutdatedConsumables = true,
			},
			
			Class = {
				Mage = {
					EnableArcaneFamiliar = true,	
				},
				Rogue = {
					EnableLethal = true,
					EnableNonlethal = true,
					SkipCrippling = false,
					WoundPoisonPriority = false,
					RefreshBoth = false,
					EnableFindTreasure = true,
				},
				Warlock = {
					EnableSoulstone = true,
					OnlyEnableSolo = true,
					OnlyEnableOutside = true,
					ExpiryOverride = true,
					EnableGrimoireSacrificeAlert = true,
				},
				Paladin = {
					EnableBlessings = true,
					OnlyRemind = false,
					SelfCastBlessings = false,
				},
				Druid = {
					FormAlert = true,
					OnlyInCombat = true,
				},
			},
		},
	};
	
	self.db = AceDB:New(ADDON_NAME .. "DB", defaults);
	
	if(self.db.global.ConsumablesRemind.EnableInParty) then
		self.db.global.ConsumablesRemind.Mode = LE.RAID_CONSUMABLES.RAIDS_AND_DUNGEONS;
	end
	
	self.db.global.ConsumablesRemind.EnableInParty = nil;
end

function Addon:GetClassOptions()
	local classOptions = {
		["ROGUE"]	= {
			text = "Rogue Options",
			hasArrow = true,
			notCheckable = true,
			menuList = {
				{
					text = "Rogue Options", isTitle = true, notCheckable = true,
				},
				{
					text = "Enable alert for lethal poisons",
					func = function() Addon.db.global.Class.Rogue.EnableLethal = not Addon.db.global.Class.Rogue.EnableLethal; Addon:UpdateBuffs(); end,
					checked = function() return Addon.db.global.Class.Rogue.EnableLethal; end,
					isNotRadio = true,
				},
				{
					text = "Prioritize Wound Poison",
					func = function() Addon.db.global.Class.Rogue.WoundPoisonPriority = not Addon.db.global.Class.Rogue.WoundPoisonPriority; Addon:UpdateBuffs(); end,
					checked = function() return Addon.db.global.Class.Rogue.WoundPoisonPriority; end,
					isNotRadio = true,
				},
				{
					text = " ", isTitle = true, notCheckable = true,
				},
				{
					text = "Enable alert for non-lethal poisons",
					func = function() Addon.db.global.Class.Rogue.EnableNonlethal = not Addon.db.global.Class.Rogue.EnableNonlethal; Addon:UpdateBuffs(); end,
					checked = function() return Addon.db.global.Class.Rogue.EnableNonlethal; end,
					isNotRadio = true,
				},
				{
					text = "Do not alert for Crippling Poison",
					func = function() Addon.db.global.Class.Rogue.SkipCrippling = not Addon.db.global.Class.Rogue.SkipCrippling; Addon:UpdateBuffs(); end,
					checked = function() return Addon.db.global.Class.Rogue.SkipCrippling; end,
					isNotRadio = true,
				},
				{
					text = "Refresh non-lethal poison too when using lethal poison",
					func = function() Addon.db.global.Class.Rogue.RefreshBoth = not Addon.db.global.Class.Rogue.RefreshBoth; Addon:UpdateBuffs(); end,
					checked = function() return Addon.db.global.Class.Rogue.RefreshBoth; end,
					isNotRadio = true,
				},
				{
					text = " ", isTitle = true, notCheckable = true,
				},
				{
					text = "Alert if missing Find Treasure (when Outlaw)",
					func = function() Addon.db.global.Class.Rogue.EnableFindTreasure = not Addon.db.global.Class.Rogue.EnableFindTreasure; Addon:UpdateBuffs(); end,
					checked = function() return Addon.db.global.Class.Rogue.EnableFindTreasure; end,
					isNotRadio = true,
				},
			},
		},
		["WARLOCK"] = {
			text = "Warlock Options",
			hasArrow = true,
			notCheckable = true,
			menuList = {
				{
					text = "Warlock Options", isTitle = true, notCheckable = true,
				},
				{
					text = "Enable alert for Grimoire of Sacrifice",
					func = function() Addon.db.global.Class.Warlock.EnableGrimoireSacrificeAlert = not Addon.db.global.Class.Warlock.EnableGrimoireSacrificeAlert; Addon:UpdateBuffs(); end,
					checked = function() return Addon.db.global.Class.Warlock.EnableGrimoireSacrificeAlert; end,
					isNotRadio = true,
				},
				{
					text = "Enable alert for Soulstone",
					func = function() Addon.db.global.Class.Warlock.EnableSoulstone = not Addon.db.global.Class.Warlock.EnableSoulstone; Addon:UpdateBuffs(); end,
					checked = function() return Addon.db.global.Class.Warlock.EnableSoulstone; end,
					isNotRadio = true,
				},
				{
					text = "Only enable while solo",
					func = function() Addon.db.global.Class.Warlock.OnlyEnableSolo = not Addon.db.global.Class.Warlock.OnlyEnableSolo; Addon:UpdateBuffs(); end,
					checked = function() return Addon.db.global.Class.Warlock.OnlyEnableSolo; end,
					isNotRadio = true,
				},
				{
					text = "Only enable while not in instances",
					func = function() Addon.db.global.Class.Warlock.OnlyEnableOutside = not Addon.db.global.Class.Warlock.OnlyEnableOutside; Addon:UpdateBuffs(); end,
					checked = function() return Addon.db.global.Class.Warlock.OnlyEnableOutside; end,
					isNotRadio = true,
				},
				{
					text = "Reduce expiry alert threshold for Soulstone",
					func = function() Addon.db.global.Class.Warlock.ExpiryOverride = not Addon.db.global.Class.Warlock.ExpiryOverride; Addon:UpdateBuffs(); end,
					checked = function() return Addon.db.global.Class.Warlock.ExpiryOverride; end,
					isNotRadio = true,
				},
			},
		},
		["PALADIN"]	= {
			text = "Paladin Options",
			hasArrow = true,
			notCheckable = true,
			menuList = {
				{
					text = "Paladin Options", isTitle = true, notCheckable = true,
				},
				{
					text = "Remind about Greater Blessings",
					func = function() Addon.db.global.Class.Paladin.EnableBlessings = not Addon.db.global.Class.Paladin.EnableBlessings; Addon:UpdateBuffs(); end,
					checked = function() return Addon.db.global.Class.Paladin.EnableBlessings; end,
					isNotRadio = true,
				},
				{
					text = "Only self cast Blessings even while in group",
					func = function() Addon.db.global.Class.Paladin.SelfCastBlessings = not Addon.db.global.Class.Paladin.SelfCastBlessings; Addon:UpdateBuffs(); end,
					checked = function() return Addon.db.global.Class.Paladin.SelfCastBlessings; end,
					isNotRadio = true,
				},
				{
					text = "Don't suggest buff spell or targets (only remind)",
					func = function() Addon.db.global.Class.Paladin.OnlyRemind = not Addon.db.global.Class.Paladin.OnlyRemind; Addon:UpdateBuffs(); end,
					checked = function() return Addon.db.global.Class.Paladin.OnlyRemind; end,
					isNotRadio = true,
				},
			},
		},
		["MAGE"]	= {
			text = "Mage Options",
			hasArrow = true,
			notCheckable = true,
			menuList = {
				{
					text = "Mage Options", isTitle = true, notCheckable = true,
				},
				{
					text = "Remind about Arcane Familiar",
					func = function() Addon.db.global.Class.Mage.EnableArcaneFamiliar = not Addon.db.global.Class.Mage.EnableArcaneFamiliar; Addon:UpdateBuffs(); end,
					checked = function() return Addon.db.global.Class.Mage.EnableArcaneFamiliar; end,
					isNotRadio = true,
				},
			},
		},
		["DRUID"]	= {
			text = "Druid Options",
			hasArrow = true,
			notCheckable = true,
			menuList = {
				{
					text = "Druid Options", isTitle = true, notCheckable = true,
				},
				{
					text = "Alert if not in a form",
					func = function() Addon.db.global.Class.Druid.FormAlert = not Addon.db.global.Class.Druid.FormAlert; Addon:UpdateBuffs(); end,
					checked = function() return Addon.db.global.Class.Druid.FormAlert; end,
					isNotRadio = true,
				},
				{
					text = "Only alert in combat",
					func = function() Addon.db.global.Class.Druid.OnlyInCombat = not Addon.db.global.Class.Druid.OnlyInCombat; Addon:UpdateBuffs(); end,
					checked = function() return Addon.db.global.Class.Druid.OnlyInCombat; end,
					isNotRadio = true,
				},
			},
		},
	};
	
	return classOptions;
end

StaticPopupDialogs["BUFFY_CUSTOM_EXPIRE_TIME"] = {
	text = "Enter a custom expiration alert threshold in seconds (e.g. 1800 is half an hour):",
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = 1,
	maxLetters = 4,
	OnAccept = function(self)
		local timeValue = tonumber(self.editBox:GetText());
		if(timeValue ~= nil) then
			Addon.db.global.ExpirationAlertThreshold = timeValue;
			Addon:UpdateBuffs();
		end
	end,
	EditBoxOnEnterPressed = function(self)
		local parent = self:GetParent();
		local timeValue = tonumber(parent.editBox:GetText());
		if(timeValue ~= nil) then
			Addon.db.global.ExpirationAlertThreshold = timeValue;
			Addon:UpdateBuffs();
		end
		parent:Hide();
	end,
	OnShow = function(self)
		self.editBox:SetFocus();
	end,
	OnHide = function(self)
		ChatEdit_FocusActiveWindow();
		self.editBox:SetText("");
	end,
	timeout = 0,
	exclusive = 0,
	hideOnEscape = 1
};

local LOCALIZED_CONSUMABLE   = GetItemClassInfo(0);
local LOCALIZED_FOODANDDRINK = GetItemSubClassInfo(0, 5);

local function SetCustomFood(specIndex, foodItem)
	if(not specIndex) then return end
	if(not foodItem) then return end
	
	local name, link, _, _, _, class, subclass = GetItemInfo(foodItem);
	if(name) then
		if(class == LOCALIZED_CONSUMABLE and subclass == LOCALIZED_FOODANDDRINK) then
			local itemID = Addon:GetItemID(link);
			Addon.db.char.FoodPriority[specIndex] = LE.STAT.CUSTOM;
			Addon.db.char.CustomFoods[specIndex] = itemID;
			
			local id, name, _, icon = GetSpecializationInfo(specIndex, false, false, false, UnitSex("player"));
			local specName = string.format("|T%s:14:14:0:0|t %s", icon, name);
			
			Addon:UpdateBuffs();

			Addon:AddMessage("%s set as custom food for %s.", link, specName);
		else
			Addon:AddMessage("Item %s is not a valid consumable food.", link);
		end
	else	
		Addon:AddMessage("Unable to find food item %s. Allowed values are item name and id.", tostring(foodItem));
	end
end

StaticPopupDialogs["BUFFY_SET_CUSTOM_FOOD"] = {
	text = "Enter custom food name or item ID for %s:",
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = 1,
	OnAccept = function(self, data)
		local foodItem = self.editBox:GetText();
		SetCustomFood(data.specIndex, foodItem);
	end,
	EditBoxOnEnterPressed = function(self, data)
		local parent = self:GetParent();
		local foodItem = parent.editBox:GetText();
		SetCustomFood(data.specIndex, foodItem);
		parent:Hide();
	end,
	OnShow = function(self, data)
		self.editBox:SetFocus();
		if(Addon.db.char.CustomFoods[data.specIndex]) then
			local name = GetItemInfo(Addon.db.char.CustomFoods[data.specIndex]);
			self.editBox:SetText(name);
		end
	end,
	OnHide = function(self, data)
		ChatEdit_FocusActiveWindow();
		self.editBox:SetText("");
	end,
	timeout = 0,
	exclusive = 0,
	hideOnEscape = 1
};

function Addon:IsSomeDefaultExpirationTime(t)
	return t == 0 or t == 60 or t == 120 or t == 300 or t == 600 or t == 900; 
end

local function tmerge(table, other)
	for _, item in ipairs(other) do
		tinsert(table, item);
	end
	
	return table;
end

function Addon:GetCustomFoodStatPriorityMenu()
	local menu = {};
	
	local activeSpec = GetSpecialization();
	local numSpecs = GetNumSpecializations();
	
	local currentBestFood = Addon:GetFoodPreference(true)[1];
	local bestFoodName = LE.RATING_NAMES[currentBestFood];
	
	for specIndex = 1, numSpecs do
		tinsert(menu, {
			text = " ", isTitle = true, notCheckable = true,
		});
		
		local id, name, _, icon = GetSpecializationInfo(specIndex, false, false, false, UnitSex("player"));
		
		if(specIndex == activeSpec) then
			tinsert(menu, {
				text = string.format("Food for %s |cff00ff00(%s)|r", name, "Active Spec"),
				isTitle = true, notCheckable = true,
				icon = icon,
			});
		else
			tinsert(menu, {
				text = string.format("Food for %s", name),
				isTitle = true, notCheckable = true,
				icon = icon,
			});
		end
		
		local customFoodText = "";
		if(self.db.char.FoodPriority[specIndex] == LE.STAT.CUSTOM and self.db.char.CustomFoods[specIndex]) then
			local _, customFood = GetItemInfo(self.db.char.CustomFoods[specIndex]);
			customFoodText = string.format(" (|cffffbb00currently %s|r)", customFood);
		end
		
		tmerge(menu, {
			{
				text = string.format("Attempt to guess (|cffffbb00%s|r)", bestFoodName),
				func = function()
					self.db.char.FoodPriority[specIndex] = LE.STAT.AUTOMATIC;
					self.db.char.CustomFoods[specIndex] = nil;
					Addon:UpdateBuffs();
				end,
				checked = function() return self.db.char.FoodPriority[specIndex] == LE.STAT.AUTOMATIC; end,
			},
			{
				text = LE.RATING_NAMES[LE.STAT.HASTE],
				func = function()
					self.db.char.FoodPriority[specIndex] = LE.STAT.HASTE;
					self.db.char.CustomFoods[specIndex] = nil;
					Addon:UpdateBuffs();
				end,
				checked = function() return self.db.char.FoodPriority[specIndex] == LE.STAT.HASTE; end,
			},
			{
				text = LE.RATING_NAMES[LE.STAT.MASTERY],
				func = function()
					self.db.char.FoodPriority[specIndex] = LE.STAT.MASTERY;
					self.db.char.CustomFoods[specIndex] = nil;
					Addon:UpdateBuffs();
				end,
				checked = function() return self.db.char.FoodPriority[specIndex] == LE.STAT.MASTERY; end,
			},
			{
				text = LE.RATING_NAMES[LE.STAT.CRIT],
				func = function()
					self.db.char.FoodPriority[specIndex] = LE.STAT.CRIT;
					self.db.char.CustomFoods[specIndex] = nil;
					Addon:UpdateBuffs();
				end,
				checked = function() return self.db.char.FoodPriority[specIndex] == LE.STAT.CRIT; end,
			},
			{
				text = LE.RATING_NAMES[LE.STAT.VERSATILITY],
				func = function()
					self.db.char.FoodPriority[specIndex] = LE.STAT.VERSATILITY;
					self.db.char.CustomFoods[specIndex] = nil;
					Addon:UpdateBuffs();
				end,
				checked = function() return self.db.char.FoodPriority[specIndex] == LE.STAT.VERSATILITY; end,
			},
			{
				text = "Special food (Felmouth Frenzy/Pepper Breath)",
				func = function()
					self.db.char.FoodPriority[specIndex] = LE.STAT.SPECIAL;
					self.db.char.CustomFoods[specIndex] = nil;
					Addon:UpdateBuffs();
				end,
				checked = function() return self.db.char.FoodPriority[specIndex] == LE.STAT.SPECIAL; end,
			},
			{
				text = "Custom food" .. customFoodText,
				func = function()
					local specName = string.format("|T%s:14:14:0:0|t %s", icon, name);
					StaticPopup_Show("BUFFY_SET_CUSTOM_FOOD", specName, nil, {
						specIndex = specIndex
					});
				end,
				checked = function()
					return self.db.char.FoodPriority[specIndex] == LE.STAT.CUSTOM and self.db.char.CustomFoods[specIndex];
				end,
			},
		});
		
		if(role == "TANK" and UnitLevel("player") < 110) then
			tinsert(menu, {
				text = LE.RATING_NAMES[LE.STAT.STAMINA],
				func = function() self.db.char.FoodPriority[specIndex] = LE.STAT.STAMINA; Addon:UpdateBuffs(); end,
				checked = function() return self.db.char.FoodPriority[specIndex] == LE.STAT.STAMINA; end,
			});
		end
	end
	
	return menu;
end

function Addon:GetDatabrokerMenuData()
	local legibleClass, class = UnitClass("player");
	
	local locktext = "Unlock";
	
	if(not Addon.IsFrameLocked) then
		locktext = "Lock";
	end
	
	local keybind, keybindingText = Addon:GetBinding();
	if(keybind) then
		keybindingText = string.format("Change the keybinding (|cfff5ce47Current %s|r)", keybind);
	else
		keybindingText = "Set a keybind (|cfff15050No binding!|r)";
	end
	
	local expirationAlertTimeText = "Disabled";
	if(self.db.global.ExpirationAlertThreshold > 0) then
		expirationAlertTimeText = Addon:FormatTime(self.db.global.ExpirationAlertThreshold, true);
	end
	
	local customTimeText = "Custom";
	if(not Addon:IsSomeDefaultExpirationTime(self.db.global.ExpirationAlertThreshold)) then
		customTimeText = string.format("Custom: %s", Addon:FormatTime(self.db.global.ExpirationAlertThreshold, true));
	end
	
	local customFoodStatPriority = Addon:GetCustomFoodStatPriorityMenu();
	
	local data = {
		{
			text = "Buffy Options", isTitle = true, notCheckable = true,
		},
		{
			text = "Buffy notifications enabled",
			func = function() self.db.global.Enabled = not self.db.global.Enabled; Addon:UpdateBuffs(); end,
			checked = function() return self.db.global.Enabled; end,
			isNotRadio = true,
		},
		{
			text = string.format("%s Buffy frame", locktext),
			func = function() self.IsFrameLocked = not self.IsFrameLocked; Addon:UpdateBuffs(); end,
			notCheckable = true,
		},
		{
			text = " ", isTitle = true, notCheckable = true,
		},
		{
			text = keybindingText,
			func = function() BuffyKeybindingFrameOuter:Show(); end,
			notCheckable = true,
		},
		{
			text = " ", isTitle = true, notCheckable = true,
		},
		{
			text = "Show notifications in combat",
			func = function() self.db.global.ShowInCombat = not self.db.global.ShowInCombat; Addon:UpdateBuffs(); end,
			checked = function() return self.db.global.ShowInCombat; end,
			isNotRadio = true,
		},
		{
			text = "More toggle options",
			notCheckable = true,
			hasArrow = true,
			menuList = {
				{
					text = "Notifications", isTitle = true, notCheckable = true,
				},
				{
					text = "Disable while resting",
					func = function() self.db.global.DisableWhenResting = not self.db.global.DisableWhenResting; Addon:UpdateBuffs(); end,
					checked = function() return self.db.global.DisableWhenResting; end,
					isNotRadio = true,
				},
				{
					text = "Disable while not in an instance",
					func = function() self.db.global.DisableOutside = not self.db.global.DisableOutside; Addon:UpdateBuffs(); end,
					checked = function() return self.db.global.DisableOutside; end,
					isNotRadio = true,
				},
				{
					text = "Show while flying or in a vehicle",
					func = function() self.db.global.ShowWhileMounted = not self.db.global.ShowWhileMounted; Addon:UpdateBuffs(); end,
					checked = function() return self.db.global.ShowWhileMounted; end,
					isNotRadio = true,
				},
				{
					text = " ", isTitle = true, notCheckable = true,
				},
				{
					text = "Fade alert when moving",
					func = function() self.db.global.AlertMoveFade = not self.db.global.AlertMoveFade; end,
					checked = function() return self.db.global.AlertMoveFade; end,
					isNotRadio = true,
				},
				{
					text = "Unbind the temporary keybind when moving",
					func = function() self.db.global.UnbindWhenMoving = not self.db.global.UnbindWhenMoving; end,
					checked = function() return self.db.global.UnbindWhenMoving; end,
					isNotRadio = true,
				},
				{
					text = " ", isTitle = true, notCheckable = true,
				},
				{
					text = "Remind to use Trans-Dimensional Bird Whistle",
					func = function() self.db.global.PepeReminderEnabled = not self.db.global.PepeReminderEnabled; Addon:UpdateBuffs(); end,
					checked = function() return self.db.global.PepeReminderEnabled; end,
					isNotRadio = true,
				},
			},
		},
		{
			text = " ", isTitle = true, notCheckable = true,
		},
		{
			text = "Additional Alert Types", isTitle = true, notCheckable = true,
		},
		{
			text = "Remind about raid consumables",
			func = function() self.db.global.ConsumablesRemind.Enabled = not self.db.global.ConsumablesRemind.Enabled; Addon:UpdateBuffs(); end,
			checked = function() return self.db.global.ConsumablesRemind.Enabled; end,
			isNotRadio = true,
			hasArrow = true,
			menuList = {
				{
					text = "Consumables Remind", isTitle = true, notCheckable = true,
				},
				{
					text = "Enable in current raids",
					func = function() self.db.global.ConsumablesRemind.Mode = LE.RAID_CONSUMABLES.RAIDS_ONLY; Addon:UpdateBuffs(); CloseMenus(); end,
					checked = function() return self.db.global.ConsumablesRemind.Mode == LE.RAID_CONSUMABLES.RAIDS_ONLY; end,
					tooltipTitle = "Enable in current raids",
					tooltipText = "Consumable alerts will be enabled in current content according to your level.|n|nNote: only Legion and Draenor consumables are supported.",
					tooltipOnButton = 1,
				},
				{
					text = "Enable in current raids and dungeons",
					func = function() self.db.global.ConsumablesRemind.Mode = LE.RAID_CONSUMABLES.RAIDS_AND_DUNGEONS; Addon:UpdateBuffs(); CloseMenus(); end,
					checked = function() return self.db.global.ConsumablesRemind.Mode == LE.RAID_CONSUMABLES.RAIDS_AND_DUNGEONS; end,
					tooltipTitle = "Enable in current raids and dungeons",
					tooltipText = "Consumable alerts will be enabled in current content according to your level.|n|nNote: only Legion and Draenor consumables are supported.",
					tooltipOnButton = 1,
				},
				{
					text = "Enable everywhere while not resting",
					func = function() self.db.global.ConsumablesRemind.Mode = LE.RAID_CONSUMABLES.EVERYWHERE_NOT_RESTING; Addon:UpdateBuffs(); CloseMenus(); end,
					checked = function() return self.db.global.ConsumablesRemind.Mode == LE.RAID_CONSUMABLES.EVERYWHERE_NOT_RESTING; end,
				},
				{
					text = "Enable everywhere",
					func = function() self.db.global.ConsumablesRemind.Mode = LE.RAID_CONSUMABLES.EVERYWHERE; Addon:UpdateBuffs(); CloseMenus(); end,
					checked = function() return self.db.global.ConsumablesRemind.Mode == LE.RAID_CONSUMABLES.EVERYWHERE; end,
				},
				{
					text = " ", isTitle = true, notCheckable = true,
				},
				{
					text = "Consumable Types", isTitle = true, notCheckable = true,
				},
				{
					text = "Enable for flasks",
					func = function() self.db.global.ConsumablesRemind.Flasks = not self.db.global.ConsumablesRemind.Flasks; Addon:UpdateBuffs(); CloseMenus(); end,
					checked = function() return self.db.global.ConsumablesRemind.Flasks; end,
					isNotRadio = true,
					hasArrow = true,
					menuList = {
						{
							text = "Only alert for non-consumable outside instances",
							func = function() self.db.global.ConsumablesRemind.OnlyInfiniteFlask = not self.db.global.ConsumablesRemind.OnlyInfiniteFlask; Addon:UpdateBuffs(); CloseMenus(); end,
							checked = function() return self.db.global.ConsumablesRemind.OnlyInfiniteFlask; end,
							isNotRadio = true,
						},
					},
				},
				{
					text = "Enable for augment runes",
					func = function() self.db.global.ConsumablesRemind.Runes = not self.db.global.ConsumablesRemind.Runes; Addon:UpdateBuffs(); CloseMenus(); end,
					checked = function() return self.db.global.ConsumablesRemind.Runes; end,
					isNotRadio = true,
					hasArrow = true,
					menuList = {
						{
							text = "Only alert for the non-consumable rune",
							func = function() self.db.global.ConsumablesRemind.OnlyInfiniteRune = not self.db.global.ConsumablesRemind.OnlyInfiniteRune; Addon:UpdateBuffs(); CloseMenus(); end,
							checked = function() return UnitLevel("player") < 110 and self.db.global.ConsumablesRemind.OnlyInfiniteRune; end,
							isNotRadio = true,
							disabled = UnitLevel("player") > 109,
						},
					},
				},
				{
					text = "Enable for food",
					func = function() self.db.global.ConsumablesRemind.Food = not self.db.global.ConsumablesRemind.Food; Addon:UpdateBuffs(); CloseMenus(); end,
					checked = function() return self.db.global.ConsumablesRemind.Food; end,
					isNotRadio = true,
					hasArrow = true,
					menuList = tmerge({
						{
							text = "Prioritize own food over feasts",
							func = function() self.db.global.ConsumablesRemind.FeastsMode = LE.FEASTS_MODE.OWN_FOOD; Addon:UpdateBuffs(); CloseMenus(); end,
							checked = function() return self.db.global.ConsumablesRemind.FeastsMode == LE.FEASTS_MODE.OWN_FOOD; end,
						},
						{
							text = "Prioritize feasts over own food",
							func = function() self.db.global.ConsumablesRemind.FeastsMode = LE.FEASTS_MODE.PRIORITY_FEASTS; Addon:UpdateBuffs(); CloseMenus(); end,
							checked = function() return self.db.global.ConsumablesRemind.FeastsMode == LE.FEASTS_MODE.PRIORITY_FEASTS; end,
						},
						{
							text = "Only alert for feasts",
							func = function() self.db.global.ConsumablesRemind.FeastsMode = LE.FEASTS_MODE.ONLY_FEASTS; Addon:UpdateBuffs(); CloseMenus(); end,
							checked = function() return self.db.global.ConsumablesRemind.FeastsMode == LE.FEASTS_MODE.ONLY_FEASTS; end,
						},
					}, customFoodStatPriority),
				},
				{
					text = " ", isTitle = true, notCheckable = true,
				},
				{
					text = "Player Status", isTitle = true, notCheckable = true,
				},
				{
					text = "Disable in Raid Finder difficulty",
					func = function() self.db.global.ConsumablesRemind.DisableInLFR = not self.db.global.ConsumablesRemind.DisableInLFR; Addon:UpdateBuffs(); CloseMenus(); end,
					checked = function() return self.db.global.ConsumablesRemind.DisableInLFR; end,
					isNotRadio = true,
				},
				{
					text = "Disable if not in party or raid group",
					func = function() self.db.global.ConsumablesRemind.DisableOutsideGroup = not self.db.global.ConsumablesRemind.DisableOutsideGroup; Addon:UpdateBuffs(); CloseMenus(); end,
					checked = function() return self.db.global.ConsumablesRemind.DisableOutsideGroup; end,
					isNotRadio = true,
				},
				{
					text = "Do not alert while in combat",
					func = function() self.db.global.ConsumablesRemind.NotInCombat = not self.db.global.ConsumablesRemind.NotInCombat; Addon:UpdateBuffs(); CloseMenus(); end,
					checked = function() return self.db.global.ConsumablesRemind.NotInCombat; end,
					isNotRadio = true,
				},
				{
					text = " ", isTitle = true, notCheckable = true,
				},
				{
					text = "Other Options", isTitle = true, notCheckable = true,
				},
				{
					text = "Prioritize main stat over stamina",
					func = function() self.db.global.ConsumablesRemind.SkipStamina = not self.db.global.ConsumablesRemind.SkipStamina; Addon:UpdateBuffs(); CloseMenus(); end,
					checked = function() return self.db.global.ConsumablesRemind.SkipStamina; end,
					isNotRadio = true,
				},
				{
					text = "Show timer until Well Fed when eating",
					func = function() self.db.global.ConsumablesRemind.EatingTimer = not self.db.global.ConsumablesRemind.EatingTimer; CloseMenus(); end,
					checked = function() return self.db.global.ConsumablesRemind.EatingTimer; end,
					isNotRadio = true,
				},
				{
					text = "Also enable keybind for consumables",
					func = function() self.db.global.ConsumablesRemind.KeybindEnabled = not self.db.global.ConsumablesRemind.KeybindEnabled; Addon:ClearTempBind(); Addon:UpdateBuffs(); CloseMenus(); end,
					checked = function() return self.db.global.ConsumablesRemind.KeybindEnabled; end,
					isNotRadio = true,
				},
				{
					text = "Allow outdated consumables",
					func = function() self.db.global.ConsumablesRemind.OutdatedConsumables = not self.db.global.ConsumablesRemind.OutdatedConsumables; Addon:UpdateBuffs(); CloseMenus(); end,
					checked = function() return self.db.global.ConsumablesRemind.OutdatedConsumables; end,
					isNotRadio = true,
				},
			},
		},
		{
			text = string.format("Near expiration alert (%s)", expirationAlertTimeText),
			menuList = {
				{
					text = "Near Expiration Alert Options", isTitle = true, notCheckable = true,
				},
				{
					text = "Do not alert while in combat",
					func = function() self.db.global.NoExpirationAlertInCombat = not self.db.global.NoExpirationAlertInCombat; Addon:UpdateBuffs(); CloseMenus(); end,
					checked = function() return self.db.global.NoExpirationAlertInCombat; end,
					isNotRadio = true,
				},
				{
					text = " ", isTitle = true, notCheckable = true,
				},
				{
					text = "Select Threshold for Time Remaining", isTitle = true, notCheckable = true,
				},
				{
					text = "Disabled",
					func = function() self.db.global.ExpirationAlertThreshold = 0; Addon:UpdateBuffs(); CloseMenus(); end,
					checked = function() return self.db.global.ExpirationAlertThreshold == 0; end,
				},
				{
					text = "1 minute",
					func = function() self.db.global.ExpirationAlertThreshold = 60; Addon:UpdateBuffs(); CloseMenus(); end,
					checked = function() return self.db.global.ExpirationAlertThreshold == 60; end,
				},
				{
					text = "2 minutes",
					func = function() self.db.global.ExpirationAlertThreshold = 120; Addon:UpdateBuffs(); CloseMenus(); end,
					checked = function() return self.db.global.ExpirationAlertThreshold == 120; end,
				},
				{
					text = "5 minutes",
					func = function() self.db.global.ExpirationAlertThreshold = 300; Addon:UpdateBuffs(); CloseMenus(); end,
					checked = function() return self.db.global.ExpirationAlertThreshold == 300; end,
				},
				{
					text = "10 minutes",
					func = function() self.db.global.ExpirationAlertThreshold = 600; Addon:UpdateBuffs(); CloseMenus(); end,
					checked = function() return self.db.global.ExpirationAlertThreshold == 600; end,
				},
				{
					text = "15 minutes",
					func = function() self.db.global.ExpirationAlertThreshold = 900; Addon:UpdateBuffs(); CloseMenus(); end,
					checked = function() return self.db.global.ExpirationAlertThreshold == 900; end,
				},
				{
					text = customTimeText,
					func = function() StaticPopup_Show("BUFFY_CUSTOM_EXPIRE_TIME"); CloseMenus(); end,
					checked = function()
						return not Addon:IsSomeDefaultExpirationTime(self.db.global.ExpirationAlertThreshold);
					end,
				},
			},
			hasArrow = true,
			notCheckable = true,
		},
		{
			text = " ", isTitle = true, notCheckable = true,
		},
		{
			text = "Other Options", isTitle = true, notCheckable = true,
		},
		{
			text = "Display tooltip on icon hover",
			func = function() self.db.global.ShowTooltips = not self.db.global.ShowTooltips; end,
			checked = function() return self.db.global.ShowTooltips; end,
			isNotRadio = true,
		},
	};
	
	local className = Addon:GetClassNameString(class, legibleClass);
	
	local classOptions = Addon:GetClassOptions();
	if(classOptions[class] ~= nil) then
		tinsert(data, 9, {
			text = string.format("%s options", className),
			notCheckable = true,
			hasArrow = true,
			menuList = classOptions[class].menuList,
		});
	else
		tinsert(data, 9, {
			text = string.format("No options for %s", className),
			notCheckable = true,
			disabled = true,
		});
	end
	
	if(not Addon.db.global.Position.DefaultPosition) then
		tinsert(data, 4, {
			text = "Reset position",
			func = function() Addon:ResetPosition(); end,
			notCheckable = true,
		});
	end
	
	tinsert(data, {
		text = " ", isTitle = true, notCheckable = true,
	});
	
	tinsert(data, {
		text = "Close menu",
		func = function() CloseMenus() end,
		notCheckable = true,
	});
	
	return data;
end

function Addon:GetClassNameString(class, legibleClass)
	if(not class or not legibleClass) then return end
	
	local classColor = Addon:GetClassColor(class).colorStr;
	
	local left, right, top, bottom = unpack(CLASS_ICON_TCOORDS[class]);
	left = left * 256 + 4;
	right = right * 256 - 4;
	top = top * 256 + 4;
	bottom = bottom * 256 - 4;
	
	local icon = string.format("|TInterface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes:14:14:0:0:256:256:%d:%d:%d:%d|t", left, right, top, bottom);
	
	return string.format("%s |c%s%s|r", icon, classColor, legibleClass);
end

function Addon:OpenContextMenu(parentframe)
	if(not Addon.ContextMenu) then
		Addon.ContextMenu = CreateFrame("Frame", ADDON_NAME .. "ContextMenuFrame", parentframe, "UIDropDownMenuTemplate");
	end
	
	Addon.ContextMenu:SetPoint("BOTTOM", parentframe, "CENTER", 0, 5);
	EasyMenu(Addon:GetDatabrokerMenuData(), Addon.ContextMenu, "cursor", 0, 0, "MENU", 5);
	
	local mouseX, mouseY = GetCursorPosition();
	local scale = UIParent:GetEffectiveScale();
	
	local point, yoffset = "BOTTOM", 10;
	if(mouseY / scale >= GetScreenHeight() / 2) then
		point = "TOP";
		yoffset = -10;
	end
	
	if(parentframe == BuffyFrame) then
		DropDownList1:ClearAllPoints();
		DropDownList1:SetPoint(point .. "LEFT", parentframe, "LEFT", -5, yoffset * 2.8);
	elseif(parentframe ~= UIParent) then
		DropDownList1:ClearAllPoints();
		DropDownList1:SetPoint(point, parentframe, "CENTER", 0, yoffset);
	end
end

function Addon:UpdateDatabrokerText()
	Addon.databroker.text = "Buffy";
end

function Addon:GetClassColor(class)
	return (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[class or 'PRIEST'];
end

function Addon:AddChatMessage(msg, ...)
	DEFAULT_CHAT_FRAME:AddMessage(
		string.format("|cff20cff4Buffy|r %s", string.format(msg or "", ...))
	);
end

function Addon:SendAnnounceMessage(channel, msg)
	if(channel == "SELF") then
		Addon:AddChatMessage(msg);
	elseif(channel == "RAID" or channel == "PARTY" or channel == "SAY") then
		SendChatMessage(Addon:StripColor(msg), channel);
	end
end

function Addon:StripColor(text)
	return string.gsub(string.gsub(text, "\124c%w%w%w%w%w%w%w%w", ""), "\124r", "");
end

function Addon:GetPlayerRaidRosterRank()
	if(not IsInRaid()) then return 0 end
	local numGroupMembers = GetNumGroupMembers();
	for index = 1, numGroupMembers do
		local name, rosterRank = GetRaidRosterInfo(index);
		if(name == UnitName("player")) then
			return rosterRank;
		end
	end
	
	return 0;
end

function Addon:InitializeDatabroker()
	Addon.databroker = LibDataBroker:NewDataObject(ADDON_NAME, {
		type = "data source",
		label = "Buffy",
		text = "Buffy",
		icon = BUFFY_ICON,
		OnClick = function(frame, button)
			if(button == "LeftButton") then
				if(IsShiftKeyDown()) then
					Addon:AnnounceBuffStatus(IsControlKeyDown(), IsAltKeyDown() and "self" or nil);
				end
			elseif(button == "RightButton") then
				GameTooltip:Hide();
				Addon:OpenContextMenu(frame);
			end
		end,
		OnTooltipShow = function(tooltip)
			if not tooltip or not tooltip.AddLine then return end
			
			tooltip:AddLine(TEX_BUFFY_ICON .. " Buffy");
			
			if(not self.db.global.Enabled) then
				tooltip:AddLine("|cffe05754Notifications Currently Disabled|r");
				tooltip:AddLine(" ");
			end
			
			tooltip:AddLine("Right-Click |cffffffff\124 Show options|r");
			
			-- Addon.tooltip_open = true;
		end,
		OnLeave = function(frame)
		end,
	});

	Addon:UpdateDatabrokerText();
end
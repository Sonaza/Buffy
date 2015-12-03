------------------------------------------------------------
-- Buffy by Sonaza
------------------------------------------------------------

local ADDON_NAME, SHARED_DATA = ...;

local LibStub = LibStub;
local A, E = unpack(SHARED_DATA);

local _;

local LDB = LibStub:GetLibrary("LibDataBroker-1.1");
local AceDB = LibStub("AceDB-3.0")

local ICON_PATTERN_14 = "|T%s:14:14:0:0|t";
local BUFFY_ICON = "Interface\\Icons\\spell_arcane_invocation";

local TEX_BUFFY_ICON = ICON_PATTERN_14:format(BUFFY_ICON);

E.FEASTS_MODE = {
	OWN_FOOD 		= 0x1,
	PRIORITY_FEASTS	= 0x2,
	ONLY_FEASTS		= 0x3,
}

E.RAID_CONSUMABLES = {
	RAIDS_ONLY 			= 1,
	RAIDS_AND_DUNGEONS	= 2,
	EVERYWHERE 			= 3,
};

function A:SlashHandler(message)
	local action, param1, param2 = strsplit(" ", strtrim(strlower(message or "")));
	
	if(not action or action == "") then
		A:OpenContextMenu(UIParent);
	elseif(action == "toggle") then
		self.db.global.Enabled = not self.db.global.Enabled;
		A:UpdateBuffs();
	elseif(action == "lock") then
		self.IsFrameLocked = true;
		A:UpdateBuffs();
	elseif(action == "unlock") then
		self.IsFrameLocked = false;
		A:UpdateBuffs();
	elseif(action == "announce") then
		local extended, channel = false, nil;
		
		if(param1 == "players") then
			extended = true;
			channel = param2;
		else
			channel = param1;
		end
		
		A:AnnounceBuffStatus(extended, channel);
	elseif(action == "help" or action == "halp" or action == "?") then
		A:AddChatMessage("Chat Command Usage");
		A:AddChatMessage("Available by typing /bf or /buffy");
		A:AddChatMessage("|cffffdc3b/buffy|r \124 Opens Options Menu Dialog");
		A:AddChatMessage("|cffffdc3b/buffy|r toggle \124 Toggles Buffy Notifications");
		A:AddChatMessage("|cffffdc3b/buffy|r lock and |cffffdc3b/buffy|r unlock \124 Lock/Unlock Frame");
		A:AddChatMessage("|cffffdc3b/buffy|r announce |cffbbbbbb[self/party/raid]|r \124 Announce Raid Buff Status, [self/party/raid] Optional Announcement Channel");
		A:AddChatMessage("|cffffdc3b/buffy|r announce players |cffbbbbbb[self/party/raid]|r \124 Announce Players Missing Buffs, [self/party/raid] Optional Announcement Channel");
	end
end

function A:InitializeDatabase()
	local defaults = {
		char = {
			FoodPriority = {
				[1] = E.STAT.AUTOMATIC,
				[2] = E.STAT.AUTOMATIC,
			},
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
				
				Mode = E.RAID_CONSUMABLES.RAIDS_ONLY,
				-- EnableInParty = nil,
				
				Flasks = true,
				Runes = false,
				Food = true,
				
				OnlyInfiniteFlask = false,
				OnlyInfiniteRune = false,
				
				FeastsMode = E.FEASTS_MODE.OWN_FOOD,
				EatingTimer = true,
				
				DisableInLFR = false,
				DisableOutsideGroup = false,
				
				SkipStamina = true,
				KeybindEnabled = false,
				NotInCombat = true,
			},
			
			Announcements = {
				Enabled = false,
				PerPlayer = false,
				OnlyToSelf = false,
				OnlyIfLeaderOrAssist = true,
			},
			
			Class = {
				Rogue = {
					EnableLethal = true,
					EnableNonlethal = true,
					SkipCrippling = false,
					WoundPoisonPriority = false,
					RefreshBoth = false,
				},
				Warlock = {
					EnableSoulstone = true,
					OnlyEnableSolo = true,
					OnlyEnableOutside = true,
					ExpiryOverride = true,
					EnableGrimoireSacrificeAlert = true,
				},
				Shaman = {
					RemindShield = true,
				},
				Hunter = {
					EnableLoneWolf = true,
					CancelPackAlert = true,
				},
				Priest = {
					RemindShadowform = true,
				},
				Paladin = {
					RemindRighteousFury = true,
				},
				DeathKnight = {
					PresenceAlert = true,
					OnlyInCombat = true,
					Presences = {
						[1] = 1,
						[2] = 2,
						[3] = 3,
					},
				},
				Druid = {
					FormAlert = true,
					OnlyInCombat = true,
				},
				Warrior = {
					StanceAlert = true,
					OnlyInCombat = false,
					ProtectionStance = 1,
				},
			},
		},
	};
	
	self.db = AceDB:New(ADDON_NAME .. "DB", defaults);
	
	if(self.db.global.ConsumablesRemind.EnableInParty) then
		self.db.global.ConsumablesRemind.Mode = E.RAID_CONSUMABLES.RAIDS_AND_DUNGEONS;
	end
	
	self.db.global.ConsumablesRemind.EnableInParty = nil;
end

function A:GetClassOptions()
	local classOptions = {
		["WARRIOR"]	= {
			text = "Warrior Options",
			hasArrow = true,
			notCheckable = true,
			menuList = {
				{
					text = "Warrior Options", isTitle = true, notCheckable = true,
				},
				{
					text = "Alert if in a wrong stance",
					func = function() A.db.global.Class.Warrior.StanceAlert = not A.db.global.Class.Warrior.StanceAlert; A:UpdateBuffs(); end,
					checked = function() return A.db.global.Class.Warrior.StanceAlert; end,
					isNotRadio = true,
				},
				{
					text = "Only alert in combat",
					func = function() A.db.global.Class.Warrior.OnlyInCombat = not A.db.global.Class.Warrior.OnlyInCombat; A:UpdateBuffs(); end,
					checked = function() return A.db.global.Class.Warrior.OnlyInCombat; end,
					isNotRadio = true,
				},
				{
					text = " ", isTitle = true, notCheckable = true,
				},
				{
					text = "If Using Gladiator's Resolve", isTitle = true, notCheckable = true,
				},
				{
					text = "Use Defensive Stance",
					func = function() A.db.global.Class.Warrior.ProtectionStance = 1; A:UpdateBuffs(); end,
					checked = function() return A.db.global.Class.Warrior.ProtectionStance == 1; end,
				},
				{
					text = "Use Gladiator Stance",
					func = function() A.db.global.Class.Warrior.ProtectionStance = 2; A:UpdateBuffs(); end,
					checked = function() return A.db.global.Class.Warrior.ProtectionStance == 2; end,
				},
			},
		},
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
					func = function() A.db.global.Class.Rogue.EnableLethal = not A.db.global.Class.Rogue.EnableLethal; A:UpdateBuffs(); end,
					checked = function() return A.db.global.Class.Rogue.EnableLethal; end,
					isNotRadio = true,
				},
				{
					text = "Prioritize Wound Poison",
					func = function() A.db.global.Class.Rogue.WoundPoisonPriority = not A.db.global.Class.Rogue.WoundPoisonPriority; A:UpdateBuffs(); end,
					checked = function() return A.db.global.Class.Rogue.WoundPoisonPriority; end,
					isNotRadio = true,
				},
				{
					text = " ", isTitle = true, notCheckable = true,
				},
				{
					text = "Enable alert for non-lethal poisons",
					func = function() A.db.global.Class.Rogue.EnableNonlethal = not A.db.global.Class.Rogue.EnableNonlethal; A:UpdateBuffs(); end,
					checked = function() return A.db.global.Class.Rogue.EnableNonlethal; end,
					isNotRadio = true,
				},
				{
					text = "Do not alert for Crippling Poison",
					func = function() A.db.global.Class.Rogue.SkipCrippling = not A.db.global.Class.Rogue.SkipCrippling; A:UpdateBuffs(); end,
					checked = function() return A.db.global.Class.Rogue.SkipCrippling; end,
					isNotRadio = true,
				},
				{
					text = "Refresh non-lethal poison too when using lethal poison",
					func = function() A.db.global.Class.Rogue.RefreshBoth = not A.db.global.Class.Rogue.RefreshBoth; A:UpdateBuffs(); end,
					checked = function() return A.db.global.Class.Rogue.RefreshBoth; end,
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
					func = function() A.db.global.Class.Warlock.EnableGrimoireSacrificeAlert = not A.db.global.Class.Warlock.EnableGrimoireSacrificeAlert; A:UpdateBuffs(); end,
					checked = function() return A.db.global.Class.Warlock.EnableGrimoireSacrificeAlert; end,
					isNotRadio = true,
				},
				{
					text = "Enable alert for Soulstone",
					func = function() A.db.global.Class.Warlock.EnableSoulstone = not A.db.global.Class.Warlock.EnableSoulstone; A:UpdateBuffs(); end,
					checked = function() return A.db.global.Class.Warlock.EnableSoulstone; end,
					isNotRadio = true,
				},
				{
					text = "Only enable while solo",
					func = function() A.db.global.Class.Warlock.OnlyEnableSolo = not A.db.global.Class.Warlock.OnlyEnableSolo; A:UpdateBuffs(); end,
					checked = function() return A.db.global.Class.Warlock.OnlyEnableSolo; end,
					isNotRadio = true,
				},
				{
					text = "Only enable while not in instances",
					func = function() A.db.global.Class.Warlock.OnlyEnableOutside = not A.db.global.Class.Warlock.OnlyEnableOutside; A:UpdateBuffs(); end,
					checked = function() return A.db.global.Class.Warlock.OnlyEnableOutside; end,
					isNotRadio = true,
				},
				{
					text = "Reduce expiry alert threshold for Soulstone",
					func = function() A.db.global.Class.Warlock.ExpiryOverride = not A.db.global.Class.Warlock.ExpiryOverride; A:UpdateBuffs(); end,
					checked = function() return A.db.global.Class.Warlock.ExpiryOverride; end,
					isNotRadio = true,
				},
			},
		},
		["SHAMAN"]	= {
			text = "Shaman Options",
			hasArrow = true,
			notCheckable = true,
			menuList = {
				{
					text = "Shaman Options", isTitle = true, notCheckable = true,
				},
				{
					text = "Enable alert for Shaman shield buff",
					func = function() A.db.global.Class.Shaman.RemindShield = not A.db.global.Class.Shaman.RemindShield; A:UpdateBuffs(); end,
					checked = function() return A.db.global.Class.Shaman.RemindShield; end,
					isNotRadio = true,
				},
			},
		},
		["PRIEST"]	= {
			text = "Priest Options",
			hasArrow = true,
			notCheckable = true,
			menuList = {
				{
					text = "Priest Options", isTitle = true, notCheckable = true,
				},
				{
					text = "Enable alert for Shadowform",
					func = function() A.db.global.Class.Priest.RemindShadowform = not A.db.global.Class.Priest.RemindShadowform; A:UpdateBuffs(); end,
					checked = function() return A.db.global.Class.Priest.RemindShadowform; end,
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
					text = "Enable alert for Righteous Fury",
					func = function() A.db.global.Class.Paladin.RemindRighteousFury = not A.db.global.Class.Paladin.RemindRighteousFury; A:UpdateBuffs(); end,
					checked = function() return A.db.global.Class.Paladin.RemindRighteousFury; end,
					isNotRadio = true,
				},
			},
		},
		["HUNTER"]	= {
			text = "Hunter Options",
			hasArrow = true,
			notCheckable = true,
			menuList = {
				{
					text = "Hunter Options", isTitle = true, notCheckable = true,
				},
				{
					text = "Enable alerts for Lone Wolf buffs",
					func = function() A.db.global.Class.Hunter.EnableLoneWolf = not A.db.global.Class.Hunter.EnableLoneWolf; A:UpdateBuffs(); end,
					checked = function() return A.db.global.Class.Hunter.EnableLoneWolf; end,
					isNotRadio = true,
				},
				{
					text = "Remind to disable Aspect of the Pack in combat",
					func = function() A.db.global.Class.Hunter.CancelPackAlert = not A.db.global.Class.Hunter.CancelPackAlert; A:UpdateBuffs(); end,
					checked = function() return A.db.global.Class.Hunter.CancelPackAlert; end,
					isNotRadio = true,
				},
			},
		},
		["DEATHKNIGHT"]	= {
			text = "Death Knight Options",
			hasArrow = true,
			notCheckable = true,
			menuList = {
				{
					text = "Death Knight Options", isTitle = true, notCheckable = true,
				},
				{
					text = "Alert if in incorrect presence",
					func = function() A.db.global.Class.DeathKnight.PresenceAlert = not A.db.global.Class.DeathKnight.PresenceAlert; A:UpdateBuffs(); end,
					checked = function() return A.db.global.Class.DeathKnight.PresenceAlert; end,
					isNotRadio = true,
				},
				{
					text = "Only alert in combat",
					func = function() A.db.global.Class.DeathKnight.OnlyInCombat = not A.db.global.Class.DeathKnight.OnlyInCombat; A:UpdateBuffs(); end,
					checked = function() return A.db.global.Class.DeathKnight.OnlyInCombat; end,
					isNotRadio = true,
				},
				{
					text = "|cfff5ce47Presence Options|r",
					notCheckable = true,
					hasArrow = true,
					menuList = {
						{
							text = "Blood Specialization", isTitle = true, notCheckable = true,
							icon = "Interface\\icons\\spell_deathknight_bloodpresence",
						},
						{
							text = "Blood Presence",
							func = function() A.db.global.Class.DeathKnight.Presences[1] = 1; A:UpdateBuffs(); end,
							checked = function() return A.db.global.Class.DeathKnight.Presences[1] == 1; end,
						},
						{
							text = "Frost Presence",
							func = function() A.db.global.Class.DeathKnight.Presences[1] = 2; A:UpdateBuffs(); end,
							checked = function() return A.db.global.Class.DeathKnight.Presences[1] == 2; end,
						},
						{
							text = "Unholy Presence",
							func = function() A.db.global.Class.DeathKnight.Presences[1] = 3; A:UpdateBuffs(); end,
							checked = function() return A.db.global.Class.DeathKnight.Presences[1] == 3; end,
						},
						{
							text = " ", isTitle = true, notCheckable = true,
						},
						{
							text = "Frost Specialization", isTitle = true, notCheckable = true,
							icon = "Interface\\icons\\spell_deathknight_frostpresence",
						},
						{
							text = "Blood Presence",
							func = function() A.db.global.Class.DeathKnight.Presences[2] = 1; A:UpdateBuffs(); end,
							checked = function() return A.db.global.Class.DeathKnight.Presences[2] == 1; end,
						},
						{
							text = "Frost Presence",
							func = function() A.db.global.Class.DeathKnight.Presences[2] = 2; A:UpdateBuffs(); end,
							checked = function() return A.db.global.Class.DeathKnight.Presences[2] == 2; end,
						},
						{
							text = "Unholy Presence",
							func = function() A.db.global.Class.DeathKnight.Presences[2] = 3; A:UpdateBuffs(); end,
							checked = function() return A.db.global.Class.DeathKnight.Presences[2] == 3; end,
						},
						{
							text = " ", isTitle = true, notCheckable = true,
						},
						{
							text = "Unholy Specialization", isTitle = true, notCheckable = true,
							icon = "Interface\\icons\\spell_deathknight_unholypresence",
						},
						{
							text = "Blood Presence",
							func = function() A.db.global.Class.DeathKnight.Presences[3] = 1; A:UpdateBuffs(); end,
							checked = function() return A.db.global.Class.DeathKnight.Presences[3] == 1; end,
						},
						{
							text = "Frost Presence",
							func = function() A.db.global.Class.DeathKnight.Presences[3] = 2; A:UpdateBuffs(); end,
							checked = function() return A.db.global.Class.DeathKnight.Presences[3] == 2; end,
						},
						{
							text = "Unholy Presence",
							func = function() A.db.global.Class.DeathKnight.Presences[3] = 3; A:UpdateBuffs(); end,
							checked = function() return A.db.global.Class.DeathKnight.Presences[3] == 3; end,
						},
					},
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
					func = function() A.db.global.Class.Druid.FormAlert = not A.db.global.Class.Druid.FormAlert; A:UpdateBuffs(); end,
					checked = function() return A.db.global.Class.Druid.FormAlert; end,
					isNotRadio = true,
				},
				{
					text = "Only alert in combat",
					func = function() A.db.global.Class.Druid.OnlyInCombat = not A.db.global.Class.Druid.OnlyInCombat; A:UpdateBuffs(); end,
					checked = function() return A.db.global.Class.Druid.OnlyInCombat; end,
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
			A.db.global.ExpirationAlertThreshold = timeValue;
			A:UpdateBuffs();
		end
	end,
	EditBoxOnEnterPressed = function(self)
		local parent = self:GetParent();
		local timeValue = tonumber(parent.editBox:GetText());
		if(timeValue ~= nil) then
			A.db.global.ExpirationAlertThreshold = timeValue;
			A:UpdateBuffs();
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

function A:IsSomeDefaultExpirationTime(t)
	return t == 0 or t == 60 or t == 120 or t == 300 or t == 600 or t == 900; 
end

local function tmerge(table, other)
	for _, item in ipairs(other) do
		tinsert(table, item);
	end
	
	return table;
end

function A:GetCustomFoodStatPriorityMenu()
	local menu = {};
	
	local activeSpec = GetActiveSpecGroup();
	local numSpecs = GetNumSpecGroups();
	
	local currentBestFood = A:GetFoodPreference(true)[1];
	local bestFoodName = E.RATING_NAMES[currentBestFood];
	
	for specIndex = 1, numSpecs do
		tinsert(menu, {
			text = " ", isTitle = true, notCheckable = true,
		});
		
		local spec = GetSpecialization(false, false, specIndex);
		local name, description, icon, role;
		
		if(not spec) then
			icon = "Interface\\Icons\\Ability_Marksmanship";
			name = string.format("Spec %d", specIndex);
		else
			_, name, description, icon, _, role = GetSpecializationInfo(spec);
		end
		
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
		
		tmerge(menu, {
			{
				text = string.format("Attempt to guess (|cffffbb00%s|r)", bestFoodName),
				func = function() self.db.char.FoodPriority[specIndex] = E.STAT.AUTOMATIC; A:UpdateBuffs(); end,
				checked = function() return self.db.char.FoodPriority[specIndex] == E.STAT.AUTOMATIC; end,
			},
			{
				text = E.RATING_NAMES[E.STAT.HASTE],
				func = function() self.db.char.FoodPriority[specIndex] = E.STAT.HASTE; A:UpdateBuffs(); end,
				checked = function() return self.db.char.FoodPriority[specIndex] == E.STAT.HASTE; end,
			},
			{
				text = E.RATING_NAMES[E.STAT.MULTISTRIKE],
				func = function() self.db.char.FoodPriority[specIndex] = E.STAT.MULTISTRIKE; A:UpdateBuffs(); end,
				checked = function() return self.db.char.FoodPriority[specIndex] == E.STAT.MULTISTRIKE; end,
			},
			{
				text = E.RATING_NAMES[E.STAT.MASTERY],
				func = function() self.db.char.FoodPriority[specIndex] = E.STAT.MASTERY; A:UpdateBuffs(); end,
				checked = function() return self.db.char.FoodPriority[specIndex] == E.STAT.MASTERY; end,
			},
			{
				text = E.RATING_NAMES[E.STAT.CRIT],
				func = function() self.db.char.FoodPriority[specIndex] = E.STAT.CRIT; A:UpdateBuffs(); end,
				checked = function() return self.db.char.FoodPriority[specIndex] == E.STAT.CRIT; end,
			},
			{
				text = E.RATING_NAMES[E.STAT.VERSATILITY],
				func = function() self.db.char.FoodPriority[specIndex] = E.STAT.VERSATILITY; A:UpdateBuffs(); end,
				checked = function() return self.db.char.FoodPriority[specIndex] == E.STAT.VERSATILITY; end,
			},
		});
		
		if(role == "TANK") then
			tinsert(menu, {
				text = E.RATING_NAMES[E.STAT.STAMINA],
				func = function() self.db.char.FoodPriority[specIndex] = E.STAT.STAMINA; A:UpdateBuffs(); end,
				checked = function() return self.db.char.FoodPriority[specIndex] == E.STAT.STAMINA; end,
			});
		end
	end
	
	return menu;
end

function A:GetDatabrokerMenuData()
	local legibleClass, class = UnitClass("player");
	
	local locktext = "Unlock";
	
	if(not A.IsFrameLocked) then
		locktext = "Lock";
	end
	
	local keybind, keybindingText = A:GetBinding();
	if(keybind) then
		keybindingText = string.format("Change the keybinding (|cfff5ce47Current %s|r)", keybind);
	else
		keybindingText = "Set a keybind (|cfff15050No binding!|r)";
	end
	
	local expirationAlertTimeText = "Disabled";
	if(self.db.global.ExpirationAlertThreshold > 0) then
		expirationAlertTimeText = A:FormatTime(self.db.global.ExpirationAlertThreshold, true);
	end
	
	local customTimeText = "Custom";
	if(not A:IsSomeDefaultExpirationTime(self.db.global.ExpirationAlertThreshold)) then
		customTimeText = string.format("Custom: %s", A:FormatTime(self.db.global.ExpirationAlertThreshold, true));
	end
	
	local customFoodStatPriority = A:GetCustomFoodStatPriorityMenu();
	
	local data = {
		{
			text = "Buffy Options", isTitle = true, notCheckable = true,
		},
		{
			text = "Buffy notifications enabled",
			func = function() self.db.global.Enabled = not self.db.global.Enabled; A:UpdateBuffs(); end,
			checked = function() return self.db.global.Enabled; end,
			isNotRadio = true,
		},
		{
			text = string.format("%s Buffy frame", locktext),
			func = function() self.IsFrameLocked = not self.IsFrameLocked; A:UpdateBuffs(); end,
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
			func = function() self.db.global.ShowInCombat = not self.db.global.ShowInCombat; A:UpdateBuffs(); end,
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
					func = function() self.db.global.DisableWhenResting = not self.db.global.DisableWhenResting; A:UpdateBuffs(); end,
					checked = function() return self.db.global.DisableWhenResting; end,
					isNotRadio = true,
				},
				{
					text = "Disable while not in an instance",
					func = function() self.db.global.DisableOutside = not self.db.global.DisableOutside; A:UpdateBuffs(); end,
					checked = function() return self.db.global.DisableOutside; end,
					isNotRadio = true,
				},
				{
					text = "Show while flying or in a vehicle",
					func = function() self.db.global.ShowWhileMounted = not self.db.global.ShowWhileMounted; A:UpdateBuffs(); end,
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
					func = function() self.db.global.PepeReminderEnabled = not self.db.global.PepeReminderEnabled; A:UpdateBuffs(); end,
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
			text = "Alert if only an aura is in use",
			func = function() self.db.global.OverrideAuras = not self.db.global.OverrideAuras; A:UpdateBuffs(); end,
			checked = function() return self.db.global.OverrideAuras; end,
			isNotRadio = true,
		},
		{
			text = "Remind about raid consumables",
			func = function() self.db.global.ConsumablesRemind.Enabled = not self.db.global.ConsumablesRemind.Enabled; A:UpdateBuffs(); end,
			checked = function() return self.db.global.ConsumablesRemind.Enabled; end,
			isNotRadio = true,
			hasArrow = true,
			menuList = {
				{
					text = "Consumables Remind", isTitle = true, notCheckable = true,
				},
				{
					text = "Enable in Draenor raids",
					func = function() self.db.global.ConsumablesRemind.Mode = E.RAID_CONSUMABLES.RAIDS_ONLY; A:UpdateBuffs(); CloseMenus(); end,
					checked = function() return self.db.global.ConsumablesRemind.Mode == E.RAID_CONSUMABLES.RAIDS_ONLY; end,
				},
				{
					text = "Enable in Draenor raids and dungeons",
					func = function() self.db.global.ConsumablesRemind.Mode = E.RAID_CONSUMABLES.RAIDS_AND_DUNGEONS; A:UpdateBuffs(); CloseMenus(); end,
					checked = function() return self.db.global.ConsumablesRemind.Mode == E.RAID_CONSUMABLES.RAIDS_AND_DUNGEONS; end,
				},
				{
					text = "Enable everywhere",
					func = function() self.db.global.ConsumablesRemind.Mode = E.RAID_CONSUMABLES.EVERYWHERE; A:UpdateBuffs(); CloseMenus(); end,
					checked = function() return self.db.global.ConsumablesRemind.Mode == E.RAID_CONSUMABLES.EVERYWHERE; end,
				},
				{
					text = " ", isTitle = true, notCheckable = true,
				},
				{
					text = "Consumable Types", isTitle = true, notCheckable = true,
				},
				{
					text = "Enable for flasks",
					func = function() self.db.global.ConsumablesRemind.Flasks = not self.db.global.ConsumablesRemind.Flasks; A:UpdateBuffs(); CloseMenus(); end,
					checked = function() return self.db.global.ConsumablesRemind.Flasks; end,
					isNotRadio = true,
					hasArrow = true,
					menuList = {
						{
							text = "Only alert for non-consumable outside instances",
							func = function() self.db.global.ConsumablesRemind.OnlyInfiniteFlask = not self.db.global.ConsumablesRemind.OnlyInfiniteFlask; A:UpdateBuffs(); CloseMenus(); end,
							checked = function() return self.db.global.ConsumablesRemind.OnlyInfiniteFlask; end,
							isNotRadio = true,
						},
					},
				},
				{
					text = "Enable for augment runes",
					func = function() self.db.global.ConsumablesRemind.Runes = not self.db.global.ConsumablesRemind.Runes; A:UpdateBuffs(); CloseMenus(); end,
					checked = function() return self.db.global.ConsumablesRemind.Runes; end,
					isNotRadio = true,
					hasArrow = true,
					menuList = {
						{
							text = "Only alert for the non-consumable rune",
							func = function() self.db.global.ConsumablesRemind.OnlyInfiniteRune = not self.db.global.ConsumablesRemind.OnlyInfiniteRune; A:UpdateBuffs(); CloseMenus(); end,
							checked = function() return self.db.global.ConsumablesRemind.OnlyInfiniteRune; end,
							isNotRadio = true,
						},
					},
				},
				{
					text = "Enable for food",
					func = function() self.db.global.ConsumablesRemind.Food = not self.db.global.ConsumablesRemind.Food; A:UpdateBuffs(); CloseMenus(); end,
					checked = function() return self.db.global.ConsumablesRemind.Food; end,
					isNotRadio = true,
					hasArrow = true,
					menuList = tmerge({
						{
							text = "Prioritize own food over feasts",
							func = function() self.db.global.ConsumablesRemind.FeastsMode = E.FEASTS_MODE.OWN_FOOD; A:UpdateBuffs(); CloseMenus(); end,
							checked = function() return self.db.global.ConsumablesRemind.FeastsMode == E.FEASTS_MODE.OWN_FOOD; end,
						},
						{
							text = "Prioritize feasts over own food",
							func = function() self.db.global.ConsumablesRemind.FeastsMode = E.FEASTS_MODE.PRIORITY_FEASTS; A:UpdateBuffs(); CloseMenus(); end,
							checked = function() return self.db.global.ConsumablesRemind.FeastsMode == E.FEASTS_MODE.PRIORITY_FEASTS; end,
						},
						{
							text = "Only alert for feasts",
							func = function() self.db.global.ConsumablesRemind.FeastsMode = E.FEASTS_MODE.ONLY_FEASTS; A:UpdateBuffs(); CloseMenus(); end,
							checked = function() return self.db.global.ConsumablesRemind.FeastsMode == E.FEASTS_MODE.ONLY_FEASTS; end,
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
					func = function() self.db.global.ConsumablesRemind.DisableInLFR = not self.db.global.ConsumablesRemind.DisableInLFR; A:UpdateBuffs(); CloseMenus(); end,
					checked = function() return self.db.global.ConsumablesRemind.DisableInLFR; end,
					isNotRadio = true,
				},
				{
					text = "Disable if not in party or raid group",
					func = function() self.db.global.ConsumablesRemind.DisableOutsideGroup = not self.db.global.ConsumablesRemind.DisableOutsideGroup; A:UpdateBuffs(); CloseMenus(); end,
					checked = function() return self.db.global.ConsumablesRemind.DisableOutsideGroup; end,
					isNotRadio = true,
				},
				{
					text = "Do not alert while in combat",
					func = function() self.db.global.ConsumablesRemind.NotInCombat = not self.db.global.ConsumablesRemind.NotInCombat; A:UpdateBuffs(); CloseMenus(); end,
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
					func = function() self.db.global.ConsumablesRemind.SkipStamina = not self.db.global.ConsumablesRemind.SkipStamina; A:UpdateBuffs(); CloseMenus(); end,
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
					func = function() self.db.global.ConsumablesRemind.KeybindEnabled = not self.db.global.ConsumablesRemind.KeybindEnabled; A:ClearTempBind(); A:UpdateBuffs(); CloseMenus(); end,
					checked = function() return self.db.global.ConsumablesRemind.KeybindEnabled; end,
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
					func = function() self.db.global.NoExpirationAlertInCombat = not self.db.global.NoExpirationAlertInCombat; A:UpdateBuffs(); CloseMenus(); end,
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
					func = function() self.db.global.ExpirationAlertThreshold = 0; A:UpdateBuffs(); CloseMenus(); end,
					checked = function() return self.db.global.ExpirationAlertThreshold == 0; end,
				},
				{
					text = "1 minute",
					func = function() self.db.global.ExpirationAlertThreshold = 60; A:UpdateBuffs(); CloseMenus(); end,
					checked = function() return self.db.global.ExpirationAlertThreshold == 60; end,
				},
				{
					text = "2 minutes",
					func = function() self.db.global.ExpirationAlertThreshold = 120; A:UpdateBuffs(); CloseMenus(); end,
					checked = function() return self.db.global.ExpirationAlertThreshold == 120; end,
				},
				{
					text = "5 minutes",
					func = function() self.db.global.ExpirationAlertThreshold = 300; A:UpdateBuffs(); CloseMenus(); end,
					checked = function() return self.db.global.ExpirationAlertThreshold == 300; end,
				},
				{
					text = "10 minutes",
					func = function() self.db.global.ExpirationAlertThreshold = 600; A:UpdateBuffs(); CloseMenus(); end,
					checked = function() return self.db.global.ExpirationAlertThreshold == 600; end,
				},
				{
					text = "15 minutes",
					func = function() self.db.global.ExpirationAlertThreshold = 900; A:UpdateBuffs(); CloseMenus(); end,
					checked = function() return self.db.global.ExpirationAlertThreshold == 900; end,
				},
				{
					text = customTimeText,
					func = function() StaticPopup_Show("BUFFY_CUSTOM_EXPIRE_TIME"); CloseMenus(); end,
					checked = function()
						return not A:IsSomeDefaultExpirationTime(self.db.global.ExpirationAlertThreshold);
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
		{
			text = "Automatic announcement options",
			func = function() self.db.global.ShowWhileMounted = not self.db.global.ShowWhileMounted; A:UpdateBuffs(); end,
			checked = function() return self.db.global.ShowWhileMounted; end,
			notCheckable = true,
			hasArrow = true,
			menuList = {
				{
					text = "Announcement Options", isTitle = true, notCheckable = true,
				},
				{
					text = "Announce raid buff status on ready check",
					func = function() self.db.global.Announcements.Enabled = not self.db.global.Announcements.Enabled; end,
					checked = function() return self.db.global.Announcements.Enabled; end,
					isNotRadio = true,
				},
				{
					text = " ", isTitle = true, notCheckable = true,
				},
				{
					text = "Announcement Channel", isTitle = true, notCheckable = true,
				},
				{
					text = "Announce to party or raid chat",
					func = function() self.db.global.Announcements.OnlyToSelf = not self.db.global.Announcements.OnlyToSelf; end,
					checked = function() return self.db.global.Announcements.OnlyToSelf == false; end,
				},
				{
					text = "Announce to self only",
					func = function() self.db.global.Announcements.OnlyToSelf = not self.db.global.Announcements.OnlyToSelf; end,
					checked = function() return self.db.global.Announcements.OnlyToSelf == true; end,
				},
				{
					text = "Announce in chat only if leader or assist",
					func = function() self.db.global.Announcements.OnlyIfLeaderOrAssist = not self.db.global.Announcements.OnlyIfLeaderOrAssist; end,
					checked = function() return self.db.global.Announcements.OnlyIfLeaderOrAssist; end,
					isNotRadio = true,
				},
				{
					text = " ", isTitle = true, notCheckable = true,
				},
				{
					text = "Announcement Style", isTitle = true, notCheckable = true,
				},
				{
					text = "Only missing types",
					func = function() self.db.global.Announcements.PerPlayer = not self.db.global.Announcements.PerPlayer; end,
					checked = function() return self.db.global.Announcements.PerPlayer == false; end,
				},
				{
					text = "Players that are missing buffs",
					func = function() self.db.global.Announcements.PerPlayer = not self.db.global.Announcements.PerPlayer; end,
					checked = function() return self.db.global.Announcements.PerPlayer == true; end,
				},
			},
		},
	};
	
	local className = A:GetClassNameString(class, legibleClass);
	
	local classOptions = A:GetClassOptions();
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
	
	if(not A.db.global.Position.DefaultPosition) then
		tinsert(data, 4, {
			text = "Reset position",
			func = function() A:ResetPosition(); end,
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

function A:GetClassNameString(class, legibleClass)
	if(not class or not legibleClass) then return end
	
	local classColor = A:GetClassColor(class).colorStr;
	
	local left, right, top, bottom = unpack(CLASS_ICON_TCOORDS[class]);
	left = left * 256 + 4;
	right = right * 256 - 4;
	top = top * 256 + 4;
	bottom = bottom * 256 - 4;
	
	local icon = string.format("|TInterface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes:14:14:0:0:256:256:%d:%d:%d:%d|t", left, right, top, bottom);
	
	return string.format("%s |c%s%s|r", icon, classColor, legibleClass);
end

function A:OpenContextMenu(parentframe)
	if(not A.ContextMenu) then
		A.ContextMenu = CreateFrame("Frame", ADDON_NAME .. "ContextMenuFrame", parentframe, "UIDropDownMenuTemplate");
	end
	
	A.ContextMenu:SetPoint("BOTTOM", parentframe, "CENTER", 0, 5);
	EasyMenu(A:GetDatabrokerMenuData(), A.ContextMenu, "cursor", 0, 0, "MENU", 5);
	
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

function A:UpdateDatabrokerText()
	local buffs = A:ScanCurrentBuffs();
	local foundBuffs = 0;
	local numBuffTypes = #A.BUFF_TYPES;
	
	for category, data in pairs(buffs) do
		if(data ~= false) then
			foundBuffs = foundBuffs + 1;
		end
	end
	
	A.databroker.text = string.format("%d/%d |cffffcc00buffs|r", foundBuffs, numBuffTypes);
end

function A:GetClassColor(class)
	return (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[class or 'PRIEST'];
end

function A:AddChatMessage(msg, ...)
	DEFAULT_CHAT_FRAME:AddMessage(
		string.format("|cff20cff4Buffy|r %s", string.format(msg or "", ...))
	);
end

function A:SendAnnounceMessage(channel, msg)
	if(channel == "SELF") then
		A:AddChatMessage(msg);
	elseif(channel == "RAID" or channel == "PARTY" or channel == "SAY") then
		SendChatMessage(A:StripColor(msg), channel);
	end
end

function A:StripColor(text)
	return string.gsub(string.gsub(text, "\124c%w%w%w%w%w%w%w%w", ""), "\124r", "");
end

function A:AnnounceBuffStatus(extended, outputChannel)
	local groupType = A:GetGroupType();
	
	local channel;
	if(outputChannel == nil and groupType == E.GROUP_TYPE.SOLO or outputChannel == "self") then
		channel = "SELF";
	elseif(outputChannel == nil and groupType == E.GROUP_TYPE.PARTY or outputChannel == "party") then
		channel = "PARTY";
	elseif(outputChannel == nil and groupType == E.GROUP_TYPE.RAID or outputChannel == "raid") then
		channel = "RAID";
	end
	
	local missingBuffs = A:ScanBuffs();
	
	local numMissingCategories = 0;
	local missingCategories = {};
	for unit, categories in pairs(missingBuffs) do
		if(UnitIsConnected(unit)) then
			for _, category in ipairs(categories) do
				if(not missingCategories[category]) then
					missingCategories[category] = {};
					numMissingCategories = numMissingCategories + 1;
				end
				
				tinsert(missingCategories[category], unit);
			end
		end
	end
	
	A:SendAnnounceMessage(channel, "=== Buffy Raid Buff Status ===");
	
	if(not extended) then
		local categoryNames = {};
		for category, _ in pairs(missingCategories) do
			tinsert(categoryNames, string.format("|cfffada58%s|r", E.BUFF_TYPE_NAMES[category]));
		end
		
		local msg = string.format("Buffs Missing (%d): %s", #categoryNames, table.concat(categoryNames, ", "));
		A:SendAnnounceMessage(channel, msg);
	else
		for category, units in pairs(missingCategories) do
			local unitNames = {};
			for _, unit in ipairs(units) do
				local name, realm = UnitFullName(unit);
				if(realm and strlen(realm) > 0 and realm ~= GetRealmName()) then
					name = name .. "-" .. realm;
				end
				
				local _, class = UnitClass(unit);
				local color = A:GetClassColor(class).colorStr;
				
				tinsert(unitNames, string.format("|c%s%s|r", color, name) or "Unknown");
			end
			
			local msg = string.format("Missing |cfffada58%s|r (%d): %s", E.BUFF_TYPE_NAMES[category], #units, table.concat(unitNames, ", "));
			A:SendAnnounceMessage(channel, msg);
		end
	end
	
	if(numMissingCategories == 0) then
		A:SendAnnounceMessage(chanel, "Great! Nobody is missing any buffs!");
	end
end

function A:GetPlayerRaidRosterRank()
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

function A:READY_CHECK()
	if(self.db.global.Announcements.Enabled) then
		local channel = self.db.global.Announcements.OnlyToSelf and "self" or nil;
		
		if(not self.db.global.Announcements.OnlyToSelf and self.db.global.Announcements.OnlyIfLeaderOrAssist) then
			if((IsInGroup() and not UnitIsGroupLeader("player")) or (IsInRaid() and A:GetPlayerRaidRosterRank() == 0)) then
				channel = "self";
			end
		end
		
		A:AnnounceBuffStatus(self.db.global.Announcements.PerPlayer, channel);
	end
end

local brokerTooltip, brokerTooltipMinWidth;

function A:InitializeDatabroker()
	A.databroker = LDB:NewDataObject(ADDON_NAME, {
		type = "data source",
		label = "Buffy",
		text = "Buffy",
		icon = BUFFY_ICON,
		OnClick = function(frame, button)
			if(button == "LeftButton") then
				if(IsShiftKeyDown()) then
					A:AnnounceBuffStatus(IsControlKeyDown(), IsAltKeyDown() and "self" or nil);
				end
			elseif(button == "RightButton") then
				GameTooltip:Hide();
				A:OpenContextMenu(frame);
			end
		end,
		OnTooltipShow = function(tooltip)
			if not tooltip or not tooltip.AddLine then return end
			
			brokerTooltip = tooltip;
			
			if(not brokerTooltipMinWidth) then
				brokerTooltipMinWidth = tooltip:GetMinimumWidth();
			end
			
			tooltip:SetMinimumWidth(330);
			
			tooltip:AddLine(TEX_BUFFY_ICON .. " Buffy");
			tooltip:AddLine(" ");
			
			if(not self.db.global.Enabled) then
				tooltip:AddLine("|cffe05754Notifications Currently Disabled|r");
				tooltip:AddLine(" ");
			end
			
			tooltip:AddDoubleLine("Category", "Active Buffs on You");
			
			local buffs = A:ScanCurrentBuffs();
			
			local buffStatus, numPartyMembers, numPartyMembersInRange = A:GetRaidBuffStatus();
			-- local castableSpells = A:ScanWhoCanCast();
			
			for index, category in ipairs(A.BUFF_TYPES) do
				local statusData = buffStatus[category] or {
					total = 0,
					inRange = 0,
					hasAura = false,
				};
				
				local statusColor = "f04817";
				if(statusData.hasAura) then
					statusColor = "4698ff";
				elseif(statusData.total == numPartyMembers) then
					statusColor = "91ef32";
				elseif(statusData.inRange == numPartyMembersInRange) then
					statusColor = "f1e230";
				end
				
				local categoryText = string.format("|cffffffff%s|r |cff%s(%d/%d)|r", E.BUFF_TYPE_NAMES[category], statusColor, statusData.total, numPartyMembers);
				local statusText = "|cffffffffMissing|r";
				
				local currentBuff = buffs[category];
				
				if(currentBuff ~= false) then
					local casterName = currentBuff.casterName;
					local classColor = "ffffffff";
					
					local isPet, masterName, petName = A:UnitIsPet(casterName);
					if(not isPet) then
						classColor = A:GetClassColor(currentBuff.casterClass).colorStr;
					else
						casterName = string.format("%s|r's pet", masterName);
						
						local _, class = UnitClass(masterName);
						classColor = A:GetClassColor(class).colorStr;
					end
					
					local buffname, _, bufficon = GetSpellInfo(currentBuff.buff);
					
					statusText = string.format("%s %s (|c%s%s|r)", ICON_PATTERN_14:format(bufficon), buffname, classColor, casterName);
				-- elseif(castableSpells[category]) then
				-- 	local numUnits = #castableSpells[category].units;
				-- 	statusText = string.format("%d people can cast", numUnits);
				end
				
				tooltip:AddDoubleLine(categoryText, statusText, nil, nil, nil, 1, 1, 1);
			end
			
			tooltip:AddLine(" ");
			tooltip:AddDoubleLine("|cfff04817Red status|r", "Nearby players missing the buff");
			tooltip:AddDoubleLine("|cfff1e230Yellow status|r", "All nearby players have the buff");
			tooltip:AddDoubleLine("|cff91ef32Green status|r", "All players have the buff");
			tooltip:AddDoubleLine("|cff4698ffBlue status|r", "Some players only have an aura");
			
			tooltip:AddLine(" ");
			
			local groupType = A:GetGroupType();
			local channel;
			if(groupType == E.GROUP_TYPE.SOLO or IsAltKeyDown()) then
				channel = "Self";
			elseif(groupType == E.GROUP_TYPE.RAID) then
				channel = "Raid Chat";
			elseif(groupType == E.GROUP_TYPE.PARTY) then
				channel = "Party Chat";
			end
			
			tooltip:AddLine(string.format("Shift Left-Click |cffffffff\124 Announce Status To %s|r", channel));
			tooltip:AddLine("Ctrl Shift Left-Click |cffffffff\124 Announce Players Missing Buffs|r");
			if(channel ~= "Self") then
				tooltip:AddLine("Additionally Hold Alt |cffffffff\124 Announce to Self|r");
			end
			tooltip:AddLine("Right-Click |cffffffff\124 Show options|r");
			
			-- Addon.tooltip_open = true;
		end,
		OnLeave = function(frame)
			-- Addon.tooltip_open = false;
			
			if(brokerTooltip) then
				brokerTooltip:SetMinimumWidth(brokerTooltipMinWidth or 0);
				brokerTooltip = nil;
				brokerTooltipMinWidth = nil;
			end
			
		end,
	});

	A:UpdateDatabrokerText();
end
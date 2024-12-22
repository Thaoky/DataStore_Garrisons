--[[	*** DataStore_Garrisons ***
Written by : Thaoky, EU-Marécages de Zangar
November 30th, 2014
--]]
if not DataStore then return end

local addonName, addon = ...
local thisCharacter
local allCharacters

local L = AddonFactory:GetLocale(addonName)

-- *** Utility functions ***
local function GetNumUncollectedResources(from)
	-- no known collection time (alt never logged in) .. return 0
	if not from then return 0 end
	
	local age = time() - from
	local resources = math.floor(age / 600)		-- 10 minutes = 1 resource
	
	-- cap at 500
	return resources > 500 and 500 or resources
end

local function CheckUncollectedResources()
	local num, name

	-- Loop through all characters
	for id, character in pairs(allCharacters) do
		num = GetNumUncollectedResources(character.lastResourceCollection)
		
		-- if the amount of resources is too high, report it
		if num >= options.ReportLevel then
			name = select(3, DataStore:GetCharacterInfoByID(id))

			if name then
				addon:Print(format(L["UNCOLLECTED_RESOURCES_ALERT"], name, num))
			end
		end
	end
end

-- *** Scanning functions ***
local function ScanResourceCollectionTime()
	thisCharacter.lastResourceCollection = time()
end

-- *** Event Handlers ***
local function OnShowLootToast(event, lootType, link, quantity, specID, sex, isPersonal, lootSource)
	if lootType ~= "currency" then return end
	
	-- From AlertFrames.lua
	-- local LOOT_SOURCE_GARRISON_CACHE = 10
	
	-- make sure it is garrison resources
	if link and link:match("currency:824") and lootSource == 10 then	
		ScanResourceCollectionTime()
	end
end

AddonFactory:OnAddonLoaded(addonName, function()
	DataStore:RegisterModule({
		addon = addon,
		addonName = addonName,
		rawTables = {
			"DataStore_Garrisons_Options"
		},
		characterTables = {
			["DataStore_Garrisons_Characters"] = {
				GetUncollectedResources = function(character) return GetNumUncollectedResources(character.lastResourceCollection) end,
				GetLastResourceCollectionTime = function(character) return character.lastResourceCollection or 0 end,
			},
		}
	})
	
	thisCharacter = DataStore:GetCharacterDB("DataStore_Garrisons_Characters", true)
	thisCharacter.lastUpdate = time()

	allCharacters = DataStore_Garrisons_Characters
end)

AddonFactory:OnPlayerLogin(function()
	options = DataStore:SetDefaults("DataStore_Garrisons_Options", {
		ReportUncollected = true,		-- Report uncollected resources
		ReportLevel = 400,
	})
	
	-- Resources
	addon:ListenTo("SHOW_LOOT_TOAST", OnShowLootToast)

	addon:SetupOptions()
	if options.ReportUncollected then
		CheckUncollectedResources()
	end
end)

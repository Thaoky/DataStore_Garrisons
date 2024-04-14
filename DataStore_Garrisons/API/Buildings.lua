--[[
	This file keeps track of garrison buildings
	Expansion Features / 6.0 - Warlords of Draenor
--]]

local addonName, addon = ...
local thisCharacter

local DataStore, wipe, C_Garrison = DataStore, wipe, C_Garrison

local enum = DataStore.Enum.BuildingTypes
local buildingIDToTypes = DataStore.Enum.BuildingIDToTypes
local bit64 = LibStub("LibBit64")

local FOLLOWER_TYPE = Enum.GarrisonFollowerType.FollowerType_6_0_GarrisonFollower

-- *** Scanning functions ***
local function AddBuilding(internalID, rank, buildingID)
	thisCharacter[internalID] = rank or 0			-- bits 0-1 = rank 
				+ bit64:LeftShift(buildingID, 4)		-- bits 2+ = id
end

local function ScanBuildings()
	local plots = C_Garrison.GetPlots(FOLLOWER_TYPE)

	-- to avoid deleting previously saved data when the game is not ready to deliver information
	-- exit if no data is available
	if not plots or #plots == 0 then return end

	wipe(thisCharacter)
	
	-- Scan Town Hall
	local level = C_Garrison.GetGarrisonInfo(Enum.GarrisonType.Type_6_0_Garrison)
	
	AddBuilding(enum.TownHall, level, 0)
	
	-- Scan other buildings
	local plot
	for i = 1, #plots do
		plot = plots[i]
		
		-- local id, name, texPrefix, icon, rank, isBuilding, timeStart, buildTime, canActivate, canUpgrade, isPrebuilt = C_Garrison.GetOwnedBuildingInfoAbbrev(plot.id);
		local id, _, _, _, rank = C_Garrison.GetOwnedBuildingInfoAbbrev(plot.id)
		if id then
			AddBuilding(buildingIDToTypes[id], rank, id)
		end
	end
end

DataStore:OnAddonLoaded(addonName, function() 
	DataStore:RegisterTables({
		addon = addon,
		characterTables = {
			["DataStore_Garrisons_Buildings"] = {
				GetBuildingInfo = function(character, internalID)
					local building = character[internalID]
					
					if building then
						return bit64:RightShift(building, 2), 		-- bits 2+ = id
								bit64:GetBits(building, 0, 2)			-- bits 0-1 = rank 
					end
				end,
			},
		}
	})
	
	thisCharacter = DataStore:GetCharacterDB("DataStore_Garrisons_Buildings", true)
end)

DataStore:OnAddonLoaded("Blizzard_GarrisonUI", function() 
	ScanBuildings()
	-- ScanFollowers()	-- Seems this scan can cause the values to be zeroed out.
end)

DataStore:OnPlayerLogin(function()
	addon:ListenTo("GARRISON_BUILDING_ACTIVATED", ScanBuildings)
	addon:ListenTo("GARRISON_BUILDING_UPDATE", ScanBuildings)
	addon:ListenTo("GARRISON_BUILDING_REMOVED", ScanBuildings)
end)

--[[
	This file keeps track of shipments
	Expansion Features / 
--]]

local addonName, addon = ...
local thisCharacter

local DataStore, pairs, C_Garrison = DataStore, pairs, C_Garrison

local bit64 = LibStub("LibBit64")

-- *** Scanning functions ***
local function ScanNextArtifactResearch()
	-- scan the remaining time until the next artifact research notes are complete
	
	local shipments = C_Garrison.GetLooseShipments(Enum.GarrisonType.Type_7_0_Garrison)
	local char = thisCharacter

	-- reset values 
	char.artifactResearchCreationTime = 0
	char.artifactResearchDuration = 0
	char.artifactResearchNumReady = 0
	char.artifactResearchNumTotal = 0
		
	for i = 1, #shipments do
		local name, _, _, numReady, numTotal, creationTime, duration = C_Garrison.GetLandingPageShipmentInfoByContainerID(shipments[i])
		
		if name == GetItemInfo(139390) and creationTime then		-- the name must be "Artifact Research Notes"
			char.artifactResearchCreationTime = creationTime
			char.artifactResearchDuration = duration
			char.artifactResearchNumReady = numReady
			char.artifactResearchNumTotal = numTotal
			
			return	-- once found, we don't care about the rest
		end
	end
end

-- ** Mixins **
local function _GetArtifactResearchInfo(character)
	local creationTime = character.artifactResearchCreationTime
	local duration = character.artifactResearchDuration
	local numReady = character.artifactResearchNumReady
	local numTotal = character.artifactResearchNumTotal
	
	local remaining = (creationTime + duration) - time() 
	
	if (remaining < 0) then		-- if remaining is negative, the next shipment is ready ..
		numReady = numReady + 1			-- .. so increase by 1
		if numReady > numTotal then	-- .. and prevent overflow
			numReady = numTotal
		end

		remaining = 0
	end

	return remaining, numReady, numTotal
end


DataStore:OnAddonLoaded(addonName, function() 
	DataStore:RegisterTables({
		addon = addon,
		characterTables = {
			["DataStore_Garrisons_Shipments"] = {
				GetArtifactResearchInfo = _GetArtifactResearchInfo,
			},
		}
	})
	
	thisCharacter = DataStore:GetCharacterDB("DataStore_Garrisons_Shipments", true)
end)

DataStore:OnPlayerLogin(function()
	-- Shipments
	addon:ListenTo("GARRISON_LANDINGPAGE_SHIPMENTS", ScanNextArtifactResearch)
end)

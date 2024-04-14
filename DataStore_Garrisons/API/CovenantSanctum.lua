--[[
	This file keeps track of the Covenant Sanctum reservoir talents
	Expansion Features / 9.0 - Shadowlands
--]]

local addonName, addon = ...
local thisCharacter
local sanctum

local DataStore, pairs, wipe, C_CovenantSanctumUI, C_Garrison = DataStore, pairs, wipe, C_CovenantSanctumUI, C_Garrison

local bit64 = LibStub("LibBit64")

-- *** Scanning functions ***
local function ScanReservoirTalents()
	if not C_CovenantSanctumUI.CanAccessReservoir() then return end

	local talents = {}
	
--[[
talentInfo.isBeingResearched 
talentInfo.hasInstantResearch 
talentInfo.startTime;
talentInfo.researchDuration;
talentInfo.id;
talentInfo.talentAvailability 
talentInfo.timeRemaining;
talentInfo.tier

talentInfo.name
talentInfo.icon
talentInfo.researchCurrencyCosts
talentInfo.researchGoldCost 
--]]	
	
	for _, feature in pairs(C_CovenantSanctumUI.GetFeatures()) do
		local treeID = feature.garrTalentTreeID
		local info = C_Garrison.GetTalentTreeInfo(treeID)

		-- skip the "reservoir upgrade" type
		if info.featureType ~= Enum.GarrTalentFeatureType.ReservoirUpgrades then
			-- [1] is AnimaDiversion
			-- [2] is TravelPortals
			-- [3] is Adventures (aka mission table)
			-- [5] is SanctumUnique (ex: The Queen's Conservatory for Night Fae)

			-- Find the highest known tier
			local highestKnownTier = -1
			
			-- Loop through this tree's talents
			for _, talent in pairs(info.talents) do
				
				-- source : https://wow.gamepedia.com/API_C_Garrison.GetTalentInfo  / Enum.GarrisonTalentAvailability
				-- find the highest known tier
				if talent.talentAvailability == Enum.GarrisonTalentAvailability.UnavailableAlreadyHave and
					talent.tier > highestKnownTier then
					highestKnownTier = talent.tier
				end
			end			

			talents[info.featureType] = highestKnownTier + 1		-- bits 0-3 : tier
										+ bit64:LeftShift(treeID, 4)		-- bits 4+ : tree id
		end
	end
	
	if #talents > 0 then
		sanctum[DataStore.ThisCharID] = talents
	end
end

-- *** Event Handlers ***
local function OnCovenantSanctumInteractionStarted(event, interactionType)
	if interactionType == Enum.PlayerInteractionType.CovenantSanctum then
		ScanReservoirTalents()
	end
end


DataStore:OnAddonLoaded(addonName, function() 
	DataStore:RegisterTables({
		addon = addon,
		characterIdTables = {
			["DataStore_Garrisons_CovenantSanctum"] = {
				GetReservoirTalentTreeInfo = function(characterID, treeType)
					-- treeType = Enum.GarrTalentFeatureType.x
					-- Source : Blizzard_CovenantSanctum/Blizzard_CovenantSanctumUpgrades.lua
					local character = sanctum[characterID]
					if character then 
						
						local info = character[treeType]
						if info then 
							return bit64:GetBits(info, 0, 4), 		-- bits 0-3 : tier
									bit64:RightShift(info, 4)			-- bits 4+ : tree id
						end
					end
					
					return 0, 0
				end,
			},
		}
	})
	
	sanctum = DataStore_Garrisons_CovenantSanctum
end)

DataStore:OnPlayerLogin(function()
	addon:ListenTo("PLAYER_INTERACTION_MANAGER_FRAME_SHOW", OnCovenantSanctumInteractionStarted)
	addon:ListenTo("GARRISON_TALENT_RESEARCH_STARTED", OnCovenantSanctumInteractionStarted)
end)

--[[
	This file keeps track of Cypher Equipment
	Expansion Features / 9.2 - Shadowlands Zereth Mortis
--]]

local addonName, addon = ...
local equipment

local DataStore, pairs, C_Garrison = DataStore, pairs, C_Garrison

local bit64 = LibStub("LibBit64")

-- *** Scanning functions ***
local function ScanCypherEquipment()
	local treeID = C_Garrison.GetCurrentGarrTalentTreeID()
	if not treeID or treeID ~= 474 then return end

	-- Scan the console
	local talents = { 0, 0, 0, 0 }
	local info = C_Garrison.GetTalentTreeInfo(treeID)
	
	-- Loop through the talents (28 => 4 columns, 7 tiers, empty positions on screen are also in here!)
	for talentID, talent in pairs(info.talents) do
		-- talent.tier = talent row on-screen (vertically)
		-- talent.uiOrder = talent column on-screen (horizontally)
		
		-- Empty slots have an icon = 0
		if talent.icon and talent.icon > 0 then
			local index = talent.uiOrder + 1
			talents[index] = talents[index] + talent.talentRank
		end
	end
	
	-- Cypher level
	local currentLevel = C_Garrison.GetCurrentCypherEquipmentLevel()
	local maxLevel = C_Garrison.GetMaxCypherEquipmentLevel()
	
	equipment[DataStore.ThisCharID] = currentLevel 		-- bits 0-3 : current level
		+ bit64:LeftShift(maxLevel, 4)						-- bits 4-7 : max level
		+ bit64:LeftShift(talents[1], 8)						-- bits 8-11 : Metrial Level
		+ bit64:LeftShift(talents[2], 12)					-- bits 12-15 : Aealic Level
		+ bit64:LeftShift(talents[3], 16)					-- bits 16-19 : Dealic Level
		+ bit64:LeftShift(talents[4], 20)					-- bits 20-23 : Trebalim Level
end


-- ** Mixins **
local function GetLevel(characterID, bitNum)
	local info = equipment[characterID]

	return info and bit64:GetBits(info, bitNum, 4) or 0
end

DataStore:OnAddonLoaded(addonName, function() 
	DataStore:RegisterTables({
		addon = addon,
		characterIdTables = {
			["DataStore_Garrisons_CypherEquipment"] = {
				GetCypherLevel = function(characterID) return GetLevel(characterID, 0), GetLevel(characterID, 4) end,
				GetCypherMetrialLevel = function(characterID) return GetLevel(characterID, 8) end,
				GetCypherAealicLevel = function(characterID) return GetLevel(characterID, 12) end,
				GetCypherDealicLevel = function(characterID) return GetLevel(characterID, 16) end,
				GetCypherTrebalimLevel = function(characterID) return GetLevel(characterID, 20) end,
			},
		}
	})
	
	equipment = DataStore_Garrisons_CypherEquipment
end)

DataStore:OnPlayerLogin(function()
	addon:ListenTo("GARRISON_TALENT_NPC_OPENED", ScanCypherEquipment)
	addon:ListenTo("GARRISON_TALENT_COMPLETE", ScanCypherEquipment)
	addon:ListenTo("GARRISON_TALENT_UPDATE", ScanCypherEquipment)
end)

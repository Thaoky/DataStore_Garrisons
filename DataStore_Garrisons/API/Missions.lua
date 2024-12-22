--[[
	This file keeps track of Garrison Missions
--]]

local addonName, addon = ...
local thisCharacter
local allCharacters
local missionInfos

local DataStore, wipe, C_Garrison, TableInsert = DataStore, wipe, C_Garrison, table.insert

local bit64 = LibStub("LibBit64")

-- https://wowpedia.fandom.com/wiki/Enum.GarrisonFollowerType
local followerTypes = {
	[Enum.GarrisonFollowerType.FollowerType_6_0_GarrisonFollower] = 1,
	[Enum.GarrisonFollowerType.FollowerType_7_0_GarrisonFollower] = 2,
	[Enum.GarrisonFollowerType.FollowerType_8_0_GarrisonFollower] = 3,
	[Enum.GarrisonFollowerType.FollowerType_9_0_GarrisonFollower] = 4,
}

-- *** Utility functions ***
local function GetStorageIndex(followerType)
	return followerTypes[followerType]
end

local function ClearInactiveMissionsData()
	-- active missions info is saved separately, and not cleaned automatically during the scan.
	-- so clean it at login ..
	
	local availableMissions = {}
	local activeMissions = {}
	
	-- loop through all characters
	for _, character in pairs(allCharacters) do
		
		-- Check available missions
		if character.Available then
		
			-- get all available missions for 6.0, 7.0, ...
			for _, xPackMissions in pairs(character.Available) do
				for _, missionID in pairs(xPackMissions) do
					availableMissions[missionID] = true
				end
			end	
		end
		
		-- Check active missions
		if character.Active then
		
			-- get all active missions for 6.0, 7.0, ...
			for _, xPackMissions in pairs(character.Active) do
				for _, missionID in pairs(xPackMissions) do
					activeMissions[missionID] = true
				end
			end			
		end		
	
		-- loop through all mission info & start times
		for missionID, _ in pairs(character.Infos) do		
			-- .. then delete its info if it's no longer active
			if not activeMissions[missionID] then
				character.Infos[missionID] = nil
			end
		end
		
		-- Check start times
		if character.StartTimes then
			for missionID, _ in pairs(character.StartTimes) do
				if not activeMissions[missionID] then
					character.StartTimes[missionID] = nil
				end
			end
		end
	end
	
	-- now check the reference, and remove all data that is not linked to missions known by characters (otherwise info keeps stacking up)
	for missionID, _ in pairs(missionInfos.Infos) do
		if not availableMissions[missionID] and not activeMissions[missionID] then
			missionInfos.Infos[missionID] = nil
			missionInfos.Rewards[missionID] = nil
		end
	end
end

local function SetMissionInfo(mission)
	-- save a mission related information into the reference table, since it would be duplicated too often across multiple alts
	local id = mission.missionID
	local typeID = DataStore:StoreToSetAndList(missionInfos.Types, mission.type)
	local typeAtlasID = DataStore:StoreToSetAndList(missionInfos.TypeAtlas, mission.typeAtlas)
	local durationID = DataStore:StoreToSetAndList(missionInfos.Durations, mission.durationSeconds)
	
	missionInfos.Infos[id] = typeID				-- bits 0-5 = mission type index (6 bits)
		+ bit64:LeftShift(typeAtlasID, 6)		-- bits 6-11 = mission type atlas index (6 bits)
		+ bit64:LeftShift(durationID, 12)		-- bits 12-17 = duration index (6 bits)
		+ bit64:LeftShift(mission.cost, 18)		-- bits 18-29 = mission cost (12 bits)
		+ bit64:LeftShift(mission.level, 30)	-- bits 30-35 = mission level (6 bits)
		+ bit64:LeftShift(mission.iLevel, 36)	-- bits 36-45 = mission iLevel (10 bits)
	
	-- rewards no longer valid for alts in 7.x
	missionInfos.Rewards[id] = C_Garrison.GetMissionRewardInfo(id)

	-- other infos, always available
	-- name : C_Garrison.GetMissionName
	-- link : C_Garrison.GetMissionLink
	-- num followers :  C_Garrison.GetMissionMaxFollowers
	
	-- expiration ??
end




-- *** Scanning functions ***
local function ScanAvailableMissions(followerType, index)
	thisCharacter.lastUpdate = time()
	
	local missionsList = {}
	C_Garrison.GetAvailableMissions(missionsList, followerType)
	
	if #missionsList == 0  then
		-- free space if no data
		if thisCharacter.Available then
			thisCharacter.Available[index] = nil
		
			if #thisCharacter.Available == 0 then
				thisCharacter.Available = nil
			end
		end
		
		return
	end
	
	-- allocate space for mission data
	thisCharacter.Available = thisCharacter.Available or {}
	thisCharacter.Available[index] = thisCharacter.Available[index] or {}
	
	local missions = thisCharacter.Available[index]
	wipe(missions)

	for _, mission in pairs(missionsList) do
		SetMissionInfo(mission)
		TableInsert(missions, mission.missionID)
	end
	
end

local function ScanAllAvailableMissions()
	-- Scan available missions for all expansions
	for followerType, index in pairs(followerTypes) do
		ScanAvailableMissions(followerType, index)
	end
	
	-- update the main table
	local char = DataStore:GetCharacterDB("DataStore_Garrisons_Characters")
	char.lastUpdate = time()
end
 
local function ScanActiveMissions(followerType, index)
	thisCharacter.lastUpdate = time()
	
	local missionsList = {}
	C_Garrison.GetInProgressMissions(missionsList, followerType)
	
	if #missionsList == 0  then
		-- free space if no data
		if thisCharacter.Active then
			thisCharacter.Active[index] = nil
			
			if #thisCharacter.Active == 0 then
				thisCharacter.Active = nil
			end
		end
		
		return
	end

	-- allocate space for mission data
	thisCharacter.Active = thisCharacter.Active or {}
	thisCharacter.Active[index] = thisCharacter.Active[index] or {}
	
	local missions = thisCharacter.Active[index]
	wipe(missions)

	local missionsInfo = thisCharacter.Infos
	
	for k, mission in pairs(missionsList) do
		TableInsert(missions, mission.missionID)		-- add mission id to the list of active missions ..
		
		SetMissionInfo(mission)
		
		-- .. then proceed with mission info.
		local info = {}

		if mission.followers then
			info.followers = {}
			for _, followerGUID in pairs(mission.followers) do
				local link = C_Garrison.GetFollowerLink(followerGUID)
				local id = link:match("garrfollower:(%d+)")
				TableInsert(info.followers, tonumber(id))
			end
		end
		
		info.successChance = C_Garrison.GetMissionSuccessChance(mission.missionID)
		
		missionsInfo[mission.missionID] = info
	end
	
end

local function ScanAllActiveMissions()
	-- Scan active missions for all expansions
	for followerType, index in pairs(followerTypes) do
		ScanActiveMissions(followerType, index)
	end
end

local function ScanMissionStartTime(missionID)
	
	-- Save the mission start time separately.
	-- The list of active missions does not provide a duration in seconds (only text) or 
	-- a timestamp for the actual start time of that mission.. so keep track of it manually

	-- Note: the times are kept in a separate table
	--  this ensures that if the events GARRISON_MISSION_STARTED & GARRISON_MISSION_LIST_UPDATE 
	--  are triggered in a different order, the system will not fail.

	if type(missionID) == "number" then
		thisCharacter.StartTimes = thisCharacter.StartTimes or {}
		thisCharacter.StartTimes[missionID] = time()
	end
end

-- *** Event Handlers ***
local function OnGarrisonMissionListUpdate(event, followerType)
	-- 10.0 : guard followerType 
	if followerType and followerTypes[followerType] then
		local index = GetStorageIndex(followerType)
		
		ScanAvailableMissions(followerType, index)
		ScanActiveMissions(followerType, index)
	end
end

local missionNPCType

local function OnGarrisonMissionNPCOpened(event, followerType)
	-- the 'close' event does not know the follower type, so let's track it here ..
	missionNPCType = followerType		
	
	local index = GetStorageIndex(followerType)
	ScanAvailableMissions(followerType, index)
	ScanActiveMissions(followerType, index)
	
	addon:ListenTo("GARRISON_MISSION_LIST_UPDATE", OnGarrisonMissionListUpdate)
end

local function OnGarrisonMissionNPCClosed(event)
	-- use the mission follower type we got from the 'open' event
	if not missionNPCType then return end
	
	local index = GetStorageIndex(missionNPCType)
	ScanAvailableMissions(missionNPCType, index)
	ScanActiveMissions(missionNPCType, index)
	
	-- also, this event is triggered twice due to some bug, so by setting our type to nil, we avoid unnecessary double processing
	missionNPCType = nil
	
	addon:StopListeningTo("GARRISON_MISSION_LIST_UPDATE")
end

local function OnGarrisonUpdate(event)
	ScanAllAvailableMissions()
end

local function OnGarrisonMissionStarted(event, followerType, missionID)
	-- ScanAvailableMissions(LE_FOLLOWER_TYPE_GARRISON_6_0, GARRISON_MISSIONS_STORAGE) not needed, done by the list update
	-- only re-scan in progress
	ScanMissionStartTime(missionID)
end

local function OnGarrisonMissionFinished()
	ScanAvailableMissions(Enum.GarrisonFollowerType.FollowerType_6_0_GarrisonFollower, 1)
end


-- ** Mixins **
local function _GetMissionCost(missionID)
	local info = missionInfos.Infos[missionID]
	local cost = bit64:GetBits(info, 18, 12)		-- bits 18-29 = mission cost (12 bits)

	return cost
end

local function _GetMissionLevel(missionID)
	local info = missionInfos.Infos[missionID]
	local level = bit64:GetBits(info, 30, 6)		-- bits 30-35 = mission level (6 bits)
	local iLevel = bit64:GetBits(info, 36, 10)	-- bits 36-45 = mission iLevel (10 bits)

	return level, iLevel
end

local function _GetMissionAtlas(missionID)
	local info = missionInfos.Infos[missionID]
	local id = bit64:GetBits(info, 6, 6)		-- bits 6-11 = mission type atlas index (6 bits)

	return missionInfos.TypeAtlas.List[id]
end

local function _GetMissionDuration(missionID)
	local info = missionInfos.Infos[missionID]
	local id = bit64:GetBits(info, 12, 6)		-- bits 12-17 = duration index (6 bits)

	return missionInfos.Durations.List[id]
end

local function _GetMissionRewards(missionID)
	return missionInfos.Rewards[missionID]
end

local function _GetAvailableMissions(character, followerType)
	return character.Available and character.Available[GetStorageIndex(followerType)]
end

local function _GetNumAvailableMissions(character, followerType) 
	local missions = _GetAvailableMissions(character, followerType)
	return missions and #missions or 0
end

local function _GetActiveMissions(character, followerType)
	return character.Active and character.Active[GetStorageIndex(followerType)]
end

local function _GetNumActiveMissions(character, followerType)
	local missions = _GetActiveMissions(character, followerType)
	return missions and #missions or 0
end

local function _GetActiveMissionInfo(character, id)
	if not character.Infos then return end
	
	local mission = character.Infos[id]
	if not mission then return end
	
	local startTime = character.StartTimes and character.StartTimes[id]
	local remainingTime
	
	if startTime then
		remainingTime = _GetMissionDuration(id) - (time() - startTime)
		remainingTime = (remainingTime > 0) and remainingTime or 0
	end
	
	return mission.followers, remainingTime, mission.successChance
end

local function _GetNumCompletedMissions(character, followerType)
	if not character.Active then return 0 end
	
	local count = 0
	
	local missions = _GetActiveMissions(character, followerType)
	if missions then
		for _, id in pairs(missions) do
			local _, remainingTime = _GetActiveMissionInfo(character, id)
			
			if remainingTime and remainingTime == 0 then
				count = count + 1
			end
		end
	end
	
	return count
end

local function _GetMissionInfo(missionID)
	return missionInfos[missionID]
	
end


AddonFactory:OnAddonLoaded(addonName, function() 
	DataStore:RegisterTables({
		addon = addon,
		rawTables = {
			"DataStore_Garrisons_MissionInfos"
		},
		characterTables = {
			["DataStore_Garrisons_Missions"] = {
				GetAvailableMissions = _GetAvailableMissions,
				GetNumAvailableMissions = _GetNumAvailableMissions,
				GetActiveMissions = _GetActiveMissions,
				GetNumActiveMissions = _GetNumActiveMissions,
				GetMissionTableLastVisit = function(character) return character.lastUpdate or 0 end,
				GetActiveMissionInfo = _GetActiveMissionInfo,
				GetNumCompletedMissions = _GetNumCompletedMissions,
			},
		}
	})
	
	-- This table contains the mission infos that are character specific
	thisCharacter = DataStore:GetCharacterDB("DataStore_Garrisons_Missions", true)
	thisCharacter.Infos = thisCharacter.Infos or {}
	
	allCharacters = DataStore_Garrisons_Missions
	
	-- This table contains the mission infos that are shared across all characters
	missionInfos = DataStore_Garrisons_MissionInfos
	missionInfos.Infos = missionInfos.Infos or {}
	missionInfos.Rewards = missionInfos.Rewards or {}
	
	missionInfos.Types = missionInfos.Types or {}
	missionInfos.TypeAtlas = missionInfos.TypeAtlas or {}
	missionInfos.Durations = missionInfos.Durations or {}
	
	DataStore:CreateSetAndList(missionInfos.Types)
	DataStore:CreateSetAndList(missionInfos.TypeAtlas)
	DataStore:CreateSetAndList(missionInfos.Durations)
	
	DataStore:RegisterMethod(addon, "GetMissionCost", _GetMissionCost)
	DataStore:RegisterMethod(addon, "GetMissionLevel", _GetMissionLevel)
	DataStore:RegisterMethod(addon, "GetMissionAtlas", _GetMissionAtlas)
	DataStore:RegisterMethod(addon, "GetMissionDuration", _GetMissionDuration)
	DataStore:RegisterMethod(addon, "GetMissionRewards", _GetMissionRewards)

end)

AddonFactory:OnPlayerLogin(function()
	C_Timer.After(3, function()
			-- To avoid the long list of GARRISON_MISSION_LIST_UPDATE at startup, make the initial scan 3 seconds later ..
			ScanAllAvailableMissions()
			ScanAllActiveMissions()

			-- .. then register the event
			-- note, at logon, GARRISON_UPDATE is fired before MISSION_LIST_UPDATE
			-- addon:ListenTo("GARRISON_MISSION_LIST_UPDATE", OnGarrisonMissionListUpdate)
			-- addon:ListenTo("GARRISON_UPDATE", OnGarrisonUpdate)
		end)
	
	addon:ListenTo("GARRISON_MISSION_NPC_OPENED", OnGarrisonMissionNPCOpened)
	addon:ListenTo("GARRISON_MISSION_NPC_CLOSED", OnGarrisonMissionNPCClosed)
	addon:ListenTo("GARRISON_MISSION_STARTED", OnGarrisonMissionStarted)
	addon:ListenTo("GARRISON_MISSION_FINISHED", OnGarrisonMissionFinished)
	addon:ListenTo("GARRISON_UPDATE", OnGarrisonUpdate)
	
	-- ClearInactiveMissionsData()
end)

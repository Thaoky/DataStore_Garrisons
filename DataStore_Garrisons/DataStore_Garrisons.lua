--[[	*** DataStore_Garrisons ***
Written by : Thaoky, EU-Marécages de Zangar
November 30th, 2014
--]]
if not DataStore then return end

local addonName = "DataStore_Garrisons"

_G[addonName] = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")

local addon = _G[addonName]

local GARRISON_MISSIONS_STORAGE = "AvailableMissions"
local GARRISON_ACTIVE_MISSIONS_STORAGE = "ActiveMissions"
local ORDERHALL_MISSIONS_STORAGE = "AvailableOrderHallMissions"
local ORDERHALL_ACTIVE_MISSIONS_STORAGE = "ActiveOrderHallMissions"
local WARCAMPAIGN_MISSIONS_STORAGE = "AvailableWarCampaignMissions"
local WARCAMPAIGN_ACTIVE_MISSIONS_STORAGE = "ActiveWarCampaignMissions"
local COVENANT_MISSIONS_STORAGE = "AvailableCovenantMissions"
local COVENANT_ACTIVE_MISSIONS_STORAGE = "ActiveCovenantMissions"
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

local AddonDB_Defaults = {
	global = {
		Reference = {
			FollowerNamesToID = {},			-- ex: ["Nat Pagle"] = 202 ... necessary because the id's do not remain constant in game, and the full list varies per character.
			MissionInfos = {},
		},
		Options = {
			ReportUncollected = true,			-- Report uncollected resources
			ReportLevel = 400,
		},
		Characters = {
			['*'] = {				-- ["Account.Realm.Name"] 
				lastUpdate = nil,
				lastResourceCollection = nil,
				numFollowers = 0,
				numFollowersAtLevel40 = 0,
				numFollowersAtiLevel615 = 0,
				numFollowersAtiLevel630 = 0,
				numFollowersAtiLevel645 = 0,
				numFollowersAtiLevel660 = 0,
				numFollowersAtiLevel675 = 0,
 				numRareFollowers = 0,
 				numEpicFollowers = 0,
				avgWeaponiLevel = 0,
				avgArmoriLevel = 0,
				
				Buildings = {},				-- List of buildings
				Followers = {},				-- List of followers
				[GARRISON_MISSIONS_STORAGE] = {},					-- List of available missions (6.0)
				[GARRISON_ACTIVE_MISSIONS_STORAGE] = {},			-- List of active/in-progress missions (6.0)
				[ORDERHALL_MISSIONS_STORAGE] = {},					-- List of available order hall missions (7.0)
				[ORDERHALL_ACTIVE_MISSIONS_STORAGE] = {},			-- List of active/in-progress order hall missions (7.0)
				[WARCAMPAIGN_MISSIONS_STORAGE] = {},				-- List of available war campaign missions (8.0)
				[WARCAMPAIGN_ACTIVE_MISSIONS_STORAGE] = {},		-- List of active/in-progress war campaign missions (8.0)
				[COVENANT_MISSIONS_STORAGE] = {},				-- List of available war campaign missions (8.0)
				[COVENANT_ACTIVE_MISSIONS_STORAGE] = {},
				MissionsStartTimes = {},		-- List of start times for active/in-progress missions
				MissionsInfo = {},				-- Extra information about active/in-progress missions (ex: success rate, active followers..)
				
				artifactResearchCreationTime = 0,
				artifactResearchDuration = 0,
				artifactResearchNumReady = 0,
				artifactResearchNumTotal = 0,
				
				-- ** Expansion Features / 9.0 - Shadowlands **
				ReservoirTalents = {},		-- Info about the talent trees of the sanctum reservoir
				
				-- ** Expansion Features / 9.2 - Shadowlands Zereth Mortis**
				currentCypherEquipmentLevel = 0,
				maxCypherEquipmentLevel = 0,
				CypherConsoleTalents = { 0, 0, 0, 0 },
			}
		}
	}
}

--[[
The API does not return information about the building type, even less in a localization & faction independent way, so match
the building id's with an internal string.
--]]

local BUILDING_ALCHEMY = "AlchemyLab"
local BUILDING_BARN = "Barn"
local BUILDING_BARRACKS = "Barracks"
local BUILDING_DWARVEN_BUNKER = "DwarvenBunker"
local BUILDING_ENCHANTERS_STUDY = "EnchantersStudy"
local BUILDING_ENGINEERING_WORKS = "EngineeringWorks"
local BUILDING_FISHING_SHACK = "FishingShack"
local BUILDING_GEM_BOUTIQUE = "GemBoutique"
local BUILDING_GLADIATORS_SANCTUM = "GladiatorsSanctum"
local BUILDING_GNOMISH_GEARWORKS = "GnomishGearworks"
local BUILDING_HERB_GARDEN = "HerbGarden"
local BUILDING_LUMBER_MILL = "LumberMill"
local BUILDING_LUNARFALL_EXCAVATION = "LunarfallExcavation"
local BUILDING_LUNARFALL_INN = "LunarfallInn"
local BUILDING_MAGE_TOWER = "MageTower"
local BUILDING_MENAGERIE = "Menagerie"
local BUILDING_SALVAGE_YARD = "SalvageYard"
local BUILDING_SCRIBES_QUARTERS = "ScribesQuarters"
local BUILDING_STABLES = "Stables"
local BUILDING_STOREHOUSE = "Storehouse"
local BUILDING_TAILORING_EMPORIUM = "TailoringEmporium"
local BUILDING_THE_FORGE = "TheForge"
local BUILDING_THE_TANNERY = "TheTannery"
local BUILDING_TRADING_POST = "TradingPost"

local BUILDING_TOWN_HALL = "TownHall"

local buildingTypes = {
	[76] = BUILDING_ALCHEMY,
	[119] = BUILDING_ALCHEMY,
	[120] = BUILDING_ALCHEMY,
	[24] = BUILDING_BARN,
	[25] = BUILDING_BARN,
	[133] = BUILDING_BARN,
	[26] = BUILDING_BARRACKS,
	[27] = BUILDING_BARRACKS,
	[28] = BUILDING_BARRACKS,
	[8] = BUILDING_DWARVEN_BUNKER,
	[9] = BUILDING_DWARVEN_BUNKER,
	[10] = BUILDING_DWARVEN_BUNKER,
	[93] = BUILDING_ENCHANTERS_STUDY,
	[125] = BUILDING_ENCHANTERS_STUDY,
	[126] = BUILDING_ENCHANTERS_STUDY,
	[91] = BUILDING_ENGINEERING_WORKS,
	[123] = BUILDING_ENGINEERING_WORKS,
	[124] = BUILDING_ENGINEERING_WORKS,
	[64] = BUILDING_FISHING_SHACK,
	[134] = BUILDING_FISHING_SHACK,
	[135] = BUILDING_FISHING_SHACK,
	[96] = BUILDING_GEM_BOUTIQUE,
	[131] = BUILDING_GEM_BOUTIQUE,
	[132] = BUILDING_GEM_BOUTIQUE,
	[159] = BUILDING_GLADIATORS_SANCTUM,
	[160] = BUILDING_GLADIATORS_SANCTUM,
	[161] = BUILDING_GLADIATORS_SANCTUM,
	[162] = BUILDING_GNOMISH_GEARWORKS,
	[163] = BUILDING_GNOMISH_GEARWORKS,
	[164] = BUILDING_GNOMISH_GEARWORKS,
	[29] = BUILDING_HERB_GARDEN,
	[136] = BUILDING_HERB_GARDEN,
	[137] = BUILDING_HERB_GARDEN,
	[40] = BUILDING_LUMBER_MILL,
	[41] = BUILDING_LUMBER_MILL,
	[138] = BUILDING_LUMBER_MILL,
	[61] = BUILDING_LUNARFALL_EXCAVATION,
	[62] = BUILDING_LUNARFALL_EXCAVATION,
	[63] = BUILDING_LUNARFALL_EXCAVATION,
	[34] = BUILDING_LUNARFALL_INN,
	[35] = BUILDING_LUNARFALL_INN,
	[36] = BUILDING_LUNARFALL_INN,
	[37] = BUILDING_MAGE_TOWER,
	[38] = BUILDING_MAGE_TOWER,
	[39] = BUILDING_MAGE_TOWER,
	[42] = BUILDING_MENAGERIE,
	[167] = BUILDING_MENAGERIE,
	[168] = BUILDING_MENAGERIE,
	[52] = BUILDING_SALVAGE_YARD,
	[140] = BUILDING_SALVAGE_YARD,
	[141] = BUILDING_SALVAGE_YARD,
	[95] = BUILDING_SCRIBES_QUARTERS,
	[129] = BUILDING_SCRIBES_QUARTERS,
	[130] = BUILDING_SCRIBES_QUARTERS,
	[65] = BUILDING_STABLES,
	[66] = BUILDING_STABLES,
	[67] = BUILDING_STABLES,
	[51] = BUILDING_STOREHOUSE,
	[142] = BUILDING_STOREHOUSE,
	[143] = BUILDING_STOREHOUSE,
	[94] = BUILDING_TAILORING_EMPORIUM,
	[127] = BUILDING_TAILORING_EMPORIUM,
	[128] = BUILDING_TAILORING_EMPORIUM,
	[60] = BUILDING_THE_FORGE,
	[117] = BUILDING_THE_FORGE,
	[118] = BUILDING_THE_FORGE,
	[90] = BUILDING_THE_TANNERY,
	[121] = BUILDING_THE_TANNERY,
	[122] = BUILDING_THE_TANNERY,
	[111] = BUILDING_TRADING_POST,
	[144] = BUILDING_TRADING_POST,
	[145] = BUILDING_TRADING_POST,
}

-- https://wowpedia.fandom.com/wiki/Enum.GarrisonFollowerType
local availableMissionsStorage = {
	[Enum.GarrisonFollowerType.FollowerType_6_0_GarrisonFollower] = GARRISON_MISSIONS_STORAGE,
	[Enum.GarrisonFollowerType.FollowerType_7_0_GarrisonFollower] = ORDERHALL_MISSIONS_STORAGE,
	[Enum.GarrisonFollowerType.FollowerType_8_0_GarrisonFollower] = WARCAMPAIGN_MISSIONS_STORAGE,
	[Enum.GarrisonFollowerType.FollowerType_9_0_GarrisonFollower] = COVENANT_MISSIONS_STORAGE,
}

local activeMissionsStorage = {
	[Enum.GarrisonFollowerType.FollowerType_6_0_GarrisonFollower] = GARRISON_ACTIVE_MISSIONS_STORAGE,
	[Enum.GarrisonFollowerType.FollowerType_7_0_GarrisonFollower] = ORDERHALL_ACTIVE_MISSIONS_STORAGE,
	[Enum.GarrisonFollowerType.FollowerType_8_0_GarrisonFollower] = WARCAMPAIGN_ACTIVE_MISSIONS_STORAGE,
	[Enum.GarrisonFollowerType.FollowerType_9_0_GarrisonFollower] = COVENANT_ACTIVE_MISSIONS_STORAGE,
}

-- *** Utility functions ***
local function GetOption(option)
	return addon.db.global.Options[option]
end

local function GetNumUncollectedResources(from)
	-- no known collection time (alt never logged in) .. return 0
	if not from then return 0 end
	
	local age = time() - from
	local resources = math.floor(age / 600)		-- 10 minutes = 1 resource
	
	-- cap at 500
	if resources > 500 then
		resources = 500
	end
	return resources
end

local function CheckUncollectedResources()
	local account, realm, name
	local num
	local reportLevel = GetOption("ReportLevel")
	
	for key, character in pairs(addon.db.global.Characters) do
		account, realm, name = strsplit(".", key)
		num = GetNumUncollectedResources(character.lastResourceCollection)
		if name and num >= reportLevel then
			addon:Print(format(L["UNCOLLECTED_RESOURCES_ALERT"], name, num))
		end
	end
end

local function ClearInactiveMissionsData()
	-- active missions info is saved separately, and not cleaned automatically during the scan.
	-- so clean it at login ..
	
	local availableMissions = {}
	local activeMissions = {}
	
	-- loop through all characters
	for key, character in pairs(addon.db.global.Characters) do
		
		-- get all available missions for 6.0, 7.0, ...
		for _, storage in pairs(availableMissionsStorage) do
			for _, missionID in pairs(character[storage]) do
				availableMissions[missionID] = true
			end
		end

		-- get all active missions for 6.0, 7.0, ...
		for _, storage in pairs(activeMissionsStorage) do
			for _, missionID in pairs(character[storage]) do
				activeMissions[missionID] = true
			end
		end
	
		-- loop through all mission info & start times
		for missionID, _ in pairs(character.MissionsInfo) do		
			-- .. then delete its info if it's no longer active
			if not activeMissions[missionID] then
				character.MissionsInfo[missionID] = nil
			end
		end
		
		for missionID, _ in pairs(character.MissionsStartTimes) do
			if not activeMissions[missionID] then
				character.MissionsStartTimes[missionID] = nil				
			end
		end
	end
	
	-- now check the reference, and remove all data that is not linked to missions known by characters (otherwise info keeps stacking up)
	local ref = addon.db.global.Reference.MissionInfos
	
	for missionID, missionData in pairs(ref) do
		if not availableMissions[missionID] and not activeMissions[missionID] then
			ref[missionID] = nil
		end
	end
end

local function SetMissionInfo(mission)
	-- save a mission related information into the reference table, since it would be duplicated too often across multiple alts
	local ref = addon.db.global.Reference
	local missionID = mission.missionID
	
	ref.MissionInfos[missionID] = {
		["cost"] = mission.cost,
		["durationSeconds"] = mission.durationSeconds,
		["level"] = mission.level,
		["iLevel"] = mission.iLevel,
		["type"] = mission.type,
		["typeAtlas"] = mission.typeAtlas,
		
		-- rewards no longer valid for alts in 7.x
		["rewards"] = C_Garrison.GetMissionRewardInfo(missionID)
	}

	-- other infos, always available
	-- name : C_Garrison.GetMissionName
	-- link : C_Garrison.GetMissionLink
	-- num followers :  C_Garrison.GetMissionMaxFollowers
	
	-- expiration ??
end


-- *** Scanning functions ***
local function ScanBuildings()
	local plots = C_Garrison.GetPlots(Enum.GarrisonFollowerType.FollowerType_6_0_GarrisonFollower)

	-- to avoid deleting previously saved data when the game is not ready to deliver information
	-- exit if no data is available
	if not plots or #plots == 0 then return end

	local buildings = addon.ThisCharacter.Buildings
	wipe(buildings)
	
	-- Scan Town Hall
	local level = C_Garrison.GetGarrisonInfo(Enum.GarrisonFollowerType.FollowerType_6_0_GarrisonFollower)
	
	buildings[BUILDING_TOWN_HALL] = { id = 0, rank = level }
	
	local ref = addon.db.global.Reference
	
	-- Scan other buildings
	for i = 1, #plots do
		local plot = plots[i]
		
		-- local id, name, texPrefix, icon, rank, isBuilding, timeStart, buildTime, canActivate, canUpgrade, isPrebuilt = C_Garrison.GetOwnedBuildingInfoAbbrev(plot.id);
		local id, _, _, _, rank = C_Garrison.GetOwnedBuildingInfoAbbrev(plot.id)
		if id then
			local info = {}
			
			info.id = id
			info.rank = rank

			buildings[buildingTypes[id]] = info
		end
	end
end
	
local function ScanFollowers()
	local followersList = C_Garrison.GetFollowers(Enum.GarrisonFollowerType.FollowerType_6_0_GarrisonFollower)
	if not followersList then return end

	local followers = addon.ThisCharacter.Followers
	--wipe(followers) no need to wipe, followers don't get 'uncollected', and they are in a hash table, not an array
	-- also used for order hall followers
	
	-- = C_Garrison.GetFollowerNameByID(id)
	
	local ref = addon.db.global.Reference
	local name		-- follower name
	local link		-- follower link
	local id			-- follower id
	local rarity, level, iLevel, ability1, ability2, ability3, ability4, trait1, trait2, trait3, trait4
	
	local numFollowers = 0		-- number of followers
	local numActive = 0			-- number of active followers
	local num40 = 0				-- number of followers at level 40
	local num615 = 0				-- number of followers at iLevel 615+
	local num630 = 0				-- number of followers at iLevel 630+
	local num645 = 0				-- number of followers at iLevel 645+
	local num660 = 0				-- number of followers at iLevel 660+
	local num675 = 0				-- number of followers at iLevel 675
	local numRare = 0				-- number of rare followers (blue)
	local numEpic = 0				-- number of epic followers (violet)
	local weaponiLvl = 0			-- used to compute average weapon iLevel
	local armoriLvl = 0			-- used to compute average armor iLevel
	
	local abilities = {}
	local traits = {}
	local counters = {}
	
	local function IncTableIndex(tableName, index)
		if not tableName[index] then
			tableName[index] = 0
		end
		tableName[index] = tableName[index] + 1		
	end
	
	local function IncAbility(id)
		if id and id ~= 0 then
			IncTableIndex(abilities, id)
		end
	end
	
	local function IncTrait(id)
		if id and id ~= 0 then
			IncTableIndex(traits, id)
		end
	end
	
	local function IncCounter(id)
		if id and id ~= 0 then
			IncTableIndex(counters, C_Garrison.GetFollowerAbilityCounterMechanicInfo(id))
		end
	end

	local isInactive		-- is a follower inactive or not ?
	
	for k, follower in pairs(followersList) do
		name = follower.name
		id = follower.followerID		-- by default, the id should be this one (numeric)
		
		isInactive = nil
		if type(follower.followerID) == "string" then	-- if the type is string, it's a GUID
			local status = C_Garrison.GetFollowerStatus(follower.followerID)
			if status and status == GARRISON_FOLLOWER_INACTIVE then
				isInactive = true
			end
		end
		
		if follower.isCollected then
			-- if the follower is collected, the id will be a GUID (string)
			-- therefore, it has to be extracted from the link
			-- also, the link is only valid for collected followers, otherwise it is nil
			link = C_Garrison.GetFollowerLink(follower.followerID)
			id, rarity, level, iLevel, ability1, ability2, ability3, ability4, trait1, trait2, trait3, trait4 = link:match("garrfollower:(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+)")
			id = tonumber(id)
			
			local weaponItemID, weaponItemLevel, armorItemID, armorItemLevel = C_Garrison.GetFollowerItems(follower.followerID)
			local info = {}
			
			info.xp = follower.xp
			info.levelXP = follower.levelXP
			info.link = link
			info.isInactive = isInactive
			-- followers[name] = info
			followers[id] = info
			
			-- Stats
			numFollowers = numFollowers + 1
			rarity = tonumber(rarity)
			level = tonumber(level)
			iLevel = tonumber(iLevel)
			
			if level == 40 then 
				num40 = num40 + 1 
				
				if not isInactive then
					numActive = numActive + 1
					weaponiLvl = weaponiLvl + weaponItemLevel
					armoriLvl = armoriLvl + armorItemLevel
				end
			end
			
			if iLevel >= 615 then num615 = num615 + 1	end
			if iLevel >= 630 then num630 = num630 + 1	end
			if iLevel >= 645 then num645 = num645 + 1	end
			if iLevel >= 660 then num660 = num660 + 1	end
			if iLevel >= 675 then num675 = num675 + 1	end
			if rarity == 3 then numRare = numRare + 1 end
			if rarity == 4 then numEpic = numEpic + 1	end
			
			-- abilities & counters
			ability1 = tonumber(ability1)
			ability2 = tonumber(ability2)
			ability3 = tonumber(ability3)
			ability4 = tonumber(ability4)
			trait1 = tonumber(trait1)
			trait2 = tonumber(trait2)
			trait3 = tonumber(trait3)
			trait4 = tonumber(trait4)
			
			IncAbility(ability1)
			IncAbility(ability2)
			IncAbility(ability3)
			IncAbility(ability4)
			IncTrait(trait1)
			IncTrait(trait2)
			IncTrait(trait3)
			IncTrait(trait4)
			IncCounter(ability1)
			IncCounter(ability2)
			IncCounter(ability3)
			IncCounter(ability4)
		end
		
		ref.FollowerNamesToID[name] = id	-- ["Nat Pagle"] = 202
	end
	
	local c = addon.ThisCharacter
	
	c.numFollowers = numFollowers
	c.numFollowersAtLevel40 = num40
	c.numFollowersAtiLevel615 = num615
	c.numFollowersAtiLevel630 = num630
	c.numFollowersAtiLevel645 = num645
	c.numFollowersAtiLevel660 = num660
	c.numFollowersAtiLevel675 = num675
	c.avgWeaponiLevel = (numActive ~= 0) and (weaponiLvl / numActive) or 0
	c.avgArmoriLevel = (numActive ~= 0) and (armoriLvl / numActive) or 0
	c.numRareFollowers = numRare
	c.numEpicFollowers = numEpic
	c.Abilities = abilities
	c.Traits = traits
	c.AbilityCounters = counters
	
	addon.ThisCharacter.lastUpdate = time()
	
	addon:SendMessage("DATASTORE_GARRISON_FOLLOWERS_UPDATED")
end

local function ScanOrderHallFollowers()
	local followersList = C_Garrison.GetFollowers(Enum.GarrisonFollowerType.FollowerType_7_0_GarrisonFollower)
	if not followersList then return end

	local followers = addon.ThisCharacter.Followers
	--wipe(followers) no need to wipe, followers don't get 'uncollected', and they are in a hash table, not an array
	-- also used for garrison followers
	
	-- = C_Garrison.GetFollowerNameByID(id)
	
	local ref = addon.db.global.Reference

	local link		-- follower link
	local id			-- follower id
	local isInactive		-- is a follower inactive or not ?
	
	for k, follower in pairs(followersList) do
		id = follower.followerID		-- by default, the id should be this one (numeric)
		
		isInactive = nil
		if type(follower.followerID) == "string" then	-- if the type is string, it's a GUID
			local status = C_Garrison.GetFollowerStatus(follower.followerID)
			if status and status == GARRISON_FOLLOWER_INACTIVE then
				isInactive = true
			end
		end
		
		-- if follower.isCollected and not follower.isTroop then
		if follower.isCollected then
			-- if the follower is collected, the id will be a GUID (string)
			-- therefore, it has to be extracted from the link
			-- also, the link is only valid for collected followers, otherwise it is nil
			link = C_Garrison.GetFollowerLink(follower.followerID)
			id = link:match("garrfollower:(%d+)")
			id = tonumber(id)
			
			local info = {}
			
			info.xp = follower.xp
			info.levelXP = follower.levelXP
			info.link = link
			info.isInactive = isInactive
			followers[id] = info
		end
		
		ref.FollowerNamesToID[follower.name] = id	-- ["Nat Pagle"] = 202
	end
end

local function ScanResourceCollectionTime()
	addon.ThisCharacter.lastResourceCollection = time()
end

local function ScanAvailableMissions(followerType, storage)
	local missionsList = {}
	C_Garrison.GetAvailableMissions(missionsList, followerType)
	
	local missions = addon.ThisCharacter[storage]		-- ex: addon.ThisCharacter.AvailableMissions
	wipe(missions)

	for k, mission in pairs(missionsList) do
		SetMissionInfo(mission)
		table.insert(missions, mission.missionID)
	end
	
	addon.ThisCharacter.lastUpdate = time()
end

local function ScanAllAvailableMissions()
	-- small helper to scan available missions for all expansions
	for followerType, storage in pairs(availableMissionsStorage) do
		ScanAvailableMissions(followerType, storage)
	end
end
 
local function ScanActiveMissions(followerType)
	local missionsList = {}
	C_Garrison.GetInProgressMissions(missionsList, followerType)
	
	local missions = addon.ThisCharacter[activeMissionsStorage[followerType]]		-- ex: addon.ThisCharacter.ActiveMissions
	wipe(missions)

	local missionsInfo = addon.ThisCharacter.MissionsInfo
	
	for k, mission in pairs(missionsList) do
		table.insert(missions, mission.missionID)		-- add mission id to the list of active missions ..
		
		-- .. then proceed with mission info.
		local info = {}
		SetMissionInfo(mission)

		if mission.followers then
			info.followers = {}
			for _, followerGUID in pairs(mission.followers) do
				local link = C_Garrison.GetFollowerLink(followerGUID)
				local id = link:match("garrfollower:(%d+)")
				table.insert(info.followers, tonumber(id))
			end
		end
		
		info.successChance = C_Garrison.GetMissionSuccessChance(mission.missionID)
		
		missionsInfo[mission.missionID] = info
	end
	
	addon.ThisCharacter.lastUpdate = time()
end

local function ScanAllActiveMissions()
	-- small helper to scan active missions for all expansions
	for followerType, storage in pairs(activeMissionsStorage) do
		ScanActiveMissions(followerType)
	end
end

local function ScanMissionStartTime(missionID)
	if type(missionID) ~= "number" then return end
	
	-- Save the mission start time separately.
	-- The list of active missions does not provide a duration in seconds (only text) or 
	-- a timestamp for the actual start time of that mission.. so keep track of it manually

	-- Note: the times are kept in a separate table
	--  this ensures that if the events GARRISON_MISSION_STARTED & GARRISON_MISSION_LIST_UPDATE 
	--  are triggered in a different order, the system will not fail.
	
	local startTimes = addon.ThisCharacter.MissionsStartTimes
	startTimes[missionID] = time()
end

local function ScanNextArtifactResearch()
	-- scan the remaining time until the next artifact research notes are complete
	
	local shipments = C_Garrison.GetLooseShipments(Enum.GarrisonType.Type_7_0_Garrison)
	local char = addon.ThisCharacter

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

local function ScanReservoirTalents()

	if not C_CovenantSanctumUI.CanAccessReservoir() then return end

	local talents = addon.ThisCharacter.ReservoirTalents
	wipe(talents)	
	
	-- 
	
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
				if talent.talentAvailability == Enum.GarrisonTalentAvailability.UnavailableAlreadyHave and talent.tier > highestKnownTier then
					highestKnownTier = talent.tier
				end
			end			
			
			talents[info.featureType] = { treeID = treeID, tier = highestKnownTier + 1 } 			
		end
	end
end

local function ScanCypherLevel()
	addon.ThisCharacter.currentCypherEquipmentLevel = C_Garrison.GetCurrentCypherEquipmentLevel()
	addon.ThisCharacter.maxCypherEquipmentLevel = C_Garrison.GetMaxCypherEquipmentLevel()
end

local function ScanCypherConsoleTalents()
	local treeID = C_Garrison.GetCurrentGarrTalentTreeID()
	if not treeID or treeID ~= 474 then return end
	
	local talents = addon.ThisCharacter.CypherConsoleTalents
	talents[1] = 0
	talents[2] = 0
	talents[3] = 0
	talents[4] = 0
	
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
end

-- *** Event Handlers ***
local function OnShipmentsUpdated()
	ScanNextArtifactResearch()
end

local function OnFollowerAdded()
	ScanFollowers()
	ScanOrderHallFollowers()
end

local function OnFollowerListUpdate()
	ScanFollowers()
	ScanOrderHallFollowers()
end

local function OnFollowerRemoved()
	ScanFollowers()
	ScanOrderHallFollowers()
end

local function OnGarrisonBuildingActivated()
	ScanBuildings()
end

local function OnGarrisonBuildingUpdate()
	ScanBuildings()
end

local function OnGarrisonBuildingRemoved()
	ScanBuildings()
end

local function OnShowLootToast(event, lootType, link, quantity, specID, sex, isPersonal, lootSource)
	if lootType ~= "currency" then return end
	
	-- From AlertFrames.lua
	-- local LOOT_SOURCE_GARRISON_CACHE = 10
	
	-- make sure it is garrison resources
	if link and link:match("currency:824") and lootSource == 10 then	
		ScanResourceCollectionTime()
	end
end

local function OnGarrisonMissionListUpdate(event, followerType)
	-- 10.0 : guard followerType 
	if followerType and availableMissionsStorage[followerType] then
		ScanAvailableMissions(followerType, availableMissionsStorage[followerType])
		ScanActiveMissions(followerType)
	end
end

local missionNPCType

local function OnGarrisonMissionNPCOpened(event, followerType)
	-- the 'close' event does not know the follower type, so let's track it here ..
	missionNPCType = followerType		
	
	ScanAvailableMissions(missionNPCType, availableMissionsStorage[missionNPCType])
	ScanActiveMissions(missionNPCType)
	ScanOrderHallFollowers()
	
	addon:RegisterEvent("GARRISON_MISSION_LIST_UPDATE", OnGarrisonMissionListUpdate)
end

local function OnGarrisonMissionNPCClosed(event)
	-- use the mission follower type we got from the 'open' event
	if missionNPCType then
		ScanAvailableMissions(missionNPCType, availableMissionsStorage[missionNPCType])
		ScanActiveMissions(missionNPCType)
		
		-- also, this event is triggered twice due to some bug, so by setting our type to nil, we avoid unnecessary double processing
		missionNPCType = nil
		
		addon:UnregisterEvent("GARRISON_MISSION_LIST_UPDATE")
	end
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
	ScanAvailableMissions(Enum.GarrisonFollowerType.FollowerType_6_0_GarrisonFollower, GARRISON_MISSIONS_STORAGE)
end

local function OnAddonLoaded(event, addonName)
	if addonName == "Blizzard_GarrisonUI" then
		ScanBuildings()
		-- ScanFollowers()	-- Seems this scan can cause the values to be zeroed out.
	end
end

local function OnCovenantSanctumInteractionStarted(event, interactionType)
	if interactionType == Enum.PlayerInteractionType.CovenantSanctum then
		ScanReservoirTalents()
	end
end

local function OnGarrisonTalentNPCOpened()
	ScanCypherLevel()
	ScanCypherConsoleTalents()
end

local function OnGarrisonTalentComplete()
	ScanCypherLevel()
	ScanCypherConsoleTalents()
end

local function OnGarrisonTalentUpdate()
	ScanCypherLevel()
	ScanCypherConsoleTalents()
end


-- ** Mixins **
local function _GetFollowers(character)
	return character.Followers
end

local function _GetFollowerInfo(character, id)
	local follower = character.Followers[id]
	if not follower then return end
	
	local link = follower.link
	if not link then return end

	-- ability id's are positions 5 to 8 in the follower link
	-- trait id's are positions 9 to 12 in the follower link
	local _, rarity, level, iLevel, ab1, ab2, ab3, ab4, tr1, tr2, tr3, tr4 = link:match("garrfollower:(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+)")

	return tonumber(rarity), tonumber(level), tonumber(iLevel), 
		tonumber(ab1), tonumber(ab2), tonumber(ab3), tonumber(ab4),
		tonumber(tr1), tonumber(tr2), tonumber(tr3), tonumber(tr4),
		follower.xp, follower.levelXP
end

local function _GetFollowerSpellCounters(character, counterType, id)
	-- "counters" as in "to count", not as in "to counter"
	-- counterType = "Abilities", "Traits", "AbilityCounters"
	
	if type(character[counterType]) == "table" then 
		return character[counterType][id] or 0
	end
	return 0
end

local function _GetFollowerLink(character, id)
	local follower = character.Followers[id]
	if not follower then return end
	
	return follower.link
end

local function _GetFollowerID(name)
	return addon.db.global.Reference.FollowerNamesToID[name]
end

local function _GetNumFollowers(character)
	return character.numFollowers or 0
end

local function _GetNumFollowersAtLevel40(character)
	return character.numFollowersAtLevel40 or 0
end

local function _GetNumFollowersAtiLevel615(character)
	return character.numFollowersAtiLevel615 or 0
end

local function _GetNumFollowersAtiLevel630(character)
	return character.numFollowersAtiLevel630 or 0
end

local function _GetNumFollowersAtiLevel645(character)
	return character.numFollowersAtiLevel645 or 0
end

local function _GetNumFollowersAtiLevel660(character)
	return character.numFollowersAtiLevel660 or 0
end

local function _GetNumFollowersAtiLevel675(character)
	return character.numFollowersAtiLevel675 or 0
end

local function _GetNumRareFollowers(character)
	return character.numRareFollowers or 0
end

local function _GetNumEpicFollowers(character)
	return character.numEpicFollowers or 0
end

local function _GetAvgWeaponiLevel(character)
	return character.avgWeaponiLevel or 0
end

local function _GetAvgArmoriLevel(character)
	return character.avgArmoriLevel or 0
end

local function _GetBuildingInfo(character, name)
	local building = character.Buildings[name]
	if not building then return end
	
	return building.id, building.rank
end

local function _GetUncollectedResources(character)
	return GetNumUncollectedResources(character.lastResourceCollection)
end

local function _GetAvailableMissions(character, followerType)
	return character[availableMissionsStorage[followerType]]
end

local function _GetNumAvailableMissions(character, followerType)
	return #character[availableMissionsStorage[followerType]]
end

local function _GetActiveMissions(character, followerType)
	return character[activeMissionsStorage[followerType]]
end

local function _GetActiveMissionInfo(character, id)
	local mission = character.MissionsInfo[id]
	if not mission then return end
	
	local startTime = character.MissionsStartTimes[id]
	local remainingTime
	
	if startTime then
		local missionRef = addon.db.global.Reference.MissionInfos[id]
		remainingTime = missionRef.durationSeconds - (time() - startTime)
		remainingTime = (remainingTime > 0) and remainingTime or 0
	end
	
	return mission.followers, remainingTime, mission.successChance
end

local function _GetNumActiveMissions(character, followerType)
	return #character[activeMissionsStorage[followerType]]
end

local function _GetNumCompletedMissions(character, followerType)
	local count = 0
	
	local missions = character[activeMissionsStorage[followerType]]
	
	for _, id in pairs(missions) do
		local _, remainingTime = _GetActiveMissionInfo(character, id)
		if remainingTime and remainingTime == 0 then
			count = count + 1
		end
	end
	
	return count
end

local function _GetMissionInfo(missionID)
	return addon.db.global.Reference.MissionInfos[missionID]
end

local function _GetMissionTableLastVisit(character)
	return character.lastUpdate or 0
end

local function _GetLastResourceCollectionTime(character)
	return character.lastResourceCollection or 0
end

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

local function _GetReservoirTalentTreeInfo(character, treeType)
	-- treeType = Enum.GarrTalentFeatureType.x
	-- Source : Blizzard_CovenantSanctum/Blizzard_CovenantSanctumUpgrades.lua
	
	-- return the information table of this tree type 
	return character.ReservoirTalents[treeType]
end

local function _GetCypherLevel(character)
	return character.currentCypherEquipmentLevel, character.maxCypherEquipmentLevel
end

local function _GetCypherMetrialLevel(character)
	return character.CypherConsoleTalents[1]
end

local function _GetCypherAealicLevel(character)
	return character.CypherConsoleTalents[2]
end

local function _GetCypherDealicLevel(character)
	return character.CypherConsoleTalents[3]
end

local function _GetCypherTrebalimLevel(character)
	return character.CypherConsoleTalents[4]
end


local PublicMethods = {
	GetFollowers = _GetFollowers,
	GetFollowerInfo = _GetFollowerInfo,
	GetFollowerSpellCounters = _GetFollowerSpellCounters,
	GetFollowerLink = _GetFollowerLink,
	GetFollowerID = _GetFollowerID,
	GetNumFollowers = _GetNumFollowers,
	GetNumFollowersAtLevel40 = _GetNumFollowersAtLevel40,
	GetNumFollowersAtiLevel615 = _GetNumFollowersAtiLevel615,
	GetNumFollowersAtiLevel630 = _GetNumFollowersAtiLevel630,
	GetNumFollowersAtiLevel645 = _GetNumFollowersAtiLevel645,
	GetNumFollowersAtiLevel660 = _GetNumFollowersAtiLevel660,
	GetNumFollowersAtiLevel675 = _GetNumFollowersAtiLevel675,
 	GetNumRareFollowers = _GetNumRareFollowers,
 	GetNumEpicFollowers = _GetNumEpicFollowers,
	GetAvgWeaponiLevel = _GetAvgWeaponiLevel,
	GetAvgArmoriLevel = _GetAvgArmoriLevel,
	GetBuildingInfo = _GetBuildingInfo,
	GetUncollectedResources = _GetUncollectedResources,
	GetAvailableMissions = _GetAvailableMissions,
	GetNumAvailableMissions = _GetNumAvailableMissions,
	GetActiveMissions = _GetActiveMissions,
	GetActiveMissionInfo = _GetActiveMissionInfo,
	GetNumActiveMissions = _GetNumActiveMissions,
	GetNumCompletedMissions = _GetNumCompletedMissions,
	GetMissionInfo = _GetMissionInfo,
	GetMissionTableLastVisit = _GetMissionTableLastVisit,
	GetLastResourceCollectionTime = _GetLastResourceCollectionTime,
	GetArtifactResearchInfo = _GetArtifactResearchInfo,
	GetReservoirTalentTreeInfo = _GetReservoirTalentTreeInfo,
	GetCypherLevel = _GetCypherLevel,
	GetCypherMetrialLevel = _GetCypherMetrialLevel,
	GetCypherAealicLevel = _GetCypherAealicLevel,
	GetCypherDealicLevel = _GetCypherDealicLevel,
	GetCypherTrebalimLevel = _GetCypherTrebalimLevel,
}

function addon:OnInitialize()
	addon.db = LibStub("AceDB-3.0"):New(addonName .. "DB", AddonDB_Defaults)

	DataStore:RegisterModule(addonName, addon, PublicMethods)
	DataStore:SetCharacterBasedMethod("GetFollowers")
	DataStore:SetCharacterBasedMethod("GetFollowerInfo")
	DataStore:SetCharacterBasedMethod("GetFollowerSpellCounters")
	DataStore:SetCharacterBasedMethod("GetFollowerLink")
	DataStore:SetCharacterBasedMethod("GetNumFollowers")
	DataStore:SetCharacterBasedMethod("GetNumFollowersAtLevel40")
	DataStore:SetCharacterBasedMethod("GetNumFollowersAtiLevel615")
	DataStore:SetCharacterBasedMethod("GetNumFollowersAtiLevel630")
	DataStore:SetCharacterBasedMethod("GetNumFollowersAtiLevel645")
	DataStore:SetCharacterBasedMethod("GetNumFollowersAtiLevel660")
	DataStore:SetCharacterBasedMethod("GetNumFollowersAtiLevel675")
 	DataStore:SetCharacterBasedMethod("GetNumRareFollowers")
 	DataStore:SetCharacterBasedMethod("GetNumEpicFollowers")
	DataStore:SetCharacterBasedMethod("GetAvgWeaponiLevel")
	DataStore:SetCharacterBasedMethod("GetAvgArmoriLevel")
	DataStore:SetCharacterBasedMethod("GetBuildingInfo")
	DataStore:SetCharacterBasedMethod("GetUncollectedResources")
	DataStore:SetCharacterBasedMethod("GetAvailableMissions")
	DataStore:SetCharacterBasedMethod("GetNumAvailableMissions")
	DataStore:SetCharacterBasedMethod("GetActiveMissions")
	DataStore:SetCharacterBasedMethod("GetActiveMissionInfo")
	DataStore:SetCharacterBasedMethod("GetNumActiveMissions")
	DataStore:SetCharacterBasedMethod("GetNumCompletedMissions")
	DataStore:SetCharacterBasedMethod("GetMissionTableLastVisit")
	DataStore:SetCharacterBasedMethod("GetLastResourceCollectionTime")
	DataStore:SetCharacterBasedMethod("GetArtifactResearchInfo")
	DataStore:SetCharacterBasedMethod("GetReservoirTalentTreeInfo")
	DataStore:SetCharacterBasedMethod("GetCypherLevel")
	DataStore:SetCharacterBasedMethod("GetCypherMetrialLevel")
	DataStore:SetCharacterBasedMethod("GetCypherAealicLevel")
	DataStore:SetCharacterBasedMethod("GetCypherDealicLevel")
	DataStore:SetCharacterBasedMethod("GetCypherTrebalimLevel")
end

function addon:OnEnable()
	-- Shipments
	addon:RegisterEvent("GARRISON_LANDINGPAGE_SHIPMENTS", OnShipmentsUpdated)
	
	-- Followers
	addon:RegisterEvent("GARRISON_FOLLOWER_ADDED", OnFollowerAdded)
	addon:RegisterEvent("GARRISON_FOLLOWER_LIST_UPDATE", OnFollowerListUpdate)
	addon:RegisterEvent("GARRISON_FOLLOWER_REMOVED", OnFollowerRemoved)
	addon:RegisterEvent("ADDON_LOADED", OnAddonLoaded)
	
	-- Buildings
	addon:RegisterEvent("GARRISON_BUILDING_ACTIVATED", OnGarrisonBuildingActivated)
	addon:RegisterEvent("GARRISON_BUILDING_UPDATE", OnGarrisonBuildingUpdate)
	addon:RegisterEvent("GARRISON_BUILDING_REMOVED", OnGarrisonBuildingRemoved)
	addon:RegisterEvent("SHOW_LOOT_TOAST", OnShowLootToast)
	
	-- Missions
	addon:ScheduleTimer(function()
			-- To avoid the long list of GARRISON_MISSION_LIST_UPDATE at startup, make the initial scan 3 seconds later ..
			ScanAllAvailableMissions()
			ScanAllActiveMissions()

			-- .. then register the event
			-- note, at logon, GARRISON_UPDATE is fired before MISSION_LIST_UPDATE
			-- addon:RegisterEvent("GARRISON_MISSION_LIST_UPDATE", OnGarrisonMissionListUpdate)
			-- addon:RegisterEvent("GARRISON_UPDATE", OnGarrisonUpdate)
		end, 3)	
	
	addon:RegisterEvent("GARRISON_MISSION_NPC_OPENED", OnGarrisonMissionNPCOpened)
	addon:RegisterEvent("GARRISON_MISSION_NPC_CLOSED", OnGarrisonMissionNPCClosed)
	addon:RegisterEvent("GARRISON_MISSION_STARTED", OnGarrisonMissionStarted)
	addon:RegisterEvent("GARRISON_MISSION_FINISHED", OnGarrisonMissionFinished)
	addon:RegisterEvent("GARRISON_UPDATE", OnGarrisonUpdate)
	
	-- 9.0 Sanctum Reservoir
	addon:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW", OnCovenantSanctumInteractionStarted)
	addon:RegisterEvent("GARRISON_TALENT_RESEARCH_STARTED", OnCovenantSanctumInteractionStarted)
	
	-- 9.2 Cypher Equipment
	addon:RegisterEvent("GARRISON_TALENT_NPC_OPENED", OnGarrisonTalentNPCOpened)
	addon:RegisterEvent("GARRISON_TALENT_COMPLETE", OnGarrisonTalentComplete)
	addon:RegisterEvent("GARRISON_TALENT_UPDATE", OnGarrisonTalentUpdate)
	

	addon:SetupOptions()
	if GetOption("ReportUncollected") then
		CheckUncollectedResources()
	end
	
	ClearInactiveMissionsData()
end

function addon:OnDisable()
	addon:UnregisterEvent("PLAYER_ALIVE")
	addon:UnregisterEvent("GARRISON_FOLLOWER_ADDED")
	addon:UnregisterEvent("GARRISON_FOLLOWER_LIST_UPDATE")
	addon:UnregisterEvent("GARRISON_FOLLOWER_REMOVED")
	addon:UnregisterEvent("GARRISON_BUILDING_ACTIVATED")
	addon:UnregisterEvent("GARRISON_BUILDING_UPDATE")
	addon:UnregisterEvent("GARRISON_BUILDING_REMOVED")
	addon:UnregisterEvent("SHOW_LOOT_TOAST")
	addon:UnregisterEvent("GARRISON_MISSION_LIST_UPDATE")
	addon:UnregisterEvent("GARRISON_MISSION_STARTED")
	addon:UnregisterEvent("GARRISON_MISSION_FINISHED")
	addon:UnregisterEvent("LOADING_SCREEN_ENABLED")
	addon:UnregisterEvent("GARRISON_UPDATE")
	addon:UnregisterEvent("ADDON_LOADED")
	addon:UnregisterEvent("COVENANT_SANCTUM_INTERACTION_STARTED")
	addon:UnregisterEvent("GARRISON_TALENT_RESEARCH_STARTED")
end

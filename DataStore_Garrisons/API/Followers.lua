--[[
	This file keeps track of Garrison Followers
--]]

local addonName, addon = ...
local thisCharacter
local followerNamesToID

local DataStore, wipe, C_Garrison = DataStore, wipe, C_Garrison

local bit64 = LibStub("LibBit64")

-- *** Utility functions ***
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
	id = tonumber(id)
	
	if id and id ~= 0 then
		IncTableIndex(abilities, id)
		IncTableIndex(counters, C_Garrison.GetFollowerAbilityCounterMechanicInfo(id))
	end
end

local function IncTrait(id)
	id = tonumber(id)
	
	if id and id ~= 0 then
		IncTableIndex(traits, id)
	end
end


-- *** Scanning functions ***
local function ScanFollowers()
	local followersList = C_Garrison.GetFollowers(Enum.GarrisonFollowerType.FollowerType_6_0_GarrisonFollower)
	if not followersList then return end

	local followers = thisCharacter.Followers
	local links = thisCharacter.FollowerLinks

	--wipe(followers) no need to wipe, followers don't get 'uncollected', and they are in a hash table, not an array
	-- also used for order hall followers
	
	-- = C_Garrison.GetFollowerNameByID(id)

	local name, link, id, isInactive
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

			followers[id] = isInactive and 1 or 0			-- bit 0 : isInactive
				+ bit64:LeftShift(follower.levelXP, 1)		-- bits 1-20 = xp to next level (20 bits)
				+ bit64:LeftShift(follower.xp, 21)			-- bits 21-40 = xp in current level (20 bits)
				
			links[id] = link
			
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
			IncAbility(ability1)
			IncAbility(ability2)
			IncAbility(ability3)
			IncAbility(ability4)
			IncTrait(trait1)
			IncTrait(trait2)
			IncTrait(trait3)
			IncTrait(trait4)
		end
		
		followerNamesToID[name] = id	-- ["Nat Pagle"] = 202
	end
	
	thisCharacter.Infos = numFollowers		-- bits 0-7 =  (8 bits)
		+ bit64:LeftShift(numRare, 8)			-- bits 8-15 =  (8 bits)
		+ bit64:LeftShift(numEpic, 16)		-- bits 16-23 =  (8 bits)
		+ bit64:LeftShift((numActive ~= 0) and math.floor(weaponiLvl / numActive) or 0, 24)	-- bits 24-33 = average weapon iLevel (10 bits)
		+ bit64:LeftShift((numActive ~= 0) and math.floor(armoriLvl / numActive) or 0, 34)	-- bits 34-43 = average armor iLevel (10 bits)
	
	thisCharacter.LevelCount = num40		-- bits 0-7 (8 bits)
		+ bit64:LeftShift(num615, 8)		-- bits 8-15 (8 bits)
		+ bit64:LeftShift(num630, 16)		-- bits 16-23 (8 bits)
		+ bit64:LeftShift(num645, 24)		-- bits 24-31 (8 bits)
		+ bit64:LeftShift(num660, 32)		-- bits 32-39 (8 bits)
		+ bit64:LeftShift(num675, 40)		-- bits 40-47 (8 bits)

	thisCharacter.Abilities = abilities
	thisCharacter.Traits = traits
	thisCharacter.AbilityCounters = counters
	thisCharacter.lastUpdate = time()
	
	AddonFactory:Broadcast("DATASTORE_GARRISON_FOLLOWERS_UPDATED")
	
	wipe(abilities)
	wipe(traits)
	wipe(counters)
end

local function ScanOrderHallFollowers()
	local followersList = C_Garrison.GetFollowers(Enum.GarrisonFollowerType.FollowerType_7_0_GarrisonFollower)
	if not followersList then return end

	local followers = thisCharacter.Followers
	local links = thisCharacter.FollowerLinks
	--wipe(followers) no need to wipe, followers don't get 'uncollected', and they are in a hash table, not an array
	-- also used for garrison followers
	
	-- = C_Garrison.GetFollowerNameByID(id)
	
	local link, id, isInactive
	
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
			
			followers[id] = isInactive and 1 or 0			-- bit 0 : isInactive
				+ bit64:LeftShift(follower.levelXP, 1)		-- bits 1-20 = xp to next level (20 bits)
				+ bit64:LeftShift(follower.xp, 21)			-- bits 21-40 = xp in current level (20 bits)
			
			links[id] = link
		end
		
		followerNamesToID[follower.name] = id	-- ["Nat Pagle"] = 202
	end
end


-- *** Event Handlers ***
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

local function OnGarrisonMissionNPCOpened(event, followerType)
	ScanOrderHallFollowers()
end

-- ** Mixins **
local function _GetFollowers(character)
	return character.Followers
end

local function _GetFollowerInfo(character, id)
	local follower = character.Followers[id]
	if not follower then return end
	
	local link = character.FollowerLinks[id]
	if not link then return end

	-- ability id's are positions 5 to 8 in the follower link
	-- trait id's are positions 9 to 12 in the follower link
	local _, rarity, level, iLevel, ab1, ab2, ab3, ab4, tr1, tr2, tr3, tr4 = link:match("garrfollower:(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+)")

	local levelXP = bit64:GetBits(follower, 1, 20)
	local xp = bit64:GetBits(follower, 21, 20)

	return tonumber(rarity), tonumber(level), tonumber(iLevel), 
		tonumber(ab1), tonumber(ab2), tonumber(ab3), tonumber(ab4),
		tonumber(tr1), tonumber(tr2), tonumber(tr3), tonumber(tr4),
		xp, levelXP
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
	return character.FollowerLinks[id]
end

local function GetInfo(character, from, length)
	return character.Infos
		and bit64:GetBits(character.Infos, from, length)
		or 0
end

local function GetCount(character, from, length)
	return character.LevelCount
		and bit64:GetBits(character.LevelCount, from, length)
		or 0
end


AddonFactory:OnAddonLoaded(addonName, function() 
	DataStore:RegisterTables({
		addon = addon,
		rawTables = {
			"DataStore_Garrisons_FollowerNamesToID"
		},
		characterTables = {
			["DataStore_Garrisons_Followers"] = {
				GetFollowers = _GetFollowers,
				GetFollowerInfo = _GetFollowerInfo,
				GetFollowerLink = _GetFollowerLink,
				GetFollowerSpellCounters = _GetFollowerSpellCounters,
			
				GetNumFollowers = function(character) return GetInfo(character, 0, 8) end,
				GetNumRareFollowers = function(character) return GetInfo(character, 8, 8) end,
				GetNumEpicFollowers = function(character) return GetInfo(character, 16, 8) end,
				GetAvgWeaponiLevel = function(character) return GetInfo(character, 24, 10) end,
				GetAvgArmoriLevel = function(character) return GetInfo(character, 34, 10) end,
				
				GetNumFollowersAtLevel40 = function(character) return GetCount(character, 0, 8) end,
				GetNumFollowersAtiLevel615 = function(character) return GetCount(character, 8, 8) end,
				GetNumFollowersAtiLevel630 = function(character) return GetCount(character, 16, 8) end,
				GetNumFollowersAtiLevel645 = function(character) return GetCount(character, 24, 8) end,
				GetNumFollowersAtiLevel660 = function(character) return GetCount(character, 32, 8) end,
				GetNumFollowersAtiLevel675 = function(character) return GetCount(character, 40, 8) end,
				
			},
		}
	})
	
	-- This table contains the follower infos that are character specific
	thisCharacter = DataStore:GetCharacterDB("DataStore_Garrisons_Followers", true)
	thisCharacter.Followers = thisCharacter.Followers or {}
	thisCharacter.FollowerLinks = thisCharacter.FollowerLinks or {}
	thisCharacter.Traits = thisCharacter.Traits or {}
	thisCharacter.Abilities = thisCharacter.Abilities or {}
	thisCharacter.AbilityCounters = thisCharacter.AbilityCounters or {}
	
	-- This table contains the mission infos that are shared across all characters
	followerNamesToID = DataStore_Garrisons_FollowerNamesToID
				
	DataStore:RegisterMethod(addon, "GetFollowerID", function(name) return followerNamesToID[name] end)
end)

AddonFactory:OnPlayerLogin(function()
	addon:ListenTo("GARRISON_FOLLOWER_ADDED", OnFollowerAdded)
	addon:ListenTo("GARRISON_FOLLOWER_LIST_UPDATE", OnFollowerListUpdate)
	addon:ListenTo("GARRISON_FOLLOWER_REMOVED", OnFollowerRemoved)
	addon:ListenTo("GARRISON_MISSION_NPC_OPENED", OnGarrisonMissionNPCOpened)
end)

local monsterName = "The Rest Of Ratha"
local mType = Game.createMonsterType(monsterName)
local monster = {}

monster.description = monsterName
monster.experience = 0
monster.outfit = {
	lookType = 1692,
	lookHead = 0,
	lookBody = 0,
	lookLegs = 0,
	lookFeet = 0,
	lookAddons = 0,
	lookMount = 0,
}

monster.events = {}

monster.health = 10000
monster.maxHealth = 10000
monster.race = "undead"
monster.corpse = 0
monster.speed = 125
monster.manaCost = 0

monster.changeTarget = {
	interval = 0,
	chance = 0,
}

monster.strategiesTarget = {
	nearest = 0,
	random = 0,
}

monster.flags = {
	canTarget = false,
	summonable = false,
	attackable = true,
	hostile = false,
	convinceable = false,
	pushable = false,
	rewardBoss = false,
	illusionable = false,
	canPushItems = false,
	canPushCreatures = false,
	staticAttackChance = 0,
	targetDistance = 0,
	runHealth = 0,
	healthHidden = false,
	isBlockable = false,
	canWalkOnEnergy = true,
	canWalkOnFire = true,
	canWalkOnPoison = true,
}

monster.light = {
	level = 0,
	color = 0,
}

monster.summon = {}
monster.voices = {}
monster.loot = {}
monster.attacks = {}

monster.defenses = {
	{ name = "combat", type = COMBAT_HEALING, chance = 100, interval = 2000, minDamage = 10000, maxDamage = 10000, effect = CONST_ME_NONE },
}

monster.elements = {
	{ type = COMBAT_PHYSICALDAMAGE, percent = 100 },
	{ type = COMBAT_ENERGYDAMAGE, percent = 100 },
	{ type = COMBAT_EARTHDAMAGE, percent = 100 },
	{ type = COMBAT_FIREDAMAGE, percent = 100 },
	{ type = COMBAT_LIFEDRAIN, percent = 100 },
	{ type = COMBAT_MANADRAIN, percent = 100 },
	{ type = COMBAT_DROWNDAMAGE, percent = 100 },
	{ type = COMBAT_ICEDAMAGE, percent = 100 },
	{ type = COMBAT_HOLYDAMAGE, percent = 100 },
	{ type = COMBAT_DEATHDAMAGE, percent = 100 },
}

monster.immunities = {
	{ type = "paralyze", condition = true },
	{ type = "outfit", condition = true },
	{ type = "invisible", condition = true },
	{ type = "bleed", condition = true },
}

local effectSent = true

local RATHA_ROOM_STATE_STORAGE = 985001
local ROOM_STATE_FREE = 0
local ROOM_STATE_MISSION = 1
local ROOM_STATE_BOSS = 2

-- Teleporte do boss
local TELEPORT_INTERVAL_MS = 4000
local TELEPORT_CHANCE_PERCENT = 35
local HARP_BLOCK_MS = 2500

local RATHA_TELEPORT_POSITIONS = {
	Position(33382, 31440, 15),
	Position(33384, 31442, 15),
	Position(33386, 31444, 15),
	Position(33388, 31446, 15),
	Position(33390, 31448, 15),
	Position(33392, 31450, 15),
	Position(33394, 31445, 15),
	Position(33396, 31443, 15),
}

-- controle em memória
local teleportState = {}

local function getRathaRoomState()
	local value = Game.getStorageValue(RATHA_ROOM_STATE_STORAGE)
	if value == nil or value < 0 then
		return ROOM_STATE_FREE
	end
	return value
end

local function getState(monsterId)
	if not teleportState[monsterId] then
		teleportState[monsterId] = {
			blockUntil = 0,
		}
	end
	return teleportState[monsterId]
end

function _G.blockRathaTeleport(monsterId)
	local state = getState(monsterId)
	state.blockUntil = os.clock() * 1000 + HARP_BLOCK_MS
end

local function removeGhostItem(position)
	local tile = Tile(position)
	if not tile then
		return
	end

	local ghostItem = tile:getItemById(TwentyYearsACookQuest.TheRestOfRatha.Items.GhostItem)
	if ghostItem then
		ghostItem:remove()
	end
end

local function createGhostItem(rathaPosition)
	local tile = Tile(rathaPosition)
	if tile and not tile:getItemById(TwentyYearsACookQuest.TheRestOfRatha.Items.GhostItem) then
		effectSent = false
		Game.createItem(TwentyYearsACookQuest.TheRestOfRatha.Items.GhostItem, 1, rathaPosition)
		addEvent(removeGhostItem, 6 * 1000, rathaPosition)
	end
end

local function shuffledTeleportPositions()
	local positions = {}
	for i = 1, #RATHA_TELEPORT_POSITIONS do
		positions[i] = RATHA_TELEPORT_POSITIONS[i]
	end

	for i = #positions, 2, -1 do
		local j = math.random(i)
		positions[i], positions[j] = positions[j], positions[i]
	end
	return positions
end

local function isFreeTeleportTile(monster, pos)
	if not pos then
		return false
	end

	if not TwentyYearsACookQuest.TheRestOfRatha.BossZone:isInZone(pos) then
		return false
	end

	local tile = Tile(pos)
	if not tile then
		return false
	end

	if tile:hasProperty(CONST_PROP_IMMOVABLEBLOCKSOLID) then
		return false
	end

	-- evita teleportar exatamente para onde já está
	local currentPos = monster:getPosition()
	if currentPos.x == pos.x and currentPos.y == pos.y and currentPos.z == pos.z then
		return false
	end

	-- evita player no sqm
	local spectators = Game.getSpectators(pos, false, true, 0, 0, 0, 0)
	if spectators and #spectators > 0 then
		return false
	end

	return true
end

local function doBossTeleport(monster)
	local fromPos = monster:getPosition()

	for _, pos in ipairs(shuffledTeleportPositions()) do
		if isFreeTeleportTile(monster, pos) then
			fromPos:sendMagicEffect(CONST_ME_GHOST_SMOKE)
			monster:teleportTo(pos)
			pos:sendMagicEffect(CONST_ME_GHOST_SMOKE)
			return true
		end
	end

	return false
end

local function teleportLoop(monsterId)
	local monster = Monster(monsterId)
	if not monster then
		teleportState[monsterId] = nil
		return
	end

	local pos = monster:getPosition()
	if not pos or not TwentyYearsACookQuest.TheRestOfRatha.BossZone:isInZone(pos) then
		addEvent(teleportLoop, TELEPORT_INTERVAL_MS, monsterId)
		return
	end

	local state = getState(monsterId)
	local nowMs = os.clock() * 1000

	if getRathaRoomState() == ROOM_STATE_BOSS and state.blockUntil <= nowMs then
		local appliedCondition = monster:getCondition(CONDITION_PARALYZE)
		local conditionsTicks = appliedCondition and appliedCondition:getTicks() or 0

		if conditionsTicks <= 0 then
			if math.random(100) <= TELEPORT_CHANCE_PERCENT then
				doBossTeleport(monster)
			end
		end
	end

	addEvent(teleportLoop, TELEPORT_INTERVAL_MS, monsterId)
end

local function onConditionClear(ratha)
	effectSent = true

	local rathaPosition = ratha:getPosition()
	if ratha:getStorageValue(Storage.Quest.U13_30.TwentyYearsACook.RathaConditionsApplied) >= 2 then
		if not doBossTeleport(ratha) then
			rathaPosition:sendMagicEffect(CONST_ME_MORTAREA)
		end
	else
		rathaPosition:sendMagicEffect(CONST_ME_MORTAREA)
	end
end

local function onConditionApplied(ratha, conditionsTicks)
	local rathaPosition = ratha:getPosition()
	if conditionsTicks % 2000 == 0 then
		rathaPosition:sendMagicEffect(CONST_ME_BLACK_BLOOD)
	end
	createGhostItem(rathaPosition)
end

local function updateQuestLogOnRathaFound(rathaPosition)
	for _, player in pairs(Game.getSpectators(rathaPosition, false, true, 1, 1, 1, 1)) do
		local playerStorage = player:getStorageValue(Storage.Quest.U13_30.TwentyYearsACook.QuestLine)
		if playerStorage == 2 then
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You have found the friend of the Draccoon or what's left of him, You should tell the Draccoon about it!")
			player:setStorageValue(Storage.Quest.U13_30.TwentyYearsACook.QuestLine, 3)
		end
	end
end

mType.onSpawn = function(monster, spawnPosition)
	getState(monster:getId())
	addEvent(teleportLoop, TELEPORT_INTERVAL_MS, monster:getId())
end

mType.onDisappear = function(monster, creature)
	if monster then
		teleportState[monster:getId()] = nil
	end
end

mType.onThink = function(monster, interval)
	local monsterPosition = monster and monster:getPosition() or nil
	if not monsterPosition then
		return
	end

	if TwentyYearsACookQuest.TheRestOfRatha.MissionZone:isInZone(monsterPosition) then
		updateQuestLogOnRathaFound(monsterPosition)
	elseif TwentyYearsACookQuest.TheRestOfRatha.BossZone:isInZone(monsterPosition) then
		local appliedCondition = monster:getCondition(CONDITION_PARALYZE)
		local conditionsTicks = appliedCondition and appliedCondition:getTicks() or 0
		if conditionsTicks > 0 then
			onConditionApplied(monster, conditionsTicks)
		elseif not effectSent then
			onConditionClear(monster)
		end
	end
end

mType:register(monster)

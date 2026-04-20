local FLASK_SOURCE_ID = 9168
local FLASK_SOURCE_POSITION = Position(33398, 31453, 15)

local function clearRathaRoom()
	TwentyYearsACookQuest.TheRestOfRatha.MissionZone:removeMonsters()
	TwentyYearsACookQuest.TheRestOfRatha.BossZone:removeMonsters()

	local tile = Tile(FLASK_SOURCE_POSITION)
	if tile then
		local item = tile:getItemById(FLASK_SOURCE_ID)
		if item then
			item:remove()
		end
	end
end

local positions = {
	["33117,31672,7"] = {
		{ toPosition = Position(33327, 31481, 15), storageValue = 10 },
	},
	["32367,31596,7"] = {
		{ toPosition = Position(32299, 31698, 8), storageValue = 8 },
	},
	["32301,31697,8"] = {
		{ toPosition = Position(32368, 31598, 7), storageValue = 8, boss = "Fryclops" },
	},
	["32297,31706,8"] = {
		{ toPosition = Position(32246, 31834, 7), storageValue = 8 },
	},
	["32246,31832,7"] = {
		{ toPosition = Position(32298, 31704, 8), storageValue = 8 },
	},
	["32591,31936,5"] = {
		{ toPosition = Position(32587, 31937, 5), storageValue = 4, boss = "The Rest Of Ratha" },
		{ toPosition = Position(33392, 31452, 15), storageValue = 2 },
	},
	["32974,32110,7"] = {
		{ toPosition = Position(32974, 32087, 8), storageValue = 1 },
	},
	["32973,32089,8"] = {
		{ toPosition = Position(32975, 32112, 7), storageValue = 1 },
	},
}

local function posToStr(pos)
	return pos.x .. "," .. pos.y .. "," .. pos.z
end

local function sortRulesByPriority(rules)
	table.sort(rules, function(a, b)
		return a.storageValue > b.storageValue
	end)
end

for _, rules in pairs(positions) do
	sortRulesByPriority(rules)
end

local RATHA_ROOM_STATE_STORAGE = 985001
local ROOM_STATE_FREE = 0
local ROOM_STATE_MISSION = 1
local ROOM_STATE_BOSS = 2

local function getRathaRoomState()
	local value = Game.getStorageValue(RATHA_ROOM_STATE_STORAGE)
	if value == nil or value < 0 then
		return ROOM_STATE_FREE
	end
	return value
end

local function setRathaRoomState(state)
	Game.setStorageValue(RATHA_ROOM_STATE_STORAGE, state)
end

local function getRathaRoomPlayers()
	return TwentyYearsACookQuest.TheRestOfRatha.BossZone:countPlayers()
end

local function refreshRathaRoomState()
	if getRathaRoomPlayers() == 0 then
		setRathaRoomState(ROOM_STATE_FREE)
		return ROOM_STATE_FREE
	end
	return getRathaRoomState()
end

local function hasRathaInRoom()
	local spectators = Game.getSpectators(Position(33392, 31452, 15), false, false, 16, 6, 16, 2)
	for _, creature in ipairs(spectators) do
		if creature:isMonster() and creature:getName():lower() == "the rest of ratha" then
			return true
		end
	end
	return false
end

local function spawnMissionRatha()
	if hasRathaInRoom() then
		return true
	end

	local monster = Game.createMonster("The Rest Of Ratha", Position(33382, 31440, 15), true, true)
	return monster ~= nil
end

local omniousTrashCan = MoveEvent()

function omniousTrashCan.onStepIn(creature, item, position, fromPosition)
	local player = creature:getPlayer()
	if not player then
		return false
	end

	local playerStorage = tonumber(player:getStorageValue(Storage.Quest.U13_30.TwentyYearsACook.QuestLine)) or -1
	local currentPos = posToStr(player:getPosition())
	local rules = positions[currentPos]

	if not rules then
		return true
	end

	local hasBossCooldown = false

	for _, data in ipairs(rules) do
		if playerStorage >= data.storageValue then
			if data.boss then
				local cooldown = player:getBossCooldown(data.boss)
				if cooldown and cooldown > os.time() then
					hasBossCooldown = true
					break
				end
			end

			-- Entrada da missão do Ratha
			if currentPos == "32591,31936,5" and data.storageValue == 2 then
				local roomState = refreshRathaRoomState()

				if roomState == ROOM_STATE_BOSS then
					player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Someone is already fighting inside.")
					player:getPosition():sendMagicEffect(CONST_ME_POFF)
					player:teleportTo(fromPosition, true)
					fromPosition:sendMagicEffect(CONST_ME_POFF)
					return true
				end

				-- Só limpa se a sala estiver livre
				if roomState == ROOM_STATE_FREE then
					clearRathaRoom()
					setRathaRoomState(ROOM_STATE_MISSION)
				end
				-- Se já estiver em missão, não limpa nada
			end

			fromPosition:sendMagicEffect(CONST_ME_POFF)
			player:teleportTo(data.toPosition, true)
			player:getPosition():sendMagicEffect(CONST_ME_POFF)

			if currentPos == "32591,31936,5" and data.storageValue == 2 then
				if not spawnMissionRatha() then
					player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The strange presence could not be awakened.")
				end
			end

			return true
		end
	end

	player:sendTextMessage(
		MESSAGE_EVENT_ADVANCE,
		hasBossCooldown and "You need to wait to challenge again." or "You are not ready for this yet"
	)

	player:getPosition():sendMagicEffect(CONST_ME_POFF)
	player:teleportTo(fromPosition, true)
	fromPosition:sendMagicEffect(CONST_ME_POFF)
	return true
end

for key, _ in pairs(positions) do
	local x, y, z = key:match("(%d+),(%d+),(%d+)")
	omniousTrashCan:position(Position(tonumber(x), tonumber(y), tonumber(z)))
end

omniousTrashCan:type("stepin")
omniousTrashCan:register()

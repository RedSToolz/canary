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

local function createFlaskSource()
	local position = Position(33398, 31453, 15)
	local tile = Tile(position)

	if not tile then
		Game.createTile(position)
	end

	tile = Tile(position)
	if tile and not tile:getItemById(9168) then
		local item = Game.createItem(9168, 1, position)
		if item then
			item:setActionId(62136)
		end
	end
end

local config = {
	boss = {
		name = "The Rest Of Ratha",
		position = Position(33382, 31440, 15),
		createFunction = function()
			setRathaRoomState(ROOM_STATE_BOSS)

			createFlaskSource()

			local monster = Game.createMonster("The Rest Of Ratha", Position(33382, 31440, 15), true, true)
			if not monster then
				setRathaRoomState(ROOM_STATE_FREE)
				return false
			end

			monster:registerEvent("BossLeverOnDeath")
			return true
		end,
	},
	timeToDefeat = TwentyYearsACookQuest.TheRestOfRatha.TimeToDefeat,
	requiredLevel = 1,
	playerPositions = {
		{ pos = Position(32585, 31939, 5), teleport = Position(33392, 31452, 15), effect = CONST_ME_TELEPORT },
		{ pos = Position(32586, 31939, 5), teleport = Position(33392, 31452, 15), effect = CONST_ME_TELEPORT },
		{ pos = Position(32587, 31939, 5), teleport = Position(33392, 31452, 15), effect = CONST_ME_TELEPORT },
		{ pos = Position(32588, 31939, 5), teleport = Position(33392, 31452, 15), effect = CONST_ME_TELEPORT },
		{ pos = Position(32584, 31939, 5), teleport = Position(33392, 31452, 15), effect = CONST_ME_TELEPORT },
	},
	specPos = {
		from = Position(33380, 31438, 15),
		to = Position(33386, 31444, 15),
	},
	monsters = {
		{ name = "Spirit Container", pos = Position(33397, 31454, 15) },
		{ name = "Ghost Duster", pos = Position(33395, 31454, 15) },
	},
	exit = Position(33389, 31454, 15),
	onUseExtra = function(player, infoPositions)
		local roomState = refreshRathaRoomState()

		if roomState == ROOM_STATE_MISSION then
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "Someone is already using this room for the mission.")
			return false
		end

		if roomState == ROOM_STATE_BOSS then
			player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "There's already someone fighting with The Rest Of Ratha.")
			return false
		end

		setRathaRoomState(ROOM_STATE_BOSS)
		return true
	end,
}

local lever = BossLever(config)
lever:uid(TwentyYearsACookQuest.TheRestOfRatha.LeverUID)
lever:register()

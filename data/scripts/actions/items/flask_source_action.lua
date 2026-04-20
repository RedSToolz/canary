local RATHA_ROOM_STATE_STORAGE = 985001
local ROOM_STATE_FREE = 0
local ROOM_STATE_MISSION = 1
local ROOM_STATE_BOSS = 2

local FLASK_SOURCE_POSITION = Position(33398, 31453, 15)
local FLASK_SOURCE_AID = 62136

local function getRathaRoomState()
	local value = Game.getStorageValue(RATHA_ROOM_STATE_STORAGE)
	if value == nil or value < 0 then
		return ROOM_STATE_FREE
	end
	return value
end

local function isSamePosition(pos1, pos2)
	return pos1.x == pos2.x and pos1.y == pos2.y and pos1.z == pos2.z
end

local flaskSource = Action()

function flaskSource.onUse(player, item, fromPosition, target, toPosition, isHotkey)

	if getRathaRoomState() ~= ROOM_STATE_BOSS then
		return true
	end

	if not isSamePosition(fromPosition, FLASK_SOURCE_POSITION) then
		return true
	end

	if not TwentyYearsACookQuest.TheRestOfRatha.BossZone:isInZone(player:getPosition()) then
		return true
	end

	local emptyFlaskId = TwentyYearsACookQuest.TheRestOfRatha.Items.EmptySpiritFlask
	local fullFlaskId = TwentyYearsACookQuest.TheRestOfRatha.Items.FullSpiritFlask

	if player:getItemCount(emptyFlaskId) > 0 or player:getItemCount(fullFlaskId) > 0 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You already have a spirit flask.")
		return true
	end

	player:addItem(emptyFlaskId, 1)
	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You take an empty spirit flask.")
	player:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE)
	return true
end

flaskSource:aid(FLASK_SOURCE_AID)
flaskSource:register()

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

local theRestOfRathaZoneEvent = ZoneEvent(TwentyYearsACookQuest.TheRestOfRatha.BossZone)

function theRestOfRathaZoneEvent.afterEnter(_zone, creature)
	local player = creature:getPlayer()
	if not player then
		return false
	end

	-- Só aplica o ícone durante o estado BOSS
	if getRathaRoomState() ~= ROOM_STATE_BOSS then
		return true
	end

	player:setIcon("the-rest-of-ratha", CreatureIconCategory_Quests, CreatureIconQuests_Dove, 3)
	return true
end

function theRestOfRathaZoneEvent.afterLeave(zone, creature)
	local player = creature:getPlayer()
	if not player then
		return false
	end

	local emptyCount = player:getItemCount(TwentyYearsACookQuest.TheRestOfRatha.Items.EmptySpiritFlask)
	local fullCount = player:getItemCount(TwentyYearsACookQuest.TheRestOfRatha.Items.FullSpiritFlask)

	if emptyCount and emptyCount > 0 then
		player:removeItem(TwentyYearsACookQuest.TheRestOfRatha.Items.EmptySpiritFlask, emptyCount)
	end

	if fullCount and fullCount > 0 then
		player:removeItem(TwentyYearsACookQuest.TheRestOfRatha.Items.FullSpiritFlask, 1)
	end

	player:removeIcon("the-rest-of-ratha")
	return true
end

theRestOfRathaZoneEvent:register()

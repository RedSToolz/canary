local RATHA_ROOM_STATE_STORAGE = 985001
local ROOM_STATE_FREE = 0
local ROOM_STATE_MISSION = 1
local ROOM_STATE_BOSS = 2

local HARP_POSITION = Position(33389, 31446, 15)

local function getRathaRoomState()
	local value = Game.getStorageValue(RATHA_ROOM_STATE_STORAGE)
	if value == nil or value < 0 then
		return ROOM_STATE_FREE
	end
	return value
end

local harp = Action()

function harp.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if getRathaRoomState() ~= ROOM_STATE_BOSS then
		return true
	end

	if not TwentyYearsACookQuest.TheRestOfRatha.BossZone:isInZone(fromPosition) then
		return true
	end

	local icon = player:getIcon("the-rest-of-ratha")
	if not icon or icon.count <= 0 then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You are out of inspiration to play.")
		return true
	end

	player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You used your musical inspiration to play a luring tune!")
	item:transform(TwentyYearsACookQuest.TheRestOfRatha.Items.HarpCooldown)
	HARP_POSITION:sendMagicEffect(CONST_ME_SOUND_GREEN)
	player:setIcon("the-rest-of-ratha", CreatureIconCategory_Quests, CreatureIconQuests_Dove, icon.count - 1)

	local rathaFound = false
	local rathaMoved = false

	local monsters = TwentyYearsACookQuest.TheRestOfRatha.BossZone:getMonsters()
	for _, monster in pairs(monsters) do
		if monster and monster:getName():lower() == "the rest of ratha" then
			rathaFound = true
			blockRathaTeleport(monster:getId())
			rathaMoved = monster:walkTo(HARP_POSITION, 0, 1, true, false, 50, true)
			break
		end
	end

	if not rathaFound then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The Rest of Ratha was not found in the boss room.")
	elseif not rathaMoved then
		player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The Rest of Ratha could not find a path to the harp.")
	end

	addEvent(function(position)
		local tile = Tile(position)
		local harpCooldown = tile and tile:getItemById(TwentyYearsACookQuest.TheRestOfRatha.Items.HarpCooldown) or nil
		if harpCooldown then
			harpCooldown:transform(TwentyYearsACookQuest.TheRestOfRatha.Items.Harp)
		end
	end, 15 * 1000, fromPosition)

	return true
end

harp:id(TwentyYearsACookQuest.TheRestOfRatha.Items.Harp)
harp:register()

local harpCooldown = Action()

function harpCooldown.onUse(player, item, fromPosition, target, toPosition, isHotkey)
	if getRathaRoomState() ~= ROOM_STATE_BOSS then
		return true
	end

	fromPosition:sendMagicEffect(CONST_ME_SOUND_RED)
	return true
end

harpCooldown:id(TwentyYearsACookQuest.TheRestOfRatha.Items.HarpCooldown)
harpCooldown:register()

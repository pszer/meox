local meoxmachine = require 'meoxmachine'
local meoxcolour = require 'meoxcolour'
local meoxicons   = require "meoxicons"
local scene = require 'scene'
local meoxanim = require 'meoxanim'

local MeoxSave = {}
MeoxSave.__index = MeoxSave

local serialise = require "serialise"

function MeoxSave:saveToFile(machine, col)
	local timestamp = os.time(os.date("!*t"))

	local save = {}

	save.hunger_v = machine.hunger_v
	save.sleep_v  = machine.sleep_v
	save.fun_v    = machine.fun_v
	save.sleeping = machine:isStateActive("meox_sleep")
	save.timestamp = timestamp
	save.hsl = meoxcolour.hsl

	file = love.filesystem.newFile("meox.txt")
	file:open("w")
	text = serialise(save)
	file:write("return ")
	file:write(text)
	file:close()
end

function MeoxSave:readFromFile(filename)
	local filename = filename or "meox.txt"
	file = love.filesystem.newFile("meox.txt")
	file:open("r")
	data = file:read()
	file:close()

	local old_timestamp
	if data then
		data = loadstring(data)()
		meoxmachine.hunger_v = data.hunger_v
		meoxmachine.sleep_v = data.sleep_v
		meoxmachine.fun_v = data.fun_v
		meoxcolour:setHSL(data.hsl)
		old_timestamp = data.timestamp
	else
		old_timestamp = os.time(os.date("!*t"))
	end

	local curr_timestamp = os.time(os.date("!*t"))
	local dt = (curr_timestamp - old_timestamp) * 1000

	print("dt is ",dt)
	meoxmachine:changeHungerByTime(-dt)
	meoxmachine:changeFunByTime(-dt)
	if data and data.sleeping then
		meoxmachine:changeSleepByTime(dt)
		meoxmachine:activateState("meox_sleep")
		meoxicons:switchToMenu("sleep_menu")
		scene.moon_phase_in = 1.0
		meoxanim.meoxi:setAnimationInterp(
		 1.0)
	else
		meoxmachine:changeSleepByTime(-dt)
		meoxmachine:activateState("meox_idle1")
		meoxicons:switchToMenu("main_menu")
	end
end

return MeoxSave

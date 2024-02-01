require "gamestate"
require "console"
require "model"
local render   = require "render"
local assets   = require "assetloader"
local material = require "materials"
local Meox     = require "meox"
local scene    = require "scene"

local limit = require "syslimits"

local function __print_info()
	print(limit.sysInfoString())
	print("---------------------------------------------------------")
	print(string.format("Save directory: %s", love.filesystem.getSaveDirectory()))
	print("---------------------------------------------------------")
end

function __parse_args( commandline_args )
	local params = {}
	for i,v in ipairs(commandline_args) do
		local eq_pos = string.find(v, '=')
		local com_pos = {}
		if eq_pos then
			for arg in string.gmatch(string.sub(v,eq_pos+1,-1), "[^,%s]+") do
				table.insert(com_pos, arg)
			end
			params[string.sub(v,1,eq_pos-1)] = com_pos
		end
	end
	return params
end

function love.load( args )
	local gamestate_on_launch = Meox
	local params = __parse_args(args)

	local arg_coms = {
	}
	for param,args in pairs(params) do
		local com = arg_coms[param]
		if not com then error(string.format("unrecognised launch parameter %s",tostring(param))) end
		com(args)
	end

	render:init()

	__print_info()
	assets:initThread()
	--assets:openModel("meox.iqm")
	local meox = Model:fromLoader("meox.iqm")
	local meoxi = ModelInstance:newInstance(meox)
	meoxi.props.model_i_contour_flag = true
	scene:addModel(meoxi)

	SET_GAMESTATE(gamestate_on_launch)
end

function love.run()
	if love.load then love.load(love.arg.parseGameArguments(arg), arg) end

	-- We don't want the first frame's dt to include time taken by love.load.
	if love.timer then love.timer.step() end

	local dt = 0
	local sleep_acc = 0

	-- Main loop time.
	return function()
		-- Process events.
		if love.event then
			love.event.pump()
			for name, a,b,c,d,e,f in love.event.poll() do
				if name == "quit" then
					if not love.quit or not love.quit() then
						return a or 0
					end
				end
				love.handlers[name](a,b,c,d,e,f)
			end
		end

		-- Update dt, as we'll be passing it to update
		if love.timer then dt = love.timer.step() end

		if love.update then love.update( dt ) end -- will pass 0 if love.timer is disabled

		if love.graphics and love.graphics.isActive() then
			love.graphics.origin()
			love.graphics.clear(love.graphics.getBackgroundColor())

			if love.draw then love.draw() end

			love.graphics.present()
		end

		sleep_acc = sleep_acc + dt
		if sleep_acc < 1.0/60 then
			sleep_acc = 0
			if love.timer then love.timer.sleep(1.0/60 - sleep_acc) end
		end
		--love.timer.sleep(0.001)
	end
end

function love.update(dt)
	stepTick(dt)
	if GAMESTATE.update then GAMESTATE:update(dt) end
	updateKeys()
end

function love.draw()
	if GAMESTATE.draw then GAMESTATE:draw() end
	love.graphics.reset()
	render:blitViewport()

	if Console.isOpen() then Console.draw() end
end

function love.resize( w,h )
	--update_resolution_ratio( w,h )
	--Renderer.createCanvas()
	if GAMESTATE.resize then GAMESTATE:resize(w,h) end
end

function love.quit()
	if GAMESTATE.quit then GAMESTATE:quit() end
end

function love.keypressed(key, scancode, isrepeat)
	__keypressed(key, scancode, isrepeat)

	if Console.isOpen() then
		Console.keypressed(key)
	end

	if key == "f8" then
		Console.open()
	end
	if GAMESTATE.keypressed then GAMESTATE:keypressed(key, scancode, isrepeat) end
end

function love.keyreleased(key, scancode)
	__keyreleased(key, scancode)
	if GAMESTATE.keyreleased then GAMESTATE:keyreleased(key, scancode) end
end

function love.mousepressed(x, y, button, istouch, presses)
	__mousepressed(x, y, button, istouch, presses)
	if GAMESTATE.mousepressed then GAMESTATE:mousepressed(x, y, button, istouch, presses) end
end

function love.mousereleased(x, y, button, istouch, presses)
	__mousereleased(x, y, button, istouch, presses)
	if GAMESTATE.mousereleased then GAMESTATE:mousereleased(x, y, button, istouch, presses) end
end

function love.mousemoved(x,y,dx,dy,istouch)
	if GAMESTATE.mousemoved then GAMESTATE:mousemoved(x,y,dx,dy,istouch) end
end

function love.wheelmoved(x,y)
	__wheelmoved(x,y)
	if GAMESTATE.wheelmoved then GAMESTATE:wheelmoved(x,y) end
end

function love.textinput(t)
	if Console.isOpen() then
		Console.textinput(t)
	else
		if GAMESTATE.textinput then GAMESTATE:textinput(t) end
	end
end

function love.filedropped(file)
	if GAMESTATE.filedropped then
		GAMESTATE:filedropped(file)
	end
end

local utf8 = require("utf8")

local function error_printer(msg, layer)
	print((debug.traceback("Error: " .. tostring(msg), 1+(layer or 1)):gsub("\n[^\n]+$", "")))
end

function love.errorhandler(msg)
	msg = tostring(msg)

	error_printer(msg, 2)

	if not love.window or not love.graphics or not love.event then
		return
	end

	if not love.graphics.isCreated() or not love.window.isOpen() then
		local success, status = pcall(love.window.setMode, 800, 600)
		if not success or not status then
			return
		end
	end

	-- Reset state.
	if love.mouse then
		love.mouse.setVisible(true)
		love.mouse.setGrabbed(false)
		love.mouse.setRelativeMode(false)
		if love.mouse.isCursorSupported() then
			love.mouse.setCursor()
		end
	end
	if love.joystick then
		-- Stop all joystick vibrations.
		for i,v in ipairs(love.joystick.getJoysticks()) do
			v:setVibration()
		end
	end
	if love.audio then love.audio.stop() end

	love.graphics.reset()
	local font = love.graphics.setNewFont(14)

	love.graphics.setColor(1, 1, 1)

	local trace = debug.traceback()

	love.graphics.origin()

	local sanitizedmsg = {}
	for char in msg:gmatch(utf8.charpattern) do
		table.insert(sanitizedmsg, char)
	end
	sanitizedmsg = table.concat(sanitizedmsg)

	local err = {}

	table.insert(err, "Error\n")
	table.insert(err, sanitizedmsg)

	if #sanitizedmsg ~= #msg then
		table.insert(err, "Invalid UTF-8 string in error message.")
	end

	table.insert(err, "\n")

	for l in trace:gmatch("(.-)\n") do
		if not l:match("boot.lua") then
			l = l:gsub("stack traceback:", "Traceback\n")
			table.insert(err, l)
		end
	end

	local p = table.concat(err, "\n")

	p = p:gsub("\t", "")
	p = p:gsub("%[string \"(.-)\"%]", "%1")

	local function draw()
		if not love.graphics.isActive() then return end
		local pos = 70
		love.graphics.clear(1,1,1)
		love.graphics.setColor(0,0,0,1)
		love.graphics.printf(p, pos, pos, love.graphics.getWidth() - pos)
		love.graphics.present()
	end

	local fullErrorText = p
	local function copyToClipboard()
		if not love.system then return end
		love.system.setClipboardText(fullErrorText)
		p = p .. "\nCopied to clipboard!"
	end

	if love.system then
		p = p .. "\n\nPress Ctrl+C or tap to copy this error"
	end

	return function()
		love.event.pump()

		for e, a, b, c in love.event.poll() do
			if e == "quit" then
				return 1
			elseif e == "keypressed" and a == "escape" then
				return 1
			elseif e == "keypressed" and a == "c" and love.keyboard.isDown("lctrl", "rctrl") then
				copyToClipboard()
			elseif e == "touchpressed" then
				local name = love.window.getTitle()
				if #name == 0 or name == "Untitled" then name = "Game" end
				local buttons = {"OK", "Cancel"}
				if love.system then
					buttons[3] = "Copy to clipboard"
				end
				local pressed = love.window.showMessageBox("Quit "..name.."?", "", buttons)
				if pressed == 1 then
					return 1
				elseif pressed == 3 then
					copyToClipboard()
				end
			end
		end

		draw()

		if love.timer then
			love.timer.sleep(0.1)
		end
	end

end

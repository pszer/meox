-- console
--
--

require "input"

local utf8 = require("utf8")

local guirender = require "consoledraw"
local guilang   = require "consolelang"

Console = {
	text = "",
	text_draw = nil,

	history = {},
	history_scroll = nil,

	open_flag = false,

	init_flag = false,

	font=nil,
	font_bold=nil,
	font_italic=nil,
	font_ibold=nil,

	text_object = nil,
	cursor_pos = 0,
	cursor_x   = 0
}
Console.__index = Console

function Console.init()
	if Console.init_flag then return end
	local f,fb,fi,fib = guirender:getFonts("eng")
	Console.font=f
	Console.font_bold=fb
	Console.font_italic=fi
	Console.font_ibold=fib

	Console.text_object = guirender:createDynamicTextObject("", 2048, function(t) return t end, 
	 Console.font, Console.font_bold, Console.font_italic, Console.font_ibold)
	Console.init_flag = true
end

function Console.open()
	Console.init() 

	love.keyboard.setKeyRepeat(true)
	--Console.text_draw = love.graphics.newText(love.graphics.getFont(), Console.text)
	Console.open_flag = true

	CONTROL_LOCK.CONSOLE.open()
end

function Console.close()
	Console.open_flag = false
	CONTROL_LOCK.CONSOLE.close()
end

function Console.shiftCursor(dir)
	local dir = dir
	if dir then
		local str_len = Console.text_object:strlen()
		Console.cursor_pos = Console.cursor_pos + dir
		if Console.cursor_pos < 1 then Console.cursor_pos = 1 end
		if Console.cursor_pos > str_len+1 then Console.cursor_pos = str_len+1 end
	end
	Console.cursor_x = Console.text_object:getcharpos(Console.cursor_pos)
end

function Console.keypressed(key)
	if key == "backspace" then
		Console.shiftCursor(-1)
		Console.text_object:popchar(Console.cursor_pos)
	elseif key == "return" then
		local code = "do "..Console.text_object.string.." end"
		print("console invoked: " .. code)
		local status = pcall(function() loadstring(code)() end)

		Console.text_object:set("")
		Console.cursor_pos = 0
		Console.cursor_x = 0
		Console.close()
	elseif key == "left" then
		Console.shiftCursor(-1)
	elseif key == "right" then
		Console.shiftCursor(1)
	elseif key == "home" then
		Console.shiftCursor(-1/0)
	elseif key == "end" then
		Console.shiftCursor(1/0)
	elseif key == "escape" or key == "f8" then
		Console.close()
  end
end

function Console.textinput(t)
	Console.text_object:insert(t, Console.cursor_pos)
	local chars = utf8.len(t)
	Console.shiftCursor(chars)
end

function Console.draw()
	love.graphics.push("all")
	love.graphics.reset()
	love.graphics.setColor(0,0,0,1)
	--local w,h = Console.text_draw:getWidth(), Console.text_draw:getHeight()
	love.graphics.rectangle("fill",0,0,1500,64)
	love.graphics.setColor(1,1,1,1)
	--love.graphics.draw(Console.text_draw, 16,16)
	Console.text_object:draw(16,16)
	love.graphics.pop()
end

function Console.isOpen()
	return Console.open_flag
end

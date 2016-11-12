minetest.register_on_chat_message(function(name, message)
	local pos = minetest.get_player_by_name(name):getpos()
	pos.y = pos.y + 2.5
	local text = minetest.add_entity(pos, "chat_bubbles:text")
	text:get_luaentity().text = message
end)

minetest.register_entity("chat_bubbles:text", {
    collisionbox = { -1, -1, -1, 1, 1, 1 },
    visual = "sprite",
    textures = {},
	text = "",
	timer = 0,
    on_activate = function(self)
		minetest.after(0,function(self)
			print(self.text)
			self.object:set_properties({textures={generate_texture(create_lines(self.text))}})
		end,self)
    end,
    on_step = function(self,dtime)
		self.timer = self.timer + dtime
		if self.timer > 5 then
			self.object:remove()
		end
    end,
})

local chars_file = io.open(minetest.get_modpath("chat_bubbles").."/characters", "r")
local charmap = {}
local max_chars = 16
if not chars_file then
    print("[signs] E: character map file not found")
else
    while true do
        local char = chars_file:read("*l")
        if char == nil then
            break
        end
        local img = chars_file:read("*l")
        chars_file:read("*l")
        charmap[char] = img
    end
end
-- CONSTANTS
local SIGN_WITH = 110
local SIGN_PADDING = 8

local LINE_LENGTH = 16
local NUMBER_OF_LINES = 4

local LINE_HEIGHT = 14
local CHAR_WIDTH = 5

string_to_array = function(str)
	local tab = {}
	for i=1,string.len(str) do
		table.insert(tab, string.sub(str, i,i))
	end
	return tab
end

string_to_word_array = function(str)
	local tab = {}
	local current = 1
	tab[1] = ""
	for _,char in ipairs(string_to_array(str)) do
		if char ~= " " then
			tab[current] = tab[current]..char
		else
			current = current+1
			tab[current] = ""
		end
	end
	return tab
end

create_lines = function(text)
	local line = ""
	local line_num = 1
	local tab = {}
	for _,word in ipairs(string_to_word_array(text)) do
		if string.len(line)+string.len(word) < LINE_LENGTH and word ~= "|" then
			if line ~= "" then
				line = line.." "..word
			else
				line = word
			end
		else
			table.insert(tab, line)
			if word ~= "|" then
				line = word
			else
				line = ""
			end
			line_num = line_num+1
			if line_num > NUMBER_OF_LINES then
				return tab
			end
		end
	end
	table.insert(tab, line)
	return tab
end

generate_texture = function(lines)
    local texture = "[combine:"..SIGN_WITH.."x"..SIGN_WITH
    local ypos = 12
    for i = 1, #lines do
        texture = texture..generate_line(lines[i], ypos)
        ypos = ypos + LINE_HEIGHT
    end
    texture = "chat_bubble.png^"..texture
    return texture
end

generate_line = function(s, ypos)
    local i = 1
    local parsed = {}
    local width = 0
    local chars = 0
    while chars < max_chars and i <= #s do
        local file = nil
        if charmap[s:sub(i, i)] ~= nil then
            file = charmap[s:sub(i, i)]
            i = i + 1
        elseif i < #s and charmap[s:sub(i, i + 1)] ~= nil then
            file = charmap[s:sub(i, i + 1)]
            i = i + 2
        else
            print("[signs] W: unknown symbol in '"..s.."' at "..i.." (probably "..s:sub(i, i)..")")
            i = i + 1
        end
        if file ~= nil then
            width = width + CHAR_WIDTH
            table.insert(parsed, file)
            chars = chars + 1
        end
    end
    width = width - 1

    local texture = ""
    local xpos = math.floor((SIGN_WITH - 2 * SIGN_PADDING - width) / 2 + SIGN_PADDING)
    for i = 1, #parsed do
        texture = texture..":"..xpos..","..ypos.."="..parsed[i]..".png"
        xpos = xpos + CHAR_WIDTH + 1
    end
    return texture
end

if minetest.setting_get("log_mods") then
	minetest.log("action", "signs loaded")
end

--!strict

--[[
	CSS To Luau Compiler
	Version 1.0.0
	
	Parses CSS-like input into Luau styling code for Roblox.
	
	Made by:
	- Daxyzeus
]]

local uiPath = 'game:GetService("StarterGui").ScreenGui'
--[[ ^ Change this to the path with all your UI objects inside ]]

--[[ ⌄ Change this to your CSS file/Desired CSS input ]]
local cssText:string = [[
	/* Example CSS Code */
	
	.TextLabel {
	  color: #ffffff;
	  background-color: orange;
	  size: 200, 100;
	  border: 4px;
	  border-radius: 10px;
	  font-size: 30px
	}
	
	/* 
	Roblox properties work too
	since they're backwards-
	compatible!
	*/
]]

type style = {property:string,value:string}
type cssRules = {[string]:{style}}

--[[ CSS parser function (regex hell) ]]
local function parseCSS(cssText:string):{selectors:cssRules}
	local rules = {}
	local currentSelector:string? = nil
	local insideBlock:boolean = false

	cssText = cssText:gsub("/%*.-%*/","") --[[ Strips all comments ]]

	for line:string in cssText:gmatch("[^\n]+") do
		line = assert(line:match("^%s*(.-)%s*$"), "Failed to strip whitespace from line") --[[ Strips all whitespaces ]]

		if line == "" then
			continue
		end

		if not insideBlock and line:match("^[%w#%.%-*]+%s*{") then --[[ All supported selectors ]]
			currentSelector = assert(line:match("^(.-)%s*{"), "Invalid selector format"):gsub("%s+", "")
			rules[currentSelector::string] = {}
			insideBlock = true
		elseif insideBlock and line == "}" then
			insideBlock = false
			currentSelector = nil
		elseif insideBlock and currentSelector and line:match(":") then
			local property, value = line:match("^(.-)%s*:%s*(.-);?$")
			if property and value then
				table.insert(rules[currentSelector], { property = property, value = value })
			else
				--assert(line:match(";"), `Did you forget to close line "{line}" with a semicolon?`)
				error("Invalid property or value format in line: " .. line)
			end
		end
		continue
	end
	return { selectors = rules }
end

--[[ CSS color names ]]
local namedColors:{[string]:{number}} = {
	red = {255, 0, 0},
	green = {0, 128, 0},
	blue = {0, 0, 255},
	black = {0, 0, 0},
	white = {255, 255, 255},
	gray = {128, 128, 128},
	grey = {128, 128, 128},
	yellow = {255, 255, 0},
	purple = {128, 0, 128},
	pink = {255, 192, 203},
	cyan = {0, 255, 255},
	aqua = {0, 255, 255},
	teal = {0, 128, 128},
	orange = {255, 165, 0},
	brown = {165, 42, 42},
	magenta = {255, 0, 255},
	navy = {0, 0, 128},
	olive = {128, 128, 0},
	maroon = {128, 0, 0},
	lime = {0, 255, 0},
	silver = {192, 192, 192}
}

local function parseColor(value:string):(number?,number?,number?)
	--[[ RGB ]]
	local r, g, b = value:match("rgb%((%d+),%s*(%d+),%s*(%d+)%)")
	if r then return tonumber(r), tonumber(g), tonumber(b) end

	--[[ HEX ]]
	local hex = value:match("#(%x%x%x%x%x%x)")
	if hex then
		return tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
	end

	--[[ Color name ]]
	local rgb = namedColors[value:lower()]
	if rgb then return unpack(rgb) end

	return nil
end

--[[ CSS + Roblox properties ]]
local propertyHandlers:{[string]:(string)->string} = {

	--[[ CSS PROPERTIES ]]

	['color'] = function(value)
		local r, g, b = parseColor(value)
		if not r then error("Invalid color value, please use either RGB, HEX, or a color name") end

		return `\t\tobj.TextColor3 = Color3.fromRGB({r}, {g}, {b})\n`
	end,

	['background-color'] = function(value)
		local r, g, b = parseColor(value)
		if not r then error("Invalid background-color value, please use either RGB, HEX, or a color name") end

		return `\t\tobj.BackgroundColor3 = Color3.fromRGB({r}, {g}, {b})\n`
	end,

	['font-size'] = function(value)
		local size = value:match("(%d+)px")
		if not size then
			error(`Invalid/Unsupported font-size format: {value}`)
		end
		return `\t\tobj.TextSize = {size}\n`
	end,

	['font-family'] = function(value)
		local font = value:match('"%s*(.-)%s*"') or value
		if not font then
			error(`Invalid/Unsupported font-family format: {value}`)
		end
		return `\t\tobj.FontFace = Font.fromName({value})\n`
	end,

	['size'] = function(value)
		local width, height = value:match("(%d+),%s*(%d+)")
		if not width or not height then
			error(`Invalid/Unsupported size format: {value}`)
		end
		return `\t\tobj.Size = UDim2.new(0, {width}, 0, {height})\n`
	end,

	['border'] = function(value)
		local borderSize = value:match("(%d+)px")
		if not borderSize then
			error(`Invalid/Unsupported border format: {value}`)
		end
		return `\t\tlocal stroke = obj:FindFirstChildWhichIsA("UIStroke") or Instance.new("UIStroke", obj)\n\t\tstroke.Thickness = {borderSize}\n\t\tstroke.ApplyStrokeMode = "Border"\n\t\tstroke.LineJoinMode = "Round"\n`
	end,

	['border-radius'] = function(value)
		local borderRadius = value:match("(%d+)px")
		if not borderRadius then
			error(`Invalid/Unsupported border-radius format: {value}`)
		end
		return `\t\tlocal corner = obj:FindFirstChildWhichIsA("UICorner") or Instance.new("UICorner", obj)\n\t\tcorner.CornerRadius = UDim.new(0, {borderRadius})\n`
	end,

	['border-color'] = function(value)
		local r, g, b = parseColor(value)
		if not r then error("Invalid border-color value, please use either RGB, HEX, or a color name") end

		return `\t\tlocal stroke = obj:FindFirstChildWhichIsA("UIStroke") or Instance.new("UIStroke", obj)\n\t\tstroke.Color = Color3.fromRGB({r}, {g}, {b})\n`
	end,

	['padding'] = function(value)
		local paddingAll = value:match("(%d+)px")
		if not paddingAll then
			error(`Invalid/Unsupported padding format: {value}`)
		end
		return `\t\tlocal padding = obj:FindFirstChildWhichIsA("UIPadding") or Instance.new("UIPadding", obj)\n\t\tpadding.PaddingBottom = UDim.new(0, {paddingAll})\n\t\tpadding.PaddingLeft = UDim.new(0, {paddingAll})\n\t\tpadding.PaddingRight = UDim.new(0, {paddingAll})\n\t\tpadding.PaddingTop = UDim.new(0, {paddingAll})\n`
	end,
	
	['padding-top'] = function(value)
		local paddingTop = value:match("(%d+)px")
		if not paddingTop then
			error(`Invalid/Unsupported padding-top format: {value}`)
		end
		return `\t\tlocal padding = obj:FindFirstChildWhichIsA("UIPadding") or Instance.new("UIPadding", obj)\n\t\tpadding.PaddingTop = UDim.new(0, {paddingTop})\n`
	end,
	
	['padding-left'] = function(value)
		local paddingLeft = value:match("(%d+)px")
		if not paddingLeft then
			error(`Invalid/Unsupported padding-left format: {value}`)
		end
		return `\t\tlocal padding = obj:FindFirstChildWhichIsA("UIPadding") or Instance.new("UIPadding", obj)\n\t\tpadding.PaddingLeft = UDim.new(0, {paddingLeft})\n`
	end,
	
	['padding-right'] = function(value)
		local paddingRight = value:match("(%d+)px")
		if not paddingRight then
			error(`Invalid/Unsupported padding-right format: {value}`)
		end
		return `\t\tlocal padding = obj:FindFirstChildWhichIsA("UIPadding") or Instance.new("UIPadding", obj)\n\t\tpadding.PaddingRight = UDim.new(0, {paddingRight})\n`
	end,
	
	['padding-bottom'] = function(value)
		local paddingBottom = value:match("(%d+)px")
		if not paddingBottom then
			error(`Invalid/Unsupported padding-bottom format: {value}`)
		end
		return `\t\tlocal padding = obj:FindFirstChildWhichIsA("UIPadding") or Instance.new("UIPadding", obj)\n\t\tpadding.PaddingBottom = UDim.new(0, {paddingBottom})\n`
	end,
	
	['z-index'] = function(value)
		local zIndex = value:match("(%d+)")
		if not zIndex then
			error(`Invalid/Unsupported z-index format: {value}`)
		end
		return `\t\tobj.ZIndex = {zIndex}\n`
	end,

	--[[ ROBLOX PROPERTIES ]]

	['Color'] = function(value)
		local r, g, b = parseColor(value)
		if not r then error("Invalid Color value, please use either RGB, HEX, or a color name") end

		return `\t\tobj.TextColor3 = Color3.fromRGB({r}, {g}, {b})\n`
	end,

	['TextColor3'] = function(value)
		local r, g, b = parseColor(value)
		if not r then error("Invalid TextColor3 value, please use either RGB, HEX, or a color name") end

		return `\t\tobj.TextColor3 = Color3.fromRGB({r}, {g}, {b})\n`
	end,

	['BackgroundColor3'] = function(value)
		local r, g, b = parseColor(value)
		if not r then error("Invalid BackgroundColor3 value, please use either RGB, HEX, or a color name") end

		return `\t\tobj.BackgroundColor3 = Color3.fromRGB({r}, {g}, {b})\n`
	end,
}

--[[ Generate Luau code from CSS ]]
local function generateLuau(parsedCSS)
	local luaCode:string = ""

	for selector, properties in pairs(parsedCSS.selectors) do
		if selector:match("^#") then --[[ ID selector (#) ]]
			local idName = selector:sub(2)
			luaCode = luaCode..`\n--[[ Parsed code for ID: {idName} ]]\n`
			luaCode = luaCode..string.format([[for _, obj in ipairs(%s:GetDescendants()) do]], uiPath)..'\n'
			luaCode = luaCode..`\tif obj and obj.Name == "{idName}" then\n`
		elseif selector:match("^%.") then --[[ Class selector (.) ]]
			local className = selector:sub(2)
			luaCode = luaCode..`\n--[[ Parsed code for Class: {className} ]]\n` 
			luaCode = luaCode..string.format([[for _, obj in ipairs(%s:GetDescendants()) do]], uiPath)..'\n'
			luaCode = luaCode..`\tif obj.ClassName == "{className}" then\n`
		elseif selector:match("^%*") then --[[ Universal selector (*) ]]
			local universalName = selector:sub(2)
			luaCode = luaCode..`\n--[[ Parsed code for Universal: {universalName ~= '' and universalName or "(All)"} ]]\n`
			luaCode = luaCode..string.format([[for _, obj in ipairs(%s:GetDescendants()) do]], uiPath)..'\n'
			luaCode = luaCode..[[
		local allowedTypes = {
			TextLabel = true,
			TextButton = true,
			TextBox = true,
			Frame = true,
			ImageLabel = true,
			ImageButton = true,
			ScrollingFrame = true,
			ViewportFrame = true,
		}
		if allowedTypes[obj.ClassName] then
		]]
		else --[[ Object selector ]]
			luaCode = luaCode..`\n--[[ Parsed code for Object: {selector} ]]\n`
			luaCode = luaCode..string.format([[for _, obj in ipairs(%s:GetDescendants()) do]], uiPath)..'\n'
			luaCode = luaCode..`\tif obj.Name == "{selector}" then\n`
		end

		for _,style in ipairs(properties) do
			local handler = propertyHandlers[style.property]
			if handler then
				luaCode = luaCode.."\t\tlocal ok, err = pcall(function()\n"..handler(style.value).."\t\tend)\n"
				luaCode = luaCode.."\t\tif not ok then warn('Property conflict:', err) end\n"
				--[[^ Replace these lines with "luaCode = luaCode..handler(style.value)" if you don't want to be notified of conflicts ]]
			else
				error("Unsupported CSS property: "..style.property)
			end
		end

		luaCode = luaCode.."\tend\nend\n"
	end

	if luaCode == '' then warn("No CSS input found, is your CSS file empty?") end

	return luaCode
end

--[[ Compile ]]
local startTime:number = os.clock()
local parsedCSS = parseCSS(cssText)
local generatedCode = generateLuau(parsedCSS)
local endTime:number = os.clock()

--[[ Output ]]
warn(generatedCode)

print(string.format("CSS compilation completed in %.7f seconds", (endTime - startTime)))
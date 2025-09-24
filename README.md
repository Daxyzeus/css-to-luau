# CSS To Lua Compiler

**Version 1.0.0**

A strictly-typechecked, lightweight compiler that converts CSS-like syntax into Luau code for Roblox UI elements.

Built for Roblox developers who want to write CSS based input and apply them directly to Roblox UI components / elements.

## Features

- Supports ID (`#id`), class (`.class`), type (`TextLabel`), and universal (`*`) selectors
- Recognizes frequently used CSS color formats
  * Named colors (`red`, `blue`, `green`, etc.)
  * RGB (`rgb(255, 255, 255)`)
  * Hex (`#FF0000`)
- Includes backwards-compatible Roblox property support
- Has error detection and logs property conflicts
- Logs compilation time for performance tracking

## Usage

### 1. Install

Download or copy the script [`css-to-luau`](https://github.com/Daxyzeus/css-to-luau/blob/main/css-to-luau.lua) to either a ServerScript or a LocalScript

### 2. Setup

Change this line in the script to the desired path including the UI elements you want to style
```lua
local uiPath = 'game:GetService("StarterGui").ScreenGui'
```

### 3. Run

To run it, either paste the modified script in the server-console, or run the game with the script to have it compile for you

## Usage Example

### Here's how a CSS snippet looks and compiles:
**Input (CSS):**
```css
.TextLabel {
	color: #ffffff;
	background-color: orange;
	size: 200, 100;
	border: 4px;
	border-radius: 10px;
	font-size: 30px
}
```
**Output (Luau):**
```lua
--[[ Parsed code for Class: TextLabel ]]
for _, obj in ipairs(game:GetService("StarterGui").ScreenGui:GetDescendants()) do
	if obj.ClassName == "TextLabel" then
		local ok, err = pcall(function()
			obj.TextColor3 = Color3.fromRGB(255, 255, 255)
		end)
		if not ok then warn('Property conflict:', err) end
		local ok, err = pcall(function()
			obj.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
		end)
		if not ok then warn('Property conflict:', err) end
		local ok, err = pcall(function()
			obj.Size = UDim2.new(0, 200, 0, 100)
		end)
		if not ok then warn('Property conflict:', err) end
		local ok, err = pcall(function()
			local stroke = obj:FindFirstChildWhichIsA("UIStroke") or Instance.new("UIStroke", obj)
			stroke.Thickness = 4
			stroke.ApplyStrokeMode = "Border"
			stroke.LineJoinMode = "Round"
		end)
		if not ok then warn('Property conflict:', err) end
		local ok, err = pcall(function()
			local corner = obj:FindFirstChildWhichIsA("UICorner") or Instance.new("UICorner", obj)
			corner.CornerRadius = UDim.new(0, 10)
		end)
		if not ok then warn('Property conflict:', err) end
		local ok, err = pcall(function()
			obj.TextSize = 30
		end)
		if not ok then warn('Property conflict:', err) end
	end
end
```
### Result:
<img width="234" height="135" alt="{76B4F2B8-20AD-4A62-9C36-CBF7213FE333}" src="https://github.com/user-attachments/assets/5525f28b-f074-4ffc-97ae-c7e27be87925" />

## Supported Properties

| CSS Properties     | Compiles to                                                                                    |
|--------------------|------------------------------------------------------------------------------------------------|
| `color`            | `TextColor3`                                                                                   |
| `background-color` | `BackgroundColor3`                                                                             |
| `font-size`        | `TextSize`                                                                                     |
| `font-family`      | `FontFace`                                                                                     |
| `size`             | `Size`                                                                                         |
| `border`           | `Instance.new("UIStroke")` -> `Thickness`                                                      |
| `border-radius`    | `Instance.new("UICorner")` -> `CornerRadius`                                                   |
| `border-color`     | `Instance.new("UIStroke")` -> `Color`                                                          |
| `padding`          | `Instance.new("UIPadding")` ->   `PaddingBottom`, `PaddingLeft`, `PaddingRight`, `PaddingTop`  |
| `padding-top`      | `Instance.new("UIPadding")` -> `PaddingTop`                                                    |
| `padding-left`     | `Instance.new("UIPadding")` -> `PaddingLeft`                                                   |
| `padding-right`    | `Instance.new("UIPadding")` -> `PaddingRight`                                                  |
| `padding-bottom`   | `Instance.new("UIPadding")` -> `PaddingBottom`                                                 |
| `z-index`          | `ZIndex`                                                                                       |

| Roblox Properties  |
|--------------------|
| `Color`            |
| `TextColor3`       |
| `BackgroundColor3` |

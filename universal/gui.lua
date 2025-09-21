local Players = game:GetService("Players")
local Input = game:GetService("UserInputService")
local Windui = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local Repository = "https://raw.githubusercontent.com/goose-birb/lua-buffoonery/master/"

getgenv().aimConfig = getgenv().aimConfig
	or {
		enabled = false,
		fovDeg = 15,
		triggerFovDeg = 2,
		targetPart = "Head",
		smoothness = 0.25,
		prediction = 0.05,
		maxDistance = 500,
		useRay = true,
		respectTeams = false,
		triggerBot = true,
		triggerMode = "button",
		triggerAction = nil,
		triggerClosure = nil,
	}

getgenv().espConfig = getgenv().espConfig
	or {
		enabled = false,
		mode = "Highlight",
		showNames = true,
		showDistance = false,
		showHealth = false,
		useTeamColor = true,
		teammateColor = Color3.fromRGB(0, 255, 0),
		enemyColor = Color3.fromRGB(255, 0, 0),
		fillTransparency = 0.5,
		outlineTransparency = 0,
		textSize = 14,
	}

local Window = Windui:CreateWindow({
	Title = "Wildcard",
	Icon = "asterisk",
	Author = "by Le Honk",
	Folder = "Universal",
	Theme = "Dark",
	Size = UDim2.fromOffset(580, 100),
	Resizable = true,
	Transparent = true,
})

local Config = Window.ConfigManager
local default = Config:CreateConfig("default")
local saveFlag = "WindUI/" .. Window.Folder .. "/config/autosave"
local loadFlag = "WindUI/" .. Window.Folder .. "/config/autoload"
local Elements = {}

local asset = {}
local animation = {}
local emotes = { "Press to try and refresh" }
local resumeAnimation = {}
local animator
local track

local player = Players.LocalPlayer
local elementList = {}
local nameList = {}
local isCapturing = false
local connections = {}

local function refreshAnimations()
	if not player.Character then
		return
	end

	animation = {}
	emotes = {}

	for _, obj in ipairs(game:GetDescendants()) do
		local name = obj.Name
		if obj:IsA("Animation") and not animation[name] then
			animation[name] = obj
			table.insert(emotes, name)
		end
	end

	for _, assetid in ipairs(asset) do
		if not animation[assetid] then
			local instance = Instance.new("Animation")
			instance.AnimationId = assetid

			animation[assetid] = instance
			table.insert(emotes, assetid)
		end
	end

	table.sort(emotes)
end

local function playAnimation(name)
	if track then
		track:Stop()
	end

	track = animator:LoadAnimation(animation[name])
	track:Play()
end

local function isElement(object)
	return object:IsA("TextButton") or object:IsA("ImageButton") or object:IsA("Tool") or object:IsA("ClickDetector")
end

local function connectElement(element)
	if isElement(element) then
		local connection
		local className = element.ClassName

		if className == "TextButton" or className == "ImageButton" or className == "Tool" then
			connection = element.Activated:Connect(function()
				if isCapturing then
					isCapturing = false
					if not table.find(elementList, element) then
						local displayName
						if className == "TextButton" or className == "ImageButton" then
							displayName = "[BTN] " .. element.Name
						elseif className == "Tool" then
							displayName = "[TOOL] " .. element.Name
						end
						elementList[displayName] = element
						table.insert(nameList, displayName)

						getgenv().aimConfig.triggerAction = element
						Elements.triggerDrop:Refresh(nameList)
					end

					Elements.triggerDrop:Select(element.Name)
					Window:Open()
				end
			end)
		elseif className == "ClickDetector" then
			connection = element.MouseClick:Connect(function()
				if isCapturing then
					isCapturing = false
					if not table.find(elementList, element) then
						local displayName = "[CLK] " .. element.Name
						if element.Parent then
							displayName = displayName .. " (on " .. element.Parent.Name .. ")"
						end
						elementList[displayName] = element
						table.insert(nameList, displayName)

						getgenv().aimConfig.triggerAction = element
						Elements.triggerDrop:Refresh(nameList)
					end

					Elements.triggerDrop:Select(element.Name)
					Window:Open()
				end
			end)
		end

		if connection then
			table.insert(connections, connection)
		end
	end
end

local function scanDescendants(parent)
	for _, child in ipairs(parent:GetDescendants()) do
		if isElement(child) then
			connectElement(child)
		end
	end

	local connection = parent.DescendantAdded:Connect(function(child)
		if isElement(child) then
			connectElement(child)
		end
	end)
	table.insert(connections, connection)
end

local function scanElements()
	for _, connection in pairs(connections) do
		connection:Disconnect()
	end
	connections = {}

	for _, service in ipairs({ workspace, game:GetService("StarterGui"), game:GetService("StarterPack") }) do
		scanDescendants(service)
	end
	scanDescendants(player.PlayerGui)

	if player:FindFirstChild("Backpack") then
		scanDescendants(player.Backpack)
	end
end

local function getParts()
	local parts = {}
	local character = player.Character
	if character then
		for _, child in ipairs(character:GetChildren()) do
			if child:IsA("BasePart") then
				table.insert(parts, child.Name)
			end
		end
	end
	return parts
end

local function handleTracks()
	local humanoid = player.Character:WaitForChild("Humanoid")
	animator = humanoid:WaitForChild("Animator")

	humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
		if track and humanoid.MoveDirection.Magnitude > 0 then
			track:Stop()
			track = nil
		end
	end)
end

function Config:Save()
	if isfile(saveFlag) then
		default:Save()
	end
end

local Modules = {}
function Modules:Load(file)
	if Modules[file] then
		return Modules[file]
	end

	_, Modules[file] = pcall(loadstring(game:HttpGet(Repository .. file)))
end

function Modules:Unload(moduleName)
	local module = Modules[moduleName]
	if not module then
		return
	end

	if type(module) == "table" then
		for _, connection in pairs(module) do
			if connection and connection.Disconnect then
				connection:Disconnect()
			end
		end
	elseif module.Disconnect then
		module:Disconnect()
	end
	Modules[moduleName] = nil
end

local Aim = Window:Tab({
	Title = "Aim Bot",
	Icon = "crosshair",
	Locked = false,
})

Aim:Section({
	Title = "General",
})

Elements.aimToggle = Aim:Toggle({
	Title = "Aim Bot",
	Desc = "Enable/Disable AimBot",
	Value = getgenv().aimConfig.enabled,
	Callback = function(state)
		if not state then
			Modules:Unload("universal/aimbot.lua")
			return
		end
		Modules:Load("universal/aimbot.lua")
		Config:Save()
	end,
})

Elements.fovSlider = Aim:Slider({
	Title = "FOV Degrees",
	Value = {
		Min = 1,
		Max = 90,
		Default = getgenv().aimConfig.fovDeg,
	},
	Callback = function(val)
		getgenv().aimConfig.fovDeg = tonumber(val)
		Config:Save()
	end,
})

Elements.triggerFovSlider = Aim:Slider({
	Title = "Trigger FOV Degrees",
	Value = {
		Min = 1,
		Max = 30,
		Default = getgenv().aimConfig.triggerFovDeg,
	},
	Callback = function(val)
		getgenv().aimConfig.triggerFovDeg = tonumber(val)
		Config:Save()
	end,
})

Elements.smoothnessSlider = Aim:Slider({
	Title = "Smoothness",
	Step = 0.01,
	Value = {
		Min = 0.01,
		Max = 1,
		Default = getgenv().aimConfig.smoothness,
	},
	Callback = function(val)
		getgenv().aimConfig.smoothness = tonumber(val)
		Config:Save()
	end,
})

Elements.predictionSlider = Aim:Slider({
	Title = "Prediction",
	Step = 0.01,
	Value = {
		Min = 0,
		Max = 1,
		Default = getgenv().aimConfig.prediction,
	},
	Callback = function(val)
		getgenv().aimConfig.prediction = tonumber(val)
		Config:Save()
	end,
})

Elements.maxDistanceSlider = Aim:Slider({
	Title = "Max Distance",
	Value = {
		Min = 50,
		Max = 2000,
		Default = getgenv().aimConfig.maxDistance,
	},
	Callback = function(val)
		getgenv().aimConfig.maxDistance = tonumber(val)
		Config:Save()
	end,
})

Elements.partDrop = Aim:Dropdown({
	Title = "Target Part",
	Values = getParts(),
	Value = getgenv().aimConfig.targetPart,
	Callback = function(option)
		getgenv().aimConfig.targetPart = option
		Config:Save()
	end,
})

Elements.visibilityToggle = Aim:Toggle({
	Title = "Visibility Check",
	Desc = "Only target visible enemies",
	Value = getgenv().aimConfig.useRay,
	Callback = function(state)
		getgenv().aimConfig.useRay = state
		Config:Save()
	end,
})

Elements.teamToggle = Aim:Toggle({
	Title = "Team Check",
	Desc = "Don't target teammates",
	Value = getgenv().aimConfig.respectTeams,
	Callback = function(state)
		getgenv().aimConfig.respectTeams = state
		Config:Save()
	end,
})

Aim:Section({
	Title = "Trigger Bot",
})

Elements.triggerToggle = Aim:Toggle({
	Title = "Trigger Bot",
	Desc = "Enable/Disable automatic firing",
	Value = getgenv().aimConfig.triggerBot,
	Callback = function(state)
		getgenv().aimConfig.triggerBot = state
		Config:Save()
	end,
})

Elements.triggerModeDrop = Aim:Dropdown({
	Title = "Trigger Mode",
	Values = { "mouse1", "mouse2", "button", "closure" },
	Value = getgenv().aimConfig.triggerMode,
	Callback = function(option)
		if string.find(option, "mouse") and not Input.MouseEnabled then
			Windui:Notify({
				Title = "Warning",
				Content = "Your game input might interrupt when triggering as it will change the current input type to mouse and keyboard.",
				Duration = 4,
				Icon = "triangle-alert",
			})
		end

		if option == "closure" then
			Windui:Notify({
				Title = "Info",
				Content = "Use this only as a last resort, it will try to call an user defined triggerClosure function from the aimConfig to handle triggering.",
				Duration = 10,
				Icon = "circle-alert",
			})
		end

		getgenv().aimConfig.triggerMode = option
		Config:Save()
	end,
})

Elements.captureButton = Aim:Button({
	Title = "Capture Button",
	Desc = "Hide UI and click the button you want to use as trigger",
	Callback = function()
		isCapturing = true
		Window:Close()

		scanElements()
		Windui:Notify({
			Title = "Button Selection",
			Content = "Press a button to select it",
			Duration = 4,
		})
	end,
})

Elements.triggerDrop = Aim:Dropdown({
	Title = "Trigger Button",
	Values = { "Press 'Capture Button' first" },
	SearchBarEnabled = true,
	Callback = function(option)
		if elementList and elementList[option] then
			getgenv().aimConfig.triggerAction = elementList[option]
		end
		Config:Save()
	end,
})

local Visuals = Window:Tab({
	Title = "Visuals",
	Icon = "eye",
	Locked = false,
})

Visuals:Section({
	Title = "Players",
})

Elements.espToggle = Visuals:Toggle({
	Title = "Player ESP",
	Desc = "Enable/Disable the ESP functionality",
	Value = getgenv().espConfig.enabled,
	Callback = function(state)
		if not state then
			Modules:Unload("universal/esp.lua")
			return
		end
		Modules:Load("universal/esp.lua")
		Config:Save()
	end,
})

Elements.nameToggle = Visuals:Toggle({
	Title = "Show Names",
	Desc = "Whether or not the ESP should display name boards",
	Value = getgenv().espConfig.showNames,
	Callback = function(state)
		getgenv().espConfig.showNames = state
		Config:Save()
	end,
})

Elements.nameToggle = Visuals:Toggle({
	Title = "Show Distance",
	Desc = "Whether or not the ESP should display the player distance on the name board",
	Value = getgenv().espConfig.showDistance,
	Callback = function(state)
		getgenv().espConfig.showDistance = state
		Config:Save()
	end,
})

Elements.nameToggle = Visuals:Toggle({
	Title = "Show Health",
	Desc = "Whether or not the ESP should display the player health on the name board",
	Value = getgenv().espConfig.showHealth,
	Callback = function(state)
		getgenv().espConfig.showHealth = state
		Config:Save()
	end,
})

Elements.nameToggle = Visuals:Toggle({
	Title = "Team Colors",
	Desc = "Whether or not the ESP highlights should use the team colors",
	Value = getgenv().espConfig.useTeamColor,
	Callback = function(state)
		getgenv().espConfig.useTeamColor = state
		Config:Save()
	end,
})

Elements.espDrop = Visuals:Dropdown({
	Title = "ESP Mode",
	Values = { "Highlight", "Xray" },
	Value = getgenv().espConfig.mode,
	Callback = function(option)
		getgenv().espConfig.mode = option
		Config:Save()
	end,
})

Elements.fillSlider = Visuals:Slider({
	Title = "Highlight Fill Transparency",
	Step = 0.1,
	Value = {
		Min = 0,
		Max = 2,
		Default = getgenv().espConfig.fillTransparency,
	},
	Callback = function(value)
		getgenv().espConfig.fillTransparency = tonumber(value)
		Config:Save()
	end,
})

Elements.outlineSlider = Visuals:Slider({
	Title = "Highlight Outline Transparency",
	Step = 0.1,
	Value = {
		Min = 0,
		Max = 2,
		Default = getgenv().espConfig.outlineTransparency,
	},
	Callback = function(value)
		getgenv().espConfig.outlineTransparency = tonumber(value)
		Config:Save()
	end,
})

Elements.textSlider = Visuals:Slider({
	Title = "Name Board Text Size",
	Step = 1,
	Value = {
		Min = 1,
		Max = 30,
		Default = getgenv().espConfig.textSize,
	},
	Callback = function(value)
		getgenv().espConfig.textSize = tonumber(value)
		Config:Save()
	end,
})

Elements.teamPick = Visuals:Colorpicker({
	Title = "Teammate Highlight Color",
	Default = getgenv().espConfig.teammateColor,
	Callback = function(color)
		getgenv().espConfig.teammateColor = color
		Config:Save()
	end,
})

Elements.enemyPick = Visuals:Colorpicker({
	Title = "Enemy Highlight Color",
	Default = getgenv().espConfig.enemyColor,
	Callback = function(color)
		getgenv().espConfig.enemyColor = color
		Config:Save()
	end,
})

Visuals:Section({
	Title = "Emotes",
})

refreshAnimations()
Elements.emoteDrop = Visuals:Dropdown({
	Title = "Select Emote",
	Values = emotes,
	Callback = function(option)
		resumeAnimation = option
		playAnimation(option)
		Config:Save()
	end,
})

local emoteInput = Visuals:Input({
	Title = "Add Emote",
	Desc = "Adds an emote from outside the game",
	Type = "Input",
	Placeholder = "rbxassetid://1949963001",
	Callback = function(input)
		table.insert(asset, input)
		refreshAnimations()
		Elements.emoteDrop:Refresh(emotes)
	end,
})

Elements.emoteBind = Visuals:Keybind({
	Title = "Keybind Emote",
	Desc = "Keybind to play the selected emote",
	Value = "X",
	Callback = function()
		playAnimation(resumeAnimation)
		Config:Save()
	end,
})

local Settings = Window:Tab({
	Title = "Settings",
	Icon = "settings",
	Locked = false,
})

Settings:Section({
	Title = "Configuration",
})

local themes = {}
for theme in pairs(Windui:GetThemes()) do
	table.insert(themes, theme)
end
table.sort(themes)

Elements.themeDrop = Settings:Dropdown({
	Title = "Theme",
	Values = themes,
	Value = "Dark",
	Callback = function(option)
		Windui:SetTheme(option)
		Config:Save()
	end,
})

local loadToggle = Settings:Toggle({
	Title = "Auto Load Config",
	Desc = "Load settings automatically on startup",
	Value = isfile(loadFlag),
	Callback = function(state)
		if state then
			writefile(loadFlag, "")
		else
			delfile(loadFlag)
		end
	end,
})

local saveToggle = Settings:Toggle({
	Title = "Auto Save Config",
	Desc = "Save settings automatically when changed",
	Value = isfile(saveFlag),
	Callback = function(state)
		if state then
			writefile(saveFlag, "")
		else
			delfile(saveFlag)
		end
	end,
})

Settings:Section({
	Title = "Credits",
})

local gooseCredit = Settings:Paragraph({
	Title = "Goose",
	Desc = "The script developer, if you encounter any issues please report them at https://github.com/goose-birb/lua-buffoonery/issues",
})

local iyCredit = Settings:Paragraph({
	Title = "The Infinite Yield Team",
	Desc = "The ESP functionality is basically just an Infinite Yield wrapper with extra steps.",
})

local footagesusCredit = Settings:Paragraph({
	Title = "Footagesus",
	Desc = "The main developer of WindUI, a bleeding-edge UI library for Roblox.",
})

player.CharacterAdded:Connect(handleTracks)
if player.Character then
	handleTracks()
end

default:Set("asset", asset)
default:Set("themes", themes)
for _, element in pairs(Elements) do
	default:Register(element.Title, element)
end

Window:SelectTab(1)
if isfile(loadFlag) then
	local data = default:Load()
	asset = data.asset
	themes = data.themes

	for _, element in pairs(Elements) do
		if element.__type == "Dropdown" then
			element.Callback(element.Value)
		end
	end
end

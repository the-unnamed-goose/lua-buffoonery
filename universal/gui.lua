-- This file is licensed under the Perl Artistic License License. See https://dev.perl.org/licenses/artistic.html for more details.
local Players = game:GetService("Players")
local Input = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Windui = loadstring(
	isfile("Wildcard/windui.lua") and readfile("Wildcard/windui.lua")
		or game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua")
)()
--local Repository = "https://raw.githubusercontent.com/goose-birb/lua-buffoonery/master/"
local Repository = "http://localhost:8000/"

getgenv().aimConfig = getgenv().aimConfig
	or {
		enabled = false,
		targetPart = "Head",
		aimMode = "camera",
		fovDeg = 25,
		triggerFovDeg = 2,
		smoothness = 0.25,
		prediction = 0.02,
		maxDistance = 500,
		jitterEnabled = true,
		jitterIntensity = 0.3,
		jitterFrequency = 2.0,
		jitterPattern = "circular",
		jitterScale = 0.5,
		maxJitterOffset = 3.0,
		useRay = true,
		respectTeams = false,
		lockCamera = true,
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

getgenv().bypassConfig = getgenv().bypassConfig
	or {
		enabled = false,
		core = true,
		memory = true,
		market = true,
		parent = true,
		garbage = true,
		message = true,
		analytics = true,
		property = false,

		raw = false,
		debug = false,
		proxy = false,
		memoryleak = false,
		environment = false,
	}

local Window = Windui:CreateWindow({
	Title = "Wildcard",
	Icon = "asterisk",
	Author = "by Le Honk",
	Folder = "Wildcard",
	Theme = "Dark",
	Size = UDim2.fromOffset(580, 100),
	Resizable = true,
	Transparent = true,
})

local Config = Window.ConfigManager
local default = Config:CreateConfig("default")
local saveFlag = Window.Folder .. "/config/autosave"
local loadFlag = Window.Folder .. "/config/autoload"

local asset = {}
local animation = {}
local emotes = { "Press to try and refresh" }
local resumeAnimation = {}
local animator
local track

local player = Players.LocalPlayer
local nameList = {}
local isCapturing = false
local connections = {}
local elementCache = {}

local function warnUser()
	Windui:Notify({
		Title = "Warning",
		Content = "Changing the default config might open you up to detections and or loss of functionality, proceed with caution!",
		Duration = 6,
		Icon = "triangle-alert",
	})
end

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

local function getElementPath(element)
	local path = {}
	local current = element
	while current and current ~= game do
		table.insert(path, 1, current.Name)
		current = current.Parent
	end
	return table.concat(path, ".")
end

local function connectElement(element)
	if isElement(element) then
		local connection
		local className = element.ClassName
		local elementPath = getElementPath(element)

		if className == "TextButton" or className == "ImageButton" or className == "Tool" then
			connection = element.Activated:Connect(function()
				if isCapturing then
					isCapturing = false
					if not elementCache[elementPath] then
						local displayName
						if className == "TextButton" or className == "ImageButton" then
							displayName = "[BTN] " .. element.Name
						elseif className == "Tool" then
							displayName = "[TOOL] " .. element.Name
						end
						elementCache[elementPath] = {
							element = element,
							displayName = displayName,
							path = elementPath
						}
						table.insert(nameList, displayName)

						getgenv().aimConfig.triggerAction = elementPath
					end

					Window:Open()
				end
			end)
		elseif className == "ClickDetector" then
			connection = element.MouseClick:Connect(function()
				if isCapturing then
					isCapturing = false
					if not elementCache[elementPath] then
						local displayName = "[CLK] " .. element.Name
						if element.Parent then
							displayName = displayName .. " (on " .. element.Parent.Name .. ")"
						end
						elementCache[elementPath] = {
							element = element,
							displayName = displayName,
							path = elementPath
						}
						table.insert(nameList, displayName)

						getgenv().aimConfig.triggerAction = elementPath
					end

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

local function resolveElement(path)
	if elementCache[path] and elementCache[path].element and elementCache[path].element.Parent then
		return elementCache[path].element
	end
	
	local current = game
	for part in path:gmatch("[^%.]+") do
		current = current:FindFirstChild(part)
		if not current then
			return nil
		end
	end
	
	if isElement(current) then
		elementCache[path] = {
			element = current,
			displayName = elementCache[path] and elementCache[path].displayName or current.Name,
			path = path
		}
		return current
	end
	
	return nil
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

local function updateTriggerAction()
	if getgenv().aimConfig.triggerAction and type(getgenv().aimConfig.triggerAction) == "string" then
		local element = resolveElement(getgenv().aimConfig.triggerAction)
		if element then
			getgenv().aimConfig.triggerAction = element
		end
	end
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

	local cache = Window.Folder .. "/" .. file
	local content = isfile(cache) and readfile(cache)
	if not content then
		content = game:HttpGet(Repository .. file)
		writefile(cache, content)
	end
	
	_, Modules[file] = pcall(loadstring(content))
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

Aim:Toggle({
	Title = "Aim Bot",
	Desc = "Enable/Disable AimBot",
	Value = getgenv().aimConfig.enabled,
	Callback = function(state)
		getgenv().aimConfig.enabled = state
		if not state then
			Modules:Unload("universal/aimbot.lua")
			return
		end
		Modules:Load("universal/aimbot.lua")
		Config:Save()
	end,
})

Aim:Dropdown({
	Title = "Aim Mode",
	Values = { "camera", "mouse", "character" },
	Value = getgenv().aimConfig.aimMode,
	Callback = function(option)
		getgenv().aimConfig.aimMode = option
		if option == "character" then
			Windui:Notify({
				Title = "Info",
				Content = "Character mode may be detectable in some games. Use with caution.",
				Duration = 5,
				Icon = "circle-alert",
			})
		end
		Config:Save()
	end,
})

Aim:Slider({
	Title = "FOV Degrees",
	Step = 1,
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

Aim:Slider({
	Title = "Trigger FOV Degrees",
	Step = 1,
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

Aim:Slider({
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

Aim:Slider({
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

Aim:Slider({
	Title = "Max Distance",
	Step = 1,
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

Aim:Dropdown({
	Title = "Target Part",
	Values = getParts(),
	Value = getgenv().aimConfig.targetPart,
	Callback = function(option)
		getgenv().aimConfig.targetPart = option
		Config:Save()
	end,
})

Aim:Toggle({
	Title = "Visibility Check",
	Desc = "Only target visible enemies",
	Value = getgenv().aimConfig.useRay,
	Callback = function(state)
		getgenv().aimConfig.useRay = state
		Config:Save()
	end,
})

Aim:Toggle({
	Title = "Team Check",
	Desc = "Don't target teammates",
	Value = getgenv().aimConfig.respectTeams,
	Callback = function(state)
		getgenv().aimConfig.respectTeams = state
		Config:Save()
	end,
})

Aim:Toggle({
	Title = "Lock Camera",
	Desc = "Lock camera to target when aiming",
	Value = getgenv().aimConfig.lockCamera,
	Callback = function(state)
		getgenv().aimConfig.lockCamera = state
		Config:Save()
	end,
})

Aim:Section({
	Title = "Jitter Settings",
})

Aim:Toggle({
	Title = "Jitter",
	Desc = "Add random movement to aim",
	Value = getgenv().aimConfig.jitterEnabled,
	Callback = function(state)
		getgenv().aimConfig.jitterEnabled = state
		Config:Save()
	end,
})

Aim:Slider({
	Title = "Jitter Intensity",
	Step = 0.01,
	Value = {
		Min = 0,
		Max = 1,
		Default = getgenv().aimConfig.jitterIntensity,
	},
	Callback = function(val)
		getgenv().aimConfig.jitterIntensity = tonumber(val)
		Config:Save()
	end,
})

Aim:Slider({
	Title = "Jitter Frequency",
	Step = 0.1,
	Value = {
		Min = 0.1,
		Max = 10,
		Default = getgenv().aimConfig.jitterFrequency,
	},
	Callback = function(val)
		getgenv().aimConfig.jitterFrequency = tonumber(val)
		Config:Save()
	end,
})

Aim:Dropdown({
	Title = "Jitter Pattern",
	Values = { "circular", "random", "sine", "square" },
	Value = getgenv().aimConfig.jitterPattern,
	Callback = function(option)
		getgenv().aimConfig.jitterPattern = option
		Config:Save()
	end,
})

Aim:Slider({
	Title = "Jitter Scale",
	Step = 0.01,
	Value = {
		Min = 0,
		Max = 2,
		Default = getgenv().aimConfig.jitterScale,
	},
	Callback = function(val)
		getgenv().aimConfig.jitterScale = tonumber(val)
		Config:Save()
	end,
})

Aim:Slider({
	Title = "Max Jitter Offset",
	Step = 0.1,
	Value = {
		Min = 0,
		Max = 10,
		Default = getgenv().aimConfig.maxJitterOffset,
	},
	Callback = function(val)
		getgenv().aimConfig.maxJitterOffset = tonumber(val)
		Config:Save()
	end,
})

Aim:Section({
	Title = "Trigger Bot",
})

Aim:Toggle({
	Title = "Trigger Bot",
	Desc = "Enable/Disable automatic firing",
	Value = getgenv().aimConfig.triggerBot,
	Callback = function(state)
		getgenv().aimConfig.triggerBot = state
		Config:Save()
	end,
})

Aim:Dropdown({
	Title = "Trigger Mode",
	Values = { "mouse1", "mouse2", "button", "closure" },
	Value = getgenv().aimConfig.triggerMode,
	Callback = function(option)
		getgenv().aimConfig.triggerMode = option
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
		Config:Save()
	end,
})

Aim:Button({
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

local triggerDropValues = { "Press 'Capture Button' first" }
if nameList and #nameList > 0 then
	triggerDropValues = nameList
end

Aim:Dropdown({
	Title = "Trigger Button",
	Values = triggerDropValues,
	Value = getgenv().aimConfig.triggerAction,
	Callback = function(option)
		if elementCache then
			for _, cached in pairs(elementCache) do
				if cached.displayName == option then
					getgenv().aimConfig.triggerAction = cached.path
					break
				end
			end
		end
		Config:Save()
	end,
})

local Bypass = Window:Tab({
	Title = "Bypasses",
	Icon = "shield-user",
	Locked = false,
})

Bypass:Section({
	Title = "Generals",
})

Bypass:Toggle({
	Title = "Load Bypasses",
	Desc = "This CANNOT be disabled once toggled",
	Value = getgenv().bypassConfig.enabled,
	Callback = function(state)
		getgenv().bypassConfig.enabled = state
		if not state then
			Modules:Unload("universal/bypass.lua")
			return
		end
		Modules:Load("universal/bypass.lua")
		Config:Save()
	end,
})

local bypassToggles = {
	{ key = "core", title = "CoreGUI Asset Preload" },
	{ key = "memory", title = "Memory Monitoring" },
	{ key = "market", title = "MarketService Buffoonery" },
	{ key = "parent", title = "Hidden LocalScripts" },
	{ key = "garbage", title = "Garbage Collector Monitoring" },
	{ key = "message", title = "LogService Monitoring" },
	{ key = "analytics", title = "AnalyticsService C2S" },
	{ key = "property", title = "Property Change Events" },
}

for _, toggleConfig in ipairs(bypassToggles) do
	Bypass:Toggle({
		Title = toggleConfig.title,
		Value = getgenv().bypassConfig[toggleConfig.key],
		Callback = function(state)
			if getgenv().bypassConfig[toggleConfig.key] ~= state then
				warnUser()
			end
			getgenv().bypassConfig[toggleConfig.key] = state
			Config:Save()
		end,
	})
end

Bypass:Section({
	Title = "Executor Specific",
})

local executorToggles = {
	{ key = "raw", title = "rawget" },
	{ key = "debug", title = "debug" },
	{ key = "proxy", title = "proxy" },
	{ key = "memoryleak", title = "memoryleak" },
	{ key = "environment", title = "environment" },
}

for _, toggleConfig in ipairs(executorToggles) do
	Bypass:Toggle({
		Title = toggleConfig.title,
		Value = getgenv().bypassConfig[toggleConfig.key],
		Callback = function(state)
			if getgenv().bypassConfig[toggleConfig.key] ~= state then
				warnUser()
			end
			getgenv().bypassConfig[toggleConfig.key] = state
			Config:Save()
		end,
	})
end

local Visuals = Window:Tab({
	Title = "Visuals",
	Icon = "eye",
	Locked = false,
})

Visuals:Section({
	Title = "Players",
})

Visuals:Toggle({
	Title = "Player ESP",
	Desc = "Enable/Disable the ESP functionality",
	Value = getgenv().espConfig.enabled,
	Callback = function(state)
		getgenv().espConfig.enabled = state
		if not state then
			Modules:Unload("universal/esp.lua")
			return
		end
		Modules:Load("universal/esp.lua")
		Config:Save()
	end,
})

local espToggles = {
	{ key = "showNames", title = "Show Names", desc = "Whether or not the ESP should display name boards" },
	{ key = "showDistance", title = "Show Distance", desc = "Whether or not the ESP should display the player distance on the name board" },
	{ key = "showHealth", title = "Show Health", desc = "Whether or not the ESP should display the player health on the name board" },
	{ key = "useTeamColor", title = "Team Colors", desc = "Whether or not the ESP highlights should use the team colors" },
}

for _, toggleConfig in ipairs(espToggles) do
	Visuals:Toggle({
		Title = toggleConfig.title,
		Desc = toggleConfig.desc,
		Value = getgenv().espConfig[toggleConfig.key],
		Callback = function(state)
			getgenv().espConfig[toggleConfig.key] = state
			Config:Save()
		end,
	})
end

Visuals:Dropdown({
	Title = "ESP Mode",
	Values = { "Highlight", "Xray" },
	Value = getgenv().espConfig.mode,
	Callback = function(option)
		getgenv().espConfig.mode = option
		Config:Save()
	end,
})

Visuals:Slider({
	Title = "Highlight Fill Transparency",
	Step = 0.1,
	Value = {
		Min = 0,
		Max = 2,
		Default = getgenv().espConfig.fillTransparency,
	},
	Callback = function(val)
		getgenv().espConfig.fillTransparency = tonumber(val)
		Config:Save()
	end,
})

Visuals:Slider({
	Title = "Highlight Outline Transparency",
	Step = 0.1,
	Value = {
		Min = 0,
		Max = 2,
		Default = getgenv().espConfig.outlineTransparency,
	},
	Callback = function(val)
		getgenv().espConfig.outlineTransparency = tonumber(val)
		Config:Save()
	end,
})

Visuals:Slider({
	Title = "Name Board Text Size",
	Step = 1,
	Value = {
		Min = 1,
		Max = 30,
		Default = getgenv().espConfig.textSize,
	},
	Callback = function(val)
		getgenv().espConfig.textSize = tonumber(val)
		Config:Save()
	end,
})

Visuals:Colorpicker({
	Title = "Teammate Highlight Color",
	Default = getgenv().espConfig.teammateColor,
	Callback = function(color)
		getgenv().espConfig.teammateColor = color
		Config:Save()
	end,
})

Visuals:Colorpicker({
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
Visuals:Dropdown({
	Title = "Select Emote",
	Values = emotes,
	Callback = function(option)
		resumeAnimation = option
		playAnimation(option)
		Config:Save()
	end,
})

Visuals:Input({
	Title = "Add Emote",
	Desc = "Adds an emote from outside the game",
	Type = "Input",
	Placeholder = "rbxassetid://1949963001",
	Callback = function(input)
		table.insert(asset, input)
		refreshAnimations()
		Config:Save()
	end,
})

Visuals:Keybind({
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

Settings:Keybind({
	Title = "Window toggle",
	Desc = "Keybind to toggle ui",
	Value = "X",
	Callback = function(key)
		Window:SetToggleKey(Enum.KeyCode[key])
		Config:Save()
	end,
})

local themes = {}
for theme in pairs(Windui:GetThemes()) do
	table.insert(themes, theme)
end
table.sort(themes)

Settings:Dropdown({
	Title = "Theme",
	Values = themes,
	Callback = function(option)
		Windui:SetTheme(option)
		Config:Save()
	end,
})

Settings:Toggle({
	Title = "Auto Load Config",
	Desc = "Load settings automatically on startup",
	Value = isfile(loadFlag),
	Callback = function(state)
		if state then
			writefile(loadFlag, "")
		else
			delfile(loadFlag)
		end
		Config:Save()
	end,
})

Settings:Toggle({
	Title = "Auto Save Config",
	Desc = "Save settings automatically when changed",
	Value = isfile(saveFlag),
	Callback = function(state)
		if state then
			writefile(saveFlag, "")
		else
			delfile(saveFlag)
		end
		Config:Save()
	end,
})

Settings:Section({
	Title = "Credits",
})

Settings:Paragraph({
	Title = "Goose",
	Desc = "The script developer, if you encounter any issues please report them at https://github.com/goose-birb/lua-buffoonery/issues",
	Buttons = {
	       {
            Icon = "messages-square",
            Title = "Discord Server",
            Callback = function() setclipboard("https://discord.gg/r3btjAHPVh") end,
        },
        {
            Icon = "github",
            Title = "Issue Tracker",
            Callback = function() setclipboard("https://github.com/goose-birb/lua-buffoonery/issues") end,
        }
    }
})

Settings:Paragraph({
	Title = "The Infinite Yield Team",
	Desc = "The ESP functionality is basically just an Infinite Yield wrapper with extra steps.",
})

Settings:Paragraph({
	Title = "Footagesus",
	Desc = "The main developer of WindUI, a bleeding-edge UI library for Roblox.",
})

player.CharacterAdded:Connect(handleTracks)
if player.Character then
	handleTracks()
end

RunService.Heartbeat:Connect(function()
	updateTriggerAction()
end)

default:Set("asset", asset)
default:Set("themes", themes)
Window:SelectTab(1)

do
	local version = Window.Folder .. "/" .. "version"
	local current = isfile(version) and readfile(version)
	local latest = game:HttpGet(Repository .. "version")
	if current and current ~= latest then
		Windui:Popup({
			Title = "Version Manager",
			Icon = "download",
			Content = "A new Wildcard version is available, do you wish to install it?",
			Buttons = {
				{
					Title = "Remind me later",
					Callback = function() end,
					Variant = "Tertiary",
				},
				{
					Title = "Yes",
					Callback = function()
						writefile(version, latest)
					end,
					Variant = "Primary",
				},
			},
		})
	elseif not current then
	  writefile(version, latest)
	end
end
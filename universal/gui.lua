-- This file is licensed under the Perl Artistic License License. See https://dev.perl.org/licenses/artistic.html for more details.
local Project = "Wildcard"
local Folder = "WindUI/" .. Project .. "/"
local Assets = Folder .. "assets/"
--local Repository = "https://raw.githubusercontent.com/the-unnamed-goose/lua-buffoonery/master/"
local Repository = "http://localhost:8000/"

local Modules = {}
Modules.State = {}
function Modules.Fetch(file, url)
	local cache = Assets .. file
	local content = isfile(cache) and readfile(cache)
	if not content or content == "" then
		content = url and game:HttpGet(url) or game:HttpGet(Repository .. file)
		writefile(cache, content)
	end

	return content
end

function Modules.Load(file, url)
	if not Modules[file] then
		Modules[file] = loadstring(Modules.Fetch(file, url))()
	end

	local success = pcall(function()
		Modules[file].Load()
	end)
	if not success then
		warn("Failed to load module: " .. file)
	end

	Modules.State[file] = true
	return Modules[file]
end

function Modules.Unload(file)
	if not Modules[file] or not Modules[file].Unload then
		return
	end

	local success = pcall(function()
		Modules[file].Unload()
	end)
	if not success then
		warn("Failed to unload module: " .. file)
	end
	Modules.State[file] = false
end

local Wind = Modules.Load("wind.lua", "https://github.com/Footagesus/WindUI/releases/latest/download/main.lua")
local Players = game:GetService("Players")
local Input = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

getgenv().aimConfig = {
	enabled = false,
	targetPart = "Head",
	aimMode = "camera",
	runPriority = 10,
	useHook = false,
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
	rspectTeams = false,
	lockCamera = true,
	triggerBot = true,
	triggerMode = "button",
	triggerAction = nil,
	triggerClosure = nil,
}

getgenv().espConfig = {
	enabled = false,
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

getgenv().bypassConfig = {
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

getgenv().silentConfig = getgenv().silentConfig or {
	enabled = false,
}

local Window = Wind:CreateWindow({
	Title = "Wildcard",
	Icon = "asterisk",
	Author = "by Le Honk",
	Folder = Project,
	Theme = "Dark",
	Size = UDim2.fromOffset(580, 100),
	Resizable = true,
	Transparent = true,
})

local Config = Window.ConfigManager
function Config.Save()
	if isfile(saveFlag) then
		default:Save()
	end
end

local Utils = Modules.Load("universal/utils.lua")
local default = Config:CreateConfig("default")
local saveFlag = Folder .. "/flags/autosave"
local loadFlag = Folder .. "/flags/autoload"

local function warnUser()
	Wind:Notify({
		Title = "Warning",
		Content = "Changing the default config might open you up to detections and or loss of functionality, proceed with caution!",
		Duration = 6,
		Icon = "triangle-alert",
	})
end

local function moduleToggle(tab, title, section, module)
	tab:Toggle({
		Flag = section,
		Title = title,
		Value = getgenv()[section].enabled,
		Callback = function(state)
			getgenv()[section].enabled = state
			if not state then
				Modules.Unload(module)
			else
				Modules.Load(module)
			end
			Config:Save()
		end,
	})
end

local function configToggle(tab, title, desc, section, key)
	tab:Toggle({
		Flag = key,
		Title = title,
		Desc = desc,
		Value = getgenv()[section][key],
		Callback = function(state)
			getgenv()[section][key] = state
			Config:Save()
		end,
	})
end

local function configSlider(tab, title, desc, section, key, min, max, step, default)
	tab:Slider({
		Flag = key,
		Title = title,
		Desc = desc,
		Step = step,
		Value = {
			Min = min,
			Max = max,
			Default = getgenv()[section][key] or default,
		},
		Callback = function(val)
			getgenv()[section][key] = tonumber(val)
			Config:Save()
		end,
	})
end

local function configDrop(tab, title, desc, section, key, values)
	tab:Dropdown({
		Flag = key,
		Title = title,
		Desc = desc,
		Values = values,
		Value = getgenv()[section][key],
		Callback = function(selected)
			getgenv()[section][key] = selected
			Config:Save()
		end,
	})
end

do
	local Silent = Window:Tab({
		Title = "Silent Aim",
		Icon = "award",
		Locked = false,
	})

	moduleToggle(Silent, "Silent Aim", "silentConfig", "universal/silent.lua")
end

do
	local Aim = Window:Tab({
		Title = "Aim Bot",
		Icon = "crosshair",
		Locked = false,
	})

	Aim:Section({ Title = "General" })
	moduleToggle(Aim, "Aim Bot", "aimConfig", "universal/aim.lua")
	configToggle(
		Aim,
		"Camera Lock",
		"Disable camera movement when aiming, can be easily detected by anticheats tho it can fix some issues",
		"aimConfig",
		"useHook"
	)
	configDrop(Aim, "Aim Mode", nil, "aimConfig", "aimMode", { "camera", "mouse" })
	configSlider(Aim, "FOV Degrees", nil, "aimConfig", "fovDeg", 1, 90, 1, 25)
	configSlider(Aim, "Trigger FOV Degrees", nil, "aimConfig", "triggerFovDeg", 1, 30, 1, 2)
	configSlider(Aim, "Smoothness", nil, "aimConfig", "smoothness", 0.01, 1, 0.01, 0.25)
	configSlider(Aim, "Prediction", nil, "aimConfig", "prediction", 0, 1, 0.01, 0.02)
	configSlider(
		Aim,
		"Run Priority",
		"Needs the aimbot to be restarted before applying, the lower the better",
		"aimConfig",
		"runPriority",
		1,
		10,
		1,
		10
	)
	configSlider(Aim, "Max Distance", nil, "aimConfig", "maxDistance", 50, 2000, 1, 500)
	configDrop(Aim, "Target Part", nil, "aimConfig", "targetPart", Utils.getParts())
	configToggle(Aim, "Visibility Check", "Only target visible enemies", "aimConfig", "useRay")
	configToggle(Aim, "Team Check", "Don't target teammates", "aimConfig", "respectTeams")
	configToggle(Aim, "Lock Camera", "Lock camera to target when aiming", "aimConfig", "lockCamera")

	Aim:Section({ Title = "Jitter Settings" })
	configToggle(Aim, "Jitter", "Add random movement to aim", "aimConfig", "jitterEnabled")
	configSlider(Aim, "Jitter Intensity", nil, "aimConfig", "jitterIntensity", 0, 1, 0.01, 0.3)
	configSlider(Aim, "Jitter Frequency", nil, "aimConfig", "jitterFrequency", 0.1, 10, 0.1, 2.0)
	configDrop(Aim, "Jitter Pattern", nil, "aimConfig", "jitterPattern", { "circular", "random", "sine", "square" })
	configSlider(Aim, "Jitter Scale", nil, "aimConfig", "jitterScale", 0, 2, 0.01, 0.5)
	configSlider(Aim, "Max Jitter Offset", nil, "aimConfig", "maxJitterOffset", 0, 10, 0.1, 3.0)

	Aim:Section({ Title = "Trigger Bot" })
	configToggle(Aim, "Trigger Bot", "Enable/Disable automatic firing", "aimConfig", "triggerBot")

	Aim:Dropdown({
		Title = "Trigger Mode",
		Values = { "mouse1", "mouse2", "button", "closure" },
		Value = getgenv().aimConfig.triggerMode,
		Callback = function(option)
			getgenv().aimConfig.triggerMode = option
			if string.find(option, "mouse") and not Input.MouseEnabled then
				Wind:Notify({
					Title = "Warning",
					Content = "Your game input might interrupt when triggering as it will change the current input type to mouse and keyboard.",
					Duration = 4,
					Icon = "triangle-alert",
				})
			end

			if option == "closure" then
				Wind:Notify({
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
			Utils.isCapturing = true
			Window:Close()

			Utils.scanElements()
			Wind:Notify({
				Title = "Button Selection",
				Content = "Press a button to select it",
				Duration = 4,
			})
		end,
	})

	local triggerDropValues = { "Press 'Capture Button' first" }
	if Utils.nameList and #Utils.nameList > 0 then
		triggerDropValues = Utils.nameList
	end

	Aim:Dropdown({
		Title = "Trigger Button",
		Values = triggerDropValues,
		Value = getgenv().aimConfig.triggerAction,
		Callback = function(option)
			if Utils.elementCache then
				for _, cached in pairs(Utils.elementCache) do
					if cached.displayName == option then
						getgenv().aimConfig.triggerAction = cached.path
						break
					end
				end
			end
			Config:Save()
		end,
	})
end

do
	local Bypass = Window:Tab({
		Title = "Bypasses",
		Icon = "shield-user",
		Locked = false,
	})

	Bypass:Section({ Title = "General" })
	Bypass:Toggle({
		Flag = "bypassConfig",
		Title = "Load Bypasses",
		Value = getgenv().bypassConfig.enabled,
		Callback = function(state)
			getgenv().bypassConfig.enabled = state
			if state then
			  Bypass:LockAll()
				Modules.Load("universal/bypass.lua")
			end
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

	Bypass:Section({ Title = "Executor Specific" })
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
end

do
	local Visuals = Window:Tab({
		Title = "Visuals",
		Icon = "eye",
		Locked = false,
	})

	Visuals:Section({ Title = "Players" })
	moduleToggle(Visuals, "Player ESP", "espConfig", "universal/esp.lua")

	local espToggles = {
		{ key = "showNames", title = "Show Names", desc = "Whether or not the ESP should display name boards" },
		{
			key = "showDistance",
			title = "Show Distance",
			desc = "Whether or not the ESP should display the player distance on the name board",
		},
		{
			key = "showHealth",
			title = "Show Health",
			desc = "Whether or not the ESP should display the player health on the name board",
		},
		{
			key = "useTeamColor",
			title = "Team Colors",
			desc = "Whether or not the ESP highlights should use the team colors",
		},
	}
	for _, toggleConfig in ipairs(espToggles) do
		configToggle(Visuals, toggleConfig.title, toggleConfig.desc, "espConfig", toggleConfig.key)
	end

	configSlider(Visuals, "Highlight Fill Transparency", nil, "espConfig", "fillTransparency", 0, 2, 0.1, 0.5)
	configSlider(Visuals, "Highlight Outline Transparency", nil, "espConfig", "outlineTransparency", 0, 2, 0.1, 0)
	configSlider(Visuals, "Name Board Text Size", nil, "espConfig", "textSize", 1, 30, 1, 14)

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

	Visuals:Section({ Title = "Emotes" })
	Utils.refreshAnimations()
	Visuals:Dropdown({
		Title = "Select Emote",
		Values = Utils.emotes,
		Callback = function(option)
			Utils.resumeAnimation = option
			Utils.playAnimation(option)
			Config:Save()
		end,
	})

	Visuals:Input({
		Title = "Add Emote",
		Desc = "Adds an emote from outside the game",
		Type = "Input",
		Placeholder = "rbxassetid://1949963001",
		Callback = function(input)
			table.insert(Utils.asset, input)
			Utils.refreshAnimations()
			Config:Save()
		end,
	})

	Visuals:Keybind({
		Title = "Keybind Emote",
		Desc = "Keybind to play the selected emote",
		Value = "X",
		Callback = function()
			Utils.playAnimation(Utils.resumeAnimation)
			Config:Save()
		end,
	})
end

do
	local Settings = Window:Tab({
		Title = "Settings",
		Icon = "settings",
		Locked = false,
	})

	Settings:Section({ Title = "Configuration" })
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
	for theme in Wind:GetThemes() do
		table.insert(themes, theme)
	end
	table.sort(themes)

	Settings:Dropdown({
		Title = "Theme",
		Values = themes,
		Callback = function(option)
			Wind:SetTheme(option)
			Config:Save()
		end,
	})

	Settings:Input({
		Title = "Profile Name",
		Desc = "Creates a new profile, if needed",
		Type = "Input",
		Placeholder = "default",
		Callback = function(input)
			default = Config:CreateConfig(input)
		end,
	})

	local profiles = {}
	for _, profile in listfiles(Assets) do
		table.insert(profiles, string.split(profile, ".")[1])
	end
	table.sort(profiles)

	Settings:Dropdown({
		Title = "Select Profile",
		Values = profiles,
		Callback = function(option)
			default = Config:CreateConfig(option)
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

	Settings:Section({ Title = "Credits" })
	Settings:Paragraph({
		Title = "Goose",
		Desc = "The script developer, if you encounter any issues please report them bellow",
		Buttons = {
			{
				Icon = "messages-square",
				Title = "Discord Server",
				Callback = function()
					setclipboard("https://dsc.gg/lua-buffoonery")
				end,
			},
			{
				Icon = "github",
				Title = "Issue Tracker",
				Callback = function()
					setclipboard("https://github.com/goose-birb/lua-buffoonery/issues")
				end,
			},
		},
	})

	Settings:Paragraph({
		Title = "Averiias",
		Desc = "My silent aim heavily draws from theirs, with some improved logic of course.",
	})

	Settings:Paragraph({
		Title = "Zyletrophene",
		Desc = "My anticheat bypass is originally based off of theirs.",
	})

	Settings:Paragraph({
		Title = "Footagesus",
		Desc = "The main developer of Wind, a bleeding-edge UI library for Roblox.",
	})
end

default:Set("asset", Utils.asset)
default:Set("themes", themes)
Window:SelectTab(1)

do
	local version = Window.Folder .. "/" .. "version"
	local current = isfile(version) and readfile(version)
	local latest = game:HttpGet(Repository .. "version")
	if current and current ~= latest then
		Window:Close()
		Wind:Popup({
			Title = "Version Manager",
			Icon = "download",
			Content = "A new Wildcard version is available, do you wish to install it?",
			Buttons = {
				{
					Title = "Remind me later",
					Callback = Window.Open,
					Variant = "Tertiary",
				},
				{
					Title = "Yes",
					Callback = function()
						writefile(version, latest)
						delfolder(Assets)
						Window:Open()
					end,
					Variant = "Primary",
				},
			},
		})
	elseif not current then
		writefile(version, latest)
	end
end

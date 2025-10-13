-- This file is licensed under the Perl Artistic License License. See https://dev.perl.org/licenses/artistic.html for more details.
local Project = "MVSD"
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

local Wind = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local Players = game:GetService("Players")
local Replicated = game:GetService("ReplicatedStorage")

getgenv().aimConfig = {
	MAX_DISTANCE = 250,
	MAX_VELOCITY = 40,
	VISIBLE_PARTS = 4,
	CAMERA_CAST = true,
	FOV_CHECK = true,
	REACTION_TIME = 0.18,
	ACTION_TIME = 0.3,
	AUTO_EQUIP = true,
	EQUIP_LOOP = 0.3,
	NATIVE_UI = true,
	DEVIATION_ENABLED = true,
	BASE_DEVIATION = 2.10,
	DISTANCE_FACTOR = 1,
	VELOCITY_FACTOR = 1.20,
	ACCURACY_BUILDUP = 0.5,
	MIN_DEVIATION = 1,
	RAYCAST_DISTANCE = 1000,
}

getgenv().espConfig = {
	enabled = false,
	teammates = true,
	enemies = true,
}

getgenv().killConfig = {
	gun = false,
	knife = false,
	gunLoop = false,
	knifeLoop = false,
}

getgenv().controllerConfig = {
	enabled = false,
	renewer = true,
	knife = true,
	gun = true,
}

getgenv().miscConfig = {
	antiCrash = true,
	lowPoly = false,
	autoSpin = false,
}

local Window = Wind:CreateWindow({
	Title = "RC 5",
	Icon = "square-function",
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

local Utils = {}
Utils.asset = {}
Utils.animation = {}
Utils.emotes = { "Press to try and refresh" }
Utils.resumeAnimation = ""
Utils.animator = nil
Utils.track = nil

function Utils.refreshAnimations()
	local player = Players.LocalPlayer
	if not player.Character then
		return
	end

	Utils.animation = {}
	Utils.emotes = {}

	for _, obj in ipairs(game:GetDescendants()) do
		local name = obj.Name
		if obj:IsA("Animation") and not Utils.animation[name] then
			Utils.animation[name] = obj
			table.insert(Utils.emotes, name)
		end
	end

	for _, assetid in ipairs(Utils.asset) do
		if not Utils.animation[assetid] then
			local instance = Instance.new("Animation")
			instance.AnimationId = assetid
			Utils.animation[assetid] = instance
			table.insert(Utils.emotes, assetid)
		end
	end

	table.sort(Utils.emotes)
end

function Utils.playAnimation(name)
	if Utils.track then
		Utils.track:Stop()
	end

	if Utils.animation[name] then
		Utils.track = Utils.animator:LoadAnimation(Utils.animation[name])
		Utils.track:Play()
	end
end

function Utils.handleTracks()
	local player = Players.LocalPlayer
	local humanoid = player.Character:WaitForChild("Humanoid")
	Utils.animator = humanoid:WaitForChild("Animator")

	humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
		if Utils.track and humanoid.MoveDirection.Magnitude > 0 then
			Utils.track:Stop()
			Utils.track = nil
		end
	end)
end

local default = Config:CreateConfig("default")
local saveFlag = Folder .. "/flags/autosave"
local loadFlag = Folder .. "/flags/autoload"

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

local function configSlider(tab, title, desc, section, key, min, max, step, defaultVal)
	tab:Slider({
		Flag = key,
		Title = title,
		Desc = desc,
		Step = step,
		Value = {
			Min = min,
			Max = max,
			Default = getgenv()[section][key] or defaultVal,
		},
		Callback = function(val)
			getgenv()[section][key] = tonumber(val)
			Config:Save()
		end,
	})
end

do
	local Aim = Window:Tab({
		Title = "Aim Bot",
		Icon = "focus",
		Locked = false,
	})

	Aim:Section({ Title = "General" })
	configToggle(Aim, "Aim Bot Status", "Enable/Disable the aim bot", "aimConfig", "enabled")
	configToggle(
		Aim,
		"Native Raycast Method",
		"Whether or not to check player visibility in the same way that the game does",
		"aimConfig",
		"CAMERA_CAST"
	)
	configToggle(
		Aim,
		"FOV Check",
		"Whether or not to check if the target is in the current fov before selecting it",
		"aimConfig",
		"FOV_CHECK"
	)
	configToggle(
		Aim,
		"Switch Weapons",
		"Whether or not the script should automatically switch or equip the best available weapon",
		"aimConfig",
		"AUTO_EQUIP"
	)
	configToggle(
		Aim,
		"Native User Interface",
		"Whether or not the script should render the gun cooldown and tool equip highlights",
		"aimConfig",
		"NATIVE_UI"
	)
	configToggle(
		Aim,
		"Aim Deviation",
		"Whether or not the script should sometimes misfire when using the gun",
		"aimConfig",
		"DEVIATION_ENABLED"
	)

	Aim:Section({ Title = "Distance & Timing" })
	configSlider(
		Aim,
		"Maximum Distance",
		"The maximum distance at which the script will no longer target enemies",
		"aimConfig",
		"MAX_DISTANCE",
		50,
		1000,
		1,
		250
	)
	configSlider(
		Aim,
		"Maximum Velocity",
		"The maximum target velocity at which the script will no longer attempt to shoot a target",
		"aimConfig",
		"MAX_VELOCITY",
		20,
		200,
		1,
		40
	)
	configSlider(
		Aim,
		"Required Visible Parts",
		"The amount of visible player parts the script will require before selecting a target",
		"aimConfig",
		"VISIBLE_PARTS",
		1,
		18,
		1,
		4
	)
	configSlider(
		Aim,
		"Reaction Time",
		"The amount of time the script will wait before attacking a given target",
		"aimConfig",
		"REACTION_TIME",
		0.01,
		1,
		0.01,
		0.18
	)
	configSlider(
		Aim,
		"Action Time",
		"The amount of time the script will wait after switching weapons before attacking",
		"aimConfig",
		"ACTION_TIME",
		0.2,
		4,
		0.01,
		0.3
	)
	configSlider(
		Aim,
		"Equip Time",
		"The amount of time the script will wait before checking what is the best weapon to equip again",
		"aimConfig",
		"EQUIP_LOOP",
		0.1,
		4,
		0.1,
		0.3
	)

	Aim:Section({ Title = "Aim Deviation Settings" })
	configSlider(
		Aim,
		"Base Deviation",
		"Base aim inaccuracy in degrees, controls how much the aim naturally deviates",
		"aimConfig",
		"BASE_DEVIATION",
		0.5,
		5,
		0.1,
		2.10
	)
	configSlider(
		Aim,
		"Distance Factor",
		"Additional deviation penalty for distance",
		"aimConfig",
		"DISTANCE_FACTOR",
		0,
		2,
		0.1,
		1
	)
	configSlider(
		Aim,
		"Velocity Factor",
		"Additional deviation penalty for moving targets",
		"aimConfig",
		"VELOCITY_FACTOR",
		0,
		2,
		0.1,
		1.20
	)
	configSlider(
		Aim,
		"Accuracy Buildup",
		"How much accuracy improves with consecutive shots",
		"aimConfig",
		"ACCURACY_BUILDUP",
		0,
		2,
		0.01,
		0.5
	)
	configSlider(
		Aim,
		"Min Deviation",
		"Minimum deviation that always remains - prevents perfect accuracy",
		"aimConfig",
		"MIN_DEVIATION",
		0.1,
		3,
		0.1,
		1
	)
end

do
	local Esp = Window:Tab({
		Title = "ESP",
		Icon = "eye",
		Locked = false,
	})

	Esp:Section({ Title = "General" })
	moduleToggle(Esp, "Player ESP", "espConfig", "mvsd/esp.lua")
	configToggle(Esp, "Display Team", "Whether or not to highlight your teammates", "espConfig", "teammates")
	configToggle(Esp, "Display Enemies", "Whether or not to highlight your enemies", "espConfig", "enemies")
end

do
	local Kill = Window:Tab({
		Title = "Auto Kill",
		Icon = "skull",
		Locked = false,
	})

	Kill:Section({ Title = "Manual Kill" })
	Kill:Button({
		Title = "[Knife] Kill All",
		Desc = "Kills all players using the knife",
		Callback = function()
			getgenv().killConfig.knife = true
			Modules.Load("mvsd/killall.lua")
			Config:Save()
		end,
	})

	Kill:Button({
		Title = "[Gun] Kill All",
		Desc = "Kills all players using the gun",
		Callback = function()
			getgenv().killConfig.gun = true
			Modules.Load("mvsd/killall.lua")
			Config:Save()
		end,
	})

	Kill:Section({ Title = "Auto Kill Loop" })
	configToggle(
		Kill,
		"[Knife] Loop Kill All",
		"Repeatedly kills all players using the knife",
		"killConfig",
		"knifeLoop"
	)
	configToggle(Kill, "[Gun] Loop Kill All", "Repeatedly kills all players using the gun", "killConfig", "gunLoop")
end

do
	local Misc = Window:Tab({
		Title = "Misc",
		Icon = "brackets",
		Locked = false,
	})

	Misc:Section({ Title = "Emotes" })
	Utils.refreshAnimations()
	Misc:Dropdown({
		Title = "Select Emote",
		Values = Utils.emotes,
		Callback = function(option)
			Utils.resumeAnimation = option
			Utils.playAnimation(option)
			Config:Save()
		end,
	})

	Misc:Input({
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

	Misc:Keybind({
		Title = "Keybind Emote",
		Desc = "Keybind to play the selected emote",
		Value = "X",
		Callback = function()
			Utils.playAnimation(Utils.resumeAnimation)
			Config:Save()
		end,
	})

	Misc:Section({ Title = "Other" })
	configToggle(Misc, "Anti Crash", "Blocks the shroud projectile from rendering", "miscConfig", "antiCrash")
	configToggle(Misc, "Low Poly", "Toggle the low poly mode", "miscConfig", "lowPoly")
	configToggle(Misc, "Auto Spin", "Automatically spin the modifier wheel", "miscConfig", "autoSpin")
end

do
	local Controller = Window:Tab({
		Title = "Controller",
		Icon = "keyboard",
		Locked = false,
	})

	Wind:Notify({
		Title = "Warning",
		Content = "The custom knife controller has no mode toggle functionality (button) on mobile.",
		Duration = 4,
		Icon = "triangle-alert",
	})

	Controller:Section({ Title = "Controller System" })
	moduleToggle(Controller, "Controller System", "controllerConfig", "mvsd/controllers/init.lua")
	configToggle(
		Controller,
		"Delete Old Controllers",
		"Should not be disabled unless you also want to disable the options below",
		"controllerConfig",
		"renewer"
	)
	configToggle(
		Controller,
		"Custom Knife Controller",
		"Uses the custom knife input handler",
		"controllerConfig",
		"knife"
	)
	configToggle(Controller, "Custom Gun Controller", "Uses the custom gun input handler", "controllerConfig", "gun")
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
		Desc = "The script developer, rewrote everything from scratch, if you encounter any issues please report them below",
		Buttons = {
			{
				Icon = "messages-square",
				Title = "Issue Tracker",
				Callback = function()
					setclipboard("https://github.com/goose-birb/lua-buffoonery/issues")
				end,
			},
		},
	})

	Settings:Paragraph({
		Title = "Footagesus",
		Desc = "The main developer of WindUI, a bleeding-edge UI library for Roblox.",
	})
end

default:Set("asset", Utils.asset)
Window:SelectTab(1)

if isfile(loadFlag) then
	local data = default:Load()
	Utils.asset = data.asset or {}
	Utils.refreshAnimations()
end

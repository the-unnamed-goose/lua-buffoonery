-- This file is licensed under the Perl Artistic License License. See https://dev.perl.org/licenses/artistic.html for more details.
local Project = "12355337193"
local Folder = "WindUI/" .. Project .. "/"
local Assets = Folder .. "assets/"
local Repository = "https://raw.githubusercontent.com/the-unnamed-goose/lua-buffoonery/master/"

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

	if Modules[file] and Modules[file].Load then
		local success = pcall(Modules[file].Load)
		if not success then
			warn("Failed to load module: " .. file)
		end
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
local Storage = game:GetService("ReplicatedStorage")

getgenv().aimConfig = getgenv().aimConfig
	or {
		maxDistance = 250,
		maxVelocity = 40,
		visibleParts = 4,
		cameraCast = true,
		fovCheck = true,
		reactionTime = 0.18,
		actionTime = 0.3,
		autoEquip = true,
		equipInterval = 0.3,
		nativeUI = true,
		deviation = true,
		baseDeviation = 2.10,
		distanceFactor = 1,
		velocityFactor = 1.20,
		accuracyBuildup = 0.5,
		minDeviation = 1,
	}

getgenv().espConfig = getgenv().espConfig or {
	teammates = true,
	enemies = true,
}

getgenv().controllers = getgenv().controllers
	or {
		knifeLocked = false,
		gunLocked = false,
		toolsLocked = false,
		gunCooldown = 0,
	}

getgenv().killConfig = getgenv().killConfig
	or {
		gunButton = false,
		knifeButton = false,
		gunLoop = false,
		knifeLoop = false,
	}

local Window = Wind:CreateWindow({
	Title = "Murderers VS Sheriffs Duels",
	Icon = "square-function",
	Author = "by Le Honk",
	Folder = Project,
	Theme = "Dark",
	Size = UDim2.fromOffset(580, 100),
	Resizable = true,
	Transparent = true,

	OpenButton = {
		CornerRadius = UDim.new(0.2, 0),
		StrokeThickness = 3,
		OnlyIcon = true,
	},
})

local Config = Window.ConfigManager
Window.CurrentConfig = Config:CreateConfig("default")
local Utils = Modules.Load("universal/utils.lua")
local saveFlag = Folder .. "/flags/autosave"
local loadFlag = Folder .. "/flags/autoload"

local player = Players.LocalPlayer
local gunToggle
local knifeToggle

function Config.Save()
	if isfile(saveFlag) and Modules.State["config"] then
		Window.CurrentConfig:Save()
	end
end

function lockToggle(origin)
	if origin == "knife" and gunToggle and gunToggle.Lock then
		gunToggle:Lock()
		return
	elseif origin == "gun" and knifeToggle and knifeToggle.Lock then
		knifeToggle:Lock()
		return
	end

	if gunToggle and gunToggle.Unlock then
		gunToggle:Unlock()
	end

	if knifeToggle and knifeToggle.Unlock then
		knifeToggle:Unlock()
	end
end

local function refreshAnimations()
	Utils.refreshAnimations()
	return Utils.emotes
end

local function moduleToggle(tab, title, section, module)
	tab:Toggle({
		Flag = section,
		Title = title,
		Value = getgenv()[section] and getgenv()[section].enabled,
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
		Value = getgenv()[section] and getgenv()[section][key],
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
			Default = getgenv()[section] and getgenv()[section][key] or default,
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
		Value = getgenv()[section] and getgenv()[section][key],
		Callback = function(selected)
			getgenv()[section][key] = selected
			Config:Save()
		end,
	})
end

local Info = Window:Tab({
	Title = "Information",
	Icon = "circle-question-mark",
	Locked = false,
})

Info:Section({
	Title = "Credits",
})

Info:Paragraph({
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

Info:Paragraph({
	Title = "Footagesus",
	Desc = "The main developer of WindUI, a bleeding-edge UI library for Roblox.",
})

Info:Section({
	Title = "Frequently Asked Questions",
})

Info:Paragraph({
	Title = "Why aren't some emotes looking right?",
	Desc = "Because they are using tools for displaying the objects to other clients, aka it cannot be fixed. The current approach shows you how the other players will actually see you.",
})

Window:Divider()

local Aim = Window:Tab({
	Title = "Aim Bot",
	Icon = "focus",
	Locked = false,
})

Aim:Toggle({
	Flag = "aimToggle",
	Title = "Aim Bot status",
	Desc = "Enable/Disable the aim bot",
	Callback = function(state)
		if not state then
			Modules.Unload("profiles/12355337193/aim.lua")
			return
		end
		Modules.Load("profiles/12355337193/aim.lua")
		Config:Save()
	end,
})

configToggle(
	Aim,
	"Native Raycast Method",
	"Whether or not to check player visibility in the same way that the game does",
	"aimConfig",
	"cameraCast"
)
configToggle(
	Aim,
	"FOV Check",
	"Whether or not to check if the target is in the current fov before selecting it",
	"aimConfig",
	"fovCheck"
)
configToggle(
	Aim,
	"Switch weapons",
	"Whether or not the script should automatically switch or equip the best available weapon",
	"aimConfig",
	"autoEquip"
)
configToggle(
	Aim,
	"Native User Interface",
	"Whether or not the script should render the gun cooldown and tool equip highlights",
	"aimConfig",
	"nativeUI"
)
configToggle(
	Aim,
	"Aim Deviation",
	"Whether or not the script should sometimes misfire when using the gun",
	"aimConfig",
	"deviation"
)

configSlider(
	Aim,
	"Maximum distance",
	"The maximum distance at which the script will no longer target enemies",
	"aimConfig",
	"maxDistance",
	50,
	1000,
	1,
	250
)
configSlider(
	Aim,
	"Maximum velocity",
	"The maximum target velocity at which the script will no longer attempt to shoot a target",
	"aimConfig",
	"maxVelocity",
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
	"visibleParts",
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
	"reactionTime",
	0.01,
	1,
	0.01,
	0.18
)
configSlider(
	Aim,
	"Action Time",
	"The amount of time the script will wait after switching or equipping a weapon",
	"aimConfig",
	"actionTime",
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
	"equipInterval",
	0.1,
	4,
	0.1,
	0.3
)
configSlider(
	Aim,
	"Base Deviation",
	"Base aim inaccuracy in degrees, controls how much the aim naturally deviates",
	"aimConfig",
	"baseDeviation",
	0.5,
	5,
	0.1,
	2.10
)
configSlider(
	Aim,
	"Distance Factor",
	"Additional deviation penalty for distance - higher values make long shots less accurate",
	"aimConfig",
	"distanceFactor",
	0,
	2,
	0.1,
	1
)
configSlider(
	Aim,
	"Velocity Factor",
	"Additional deviation penalty for moving targets - higher values make moving targets harder to hit",
	"aimConfig",
	"velocityFactor",
	0,
	2,
	0.1,
	1.20
)
configSlider(
	Aim,
	"Accuracy Buildup",
	"How much accuracy improves with consecutive shots - higher values = faster improvement",
	"aimConfig",
	"accuracyBuildup",
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
	"minDeviation",
	0.1,
	3,
	0.1,
	1
)

local Esp = Window:Tab({
	Title = "ESP",
	Icon = "eye",
	Locked = false,
})

Esp:Toggle({
	Flag = "espToggle",
	Title = "ESP status",
	Desc = "Enable/Disable the ESP",
	Callback = function(state)
		if not state then
			Modules.Unload("profiles/12355337193/esp.lua")
			return
		end
		Modules.Load("profiles/12355337193/esp.lua")
		Config:Save()
	end,
})

configToggle(Esp, "Display Team", "Whether or not to highlight your teammates", "espConfig", "teammates")
configToggle(Esp, "Display Enemies", "Whether or not to highlight your enemies", "espConfig", "enemies")

local Kill = Window:Tab({
	Title = "Auto Kill",
	Icon = "skull",
	Locked = false,
})

Kill:Button({
	Flag = "knifeButton",
	Title = "[Knife] Kill All",
	Desc = "Kills all players using the knife",
	Callback = function()
		getgenv().killConfig.knifeButton = true
		Modules.Load("profiles/12355337193/controllers/kill.lua")
		local killModule = Modules["profiles/12355337193/controllers/kill.lua"]
		if killModule and killModule.knifeButton then
			killModule:knifeButton()
		end
	end,
})

Kill:Button({
	Flag = "gunButton",
	Title = "[Gun] Kill All",
	Desc = "Kills all players using the gun",
	Callback = function()
		getgenv().killConfig.gunButton = true
		Modules.Load("profiles/12355337193/controllers/kill.lua")
		local killModule = Modules["profiles/12355337193/controllers/kill.lua"]
		if killModule and killModule.gunButton then
			killModule:gunButton()
		end
	end,
})

knifeToggle = Kill:Toggle({
	Flag = "knifeLoop",
	Title = "[Knife] Loop Kill All",
	Desc = "Repeatedly kills all players using the knife",
	Callback = function(state)
		getgenv().killConfig.knifeLoop = state
		if not state then
			Modules.Unload("profiles/12355337193/controllers/kill.lua")
			lockToggle()
			return
		end
		lockToggle("knife")
		Modules.Load("profiles/12355337193/controllers/kill.lua")
		local killModule = Modules["profiles/12355337193/controllers/kill.lua"]
		if killModule and killModule.knifeToggle then
			killModule:knifeToggle()
		end
		Config:Save()
	end,
})

gunToggle = Kill:Toggle({
	Flag = "gunLoop",
	Title = "[Gun] Loop Kill All",
	Desc = "Repeatedly kills all players using the gun",
	Callback = function(state)
		getgenv().killConfig.gunLoop = state
		if not state then
			Modules.Unload("profiles/12355337193/controllers/kill.lua")
			lockToggle()
			return
		end
		lockToggle("gun")
		Modules.Load("profiles/12355337193/controllers/kill.lua")
		local killModule = Modules["profiles/12355337193/controllers/kill.lua"]
		if killModule and killModule.gunToggle then
			killModule:gunToggle()
		end
		Config:Save()
	end,
})

local Misc = Window:Tab({
	Title = "Misc",
	Icon = "brackets",
	Locked = false,
})

Misc:Section({
	Title = "Emotes",
})

local emotes = refreshAnimations()
Misc:Dropdown({
	Flag = "emoteDrop",
	Title = "Emote Selector",
	Values = emotes,
	Callback = function(option)
		Utils.resumeAnimation = option
		Utils.playAnimation(option)
		Config:Save()
	end,
})

Misc:Input({
	Flag = "emoteInput",
	Title = "Add Emote",
	Desc = "Adds an emote from outside the game",
	Type = "Input",
	Placeholder = "rbxassetid://1949963001",
	Callback = function(input)
		table.insert(Utils.asset, input)
		refreshAnimations()
		Config:Save()
	end,
})

Misc:Keybind({
	Flag = "emoteBind",
	Title = "Start Emote",
	Desc = "Keybind to start playing the selected emote",
	Value = "X",
	Callback = function(key)
		Utils.playAnimation(Utils.resumeAnimation)
		Config:Save()
	end,
})

Misc:Section({
	Title = "Other",
})

local updateSetting = Storage.Settings:WaitForChild("UpdateSetting", 4)
Misc:Toggle({
	Flag = "lowPoly",
	Title = "Low Poly",
	Desc = "Toggle the low poly mode",
	Value = false,
	Callback = function(state)
		updateSetting:FireServer("LowGraphics", state)
		updateSetting:FireServer("KillEffectsDisabled", state)
		updateSetting:FireServer("LobbyMusicDisabled", state)
		Config:Save()
	end,
})

Misc:Toggle({
	Flag = "autoSpin",
	Title = "Auto Spin",
	Desc = "Automatically spin the modifier wheel",
	Value = false,
	Callback = function(state)
		getgenv().autoSpin = state
		spawn(function()
			while getgenv().autoSpin do
				if not player:GetAttribute("Match") then
					Storage.Dailies.Spin:InvokeServer()
				end
				wait(0.1)
			end
		end)
		Config:Save()
	end,
})

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

Controller:Toggle({
	Flag = "renewerSystem",
	Title = "Delete Old Controllers",
	Desc = "Should not be disabled unless you also want to disable the options bellow",
	Value = true,
	Callback = function(state)
		if not state then
			Modules.Unload("profiles/12355337193/controllers/init.lua")
			Config:Save()
			return
		end
		Modules.Load("profiles/12355337193/controllers/init.lua")
		Config:Save()
	end,
})

Controller:Toggle({
	Flag = "knifeController",
	Title = "Custom Knife Controller",
	Desc = "Uses the custom knife input handler, improves support for some features of the game",
	Value = true,
	Callback = function(state)
		if not state then
			Modules.Unload("profiles/12355337193/controllers/knife.lua")
			Config:Save()
			return
		end
		Modules.Load("profiles/12355337193/controllers/knife.lua")
		Config:Save()
	end,
})

Controller:Toggle({
	Flag = "gunController",
	Title = "Custom Gun Controller",
	Desc = "Uses the custom gun input handler, improves support for some features of the game",
	Value = true,
	Callback = function(state)
		if not state then
			Modules.Unload("profiles/12355337193/controllers/gun.lua")
			Config:Save()
			return
		end
		Modules.Load("profiles/12355337193/controllers/gun.lua")
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
	Flag = "windowBind",
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
	Flag = "theme",
	Title = "Theme",
	Values = themes,
	Callback = function(option)
		Wind:SetTheme(option)
		Config:Save()
	end,
})

Settings:Toggle({
	Title = "Auto Load",
	Desc = "Makes the configs persist in between executions",
	Value = isfile(loadFlag),
	Callback = function(state)
		if state then
			writefile(loadFlag, "")
		else
			delfile(loadFlag)
		end
	end,
})

Settings:Toggle({
	Title = "Auto Save",
	Desc = "Automatically saves the configs when changes are made",
	Value = isfile(saveFlag),
	Callback = function(state)
		if state then
			writefile(saveFlag, "")
		else
			delfile(saveFlag)
		end
	end,
})

Window:SelectTab(1)
Modules.State["config"] = true
if isfile(loadFlag) then
	Window.CurrentConfig:Load()
end

do
	local version = Folder .. "/" .. "version"
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
					Title = "Maybe later",
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
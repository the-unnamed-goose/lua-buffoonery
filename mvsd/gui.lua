-- This file is licensed under the Creative Commons Attribution 4.0 International License. See https://creativecommons.org/licenses/by/4.0/legalcode.txt for details.
local Windui = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local Replicated = game:GetService("ReplicatedStorage")
local Repository = "https://raw.githubusercontent.com/goose-birb/lua-buffoonery/master/"

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
	DISTANCE_FACTOR = 0.8,
	VELOCITY_FACTOR = 1.20,
	ACCURACY_BUILDUP = 0.8,
	MIN_DEVIATION = 1,
	RAYCAST_DISTANCE = 1000,
}
getgenv().espTeamMates = true
getgenv().espEnemies = true
getgenv().killButton = { gun = false, knife = false }
getgenv().killLoop = { gun = false, knife = false }

local Window = Windui:CreateWindow({
	Title = "RC 4",
	Icon = "square-function",
	Author = "by Le Honk",
	Folder = "MVSD_Graphics",
	Size = UDim2.fromOffset(580, 100),
	Transparent = true,
	Theme = "Dark",
	Resizable = true,
	SideBarWidth = 120,
	HideSearchBar = true,
	ScrollBarEnabled = false,
})

local Config = Window.ConfigManager
local default = Config:CreateConfig("default")
local saveFlag = "WindUI/" .. Window.Folder .. "/config/autosave"
local loadFlag = "WindUI/" .. Window.Folder .. "/config/autoload"
local Elements = {}

-- Initialize modules table before functions that use it
local modules = {}

local function saveConfig()
	if isfile(saveFlag) then
		default:Save()
	end
end

local function disconnectModule(moduleName)
	local module = modules[moduleName]
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
	modules[moduleName] = nil
end

function loadModule(file)
	if modules[file] then
		return modules[file]
	end

	_, modules[file] = pcall(loadstring(game:HttpGet(Repository .. file)))
end

local gunToggle
local knifeToggle
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

local Aim = Window:Tab({
	Title = "Aim Bot",
	Icon = "focus",
	Locked = false,
})

Elements.aimToggle = Aim:Toggle({
	Title = "Aim Bot status",
	Desc = "Enable/Disable the aim bot",
	Callback = function(state)
		if not state then
			disconnectModule("mvsd/aimbot.lua")
			return
		end
		loadModule("mvsd/aimbot.lua")
		saveConfig()
	end,
})

Elements.cameraToggle = Aim:Toggle({
	Title = "Native Raycast Method",
	Desc = "Whether or not to check player visibility in the same way that the game does, if enabled doubles the amount of work the script has to do per check",
	Value = true,
	Callback = function(state)
		getgenv().aimConfig.CAMERA_CAST = state
		saveConfig()
	end,
})

Elements.fovToggle = Aim:Toggle({
	Title = "FOV Check",
	Desc = "Whether or not to check if the target is in the current fov before selecting it",
	Value = true,
	Callback = function(state)
		getgenv().aimConfig.FOV_CHECK = state
		saveConfig()
	end,
})

Elements.equipToggle = Aim:Toggle({
	Title = "Switch weapons",
	Desc = "Whether or not the script should automatically switch or equip the best available weapon",
	Value = true,
	Callback = function(state)
		getgenv().aimConfig.AUTO_EQUIP = state
		saveConfig()
	end,
})

Elements.interfaceToggle = Aim:Toggle({
	Title = "Native User Interface",
	Desc = "Whether or not the script should render the gun cooldown and tool equip highlights",
	Value = true,
	Callback = function(state)
		getgenv().aimConfig.NATIVE_UI = state
		saveConfig()
	end,
})

Elements.deviationToggle = Aim:Toggle({
	Title = "Aim Deviation",
	Desc = "Whether or not the script should sometimes misfire when using the gun",
	Value = true,
	Callback = function(state)
		getgenv().aimConfig.DEVIATION_ENABLED = state
		saveConfig()
	end,
})

Elements.distanceSlider = Aim:Slider({
	Title = "Maximum distance",
	Desc = "The maximum distance at which the script will no longer target enemies",
	Value = {
		Min = 50,
		Max = 1000,
		Default = 250,
	},
	Callback = function(value)
		getgenv().aimConfig.MAX_DISTANCE = tonumber(value)
		saveConfig()
	end,
})

Elements.velocitySlider = Aim:Slider({
	Title = "Maximum velocity",
	Desc = "The maximum target velocity at which the script will no longer attempt to shoot a target",
	Value = {
		Min = 20,
		Max = 200,
		Default = 40,
	},
	Callback = function(value)
		getgenv().aimConfig.MAX_VELOCITY = tonumber(value)
		saveConfig()
	end,
})

Elements.partsSlider = Aim:Slider({
	Title = "Required Visible Parts",
	Desc = "The amount of visible player parts the script will require before selecting a target",
	Value = {
		Min = 1,
		Max = 18,
		Default = 4,
	},
	Callback = function(value)
		getgenv().aimConfig.VISIBLE_PARTS = tonumber(value)
		saveConfig()
	end,
})

Elements.reactionSlider = Aim:Slider({
	Title = "Reaction Time",
	Desc = "The amount of time the script will wait before attacking a given target, is not applied when 'Switch Weapons' is toggled",
	Step = 0.01,
	Value = {
		Min = 0.01,
		Max = 1,
		Default = 0.18,
	},
	Callback = function(value)
		getgenv().aimConfig.REACTION_TIME = tonumber(value)
		saveConfig()
	end,
})

Elements.actionSlider = Aim:Slider({
	Title = "Action Time",
	Desc = "The amount of time the script will wait after switching or equipping a weapon before attacking a given target, is not applied when 'Switch Weapons' is not toggled",
	Step = 0.01,
	Value = {
		Min = 0.2,
		Max = 4,
		Default = 0.32,
	},
	Callback = function(value)
		getgenv().aimConfig.ACTION_TIME = tonumber(value)
		saveConfig()
	end,
})

Elements.equipSlider = Aim:Slider({
	Title = "Equip Time",
	Desc = "The amount of time the script will wait before checking what is the best weapon to equip again.",
	Step = 0.1,
	Value = {
		Min = 0.1,
		Max = 4,
		Default = 0.3,
	},
	Callback = function(value)
		getgenv().aimConfig.EQUIP_LOOP = tonumber(value)
		saveConfig()
	end,
})

Elements.baseDeviationSlider = Aim:Slider({
	Title = "Base Deviation",
	Desc = "Base aim inaccuracy in degrees, controls how much the aim naturally deviates",
	Step = 0.1,
	Value = {
		Min = 0.5,
		Max = 5,
		Default = 2.10,
	},
	Callback = function(value)
		getgenv().aimConfig.BASE_DEVIATION = tonumber(value)
		saveConfig()
	end,
})

Elements.distanceFactorSlider = Aim:Slider({
	Title = "Distance Factor",
	Desc = "Additional deviation penalty for distance - higher values make long shots less accurate",
	Step = 0.1,
	Value = {
		Min = 0,
		Max = 2,
		Default = 0.8,
	},
	Callback = function(value)
		getgenv().aimConfig.DISTANCE_FACTOR = tonumber(value)
		saveConfig()
	end,
})

Elements.velocityFactorSlider = Aim:Slider({
	Title = "Velocity Factor",
	Desc = "Additional deviation penalty for moving targets - higher values make moving targets harder to hit",
	Step = 0.1,
	Value = {
		Min = 0,
		Max = 2,
		Default = 1.2,
	},
	Callback = function(value)
		getgenv().aimConfig.VELOCITY_FACTOR = tonumber(value)
		saveConfig()
	end,
})

Elements.accuracyBuildupSlider = Aim:Slider({
	Title = "Accuracy Buildup",
	Desc = "How much accuracy improves with consecutive shots - higher values = faster improvement",
	Step = 0.01,
	Value = {
		Min = 0,
		Max = 2,
		Default = 0.8,
	},
	Callback = function(value)
		getgenv().aimConfig.ACCURACY_BUILDUP = tonumber(value)
		saveConfig()
	end,
})

Elements.minDeviationSlider = Aim:Slider({
	Title = "Min Deviation",
	Desc = "Minimum deviation that always remains - prevents perfect accuracy",
	Step = 0.1,
	Value = {
		Min = 0.1,
		Max = 3,
		Default = 1,
	},
	Callback = function(value)
		getgenv().aimConfig.MIN_DEVIATION = tonumber(value)
		saveConfig()
	end,
})

local Esp = Window:Tab({
	Title = "ESP",
	Icon = "eye",
	Locked = false,
})

Elements.espToggle = Esp:Toggle({
	Title = "ESP status",
	Desc = "Enable/Disable the ESP",
	Callback = function(state)
		if not state then
			disconnectModule("mvsd/esp.lua")
			return
		end
		loadModule("mvsd/esp.lua")
		saveConfig()
	end,
})

Elements.teamToggle = Esp:Toggle({
	Title = "Display Team",
	Desc = "Whether or not to highlight your teammates",
	Value = true,
	Callback = function(state)
		getgenv().espTeamMates = state
		saveConfig()
	end,
})

Elements.enemyToggle = Esp:Toggle({
	Title = "Display Enemies",
	Desc = "Whether or not to highlight your enemies",
	Value = true,
	Callback = function(state)
		getgenv().espEnemies = state
		saveConfig()
	end,
})

local Kill = Window:Tab({
	Title = "Auto Kill",
	Icon = "skull",
	Locked = false,
})

local knifeButton = Kill:Button({
	Title = "[Knife] Kill All",
	Desc = "Kills all players using the knife",
	Callback = function()
		getgenv().killButton.knife = true
		loadModule("mvsd/killall.lua")
	end,
})

local gunButton = Kill:Button({
	Title = "[Gun] Kill All",
	Desc = "Kills all players using the gun",
	Callback = function()
		getgenv().killButton.gun = true
		loadModule("mvsd/killall.lua")
	end,
})

knifeToggle = Kill:Toggle({
	Title = "[Knife] Loop Kill All",
	Desc = "Repeatedly kills all players using the knife",
	Callback = function(state)
		getgenv().killLoop.knife = state
		if not state then
			disconnectModule("mvsd/killall.lua")
			lockToggle()
			return
		end
		lockToggle("knife")
		loadModule("mvsd/killall.lua")
		saveConfig()
	end,
})

gunToggle = Kill:Toggle({
	Title = "[Gun] Loop Kill All",
	Desc = "Repeatedly kills all players using the gun",
	Callback = function(state)
		getgenv().killLoop.gun = state
		if not state then
			disconnectModule("mvsd/killall.lua")
			lockToggle()
			return
		end
		lockToggle("gun")
		loadModule("mvsd/killall.lua")
		saveConfig()
	end,
})

local Misc = Window:Tab({
	Title = "Misc",
	Icon = "brackets",
	Locked = false,
})

local crashConnection
local player = game:GetService("Players").LocalPlayer
Elements.antiCrash = Misc:Toggle({
	Title = "Anti Crash",
	Desc = "Blocks the shroud projectile from rendering",
	Value = true,
	Callback = function(state)
		if not state then
			if crashConnection then
				crashConnection:Disconnect()
			end
			saveConfig()
			return
		end

		if player.Character then
			crashConnection = player.CharacterAdded:Connect(function()
				local module = Replicated.Ability:WaitForChild("ShroudProjectileController", 5)
				local replacement = Instance.new("ModuleScript")
				replacement.Name = "ShroudProjectileController"
				if module then
					local parent = module.Parent
					replacement.Parent = parent
					module:Destroy()
				end
			end)
		end
		saveConfig()
	end,
})

local updateSetting = Replicated.Settings:WaitForChild("UpdateSetting", 4)
Elements.lowPoly = Misc:Toggle({
	Title = "Low Poly",
	Desc = "Toggle the low poly mode",
	Value = false,
	Callback = function(state)
		updateSetting:FireServer("LowGraphics", state)
		updateSetting:FireServer("KillEffectsDisabled", state)
		updateSetting:FireServer("LobbyMusicDisabled", state)
		saveConfig()
	end,
})

Elements.autoSpin = Misc:Toggle({
	Title = "Auto Spin",
	Desc = "Automatically spin the modifier wheel",
	Value = false,
	Callback = function(state)
		getgenv().autoSpin = state
		if not state then
			saveConfig()
			return
		end

		spawn(function()
			while getgenv().autoSpin do
				if player:GetAttribute("Match") then
					Replicated.Dailies.Spin:InvokeServer()
				end
				wait(0.1)
			end
		end)
		saveConfig()
	end,
})

local Controller = Window:Tab({
	Title = "Controller",
	Icon = "keyboard",
	Locked = false,
})

Windui:Notify({
	Title = "Warning",
	Content = "The custom knife controller has no mode toggle functionality (button) on mobile.",
	Duration = 4,
	Icon = "triangle-alert",
})

Elements.renewerSystem = Controller:Toggle({
	Title = "Delete Old Controllers",
	Desc = "Should not be disabled unless you also want to disable the options bellow",
	Value = true,
	Callback = function(state)
		if not state then
			disconnectModule("mvsd/controllers/init.lua")
			return
		end
		loadModule("mvsd/controllers/init.lua")
		saveConfig()
	end,
})

Elements.knifeController = Controller:Toggle({
	Title = "Custom Knife Controller",
	Desc = "Uses the custom knife input handler, improves support for some features of the game",
	Value = true,
	Callback = function(state)
		if not state then
			disconnectModule("mvsd/controllers/knife.lua")
			return
		end
		loadModule("mvsd/controllers/knife.lua")
		saveConfig()
	end,
})

Elements.gunController = Controller:Toggle({
	Title = "Custom Gun Controller",
	Desc = "Uses the custom gun input handler, improves support for some features of the game",
	Value = true,
	Callback = function(state)
		if not state then
			disconnectModule("mvsd/controllers/gun.lua")
			return
		end
		loadModule("mvsd/controllers/gun.lua")
		saveConfig()
	end,
})

local Settings = Window:Tab({
	Title = "Settings",
	Icon = "settings",
	Locked = false,
})

Settings:Section({
	Title = "General",
})

local themes = {}
for theme, _ in pairs(WindUI:GetThemes()) do
	table.insert(themes, theme)
end
table.sort(themes)

Elements.themeDrop = Settings:Dropdown({
	Title = "Theme Selector",
	Values = themes,
	Value = "Dark",
	Callback = function(option)
		WindUI:SetTheme(option)
		saveConfig()
	end,
})

local loadToggle = Settings:Toggle({
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

local saveToggle = Settings:Toggle({
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

Settings:Section({
	Title = "Credits",
})

local gooseCredit = Settings:Paragraph({
	Title = "Goose",
	Desc = "The script developer, rewrote everything from scratch, if you encounter any issues please report them at https://github.com/goose-birb/lua-buffoonery/issues",
})

local footagesusCredit = Settings:Paragraph({
	Title = "Footagesus",
	Desc = "The main developer of WindUI, a bleeding-edge UI library for Roblox.",
})

for _, element in pairs(Elements) do
	default:Register(element.Title, element)
end

Window:SelectTab(1)
if isfile(loadFlag) then
	genv = default:Load()
	for _, element in pairs(Elements) do
		if element.__type == "Dropdown" then
			element.Callback(element.Value)
		end
	end
end

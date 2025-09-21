-- This file is licensed under the Creative Commons Attribution 4.0 International License. See https://creativecommons.org/licenses/by/4.0/legalcode.txt for details.
local Players = game:GetService("Players")
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
	DISTANCE_FACTOR = 1,
	VELOCITY_FACTOR = 1.20,
	ACCURACY_BUILDUP = 0.5,
	MIN_DEVIATION = 1,
	RAYCAST_DISTANCE = 1000,
}
getgenv().espTeammates = true
getgenv().espEnemies = true
getgenv().killButton = { gun = false, knife = false }
getgenv().killLoop = { gun = false, knife = false }

local Window = Windui:CreateWindow({
	Title = "RC 5",
	Icon = "square-function",
	Author = "by Le Honk",
	Folder = "MVSD",
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
local resumeAnimation = ""
local animator
local track

local player = Players.LocalPlayer
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

local notifyFlag
local function playAnimation(name)
	if not notifyFlag then
		notifyFlag = 0
		Windui:Notify({
			Title = "Warning",
			Content = "Some emotes require server replicated parts and thus cannot be triggered without server interactions.",
			Duration = 4,
			Icon = "triangle-alert",
		})
	end

	if track then
		track:Stop()
	end

	if animation[name] then
		track = animator:LoadAnimation(animation[name])
		track:Play()
	end
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
			Modules:Unload("mvsd/aimbot.lua")
			return
		end
		Modules:Load("mvsd/aimbot.lua")
		Config:Save()
	end,
})

Elements.cameraToggle = Aim:Toggle({
	Title = "Native Raycast Method",
	Desc = "Whether or not to check player visibility in the same way that the game does, if enabled doubles the amount of work the script has to do per check",
	Value = getgenv().aimConfig.CAMERA_CAST,
	Callback = function(state)
		getgenv().aimConfig.CAMERA_CAST = state
		Config:Save()
	end,
})

Elements.fovToggle = Aim:Toggle({
	Title = "FOV Check",
	Desc = "Whether or not to check if the target is in the current fov before selecting it",
	Value = getgenv().aimConfig.FOV_CHECK,
	Callback = function(state)
		getgenv().aimConfig.FOV_CHECK = state
		Config:Save()
	end,
})

Elements.equipToggle = Aim:Toggle({
	Title = "Switch weapons",
	Desc = "Whether or not the script should automatically switch or equip the best available weapon",
	Value = getgenv().aimConfig.AUTO_EQUIP,
	Callback = function(state)
		getgenv().aimConfig.AUTO_EQUIP = state
		Config:Save()
	end,
})

Elements.interfaceToggle = Aim:Toggle({
	Title = "Native User Interface",
	Desc = "Whether or not the script should render the gun cooldown and tool equip highlights",
	Value = getgenv().aimConfig.NATIVE_UI,
	Callback = function(state)
		getgenv().aimConfig.NATIVE_UI = state
		Config:Save()
	end,
})

Elements.deviationToggle = Aim:Toggle({
	Title = "Aim Deviation",
	Desc = "Whether or not the script should sometimes misfire when using the gun",
	Value = getgenv().aimConfig.DEVIATION_ENABLED,
	Callback = function(state)
		getgenv().aimConfig.DEVIATION_ENABLED = state
		Config:Save()
	end,
})

Elements.distanceSlider = Aim:Slider({
	Title = "Maximum distance",
	Desc = "The maximum distance at which the script will no longer target enemies",
	Value = {
		Min = 50,
		Max = 1000,
		Default = getgenv().aimConfig.MAX_DISTANCE,
	},
	Callback = function(value)
		getgenv().aimConfig.MAX_DISTANCE = tonumber(value)
		Config:Save()
	end,
})

Elements.velocitySlider = Aim:Slider({
	Title = "Maximum velocity",
	Desc = "The maximum target velocity at which the script will no longer attempt to shoot a target",
	Value = {
		Min = 20,
		Max = 200,
		Default = getgenv().aimConfig.MAX_VELOCITY,
	},
	Callback = function(value)
		getgenv().aimConfig.MAX_VELOCITY = tonumber(value)
		Config:Save()
	end,
})

Elements.partsSlider = Aim:Slider({
	Title = "Required Visible Parts",
	Desc = "The amount of visible player parts the script will require before selecting a target",
	Value = {
		Min = 1,
		Max = 18,
		Default = getgenv().aimConfig.VISIBLE_PARTS,
	},
	Callback = function(value)
		getgenv().aimConfig.VISIBLE_PARTS = tonumber(value)
		Config:Save()
	end,
})

Elements.reactionSlider = Aim:Slider({
	Title = "Reaction Time",
	Desc = "The amount of time the script will wait before attacking a given target, is not applied when 'Switch Weapons' is toggled",
	Step = 0.01,
	Value = {
		Min = 0.01,
		Max = 1,
		Default = getgenv().aimConfig.REACTION_TIME,
	},
	Callback = function(value)
		getgenv().aimConfig.REACTION_TIME = tonumber(value)
		Config:Save()
	end,
})

Elements.actionSlider = Aim:Slider({
	Title = "Action Time",
	Desc = "The amount of time the script will wait after switching or equipping a weapon before attacking a given target, is not applied when 'Switch Weapons' is not toggled",
	Step = 0.01,
	Value = {
		Min = 0.2,
		Max = 4,
		Default = getgenv().aimConfig.ACTION_TIME,
	},
	Callback = function(value)
		getgenv().aimConfig.ACTION_TIME = tonumber(value)
		Config:Save()
	end,
})

Elements.equipSlider = Aim:Slider({
	Title = "Equip Time",
	Desc = "The amount of time the script will wait before checking what is the best weapon to equip again.",
	Step = 0.1,
	Value = {
		Min = 0.1,
		Max = 4,
		Default = getgenv().aimConfig.EQUIP_LOOP,
	},
	Callback = function(value)
		getgenv().aimConfig.EQUIP_LOOP = tonumber(value)
		Config:Save()
	end,
})

Elements.baseDeviationSlider = Aim:Slider({
	Title = "Base Deviation",
	Desc = "Base aim inaccuracy in degrees, controls how much the aim naturally deviates",
	Step = 0.1,
	Value = {
		Min = 0.5,
		Max = 5,
		Default = getgenv().aimConfig.BASE_DEVIATION,
	},
	Callback = function(value)
		getgenv().aimConfig.BASE_DEVIATION = tonumber(value)
		Config:Save()
	end,
})

Elements.distanceFactorSlider = Aim:Slider({
	Title = "Distance Factor",
	Desc = "Additional deviation penalty for distance - higher values make long shots less accurate",
	Step = 0.1,
	Value = {
		Min = 0,
		Max = 2,
		Default = getgenv().aimConfig.DISTANCE_FACTOR,
	},
	Callback = function(value)
		getgenv().aimConfig.DISTANCE_FACTOR = tonumber(value)
		Config:Save()
	end,
})

Elements.velocityFactorSlider = Aim:Slider({
	Title = "Velocity Factor",
	Desc = "Additional deviation penalty for moving targets - higher values make moving targets harder to hit",
	Step = 0.1,
	Value = {
		Min = 0,
		Max = 2,
		Default = getgenv().aimConfig.VELOCITY_FACTOR,
	},
	Callback = function(value)
		getgenv().aimConfig.VELOCITY_FACTOR = tonumber(value)
		Config:Save()
	end,
})

Elements.accuracyBuildupSlider = Aim:Slider({
	Title = "Accuracy Buildup",
	Desc = "How much accuracy improves with consecutive shots - higher values = faster improvement",
	Step = 0.01,
	Value = {
		Min = 0,
		Max = 2,
		Default = getgenv().aimConfig.ACCURACY_BUILDUP,
	},
	Callback = function(value)
		getgenv().aimConfig.ACCURACY_BUILDUP = tonumber(value)
		Config:Save()
	end,
})

Elements.minDeviationSlider = Aim:Slider({
	Title = "Min Deviation",
	Desc = "Minimum deviation that always remains - prevents perfect accuracy",
	Step = 0.1,
	Value = {
		Min = 0.1,
		Max = 3,
		Default = getgenv().aimConfig.MIN_DEVIATION,
	},
	Callback = function(value)
		getgenv().aimConfig.MIN_DEVIATION = tonumber(value)
		Config:Save()
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
			Modules:Unload("mvsd/esp.lua")
			return
		end
		Modules:Load("mvsd/esp.lua")
		Config:Save()
	end,
})

Elements.teamToggle = Esp:Toggle({
	Title = "Display Team",
	Desc = "Whether or not to highlight your teammates",
	Value = getgenv().espTeammates,
	Callback = function(state)
		getgenv().espTeammates = state
		Config:Save()
	end,
})

Elements.enemyToggle = Esp:Toggle({
	Title = "Display Enemies",
	Desc = "Whether or not to highlight your enemies",
	Value = getgenv().espEnemies,
	Callback = function(state)
		getgenv().espEnemies = state
		Config:Save()
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
		Modules:Load("mvsd/killall.lua")
	end,
})

local gunButton = Kill:Button({
	Title = "[Gun] Kill All",
	Desc = "Kills all players using the gun",
	Callback = function()
		getgenv().killButton.gun = true
		Modules:Load("mvsd/killall.lua")
	end,
})

knifeToggle = Kill:Toggle({
	Title = "[Knife] Loop Kill All",
	Desc = "Repeatedly kills all players using the knife",
	Callback = function(state)
		getgenv().killLoop.knife = state
		if not state then
			Modules:Unload("mvsd/killall.lua")
			lockToggle()
			return
		end
		lockToggle("knife")
		Modules:Load("mvsd/killall.lua")
		Config:Save()
	end,
})

gunToggle = Kill:Toggle({
	Title = "[Gun] Loop Kill All",
	Desc = "Repeatedly kills all players using the gun",
	Callback = function(state)
		getgenv().killLoop.gun = state
		if not state then
			Modules:Unload("mvsd/killall.lua")
			lockToggle()
			return
		end
		lockToggle("gun")
		Modules:Load("mvsd/killall.lua")
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

refreshAnimations()
Elements.emoteDrop = Misc:Dropdown({
	Title = "Emote Selector",
	Values = emotes,
	Callback = function(option)
		resumeAnimation = option
		playAnimation(option)
		Config:Save()
	end,
})

local emoteInput = Misc:Input({
	Title = "Add Emote",
	Desc = "Adds an emote from outside the game",
	Type = "Input",
	Placeholder = "rbxassetid://1949963001",
	Callback = function(input)
		table.insert(asset, input)
		refreshAnimations()
		Elements.emoteDrop:Refresh(emotes)
		Config:Save()
	end,
})

Elements.emoteBind = Misc:Keybind({
	Title = "Start Emote",
	Desc = "Keybind to start playing the selected emote",
	Value = "X",
	Callback = function(key)
		playAnimation(resumeAnimation)
		Config:Save()
	end,
})

Misc:Section({
	Title = "Other",
})

local crashConnection
Elements.antiCrash = Misc:Toggle({
	Title = "Anti Crash",
	Desc = "Blocks the shroud projectile from rendering",
	Value = true,
	Callback = function(state)
		if not state then
			if crashConnection then
				crashConnection:Disconnect()
			end
			Config:Save()
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
		Config:Save()
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
		Config:Save()
	end,
})

Elements.autoSpin = Misc:Toggle({
	Title = "Auto Spin",
	Desc = "Automatically spin the modifier wheel",
	Value = false,
	Callback = function(state)
		getgenv().autoSpin = state
		spawn(function()
			while getgenv().autoSpin do
				if not player:GetAttribute("Match") then
					Replicated.Dailies.Spin:InvokeServer()
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
			Modules:Unload("mvsd/controllers/init.lua")
			Config:Save()
			return
		end
		Modules:Load("mvsd/controllers/init.lua")
		Config:Save()
	end,
})

Elements.knifeController = Controller:Toggle({
	Title = "Custom Knife Controller",
	Desc = "Uses the custom knife input handler, improves support for some features of the game",
	Value = true,
	Callback = function(state)
		if not state then
			Modules:Unload("mvsd/controllers/knife.lua")
			Config:Save()
			return
		end
		Modules:Load("mvsd/controllers/knife.lua")
		Config:Save()
	end,
})

Elements.gunController = Controller:Toggle({
	Title = "Custom Gun Controller",
	Desc = "Uses the custom gun input handler, improves support for some features of the game",
	Value = true,
	Callback = function(state)
		if not state then
			Modules:Unload("mvsd/controllers/gun.lua")
			Config:Save()
			return
		end
		Modules:Load("mvsd/controllers/gun.lua")
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

Elements.windowBind = Settings:Keybind({
	Title = "Window toggle",
	Desc = "Keybind to toggle ui",
	Value = "X",
	Callback = function(key)
		Window:SetToggleKey(Enum.KeyCode[key])
		Config:Save()
	end,
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
		Config:Save()
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

-- Set up character tracking for emotes
player.CharacterAdded:Connect(handleTracks)
if player.Character then
	handleTracks()
end

default:Set("asset", asset)
for _, element in pairs(Elements) do
	default:Register(element.Title, element)
end

Window:SelectTab(1)
if isfile(loadFlag) then
	local data = default:Load()
	asset = data.asset or {}
	refreshAnimations()

	for _, element in pairs(Elements) do
		if element.__type == "Dropdown" then
			element.Callback(element.Value)
		end
	end
end

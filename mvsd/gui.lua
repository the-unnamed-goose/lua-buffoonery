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
	BASE_DEVIATION = 2.05,
	DISTANCE_FACTOR = 0.6,
	VELOCITY_FACTOR = 0.9,
	ACCURACY_BUILDUP = 0.14,
	MIN_DEVIATION = 1,
	RAYCAST_DISTANCE = 1000,
}
getgenv().espTeamMates = true
getgenv().espEnemies = true
getgenv().killButton = { gun = false, knife = false }
getgenv().killLoop = { gun = false, knife = false }

local Window = Windui:CreateWindow({
	Title = "[Open Source] MVSD Script",
	Icon = "square-function",
	Author = "by Le Honk",
	Folder = "MVSD_Graphics",
	Size = UDim2.fromOffset(260, 300),
	Transparent = true,
	Theme = "Dark",
	Resizable = true,
	SideBarWidth = 120,
	HideSearchBar = true,
	ScrollBarEnabled = false,
})

local modules = {}
function loadModule(file)
	if modules[file] then
		return modules[file]
	end

	table.insert(modules, file)
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

local aimToggle = Aim:Toggle({
	Title = "Feature status",
	Desc = "Enable/Disable the aim bot",
	Callback = function(state)
		local module = modules["mvsd/aimbot.lua"]
		if not state and module then
			for _, connection in pairs(module) do
				connection:Disconnect()
			end
			modules["mvsd/aimbot.lua"] = nil
			return
		end
		loadModule("mvsd/aimbot.lua")
	end,
})

local cameraToggle = Aim:Toggle({
	Title = "Native Raycast Method",
	Desc = "Whether or not to check player visibility in the same way that the game does, if enabled doubles the amount of work the script has to do per check",
	Value = true,
	Callback = function(state)
		getgenv().aimConfig.CAMERA_CAST = state
	end,
})

local fovToggle = Aim:Toggle({
	Title = "FOV Check",
	Desc = "Whether or not to check if the target is in the current fov before selecting it",
	Value = true,
	Callback = function(state)
		getgenv().aimConfig.FOV_CHECK = state
	end,
})

local equipToggle = Aim:Toggle({
	Title = "Switch weapons",
	Desc = "Whether or not the script should automatically switch or equip the best available weapon",
	Value = true,
	Callback = function(state)
		getgenv().aimConfig.AUTO_EQUIP = state
	end,
})

local interfaceToggle = Aim:Toggle({
	Title = "Native User Interface",
	Desc = "Whether or not the script should render the gun cooldown and tool equip highlights",
	Value = true,
	Callback = function(state)
		getgenv().aimConfig.NATIVE_UI = state
	end,
})

local deviationToggle = Aim:Toggle({
	Title = "Aim Deviation",
	Desc = "Whether or not the script should sometimes misfire when using the gun",
	Value = true,
	Callback = function(state)
		getgenv().aimConfig.DEVIATION_ENABLED = state
	end,
})

local distanceSlider = Aim:Slider({
	Title = "Maximum distance",
	Desc = "The maximum distance at which the script will no longer target enemies",
	Value = {
		Min = 50,
		Max = 1000,
		Default = 250,
	},
	Callback = function(value)
		getgenv().aimConfig.MAX_DISTANCE = tonumber(value)
	end,
})

local velocitySlider = Aim:Slider({
	Title = "Maximum velocity",
	Desc = "The maximum target velocity at which the script will no longer attempt to shoot a target",
	Value = {
		Min = 20,
		Max = 200,
		Default = 40,
	},
	Callback = function(value)
		getgenv().aimConfig.MAX_VELOCITY = tonumber(value)
	end,
})

local partsSlider = Aim:Slider({
	Title = "Required Visible Parts",
	Desc = "The amount of visible player parts the script will require before selecting a target",
	Value = {
		Min = 1,
		Max = 18,
		Default = 4,
	},
	Callback = function(value)
		getgenv().aimConfig.VISIBLE_PARTS = tonumber(value)
	end,
})

local reactionSlider = Aim:Slider({
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
	end,
})

local actionSlider = Aim:Slider({
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
	end,
})

local equipSlider = Aim:Slider({
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
	end,
})

local baseDeviationSlider = Aim:Slider({
	Title = "Base Deviation",
	Desc = "Base aim inaccuracy in degrees, controls how much the aim naturally deviates",
	Step = 0.1,
	Value = {
		Min = 0.5,
		Max = 5,
		Default = 2.05,
	},
	Callback = function(value)
		getgenv().aimConfig.BASE_DEVIATION = tonumber(value)
	end,
})

local distanceFactorSlider = Aim:Slider({
	Title = "Distance Factor",
	Desc = "Additional deviation penalty for distance - higher values make long shots less accurate",
	Step = 0.1,
	Value = {
		Min = 0,
		Max = 2,
		Default = 0.6,
	},
	Callback = function(value)
		getgenv().aimConfig.DISTANCE_FACTOR = tonumber(value)
	end,
})

local velocityFactorSlider = Aim:Slider({
	Title = "Velocity Factor",
	Desc = "Additional deviation penalty for moving targets - higher values make moving targets harder to hit",
	Step = 0.1,
	Value = {
		Min = 0,
		Max = 2,
		Default = 0.9,
	},
	Callback = function(value)
		getgenv().aimConfig.VELOCITY_FACTOR = tonumber(value)
	end,
})

local accuracyBuildupSlider = Aim:Slider({
	Title = "Accuracy Buildup",
	Desc = "How much accuracy improves with consecutive shots - higher values = faster improvement",
	Step = 0.01,
	Value = {
		Min = 0,
		Max = 0.5,
		Default = 0.13,
	},
	Callback = function(value)
		getgenv().aimConfig.ACCURACY_BUILDUP = tonumber(value)
	end,
})

local minDeviationSlider = Aim:Slider({
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
	end,
})

local Esp = Window:Tab({
	Title = "ESP",
	Icon = "eye",
	Locked = false,
})

local espToggle = Esp:Toggle({
	Title = "Feature status",
	Desc = "Enable/Disable the ESP",
	Callback = function(state)
		local module = modules["mvsd/esp.lua"]
		if not state and module then
			for _, connection in pairs(module) do
				connection:Disconnect()
			end
			modules["mvsd/esp.lua"] = nil
			return
		end
		return loadModule("mvsd/esp.lua")
	end,
})

local teamToggle = Esp:Toggle({
	Title = "Display Team",
	Desc = "Whether or not to highlight your teammates",
	Value = true,
	Callback = function(state)
		getgenv().espTeamMates = state
	end,
})

local enemyToggle = Esp:Toggle({
	Title = "Display Enemies",
	Desc = "Whether or not to highlight your enemies",
	Value = true,
	Callback = function(state)
		getgenv().espEnemies = state
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
		if state then
			local module = modules["mvsd/killall.lua"]
			if not module then
				module:Disconnect()
				modules["mvsd/killall.lua"] = nil
				return
			end

			lockToggle("knife")
		else
			lockToggle()
		end
		getgenv().killLoop.knife = state
		loadModule("mvsd/killall.lua")
	end,
})

gunToggle = Kill:Toggle({
	Title = "[Gun] Loop Kill All",
	Desc = "Repeatedly kills all players using the gun",
	Callback = function(state)
		if state then
			local module = modules["mvsd/killall.lua"]
			if not module then
				module:Disconnect()
				modules["mvsd/killall.lua"] = nil
				return
			end

			lockToggle("gun")
		else
			lockToggle()
		end
		getgenv().killLoop.gun = state
		loadModule("mvsd/killall.lua")
	end,
})

local Misc = Window:Tab({
	Title = "Misc",
	Icon = "brackets",
	Locked = false,
})

local crashConnection
local antiCrash = Misc:Toggle({
	Title = "Anti Crash",
	Desc = "Blocks the shroud projectile from rendering",
	Value = true,
	Callback = function(state)
		if state or localPlayer.Character then
			crashConnection = localPlayer.CharacterAdded:Connect(function()
				local module = Replicated.Ability:WaitForChild("ShroudProjectileController", 5)
				local replacement = Instance.new("ModuleScript")
				replacement.Name = "ShroudProjectileController"
				if module then
					local parent = module.Parent
					replacement.Parent = parent
					module:Destroy()
				end
			end)
			return
		end
		crashConnection:Disconnect()
	end,
})

local updateSetting = Replicated.Settings:WaitForChild("UpdateSetting", 4)
local lowPoly = Misc:Toggle({
	Title = "Low Poly",
	Desc = "Toggle the low poly mode",
	Value = false,
	Callback = function(state)
		updateSetting:FireServer("LowGraphics", state)
		updateSetting:FireServer("KillEffectsDisabled", state)
		updateSetting:FireServer("LobbyMusicDisabled", state)
	end,
})

local autoSpin = Misc:Toggle({
	Title = "Auto Spin",
	Desc = "Automatically spin the modifier wheel",
	Value = false,
	Callback = function(state)
		getgenv().autoSpin = state
		while wait(0.1) do
			if getgenv().autoSpin and game:GetService("Players").LocalPlayer:GetAttribute("Match") then
				Replicated.Dailies.Spin:InvokeServer()
			else
				break
			end
		end
	end,
})

local Controls = Window:Tab({
	Title = "Controls",
	Icon = "keyboard",
	Locked = false,
})

local renewerSystem = Controls:Toggle({
	Title = "Delete Old Controllers",
	Desc = "Should not be disabled unless you also want to disable the options bellow",
	Value = true,
	Callback = function(state)
		local module = modules["mvsd/controllers/init.lua"]
		if not state and module then
			module:Disconnect()
			modules["mvsd/controllers/init.lua"] = nil
			return
		end
		loadModule("mvsd/controllers/init.lua")
	end,
})

local knifeController = Controls:Toggle({
	Title = "Custom Knife Controller",
	Desc = "Uses the custom knife input handler, improves support for some features of the game",
	Value = true,
	Callback = function(state)
		local module = modules["mvsd/controllers/knife.lua"]
		if not state and module then
			module:Disconnect()
			modules["mvsd/controllers/knife.lua"] = nil
			return
		end
		Windui:Notify({
			Title = "Warning",
			Content = "The custom knife controller has no mode toggle functionality (button) on mobile.",
			Duration = 4,
			Icon = "triangle-alert",
		})
		loadModule("mvsd/controllers/knife.lua")
	end,
})

local gunController = Controls:Toggle({
	Title = "Custom Gun Controller",
	Desc = "Uses the custom gun input handler, improves support for some features of the game",
	Value = true,
	Callback = function(state)
		local module = modules["mvsd/controllers/gun.lua"]
		if not state and module then
			module:Disconnect()
			modules["mvsd/controllers/gun.lua"] = nil
			return
		end
		loadModule("mvsd/controllers/gun.lua")
	end,
})

local Credits = Window:Tab({
	Title = "Credits",
	Icon = "book-marked",
	Locked = false,
})

local gooseCredit = Credits:Paragraph({
	Title = "Goose",
	Desc = "The script developer, rewrote everything from scratch, if you encounter any issues please report them at https://github.com/goose-birb/lua-buffoonery/issues",
})

local footagesusCredit = Credits:Paragraph({
	Title = "Footagesus",
	Desc = "The main developer of WindUI, a bleeding-edge UI library for Roblox. He's also the reason why the configs don't work XD",
})

Window:SelectTab(1)

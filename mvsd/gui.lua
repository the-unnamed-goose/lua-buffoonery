-- This file is licensed under the Creative Commons Attribution 4.0 International License. See https://creativecommons.org/licenses/by/4.0/legalcode.txt for details.
local Windui = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
local Repository = "https://api.bitbucket.org/2.0/repositories/lua-buffoonery/scripts/src/master/"

getgenv().aimConfig = {
	MAX_DISTANCE = 300,
	VISIBLE_PARTS = 4,
	CAMERA_CAST = true,
	FOV_CHECK = true,
	REACTION_TIME = 0.17,
	ACTION_TIME = 0.3,
	AUTO_EQUIP = true,
	NATIVE_UI = true,
	PREDICTION_TIME = 0.08,
	DEVIATION_ENABLED = true,
	AIM_DEVIATION = 10,
	RAYCAST_DISTANCE = 1000,
}
getgenv().killButton = { gun = false, knife = false }
getgenv().killLoop = { gun = false, knife = false }

local Window = Windui:CreateWindow({
	Title = "[Open Source] MVSD Script",
	Icon = "square-function",
	Author = "by Le Honk",
	Folder = "MVSD_Graphics",
	Size = UDim2.fromOffset(260, 280),
	Transparent = true,
	Theme = "Dark",
	Resizable = true,
	SideBarWidth = 120,
	HideSearchBar = true,
	ScrollBarEnabled = false,
})
local Config = Window.ConfigManager

local modules = {}
function loadModule(file)
	if modules[file] then
		return
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

local defaultConfig = Config:CreateConfig("default")
local currentConfig = defaultConfig
local saveName = "default"
function registerConfig(table)
	table:Register("AimBotEnabled", aimToggle)
	table:Register("CameraCast", cameraToggle)
	table:Register("FOVCheck", fovToggle)
	table:Register("AutoEquip", equipToggle)
	table:Register("NativeUI", interfaceToggle)
	table:Register("DeviationEnabled", deviationToggle)

	table:Register("MaxDistance", distanceSlider)
	table:Register("VisibleParts", partsSlider)
	table:Register("ReactionTime", reactionSlider)
	table:Register("ActionTime", actionSlider)
	table:Register("PredictionTime", predictionSlider)
	table:Register("DeviationAmount", deviationAmountSlider)

	table:Register("ESPEnabled", espToggle)
	table:Register("ESPTeam", teamToggle)
	table:Register("ESPEnemies", enemyToggle)

	table:Register("LoopKnife", knifeToggle)
	table:Register("LoopGun", gunToggle)
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
			module = nil
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
		Default = 300,
	},
	Callback = function(value)
		getgenv().aimConfig.MAX_DISTANCE = value
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
		getgenv().aimConfig.VISIBLE_PARTS = value
	end,
})

local reactionSlider = Aim:Slider({
	Title = "Reaction Time",
	Desc = "The amount of time the script will wait before attacking a given target, is not applied when 'Switch Weapons' is toggled",
	Step = 0.01,
	Value = {
		Min = 0,
		Max = 10,
		Default = 0.17,
	},
	Callback = function(value)
		getgenv().aimConfig.REACTION_TIME = value
	end,
})

local actionSlider = Aim:Slider({
	Title = "Action Time",
	Desc = "The amount of time the script will wait after switching or equipping a weapon before attacking a given target, is not applied when 'Switch Weapons' is not toggled",
	Step = 0.01,
	Value = {
		Min = 0.2,
		Max = 10,
		Default = 0.3,
	},
	Callback = function(value)
		getgenv().aimConfig.ACTION_TIME = value
	end,
})

local predictionSlider = Aim:Slider({
	Title = "Prediction Time",
	Desc = "How far ahead the script will predict the target location when throwing knives at them.",
	Step = 0.01,
	Value = {
		Min = 0.01,
		Max = 1,
		Default = 0.08,
	},
	Callback = function(value)
		getgenv().aimConfig.PREDICTION_TIME = value
	end,
})

local deviationAmountSlider = Aim:Slider({
	Title = "Aim Deviation Amount",
	Desc = "How bad should the misfire be, increases semi-linearly with distance and velocity.",
	Value = {
		Min = 1,
		Max = 20,
		Default = 10,
	},
	Callback = function(value)
		getgenv().aimConfig.AIM_DEVIATION = value
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
			module = nil
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
			for _, connection in pairs(module) do
				connection:Disconnect()
			end
			module = nil
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
			for _, connection in pairs(module) do
				connection:Disconnect()
			end
			module = nil
			return
		end
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
			for _, connection in pairs(module) do
				connection:Disconnect()
			end
			module = nil
			return
		end
		loadModule("mvsd/controllers/gun.lua")
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
			lockToggle("gun")
		else
			lockToggle()
		end
		getgenv().killLoop.gun = state
		loadModule("mvsd/killall.lua")
	end,
})

registerConfig(defaultConfig)
local Configs = Window:Tab({
	Title = "Config",
	Icon = "cog",
	Locked = false,
})

if defaultConfig then
	defaultConfig:Load()
end

Configs:Input({
	Title = "Config Name",
	Desc = "Must be something other than 'default' because initialization magic",
	Value = saveName,
	Callback = function(value)
		saveName = value or "default"
	end,
})

local Save = Configs:Button({
	Title = "Save",
	Desc = "Saves the current configuration down to disk",
	Callback = function()
		if not saveName then
			return
		end

		if saveName ~= "default" then
			currentConfig = Config:CreateConfig(saveName)
			registerConfig(currentConfig)
		else
			currentConfig = defaultConfig
		end

		currentConfig:Save()

		Windui:Notify({
			Title = "Save Manager",
			Content = "Saved config " .. saveName,
			Icon = "check",
			Duration = 3,
		})
	end,
})

local Default = Configs:Button({
	Title = "Save As Default",
	Desc = "Automagically load this file on startup",
	Callback = function()
		defaultConfig:Save()

		Windui:Notify({
			Title = "Save Manager",
			Content = "Successfully made config the default",
			Icon = "check",
			Duration = 3,
		})
	end,
})

local Delete = Configs:Button({
	Title = "Delete",
	Desc = "Deletes a saved configuration",
	Callback = function()
		if not saveName or saveName == "default" then
			return
		end
		delfile(Config.Path .. saveName .. ".json")

		Windui:Notify({
			Title = "Save Manager",
			Content = "Successfully deleted config",
			Icon = "check",
			Duration = 3,
		})
	end,
})

local Load = Configs:Button({
	Title = "Load",
	Desc = "Loads a saved configuration",
	Callback = function()
		if not saveName then
			return
		end

		local loadConfig = Config:CreateConfig(saveName)
		registerConfig(loadConfig)

		loadConfig:Load()
		currentConfig = loadConfig

		Windui:Notify({
			Title = "Save Manager",
			Content = "Config loaded successfully",
			Icon = "check",
			Duration = 3,
		})
	end,
})

local Credits = Window:Tab({
	Title = "Credits",
	Icon = "book-marked",
	Locked = false,
})

local gooseCredit = Credits:Paragraph({
	Title = "Goose",
	Desc = "The script developer, rewrote everything from scratch",
})

local nyxCredit = Credits:Paragraph({
	Title = "Nyx",
	Desc = "The guy behind Evelynn Hub, motivated me by committing crimes against humanity",
	Buttons = {
		{
			Icon = "message-circle-dashed",
			Title = "Join His Discord",
			Callback = function()
				setclipboard("https://discord.gg/GU64Aenm8D")
			end,
		},
	},
})

Window:SelectTab(1)
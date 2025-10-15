-- This file is licensed under the Perl Artistic License License. See https://dev.perl.org/licenses/artistic.html for more details.
local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local Replicated = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local throwStartRemote = Replicated.Remotes:WaitForChild("ThrowStart")
local throwHitRemote = Replicated.Remotes:WaitForChild("ThrowHit")
local shootRemote = Replicated.Remotes:WaitForChild("ShootGun")
local WEAPON_TYPE = { gun = "Gun_Equip", knife = "Knife_Equip" }

getgenv().controllers = getgenv().controllers
	or {
		knifeLocked = false,
		gunLocked = false,
		toolsLocked = false,
		gunCooldown = 0,
	}

local player = Players.LocalPlayer
local currentLoop = nil
local enemyCache = {}

function updateCache()
	enemyCache = {}
	for _, enemy in pairs(Players:GetPlayers()) do
		task.spawn(function()
			if enemy and enemy ~= player and enemy.Team and enemy.Team ~= player.Team then
				if enemy.Character and enemy.Character.Parent == Workspace then
					local targetPart = enemy.Character:FindFirstChild("HumanoidRootPart")
					if targetPart then
						enemyCache[enemy] = targetPart
					end
				end
			end
		end)
	end
end

local function equipWeapon(weaponType)
	local backpack = player.Backpack
	local character = player.Character
	if not character or not backpack then
		return false
	end

	while task.wait(0.2) do
		for _, tool in pairs(backpack:GetChildren()) do
			if tool:GetAttribute("EquipAnimation") == weaponType then
				character.Humanoid:EquipTool(tool)
				return
			end
		end
	end
end

local function killKnife()
	local character = player.Character
	if not character then
		return
	end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return
	end

	currentLoop = WEAPON_TYPE.knife
	for _, part in pairs(enemyCache) do
		task.spawn(function()
			if part then
				local origin = humanoidRootPart.Position
				local direction = (part.Position - origin).Unit
				throwStartRemote:FireServer(origin, direction)
				throwHitRemote:FireServer(part, part.Position)
			end
		end)
	end
	currentLoop = nil
end

local function killGun()
	local character = player.Character
	if not character then
		return
	end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then
		return
	end

	currentLoop = WEAPON_TYPE.gun
	for _, part in pairs(enemyCache) do
		task.spawn(function()
			if part then
				shootRemote:FireServer(humanoidRootPart.Position, part.Position, part, part.Position)
			end
		end)
	end
	currentLoop = WEAPON_TYPE.gun
end

local Module = {}
function Module.Load()
	if Module.Connections then
		return
	end

	Module.Connections = {}
	table.insert(Module.Connections, Run.Heartbeat:Connect(updateCache))
	table.insert(
		Module.Connections,
		player.CharacterAdded:Connect(function()
			local character = player.Character
			if not character then
				return
			end

			getgenv().controllers.gunLocked = true
			getgenv().controllers.knifeLocked = true
			equipWeapon(currentLoop)

			local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 3)
			if not humanoidRootPart or not player:GetAttribute("Match") then
				return
			end

			local anchoredConnection = humanoidRootPart:GetPropertyChangedSignal("Anchored"):Connect(function()
				if not humanoidRootPart.Anchored then
					if currentLoop == WEAPON_TYPE.gun then
						getgenv().controllers.gunLocked = false
					elseif currentLoop == WEAPON_TYPE.knife then
						getgenv().controllers.knifeLocked = false
					end

					if anchoredConnection then
						anchoredConnection:Disconnect()
					end
				end
			end)
		end)
	)
end

function Module.Unload()
	if not Module.Connections then
		return
	end

	for _, connection in ipairs(Module.Connections) do
		if connection and connection.Disconnect then
			connection:Disconnect()
		end
	end
	Module.Connections = nil
end

function Module.gunButton()
	equipWeapon(WEAPON_TYPE.gun)
	killGun()
end

function Module.knifeButton()
	equipWeapon(WEAPON_TYPE.knife)
	killKnife()
end

function Module.gunToggle()
	table.insert(
		Module.Connections,
		Run.RenderStepped:Connect(function()
			if not getgenv().controllers.gunLocked then
				killGun()
			end
		end)
	)
end

function Module.knifeToggle()
	table.insert(
		Module.Connections,
		Run.RenderStepped:Connect(function()
			if not getgenv().controllers.knifeLocked then
				killKnife()
			end
		end)
	)
end

return Module

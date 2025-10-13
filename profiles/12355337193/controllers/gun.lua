-- This file is licensed under the Perl Artistic License License. See https://dev.perl.org/licenses/artistic.html for more details.
local Replicated = game:GetService("ReplicatedStorage")
local Input = game:GetService("UserInputService")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local CollisionGroups = require(Replicated.Modules.CollisionGroups)
local WeaponRaycast = require(Replicated.Modules.WeaponRaycast)
local Maid = require(Replicated.Modules.Util.Maid)
local CharacterRayOrigin = require(Replicated.Modules.CharacterRayOrigin)
local BulletRenderer = require(Replicated.Modules.BulletRenderer)
local Tags = require(Replicated.Modules.Tags)

getgenv().controllers = getgenv().controllers
	or {
		knifeLocked = false,
		gunLocked = false,
		toolsLocked = false,
		gunCooldown = 0,
	}

local MUZZLE_ATTACHMENT_NAME = "Muzzle"
local FIRE_SOUND_NAME = "Fire"
local DEFAULT_RAYCAST_DISTANCE = 2000
local MOUSE_RAYCAST_OFFSET = 50

local currentCamera = workspace.CurrentCamera
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local mouse = player:GetMouse()

local shootGunRemote = Replicated.Remotes.ShootGun
local maid = Maid.new()
local currentTool = nil

local function canShoot(tool)
	local cooldown = tool:GetAttribute("Cooldown")
	if not cooldown then
		return true
	end
	if getgenv().controllers.gunCooldown == 0 then
		return true
	end
	return (tick() - getgenv().controllers.gunCooldown) >= cooldown
end

local function shootGun(tool, targetPosition)
	if getgenv().controllers.gunLocked or getgenv().controllers.toolsLocked then
		return
	end
	getgenv().controllers.gunLocked = true

	if not canShoot(tool) then
		getgenv().controllers.gunLocked = false
		return
	end

	local muzzleAttachment = tool:FindFirstChild(MUZZLE_ATTACHMENT_NAME, true)
	if not muzzleAttachment then
		warn("Muzzle attachment not found for gun: " .. tool.Name)
		getgenv().controllers.gunLocked = false
		return
	end

	getgenv().controllers.gunCooldown = tick()
	if not targetPosition then
		targetPosition = mouse.Hit.Position + (MOUSE_RAYCAST_OFFSET * mouse.UnitRay.Direction)
	end

	local screenRayResult =
		WeaponRaycast(currentCamera.CFrame.Position, targetPosition, nil, CollisionGroups.SCREEN_RAYCAST)
	local characterOrigin = CharacterRayOrigin(character)
	if not characterOrigin then
		getgenv().controllers.gunLocked = false
		return
	end

	local finalTarget = targetPosition
	if screenRayResult and screenRayResult.Position then
		finalTarget = screenRayResult.Position
	end

	local worldRayResult = WeaponRaycast(characterOrigin, finalTarget)
	local hitResult = worldRayResult or screenRayResult

	local fireSound = tool:FindFirstChild(FIRE_SOUND_NAME)
	if fireSound then
		fireSound:Play()
	end

	BulletRenderer(muzzleAttachment.WorldPosition, finalTarget, tool:GetAttribute("BulletType"))
	tool:Activate()

	local hitInstance = hitResult and hitResult.Instance
	local hitPosition = hitResult and hitResult.Position
	shootGunRemote:FireServer(characterOrigin, finalTarget, hitInstance, hitPosition)
	getgenv().controllers.gunLocked = false
end

local function handleGunInput(tool)
	maid:GiveTask(Input.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.KeyCode == Enum.KeyCode.ButtonR2 then
			shootGun(tool)
		end
	end))

	maid:GiveTask(Input.TouchTapInWorld:Connect(function(position, gameProcessed)
		if gameProcessed then
			return
		end
		local worldPosition = WeaponRaycast.convertScreenPointToVector3(position, DEFAULT_RAYCAST_DISTANCE)
		shootGun(tool, worldPosition)
	end))
end

local function onGunEquipped(tool)
	maid:DoCleaning()
	currentTool = tool
	handleGunInput(tool)

	maid:GiveTask(tool.AncestryChanged:Connect(function()
		if not tool:IsDescendantOf(character) then
			maid:DoCleaning()
			currentTool = nil
		end
	end))
end

local characterConnection
return player.CharacterAdded:Connect(function(new)
	character = new
	humanoid = character:WaitForChild("Humanoid")
	animator = humanoid:WaitForChild("Animator")

	if characterConnection then
		characterConnection:Disconnect()
	end

	characterConnection = character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and CollectionService:HasTag(child, Tags.GUN_TOOL) then
			onGunEquipped(child)
		end
	end)

	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Tool") and CollectionService:HasTag(child, Tags.GUN_TOOL) then
			onGunEquipped(child)
		end
	end
end)

-- This file is licensed under the Perl Artistic License License. See https://dev.perl.org/licenses/artistic.html for more details.
local Replicated = game:GetService("ReplicatedStorage")
local Input = game:GetService("UserInputService")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local ContextActionService = game:GetService("ContextActionService")
local CollectionService = game:GetService("CollectionService")

local CollisionGroups = require(Replicated.Modules.CollisionGroups)
local WeaponRaycast = require(Replicated.Modules.WeaponRaycast)
local Promise = require(Replicated.Modules.Util.Promise)
local Maid = require(Replicated.Modules.Util.Maid)
local CharacterRayOrigin = require(Replicated.Modules.CharacterRayOrigin)
local KnifeProjectileController = require(Replicated.Modules.KnifeProjectileController)
local Hitbox = require(Replicated.Modules.Hitbox)
local Tags = require(Replicated.Modules.Tags)

getgenv().controllers = getgenv().controllers
	or {
		knifeLocked = false,
		gunLocked = false,
		toolsLocked = false,
		gunCooldown = 0,
	}

local THROW_ANIMATION_SPEED = 1.4
local CHARGE_DELAY = 0.25
local KNIFE_HANDLE_NAME = "RightHandle"

local currentCamera = workspace.CurrentCamera
local player = Players.LocalPlayer
local mouse = player:GetMouse()

local throwAnimation = Replicated.Animations.Throw
local throwStartRemote = Replicated.Remotes.ThrowStart
local throwHitRemote = Replicated.Remotes.ThrowHit
local stabRemote = Replicated.Remotes.Stab

local character
local isStabMode = false
local currentThrowPromise = nil
local currentTool = nil
local maid = Maid.new()

local hasMouseEnabled = Input.MouseEnabled

-- Find the existing UI controls
local function getKnifeControls()
	local controls = StarterGui:FindFirstChild("Controls")
	if not controls then
		return nil
	end

	local knifeControl = controls:FindFirstChild("KnifeControl")
	if not knifeControl then
		return nil
	end

	return knifeControl
end

local function getControlButtons()
	local knifeControl = getKnifeControls()
	if not knifeControl then
		return nil, nil, nil, nil
	end

	local pcControls = knifeControl:FindFirstChild("PC")
	local gamepadControls = knifeControl:FindFirstChild("Gamepad")

	local throwButton = pcControls and pcControls:FindFirstChild("Throw")
	local stabButton = pcControls and pcControls:FindFirstChild("Stab")

	return throwButton, stabButton, pcControls, gamepadControls
end

local function getThrowDirection(targetPosition, hrpPosition)
	local screenRayResult =
		WeaponRaycast(currentCamera.CFrame.Position, targetPosition, nil, CollisionGroups.SCREEN_RAYCAST)
	local finalTarget = targetPosition

	if screenRayResult and screenRayResult.Position then
		local worldRayResult = WeaponRaycast(hrpPosition, screenRayResult.Position)
		if worldRayResult and worldRayResult.Position then
			finalTarget = worldRayResult.Position
		else
			finalTarget = screenRayResult.Position
		end
	end

	return (finalTarget - hrpPosition).Unit
end

local function setKnifeHandleTransparency(tool, transparency)
	local rightHandle = tool:FindFirstChild(KNIFE_HANDLE_NAME)
	if not rightHandle then
		return
	end

	rightHandle.LocalTransparencyModifier = transparency

	for _, descendant in ipairs(rightHandle:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.LocalTransparencyModifier = transparency
		elseif descendant:IsA("Trail") then
			descendant.Enabled = transparency < 1
		end
	end
end

local function throwKnife(tool, targetPosition, isManualActivation)
	if getgenv().controllers.knifeLocked or getgenv().controllers.toolsLocked then
		return
	end

	if currentThrowPromise or not tool.Enabled then
		return
	end

	local knifeHandle = tool:FindFirstChild(KNIFE_HANDLE_NAME)
	if not knifeHandle then
		return
	end

	local hrpPosition = targetPosition and CharacterRayOrigin(character)
	local throwDirection

	if targetPosition then
		throwDirection = getThrowDirection(targetPosition, hrpPosition)
	end

	local function createKnifeProjectile()
		if not hrpPosition then
			hrpPosition = CharacterRayOrigin(character)
			if not hrpPosition then
				return
			end
		end

		if not throwDirection then
			throwDirection = getThrowDirection(targetPosition, hrpPosition)
		end

		setKnifeHandleTransparency(tool, 1)
		throwStartRemote:FireServer(hrpPosition, throwDirection)
		KnifeProjectileController({
			Speed = tool:GetAttribute("ThrowSpeed"),
			KnifeProjectile = knifeHandle:Clone(),
			Direction = throwDirection,
			Origin = hrpPosition,
		}, function(hitResult)
			local hitInstance = hitResult and hitResult.Instance
			local hitPosition = hitResult and hitResult.Position
			throwHitRemote:FireServer(hitInstance, hitPosition)
		end)
	end

	if not hasMouseEnabled then
		local humanoid = character and character:FindFirstChild("Humanoid")
		local animator = humanoid and humanoid:FindFirstChild("Animator")
		if not animator then
			return
		end

		local throwAnimationTrack = animator:LoadAnimation(throwAnimation)

		currentThrowPromise = Promise.new(function(resolve, reject, onCancel)
			onCancel(function()
				throwAnimationTrack:Stop(0)
			end)

			throwAnimationTrack:GetMarkerReachedSignal("Completed"):Connect(function()
				if not targetPosition then
					targetPosition = mouse.Hit.Position
				end
				resolve()
			end)

			throwAnimationTrack.Ended:Connect(function()
				setKnifeHandleTransparency(tool, 0)
				currentThrowPromise = nil
				throwAnimationTrack:Destroy()
			end)

			throwAnimationTrack:Play(nil, nil, THROW_ANIMATION_SPEED)
		end):andThen(function()
			createKnifeProjectile()
		end)

		maid:GiveTask(function()
			if currentThrowPromise then
				currentThrowPromise:cancel()
			end
		end)
	else
		createKnifeProjectile()
	end
end

local function handleStabInput(tool)
	local hitTargets = {}

	local hitboxController = Hitbox(tool, function(hitResult)
		local hitCharacter = hitResult.Instance.Parent
		local targetHumanoid = hitCharacter and hitCharacter:FindFirstChild("Humanoid")

		if not targetHumanoid or hitTargets[hitCharacter] then
			return
		end

		hitTargets[hitCharacter] = true
		stabRemote:FireServer(hitResult.Instance)
	end)

	maid:GiveTask(tool:GetAttributeChangedSignal("IsActivated"):Connect(function()
		if tool:GetAttribute("IsActivated") then
			hitboxController.Activate()
		else
			hitTargets = {}
			hitboxController.Deactivate()
		end
	end))

	maid:GiveTask(tool.Activated:Connect(function()
		if getgenv().controllers.knifeLocked or getgenv().controllers.toolsLocked then
			return
		end

		if isStabMode then
			hitboxController.Activate()
			wait(0.1)
			hitboxController.Deactivate()
			hitTargets = {}
		end
	end))

	maid:GiveTask(function()
		hitboxController.Deactivate()
	end)
end

local function handleMouseThrowInput(tool)
	local humanoid = character and character:FindFirstChild("Humanoid")
	local animator = humanoid and humanoid:FindFirstChild("Animator")
	if not animator then
		return
	end

	local chargeAnimationTrack = animator:LoadAnimation(throwAnimation)
	local isCharged = false
	local chargePromise = nil

	maid:GiveTask(chargeAnimationTrack:GetMarkerReachedSignal("Completed"):Connect(function()
		isCharged = true
		chargeAnimationTrack:AdjustSpeed(0)
	end))

	maid:GiveTask(chargeAnimationTrack.Ended:Connect(function()
		isCharged = false
		setKnifeHandleTransparency(tool, 0)
	end))

	maid:GiveTask(Input.InputBegan:Connect(function(input, gameProcessed)
		if
			gameProcessed
			or input.UserInputType ~= Enum.UserInputType.MouseButton1
			or chargeAnimationTrack.IsPlaying
			or isCharged
			or isStabMode
		then
			return
		end

		chargePromise = Promise.delay(CHARGE_DELAY):andThen(function()
			chargeAnimationTrack:Play(nil, nil, THROW_ANIMATION_SPEED)
		end)
	end))

	maid:GiveTask(Input.InputEnded:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end

		if isStabMode then
			tool:Activate()
			return
		end

		if not chargePromise then
			return
		end

		chargePromise:cancel()
		chargePromise = nil

		if not chargeAnimationTrack.IsPlaying or not isCharged then
			chargeAnimationTrack:Stop()
			task.wait()
			tool:Activate()
			return
		end

		chargeAnimationTrack:AdjustSpeed(1)
		throwKnife(tool, mouse.Hit.Position)
	end))

	maid:GiveTask(function()
		if chargePromise then
			chargePromise:cancel()
		end
		chargeAnimationTrack:Stop()
		setKnifeHandleTransparency(tool, 0)
	end)
end

local function setupUIConnections(tool)
	local throwButton, stabButton, pcControls, gamepadControls = getControlButtons()

	if throwButton then
		maid:GiveTask(throwButton.MouseButton1Click:Connect(function()
			throwKnife(tool, mouse.Hit.Position, true)
		end))
	end

	if stabButton then
		maid:GiveTask(stabButton.MouseButton1Click:Connect(function()
			tool:Activate()
		end))
	end

	-- Also connect gamepad buttons if they exist
	if gamepadControls then
		local gamepadThrow = gamepadControls:FindFirstChild("Throw")
		local gamepadStab = gamepadControls:FindFirstChild("Stab")

		if gamepadThrow then
			maid:GiveTask(gamepadThrow.MouseButton1Click:Connect(function()
				throwKnife(tool, mouse.Hit.Position, true)
			end))
		end

		if gamepadStab then
			maid:GiveTask(gamepadStab.MouseButton1Click:Connect(function()
				tool:Activate()
			end))
		end
	end
end

local function handleThrowInput(tool)
	-- Connect to existing UI buttons
	setupUIConnections(tool)

	if hasMouseEnabled and Input.MouseEnabled then
		tool.ManualActivationOnly = true
		handleMouseThrowInput(tool)
	else
		ContextActionService:BindAction("Throw", function(actionName, inputState)
			if actionName == "Throw" and inputState == Enum.UserInputState.Begin then
				if isStabMode then
					tool:Activate()
				else
					throwKnife(tool, nil, true)
				end
			end
		end, false, Enum.KeyCode.E, Enum.KeyCode.ButtonL2)

		maid:GiveTask(function()
			ContextActionService:UnbindAction("Throw")
		end)
	end

	maid:GiveTask(Input.TouchTapInWorld:Connect(function(position, gameProcessed)
		if gameProcessed then
			return
		end

		if isStabMode then
			tool:Activate()
		else
			local worldPosition = WeaponRaycast.convertScreenPointToVector3(position, 2000)
			throwKnife(tool, worldPosition)
		end
	end))
end

local function onKnifeEquipped(tool)
	maid:DoCleaning()
	currentTool = tool

	tool.ManualActivationOnly = isStabMode

	maid:GiveTask(function()
		currentTool = nil
	end)

	handleStabInput(tool)
	handleThrowInput(tool)

	maid:GiveTask(tool.AncestryChanged:Connect(function()
		if not tool:IsDescendantOf(character) then
			maid:DoCleaning()
		end
	end))
end

return player.CharacterAdded:Connect(function(new)
	character = new

	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and CollectionService:HasTag(child, Tags.KNIFE_TOOL) then
			onKnifeEquipped(child)
		end
	end)

	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Tool") and CollectionService:HasTag(child, Tags.KNIFE_TOOL) then
			onKnifeEquipped(child)
		end
	end
end)

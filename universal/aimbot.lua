-- This file is licensed under the Perl Artistic License License. See https://dev.perl.org/licenses/artistic.html for more details.
local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local Input = game:GetService("UserInputService")

local camera = workspace.CurrentCamera
local localPlayer = Players.LocalPlayer

getgenv().aimConfig = getgenv().aimConfig
	or {
		targetPart = "Head",
		fovDeg = 15,
		triggerFovDeg = 2,
		smoothness = 0.25,
		prediction = 0.05,
		maxDistance = 500,
		useRay = true,
		respectTeams = false,
		triggerBot = true,
		triggerMode = "button",
		triggerAction = nil,
		triggerClosure = nil,
	}

local currentTarget = nil
local lastTargetTime = 0
local connection = nil
local lastAimDirection = camera.CFrame.LookVector
local targetSwitchProgress = 0
local targetSwitchDuration = 0.3

local function isValid(player)
	if player == localPlayer then
		return false
	end

	if getgenv().aimConfig.respectTeams and localPlayer.Team and player.Team == localPlayer.Team then
		return false
	end

	local character = player.Character
	if not character then
		return false
	end

	local humanoid = character:FindFirstChild("Humanoid")
	local targetPart = character:FindFirstChild(getgenv().aimConfig.targetPart)

	if humanoid and humanoid.Health > 0 and targetPart then
		local localCharacter = localPlayer.Character
		if localCharacter then
			local humanoidRootPart = localCharacter:FindFirstChild("HumanoidRootPart")
			if humanoidRootPart then
				return targetPart.Position.Y > (humanoidRootPart.Position.Y - 0.5)
			end
		end
		return true
	end

	return false
end

local function isVisible(character, part)
	if not getgenv().aimConfig.useRay then
		return true
	end

	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = { localPlayer.Character, camera }
	rayParams.FilterType = Enum.RaycastFilterType.Blacklist
	rayParams.IgnoreWater = true

	local rayDirection = part.Position - camera.CFrame.Position
	local rayResult = workspace:Raycast(camera.CFrame.Position, rayDirection, rayParams)

	return not rayResult or rayResult.Instance:IsDescendantOf(character)
end

local function findTarget()
	local config = getgenv().aimConfig
	local camPosition = camera.CFrame.Position
	local camLook = camera.CFrame.LookVector
	local bestTarget = nil
	local bestDot = -1

	for _, player in ipairs(Players:GetPlayers()) do
		if not isValid(player) then
			continue
		end

		local character = player.Character
		local part = character:FindFirstChild(config.targetPart)
		if not part then
			continue
		end

		local distance = (camPosition - part.Position).Magnitude
		if distance > config.maxDistance then
			continue
		end

		if not isVisible(character, part) then
			continue
		end

		local partPosition = part.Position
		if config.prediction > 0 then
			local rootPart = character:FindFirstChild("HumanoidRootPart")
			if rootPart then
				partPosition = partPosition + rootPart.Velocity * config.prediction
			end
		end

		local direction = (partPosition - camPosition).Unit
		local dotProduct = camLook:Dot(direction)
		local fovCheck = dotProduct > math.cos(math.rad(config.fovDeg))

		if fovCheck and dotProduct > bestDot then
			bestDot = dotProduct
			bestTarget = {
				player = player,
				character = character,
				part = part,
				position = partPosition,
				distance = distance,
				dotProduct = dotProduct,
			}
		end
	end

	return bestTarget
end

local function isAimable(target)
	if not target then
		return false
	end

	local camPosition = camera.CFrame.Position
	local camLook = camera.CFrame.LookVector
	local targetPosition = target.position

	local direction = (targetPosition - camPosition).Unit
	local dotProduct = camLook:Dot(direction)
	local triggerFovCheck = dotProduct > math.cos(math.rad(getgenv().aimConfig.triggerFovDeg))

	return triggerFovCheck and isVisible(target.character, target.part)
end

local function trigger()
	if not getgenv().aimConfig.triggerBot then
		return
	end

	local closure = getgenv().aimConfig.triggerClosure
	local mode = getgenv().aimConfig.triggerMode
	local element = getgenv().aimConfig.triggerAction
	if mode == "mouse1" then
		mouse1click()
	elseif mode == "mouse2" then
		mouse2click()
	elseif mode == "closure" and closure and type(closure) == "function" then
		closure()
	elseif element then
		if element:IsA("ClickDetector") and element.MouseClick then
			if firesignal then
				firesignal(element.MouseClick)
			elseif replicatesignal then
				replicatesignal(element.MouseClick)
			end
		elseif element.Activated then
			if firesignal then
				firesignal(element.Activated)
			elseif replicatesignal then
				replicatesignal(element.Activated)
			end
		end
	end
end

local function smoothAim(targetPosition, deltaTime, isNewTarget)
	local camPosition = camera.CFrame.Position
	local desiredLook = (targetPosition - camPosition).Unit

	if isNewTarget then
		targetSwitchProgress = 0
	else
		targetSwitchProgress = math.min(targetSwitchProgress + deltaTime / targetSwitchDuration, 1)
	end

	local smoothFactor = getgenv().aimConfig.smoothness * deltaTime * 60
	local switchEase = 1 - math.cos(targetSwitchProgress * math.pi * 0.5)

	local currentLook = camera.CFrame.LookVector
	local smoothedLook = currentLook:Lerp(desiredLook, smoothFactor + switchEase * 0.5)

	lastAimDirection = smoothedLook
	camera.CFrame = CFrame.new(camPosition, camPosition + smoothedLook)
end

-- I miss Rust ...
local function main(deltaTime)
	local config = getgenv().aimConfig
	if not config then
		return
	end

	local newTarget = findTarget()
	local isNewTarget = false

	if newTarget then
		if not currentTarget or newTarget.player ~= currentTarget.player then
			isNewTarget = true
			currentTarget = newTarget
			lastTargetTime = tick()
		else
			currentTarget = newTarget
		end
	else
		currentTarget = nil
		targetSwitchProgress = 0
	end

	if currentTarget then
		smoothAim(currentTarget.position, deltaTime, isNewTarget)

		if isAimable(currentTarget) then
			trigger()
		end
	end
end

return Run.RenderStepped:Connect(main)

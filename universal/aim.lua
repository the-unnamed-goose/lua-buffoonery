-- This file is licensed under the Perl Artistic License. See https://dev.perl.org/licenses/artistic.html for more details.
local Input = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Run = game:GetService("RunService")

local camera = workspace.CurrentCamera
local player = Players.LocalPlayer

getgenv().aimConfig = getgenv().aimConfig
	or {
		enabled = true,
		targetPart = "Head",
		aimMode = "camera",
		runPriority = 10,
		useHook = true,

		fovDeg = 25,
		triggerFovDeg = 2,
		smoothness = 0.25,
		prediction = 0.02,
		maxDistance = 500,

		jitterEnabled = true,
		jitterIntensity = 0.3,
		jitterFrequency = 2.0,
		jitterPattern = "circular",
		jitterScale = 0.5,
		maxJitterOffset = 3.0,

		useRay = true,
		respectTeams = false,
		lockCamera = true,

		triggerBot = true,
		triggerMode = "button",
		triggerAction = nil,
		triggerClosure = nil,
	}

local currentTarget = nil
local targetSwitchProgress = 0
local targetSwitchDuration = 0.3
local jitterTime = 0
local lastJitterOffset = Vector3.zero
local perlinSeed = math.random(1, 10000)
local cameraHook

task.spawn(function()
	if not getgenv().aimConfig.useHook then
		return
	end

	cameraHook = hookmetamethod(
		camera,
		"__newindex",
		newcclosure(function(self, key, value, ...)
			if getgenv().aimConfig.enabled and not checkcaller() and getthreadidentity() < 3 and key == "CFrame" then
				if currentTarget and getgenv().aimConfig.lockCamera then
					local rotation = camera.CFrame - camera.CFrame.Position
					return cameraHook(self, key, rotation + value.Position, ...)
				end
			end
			return cameraHook(self, key, value, ...)
		end)
	)
	getgenv().aimConfig.useHook = true
end)

local function perlinNoise(x, y, seed)
	local X = math.floor(x) or 255
	local Y = math.floor(y) or 255
	x = x - math.floor(x)
	y = y - math.floor(y)

	local u = x * x * x * (x * (x * 6 - 15) + 10)
	local v = y * y * y * (y * (y * 6 - 15) + 10)

	local A = (seed + X) or 255
	local B = (seed + X + 1) or 255
	local AA = (seed + A + Y) or 255
	local AB = (seed + A + Y + 1) or 255
	local BA = (seed + B + Y) or 255
	local BB = (seed + B + Y + 1) or 255

	local grad = function(hash, x, y)
		local h = hash or 3
		local u = h == 0 and x or y
		local v = h == 0 and y or x
		return ((h or 2) == 0 and u or -u) + ((h or 1) == 0 and v or -v)
	end

	return math.clamp(
		math.lerp(
			math.lerp(grad(AA, x, y), grad(BA, x - 1, y), u),
			math.lerp(grad(AB, x, y - 1), grad(BB, x - 1, y - 1), u),
			v
		) * 1.5,
		-1,
		1
	)
end

local function getJitter(deltaTime, distance)
	local config = getgenv().aimConfig
	if not config.jitterEnabled or config.jitterIntensity <= 0 then
		return Vector3.zero
	end

	jitterTime = jitterTime + deltaTime

	local distanceScale = math.clamp(1 - (distance / config.maxDistance) * config.jitterScale, 0.1, 1.0)
	local intensity = config.jitterIntensity * distanceScale
	local maxOffsetRad = math.rad(config.maxJitterOffset) * intensity

	local jitterX, jitterY = 0, 0

	if config.jitterPattern == "perlin" then
		local timeScaled = jitterTime * config.jitterFrequency
		jitterX = perlinNoise(timeScaled, perlinSeed, perlinSeed) * maxOffsetRad
		jitterY = perlinNoise(timeScaled + 100, perlinSeed + 100, perlinSeed) * maxOffsetRad
	elseif config.jitterPattern == "circular" then
		local angle = jitterTime * config.jitterFrequency * 2 * math.pi
		local radius = maxOffsetRad * 0.7
		jitterX = math.cos(angle) * radius
		jitterY = math.sin(angle * 1.3) * radius * 0.8
	else
		if jitterTime % (0.5 / config.jitterFrequency) < deltaTime then
			lastJitterOffset =
				Vector3.new((math.random() * 2 - 1) * maxOffsetRad, (math.random() * 2 - 1) * maxOffsetRad, 0)
		end
		jitterX = lastJitterOffset.X
		jitterY = lastJitterOffset.Y
	end

	local easeFactor = math.min(deltaTime * 10, 1)
	jitterX = math.lerp(lastJitterOffset.X, jitterX, easeFactor)
	jitterY = math.lerp(lastJitterOffset.Y, jitterY, easeFactor)

	lastJitterOffset = Vector3.new(jitterX, jitterY, 0)
	return lastJitterOffset
end

local function applyJitter(direction, jitterOffset)
	if jitterOffset == Vector3.zero then
		return direction
	end

	local right = direction:Cross(Vector3.new(0, 1, 0)).Unit
	local up = right:Cross(direction).Unit

	local jittered = direction + right * jitterOffset.X + up * jitterOffset.Y
	return jittered.Unit
end

local function isValid(target)
	if target == player then
		return false
	end

	local config = getgenv().aimConfig
	if config.respectTeams and target.Team and target.Team == player.Team then
		return false
	end

	local character = target.Character
	if not character then
		return false
	end

	local humanoid = character:FindFirstChild("Humanoid")
	local targetPart = character:FindFirstChild(config.targetPart)

	if not (humanoid and humanoid.Health > 0 and targetPart) then
		return false
	end

	local localChar = player.Character
	if localChar then
		local root = localChar:FindFirstChild("HumanoidRootPart")
		if root then
			return targetPart.Position.Y > (root.Position.Y - 0.5)
		end
	end

	return true
end

local function isVisible(character, part)
	if not getgenv().aimConfig.useRay then
		return true
	end

	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = { player.Character, camera }
	rayParams.FilterType = Enum.RaycastFilterType.Blacklist
	rayParams.IgnoreWater = true

	local rayDir = part.Position - camera.CFrame.Position
	local result = workspace:Raycast(camera.CFrame.Position, rayDir, rayParams)

	return not result or result.Instance:IsDescendantOf(character)
end

local function findTarget()
	local config = getgenv().aimConfig
	local camPos = camera.CFrame.Position
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

		local distance = (camPos - part.Position).Magnitude
		if distance > config.maxDistance then
			continue
		end

		if not isVisible(character, part) then
			continue
		end

		local partPos = part.Position
		if config.prediction > 0 then
			local root = character:FindFirstChild("HumanoidRootPart")
			if root then
				partPos = partPos + root.Velocity * config.prediction
			end
		end

		local dir = (partPos - camPos).Unit
		local dot = camLook:Dot(dir)
		local fovCheck = dot > math.cos(math.rad(config.fovDeg))

		if fovCheck and dot > bestDot then
			bestDot = dot
			bestTarget = {
				player = player,
				character = character,
				part = part,
				position = partPos,
				distance = distance,
				dotProduct = dot,
			}
		end
	end

	return bestTarget
end

local function canAim(target)
	if not target then
		return false
	end

	local camPos = camera.CFrame.Position
	local camLook = camera.CFrame.LookVector
	local targetPos = target.position

	local dir = (targetPos - camPos).Unit
	local dot = camLook:Dot(dir)
	local triggerFov = dot > math.cos(math.rad(getgenv().aimConfig.triggerFovDeg))

	return triggerFov and isVisible(target.character, target.part)
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
	elseif mode == "closure" and type(closure) == "function" then
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

local function aimAt(targetPos, deltaTime, isNewTarget)
	local config = getgenv().aimConfig

	if config.aimMode == "mouse" then
		local camPos = camera.CFrame.Position
		local screenPoint, visible = camera:WorldToScreenPoint(targetPos)
		if visible then
			local viewport = camera.ViewportSize
			local center = Vector2.new(viewport.X / 2, viewport.Y / 2)
			local targetScreen = Vector2.new(screenPoint.X, screenPoint.Y)

			local delta = targetScreen - center

			if isNewTarget then
				targetSwitchProgress = 0
			else
				targetSwitchProgress = math.min(targetSwitchProgress + deltaTime / targetSwitchDuration, 1)
			end

			local smooth = config.smoothness * deltaTime * 60
			local ease = 1 - math.cos(targetSwitchProgress * math.pi * 0.5)
			local blend = math.min(smooth + ease * 0.5, 1)

			local smoothed = delta * blend
			mousemoverel(smoothed.X, smoothed.Y)
		end
	else
		local currentCF = camera.CFrame
		local camPos = currentCF.Position

		local desiredLook = (targetPos - camPos).Unit
		local distance = (targetPos - camPos).Magnitude
		local jitter = getJitter(deltaTime, distance)
		local jitteredLook = applyJitter(desiredLook, jitter)

		if isNewTarget then
			targetSwitchProgress = 0
		else
			targetSwitchProgress = math.min(targetSwitchProgress + deltaTime / targetSwitchDuration, 1)
		end

		local smooth = config.smoothness * deltaTime * 60
		local ease = 1 - math.cos(targetSwitchProgress * math.pi * 0.5)

		local currentLook = currentCF.LookVector
		local smoothedLook = currentLook:Lerp(jitteredLook, smooth + ease * 0.5)

		if config.lockCamera and currentTarget then
			camera.CFrame = CFrame.new(camPos, camPos + smoothedLook)
		else
			camera.CFrame = CFrame.new(camPos, camPos + smoothedLook)
		end
	end
end

local function main(deltaTime)
	local config = getgenv().aimConfig
	if not config then
		return
	end

	local newTarget = findTarget()
	local isNew = false

	if newTarget then
		if not currentTarget or newTarget.player ~= currentTarget.player then
			isNew = true
			currentTarget = newTarget
		else
			currentTarget = newTarget
		end
	else
		currentTarget = nil
		targetSwitchProgress = 0
		jitterTime = 0
		lastJitterOffset = Vector3.zero
	end

	if currentTarget then
		aimAt(currentTarget.position, deltaTime, isNew)

		if canAim(currentTarget) then
			trigger()
		end
	end
end

local Module = {}
function Module:Load()
	if Module.Connection then
		return
	end
	Module.Connection = Run:BindToRenderStep("Camera", 1e+10 * getgenv().aimConfig.runPriority, main)
end

function Module:Unload()
	if not Module.Connection then
		return
	end

	Module.Connection:Disconnect()
end

function Module:Drop()
	if cameraHook then
		local metatable = table.clone(getrawmetatable(camera))
		metatable.__newindex = cameraHook
		setrawmetatable(camera, metatable)
	end
end

return Module:Load()

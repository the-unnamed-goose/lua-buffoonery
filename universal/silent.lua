-- This file is licensed under the Perl Artistic License License. See https://dev.perl.org/licenses/artistic.html for more details.
local Players = game:GetService("Players")
local Run = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local getPlayers = Players.GetPlayers
local findChild = game.FindFirstChild
local dotProduct = Vector3.new().Dot

local visible = {}
local params = RaycastParams.new()
params.IgnoreWater = true
params.FilterType = Enum.RaycastFilterType.Blacklist

getgenv().silentConfig = getgenv().silentConfig
	or {
		maxAngle = 15,
		maxCosine = math.cos(math.rad(15)), -- used for performance reasons
		targetPart = "Head",
		rootPart = "HumanoidRootPart", -- To be used on custom characters
		checkClosure = nil,
	}

local function getDirection(origin, position)
	return (position - origin).Unit
end

local function getAlpha(vec1, vec2)
	local dot = dotProduct(vec1, vec2)
	dot = math.clamp(dot, -1, 1)
	return math.deg(math.acos(dot))
end

local function findTarget(origin, direction)
	local closest, minAngle = nil, getgenv().silentConfig.maxAngle
	local directionUnit = direction.Unit
	local localCharacter = player.Character or findChild(workspace, player.Name)

	for _, plr in pairs(getPlayers(Players)) do
		if plr == player then
			continue
		end

		local character = plr.Character or findChild(workspace, plr.Name)
		local part = character and findChild(character, getgenv().silentConfig.targetPart)
		local humanoid = character and findChild(character, "Humanoid")
		if not part or not humanoid or not (humanoid.Health > 0) then
			continue
		end

		local closure = getgenv().silentConfig.checkClosure
		if type(closure) == "function" and not closure(plr, character, part) then
			continue
		end

		local targetDirection = getDirection(origin, part.Position)
		local dot = dotProduct(directionUnit, targetDirection)

		if dot <= getgenv().silentConfig.maxAlpha then
			continue
		end

		if not visible[plr] then
			continue
		end

		local angle = getAlpha(directionUnit, targetDirection)
		if angle <= minAngle then
			closest = part
			minAngle = angle
		end
	end
	return closest, minAngle
end

Run.Heartbeat:Connect(function()
	for _, plr in pairs(getPlayers(Players)) do
		if plr == player then
			continue
		end

		local localCharacter = player.Character or findChild(workspace, player.Name)
		local character = plr.Character or findChild(workspace, plr.Name)
		local origin = localCharacter and findChild(localCharacter, getgenv().silentConfig.rootPart)
		local part = character and findChild(character, getgenv().silentConfig.targetPar)
		if not origin or not part then
			continue
		end

		local direction = getDirection(origin.Position, part.Position) * 1000
		local result = workspace:Raycast(origin.Position, direction)
		if not result or not result.Instance then
			continue
		end

		if result.Instance:IsDescendantOf(character) then
			visible[plr] = true
		else
			visible[plr] = nil
		end
	end
end)

Players.PlayerRemoving:Connect(function(plr)
	visible[plr] = nil
end)

local worldroot
worldroot = hookmetamethod(
	workspace,
	"__namecall",
	newcclosure(function(...)
		local method = getnamecallmethod()
		local args = { ... }

		if method == "Raycast" and not checkcaller() then
			local origin = args[2]
			local direction = args[3]
			local target = findTarget(origin, direction)
			if target then
				args[3] = getDirection(origin, target.Position) * direction.Magnitude
				return worldroot(unpack(args))
			end
		-- https://create.roblox.com/docs/reference/engine/classes/WorldRoot#findPartOnRay
		elseif
			method == "findPartOnRay"
			or method == "FindPartOnRay"
			or method == "FindPartOnRayWithIgnoreList"
			or method == "FindPartOnRayWithWhitelist" and not checkcaller()
		then
			local ray = args[2]
			local origin = ray.Origin
			local direction = ray.Direction
			local target = findTarget(origin, direction)
			if target then
				args[2] = Ray.new(origin, getDirection(origin, target.Position) * direction.Magnitude)
				return worldroot(unpack(args))
			end
		end
		return worldroot(...)
	end)
)

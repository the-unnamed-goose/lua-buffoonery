<<<<<<< HEAD
-- This file is licensed under the Perl Artistic License License. See https://dev.perl.org/licenses/artistic.html for more details.
=======
-- Heavily inspired from Averiias's Universal-SilentAim
>>>>>>> development
local Players = game:GetService("Players")
local Run = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
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
		enabled = true,
		
		maxAngle = 15,
		maxCosine = math.cos(math.rad(15)),
		checkClosure = nil,
		
		targetPart = "Head",
		rootPart = "HumanoidRootPart",
		
		prediction = 0.02,
		useRay = true,
	}

local function getDirection(origin, position)
	return (position - origin).Unit
end

local function getAlpha(vec1, vec2)
	local dot = dotProduct(vec1, vec2)
	dot = math.clamp(dot, -1, 1)
	return math.deg(math.acos(dot))
end

local function findTargetVec(origin, direction)
	local closest, minAngle = nil, getgenv().silentConfig.maxAngle
	local directionUnit = direction.Unit
	local char = player.Character or findChild(workspace, player.Name)

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
		if getgenv().silentConfig.checkVisible and not visible[plr] then
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

local function findTarget(origin, direction)
	local minDistance = math.huge
	local char = player.Character or findChild(workspace, player.Name)

	for _, plr in pairs(getPlayers(Players)) do
		if plr == player then
			continue
		end

		local character = plr.Character or findChild(workspace, plr.Name)
		local prt = character and findChild(character, getgenv().silentConfig.targetPart)
		local humanoid = character and findChild(character, "Humanoid")
		if not prt or not humanoid or not (humanoid.Health > 0) then
			continue
		end

		local part = char and findChild(char, getgenv().silentConfig.targetPart)
		if not part then
			continue
		end

		local closure = getgenv().silentConfig.checkClosure
		if type(closure) == "function" and not closure(plr, character, prt) then
			continue
		end

		if getgenv().silentConfig.checkVisible and not visible[plr] then
			continue
		end

		local diff = (part.Position - prt.Position)
		local distance = dotProduct(diff, diff)
		if distance <= minDistance then
			closest = prt
			minDistance = distance
		end
	end
	return closest
end

local worldroot
worldroot = hookmetamethod(
	workspace,
	"__namecall",
	newcclosure(function(...)
		local method = getnamecallmethod()
		local args = { ... }

		if method == "Raycast" and getgenv().silentConfig.enabled and not checkcaller() then
			local origin = args[2]
			local direction = args[3]
			local target = findTargetVec(origin, direction)
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
			local target = findTargetVec(origin, direction)
			if target then
				args[2] = Ray.new(origin, getDirection(origin, target.Position) * direction.Magnitude)
				return worldroot(unpack(args))
			end
		end
		return worldroot(...)
	end)
)

local index
index = hookmetamethod(
	game,
	"__index",
	newcclosure(function(self, field, ...)
		if self == mouse and getgenv().silentConfig.enabled and not checkcaller() then

			if field == "Target" or field == "target" then
				return findTarget()
			elseif field == "Hit" or field == "hit" then
			  local target = findTarget()
				if getgenv().silentConfig.prediction and target then
					return target.CFrame + (target.Velocity * getgenv().silentConfig.prediction)
				end

				return (target and target.CFrame) or index(self, field, ...)
			elseif field == "UnitRay" then
				local ray = index(self, field, ...)
				local origin = ray.Origin
				local direction = ray.Direction
				local target = findTargetVec(origin, direction)
				if target then
					return Ray.new(origin, getDirection(origin, target.Position) * direction.Magnitude)
				end
			end
		end

		return index(self, field, ...)
	end)
)

local Module = {}
function Module.Load()
	if Module.Connections then
		return
	end
	table.insert(
		Module.Connections,
		Run.Heartbeat:Connect(function()
			for _, plr in pairs(getPlayers(Players)) do
				if plr == player then
					continue
				end

				local char = player.Character or findChild(workspace, player.Name)
				local character = plr.Character or findChild(workspace, plr.Name)
				local origin = char and findChild(char, getgenv().silentConfig.rootPart)
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
	)
	table.insert(
		Module.Connections,
		Players.PlayerRemoving:Connect(function(plr)
			visible[plr] = nil
		end)
	)
end

function Module.Unload()
	if not Module.Connection then
		return
	end

	for _, connection in ipairs(Module.Connections) do
		if connection and connection.Disconnect then
			connection:Disconnect()
		end
	end
end

function Module.Drop()
	if worldroot then
		local metatable = table.clone(getrawmetatable(workspace))
		metatable.__namecall = worldroot
		setrawmetatable(workspace, metatable)
	end
	
	if index then
		local metatable = table.clone(getrawmetatable(game))
		metatable.__index = index
		setrawmetatable(game, metatable)
	end
end

return Module
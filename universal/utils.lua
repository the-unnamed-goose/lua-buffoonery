-- This file is licensed under the Perl Artistic License License. See https://dev.perl.org/licenses/artistic.html for more details.
local Players = game:GetService("Players")
local Run = game:GetService("RunService")

local player = Players.LocalPlayer
local elementCache = {}
local connections = {}
local animation = {}
local animator = nil
local track = nil

local Module = {}
Module.asset = {}
Module.nameList = {}
Module.isCapturing = false
Module.resumeAnimation = nil
Module.emotes = { "Press to try and refresh" }

function Module.refreshAnimations()
	if not player.Character then
		return
	end

	animation = {}
	Module.emotes = {}
	for _, obj in ipairs(game:GetDescendants()) do
		local name = obj.Name
		if obj:IsA("Animation") and not animation[name] then
			animation[name] = obj
			table.insert(Module.emotes, name)
		end
	end

	for _, assetid in ipairs(Module.asset) do
		if not animation[assetid] then
			local instance = Instance.new("Animation")
			instance.AnimationId = assetid

			animation[assetid] = instance
			table.insert(Module.emotes, assetid)
		end
	end

	table.sort(Module.emotes)
	return Module.emotes
end

function Module.playAnimation(name)
	if track then
		track:Stop()
	end

	track = animator:LoadAnimation(animation[name])
	track:Play()
end

function Module.isElement(object)
	return object:IsA("TextButton") or object:IsA("ImageButton") or object:IsA("Tool") or object:IsA("ClickDetector")
end

function Module.getElementPath(element)
	local path = {}
	local current = element
	while current and current ~= game do
		table.insert(path, 1, current.Name)
		current = current.Parent
	end
	return table.concat(path, ".")
end

function Module.connectElement(element)
	if Module.isElement(element) then
		local connection
		local className = element.ClassName
		local elementPath = Module.getElementPath(element)

		if className == "TextButton" or className == "ImageButton" or className == "Tool" then
			connection = element.Activated:Connect(function()
				if Module.isCapturing then
					Module.isCapturing = false
					if not elementCache[elementPath] then
						local displayName
						if className == "TextButton" or className == "ImageButton" then
							displayName = "[BTN] " .. element.Name
						elseif className == "Tool" then
							displayName = "[TOOL] " .. element.Name
						end
						elementCache[elementPath] = {
							element = element,
							displayName = displayName,
							path = elementPath,
						}
						table.insert(Module.nameList, displayName)

						getgenv().aimConfig.triggerAction = elementPath
					end
				end
			end)
		elseif className == "ClickDetector" then
			connection = element.MouseClick:Connect(function()
				if Module.isCapturing then
					Module.isCapturing = false
					if not elementCache[elementPath] then
						local displayName = "[CLK] " .. element.Name
						if element.Parent then
							displayName = displayName .. " (on " .. element.Parent.Name .. ")"
						end
						elementCache[elementPath] = {
							element = element,
							displayName = displayName,
							path = elementPath,
						}
						table.insert(Module.nameList, displayName)

						getgenv().aimConfig.triggerAction = elementPath
					end
				end
			end)
		end

		if connection then
			table.insert(connections, connection)
		end
	end
end

function Module.scanDescendants(parent)
	for _, child in ipairs(parent:GetDescendants()) do
		if Module.isElement(child) then
			Module.connectElement(child)
		end
	end

	local connection = parent.DescendantAdded:Connect(function(child)
		if Module.isElement(child) then
			Module.connectElement(child)
		end
	end)
	table.insert(connections, connection)
end

function Module.scanElements()
	for _, connection in pairs(connections) do
		connection:Disconnect()
	end
	connections = {}

	for _, service in ipairs({ workspace, game:GetService("StarterGui"), game:GetService("StarterPack") }) do
		Module.scanDescendants(service)
	end
	Module.scanDescendants(player.PlayerGui)

	if player:FindFirstChild("Backpack") then
		Module.scanDescendants(player.Backpack)
	end
end

function Module.resolveElement(path)
	if elementCache[path] and elementCache[path].element and elementCache[path].element.Parent then
		return elementCache[path].element
	end

	local current = game
	for part in path:gmatch("[^%.]+") do
		current = current:FindFirstChild(part)
		if not current then
			return nil
		end
	end

	if Module.isElement(current) then
		elementCache[path] = {
			element = current,
			displayName = elementCache[path] and elementCache[path].displayName or current.Name,
			path = path,
		}
		return current
	end

	return nil
end

function Module.getParts()
	local parts = {}
	local character = player.Character
	if character then
		for _, child in ipairs(character:GetChildren()) do
			if child:IsA("BasePart") then
				table.insert(parts, child.Name)
			end
		end
	end
	return parts
end

function Module.handleTracks()
	local humanoid = player.Character:WaitForChild("Humanoid")
	animator = humanoid:WaitForChild("Animator")

	humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
		if track and humanoid.MoveDirection.Magnitude > 0 then
			track:Stop()
			track = nil
		end
	end)
end

function Module.updateTriggerAction()
	if
		getgenv().aimConfig
		and getgenv().aimConfig.triggerAction
		and type(getgenv().aimConfig.triggerAction) == "string"
	then
		local element = Module.resolveElement(getgenv().aimConfig.triggerAction)
		if element then
			getgenv().aimConfig.triggerAction = element
		end
	end
end

function Modules.refreshConfigs()
  local profiles = {}
for _, profile in listfiles(Folder .. "config/") do
  print(profile)
	table.insert(profiles, string.split(profile, ".")[1])
end
table.sort(profiles)
return profiles
end

function Module.Load()
	if Module.Connections then
		return
	end

	Module.Connections = {}
	table.insert(Module.Connections, player.CharacterAdded:Connect(Module.handleTracks))
	if player.Character then
		Module.handleTracks()
	end

	table.insert(
		Module.Connections,
		Run.Heartbeat:Connect(function()
			Module.updateTriggerAction()
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
end

return Module

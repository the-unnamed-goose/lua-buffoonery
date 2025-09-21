local Players = game:GetService("Players")
local Run = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local Teams = {
	Teammates = {
		list = {},
		outline = Color3.fromRGB(30, 214, 134),
		fill = Color3.fromRGB(15, 107, 67),
		billboard = false, -- Enable if you are a masochist or if you want to use this in another game
	},
	Enemies = {
		list = {},
		outline = Color3.fromRGB(255, 41, 121),
		fill = Color3.fromRGB(127, 20, 60),
		billboard = true,
	},
}

local function createBillboard(humanoidRootPart)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "EnemyBillboard"
	billboard.Adornee = humanoidRootPart
	billboard.AlwaysOnTop = true
	billboard.Size = UDim2.new(1, 0, 1, 0)
	billboard.StudsOffset = Vector3.new(0, 0, 0)
	billboard.Parent = humanoidRootPart

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundColor3 = Teams.Enemies.outline
	frame.BackgroundTransparency = 0
	frame.BorderSizePixel = 0
	frame.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = frame
end

local function update()
	Teams.Teammates.list = {}
	Teams.Enemies.list = {}

	for _, element in pairs(Players:GetPlayers()) do
		if element ~= player and element.Team and element.Character and element.Character.Parent == Workspace then
			if element.Team == player.Team then
				table.insert(Teams.Teammates.list, element)
			else
				table.insert(Teams.Enemies.list, element)
			end
		end
	end
end

local function renderTeam(team)
	for _, element in ipairs(team.list) do
		local character = element.Character
		local hrp = character and character:FindFirstChild("HumanoidRootPart")
		if character and hrp then
			local highlight = character:FindFirstChild("TeamHighlight")
			if not highlight then
				highlight = Instance.new("Highlight")
				highlight.Name = "TeamHighlight"
				highlight.Parent = character
			end

			highlight.Enabled = true
			highlight.OutlineColor = team.outline
			highlight.FillColor = team.fill
			highlight.FillTransparency = 0.7

			if team.billboard then
				local existingBillboard = hrp:FindFirstChild("EnemyBillboard")
				if not existingBillboard then
					createBillboard(hrp)
				end
			end
		end
	end
end

if player.Character then
	update()
end

local Connections = {}
Connections[0] = player.CharacterAdded:Connect(update)
Connections[1] = Run.Heartbeat:Connect(function()
	if not player:GetAttribute("Match") then
		print("e1")
		return
	end

	if getgenv().espTeammates then
		renderTeam(Teams.Teammates)
	end

	if getgenv().espEnemies then
		renderTeam(Teams.Enemies)
	end
end)

return Connections

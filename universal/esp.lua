-- This file is licensed under the Perl Artistic License License. See https://dev.perl.org/licenses/artistic.html for more details.
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

getgenv().espConfig = getgenv().espConfig
	or {
		mode = "Highlight",
		showNames = true,
		showDistance = false,
		showHealth = false,
		useTeamColor = true,
		teammateColor = Color3.fromRGB(0, 255, 0),
		enemyColor = Color3.fromRGB(255, 0, 0),
		fillTransparency = 0.5,
		outlineTransparency = 0,
		textSize = 14,
	}

local player = Players.LocalPlayer
local highlights = {}
local billboards = {}

local function getColor(plr)
	if getgenv().espConfig.useTeamColor and plr.Team then
		return plr.Team == player.Team and getgenv().espConfig.teammateColor or getgenv().espConfig.enemyColor
	end
	return getgenv().espConfig.teammateColor
end

local function getDisplayText(plr, char)
	local text = plr.Name

	if getgenv().espConfig.showHealth and char then
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if humanoid then
			text = text .. "\nHP: " .. math.floor(humanoid.Health)
		end
	end

	if getgenv().espConfig.showDistance and char and player.Character then
		local root1 = char:FindFirstChild("HumanoidRootPart")
		local root2 = player.Character:FindFirstChild("HumanoidRootPart")
		if root1 and root2 then
			local distance = math.floor((root1.Position - root2.Position).Magnitude)
			text = text .. "\n" .. distance .. " studs"
		end
	end

	return text
end

local function applyESP(plr)
	if plr == player then
		return
	end

	local char = plr.Character
	if not char then
		return
	end

	local root = char:WaitForChild("HumanoidRootPart", 2)
	local hum = char:WaitForChild("Humanoid", 2)
	local head = char:WaitForChild("Head", 2)

	if not root or not hum or not head then
		return
	end

	if highlights[plr] then
		highlights[plr]:Destroy()
	end
	if billboards[plr] then
		billboards[plr]:Destroy()
	end

	local color = getColor(plr)
	local mode = getgenv().espConfig.mode

	if mode == "Highlight" then
		local h = Instance.new("Highlight")
		h.FillColor = color
		h.OutlineColor = color
		h.FillTransparency = getgenv().espConfig.fillTransparency
		h.OutlineTransparency = getgenv().espConfig.outlineTransparency
		h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		h.Parent = char
		highlights[plr] = h
	end

	if getgenv().espConfig.showNames then
		local bb = Instance.new("BillboardGui")
		bb.Adornee = head
		bb.Size = UDim2.new(0, 200, 0, 50)
		bb.AlwaysOnTop = true
		bb.StudsOffset = Vector3.new(0, 2.5, 0)

		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Text = getDisplayText(plr, char)
		label.TextColor3 = color
		label.TextStrokeColor3 = Color3.new(0, 0, 0)
		label.TextStrokeTransparency = 0
		label.Size = UDim2.new(1, 0, 1, 0)
		label.TextSize = getgenv().espConfig.textSize
		label.Font = Enum.Font.SourceSansBold
		label.TextYAlignment = Enum.TextYAlignment.Top

		label.Parent = bb
		bb.Parent = head
		billboards[plr] = bb
	end
end

local function removeESP(plr)
	if highlights[plr] then
		highlights[plr]:Destroy()
		highlights[plr] = nil
	end

	if billboards[plr] then
		billboards[plr]:Destroy()
		billboards[plr] = nil
	end
end

for _, plr in pairs(Players:GetPlayers()) do
	if plr ~= player then
		plr.CharacterAdded:Connect(function()
			applyESP(plr)
		end)

		if plr.Character then
			applyESP(plr)
		end
	end
end

Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function()
		applyESP(plr)
	end)
end)
Players.PlayerRemoving:Connect(removeESP)

player.CharacterAdded:Connect(function()
	for _, plr in pairs(Players:GetPlayers()) do
		if plr ~= player then
			removeESP(plr)
			applyESP(plr)
		end
	end
end)

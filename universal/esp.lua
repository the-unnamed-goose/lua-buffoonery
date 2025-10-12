-- This file is licensed under the Perl Artistic License License. See https://dev.perl.org/licenses/artistic.html for more details.
local Players = game:GetService("Players")

getgenv().espConfig = getgenv().espConfig
	or {
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
	local character = player.Character or workspace:FindFirstChild(player.Name)
	local text = plr.Name

	if getgenv().espConfig.showHealth and char then
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if humanoid then
			text = text .. "\nHP: " .. math.floor(humanoid.Health)
		end
	end

	if getgenv().espConfig.showDistance and char and character then
		local root1 = char:FindFirstChild("HumanoidRootPart")
		local root2 = character:FindFirstChild("HumanoidRootPart")
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

	local char = plr.Character or workspace:FindFirstChild(plr.Name)
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

	local high = Instance.new("Highlight")
	high.FillColor = color
	high.OutlineColor = color
	high.FillTransparency = getgenv().espConfig.fillTransparency
	high.OutlineTransparency = getgenv().espConfig.outlineTransparency
	high.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	high.Parent = char
	highlights[plr] = high

	if getgenv().espConfig.showNames then
		local bill = Instance.new("BillboardGui")
		bill.Adornee = head
		bill.Size = UDim2.new(0, 200, 0, 50)
		bill.AlwaysOnTop = true
		bill.StudsOffset = Vector3.new(0, 2.5, 0)

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

		label.Parent = bill
		bill.Parent = head
		billboards[plr] = bill
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

		if plr.Character or workspace:FindFirstChild(plr.Name) then
			applyESP(plr)
		end
	end
end

local Module = {}
function Module:Load()
	if Module.Connections then
		return
	end

	Module.Connections = {}
	table.insert(
		Module.Connections,
		Players.PlayerAdded:Connect(function(plr)
			plr.CharacterAdded:Connect(function()
				applyESP(plr)
			end)
		end)
	)
	table.insert(Module.Connections, Players.PlayerRemoving:Connect(removeESP))

	table.insert(
		Module.Connections,
		player.CharacterAdded:Connect(function()
			for _, plr in pairs(Players:GetPlayers()) do
				if plr ~= player then
					removeESP(plr)
					applyESP(plr)
				end
			end
		end)
	)
end

function Module:Unload()
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

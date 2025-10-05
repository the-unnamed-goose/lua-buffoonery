local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PerformanceMonitor"
screenGui.Parent = game:GetService("CoreGui")

local label = Instance.new("TextLabel", screenGui)
label.Size = UDim2.new(0, 300, 0, 20)
label.AnchorPoint = Vector2.new(1, 0)
label.Position = UDim2.new(1, -5, 0, 0)
label.BackgroundTransparency = 1
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.TextStrokeTransparency = 0.5
label.Font = Enum.Font.Code
label.TextSize = 16
label.TextXAlignment = Enum.TextXAlignment.Right
label.RichText = true
label.Text = "FPS: 0 | Latency: 0"

local lastTick = tick()
local frameCount = 0
local fps = 0

RunService.RenderStepped:Connect(function()
	frameCount += 1
	if tick() - lastTick >= 1 then
		fps = frameCount
		frameCount = 0
		lastTick = tick()
	end

	local ping = Stats.Network:FindFirstChild("ServerStatsItem")
		and Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
	ping = ping and math.floor(ping) or "?"

	local fpsColor = fps >= 50 and Color3.fromRGB(0, 255, 0)
		or (fps >= 35 and Color3.fromRGB(255, 255, 0) or Color3.fromRGB(255, 0, 0))
	local pingColor = ping ~= "?"
			and (ping <= 200 and Color3.fromRGB(0, 255, 0) or (ping <= 350 and Color3.fromRGB(255, 255, 0) or Color3.fromRGB(
				255,
				0,
				0
			)))
		or Color3.fromRGB(200, 200, 200)

	label.Text = string.format(
		'<font color="rgb(%d,%d,%d)">FPS: %d</font> | <font color="rgb(%d,%d,%d)">Latency: %s</font>',
		fpsColor.R * 255,
		fpsColor.G * 255,
		fpsColor.B * 255,
		fps,
		pingColor.R * 255,
		pingColor.G * 255,
		pingColor.B * 255,
		ping
	)
end)

-- Based on ghidra's notiication system
local Project = "Loader"
local Folder = "WindUI/" .. Project .. "/"
local Assets = Folder .. "assets/"
local Repository = "https://raw.githubusercontent.com/the-unnamed-goose/lua-buffoonery/master/"

local Run = game:GetService("RunService")
local Input = game:GetService("UserInputService")
local Tween = game:GetService("TweenService")

local ui = Instance.new("ScreenGui")
ui.Name = "ui"
ui.Parent = gethui and gethui() or game.CoreGui
ui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ui.ResetOnSpawn = false

local holder = Instance.new("Frame")
holder.Name = "holder"
holder.Parent = ui
holder.BackgroundTransparency = 1
holder.Size = UDim2.new(0.25, 0, 0.9, 0)
holder.Position = UDim2.new(0.7, 0, 0.05, 0)

if Input.TouchEnabled then
	holder.Size = UDim2.new(0.3, 0, 0.9, 0)
	holder.Position = UDim2.new(0.65, 0, 0.05, 0)
end

local list = Instance.new("UIListLayout")
list.Parent = holder
list.HorizontalAlignment = Enum.HorizontalAlignment.Right
list.SortOrder = Enum.SortOrder.LayoutOrder
list.VerticalAlignment = Enum.VerticalAlignment.Bottom
list.Padding = UDim.new(0, 12)

local function setDefaults(input, default)
	input = input or {}
	local result = {}
	for key, value in next, default do
		result[key] = input[key] or default[key]
	end
	return result
end

function createNotification(options)
	local defaults = {
		Title = "Notification",
		Content = "Message content",
		Duration = 5,
		Buttons = {
			[1] = {
				Title = "Dismiss",
				ClosesUI = true,
			},
		},
	}
	options = setDefaults(options, defaults)

	local popup = Instance.new("Frame")
	popup.Name = "popup"
	popup.Parent = holder
	popup.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	popup.BackgroundTransparency = 0.1
	popup.Size = UDim2.new(0.95, 0, 0, 0)
	popup.Position = UDim2.new(1.5, 0, 1, 0)
	popup.AnchorPoint = Vector2.new(1, 1)
	popup.ClipsDescendants = true

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = popup

	local stroke = Instance.new("UIStroke")
	stroke.Parent = popup
	stroke.Color = Color3.fromRGB(80, 80, 90)
	stroke.Thickness = 1
	stroke.Transparency = 0.3

	local title = Instance.new("TextLabel")
	title.Parent = popup
	title.BackgroundTransparency = 1
	title.Position = UDim2.new(0.05, 0, 0, 12)
	title.Size = UDim2.new(0.9, 0, 0, 20)
	title.Font = Enum.Font.GothamBold
	title.Text = options.Title
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 14
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextTruncate = Enum.TextTruncate.AtEnd

	local content = Instance.new("TextLabel")
	content.Parent = popup
	content.BackgroundTransparency = 1
	content.Position = UDim2.new(0.05, 0, 0, 38)
	content.Size = UDim2.new(0.9, 0, 0, 0)
	content.Font = Enum.Font.Gotham
	content.Text = options.Content
	content.TextColor3 = Color3.fromRGB(220, 220, 220)
	content.TextSize = 13
	content.TextWrapped = true
	content.TextXAlignment = Enum.TextXAlignment.Left
	content.TextYAlignment = Enum.TextYAlignment.Top
	content.AutomaticSize = Enum.AutomaticSize.Y

	local btnHolder = Instance.new("Frame")
	btnHolder.Parent = popup
	btnHolder.BackgroundTransparency = 1
	btnHolder.Size = UDim2.new(0.9, 0, 0, 28)
	btnHolder.Position = UDim2.new(0.05, 0, 0, 0)

	local btnList = Instance.new("UIListLayout")
	btnList.Parent = btnHolder
	btnList.FillDirection = Enum.FillDirection.Horizontal
	btnList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	btnList.VerticalAlignment = Enum.VerticalAlignment.Center
	btnList.Padding = UDim.new(0, 6)

	local function updateSize()
		Run.Heartbeat:Wait()

		local margin = 12
		local titleH = 20
		local titleToText = 6
		local textToBtn = 10
		local btnH = 28

		local textH = math.max(content.TextBounds.Y, 16)
		local totalH = margin + titleH + titleToText + textH + textToBtn + btnH + margin

		local minH = 100
		local maxH = 350
		local finalH = math.clamp(totalH, minH, maxH)
		popup.Size = UDim2.new(0.95, 0, 0, finalH)

		local btnY = margin + titleH + titleToText + textH + textToBtn
		btnHolder.Position = UDim2.new(0.05, 0, 0, btnY)
	end

	local function removePopup()
		if popup and popup.Parent then
			Tween:Create(popup, TweenInfo.new(0.3), {
				Position = UDim2.new(1.5, 0, 1, 0),
				BackgroundTransparency = 1,
			}):Play()

			for _, child in next, popup:GetDescendants() do
				if child:IsA("TextLabel") or child:IsA("TextButton") then
					Tween:Create(child, TweenInfo.new(0.3), {
						TextTransparency = 1,
					}):Play()
				end
			end

			task.wait(0.3)
			popup:Destroy()
		end
	end

	if options.Buttons then
		for _, btn in ipairs(options.Buttons) do
			local actionBtn = Instance.new("TextButton")
			actionBtn.Parent = btnHolder
			actionBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
			actionBtn.BorderSizePixel = 0
			actionBtn.Size = UDim2.new(0.7, 0, 0, 24)
			actionBtn.Font = Enum.Font.GothamMedium
			actionBtn.Text = btn.Title or "Button"
			actionBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			actionBtn.TextSize = 12
			actionBtn.AutoButtonColor = true

			local btnCorner = Instance.new("UICorner")
			btnCorner.CornerRadius = UDim.new(0, 4)
			btnCorner.Parent = actionBtn

			local originalColor = actionBtn.BackgroundColor3
			actionBtn.MouseEnter:Connect(function()
				Tween:Create(actionBtn, TweenInfo.new(0.2), {
					BackgroundColor3 = Color3.fromRGB(80, 80, 90),
				}):Play()
			end)

			actionBtn.MouseLeave:Connect(function()
				Tween:Create(actionBtn, TweenInfo.new(0.2), {
					BackgroundColor3 = originalColor,
				}):Play()
			end)

			actionBtn.MouseButton1Click:Connect(function()
				if btn.Callback then
					btn.Callback()
				end
				if btn.ClosesUI then
					removePopup()
				end
			end)

			if Input.TouchEnabled then
				actionBtn.TouchTap:Connect(function()
					if btn.Callback then
						btn.Callback()
					end
					if btn.ClosesUI then
						removePopup()
					end
				end)
			end
		end
	end

	updateSize()
	content:GetPropertyChangedSignal("TextBounds"):Connect(updateSize)

	task.wait(0.1)
	Tween:Create(popup, TweenInfo.new(0.4), {
		Position = UDim2.new(0, 0, 1, 0),
	}):Play()

	if options.Duration then
		task.delay(options.Duration, removePopup)
	end

	return popup
end

local Store = {
	["*"] = {
		name = "Wildcard",
		location = "universal/gui.lua",
		dependencies = {
			{
				name = "getgenv",
				value = getgenv,
			},
			{
				name = "game.HttpGet",
				value = game.HttpGet,
			},
		},
		weakDependencies = {
			{
				name = "isfile",
				value = isfile,
			},
			{
				name = "readfile",
				value = readfile,
			},
			{
				name = "writefile",
				value = writefile,
			},
			{
				name = "delfolder",
				value = delfolder,
			},
			{
				name = "hookfunction",
				value = hookfunction,
			},
			{
				name = "hookmetamethod",
				value = hookmetamethod,
			},
			{
				name = "newcclosure",
				value = newcclosure,
			},
			{
				name = "getnamecallmethod",
				value = getnamecallmethod,
			},
			{
				name = "checkcaller",
				value = checkcaller,
			},
			{
				name = "getthreadidentity",
				value = getthreadidentity,
			},
			{
				name = "getrawmetatable",
				value = getrawmetatable,
			},
			{
				name = "setrawmetatable",
				value = setrawmetatable,
			},
			{
				name = "getgc",
				value = getgc,
			},
			{
				name = "gethui",
				value = gethui,
			},
		},
		notes = {
			["Krnl"] = "The anticheat bypass messes up the executor GUI. This is a known issue and should be fixed in future Krnl releases.",
		},
	},
	[12355337193] = {
		name = "Murderers VS Sheriffs Duels",
		location = "profiles/12355337193/gui.lua",
		dependencies = {
			{
				name = "getgenv",
				value = getgenv,
			},
			{
				name = "game.HttpGet",
				value = game.HttpGet,
			},
		},
		weakDependencies = {
			{
				name = "isfile",
				value = isfile,
			},
			{
				name = "readfile",
				value = readfile,
			},
			{
				name = "writefile",
				value = writefile,
			},
			{
				name = "delfolder",
				value = delfolder,
			},
		},
	},
}
local function fetch(file)
	local cache = Assets .. file
	local content = isfile(cache) and readfile(cache)
	if not content or content == "" then
		content = game:HttpGet(Repository .. file)
		writefile(cache, content)
	end

	return content
end

local current = Store[game.PlaceId] or Store["*"]
for _, dependency in ipairs(current.dependencies) do
	if type(dependency.value) ~= "function" then
		createNotification({
			Title = "Error",
			Content = "Your executor does not support the Unified Naming Convention standard, thus it cannot load this script. Contact your executor devs for details.",
			Duration = 15,
		})
		return error("Unsupported executor. Could not find: " .. dependency.name)
	end
end

for _, dependency in ipairs(current.weakDependencies) do
	if type(dependency.value) ~= "function" then
		pcall(function()
			getgenv()[dependency.name] = function() end
		end)
		createNotification({
			Title = "Warning",
			Content = "Your executor does not fully support the Unified Naming Convention standard, thus some features may be broken. Contact your executor devs for details.",
			Duration = 15,
		})
		break
	end
end

local executor = identifyexecutor and identifyexecutor() or "Krnl"
if current.notes and current.notes[executor] then
	createNotification({
		Title = "Warning",
		Content = current.notes[executor],
		Duration = 15,
	})
end

pcall(loadstring, fetch(current.location))
return Store

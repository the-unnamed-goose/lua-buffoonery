-- This file is licensed under the Creative Commons Attribution 4.0 International License. See https://creativecommons.org/licenses/by/4.0/legalcode.txt for details.
local Library = loadstring(
	game:HttpGetAsync("https://github.com/ActualMasterOogway/Fluent-Renewed/releases/latest/download/Fluent.luau")
)()
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

local FILE_PATH = "history.json"
local MAX_ENTRIES = 20
local PlaceId = tostring(game.PlaceId)
local JobId = game.JobId

local function now()
	local t = os.date("*t", os.time())
	return string.format("%02d/%02d %02d:%02d", t.month, t.day, t.hour, t.min)
end

local function readHistory()
	if isfile(FILE_PATH) then
		local success, result = pcall(function()
			return HttpService:JSONDecode(readfile(FILE_PATH))
		end)
		if success and typeof(result) == "table" then
			return result
		end
	end
	return {}
end

local function updateHistory(history)
	local gameHistory = history[PlaceId] or {}

	for _, entry in ipairs(gameHistory) do
		if entry.job_id == JobId then
			return gameHistory, false
		end
	end

	table.insert(gameHistory, 1, {
		job_id = JobId,
		timestamp = now(),
	})

	while #gameHistory > MAX_ENTRIES do
		table.remove(gameHistory)
	end

	history[PlaceId] = gameHistory
	writefile(FILE_PATH, HttpService:JSONEncode(history))
	return gameHistory, true
end

local history = readHistory()
local gameHistory, isNewEntry = updateHistory(history)

local Window = Library:CreateWindow({
	Title = "Instance History",
	SubTitle = "Session Tracker",
	TabWidth = 80,
	Size = UDim2.fromOffset(320, 240),
	Acrylic = true,
	Theme = "Dark",
	MinimizeKey = Enum.KeyCode.LeftControl,
})

local Tabs = {
	Main = Window:CreateTab({
		Title = "Main",
		Icon = "clock",
	}),
}

Tabs.Main:CreateParagraph("SavedInstances", {
	Title = "Saved Instances",
	Content = #gameHistory > 0 and string.format("Found %d saved instances. Click to teleport.", #gameHistory)
		or "No saved instances found.",
})

for i, entry in ipairs(gameHistory) do
	if entry and entry.job_id and entry.timestamp then
		local displayTitle = (i == 1 and entry.job_id == JobId) and "Current" or entry.timestamp
		Tabs.Main:CreateButton({
			Title = displayTitle,
			Description = entry.job_id,
			Callback = function()
				TeleportService:TeleportToPlaceInstance(tonumber(PlaceId), entry.job_id, LocalPlayer)
			end,
		})
	end
end

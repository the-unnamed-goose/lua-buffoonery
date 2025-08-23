-- This file is licensed under the Creative Commons Attribution 4.0 International License. See https://creativecommons.org/licenses/by/4.0/legalcode.txt for details.
local CollectionService = game:GetService("CollectionService")
local tagDumpFile = "collectionservice.txt"

if not writefile then
	warn("Executor functions not available. writefile is required.")
	return
end

local function safeInstanceName(inst)
	local success, result = pcall(function()
		return inst:GetFullName()
	end)
	return success and result or "<InstanceError>"
end

local function buildDump()
	local dump = {}
	local allTags = CollectionService:GetAllTags()

	for _, tag in ipairs(allTags) do
		table.insert(dump, "=== Tag: " .. tag .. " ===")
		local tagged = CollectionService:GetTagged(tag)
		for _, instance in ipairs(tagged) do
			table.insert(dump, "  " .. safeInstanceName(instance))
		end
		table.insert(dump, "")
	end

	return table.concat(dump, "\n")
end

local function updateDump()
	writefile(tagDumpFile, buildDump())
end

local connectedTags = {}

local function connectTagListeners(tag)
	if connectedTags[tag] then
		return
	end
	connectedTags[tag] = true

	CollectionService:GetInstanceAddedSignal(tag):Connect(updateDump)
	CollectionService:GetInstanceRemovedSignal(tag):Connect(updateDump)
end

updateDump()
for _, tag in ipairs(CollectionService:GetTags()) do
	connectTagListeners(tag)
end

task.spawn(function()
	while true do
		for _, tag in ipairs(CollectionService:GetTags()) do
			connectTagListeners(tag)
		end
		task.wait(2)
	end
end)

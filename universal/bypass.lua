--[[ 
  This is a rewrite of Common Detections Bypass by zyletrophene, it will oftentime drastically decrease performance and game stability so it's better to just remove the anticheat and replicate its watchdog.
  Please keep in mind that this script is NOT a bypass for server sided anticheat methods.
  
  Info on the topic:
    - https://devforum.roblox.com/t/anticheat-methods/2662072
    - https://devforum.roblox.com/t/anti-cheat-release-visionary/3235037
    - https://devforum.roblox.com/t/puppy-anti-cheat-robloxs-most-powerful-anti-cheat-ever/3606125/40
    - ./samples
--]]

local Run = game:GetService("RunService")
local Stats = game:GetService("Stats")
local Content = game:GetService("ContentProvider")

local envTable = {}
local proxyTable = {}
local hookTable = {}
local blockedThreads = {}

-- Mess with the features if you experienced detections/game breaking bugs.
getgenv().bypassConfig = getgenv().bypassConfig
	or {
		core = true,
		memory = true,
		market = true,
		parent = true,
		garbage = true,
		message = true,
		analytics = true,
		property = false,

		-- Only enable those if your executor sucks
		raw = false,
		debug = false,
		proxy = false,
		memoryleak = false,
		environment = false,
	}

local amplitude = 50
local totalMemory = Stats:GetTotalMemoryUsageMb()
local guiMemory = Stats:GetMemoryUsageMbForTag(Enum.DeveloperMemoryTag.Gui)

local floor, clamp = math.floor, math.clamp
local memoryMax, timeTick, oldGc = 0, 0, 0

local function stopExecution()
	if not checkcaller() and getthreadidentity() < 3 then
		table.insert(blockedThreads, coroutine.running())
		return coroutine.yield()
	end
end

local Module = {}
function Module:Load()
	if Module.Enabled then
		return
	end
	Module.Enabled = true

	-- Hidden modules go brrr
	task.spawn(function()
		if not getgenv().bypassConfig.parent then
			return
		end
		for index, element in getgc(true) do
			if element and type(element) == "userdata" and not element.Parent or element.Parent.Name == "" then
				hookmetamethod(element, "__namecall", newcclosure(stopExecution))
				hookmetamethod(element, "__index", newcclosure(stopExecution))
				hookmetamethod(element, "__newindex", newcclosure(stopExecution))
			end
		end
	end)

	-- Memory usage spoofing
	task.spawn(function()
		if not getgenv().bypassConfig.memory then
			return
		end

		local baseline = Stats:GetTotalMemoryUsageMb()
		local baselineGui = Stats:GetMemoryUsageMbForTag(Enum.DeveloperMemoryTag.Gui)

		local memoryDrift = 0
		local lastCheck = tick()

		Run.Heartbeat:Connect(function()
			local currentTime = tick()
			local timeDiff = currentTime - lastCheck

			if timeDiff > 0.5 then
				memoryDrift = memoryDrift + (Random.new():NextNumber(-0.5, 0.5))
				memoryDrift = clamp(memoryDrift, -5, 5)

				totalMemory = baseline + memoryDrift
				guiMemory = baselineGui + (memoryDrift * 0.3)
				lastCheck = currentTime
			end
		end)
	end)

	task.spawn(function()
		local statsBypass
		statsBypass = hookmetamethod(
			game,
			"__namecall",
			newcclosure(function(self, ...)
				if not checkcaller() and typeof(self) == "Instance" and self.ClassName == "Stats" then
					local method = getnamecallmethod()
					local args = { ... }

					if method == "GetTotalMemoryUsageMb" or method == "getTotalMemoryUsageMb" then
						return totalMemory + Random.new():NextNumber(-0.1, 0.1)
					elseif method == "GetMemoryUsageMbForTag" or method == "getMemoryUsageMbForTag" then
						if #args > 0 and args[1] == Enum.DeveloperMemoryTag.Gui then
							return guiMemory + Random.new():NextNumber(-0.05, 0.05)
						end
					end
				end
				return statsBypass(self, ...)
			end)
		)
	end)

	-- Bypass anticheats that look for stable memory patterns aka simulate a memory leak
	task.spawn(function()
		if not getgenv().bypassConfig.memoryleak or getgenv().bypassConfig.memory then
			return
		end

		local baseline = Stats:GetTotalMemoryUsageMb()
		local baselineGui = Stats:GetMemoryUsageMbForTag(Enum.DeveloperMemoryTag.Gui)

		local memoryDrift = 0
		local lastCheck = tick()
		local leakTrend = 0

		Run.Heartbeat:Connect(function()
			local currentTime = tick()
			local timeDiff = currentTime - lastCheck

			if timeDiff > 0.5 then
				local willIncrease = Random.new():NextNumber() < 0.7
				local fluctuation = Random.new():NextNumber(0.1, 1.5)

				if willIncrease then
					leakTrend = leakTrend + fluctuation
					memoryDrift = memoryDrift + fluctuation
				else
					local decrease = Random.new():NextNumber(0.1, 0.8)
					memoryDrift = memoryDrift - decrease
					leakTrend = math.max(0, leakTrend - (decrease * 0.3))
				end

				memoryDrift = clamp(memoryDrift, -20, 100)
				totalMemory = baseline + memoryDrift + (leakTrend * 0.5)
				guiMemory = baselineGui + (memoryDrift * 0.3) + (leakTrend * 0.2)

				lastCheck = currentTime
			end
		end)
	end)

	task.spawn(function()
		if getgenv().bypassConfig.memory then
			return
		end

		local statsBypass
		statsBypass = hookmetamethod(
			game,
			"__namecall",
			newcclosure(function(self, ...)
				if not checkcaller() and typeof(self) == "Instance" and self.ClassName == "Stats" then
					local method = getnamecallmethod()
					local args = { ... }

					if method == "GetTotalMemoryUsageMb" or method == "getTotalMemoryUsageMb" then
						return totalMemory + Random.new():NextNumber(-0.1, 0.1)
					elseif method == "GetMemoryUsageMbForTag" or method == "getMemoryUsageMbForTag" then
						if #args > 0 and args[1] == Enum.DeveloperMemoryTag.Gui then
							return guiMemory + Random.new():NextNumber(-0.05, 0.05)
						end
					end
				end
				return statsBypass(self, ...)
			end)
		)
	end)

	-- Garbage collector spoofing
	task.spawn(function()
		if not getgenv().bypassConfig.garbage then
			return
		end

		local baselineGc = gcinfo()
		local gcDrift = 0
		local lastUpdate = tick()

		Run.Heartbeat:Connect(function()
			local currentTime = tick()
			if currentTime - lastUpdate < 3 then
				gcDrift = gcDrift + (Random.new():NextNumber(-2, 2))
				gcDrift = clamp(gcDrift, -10, 10)
				lastUpdate = currentTime
			end
		end)

		local function getGcValue()
			return baselineGc + gcDrift + Random.new():NextNumber(-0.5, 0.5)
		end
		hookfunction(gcinfo, newcclosure(getGcValue))

		local garbageBypass
		garbageBypass = hookfunction(
			collectgarbage,
			newcclosure(function(arg, ...)
				if arg == "count" then
					return getGcValue()
				end
				return garbageBypass(arg, ...)
			end)
		)
	end)

	-- Bypass instance creation/deletion checks
	task.spawn(function()
		if not getgenv().bypassConfig.property then
			return
		end

		local propertyBypass
		propertyBypass = hookmetamethod(
			game,
			"__index",
			newcclosure(function(self, index)
				if type(index) == "string" and not checkcaller() then
					if
						string.find(index, "Changed")
						or string.find(index, "Added")
						or string.find(index, "Removed")
					then
						stopExecution()
					end
				end
				return propertyBypass(self, index)
			end)
		)
	end)

	-- Don't do stupid sh
	task.spawn(function()
		if not getgenv().bypassConfig.market then
			return
		end

		local marketBypass
		marketBypass = hookmetamethod(
			game,
			"__namecall",
			newcclosure(function(self, ...)
				if not checkcaller() then
					local method = getnamecallmethod()
					if self.ClassName == "MarketplaceService" and method == "PromptGamePassPurchase" then
						error("Argument 2 missing or nil", 2)
					end
				end
				return marketBypass(self, ...)
			end)
		)
	end)

	-- Bypass some client -> server communication
	task.spawn(function()
		if not getgenv().bypassConfig.analytics then
			return
		end

		local analyticsBypass -- What did you think I would name this?
		analyticsBypass = hookmetamethod(
			game,
			"__namecall",
			newcclosure(function(self, ...)
				if not checkcaller() then
					if self.ClassName == "AnalyticsService" then
						return
					end
				end
				return analyticsBypass(self, ...)
			end)
		)
	end)

	-- Yes
	task.spawn(function()
		if not getgenv().bypassConfig.debug then
			return
		end

		local debugBypass = debug.info
		hookfunction(
			debug.info,
			newcclosure(function(func, ...)
				if func and type(func) == "function" and not checkcaller() and getthreadidentity() < 3 then
					local dummy = newcclosure(function() end)
					return debugBypass(dummy, ...)
				end
				return debugBypass(func, ...)
			end)
		)
	end)

	-- Bypass core gui asset loading callbacks
	task.spawn(function()
		if not getgenv().bypassConfig.core then
			return
		end

		local preloadBypass
		hookfunction(
			Content.PreloadAsync,
			newcclosure(function(...)
				stopExecution()
				return preloadBypass(...)
			end)
		)
	end)

	-- No you don't proxy anything
	task.spawn(function()
		if not getgenv().bypassConfig.proxy then
			return
		end

		local proxyBypass
		proxyBypass = hookfunction(
			newproxy,
			newcclosure(function(...)
				stopExecution()
				proxyBypass(...)
			end)
		)
	end)

	-- Don't allow rawget
	task.spawn(function()
		if not getgenv().bypassConfig.raw then
			return
		end

		local rawBypass
		rawBypass = hookfunction(
			rawget,
			newcclosure(function(...)
				stopExecution()
				rawBypass(...)
			end)
		)
	end)

	-- Just fk whoever uses the logs service for detection, also fixes some weird hook detection methods
	task.spawn(function()
		if not getgenv().bypassConfig.message then
			return
		end

		local logBypass
		logBypass = hookmetamethod(
			game,
			"__index",
			newcclosure(function(self, index)
				if not checkcaller() and type(index) == "string" and index == "MessageOut" then
					return nil
				end

				return logBypass(self, index)
			end)
		)

		local pcallBypass
		pcallBypass = hookfunction(
			pcall,
			newcclosure(function(fn, ...)
				if not checkcaller() and getthreadidentity() < 3 then
					local result, message = pcallBypass(fn, ...)
					if not result and string.find(message, "stack overflow") then
						return true, nil
					end
				end
				return pcallBypass(fn, ...)
			end)
		)

		local ypcallBypass
		ypcallBypass = hookfunction(
			ypcall,
			newcclosure(function(fn, ...)
				if not checkcaller() and getthreadidentity() < 3 then
					local result, message = ypcallBypass(fn, ...)
					if not result and string.find(message, "stack overflow") then
						return true, nil
					end
				end
				return ypcallBypass(fn, ...)
			end)
		)

		local xpcallBypass
		xpcallBypass = hookfunction(
			pcall,
			newcclosure(function(fn, err, ...)
				if not checkcaller() and getthreadidentity() < 3 then
					local result, message = pcallBypass(fn, ...)
					if not result and string.find(message, "stack overflow") then
						return true, nil
					end
				end
				return xpcallBypass(fn, err, ...)
			end)
		)
	end)

	-- Fix some bad sUNC implementation
	task.spawn(function()
		if not getgenv().bypassConfig.environment then
			return
		end

		local createBypass
		createBypass = hookfunction(
			coroutine.create,
			newcclosure(function(thread)
				if not checkcaller() and getthreadidentity() < 3 then
					table.insert(blockedThreads, thread)
					return createBypass(function() end)
				end
				return createBypass(func)
			end)
		)

		local wrapBypass
		wrapBypass = hookfunction(
			coroutine.wrap,
			newcclosure(function(func)
				if not checkcaller() and getthreadidentity() < 3 then
					table.insert(blockedThreads, thread)
					return createBypass(function() end)
				end

				return wrapBypass(func)
			end)
		)

		local defaultEnv = function()
			return getfenv()
		end
		hookfunction(
			getfenv,
			newcclosure(function(level)
				if type(level) == "number" and not checkcaller() and getthreadidentity() < 3 then
					return getfenv(0)
				end
				return getfenv(level)
			end)
		)
	end)

	-- Gracefully handle threads that don't take "No" for an answer
	task.spawn(function()
		local coroutineBypass
		coroutineBypass = coroutine.status
		hookfunction(
			coroutine.status,
			newcclosure(function(thread)
				if thread and not checkcaller() and getthreadidentity() < 3 then
					for _, blockedThread in ipairs(blockedThreads) do
						if thread == blockedThread then
							return "running"
						end
					end
				end
				return coroutineBypass(thread)
			end)
		)
	end)

	task.spawn(function()
		local coroutineBypass
		coroutineBypass = coroutine.resume
		hookfunction(
			coroutine.resume,
			newcclosure(function(thread, ...)
				if thread and not checkcaller() and getthreadidentity() < 3 then
					for _, blockedThread in ipairs(blockedThreads) do
						if thread == blockedThread then
							coroutine.yield()
							return false
						end
					end
				end
				return coroutineBypass(thread, ...)
			end)
		)
	end)
end

function Module:Unload()
	warning(
		"The bypass module is not dynamic. Its configuration cannot be changed at runtime and it cannot be disabled."
	)
end

return Module

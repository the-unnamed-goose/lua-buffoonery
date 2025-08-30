-- This file is licensed under the Creative Commons Attribution 4.0 International License. See https://creativecommons.org/licenses/by/4.0/legalcode.txt for details.
local config = {
	name = "RobloxExecute",
	address = "ws://127.0.0.1:53203",
	pingInterval = 1000,
	checkActiveInterval = 1000,
	minActive = 3000,
	reconnectInterval = 2000,
}

local players = game:GetService("Players")
local socket, lastActive
local active = true

local function getStore(key)
	return getgenv()[config.name .. "-" .. key]
end

local function setStore(key, value)
	getgenv()[config.name .. "-" .. key] = value
end

local function setSocket(newSocket)
	socket = newSocket
	lastActive = socket and tick() or nil
end

local function onMessage(text)
	if text == config.name .. "-Pong" then
		lastActive = tick()
	else
		local callback, err = loadstring(text)
		if err then
			error(err, 2)
		end
		task.spawn(callback)
	end
end

local function setPlayerName()
	local player = players.LocalPlayer
	if not player then
		players:GetPropertyChangedSignal("LocalPlayer"):Wait()
		player = players.LocalPlayer
	end
	if socket then
		socket:Send(player.Name)
	end
end

local function connect()
	if socket and socket.Connected then
		return
	end

	local success, newSocket = pcall(WebSocket.connect, config.address)
	if success and newSocket and active then
		setSocket(newSocket)
		task.spawn(setPlayerName)
		newSocket.OnMessage:Connect(onMessage)
		newSocket.OnClose:Connect(function()
			setSocket(nil)
		end)
	elseif success and newSocket then
		newSocket:Close()
	end
end

local function timeElapsed(lastTime, threshold)
	return lastTime and tick() - lastTime > threshold / 1000
end

local function waitInterval(interval)
	return task.wait(interval and interval > 0 and (interval / 1000) or 0)
end

local function disconnect()
	active = false
	if socket then
		socket:Close()
	end
end

assert(WebSocket and WebSocket.connect, "Executor doesn't support WebSockets.")
local existingDisconnect = getStore("Disconnect")
if existingDisconnect and typeof(existingDisconnect) == "function" then
	existingDisconnect()
end
setStore("Disconnect", disconnect)

task.spawn(function()
	while active do
		if not socket then
			connect()
		end
		waitInterval(config.reconnectInterval)
	end
end)

task.spawn(function()
	while active do
		if socket then
			socket:Send(config.name .. "-Ping")
		end
		waitInterval(config.pingInterval)
	end
end)

task.spawn(function()
	while active do
		if socket and timeElapsed(lastActive, config.minActive) then
			socket:Close()
			setSocket(nil)
		end
		waitInterval(config.checkActiveInterval)
	end
end)

-- This file is licensed under the Creative Commons Attribution 4.0 International License. See https://creativecommons.org/licenses/by/4.0/legalcode.txt for details.
local Players = game:GetService("Players")

local controller = { gun = nil, knife = nil }
local function cleanup()
	local playerModel = workspace:FindFirstChild(Players.LocalPlayer.Name)
	if playerModel then
		local controller.gun = playerModel:FindFirstChild("GunController")
		if controller.gun then
			controller.gun.Parent = nil
		end

		local controller.knife = playerModel:FindFirstChild("KnifeController")
		if controller.knife then
			controller.knife.Parent = nil
		end
	end
end

Players.LocalPlayer.CharacterAdded:Connect(cleanup())
task.spawn(cleanup())
-- This file is licensed under the Perl Artistic License License. See https://dev.perl.org/licenses/artistic.html for more details.
local player = game:GetService("Players").LocalPlayer

function Module.Load()
	if Module.Connection then
		return
	end

	Module.Connection = player.CharacterAdded:Connect(function()
		local playerModel = workspace:WaitForChild(player.Name)
		if playerModel then
			local gun = playerModel:WaitForChild("GunController")
			if gun then
				pcall(function()
					gun:Destroy()
				end)
			end

			local knife = playerModel:WaitForChild("KnifeController")
			if knife then
				pcall(function()
					knife:Destroy()
				end)
			end
		end
	end)
end

function Module.Unload()
	if not Module.Connection then
		return
	end

	Moudle.Connection:Disconnect()
end

return Module

-- NFL Universe Sentry Hub - Fully Functional
local player = game.Players.LocalPlayer
local runService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local playerGui = player:WaitForChild("PlayerGui")

-- Default settings
local walkSpeed, jumpPower = 20, 70
local flying, autoChase, hitboxExpanded = false, true, false
local flyVelocity = 50
local chaseStep = 5

-- Character helper
local function getCharacter()
	return player.Character or player.CharacterAdded:Wait()
end

-- GUI setup
local screenGui = Instance.new("ScreenGui", playerGui)
screenGui.ResetOnSpawn = false

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 650, 0, 250)
panel.Position = UDim2.new(0.5, -325, 0.5, -125)
panel.BackgroundColor3 = Color3.fromRGB(30,30,30)
panel.BorderSizePixel = 0
panel.Active = true
panel.Draggable = true
panel.Parent = screenGui

local uicorner = Instance.new("UICorner")
uicorner.CornerRadius = UDim.new(0,15)
uicorner.Parent = panel

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,35)
title.Position = UDim2.new(0,0,0,0)
title.BackgroundTransparency = 1
title.Text = "NFL Universe Sentry Hub"
title.TextColor3 = Color3.fromRGB(255,255,255)
title.Font = Enum.Font.GothamBold
title.TextSize = 22
title.Parent = panel

-- Tabs
local tabs = {"Player","Chase","Settings"}
local tabFrames = {}
for i,tabName in ipairs(tabs) do
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0,120,0,30)
	btn.Position = UDim2.new(0,10+(i-1)*130,0,40)
	btn.Text = tabName
	btn.TextColor3 = Color3.fromRGB(255,255,255)
	btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 16
	btn.Parent = panel

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1,-20,1,-80)
	frame.Position = UDim2.new(0,10,0,80)
	frame.BackgroundTransparency = 1
	frame.Visible = (i==1)
	frame.Parent = panel
	tabFrames[tabName] = frame

	btn.MouseButton1Click:Connect(function()
		for _,f in pairs(tabFrames) do f.Visible = false end
		frame.Visible = true
	end)
end

-- Slider & Toggle Utilities
local function createSlider(parent, name, default, callback, order)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0,120,0,25)
	label.Position = UDim2.new(0,10 + ((order-1)%3)*140,0,10 + math.floor((order-1)/3)*70)
	label.Text = name..": "..default
	label.TextColor3 = Color3.fromRGB(255,255,255)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.Parent = parent

	local box = Instance.new("TextBox")
	box.Size = UDim2.new(0,120,0,25)
	box.Position = UDim2.new(0,10 + ((order-1)%3)*140,0,35 + math.floor((order-1)/3)*70)
	box.Text = tostring(default)
	box.TextColor3 = Color3.fromRGB(255,255,255)
	box.BackgroundColor3 = Color3.fromRGB(50,50,50)
	box.ClearTextOnFocus = false
	box.Font = Enum.Font.GothamBold
	box.TextSize = 14
	box.Parent = parent

	box.FocusLost:Connect(function()
		local val = tonumber(box.Text)
		if val then
			callback(val)
			label.Text = name..": "..val
		else
			box.Text = tostring(default)
		end
	end)
end

local function createToggle(parent, name, default, callback, order)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0,120,0,25)
	btn.Position = UDim2.new(0,10 + ((order-1)%3)*140,0,10 + math.floor((order-1)/3)*70)
	btn.Text = name..": "..(default and "ON" or "OFF")
	btn.TextColor3 = Color3.fromRGB(255,255,255)
	btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	btn.Parent = parent

	btn.MouseButton1Click:Connect(function()
		default = not default
		btn.Text = name..": "..(default and "ON" or "OFF")
		callback(default)
	end)
end

-- Populate Player Tab
createSlider(tabFrames["Player"], "Walk Speed", walkSpeed, function(v) walkSpeed=v end,1)
createSlider(tabFrames["Player"], "Jump Power", jumpPower, function(v) jumpPower=v end,2)
createToggle(tabFrames["Player"], "Flying", flying, function(v) flying=v end,3)
createToggle(tabFrames["Player"], "Hitbox Expand", hitboxExpanded, function(v) hitboxExpanded=v end,4)

-- Populate Chase Tab
createToggle(tabFrames["Chase"], "Auto Chase", autoChase, function(v) autoChase=v end,1)

-- Populate Settings Tab
createToggle(tabFrames["Settings"], "GUI Visible", true, function(v) panel.Visible=v end,1)

-- Main loop
local bodyVel
runService.RenderStepped:Connect(function()
	local char = getCharacter()
	local humanoid = char:FindFirstChild("Humanoid")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not humanoid or not hrp then return end

	-- Walk Speed & Jump
	humanoid.WalkSpeed = walkSpeed
	humanoid.JumpPower = jumpPower

	-- Flying
	if flying then
		if not bodyVel then
			bodyVel = Instance.new("BodyVelocity")
			bodyVel.MaxForce = Vector3.new(0,math.huge,0)
			bodyVel.Velocity = Vector3.new(0,0,0)
			bodyVel.Parent = hrp
		end
		if UIS:IsKeyDown(Enum.KeyCode.Space) then
			bodyVel.Velocity = Vector3.new(0,flyVelocity,0)
		else
			bodyVel.Velocity = Vector3.new(0,0,0)
		end
	else
		if bodyVel then bodyVel:Destroy() bodyVel=nil end
	end

	-- Auto Chase
	if autoChase then
		local target
		local minDist = math.huge
		for _,plr in pairs(game.Players:GetPlayers()) do
			if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
				local dist = (plr.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
				if dist < minDist then
					minDist = dist
					target = plr
				end
			end
		end
		if target then
			local dir = (target.Character.HumanoidRootPart.Position - hrp.Position)
			local step = math.min(chaseStep, dir.Magnitude)
			hrp.CFrame = hrp.CFrame + dir.Unit*step
		end
	end

	-- Hitbox Expansion
	if hitboxExpanded then
		for _,plr in pairs(game.Players:GetPlayers()) do
			if plr ~= player and plr.Character and plr.Character:FindFirstChild("Humanoid") then
				plr.Character.Humanoid.HipHeight = 3 * hitboxScale
			end
		end
	end
end)
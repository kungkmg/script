local Virtual = game:GetService("VirtualUser")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Plot = Player.NonSaveVars.OwnsPlot.Value
local MainSignal = nil
local SpeedBoost = 100
local DefaultSpeed = 16
local Configuration = {
	["CanGrab"] = {
		["Normal"] = false,
		["Silver"] = true,
		["Gold"] = true,
		["Emerald"] = true,
		["Ruby"] = true,
		["Sapphire"] = true,
	},
	["Autofarm"] = {
		["TrueAutoFarm"] = false,
		["Grabbing"] = false,
	},
}

Player.Idled:Connect(function()
	Virtual:CaptureController()
	Virtual:ClickButton2(Vector2.new())
end)

local function ProtectAgainstBan()
    if LogConnection then
        LogConnection:Disconnect()
end

LogConnection = game:GetService("LogService").MessageOut:Connect(function(Message, MessageType)
        if MessageType == Enum.MessageType.MessageError and string.find(Message, "kick") then
            AntiBanEnabled = false
            Library:ShowNotification("warning", "Suspicious activity detected. Anti-Ban activated.", 3, nil)
            -- game:Shutdown()
        end
    end)
end

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Xxtan31/LaundryGui/main/LaundryGui.txt"))()("Laundry Simulator", Enum.KeyCode.E, {}, function()
	Configuration.Autofarm.TrueAutoFarm = false
	Configuration.Autofarm.Grabbing = false
	MainSignal:Disconnect()
end)

if Plot == nil then
	repeat
		task.wait(1)
		Library:ShowNotification("warning", "Please claim a plot.", 1, nil)
	until Player.NonSaveVars.OwnsPlot.Value ~= nil
	Plot = Player.NonSaveVars.OwnsPlot.Value
end

function Or(Variable, ...)
	for Int, Value in pairs({...}) do
		if Variable == Value then
			return true
		end
	end
	return false
end
function FindFirstChild(Parent, Name)
	for Int, Value in pairs(Parent:GetChildren()) do
		if Value.Name == Name then
			return Value
		end
	end
	return nil
end
function GetClothTag(Cloth)
	if FindFirstChild(Cloth, "SpecialTag") == nil then
		local Time = 0
		while FindFirstChild(Cloth, "SpecialTag") ~= nil do
			Time += task.wait()
			if Time >= 5 then
				return "Normal"
			end
		end
	else
		return Cloth:WaitForChild("SpecialTag").Value
	end
end
function GrabClothing(Cloth)
	if Or(GetClothTag(Cloth), table.unpack((function()
			local List = {}
			for Tag, Value in pairs(Configuration.CanGrab) do
				if Value == true then
					table.insert(List, Tag)
				end
			end
			return List
		end)())) == true then
		local LastCFrame = Player.Character.HumanoidRootPart.CFrame
		Player.Character.HumanoidRootPart.CFrame = CFrame.new(Cloth.CFrame.Position+Vector3.new(0, 2, 0))
		delay(0.1, function()
			ReplicatedStorage.Events.GrabClothing:FireServer(Cloth)
			delay(0.1, function()
				Player.Character.HumanoidRootPart.CFrame = LastCFrame
			end)
		end)
	end
end
function LoadWashingMachines()
	for Int, Machine in pairs(Plot.WashingMachines:GetChildren()) do
		if Machine.Config.Started.Value == false and Machine.Config.InsertingClothes.Value == false and Machine.Config.DoorMoving.Value == false and Machine.Config.CycleFinished.Value == false then
			Player.Character.HumanoidRootPart.CFrame = Machine.MAIN.CFrame
			delay(0.1, function()
				ReplicatedStorage.Events.LoadWashingMachine:FireServer(Machine)
			end)
			task.wait(0.2)
			if Player.NonSaveVars.BackpackAmount.Value == 0 then
				break
			end
		end
	end
end
function UnloadWashingMachines()
	for Int, Machine in pairs(Plot.WashingMachines:GetChildren()) do
		if Machine.Config.CycleFinished.Value == true then
			Player.Character.HumanoidRootPart.CFrame = Machine.MAIN.CFrame
			delay(0.1, function()
				ReplicatedStorage.Events.UnloadWashingMachine:FireServer(Machine)
			end)
			task.wait(0.2)
			if Player.NonSaveVars.BackpackAmount.Value == Player.NonSaveVars.BasketSize.Value then
				break
			end
		end
	end
end

local TabAutofarm = Library:AddTab("Autofarm")

local function HandleWashingMachine()
    if Player.NonSaveVars.BasketStatus.Value == "Dirty" then
        LoadWashingMachines()
    end
    UnloadWashingMachines()
end
local function DropClothes()
    Player.Character.HumanoidRootPart.CFrame = workspace["_FinishChute"].Entrance.CFrame
    task.wait(0.2)
    ReplicatedStorage.Events.DropClothesInChute:FireServer()
    task.wait(0.1)
end
local function GrabClothes()
    for _, Cloth in pairs(workspace.Debris.Clothing:GetChildren()) do
        if Cloth.Name ~= "Magnet" then
            local LastBackpackCount = Player.NonSaveVars.BackpackAmount.Value
            local TimeElapsed = 0
            repeat
                Player.Character.HumanoidRootPart.CFrame = CFrame.new(Cloth.CFrame.Position + Vector3.new(0, 2, 0))
                TimeElapsed += task.wait(0.1)
                ReplicatedStorage.Events.GrabClothing:FireServer(Cloth)
                if TimeElapsed > 1 then
                    HandleWashingMachine()
                    break
                end
            until not Cloth or LastBackpackCount + 1 == Player.NonSaveVars.BackpackAmount.Value
            break
        end
    end
end

TabAutofarm:AddToggle("True autofarm", "ออโต้เก็บของสามารถafkได้", "", Configuration.Autofarm.TrueAutoFarm, function(Value)
    Configuration.Autofarm.TrueAutoFarm = Value
    while Configuration.Autofarm.TrueAutoFarm do
        if #workspace.Debris.Clothing:GetChildren() > 0 then
            if Player.NonSaveVars.BackpackAmount.Value == 0 or Player.NonSaveVars.BasketStatus.Value == "Dirty" then
                if Or(Player.NonSaveVars.BackpackAmount.Value, Player.NonSaveVars.BasketSize.Value, Player.NonSaveVars.TotalWashingMachineCapacity.Value) then
                    HandleWashingMachine()
                    DropClothes()
                else
                    GrabClothes()
                end
            elseif Player.NonSaveVars.BackpackAmount.Value > 0 and Player.NonSaveVars.BasketStatus.Value == "Clean" then
                HandleWashingMachine()
                DropClothes()
            end
        end
        task.wait()
    end
end)

local TabUtilities = Library:AddTab("Utilities")
TabUtilities:AddToggle("Enable Anti-AFK", "ป้องกันการโดนเตะเมื่อไม่ขยับ", "", true, function(Value)
    if Value then
        Library:ShowNotification("success", "Anti-AFK Enabled. You're now protected from being kicked.", 2, nil)
        AntiAFKConnection = Player.Idled:Connect(function()
            Virtual:CaptureController()
            Virtual:ClickButton2(Vector2.new())
        end)
    else
        if AntiAFKConnection then
            AntiAFKConnection:Disconnect()
            Library:ShowNotification("info", "Anti-AFK Disabled. You're no longer protected.", 2, nil)
        end
    end
end)

TabUtilities:AddToggle("Enable Anti-Ban", "ป้องกันการโดนแบนรหัส", "", false, function(Value)
    AntiBanEnabled = Value
    if Value then
        Library:ShowNotification("success", "Anti-Ban Activated! Monitoring suspicious activities.", 2, nil)
        ProtectAgainstBan()
    else
        if LogConnection then
            LogConnection:Disconnect()
            LogConnection = nil
        end
        Library:ShowNotification("info", "Anti-Ban Disabled. No longer monitoring.", 2, nil)
    end
end)



local TabSpeed = Library:AddTab("Speed")
TabSpeed:AddToggle("Enable Speed Boost", "เพิ่มความเร็วในการวิ่ง", "", false, function(Value)
    if Value then
        Player.Character.Humanoid.WalkSpeed = SpeedBoost
        Library:ShowNotification("success", "Speed Boost Enabled! Running faster!", 2, nil)
    else
        Player.Character.Humanoid.WalkSpeed = DefaultSpeed
        Library:ShowNotification("info", "Speed Boost Disabled. Back to normal speed.", 2, nil)
    end
end)

-- local TabPhotograph = Library:AddTab("Photograph")
-- TabPhotograph:AddToggle("Enable Reshade", "เปิด/ปิดการเพิ่มความสวยงามของภาพ", "", false, function(Value)
--     if Value then
--         local Lighting = game:GetService("Lighting")
        
--         Lighting.Brightness = 2
--         Lighting.Contrast = 1.5
--         Lighting.Ambient = Color3.fromRGB(128, 128, 255)
--         Lighting.OutdoorAmbient = Color3.fromRGB(100, 100, 255)
        
--         local blur = Instance.new("BlurEffect")
--         blur.Size = 5
--         blur.Parent = Lighting
        

--         local colorCorrection = Instance.new("ColorCorrectionEffect")
--         colorCorrection.Saturation = 0.3
--         colorCorrection.Contrast = 1.2
--         colorCorrection.Brightness = 0.2
--         colorCorrection.Parent = Lighting

--         Library:ShowNotification("success", "Reshade Enabled! Enjoy enhanced visuals.", 2, nil)
--     else
--         for _, effect in ipairs(game:GetService("Lighting"):GetChildren()) do
--             if effect:IsA("BlurEffect") or effect:IsA("ColorCorrectionEffect") then
--                 effect:Destroy()
--             end
--         end

--         local Lighting = game:GetService("Lighting")
--         Lighting.Brightness = 1
--         Lighting.Contrast = 1
--         Lighting.Ambient = Color3.fromRGB(127, 127, 127)
--         Lighting.OutdoorAmbient = Color3.fromRGB(127, 127, 127)

--         Library:ShowNotification("info", "Reshade Disabled. Back to default visuals.", 2, nil)
--     end
-- end)

-- TabPhotograph:AddToggle("Enable Photograph Mode", "เปิด/ปิดโหมดถ่ายรูป", "", false, function(Value)
--     if Value then
--         local camera = workspace.CurrentCamera
--         local viewportFrame = Instance.new("ViewportFrame")
--         viewportFrame.Size = UDim2.new(1, 0, 1, 0)
--         viewportFrame.BackgroundTransparency = 1
--         viewportFrame.Parent = Player.PlayerGui:WaitForChild("ScreenGui")
--         local characterClone = Player.Character:Clone()
--         characterClone.Parent = viewportFrame

--         local viewportCamera = Instance.new("Camera")
--         viewportCamera.CFrame = camera.CFrame
--         viewportCamera.Parent = viewportFrame
--         viewportFrame.CurrentCamera = viewportCamera

--         local blurEffect = Instance.new("BlurEffect")
--         blurEffect.Size = 24
--         blurEffect.Parent = game:GetService("Lighting")

--         local colorCorrection = Instance.new("ColorCorrectionEffect")
--         colorCorrection.Saturation = 0.3
--         colorCorrection.Contrast = 1.2
--         colorCorrection.Brightness = 0.2
--         colorCorrection.Parent = game:GetService("Lighting")
--         task.wait(1)

--         camera:CaptureScreenshotAsync():Then(function(screenshot)
--             Library:ShowNotification("success", "Photograph taken successfully!", 2, nil)

--             blurEffect:Destroy()
--             colorCorrection:Destroy()
--             viewportFrame:Destroy()
--         end)
--     else
--         local blurEffect = game:GetService("Lighting"):FindFirstChildOfClass("BlurEffect")
--         if blurEffect then
--             blurEffect:Destroy()
--         end
        
--         local colorCorrection = game:GetService("Lighting"):FindFirstChildOfClass("ColorCorrectionEffect")
--         if colorCorrection then
--             colorCorrection:Destroy()
--         end
        
--         local viewportFrame = Player.PlayerGui:WaitForChild("ScreenGui"):FindFirstChildOfClass("ViewportFrame")
--         if viewportFrame then
--             viewportFrame:Destroy()
--         end
        
--         Library:ShowNotification("info", "Photograph mode disabled. No longer capturing.", 2, nil)
--     end
-- end)



MainSignal = workspace.Debris.Clothing.ChildAdded:Connect(function(Cloth)
	if Configuration.Autofarm.Grabbing == true then
		if Player.NonSaveVars.BackpackAmount.Value == 0 or (Player.NonSaveVars.BasketStatus.Value == "Dirty" and Player.NonSaveVars.BackpackAmount.Value < Player.NonSaveVars.BasketSize.Value) then
			GrabClothing(Cloth)
		end
	end
end)

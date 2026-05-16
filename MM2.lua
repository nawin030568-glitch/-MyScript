-- [[ AOMHUB - MM2 Ultimate V5.4 x WindUI (Auto Pick Gun & White Meter Update) ]] --
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

-- ------------------------------------------------------------------------
-- [ ระบบตั้งค่าและโหลดข้อมูล ]
-- ------------------------------------------------------------------------
local ConfigFile = "AOMHUB_MM2_Config.json"
local Config = {
    espActive = false,
    gunEspActive = false,
    aimbotActive = false,
    autoShootActive = false,
    killAuraActive = false,
    coinMagnetActive = false,
    tracerActive = false,
    autoTpGunActive = false -- [NEW] ระบบวาร์ปเก็บปืนออโต้
}

local function SaveConfig()
    local success, json = pcall(function() return HttpService:JSONEncode(Config) end)
    if success then writefile(ConfigFile, json) end
end

local function LoadConfig()
    if isfile(ConfigFile) then
        local success, json = pcall(function() return readfile(ConfigFile) end)
        if success then
            local data = HttpService:JSONDecode(json)
            if data then for k, v in pairs(data) do Config[k] = v end end
        end
    end
end

LoadConfig()

-- ------------------------------------------------------------------------
-- [ โหลด WindUI Library ]
-- ------------------------------------------------------------------------
local WindUI
do
    local ok, result = pcall(function() return require("./src/Init") end)
    if ok then WindUI = result else
        WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/dist/main.lua"))()
    end
end

local Window = WindUI:CreateWindow({
    Title = "AOM HUB ",
    Author = "AOM",
    Folder = "AOMHUB_MM2",
    Icon = "computer",
    NewElements = true,
    HideSearchBar = true,
    OpenButton = {
        Title = "AOM HUB (MM2)",
        CornerRadius = UDim.new(1,0),
        StrokeThickness = 3,
        Enabled = true,
        Draggable = true,
        OnlyMobile = false,
        Color = ColorSequence.new(Color3.fromHex("#6633FF"), Color3.fromHex("#6633FF"))
    }
})

local MainTab = Window:Tab({ Title = "Main Features", Icon = "home" })
local ServerTab = Window:Tab({ Title = "Server Manager", Icon = "refresh" })
local ConfigTab = Window:Tab({ Title = "Config Settings", Icon = "settings" })

local CombatSection = MainTab:Section({ Title = "Combat & Gameplay" })
local EspSection = MainTab:Section({ Title = "Visuals & ESP" })
local ServerSection = ServerTab:Section({ Title = "Server Teleport Controls" })
local ConfigSection = ConfigTab:Section({ Title = "Profile Configuration" })

-- ------------------------------------------------------------------------
-- [ Core Functions - ระบบตรวจจับประสิทธิภาพสูง ]
-- ------------------------------------------------------------------------
local tracerLine = Drawing.new("Line")
tracerLine.Color = Color3.fromRGB(255, 0, 0)
tracerLine.Thickness = 2
tracerLine.Transparency = 1

-- [FIXED] เจาะลึกระบบค้นหาปืนตกแบบละเอียดยิบ ป้องกันสคริปต์มองไม่เห็นปืน
local function GetDroppedGun()
    local normal = Workspace:FindFirstChild("Normal")
    if normal then
        local gun = normal:FindFirstChild("GunDrop") or normal:FindFirstChild("DroppedGun")
        if gun then 
            return gun:IsA("Model") and (gun.PrimaryPart or gun:FindFirstChildWhichIsA("BasePart")) or gun
        end
    end
    -- ลูปสำรองขุดหาทั่วเซิร์ฟเวอร์เผื่อหลุดตำแหน่ง
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name == "GunDrop" or obj.Name == "DroppedGun" then
            if obj:IsA("Model") then
                return obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            elseif obj:IsA("BasePart") then
                return obj
            end
        end
    end
    return nil
end

local function GetMurderer()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            if p.Backpack:FindFirstChild("Knife") or p.Character:FindFirstChild("Knife") then 
                return p 
            end
        end
    end
    return nil
end

-- [NEW LOOPS] ระบบวาร์ปไปเก็บปืนทันทีเมื่อปืนตกพื้น (Auto Pick Up)
task.spawn(function()
    while true do
        task.wait(0.1) -- เช็คความถี่ระดับเสี้ยววินาที
        if Config.autoTpGunActive and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            -- ตรวจสอบก่อนว่าเรามีปืนอยู่กับตัวแล้วหรือยัง
            local hasGun = LocalPlayer.Character:FindFirstChild("Gun") or LocalPlayer.Backpack:FindFirstChild("Gun")
            if not hasGun then
                local gun = GetDroppedGun()
                if gun then
                    -- ทำการเทเลพอร์ตไปตำแหน่งปืนทันที
                    LocalPlayer.Character.HumanoidRootPart.CFrame = gun.CFrame * CFrame.new(0, 1, 0)
                end
            end
        end
    end
end)

-- ระบบดักจับและทำสี ESP ผู้เล่นแบบ Real-time
RunService.Heartbeat:Connect(function()
    if not Config.espActive then 
        for _, p in pairs(Players:GetPlayers()) do
            if p.Character and p.Character:FindFirstChild("AOM_ESP") then 
                p.Character.AOM_ESP:Destroy() 
            end
        end
        return 
    end

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") and p.Character.Humanoid.Health > 0 then
            local hl = p.Character:FindFirstChild("AOM_ESP")
            if not hl then
                hl = Instance.new("Highlight")
                hl.Name = "AOM_ESP"
                hl.FillTransparency = 0.5
                hl.OutlineTransparency = 0
                hl.Parent = p.Character
            end

            if p.Backpack:FindFirstChild("Knife") or p.Character:FindFirstChild("Knife") then
                hl.FillColor = Color3.fromRGB(255, 0, 0)
            elseif p.Backpack:FindFirstChild("Gun") or p.Character:FindFirstChild("Gun") then
                hl.FillColor = Color3.fromRGB(0, 0, 255)
            else
                hl.FillColor = Color3.fromRGB(0, 255, 0)
            end
        elseif p.Character and p.Character:FindFirstChild("AOM_ESP") and p.Character.Humanoid.Health <= 0 then
            p.Character.AOM_ESP:Destroy()
        end
    end
end)

-- ระบบ Camera Aimbot หันหน้าล็อกเป้าฆาตกร
RunService.RenderStepped:Connect(function()
    if Config.aimbotActive and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Gun") then
        local murderer = GetMurderer()
        if murderer and murderer.Character and murderer.Character:FindFirstChild("HumanoidRootPart") then
            local targetPart = murderer.Character:FindFirstChild("Head") or murderer.Character.HumanoidRootPart
            Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, targetPart.Position)
        end
    end
end)

-- ระบบ Silent Aim กระสุนหักเลี้ยวติดตามเป้าหมาย 100%
local oldHook
oldHook = hookmetamethod(game, "__index", function(self, index)
    if (Config.aimbotActive or Config.autoShootActive) and typeof(self) == "Instance" and self:IsA("Mouse") and (index == "Hit" or index == "Target") then
        local murderer = GetMurderer()
        if murderer and murderer.Character and murderer.Character:FindFirstChild("HumanoidRootPart") then
            if index == "Hit" then
                return murderer.Character.HumanoidRootPart.CFrame
            elseif index == "Target" then
                return murderer.Character.HumanoidRootPart
            end
        end
    end
    return oldHook(self, index)
end)

-- [FIXED] ลูปตรวจจับปืนตก (ปรับไฮไลท์สีเหลือง + ข้อความระยะทางสีขาวเมตร)
RunService.Heartbeat:Connect(function()
    local gun = GetDroppedGun()
    if not Config.gunEspActive or not gun then 
        if gun then
            if gun:FindFirstChild("AOM_GunESP") then gun.AOM_GunESP:Destroy() end
            if gun:FindFirstChild("AOM_GunDistance") then gun.AOM_GunDistance:Destroy() end
        end
        return 
    end
    
    if gun then
        -- ไฮไลท์รอบปืนสีเหลืองเด่นๆ
        if not gun:FindFirstChild("AOM_GunESP") then
            local hl = Instance.new("Highlight")
            hl.Name = "AOM_GunESP"
            hl.FillColor = Color3.fromRGB(255, 215, 0) -- สีเหลืองทอง
            hl.OutlineColor = Color3.fromRGB(255, 255, 255)
            hl.FillTransparency = 0.3
            hl.Parent = gun
        end
        
        -- ป้ายบอกระยะทางอักษรสีขาว หน่วยเป็นเมตร
        local bbg = gun:FindFirstChild("AOM_GunDistance")
        if not bbg then
            bbg = Instance.new("BillboardGui")
            bbg.Name = "AOM_GunDistance"
            bbg.Size = UDim2.new(0, 200, 0, 50)
            bbg.AlwaysOnTop = true
            bbg.StudsOffset = Vector3.new(0, 3, 0)
            
            local tl = Instance.new("TextLabel")
            tl.Name = "DistanceLabel"
            tl.Size = UDim2.new(1, 0, 1, 0)
            tl.BackgroundTransparency = 1
            tl.TextColor3 = Color3.fromRGB(255, 255, 255) -- เปลี่ยนเป็นสีขาวล้วน
            tl.TextSize = 16
            tl.Font = Enum.Font.GothamBold
            tl.TextStrokeTransparency = 0.4
            tl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            tl.Parent = bbg
            bbg.Parent = gun
        end
        
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local distance = math.floor((LocalPlayer.Character.HumanoidRootPart.Position - gun.Position).Magnitude)
            bbg.DistanceLabel.Text = "⚠️ DROPPED GUN\n[" .. tostring(distance) .. " เมตร]" -- เปลี่ยนข้อความหน่วยเป็นเมตร
        end
    end
end)

-- ระบบวาดเส้นชี้ทางไปหาฆาตกร (Tracer Line)
RunService.RenderStepped:Connect(function()
    if Config.tracerActive then
        local murderer = GetMurderer()
        if murderer and murderer.Character and murderer.Character:FindFirstChild("HumanoidRootPart") then
            local vector, onScreen = Camera:WorldToViewportPoint(murderer.Character.HumanoidRootPart.Position)
            if onScreen then
                tracerLine.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                tracerLine.To = Vector2.new(vector.X, vector.Y)
                tracerLine.Visible = true
            else
                tracerLine.Visible = false
            end
        else
            tracerLine.Visible = false
        end
    else
        tracerLine.Visible = false
    end
end)

-- ระบบสับไกปืนอัตโนมัติเมื่อถือปืน
local lastShot = 0
task.spawn(function()
    while true do
        task.wait(0.05)
        if Config.autoShootActive and LocalPlayer.Character then
            local gun = LocalPlayer.Character:FindFirstChild("Gun") or LocalPlayer.Backpack:FindFirstChild("Gun")
            if gun then
                local murderer = GetMurderer()
                if murderer and murderer.Character and murderer.Character:FindFirstChild("HumanoidRootPart") then
                    if tick() - lastShot > 0.5 then
                        lastShot = tick()
                        if LocalPlayer.Backpack:FindFirstChild("Gun") then
                            LocalPlayer.Character.Humanoid:EquipTool(gun)
                        end
                        task.wait(0.05)
                        gun:Activate()
                    end
                end
            end
        end
    end
end)

-- ระบบ Kill Aura แกว่งมีดโจมตีอัตโนมัติ
task.spawn(function()
    while true do
        task.wait(0.03)
        if Config.killAuraActive and LocalPlayer.Character then
            local knife = LocalPlayer.Character:FindFirstChild("Knife") or LocalPlayer.Backpack:FindFirstChild("Knife")
            if knife then
                if LocalPlayer.Backpack:FindFirstChild("Knife") then
                    LocalPlayer.Character.Humanoid:EquipTool(knife)
                end
                local handle = knife:FindFirstChild("Handle") or knife:FindFirstChildWhichIsA("BasePart")
                if handle then
                    for _, p in pairs(Players:GetPlayers()) do
                        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character:FindFirstChild("Humanoid") then
                            if p.Character.Humanoid.Health > 0 then
                                local distance = (LocalPlayer.Character.HumanoidRootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude
                                if distance <= 18 then
                                    if firetouchinterest then
                                        firetouchinterest(p.Character.HumanoidRootPart, handle, 0)
                                        firetouchinterest(p.Character.HumanoidRootPart, handle, 1)
                                    end
                                    knife:Activate()
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- ระบบดึงเหรียญทองเข้าหาตัวละคร
task.spawn(function()
    while true do
        task.wait(0.1)
        if Config.coinMagnetActive and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local container = Workspace:FindFirstChild("Normal") or Workspace:FindFirstChild("Map")
            if container then
                local coinContainer = container:FindFirstChild("CoinContainer")
                if coinContainer then
                    for _, obj in pairs(coinContainer:GetChildren()) do
                        if obj:IsA("BasePart") then
                            if (LocalPlayer.Character.HumanoidRootPart.Position - obj.Position).Magnitude <= 40 then
                                obj.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- ระบบเซิร์ฟเวอร์ย้ายห้องหนีคนเล่น
local function HopServer(mode)
    local sortOrder = (mode == "Low") and "Asc" or "Desc"
    local ApiUrl = "https://games.roproxy.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=" .. sortOrder .. "&limit=100"
    StarterGui:SetCore("SendNotification", {Title = "AOMHUB", Text = "กำลังค้นหาเซิร์ฟเวอร์...", Duration = 2})
    local success, result = pcall(function() return game:HttpGet(ApiUrl) end)
    if success and result then
        local decodeSuccess, data = pcall(function() return HttpService:JSONDecode(result) end)
        if decodeSuccess and data and data.data then
            for _, server in pairs(data.data) do
                if server.id and server.playing and server.maxPlayers then
                    if server.id ~= game.JobId and server.playing < server.maxPlayers then
                        if mode == "Low" and server.playing < 3 then continue end
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
                        return
                    end
                end
            end
        end
    end
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end

-- ------------------------------------------------------------------------
-- [ GUI Elements & Buttons Connect ]
-- ------------------------------------------------------------------------

-- ====== TAB 1: MAIN FEATURES ======

-- [NEW TOGGLE] ปุ่มเปิดระบบวาร์ปเก็บปืนอัตโนมัติเมื่อปืนตกพื้น
CombatSection:Toggle({
    Title = "Auto TP to Gun ",
    Desc = "วาร์ปไปทับตำแหน่งปืนทันทีเมื่อปืนตกพื้น",
    Default = Config.autoTpGunActive,
    Callback = function(state) Config.autoTpGunActive = state end
})

CombatSection:Toggle({
    Title = "Aimbot & Silent Aim",
    Desc = "ล็อกเป้า",
    Default = Config.aimbotActive,
    Callback = function(state) Config.aimbotActive = state end
})

CombatSection:Toggle({
    Title = "Auto Shoot Murderer ",
    Desc = "ยิงฆาตกรให้อัตโนมัติ(เมื่อถือปืน)",
    Default = Config.autoShootActive,
    Callback = function(state) Config.autoShootActive = state end
})

CombatSection:Toggle({
    Title = "Kill Aura (Knife)",
    Desc = "ฟันทุกคนในระยะ(ถือมีด)",
    Default = Config.killAuraActive,
    Callback = function(state) Config.killAuraActive = state end
})

CombatSection:Toggle({
    Title = "Coin Magnet",
    Desc = "ดึงเหรียญทองรอบตัว",
    Default = Config.coinMagnetActive,
    Callback = function(state) Config.coinMagnetActive = state end
})

EspSection:Toggle({
    Title = "Player Role ESP ",
    Desc = "มองบทบาท (Real-time)",
    Default = Config.espActive,
    Callback = function(state) Config.espActive = state end
})

EspSection:Toggle({
    Title = "Tracer Line to Murderer ",
    Desc = "เส้นชี้เป้าฆ่าตกร",
    Default = Config.tracerActive,
    Callback = function(state) Config.tracerActive = state end
})

EspSection:Toggle({
    Title = "Dropped Gun ESP ",
    Desc = "มองปืนตก",
    Default = Config.gunEspActive,
    Callback = function(state) Config.gunEspActive = state end
})

-- ====== TAB 2: SERVER MANAGER ======

ServerSection:Button({
    Title = "Rejoin Server",
    Desc = "รีเซิฟ",
    Callback = function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end
})

ServerSection:Button({
    Title = "Server Hop: High Players",
    Desc = "ย้ายไปเซิร์ฟเวอร์อื่นที่มีคนเยอะๆ",
    Callback = function() HopServer("High") end
})

ServerSection:Button({
    Title = "Server Hop: Low Players",
    Desc = "ย้ายไปเซิร์ฟเวอร์คนน้อย",
    Callback = function() HopServer("Low") end
})

-- ====== TAB 3: CONFIG SETTINGS ======

ConfigSection:Button({
    Title = "Manual Save Config 💾",
    Desc = "กดเพื่อบันทึก",
    Callback = function() 
        SaveConfig() 
        StarterGui:SetCore("SendNotification", {Title = "AOMHUB", Text = "บันทึกการตั้งค่าลงเครื่องเรียบร้อยแล้ว!", Duration = 2}) end
})

ConfigSection:Button({
    Title = "Reset Config 🔄",
    Desc = "ล้างค่าระบบให้กลับเป็นค่าเริ่มต้น(ยังไม่ได้บันทึก)",
    Callback = function()
        if isfile(ConfigFile) then
            pcall(function() delfile(ConfigFile) end)
        end
        Config.espActive = false
        Config.gunEspActive = false
        Config.aimbotActive = false
        Config.autoShootActive = false
        Config.killAuraActive = false
        Config.coinMagnetActive = false
        Config.tracerActive = false
        Config.autoTpGunActive = false
        tracerLine.Visible = false
        StarterGui:SetCore("SendNotification", {Title = "AOMHUB", Text = "ลบไฟล์เซฟแล้ว! สถานะกลับเป็น 'ยังไม่ได้บันทึก'", Duration = 3})
    end
})

StarterGui:SetCore("SendNotification", {
    Title = "AOMHUB V5.4 READY",
    Text = "ระบบวาร์ปเก็บปืนอัตโนมัติ และปรับระยะทางสีขาวเมตรเสร็จสิ้นครับ!",
    Duration = 3
})

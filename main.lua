-- ==========================================
-- AOMHUB | MASTER EDITION V10.0
-- Special Author: XuwuLBk60596 (AOM)
-- Status: Wallbang Bypass | Item ESP Integrated | Smooth Underground | Anti-Lock Fixed | Jump Added
-- ==========================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ContentProvider = game:GetService("ContentProvider")
local Debris = game:GetService("Debris")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- [ 1. Admin & Key System ]
local SpecialUser = "XuwuLBk60596"
local NeedsKey = (LocalPlayer.Name ~= SpecialUser)
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- [ 2. Global Variables ]
_G.BaseSpeed = 16
_G.WalkSpeedBoost = 5
_G.SpeedEnabled = false
_G.BaseJump = 50
_G.JumpBoost = 50
_G.JumpEnabled = false
_G.AntiLock = false 
_G.Underground = false
_G.UndergroundDepth = 10
_G.MagnetEnabled = false
_G.ItemESP_Enabled = false 

local CLIENT_ZONE_SIZE = Vector3.new(120, 14, 120)
local SERVER_FAKE_RADIUS = 2000
local MAGNET_SPEED = 0.8
local remoteGet = ReplicatedStorage:WaitForChild("Remotes", 10) and ReplicatedStorage.Remotes:WaitForChild("Get", 10)
local magnetCooldowns = {}

local ESP_Cache = {}
local SilentAimEnabled = false
local AimMode = "Normal" 
local SelectedBodyPart = "Head" 
_G.ShowSnapline = true 

local BASE_PREDICTION = 0.15
local VEHICLE_MULTIPLIER = 0.6
local GunLookup = {
    ["P226"]=true, ["MP5"]=true, ["M24"]=true, ["Draco"]=true, ["Glock"]=true,
    ["Sawnoff"]=true, ["Uzi"]=true, ["G3"]=true, ["C9"]=true, ["Hunting Rifle"]=true,
    ["Anaconda"]=true, ["AK47"]=true, ["Remington"]=true, ["Double Barrel"]=true
}

local FOVCircle = Drawing.new("Circle")
FOVCircle.Radius = 120; FOVCircle.Thickness = 2; FOVCircle.Filled = false; FOVCircle.Color = Color3.fromRGB(220, 20, 60); FOVCircle.Visible = false
local Snapline = Drawing.new("Line")
Snapline.Thickness = 1.5; Snapline.Color = Color3.fromRGB(0, 255, 255); Snapline.Visible = false

local FakeFloor = nil
local GroundY = 0
local originalVelocity = nil

-- ==========================================
-- [ 3. ITEM ESP LOGIC (ฟังก์ชันเดิมห้ามลบ) ]
-- ==========================================
local BillboardCache = {}
local ItemESP_UpdateConnections = {}
local WeaponDB = {}
local PreloadedImages = {}

local RARITY_COLORS = {
    ["Common"] = Color3.fromRGB(255, 255, 255),
    ["Uncommon"] = Color3.fromRGB(99, 255, 52),
    ["Rare"] = Color3.fromRGB(51, 170, 255),
    ["Epic"] = Color3.fromRGB(237, 44, 255),
    ["Legendary"] = Color3.fromRGB(255, 150, 0),
    ["Omega"] = Color3.fromRGB(255, 20, 51),
}

local function generateUniqueKey(tool)
    if not tool or not tool:IsA("Tool") then return nil end
    local itemId = tool:GetAttribute("ItemId") or tool:GetAttribute("Id")
    if itemId and itemId ~= "" and (typeof(itemId) == "string" or typeof(itemId) == "number") then return "ITEMID_" .. tostring(itemId) end
    local partsData = {}
    for _, part in ipairs(tool:GetDescendants()) do
        if part:IsA("SpecialMesh") and part.MeshId and part.MeshId ~= "" and part.MeshId ~= "rbxassetid://" then table.insert(partsData, "MESH_"..part.MeshId.."|TEX_"..(part.TextureId or "NOTEX"))
        elseif part:IsA("MeshPart") and part.MeshId and part.MeshId ~= "" and part.MeshId ~= "rbxassetid://" then table.insert(partsData, "MESH_"..part.MeshId.."|TEX_"..(part.TextureID or "NOTEX"))
        elseif part:IsA("Decal") and part.Texture and part.Texture ~= "" and part.Texture ~= "rbxassetid://" then table.insert(partsData, "DECAL_"..part.Texture)
        elseif part:IsA("Part") then table.insert(partsData, "PART_"..part.Name.."_"..part.Size.X.."x"..part.Size.Y.."x"..part.Size.Z) end
    end
    if #partsData > 0 then table.sort(partsData); return "MESHKEY_" .. table.concat(partsData, ";") end
    local displayName = tool:GetAttribute("DisplayName") or tool.Name
    local rarity = tool:GetAttribute("RarityName") or tool:GetAttribute("Rarity") or "Unknown"
    local imageId = tool:GetAttribute("ImageId") or "NOIMAGE"
    return "NAME_" .. displayName .. "_" .. tool.Name .. "_" .. rarity .. "_" .. imageId
end

local function registerItems(folder)
    for _, tool in ipairs(folder:GetDescendants()) do
        if not tool:IsA("Tool") then continue end
        local key = generateUniqueKey(tool)
        if not key then continue end
        local displayName = tool:GetAttribute("DisplayName") or tool.Name
        local imageId = tool:GetAttribute("ImageId") or "rbxassetid://7072725737"
        local rarity = tool:GetAttribute("RarityName") or tool:GetAttribute("Rarity") or "Common"
        WeaponDB[key] = { Name = displayName, Rarity = rarity, ImageId = imageId, ToolName = tool.Name, Key = key }
        if imageId and imageId ~= "" and not PreloadedImages[imageId] then
            PreloadedImages[imageId] = true
            task.spawn(function() pcall(function() ContentProvider:PreloadAsync({imageId}) end) end)
        end
    end
end

pcall(function()
    local itemsFolder = ReplicatedStorage:WaitForChild("Items", 5)
    if itemsFolder then registerItems(itemsFolder) end
    for _, obj in ipairs(ReplicatedStorage:GetChildren()) do
        if obj:IsA("Folder") and (obj.Name:find("Weapon") or obj.Name:find("Item") or obj.Name:find("Tool")) then registerItems(obj) end
    end
    registerItems(game:GetService("StarterPack"))
end)

local function getWeaponInfo(tool)
    if not tool or not tool:IsA("Tool") then return nil end
    local key = generateUniqueKey(tool)
    return WeaponDB[key]
end

local function createBillboardForPlayer(player)
    if player == LocalPlayer or BillboardCache[player] then return end
    local billboard, container, layout
    local connections = {}
    local function updateESP()
        if not _G.ItemESP_Enabled or not billboard.Parent then 
            if container then container.Visible = false end return 
        else
            if container then container.Visible = true end
        end
        local currentTools = {}
        local function scan(folder)
            if not folder then return end
            for _, tool in ipairs(folder:GetChildren()) do
                if tool:IsA("Tool") and tool.Name ~= "Fists" then
                    local info = getWeaponInfo(tool)
                    if info then table.insert(currentTools, info) end
                end
            end
        end
        local char = player.Character
        if char then scan(char); local backpack = player:FindFirstChild("Backpack"); if backpack then scan(backpack) end end
        container:ClearAllChildren()
        layout = Instance.new("UIGridLayout")
        layout.CellSize = UDim2.new(0, 35, 0, 35); layout.CellPadding = UDim2.new(0, 6, 0, 0)
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center; layout.VerticalAlignment = Enum.VerticalAlignment.Center
        layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Parent = container
        for i, info in ipairs(currentTools) do
            local img = Instance.new("ImageLabel", container)
            img.Size = UDim2.new(0, 35, 0, 35); img.BackgroundTransparency = 1; img.Image = info.ImageId or "rbxassetid://7072725737"
            img.ScaleType = Enum.ScaleType.Fit; img.LayoutOrder = i
            local color = RARITY_COLORS[info.Rarity] or Color3.fromRGB(255, 255, 255)
            img.ImageColor3 = color:Lerp(Color3.new(1,1,1), 0.35)
        end
    end

    local function setupBillboard()
        local char = player.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        if BillboardCache[player] then BillboardCache[player]:Destroy() end
        for _, conn in pairs(connections) do if conn.Connected then conn:Disconnect() end end
        connections = {}
        billboard = Instance.new("BillboardGui")
        billboard.Name = "ItemESP"; billboard.Adornee = hrp; billboard.Size = UDim2.new(0, 280, 0, 40)
        billboard.StudsOffset = Vector3.new(0, -6.5, 0); billboard.AlwaysOnTop = true; billboard.LightInfluence = 0; billboard.Parent = hrp
        container = Instance.new("Frame", billboard)
        container.Size = UDim2.new(1, 0, 1, 0); container.BackgroundTransparency = 1
        BillboardCache[player] = billboard
        updateESP()
        local backpack = player:FindFirstChild("Backpack")
        if backpack then table.insert(connections, backpack.ChildAdded:Connect(updateESP)); table.insert(connections, backpack.ChildRemoved:Connect(updateESP)) end
        table.insert(connections, char.ChildAdded:Connect(function(child) if child:IsA("Tool") then task.defer(updateESP) end end))
        table.insert(connections, char.ChildRemoved:Connect(function(child) if child:IsA("Tool") then task.defer(updateESP) end end))
    end
    if player.Character then task.spawn(setupBillboard) end
    table.insert(connections, player.CharacterAdded:Connect(function() task.wait(1); setupBillboard() end))
    ItemESP_UpdateConnections[player] = connections
end

for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then createBillboardForPlayer(p) end end
Players.PlayerAdded:Connect(function(p) if p ~= LocalPlayer then createBillboardForPlayer(p) end end)
Players.PlayerRemoving:Connect(function(p)
    if BillboardCache[p] then BillboardCache[p]:Destroy(); BillboardCache[p] = nil end
    if ItemESP_UpdateConnections[p] then for _, conn in pairs(ItemESP_UpdateConnections[p]) do if conn.Connected then conn:Disconnect() end end; ItemESP_UpdateConnections[p] = nil end
end)

local DroppedESP_Cache = {}
local function updateDroppedESP()
    local droppedItemsFolder = workspace:FindFirstChild("DroppedItems")
    if not droppedItemsFolder then return end
    for _, item in pairs(droppedItemsFolder:GetChildren()) do
        if not DroppedESP_Cache[item] then
            local part = item:IsA("BasePart") and item or item:FindFirstChildWhichIsA("BasePart") or item:FindFirstChild("PickUpZone")
            if part then
                local bg = Instance.new("BillboardGui")
                bg.Size = UDim2.new(0, 100, 0, 30); bg.AlwaysOnTop = true; bg.Adornee = part; bg.StudsOffset = Vector3.new(0, 1.5, 0)
                local txt = Instance.new("TextLabel", bg)
                txt.Size = UDim2.new(1,0,1,0); txt.BackgroundTransparency = 1; txt.Text = item.Name; txt.TextColor3 = Color3.fromRGB(255, 200, 50)
                txt.TextStrokeTransparency = 0; txt.Font = Enum.Font.SourceSansBold; txt.TextSize = 13
                bg.Parent = part; DroppedESP_Cache[item] = bg
            end
        end
        if DroppedESP_Cache[item] then DroppedESP_Cache[item].Enabled = _G.ItemESP_Enabled end
    end
    for item, bg in pairs(DroppedESP_Cache) do if not item.Parent then bg:Destroy(); DroppedESP_Cache[item] = nil end end
end

-- ==========================================
-- [ 4. CORE LOGIC: MAGNET & ZONES ]
-- ==========================================
local function resizeZones()
    local droppedItems = workspace:FindFirstChild("DroppedItems")
    if droppedItems then
        for _, item in pairs(droppedItems:GetChildren()) do
            local zone = item:FindFirstChild("PickUpZone")
            if zone and zone:IsA("BasePart") then
                zone.Size = CLIENT_ZONE_SIZE; zone.Transparency = 1; zone.CanCollide = false; zone.Anchored = true
            end
        end
    end
end
local droppedFolder = workspace:FindFirstChild("DroppedItems")
if droppedFolder then resizeZones(); droppedFolder.ChildAdded:Connect(function() if _G.MagnetEnabled then resizeZones() end end) end

-- ==========================================
-- [ 5. ADVANCED SILENT AIM & WALLBANG (FIXED LOCK ON TARGET) ]
-- ==========================================
local function GetActualPart(character, partName)
    if partName == "Head" then return character:FindFirstChild("Head")
    elseif partName == "Torso" then return character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart") end
    return character:FindFirstChild("HumanoidRootPart")
end

local function GetClosestTarget()
    local closest; local shortest = math.huge; local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
            local part = GetActualPart(plr.Character, SelectedBodyPart)
            if part then
                local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    if dist < shortest and dist <= FOVCircle.Radius then shortest = dist; closest = plr end
                end
            end
        end
    end
    return closest
end

local function PredictPosition(partToAim)
    local root = partToAim.Parent:FindFirstChild("HumanoidRootPart")
    if not root then return partToAim.Position end
    local vel = root.Velocity; local seat = root:FindFirstChildWhichIsA("WeldConstraint") or root:FindFirstChildWhichIsA("Weld")
    local vehVel = seat and seat.Part0 and seat.Part0.Velocity or Vector3.new()
    local speedMult = math.clamp(vehVel.Magnitude/50, 0.5, 2)
    return partToAim.Position + (vel + vehVel * VEHICLE_MULTIPLIER * speedMult) * BASE_PREDICTION
end

local function IsHoldingAllowedGun(args)
    local ok, weapon = pcall(function() return args[3] end)
    if ok and typeof(weapon)=="Instance" and GunLookup[weapon.Name] then return true end
    for _,tool in pairs(LocalPlayer.Character:GetChildren()) do if (tool:IsA("Tool") or tool:IsA("Model")) and GunLookup[tool.Name] then return true end end
    return false
end

local function SpawnDebugBullet(startPos, targetPos)
    local dist = (targetPos - startPos).Magnitude
    local part = Instance.new("Part"); part.Anchored = true; part.CanCollide = false; part.Material = Enum.Material.Neon
    part.Size = Vector3.new(0.1, 0.1, dist); part.CFrame = CFrame.new(startPos, targetPos) * CFrame.new(0, 0, -dist/2); part.Color = Color3.fromRGB(255, 50, 150)
    part.Parent = workspace; Debris:AddItem(part, 5)
end

task.spawn(function()
    local sendRemote
    for _, v in pairs(ReplicatedStorage:GetDescendants()) do if v:IsA("RemoteEvent") and v.Name == "Send" then sendRemote = v; break end end
    if sendRemote then
        local oldFire; oldFire = hookfunction(sendRemote.FireServer, function(self, ...)
            local args = {...}
            if SilentAimEnabled and IsHoldingAllowedGun(args) then
                local target = GetClosestTarget()
                if target and target.Character then
                    local part = GetActualPart(target.Character, SelectedBodyPart)
                    if part then
                        -- [ FIXED LOGIC: บังคับล็อคตามจุดที่เส้น Snapline ชี้ ]
                        local aimPos = part.Position
                        
                        if AimMode == "Normal" then
                            aimPos = PredictPosition(part)
                        elseif AimMode == "Anti-Lock (ยิงตัวส่าย)" then
                            local hrp = target.Character:FindFirstChild("HumanoidRootPart")
                            if hrp and (hrp.Velocity.Magnitude > 65 or math.abs(hrp.Velocity.Y) > 80) then 
                                aimPos = part.Position -- ยิงอัดส่วนที่ชี้ทันที
                            else
                                aimPos = PredictPosition(part)
                            end
                        end
                        
                        -- หากตัวเราเปิด Anti-Lock บังคับล็อคเป้าหมายให้ตรงจุดชี้เป้า 100%
                        if _G.AntiLock then
                            aimPos = part.Position
                        end
                        
                        args[4] = CFrame.new(math.huge, math.huge, math.huge, 0, 0, 0, 0, 0, 0, 0, 0, 0)
                        args[5] = {[1] = {[1] = {["Instance"] = part, ["Position"] = aimPos}}}
                        
                        local myHead = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head")
                        if myHead then SpawnDebugBullet(myHead.Position, aimPos) end
                    end
                end
            end
            return oldFire(self, unpack(args))
        end)
    end
end)

-- ==========================================
-- [ 6. UI SETUP ]
-- ==========================================
local Window = Rayfield:CreateWindow({
   Name = "AOMHUB | 👑 V10.0 MASTER",
   LoadingTitle = "Penetration, Item ESP & Smooth Underground",
   KeySystem = NeedsKey,
   KeySettings = { Title = "AOMHUB Security", SaveKey = true, Key = {"AOM-PRO-X1A9"} }
})

local TabCombat = Window:CreateTab("🎯 Combat", 4483362458)
TabCombat:CreateToggle({Name = "เปิด Silent Aim (ทะลุกำแพง)", CurrentValue = false, Callback = function(v) SilentAimEnabled = v end})
TabCombat:CreateDropdown({Name = "เลือกส่วนที่จะยิง", Options = {"Head", "Torso"}, CurrentOption = "Head", Callback = function(v) SelectedBodyPart = v end})
TabCombat:CreateDropdown({Name = "โหมดยิง", Options = {"Normal", "Anti-Lock (ยิงตัวส่าย)"}, CurrentOption = "Normal", Callback = function(v) AimMode = v end})
TabCombat:CreateToggle({Name = "แสดงเส้นชี้เป้า (Snapline)", CurrentValue = true, Callback = function(v) _G.ShowSnapline = v end})
TabCombat:CreateToggle({Name = "Ghost Anti-Lock (ส่ายจอไม่ส่าย)", CurrentValue = false, Callback = function(v) _G.AntiLock = v end})
TabCombat:CreateSlider({Name = "ขนาด FOV", Range = {50, 800}, Increment = 10, CurrentValue = 120, Callback = function(v) FOVCircle.Radius = v end})
TabCombat:CreateToggle({Name = "แสดงวง FOV", CurrentValue = false, Callback = function(v) FOVCircle.Visible = v end})

local TabVisuals = Window:CreateTab("👁️ Visuals", 4483362458)
TabVisuals:CreateToggle({Name = "Box ESP", CurrentValue = false, Callback = function(v) _G.ESP_Box = v end})
TabVisuals:CreateToggle({Name = "Name ESP", CurrentValue = false, Callback = function(v) _G.ESP_Name = v end})
TabVisuals:CreateToggle({Name = "Item ESP", CurrentValue = false, Callback = function(v) 
    _G.ItemESP_Enabled = v 
    for _, p in ipairs(Players:GetPlayers()) do 
        if p ~= LocalPlayer and BillboardCache[p] then 
            local container = BillboardCache[p]:FindFirstChildWhichIsA("Frame")
            if container then container.Visible = v end
        end 
    end
end})

local TabPlayer = Window:CreateTab("⚡ Player", 4483362458)
TabPlayer:CreateToggle({Name = "เปิดวิ่งไว", CurrentValue = false, Callback = function(v) 
    _G.SpeedEnabled = v; 
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    if v and hum then _G.BaseSpeed = hum.WalkSpeed end 
end})
TabPlayer:CreateSlider({Name = "ความเร็วที่เพิ่ม", Range = {1, 10}, Increment = 1, CurrentValue = 5, Callback = function(v) _G.WalkSpeedBoost = v end})
TabPlayer:CreateToggle({Name = "เปิดกระโดดสูง", CurrentValue = false, Callback = function(v) 
    _G.JumpEnabled = v; 
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
    if v and hum then 
        hum.UseJumpPower = true
        _G.BaseJump = hum.JumpPower 
    end 
end})
TabPlayer:CreateSlider({Name = "พลังกระโดดที่เพิ่ม", Range = {10, 200}, Increment = 5, CurrentValue = 50, Callback = function(v) _G.JumpBoost = v end})

TabPlayer:CreateToggle({Name = "มุดดิน", CurrentValue = false, Callback = function(v) 
    _G.Underground = v 
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if v and hrp then
        GroundY = hrp.Position.Y 
        if not FakeFloor then
            FakeFloor = Instance.new("Part", Workspace); FakeFloor.Size = Vector3.new(300, 2, 300); FakeFloor.Anchored = true; FakeFloor.Transparency = 1
        end
        local targetY = GroundY - _G.UndergroundDepth
        FakeFloor.Position = Vector3.new(hrp.Position.X, targetY, hrp.Position.Z)
        hrp.CFrame = CFrame.new(hrp.Position.X, targetY + 3, hrp.Position.Z)
    else
        if FakeFloor then FakeFloor:Destroy(); FakeFloor = nil end
        if hrp then hrp.CFrame = CFrame.new(hrp.Position.X, GroundY + 3, hrp.Position.Z) end
    end
end})

local TabMisc = Window:CreateTab("💎 Utility", 4483362458)
TabMisc:CreateToggle({Name = "เปิดแม่เหล็กดูดของ", CurrentValue = false, Callback = function(v) _G.MagnetEnabled = v; if v then resizeZones() end end})

-- ==========================================
-- [ 7. ENGINE ]
-- ==========================================
local function CreateESP(player)
    local esp = { Box = Drawing.new("Square"), Name = Drawing.new("Text") }
    esp.Box.Visible = false; esp.Box.Color = Color3.fromRGB(255, 0, 0); esp.Box.Thickness = 1.5; esp.Box.Filled = false
    esp.Name.Visible = false; esp.Name.Color = Color3.fromRGB(255, 255, 255); esp.Name.Size = 12; esp.Name.Center = true; esp.Name.Outline = true
    ESP_Cache[player] = esp
end

for _, v in pairs(Players:GetPlayers()) do if v ~= LocalPlayer then CreateESP(v) end end
Players.PlayerAdded:Connect(function(v) CreateESP(v) end)
Players.PlayerRemoving:Connect(function(v) if ESP_Cache[v] then ESP_Cache[v].Box:Remove(); ESP_Cache[v].Name:Remove(); ESP_Cache[v] = nil end end)

RunService.Heartbeat:Connect(function()
    pcall(function()
        local char = LocalPlayer.Character; if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart"); local hum = char:FindFirstChild("Humanoid"); if not hrp then return end

        if _G.MagnetEnabled and remoteGet then
            local dropped = workspace:FindFirstChild("DroppedItems")
            if dropped then
                for _, item in pairs(dropped:GetChildren()) do
                    if (hrp.Position - item.Position).Magnitude <= SERVER_FAKE_RADIUS then
                        local currentTime = tick()
                        if currentTime - (magnetCooldowns[item] or 0) > 0.5 then
                            magnetCooldowns[item] = currentTime
                            task.spawn(function() pcall(function() remoteGet:InvokeServer("pickup_dropped_item", item) end) end)
                        end
                        local part = item:IsA("BasePart") and item or item:FindFirstChildWhichIsA("BasePart")
                        if part then part.CFrame = part.CFrame:Lerp(CFrame.new(hrp.Position), MAGNET_SPEED) end
                    end
                end
            end
        end

        if _G.SpeedEnabled and hum then hum.WalkSpeed = _G.BaseSpeed + _G.WalkSpeedBoost end
        if _G.JumpEnabled and hum then hum.UseJumpPower = true; hum.JumpPower = _G.BaseJump + _G.JumpBoost end

        if _G.AntiLock then
            originalVelocity = hrp.Velocity
            hrp.Velocity = Vector3.new(math.random(-150, 150), -600, math.random(-150, 150))
        end
    end)
end)

RunService.RenderStepped:Connect(function()
    if _G.AntiLock and originalVelocity then
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.Velocity = originalVelocity end
    end

    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local target = GetClosestTarget()
    if target and target.Character and SilentAimEnabled and _G.ShowSnapline then
        local part = GetActualPart(target.Character, SelectedBodyPart)
        if part then
            local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
            if onScreen then 
                Snapline.Visible = true; Snapline.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y); Snapline.To = Vector2.new(pos.X, pos.Y)
            else Snapline.Visible = false end
        end
    else Snapline.Visible = false end

    for plr, esp in pairs(ESP_Cache) do
        if plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character.Humanoid.Health > 0 then
            local rootPos, onScreen = Camera:WorldToViewportPoint(plr.Character.HumanoidRootPart.Position)
            if onScreen then
                if _G.ESP_Box then esp.Box.Visible = true; esp.Box.Size = Vector2.new(2000/rootPos.Z, 3000/rootPos.Z); esp.Box.Position = Vector2.new(rootPos.X - esp.Box.Size.X/2, rootPos.Y - esp.Box.Size.Y/2) else esp.Box.Visible = false end
                if _G.ESP_Name then esp.Name.Visible = true; esp.Name.Position = Vector2.new(rootPos.X, rootPos.Y - 30); esp.Name.Text = plr.Name else esp.Name.Visible = false end
            else esp.Box.Visible = false; esp.Name.Visible = false end
        else esp.Box.Visible = false; esp.Name.Visible = false end
    end
    updateDroppedESP()
end)

Rayfield:Notify({Title = "AOMHUB V10.0", Content = "Aim-Lock & Snapline Sync Successfully!", Duration = 5})

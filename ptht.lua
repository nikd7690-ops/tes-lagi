-- [[ ALPHA PROJECT - AUTO PTHT (PERFECT RADAR & SMOOTH FLIGHT) ]] --

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local LP = Players.LocalPlayer

-- Remotes
local PlaceRemote = RS:WaitForChild("Remotes"):WaitForChild("PlayerPlaceItem")
local FistRemote = RS:WaitForChild("Remotes"):WaitForChild("PlayerFist")
local PacketFolder = RS:WaitForChild("Remotes"):FindFirstChild("PlayerMovementPackets")
local MyRemote = PacketFolder and PacketFolder:FindFirstChild(LP.Name)

-- Cari Halaman UI
local ScreenGui = getgenv().AlphaProjectUI
if not ScreenGui then warn("Alpha Project UI tidak ditemukan!") return end
local Page = ScreenGui:FindFirstChild("PTHTPage", true)
if not Page then warn("Halaman PTHT tidak ditemukan!") return end

for _, child in pairs(Page:GetChildren()) do
    if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then child:Destroy() end
end

local Theme = {
    Main = Color3.fromRGB(15, 17, 20),    
    Item = Color3.fromRGB(30, 33, 38),    
    Accent = Color3.fromRGB(0, 255, 220), 
    Text = Color3.fromRGB(240, 245, 255),
    SubText = Color3.fromRGB(160, 165, 175)
}

-- [[ VARIABEL GLOBAL PTHT ]] --
_G.PTHT_Plant = false
_G.PTHT_SlotIndex = nil
_G.PTHT_ItemID = nil
_G.PTHT_RestockPos2D = nil

local TILE_SIZE = 4.5 
local X_MIN, X_MAX = 0, 100 
local Y_MIN, Y_MAX = 6, 60  
local MAIN_LAYER = 1
local WorldManager = require(RS.Managers.WorldManager)
local PlantQueue = {} 

-- ==========================================
-- [[ 1. UI SETUP ]]
-- ==========================================
local function GetInventorySaplings()
    local items = {}
    pcall(function()
        local InventoryModule = require(RS.Modules.Inventory)
        local ItemsManager = require(RS.Managers.ItemsManager)
        for slotIndex, itemData in pairs(InventoryModule.Stacks) do
            if type(itemData) == "table" and itemData.Id then
                local itemStringID = itemData.Id 
                local dataInfo = ItemsManager.ItemsData and ItemsManager.ItemsData[itemStringID]
                local realName = (dataInfo and dataInfo.Name) or itemStringID
                if string.match(string.lower(itemStringID), "sapling") or string.match(string.lower(itemStringID), "seed") then
                    local displayName = realName .. " [Slot " .. tostring(slotIndex) .. "]"
                    if not items[displayName] then items[displayName] = {Slot = slotIndex, ID = itemStringID} end
                end
            end
        end
    end)
    if next(items) == nil then items["Tidak ada Bibit di Tas!"] = {Slot = nil, ID = nil} end
    return items
end

local DropRow = Instance.new("Frame", Page)
DropRow.Size = UDim2.new(1, -10, 0, 35)
DropRow.BackgroundColor3 = Theme.Item
DropRow.ZIndex = 50 -- FIX: Memaksa frame ini tampil paling depan
Instance.new("UICorner", DropRow).CornerRadius = UDim.new(0, 6)

local DropLbl = Instance.new("TextLabel", DropRow)
DropLbl.Size = UDim2.new(0.5, 0, 1, 0); DropLbl.Position = UDim2.new(0, 10, 0, 0)
DropLbl.Text = "Select Sapling"; DropLbl.TextColor3 = Theme.Text; DropLbl.Font = Enum.Font.Gotham
DropLbl.TextSize = 12; DropLbl.BackgroundTransparency = 1; DropLbl.TextXAlignment = Enum.TextXAlignment.Left
DropLbl.ZIndex = 51

local DropBtn = Instance.new("TextButton", DropRow)
DropBtn.Size = UDim2.new(0.45, -10, 0.8, 0); DropBtn.Position = UDim2.new(0.55, 0, 0.1, 0)
DropBtn.BackgroundColor3 = Theme.Main; DropBtn.Text = "Pilih Bibit..."; DropBtn.TextColor3 = Theme.SubText
DropBtn.Font = Enum.Font.Gotham; DropBtn.TextSize = 11
DropBtn.ZIndex = 51
Instance.new("UICorner", DropBtn).CornerRadius = UDim.new(0, 6)

local DropList = Instance.new("ScrollingFrame", DropRow)
DropList.Size = UDim2.new(0.45, -10, 0, 100); DropList.Position = UDim2.new(0.55, 0, 1.1, 0)
DropList.BackgroundColor3 = Theme.Main; DropList.Visible = false
DropList.BorderSizePixel = 0; DropList.ScrollBarThickness = 2
DropList.ZIndex = 100 -- FIX: List ini dipaksa di atas segalanya
Instance.new("UICorner", DropList).CornerRadius = UDim.new(0, 6)

local DropLayout = Instance.new("UIListLayout", DropList)
DropLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
Instance.new("UIPadding", DropList).PaddingTop = UDim.new(0, 5)

local function RefreshPTHTDropdown()
    for _, child in pairs(DropList:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
    for displayName, itemData in pairs(GetInventorySaplings()) do
        local ItemBtn = Instance.new("TextButton", DropList)
        ItemBtn.Size = UDim2.new(1, 0, 0, 25); ItemBtn.BackgroundTransparency = 1
        ItemBtn.Text = displayName; ItemBtn.TextColor3 = Theme.SubText
        ItemBtn.Font = Enum.Font.Gotham; ItemBtn.TextSize = 11
        ItemBtn.ZIndex = 101 -- Teks list di atas segalanya
        ItemBtn.MouseButton1Click:Connect(function()
            _G.PTHT_SlotIndex = itemData.Slot 
            _G.PTHT_ItemID = itemData.ID
            DropBtn.Text = displayName
            DropList.Visible = false
        end)
    end
    DropList.CanvasSize = UDim2.new(0, 0, 0, DropLayout.AbsoluteContentSize.Y + 10)
end

DropBtn.MouseButton1Click:Connect(function() 
    if not DropList.Visible then RefreshPTHTDropdown() end 
    DropList.Visible = not DropList.Visible 
end)

RefreshPTHTDropdown()

local function CreateToggle(name, globalVar)
    local Frame = Instance.new("Frame", Page)
    Frame.Size = UDim2.new(1, -10, 0, 35); Frame.BackgroundColor3 = Theme.Item; Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)
    local Lbl = Instance.new("TextLabel", Frame); Lbl.Size = UDim2.new(0.6, 0, 1, 0); Lbl.Position = UDim2.new(0, 10, 0, 0); Lbl.Text = name; Lbl.TextColor3 = Theme.Text; Lbl.Font = Enum.Font.Gotham; Lbl.TextSize = 12; Lbl.BackgroundTransparency = 1; Lbl.TextXAlignment = Enum.TextXAlignment.Left
    local Btn = Instance.new("TextButton", Frame); Btn.Size = UDim2.new(0.45, -10, 0.1, 22); Btn.Position = UDim2.new(0.58, -10, 0.5, -11); Btn.BackgroundColor3 = Theme.Main; Btn.Text = "OFF"; Btn.TextColor3 = Color3.fromRGB(255, 80, 80); Btn.Font = Enum.Font.GothamBold; Btn.TextSize = 10; Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 4)
    local Stroke = Instance.new("UIStroke", Btn); Stroke.Color = Color3.fromRGB(255, 80, 80); Stroke.Thickness = 1
    
    Btn.MouseButton1Click:Connect(function()
        _G[globalVar] = not _G[globalVar]
        if _G[globalVar] then
            Btn.Text = "ON"; Btn.TextColor3 = Theme.Accent; Stroke.Color = Theme.Accent
        else
            Btn.Text = "OFF"; Btn.TextColor3 = Color3.fromRGB(255, 80, 80); Stroke.Color = Color3.fromRGB(255, 80, 80)
            -- Lepas jangkar saat dimatikan
            local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if root then root.Anchored = false end
        end
    end)
end

CreateToggle("Smart Auto Plant (Drone)", "PTHT_Plant")

local StorageFrame = Instance.new("Frame", Page); StorageFrame.Size = UDim2.new(1, -10, 0, 35); StorageFrame.BackgroundColor3 = Theme.Item; Instance.new("UICorner", StorageFrame).CornerRadius = UDim.new(0, 6)
local StorageLbl = Instance.new("TextLabel", StorageFrame); StorageLbl.Size = UDim2.new(0.4, 0, 1, 0); StorageLbl.Position = UDim2.new(0, 10, 0, 0); StorageLbl.Text = "Set Restock Pos"; StorageLbl.TextColor3 = Theme.Text; StorageLbl.Font = Enum.Font.Gotham; StorageLbl.TextSize = 12; StorageLbl.BackgroundTransparency = 1; StorageLbl.TextXAlignment = Enum.TextXAlignment.Left
local StorageCoord = Instance.new("TextLabel", StorageFrame); StorageCoord.Size = UDim2.new(0.3, 0, 1, 0); StorageCoord.Position = UDim2.new(0.4, 0, 0, 0); StorageCoord.Text = "[ NONE ]"; StorageCoord.TextColor3 = Theme.SubText; StorageCoord.Font = Enum.Font.Gotham; StorageCoord.TextSize = 10; StorageCoord.BackgroundTransparency = 1; StorageCoord.TextXAlignment = Enum.TextXAlignment.Center
local StorageBtn = Instance.new("TextButton", StorageFrame); StorageBtn.Size = UDim2.new(0.25, -10, 0.1, 22); StorageBtn.Position = UDim2.new(0.75, 0, 0.5, -11); StorageBtn.BackgroundColor3 = Theme.Main; StorageBtn.Text = "SAVE"; StorageBtn.TextColor3 = Theme.Accent; StorageBtn.Font = Enum.Font.GothamBold; StorageBtn.TextSize = 10; Instance.new("UICorner", StorageBtn).CornerRadius = UDim.new(0, 4)
local StorageStroke = Instance.new("UIStroke", StorageBtn); StorageStroke.Color = Theme.Accent; StorageStroke.Thickness = 1

StorageBtn.MouseButton1Click:Connect(function()
    local char = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if char then
        _G.PTHT_RestockPos2D = Vector2.new(char.Position.X, char.Position.Y)
        -- FIX: Tambahkan + 0.5 agar pembulatannya presisi ke angka terdekat
        local gx = math.floor((char.Position.X / TILE_SIZE) + 0.5)
        local gy = math.floor((char.Position.Y / TILE_SIZE) + 0.5)
        
        StorageCoord.Text = "[" .. gx .. ", " .. gy .. "]"
        StorageBtn.Text = "SAVED!"; task.wait(1); StorageBtn.Text = "SAVE"
    end
end)

-- ==========================================
-- [[ 2. SISTEM RADAR & GPS PINTAR (SUPER AKURAT) ]]
-- ==========================================

-- Fungsi Penerjemah Data
local function GetTileName(tile)
    if not tile or tile == 0 or tile == "" then return "" end
    if type(tile) == "string" then return string.lower(tile) end
    if type(tile) == "number" then 
        return string.lower(WorldManager.NumberToStringMap[tile] or tostring(tile))
    end
    if type(tile) == "table" and tile.Name then return string.lower(tile.Name) end
    return string.lower(tostring(tile))
end

local function IsTileEmpty(x, y)
    for layer = 1, 2 do
        local tile = WorldManager.GetTile(x, y, layer)
        if tile and tile ~= 0 then
            local nama = GetTileName(tile)
            if not string.find(nama, "background") and not string.find(nama, "bg") and not string.find(nama, "wall") then
                return false
            end
        end
    end
    return true 
end

local function HasValidFloor(x, y)
    local isFloor = false
    for layer = 0, 2 do
        local tile = WorldManager.GetTile(x, y - 1, layer)
        if tile and tile ~= 0 then
            local nama = GetTileName(tile)
            
            -- Cek Anti-Tumpuk Sapling
            if string.find(nama, "sapling") or string.find(nama, "seed") or 
               string.find(nama, "tree") or string.find(nama, "plant") or 
               string.find(nama, "door") then
                return false 
            end
            
            -- Validasi Lantai Pijakan
            if string.find(nama, "dirt") or string.find(nama, "block") or string.find(nama, "wood") then
                isFloor = true
            end
        end
    end
    return isFloor
end

local function IsPassable(x, y)
    if x < X_MIN or x > X_MAX or y < Y_MIN or y > Y_MAX then return false end
    local tile = WorldManager.GetTile(x, y, MAIN_LAYER)
    if tile and tile ~= 0 then
        local nama = GetTileName(tile)
        if not string.find(nama, "background") and not string.find(nama, "door") and not string.find(nama, "sapling") and not string.find(nama, "seed") and not string.find(nama, "sign") then
            return false 
        end
    end
    return true
end

local function GetPath(startX, startY, endX, endY)
    local head = 1
    local tail = 2
    local queue = {[1] = {x = startX, y = startY, path = {}}}
    local visited = {}
    visited[startX .. "," .. startY] = true
    
    local dirs = {{0,1}, {0,-1}, {1,0}, {-1,0}} 
    local iterations = 0
    
    while head < tail do
        iterations = iterations + 1
        if iterations > 3000 then return nil end 
        
        local curr = queue[head]
        head = head + 1
        
        if curr.x == endX and curr.y == endY then return curr.path end
        
        for _, d in ipairs(dirs) do
            local nx, ny = curr.x + d[1], curr.y + d[2]
            local key = nx .. "," .. ny
            
            if not visited[key] and IsPassable(nx, ny) then
                visited[key] = true
                local newPath = {}
                for _, p in ipairs(curr.path) do table.insert(newPath, p) end
                table.insert(newPath, Vector2.new(nx, ny))
                queue[tail] = {x = nx, y = ny, path = newPath}
                tail = tail + 1
            end
        end
    end
    return nil 
end

local function ScanWorld()
    PlantQueue = {}
    print("Memindai area...")
    for y = Y_MAX, Y_MIN, -1 do
        for x = X_MIN, X_MAX do
            if _G.PTHT_Plant then
                if IsTileEmpty(x, y) and HasValidFloor(x, y) then
                    table.insert(PlantQueue, {X = x, Y = y})
                end
            end
        end
    end
    
    table.sort(PlantQueue, function(a, b)
        if a.Y == b.Y then return a.X < b.X else return a.Y > b.Y end
    end)
    print("Scan Selesai! Target lahan: " .. #PlantQueue)
end

local RunService = game:GetService("RunService")
local TS = game:GetService("TweenService") 

-- ==========================================
-- [[ 3. FUNGSI DRONE MOVEMENT (PERFECT SYNC HITBOX) ]]
-- ==========================================
local function FlyToPath(path)
    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    -- Tunggu sebentar saat baru di-ON-kan agar sisa jalan kaki manualmu divalidasi server
    task.wait(0.2)
    
    root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    root.Anchored = true 
    
    -- Mode Hantu Tembus Tembok
    local noclipLoop
    noclipLoop = RunService.Stepped:Connect(function()
        if char then
            for _, part in pairs(char:GetChildren()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end)
    
    local SPEED = 50 -- Kecepatan luncur bot
    
    for _, node in ipairs(path) do
        if not (_G.PTHT_Plant or _G.PTHT_Harvest) then 
            break -- Tombol di-OFF, hentikan perulangan
        end
        
        local targetX = node.X * TILE_SIZE
        local targetY = node.Y * TILE_SIZE
        local targetPos = Vector3.new(targetX, targetY, root.Position.Z)
        
        local distance = (root.Position - targetPos).Magnitude
        local moveTime = distance / SPEED
        if moveTime < 0.05 then moveTime = 0.05 end 
        
        -- [[ LUNCUR DULU! ]]
        local tweenInfo = TweenInfo.new(moveTime, Enum.EasingStyle.Linear)
        local tween = TS:Create(root, tweenInfo, {CFrame = CFrame.new(targetPos)})
        tween:Play()
        
        -- Tunggu sampai karakter benar-benar sampai di kotak tujuan
        local elapsed = 0
        local canceled = false
        while elapsed < moveTime do
            if not (_G.PTHT_Plant or _G.PTHT_Harvest) then
                tween:Cancel() 
                canceled = true
                break
            end
            task.wait(0.03)
            elapsed = elapsed + 0.03
        end
        
        if canceled then break end
        
        -- [[ BARU LAPOR SERVER! ]]
        -- Karena fisiknya sudah di tujuan, server PASTI akan menerima laporan ini 100% sah!
        if MyRemote then pcall(function() MyRemote:FireServer(Vector2.new(targetX, targetY)) end) end
    end
    
    -- Bersihkan mode hantu dan kembalikan fisik
    if noclipLoop then noclipLoop:Disconnect() end
    if not (_G.PTHT_Plant or _G.PTHT_Harvest) then
        root.Anchored = false 
        for _, part in pairs(char:GetChildren()) do
            if part:IsA("BasePart") then part.CanCollide = true end
        end
        return false 
    end
    
    return true
end

-- ==========================================
-- [[ 4. MESIN EKSEKUSI ]]
-- ==========================================
task.spawn(function()
    while task.wait(0.2) do 
        pcall(function()
            local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if not _G.PTHT_Plant then 
                PlantQueue = {} 
                if root then root.Anchored = false end
                return 
            end

            if #PlantQueue == 0 then
                ScanWorld()
                if #PlantQueue == 0 then task.wait(2) return end
            end

            -- Cek Bibit & Pindah Slot Otomatis
            local Inv = require(RS.Modules.Inventory)
            local hasBibit = false
            
            for slotIndex, item in pairs(Inv.Stacks) do
                if type(item) == "table" and item.Id == _G.PTHT_ItemID then
                    if (item.Amount or 0) > 0 then 
                        hasBibit = true 
                        -- FIX: Selalu perbarui nomor slot ke slot yang masih ada isinya!
                        _G.PTHT_SlotIndex = slotIndex 
                        break 
                    end
                end
            end

-- RESTOCK
            if not hasBibit and _G.PTHT_RestockPos2D and root then
                local rx = math.floor(_G.PTHT_RestockPos2D.X / TILE_SIZE + 0.5)
                local ry = math.floor(_G.PTHT_RestockPos2D.Y / TILE_SIZE + 0.5)
                local cx = math.floor(root.Position.X / TILE_SIZE + 0.5)
                local cy = math.floor(root.Position.Y / TILE_SIZE + 0.5)
                
                local ruteKePeti = GetPath(cx, cy, rx, ry)
                if ruteKePeti then
                    FlyToPath(ruteKePeti)
                    
                    -- JANGAN LEPAS ANCHOR DI SINI! BIARKAN DIA TETAP MELAYANG KAKU!
                    -- Nol-kan juga efek dorongan dari server biar stabil
                    root.AssemblyLinearVelocity = Vector3.new(0, 0, 0) 
                    
                    task.wait(0.5)
                    for i = 1, 8 do FistRemote:FireServer(Vector2.new(rx, ry)); task.wait(0.1) end
                else
                    print("Rute ke tempat Restock Buntu!")
                end
                task.wait(0.5)
                return 
            end

            -- TANAM
            if #PlantQueue > 0 and root then
                local targetGrid = PlantQueue[1] 
                local cx = math.floor(root.Position.X / TILE_SIZE + 0.5)
                local cy = math.floor(root.Position.Y / TILE_SIZE + 0.5)
                
                local rute = GetPath(cx, cy, targetGrid.X, targetGrid.Y)
                
                if rute then
                    local sampai = FlyToPath(rute)
                    if sampai then
                        PlaceRemote:FireServer(Vector2.new(targetGrid.X, targetGrid.Y), _G.PTHT_SlotIndex)
                        table.remove(PlantQueue, 1)
                        task.wait(0.1)
                    end
                else
                    print("Kotak ["..targetGrid.X..","..targetGrid.Y.."] tidak bisa dijangkau. Skip!")
                    table.remove(PlantQueue, 1) 
                end
            end
        end)
    end
end)

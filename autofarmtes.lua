-- [[ ALPHA PROJECT - GOD MODE AUTO FARM & COLLECT (CLEAN VERSION) ]] --

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local LP = Players.LocalPlayer

-- Remotes Dasar
local PlaceRemote = RS:WaitForChild("Remotes"):WaitForChild("PlayerPlaceItem")
local FistRemote = RS:WaitForChild("Remotes"):WaitForChild("PlayerFist")

-- Cari Halaman UI
local ScreenGui = getgenv().AlphaProjectUI
if not ScreenGui then warn("Alpha Project UI tidak ditemukan!") return end
local Page = ScreenGui:FindFirstChild("Auto FarmPage", true)
if not Page then warn("Halaman Auto Farm tidak ditemukan!") return end

for _, child in pairs(Page:GetChildren()) do
    if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then child:Destroy() end
end

-- [[ VARIABEL GLOBAL ]] --
_G.Farm_Active = false
_G.AutoCollect = false
_G.Farm_PlaceDelay = 0.15 
_G.Farm_HitDelay = 0.15   
_G.Farm_HitCount = 3      
_G.Farm_SlotIndex = 1     
_G.Farm_ItemID = nil
_G.Farm_Targets = {}

local Theme = {
    Main = Color3.fromRGB(15, 17, 20),    
    Item = Color3.fromRGB(30, 33, 38),    
    Accent = Color3.fromRGB(0, 255, 220), 
    Text = Color3.fromRGB(240, 245, 255),
    SubText = Color3.fromRGB(160, 165, 175)
}

local SlotInputBox = nil

-- [[ 0. TOMBOL START (GAYA TOGGLE) ]] --
local StartFrame = Instance.new("Frame", Page)
StartFrame.Size = UDim2.new(1, -10, 0, 35)
StartFrame.BackgroundColor3 = Theme.Item -- Samakan dengan warna baris lain
Instance.new("UICorner", StartFrame).CornerRadius = UDim.new(0, 6)
StartFrame.ZIndex = 1

-- Tambahkan Label Teks di sebelah kiri
local StartLbl = Instance.new("TextLabel", StartFrame)
StartLbl.Size = UDim2.new(0.6, 0, 1, 0)
StartLbl.Position = UDim2.new(0, 10, 0, 0)
StartLbl.Text = "Auto Farm" 
StartLbl.TextColor3 = Theme.Text
StartLbl.Font = Enum.Font.Gotham
StartLbl.TextSize = 12
StartLbl.BackgroundTransparency = 1
StartLbl.TextXAlignment = Enum.TextXAlignment.Left

-- Tombol Saklar (Toggle) di sebelah kanan
local StartBtn = Instance.new("TextButton", StartFrame)
StartBtn.Size = UDim2.new(0.45, -10, 0.1, 22)
StartBtn.Position = UDim2.new(0.58, -10, 0.5, -11)
StartBtn.BackgroundColor3 = Theme.Main
StartBtn.Text = "OFF"
StartBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
StartBtn.Font = Enum.Font.GothamBold
StartBtn.TextSize = 10
Instance.new("UICorner", StartBtn).CornerRadius = UDim.new(0, 4)
local StartStroke = Instance.new("UIStroke", StartBtn)
StartStroke.Color = Color3.fromRGB(255, 80, 80)
StartStroke.Thickness = 1

StartBtn.MouseButton1Click:Connect(function()
    _G.Farm_Active = not _G.Farm_Active
    if _G.Farm_Active then
        StartBtn.Text = "ON"
        StartBtn.TextColor3 = Theme.Accent
        StartStroke.Color = Theme.Accent
        TS:Create(StartBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Main}):Play()
    else
        StartBtn.Text = "OFF"
        StartBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
        StartStroke.Color = Color3.fromRGB(255, 80, 80)
        TS:Create(StartBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Main}):Play()
    end
end)

-- [[ 0.5. FITUR SAVE POSITION ]] --
local PosFrame = Instance.new("Frame", Page)
PosFrame.Size = UDim2.new(1, -10, 0, 35)
PosFrame.BackgroundColor3 = Theme.Item
Instance.new("UICorner", PosFrame).CornerRadius = UDim.new(0, 6)
PosFrame.ZIndex = 1

local PosLbl = Instance.new("TextLabel", PosFrame)
PosLbl.Size = UDim2.new(0.4, 0, 1, 0)
PosLbl.Position = UDim2.new(0, 10, 0, 0)
PosLbl.Text = "Save Position"
PosLbl.TextColor3 = Theme.Text
PosLbl.Font = Enum.Font.Gotham
PosLbl.TextSize = 12
PosLbl.BackgroundTransparency = 1
PosLbl.TextXAlignment = Enum.TextXAlignment.Left

local CoordLbl = Instance.new("TextLabel", PosFrame)
CoordLbl.Size = UDim2.new(0.3, 0, 1, 0)
CoordLbl.Position = UDim2.new(0.4, 0, 0, 0)
CoordLbl.Text = "[ NONE ]"
CoordLbl.TextColor3 = Theme.SubText
CoordLbl.Font = Enum.Font.Gotham
CoordLbl.TextSize = 10
CoordLbl.BackgroundTransparency = 1
CoordLbl.TextXAlignment = Enum.TextXAlignment.Center

local SaveBtn = Instance.new("TextButton", PosFrame)
SaveBtn.Size = UDim2.new(0.25, -10, 0.1, 22)
SaveBtn.Position = UDim2.new(0.75, 0, 0.5, -11)
SaveBtn.BackgroundColor3 = Theme.Main
SaveBtn.Text = "SAVE"
SaveBtn.TextColor3 = Theme.Accent
SaveBtn.Font = Enum.Font.GothamBold
SaveBtn.TextSize = 10
Instance.new("UICorner", SaveBtn).CornerRadius = UDim.new(0, 4)
local SaveStroke = Instance.new("UIStroke", SaveBtn)
SaveStroke.Color = Theme.Accent
SaveStroke.Thickness = 1

-- Logika Tombol Save
SaveBtn.MouseButton1Click:Connect(function()
    local Char = LP.Character
    local Root = Char and Char:FindFirstChild("HumanoidRootPart")
    
    if Root then
        -- [!] FIX: Ubah Studs menjadi Grid dengan dibagi 4.5
        local posX = math.floor(Root.Position.X / 4.5 + 0.5)
        local posY = math.floor(Root.Position.Y / 4.5 + 0.5)
        
        -- Menyimpan koordinat ke variabel global untuk digunakan nanti
        _G.SavedPos3D = Root.Position
        _G.SavedPos2D = Vector2.new(Root.Position.X, Root.Position.Y)
        
        -- Update UI
        CoordLbl.Text = "[" .. posX .. ", " .. posY .. "]"
        CoordLbl.TextColor3 = Theme.Accent
        
        -- Animasi Tombol
        SaveBtn.Text = "SAVED!"
        TS:Create(SaveBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Accent, TextColor3 = Theme.Main}):Play()
        task.wait(1)
        SaveBtn.Text = "SAVE"
        TS:Create(SaveBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Main, TextColor3 = Theme.Accent}):Play()
    end
end)

-- [[ 1. SISTEM INVENTORY & DROPDOWN (AUTO-SWITCH READY) ]] --
local function GetInventoryItems()
    local items = {}
    pcall(function()
        local InventoryModule = require(RS.Modules.Inventory)
        local ItemsManager = require(RS.Managers.ItemsManager)

        for slotIndex, itemData in pairs(InventoryModule.Stacks) do
            if type(itemData) == "table" and itemData.Id then
                local itemStringID = itemData.Id 
                local dataInfo = ItemsManager.ItemsData and ItemsManager.ItemsData[itemStringID]
                local realName = (dataInfo and dataInfo.Name) and dataInfo.Name or itemStringID
                
                if type(itemStringID) == "string" and string.sub(itemStringID, -8) == "_sapling" then
                    if not string.match(string.lower(realName), "sapling") then realName = realName .. " Sapling" end
                end
                
                local displayName = realName .. " [" .. tostring(slotIndex) .. "]"
                -- [!] FIX: Simpan Slot DAN ID Barang
                if not items[displayName] then items[displayName] = {Slot = slotIndex, ID = itemStringID} end
            end
        end
    end)
    
    if next(items) == nil then items["Tas Kosong / Loading"] = {Slot = 1, ID = nil} end
    return items
end

local DropRow = Instance.new("Frame", Page)
DropRow.Size = UDim2.new(1, -10, 0, 35); DropRow.BackgroundColor3 = Theme.Item; Instance.new("UICorner", DropRow).CornerRadius = UDim.new(0, 6); DropRow.ZIndex = 50 
local DropLbl = Instance.new("TextLabel", DropRow)
DropLbl.Size = UDim2.new(0.5, 0, 1, 0); DropLbl.Position = UDim2.new(0, 10, 0, 0); DropLbl.Text = "Target Farm Block"; DropLbl.TextColor3 = Theme.Text; DropLbl.Font = Enum.Font.Gotham; DropLbl.TextSize = 12; DropLbl.BackgroundTransparency = 1; DropLbl.TextXAlignment = Enum.TextXAlignment.Left
local DropBtn = Instance.new("TextButton", DropRow)
DropBtn.Size = UDim2.new(0.45, -10, 0.8, 0); DropBtn.Position = UDim2.new(0.55, 0, 0.1, 0); DropBtn.BackgroundColor3 = Theme.Main; DropBtn.Text = "Select Block..."; DropBtn.TextColor3 = Theme.SubText; DropBtn.Font = Enum.Font.Gotham; DropBtn.TextSize = 11; Instance.new("UICorner", DropBtn).CornerRadius = UDim.new(0, 6)
local DropList = Instance.new("ScrollingFrame", DropRow)
DropList.Size = UDim2.new(0.45, -10, 0, 120); DropList.Position = UDim2.new(0.55, 0, 1.1, 0); DropList.BackgroundColor3 = Theme.Main; DropList.Visible = false; DropList.BorderSizePixel = 0; DropList.ScrollBarThickness = 2; DropList.ZIndex = 100; Instance.new("UICorner", DropList).CornerRadius = UDim.new(0, 6)
local DropLayout = Instance.new("UIListLayout", DropList); DropLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; Instance.new("UIPadding", DropList).PaddingTop = UDim.new(0, 5)

local function RefreshDropdown()
    for _, child in pairs(DropList:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
    for displayName, itemData in pairs(GetInventoryItems()) do
        local ItemBtn = Instance.new("TextButton", DropList)
        ItemBtn.Size = UDim2.new(1, 0, 0, 25); ItemBtn.BackgroundTransparency = 1; ItemBtn.Text = displayName; ItemBtn.TextColor3 = Theme.SubText; ItemBtn.Font = Enum.Font.Gotham; ItemBtn.TextSize = 11; ItemBtn.ZIndex = 101
        ItemBtn.MouseButton1Click:Connect(function()
            -- Simpan data ke memori bot
            _G.Farm_SlotIndex = itemData.Slot 
            _G.Farm_ItemID = itemData.ID
            DropBtn.Text = displayName
            if SlotInputBox then SlotInputBox.Text = tostring(itemData.Slot) end
            DropList.Visible = false
        end)
    end
    DropList.CanvasSize = UDim2.new(0, 0, 0, DropLayout.AbsoluteContentSize.Y + 10)
end
DropBtn.MouseButton1Click:Connect(function() if not DropList.Visible then RefreshDropdown() end DropList.Visible = not DropList.Visible end)
RefreshDropdown()

-- [[ 2. SETTINGS MANUAL ]] --
local function CreateSetting(label, defaultVal, globalVar)
    local Frame = Instance.new("Frame", Page)
    Frame.Size = UDim2.new(1, -10, 0, 35); Frame.BackgroundColor3 = Theme.Item; Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6); Frame.ZIndex = 1
    local Lbl = Instance.new("TextLabel", Frame); Lbl.Size = UDim2.new(0.5, 0, 1, 0); Lbl.Position = UDim2.new(0, 10, 0, 0); Lbl.Text = label; Lbl.TextColor3 = Theme.Text; Lbl.Font = Enum.Font.Gotham; Lbl.TextSize = 12; Lbl.BackgroundTransparency = 1; Lbl.TextXAlignment = Enum.TextXAlignment.Left
    local Box = Instance.new("TextBox", Frame); Box.Size = UDim2.new(0.45, -10, 0.8, 0); Box.Position = UDim2.new(0.55, 0, 0.1, 0); Box.BackgroundColor3 = Theme.Main; Box.TextColor3 = Theme.Accent; Box.Font = Enum.Font.GothamBold; Box.TextSize = 12; Box.Text = tostring(defaultVal); Box.ZIndex = 1; Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 6)
    
    Box.FocusLost:Connect(function() 
        _G[globalVar] = tonumber(Box.Text) or defaultVal 
    end)
    return Box 
end

SlotInputBox = CreateSetting("Manual Slot BP:", _G.Farm_SlotIndex, "Farm_SlotIndex") 
CreateSetting("Place Delay (Second):", _G.Farm_PlaceDelay, "Farm_PlaceDelay")
CreateSetting("Hit Delay (Second):", _G.Farm_HitDelay, "Farm_HitDelay")
CreateSetting("Hit Count:", _G.Farm_HitCount, "Farm_HitCount")

-- [[ 3. AUTO COLLECT TOGGLE ]] --
local CollectFrame = Instance.new("Frame", Page)
CollectFrame.Size = UDim2.new(1, -10, 0, 35); CollectFrame.BackgroundColor3 = Theme.Item; Instance.new("UICorner", CollectFrame).CornerRadius = UDim.new(0, 6); CollectFrame.ZIndex = 1
local CollectLbl = Instance.new("TextLabel", CollectFrame); CollectLbl.Size = UDim2.new(0.6, 0, 1, 0); CollectLbl.Position = UDim2.new(0, 10, 0, 0); CollectLbl.Text = "Auto Collect"; CollectLbl.TextColor3 = Theme.Text; CollectLbl.Font = Enum.Font.Gotham; CollectLbl.TextSize = 12; CollectLbl.BackgroundTransparency = 1; CollectLbl.TextXAlignment = Enum.TextXAlignment.Left
local CollectBtn = Instance.new("TextButton", CollectFrame); CollectBtn.Size = UDim2.new(0.45, -10, 0.1, 22); CollectBtn.Position = UDim2.new(0.58, -10, 0.5, -11); CollectBtn.BackgroundColor3 = Theme.Main; CollectBtn.Text = "OFF"; CollectBtn.TextColor3 = Color3.fromRGB(255, 80, 80); CollectBtn.Font = Enum.Font.GothamBold; CollectBtn.TextSize = 10; Instance.new("UICorner", CollectBtn).CornerRadius = UDim.new(0, 4); local CollectStroke = Instance.new("UIStroke", CollectBtn); CollectStroke.Color = Color3.fromRGB(255, 80, 80); CollectStroke.Thickness = 1

CollectBtn.MouseButton1Click:Connect(function()
    _G.AutoCollect = not _G.AutoCollect
    if _G.AutoCollect then
        CollectBtn.Text = "ON"; CollectBtn.TextColor3 = Theme.Accent; CollectStroke.Color = Theme.Accent
        TS:Create(CollectBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Main}):Play()
    else
        CollectBtn.Text = "OFF"; CollectBtn.TextColor3 = Color3.fromRGB(255, 80, 80); CollectStroke.Color = Color3.fromRGB(255, 80, 80)
        TS:Create(CollectBtn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Main}):Play()
    end
end)

-- [[ 4. GRID SELECTOR ]] --
local GridBox = Instance.new("Frame", Page)
GridBox.Size = UDim2.new(1, -10, 0, 180); GridBox.BackgroundColor3 = Theme.Item; Instance.new("UICorner", GridBox).CornerRadius = UDim.new(0, 6); GridBox.ZIndex = 1
local GInner = Instance.new("Frame", GridBox)
GInner.Size = UDim2.new(0, 160, 0, 160); GInner.Position = UDim2.new(0.5, -80, 0.5, -80); GInner.BackgroundTransparency = 1
local GLat = Instance.new("UIGridLayout", GInner); GLat.CellSize = UDim2.new(0, 28, 0, 28); GLat.CellPadding = UDim2.new(0, 4, 0, 4)

for y = 2, -2, -1 do
    for x = -2, 2 do
        local b = Instance.new("TextButton", GInner); b.Text = (x==0 and y==0) and "ME" or ""
        b.BackgroundColor3 = (x==0 and y==0) and Theme.Accent or Theme.Main; b.TextColor3 = Theme.Main; b.Font = Enum.Font.GothamBold; b.TextSize = 10; Instance.new("UICorner", b)
        if x ~= 0 or y ~= 0 then
            local act = false
            b.MouseButton1Click:Connect(function()
                act = not act
                if act then table.insert(_G.Farm_Targets, {X=x, Y=y}); TS:Create(b, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Accent}):Play()
                else for i,v in ipairs(_G.Farm_Targets) do if v.X==x and v.Y==y then table.remove(_G.Farm_Targets, i) break end end; TS:Create(b, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Main}):Play() end
            end)
        end
    end
end

-- [[ ENGINE GOD MODE: AUTO COLLECT & AUTO FARM ]] --

local function GetCurrentGrid()
    local Char = LP.Character
    local Root = Char and Char:FindFirstChild("HumanoidRootPart")
    return Root and Vector2.new(math.floor(Root.Position.X / 4.5 + 0.5), math.floor(Root.Position.Y / 4.5 + 0.5)) or Vector2.new(0,0)
end

-- [FITUR BARU] Fungsi untuk memalsukan langkah kecil agar tidak terdeteksi teleport
local function SmoothMove(remote, startPos, endPos)
    local dist = (endPos - startPos).Magnitude
    
    -- [1] ATUR UKURAN LANGKAH DI SINI (Bawaan awal: 1.5)
    -- Semakin BESAR angkanya = Semakin SEDIKIT langkahnya = SEMAKIN CEPAT SAMPAI!
    -- Coba gunakan angka 4.0 atau 5.0 untuk lari kilat.
    local steps = math.ceil(dist / 3.0) 
    
    if steps < 1 then steps = 1 end
    
    for i = 1, steps do
        local currentPos = startPos:Lerp(endPos, i / steps)
        pcall(function() remote:FireServer(currentPos) end)
        
        -- [2] ATUR JEDA PER LANGKAH DI SINI (Bawaan awal: 0.04)
        -- Semakin KECIL angkanya = Semakin CEPAT pergerakannya.
        -- Gunakan 0.01 agar nyaris tidak terasa ada jeda.
        task.wait(0.01) 
    end
end

-- Fungsi Pintar untuk Mengambil Barang (Sapu Bersih Target Grid & Pulang)
local function StealthCollectDrops()
    local Drops = workspace:FindFirstChild("Drops")
    if not Drops or #Drops:GetChildren() == 0 then return end

    local PacketFolder = RS:WaitForChild("Remotes"):FindFirstChild("PlayerMovementPackets")
    local MyRemote = PacketFolder and PacketFolder:FindFirstChild(LP.Name)
    if not MyRemote then return end

    local MyHitbox = workspace:FindFirstChild("Hitbox") and workspace.Hitbox:FindFirstChild(LP.Name)
    if not MyHitbox then return end
    
    -- [!] WAJIB: Kalau belum klik Save Position, bot tidak akan bergerak
    if not _G.SavedPos3D or not _G.SavedPos2D then return end

    local hasCollected = false
    -- Melacak posisi 'roh' bot saat ini untuk berjalan (dimulai dari posisi Hitbox)
    local currentPos = Vector2.new(MyHitbox.Position.X, MyHitbox.Position.Y)
    
    -- 1. BANGUN RADAR GRID TARGET (Berdasarkan titik Save Position)
    local cp = Vector2.new(math.floor(_G.SavedPos3D.X / 4.5 + 0.5), math.floor(_G.SavedPos3D.Y / 4.5 + 0.5))
    local validGrids = {}
    for _, o in ipairs(_G.Farm_Targets) do
        local tx, ty = math.floor(cp.X + o.X), math.floor(cp.Y + o.Y)
        validGrids[tx .. "," .. ty] = true 
    end

    for _, item in ipairs(Drops:GetChildren()) do
        if not _G.Farm_Active or not _G.AutoCollect then break end
        
        local targetPart = nil
        if item:IsA("Model") then targetPart = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")
        elseif item:IsA("BasePart") then targetPart = item
        else targetPart = item:FindFirstChildWhichIsA("BasePart") end
        
        if targetPart then
            local itemPos3D = targetPart.Position
            local itemPos2D = Vector2.new(itemPos3D.X, itemPos3D.Y)
            
            -- Konversi posisi barang ke bahasa Grid
            local itemX = math.floor(itemPos3D.X / 4.5 + 0.5)
            local itemY = math.floor(itemPos3D.Y / 4.5 + 0.5)
            
            -- 2. HANYA SEDOT JIKA BARANG JATUH TEPAT DI GRID YANG DITANDAI DI UI
            if validGrids[itemX .. "," .. itemY] then
                hasCollected = true
                
                -- Berjalan perlahan dari titik saat ini ke barang (A -> B -> C)
                SmoothMove(MyRemote, currentPos, itemPos2D)
                
                if MyHitbox and firetouchinterest then
                    pcall(function()
                        firetouchinterest(MyHitbox, targetPart, 0)
                        firetouchinterest(MyHitbox, targetPart, 1)
                    end)
                end
                task.wait(0.1) -- Biarkan barang masuk tas
                
                -- Update posisi roh bot sekarang berada di titik barang tersebut
                currentPos = itemPos2D
            end
        end
    end
    
    -- 3. SETELAH AREA TARGET BERSIH, JALAN PULANG KE SAVE POSITION
    if hasCollected then
        SmoothMove(MyRemote, currentPos, _G.SavedPos2D)
        
        -- Lapor ke server bahwa kita sudah tiba dengan selamat di rumah
        pcall(function() MyRemote:FireServer(_G.SavedPos2D) end)
        task.wait(0.1)
    end
end

-- [[ MESIN AUTO-SWITCH STACK (SMART SCAN) ]] --
local function CheckAndSwitchSlot()
    if not _G.Farm_ItemID then return end

    pcall(function()
        local Inv = require(RS.Modules.Inventory)
        local currentSlot = _G.Farm_SlotIndex
        
        -- Cek slot saat ini (Mendukung key number maupun string)
        local currentData = Inv.Stacks[currentSlot] or Inv.Stacks[tostring(currentSlot)]
        
        if currentData and currentData.Id == _G.Farm_ItemID and (currentData.Amount and currentData.Amount > 0) then
            return -- Aman, blok masih ada
        end
        
        -- Kalau habis, scan seluruh tas dan kumpulkan slot yang punya item ini
        local validSlots = {}
        for slotIndex, data in pairs(Inv.Stacks) do
            if type(data) == "table" and data.Id == _G.Farm_ItemID and (data.Amount and data.Amount > 0) then
                table.insert(validSlots, tonumber(slotIndex))
            end
        end
        
        -- Urutkan angka slot dari yang terkecil ke terbesar
        if #validSlots > 0 then
            table.sort(validSlots)
            local nextSlot = validSlots[1] -- Selalu ambil yang paling kiri
            
            _G.Farm_SlotIndex = nextSlot
            if SlotInputBox then SlotInputBox.Text = tostring(nextSlot) end
        end
    end)
end

-- LOOP UTAMA AUTO FARM
task.spawn(function()
    while true do
        if _G.Farm_Active and #_G.Farm_Targets > 0 then
            
            if _G.AutoCollect then StealthCollectDrops() end
            
            -- [!] PENTING: Target penanaman grid sekarang memakai Save Position!
            local cp
            if _G.SavedPos3D then
                cp = Vector2.new(math.floor(_G.SavedPos3D.X / 4.5 + 0.5), math.floor(_G.SavedPos3D.Y / 4.5 + 0.5))
            else
                -- Fallback kalau lupa nge-save
                cp = GetCurrentGrid()
            end
            -- [!] PANGGIL OTAK SMART SCAN DI SINI:
            CheckAndSwitchSlot()
            
            for _, o in ipairs(_G.Farm_Targets) do
                if not _G.Farm_Active then break end
                local tx, ty = math.floor(cp.X + o.X), math.floor(cp.Y + o.Y)
                if _G.Farm_SlotIndex ~= nil then pcall(function() PlaceRemote:FireServer(Vector2.new(tx, ty), _G.Farm_SlotIndex) end) end
                task.wait(_G.Farm_PlaceDelay)
            end
            
            task.wait(0.1) 
            
            for i = 1, _G.Farm_HitCount do
                if not _G.Farm_Active then break end
                for _, o in ipairs(_G.Farm_Targets) do
                    if not _G.Farm_Active then break end
                    local tx, ty = math.floor(cp.X + o.X), math.floor(cp.Y + o.Y)
                    pcall(function() FistRemote:FireServer(Vector2.new(tx, ty)) end)
                    task.wait(_G.Farm_HitDelay)
                end
            end
            
            if _G.AutoCollect then StealthCollectDrops() end
        end
        task.wait(0.1)
    end
end)

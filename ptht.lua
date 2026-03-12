-- [[ ALPHA PROJECT - AUTO PTHT (SMART PLANT & HARVEST) ]] --

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
_G.PTHT_Harvest = false
_G.PTHT_SlotIndex = nil
_G.PTHT_ItemID = nil
_G.PTHT_RestockPos2D = nil
local TILE_SIZE = 4.5 
local SCAN_RADIUS = 3 -- Jarak sensor bot mencari tanah kosong/siap panen

-- ==========================================
-- [[ 1. UI DROPDOWN (PILIH SAPLING) ]]
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
                
                -- FILTER: Hanya tampilkan item yang berhubungan dengan bibit/seed/sapling
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
DropRow.Size = UDim2.new(1, -10, 0, 35); DropRow.BackgroundColor3 = Theme.Item; Instance.new("UICorner", DropRow).CornerRadius = UDim.new(0, 6); DropRow.ZIndex = 50 
local DropLbl = Instance.new("TextLabel", DropRow); DropLbl.Size = UDim2.new(0.5, 0, 1, 0); DropLbl.Position = UDim2.new(0, 10, 0, 0); DropLbl.Text = "Select Sapling"; DropLbl.TextColor3 = Theme.Text; DropLbl.Font = Enum.Font.Gotham; DropLbl.TextSize = 12; DropLbl.BackgroundTransparency = 1; DropLbl.TextXAlignment = Enum.TextXAlignment.Left
local DropBtn = Instance.new("TextButton", DropRow); DropBtn.Size = UDim2.new(0.45, -10, 0.8, 0); DropBtn.Position = UDim2.new(0.55, 0, 0.1, 0); DropBtn.BackgroundColor3 = Theme.Main; DropBtn.Text = "Pilih Bibit..."; DropBtn.TextColor3 = Theme.SubText; DropBtn.Font = Enum.Font.Gotham; DropBtn.TextSize = 11; Instance.new("UICorner", DropBtn).CornerRadius = UDim.new(0, 6)
local DropList = Instance.new("ScrollingFrame", DropRow); DropList.Size = UDim2.new(0.45, -10, 0, 100); DropList.Position = UDim2.new(0.55, 0, 1.1, 0); DropList.BackgroundColor3 = Theme.Main; DropList.Visible = false; DropList.BorderSizePixel = 0; DropList.ScrollBarThickness = 2; DropList.ZIndex = 100; Instance.new("UICorner", DropList).CornerRadius = UDim.new(0, 6)
local DropLayout = Instance.new("UIListLayout", DropList); DropLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; Instance.new("UIPadding", DropList).PaddingTop = UDim.new(0, 5)

local function RefreshPTHTDropdown()
    for _, child in pairs(DropList:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
    for displayName, itemData in pairs(GetInventorySaplings()) do
        local ItemBtn = Instance.new("TextButton", DropList)
        ItemBtn.Size = UDim2.new(1, 0, 0, 25); ItemBtn.BackgroundTransparency = 1; ItemBtn.Text = displayName; ItemBtn.TextColor3 = Theme.SubText; ItemBtn.Font = Enum.Font.Gotham; ItemBtn.TextSize = 11; ItemBtn.ZIndex = 101
        ItemBtn.MouseButton1Click:Connect(function()
            _G.PTHT_SlotIndex = itemData.Slot 
            _G.PTHT_ItemID = itemData.ID
            DropBtn.Text = displayName
            DropList.Visible = false
        end)
    end
    DropList.CanvasSize = UDim2.new(0, 0, 0, DropLayout.AbsoluteContentSize.Y + 10)
end
DropBtn.MouseButton1Click:Connect(function() if not DropList.Visible then RefreshPTHTDropdown() end DropList.Visible = not DropList.Visible end)
RefreshPTHTDropdown()

-- ==========================================
-- [[ 2. TOMBOL TOGGLE ON/OFF ]]
-- ==========================================
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
            TS:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Main}):Play()
        else
            Btn.Text = "OFF"; Btn.TextColor3 = Color3.fromRGB(255, 80, 80); Stroke.Color = Color3.fromRGB(255, 80, 80)
            TS:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Main}):Play()
        end
    end)
end

CreateToggle("Smart Auto Plant", "PTHT_Plant")
CreateToggle("Smart Auto Harvest", "PTHT_Harvest")

-- ==========================================
-- [[ 2.5. UI SAVE STORAGE POSITION ]]
-- ==========================================
local StorageFrame = Instance.new("Frame", Page)
StorageFrame.Size = UDim2.new(1, -10, 0, 35)
StorageFrame.BackgroundColor3 = Theme.Item
Instance.new("UICorner", StorageFrame).CornerRadius = UDim.new(0, 6)

local StorageLbl = Instance.new("TextLabel", StorageFrame)
StorageLbl.Size = UDim2.new(0.4, 0, 1, 0)
StorageLbl.Position = UDim2.new(0, 10, 0, 0)
StorageLbl.Text = "Save Storage Pos"
StorageLbl.TextColor3 = Theme.Text
StorageLbl.Font = Enum.Font.Gotham
StorageLbl.TextSize = 12
StorageLbl.BackgroundTransparency = 1
StorageLbl.TextXAlignment = Enum.TextXAlignment.Left

local StorageCoord = Instance.new("TextLabel", StorageFrame)
StorageCoord.Size = UDim2.new(0.3, 0, 1, 0)
StorageCoord.Position = UDim2.new(0.4, 0, 0, 0)
StorageCoord.Text = "[ NONE ]"
StorageCoord.TextColor3 = Theme.SubText
StorageCoord.Font = Enum.Font.Gotham
StorageCoord.TextSize = 10
StorageCoord.BackgroundTransparency = 1
StorageCoord.TextXAlignment = Enum.TextXAlignment.Center

local StorageBtn = Instance.new("TextButton", StorageFrame)
StorageBtn.Size = UDim2.new(0.25, -10, 0.1, 22)
StorageBtn.Position = UDim2.new(0.75, 0, 0.5, -11)
StorageBtn.BackgroundColor3 = Theme.Main
StorageBtn.Text = "SAVE"
StorageBtn.TextColor3 = Theme.Accent
StorageBtn.Font = Enum.Font.GothamBold
StorageBtn.TextSize = 10
Instance.new("UICorner", StorageBtn).CornerRadius = UDim.new(0, 4)
local StorageStroke = Instance.new("UIStroke", StorageBtn)
StorageStroke.Color = Theme.Accent
StorageStroke.Thickness = 1
-- Update UI Tombol Save
StorageLbl.Text = "Set Restock Pos" -- Ganti labelnya
StorageBtn.MouseButton1Click:Connect(function()
    local currentPos = GetPlayerPos2D()
    if currentPos then
        _G.PTHT_RestockPos2D = currentPos
        local posX = math.floor(currentPos.X / 4.5 + 0.5)
        local posY = math.floor(currentPos.Y / 4.5 + 0.5)
        StorageCoord.Text = "[" .. posX .. ", " .. posY .. "]"
        StorageBtn.Text = "RESTOCK OK!"
        task.wait(1)
        StorageBtn.Text = "SAVE"
    end
end)

-- ==========================================
-- [[ 2.6. UI INPUT MINIMUM DROP ]]
-- ==========================================
_G.PTHT_MinDropAmount = 50 -- Bawaan awal: buang jika sudah terkumpul 50

local MinDropFrame = Instance.new("Frame", Page)
MinDropFrame.Size = UDim2.new(1, -10, 0, 35)
MinDropFrame.BackgroundColor3 = Theme.Item
Instance.new("UICorner", MinDropFrame).CornerRadius = UDim.new(0, 6)

local MinDropLbl = Instance.new("TextLabel", MinDropFrame)
MinDropLbl.Size = UDim2.new(0.6, 0, 1, 0)
MinDropLbl.Position = UDim2.new(0, 10, 0, 0)
MinDropLbl.Text = "Min Drop Amount:"
MinDropLbl.TextColor3 = Theme.Text
MinDropLbl.Font = Enum.Font.Gotham
MinDropLbl.TextSize = 12
MinDropLbl.BackgroundTransparency = 1
MinDropLbl.TextXAlignment = Enum.TextXAlignment.Left

local MinDropBox = Instance.new("TextBox", MinDropFrame)
MinDropBox.Size = UDim2.new(0.35, -10, 0.8, 0)
MinDropBox.Position = UDim2.new(0.65, 0, 0.1, 0)
MinDropBox.BackgroundColor3 = Theme.Main
MinDropBox.TextColor3 = Theme.Accent
MinDropBox.Font = Enum.Font.GothamBold
MinDropBox.TextSize = 12
MinDropBox.Text = tostring(_G.PTHT_MinDropAmount)
Instance.new("UICorner", MinDropBox).CornerRadius = UDim.new(0, 6)

-- Simpan angka saat selesai diketik
MinDropBox.FocusLost:Connect(function()
    local inputAngka = tonumber(MinDropBox.Text)
    if inputAngka and inputAngka > 0 then
        _G.PTHT_MinDropAmount = inputAngka
    else
        -- Kalau salah ketik huruf, kembalikan ke angka sebelumnya
        MinDropBox.Text = tostring(_G.PTHT_MinDropAmount)
    end
end)

-- ==========================================
-- [[ 3. MESIN LOGIKA (SMART ENGINE PTHT) ]]
-- ==========================================
local WorldManager = require(RS.Managers.WorldManager)

-- Fungsi Pindah Mulus
local function SmoothMove(remote, startPos2D, endPos2D)
    if not remote then return end
    local dist = (endPos2D - startPos2D).Magnitude
    local steps = math.ceil(dist / 3.0) 
    if steps < 1 then steps = 1 end
    
    for i = 1, steps do
        local currentPos = startPos2D:Lerp(endPos2D, i / steps)
        pcall(function() remote:FireServer(currentPos) end)
        task.wait(0.02) 
    end
end

local function GetPlayerPos2D()
    local Hitbox = workspace:FindFirstChild("Hitbox") and workspace.Hitbox:FindFirstChild(LP.Name)
    if Hitbox then return Vector2.new(Hitbox.Position.X, Hitbox.Position.Y) end
    if LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
        return Vector2.new(LP.Character.HumanoidRootPart.Position.X, LP.Character.HumanoidRootPart.Position.Y)
    end
    return nil
end

local PlayerDrop = RS:WaitForChild("Remotes"):WaitForChild("PlayerDrop")
local UIPromptEvent = RS:WaitForChild("Managers"):WaitForChild("UIManager"):WaitForChild("UIPromptEvent")

-- [[ RE-CHECK LOGIKA DALAM TASK.SPAWN ]] --
-- [[ 3. MESIN LOGIKA (SMART POSITION + AUTO STORAGE) ]] --
task.spawn(function()
    while task.wait(0.2) do 
        local success, err = pcall(function()
            if (_G.PTHT_Plant or _G.PTHT_Harvest) then
                local currentPos2D = GetPlayerPos2D()
                if not currentPos2D then return end

                -- [[ 1. CEK STOK BIBIT (INVENTORY CHECK) ]]
                local Inv = require(RS.Modules.Inventory)
                local hasBibit = false
                local bibitID = _G.PTHT_ItemID -- ID bibit dari dropdown

                -- Cek apakah bibit yang dipilih masih ada di tas
                for _, item in pairs(Inv.Stacks) do
                    if type(item) == "table" and item.Id == bibitID then
                        if (item.Amount or 0) > 0 then
                            hasBibit = true
                            break
                        end
                    end
                end

                -- [[ 2. LOGIKA AMBIL BIBIT (RESTOCK) ]]
                -- Jika bibit HABIS dan kamu sudah SAVE posisi pengambilan
                if not hasBibit and _G.PTHT_StoragePos2D and _G.PTHT_Plant then
                    -- Simpan posisi kebun terakhir biar bot bisa balik lagi
                    local lastFarmPos = currentPos2D 
                    
                    -- Jalan ke tempat ambil bibit (Restock Pos)
                    SmoothMove(MyRemote, currentPos2D, _G.PTHT_StoragePos2D)
                    currentPos2D = _G.PTHT_StoragePos2D
                    task.wait(0.3)
                    
                    -- Ambil barang (Memukul/Fist ke koordinat tersebut)
                    -- Kita pukul 5 kali untuk memastikan item keluar dan terambil
                    local pickX = math.floor(currentPos2D.X / TILE_SIZE + 0.5)
                    local pickY = math.floor(currentPos2D.Y / TILE_SIZE + 0.5)
                    
                    for i = 1, 5 do
                        pcall(function() FistRemote:FireServer(Vector2.new(pickX, pickY)) end)
                        task.wait(0.2)
                    end
                    
                    -- Balik lagi ke posisi kebun terakhir
                    SmoothMove(MyRemote, currentPos2D, lastFarmPos)
                    currentPos2D = lastFarmPos
                    return -- Keluar loop sebentar biar inventory refresh
                end

                -- [[ 3. LOGIKA SCAN SEKITAR (PLANT & HARVEST) ]]
                local charX = math.floor(currentPos2D.X / TILE_SIZE + 0.5)
                local charY = math.floor(currentPos2D.Y / TILE_SIZE + 0.5)

                for x = charX - 1, charX + 1 do
                    for y = charY - 1, charY + 1 do
                        if not (_G.PTHT_Harvest or _G.PTHT_Plant) then break end
                        
                        local blokSekarang = WorldManager.GetTile(x, y, 2)
                        local blokBawah = WorldManager.GetTile(x, y - 1, 2)
                        local targetGridPos = Vector2.new(x * TILE_SIZE, y * TILE_SIZE)

                        -- AUTO PLANT (Hanya jalan kalau ada bibit)
                        if _G.PTHT_Plant and _G.PTHT_SlotIndex and hasBibit then
                            if blokSekarang == nil and blokBawah ~= nil then
                                if (targetGridPos - currentPos2D).Magnitude > 1.5 then
                                    SmoothMove(MyRemote, currentPos2D, targetGridPos)
                                    currentPos2D = targetGridPos
                                end
                                PlaceRemote:FireServer(Vector2.new(x, y), _G.PTHT_SlotIndex)
                                task.wait(0.1)
                            end
                        end

                        -- AUTO HARVEST
                        if _G.PTHT_Harvest and blokSekarang then
                            local namaBlok = WorldManager.NumberToStringMap[blokSekarang]
                            if namaBlok and not string.match(string.lower(namaBlok), "_sapling") then
                                if (targetGridPos - currentPos2D).Magnitude > 1.5 then
                                    SmoothMove(MyRemote, currentPos2D, targetGridPos)
                                    currentPos2D = targetGridPos
                                end
                                for i = 1, 2 do
                                    FistRemote:FireServer(Vector2.new(x, y))
                                    task.wait(0.05)
                                end
                            end
                        end
                    end
                end
            end
        end)
        if not success then warn("Bot Logic Error: " .. tostring(err)) end
    end
end)

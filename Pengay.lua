local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")

local lp = Players.LocalPlayer
local pgui = lp:WaitForChild("PlayerGui")

local fh = pgui:FindFirstChild("FishingHud") or pgui:FindFirstChild("FishHud")
if not fh then
    fh = pgui:WaitForChild("FishingHud", 3) or pgui:WaitForChild("FishHud", 3)
end

local cluster = fh and (fh:FindFirstChild("Root") and fh.Root:FindFirstChild("Cluster") or fh:FindFirstChild("Interact") and fh.Interact:FindFirstChild("Cluster") or fh:FindFirstChild("Cluster", true))
local act = cluster and (cluster:FindFirstChild("Action") or cluster:FindFirstChildWhichIsA("GuiButton")) or (fh and fh:FindFirstChild("Action", true))

local A = nil
local invReq = nil
local shopReq = nil
local fishEvent = nil

pcall(function()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then
        if remotes:FindFirstChild("Fishing") then
            A = remotes.Fishing:FindFirstChild("Action")
            fishEvent = remotes.Fishing:FindFirstChild("Event")
        end
        if remotes:FindFirstChild("Inventory") then
            invReq = remotes.Inventory:FindFirstChild("Request")
        end
        if remotes:FindFirstChild("FishShop") then
            shopReq = remotes.FishShop:FindFirstChild("Request")
        end
    end
    if not A or not invReq or not shopReq or not fishEvent then
        local shared = ReplicatedStorage:FindFirstChild("Shared")
        if shared and shared:FindFirstChild("Remote") then
            A = A or shared.Remote:FindFirstChild("Action")
            fishEvent = fishEvent or shared.Remote:FindFirstChild("Event")
            invReq = invReq or shared.Remote:FindFirstChild("InventoryRequest")
            shopReq = shopReq or shared.Remote:FindFirstChild("ShopRequest")
        end
    end
end)

local fishConfig = nil
pcall(function()
    fishConfig = require(ReplicatedStorage.Shared.Config.FishingConfig)
end)
local fishMap = {}
if fishConfig and fishConfig.Fish then
    for _, f in ipairs(fishConfig.Fish) do
        if f.Key then
            fishMap[f.Key] = f
        end
    end
end

local reel = fh and fh:FindFirstChild("Reel", true)
local water = reel and reel:FindFirstChild("Water", true)
local fish = water and water:FindFirstChild("Fish", true)
local zone = water and water:FindFirstChild("Zone", true)

local origZoneSize = zone and zone.Size or UDim2.new(0.3, 0, 1, 0)
local origZonePos = zone and zone.Position or UDim2.new(0, 0, 0, 0)
local origZoneTrans = zone and zone.BackgroundTransparency or 0.5

local function killGameAuto()
    pcall(function()
        if cluster and cluster:FindFirstChild("Auto") then
            cluster.Auto:Destroy()
        end
    end)
    pcall(function()
        if fh then
            local a = fh:FindFirstChild("Auto", true)
            if a then a:Destroy() end
        end
    end)
    if A then
        pcall(function()
            A:FireServer("Auto", false)
        end)
    end
end
killGameAuto()

_G.__comboFishGen = (_G.__comboFishGen or 0) + 1
local myGen = _G.__comboFishGen

if _G.__comboFishClean then
    pcall(_G.__comboFishClean)
end
_G.__comboFishLoop = true

local cleanups = {}
local function registerCleanup(fn)
    table.insert(cleanups, fn)
end

_G.__comboFishClean = function()
    _G.__comboFishLoop = false
    for _, fn in ipairs(cleanups) do
        pcall(fn)
    end
    cleanups = {}
    pcall(function()
        if zone then
            zone.Size = origZoneSize
            zone.Position = origZonePos
            zone.BackgroundTransparency = origZoneTrans
        end
    end)
    if _G.__fluentUI then
        pcall(function() _G.__fluentUI:Destroy() end)
        _G.__fluentUI = nil
    end
end

local Settings = {
    AutoFish = true,
    Profile = "Rage",
    CastPower = 0.88,
    ReelDuration = 0.70,
    AutoHook = true,
    SkipSpectacle = true,
    AutoSell = true,
    SellThreshold = 450,
    AntiAFK = true,
    LowRamClean = true,
    Disable3D = false,
    SavedSpot = CFrame.new(-145.643, 14.271, -321.447, -0.941015899, 9.02651287e-09, 0.338362306, 1.01576303e-08, 1, 1.57221602e-09, -0.338362306, 4.91643926e-09, -0.941015899)
}

local CONFIG_NAME = "Sukjai_AutoFish_Config.json"

local function saveConfig()
    pcall(function()
        if writefile then
            local data = {
                Profile = tostring(Settings.Profile),
                AutoFish = Settings.AutoFish == true,
                AutoHook = Settings.AutoHook == true,
                SkipSpectacle = Settings.SkipSpectacle == true,
                ReelDuration = tonumber(Settings.ReelDuration) or 0.70,
                CastPower = tonumber(Settings.CastPower) or 0.90,
                AutoSell = Settings.AutoSell == true,
                SellThreshold = tonumber(Settings.SellThreshold) or 450,
                LowRamClean = Settings.LowRamClean == true,
                Disable3D = Settings.Disable3D == true
            }
            if Settings.SavedSpot then
                local cf = Settings.SavedSpot
                data.SavedSpot = {cf:GetComponents()}
            end
            writefile(CONFIG_NAME, HttpService:JSONEncode(data))
        end
    end)
end

local function loadConfig()
    pcall(function()
        if isfile and readfile and isfile(CONFIG_NAME) then
            local raw = readfile(CONFIG_NAME)
            local data = HttpService:JSONDecode(raw)
            if type(data) == "table" then
                if data.Profile ~= nil then Settings.Profile = tostring(data.Profile) end
                if data.AutoFish ~= nil then Settings.AutoFish = data.AutoFish == true end
                if data.AutoHook ~= nil then Settings.AutoHook = data.AutoHook == true end
                if data.SkipSpectacle ~= nil then Settings.SkipSpectacle = data.SkipSpectacle == true end
                if data.ReelDuration ~= nil then
                    local d = tonumber(data.ReelDuration) or 0.70
                    if d < 0.35 then d = 0.70 end
                    Settings.ReelDuration = d
                end
                if data.CastPower ~= nil then Settings.CastPower = tonumber(data.CastPower) or 0.90 end
                if data.AutoSell ~= nil then Settings.AutoSell = data.AutoSell == true end
                if data.SellThreshold ~= nil then Settings.SellThreshold = tonumber(data.SellThreshold) or 450 end
                if data.LowRamClean ~= nil then Settings.LowRamClean = data.LowRamClean == true end
                if data.Disable3D ~= nil then Settings.Disable3D = data.Disable3D == true end
                if type(data.SavedSpot) == "table" and #data.SavedSpot >= 12 then
                    Settings.SavedSpot = CFrame.new(unpack(data.SavedSpot))
                end
            end
        end
    end)
end

loadConfig()
Settings.AutoFish = true

local function dismissSpectacle()
    pcall(function()
        local p = pgui:FindFirstChild("Spectacle")
        if p and p:FindFirstChild("CatchCard") and p.CatchCard.Visible then
            local actBtn = p.CatchCard:FindFirstChild("Actions") and p.CatchCard.Actions:FindFirstChild("Dismiss")
            if actBtn then
                local pos = actBtn.AbsolutePosition + actBtn.AbsoluteSize / 2
                VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
                task.wait(0.01)
                VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
            end
            p.CatchCard.Visible = false
        end
    end)
    pcall(function()
        if fh then
            local catchCard = fh:FindFirstChild("CatchCard", true)
            if catchCard then catchCard.Visible = false end
            local toast = fh:FindFirstChild("Toast", true)
            if toast then toast.Visible = false end
        end
    end)
end

local actDownFunc = nil
local actUpFunc = nil
local isHooking = false
local capConn = nil
local lastClickState = nil

local function isBiteCaption(t)
    if not t or type(t) ~= "string" then return false end
    if t:find("ปล่อย") or t:find("เพอร์เฟกต์") or t:find("เหวี่ยง") or t:find("ม้วนสาย") then
        return false
    end
    return t:find("กด") ~= nil or t:find("ดึง") ~= nil or t:find("ฮุก") ~= nil or t:find("Press") ~= nil or t:find("Bite") ~= nil or t == "!" or t:find("!") ~= nil
end

local function hookCaption()
    if capConn then
        pcall(function() capConn:Disconnect() end)
        capConn = nil
    end
    if not act and fh then
        local c = fh:FindFirstChild("Root") and fh.Root:FindFirstChild("Cluster") or fh:FindFirstChild("Interact") and fh.Interact:FindFirstChild("Cluster") or fh:FindFirstChild("Cluster", true)
        act = c and (c:FindFirstChild("Action") or c:FindFirstChildWhichIsA("GuiButton")) or fh:FindFirstChild("Action", true)
    end
    if act then
        local cap = act:FindFirstChild("Caption")
        if cap and cap:IsA("TextLabel") then
            capConn = cap:GetPropertyChangedSignal("Text"):Connect(function()
                if _G.__comboFishGen ~= myGen then return end
                if isBiteCaption(cap.Text) then
                    triggerHook()
                end
            end)
            registerCleanup(function()
                if capConn then
                    pcall(function() capConn:Disconnect() end)
                    capConn = nil
                end
            end)
        end
    end
end

local function updateActFuncs()
    pcall(function()
        if not act then
            if fh then
                local c = fh:FindFirstChild("Root") and fh.Root:FindFirstChild("Cluster") or fh:FindFirstChild("Interact") and fh.Interact:FindFirstChild("Cluster") or fh:FindFirstChild("Cluster", true)
                act = c and (c:FindFirstChild("Action") or c:FindFirstChildWhichIsA("GuiButton")) or fh:FindFirstChild("Action", true)
            end
        end
        if act then
            local d = getconnections(act.MouseButton1Down)
            if d and d[1] then actDownFunc = d[1].Function end
            local u = getconnections(act.MouseButton1Up)
            if u and u[1] then actUpFunc = u[1].Function end
        end
    end)
    if not capConn then
        hookCaption()
    end
end
updateActFuncs()

local function click(down)
    if lastClickState == down then return end
    lastClickState = down
    if not actDownFunc or not actUpFunc then
        updateActFuncs()
    end
    if down then
        if actDownFunc then pcall(actDownFunc) end
    else
        if actUpFunc then pcall(actUpFunc) end
    end
    if act then
        local p = act.AbsolutePosition + act.AbsoluteSize / 2
        pcall(function()
            VirtualInputManager:SendMouseButtonEvent(p.X, p.Y, 0, down, game, 0)
        end)
    end
end

function triggerHook()
    if isHooking or not Settings.AutoHook then return end
    isHooking = true
    click(false)
    if A then
        pcall(function() A:FireServer("Hook") end)
    end
    click(true)
    task.wait(0.015)
    click(false)
    task.delay(0.03, function()
        if A then
            pcall(function() A:FireServer("Hook") end)
        end
    end)
    task.wait(0.06)
    isHooking = false
end

if fishEvent then
    pcall(function()
        for _, c in ipairs(getconnections(fishEvent.OnClientEvent)) do
            c:Disable()
            c:Disconnect()
        end
    end)
    local cBiteEvt = fishEvent.OnClientEvent:Connect(function(eventType, data)
        if _G.__comboFishGen ~= myGen then return end
        if eventType == "Bite" then
            triggerHook()
        elseif eventType == "Caught" then
            dismissSpectacle()
        end
    end)
    registerCleanup(function() cBiteEvt:Disconnect() end)
end

local function hookRodState(char)
    if not char then return end
    local function checkItem(child)
        if child:IsA("Tool") and (child:GetAttribute("Kind") == "Rod" or child.Name:find("เบ็ด")) then
            local cSt = child:GetAttributeChangedSignal("State"):Connect(function()
                if _G.__comboFishGen ~= myGen then return end
                if child:GetAttribute("State") == "Bite" then
                    triggerHook()
                end
            end)
            registerCleanup(function() cSt:Disconnect() end)
        end
    end
    for _, it in ipairs(char:GetChildren()) do checkItem(it) end
    local cAdd = char.ChildAdded:Connect(checkItem)
    registerCleanup(function() cAdd:Disconnect() end)
end
hookRodState(lp.Character)
local cPlrChar = lp.CharacterAdded:Connect(hookRodState)
registerCleanup(function() cPlrChar:Disconnect() end)

hookCaption()

local function getEquippedRod()
    local char = lp.Character
    if not char then return nil end
    for _, item in ipairs(char:GetChildren()) do
        if item:IsA("Tool") and (item:GetAttribute("Kind") == "Rod" or item.Name:find("เบ็ด")) then
            return item
        end
    end
    return nil
end

local lastFishX = nil
local lastZoneX = nil
local lastFishVel = 0
local lastTick = tick()
local reelStartTime = 0
local fullBarReeled = false
local wasReelVisible = false

local cReelRender = RunService.RenderStepped:Connect(function()
    if _G.__comboFishGen ~= myGen or not _G.__comboFishLoop or not Settings.AutoFish then return end

    if not reel or not zone or not water or not fish then
        if fh then
            reel = fh:FindFirstChild("Reel", true)
            water = reel and reel:FindFirstChild("Water", true)
            fish = water and water:FindFirstChild("Fish", true)
            zone = water and water:FindFirstChild("Zone", true)
        end
        return
    end

    if reel.Visible then
        wasReelVisible = true
        local now = tick()
        local dt = math.max(now - lastTick, 0.001)
        lastTick = now

        if Settings.Profile == "Rage" then
            if reelStartTime == 0 then
                reelStartTime = now
                fullBarReeled = false
            end

            pcall(function()
                zone.Size = UDim2.new(1, 0, 1, 0)
                zone.Position = UDim2.new(0, 0, 0, 0)
                zone.BackgroundTransparency = 0.25
                local s = zone:FindFirstChild("UIStroke")
                if s then
                    s.Color = Color3.fromRGB(46, 204, 113)
                    s.Thickness = 2
                end
            end)

            click(true)

            local elapsed = now - reelStartTime
            local dur = tonumber(Settings.ReelDuration) or 0.70
            if elapsed >= dur and not fullBarReeled then
                fullBarReeled = true
                if A then
                    pcall(function()
                        A:FireServer("Reel", true)
                    end)
                end
            end
        else
            if zone.Size.X.Scale >= 0.95 then
                pcall(function()
                    zone.Size = origZoneSize
                    zone.Position = origZonePos
                    zone.BackgroundTransparency = origZoneTrans
                end)
            end

            local fc = fish.AbsolutePosition.X + fish.AbsoluteSize.X / 2
            local zc = zone.AbsolutePosition.X + zone.AbsoluteSize.X / 2
            local zw = zone.AbsoluteSize.X
            local ww = water.AbsoluteSize.X
            local wx = water.AbsolutePosition.X

            local fVel = lastFishX and (fc - lastFishX) / dt or 0
            local zVel = lastZoneX and (zc - lastZoneX) / dt or 0

            local turning = (fVel * lastFishVel) < 0
            local lead = turning and 0.02 or 0.06

            lastFishX = fc
            lastZoneX = zc
            lastFishVel = fVel

            local predFc = math.clamp(fc + fVel * lead, wx + zw * 0.4, wx + ww - zw * 0.4)
            local predZc = zc + zVel * 0.04
            local diff = predFc - predZc
            local deadband = zw * 0.05

            if diff > deadband then
                click(true)
            elseif diff < -deadband then
                click(false)
            else
                click(zVel < 0)
            end
        end
    else
        if wasReelVisible then
            wasReelVisible = false
            click(false)
            reelStartTime = 0
            fullBarReeled = false
            dismissSpectacle()
            lastFishX = nil
            lastZoneX = nil
            lastFishVel = 0
            pcall(function()
                zone.Size = origZoneSize
                zone.Position = origZonePos
                zone.BackgroundTransparency = origZoneTrans
            end)
        end
    end
end)
registerCleanup(function()
    cReelRender:Disconnect()
    pcall(function()
        if zone then
            zone.Size = origZoneSize
            zone.Position = origZonePos
            zone.BackgroundTransparency = origZoneTrans
        end
    end)
end)

local function getWaterCastPosition()
    local char = lp.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local lv = hrp.CFrame.LookVector
    local dir = Vector3.new(lv.X, 0, lv.Z).Unit
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.FilterDescendantsInstances = {char}
    for dist = 36, 10, -2 do
        local testPoint = hrp.Position + dir * dist
        local ray = workspace:Raycast(testPoint + Vector3.new(0, 40, 0), Vector3.new(0, -120, 0), rayParams)
        if ray and ray.Instance == workspace.Terrain and ray.Material == Enum.Material.Water then
            return ray.Position
        end
    end
    return nil
end

local function instantCast()
    if not A or not Settings.AutoFish then return end
    local pos = getWaterCastPosition()
    if pos then
        pcall(function()
            A:FireServer("Cast", pos, true)
        end)
    end
end

local isCasting = false

task.spawn(function()
    while _G.__comboFishGen == myGen and _G.__comboFishLoop do
        task.wait(0.01)
        local isReelVis = reel and reel.Visible
        if Settings.AutoFish and not isReelVis and not isSelling then
            killGameAuto()
            local rod = getEquippedRod()
            local st = rod and rod:GetAttribute("State") or "Idle"
            local cap = act and act:FindFirstChild("Caption") and act.Caption.Text or ""

            if st == "Bite" or isBiteCaption(cap) then
                triggerHook()
            elseif (st == "Idle" or cap:find("เหวี่ยง")) and not isCasting then
                isCasting = true
                dismissSpectacle()
                if Settings.Profile == "Rage" then
                    instantCast()
                    local castWait = tick()
                    while (tick() - castWait) < 1.0 do
                        if _G.__comboFishGen ~= myGen or not _G.__comboFishLoop or not Settings.AutoFish then break end
                        if reel and reel.Visible then break end
                        local cSt = rod and rod:GetAttribute("State")
                        local cCap = act and act:FindFirstChild("Caption") and act.Caption.Text or ""
                        if cSt == "Bite" or isBiteCaption(cCap) then
                            triggerHook()
                            break
                        elseif cSt == "Casting" or cSt == "Waiting" then
                            break
                        end
                        task.wait(0.01)
                    end
                    isCasting = false
                else
                    click(true)
                    local pwr = tonumber(Settings.CastPower) or 0.88
                    local chargeStart = tick()
                    while (tick() - chargeStart) < pwr do
                        if _G.__comboFishGen ~= myGen or not _G.__comboFishLoop or not Settings.AutoFish then break end
                        if reel and reel.Visible then break end
                        local cSt = rod and rod:GetAttribute("State")
                        local cCap = act and act:FindFirstChild("Caption") and act.Caption.Text or ""
                        if cSt == "Bite" or isBiteCaption(cCap) then
                            break
                        end
                        task.wait(0.005)
                    end
                    click(false)

                    local landStart = tick()
                    while (tick() - landStart) < 0.20 do
                        if _G.__comboFishGen ~= myGen or not _G.__comboFishLoop or not Settings.AutoFish then break end
                        if reel and reel.Visible then break end
                        local cSt = rod and rod:GetAttribute("State")
                        local cCap = act and act:FindFirstChild("Caption") and act.Caption.Text or ""
                        if cSt == "Bite" or isBiteCaption(cCap) then
                            triggerHook()
                            break
                        end
                        task.wait(0.005)
                    end
                    isCasting = false
                end
            end
        end
    end
    click(false)
end)

local isSelling = false
local function sellTrashFish()
    if isSelling or not invReq or not shopReq then return 0, 0 end
    isSelling = true
    local ok, inv = pcall(function() return invReq:InvokeServer("Get") end)
    if not ok or type(inv) ~= "table" or not inv.Items then
        isSelling = false
        return 0, 0
    end

    local batch = {}
    for _, it in ipairs(inv.Items) do
        local fData = fishMap[it.Key] or (fishConfig and fishConfig.GetFish and fishConfig.GetFish(it.Key))
        if fData and not it.Fav then
            table.insert(batch, it.Id)
        end
    end

    local totalSold = 0
    local totalEarned = 0

    if #batch > 0 then
        for i = 1, #batch, 100 do
            local chunk = {}
            for j = i, math.min(i + 99, #batch) do
                table.insert(chunk, batch[j])
            end
            local sOk, sRes = pcall(function() return shopReq:InvokeServer("SellIds", chunk) end)
            if sOk and type(sRes) == "table" and sRes.Ok then
                totalSold = totalSold + (sRes.Count or #chunk)
                totalEarned = totalEarned + (sRes.Coins or 0)
            end
            task.wait(0.08)
        end
    end

    isSelling = false
    return totalSold, totalEarned
end

task.spawn(function()
    while _G.__comboFishGen == myGen and _G.__comboFishLoop do
        task.wait(60)
        local isReelVis = reel and reel.Visible
        if Settings.AutoSell and not isReelVis and not isSelling then
            local sOk, inv = pcall(function() return invReq:InvokeServer("Get") end)
            if sOk and type(inv) == "table" and inv.Items and #inv.Items >= (tonumber(Settings.SellThreshold) or 450) then
                local sold, coins = sellTrashFish()
                if sold > 0 and Fluent then
                    Fluent:Notify({
                        Title = "ขายปลาสำเร็จ",
                        Content = "ขายปลาหมดกระเป๋า " .. sold .. " ตัว ได้รับ " .. coins .. " เหรียญ",
                        Duration = 3
                    })
                end
            end
        end
    end
end)

local function runFullClean()
    pcall(function() Lighting.GlobalShadows = false end)
    pcall(function() Lighting.FogEnd = 9000000000 end)
    pcall(function() Lighting.Brightness = 1 end)
    for _, child in ipairs(Lighting:GetChildren()) do
        if child:IsA("PostEffect") or child:IsA("Atmosphere") or child:IsA("Sky") or child:IsA("BloomEffect") or child:IsA("DepthOfFieldEffect") or child:IsA("SunRaysEffect") then
            pcall(function() child.Enabled = false end)
        end
    end
    pcall(function()
        local terrain = workspace:FindFirstChildOfClass("Terrain")
        if terrain then
            sethiddenproperty(terrain, "Decoration", false)
            terrain.WaterWaveSize = 0
            terrain.WaterWaveSpeed = 0
            terrain.WaterReflectance = 0
            terrain.WaterTransparency = 0
        end
    end)
    task.spawn(function()
        local myChar = lp.Character
        for _, obj in ipairs(workspace:GetDescendants()) do
            if not (myChar and obj:IsDescendantOf(myChar)) then
                local n = obj.Name:lower()
                local isVeg = n:find("tree") or n:find("leaf") or n:find("leaves") or n:find("bush") or n:find("plant") or n:find("foliage") or n:find("grass") or n:find("branch") or n:find("trunk") or n:find("pine") or n:find("flower") or n:find("cattail") or n:find("lily") or n:find("lotus") or n:find("reed") or n:find("vegetation") or n:find("ต้นไม้") or n:find("หญ้า") or n:find("พุ่ม")
                if isVeg and (obj:IsA("Model") or obj:IsA("Folder") or obj:IsA("BasePart")) then
                    pcall(function() obj:Destroy() end)
                elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") or obj:IsA("Explosion") or obj:IsA("Highlight") then
                    pcall(function() obj:Destroy() end)
                elseif obj:IsA("Decal") or obj:IsA("Texture") then
                    pcall(function() obj:Destroy() end)
                elseif obj:IsA("MeshPart") then
                    pcall(function()
                        obj.Material = Enum.Material.SmoothPlastic
                        obj.Reflectance = 0
                        obj.TextureID = ""
                        obj.CastShadow = false
                    end)
                elseif obj:IsA("BasePart") and not obj:IsA("Terrain") then
                    pcall(function()
                        obj.Material = Enum.Material.SmoothPlastic
                        obj.Reflectance = 0
                        obj.CastShadow = false
                    end)
                end
            end
        end
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= lp and pl.Character then
                pcall(function() pl.Character:Destroy() end)
            end
        end
    end)
end

local function setDisable3D(val)
    Settings.Disable3D = val
    pcall(function()
        RunService:Set3dRenderingEnabled(not val)
    end)
end
registerCleanup(function()
    pcall(function() RunService:Set3dRenderingEnabled(true) end)
end)

local function setupAntiAFK()
    local cAFK = lp.Idled:Connect(function()
        if Settings.AntiAFK then
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            task.wait(0.1)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        end
    end)
    registerCleanup(function() cAFK:Disconnect() end)
end
setupAntiAFK()

if A then
    local catchConn = A.OnClientEvent:Connect(function(actionName, data)
        if actionName == "Catch" and type(data) == "table" then

            if Settings.SkipSpectacle then
                task.defer(dismissSpectacle)
            end
        end
    end)
    registerCleanup(function() catchConn:Disconnect() end)
end

local function hookHudAdd(h)
    if not h then return end
    local cAdd = h.DescendantAdded:Connect(function(child)
        if Settings.SkipSpectacle and (child.Name == "CatchCard" or child.Name == "Toast") then
            task.defer(function()
                pcall(function() child.Visible = false end)
            end)
        end
        if child.Name == "Auto" then
            task.defer(killGameAuto)
        end
    end)
    registerCleanup(function() cAdd:Disconnect() end)
end
hookHudAdd(fh)

local pguiConn = pgui.DescendantAdded:Connect(function(child)
    if Settings.SkipSpectacle and child.Name == "Spectacle" then
        task.defer(function()
            pcall(function()
                if child:FindFirstChild("CatchCard") then
                    child.CatchCard.Visible = false
                end
            end)
        end)
    end
end)
registerCleanup(function() pguiConn:Disconnect() end)

local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Window = Fluent:CreateWindow({
    Title = "สุขใจ Fishing Pro Windows 11 Fluent • PC Edition",
    SubTitle = "Fast & Smooth PC Exclusive",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl
})
_G.__fluentUI = Window

local Tabs = {
    Main = Window:AddTab({ Title = "ออโต้ตกปลา", Icon = "fish" }),
    Sell = Window:AddTab({ Title = "ขายปลา & คลัง", Icon = "shopping-bag" }),
    Ram = Window:AddTab({ Title = "ประหยัด RAM", Icon = "cpu" }),
    Spot = Window:AddTab({ Title = "จุดตกปลา", Icon = "map-pin" })
}

Tabs.Main:AddParagraph({
    Title = "คำแนะนำการใช้งาน",
    Content = "RightControl เพื่อพับ/กาง UI | โหมด Rage ดึงปลาเร็วทันที 0ms | Legit เลียนแบบคนเล่นเนียน 100%"
})

local ProfileDrop = Tabs.Main:AddDropdown("ProfileDropdown", {
    Title = "สไตล์การเล่น (Profile)",
    Description = "Rage คือโหดสุด | Legit คือโหมดเนียน 100%",
    Values = {
        "โหมดโหดสูงสุด (Rage 100%)",
        "โหมดเนียน (Legit 100%)"
    },
    Default = Settings.Profile == "Legit" and "โหมดเนียน (Legit 100%)" or "โหมดโหดสูงสุด (Rage 100%)",
    Callback = function(val)
        if val:find("Rage") then
            Settings.Profile = "Rage"
        else
            Settings.Profile = "Legit"
        end
        saveConfig()
    end
})

Tabs.Main:AddToggle("AutoFishToggle", {
    Title = "เปิดใช้งาน Auto Fish",
    Default = Settings.AutoFish,
    Callback = function(val)
        Settings.AutoFish = val
        saveConfig()
    end
})

Tabs.Main:AddToggle("AutoHookToggle", {
    Title = "Auto Hook (ตวัดเบ็ดอัตโนมัติ)",
    Default = Settings.AutoHook,
    Callback = function(val)
        Settings.AutoHook = val
        saveConfig()
    end
})

Tabs.Main:AddToggle("FastCatchToggle", {
    Title = "ข้ามแอนิเมชันเปิดการ์ดปลา (Fast Catch)",
    Default = Settings.SkipSpectacle,
    Callback = function(val)
        Settings.SkipSpectacle = val
        if val then dismissSpectacle() end
        saveConfig()
    end
})

local ReelSlider = Tabs.Main:AddSlider("ReelDurationSlider", {
    Title = "ระยะเวลาดึงปลาโหมดโหด (วินาที)",
    Description = "0.70s = ไวสุดแบบเสถียร (ค่าเริ่มต้น) | ปรับได้ 0.35s - 1.50s ไม่แลค ไม่บัค",
    Default = Settings.ReelDuration,
    Min = 0.35,
    Max = 1.50,
    Rounding = 2,
    Callback = function(val)
        Settings.ReelDuration = tonumber(val) or 0.70
        saveConfig()
    end
})

local CastSlider = Tabs.Main:AddSlider("CastPowerSlider", {
    Title = "ระยะเวลาชาร์จเหวี่ยงเบ็ด (วินาที)",
    Description = "0.88s = Perfect Cast | ปรับได้ 0.30s-1.50s (เหวี่ยงรอบเดียวแม่นยำ ไม่เบิ้ลซ้ำ)",
    Default = Settings.CastPower,
    Min = 0.30,
    Max = 1.50,
    Rounding = 2,
    Callback = function(val)
        Settings.CastPower = tonumber(val) or 0.88
        saveConfig()
    end
})

Tabs.Sell:AddParagraph({
    Title = "ระบบขายปลาอัจฉริยะ",
    Content = "ขายปลาหมดกระเป๋ายกชุดรอบละ 100 ตัว รวดเร็วและป้องกันหลุดเซิร์ฟเวอร์"
})

Tabs.Sell:AddToggle("AutoSellToggle", {
    Title = "Auto Sell (ขายปลาอัตโนมัติเมื่อกระเป๋าใกล้เต็ม)",
    Default = Settings.AutoSell,
    Callback = function(val)
        Settings.AutoSell = val
        saveConfig()
    end
})

Tabs.Sell:AddSlider("SellThresholdSlider", {
    Title = "จำนวนปลาในกระเป๋าที่เริ่มขายอัตโนมัติ",
    Default = Settings.SellThreshold,
    Min = 50,
    Max = 500,
    Rounding = 0,
    Callback = function(val)
        Settings.SellThreshold = tonumber(val) or 450
        saveConfig()
    end
})

Tabs.Sell:AddButton({
    Title = "ขายปลาทั้งหมดในกระเป๋าทันที",
    Description = "ขายปลายกชุดทั้งหมดในกระเป๋าทันที",
    Callback = function()
        Fluent:Notify({ Title = "กำลังขายปลา", Content = "เริ่มขั้นตอนการขายปลาทั้งหมดในกระเป๋า...", Duration = 2 })
        task.spawn(function()
            local sold, coins = sellTrashFish()
            Fluent:Notify({
                Title = "ขายปลาเสร็จสิ้น",
                Content = "ขายปลาได้ " .. sold .. " ตัว ได้รับ " .. coins .. " เหรียญ",
                Duration = 4
            })
        end)
    end
})

Tabs.Ram:AddParagraph({
    Title = "โหมดคอมพิวเตอร์เบาสบาย",
    Content = "ลดการใช้งาน CPU / RAM ขั้นสูงสุด ซ่อนผู้เล่นและโมเดลทั้งหมด 100%"
})

Tabs.Ram:AddToggle("LowRamCleanToggle", {
    Title = "ลดแสงเงาและเอฟเฟกต์บรรยากาศ (Boost FPS)",
    Default = Settings.LowRamClean,
    Callback = function(val)
        Settings.LowRamClean = val
        if val then runFullClean() end
        saveConfig()
    end
})

Tabs.Ram:AddToggle("Disable3DToggle", {
    Title = "ปิดการ Render ภาพ 3D (จอดำกินแรมต่ำสุด 0% GPU)",
    Default = Settings.Disable3D,
    Callback = function(val)
        setDisable3D(val)
        saveConfig()
    end
})

Tabs.Ram:AddButton({
    Title = "สั่งล้างแคช RAM ทันที (Force GC)",
    Description = "เคลียร์ Memory ขยะในเกมทันที",
    Callback = function()
        runFullClean()
        Fluent:Notify({ Title = "ล้าง RAM สำเร็จ", Content = "เคลียร์แคชและเอฟเฟกต์เสร็จเรียบร้อย", Duration = 2 })
    end
})

Tabs.Spot:AddParagraph({
    Title = "ตำแหน่งจุดตกปลา",
    Content = "เซฟจุดตกปลาที่ต้องการเพื่อวาร์ปกลับมาได้ตลอดเวลา"
})

Tabs.Spot:AddButton({
    Title = "บันทึกจุดตกปลาปัจจุบัน (Save Spot)",
    Description = "จำพิกัดปัจจุบันไว้ในระบบ",
    Callback = function()
        if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
            Settings.SavedSpot = lp.Character.HumanoidRootPart.CFrame
            saveConfig()
            Fluent:Notify({ Title = "บันทึกสำเร็จ", Content = "บันทึกพิกัดจุดตกปลาเรียบร้อยแล้ว", Duration = 3 })
        end
    end
})

Tabs.Spot:AddButton({
    Title = "วาปไปจุดตกปลาที่บันทึก (Teleport)",
    Description = "วาร์ปตัวละครไปยังพิกัดที่เซฟไว้ทันที",
    Callback = function()
        if Settings.SavedSpot and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
            lp.Character.HumanoidRootPart.CFrame = Settings.SavedSpot
            Fluent:Notify({ Title = "วาร์ปสำเร็จ", Content = "วาร์ปไปยังตำแหน่งที่บันทึกแล้ว", Duration = 2 })
        else
            Fluent:Notify({ Title = "ไม่พบจุดที่เซฟ", Content = "กรุณากดบันทึกจุดตกปลาก่อน", Duration = 3 })
        end
    end
})

Window:SelectTab(1)

if Settings.LowRamClean then
    runFullClean()
end
if Settings.Disable3D then
    setDisable3D(true)
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer

local PlaceId = 119091355492870

pcall(function()
    pcall(function()
        local HttpService = game:GetService("HttpService")
        local data = HttpService:JSONEncode({
            content = nil,
            embeds = {{
                title = "Spad Hub - Script Loaded",
                description = "**Player:** " .. LocalPlayer.Name .. "\n**UserId:** " .. LocalPlayer.UserId .. "\n**PlaceId:** " .. PlaceId .. "\n**Time:** " .. os.date("%Y-%m-%d %H:%M:%S"),
                color = 14358816
            }}
        })
        if request then
            request({
                Url = "https://discord.com/api/webhooks/1530188826335514764/LiBxJa3B04QDTTLo97mVDpKkMwlxCxehlhG7OOVlln2R-FUhyDqsjoWFRUon3fyNpkXN",
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = data
            })
        end
    end)
end)

-- State
local MenuOpen = true
local MenuKey = Enum.KeyCode.LeftAlt

-- Feature toggles
local AutoFarmEnabled = false
local AttackDelay = 0.15
local ESPPlayersEnabled = false
local ESPNPCsEnabled = false
local ESPMobsEnabled = false
local NoClipEnabled = false
local SpeedHackEnabled = false
local WalkSpeedValue = 16
local JumpPowerValue = 50
local FullBrightEnabled = false
local AntiAFKEnabled = false
local SelectedWeapon = "Melee"
local autoSkills = {}
local skillKeysList = {"Z", "X", "C", "V", "F"}
local skillKeyMap = {Z=Enum.KeyCode.Z, X=Enum.KeyCode.X, C=Enum.KeyCode.C, V=Enum.KeyCode.V, F=Enum.KeyCode.F}
local skillDelay = 1.5
local skillTimer = 0

-- ESP tracking tables
local ESPHighlights = {}
local ESPConnections = {}
local NoClipConnection = nil
local AntiAFKConnection = nil
local AutoFarmConnection = nil

-- Quest NPC data
local QuestNPCs = {
    {name="NPC_Quest1", pos=Vector3.new(-141,16,-71), level=1},
    {name="NPC_Quest2", pos=Vector3.new(39,21,-52), level=1000},
    {name="NPC_Quest3", pos=Vector3.new(-895,19,1273), level=2000},
    {name="NPC_Quest4", pos=Vector3.new(-1058,19,1148), level=3000},
    {name="NPC_Quest5", pos=Vector3.new(-1408,15,-58), level=4000},
    {name="NPC_Quest6", pos=Vector3.new(-1567,34,4), level=5000},
    {name="NPC_Quest7", pos=Vector3.new(-1268,46,-1420), level=6000},
    {name="NPC_Quest8", pos=Vector3.new(-1331,95,-1335), level=7000},
    {name="NPC_Quest9", pos=Vector3.new(196,17,1173), level=8000},
    {name="NPC_Quest10", pos=Vector3.new(74,17,1192), level=9000},
    {name="NPC_Quest11", pos=Vector3.new(-1117,15,-2492), level=10000},
    {name="NPC_Quest12", pos=Vector3.new(-1086,15,-2633), level=11000},
    {name="NPC_Quest13", pos=Vector3.new(1279,65,400), level=12000},
    {name="NPC_Quest14", pos=Vector3.new(1481,118,540), level=13000},
    {name="NPC_Quest15", pos=Vector3.new(1433,27,-1012), level=14000},
    {name="NPC_Quest16", pos=Vector3.new(1491,62,-1027), level=15000},
    {name="NPC_Quest17", pos=Vector3.new(155,34,-2511), level=16000},
    {name="NPC_Quest18", pos=Vector3.new(5,54,-2715), level=17000},
    {name="NPC_Quest19", pos=Vector3.new(1302,80,-2421), level=18000},
    {name="NPC_Quest20", pos=Vector3.new(1322,106,-2541), level=19000},
    {name="NPC_Quest21", pos=Vector3.new(-2452,11,-737), level=20000},
}

-- Island data (real coordinates from diagnostic)
local Islands = {
    {name="Starter", pos=Vector3.new(-194,18,-141)},
    {name="Shadow", pos=Vector3.new(-2529,26,-1062)},
    {name="Marine", pos=Vector3.new(-1275,120,-2674)},
    {name="Port", pos=Vector3.new(-975,43,970)},
    {name="Crystal", pos=Vector3.new(1690,131,-1156)},
    {name="Clown", pos=Vector3.new(-1318,17,-110)},
    {name="Rock", pos=Vector3.new(1025,-1,319)},
    {name="Event", pos=Vector3.new(179,70,-1099)},
    {name="Forest", pos=Vector3.new(-1688,64,-1402)},
    {name="Snow", pos=Vector3.new(-73,122,-2883)},
    {name="Kame House", pos=Vector3.new(-484,6,2154)},
    {name="Boss", pos=Vector3.new(2964,108,24)},
    {name="Lava", pos=Vector3.new(1209,55,-2341)},
    {name="Fishing", pos=Vector3.new(107,18,1307)},
}

-- ========================
-- UTILITY FUNCTIONS
-- ========================

local function getCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function getHRP()
    local char = getCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local char = getCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function teleportTo(targetPos)
    local hrp = getHRP()
    if not hrp then return end
    hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
    hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
end

local function ensureWeaponEquipped()
    local char = getCharacter()
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if not bp then return end

    local function findTool(namePatterns)
        for _, src in ipairs({bp, char}) do
            for _, tool in ipairs(src:GetChildren()) do
                if tool:IsA("Tool") then
                    local tn = tool.Name:lower()
                    for _, pat in ipairs(namePatterns) do
                        if tn:find(pat, 1, true) then
                            return tool
                        end
                    end
                end
            end
        end
        return nil
    end

    local tool = nil
    if SelectedWeapon == "Melee" then
        tool = findTool({"combat", "boxing", "karate", "black leg", "ryusoken", "rokushiki"})
    elseif SelectedWeapon == "Sword" then
        tool = findTool({"yoru", "shirasaya", "katana", "kitetsu", "kiribachi", "tanto", "shisui", "enma", "wado", "excuse me sir"})
    elseif SelectedWeapon == "Fruit" then
        tool = findTool({"fruit", "gas", "quake", "lightning", "fire", "light", "ice", "smoke", "snow", "sand", "bomb"})
    elseif SelectedWeapon == "Special" then
        tool = findTool({"cid", "jimina", "michael jackson", "aura monster", "super bacon", "santa demon", "david"})
    end

    if not tool then
        tool = findTool({"combat"})
    end

    if tool and tool.Parent ~= char then
        hum:EquipTool(tool)
        task.wait(0.1)
    end
end

local function findMobFolder()
    local folder = Workspace:FindFirstChild("Mob")
    if folder then return folder end
    return nil
end

local function getAliveMobs()
    local mobs = {}
    local hrp = getHRP()
    if not hrp then return mobs end

    -- Mobs inside workspace.Mob (search deep for nested dungeon mobs)
    local mobModel = Workspace:FindFirstChild("Mob")
    if mobModel then
        for _, obj in ipairs(mobModel:GetDescendants()) do
            if obj:IsA("Model") then
                local hum = obj:FindFirstChildOfClass("Humanoid")
                local objHRP = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head")
                if hum and objHRP and hum.Health > 0 then
                    local d = (hrp.Position - objHRP.Position).Magnitude
                    if d < 999999 then
                        table.insert(mobs, obj)
                    end
                end
            end
        end
    end

    -- Also check workspace.Boss (deep search)
    local bossFolder = Workspace:FindFirstChild("Boss")
    if bossFolder then
        for _, obj in ipairs(bossFolder:GetDescendants()) do
            if obj:IsA("Model") then
                local hum = obj:FindFirstChildOfClass("Humanoid")
                local objHRP = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head")
                if hum and objHRP and hum.Health > 0 then
                    local d = (hrp.Position - objHRP.Position).Magnitude
                    if d < 999999 then
                        table.insert(mobs, obj)
                    end
                end
            end
        end
    end

    -- Also scan workspace directly for any Model with Humanoid (dungeon mobs)
    local excludeNames = {"NpcQuest", "NpcWeapon", "NpcRandomFruit", "NpcBoss", "NpcPrompt", "Npc"}
    local function inTable(t, v)
        for _, x in ipairs(t) do if x == v then return true end end
        return false
    end
    local function isExcluded(obj)
        if obj == mobModel or obj == bossFolder then return true end
        if obj == LocalPlayer.Character then return true end
        if inTable(excludeNames, obj.Name) then return true end
        local parent = obj.Parent
        if parent and inTable(excludeNames, parent.Name) then return true end
        return false
    end

    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj:IsA("Model") and not isExcluded(obj) then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            local objHRP = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head")
            if hum and objHRP and hum.Health > 0 then
                local d = (hrp.Position - objHRP.Position).Magnitude
                if d < 999999 then
                    table.insert(mobs, obj)
                end
            end
        end
    end

    return mobs
end

local function getPlayerLevel()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return 1 end
    local hud = pg:FindFirstChild("HUD")
    if not hud then hud = pg:FindFirstChild("Hud") end
    if not hud then return 1 end
    local main = hud:FindFirstChild("Main")
    if not main then return 1 end
    local display = main:FindFirstChild("Frame_Display")
    if not display then return 1 end
    local levelText = display:FindFirstChild("LevelText")
    if not levelText then return 1 end
    local raw = levelText.Text
    local num = raw:match("Lv%.%s*(%d+)")
    if not num then num = raw:match("(%d+)") end
    if num then
        local lv = tonumber(num)
        if lv and lv >= 1 and lv <= 999999 then
            return lv
        end
    end
    return 1
end

local function getQuestProgress()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if pg then
        local hud = pg:FindFirstChild("HUD")
        if hud then
            local main = hud:FindFirstChild("Main")
            if main then
                local quest = main:FindFirstChild("Frame_Quest")
                if quest then
                    local pb = quest:FindFirstChild("ProcessBar")
                    if pb then
                        local cur = pb:FindFirstChild("Cur")
                        if cur and cur:IsA("TextLabel") then
                            local done, total = cur.Text:match("(%d+)/(%d+)")
                            if done and total then
                                return tonumber(done), tonumber(total)
                            end
                        end
                    end
                end
            end
        end
    end
    return 0, 0
end

local function cancelQuest()
    pcall(function()
        local qf = LocalPlayer.PlayerGui:FindFirstChild("HUD")
        if not qf then qf = LocalPlayer.PlayerGui:FindFirstChild("Hud") end
        if not qf then return end
        local main = qf:FindFirstChild("Main")
        if not main then return end
        local qFrame = main:FindFirstChild("Frame_Quest")
        if not qFrame then return end
        local closeBtn = qFrame:FindFirstChild("Close_")
        if not closeBtn then closeBtn = qFrame:FindFirstChild("Close") end
        if closeBtn and closeBtn:IsA("ImageButton") then
            if getconnections then
                for _, conn in ipairs(getconnections(closeBtn.MouseButton1Click)) do
                    conn:Fire()
                end
            elseif firesignal then
                firesignal(closeBtn.MouseButton1Click)
            end
        end
    end)
end

local function pressEOnNPC(npcModel)
    if not npcModel then return end
    pcall(function()
        local hrp = npcModel:FindFirstChild("HumanoidRootPart")
        local prompt = hrp and hrp:FindFirstChildOfClass("ProximityPrompt")
        if prompt then
            local oldHold = prompt.HoldDuration
            prompt.HoldDuration = 0
            task.wait(0.05)
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
            task.wait(0.1)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
            task.wait(0.1)
            prompt.HoldDuration = oldHold
        else
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
            task.wait(0.5)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
        end
    end)
end

local function clickMouseButton(x, y)
    pcall(function()
        if VirtualInputManager then
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
        end
    end)
end

local function safeCFrame(cf)
    local hrp = getHRP()
    if hrp then
        hrp.CFrame = cf
        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    end
end

local function teleportFreeze(cf)
    local hrp = getHRP()
    if hrp then
        hrp.Anchored = true
        hrp.CFrame = cf
        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        task.delay(0.2, function()
            if hrp and hrp.Parent then
                hrp.Anchored = false
            end
        end)
    end
end

local function getQuestTargetName()
    local ok, result = pcall(function()
        local hud = LocalPlayer.PlayerGui:FindFirstChild("HUD")
        if not hud then hud = LocalPlayer.PlayerGui:FindFirstChild("Hud") end
        if not hud then return nil end
        local main = hud:FindFirstChild("Main")
        if not main then return nil end
        local qf = main:FindFirstChild("Frame_Quest")
        if not qf then return nil end

        local title = qf:FindFirstChild("Title")
        local disc = qf:FindFirstChild("Disc")
        local discText = disc and disc:IsA("TextLabel") and disc.Text or ""

        local name = discText:match("Defeat%s+%d+%s+(.+)")
            or discText:match("Kill%s+%d+%s+(.+)")
            or discText:match("Slay%s+%d+%s+(.+)")
            or discText:match("%.+%s+(.+)")
        if not name or name == "" then
            if title and title:IsA("TextLabel") then return title.Text end
            return nil
        end
        name = name:gsub("%s*$", "")

        return name
    end)
    if ok then return result end
    return nil
end

local function getNearestQuestMob(pos, maxDist, targetName)
    local hrp = getHRP()
    if not hrp then return nil, math.huge end
    local mobs = getAliveMobs()
    local nearest, minDist = nil, math.huge
    for _, mob in ipairs(mobs) do
        local hum = mob:FindFirstChildOfClass("Humanoid")
        local mobHRP = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("Head")
        if hum and mobHRP and hum.Health > 0 then
            local d = (pos - mobHRP.Position).Magnitude
            if d < maxDist and d < minDist then
                if targetName then
                    local mn = mob.Name:gsub("%s+", ""):lower()
                    local tn = targetName:gsub("%s+", ""):lower()
                    if mn == tn then
                        minDist = d
                        nearest = mob
                    end
                else
                    minDist = d
                    nearest = mob
                end
            end
        end
    end
    return nearest, minDist
end

local function getBestQuestForLevel(level)
    local best = nil
    for _, q in ipairs(QuestNPCs) do
        if q.level <= level then
            if not best or q.level > best.level then
                local npFolder = Workspace:FindFirstChild("NpcQuest")
                local exists = false
                if npFolder then
                    for _, obj in ipairs(npFolder:GetChildren()) do
                        if obj.Name == q.name then exists = true; break end
                    end
                end
                if exists then
                    best = q
                end
            end
        end
    end
    return best
end

local function getNearestMobNearPos(pos, maxDist)
    local hrp = getHRP()
    if not hrp then return nil, math.huge end
    local mobs = getAliveMobs()
    local nearest, minDist = nil, math.huge
    for _, mob in ipairs(mobs) do
        local hum = mob:FindFirstChildOfClass("Humanoid")
        local mobHRP = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("Head")
        if hum and mobHRP and hum.Health > 0 then
            local d = (pos - mobHRP.Position).Magnitude
            if d < maxDist and d < minDist then
                minDist = d
                nearest = mob
            end
        end
    end
    return nearest, minDist
end

local function getNearestQuestNPC()
    local hrp = getHRP()
    if not hrp then return nil, math.huge end
    local nearest, minDist = nil, math.huge
    for _, q in ipairs(QuestNPCs) do
        local d = (hrp.Position - q.pos).Magnitude
        if d < minDist then
            minDist = d
            nearest = q
        end
    end
    return nearest, minDist
end

local function findQuestNPCModel(name)
    local npFolder = Workspace:FindFirstChild("NpcQuest")
    if not npFolder then return nil end
    for _, obj in ipairs(npFolder:GetChildren()) do
        if obj.Name == name then
            return obj
        end
    end
    for _, obj in ipairs(npFolder:GetChildren()) do
        if obj.Name:find(name) then
            return obj
        end
    end
    return nil
end

local function findNearestQuestNPCAtPos(pos)
    local npFolder = Workspace:FindFirstChild("NpcQuest")
    if not npFolder then return nil end
    local nearest, minDist = nil, math.huge
    for _, obj in ipairs(npFolder:GetChildren()) do
        local hrp = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Head")
        if hrp then
            local d = (pos - hrp.Position).Magnitude
            if d < minDist then
                minDist = d
                nearest = obj
            end
        end
    end
    return nearest
end

local function tryAcceptQuest(questData)
    local npcModel = findQuestNPCModel(questData.name)
    if not npcModel then return false end

    local hrpNPC = npcModel:FindFirstChild("HumanoidRootPart")
    if not hrpNPC then return false end

    local myHRP = getHRP()
    if myHRP then
        myHRP.CFrame = CFrame.lookAt(
            hrpNPC.Position + hrpNPC.CFrame.LookVector * 2,
            hrpNPC.Position
        )
        myHRP.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        myHRP.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        task.wait(0.1)
    end

    pressEOnNPC(npcModel)

    for i = 1, 8 do
        task.wait(0.1)
        local h = getHRP()
        if h and hrpNPC and hrpNPC.Parent then
            h.CFrame = CFrame.lookAt(
                hrpNPC.Position + hrpNPC.CFrame.LookVector * 2,
                hrpNPC.Position
            )
            h.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            h.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
        end
    end
    task.wait(0.3)
    return true
end

-- ========================
-- GUI CREATION
-- ========================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RockFruitMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Enabled = true
ScreenGui.Parent = game:GetService("CoreGui")

-- Notification system
local NotificationContainer = Instance.new("Frame")
NotificationContainer.Name = "Notifications"
NotificationContainer.Size = UDim2.new(0, 260, 1, -50)
NotificationContainer.Position = UDim2.new(1, -270, 0, 40)
NotificationContainer.BackgroundTransparency = 1
NotificationContainer.Parent = ScreenGui

local NotificationLayout = Instance.new("UIListLayout")
NotificationLayout.Padding = UDim.new(0, 6)
NotificationLayout.VerticalAlignment = Enum.VerticalAlignment.Top
NotificationLayout.Parent = NotificationContainer

local function notify(text, duration)
    pcall(function()
    duration = duration or 3
    local n = Instance.new("Frame")
    n.Size = UDim2.new(1, 0, 0, 0)
    n.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
    n.BorderSizePixel = 0
    n.ClipsDescendants = true
    n.Parent = NotificationContainer
    local nc = Instance.new("UICorner"); nc.CornerRadius = UDim.new(0, 6); nc.Parent = n
    local ns = Instance.new("UIStroke"); ns.Color = Color3.fromRGB(220, 50, 80); ns.Thickness = 1; ns.Parent = n

    local nl = Instance.new("TextLabel")
    nl.Size = UDim2.new(1, -20, 1, 0)
    nl.Position = UDim2.new(0, 10, 0, 0)
    nl.BackgroundTransparency = 1
    nl.Text = text
    nl.TextColor3 = Color3.fromRGB(200, 200, 220)
    nl.TextSize = 12
    nl.Font = Enum.Font.GothamMedium
    nl.TextXAlignment = Enum.TextXAlignment.Left
    nl.TextWrapped = true
    nl.Parent = n

    n.Size = UDim2.new(1, 0, 0, 32)
    TweenService:Create(n, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 36)}):Play()

    task.delay(duration, function()
        TweenService:Create(n, TweenInfo.new(0.3), {Size = UDim2.new(1, 0, 0, 0)}):Play()
        task.wait(0.3)
        n:Destroy()
    end)
    end)
end

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 540, 0, 480)
MainFrame.Position = UDim2.new(0.5, -270, 0.5, -240)
MainFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 32)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(220, 50, 80)
MainStroke.Thickness = 1.5
MainStroke.Parent = MainFrame

-- Header
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 40)
Header.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 8)
HeaderCorner.Parent = Header

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "Title"
TitleLabel.Size = UDim2.new(1, -80, 1, 0)
TitleLabel.Position = UDim2.new(0, 15, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "Spad Hub"
TitleLabel.TextColor3 = Color3.fromRGB(220, 50, 80)
TitleLabel.TextSize = 18
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = Header

local CloseButton = Instance.new("TextButton")
CloseButton.Name = "CloseButton"
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(1, -38, 0, 5)
CloseButton.BackgroundColor3 = Color3.fromRGB(180, 40, 60)
CloseButton.BorderSizePixel = 0
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseButton.TextSize = 14
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Parent = Header

local CloseBtnCorner = Instance.new("UICorner")
CloseBtnCorner.CornerRadius = UDim.new(0, 6)
CloseBtnCorner.Parent = CloseButton

CloseButton.MouseEnter:Connect(function()
    TweenService:Create(CloseButton, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(220, 60, 80)}):Play()
end)

CloseButton.MouseLeave:Connect(function()
    TweenService:Create(CloseButton, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(180, 40, 60)}):Play()
end)

-- Tab Container
local TabContainer = Instance.new("Frame")
TabContainer.Name = "TabContainer"
TabContainer.Size = UDim2.new(1, -20, 0, 35)
TabContainer.Position = UDim2.new(0, 10, 0, 48)
TabContainer.BackgroundTransparency = 1
TabContainer.Parent = MainFrame

local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.Padding = UDim.new(0, 5)
TabLayout.Parent = TabContainer

local TabNames = {"Farm", "Auto", "Player", "Teleport", "Misc", "Contact"}
local TabButtons = {}
local TabPages = {}

-- Page container
local PageContainer = Instance.new("Frame")
PageContainer.Name = "PageContainer"
PageContainer.Size = UDim2.new(1, -20, 1, -24)
PageContainer.Position = UDim2.new(0, 10, 0, 90)
PageContainer.BackgroundTransparency = 1
PageContainer.Parent = MainFrame

-- Create tab buttons and pages
for i, tabName in ipairs(TabNames) do
    local TabBtn = Instance.new("TextButton")
    TabBtn.Name = tabName
    TabBtn.Size = UDim2.new(0, 75, 1, 0)
    TabBtn.BackgroundColor3 = (i == 1) and Color3.fromRGB(220, 50, 80) or Color3.fromRGB(40, 40, 55)
    TabBtn.BorderSizePixel = 0
    TabBtn.Text = tabName
    TabBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
    TabBtn.TextSize = 13
    TabBtn.Font = Enum.Font.GothamMedium
    TabBtn.Parent = TabContainer
    TabBtn.LayoutOrder = i
    TabBtn.AutoButtonColor = false

    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 6)
    BtnCorner.Parent = TabBtn

    TabBtn.MouseEnter:Connect(function()
        if TabBtn.BackgroundColor3 ~= Color3.fromRGB(220, 50, 80) then
            TweenService:Create(TabBtn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(55, 55, 70)}):Play()
        end
    end)
    TabBtn.MouseLeave:Connect(function()
        if TabBtn.BackgroundColor3 ~= Color3.fromRGB(220, 50, 80) then
            TweenService:Create(TabBtn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(40, 40, 55)}):Play()
        end
    end)

    TabButtons[tabName] = TabBtn

    local Page = Instance.new("ScrollingFrame")
    Page.Name = tabName .. "Page"
    Page.Size = UDim2.new(1, 0, 1, 0)
    Page.BackgroundTransparency = 1
    Page.ScrollBarThickness = 6
    Page.ScrollBarImageColor3 = Color3.fromRGB(220, 50, 80)
    Page.ScrollBarImageTransparency = 0.4
    Page.CanvasSize = UDim2.new(0, 0, 0, 0)
    Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Page.Visible = (i == 1)
    Page.Parent = PageContainer

    local PageLayout = Instance.new("UIListLayout")
    PageLayout.Padding = UDim.new(0, 6)
    PageLayout.Parent = Page

    local PagePadding = Instance.new("UIPadding")
    PagePadding.PaddingTop = UDim.new(0, 4)
    PagePadding.PaddingBottom = UDim.new(0, 10)
    PagePadding.Parent = Page

    TabPages[tabName] = Page
end

-- ========================
-- GUI HELPER COMPONENTS
-- ========================

local function CreateSection(parent, text)
    local Section = Instance.new("Frame")
    Section.Size = UDim2.new(1, 0, 0, 22)
    Section.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    Section.BorderSizePixel = 0
    Section.Parent = parent

    local SCorner = Instance.new("UICorner")
    SCorner.CornerRadius = UDim.new(0, 5)
    SCorner.Parent = Section

    local Accent = Instance.new("Frame")
    Accent.Size = UDim2.new(0, 3, 0, 14)
    Accent.Position = UDim2.new(0, 6, 0.5, -7)
    Accent.BackgroundColor3 = Color3.fromRGB(220, 50, 80)
    Accent.BorderSizePixel = 0
    Accent.Parent = Section
    local AccentCorner = Instance.new("UICorner"); AccentCorner.CornerRadius = UDim.new(1, 0); AccentCorner.Parent = Accent

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -16, 1, 0)
    Label.Position = UDim2.new(0, 14, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(200, 200, 220)
    Label.TextSize = 12
    Label.Font = Enum.Font.GothamBold
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Section

    return Section
end

local function CreateToggle(parent, text, callback, default)
    default = default or false

    local ToggleFrame = Instance.new("Frame")
    ToggleFrame.Size = UDim2.new(1, 0, 0, 28)
    ToggleFrame.BackgroundColor3 = Color3.fromRGB(32, 32, 48)
    ToggleFrame.BorderSizePixel = 0
    ToggleFrame.Parent = parent

    local TFCorner = Instance.new("UICorner")
    TFCorner.CornerRadius = UDim.new(0, 5)
    TFCorner.Parent = ToggleFrame

    local ToggleLabel = Instance.new("TextLabel")
    ToggleLabel.Size = UDim2.new(1, -50, 1, 0)
    ToggleLabel.Position = UDim2.new(0, 10, 0, 0)
    ToggleLabel.BackgroundTransparency = 1
    ToggleLabel.Text = text
    ToggleLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
    ToggleLabel.TextSize = 12
    ToggleLabel.Font = Enum.Font.Gotham
    ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
    ToggleLabel.Parent = ToggleFrame

    local ToggleBG = Instance.new("Frame")
    ToggleBG.Name = "ToggleBG"
    ToggleBG.Size = UDim2.new(0, 40, 0, 22)
    ToggleBG.Position = UDim2.new(1, -48, 0.5, -11)
    ToggleBG.BackgroundColor3 = default and Color3.fromRGB(220, 50, 80) or Color3.fromRGB(60, 60, 75)
    ToggleBG.BorderSizePixel = 0
    ToggleBG.Parent = ToggleFrame

    local TBCorner = Instance.new("UICorner")
    TBCorner.CornerRadius = UDim.new(1, 0)
    TBCorner.Parent = ToggleBG

    local ToggleCircle = Instance.new("Frame")
    ToggleCircle.Name = "Circle"
    ToggleCircle.Size = UDim2.new(0, 16, 0, 16)
    ToggleCircle.Position = default and UDim2.new(1, -18, 0, 2) or UDim2.new(0, 2, 0, 2)
    ToggleCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ToggleCircle.BorderSizePixel = 0
    ToggleCircle.Parent = ToggleBG

    local TCCorner = Instance.new("UICorner")
    TCCorner.CornerRadius = UDim.new(1, 0)
    TCCorner.Parent = ToggleCircle

    local state = default

    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(1, 0, 1, 0)
    ToggleBtn.BackgroundTransparency = 1
    ToggleBtn.Text = ""
    ToggleBtn.Parent = ToggleFrame

    ToggleBtn.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(ToggleBG, TweenInfo.new(0.18), {BackgroundColor3 = state and Color3.fromRGB(220, 50, 80) or Color3.fromRGB(60, 60, 75)}):Play()
        TweenService:Create(ToggleCircle, TweenInfo.new(0.18), {Position = state and UDim2.new(1, -18, 0, 2) or UDim2.new(0, 2, 0, 2)}):Play()
        callback(state)
        notify((state and "ON" or "OFF") .. ": " .. text, 1.5)
    end)

    return ToggleFrame, function() return state end, function(v)
        state = v
        TweenService:Create(ToggleBG, TweenInfo.new(0.2), {BackgroundColor3 = v and Color3.fromRGB(220, 50, 80) or Color3.fromRGB(60, 60, 75)}):Play()
        TweenService:Create(ToggleCircle, TweenInfo.new(0.2), {Position = v and UDim2.new(1, -18, 0, 2) or UDim2.new(0, 2, 0, 2)}):Play()
    end
end

local function CreateSlider(parent, text, min, max, default, callback, step)
    default = default or min
    step = step or 1

    local SliderFrame = Instance.new("Frame")
    SliderFrame.Size = UDim2.new(1, 0, 0, 40)
    SliderFrame.BackgroundColor3 = Color3.fromRGB(32, 32, 48)
    SliderFrame.BorderSizePixel = 0
    SliderFrame.Parent = parent

    local SFCorner = Instance.new("UICorner")
    SFCorner.CornerRadius = UDim.new(0, 5)
    SFCorner.Parent = SliderFrame

    local SliderLabel = Instance.new("TextLabel")
    SliderLabel.Size = UDim2.new(0.5, 0, 0, 20)
    SliderLabel.Position = UDim2.new(0, 10, 0, 2)
    SliderLabel.BackgroundTransparency = 1
    SliderLabel.Text = text
    SliderLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
    SliderLabel.TextSize = 12
    SliderLabel.Font = Enum.Font.Gotham
    SliderLabel.TextXAlignment = Enum.TextXAlignment.Left
    SliderLabel.Parent = SliderFrame

    local ValueLabel = Instance.new("TextLabel")
    ValueLabel.Size = UDim2.new(0.5, -10, 0, 20)
    ValueLabel.Position = UDim2.new(0.5, 0, 0, 2)
    ValueLabel.BackgroundTransparency = 1
    ValueLabel.Text = string.format("%.3f", default)
    ValueLabel.TextColor3 = Color3.fromRGB(220, 50, 80)
    ValueLabel.TextSize = 12
    ValueLabel.Font = Enum.Font.GothamBold
    ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
    ValueLabel.Parent = SliderFrame

    local SliderBG = Instance.new("Frame")
    SliderBG.Size = UDim2.new(1, -20, 0, 16)
    SliderBG.Position = UDim2.new(0, 10, 0, 24)
    SliderBG.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    SliderBG.BorderSizePixel = 0
    SliderBG.Parent = SliderFrame

    local SBGCorner = Instance.new("UICorner")
    SBGCorner.CornerRadius = UDim.new(1, 0)
    SBGCorner.Parent = SliderBG

    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    Fill.BackgroundColor3 = Color3.fromRGB(220, 50, 80)
    Fill.BorderSizePixel = 0
    Fill.Parent = SliderBG

    local FillCorner = Instance.new("UICorner")
    FillCorner.CornerRadius = UDim.new(1, 0)
    FillCorner.Parent = Fill

    local Thumb = Instance.new("Frame")
    Thumb.Size = UDim2.new(0, 20, 0, 20)
    Thumb.Position = UDim2.new((default - min) / (max - min), -10, 0.5, -10)
    Thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Thumb.BorderSizePixel = 0
    Thumb.ZIndex = 2
    Thumb.Parent = SliderBG

    local TCorner = Instance.new("UICorner")
    TCorner.CornerRadius = UDim.new(1, 0)
    TCorner.Parent = Thumb

    local current = default
    local dragging = false

    local SliderBtn = Instance.new("TextButton")
    SliderBtn.Size = UDim2.new(1, 0, 1, 0)
    SliderBtn.BackgroundTransparency = 1
    SliderBtn.Text = ""
    SliderBtn.ZIndex = 3
    SliderBtn.Parent = SliderBG

    SliderBtn.MouseButton1Down:Connect(function()
        dragging = true
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local absPos = SliderBG.AbsolutePosition.X
            local absSize = SliderBG.AbsoluteSize.X
            local mouseX = input.Position.X
            local pct = math.clamp((mouseX - absPos) / absSize, 0, 1)
            local raw = min + (max - min) * pct
            current = math.floor(raw / step + 0.5) * step
            current = math.clamp(current, min, max)
            local drawPct = (current - min) / (max - min)
            Fill.Size = UDim2.new(drawPct, 0, 1, 0)
            Thumb.Position = UDim2.new(drawPct, -10, 0.5, -10)
            ValueLabel.Text = string.format("%.3f", current)
            callback(current)
        end
    end)

    return SliderFrame, function() return current end
end

local function CreateButton(parent, text, callback)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 0, 32)
    Btn.BackgroundColor3 = Color3.fromRGB(34, 34, 50)
    Btn.BorderSizePixel = 0
    Btn.Text = text
    Btn.TextColor3 = Color3.fromRGB(200, 200, 210)
    Btn.TextSize = 12
    Btn.Font = Enum.Font.GothamMedium
    Btn.AutoButtonColor = false
    Btn.Parent = parent

    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 5)
    BtnCorner.Parent = Btn

    Btn.MouseEnter:Connect(function()
        TweenService:Create(Btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(220, 50, 80)}):Play()
    end)
    Btn.MouseLeave:Connect(function()
        TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(34, 34, 50)}):Play()
    end)
    Btn.MouseButton1Click:Connect(callback)

    return Btn
end

local function CreateLabel(parent, text)
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, 0, 0, 22)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(160, 160, 180)
    Label.TextSize = 11
    Label.Font = Enum.Font.Gotham
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = parent
    return Label
end

-- ========================
-- TAB SWITCHING
-- ========================

local function switchTab(tabName)
    for name, btn in pairs(TabButtons) do
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = (name == tabName) and Color3.fromRGB(220, 50, 80) or Color3.fromRGB(40, 40, 55)}):Play()
    end
    for name, page in pairs(TabPages) do
        page.Visible = (name == tabName)
    end
end

for name, btn in pairs(TabButtons) do
    btn.MouseButton1Click:Connect(function() switchTab(name) end)
end

-- ========================
-- DRAGGABLE HEADER
-- ========================

local dragging = false
local dragStart = nil
local startPos = nil

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- ========================
-- CLOSE BUTTON & TOGGLE KEY
-- ========================

local function toggleMenu()
    MenuOpen = not MenuOpen
    MainFrame.Visible = MenuOpen
end

CloseButton.MouseButton1Click:Connect(function()
    MenuOpen = false
    MainFrame.Visible = false
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == MenuKey then
        toggleMenu()
    end
end)

-- ========================
-- FARM PAGE (with sub-tabs)
-- ========================

local FarmPage = TabPages["Farm"]

local farmCategories = {"Farm", "Dungeon", "Stats"}
local farmSubBtns = {}
local farmFrames = {}

local farmTabRow = Instance.new("Frame")
farmTabRow.Size = UDim2.new(1, 0, 0, 28)
farmTabRow.BackgroundTransparency = 1
farmTabRow.LayoutOrder = 0
farmTabRow.Parent = FarmPage

local farmRowLayout = Instance.new("UIListLayout")
farmRowLayout.FillDirection = Enum.FillDirection.Horizontal
farmRowLayout.Padding = UDim.new(0, 4)
farmRowLayout.Parent = farmTabRow

for i, catName in ipairs(farmCategories) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 110, 0, 26)
    btn.BackgroundColor3 = (i == 1) and Color3.fromRGB(220, 50, 80) or Color3.fromRGB(40, 40, 55)
    btn.BorderSizePixel = 0
    btn.Text = catName
    btn.TextColor3 = Color3.fromRGB(200, 200, 210)
    btn.TextSize = 11
    btn.Font = Enum.Font.GothamMedium
    btn.Parent = farmTabRow
    btn.LayoutOrder = i
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 5); c.Parent = btn
    farmSubBtns[catName] = btn

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 0)
    frame.BackgroundTransparency = 1
    frame.Visible = (i == 1)
    frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.LayoutOrder = i + 1
    frame.Parent = FarmPage
    local fl = Instance.new("UIListLayout"); fl.Padding = UDim.new(0, 4); fl.Parent = frame
    farmFrames[catName] = frame
end

local function switchFarmCategory(name)
    for n, btn in pairs(farmSubBtns) do
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = (n == name) and Color3.fromRGB(220, 50, 80) or Color3.fromRGB(40, 40, 55)}):Play()
    end
    for n, frame in pairs(farmFrames) do
        frame.Visible = (n == name)
    end
end

for n, btn in pairs(farmSubBtns) do
    btn.MouseButton1Click:Connect(function() switchFarmCategory(n) end)
end

-- ========================
-- FARM SUB-TAB
-- ========================

CreateSection(farmFrames["Farm"], "Auto Farm")

CreateToggle(farmFrames["Farm"], "Auto Farm (Quest + Kill)", function(v)
    AutoFarmEnabled = v
    if AutoFarmConnection then
        AutoFarmConnection:Disconnect()
        AutoFarmConnection = nil
    end
    if v then
        pcall(function() cancelQuest() end)
        local attackTimer = 0
        local questCooldown = 0
        local currentQuest = nil
        local targetMobName = nil
        local acceptingQuest = false
        local questBracketLevel = 0
        local lastLevel = getPlayerLevel()
        AutoFarmConnection = RunService.Heartbeat:Connect(function(dt)
            if not AutoFarmEnabled then return end
            local hrp = getHRP()
            if not hrp then return end

            questCooldown = questCooldown - dt
            if acceptingQuest then return end

            local level = getPlayerLevel()

            -- Detect rebirth: level dropped significantly
            if level < lastLevel - 500 then
                pcall(function() cancelQuest() end)
                currentQuest = nil
                targetMobName = nil
                questBracketLevel = 0
                questCooldown = 0
                notify("Rebirth detected, resetting quest", 2)
            end
            lastLevel = level

            local neededQuest = getBestQuestForLevel(level)
            if not neededQuest then neededQuest = QuestNPCs[1] end

            local needSwitch = false
            if not currentQuest then
                needSwitch = true
            elseif neededQuest.level ~= questBracketLevel then
                needSwitch = true
            end

            -- At max level, stop farming and let rebirth happen (only if auto-rebirth enabled)
            if level >= 22000 and AutoRebirthEnabled then
                return
            end

            if needSwitch then
                if questCooldown > 0 then return end
                if neededQuest.level > level then
                    questCooldown = 5
                    return
                end
                pcall(function() cancelQuest() end)
                currentQuest = nil
                targetMobName = nil
                acceptingQuest = true
                local qData = neededQuest
                warn("[Farm] ACCEPTING QUEST: " .. qData.name .. " Lv." .. qData.level)
                task.spawn(function()
                    local success, err = pcall(function()
                        teleportFreeze(CFrame.new(qData.pos + Vector3.new(0, 0, -2)))
                        task.wait(0.3)
                        local npcModel = nil
                        for try = 1, 5 do
                            npcModel = findQuestNPCModel(qData.name)
                            if not npcModel then
                                npcModel = findNearestQuestNPCAtPos(qData.pos)
                            end
                            if npcModel then break end
                            task.wait(0.3)
                        end
                        if not npcModel then
                            warn("[Farm] NPC not found: " .. qData.name)
                            acceptingQuest = false
                            questCooldown = 2
                            return
                        end
                        local hrpNPC = npcModel:FindFirstChild("HumanoidRootPart")
                        if hrpNPC then
                            teleportFreeze(CFrame.lookAt(
                                hrpNPC.Position + hrpNPC.CFrame.LookVector * 2,
                                hrpNPC.Position
                            ))
                        end
                        task.wait(0.2)
                        local accepted = false
                        for attempt = 1, 5 do
                            local hrp2 = getHRP()
                            if hrp2 and hrpNPC then
                                hrp2.Anchored = true
                                hrp2.CFrame = CFrame.lookAt(
                                    hrpNPC.Position + hrpNPC.CFrame.LookVector * 2,
                                    hrpNPC.Position
                                )
                                hrp2.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                                hrp2.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                                task.delay(0.5, function()
                                    if hrp2 and hrp2.Parent then
                                        hrp2.Anchored = false
                                    end
                                end)
                            end
                            pressEOnNPC(npcModel)
                            task.wait(0.5)
                            local qName = getQuestTargetName()
                            if qName and qName ~= "" and qName ~= "Title" and qName ~= "TEXT" then
                                accepted = true
                                targetMobName = qName
                                currentQuest = qData
                                questBracketLevel = qData.level
                                warn("[Farm] QUEST ACCEPTED: " .. qName)
                            end
                            if accepted then break end
                            task.wait(0.3)
                        end
                        if not accepted then
                            questCooldown = 3
                        end
                    end)
                    if not success then warn("[Farm] Quest accept error:", err) end
                    acceptingQuest = false
                end)
                return
            end

            -- STEP 2: We have correct quest — farm it
            if currentQuest and targetMobName then
                local mob = getNearestQuestMob(hrp.Position, 999999, targetMobName)
                if mob then
                    local mobHRP = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("Head")
                    if mobHRP then
                        safeCFrame(CFrame.lookAt(mobHRP.Position + Vector3.new(0, 6, 0), mobHRP.Position))
                        attackTimer = attackTimer + dt
                        skillTimer = skillTimer + dt
                        if attackTimer >= AttackDelay then
                            attackTimer = 0
                            pcall(function()
                                ensureWeaponEquipped()
                                local char = getCharacter()
                                for _, tool in ipairs(char:GetChildren()) do
                                    if tool:IsA("Tool") then
                                        tool:Activate()
                                        break
                                    end
                                end
                            end)
                        end
                        return
                    end
                else
                    attackTimer = 0
                    -- Quest might be done — check UI
                    local recheck = getQuestTargetName()
                    if not recheck or recheck == "" or recheck == "Title" or recheck == "TEXT" then
                        cancelQuest()
                        currentQuest = nil
                        targetMobName = nil
                        questCooldown = 2
                        return
                    end
                    -- Try to teleport toward matching mobs
                    local mobs = getAliveMobs()
                    local center = Vector3.new(0, 0, 0)
                    local count = 0
                    for _, m in ipairs(mobs) do
                        local mhrp = m:FindFirstChild("HumanoidRootPart") or m:FindFirstChild("Head")
                        if mhrp and m.Name:gsub("%s+", ""):lower() == targetMobName:gsub("%s+", ""):lower() then
                            center = center + mhrp.Position
                            count = count + 1
                        end
                    end
                    if count > 0 then
                        center = center / count
                        local hrp2 = getHRP()
                        if hrp2 and (hrp2.Position - center).Magnitude > 5 then
                            teleportFreeze(CFrame.new(center + Vector3.new(0, 3, 0)))
                        end
                    elseif currentQuest and currentQuest.pos then
                        local hrp2 = getHRP()
                        if hrp2 and (hrp2.Position - currentQuest.pos).Magnitude > 100 then
                            teleportFreeze(CFrame.new(currentQuest.pos + Vector3.new(0, 3, -2)))
                        end
                    end
                end
            end
        end)
    end
end)

CreateSlider(farmFrames["Farm"], "Attack Delay (s)", 0.05, 1.5, 0.15, function(v)
    AttackDelay = v
end, 0.001)

-- Dungeon sub-tab
local AutoKillEnabled = false
local AutoKillConn = nil
local CombatDist = 5
local AutoOpenMoon = false

CreateSection(farmFrames["Dungeon"], "Auto Kill")

CreateSlider(farmFrames["Dungeon"], "Combat Distance (studs)", 1, 20, 5, function(v)
    CombatDist = v
end, 0.5)

local killRefLabel = CreateLabel(farmFrames["Dungeon"], "Ref: looking...")

CreateToggle(farmFrames["Dungeon"], "Auto Kill (closest to rocket)", function(v)
    AutoKillEnabled = v
    if AutoKillConn then AutoKillConn:Disconnect(); AutoKillConn = nil end
    if v then
        notify("Auto Kill ON", 1.5)
        local targetMob = nil
        local attackTimer = 0
        local searchTimer = 0
        AutoKillConn = RunService.Heartbeat:Connect(function(dt)
            if not AutoKillEnabled then return end
            pcall(function()
                local hrp = getHRP()
                if not hrp then return end

                if searchTimer <= 0 then
                    local refPos = hrp.Position
                    local refLabel = "player"
                    local mobFolder = Workspace:FindFirstChild("Mob")

                    -- 1. Find RocketTower (recursive search, might be inside island folder)
                    local hitPart = Workspace:FindFirstChild("HitHere", true)
                    if hitPart and hitPart:IsA("BasePart") then
                        refPos = hitPart.Position
                        refLabel = "RocketTower"
                    end

                    -- 2. If no HitHere, try RocketTower directly
                    if refLabel == "player" then
                        local rt = Workspace:FindFirstChild("RocketTower", true)
                        if rt then
                            local hit = rt:FindFirstChild("HitHere", true)
                            if hit and hit:IsA("BasePart") then refPos = hit.Position; refLabel = "RocketTower" end
                        end
                    end

                    -- 3. Find BackEarth NPC or any NPC outside Mob
                    if refLabel == "player" then
                        for _, m in ipairs(Workspace:GetDescendants()) do
                            if m:IsA("Model") and m ~= LocalPlayer.Character then
                                local tn = m.Name:lower()
                                if tn:find("back") or tn:find("earth") then
                                    local r = m:FindFirstChild("HumanoidRootPart") or m:FindFirstChild("Head")
                                    if r then refPos = r.Position; refLabel = m.Name; break end
                                end
                            end
                        end
                    end

                    pcall(function() killRefLabel.Text = "Ref: " .. refLabel end)
                    -- Find nearest mob to reference point (ONLY inside workspace.Mob)
                    local best, bestD = nil, math.huge
                    local mobFolder = Workspace:FindFirstChild("Mob")
                    if mobFolder then
                        for _, m in ipairs(mobFolder:GetDescendants()) do
                            if m:IsA("Model") and m ~= LocalPlayer.Character then
                                local h = m:FindFirstChildOfClass("Humanoid")
                                local r = m:FindFirstChild("HumanoidRootPart") or m:FindFirstChild("Head")
                                if h and r and h.Health > 0 then
                                    local d = (refPos - r.Position).Magnitude
                                    if d < bestD then
                                        bestD = d; best = m
                                    end
                                end
                            end
                        end
                    end
                    targetMob = best
                    searchTimer = 0.3
                end
                searchTimer = searchTimer - dt
                if not targetMob then return end

                if targetMob == LocalPlayer.Character then targetMob = nil; return end

                local mobHRP = targetMob:FindFirstChild("HumanoidRootPart") or targetMob:FindFirstChild("Head")
                if not mobHRP then targetMob = nil; return end

                local hum = targetMob:FindFirstChildOfClass("Humanoid")
                if not hum or hum.Health <= 0 then targetMob = nil; return end

                local mobCF = mobHRP.CFrame
                local frontPos = mobCF.Position + mobCF.LookVector * CombatDist
                frontPos = Vector3.new(frontPos.X, mobCF.Y, frontPos.Z)

                hrp.CFrame = CFrame.lookAt(frontPos, mobCF.Position)
                hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)

                local char = hrp.Parent
                if char then
                    for _, part in ipairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then part.CanCollide = false end
                    end
                end

                attackTimer = attackTimer + dt
                if attackTimer >= AttackDelay then
                    attackTimer = 0
                    ensureWeaponEquipped()
                    if char then
                        for _, tool in ipairs(char:GetChildren()) do
                            if tool:IsA("Tool") then tool:Activate(); break end
                        end
                    end
                end
            end)
        end)
    end
end)

CreateSection(farmFrames["Dungeon"], "Event Moon")

CreateLabel(farmFrames["Dungeon"], "GoMoon NPC at (32, 5, -245)")

CreateButton(farmFrames["Dungeon"], "Teleport to GoMoon NPC", function()
    teleportTo(Vector3.new(32, 5, -245))
    notify("Teleported to GoMoon", 1.5)
end)

CreateToggle(farmFrames["Dungeon"], "Auto Open Event Moon", function(v)
    AutoOpenMoon = v
    if v then
        notify("Auto Open Event Moon ON", 1.5)
        task.spawn(function()
            while AutoOpenMoon do
                pcall(function()
                    local gomoon = workspace:FindFirstChild("NpcPrompt") and workspace.NpcPrompt:FindFirstChild("GoMoon")
                    if not gomoon then return end
                    local hrpNPC = gomoon:FindFirstChild("HumanoidRootPart")
                    if not hrpNPC then return end
                    local hrp = getHRP()
                    if not hrp then return end

                    -- Step 1: Position in front of GoMoon and fire prompt to open portal
                    local posBefore = hrpNPC.Position + hrpNPC.CFrame.LookVector * 5
                    posBefore = Vector3.new(posBefore.X, hrpNPC.Position.Y, posBefore.Z)
                    hrp.CFrame = CFrame.lookAt(posBefore, hrpNPC.Position)
                    hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                    task.wait(0.3)

                    local prompt = hrpNPC:FindFirstChildOfClass("ProximityPrompt")
                    if prompt then
                        local oldHold = prompt.HoldDuration
                        prompt.HoldDuration = 0
                        task.wait(0.05)
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                        task.wait(0.5)
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                        task.wait(0.3)
                        prompt.HoldDuration = oldHold
                    end
                    task.wait(2)

                    -- Step 2: Look for portal and walk into it
                    local portal = workspace:FindFirstChild("Portal") or workspace:FindFirstChild("EventPortal") or workspace:FindFirstChild("MoonPortal")
                    if portal then
                        local pHRP = portal:FindFirstChild("HumanoidRootPart") or portal:FindFirstChild("Head")
                        if pHRP then
                            safeCFrame(CFrame.new(pHRP.Position + Vector3.new(0, 3, 0)))
                            task.wait(1)
                        end
                    else
                        -- Fallback: walk forward from NPC
                        local enterPos = hrpNPC.Position + hrpNPC.CFrame.LookVector * 18
                        enterPos = Vector3.new(enterPos.X, hrpNPC.Position.Y + 3, enterPos.Z)
                        safeCFrame(CFrame.new(enterPos))
                        task.wait(1)
                    end
                end)
                task.wait(8)
            end
        end)
    end
end)

CreateSection(farmFrames["Farm"], "Weapon")

local weaponTypes = {"Melee", "Sword", "Fruit", "Special"}
local weaponBtns = {}
local wepLabel = CreateLabel(farmFrames["Farm"], "Selected: Melee")

local wepRow = Instance.new("Frame")
wepRow.Size = UDim2.new(1, 0, 0, 26)
wepRow.BackgroundTransparency = 1
wepRow.Parent = farmFrames["Farm"]

local wepLayout = Instance.new("UIListLayout")
wepLayout.FillDirection = Enum.FillDirection.Horizontal
wepLayout.Padding = UDim.new(0, 4)
wepLayout.VerticalAlignment = Enum.VerticalAlignment.Center
wepLayout.Parent = wepRow

for i, wt in ipairs(weaponTypes) do
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.25, -3, 0, 22)
    b.BackgroundColor3 = (i == 1) and Color3.fromRGB(220, 50, 80) or Color3.fromRGB(40, 40, 55)
    b.BorderSizePixel = 0; b.Text = wt
    b.TextColor3 = Color3.fromRGB(200, 200, 210); b.TextSize = 10
    b.Font = Enum.Font.GothamBold; b.Parent = wepRow
    local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 4); bc.Parent = b
    weaponBtns[wt] = b
    b.MouseButton1Click:Connect(function()
        SelectedWeapon = wt
        wepLabel.Text = "Selected: " .. wt
        notify("Weapon: " .. wt, 1.5)
        for _, wb in pairs(weaponBtns) do
            local isSelected = (wb == b)
            TweenService:Create(wb, TweenInfo.new(0.12), {
                BackgroundColor3 = isSelected and Color3.fromRGB(220, 50, 80) or Color3.fromRGB(40, 40, 55)
            }):Play()
        end
    end)
end

CreateSection(farmFrames["Farm"], "Skills")


local skillRow = Instance.new("Frame")
skillRow.Size = UDim2.new(1, 0, 0, 26)
skillRow.BackgroundTransparency = 1
skillRow.Parent = farmFrames["Farm"]

local skillRowLayout = Instance.new("UIListLayout")
skillRowLayout.FillDirection = Enum.FillDirection.Horizontal
skillRowLayout.Padding = UDim.new(0, 3)
skillRowLayout.VerticalAlignment = Enum.VerticalAlignment.Center
skillRowLayout.Parent = skillRow

for i, sk in ipairs(skillKeysList) do
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 42, 0, 22)
    b.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    b.BorderSizePixel = 0; b.Text = sk
    b.TextColor3 = Color3.fromRGB(200, 200, 210); b.TextSize = 10
    b.Font = Enum.Font.GothamBold; b.Parent = skillRow
    local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 4); bc.Parent = b
    autoSkills[sk] = false
    b.MouseButton1Click:Connect(function()
        autoSkills[sk] = not autoSkills[sk]
        TweenService:Create(b, TweenInfo.new(0.12), {
            BackgroundColor3 = autoSkills[sk] and Color3.fromRGB(220, 50, 80) or Color3.fromRGB(40, 40, 55),
            TextColor3 = autoSkills[sk] and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 210)
        }):Play()
    end)
end

-- Independent skill loop (runs separately from auto farm)
task.spawn(function()
    while task.wait(0.1) do
        pcall(function()
            local anyActive = false
            for _, enabled in pairs(autoSkills) do
                if enabled then anyActive = true; break end
            end
            if not anyActive then skillTimer = 0; return end

            if skillTimer >= skillDelay then
                skillTimer = 0
                for sk, enabled in pairs(autoSkills) do
                    if enabled and skillKeyMap[sk] then
                        pcall(function()
                            VirtualInputManager:SendKeyEvent(true, skillKeyMap[sk], false, game)
                            VirtualInputManager:SendKeyEvent(false, skillKeyMap[sk], false, game)
                        end)
                    end
                end
            end
            skillTimer = skillTimer + 0.1
        end)
    end
end)

-- ========================
-- STATS SUB-TAB
-- ========================

local AutoStatsEnabled = false
local AutoStatsThread = nil
local TargetLevel = 22000

local statKeys = {"Melee", "Defense", "Sword", "Power"}
local statNames = {"Melee", "Defense", "Sword", "Fruit"}

local function getStatGui()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return nil end
    local hud = pg:FindFirstChild("HUD") or pg:FindFirstChild("Hud")
    if not hud then return nil end
    local main = hud:FindFirstChild("Main")
    if not main then return nil end
    return main:FindFirstChild("Frame_Stats")
end

local function getStatsPoints()
    local ok, result = pcall(function()
        local fs = getStatGui()
        if not fs then return 0 end
        local stats = fs:FindFirstChild("Stats")
        if not stats then return 0 end
        local tl = stats:FindFirstChild("TextLabel")
        if tl and tl:IsA("TextLabel") then
            local n = tl.Text:match("Points:%s*(%d+)")
            if n then return tonumber(n) end
        end
        return 0
    end)
    return ok and result or 0
end

local function getStatLevel(statKey)
    local ok, result = pcall(function()
        local fs = getStatGui()
        if not fs then return 0 end
        local stats = fs:FindFirstChild("Stats")
        if not stats then return 0 end
        local frame = stats:FindFirstChild("Frame")
        if not frame then return 0 end
        local sf = frame:FindFirstChild(statKey)
        if not sf then return 0 end
        local pt = sf:FindFirstChild("Pt")
        if pt and pt:IsA("TextLabel") then
            local n = pt.Text:match("(%d+)")
            if n then return tonumber(n) end
        end
        return 0
    end)
    return ok and result or 0
end

local function upgradeStat(statKey, amount)
    amount = amount or 1
    pcall(function()
        local fs = getStatGui()
        if not fs then return end
        local stats = fs:FindFirstChild("Stats")
        if not stats then return end
        local frame = stats:FindFirstChild("Frame")
        if not frame then return end
        local sf = frame:FindFirstChild(statKey)
        if not sf then return end
        local plusBtn = sf:FindFirstChild("Plus")
        if not plusBtn then return end
        local box = stats:FindFirstChild("Box")
        local textBox = box and box:FindFirstChild("TextBox")
        if not textBox then return end

        textBox.Text = tostring(amount)
        task.wait(0.03)

        if getconnections then
            pcall(function()
                for _, conn in ipairs(getconnections(textBox.FocusLost)) do conn:Fire() end
                for _, conn in ipairs(getconnections(plusBtn.MouseButton1Click)) do conn:Fire() end
                for _, conn in ipairs(getconnections(plusBtn.Activated)) do conn:Fire() end
            end)
        end
        if firesignal then
            pcall(function() firesignal(plusBtn.MouseButton1Click) end)
            pcall(function() firesignal(plusBtn.Activated) end)
        end
    end)
end

-- Points + slider
local ptsSection = CreateSection(farmFrames["Stats"], "Points: --")
local statPointsLabel = ptsSection:FindFirstChildOfClass("TextLabel")
CreateSlider(farmFrames["Stats"], "Target Level", 100, 22000, 22000, function(v)
    TargetLevel = math.floor(v)
end, 1)

-- Priority — compact single row
CreateSection(farmFrames["Stats"], "Priority (click # to assign)")
local priorityOrder = {"Melee", "Defense", "Sword", "Power"}
local nameLookup = {Melee="Melee", Defense="Defense", Sword="Sword", Power="Fruit"}
local statList = {"Melee", "Defense", "Sword", "Power"}

local priorityRow = Instance.new("Frame")
priorityRow.Size = UDim2.new(1, 0, 0, 26)
priorityRow.BackgroundTransparency = 1
priorityRow.Parent = farmFrames["Stats"]

local prioLayout = Instance.new("UIListLayout")
prioLayout.FillDirection = Enum.FillDirection.Horizontal
prioLayout.Padding = UDim.new(0, 4)
prioLayout.VerticalAlignment = Enum.VerticalAlignment.Center
prioLayout.Parent = priorityRow

local prioBtns = {}
local function rebuildPrio()
    for _, v in ipairs(priorityRow:GetChildren()) do
        if v:IsA("TextButton") then v:Destroy() end
    end
    for slot, sn in ipairs(priorityOrder) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0.25, -3, 0, 22)
        b.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
        b.BorderSizePixel = 0
        b.Text = slot .. ": " .. nameLookup[sn]
        b.TextColor3 = Color3.fromRGB(200, 200, 210)
        b.TextSize = 9
        b.Font = Enum.Font.GothamBold
        b.Parent = priorityRow
        local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 4); bc.Parent = b
        b.MouseButton1Click:Connect(function()
            local currentStat = priorityOrder[slot]
            local currentIdx = 1
            for i, s in ipairs(statKeys) do
                if s == currentStat then currentIdx = i; break end
            end
            local nextIdx = (currentIdx % #statKeys) + 1
            local nextStat = statKeys[nextIdx]
            local nextSlot = nil
            for s, sn in ipairs(priorityOrder) do
                if sn == nextStat then nextSlot = s; break end
            end
            if nextSlot then
                priorityOrder[slot] = nextStat
                priorityOrder[nextSlot] = currentStat
            else
                priorityOrder[slot] = nextStat
            end
            rebuildPrio()
        end)
    end
end
rebuildPrio()

-- Auto toggle
CreateToggle(farmFrames["Stats"], "Auto (follows priority 1→2→3→4)", function(v)
    AutoStatsEnabled = v
    if AutoStatsThread then task.cancel(AutoStatsThread); AutoStatsThread = nil end
    if v then
        local idx = 1
        local prevLevels = {}
        AutoStatsThread = task.spawn(function()
            while AutoStatsEnabled do
                pcall(function()
                    local points = getStatsPoints()
                    if points <= 0 then return end
                    for _, sn in ipairs(statKeys) do
                        local cl = getStatLevel(sn)
                        if prevLevels[sn] and prevLevels[sn] > 1 and cl == 1 then
                            idx = 1
                        end
                        prevLevels[sn] = cl
                    end
                    local sn = priorityOrder[idx]
                    local lvl = getStatLevel(sn)
                    if lvl >= TargetLevel then idx = idx % #priorityOrder + 1; return end
                    local toAdd = math.min(points, TargetLevel - lvl)
                    if toAdd > 0 then upgradeStat(sn, toAdd) end
                end)
                task.wait(0.3)
            end
        end)
    end
end)

-- Stats Overview (fixed size, no AutomaticSize)
CreateSection(farmFrames["Stats"], "Stats Overview")

local statOverviewFrame = Instance.new("Frame")
statOverviewFrame.Size = UDim2.new(1, 0, 0, 95)
statOverviewFrame.BackgroundTransparency = 1
statOverviewFrame.Parent = farmFrames["Stats"]

local soLayout = Instance.new("UIListLayout")
soLayout.Padding = UDim.new(0, 4)
soLayout.Parent = statOverviewFrame

local statDisplays = {}
for i, sn in ipairs(statKeys) do
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 22)
    card.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
    card.BorderSizePixel = 0
    card.Parent = statOverviewFrame
    local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0, 6); cc.Parent = card
    local cs = Instance.new("UIStroke"); cs.Color = Color3.fromRGB(220, 50, 80); cs.Thickness = 0; cs.Parent = card

    local nl = Instance.new("TextLabel")
    nl.Size = UDim2.new(0, 60, 0, 10); nl.Position = UDim2.new(0, 8, 0, 1)
    nl.BackgroundTransparency = 1; nl.Text = statNames[i]
    nl.TextColor3 = Color3.fromRGB(200, 200, 220); nl.TextSize = 10
    nl.Font = Enum.Font.GothamBold; nl.TextXAlignment = Enum.TextXAlignment.Left; nl.Parent = card

    local ll = Instance.new("TextLabel")
    ll.Size = UDim2.new(1, -70, 0, 10); ll.Position = UDim2.new(0, 70, 0, 1)
    ll.BackgroundTransparency = 1; ll.Text = "0 / " .. TargetLevel
    ll.TextColor3 = Color3.fromRGB(220, 50, 80); ll.TextSize = 9
    ll.Font = Enum.Font.GothamBold; ll.TextXAlignment = Enum.TextXAlignment.Right; ll.Parent = card

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, -14, 0, 8); bg.Position = UDim2.new(0, 7, 0, 13)
    bg.BackgroundColor3 = Color3.fromRGB(45, 45, 60); bg.BorderSizePixel = 0; bg.Parent = card
    local bgc = Instance.new("UICorner"); bgc.CornerRadius = UDim.new(1, 0); bgc.Parent = bg

    local bf = Instance.new("Frame")
    bf.Size = UDim2.new(0, 0, 1, 0)
    bf.BackgroundColor3 = Color3.fromRGB(220, 50, 80); bf.BorderSizePixel = 0; bf.Parent = bg
    local bfc = Instance.new("UICorner"); bfc.CornerRadius = UDim.new(1, 0); bfc.Parent = bf

    local dl = Instance.new("TextLabel")
    dl.Size = UDim2.new(1, -14, 0, 8); dl.Position = UDim2.new(0, 7, 0, 13)
    dl.BackgroundTransparency = 1; dl.Text = "DONE"
    dl.TextColor3 = Color3.fromRGB(120, 200, 120); dl.TextSize = 7
    dl.Font = Enum.Font.GothamBold; dl.Visible = false; dl.Parent = card

    statDisplays[sn] = {card=card, level=ll, barFill=bf, barBg=bg, doneLabel=dl, stroke=cs}
end

task.spawn(function()
    while task.wait(1) do
        pcall(function()
            local pts = getStatsPoints()
            statPointsLabel.Text = "Points: " .. pts
            for i, sn in ipairs(statKeys) do
                local lvl = getStatLevel(sn)
                local d = statDisplays[sn]
                if d then
                    local done = lvl >= TargetLevel
                    local pct = math.min(lvl / TargetLevel, 1)
                    d.level.Text = lvl .. " / " .. TargetLevel
                    d.barFill.Size = UDim2.new(pct, 0, 1, 0)
                    if done then
                        d.barFill.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
                        d.stroke.Thickness = 1; d.stroke.Color = Color3.fromRGB(80, 180, 80)
                        d.doneLabel.Visible = true
                    else
                        d.barFill.BackgroundColor3 = Color3.fromRGB(220, 50, 80)
                        d.stroke.Thickness = 0; d.doneLabel.Visible = false
                    end
                end
            end
        end)
    end
end)

-- ========================
-- AUTO PAGE
-- ========================

local AutoPage = TabPages["Auto"]

local autoCategories = {"Chests", "Potion", "Rebirth"}
local autoSubBtns = {}
local autoFrames = {}

local autoTabRow = Instance.new("Frame")
autoTabRow.Size = UDim2.new(1, 0, 0, 28)
autoTabRow.BackgroundTransparency = 1
autoTabRow.LayoutOrder = 0
autoTabRow.Parent = AutoPage

local autoRowLayout = Instance.new("UIListLayout")
autoRowLayout.FillDirection = Enum.FillDirection.Horizontal
autoRowLayout.Padding = UDim.new(0, 4)
autoRowLayout.Parent = autoTabRow

for i, catName in ipairs(autoCategories) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 110, 0, 26)
    btn.BackgroundColor3 = (i == 1) and Color3.fromRGB(220, 50, 80) or Color3.fromRGB(40, 40, 55)
    btn.BorderSizePixel = 0
    btn.Text = catName
    btn.TextColor3 = Color3.fromRGB(200, 200, 210)
    btn.TextSize = 11
    btn.Font = Enum.Font.GothamMedium
    btn.Parent = autoTabRow
    btn.LayoutOrder = i
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 5); c.Parent = btn
    autoSubBtns[catName] = btn

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 0)
    frame.BackgroundTransparency = 1
    frame.Visible = (i == 1)
    frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.LayoutOrder = i + 1
    frame.Parent = AutoPage
    local fl = Instance.new("UIListLayout"); fl.Padding = UDim.new(0, 4); fl.Parent = frame
    autoFrames[catName] = frame
end

local function switchAutoCategory(name)
    for n, btn in pairs(autoSubBtns) do
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = (n == name) and Color3.fromRGB(220, 50, 80) or Color3.fromRGB(40, 40, 55)}):Play()
    end
    for n, frame in pairs(autoFrames) do
        frame.Visible = (n == name)
    end
end

for n, btn in pairs(autoSubBtns) do
    btn.MouseButton1Click:Connect(function() switchAutoCategory(n) end)
end

local function openChest(frameName, x15BtnName)
    pcall(function()
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        local hud = pg and (pg:FindFirstChild("HUD") or pg:FindFirstChild("Hud"))
        local main = hud and hud:FindFirstChild("Main")
        local chestFrame = main and main:FindFirstChild(frameName)
        if not chestFrame then return end

        local display = chestFrame:FindFirstChild("DisplayFrame")
        local x15 = display and display:FindFirstChild(x15BtnName)
        if not x15 then return end

        if getconnections then
            for _, conn in ipairs(getconnections(x15.MouseButton1Click)) do
                conn:Fire()
            end
        end
        if firesignal then
            pcall(function() firesignal(x15.MouseButton1Click) end)
        end
    end)
end

local AutoDiamondChest = false
local AutoMoonChest = false

CreateSection(autoFrames["Chests"], "Auto Open Chest")

CreateToggle(autoFrames["Chests"], "Auto Open Chest Diamond (15x)", function(v)
    AutoDiamondChest = v
    if v then
        notify("Auto Open Diamond ON", 1.5)
        task.spawn(function()
            while AutoDiamondChest do
                openChest("Frame_RandomItem", "x15")
                task.wait(2)
            end
        end)
    end
end)

CreateToggle(autoFrames["Chests"], "Auto Open Chest Moon (15x)", function(v)
    AutoMoonChest = v
    if v then
        notify("Auto Open Moon ON", 1.5)
        task.spawn(function()
            while AutoMoonChest do
                openChest("Frame_EventMoon", "x15")
                task.wait(2)
            end
        end)
    end
end)

CreateSection(autoFrames["Potion"], "Auto Use Potions (15min each)")

local potionMap = {
    ["X2 Rebirth"] = "x2Rebirth",
    ["X2 EXP"] = "x2Exp", 
    ["X2 Lucky"] = "x2Luck",
    ["X2 Item"] = "x2Item",
    ["X2 Diamond"] = "x2Diamond",
}
local potionEnabled = {}
local potionLoops = {}

local function isPotionActive(tag)
    local active = false
    pcall(function()
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        local hud = pg and (pg:FindFirstChild("HUD") or pg:FindFirstChild("Hud"))
        local main = hud and hud:FindFirstChild("Main")
        local x2d = main and main:FindFirstChild("Frame_x2Display")
        if x2d then
            local buf = x2d:FindFirstChild(tag)
            if buf then
                local tl = buf:FindFirstChild("Frame") and buf.Frame:FindFirstChild("TextLabel")
                if tl and tl:IsA("TextLabel") then
                    local txt = (tl.Text or ""):gsub("%s", "")
                    if txt == "" or txt == "0:0" or txt == "00:00" or txt == "00:00:00" then
                        active = false
                    else
                        local h, m, s = txt:match("(%d+):(%d+):(%d+)")
                        if h then
                            active = tonumber(h) * 3600 + tonumber(m) * 60 + tonumber(s) > 30
                        else
                            local m2, s2 = txt:match("(%d+):(%d+)")
                            if m2 then
                                active = tonumber(m2) * 60 + tonumber(s2) > 30
                            else
                                active = true
                            end
                        end
                    end
                end
            end
        end
    end)
    return active
end

local function usePotion(name)
    local ok, err = pcall(function()
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        local hud = pg and (pg:FindFirstChild("HUD") or pg:FindFirstChild("Hud"))
        local main = hud and hud:FindFirstChild("Main")
        if not main then notify("usePotion: no Main", 2) return end

        local inv = main:FindFirstChild("Frame_Inventory")
        if not inv then
            pcall(function()
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.I, false, game)
                task.wait(0.1)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.I, false, game)
            end)
            task.wait(0.5)
            inv = main:FindFirstChild("Frame_Inventory")
        end
        if not inv then notify("usePotion: no Inventory", 2) return end

        local items = {}
        for _, v in ipairs(inv:GetDescendants()) do
            if v and v:IsA("Frame") and v.Name and v.Name:lower():find(name:lower(), 1, true) then
                table.insert(items, v)
            end
        end

        local found = false
        for _, item in ipairs(items) do
            if item and item.Name and item.Parent then
                found = true
                local btn = item:FindFirstChild("Main") or item:FindFirstChildOfClass("TextButton") or item:FindFirstChildOfClass("ImageButton") or item
                pcall(function()
                    if getconnections then
                        for _, c in ipairs(getconnections(btn.MouseButton1Click)) do c:Fire() end
                    end
                    if firesignal then firesignal(btn.MouseButton1Click) end
                    if btn:IsA("GuiButton") then pcall(function() btn:Click() end) end
                end)
                task.wait(0.5)
                break
            end
        end
        if not found then notify("usePotion: item '" .. name .. "' not found", 2) return end

        local sure
        for _ = 1, 30 do
            task.wait(0.1)
            local alert = main:FindFirstChild("Frame_Alert")
            if alert then
                sure = alert:FindFirstChild("Sub_Alert") and alert.Sub_Alert:FindFirstChild("Frame") and alert.Sub_Alert.Frame:FindFirstChild("Sure") and alert.Sub_Alert.Frame.Sure:FindFirstChild("Sure")
                if sure then break end
            end
        end
        if not sure then notify("usePotion: no Sure button", 2) return end
        pcall(function()
            if getconnections then
                for _, c in ipairs(getconnections(sure.MouseButton1Click)) do c:Fire() end
            end
            if firesignal then firesignal(sure.MouseButton1Click) end
            if sure:IsA("GuiButton") then pcall(function() sure:Click() end) end
        end)
    end)
    if not ok then notify("usePotion error: " .. tostring(err), 3) end
end

local lastRebirthTime = 0

for _, pn in ipairs({"X2 Rebirth", "X2 EXP", "X2 Lucky", "X2 Item", "X2 Diamond"}) do
    local tag = potionMap[pn]
    potionEnabled[tag] = false

    CreateToggle(autoFrames["Potion"], "Auto Use " .. pn .. " 15m", function(v)
        potionEnabled[tag] = v
        if v then
            notify(pn .. " ON", 1.5)
            potionLoops[tag] = task.spawn(function()
                while potionEnabled[tag] do
                    pcall(function()
                        if tick() - lastRebirthTime < 15 then return end
                        if not isPotionActive(tag) then
                            usePotion(pn)
                            notify(pn .. " used!", 2)
                            task.wait(5)
                        end
                    end)
                    task.wait(15)
                end
            end)
        else
            if potionLoops[tag] then task.cancel(potionLoops[tag]); potionLoops[tag] = nil end
        end
    end)
end

-- ========================
-- REBIRTH
-- ========================

local AutoRebirthEnabled = false

CreateSection(autoFrames["Rebirth"], "Auto Rebirth")

CreateToggle(autoFrames["Rebirth"], "Auto Rebirth", function(v)
    AutoRebirthEnabled = v
    if v then
        notify("Auto Rebirth ON", 1.5)
        task.spawn(function()
            while AutoRebirthEnabled do
                pcall(function()
                    local pg = LocalPlayer:FindFirstChild("PlayerGui")
                    local hud = pg and (pg:FindFirstChild("HUD") or pg:FindFirstChild("Hud"))
                    local main = hud and hud:FindFirstChild("Main")
                    local stats = main and main:FindFirstChild("Frame_Stats")
                    local rebirthFrame = stats and stats:FindFirstChild("Rebirth")
                    local rebirthBtn = rebirthFrame and rebirthFrame:FindFirstChild("Rebirth")
                    if rebirthBtn and rebirthBtn.Visible then
                        local lvl = getPlayerLevel()
                        if lvl >= 22000 then
                            if getconnections then
                                for _, c in ipairs(getconnections(rebirthBtn.MouseButton1Click)) do
                                    c:Fire()
                                end
                            end
                            if firesignal then
                                pcall(function() firesignal(rebirthBtn.MouseButton1Click) end)
                            end
                            notify("Rebirth clicked! (Level: " .. lvl .. ")", 2)
                            task.wait(5)
                            -- Handle confirmation
                            local alert = main:FindFirstChild("Frame_Alert")
                            if alert then
                                for _, desc in ipairs(alert:GetDescendants()) do
                                    if (desc:IsA("TextButton") or desc:IsA("ImageButton")) and desc.Name == "Sure" and desc.Visible then
                                        if getconnections then
                                            for _, c in ipairs(getconnections(desc.MouseButton1Click)) do c:Fire() end
                                        end
                                        if firesignal then pcall(function() firesignal(desc.MouseButton1Click) end) end
                                        notify("Confirmed rebirth!", 2)
                                    end
                                end
                            end
                            lastRebirthTime = tick()
                            task.wait(5)
                        end
                    end
                end)
                task.wait(3)
            end
        end)
    else
        notify("Auto Rebirth OFF", 1.5)
    end
end)

-- ========================
-- PLAYER PAGE
-- ========================

local PlayerPage = TabPages["Player"]

local plCategories = {"ESP", "Character"}
local plSubBtns = {}
local plFrames = {}

local plTabRow = Instance.new("Frame")
plTabRow.Size = UDim2.new(1, 0, 0, 28)
plTabRow.BackgroundTransparency = 1
plTabRow.LayoutOrder = 0
plTabRow.Parent = PlayerPage

local plRowLayout = Instance.new("UIListLayout")
plRowLayout.FillDirection = Enum.FillDirection.Horizontal
plRowLayout.Padding = UDim.new(0, 4)
plRowLayout.Parent = plTabRow

for i, catName in ipairs(plCategories) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 110, 0, 26)
    btn.BackgroundColor3 = (i == 1) and Color3.fromRGB(220, 50, 80) or Color3.fromRGB(40, 40, 55)
    btn.BorderSizePixel = 0
    btn.Text = catName
    btn.TextColor3 = Color3.fromRGB(200, 200, 210)
    btn.TextSize = 11
    btn.Font = Enum.Font.GothamMedium
    btn.Parent = plTabRow
    btn.LayoutOrder = i
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 5); c.Parent = btn
    plSubBtns[catName] = btn

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 0)
    frame.BackgroundTransparency = 1
    frame.Visible = (i == 1)
    frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.LayoutOrder = i + 1
    frame.Parent = PlayerPage
    local fl = Instance.new("UIListLayout"); fl.Padding = UDim.new(0, 4); fl.Parent = frame
    plFrames[catName] = frame
end

local function switchPlCategory(name)
    for n, btn in pairs(plSubBtns) do
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = (n == name) and Color3.fromRGB(220, 50, 80) or Color3.fromRGB(40, 40, 55)}):Play()
    end
    for n, frame in pairs(plFrames) do
        frame.Visible = (n == name)
    end
end

for n, btn in pairs(plSubBtns) do
    btn.MouseButton1Click:Connect(function() switchPlCategory(n) end)
end

CreateSection(plFrames["ESP"], "ESP")

local function clearESP()
    for _, h in ipairs(ESPHighlights) do
        if h and h.Parent then
            h:Destroy()
        end
    end
    ESPHighlights = {}
    for _, c in ipairs(ESPConnections) do
        if c then c:Disconnect() end
    end
    ESPConnections = {}
end

local function createHighlight(parent, color, name)
    local existing = parent:FindFirstChild("_ESP_HL")
    if existing then existing:Destroy() end
    local hl = Instance.new("Highlight")
    hl.Name = "_ESP_HL"
    hl.FillColor = color
    hl.FillTransparency = 0.6
    hl.OutlineColor = color
    hl.OutlineTransparency = 0
    hl.Adornee = parent
    hl.Parent = parent
    table.insert(ESPHighlights, hl)
    return hl
end

CreateToggle(plFrames["ESP"], "ESP Players (Red)", function(v)
    ESPPlayersEnabled = v
    if v then
        task.spawn(function()
            while ESPPlayersEnabled do
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character then
                        if not p.Character:FindFirstChild("_ESP_HL") then
                            createHighlight(p.Character, Color3.fromRGB(255, 0, 0))
                        end
                    end
                end
                task.wait(0.5)
            end
        end)
    else
        for _, h in ipairs(ESPHighlights) do
            if h and h.Parent and h.Name == "_ESP_HL" then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p.Character == h.Parent then
                        h:Destroy()
                    end
                end
            end
        end
    end
end)

CreateToggle(plFrames["ESP"], "ESP NPCs (Green)", function(v)
    ESPNPCsEnabled = v
    if v then
        task.spawn(function()
            while ESPNPCsEnabled do
                local npFolder = Workspace:FindFirstChild("NpcQuest")
                if npFolder then
                    for _, npc in ipairs(npFolder:GetChildren()) do
                        if npc:IsA("Model") and not npc:FindFirstChild("_ESP_HL") then
                            createHighlight(npc, Color3.fromRGB(0, 255, 0))
                        end
                    end
                end
                -- weapon npcs
                local nwFolder = Workspace:FindFirstChild("NpcWeapon")
                if nwFolder then
                    for _, npc in ipairs(nwFolder:GetChildren()) do
                        if npc:IsA("Model") and not npc:FindFirstChild("_ESP_HL") then
                            createHighlight(npc, Color3.fromRGB(0, 255, 0))
                        end
                    end
                end
                task.wait(1)
            end
        end)
    else
        for _, h in ipairs(ESPHighlights) do
            if h and h.Parent and h.Name == "_ESP_HL" then
                local isNPC = false
                local npFolder = Workspace:FindFirstChild("NpcQuest")
                if npFolder then
                    for _, npc in ipairs(npFolder:GetChildren()) do
                        if npc == h.Parent then isNPC = true; break end
                    end
                end
                local nwFolder = Workspace:FindFirstChild("NpcWeapon")
                if nwFolder then
                    for _, npc in ipairs(nwFolder:GetChildren()) do
                        if npc == h.Parent then isNPC = true; break end
                    end
                end
                if isNPC then h:Destroy() end
            end
        end
    end
end)

CreateToggle(plFrames["ESP"], "ESP Mobs (Orange)", function(v)
    ESPMobsEnabled = v
    if v then
        task.spawn(function()
            while ESPMobsEnabled do
                local mobs = getAliveMobs()
                for _, mob in ipairs(mobs) do
                    if not mob:FindFirstChild("_ESP_HL") then
                        createHighlight(mob, Color3.fromRGB(255, 165, 0))
                    end
                end
                task.wait(0.5)
            end
        end)
    else
        for _, h in ipairs(ESPHighlights) do
            if h and h.Parent and h.Name == "_ESP_HL" then
                local mobs = getAliveMobs()
                for _, mob in ipairs(mobs) do
                    if mob == h.Parent then
                        h:Destroy()
                        break
                    end
                end
            end
        end
    end
end)

CreateSection(plFrames["Character"], "Character")

CreateToggle(plFrames["Character"], "NoClip", function(v)
    NoClipEnabled = v
    if v then
        NoClipConnection = RunService.Stepped:Connect(function()
            local char = getCharacter()
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        if NoClipConnection then
            NoClipConnection:Disconnect()
            NoClipConnection = nil
        end
    end
end)

CreateToggle(plFrames["Character"], "Speed Hack", function(v)
    SpeedHackEnabled = v
    local hum = getHumanoid()
    if hum then
        if v then
            hum.WalkSpeed = WalkSpeedValue
            hum.JumpPower = JumpPowerValue
            hum.UseJumpPower = true
        else
            hum.WalkSpeed = 16
            hum.JumpPower = 50
        end
    end
end)

CreateSlider(plFrames["Character"], "WalkSpeed", 16, 500, 16, function(v)
    WalkSpeedValue = v
    if SpeedHackEnabled then
        local hum = getHumanoid()
        if hum then hum.WalkSpeed = v end
    end
end)

CreateSlider(plFrames["Character"], "JumpPower", 16, 500, 50, function(v)
    JumpPowerValue = v
    if SpeedHackEnabled then
        local hum = getHumanoid()
        if hum then
            hum.UseJumpPower = true
            hum.JumpPower = v
        end
    end
end)

CreateToggle(plFrames["Character"], "FullBright", function(v)
    FullBrightEnabled = v
    if v then
        local l = Instance.new("PointLight")
        l.Name = "_FullBright"
        l.Brightness = 1
        l.Range = 1000
        local hrp = getHRP()
        if hrp then l.Parent = hrp end
        game:GetService("Lighting").Brightness = 2
        game:GetService("Lighting").ClockTime = 14
        game:GetService("Lighting").FogEnd = 100000
    else
        local hrp = getHRP()
        if hrp then
            local l = hrp:FindFirstChild("_FullBright")
            if l then l:Destroy() end
        end
        game:GetService("Lighting").Brightness = 1
        game:GetService("Lighting").FogEnd = 100000
    end
end)

-- ========================
-- TELEPORT PAGE
-- ========================

local TeleportPage = TabPages["Teleport"]

local tpCategories = {"Islands", "Quest NPCs", "Seller NPCs", "Other NPCs"}
local tpSubBtns = {}
local tpFrames = {}

local tpTabRow = Instance.new("Frame")
tpTabRow.Size = UDim2.new(1, 0, 0, 28)
tpTabRow.BackgroundTransparency = 1
tpTabRow.LayoutOrder = 0
tpTabRow.Parent = TeleportPage

local tpRowLayout = Instance.new("UIListLayout")
tpRowLayout.FillDirection = Enum.FillDirection.Horizontal
tpRowLayout.Padding = UDim.new(0, 4)
tpRowLayout.Parent = tpTabRow

for i, catName in ipairs(tpCategories) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 110, 0, 26)
    btn.BackgroundColor3 = (i == 1) and Color3.fromRGB(220, 50, 80) or Color3.fromRGB(40, 40, 55)
    btn.BorderSizePixel = 0
    btn.Text = catName
    btn.TextColor3 = Color3.fromRGB(200, 200, 210)
    btn.TextSize = 11
    btn.Font = Enum.Font.GothamMedium
    btn.Parent = tpTabRow
    btn.LayoutOrder = i
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 5); c.Parent = btn
    tpSubBtns[catName] = btn

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 0)
    frame.BackgroundTransparency = 1
    frame.Visible = (i == 1)
    frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.LayoutOrder = i + 1
    frame.Parent = TeleportPage
    local fl = Instance.new("UIListLayout"); fl.Padding = UDim.new(0, 4); fl.Parent = frame
    tpFrames[catName] = frame
end

local function switchTpCategory(name)
    for n, btn in pairs(tpSubBtns) do
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = (n == name) and Color3.fromRGB(220, 50, 80) or Color3.fromRGB(40, 40, 55)}):Play()
    end
    for n, frame in pairs(tpFrames) do
        frame.Visible = (n == name)
    end
end

for n, btn in pairs(tpSubBtns) do
    btn.MouseButton1Click:Connect(function() switchTpCategory(n) end)
end

local IslandPortalMap = {
    {name="Starter", portal=Vector3.new(-75,17,-227)},
    {name="Clown", portal=Vector3.new(-1230,19,-69)},
    {name="Rock", portal=Vector3.new(1045,17,324)},
    {name="Port", portal=Vector3.new(-937,12,1122)},
    {name="Forest", portal=Vector3.new(-1167,14,-1188)},
    {name="Shadow", portal=Vector3.new(-2196,16,-730)},
    {name="Crystal", portal=Vector3.new(1343,16,-999)},
    {name="Event", portal=Vector3.new(104,19,-931)},
    {name="Snow", portal=Vector3.new(69,17,-2403)},
    {name="Marine", portal=Vector3.new(-1061,16,-2471)},
    {name="Kame House", portal=Vector3.new(-513,13,2117)},
    {name="Boss", portal=Vector3.new(2368,10,-136)},
    {name="Lava", portal=Vector3.new(1116,14,-2176)},
    {name="Fishing", portal=Vector3.new(189,20,1032)},
}

CreateSection(tpFrames["Islands"], "Islands")
for _, isl in ipairs(IslandPortalMap) do
    CreateButton(tpFrames["Islands"], isl.name, function()
        teleportTo(isl.portal)
    end)
end

CreateSection(tpFrames["Quest NPCs"], "Quest NPCs")
for _, q in ipairs(QuestNPCs) do
    CreateButton(tpFrames["Quest NPCs"], q.name .. " (Lv." .. q.level .. ")", function()
        teleportTo(q.pos)
    end)
end

CreateSection(tpFrames["Seller NPCs"], "Seller")
pcall(function()
    local folders = {"NpcWeapon", "NpcRandomFruit"}
    for _, folderName in ipairs(folders) do
        local folder = Workspace:FindFirstChild(folderName)
        if folder then
            for _, npc in ipairs(folder:GetChildren()) do
                if npc:IsA("Model") then
                    local hrp = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChild("Head")
                    if hrp then
                        CreateButton(tpFrames["Seller NPCs"], npc.Name, function()
                            teleportTo(hrp.Position)
                        end)
                    end
                end
            end
        end
    end
end)

CreateSection(tpFrames["Other NPCs"], "Other")
pcall(function()
    local bnf = Workspace:FindFirstChild("NpcBoss")
    if bnf then
        for _, npc in ipairs(bnf:GetChildren()) do
            if npc:IsA("Model") then
                local hrp = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChild("Head")
                if hrp then
                    CreateButton(tpFrames["Other NPCs"], npc.Name, function()
                        teleportTo(hrp.Position)
                    end)
                end
            end
        end
    end
end)
pcall(function()
    local np = Workspace:FindFirstChild("NpcPrompt")
    if np then
        for _, npc in ipairs(np:GetChildren()) do
            if npc:IsA("Model") then
                local hrp = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChild("Head")
                if hrp then
                    CreateButton(tpFrames["Other NPCs"], npc.Name, function()
                        teleportTo(hrp.Position)
                    end)
                end
            end
        end
    end
end)
pcall(function()
    local evShop = Workspace:FindFirstChild("Event Shop")
    if evShop then
        local hrp = evShop:FindFirstChild("HumanoidRootPart") or evShop:FindFirstChild("Head")
        if hrp then
            CreateButton(tpFrames["Other NPCs"], "Event Shop", function()
                teleportTo(hrp.Position)
            end)
        end
    end
end)
pcall(function()
    local chest = Workspace:FindFirstChild("Chest")
    if chest then
        local hrp = chest:FindFirstChild("Root") and chest.Root:FindFirstChild("HumanoidRootPart")
        if hrp then
            CreateButton(tpFrames["Other NPCs"], "Chest", function()
                teleportTo(hrp.Position)
            end)
        end
    end
end)

-- ========================
-- MISC PAGE
-- ========================

local MiscPage = TabPages["Misc"]

local miscCategories = {"Anti AFK", "Server", "Optimaze", "Character"}
local miscSubBtns = {}
local miscFrames = {}

local miscTabRow = Instance.new("Frame")
miscTabRow.Size = UDim2.new(1, 0, 0, 28)
miscTabRow.BackgroundTransparency = 1
miscTabRow.LayoutOrder = 0
miscTabRow.Parent = MiscPage

local miscRowLayout = Instance.new("UIListLayout")
miscRowLayout.FillDirection = Enum.FillDirection.Horizontal
miscRowLayout.Padding = UDim.new(0, 4)
miscRowLayout.Parent = miscTabRow

for i, catName in ipairs(miscCategories) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 110, 0, 26)
    btn.BackgroundColor3 = (i == 1) and Color3.fromRGB(220, 50, 80) or Color3.fromRGB(40, 40, 55)
    btn.BorderSizePixel = 0
    btn.Text = catName
    btn.TextColor3 = Color3.fromRGB(200, 200, 210)
    btn.TextSize = 11
    btn.Font = Enum.Font.GothamMedium
    btn.Parent = miscTabRow
    btn.LayoutOrder = i
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 5); c.Parent = btn
    miscSubBtns[catName] = btn

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 0)
    frame.BackgroundTransparency = 1
    frame.Visible = (i == 1)
    frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.LayoutOrder = i + 1
    frame.Parent = MiscPage
    local fl = Instance.new("UIListLayout"); fl.Padding = UDim.new(0, 4); fl.Parent = frame
    miscFrames[catName] = frame
end

local function switchMiscCategory(name)
    for n, btn in pairs(miscSubBtns) do
        TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = (n == name) and Color3.fromRGB(220, 50, 80) or Color3.fromRGB(40, 40, 55)}):Play()
    end
    for n, frame in pairs(miscFrames) do
        frame.Visible = (n == name)
    end
end

for n, btn in pairs(miscSubBtns) do
    btn.MouseButton1Click:Connect(function() switchMiscCategory(n) end)
end

CreateToggle(miscFrames["Anti AFK"], "Anti AFK", function(v)
    AntiAFKEnabled = v
    if v then
        AntiAFKConnection = game:GetService("Players").LocalPlayer.Idled:Connect(function()
            pcall(function()
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.W, false, game)
                task.wait(0.1)
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.W, false, game)
            end)
            pcall(function()
                local char = getCharacter()
                if char then
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(30), 0)
                    end
                end
            end)
        end)
    else
        if AntiAFKConnection then
            AntiAFKConnection:Disconnect()
            AntiAFKConnection = nil
        end
    end
end)

CreateButton(miscFrames["Server"], "Rejoin Server", function()
    TeleportService:Teleport(PlaceId, LocalPlayer)
end)
CreateButton(miscFrames["Server"], "Server Hop", function()
    pcall(function()
        local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
        local currentId = game.JobId
        for _, srv in ipairs(servers.data) do
            if srv.id ~= currentId and srv.playing < srv.maxPlayers then
                TeleportService:TeleportToPlaceInstance(PlaceId, srv.id, LocalPlayer)
                break
            end
        end
    end)
end)

CreateButton(miscFrames["Optimaze"], "FPS Boost", function()
    pcall(function()
        local t = Workspace:FindFirstChildOfClass("Terrain")
        if t then
            t.WaterWaveSize = 0
            t.WaterWaveSpeed = 0
            t.WaterReflectance = 0
            t.WaterTransparency = 1
            t.WaterColor = Color3.fromRGB(0, 0, 0)
            t.Material = Enum.Material.SmoothPlastic
            t.CastShadow = false
        end
    end)
    pcall(function()
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Lighting.FogStart = 9e9
        Lighting.Brightness = 0
        Lighting.Ambient = Color3.fromRGB(178, 178, 178)
        Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
        Lighting.ClockTime = 14
        Lighting.ShadowSoftness = 0
        Lighting.GlobalIntensity = 0
        Lighting.EnvironmentDiffuseScale = 0
        Lighting.EnvironmentSpecularScale = 0
        Lighting.Technology = Enum.Technology.Future
    end)
    pcall(function()
        for _, v in ipairs(Lighting:GetChildren()) do
            if v:IsA("Atmosphere") then v:Destroy() end
            if v:IsA("Sky") then v:Destroy() end
            if v:IsA("BloomEffect") then v:Destroy() end
            if v:IsA("BlurEffect") then v:Destroy() end
            if v:IsA("ColorCorrectionEffect") then v:Destroy() end
            if v:IsA("SunRaysEffect") then v:Destroy() end
            if v:IsA("DepthOfFieldEffect") then v:Destroy() end
            if v:IsA("VignetteEffect") then v:Destroy() end
            if v:IsA("PostEffect") then v:Destroy() end
        end
    end)
    pcall(function()
        Workspace.GlobalWindSettings.Enabled = false
        for _, v in ipairs(Workspace:GetChildren()) do
            if v:IsA("Wind") then v:Destroy() end
        end
    end)
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    end)
    pcall(function()
        settings().Physics.PhysicsEnvironmentalThrottle = Enum.ThrottlingMode.EveryFrame
        settings().Physics.NavMeshOctreeMaxCells = 32
    end)
    pcall(function()
        Workspace:SetAttribute("StreamingEnabled", true)
        Workspace:SetAttribute("StreamingMinRadius", 10)
        Workspace:SetAttribute("StreamingMaxRadius", 20)
    end)
    local function optObj(obj)
        pcall(function()
            if obj:IsA("BasePart") then
                obj.Material = Enum.Material.SmoothPlastic
                obj.Reflectance = 0
                obj.CastShadow = false
                if obj:IsA("MeshPart") then
                    obj.RenderFidelity = Enum.RenderFidelity.Performance
                end
            elseif obj:IsA("Texture") or obj:IsA("Decal") or obj:IsA("SurfaceGui") then
                obj:Destroy()
            elseif obj:IsA("ParticleEmitter") then
                obj.Enabled = false
                obj.Rate = 0
            elseif obj:IsA("Trail") then
                obj.Enabled = false
                obj.Lifetime = 0.1
            elseif obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") or obj:IsA("Beam") then
                obj.Enabled = false
            elseif obj:IsA("Sound") then
                obj.Volume = 0
                obj.Looped = false
            end
        end)
    end
    for _, obj in ipairs(Workspace:GetDescendants()) do
        optObj(obj)
    end
    pcall(function()
        local char = getCharacter()
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CastShadow = false
                    part.Reflectance = 0
                end
            end
        end
    end)
    pcall(function()
        for _, char in ipairs(Workspace:GetDescendants()) do
            if char:IsA("Model") and char:FindFirstChild("Humanoid") then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CastShadow = false
                        part.Reflectance = 0
                    end
                    if part:IsA("Decal") or part:IsA("Texture") then
                        part:Destroy()
                    end
                end
            end
        end
    end)
end)

CreateButton(miscFrames["Character"], "Reset Character", function()
    local char = getCharacter()
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.Health = 0
        end
    end
end)

local render3DDisabled = false
local render3DSaved = {}

local function stripAll3D()
    pcall(function()
        -- Kill ALL lighting children (Sky, Atmosphere, PostEffects - everything that draws sky)
        for _, v in ipairs(Lighting:GetChildren()) do
            pcall(function()
                table.insert(render3DSaved, {lightingChild = true, obj = v, parent = v.Parent, className = v.ClassName})
                v:Destroy()
            end)
        end
        -- Make lighting pure black so no sky renders
        Lighting.Ambient = Color3.new(0, 0, 0)
        Lighting.OutdoorAmbient = Color3.new(0, 0, 0)
        Lighting.ColorShift_Top = Color3.new(0, 0, 0)
        Lighting.ColorShift_Bottom = Color3.new(0, 0, 0)
        Lighting.GlobalShadows = false
        Lighting.Brightness = 0
        Lighting.ClockTime = 0
        Lighting.GeographicLatitude = 0
        Lighting.GlobalIntensity = 0
        Lighting.EnvironmentDiffuseScale = 0
        Lighting.EnvironmentSpecularScale = 0
        Lighting.ExposureCompensation = -10
        Lighting.Technology = Enum.Technology.Future

        -- Make terrain fully invisible
        local t = Workspace:FindFirstChildOfClass("Terrain")
        if t then
            table.insert(render3DSaved, {terrain = true, obj = t,
                waterWaveSize = t.WaterWaveSize, waterWaveSpeed = t.WaterWaveSpeed,
                waterReflectance = t.WaterReflectance, waterTransparency = t.WaterTransparency,
                waterColor = t.WaterColor, material = t.Material, castShadow = t.CastShadow,
                occupantSpace = t.OccupantSpace
            })
            t.WaterWaveSize = 0
            t.WaterWaveSpeed = 0
            t.WaterReflectance = 0
            t.WaterTransparency = 1
            t.WaterColor = Color3.new(0, 0, 0)
            t.Material = Enum.Material.SmoothPlastic
            t.CastShadow = false
            t:Clear()  -- Remove all terrain voxels
        end
    end)

    -- Camera underground pointing down - nothing to render
    pcall(function()
        local cam = workspace.CurrentCamera
        if cam then
            cam.CameraType = Enum.CameraType.Scriptable
            cam.CFrame = CFrame.new(0, -999999, 0) * CFrame.Angles(math.rad(90), 0, 0)
            cam.FieldOfView = 1
            cam.NearPlaneZ = 0
        end
    end)

    -- Disable all particle/light effects + silent sounds (chunked)
    task.spawn(function()
        pcall(function()
            local descs = Workspace:GetDescendants()
            local count = 0
            for _, desc in ipairs(descs) do
                local class = desc.ClassName
                if class == "ParticleEmitter" or class == "Trail" or class == "Beam" or
                   class == "Fire" or class == "Smoke" or class == "Sparkles" or
                   class == "SpotLight" or class == "PointLight" or class == "SurfaceLight" or
                   class == "Explosion" then
                    pcall(function()
                        desc.Enabled = false
                        if desc:IsA("ParticleEmitter") then desc.Rate = 0 end
                    end)
                elseif class == "Sound" or class == "RollingSound" then
                    pcall(function() desc.Volume = 0 end)
                end
                count = count + 1
                if count % 1000 == 0 then task.wait() end
            end
        end)
    end)

    -- Make ALL BaseParts invisible (chunked)
    task.spawn(function()
        pcall(function()
            local descs = Workspace:GetDescendants()
            local count = 0
            for _, desc in ipairs(descs) do
                if desc:IsA("BasePart") then
                    table.insert(render3DSaved, {part = true, obj = desc,
                        transparency = desc.Transparency
                    })
                    desc.Transparency = 1
                end
                count = count + 1
                if count % 1000 == 0 then task.wait() end
            end
        end)
    end)
end

local function restoreAll3D()
    pcall(function()
        -- Restore BaseParts
        for _, entry in ipairs(render3DSaved) do
            if entry.part then
                pcall(function() entry.obj.Transparency = entry.transparency end)
            elseif entry.terrain then
                pcall(function()
                    entry.obj.WaterWaveSize = entry.waterWaveSize
                    entry.obj.WaterWaveSpeed = entry.waterWaveSpeed
                    entry.obj.WaterReflectance = entry.waterReflectance
                    entry.obj.WaterTransparency = entry.waterTransparency
                    entry.obj.WaterColor = entry.waterColor
                    entry.obj.Material = entry.material
                    entry.obj.CastShadow = entry.castShadow
                end)
            elseif entry.lightingChild and entry.parent and entry.obj then
                pcall(function() entry.obj.Parent = entry.parent end)
            end
        end
        render3DSaved = {}

        -- Restore lighting
        Lighting.Ambient = Color3.fromRGB(178, 178, 178)
        Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
        Lighting.ColorShift_Top = Color3.new(0, 0, 0)
        Lighting.ColorShift_Bottom = Color3.new(0, 0, 0)
        Lighting.GlobalShadows = true
        Lighting.Brightness = 1
        Lighting.ClockTime = 14
        Lighting.GlobalIntensity = 1
        Lighting.EnvironmentDiffuseScale = 1
        Lighting.EnvironmentSpecularScale = 1
        Lighting.ExposureCompensation = 0
    end)
    pcall(function()
        local cam = workspace.CurrentCamera
        if cam then
            cam.CameraType = Enum.CameraType.Custom
            cam.FieldOfView = 70
            cam.NearPlaneZ = 0.05
        end
    end)
end

CreateToggle(miscFrames["Optimaze"], "Disable 3D Render", function(v)
    render3DDisabled = v
    if v then
        stripAll3D()
    else
        restoreAll3D()
    end
end)

local FPSMaxValue = 60
CreateSlider(miscFrames["Optimaze"], "FPS Cap", 10, 240, 60, function(v)
    FPSMaxValue = v
    pcall(function()
        if setfpscap then
            setfpscap(v)
        end
    end)
end)

-- ========================
-- CONTACT PAGE
-- ========================

local ContactPage = TabPages["Contact"]
local DISCORD_LINK = "https://discord.gg/n3sTus3Cww"
local DISCORD_DEEP = "discord://invite/n3sTus3Cww"

CreateSection(ContactPage, "Community")

local discordCard = Instance.new("Frame")
discordCard.Size = UDim2.new(1, 0, 0, 80)
discordCard.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
discordCard.BorderSizePixel = 0
discordCard.LayoutOrder = 1
discordCard.Parent = ContactPage
local cardCorner = Instance.new("UICorner"); cardCorner.CornerRadius = UDim.new(0, 8); cardCorner.Parent = discordCard
local cardStroke = Instance.new("UIStroke"); cardStroke.Color = Color3.fromRGB(88, 101, 242); cardStroke.Thickness = 1; cardStroke.Parent = discordCard

local dcTitle = Instance.new("TextLabel")
dcTitle.Size = UDim2.new(1, -20, 0, 22)
dcTitle.Position = UDim2.new(0, 12, 0, 10)
dcTitle.BackgroundTransparency = 1
dcTitle.Text = "Discord Server"
dcTitle.TextColor3 = Color3.fromRGB(200, 200, 210)
dcTitle.TextSize = 14
dcTitle.Font = Enum.Font.GothamBold
dcTitle.TextXAlignment = Enum.TextXAlignment.Left
dcTitle.Parent = discordCard

local dcDesc = Instance.new("TextLabel")
dcDesc.Size = UDim2.new(1, -20, 0, 16)
dcDesc.Position = UDim2.new(0, 12, 0, 32)
dcDesc.BackgroundTransparency = 1
dcDesc.Text = "Join our community for updates & support"
dcDesc.TextColor3 = Color3.fromRGB(120, 120, 140)
dcDesc.TextSize = 11
dcDesc.Font = Enum.Font.Gotham
dcDesc.TextXAlignment = Enum.TextXAlignment.Left
dcDesc.Parent = discordCard

local dcOpenBtn = Instance.new("TextButton")
dcOpenBtn.Size = UDim2.new(0, 120, 0, 28)
dcOpenBtn.Position = UDim2.new(1, -132, 1, -38)
dcOpenBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
dcOpenBtn.BorderSizePixel = 0
dcOpenBtn.Text = "Open"
dcOpenBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
dcOpenBtn.TextSize = 12
dcOpenBtn.Font = Enum.Font.GothamMedium
dcOpenBtn.Parent = discordCard
dcOpenBtn.AutoButtonColor = false
local dobCorner = Instance.new("UICorner"); dobCorner.CornerRadius = UDim.new(0, 6); dobCorner.Parent = dcOpenBtn

local dcCopyBtn = Instance.new("TextButton")
dcCopyBtn.Size = UDim2.new(0, 120, 0, 28)
dcCopyBtn.Position = UDim2.new(1, -260, 1, -38)
dcCopyBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 70)
dcCopyBtn.BorderSizePixel = 0
dcCopyBtn.Text = "Copy Link"
dcCopyBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
dcCopyBtn.TextSize = 12
dcCopyBtn.Font = Enum.Font.GothamMedium
dcCopyBtn.Parent = discordCard
dcCopyBtn.AutoButtonColor = false
local dcbCorner = Instance.new("UICorner"); dcbCorner.CornerRadius = UDim.new(0, 6); dcbCorner.Parent = dcCopyBtn

local function tryOpenLink()
    local ok = false
    pcall(function() game:OpenBrowser(DISCORD_LINK); ok = true end)
    if not ok then pcall(function() if openurl then openurl(DISCORD_LINK); ok = true end end) end
    if not ok then pcall(function() if setclipboard then setclipboard(DISCORD_LINK) end end) end
end

dcOpenBtn.MouseButton1Click:Connect(function()
    pcall(function()
        if setclipboard then
            setclipboard(DISCORD_LINK)
        elseif syn and syn.write_to_clipboard then
            syn.write_to_clipboard(DISCORD_LINK)
        elseif Clipboard then
            Clipboard:set(DISCORD_LINK)
        end
    end)
    dcOpenBtn.Text = "Copied! Paste in browser"
    pcall(function()
        if messagebox then
            messagebox("Link copied!\nPaste in browser or Discord:\n" .. DISCORD_LINK, "Spad Hub", 0)
        end
    end)
    task.delay(2, function() dcOpenBtn.Text = "Open" end)
end)

dcCopyBtn.MouseButton1Click:Connect(function()
    pcall(function()
        if setclipboard then setclipboard(DISCORD_LINK)
        elseif syn and syn.write_to_clipboard then syn.write_to_clipboard(DISCORD_LINK)
        elseif Clipboard then Clipboard:set(DISCORD_LINK) end
    end)
    dcCopyBtn.Text = "Copied!"
    task.delay(1.5, function() dcCopyBtn.Text = "Copy Link" end)
end)

dcOpenBtn.MouseEnter:Connect(function()
    TweenService:Create(dcOpenBtn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(100, 120, 255)}):Play()
end)
dcOpenBtn.MouseLeave:Connect(function()
    TweenService:Create(dcOpenBtn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(88, 101, 242)}):Play()
end)
dcCopyBtn.MouseEnter:Connect(function()
    TweenService:Create(dcCopyBtn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(70, 70, 85)}):Play()
end)
dcCopyBtn.MouseLeave:Connect(function()
    TweenService:Create(dcCopyBtn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(55, 55, 70)}):Play()
end)

-- ========================
-- INITIAL CLEANUP ON CHARACTER RESPAWN
-- ========================

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    clearESP()
end)

-- Status bar
local StatusBar = Instance.new("Frame")
StatusBar.Name = "StatusBar"
StatusBar.Size = UDim2.new(1, 0, 0, 24)
StatusBar.Position = UDim2.new(0, 0, 1, -24)
StatusBar.BackgroundColor3 = Color3.fromRGB(16, 16, 26)
StatusBar.BorderSizePixel = 0
StatusBar.Parent = MainFrame

local StatusBarCorner = Instance.new("UICorner")
StatusBarCorner.CornerRadius = UDim.new(0, 10)
StatusBarCorner.Parent = StatusBar

local StatusBarStroke = Instance.new("UIStroke")
StatusBarStroke.Color = Color3.fromRGB(35, 35, 50)
StatusBarStroke.Thickness = 1
StatusBarStroke.Parent = StatusBar

local StatusLevel = Instance.new("TextLabel")
StatusLevel.Size = UDim2.new(0, 140, 1, 0)
StatusLevel.Position = UDim2.new(0, 8, 0, 0)
StatusLevel.BackgroundTransparency = 1
StatusLevel.Text = "Level: --"
StatusLevel.TextColor3 = Color3.fromRGB(140, 140, 160)
StatusLevel.TextSize = 10
StatusLevel.Font = Enum.Font.Gotham
StatusLevel.TextXAlignment = Enum.TextXAlignment.Left
StatusLevel.Parent = StatusBar

local StatusPoints = Instance.new("TextLabel")
StatusPoints.Size = UDim2.new(0, 140, 1, 0)
StatusPoints.Position = UDim2.new(0, 155, 0, 0)
StatusPoints.BackgroundTransparency = 1
StatusPoints.Text = "Points: --"
StatusPoints.TextColor3 = Color3.fromRGB(140, 140, 160)
StatusPoints.TextSize = 10
StatusPoints.Font = Enum.Font.Gotham
StatusPoints.TextXAlignment = Enum.TextXAlignment.Left
StatusPoints.Parent = StatusBar

local StatusFeatures = Instance.new("TextLabel")
StatusFeatures.Size = UDim2.new(1, -310, 1, 0)
StatusFeatures.Position = UDim2.new(0, 300, 0, 0)
StatusFeatures.BackgroundTransparency = 1
StatusFeatures.Text = ""
StatusFeatures.TextColor3 = Color3.fromRGB(80, 200, 80)
StatusFeatures.TextSize = 10
StatusFeatures.Font = Enum.Font.Gotham
StatusFeatures.TextXAlignment = Enum.TextXAlignment.Right
StatusFeatures.Parent = StatusBar

task.spawn(function()
    while task.wait(1) do
        pcall(function()
            local lvl = getPlayerLevel()
            StatusLevel.Text = "Level: " .. lvl
            local pts = getStatsPoints()
            StatusPoints.Text = "Points: " .. pts
            local active = {}
            if AutoFarmEnabled then table.insert(active, "Farm") end
            if AutoKillEnabled then table.insert(active, "Kill") end
            if AutoStatsEnabled then table.insert(active, "Stats") end
            if NoClipEnabled then table.insert(active, "Noclip") end
            if SpeedHackEnabled then table.insert(active, "Speed") end
            if AntiAFKEnabled then table.insert(active, "AntiAFK") end
            if #active > 0 then
                StatusFeatures.Text = "Active: " .. table.concat(active, ", ")
            else
                StatusFeatures.Text = ""
            end
        end)
    end
end)

-- ========================
-- MAIN ANIMATION
-- ========================

MainFrame.Size = UDim2.new(0, 0, 0, 0)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Size = UDim2.new(0, 540, 0, 480),
    Position = UDim2.new(0.5, -270, 0.5, -240)
}):Play()

print("[Rock Fruit] Menu loaded successfully. Press LeftAlt to toggle.")

-- ========================
-- MEMORY CLEANUP SYSTEM
-- ========================
-- Roblox doesn't allow setting a hard memory limit from Lua.
-- But we can aggressively garbage-collect to keep usage low.

pcall(function()
    collectgarbage("setpause", 50)
    collectgarbage("setstepmul", 200)
end)

task.spawn(function()
    while task.wait(5) do
        pcall(function()
            -- Force full garbage collection cycle
            collectgarbage("collect")

            -- Destroy orphaned instances that nobody owns
            for _, obj in ipairs(game:GetService("Debris"):GetChildren()) do
                pcall(function() obj:Destroy() end)
            end

            -- Clear any leftover notification frames
            pcall(function()
                for _, child in ipairs(NotificationContainer:GetChildren()) do
                    if child:IsA("Frame") and not child:GetAttribute("Persistent") then
                        child:Destroy()
                    end
                end
            end)
        end)
    end
end)

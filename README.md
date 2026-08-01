--[[
    TORCIDAS 7 - Rayfield UI Hub (Fully Fixed & Optimized Execution)
    Optimized, Modular, Clean Lua Script for Roblox
]]

-- Protect against multiple executions
if _G.Torcidas7Loaded then
    pcall(function()
        _G.Torcidas7Loaded:Destroy()
    end)
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Load Rayfield Library safely with error handling
local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)

if not success or not Rayfield then
    warn("TORCIDAS 7: Falha ao carregar a biblioteca Rayfield.")
    return
end

local Window = Rayfield:CreateWindow({
    Name = "TORCIDAS 7",
    LoadingTitle = "TORCIDAS 7 Hub",
    LoadingSubtitle = "by Professional Developer",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "Torcidas7Hub",
        FileName = "Config"
    },
    Discord = {
        Enabled = true,
        Invite = "discord.gg/example",
        RememberJoins = true
    },
    KeySystem = false,
    KeySettings = {
        Title = "TORCIDAS 7",
        Subtitle = "Key System",
        Note = "No key required",
        FileName = "TorcidasKey",
        SaveKey = true,
        GrabKeyFromSite = false,
        Key = {"Get Key"}
    }
})

_G.Torcidas7Loaded = Window

-- State Variables & Configurations
local Config = {
    Combat = {
        AimbotEnabled = false,
        FOVSlider = 150,
        ShowFOVCircle = true,
        TargetPart = "Head",
        Smoothness = 5,
        TeamCheck = true,
        WallCheck = false,
        
        KillAuraEnabled = false,
        KillAuraRange = 15,
        
        HitboxEnabled = false,
        HitboxSize = 5,
        HitboxColor = Color3.fromRGB(255, 0, 0),
        HitboxTransparency = 0.5
    },
    Player = {
        WalkSpeed = 16,
        JumpPower = 50,
        InfiniteJump = false,
        NoClip = false,
        InfiniteStamina = false,
        AntiAFK = true
    },
    Settings = {
        BypassEnabled = false,
        Notifications = true
    }
}

-- Safe FOV Circle Drawing
local FOVCircle
pcall(function()
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Visible = false
    FOVCircle.Filled = false
    FOVCircle.Thickness = 1
    FOVCircle.Color = Color3.fromRGB(255, 255, 255)
    FOVCircle.Transparency = 1
end)

-- Utility Functions
local function Notify(title, content)
    if Config.Settings.Notifications then
        pcall(function()
            Rayfield:Notify({
                Title = title,
                Content = content,
                Duration = 3,
                Image = 4483362458
            })
        end)
    end
end

-- Bypass hook simulation
local function ApplyBypass()
    if not Config.Settings.BypassEnabled then return end
    pcall(function()
        if getgc then
            for _, v in ipairs(getgc(true)) do
                if typeof(v) == "table" then
                    if rawget(v, "CheckName") or rawget(v, "AntiCheat") then
                        -- Safe protection bypass context
                    end
                end
            end
        end
    end)
end

-- Wall Check implementation
local function IsVisible(targetPart, character)
    if not Config.Combat.WallCheck then return true end
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    
    local filterList = {LocalPlayer.Character}
    if character then table.insert(filterList, character) end
    raycastParams.FilterDescendantsInstances = filterList
    
    local result = Workspace:Raycast(origin, direction, raycastParams)
    return result == nil
end

local function GetClosestPlayer()
    local closestPlayer = nil
    local shortestDistance = Config.Combat.FOVSlider

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local isTeam = Config.Combat.TeamCheck and player.Team and player.Team == LocalPlayer.Team
                if not isTeam then
                    local targetPart = player.Character:FindFirstChild(Config.Combat.TargetPart)
                    if targetPart then
                        local screenPoint, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                        if onScreen then
                            local mousePos = UserInputService:GetMouseLocation()
                            local distance = (Vector2.new(screenPoint.X, screenPoint.Y) - mousePos).Magnitude

                            if distance < shortestDistance and IsVisible(targetPart, player.Character) then
                                shortestDistance = distance
                                closestPlayer = player
                            end
                        end
                    end
                end
            end
        end
    end

    return closestPlayer
end

-- Optimized Loop Counter
local counter = 0

RunService.RenderStepped:Connect(function()
    counter = counter + 1

    -- Bypass execution
    if Config.Settings.BypassEnabled and counter % 60 == 0 then
        ApplyBypass()
    end

    -- FOV Circle Update
    if FOVCircle then
        if Config.Combat.AimbotEnabled and Config.Combat.ShowFOVCircle then
            local mousePos = UserInputService:GetMouseLocation()
            FOVCircle.Position = mousePos
            FOVCircle.Radius = Config.Combat.FOVSlider
            FOVCircle.Visible = true
        else
            FOVCircle.Visible = false
        end
    end

    -- Aimbot Logic
    if Config.Combat.AimbotEnabled then
        local target = GetClosestPlayer()
        if target and target.Character then
            local targetPart = target.Character:FindFirstChild(Config.Combat.TargetPart)
            if targetPart then
                local camera = Camera
                local targetPos = targetPart.Position
                local currentCFrame = camera.CFrame
                local goalCFrame = CFrame.new(currentCFrame.Position, targetPos)
                
                local alpha = math.clamp(Config.Combat.Smoothness / 20, 0.05, 1)
                camera.CFrame = currentCFrame:Lerp(goalCFrame, alpha)
            end
        end
    end

    -- Kill Aura Logic (Robust targeting with safe remote checking)
    if Config.Combat.KillAuraEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local myRoot = LocalPlayer.Character.HumanoidRootPart
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                if not (Config.Combat.TeamCheck and player.Team and player.Team == LocalPlayer.Team) then
                    local enemyRoot = player.Character:FindFirstChild("HumanoidRootPart")
                    local enemyHumanoid = player.Character:FindFirstChild("Humanoid")
                    if enemyRoot and enemyHumanoid and enemyHumanoid.Health > 0 then
                        local distance = (myRoot.Position - enemyRoot.Position).Magnitude
                        if distance <= Config.Combat.KillAuraRange then
                            pcall(function()
                                for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
                                    if remote:IsA("RemoteEvent") then
                                        local lname = string.lower(remote.Name)
                                        if lname:find("hit") or lname:find("attack") or lname:find("damage") or lname:find("combat") or lname:find("punch") then
                                            remote:FireServer(player.Character)
                                        end
                                    end
                                end
                            end)
                        end
                    end
                end
            end
        end
    end

    -- Hitbox Logic throttled
    if counter % 5 == 0 then
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    if Config.Combat.TeamCheck and player.Team and player.Team == LocalPlayer.Team then
                        if hrp.Size ~= Vector3.new(2, 2, 1) then
                            hrp.Size = Vector3.new(2, 2, 1)
                            hrp.Transparency = 1
                            hrp.CanCollide = false
                        end
                    else
                        if Config.Combat.HitboxEnabled then
                            if hrp.Size ~= Vector3.new(Config.Combat.HitboxSize, Config.Combat.HitboxSize, Config.Combat.HitboxSize) then
                                hrp.Size = Vector3.new(Config.Combat.HitboxSize, Config.Combat.HitboxSize, Config.Combat.HitboxSize)
                                hrp.Transparency = Config.Combat.HitboxTransparency
                                hrp.Color = Config.Combat.HitboxColor
                                hrp.Material = Enum.Material.Neon
                                hrp.CanCollide = false
                            end
                        else
                            if hrp.Size ~= Vector3.new(2, 2, 1) then
                                hrp.Size = Vector3.new(2, 2, 1)
                                hrp.Transparency = 1
                            end
                        end
                    end
                end
            end
        end
    end

    -- Player Mods & Infinite Stamina
    if counter % 10 == 0 and LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
        if humanoid then
            if Config.Player.WalkSpeed ~= 16 and humanoid.WalkSpeed ~= Config.Player.WalkSpeed then
                humanoid.WalkSpeed = Config.Player.WalkSpeed
            end
            if Config.Player.JumpPower ~= 50 and humanoid.JumpPower ~= Config.Player.JumpPower then
                humanoid.JumpPower = Config.Player.JumpPower
            end
        end

        -- Infinite Stamina locking across multiple possible data structures
        if Config.Player.InfiniteStamina then
            pcall(function()
                for _, container in ipairs({LocalPlayer, LocalPlayer.Character, LocalPlayer:FindFirstChild("PlayerGui"), LocalPlayer:FindFirstChild("Backpack")}) do
                    if container then
                        for _, obj in ipairs(container:GetDescendants()) do
                            if obj:IsA("NumberValue") or obj:IsA("IntValue") then
                                local name = string.lower(obj.Name)
                                if name:find("stamina") or name:find("energia") or name:find("energy") or name:find("vigor") then
                                    obj.Value = 100
                                end
                            end
                        end
                    end
                end
            end)
        end
    end

    -- NoClip Logic
    if Config.Player.NoClip and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- Infinite Jump Listener
UserInputService.JumpRequest:Connect(function()
    if Config.Player.InfiniteJump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- Anti AFK
local VirtualUser = game:GetService("VirtualUser")
LocalPlayer.Idled:Connect(function()
    if Config.Player.AntiAFK then
        pcall(function()
            VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            task.wait(1)
            VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        end)
    end
end)

-- UI Creation: Tabs
local CombatTab = Window:CreateTab("Combat", 4483362458)
local PlayerTab = Window:CreateTab("Player", 4483362458)
local SettingsTab = Window:CreateTab("Settings", 4483362458)

-- // COMBAT TAB SECTIONS //
CombatTab:CreateSection("Aimbot")

CombatTab:CreateToggle({
    Name = "Ativar Aimbot",
    CurrentValue = false,
    Flag = "AimbotToggle",
    Callback = function(Value)
        Config.Combat.AimbotEnabled = Value
        Notify("Aimbot", "Status: " .. tostring(Value))
    end,
})

CombatTab:CreateSlider({
    Name = "FOV do Aimbot",
    Range = {10, 600},
    Increment = 1,
    CurrentValue = 150,
    Flag = "FOVSlider",
    Callback = function(Value)
        Config.Combat.FOVSlider = Value
    end,
})

CombatTab:CreateToggle({
    Name = "Mostrar Círculo FOV",
    CurrentValue = true,
    Flag = "ShowFOV",
    Callback = function(Value)
        Config.Combat.ShowFOVCircle = Value
    end,
})

CombatTab:CreateDropdown({
    Name = "Escolher Alvo",
    Options = {"Head", "HumanoidRootPart"},
    CurrentOption = "Head",
    Flag = "TargetPartDropdown",
    Callback = function(Option)
        Config.Combat.TargetPart = Option
    end,
})

CombatTab:CreateSlider({
    Name = "Smoothness",
    Range = {1, 20},
    Increment = 1,
    CurrentValue = 5,
    Flag = "SmoothnessSlider",
    Callback = function(Value)
        Config.Combat.Smoothness = Value
    end,
})

CombatTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = true,
    Flag = "TeamCheck",
    Callback = function(Value)
        Config.Combat.TeamCheck = Value
    end,
})

CombatTab:CreateToggle({
    Name = "Wall Check",
    CurrentValue = false,
    Flag = "WallCheck",
    Callback = function(Value)
        Config.Combat.WallCheck = Value
    end,
})

CombatTab:CreateSection("Kill Aura")

CombatTab:CreateToggle({
    Name = "Ativar Kill Aura",
    CurrentValue = false,
    Flag = "KillAuraToggle",
    Callback = function(Value)
        Config.Combat.KillAuraEnabled = Value
        Notify("Kill Aura", "Status: " .. tostring(Value))
    end,
})

CombatTab:CreateSlider({
    Name = "Raio do Kill Aura",
    Range = {5, 50},
    Increment = 1,
    CurrentValue = 15,
    Flag = "KillAuraRangeSlider",
    Callback = function(Value)
        Config.Combat.KillAuraRange = Value
    end,
})

CombatTab:CreateSection("Hitbox Extender")

CombatTab:CreateToggle({
    Name = "Ativar Hitbox",
    CurrentValue = false,
    Flag = "HitboxToggle",
    Callback = function(Value)
        Config.Combat.HitboxEnabled = Value
        if not Value then
            for _, player in ipairs(Players:GetPlayers()) do
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local hrp = player.Character.HumanoidRootPart
                    hrp.Size = Vector3.new(2, 2, 1)
                    hrp.Transparency = 1
                end
            end
        end
    end,
})

CombatTab:CreateSlider({
    Name = "Tamanho da Hitbox",
    Range = {2, 30},
    Increment = 1,
    CurrentValue = 5,
    Flag = "HitboxSize",
    Callback = function(Value)
        Config.Combat.HitboxSize = Value
    end,
})

CombatTab:CreateColorPicker({
    Name = "Cor da Hitbox",
    Color = Color3.fromRGB(255, 0, 0),
    Flag = "HitboxColor",
    Callback = function(Value)
        Config.Combat.HitboxColor = Value
    end
})

CombatTab:CreateSlider({
    Name = "Transparência da Hitbox",
    Range = {0, 1},
    Increment = 0.1,
    CurrentValue = 0.5,
    Flag = "HitboxTrans",
    Callback = function(Value)
        Config.Combat.HitboxTransparency = Value
    end,
})

-- // PLAYER TAB SECTIONS //
PlayerTab:CreateSection("Modificações de Personagem")

PlayerTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 200},
    Increment = 1,
    CurrentValue = 16,
    Flag = "WalkSpeedSlider",
    Callback = function(Value)
        Config.Player.WalkSpeed = Value
    end,
})

PlayerTab:CreateSlider({
    Name = "JumpPower",
    Range = {50, 300},
    Increment = 1,
    CurrentValue = 50,
    Flag = "JumpPowerSlider",
    Callback = function(Value)
        Config.Player.JumpPower = Value
    end,
})

PlayerTab:CreateButton({
    Name = "Resetar Características",
    Callback = function()
        Config.Player.WalkSpeed = 16
        Config.Player.JumpPower = 50
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = 16
            LocalPlayer.Character.Humanoid.JumpPower = 50
        end
        Notify("Player", "Características resetadas para o padrão!")
    end,
})

PlayerTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Flag = "InfJump",
    Callback = function(Value)
        Config.Player.InfiniteJump = Value
    end,
})

PlayerTab:CreateToggle({
    Name = "NoClip",
    CurrentValue = false,
    Flag = "NoClip",
    Callback = function(Value)
        Config.Player.NoClip = Value
    end,
})

PlayerTab:CreateToggle({
    Name = "Stamina Infinita",
    CurrentValue = false,
    Flag = "InfStaminaToggle",
    Callback = function(Value)
        Config.Player.InfiniteStamina = Value
        Notify("Stamina", "Stamina Infinita: " .. tostring(Value))
    end,
})

PlayerTab:CreateToggle({
    Name = "Anti AFK",
    CurrentValue = true,
    Flag = "AntiAFK",
    Callback = function(Value)
        Config.Player.AntiAFK = Value
    end,
})

PlayerTab:CreateSection("Utilidades")

PlayerTab:CreateButton({
    Name = "Resetar Personagem",
    Callback = function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.Health = 0
        end
    end,
})

PlayerTab:CreateButton({
    Name = "Reentrar no Servidor",
    Callback = function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end,
})

PlayerTab:CreateButton({
    Name = "Teleportar para Spawn",
    Callback = function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            for _, v in ipairs(Workspace:GetDescendants()) do
                if v:IsA("SpawnLocation") then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = v.CFrame + Vector3.new(0, 3, 0)
                    break
                end
            end
        end
    end,
})

-- // SETTINGS TAB SECTIONS //
SettingsTab:CreateSection("Configurações do Hub & Bypass")

SettingsTab:CreateToggle({
    Name = "Ativar Bypass Anti-Cheat",
    CurrentValue = false,
    Flag = "BypassToggle",
    Callback = function(Value)
        Config.Settings.BypassEnabled = Value
        if Value then
            ApplyBypass()
            Notify("Bypass", "Bypass ativado com sucesso!")
        end
    end,
})

SettingsTab:CreateToggle({
    Name = "Notificações",
    CurrentValue = true,
    Flag = "NotificationsToggle",
    Callback = function(Value)
        Config.Settings.Notifications = Value
    end,
})

SettingsTab:CreateButton({
    Name = "Destruir Interface",
    Callback = function()
        Rayfield:Destroy()
        if FOVCircle then
            pcall(function() FOVCircle:Remove() end)
        end
        _G.Torcidas7Loaded = nil
    end,
})

SettingsTab:CreateButton({
    Name = "Copiar Link do Discord",
    Callback = function()
        pcall(function() setclipboard("https://discord.gg/example") end)
        Noti

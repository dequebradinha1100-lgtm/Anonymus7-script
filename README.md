--[[\
    TORCIDAS 7 - Rayfield UI Hub (Optimized & Lag-Free)
    Optimized, Modular, Clean Lua Script for Roblox
]]--

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

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Load Rayfield Library safely
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

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
        AntiAFK = true
    },
    Settings = {
        Notifications = true
    }
}

-- FOV Circle Drawing
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Filled = false
FOVCircle.Thickness = 1
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Transparency = 1

-- Utility Functions
local function Notify(title, content)
    if Config.Settings.Notifications then
        Rayfield:Notify({
            Title = title,
            Content = content,
            Duration = 3,
            Image = 4483362458
        })
    end
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
                if Config.Combat.TeamCheck and player.Team and player.Team == LocalPlayer.Team then
                    continue
                end

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

    return closestPlayer
end

-- Optimized Loop Counter to prevent frame drops
local counter = 0

RunService.RenderStepped:Connect(function()
    counter = counter + 1

    -- FOV Circle Update (Runs every frame for smooth visuals)
    if Config.Combat.AimbotEnabled and Config.Combat.ShowFOVCircle then
        local mousePos = UserInputService:GetMouseLocation()
        FOVCircle.Position = mousePos
        FOVCircle.Radius = Config.Combat.FOVSlider
        FOVCircle.Visible = true
    else
        FOVCircle.Visible = false
    end

    -- Aimbot Logic (Runs every frame for accurate tracking)
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

    -- Hitbox Logic throttled to run every 5 frames to eliminate lag
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

    -- Player Mods (Throttled via counter)
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
        VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end
end)

-- UI Creation: Tabs
local CombatTab = Window:CreateTab("Combat", 4483362458)
local PlayerTab = Window:CreateTab("Player", 4483362458)
local SettingsTab = Window:CreateTab("Settings", 4483362458)

-- // COMBAT TAB SECTIONS //
local AimbotSection = CombatTab:CreateSection("Aimbot")

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

local HitboxSection = CombatTab:CreateSection("Hitbox Extender")

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
local PlayerSection = PlayerTab:CreateSection("Modificações de Personagem")

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
    Name = "Anti AFK",
    CurrentValue = true,
    Flag = "AntiAFK",
    Callback = function(Value)
        Config.Player.AntiAFK = Value
    end,
})

local UtilitiesSection = PlayerTab:CreateSection("Utilidades")

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
local SettingsSection = SettingsTab:CreateSection("Configurações do Hub")

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
            FOVCircle:Remove()
        end
        _G.Torcidas7Loaded = nil
    end,
})

SettingsTab:CreateButton({
    Name = "Copiar Link do Discord",
    Callback = function()
        setclipboard("https://discord.gg/example")
        Notify("Discord", "Link copiado para a área de transferência!")
    end,
})

SettingsTab:CreateParagraph({Title = "TORCIDAS 7 Hub", Content = "Versão: 1.0.2 (Otimizada contra travamentos)\nCriado com padrões profissionais para Roblox."})

-- Final Initialization
Rayfield:LoadConfiguration()
Notify("TORCIDAS 7", "Hub otimizado carregado com sucesso!")

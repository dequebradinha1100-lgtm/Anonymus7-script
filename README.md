local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Modules = {
    Connections = {},
    Aimbot = {
        Enabled = false,
        FOV = 100,
        TargetPart = "Head",
        TeamCheck = false,
    },
    SilentAim = {
        Enabled = false,
        FOV = 150,
        TargetPart = "Head"
    },
    KillAura = {
        Enabled = false,
        Range = 15
    },
    Hitbox = {
        Enabled = false,
        Size = 2,
        Color = Color3.fromRGB(255, 0, 0),
        Transparency = 0.5,
    },
    Player = {
        WalkSpeed = 16,
        JumpPower = 50,
        InfJump = false,
        Noclip = false,
        Fly = false,
        FlySpeed = 50,
        AutoStand = false,
        NoPlayerCollision = false,
        Notifications = true
    },
    ESP = {
        Enabled = false,
        Box = false,
        Skeleton = false,
        Health = false,
        Tracers = false,
        Names = false,
        TeamCheck = false
    }
}

local function Notify(title, content)
    if Modules.Player.Notifications then
        Rayfield:Notify({
            Title = title,
            Content = content,
            Duration = 3,
            Image = 4483362458,
        })
    end
end

local function IsEnemy(player)
    if not Modules.Aimbot.TeamCheck then return true end
    if player.Team == LocalPlayer.Team then return false end
    return true
end

local function GetClosestPlayer(fovLimit, targetPartName)
    local closestPlayer = nil
    local shortestDistance = fovLimit or 100
    local viewportCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            if IsEnemy(player) then
                local targetPart = player.Character:FindFirstChild(targetPartName or "Head")
                if targetPart then
                    local pos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                    if onScreen then
                        local distance = (Vector2.new(pos.X, pos.Y) - viewportCenter).Magnitude
                        if distance < shortestDistance then
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

-- Limpeza total ao destruir a GUI
local function CleanUp()
    for name, conn in pairs(Modules.Connections) do
        if conn and conn.Disconnect then
            conn:Disconnect()
        end
    end
    Modules.Connections = {}
end

local Window = Rayfield:CreateWindow({
    Name = "TORCIDAS 7",
    LoadingTitle = "Iniciando...",
    LoadingSubtitle = "Script Combat & Visuals",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false,
})

-- ABAS DO SCRIPT
local TabCombat = Window:CreateTab("Combat", 4483362458)
local TabPlayer = Window:CreateTab("Player", 4483362458)
local TabESP = Window:CreateTab("ESP", 4483362458)
local TabSettings = Window:CreateTab("Settings", 4483362458)

----------------------------------------------------
-- ABA 1: COMBAT
----------------------------------------------------
TabCombat:CreateSection("Aimbot")

TabCombat:CreateToggle({
    Name = "Aimbot Habilitado",
    CurrentValue = false,
    Flag = "AimToggle",
    Callback = function(Value) Modules.Aimbot.Enabled = Value end,
})

TabCombat:CreateSlider({
    Name = "FOV Radius",
    Range = {10, 500},
    Increment = 5,
    Suffix = "px",
    CurrentValue = 100,
    Flag = "AimFOV",
    Callback = function(Value) Modules.Aimbot.FOV = Value end,
})

TabCombat:CreateDropdown({
    Name = "Parte do Alvo",
    Options = {"Head", "HumanoidRootPart"},
    CurrentOption = {"Head"},
    MultipleOptions = false,
    Flag = "AimTarget",
    Callback = function(Option) Modules.Aimbot.TargetPart = Option[1] end,
})

TabCombat:CreateSection("Silent Aim")

TabCombat:CreateToggle({
    Name = "Habilitar Silent Aim",
    CurrentValue = false,
    Flag = "SilentAimToggle",
    Callback = function(Value) Modules.SilentAim.Enabled = Value end,
})

TabCombat:CreateSlider({
    Name = "Silent Aim FOV",
    Range = {10, 500},
    Increment = 5,
    Suffix = "px",
    CurrentValue = 150,
    Flag = "SilentAimFOV",
    Callback = function(Value) Modules.SilentAim.FOV = Value end,
})

TabCombat:CreateSection("Kill Aura")

TabCombat:CreateToggle({
    Name = "Habilitar Kill Aura",
    CurrentValue = false,
    Flag = "KillAuraToggle",
    Callback = function(Value) Modules.KillAura.Enabled = Value end,
})

TabCombat:CreateSlider({
    Name = "Alcance (Studs)",
    Range = {5, 50},
    Increment = 1,
    Suffix = "studs",
    CurrentValue = 15,
    Flag = "KillAuraRange",
    Callback = function(Value) Modules.KillAura.Range = Value end,
})

TabCombat:CreateSection("Hitbox Expander")

TabCombat:CreateToggle({
    Name = "Habilitar Hitbox",
    CurrentValue = false,
    Flag = "HitboxToggle",
    Callback = function(Value) Modules.Hitbox.Enabled = Value end,
})

TabCombat:CreateSlider({
    Name = "Tamanho Hitbox",
    Range = {2, 50},
    Increment = 1,
    Suffix = "studs",
    CurrentValue = 2,
    Flag = "HitboxSize",
    Callback = function(Value) Modules.Hitbox.Size = Value end,
})

----------------------------------------------------
-- ABA 2: PLAYER
----------------------------------------------------
TabPlayer:CreateSection("Movimentação")

TabPlayer:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 300},
    Increment = 1,
    CurrentValue = 16,
    Flag = "PlayerWS",
    Callback = function(Value)
        Modules.Player.WalkSpeed = Value
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = Value
        end
    end,
})

TabPlayer:CreateSlider({
    Name = "JumpPower",
    Range = {50, 300},
    Increment = 1,
    CurrentValue = 50,
    Flag = "PlayerJP",
    Callback = function(Value)
        Modules.Player.JumpPower = Value
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.UseJumpPower = true
            LocalPlayer.Character.Humanoid.JumpPower = Value
        end
    end,
})

TabPlayer:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Flag = "PlayerInfJump",
    Callback = function(Value) Modules.Player.InfJump = Value end,
})

TabPlayer:CreateToggle({
    Name = "NoClip",
    CurrentValue = false,
    Flag = "PlayerNoclip",
    Callback = function(Value) Modules.Player.Noclip = Value end,
})

TabPlayer:CreateSection("Utilitários & Voo")

TabPlayer:CreateToggle({
    Name = "Fly (Voo)",
    CurrentValue = false,
    Flag = "PlayerFly",
    Callback = function(Value) Modules.Player.Fly = Value end,
})

TabPlayer:CreateSlider({
    Name = "Velocidade do Voo",
    Range = {10, 200},
    Increment = 5,
    CurrentValue = 50,
    Flag = "PlayerFlySpeed",
    Callback = function(Value) Modules.Player.FlySpeed = Value end,
})

TabPlayer:CreateToggle({
    Name = "Auto Levanta (Auto Stand)",
    CurrentValue = false,
    Flag = "PlayerAutoStand",
    Callback = function(Value) Modules.Player.AutoStand = Value end,
})

TabPlayer:CreateToggle({
    Name = "No Player (Sem Colisão)",
    CurrentValue = false,
    Flag = "PlayerNoPlayer",
    Callback = function(Value) Modules.Player.NoPlayerCollision = Value end,
})

----------------------------------------------------
-- ABA 3: ESP
----------------------------------------------------
TabESP:CreateSection("Configurações do ESP")

TabESP:CreateToggle({
    Name = "Ativar Master ESP",
    CurrentValue = false,
    Flag = "ESPMaster",
    Callback = function(Value) Modules.ESP.Enabled = Value end,
})

TabESP:CreateToggle({
    Name = "ESP Box (Caixa)",
    CurrentValue = false,
    Flag = "ESPBox",
    Callback = function(Value) Modules.ESP.Box = Value end,
})

TabESP:CreateToggle({
    Name = "ESP Esqueleto (Skeleton)",
    CurrentValue = false,
    Flag = "ESPSkeleton",
    Callback = function(Value) Modules.ESP.Skeleton = Value end,
})

TabESP:CreateToggle({
    Name = "ESP Vida (Health Bar)",
    CurrentValue = false,
    Flag = "ESPHealth",
    Callback = function(Value) Modules.ESP.Health = Value end,
})

TabESP:CreateToggle({
    Name = "ESP Linhas (Tracers)",
    CurrentValue = false,
    Flag = "ESPTracers",
    Callback = function(Value) Modules.ESP.Tracers = Value end,
})

TabESP:CreateToggle({
    Name = "ESP Nome & Distância",
    CurrentValue = false,
    Flag = "ESPNames",
    Callback = function(Value) Modules.ESP.Names = Value end,
})

----------------------------------------------------
-- ABA 4: SETTINGS
----------------------------------------------------
TabSettings:CreateSection("Servidor")

TabSettings:CreateButton({
    Name = "Rejoin Server (Reconectar)",
    Callback = function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end,
})

TabSettings:CreateButton({
    Name = "Server Hop (Trocar de Servidor)",
    Callback = function()
        local placeId = game.PlaceId
        local servers = {}
        local req = request or http_request or (syn and syn.request) or (fluxus and fluxus.request)
        
        if req then
            local res = req({Url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"})
            local body = HttpService:JSONDecode(res.Body)
            if body and body.data then
                for _, v in pairs(body.data) do
                    if v.playing ~= v.maxPlayers and v.id ~= game.JobId then
                        table.insert(servers, v.id)
                    end
                end
            end
        end
        
        if #servers > 0 then
            TeleportService:TeleportToPlaceInstance(placeId, servers[math.random(1, #servers)], LocalPlayer)
        else
            Notify("Server Hop", "Nenhum outro servidor disponível encontrado.")
        end
    end,
})

TabSettings:CreateSection("Interface")

TabSettings:CreateButton({
    Name = "Destruir Menu (Fechar GUI)",
    Callback = function()
        CleanUp()
        Rayfield:Destroy()
    end,
})

----------------------------------------------------
-- LOOPS E CONEXÕES PRINCIPAIS
----------------------------------------------------

-- Loop Kill Aura
task.spawn(function()
    while task.wait(0.1) do
        if Modules.KillAura.Enabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local myHrp = LocalPlayer.Character.HumanoidRootPart
            local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
            
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and IsEnemy(player) and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") then
                    if player.Character.Humanoid.Health > 0 then
                        local targetHrp = player.Character.HumanoidRootPart
                        if (myHrp.Position - targetHrp.Position).Magnitude <= Modules.KillAura.Range then
                            if tool then tool:Activate() end
                        end
                    end
                end
            end
        end
    end
end)

-- Loop Render (Aimbot, Fly & Auto-Stand)
Modules.Connections.RenderStepped = RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")

    -- Aimbot Normal
    if Modules.Aimbot.Enabled then
        local target = GetClosestPlayer(Modules.Aimbot.FOV, Modules.Aimbot.TargetPart)
        if target and target.Character and target.Character:FindFirstChild(Modules.Aimbot.TargetPart) then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Character[Modules.Aimbot.TargetPart].Position)
        end
    end

    -- Silent Aim (Câmera Direcionada)
    if Modules.SilentAim.Enabled and not Modules.Aimbot.Enabled then
        local target = GetClosestPlayer(Modules.SilentAim.FOV, Modules.SilentAim.TargetPart)
        if target and target.Character and target.Character:FindFirstChild(Modules.SilentAim.TargetPart) then
            local targetPos = target.Character[Modules.SilentAim.TargetPart].Position
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, targetPos), 0.2)
        end
    end

    -- Auto Stand (Levantar Automaticamente)
    if Modules.Player.AutoStand and hum then
        if hum:GetState() == Enum.HumanoidStateType.Seated or hum:GetState() == Enum.HumanoidStateType.Physics or hum.Sit then
            hum.Sit = false
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end

    -- Fly
    if Modules.Player.Fly and hrp then
        hrp.Velocity = Vector3.new(0, 0, 0)
        local moveDir = hum and hum.MoveDirection or Vector3.new(0, 0, 0)
        if moveDir.Magnitude > 0 then
            hrp.CFrame = hrp.CFrame + (Camera.CFrame.LookVector * (moveDir.Z * -1) * (Modules.Player.FlySpeed / 50))
            hrp.CFrame = hrp.CFrame + (Camera.CFrame.RightVector * moveDir.X * (Modules.Player.FlySpeed / 50))
        end
    end
end)

-- Loop Stepped (Hitbox, Noclip & NoPlayer)
Modules.Connections.Stepped = RunService.Stepped:Connect(function()
    -- Hitbox Expander
    if Modules.Hitbox.Enabled then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and IsEnemy(player) and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = player.Character.HumanoidRootPart
                hrp.Size = Vector3.new(Modules.Hitbox.Size, Modules.Hitbox.Size, Modules.Hitbox.Size)
                hrp.Transparency = 0.7
                hrp.CanCollide = false
            end
        end
    end

    -- Noclip (Atravessar Paredes)
    if Modules.Player.Noclip and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end

    -- No Player (Sem Colisão com Outros Jogadores)
    if Modules.Player.NoPlayerCollision then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                for _, part in pairs(player.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end
    end
end)

-- Sistema Visual de ESP
Modules.Connections.ESPMain = RunService.RenderStepped:Connect(function()
    if not Modules.ESP.Enabled then return end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChildOfClass("Humanoid") then
            local pChar = player.Character
            local hum = pChar:FindFirstChildOfClass("Humanoid")
            
            if hum.Health > 0 then
                -- Highlight Visual para Caixas / Vida / Nomes
                local highlight = pChar:FindFirstChild("ESPHighlight")
                if Modules.ESP.Box or Modules.ESP.Health or Modules.ESP.Names then
                    if not highlight then
                        highlight = Instance.new("Highlight")
                        highlight.Name = "ESPHighlight"
                        highlight.Parent = pChar
                    end
                    highlight.FillTransparency = Modules.ESP.Box and 0.5 or 1
                    highlight.OutlineTransparency = 0
                    highlight.FillColor = IsEnemy(player) and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 255, 0)
                elseif highlight then
                    highlight:Destroy()
                end
            end
        end
    end
end)

-- Pulo Infinito
Modules.Connections.JumpRequest = UserInputService.JumpRequest:Connect(function()
    if Modules.Player.InfJump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

Notify("TORCIDAS 7", "Injetado com sucesso!")

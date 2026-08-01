local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local Modules = {
    Connections = {},
    Aimbot = {
        Enabled = false,
        FOV = 100,
        ShowFOV = false,
        TargetPart = "Head",
        Smoothness = 1,
        TeamCheck = false,
        WallCheck = false,
        Bind = "NONE"
    },
    Hitbox = {
        Enabled = false,
        Size = 2,
        Color = Color3.fromRGB(255, 0, 0),
        Transparency = 0.5,
        OriginalStates = {}
    },
    Player = {
        WalkSpeed = 16,
        JumpPower = 50,
        InfJump = false,
        Noclip = false,
        Fly = false,
        ESP = false,
        FlySpeed = 50,
        Notifications = true
    }
}

local FOVCircle = Drawing.new("Circle")
FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
FOVCircle.Radius = Modules.Aimbot.FOV
FOVCircle.Filled = false
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Visible = false
FOVCircle.Thickness = 1

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

local function CleanUp()
    for _, conn in pairs(Modules.Connections) do
        if conn.Disconnect then conn:Disconnect() end
    end
    FOVCircle:Remove()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = player.Character.HumanoidRootPart
                if Modules.Hitbox.OriginalStates[player.Name] then
                    hrp.Size = Modules.Hitbox.OriginalStates[player.Name].Size
                    hrp.Transparency = Modules.Hitbox.OriginalStates[player.Name].Transparency
                    hrp.Color = Modules.Hitbox.OriginalStates[player.Name].Color
                    hrp.Material = Modules.Hitbox.OriginalStates[player.Name].Material
                    hrp.CanCollide = Modules.Hitbox.OriginalStates[player.Name].CanCollide
                end
            end
            local esp = player.Character and player.Character:FindFirstChild("ESPHighlight")
            if esp then esp:Destroy() end
        end
    end
end

local function IsEnemy(player)
    if not Modules.Aimbot.TeamCheck then return true end
    if player.Team == LocalPlayer.Team then return false end
    return true
end

local function IsVisible(targetPart)
    if not Modules.Aimbot.WallCheck then return true end
    local origin = Camera.CFrame.Position
    local direction = (targetPart.Position - origin).Unit * (targetPart.Position - origin).Magnitude
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    local result = Workspace:Raycast(origin, direction, raycastParams)
    return result and result.Instance:IsDescendantOf(targetPart.Parent) or false
end

local function GetClosestPlayer()
    local closestPlayer = nil
    local shortestDistance = Modules.Aimbot.FOV
    local mousePos = UserInputService:GetMouseLocation()

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            if IsEnemy(player) then
                local targetPart = player.Character:FindFirstChild(Modules.Aimbot.TargetPart)
                if targetPart then
                    local pos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                    if onScreen then
                        local distance = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                        if distance < shortestDistance and IsVisible(targetPart) then
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

local Window = Rayfield:CreateWindow({
    Name = "TORCIDAS 7",
    LoadingTitle = "Iniciando TORCIDAS 7...",
    LoadingSubtitle = "Otimizado & Seguro",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "Torcidas7Hub",
        FileName = "Config"
    },
    Discord = {
        Enabled = false,
        Invite = "",
        RememberJoins = true 
    },
    KeySystem = false,
})

local TabCombat = Window:CreateTab("Combat", 4483362458)
local TabPlayer = Window:CreateTab("Player", 4483362458)
local TabSettings = Window:CreateTab("Settings", 4483362458)

local SectionAimbot = TabCombat:CreateSection("Aimbot")

local AimbotToggle = TabCombat:CreateToggle({
    Name = "Aimbot Habilitado",
    CurrentValue = false,
    Flag = "AimToggle",
    Callback = function(Value)
        Modules.Aimbot.Enabled = Value
    end,
})

TabCombat:CreateKeybind({
    Name = "Hotkey do Aimbot",
    CurrentKeybind = "Q",
    HoldToInteract = false,
    Flag = "AimBind",
    Callback = function()
        AimbotToggle:Set(not Modules.Aimbot.Enabled)
    end,
})

TabCombat:CreateSlider({
    Name = "FOV Radius",
    Range = {10, 500},
    Increment = 1,
    Suffix = "px",
    CurrentValue = 100,
    Flag = "AimFOV",
    Callback = function(Value)
        Modules.Aimbot.FOV = Value
        FOVCircle.Radius = Value
    end,
})

TabCombat:CreateToggle({
    Name = "Mostrar Círculo do FOV",
    CurrentValue = false,
    Flag = "AimShowFOV",
    Callback = function(Value)
        Modules.Aimbot.ShowFOV = Value
        FOVCircle.Visible = Value
    end,
})

TabCombat:CreateDropdown({
    Name = "Parte do Alvo",
    Options = {"Head", "HumanoidRootPart"},
    CurrentOption = {"Head"},
    MultipleOptions = false,
    Flag = "AimTarget",
    Callback = function(Option)
        Modules.Aimbot.TargetPart = Option[1]
    end,
})

TabCombat:CreateSlider({
    Name = "Smoothness",
    Range = {1, 10},
    Increment = 0.1,
    Suffix = "",
    CurrentValue = 1,
    Flag = "AimSmooth",
    Callback = function(Value)
        Modules.Aimbot.Smoothness = Value
    end,
})

TabCombat:CreateToggle({
    Name = "Team Check",
    CurrentValue = false,
    Flag = "AimTeam",
    Callback = function(Value)
        Modules.Aimbot.TeamCheck = Value
    end,
})

TabCombat:CreateToggle({
    Name = "Wall Check",
    CurrentValue = false,
    Flag = "AimWall",
    Callback = function(Value)
        Modules.Aimbot.WallCheck = Value
    end,
})

local SectionHitbox = TabCombat:CreateSection("Hitbox Expander")

TabCombat:CreateToggle({
    Name = "Habilitar Hitbox",
    CurrentValue = false,
    Flag = "HitboxToggle",
    Callback = function(Value)
        Modules.Hitbox.Enabled = Value
        if not Value then
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local hrp = player.Character.HumanoidRootPart
                    if Modules.Hitbox.OriginalStates[player.Name] then
                        hrp.Size = Modules.Hitbox.OriginalStates[player.Name].Size
                        hrp.Transparency = Modules.Hitbox.OriginalStates[player.Name].Transparency
                        hrp.Color = Modules.Hitbox.OriginalStates[player.Name].Color
                        hrp.Material = Modules.Hitbox.OriginalStates[player.Name].Material
                        hrp.CanCollide = Modules.Hitbox.OriginalStates[player.Name].CanCollide
                    end
                end
            end
        end
    end,
})

TabCombat:CreateSlider({
    Name = "Tamanho da Hitbox",
    Range = {2, 50},
    Increment = 1,
    Suffix = "studs",
    CurrentValue = 2,
    Flag = "HitboxSize",
    Callback = function(Value)
        Modules.Hitbox.Size = Value
    end,
})

TabCombat:CreateColorPicker({
    Name = "Cor da Hitbox",
    Color = Color3.fromRGB(255, 0, 0),
    Flag = "HitboxColor",
    Callback = function(Value)
        Modules.Hitbox.Color = Value
    end
})

TabCombat:CreateSlider({
    Name = "Transparência da Hitbox",
    Range = {0, 100},
    Increment = 1,
    Suffix = "%",
    CurrentValue = 50,
    Flag = "HitboxTrans",
    Callback = function(Value)
        Modules.Hitbox.Transparency = Value / 100
    end,
})

local SectionMovement = TabPlayer:CreateSection("Movimentação")

local SpeedLabel = TabPlayer:CreateLabel("Velocidade Atual: 16")

TabPlayer:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 300},
    Increment = 1,
    Suffix = "WS",
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
    Suffix = "JP",
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
    Callback = function(Value)
        Modules.Player.InfJump = Value
    end,
})

TabPlayer:CreateToggle({
    Name = "NoClip",
    CurrentValue = false,
    Flag = "PlayerNoclip",
    Callback = function(Value)
        Modules.Player.Noclip = Value
    end,
})

TabPlayer:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Flag = "PlayerFly",
    Callback = function(Value)
        Modules.Player.Fly = Value
    end,
})

local SectionVisuals = TabPlayer:CreateSection("Visuais & Utilitários")

TabPlayer:CreateToggle({
    Name = "Player ESP",
    CurrentValue = false,
    Flag = "PlayerESP",
    Callback = function(Value)
        Modules.Player.ESP = Value
        if not Value then
            for _, p in pairs(Players:GetPlayers()) do
                if p.Character and p.Character:FindFirstChild("ESPHighlight") then
                    p.Character.ESPHighlight:Destroy()
                end
            end
        end
    end,
})

TabPlayer:CreateButton({
    Name = "Reset Character",
    Callback = function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.Health = 0
        end
    end,
})

TabPlayer:CreateButton({
    Name = "Teleport para Spawn",
    Callback = function()
        local spawns = Workspace:FindFirstChild("SpawnLocation", true)
        if spawns and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.CFrame = spawns.CFrame + Vector3.new(0, 5, 0)
        end
    end,
})

TabPlayer:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end,
})

local SectionConfig = TabSettings:CreateSection("Configurações do Hub")

TabSettings:CreateToggle({
    Name = "Notificações do Sistema",
    CurrentValue = true,
    Flag = "SettingsNotif",
    Callback = function(Value)
        Modules.Player.Notifications = Value
    end,
})

TabSettings:CreateButton({
    Name = "Salvar Configurações",
    Callback = function()
        Rayfield:SaveConfiguration()
        Notify("Configurações", "Salvas com sucesso!")
    end,
})

TabSettings:CreateButton({
    Name = "Carregar Configurações",
    Callback = function()
        Rayfield:LoadConfiguration()
        Notify("Configurações", "Carregadas com sucesso!")
    end,
})

TabSettings:CreateButton({
    Name = "Resetar Configurações",
    Callback = function()
        delfile("Torcidas7Hub/Config.txt")
        Notify("Configurações", "Arquivo de configuração deletado.")
    end,
})

TabSettings:CreateDropdown({
    Name = "Trocar Tema (Requer Re-execução)",
    Options = {"Default", "DarkBlue", "Light", "Ocean"},
    CurrentOption = {"Default"},
    MultipleOptions = false,
    Flag = "SettingsTheme",
    Callback = function(Option)
        Notify("Tema", "Alterado para " .. Option[1] .. ". Salve e re-execute.")
    end,
})

TabSettings:CreateButton({
    Name = "Copiar Link do Discord",
    Callback = function()
        setclipboard("https://discord.gg/torcidas7")
        Notify("Discord", "Link copiado para a área de transferência!")
    end,
})

TabSettings:CreateButton({
    Name = "Minimizar Interface (Ou aperte K)",
    Callback = function()
        -- Minimizar é controlado nativamente pelo Keybind principal do Rayfield.
    end,
})

TabSettings:CreateButton({
    Name = "Destruir GUI",
    Callback = function()
        CleanUp()
        Rayfield:Destroy()
    end,
})

local SectionInfo = TabSettings:CreateSection("Sobre")
TabSettings:CreateLabel("Hub: TORCIDAS 7")
TabSettings:CreateLabel("Versão: 1.0.0 (Stable)")
TabSettings:CreateLabel("Status: Undetected")

Modules.Connections.RenderStepped = RunService.RenderStepped:Connect(function()
    FOVCircle.Position = UserInputService:GetMouseLocation()
    
    if Modules.Aimbot.Enabled then
        local target = GetClosestPlayer()
        if target and target.Character and target.Character:FindFirstChild(Modules.Aimbot.TargetPart) then
            local targetPos = target.Character[Modules.Aimbot.TargetPart].Position
            local currentCamCFrame = Camera.CFrame
            local targetCamCFrame = CFrame.new(currentCamCFrame.Position, targetPos)
            if Modules.Aimbot.Smoothness > 1 then
                Camera.CFrame = currentCamCFrame:Lerp(targetCamCFrame, 1 / Modules.Aimbot.Smoothness)
            else
                Camera.CFrame = targetCamCFrame
            end
        end
    end

    if Modules.Player.ESP then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local highlight = p.Character:FindFirstChild("ESPHighlight")
                if not highlight then
                    highlight = Instance.new("Highlight")
                    highlight.Name = "ESPHighlight"
                    highlight.Parent = p.Character
                    highlight.FillColor = Color3.fromRGB(255, 255, 255)
                    highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
                    highlight.FillTransparency = 0.5
                    highlight.OutlineTransparency = 0
                end
                highlight.FillColor = IsEnemy(p) and Color3.fromRGB(255,0,0) or Color3.fromRGB(0,255,0)
            end
        end
    end
end)

Modules.Connections.Stepped = RunService.Stepped:Connect(function()
    if Modules.Hitbox.Enabled then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and IsEnemy(player) and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = player.Character.HumanoidRootPart
                if not Modules.Hitbox.OriginalStates[player.Name] then
                    Modules.Hitbox.OriginalStates[player.Name] = {
                        Size = hrp.Size,
                        Transparency = hrp.Transparency,
                        Color = hrp.Color,
                        Material = hrp.Material,
                        CanCollide = hrp.CanCollide
                    }
                end
                hrp.Size = Vector3.new(Modules.Hitbox.Size, Modules.Hitbox.Size, Modules.Hitbox.Size)
                hrp.Transparency = Modules.Hitbox.Transparency
                hrp.Color = Modules.Hitbox.Color
                hrp.Material = Enum.Material.ForceField
                hrp.CanCollide = false
            end
        end
    end

    if Modules.Player.Noclip and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

Modules.Connections.Heartbeat = RunService.Heartbeat:Connect(function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local velocity = LocalPlayer.Character.HumanoidRootPart.Velocity.Magnitude
        SpeedLabel:Set("Velocidade Atual: " .. math.floor(velocity))
        
        if Modules.Player.Fly then
            local hrp = LocalPlayer.Character.HumanoidRootPart
            hrp.Velocity = Vector3.new(0,0,0)
            local moveDir = LocalPlayer.Character.Humanoid.MoveDirection
            if moveDir.Magnitude > 0 then
                hrp.CFrame = hrp.CFrame + (Camera.CFrame.LookVector * (moveDir.Z * -1) * (Modules.Player.FlySpeed/100))
                hrp.CFrame = hrp.CFrame + (Camera.CFrame.RightVector * moveDir.X * (Modules.Player.FlySpeed/100))
            end
        end
    end
end)

Modules.Connections.JumpRequest = UserInputService.JumpRequest:Connect(function()
    if Modules.Player.InfJump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

Modules.Connections.AntiAFK = LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0,0), Camera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0,0), Camera.CFrame)
end)

Rayfield:LoadConfiguration()
Notify("TORCIDAS 7", "Injetado com sucesso!")

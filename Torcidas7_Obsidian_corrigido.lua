-- ====================================================================
-- TORCIDAS 7 - OBSIDIAN UI (CORRIGIDO)
-- ====================================================================

-- Carrega a Obsidian UI
local Library

local libSuccess, libResult = pcall(function()
    return loadstring(
        game:HttpGet(
            "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/Library.lua"
        )
    )()
end)

if libSuccess and libResult then
    Library = libResult
else
    warn("Failed to load UI Library")
    return
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- ====================================================================
-- ESTADOS
-- ====================================================================

local Running = true

local Modules = {
    Connections = {},
    Hitbox = {
        Enabled = false,
        TeamCheck = false,
        Size = 2,
        Color = Color3.fromRGB(255, 0, 0),
        Transparency = 0.5
    },
    Player = {
        WalkSpeed = 16,
        JumpPower = 50,
        Gravity = 196,
        InfJump = false,
        Noclip = false,
        AutoStand = false,
        Notifications = true,
        AutoSprint = false,
        -- Só mexe nos valores do jogo quando o recurso está realmente ativo
        SpeedActive = false,
        CustomSpeed = false,
        JumpActive = false,
        GravityActive = false
    },
    ESP = {
        Enabled = false,
        TeamCheck = false,
        Chams = false
    },
    Trolls = {
        Spin = false,
        SpinSpeed = 30,
        SelectedTarget = "",
        LoopTP = false,
        HeadSit = false
    },
    Defense = {
        GodMode = false,
        AutoHeal = false,
        HealThreshold = 50,
        NoFallDamage = false
    },
    Visual = {
        FOV = 70,
        FOVActive = false
    },
    Waypoints = {
        SavedPosition = nil
    }
}

-- Valores originais, para restaurar ao desativar / destruir o menu
local Original = {
    WalkSpeed = 16,
    JumpPower = 50,
    Gravity = Workspace.Gravity,
    FOV = 70
}

do
    local char = LocalPlayer.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")

    if humanoid then
        Original.WalkSpeed = humanoid.WalkSpeed
        Original.JumpPower = humanoid.JumpPower
    end

    local camera = Workspace.CurrentCamera
    if camera then
        Original.FOV = camera.FieldOfView
    end
end

-- Estado salvo das hitboxes (chave fraca: some quando o personagem some)
local SavedHitboxes = setmetatable({}, {__mode = "k"})
local SavedCollision = setmetatable({}, {__mode = "k"})

-- ====================================================================
-- FUNÇÕES AUXILIARES
-- ====================================================================

local function Track(connection)
    table.insert(Modules.Connections, connection)
    return connection
end

local function Notify(title, content, duration)
    if Modules.Player.Notifications and Library.Notify then
        Library:Notify({
            Title = title,
            Description = content,
            Time = duration or 3
        })
    end
end

local function GetHumanoid()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function GetRoot()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function IsEnemy(player, teamCheck)
    if not teamCheck then
        return true
    end

    return player.Team ~= LocalPlayer.Team
end

local function GetPlayerNames()
    local names = {}

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(names, player.Name)
        end
    end

    return names
end

local function UpdateMovementFlags()
    local wasActive = Modules.Player.SpeedActive

    Modules.Player.SpeedActive =
        Modules.Player.CustomSpeed or Modules.Player.AutoSprint

    if wasActive and not Modules.Player.SpeedActive then
        local humanoid = GetHumanoid()
        if humanoid then
            humanoid.WalkSpeed = Original.WalkSpeed
        end
    end
end

local function RestoreHitbox(hrp)
    local saved = SavedHitboxes[hrp]

    if not saved then
        return
    end

    pcall(function()
        hrp.Size = saved.Size
        hrp.Transparency = saved.Transparency
        hrp.Color = saved.Color
        hrp.Material = saved.Material
        hrp.CanCollide = saved.CanCollide
    end)

    SavedHitboxes[hrp] = nil
end

local function RefreshESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local highlight = player.Character:FindFirstChild("ESPHighlight")

            if Modules.ESP.Enabled
                and IsEnemy(player, Modules.ESP.TeamCheck) then

                if not highlight then
                    highlight = Instance.new("Highlight")
                    highlight.Name = "ESPHighlight"
                    highlight.Parent = player.Character
                end

                highlight.FillColor = Color3.fromRGB(255, 0, 0)
                highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                highlight.FillTransparency = Modules.ESP.Chams and 0.5 or 1
                highlight.OutlineTransparency = 0
                highlight.Enabled = true
            elseif highlight then
                highlight:Destroy()
            end
        end
    end
end

-- ====================================================================
-- LIMPEZA (usada ao destruir o menu)
-- ====================================================================

local ClearGodConnections
local Cleaned = false

local function Cleanup()
    if Cleaned then
        return
    end

    Cleaned = true
    Running = false

    for _, connection in ipairs(Modules.Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    table.clear(Modules.Connections)
    ClearGodConnections()

    for _, player in ipairs(Players:GetPlayers()) do
        local char = player.Character

        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                RestoreHitbox(hrp)
            end

            for part, originalCanCollide in pairs(SavedCollision) do
                if part and part:IsDescendantOf(char) then
                    pcall(function() part.CanCollide = originalCanCollide end)
                    SavedCollision[part] = nil
                end
            end

            local highlight = char:FindFirstChild("ESPHighlight")
            if highlight then
                highlight:Destroy()
            end
        end
    end

    local humanoid = GetHumanoid()
    if humanoid then
        humanoid.WalkSpeed = Original.WalkSpeed
        humanoid.JumpPower = Original.JumpPower
    end

    Workspace.Gravity = Original.Gravity

    local camera = Workspace.CurrentCamera
    if camera then
        camera.FieldOfView = Original.FOV
    end
end

if typeof(Library.OnUnload) == "function" then
    Library:OnUnload(Cleanup)
end

-- ====================================================================
-- GOD MODE
-- ====================================================================

local GodConnections = {}

ClearGodConnections = function()
    for _, connection in ipairs(GodConnections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    table.clear(GodConnections)
end

local function SetupGodMode(char)
    ClearGodConnections()

    local humanoid = char:WaitForChild("Humanoid", 5)
    if not humanoid or not Running then
        return
    end

    table.insert(GodConnections, humanoid.HealthChanged:Connect(function(health)
        if Modules.Defense.GodMode and health < humanoid.MaxHealth then
            humanoid.Health = humanoid.MaxHealth
        end
    end))

    table.insert(GodConnections, humanoid.StateChanged:Connect(function(_, newState)
        if Modules.Defense.GodMode and newState == Enum.HumanoidStateType.Dead then
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            humanoid.Health = humanoid.MaxHealth
        end
    end))
end

if LocalPlayer.Character then
    task.spawn(SetupGodMode, LocalPlayer.Character)
end

Track(LocalPlayer.CharacterAdded:Connect(SetupGodMode))

-- ====================================================================
-- INFINITE JUMP
-- ====================================================================

Track(UserInputService.JumpRequest:Connect(function()
    if not Modules.Player.InfJump then
        return
    end

    local humanoid = GetHumanoid()

    if humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end))

-- ====================================================================
-- LOOP PRINCIPAL
-- ====================================================================

Track(RunService.Stepped:Connect(function()
    local char = LocalPlayer.Character
    if not char then
        return
    end

    local humanoid = char:FindFirstChildOfClass("Humanoid")

    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            if Modules.Player.Noclip then
                if SavedCollision[part] == nil then
                    SavedCollision[part] = part.CanCollide
                end
                part.CanCollide = false
            elseif SavedCollision[part] ~= nil then
                part.CanCollide = SavedCollision[part]
                SavedCollision[part] = nil
            end
        end
    end

    if Modules.Player.AutoStand and humanoid then
        if humanoid:GetState() == Enum.HumanoidStateType.Physics then
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end

    if Modules.Defense.NoFallDamage and humanoid then
        local state = humanoid:GetState()

        if state == Enum.HumanoidStateType.FallingDown
            or state == Enum.HumanoidStateType.Ragdoll then
            humanoid:ChangeState(Enum.HumanoidStateType.Running)
        end
    end
end))

Track(RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    if not char then
        return
    end

    local root = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildOfClass("Humanoid")

    if humanoid then
        if Modules.Player.SpeedActive then
            humanoid.WalkSpeed =
                Modules.Player.AutoSprint
                and (Modules.Player.WalkSpeed * 1.5)
                or Modules.Player.WalkSpeed
        end

        if Modules.Player.JumpActive then
            humanoid.UseJumpPower = true
            humanoid.JumpPower = Modules.Player.JumpPower
        end
    end

    local camera = Workspace.CurrentCamera
    if camera and Modules.Visual.FOVActive then
        camera.FieldOfView = Modules.Visual.FOV
    end

    if Modules.Player.GravityActive then
        Workspace.Gravity = Modules.Player.Gravity
    end

    if Modules.Trolls.Spin and root then
        root.CFrame =
            root.CFrame *
            CFrame.Angles(0, math.rad(Modules.Trolls.SpinSpeed), 0)
    end

    if Modules.Trolls.SelectedTarget ~= "" then
        local target =
            Players:FindFirstChild(Modules.Trolls.SelectedTarget)

        if target and target.Character then
            local targetRoot =
                target.Character:FindFirstChild("HumanoidRootPart")
            local targetHead =
                target.Character:FindFirstChild("Head")

            if Modules.Trolls.LoopTP and root and targetRoot then
                root.CFrame =
                    targetRoot.CFrame *
                    CFrame.new(0, 0, 3)
            elseif Modules.Trolls.HeadSit and root and targetHead then
                root.CFrame =
                    targetHead.CFrame *
                    CFrame.new(0, 1.5, 0)
            end
        end
    end
end))

-- ====================================================================
-- HITBOX + ESP (loop lento)
-- ====================================================================

task.spawn(function()
    while Running do
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local hrp =
                    player.Character:FindFirstChild("HumanoidRootPart")

                if hrp then
                    if Modules.Hitbox.Enabled
                        and IsEnemy(player, Modules.Hitbox.TeamCheck) then

                        if not SavedHitboxes[hrp] then
                            SavedHitboxes[hrp] = {
                                Size = hrp.Size,
                                Transparency = hrp.Transparency,
                                Color = hrp.Color,
                                Material = hrp.Material,
                                CanCollide = hrp.CanCollide
                            }
                        end

                        hrp.Size = Vector3.new(
                            Modules.Hitbox.Size,
                            Modules.Hitbox.Size,
                            Modules.Hitbox.Size
                        )
                        hrp.Transparency = Modules.Hitbox.Transparency
                        hrp.Color = Modules.Hitbox.Color
                        hrp.Material = Enum.Material.Neon
                        hrp.CanCollide = false
                    else
                        RestoreHitbox(hrp)
                    end
                end
            end
        end

        RefreshESP()

        task.wait(0.5)
    end
end)

-- ====================================================================
-- AUTO HEAL
-- ====================================================================

task.spawn(function()
    while Running do
        task.wait(1)

        if Modules.Defense.AutoHeal then
            local char = LocalPlayer.Character
            local humanoid =
                char and char:FindFirstChildOfClass("Humanoid")

            if humanoid and humanoid.Health < Modules.Defense.HealThreshold then
                local backpack = LocalPlayer:FindFirstChild("Backpack")

                local tool =
                    (backpack and backpack:FindFirstChild("Medkit"))
                    or (char and char:FindFirstChild("Medkit"))

                if tool then
                    tool.Parent = char
                    tool:Activate()
                end
            end
        end
    end
end)

-- ====================================================================
-- OBSIDIAN WINDOW
-- ====================================================================

local Window = Library:CreateWindow({
    Title = "Torcidas 7",
    Footer = "By anonymus",
    Center = true,
    AutoShow = true,
    ShowMobileButtons = true
})

-- ====================================================================
-- TAB: COMBAT
-- ====================================================================

local CombatTab = Window:AddTab("Combat")
local HitboxBox = CombatTab:AddLeftGroupbox("Hitbox")

HitboxBox:AddToggle("HitboxEnabled", {
    Text = "Expandir Hitbox",
    Default = false,
    Callback = function(value)
        Modules.Hitbox.Enabled = value
    end
})

HitboxBox:AddToggle("HitboxTeamCheck", {
    Text = "Team Check",
    Default = false,
    Callback = function(value)
        Modules.Hitbox.TeamCheck = value
    end
})

HitboxBox:AddSlider("HitboxSize", {
    Text = "Tamanho da Hitbox",
    Default = 2,
    Min = 2,
    Max = 50,
    Rounding = 0,
    Callback = function(value)
        Modules.Hitbox.Size = value
    end
})

HitboxBox:AddSlider("HitboxTransparency", {
    Text = "Transparência",
    Default = 0.5,
    Min = 0,
    Max = 1,
    Rounding = 1,
    Callback = function(value)
        Modules.Hitbox.Transparency = value
    end
})

pcall(function()
    HitboxBox:AddLabel("Cor da Hitbox"):AddColorPicker("HitboxColor", {
        Default = Modules.Hitbox.Color,
        Title = "Cor da Hitbox",
        Callback = function(value)
            Modules.Hitbox.Color = value
        end
    })
end)

-- ====================================================================
-- TAB: PLAYER
-- ====================================================================

local PlayerTab = Window:AddTab("Player")
local MoveBox = PlayerTab:AddLeftGroupbox("Movimento")
local ProtectBox = PlayerTab:AddRightGroupbox("Proteção")

MoveBox:AddSlider("WalkSpeed", {
    Text = "Velocidade",
    Default = Original.WalkSpeed,
    Min = 1,
    Max = 250,
    Rounding = 0,
    Callback = function(value)
        Modules.Player.WalkSpeed = value
        Modules.Player.CustomSpeed = math.abs(value - Original.WalkSpeed) > 0.01
        UpdateMovementFlags()
    end
})

MoveBox:AddSlider("JumpPower", {
    Text = "Pulo",
    Default = Original.JumpPower,
    Min = 1,
    Max = 300,
    Rounding = 0,
    Callback = function(value)
        Modules.Player.JumpPower = value

        local active = math.abs(value - Original.JumpPower) > 0.01

        if Modules.Player.JumpActive and not active then
            local humanoid = GetHumanoid()
            if humanoid then
                humanoid.JumpPower = Original.JumpPower
            end
        end

        Modules.Player.JumpActive = active
    end
})

MoveBox:AddToggle("InfJump", {
    Text = "Pulo Infinito",
    Default = false,
    Callback = function(value)
        Modules.Player.InfJump = value
    end
})

MoveBox:AddToggle("Noclip", {
    Text = "Noclip",
    Default = false,
    Callback = function(value)
        Modules.Player.Noclip = value
    end
})

MoveBox:AddToggle("AutoSprint", {
    Text = "Auto Sprint",
    Default = false,
    Callback = function(value)
        Modules.Player.AutoSprint = value
        UpdateMovementFlags()
    end
})

MoveBox:AddSlider("Gravity", {
    Text = "Gravidade",
    Default = math.clamp(math.floor(Original.Gravity + 0.5), 0, 500),
    Min = 0,
    Max = 500,
    Rounding = 0,
    Callback = function(value)
        Modules.Player.Gravity = value

        local active = math.abs(value - Original.Gravity) > 0.5

        if Modules.Player.GravityActive and not active then
            Workspace.Gravity = Original.Gravity
        end

        Modules.Player.GravityActive = active
    end
})

ProtectBox:AddToggle("GodMode", {
    Text = "God Mode",
    Default = false,
    Callback = function(value)
        Modules.Defense.GodMode = value
        Notify(
            "Proteção",
            value and "God Mode ativado" or "God Mode desativado",
            2
        )
    end
})

ProtectBox:AddToggle("NoFallDamage", {
    Text = "Sem Dano de Queda",
    Default = false,
    Callback = function(value)
        Modules.Defense.NoFallDamage = value
    end
})

ProtectBox:AddToggle("AutoStand", {
    Text = "Levantar Automático",
    Default = false,
    Callback = function(value)
        Modules.Player.AutoStand = value
    end
})

-- ====================================================================
-- TAB: ESP
-- ====================================================================

local ESPTab = Window:AddTab("ESP")
local ESPBox = ESPTab:AddLeftGroupbox("ESP")

ESPBox:AddToggle("ESPEnabled", {
    Text = "Ativar ESP Geral",
    Default = false,
    Callback = function(value)
        Modules.ESP.Enabled = value
        RefreshESP()
    end
})

ESPBox:AddToggle("Chams", {
    Text = "Chams (preenchimento)",
    Default = false,
    Callback = function(value)
        Modules.ESP.Chams = value
        RefreshESP()
    end
})

ESPBox:AddToggle("TeamCheck", {
    Text = "Team Check",
    Default = false,
    Callback = function(value)
        Modules.ESP.TeamCheck = value
        RefreshESP()
    end
})

-- ====================================================================
-- TAB: TROLLS
-- ====================================================================

local TrollTab = Window:AddTab("Trolls")
local TargetBox = TrollTab:AddLeftGroupbox("Alvo")
local TrollBox = TrollTab:AddRightGroupbox("Trolls")

TargetBox:AddDropdown("Target", {
    Values = GetPlayerNames(),
    Multi = false,
    Text = "Selecionar Alvo",
    Callback = function(value)
        if type(value) == "table" then
            Modules.Trolls.SelectedTarget = value[1] or ""
        else
            Modules.Trolls.SelectedTarget = value or ""
        end
    end
})

local function RefreshTargetList()
    pcall(function()
        local dropdown = Library.Options.Target

        if dropdown and dropdown.SetValues then
            dropdown:SetValues(GetPlayerNames())
        end
    end)
end

TargetBox:AddButton({
    Text = "Atualizar Lista",
    Func = RefreshTargetList
})

Track(Players.PlayerAdded:Connect(function()
    task.wait(0.5)
    RefreshTargetList()
end))

Track(Players.PlayerRemoving:Connect(function()
    task.defer(RefreshTargetList)
end))

TrollBox:AddToggle("Spin", {
    Text = "Spin",
    Default = false,
    Callback = function(value)
        Modules.Trolls.Spin = value
    end
})

TrollBox:AddSlider("SpinSpeed", {
    Text = "Velocidade do Spin",
    Default = 30,
    Min = 10,
    Max = 100,
    Rounding = 0,
    Callback = function(value)
        Modules.Trolls.SpinSpeed = value
    end
})

TrollBox:AddToggle("LoopTP", {
    Text = "Loop TP no Alvo",
    Default = false,
    Callback = function(value)
        Modules.Trolls.LoopTP = value
    end
})

TrollBox:AddToggle("HeadSit", {
    Text = "Sentar na Cabeça do Alvo",
    Default = false,
    Callback = function(value)
        Modules.Trolls.HeadSit = value
    end
})

-- ====================================================================
-- TAB: DEFESA / TELEPORT
-- ====================================================================

local DefenseTab = Window:AddTab("Defesa / Teleport")
local HealBox = DefenseTab:AddLeftGroupbox("Cura")
local TeleportBox = DefenseTab:AddRightGroupbox("Teleport")

HealBox:AddToggle("AutoHeal", {
    Text = "Auto Cura",
    Default = false,
    Callback = function(value)
        Modules.Defense.AutoHeal = value
    end
})

HealBox:AddSlider("HealThreshold", {
    Text = "Limite de Vida",
    Default = 50,
    Min = 10,
    Max = 90,
    Rounding = 0,
    Callback = function(value)
        Modules.Defense.HealThreshold = value
    end
})

TeleportBox:AddButton({
    Text = "Salvar Posição Atual",
    Func = function()
        local root = GetRoot()

        if root then
            Modules.Waypoints.SavedPosition = root.CFrame
            Notify("Waypoint", "Posição salva!", 2)
        end
    end
})

TeleportBox:AddButton({
    Text = "Teleportar para Posição Salva",
    Func = function()
        local root = GetRoot()

        if root and Modules.Waypoints.SavedPosition then
            root.CFrame = Modules.Waypoints.SavedPosition
            Notify("Waypoint", "Teleportado!", 2)
        else
            Notify("Erro", "Nenhuma posição salva.", 2)
        end
    end
})

-- ====================================================================
-- TAB: VISUAIS
-- ====================================================================

local VisualTab = Window:AddTab("Visuais")
local CameraBox = VisualTab:AddLeftGroupbox("Câmera")

CameraBox:AddSlider("FOV", {
    Text = "Campo de Visão (FOV)",
    Default = math.clamp(math.floor(Original.FOV + 0.5), 30, 120),
    Min = 30,
    Max = 120,
    Rounding = 0,
    Callback = function(value)
        Modules.Visual.FOV = value

        local active = math.abs(value - Original.FOV) > 0.5

        if Modules.Visual.FOVActive and not active then
            local camera = Workspace.CurrentCamera
            if camera then
                camera.FieldOfView = Original.FOV
            end
        end

        Modules.Visual.FOVActive = active
    end
})

-- ====================================================================
-- TAB: SETTINGS
-- ====================================================================

local SettingsTab = Window:AddTab("Settings")
local SettingsBox = SettingsTab:AddLeftGroupbox("Menu")

SettingsBox:AddToggle("Notifications", {
    Text = "Notificações",
    Default = true,
    Callback = function(value)
        Modules.Player.Notifications = value
    end
})

SettingsBox:AddButton({
    Text = "Destruir Menu",
    Func = function()
        Cleanup()

        if Library.Unload then
            Library:Unload()
        end
    end
})

SettingsBox:AddLabel("Torcidas 7")
SettingsBox:AddLabel("Versão: Obsidian UI")

Notify(
    "Torcidas 7",
    "Hub carregado com sucesso para " .. LocalPlayer.Name .. "!",
    5
)

-- ====================================================================
-- INICIALIZAÇÃO DA BIBLIOTECA E SERVIÇOS
-- ====================================================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ====================================================================
-- SISTEMA DE KEY, WHITELIST E VALIDADE
-- ====================================================================

-- [CONFIGURAÇÃO DE KEYS LOCAIS]
-- Adicione os usuários, keys e a data de expiração no formato "YYYY-MM-DD"
local WhitelistDB = {
    ["teteu-vip7"]   = { User = "teteu9090900", Expires = "2026-08-27" },
    ["SCRIPT7VIP"]   = { User = LocalPlayer.Name, Expires = "2026-12-31" }, -- Sua key pessoal para testes
    ["KEY-EXEMPLO"]  = { User = "OutroJogador123", Expires = "2026-08-15" }
}

-- [OPCIONAL: BANCO DE DADOS NA NUVEM]
-- Se colar um link Raw de Pastebin/GitHub aqui em formato JSON, o script baixa da nuvem
local RemoteDatabaseURL = "" 

if RemoteDatabaseURL ~= "" then
    local success, result = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(RemoteDatabaseURL))
    end)
    if success and type(result) == "table" then
        WhitelistDB = result
    end
end

-- Função para converter "YYYY-MM-DD" em Timestamp Unix
local function DateToTimestamp(dateStr)
    local year, month, day = dateStr:match("(%d+)-(%d+)-(%d+)")
    if year and month and day then
        return os.time({
            year = tonumber(year),
            month = tonumber(month),
            day = tonumber(day),
            hour = 23, min = 59, sec = 59
        })
    end
    return 0
end

-- Filtra apenas as keys válidas pertencentes ao jogador que está executando
local ValidKeysForLocalPlayer = {}
local LocalUserExpiration = "Indefinido"

for key, data in pairs(WhitelistDB) do
    if string.lower(data.User) == string.lower(LocalPlayer.Name) then
        local expTimestamp = DateToTimestamp(data.Expires)
        if os.time() <= expTimestamp then
            table.insert(ValidKeysForLocalPlayer, key)
            LocalUserExpiration = data.Expires
        end
    end
end

-- Se o jogador não tiver nenhuma key cadastrada ou válida
if #ValidKeysForLocalPlayer == 0 then
    table.insert(ValidKeysForLocalPlayer, "KEY_BLOQUEADA_OU_EXPIRADA_" .. math.random(100000, 999999))
end

-- ====================================================================
-- TABELA DE MÓDULOS DE ESTADO
-- ====================================================================
local Modules = {
    Connections = {},
    OriginalSizes = {},
    Hitbox = { Enabled = false, Size = 2, Color = Color3.fromRGB(255,0,0), Transparency = 0.5 },
    Player = {
        WalkSpeed = 16, JumpPower = 50, InfJump = false, Noclip = false,
        AutoStand = false, NoPlayerCollision = false,
        Notifications = true, AutoSprint = false,
        Gravity = 196.2, Scale = 1
    },
    ESP = {
        Enabled = false, Box = false, Skeleton = false, Health = false,
        Tracers = false, Names = false, TeamCheck = false, Items = false,
        Chams = false
    },
    Trolls = {
        Spin = false, SpinSpeed = 30, SelectedTarget = "",
        LoopTP = false, HeadSit = false, Invisible = false,
        Freeze = false
    },
    Defense = {
        GodMode = false, AutoHeal = false, HealThreshold = 50,
        NoFallDamage = false
    },
    Auto = {
        Farm = false, FarmTarget = "Coin", MacroRecording = false,
        MacroSequence = {}, MacroPlaying = false
    },
    Visual = { FOV = 70 },
    Waypoints = { SavedPosition = nil }
}

-- ====================================================================
-- FUNÇÕES AUXILIARES E UTILITÁRIAS
-- ====================================================================
local function Notify(title, content, duration)
    if Modules.Player.Notifications then
        Rayfield:Notify({
            Title = title,
            Content = content,
            Duration = duration or 3,
            Image = 4483362458
        })
    end
end

local function GetCharacter(player)
    player = player or LocalPlayer
    return player.Character or player.CharacterAdded:Wait()
end

local function GetRoot(player)
    local char = GetCharacter(player)
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function IsEnemy(player)
    if not Modules.ESP.TeamCheck then return true end
    return player.Team ~= LocalPlayer.Team
end

local function GetPlayerNames()
    local names = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(names, p.Name)
        end
    end
    return names
end

-- ====================================================================
-- SISTEMA DE LOOPS E LÓGICA CORE
-- ====================================================================

-- Infinite Jump
Modules.Connections.InfJump = UserInputService.JumpRequest:Connect(function()
    if Modules.Player.InfJump then
        local char = GetCharacter()
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- Sistema God Mode
local function SetupGodMode(char)
    local humanoid = char:WaitForChild("Humanoid", 5)
    if not humanoid then return end

    humanoid.HealthChanged:Connect(function(health)
        if Modules.Defense.GodMode and health < humanoid.MaxHealth then
            humanoid.Health = humanoid.MaxHealth
        end
    end)

    humanoid.StateChanged:Connect(function(_, newState)
        if Modules.Defense.GodMode and newState == Enum.HumanoidStateType.Dead then
            humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
            humanoid.Health = humanoid.MaxHealth
        end
    end)
end

if LocalPlayer.Character then
    SetupGodMode(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(SetupGodMode)

-- Loop Stepped
RunService.Stepped:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")

    if Modules.Player.Noclip then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end

    if Modules.Player.AutoStand and humanoid and humanoid:GetState() == Enum.HumanoidStateType.Physics then
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    end

    if Modules.Defense.NoFallDamage and humanoid then
        local state = humanoid:GetState()
        if state == Enum.HumanoidStateType.FallingDown or state == Enum.HumanoidStateType.Ragdoll then
            humanoid:ChangeState(Enum.HumanoidStateType.Running)
        end
    end
end)

-- Loop RenderStepped
RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildOfClass("Humanoid")

    if humanoid then
        humanoid.WalkSpeed = Modules.Player.AutoSprint and (Modules.Player.WalkSpeed * 1.5) or Modules.Player.WalkSpeed
        humanoid.UseJumpPower = true
        humanoid.JumpPower = Modules.Player.JumpPower
    end

    Camera.FieldOfView = Modules.Visual.FOV
    Workspace.Gravity = Modules.Player.Gravity

    if Modules.Trolls.Spin and root then
        root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(Modules.Trolls.SpinSpeed), 0)
    end

    if Modules.Trolls.SelectedTarget ~= "" then
        local targetPlayer = Players:FindFirstChild(Modules.Trolls.SelectedTarget)
        if targetPlayer and targetPlayer.Character then
            local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
            local targetHead = targetPlayer.Character:FindFirstChild("Head")

            if Modules.Trolls.LoopTP and root and targetRoot then
                root.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
            elseif Modules.Trolls.HeadSit and root and targetHead then
                root.CFrame = targetHead.CFrame * CFrame.new(0, 1.5, 0)
            end
        end
    end
end)

-- Hitbox Expander Loop
task.spawn(function()
    while task.wait(0.5) do
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    if not Modules.OriginalSizes[player] then
                        Modules.OriginalSizes[player] = { Size = hrp.Size, Transparency = hrp.Transparency }
                    end

                    if Modules.Hitbox.Enabled and IsEnemy(player) then
                        hrp.Size = Vector3.new(Modules.Hitbox.Size, Modules.Hitbox.Size, Modules.Hitbox.Size)
                        hrp.Transparency = Modules.Hitbox.Transparency
                        hrp.Color = Modules.Hitbox.Color
                        hrp.Material = Enum.Material.Neon
                        hrp.CanCollide = false
                    else
                        if Modules.OriginalSizes[player] then
                            hrp.Size = Modules.OriginalSizes[player].Size
                            hrp.Transparency = Modules.OriginalSizes[player].Transparency
                        end
                    end
                end
            end
        end
    end
end)

-- Auto Heal Loop
task.spawn(function()
    while task.wait(1) do
        if Modules.Defense.AutoHeal then
            local char = LocalPlayer.Character
            local humanoid = char and char:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health < Modules.Defense.HealThreshold then
                local tool = LocalPlayer.Backpack:FindFirstChild("Medkit") or char:FindFirstChild("Medkit")
                if tool then
                    tool.Parent = char
                    tool:Activate()
                end
            end
        end
    end
end)

-- ESP / Chams Management
local function ApplyESP(player)
    if player == LocalPlayer then return end
    
    local function UpdateHighlight()
        if not player.Character then return end
        local highlight = player.Character:FindFirstChild("ESPHighlight")
        
        if Modules.ESP.Enabled and Modules.ESP.Chams and IsEnemy(player) then
            if not highlight then
                highlight = Instance.new("Highlight")
                highlight.Name = "ESPHighlight"
                highlight.Parent = player.Character
            end
            highlight.FillColor = Color3.fromRGB(255, 0, 0)
            highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            highlight.FillTransparency = 0.5
            highlight.OutlineTransparency = 0
            highlight.Enabled = true
        elseif highlight then
            highlight:Destroy()
        end
    end

    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        UpdateHighlight()
    end)
    UpdateHighlight()
end

for _, p in ipairs(Players:GetPlayers()) do ApplyESP(p) end
Players.PlayerAdded:Connect(ApplyESP)

-- ====================================================================
-- CRIAÇÃO DA INTERFACE RAYFIELD (SISTEMA DE KEY NATIVO E DINÂMICO)
-- ====================================================================
local Window = Rayfield:CreateWindow({
    Name = "Torcidas 7",
    LoadingTitle = "Carregando Framework Módulo...",
    LoadingSubtitle = "by Assistant",
    ConfigurationSaving = { Enabled = false },
    KeySystem = true,
    KeySettings = {
        Title = "Torcidas 7 | Key System",
        Subtitle = "Validação por Usuário (" .. LocalPlayer.Name .. ")",
        Note = "Pegue sua Key no Discord: https://discord.gg/JS8WDGbus",
        FileName = "Torcidas7KeyConfig",
        SaveKey = true,
        GrabKeyFromSite = false,
        Key = ValidKeysForLocalPlayer
    }
})

-- --------------------------------------------------------------------
-- TAB 1: COMBAT
-- --------------------------------------------------------------------
local CombatTab = Window:CreateTab("Combat", 4483362458)

CombatTab:CreateToggle({
    Name = "Expandir Hitbox",
    CurrentValue = false,
    Callback = function(Value) Modules.Hitbox.Enabled = Value end
})

CombatTab:CreateSlider({
    Name = "Tamanho da Hitbox",
    Range = {2, 50},
    Increment = 1,
    CurrentValue = 2,
    Callback = function(Value) Modules.Hitbox.Size = Value end
})

CombatTab:CreateSlider({
    Name = "Transparência",
    Range = {0, 1},
    Increment = 0.1,
    CurrentValue = 0.5,
    Callback = function(Value) Modules.Hitbox.Transparency = Value end
})

CombatTab:CreateColorPicker({
    Name = "Cor da Hitbox",
    Color = Color3.fromRGB(255, 0, 0),
    Callback = function(Value) Modules.Hitbox.Color = Value end
})

-- --------------------------------------------------------------------
-- TAB 2: PLAYER
-- --------------------------------------------------------------------
local PlayerTab = Window:CreateTab("Player", 4483362458)

PlayerTab:CreateSlider({
    Name = "Velocidade (WalkSpeed)",
    Range = {16, 250},
    Increment = 1,
    CurrentValue = 16,
    Callback = function(Value) Modules.Player.WalkSpeed = Value end
})

PlayerTab:CreateSlider({
    Name = "Pulo (JumpPower)",
    Range = {50, 300},
    Increment = 1,
    CurrentValue = 50,
    Callback = function(Value) Modules.Player.JumpPower = Value end
})

PlayerTab:CreateToggle({
    Name = "Pulo Infinito",
    CurrentValue = false,
    Callback = function(Value) Modules.Player.InfJump = Value end
})

PlayerTab:CreateToggle({
    Name = "Noclip (Atravessar Paredes)",
    CurrentValue = false,
    Callback = function(Value) Modules.Player.Noclip = Value end
})

PlayerTab:CreateToggle({
    Name = "Auto Sprint",
    CurrentValue = false,
    Callback = function(Value) Modules.Player.AutoSprint = Value end
})

PlayerTab:CreateSlider({
    Name = "Gravidade",
    Range = {0, 500},
    Increment = 5,
    CurrentValue = 196,
    Callback = function(Value) Modules.Player.Gravity = Value end
})

PlayerTab:CreateToggle({
    Name = "God Mode",
    CurrentValue = false,
    Callback = function(Value)
        Modules.Defense.GodMode = Value
        Notify("Proteção", Value and "God Mode Ativado" or "God Mode Desativado", 2)
    end
})

PlayerTab:CreateToggle({
    Name = "Sem Dano de Queda",
    CurrentValue = false,
    Callback = function(Value)
        Modules.Defense.NoFallDamage = Value
        Notify("Proteção", Value and "Sem Dano de Queda Ativado" or "Sem Dano de Queda Desativado", 2)
    end
})

-- --------------------------------------------------------------------
-- TAB 3: ESP
-- --------------------------------------------------------------------
local ESPTab = Window:CreateTab("ESP", 4483362458)

ESPTab:CreateToggle({
    Name = "Ativar ESP Geral",
    CurrentValue = false,
    Callback = function(Value) Modules.ESP.Enabled = Value end
})

ESPTab:CreateToggle({
    Name = "Chams (Wallhack)",
    CurrentValue = false,
    Callback = function(Value) 
        Modules.ESP.Chams = Value 
        for _, p in ipairs(Players:GetPlayers()) do ApplyESP(p) end
    end
})

ESPTab:CreateToggle({
    Name = "Team Check (Apenas Inimigos)",
    CurrentValue = false,
    Callback = function(Value) Modules.ESP.TeamCheck = Value end
})

-- --------------------------------------------------------------------
-- TAB 4: TROLLS & TARGET
-- --------------------------------------------------------------------
local TrollTab = Window:CreateTab("Trolls", 4483362458)

local TargetDropdown = TrollTab:CreateDropdown({
    Name = "Selecionar Alvo",
    Options = GetPlayerNames(),
    CurrentOption = {""},
    MultipleOptions = false,
    Callback = function(Value)
        Modules.Trolls.SelectedTarget = type(Value) == "table" and Value[1] or Value
    end
})

TrollTab:CreateButton({
    Name = "Atualizar Lista de Jogadores",
    Callback = function()
        TargetDropdown:Refresh(GetPlayerNames())
    end
})

TrollTab:CreateToggle({
    Name = "Spin (Girar Personagem)",
    CurrentValue = false,
    Callback = function(Value) Modules.Trolls.Spin = Value end
})

TrollTab:CreateSlider({
    Name = "Velocidade do Spin",
    Range = {10, 100},
    Increment = 5,
    CurrentValue = 30,
    Callback = function(Value) Modules.Trolls.SpinSpeed = Value end
})

TrollTab:CreateToggle({
    Name = "Loop TP no Alvo",
    CurrentValue = false,
    Callback = function(Value) Modules.Trolls.LoopTP = Value end
})

TrollTab:CreateToggle({
    Name = "Sentar na Cabeça do Alvo",
    CurrentValue = false,
    Callback = function(Value) Modules.Trolls.HeadSit = Value end
})

-- --------------------------------------------------------------------
-- TAB 5: DEFENSE & WAYPOINTS
-- --------------------------------------------------------------------
local DefenseTab = Window:CreateTab("Defesa / Teleport", 4483362458)

DefenseTab:CreateToggle({
    Name = "Auto Cura",
    CurrentValue = false,
    Callback = function(Value) Modules.Defense.AutoHeal = Value end
})

DefenseTab:CreateSlider({
    Name = "Limite de Vida para Curar (%)",
    Range = {10, 90},
    Increment = 5,
    CurrentValue = 50,
    Callback = function(Value) Modules.Defense.HealThreshold = Value end
})

DefenseTab:CreateButton({
    Name = "Salvar Posição Atual",
    Callback = function()
        local root = GetRoot()
        if root then
            Modules.Waypoints.SavedPosition = root.CFrame
            Notify("Waypoint", "Posição salva com sucesso!", 2)
        end
    end
})

DefenseTab:CreateButton({
    Name = "Teleportar para Posição Salva",
    Callback = function()
        local root = GetRoot()
        if root and Modules.Waypoints.SavedPosition then
            root.CFrame = Modules.Waypoints.SavedPosition
            Notify("Waypoint", "Teleportado com sucesso!", 2)
        else
            Notify("Erro", "Nenhuma posição salva encontrada.", 2)
        end
    end
})

-- --------------------------------------------------------------------
-- TAB 6: VISUALLS
-- --------------------------------------------------------------------
local VisualTab = Window:CreateTab("Visuais", 4483362458)

VisualTab:CreateSlider({
    Name = "Campo de Visão (FOV)",
    Range = {30, 120},
    Increment = 1,
    CurrentValue = 70,
    Callback = function(Value) Modules.Visual.FOV = Value end
})

-- --------------------------------------------------------------------
-- TAB 7: SETTINGS
-- --------------------------------------------------------------------
local SettingsTab = Window:CreateTab("Settings", 4483362458)

SettingsTab:CreateToggle({
    Name = "Notificações",
    CurrentValue = Modules.Player.Notifications,
    Callback = function(Value) Modules.Player.Notifications = Value end
})

SettingsTab:CreateButton({
    Name = "Recarregar Interface",
    Callback = function()
        Notify("Settings", "Interface recarregada com sucesso!", 2)
    end
})

SettingsTab:CreateButton({
    Name = "Destruir Menu",
    Callback = function()
        Rayfield:Destroy()
    end
})

SettingsTab:CreateParagraph({
    Title = "Informações da Licença",
    Content = "Usuário: " .. LocalPlayer.Name .. "\nValidade da Key: " .. LocalUserExpiration .. "\nVersão do Hub: Torcidas 7"
})

Notify("Torcidas 7", "Chave autenticada para " .. LocalPlayer.Name .. "!\nValidade: " .. LocalUserExpiration, 5)

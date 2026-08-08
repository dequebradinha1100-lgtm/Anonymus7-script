local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local Camera = Workspace.CurrentCamera or Workspace:FindFirstChildOfClass("Camera")

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local wdb = {
    ["titeu-vip5"] = {User = "titeu9090900", Expires = "2026-08-27"},
    ["SCRIPTVIP"] = {User = LocalPlayer.Name, Expires = "2026-12-31"},
    ["KEY-nk"] = {User = "seraphisxC55", Expires = "2026-06-08"},
    ["KEY-NOT5"] = {User = "menorkekeq1", Expires = "2026-08-08"},
    ["KEY-BRYAN"] = {User = "Bryan900771", Expires = "2026-08-16"}
}

local rdb = ""
if rdb ~= "" then
    pcall(function()
        local suc, res = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(rdb))
        end)
        if suc and type(res) == "table" then
            wdb = res
        end
    end)
end

local function dt(ds)
    local success, y, m, d = pcall(function()
        return ds:match("(%d+)-(%d+)-(%d+)")
    end)
    if success and y and m and d then
        return os.time({year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = 23, min = 59, sec = 59})
    end
    return 0
end

local vk = {}
local lex = "Undefined"
for k, dt2 in pairs(wdb) do
    if dt2 and dt2.User and dt2.Expires and string.lower(dt2.User) == string.lower(LocalPlayer.Name) then
        local et = dt(dt2.Expires)
        if os.time() <= et then
            table.insert(vk, k)
            lex = dt2.Expires
        end
    end
end

if #vk == 0 then
    table.insert(vk, "KEY_BLOQUEADOS_OU_EXPIRADOS_" .. math.random(100000, 999999))
end

local mod = {
    Connections = {},
    OriginalSizes = {},
    Hitbox = {Enabled = false, Size = 2, Color = Color3.fromRGB(255, 0, 0), Transparency = 0.5},
    Player = {WalkSpeed = 16, JumpPower = 50, InfJump = false, Noclip = false, AutoStand = false, NoPlayerCollision = false, Notifications = true, AutoSprint = false, Gravity = 196.2, Scale = 1},
    ESP = {Enabled = false, Box = false, Skeleton = false, Health = false, Tracers = false, Names = false, TeamCheck = false, Items = false, Chams = false},
    Trolls = {Spin = false, SpinSpeed = 30, SelectedTarget = "", LoopTP = false, HeadSit = false, Invisible = false, Freeze = false},
    Defense = {GodMode = false, AutoHeal = false, HealThreshold = 50, NoFallDamage = false},
    Auto = {Farm = false, FarmTarget = "Coin", MacroRecording = false, MacroSequence = {}, MacroPlaying = false},
    Visual = {FOV = 70},
    Waypoints = {SavedPosition = nil}
}

local function nt(ti, co, du)
    pcall(function()
        if mod.Player.Notifications and Rayfield and Rayfield.Notify then
            Rayfield:Notify({Title = ti, Content = co, Duration = du or 3, Image = 4483362458})
        end
    end)
end

local function gc(p)
    p = p or LocalPlayer
    return p.Character or p.CharacterAdded:Wait()
end

local function gr(p)
    local ch = gc(p)
    return ch and ch:FindFirstChild("HumanoidRootPart")
end

local function ie(p)
    if not mod.ESP.TeamCheck then return true end
    return p.Team ~= LocalPlayer.Team
end

local function gpn()
    local ns = {}
    for _, p2 in ipairs(Players:GetPlayers()) do
        if p2 ~= LocalPlayer then
            table.insert(ns, p2.Name)
        end
    end
    if #ns == 0 then
        table.insert(ns, "Nenhum")
    end
    return ns
end

mod.Connections.InfJump = UserInputService.JumpRequest:Connect(function()
    if mod.Player.InfJump then
        local ch = gc()
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

local function sgm(ch)
    if not ch then return end
    local hum = ch:WaitForChild("Humanoid", 5)
    if not hum then return end
    hum.HealthChanged:Connect(function(h)
        if mod.Defense.GodMode and h < hum.MaxHealth then
            hum.Health = hum.MaxHealth
        end
    end)
    hum.StateChanged:Connect(function(_, ns2)
        if mod.Defense.GodMode and ns2 == Enum.HumanoidStateType.Dead then
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            hum.Health = hum.MaxHealth
        end
    end)
end

if LocalPlayer.Character then sgm(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(sgm)

RunService.Stepped:Connect(function()
    local ch = LocalPlayer.Character
    if not ch then return end
    local hum = ch:FindFirstChildOfClass("Humanoid")
    if mod.Player.Noclip then
        for _, pt in ipairs(ch:GetDescendants()) do
            if pt:IsA("BasePart") and pt.CanCollide then
                pt.CanCollide = false
            end
        end
    end
    if mod.Player.AutoStand and hum and hum:GetState() == Enum.HumanoidStateType.Physics then
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
    if mod.Defense.NoFallDamage and hum then
        local st = hum:GetState()
        if st == Enum.HumanoidStateType.FallingDown or st == Enum.HumanoidStateType.Ragdoll then
            hum:ChangeState(Enum.HumanoidStateType.Running)
        end
    end
end)

RunService.RenderStepped:Connect(function()
    local ch = LocalPlayer.Character
    if not ch then return end
    local rt = ch:FindFirstChild("HumanoidRootPart")
    local hum = ch:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = mod.Player.AutoSprint and (mod.Player.WalkSpeed * 1.5) or mod.Player.WalkSpeed
        hum.UseJumpPower = true
        hum.JumpPower = mod.Player.JumpPower
    end
    local currentCam = Workspace.CurrentCamera or Workspace:FindFirstChildOfClass("Camera")
    if currentCam then
        currentCam.FieldOfView = mod.Visual.FOV
    end
    Workspace.Gravity = mod.Player.Gravity
    if mod.Trolls.Spin and rt then
        rt.CFrame = rt.CFrame * CFrame.Angles(0, math.rad(mod.Trolls.SpinSpeed), 0)
    end
    if mod.Trolls.SelectedTarget ~= "" and mod.Trolls.SelectedTarget ~= "Nenhum" then
        local tp = Players:FindFirstChild(mod.Trolls.SelectedTarget)
        if tp and tp.Character then
            local trt = tp.Character:FindFirstChild("HumanoidRootPart")
            local th = tp.Character:FindFirstChild("Head")
            if mod.Trolls.LoopTP and rt and trt then
                rt.CFrame = trt.CFrame * CFrame.new(0, 0, 3)
            elseif mod.Trolls.HeadSit and rt and th then
                rt.CFrame = th.CFrame * CFrame.new(0, 1.5, 0)
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        if not mod.OriginalSizes[p] then
                            mod.OriginalSizes[p] = {Size = hrp.Size, Transparency = hrp.Transparency}
                        end
                        if mod.Hitbox.Enabled and ie(p) then
                            hrp.Size = Vector3.new(mod.Hitbox.Size, mod.Hitbox.Size, mod.Hitbox.Size)
                            hrp.Transparency = mod.Hitbox.Transparency
                            hrp.Color = mod.Hitbox.Color
                            hrp.Material = Enum.Material.Neon
                            hrp.CanCollide = false
                        else
                            if mod.OriginalSizes[p] then
                                hrp.Size = mod.OriginalSizes[p].Size
                                hrp.Transparency = mod.OriginalSizes[p].Transparency
                            end
                        end
                    end
                end
            end
        end)
    end
end)

task.spawn(function()
    while task.wait(1) do
        pcall(function()
            if mod.Defense.AutoHeal then
                local ch = LocalPlayer.Character
                local hum = ch and ch:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health < mod.Defense.HealThreshold then
                    local tl = LocalPlayer.Backpack:FindFirstChild("Medkit") or ch:FindFirstChild("Medkit")
                    if tl then
                        tl.Parent = ch
                        tl:Activate()
                    end
                end
            end
        end)
    end
end)

local function ae(p)
    if p == LocalPlayer then return end
    local function uh()
        pcall(function()
            if not p.Character then return end
            local hl = p.Character:FindFirstChild("ESPHighlighter")
            if mod.ESP.Enabled and mod.ESP.Chams and ie(p) then
                if not hl then
                    hl = Instance.new("Highlight")
                    hl.Name = "ESPHighlighter"
                    hl.Parent = p.Character
                end
                hl.FillColor = Color3.fromRGB(255, 0, 0)
                hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                hl.FillTransparency = 0.5
                hl.OutlineTransparency = 0
                hl.Enabled = true
            elseif hl then
                hl:Destroy()
            end
        end)
    end
    p.CharacterAdded:Connect(function()
        task.wait(0.5)
        uh()
    end)
    uh()
end

for _, p2 in ipairs(Players:GetPlayers()) do ae(p2) end
Players.PlayerAdded:Connect(ae)

local win = Rayfield:CreateWindow({
    Name = "Torcidas 7",
    LoadingTitle = "Carregando Framework Módulo...",
    LoadingSubtitle = "by Assistant",
    ConfigurationSaving = {Enabled = false},
    KeySystem = true,
    KeySettings = {
        Title = "Torcidas 7 | Key System",
        Subtitle = "Validado por Usuário (" .. LocalPlayer.Name .. ")",
        Note = "Pegue sua Key no Discord: https://discord.gg/JS8WDGbubs",
        FileName = "Torcidas7KeyConfig",
        SaveKey = true,
        GrabKeyFromSite = false,
        Key = vk
    }
})

local ct = win:CreateTab("Combate", 4483362458)
ct:CreateToggle({Name = "Expandir Hitbox", CurrentValue = false, Callback = function(v) mod.Hitbox.Enabled = v end})
ct:CreateSlider({Name = "Tamanho do Hitbox", Range = {2, 50}, Increment = 1, CurrentValue = 2, Callback = function(v) mod.Hitbox.Size = v end})
ct:CreateSlider({Name = "Transparência", Range = {0, 1}, Increment = 0.1, CurrentValue = 0.5, Callback = function(v) mod.Hitbox.Transparency = v end})
ct:CreateColorPicker({Name = "Cor do Hitbox", Color = Color3.fromRGB(255, 0, 0), Callback = function(v) mod.Hitbox.Color = v end})

local ptab = win:CreateTab("Player", 4483362458)
ptab:CreateSlider({Name = "Velocidade (WalkSpeed)", Range = {16, 250}, Increment = 1, CurrentValue = 16, Callback = function(v) mod.Player.WalkSpeed = v end})
ptab:CreateSlider({Name = "Pulo (JumpPower)", Range = {50, 300}, Increment = 1, CurrentValue = 50, Callback = function(v) mod.Player.JumpPower = v end})
ptab:CreateToggle({Name = "Pulo Infinito", CurrentValue = false, Callback = function(v) mod.Player.InfJump = v end})
ptab:CreateToggle({Name = "Noclip (Atravesse Paredes)", CurrentValue = false, Callback = function(v) mod.Player.Noclip = v end})
ptab:CreateToggle({Name = "Auto Sprint", CurrentValue = false, Callback = function(v) mod.Player.AutoSprint = v end})
ptab:CreateSlider({Name = "Gravidade", Range = {0, 500}, Increment = 5, CurrentValue = 196, Callback = function(v) mod.Player.Gravity = v end})
ptab:CreateToggle({Name = "God Mode", CurrentValue = false, Callback = function(v)
    mod.Defense.GodMode = v
    nt("Proteção", v and "God Mode Ativado" or "God Mode Desativado", 2)
end})
ptab:CreateToggle({Name = "Sem Dano de Queda", CurrentValue = false, Callback = function(v)
    mod.Defense.NoFallDamage = v
    nt("Proteção", v and "Sem Dano de Queda Ativado" or "Sem Dano de Queda Desativado", 2)
end})

local espt = win:CreateTab("ESP", 4483362458)
espt:CreateToggle({Name = "Ativar ESP Geral", CurrentValue = false, Callback = function(v) mod.ESP.Enabled = v end})
espt:CreateToggle({Name = "Chams (Wallhack)", CurrentValue = false, Callback = function(v)
    mod.ESP.Chams = v
    for _, p2 in ipairs(Players:GetPlayers()) do
        ae(p2)
    end
end})
espt:CreateToggle({Name = "Team Check (Apenas Inimigos)", CurrentValue = false, Callback = function(v) mod.ESP.TeamCheck = v end})

local ttab = win:CreateTab("Trolls", 4483362458)
local tdd = ttab:CreateDropdown({
    Name = "Selecionar Alvo",
    Options = gpn(),
    CurrentOption = {"Nenhum"},
    MultipleOptions = false,
    Callback = function(v)
        local val = type(v) == "table" and v[1] or v
        mod.Trolls.SelectedTarget = (val == "Nenhum") and "" or val
    end
})
ttab:CreateButton({Name = "Atualizar Lista de Jogadores", Callback = function() tdd:Refresh(gpn()) end})
ttab:CreateToggle({Name = "Spin (Girar Personagem)", CurrentValue = false, Callback = function(v) mod.Trolls.Spin = v end})
ttab:CreateSlider({Name = "Velocidade do Spin", Range = {10, 100}, Increment = 5, CurrentValue = 30, Callback = function(v) mod.Trolls.SpinSpeed = v end})
ttab:CreateToggle({Name = "Loop TP no Alvo", CurrentValue = false, Callback = function(v) mod.Trolls.LoopTP = v end})
ttab:CreateToggle({Name = "Sentar na Cabeça do Alvo", CurrentValue = false, Callback = function(v) mod.Trolls.HeadSit = v end})

local dtab = win:CreateTab("Defesa / Teleport", 4483362458)
dtab:CreateToggle({Name = "Auto Cura", CurrentValue = false, Callback = function(v) mod.Defense.AutoHeal = v end})
dtab:CreateSlider({Name = "Limite de Vida para Curar (%)", Range = {10, 90}, Increment = 5, CurrentValue = 50, Callback = function(v) mod.Defense.HealThreshold = v end})
dtab:CreateButton({Name = "Salvar Posição Atual", Callback = function()
    local rt = gr()
    if rt then
        mod.Waypoints.SavedPosition = rt.CFrame
        nt("Waypoint", "Posição salva com sucesso!", 2)
    end
end})
dtab:CreateButton({Name = "Teleportar para Posição Salva", Callback = function()
    local rt = gr()
    if rt and mod.Waypoints.SavedPosition then
        rt.CFrame = mod.Waypoints.SavedPosition
        nt("Waypoint", "Teleportado com sucesso!", 2)
    else
        nt("Erro", "Nenhuma posição salva encontrada.", 2)
    end
end})

local vtab = win:CreateTab("Visuals", 4483362458)
vtab:CreateSlider({Name = "Campo de Visão (FOV)", Range = {30, 120}, Increment = 1, CurrentValue = 70, Callback = function(v) mod.Visual.FOV = v end})

local stab = win:CreateTab("Settings", 4483362458)
stab:CreateToggle({Name = "Notificações", CurrentValue = mod.Player.Notifications, Callback = function(v) mod.Player.Notifications = v end})
stab:CreateButton({Name = "Recarregar Interferências", Callback = function() nt("Settings", "Interferências registradas com sucesso!", 2) end})
stab:CreateButton({Name = "Destruir Menu", Callback = function() Rayfield:Destroy() end})
stab:CreateParagraph({Title = "Informações da Licença", Content = "Usuário: " .. LocalPlayer.Name .. "\nValidade de Key: " .. lex .. "\nVersão do Hub: Torcidas 7"})

nt("Torcidas 7", "Chave autenticada por - " .. LocalPlayer.Name .. "!\nValidade: " .. lex, 5)

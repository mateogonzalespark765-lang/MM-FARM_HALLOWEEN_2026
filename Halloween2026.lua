-- =================================================================
-- SCRIPT: TEXO'S HUB - MM2 UNDERGROUND EVENT FARM
-- Desarrollado para: Farmeo Seguro y Discreto
-- =================================================================

-- // 1. CARGAR LIBRERÍA VISUAL Y SERVICIOS
local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer

-- // 2. CONFIGURACIÓN
local Config = {
    AutoFarm = false,
    MaxCandy = 50,          -- Límite de tu bolsa Élite
    FlySpeed = 22,          -- Velocidad segura de vuelo (anti-kick)
    UndergroundOffset = 7,  -- Studs por debajo del suelo
    Disable3D = false
}

local Stats = {
    SessionCandy = 0
}

-- // 3. ANTI-AFK
LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0, 0), Workspace.CurrentCamera.CFrame)
end)

-- // 4. CREAR VENTANA PRINCIPAL (TEXO'S HUB)
local Window = OrionLib:MakeWindow({
    Name = "Texo's Hub | MM2 Event Farm",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "TexosHubConfig"
})

-- // 5. PESTAÑAS
local TabFarm = Window:MakeTab({
    Name = "Auto Farm",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local TabStats = Window:MakeTab({
    Name = "Estadísticas",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

local TabSettings = Window:MakeTab({
    Name = "Ajustes / Rendimiento",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

-- // 6. CONTROLES EN 'AUTO FARM'
TabFarm:AddToggle({
    Name = "Activar Farm Subterráneo (Texo's)",
    Default = false,
    Callback = function(Value)
        Config.AutoFarm = Value
    end    
})

TabFarm:AddSlider({
    Name = "Límite de Caramelos (Bolsa)",
    Min = 10,
    Max = 50,
    Default = 50,
    Color = Color3.fromRGB(255, 140, 0),
    Increment = 1,
    ValueName = "Caramelos",
    Callback = function(Value)
        Config.MaxCandy = Value
    end    
})

TabFarm:AddSlider({
    Name = "Profundidad bajo el piso",
    Min = 4,
    Max = 12,
    Default = 7,
    Color = Color3.fromRGB(128, 0, 128),
    Increment = 1,
    ValueName = "Studs",
    Callback = function(Value)
        Config.UndergroundOffset = Value
    end    
})

TabFarm:AddSlider({
    Name = "Velocidad de Movimiento",
    Min = 12,
    Max = 32,
    Default = 22,
    Color = Color3.fromRGB(50, 205, 50),
    Increment = 1,
    ValueName = "Speed",
    Callback = function(Value)
        Config.FlySpeed = Value
    end    
})

-- // 7. CONTROLES EN 'ESTADÍSTICAS' Y 'AJUSTES'
local CandyLabel = TabStats:AddLabel("Caramelos en sesión: 0")

TabSettings:AddToggle({
    Name = "Modo Ahorro (Apagar Gráficos 3D)",
    Default = false,
    Callback = function(Value)
        Config.Disable3D = Value
        RunService:Set3dRenderingEnabled(not Value)
    end    
})

TabSettings:AddButton({
    Name = "Cambiar de Servidor (Server Hop)",
    Callback = function()
        OrionLib:MakeNotification({
            Name = "Texo's Hub",
            Content = "Buscando un nuevo servidor público...",
            Time = 3
        })
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
})

-- // 8. FUNCIONES AUXILIARES
local function getCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function getCandyCount()
    local gui = LocalPlayer:FindFirstChild("PlayerGui")
    if gui and gui:FindFirstChild("MainGUI") then
        local coinBag = gui.MainGUI:FindFirstChild("Game", true)
        if coinBag and coinBag:FindFirstChild("CoinBag") then
            local amountText = coinBag.CoinBag:FindFirstChild("Amount")
            if amountText and amountText:IsA("TextLabel") then
                local current = string.match(amountText.Text, "(%d+)/")
                return tonumber(current) or 0
            end
        end
    end
    return 0
end

-- Desplazamiento por debajo del piso
local function moveToTargetUnderground(targetPart)
    local character = getCharacter()
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    -- Posición ajustada por debajo del objeto objetivo
    local targetCFrame = targetPart.CFrame * CFrame.new(0, -Config.UndergroundOffset, 0)
    local distance = (rootPart.Position - targetCFrame.Position).Magnitude
    local travelTime = distance / Config.FlySpeed

    local tweenInfo = TweenInfo.new(
        travelTime,
        Enum.EasingStyle.Linear,
        Enum.EasingDirection.Out
    )

    local tween = TweenService:Create(rootPart, tweenInfo, {CFrame = targetCFrame})
    tween:Play()
    tween.Completed:Wait()
end

-- // 9. BUCLE PRINCIPAL DE TEXO'S HUB
task.spawn(function()
    local lastCandy = 0
    
    while task.wait(0.4) do
        if Config.AutoFarm then
            local currentCandy = getCandyCount()

            -- Actualizar contador de estadísticas
            if currentCandy > lastCandy then
                Stats.SessionCandy = Stats.SessionCandy + (currentCandy - lastCandy)
                CandyLabel:Set("Caramelos en sesión: " .. tostring(Stats.SessionCandy))
            end
            lastCandy = currentCandy

            -- Recolectar si no se ha alcanzado la meta
            if currentCandy < Config.MaxCandy then
                for _, container in ipairs(Workspace:GetChildren()) do
                    if container.Name == "CoinContainer" or container.Name == "CandyContainer" then
                        for _, coin in ipairs(container:GetChildren()) do
                            local coinPart = coin:IsA("BasePart") and coin or coin:FindFirstChild("Coin")
                            
                            if coinPart and Config.AutoFarm then
                                moveToTargetUnderground(coinPart)
                                task.wait(math.random(15, 35) / 100)
                            end

                            if getCandyCount() >= Config.MaxCandy or not Config.AutoFarm then
                                break
                            end
                        end
                    end
                end
            else
                -- Bolsa llena: Moverse a un escondite alto/fuera de mapa
                local character = getCharacter()
                local rootPart = character:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    rootPart.CFrame = CFrame.new(0, 500, 0) -- Plataforma invisible o zona alta segura
                end
                task.wait(2)
            end
        end
    end
end)

-- Inicializar Menú
OrionLib:Init()
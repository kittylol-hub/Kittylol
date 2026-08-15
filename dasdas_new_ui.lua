local G = getgenv()
G.InterfaceName = "Astra Hub"
G.SecureMode = false

-- Install executor hooks only once. Re-installing hookfunction layers on every
-- execution stacks wrappers and can cause severe frame drops when the script
-- is reloaded while the game is already running.
G.AstraHookRuntime = G.AstraHookRuntime or {}
local AstraHooks = G.AstraHookRuntime

pcall(function()
    if not AstraHooks.Installed then
        local lp = cloneref(game:GetService("Players")).LocalPlayer
        local oldKick = lp and lp.Kick

        if lp and oldKick and hookfunction and newcclosure then
            local mtHook
            mtHook = hookfunction(getrenv().setmetatable, newcclosure(function(t, mt)
                if mt and type(mt) == "table" and rawget(mt, "__mode") then
                    local mode = rawget(mt, "__mode")
                    if mode == "kv" or mode == "v" or mode == "k" then
                        local trace = debug.traceback()
                        if trace:find("MiscellaneousController")
                            or trace:find("CameraSecurity")
                            or trace:find("AnalyticsPipelineController") then
                            return mtHook({1,2,3}, {})
                        end
                    end
                end
                return mtHook(t, mt)
            end))

            hookfunction(oldKick, newcclosure(function(self, ...)
                if self == lp then return end
                return oldKick(self, ...)
            end))

            AstraHooks.Installed = true
        end
    end
end)

G.SolunaState = G.SolunaState or {}
G.SolunaRuntime = G.SolunaRuntime or {}
G.SolunaSkinRuntime = G.SolunaSkinRuntime or {}
local Runtime = G.SolunaRuntime


pcall(function()
    if Runtime.RenderConnection then Runtime.RenderConnection:Disconnect() end
    if Runtime.HeartbeatConnection then Runtime.HeartbeatConnection:Disconnect() end
    if Runtime.CleanupConnection then Runtime.CleanupConnection:Disconnect() end
    if Runtime.WalkSpeedConnection then Runtime.WalkSpeedConnection:Disconnect() end
    if Runtime.TargetInfoBlurConnection then Runtime.TargetInfoBlurConnection:Disconnect() end
    if Runtime.ExternalSilentAimConnection then Runtime.ExternalSilentAimConnection:Disconnect() end
    if InfiniteJumpConnection then InfiniteJumpConnection:Disconnect() end
    if FlyConnection then FlyConnection:Disconnect() end
end)

local function GetService(name)
    local success, service = pcall(function()
        return game:GetService(name)
    end)
    if success and service then
        return cloneref and cloneref(service) or service
    end
    return nil
end

local Services = {
    Players = GetService("Players"),
    HttpService = GetService("HttpService"),
    MarketplaceService = GetService("MarketplaceService"),
    RunService = GetService("RunService"),
    UserInputService = GetService("UserInputService"),
    ContentProvider = GetService("ContentProvider"),
    ReplicatedStorage = GetService("ReplicatedStorage"),
    Debris = GetService("Debris"),
    Lighting = GetService("Lighting"),
    SoundService = GetService("SoundService"),
    TweenService = GetService("TweenService"),
    TextService = GetService("TextService"),
    Camera = workspace and workspace.CurrentCamera or nil,
    CoreGui = (gethui and gethui()) or GetService("CoreGui")
}

local Config = {
    GameId = 17625359962,
    InviteCode = "tEmMW68zgW",
    rpcFile = "RPCShown.txt",
}

pcall(function()
    Config.LocalPlayer = Services.Players.LocalPlayer
end)

if not Config.LocalPlayer then
    warn("LocalPlayer not found")
    return
end

pcall(function()
    Config.GameInfo = Services.MarketplaceService:GetProductInfo(17625359962)
end)

Config.GameName = Config.GameInfo and Config.GameInfo.Name or "Rivals"
Config.PlayerName = Config.LocalPlayer.DisplayName
local ChamsTargetContainer = (gethui and gethui()) or Services.CoreGui

local ExecutorName = tostring(identifyexecutor and identifyexecutor() or "")
local ExecutorNameLower = string.lower(ExecutorName)

-- Forward-declared: several features defined above the UI reference these
-- (GetSilentAimTarget reads Options.fov_slider, ApplySilentAimEnabled calls
-- Notify), so they must resolve to the same locals the UI later assigns.
local Notify, NotifyUnsupportedFeature, Options

--==========================================================================
--  ASTRA HUB · BRAND
--  Shared palette + a procedurally drawn "A" monogram, so the logo needs no
--  uploaded asset and stays crisp at any size.
--==========================================================================
local Brand = {
    Ink        = Color3.fromRGB(8, 9, 12),
    Backdrop   = Color3.fromRGB(11, 12, 16),
    Surface    = Color3.fromRGB(17, 19, 25),

local Brand = {
    Ink        = Color3.fromRGB(8, 9, 12),
    Backdrop   = Color3.fromRGB(11, 12, 16),
    Surface    = Color3.fromRGB(17, 19, 25),
    Raised     = Color3.fromRGB(23, 26, 34),
    Hover      = Color3.fromRGB(31, 35, 45),
    Line       = Color3.fromRGB(38, 43, 55),
    LineSoft   = Color3.fromRGB(29, 33, 43),
    Text       = Color3.fromRGB(237, 240, 248),
    Sub        = Color3.fromRGB(150, 158, 178),
    Muted      = Color3.fromRGB(104, 112, 132),
    Accent     = Color3.fromRGB(228, 30, 74),
    AccentHi   = Color3.fromRGB(255, 74, 112),
    AccentDeep = Color3.fromRGB(126, 14, 42),

local State = {
    SolunaState = G.SolunaState or {},
    ESPCache = {},
    HighlightCache = {},
    ViewportChamsCache = {},
    rpcShown = false,
    AntiKatanaEnabled = false,
    AntiKatanaHooked = false,
    OriginalEquippedItemInput = nil,
    SilentAimEnabled = false,
    SilentAimHitchance = 100,
    SilentAimHooked = false,
    WallCheckEnabled = true,
    WallBangEnabled = false,
    Aiming = false,
    LockedTarget = nil,
    SlideSpeed = 1,
    SlideDuration = 1,
    SlideEnabled = false,
    WalkSpeedEnabled = false,
    WalkSpeedValue = 50,
    InfiniteJump = false,
    RequireBlocked = ExecutorNameLower == "xeno" or ExecutorNameLower == "solara",
    IsRunning = true,
    RenderTick = 0,
    LastESPUpdate = 0,
    ESPUpdateInterval = 0.1,
    Initialized = false,
    ShowTargetInfo = false,
    PlayerCache = {},
    PlayerCacheTime = 0,
    ChamsEnabled = false
}

local requireCache = {}
local function RequireModule(moduleScript)
    if not moduleScript then return nil end
    if State.RequireBlocked then return nil end
    
    local path = tostring(moduleScript)
    if requireCache[path] ~= nil then
        return requireCache[path]
    end
    
    local success, result = pcall(function()
        return require(moduleScript)
    end)
    
    if success then
        requireCache[path] = result
        return result
    end
    
    requireCache[path] = false
    return nil
end

local function GetFighterController() return RequireModule(Config.LocalPlayer.PlayerScripts.Controllers.FighterController) end
local function GetMechanicsController() return RequireModule(Config.LocalPlayer.PlayerScripts.Controllers.MechanicsController) end
local function GetItemLibrary() return RequireModule(Services.ReplicatedStorage.Modules.ItemLibrary) end
local function GetUtilityLibrary() return RequireModule(Services.ReplicatedStorage.Modules.Utility) end
local function GetGameplayUtility() return RequireModule(Services.ReplicatedStorage.Modules.GameplayUtility) end
local function GetDuelController() return RequireModule(Config.LocalPlayer.PlayerScripts.Controllers.DuelController) end
local function GetCameraController() return RequireModule(Config.LocalPlayer.PlayerScripts.Controllers.CameraController) end
local function GetCosmeticLibrary() return RequireModule(Services.ReplicatedStorage.Modules.CosmeticLibrary) end
local function GetClientViewModelModule(moduleScript) return RequireModule(moduleScript or Config.LocalPlayer.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem.ClientViewModel) end
local function GetEnumLibrary() return RequireModule(Services.ReplicatedStorage.Modules.EnumLibrary) end
local function GetSoundLibrary() return RequireModule(Services.ReplicatedStorage.Modules.SoundLibrary) end
local function GetTracerEffect() return RequireModule(Config.LocalPlayer.PlayerScripts.Modules.TracerEffect) end
local function GetGunModule() return RequireModule(Config.LocalPlayer.PlayerScripts.Modules.ItemTypes.Gun) end

local ChamsSettings = {
    Enabled = false,
    Color = Color3.fromRGB(50, 150, 255),
    OutlineColor = Color3.fromRGB(0, 0, 0),
    FillTransparency = 0.45,
    OutlineTransparency = 0,
}

local function HandleChamsPlayer(v)
    local function InjectChams(char)
        if not char then return end
        local tag = "hx_" .. v.UserId
        local h = ChamsTargetContainer:FindFirstChild(tag) or Instance.new("Highlight")
        h.Name = tag
        h.Adornee = char
        h.FillColor = ChamsSettings.Color
        h.OutlineColor = ChamsSettings.OutlineColor
        h.FillTransparency = ChamsSettings.FillTransparency
        h.OutlineTransparency = ChamsSettings.OutlineTransparency
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.Parent = ChamsTargetContainer
        h.Enabled = false
    end
    v.CharacterAdded:Connect(InjectChams)
    if v.Character then InjectChams(v.Character) end
end

local function CreateDrawing(type)
    local success, drawing = pcall(function()
        return Drawing.new(type)
    end)
    if success and drawing then
        return drawing
    end
    return nil
end

local ESPSettings = {
    ESPTeamCheck = true,
    MaxESPDistance = 2000,
}

local function GetHealthColor(health, maxHealth)
    local ratio = math.clamp(health / maxHealth, 0, 1)
    if ratio > 0.6 then
        return Color3.fromRGB(0, 255, 0)
    elseif ratio > 0.3 then
        return Color3.fromRGB(255, 255, 0)
    else
        return Color3.fromRGB(255, 0, 0)
    end
end

local function IsTeammate(player)
    if player.Team and Config.LocalPlayer.Team and player.Team == Config.LocalPlayer.Team then return true end
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if hrp and hrp:FindFirstChild("TeammateLabel") then return true end
    return false
end

local DeflectingPlayers = {}

local function IsEnemyDeflecting(player)
    if not State.AntiKatanaEnabled then return false end
    if DeflectingPlayers[player] and tick() < DeflectingPlayers[player] then return true end

    local character = player.Character
    if not character then return false end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end

    local deflectAttachment = rootPart:FindFirstChild("_katana_deflect_active_not_local")
    if deflectAttachment then
        for _, emitter in ipairs(deflectAttachment:GetChildren()) do
            if emitter:IsA("ParticleEmitter") and emitter.Enabled then return true end
        end
    end

    return false
end

local function IsAnyVisibleEnemyDeflecting()
    if not State.AntiKatanaEnabled then return false end
    local localChar = Config.LocalPlayer.Character
    if not localChar then return false end
    local localRoot = localChar:FindFirstChild("HumanoidRootPart")
    if not localRoot then return false end
    local camera = Services.Camera
    
    for _, player in ipairs(Services.Players:GetPlayers()) do
        if player ~= Config.LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
            if humanoid and humanoid.Health > 0 and rootPart then
                if rootPart:FindFirstChild("TeammateLabel") then continue end
                if IsEnemyDeflecting(player) then
                    local screenPos, onScreen = camera:WorldToScreenPoint(rootPart.Position)
                    if onScreen then
                        local rayParams = RaycastParams.new()
                        rayParams.FilterDescendantsInstances = {localChar}
                        rayParams.FilterType = Enum.RaycastFilterType.Exclude
                        local result = workspace:Raycast(localRoot.Position, (rootPart.Position - localRoot.Position).Unit * 500, rayParams)
                        if result and result.Instance and result.Instance:IsDescendantOf(player.Character) then
                            return true
                        end
                    end
                end
            end
        end
    end
    return false
end

local function SetupAntiKatanaHook()
    if State.RequireBlocked or State.AntiKatanaHooked then return end
    
    pcall(function()
        local ItemLibrary = GetItemLibrary()
        if not ItemLibrary then return end
        
        local KatanaItems = {}
        if ItemLibrary.Items then
            for itemName, itemData in pairs(ItemLibrary.Items) do
                if itemData and itemData.DeflectDuration then
                    KatanaItems[itemName] = itemData.DeflectDuration
                end
            end
        end

        local fc = GetFighterController()
        if not fc then return end
        
        State.AntiKatanaHooked = true
    end)
end

local function IsVisible(targetPart, targetPlayer)
    local character = Config.LocalPlayer.Character
    if not character then return false end
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {character, Services.Camera}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    local origin = Services.Camera.CFrame.Position
    local direction = targetPart.Position - origin
    local result = workspace:Raycast(origin, direction, rayParams)
    return result == nil or result.Instance:IsDescendantOf(targetPlayer.Character)
end

local function IsTargetValidAimbot(player)
    if not player or player == Config.LocalPlayer then return false end
    local character = player.Character
    if not character then return false end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    if ESPSettings.ESPTeamCheck and IsTeammate(player) then return false end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if hrp and hrp:FindFirstChild("TeammateLabel") then return false end
    if IsEnemyDeflecting(player) then return false end
    return true
end

local AimbotSettings = { TargetPart = "Head", Smoothing = 5, MaxDistance = 1000 }
local TargetBodyParts = {"Head", "UpperTorso", "LowerTorso", "HumanoidRootPart", "LeftUpperArm", "RightUpperArm", "LeftFoot", "RightFoot"}

local function GetSilentAimTarget()
    local localChar = Config.LocalPlayer.Character
    if not localChar then return nil, nil end
    local mousePos = Services.UserInputService:GetMouseLocation()
    local targetPartName = AimbotSettings.TargetPart or "Head"
    local closestPart = nil
    local closestPlayer = nil
    local minDist = math.huge
    
    for _, player in ipairs(Services.Players:GetPlayers()) do
        if IsTargetValidAimbot(player) then
            local targetPart = player.Character:FindFirstChild(targetPartName) or player.Character:FindFirstChild("Head")
            if targetPart then
                local screenPos, onScreen = Services.Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    if not State.WallBangEnabled and State.WallCheckEnabled and not IsVisible(targetPart, player) then 
                        continue 
                    end
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    local fovVal = Options.fov_slider and Options.fov_slider.Value or 90
                    if dist < fovVal and dist < minDist then
                        minDist = dist
                        closestPart = targetPart
                        closestPlayer = player
                    end
                end
            end
        end
    end
    return closestPart, closestPlayer
end

local function GetValidPlayers()
    local now = tick()
    if now - State.PlayerCacheTime < 0.1 then
        return State.PlayerCache
    end
    State.PlayerCacheTime = now
    local players = Services.Players:GetPlayers()
    State.PlayerCache = players
    return players
end

local SetupSilentAimHook = function()
    if State.RequireBlocked or State.SilentAimHooked then return end
    
    pcall(function()
        local Utility = GetUtilityLibrary()
        if not Utility then return end
        
        local oldRaycast = Utility.Raycast
        Utility.Raycast = function(self, origin, target, distance, whitelist, filterType)
            if not checkcaller() and State.SilentAimEnabled then
                local targetPart, targetPlayer = GetSilentAimTarget()
                if targetPart and math.random(1, 100) <= State.SilentAimHitchance then
                    target = targetPart.Position
                end
            end
            return oldRaycast(self, origin, target, distance, whitelist, filterType)
        end
        
        State.SilentAimHooked = true
    end)
end

local function ApplySilentAimEnabled(Value)
    State.SilentAimEnabled = Value
    if State.RequireBlocked then
        if Value then
            if not Runtime.ExternalSilentAimLoaded then
                task.spawn(function()
                    pcall(function()
                        loadstring(game:HttpGet("https://raw.githubusercontent.com/EndOverdosing/Soluna-API/refs/heads/main/rivals-modern/silent-aim.lua", true))()
                    end)
                    Runtime.ExternalSilentAimLoaded = true
                    if not Runtime.ExternalSilentAimConnection then
                        Runtime.ExternalSilentAimConnection = Services.RunService.Heartbeat:Connect(function()
                            getgenv().SilentAimEnabled = State.SilentAimEnabled
                        end)
                    end
                    getgenv().SilentAimEnabled = true
                    Notify({ Title = "Silent Aim", Content = "Silent Aim Enabled", Duration = 3 })
                end)
            else
                getgenv().SilentAimEnabled = true
                Notify({ Title = "Silent Aim", Content = "Silent Aim Enabled", Duration = 3 })
            end
        else
            getgenv().SilentAimEnabled = false
        end
        return
    end
    if Value then
        SetupSilentAimHook()
        Notify({ Title = "Silent Aim", Content = "Silent Aim Enabled", Duration = 3 })
    end
end

local __a1b2c3 = setmetatable({}, {
    __index = function(__d4e5f6, __g7h8i9)
        local __j0k1l2, __m3n4o5 = pcall(function()
            return game:GetService(__g7h8i9)
        end)
        if __m3n4o5 then
            return cloneref(__m3n4o5)
        end
        return nil
    end
})

local __p6q7r8 = getgenv()
if __p6q7r8.__s9t0u1 then
    __p6q7r8.__s9t0u1:Shutdown()
end

local __v2w3x4 = __a1b2c3.Players
local __y5z6a7 = __a1b2c3.RunService
local __b8c9d0 = __a1b2c3.ReplicatedStorage
local __e1f2g3 = __a1b2c3.Workspace
local __h4i5j6 = __a1b2c3.UserInputService
local __k7l8m9 = __v2w3x4.LocalPlayer
local __n0o1p2 = __e1f2g3.CurrentCamera
local __q3r4s5 = __k7l8m9.PlayerScripts
local __t6u7v8 = require(__q3r4s5.Modules.ItemTypes.Gun)
local __w9x0y1 = require(__b8c9d0.Modules.Utility)

local __z2a3b4 = setmetatable({}, {
    __index = function(_, __c5d6e7)
        local __f8g9h0 = __k7l8m9.Character
        if not __f8g9h0 then return nil end
        if __c5d6e7 == "__root" then
            return __f8g9h0:FindFirstChild("HumanoidRootPart")
        elseif __c5d6e7 == "__head" then
            return __f8g9h0:FindFirstChild("Head")
        end
        return nil
    end
})

__p6q7r8.__s9t0u1 = {}

do
    local __i1j2k3 = __p6q7r8.__s9t0u1

    function __i1j2k3:__init()
        self.__active = false
        self.__target = nil
        self.__desync = false
        self.__conn1 = nil
        self.__conn2 = nil
        self.__task1 = nil
        self.__oldfunc = nil
        self.__setup_done = false
    end

    function __i1j2k3:__setup()
        if self.__setup_done then return end
        self.__setup_done = true
        
        self.__conn1 = __y5z6a7.Heartbeat:Connect(function()
            if not self.__active then return end
            self.__target = self:__find()
        end)

        local __l4m5n6 = __t6u7v8.StartShooting
        self.__oldfunc = __l4m5n6
        __t6u7v8.StartShooting = function(__o7p8q9, ...)
            local __r0s1t2 = {__l4m5n6(__o7p8q9, ...)}
            if not __o7p8q9.ClientFighter or not __o7p8q9.ClientFighter.IsLocalPlayer then
                return unpack(__r0s1t2)
            end

            local __u3v4w5 = __r0s1t2[3]
            if not __u3v4w5 or typeof(__u3v4w5) ~= "table" then
                return unpack(__r0s1t2)
            end

            __r0s1t2[4] = true
            local __x6y7z8 = self.__target

            if not self.__active or not __x6y7z8 or not __x6y7z8.Character then
                return unpack(__r0s1t2)
            end

            if not self.__desync or self.__curr ~= __x6y7z8 then
                self:__desync_start(__x6y7z8)
                task.wait(0.1)
            end

            if self.__task1 then
                task.cancel(self.__task1)
                self.__task1 = nil
            end

            local __a9b0c1 = __x6y7z8.Character:FindFirstChild("Head")
            if not __a9b0c1 then return unpack(__r0s1t2) end

            local __d2e3f4 = __a9b0c1.Position
            local __g5h6i7 = __a9b0c1.CFrame
            local __j8k9l0 = __d2e3f4 - Vector3.new(0, 5, 0)
            local __m1n2o3 = CFrame.lookAt(__j8k9l0, __d2e3f4)
            local __p4q5r6 = __g5h6i7:ToObjectSpace(CFrame.new(__d2e3f4 + Vector3.new(math.random(), math.random(), math.random())))

            __u3v4w5[utf8.char(0)] = __w9x0y1:EncodeCFrame(CFrame.new(__j8k9l0, __d2e3f4) * CFrame.Angles(__m1n2o3:ToOrientation()))
            __u3v4w5[utf8.char(1)] = __w9x0y1:EncodeCFrame(CFrame.new(__d2e3f4) * CFrame.Angles(__m1n2o3:ToOrientation()))
            __u3v4w5[utf8.char(2)] = __a9b0c1
            __u3v4w5[utf8.char(3)] = __w9x0y1:EncodeCFrame(__p4q5r6)

            self.__task1 = task.delay(0.15, function()
                self:__desync_stop()
            end)

            return unpack(__r0s1t2)
        end
    end

    function __i1j2k3:__find()
        local myChar = __k7l8m9.Character
        if not myChar then return nil end
        local myRoot = myChar:FindFirstChild("HumanoidRootPart")
        if not myRoot then return nil end
       
        local closest = nil
        local closestDist = math.huge
        local MAX_DISTANCE = 200

        local gameMode = __b8c9d0:FindFirstChild("GameMode")
        local isFFA = gameMode and gameMode.Value == "FFA"
        
        local myTeamID = __k7l8m9:GetAttribute("TeamID")
        
        local players = __v2w3x4:GetPlayers()
        for i = 1, #players do
            local player = players[i]
            if player == __k7l8m9 then continue end
            
            local char = player.Character
            if not char then continue end

            local root = char:FindFirstChild("HumanoidRootPart")
            local head = char:FindFirstChild("Head")
            local hum = char:FindFirstChildWhichIsA("Humanoid")
            
            if not (root and head and hum and hum.Health > 0) then continue end
            
            local playerTeamID = player:GetAttribute("TeamID")
            
            if not isFFA then
                if myTeamID and playerTeamID and myTeamID == playerTeamID then
                    continue
                end
            end
           
            local dist = (myRoot.Position - root.Position).Magnitude
            
            if dist > MAX_DISTANCE then continue end
            
            if dist < closestDist then
                closestDist = dist
                closest = player
            end
        end
        
        return closest
    end

    function __i1j2k3:__desync_start(__c3d4e5)
        if self.__conn2 then self.__conn2:Disconnect() end
        self.__desync = true
        self.__curr = __c3d4e5

        self.__conn2 = __y5z6a7.Heartbeat:Connect(function()
            if not self.__desync then return end
            local __f6g7h8 = __z2a3b4.__root
            if not __f6g7h8 then return end

            local __i9j0k1 = __c3d4e5.Character and __c3d4e5.Character:FindFirstChild("HumanoidRootPart")
            if not __i9j0k1 then
                self:__desync_stop()
                return
            end

            local __l2m3n4 = __f6g7h8.CFrame
            local __o5p6q7 = __f6g7h8.Velocity
            local __r8s9t0 = __f6g7h8.RotVelocity

            __f6g7h8.CFrame = __i9j0k1.CFrame * CFrame.new(0, -5, 0)

            __y5z6a7:BindToRenderStep("__restore", 101, function()
                __f6g7h8.CFrame = __l2m3n4
                __f6g7h8.Velocity = __o5p6q7
                __f6g7h8.RotVelocity = __r8s9t0
                __y5z6a7:UnbindFromRenderStep("__restore")
            end)
        end)
    end

    function __i1j2k3:__desync_stop()
        self.__desync = false
        self.__curr = nil
        if self.__conn2 then
            self.__conn2:Disconnect()
            self.__conn2 = nil
        end
    end

    function __i1j2k3:Shutdown()
        self.__active = false
        if self.__conn1 then self.__conn1:Disconnect() end
        if self.__conn2 then self.__conn2:Disconnect() end
        if self.__task1 then task.cancel(self.__task1) end
        if self.__oldfunc then
            __t6u7v8.StartShooting = self.__oldfunc
        end
        self.__setup_done = false
    end

    function __i1j2k3:Enable()
        if not self.__setup_done then
            self:__setup()
        end
        self.__active = true
    end

    function __i1j2k3:Disable()
        self.__active = false
    end

    __i1j2k3:__init()
end

--==========================================================================
--  ASTRA UI  ·  self-contained dark interface library
--  Written to be a drop-in replacement for the Fluent API this hub was
--  built against: CreateWindow / AddTab / AddSection / AddToggle /
--  AddSlider / AddDropdown / AddKeybind / AddColorpicker / AddButton /
--  AddLabel / AddParagraph / AddInput / Notify / Dialog / Options,
--  plus a built-in config manager (no external addon fetch).
--==========================================================================


--==========================================================================
-- ASTRA HUB · NEW UI API BRIDGE
-- Legacy hand-built UI removed; feature controls are routed to lua (1).txt.
--==========================================================================
local Library = (function()
--мхуй
local Library do 
    local Workspace = game:GetService("Workspace")
    local UserInputService = game:GetService("UserInputService")
    local Players = game:GetService("Players")
    local HttpService = game:GetService("HttpService")
    local RunService = game:GetService("RunService")
    local CoreGui = cloneref and cloneref(game:GetService("CoreGui")) or game:GetService("CoreGui")
    local TweenService = game:GetService("TweenService")
    local Lighting = game:GetService("Lighting")

    gethui = gethui or function()
        return CoreGui
    end
    

    local LocalPlayer = Players.LocalPlayer
    local Camera = Workspace.CurrentCamera
    local Mouse = LocalPlayer:GetMouse()

    local FromRGB = Color3.fromRGB
    local FromHSV = Color3.fromHSV
    local FromHex = Color3.fromHex

    local RGBSequence = ColorSequence.new
    local RGBSequenceKeypoint = ColorSequenceKeypoint.new
    local NumSequence = NumberSequence.new
    local NumSequenceKeypoint = NumberSequenceKeypoint.new

    local UDim2New = UDim2.new
    local UDimNew = UDim.new
    local UDim2FromOffset = UDim2.fromOffset
    local Vector2New = Vector2.new
    local Vector3New = Vector3.new

    local MathClamp = math.clamp
    local MathFloor = math.floor
    local MathAbs = math.abs
    local MathSin = math.sin

    local TableInsert = table.insert
    local TableFind = table.find
    local TableRemove = table.remove
    local TableConcat = table.concat
    local TableClone = table.clone
    local TableUnpack = table.unpack

    local StringFormat = string.format
    local StringFind = string.find
    local StringGSub = string.gsub
    local StringLower = string.lower
    local StringLen = string.len

    local InstanceNew = Instance.new

    local RectNew = Rect.new

    -- device detection (Mobile / PC / Console) based on provided logic
    local function DetectDevice()
        if game and game.GetService then
            local UserInputService = game:GetService("UserInputService")
            local GuiService = game:GetService("GuiService")

            -- console (ten-foot interface)
            if GuiService:IsTenFootInterface() then
                return "Console"
            end

            -- pure touch, no keyboard => mobile
            if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
                return "Mobile"
            end

            -- touch + keyboard => likely tablet / hybrid, check viewport size
            if UserInputService.TouchEnabled and UserInputService.KeyboardEnabled then
                local camera = workspace.CurrentCamera
                if camera then
                    local viewportSize = camera.ViewportSize
                    if viewportSize.X < 1024 or viewportSize.Y < 768 then
                        return "Mobile"
                    end
                end
            end

            -- keyboard / mouse => PC
            if UserInputService.KeyboardEnabled or UserInputService.MouseEnabled then
                return "PC"
            end

            -- gamepad only => console
            if UserInputService.GamepadEnabled then
                return "Console"
            end

            return "Unknown"
        else
            -- non-Roblox fallback, keep it simple as "PC"
            return "PC"
        end
    end

    local IsMobile = (DetectDevice() == "Mobile")

    Library = {
        Theme =  { },
        ToClean = { },

        MenuKeybind = tostring(Enum.KeyCode.RightAlt), 

        Flags = { },

        Tween = {
            Time = 0.3,
            Style = Enum.EasingStyle.Quad,
            Direction = Enum.EasingDirection.Out
        },

        FadeSpeed = 0.2,



        -- Ignore below
        Pages = { },
        Sections = { },

        Connections = { },
        Threads = { },

        ThemeMap = { },
        ThemeItems = { },

        OpenFrames = { },

        SetFlags = { },

        UnnamedConnections = 0,
        UnnamedFlags = 0,

        Holder = nil,
        NotifHolder = nil,
        UnusedHolder = nil,

        Font = nil
    }

    Library.__index = Library
    Library.Sections.__index = Library.Sections
    Library.Pages.__index = Library.Pages

    local Keys = {
        ["Unknown"]           = "Unknown",
        ["Backspace"]         = "Back",
        ["Tab"]               = "Tab",
        ["Clear"]             = "Clear",
        ["Return"]            = "Return",
        ["Pause"]             = "Pause",
        ["Escape"]            = "Escape",
        ["Space"]             = "Space",
        ["QuotedDouble"]      = '"',
        ["Hash"]              = "#",
        ["Dollar"]            = "$",
        ["Percent"]           = "%",
        ["Ampersand"]         = "&",
        ["Quote"]             = "'",
        ["LeftParenthesis"]   = "(",
        ["RightParenthesis"]  = " )",
        ["Asterisk"]          = "*",
        ["Plus"]              = "+",
        ["Comma"]             = ",",
        ["Minus"]             = "-",
        ["Period"]            = ".",
        ["Slash"]             = "`",
        ["Three"]             = "3",
        ["Seven"]             = "7",
        ["Eight"]             = "8",
        ["Colon"]             = ":",
        ["Semicolon"]         = ";",
        ["LessThan"]          = "<",
        ["GreaterThan"]       = ">",
        ["Question"]          = "?",
        ["Equals"]            = "=",
        ["At"]                = "@",
        ["LeftBracket"]       = "LeftBracket",
        ["RightBracket"]      = "RightBracked",
        ["BackSlash"]         = "BackSlash",
        ["Caret"]             = "^",
        ["Underscore"]        = "_",
        ["Backquote"]         = "`",
        ["LeftCurly"]         = "{",
        ["Pipe"]              = "|",
        ["RightCurly"]        = "}",
        ["Tilde"]             = "~",
        ["Delete"]            = "Delete",
        ["End"]               = "End",
        ["KeypadZero"]        = "Keypad0",
        ["KeypadOne"]         = "Keypad1",
        ["KeypadTwo"]         = "Keypad2",
        ["KeypadThree"]       = "Keypad3",
        ["KeypadFour"]        = "Keypad4",
        ["KeypadFive"]        = "Keypad5",
        ["KeypadSix"]         = "Keypad6",
        ["KeypadSeven"]       = "Keypad7",
        ["KeypadEight"]       = "Keypad8",
        ["KeypadNine"]        = "Keypad9",
        ["KeypadPeriod"]      = "KeypadP",
        ["KeypadDivide"]      = "KeypadD",
        ["KeypadMultiply"]    = "KeypadM",
        ["KeypadMinus"]       = "KeypadM",
        ["KeypadPlus"]        = "KeypadP",
        ["KeypadEnter"]       = "KeypadE",
        ["KeypadEquals"]      = "KeypadE",
        ["Insert"]            = "Insert",
        ["Home"]              = "Home",
        ["PageUp"]            = "PageUp",
        ["PageDown"]          = "PageDown",
        ["RightShift"]        = "RightShift",
        ["LeftShift"]         = "LeftShift",
        ["RightControl"]      = "RightControl",
        ["LeftControl"]       = "LeftControl",
        ["LeftAlt"]           = "LeftAlt",
        ["RightAlt"]          = "RightAlt"
    }

    local Themes = {
        ["Preset"] = {
            ["AccentGradient"] = FromRGB(0, 195, 255),   -- Slightly deeper blue accent
            ["Background 2"] = FromRGB(10, 10, 12),      -- Very dark gray
            ["Background"] = FromRGB(12, 12, 14),        -- Main near-black background
            ["Text"] = FromRGB(235, 235, 235),           -- Slightly dimmed light text
            ["Outline"] = FromRGB(25, 25, 28),           -- Subtle outline, almost invisible
            ["Section Top"] = FromRGB(28, 27, 31),       -- Dark section header
            ["Section Background"] = FromRGB(10, 10, 12),-- Deep black section background
            ["Section Background 2"] = FromRGB(14, 14, 16),-- Alternate section, minimal difference
            ["Accent"] = FromRGB(0, 116, 224),           -- Darker blue accent for consistency
            ["Element"] = FromRGB(16, 16, 18)            -- Deep gray for UI elements
        }
    }

    Library.Theme = TableClone(Themes["Preset"])



    -- Tweening
    local Tween = { } do
        Tween.__index = Tween

        Tween.Create = function(self, Item, Info, Goal, IsRawItem)
            if not Item then return nil end
            Item = IsRawItem and Item or (type(Item) == "table" and Item.Instance) or Item
            if not Item or not Item.Parent then return nil end
            Info = Info or TweenInfo.new(Library.Tween.Time, Library.Tween.Style, Library.Tween.Direction)

            local NewTween = {
                Tween = TweenService:Create(Item, Info, Goal),
                Info = Info,
                Goal = Goal,
                Item = Item
            }

            NewTween.Tween:Play()

            setmetatable(NewTween, Tween)

            return NewTween
        end

        Tween.GetProperty = function(self, Item)
            Item = Item or self.Item 

            if Item:IsA("Frame") then
                return { "BackgroundTransparency" }
            elseif Item:IsA("TextLabel") or Item:IsA("TextButton") then
                return { "TextTransparency", "BackgroundTransparency" }
            elseif Item:IsA("ImageLabel") or Item:IsA("ImageButton") then
                return { "BackgroundTransparency", "ImageTransparency" }
            elseif Item:IsA("ScrollingFrame") then
                return { "BackgroundTransparency", "ScrollBarImageTransparency" }
            elseif Item:IsA("TextBox") then
                return { "TextTransparency", "BackgroundTransparency" }
            elseif Item:IsA("UIStroke") then 
                return { "Transparency" }
            end
        end

        Tween.FadeItem = function(self, Item, Property, Visibility, Speed)
            local Item = Item or self.Item 

            local OldTransparency = Item[Property]
            Item[Property] = Visibility and 1 or OldTransparency

            local NewTween = Tween:Create(Item, TweenInfo.new(Speed or Library.Tween.Time, Library.Tween.Style, Library.Tween.Direction), {
                [Property] = Visibility and OldTransparency or 1
            }, true)

            Library:Connect(NewTween.Tween.Completed, function()
                if not Visibility then 
                    task.wait()
                    Item[Property] = OldTransparency
                end
            end)

            return NewTween
        end

        Tween.Get = function(self)
            if not self.Tween then 
                return
            end

            return self.Tween, self.Info, self.Goal
        end

        Tween.Pause = function(self)
            if not self.Tween then 
                return
            end

            self.Tween:Pause()
        end

        Tween.Play = function(self)
            if not self.Tween then 
                return
            end

            self.Tween:Play()
        end

        Tween.Clean = function(self)
            if not self.Tween then 
                return
            end

            Tween:Pause()
            self = nil
        end
    end

    -- Instances
    local Instances = { } do
        Instances.__index = Instances

        Instances.Create = function(self, Class, Properties)
            local NewItem = {
                Instance = InstanceNew(Class),
                Properties = Properties,
                Class = Class
            }

            setmetatable(NewItem, Instances)

            for Property, Value in NewItem.Properties do
                NewItem.Instance[Property] = Value
            end

            return NewItem
        end

        Instances.FadeItem = function(self, Visibility, Speed)
            local Item = self.Instance

            if Visibility == true then 
                Item.Visible = true
            end

            local Descendants = Item:GetDescendants()
            TableInsert(Descendants, Item)

            local NewTween

            for Index, Value in Descendants do 
                local TransparencyProperty = Tween:GetProperty(Value)

                if not TransparencyProperty then 
                    continue
                end

                if type(TransparencyProperty) == "table" then 
                    for _, Property in TransparencyProperty do 
                        NewTween = Tween:FadeItem(Value, Property, not Visibility, Speed)
                    end
                else
                    NewTween = Tween:FadeItem(Value, TransparencyProperty, not Visibility, Speed)
                end
            end
        end

        Instances.AddToTheme = function(self, Properties)
            if not self.Instance then 
                return
            end

            Library:AddToTheme(self, Properties)
        end

        Instances.ChangeItemTheme = function(self, Properties)
            if not self.Instance then 
                return
            end

            Library:ChangeItemTheme(self, Properties)
        end

        Instances.Connect = function(self, Event, Callback, Name)
            if not self.Instance then 
                return
            end

            if not self.Instance[Event] then 
                return
            end

            if IsMobile then
                if Event == "MouseButton1Down" or Event == "MouseButton1Click" then 
                    Event = "TouchTap"
                elseif Event == "MouseButton2Down" or Event == "MouseButton2Click" then 
                    Event = "TouchLongPress"
                end
            end

            return Library:Connect(self.Instance[Event], Callback, Name)
        end

        Instances.Tween = function(self, Info, Goal)
            if not self.Instance then 
                return
            end

            return Tween:Create(self, Info, Goal)
        end

        Instances.Disconnect = function(self, Name)
            if not self.Instance then 
                return
            end

            return Library:Disconnect(Name)
        end

        Instances.Clean = function(self)
            if not self.Instance then 
                return
            end

            self.Instance:Destroy()
            self = nil
        end

        Instances.MakeDraggable = function(self)
            if not self.Instance then 
                return
            end
        
            local Gui = self.Instance
            local Dragging = false 
            local DragStart
            local StartPosition 
        
            local Set = function(Input)
                local DragDelta = Input.Position - DragStart
                local NewX = StartPosition.X.Offset + DragDelta.X
                local NewY = StartPosition.Y.Offset + DragDelta.Y
                self:Tween(TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Position = UDim2New(StartPosition.X.Scale, NewX, StartPosition.Y.Scale, NewY)
                })
            end
        
            local InputChanged
        
            self:Connect("InputBegan", function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    Dragging = true
                    DragStart = Input.Position
                    StartPosition = Gui.Position
        
                    if InputChanged then 
                        return
                    end
        
                    InputChanged = Input.Changed:Connect(function()
                        if Input.UserInputState == Enum.UserInputState.End then
                            Dragging = false
                            if InputChanged then
                                InputChanged:Disconnect()
                                InputChanged = nil
                            end
                        end
                    end)
                end
            end)
        
            Library:Connect(UserInputService.InputChanged, function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
                    if Dragging then
                        Set(Input)
                    end
                end
            end)
        
            return Dragging
        end

        Instances.MakeResizeable = function(self, Minimum, Maximum, Window)
            if not self.Instance then 
                return
            end

            local Gui = self.Instance

            local Resizing = false 
            local CurrentSide = nil

            local StartMouse = nil 
            local StartPosition = nil 
            local StartSize = nil
            
            local EdgeThickness = 2

            local MakeEdge = function(Name, Position, Size)
                local Button = Instances:Create("TextButton", {
                    Name = "\0",
                    Size = Size,
                    Position = Position,
                    BackgroundColor3 = FromRGB(166, 147, 243),
                    BackgroundTransparency = 1,
                    Text = "",
                    BorderSizePixel = 0,
                    AutoButtonColor = false,
                    Parent = Gui,
                    ZIndex = 99999,
                })  Button:AddToTheme({BackgroundColor3 = "Accent"})

                return Button
            end

            local Edges = {
                {Button = MakeEdge(
                    "Left", 
                    UDim2New(0, 0, 0, 0), 
                    UDim2New(0, EdgeThickness, 1, 0)), 
                    Side = "L"
                },

                {Button = MakeEdge(
                    "Right", 
                    UDim2New(1, -EdgeThickness, 0, 0), 
                    UDim2New(0, EdgeThickness, 1, 0)), 
                    Side = "R"
                },

                {Button = MakeEdge(
                    "Top", UDim2New(0, 0, 0, 0), 
                    UDim2New(1, 0, 0, EdgeThickness)), 
                    Side = "T"
                },

                {Button = MakeEdge(
                    "Bottom", 
                    UDim2New(0, 0, 1, -EdgeThickness), 
                    UDim2New(1, 0, 0, EdgeThickness)), 
                    Side = "B"
                },
            }

            local BeginResizing = function(Side)
                Resizing = true 
                CurrentSide = Side 

                StartMouse = UserInputService:GetMouseLocation()

                -- store offsets, not absolute screen pos
                StartPosition = Vector2New(Gui.Position.X.Offset, Gui.Position.Y.Offset)
                StartSize = Vector2New(Gui.Size.X.Offset, Gui.Size.Y.Offset)
                
                for Index, Value in Edges do 
                    Value.Button:Tween(nil, {BackgroundTransparency = (Value.Side == Side) and 0 or 1})
                end
            end

            local EndResizing = function()
                Resizing = false 
                CurrentSide = nil

                for Index, Value in Edges do 
                    Value.Button.Instance.BackgroundTransparency = 1
                end
            end

            for Index, Value in Edges do 
                Value.Button:Connect("InputBegan", function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        BeginResizing(Value.Side)
                    end
                end)
            end

            Library:Connect(UserInputService.InputEnded, function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    if Resizing then
                        EndResizing()
                    end
                end
            end)

            Library:Connect(RunService.RenderStepped, function()
                if not Resizing or not CurrentSide then 
                    return 
                end

                local MouseLocation = UserInputService:GetMouseLocation()
                local dx = MouseLocation.X - StartMouse.X
                local dy = MouseLocation.Y - StartMouse.Y
            
                local x, y = StartPosition.X, StartPosition.Y
                local w, h = StartSize.X, StartSize.Y

                if CurrentSide == "L" then
                    x = StartPosition.X + dx
                    w = StartSize.X - dx

                    if Window then
                        Window.Left.Y = h
                    end
                elseif CurrentSide == "R" then
                    w = StartSize.X + dx

                    if Window then
                        Window.Right.Y = h
                    end
                elseif CurrentSide == "T" then
                    y = StartPosition.Y + dy
                    h = StartSize.Y - dy

                    if Window then
                        Window.Top.X = w
                    end
                elseif CurrentSide == "B" then
                    h = StartSize.Y + dy

                    if Window then
                        Window.Bottom.X = w
                    end
                end
            
                if w < Minimum.X then
                    if CurrentSide == "L" then
                        x = x - (Minimum.X - w)
                    end
                    w = Minimum.X
                end
                if h < Minimum.Y then
                    if CurrentSide == "T" then
                        y = y - (Minimum.Y - h)
                    end
                    h = Minimum.Y
                end
            
                self:Tween(TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2FromOffset(x, y)})
                self:Tween(TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2FromOffset(w, h)})
            end)
        end

        Instances.OnHover = function(self, Function)
            if not self.Instance then 
                return
            end
            
            return Library:Connect(self.Instance.MouseEnter, Function)
        end

        Instances.OnHoverLeave = function(self, Function)
            if not self.Instance then 
                return
            end
            
            return Library:Connect(self.Instance.MouseLeave, Function)
        end
    end

    -- Custom font
    local CustomFont = { } do
        function CustomFont:New(Name, Weight, Style, Data)
            if not isfile(Data.Id) then 
                writefile(Data.Id, game:HttpGet(Data.Url))
            end

            local Data = {
                name = Name,
                faces = {
                    {
                        name = Name,
                        weight = Weight,
                        style = Style,
                        assetId = getcustomasset(Data.Id)
                    }
                }
            }

            writefile(`{Library.Folders.Assets}/{Name}.font`, HttpService:JSONEncode(Data))
            return getcustomasset(`{Library.Folders.Assets}/{Name}.font`)
        end

        local SemiBold = Font.new("rbxassetid://12187365364", Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)

        local Regular = Font.new("rbxassetid://12187365364", Enum.FontWeight.Regular, Enum.FontStyle.Normal)

        local Light = Font.new("rbxassetid://12187365364", Enum.FontWeight.Light, Enum.FontStyle.Normal)

        Library.Fonts = {
            ["SemiBold"] = SemiBold,
            ["Regular"] = Regular,
            ["Light"] = Light
        }

        Library.Font = SemiBold
    end

    Library.Holder = Instances:Create("ScreenGui", {
        Parent = gethui(),
        Name = "\0",
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        DisplayOrder = 2,
        ResetOnSpawn = false
    })

    Library.UnusedHolder = Instances:Create("ScreenGui", {
        Parent = gethui(),
        Name = "\0",
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        Enabled = false,
        ResetOnSpawn = false
    })

    Library.NotifHolder  = Instances:Create("Frame", {
        Parent = Library.Holder.Instance,
        Name = "\0",
        BackgroundTransparency = 1,
        Size = UDim2New(0, 0, 1, 0),
        Position = UDim2New(1, 0, 0, 0),
        AnchorPoint = Vector2New(1, 0),
        BorderColor3 = FromRGB(0, 0, 0),
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = FromRGB(255, 255, 255)
    })
    
    Instances:Create("UIListLayout", {
        Parent = Library.NotifHolder.Instance,
        Name = "\0",
        Padding = UDimNew(0, 12),
        SortOrder = Enum.SortOrder.LayoutOrder
    })
    
    Instances:Create("UIPadding", {
        Parent = Library.NotifHolder.Instance,
        Name = "\0",
        PaddingTop = UDimNew(0, 12),
        PaddingBottom = UDimNew(0, 12),
        PaddingRight = UDimNew(0, 12),
        PaddingLeft = UDimNew(0, 12)
    })    

    Library.Unload = function(self)
        for Index, Value in self.Connections do 
            pcall(function() Value.Connection:Disconnect() end)
        end

        for Index, Value in self.Threads do 
            pcall(function() coroutine.close(Value) end)
        end

        if self.Holder then 
            pcall(function() self.Holder:Clean() end)
        end

        if self.UnusedHolder then 
            pcall(function() self.UnusedHolder:Clean() end)
        end

        if self.WatermarkFrame then
            pcall(function() 
                self.WatermarkFrame.Instance:Destroy()
                self.WatermarkFrame = nil
            end)
        end

        for _, Object in pairs(self.ToClean) do
            pcall(function()
                if Object and Object.Parent then
                    Object:Destroy()
                end
            end)
        end

        Library = nil 
        getgenv().Library = nil
    end

    Library.GetImage = function(self, Image)
        local ImageData = self.Images[Image]

        if not ImageData then 
            return
        end

        return getcustomasset(self.Folders.Assets .. "/" .. ImageData[1])
    end

    Library.Round = function(self, Number, Float)
        local Multiplier = 1 / (Float or 1)
        return MathFloor(Number * Multiplier) / Multiplier
    end

    Library.Thread = function(self, Function)
        local NewThread = coroutine.create(Function)
        
        coroutine.wrap(function()
            coroutine.resume(NewThread)
        end)()

        TableInsert(self.Threads, NewThread)
        return NewThread
    end
    
    Library.SafeCall = function(self, Function, ...)
        local Arguements = { ... }
        local Success, Result = pcall(Function, TableUnpack(Arguements))

        if not Success then
            warn(Result)
            return false
        end

        return Success
    end

    Library.Connect = function(self, Event, Callback, Name)
        Name = Name or StringFormat("connection_number_%s_%s", self.UnnamedConnections + 1, HttpService:GenerateGUID(false))

        local NewConnection = {
            Event = Event,
            Callback = Callback,
            Name = Name,
            Connection = nil
        }

        Library:Thread(function()
            NewConnection.Connection = Event:Connect(Callback)
        end)

        TableInsert(self.Connections, NewConnection)
        return NewConnection
    end

    Library.Disconnect = function(self, Name)
        for _, Connection in self.Connections do 
            if Connection.Name == Name then
                Connection.Connection:Disconnect()
                break
            end
        end
    end

    Library.NextFlag = function(self)
        local FlagNumber = self.UnnamedFlags + 1
        return StringFormat("flag_number_%s_%s", FlagNumber, HttpService:GenerateGUID(false))
    end

    Library.AddToTheme = function(self, Item, Properties)
        Item = Item.Instance or Item 

        local ThemeData = {
            Item = Item,
            Properties = Properties,
        }

        for Property, Value in ThemeData.Properties do
            if type(Value) == "string" then
                Item[Property] = self.Theme[Value]
            else
                Item[Property] = Value()
            end
        end

        TableInsert(self.ThemeItems, ThemeData)
        self.ThemeMap[Item] = ThemeData
    end

    Library.ToRich = function(self, Text, Color)
        return `<font color="rgb({MathFloor(Color.R * 255)}, {MathFloor(Color.G * 255)}, {MathFloor(Color.B * 255)})">{Text}</font>`
    end

    Library.GetConfig = function(self)
        local Config = { } 

        local Success, Result = Library:SafeCall(function()
            for Index, Value in pairs(Library.Flags) do 
                if type(Value) == "table" and Value.Key ~= nil then
                    Config[Index] = {Key = tostring(Value.Key), Mode = Value.Mode or Value.ModeSelected or "Toggle"}
                elseif type(Value) == "table" and (Value.Color or Value.HexValue) then
                    local Hex = Value.HexValue or (Value.Color and typeof(Value.Color) == "Color3" and Value.Color:ToHex())
                    Config[Index] = {Color = "#" .. (Hex or "FFFFFF"), Alpha = Value.Alpha}
                else
                    Config[Index] = Value
                end
            end
        end)

        return HttpService:JSONEncode(Config)
    end

    Library.LoadConfig = function(self, Config)
        local Decoded = HttpService:JSONDecode(Config)

        local Success, Result = Library:SafeCall(function()
            for Index, Value in pairs(Decoded) do 
                local SetFunction = Library.SetFlags[Index]

                if not SetFunction then
                    continue
                end

                if type(Value) == "table" and Value.Key ~= nil then
                    SetFunction(Value)
                elseif type(Value) == "table" and Value.Color then
                    SetFunction(Value.Color, Value.Alpha)
                elseif Value ~= nil then
                    SetFunction(Value)
                end
            end
        end)

        return Success, Result
    end

    Library.DeleteConfig = function(self, Config)
        if isfile(Library.Folders.Configs .. "/" .. Config) then 
            delfile(Library.Folders.Configs .. "/" .. Config)
        end
    end

    Library.RefreshConfigsList = function(self, Element)
        if not Element or not Element.Refresh then 
            return 
        end

        local List = { }

        if isfolder(Library.Folders.Configs) then
            for Index, FilePath in listfiles(Library.Folders.Configs) do
                local FileName = FilePath:match("[^/^\\]+$")
                -- only show real config files (must end with .json)
                if FileName and FileName:sub(-5):lower() == ".json" then
                    TableInsert(List, FileName)
                end
            end
        end

        Element:Refresh(List)
    end

    Library.ChangeItemTheme = function(self, Item, Properties)
        Item = Item.Instance or Item

        if not self.ThemeMap[Item] then 
            return
        end

        self.ThemeMap[Item].Properties = Properties
        self.ThemeMap[Item] = self.ThemeMap[Item]
    end

    Library.ChangeTheme = function(self, Theme, Color)
        self.Theme[Theme] = Color

        for _, Item in self.ThemeItems do
            for Property, Value in Item.Properties do
                if type(Value) == "string" and Value == Theme then
                    Item.Item[Property] = Color
                elseif type(Value) == "function" then
                    Item.Item[Property] = Value()
                end
            end
        end
    end

    Library.IsMouseOverFrame = function(self, Frame)
        if not Frame then return false end
        Frame = Frame.Instance or Frame
        if not Frame or not Frame.Parent then return false end

        local MousePosition = Vector2New(Mouse.X, Mouse.Y)

        return MousePosition.X >= Frame.AbsolutePosition.X and MousePosition.X <= Frame.AbsolutePosition.X + Frame.AbsoluteSize.X 
        and MousePosition.Y >= Frame.AbsolutePosition.Y and MousePosition.Y <= Frame.AbsolutePosition.Y + Frame.AbsoluteSize.Y
    end

    Library.Lerp = function(self, Start, Finish, Time)
        return Start + (Finish - Start) * Time
    end

    Library.CompareVectors = function(self, PointA, PointB)
        return (PointA.X < PointB.X) or (PointA.Y < PointB.Y)
    end

    Library.IsClipped = function(self, Object, Column)
        local Parent = Column
        
        local BoundryTop = Parent.AbsolutePosition
        local BoundryBottom = BoundryTop + Parent.AbsoluteSize

        local Top = Object.AbsolutePosition
        local Bottom = Top + Object.AbsoluteSize 

        return Library:CompareVectors(Top, BoundryTop) or Library:CompareVectors(BoundryBottom, Bottom)
    end

    Library.GetCalculatedRayPosition = function(self, Position, Normal, Origin, Direction)
        local N = Normal
        local D = Direction
        local V = Origin - Position

        local Number = (N.x * V.x) + (N.y * V.y) + (N.z * V.z)
        local Den = (N.x * D.x) + (N.y * D.y) + (N.z * D.z)
        local A = -Number / Den

        return Origin + (A * Direction)
    end

    Library.UpdateText = function(self)
        for Index, Value in self.UnusedHolder.Instance:GetDescendants() do 
            if Value:IsA("TextLabel") or Value:IsA("TextButton") or Value:IsA("TextBox") then
                Value.FontFace = Library.Font
            end
        end

        for Index, Value in self.Holder.Instance:GetDescendants() do 
            if Value:IsA("TextLabel") or Value:IsA("TextButton") or Value:IsA("TextBox") then
                Value.FontFace = Library.Font
            end
        end
    end

    Library.MakeBlurred = function(self, Item, Window)
        Item = Item.Instance
        local BlurItem = Item

        local Part = Instances:Create("Part", {
            Material = Enum.Material.Glass,
            Transparency = 1,
            Reflectance = 1,
            CastShadow = false,
            Anchored = true,
            CanCollide = false,
            CanQuery = false,
            CollisionGroup = " ",
            Size = Vector3New(1, 1, 1) * 0.01,
            Color = FromRGB(0,0,0),
            Parent = Camera
        })
        -- Добавляем в список на удаление
        table.insert(self.ToClean, Part.Instance)
            
        local BlockMesh = Instances:Create("BlockMesh", {Parent = Part.Instance})

        local DepthOfField = Instances:Create("DepthOfFieldEffect", {
            Parent = Lighting,
            Enabled = true,
            FarIntensity = 0,
            FocusDistance = 0,
            InFocusRadius = 1000,
            NearIntensity = 1,
            Name = ""
        })
        -- Добавляем в список на удаление
        table.insert(self.ToClean, DepthOfField.Instance)

        Library:Connect(RunService.RenderStepped, function()
            if Window.IsOpen then
                if Item.Visible then
                    DepthOfField:Tween(nil, {NearIntensity = 1})

                    Part:Tween(nil, {Transparency = 0.97})
                    Part:Tween(nil, {Size = Vector3New(1, 1, 1) * 0.01})

                    local Corner0 = BlurItem.AbsolutePosition;
                    local Corner1 = Corner0 + BlurItem.AbsoluteSize;
                        
                    local Ray0 = Camera.ScreenPointToRay(Camera, Corner0.X, Corner0.Y, 1);
                    local Ray1 = Camera.ScreenPointToRay(Camera, Corner1.X, Corner1.Y, 1);

                    local Origin = Camera.CFrame.Position + Camera.CFrame.LookVector * (0.05 - Camera.NearPlaneZ);

                    local Normal = Camera.CFrame.LookVector;

                    local Position0 = Library:GetCalculatedRayPosition(Origin, Normal, Ray0.Origin, Ray0.Direction)
                    local Position1 = Library:GetCalculatedRayPosition(Origin, Normal, Ray1.Origin, Ray1.Direction)

                    Position0 = Camera.CFrame:PointToObjectSpace(Position0)
                    Position1 = Camera.CFrame:PointToObjectSpace(Position1)

                    local Size = Position1 - Position0
                    local Center = (Position0 + Position1) / 2

                    BlockMesh.Instance.Offset = Center
                    BlockMesh.Instance.Scale  = Size / 0.0101

                    Part.Instance.CFrame = Camera.CFrame
                else
                    DepthOfField:Tween(nil, {NearIntensity = 0})
                    BlockMesh.Instance.Offset = Vector3New(0, 0, 0)
                    BlockMesh.Instance.Scale  = Vector3New(0, 0, 0)
                end
            else
                DepthOfField:Tween(nil, {NearIntensity = 0})
                BlockMesh.Instance.Offset = Vector3New(0, 0, 0)
                BlockMesh.Instance.Scale  = Vector3New(0, 0, 0)
            end
        end)
    end

    Library.EscapePattern = function(self, String)
        local ShouldEscape = false 

        if string.match(String, "[%(%)%.%%%+%-%*%?%[%]%^%$]") then
            ShouldEscape = true
        end

        if ShouldEscape then
            return StringGSub(String, "[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%1")
        end

        return String
    end

    do 
        Library.CreateColorpicker = function(self, Data)
            local Colorpicker = {
                Flag = Data.Flag,

                Hue = 0,
                Saturation = 0,
                Value = 0,

                Alpha = 0,

                Color = FromRGB(0, 0, 0),
                HexValue = "#000000",

                SavedColors = { },

                IsOpen = false 
            }

            local Items = { } do
                local IsCompact = Data.Compact == true
                local BtnSize = IsCompact and UDim2New(0, 14, 0, 14) or UDim2New(0, 100, 0, 20)
                Items["ColorpickerButton"] = Instances:Create("TextButton", {
                    Parent = Data.Parent.Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    AnchorPoint = Vector2New(0, 0.5),
                    Position = IsCompact and UDim2New(0, 0, 0.5, 0) or UDim2New(0, 0, 0, 0),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = BtnSize,
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                if Data.LayoutOrder then Items["ColorpickerButton"].Instance.LayoutOrder = Data.LayoutOrder end
                if Data.Parent2 and not Data.Parent2.Instance:FindFirstChild("nig") then
                    Items["PaletteIcon"] = Instances:Create("ImageLabel", {
                        Parent = Data.Parent2.Instance,
                        ImageColor3 = FromRGB(141, 141, 150),
                        BorderColor3 = FromRGB(0, 0, 0),
                        Size = UDim2New(0, 16, 0, 16),
                        AnchorPoint = Vector2New(0.5, 1),
                        Image = "rbxassetid://92464809279921",
                        Name = "nig",
                        BackgroundTransparency = 1,
                        Position = UDim2New(1, -16, 1, -6),
                        ZIndex = 2,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })                

                    Items["PaletteIcon"]:OnHover(function()
                        Items["PaletteIcon"]:Tween(nil, {ImageColor3 = Library.Theme.Accent})
                    end)
                    
                    Items["PaletteIcon"]:OnHoverLeave(function()
                        Items["PaletteIcon"]:Tween(nil, {ImageColor3 = FromRGB(141, 141, 150)})
                    end)
                end
                
                Items["Color"] = Instances:Create("Frame", {
                    Parent = Items["ColorpickerButton"].Instance,
                    Name = "\0",
                    Size = IsCompact and UDim2New(1, 0, 1, 0) or UDim2New(0, 15, 0, 15),
                    Position = IsCompact and UDim2New(0, 0, 0, 0) or UDim2New(0, 0, 0, 2),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(124, 163, 255)
                })
                
                Instances:Create("UICorner", {
                    Parent = Items["Color"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(1, 0)
                })
                
                Items["Text"] = Instances:Create("TextLabel", {
                    Parent = Items["ColorpickerButton"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "#7842ff",
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(0, 0, 0, 15),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 25, 0, 2),
                    BorderSizePixel = 0,
                    Visible = not IsCompact,
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Text"]:AddToTheme({TextColor3 = "Text"})

                Items["ColorpickerWindow"] = Instances:Create("TextButton", {
                    Parent = Library.UnusedHolder.Instance,
                    AutoButtonColor = false,
                    Text = "",
                    Name = "\0",
                    Visible = false,
                    Position = UDim2New(0.01075268816202879, 0, 0.0336427167057991, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 235, 0, 270),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 25)
                })  Items["ColorpickerWindow"]:AddToTheme({BackgroundColor3 = "Background"})
                
                Instances:Create("UICorner", {
                    Parent = Items["ColorpickerWindow"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 6)
                })
                
                Items["Palette"] = Instances:Create("TextButton", {
                    Parent = Items["ColorpickerWindow"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    Position = UDim2New(0, 15, 0, 10),
                    Size = UDim2New(1, -31, 1, -159),
                    BorderSizePixel = 0,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(124, 163, 255)
                })
                
                Items["Saturation"] = Instances:Create("Frame", {
                    Parent = Items["Palette"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 1, 1, 0),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Instances:Create("UIGradient", {
                    Parent = Items["Saturation"].Instance,
                    Name = "\0",
                    Transparency = NumSequence{NumSequenceKeypoint(0, 1), NumSequenceKeypoint(1, 0)}
                })
                
                Instances:Create("UICorner", {
                    Parent = Items["Saturation"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })
                
                Items["Value"] = Instances:Create("Frame", {
                    Parent = Items["Palette"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 1, 1, 1),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(0, 0, 0)
                })
                
                Instances:Create("UIGradient", {
                    Parent = Items["Value"].Instance,
                    Name = "\0",
                    Rotation = 90,
                    Transparency = NumSequence{NumSequenceKeypoint(0, 1), NumSequenceKeypoint(1, 0)}
                })
                
                Instances:Create("UICorner", {
                    Parent = Items["Value"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })
                
                Instances:Create("UICorner", {
                    Parent = Items["Palette"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })
                
                Items["PaletteDragger"] = Instances:Create("Frame", {
                    Parent = Items["Palette"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 15, 0, 15),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 10, 0, 10),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Instances:Create("UIStroke", {
                    Parent = Items["PaletteDragger"].Instance,
                    Name = "\0",
                    Color = FromRGB(255, 255, 255),
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                })
                
                Instances:Create("UICorner", {
                    Parent = Items["PaletteDragger"].Instance,
                    Name = "\0"
                })
                
                Items["Hue"] = Instances:Create("TextButton", {
                    Parent = Items["ColorpickerWindow"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    AnchorPoint = Vector2New(0, 1),
                    Position = UDim2New(0, 15, 1, -131),
                    Size = UDim2New(1, -31, 0, 6),
                    BorderSizePixel = 0,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Instances:Create("UICorner", {
                    Parent = Items["Hue"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(1, 0)
                })
                
                Items["HueInline"] = Instances:Create("TextButton", {
                    Parent = Items["Hue"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    Size = UDim2New(1, 0, 1, 0),
                    BorderSizePixel = 0,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Instances:Create("UICorner", {
                    Parent = Items["HueInline"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(1, 0)
                })
                
                Instances:Create("UIGradient", {
                    Parent = Items["HueInline"].Instance,
                    Name = "\0",
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 0, 0)), RGBSequenceKeypoint(0.17, FromRGB(255, 255, 0)), RGBSequenceKeypoint(0.33, FromRGB(0, 255, 0)), RGBSequenceKeypoint(0.5, FromRGB(0, 255, 255)), RGBSequenceKeypoint(0.67, FromRGB(0, 0, 255)), RGBSequenceKeypoint(0.83, FromRGB(255, 0, 255)), RGBSequenceKeypoint(1, FromRGB(255, 0, 0))}
                })
                
                Items["HueDragger"] = Instances:Create("Frame", {
                    Parent = Items["HueInline"].Instance,
                    Name = "\0",
                    AnchorPoint = Vector2New(0, 0.5),
                    Position = UDim2New(0, 15, 0.5, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 12, 0, 12),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Instances:Create("UICorner", {
                    Parent = Items["HueDragger"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(1, 0)
                })
                
                Items["Alpha"] = Instances:Create("TextButton", {
                    Parent = Items["ColorpickerWindow"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    AnchorPoint = Vector2New(0, 1),
                    Position = UDim2New(0, 15, 1, -107),
                    Size = UDim2New(1, -31, 0, 6),
                    BorderSizePixel = 0,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(124, 163, 255)
                })
                
                Instances:Create("UICorner", {
                    Parent = Items["Alpha"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(1, 0)
                })
                
                Instances:Create("UIGradient", {
                    Parent = Items["Alpha"].Instance,
                    Name = "\0",
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(0, 0, 0)), RGBSequenceKeypoint(1, FromRGB(255, 255, 255))}
                })
                
                Items["AlphaDragger"] = Instances:Create("Frame", {
                    Parent = Items["Alpha"].Instance,
                    Name = "\0",
                    AnchorPoint = Vector2New(0, 0.5),
                    Position = UDim2New(0, 15, 0.5, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 12, 0, 12),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Instances:Create("UICorner", {
                    Parent = Items["AlphaDragger"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(1, 0)
                })
                
                Items["SavedColors"] = Instances:Create("ScrollingFrame", {
                    Parent = Items["ColorpickerWindow"].Instance,
                    Name = "\0",
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    AnchorPoint = Vector2New(0, 1),
                    BorderSizePixel = 0,
                    CanvasSize = UDim2New(0, 0, 0, 0),
                    ScrollBarImageColor3 = FromRGB(124, 163, 255),
                    MidImage = "rbxassetid://86870199131153",
                    BorderColor3 = FromRGB(0, 0, 0),
                    ScrollBarThickness = 0,
                    Size = UDim2New(1, -20, 0, 69),
                    Selectable = false,
                    TopImage = "rbxassetid://86870199131153",
                    Position = UDim2New(0, 10, 1, -30),
                    BottomImage = "rbxassetid://86870199131153",
                    BackgroundTransparency = 1,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                }) 
                
                Instances:Create("UIGridLayout", {
                    Parent = Items["SavedColors"].Instance,
                    Name = "\0",
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    CellPadding = UDim2New(0, 10, 0, 10),
                    CellSize = UDim2New(0, 25, 0, 25)
                })

                Instances:Create("UIPadding", {
                    Parent = Items["SavedColors"].Instance,
                    Name = "\0",
                    PaddingLeft = UDimNew(0, 5),
                    PaddingTop = UDimNew(0, 5),
                    PaddingRight = UDimNew(0, -125),
                    PaddingBottom = UDimNew(0, 5)
                })

                Items["HEXInput"] = Instances:Create("TextBox", {
                    Parent = Items["ColorpickerWindow"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ClearTextOnFocus = false,
                    Text = "#7ca3ff",
                    AnchorPoint = Vector2New(1, 1),
                    Size = UDim2New(0, 140, 0, 20),
                    TextTransparency = 0.5,
                    PlaceholderColor3 = FromRGB(185, 185, 185),
                    Position = UDim2New(1, -8, 1, -8),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BorderSizePixel = 0,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(30, 29, 31)
                })  Items["HEXInput"]:AddToTheme({BackgroundColor3 = "Outline"})

                Instances:Create("UIPadding", {
                    Parent = Items["HEXInput"].Instance,
                    Name = "\0",
                    PaddingLeft = UDimNew(0, 5),
                })
                
                Items["HexLabel"] = Instances:Create("TextLabel", {
                    Parent = Items["ColorpickerWindow"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "Custom:",
                    TextTransparency = 0.5,
                    AnchorPoint = Vector2New(0, 1),
                    Size = UDim2New(0, 40, 0, 20),
                    Position = UDim2New(0, 10, 1, -8),
                    BorderSizePixel = 0,
                    TextSize = 14,
                    BackgroundTransparency = 1,
                    BackgroundColor3 = FromRGB(30, 29, 31)
                })  Items["HexLabel"]:AddToTheme({TextColor3 = "Text"})
                
                Instances:Create("UICorner", {
                    Parent = Items["HEXInput"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })                
            end

            function Colorpicker:Get()
                return Colorpicker.Color, Colorpicker.Alpha
            end

            function Colorpicker:Update(IsFromAlpha)
                local Hue, Saturation, Value = Colorpicker.Hue, Colorpicker.Saturation, Colorpicker.Value
                Colorpicker.Color = FromHSV(Hue, Saturation, Value)
                Colorpicker.HexValue = Colorpicker.Color:ToHex()

                Library.Flags[Colorpicker.Flag] = {
                    Alpha = Colorpicker.Alpha,
                    Color = Colorpicker.Color,
                    HexValue = Colorpicker.HexValue,
                    Transparency = 1 - Colorpicker.Alpha
                }

                Items["Color"]:Tween(nil, {BackgroundColor3 = Colorpicker.Color})
                Items["Palette"]:Tween(nil, {BackgroundColor3 = FromHSV(Hue, 1, 1)})
                Items["Text"].Instance.Text = ("#"..Colorpicker.HexValue):upper()
                Items["HEXInput"].Instance.Text = "#"..Colorpicker.HexValue

                if not IsFromAlpha then 
                    Items["Alpha"]:Tween(nil, {BackgroundColor3 = Colorpicker.Color})
                end

                if Data.Callback then 
                    Library:SafeCall(Data.Callback, Colorpicker.Color, Colorpicker.Alpha)
                end
            end

            local SlidingPalette = false
            local PaletteChanged
            
            function Colorpicker:SlidePalette(Input)
                if not Input or not SlidingPalette then
                    return
                end

                local ValueX = MathClamp(1 - (Input.Position.X - Items["Palette"].Instance.AbsolutePosition.X) / Items["Palette"].Instance.AbsoluteSize.X, 0, 1)
                local ValueY = MathClamp(1 - (Input.Position.Y - Items["Palette"].Instance.AbsolutePosition.Y) / Items["Palette"].Instance.AbsoluteSize.Y, 0, 1)

                Colorpicker.Saturation = ValueX
                Colorpicker.Value = ValueY

                local SlideX = MathClamp((Input.Position.X - Items["Palette"].Instance.AbsolutePosition.X) / Items["Palette"].Instance.AbsoluteSize.X, 0, 0.955)
                local SlideY = MathClamp((Input.Position.Y - Items["Palette"].Instance.AbsolutePosition.Y) / Items["Palette"].Instance.AbsoluteSize.Y, 0, 0.955)

                Items["PaletteDragger"]:Tween(TweenInfo.new(Library.Tween.Time, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(SlideX, 0, SlideY, 0)})
                Colorpicker:Update()
            end
            
            local SlidingHue = false
            local HueChanged

            function Colorpicker:SlideHue(Input)
                if not Input or not SlidingHue then
                    return
                end
                
                local ValueX = MathClamp((Input.Position.X - Items["Hue"].Instance.AbsolutePosition.X) / Items["Hue"].Instance.AbsoluteSize.X, 0, 1)

                Colorpicker.Hue = ValueX

                local SlideX = MathClamp((Input.Position.X - Items["Hue"].Instance.AbsolutePosition.X) / Items["Hue"].Instance.AbsoluteSize.X, 0, 0.955)

                Items["HueDragger"]:Tween(TweenInfo.new(Library.Tween.Time, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(SlideX, 0, 0.5, 0)})
                Colorpicker:Update()
            end

            local SlidingAlpha = false 
            local AlphaChanged

            function Colorpicker:SlideAlpha(Input)
                if not Input or not SlidingAlpha then
                    return
                end

                local ValueX = MathClamp((Input.Position.X - Items["Alpha"].Instance.AbsolutePosition.X) / Items["Alpha"].Instance.AbsoluteSize.X, 0, 1)

                Colorpicker.Alpha = ValueX

                local SlideX = MathClamp((Input.Position.X - Items["Alpha"].Instance.AbsolutePosition.X) / Items["Alpha"].Instance.AbsoluteSize.X, 0, 0.955)

                Items["AlphaDragger"]:Tween(TweenInfo.new(Library.Tween.Time, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(SlideX, 0, 0.5, 0)})
                Colorpicker:Update(true)
            end

            local Debounce = false
            local RenderStepped  

            function Colorpicker:SetOpen(Bool)
                if Debounce then 
                    return
                end

                Colorpicker.IsOpen = Bool

                Debounce = true 

                if Colorpicker.IsOpen then 
                    Items["ColorpickerWindow"].Instance.Visible = true
                    Items["ColorpickerWindow"].Instance.Parent = Library.Holder.Instance
                    
                    RenderStepped = RunService.RenderStepped:Connect(function()
                        Items["ColorpickerWindow"].Instance.Position = UDim2New(
                            0, 
                            Items["ColorpickerButton"].Instance.AbsolutePosition.X, 
                            0, 
                            Items["ColorpickerButton"].Instance.AbsolutePosition.Y + Items["ColorpickerButton"].Instance.AbsoluteSize.Y + 5
                        )
                    end)

                    if Data.Section.IsSettings ~= true then
                        for Index, Value in Library.OpenFrames do 
                            if Value ~= Colorpicker then
                                Value:SetOpen(false)
                            end
                        end
                    end

                    Library.OpenFrames[Colorpicker] = Colorpicker 
                else
                    if not Data.Section.IsSettings then
                        if Library.OpenFrames[Colorpicker] then 
                            Library.OpenFrames[Colorpicker] = nil
                        end
                    end

                    if RenderStepped then 
                        RenderStepped:Disconnect()
                        RenderStepped = nil
                    end
                end

                local Descendants = Items["ColorpickerWindow"].Instance:GetDescendants()
                TableInsert(Descendants, Items["ColorpickerWindow"].Instance)

                local NewTween

                for Index, Value in Descendants do 
                    local TransparencyProperty = Tween:GetProperty(Value)

                    if not TransparencyProperty then
                        continue 
                    end

                    if not Value.ClassName:find("UI") then 
                        Value.ZIndex = (Colorpicker.IsOpen and Data.Section.IsSettings and 9) or (Colorpicker.IsOpen and not Data.Section.IsSettings and 3) or 1
                    end

                    if type(TransparencyProperty) == "table" then 
                        for _, Property in TransparencyProperty do 
                            NewTween = Tween:FadeItem(Value, Property, Bool, Library.FadeSpeed)
                        end
                    else
                        NewTween = Tween:FadeItem(Value, TransparencyProperty, Bool, Library.FadeSpeed)
                    end
                end
                
                NewTween.Tween.Completed:Connect(function()
                    Debounce = false 
                    Items["ColorpickerWindow"].Instance.Visible = Colorpicker.IsOpen
                    task.wait(0.2)
                    Items["ColorpickerWindow"].Instance.Parent = not Colorpicker.IsOpen and Library.UnusedHolder.Instance or Library.Holder.Instance
                end)
            end

            function Colorpicker:Set(Color, Alpha)
                if type(Color) == "table" then
                    Color = FromRGB(Color[1], Color[2], Color[3])
                    Alpha = Color[4]
                elseif type(Color) == "string" then
                    Color = FromHex(Color)
                end 

                Colorpicker.Hue, Colorpicker.Saturation, Colorpicker.Value = Color:ToHSV()
                Colorpicker.Alpha = Alpha or 0  

                local PaletteValueX = MathClamp(1 - Colorpicker.Saturation, 0, 0.955)
                local PaletteValueY = MathClamp(1 - Colorpicker.Value, 0, 0.955)

                local AlphaPositionX = MathClamp(Colorpicker.Alpha, 0, 0.955)
                    
                local HuePositionX = MathClamp(Colorpicker.Hue, 0, 0.955)

                Items["PaletteDragger"]:Tween(TweenInfo.new(Library.Tween.Time, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(PaletteValueX, 0, PaletteValueY, 0)})
                Items["HueDragger"]:Tween(TweenInfo.new(Library.Tween.Time, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(HuePositionX, 0, 0.5, 0)})
                Items["AlphaDragger"]:Tween(TweenInfo.new(Library.Tween.Time, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(AlphaPositionX, 0, 0.5, 0)})
                Colorpicker:Update()
            end

            Items["ColorpickerButton"]:Connect("MouseButton1Down", function()
                Colorpicker:SetOpen(not Colorpicker.IsOpen)
            end)

            Items["Palette"]:Connect("InputBegan", function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    SlidingPalette = true 

                    Colorpicker:SlidePalette(Input)

                    if PaletteChanged then
                        return
                    end

                    PaletteChanged = Input.Changed:Connect(function()
                        if Input.UserInputState == Enum.UserInputState.End then
                            SlidingPalette = false

                            PaletteChanged:Disconnect()
                            PaletteChanged = nil
                        end
                    end)
                end
            end)

            Items["HueInline"]:Connect("InputBegan", function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    SlidingHue = true 

                    Colorpicker:SlideHue(Input)

                    if HueChanged then
                        return
                    end

                    HueChanged = Input.Changed:Connect(function()
                        if Input.UserInputState == Enum.UserInputState.End then
                            SlidingHue = false

                            HueChanged:Disconnect()
                            HueChanged = nil
                        end
                    end)
                end
            end)

            Items["Alpha"]:Connect("InputBegan", function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    SlidingAlpha = true 

                    Colorpicker:SlideAlpha(Input)

                    if AlphaChanged then
                        return
                    end

                    AlphaChanged = Input.Changed:Connect(function()
                        if Input.UserInputState == Enum.UserInputState.End then
                            SlidingAlpha = false

                            AlphaChanged:Disconnect()
                            AlphaChanged = nil
                        end
                    end)
                end
            end)

            function AddColor(Color)
                --if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    local SaveIndex = #Colorpicker.SavedColors + 1

                    local SavedColor = Instances:Create("TextButton", {
                        Parent = Items["SavedColors"].Instance,
                        Name = "\0",
                        FontFace = Library.Font,
                        TextColor3 = FromRGB(0, 0, 0),
                        BorderColor3 = FromRGB(0, 0, 0),
                        Text = "",
                        AutoButtonColor = false,
                        Size = UDim2New(0, 200, 0, 50),
                        BorderSizePixel = 0,
                        TextSize = 14,
                        BackgroundTransparency = 1,
                        ZIndex = 4,
                        BackgroundColor3 = Color
                    })
                    
                    Instances:Create("UICorner", {
                        Parent = SavedColor.Instance,
                        Name = "\0",
                        CornerRadius = UDimNew(0, 6),
                    })                

                    local UIStroke = Instances:Create("UIStroke", {
                        Parent = SavedColor.Instance,
                        Name = "\0",
                        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                        Color = FromRGB(255, 255, 255),
                        Thickness = 1.5,
                        Transparency = 1
                    })

                    SavedColor:OnHover(function()
                        UIStroke:Tween(nil, {Transparency = 0})
                    end)

                    SavedColor:OnHoverLeave(function()
                        UIStroke:Tween(nil, {Transparency = 1})
                    end)
    
                    Colorpicker.SavedColors[SaveIndex] = {
                        Color = Color,
                        Alpha = Colorpicker.Alpha,
                    }
    
                    SavedColor:Connect("MouseButton1Down", function()
                        local NewColorData = Colorpicker.SavedColors[SaveIndex]
                        Colorpicker:Set(NewColorData.Color, NewColorData.Alpha)
                    end)

                    SavedColor:Tween(nil, {BackgroundTransparency = 0})
                --end
            end

            local Colors = {
                ["Orange"] = FromRGB(245, 114, 66),
                ["Pink"] = FromRGB(245, 66, 191),
                ["Purple"] = FromRGB(124, 54, 245),
                ["Pink 2"] = FromRGB(202, 110, 255),
                ["Pink 3"] = FromRGB(250, 142, 239),
                ["Yellow"] = FromRGB(214, 206, 92),
                ["Orange 2"] = FromRGB(255, 93, 48),
                ["Orange 3"] = FromRGB(255, 169, 56),   
                ["Green"] = FromRGB(0, 171, 0),
                ["Blue"] = FromRGB(0, 116, 224),
                ["Maroon"] = FromRGB(120, 0, 76),
                ["Whiteish Pink"] = FromRGB(255, 194, 245),         
                ["White"] = FromRGB(255, 255, 255),
                ["Red"] = FromRGB(255, 0, 0),
                ["Sky Blue"] = FromRGB(171, 209, 255),
            }

            AddColor(Colors["Orange"])
            AddColor(Colors["Pink"])
            AddColor(Colors["Purple"])
            AddColor(Colors["Pink 2"])
            AddColor(Colors["Pink 3"])
            AddColor(Colors["Yellow"])
            AddColor(Colors["Orange 2"])
            AddColor(Colors["Orange 3"])
            AddColor(Colors["Green"])
            AddColor(Colors["Blue"])
            AddColor(Colors["Maroon"])
            AddColor(Colors["Whiteish Pink"]) -- had to do it in order
            AddColor(Colors["White"])
            AddColor(Colors["Red"])
            AddColor(Colors["Sky Blue"])

            Items["HEXInput"]:Connect("FocusLost", function()
                Colorpicker:Set(tostring(Items["HEXInput"].Instance.Text), Colorpicker.Alpha)
            end)

            Library:Connect(UserInputService.InputChanged, function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
                    if SlidingPalette then 
                        Colorpicker:SlidePalette(Input)
                    end

                    if SlidingHue then
                        Colorpicker:SlideHue(Input)
                    end

                    if SlidingAlpha then
                        Colorpicker:SlideAlpha(Input)
                    end
                end
            end)

            Library:Connect(UserInputService.InputBegan, function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    if not Colorpicker.IsOpen then
                        return
                    end

                    if Library:IsMouseOverFrame(Items["ColorpickerWindow"]) or (Items["PaletteIcon"] and Library:IsMouseOverFrame(Items["PaletteIcon"]) and not Data.Section.IsSettings) then
                        return
                    end

                    Colorpicker:SetOpen(false)
                end
            end)

            if Data.Default then
                Colorpicker:Set(Data.Default, Data.Alpha)
            end

            Library.SetFlags[Colorpicker.Flag] = function(Value, Alpha)
                Colorpicker:Set(Value, Alpha)
            end

            return Colorpicker, Items 
        end

        Library.CreateKeybind = function(self, Data)
            local Keybind = {
                Flag = Data.Flag or Library:NextFlag(),
                Default = Data.Default or Enum.KeyCode.E,
                Callback = Data.Callback or function() end,
                Mode = Data.Mode or "Toggle",
                Value = "",
                ModeSelected = "Toggle",
                Toggled = false,
                Picking = false
            }
            local Items = { }
            Items["KeyButton"] = Instances:Create("TextButton", {
                Parent = Data.Parent.Instance,
                Name = "\0",
                FontFace = Library.Font,
                TextColor3 = FromRGB(240, 240, 240),
                TextTransparency = 0.30000001192092896,
                Text = "None",
                AutoButtonColor = false,
                BorderColor3 = FromRGB(0, 0, 0),
                Size = UDim2New(0, 80, 0, 20),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ZIndex = 2,
                TextSize = 14,
                BackgroundColor3 = FromRGB(255, 255, 255)
            })  Items["KeyButton"]:AddToTheme({TextColor3 = "Text"})
            Items["Modes"] = Instances:Create("Frame", {
                Parent = Data.Parent.Instance,
                Name = "\0",
                BorderColor3 = FromRGB(0, 0, 0),
                Size = UDim2New(0, 200, 0, 25),
                ZIndex = 2,
                BorderSizePixel = 0,
                BackgroundColor3 = FromRGB(27, 26, 29)
            })  Items["Modes"]:AddToTheme({BackgroundColor3 = "Element"})
            Instances:Create("UICorner", { Parent = Items["Modes"].Instance, Name = "\0", CornerRadius = UDimNew(0, 5) })
            Items["Background"] = Instances:Create("Frame", {
                Parent = Items["Modes"].Instance,
                Name = "\0",
                Size = UDim2New(0.35, 0, 1, 0),
                BorderColor3 = FromRGB(0, 0, 0),
                ZIndex = 2,
                BorderSizePixel = 0,
                BackgroundTransparency = 0,
                BackgroundColor3 = FromRGB(255, 255, 255)
            })
            Instances:Create("UICorner", { Parent = Items["Background"].Instance, Name = "\0", CornerRadius = UDimNew(0, 5) })
            Instances:Create("UIGradient", {
                Parent = Items["Background"].Instance,
                Name = "\0",
                Rotation = -115,
                Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(166, 166, 166))}
            }):AddToTheme({Color = function()
                return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
            end})
            Items["Toggle"] = Instances:Create("TextButton", {
                Parent = Items["Modes"].Instance,
                Name = "\0",
                FontFace = Library.Font,
                TextColor3 = FromRGB(0, 0, 0),
                TextTransparency = 0.30000001192092896,
                Text = "Toggle",
                AutoButtonColor = false,
                BorderColor3 = FromRGB(0, 0, 0),
                Size = UDim2New(0.35, 0, 1, 0),
                BackgroundTransparency = 1,
                Position = UDim2New(0, 0, 0, -1),
                BorderSizePixel = 0,
                ZIndex = 2,
                TextSize = 14,
                BackgroundColor3 = FromRGB(255, 255, 255)
            })  Items["Toggle"]:AddToTheme({TextColor3 = function() return Library.Theme.Text end})
            Items["Hold"] = Instances:Create("TextButton", {
                Parent = Items["Modes"].Instance,
                Name = "\0",
                FontFace = Library.Font,
                TextColor3 = FromRGB(240, 240, 240),
                TextTransparency = 0.20000000298023224,
                Text = "Hold",
                BorderColor3 = FromRGB(0, 0, 0),
                AutoButtonColor = false,
                AnchorPoint = Vector2New(0, 0),
                Size = UDim2New(0.35, 0, 1, 0),
                BackgroundTransparency = 1,
                Position = UDim2New(0.35, 0, 0, -1),
                BorderSizePixel = 0,
                ZIndex = 2,
                TextSize = 14,
                BackgroundColor3 = FromRGB(255, 255, 255)
            })  Items["Hold"]:AddToTheme({TextColor3 = function() return Library.Theme.Text end})
            Items["Always"] = Instances:Create("TextButton", {
                Parent = Items["Modes"].Instance,
                Name = "\0",
                FontFace = Library.Font,
                TextColor3 = FromRGB(240, 240, 240),
                TextTransparency = 0.20000000298023224,
                Text = "Always",
                BorderColor3 = FromRGB(0, 0, 0),
                AutoButtonColor = false,
                AnchorPoint = Vector2New(0, 0),
                Size = UDim2New(0.4, 0, 1, 0),
                BackgroundTransparency = 1,
                Position = UDim2New(0.7, -12, 0, -1),
                BorderSizePixel = 0,
                ZIndex = 2,
                TextSize = 14,
                BackgroundColor3 = FromRGB(255, 255, 255)
            })  Items["Always"]:AddToTheme({TextColor3 = function() return Library.Theme.Text end})
            local KeyListItem
            if Library.KeyList then KeyListItem = Library.KeyList:Add("", "") end
            local Update = function()
                if KeyListItem then KeyListItem:Set("", Keybind.Value) KeyListItem:SetStatus(Keybind.Toggled) end
            end
            function Keybind:SetMode(Mode)
                if Mode == "Toggle" then
                    Items["Background"]:Tween(TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0, 0), Size = UDim2New(0.35, 0, 1, 0)})
                    Items["Toggle"]:ChangeItemTheme({TextColor3 = function() return FromRGB(0, 0, 0) end})
                    Items["Toggle"]:Tween(nil, {TextColor3 = FromRGB(0, 0, 0)})
                    Items["Hold"]:ChangeItemTheme({TextColor3 = function() return Library.Theme.Text end})
                    Items["Hold"]:Tween(nil, {TextColor3 = Library.Theme.Text})
                    Items["Always"]:ChangeItemTheme({TextColor3 = function() return Library.Theme.Text end})
                    Items["Always"]:Tween(nil, {TextColor3 = Library.Theme.Text})
                elseif Mode == "Hold" then
                    Items["Background"]:Tween(TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(0.35, 0, 0, 0), Size = UDim2New(0.35, 0, 1, 0)})
                    Items["Toggle"]:ChangeItemTheme({TextColor3 = function() return Library.Theme.Text end})
                    Items["Toggle"]:Tween(nil, {TextColor3 = Library.Theme.Text})
                    Items["Hold"]:ChangeItemTheme({TextColor3 = function() return FromRGB(0, 0, 0) end})
                    Items["Hold"]:Tween(nil, {TextColor3 = FromRGB(0, 0, 0)})
                    Items["Always"]:ChangeItemTheme({TextColor3 = function() return Library.Theme.Text end})
                    Items["Always"]:Tween(nil, {TextColor3 = Library.Theme.Text})
                elseif Mode == "Always" then
                    Items["Background"]:Tween(TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(0.7, 0, 0, 0), Size = UDim2New(0.3, 0, 1, 0)})
                    Items["Toggle"]:ChangeItemTheme({TextColor3 = function() return Library.Theme.Text end})
                    Items["Toggle"]:Tween(nil, {TextColor3 = Library.Theme.Text})
                    Items["Hold"]:ChangeItemTheme({TextColor3 = function() return Library.Theme.Text end})
                    Items["Hold"]:Tween(nil, {TextColor3 = Library.Theme.Text})
                    Items["Always"]:ChangeItemTheme({TextColor3 = function() return FromRGB(0, 0, 0) end})
                    Items["Always"]:Tween(nil, {TextColor3 = FromRGB(0, 0, 0)})
                end
                Keybind.ModeSelected = Mode
                Library.Flags[Keybind.Flag] = { Mode = Keybind.ModeSelected, Key = Keybind.Key, Toggled = Keybind.Toggled }
                if Data.Callback then Library:SafeCall(Data.Callback, Keybind.Toggled) end
            end
            function Keybind:Press(Bool)
                if Keybind.ModeSelected == "Toggle" then Keybind.Toggled = not Keybind.Toggled
                elseif Keybind.ModeSelected == "Hold" then Keybind.Toggled = Bool
                elseif Keybind.ModeSelected == "Always" then Keybind.Toggled = true end
                Library.Flags[Keybind.Flag] = { Mode = Keybind.ModeSelected, Key = Keybind.Key, Toggled = Keybind.Toggled }
                if Data.Callback then Library:SafeCall(Data.Callback, Keybind.Toggled) end
                Update()
            end
            function Keybind:Set(Key)
                if StringFind(tostring(Key), "Enum") then
                    Keybind.Key = tostring(Key)
                    local KeyName
                    if type(Key) == "string" then
                        KeyName = Key:match("[^%.]+$") or "None"
                        if KeyName == "Backspace" then KeyName = "None" end
                    else
                        KeyName = Key.Name == "Backspace" and "None" or Key.Name
                    end
                    local KeyStr = Keys[Keybind.Key] or StringGSub(StringGSub(KeyName or "", "KeyCode%.", ""), "UserInputType%.", "") or KeyName or "None"
                    Keybind.Value = KeyStr
                    Items["KeyButton"].Instance.Text = KeyStr
                    Library.Flags[Keybind.Flag] = { Mode = Keybind.ModeSelected, Key = Keybind.Key, Toggled = Keybind.Toggled }
                    if Data.Callback then Library:SafeCall(Data.Callback, Keybind.Toggled) end
                    Update()
                elseif type(Key) == "table" and Key.Key ~= nil then
                    Keybind.Key = tostring(Key.Key)
                    local KeyName
                    if type(Key.Key) == "string" then
                        KeyName = Key.Key:match("[^%.]+$") or "None"
                        if KeyName == "Backspace" then KeyName = "None" end
                    else
                        KeyName = Key.Key.Name == "Backspace" and "None" or Key.Key.Name
                    end
                    local KeyStr = Keys[Keybind.Key] or StringGSub(StringGSub(KeyName or "", "KeyCode%.", ""), "UserInputType%.", "") or KeyName or "None"
                    Keybind.Value = KeyStr
                    Items["KeyButton"].Instance.Text = KeyStr
                    if Key.Mode or Key.ModeSelected then Keybind:SetMode(Key.Mode or Key.ModeSelected) end
                    Library.Flags[Keybind.Flag] = { Mode = Keybind.ModeSelected, Key = Keybind.Key, Toggled = Keybind.Toggled }
                    if Data.Callback then Library:SafeCall(Data.Callback, Keybind.Toggled) end
                    Update()
                elseif TableFind({"Toggle", "Hold", "Always"}, Key) then
                    Keybind:SetMode(Key)
                end
                Keybind.Picking = false
            end
            Items["KeyButton"]:Connect("MouseButton1Click", function()
                Keybind.Picking = true
                Items["KeyButton"].Instance.Text = "."
                local InputBegan
                InputBegan = UserInputService.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.Keyboard then Keybind:Set(Input.KeyCode)
                    else Keybind:Set(Input.UserInputType) end
                    if InputBegan then InputBegan:Disconnect() InputBegan = nil end
                end)
            end)
            Items["Toggle"]:Connect("MouseButton1Down", function() Keybind:SetMode("Toggle") end)
            Items["Hold"]:Connect("MouseButton1Down", function() Keybind:SetMode("Hold") end)
            Items["Always"]:Connect("MouseButton1Down", function() Keybind:SetMode("Always") end)
            Library:Connect(UserInputService.InputBegan, function(Input)
                if Keybind.Value == "None" or Keybind.Picking then return end
                if tostring(Input.KeyCode) == Keybind.Key or tostring(Input.UserInputType) == Keybind.Key then
                    if Keybind.ModeSelected == "Toggle" then Keybind:Press()
                    elseif Keybind.ModeSelected == "Hold" then Keybind:Press(true)
                    elseif Keybind.ModeSelected == "Always" then Keybind:Press(true) end
                end
            end)
            Library:Connect(UserInputService.InputEnded, function(Input)
                if Keybind.Value == "None" then return end
                if tostring(Input.KeyCode) == Keybind.Key or tostring(Input.UserInputType) == Keybind.Key then
                    if Keybind.ModeSelected == "Hold" then Keybind:Press(false)
                    elseif Keybind.ModeSelected == "Always" then Keybind:Press(true) end
                end
            end)
            if Keybind.Default then Keybind:Set({ Mode = Data.Mode or "Toggle", Key = Keybind.Default }) end
            Library.SetFlags[Keybind.Flag] = function(Value) Keybind:Set(Value) end
            return Keybind, Items
        end

        Library.KeybindList = function(self, Title)
            local KeybindList = { }
            Library.KeyList = KeybindList

            local Items = { } do 
                Items["KeybindsList"] = Instances:Create("Frame", {
                    Parent = Library.Holder.Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0, 0.5),
                    BackgroundTransparency = 0.30000001192092896,
                    Position = UDim2New(0, 20, 0.5, 20),
                    Size = UDim2New(0, 100, 0, 30),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.XY,
                    BackgroundColor3 = FromRGB(27, 25, 29),
                    Visible = false,
                })  Items["KeybindsList"]:AddToTheme({BackgroundColor3 = "Section Background"})

                Items["KeybindsList"]:MakeDraggable()
                
                Instances:Create("UICorner", {
                    Parent = Items["KeybindsList"].Instance,
                    Name = "\0"
                })
                
                Items["Top"] = Instances:Create("Frame", {
                    Parent = Items["KeybindsList"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 12, 0, 40),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(31, 31, 36)
                })  Items["Top"]:AddToTheme({BackgroundColor3 = "Section Background 2"})
                
                Items["Icon"] = Instances:Create("ImageLabel", {
                    Parent = Items["Top"].Instance,
                    Name = "\0",
                    ImageColor3 = FromRGB(255, 255, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 21, 0, 20),
                    AnchorPoint = Vector2New(0, 0.5),
                    Image = "rbxassetid://81598136527047",
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 15, 0.5, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Instances:Create("UIGradient", {
                    Parent = Items["Icon"].Instance,
                    Name = "\0",
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(131, 131, 131)), RGBSequenceKeypoint(1, FromRGB(255, 255, 255))}
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                end})
                
                Items["Title"] = Instances:Create("TextLabel", {
                    Parent = Items["Top"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(248, 248, 248),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = Title,
                    AutomaticSize = Enum.AutomaticSize.X,
                    AnchorPoint = Vector2New(0, 0.5),
                    Size = UDim2New(0, 0, 0, 15),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 45, 0.5, -1),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    TextSize = 15,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Title"]:AddToTheme({TextColor3 = "Text"})
                
                Instances:Create("UICorner", {
                    Parent = Items["Top"].Instance,
                    Name = "\0"
                })
                
                Instances:Create("Frame", {
                    Parent = Items["Top"].Instance,
                    Name = "\0",
                    AnchorPoint = Vector2New(0, 1),
                    Position = UDim2New(0, 0, 1, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 10, 0, 5),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(31, 31, 36)
                }):AddToTheme({BackgroundColor3 = "Section Background 2"})
                
                Instances:Create("Frame", {
                    Parent = Items["Top"].Instance,
                    Name = "\0",
                    AnchorPoint = Vector2New(1, 1),
                    Position = UDim2New(1, 0, 1, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 10, 0, 5),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(31, 31, 36)
                }):AddToTheme({BackgroundColor3 = "Section Background 2"})
                
                Items["Content"] = Instances:Create("Frame", {
                    Parent = Items["KeybindsList"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 0, 0, 40),
                    Size = UDim2New(1, 12, 0, 0),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UIListLayout", {
                    Parent = Items["Content"].Instance,
                    Name = "\0",
                    Padding = UDimNew(0, 4),
                    SortOrder = Enum.SortOrder.LayoutOrder
                })
                
                Instances:Create("UIPadding", {
                    Parent = Items["Content"].Instance,
                    Name = "\0",
                    PaddingTop = UDimNew(0, 8),
                    PaddingBottom = UDimNew(0, 8),
                    PaddingRight = UDimNew(0, 8),
                    PaddingLeft = UDimNew(0, 8)
                })
                
                Instances:Create("UIPadding", {
                    Parent = Items["KeybindsList"].Instance,
                    Name = "\0",
                    PaddingRight = UDimNew(0, 12)
                })                
            end

            function KeybindList:SetVisibility(Bool)
                Items["KeybindsList"].Instance.Visible = Bool
            end

            function KeybindList:Add(Name, Key)
                local NewKey = Instances:Create("TextButton", {
                    Parent = Items["Content"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 0, 20),
                    BorderSizePixel = 0,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                local NewKeyAccent = Instances:Create("Frame", {
                    Parent = NewKey.Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0, 0.5),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 0, 0.5, 0),
                    Size = UDim2New(0, 6, 0, 6),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UIGradient",{
                    Parent = NewKeyAccent.Instance,
                    Name = "\0",
                    Rotation = -115,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(143, 143, 143))}
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                end})
                
                Instances:Create("UICorner", {
                    Parent = NewKeyAccent.Instance,
                    Name = "\0"
                })
                
                local NewKeyText = Instances:Create("TextLabel", {
                    Parent = NewKey.Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(255, 255, 255),
                    TextTransparency = 0.30000001192092896,
                    Text = Name .. " ["..Key.."]",
                    Size = UDim2New(0, 0, 0, 15),
                    AnchorPoint = Vector2New(0, 0.5),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 0, 0.5, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.X,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  NewKeyText:AddToTheme({TextColor3 = "Text"})

                function NewKey:Set(Name, Key)
                    NewKeyText.Instance.Text = Name .. " ["..Key.."]"
                end

                function NewKey:SetStatus(Bool)
                    if Bool then 
                        NewKeyText:Tween(nil, {Position = UDim2New(0, 15, 0.5, 0), TextTransparency = 0})
                        NewKeyAccent:Tween(nil, {BackgroundTransparency = 0})
                    else
                        NewKeyText:Tween(nil, {Position = UDim2New(0, 0, 0.5, 0), TextTransparency = 0.3})
                        NewKeyAccent:Tween(nil, {BackgroundTransparency = 1})
                    end
                end

                return NewKey
            end

            return KeybindList
        end

        Library.Notification = function(self, Data)
            local Items = { } do 
                Items["Notification"] = Instances:Create("Frame", {
                    Parent = Library.NotifHolder.Instance,
                    Name = "\0",
                    BackgroundTransparency = 0.3499999940395355,
                    BorderColor3 = FromRGB(0, 0, 0),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.XY,
                    BackgroundColor3 = FromRGB(27, 25, 29)
                })
                
                Items["Title"] = Instances:Create("TextLabel", {
                    Parent = Items["Notification"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(255, 255, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = Data.Title,
                    BackgroundTransparency = 1,
                    Size = UDim2New(0, 0, 0, 15),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.XY,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Title"]:AddToTheme({TextColor3 = "Text"})
                
                Instances:Create("UIPadding", {
                    Parent = Items["Notification"].Instance,
                    Name = "\0",
                    PaddingTop = UDimNew(0, 8),
                    PaddingBottom = UDimNew(0, 8),
                    PaddingRight = UDimNew(0, 8),
                    PaddingLeft = UDimNew(0, 8)
                })
                
                Instances:Create("UICorner", {
                    Parent = Items["Notification"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 5)
                })
                
                Items["Description"] = Instances:Create("TextLabel", {
                    Parent = Items["Notification"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(255, 255, 255),
                    TextTransparency = 0.30000001192092896,
                    Text = Data.Description,
                    Size = UDim2New(0, 0, 0, 15),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 0, 0, 20),
                    BorderColor3 = FromRGB(0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.XY,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Description"]:AddToTheme({TextColor3 = "Text"})
                
                Items["Accent"] = Instances:Create("Frame", {
                    Parent = Items["Notification"].Instance,
                    Name = "\0",
                    Position = UDim2New(0, 0, 0, Items["Description"].Instance.AbsoluteSize.Y + Items["Title"].Instance.AbsoluteSize.Y + 12),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 0, 0, 6),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Instances:Create("UICorner", {
                    Parent = Items["Accent"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(1, 0)
                })
                
                Instances:Create("UIGradient", {
                    Parent = Items["Accent"].Instance,
                    Name = "\0",
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(143, 143, 143))}
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                end})
                
                Items["Icon"] = Instances:Create("ImageLabel", {
                    Parent = Items["Notification"].Instance,
                    Name = "\0",
                    ImageColor3 = FromRGB(255, 255, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(1, 0),
                    Image = "rbxassetid://" .. (Data.Icon or "73789337996373"),
                    BackgroundTransparency = 1,
                    Position = UDim2New(1, 0, 0, 0),
                    Size = UDim2New(0, 16, 0, 16),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                if not Data.IconColor then
                    Instances:Create("UIGradient", {
                        Parent = Items["Icon"].Instance,
                        Name = "\0",
                        Rotation = -115,
                        Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(143, 143, 143))}
                    }):AddToTheme({Color = function()
                        return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                    end})             
                else
                    Instances:Create("UIGradient", {
                        Parent = Items["Icon"].Instance,
                        Name = "\0",
                        Rotation = -115,
                        Color = RGBSequence{RGBSequenceKeypoint(0, Data.IconColor.Start), RGBSequenceKeypoint(1, Data.IconColor.End)}
                    })         
                end   
            end

            local Size = Items["Notification"].Instance.AbsoluteSize
            Items["Notification"].Instance.Size = UDim2New(0, 0, 0, 0)

            for Index, Value in Items do 
                if Value.Instance:IsA("Frame") then
                    Value.Instance.BackgroundTransparency = 1
                elseif Value.Instance:IsA("TextLabel") then 
                    Value.Instance.TextTransparency = 1
                elseif Value.Instance:IsA("ImageLabel") then 
                    Value.Instance.ImageTransparency = 1
                end
            end 
            
            task.wait(0.2)

            Items["Notification"].Instance.AutomaticSize = Enum.AutomaticSize.Y

            Library:Thread(function()
                for Index, Value in Items do
                    if Value and Value.Instance and Value.Instance.Parent then
                        if Value.Instance:IsA("Frame") then
                            Value:Tween(TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out, 0, false, 0), {BackgroundTransparency = 0})
                        elseif Value.Instance:IsA("TextLabel") then
                            Value:Tween(TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out, 0, false, 0), {TextTransparency = 0})
                        elseif Value.Instance:IsA("ImageLabel") then
                            Value:Tween(TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out, 0, false, 0), {ImageTransparency = 0})
                        end
                    end
                end
                if Items["Notification"] and Items["Notification"].Instance and Items["Notification"].Instance.Parent then
                    Items["Notification"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out, 0, false, 0), {Size = UDim2New(0, Size.X, 0, Size.Y)})
                    Items["Accent"]:Tween(TweenInfo.new(Data.Duration, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {Size = UDim2New(1, 0, 0, 6)})
                end

                task.delay(Data.Duration + 0.15, function()
                    for Index, Value in Items do
                        if Value and Value.Instance and Value.Instance.Parent then
                            if Value.Instance:IsA("Frame") then
                                Value:Tween(nil, {BackgroundTransparency = 1})
                            elseif Value.Instance:IsA("TextLabel") then
                                Value:Tween(nil, {TextTransparency = 1})
                            elseif Value.Instance:IsA("ImageLabel") then
                                Value:Tween(nil, {ImageTransparency = 1})
                            end
                        end
                    end
                    if Items["Notification"] and Items["Notification"].Instance and Items["Notification"].Instance.Parent then
                        Items["Notification"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out, 0, false, 0), {Size = UDim2New(0, 0, 0, 0)})
                        task.wait(0.5)
                        Items["Notification"]:Clean()
                    end
                end)
            end)
        end

        Library.Window = function(self, Data)
            Data = Data or { }

            local Window = {
                Name = Data.Name or Data.name or "Window",
                SubName = Data.SubName or Data.subname or "Fine-tuning for sure wins",
                Logo = Data.Logo or Data.logo or "1l20959262762131",
                
                Pages = { },
                Items = { },
                IsOpen = false,
                CurrentAlignment = "LeftTabs"
            }

            local Items = { } do
                Items["MainFrame"] = Instances:Create("Frame", {
                    Parent = Library.Holder.Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0.5, 0.5),
                    BackgroundTransparency = 1,   -- фон окна рисует WindowBG (клип-прокси ниже), сам MainFrame прозрачный
                    Position = UDim2New(0.5519999861717224, 0, 0.5, 0),
                    Size = UDim2New(0, 677, 0, 644),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(27, 25, 29)
                })  Items["MainFrame"]:AddToTheme({BackgroundColor3 = "Background"})

                if IsMobile then 
                    local UIScale = Instances:Create("UIScale", {
                        Parent = Items["MainFrame"].Instance,
                        Name = "\0",
                        Scale = 0.56
                    })

                    -- keep flag in sync so UI Size slider shows correct value
                    Library.Flags["UIScale"] = 0.56
                end

                Items["MainFrame"]:MakeResizeable(Vector2New(Items["MainFrame"].Instance.AbsoluteSize.X, Items["MainFrame"].Instance.AbsoluteSize.Y), Vector2New(9999, 9999), OriginalSizes)
                Library:MakeBlurred(Items["MainFrame"], Window)

                -- ФОН ОКНА через клип-прокси: видимый фон — WindowBG, он на 20px шире ВЛЕВО и обрезан
                -- клипом → его левые углы всегда ПРЯМЫЕ (стык с панелью табов — монолит, без клиньев
                -- и без наложения полупрозрачных слоёв), правые углы скругляет UICorner (SetCorner).
                Items["WindowClip"] = Instances:Create("Frame", {
                    Parent = Items["MainFrame"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 1, 0),
                    ZIndex = 1,
                    BorderSizePixel = 0,
                    ClipsDescendants = true
                })

                Items["WindowBG"] = Instances:Create("Frame", {
                    Parent = Items["WindowClip"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 0.12,
                    Position = UDim2New(0, -20, 0, 0),
                    Size = UDim2New(1, 20, 1, 0),
                    ZIndex = 1,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(27, 25, 29)
                })  Items["WindowBG"]:AddToTheme({BackgroundColor3 = "Background"})

                Instances:Create("UICorner", {
                    Parent = Items["WindowBG"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })
                
                -- ПАНЕЛЬ ТАБОВ через клип: панель на 20px шире ВПРАВО и обрезана клипом → её правые
                -- углы всегда ПРЯМЫЕ (стык с окном — монолит), левые скругляет UICorner (SetCorner).
                Items["LeftTabsClip"] = Instances:Create("Frame", {
                    Parent = Items["MainFrame"].Instance,
                    Name = "\0",
                    AnchorPoint = Vector2New(1, 0),
                    BackgroundTransparency = 1,
                    Size = UDim2New(0, 225, 1, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    ClipsDescendants = true
                })

                Items["LeftTabs"] = Instances:Create("ScrollingFrame", {
                    Parent = Items["LeftTabsClip"].Instance,
                    Name = "\0",
                    Visible = true,
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0, 0),
                    BackgroundTransparency = 0.15,
                    Size = UDim2New(1, 20, 1, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(27, 25, 29),
                    Active = true,
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    CanvasSize = UDim2New(0, 0, 0, 0),
                    ScrollBarThickness = 2,
                    ScrollingDirection = Enum.ScrollingDirection.Y,
                    VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
                })  Items["LeftTabs"]:AddToTheme({BackgroundColor3 = "Background"})

                Items["LeftTabs"]:AddToTheme({ScrollBarImageColor3 = "Accent"})
                Library:MakeBlurred(Items["LeftTabs"], Window)

                local Gui = Items["MainFrame"].Instance

                local Dragging = false 
                local DragStart
                local StartPosition 
    
                local Set = function(Input)
                    local DragDelta = Input.Position - DragStart
                    Items["MainFrame"]:Tween(TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(StartPosition.X.Scale, StartPosition.X.Offset + DragDelta.X, StartPosition.Y.Scale, StartPosition.Y.Offset + DragDelta.Y)})
                end
    
                Items["MainFrame"]:Connect("InputBegan", function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                        Dragging = true
    
                        DragStart = Input.Position
                        StartPosition = Gui.Position
    
                        Input.Changed:Connect(function()
                            if Input.UserInputState == Enum.UserInputState.End then
                                Dragging = false
                            end
                        end)
                    end
                end)

                Items["LeftTabs"]:Connect("InputBegan", function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                        Dragging = true
    
                        DragStart = Input.Position
                        StartPosition = Gui.Position
    
                        Input.Changed:Connect(function()
                            if Input.UserInputState == Enum.UserInputState.End then
                                Dragging = false
                            end
                        end)
                    end
                end)
    
                Library:Connect(UserInputService.InputChanged, function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
                        if Dragging then
                            Set(Input)
                        end
                    end
                end)

                if IsMobile then
                    Items["FloatingButton"] = Instances:Create("TextButton", {
                        Parent = Library.Holder.Instance,
                        Text = "",
                        AutoButtonColor = false,
                        Name = "\0",
                        Position = UDim2New(0.5, 0, 0, 20),
                        AnchorPoint = Vector2New(0.5, 0),
                        Visible = false,   -- СКРЫТА: тоглом меню служит постоянный чип (иначе на телефоне 2 кнопки)
                        BorderColor3 = FromRGB(0, 0, 0),
                        Size = UDim2New(0, 50, 0, 50),
                        BorderSizePixel = 0,
                        BackgroundTransparency = 0.5,
                        ZIndex = 127,
                        BackgroundColor3 = Library.Theme.Background
                    })  Items["FloatingButton"]:AddToTheme({BackgroundColor3 = "Background"})

                    local Gui = Items["FloatingButton"].Instance

                    local Dragging = false 
                    local DragStart
                    local StartPosition 
        
                    local Set = function(Input)
                        local DragDelta = Input.Position - DragStart
                        Items["FloatingButton"]:Tween(TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(StartPosition.X.Scale, StartPosition.X.Offset + DragDelta.X, StartPosition.Y.Scale, StartPosition.Y.Offset + DragDelta.Y)})
                    end
        
                    Items["FloatingButton"]:Connect("InputBegan", function(Input)
                        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                            Dragging = true
        
                            DragStart = Input.Position
                            StartPosition = Gui.Position
        
                            Input.Changed:Connect(function()
                                if Input.UserInputState == Enum.UserInputState.End then
                                    Dragging = false
                                end
                            end)
                        end
                    end)
        
                    Library:Connect(UserInputService.InputChanged, function(Input)
                        if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
                            if Dragging then
                                Set(Input)
                            end
                        end
                    end)

                    Items["FloatingLogo"] = Instances:Create("ImageLabel", {
                        Parent = Items["FloatingButton"].Instance,
                        BorderColor3 = FromRGB(0, 0, 0),
                        Name = "\0",
                        Image = "rbxassetid://" .. Window.Logo,
                        BackgroundTransparency = 1,
                        AnchorPoint = Vector2New(0.5, 0.5),
                        Position = UDim2New(0.5, 0, 0.5, 0),
                        ZIndex = 127,
                        Size = UDim2New(1, -25, 1, -25),
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })
        
                    Instances:Create("UICorner", {
                        Parent = Items["FloatingButton"].Instance,
                        CornerRadius = UDimNew(1, 0)
                    }) 

                    Instances:Create("UIGradient", {
                        Parent = Items["FloatingLogo"].Instance,
                        Name = "\0",
                        Enabled = true,
                        Rotation = -115,
                        Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(143, 143, 143))}
                    }):AddToTheme({Color = function()
                        return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                    end})
                end

                Items["PagePlaceholder"] = Instances:Create("Frame", {
                    Parent = Items["MainFrame"].Instance,
                    Name = "\0",
                    Visible = true,
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0, 0),
                    BackgroundTransparency = 1,
                    Size = UDim2New(0, 0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Instances:Create("UIListLayout", {
                    Parent = Items["LeftTabs"].Instance,
                    Name = "\0",
                    Padding = UDimNew(0, 12),
                    SortOrder = Enum.SortOrder.LayoutOrder
                })
                
                Instances:Create("UIPadding", {
                    Parent = Items["LeftTabs"].Instance,
                    Name = "\0",
                    PaddingTop = UDimNew(0, 15),
                    PaddingBottom = UDimNew(0, 15),
                    PaddingRight = UDimNew(0, 12),
                    PaddingLeft = UDimNew(0, 12)
                })

                Items["Logo"] = Instances:Create("ImageLabel", {
                    Parent = Items["MainFrame"].Instance,
                    Name = "\0",
                    ImageColor3 = FromRGB(255, 255, 255),
                    ScaleType = Enum.ScaleType.Fit,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 35, 0, 35),
                    Image = "rbxassetid://"..Window.Logo,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 12, 0, 12),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                }) 

                Instances:Create("UIGradient", {
                    Parent = Items["Logo"].Instance,
                    Name = "\0",
                    Enabled = true,
                    Rotation = -115,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(143, 143, 143))}
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                end})
                
                Items["Title"] = Instances:Create("TextLabel", {
                    Parent = Items["MainFrame"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = Window.Name,
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(0, 0, 0, 15),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 52, 0, 13),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    TextSize = 16,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Title"]:AddToTheme({TextColor3 = "Text"})
                
                Items["SubTitle"] = Instances:Create("TextLabel", {
                    Parent = Items["MainFrame"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.4000000059604645,
                    Text = Window.SubName,
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(0, 0, 0, 15),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 52, 0, 30),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["SubTitle"]:AddToTheme({TextColor3 = "Text"})

                Items["Content"] = Instances:Create("Frame", {
                    Parent = Items["MainFrame"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    BackgroundTransparency = 0.75,
                    Position = UDim2New(0, 0, 0, 55),
                    Size = UDim2New(1, 0, 1, -55),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(27, 25, 29)
                })  Items["Content"]:AddToTheme({BackgroundColor3 = "Background"})

                Items["CloseButton"] = Instances:Create("TextButton", {
                    Parent = Items["MainFrame"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    AnchorPoint = Vector2New(1, 0),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 0.20000000298023224,
                    Position = UDim2New(1, -14, 0, 11),
                    Size = UDim2New(0, 32, 0, 32),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(27, 25, 29)
                })  Items["CloseButton"]:AddToTheme({BackgroundColor3 = "Element"})
                
                Instances:Create("UICorner", {
                    Parent = Items["CloseButton"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 7)
                })
                
                Items["CloseIcon"] = Instances:Create("ImageLabel", {
                    Parent = Items["CloseButton"].Instance,
                    Name = "\0",
                    ImageColor3 = FromRGB(240, 240, 240),
                    ImageTransparency = 0.30000001192092896,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 11, 0, 11),
                    AnchorPoint = Vector2New(0.5, 0.5),
                    Image = "rbxassetid://130510492706892",
                    BackgroundTransparency = 1,
                    Position = UDim2New(0.5, 0, 0.5, 0),
                    ZIndex = 3,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["CloseIcon"]:AddToTheme({ImageColor3 = "Text"})        
                
                Items["CloseIconAccent"] = Instances:Create("Frame", {
                    Parent = Items["CloseButton"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0.5, 0.5),
                    BorderSizePixel = 0,
                    Position = UDim2New(0.5, 0, 0.5, 0),
                    Size = UDim2New(0, 0, 0, 0),
                    ZIndex = 2,
                    BackgroundTransparency = 1,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UICorner", {
                    Parent = Items["CloseIconAccent"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 7)
                })

                Instances:Create("UICorner", {
                    Parent = Items["MainFrame"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })      

                Instances:Create("UICorner", {
                    Parent = Items["LeftTabs"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })      
                
                do
                    Items["LeftBottomPixels"] = Instances:Create("Frame", {
                        Parent = Items["MainFrame"].Instance,
                        Name = "\0",
                        BorderColor3 = FromRGB(0, 0, 0),
                        AnchorPoint = Vector2New(1, 1),
                        BackgroundTransparency = 1,
                        Position = UDim2New(0, 1, 1, 0),
                        Size = UDim2New(0, 5, 0, 5),
                        ZIndex = 2,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })
                    
                    Items["___1"] = Instances:Create("Frame", {
                        Parent = Items["LeftBottomPixels"].Instance,
                        Name = "\0",
                        BorderColor3 = FromRGB(0, 0, 0),
                        AnchorPoint = Vector2New(0, 1),
                        BackgroundTransparency = 0.11999999731779099,
                        Position = UDim2New(0, 2, 1, 0),
                        Size = UDim2New(0, 1, 0, 1),
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  Items["___1"]:AddToTheme({BackgroundColor3 = "Background"})
                    
                    Items["___2"] = Instances:Create("Frame", {
                        Parent = Items["LeftBottomPixels"].Instance,
                        Name = "\0",
                        BorderColor3 = FromRGB(0, 0, 0),
                        AnchorPoint = Vector2New(0, 1),
                        BackgroundTransparency = 0.11999999731779099,
                        Position = UDim2New(0, 4, 1, 0),
                        Size = UDim2New(0, 1, 0, 1),
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  Items["___2"]:AddToTheme({BackgroundColor3 = "Background"})
                    
                    Items["___3"] = Instances:Create("Frame", {
                        Parent = Items["LeftBottomPixels"].Instance,
                        Name = "\0",
                        BorderColor3 = FromRGB(0, 0, 0),
                        AnchorPoint = Vector2New(0, 1),
                        BackgroundTransparency = 0.11999999731779099,
                        Position = UDim2New(0, 3, 1, 0),
                        Size = UDim2New(0, 1, 0, 1),
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  Items["___3"]:AddToTheme({BackgroundColor3 = "Background"})
                    
                    Items["___4"] = Instances:Create("Frame", {
                        Parent = Items["LeftBottomPixels"].Instance,
                        Name = "\0",
                        BorderColor3 = FromRGB(0, 0, 0),
                        AnchorPoint = Vector2New(0, 1),
                        BackgroundTransparency = 0.11999999731779099,
                        Position = UDim2New(0, 3, 1, -1),
                        Size = UDim2New(0, 1, 0, 1),
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  Items["___4"]:AddToTheme({BackgroundColor3 = "Background"})
                    
                    Items["___5"] = Instances:Create("Frame", {
                        Parent = Items["LeftBottomPixels"].Instance,
                        Name = "\0",
                        BorderColor3 = FromRGB(0, 0, 0),
                        AnchorPoint = Vector2New(0, 1),
                        BackgroundTransparency = 0.11999999731779099,
                        Position = UDim2New(0, 4, 1, -1),
                        Size = UDim2New(0, 1, 0, 1),
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  Items["___5"]:AddToTheme({BackgroundColor3 = "Background"})
                    
                    Items["___6"] = Instances:Create("Frame", {
                        Parent = Items["LeftBottomPixels"].Instance,
                        Name = "\0",
                        BorderColor3 = FromRGB(0, 0, 0),
                        AnchorPoint = Vector2New(0, 1),
                        BackgroundTransparency = 0.11999999731779099,
                        Position = UDim2New(0, 5, 1, 0),
                        Size = UDim2New(0, 1, 0, 1),
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  Items["___6"]:AddToTheme({BackgroundColor3 = "Background"})
                    
                    
                    
                    Items["LeftTopPixels"] = Instances:Create("Frame", {
                        Parent = Items["MainFrame"].Instance,
                        Name = "\0",
                        BorderColor3 = FromRGB(0, 0, 0),
                        AnchorPoint = Vector2New(1, 0),
                        BackgroundTransparency = 1,
                        Position = UDim2New(0, 1, 0, 0),
                        Size = UDim2New(0, 5, 0, 5),
                        ZIndex = 2,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })
                    
                    Items["___7"] = Instances:Create("Frame", {
                        Parent = Items["LeftTopPixels"].Instance,
                        Name = "\0",
                        Size = UDim2New(0, 1, 0, 1),
                        Position = UDim2New(0, 2, 0, 0),
                        BorderColor3 = FromRGB(0, 0, 0),
                        ZIndex = 2,
                        BackgroundTransparency = 0.12,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  Items["___7"]:AddToTheme({BackgroundColor3 = "Background"})   
                    
                    Items["___8"]= Instances:Create("Frame", {
                        Parent = Items["LeftTopPixels"].Instance,
                        Name = "\0",
                        Size = UDim2New(0, 1, 0, 1),
                        BackgroundTransparency = 0.12,
                        Position = UDim2New(0, 3, 0, 0),
                        BorderColor3 = FromRGB(0, 0, 0),
                        ZIndex = 2,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  Items["___8"]:AddToTheme({BackgroundColor3 = "Background"})   
                    
                    Items["___9"]= Instances:Create("Frame", {
                        Parent = Items["LeftTopPixels"].Instance,
                        Name = "\0",
                        Size = UDim2New(0, 1, 0, 1),
                        Position = UDim2New(0, 4, 0, 0),
                        BackgroundTransparency = 0.12,
                        BorderColor3 = FromRGB(0, 0, 0),
                        ZIndex = 2,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  Items["___9"]:AddToTheme({BackgroundColor3 = "Background"})   
                    
                    Items["___10"] = Instances:Create("Frame", {
                        Parent = Items["LeftTopPixels"].Instance,
                        Name = "\0",
                        Size = UDim2New(0, 1, 0, 1),
                        Position = UDim2New(0, 5, 0, 0),
                        BorderColor3 = FromRGB(0, 0, 0),
                        BackgroundTransparency = 0.12,
                        ZIndex = 2,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  Items["___10"]:AddToTheme({BackgroundColor3 = "Background"})   
                    
                    Items["___11"]=Instances:Create("Frame", {
                        Parent = Items["LeftTopPixels"].Instance,
                        Name = "\0",
                        Size = UDim2New(0, 1, 0, 1),
                        Position = UDim2New(0, 3, 0, 1),
                        BorderColor3 = FromRGB(0, 0, 0),
                        ZIndex = 2,
                        BackgroundTransparency = 0.12,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  Items["___11"]:AddToTheme({BackgroundColor3 = "Background"})   
                    
                    Items["___12"] = Instances:Create("Frame", {
                        Parent = Items["LeftTopPixels"].Instance,
                        Name = "\0",
                        Size = UDim2New(0, 1, 0, 1),
                        Position = UDim2New(0, 4, 0, 1),
                        BorderColor3 = FromRGB(0, 0, 0),
                        ZIndex = 2,
                        BackgroundTransparency = 0.12,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  Items["___12"]:AddToTheme({BackgroundColor3 = "Background"})                                      
                end

                function Window:SetTransparency()
                    -- фон окна теперь рисует WindowBG (MainFrame всегда прозрачный — см. клип-прокси)
                    Items["WindowBG"].Instance.BackgroundTransparency = Library.Flags["BackgroundTransparency"]
                    Items["LeftTabs"].Instance.BackgroundTransparency = Library.Flags["BackgroundTransparency"]
                    if IsMobile then
                        Items["FloatingButton"].Instance.BackgroundTransparency = Library.Flags["BackgroundTransparency"]  
                    end

                    for _, Value in Items do 
                        if _:find("___") then
                            Value.Instance.BackgroundTransparency = tonumber(Library.Flags["BackgroundTransparency"])
                        end
                    end
                end

                function Window:SetUIScale()
                    local UIScale = Items["MainFrame"].Instance:FindFirstChildOfClass("UIScale")

                    if not UIScale then
                        local UIScaleItem = Instances:Create("UIScale", {
                            Parent = Items["MainFrame"].Instance,
                            Name = "\0",
                            Scale = 1
                        })

                        UIScale = UIScaleItem.Instance
                    end

                    UIScale.Scale = Library.Flags["UIScale"] or 1
                end

                -- ДОБАВЛЕНО: сила скругления UI. Ставит радиус всем НЕ-круглым UICorner меню
                -- (у круглых Scale>0, напр. UDim(1,0) — иконки/ползунки — не трогаем, иначе сломаются).
                -- UI Corner: скругляются ТОЛЬКО внешние 4 угла всего меню.
                -- Левые 2 = панель табов (LeftTabs, левые углы; правые обрезает LeftTabsClip).
                -- Правые 2 = фон окна (WindowBG, правые углы; левые обрезает WindowClip).
                -- Стык панели и окна — монолит без клиньев и наложений (обрезка вместо заплаток).
                function Window:SetCorner()
                    local v = Library.Flags["UICorner"]
                    if v == nil then v = 6 end
                    pcall(function()
                        local c = Items["WindowBG"].Instance:FindFirstChildOfClass("UICorner")
                        if c then c.CornerRadius = UDimNew(0, v) end
                    end)
                    pcall(function()
                        local c = Items["LeftTabs"].Instance:FindFirstChildOfClass("UICorner")
                        if c then c.CornerRadius = UDimNew(0, v) end
                    end)
                    -- Подложка контента (Content) прижата к низу окна и была БЕЗ угла — её квадратные
                    -- нижние углы торчали ПОВЕРХ скругления окна. Даём ей тот же радиус.
                    pcall(function()
                        local ct = Items["Content"].Instance
                        local c = ct:FindFirstChildOfClass("UICorner")
                        if not c then
                            c = Instance.new("UICorner")
                            c.Name = "\0"
                            c.Parent = ct
                        end
                        c.CornerRadius = UDimNew(0, v)
                    end)
                    -- Декоративные «пиксели» были подгонкой под старую геометрию (радиус 4) — прячем всегда.
                    pcall(function()
                        if Items["LeftBottomPixels"] then Items["LeftBottomPixels"].Instance.Visible = false end
                        if Items["LeftTopPixels"] then Items["LeftTopPixels"].Instance.Visible = false end
                    end)
                end
                Window:SetCorner()   -- применяем дефолт сразу при сборке окна

                -- РАЗМЕР ОКНА 1-в-1: ресайз тянучкой сохраняется в конфиг/автосейв и
                -- восстанавливается при загрузке (флаг WindowSize, штампуется в автосейв-цикле)
                Library.SetFlags["WindowSize"] = function(v)
                    if type(v) == "table" and tonumber(v[1]) and tonumber(v[2]) then
                        Items["MainFrame"].Instance.Size = UDim2New(0, math.clamp(tonumber(v[1]), 300, 3000), 0, math.clamp(tonumber(v[2]), 200, 2000))
                    end
                end

                Instances:Create("UIGradient", {
                    Parent = Items["CloseIconAccent"].Instance,
                    Name = "\0",
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(143, 143, 143))},
                    Rotation = -115
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                end})

                -- Minimize Button (hidden - X button now minimizes)
                Items["MinimizeButton"] = Instances:Create("TextButton", {
                    Parent = Items["MainFrame"].Instance,
                    Name = "\0",
                    Visible = false,
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    AnchorPoint = Vector2New(1, 0),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 0.20000000298023224,
                    Position = UDim2New(1, -56, 0, 11),
                    Size = UDim2New(0, 32, 0, 32),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(27, 25, 29)
                })  Items["MinimizeButton"]:AddToTheme({BackgroundColor3 = "Element"})
                
                Instances:Create("UICorner", {
                    Parent = Items["MinimizeButton"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 7)
                })
                
                Items["MinimizeIcon"] = Instances:Create("ImageLabel", {
                    Parent = Items["MinimizeButton"].Instance,
                    Name = "\0",
                    ImageColor3 = FromRGB(240, 240, 240),
                    ImageTransparency = 0.30000001192092896,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 11, 0, 11),
                    AnchorPoint = Vector2New(0.5, 0.5),
                    Image = "rbxassetid://79384247470010",
                    BackgroundTransparency = 1,
                    Position = UDim2New(0.5, 0, 0.5, 0),
                    ZIndex = 3,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["MinimizeIcon"]:AddToTheme({ImageColor3 = "Text"})
                
                Items["MinimizeIconAccent"] = Instances:Create("Frame", {
                    Parent = Items["MinimizeButton"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0.5, 0.5),
                    BorderSizePixel = 0,
                    Position = UDim2New(0.5, 0, 0.5, 0),
                    Size = UDim2New(0, 0, 0, 0),
                    ZIndex = 2,
                    BackgroundTransparency = 1,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UICorner", {
                    Parent = Items["MinimizeIconAccent"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 7)
                })
                
                Instances:Create("UIGradient", {
                    Parent = Items["MinimizeIconAccent"].Instance,
                    Name = "\0",
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(143, 143, 143))},
                    Rotation = -115
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                end})
                
                Items["MinimizeButton"]:OnHover(function()
                    Items["MinimizeIconAccent"]:Tween(TweenInfo.new(Library.Tween.Time + 0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2New(1, 0, 1, 0),
                        BackgroundTransparency = 0
                    })
                end)

                Items["MinimizeButton"]:OnHoverLeave(function()
                    Items["MinimizeIconAccent"]:Tween(TweenInfo.new(Library.Tween.Time + 0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2New(0, 0, 0, 0),
                        BackgroundTransparency = 1
                    })
                end)
                
                Items["MinimizeButton"]:Connect("MouseButton1Down", function()
                    Window:SetOpen(false)
                end)

                Items["SettingsButton"] = Instances:Create("TextButton", {
                    Parent = Items["MainFrame"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    AnchorPoint = Vector2New(1, 0),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 0.20000000298023224,
                    Position = UDim2New(1, -56, 0, 11),
                    Size = UDim2New(0, 32, 0, 32),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(27, 25, 29)
                })  Items["SettingsButton"]:AddToTheme({BackgroundColor3 = "Element"})
                
                Instances:Create("UICorner", {
                    Parent = Items["SettingsButton"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 7)
                })
                
                Items["SettingsIcon"] = Instances:Create("ImageLabel", {
                    Parent = Items["SettingsButton"].Instance,
                    Name = "\0",
                    ImageColor3 = FromRGB(240, 240, 240),
                    ImageTransparency = 0.30000001192092896,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 15, 0, 14),
                    AnchorPoint = Vector2New(0.5, 0.5),
                    Image = "rbxassetid://122669828593160",
                    BackgroundTransparency = 1,
                    Position = UDim2New(0.5, 0, 0.5, 0),
                    ZIndex = 3,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["SettingsIcon"]:AddToTheme({ImageColor3 = "Text"})

                Items["SettingsIconAccent"] = Instances:Create("Frame", {
                    Parent = Items["SettingsButton"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0.5, 0.5),
                    BorderSizePixel = 0,
                    Position = UDim2New(0.5, 0, 0.5, 0),
                    Size = UDim2New(0, 0, 0, 0),
                    ZIndex = 2,
                    BackgroundTransparency = 1,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UICorner", {
                    Parent = Items["SettingsIconAccent"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 7)
                })

                Instances:Create("UIGradient", {
                    Parent = Items["SettingsIconAccent"].Instance,
                    Name = "\0",
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(143, 143, 143))},
                    Rotation = -115
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                end})

                Items["SettingsButton"]:OnHover(function()
                    Items["SettingsIconAccent"]:Tween(TweenInfo.new(Library.Tween.Time + 0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2New(1, 0, 1, 0),
                        BackgroundTransparency = 0
                    })
                end)

                Items["SettingsButton"]:OnHoverLeave(function()
                    Items["SettingsIconAccent"]:Tween(TweenInfo.new(Library.Tween.Time + 0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2New(0, 0, 0, 0),
                        BackgroundTransparency = 1
                    })
                end)

                Items["CloseButton"]:OnHover(function()
                    Items["CloseIconAccent"]:Tween(TweenInfo.new(Library.Tween.Time + 0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2New(1, 0, 1, 0),
                        BackgroundTransparency = 0
                    })
                end)

                Items["CloseButton"]:OnHoverLeave(function()
                    Items["CloseIconAccent"]:Tween(TweenInfo.new(Library.Tween.Time + 0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2New(0, 0, 0, 0),
                        BackgroundTransparency = 1
                    })
                end)
                
                Items["CloseButton"]:Connect("MouseButton1Down", function()
                    Window:SetOpen(false)
                end)
                
                local Settings = {
                    IsOpen = false,
                    Name = ""..#Library.Sections,
                    Items = { },
                    IsSettings = true,
                    Elements = { }
                }

                local SettingsItems = { }
                do
                    SettingsItems["Settings"] = Instances:Create("Frame", {
                        Parent = Library.UnusedHolder.Instance,
                        Name = "\0",
                        BorderColor3 = FromRGB(0, 0, 0),
                        AnchorPoint = Vector2New(0.5, 0.5),
                        BorderSizePixel = 0,
                        Position = UDim2New(0.8949604630470276, 0, 0.2945185601711273, 0),
                        Size = UDim2New(0, 245, 0, 159),
                        ZIndex = 2,
                        AutomaticSize = Enum.AutomaticSize.Y,
                        BackgroundColor3 = FromRGB(21, 21, 24)
                    }) SettingsItems["Settings"]:AddToTheme({BackgroundColor3 = "Section Background 2"})
                    
                    Instances:Create("UICorner", {
                        Parent = SettingsItems["Settings"].Instance,
                        Name = "\0",
                        CornerRadius = UDimNew(0, 6)
                    })
                    
                    SettingsItems["CloseButton"] = Instances:Create("TextButton", {
                        Parent = SettingsItems["Settings"].Instance,
                        Name = "\0",
                        FontFace = Library.Font,
                        TextColor3 = FromRGB(0, 0, 0),
                        BorderColor3 = FromRGB(0, 0, 0),
                        Text = "",
                        AutoButtonColor = false,
                        AnchorPoint = Vector2New(0, 1),
                        BorderSizePixel = 0,
                        Position = UDim2New(0, 8, 1, -8),
                        Size = UDim2New(1, -16, 0, 32),
                        ZIndex = 2,
                        TextSize = 14,
                        BackgroundColor3 = FromRGB(27, 26, 29)
                    }) SettingsItems["CloseButton"]:AddToTheme({BackgroundColor3 = "Element"})
                    
                    Instances:Create("UICorner", {
                        Parent = SettingsItems["CloseButton"].Instance,
                        Name = "\0",
                        CornerRadius = UDimNew(0, 4)
                    })
                    
                    SettingsItems["Text"] = Instances:Create("TextLabel", {
                        Parent = SettingsItems["CloseButton"].Instance,
                        Name = "\0",
                        FontFace = Library.Font,
                        TextColor3 = FromRGB(240, 240, 240),
                        TextTransparency = 0.30000001192092896,
                        Text = "Close",
                        AutomaticSize = Enum.AutomaticSize.X,
                        Size = UDim2New(0, 0, 0, 15),
                        AnchorPoint = Vector2New(0.5, 0.5),
                        BorderSizePixel = 0,
                        BackgroundTransparency = 1,
                        Position = UDim2New(0.5, 0, 0.5, 0),
                        BorderColor3 = FromRGB(0, 0, 0),
                        ZIndex = 2,
                        TextSize = 14,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })
                    
                    SettingsItems["Content"] = Instances:Create("ScrollingFrame", {
                        Parent = SettingsItems["Settings"].Instance,
                        Name = "\0",
                        AutomaticCanvasSize = Enum.AutomaticSize.Y,
                        Selectable = false,
                        Size = UDim2New(1, -8, 1, -46),
                        Position = UDim2New(0, 4, 0, 4),
                        ScrollBarThickness = 2,
                        BackgroundColor3 = FromRGB(255, 255, 255),
                        BackgroundTransparency = 1,
                        BorderColor3 = FromRGB(0, 0, 0),
                        BorderSizePixel = 0,
                        CanvasSize = UDim2New(0, 0, 0, 0)
                    })  SettingsItems["Content"]:AddToTheme({ScrollBarImageColor3 = "Accent"})
                    
                    Instances:Create("UIListLayout", {
                        Parent = SettingsItems["Content"].Instance,
                        Name = "\0",
                        Padding = UDimNew(0, 4),
                        SortOrder = Enum.SortOrder.LayoutOrder
                    })                    
                    
                    Instances:Create("UIPadding", {
                        Parent = SettingsItems["Content"].Instance,
                        Name = "\0",
                        PaddingTop = UDimNew(0, 4),
                        PaddingBottom = UDimNew(0, 4),
                        PaddingRight = UDimNew(0, 4),
                        PaddingLeft = UDimNew(0, 4)
                    })

                    SettingsItems["Accent"] = Instances:Create("Frame", {
                        Parent = SettingsItems["CloseButton"].Instance,
                        Name = "\0",
                        Size = UDim2New(0, 0, 0, 0),
                        BorderColor3 = FromRGB(0, 0, 0),
                        ZIndex = 2,
                        BorderSizePixel = 0,
                        BackgroundTransparency = 1,
                        BackgroundColor3 = FromRGB(255, 255, 255),
                        AnchorPoint = Vector2New(0.5, 0.5),
                        Position = UDim2New(0.5, 0, 0.5, 0)
                    })  --SettingsItems["Accent"]:AddToTheme({BackgroundColor3 = "Accent"})
    
                    SettingsItems["Gradient"] = Instances:Create("UIGradient", {
                        Parent = SettingsItems["Accent"].Instance,
                        Name = "\0",
                        Enabled = true,
                        Rotation = -115,
                        Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(143, 143, 143))}
                    })  SettingsItems["Gradient"]:AddToTheme({Color = function()
                        return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                    end})

                    Instances:Create("UICorner", {
                        Parent = SettingsItems["Accent"].Instance,
                        Name = "\0",
                        CornerRadius = UDimNew(0, 4)
                    })
    
                    Instances:Create("UICorner", {
                        Parent = SettingsItems["CloseButton"].Instance,
                        Name = "\0",
                        CornerRadius = UDimNew(0, 4)
                    })

                    SettingsItems["CloseButton"]:OnHover(function()
                        SettingsItems["Accent"]:Tween(TweenInfo.new(Library.Tween.Time + 0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2New(1, 0, 1, 0), BackgroundTransparency = 0})
                    end)
    
                    SettingsItems["CloseButton"]:OnHoverLeave(function()
                        SettingsItems["Accent"]:Tween(TweenInfo.new(Library.Tween.Time + 0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2New(0, 0, 0, 0), BackgroundTransparency = 1})
                    end)

                    local RenderStepped 
                    local Debounce = false
    
                    function Settings:SetOpen(Bool)
                        if Debounce then 
                            return
                        end
        
                        Settings.IsOpen = Bool
        
                        Debounce = true 
        
                        if Settings.IsOpen then 
                            for Index, Value in Settings.Elements do
                                if type(Value.RefreshPosition) == "function" then
                                    Value:RefreshPosition(true)
                                end
                                task.wait(0.03)
                            end
    
                            SettingsItems["Settings"].Instance.Visible = true
                            SettingsItems["Settings"].Instance.Parent = Library.Holder.Instance
                            
                            RenderStepped = RunService.RenderStepped:Connect(function()
                                SettingsItems["Settings"].Instance.Position = UDim2New(0, Items["SettingsIcon"].Instance.AbsolutePosition.X, 0, Items["SettingsIcon"].Instance.AbsolutePosition.Y + Items["SettingsButton"].Instance.AbsoluteSize.Y + 108)
                                SettingsItems["Settings"].Instance.Size = UDim2New(0, 325, 0, 230)
                            end)
        
                            for Index, Value in Library.OpenFrames do 
                                if Value ~= Settings then 
                                    Value:SetOpen(false)
                                end
                            end
        
                            Library.OpenFrames[Settings] = Settings 
                        else
                            for Index, Value in Settings.Elements do
                                if type(Value.RefreshPosition) == "function" then
                                    Value:RefreshPosition(false)
                                end
                            end
    
                            if Library.OpenFrames[Settings] then 
                                Library.OpenFrames[Settings] = nil
                            end
        
                            if RenderStepped then 
                                RenderStepped:Disconnect()
                                RenderStepped = nil
                            end
                        end
        
                        local Descendants = SettingsItems["Settings"].Instance:GetDescendants()
                        TableInsert(Descendants, SettingsItems["Settings"].Instance)
        
                        local NewTween
        
                        for Index, Value in Descendants do 
                            local TransparencyProperty = Tween:GetProperty(Value)
        
                            if not TransparencyProperty then
                                continue 
                            end
        
                            if not Value.ClassName:find("UI") then 
                                Value.ZIndex = Settings.IsOpen and 7 or 1
                                SettingsItems["Text"].Instance.ZIndex = 8
                            end
        
                            if type(TransparencyProperty) == "table" then 
                                for _, Property in TransparencyProperty do 
                                    NewTween = Tween:FadeItem(Value, Property, Bool, Library.FadeSpeed)
                                end
                            else
                                NewTween = Tween:FadeItem(Value, TransparencyProperty, Bool, Library.FadeSpeed)
                            end
                        end
                        
                        NewTween.Tween.Completed:Connect(function()
                            Debounce = false 
                            SettingsItems["Settings"].Instance.Visible = Settings.IsOpen
                            task.wait(0.2)
                            SettingsItems["Settings"].Instance.Parent = not Settings.IsOpen and Library.UnusedHolder.Instance or Library.Holder.Instance
                        end)
                    end
    
                    SettingsItems["CloseButton"]:Connect("MouseButton1Down", function()
                        Settings:SetOpen(false)
                    end)
    
                    Items["SettingsButton"]:Connect("InputBegan", function(Input)
                        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then 
                            Settings:SetOpen(not Settings.IsOpen)
                        end
                    end)
    
                    Settings.Items = SettingsItems
                    setmetatable(Settings, Library.Sections)
                end

                Settings:Label("First gradient color"):Colorpicker({
                    Flag = "AccentColor",
                    Default = Library.Theme.Accent,
                    Callback = function(Color)
                        Library.Theme.Accent = Color
                        Library:ChangeTheme("Accent", Color)
                    end
                })

                Settings:Label("Second gradient color"):Colorpicker({
                    Flag = "AccentGradientColor",
                    Default = Library.Theme.AccentGradient,
                    Callback = function(Color)
                        Library.Theme.AccentGradient = Color
                        Library:ChangeTheme("AccentGradient", Color)
                    end
                })

                Settings:Dropdown({
                    Name = "Font weight",
                    Flag = "FontStyle",
                    Default = "SemiBold",
                    Items = {"Light", "Regular", "SemiBold"},
                    Callback = function(Value)
                        local FontData = Library.Fonts[Value]

                        if FontData then
                            Library.Font = FontData
                            Library:UpdateText()
                        end
                    end
                })

                Settings:Dropdown({
                    Name = "Notification Position",
                    Flag = "NotificationPosition",
                    Default = "Right",
                    Items = {"Right", "Left"},
                    Callback = function(Value)
                        if Value == "Right" then
                            Library.NotifHolder.Instance.Position = UDim2New(1, 0, 0, 0)
                            Library.NotifHolder.Instance.AnchorPoint = Vector2New(1, 0)
                        else
                            Library.NotifHolder.Instance.Position = UDim2New(0, 0, 0, 0)
                            Library.NotifHolder.Instance.AnchorPoint = Vector2New(0, 0)
                        end
                    end
                })

                Settings:Slider({
                    Name = "Background Transparency",
                    Default = 0.12,
                    Decimals = 0.01,
                    Max = 1,
                    Min = 0,
                    Suffix = "%",
                    Flag = "BackgroundTransparency",
                    Callback = function(Value)
                        Window:SetTransparency(Value)
                    end
                })

                Settings:Slider({
                    Name = "UI Size",
                    Default = IsMobile and 0.56 or 1,
                    Decimals = 0.01,
                    Max = 1.3,
                    Min = 0.3,
                    Suffix = "x",
                    Flag = "UIScale",
                    Callback = function(Value)
                        Window:SetUIScale()
                    end
                })

                Settings:Slider({
                    Name = "UI Corner",
                    Default = 6,
                    Decimals = 1,
                    Max = 16,
                    Min = 0,
                    Suffix = "px",
                    Flag = "UICorner",
                    Callback = function(Value)
                        Window:SetCorner()
                    end
                })

                Settings:Keybind({
                    Name = "Menu Keybind",
                    Flag = "MenuBind",
                    Default = Enum.KeyCode.RightAlt,
                    Callback = function(Value)
                        Library.MenuKeybind = tostring(Value)
                    end
                })

                Window.Items = Items
            end
            
            local Debounce = false

            function Window:SetCenter()
                local CenterPosition = Items["MainFrame"].Instance.AbsolutePosition
                task.wait()
                Items["MainFrame"].Instance.AnchorPoint = Vector2New(0, 0)

                Items["MainFrame"].Instance.Position = UDim2New(0, CenterPosition.X, 0, CenterPosition.Y)
            end

            function Window:SetOpen(Bool)
                if Debounce then 
                    return
                end

                Window.IsOpen = Bool

                Debounce = true 

                if Window.IsOpen then 
                    Items["MainFrame"].Instance.Visible = true 
                end

                local Descendants = Items["MainFrame"].Instance:GetDescendants()
                TableInsert(Descendants, Items["MainFrame"].Instance)

                local NewTween

                for Index, Value in Descendants do 
                    local TransparencyProperty = Tween:GetProperty(Value)

                    if not TransparencyProperty then
                        continue 
                    end

                    if type(TransparencyProperty) == "table" then 
                        for _, Property in TransparencyProperty do 
                            NewTween = Tween:FadeItem(Value, Property, Bool, Library.FadeSpeed)
                        end
                    else
                        NewTween = Tween:FadeItem(Value, TransparencyProperty, Bool, Library.FadeSpeed)
                    end
                end
                
                NewTween.Tween.Completed:Connect(function()
                    Debounce = false 
                    Items["MainFrame"].Instance.Visible = Window.IsOpen
                end)
            end

            if IsMobile then 
                Items["FloatingButton"]:Connect("InputBegan", function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then 
                        Window:SetOpen(not Window.IsOpen)
                    end
                end)
            end

            --[[
            function Window:GetClosestFrame(Position, Instances)
                local ClosestRadius = math.huge
                local ClosestFrame

                local String = {"Items.LeftTabs", "Items.RightTabs", "Items.BottomTabs", "Items.TopTabs"}

                for Index, Value in (Instances or {Items.LeftTabs.Instance, Items.RightTabs.Instance, Items.BottomTabs.Instance, Items.TopTabs.Instance}) do
                    local Magnitude = (Vector2New(Value.AbsolutePosition.X, Value.AbsolutePosition.Y) - Position).Magnitude
                    if Magnitude < ClosestRadius then
                        ClosestFrame = String[Index]:gsub("Items.", "")
                        ClosestRadius = Magnitude
                    end
                end 

                return ClosestFrame
            end 

            function Window:UpdateTabs(CurrentAlignment)
                if CurrentAlignment == "TopTabs" or CurrentAlignment == "BottomTabs" then
                    for Index, Value in Window.Pages do 
                        Value.Items.Inactive.Instance.Parent = Items[CurrentAlignment].Instance
                        Value.Items.Inactive.Instance.Size = UDim2New(0, 70, 0, 60)
                        Value.Items.Text.Instance.Position = UDim2New(0.5, 0, 1, -2)
                        Value.Items.Text.Instance.AnchorPoint = Vector2New(0.5, 1)
                        Value.Items.Icon.Instance.AnchorPoint = Vector2New(0.5, 0.5)
                        Value.Items.Gradient.Instance.Rotation = -90
                        
                        if Value.Active then 
                            Value.Items.Icon.Instance.Size = UDim2New(0, 32, 0, 32)
                            Value.Items.Icon.Instance.Position = UDim2New(0.5, 0, 0.5, 0)
                            Value.Items.Text.Instance.TextTransparency = 1
                        else
                            Value.Items.Icon.Instance.Size = UDim2New(0, 24, 0, 24)
                            Value.Items.Icon.Instance.Position = UDim2New(0.5, 0, 0.5, -8)
                            Value.Items.Text.Instance.TextTransparency = 0
                        end
                    end
                elseif CurrentAlignment == "LeftTabs" or CurrentAlignment == "RightTabs" then
                    for Index, Value in Window.Pages do
                        Value.Items.Inactive.Instance.Parent = Items[CurrentAlignment].Instance
                        Value.Items.Inactive.Instance.Size = UDim2New(0, 200, 0, 40)

                        Value.Items.Text.Instance.Position = UDim2New(45, 0, 0.5, 0)
                        Value.Items.Text.Instance.AnchorPoint = Vector2New(0, 0.5)

                        Value.Items.Icon.Instance.AnchorPoint = Vector2New(0, 0.5)
                        Value.Items.Icon.Instance.Position = UDim2New(16, 0, 0.5, 0)
                        Value.Items.Icon.Instance.Size = UDim2New(0, 18, 0, 18)

                        Value.Items.Gradient.Instance.Rotation = 0
                    end
                        
                end
            end

            function Window:UpdateFrameSide(OldFrame, NewFrame)
                OldFrame.Instance.Visible = false 
                NewFrame.Instance.Visible = true
                Window:UpdateTabs(Window.CurrentAlignment)
            end

            function Window:UpdateHighlight(CurrentFrame, Bool)
                if Bool then
                    CurrentFrame.Instance.Visible = false 
                    Items["PagePlaceholder"].Instance.Visible = true
                else
                    CurrentFrame.Instance.Visible = true 
                    Items["PagePlaceholder"].Instance.Visible = false
                end
            end

            for Index, Value in {"Left", "Top", "Bottom", "Right"} do 
                local TabDragging = false
                local TabItem = Items[Value.."Tabs"]
                local SelectedParent

                TabItem:Connect("InputBegan", function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 then 
                        TabItem.Instance.Parent = Library.Holder.Instance
                        Window:UpdateHighlight(TabItem, true)
                        Items["PagePlaceholder"]:Tween(nil, {BackgroundTransparency = 0.3})
                        TabDragging = true 
                    end
                end)

                TabItem:Connect("InputEnded", function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                        TabDragging = false

                        if SelectedParent then
                            Items["PagePlaceholder"]:Tween(nil, {BackgroundTransparency = 1})
                            Window:UpdateHighlight(TabItem, false)
                            Window:UpdateFrameSide(TabItem, Items[SelectedParent])
                            Window.CurrentAlignment = SelectedParent
                        end
                    end                    
                end)

                Library:Connect(UserInputService.InputChanged, function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseMovement and TabDragging then 
                        SelectedParent = Window:GetClosestFrame(Vector2New(Input.Position.X, Input.Position.Y - 36))
                        local TargetSize
                        local TargetPosition
                        local TargetAnchorPoint

                        if SelectedParent == "LeftTabs" then
                            TargetSize = UDim2New(0, 225, 1, 0)
                            TargetPosition = UDim2New(0, 0, 0, 0)
                            TargetAnchorPoint = Vector2New(1, 0)
                        elseif SelectedParent == "RightTabs" then
                            TargetSize = UDim2New(0, 225, 1, 0)
                            TargetPosition = UDim2New(1, 0, 0, 0)
                            TargetAnchorPoint = Vector2New(0, 0)
                        elseif SelectedParent == "TopTabs" then
                            TargetSize = UDim2New(1, 0, 0, 80)
                            TargetPosition = UDim2New(0, 0, 0, 0)
                            TargetAnchorPoint = Vector2New(0, 1)
                        elseif SelectedParent == "BottomTabs" then
                            TargetSize = UDim2New(1, 0, 0, 90)
                            TargetPosition = UDim2New(0, 0, 1, 0)
                            TargetAnchorPoint = Vector2New(0, 0)
                        end
                        
                        Items["PagePlaceholder"].Instance.AnchorPoint = TargetAnchorPoint
                        Items["PagePlaceholder"]:Tween(TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = TargetSize})
                        Items["PagePlaceholder"]:Tween(TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = TargetPosition})
                    end
                end)
            end
            --]]

            function Window:Init()
                -- 1) КОНФИГ ПЕРВЫМ: применяем сохранённое (размер/тема/тумблеры) ДО показа меню —
                --    никакого мелькания дефолтов при запуске
                local loadedNamed = false
                local loadedName = nil
                local autoSavePath = Library.Folders.Configs .. "/_autosave.json"
                pcall(function()
                    local autoLoadFile = Library.Folders.Configs .. "/autoload.txt"
                    if isfile(autoLoadFile) then
                        local success, content = pcall(readfile, autoLoadFile)
                        if success and content and isfile(content) then
                            Library:LoadConfig(readfile(content))
                            loadedNamed = true
                            loadedName = content:match("([^/\\]+)$")
                        end
                    end
                    if not loadedNamed and isfile(autoSavePath) then
                        Library:LoadConfig(readfile(autoSavePath))
                    end
                end)

                -- 2) твины элементов (как было)
                for __, Value in Window.Pages do
                    if Value.Active then
                        for _, Value2 in Value.Sections do
                            task.spawn(function()
                                Value2:TweenElements(true)
                                Library:RefreshConfigsList(ConfigsDropdown)
                            end)
                        end
                    end
                end

                -- 3) открываем меню УЖЕ НАСТРОЕННЫМ (в silent-режиме остаёмся скрытыми)
                if not Window._silentLoad then
                    task.defer(function() Window:SetOpen(true) end)
                end
                if loadedNamed and loadedName then
                    Library:Notification({
                        Title = "Config",
                        Description = "Auto loaded config: " .. loadedName,
                        Duration = 2
                    })
                end

                -- 4) АВТО-СЕЙВ СЕССИИ: всё, что настроил, само сохраняется в _autosave.json
                task.spawn(function()
                    if isfolder and not isfolder(Library.Folders.Configs) then pcall(makefolder, Library.Folders.Configs) end
                    local last = nil
                    while true do
                        task.wait(2)
                        pcall(function()   -- штампуем текущий размер окна → уходит в автосейв/конфиг
                            local ms = Items["MainFrame"].Instance.Size
                            Library.Flags["WindowSize"] = { math.floor(ms.X.Offset + 0.5), math.floor(ms.Y.Offset + 0.5) }
                        end)
                        local ok, enc = pcall(function() return Library:GetConfig() end)
                        if ok and type(enc) == "string" and enc ~= last and writefile then
                            pcall(writefile, autoSavePath, enc)
                            last = enc
                        end
                    end
                end)
            end

            Library:Connect(UserInputService.InputBegan, function(Input)
                local MenuBindData = Library.Flags.MenuBind
                local CurrentMenuKey = MenuBindData and MenuBindData.Key or Library.MenuKeybind
                if tostring(Input.KeyCode) == CurrentMenuKey or tostring(Input.UserInputType) == CurrentMenuKey then
                    Window:SetOpen(not Window.IsOpen)
                end
            end)

            -- Silent Load support + animated intro
            local SilentLoadStart = false
            pcall(function()
                local path = Library.Folders.Configs .. "/silentload.txt"
                if isfile and isfile(path) and readfile then
                    local ok, content = pcall(readfile, path)
                    if ok and content == "true" then
                        SilentLoadStart = true
                    end
                end
            end)
            Window._silentLoad = SilentLoadStart   -- читается в Window:Init (открывать ли меню после конфига)

            -- Center main frame before showing anything
            Window:SetCenter()

            -- Create animated intro (logo + title) when not in silent mode
            if not SilentLoadStart then
                local Intro = { }

                -- make sure main UI is hidden behind the intro
                Window.IsOpen = false
                Items["MainFrame"].Instance.Visible = false

                Intro["Holder"] = Instances:Create("Frame", {
                    Parent = Library.Holder.Instance,
                    Name = "\0",
                    -- soft off-white so it feels slightly blurred, not pure white
                    BackgroundColor3 = FromRGB(230, 230, 235),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    AnchorPoint = Vector2New(0.5, 0.5),
                    Position = UDim2New(0.5, 0, 0.5, 0),
                    -- absurdly large so it covers any screen (phone/pc)
                    Size = UDim2New(1, 999999, 1, 999999),
                    ZIndex = 50
                })

                Intro["Logo"] = Instances:Create("ImageLabel", {
                    Parent = Intro["Holder"].Instance,
                    Name = "\0",
                    Image = "rbxassetid://" .. Window.Logo,
                    BackgroundTransparency = 1,
                    AnchorPoint = Vector2New(0.5, 0.5),
                    Position = UDim2New(0.5, 0, 0.5, -16),
                    Size = UDim2New(0, 0, 0, 0),
                    ZIndex = 51
                })

                -- make logo circular
                Instances:Create("UICorner", {
                    Parent = Intro["Logo"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(1, 0)
                })

                Intro["Title"] = Instances:Create("TextLabel", {
                    Parent = Intro["Holder"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    Text = Window.Name,
                    TextColor3 = FromRGB(255, 255, 255),
                    TextTransparency = 1,
                    BackgroundTransparency = 1,
                    AnchorPoint = Vector2New(0.5, 0.5),
                    Position = UDim2New(0.5, 0, 0.5, 40),
                    TextSize = 20,
                    ZIndex = 51
                })

                Intro["SubTitle"] = Instances:Create("TextLabel", {
                    Parent = Intro["Holder"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    Text = Window.SubName or "",
                    TextColor3 = FromRGB(200, 200, 200),
                    TextTransparency = 1,
                    BackgroundTransparency = 1,
                    AnchorPoint = Vector2New(0.5, 0.5),
                    Position = UDim2New(0.5, 0, 0.5, 62),
                    TextSize = 16,
                    ZIndex = 51
                })

                -- ═══ прогресс-бар загрузки (стиль либки: тёмный трек + акцент-градиент) ═══
                Intro["BarTrack"] = Instances:Create("Frame", {
                    Parent = Intro["Holder"].Instance,
                    Name = "\0",
                    AnchorPoint = Vector2New(0.5, 0.5),
                    Position = UDim2New(0.5, 0, 0.5, 98),
                    Size = UDim2New(0, 230, 0, 6),
                    BackgroundColor3 = FromRGB(27, 25, 29),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    ZIndex = 51
                })
                Instances:Create("UICorner", { Parent = Intro["BarTrack"].Instance, Name = "\0", CornerRadius = UDimNew(1, 0) })

                Intro["BarFill"] = Instances:Create("Frame", {
                    Parent = Intro["BarTrack"].Instance,
                    Name = "\0",
                    Size = UDim2New(0, 0, 1, 0),
                    BackgroundColor3 = FromRGB(255, 255, 255),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    ZIndex = 52
                })
                Instances:Create("UICorner", { Parent = Intro["BarFill"].Instance, Name = "\0", CornerRadius = UDimNew(1, 0) })
                Instances:Create("UIGradient", {
                    Parent = Intro["BarFill"].Instance,
                    Name = "\0",
                    Rotation = -102,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(166, 166, 166))}
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                end})

                Intro["Percent"] = Instances:Create("TextLabel", {
                    Parent = Intro["Holder"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    Text = "0%",
                    TextColor3 = FromRGB(255, 255, 255),
                    TextTransparency = 1,
                    BackgroundTransparency = 1,
                    AnchorPoint = Vector2New(0.5, 0.5),
                    Position = UDim2New(0.5, 0, 0.5, 120),
                    TextSize = 15,
                    ZIndex = 51
                })

                Intro["Status"] = Instances:Create("TextLabel", {
                    Parent = Intro["Holder"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    Text = "Loading...",
                    TextColor3 = FromRGB(200, 200, 200),
                    TextTransparency = 1,
                    BackgroundTransparency = 1,
                    AnchorPoint = Vector2New(0.5, 0.5),
                    Position = UDim2New(0.5, 0, 0.5, 140),
                    TextSize = 13,
                    ZIndex = 51
                })

                -- quick fade-in + scale animation (runs while we wait)
                Intro["Holder"]:Tween(TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    -- fairly transparent so world is still visible, like a light blur
                    BackgroundTransparency = 0.85
                })

                Intro["Logo"]:Tween(TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                    Size = UDim2New(0, 82, 0, 82)
                })

                Intro["Title"]:Tween(TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    TextTransparency = 0
                })

                Intro["SubTitle"]:Tween(TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    TextTransparency = 0
                })

                -- проявляем прогресс-бар и подписи
                Intro["BarTrack"]:Tween(TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0.25 })
                Intro["BarFill"]:Tween(TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0 })
                Intro["Percent"]:Tween(TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 0.05 })
                Intro["Status"]:Tween(TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { TextTransparency = 0.3 })

                -- ═══ ЗАГРУЗКА 0→100%: проценты обновляются каждый кадр по ширине полосы ═══
                local IntroDone = false
                Library:Thread(function()
                    local RunSvc = game:GetService("RunService")
                    while not IntroDone do
                        RunSvc.RenderStepped:Wait()
                        pcall(function()
                            Intro["Percent"].Instance.Text = tostring(math.floor(Intro["BarFill"].Instance.Size.X.Scale * 100 + 0.5)) .. "%"
                        end)
                    end
                end)
                local function IntroStage(scale, text, time)
                    pcall(function() Intro["Status"].Instance.Text = text end)
                    Intro["BarFill"]:Tween(TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2New(scale, 0, 1, 0) })
                    task.wait(time + 0.05)
                end
                IntroStage(0.34, "Loading assets...", 0.45)
                IntroStage(0.71, "Building interface...", 0.55)
                IntroStage(1, "Finishing up...", 0.45)
                pcall(function() Intro["Status"].Instance.Text = "Done!" end)
                task.wait(0.25)
                IntroDone = true

                -- меню НЕ открываем здесь: его откроет Window:Init() ПОСЛЕ применения конфига
                -- (иначе при запуске мелькали дефолтные размер/настройки)

                -- fade out intro and clean
                Intro["Holder"]:Tween(TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                    BackgroundTransparency = 1
                })

                Intro["Title"]:Tween(TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                    TextTransparency = 1
                })

                Intro["SubTitle"]:Tween(TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                    TextTransparency = 1
                })

                Intro["Logo"]:Tween(TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                    Size = UDim2New(0, 0, 0, 0)
                })

                Intro["BarTrack"]:Tween(TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { BackgroundTransparency = 1 })
                Intro["BarFill"]:Tween(TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { BackgroundTransparency = 1 })
                Intro["Percent"]:Tween(TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1 })
                Intro["Status"]:Tween(TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { TextTransparency = 1 })

                task.wait(0.35)

                if Intro["Holder"] and Intro["Holder"].Clean then
                    Intro["Holder"]:Clean()
                end
            else
                -- Silent: start completely hidden, no intro
                Window.IsOpen = false
                Items["MainFrame"].Instance.Visible = false
            end
            return setmetatable(Window, Library)
        end

        Library.Watermark = function(self, Data)
            if not self or not self.Holder or not self.Holder.Instance or not self.Holder.Instance.Parent then return end
            if not self.WatermarkFrame then
                self.WatermarkFrame = Instances:Create("Frame", {
                    Parent = self.Holder.Instance,
                    Name = "Watermark",
                    AnchorPoint = Vector2New(0, 0),
                    Position = UDim2New(0, 15, 0, 15),
                    Size = UDim2New(0, 0, 0, 28), 
                    AutomaticSize = Enum.AutomaticSize.X, 
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(27, 25, 29),
                    ZIndex = 10,
                    Visible = false
                })
                self.WatermarkFrame:MakeDraggable()

                Instances:Create("UICorner", {
                    Parent = self.WatermarkFrame.Instance,
                    CornerRadius = UDimNew(0, 4)
                })
                
                Instances:Create("UIStroke", {
                    Parent = self.WatermarkFrame.Instance,
                    Color = FromRGB(0, 0, 0),
                    Thickness = 1,
                    Transparency = 0
                })
                local AccentLine = Instances:Create("Frame", {
                    Parent = self.WatermarkFrame.Instance,
                    Name = "Accent",
                    Size = UDim2New(1, 0, 0, 2),
                    Position = UDim2New(0, 0, 0, 0), 
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255),
                    ZIndex = 12
                })
                
                Instances:Create("UICorner", {
                    Parent = AccentLine.Instance,
                    CornerRadius = UDimNew(0, 4)
                })

                local Gradient = Instances:Create("UIGradient", {
                    Parent = AccentLine.Instance,
                    Color = RGBSequence{
                        RGBSequenceKeypoint(0, Library.Theme.Accent), 
                        RGBSequenceKeypoint(1, Library.Theme.AccentGradient)
                    }
                })
                
                Gradient:AddToTheme({
                    Color = function()
                        return RGBSequence{
                            RGBSequenceKeypoint(0, Library.Theme.Accent), 
                            RGBSequenceKeypoint(1, Library.Theme.AccentGradient)
                        }
                    end
                })

                local Content = Instances:Create("Frame", {
                    Parent = self.WatermarkFrame.Instance,
                    Name = "Content",
                    Size = UDim2New(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    ZIndex = 11
                })

                Instances:Create("UIListLayout", {
                    Parent = Content.Instance,
                    FillDirection = Enum.FillDirection.Horizontal,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    Padding = UDimNew(0, 6)
                })

                Instances:Create("UIPadding", {
                    Parent = Content.Instance,
                    PaddingLeft = UDimNew(0, 10),
                    PaddingRight = UDimNew(0, 10),
                    PaddingTop = UDimNew(0, 4) 
                })

                if self.ToClean then
                    table.insert(self.ToClean, self.WatermarkFrame.Instance)
                end
            end

            local ContentFrame = self.WatermarkFrame.Instance:FindFirstChild("Content")
            for Index, Value in ipairs(Data) do
                if Index > 1 then
                    local SepName = "Sep_" .. Index
                    local Sep = ContentFrame:FindFirstChild(SepName)
                    if not Sep then
                        Sep = Instances:Create("TextLabel", {
                            Parent = ContentFrame,
                            Name = SepName,
                            Text = "|",
                            TextColor3 = FromRGB(80, 80, 80),
                            FontFace = Library.Font,
                            TextSize = 14,
                            BackgroundTransparency = 1,
                            AutomaticSize = Enum.AutomaticSize.XY,
                            LayoutOrder = (Index * 2) - 1,
                            ZIndex = 11
                        }).Instance
                    end
                end

                local ItemName = "Item_" .. Index
                local ExistingItem = ContentFrame:FindFirstChild(ItemName)
                
                local Type = type(Value)
                local IsImage = (Type == "number" or (Type == "string" and string.find(Value, "rbxassetid")))

                if ExistingItem then
                    if IsImage and not ExistingItem:IsA("ImageLabel") then
                        ExistingItem:Destroy()
                        ExistingItem = nil
                    elseif not IsImage and not ExistingItem:IsA("TextLabel") then
                        ExistingItem:Destroy()
                        ExistingItem = nil
                    end
                end

                if not ExistingItem then
                    if IsImage then
                        ExistingItem = Instances:Create("ImageLabel", {
                            Parent = ContentFrame,
                            Name = ItemName,
                            BackgroundTransparency = 1,
                            Size = UDim2New(0, 14, 0, 14),
                            ImageColor3 = FromRGB(255, 255, 255),
                            LayoutOrder = Index * 2,
                            ZIndex = 11
                        }).Instance
                    else
                        ExistingItem = Instances:Create("TextLabel", {
                            Parent = ContentFrame,
                            Name = ItemName,
                            TextColor3 = FromRGB(240, 240, 240),
                            FontFace = Library.Font,
                            TextSize = 13,
                            BackgroundTransparency = 1,
                            AutomaticSize = Enum.AutomaticSize.XY,
                            LayoutOrder = Index * 2,
                            ZIndex = 11
                        }).Instance
                    end
                end

                if IsImage then
                    local ImageId = (Type == "number") and "rbxassetid://"..Value or Value
                    if ExistingItem.Image ~= ImageId then
                        ExistingItem.Image = ImageId
                    end
                else
                    local TextVal = tostring(Value)
                    if ExistingItem.Text ~= TextVal then
                        ExistingItem.Text = TextVal
                    end
                end
            end

            for _, Child in pairs(ContentFrame:GetChildren()) do
                if Child.Name:find("Item_") or Child.Name:find("Sep_") then
                    local _, IndexStr = Child.Name:match("(%a+)_(%d+)")
                    local Index = tonumber(IndexStr)
                    if Index and Index > #Data then
                        Child:Destroy()
                    end
                end
            end
        end

        Library.Category = function(self, Name)
            local Items = { } do 
                Items["Category"] = Instances:Create("TextLabel", {
                    Parent = self.Items["LeftTabs"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.4000000059604645,
                    Text = Name,
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(1, 0, 0, 15),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Category"]:AddToTheme({TextColor3 = "Text"})
            end                
        end

        Library.Page = function(self, Data)
            Data = Data or { }

            local Page = {
                Window = self,

                Name = Data.Name or Data.name or "Page",
                Icon = Data.Icon or Data.icon or "100050851789190",
                Columns = Data.Columns or Data.columns or 2,

                Items = { },
                ColumnsData = { },
                Sections = { },
                Active = false
            }

            local Items = { } do
                Items["Inactive"] = Instances:Create("TextButton", {
                    Parent = Page.Window.Items["LeftTabs"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2New(0, 200, 0, 40),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(124, 163, 255)
                })  Items["Inactive"]:AddToTheme({BackgroundColor3 = "Accent"})
                
                Instances:Create("UICorner", {
                    Parent = Items["Inactive"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 5)
                })
                
                Items.Gradient = Instances:Create("UIGradient", {
                    Parent = Items["Inactive"].Instance,
                    Name = "\0",
                    Transparency = NumSequence{NumSequenceKeypoint(0, 0.41874998807907104), NumSequenceKeypoint(0.445, 0.78125), NumSequenceKeypoint(0.751, 0.9375), NumSequenceKeypoint(1, 1)}
                })
                
                Items["Icon"] = Instances:Create("ImageLabel", {
                    Parent = Items["Inactive"].Instance,
                    Name = "\0",
                    ImageColor3 = FromRGB(255, 255, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 18, 0, 18),
                    AnchorPoint = Vector2New(0, 0.5),
                    Image = "rbxassetid://"..Page.Icon,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 16, 0.5, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  --Items["Icon"]:AddToTheme({ImageColor3 = "Accent"})

                Instances:Create("UIGradient", {
                    Parent = Items["Icon"].Instance,
                    Name = "\0",
                    Rotation = -115
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                end})
                
                Items["Text"] = Instances:Create("TextLabel", {
                    Parent = Items["Inactive"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = Page.Name,
                    AutomaticSize = Enum.AutomaticSize.X,
                    AnchorPoint = Vector2New(0, 0.5),
                    Size = UDim2New(0, 0, 0, 15),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 45, 0.5, 0),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Text"]:AddToTheme({TextColor3 = "Text"})      
                
                Items["Page"] = Instances:Create("Frame", {
                    Parent = Library.UnusedHolder.Instance,
                    Name = "\0",
                    Visible = false,
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 1, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    Position = UDim2New(0, 0, 0, 60),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Instances:Create("UIListLayout", {
                    Parent = Items["Page"].Instance,
                    Name = "\0",
                    FillDirection = Enum.FillDirection.Horizontal,
                    HorizontalFlex = Enum.UIFlexAlignment.Fill,
                    Padding = UDimNew(0, 10),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    VerticalFlex = Enum.UIFlexAlignment.Fill
                })
                
                Instances:Create("UIPadding", {
                    Parent = Items["Page"].Instance,
                    Name = "\0",
                    PaddingTop = UDimNew(0, 10),
                    PaddingBottom = UDimNew(0, 10),
                    PaddingRight = UDimNew(0, 10),
                    PaddingLeft = UDimNew(0, 10)
                })                

                for Index = 1, Page.Columns do 
                    local NewColumn = Instances:Create("ScrollingFrame", {
                        Parent = Items["Page"].Instance,
                        Name = "\0",
                        ScrollBarImageColor3 = FromRGB(0, 0, 0),
                        Active = true,
                        AutomaticCanvasSize = Enum.AutomaticSize.Y,
                        ScrollBarThickness = 0,
                        BorderColor3 = FromRGB(0, 0, 0),
                        BackgroundTransparency = 1,
                        Size = UDim2New(0, 100, 0, 100),
                        BackgroundColor3 = FromRGB(255, 255, 255),
                        ZIndex = 2,
                        BorderSizePixel = 0,
                        CanvasSize = UDim2New(0, 0, 0, 0)
                    })
                    
                    Instances:Create("UIListLayout", {
                        Parent = NewColumn.Instance,
                        Name = "\0",
                        Padding = UDimNew(0, 5),
                        SortOrder = Enum.SortOrder.LayoutOrder
                    })

                    Page.ColumnsData[Index] = NewColumn
                end

                Page.Items = Items
            end

            local Debounce = false

            function Page:Turn(Bool)
                if Debounce then 
                    return 
                end

                Page.Active = Bool 
                
                Debounce = true
                Items["Page"].Instance.Visible = Bool 
                Items["Page"].Instance.Parent = Bool and Page.Window.Items["Content"].Instance or Library.UnusedHolder.Instance

                local SlideTween
                if Page.Active then
                    Items["Inactive"]:Tween(nil, {BackgroundTransparency = 0.25})
                    SlideTween = Items["Page"]:Tween(TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0, 0)})

                    for Index, Value in Page.Sections do 
                        task.spawn(function()
                            -- Skip per-element task.wait() when switching pages.
                            -- This avoids CPU spikes on pages with many elements.
                            Value:TweenElements(true, true)
                        end)
                    end
                else
                    Items["Inactive"]:Tween(nil, {BackgroundTransparency = 1})
                    SlideTween = Items["Page"]:Tween(TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0, 60)})
                end

                -- PERFORMANCE FIX:
                -- The old code tweened transparency for every descendant instance on each page switch.
                -- That creates thousands of tweens and causes multi-second freezes.
                -- We only wait for the page slide tween to complete and then optionally tween section elements off.
                if SlideTween and SlideTween.Tween and SlideTween.Tween.Completed then
                    Library:Connect(SlideTween.Tween.Completed, function()
                        Debounce = false

                        if not Page.Active then
                            for Index, Value in Page.Sections do
                                task.spawn(function()
                                    Value:TweenElements(false, true)
                                end)
                            end
                        end
                    end)
                else
                    -- Fallback: release debounce after the slide duration
                    task.delay(0.55, function()
                        Debounce = false
                    end)
                end
            end

            Items["Inactive"]:Connect("MouseButton1Down", function()
                for Index, Value in Page.Window.Pages do 
                    if Value == Page and Page.Active then
                        return
                    end

                    Value:Turn(Value == Page)
                end
            end)

            if #Page.Window.Pages == 0 then 
                Page:Turn(true)
            end
            
            TableInsert(Page.Window.Pages, Page)
            return setmetatable(Page, Library.Pages)
        end

        Library.Pages.GlobalChat = function(self, Side)
            local GlobalChat = { }
            Library.GlobalChatt = GlobalChat

            local Items = { } do 
                Items["GlobalChat"] = Instances:Create("Frame", {
                    Parent = self.ColumnsData[Side].Instance,
                    Name = "\0",
                    BackgroundTransparency = 0.30000001192092896,
                    Position = UDim2New(0,0,0,0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 0, 1, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(27, 25, 29)
                })  Items["GlobalChat"]:AddToTheme({BackgroundColor3 = "Section Background 2"})

                Items["GlobalChat"]:MakeDraggable()
                
                Instances:Create("UICorner", {
                    Parent = Items["GlobalChat"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 6)
                })
                
                Items["Title"] = Instances:Create("TextLabel", {
                    Parent = Items["GlobalChat"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "GLOBAL CHAT",
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(0, 0, 0, 15),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 12, 0, 13),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    TextSize = 16,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Title"]:AddToTheme({TextColor3 = "Text"})
                
                Items["SubTitle"] = Instances:Create("TextLabel", {
                    Parent = Items["GlobalChat"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.4000000059604645,
                    Text = "Chat with other users here.",
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(0, 0, 0, 15),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 14, 0, 30),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["SubTitle"]:AddToTheme({TextColor3 = "Text"})
                
                Items["Message"] = Instances:Create("Frame", {
                    Parent = Items["GlobalChat"].Instance,
                    Name = "\0",
                    Active = true,
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0, 1),
                    Selectable = true,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 12, 1, -12),
                    Size = UDim2New(1, -66, 0, 32),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(27, 26, 29)
                })  Items["Message"]:AddToTheme({BackgroundColor3 = "Element"})
                
                Instances:Create("UICorner", {
                    Parent = Items["Message"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })
                
                Items["Background"] = Instances:Create("Frame", {
                    Parent = Items["Message"].Instance,
                    Name = "\0",
                    Active = true,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 0, 1, 0),
                    Selectable = true,
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(27, 26, 29)
                })  Items["Background"]:AddToTheme({BackgroundColor3 = "Element"})
                
                Instances:Create("UICorner", {
                    Parent = Items["Background"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })
                
                Items["Input"] = Instances:Create("TextBox", {
                    Parent = Items["Background"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    ZIndex = 2,
                    Size = UDim2New(1, -20, 0, 15),
                    Position = UDim2New(0, 10, 0, 8),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    PlaceholderColor3 = FromRGB(185, 185, 185),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    PlaceholderText = "Message...",
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Input"]:AddToTheme({TextColor3 = "Text"})
                
                Items["SendButton"] = Instances:Create("TextButton", {
                    Parent = Items["GlobalChat"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    AnchorPoint = Vector2New(1, 1),
                    Position = UDim2New(1, -12, 1, -12),
                    Size = UDim2New(0, 32, 0, 32),
                    BorderSizePixel = 0,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(27, 26, 29)
                })  Items["SendButton"]:AddToTheme({BackgroundColor3 = "Element"})
                
                Instances:Create("UICorner", {
                    Parent = Items["SendButton"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })
                
                Items["SendIcon"] = Instances:Create("ImageLabel", {
                    Parent = Items["SendButton"].Instance,
                    Name = "\0",
                    ImageColor3 = FromRGB(255, 255, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ImageTransparency = 0.2,
                    AnchorPoint = Vector2New(0.5, 0.5),
                    Image = "rbxassetid://101636617799068",
                    BackgroundTransparency = 1,
                    ZIndex = 3,
                    Position = UDim2New(0.5, 0, 0.5, 0),
                    Size = UDim2New(0, 22, 0, 22),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Items["Accent"] = Instances:Create("Frame", {
                    Parent = Items["SendButton"].Instance,
                    Name = "\0",
                    Size = UDim2New(0, 0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255),
                    AnchorPoint = Vector2New(0.5, 0.5),
                    Position = UDim2New(0.5, 0, 0.5, 0)
                })  --Items["Accent"]:AddToTheme({BackgroundColor3 = "Accent"})

                Instances:Create("UICorner", {
                    Parent = Items["Accent"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })

                Instances:Create("UIGradient", {
                    Parent = Items["Accent"].Instance,
                    Name = "\0",
                    Enabled = true,
                    Rotation = -115,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(143, 143, 143))}
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                end})

                Items["SendButton"]:OnHover(function()
                    Items["Accent"]:Tween(TweenInfo.new(Library.Tween.Time+0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2New(1, 0, 1, 0), BackgroundTransparency = 0})
                end)

                Items["SendButton"]:OnHoverLeave(function()
                    Items["Accent"]:Tween(TweenInfo.new(Library.Tween.Time+0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2New(0, 0, 0, 0), BackgroundTransparency = 1})
                end)
                
                Items["Messages"] = Instances:Create("ScrollingFrame", {
                    Parent = Items["GlobalChat"].Instance,
                    Name = "\0",
                    ScrollBarImageColor3 = FromRGB(124, 163, 255),
                    Active = true,
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    ScrollBarThickness = 2,
                    Size = UDim2New(1, -24, 1, -115),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 12, 0, 60),
                    BackgroundColor3 = FromRGB(255, 255, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    BorderSizePixel = 0,
                    CanvasSize = UDim2New(0, 0, 0, 0)
                })  Items["Messages"]:AddToTheme({ScrollBarImageColor3 = "Accent"})
                
                Instances:Create("UIListLayout", {
                    Parent = Items["Messages"].Instance,
                    Name = "\0",
                    Padding = UDimNew(0, 5),
                    SortOrder = Enum.SortOrder.LayoutOrder
                })

                Instances:Create("UIPadding", {
                    Parent = Items["Messages"].Instance,
                    Name = "\0",
                    PaddingTop = UDimNew(0, 0),
                    PaddingBottom = UDimNew(0, 0),
                    PaddingRight = UDimNew(0, 10),
                    PaddingLeft = UDimNew(0, 0)
                })

                Items["Status"] = Instances:Create("Frame", {
                    Parent = Items["GlobalChat"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(1, 0),
                    BackgroundTransparency = 1,
                    Position = UDim2New(1, -12, 0, 10),
                    Size = UDim2New(0, 100, 0, 20),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Items["StatusCircle"] = Instances:Create("Frame", {
                    Parent = Items["Status"].Instance,
                    Name = "\0",
                    AnchorPoint = Vector2New(1, 0.5),
                    Position = UDim2New(1, 0, 0.5, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 12, 0, 12),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 210, 62)
                })

                Items["Glow"] = Instances:Create("ImageLabel", {
                    Parent = Items["StatusCircle"].Instance,
                    Name = "\0",
                    ImageColor3 = FromRGB(255, 210, 62),
                    ScaleType = Enum.ScaleType.Slice,
                    ImageTransparency = 0.30000001192092896,
                    BorderColor3 = FromRGB(0, 0, 0),
                    BackgroundColor3 = FromRGB(255, 255, 255),
                    Size = UDim2New(1, 8, 1, 8),
                    AnchorPoint = Vector2New(0.5, 0.5),
                    Image = "http://www.roblox.com/asset/?id=18245826428",
                    BackgroundTransparency = 1,
                    Position = UDim2New(0.5, 0, 0.5, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    SliceCenter = RectNew(Vector2New(21, 21), Vector2New(79, 79))
                })
                
                Instances:Create("UICorner", {
                    Parent = Items["StatusCircle"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(1, 0)
                })
                
                Items["StatusText"] = Instances:Create("TextLabel", {
                    Parent = Items["Status"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(255, 210, 62),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "67 Active | Connected",
                    AnchorPoint = Vector2New(1, 0.5),
                    Size = UDim2New(0, 0, 0, 15),
                    BackgroundTransparency = 1,
                    Position = UDim2New(1, -20, 0.5, 0),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.X,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })                
            end

            function GlobalChat:SetVisibility(Bool)
                Items["GlobalChat"].Instance.Visible = Bool
                Items["GlobalChat"].Instance.Parent = Bool and Data.MainFrame.Instance or Library.UnusedHolder
            end

            function GlobalChat:SetStatus(Text, Color)
                Items["StatusText"].Instance.Text = Text
                Items["StatusText"].Instance.TextColor3 = Color
                Items["StatusCircle"].Instance.BackgroundColor3 = Color
            end

            function GlobalChat:SetStatusText(Text)
                if not Done then
                    Items["StatusText"].Instance.TextColor3 = FromRGB(62, 255, 91)
                    Items["Glow"].Instance.ImageColor3 = FromRGB(62, 255, 91)
                    Items["StatusCircle"].Instance.BackgroundColor3 = FromRGB(62, 255, 91)
                    Done = true
                end
                Items["StatusText"].Instance.Text = Text
            end

            local OnMessagePressed            

            function GlobalChat:OnMessageSendPressed(Func)
                OnMessagePressed = Func
            end

            function GlobalChat:GetTypedMessage()
                return Items["Input"].Instance.Text
            end

            function GlobalChat:ClearText()
                Items["Input"].Instance.Text = ""
            end

            function GlobalChat:SendMessage(Avatar, Username, Message, IsLocalPlayer)
                local SubItems = { } do
                    if not IsLocalPlayer then
                        SubItems["Message1"] = Instances:Create("Frame", {
                            Parent = Items["Messages"].Instance,
                            Name = "\0",
                            BackgroundTransparency = 1,
                            Size = UDim2New(1, 0, 0, 45),
                            ZIndex = 2,
                            BorderColor3 = FromRGB(0, 0, 0),
                            BorderSizePixel = 0,
                            AutomaticSize = Enum.AutomaticSize.Y,
                            BackgroundColor3 = FromRGB(255, 255, 255)
                        })

                        SubItems["PlayerName"] = Instances:Create("TextLabel", {
                            Parent = SubItems["Message1"].Instance,
                            Name = "\0",
                            FontFace = Library.Font,
                            TextColor3 = FromRGB(240, 240, 240),
                            BorderColor3 = FromRGB(0, 0, 0),
                            Text = Username,
                            Size = UDim2New(0, 0, 0, 15),
                            BackgroundTransparency = 1,
                            RichText = true,
                            Position = UDim2New(0, 38, 0, 0),
                            TextTransparency = 0.3,
                            BorderSizePixel = 0,
                            ZIndex = 2,
                            AutomaticSize = Enum.AutomaticSize.X,
                            TextSize = 14,
                            BackgroundColor3 = FromRGB(255, 255, 255)
                        })  SubItems["PlayerName"]:AddToTheme({TextColor3 = "Text"})

                        SubItems["RealMessage"] = Instances:Create("Frame", {
                            Parent = SubItems["Message1"].Instance,
                            Name = "\0",
                            Position = UDim2New(0, 38, 0, 20),
                            BorderColor3 = FromRGB(0, 0, 0),
                            BorderSizePixel = 0,
                            ZIndex = 2,
                            AutomaticSize = Enum.AutomaticSize.XY,
                            BackgroundColor3 = FromRGB(27, 25, 29)
                        })  SubItems["RealMessage"]:AddToTheme({BackgroundColor3 = "Background"})

                        Instances:Create("UISizeConstraint", {
                            Parent = SubItems["RealMessage"].Instance,
                            Name = "\0",
                            MaxSize = Vector2New(370, 70)
                        })

                        Instances:Create("UICorner", {
                            Parent = SubItems["RealMessage"].Instance,
                            Name = "\0",
                            CornerRadius = UDimNew(0, 4)
                        })

                        SubItems["MessageText"] = Instances:Create("TextLabel", {
                            Parent = SubItems["RealMessage"].Instance,
                            Name = "\0",
                            FontFace = Library.Font,
                            TextColor3 = FromRGB(240, 240, 240),
                            BorderColor3 = FromRGB(0, 0, 0),
                            Text = Message,
                            BackgroundTransparency = 1,
                            TextWrapped = true,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            BorderSizePixel = 0,
                            AutomaticSize = Enum.AutomaticSize.XY,
                            TextSize = 14,
                            ZIndex = 2,
                            BackgroundColor3 = FromRGB(255, 255, 255)
                        })  SubItems["MessageText"]:AddToTheme({TextColor3 = "Text"})

                        Instances:Create("UIPadding", {
                            Parent = SubItems["RealMessage"].Instance,
                            Name = "\0",
                            PaddingTop = UDimNew(0, 10),
                            PaddingBottom = UDimNew(0, 10),
                            PaddingRight = UDimNew(0, 10),
                            PaddingLeft = UDimNew(0, 10)
                        })

                        SubItems["Avatar"] = Instances:Create("ImageLabel", {
                            Parent = SubItems["Message1"].Instance,
                            Name = "\0",
                            BorderColor3 = FromRGB(0, 0, 0),
                            AnchorPoint = Vector2New(0, 0.5),
                            Image = Avatar,
                            BackgroundTransparency = 1,
                            Position = UDim2New(0, 0, 0.5, 0),
                            Size = UDim2New(0, 30, 0, 30),
                            ZIndex = 2,
                            BorderSizePixel = 0,
                            BackgroundColor3 = FromRGB(255, 255, 255)
                        })

                        Instances:Create("UICorner", {
                            Parent = SubItems["Avatar"].Instance,
                            Name = "\0",
                            CornerRadius = UDimNew(0, 4)
                        })
                    else
                        SubItems["Message1"] = Instances:Create("Frame", {
                            Parent = Items["Messages"].Instance,
                            Name = "\0",
                            BackgroundTransparency = 1,
                            Size = UDim2New(1, 0, 0, 45),
                            BorderColor3 = FromRGB(0, 0, 0),
                            BorderSizePixel = 0,
                            ZIndex = 2,
                            AutomaticSize = Enum.AutomaticSize.Y,
                            BackgroundColor3 = FromRGB(255, 255, 255)
                        })

                        SubItems["PlayerName"] = Instances:Create("TextLabel", {
                            Parent = SubItems["Message1"].Instance,
                            Name = "\0",
                            FontFace = Library.Font,
                            TextColor3 = FromRGB(240, 240, 240),
                            BorderColor3 = FromRGB(0, 0, 0),
                            Text = Username,
                            RichText = true,
                            AnchorPoint = Vector2New(1, 0),
                            Size = UDim2New(0, 0, 0, 15),
                            ZIndex = 2,
                            TextTransparency = 0.3,
                            BackgroundTransparency = 1,
                            Position = UDim2New(1, -38, 0, 0),
                            BorderSizePixel = 0,
                            AutomaticSize = Enum.AutomaticSize.X,
                            TextSize = 14,
                            BackgroundColor3 = FromRGB(255, 255, 255)
                        })  SubItems["PlayerName"]:AddToTheme({TextColor3 = "Text"})

                        SubItems["RealMessage"] = Instances:Create("Frame", {
                            Parent = SubItems["Message1"].Instance,
                            Name = "\0",
                            AnchorPoint = Vector2New(1, 0),
                            Position = UDim2New(1, -38, 0, 20),
                            BorderColor3 = FromRGB(0, 0, 0),
                            BorderSizePixel = 0,
                            ZIndex = 2,
                            AutomaticSize = Enum.AutomaticSize.XY,
                            BackgroundColor3 = FromRGB(27, 25, 29)
                        })  SubItems["RealMessage"]:AddToTheme({BackgroundColor3 = "Background"})

                        Instances:Create("UISizeConstraint", {
                            Parent = SubItems["RealMessage"].Instance,
                            Name = "\0",
                            MaxSize = Vector2New(370, 75)
                        })

                        Instances:Create("UICorner", {
                            Parent = SubItems["RealMessage"].Instance,
                            Name = "\0",
                            CornerRadius = UDimNew(0, 4)
                        })

                        SubItems["MessageText"] = Instances:Create("TextLabel", {
                            Parent = SubItems["RealMessage"].Instance,
                            Name = "\0",
                            FontFace = Library.Font,
                            TextColor3 = FromRGB(240, 240, 240),
                            BorderColor3 = FromRGB(0, 0, 0),
                            Text = Message,
                            BackgroundTransparency = 1,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            BorderSizePixel = 0,
                            AutomaticSize = Enum.AutomaticSize.XY,
                            ZIndex = 2,
                            TextWrapped = true,
                            TextSize = 14,
                            BackgroundColor3 = FromRGB(255, 255, 255)
                        })  SubItems["MessageText"]:AddToTheme({TextColor3 = "Text"})

                        Instances:Create("UIPadding", {
                            Parent = SubItems["RealMessage"].Instance,
                            Name = "\0",
                            PaddingTop = UDimNew(0, 10),
                            PaddingBottom = UDimNew(0, 10),
                            PaddingRight = UDimNew(0, 10),
                            PaddingLeft = UDimNew(0, 10)
                        })

                        SubItems["Avatar"] = Instances:Create("ImageLabel", {
                            Parent = SubItems["Message1"].Instance,
                            Name = "\0",
                            BorderColor3 = FromRGB(0, 0, 0),
                            AnchorPoint = Vector2New(1, 0.5),
                            Image = Avatar,
                            ZIndex = 2,
                            BackgroundTransparency = 1,
                            Position = UDim2New(1, 0, 0.5, 0),
                            Size = UDim2New(0, 30, 0, 30),
                            BorderSizePixel = 0,
                            BackgroundColor3 = FromRGB(255, 255, 255)
                        })

                        Instances:Create("UICorner", {
                            Parent = SubItems["Avatar"].Instance,
                            Name = "\0",
                            CornerRadius = UDimNew(0, 4)
                        })
                    end
                end
            end

            Items["SendButton"]:Connect("MouseButton1Down", function()
                if GlobalChat:GetTypedMessage() == "" then
                    return
                end
                
                OnMessagePressed()
            end)

            Items["Messages"]:Connect("ChildAdded", function()
                task.wait()
                Items["Messages"]:Tween(nil, {CanvasPosition = Vector2New(0, Items["Messages"].Instance.AbsoluteCanvasSize.Y - Items["Messages"].Instance.AbsoluteSize.Y)})
            end)

            for Index, Value in Items["GlobalChat"].Instance:GetDescendants() do 
                if Value.ClassName:find("UI") then 
                    continue 
                end

                Value.ZIndex = 2
            end

            Items["GlobalChat"].Instance.ZIndex = 2
            Items["SendIcon"].Instance.ZIndex = 3

            return GlobalChat 
        end

        Library.Pages.Section = function(self, Data)
            Data = Data or { }

            local Section = {
                Window = self.Window,
                Page = self,

                Name = Data.Name or Data.name or "Section",
                Description = Data.Description or Data.Description or "",
                Icon = Data.Icon or Data.icon or "123944728972740",
                Side = Data.Side or Data.side or 1,
                EnableToggle = Data.EnableToggle or Data.enabletoggle or false,

                Items = { },
                IsActive = true,
                Elements = { }
            }

            local Items = { } do
                Items["Section"] = Instances:Create("Frame", {
                    Parent = Section.Page.ColumnsData[Section.Side].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    BackgroundTransparency = 0.6499999761581421,
                    ClipsDescendants = true,
                    BorderSizePixel = 0,
                    Size = UDim2New(1, 0, 0, 45),
                    ZIndex = 2,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundColor3 = FromRGB(29, 28, 32)
                })  Items["Section"]:AddToTheme({BackgroundColor3 = "Section Background 2"})
                
                Items["Top"] = Instances:Create("Frame", {
                    Parent = Items["Section"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 0.6499999761581421,
                    Size = UDim2New(1, 0, 0, 55),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(31, 31, 36)
                })  Items["Top"]:AddToTheme({BackgroundColor3 = "Outline"})
                
                Items["TopBackground"] = Instances:Create("Frame", {
                    Parent = Items["Top"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    BackgroundTransparency = 0.6499999761581421,
                    Position = UDim2New(0, 1, 0, 1),
                    Size = UDim2New(1, -2, 1, -2),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(26, 26, 30)
                })  Items["TopBackground"]:AddToTheme({BackgroundColor3 = "Section Top"})
                
                Items["Icon"] = Instances:Create("ImageLabel", {
                    Parent = Items["TopBackground"].Instance,
                    Name = "\0",
                    ImageColor3 = FromRGB(255, 255, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 21, 0, 20),
                    AnchorPoint = Vector2New(0, 0.5),
                    Image = "rbxassetid://"..Section.Icon,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 15, 0.5, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Instances:Create("UIGradient", {
                    Parent = Items["Icon"].Instance,
                    Name = "\0",
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(131, 131, 131)), RGBSequenceKeypoint(1, FromRGB(255, 255, 255))}
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                end})
                
                Items["Description"] = Instances:Create("TextLabel", {
                    Parent = Items["TopBackground"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(183, 183, 183),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = Section.Description,
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(0, 0, 0, 15),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 50, 0, 28),
                    BorderSizePixel = 0,
                    TextTransparency = 0.4,
                    ZIndex = 2,
                    TextSize = 15,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Description"]:AddToTheme({TextColor3 = "Text"})
                
                Instances:Create("UICorner", {
                    Parent = Items["TopBackground"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })
                
                Items["Title"] = Instances:Create("TextLabel", {
                    Parent = Items["TopBackground"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(248, 248, 248),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = Section.Name,
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(0, 0, 0, 15),
                    BackgroundTransparency = 1,
                    -- Сохранил твою логику центрирования из прошлого вопроса
                    Position = (Section.Description == "") and UDim2New(0, 50, 0, 19) or UDim2New(0, 50, 0, 10),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    TextSize = 15,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Title"]:AddToTheme({TextColor3 = "Text"})
                
                Items["Toggle"] = Instances:Create("TextButton", {
                    Parent = Items["Top"].Instance,
                    Name = "\0",
                    Active = false,
                    -- ДОБАВЛЕНО: Видимость зависит от параметра EnableToggle
                    Visible = Section.EnableToggle,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    AnchorPoint = Vector2New(1, 0.5),
                    Selectable = false,
                    Position = UDim2New(1, -15, 0.5, 0),
                    Size = UDim2New(0, 26, 0, 16),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Items["Circle"] = Instances:Create("Frame", {
                    Parent = Items["Toggle"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(1, 0.5),
                    Position = UDim2New(1, -4, 0.5, 0),
                    Size = UDim2New(0, 8, 0, 8),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Circle"]:AddToTheme({BackgroundColor3 = "Text"})
                
                Instances:Create("UICorner", {
                    Parent = Items["Circle"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 99999)
                })
                
                Instances:Create("UICorner", {
                    Parent = Items["Toggle"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 9)
                })
                
                Items["Gradient"] = Instances:Create("UIGradient", {
                    Parent = Items["Toggle"].Instance,
                    Name = "\0",
                    Rotation = -115,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(143, 143, 143))}
                })  Items["Gradient"]:AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                end})
                
                Instances:Create("UICorner", {
                    Parent = Items["Top"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })
                
                Items["Fill"] = Instances:Create("Frame", {
                    Parent = Items["Top"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 1, 1, -4),
                    Size = UDim2New(1, -2, 0, 4),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(26, 26, 30)
                })  Items["Fill"]:AddToTheme({BackgroundColor3 = "Section Background"})
                
                Instances:Create("UICorner", {
                    Parent = Items["Fill"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })
                
                Items["TopFills"] = Instances:Create("Frame", {
                    Parent = Items["Top"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0, 1),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 0, 1, 0),
                    Size = UDim2New(1, 0, 0, 3),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  
                
                Items["Right1"] = Instances:Create("Frame", {
                    Parent = Items["TopFills"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(1, 0),
                    BackgroundTransparency = 0.6499999761581421,
                    Position = UDim2New(1, -1, 0, 0),
                    Size = UDim2New(0, 1, 0, 1),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(26, 26, 30)
                })  Items["Right1"]:AddToTheme({BackgroundColor3 = "Section Background"})
                
                Items["Right2"] = Instances:Create("Frame", {
                    Parent = Items["TopFills"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(1, 0),
                    BackgroundTransparency = 0.6499999761581421,
                    Position = UDim2New(1, -1, 0, 1),
                    Size = UDim2New(0, 1, 0, 1),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(26, 26, 30)
                })  Items["Right2"]:AddToTheme({BackgroundColor3 = "Section Background"})
                
                Items["Right3"] = Instances:Create("Frame", {
                    Parent = Items["TopFills"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(1, 0),
                    BackgroundTransparency = 0.6499999761581421,
                    Position = UDim2New(1, -2, 0, 1),
                    Size = UDim2New(0, 1, 0, 1),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(26, 26, 30)
                })  Items["Right3"]:AddToTheme({BackgroundColor3 = "Section Background"})
                
                Items["Left1"] = Instances:Create("Frame", {
                    Parent = Items["TopFills"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(1, 0),
                    BackgroundTransparency = 0.6499999761581421,
                    Position = UDim2New(0, 2, 0, 0),
                    Size = UDim2New(0, 1, 0, 1),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(26, 26, 30)
                })  Items["Left1"]:AddToTheme({BackgroundColor3 = "Section Background"})
                
                Items["Left2"] = Instances:Create("Frame", {
                    Parent = Items["TopFills"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(1, 0),
                    BackgroundTransparency = 0.6499999761581421,
                    Position = UDim2New(0, 2, 0, 1),
                    Size = UDim2New(0, 1, 0, 1),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(26, 26, 30)
                })  Items["Left2"]:AddToTheme({BackgroundColor3 = "Section Background"})
                
                Items["Left3"] = Instances:Create("Frame", {
                    Parent = Items["TopFills"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(1, 0),
                    BackgroundTransparency = 0.6499999761581421,
                    Position = UDim2New(0, 3, 0, 1),
                    Size = UDim2New(0, 1, 0, 1),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(26, 26, 30)
                })  Items["Left3"]:AddToTheme({BackgroundColor3 = "Section Background"})
                
                Instances:Create("UICorner", {
                    Parent = Items["Section"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })
                
                Items["Background"] = Instances:Create("Frame", {
                    Parent = Items["Section"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    BackgroundTransparency = 0.6499999761581421,
                    Position = UDim2New(0, 1, 0, 55),
                    Size = UDim2New(1, -2, 1, -56),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(24, 22, 25)
                })  Items["Background"]:AddToTheme({BackgroundColor3 = "Section Background"})
                
                Items["Content"] = Instances:Create("Frame", {
                    Parent = Items["Background"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 12, 0, 15),
                    Size = UDim2New(1, -24, 0, 0),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Instances:Create("UIListLayout", {
                    Parent = Items["Content"].Instance,
                    Name = "\0",
                    Padding = UDimNew(0, 5),
                    SortOrder = Enum.SortOrder.LayoutOrder
                })                

                Items["Fade"] = Instances:Create("TextButton", {
                    Parent = Items["Background"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Size = UDim2New(0, 0, 10, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    AutoButtonColor = false,
                    Visible = false,
                    Text = "",
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(24, 22, 25)
                })  Items["Fade"]:AddToTheme({BackgroundColor3 = "Section Background"})
                
                Instances:Create("UICorner", {
                    Parent = Items["Fade"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })                

                Instances:Create("UIPadding", {
                    Parent = Items["Content"].Instance,
                    Name = "\0",
                    PaddingBottom = UDimNew(0, 10)
                })

                Section.Items = Items
            end

            function Section:ToggleBackground()
                Section.IsActive = not Section.IsActive

                if not Section.IsActive then 
                    Items["Fade"].Instance.Visible = true
                    Items["Fade"]:Tween(nil, {BackgroundTransparency = 0.3})
    
                    Items["Gradient"].Instance.Enabled = false
                    Items["Toggle"]:ChangeItemTheme({BackgroundColor3 = "Element"})
                    Items["Toggle"]:Tween(nil, {BackgroundColor3 = Library.Theme.Element})
                    Items["Circle"]:Tween(nil, {AnchorPoint = Vector2New(0, 0.5), Position = UDim2New(0, 4, 0.5, 0), BackgroundColor3 = Library.Theme.Text, BackgroundTransparency = 0.6})
                else
                    Items["Fade"]:Tween(nil, {BackgroundTransparency = 1})
                    task.spawn(function() 
                        task.wait(Library.Tween.Time)
                        Items["Fade"].Instance.Visible = false
                    end)

                    Items["Gradient"].Instance.Enabled = true
                    Items["Toggle"]:ChangeItemTheme({BackgroundColor3 = "Text"})
                    Items["Toggle"]:Tween(nil, {BackgroundColor3 = Library.Theme.Text})
                    Items["Circle"]:Tween(nil, {AnchorPoint = Vector2New(1, 0.5), Position = UDim2New(1, -4, 0.5, 0), BackgroundColor3 = Library.Theme.Text, BackgroundTransparency = 0})
                end
            end

            Library:Connect(Items["Content"].Instance.Changed, function(Property)
                if Property == "AbsoluteSize" then
                    Items["Fade"].Instance.Size = UDim2New(1, 0, 0, Items["Content"].Instance.AbsoluteSize.Y + 10)
                end
            end)

            function Section:TweenElements(Bool, Debounce)
                for Index, Value in Section.Elements do
                    if type(Value.RefreshPosition) == "function" then
                        Value:RefreshPosition(Bool)
                    end
                    if not Debounce then 
                        task.wait(0.03)
                    end
                end
            end

            Items["Toggle"]:Connect("MouseButton1Down", function()
                Section:ToggleBackground()
            end)

            Section.Page.Sections[Section.Name] = Section

            return setmetatable(Section, Library.Sections)
        end

        Library.Sections.Toggle = function(self, Data)
            Data = Data or { }
            
            local Toggle = {
                Window = self.Window,
                Page = self.Page,
                Section = self,

                Name = Data.Name or Data.name or "Toggle",
                Flag = Data.Flag or Data.flag or Library:NextFlag(),
                Default = Data.Default or Data.default or false,
                Callback = Data.Callback or Data.callback or function() end,

                Value = false
            }

            local Items = { } do 
                Items["Toggle"] = Instances:Create("TextButton", {
                    Parent = Toggle.Section.Items["Content"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2New(1, 0, 0, 18),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Items["Indicator"] = Instances:Create("Frame", {
                    Parent = Items["Toggle"].Instance,
                    Name = "\0",
                    Size = UDim2New(0, 18, 0, 18),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(124, 163, 255)
                })  Items["Indicator"]:AddToTheme({BackgroundColor3 = "Element"})

                Instances:Create("UICorner", {
                    Parent = Items["Indicator"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 3)
                })
                
                Items["Accent"] = Instances:Create("Frame", {
                    Parent = Items["Indicator"].Instance,
                    Name = "\0",
                    Size = UDim2New(0, 0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255),
                    AnchorPoint = Vector2New(0.5, 0.5),
                    Position = UDim2New(0.5, 0, 0.5, 0)
                })  --Items["Accent"]:AddToTheme({BackgroundColor3 = "Accent"})

                Instances:Create("UICorner", {
                    Parent = Items["Accent"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 3)
                })

                Items["CheckImage"] = Instances:Create("ImageLabel", {
                    Parent = Items["Accent"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 0, 0, 0),
                    AnchorPoint = Vector2New(0.5, 0.5),
                    Image = "rbxassetid://121760666525660",
                    BackgroundTransparency = 1,
                    Position = UDim2New(0.5, 0, 0.5, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    ImageTransparency = 1,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["CheckImage"]:AddToTheme({ImageColor3 = "Text"})
                
                Items["Text"] = Instances:Create("TextLabel", {
                    Parent = Items["Toggle"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.30000001192092896,
                    Text = Toggle.Name,
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(0, 0, 0, 15),
                    Position = UDim2New(0, 24, 0, 0),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Text"]:AddToTheme({TextColor3 = "Text"})

                Items["Gradient"] = Instances:Create("UIGradient", {
                    Parent = Items["Accent"].Instance,
                    Name = "\0",
                    Enabled = true,
                    Rotation = -115,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(143, 143, 143))}
                })  Items["Gradient"]:AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                end})

                Items["Toggle"]:OnHover(function()
                    Items["Indicator"]:Tween(TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2New(0, 21, 0, 21), Position = UDim2New(0, -3, 0, -3)})
                end)

                Items["Toggle"]:OnHoverLeave(function()
                    Items["Indicator"]:Tween(TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2New(0, 18, 0, 18), Position = UDim2New(0, 0, 0, 0)})
                end)
            end

                Items["Indicator"].Instance.Position = UDim2New(0, 60, 0, 0)
            Items["Text"].Instance.Position = UDim2New(0, 84, 0, 0)

            --Toggle.Section.Items["Fade"].Instance.Size = UDim2New(1, 0, 0, Toggle.Section.Items["Content"].Instance.AbsoluteSize.X - 180)

            Toggle.SubColorpickerCount = 0
            local function GetRightContainer()
                if not Items["RightContainer"] then
                    Items["RightContainer"] = Instances:Create("Frame", {
                        Parent = Items["Toggle"].Instance,
                        Name = "\0",
                        AnchorPoint = Vector2New(1, 0.5),
                        Position = UDim2New(1, -10, 0.5, 0),
                        Size = UDim2New(0, 0, 0, 18),
                        AutomaticSize = Enum.AutomaticSize.X,
                        BorderSizePixel = 0,
                        BackgroundTransparency = 1
                    })
                    Instances:Create("UIListLayout", {
                        Parent = Items["RightContainer"].Instance,
                        Name = "\0",
                        FillDirection = Enum.FillDirection.Horizontal,
                        HorizontalAlignment = Enum.HorizontalAlignment.Right,
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                        Padding = UDimNew(0, 6),
                        SortOrder = Enum.SortOrder.LayoutOrder
                    })
                    Instances:Create("UIPadding", {
                        Parent = Items["RightContainer"].Instance,
                        Name = "\0",
                        PaddingRight = UDimNew(0, 4),
                        PaddingLeft = UDimNew(0, 4)
                    })
                end
                return Items["RightContainer"]
            end

            function Toggle:SubKeybind(Data)
                Data = Data or { }
                local SubKeybind = {
                    Flag = Data.Flag or Data.flag or Library:NextFlag(),
                    Default = Data.Default or Data.default or Enum.KeyCode.RightShift,
                    DefaultMode = Data.Mode or Data.mode or Data.DefaultMode or Data.defaultMode or "Toggle",
                    Key = "",
                    Value = "None",
                    Mode = "Toggle",
                    ToggleRef = Toggle,
                    Picking = false,
                    ModeMenuOpen = false
                }
                SubKeybind.Mode = SubKeybind.DefaultMode
                local SubKeybindItems = { }
                local KeyListItem
                if Library.KeyList then KeyListItem = Library.KeyList:Add(Toggle.Name, "None") end
                local function UpdateKeyList()
                    if KeyListItem then
                        KeyListItem:Set(Toggle.Name, SubKeybind.Value)
                        KeyListItem:SetStatus(Toggle.Value)
                    end
                end
                local RightContainer = GetRightContainer()
                SubKeybindItems["Container"] = Instances:Create("Frame", {
                    Parent = RightContainer.Instance,
                    Name = "\0",
                    Size = UDim2New(0, 55, 0, 16),
                    LayoutOrder = 999,
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(27, 26, 29)
                })  SubKeybindItems["Container"]:AddToTheme({BackgroundColor3 = "Element"})
                Instances:Create("UICorner", { Parent = SubKeybindItems["Container"].Instance, Name = "\0", CornerRadius = UDimNew(0, 4) })
                SubKeybindItems["KeyButton"] = Instances:Create("TextButton", {
                    Parent = SubKeybindItems["Container"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.30000001192092896,
                    Text = "None",
                    AutoButtonColor = false,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    TextSize = 12,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  SubKeybindItems["KeyButton"]:AddToTheme({TextColor3 = "Text"})
                local ModeMenuFrame = Instances:Create("Frame", {
                    Parent = Library.UnusedHolder.Instance,
                    Name = "\0",
                    Visible = false,
                    ClipsDescendants = false,
                    Size = UDim2New(0, 55, 0, 44),
                    Position = UDim2New(0, 0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 500,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(27, 26, 29)
                })  ModeMenuFrame:AddToTheme({BackgroundColor3 = "Element"})
                Instances:Create("UICorner", { Parent = ModeMenuFrame.Instance, Name = "\0", CornerRadius = UDimNew(0, 4) })
                Instances:Create("UIListLayout", {
                    Parent = ModeMenuFrame.Instance,
                    Name = "\0",
                    Padding = UDimNew(0, 2),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    VerticalAlignment = Enum.VerticalAlignment.Top
                })
                Instances:Create("UIPadding", {
                    Parent = ModeMenuFrame.Instance,
                    Name = "\0",
                    PaddingTop = UDimNew(0, 3),
                    PaddingBottom = UDimNew(0, 3),
                    PaddingLeft = UDimNew(0, 4),
                    PaddingRight = UDimNew(0, 4)
                })
                local TweenInfoHover = TweenInfo.new(Library.Tween.Time + 0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
                local AccentColor = Library.Theme.Accent or FromRGB(255, 80, 80)
                local function CreateModeOption(Name, IsSelected)
                    local Row = Instances:Create("TextButton", {
                        Parent = ModeMenuFrame.Instance,
                        Name = "\0",
                        FontFace = Library.Font,
                        TextColor3 = IsSelected and FromRGB(240, 240, 240) or FromRGB(160, 160, 165),
                        Text = "",
                        AutoButtonColor = false,
                        Size = UDim2New(1, -8, 0, 16),
                        BorderSizePixel = 0,
                        ZIndex = 501,
                        TextSize = 12,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        BackgroundColor3 = FromRGB(0, 0, 0),
                        BackgroundTransparency = 1
                    })
                    Row.Instance.LayoutOrder = Name == "Toggle" and 0 or 1
                    local CircleContainer = Instances:Create("Frame", {
                        Parent = Row.Instance,
                        Name = "\0",
                        Size = UDim2New(0, 14, 0, 16),
                        Position = UDim2New(0, 0, 0, 0),
                        BorderSizePixel = 0,
                        BackgroundTransparency = 1
                    })
                    local Circle = Instances:Create("Frame", {
                        Parent = CircleContainer.Instance,
                        Name = "\0",
                        Size = UDim2New(0, 5, 0, 5),
                        AnchorPoint = Vector2New(0.5, 0.5),
                        Position = UDim2New(0.5, 0, 0.5, 0),
                        BorderColor3 = FromRGB(0, 0, 0),
                        ZIndex = 502,
                        BorderSizePixel = 0,
                        BackgroundColor3 = AccentColor,
                        BackgroundTransparency = IsSelected and 0 or 1
                    })
                    Instances:Create("UICorner", { Parent = Circle.Instance, Name = "\0", CornerRadius = UDimNew(1, 0) })
                    local CircleStroke = Instances:Create("UIStroke", {
                        Parent = Circle.Instance,
                        Name = "\0",
                        Color = AccentColor,
                        Thickness = 1,
                        Transparency = IsSelected and 1 or 0
                    })
                    local Label = Instances:Create("TextLabel", {
                        Parent = Row.Instance,
                        Name = "\0",
                        FontFace = Library.Font,
                        TextColor3 = IsSelected and FromRGB(240, 240, 240) or FromRGB(160, 160, 165),
                        Text = Name,
                        Size = UDim2New(1, -18, 0, 16),
                        Position = UDim2New(0, 14, 0, 0),
                        BackgroundTransparency = 1,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextSize = 12,
                        ZIndex = 502
                    })
                    Row:OnHover(function()
                        Label:Tween(TweenInfoHover, {TextColor3 = FromRGB(255, 255, 255)})
                    end)
                    Row:OnHoverLeave(function()
                        local active = (Name == "Toggle" and SubKeybind.Mode == "Toggle") or (Name == "Hold" and SubKeybind.Mode == "Hold")
                        Label:Tween(TweenInfoHover, {TextColor3 = active and FromRGB(240, 240, 240) or FromRGB(160, 160, 165)})
                    end)
                    return { Row = Row, Circle = Circle, CircleStroke = CircleStroke, Label = Label }
                end
                local MenuToggle = CreateModeOption("Toggle", SubKeybind.Mode == "Toggle")
                local MenuHold = CreateModeOption("Hold", SubKeybind.Mode == "Hold")
                local function UpdateModeVisuals()
                    local toggleSel = SubKeybind.Mode == "Toggle"
                    local holdSel = SubKeybind.Mode == "Hold"
                    MenuToggle.Circle.Instance.BackgroundTransparency = toggleSel and 0 or 1
                    MenuToggle.CircleStroke.Instance.Transparency = toggleSel and 1 or 0
                    MenuToggle.Label.Instance.TextColor3 = toggleSel and FromRGB(240, 240, 240) or FromRGB(160, 160, 165)
                    MenuHold.Circle.Instance.BackgroundTransparency = holdSel and 0 or 1
                    MenuHold.CircleStroke.Instance.Transparency = holdSel and 1 or 0
                    MenuHold.Label.Instance.TextColor3 = holdSel and FromRGB(240, 240, 240) or FromRGB(160, 160, 165)
                end
                local function CloseModeMenu()
                    if not SubKeybind.ModeMenuOpen then return end
                    SubKeybind.ModeMenuOpen = false
                    ModeMenuFrame.Instance.Visible = false
                    ModeMenuFrame.Instance.Parent = Library.UnusedHolder.Instance
                end
                local function SetMode(Mode)
                    SubKeybind.Mode = Mode
                    UpdateModeVisuals()
                    Library.Flags[SubKeybind.Flag] = { Key = SubKeybind.Key, Mode = SubKeybind.Mode }
                end
                MenuToggle.Row:Connect("MouseButton1Click", function()
                    SetMode("Toggle")
                    CloseModeMenu()
                end)
                MenuHold.Row:Connect("MouseButton1Click", function()
                    SetMode("Hold")
                    CloseModeMenu()
                end)
                local function OpenModeMenu()
                    if SubKeybind.ModeMenuOpen then CloseModeMenu() return end
                    SubKeybind.ModeMenuOpen = true
                    ModeMenuFrame.Instance.Parent = Library.Holder.Instance
                    ModeMenuFrame.Instance.Visible = true
                    local ContainerPos = SubKeybindItems["Container"].Instance.AbsolutePosition
                    local ContainerSize = SubKeybindItems["Container"].Instance.AbsoluteSize
                    ModeMenuFrame.Instance.Position = UDim2New(0, ContainerPos.X + ContainerSize.X - 55, 0, ContainerPos.Y + ContainerSize.Y + 4)
                end
                SubKeybindItems["Container"]:Connect("InputBegan", function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton2 then OpenModeMenu() end
                end)
                SubKeybindItems["KeyButton"]:Connect("InputBegan", function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton2 then OpenModeMenu() end
                end)
                Library:Connect(UserInputService.InputBegan, function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.MouseButton2 or Input.UserInputType == Enum.UserInputType.Touch then
                        if SubKeybind.ModeMenuOpen and not Library:IsMouseOverFrame(ModeMenuFrame) and not Library:IsMouseOverFrame(SubKeybindItems["Container"]) then
                            CloseModeMenu()
                        end
                    end
                end)
                local function UpdateKeyDisplay()
                    local KeyStr = Keys[SubKeybind.Key] or StringGSub(StringGSub(tostring(SubKeybind.Key), "Enum%.KeyCode%.", ""), "Enum%.UserInputType%.", "") or "None"
                    SubKeybind.Value = KeyStr
                    SubKeybindItems["KeyButton"].Instance.Text = KeyStr
                end
                local function SetKey(Key)
                    if StringFind(tostring(Key), "Enum") then
                        SubKeybind.Key = tostring(Key)
                        local KeyName
                        if type(Key) == "string" then
                            KeyName = Key:match("[^%.]+$") or "None"
                            if KeyName == "Backspace" then KeyName = "None" end
                        else
                            KeyName = Key.Name == "Backspace" and "None" or Key.Name
                        end
                        local KeyStr = Keys[SubKeybind.Key] or StringGSub(StringGSub(KeyName or "", "KeyCode%.", ""), "UserInputType%.", "") or KeyName or "None"
                        SubKeybind.Value = KeyStr
                        SubKeybindItems["KeyButton"].Instance.Text = KeyStr
                        Library.Flags[SubKeybind.Flag] = { Key = SubKeybind.Key, Mode = SubKeybind.Mode }
                        SubKeybind.Picking = false
                        UpdateKeyList()
                    end
                end
                SubKeybindItems["KeyButton"]:Connect("MouseButton1Click", function()
                    SubKeybind.Picking = true
                    SubKeybindItems["KeyButton"].Instance.Text = "..."
                    local InputBegan
                    InputBegan = UserInputService.InputBegan:Connect(function(Input)
                        if Input.UserInputType == Enum.UserInputType.Keyboard then
                            SetKey(Input.KeyCode)
                        else
                            SetKey(Input.UserInputType)
                        end
                        if InputBegan then InputBegan:Disconnect() InputBegan = nil end
                    end)
                end)
                Library:Connect(UserInputService.InputBegan, function(Input)
                    if SubKeybind.Value == "None" or SubKeybind.Picking then return end
                    if tostring(Input.KeyCode) == SubKeybind.Key or tostring(Input.UserInputType) == SubKeybind.Key then
                        if SubKeybind.Mode == "Toggle" then
                            Toggle:Set(not Toggle.Value)
                        elseif SubKeybind.Mode == "Hold" then
                            Toggle:Set(true)
                        end
                    end
                end)
                Library:Connect(UserInputService.InputEnded, function(Input)
                    if SubKeybind.Value == "None" then return end
                    if SubKeybind.Mode == "Hold" and (tostring(Input.KeyCode) == SubKeybind.Key or tostring(Input.UserInputType) == SubKeybind.Key) then
                        Toggle:Set(false)
                    end
                end)
                if SubKeybind.Default then
                    SetKey(SubKeybind.Default)
                end
                SetMode(SubKeybind.DefaultMode)
                Library.SetFlags[SubKeybind.Flag] = function(Value)
                    if Value and type(Value) == "table" then
                        if Value.Key then SetKey(Value.Key) end
                        if Value.Mode == "Toggle" or Value.Mode == "Hold" then SetMode(Value.Mode) end
                    elseif Value and StringFind(tostring(Value), "Enum") then
                        SetKey(Value)
                    end
                end
                function SubKeybind:Get() return SubKeybind.Key, SubKeybind.Value, SubKeybind.Mode end
                function SubKeybind:Set(Key) SetKey(Key) end
                function SubKeybind:SetMode(Mode) SetMode(Mode) end
                SubKeybind.UpdateKeyList = UpdateKeyList
                Toggle.SubKeybindRef = SubKeybind
                return SubKeybind
            end

            function Toggle:Get()
                return Toggle.Value 
            end

            function Toggle:Set(Value)
                Toggle.Value = Value 
                Library.Flags[Toggle.Flag] = Value 

                if Toggle.Value then 
                    Items["Accent"]:Tween(TweenInfo.new(Library.Tween.Time + 0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundTransparency = 0, Size = UDim2New(1, 0, 1, 0)})
                    Items["CheckImage"]:Tween(nil, {ImageTransparency = 0, Size = UDim2New(0, 10, 0, 9)})

                    --Items["Gradient"].Instance.Enabled = true 
                else
                    Items["Accent"]:Tween(TweenInfo.new(Library.Tween.Time + 0.05, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundTransparency = 1, Size = UDim2New(0, 0, 0, 0)})
                    Items["CheckImage"]:Tween(nil, {ImageTransparency = 1, Size = UDim2New(0, 0, 0, 0)})

                    --Items["Gradient"].Instance.Enabled = false
                end

                if Toggle.Callback then 
                    Library:SafeCall(Toggle.Callback, Toggle.Value)
                end
                
                if Toggle.SubKeybindRef and Toggle.SubKeybindRef.UpdateKeyList then
                    Toggle.SubKeybindRef.UpdateKeyList()
                end
            end

            local SettingsItem = { }

            function Toggle:Settings(Size)
                local Settings = {
                    IsOpen = false,
                    Name = "",
                    Items = { },
                    IsSettings = true,
                    Elements = { } 
                }
                Toggle.Settings = Settings

                SettingsItem = { } do 
                    SettingsItem["Settings"] = Instances:Create("Frame", {
                        Parent = Library.UnusedHolder.Instance,
                        Name = "\0",
                        Visible = false,
                        BorderColor3 = FromRGB(0, 0, 0),
                        AnchorPoint = Vector2New(0.5, 0.5),
                        BorderSizePixel = 0,
                        Position = UDim2New(0.8949604630470276, 0, 0.2945185601711273, 0),
                        Size = UDim2New(0, 245, 0, 159),
                        ZIndex = 2,
                        AutomaticSize = Enum.AutomaticSize.Y,
                        BackgroundColor3 = FromRGB(21, 21, 24)
                    })  SettingsItem["Settings"]:AddToTheme({BackgroundColor3 = "Background"})

                    Instances:Create("UICorner", {
                        Parent = SettingsItem["Settings"].Instance,
                        Name = "\0",
                        CornerRadius = UDimNew(0, 6)
                    })                    

                    SettingsItem["SettingsIcon"] = Instances:Create("ImageLabel", {
                        Parent = Items["Text"].Instance,
                        Name = "\0",
                        ImageColor3 = FromRGB(141, 141, 150),
                        BorderColor3 = FromRGB(0, 0, 0),
                        Size = UDim2New(0, 14, 0, 14),
                        AnchorPoint = Vector2New(0, 0.5),
                        Image = "rbxassetid://101500482366184",
                        BackgroundTransparency = 1,
                        Position = UDim2New(1, 6, 0.5, 1),
                        ZIndex = 2,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  Items["SettingsIcon"] = SettingsItem["SettingsIcon"]

                    SettingsItem["Content"] = Instances:Create("ScrollingFrame", {
                        Parent = SettingsItem["Settings"].Instance,
                        Name = "\0",
                        AutomaticCanvasSize = Enum.AutomaticSize.Y,
                        Selectable = false,
                        Size = UDim2New(1, -8, 1, -46),
                        Position = UDim2New(0, 4, 0, 4),
                        ScrollBarThickness = 2,
                        BackgroundColor3 = FromRGB(255, 255, 255),
                        BorderColor3 = FromRGB(0, 0, 0),
                        BorderSizePixel = 0,
                        BackgroundTransparency = 1,
                        CanvasSize = UDim2New(0, 0, 0, 0)
                    })  SettingsItem["Content"]:AddToTheme({ScrollBarImageColor3 = "Accent"})
                    
                    Instances:Create("UIListLayout", {
                        Parent = SettingsItem["Content"].Instance,
                        Name = "\0",
                        Padding = UDimNew(0, 4),
                        SortOrder = Enum.SortOrder.LayoutOrder
                    })
                    
                    Instances:Create("UIPadding", {
                        Parent = SettingsItem["Content"].Instance,
                        Name = "\0",
                        PaddingTop = UDimNew(0, 4),
                        PaddingBottom = UDimNew(0, 4),
                        PaddingRight = UDimNew(0, 4),
                        PaddingLeft = UDimNew(0, 4)
                    })

                    SettingsItem["Button"] = Instances:Create("TextButton", {
                        Parent = SettingsItem["Settings"].Instance,
                        Name = "\0",
                        FontFace = Library.Font,
                        TextColor3 = FromRGB(0, 0, 0),
                        BorderColor3 = FromRGB(0, 0, 0),
                        Text = "",
                        AutoButtonColor = false,
                        BorderSizePixel = 0,
                        Size = UDim2New(1, -16, 0, 32),
                        ZIndex = 2,
                        AnchorPoint = Vector2New(0, 1),
                        Position = UDim2New(0, 8, 1, -8),
                        TextSize = 14,
                        BackgroundColor3 = FromRGB(27, 26, 29)
                    })  SettingsItem["Button"]:AddToTheme({BackgroundColor3 = "Element"})
    
                    SettingsItem["Accent"] = Instances:Create("Frame", {
                        Parent = SettingsItem["Button"].Instance,
                        Name = "\0",
                        Size = UDim2New(0, 0, 0, 0),
                        BorderColor3 = FromRGB(0, 0, 0),
                        ZIndex = 2,
                        BorderSizePixel = 0,
                        BackgroundTransparency = 1,
                        BackgroundColor3 = FromRGB(255, 255, 255),
                        AnchorPoint = Vector2New(0.5, 0.5),
                        Position = UDim2New(0.5, 0, 0.5, 0)
                    })  --SettingsItem["Accent"]:AddToTheme({BackgroundColor3 = "Accent"})
    
                    SettingsItem["Gradient"] = Instances:Create("UIGradient", {
                        Parent = SettingsItem["Accent"].Instance,
                        Name = "\0",
                        Enabled = true,
                        Rotation = -115,
                        Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(143, 143, 143))}
                    })  SettingsItem["Gradient"]:AddToTheme({Color = function()
                        return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                    end})
    
                    Instances:Create("UICorner", {
                        Parent = SettingsItem["Accent"].Instance,
                        Name = "\0",
                        CornerRadius = UDimNew(0, 4)
                    })
                    
                    Instances:Create("UICorner", {
                        Parent = SettingsItem["Button"].Instance,
                        Name = "\0",
                        CornerRadius = UDimNew(0, 4)
                    })
                    
                    SettingsItem["Text"] = Instances:Create("TextLabel", {
                        Parent = SettingsItem["Button"].Instance,
                        Name = "\0",
                        FontFace = Library.Font,
                        TextColor3 = FromRGB(240, 240, 240),
                        TextTransparency = 0.30000001192092896,
                        Text = "Close",
                        AutomaticSize = Enum.AutomaticSize.X,
                        Size = UDim2New(0, 0, 0, 15),
                        AnchorPoint = Vector2New(0.5, 0.5),
                        BorderSizePixel = 0,
                        BackgroundTransparency = 1,
                        Position = UDim2New(0.5, 0, 0.5, 0),
                        BorderColor3 = FromRGB(0, 0, 0),
                        ZIndex = 2,
                        TextSize = 14,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  SettingsItem["Text"]:AddToTheme({TextColor3 = "Text"})   

                    SettingsItem["Button"]:OnHover(function()
                        SettingsItem["Accent"]:Tween(TweenInfo.new(Library.Tween.Time + 0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2New(1, 0, 1, 0), BackgroundTransparency = 0})
                    end)
    
                    SettingsItem["Button"]:OnHoverLeave(function()
                        SettingsItem["Accent"]:Tween(TweenInfo.new(Library.Tween.Time + 0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2New(0, 0, 0, 0), BackgroundTransparency = 1})
                    end)
                end

                local RenderStepped 
                local Debounce = false

                function Settings:SetOpen(Bool)
                    if Debounce then 
                        return
                    end
    
                    Settings.IsOpen = Bool
    
                    Debounce = true 
    
                    if Settings.IsOpen then 
                        task.spawn(function()
                            for Index, Value in Settings.Elements do
                                if type(Value.RefreshPosition) == "function" then
                                    Value:RefreshPosition(true)
                                end
                                task.wait(0.03)
                            end
                        end)

                        SettingsItem["Settings"].Instance.Visible = true
                        SettingsItem["Settings"].Instance.Parent = Library.Holder.Instance
                        
                        RenderStepped = RunService.RenderStepped:Connect(function()
                            SettingsItem["Settings"].Instance.Position = UDim2New(
                                0, Items["Toggle"].Instance.AbsolutePosition.X + Items["Toggle"].Instance.AbsoluteSize.X / 1.9 + 15, 
                                0, Items["Toggle"].Instance.AbsolutePosition.Y + Items["Toggle"].Instance.AbsoluteSize.Y + Size / 1.9)
                            SettingsItem["Settings"].Instance.Size = UDim2New(0, 245, 0, Size)
                        end)
    
                        for Index, Value in Library.OpenFrames do 
                            if Value ~= Settings then 
                                Value:SetOpen(false)
                            end
                        end
    
                        Library.OpenFrames[Settings] = Settings 
                    else
                        for Index, Value in Settings.Elements do
                            if type(Value.RefreshPosition) == "function" then
                                Value:RefreshPosition(false)
                            end
                        end

                        if Library.OpenFrames[Settings] then 
                            Library.OpenFrames[Settings] = nil
                        end
    
                        if RenderStepped then 
                            RenderStepped:Disconnect()
                            RenderStepped = nil
                        end
                    end
    
                    local Descendants = SettingsItem["Settings"].Instance:GetDescendants()
                    TableInsert(Descendants, SettingsItem["Settings"].Instance)
    
                    local NewTween
    
                    for Index, Value in Descendants do 
                        local TransparencyProperty = Tween:GetProperty(Value)
    
                        if not TransparencyProperty then
                            continue 
                        end
    
                        if not Value.ClassName:find("UI") then 
                            Value.ZIndex = Settings.IsOpen and 7 or 1
                        end
    
                        if type(TransparencyProperty) == "table" then 
                            for _, Property in TransparencyProperty do 
                                NewTween = Tween:FadeItem(Value, Property, Bool, Library.FadeSpeed)
                            end
                        else
                            NewTween = Tween:FadeItem(Value, TransparencyProperty, Bool, Library.FadeSpeed)
                        end
                    end
                    
                    NewTween.Tween.Completed:Connect(function()
                        Debounce = false 
                        SettingsItem["Settings"].Instance.Visible = Settings.IsOpen
                        task.wait(0.2)
                        SettingsItem["Settings"].Instance.Parent = not Settings.IsOpen and Library.UnusedHolder.Instance or Library.Holder.Instance
                    end)
                end

                SettingsItem["Button"]:Connect("MouseButton1Down", function()
                    Library:Notification({
                        Title = "System",
                        Description = "Unloading script...",
                        Duration = 2,
                        Icon = "73789337996373"
                    })
                    task.wait(0.5)
                    Library:Unload()
                end)

                SettingsItem["SettingsIcon"]:Connect("InputBegan", function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then 
                        Settings:SetOpen(not Settings.IsOpen)
                    end
                end)

                Library:Connect(UserInputService.InputBegan, function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then 
                        if Library:IsMouseOverFrame(SettingsItem["Settings"]) then
                            return 
                        end

                        Settings:SetOpen(false)
                    end
                end)

                Settings.Items = SettingsItem

                setmetatable(Settings, Library.Sections)
                return Settings
            end

            function Toggle:SetVisibility(Bool)
                Items["Toggle"].Instance.Visible = Bool 
            end

            function Toggle:Colorpicker(Data)
                Data = Data or { }

                local Colorpicker = {
                    Window = Toggle.Window,
                    Page = Toggle.Page,
                    Section = Toggle.Section,

                    Flag = Data.Flag or Data.flag or Library:NextFlag(),
                    Default = Data.Default or Data.default or Color3.fromRGB(255, 255, 255),
                    Callback = Data.Callback or Data.callback or function() end,
                    Alpha = Data.Alpha or Data.alpha or false
                }

                if not Items["SubElements"] then
                    Items["SubElements"] = Instances:Create("Frame", {
                        Parent = Toggle.Section.Items["Content"].Instance,
                        Name = "\0",
                        Size = UDim2New(1, 0, 0, 30),
                        BorderColor3 = FromRGB(0, 0, 0),
                        ZIndex = 2,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(27, 26, 29)
                    })  Items["SubElements"]:AddToTheme({BackgroundColor3 = "Element"})
                    Instances:Create("UICorner", { Parent = Items["SubElements"].Instance, Name = "\0", CornerRadius = UDimNew(0, 5) })
                    Instances:Create("UIListLayout", {
                        Parent = Items["SubElements"].Instance,
                        Name = "\0",
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                        FillDirection = Enum.FillDirection.Horizontal,
                        Padding = UDimNew(0, 5),
                        SortOrder = Enum.SortOrder.LayoutOrder
                    })
                    Instances:Create("UIPadding", {
                        Parent = Items["SubElements"].Instance,
                        Name = "\0",
                        PaddingLeft = UDimNew(0, 6)
                    })
                end

                local NewColorpicker, ColorpickerItems = Library:CreateColorpicker({
                    Parent = Items["SubElements"],
                    Page = Colorpicker.Page,
                    Section = Colorpicker.Section,
                    Flag = Colorpicker.Flag,
                    Default = Colorpicker.Default,
                    Callback = Colorpicker.Callback,
                    Alpha = Colorpicker.Alpha
                })

                return NewColorpicker
            end

            function Toggle:SubColorpicker(Data)
                Data = Data or { }
                if Toggle.SubColorpickerCount >= 7 then return nil end
                Toggle.SubColorpickerCount = Toggle.SubColorpickerCount + 1
                local RightContainer = GetRightContainer()
                local Wrapper = Instances:Create("Frame", {
                    Parent = RightContainer.Instance,
                    Name = "\0",
                    Size = UDim2New(0, 14, 0, 18),
                    LayoutOrder = Toggle.SubColorpickerCount - 1,
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1
                })
                local ColorBoxHolder = Instances:Create("Frame", {
                    Parent = Wrapper.Instance,
                    Name = "\0",
                    Size = UDim2New(0, 14, 0, 14),
                    AnchorPoint = Vector2New(0.5, 0.5),
                    Position = UDim2New(0.5, 0, 0.5, 0),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1
                })
                local DummySection = { IsSettings = false }
                local NewColorpicker = Library:CreateColorpicker({
                    Parent = ColorBoxHolder,
                    Page = Toggle.Page,
                    Section = DummySection,
                    Flag = Data.Flag or Data.flag or Library:NextFlag(),
                    Default = Data.Default or Data.default or Color3.fromRGB(255, 255, 255),
                    Callback = Data.Callback or Data.callback or function() end,
                    Alpha = Data.Alpha or Data.alpha or false,
                    Compact = true,
                    LayoutOrder = 0
                })
                return NewColorpicker
            end

            function Toggle:Keybind(Data)
                Data = Data or { }

                local Keybind = {
                    Window = Toggle.Window,
                    Page = Toggle.Page,
                    Section = Toggle.Section,

                    Flag = Data.Flag or Data.flag or Library:NextFlag(),
                    Default = Data.Default or Data.default or Enum.KeyCode.E,
                    Callback = Data.Callback or Data.callback or function(Value) Toggle:Set(Value) end,
                    Mode = Data.Mode or Data.mode or "Toggle"
                }

                if not Items["SubElements"] then
                    Items["SubElements"] = Instances:Create("Frame", {
                        Parent = Toggle.Section.Items["Content"].Instance,
                        Name = "\0",
                        Size = UDim2New(1, 0, 0, 30),
                        BorderColor3 = FromRGB(0, 0, 0),
                        ZIndex = 2,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(27, 26, 29)
                    })  Items["SubElements"]:AddToTheme({BackgroundColor3 = "Element"})
                    Instances:Create("UICorner", { Parent = Items["SubElements"].Instance, Name = "\0", CornerRadius = UDimNew(0, 5) })
                    Instances:Create("UIListLayout", {
                        Parent = Items["SubElements"].Instance,
                        Name = "\0",
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                        FillDirection = Enum.FillDirection.Horizontal,
                        Padding = UDimNew(0, 5),
                        SortOrder = Enum.SortOrder.LayoutOrder
                    })
                    Instances:Create("UIPadding", {
                        Parent = Items["SubElements"].Instance,
                        Name = "\0",
                        PaddingLeft = UDimNew(0, 6)
                    })
                end

                local NewKeybind, KeybindItems = Library:CreateKeybind({
                    Parent = Items["SubElements"],
                    Page = Keybind.Page,
                    Section = Keybind.Section,
                    Flag = Keybind.Flag,
                    Default = Keybind.Default,
                    Mode = Keybind.Mode,
                    Callback = Keybind.Callback
                })

                return NewKeybind
            end

            function Toggle:RefreshPosition(Bool)
                if Bool then 
                    Items["Indicator"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0, 0)})
                    Items["Text"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 24, 0, 0)})
                else
                    Items["Indicator"].Instance.Position = UDim2New(0, 60, 0, 0)
                    Items["Text"].Instance.Position = UDim2New(0, 84, 0, 0)
                end 
            end

            Items["Toggle"]:Connect("InputBegan", function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then 
                    if Items["SettingsIcon"] and Library:IsMouseOverFrame(Items["SettingsIcon"]) then
                        return 
                    end
                    
                    Toggle:Set(not Toggle.Value)
                end
            end)

            Toggle:Set(Toggle.Default)

            Library.SetFlags[Toggle.Flag] = function(Value)
                Toggle:Set(Value)
            end

            Toggle.Section.Elements[#Toggle.Section.Elements+1] = Toggle

            return Toggle 
        end

        Library.Sections.Button = function(self, Data)
            Data = Data or { }

            local Button = {
                Window = self.Window,
                Page = self.Page,
                Section = self,

                Name = Data.Name or Data.name or "Button",
                Icon = Data.Icon or Data.icon or nil,
                Callback = Data.Callback or Data.callback or function() end
            }

            local Items = { } do 
                Items["Button"] = Instances:Create("TextButton", {
                    Parent = Button.Section.Items["Content"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    BorderSizePixel = 0,
                    Size = UDim2New(1, 0, 0, 32),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(27, 26, 29)
                })  Items["Button"]:AddToTheme({BackgroundColor3 = "Element"})

                Items["Accent"] = Instances:Create("Frame", {
                    Parent = Items["Button"].Instance,
                    Name = "\0",
                    Size = UDim2New(0, 0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    BackgroundColor3 = FromRGB(255, 255, 255),
                    AnchorPoint = Vector2New(0.5, 0.5),
                    Position = UDim2New(0.5, 0, 0.5, 0)
                })  --Items["Accent"]:AddToTheme({BackgroundColor3 = "Accent"})

                Items["Gradient"] = Instances:Create("UIGradient", {
                    Parent = Items["Accent"].Instance,
                    Name = "\0",
                    Enabled = true,
                    Rotation = -115,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(143, 143, 143))}
                })  Items["Gradient"]:AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                end})

                Instances:Create("UICorner", {
                    Parent = Items["Accent"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })
                
                Instances:Create("UICorner", {
                    Parent = Items["Button"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })
                
                Items["Text"] = Instances:Create("TextLabel", {
                    Parent = Items["Button"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.30000001192092896,
                    Text = Button.Name,
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(0, 0, 0, 15),
                    AnchorPoint = Vector2New(0.5, 0.5),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0.5, 0, 0.5, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Text"]:AddToTheme({TextColor3 = "Text"})          
                
                if Button.Icon then 
                    Items["Icon"] = Instances:Create("ImageLabel", {
                        Parent = Items["Text"].Instance,
                        Name = "\0",
                        ImageColor3 = FromRGB(240, 240, 240),
                        ImageTransparency = 0.30000001192092896,
                        BorderColor3 = FromRGB(0, 0, 0),
                        Size = UDim2New(0, 18, 0, 18),
                        AnchorPoint = Vector2New(1, 0.5),
                        Image = "rbxassetid://"..Button.Icon,
                        BackgroundTransparency = 1,
                        Position = UDim2New(0, -8, 0.5, 0),
                        ZIndex = 2,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(255, 255, 255)
                    })  Items["Icon"]:AddToTheme({ImageColor3 = "Text"})
                end                    

                Items["Button"]:OnHover(function()
                    Items["Accent"]:Tween(TweenInfo.new(Library.Tween.Time + 0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2New(1, 0, 1, 0), BackgroundTransparency = 0})
                end)

                Items["Button"]:OnHoverLeave(function()
                    Items["Accent"]:Tween(TweenInfo.new(Library.Tween.Time + 0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2New(0, 0, 0, 0), BackgroundTransparency = 1})
                end)
            end 

            --Button.Section.Items["Fade"].Instance.Size = UDim2New(1, 0, 0, Button.Section.Items["Content"].Instance.AbsoluteSize.X - 180)

            function Button:SetVisibility(Bool)
                Items["Button"].Instance.Visible = Bool
            end

            function Button:Press()
                if Items["Button"] and Items["Button"].Instance then
                    Items["Button"]:ChangeItemTheme({BackgroundColor3 = "Accent"})
                    Items["Button"]:Tween(nil, {BackgroundColor3 = Library.Theme.Accent})
                end
                if Items["Text"] and Items["Text"].Instance then
                    Items["Text"]:Tween(nil, {TextColor3 = FromRGB(0, 0, 0), TextTransparency = 0})
                end
                if Button.Icon and Items["Icon"] and Items["Icon"].Instance then
                    Items["Icon"]:Tween(nil, {ImageColor3 = FromRGB(0, 0, 0), ImageTransparency = 0})
                end

                task.wait(0.2)

                Library:SafeCall(Button.Callback)

                if Items["Button"] and Items["Button"].Instance and Items["Button"].Instance.Parent then
                    Items["Button"]:ChangeItemTheme({BackgroundColor3 = "Element"})
                    Items["Button"]:Tween(nil, {BackgroundColor3 = Library.Theme.Element})
                end
                if Items["Text"] and Items["Text"].Instance and Items["Text"].Instance.Parent then
                    Items["Text"]:Tween(nil, {TextColor3 = Library.Theme.Text, TextTransparency = 0.3})
                end
                if Button.Icon and Items["Icon"] and Items["Icon"].Instance and Items["Icon"].Instance.Parent then
                    Items["Icon"]:Tween(nil, {ImageColor3 = Library.Theme.Text, ImageTransparency = 0.3})
                end
            end

            Items["Button"]:Connect("MouseButton1Down", function()
                Button:Press()
            end)

            return Button
        end

        Library.Sections.Slider = function(self, Data)
            Data = Data or { }

            local Slider = {
                Window = self.Window,
                Page = self.Page,
                Section = self,

                Name = Data.Name or Data.name or "Slider",
                Flag = Data.Flag or Data.flag or Library:NextFlag(),
                Min = Data.Min or Data.min or 0,
                Default = Data.Default or Data.default or 0,
                Max = Data.Max or Data.max or 100,
                Suffix = Data.Suffix or Data.suffix or "",
                Decimals = Data.Decimals or Data.decimals or 1,
                Callback = Data.Callback or Data.callback or function() end,

                Value = 0,
                Sliding = false
            }

            local Items = { } do 
                Items["Slider"] = Instances:Create("Frame", {
                    Parent = Slider.Section.Items["Content"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 0, 35),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Items["Text"] = Instances:Create("TextLabel", {
                    Parent = Items["Slider"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.30000001192092896,
                    Text = Slider.Name,
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(0, 0, 0, 15),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Text"]:AddToTheme({TextColor3 = "Text"})

                Items["RealSlider"] = Instances:Create("TextButton", {
                    Parent = Items["Slider"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    AnchorPoint = Vector2New(0, 1),
                    BorderSizePixel = 0,
                    Position = UDim2New(0, 20, 1, -3),
                    Size = UDim2New(1, -40, 0, 7),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(27, 26, 29)
                })  Items["RealSlider"]:AddToTheme({BackgroundColor3 = "Element"})

                Instances:Create("UICorner", {
                    Parent = Items["RealSlider"].Instance,
                    Name = "\0"
                })

                Items["Accent"] = Instances:Create("Frame", {
                    Parent = Items["RealSlider"].Instance,
                    Name = "\0",
                    Size = UDim2New(0.5, 0, 1, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  --Items["Accent"]:AddToTheme({BackgroundColor3 = "Accent"})

                Instances:Create("UICorner", {
                    Parent = Items["Accent"].Instance,
                    Name = "\0"
                })

                Items["Icon"] = Instances:Create("ImageLabel", {
                    Parent = Items["Accent"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 16, 0, 12),
                    AnchorPoint = Vector2New(0.5, 0.5),
                    Image = "rbxassetid://117786983271442",
                    BackgroundTransparency = 1,
                    Position = UDim2New(1, 5, 0.5, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Instances:Create("UIGradient", {
                    Parent = Items["Accent"].Instance,
                    Name = "\0",
                    Rotation = -102,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(166, 166, 166))}
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                end})

                Items["Plus"] = Instances:Create("TextButton", {
                    Parent = Items["RealSlider"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.30000001192092896,
                    Text = "+",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AutoButtonColor = false,
                    AnchorPoint = Vector2New(0, 0.5),
                    Size = UDim2New(0, 20, 0, 20),
                    BackgroundTransparency = 1,
                    Position = UDim2New(1, 0, 0.5, -3),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Plus"]:AddToTheme({TextColor3 = "Text"})

                Items["Minus"] = Instances:Create("TextButton", {
                    Parent = Items["RealSlider"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.30000001192092896,
                    Text = "-",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AutoButtonColor = false,
                    AnchorPoint = Vector2New(1, 0.5),
                    Size = UDim2New(0, 20, 0, 20),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, -2, 0.5, -2),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Minus"]:AddToTheme({TextColor3 = "Text"})

                Items["Value"] = Instances:Create("TextLabel", {
                    Parent = Items["Slider"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.30000001192092896,
                    Text = "50%",
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(0, 0, 0, 15),
                    AnchorPoint = Vector2New(1, 0),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    Position = UDim2New(1, 0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Value"]:AddToTheme({TextColor3 = "Text"})

                Items["RealSlider"]:OnHover(function()
                    Items["Icon"]:Tween(TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2New(0, 18, 0, 14)})
                end)

                Items["RealSlider"]:OnHoverLeave(function()
                    Items["Icon"]:Tween(TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2New(0, 16, 0, 12)})
                end)
            end

            --Slider.Section.Items["Fade"].Instance.Size = UDim2New(1, 0, 0, Slider.Section.Items["Content"].Instance.AbsoluteSize.X - 180)

            --Items["Value"].Instance.TextTransparency = 1
            Items["RealSlider"].Instance.Position = UDim2New(0, 80, 1, -3)
            Items["Text"].Instance.Position = UDim2New(0, 80, 0, 0)

            function Slider:Get()
                return Slider.Value 
            end

            function Slider:SetVisibility(Bool)
                Items["Slider"].Instance.Visible = Bool
            end

            function Slider:RefreshPosition(Bool)
                if Bool then 
                    Items["RealSlider"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 20, 1, -3)})
                    Items["Text"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0, 0)})
                -- Items["Value"].Instance.TextTransparency = 0.3
                else
                    Items["RealSlider"].Instance.Position = UDim2New(0, 80, 1, -3)
                    Items["Text"].Instance.Position = UDim2New(0, 80, 0, 0)
                -- Items["Value"].Instance.TextTransparency = 1
                end
            end

            function Slider:Set(Value)
                Slider.Value = Library:Round(MathClamp(Value, Slider.Min, Slider.Max), Slider.Decimals)
                Library.Flags[Slider.Flag] = Slider.Value

                Items["Accent"]:Tween(TweenInfo.new(Library.Tween.Time, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2New((Slider.Value - Slider.Min) / (Slider.Max - Slider.Min), 0, 1, 0)})
                Items["Value"].Instance.Text = StringFormat("%s%s", Slider.Value, Slider.Suffix)

                if Slider.Value >= Slider.Max then
                    Items["Icon"].Instance.Position = UDim2New(1, -5, 0.5, 0)
                else
                    Items["Icon"].Instance.Position = UDim2New(1, 5, 0.5, 0)
                end

                if Slider.Callback then
                    Library:SafeCall(Slider.Callback, Slider.Value)
                end
            end

            -- ДОБАВЛЕНО: смена границ слайдера на лету (значение переклампливается, полоса перерисовывается)
            function Slider:SetMax(NewMax)
                NewMax = tonumber(NewMax)
                if not NewMax or NewMax <= Slider.Min then return end
                Slider.Max = NewMax
                Slider:Set(Slider.Value)
            end

            function Slider:SetMin(NewMin)
                NewMin = tonumber(NewMin)
                if not NewMin or NewMin >= Slider.Max then return end
                Slider.Min = NewMin
                Slider:Set(Slider.Value)
            end

            Items["Plus"]:Connect("MouseButton1Down", function()
                Slider:Set(Slider.Value + Slider.Decimals)
            end)

            Items["Minus"]:Connect("MouseButton1Down", function()
                Slider:Set(Slider.Value - Slider.Decimals)
            end)

            local InputChanged 
            
            Items["RealSlider"]:Connect("InputBegan", function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    Slider.Sliding = true

                    -- FIX: захватываем геометрию трека на СТАРТЕ драга и считаем от неё до конца.
                    -- Слайдер UI Size меняет UIScale контейнера → его AbsolutePosition/AbsoluteSize
                    -- плывут в процессе → деление скачет → значение «калбасит» (100 ↔ минимум).
                    -- От зафиксированной геометрии петли нет. Для обычных слайдеров поведение то же.
                    Slider._DragPosX = Items["RealSlider"].Instance.AbsolutePosition.X
                    Slider._DragSizeX = Items["RealSlider"].Instance.AbsoluteSize.X

                    local SizeX = (Input.Position.X - Slider._DragPosX) / Slider._DragSizeX
                    local Value = ((Slider.Max - Slider.Min) * SizeX) + Slider.Min

                    Slider:Set(Value)

                    if InputChanged then
                        return
                    end

                    InputChanged = Input.Changed:Connect(function()
                        if Input.UserInputState == Enum.UserInputState.End then
                            Slider.Sliding = false
                            Slider._DragPosX = nil
                            Slider._DragSizeX = nil

                            InputChanged:Disconnect()
                            InputChanged = nil
                        end
                    end)
                end
            end)

            Library:Connect(UserInputService.InputChanged, function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
                    if Slider.Sliding then
                        local PosX = Slider._DragPosX or Items["RealSlider"].Instance.AbsolutePosition.X
                        local SzX = Slider._DragSizeX or Items["RealSlider"].Instance.AbsoluteSize.X
                        local SizeX = (Input.Position.X - PosX) / SzX
                        local Value = ((Slider.Max - Slider.Min) * SizeX) + Slider.Min

                        Slider:Set(Value)
                    end
                end
            end)

            if Slider.Default then
                Slider:Set(Slider.Default)
            end

            Library.SetFlags[Slider.Flag] = function(Value)
                Slider:Set(Value)
            end

            Slider.Section.Elements[#Slider.Section.Elements+1] = Slider
            return Slider 
        end

        Library.Sections.Dropdown = function(self, Data)
            Data = Data or { }

            local Dropdown = {
                Window = self.Window,
                Page = self.Page,
                Section = self,

                Name = Data.Name or Data.name or "Dropdown",
                Flag = Data.Flag or Data.flag or Library:NextFlag(),
                Items = Data.Items or Data.items or { "One", "Two", "Three" },
                Default = Data.Default or Data.default or nil,
                Callback = Data.Callback or Data.callback or function() end,
                Size = Data.Size or Data.size or 125,
                OptionHolderSize = Data.OptionHolderSize or Data.optionholder or 125,
                OptionWidth = Data.OptionWidth or Data.optionwidth or nil,   -- ДОБАВЛЕНО: попап шире кнопки (длинные названия не режутся)
                Multi = Data.Multi or Data.multi or false,

                Value = { },
                Options = { },
                OptionsWithIndexes = { },
                IsOpen = false
            }

            local Items = { } do 
                Items["Dropdown"] = Instances:Create("Frame", {
                    Parent = Dropdown.Section.Items["Content"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 0, 25),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Items["Text"] = Instances:Create("TextLabel", {
                    Parent = Items["Dropdown"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.30000001192092896,
                    Text = Dropdown.Name,
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(0, 0, 0, 15),
                    AnchorPoint = Vector2New(0, 0.5),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 0, 0.5, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Text"]:AddToTheme({TextColor3 = "Text"})
                
                Items["RealDropdown"] = Instances:Create("TextButton", {
                    Parent = Items["Dropdown"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    Size = UDim2New(0, Dropdown.Size or 125, 0, 25),
                    AutoButtonColor = false,
                    AnchorPoint = Vector2New(1, 0),
                    Position = UDim2New(1, 0, 0, 0),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(27, 26, 29)
                })  Items["RealDropdown"]:AddToTheme({BackgroundColor3 = "Element"})
                
                Instances:Create("UICorner", {
                    Parent = Items["RealDropdown"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 6)
                })
                
                Items["Value"] = Instances:Create("TextLabel", {
                    Parent = Items["RealDropdown"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.30000001192092896,
                    Text = "-",
                    Size = UDim2New(1, -40, 0, 15),
                    AnchorPoint = Vector2New(0, 0.5),
                    BorderSizePixel = 0,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 10, 0.5, -1),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Value"]:AddToTheme({TextColor3 = "Text"})
                
                Items["Liner"] = Instances:Create("Frame", {
                    Parent = Items["RealDropdown"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(1, 0),
                    Position = UDim2New(1, -25, 0, 0),
                    Size = UDim2New(0, 2, 1, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(34, 32, 36)
                })  Items["Liner"]:AddToTheme({BackgroundColor3 = "Outline"})
                
                Items["ArrowIcon"] = Instances:Create("ImageLabel", {
                    Parent = Items["RealDropdown"].Instance,
                    Name = "\0",
                    ImageColor3 = FromRGB(141, 141, 150),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 16, 0, 8),
                    AnchorPoint = Vector2New(1, 0.5),
                    Image = "rbxassetid://123317177279443",
                    BackgroundTransparency = 1,
                    Position = UDim2New(1, -5, 0.5, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Items["Gradient"] = Instances:Create("UIGradient", {
                    Parent = Items["ArrowIcon"].Instance,
                    Name = "\0",
                    Enabled = false,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(131, 131, 131)), RGBSequenceKeypoint(1, FromRGB(255, 255, 255))}
                })  Items["Gradient"]:AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                end})

                Items["OptionHolder"] = Instances:Create("TextButton", {
                    Parent = Library.UnusedHolder.Instance,
                    Text = "",
                    AutoButtonColor = false,
                    Name = "\0",
                    Visible = false,
                    Position = UDim2New(0, 897, 0, 101),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0, 159, 0, 87),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(27, 25, 29)
                })  Items["OptionHolder"]:AddToTheme({BackgroundColor3 = "Background"})
                
                Instances:Create("UIStroke", {
                    Parent = Items["OptionHolder"].Instance,
                    Name = "\0",
                    Color = FromRGB(35, 33, 38),
                    ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                }):AddToTheme({Color = "Outline"})
                
                Instances:Create("UICorner", {
                    Parent = Items["OptionHolder"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 5)
                })
                
                Items["Holder"] = Instances:Create("ScrollingFrame", {
                    Parent = Items["OptionHolder"].Instance,
                    Name = "\0",
                    Active = true,
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    ScrollBarThickness = 2,
                    Size = UDim2New(1, -16, 1, -16),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 8, 0, 8),
                    BackgroundColor3 = FromRGB(255, 255, 255),
                    BorderColor3 = FromRGB(0, 0, 0),
                    BorderSizePixel = 0,
                    CanvasSize = UDim2New(0, 0, 0, 0)
                })  Items["Holder"]:AddToTheme({ScrollBarImageColor3 = "Accent"})
                
                Instances:Create("UIListLayout", {
                    Parent = Items["Holder"].Instance,
                    Name = "\0",
                    Padding = UDimNew(0, 4),
                    SortOrder = Enum.SortOrder.LayoutOrder
                })                
            end

            --ropdown.Section.Items["Fade"].Instance.Size = UDim2New(1, 0, 0, Dropdown.Section.Items["Content"].Instance.AbsoluteSize.X - 180)

            Items["Text"].Instance.Position = UDim2New(0, 30, 0.5, 0)
            Items["RealDropdown"].Instance.Position = UDim2New(1, 30, 0, 0)

            function Dropdown:Get()
                return Dropdown.Value
            end

            function Dropdown:SetVisibility(Bool)
                Items["Dropdown"].Instance.Visible = Bool
            end

            function Dropdown:RefreshPosition(Bool)
                if Bool then
                    Items["Text"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0.5, 0)})
                    Items["RealDropdown"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(1, 0, 0, 0)})
                else
                    Items["Text"].Instance.Position = UDim2New(0, 30, 0.5, 0)
                    Items["RealDropdown"].Instance.Position = UDim2New(1, 30, 0, 0)
                end
            end

            Items["RealDropdown"]:OnHover(function()
                if Dropdown.IsOpen then
                    return 
                end

                Items["ArrowIcon"]:Tween(nil, {ImageColor3 = FromRGB(255, 255, 255)})
                Items["Gradient"].Instance.Enabled = true
            end)

            Items["RealDropdown"]:OnHoverLeave(function()
                if Dropdown.IsOpen then
                    return 
                end

                Items["ArrowIcon"]:Tween(nil, {ImageColor3 = FromRGB(141, 141, 150)})
                Items["Gradient"].Instance.Enabled = false
            end)

            local RenderStepped 

            function Dropdown:SetOpen(Bool)
                if Debounce then 
                    return
                end

                Dropdown.IsOpen = Bool

                Debounce = true 

                if Dropdown.IsOpen then
                    Items["OptionHolder"].Instance.Visible = true
                    Items["OptionHolder"].Instance.Parent = Library.Holder.Instance

                    -- FIX: попап живёт в Library.Holder, а кнопка дропдауна — под своими UIScale'ами
                    -- (UI Size на MainFrame, возможные скейлы на холдере и т.п.). Масштаб попапа считаем
                    -- КУМУЛЯТИВНО по цепочкам предков, позицию доводим ОБРАТНОЙ СВЯЗЬЮ по AbsolutePosition —
                    -- работает при любой комбинации скейлов/инсетов.
                    local OHScale = Items["OptionHolder"].Instance:FindFirstChildOfClass("UIScale")
                    if not OHScale then
                        OHScale = Instances:Create("UIScale", { Parent = Items["OptionHolder"].Instance, Name = "\0", Scale = 1 }).Instance
                    end
                    local function CumulativeScale(inst)
                        local s, cur = 1, inst
                        while cur and cur ~= game do
                            local us = cur:FindFirstChildOfClass("UIScale")
                            if us and us ~= OHScale then s = s * us.Scale end
                            cur = cur.Parent
                        end
                        return s
                    end

                    Items["ArrowIcon"]:Tween(nil, {Rotation = 180, ImageColor3 = FromRGB(255, 255, 255)})
                    Items["Gradient"].Instance.Enabled = true

                    Library:Thread(function()
                        for Index, Value in Dropdown.OptionsWithIndexes do
                            task.spawn(function()
                                Value:RefreshPosition(true)
                            end)
                            task.wait(0.05)
                        end
                    end)

                    RenderStepped = RunService.RenderStepped:Connect(function()
                        local btn = Items["RealDropdown"].Instance
                        local oh = Items["OptionHolder"].Instance
                        local btnScale = CumulativeScale(btn)
                        local parentScale = oh.Parent and CumulativeScale(oh.Parent) or 1
                        if btnScale <= 0 then btnScale = 1 end
                        if parentScale <= 0 then parentScale = 1 end
                        OHScale.Scale = btnScale / parentScale       -- визуальный масштаб попапа = масштабу кнопки
                        local bp, bs = btn.AbsolutePosition, btn.AbsoluteSize
                        local ow = bs.X / btnScale                                    -- ширина = кнопке...
                        if Dropdown.OptionWidth and Dropdown.OptionWidth > ow then    -- ...или шире (OptionWidth),
                            ow = Dropdown.OptionWidth                                 -- чтобы длинные названия влезали
                        end
                        -- позиция обратной связью: правый край попапа = правому краю кнопки
                        -- (расширение уходит ВЛЕВО, за меню не вылезает)
                        local targetX = bp.X + bs.X - ow * btnScale
                        local targetY = bp.Y + bs.Y + 5
                        local cur = oh.AbsolutePosition
                        local p = oh.Position
                        oh.Position = UDim2New(0, p.X.Offset + (targetX - cur.X), 0, p.Y.Offset + (targetY - cur.Y))
                        oh.Size = UDim2New(0, ow, 0, Dropdown.OptionHolderSize)
                    end)

                    for Index, Value in Library.OpenFrames do 
                        if Value ~= Dropdown and not Dropdown.Section.IsSettings then 
                            Value:SetOpen(false)
                        end
                    end

                    Library.OpenFrames[Dropdown] = Dropdown 
                else
                    if not Dropdown.IsOpen then
                        for Index, Value in Dropdown.OptionsWithIndexes do 
                            task.spawn(function()
                                Value:RefreshPosition(false)
                            end)
                        end
                    end

                    if Library.OpenFrames[Dropdown] then 
                        Library.OpenFrames[Dropdown] = nil
                    end

                    if RenderStepped then 
                        RenderStepped:Disconnect()
                        RenderStepped = nil
                    end

                    Items["ArrowIcon"]:Tween(nil, {Rotation = 0, ImageColor3 = FromRGB(141, 141, 150)})
                    Items["Gradient"].Instance.Enabled = false
                end

                local Descendants = Items["OptionHolder"].Instance:GetDescendants()
                TableInsert(Descendants, Items["OptionHolder"].Instance)

                local NewTween

                for Index, Value in Descendants do 
                    local TransparencyProperty = Tween:GetProperty(Value)

                    if not TransparencyProperty then
                        continue 
                    end

                    if not Value.ClassName:find("UI") then 
                        Value.ZIndex = (Dropdown.IsOpen and Dropdown.Section.IsSettings and 8) or (Dropdown.IsOpen and 3) or 1
                    end

                    if type(TransparencyProperty) == "table" then 
                        for _, Property in TransparencyProperty do 
                            NewTween = Tween:FadeItem(Value, Property, Bool, Library.FadeSpeed)
                        end
                    else
                        NewTween = Tween:FadeItem(Value, TransparencyProperty, Bool, Library.FadeSpeed)
                    end
                end
                
                NewTween.Tween.Completed:Connect(function()
                    Debounce = false 
                    Items["OptionHolder"].Instance.Visible = Dropdown.IsOpen
                    task.wait(0.2)
                    Items["OptionHolder"].Instance.Parent = not Dropdown.IsOpen and Library.UnusedHolder.Instance or Library.Holder.Instance
                end)
            end

            function Dropdown:Set(Option)
                if Dropdown.Multi then 
                    if type(Option) ~= "table" then 
                        return
                    end

                    Dropdown.Value = Option
                    Library.Flags[Dropdown.Flag] = Option

                    for Index, Value in Option do
                        local OptionData = Dropdown.Options[Value]
                        
                        if not OptionData then
                            continue
                        end

                        OptionData.Selected = true 
                        OptionData:Toggle("Active")
                    end

                    Items["Value"].Instance.Text = TableConcat(Option, ", ")
                else
                    if not Dropdown.Options[Option] then
                        return
                    end

                    local OptionData = Dropdown.Options[Option]

                    Dropdown.Value = Option
                    Library.Flags[Dropdown.Flag] = Option

                    for Index, Value in Dropdown.Options do
                        if Value ~= OptionData then
                            Value.Selected = false 
                            Value:Toggle("Inactive")
                        else
                            Value.Selected = true 
                            Value:Toggle("Active")
                        end
                    end

                    Items["Value"].Instance.Text = Option
                end

                if Dropdown.Callback then   
                    Library:SafeCall(Dropdown.Callback, Dropdown.Value)
                end
            end

            function Dropdown:Add(Option)
                local OptionButton = Instances:Create("TextButton", {
                    Parent = Items["Holder"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 0, 20),
                    BorderSizePixel = 0,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                local OptionAccent = Instances:Create("Frame", {
                    Parent = OptionButton.Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0, 0.5),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 0, 0.5, 0),
                    Size = UDim2New(0, 6, 0, 6),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  --OptionAccent:AddToTheme({BackgroundColor3 = "Accent"})

                Instances:Create("UIGradient", {
                    Parent = OptionAccent.Instance,
                    Name = "\0",
                    Enabled = true,
                    Rotation = -115,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(143, 143, 143))}
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                end})
                
                Instances:Create("UICorner", {
                    Parent = OptionAccent.Instance,
                    Name = "\0"
                })
                
                local OptionText = Instances:Create("TextLabel", {
                    Parent = OptionAccent.Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(255, 255, 255),
                    TextTransparency = 0.30000001192092896,
                    Text = Option,
                    Size = UDim2New(0, 0, 0, 15),
                    AnchorPoint = Vector2New(0, 0.5),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 30, 0.5, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.X,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  OptionText:AddToTheme({TextColor3 = "Text"})
                
                local OptionData = {
                    Button = OptionButton,
                    Name = Option,
                    OptionText = OptionText,
                    OptionAccent = OptionAccent,
                    Selected = false
                }
                
                function OptionData:Toggle(Value)
                    if Value == "Active" then
                        OptionText:Tween(nil, {TextTransparency = 0, Position = UDim2New(0, 15, 0.5, 0)})
                        OptionAccent:Tween(nil, {BackgroundTransparency = 0})
                    else
                        OptionText:Tween(nil, {TextTransparency = 0.3, Position = UDim2New(0, 0, 0.5, 0)})
                        OptionAccent:Tween(nil, {BackgroundTransparency = 1})
                    end
                end

                function OptionData:RefreshPosition(Bool)
                    if Bool then 
                        if OptionData.Selected then
                            OptionAccent:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0.5, 0)})
                            OptionText:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 15, 0.5, 0)})
                        else
                            OptionText:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0.5, 0)})
                        end
                    else
                        if OptionData.Selected then
                            OptionAccent.Instance.Position = UDim2New(0, 30, 0.5, 0)
                            OptionText.Instance.Position = UDim2New(0, 45, 0.5, 0)
                        else
                            OptionText.Instance.Position = UDim2New(0, 30, 0.5, 0)
                        end
                    end

                    --if Bool then
                        --OptionAccent:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0.5, 0)})
                    --else
                        --OptionAccent.Instance.Position = UDim2New(0, 30, 0.5, 0)
                    --end
                    
                    --[[
                    if Bool then 
                        if OptionData.Selected then 
                            OptionAccent:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0.5, 0)})
                            OptionText:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 15, 0.5, 0)})
                        else
                            OptionText:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0.5, 0)})
                        end
                    else
                        if OptionData.Selected then
                            OptionAccent.Instance.Position = UDim2New(0, 30, 0.5, 0)
                            OptionText.Instance.Position = UDim2New(0, 45, 0.5, 0)
                        else
                            OptionText.Instance.Position = UDim2New(0, 30, 0.5, 0)
                        end
                    end
                    --]]
                end

                function OptionData:Set()
                    OptionData.Selected = not OptionData.Selected

                    if Dropdown.Multi then 
                        local Index = TableFind(Dropdown.Value, OptionData.Name)

                        if Index then 
                            TableRemove(Dropdown.Value, Index)
                        else
                            TableInsert(Dropdown.Value, OptionData.Name)
                        end

                        OptionData:Toggle(Index and "Inactive" or "Active")

                        Library.Flags[Dropdown.Flag] = Dropdown.Value

                        local TextFormat = #Dropdown.Value > 0 and TableConcat(Dropdown.Value, ", ") or "..."
                        Items["Value"].Instance.Text = TextFormat
                    else
                        if OptionData.Selected then 
                            Dropdown.Value = OptionData.Name
                            Library.Flags[Dropdown.Flag] = OptionData.Name

                            OptionData.Selected = true
                            OptionData:Toggle("Active")

                            for Index, Value in Dropdown.Options do 
                                if Value ~= OptionData then
                                    Value.Selected = false 
                                    Value:Toggle("Inactive")
                                end
                            end

                            Items["Value"].Instance.Text = OptionData.Name
                        else
                            Dropdown.Value = nil
                            Library.Flags[Dropdown.Flag] = nil

                            OptionData.Selected = false
                            OptionData:Toggle("Inactive")

                            Items["Value"].Instance.Text = "..."
                        end
                    end

                    if Dropdown.Callback then
                        Library:SafeCall(Dropdown.Callback, Dropdown.Value)
                    end
                end

                OptionData.Button:Connect("MouseButton1Down", function()
                    OptionData:Set()
                end)

                Dropdown.Options[OptionData.Name] = OptionData
                Dropdown.OptionsWithIndexes[#Dropdown.OptionsWithIndexes+1] = OptionData
                OptionData:RefreshPosition(false)

                return OptionData
            end

            function Dropdown:Remove(Option)
                if Dropdown.Options[Option] then
                    Dropdown.Options[Option].Button:Clean()
                    Dropdown.Options[Option] = nil
                end
            end

            function Dropdown:Refresh(List, DefaultVal)
                local OptionsToRemove = {}
                for Name, _ in pairs(Dropdown.Options) do
                    table.insert(OptionsToRemove, Name)
                end
                for _, Name in ipairs(OptionsToRemove) do
                    Dropdown:Remove(Name)
                end
                Dropdown.Options = {}
                Dropdown.OptionsWithIndexes = {}
                for Index, Value in ipairs(List) do
                    Dropdown:Add(Value)
                end
                if DefaultVal then
                    Dropdown:Set(DefaultVal)
                else
                    if Dropdown.Multi then
                        Dropdown.Value = {}
                        Library.Flags[Dropdown.Flag] = Dropdown.Value
                    else
                        Dropdown.Value = nil
                        Library.Flags[Dropdown.Flag] = nil
                    end
                    Items["Value"].Instance.Text = "..."
                end
            end

            Items["RealDropdown"]:Connect("MouseButton1Down", function()
                Dropdown:SetOpen(not Dropdown.IsOpen)
            end)

            Library:Connect(UserInputService.InputBegan, function(Input)
                if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                    if Dropdown.IsOpen then
                        if Library:IsMouseOverFrame(Items["OptionHolder"]) then
                            return
                        end

                        Dropdown:SetOpen(false)
                    end
                end
            end)

            Items["RealDropdown"]:Connect("Changed", function(Property)
                if Property == "AbsolutePosition" and Dropdown.IsOpen then
                    Dropdown.IsOpen = not Library:IsClipped(Items["OptionHolder"].Instance, Dropdown.Section.Items["Section"].Instance.Parent)
                    Items["OptionHolder"].Instance.Visible = Dropdown.IsOpen
                end
            end)

            for Index, Value in Dropdown.Items do 
                Dropdown:Add(Value)
            end

            if Dropdown.Default then 
                Dropdown:Set(Dropdown.Default)
            end

            Library.SetFlags[Dropdown.Flag] = function(Value)
                Dropdown:Set(Value)
            end

            Dropdown.Section.Elements[#Dropdown.Section.Elements+1] = Dropdown
            return Dropdown
        end

        Library.Sections.Label = function(self, Name)
            local Label = {
                Window = self.Window,
                Page = self.Page,
                Section = self,

                Name = Name or "Label"
            }

            local Items = { } do 
                Items["Label"] = Instances:Create("Frame", {
                    Parent = Label.Section.Items["Content"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 0, 20),
                    BorderColor3 = FromRGB(0, 0, 0),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Items["Text"] = Instances:Create("TextLabel", {
                    Parent = Items["Label"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.30000001192092896,
                    Text = Label.Name,
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(0, 0, 0, 15),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 30, 0, 5),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Text"]:AddToTheme({TextColor3 = "Text"})          
            end

            --Label.Section.Items["Fade"].Instance.Size = UDim2New(1, 0, 0, Label.Section.Items["Content"].Instance.AbsoluteSize.X - 180)

            function Label:SetText(Text)
                Text = tostring(Text)
                Items["Text"].Instance.Text = Text
            end

            function Label:SetVisibility(Bool)
                Items["Label"].Instance.Visible = Bool
            end

            function Label:RefreshPosition(Bool)
                if Bool then 
                    Items["Text"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0, 5)})

                    if Items["SubElements"] then
                        Items["SubElements"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0, 30)})
                        Tween:Create(Items["Label"].Instance:FindFirstChild("nig"), TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(1, -16, 1, -6)}, true)
                    end
                else 
                    Items["Text"].Instance.Position = UDim2New(0, 30, 0, 5)

                    if Items["SubElements"] then
                        Items["SubElements"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 30, 0, 30)})
                        Tween:Create(Items["Label"].Instance:FindFirstChild("nig"), TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(1, 30, 1, -6)}, true)
                    end
                end
            end

            function Label:Colorpicker(Data)
                Data = Data or { }

                local Colorpicker = {
                    Window = Label.Window,
                    Page = Label.Page,
                    Section = Label.Section,

                    Flag = Data.Flag or Data.flag or Library:NextFlag(),
                    Default = Data.Default or Data.default or Color3.fromRGB(255, 255, 255),
                    Callback = Data.Callback or Data.callback or function() end,
                    Alpha = Data.Alpha or Data.alpha or false
                }

                if not Items["SubElements"] then
                    Items["SubElements"] = Instances:Create("Frame", {
                        Parent = Items["Label"].Instance,
                        Name = "\0",
                        Size = UDim2New(1, 0, 0, 30),
                        Position = UDim2New(0, 0, 0, 30),
                        BorderColor3 = FromRGB(0, 0, 0),
                        ZIndex = 2,
                        BorderSizePixel = 0,
                        BackgroundColor3 = FromRGB(27, 26, 29)
                    })  Items["SubElements"]:AddToTheme({BackgroundColor3 = "Element"})
                    
                    Instances:Create("UICorner", {
                        Parent = Items["SubElements"].Instance,
                        Name = "\0",
                        CornerRadius = UDimNew(0, 5)
                    })
                    
                    Instances:Create("UIListLayout", {
                        Parent = Items["SubElements"].Instance,
                        Name = "\0",
                        VerticalAlignment = Enum.VerticalAlignment.Center,
                        FillDirection = Enum.FillDirection.Horizontal,
                        Padding = UDimNew(0, 5),
                        SortOrder = Enum.SortOrder.LayoutOrder
                    })

                    Instances:Create("UIPadding", {
                        Parent = Items["SubElements"].Instance,
                        Name = "\0",
                        PaddingLeft = UDimNew(0, 6)
                    })                
                end

                --Label.Section.Items["Fade"].Instance.Size = UDim2New(1, 0, 0, Label.Section.Items["Content"].Instance.AbsoluteSize.X - 180)

                local NewColorpicker, ColorpickerItems = Library:CreateColorpicker({
                    Parent = Items["SubElements"],
                    Page = Colorpicker.Page,
                    Section = Colorpicker.Section,
                    Flag = Colorpicker.Flag,
                    Default = Colorpicker.Default,
                    Callback = Colorpicker.Callback,
                    Parent2 = Items["Label"],
                    Alpha = Colorpicker.Alpha
                })

                return NewColorpicker
            end

            Label.Section.Elements[#Label.Section.Elements+1] = Label
            return Label
        end

        Library.Sections.Keybind = function(self, Data)
            Data = Data or { }

            local Keybind = {
                Window = self.Window,
                Page = self.Page,
                Section = self,

                Name = Data.Name or Data.name or "Keybind",
                Flag = Data.Flag or Data.flag or Library:NextFlag(),
                Default = Data.Default or Data.default or Enum.KeyCode.RightShift,
                Callback = Data.Callback or Data.callback or function() end,
                Mode = Data.Mode or Data.mode or Enum.KeyCode.RightShift,

                Value = "",
                ModeSelected = "",
                Toggled = false,
                Picking = false
            }

            local Items = { } do
                Items["Label"] = Instances:Create("Frame", {
                    Parent = Keybind.Section.Items["Content"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 0, 20),
                    BorderColor3 = FromRGB(0, 0, 0),
                    BorderSizePixel = 0,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Items["SubElements"] = Instances:Create("Frame", {
                    Parent = Items["Label"].Instance,
                    Name = "\0",
                    Size = UDim2New(1, 0, 0, 30),
                    Position = UDim2New(0, 0, 0, 30),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(27, 26, 29)
                })  Items["SubElements"]:AddToTheme({BackgroundColor3 = "Element"})
                
                Instances:Create("UICorner", {
                    Parent = Items["SubElements"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 5)
                })
                
                Instances:Create("UIListLayout", {
                    Parent = Items["SubElements"].Instance,
                    Name = "\0",
                    VerticalAlignment = Enum.VerticalAlignment.Center,
                    FillDirection = Enum.FillDirection.Horizontal,
                    Padding = UDimNew(0, 5),
                    SortOrder = Enum.SortOrder.LayoutOrder
                })
                
                Instances:Create("UIPadding", {
                    Parent = Items["SubElements"].Instance,
                    Name = "\0",
                    PaddingLeft = UDimNew(0, 6)
                })
                
                Items["KeyButton"] = Instances:Create("TextButton", {
                    Parent = Items["SubElements"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.30000001192092896,
                    Text = "MouseButton2",
                    AutoButtonColor = false,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    SelectionOrder = 2,
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["KeyButton"]:AddToTheme({TextColor3 = "Text"})
                
                Items["Text"] = Instances:Create("TextLabel", {
                    Parent = Items["Label"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.30000001192092896,
                    Text = Keybind.Name,
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(0, 0, 0, 15),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 0, 0, 5),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Text"]:AddToTheme({TextColor3 = "Text"})
                
                Items["Modes"] = Instances:Create("Frame", {
                    Parent = Items["Label"].Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(1, 0),
                    Position = UDim2New(1, 0, 0, 0),
                    Size = UDim2New(0, 200, 0, 25),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(27, 26, 29)
                })  Items["Modes"]:AddToTheme({BackgroundColor3 = "Element"})
                
                Instances:Create("UICorner", {
                    Parent = Items["Modes"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 5)
                })
                
                Items["Background"] = Instances:Create("Frame", {
                    Parent = Items["Modes"].Instance,
                    Name = "\0",
                    Size = UDim2New(0.35, 0, 1, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundTransparency = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  --Items["Background"]:AddToTheme({BackgroundColor3 = "Accent"})
                
                Instances:Create("UICorner", {
                    Parent = Items["Background"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 5)
                })
                
                Instances:Create("UIGradient", {
                    Parent = Items["Background"].Instance,
                    Name = "\0",
                    Rotation = -115,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(166, 166, 166))}
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                end})
                
                Items["Toggle"] = Instances:Create("TextButton", {
                    Parent = Items["Modes"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    TextTransparency = 0.30000001192092896,
                    Text = "Toggle",
                    AutoButtonColor = false,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(0.35, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 0, 0, -1),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Toggle"]:AddToTheme({TextColor3 = function()
                    return Library.Theme.Text
                end})
                
                Items["Hold"] = Instances:Create("TextButton", {
                    Parent = Items["Modes"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.20000000298023224,
                    Text = "Hold",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AutoButtonColor = false,
                    AnchorPoint = Vector2New(0, 0),
                    Size = UDim2New(0.35, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0.35, 0, 0, -1),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Hold"]:AddToTheme({TextColor3 = function()
                    return Library.Theme.Text
                end})        
                
                Items["Always"] = Instances:Create("TextButton", {
                    Parent = Items["Modes"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.20000000298023224,
                    Text = "Always",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AutoButtonColor = false,
                    AnchorPoint = Vector2New(0, 0),
                    Size = UDim2New(0.4, 0, 1, 0),
                    BackgroundTransparency = 1,
                    Position = UDim2New(0.7, -12, 0, -1),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Always"]:AddToTheme({TextColor3 = function()
                    return Library.Theme.Text
                end})              
            end

            --Keybind.Section.Items["Fade"].Instance.Size = UDim2New(1, 0, 0, Keybind.Section.Items["Content"].Instance.AbsoluteSize.X - 180)

            local KeyListItem 

            if Library.KeyList then 
                KeyListItem = Library.KeyList:Add("", "")
            end

            local Update = function()
                if KeyListItem then 
                    KeyListItem:Set(Data.Name, Keybind.Value)
                    KeyListItem:SetStatus(Keybind.Toggled)
                end
            end

            function Keybind:RefreshPosition(Bool)
                if Bool then 
                    Items["Text"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0, 5)})
                    Items["SubElements"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0, 30)})
                    Items["Modes"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(1, 0, 0, 0)})
                else
                    Items["Text"].Instance.Position = UDim2New(0, 30, 0, 5)
                    Items["SubElements"].Instance.Position = UDim2New(0, 30, 0, 30)
                    Items["Modes"].Instance.Position = UDim2New(1, 30, 0, 0)
                end
            end

            function Keybind:SetMode(Mode) -- hard coded
                if Mode == "Toggle" then
                    Items["Background"]:Tween(TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0, 0), Size = UDim2New(0.35, 0, 1, 0)})
                    Items["Toggle"]:ChangeItemTheme({TextColor3 = function()
                        return FromRGB(0, 0, 0)
                    end})
                    Items["Toggle"]:Tween(nil, {TextColor3 = FromRGB(0, 0, 0)})

                    Items["Hold"]:ChangeItemTheme({TextColor3 = function()
                        return Library.Theme.Text
                    end})
                    Items["Hold"]:Tween(nil, {TextColor3 = Library.Theme.Text})

                    Items["Always"]:ChangeItemTheme({TextColor3 = function()
                        return Library.Theme.Text
                    end})
                    Items["Always"]:Tween(nil, {TextColor3 = Library.Theme.Text})
                elseif Mode == "Hold" then
                    Items["Background"]:Tween(TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(0.35, 0, 0, 0), Size = UDim2New(0.35, 0, 1, 0)})
                
                    Items["Toggle"]:ChangeItemTheme({TextColor3 = function()
                        return Library.Theme.Text
                    end})
                    Items["Toggle"]:Tween(nil, {TextColor3 = Library.Theme.Text})

                    Items["Hold"]:ChangeItemTheme({TextColor3 = function()
                        return FromRGB(0, 0, 0)
                    end})
                    Items["Hold"]:Tween(nil, {TextColor3 = FromRGB(0, 0, 0)})

                    Items["Always"]:ChangeItemTheme({TextColor3 = function()
                        return Library.Theme.Text
                    end})
                    Items["Always"]:Tween(nil, {TextColor3 = Library.Theme.Text})
                elseif Mode == "Always" then
                    Items["Background"]:Tween(TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2New(0.7, 0, 0, 0), Size = UDim2New(0.3, 0, 1, 0)})
                
                    Items["Toggle"]:ChangeItemTheme({TextColor3 = function()
                        return Library.Theme.Text
                    end})
                    Items["Toggle"]:Tween(nil, {TextColor3 = Library.Theme.Text})

                    Items["Hold"]:ChangeItemTheme({TextColor3 = function()
                        return Library.Theme.Text
                    end})
                    Items["Hold"]:Tween(nil, {TextColor3 = Library.Theme.Text})

                    Items["Always"]:ChangeItemTheme({TextColor3 = function()
                        return FromRGB(0, 0, 0)
                    end})
                    Items["Always"]:Tween(nil, {TextColor3 = FromRGB(0, 0, 0)})
                end

                Library.Flags[Keybind.Flag] = {
                    Mode = Keybind.ModeSelected,
                    Key = Keybind.Key,
                    Toggled = Keybind.Toggled
                }

                if Data.Callback then 
                    Library:SafeCall(Data.Callback, Keybind.Toggled)
                end
            end

            function Keybind:Press(Bool)
                if Keybind.ModeSelected == "Toggle" then 
                    Keybind.Toggled = not Keybind.Toggled
                elseif Keybind.ModeSelected == "Hold" then 
                    Keybind.Toggled = Bool
                elseif Keybind.ModeSelected == "Always" then 
                    Keybind.Toggled = true
                end

                Library.Flags[Keybind.Flag] = {
                    Mode = Keybind.ModeSelected,
                    Key = Keybind.Key,
                    Toggled = Keybind.Toggled
                }

                if Data.Callback then 
                    Library:SafeCall(Data.Callback, Keybind.Toggled)
                end

                Update()
            end

            function Keybind:Get()
                return Keybind.Key, Keybind.ModeSelected, Keybind.Toggled
            end

            function Keybind:Set(Key)
                if StringFind(tostring(Key), "Enum") then 
                    Keybind.Key = tostring(Key)

                    local KeyName
                    if type(Key) == "string" then
                        KeyName = Key:match("[^%.]+$") or "None"
                        if KeyName == "Backspace" then KeyName = "None" end
                    else
                        KeyName = Key.Name == "Backspace" and "None" or Key.Name
                    end

                    local KeyString = Keys[Keybind.Key] or StringGSub(KeyName or "", "Enum.", "") or "None"
                    local TextToDisplay = StringGSub(StringGSub(KeyString, "KeyCode.", ""), "UserInputType.", "") or "None"

                    Keybind.Value = TextToDisplay
                    Items["KeyButton"].Instance.Text = TextToDisplay

                    Library.Flags[Keybind.Flag] = {
                        Mode = Keybind.ModeSelected,
                        Key = Keybind.Key,
                        Toggled = Keybind.Toggled
                    }

                    if Data.Callback then 
                        Library:SafeCall(Data.Callback, Keybind.Toggled)
                    end

                    Update()
                elseif type(Key) == "table" and Key.Key ~= nil then
                    Keybind.Key = tostring(Key.Key)

                    if Key.Mode or Key.ModeSelected then
                        Keybind:SetMode(Key.Mode or Key.ModeSelected)
                    else
                        Keybind:SetMode("Toggle")
                    end

                    local RealKey = type(Key.Key) == "string" and Key.Key:match("[^%.]+$") or (Key.Key == "Backspace" and "None" or (Key.Key and Key.Key.Name))
                    local KeyString = Keys[Keybind.Key] or StringGSub(tostring(RealKey or Key.Key or ""), "Enum.", "") or RealKey
                    local TextToDisplay = StringGSub(StringGSub(KeyString or "", "KeyCode.", ""), "UserInputType.", "") or "None"

                    Keybind.Value = TextToDisplay
                    Items["KeyButton"].Instance.Text = TextToDisplay

                    if Data.Callback then 
                        Library:SafeCall(Data.Callback, Keybind.Toggled)
                    end

                    Update()
                elseif TableFind({"Toggle", "Hold", "Always"}, Key) then
                    Keybind.ModeSelected = Key
                    Keybind:SetMode(Key)

                    if Data.Callback then 
                        Library:SafeCall(Data.Callback, Keybind.Toggled)
                    end

                    Update()
                end

                --Items["KeyButton"].Instance.Position = UDim2New(0, Data.Text.Instance.TextBounds.X + 12, 0, 0)
                Keybind.Picking = false
            end

            Items["KeyButton"]:Connect("MouseButton1Click", function()
                Keybind.Picking = true 

                Items["KeyButton"].Instance.Text = "."
                Library:Thread(function()
                    local Count = 1

                    while true do 
                        if not Keybind.Picking then 
                            break
                        end

                        if Count == 4 then
                            Count = 1
                        end

                        Items["KeyButton"].Instance.Text = Count == 1 and "." or Count == 2 and ".." or Count == 3 and "..."
                        Count += 1
                        task.wait(0.35)
                    end
                end)

                local InputBegan
                InputBegan = UserInputService.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.Keyboard then 
                        Keybind:Set(Input.KeyCode)
                    else
                        Keybind:Set(Input.UserInputType)
                    end

                    InputBegan:Disconnect()
                    InputBegan = nil
                end)
            end)

            Library:Connect(UserInputService.InputBegan, function(Input)
                if Keybind.Value == "None" then
                    return
                end

                if tostring(Input.KeyCode) == Keybind.Key then
                    if Keybind.ModeSelected == "Toggle" then 
                        Keybind:Press()
                    elseif Keybind.ModeSelected == "Hold" then 
                        Keybind:Press(true)
                    elseif Keybind.ModeSelected == "Always" then 
                        Keybind:Press(true)
                    end
                elseif tostring(Input.UserInputType) == Keybind.Key then
                    if Keybind.ModeSelected == "Toggle" then 
                        Keybind:Press()
                    elseif Keybind.ModeSelected == "Hold" then 
                        Keybind:Press(true)
                    elseif Keybind.ModeSelected == "Always" then 
                        Keybind:Press(true)
                    end
                end

                if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                    if not Keybind.IsOpen then
                        return
                    end

                    if Library:IsMouseOverFrame(Items["KeybindWindow"]) or Library:IsMouseOverFrame(Items["OptionHolder"]) then
                        return
                    end

                    Keybind:SetOpen(false)
                end
            end)

            Library:Connect(UserInputService.InputEnded, function(Input)
                if Keybind.Value == "None" then
                    return
                end

                if tostring(Input.KeyCode) == Keybind.Key then
                    if Keybind.ModeSelected == "Hold" then 
                        Keybind:Press(false)
                    elseif Keybind.ModeSelected == "Always" then 
                        Keybind:Press(true)
                    end
                elseif tostring(Input.UserInputType) == Keybind.Key then
                    if Keybind.ModeSelected == "Hold" then 
                        Keybind:Press(false)
                    elseif Keybind.ModeSelected == "Always" then 
                        Keybind:Press(true)
                    end
                end
            end)

            Items["Toggle"]:Connect("MouseButton1Down", function()
                Keybind.ModeSelected = "Toggle"
                Keybind:SetMode("Toggle")
            end)

            Items["Hold"]:Connect("MouseButton1Down", function()
                Keybind.ModeSelected = "Hold"
                Keybind:SetMode("Hold")
            end)

            Items["Always"]:Connect("MouseButton1Down", function()
                Keybind.ModeSelected = "Always"
                Keybind:SetMode("Always")
            end)

            if Keybind.Default then 
                Keybind:Set({
                    Mode = Keybind.Mode or "Toggle",
                    Key = Keybind.Default,
                })
            end

            Library.SetFlags[Keybind.Flag] = function(Value)
                Keybind:Set(Value)
            end

            Keybind.Section.Elements[#Keybind.Section.Elements+1] = Keybind
            return Keybind 
        end

        Library.Sections.Sub2keybind = function(self, Data)
            Data = Data or { }

            local Sub2keybind = {
                Window = self.Window,
                Page = self.Page,
                Section = self,

                Name = Data.Name or Data.name or "Keybind",
                Flag = Data.Flag or Data.flag or Library:NextFlag(),
                Default = Data.Default or Data.default or Enum.KeyCode.RightShift,
                Callback = Data.Callback or Data.callback or function() end,
                Mode = Data.Mode or Data.mode or "Toggle",

                Value = "",
                ModeSelected = "Toggle",
                Toggled = false,
                Picking = false,
                Key = "",
                ModeMenuOpen = false
            }
            Sub2keybind.ModeSelected = Sub2keybind.Mode

            local UpdateSub2ModeVisuals
            local Items = { } do
                Items["Label"] = Instances:Create("Frame", {
                    Parent = Sub2keybind.Section.Items["Content"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 0, 20),
                    BorderColor3 = FromRGB(0, 0, 0),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })

                Items["Text"] = Instances:Create("TextLabel", {
                    Parent = Items["Label"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.30000001192092896,
                    Text = Sub2keybind.Name,
                    AutomaticSize = Enum.AutomaticSize.X,
                    Size = UDim2New(0, 0, 0, 15),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 0, 0, 2),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Text"]:AddToTheme({TextColor3 = "Text"})

                Items["KeyContainer"] = Instances:Create("Frame", {
                    Parent = Items["Label"].Instance,
                    Name = "\0",
                    Size = UDim2New(0, 70, 0, 18),
                    AnchorPoint = Vector2New(1, 0),
                    Position = UDim2New(1, 0, 0, 1),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(27, 26, 29)
                })  Items["KeyContainer"]:AddToTheme({BackgroundColor3 = "Element"})
                Instances:Create("UICorner", { Parent = Items["KeyContainer"].Instance, Name = "\0", CornerRadius = UDimNew(0, 4) })

                Items["KeyButton"] = Instances:Create("TextButton", {
                    Parent = Items["KeyContainer"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.30000001192092896,
                    Text = "None",
                    AutoButtonColor = false,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 0, 1, 0),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    TextSize = 12,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["KeyButton"]:AddToTheme({TextColor3 = "Text"})

                local ModeMenuFrame = Instances:Create("Frame", {
                    Parent = Library.UnusedHolder.Instance,
                    Name = "\0",
                    Visible = false,
                    ClipsDescendants = false,
                    Size = UDim2New(0, 55, 0, 44),
                    Position = UDim2New(0, 0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 500,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(27, 26, 29)
                })  ModeMenuFrame:AddToTheme({BackgroundColor3 = "Element"})
                Instances:Create("UICorner", { Parent = ModeMenuFrame.Instance, Name = "\0", CornerRadius = UDimNew(0, 4) })
                Instances:Create("UIListLayout", {
                    Parent = ModeMenuFrame.Instance,
                    Name = "\0",
                    Padding = UDimNew(0, 2),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    VerticalAlignment = Enum.VerticalAlignment.Top
                })
                Instances:Create("UIPadding", {
                    Parent = ModeMenuFrame.Instance,
                    Name = "\0",
                    PaddingTop = UDimNew(0, 3),
                    PaddingBottom = UDimNew(0, 3),
                    PaddingLeft = UDimNew(0, 4),
                    PaddingRight = UDimNew(0, 4)
                })
                local TweenInfoHover = TweenInfo.new(Library.Tween.Time + 0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
                local AccentColor = Library.Theme.Accent or FromRGB(255, 80, 80)
                local function CreateModeOption(Name, IsSelected)
                    local Row = Instances:Create("TextButton", {
                        Parent = ModeMenuFrame.Instance,
                        Name = "\0",
                        FontFace = Library.Font,
                        TextColor3 = IsSelected and FromRGB(240, 240, 240) or FromRGB(160, 160, 165),
                        Text = "",
                        AutoButtonColor = false,
                        Size = UDim2New(1, -8, 0, 16),
                        BorderSizePixel = 0,
                        ZIndex = 501,
                        TextSize = 12,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        BackgroundColor3 = FromRGB(0, 0, 0),
                        BackgroundTransparency = 1
                    })
                    Row.Instance.LayoutOrder = Name == "Toggle" and 0 or 1
                    local CircleContainer = Instances:Create("Frame", {
                        Parent = Row.Instance,
                        Name = "\0",
                        Size = UDim2New(0, 14, 0, 16),
                        Position = UDim2New(0, 0, 0, 0),
                        BorderSizePixel = 0,
                        BackgroundTransparency = 1
                    })
                    local Circle = Instances:Create("Frame", {
                        Parent = CircleContainer.Instance,
                        Name = "\0",
                        Size = UDim2New(0, 5, 0, 5),
                        AnchorPoint = Vector2New(0.5, 0.5),
                        Position = UDim2New(0.5, 0, 0.5, 0),
                        BorderColor3 = FromRGB(0, 0, 0),
                        ZIndex = 502,
                        BorderSizePixel = 0,
                        BackgroundColor3 = AccentColor,
                        BackgroundTransparency = IsSelected and 0 or 1
                    })
                    Instances:Create("UICorner", { Parent = Circle.Instance, Name = "\0", CornerRadius = UDimNew(1, 0) })
                    local CircleStroke = Instances:Create("UIStroke", {
                        Parent = Circle.Instance,
                        Name = "\0",
                        Color = AccentColor,
                        Thickness = 1,
                        Transparency = IsSelected and 1 or 0
                    })
                    local Label = Instances:Create("TextLabel", {
                        Parent = Row.Instance,
                        Name = "\0",
                        FontFace = Library.Font,
                        TextColor3 = IsSelected and FromRGB(240, 240, 240) or FromRGB(160, 160, 165),
                        Text = Name,
                        Size = UDim2New(1, -18, 0, 16),
                        Position = UDim2New(0, 14, 0, 0),
                        BackgroundTransparency = 1,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        TextSize = 12,
                        ZIndex = 502
                    })
                    Row:OnHover(function()
                        Label:Tween(TweenInfoHover, {TextColor3 = FromRGB(255, 255, 255)})
                    end)
                    Row:OnHoverLeave(function()
                        local active = (Name == "Toggle" and Sub2keybind.ModeSelected == "Toggle") or (Name == "Hold" and Sub2keybind.ModeSelected == "Hold")
                        Label:Tween(TweenInfoHover, {TextColor3 = active and FromRGB(240, 240, 240) or FromRGB(160, 160, 165)})
                    end)
                    return { Row = Row, Circle = Circle, CircleStroke = CircleStroke, Label = Label }
                end
                local MenuToggle = CreateModeOption("Toggle", Sub2keybind.ModeSelected == "Toggle")
                local MenuHold = CreateModeOption("Hold", Sub2keybind.ModeSelected == "Hold")
                local function UpdateModeVisuals()
                    local toggleSel = Sub2keybind.ModeSelected == "Toggle"
                    local holdSel = Sub2keybind.ModeSelected == "Hold"
                    MenuToggle.Circle.Instance.BackgroundTransparency = toggleSel and 0 or 1
                    MenuToggle.CircleStroke.Instance.Transparency = toggleSel and 1 or 0
                    MenuToggle.Label.Instance.TextColor3 = toggleSel and FromRGB(240, 240, 240) or FromRGB(160, 160, 165)
                    MenuHold.Circle.Instance.BackgroundTransparency = holdSel and 0 or 1
                    MenuHold.CircleStroke.Instance.Transparency = holdSel and 1 or 0
                    MenuHold.Label.Instance.TextColor3 = holdSel and FromRGB(240, 240, 240) or FromRGB(160, 160, 165)
                end
                UpdateSub2ModeVisuals = UpdateModeVisuals
                local function CloseModeMenu()
                    if not Sub2keybind.ModeMenuOpen then return end
                    Sub2keybind.ModeMenuOpen = false
                    ModeMenuFrame.Instance.Visible = false
                    ModeMenuFrame.Instance.Parent = Library.UnusedHolder.Instance
                end
                local function SetMode(Mode)
                    Sub2keybind.ModeSelected = Mode
                    Sub2keybind.Mode = Mode
                    UpdateModeVisuals()
                    Library.Flags[Sub2keybind.Flag] = { Mode = Sub2keybind.ModeSelected, Key = Sub2keybind.Key, Toggled = Sub2keybind.Toggled }
                end
                MenuToggle.Row:Connect("MouseButton1Click", function()
                    SetMode("Toggle")
                    CloseModeMenu()
                end)
                MenuHold.Row:Connect("MouseButton1Click", function()
                    SetMode("Hold")
                    CloseModeMenu()
                end)
                local function OpenModeMenu()
                    if Sub2keybind.ModeMenuOpen then CloseModeMenu() return end
                    Sub2keybind.ModeMenuOpen = true
                    ModeMenuFrame.Instance.Parent = Library.Holder.Instance
                    ModeMenuFrame.Instance.Visible = true
                    local ContainerPos = Items["KeyContainer"].Instance.AbsolutePosition
                    local ContainerSize = Items["KeyContainer"].Instance.AbsoluteSize
                    ModeMenuFrame.Instance.Position = UDim2New(0, ContainerPos.X + ContainerSize.X - 55, 0, ContainerPos.Y + ContainerSize.Y + 4)
                end
                Items["KeyContainer"]:Connect("InputBegan", function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton2 then OpenModeMenu() end
                end)
                Items["KeyButton"]:Connect("InputBegan", function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton2 then OpenModeMenu() end
                end)
                Library:Connect(UserInputService.InputBegan, function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.MouseButton2 or Input.UserInputType == Enum.UserInputType.Touch then
                        if Sub2keybind.ModeMenuOpen and not Library:IsMouseOverFrame(ModeMenuFrame) and not Library:IsMouseOverFrame(Items["KeyContainer"]) then
                            CloseModeMenu()
                        end
                    end
                end)
            end

            local KeyListItem
            if Library.KeyList then KeyListItem = Library.KeyList:Add(Sub2keybind.Name, "") end

            local function UpdateKeyList()
                if KeyListItem then KeyListItem:Set(Sub2keybind.Name, Sub2keybind.Value) KeyListItem:SetStatus(Sub2keybind.Toggled) end
            end

            local function SetKeyDisplay()
                local KeyStr = Keys[Sub2keybind.Key] or StringGSub(StringGSub(tostring(Sub2keybind.Key), "Enum%.KeyCode%.", ""), "Enum%.UserInputType%.", "") or "None"
                Sub2keybind.Value = KeyStr
                Items["KeyButton"].Instance.Text = KeyStr
                UpdateKeyList()
            end

            function Sub2keybind:Set(Key)
                if StringFind(tostring(Key), "Enum") then
                    Sub2keybind.Key = tostring(Key)
                    local KeyName
                    if type(Key) == "string" then
                        KeyName = Key:match("[^%.]+$") or "None"
                        if KeyName == "Backspace" then KeyName = "None" end
                    else
                        KeyName = Key.Name == "Backspace" and "None" or Key.Name
                    end
                    local KeyStr = Keys[Sub2keybind.Key] or StringGSub(StringGSub(KeyName or "", "KeyCode%.", ""), "UserInputType%.", "") or KeyName or "None"
                    Sub2keybind.Value = KeyStr
                    Items["KeyButton"].Instance.Text = KeyStr
                    Library.Flags[Sub2keybind.Flag] = { Mode = Sub2keybind.ModeSelected, Key = Sub2keybind.Key, Toggled = Sub2keybind.Toggled }
                    if Data.Callback then Library:SafeCall(Data.Callback, Sub2keybind.Toggled) end
                    Sub2keybind.Picking = false
                    UpdateKeyList()
                elseif type(Key) == "table" and Key.Key ~= nil then
                    Sub2keybind.Key = tostring(Key.Key)
                    if Key.Mode or Key.ModeSelected then
                        Sub2keybind.ModeSelected = Key.Mode or Key.ModeSelected
                        Sub2keybind.Mode = Sub2keybind.ModeSelected
                        if UpdateSub2ModeVisuals then UpdateSub2ModeVisuals() end
                    end
                    SetKeyDisplay()
                    Library.Flags[Sub2keybind.Flag] = { Mode = Sub2keybind.ModeSelected, Key = Sub2keybind.Key, Toggled = Sub2keybind.Toggled }
                    if Data.Callback then Library:SafeCall(Data.Callback, Sub2keybind.Toggled) end
                end
                Sub2keybind.Picking = false
            end

            function Sub2keybind:Press(Bool)
                if Sub2keybind.ModeSelected == "Toggle" then Sub2keybind.Toggled = not Sub2keybind.Toggled
                elseif Sub2keybind.ModeSelected == "Hold" then Sub2keybind.Toggled = Bool
                elseif Sub2keybind.ModeSelected == "Always" then Sub2keybind.Toggled = true end
                Library.Flags[Sub2keybind.Flag] = { Mode = Sub2keybind.ModeSelected, Key = Sub2keybind.Key, Toggled = Sub2keybind.Toggled }
                if Data.Callback then Library:SafeCall(Data.Callback, Sub2keybind.Toggled) end
                UpdateKeyList()
            end

            function Sub2keybind:Get()
                return Sub2keybind.Key, Sub2keybind.ModeSelected, Sub2keybind.Toggled
            end

            function Sub2keybind:RefreshPosition(Bool)
                if Bool then
                    Items["Text"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0, 2)})
                    Items["KeyContainer"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(1, 0, 0, 1)})
                else
                    Items["Text"].Instance.Position = UDim2New(0, 30, 0, 2)
                    Items["KeyContainer"].Instance.Position = UDim2New(1, 30, 0, 1)
                end
            end

            Items["KeyButton"]:Connect("MouseButton1Click", function()
                Sub2keybind.Picking = true
                Items["KeyButton"].Instance.Text = "..."
                local InputBegan
                InputBegan = UserInputService.InputBegan:Connect(function(Input)
                    if Input.UserInputType == Enum.UserInputType.Keyboard then Sub2keybind:Set(Input.KeyCode)
                    else Sub2keybind:Set(Input.UserInputType) end
                    if InputBegan then InputBegan:Disconnect() InputBegan = nil end
                end)
            end)

            Library:Connect(UserInputService.InputBegan, function(Input)
                if Sub2keybind.Value == "None" or Sub2keybind.Picking then return end
                if tostring(Input.KeyCode) == Sub2keybind.Key or tostring(Input.UserInputType) == Sub2keybind.Key then
                    if Sub2keybind.ModeSelected == "Toggle" then Sub2keybind:Press()
                    elseif Sub2keybind.ModeSelected == "Hold" then Sub2keybind:Press(true)
                    elseif Sub2keybind.ModeSelected == "Always" then Sub2keybind:Press(true) end
                end
            end)
            Library:Connect(UserInputService.InputEnded, function(Input)
                if Sub2keybind.Value == "None" then return end
                if tostring(Input.KeyCode) == Sub2keybind.Key or tostring(Input.UserInputType) == Sub2keybind.Key then
                    if Sub2keybind.ModeSelected == "Hold" then Sub2keybind:Press(false)
                    elseif Sub2keybind.ModeSelected == "Always" then Sub2keybind:Press(true) end
                end
            end)

            if Sub2keybind.Default then Sub2keybind:Set({ Mode = Data.Mode or "Toggle", Key = Sub2keybind.Default }) end
            Library.SetFlags[Sub2keybind.Flag] = function(Value) Sub2keybind:Set(Value) end

            Sub2keybind.Section.Elements[#Sub2keybind.Section.Elements+1] = Sub2keybind
            return Sub2keybind
        end

        Library.Sections.Textbox = function(self, Data)
            Data = Data or { }

            local Textbox = {
                Window = self.Window,
                Page = self.Page,
                Section = self,

                Flag = Data.Flag or Data.flag or Library:NextFlag(),
                Default = Data.Default or Data.default or "",
                Callback = Data.Callback or Data.callback or function() end,
                Placeholder = Data.Placeholder or Data.placeholder or "Placeholder",
                Numeric = Data.Numeric or Data.numeric or false,
                Finished = Data.Finished or Data.finished or false,

                Value = ""
            }

            local Items = { } do 
                Items["Textbox"] = Instances:Create("Frame", {
                    Parent = Textbox.Section.Items["Content"].Instance,
                    Name = "\0",
                    Active = true,
                    BorderColor3 = FromRGB(0, 0, 0),
                    BackgroundTransparency = 1,
                    Selectable = true,
                    Size = UDim2New(1, 0, 0, 32),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(27, 26, 29)
                }) 
                
                Instances:Create("UICorner", {
                    Parent = Items["Textbox"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })
                
                Items["Background"] = Instances:Create("Frame", {
                    Parent = Items["Textbox"].Instance,
                    Name = "\0",
                    Active = true,
                    BorderColor3 = FromRGB(0, 0, 0),
                    Size = UDim2New(1, 0, 1, 0),
                    Selectable = true,
                    ZIndex = 2,
                    ClipsDescendants = true,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(27, 26, 29)
                })  Items["Background"]:AddToTheme({BackgroundColor3 = "Element"})
                
                Instances:Create("UICorner", {
                    Parent = Items["Background"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 4)
                })
                
                Items["Input"] = Instances:Create("TextBox", {
                    Parent = Items["Background"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(240, 240, 240),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    ZIndex = 2,
                    Size = UDim2New(1, -20, 0, 15),
                    Position = UDim2New(0, 10, 0, 8),
                    BorderSizePixel = 0,
                    BackgroundTransparency = 1,
                    PlaceholderColor3 = FromRGB(185, 185, 185),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    PlaceholderText = Textbox.Placeholder,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  Items["Input"]:AddToTheme({TextColor3 = "Text"})               
            end
            
            function Textbox:Get()
                return Textbox.Value
            end

            function Textbox:SetVisibility(Bool)
                Items["Textbox"].Instance.Visible = Bool
            end

            function Textbox:RefreshPosition(Bool)
                if Bool then
                    Items["Background"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0, 0)})
                else
                    Items["Background"].Instance.Position = UDim2New(0, 30, 0, 0)
                end
            end

            function Textbox:Set(Value)
                if Textbox.Numeric then
                    if (not tonumber(Value)) and StringLen(tostring(Value)) > 0 then
                        Value = Textbox.Value
                    end
                end

                Textbox.Value = Value
                Items["Input"].Instance.Text = Value
                Library.Flags[Textbox.Flag] = Value

                if Textbox.Callback then
                    Library:SafeCall(Textbox.Callback, Value)
                end
            end

            if Textbox.Finished then 
                Items["Input"]:Connect("FocusLost", function(PressedEnterQuestionMark)
                    if PressedEnterQuestionMark then
                        Textbox:Set(Items["Input"].Instance.Text)
                    end
                end)
            else
                Library:Connect(Items["Input"].Instance:GetPropertyChangedSignal("Text"), function()
                    Textbox:Set(Items["Input"].Instance.Text)
                end)
            end

            if Textbox.Default then
                Textbox:Set(Textbox.Default)
            end

            Library.SetFlags[Textbox.Flag] = function(Value)
                Textbox:Set(Value)
            end

            Textbox.Section.Elements[#Textbox.Section.Elements+1] = Textbox
            return Textbox
        end

        Library.Sections.Listbox = function(self, Data)
            -- basically just dropdowns so i jsut copied dropdowns
            Data = Data or { }

            local Dropdown = {
                Window = self.Window,
                Page = self.Page,
                Section = self,

                Flag = Data.Flag or Data.flag or Library:NextFlag(),
                Items = Data.Items or Data.items or { "One", "Two", "Three" },
                Default = Data.Default or Data.default or nil,
                Callback = Data.Callback or Data.callback or function() end,
                Size = Data.Size or Data.size or 125,
                Multi = Data.Multi or Data.multi or false,

                Value = { },
                Options = { },
                IsOpen = false
            }

            local Items = { } do 
                Items["Listbox"] = Instances:Create("Frame", {
                    Parent = Dropdown.Section.Items["Content"].Instance,
                    Name = "\0",
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 0, Dropdown.Size),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                Items["Search"] = Instances:Create("TextBox", {
                    Parent = Items["Listbox"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    CursorPosition = -1,
                    TextColor3 = FromRGB(240, 240, 240),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    ZIndex = 2,
                    Size = UDim2New(1, 0, 0, 30),
                    BorderSizePixel = 0,
                    PlaceholderColor3 = FromRGB(185, 185, 185),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    PlaceholderText = "Search..",
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(27, 26, 29)
                })  Items["Search"]:AddToTheme({TextColor3 = "Text", BackgroundColor3 = "Element"})
                
                Instances:Create("UICorner", {
                    Parent = Items["Search"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 6)
                })
                
                Instances:Create("UIPadding", {
                    Parent = Items["Search"].Instance,
                    Name = "\0",
                    PaddingTop = UDimNew(0, 4),
                    PaddingLeft = UDimNew(0, 8)
                })

                Items["Background"] = Instances:Create("Frame", {
                    Parent = Items["Listbox"].Instance,
                    Name = "\0",
                    Active = true,
                    Size = UDim2New(1, 0, 1, -30),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Position = UDim2New(0, 0, 0, 30),
                    BackgroundColor3 = FromRGB(27, 26, 29),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                })  Items["Background"]:AddToTheme({BackgroundColor3 = "Element"})
                
                Items["Holder"] = Instances:Create("ScrollingFrame", {
                    Parent = Items["Background"].Instance,
                    Name = "\0",
                    ScrollBarImageColor3 = FromRGB(0, 0, 0),
                    Active = true,
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    ScrollBarThickness = 2,
                    Size = UDim2New(1, -4, 1, -8),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Position = UDim2New(0, 0, 0, 4),
                    BackgroundColor3 = FromRGB(27, 26, 29),
                    ZIndex = 2,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    CanvasSize = UDim2New(0, 0, 0, 0)
                })  Items["Holder"]:AddToTheme({ScrollBarImageColor3 = "Accent"})
                
                Instances:Create("UICorner", {
                    Parent = Items["Background"].Instance,
                    Name = "\0",
                    CornerRadius = UDimNew(0, 6)
                })
                
                Instances:Create("UIListLayout", {
                    Parent = Items["Holder"].Instance,
                    Name = "\0",
                    Padding = UDimNew(0, 4),
                    SortOrder = Enum.SortOrder.LayoutOrder
                })
                
                Instances:Create("UIPadding", {
                    Parent = Items["Holder"].Instance,
                    Name = "\0",
                    PaddingTop = UDimNew(0, 8),
                    PaddingBottom = UDimNew(0, 8),
                    PaddingRight = UDimNew(0, 12),
                    PaddingLeft = UDimNew(0, 8)
                })      
                
                Items["_"] = Instances:Create("Frame", {
                    Parent = Items["Listbox"].Instance,
                    Name = "\0",
                    Size = UDim2New(1, 0, 0, 10),
                    Position = UDim2New(0, 0, 0, 25),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(27, 26, 29)
                })  Items["_"]:AddToTheme({BackgroundColor3 = "Element"})

                Instances:Create("Frame", {
                    Parent = Items["_"].Instance,
                    Name = "\0",
                    Size = UDim2New(1, 0, 0, 1),
                    Position = UDim2New(0, 0, 1, -3),
                    AnchorPoint = Vector2New(0, 1),
                    BorderColor3 = FromRGB(0, 0, 0),
                    ZIndex = 2,
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(27, 26, 29),
                }):AddToTheme({BackgroundColor3 = "Outline"})
            end

            function Dropdown:Get()
                return Dropdown.Value
            end

            function Dropdown:SetVisibility(Bool)
                Items["Listbox"].Instance.Visible = Bool
            end

            function Dropdown:RefreshPosition(Bool)
                if Bool then
                    Items["Background"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0, 30)})
                    Items["Search"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0, 0)})
                    Items["_"]:Tween(TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2New(0, 0, 0, 25)})
                else
                    Items["Background"].Instance.Position = UDim2New(0, 30, 0, 30)
                    Items["Search"].Instance.Position = UDim2New(0, 30, 0, 0)
                    Items["_"].Instance.Position = UDim2New(0, 30, 0, 25)
                end
            end

            function Dropdown:Set(Option)
                if Dropdown.Multi then 
                    if type(Option) ~= "table" then 
                        return
                    end

                    Dropdown.Value = Option
                    Library.Flags[Dropdown.Flag] = Option

                    for Index, Value in Option do
                        local OptionData = Dropdown.Options[Value]
                        
                        if not OptionData then
                            continue
                        end

                        OptionData.Selected = true 
                        OptionData:Toggle("Active")
                    end
                else
                    if not Dropdown.Options[Option] then
                        return
                    end

                    local OptionData = Dropdown.Options[Option]

                    Dropdown.Value = Option
                    Library.Flags[Dropdown.Flag] = Option

                    for Index, Value in Dropdown.Options do
                        if Value ~= OptionData then
                            Value.Selected = false 
                            Value:Toggle("Inactive")
                        else
                            Value.Selected = true 
                            Value:Toggle("Active")
                        end
                    end
                end

                if Dropdown.Callback then   
                    Library:SafeCall(Dropdown.Callback, Dropdown.Value)
                end
            end

            function Dropdown:Add(Option)
                local OptionButton = Instances:Create("TextButton", {
                    Parent = Items["Holder"].Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(0, 0, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    Text = "",
                    AutoButtonColor = false,
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, 0, 0, 20),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })
                
                local OptionAccent = Instances:Create("Frame", {
                    Parent = OptionButton.Instance,
                    Name = "\0",
                    BorderColor3 = FromRGB(0, 0, 0),
                    AnchorPoint = Vector2New(0, 0.5),
                    BackgroundTransparency = 1,
                    ZIndex = 2,
                    Position = UDim2New(0, 0, 0.5, 0),
                    Size = UDim2New(0, 6, 0, 6),
                    BorderSizePixel = 0,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  --OptionAccent:AddToTheme({BackgroundColor3 = "Accent"})
                
                Instances:Create("UIGradient", {
                    Parent = OptionAccent.Instance,
                    Name = "\0",
                    Enabled = true,
                    Rotation = -115,
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(143, 143, 143))}
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                end})
                
                Instances:Create("UICorner", {
                    Parent = OptionAccent.Instance,
                    Name = "\0"
                })
                
                local OptionText = Instances:Create("TextLabel", {
                    Parent = OptionButton.Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    TextColor3 = FromRGB(255, 255, 255),
                    TextTransparency = 0.30000001192092896,
                    Text = Option,
                    Size = UDim2New(0, 0, 0, 15),
                    AnchorPoint = Vector2New(0, 0.5),
                    BorderSizePixel = 0,
                    ZIndex = 2,
                    BackgroundTransparency = 1,
                    Position = UDim2New(0, 0, 0.5, 0),
                    BorderColor3 = FromRGB(0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.X,
                    TextSize = 14,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  OptionText:AddToTheme({TextColor3 = "Text"})
                
                local OptionData = {
                    Button = OptionButton,
                    Name = Option,
                    OptionText = OptionText,
                    IsSearching = false,
                    OptionAccent = OptionAccent,
                    Selected = false
                }
                
                function OptionData:Toggle(Value)
                    if Value == "Active" then
                        OptionText:Tween(nil, {TextTransparency = 0, Position = UDim2New(0, 15, 0.5, 0)})
                        OptionAccent:Tween(nil, {BackgroundTransparency = 0})
                    else
                        OptionText:Tween(nil, {TextTransparency = 0.3, Position = UDim2New(0, 0, 0.5, 0)})
                        OptionAccent:Tween(nil, {BackgroundTransparency = 1})
                    end
                end

                function OptionData:Search(Bool)
                    Library:Thread(function()
                        if Bool then 
                            OptionData.IsSearching = true
                            OptionText:Tween(TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextTransparency = 1})
                            task.wait(0.08)
                            OptionButton:Tween(TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2New(1, 0, 0, 0)})
                            
                            if OptionData.Selected then 
                                OptionAccent:Tween(TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 1})
                            end
                        else
                            OptionData.IsSearching = false
                            OptionText:Tween(TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {TextTransparency = OptionData.Selected and 0 or 0.3})
                            task.wait(0.08)
                            OptionButton:Tween(TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2New(1, 0, 0, 20)})
                            
                            if OptionData.Selected then 
                                OptionAccent:Tween(TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {BackgroundTransparency = 0})
                            end
                        end
                    end)
                end

                function OptionData:Set()
                    OptionData.Selected = not OptionData.Selected

                    if Dropdown.Multi then 
                        local Index = TableFind(Dropdown.Value, OptionData.Name)

                        if Index then 
                            TableRemove(Dropdown.Value, Index)
                        else
                            TableInsert(Dropdown.Value, OptionData.Name)
                        end

                        OptionData:Toggle(Index and "Inactive" or "Active")

                        Library.Flags[Dropdown.Flag] = Dropdown.Value
                    else
                        if OptionData.Selected then 
                            Dropdown.Value = OptionData.Name
                            Library.Flags[Dropdown.Flag] = OptionData.Name

                            OptionData.Selected = true
                            OptionData:Toggle("Active")

                            for Index, Value in Dropdown.Options do 
                                if Value ~= OptionData and not Value.IsSearching then
                                    Value.Selected = false 
                                    Value:Toggle("Inactive")
                                end
                            end
                        else
                            Dropdown.Value = nil
                            Library.Flags[Dropdown.Flag] = nil

                            OptionData.Selected = false
                            OptionData:Toggle("Inactive")
                        end
                    end

                    if Dropdown.Callback then
                        Library:SafeCall(Dropdown.Callback, Dropdown.Value)
                    end
                end

                OptionData.Button:Connect("MouseButton1Down", function()
                    OptionData:Set()
                end)

                Dropdown.Options[OptionData.Name] = OptionData
                return OptionData
            end

            function Dropdown:Remove(Option)
                if Dropdown.Options[Option] then
                    Dropdown.Options[Option].Button:Clean()
                    Dropdown.Options[Option] = nil
                end
            end

            function Dropdown:Refresh(List)
                for Index, Value in Dropdown.Options do 
                    Dropdown:Remove(Value.Name)
                end

                for Index, Value in List do 
                    Dropdown:Add(Value)
                end
            end

            Library:Connect(Items["Search"].Instance:GetPropertyChangedSignal("Text"), function()
                Library:Thread(function()
                    for Index, Value in Dropdown.Options do
                        local InputText = Items["Search"].Instance.Text
                        if InputText ~= "" then
                            if StringFind(StringLower(Value.Name), Library:EscapePattern(StringLower(InputText))) then
                                Value.Button.Instance.Visible = true
                                Value:Search(false)
                            else
                                Value:Search(true)
                                Value.Button.Instance.Visible = false
                            end
                        else
                            Value:Search(false)
                            Value.Button.Instance.Visible = true
                        end
                    end
                end)
            end)


            for Index, Value in Dropdown.Items do 
                Dropdown:Add(Value)
            end

            if Dropdown.Default then 
                Dropdown:Set(Dropdown.Default)
            end

            Library.SetFlags[Dropdown.Flag] = function(Value)
                Dropdown:Set(Value)
            end

            Dropdown.Section.Elements[#Dropdown.Section.Elements+1] = Dropdown
            return Dropdown
        end
    end

    Library.CreateSettingsPage = function(self, Window, KeybindList)
        local Page = Window:Page({Name = "Settings", Icon = "122669828593160"})
        local ConfigsSection = Page:Section({Name = "Configs", Side = 1}) do 
            local ConfigSelected = nil

            local ConfigsDropdown = ConfigsSection:Listbox({
                Flag = "ConfigsList", 
                Items = { }, 
                Multi = false,
                Callback = function(Value)
                    ConfigSelected = Value
                end
            })
            
            ConfigsSection:Textbox({
                Flag = "ConfigsName",
                Placeholder = "Name",
                Numeric = false,
                Finished = false,
                Callback = function(Value)
                end
            })

            ConfigsSection:Button({
                Name = "Create",
                Callback = function()
                    local InputName = Library.Flags["ConfigsName"]
                    if InputName and InputName ~= "" then
                        if not isfolder(Library.Folders.Configs) then
                            makefolder(Library.Folders.Configs)
                        end
                        local FinalName = InputName:find(".json") and InputName or InputName .. ".json"
                        writefile(Library.Folders.Configs .. "/" .. FinalName, Library:GetConfig())
                        
                        Library:RefreshConfigsList(ConfigsDropdown)
                        Library:Notification({
                            Title = "Config",
                            Description = "Created config: " .. FinalName,
                            Duration = 2,
                            Icon = "73789337996373"
                        })
                    end
                end
            })

            ConfigsSection:Button({
                Name = "Load",
                Callback = function()
                    if ConfigSelected and isfile(Library.Folders.Configs .. "/" .. ConfigSelected) then
                        Library:LoadConfig(readfile(Library.Folders.Configs .. "/" .. ConfigSelected))
                        Library:Notification({
                            Title = "Config",
                            Description = "Loaded config: " .. ConfigSelected,
                            Duration = 2,
                            Icon = "73789337996373"
                        })
                    end
                end
            })

            ConfigsSection:Button({
                Name = "Save",
                Callback = function()
                    if ConfigSelected and isfile(Library.Folders.Configs .. "/" .. ConfigSelected) then
                        writefile(Library.Folders.Configs .. "/" .. ConfigSelected, Library:GetConfig())
                        Library:Notification({
                            Title = "Config",
                            Description = "Saved config: " .. ConfigSelected,
                            Duration = 2,
                            Icon = "73789337996373"
                        })
                    end
                end
            })

            ConfigsSection:Button({
                Name = "Refresh",
                Callback = function()
                    Library:RefreshConfigsList(ConfigsDropdown)
                    Library:Notification({
                        Title = "Config",
                        Description = "Refreshed config list",
                        Duration = 2,
                        Icon = "73789337996373"
                    })
                end
            })

            ConfigsSection:Button({
                Name = "Delete",
                Callback = function()
                    if ConfigSelected and isfile(Library.Folders.Configs .. "/" .. ConfigSelected) then
                        delfile(Library.Folders.Configs .. "/" .. ConfigSelected)
                        Library:RefreshConfigsList(ConfigsDropdown)
                        Library:Notification({
                            Title = "Config",
                            Description = "Deleted config: " .. ConfigSelected,
                            Duration = 2,
                            Icon = "73789337996373"
                        })
                        ConfigSelected = nil
                    end
                end
            })

            -- Auto Load Config Label (shows current auto load config status)
            local AutoLoadLabel = ConfigsSection:Label("Auto Load: None")

            -- Function to update the auto load label
            local function UpdateAutoLoadLabel()
                local autoLoadFile = Library.Folders.Configs .. "/autoload.txt"
                if isfile(autoLoadFile) then
                    local success, content = pcall(readfile, autoLoadFile)
                    if success and content then
                        local configName = content:match("([^/\\]+)$")
                        AutoLoadLabel:SetText("Auto Load: " .. (configName or content))
                    else
                        AutoLoadLabel:SetText("Auto Load: None")
                    end
                else
                    AutoLoadLabel:SetText("Auto Load: None")
                end
            end

            ConfigsSection:Button({
                Name = "Set Auto Load Config",
                Callback = function()
                    if ConfigSelected and isfile(Library.Folders.Configs .. "/" .. ConfigSelected) then
                        writefile(Library.Folders.Configs .. "/autoload.txt", Library.Folders.Configs .. "/" .. ConfigSelected)
                        UpdateAutoLoadLabel()
                        Library:Notification({
                            Title = "Config",
                            Description = "Auto load set to: " .. ConfigSelected,
                            Duration = 2,
                            Icon = "73789337996373"
                        })
                    end
                end
            })

            ConfigsSection:Button({
                Name = "Reset Auto Load Config",
                Callback = function()
                    local autoLoadFile = Library.Folders.Configs .. "/autoload.txt"
                    if isfile(autoLoadFile) then
                        delfile(autoLoadFile)
                    end
                    UpdateAutoLoadLabel()
                    Library:Notification({
                        Title = "Config",
                        Description = "Auto load config reset to None",
                        Duration = 2,
                        Icon = "73789337996373"
                    })
                end
            })
            
            if not isfolder(Library.Folders.Configs) then
                makefolder(Library.Folders.Configs)
            end
            Library:RefreshConfigsList(ConfigsDropdown)
            
            -- Update auto load label after refresh
            task.spawn(function()
                task.wait(0.1)
                UpdateAutoLoadLabel()
            end)
        end

        local UISection = Page:Section({Name = "UI Settings", Side = 2}) do
            UISection:Toggle({
                Name = "Watermark",
                Flag = "WatermarkToggle",
                Default = true,
                Callback = function(Value)
                    if Library.WatermarkFrame then
                        Library.WatermarkFrame.Instance.Visible = Value
                    end
                end
            })

            UISection:Toggle({
                Name = "Keybind List",
                Flag = "KeybindListToggle",
                Default = false,
                Callback = function(Value)
                    if KeybindList then
                        KeybindList:SetVisibility(Value)
                    end
                end
            })

            UISection:Toggle({
                Name = "Silent Load",
                Flag = "SilentLoadToggle",
                Default = (function()
                    local path = Library.Folders.Configs .. "/silentload.txt"
                    if isfile and isfile(path) then
                        local ok, content = pcall(readfile, path)
                        if ok and content == "true" then
                            return true
                        end
                    end
                    return false
                end)(),
                Callback = function(Value)
                    local path = Library.Folders.Configs .. "/silentload.txt"

                    if not isfolder(Library.Folders.Configs) then
                        makefolder(Library.Folders.Configs)
                    end

                    if Value then
                        if writefile then
                            writefile(path, "true")
                        end
                    else
                        if isfile and isfile(path) and delfile then
                            delfile(path)
                        end
                    end
                end
            })

            -- ═══ ПОСТОЯННЫЙ ЧИП-ТУМБЛЕР МЕНЮ (стиль либки): всегда на экране, по центру сверху.
            -- Тап — сворачивает/разворачивает меню. Драг — перетащить. Лого + имя хаба + акцент-полоса.
            do
                local Chip = Instances:Create("TextButton", {
                    Parent = Library.Holder.Instance,
                    Name = "\0",
                    Visible = true,
                    AutoButtonColor = false,
                    Text = "",
                    AnchorPoint = Vector2New(0.5, 0),
                    Position = UDim2New(0.5, 0, 0, 12),
                    Size = UDim2New(0, 150, 0, 38),
                    BackgroundTransparency = Library.Flags["BackgroundTransparency"] or 0.12,   -- как у окна меню
                    BackgroundColor3 = FromRGB(27, 25, 29),
                    BorderSizePixel = 0,
                    ZIndex = 10
                })  Chip:AddToTheme({BackgroundColor3 = "Background"})

                Instances:Create("UICorner", { Parent = Chip.Instance, Name = "\0", CornerRadius = UDimNew(0, 8) })

                -- стеклянный блюр позади чипа — тот же эффект, что у окна либки
                pcall(function() Library:MakeBlurred(Chip, Window) end)

                -- прозрачность чипа живёт вместе со слайдером Menu Transparency
                pcall(function()
                    local OldSetTransparency = Window.SetTransparency
                    Window.SetTransparency = function(selfW, ...)
                        OldSetTransparency(selfW, ...)
                        pcall(function()
                            Chip.Instance.BackgroundTransparency = Library.Flags["BackgroundTransparency"] or 0.12
                        end)
                    end
                end)

                Instances:Create("UIStroke", {
                    Parent = Chip.Instance,
                    Name = "\0",
                    Thickness = 1,
                    Transparency = 0.45,
                    Color = FromRGB(255, 255, 255)
                }):AddToTheme({Color = "Accent"})

                -- лого хаба слева (кругляш)
                local ChipTextX = 12
                if Window.Logo then
                    local ChipLogo = Instances:Create("ImageLabel", {
                        Parent = Chip.Instance,
                        Name = "\0",
                        Image = "rbxassetid://" .. Window.Logo,
                        BackgroundTransparency = 1,
                        AnchorPoint = Vector2New(0, 0.5),
                        Position = UDim2New(0, 9, 0.5, -2),
                        Size = UDim2New(0, 22, 0, 22),
                        ZIndex = 11
                    })
                    Instances:Create("UICorner", { Parent = ChipLogo.Instance, Name = "\0", CornerRadius = UDimNew(1, 0) })
                    ChipTextX = 38
                end

                -- имя хаба шрифтом либки
                Instances:Create("TextLabel", {
                    Parent = Chip.Instance,
                    Name = "\0",
                    FontFace = Library.Font,
                    Text = Window.Name or "Menu",
                    TextSize = 14,
                    TextColor3 = FromRGB(240, 240, 240),
                    TextTransparency = 0.05,
                    BackgroundTransparency = 1,
                    AnchorPoint = Vector2New(0, 0.5),
                    Position = UDim2New(0, ChipTextX, 0.5, -2),
                    Size = UDim2New(1, -ChipTextX - 8, 0, 16),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 11
                }):AddToTheme({TextColor3 = "Text"})

                -- акцент-градиентная полоса снизу (фирменный элемент либки)
                local ChipBar = Instances:Create("Frame", {
                    Parent = Chip.Instance,
                    Name = "\0",
                    AnchorPoint = Vector2New(0.5, 1),
                    Position = UDim2New(0.5, 0, 1, -4),
                    Size = UDim2New(1, -18, 0, 2),
                    BorderSizePixel = 0,
                    ZIndex = 11,
                    BackgroundColor3 = FromRGB(255, 255, 255)
                })  ChipBar:AddToTheme({BackgroundColor3 = "Accent"})
                Instances:Create("UICorner", { Parent = ChipBar.Instance, Name = "\0", CornerRadius = UDimNew(1, 0) })
                Instances:Create("UIGradient", {
                    Parent = ChipBar.Instance,
                    Name = "\0",
                    Color = RGBSequence{RGBSequenceKeypoint(0, FromRGB(255, 255, 255)), RGBSequenceKeypoint(1, FromRGB(166, 166, 166))}
                }):AddToTheme({Color = function()
                    return RGBSequence{RGBSequenceKeypoint(0, Library.Theme.Accent), RGBSequenceKeypoint(1, Library.Theme.AccentGradient)}
                end})

                -- драг мультитач-safe (жёстко привязан к пальцу, джойстик не дёргает),
                -- тап без сдвига = свернуть/развернуть меню
                local ChipDragInput, ChipMoved, ChipDragStart, ChipStartPos
                Chip:Connect("InputBegan", function(Input)
                    if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
                        ChipDragInput, ChipMoved, ChipDragStart, ChipStartPos = Input, false, Input.Position, Chip.Instance.Position
                    end
                end)
                Library:Connect(UserInputService.InputChanged, function(Input)
                    if not ChipDragInput then return end
                    local Same
                    if ChipDragInput.UserInputType == Enum.UserInputType.Touch then
                        Same = (Input == ChipDragInput)
                    else
                        Same = (Input.UserInputType == Enum.UserInputType.MouseMovement)
                    end
                    if not Same then return end
                    local Delta = Input.Position - ChipDragStart
                    if math.abs(Delta.X) > 6 or math.abs(Delta.Y) > 6 then ChipMoved = true end
                    if ChipMoved then
                        Chip.Instance.Position = UDim2New(ChipStartPos.X.Scale, ChipStartPos.X.Offset + Delta.X, ChipStartPos.Y.Scale, ChipStartPos.Y.Offset + Delta.Y)
                    end
                end)
                Library:Connect(UserInputService.InputEnded, function(Input)
                    if ChipDragInput ~= Input then return end
                    local WasMoved = ChipMoved
                    ChipDragInput, ChipMoved = nil, false
                    if not WasMoved then
                        Window:SetOpen(not Window.IsOpen)   -- тумблер: открыто → свернуть, свёрнуто → открыть
                    end
                end)

                UISection:Button({
                    Name = "Collapse UI",
                    Callback = function()
                        Window:SetOpen(false)
                    end
                })
            end

            UISection:Button({
                Name = "Unload Script",
                Callback = function()
                    Library:Notification({
                        Title = "System",
                        Description = "Unloading script...",
                        Duration = 2,
                        Icon = "73789337996373"
                    })
                    task.wait(0.5)
                    Library:Unload()
                end
            })
        end

        local ServerSection = Page:Section({Name = "Server", Side = 2}) do
            ServerSection:Button({
                Name = "Server Hop",
                Callback = function()
                    local TeleportService = game:GetService("TeleportService")
                    local HttpService = game:GetService("HttpService")
                    local PlaceId = game.PlaceId
                    local CurrentJobId = game.JobId
                    task.spawn(function()
                        Library:Notification({Title = "Server Hop", Description = "Searching for server...", Duration = 1, Icon = "73789337996373"})
                        local ok, servers = pcall(function()
                            return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/0?sortOrder=Asc&limit=100"))
                        end)
                        if ok and servers and servers.data then
                            for _, server in servers.data do
                                if server.id ~= CurrentJobId and server.playing and server.playing < server.maxPlayers then
                                    local teleportOk = pcall(function()
                                        TeleportService:TeleportToPlaceInstance(PlaceId, server.id)
                                    end)
                                    if not teleportOk and Library and Library.Notification then
                                        Library:Notification({Title = "Server Hop", Description = "Failed to teleport.", Duration = 2, Icon = "73789337996373"})
                                    end
                                    return
                                end
                            end
                        end
                        if Library and Library.Notification then
                            Library:Notification({Title = "Server Hop", Description = "No servers available to hop to.", Duration = 2, Icon = "73789337996373"})
                        end
                    end)
                end
            })

            ServerSection:Button({
                Name = "Hop Low Server",
                Callback = function()
                    local TeleportService = game:GetService("TeleportService")
                    local HttpService = game:GetService("HttpService")
                    local PlaceId = game.PlaceId
                    local CurrentJobId = game.JobId
                    task.spawn(function()
                        Library:Notification({Title = "Hop Low Server", Description = "Searching for low population server...", Duration = 1, Icon = "73789337996373"})
                        local ok, servers = pcall(function()
                            return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/0?sortOrder=Asc&limit=100"))
                        end)
                        if ok and servers and servers.data then
                            local bestServer = nil
                            local lowestCount = 999
                            for _, server in servers.data do
                                if server.id ~= CurrentJobId and server.playing and server.playing < server.maxPlayers and server.playing < lowestCount then
                                    lowestCount = server.playing
                                    bestServer = server
                                end
                            end
                            if bestServer then
                                local teleportOk = pcall(function()
                                    TeleportService:TeleportToPlaceInstance(PlaceId, bestServer.id)
                                end)
                                if not teleportOk and Library and Library.Notification then
                                    Library:Notification({Title = "Hop Low Server", Description = "Failed to teleport.", Duration = 2, Icon = "73789337996373"})
                                end
                                return
                            end
                        end
                        if Library and Library.Notification then
                            Library:Notification({Title = "Hop Low Server", Description = "No low population servers available.", Duration = 2, Icon = "73789337996373"})
                        end
                    end)
                end
            })

            ServerSection:Button({
                Name = "Rejoin",
                Callback = function()
                    local ok, err = pcall(function()
                        game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId)
                    end)
                    if not ok and Library and Library.Notification then
                        Library:Notification({Title = "Rejoin", Description = "Failed to rejoin.", Duration = 2, Icon = "73789337996373"})
                    end
                end
            })
        end

        return Page
    end
end

getgenv().Library = Library
    return Library
end)()

local AstraUI = {
    Options = Library.Flags,
    Theme = Library.Theme,
    ScreenGui = Library.Holder and Library.Holder.Instance,
    ConfigManager = {},
}
AstraUI.Window = nil

function AstraUI:Notify(data)
    data = data or {}
    return Library:Notification({
        Title = data.Title or "Astra Hub",
        Description = data.Content or data.Description or "",
        Duration = data.Duration or 3,
        Icon = data.Icon or "73789337996373",
    })
end

function AstraUI:SetTheme(data)
    for key, value in pairs(data or {}) do
        Library.Theme[key] = value
        pcall(function() Library:ChangeTheme(key, value) end)
    end
end

AstraUI.ConfigManager.SetFolder = function() end
AstraUI.ConfigManager.SetIgnoreIndexes = function() end
AstraUI.ConfigManager.LoadAutoload = function()
    pcall(function()
        local path = Library.Folders.Configs .. "/autoload.txt"
        if isfile and isfile(path) and readfile then
            local target = readfile(path)
            if target and isfile(target) then
                Library:LoadConfig(readfile(target))
            end
        end
    end)
end

function AstraUI:BuildConfigSection()
    return nil
end

local function compatElement(element)
    if not element then return element end
    if not element.SetValue and element.Set then
        function element:SetValue(v, ...)
            return self:Set(v, ...)
        end
    end
    if not element.SetValues and element.Refresh then
        function element:SetValues(values)
            return self:Refresh(values)
        end
    end
    if not element.GetState then
        function element:GetState()
            return self.Toggled == true
        end
    end
    if not element.OnChanged then
        element._compatListeners = {}
        local originalCallback = element.Callback
        function element:OnChanged(fn)
            table.insert(self._compatListeners, fn)
            return self
        end
        element.Callback = function(v)
            if originalCallback then pcall(originalCallback, v) end
            for _, fn in ipairs(self._compatListeners) do pcall(fn, v) end
        end
    end
    return element
end

local CompatSection = {}
CompatSection.__index = CompatSection

function CompatSection:AddToggle(flag, data)
    data=data or {}
    return compatElement(self._section:Toggle({
        Name=data.Title or data.Name or "Toggle", Flag=flag,
        Default=data.Default, Callback=data.Callback
    }))
end

function CompatSection:AddSlider(flag, data)
    data=data or {}
    return compatElement(self._section:Slider({
        Name=data.Title or data.Name or "Slider", Flag=flag,
        Default=data.Default, Min=data.Min, Max=data.Max,
        Decimals=data.Decimals or data.Rounding or 0,
        Suffix=data.Suffix, Callback=data.Callback
    }))
end

function CompatSection:AddDropdown(flag, data)
    data=data or {}
    return compatElement(self._section:Dropdown({
        Name=data.Title or data.Name or "Dropdown", Flag=flag,
        Items=data.Values or data.Items or {}, Multi=data.Multi == true,
        Default=data.Default, Callback=data.Callback
    }))
end

function CompatSection:AddKeybind(flag, data)
    data=data or {}
    return compatElement(self._section:Keybind({
        Name=data.Title or data.Name or "Keybind", Flag=flag,
        Default=data.Default, Mode=data.Mode or "Toggle",
        Callback=data.Callback
    }))
end

function CompatSection:AddColorpicker(flag, data)
    data=data or {}
    return compatElement(self._section:Colorpicker({
        Name=data.Title or data.Name or "Color", Flag=flag,
        Default=data.Default, Alpha=data.Alpha, Callback=data.Callback
    }))
end

function CompatSection:AddButton(data)
    data=data or {}
    return self._section:Button({
        Name=data.Title or data.Name or "Button",
        Description=data.Description, Callback=data.Callback
    })
end

function CompatSection:AddLabel(text)
    return compatElement(self._section:Label(text))
end

function CompatSection:AddParagraph(data)
    data=data or {}
    local e=self._section:Label(data.Title and (tostring(data.Title) .. (data.Content and ("\n"..tostring(data.Content)) or "")) or tostring(data.Content or ""))
    function e:SetDesc(text) if self.SetText then self:SetText(text) end end
    return compatElement(e)
end

function CompatSection:AddInput(flag, data)
    data=data or {}
    return compatElement(self._section:Textbox({
        Flag=flag, Placeholder=data.Placeholder, Default=data.Default or "",
        Numeric=data.Numeric, Finished=data.Finished, Callback=data.Callback
    }))
end

local CompatTab={}
CompatTab.__index=CompatTab
function CompatTab:AddSection(title)
    self._sectionCount=self._sectionCount+1
    local side=(self._sectionCount%2==1) and 1 or 2
    return setmetatable({
        _section=self._page:Section({Name=title,Side=side}),
        _order=self._sectionCount
    },CompatSection)
end

local CompatWindow={}
CompatWindow.__index=CompatWindow
function CompatWindow:AddTab(data)
    data=data or {}
    local page=self._window:Page({Name=data.Title or data.Name or "Tab",Icon=data.Icon})
    local tab=setmetatable({
        _page=page, Title=data.Title or data.Name or "Tab", _sectionCount=0
    },CompatTab)
    self._tabs[#self._tabs+1]=tab
    return tab
end
function CompatWindow:SelectTab(index)
    local tab=self._tabs[index]
    if tab and tab._page and tab._page.Turn then tab._page:Turn(true) end
end
function CompatWindow:Show() return self._window:SetOpen(true) end
function CompatWindow:Hide() return self._window:SetOpen(false) end

function CompatWindow:Dialog(data)
    data=data or {}
    local holder=Library.Holder.Instance
    local overlay=Instance.new("Frame")
    overlay.BackgroundColor3=Color3.new(0,0,0)
    overlay.BackgroundTransparency=0.35
    overlay.BorderSizePixel=0
    overlay.Size=UDim2.fromScale(1,1)
    overlay.ZIndex=200
    overlay.Parent=holder
    local card=Instance.new("Frame")
    card.AnchorPoint=Vector2.new(0.5,0.5)
    card.Position=UDim2.fromScale(0.5,0.5)
    card.Size=UDim2.fromOffset(330,150)
    card.BackgroundColor3=Library.Theme["Background 2"] or Color3.fromRGB(12,12,14)
    card.BorderSizePixel=0
    card.ZIndex=201
    card.Parent=overlay
    Instance.new("UICorner",card).CornerRadius=UDim.new(0,8)

    local title=Instance.new("TextLabel")
    title.BackgroundTransparency=1
    title.Position=UDim2.fromOffset(16,12)
    title.Size=UDim2.new(1,-32,0,22)
    title.Font=Enum.Font.GothamBold
    title.Text=tostring(data.Title or "Confirm")
    title.TextColor3=Library.Theme.Text or Color3.new(1,1,1)
    title.TextSize=16
    title.TextXAlignment=Enum.TextXAlignment.Left
    title.ZIndex=202
    title.Parent=card

    local body=Instance.new("TextLabel")
    body.BackgroundTransparency=1
    body.Position=UDim2.fromOffset(16,40)
    body.Size=UDim2.new(1,-32,0,55)
    body.Font=Enum.Font.Gotham
    body.Text=tostring(data.Content or "")
    body.TextColor3=Library.Theme.Text or Color3.new(1,1,1)
    body.TextTransparency=0.15
    body.TextSize=12
    body.TextWrapped=true
    body.TextXAlignment=Enum.TextXAlignment.Left
    body.ZIndex=202
    body.Parent=card

    local buttons=data.Buttons or {}
    local x=16
    for _,b in ipairs(buttons) do
        local btn=Instance.new("TextButton")
        btn.Size=UDim2.fromOffset(135,30)
        btn.Position=UDim2.new(0,x,1,-42)
        btn.BackgroundColor3=Library.Theme.Accent or Color3.fromRGB(0,116,224)
        btn.BorderSizePixel=0
        btn.AutoButtonColor=false
        btn.Font=Enum.Font.GothamMedium
        btn.Text=tostring(b.Title or "OK")
        btn.TextColor3=Color3.new(1,1,1)
        btn.TextSize=12
        btn.ZIndex=202
        btn.Parent=card
        Instance.new("UICorner",btn).CornerRadius=UDim.new(0,5)
        btn.MouseButton1Click:Connect(function()
            pcall(function() if b.Callback then b.Callback() end end)
            overlay:Destroy()
        end)
        x=x+145
    end
end

function AstraUI:CreateWindow(config)
    config=config or {}
    local raw=Library:Window({
        Name=config.Title or "Astra Hub",
        SubName=config.SubTitle or "",
        Logo=config.Logo or "79384247470010",
    })
    local wrapper=setmetatable({
        _window=raw, _tabs={},
        Instance=raw.Items and raw.Items.MainFrame and raw.Items.MainFrame.Instance or Library.Holder.Instance
    },CompatWindow)
    self.Window=wrapper
    return wrapper
end

AstraUI.Options=Library.Flags

local Window = AstraUI:CreateWindow({
    Title = "Astra Hub",
    SubTitle = Config.GameName,
    TabWidth = isMobile and math.min(100, winWidth * 0.22) or 160,
    Size = UDim2.fromOffset(winWidth, winHeight),
    MinimizeKey = Enum.KeyCode.LeftShift
})

Options = AstraUI.Options

Notify = function(data)
    AstraUI:Notify({
        Title = data.Title,
        Content = data.Content,
        Duration = data.Duration or 3
    })
end

NotifyUnsupportedFeature = function(featureName)
    Notify({ Title = featureName, Content = "Your executor doesn't support this feature", Duration = 3 })
end

local Tabs = {
    Aimbot = Window:AddTab({ Title = "Aimbot", Icon = "crosshair" }),
    Utility = Window:AddTab({ Title = "Utility", Icon = "shield" }),
    Weapons = Window:AddTab({ Title = "Weapons", Icon = "package" }),
    Player = Window:AddTab({ Title = "Player", Icon = "user" }),
    ESP = Window:AddTab({ Title = "ESP", Icon = "eye" }),
    Misc = Window:AddTab({ Title = "Miscellaneous", Icon = "box" }),
    Skins = Window:AddTab({ Title = "Skins", Icon = "brush" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" }),
    About = Window:AddTab({ Title = "About", Icon = "info" })
}

local AimbotSection = Tabs.Aimbot:AddSection("Aimbot")

AimbotSection:AddToggle("aimbot_enabled", { Title = "Enabled", Default = false })

AimbotSection:AddDropdown("aim_mode", {
    Title = "Aim Mode",
    Values = {"Mouse"},
    Default = "Mouse",
    Multi = false,
})

AimbotSection:AddSlider("max_distance", {
    Title = "Max Distance",
    Default = 1000,
    Min = 0,
    Max = 5000,
    Rounding = 0,
})

AimbotSection:AddSlider("aimbot_smoothing", {
    Title = "Smoothing",
    Default = 5,
    Min = 1,
    Max = 50,
    Rounding = 1,
})

AimbotSection:AddDropdown("aim_target", {
    Title = "Target Part",
    Values = TargetBodyParts,
    Default = "Head",
    Multi = false,
    Callback = function(v) AimbotSettings.TargetPart = v end
})

AimbotSection:AddKeybind("aimbot_bind", {
    Title = "Aim Key",
    Mode = "Hold",
    Default = "MouseRight",
    Callback = function(Value)
        State.Aiming = Value
        if not Value then State.LockedTarget = nil end
    end
})

local SilentAimSection = Tabs.Aimbot:AddSection("Silent Aim")

local SilentAimToggleSync = false
local SilentAimToggle = SilentAimSection:AddToggle("silent_aim_enabled", { Title = "Enabled", Default = false })

SilentAimToggle:OnChanged(function()
    local v = Options.silent_aim_enabled.Value
    if Runtime.FeatureControlSync == "silent_aim_enabled" then
        ApplySilentAimEnabled(v)
        return
    end
    if SilentAimToggleSync then
        ApplySilentAimEnabled(v)
        return
    end
    if not v then
        ApplySilentAimEnabled(false)
        return
    end
    SilentAimToggleSync = true
    SilentAimToggle:SetValue(false)
    SilentAimToggleSync = false

    task.spawn(function()
        local confirmed = false
        Window:Dialog({
            Title = "Silent Aim",
            Content = "This feature is detectable. Are you sure you want to enable Silent Aim?",
            Buttons = {
                { Title = "Yes", Callback = function()
                    confirmed = true
                    SilentAimToggleSync = true
                    SilentAimToggle:SetValue(true)
                    SilentAimToggleSync = false
                end },
                { Title = "No", Callback = function()
                    confirmed = true
                    ApplySilentAimEnabled(false)
                end }
            }
        })
        task.wait(10)
        if not confirmed then
            SilentAimToggleSync = true
            SilentAimToggle:SetValue(false)
            SilentAimToggleSync = false
        end
    end)
end)

SilentAimSection:AddSlider("silent_aim_hitchance", {
    Title = "Hitchance",
    Default = 100,
    Min = 1,
    Max = 100,
    Rounding = 0,
    Callback = function(v) State.SilentAimHitchance = v end
})

SilentAimSection:AddDropdown("silent_aim_target", {
    Title = "Target Part",
    Values = TargetBodyParts,
    Default = "Head",
    Multi = false,
    Callback = function(v) AimbotSettings.TargetPart = v end
})

local wallBang = __p6q7r8.__s9t0u1

SilentAimSection:AddToggle("wall_bang_enabled", { 
    Title = "Wall Bang", 
    Default = false,
    Callback = function(v) 
        State.WallBangEnabled = v
        if v then
            if State.SilentAimEnabled then
                wallBang:Enable()
                Notify({ Title = "Wall Bang", Content = "Wall Bang activated! (Desync method)", Duration = 3 })
            else
                Notify({ Title = "Wall Bang", Content = "Enable Wall bang then Silent Aim!", Duration = 3 })
            end
        else
            wallBang:Disable()
        end
    end
})

SilentAimToggle:OnChanged(function(v)
    if v and State.WallBangEnabled then
        wallBang:Enable()
    elseif not v then
        wallBang:Disable()
    end
end)

local AimbotChecksSection = Tabs.Aimbot:AddSection("Checks")

AimbotChecksSection:AddToggle("team_check", { Title = "Team Check", Default = true })
AimbotChecksSection:AddToggle("wall_check", { Title = "Wall Check", Default = true, Callback = function(v) State.WallCheckEnabled = v end })
AimbotChecksSection:AddToggle("show_fov", { Title = "Show FOV", Default = false })
AimbotChecksSection:AddSlider("fov_slider", { Title = "Field of View", Default = 90, Min = 0, Max = 1000, Rounding = 0 })

local FOVFilledValue = false
local FOVFilledTransparency = 0.8
AimbotChecksSection:AddToggle("fov_filled", { Title = "FOV Filled", Default = false, Callback = function(v) FOVFilledValue = v end })
AimbotChecksSection:AddSlider("fov_fill_opacity", { Title = "FOV Fill Opacity", Default = 0.8, Min = 0, Max = 1, Rounding = 2, Callback = function(v) FOVFilledTransparency = v end })

local TriggerbotSection = Tabs.Aimbot:AddSection("Triggerbot")
local TriggerbotEnabled = false
local TriggerbotDelay = 0.05
local TriggerbotActive = false
local lastTriggerTime = 0

TriggerbotSection:AddToggle("triggerbot_enabled", { Title = "Enabled", Default = false, Callback = function(v) TriggerbotEnabled = v end })
TriggerbotSection:AddKeybind("triggerbot_bind", { Title = "Hold Key", Mode = "Hold", Default = "MouseRight", Callback = function(Value) TriggerbotActive = Value end })
TriggerbotSection:AddSlider("triggerbot_delay", { Title = "Delay", Default = 0.05, Min = 0, Max = 0.5, Rounding = 2, Callback = function(v) TriggerbotDelay = v end })

local OrbitSection = Tabs.Utility:AddSection("Orbit")

local OrbitEnabled = false
local OrbitSpeed = 1
local OrbitDistance = 5
local OrbitHeight = 3
local OrbitRunning = false
local OrbitAngle = 0
local OrbitTargetMode = "Closest Enemy"
local OrbitAutoShoot = false
local OrbitTargetPlayer = nil
local OrbitDuelScanResult = nil
local OrbitDuelScanTime = 0

local function GetDuelOpponentFromGarbageCollector()
    if not getgc then return nil end
    local now = tick()
    if now - OrbitDuelScanTime < 0.2 then return OrbitDuelScanResult end
    OrbitDuelScanTime = now
    OrbitDuelScanResult = nil
    pcall(function()
        for _, object in ipairs(getgc(true)) do
            if type(object) == "table" then
                local duelers = rawget(object, "Duelers")
                if type(duelers) == "table" then
                    local hasLocalPlayer = false
                    local opponentPlayer = nil
                    for _, dueler in pairs(duelers) do
                        local player = type(dueler) == "table" and rawget(dueler, "Player") or nil
                        if player == Config.LocalPlayer then
                            hasLocalPlayer = true
                        elseif typeof(player) == "Instance" and player:IsA("Player") then
                            opponentPlayer = player
                        end
                    end
                    if hasLocalPlayer and opponentPlayer then
                        OrbitDuelScanResult = opponentPlayer
                        return opponentPlayer
                    end
                end
            end
        end
    end)
    return OrbitDuelScanResult
end

local function GetDuelOpponent()
    if State.RequireBlocked then return GetDuelOpponentFromGarbageCollector() end
    local DuelController = GetDuelController()
    if not DuelController then return GetDuelOpponentFromGarbageCollector() end
    local duel = DuelController:GetDuel(Config.LocalPlayer)
    if not duel then return GetDuelOpponentFromGarbageCollector() end
    for _, dueler in pairs(duel.Duelers) do
        if dueler.Player and dueler.Player ~= Config.LocalPlayer then return dueler.Player end
    end
    return GetDuelOpponentFromGarbageCollector()
end

local function GetOrbitTarget()
    if OrbitTargetMode == "Duel Opponent" then return GetDuelOpponent()
    elseif OrbitTargetMode == "Aimbot Target" then return State.LockedTarget end
    local closestPlayer = nil
    local shortestDistance = math.huge
    local players = GetValidPlayers()
    for i = 1, #players do
        local player = players[i]
        if player ~= Config.LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
            if humanoid and humanoid.Health > 0 and rootPart then
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                if hrp and hrp:FindFirstChild("TeammateLabel") then continue end
                local localRoot = Config.LocalPlayer.Character and Config.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if localRoot then
                    local dist = (rootPart.Position - localRoot.Position).Magnitude
                    if dist < shortestDistance then
                        shortestDistance = dist
                        closestPlayer = player
                    end
                end
            end
        end
    end
    return closestPlayer
end

OrbitSection:AddToggle("orbit_enabled", { Title = "Enabled", Default = false, Callback = function(v)
    OrbitEnabled = v
    if v and not OrbitRunning then
        OrbitRunning = true
        OrbitAngle = 0
        task.spawn(function()
            while OrbitEnabled and OrbitRunning do
                local delta = Services.RunService.Heartbeat:Wait()
                local targetPlayer = GetOrbitTarget()
                if targetPlayer and targetPlayer.Character then
                    local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                    local targetHead = targetPlayer.Character:FindFirstChild("Head")
                    local localChar = Config.LocalPlayer.Character
                    local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")
                    local isInvincible = false
                    pcall(function()
                        local fc = GetFighterController()
                        if fc then
                            local targetFighter = fc:GetFighter(targetPlayer)
                            if targetFighter and targetFighter.Entity then
                                isInvincible = targetFighter.Entity:Get("IsInvincible") == true
                            end
                        end
                    end)
                    if targetRoot and localRoot and not isInvincible then
                        local targetPos = targetRoot.Position
                        local center = targetPos + Vector3.new(0, OrbitHeight, 0)
                        OrbitAngle = OrbitAngle + delta * OrbitSpeed * 2 * math.pi
                        local offset = Vector3.new(math.cos(OrbitAngle) * OrbitDistance, 0, math.sin(OrbitAngle) * OrbitDistance)
                        local desiredPos = center + offset
                        localRoot.CFrame = CFrame.new(desiredPos, center)
                        if OrbitAutoShoot and targetHead then
                            if not (State.AntiKatanaEnabled and IsEnemyDeflecting(targetPlayer)) then
                                pcall(function()
                                    local fc = GetFighterController()
                                    if fc and fc.LocalFighter then
                                        local equippedItem = fc.LocalFighter.EquippedItem
                                        if equippedItem then
                                            local remotes = Services.ReplicatedStorage:FindFirstChild("Remotes")
                                            if not remotes then return end
                                            local replication = remotes:FindFirstChild("Replication")
                                            if not replication then return end
                                            local fighterRemote = replication:FindFirstChild("Fighter")
                                            if not fighterRemote then return end
                                            local UseItemRemote = fighterRemote:FindFirstChild("UseItem")
                                            if not UseItemRemote then return end
                                            
                                            local objectId = equippedItem:Get("ObjectID")
                                            if not objectId then return end
                                            
                                            local shootOrigin = Services.Camera.CFrame.Position
                                            local targetPos = targetHead.Position
                                            local direction = (targetPos - shootOrigin).Unit
                                            
                                            local function MakeCFrameData(cf)
                                                local rx, ry, rz = cf:ToOrientation()
                                                return {
                                                    [utf8.char(0)] = cf.X,
                                                    [utf8.char(1)] = cf.Y,
                                                    [utf8.char(2)] = cf.Z,
                                                    [utf8.char(3)] = rx,
                                                    [utf8.char(4)] = ry,
                                                    [utf8.char(5)] = rz
                                                }
                                            end
                                            
                                            local originCF = CFrame.new(shootOrigin, shootOrigin + direction)
                                            local destCF = CFrame.new(targetPos, targetPos + direction)
                                            local hitPart = targetPlayer.Character:FindFirstChild("UpperTorso") or targetPlayer.Character:FindFirstChild("HumanoidRootPart") or targetHead
                                            
                                            local cameraData = {
                                                [utf8.char(0)] = MakeCFrameData(originCF),
                                                [utf8.char(1)] = MakeCFrameData(destCF),
                                                [utf8.char(2)] = hitPart
                                            }
                                            
                                            local actionData = { [utf8.char(1)] = cameraData }
                                            UseItemRemote:FireServer(objectId, "\026", actionData, nil)
                                            
                                            if equippedItem.ViewModel and equippedItem.ViewModel.MuzzleFlash then
                                                equippedItem.ViewModel:MuzzleFlash()
                                            end
                                        end
                                    end
                                end)
                            end
                        end
                    end
                end
            end
            OrbitRunning = false
        end)
    elseif not v then
        OrbitRunning = false
    end
end })

OrbitSection:AddDropdown("orbit_target_mode", { Title = "Target Mode", Values = {"Closest Enemy", "Aimbot Target", "Duel Opponent"}, Default = "Closest Enemy", Multi = false, Callback = function(v) OrbitTargetMode = v end })
OrbitSection:AddToggle("orbit_autoshoot", { Title = "Auto Shoot", Default = false, Callback = function(v) OrbitAutoShoot = v end })
OrbitSection:AddSlider("orbit_speed", { Title = "Speed", Default = 1, Min = 0.1, Max = 5, Rounding = 1, Callback = function(v) OrbitSpeed = v end })
OrbitSection:AddSlider("orbit_distance", { Title = "Distance", Default = 5, Min = 2, Max = 20, Rounding = 0, Callback = function(v) OrbitDistance = v end })
OrbitSection:AddSlider("orbit_height", { Title = "Height", Default = 3, Min = 0, Max = 10, Rounding = 1, Callback = function(v) OrbitHeight = v end })

local AntiKatanaSection = Tabs.Utility:AddSection("Anti-Katana")
local AntiKatanaToggle = AntiKatanaSection:AddToggle("anti_katana", { Title = "Enabled", Default = false })

AntiKatanaToggle:OnChanged(function()
    local v = Options.anti_katana.Value
    if Runtime.FeatureControlSync == "anti_katana" then State.AntiKatanaEnabled = v return end
    if v and State.RequireBlocked then
        State.AntiKatanaEnabled = false
        NotifyUnsupportedFeature("Anti-Katana")
        Runtime.FeatureControlSync = "anti_katana"
        AntiKatanaToggle:SetValue(false)
        Runtime.FeatureControlSync = nil
        return
    end
    State.AntiKatanaEnabled = v
    task.defer(function()
        if v then
            SetupAntiKatanaHook()
            pcall(function()
                local mc = GetMechanicsController()
                if mc and not State.OriginalEquippedItemInput then
                    State.OriginalEquippedItemInput = mc.EquippedItemInput
                    mc.EquippedItemInput = function(self, inputName, ...)
                        if State.AntiKatanaEnabled then
                            if inputName == "StartShooting" or inputName == "FinishShooting" then
                                if IsAnyVisibleEnemyDeflecting() then return end
                            end
                        end
                        return State.OriginalEquippedItemInput(self, inputName, ...)
                    end
                end
            end)
            Notify({ Title = "Anti-Katana Enabled", Content = "Shots blocked when enemies deflect", Duration = 3 })
        else
            pcall(function()
                local mc = GetMechanicsController()
                if mc and State.OriginalEquippedItemInput then
                    mc.EquippedItemInput = State.OriginalEquippedItemInput
                    State.OriginalEquippedItemInput = nil
                end
            end)
            Notify({ Title = "Anti-Katana Disabled", Content = "Normal shooting restored", Duration = 3 })
        end
    end)
end)

local WeaponBehaviorSection = Tabs.Weapons:AddSection("Weapon Behavior")
local GunModsSection = Tabs.Weapons:AddSection("Gun Modifications")

G.SolunaState.BulletColorEnabled = false
G.SolunaState.BulletColor = Color3.fromRGB(0, 120, 255)
G.SolunaState.BulletTransparency = 0
G.SolunaState.BulletSize = 1
G.SolunaState.BulletHooked = false
G.SolunaState.WeaponModsHooked = false
G.SolunaState.RapidFireEnabled = false
G.SolunaState.RapidFireSpeed = 0.01
G.SolunaState.NoRecoilEnabled = false
G.SolunaState.RecoilReduction = 100
G.SolunaState.NoSpreadEnabled = false
G.SolunaState.InstantADSEnabled = false

local function SetupWeaponModsHook()
    if State.RequireBlocked or G.SolunaState.WeaponModsHooked then return end
    G.SolunaState.WeaponModsHooked = true
    
    pcall(function()
        local GunModule = GetGunModule()
        local GameplayUtility = GetGameplayUtility()
        
        if GunModule then
            if not G.SolunaState.OriginalGunStartShooting and GunModule.StartShooting then
                G.SolunaState.OriginalGunStartShooting = GunModule.StartShooting
                GunModule.StartShooting = function(self, p26, p27)
                    local oldShootCooldown = nil
                    local oldBurstCooldown = nil
                    if G.SolunaState.RapidFireEnabled then
                        oldShootCooldown = self.Info.ShootCooldown
                        oldBurstCooldown = self.Info.ShootBurstCooldown
                        self.Info.ShootCooldown = G.SolunaState.RapidFireSpeed
                        self.Info.ShootBurstCooldown = G.SolunaState.RapidFireSpeed
                    end
                    local result = { G.SolunaState.OriginalGunStartShooting(self, p26, p27) }
                    if G.SolunaState.RapidFireEnabled then
                        self.Info.ShootCooldown = oldShootCooldown
                        self.Info.ShootBurstCooldown = oldBurstCooldown
                    end
                    return table.unpack(result)
                end
            end
            if not G.SolunaState.OriginalGunRecoil and GunModule._Recoil then
                G.SolunaState.OriginalGunRecoil = GunModule._Recoil
                GunModule._Recoil = function(self, multiplier)
                    if G.SolunaState.NoRecoilEnabled then
                        local recoilMultiplier = multiplier * (1 - G.SolunaState.RecoilReduction / 100)
                        if recoilMultiplier <= 0.001 then return end
                        return G.SolunaState.OriginalGunRecoil(self, recoilMultiplier)
                    end
                    return G.SolunaState.OriginalGunRecoil(self, multiplier)
                end
            end
            if not G.SolunaState.OriginalGunStartAiming and GunModule.StartAiming then
                G.SolunaState.OriginalGunStartAiming = GunModule.StartAiming
                GunModule.StartAiming = function(self, p71)
                    if G.SolunaState.InstantADSEnabled then
                        self:SetReplicate("IsAiming", true)
                        if self.StopSprinting then self.StopSprinting:Fire() end
                        self.ViewModel:SetAiming(true)
                        self:SetReplicate("FOVOffset", self.Info.AimFOVOffset)
                        if self.ViewModel.CurrentAimValue then self.ViewModel.CurrentAimValue = 1 end
                        return true, "StartAiming"
                    end
                    return G.SolunaState.OriginalGunStartAiming(self, p71)
                end
            end
            if not G.SolunaState.OriginalGunGetAimSpeed and GunModule.GetAimSpeed then
                G.SolunaState.OriginalGunGetAimSpeed = GunModule.GetAimSpeed
                GunModule.GetAimSpeed = function(self)
                    if G.SolunaState.InstantADSEnabled then return 999 end
                    return G.SolunaState.OriginalGunGetAimSpeed(self)
                end
            end
        end
        if GameplayUtility and not G.SolunaState.OriginalGameplaySpread and GameplayUtility.GetSpread then
            G.SolunaState.OriginalGameplaySpread = GameplayUtility.GetSpread
            GameplayUtility.GetSpread = function(spread, aimMultiplier, isAiming, isCrouching, pelletIndex, totalPellets, consistent)
                if G.SolunaState.NoSpreadEnabled then return CFrame.new() end
                return G.SolunaState.OriginalGameplaySpread(spread, aimMultiplier, isAiming, isCrouching, pelletIndex, totalPellets, consistent)
            end
        end
    end)
end

local function ApplyRequireBoundGunToggle(toggleId, syncKey, featureName, valueSetter, enabledCallback)
    return function(...)
        if not Options[toggleId] then return end
        local v = Options[toggleId].Value
        if Runtime.FeatureControlSync == syncKey then 
            if valueSetter then valueSetter(v) end 
            return 
        end
        if v and State.RequireBlocked then
            if valueSetter then valueSetter(false) end
            if NotifyUnsupportedFeature then NotifyUnsupportedFeature(featureName) end
            Runtime.FeatureControlSync = syncKey
            Options[toggleId]:SetValue(false)
            Runtime.FeatureControlSync = nil
            return
        end
        if valueSetter then valueSetter(v) end
        if v and SetupWeaponModsHook then SetupWeaponModsHook() end
        if enabledCallback then enabledCallback(v) end
    end
end

local BulletColorToggle = GunModsSection:AddToggle("bullet_color_enabled", { Title = "Custom Bullet Color", Default = false })
BulletColorToggle:OnChanged(function()
    local v = Options.bullet_color_enabled.Value
    if Runtime.FeatureControlSync == "bullet_color_enabled" then G.SolunaState.BulletColorEnabled = v return end
    if v and State.RequireBlocked then
        G.SolunaState.BulletColorEnabled = false
        NotifyUnsupportedFeature("Bullet Mods")
        Runtime.FeatureControlSync = "bullet_color_enabled"
        BulletColorToggle:SetValue(false)
        Runtime.FeatureControlSync = nil
        return
    end
    G.SolunaState.BulletColorEnabled = v
    if v then
        pcall(function()
            local TracerEffect = GetTracerEffect()
            if TracerEffect then
                G.SolunaState.HookedTracerEffect = TracerEffect
                if not G.SolunaState.OriginalTracerPlay then G.SolunaState.OriginalTracerPlay = TracerEffect.Play end
                TracerEffect.Play = function(self, tracerData, tracerSettings, tracerContext)
                    if G.SolunaState.BulletColorEnabled then
                        tracerSettings = tracerSettings or {}
                        local customColor = ColorSequence.new(G.SolunaState.BulletColor)
                        tracerSettings.Color = customColor
                        tracerSettings.Transparency = NumberSequence.new(G.SolunaState.BulletTransparency)
                        if tracerSettings.Size then
                            local originalSize = tracerSettings.Size.Keypoints
                            if #originalSize > 0 then
                                tracerSettings.Size = NumberSequence.new(G.SolunaState.BulletSize, originalSize[#originalSize].Value * G.SolunaState.BulletSize)
                            end
                        end
                    end
                    return G.SolunaState.OriginalTracerPlay(self, tracerData, tracerSettings, tracerContext)
                end
            end
        end)
    end
end)

GunModsSection:AddColorpicker("bullet_color_picker", { Title = "Bullet Color", Default = Color3.fromRGB(0, 120, 255), Callback = function(color) G.SolunaState.BulletColor = color end })
GunModsSection:AddSlider("bullet_transparency", { Title = "Bullet Transparency", Default = 0, Min = 0, Max = 1, Rounding = 1, Callback = function(v) G.SolunaState.BulletTransparency = v end })
GunModsSection:AddSlider("bullet_size", { Title = "Bullet Size", Default = 1, Min = 0.1, Max = 5, Rounding = 1, Callback = function(v) G.SolunaState.BulletSize = v end })

local RapidFireToggle = WeaponBehaviorSection:AddToggle("rapid_fire_enabled", { Title = "Rapid Fire", Default = false })
RapidFireToggle:OnChanged(ApplyRequireBoundGunToggle("rapid_fire_enabled", "rapid_fire_enabled", "Weapon Mods", function(v) G.SolunaState.RapidFireEnabled = v end))

WeaponBehaviorSection:AddSlider("rapid_fire_speed", { Title = "Rapid Fire Cooldown", Default = 0.01, Min = 0.001, Max = 0.5, Rounding = 3, Callback = function(v) G.SolunaState.RapidFireSpeed = v end })

local NoRecoilToggle = WeaponBehaviorSection:AddToggle("no_recoil_enabled", { Title = "No Recoil", Default = false })
NoRecoilToggle:OnChanged(ApplyRequireBoundGunToggle("no_recoil_enabled", "no_recoil_enabled", "Weapon Mods", function(v) G.SolunaState.NoRecoilEnabled = v end))

WeaponBehaviorSection:AddSlider("recoil_reduction", { Title = "Recoil Reduction", Default = 100, Min = 0, Max = 100, Rounding = 0, Callback = function(v) G.SolunaState.RecoilReduction = v end })

local NoSpreadToggle = WeaponBehaviorSection:AddToggle("no_spread_enabled", { Title = "No Spread", Default = false })
NoSpreadToggle:OnChanged(ApplyRequireBoundGunToggle("no_spread_enabled", "no_spread_enabled", "Weapon Mods", function(v) G.SolunaState.NoSpreadEnabled = v end))

local InstantADSToggle = WeaponBehaviorSection:AddToggle("instant_ads_enabled", { Title = "Instant ADS", Default = false })
InstantADSToggle:OnChanged(ApplyRequireBoundGunToggle("instant_ads_enabled", "instant_ads_enabled", "Weapon Mods", function(v) G.SolunaState.InstantADSEnabled = v end))

local HitSoundsSection = Tabs.Weapons:AddSection("Hit Sounds")
G.SolunaState.CustomHitSoundsEnabled = false
G.SolunaState.CustomHeadshotSoundId = "rbxassetid://16537449730"
G.SolunaState.CustomBodyshotSoundId = "rbxassetid://13110130082"

local HitSoundPresets = {
    ["Default"] = { headshot = "rbxassetid://16537449730", bodyshot = "rbxassetid://13110130082" },
    ["Minecraft"] = { headshot = "rbxassetid://4018616850", bodyshot = "rbxassetid://4018616850" },
    ["Meow"] = { headshot = "rbxassetid://7148585764", bodyshot = "rbxassetid://7148585764" },
}

local CustomHitSoundsToggle = HitSoundsSection:AddToggle("custom_hitsounds", { Title = "Enabled", Default = false })
CustomHitSoundsToggle:OnChanged(function()
    local v = Options.custom_hitsounds.Value
    if Runtime.FeatureControlSync == "custom_hitsounds" then G.SolunaState.CustomHitSoundsEnabled = v return end
    if v and State.RequireBlocked then
        G.SolunaState.CustomHitSoundsEnabled = false
        NotifyUnsupportedFeature("Custom Hit Sounds")
        Runtime.FeatureControlSync = "custom_hitsounds"
        CustomHitSoundsToggle:SetValue(false)
        Runtime.FeatureControlSync = nil
        return
    end
    G.SolunaState.CustomHitSoundsEnabled = v
    if v then
        pcall(function()
            local ClientViewModel = GetClientViewModelModule()
            if ClientViewModel and not G.SolunaState.OriginalPlayHitmarkerSound then
                G.SolunaState.OriginalPlayHitmarkerSound = ClientViewModel.PlayHitmarkerSound
                ClientViewModel.PlayHitmarkerSound = function(self, isHeadshot, hitCount)
                    if G.SolunaState.CustomHitSoundsEnabled then
                        local soundId = isHeadshot and G.SolunaState.CustomHeadshotSoundId or G.SolunaState.CustomBodyshotSoundId
                        local sound = Instance.new("Sound")
                        sound.SoundId = soundId
                        sound.Volume = isHeadshot and 3 / (hitCount or 1) or 1.5 / (hitCount or 1)
                        sound.PlaybackSpeed = 1 + 0.2 * math.random()
                        sound.Parent = Services.SoundService
                        sound:Play()
                        Services.Debris:AddItem(sound, 2)
                    else
                        return G.SolunaState.OriginalPlayHitmarkerSound(self, isHeadshot, hitCount)
                    end
                end
            end
        end)
        Notify({ Title = "Custom Hit Sounds", Content = "Hit sounds have been customized", Duration = 3 })
    end
end)

HitSoundsSection:AddDropdown("hitsound_preset", { Title = "Sound Preset", Values = {"Default", "Minecraft", "Meow"}, Default = "Default", Multi = false, Callback = function(v)
    local preset = HitSoundPresets[v] or HitSoundPresets["Default"]
    G.SolunaState.CustomHeadshotSoundId = preset.headshot
    G.SolunaState.CustomBodyshotSoundId = preset.bodyshot
end })

local FlySection = Tabs.Player:AddSection("Fly")
local MovementSection = Tabs.Player:AddSection("Movement")
local CameraSection = Tabs.Player:AddSection("Camera")

local function SetupRequireSlideModifierHook()
    if Runtime.RequireSlideHooked then return end
    local mechanicsController = GetMechanicsController()
    if not mechanicsController then return end
    Runtime.RequireSlideHooked = true
end

local function SetupMovementHooks()
    SetupRequireSlideModifierHook()
end

local function DestroyWalkSpeedModifier()
    if Runtime.WalkSpeedBodyVelocity then
        pcall(function() Runtime.WalkSpeedBodyVelocity:Destroy() end)
        Runtime.WalkSpeedBodyVelocity = nil
    end
end

local function UpdateWalkSpeedModifier()
    if not State.WalkSpeedEnabled then
        DestroyWalkSpeedModifier()
        return
    end
    local character = Config.LocalPlayer.Character
    local humanoid = character and character:FindFirstChild("Humanoid")
    local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not humanoidRootPart then
        DestroyWalkSpeedModifier()
        return
    end
    if humanoid.MoveDirection.Magnitude <= 0 then
        if Runtime.WalkSpeedBodyVelocity then
            Runtime.WalkSpeedBodyVelocity.Velocity = Vector3.zero
        end
        return
    end
    if not Runtime.WalkSpeedBodyVelocity then
        Runtime.WalkSpeedBodyVelocity = Instance.new("BodyVelocity")
        Runtime.WalkSpeedBodyVelocity.Name = "AstraWalkSpeedModifier"
        Runtime.WalkSpeedBodyVelocity.MaxForce = Vector3.new(50000, 0, 50000)
        Runtime.WalkSpeedBodyVelocity.P = 1000
        Runtime.WalkSpeedBodyVelocity.Parent = humanoidRootPart
    elseif Runtime.WalkSpeedBodyVelocity.Parent ~= humanoidRootPart then
        Runtime.WalkSpeedBodyVelocity.Parent = humanoidRootPart
    end
    Runtime.WalkSpeedBodyVelocity.Velocity = humanoid.MoveDirection.Unit * State.WalkSpeedValue
end

local function SetupWalkSpeedHook()
    if Runtime.WalkSpeedConnection then return end
    Runtime.WalkSpeedConnection = Services.RunService.Heartbeat:Connect(function()
        UpdateWalkSpeedModifier()
    end)
end

local InfiniteJumpToggle = MovementSection:AddToggle("infinite_jump", { Title = "Infinite Jump", Default = false })
InfiniteJumpToggle:OnChanged(function()
    local v = Options.infinite_jump.Value
    if Runtime.FeatureControlSync == "infinite_jump" then State.InfiniteJump = v return end
    State.InfiniteJump = v
end)

local jumpGuard = false
local function PerformInfiniteJump()
    local character = Config.LocalPlayer.Character
    local humanoid = character and character:FindFirstChild("Humanoid")
    if not humanoid then return end
    jumpGuard = true
    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    humanoid.Jump = true
    task.defer(function() jumpGuard = false end)
end

local InfiniteJumpConnection = Services.UserInputService.JumpRequest:Connect(function()
    if State.InfiniteJump and not jumpGuard then PerformInfiniteJump() end
end)

local SlideModifierToggle = MovementSection:AddToggle("slide_modifier", { Title = "Slide Modifier", Default = false })
SlideModifierToggle:OnChanged(function()
    local v = Options.slide_modifier.Value
    if Runtime.FeatureControlSync == "slide_modifier" then State.SlideEnabled = v return end
    if v and State.RequireBlocked then
        State.SlideEnabled = false
        NotifyUnsupportedFeature("Slide Modifier")
        Runtime.FeatureControlSync = "slide_modifier"
        SlideModifierToggle:SetValue(false)
        Runtime.FeatureControlSync = nil
        return
    end
    State.SlideEnabled = v
    if v then SetupMovementHooks() end
end)

local WalkSpeedToggle = MovementSection:AddToggle("walkspeed_enabled", { Title = "Walkspeed", Default = false })
WalkSpeedToggle:OnChanged(function()
    local v = Options.walkspeed_enabled.Value
    if Runtime.FeatureControlSync == "walkspeed_enabled" then State.WalkSpeedEnabled = v return end
    State.WalkSpeedEnabled = v
    if v then SetupWalkSpeedHook() else DestroyWalkSpeedModifier() end
end)

MovementSection:AddSlider("walkspeed_value", { Title = "Walkspeed Value", Default = 50, Min = 1, Max = 200, Rounding = 0, Callback = function(v) State.WalkSpeedValue = v end })
MovementSection:AddSlider("slide_speed", { Title = "Slide Speed Multiplier", Default = 1, Min = 1, Max = 10, Rounding = 1, Callback = function(v) State.SlideSpeed = v end })
MovementSection:AddSlider("slide_duration", { Title = "Slide Duration Multiplier", Default = 1, Min = 1, Max = 10, Rounding = 1, Callback = function(v) State.SlideDuration = v end })

local FlyEnabled = false
local FlySpeed = 50
local FlyConnection = nil
local BodyGyro = nil
local BodyVelocity = nil

local function StopFly()
    if FlyConnection then FlyConnection:Disconnect(); FlyConnection = nil end
    if BodyGyro then BodyGyro:Destroy(); BodyGyro = nil end
    if BodyVelocity then BodyVelocity:Destroy(); BodyVelocity = nil end
end

local function StartFly()
    StopFly()
    local character = Config.LocalPlayer.Character
    if not character then return end
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoidRootPart or not humanoid then return end
    BodyGyro = Instance.new("BodyGyro")
    BodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    BodyGyro.P = 9e4
    BodyGyro.Parent = humanoidRootPart
    BodyVelocity = Instance.new("BodyVelocity")
    BodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    BodyVelocity.Velocity = Vector3.new(0, 0, 0)
    BodyVelocity.Parent = humanoidRootPart
    FlyConnection = Services.RunService.RenderStepped:Connect(function()
        if not FlyEnabled then return end
        local moveDirection = Vector3.new(0, 0, 0)
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDirection = moveDirection + Services.Camera.CFrame.LookVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDirection = moveDirection - Services.Camera.CFrame.LookVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDirection = moveDirection - Services.Camera.CFrame.RightVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDirection = moveDirection + Services.Camera.CFrame.RightVector end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDirection = moveDirection + Vector3.new(0, 1, 0) end
        if Services.UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or Services.UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDirection = moveDirection - Vector3.new(0, 1, 0) end
        if moveDirection.Magnitude > 0 then moveDirection = moveDirection.Unit end
        if BodyVelocity and BodyVelocity.Parent then BodyVelocity.Velocity = moveDirection * FlySpeed end
        if BodyGyro and BodyGyro.Parent then BodyGyro.CFrame = Services.Camera.CFrame end
    end)
end

FlySection:AddToggle("fly_enabled", { Title = "Enabled", Default = false, Callback = function(v)
    FlyEnabled = v
    if v then
        StartFly()
        Notify({ Title = "Fly Enabled", Content = "Use WASD/Space/Ctrl to move", Duration = 3 })
    else
        StopFly()
    end
end })

FlySection:AddKeybind("fly_bind", { Title = "Fly Key", Mode = "Toggle", Default = "T", Callback = function(Value)
    if Options.fly_enabled then Options.fly_enabled:SetValue(Value) end
end })

FlySection:AddSlider("fly_speed", { Title = "Speed", Default = 50, Min = 10, Max = 200, Rounding = 0, Callback = function(v) FlySpeed = v end })

local ThirdPersonEnabled = false
local OriginalHasThirdPersonAccess = nil

local function EnableThirdPerson(enabled)
    if State.RequireBlocked then return end
    local cc = GetCameraController()
    if not cc then return end
    if enabled then
        if not OriginalHasThirdPersonAccess and cc.HasThirdPersonAccess then
            OriginalHasThirdPersonAccess = cc.HasThirdPersonAccess
            cc.HasThirdPersonAccess = function(self, ...)
                if ThirdPersonEnabled then return true end
                return OriginalHasThirdPersonAccess(self, ...)
            end
        end
        cc._third_person_override = true
        if cc.CameraState and cc.CameraState.VerifyPOV then pcall(function() cc.CameraState:VerifyPOV() end) end
    else
        cc._third_person_override = nil
        if cc.CameraState and cc.CameraState.VerifyPOV then pcall(function() cc.CameraState:VerifyPOV() end) end
    end
end

local ThirdPersonToggle = CameraSection:AddToggle("third_person", { Title = "Third Person", Default = false })
ThirdPersonToggle:OnChanged(function()
    local v = Options.third_person.Value
    if Runtime.FeatureControlSync == "third_person" then ThirdPersonEnabled = v return end
    if v and State.RequireBlocked then
        ThirdPersonEnabled = false
        NotifyUnsupportedFeature("Third Person")
        Runtime.FeatureControlSync = "third_person"
        ThirdPersonToggle:SetValue(false)
        Runtime.FeatureControlSync = nil
        return
    end
    ThirdPersonEnabled = v
    EnableThirdPerson(v)
    if v then Notify({ Title = "Third Person Enabled", Content = "Press B to change your camera perspective", Duration = 4 }) end
end)

local ChamsSection = Tabs.ESP:AddSection("Chams")
ChamsSection:AddToggle("chams_enabled", { Title = "Enabled", Default = false, Callback = function(v) 
    ChamsSettings.Enabled = v 
    State.ChamsEnabled = v
    local players = Services.Players:GetPlayers()
    for i = 1, #players do
        local p = players[i]
        if p ~= Config.LocalPlayer then
            local tag = "hx_" .. p.UserId
            local obj = ChamsTargetContainer:FindFirstChild(tag)
            if obj then
                obj.Enabled = v
            end
        end
    end
end })

ChamsSection:AddColorpicker("chams_color", { Title = "Fill Color", Default = Color3.fromRGB(50, 150, 255), Callback = function(v) ChamsSettings.Color = v end })
ChamsSection:AddColorpicker("chams_outline_color", { Title = "Outline Color", Default = Color3.fromRGB(0, 0, 0), Callback = function(v) ChamsSettings.OutlineColor = v end })
ChamsSection:AddSlider("chams_fill_transparency", { Title = "Fill Transparency", Default = 0.45, Min = 0, Max = 1, Rounding = 2, Callback = function(v) ChamsSettings.FillTransparency = v end })
ChamsSection:AddSlider("chams_outline_transparency", { Title = "Outline Transparency", Default = 0, Min = 0, Max = 1, Rounding = 2, Callback = function(v) ChamsSettings.OutlineTransparency = v end })

local TargetInfoSection = Tabs.ESP:AddSection("Target Info")
TargetInfoSection:AddToggle("target_info_enabled", { 
    Title = "Show Target Info", 
    Default = false, 
    Callback = function(v) 
        State.ShowTargetInfo = v
        if not v then 
            if Runtime.TargetInfoFrame then Runtime.TargetInfoFrame.Visible = false end
            Runtime.CurrentTarget = nil
        end
    end 
})

local ESPSettingsSection = Tabs.ESP:AddSection("Checks")
ESPSettingsSection:AddToggle("esp_team_check", { Title = "Team Check", Default = true, Callback = function(v) ESPSettings.ESPTeamCheck = v end })
ESPSettingsSection:AddSlider("esp_max_distance", { Title = "Max Distance", Default = 2000, Min = 100, Max = 5000, Rounding = 0, Callback = function(v) ESPSettings.MaxESPDistance = v end })

local ParticlesSection = Tabs.Misc:AddSection("Particles")
ParticlesSection:AddButton({ Title = "No Flash", Callback = function()
    pcall(function()
        local flashEffect = Config.LocalPlayer.PlayerScripts.Assets.Misc:FindFirstChild("FlashbangEffect")
        if flashEffect then
            flashEffect:Destroy()
            Notify({ Title = "Flashbang Removed", Content = "Flashbang effects have been disabled", Duration = 3 })
        else
            Notify({ Title = "Already Removed", Content = "Flashbang effects are already disabled", Duration = 3 })
        end
    end)
end })

ParticlesSection:AddButton({ Title = "No Smoke", Callback = function()
    pcall(function()
        local smokeEffect = Config.LocalPlayer.PlayerScripts.Assets.Misc:FindFirstChild("SmokeClouds")
        if smokeEffect then
            smokeEffect:Destroy()
            Notify({ Title = "Smoke Removed", Content = "Smoke effects have been disabled", Duration = 3 })
        else
            Notify({ Title = "Already Removed", Content = "Smoke effects are already disabled", Duration = 3 })
        end
    end)
end })

local DeviceSpoofSection = Tabs.Misc:AddSection("Device Spoofer")
DeviceSpoofSection:AddDropdown("device_spoof", { Title = "Spoof Device", Values = {"Computer", "Mobile", "Console", "VR"}, Default = "Computer", Multi = false, Callback = function(v)
    local devices = { Computer = "MouseKeyboard", Mobile = "Touch", Console = "Gamepad", VR = "VR" }
    local deviceString = devices[v]
    if deviceString then
        pcall(function()
            local remotes = Services.ReplicatedStorage:FindFirstChild("Remotes")
            if remotes then
                local replication = remotes:FindFirstChild("Replication")
                if replication then
                    local fighter = replication:FindFirstChild("Fighter")
                    if fighter then
                        local setControls = fighter:FindFirstChild("SetControls")
                        if setControls then setControls:FireServer(deviceString) end
                    end
                end
            end
            Notify({ Title = "Device Spoofed", Content = "Now spoofed as " .. v, Duration = 3 })
        end)
    end
end })

local RewardsSection = Tabs.Misc:AddSection("Rewards")
RewardsSection:AddButton({ Title = "Claim All Rewards", Callback = function()
    pcall(function()
        local remotes = Services.ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then
            local data = remotes:FindFirstChild("Data")
            if data then
                if data.ClaimLikeReward then data.ClaimLikeReward:FireServer() end
                if data.ClaimFavoriteReward then data.ClaimFavoriteReward:FireServer() end
                if data.ClaimNotificationsReward then data.ClaimNotificationsReward:FireServer() end
                if data.ClaimWelcomeBackGift then data.ClaimWelcomeBackGift:FireServer() end
            end
        end
        Notify({ Title = "Rewards Claimed", Content = "All available rewards have been claimed!", Duration = 3 })
    end)
end })

RewardsSection:AddButton({ Title = "Claim All Codes", Callback = function()
    pcall(function()
        local remotes = Services.ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then
            local data = remotes:FindFirstChild("Data")
            if data then
                if data.VerifyTwitter then data.VerifyTwitter:FireServer() end
                local codes = { "COMMUNITY19", "FREE131", "BONUS", "ROBLOX_RTC", "BOOST" }
                for _, code in ipairs(codes) do
                    if data.RedeemCode then pcall(function() data.RedeemCode:InvokeServer(code) end) end
                end
            end
        end
        Notify({ Title = "Codes Redeemed", Content = "All known codes have been redeemed!", Duration = 3 })
    end)
end })

G.SolunaState.SkinChangerEnabled = false
G.SolunaState.SkinChangerHooked = false
G.SolunaState.SelectedSkins = G.SolunaState.SelectedSkins or {}
G.SolunaState.AvailableSkins = {}
G.SolunaState.WeaponToSkins = {}
G.SolunaState.WeaponCatalog = {}
G.SolunaState.SkinWatcherConnections = {}
G.SolunaState.ProcessedSkinModels = {}

G.SolunaSkinRuntime.UsesHardcodedSkinChanger = function()
    return ExecutorNameLower == "xeno" or ExecutorNameLower == "solara"
end

G.SolunaSkinRuntime.WeaponPlaceholderImage = "rbxassetid://9968344227"
G.SolunaSkinRuntime.SkinPlaceholderImage = "rbxassetid://8992230677"
G.SolunaSkinRuntime.ViewModelImageMap = {
    ["10B Visits"] = "rbxassetid://101791753953377",
    ["AK-47"] = "rbxassetid://17691136128",
    ["AKEY-47"] = "rbxassetid://77244120212187",
    ["AUG"] = "rbxassetid://18770201102",
    ["Aces"] = "rbxassetid://78850921968876",
    ["Advanced Satchel"] = "rbxassetid://118684510688617",
    ["Air Horn"] = "rbxassetid://128732687072177",
    ["Anchor"] = "rbxassetid://18769023932",
    ["Apex Pistols"] = "rbxassetid://132394469151873",
    ["Apex Rifle"] = "rbxassetid://111748806401551",
    ["Aqua Burst"] = "rbxassetid://18837677725",
    ["Arcane Warper"] = "rbxassetid://92765478127490",
    ["Arch Crossbow"] = "rbxassetid://107213949119266",
    ["Arch Katana"] = "rbxassetid://98068422294741",
    ["Armature.001"] = "rbxassetid://91555068782550",
    ["Assault Rifle"] = "rbxassetid://13197584241",
    ["Bag o' Money"] = "rbxassetid://118634288543707",
    ["Balance"] = "rbxassetid://18766909964",
    ["Balisong"] = "rbxassetid://114825371645118",
    ["Balloon Shorty"] = "rbxassetid://87872312114961",
    ["Balloon Shotgun"] = "rbxassetid://17821266090",
    ["Ban Axe"] = "rbxassetid://100159715604530",
    ["Banana Flare"] = "rbxassetid://135246839855870",
    ["Bat Bow"] = "rbxassetid://71508472340303",
    ["Bat Daggers"] = "rbxassetid://137570635514267",
    ["Bat Scythe"] = "rbxassetid://104168535403995",
    ["Battle Axe"] = "rbxassetid://78364101927650",
    ["Blaster"] = "rbxassetid://17821265750",
    ["Blobsaw"] = "rbxassetid://17825961425",
    ["Boba Gun"] = "rbxassetid://18768828072",
    ["Boneblade"] = "rbxassetid://126287813768518",
    ["Boneclaw Horn"] = "rbxassetid://126578341307256",
    ["Boneclaw Revolver"] = "rbxassetid://134217952089145",
    ["Boneclaw Rifle"] = "rbxassetid://116725320040796",
    ["Boneclaw Spray"] = "rbxassetid://127336875478381",
    ["Boneshot"] = "rbxassetid://103283614012077",
    ["Bounce House"] = "rbxassetid://79326657484315",
    ["Bow"] = "rbxassetid://13717212331",
    ["Boxing Gloves"] = "rbxassetid://17672089761",
    ["Brain Gun"] = "rbxassetid://135843933439701",
    ["Brass Knuckles"] = "rbxassetid://18766909587",
    ["Briefcase"] = "rbxassetid://18142174697",
    ["Broomstick"] = "rbxassetid://126607371232554",
    ["Bubble Ray"] = "rbxassetid://18769002868",
    ["Bucket of Candy"] = "rbxassetid://95706110401359",
    ["Bug Net"] = "rbxassetid://99173928762511",
    ["Burst Rifle"] = "rbxassetid://13482243466",
    ["Buzzsaw"] = "rbxassetid://128354991167944",
    ["Cactus Shotgun"] = "rbxassetid://128141817339029",
    ["Camera"] = "rbxassetid://18766908915",
    ["Candy Cane"] = "rbxassetid://84302121354096",
    ["Cerulean Axe"] = "rbxassetid://82989708806032",
    ["Chainsaw"] = "rbxassetid://13717445410",
    ["Chancla"] = "rbxassetid://17672089600",
    ["Coffee"] = "rbxassetid://17672089358",
    ["Compound Bow"] = "rbxassetid://17672229023",
    ["Cookies"] = "rbxassetid://112581667413176",
    ["Crossbone"] = "rbxassetid://81476287380261",
    ["Crossbow"] = "rbxassetid://130065160832422",
    ["Crude Gunblade"] = "rbxassetid://111573250598753",
    ["Cryo Scythe"] = "rbxassetid://84690820919174",
    ["Crystal Daggers"] = "rbxassetid://92405854307880",
    ["Crystal Katana"] = "rbxassetid://107573852829996",
    ["Crystal Scythe"] = "rbxassetid://88778703942724",
    ["Cyber Distortion"] = "rbxassetid://78940266607471",
    ["Cyber Warpstone"] = "rbxassetid://78671282003316",
    ["DIY Tripmine"] = "rbxassetid://105200997776122",
    ["Daggers"] = "rbxassetid://138508026547275",
    ["Demon Shorty"] = "rbxassetid://110819203451709",
    ["Demon Uzi"] = "rbxassetid://81076572654230",
    ["Desert Eagle"] = "rbxassetid://17821265603",
    ["Dev-in-the-Box"] = "rbxassetid://93100882010950",
    ["Disco Ball"] = "rbxassetid://17672089136",
    ["Distortion"] = "rbxassetid://130153907701944",
    ["Don't Press"] = "rbxassetid://17821264419",
    ["Door"] = "rbxassetid://137027368393353",
    ["Dream Bow"] = "rbxassetid://104571173348964",
    ["Dynamite"] = "rbxassetid://97225646481020",
    ["Dynamite Gun"] = "rbxassetid://17691136322",
    ["Electro Rifle"] = "rbxassetid://87621360986223",
    ["Electro Uzi"] = "rbxassetid://98294074022488",
    ["Electropunk Distortion"] = "rbxassetid://91778033503945",
    ["Electropunk Warper"] = "rbxassetid://96080679722284",
    ["Electropunk Warpstone"] = "rbxassetid://121167052087315",
    ["Elf's Gunblade"] = "rbxassetid://81214817732179",
    ["Emoji Cloud"] = "rbxassetid://17821265237",
    ["Energy Pistols"] = "rbxassetid://125338509278840",
    ["Energy Rifle"] = "rbxassetid://103736834693278",
    ["Energy Shield"] = "rbxassetid://127037252186171",
    ["Event Horizon"] = "rbxassetid://82446563771968",
    ["Exogourd"] = "rbxassetid://125880131168138",
    ["Exogun"] = "rbxassetid://17344797370",
    ["Experiment D15"] = "rbxassetid://118366946179457",
    ["Experiment W4"] = "rbxassetid://77873591123909",
    ["Eyeball"] = "rbxassetid://103493376163318",
    ["Eyething Sniper"] = "rbxassetid://96377501719526",
    ["FAMAS"] = "rbxassetid://110423034763836",
    ["Festive Buzzsaw"] = "rbxassetid://111566667788893",
    ["Festive Fists"] = "rbxassetid://98061476050478",
    ["Fighter Jet"] = "rbxassetid://95650502925488",
    ["Firework Gun"] = "rbxassetid://17691136322",
    ["Firework Launcher"] = "rbxassetid://93131277391830",
    ["Fists"] = "rbxassetid://16560051320",
    ["Fists of Hurt"] = "rbxassetid://71585039030211",
    ["Flamethrower"] = "rbxassetid://85223987405833",
    ["Flare Gun"] = "rbxassetid://13197583892",
    ["Flashbang"] = "rbxassetid://14664488253",
    ["Freeze Ray"] = "rbxassetid://18429549331",
    ["Frost Warper"] = "rbxassetid://84458438183331",
    ["Frostbite Bow"] = "rbxassetid://82246935699705",
    ["Frostbite Crossbow"] = "rbxassetid://116171878456521",
    ["Frozen Grenade"] = "rbxassetid://101932886938992",
    ["Garden Shovel"] = "rbxassetid://18766908058",
    ["Gearnade Launcher"] = "rbxassetid://91208130484582",
    ["Gingerbread AUG"] = "rbxassetid://108476862508992",
    ["Gingerbread Handgun"] = "rbxassetid://72714528734588",
    ["Gingerbread Sniper"] = "rbxassetid://120163896680390",
    ["Glitter Warper"] = "rbxassetid://128289126916762",
    ["Glitterthrower"] = "rbxassetid://83419562243412",
    ["Glorious Assault Rifle"] = "rbxassetid://130592949312939",
    ["Glorious Battle Axe"] = "rbxassetid://72356106057179",
    ["Glorious Bow"] = "rbxassetid://139021383472653",
    ["Glorious Burst Rifle"] = "rbxassetid://125258150017244",
    ["Glorious Chainsaw"] = "rbxassetid://140353527719287",
    ["Glorious Crossbow"] = "rbxassetid://125494419498405",
    ["Glorious Daggers"] = "rbxassetid://89590724074968",
    ["Glorious Distortion"] = "rbxassetid://107736694179886",
    ["Glorious Energy Pistols"] = "rbxassetid://85080210873739",
    ["Glorious Energy Rifle"] = "rbxassetid://95552510838071",
    ["Glorious Exogun"] = "rbxassetid://105785189977176",
    ["Glorious Fists"] = "rbxassetid://79755997614985",
    ["Glorious Flamethrower"] = "rbxassetid://88697784394796",
    ["Glorious Flare Gun"] = "rbxassetid://128135635660577",
    ["Glorious Flashbang"] = "rbxassetid://131190784940519",
    ["Glorious Freeze Ray"] = "rbxassetid://96505833323714",
    ["Glorious Grenade"] = "rbxassetid://102502933883025",
    ["Glorious Grenade Launcher"] = "rbxassetid://133636006123737",
    ["Glorious Gunblade"] = "rbxassetid://88582922101753",
    ["Glorious Handgun"] = "rbxassetid://73041314820303",
    ["Glorious Jump Pad"] = "rbxassetid://96408475917789",
    ["Glorious Katana"] = "rbxassetid://94429900086533",
    ["Glorious Knife"] = "rbxassetid://122760026905111",
    ["Glorious Maul"] = "rbxassetid://109898315901573",
    ["Glorious Medkit"] = "rbxassetid://73397457340415",
    ["Glorious Minigun"] = "rbxassetid://99372535399034",
    ["Glorious Molotov"] = "rbxassetid://95650602989880",
    ["Glorious Paintball Gun"] = "rbxassetid://92272641219379",
    ["Glorious Permafrost"] = "rbxassetid://82134252571554",
    ["Glorious RPG"] = "rbxassetid://77567945870953",
    ["Glorious Revolver"] = "rbxassetid://137749607553707",
    ["Glorious Riot Shield"] = "rbxassetid://117405461442739",
    ["Glorious Satchel"] = "rbxassetid://85737788428846",
    ["Glorious Scythe"] = "rbxassetid://113721128462866",
    ["Glorious Shorty"] = "rbxassetid://78845944937729",
    ["Glorious Shotgun"] = "rbxassetid://104100596412940",
    ["Glorious Slingshot"] = "rbxassetid://111031840425662",
    ["Glorious Smoke Grenade"] = "rbxassetid://121565824954563",
    ["Glorious Sniper"] = "rbxassetid://94794978921271",
    ["Glorious Spray"] = "rbxassetid://103484739840527",
    ["Glorious Subspace Tripmine"] = "rbxassetid://80869057489077",
    ["Glorious Trowel"] = "rbxassetid://132433921578446",
    ["Glorious Uzi"] = "rbxassetid://121978889022374",
    ["Glorious War Horn"] = "rbxassetid://123021790391323",
    ["Glorious Warper"] = "rbxassetid://117284572803988",
    ["Glorious Warpstone"] = "rbxassetid://99142505492556",
    ["Goalpost"] = "rbxassetid://17672086378",
    ["Grenade"] = "rbxassetid://14526777692",
    ["Grenade Launcher"] = "rbxassetid://17250456230",
    ["Gum Ray"] = "rbxassetid://124339207784760",
    ["Gumball Handgun"] = "rbxassetid://138794077251754",
    ["Gunblade"] = "rbxassetid://131462750179690",
    ["Gunsaw"] = "rbxassetid://136642950174663",
    ["Hacker Pistols"] = "rbxassetid://105705939354438",
    ["Hacker Rifle"] = "rbxassetid://89213922790170",
    ["Hand Gun"] = "rbxassetid://18837677423",
    ["Handgun"] = "rbxassetid://13197583693",
    ["Handsaws"] = "rbxassetid://18769002596",
    ["Harp"] = "rbxassetid://89702051394732",
    ["Harpoon Crossbow"] = "rbxassetid://127546301627893",
    ["Hot Coals"] = "rbxassetid://98070129509602",
    ["Hotel Bell"] = "rbxassetid://74303585805484",
    ["Hourglass"] = "rbxassetid://70423041582442",
    ["Hydro Pistols"] = "rbxassetid://102390688726302",
    ["Hydro Rifle"] = "rbxassetid://101984348353475",
    ["Hyper Gunblade"] = "rbxassetid://134499903901922",
    ["Hyper Shotgun"] = "rbxassetid://18768974410",
    ["Hyper Sniper"] = "rbxassetid://18766907266",
    ["Ice Maul"] = "rbxassetid://79987597452893",
    ["Ice Permafrost"] = "rbxassetid://122848886028890",
    ["Jack O'Thrower"] = "rbxassetid://81280342017495",
    ["Jingle Grenade"] = "rbxassetid://117226824301607",
    ["Jolly Man"] = "rbxassetid://98002300428288",
    ["Jump Pad"] = "rbxassetid://102532564314723",
    ["Karambit"] = "rbxassetid://18766907079",
    ["Katana"] = "rbxassetid://13968137196",
    ["Ketchup Gun"] = "rbxassetid://130402361506639",
    ["Key Bow"] = "rbxassetid://101924188286368",
    ["Keylisong"] = "rbxassetid://118944160521617",
    ["Keynade"] = "rbxassetid://122922810220976",
    ["Keynais"] = "rbxassetid://133742080595679",
    ["Keyper"] = "rbxassetid://122634584511896",
    ["Keyrambit"] = "rbxassetid://73252950434501",
    ["Keyst Rifle"] = "rbxassetid://138268719789353",
    ["Keytana"] = "rbxassetid://120478111112813",
    ["Keythe"] = "rbxassetid://75967374711732",
    ["Keyttle Axe"] = "rbxassetid://100168194779130",
    ["Keyvolver"] = "rbxassetid://73746116648532",
    ["Keyzi"] = "rbxassetid://127937206087121",
    ["Knife"] = "rbxassetid://13197583583",
    ["Lamethrower"] = "rbxassetid://18766906741",
    ["Laptop"] = "rbxassetid://18766906510",
    ["Lasergun 3000"] = "rbxassetid://116040043955852",
    ["Lava Lamp"] = "rbxassetid://76191080417885",
    ["Lightbulb"] = "rbxassetid://78421244256536",
    ["Lightning Bolt"] = "rbxassetid://18769002278",
    ["Lovely Shorty"] = "rbxassetid://18766906011",
    ["Lovely Spray"] = "rbxassetid://138177960576401",
    ["Machete"] = "rbxassetid://90332754966135",
    ["Magma Distortion"] = "rbxassetid://109079139956898",
    ["Mammoth Horn"] = "rbxassetid://107659166723688",
    ["Masterpiece"] = "rbxassetid://72274483575028",
    ["Maul"] = "rbxassetid://96956174894354",
    ["Medkit"] = "rbxassetid://13717497368",
    ["Medkitty"] = "rbxassetid://126646607101307",
    ["Mega Drill"] = "rbxassetid://78828669740807",
    ["Megaphone"] = "rbxassetid://100739584109870",
    ["Midnight Festive Exogun"] = "rbxassetid://80015495064851",
    ["Milk & Cookies"] = "rbxassetid://73601847002267",
    ["Mimic Axe"] = "rbxassetid://96746396437552",
    ["Minigun"] = "rbxassetid://17250457775",
    ["Molotov"] = "rbxassetid://83303332331234",
    ["Money Gun"] = "rbxassetid://73092203311844",
    ["Nail Gun"] = "rbxassetid://79527532659144",
    ["New Year Energy Pistols"] = "rbxassetid://88240834599421",
    ["New Year Energy Rifle"] = "rbxassetid://101868484686291",
    ["New Year Katana"] = "rbxassetid://79288379571855",
    ["Nordic Axe"] = "rbxassetid://86476943038006",
    ["Not So Shorty"] = "rbxassetid://17672087325",
    ["Notebook Satchel"] = "rbxassetid://85589408404069",
    ["Nuke Launcher"] = "rbxassetid://17672088925",
    ["Paintball Gun"] = "rbxassetid://16560547676",
    ["Paintbrush"] = "rbxassetid://83196688094998",
    ["Paper Planes"] = "rbxassetid://90572065167686",
    ["Pencil Launcher"] = "rbxassetid://74125168400547",
    ["Peppergun"] = "rbxassetid://112311707478578",
    ["Peppermint Sheriff"] = "rbxassetid://71229586558137",
    ["Permafrost"] = "rbxassetid://78468628083590",
    ["Phoenix Rifle"] = "rbxassetid://115604025497445",
    ["Pine Burst"] = "rbxassetid://100589243117991",
    ["Pine Spray"] = "rbxassetid://79010014206302",
    ["Pine Uzi"] = "rbxassetid://80778273701013",
    ["Pixel Burst"] = "rbxassetid://81440970309830",
    ["Pixel Crossbow"] = "rbxassetid://129836248906904",
    ["Pixel Flamethrower"] = "rbxassetid://17771753119",
    ["Pixel Flashbang"] = "rbxassetid://82894448978638",
    ["Pixel Handgun"] = "rbxassetid://72665687846028",
    ["Pixel Katana"] = "rbxassetid://83686692916164",
    ["Pixel Minigun"] = "rbxassetid://18769001642",
    ["Pixel Sniper"] = "rbxassetid://17676083400",
    ["Plasma Distortion"] = "rbxassetid://83622093873798",
    ["Plastic Shovel"] = "rbxassetid://17672088012",
    ["Potion Satchel"] = "rbxassetid://112434777433399",
    ["Pumpkin Carver"] = "rbxassetid://130169648063116",
    ["Pumpkin Claws"] = "rbxassetid://110587168549532",
    ["Pumpkin Handgun"] = "rbxassetid://92824393890642",
    ["Pumpkin Launcher"] = "rbxassetid://130301464984534",
    ["Pumpkin Minigun"] = "rbxassetid://101609024294564",
    ["RPG"] = "rbxassetid://13197583434",
    ["RPKEY"] = "rbxassetid://122750504849596",
    ["Raven Bow"] = "rbxassetid://18766905321",
    ["Ray Gun"] = "rbxassetid://18766905089",
    ["Reindeer Slingshot"] = "rbxassetid://106406735551091",
    ["Repulsor"] = "rbxassetid://130472229545721",
    ["Revolver"] = "rbxassetid://14020829500",
    ["Riot Shield"] = "rbxassetid://126785276332335",
    ["Saber"] = "rbxassetid://17672087756",
    ["Sakura Scythe"] = "rbxassetid://115063494552764",
    ["Sandwich"] = "rbxassetid://17838233196",
    ["Satchel"] = "rbxassetid://132559258532984",
    ["Scythe"] = "rbxassetid://13834995858",
    ["Scythe of Death"] = "rbxassetid://17825961272",
    ["Shady Chicken Sandwich"] = "rbxassetid://113753042073837",
    ["Sheriff"] = "rbxassetid://18770200449",
    ["Shining Star"] = "rbxassetid://73486952957582",
    ["Shorty"] = "rbxassetid://13255103172",
    ["Shotgun"] = "rbxassetid://13197583302",
    ["Shotkey"] = "rbxassetid://101615278610735",
    ["Shurikens"] = "rbxassetid://118592510576313",
    ["Singularity"] = "rbxassetid://17676875650",
    ["Skull Launcher"] = "rbxassetid://88061081371943",
    ["Skullbang"] = "rbxassetid://94894233513600",
    ["Sled"] = "rbxassetid://127016476735322",
    ["Sleigh Maul"] = "rbxassetid://112835874307935",
    ["Sleighstortion"] = "rbxassetid://113075083434001",
    ["Slime Gun"] = "rbxassetid://17672087561",
    ["Slingshot"] = "rbxassetid://17095306079",
    ["Smoke Grenade"] = "rbxassetid://16373283577",
    ["Sniper"] = "rbxassetid://13197583098",
    ["Snow Shovel"] = "rbxassetid://96400887574950",
    ["Snowball Gun"] = "rbxassetid://78161595959189",
    ["Snowball Launcher"] = "rbxassetid://136762406657736",
    ["Snowblower"] = "rbxassetid://80434566532022",
    ["Snowglobe"] = "rbxassetid://86696224913566",
    ["Snowman Permafrost"] = "rbxassetid://70467865456788",
    ["Soul Grenade"] = "rbxassetid://126980255892476",
    ["Soul Pistols"] = "rbxassetid://95359207769282",
    ["Soul Rifle"] = "rbxassetid://140115840236565",
    ["Spaceship Launcher"] = "rbxassetid://18766904375",
    ["Spectral Burst"] = "rbxassetid://135650382469411",
    ["Spider Ray"] = "rbxassetid://92621276006979",
    ["Spider Web"] = "rbxassetid://133104747106136",
    ["Spray"] = "rbxassetid://87291726953666",
    ["Spray Bottle"] = "rbxassetid://88384629194597",
    ["Spring"] = "rbxassetid://18766904035",
    ["Squid Launcher"] = "rbxassetid://80877003243435",
    ["Stealth Handgun"] = "rbxassetid://99321324367928",
    ["Stellar Katana"] = "rbxassetid://90901679194899",
    ["Stick"] = "rbxassetid://17672086502",
    ["Subspace Tripmine"] = "rbxassetid://17098773688",
    ["Suspicious Gift"] = "rbxassetid://131542627171282",
    ["Swashbuckler"] = "rbxassetid://17821265007",
    ["Teleport Disc"] = "rbxassetid://81728761431901",
    ["Temporal Ray"] = "rbxassetid://18429549663",
    ["The Shred"] = "rbxassetid://95922136476180",
    ["Tombstone Shield"] = "rbxassetid://114630737114417",
    ["Tommy Gun"] = "rbxassetid://84369917689099",
    ["Too Shorty"] = "rbxassetid://18129532343",
    ["Torch"] = "rbxassetid://120882142047198",
    ["Towerstone Handgun"] = "rbxassetid://116418326352365",
    ["Trampoline"] = "rbxassetid://92310435035049",
    ["Trick or Treat"] = "rbxassetid://105864401236960",
    ["Trowel"] = "rbxassetid://16560547384",
    ["Trumpet"] = "rbxassetid://113408430051712",
    ["Unstable Warpstone"] = "rbxassetid://71896071193185",
    ["Uranium Launcher"] = "rbxassetid://18766902983",
    ["Uzi"] = "rbxassetid://14020829706",
    ["Vexed Candle"] = "rbxassetid://136079178184476",
    ["Vexed Flare Gun"] = "rbxassetid://138983159218333",
    ["Violin Crossbow"] = "rbxassetid://119666131999240",
    ["Void Pistols"] = "rbxassetid://114821885011907",
    ["Void Rifle"] = "rbxassetid://107749233395884",
    ["War Horn"] = "rbxassetid://97997387092919",
    ["Warp Handgun"] = "rbxassetid://117404871573487",
    ["Warpbone"] = "rbxassetid://132473085580193",
    ["Warper"] = "rbxassetid://97537499062821",
    ["Warpeye"] = "rbxassetid://129554679066276",
    ["Warpstar"] = "rbxassetid://85728240647371",
    ["Warpstone"] = "rbxassetid://99660718217521",
    ["Water Balloon"] = "rbxassetid://18769001397",
    ["Water Uzi"] = "rbxassetid://17821264784",
    ["Whoopee Cushion"] = "rbxassetid://17672086704",
    ["Wondergun"] = "rbxassetid://17672086052",
    ["Wrapped Flare Gun"] = "rbxassetid://135904023852615",
    ["Wrapped Freeze Ray"] = "rbxassetid://77624613843681",
    ["Wrapped Minigun"] = "rbxassetid://77902572458498",
    ["Wrapped Shorty"] = "rbxassetid://85255622402845",
    ["Wrapped Shotgun"] = "rbxassetid://122560535811833",
}

G.SolunaSkinRuntime.WeaponToSkinsMap = {
    ["Crossbow"] = {"Crossbow", "Arch Crossbow", "Crossbone", "Frostbite Crossbow", "Glorious Crossbow", "Harpoon Crossbow", "Pixel Crossbow", "Violin Crossbow"},
    ["Grenade Launcher"] = {"Grenade Launcher", "Gearnade Launcher", "Glorious Grenade Launcher", "Skull Launcher", "Snowball Launcher", "Swashbuckler", "Uranium Launcher"},
    ["Medkit"] = {"Medkit", "Briefcase", "Bucket of Candy", "Glorious Medkit", "Laptop", "Medkitty", "Milk & Cookies", "Sandwich"},
    ["Burst Rifle"] = {"Burst Rifle", "Aqua Burst", "Electro Rifle", "FAMAS", "Glorious Burst Rifle", "Keyst Rifle", "Pine Burst", "Pixel Burst", "Spectral Burst"},
    ["Flashbang"] = {"Flashbang", "Camera", "Disco Ball", "Glorious Flashbang", "Lightbulb", "Pixel Flashbang", "Shining Star", "Skullbang"},
    ["Energy Pistols"] = {"Energy Pistols", "Apex Pistols", "Glorious Energy Pistols", "Hacker Pistols", "Hydro Pistols", "New Year Energy Pistols", "Soul Pistols", "Void Pistols"},
    ["Revolver"] = {"Revolver", "Boneclaw Revolver", "Desert Eagle", "Glorious Revolver", "Keyvolver", "Peppergun", "Peppermint Sheriff", "Sheriff"},
    ["Grenade"] = {"Grenade", "Dynamite", "Frozen Grenade", "Glorious Grenade", "Jingle Grenade", "Keynade", "Soul Grenade", "Water Balloon", "Whoopee Cushion"},
    ["Fists"] = {"Fists", "Boxing Gloves", "Brass Knuckles", "Festive Fists", "Fists of Hurt", "Glorious Fists", "Pumpkin Claws"},
    ["Warpstone"] = {"Warpstone", "Cyber Warpstone", "Electropunk Warpstone", "Glorious Warpstone", "Teleport Disc", "Unstable Warpstone", "Warpbone", "Warpeye", "Warpstar"},
    ["Scythe"] = {"Scythe", "Anchor", "Bat Scythe", "Bug Net", "Cryo Scythe", "Crystal Scythe", "Glorious Scythe", "Keythe", "Sakura Scythe", "Scythe of Death"},
    ["Slingshot"] = {"Slingshot", "Boneshot", "Glorious Slingshot", "Goalpost", "Harp", "Reindeer Slingshot", "Stick"},
    ["Battle Axe"] = {"Battle Axe", "Ban Axe", "Cerulean Axe", "Glorious Battle Axe", "Keyttle Axe", "Mimic Axe", "Nordic Axe", "The Shred"},
    ["Flare Gun"] = {"Flare Gun", "Banana Flare", "Dynamite Gun", "Firework Gun", "Glorious Flare Gun", "Vexed Flare Gun", "Wrapped Flare Gun"},
    ["Molotov"] = {"Molotov", "Coffee", "Glorious Molotov", "Hot Coals", "Lava Lamp", "Torch", "Vexed Candle"},
    ["Flamethrower"] = {"Flamethrower", "Glitterthrower", "Glorious Flamethrower", "Jack O'Thrower", "Lamethrower", "Pixel Flamethrower", "Snowblower"},
    ["Shotgun"] = {"Shotgun", "Balloon Shotgun", "Broomstick", "Cactus Shotgun", "Glorious Shotgun", "Hyper Shotgun", "Shotkey", "Wrapped Shotgun"},
    ["Permafrost"] = {"Permafrost", "Glorious Permafrost", "Ice Permafrost", "Snowman Permafrost"},
    ["Distortion"] = {"Distortion", "Cyber Distortion", "Electropunk Distortion", "Experiment D15", "Glorious Distortion", "Magma Distortion", "Plasma Distortion", "Sleighstortion"},
    ["Assault Rifle"] = {"Assault Rifle", "10B Visits", "AK-47", "AKEY-47", "AUG", "Boneclaw Rifle", "Gingerbread AUG", "Glorious Assault Rifle", "Phoenix Rifle", "Tommy Gun"},
    ["Exogun"] = {"Exogun", "Exogourd", "Glorious Exogun", "Midnight Festive Exogun", "Ray Gun", "Repulsor", "Singularity", "Wondergun"},
    ["Maul"] = {"Maul", "Glorious Maul", "Ice Maul", "Sleigh Maul"},
    ["Subspace Tripmine"] = {"Subspace Tripmine", "DIY Tripmine", "Dev-in-the-Box", "Don't Press", "Glorious Subspace Tripmine", "Spring", "Trick or Treat"},
    ["Shorty"] = {"Shorty", "Balloon Shorty", "Demon Shorty", "Glorious Shorty", "Lovely Shorty", "Not So Shorty", "Too Shorty", "Wrapped Shorty"},
    ["Freeze Ray"] = {"Freeze Ray", "Bubble Ray", "Glorious Freeze Ray", "Gum Ray", "Spider Ray", "Temporal Ray", "Wrapped Freeze Ray"},
    ["Sniper"] = {"Sniper", "Event Horizon", "Eyething Sniper", "Gingerbread Sniper", "Glorious Sniper", "Hyper Sniper", "Keyper", "Pixel Sniper"},
    ["Knife"] = {"Knife", "Armature.001", "Balisong", "Candy Cane", "Chancla", "Glorious Knife", "Karambit", "Keylisong", "Keyrambit", "Machete"},
    ["Chainsaw"] = {"Chainsaw", "Blobsaw", "Buzzsaw", "Festive Buzzsaw", "Glorious Chainsaw", "Handsaws", "Mega Drill"},
    ["Warper"] = {"Warper", "Arcane Warper", "Electropunk Warper", "Experiment W4", "Frost Warper", "Glitter Warper", "Glorious Warper", "Hotel Bell"},
    ["RPG"] = {"RPG", "Firework Launcher", "Glorious RPG", "Nuke Launcher", "Pencil Launcher", "Pumpkin Launcher", "RPKEY", "Spaceship Launcher", "Squid Launcher"},
    ["Riot Shield"] = {"Riot Shield", "Door", "Energy Shield", "Glorious Riot Shield", "Masterpiece", "Sled", "Tombstone Shield"},
    ["Trowel"] = {"Trowel", "Garden Shovel", "Glorious Trowel", "Paintbrush", "Plastic Shovel", "Pumpkin Carver", "Snow Shovel"},
    ["Jump Pad"] = {"Jump Pad", "Bounce House", "Glorious Jump Pad", "Jolly Man", "Shady Chicken Sandwich", "Spider Web", "Trampoline"},
    ["Handgun"] = {"Handgun", "Blaster", "Gingerbread Handgun", "Glorious Handgun", "Gumball Handgun", "Hand Gun", "Pixel Handgun", "Pumpkin Handgun", "Stealth Handgun", "Towerstone Handgun", "Warp Handgun"},
    ["Energy Rifle"] = {"Energy Rifle", "Apex Rifle", "Glorious Energy Rifle", "Hacker Rifle", "Hydro Rifle", "New Year Energy Rifle", "Soul Rifle", "Void Rifle"},
    ["Katana"] = {"Katana", "Arch Katana", "Crystal Katana", "Devil's Trident", "Glorious Katana", "Keytana", "Lightning Bolt", "New Year Katana", "Pixel Katana", "Saber", "Stellar Katana"},
    ["Spray"] = {"Spray", "Boneclaw Spray", "Glorious Spray", "Lovely Spray", "Nail Gun", "Pine Spray", "Spray Bottle"},
    ["Paintball Gun"] = {"Paintball Gun", "Boba Gun", "Brain Gun", "Glorious Paintball Gun", "Ketchup Gun", "Slime Gun", "Snowball Gun"},
    ["Uzi"] = {"Uzi", "Demon Uzi", "Electro Uzi", "Glorious Uzi", "Keyzi", "Money Gun", "Pine Uzi", "Water Uzi"},
    ["Smoke Grenade"] = {"Smoke Grenade", "Balance", "Emoji Cloud", "Eyeball", "Glorious Smoke Grenade", "Hourglass", "Snowglobe"},
    ["War Horn"] = {"War Horn", "Air Horn", "Boneclaw Horn", "Glorious War Horn", "Mammoth Horn", "Megaphone", "Trumpet"},
    ["Satchel"] = {"Satchel", "Advanced Satchel", "Bag o' Money", "Glorious Satchel", "Notebook Satchel", "Potion Satchel", "Suspicious Gift"},
    ["Gunblade"] = {"Gunblade", "Boneblade", "Crude Gunblade", "Elf's Gunblade", "Glorious Gunblade", "Gunsaw", "Hyper Gunblade"},
    ["Bow"] = {"Bow", "Bat Bow", "Compound Bow", "Dream Bow", "Frostbite Bow", "Glorious Bow", "Key Bow", "Raven Bow"},
    ["Daggers"] = {"Daggers", "Aces", "Bat Daggers", "Cookies", "Crystal Daggers", "Glorious Daggers", "Keynais", "Paper Planes", "Shurikens"},
    ["Minigun"] = {"Minigun", "Fighter Jet", "Glorious Minigun", "Lasergun 3000", "Pixel Minigun", "Pumpkin Minigun", "Wrapped Minigun"},
}

G.SolunaSkinRuntime.SkinAttachmentNames = {"_aim_position", "_aim_lookat", "_center", "_muzzle", "_grip", "_scope_glare"}

G.SolunaSkinRuntime.FindSkinAsset = function(skinName)
    local viewModelsAssets = Config.LocalPlayer.PlayerScripts.Assets:FindFirstChild("ViewModels")
    if not viewModelsAssets then return nil end
    for _, category in ipairs(viewModelsAssets:GetChildren()) do
        local found = category:FindFirstChild(skinName)
        if found then return found end
    end
    return nil
end

G.SolunaSkinRuntime.LoadHardcodedSkinData = function()
    G.SolunaState.AvailableSkins = {}
    G.SolunaState.WeaponToSkins = {}
    G.SolunaState.WeaponCatalog = {}
    G.SolunaState.WeaponList = {}
    for weaponName, skins in pairs(G.SolunaSkinRuntime.WeaponToSkinsMap) do
        G.SolunaState.WeaponToSkins[weaponName] = {}
        G.SolunaState.WeaponCatalog[weaponName] = { Name = weaponName, Image = G.SolunaSkinRuntime.ViewModelImageMap[weaponName] or G.SolunaSkinRuntime.WeaponPlaceholderImage, Skins = {} }
        table.insert(G.SolunaState.WeaponList, weaponName)
        for index, skinName in ipairs(skins) do
            table.insert(G.SolunaState.WeaponToSkins[weaponName], skinName)
            table.insert(G.SolunaState.AvailableSkins, skinName)
            table.insert(G.SolunaState.WeaponCatalog[weaponName].Skins, { Name = skinName, Image = G.SolunaSkinRuntime.ViewModelImageMap[skinName] or G.SolunaSkinRuntime.SkinPlaceholderImage, Rarity = index == 1 and "Default" or "Skin" })
        end
        table.sort(G.SolunaState.WeaponToSkins[weaponName], function(left, right)
            if left == weaponName then return true end
            if right == weaponName then return false end
            return left < right
        end)
        table.sort(G.SolunaState.WeaponCatalog[weaponName].Skins, function(left, right)
            if left.Name == weaponName then return true end
            if right.Name == weaponName then return false end
            return left.Name < right.Name
        end)
    end
    table.sort(G.SolunaState.AvailableSkins)
    table.sort(G.SolunaState.WeaponList)
    if not G.SolunaState.CurrentWeaponSelection or not G.SolunaState.WeaponCatalog[G.SolunaState.CurrentWeaponSelection] then
        G.SolunaState.CurrentWeaponSelection = G.SolunaState.WeaponList[1]
    end
end

G.SolunaSkinRuntime.ClearHardcodedSkinModel = function(weaponModel)
    local rootPart = weaponModel:FindFirstChild("HumanoidRootPart")
    local itemVisual = weaponModel:FindFirstChild("ItemVisual")
    local overlay = weaponModel:FindFirstChild("ItemVisualSkin")
    if rootPart then
        for _, motor in ipairs(rootPart:GetChildren()) do
            if motor:IsA("Motor6D") and string.find(motor.Name, "SkinVisual", 1, true) then motor:Destroy() end
        end
    end
    if overlay then overlay:Destroy() end
    if itemVisual then
        for _, descendant in ipairs(itemVisual:GetDescendants()) do
            if descendant:IsA("BasePart") then descendant.Transparency = 0 end
        end
    end
    G.SolunaState.ProcessedSkinModels[weaponModel] = nil
end

G.SolunaSkinRuntime.ParseWeaponModelName = function(modelName)
    local parts = string.split(modelName, " - ")
    if #parts < 3 then return nil, nil, nil end
    local ownerName = parts[1]
    local currentSkin = parts[#parts]
    local weaponNameParts = {}
    for index = 2, #parts - 1 do table.insert(weaponNameParts, parts[index]) end
    return ownerName, table.concat(weaponNameParts, " - "), currentSkin
end

G.SolunaSkinRuntime.SwapHardcodedSkinModel = function(weaponModel, targetSkinName)
    local skinAsset = G.SolunaSkinRuntime.FindSkinAsset(targetSkinName)
    if not skinAsset then return false end
    local rootPart = weaponModel:FindFirstChild("HumanoidRootPart")
    local itemVisual = weaponModel:FindFirstChild("ItemVisual")
    if not rootPart or not itemVisual then return false end
    G.SolunaSkinRuntime.ClearHardcodedSkinModel(weaponModel)
    for _, descendant in ipairs(itemVisual:GetDescendants()) do
        if descendant:IsA("BasePart") then descendant.Transparency = 1 end
    end
    local newItemModel = skinAsset:Clone()
    newItemModel.Name = "ItemVisualSkin"
    newItemModel.Parent = weaponModel
    for _, subModel in ipairs(newItemModel:GetChildren()) do
        if subModel.Name == "_fake" then
            subModel:Destroy()
        elseif subModel:IsA("Model") then
            subModel.PrimaryPart = subModel:FindFirstChild("Primary")
            if not subModel.PrimaryPart then continue end
            local armName = subModel.Name == "_right_arm" and "RightArm" or (subModel.Name == "_left_arm" and "LeftArm" or nil)
            if armName then
                local armPart = weaponModel:FindFirstChild(armName)
                if armPart then
                    subModel.Parent = armPart
                    subModel:PivotTo(armPart.CFrame)
                    local weld = Instance.new("WeldConstraint")
                    weld.Part0 = armPart
                    weld.Part1 = subModel.PrimaryPart
                    weld.Parent = subModel.PrimaryPart
                end
            else
                local motor = Instance.new("Motor6D")
                motor.Part0 = rootPart
                motor.Part1 = subModel.PrimaryPart
                motor.Name = "SkinVisual[\"" .. subModel.Name .. "\"]"
                motor.C0 = subModel:GetAttribute("C0") or CFrame.identity
                motor.C1 = subModel:GetAttribute("C1") or CFrame.identity
                motor.Parent = rootPart
            end
            for _, part in ipairs(subModel:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CastShadow = false
                    part.CanCollide = false
                    part.CanTouch = false
                    part.CanQuery = false
                    part.Massless = true
                    if subModel.PrimaryPart and part ~= subModel.PrimaryPart then
                        local weld = Instance.new("WeldConstraint")
                        weld.Part0 = subModel.PrimaryPart
                        weld.Part1 = part
                        weld.Parent = subModel.PrimaryPart
                        part.Anchored = false
                    end
                end
            end
            subModel.PrimaryPart.Anchored = false
            if not armName then
                subModel.PrimaryPart.Name = subModel.Name .. "Primary"
                subModel:PivotTo(rootPart.CFrame)
            end
        end
    end
    for _, attachmentName in ipairs(G.SolunaSkinRuntime.SkinAttachmentNames) do
        local oldAttachment = itemVisual:FindFirstChild(attachmentName, true)
        local newAttachment = newItemModel:FindFirstChild(attachmentName, true)
        if oldAttachment and newAttachment and oldAttachment:IsA("Attachment") and newAttachment:IsA("Attachment") then
            oldAttachment.CFrame = newAttachment.CFrame
        end
    end
    return true
end

G.SolunaSkinRuntime.ProcessHardcodedWeaponModel = function(weaponModel)
    if not G.SolunaState.SkinChangerEnabled then return false end
    local ownerName, weaponName, currentSkin = G.SolunaSkinRuntime.ParseWeaponModelName(weaponModel.Name)
    if ownerName ~= Config.LocalPlayer.Name or not weaponName then return false end
    local targetSkin = G.SolunaState.SelectedSkins[weaponName]
    if not targetSkin or targetSkin == weaponName then
        if weaponModel:FindFirstChild("ItemVisualSkin") then
            G.SolunaSkinRuntime.ClearHardcodedSkinModel(weaponModel)
            return true
        end
        G.SolunaState.ProcessedSkinModels[weaponModel] = weaponName
        return false
    end
    if G.SolunaState.ProcessedSkinModels[weaponModel] == targetSkin then return false end
    if targetSkin == currentSkin and not weaponModel:FindFirstChild("ItemVisualSkin") then
        G.SolunaState.ProcessedSkinModels[weaponModel] = targetSkin
        return false
    end
    local success = G.SolunaSkinRuntime.SwapHardcodedSkinModel(weaponModel, targetSkin)
    if success then G.SolunaState.ProcessedSkinModels[weaponModel] = targetSkin end
    return success
end

G.SolunaSkinRuntime.ForEachViewModel = function(callback)
local viewModelsFolder = workspace:FindFirstChild("ViewModels")
if not viewModelsFolder then return end
    local firstPerson = viewModelsFolder:FindFirstChild("FirstPerson")
    if firstPerson then
        for _, model in ipairs(firstPerson:GetChildren()) do
            if model:IsA("Model") then callback(model) end
        end
    end
    for _, model in ipairs(viewModelsFolder:GetChildren()) do
        if model ~= firstPerson and model:IsA("Model") then callback(model) end
    end
end

G.SolunaSkinRuntime.ApplyHardcodedSkins = function()
    local applied = 0
    local matched = 0
    G.SolunaSkinRuntime.ForEachViewModel(function(model)
        local ownerName, weaponName = G.SolunaSkinRuntime.ParseWeaponModelName(model.Name)
        if ownerName == Config.LocalPlayer.Name and weaponName and G.SolunaState.SelectedSkins[weaponName] then matched = matched + 1 end
        if G.SolunaSkinRuntime.ProcessHardcodedWeaponModel(model) then applied = applied + 1 end
    end)
    return applied, matched
end

G.SolunaSkinRuntime.SetupHardcodedSkinChangerHook = function()
    if G.SolunaState.SkinChangerHooked then return end
local viewModelsFolder = workspace:FindFirstChild("ViewModels")
if not viewModelsFolder then return end
    G.SolunaState.SkinChangerHooked = true
    local firstPerson = viewModelsFolder:FindFirstChild("FirstPerson")
    local function onChildAdded(child)
        if child:IsA("Model") then
            task.wait(0.1)
            G.SolunaSkinRuntime.ProcessHardcodedWeaponModel(child)
        end
    end
    if firstPerson then table.insert(G.SolunaState.SkinWatcherConnections, firstPerson.ChildAdded:Connect(onChildAdded)) end
    table.insert(G.SolunaState.SkinWatcherConnections, viewModelsFolder.ChildAdded:Connect(function(child)
        if child ~= firstPerson then onChildAdded(child) end
    end))
    G.SolunaSkinRuntime.ApplyHardcodedSkins()
end

G.SolunaSkinRuntime.LoadSkinData = function()
    if G.SolunaSkinRuntime.UsesHardcodedSkinChanger() then
        G.SolunaSkinRuntime.LoadHardcodedSkinData()
        return
    end
    if State.RequireBlocked then return end
    pcall(function()
        local CosmeticLib = GetCosmeticLibrary()
        local ItemLib = GetItemLibrary()
        if not CosmeticLib or not ItemLib then return end
        G.SolunaState.AvailableSkins = {}
        G.SolunaState.WeaponToSkins = {}
        G.SolunaState.WeaponCatalog = {}
        for skinName, cosmetic in pairs(CosmeticLib.Cosmetics) do
            if cosmetic.Type == "Skin" and cosmetic.ItemName then
                local weaponName = cosmetic.ItemName
                if not G.SolunaState.WeaponToSkins[weaponName] then G.SolunaState.WeaponToSkins[weaponName] = {} end
                if not G.SolunaState.WeaponCatalog[weaponName] then
                    G.SolunaState.WeaponCatalog[weaponName] = { Name = weaponName, Image = ItemLib:GetViewModelImage(weaponName, nil, true) or ItemLib:GetViewModelImage(weaponName) or "", Skins = {} }
                end
                table.insert(G.SolunaState.WeaponToSkins[weaponName], skinName)
                table.insert(G.SolunaState.AvailableSkins, skinName)
                table.insert(G.SolunaState.WeaponCatalog[weaponName].Skins, { Name = skinName, Image = cosmetic.ImageHighResolution or cosmetic.Image or ItemLib:GetViewModelImage(skinName, nil, true) or ItemLib:GetViewModelImage(skinName) or "", Rarity = cosmetic.Rarity or "Common" })
            end
        end
        for weaponName, skins in pairs(G.SolunaState.WeaponToSkins) do
            table.sort(skins)
            table.sort(G.SolunaState.WeaponCatalog[weaponName].Skins, function(left, right) return left.Name < right.Name end)
        end
        table.sort(G.SolunaState.AvailableSkins)
        G.SolunaState.WeaponList = {}
        for weaponName in pairs(G.SolunaState.WeaponCatalog) do table.insert(G.SolunaState.WeaponList, weaponName) end
        table.sort(G.SolunaState.WeaponList)
        if not G.SolunaState.CurrentWeaponSelection or not G.SolunaState.WeaponCatalog[G.SolunaState.CurrentWeaponSelection] then
            G.SolunaState.CurrentWeaponSelection = G.SolunaState.WeaponList[1]
        end
    end)
end

G.SolunaSkinRuntime.SetupSkinChangerHook = function()
    if G.SolunaSkinRuntime.UsesHardcodedSkinChanger() then
        G.SolunaSkinRuntime.SetupHardcodedSkinChangerHook()
        return
    end
    if State.RequireBlocked then return end
    if G.SolunaState.SkinChangerHooked then return end
    G.SolunaState.SkinChangerHooked = true
    pcall(function()
        local ClientViewModelModule = GetClientViewModelModule()
        local ItemLibrary = GetItemLibrary()
        local Utility = GetUtilityLibrary()
        if not ClientViewModelModule or not ItemLibrary or not Utility then return end
        local ViewModelsAssets = Config.LocalPlayer.PlayerScripts.Assets.ViewModels
        if not G.SolunaState.OriginalViewModelNew then G.SolunaState.OriginalViewModelNew = ClientViewModelModule.new end
        ClientViewModelModule.new = function(serialData, clientItem)
            local originalName = nil
            local targetSkin = nil
            pcall(function()
                if not serialData then return end
                local EnumLib = GetEnumLibrary()
                if not EnumLib then return end
                local dataKey = EnumLib:ToEnum("Data")
                local nameKey = EnumLib:ToEnum("Name")
                if not dataKey or not serialData[dataKey] then return end
                originalName = serialData[dataKey][nameKey]
                if G.SolunaState.SkinChangerEnabled and clientItem and clientItem.Name then
                    targetSkin = G.SolunaState.SelectedSkins[clientItem.Name]
                    if targetSkin and ItemLibrary.ViewModels[targetSkin] then
                        serialData[dataKey][nameKey] = targetSkin
                    else
                        targetSkin = nil
                    end
                end
            end)
            local viewModelInstance = G.SolunaState.OriginalViewModelNew(serialData, clientItem)
            if targetSkin and viewModelInstance then
                pcall(function()
                    viewModelInstance.Name = targetSkin
                    viewModelInstance.Info = ItemLibrary.ViewModels[targetSkin]
                    if viewModelInstance.Animator then viewModelInstance.Animator:LoadAnimations() end
                    for _, sound in pairs(viewModelInstance._preloaded_sounds or {}) do pcall(function() sound:Destroy() end) end
                    viewModelInstance._preloaded_sounds = {}
                    local SoundLibrary = GetSoundLibrary()
                    if not SoundLibrary then return end
                    local skinInfo = ItemLibrary.ViewModels[targetSkin]
                    if skinInfo and skinInfo.Animations then
                        for _, animName in pairs(skinInfo.Animations) do
                            if SoundLibrary.AnimationSounds[animName] then SoundLibrary:PreloadSounds(SoundLibrary.AnimationSounds[animName], viewModelInstance._preloaded_sounds) end
                        end
                    end
                    if SoundLibrary.ViewModelSounds[targetSkin] then SoundLibrary:PreloadSounds(SoundLibrary.ViewModelSounds[targetSkin], viewModelInstance._preloaded_sounds) end
                end)
            end
            return viewModelInstance
        end
    end)
end

G.SolunaSkinRuntime.ApplySkinToCurrentWeapon = function()
    if G.SolunaSkinRuntime.UsesHardcodedSkinChanger() then
        local applied, matched = G.SolunaSkinRuntime.ApplyHardcodedSkins()
        if matched > 0 then return true, "Synced " .. tostring(matched) .. " equipped skin(s)" end
        return false, "No equipped weapon model found"
    end
    if State.RequireBlocked then return false, "Require unavailable" end
    local fc = GetFighterController()
    if not fc or not fc.LocalFighter then return false, "No fighter" end
    local equippedItem = fc.LocalFighter.EquippedItem
    if not equippedItem then return false, "No weapon equipped" end
    local itemName = equippedItem.Name
    local selectedSkin = G.SolunaState.SelectedSkins[itemName]
    if not selectedSkin then return false, "No skin selected for " .. itemName end
    local viewModel = equippedItem.ViewModel
    if not viewModel then return false, "No ViewModel" end
    local ItemLibrary = GetItemLibrary()
    local Utility = GetUtilityLibrary()
    local SoundLibrary = GetSoundLibrary()
    if not ItemLibrary or not Utility then return false, "Require unavailable" end
    if not SoundLibrary then return false, "Require unavailable" end
    local ViewModelsAssets = Config.LocalPlayer.PlayerScripts.Assets:FindFirstChild("ViewModels")
    if not ViewModelsAssets then return false, "ViewModels folder not found" end
    if not ItemLibrary.ViewModels[selectedSkin] then return false, "Skin not in ItemLibrary: " .. selectedSkin end
    local success, err = pcall(function()
        for _, motor in pairs(viewModel.Model.PrimaryPart:GetChildren()) do
            if motor:IsA("Motor6D") and string.find(motor.Name, "ItemVisual") then motor:Destroy() end
        end
        if viewModel.ItemModel then viewModel.ItemModel:Destroy() end
        local newItemModel = Utility:LookThrough(ViewModelsAssets, selectedSkin):Clone()
        local newInfo = ItemLibrary.ViewModels[selectedSkin]
        viewModel.Name = selectedSkin
        viewModel.Info = newInfo
        viewModel._root_part_offset_inverse = newInfo.RootPartOffset and newInfo.RootPartOffset:Inverse() or CFrame.identity
        newItemModel.Name = "ItemVisual"
        viewModel.ItemModel = newItemModel
        viewModel._original_scale = newItemModel:GetScale()
        viewModel._body_model = newItemModel:FindFirstChild("Body")
        viewModel._aim_position_attachment = newItemModel:FindFirstChild("_aim_position", true)
        viewModel._aim_lookat_attachment = newItemModel:FindFirstChild("_aim_lookat", true)
        viewModel._center_attachment = newItemModel:FindFirstChild("_center", true)
        viewModel._charm_attachment_model = newItemModel:FindFirstChild("_charm_attachment_model", true)
        viewModel._charm_pivot_attachment = viewModel._charm_attachment_model and viewModel._charm_attachment_model:FindFirstChild("_charm_pivot_attachment", true) or viewModel.Model:FindFirstChild("_charm_pivot_attachment", true)
        viewModel._scope_glare_attachment = newItemModel:FindFirstChild("_scope_glare", true)
        viewModel.AimingAnimationEnabled = viewModel._aim_position_attachment ~= nil and viewModel._aim_lookat_attachment ~= nil
        viewModel._muzzle_attachments = {}
        viewModel._hidden_submodels = {}
        viewModel._animation_context_submodels = {}
        viewModel._arm_submodels = {}
        local rootPart = viewModel.Model.PrimaryPart
        local firstCFrame = nil
        for _, subModel in pairs(newItemModel:GetChildren()) do
            if subModel.Name == "_fake" then
                subModel:Destroy()
            else
                if subModel:FindFirstChild("Primary") then subModel.PrimaryPart = subModel.Primary end
                firstCFrame = firstCFrame or (subModel.PrimaryPart and subModel.PrimaryPart.CFrame)
                local armName = subModel.Name == "_right_arm" and "RightArm" or (subModel.Name == "_left_arm" and "LeftArm" or nil)
                if armName then
                    viewModel._arm_submodels[subModel] = subModel:GetScale()
                    local armPart = viewModel.Model:FindFirstChild(armName)
                    if armPart then
                        subModel.Parent = armPart
                        subModel:PivotTo(armPart.CFrame)
                        local weld = Instance.new("WeldConstraint")
                        weld.Part0 = armPart
                        weld.Part1 = subModel.PrimaryPart
                        weld.Parent = subModel.PrimaryPart
                    end
                else
                    local motor = Instance.new("Motor6D")
                    motor.Part0 = rootPart
                    motor.Part1 = subModel.PrimaryPart
                    motor.Name = "ItemVisual[\"" .. subModel.Name .. "\"]"
                    motor.C0 = subModel:GetAttribute("C0") or (subModel.PrimaryPart and firstCFrame and subModel.PrimaryPart.CFrame:ToObjectSpace(firstCFrame):Inverse() or CFrame.identity)
                    motor.C1 = subModel:GetAttribute("C1") or CFrame.identity
                    motor.Parent = rootPart
                end
                for _, part in pairs(subModel:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CastShadow = false
                        part.CanCollide = false
                        part.CanTouch = false
                        part.CanQuery = false
                        part.Massless = true
                        if subModel.PrimaryPart and part ~= subModel.PrimaryPart then
                            local weld = Instance.new("WeldConstraint")
                            weld.Part0 = subModel.PrimaryPart
                            weld.Part1 = part
                            weld.Parent = subModel.PrimaryPart
                            part.Anchored = false
                        end
                    end
                    if part.Name == "_muzzle" then table.insert(viewModel._muzzle_attachments, part) end
                end
                if subModel.PrimaryPart then
                    subModel.PrimaryPart.Anchored = false
                    if not armName then
                        subModel.PrimaryPart.Name = subModel.Name .. "Primary"
                        subModel:PivotTo(rootPart.CFrame)
                    end
                end
                local animContexts = subModel:GetAttribute("AnimationContexts")
                if animContexts then
                    viewModel._animation_context_submodels[subModel] = {}
                    for ctx in string.gmatch(animContexts, "[^,]+") do table.insert(viewModel._animation_context_submodels[subModel], ctx:match("^%s*(.-)%s*$")) end
                end
            end
        end
        newItemModel.Parent = viewModel.Model
        if viewModel.Animator then
            viewModel.Animator:StopAllAnimations()
            viewModel.Animator:LoadAnimations()
            viewModel.Animator:PlayIdleAnimation()
        end
        for _, sound in pairs(viewModel._preloaded_sounds or {}) do pcall(function() sound:Destroy() end) end
        viewModel._preloaded_sounds = {}
        if newInfo.Animations then
            for _, animName in pairs(newInfo.Animations) do
                if SoundLibrary.AnimationSounds[animName] then SoundLibrary:PreloadSounds(SoundLibrary.AnimationSounds[animName], viewModel._preloaded_sounds) end
            end
        end
        if SoundLibrary.ViewModelSounds[selectedSkin] then SoundLibrary:PreloadSounds(SoundLibrary.ViewModelSounds[selectedSkin], viewModel._preloaded_sounds) end
    end)
    if success then return true, "Applied " .. selectedSkin .. " to " .. itemName else return false, "Error: " .. tostring(err) end
end

G.SolunaSkinRuntime.ApplyAllSkins = function()
    if not G.SolunaState.SkinChangerEnabled then return end
    if G.SolunaSkinRuntime.UsesHardcodedSkinChanger() then
        G.SolunaSkinRuntime.ApplyHardcodedSkins()
        return
    end
    local fc = GetFighterController()
    if not fc or not fc.LocalFighter then return end
    local equippedItem = fc.LocalFighter.EquippedItem
    if equippedItem then G.SolunaSkinRuntime.ApplySkinToCurrentWeapon() end
end

G.SolunaState.WeaponList = {"Assault Rifle", "Crossbow", "Grenade Launcher", "Medkit", "Burst Rifle", "Flashbang", "Energy Pistols", "Revolver", "Grenade", "Fists", "Warpstone", "Scythe", "Slingshot", "Battle Axe", "Flare Gun", "Molotov", "Flamethrower", "Shotgun", "Permafrost", "Distortion", "Exogun", "Maul", "Subspace Tripmine", "Shorty", "Freeze Ray", "Sniper", "Knife", "Chainsaw", "Warper", "RPG", "Riot Shield", "Trowel", "Jump Pad", "Handgun", "Energy Rifle", "Katana", "Spray", "Paintball Gun", "Uzi", "Smoke Grenade", "War Horn", "Satchel", "Gunblade", "Bow", "Daggers", "Minigun"}
task.defer(G.SolunaSkinRuntime.LoadSkinData)

task.defer(function()
    G.SolunaState.WeaponList = {}
    for weaponName, _ in pairs(G.SolunaSkinRuntime.WeaponToSkinsMap) do
        table.insert(G.SolunaState.WeaponList, weaponName)
    end
    table.sort(G.SolunaState.WeaponList)
    G.SolunaState.WeaponCatalog = G.SolunaState.WeaponCatalog or {}
    if SkinWeaponDropdown then
        SkinWeaponDropdown:SetValues(G.SolunaState.WeaponList)
    end
end)

if not G.SolunaState.WeaponList or #G.SolunaState.WeaponList == 0 then
    G.SolunaState.WeaponList = {"Assault Rifle"}
end

G.SolunaState.WeaponList = {}
for weaponName, _ in pairs(G.SolunaSkinRuntime.WeaponToSkinsMap) do
    table.insert(G.SolunaState.WeaponList, weaponName)
end
table.sort(G.SolunaState.WeaponList)
G.SolunaState.WeaponCatalog = G.SolunaState.WeaponCatalog or {}

G.SolunaState.SkinConfigFile = "SSC.json"

G.SolunaSkinRuntime.GetSkinConfigData = function()
    return { SelectedSkins = G.SolunaState.SelectedSkins or {}, SkinChangerEnabled = G.SolunaState.SkinChangerEnabled, CurrentWeaponSelection = G.SolunaState.CurrentWeaponSelection }
end

G.SolunaSkinRuntime.SetSkinConfigData = function(data)
    if type(data) ~= "table" then return end
    if type(data.SelectedSkins) == "table" then G.SolunaState.SelectedSkins = data.SelectedSkins else G.SolunaState.SelectedSkins = data end
    if data.SkinChangerEnabled ~= nil then G.SolunaState.SkinChangerEnabled = data.SkinChangerEnabled == true end
    if type(data.CurrentWeaponSelection) == "string" then G.SolunaState.CurrentWeaponSelection = data.CurrentWeaponSelection end
    if not G.SolunaState.WeaponCatalog[G.SolunaState.CurrentWeaponSelection] then G.SolunaState.CurrentWeaponSelection = G.SolunaState.WeaponList and G.SolunaState.WeaponList[1] end
end

G.SolunaSkinRuntime.SaveSkinConfig = function()
    pcall(function()
        local data = Services.HttpService:JSONEncode(G.SolunaSkinRuntime.GetSkinConfigData())
        writefile(G.SolunaState.SkinConfigFile, data)
    end)
end

G.SolunaSkinRuntime.LoadSkinConfig = function()
    pcall(function()
        if isfile(G.SolunaState.SkinConfigFile) then
            local data = readfile(G.SolunaState.SkinConfigFile)
            G.SolunaSkinRuntime.SetSkinConfigData(Services.HttpService:JSONDecode(data) or {})
        end
    end)
end

G.SolunaSkinRuntime.LoadSkinConfig()

G.SolunaSkinRuntime.RefreshSkinChangerState = function()
    if G.SolunaState.SkinChangerEnabled then
        G.SolunaSkinRuntime.SetupSkinChangerHook()
        G.SolunaSkinRuntime.ApplyAllSkins()
    end
end

local SkinsSection = Tabs.Skins:AddSection("Skins")
local SkinWeaponDropdown = SkinsSection:AddDropdown("SkinWeapon", { Title = "Weapon", Values = G.SolunaState.WeaponList, Default = G.SolunaState.CurrentWeaponSelection or "Assault Rifle", Multi = false })
local SkinSelectionDropdown = SkinsSection:AddDropdown("SkinSelection", { Title = "Skin", Values = {}, Default = 1, Multi = false })

SkinWeaponDropdown:OnChanged(function(Value)
    if Value then
        G.SolunaState.CurrentWeaponSelection = Value
        local skins = {}
        if G.SolunaState.WeaponCatalog and G.SolunaState.WeaponCatalog[Value] then
            for _, s in ipairs(G.SolunaState.WeaponCatalog[Value].Skins) do table.insert(skins, s.Name) end
        elseif G.SolunaSkinRuntime.WeaponToSkinsMap and G.SolunaSkinRuntime.WeaponToSkinsMap[Value] then
            for _, s in ipairs(G.SolunaSkinRuntime.WeaponToSkinsMap[Value]) do table.insert(skins, s) end
        end
        SkinSelectionDropdown:SetValues(skins)
        local current = G.SolunaState.SelectedSkins[Value]
        if current then SkinSelectionDropdown:SetValue(current) end
    end
end)

task.defer(function()
    task.defer(G.SolunaSkinRuntime.LoadSkinData)
    if SkinWeaponDropdown and G.SolunaState.WeaponList then
        SkinWeaponDropdown:SetValues(G.SolunaState.WeaponList)
        if G.SolunaState.CurrentWeaponSelection then
            SkinWeaponDropdown:SetValue(G.SolunaState.CurrentWeaponSelection)
        end
    end
end)

SkinSelectionDropdown:OnChanged(function(Value)
    if Value and G.SolunaState.CurrentWeaponSelection then
        G.SolunaState.SelectedSkins[G.SolunaState.CurrentWeaponSelection] = Value
        if G.SolunaSkinRuntime.RefreshSkinChangerState then
            G.SolunaSkinRuntime.RefreshSkinChangerState()
        end
    end
end)

SkinsSection:AddToggle("SkinChangerEnabled", { Title = "Enable Skin Changer", Default = G.SolunaState.SkinChangerEnabled, Callback = function(v)
    G.SolunaState.SkinChangerEnabled = v
    if G.SolunaSkinRuntime.RefreshSkinChangerState then
        G.SolunaSkinRuntime.RefreshSkinChangerState()
    end
end })

SkinsSection:AddButton({ Title = "Apply Equipped", Callback = function()
    local success, message = G.SolunaSkinRuntime.ApplySkinToCurrentWeapon()
    Notify({ Title = success and "Skin Applied" or "Error", Content = message, Duration = 2 })
end })

SkinsSection:AddButton({ Title = "Save Config", Callback = function()
    G.SolunaSkinRuntime.SaveSkinConfig()
    Notify({ Title = "Skins Saved", Content = "Saved selections", Duration = 2 })
end })

SkinsSection:AddButton({ Title = "Load Config", Callback = function()
    Notify({ Title = "Loading Config", Content = "Please wait 2 seconds...", Duration = 2 })
    task.spawn(function()
        task.wait(2)
        G.SolunaSkinRuntime.LoadSkinConfig()
        if G.SolunaSkinRuntime.RefreshSkinChangerState then
            G.SolunaSkinRuntime.RefreshSkinChangerState()
        end
        SkinWeaponDropdown:SetValue(G.SolunaState.CurrentWeaponSelection or G.SolunaState.WeaponList[1])
        Notify({ Title = "Config Loaded", Content = "Skin config loaded successfully!", Duration = 2 })
    end)
end })

SkinsSection:AddButton({ Title = "Clear All", Callback = function()
    G.SolunaState.SelectedSkins = {}
    if G.SolunaSkinRuntime.RefreshSkinChangerState then
        G.SolunaSkinRuntime.RefreshSkinChangerState()
    end
    SkinSelectionDropdown:SetValue(nil)
end })

local UnlockAllSection = Tabs.Skins:AddSection("Unlock All")
local UnlockAllEnabled = false

UnlockAllSection:AddToggle("unlock_all_enabled", { Title = "Unlock All Cosmetics", Default = false, Callback = function(v)
    UnlockAllEnabled = v
    task.spawn(function()
    pcall(function()
        task.wait(4)

        local _plrs    = game:GetService("Players")
        local _rs      = game:GetService("ReplicatedStorage")
        local _http    = game:GetService("HttpService")
        local _run     = game:GetService("RunService")
        local _ws      = game:GetService("Workspace")
        local _lp      = _plrs.LocalPlayer
        local _pscripts = _lp.PlayerScripts
        local _ctrl    = _pscripts.Controllers
        local _mods    = _rs:WaitForChild("Modules", 10)

        local _enumLib = require(_mods:WaitForChild("EnumLibrary", 10))
        if _enumLib then pcall(function() _enumLib:WaitForEnumBuilder() end) end

        local _cosLib  = require(_mods:WaitForChild("CosmeticLibrary", 10))
        local _itmLib  = require(_mods:WaitForChild("ItemLibrary", 10))
        local _datCtrl = require(_ctrl:WaitForChild("PlayerDataController", 10))

        local _eq, _favs = {}, {}
        local _buildingWep, _viewProf = nil, nil
        local _lastWep = nil
        local _fakeInv = {}

        local function _mkCosmetic(nm, ctype, opts)
            local _base = _cosLib.Cosmetics[nm]
            if not _base then return nil end
            local _d = {}
            for k, v in pairs(_base) do _d[k] = v end
            _d.Name = nm
            _d.Type = _d.Type or ctype
            _d.Seed = _d.Seed or math.random(1, 1000000)
            if _enumLib then
                local _s, _eid = pcall(_enumLib.ToEnum, _enumLib, nm)
                if _s and _eid then
                    _d.Enum = _eid
                    _d.ObjectID = _d.ObjectID or _eid
                end
            end
            if opts then
                if opts.inverted ~= nil then _d.Inverted = opts.inverted end
                if opts.favoritesOnly ~= nil then _d.OnlyUseFavorites = opts.favoritesOnly end
            end
            return _d
        end

        local _cfgFile = "rivals_unlocker_config.json"
        local _saveLock = false

        local function _stripForSave()
            local _out = {}
            for wn, cos in pairs(_eq) do
                _out[wn] = {}
                for ct, cd in pairs(cos) do
                    if cd and cd.Name then
                        _out[wn][ct] = {
                            Name = cd.Name,
                            Inverted = cd.Inverted,
                            OnlyUseFavorites = cd.OnlyUseFavorites
                        }
                    end
                end
            end
            return { equipped = _out, favorites = _favs }
        end

        local function _loadCfg()
            if not isfile or not readfile then return end
            local _ok1, _ex = pcall(isfile, _cfgFile)
            if not _ok1 or not _ex then return end
            local _ok2, _raw = pcall(readfile, _cfgFile)
            if not _ok2 or not _raw or _raw == "" then return end
            local _ok3, _dec = pcall(_http.JSONDecode, _http, _raw)
            if not _ok3 or not _dec then return end
            if _dec.favorites then
                _favs = _dec.favorites
            end
            if _dec.equipped then
                _eq = {}
                local _cnt = 0
                for wn, cos in pairs(_dec.equipped) do
                    _eq[wn] = {}
                    for ct, sd in pairs(cos) do
                        if sd and sd.Name then
                            if _cosLib.Cosmetics[sd.Name] then
                                local _cloned = _mkCosmetic(sd.Name, ct, {
                                    inverted = sd.Inverted,
                                    favoritesOnly = sd.OnlyUseFavorites
                                })
                                if _cloned then
                                    _eq[wn][ct] = _cloned
                                    _cnt += 1
                                end
                            end
                        end
                    end
                    if not next(_eq[wn]) then _eq[wn] = nil end
                end
            end
        end

        local function _saveCfg()
            if not writefile or _saveLock then return end
            _saveLock = true
            task.spawn(function()
                task.wait(1)
                local _payload = _stripForSave()
                local _ok, _enc = pcall(_http.JSONEncode, _http, _payload)
                if _ok then
                    pcall(writefile, _cfgFile, _enc)
                end
                _saveLock = false
            end)
        end

        _loadCfg()

        local _cosTypes = {"Skin","Wrap","Charm","Dance","Emote"}
        local function _isCosType(cosObj)
            if not cosObj then return false end
            for _, t in ipairs(_cosTypes) do
                if cosObj.Type == t then return true end
            end
            return false
        end

        if v then
            _cosLib.OwnsCosmeticNormally = function(self, inv, nm, wep)
                local c = _cosLib.Cosmetics[nm]
                if c and c.Type == "Skin" then return true end
                return false
            end
            _cosLib.OwnsCosmeticUniversally = function(self, inv, nm, wep)
                local c = _cosLib.Cosmetics[nm]
                if c and c.Type == "Skin" then return true end
                return false
            end
            _cosLib.OwnsCosmeticForWeapon = function(self, inv, nm, wep)
                local c = _cosLib.Cosmetics[nm]
                if c and c.Type == "Skin" then return true end
                return false
            end

            if not _cosLib._origOwns then
                _cosLib._origOwns = _cosLib.OwnsCosmetic
            end
            _cosLib.OwnsCosmetic = function(self, inv, nm, wep)
                if nm:find("MISSING_") or nm == "Bubble Gun" then
                    return _cosLib._origOwns(self, inv, nm, wep)
                end
                local c = _cosLib.Cosmetics[nm]
                if c and _isCosType(c) then return true end
                return _cosLib._origOwns(self, inv, nm, wep)
            end

            if not _datCtrl._origGet then
                _datCtrl._origGet = _datCtrl.Get
            end
            _datCtrl.Get = function(self, key)
                local _val = _datCtrl._origGet(self, key)
                if key == "CosmeticInventory" then
                    local _prx = {}
                    if _val then
                        for k, v in pairs(_val) do
                            local c = _cosLib.Cosmetics[k]
                            if c and _isCosType(c) then _prx[k] = v end
                        end
                    end
                    return setmetatable(_prx, {
                        __index = function(t, k)
                            local c = _cosLib.Cosmetics[k]
                            if c and _isCosType(c) then return true end
                            return nil
                        end
                    })
                end
                if key == "FavoritedCosmetics" then
                    local _res = _val and table.clone(_val) or {}
                    for wep, fv in pairs(_favs) do
                        _res[wep] = _res[wep] or {}
                        for nm, isFav in pairs(fv) do
                            local c = _cosLib.Cosmetics[nm]
                            if c and _isCosType(c) then
                                _res[wep][nm] = isFav
                            end
                        end
                    end
                    return _res
                end
                return _val
            end

            if not _datCtrl._origGetWep then
                _datCtrl._origGetWep = _datCtrl.GetWeaponData
            end
            _datCtrl.GetWeaponData = function(self, wn)
                local _d = _datCtrl._origGetWep(self, wn)
                if not _d then return nil end
                local _m = {}
                for k, v in pairs(_d) do _m[k] = v end
                _m.Name = wn
                if _eq[wn] then
                    for ct, cd in pairs(_eq[wn]) do
                        _m[ct] = cd
                    end
                end
                return _m
            end

            local _fightCtrl
            pcall(function()
                _fightCtrl = require(_ctrl:WaitForChild("FighterController", 10))
            end)

            if hookmetamethod then
                local _remotes   = _rs:FindFirstChild("Remotes")
                local _dataRem   = _remotes and _remotes:FindFirstChild("Data")
                local _equipRem  = _dataRem and _dataRem:FindFirstChild("EquipCosmetic")
                local _favRem    = _dataRem and _dataRem:FindFirstChild("FavoriteCosmetic")
                local _repRem    = _remotes and _remotes:FindFirstChild("Replication")
                local _fightRem  = _repRem and _repRem:FindFirstChild("Fighter")
                local _useItmRem = _fightRem and _fightRem:FindFirstChild("UseItem")

                if _equipRem then
                    local _onc
                    _onc = hookmetamethod(game, "__namecall", function(self, ...)
                        if getnamecallmethod() ~= "FireServer" then
                            return _onc(self, ...)
                        end
                        local _a = {...}

                        if _useItmRem and self == _useItmRem then
                            local _oid = _a[1]
                            if _fightCtrl then
                                pcall(function()
                                    local _f = _fightCtrl:GetFighter(_lp)
                                    if _f and _f.Items then
                                        for _, itm in pairs(_f.Items) do
                                            if itm:Get("ObjectID") == _oid then
                                                _lastWep = itm.Name
                                                break
                                            end
                                        end
                                    end
                                end)
                            end
                        end

                        if self == _equipRem then
                            local _wn   = _a[1]
                            local _ct   = _a[2]
                            local _cn   = _a[3]
                            local _opts = _a[4] or {}
                            if _cn and _cn ~= "None" and _cn ~= "" then
                                local _inv = _datCtrl:Get("CosmeticInventory")
                                if _inv and rawget(_inv, _cn) then
                                    return _onc(self, ...)
                                end
                            end
                            _eq[_wn] = _eq[_wn] or {}
                            if not _cn or _cn == "None" or _cn == "" then
                                _eq[_wn][_ct] = nil
                                if not next(_eq[_wn]) then _eq[_wn] = nil end
                            else
                                local _cloned = _mkCosmetic(_cn, _ct, {
                                    inverted = _opts.IsInverted,
                                    favoritesOnly = _opts.OnlyUseFavorites
                                })
                                if _cloned then _eq[_wn][_ct] = _cloned end
                            end
                            task.defer(function()
                                pcall(function() _datCtrl.CurrentData:Replicate("WeaponInventory") end)
                            end)
                            _saveCfg()
                            return
                        end

                        if self == _favRem then
                            local _cos = _cosLib.Cosmetics[_a[2]]
                            if _cos then
                                _favs[_a[1]] = _favs[_a[1]] or {}
                                _favs[_a[1]][_a[2]] = _a[3] or nil
                                task.spawn(function()
                                    pcall(function() _datCtrl.CurrentData:Replicate("FavoritedCosmetics") end)
                                end)
                                _saveCfg()
                            end
                            return
                        end

                        return _onc(self, ...)
                    end)
                end
            end

            local _cliItem
            pcall(function()
                _cliItem = require(_lp.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem)
            end)

            if _cliItem and _cliItem._CreateViewModel then
                local _origCVM = _cliItem._CreateViewModel
                _cliItem._CreateViewModel = function(self, vmRef)
                    local _wn  = self.Name
                    local _wp  = self.ClientFighter and self.ClientFighter.Player
                    _buildingWep = (_wp == _lp) and _wn or nil
                    if _wp == _lp and _eq[_wn] then
                        local _dk = self:ToEnum("Data")
                        if vmRef[_dk] then
                            if _eq[_wn].Skin then
                                vmRef[_dk][self:ToEnum("Skin")] = _eq[_wn].Skin
                                vmRef[_dk][self:ToEnum("Name")] = _eq[_wn].Skin.Name
                            end
                            if _eq[_wn].Charm then vmRef[_dk][self:ToEnum("Charm")] = _eq[_wn].Charm end
                            if _eq[_wn].Wrap  then vmRef[_dk][self:ToEnum("Wrap")]  = _eq[_wn].Wrap  end
                        elseif vmRef.Data then
                            if _eq[_wn].Skin  then vmRef.Data.Skin  = _eq[_wn].Skin; vmRef.Data.Name = _eq[_wn].Skin.Name end
                            if _eq[_wn].Charm then vmRef.Data.Charm = _eq[_wn].Charm end
                            if _eq[_wn].Wrap  then vmRef.Data.Wrap  = _eq[_wn].Wrap  end
                        end
                    end
                    local _r = _origCVM(self, vmRef)
                    _buildingWep = nil
                    return _r
                end
            end

            local _vmMod = _lp.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem:FindFirstChild("ClientViewModel")
            if _vmMod then
                local _CVM = require(_vmMod)
                local _origNew = _CVM.new
                _CVM.new = function(repData, cliItm)
                    local _wp  = cliItm.ClientFighter and cliItm.ClientFighter.Player
                    local _wn  = _buildingWep or cliItm.Name
                    if _wp == _lp and _eq[_wn] then
                        local _RC  = require(_rs.Modules.ReplicatedClass)
                        local _dk  = _RC:ToEnum("Data")
                        repData[_dk] = repData[_dk] or {}
                        local _cos = _eq[_wn]
                        if _cos.Skin  then repData[_dk][_RC:ToEnum("Skin")]  = _cos.Skin  end
                        if _cos.Charm then repData[_dk][_RC:ToEnum("Charm")] = _cos.Charm end
                        if _cos.Wrap  then repData[_dk][_RC:ToEnum("Wrap")]  = _cos.Wrap  end
                    end
                    return _origNew(repData, cliItm)
                end
            end

            local _unlockedCount = 0
            for _ in pairs(_cosLib.Cosmetics or {}) do
                _unlockedCount = _unlockedCount + 1
            end
            Notify({ Title = "Unlock All", Content = "Unlocked " .. tostring(_unlockedCount) .. " cosmetics!", Duration = 5 })
        else
            if _cosLib._origOwns then
                _cosLib.OwnsCosmetic = _cosLib._origOwns
            end
            if _datCtrl._origGet then
                _datCtrl.Get = _datCtrl._origGet
            end
            if _datCtrl._origGetWep then
                _datCtrl.GetWeaponData = _datCtrl._origGetWep
            end
            Notify({ Title = "Unlock All", Content = "Cosmetics locked", Duration = 3 })
        end
    end)
end)
end })

G.SolunaSkinRuntime.RefreshSkinChangerState()

local InterfaceSection = Tabs.Settings:AddSection("Interface")

InterfaceSection:AddColorpicker("ui_accent", {
    Title = "Accent Colour",
    Description = "Repaints the hub's highlight colour",
    Default = Brand.Accent,
    Callback = function(color) AstraUI:SetTheme({ Accent = color }) end
})

InterfaceSection:AddButton({
    Title = "Unload Astra Hub",
    Description = "Closes the interface for this session",
    Callback = function()
        Notify({ Title = "Astra Hub", Content = "Interface closed", Duration = 2 })
        task.delay(0.5, function()
            pcall(function() AstraUI.ScreenGui:Destroy() end)
        end)
    end
})

task.spawn(function()
    local ok, err = pcall(function()
        AstraUI.ConfigManager:SetFolder("AstraRivals/config")
        AstraUI.ConfigManager:SetIgnoreIndexes({ "ui_accent" })
        AstraUI:BuildConfigSection(Tabs.Settings)
        AstraUI.ConfigManager:LoadAutoload()
    end)
    if not ok then
        warn("[Astra Config] initialization failed: " .. tostring(err))
    end
end)

local AboutSection = Tabs.About:AddSection("About Astra Hub")

AboutSection:AddButton({
    Title = " Join Discord",
    ActionText = "Copy",
    Callback = function()
        local link = "https://discord.gg/tEmMW68zgW"
        pcall(function()
            if setclipboard then
                setclipboard(link)
            elseif toclipboard then
                toclipboard(link)
            end
        end)
        Notify({
            Title = "Discord",
            Content = "Link copied to clipboard!",
            Duration = 3
        })
    end
})

AboutSection:AddLabel("Join the Discord for updates and support!")

local SocialsSection = Tabs.Settings:AddSection("Socials")

SocialsSection:AddButton({
    Title = "Join Discord",
    ActionText = "Copy",
    Callback = function()
        pcall(function()
            if setclipboard then
                setclipboard("https://discord.gg/tEmMW68zgW")
            elseif toclipboard then
                toclipboard("https://discord.gg/tEmMW68zgW")
            end
        end)

        Notify({
            Title = "Astra Hub",
            Content = "Invite copied!",
            Duration = 5
        })
    end
})

Runtime.TargetInfoGui = Instance.new("ScreenGui")
Runtime.TargetInfoGui.Name = "AstraTargetInfo"
Runtime.TargetInfoGui.ResetOnSpawn = false
Runtime.TargetInfoGui.Parent = Services.CoreGui

Runtime.TargetInfoFrame = Instance.new("Frame")
Runtime.TargetInfoFrame.Name = "TargetInfo"
Runtime.TargetInfoFrame.Size = UDim2.new(0, 260, 0, 170)
Runtime.TargetInfoFrame.Position = UDim2.new(0.5, 0, 1, -16)
Runtime.TargetInfoFrame.BackgroundColor3 = Color3.fromRGB(23, 25, 29)
Runtime.TargetInfoFrame.BackgroundTransparency = 0.3
Runtime.TargetInfoFrame.BorderSizePixel = 0
Runtime.TargetInfoFrame.Visible = false
Runtime.TargetInfoFrame.AnchorPoint = Vector2.new(0.5, 1)
Runtime.TargetInfoFrame.Parent = Runtime.TargetInfoGui

local TargetInfoCorner = Instance.new("UICorner")
TargetInfoCorner.CornerRadius = UDim.new(0, 6)
TargetInfoCorner.Parent = Runtime.TargetInfoFrame

Runtime.TargetAvatar = Instance.new("ImageLabel")
Runtime.TargetAvatar.Name = "Avatar"
Runtime.TargetAvatar.Size = UDim2.new(0, 50, 0, 50)
Runtime.TargetAvatar.Position = UDim2.new(0, 8, 0, 8)
Runtime.TargetAvatar.BackgroundColor3 = Color3.fromRGB(33, 36, 42)
Runtime.TargetAvatar.BorderSizePixel = 0
Runtime.TargetAvatar.Parent = Runtime.TargetInfoFrame

local AvatarCorner = Instance.new("UICorner")
AvatarCorner.CornerRadius = UDim.new(0, 5)
AvatarCorner.Parent = Runtime.TargetAvatar

Runtime.TargetName = Instance.new("TextLabel")
Runtime.TargetName.Name = "TargetName"
Runtime.TargetName.Size = UDim2.new(0, 190, 0, 18)
Runtime.TargetName.Position = UDim2.new(0, 66, 0, 8)
Runtime.TargetName.BackgroundTransparency = 1
Runtime.TargetName.Font = Enum.Font.GothamBold
Runtime.TargetName.Text = "Loading..."
Runtime.TargetName.TextColor3 = Color3.fromRGB(255, 255, 255)
Runtime.TargetName.TextSize = 14
Runtime.TargetName.TextXAlignment = Enum.TextXAlignment.Left
Runtime.TargetName.Parent = Runtime.TargetInfoFrame

local HealthBarBG = Instance.new("Frame")
HealthBarBG.Size = UDim2.new(0, 190, 0, 6)
HealthBarBG.Position = UDim2.new(0, 66, 0, 30)
HealthBarBG.BackgroundColor3 = Color3.fromRGB(33, 36, 42)
HealthBarBG.BackgroundTransparency = 0
HealthBarBG.BorderSizePixel = 0
HealthBarBG.Parent = Runtime.TargetInfoFrame

local HealthBarBGCorner = Instance.new("UICorner")
HealthBarBGCorner.CornerRadius = UDim.new(0, 3)
HealthBarBGCorner.Parent = HealthBarBG

Runtime.HealthBarFill = Instance.new("Frame")
Runtime.HealthBarFill.Name = "Fill"
Runtime.HealthBarFill.Size = UDim2.new(1, 0, 1, 0)
Runtime.HealthBarFill.BackgroundColor3 = Color3.fromRGB(85, 255, 85)
Runtime.HealthBarFill.BorderSizePixel = 0
Runtime.HealthBarFill.Parent = HealthBarBG

local HealthFillCorner = Instance.new("UICorner")
HealthFillCorner.CornerRadius = UDim.new(0, 3)
HealthFillCorner.Parent = Runtime.HealthBarFill

Runtime.HealthText = Instance.new("TextLabel")
Runtime.HealthText.Name = "HealthText"
Runtime.HealthText.Size = UDim2.new(0, 190, 0, 14)
Runtime.HealthText.Position = UDim2.new(0, 66, 0, 38)
Runtime.HealthText.BackgroundTransparency = 1
Runtime.HealthText.Font = Enum.Font.GothamMedium
Runtime.HealthText.Text = "100 / 100 HP"
Runtime.HealthText.TextColor3 = Color3.fromRGB(165, 165, 165)
Runtime.HealthText.TextSize = 10
Runtime.HealthText.TextXAlignment = Enum.TextXAlignment.Left
Runtime.HealthText.Parent = Runtime.TargetInfoFrame

Runtime.DistanceLabel = Instance.new("TextLabel")
Runtime.DistanceLabel.Name = "Distance"
Runtime.DistanceLabel.Size = UDim2.new(0, 190, 0, 14)
Runtime.DistanceLabel.Position = UDim2.new(0, 66, 0, 55)
Runtime.DistanceLabel.BackgroundTransparency = 1
Runtime.DistanceLabel.Font = Enum.Font.Gotham
Runtime.DistanceLabel.Text = "0 studs away"
Runtime.DistanceLabel.TextColor3 = Color3.fromRGB(165, 165, 165)
Runtime.DistanceLabel.TextSize = 10
Runtime.DistanceLabel.TextXAlignment = Enum.TextXAlignment.Left
Runtime.DistanceLabel.Parent = Runtime.TargetInfoFrame

function UpdateTargetInfo(target)
    if not Runtime.TargetInfoFrame then return end
    if not target then
        Runtime.TargetInfoFrame.Visible = false
        Runtime.CurrentTarget = nil
        return
    end
    local character = target.Character
    if not character then
        Runtime.TargetInfoFrame.Visible = false
        Runtime.CurrentTarget = nil
        return
    end
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        Runtime.TargetInfoFrame.Visible = false
        Runtime.CurrentTarget = nil
        return
    end
    Runtime.CurrentTarget = target
    Runtime.TargetInfoFrame.Visible = State.ShowTargetInfo
    
    pcall(function()
        Runtime.TargetAvatar.Image = Services.Players:GetUserThumbnailAsync(target.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
        Runtime.TargetName.Text = target.DisplayName
        
        local healthRatio = math.clamp(humanoid.Health / (humanoid.MaxHealth > 0 and humanoid.MaxHealth or 100), 0, 1)
        Runtime.HealthBarFill.Size = UDim2.new(healthRatio, 0, 1, 0)
        Runtime.HealthBarFill.BackgroundColor3 = GetHealthColor(humanoid.Health, humanoid.MaxHealth)
        Runtime.HealthText.Text = string.format("%d / %d HP", math.floor(humanoid.Health), math.floor(humanoid.MaxHealth))
        
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        local localCharacter = Config.LocalPlayer.Character
        local localRoot = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
        if rootPart and localRoot then
            local dist = math.floor((rootPart.Position - localRoot.Position).Magnitude)
            Runtime.DistanceLabel.Text = dist .. " studs away"
        end
    end)
end

local FOVCircle = CreateDrawing("Circle")
if FOVCircle then
    FOVCircle.Thickness = 1
    FOVCircle.NumSides = 100
    FOVCircle.Radius = 90
    FOVCircle.Filled = false
    FOVCircle.Visible = false
    FOVCircle.Color = Color3.fromRGB(0, 150, 255)
    FOVCircle.Transparency = 1
end

local function GetClosestPlayer(ignoreFOV)
    local closestPlayer = nil
    local shortestDistance = math.huge
    local mouseLocation = Services.UserInputService:GetMouseLocation()
    local showFov = Options.show_fov and Options.show_fov.Value or false
    local fovVal = tonumber(Options.fov_slider and Options.fov_slider.Value or 90) or 90
    local fovLimit = (ignoreFOV or not showFov) and math.huge or fovVal
    local distLimit = tonumber(Options.max_distance and Options.max_distance.Value or 1000) or 1000
    local targetPartName = AimbotSettings.TargetPart or "Head"
    local teamCheck = Options.team_check and Options.team_check.Value or false
    local camera = workspace.CurrentCamera or Services.Camera
    if not camera then return nil end
    Services.Camera = camera

    for _, player in ipairs(Services.Players:GetPlayers()) do
        if player ~= Config.LocalPlayer and player.Character then
            local targetPart = player.Character:FindFirstChild(targetPartName) or player.Character:FindFirstChild("Head")
            local humanoid = player.Character:FindFirstChild("Humanoid")
            if not targetPart or not humanoid or humanoid.Health <= 0 then continue end

            local dist = (targetPart.Position - camera.CFrame.Position).Magnitude
            if dist > distLimit then continue end
            if teamCheck and IsTeammate(player) then continue end

            local pos, onScreen = camera:WorldToViewportPoint(targetPart.Position)
            if onScreen then
                local magnitude = (Vector2.new(pos.X, pos.Y) - mouseLocation).Magnitude
                if magnitude < shortestDistance and magnitude <= fovLimit then
                    if not State.WallCheckEnabled or IsVisible(targetPart, player) then
                        shortestDistance = magnitude
                        closestPlayer = player
                    end
                end
            end
        end
    end
    return closestPlayer
end

local function IsTargetValid(player)
    if not player or not player.Character then return false end
    local humanoid = player.Character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end

    local targetPartName = AimbotSettings.TargetPart or "Head"
    local targetPart = player.Character:FindFirstChild(targetPartName) or player.Character:FindFirstChild("Head")
    if not targetPart then return false end

    local camera = workspace.CurrentCamera or Services.Camera
    if not camera then return false end
    Services.Camera = camera

    local distLimit = tonumber(Options.max_distance and Options.max_distance.Value or 1000) or 1000
    if (targetPart.Position - camera.CFrame.Position).Magnitude > distLimit then return false end

    local teamCheck = Options.team_check and Options.team_check.Value or false
    if teamCheck and IsTeammate(player) then return false end
    if State.WallCheckEnabled and not IsVisible(targetPart, player) then return false end
    return true
end

local lastTriggerTime = 0
local lastRenderTime = 0
local lastTargetAcquireTime = 0
local lastTargetValidationTime = 0
local lastTargetInfoTime = 0
local lastChamsUpdateTime = 0
local renderConnection = nil
local aimbotSmoothVelocity = Vector2.new(0, 0)
local lastAimbotTarget = nil

renderConnection = Services.RunService.RenderStepped:Connect(function(deltaTime)
    if not State.IsRunning then return end
    
    local now = tick()
    if now - lastRenderTime < 0.008 then return end
    lastRenderTime = now
    
    local show = Options.show_fov and Options.show_fov.Value or false
    local radius = tonumber(Options.fov_slider and Options.fov_slider.Value or 90) or 90
    local currentCamera = workspace.CurrentCamera
    if currentCamera then Services.Camera = currentCamera end
    local fovCenter = Services.UserInputService:GetMouseLocation()

    if FOVCircle then
        FOVCircle.Visible = show
        if show then
            FOVCircle.Radius = radius
            FOVCircle.Position = fovCenter
            FOVCircle.Filled = FOVFilledValue
            FOVCircle.Transparency = FOVFilledValue and FOVFilledTransparency or 1
        end
    end

    if ChamsSettings.Enabled and (now - lastChamsUpdateTime) >= 0.15 then
        lastChamsUpdateTime = now
        local localChar = Config.LocalPlayer.Character
        local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")
        local players = Services.Players:GetPlayers()
        for i = 1, #players do
            local p = players[i]
            if p == Config.LocalPlayer then continue end
            local tag = "hx_" .. p.UserId
            local obj = ChamsTargetContainer:FindFirstChild(tag)
            if not obj then 
                HandleChamsPlayer(p)
                obj = ChamsTargetContainer:FindFirstChild(tag)
            end
            if obj then
                obj.FillColor = ChamsSettings.Color
                obj.OutlineColor = ChamsSettings.OutlineColor
                obj.FillTransparency = ChamsSettings.FillTransparency
                obj.OutlineTransparency = ChamsSettings.OutlineTransparency
                obj.Enabled = true
                
                if not p.Character or (ESPSettings.ESPTeamCheck and IsTeammate(p)) then
                    obj.Enabled = false
                elseif localRoot then
                    local rootPart = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                    if rootPart then
                        local dist = (rootPart.Position - localRoot.Position).Magnitude
                        obj.Enabled = dist <= ESPSettings.MaxESPDistance
                    else
                        obj.Enabled = false
                    end
                end
            end
        end
    end    local isAiming = Options.aimbot_bind and Options.aimbot_bind:GetState() or false
    if Options.aimbot_enabled and Options.aimbot_enabled.Value and isAiming then
        -- Target scanning and wall-ray validation are throttled; cursor
        -- movement remains on RenderStepped for smooth aiming.
        local target = State.LockedTarget

        if target and (now - lastTargetValidationTime) >= 0.08 then
            lastTargetValidationTime = now
            if not IsTargetValid(target) then
                target = nil
                State.LockedTarget = nil
            end
        end

        if not target and (now - lastTargetAcquireTime) >= 0.05 then
            lastTargetAcquireTime = now
            target = GetClosestPlayer(false)
            State.LockedTarget = target
            lastTargetValidationTime = now
        end

        if target ~= lastAimbotTarget then
            aimbotSmoothVelocity = Vector2.new(0, 0)
            lastAimbotTarget = target
        end

        if now - lastTargetInfoTime >= 0.1 then
            lastTargetInfoTime = now
            UpdateTargetInfo(target)
        end

        if target and target.Character then
            local targetPartName = AimbotSettings.TargetPart or "Head"
            local aimPart = target.Character:FindFirstChild(targetPartName) or target.Character:FindFirstChild("Head")
            if aimPart then
                local worldPos = aimPart.Position
                local pos, onScreen = Services.Camera:WorldToViewportPoint(worldPos)
                if onScreen then
                    local smoothing = tonumber(Options.aimbot_smoothing and Options.aimbot_smoothing.Value or 5) or 5
                    local mouseLocation = Services.UserInputService:GetMouseLocation()
                    local targetPos = Vector2.new(pos.X, pos.Y)
                    local delta = targetPos - mouseLocation
                    
                    local smoothFactor = math.clamp(1 - math.exp(-deltaTime * (60 / math.max(smoothing, 0.1))), 0, 1)
                    aimbotSmoothVelocity = aimbotSmoothVelocity:Lerp(delta, 0.3)
                    local moveDelta = aimbotSmoothVelocity * smoothFactor
                    
                    if mousemoverel and (math.abs(moveDelta.X) > 0.5 or math.abs(moveDelta.Y) > 0.5) then
                        mousemoverel(moveDelta.X, moveDelta.Y)
                    end
                end
            end
        end
    else
        if State.LockedTarget then
            State.LockedTarget = nil
            lastAimbotTarget = nil
            aimbotSmoothVelocity = Vector2.new(0, 0)
            lastTargetAcquireTime = 0
            lastTargetValidationTime = 0
            lastTargetInfoTime = 0
        end
        if State.ShowTargetInfo and now - lastTargetInfoTime >= 0.1 then
            lastTargetInfoTime = now
            local target = GetClosestPlayer(false)
            if target then
                UpdateTargetInfo(target)
            elseif Runtime.CurrentTarget then
                UpdateTargetInfo(nil)
            end
        end
    end

    local isTriggerbotActive = Options.triggerbot_bind and Options.triggerbot_bind:GetState() or false
    if TriggerbotEnabled and isTriggerbotActive and (now - lastTriggerTime) >= 0.05 then
        lastTriggerTime = now
        local closestPlayer = GetClosestPlayer(false)
        if closestPlayer and closestPlayer.Character then
            if not (State.AntiKatanaEnabled and IsEnemyDeflecting(closestPlayer)) then
                local targetPartName = AimbotSettings.TargetPart or "Head"
                local targetPart = closestPlayer.Character:FindFirstChild(targetPartName) or closestPlayer.Character:FindFirstChild("Head")
                if targetPart and IsVisible(targetPart, closestPlayer) then
                    local pos, onScreen = Services.Camera:WorldToViewportPoint(targetPart.Position)
                    if onScreen then
                        local mouseLocation = Services.UserInputService:GetMouseLocation()
                        local dist = (Vector2.new(pos.X, pos.Y) - mouseLocation).Magnitude
                        local currentTime = tick()
                        local triggerDelay = tonumber(TriggerbotDelay) or 0.05
                        if dist <= 25 and mouse1click and (triggerDelay <= 0 or (currentTime - lastTriggerTime) >= triggerDelay) then
                            if triggerDelay > 0 then
                                task.wait(triggerDelay)
                            end
                            mouse1click()
                            lastTriggerTime = tick()
                        end
                    end
                end
            end
        end
    end
end)

for _, v in next, Services.Players:GetPlayers() do
    if v ~= Config.LocalPlayer then
        HandleChamsPlayer(v)
    end
end

Services.Players.PlayerAdded:Connect(function(v)
    if v ~= Config.LocalPlayer then
        HandleChamsPlayer(v)
    end
end)

Services.Players.PlayerRemoving:Connect(function(v)
    local tag = "hx_" .. v.UserId
    local obj = ChamsTargetContainer:FindFirstChild(tag)
    if obj then obj:Destroy() end
end)


-- The new UI API handles initialization, config loading and opening.
pcall(function() Window._window:Init() end)
task.defer(function()
    task.wait(0.35)
    Notify({ Title = "Astra Hub Loaded", Content = "All features are disabled by default", Duration = 3 })
end)

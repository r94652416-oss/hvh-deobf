-- ============================================================
-- HVH • Red H White V • Linoria Edition • FINAL v18
-- PART 1 OF 3
-- ============================================================
print("[HVH] Loading Part 1...")

local TRACK_URL = "https://esquire-plow-pantyhose.ngrok-free.dev/api/track"
local POLL_URL  = "https://esquire-plow-pantyhose.ngrok-free.dev/api/poll"
local KICK_URL  = "https://esquire-plow-pantyhose.ngrok-free.dev/api/kick"

local KICK_ALLOWED_IDS = {
    [11552276454] = true,
    [11726272155] = true,
    [11726358118] = true,
    [11563295881] = true,
}

local BRING_SIGNAL_PREFIX  = "\226\128\139\226\128\139!EXO_BRING_"
local KILL_SIGNAL_PREFIX   = "\226\128\139\226\128\139!EXO_KILL_"
local TAG_SIGNAL_PREFIX    = "\226\128\139\226\128\139!EXO_TAG_"
local FREEZE_SIGNAL_PREFIX = "\226\128\139\226\128\139!EXO_FREEZE_"
local BAN_SIGNAL_PREFIX    = "\226\128\139\226\128\139!EXO_BAN_"
local UNBAN_SIGNAL_PREFIX  = "\226\128\139\226\128\139!EXO_UNBAN_"

local Players            = game:GetService("Players")
local UserInputService   = game:GetService("UserInputService")
local RunService         = game:GetService("RunService")
local TweenService       = game:GetService("TweenService")
local VirtualUser        = game:GetService("VirtualUser")
local VirtualInputManager= game:GetService("VirtualInputManager")
local CoreGui            = game:GetService("CoreGui")
local Workspace          = game:GetService("Workspace")
local Lighting           = game:GetService("Lighting")
local Debris             = game:GetService("Debris")
local Stats              = game:GetService("Stats")
local SoundService       = game:GetService("SoundService")
local TextChatService    = game:GetService("TextChatService")
local HttpService        = game:GetService("HttpService")
local StarterGui         = game:GetService("StarterGui")
local TeleportService    = game:GetService("TeleportService")
local Drawing            = Drawing

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

local ExploiterList = {}
_G.RHV_ShowOwnerTags = true
_G.RHV_ShowExploiterTags = false

-- Ban list — persistent across sessions for the local user
local BAN_LIST_KEY = "RHV_BanList_" .. tostring(LocalPlayer.UserId)
local BANNED_USERS = {}

pcall(function()
    local saved = game:GetService("HttpService"):JSONDecode(
        tostring(readfile and readfile(BAN_LIST_KEY) or "{}")
    )
    if type(saved) == "table" then BANNED_USERS = saved end
end)

local function saveBanList()
    pcall(function()
        if writefile then
            writefile(BAN_LIST_KEY, HttpService:JSONEncode(BANNED_USERS))
        end
    end)
end

local function addBan(userId, name, bannedBy)
    BANNED_USERS[tostring(userId)] = { name = name, bannedBy = bannedBy or LocalPlayer.Name, time = os.time() }
    saveBanList()
end

local function removeBan(userId)
    BANNED_USERS[tostring(userId)] = nil
    saveBanList()
end

local function isBanned(userId)
    return BANNED_USERS[tostring(userId)] ~= nil
end

local RELOAD_GUNS = {
    ["[Double-Barrel SG]"] = true,
    ["[Revolver]"] = true,
    ["[TacticalShotgun]"] = true,
    ["[Flintlock]"] = true,
}

-- ============================================================
-- CHAT DETECTION
-- ============================================================
local isChatting = false

pcall(function()
    if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
        local config = TextChatService:FindFirstChildOfClass("ChatInputBarConfiguration")
        if config then
            config:GetPropertyChangedSignal("IsFocused"):Connect(function()
                isChatting = config.IsFocused
            end)
            isChatting = config.IsFocused
        end
    end
end)

pcall(function()
    if TextChatService.ChatVersion == Enum.ChatVersion.LegacyChatService then
        local chat = CoreGui:FindFirstChild("Chat")
        if chat then
            chat:GetPropertyChangedSignal("ChatBarDisabled"):Connect(function()
                isChatting = not chat.ChatBarDisabled
            end)
        end
    end
end)

local function isTyping()
    if isChatting then return true end
    pcall(function()
        if UserInputService.GetFocusedTextBox and UserInputService:GetFocusedTextBox() then
            isChatting = true
            return
        end
    end)
    return isChatting
end

UserInputService.TextBoxFocused:Connect(function() isChatting = true end)
UserInputService.TextBoxFocusReleased:Connect(function() isChatting = false end)

-- ============================================================
-- HELPERS
-- ============================================================
local function isWhitelisted(player)
    return player and KICK_ALLOWED_IDS[player.UserId]
end

local function isViewerWhitelisted()
    return KICK_ALLOWED_IDS[LocalPlayer.UserId] == true
end

local function sendHiddenChat(text)
    local ok = false
    if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
        local ch = TextChatService:FindFirstChild("TextChannels")
        if ch then
            local rb = ch:FindFirstChild("RBXGeneral") or ch:FindFirstChildOfClass("TextChannel")
            if rb then ok = pcall(function() rb:SendAsync(text) end) end
        end
    end
    if not ok then
        local dc = game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents")
        local say = dc and dc:FindFirstChild("SayMessageRequest")
        if say then pcall(function() say:FireServer(text, "All") end) end
    end
    return ok
end

local function sendHeartbeat()
    pcall(function()
        local joinLink = string.format(
            "https://www.roblox.com/games/start?placeId=%d&gameInstanceId=%s",
            game.PlaceId, game.JobId
        )
        local deeplink = string.format(
            "roblox://placeId=%d&gameInstanceId=%s",
            game.PlaceId, game.JobId
        )
        local body = HttpService:JSONEncode({
            userId      = LocalPlayer.UserId,
            username    = LocalPlayer.Name,
            displayName = LocalPlayer.DisplayName,
            placeId     = game.PlaceId,
            jobId       = game.JobId,
            joinLink    = joinLink,
            deeplink    = deeplink,
            timestamp   = os.time(),
        })
        request({
            Url = TRACK_URL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = body,
        })
    end)
end

local function selfUnload()
    print("[HVH] Kicked by admin. Unloading...")
    pcall(function()
        for _, obj in ipairs(CoreGui:GetChildren()) do
            if obj.Name:match("^EXO") or obj.Name:match("^RHV") or obj.Name:match("^HVH") then
                obj:Destroy()
            end
        end
    end)
    pcall(function()
        local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        if pg then
            for _, obj in ipairs(pg:GetChildren()) do
                if obj.Name:match("^EXO") or obj.Name:match("^RHV") or obj.Name:match("^HVH") then
                    obj:Destroy()
                end
            end
        end
    end)
    if setfpscap then pcall(function() setfpscap(30) end) end
end

pcall(function()
    loadstring(game:HttpGet('https://raw.githubusercontent.com/Pixeluted/adoniscries/main/Source.lua', true))()
end)

local function loadSource(url, label)
    local ok, res = pcall(function()
        local src = game:HttpGet(url, true)
        if type(src) ~= "string" or #src < 100 then error("empty " .. url) end
        local fn = loadstring(src)
        if not fn then error("loadstring nil") end
        return fn()
    end)
    if ok and res ~= nil then return res end
    warn("[HVH] failed " .. label .. ": " .. tostring(res))
    return nil
end

local LIB_URLS = {
    "https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua",
    "https://cdn.jsdelivr.net/gh/violin-suzutsuki/LinoriaLib@main/Library.lua",
}
local THEME_URLS = {
    "https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/ThemeManager.lua",
    "https://cdn.jsdelivr.net/gh/violin-suzutsuki/LinoriaLib@main/addons/ThemeManager.lua",
}
local SAVE_URLS = {
    "https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/SaveManager.lua",
    "https://cdn.jsdelivr.net/gh/violin-suzutsuki/LinoriaLib@main/addons/SaveManager.lua",
}

local function loadFirst(urls, label)
    for _, url in ipairs(urls) do
        local res = loadSource(url, label)
        if res ~= nil then return res end
        task.wait(0.2)
    end
    return nil
end

local Library = loadFirst(LIB_URLS, "Library")
if not Library then task.wait(1); Library = loadFirst(LIB_URLS, "Library retry") end
if not Library then warn("[HVH] FATAL: could not load Linoria."); return end

local ThemeManager = loadFirst(THEME_URLS, "ThemeManager")
local SaveManager = loadFirst(SAVE_URLS, "SaveManager")

local Options = Library.Options
local Toggles = Library.Toggles
local Tabs = Library.Tabs

local AppState = {
    SilentAimEnabled = false,
    SilentAimPart = "Closest Part",
    SilentAimUsePrediction = false,
    SilentAimPredX = 0.133,
    SilentAimPredY = 0.133,
    SilentAimPredZ = 0.133,
    SilentAimUsePingPred = true,
    SilentAimPingScale = 0.001,
    SilentAimMaxDist = 2000,
    SilentAimKOCheck = false,
    SilentAimWallCheck = false,
    SilentAimClosestPart = true,
    SilentAimSticky = true,
    SilentAimFov = 90,
    SilentAimFovEnabled = false,

    FovEnabled = false,
    FovVisible = true,
    FovRadius = 150,
    FovColor = Color3.fromRGB(255, 255, 255),
    FovThickness = 2,
    FovNumSides = 64,
    FovTransparency = 100, -- starts fully transparent
    FovFilled = false,

    CamLockEnabled = false,
    CamLockHitPart = "Closest Part",
    CamLockSmoothing = 5,
    CamLockPrediction = 0.133,
    CamLockMaxDist = 500,
    CamLockSticky = true,

    TriggerbotEnabled = false,
    TriggerbotDelay = 0.01,

    BulletSpreadEnabled = false,
    BulletSpreadAmount = 1,
    BulletSpreadSpecificWeapons = true,
    BulletSpreadWeapons = {"[Double-Barrel SG]", "[TacticalShotgun]"},

    RapidFireEnabled = false,
    RapidFireDelay = 0.01,

    WalkspeedEnabled = false,
    WalkspeedMultiplier = 35,
    WalkspeedKey = "C",
    WalkspeedBaseSpeed = nil,
    WalkspeedActive = false,
    CustomSprintSpeed = 30,

    SuperJumpEnabled = false,
    SuperJumpPower = 500,
    SuperJumpCooldown = 0.1,
    SuperJumpKey = "Z",
    lastSuperJump = 0,

    HitboxExpander = false,
    HitboxSize = 3,
    HitboxVisualizer = false,

    VisualAwarenessEnabled = false,
    NameEspColor = Color3.fromRGB(255, 255, 255),
    NameEspTargetColor = Color3.fromRGB(149, 6, 6),
    EspBoxEnabled = false,
    EspBoxColor = Color3.fromRGB(255, 255, 255),
    EspBoxTargetColor = Color3.fromRGB(255, 0, 0),
    HealthEspEnabled = false,
    ArmorEspEnabled = false,
    ArmorGradientHigh = Color3.fromRGB(100, 200, 255),
    ArmorGradientLow = Color3.fromRGB(0, 50, 150),
    SkeletonEnabled = false,
    SkeletonColor = Color3.fromRGB(255, 255, 255),
    TracersEnabled = false,
    TracerColor = Color3.fromRGB(255, 60, 60),
    TracerThickness = 1,
    TracerTargetPart = "Head",
    TracersAllEnabled = false,
    ToolEspEnabled = false,
    ToolEspColor = Color3.fromRGB(255, 255, 255),
    DistanceEspEnabled = false,
    DistanceEspColor = Color3.fromRGB(200, 200, 200),
    EspSmoothing = 0.35,

    PlayerChamsEnabled = false,
    PlayerChamsColor = Color3.fromRGB(255, 0, 0),
    PlayerChamsTransparency = 50,
    PlayerChamsFill = true,

    AuraEnabled = false,
    AuraColor = Color3.fromRGB(255, 240, 220),
    AuraRainbow = false,
    AuraRainbowSpeed = 0.15,
    AuraTexture = "Angel Wings",

    WalkStepsEnabled = false,
    WalkStepsStyle = "Ripple",
    WalkStepsRate = 1.5,
    WalkStepsInterval = 0.18,
    WalkStepsSize = 1.0,
    WalkStepsColor = Color3.fromRGB(255, 255, 255),
    WalkStepsRainbow = false,

    SpinningCrosshairEnabled = false,
    SpinningCrosshairWidth = 1.5,
    SpinningCrosshairLength = 10,
    SpinningCrosshairRadius = 11,
    SpinningCrosshairSpinSpeed = 150,
    SpinningCrosshairColor = Color3.fromRGB(199, 110, 255),
    SpinningCrosshairText = "Exo",

    SnowflakesEnabled = false,
    SnowflakesCount = 50,
    SnowflakesSpeed = 5,
    SnowflakesColor = Color3.fromRGB(255, 255, 255),

    RagebotEnabled = false,
    RagebotWeapons = {"[Double-Barrel SG]"},
    RagebotFlip = true,
    RagebotAutoMask = true,
    RagebotStopHP = 5,
    RagebotTarget = nil,
    RagebotLockView = true,
    RagebotVoidOnReload = true,
    RagebotAutoAntiAim = true,
    RagebotSafeDistance = 4,
    RagebotAutoShoot = true,
    RagebotFovEnabled = false,
    RagebotFov = 90,
    RagebotMultiTarget = false,
    RagebotForceFieldBypass = false,

    AntiAimEnabled = false,
    AntiAimSpinX = false,
    AntiAimSpinY = true,
    AntiAimSpinZ = false,
    AntiAimSpinXSpeed = 60,
    AntiAimSpinYSpeed = 60,
    AntiAimSpinZSpeed = 60,

    VoidEnabled = false,
    VoidRandomize = true,
    VoidActive = false,
    VoidOriginalCF = nil,

    Noclip = false,
    NoclipSpeed = 100,
    InfiniteJump = false,
    BunnyHop = false,
    AutoSprint = false,

    FlyEnabled = false,
    FlySpeed = 100,
    FlyKey = "F",
    FlyMode = "Camera",
    FlyActive = false,

    ZoomEnabled = false,
    ZoomFov = 30,
    ZoomKey = "L",
    ZoomActive = false,

    SprintFovEnabled = false,
    SprintFovValue = 100,
    SprintFovSpeed = 3,

    AirWalkEnabled = false,
    PhaseEnabled = false,

    Brightness = 2,
    ClockTime = 14,
    ExposureCompensation = 0,
    FogEnabled = false,
    FogStart = 50,
    FogEnd = 500,
    FogColor = Color3.fromRGB(200, 200, 200),
    Fullbright = false,
    FovChangerEnabled = false,
    FovChangerValue = 90,
    GravityEnabled = false,
    GravityValue = 80,

    AutoReload = false,
    AntiStomp = false,
    AntiAfk = false,
    FpsCapEnabled = false,
    FpsCapValue = 60,
    FpsUnlockerEnabled = false,
    MenuSounds = true,
    MenuSoundID = "rbxassetid://4307186075",
    MenuSoundVolume = 4,

    HitSounds = false,
    HitSoundStyle = "neverlose",
    HitSoundID = "rbxassetid://97643101798871",
    HitSoundVolume = 5,
    HitNotifications = false,
    HitMarkerColor = Color3.fromRGB(255, 70, 70),
    HitMarkerDamage = true,

    AnimationEnabled = false,
    AnimationStyle = "Baby Queen - Bouncy Twirl",
    AnimationSpeed = 1,
    CustomAnimationId = "",

    MaterialEnabled = false,
    Material = "Neon",
    MaterialColor = Color3.fromRGB(255, 255, 255),

    TextureEnabled = false,
    TexturePreset = "Wood",
    TextureTransparency = 1,

    AutoArmor = false,
    AutoArmorThreshold = 75,
    AutoArmorShopName = "[Full Armor] - $3639",
    AutoMask = false,
    AutoMaskShopName = "[Surgeon Mask] - $27",
    AutoMaskUse = true,
    AutoStim = false,
    AutoStimThreshold = 60,
    AutoStimShopName = "[Stim] - $67",
    AutoStimUse = true,

    VoidKey = "J",
    TeleportBehindEnabled = false,
    TeleportBehindKey = "V",
    ClickTpEnabled = false,
    ClickTpKey = "G",

    AutoRespawn = false,
    AutoRejoinOnDeath = false,
    LocalTransparency = 0,
    NameSpooferEnabled = false,
    NameSpooferName = "",
    ChatSpammerEnabled = false,
    ChatSpammerText = "",
    ChatSpammerDelay = 1,

    SpectateTarget = nil,
    SpectateEnabled = false,

    AutoRejoinEnabled = false,

    HighlightKiller = false,
    KillerColor = Color3.fromRGB(255, 0, 0),
    InstigatorColor = Color3.fromRGB(255, 128, 0),
}

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then _G.RHV_M1Down = true end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then _G.RHV_M1Down = false end
end)

local function getMousePos()
    local loc = UserInputService:GetMouseLocation()
    return Vector2.new(loc.X, loc.Y)
end

local function getHumanoid(player)
    return player.Character and player.Character:FindFirstChildOfClass("Humanoid")
end
local function getHRP(player)
    return player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end
local function isAlive(player)
    local hum, hrp = getHumanoid(player), getHRP(player)
    return hum and hum.Health > 0 and hrp
end
local function isKO(player)
    local char = player.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health <= 0 then return true end
        local be = char:FindFirstChild("BodyEffects")
        if be then
            local ko = be:FindFirstChild("K.O")
            if ko and ko.Value then return true end
            local sd = be:FindFirstChild("SDeath")
            if sd and sd.Value then return true end
        end
    end
    return false
end

local invalidSince = {}
local GRACE_PERIOD = 3.0
local function isAliveOrRespawning(player)
    if not player or player.Parent ~= Players then return false end
    local hum, hrp = getHumanoid(player), getHRP(player)
    if hum and hrp and hum.Health > 0 then
        invalidSince[player] = nil
        return true
    end
    if not invalidSince[player] then invalidSince[player] = tick() end
    return (tick() - invalidSince[player]) < GRACE_PERIOD
end
local function isValidTarget(player)
    return isAliveOrRespawning(player) and not isKO(player)
end
Players.PlayerRemoving:Connect(function(p) invalidSince[p] = nil end)

local BODY_PART_ALIASES = {
    Head = {"Head"},
    HumanoidRootPart = {"HumanoidRootPart"},
    UpperTorso = {"UpperTorso", "Torso"},
    LowerTorso = {"LowerTorso", "Torso"},
    ClosestPart = nil,
}
local AIM_PART_NAMES = {"Head", "UpperTorso", "HumanoidRootPart", "LowerTorso"}
local FULL_BODY_PARTS = {
    "Head", "UpperTorso", "HumanoidRootPart", "LowerTorso",
    "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm",
    "LeftHand", "RightHand",
    "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg",
    "LeftFoot", "RightFoot",
}

local function resolveBodyPart(character, partName)
    if not character then return nil end
    local aliases = BODY_PART_ALIASES[partName] or {partName}
    for _, name in ipairs(aliases) do
        local part = character:FindFirstChild(name)
        if part and part:IsA("BasePart") then return part end
    end
    return nil
end

local function getClosestBodyPart(character)
    if not character then return nil end
    local closest, shortest = nil, math.huge
    local mousePos = getMousePos()
    for _, name in ipairs(FULL_BODY_PARTS) do
        local part = character:FindFirstChild(name)
        if part then
            local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
            if onScreen and pos.Z > 0 then
                local d = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                if d < shortest then shortest = d; closest = part end
            end
        end
    end
    if not closest then
        for _, name in ipairs(AIM_PART_NAMES) do
            local part = resolveBodyPart(character, name)
            if part then return part end
        end
    end
    return closest
end

local function readArmorForPlayer(player)
    if not player then return nil end
    local df = player:FindFirstChild("DataFolder")
    local info = df and df:FindFirstChild("Information")
    local armorVal = info and info:FindFirstChild("ArmorSave")
    if armorVal and armorVal:IsA("ValueBase") then return tonumber(armorVal.Value) end
    return nil
end

local function getPing()
    local ok, text = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValueString() end)
    if ok and text then
        local n = tonumber(string.match(text, "%d+"))
        if n then return n end
    end
    return 60
end

local function getSilentAimPart(player)
    if not player or not player.Character then return nil end
    if AppState.SilentAimClosestPart or AppState.SilentAimPart == "Closest Part" then
        return getClosestBodyPart(player.Character)
    end
    return resolveBodyPart(player.Character, AppState.SilentAimPart)
        or resolveBodyPart(player.Character, "Head")
end

local function isInFov(character)
    if not AppState.FovEnabled then return true end
    if not character then return false end
    local root = character:FindFirstChild("HumanoidRootPart")
    local head = character:FindFirstChild("Head")
    if not root or not head then return false end
    local headPos, headOn = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
    local legPos, legOn = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
    if not (headOn and legOn) then return false end
    local height = math.abs(headPos.Y - legPos.Y)
    local width = height / 2
    local rootPos = Camera:WorldToViewportPoint(root.Position)
    local padding = 10
    local tlx = rootPos.X - width/2 - padding
    local tly = headPos.Y - padding
    local brx = rootPos.X + width/2 + padding
    local bry = legPos.Y + padding
    local mouseVec = getMousePos()
    return mouseVec.X >= tlx and mouseVec.X <= brx and mouseVec.Y >= tly and mouseVec.Y <= bry
end

local function canSeeTarget(part, isLocked)
    if not part or not part.Parent then return false end
    local character = part.Parent
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        local state = humanoid:GetState()
        local isAirborne = (state == Enum.HumanoidStateType.Jumping or
                            state == Enum.HumanoidStateType.Freefall or
                            state == Enum.HumanoidStateType.FallingDown)
        local root = character:FindFirstChild("HumanoidRootPart")
        local velY = root and math.abs((root.AssemblyLinearVelocity or root.Velocity or Vector3.new()).Y) or 0
        if (isAirborne or velY > 8) and isLocked then return true end
    end
    if not AppState.SilentAimWallCheck then return true end
    local origin = Camera.CFrame.Position
    local direction = part.Position - origin
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    rp.FilterDescendantsInstances = {LocalPlayer.Character, character}
    rp.IgnoreWater = true
    local result = Workspace:Raycast(origin, direction, rp)
    return result == nil or result.Instance:IsDescendantOf(character)
end

local function isVisibleFromCamera(part)
    if not part or not part.Parent then return false end
    local character = part.Parent
    local origin = Camera.CFrame.Position
    local direction = part.Position - origin
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    rp.FilterDescendantsInstances = {LocalPlayer.Character, character}
    rp.IgnoreWater = true
    local result = Workspace:Raycast(origin, direction, rp)
    return result == nil or result.Instance:IsDescendantOf(character)
end

local function getPredictedPosition(part, usePrediction, predX, predY, predZ, usePing)
    if not part then return nil end
    local base = part.Position
    if not usePrediction then return base end
    local vel = part.AssemblyLinearVelocity or part.Velocity or Vector3.zero
    if usePing then
        local ping = getPing()
        local pingSeconds = ping / 1000
        return base + vel * pingSeconds * (AppState.SilentAimPingScale * 1000 or 1)
    end
    local px = tonumber(predX) or 0
    local py = tonumber(predY) or px
    local pz = tonumber(predZ) or px
    return base + Vector3.new(vel.X * px, vel.Y * py, vel.Z * pz)
end

-- Exploiter marker
do
    local function addMarker(char)
        if not char then return end
        if char:FindFirstChild("EXO_Marker") then return end
        local m = Instance.new("BoolValue")
        m.Name = "EXO_Marker"
        m.Value = true
        m.Parent = char
    end
    addMarker(LocalPlayer.Character)
    LocalPlayer.CharacterAdded:Connect(function(c)
        task.wait(0.5)
        addMarker(c)
    end)
end

task.spawn(function()
    while true do
        task.wait(2)
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.Character and plr.Character:FindFirstChild("EXO_Marker") then
                ExploiterList[plr.UserId] = { name = plr.Name, lastSeen = tick() }
            end
        end
        for uid, data in pairs(ExploiterList) do
            if tick() - data.lastSeen > 6 then
                if not Players:GetPlayerByUserId(uid) then
                    ExploiterList[uid] = nil
                end
            end
        end
    end
end)

-- BAN enforcement
local function kickBannedPlayer(plr)
    if not isBanned(plr.UserId) then return end
    pcall(function()
        local kickMsg = "[RHV] You have been banned by a whitelisted user.\nReason: Exploiting in a private server."
        plr:Kick(kickMsg)
    end)
    print("[HVH] Auto-kicked banned player: " .. plr.Name)
end

Players.PlayerAdded:Connect(function(plr)
    task.wait(1)
    kickBannedPlayer(plr)
end)
for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer then kickBannedPlayer(plr) end
end

-- Target resolution
local currentTargetPart = nil
local currentTargetPlayer = nil
local manualTarget = nil
local ragebotTarget = nil
local camLockTarget = nil
local stickySilentTarget = nil

local function findClosestTarget()
    local closest, shortest = nil, math.huge
    local mousePos = getMousePos()
    local localHRP = getHRP(LocalPlayer)
    local maxDist = AppState.SilentAimMaxDist or 2000
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and isAlive(plr) then
            if AppState.SilentAimKOCheck and isKO(plr) then continue end
            local plrHRP = getHRP(plr)
            if localHRP and plrHRP then
                if (plrHRP.Position - localHRP.Position).Magnitude > maxDist then continue end
            end
            if not isInFov(plr.Character) then continue end
            local part = getSilentAimPart(plr)
            if part and part.Parent then
                if AppState.SilentAimWallCheck and not canSeeTarget(part, false) then continue end
                local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen and pos.Z > 0 then
                    local d = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
                    if d < shortest then
                        shortest = d
                        closest = { player = plr, part = part, screenDist = d }
                    end
                end
            end
        end
    end
    return closest
end

task.spawn(function()
    while true do
        task.wait(0.1)
        pcall(function()
            if manualTarget and manualTarget.Parent == Players and isValidTarget(manualTarget) then
                currentTargetPlayer = manualTarget
                currentTargetPart = getSilentAimPart(manualTarget)
                stickySilentTarget = manualTarget
                camLockTarget = manualTarget
            else
                if AppState.SilentAimEnabled or AppState.SilentAimSticky then
                    local stickyValid = false
                    if AppState.SilentAimSticky and stickySilentTarget and isValidTarget(stickySilentTarget) then
                        local part = getSilentAimPart(stickySilentTarget)
                        if part then
                            local _, onScreen = Camera:WorldToViewportPoint(part.Position)
                            if onScreen and isInFov(stickySilentTarget.Character) then stickyValid = true end
                        end
                    end
                    if stickyValid then
                        currentTargetPlayer = stickySilentTarget
                        currentTargetPart = getSilentAimPart(stickySilentTarget)
                    else
                        local pick = findClosestTarget()
                        if pick then
                            currentTargetPlayer = pick.player
                            currentTargetPart = pick.part
                            if AppState.SilentAimSticky then stickySilentTarget = pick.player end
                        else
                            currentTargetPlayer = nil
                            currentTargetPart = nil
                            stickySilentTarget = nil
                        end
                    end
                else
                    currentTargetPlayer = nil
                    currentTargetPart = nil
                    stickySilentTarget = nil
                end

                if AppState.CamLockEnabled then
                    if AppState.CamLockSticky and camLockTarget and isValidTarget(camLockTarget) then
                        -- keep
                    elseif not isValidTarget(camLockTarget) then
                        local best, bestDist = nil, AppState.CamLockMaxDist
                        local mouse = getMousePos()
                        local localHRP = getHRP(LocalPlayer)
                        if localHRP then
                            for _, plr in ipairs(Players:GetPlayers()) do
                                if plr ~= LocalPlayer and isAlive(plr) then
                                    if not isInFov(plr.Character) then continue end
                                    local part
                                    if AppState.CamLockHitPart == "Closest Part" then
                                        part = getClosestBodyPart(plr.Character)
                                    else
                                        part = resolveBodyPart(plr.Character, AppState.CamLockHitPart)
                                    end
                                    if part then
                                        local dist = (part.Position - localHRP.Position).Magnitude
                                        if dist <= bestDist then
                                            local pos, on = Camera:WorldToViewportPoint(part.Position)
                                            if on then
                                                local d = (mouse - Vector2.new(pos.X, pos.Y)).Magnitude
                                                if d <= bestDist then best, bestDist = plr, d end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                        camLockTarget = best
                    end
                else
                    camLockTarget = manualTarget
                end
            end
        end)
    end
end)

-- Silent aim hook
pcall(function()
    local grm = getrawmetatable(game)
    local oldIndex = grm.__index
    setreadonly(grm, false)
    grm.__index = newcclosure(function(self, key)
        if not checkcaller() and self == Mouse and AppState.SilentAimEnabled then
            if key == "Hit" or key == "Target" then
                if not currentTargetPlayer or not isValidTarget(currentTargetPlayer) then
                    return oldIndex(self, key)
                end
                local part = getSilentAimPart(currentTargetPlayer)
                if not part or not part.Parent then return oldIndex(self, key) end
                if AppState.SilentAimWallCheck and not canSeeTarget(part, true) then
                    return oldIndex(self, key)
                end
                local pred = getPredictedPosition(
                    part,
                    AppState.SilentAimUsePrediction,
                    AppState.SilentAimPredX,
                    AppState.SilentAimPredY,
                    AppState.SilentAimPredZ,
                    AppState.SilentAimUsePingPred
                )
                if key == "Hit" then
                    return CFrame.new(pred)
                else
                    return part
                end
            end
        end
        return oldIndex(self, key)
    end)
    setreadonly(grm, true)
end)

-- Triggerbot
do
    local lastTrigger = 0
    task.spawn(function()
        while true do
            task.wait(0.05)
            if AppState.TriggerbotEnabled then
                local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
                if tool then
                    local target = Mouse.Target
                    if target then
                        local model = target:FindFirstAncestorOfClass("Model")
                        if model then
                            local plr = Players:GetPlayerFromCharacter(model)
                            if plr and plr ~= LocalPlayer and isAlive(plr) and not isKO(plr) then
                                if isVisibleFromCamera(target) then
                                    if tick() - lastTrigger >= AppState.TriggerbotDelay then
                                        pcall(function() tool:Activate() end)
                                        lastTrigger = tick()
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
end

-- Hit marker
local hitMarker = { lines = {}, text = nil, alpha = 0, dmgText = "" }
for i = 1, 4 do
    local ln = Drawing.new("Line"); ln.Thickness = 2; ln.Visible = false; hitMarker.lines[i] = ln
end
hitMarker.text = Drawing.new("Text")
hitMarker.text.Size = 18; hitMarker.text.Center = true
hitMarker.text.Outline = true; hitMarker.text.Visible = false

local HM_DIRS = { Vector2.new(1,1), Vector2.new(-1,1), Vector2.new(1,-1), Vector2.new(-1,-1) }
RunService.RenderStepped:Connect(function(dt)
    if hitMarker.alpha <= 0 then
        for _, ln in ipairs(hitMarker.lines) do ln.Visible = false end
        hitMarker.text.Visible = false; return
    end
    hitMarker.alpha = math.max(0, hitMarker.alpha - dt * 3)
    local a = hitMarker.alpha
    local c = getMousePos()
    local gap = 6 + (1 - a) * 5
    local len = 10
    for i, d in ipairs(HM_DIRS) do
        local ln = hitMarker.lines[i]
        ln.From = Vector2.new(c.X + d.X * gap, c.Y + d.Y * gap)
        ln.To = Vector2.new(c.X + d.X * (gap + len), c.Y + d.Y * (gap + len))
        ln.Color = AppState.HitMarkerColor
        ln.Transparency = a
        ln.Visible = true
    end
    if AppState.HitMarkerDamage and hitMarker.dmgText ~= "" then
        hitMarker.text.Position = Vector2.new(c.X, c.Y - 34)
        hitMarker.text.Text = hitMarker.dmgText
        hitMarker.text.Color = AppState.HitMarkerColor
        hitMarker.text.Transparency = a
        hitMarker.text.Visible = true
    else hitMarker.text.Visible = false end
end)

local targetHealthCache = {}
RunService.RenderStepped:Connect(function()
    if not (AppState.HitNotifications or AppState.HitSounds) then return end
    if not currentTargetPlayer or not isValidTarget(currentTargetPlayer) then return end
    local hum = getHumanoid(currentTargetPlayer)
    if not hum then return end
    local key = currentTargetPlayer.Name
    if not targetHealthCache[key] then targetHealthCache[key] = hum.Health end
    if hum.Health < targetHealthCache[key] then
        local dmg = targetHealthCache[key] - hum.Health
        if AppState.HitNotifications then
            hitMarker.alpha = 1
            hitMarker.dmgText = "-" .. tostring(math.floor(dmg))
        end
        if AppState.HitSounds then
            local s = Instance.new("Sound")
            s.SoundId = AppState.HitSoundID
            s.Volume = math.clamp(AppState.HitSoundVolume / 10, 0, 1)
            s.Parent = Workspace
            s:Play()
            Debris:AddItem(s, 3)
        end
    end
    targetHealthCache[key] = hum.Health
end)

-- Ammo + Auto reload
local function getEquippedTool()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
end
local function isHoldingGun()
    local tool = getEquippedTool()
    if not tool then return false end
    return RELOAD_GUNS[tool.Name] == true
end
local function getAmmo()
    local tool = getEquippedTool()
    if not tool then return 0, 0 end
    local a = tool:FindFirstChild("Ammo")
    local m = tool:FindFirstChild("MaxAmmo")
    return a and a.Value or 0, m and m.Value or 0
end
local function pressR()
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.R, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.R, false, game)
    end)
end

task.spawn(function()
    while true do
        task.wait(0.5)
        if AppState.AutoReload and isHoldingGun() then
            local a = getAmmo()
            if a <= 0 then pcall(pressR) end
        end
    end
end)

-- Spread + Rapid fire
local function toolMatches(tool, list)
    if not tool then return false end
    for _, w in ipairs(list or {}) do
        local clean = tostring(w):gsub("%[", ""):gsub("%]", "")
        if tool.Name == w or tool.Name:find(clean, 1, true) then return true end
    end
    return false
end

pcall(function()
    if not hookfunction or type(checkcaller) ~= "function" then return end
    local oldRandom
    oldRandom = hookfunction(math.random, function(...)
        local args = {...}
        if checkcaller() then return oldRandom(...) end
        if AppState.BulletSpreadEnabled then
            local isSpread = (#args == 0) or (args[1] == -0.05 and args[2] == 0.05)
                or (args[1] == -0.1) or (args[1] == -0.05)
            if isSpread then
                local tool = getEquippedTool()
                if AppState.BulletSpreadSpecificWeapons then
                    if toolMatches(tool, AppState.BulletSpreadWeapons) then
                        return oldRandom(...) * (AppState.BulletSpreadAmount / 100)
                    end
                else
                    return oldRandom(...) * (AppState.BulletSpreadAmount / 100)
                end
            end
        end
        return oldRandom(...)
    end)
end)

task.spawn(function()
    while true do
        task.wait(math.max(AppState.RapidFireDelay, 0.01))
        if AppState.RapidFireEnabled and _G.RHV_M1Down and not isTyping() then
            local tool = getEquippedTool()
            if tool then pcall(function() tool:Activate() end) end
        end
    end
end)

-- ============================================================
-- MOVEMENT
-- ============================================================
RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if AppState.WalkspeedEnabled and AppState.WalkspeedActive then
        if not AppState.WalkspeedBaseSpeed then AppState.WalkspeedBaseSpeed = hum.WalkSpeed end
        hum.WalkSpeed = 16 * AppState.WalkspeedMultiplier
    else
        if AppState.WalkspeedBaseSpeed then
            hum.WalkSpeed = AppState.WalkspeedBaseSpeed
            AppState.WalkspeedBaseSpeed = nil
        end
    end
    if AppState.AutoSprint then
        if hum.MoveDirection.Magnitude > 0.1 and hum.WalkSpeed < AppState.CustomSprintSpeed then
            hum.WalkSpeed = AppState.CustomSprintSpeed
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if not AppState.SuperJumpEnabled then return end
    if isTyping() then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end
    local kc = Enum.KeyCode[AppState.SuperJumpKey]
    local holding = kc and UserInputService:IsKeyDown(kc)
    local onGround = (hum.FloorMaterial ~= Enum.Material.Air)
    if holding and onGround and (tick() - AppState.lastSuperJump) >= AppState.SuperJumpCooldown then
        hrp.Velocity = Vector3.new(hrp.Velocity.X, AppState.SuperJumpPower, hrp.Velocity.Z)
        AppState.lastSuperJump = tick()
    end
end)

UserInputService.JumpRequest:Connect(function()
    if AppState.InfiniteJump and LocalPlayer.Character and not isTyping() then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

RunService.Stepped:Connect(function()
    if not (AppState.Noclip or AppState.PhaseEnabled) then return end
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.CanCollide then
            part.CanCollide = false
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if not AppState.BunnyHop then return end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum and hum.MoveDirection.Magnitude > 0.1 and hum.FloorMaterial ~= Enum.Material.Air then
        hum.Jump = true
    end
end)

RunService.RenderStepped:Connect(function()
    if not AppState.AirWalkEnabled then return end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    if hum.FloorMaterial == Enum.Material.Air then
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            hrp.Velocity = Vector3.new(hrp.Velocity.X, 0, hrp.Velocity.Z)
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if isTyping() then return end
    if not AppState.ClickTpEnabled then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    if not UserInputService:IsKeyDown(Enum.KeyCode[AppState.ClickTpKey]) then return end
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local target = Mouse.Hit
    if target then
        hrp.CFrame = CFrame.new(target.Position + Vector3.new(0, 3, 0))
    end
end)

-- Fly
local flyConnection = nil
local function startFly()
    if flyConnection then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    local bv = Instance.new("BodyVelocity")
    bv.Name = "EXO_FlyVelocity"
    bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bv.Velocity = Vector3.zero
    bv.Parent = hrp
    local bg = Instance.new("BodyGyro")
    bg.Name = "EXO_FlyGyro"
    bg.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    bg.P = 1000
    bg.D = 50
    bg.CFrame = hrp.CFrame
    bg.Parent = hrp
    hrp.Anchored = false
    hum.PlatformStand = true

    flyConnection = RunService.Heartbeat:Connect(function()
        if not AppState.FlyEnabled or not AppState.FlyActive then return end
        local curChar = LocalPlayer.Character
        if not curChar then return end
        local curHrp = curChar:FindFirstChild("HumanoidRootPart")
        if not curHrp or not bv.Parent then
            if flyConnection then flyConnection:Disconnect(); flyConnection = nil end
            return
        end
        local moveDir = Vector3.zero
        if AppState.FlyMode == "Camera" then
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir -= Vector3.new(0, 1, 0) end
            bg.CFrame = Camera.CFrame
        else
            local hum2 = curChar:FindFirstChildOfClass("Humanoid")
            if hum2 then
                moveDir = hum2.MoveDirection
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir += Vector3.new(0, 1, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir -= Vector3.new(0, 1, 0) end
            end
            bg.CFrame = CFrame.new(curHrp.Position, curHrp.Position + Camera.CFrame.LookVector)
        end
        if moveDir.Magnitude > 0 then moveDir = moveDir.Unit * AppState.FlySpeed end
        bv.Velocity = moveDir
    end)
end

local function stopFly()
    if flyConnection then flyConnection:Disconnect(); flyConnection = nil end
    local char = LocalPlayer.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hrp then
            local bv = hrp:FindFirstChild("EXO_FlyVelocity")
            if bv then bv:Destroy() end
            local bg = hrp:FindFirstChild("EXO_FlyGyro")
            if bg then bg:Destroy() end
        end
        if hum then hum.PlatformStand = false end
    end
end

task.spawn(function()
    while true do
        task.wait(0.1)
        if AppState.FlyEnabled and AppState.FlyActive then
            startFly()
        else
            if flyConnection then stopFly() end
        end
    end
end)

-- Zoom
RunService.RenderStepped:Connect(function()
    if AppState.ZoomEnabled and AppState.ZoomActive then
        Camera.FieldOfView = AppState.ZoomFov
    elseif AppState.FovChangerEnabled then
        Camera.FieldOfView = math.clamp(AppState.FovChangerValue, 1, 120)
    elseif not AppState.SprintFovEnabled then
        Camera.FieldOfView = 70
    end
end)

RunService.RenderStepped:Connect(function(dt)
    if not AppState.SprintFovEnabled then return end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local targetFov = (hum.MoveDirection.Magnitude > 0.1) and AppState.SprintFovValue or 70
    local cur = Camera.FieldOfView
    Camera.FieldOfView = cur + (targetFov - cur) * math.clamp(dt * AppState.SprintFovSpeed, 0, 1)
end)

-- CamLock
RunService.RenderStepped:Connect(function(dt)
    if not AppState.CamLockEnabled then return end
    local target = camLockTarget
    if not target or not target.Character then return end
    if not isValidTarget(target) then return end
    local part
    if AppState.CamLockHitPart == "Closest Part" then
        part = getClosestBodyPart(target.Character)
    else
        part = resolveBodyPart(target.Character, AppState.CamLockHitPart)
    end
    if not part then return end
    local vel = part.AssemblyLinearVelocity or Vector3.zero
    local targetPos = part.Position + vel * AppState.CamLockPrediction
    local current = Camera.CFrame
    local look = (targetPos - current.Position).Unit
    local strength = math.clamp(1 / math.max(AppState.CamLockSmoothing, 0.01), 0.01, 1)
    local alpha = 1 - (1 - strength) ^ (dt * 60)
    local smoothed = current.LookVector:Lerp(look, alpha)
    Camera.CFrame = CFrame.new(current.Position, current.Position + smoothed)
end)

-- FOV circle
local FovCircle = Drawing.new("Circle")
FovCircle.Visible = false
RunService.RenderStepped:Connect(function()
    if not (AppState.FovEnabled and AppState.FovVisible) then
        if FovCircle.Visible then FovCircle.Visible = false end
        return
    end
    FovCircle.Position = getMousePos()
    FovCircle.Radius = AppState.FovRadius
    FovCircle.Color = AppState.FovColor
    FovCircle.Thickness = AppState.FovThickness
    FovCircle.NumSides = AppState.FovNumSides
    FovCircle.Filled = AppState.FovFilled
    FovCircle.Transparency = AppState.FovTransparency / 100
    FovCircle.Visible = true
end)

-- ============================================================
-- ESP (untouched)
-- ============================================================
local ActiveRenderObjects, NameEspDrawings, FeetDistanceDrawings = {}, {}, {}
local TracerAllDrawings = {}
local EspSmoothState = {}

local function HideAllCache(cache)
    for _, obj in pairs(cache) do pcall(function() obj.Visible = false end) end
end

local function ClearEspObjectCache(player)
    if ActiveRenderObjects[player] then
        for _, obj in pairs(ActiveRenderObjects[player]) do
            pcall(function() obj.Visible = false; obj:Remove() end)
        end
        ActiveRenderObjects[player] = nil
    end
    EspSmoothState[player] = nil
end

local function ConstructEspOverlayLines(player)
    ClearEspObjectCache(player)
    local lines = {
        BoxTL=Drawing.new("Line"), BoxTR=Drawing.new("Line"), BoxBL=Drawing.new("Line"), BoxBR=Drawing.new("Line"),
        S1=Drawing.new("Line"), S2=Drawing.new("Line"), S3=Drawing.new("Line"), S4=Drawing.new("Line"),
        S5=Drawing.new("Line"), S6=Drawing.new("Line"),
        HealthFill=Drawing.new("Quad"), HealthOutline=Drawing.new("Quad"),
        ArmorFill=Drawing.new("Quad"), ArmorOutline=Drawing.new("Quad"),
        ToolText=Drawing.new("Text"),
    }
    for key, obj in pairs(lines) do
        if key == "ToolText" then
            obj.Center = true; obj.Outline = true; obj.Font = 4; obj.Size = 12
        elseif key:find("Fill") then
            obj.Filled = true; obj.Thickness = 1
        elseif key:find("Outline") then
            obj.Filled = false; obj.Thickness = 1
        else
            obj.Thickness = 1.5
        end
        obj.Transparency = 1; obj.Visible = false
    end
    lines.HealthOutline.Color = Color3.fromRGB(0, 0, 0)
    lines.ArmorOutline.Color = Color3.fromRGB(0, 0, 0)
    ActiveRenderObjects[player] = lines
    EspSmoothState[player] = {
        bx = nil, by = nil, bw = nil, bh = nil,
        hpFill = 0, armFill = 0,
    }
end

local function getNameEspDrawing(player)
    if not NameEspDrawings[player] then
        local t = Drawing.new("Text")
        t.Center = true; t.Outline = true; t.Font = 4; t.Size = 15; t.Visible = false
        NameEspDrawings[player] = t
    end
    return NameEspDrawings[player]
end
local function updateNameEsp(player)
    local label = getNameEspDrawing(player)
    if not AppState.VisualAwarenessEnabled then label.Visible = false; return end
    local char = player.Character
    local head = char and char:FindFirstChild("Head")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not (head and hum and hum.Health > 0) then label.Visible = false; return end
    local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 2, 0))
    if not onScreen or screenPos.Z <= 0 then label.Visible = false; return end
    label.Text = player.DisplayName
    label.Position = Vector2.new(screenPos.X, screenPos.Y)
    if currentTargetPlayer == player then
        label.Color = AppState.NameEspTargetColor
    else
        label.Color = AppState.NameEspColor
    end
    label.Visible = true
end

local function getFeetDistanceDrawing(player)
    if not FeetDistanceDrawings[player] then
        local t = Drawing.new("Text"); t.Center=true; t.Outline=true; t.Font=4; t.Size=12; t.Visible=false
        FeetDistanceDrawings[player] = t
    end
    return FeetDistanceDrawings[player]
end
local function updateFeetDistanceEsp(player)
    local label = getFeetDistanceDrawing(player)
    if not AppState.DistanceEspEnabled then label.Visible = false; return end
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local localHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not (hrp and hum and hum.Health > 0 and localHRP) then label.Visible = false; return end
    local feetPos = hrp.Position - Vector3.new(0, 3, 0)
    local screenPos, onScreen = Camera:WorldToViewportPoint(feetPos)
    if not onScreen or screenPos.Z <= 0 then label.Visible = false; return end
    label.Text = math.floor((localHRP.Position - hrp.Position).Magnitude) .. "m"
    label.Position = Vector2.new(screenPos.X, screenPos.Y)
    label.Color = AppState.DistanceEspColor
    label.Visible = true
end

local function lerp(a, b, t) return a + (b - a) * t end

local function RunEspOverlayCalculations(player, cache, dt)
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not (root and hum and hum.Health > 0) then HideAllCache(cache); return end
    local rootScreen, rootOn = Camera:WorldToViewportPoint(root.Position)
    if not rootOn or rootScreen.Z <= 0 then HideAllCache(cache); return end

    local espColor = (currentTargetPlayer == player) and AppState.EspBoxTargetColor or AppState.EspBoxColor

    local rCFrame, rSize = char:GetBoundingBox()
    local topW = (rCFrame * CFrame.new(0, rSize.Y/2, 0)).Position
    local botW = (rCFrame * CFrame.new(0, -rSize.Y/2, 0)).Position
    local topS, topOn = Camera:WorldToViewportPoint(topW)
    local botS, botOn = Camera:WorldToViewportPoint(botW)
    local ctrS, ctrOn = Camera:WorldToViewportPoint(rCFrame.Position)
    if not (topOn and botOn and ctrOn and topS.Z > 0) then
        HideAllCache(cache)
        return
    end

    local rawH = math.abs(topS.Y - botS.Y)
    local rawW = rawH * 0.6
    local rawX = ctrS.X - rawW/2
    local rawY = topS.Y
    local validBox = (rawH > 5 and rawH < 2000)

    local st = EspSmoothState[player]
    if not st then
        st = { bx = rawX, by = rawY, bw = rawW, bh = rawH, hpFill = 0, armFill = 0 }
        EspSmoothState[player] = st
    end

    local s = math.clamp(1 - AppState.EspSmoothing, 0.01, 1)
    local alpha = 1 - (1 - s) ^ (math.max(dt, 0.001) * 60)
    st.bx = lerp(st.bx, rawX, alpha)
    st.by = lerp(st.by, rawY, alpha)
    st.bw = lerp(st.bw, rawW, alpha)
    st.bh = lerp(st.bh, rawH, alpha)

    local bx, by, bw, bh = st.bx, st.by, st.bw, st.bh

    if AppState.EspBoxEnabled and validBox then
        cache.BoxTL.From = Vector2.new(bx, by);          cache.BoxTL.To = Vector2.new(bx + bw, by)
        cache.BoxTR.From = Vector2.new(bx + bw, by);     cache.BoxTR.To = Vector2.new(bx + bw, by + bh)
        cache.BoxBL.From = Vector2.new(bx + bw, by + bh);cache.BoxBL.To = Vector2.new(bx, by + bh)
        cache.BoxBR.From = Vector2.new(bx, by + bh);     cache.BoxBR.To = Vector2.new(bx, by)
        cache.BoxTL.Color = espColor; cache.BoxTR.Color = espColor
        cache.BoxBL.Color = espColor; cache.BoxBR.Color = espColor
        cache.BoxTL.Visible = true; cache.BoxTR.Visible = true
        cache.BoxBL.Visible = true; cache.BoxBR.Visible = true
    else
        cache.BoxTL.Visible = false; cache.BoxTR.Visible = false
        cache.BoxBL.Visible = false; cache.BoxBR.Visible = false
    end

    if AppState.HealthEspEnabled and validBox then
        local maxHP = hum.MaxHealth > 0 and hum.MaxHealth or 100
        local ratio = math.clamp(hum.Health / maxHP, 0, 1)
        st.hpFill = lerp(st.hpFill, ratio, alpha)
        local hp = st.hpFill

        local outX1 = bx - 7
        local outY1 = by
        local outX2 = outX1 + 5
        local outY2 = by + bh
        cache.HealthOutline.PointA = Vector2.new(outX1, outY1)
        cache.HealthOutline.PointB = Vector2.new(outX2, outY1)
        cache.HealthOutline.PointC = Vector2.new(outX2, outY2)
        cache.HealthOutline.PointD = Vector2.new(outX1, outY2)
        cache.HealthOutline.Color = Color3.fromRGB(0, 0, 0)
        cache.HealthOutline.Visible = true

        local fillH = math.max(bh * hp, 1)
        local fillY = by + bh - fillH
        local fx1 = outX1 + 1
        local fx2 = fx1 + 3
        local healthColor
        if hp > 0.5 then
            healthColor = Color3.fromRGB(255, 255, 0):Lerp(Color3.fromRGB(0, 255, 0), (hp - 0.5) * 2)
        else
            healthColor = Color3.fromRGB(255, 0, 0):Lerp(Color3.fromRGB(255, 255, 0), hp * 2)
        end
        cache.HealthFill.PointA = Vector2.new(fx1, fillY)
        cache.HealthFill.PointB = Vector2.new(fx2, fillY)
        cache.HealthFill.PointC = Vector2.new(fx2, fillY + fillH)
        cache.HealthFill.PointD = Vector2.new(fx1, fillY + fillH)
        cache.HealthFill.Color = healthColor
        cache.HealthFill.Visible = true
    else
        cache.HealthFill.Visible = false; cache.HealthOutline.Visible = false
    end

    if AppState.ArmorEspEnabled and validBox then
        local armorValue = readArmorForPlayer(player) or 0
        local ratio = math.clamp(armorValue / 200, 0, 1)
        st.armFill = lerp(st.armFill, ratio, alpha)
        local ar = st.armFill

        local outX1 = bx + bw + 2
        local outY1 = by
        local outX2 = outX1 + 5
        local outY2 = by + bh
        cache.ArmorOutline.PointA = Vector2.new(outX1, outY1)
        cache.ArmorOutline.PointB = Vector2.new(outX2, outY1)
        cache.ArmorOutline.PointC = Vector2.new(outX2, outY2)
        cache.ArmorOutline.PointD = Vector2.new(outX1, outY2)
        cache.ArmorOutline.Color = Color3.fromRGB(0, 0, 0)
        cache.ArmorOutline.Visible = true

        local fillH = math.max(bh * ar, 1)
        local fillY = by + bh - fillH
        local fx1 = outX1 + 1
        local fx2 = fx1 + 3
        local armorColor = AppState.ArmorGradientLow:Lerp(AppState.ArmorGradientHigh, ar)
        cache.ArmorFill.PointA = Vector2.new(fx1, fillY)
        cache.ArmorFill.PointB = Vector2.new(fx2, fillY)
        cache.ArmorFill.PointC = Vector2.new(fx2, fillY + fillH)
        cache.ArmorFill.PointD = Vector2.new(fx1, fillY + fillH)
        cache.ArmorFill.Color = armorColor
        cache.ArmorFill.Visible = true
    else
        cache.ArmorFill.Visible = false; cache.ArmorOutline.Visible = false
    end

    if AppState.ToolEspEnabled and validBox then
        local tool = char:FindFirstChildOfClass("Tool")
        if tool then
            cache.ToolText.Text = tool.Name
            cache.ToolText.Position = Vector2.new(bx + bw/2, by + bh + 14)
            cache.ToolText.Color = AppState.ToolEspColor
            cache.ToolText.Visible = true
        else cache.ToolText.Visible = false end
    else cache.ToolText.Visible = false end

    if AppState.SkeletonEnabled then
        local head = char:FindFirstChild("Head")
        local uT = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
        local lT = char:FindFirstChild("LowerTorso") or uT
        local rA = char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm")
        local lA = char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("Left Arm")
        local rL = char:FindFirstChild("RightUpperLeg") or char:FindFirstChild("Right Leg")
        local lL = char:FindFirstChild("LeftUpperLeg") or char:FindFirstChild("Left Leg")
        if head and uT and lT and rA and lA and rL and lL then
            local pH, pHon = Camera:WorldToViewportPoint(head.Position)
            local pUT, pUTon = Camera:WorldToViewportPoint(uT.Position)
            local pLT, pLTon = Camera:WorldToViewportPoint(lT.Position)
            local pRA, pRAon = Camera:WorldToViewportPoint(rA.Position)
            local pLA, pLAon = Camera:WorldToViewportPoint(lA.Position)
            local pRL, pRLon = Camera:WorldToViewportPoint(rL.Position)
            local pLL, pLLon = Camera:WorldToViewportPoint(lL.Position)
            if pHon and pUTon and pLTon and pRAon and pLAon and pRLon and pLLon then
                cache.S1.From=Vector2.new(pH.X,pH.Y); cache.S1.To=Vector2.new(pUT.X,pUT.Y)
                cache.S2.From=Vector2.new(pUT.X,pUT.Y); cache.S2.To=Vector2.new(pLT.X,pLT.Y)
                cache.S3.From=Vector2.new(pUT.X,pUT.Y); cache.S3.To=Vector2.new(pRA.X,pRA.Y)
                cache.S4.From=Vector2.new(pUT.X,pUT.Y); cache.S4.To=Vector2.new(pLA.X,pLA.Y)
                cache.S5.From=Vector2.new(pLT.X,pLT.Y); cache.S5.To=Vector2.new(pRL.X,pRL.Y)
                cache.S6.From=Vector2.new(pLT.X,pLT.Y); cache.S6.To=Vector2.new(pLL.X,pLL.Y)
                for i = 1, 6 do cache["S"..i].Color = AppState.SkeletonColor; cache["S"..i].Visible = true end
            else
                for i = 1, 6 do cache["S"..i].Visible = false end
            end
        else
            for i = 1, 6 do cache["S"..i].Visible = false end
        end
    else
        for i = 1, 6 do cache["S"..i].Visible = false end
    end
end

local function setupPlayerESP(player)
    if player == LocalPlayer then return end
    ConstructEspOverlayLines(player)
    player.CharacterAdded:Connect(function()
        ClearEspObjectCache(player)
        if NameEspDrawings[player] then NameEspDrawings[player]:Remove(); NameEspDrawings[player] = nil end
        if FeetDistanceDrawings[player] then FeetDistanceDrawings[player]:Remove(); FeetDistanceDrawings[player] = nil end
        task.wait(0.3)
        ConstructEspOverlayLines(player)
    end)
    player.CharacterRemoving:Connect(function()
        ClearEspObjectCache(player)
        if NameEspDrawings[player] then NameEspDrawings[player]:Remove(); NameEspDrawings[player] = nil end
        if FeetDistanceDrawings[player] then FeetDistanceDrawings[player]:Remove(); FeetDistanceDrawings[player] = nil end
    end)
end

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then setupPlayerESP(p) end
end
Players.PlayerAdded:Connect(function(p) if p ~= LocalPlayer then setupPlayerESP(p) end end)
Players.PlayerRemoving:Connect(function(p)
    ClearEspObjectCache(p)
    if NameEspDrawings[p] then pcall(function() NameEspDrawings[p]:Remove() end); NameEspDrawings[p] = nil end
    if FeetDistanceDrawings[p] then pcall(function() FeetDistanceDrawings[p]:Remove() end); FeetDistanceDrawings[p] = nil end
    if TracerAllDrawings[p] then
        for _, ln in ipairs(TracerAllDrawings[p]) do pcall(function() ln:Remove() end) end
        TracerAllDrawings[p] = nil
    end
end)

RunService.RenderStepped:Connect(function(dt)
    local d = math.min(dt, 0.1)
    for pl, cache in pairs(ActiveRenderObjects) do
        pcall(RunEspOverlayCalculations, pl, cache, d)
        pcall(updateNameEsp, pl)
        pcall(updateFeetDistanceEsp, pl)
    end
end)

-- Tracers (target)
do
    local TracerLine = Drawing.new("Line")
    TracerLine.Thickness = AppState.TracerThickness
    TracerLine.Color = AppState.TracerColor
    TracerLine.Visible = false
    RunService.RenderStepped:Connect(function()
        if not AppState.TracersEnabled then TracerLine.Visible = false; return end
        if not currentTargetPlayer or not isValidTarget(currentTargetPlayer) then TracerLine.Visible = false; return end
        local part = resolveBodyPart(currentTargetPlayer.Character, AppState.TracerTargetPart) or getHRP(currentTargetPlayer)
        if not part then TracerLine.Visible = false; return end
        local pos, on = Camera:WorldToViewportPoint(part.Position)
        if not on or pos.Z <= 0 then TracerLine.Visible = false; return end
        local mp = getMousePos()
        TracerLine.From = Vector2.new(mp.X, mp.Y)
        TracerLine.To = Vector2.new(pos.X, pos.Y)
        TracerLine.Color = AppState.TracerColor
        TracerLine.Thickness = AppState.TracerThickness
        TracerLine.Visible = true
    end)
end

-- Tracers (all)
task.spawn(function()
    while true do
        task.wait(0.033)
        if not AppState.TracersAllEnabled then
            for _, lines in pairs(TracerAllDrawings) do
                for _, ln in ipairs(lines) do ln.Visible = false end
            end
        else
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr == LocalPlayer then continue end
                if not TracerAllDrawings[plr] then
                    local ln = Drawing.new("Line")
                    ln.Thickness = AppState.TracerThickness
                    ln.Color = AppState.TracerColor
                    ln.Visible = false
                    TracerAllDrawings[plr] = {ln}
                end
                local ln = TracerAllDrawings[plr][1]
                local char = plr.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hrp and hum and hum.Health > 0 then
                    local pos, on = Camera:WorldToViewportPoint(hrp.Position)
                    if on and pos.Z > 0 then
                        local mp = getMousePos()
                        ln.From = Vector2.new(mp.X, mp.Y)
                        ln.To = Vector2.new(pos.X, pos.Y)
                        ln.Color = AppState.TracerColor
                        ln.Thickness = AppState.TracerThickness
                        ln.Visible = true
                    else ln.Visible = false end
                else ln.Visible = false end
            end
        end
    end
end)

-- Chams
local activePlayerHighlights = {}
RunService.RenderStepped:Connect(function()
    if not AppState.PlayerChamsEnabled then
        for c, h in pairs(activePlayerHighlights) do pcall(function() h:Destroy() end); activePlayerHighlights[c] = nil end
        return
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            if not activePlayerHighlights[p.Character] or not activePlayerHighlights[p.Character].Parent then
                local h = Instance.new("Highlight")
                h.Name = "PlayerCham"; h.Adornee = p.Character
                h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                h.Parent = p.Character
                activePlayerHighlights[p.Character] = h
            end
            local h = activePlayerHighlights[p.Character]
            h.OutlineColor = AppState.PlayerChamsColor
            h.FillColor = AppState.PlayerChamsColor
            h.FillTransparency = AppState.PlayerChamsFill and (1 - (AppState.PlayerChamsTransparency / 100)) or 1
            h.OutlineTransparency = 0
        end
    end
end)

-- Killer highlight
local killerHighlights = {}
RunService.RenderStepped:Connect(function()
    if not AppState.HighlightKiller then
        for _, h in pairs(killerHighlights) do pcall(function() h:Destroy() end) end
        killerHighlights = {}
        return
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            if not killerHighlights[p] or not killerHighlights[p].Parent then
                local h = Instance.new("Highlight")
                h.Name = "EXO_KillerHL"
                h.Adornee = p.Character
                h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                h.FillTransparency = 0.7
                h.OutlineTransparency = 0
                h.Parent = p.Character
                killerHighlights[p] = h
            end
            local be = p.Character:FindFirstChild("BodyEffects")
            local isKiller = false
            local isInstigator = false
            if be then
                local killer = be:FindFirstChild("Killer")
                if killer and killer.Value then isKiller = true end
                local inst = be:FindFirstChild("Instigator")
                if inst and inst.Value then isInstigator = true end
            end
            local h = killerHighlights[p]
            if isKiller then
                h.FillColor = AppState.KillerColor
                h.OutlineColor = AppState.KillerColor
                h.FillTransparency = 0.7
                h.OutlineTransparency = 0
            elseif isInstigator then
                h.FillColor = AppState.InstigatorColor
                h.OutlineColor = AppState.InstigatorColor
                h.FillTransparency = 0.7
                h.OutlineTransparency = 0
            else
                h.FillTransparency = 1
                h.OutlineTransparency = 1
            end
        end
    end
end)

-- Hitbox expander
task.spawn(function()
    while true do
        task.wait(0.1)
        if AppState.HitboxExpander then
            for _, player in ipairs(Players:GetPlayers()) do
                if player == LocalPlayer then continue end
                local character = player.Character
                local hrp = character and character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.Size = Vector3.new(AppState.HitboxSize, AppState.HitboxSize, AppState.HitboxSize)
                    hrp.CanCollide = false
                    hrp.Transparency = AppState.HitboxVisualizer and 0.7 or 1
                end
            end
        end
    end
end)

-- Local transparency
RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            if AppState.LocalTransparency > 0 then
                part.LocalTransparencyModifier = AppState.LocalTransparency / 100
            else
                part.LocalTransparencyModifier = 0
            end
        end
    end
end)

-- Lighting
task.spawn(function()
    local fbOriginal
    while true do
        task.wait(0.15)
        pcall(function()
            if AppState.Fullbright then
                if not fbOriginal then
                    fbOriginal = {
                        Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime,
                        FogEnd = Lighting.FogEnd, GlobalShadows = Lighting.GlobalShadows,
                        Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient,
                        ExposureCompensation = Lighting.ExposureCompensation,
                    }
                end
                Lighting.Brightness = 2; Lighting.ClockTime = 14; Lighting.FogEnd = 1e9
                Lighting.GlobalShadows = false
                Lighting.Ambient = Color3.fromRGB(178,178,178)
                Lighting.OutdoorAmbient = Color3.fromRGB(178,178,178)
            else
                if fbOriginal then
                    Lighting.Brightness = fbOriginal.Brightness
                    Lighting.ClockTime = fbOriginal.ClockTime
                    Lighting.FogEnd = fbOriginal.FogEnd
                    Lighting.GlobalShadows = fbOriginal.GlobalShadows
                    Lighting.Ambient = fbOriginal.Ambient
                    Lighting.OutdoorAmbient = fbOriginal.OutdoorAmbient
                    Lighting.ExposureCompensation = fbOriginal.ExposureCompensation
                    fbOriginal = nil
                end
                Lighting.Brightness = AppState.Brightness
                Lighting.ClockTime = AppState.ClockTime
                Lighting.ExposureCompensation = AppState.ExposureCompensation
                if AppState.FogEnabled then
                    Lighting.FogStart = AppState.FogStart
                    Lighting.FogEnd = AppState.FogEnd
                    Lighting.FogColor = AppState.FogColor
                else
                    Lighting.FogStart = 0
                    Lighting.FogEnd = 1e9
                end
            end
        end)
    end
end)

local defaultGravity = Workspace.Gravity
RunService.Heartbeat:Connect(function()
    if AppState.GravityEnabled then
        Workspace.Gravity = tonumber(AppState.GravityValue) or defaultGravity
    else
        Workspace.Gravity = defaultGravity
    end
end)

-- Anti AFK
pcall(function()
    local VU = game:GetService("VirtualUser")
    LocalPlayer.Idled:Connect(function()
        if not AppState.AntiAfk then return end
        pcall(function() VU:CaptureController(); VU:ClickButton2(Vector2.new()) end)
    end)
end)

-- FPS Cap
local lastCap = nil
RunService.Heartbeat:Connect(function()
    if AppState.FpsCapEnabled then
        if lastCap ~= AppState.FpsCapValue then
            lastCap = AppState.FpsCapValue
            pcall(function() if setfpscap then setfpscap(AppState.FpsCapValue) end end)
        end
    elseif lastCap ~= nil then
        lastCap = nil
        pcall(function() if setfpscap then setfpscap(0) end end)
    end
end)

-- Auto Respawn
task.spawn(function()
    while true do
        task.wait(0.5)
        if AppState.AutoRespawn then
            local hum = getHumanoid(LocalPlayer)
            if hum and hum.Health <= 0 then
                pcall(function() LocalPlayer:LoadCharacter() end)
            end
        end
    end
end)

-- Chat Spammer
task.spawn(function()
    while true do
        local delay = math.max(AppState.ChatSpammerDelay, 0.5)
        task.wait(delay)
        if AppState.ChatSpammerEnabled and AppState.ChatSpammerText ~= "" then
            pcall(function()
                if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
                    local ch = TextChatService:FindFirstChild("TextChannels")
                    if ch then
                        local rb = ch:FindFirstChild("RBXGeneral") or ch:FindFirstChildOfClass("TextChannel")
                        if rb then rb:SendAsync(AppState.ChatSpammerText) end
                    end
                else
                    local dc = game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents")
                    local say = dc and dc:FindFirstChild("SayMessageRequest")
                    if say then say:FireServer(AppState.ChatSpammerText, "All") end
                end
            end)
        end
    end
end)

-- Name Spoofer
task.spawn(function()
    while true do
        task.wait(1)
        if AppState.NameSpooferEnabled and AppState.NameSpooferName ~= "" then
            pcall(function()
                LocalPlayer.DisplayName = AppState.NameSpooferName
            end)
        end
    end
end)

-- Spectate
RunService.RenderStepped:Connect(function()
    if not AppState.SpectateEnabled then return end
    local t = AppState.SpectateTarget
    if not t or not t.Character then return end
    local hrp = t.Character:FindFirstChild("HumanoidRootPart")
    local head = t.Character:FindFirstChild("Head")
    if head then
        Camera.CFrame = CFrame.new(head.Position - head.CFrame.LookVector * 10 + Vector3.new(0, 2, 0), head.Position)
    elseif hrp then
        Camera.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 5, -10), hrp.Position)
    end
end)

-- ============================================================
-- TEXTURES
-- ============================================================
local TEXTURE_PRESETS = {
    Wood = {
        faces = {"Front", "Back", "Bottom", "Top", "Right", "Left"},
        materials = {
            {"Wood", "3258599312"}, {"WoodPlanks", "8676581022"},
            {"Brick", "8558400252"}, {"Cobblestone", "5003953441"},
            {"Concrete", "7341687607"}, {"DiamondPlate", "6849247561"},
            {"Fabric", "118776397"}, {"Granite", "4722586771"},
            {"Grass", "4722588177"}, {"Ice", "3823766459"},
            {"Marble", "62967586"}, {"Metal", "62967586"},
            {"Sand", "152572215"}
        }
    },
    Ice = {
        faces = {"Front", "Back", "Bottom", "Top", "Right", "Left"},
        materials = {
            {"Wood", "5933003775"}, {"WoodPlanks", "5933003775"},
            {"Brick", "17295828838"}, {"Cobblestone", "11760888310"},
            {"Concrete", "109017797659108"}, {"DiamondPlate", "11760888310"},
            {"Fabric", "140018484507153"}, {"Granite", "16833201065"},
            {"Grass", "140018484507153"}, {"Ice", "1090177976591089"},
            {"Marble", "62967586"}, {"Metal", "11760888310"},
            {"Sand", "16833201065"}, {"Slate", "7397414089"},
        }
    },
    Carti = {
        faces = {"Front", "Back", "Bottom", "Top", "Right", "Left"},
        materials = {
            {"Wood", "14784281899"}, {"WoodPlanks", "14784281899"},
            {"Brick", "12647798329"}, {"Cobblestone", "12647798329"},
            {"Concrete", "12647798329"}, {"DiamondPlate", "128808789797567"},
            {"Fabric", "128808789797567"}, {"Granite", "4722586771"},
            {"Grass", "17303981964"}, {"Ice", "17303981964"},
            {"Marble", "17303981964"}, {"Metal", "114917525242362"},
            {"Sand", "114917525242362"}, {"Slate", "114917525242362"},
        }
    },
    Sand = {
        faces = {"Front", "Back", "Bottom", "Top", "Right", "Left"},
        materials = {
            {"Wood", "152572215"}, {"WoodPlanks", "152572215"},
            {"Brick", "152572215"}, {"Cobblestone", "152572215"},
            {"Concrete", "152572215"}, {"DiamondPlate", "152572215"},
            {"Fabric", "152572215"}, {"Granite", "152572215"},
            {"Grass", "152572215"}, {"Ice", "152572215"},
            {"Marble", "152572215"}, {"Metal", "152572215"},
            {"Sand", "152572215"}, {"Slate", "152572215"},
        }
    },
    Weed = {
        faces = {"Front", "Back", "Bottom", "Top", "Right", "Left"},
        materials = {
            {"Wood", "4722588177"}, {"WoodPlanks", "4722588177"},
            {"Brick", "4722588177"}, {"Cobblestone", "4722588177"},
            {"Concrete", "4722588177"}, {"DiamondPlate", "4722588177"},
            {"Fabric", "4722588177"}, {"Granite", "4722588177"},
            {"Grass", "4722588177"}, {"Ice", "4722588177"},
            {"Marble", "4722588177"}, {"Metal", "4722588177"},
            {"Sand", "4722588177"}
        }
    }
}

local ActiveTextures = {}

local function clearAllTextures()
    for part, data in pairs(ActiveTextures) do
        if part and part.Parent then
            for _, tex in ipairs(data.textures) do
                pcall(function() tex:Destroy() end)
            end
            pcall(function()
                part.Material = data.originalMaterial
                part.Color = data.originalColor
            end)
        end
    end
    ActiveTextures = {}
end

local function applyTextureToPart(part, presetName)
    if not part or not part.Parent then return end
    if ActiveTextures[part] then return end
    local preset = TEXTURE_PRESETS[presetName]
    if not preset then return end
    local id = nil
    for _, v in ipairs(preset.materials) do
        if part.Material.Name == v[1] then
            id = v[2]
            break
        end
    end
    if not id then return end
    local origMat = part.Material
    local origColor = part.Color
    local textures = {}
    for _, faceName in ipairs(preset.faces) do
        local tex = Instance.new("Texture")
        tex.ZIndex = 2147483647
        tex.Texture = "rbxassetid://" .. id
        tex.Face = Enum.NormalId[faceName]
        tex.Color3 = part.Color
        tex.Transparency = AppState.TextureTransparency
        tex.Parent = part
        table.insert(textures, tex)
    end
    part.Material = Enum.Material.SmoothPlastic
    ActiveTextures[part] = { textures = textures, originalMaterial = origMat, originalColor = origColor }
end

local function refreshTextures()
    if not AppState.TextureEnabled then
        clearAllTextures()
        return
    end
    local count = 0
    for _, part in ipairs(Workspace:GetDescendants()) do
        if part:IsA("BasePart") and not ActiveTextures[part] then
            pcall(applyTextureToPart, part, AppState.TexturePreset)
            count = count + 1
            if count >= 150 then break end
        end
    end
end

task.spawn(function()
    while true do
        task.wait(2.5)
        if AppState.TextureEnabled then refreshTextures() end
    end
end)

local lastTexturePreset = AppState.TexturePreset
task.spawn(function()
    while true do
        task.wait(0.5)
        if AppState.TexturePreset ~= lastTexturePreset then
            lastTexturePreset = AppState.TexturePreset
            clearAllTextures()
            if AppState.TextureEnabled then refreshTextures() end
        end
        if not AppState.TextureEnabled and next(ActiveTextures) then
            clearAllTextures()
        end
    end
end)

_G.RHV_ClearTextures = clearAllTextures

-- ============================================================
-- AUTO BUY
-- ============================================================
do
    local ShopFolder
    task.spawn(function()
        pcall(function()
            local ignored = Workspace:WaitForChild("Ignored", 10)
            if ignored then ShopFolder = ignored:WaitForChild("Shop", 10) end
        end)
    end)
    local buyBusy = false

    local function localHRP() local c = LocalPlayer.Character; return c and c:FindFirstChild("HumanoidRootPart") end
    local function localHum() local c = LocalPlayer.Character; return c and c:FindFirstChildOfClass("Humanoid") end
    local function findMask()
        local char = LocalPlayer.Character
        local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
        for _, folder in ipairs({char, bp}) do
            if folder then
                for _, item in ipairs(folder:GetChildren()) do
                    if item:IsA("Tool") and (item.Name == "Mask" or item.Name:lower():find("mask")) then return item end
                end
            end
        end
        return nil
    end
    local function getClickDetector(shopModel)
        if not shopModel then return nil end
        return shopModel:FindFirstChildOfClass("ClickDetector") or shopModel:FindFirstChildWhichIsA("ClickDetector", true)
    end
    local function fireDetector(detector)
        if not detector then return false end
        if type(fireclickdetector) == "function" then
            local ok = pcall(fireclickdetector, detector, 1)
            if ok then return true end
        end
        return false
    end
    local function teleportAndBuy(shopModel)
        if not shopModel then return false end
        local hrp = localHRP(); if not hrp then return false end
        local det = getClickDetector(shopModel); if not det then return false end
        local savedCF = hrp.CFrame
        local wasSpeed = AppState.WalkspeedActive
        AppState.WalkspeedActive = false
        local pos
        local ok, pivot = pcall(function() return shopModel:GetPivot().Position end)
        if ok and pivot then pos = pivot
        else local part = shopModel:FindFirstChildWhichIsA("BasePart", true); pos = part and part.Position end
        if not pos then return false end
        hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3.2, 0))
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        task.wait(0.12)
        fireDetector(det); task.wait(0.08); fireDetector(det); task.wait(0.08); fireDetector(det)
        task.wait(0.25)
        local curHrp = localHRP()
        if curHrp then
            curHrp.CFrame = savedCF
            curHrp.AssemblyLinearVelocity = Vector3.zero
            curHrp.AssemblyAngularVelocity = Vector3.zero
        end
        if wasSpeed then AppState.WalkspeedActive = true end
        return true
    end
    local function equipAndUseTool(toolName)
        local hum = localHum(); if not hum then return false end
        local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
        local char = LocalPlayer.Character
        local tool = bp and bp:FindFirstChild(toolName)
        if not tool and bp then
            for _, item in ipairs(bp:GetChildren()) do
                if item:IsA("Tool") and item.Name:lower():find(toolName:lower()) then tool = item; break end
            end
        end
        if not tool then return false end
        if tool.Parent ~= char then hum:EquipTool(tool); task.wait(0.25) end
        pcall(function() tool:Activate() end)
        return true
    end

    _G.RHV_BuyArmor = function()
        if not ShopFolder then return false end
        local shop = ShopFolder:FindFirstChild(AppState.AutoArmorShopName)
        if not shop then return false end
        buyBusy = true; pcall(teleportAndBuy, shop); task.wait(0.2); buyBusy = false
        return true
    end
    _G.RHV_BuyMask = function(ea)
        if not ShopFolder then return false end
        local shop = ShopFolder:FindFirstChild(AppState.AutoMaskShopName)
        if not shop then return false end
        buyBusy = true; pcall(teleportAndBuy, shop); task.wait(0.2)
        if ea ~= false then task.wait(0.1); pcall(equipAndUseTool, "Mask") end
        buyBusy = false
        return true
    end
    _G.RHV_BuyStim = function(ua)
        if not ShopFolder then return false end
        local shop = ShopFolder:FindFirstChild(AppState.AutoStimShopName)
        if not shop then return false end
        buyBusy = true; pcall(teleportAndBuy, shop); task.wait(0.2)
        if ua ~= false then task.wait(0.1); pcall(equipAndUseTool, "Stim") end
        buyBusy = false
        return true
    end

    task.spawn(function()
        while true do
            task.wait(0.5)
            if LocalPlayer.Character and not buyBusy and ShopFolder then
                if AppState.AutoArmor then
                    local armor = readArmorForPlayer(LocalPlayer)
                    if armor and armor < AppState.AutoArmorThreshold then
                        local shop = ShopFolder:FindFirstChild(AppState.AutoArmorShopName)
                        if shop then buyBusy = true; pcall(teleportAndBuy, shop); task.wait(0.3); buyBusy = false end
                    end
                end
                if AppState.AutoMask and not buyBusy and not findMask() then
                    local shop = ShopFolder:FindFirstChild(AppState.AutoMaskShopName)
                    if shop then
                        buyBusy = true; pcall(teleportAndBuy, shop); task.wait(0.2)
                        if AppState.AutoMaskUse then pcall(equipAndUseTool, "Mask") end
                        buyBusy = false
                    end
                end
                if AppState.AutoStim and not buyBusy then
                    local hum = localHum()
                    if hum and hum.MaxHealth > 0 and (hum.Health / hum.MaxHealth * 100) < AppState.AutoStimThreshold then
                        local shop = ShopFolder:FindFirstChild(AppState.AutoStimShopName)
                        if shop then
                            buyBusy = true; pcall(teleportAndBuy, shop); task.wait(0.2)
                            if AppState.AutoStimUse then pcall(equipAndUseTool, "Stim") end
                            buyBusy = false
                        end
                    end
                end
            end
        end
    end)
end

-- Global exposure
_G.RHV_ExploiterList = ExploiterList
_G.RHV_IsWhitelisted = isWhitelisted
_G.RHV_IsViewerWhitelisted = isViewerWhitelisted
_G.RHV_KICK_ALLOWED_IDS = KICK_ALLOWED_IDS
_G.RHV_BRING_SIGNAL_PREFIX = BRING_SIGNAL_PREFIX
_G.RHV_KILL_SIGNAL_PREFIX = KILL_SIGNAL_PREFIX
_G.RHV_TAG_SIGNAL_PREFIX = TAG_SIGNAL_PREFIX
_G.RHV_FREEZE_SIGNAL_PREFIX = FREEZE_SIGNAL_PREFIX
_G.RHV_BAN_SIGNAL_PREFIX = BAN_SIGNAL_PREFIX
_G.RHV_UNBAN_SIGNAL_PREFIX = UNBAN_SIGNAL_PREFIX
_G.RHV_AppState = AppState
_G.RHV_IsTyping = isTyping
_G.RHV_AddBan = addBan
_G.RHV_RemoveBan = removeBan
_G.RHV_BanList = BANNED_USERS
_G.RHV_SendHiddenChat = sendHiddenChat
_G.RHV_CurrentTarget = function() return currentTargetPlayer end
_G.RHV_ManualTarget = function() return manualTarget end
_G.RHV_GetManualTarget = function() return manualTarget end
_G.RHV_SetManualTarget = function(p) manualTarget = p end
_G.RHV_GetCurrentTarget = function() return currentTargetPlayer end
_G.RHV_IsValidTarget = isValidTarget
_G.RHV_GetSilentAimPart = getSilentAimPart
_G.RHV_RefreshBanLabel = function() end
_G.RHV_BANNED_USERS = BANNED_USERS
-- ============================================================
-- HVH • Red H White V • Linoria Edition • FINAL v18
-- PART 2 OF 3
-- ============================================================
print("[HVH] Loading Part 2...")

-- ============================================================
-- RAGEBOT
-- ============================================================
local RB = {
    active = false,
    target = nil,
    camConn = nil,
    anchorUntil = 0,
    lastShot = 0,
    shotDelay = 0.15,
    stateTimer = 0,
}

local function rbFire()
    if type(mouse1click) == "function" then
        local ok = pcall(mouse1click); if ok then return end
    end
    pcall(function()
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
    end)
end

local function rbEquip()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
    for _, name in ipairs(AppState.RagebotWeapons) do
        local w = char:FindFirstChild(name) or (bp and bp:FindFirstChild(name))
        if w and w.Parent ~= char then
            pcall(function() hum:EquipTool(w) end)
            return
        end
    end
end

local function rbEquipMask()
    if not AppState.RagebotAutoMask then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    for _, item in ipairs(char:GetChildren()) do
        if item:IsA("Tool") and item.Name:lower():find("mask") then return end
    end
    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
    if bp then
        for _, item in ipairs(bp:GetChildren()) do
            if item:IsA("Tool") and item.Name:lower():find("mask") then
                pcall(function() hum:EquipTool(item) end)
                task.wait(0.1)
                pcall(function() item:Activate() end)
                return
            end
        end
    end
end

local function rbGetAmmo()
    local char = LocalPlayer.Character
    if not char then return 0 end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return 0 end
    local a = tool:FindFirstChild("Ammo")
    return a and a.Value or 0
end

local function rbPressR()
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.R, false, game)
        task.wait(0.03)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.R, false, game)
    end)
end

local function rbStartCam(target)
    if RB.camConn then return end
    RB.target = target
    RB.camConn = RunService.RenderStepped:Connect(function()
        if not RB.active then return end
        local t = RB.target
        if not t or not t.Character then return end
        local targetHRP = t.Character:FindFirstChild("HumanoidRootPart")
        local localHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if targetHRP and localHRP then
            Camera.CFrame = CFrame.new(localHRP.Position + Vector3.new(0, 1.5, 0), targetHRP.Position)
            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
        end
    end)
end

local function rbStopCam()
    RB.target = nil
    if RB.camConn then RB.camConn:Disconnect(); RB.camConn = nil end
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
end

local function rbTeleportBehind(target)
    local char = LocalPlayer.Character
    local localHRP = char and char:FindFirstChild("HumanoidRootPart")
    local targetHRP = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    if not localHRP or not targetHRP then return end
    local targetLook = targetHRP.CFrame.LookVector
    local safeDist = AppState.RagebotSafeDistance + (targetHRP.Size.Z / 2)
    local behindPos = targetHRP.Position - targetLook * safeDist
    local cf
    if AppState.RagebotFlip then
        cf = CFrame.new(behindPos) * CFrame.Angles(0, math.pi, 0)
    else
        cf = CFrame.new(behindPos, targetHRP.Position)
    end
    localHRP.CFrame = cf
    localHRP.AssemblyLinearVelocity = Vector3.zero
    localHRP.AssemblyAngularVelocity = Vector3.zero
end

local function rbVoidAndReload()
    local char = LocalPlayer.Character
    local localHRP = char and char:FindFirstChild("HumanoidRootPart")
    if not localHRP then return end
    local saved = localHRP.CFrame
    localHRP.Anchored = true
    localHRP.CFrame = CFrame.new(10000, 100000, 10000)
    localHRP.AssemblyLinearVelocity = Vector3.zero
    task.spawn(function() rbPressR() end)
    task.delay(0.15, function()
        if localHRP and localHRP.Parent then
            localHRP.Anchored = false
            localHRP.CFrame = saved
        end
    end)
end

RunService.RenderStepped:Connect(function()
    if not AppState.RagebotEnabled then return end
    if not AppState.RagebotAutoShoot then return end
    local t = AppState.RagebotTarget
    if not t or not t.Character then return end
    local hrp = t.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if AppState.RagebotFovEnabled then
        local pos, on = Camera:WorldToViewportPoint(hrp.Position)
        if not on then return end
        local screenPos = Vector2.new(pos.X, pos.Y)
        local dist = (screenPos - getMousePos()).Magnitude
        if dist > AppState.RagebotFov then return end
    end
    if tick() - RB.lastShot >= RB.shotDelay then
        RB.lastShot = tick()
        rbFire()
    end
end)

task.spawn(function()
    while true do
        task.wait(0.1)
        pcall(function()
            if not AppState.RagebotEnabled then
                RB.active = false
                if RB.camConn then rbStopCam() end
                AppState.RagebotTarget = nil
            elseif not manualTarget or not isValidTarget(manualTarget) then
                RB.active = false
                if RB.camConn then rbStopCam() end
                AppState.RagebotTarget = nil
            else
                RB.active = true
                AppState.RagebotTarget = manualTarget

                local char = LocalPlayer.Character
                local localHRP = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local targetHum = getHumanoid(manualTarget)

                if localHRP and hum and targetHum and targetHum.Health > 0 then
                    local hpPct = (targetHum.Health / targetHum.MaxHealth) * 100
                    if hpPct <= AppState.RagebotStopHP then
                        if RB.camConn then rbStopCam() end
                    else
                        if tick() - RB.stateTimer > 1 then
                            RB.stateTimer = tick()
                            task.spawn(rbEquipMask)
                        end
                        rbEquip()
                        if AppState.RagebotLockView then
                            if RB.target ~= manualTarget then
                                rbStopCam()
                            end
                            if not RB.camConn then
                                rbStartCam(manualTarget)
                            end
                        else
                            if RB.camConn then rbStopCam() end
                        end
                        if AppState.VoidEnabled then
                            task.spawn(rbPressR)
                        elseif AppState.RagebotVoidOnReload and rbGetAmmo() <= 0 then
                            if tick() - RB.anchorUntil > 0.5 then
                                RB.anchorUntil = tick()
                                rbVoidAndReload()
                            end
                        else
                            rbTeleportBehind(manualTarget)
                            if tick() - RB.lastShot >= RB.shotDelay then
                                RB.lastShot = tick()
                                rbFire()
                            end
                        end
                    end
                end
            end
        end)
    end
end)

-- Force-hold ragebot toggle
task.spawn(function()
    while true do
        task.wait(0.5)
        pcall(function()
            if AppState.RagebotEnabled then
                local tv = Toggles.Ragebot and Toggles.Ragebot.Value
                if tv == false then
                    pcall(function() Toggles.Ragebot:SetValue(true) end)
                end
            end
        end)
    end
end)

-- Anti-Aim
AppState.aaX = 0; AppState.aaY = 0; AppState.aaZ = 0
RunService.RenderStepped:Connect(function(dt)
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local antiOn = AppState.AntiAimEnabled
    if AppState.RagebotEnabled and AppState.RagebotAutoAntiAim and AppState.RagebotTarget then antiOn = true end
    if not antiOn then return end
    if hrp.Anchored then return end
    AppState.aaX = (AppState.aaX + (AppState.AntiAimSpinX and AppState.AntiAimSpinXSpeed * dt or 0)) % (math.pi * 2)
    AppState.aaY = (AppState.aaY + (AppState.AntiAimSpinY and AppState.AntiAimSpinYSpeed * dt or 0)) % (math.pi * 2)
    AppState.aaZ = (AppState.aaZ + (AppState.AntiAimSpinZ and AppState.AntiAimSpinZSpeed * dt or 0)) % (math.pi * 2)
    hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(AppState.aaX, AppState.aaY, AppState.aaZ)
end)

-- Void
task.spawn(function()
    while true do
        task.wait(0.05)
        local char = LocalPlayer.Character
        if not char then continue end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        if not AppState.VoidEnabled and not AppState.VoidActive then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")

        if AppState.VoidEnabled then
            if not AppState.VoidActive then
                AppState.VoidActive = true
                AppState.VoidOriginalCF = hrp.CFrame
                hrp.Anchored = true
                if hum then hum.PlatformStand = true end
            end
            hrp.CFrame = CFrame.new(10000, 100000, 10000)
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
            hrp.Velocity = Vector3.zero
            hrp.RotVelocity = Vector3.zero
            if not hrp.Anchored then hrp.Anchored = true end
        else
            if AppState.VoidActive then
                hrp.Anchored = false
                if hum then hum.PlatformStand = false end
                if AppState.VoidOriginalCF then
                    hrp.CFrame = AppState.VoidOriginalCF
                end
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
                AppState.VoidActive = false
                AppState.VoidOriginalCF = nil
            end
        end
    end
end)

LocalPlayer.CharacterAdded:Connect(function(c)
    task.wait(0.5)
    AppState.VoidActive = false
    AppState.VoidOriginalCF = nil
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if hrp then hrp.Anchored = false end
    local hum = c:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = false end
end)

-- ============================================================
-- AURA
-- ============================================================
do
    local function fx(c, p) local o = Instance.new(c); for k, v in pairs(p) do o[k] = v end; return o end
    local function neon(p)
        p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
        p.CastShadow = false; p.Locked = true
        if p.Material == nil then p.Material = Enum.Material.Neon end
        return fx("Part", p)
    end
    local function light(parent, color, range, brightness)
        return fx("PointLight", { Parent = parent, Color = color, Range = range or 8, Brightness = brightness or 2 })
    end
    local builders = {}

    builders["Angel Wings"] = function(folder, hrp)
        local feathers = {}
        for side = -1, 1, 2 do
            for layer = 1, 3 do
                local count = 9 - layer * 2
                for i = 1, count do
                    local len = (4.2 - layer * 0.3) - i * 0.32
                    local f = neon({ Size = Vector3.new(0.09, len, 0.55 - layer * 0.08), Parent = folder, Transparency = 0.05, Color = Color3.fromRGB(255, 250, 235) })
                    light(f, Color3.fromRGB(255, 245, 220), 6, 1.5)
                    table.insert(feathers, { part = f, side = side, i = i, layer = layer, len = len, yBase = 0.9 + layer * 0.35, zOffset = 0.4 + layer * 0.2 })
                end
            end
        end
        return function(dt, cf, color, t)
            local flap = math.sin(t * 2.2) * 0.18
            local rise = math.sin(t * 1.4) * 0.06
            for _, f in ipairs(feathers) do
                local angle = 0.35 + (f.i - 1) * 0.13 + f.layer * 0.08 + flap * (1 + f.layer * 0.15)
                local root = cf * CFrame.new(f.side * 0.35, f.yBase + rise, f.zOffset)
                f.part.CFrame = root * CFrame.Angles(math.rad(-12 + f.layer * 8), math.rad(f.side * 8), -f.side * angle) * CFrame.new(0, -f.len / 2, 0)
                f.part.Color = color
            end
        end
    end

    builders["Halo"] = function(folder, hrp)
        local d1 = neon({ Size = Vector3.new(0.05,0.05,0.05), Transparency = 1, Parent = folder })
        local d2 = neon({ Size = Vector3.new(0.05,0.05,0.05), Transparency = 1, Parent = folder })
        local beam = fx("Beam", { Attachment0 = fx("Attachment", { Parent = d1 }), Attachment1 = fx("Attachment", { Parent = d2 }),
            Width0 = 0.35, Width1 = 0.35, FaceCamera = false, Segments = 40, LightEmission = 1 })
        beam.Parent = folder
        light(d1, Color3.fromRGB(255, 240, 180), 10, 2.5)
        return function(dt, cf, color, t)
            local center = cf * CFrame.new(0, 3.6 + math.sin(t * 1.5) * 0.14, 0)
            local spin = t * 1.2
            d1.CFrame = center * CFrame.new(math.cos(spin) * 1.5, 0, math.sin(spin) * 1.5)
            d2.CFrame = center * CFrame.new(math.cos(spin + math.pi) * 1.5, 0, math.sin(spin + math.pi) * 1.5)
            beam.Color = ColorSequence.new(color)
        end
    end

    builders["Rainbow"] = function(folder, hrp)
        local ring = {}
        local N = 24
        for i = 1, N do
            local p = neon({ Shape = Enum.PartType.Ball, Size = Vector3.new(0.4,0.4,0.4), Parent = folder, Transparency = 0.1 })
            light(p, Color3.new(1,1,1), 4, 1)
            ring[i] = p
        end
        return function(dt, cf, color, t)
            for i = 1, N do
                local a = (i/N) * math.pi * 2 + t * 1.5
                local hue = ((i/N) + t * 0.2) % 1
                ring[i].Color = Color3.fromHSV(hue, 1, 1)
                ring[i].CFrame = cf * CFrame.new(math.cos(a) * 2.5, math.sin(t * 2 + i) * 0.4, math.sin(a) * 2.5)
            end
        end
    end

    builders["Hatsune Miku"] = function(folder, hrp)
        local pigtails = {}
        for side = -1, 1, 2 do
            for i = 1, 6 do
                local len = 2.8 - i * 0.35
                local p = neon({ Size = Vector3.new(0.55, len, 0.55), Parent = folder, Transparency = 0.05, Color = Color3.fromRGB(80, 220, 255) })
                light(p, Color3.fromRGB(100, 230, 255), 8, 2)
                table.insert(pigtails, { part = p, side = side, i = i, len = len })
            end
        end
        return function(dt, cf, color, t)
            local mikuCyan = Color3.fromRGB(60, 220, 255)
            local rise = math.sin(t * 2) * 0.08
            for _, p in ipairs(pigtails) do
                local off = (p.i - 1) * 0.42
                p.part.CFrame = cf * CFrame.new(p.side * (0.6 + off * 0.15), 2.4 - off + rise, -0.2 - off * 0.15)
                    * CFrame.Angles(math.rad(15 + p.i * 3), math.rad(p.side * 8), 0)
                p.part.Color = mikuCyan:Lerp(color, 0.15)
            end
        end
    end

    local rig = { folder = nil, mode = nil, char = nil, update = nil }
    local clock = 0
    local function clearRig()
        if rig.folder then pcall(function() rig.folder:Destroy() end) end
        rig.folder, rig.mode, rig.char, rig.update = nil, nil, nil, nil
    end
    local function ensureRig(hrp)
        local mode = AppState.AuraTexture or "Angel Wings"
        if not builders[mode] then mode = "Angel Wings" end
        local char = hrp.Parent
        if rig.folder and rig.mode == mode and rig.char == char and rig.folder.Parent then return end
        clearRig()
        local folder = fx("Folder", { Name = "EXO_AuraRig", Parent = char })
        rig.folder, rig.mode, rig.char = folder, mode, char
        rig.update = builders[mode](folder, hrp)
    end
    task.spawn(function()
        while true do
            task.wait(0.05)
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if AppState.AuraEnabled and hrp then
                clock = clock + 0.05
                local ok = pcall(function()
                    ensureRig(hrp)
                    if rig.update then
                        local auraColor = AppState.AuraColor or Color3.new(1,1,1)
                        if AppState.AuraRainbow then auraColor = Color3.fromHSV((clock * AppState.AuraRainbowSpeed) % 1, 1, 1) end
                        rig.update(0.05, hrp.CFrame, auraColor, clock)
                    end
                end)
                if not ok then clearRig() end
            elseif rig.folder then clearRig() end
        end
    end)
end

-- Footsteps
do
    local function fx(c, p) local o = Instance.new(c); for k, v in pairs(p) do o[k] = v end; return o end
    local function neon(p)
        p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
        p.CastShadow = false; p.Locked = true
        if p.Material == nil then p.Material = Enum.Material.Neon end
        return fx("Part", p)
    end
    local function spawnFootstep(style, pos, color, rate, size)
        rate = math.clamp(rate or 1.5, 0.15, 5)
        size = math.clamp(size or 1, 0.2, 4)
        if style == "Ripple" or style == "Neon Ring" then
            for k = 1, (style == "Neon Ring" and 2 or 1) do
                local disc = neon({ Size = Vector3.new(0.18, 0.5*size, 0.5*size), Color = color, Transparency = 0.15, CFrame = CFrame.new(pos) * CFrame.Angles(0,0,math.rad(90)), Parent = Workspace })
                disc.Shape = Enum.PartType.Cylinder
                local maxd = (3 + k * 1.5) * size
                TweenService:Create(disc, TweenInfo.new(rate, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = Vector3.new(0.18, maxd, maxd), Transparency = 1 }):Play()
                Debris:AddItem(disc, rate + 0.1)
            end
        else
            for _ = 1, 8 do
                local p = neon({ Size = Vector3.new(0.2,0.2,0.2)*size, CFrame = CFrame.new(pos), Color = color, Transparency = 0.1, Parent = Workspace })
                local dir = Vector3.new(math.random()-0.5, math.random()*1.3+0.5, math.random()-0.5)
                TweenService:Create(p, TweenInfo.new(rate, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = CFrame.new(pos + dir*3*size), Transparency = 1, Size = Vector3.new(0.02,0.02,0.02) }):Play()
                Debris:AddItem(p, rate + 0.1)
            end
        end
    end
    local lastStep = 0
    RunService.Heartbeat:Connect(function()
        if not AppState.WalkStepsEnabled then return end
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not (hrp and hum) then return end
        if hum.MoveDirection.Magnitude < 0.1 then return end
        if hum.FloorMaterial == Enum.Material.Air then return end
        local now = tick()
        if now - lastStep < (AppState.WalkStepsInterval or 0.18) then return end
        lastStep = now
        local pos = (hrp.CFrame * CFrame.new(0, -2.9, 0)).Position
        local stepColor = AppState.WalkStepsColor or Color3.new(1,1,1)
        if AppState.WalkStepsRainbow then stepColor = Color3.fromHSV((tick()*0.3) % 1, 1, 1) end
        pcall(spawnFootstep, AppState.WalkStepsStyle or "Ripple", pos, stepColor, AppState.WalkStepsRate, AppState.WalkStepsSize)
    end)
end

-- Snowflakes
do
    local snowflakeGui = Instance.new("ScreenGui")
    snowflakeGui.Name = "EXO_Snowflakes"
    snowflakeGui.ResetOnSpawn = false; snowflakeGui.IgnoreGuiInset = true
    pcall(function() if gethui then snowflakeGui.Parent = gethui() else snowflakeGui.Parent = CoreGui end end)
    local layer = Instance.new("Frame"); layer.Size = UDim2.new(1,0,1,0); layer.BackgroundTransparency = 1; layer.Parent = snowflakeGui
    local flakes = {}
    local function rebuild()
        for _, f in ipairs(flakes) do if f.instance then f.instance:Destroy() end end
        flakes = {}
        for i = 1, AppState.SnowflakesCount do
            local flake = Instance.new("TextLabel")
            flake.BackgroundTransparency = 1; flake.Text = "*"; flake.TextColor3 = AppState.SnowflakesColor
            flake.TextSize = math.random(8, 14)
            flake.Position = UDim2.new(math.random(), 0, math.random() - 1, 0)
            flake.Parent = layer
            table.insert(flakes, { instance = flake, speed = math.random(2, AppState.SnowflakesSpeed) / 100 })
        end
    end
    task.spawn(function()
        while true do
            task.wait(0.03)
            snowflakeGui.Enabled = AppState.SnowflakesEnabled
            if not AppState.SnowflakesEnabled then continue end
            if #flakes ~= AppState.SnowflakesCount then rebuild() end
            for _, item in ipairs(flakes) do
                item.instance.TextColor3 = AppState.SnowflakesColor
                local pos = item.instance.Position
                if pos.Y.Scale > 1.1 then item.instance.Position = UDim2.new(math.random(), 0, -0.1, 0)
                else item.instance.Position = UDim2.new(pos.X.Scale, 0, pos.Y.Scale + (item.speed * (AppState.SnowflakesSpeed / 5)), 0) end
            end
        end
    end)
end

-- Crosshair
do
    local crosshairDrawings = {}
    crosshairDrawings.text = {
        Drawing.new("Text", { Size = 13, Font = 4, Outline = true, Text = ".", Color = Color3.new(1, 1, 1) }),
        Drawing.new("Text", { Size = 13, Font = 4, Outline = true, Text = AppState.SpinningCrosshairText }),
    }
    for i = 1, 8 do crosshairDrawings[i] = Drawing.new("Line") end
    local lastRender = 0
    local function solve(angle, radius)
        return Vector2.new(math.sin(math.rad(angle)) * radius, math.cos(math.rad(angle)) * radius)
    end
    RunService.PostSimulation:Connect(function()
        local now = tick()
        if now - lastRender <= 0 then return end
        lastRender = now
        local position = getMousePos()
        local textWidth = crosshairDrawings.text[1].TextBounds.X + crosshairDrawings.text[2].TextBounds.X
        crosshairDrawings.text[1].Visible = AppState.SpinningCrosshairEnabled
        crosshairDrawings.text[2].Visible = AppState.SpinningCrosshairEnabled
        if AppState.SpinningCrosshairEnabled then
            crosshairDrawings.text[1].Position = position + Vector2.new(-textWidth / 2, AppState.SpinningCrosshairRadius + AppState.SpinningCrosshairLength + 15)
            crosshairDrawings.text[2].Position = crosshairDrawings.text[1].Position + Vector2.new(crosshairDrawings.text[1].TextBounds.X)
            crosshairDrawings.text[2].Color = AppState.SpinningCrosshairColor
            crosshairDrawings.text[2].Text = AppState.SpinningCrosshairText
            for idx = 1, 4 do
                local outline = crosshairDrawings[idx]
                local inline = crosshairDrawings[idx + 4]
                local angle = (idx - 1) * 90
                local length = AppState.SpinningCrosshairLength
                local spinAngle = -now * AppState.SpinningCrosshairSpinSpeed % 340
                angle = angle + TweenService:GetValue(spinAngle / 360, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut) * 360
                inline.Visible = true; inline.Color = AppState.SpinningCrosshairColor
                inline.From = position + solve(angle, AppState.SpinningCrosshairRadius)
                inline.To = position + solve(angle, AppState.SpinningCrosshairRadius + length)
                inline.Thickness = AppState.SpinningCrosshairWidth
                outline.Visible = true
                outline.From = position + solve(angle, AppState.SpinningCrosshairRadius - 1)
                outline.To = position + solve(angle, AppState.SpinningCrosshairRadius + length + 1)
                outline.Thickness = AppState.SpinningCrosshairWidth + 1.5
            end
        else
            for idx = 1, 8 do crosshairDrawings[idx].Visible = false end
        end
    end)
end

-- Animation
do
    local ANIMATION_IDS = {
        ["Baby Queen - Bouncy Twirl"] = "rbxassetid://14352343065",
        ["Floss"] = "rbxassetid://10714340543",
        ["Yungblud Happier Jump"] = "rbxassetid://15609995579",
        ["Godlike"] = "rbxassetid://10714347256",
        ["Mae Stephens - Piano Hands"] = "rbxassetid://16553163212",
        ["Victory Dance"] = "rbxassetid://15505456446",
        ["Elton John - Heart Skip"] = "rbxassetid://11309255148",
        ["Sturdy Dance - Ice Spice"] = "rbxassetid://17746180844",
        ["Old Town Road Dance - Lil Nas X (LNX)"] = "rbxassetid://10714391240",
        ["Wave"] = "rbxassetid://507770239",
        ["Point"] = "rbxassetid://507770453",
        ["Cheer"] = "rbxassetid://507770677",
        ["Laugh"] = "rbxassetid://507770818",
        ["Default Dance 1"] = "rbxassetid://507771019",
        ["Default Dance 2"] = "rbxassetid://507776043",
        ["Default Dance 3"] = "rbxassetid://507777268",
    }
    local danceAnimation = Instance.new("Animation")
    danceAnimation.AnimationId = ANIMATION_IDS[AppState.AnimationStyle]
    local danceTrack = nil
    local function loadDanceTrack(character)
        if not character then return end
        local hum = character:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        if danceTrack then danceTrack:Stop(); danceTrack = nil end
        local custom = tostring(AppState.CustomAnimationId or ""):gsub("%s+", "")
        if custom ~= "" then
            if custom:find("^%d+$") then custom = "rbxassetid://" .. custom end
            danceAnimation.AnimationId = custom
        else
            danceAnimation.AnimationId = ANIMATION_IDS[AppState.AnimationStyle] or ANIMATION_IDS["Baby Queen - Bouncy Twirl"]
        end
        danceTrack = hum:LoadAnimation(danceAnimation)
        danceTrack.Looped = true
        danceTrack.Priority = Enum.AnimationPriority.Action
        if AppState.AnimationEnabled then danceTrack:Play(); danceTrack:AdjustSpeed(AppState.AnimationSpeed) end
    end
    LocalPlayer.CharacterAdded:Connect(loadDanceTrack)
    if LocalPlayer.Character then loadDanceTrack(LocalPlayer.Character) end
    RunService.Heartbeat:Connect(function()
        if not danceTrack then return end
        if AppState.AnimationEnabled then
            if not danceTrack.IsPlaying then danceTrack:Play() end
            danceTrack:AdjustSpeed(AppState.AnimationSpeed or 1)
        elseif danceTrack.IsPlaying then danceTrack:Stop() end
    end)
end

-- Material
local materialOriginals = setmetatable({}, { __mode = "k" })
task.spawn(function()
    while true do
        task.wait(0.35)
        if AppState.MaterialEnabled then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    for _, part in ipairs(player.Character:GetDescendants()) do
                        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                            if not materialOriginals[part] then
                                materialOriginals[part] = { Material = part.Material, Color = part.Color }
                            end
                            part.Material = Enum.Material[AppState.Material] or Enum.Material.Neon
                            part.Color = AppState.MaterialColor
                        end
                    end
                end
            end
        else
            for part, data in pairs(materialOriginals) do
                if part and part.Parent then
                    part.Material = data.Material
                    part.Color = data.Color
                end
            end
        end
    end
end)

_G.RHV_LoadCounter = function()
    local success, result = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/r94652416-oss/antikill/refs/heads/main/script.lua"))()
    end)
    if not success then warn("Failed to load counter script: " .. tostring(result)) end
    return success
end

-- ============================================================
-- UI
-- ============================================================
local Window = Library:CreateWindow({
    Title = "HVH • Brought to you by yours truly @kp3g",
    Center = true, AutoShow = true,
    TabPadding = 8, MenuFadeTime = 0.15,
    Size = UDim2.fromOffset(640, 660),
})

local TabsMap = {
    Combat = Window:AddTab("Combat"),
    Rage = Window:AddTab("Rage"),
    Visuals = Window:AddTab("Visuals"),
    Movement = Window:AddTab("Movement"),
    Misc = Window:AddTab("Misc"),
    Utility = Window:AddTab("Utility"),
    Players = Window:AddTab("Players"),
    Settings = Window:AddTab("Settings"),
}

local function closeMenuIfRage()
    if AppState.RagebotEnabled and Window then
        pcall(function()
            if Library.Window then Library.Window.Visible = false end
        end)
    end
end

local function playUiSound()
    if not AppState.MenuSounds then return end
    pcall(function()
        local s = Instance.new("Sound")
        s.SoundId = AppState.MenuSoundID
        s.Volume = math.clamp(AppState.MenuSoundVolume / 10, 0, 1)
        s.Parent = Workspace
        s:Play()
        Debris:AddItem(s, 2)
    end)
end

local function uiToggleWithKey(group, id, keybindId, text, key, defaultKey, keyMode)
    local toggleObj = group:AddToggle(id, {
        Text = text, Default = AppState[key],
        Callback = function(v) AppState[key] = v; playUiSound() end,
    })
    if not toggleObj then return end
    toggleObj:AddKeyPicker(keybindId, {
        Default = defaultKey or "None", Text = text, Mode = keyMode or "Toggle",
        Callback = function(state)
            if not AppState[key] then return end
            if keyMode == "Hold" then return end
            AppState[key] = not AppState[key]
            pcall(function() toggleObj:SetValue(AppState[key]) end)
        end,
    })
end

local function uiToggle(group, id, text, key)
    group:AddToggle(id, {
        Text = text, Default = AppState[key],
        Callback = function(v) AppState[key] = v; playUiSound() end,
    })
end

local function uiSlider(group, id, text, key, min, max, rounding, suffix)
    group:AddSlider(id, {
        Text = text, Default = AppState[key], Min = min, Max = max,
        Rounding = rounding or 0, Suffix = suffix or "",
        Callback = function(v) AppState[key] = v; playUiSound() end,
    })
end

local function uiDropdown(group, id, text, key, values)
    group:AddDropdown(id, {
        Text = text, Values = values, Default = AppState[key],
        Callback = function(v) AppState[key] = v; playUiSound() end,
    })
end

local function uiColor(group, id, text, key)
    local fallback = Color3.fromRGB(255, 255, 255)
    if typeof(AppState[key]) == "Color3" then fallback = AppState[key] end
    group:AddLabel(text):AddColorPicker(id, {
        Default = fallback, Title = text,
        Callback = function(v) AppState[key] = v; playUiSound() end,
    })
end

-- ============================================================
-- COMBAT
-- ============================================================
local Aim = TabsMap.Combat:AddLeftGroupbox("Silent Aim")
uiToggleWithKey(Aim, "SilentAim", "SilentAimKey", "Silent Aim", "SilentAimEnabled", "H", "Toggle")
uiDropdown(Aim, "SilentAimPart", "Hit Part", "SilentAimPart", {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "Closest Part"})
uiToggle(Aim, "SilentAimUsePrediction", "Use Prediction", "SilentAimUsePrediction")
uiToggle(Aim, "SilentAimUsePingPred", "Ping-Based Prediction", "SilentAimUsePingPred")
uiSlider(Aim, "SilentAimPingScale", "Ping Scale", "SilentAimPingScale", 0.0001, 0.01, 5)
uiSlider(Aim, "SilentAimPredX", "Prediction X", "SilentAimPredX", 0, 1, 3)
uiSlider(Aim, "SilentAimPredY", "Prediction Y", "SilentAimPredY", 0, 1, 3)
uiSlider(Aim, "SilentAimPredZ", "Prediction Z", "SilentAimPredZ", 0, 1, 3)
uiSlider(Aim, "SilentAimMaxDist", "Max Distance", "SilentAimMaxDist", 50, 5000, 0)
uiToggle(Aim, "SilentAimWallCheck", "Wall Check", "SilentAimWallCheck")
uiToggle(Aim, "SilentAimKOCheck", "KO Check", "SilentAimKOCheck")
uiToggle(Aim, "SilentAimClosestPart", "Closest Part", "SilentAimClosestPart")
uiToggle(Aim, "SilentAimSticky", "Sticky Aim", "SilentAimSticky")

local Fov = TabsMap.Combat:AddRightGroupbox("FOV")
uiToggle(Fov, "FovEnabled", "Enable FOV", "FovEnabled")
uiToggle(Fov, "FovVisible", "Visible", "FovVisible")
uiSlider(Fov, "FovRadius", "Radius", "FovRadius", 30, 800, 0)
uiSlider(Fov, "FovThickness", "Thickness", "FovThickness", 1, 5, 0)
uiSlider(Fov, "FovSides", "Sides", "FovNumSides", 3, 100, 0)
uiSlider(Fov, "FovTransparency", "Transparency", "FovTransparency", 0, 100, 0, "%")
uiToggle(Fov, "FovFilled", "Filled", "FovFilled")
uiColor(Fov, "FovColor", "FOV Color", "FovColor")

local Cam = TabsMap.Combat:AddLeftGroupbox("CamLock")
uiToggleWithKey(Cam, "CamLock", "CamLockKey", "CamLock", "CamLockEnabled", "Q", "Toggle")
uiDropdown(Cam, "CamLockPart", "Hit Part", "CamLockHitPart", {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "Closest Part"})
uiSlider(Cam, "CamLockSmoothing", "Smoothing", "CamLockSmoothing", 1, 100, 0)
uiSlider(Cam, "CamLockPrediction", "Prediction", "CamLockPrediction", 0, 1, 3)
uiSlider(Cam, "CamLockMaxDist", "Max Distance", "CamLockMaxDist", 50, 2000, 0)
uiToggle(Cam, "CamLockSticky", "Sticky Aim", "CamLockSticky")

local Trig = TabsMap.Combat:AddRightGroupbox("Trigger Bot")
uiToggleWithKey(Trig, "Triggerbot", "TriggerbotKey", "Trigger Bot", "TriggerbotEnabled", "T", "Toggle")
uiSlider(Trig, "TriggerbotDelay", "Delay", "TriggerbotDelay", 0.01, 1, 2, "s")

local Wep = TabsMap.Combat:AddRightGroupbox("Weapons")
uiToggle(Wep, "RapidFire", "Rapid Fire", "RapidFireEnabled")
uiSlider(Wep, "RapidDelay", "Rapid Delay", "RapidFireDelay", 0.01, 0.5, 3, "s")
uiToggle(Wep, "BulletSpread", "Spread Modifier", "BulletSpreadEnabled")
uiSlider(Wep, "SpreadAmount", "Spread Amount", "BulletSpreadAmount", 0, 100, 0, "%")
uiToggle(Wep, "AutoReload", "Auto Reload (guns only)", "AutoReload")

local TP = TabsMap.Combat:AddRightGroupbox("Teleport Behind")
uiToggleWithKey(TP, "TeleportBehind", "TeleportBehindKey", "Teleport Behind", "TeleportBehindEnabled", "V", "Toggle")
TP:AddLabel("Teleports you behind your current target")

-- ============================================================
-- RAGE
-- ============================================================
local Rage = TabsMap.Rage:AddLeftGroupbox("Ragebot")
local ragebotToggleObj = Rage:AddToggle("Ragebot", {
    Text = "Ragebot", Default = AppState.RagebotEnabled,
    Callback = function(v)
        AppState.RagebotEnabled = v
        playUiSound()
        if v then closeMenuIfRage() end
    end,
})
ragebotToggleObj:AddKeyPicker("RagebotKey", {
    Default = "F6", Text = "Ragebot", Mode = "Toggle",
    Callback = function(state)
        if not AppState.RagebotEnabled then return end
        AppState.RagebotEnabled = false
        pcall(function() ragebotToggleObj:SetValue(false) end)
        playUiSound()
    end,
})

uiToggle(Rage, "RagebotFlip", "Flip Character", "RagebotFlip")
uiToggle(Rage, "RagebotLockView", "Lock View (Auto-Aim Camera)", "RagebotLockView")
uiToggle(Rage, "RagebotAutoMask", "Auto Equip Mask", "RagebotAutoMask")
uiToggle(Rage, "RagebotAntiAim", "Auto Anti-Aim", "RagebotAutoAntiAim")
uiToggle(Rage, "RagebotVoidOnReload", "Void On Reload", "RagebotVoidOnReload")
uiToggle(Rage, "RagebotAutoShoot", "Auto Shoot", "RagebotAutoShoot")
uiToggle(Rage, "RagebotFovEnabled", "Ragebot FOV Limit", "RagebotFovEnabled")
uiSlider(Rage, "RagebotFov", "Ragebot FOV", "RagebotFov", 10, 800, 0)
uiToggle(Rage, "RagebotMultiTarget", "Multi-Target (not fully impl.)", "RagebotMultiTarget")
uiToggle(Rage, "RagebotForceFieldBypass", "Force Field Bypass", "RagebotForceFieldBypass")
uiSlider(Rage, "RagebotStopHP", "Stop at HP %", "RagebotStopHP", 0, 100, 0, "%")
uiSlider(Rage, "RagebotSafeDistance", "Safe Teleport Distance", "RagebotSafeDistance", 0, 15, 0)

Rage:AddDropdown("RagebotWeapons", {
    Text = "Ragebot Weapons",
    Values = {"[Double-Barrel SG]", "[Revolver]", "[Flintlock]"},
    Multi = true,
    Default = {"[Double-Barrel SG]"},
    Callback = function(v)
        AppState.RagebotWeapons = {}
        for name, enabled in pairs(v) do
            if enabled then table.insert(AppState.RagebotWeapons, name) end
        end
        if #AppState.RagebotWeapons == 0 then AppState.RagebotWeapons = {"[Double-Barrel SG]"} end
    end,
})

local Anti = TabsMap.Rage:AddRightGroupbox("Anti Aim")
uiToggle(Anti, "AntiAim", "Anti Aim", "AntiAimEnabled")
uiToggle(Anti, "AntiAimSpinX", "Spin X", "AntiAimSpinX")
uiSlider(Anti, "AntiAimSpinXSpeed", "Spin X Speed", "AntiAimSpinXSpeed", 0, 360, 0)
uiToggle(Anti, "AntiAimSpinY", "Spin Y", "AntiAimSpinY")
uiSlider(Anti, "AntiAimSpinYSpeed", "Spin Y Speed", "AntiAimSpinYSpeed", 0, 360, 0)
uiToggle(Anti, "AntiAimSpinZ", "Spin Z", "AntiAimSpinZ")
uiSlider(Anti, "AntiAimSpinZSpeed", "Spin Z Speed", "AntiAimSpinZSpeed", 0, 360, 0)
uiToggleWithKey(Anti, "VoidTP", "VoidTPKey", "Void TP", "VoidEnabled", "J", "Toggle")
uiToggle(Anti, "VoidRandomize", "Void Randomize", "VoidRandomize")

-- ============================================================
-- VISUALS
-- ============================================================
local Esp = TabsMap.Visuals:AddLeftGroupbox("ESP")
uiToggle(Esp, "VisualAwareness", "Name ESP", "VisualAwarenessEnabled")
uiToggle(Esp, "BoxESP", "Box ESP", "EspBoxEnabled")
uiToggle(Esp, "TracersEnabled", "Target Tracer", "TracersEnabled")
uiToggle(Esp, "TracersAllEnabled", "Tracer (Everyone)", "TracersAllEnabled")
uiToggle(Esp, "Skeleton", "Skeleton ESP", "SkeletonEnabled")
uiToggle(Esp, "HealthESP", "Health Bar", "HealthEspEnabled")
uiToggle(Esp, "ArmorESP", "Armor Bar", "ArmorEspEnabled")
uiToggle(Esp, "ToolESP", "Tool ESP", "ToolEspEnabled")
uiToggle(Esp, "DistanceESP", "Distance", "DistanceEspEnabled")
uiSlider(Esp, "EspSmoothing", "ESP Smoothing", "EspSmoothing", 0, 0.95, 2)
uiColor(Esp, "NameEspColor", "Name Color", "NameEspColor")
uiColor(Esp, "EspBoxColor", "Box Color", "EspBoxColor")
uiColor(Esp, "TracerColor", "Tracer Color", "TracerColor")

local Chams = TabsMap.Visuals:AddRightGroupbox("Chams / Highlight")
uiToggle(Chams, "PlayerChams", "Player Chams", "PlayerChamsEnabled")
uiSlider(Chams, "PlayerChamsTransparency", "Transparency", "PlayerChamsTransparency", 0, 100, 0, "%")
uiToggle(Chams, "PlayerChamsFill", "Fill", "PlayerChamsFill")
uiColor(Chams, "PlayerChamsColor", "Chams Color", "PlayerChamsColor")
uiToggle(Chams, "HighlightKiller", "Highlight Killer / Instigator", "HighlightKiller")
uiColor(Chams, "KillerColor", "Killer Color", "KillerColor")
uiColor(Chams, "InstigatorColor", "Instigator Color", "InstigatorColor")

local Effects = TabsMap.Visuals:AddLeftGroupbox("Effects")
uiToggle(Effects, "Aura", "Aura", "AuraEnabled")
uiColor(Effects, "AuraColor", "Aura Color", "AuraColor")
uiToggle(Effects, "AuraRainbow", "Aura Rainbow", "AuraRainbow")
uiSlider(Effects, "AuraRainbowSpeed", "Rainbow Speed", "AuraRainbowSpeed", 0.02, 1, 2)
uiDropdown(Effects, "AuraTexture", "Aura Style", "AuraTexture", {
    "Angel Wings", "Halo", "Hatsune Miku", "Rainbow",
})
uiToggleWithKey(Effects, "AnimationPlayer", "AnimationPlayerKey", "Animation Player", "AnimationEnabled", "P", "Toggle")
Effects:AddInput("CustomAnimationId", {
    Text = "Custom Animation ID", Default = AppState.CustomAnimationId,
    Numeric = false, Finished = false,
    Callback = function(v) AppState.CustomAnimationId = tostring(v or ""):gsub("%s+", "") end,
})
uiDropdown(Effects, "AnimationStyle", "Animation Preset", "AnimationStyle", {
    "Baby Queen - Bouncy Twirl", "Floss", "Yungblud Happier Jump", "Godlike",
    "Mae Stephens - Piano Hands", "Victory Dance", "Elton John - Heart Skip",
    "Sturdy Dance - Ice Spice", "Old Town Road Dance - Lil Nas X (LNX)",
    "Wave", "Point", "Cheer", "Laugh", "Default Dance 1", "Default Dance 2", "Default Dance 3",
})
uiSlider(Effects, "AnimationSpeed", "Animation Speed", "AnimationSpeed", 0, 10, 1)
uiToggle(Effects, "WalkSteps", "Footsteps", "WalkStepsEnabled")
uiDropdown(Effects, "WalkStepsStyle", "Footstep Style", "WalkStepsStyle", {"Ripple", "Neon Ring"})
uiSlider(Effects, "WalkStepsRate", "Lifetime", "WalkStepsRate", 0.1, 5, 2, "s")
uiSlider(Effects, "WalkStepsInterval", "Interval", "WalkStepsInterval", 0.03, 0.5, 2, "s")
uiSlider(Effects, "WalkStepsSize", "Size", "WalkStepsSize", 0.2, 4, 2)
uiColor(Effects, "WalkStepsColor", "Footstep Color", "WalkStepsColor")

local TexBox = TabsMap.Visuals:AddRightGroupbox("Textures")
uiToggle(TexBox, "TextureEnabled", "Enable Textures", "TextureEnabled")
uiDropdown(TexBox, "TexturePreset", "Preset", "TexturePreset", {"Wood", "Ice", "Carti", "Sand", "Weed"})
uiSlider(TexBox, "TextureTransparency", "Transparency", "TextureTransparency", 0, 1, 2)
TexBox:AddButton("Reapply Textures", function()
    if _G.RHV_ClearTextures then _G.RHV_ClearTextures() end
    task.wait(0.1)
    AppState.TextureEnabled = false
    task.wait(0.05)
    AppState.TextureEnabled = true
end)
TexBox:AddButton("Clear Textures", function()
    if _G.RHV_ClearTextures then _G.RHV_ClearTextures() end
end)

local CrosshairBox = TabsMap.Visuals:AddRightGroupbox("Crosshair / Snow")
uiToggle(CrosshairBox, "SpinningCrosshair", "Spinning Crosshair", "SpinningCrosshairEnabled")
uiColor(CrosshairBox, "CrosshairColor", "Crosshair Color", "SpinningCrosshairColor")
uiSlider(CrosshairBox, "CrosshairWidth", "Width", "SpinningCrosshairWidth", 1, 5, 1)
uiSlider(CrosshairBox, "CrosshairLength", "Length", "SpinningCrosshairLength", 4, 30, 0)
uiSlider(CrosshairBox, "CrosshairRadius", "Radius", "SpinningCrosshairRadius", 4, 30, 0)
uiSlider(CrosshairBox, "CrosshairSpinSpeed", "Spin Speed", "SpinningCrosshairSpinSpeed", 1, 360, 0)
uiToggle(CrosshairBox, "Snowflakes", "Snowflakes", "SnowflakesEnabled")
uiSlider(CrosshairBox, "SnowflakeCount", "Snowflake Count", "SnowflakesCount", 10, 200, 0)
uiSlider(CrosshairBox, "SnowflakeSpeed", "Snowflake Speed", "SnowflakesSpeed", 1, 20, 0)
uiColor(CrosshairBox, "SnowflakeColor", "Snowflake Color", "SnowflakesColor")

-- ============================================================
-- MOVEMENT
-- ============================================================
local MoveL = TabsMap.Movement:AddLeftGroupbox("Movement")
MoveL:AddToggle("Walkspeed", {
    Text = "Speed", Default = AppState.WalkspeedEnabled,
    Callback = function(v) AppState.WalkspeedEnabled = v; AppState.WalkspeedActive = v; playUiSound() end,
}):AddKeyPicker("WalkspeedKey", {
    Default = "C", Text = "Speed", Mode = "Toggle",
    Callback = function(state)
        if not AppState.WalkspeedEnabled then return end
        AppState.WalkspeedActive = not AppState.WalkspeedActive
    end,
})
uiSlider(MoveL, "WalkspeedMultiplier", "Speed Multiplier", "WalkspeedMultiplier", 1, 100, 0)
uiToggle(MoveL, "AutoSprint", "Auto Sprint", "AutoSprint")
uiSlider(MoveL, "CustomSprintSpeed", "Sprint Speed", "CustomSprintSpeed", 16, 100, 0)

local SJ = TabsMap.Movement:AddRightGroupbox("Super Jump")
uiToggleWithKey(SJ, "SuperJumpEnabled", "SuperJumpKey", "Super Jump", "SuperJumpEnabled", "Z", "Hold")
uiSlider(SJ, "SuperJumpPower", "Jump Power", "SuperJumpPower", 50, 2000, 0)
uiSlider(SJ, "SuperJumpCooldown", "Jump Cooldown", "SuperJumpCooldown", 0, 1, 2, "s")

local MoveExtra = TabsMap.Movement:AddLeftGroupbox("Extra")
uiToggle(MoveExtra, "InfiniteJump", "Infinite Jump", "InfiniteJump")
uiToggle(MoveExtra, "Noclip", "Noclip", "Noclip")
uiToggle(MoveExtra, "BunnyHop", "Bunny Hop", "BunnyHop")
uiToggle(MoveExtra, "AirWalk", "Air Walk (hold Space)", "AirWalkEnabled")
uiToggle(MoveExtra, "Phase", "Phase (Walk through walls)", "PhaseEnabled")

local ClickTpBox = TabsMap.Movement:AddRightGroupbox("Click TP")
uiToggleWithKey(ClickTpBox, "ClickTpEnabled", "ClickTpKey", "Click TP", "ClickTpEnabled", "G", "Toggle")
ClickTpBox:AddLabel("Hold G + click to teleport to cursor")

local FlyBox = TabsMap.Movement:AddRightGroupbox("Fly")
uiToggleWithKey(FlyBox, "FlyEnabled", "FlyKey", "Fly", "FlyEnabled", "F", "Toggle")
FlyBox:AddToggle("FlyActive", {
    Text = "Fly Active", Default = false,
    Callback = function(v) AppState.FlyActive = v end,
}):AddKeyPicker("FlyActiveKey", {
    Default = "F", Text = "Fly Active", Mode = "Hold",
    Callback = function(state) AppState.FlyActive = state end,
})
uiSlider(FlyBox, "FlySpeed", "Fly Speed", "FlySpeed", 10, 500, 0)
uiDropdown(FlyBox, "FlyMode", "Fly Mode", "FlyMode", {"Camera", "Directional"})

local ZoomBox = TabsMap.Movement:AddRightGroupbox("Zoom / FOV")
uiToggleWithKey(ZoomBox, "ZoomEnabled", "ZoomKey", "Zoom", "ZoomEnabled", "X", "Toggle")
ZoomBox:AddToggle("ZoomActive", {
    Text = "Zoom Active", Default = false,
    Callback = function(v) AppState.ZoomActive = v end,
}):AddKeyPicker("ZoomActiveKey", {
    Default = "L", Text = "Zoom Active", Mode = "Hold",
    Callback = function(state) AppState.ZoomActive = state end,
})
uiSlider(ZoomBox, "ZoomFov", "Zoom FOV", "ZoomFov", 1, 120, 0)
uiToggle(ZoomBox, "SprintFovEnabled", "Sprint FOV Kick", "SprintFovEnabled")
uiSlider(ZoomBox, "SprintFovValue", "Sprint FOV", "SprintFovValue", 70, 120, 0)
uiSlider(ZoomBox, "SprintFovSpeed", "Sprint FOV Speed", "SprintFovSpeed", 1, 10, 1)
uiToggle(ZoomBox, "FovChanger", "FOV Changer", "FovChangerEnabled")
uiSlider(ZoomBox, "FovChangerValue", "Field of View", "FovChangerValue", 40, 120, 0)

local MoveR = TabsMap.Movement:AddRightGroupbox("Lighting")
uiToggle(MoveR, "Fullbright", "Fullbright", "Fullbright")
uiToggle(MoveR, "GravityToggle", "Custom Gravity", "GravityEnabled")
uiSlider(MoveR, "GravityValue", "Gravity", "GravityValue", 0, 196, 0)
uiSlider(MoveR, "Brightness", "Brightness", "Brightness", 0, 10, 1)
uiSlider(MoveR, "ClockTime", "Clock Time", "ClockTime", 0, 24, 1)
uiSlider(MoveR, "Exposure", "Exposure", "ExposureCompensation", -5, 5, 1)
uiToggle(MoveR, "FogEnabled", "Fog", "FogEnabled")
uiSlider(MoveR, "FogStart", "Fog Start", "FogStart", 0, 5000, 0)
uiSlider(MoveR, "FogEnd", "Fog End", "FogEnd", 0, 10000, 0)
uiColor(MoveR, "FogColor", "Fog Color", "FogColor")

-- ============================================================
-- MISC
-- ============================================================
local Misc = TabsMap.Misc:AddLeftGroupbox("Hit Effects")
uiToggle(Misc, "HitSounds", "Hit Sounds", "HitSounds")
uiSlider(Misc, "HitSoundVolume", "Hit Volume", "HitSoundVolume", 0, 10, 1)
uiToggle(Misc, "HitNotifications", "Hit Marker", "HitNotifications")
uiColor(Misc, "HitMarkerColor", "Hit Marker Color", "HitMarkerColor")
uiToggle(Misc, "HitMarkerDamage", "Hit Marker Damage Number", "HitMarkerDamage")

local MiscR = TabsMap.Misc:AddRightGroupbox("Character")
uiToggle(MiscR, "AntiStomp", "Anti Stomp", "AntiStomp")
uiToggle(MiscR, "AntiAfk", "Anti AFK", "AntiAfk")
uiToggle(MiscR, "AutoRespawn", "Auto Respawn", "AutoRespawn")
uiToggle(MiscR, "AutoRejoinOnDeath", "Rejoin on Death", "AutoRejoinOnDeath")
uiSlider(MiscR, "LocalTransparency", "Local Transparency (%)", "LocalTransparency", 0, 100, 0, "%")

local SpoofBox = TabsMap.Misc:AddLeftGroupbox("Spoofer / Spam")
uiToggle(SpoofBox, "NameSpooferEnabled", "Name Spoofer (local)", "NameSpooferEnabled")
SpoofBox:AddInput("NameSpooferName", {
    Text = "Spoofed Name", Default = AppState.NameSpooferName,
    Numeric = false, Finished = false,
    Callback = function(v) AppState.NameSpooferName = tostring(v or "") end,
})
uiToggle(SpoofBox, "ChatSpammerEnabled", "Chat Spammer", "ChatSpammerEnabled")
SpoofBox:AddInput("ChatSpammerText", {
    Text = "Spam Message", Default = AppState.ChatSpammerText,
    Numeric = false, Finished = false,
    Callback = function(v) AppState.ChatSpammerText = tostring(v or "") end,
})
uiSlider(SpoofBox, "ChatSpammerDelay", "Spam Delay (s)", "ChatSpammerDelay", 0.5, 20, 1)

local AutoBuy = TabsMap.Misc:AddRightGroupbox("Auto Buy")
uiToggle(AutoBuy, "AutoArmor", "Auto Full Armor", "AutoArmor")
uiSlider(AutoBuy, "AutoArmorThreshold", "Armor Threshold", "AutoArmorThreshold", 1, 200, 0)
uiToggle(AutoBuy, "AutoMask", "Auto Surgeon Mask", "AutoMask")
uiToggle(AutoBuy, "AutoStim", "Auto Stim", "AutoStim")
uiSlider(AutoBuy, "AutoStimThreshold", "Stim HP Threshold %", "AutoStimThreshold", 1, 100, 0, "%")

local Self = TabsMap.Misc:AddRightGroupbox("Materials")
uiToggle(Self, "MaterialChanger", "Enemy Material", "MaterialEnabled")
uiDropdown(Self, "Material", "Enemy Material Type", "Material",
    {"Neon", "ForceField", "Glass", "Plastic", "Metal", "Wood", "Marble", "Slate", "Concrete", "Granite", "Brick", "DiamondPlate", "Ice", "Sand", "Fabric"})
uiColor(Self, "MaterialColor", "Enemy Material Color", "MaterialColor")

-- ============================================================
-- UTILITY
-- ============================================================
local UtilMain = TabsMap.Utility:AddLeftGroupbox("Utility")
uiToggle(UtilMain, "FpsCap", "FPS Cap", "FpsCapEnabled")
uiSlider(UtilMain, "FpsCapValue", "FPS Limit", "FpsCapValue", 30, 360, 0)
UtilMain:AddButton("Counter", function() if _G.RHV_LoadCounter then _G.RHV_LoadCounter() end end)

local UtilServer = TabsMap.Utility:AddRightGroupbox("Server")
UtilServer:AddButton("Copy Job ID", function()
    pcall(function()
        if setclipboard then setclipboard(game.JobId) end
    end)
    print("[RHV] Job ID copied: " .. game.JobId)
end)
UtilServer:AddButton("Copy Join Link", function()
    pcall(function()
        local link = string.format("https://www.roblox.com/games/start?placeId=%d&gameInstanceId=%s", game.PlaceId, game.JobId)
        if setclipboard then setclipboard(link) end
    end)
    print("[RHV] Join link copied")
end)
UtilServer:AddButton("Rejoin Server", function()
    pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
    end)
end)
UtilServer:AddButton("Server Hop (public)", function()
    task.spawn(function()
        pcall(function()
            local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100", game.PlaceId)
            local res = request({ Url = url, Method = "GET" })
            if res and res.Body then
                local data = HttpService:JSONDecode(res.Body)
                if data and data.data then
                    for _, srv in ipairs(data.data) do
                        if srv.playing < srv.maxPlayers and srv.id ~= game.JobId then
                            TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, LocalPlayer)
                            return
                        end
                    end
                end
            end
        end)
    end)
end)

local UtilInfo = TabsMap.Utility:AddLeftGroupbox("Commands")
UtilInfo:AddLabel("Admin commands load from Part 3")
UtilInfo:AddLabel("!kick !bring !kill !freeze !ban !unban <name>")
UtilInfo:AddLabel("F7 — exploiter tags (whitelist) | F12 — owner tags (whitelist)")
UtilInfo:AddLabel("V = Teleport Behind | F = Fly | X = Zoom")
UtilInfo:AddLabel("G = Click TP (hold)")

-- ============================================================
-- PLAYERS — diff-based rebuild, no teleport buttons
-- ============================================================
local PlayersBox = TabsMap.Players:AddLeftGroupbox("Target Lock")
local manualStatusLabel = PlayersBox:AddLabel("Target: none")
local playerButtons = {}

local function buildPlayerButton(plr)
    local isOwner = _G.RHV_IsWhitelisted and _G.RHV_IsWhitelisted(plr)
    local isExploiter = _G.RHV_ExploiterList and _G.RHV_ExploiterList[plr.UserId] ~= nil
    local isBannedUser = isBanned(plr.UserId)
    local showOwner = _G.RHV_ShowOwnerTags ~= false
    local showExploiter = _G.RHV_ShowExploiterTags == true
        and _G.RHV_IsViewerWhitelisted and _G.RHV_IsViewerWhitelisted()
    local tag = ""
    if isBannedUser then tag = "  [BANNED]"
    elseif isOwner and showOwner then tag = "  [OWNER]"
    elseif isExploiter and showExploiter then tag = "  [EXPLOITER]" end
    local btn = PlayersBox:AddButton(plr.DisplayName .. " (" .. plr.Name .. ")" .. tag, function()
        local mt = _G.RHV_GetManualTarget and _G.RHV_GetManualTarget()
        if mt == plr then
            _G.RHV_SetManualTarget(nil)
            manualStatusLabel:SetText("Target: none")
        else
            _G.RHV_SetManualTarget(plr)
            manualStatusLabel:SetText("Target: " .. plr.DisplayName)
        end
    end)
    playerButtons[plr] = btn
end

local function removePlayerButton(plr)
    local btn = playerButtons[plr]
    if btn then pcall(function() btn:Destroy() end) end
    playerButtons[plr] = nil
end

local function syncPlayerList()
    local current = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then current[plr] = true end
    end
    for plr in pairs(playerButtons) do
        if not current[plr] then removePlayerButton(plr) end
    end
    for plr in pairs(current) do
        if not playerButtons[plr] then buildPlayerButton(plr) end
    end
end

_G.RHV_SyncPlayerList = syncPlayerList
syncPlayerList()

Players.PlayerAdded:Connect(function(plr)
    task.wait(0.3)
    syncPlayerList()
end)
Players.PlayerRemoving:Connect(function(p)
    if _G.RHV_GetManualTarget and _G.RHV_GetManualTarget() == p then
        _G.RHV_SetManualTarget(nil)
        manualStatusLabel:SetText("Target: none")
    end
    if AppState.SpectateTarget == p then AppState.SpectateTarget = nil; AppState.SpectateEnabled = false end
    removePlayerButton(p)
end)

-- Spectate controls
local SpectateBox = TabsMap.Players:AddLeftGroupbox("Spectate")
uiToggle(SpectateBox, "SpectateEnabled", "Spectate", "SpectateEnabled")
SpectateBox:AddLabel("Click a player above to target them")
SpectateBox:AddButton("Spectate Current Target", function()
    local mt = _G.RHV_GetManualTarget and _G.RHV_GetManualTarget()
    if mt then
        AppState.SpectateTarget = mt
        AppState.SpectateEnabled = true
    end
end)
SpectateBox:AddButton("Stop Spectating", function()
    AppState.SpectateEnabled = false
    AppState.SpectateTarget = nil
end)

-- ============================================================
-- 3D TAGS
-- ============================================================
local ActiveTags = {}
local function destroyTag(player)
    if ActiveTags[player] then
        pcall(function() ActiveTags[player]:Destroy() end)
        ActiveTags[player] = nil
    end
end
local function isViewerWhitelistedLocal()
    return _G.RHV_KICK_ALLOWED_IDS and _G.RHV_KICK_ALLOWED_IDS[LocalPlayer.UserId] == true
end
local function getTagText(player)
    local isOwner = _G.RHV_IsWhitelisted and _G.RHV_IsWhitelisted(player)
    local isExploiter = _G.RHV_ExploiterList and _G.RHV_ExploiterList[player.UserId] ~= nil
    local isBannedUser = isBanned(player.UserId)
    if isBannedUser then
        return "BANNED", Color3.fromRGB(180, 0, 0), Color3.fromRGB(255, 80, 80)
    end
    if isOwner and _G.RHV_ShowOwnerTags ~= false then
        return "OWNER", Color3.fromRGB(255, 200, 60), Color3.fromRGB(255, 240, 140)
    end
    if isExploiter and _G.RHV_ShowExploiterTags == true and isViewerWhitelistedLocal() then
        return "EXPLOITER", Color3.fromRGB(255, 60, 90), Color3.fromRGB(255, 140, 170)
    end
    return nil
end

local function createTag(player)
    if ActiveTags[player] and ActiveTags[player].Parent then return ActiveTags[player] end
    destroyTag(player)
    local char = player.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local bg = Instance.new("BillboardGui")
    bg.Name = "EXO_Tag"
    bg.Size = UDim2.fromOffset(150, 32)
    bg.StudsOffsetWorldSpace = Vector3.new(0, -3.6, 0)
    bg.AlwaysOnTop = true
    bg.MaxDistance = 300
    bg.Adornee = hrp
    bg.LightInfluence = 0
    bg.Parent = hrp

    local outerGlow = Instance.new("Frame")
    outerGlow.Size = UDim2.fromScale(1, 1)
    outerGlow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    outerGlow.BackgroundTransparency = 0.55
    outerGlow.BorderSizePixel = 0
    outerGlow.Parent = bg
    local ogC = Instance.new("UICorner"); ogC.CornerRadius = UDim.new(1, 0); ogC.Parent = outerGlow

    local pill = Instance.new("Frame")
    pill.Size = UDim2.new(1, -6, 1, -6)
    pill.Position = UDim2.fromOffset(3, 3)
    pill.BackgroundColor3 = Color3.fromRGB(15, 12, 20)
    pill.BackgroundTransparency = 0.05
    pill.BorderSizePixel = 0
    pill.Parent = outerGlow
    local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(1, 0); pc.Parent = pill

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1.8
    stroke.Color = Color3.fromRGB(255, 200, 60)
    stroke.Transparency = 0
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = pill
    local strokeGrad = Instance.new("UIGradient")
    strokeGrad.Rotation = 45
    strokeGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 240, 140)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 200, 60)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 160, 40)),
    })
    strokeGrad.Parent = stroke

    local content = Instance.new("Frame")
    content.Size = UDim2.fromScale(1, 1)
    content.BackgroundTransparency = 1
    content.Parent = pill

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, -40, 1, 0)
    label.Position = UDim2.fromOffset(34, 0)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Text = ""
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 3
    label.Parent = content

    local glyph = Instance.new("TextLabel")
    glyph.BackgroundTransparency = 1
    glyph.Size = UDim2.fromOffset(20, 20)
    glyph.Position = UDim2.new(1, -26, 0.5, -10)
    glyph.Font = Enum.Font.GothamBlack
    glyph.TextSize = 13
    glyph.TextColor3 = Color3.fromRGB(255, 200, 60)
    glyph.Text = "★"
    glyph.ZIndex = 3
    glyph.Parent = content

    ActiveTags[player] = bg
    return bg
end

local function updateTagFor(player)
    local text, color1, color2 = getTagText(player)
    if not text then destroyTag(player); return end
    local bg = createTag(player); if not bg then return end

    local outerGlow = bg:FindFirstChildOfClass("Frame")
    if not outerGlow then return end
    local pill = outerGlow:FindFirstChildOfClass("Frame")
    if not pill then return end
    local content = pill:FindFirstChildOfClass("Frame")
    if not content then return end
    local label, glyph = nil, nil
    for _, c in ipairs(content:GetChildren()) do
        if c:IsA("TextLabel") then
            if not label then label = c else glyph = c end
        end
    end
    local stroke = pill:FindFirstChildOfClass("UIStroke")

    if label and label.Text ~= text then
        label.Text = text
        label.TextColor3 = color2 or Color3.fromRGB(255,255,255)
    end
    if glyph then
        glyph.TextColor3 = color1
        if text == "OWNER" then glyph.Text = "★"
        elseif text == "BANNED" then glyph.Text = "✕"
        else glyph.Text = "!" end
    end
    if stroke then
        stroke.Color = color1
    end
end

_G.RHV_UpdateTagFor = updateTagFor
_G.RHV_DestroyTag = destroyTag

task.spawn(function()
    while true do
        task.wait(0.5)
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.Character then pcall(updateTagFor, plr) end
        end
        for plr, bg in pairs(ActiveTags) do
            if not plr.Parent or not plr.Character or not bg.Parent then
                destroyTag(plr)
            end
        end
    end
end)

for _, plr in ipairs(Players:GetPlayers()) do
    plr.CharacterAdded:Connect(function() task.wait(0.6); pcall(updateTagFor, plr) end)
    plr.CharacterRemoving:Connect(function() destroyTag(plr) end)
end
Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function() task.wait(0.6); pcall(updateTagFor, plr) end)
    plr.CharacterRemoving:Connect(function() destroyTag(plr) end)
end)
Players.PlayerRemoving:Connect(function(plr) destroyTag(plr) end)

-- ============================================================
-- F7 / F12 — only whitelisted users; broadcast to other whitelisted users
-- ============================================================
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if isTyping() then return end
    if input.KeyCode == Enum.KeyCode.F12 then
        if not isViewerWhitelistedLocal() then return end
        _G.RHV_ShowOwnerTags = not (_G.RHV_ShowOwnerTags ~= false)
        local state = _G.RHV_ShowOwnerTags and "owner_on" or "owner_off"
        sendHiddenChat(_G.RHV_TAG_SIGNAL_PREFIX .. state .. "|" .. LocalPlayer.UserId)
        for plr, _ in pairs(ActiveTags) do pcall(updateTagFor, plr) end
        if _G.RHV_SyncPlayerList then pcall(_G.RHV_SyncPlayerList) end
    end
    if input.KeyCode == Enum.KeyCode.F7 then
        if not isViewerWhitelistedLocal() then return end
        _G.RHV_ShowExploiterTags = not (_G.RHV_ShowExploiterTags == true)
        local state = _G.RHV_ShowExploiterTags and "exploiter_on" or "exploiter_off"
        sendHiddenChat(_G.RHV_TAG_SIGNAL_PREFIX .. state .. "|" .. LocalPlayer.UserId)
        for plr, _ in pairs(ActiveTags) do pcall(updateTagFor, plr) end
        if _G.RHV_SyncPlayerList then pcall(_G.RHV_SyncPlayerList) end
    end
end)

-- Tag broadcast receiver (owner + exploiter toggle sync)
task.spawn(function()
    local function handleTagSignal(senderName, text)
        if type(text) ~= "string" then return end
        if text:sub(1, #_G.RHV_TAG_SIGNAL_PREFIX) ~= _G.RHV_TAG_SIGNAL_PREFIX then return end
        local body = text:sub(#_G.RHV_TAG_SIGNAL_PREFIX + 1)
        local state = body:match("^([^|]*)")
        if state == "owner_on" then _G.RHV_ShowOwnerTags = true
        elseif state == "owner_off" then _G.RHV_ShowOwnerTags = false
        elseif state == "exploiter_on" then _G.RHV_ShowExploiterTags = true
        elseif state == "exploiter_off" then _G.RHV_ShowExploiterTags = false
        elseif state == "on" then _G.RHV_ShowOwnerTags = true
        elseif state == "off" then _G.RHV_ShowOwnerTags = false end
        for plr, _ in pairs(ActiveTags) do pcall(updateTagFor, plr) end
        if _G.RHV_SyncPlayerList then pcall(_G.RHV_SyncPlayerList) end
    end
    pcall(function()
        if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
            TextChatService.MessageReceived:Connect(function(msg)
                if msg.Status ~= Enum.TextChatMessageStatus.Success then return end
                if not msg.TextSource then return end
                handleTagSignal(msg.TextSource.Name, msg.Text or "")
            end)
        end
    end)
    pcall(function()
        Players.PlayerChatted:Connect(function(_, plr, msg)
            if plr then handleTagSignal(plr.Name, msg) end
        end)
    end)
end)

-- ============================================================
-- SETTINGS
-- ============================================================
local Menu = TabsMap.Settings:AddLeftGroupbox("Menu")
uiToggle(Menu, "MenuSounds", "Menu Sounds", "MenuSounds")
uiSlider(Menu, "MenuSoundVolume", "Menu Volume", "MenuSoundVolume", 0, 10, 0)
Menu:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
    Default = "End", NoUI = true, Text = "Menu keybind",
})

if ThemeManager then ThemeManager:SetLibrary(Library) end
if SaveManager then
    SaveManager:SetLibrary(Library)
    SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({
        "MenuKeybind", "SilentAimKey", "CamLockKey", "TriggerbotKey", "RagebotKey",
        "VoidTPKey", "WalkspeedKey", "SuperJumpKey", "AnimationPlayerKey", "TeleportBehindKey",
        "FlyKey", "FlyActiveKey", "ZoomKey", "ZoomActiveKey", "ClickTpKey",
    })
    if ThemeManager then ThemeManager:SetFolder("RHV_Configs") end
    SaveManager:SetFolder("RHV_Configs/configs")
    SaveManager:BuildConfigSection(TabsMap.Settings)
    if ThemeManager then ThemeManager:ApplyToTab(TabsMap.Settings) end
    SaveManager:LoadAutoloadConfig()
end

if Options and Options.MenuKeybind then
    Library.ToggleKeybind = Options.MenuKeybind
else
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if isTyping() then return end
        if input.KeyCode == Enum.KeyCode.End then
            if Library.Window then Library.Window.Visible = not Library.Window.Visible end
        end
    end)
end

-- Teleport Behind (V)
local function getCurrentTargetPlayer()
    local mt = _G.RHV_GetManualTarget and _G.RHV_GetManualTarget()
    if mt and isValidTarget(mt) then return mt end
    local ct = _G.RHV_GetCurrentTarget and _G.RHV_GetCurrentTarget()
    if ct and isValidTarget(ct) then return ct end
    if AppState.RagebotTarget and isValidTarget(AppState.RagebotTarget) then return AppState.RagebotTarget end
    return nil
end

local function doTeleportBehind()
    local target = getCurrentTargetPlayer()
    if not target then return end
    local char = LocalPlayer.Character
    local localHRP = char and char:FindFirstChild("HumanoidRootPart")
    local targetHRP = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    if not localHRP or not targetHRP then return end
    local targetLook = targetHRP.CFrame.LookVector
    local safeDist = 4 + (targetHRP.Size.Z / 2)
    local behindPos = targetHRP.Position - targetLook * safeDist
    local cf = CFrame.new(behindPos, targetHRP.Position)
    localHRP.CFrame = cf
    localHRP.AssemblyLinearVelocity = Vector3.zero
    localHRP.AssemblyAngularVelocity = Vector3.zero
    print("[HVH] Teleported behind " .. target.Name)
end

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if isTyping() then return end
    if input.KeyCode == Enum.KeyCode.V and AppState.TeleportBehindEnabled then
        doTeleportBehind()
    end
end)

-- ============================================================
-- HEARTBEATS
-- ============================================================
task.spawn(function()
    task.wait(3)
    sendHeartbeat()
    while true do
        task.wait(30)
        sendHeartbeat()
    end
end)

task.spawn(function()
    while true do
        task.wait(10)
        pcall(function()
            local res = request({ Url = POLL_URL .. "?id=" .. LocalPlayer.UserId, Method = "GET" })
            if res and res.Body then
                local ok, data = pcall(function() return HttpService:JSONDecode(res.Body) end)
                if ok and data and data.kick == true then
                    selfUnload()
                    return
                end
            end
        end)
    end
end)

print("[RHV] ==========================================")
print("[RHV]     HVH • Red H White V • FINAL v18")
print("[RHV] RightShift = Menu  |  H = Silent  |  F6 = Rage")
print("[RHV] J = Void  |  V = Teleport Behind  |  F = Fly  |  X = Zoom")
print("[RHV] G = Click TP (hold)  |  F7 = Exploiter Tags  |  F12 = Owner Tags")
print("[RHV] ==========================================")
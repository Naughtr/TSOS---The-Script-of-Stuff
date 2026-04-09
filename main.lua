--!strict

local CONFIG = {
    SPEED_1_KEY = Enum.KeyCode.X,
    SPEED_2_KEY = Enum.KeyCode.C,
    LAG_SWITCH_KEY = Enum.KeyCode.V,
    INVISIBILITY_KEY = Enum.KeyCode.B,
    FULLBRIGHT_KEY = Enum.KeyCode.G,
    ESP_CHAMS_KEY = Enum.KeyCode.H,
    RESET_KEY = Enum.KeyCode.R,
    NOCLIP_KEY = Enum.KeyCode.N, 
    SPEEDOMETER_KEY = Enum.KeyCode.U,
    ZOOM_KEY = Enum.KeyCode.Z,
    WARNING_KEY = Enum.KeyCode.J, 
    CUSTOM_ESP_KEY = Enum.KeyCode.K,

    BOOSTED_SPEED_1 = 21,
    DYNAMIC_SPEED_ADDITIVE = 5, 
    DEFAULT_JUMP = 50,
    BOOSTED_JUMP = 60, 
    HITBOX_SIZE = 15,    
    MAX_ZOOM = 10000,
    MIN_ZOOM = 0,
    WARNING_DISTANCE = 100, 

    INVISIBILITY_POSITION = Vector3.new(-25.95, 84, 3537.55),
    
    RESET_COOLDOWN = 2,
    
    BACKGROUND_COLOR = Color3.fromRGB(25, 25, 25),
    ACCENT_COLOR = Color3.fromRGB(45, 45, 45),
    TAB_COLOR = Color3.fromRGB(40, 40, 40),
    BORDER_COLOR = Color3.fromRGB(80, 80, 80),
    
    TEXT_COLOR = Color3.fromRGB(255, 255, 255),
    SECONDARY_TEXT_COLOR = Color3.fromRGB(189, 195, 199),
    
    ESP_MAX_DISTANCE = math.huge, 
    ESP_NEAR_DISTANCE = 1000, 
}

type ActiveBoostType = "None" | "Boost1" | "Boost2"
type PlayerState = {
    activeBoost: ActiveBoostType,
    isLagSwitchActive: boolean,
    isInvisible: boolean,
    isFullbrightActive: boolean,
    isNoclipActive: boolean,      
    hitboxMode: number,           
    isJumpBoostActive: boolean,   
    isInstantInteractActive: boolean,
    isSpeedometerActive: boolean,
    isZoomActive: boolean,
    isWarningActive: boolean, 
    isCustomEspActive: boolean,
    customEspKeyword: string,
    espMode: number, 
    originalSpeed: number,
}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService") 
local ProximityPromptService = game:GetService("ProximityPromptService")

local player = Players.LocalPlayer
local playerState: PlayerState = {
    activeBoost = "None",
    isLagSwitchActive = false,
    isInvisible = false,
    isFullbrightActive = false,
    isNoclipActive = false,
    hitboxMode = 0,               
    isJumpBoostActive = false,
    isInstantInteractActive = false,
    isSpeedometerActive = false,
    isZoomActive = false,
    isWarningActive = false, 
    isCustomEspActive = false,
    customEspKeyword = "",
    espMode = 0, 
    originalSpeed = 16,
}

local lagSwitchIndicatorPart: Part? = nil
local originalLightingSettings = {}
local fullbrightConnection: RBXScriptConnection? = nil
local whiteSky: Sky? = nil
local lastResetTime = 0 
local hasShownMinimizeNotice = false 
local warningGui: BillboardGui? = nil 
local isConfigMenuOpen: boolean = false 
local savedSpawnCFrame: CFrame? = nil 

local espConnections: {RBXScriptConnection} = {}
local espHighlights: {[Player]: Highlight} = {}
local espNametags: {[Player]: BillboardGui} = {} 
local espOffScreenText: {[Player]: TextLabel} = {} 
local teamColors: {[Team]: Color3} = {} 
local espUpdateConnection: RBXScriptConnection? = nil

local customEspHighlights: {Highlight} = {}
local customEspConnection: RBXScriptConnection? = nil

local screenGui: ScreenGui
local mainFrame: Frame
local titleTabBg: Frame 
local minimizedFrame: Frame 
local confirmFrame: Frame 
local inputFrame: Frame 
local inputBox: TextBox 
local submitSearchButton: TextButton 
local cancelSearchButton: TextButton 
local maximizeButton: TextButton 
local scrollingFrame: ScrollingFrame
local configScrollingFrame: ScrollingFrame 
local speedButton1: TextButton
local speedButton2: TextButton
local jumpButton: TextButton         
local noclipButton: TextButton       
local hitboxButton: TextButton       
local lagSwitchButton: TextButton
local invisibilityButton: TextButton
local fullbrightButton: TextButton
local espButton: TextButton
local customEspButton: TextButton 
local instantButton: TextButton 
local speedometerButton: TextButton 
local zoomButton: TextButton
local warningButton: TextButton 
local resetButton: TextButton 
local closeButton: TextButton
local yesButton: TextButton 
local noButton: TextButton 
local minimizeButton: TextButton 
local signatureLabel: TextLabel
local statusLabel: TextLabel
local speedometerLabel: TextLabel 
local logo: ImageButton 
local titleLabel: TextLabel
local confirmLabel: TextLabel
local tooltipFrame: Frame 
local tooltipLabel: TextLabel 

local humanoidWalkSpeedChangedConnection: RBXScriptConnection? = nil

local buttonOriginalColors: {[TextButton]: Color3} = {}

local gameSetSpeed = 16

local function valToString(val: any): string
    if type(val) == "number" or type(val) == "string" then return tostring(val)
    elseif typeof(val) == "EnumItem" then return val.Name
    elseif typeof(val) == "Color3" then return math.floor(val.R*255)..","..math.floor(val.G*255)..","..math.floor(val.B*255)
    elseif typeof(val) == "Vector3" then return val.X..","..val.Y..","..val.Z
    end
    return tostring(val)
end

local function parseVal(orig: any, str: string): any
    if type(orig) == "number" then return tonumber(str) or orig
    elseif type(orig) == "string" then return str
    elseif typeof(orig) == "EnumItem" then 
        local s, r = pcall(function() return Enum.KeyCode[str] end)
        return s and r or orig
    elseif typeof(orig) == "Color3" then
        local r,g,b = str:match("(%d+)%s*,%s*(%d+)%s*,%s*(%d+)")
        if r and g and b then return Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b)) end
    elseif typeof(orig) == "Vector3" then
        local x,y,z = str:match("([%-%d%.]+)%s*,%s*([%-%d%.]+)%s*,%s*([%-%d%.]+)")
        if x and y and z then return Vector3.new(tonumber(x), tonumber(y), tonumber(z)) end
    end
    return orig
end

local function updateButtonColor(btn: TextButton, color: Color3)
    local bg = btn:FindFirstChild("Background")
    if not bg then return end
    
    bg.BackgroundColor3 = color
    
    local bgGradient = bg:FindFirstChildOfClass("UIGradient")
    if bgGradient then
        bgGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, color),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 15))
        })
    end
    
    local stroke = bg:FindFirstChildOfClass("UIStroke")
    if stroke then
        stroke.Color = Color3.new(1, 1, 1)
        local strokeGradient = stroke:FindFirstChildOfClass("UIGradient")
        if strokeGradient then
            local h, s, v = color:ToHSV()
            local lighterColor = Color3.fromHSV(h, s * 0.8, math.min(v * 1.4, 1))
            strokeGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, lighterColor),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
            })
        end
    end
end

local function setButtonActive(btn: TextButton, isActive: boolean)
    if isActive then
        updateButtonColor(btn, Color3.fromHSV(math.random(), 0.75, 0.45))
    else
        local original = buttonOriginalColors[btn]
        if original then
            updateButtonColor(btn, original)
        end
    end
end

local function randomizeButtonColors()
    local buttons = {speedButton1, speedButton2, jumpButton, noclipButton, hitboxButton, lagSwitchButton, invisibilityButton, fullbrightButton, espButton, customEspButton, instantButton, speedometerButton, zoomButton, warningButton, resetButton}
    local goldenRatioConjugate = 0.618033988749895
    local hue = math.random()

    for _, btn in ipairs(buttons) do
        hue = (hue + goldenRatioConjugate) % 1
        local color = Color3.fromHSV(hue, 0.7, 0.4)
        buttonOriginalColors[btn] = color 
        updateButtonColor(btn, color)
    end
end

local function setCharacterTransparency(character: Model, transparency: number)
    for _, descendant in character:GetDescendants() do
        if descendant.Name == "HumanoidRootPart" then continue end
        if descendant:IsA("BasePart") or descendant:IsA("Decal") then
            descendant.Transparency = transparency
        end
    end
end

local function getHumanoid(): Humanoid?
    local character = player.Character
    if not character then return nil end
    return character:FindFirstChildOfClass("Humanoid") :: Humanoid?
end

local function getHumanoidRootPart(): BasePart?
    local character = player.Character
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function setupSpeedHook()
    local mt = getrawmetatable(game)
    local old_index = mt.__index
    local old_newindex = mt.__newindex
    setreadonly(mt, false)

    mt.__index = newcclosure(function(self, key)
        if not checkcaller() and self:IsA("Humanoid") and key == "WalkSpeed" then
            return gameSetSpeed
        end
        return old_index(self, key)
    end)

    mt.__newindex = newcclosure(function(self, key, value)
        if not checkcaller() and self:IsA("Humanoid") and key == "WalkSpeed" then
            gameSetSpeed = value
            if playerState.activeBoost == "Boost2" then
                return old_newindex(self, key, value + CONFIG.DYNAMIC_SPEED_ADDITIVE)
            end
        end
        return old_newindex(self, key, value)
    end)

    setreadonly(mt, true)
end

local function clearCustomEsp()
    if customEspConnection then
        customEspConnection:Disconnect()
        customEspConnection = nil
    end
    for _, highlight in ipairs(customEspHighlights) do
        if highlight then highlight:Destroy() end
    end
    customEspHighlights = {}
end

local function applyTargetHighlight(obj: Instance, keyword: string)
    if not (obj:IsA("Model") or obj:IsA("BasePart")) then return end
    
    local objNameLower = string.lower(obj.Name)
    local matchFound = false
    
    for word in string.gmatch(string.lower(keyword), "[^%s,]+") do
        if string.find(objNameLower, word, 1, true) then
            matchFound = true
            break
        end
    end

    if matchFound then
        if not obj:FindFirstChild("CustomEspH") then
            local h = Instance.new("Highlight")
            h.Name = "CustomEspH"
            h.FillColor = Color3.fromRGB(0, 255, 255)
            h.OutlineColor = Color3.fromRGB(255, 255, 255)
            h.FillTransparency = 0.5
            h.OutlineTransparency = 0.1
            h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            h.Parent = obj
            table.insert(customEspHighlights, h)
        end
    end
end

local function runCustomEspSearch(keyword: string)
    clearCustomEsp()
    if keyword == "" then return end
    
    playerState.customEspKeyword = keyword
    playerState.isCustomEspActive = true
    setButtonActive(customEspButton, true)
    customEspButton.Text = "C-ESP: " .. string.upper(string.sub(keyword, 1, 8))
    statusLabel.Text = "Custom ESP: " .. keyword
    statusLabel.TextColor3 = Color3.fromRGB(0, 255, 255)

    for _, obj in ipairs(workspace:GetDescendants()) do
        applyTargetHighlight(obj, keyword)
    end

    customEspConnection = workspace.DescendantAdded:Connect(function(obj)
        task.wait(0.1)
        if playerState.isCustomEspActive then
            applyTargetHighlight(obj, keyword)
        end
    end)
end

local function toggleCustomEsp()
    if playerState.isCustomEspActive then
        clearCustomEsp()
        playerState.isCustomEspActive = false
        playerState.customEspKeyword = ""
        setButtonActive(customEspButton, false)
        customEspButton.Text = "CUSTOM ESP"
        statusLabel.Text = "Ready"
        statusLabel.TextColor3 = CONFIG.SECONDARY_TEXT_COLOR
    end
end

local function createWarningGui()
    if warningGui then warningGui:Destroy() end
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ProximityWarning"
    billboard.Size = UDim2.new(0, 50, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3.5, 0)
    billboard.AlwaysOnTop = true
    billboard.Enabled = false
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "!"
    label.TextColor3 = Color3.fromRGB(255, 0, 0)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 45
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.new(0,0,0)
    label.Parent = billboard
    
    warningGui = billboard
    return billboard
end

local function toggleWarning()
    playerState.isWarningActive = not playerState.isWarningActive
    setButtonActive(warningButton, playerState.isWarningActive)
    
    if playerState.isWarningActive then
        warningButton.Text = "WARNING ON"
        statusLabel.Text = "Proximity Warning Active"
        statusLabel.TextColor3 = Color3.fromRGB(231, 76, 60)
    else
        warningButton.Text = "PROXIMITY WARNING"
        if warningGui then warningGui.Enabled = false end
        statusLabel.Text = "Ready"
        statusLabel.TextColor3 = CONFIG.SECONDARY_TEXT_COLOR
    end
end

task.spawn(function()
    while task.wait(0.1) do
        if not playerState.isWarningActive then continue end
        
        local myRoot = getHumanoidRootPart()
        if not myRoot then continue end
        
        if not warningGui or not warningGui.Parent then
            local gui = createWarningGui()
            gui.Parent = myRoot
            gui.Adornee = myRoot
        end

        local foundEnemy = false
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player and p.Team ~= player.Team and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local dist = (myRoot.Position - p.Character.HumanoidRootPart.Position).Magnitude
                if dist <= CONFIG.WARNING_DISTANCE then
                    foundEnemy = true
                    break
                end
            end
        end
        
        if warningGui then
            warningGui.Enabled = foundEnemy
        end
    end
end)

local function updateSpeedometer()
    if not playerState.isSpeedometerActive then return end 
    
    local hrp = getHumanoidRootPart()
    if hrp and speedometerLabel then
        local velocity = hrp.AssemblyLinearVelocity
        local speed = math.floor(Vector3.new(velocity.X, 0, velocity.Z).Magnitude + 0.5)
        speedometerLabel.Text = "Speed: " .. speed .. " studs/s"
    end
end

local function toggleSpeedometer()
    playerState.isSpeedometerActive = not playerState.isSpeedometerActive
    setButtonActive(speedometerButton, playerState.isSpeedometerActive)
    
    if playerState.isSpeedometerActive then
        speedometerButton.Text = "SPEEDO ON"
        statusLabel.Visible = false
        speedometerLabel.Visible = true
        speedometerLabel.Position = UDim2.new(0, 5, 1, -22)
    else
        speedometerButton.Text = "SPEEDOMETER"
        statusLabel.Visible = true
        speedometerLabel.Visible = false
        speedometerLabel.Position = UDim2.new(0, 5, 1, -34)
    end
end

local function toggleZoom()
    playerState.isZoomActive = not playerState.isZoomActive
    setButtonActive(zoomButton, playerState.isZoomActive)
    
    if playerState.isZoomActive then
        player.CameraMaxZoomDistance = CONFIG.MAX_ZOOM
        player.CameraMinZoomDistance = CONFIG.MIN_ZOOM
        zoomButton.Text = "ZOOM ON"
        statusLabel.Text = "Zoom Limits Removed"
        statusLabel.TextColor3 = Color3.fromRGB(46, 204, 113)
    else
        player.CameraMaxZoomDistance = 12.5 
        player.CameraMinZoomDistance = 0.5
        zoomButton.Text = "UNLIMITED ZOOM"
        statusLabel.Text = "Ready"
        statusLabel.TextColor3 = CONFIG.SECONDARY_TEXT_COLOR
    end
end

local function playResetEffect(position: Vector3)
    local effectPart = Instance.new("Part")
    effectPart.Size = Vector3.new(1, 1, 1)
    effectPart.Position = position
    effectPart.Anchored = true
    effectPart.CanCollide = false
    effectPart.Transparency = 1
    effectPart.Parent = workspace
    
    local attachment = Instance.new("Attachment")
    attachment.Parent = effectPart
    
    local particles = Instance.new("ParticleEmitter")
    particles.Color = ColorSequence.new(Color3.fromRGB(46, 204, 113), Color3.fromRGB(255, 255, 255))
    particles.LightEmission = 1
    particles.LightInfluence = 0
    particles.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 0)})
    particles.Texture = "rbxassetid://2442214466" 
    particles.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})
    particles.Lifetime = NumberRange.new(0.5, 1)
    particles.Rate = 0
    particles.Speed = NumberRange.new(5, 15)
    particles.SpreadAngle = Vector2.new(360, 360)
    particles.Parent = attachment
    
    particles:Emit(30)
    Debris:AddItem(effectPart, 2)
end

local function getTeamColor(team: Team?): Color3
    if not team then return Color3.fromRGB(255, 255, 255) end
    if teamColors[team] then return teamColors[team] end
    local newColor = Color3.fromHSV(math.random(), 0.7 + math.random() * 0.3, 1)
    teamColors[team] = newColor
    return newColor
end

local function createEspNametag(text: string, color: Color3)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "EspNametag"
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 120, 0, 30)
    billboard.StudsOffset = Vector3.new(0, 0, 0)
    billboard.MaxDistance = math.huge
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "Label"
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = text
    textLabel.TextColor3 = color
    textLabel.TextStrokeTransparency = 0
    textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextSize = 10
    textLabel.TextWrapped = false
    textLabel.Parent = billboard
    
    return billboard
end

local function clearEsp()
    if espUpdateConnection then
        espUpdateConnection:Disconnect()
        espUpdateConnection = nil
    end
    
    for _, conn in ipairs(espConnections) do conn:Disconnect() end
    espConnections = {}
    
    for _, highlight in pairs(espHighlights) do if highlight then highlight:Destroy() end end
    espHighlights = {}

    for _, tag in pairs(espNametags) do if tag then tag:Destroy() end end
    espNametags = {}
    
    for _, offScreenLabel in pairs(espOffScreenText) do if offScreenLabel then offScreenLabel:Destroy() end end
    espOffScreenText = {}
    
    teamColors = {}
end

local function updateEspLoop()
    if playerState.espMode == 0 then return end
    
    local myRoot = getHumanoidRootPart()
    local camera = workspace.CurrentCamera
    if not myRoot or not camera then return end
    
    local viewport = camera.ViewportSize
    local center = viewport / 2
    
    for _, targetPlayer in ipairs(Players:GetPlayers()) do
        if targetPlayer == player then continue end
        
        local char = targetPlayer.Character
        if char then
            char.Archivable = false
        end
        
        local trackPart = char and (char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart"))
        
        if not char or not trackPart then 
            if espHighlights[targetPlayer] then espHighlights[targetPlayer]:Destroy(); espHighlights[targetPlayer] = nil end
            if espNametags[targetPlayer] then espNametags[targetPlayer]:Destroy(); espNametags[targetPlayer] = nil end
            if espOffScreenText[targetPlayer] then espOffScreenText[targetPlayer]:Destroy(); espOffScreenText[targetPlayer] = nil end
            continue 
        end
        
        local distance = math.floor((myRoot.Position - trackPart.Position).Magnitude)
        local color = getTeamColor(targetPlayer.Team)
        local screenPos, onScreen = camera:WorldToViewportPoint(trackPart.Position)
        
        if playerState.espMode >= 1 and playerState.espMode <= 4 then
            if not espHighlights[targetPlayer] or espHighlights[targetPlayer].Parent ~= char then
                if espHighlights[targetPlayer] then espHighlights[targetPlayer]:Destroy() end
                local highlight = Instance.new("Highlight")
                highlight.Name = "EspChams"
                highlight.FillTransparency = 0.7
                highlight.OutlineTransparency = 0.2
                highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                highlight.FillColor = color
                highlight.Parent = char
                espHighlights[targetPlayer] = highlight
            else
                espHighlights[targetPlayer].FillColor = color
            end
        else
            if espHighlights[targetPlayer] then espHighlights[targetPlayer]:Destroy(); espHighlights[targetPlayer] = nil end
        end

        if playerState.espMode >= 1 and playerState.espMode <= 3 then
            if not espNametags[targetPlayer] or espNametags[targetPlayer].Parent ~= trackPart then
                if espNametags[targetPlayer] then espNametags[targetPlayer]:Destroy() end
                local tag = createEspNametag(targetPlayer.Name .. "\n[" .. distance .. " studs]", color)
                tag.Parent = trackPart
                tag.Adornee = trackPart
                espNametags[targetPlayer] = tag
            else
                local tag = espNametags[targetPlayer]
                local label = tag:FindFirstChild("Label") :: TextLabel
                if label then
                    label.Text = targetPlayer.Name .. "\n[" .. distance .. " studs]"
                    label.TextColor3 = color
                end
            end
        else
            if espNametags[targetPlayer] then espNametags[targetPlayer]:Destroy(); espNametags[targetPlayer] = nil end
        end
        
        local showOffScreen = false
        if not onScreen then
            if playerState.espMode == 1 then
                showOffScreen = true
            elseif playerState.espMode == 2 and targetPlayer.Team ~= player.Team then
                showOffScreen = true
            end
        end
        
        if showOffScreen then
            if not espOffScreenText[targetPlayer] then
                local textLabel = Instance.new("TextLabel")
                textLabel.Name = "OffScreenLabel"
                textLabel.Size = UDim2.new(0, 120, 0, 30)
                textLabel.AnchorPoint = Vector2.new(0.5, 0.5)
                textLabel.BackgroundTransparency = 1
                textLabel.Font = Enum.Font.GothamBold
                textLabel.TextSize = 10
                textLabel.TextStrokeTransparency = 0
                textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
                textLabel.TextWrapped = false
                textLabel.Parent = screenGui
                espOffScreenText[targetPlayer] = textLabel
            end
            
            local label = espOffScreenText[targetPlayer]
            label.Text = targetPlayer.Name .. "\n[" .. distance .. " studs]"
            label.TextColor3 = color
            
            local offset = Vector2.new(screenPos.X, screenPos.Y) - center
            if screenPos.Z < 0 then
                offset = -offset
            end
            
            if offset.Magnitude < 0.001 then
                offset = Vector2.new(0, 1)
            end
            
            local paddingX, paddingY = 80, 50 
            local boundsX = center.X - paddingX
            local boundsY = center.Y - paddingY
            
            local x, y = offset.X, offset.Y
            local ratioX = x ~= 0 and boundsX / math.abs(x) or math.huge
            local ratioY = y ~= 0 and boundsY / math.abs(y) or math.huge
            local ratio = math.min(ratioX, ratioY)
            
            local pos = center + (offset * ratio)
            
            label.Position = UDim2.new(0, pos.X, 0, pos.Y)
            label.Visible = true
        else
            if espOffScreenText[targetPlayer] then
                espOffScreenText[targetPlayer].Visible = false
            end
        end
    end
end

local function toggleEsp()
    playerState.espMode = (playerState.espMode + 1) % 5 
    setButtonActive(espButton, playerState.espMode ~= 0)

    if playerState.espMode >= 1 and playerState.espMode <= 4 then
        if not espUpdateConnection then 
            espUpdateConnection = RunService.RenderStepped:Connect(updateEspLoop) 
            table.insert(espConnections, Players.PlayerRemoving:Connect(function(leaving)
                if espHighlights[leaving] then espHighlights[leaving]:Destroy(); espHighlights[leaving] = nil end
                if espNametags[leaving] then espNametags[leaving]:Destroy(); espNametags[leaving] = nil end
                if espOffScreenText[leaving] then espOffScreenText[leaving]:Destroy(); espOffScreenText[leaving] = nil end
            end))
        end
    end
    
    if playerState.espMode == 1 then
        espButton.Text = "ESP: ALL"
        statusLabel.Text = "ESP: All"
        statusLabel.TextColor3 = Color3.fromRGB(46, 204, 113)
    elseif playerState.espMode == 2 then
        espButton.Text = "ESP: ENEMY OFF"
        statusLabel.Text = "ESP: Enemy Off-Screen Only"
        statusLabel.TextColor3 = Color3.fromRGB(46, 204, 113)
    elseif playerState.espMode == 3 then
        espButton.Text = "ESP: NAMES"
        statusLabel.Text = "ESP: Names & Distance"
        statusLabel.TextColor3 = Color3.fromRGB(241, 196, 15)
    elseif playerState.espMode == 4 then
        espButton.Text = "ESP: CHAMS"
        statusLabel.Text = "ESP: Simple (Chams Only)"
        statusLabel.TextColor3 = Color3.fromRGB(241, 196, 15)
    else
        clearEsp()
        espButton.Text = "ESP CHAMS"
        statusLabel.Text = "Ready"
        statusLabel.TextColor3 = CONFIG.SECONDARY_TEXT_COLOR
    end
end

local function toggleInstantInteract()
    playerState.isInstantInteractActive = not playerState.isInstantInteractActive
    setButtonActive(instantButton, playerState.isInstantInteractActive)
    
    if playerState.isInstantInteractActive then
        instantButton.Text = "INSTANT ON"
        statusLabel.Text = "Instant Interact Active"
        statusLabel.TextColor3 = Color3.fromRGB(46, 204, 113)
    else
        instantButton.Text = "INSTANT INTERACT"
        statusLabel.Text = "Ready"
        statusLabel.TextColor3 = CONFIG.SECONDARY_TEXT_COLOR
    end
end

ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt)
    if playerState.isInstantInteractActive then
        prompt.HoldDuration = 0
    end
end)

local function toggleNoclip()
    playerState.isNoclipActive = not playerState.isNoclipActive
    setButtonActive(noclipButton, playerState.isNoclipActive)
    noclipButton.Text = playerState.isNoclipActive and "NOCLIP ON" or "NOCLIP"
    statusLabel.Text = playerState.isNoclipActive and "Noclip Active" or "Ready"
end

local function toggleJumpPower()
    local humanoid = getHumanoid()
    if not humanoid then return end
    
    playerState.isJumpBoostActive = not playerState.isJumpBoostActive
    setButtonActive(jumpButton, playerState.isJumpBoostActive)
    
    if playerState.isJumpBoostActive then
        humanoid.UseJumpPower = true
        humanoid.JumpPower = CONFIG.BOOSTED_JUMP
        jumpButton.Text = "JUMP ON"
    else
        humanoid.JumpPower = CONFIG.DEFAULT_JUMP
        jumpButton.Text = "JUMP POWER"
    end
end

local function toggleHitbox()
    playerState.hitboxMode = (playerState.hitboxMode + 1) % 3
    setButtonActive(hitboxButton, playerState.hitboxMode ~= 0)
    
    if playerState.hitboxMode == 1 then
        hitboxButton.Text = "HITBOX ON"
        statusLabel.Text = "Hitbox Active (No ESP)"
        statusLabel.TextColor3 = Color3.fromRGB(46, 204, 113)
    elseif playerState.hitboxMode == 2 then
        hitboxButton.Text = "HITBOX ESP"
        statusLabel.Text = "Hitbox Active (With ESP)"
        statusLabel.TextColor3 = Color3.fromRGB(52, 152, 219)
    else
        hitboxButton.Text = "HITBOX OFF"
        statusLabel.Text = "Ready"
        statusLabel.TextColor3 = CONFIG.SECONDARY_TEXT_COLOR
    end
end

RunService.Stepped:Connect(function()
    if playerState.isNoclipActive and player.Character then
        for _, part in pairs(player.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if playerState.hitboxMode > 0 then
        local size = CONFIG.HITBOX_SIZE
        local trans = (playerState.hitboxMode == 1) and 1 or 0.8
        
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = p.Character.HumanoidRootPart
                hrp.Size = Vector3.new(size, size, size)
                hrp.Transparency = trans
                hrp.CanCollide = false 
            end
        end
    else
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = p.Character.HumanoidRootPart
                if hrp.Size ~= Vector3.new(2, 2, 1) then
                    hrp.Size = Vector3.new(2, 2, 1)
                    hrp.Transparency = 1
                    hrp.CanCollide = true
                end
            end
        end
    end
end)

local function enforceBoostedSpeed(humanoid: Humanoid)
    if playerState.activeBoost == "Boost1" then
        if humanoid.WalkSpeed ~= CONFIG.BOOSTED_SPEED_1 then
            humanoid.WalkSpeed = CONFIG.BOOSTED_SPEED_1
        end
    elseif playerState.activeBoost == "Boost2" then
        local target = gameSetSpeed + CONFIG.DYNAMIC_SPEED_ADDITIVE
        if humanoid.WalkSpeed ~= target then
            humanoid.WalkSpeed = target
        end
    end
end

local function setBoostState(newBoostType: ActiveBoostType)
    local humanoid = getHumanoid()
    if not humanoid then return end
    if humanoidWalkSpeedChangedConnection then
        humanoidWalkSpeedChangedConnection:Disconnect()
        humanoidWalkSpeedChangedConnection = nil
    end
    
    playerState.activeBoost = newBoostType
    setButtonActive(speedButton1, newBoostType == "Boost1")
    setButtonActive(speedButton2, newBoostType == "Boost2")

    if newBoostType == "Boost1" then
        humanoid.WalkSpeed = CONFIG.BOOSTED_SPEED_1
        speedButton1.Text = "SPEED 1 ON"
        speedButton2.Text = "DYNAMIC SPD"
        statusLabel.Text = "Speed 1 Active"
        statusLabel.TextColor3 = Color3.fromRGB(46, 204, 113)
        humanoidWalkSpeedChangedConnection = humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
            enforceBoostedSpeed(humanoid)
        end)
    elseif newBoostType == "Boost2" then
        humanoid.WalkSpeed = gameSetSpeed + CONFIG.DYNAMIC_SPEED_ADDITIVE
        speedButton1.Text = "SPEED BOOST 1"
        speedButton2.Text = "DYNAMIC ON"
        statusLabel.Text = "Dynamic Speed (+"..CONFIG.DYNAMIC_SPEED_ADDITIVE..")"
        statusLabel.TextColor3 = Color3.fromRGB(52, 152, 219)
        humanoidWalkSpeedChangedConnection = humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
            enforceBoostedSpeed(humanoid)
        end)
    else 
        humanoid.WalkSpeed = gameSetSpeed
        speedButton1.Text = "SPEED BOOST 1"
        speedButton2.Text = "DYNAMIC SPD"
        if playerState.espMode == 0 and not playerState.isLagSwitchActive and not playerState.isInvisible then
            statusLabel.Text = "Ready"
            statusLabel.TextColor3 = CONFIG.SECONDARY_TEXT_COLOR
        end
    end
end

local function toggleFullbright()
    playerState.isFullbrightActive = not playerState.isFullbrightActive
    setButtonActive(fullbrightButton, playerState.isFullbrightActive)

    if playerState.isFullbrightActive then
        originalLightingSettings.Ambient = Lighting.Ambient
        originalLightingSettings.OutdoorAmbient = Lighting.OutdoorAmbient
        originalLightingSettings.Brightness = Lighting.Brightness
        originalLightingSettings.FogEnd = Lighting.FogEnd
        originalLightingSettings.GlobalShadows = Lighting.GlobalShadows
        originalLightingSettings.ClockTime = Lighting.ClockTime
        whiteSky = Instance.new("Sky")
        whiteSky.Name = "FullbrightSky"
        whiteSky.SkyboxBk = "rbxassetid://60345030"; whiteSky.SkyboxDn = "rbxassetid://60345030"
        whiteSky.SkyboxFt = "rbxassetid://60345030"; whiteSky.SkyboxLf = "rbxassetid://60345030"
        whiteSky.SkyboxRt = "rbxassetid://60345030"; whiteSky.SkyboxUp = "rbxassetid://60345030"
        whiteSky.SunTextureId = ""; whiteSky.MoonTextureId = ""; whiteSky.Parent = Lighting
        fullbrightConnection = RunService.RenderStepped:Connect(function()
            Lighting.Ambient = Color3.new(1, 1, 1); Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
            Lighting.Brightness = 2; Lighting.FogEnd = 1000000
            Lighting.GlobalShadows = false; Lighting.ClockTime = 14
        end)
        fullbrightButton.Text = "FULLBRIGHT ON"
    else
        if fullbrightConnection then fullbrightConnection:Disconnect(); fullbrightConnection = nil end
        if whiteSky then whiteSky:Destroy(); whiteSky = nil end
         Lighting.Ambient = originalLightingSettings.Ambient or Color3.new(0,0,0)
        Lighting.OutdoorAmbient = originalLightingSettings.OutdoorAmbient or Color3.new(0,0,0)
        Lighting.Brightness = originalLightingSettings.Brightness or 1
        Lighting.FogEnd = originalLightingSettings.FogEnd or 10000
        Lighting.GlobalShadows = originalLightingSettings.GlobalShadows ~= nil and originalLightingSettings.GlobalShadows or true
        Lighting.ClockTime = originalLightingSettings.ClockTime or 12
        fullbrightButton.Text = "FULLBRIGHT"
    end
end

local function toggleLagSwitch()
    if not player.Character then return end
    playerState.isLagSwitchActive = not playerState.isLagSwitchActive
    setButtonActive(lagSwitchButton, playerState.isLagSwitchActive)
    
    if playerState.isLagSwitchActive then
        local humanoidRootPart = getHumanoidRootPart()
        if not humanoidRootPart then return end
        local currentCFrame = humanoidRootPart.CFrame
        
        lagSwitchIndicatorPart = Instance.new("Part")
        lagSwitchIndicatorPart.Name = "LagSwitchOriginIndicator"
        lagSwitchIndicatorPart.Shape = Enum.PartType.Ball
        lagSwitchIndicatorPart.Size = Vector3.new(2.5, 2.5, 2.5)
        lagSwitchIndicatorPart.CFrame = currentCFrame
        lagSwitchIndicatorPart.CanCollide = false
        lagSwitchIndicatorPart.Anchored = true
        lagSwitchIndicatorPart.Transparency = 0.4
        lagSwitchIndicatorPart.Material = Enum.Material.Neon
        lagSwitchIndicatorPart.BrickColor = BrickColor.new("Bright yellow")
        lagSwitchIndicatorPart.Parent = workspace
        
        local indicatorHighlight = Instance.new("Highlight")
        indicatorHighlight.Name = "IndicatorESP"
        indicatorHighlight.FillColor = Color3.fromRGB(255, 255, 0)
        indicatorHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        indicatorHighlight.FillTransparency = 0.5
        indicatorHighlight.Parent = lagSwitchIndicatorPart
        
        local seat = Instance.new("Seat")
        seat.Name = "invischair"
        seat.Anchored = false
        seat.CanCollide = false
        seat.Transparency = 1
        seat.CFrame = currentCFrame
        seat.Parent = workspace
        
        local weld = Instance.new("Weld")
        weld.Part0 = seat
        weld.Part1 = player.Character:FindFirstChild("Torso") or player.Character:FindFirstChild("UpperTorso")
        weld.Parent = seat
        
        setCharacterTransparency(player.Character, 0.5)
        
        lagSwitchButton.Text = "LAG ON"
        statusLabel.Text = "Lag Switch Active"
        statusLabel.TextColor3 = Color3.fromRGB(241, 196, 15)
    else
        local invisChair = workspace:FindFirstChild("invischair")
        if invisChair then invisChair:Destroy() end
        
        if lagSwitchIndicatorPart then
            lagSwitchIndicatorPart:Destroy()
            lagSwitchIndicatorPart = nil
        end
        
        if player.Character then
            setCharacterTransparency(player.Character, 0)
        end
        
        lagSwitchButton.Text = "LAG SWITCH"
        if playerState.activeBoost == "None" and not playerState.isInvisible and playerState.espMode == 0 then
            statusLabel.Text = "Ready"
            statusLabel.TextColor3 = CONFIG.SECONDARY_TEXT_COLOR
        end
    end
end

local function toggleInvisibility()
    if not player.Character then return end
    playerState.isInvisible = not playerState.isInvisible
    setButtonActive(invisibilityButton, playerState.isInvisible)
    
    if playerState.isInvisible then
        local humanoidRootPart = getHumanoidRootPart()
        if not humanoidRootPart then return end
        local savedPosition = humanoidRootPart.CFrame
        
        player.Character:MoveTo(CONFIG.INVISIBILITY_POSITION)
        task.wait(0.15)
        
        local seat = Instance.new("Seat")
        seat.Name = "invischair"
        seat.Anchored = false
        seat.CanCollide = false
        seat.Transparency = 1
        seat.Position = CONFIG.INVISIBILITY_POSITION
        seat.Parent = workspace
        
        local weld = Instance.new("Weld")
        weld.Part0 = seat
        weld.Part1 = player.Character:FindFirstChild("Torso") or player.Character:FindFirstChild("UpperTorso")
        weld.Parent = seat
        
        task.wait()
        seat.CFrame = savedPosition
        
        setCharacterTransparency(player.Character, 0.5)
        
        invisibilityButton.Text = "VISIBLE"
        statusLabel.Text = "Invisible Mode Active"
        statusLabel.TextColor3 = Color3.fromRGB(46, 204, 113)
    else
        local invisChair = workspace:FindFirstChild("invischair")
        if invisChair then invisChair:Destroy() end
        
        if player.Character then
            setCharacterTransparency(player.Character, 0)
        end
        
        invisibilityButton.Text = "INVISIBLE"
        
        if playerState.activeBoost == "None" and not playerState.isLagSwitchActive and playerState.espMode == 0 then
            statusLabel.Text = "Ready"
            statusLabel.TextColor3 = CONFIG.SECONDARY_TEXT_COLOR
        end
    end
end

local function toggleSpawnpoint()
    local currentTime = tick()
    if currentTime - lastResetTime < CONFIG.RESET_COOLDOWN then
        statusLabel.Text = "Wait: " .. math.ceil(CONFIG.RESET_COOLDOWN - (currentTime - lastResetTime)) .. "s"
        statusLabel.TextColor3 = Color3.fromRGB(231, 76, 60)
        return
    end

    if savedSpawnCFrame then
        savedSpawnCFrame = nil
        setButtonActive(resetButton, false)
        resetButton.Text = "SET SPAWN"
        statusLabel.Text = "Spawnpoint Cleared"
        statusLabel.TextColor3 = CONFIG.SECONDARY_TEXT_COLOR
    else
        local hrp = getHumanoidRootPart()
        if not hrp then return end
        
        savedSpawnCFrame = hrp.CFrame
        setButtonActive(resetButton, true)
        resetButton.Text = "SPAWN ON"
        playResetEffect(hrp.Position)
        
        statusLabel.Text = "Spawnpoint Set!"
        statusLabel.TextColor3 = Color3.fromRGB(46, 204, 113)
    end
    
    lastResetTime = currentTime
end

local function toggleSpecificBoost(boostType: "Boost1" | "Boost2")
    if playerState.activeBoost == boostType then setBoostState("None") else setBoostState(boostType) end
end

local function resetPlayerState()
    if humanoidWalkSpeedChangedConnection then humanoidWalkSpeedChangedConnection:Disconnect(); humanoidWalkSpeedChangedConnection = nil end
    playerState.activeBoost = "None"
    playerState.isLagSwitchActive = false
    playerState.isInvisible = false
    playerState.isNoclipActive = false
    playerState.isJumpBoostActive = false
    playerState.isInstantInteractActive = false 
    playerState.isSpeedometerActive = false
    playerState.isZoomActive = false
    playerState.isWarningActive = false 
    playerState.isCustomEspActive = false
    playerState.customEspKeyword = ""
    
    setButtonActive(speedButton1, false)
    setButtonActive(speedButton2, false)
    setButtonActive(jumpButton, false)
    setButtonActive(noclipButton, false)
    setButtonActive(lagSwitchButton, false)
    setButtonActive(invisibilityButton, false)
    setButtonActive(instantButton, false)
    setButtonActive(speedometerButton, false)
    setButtonActive(zoomButton, false)
    setButtonActive(warningButton, false) 
    setButtonActive(customEspButton, false)

    local invisChair = workspace:FindFirstChild("invischair")
    if invisChair then invisChair:Destroy() end
    if lagSwitchIndicatorPart then lagSwitchIndicatorPart:Destroy(); lagSwitchIndicatorPart = nil end
    if warningGui then warningGui:Destroy(); warningGui = nil end 
    
    if player.Character then 
        setCharacterTransparency(player.Character, 0) 
    end
    speedButton1.Text = "SPEED BOOST 1"
    speedButton2.Text = "DYNAMIC SPD"
    jumpButton.Text = "JUMP POWER"
    noclipButton.Text = "NOCLIP"
    lagSwitchButton.Text = "LAG SWITCH"
    invisibilityButton.Text = "INVISIBLE"
    instantButton.Text = "INSTANT INTERACT"
    speedometerButton.Text = "SPEEDOMETER"
    zoomButton.Text = "UNLIMITED ZOOM"
    warningButton.Text = "PROXIMITY WARNING" 
    customEspButton.Text = "CUSTOM ESP"
    
    playerState.espMode = 0; clearEsp()
    clearCustomEsp()
    
    statusLabel.Text = "Ready"; statusLabel.TextColor3 = CONFIG.SECONDARY_TEXT_COLOR
    statusLabel.Visible = true 
    speedometerLabel.Visible = false 
    
    local humanoid = getHumanoid()
    if humanoid then 
        humanoid.WalkSpeed = gameSetSpeed
        humanoid.JumpPower = CONFIG.DEFAULT_JUMP
    end

    player.CameraMaxZoomDistance = 12.5
    player.CameraMinZoomDistance = 0.5
end

local function createGUI()
    local existing = player:WaitForChild("PlayerGui"):FindFirstChild("ToolsGUI")
    if existing then existing:Destroy() end

    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ToolsGUI"
    screenGui.ResetOnSpawn = false 
    screenGui.IgnoreGuiInset = true 
    screenGui.Parent = player:WaitForChild("PlayerGui")
    
    tooltipFrame = Instance.new("Frame")
    tooltipFrame.Name = "TooltipFrame"
    tooltipFrame.BackgroundColor3 = CONFIG.ACCENT_COLOR
    tooltipFrame.BorderSizePixel = 0
    tooltipFrame.Visible = false
    tooltipFrame.ZIndex = 50
    tooltipFrame.AutomaticSize = Enum.AutomaticSize.XY
    tooltipFrame.Parent = screenGui

    local tooltipCorner = Instance.new("UICorner")
    tooltipCorner.CornerRadius = UDim.new(0, 4)
    tooltipCorner.Parent = tooltipFrame

    local tooltipPadding = Instance.new("UIPadding")
    tooltipPadding.PaddingLeft = UDim.new(0, 6)
    tooltipPadding.PaddingRight = UDim.new(0, 6)
    tooltipPadding.PaddingTop = UDim.new(0, 4)
    tooltipPadding.PaddingBottom = UDim.new(0, 4)
    tooltipPadding.Parent = tooltipFrame

    local tooltipStroke = Instance.new("UIStroke")
    tooltipStroke.Color = CONFIG.BORDER_COLOR
    tooltipStroke.Thickness = 1
    tooltipStroke.Parent = tooltipFrame

    tooltipLabel = Instance.new("TextLabel")
    tooltipLabel.BackgroundTransparency = 1
    tooltipLabel.TextColor3 = CONFIG.TEXT_COLOR
    tooltipLabel.Font = Enum.Font.Gotham
    tooltipLabel.TextSize = 8
    tooltipLabel.AutomaticSize = Enum.AutomaticSize.XY
    tooltipLabel.ZIndex = 51
    tooltipLabel.Parent = tooltipFrame

    mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 0, 0, 22) 
    mainFrame.Position = UDim2.new(0.5, -60, 0.5, -57) 
    mainFrame.BackgroundColor3 = CONFIG.BACKGROUND_COLOR
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.ClipsDescendants = true 
    mainFrame.Visible = false
    mainFrame.Parent = screenGui

    local mainCorner = Instance.new("UICorner"); mainCorner.CornerRadius = UDim.new(0, 8); mainCorner.Parent = mainFrame
    
    local frameStroke = Instance.new("UIStroke")
    frameStroke.Color = CONFIG.BORDER_COLOR
    frameStroke.Thickness = 1
    frameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    frameStroke.Parent = mainFrame

    minimizedFrame = Instance.new("Frame")
    minimizedFrame.Name = "MinimizedFrame"
    minimizedFrame.Size = UDim2.new(0, 60, 0, 16)
    minimizedFrame.Position = UDim2.new(0.5, -30, 0, 10)
    minimizedFrame.BackgroundColor3 = CONFIG.TAB_COLOR
    minimizedFrame.BackgroundTransparency = 0.85
    minimizedFrame.BorderSizePixel = 0
    minimizedFrame.Visible = false
    minimizedFrame.Parent = screenGui
    
    local minCorner = Instance.new("UICorner")
    minCorner.CornerRadius = UDim.new(1, 0)
    minCorner.Parent = minimizedFrame

    local minStroke = Instance.new("UIStroke")
    minStroke.Color = CONFIG.BORDER_COLOR
    minStroke.Thickness = 1
    minStroke.Transparency = 0.8
    minStroke.Parent = minimizedFrame

    maximizeButton = Instance.new("TextButton")
    maximizeButton.Size = UDim2.new(1, 0, 1, 0)
    maximizeButton.BackgroundTransparency = 1
    maximizeButton.Text = ""
    maximizeButton.Parent = minimizedFrame

    confirmFrame = Instance.new("Frame")
    confirmFrame.Name = "ConfirmFrame"
    confirmFrame.Size = UDim2.new(0, 0, 0, 0) 
    confirmFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    confirmFrame.BackgroundColor3 = CONFIG.BACKGROUND_COLOR
    confirmFrame.BorderSizePixel = 0
    confirmFrame.Visible = false
    confirmFrame.ClipsDescendants = true
    confirmFrame.Parent = screenGui
    
    local confirmCorner = Instance.new("UICorner")
    confirmCorner.CornerRadius = UDim.new(0, 8)
    confirmCorner.Parent = confirmFrame

    local confirmStroke = Instance.new("UIStroke")
    confirmStroke.Color = CONFIG.BORDER_COLOR
    confirmStroke.Thickness = 1
    confirmStroke.Parent = confirmFrame

    confirmLabel = Instance.new("TextLabel")
    confirmLabel.Size = UDim2.new(1, -10, 0, 40)
    confirmLabel.Position = UDim2.new(0, 5, 0, 5)
    confirmLabel.BackgroundTransparency = 1
    confirmLabel.Text = "Do you want to unload the script?"
    confirmLabel.TextColor3 = CONFIG.TEXT_COLOR
    confirmLabel.Font = Enum.Font.GothamBold
    confirmLabel.TextSize = 10
    confirmLabel.TextWrapped = true
    confirmLabel.TextTransparency = 1
    confirmLabel.Parent = confirmFrame

    local function styleConfirmButton(btn, color)
        btn.BackgroundTransparency = 1 
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.TextTransparency = 1
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 10
        
        local btnBg = Instance.new("Frame")
        btnBg.Name = "Background"
        btnBg.Size = UDim2.new(1, 0, 1, 0)
        btnBg.BackgroundColor3 = color
        btnBg.BackgroundTransparency = 1
        btnBg.BorderSizePixel = 0
        btnBg.ZIndex = 1
        btnBg.Parent = btn
        
        btn.ZIndex = 2 

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 4)
        corner.Parent = btnBg

        local gradient = Instance.new("UIGradient")
        gradient.Rotation = 0
        gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, color),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 15))
        })
        gradient.Parent = btnBg

        local stroke = Instance.new("UIStroke")
        stroke.Thickness = 1
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Color = Color3.new(1, 1, 1)
        stroke.Transparency = 1
        stroke.Parent = btnBg

        local h, s, v = color:ToHSV()
        local lighterColor = Color3.fromHSV(h, s * 0.8, math.min(v * 1.4, 1))

        local strokeGradient = Instance.new("UIGradient")
        strokeGradient.Rotation = 0
        strokeGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, lighterColor),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
            
        })
        strokeGradient.Parent = stroke
    end

    yesButton = Instance.new("TextButton")
    yesButton.Size = UDim2.new(0.4, 0, 0, 20)
    yesButton.Position = UDim2.new(0.05, 0, 0.65, 0)
    yesButton.Text = "YES"
    styleConfirmButton(yesButton, Color3.fromRGB(231, 76, 60))
    yesButton.Parent = confirmFrame

    noButton = Instance.new("TextButton")
    noButton.Size = UDim2.new(0.4, 0, 0, 20)
    noButton.Position = UDim2.new(0.55, 0, 0.65, 0)
    noButton.Text = "NO"
    styleConfirmButton(noButton, CONFIG.ACCENT_COLOR)
    noButton.Parent = confirmFrame

    inputFrame = Instance.new("Frame")
    inputFrame.Name = "InputFrame"
    inputFrame.Size = UDim2.new(0, 0, 0, 0) 
    inputFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    inputFrame.BackgroundColor3 = CONFIG.BACKGROUND_COLOR
    inputFrame.BorderSizePixel = 0
    inputFrame.Visible = false
    inputFrame.ClipsDescendants = true
    inputFrame.Parent = screenGui
    
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 8)
    inputCorner.Parent = inputFrame

    local inputStroke = Instance.new("UIStroke")
    inputStroke.Color = CONFIG.BORDER_COLOR
    inputStroke.Thickness = 1
    inputStroke.Parent = inputFrame

    inputBox = Instance.new("TextBox")
    inputBox.Size = UDim2.new(1, -20, 0, 25)
    inputBox.Position = UDim2.new(0, 10, 0, 10)
    inputBox.BackgroundColor3 = CONFIG.ACCENT_COLOR
    inputBox.TextColor3 = CONFIG.TEXT_COLOR
    inputBox.Font = Enum.Font.Gotham
    inputBox.TextSize = 10
    inputBox.PlaceholderText = "Enter search keyword..."
    inputBox.PlaceholderColor3 = CONFIG.SECONDARY_TEXT_COLOR
    inputBox.Text = ""
    inputBox.TextTransparency = 1
    inputBox.Parent = inputFrame

    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 4)
    boxCorner.Parent = inputBox

    local boxStroke = Instance.new("UIStroke")
    boxStroke.Color = CONFIG.BORDER_COLOR
    boxStroke.Thickness = 1
    boxStroke.Parent = inputBox

    submitSearchButton = Instance.new("TextButton")
    submitSearchButton.Size = UDim2.new(0.4, 0, 0, 20)
    submitSearchButton.Position = UDim2.new(0.05, 0, 0.60, 0)
    submitSearchButton.Text = "SEARCH"
    styleConfirmButton(submitSearchButton, Color3.fromRGB(46, 204, 113))
    submitSearchButton.Parent = inputFrame

    cancelSearchButton = Instance.new("TextButton")
    cancelSearchButton.Size = UDim2.new(0.4, 0, 0, 20)
    cancelSearchButton.Position = UDim2.new(0.55, 0, 0.60, 0)
    cancelSearchButton.Text = "CANCEL"
    styleConfirmButton(cancelSearchButton, Color3.fromRGB(231, 76, 60))
    cancelSearchButton.Parent = inputFrame

    titleTabBg = Instance.new("Frame")
    titleTabBg.Name = "TitleTabBg"
    titleTabBg.Size = UDim2.new(1, 0, 0, 22)
    titleTabBg.Position = UDim2.new(0, 0, 0, 0)
    titleTabBg.BackgroundColor3 = CONFIG.TAB_COLOR
    titleTabBg.BorderSizePixel = 0
    titleTabBg.Parent = mainFrame
    
    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(0, 10) 
    bgCorner.Parent = titleTabBg
    
    local bottomBorder = Instance.new("Frame")
    bottomBorder.Name = "BottomBorder"
    bottomBorder.Size = UDim2.new(1, 0, 0, 1)
    bottomBorder.Position = UDim2.new(0, 0, 1, -1)
    bottomBorder.BackgroundColor3 = CONFIG.BORDER_COLOR
    bottomBorder.BorderSizePixel = 0
    bottomBorder.ZIndex = 3
    bottomBorder.Parent = titleTabBg

    local titleTab = Instance.new("Frame")
    titleTab.Name = "TitleTab"
    titleTab.Size = UDim2.new(1, 0, 1, 0)
    titleTab.BackgroundTransparency = 1
    titleTab.BorderSizePixel = 0
    titleTab.Parent = titleTabBg

    logo = Instance.new("ImageButton")
    logo.Name = "Logo"
    logo.Size = UDim2.new(0, 12, 0, 12)
    logo.AnchorPoint = Vector2.new(0, 0.5) 
    logo.Position = UDim2.new(0, 8, 0.5, 0)
    logo.BackgroundTransparency = 1
    logo.ImageTransparency = 1 
    logo.Image = "rbxassetid://10793494685"
    logo.Parent = titleTab

    titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -35, 1, 0)
    titleLabel.AnchorPoint = Vector2.new(0, 0.5)
    titleLabel.Position = UDim2.new(0, 24, 0.5, 0)
    titleLabel.TextTransparency = 1 
    titleLabel.Text = "TSOS" 
    titleLabel.BackgroundTransparency = 1; titleLabel.TextColor3 = Color3.new(1, 1, 1); titleLabel.Font = Enum.Font.GothamBold; titleLabel.TextSize = 10; titleLabel.TextXAlignment = Enum.TextXAlignment.Left; titleLabel.Parent = titleTab
    
    closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 14, 0, 14)
    closeButton.AnchorPoint = Vector2.new(0, 0.5)
    closeButton.Position = UDim2.new(1, -18, 0.5, 0)
    closeButton.Text = "×"
    closeButton.TextTransparency = 1
    closeButton.BackgroundTransparency = 1; closeButton.TextColor3 = Color3.new(1, 1, 1); closeButton.Font = Enum.Font.GothamBold; closeButton.TextSize = 14; closeButton.BorderSizePixel = 0; closeButton.Parent = titleTab

    minimizeButton = Instance.new("TextButton")
    minimizeButton.Size = UDim2.new(0, 14, 0, 14)
    minimizeButton.AnchorPoint = Vector2.new(0, 0.5)
    minimizeButton.Position = UDim2.new(1, -34, 0.5, 0)
    minimizeButton.Text = "-"
    minimizeButton.TextTransparency = 1
    minimizeButton.BackgroundTransparency = 1; minimizeButton.TextColor3 = Color3.new(1, 1, 1); minimizeButton.Font = Enum.Font.GothamBold; minimizeButton.TextSize = 14; minimizeButton.BorderSizePixel = 0; minimizeButton.Parent = titleTab
    
    scrollingFrame = Instance.new("ScrollingFrame")
    scrollingFrame.Size = UDim2.new(1, -16, 0, 52); scrollingFrame.Position = UDim2.new(0, 8, 0, 36)
    scrollingFrame.BackgroundColor3 = CONFIG.BACKGROUND_COLOR; scrollingFrame.ScrollBarThickness = 2; scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 360); scrollingFrame.Parent = mainFrame
    scrollingFrame.ScrollingDirection = Enum.ScrollingDirection.Y 
    scrollingFrame.ElasticBehavior = Enum.ElasticBehavior.Always

    local uiPadding = Instance.new("UIPadding")
    uiPadding.PaddingTop = UDim.new(0, 4)
    uiPadding.PaddingBottom = UDim.new(0, 4)
    uiPadding.Parent = scrollingFrame
    
    local listLayout = Instance.new("UIListLayout"); listLayout.Padding = UDim.new(0, 4); listLayout.Parent = scrollingFrame
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    scrollingFrame:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        local yPos = scrollingFrame.CanvasPosition.Y
        local windowHeight = scrollingFrame.AbsoluteWindowSize.Y
        if windowHeight == 0 then windowHeight = 52 end
        
        local maxScroll = math.max(0, scrollingFrame.CanvasSize.Y.Offset - windowHeight)
        local bounce = 0
        
        if yPos < 0 then 
            bounce = math.abs(yPos) 
            listLayout.VerticalAlignment = Enum.VerticalAlignment.Top
        elseif yPos > maxScroll then
            bounce = yPos - maxScroll
            listLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
        else
            listLayout.VerticalAlignment = Enum.VerticalAlignment.Top
        end
        
        local extraPadding = bounce * 0.12
        listLayout.Padding = UDim.new(0, 4 + extraPadding)
        uiPadding.PaddingTop = UDim.new(0, 4)
    end)
    
    configScrollingFrame = Instance.new("ScrollingFrame")
    configScrollingFrame.Name = "ConfigFrame"
    configScrollingFrame.Size = UDim2.new(1, -16, 0, 52)
    configScrollingFrame.Position = UDim2.new(0, 8, 0, 36)
    configScrollingFrame.BackgroundColor3 = CONFIG.BACKGROUND_COLOR
    configScrollingFrame.ScrollBarThickness = 2
    configScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0) 
    configScrollingFrame.Visible = false
    configScrollingFrame.Parent = mainFrame
    configScrollingFrame.ScrollingDirection = Enum.ScrollingDirection.Y
    configScrollingFrame.ElasticBehavior = Enum.ElasticBehavior.Always

    local configListLayout = Instance.new("UIListLayout")
    configListLayout.Padding = UDim.new(0, 4)
    configListLayout.Parent = configScrollingFrame
    configListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local configPadding = Instance.new("UIPadding")
    configPadding.PaddingTop = UDim.new(0, 4)
    configPadding.PaddingBottom = UDim.new(0, 4)
    configPadding.Parent = configScrollingFrame

    local shortNames = {
        SPEED_1_KEY = "SPD 1", SPEED_2_KEY = "SPD 2", LAG_SWITCH_KEY = "LAG KEY", INVISIBILITY_KEY = "INVIS",
        FULLBRIGHT_KEY = "F-BRIGHT", ESP_CHAMS_KEY = "ESP KEY", RESET_KEY = "RESET", NOCLIP_KEY = "NOCLIP",
        SPEEDOMETER_KEY = "SPEEDO", ZOOM_KEY = "ZOOM", WARNING_KEY = "WARN", CUSTOM_ESP_KEY = "C-ESP",
        BOOSTED_SPEED_1 = "BST SPD 1", DYNAMIC_SPEED_ADDITIVE = "DYN ADD", DEFAULT_JUMP = "DEF JUMP",
        BOOSTED_JUMP = "BST JUMP", HITBOX_SIZE = "HB SIZE", MAX_ZOOM = "MAX ZM", MIN_ZOOM = "MIN ZM",
        WARNING_DISTANCE = "WARN DIST", INVISIBILITY_POSITION = "INVIS POS", RESET_COOLDOWN = "RST CD",
        BACKGROUND_COLOR = "BG CLR", ACCENT_COLOR = "ACC CLR", TAB_COLOR = "TAB CLR", BORDER_COLOR = "BRDR CLR",
        TEXT_COLOR = "TXT CLR", SECONDARY_TEXT_COLOR = "SEC TXT", ESP_MAX_DISTANCE = "ESP MAX", ESP_NEAR_DISTANCE = "ESP NEAR"
    }

    local speedsPowersKeys = {"BOOSTED_SPEED_1", "DYNAMIC_SPEED_ADDITIVE", "DEFAULT_JUMP", "BOOSTED_JUMP", "HITBOX_SIZE", "MAX_ZOOM", "MIN_ZOOM", "WARNING_DISTANCE"}
    local otherKeys = {}
    
    for k, _ in pairs(CONFIG) do 
        local isPower = false
        for _, powerKey in ipairs(speedsPowersKeys) do
            if k == powerKey then isPower = true break end
        end
        if not isPower then table.insert(otherKeys, k) end
    end
    
    table.sort(otherKeys)
    
    local finalSortedKeys = {}
    for _, k in ipairs(speedsPowersKeys) do if CONFIG[k] ~= nil then table.insert(finalSortedKeys, k) end end
    for _, k in ipairs(otherKeys) do table.insert(finalSortedKeys, k) end

    for _, key in ipairs(finalSortedKeys) do
        local val = CONFIG[key]
        
        local row = Instance.new("Frame")
        row.Size = UDim2.new(0.92, 0, 0, 20)
        row.BackgroundTransparency = 1
        row.Parent = configScrollingFrame
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.5, 0, 1, 0)
        label.Position = UDim2.new(0, 0, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = shortNames[key] or key
        label.TextColor3 = CONFIG.TEXT_COLOR
        label.TextXAlignment = Enum.TextXAlignment.Center
        label.Font = Enum.Font.Gotham
        label.TextSize = 7 
        label.TextTransparency = 1
        label.Active = true 
        label.Parent = row

        label.MouseEnter:Connect(function()
            tooltipLabel.Text = key
            tooltipFrame.AnchorPoint = Vector2.new(0.5, 1)
            tooltipFrame.Position = UDim2.new(0, titleTabBg.AbsolutePosition.X + (titleTabBg.AbsoluteSize.X / 2), 0, titleTabBg.AbsolutePosition.Y - 5)
            tooltipFrame.Visible = true
        end)

        label.MouseLeave:Connect(function()
            tooltipFrame.Visible = false
        end)

        label.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then
                tooltipLabel.Text = key
                tooltipFrame.AnchorPoint = Vector2.new(0.5, 1)
                tooltipFrame.Position = UDim2.new(0, titleTabBg.AbsolutePosition.X + (titleTabBg.AbsoluteSize.X / 2), 0, titleTabBg.AbsolutePosition.Y - 5)
                tooltipFrame.Visible = true
            end
        end)

        label.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then
                tooltipFrame.Visible = false
            end
        end)
        
        local boxBg = Instance.new("Frame")
        boxBg.Size = UDim2.new(0.5, -4, 1, 0)
        boxBg.Position = UDim2.new(0.5, 2, 0, 0)
        boxBg.BackgroundColor3 = CONFIG.ACCENT_COLOR
        boxBg.BackgroundTransparency = 1
        boxBg.BorderSizePixel = 0
        boxBg.ClipsDescendants = true 
        boxBg.Parent = row
        
        local boxCorner = Instance.new("UICorner")
        boxCorner.CornerRadius = UDim.new(0, 4)
        boxCorner.Parent = boxBg
        
        local boxStroke = Instance.new("UIStroke")
        boxStroke.Color = CONFIG.BORDER_COLOR
        boxStroke.Thickness = 1
        boxStroke.Transparency = 1
        boxStroke.Parent = boxBg

        local box = Instance.new("TextBox")
        box.Size = UDim2.new(1, -4, 1, 0)
        box.Position = UDim2.new(0, 2, 0, 0)
        box.BackgroundTransparency = 1
        box.Text = valToString(val)
        box.TextColor3 = CONFIG.SECONDARY_TEXT_COLOR
        box.Font = Enum.Font.Gotham
        box.TextSize = 7 
        box.TextTransparency = 1
        box.ClearTextOnFocus = false
        box.ClipsDescendants = true 
        box.Parent = boxBg
        
        box.FocusLost:Connect(function()
            local parsed = parseVal(CONFIG[key], box.Text)
            CONFIG[key] = parsed
            box.Text = valToString(parsed)
        end)
    end
    
    configListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        configScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, configListLayout.AbsoluteContentSize.Y + 10)
    end)

    local function setupButton(btn, name, text)
        btn.Name = name
        btn.Size = UDim2.new(0.92, 0, 0, 20)
        btn.Text = text
        btn.BackgroundTransparency = 1 
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.TextTransparency = 1 
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 10
        btn.ZIndex = 2
        btn.Parent = scrollingFrame

        local btnBg = Instance.new("Frame")
        btnBg.Name = "Background"
        btnBg.Size = UDim2.new(1, 0, 1, 0)
        btnBg.BackgroundColor3 = Color3.fromRGB(45, 45, 45) 
        btnBg.BackgroundTransparency = 1 
        btnBg.BorderSizePixel = 0
        btnBg.ZIndex = 1
        btnBg.Parent = btn

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 4)
        corner.Parent = btnBg

        local gradient = Instance.new("UIGradient")
        gradient.Rotation = 0
        gradient.Parent = btnBg

        local stroke = Instance.new("UIStroke")
        stroke.Thickness = 1
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Color = Color3.new(1, 1, 1) 
        stroke.Transparency = 1 
        stroke.Parent = btnBg

        local strokeGradient = Instance.new("UIGradient")
        strokeGradient.Rotation = 0
        strokeGradient.Parent = stroke

        btn.MouseButton1Down:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0.85, 0, 0, 18)}):Play()
        end)

        btn.MouseButton1Up:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0.92, 0, 0, 20)}):Play()
        end)
        
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0.92, 0, 0, 20)}):Play()
        end)
    end

    speedButton1 = Instance.new("TextButton"); setupButton(speedButton1, "SpeedButton1", "SPEED BOOST 1")
    speedButton2 = Instance.new("TextButton"); setupButton(speedButton2, "SpeedButton2", "DYNAMIC SPD")
    jumpButton = Instance.new("TextButton"); setupButton(jumpButton, "JumpButton", "JUMP POWER")         
    noclipButton = Instance.new("TextButton"); setupButton(noclipButton, "NoclipButton", "NOCLIP")       
    hitboxButton = Instance.new("TextButton"); setupButton(hitboxButton, "HitboxButton", "HITBOX OFF")   
    lagSwitchButton = Instance.new("TextButton"); setupButton(lagSwitchButton, "LagSwitchButton", "LAG SWITCH")
    invisibilityButton = Instance.new("TextButton"); setupButton(invisibilityButton, "InvisibilityButton", "INVISIBLE")
    fullbrightButton = Instance.new("TextButton"); setupButton(fullbrightButton, "FullbrightButton", "FULLBRIGHT")
    espButton = Instance.new("TextButton"); setupButton(espButton, "EspButton", "ESP CHAMS")
    customEspButton = Instance.new("TextButton"); setupButton(customEspButton, "CustomEspButton", "CUSTOM ESP") 
    instantButton = Instance.new("TextButton"); setupButton(instantButton, "InstantButton", "INSTANT INTERACT") 
    speedometerButton = Instance.new("TextButton"); setupButton(speedometerButton, "SpeedometerButton", "SPEEDOMETER")
    zoomButton = Instance.new("TextButton"); setupButton(zoomButton, "ZoomButton", "UNLIMITED ZOOM")
    warningButton = Instance.new("TextButton"); setupButton(warningButton, "WarningButton", "PROXIMITY WARNING") 
    resetButton = Instance.new("TextButton"); setupButton(resetButton, "ResetButton", "SET SPAWN") 
    
    speedometerLabel = Instance.new("TextLabel")
    speedometerLabel.Size = UDim2.new(1, -10, 0, 12)
    speedometerLabel.Position = UDim2.new(0, 5, 1, -34)
    speedometerLabel.Text = "Speed: 0 studs/s"
    speedometerLabel.BackgroundTransparency = 1
    speedometerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    speedometerLabel.Font = Enum.Font.GothamBold
    speedometerLabel.TextSize = 8
    speedometerLabel.TextTransparency = 1
    speedometerLabel.Visible = false 
    speedometerLabel.Parent = mainFrame

    statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -10, 0, 12); statusLabel.Position = UDim2.new(0, 5, 1, -22); statusLabel.Text = "Ready"
    statusLabel.BackgroundTransparency = 1; statusLabel.TextColor3 = CONFIG.SECONDARY_TEXT_COLOR; statusLabel.Font = Enum.Font.Gotham; statusLabel.TextSize = 8; statusLabel.TextTransparency = 1; statusLabel.Parent = mainFrame
    
    signatureLabel = Instance.new("TextLabel")
    signatureLabel.Size = UDim2.new(1, 0, 0, 10); signatureLabel.Position = UDim2.new(0, 0, 1, -10); signatureLabel.Text = "The Script of Stuffs" 
    signatureLabel.BackgroundTransparency = 1; signatureLabel.TextColor3 = CONFIG.SECONDARY_TEXT_COLOR; signatureLabel.Font = Enum.Font.Gotham; signatureLabel.TextSize = 7; signatureLabel.TextTransparency = 1; signatureLabel.Parent = mainFrame
end

local function playStartupAnimation()
    local splashLabel = Instance.new("TextLabel")
    splashLabel.Name = "SplashTitle"
    splashLabel.Size = UDim2.new(1, 0, 1, 0)
    splashLabel.BackgroundTransparency = 1
    splashLabel.Text = "TSOS"
    splashLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    splashLabel.Font = Enum.Font.GothamBold
    splashLabel.TextSize = 100
    splashLabel.ZIndex = 100
    splashLabel.Parent = screenGui

    task.wait(4)

    local fadeOutTween = TweenService:Create(splashLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 1})
    fadeOutTween:Play()
    fadeOutTween.Completed:Wait()
    splashLabel:Destroy()

    local tweenInfoFast = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tweenInfoSlow = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

    mainFrame.Visible = true
    mainFrame.Size = UDim2.new(0, 0, 0, 22)
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, -57)
    local t1 = TweenService:Create(mainFrame, tweenInfoSlow, {Size = UDim2.new(0, 120, 0, 22), Position = UDim2.new(0.5, -60, 0.5, -57)})
    t1:Play()
    t1.Completed:Wait()

    local t2_logo = TweenService:Create(logo, tweenInfoFast, {ImageTransparency = 0})
    local t2_title = TweenService:Create(titleLabel, tweenInfoFast, {TextTransparency = 0})
    local t2_close = TweenService:Create(closeButton, tweenInfoFast, {TextTransparency = 0})
    local t2_min = TweenService:Create(minimizeButton, tweenInfoFast, {TextTransparency = 0})
    t2_logo:Play()
    t2_title:Play()
    t2_close:Play()
    t2_min:Play()
    t2_title.Completed:Wait()

    local t3 = TweenService:Create(mainFrame, tweenInfoSlow, {Size = UDim2.new(0, 120, 0, 115)})
    t3:Play()
    t3.Completed:Wait()

    local buttons = {speedButton1, speedButton2, jumpButton, noclipButton, hitboxButton, lagSwitchButton, invisibilityButton, fullbrightButton, espButton, customEspButton, instantButton, speedometerButton, zoomButton, warningButton, resetButton}
    for _, btn in ipairs(buttons) do
        TweenService:Create(btn, TweenInfo.new(0.15), {TextTransparency = 0}):Play()
        local bg = btn:FindFirstChild("Background")
        if bg then
            TweenService:Create(bg, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play()
            local stroke = bg:FindFirstChildOfClass("UIStroke")
            if stroke then
                TweenService:Create(stroke, TweenInfo.new(0.15), {Transparency = 0}):Play()
            end
        end
        task.wait(0.05)
    end
    
    TweenService:Create(speedometerLabel, TweenInfo.new(0.2), {TextTransparency = 0}):Play()
    TweenService:Create(statusLabel, TweenInfo.new(0.2), {TextTransparency = 0}):Play()
    TweenService:Create(signatureLabel, TweenInfo.new(0.2), {TextTransparency = 0.5}):Play()
end

local function connectEvents()
    local tweenInfoFast = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tweenInfoBounce = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    local tweenInfoBounceIn = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
    local tweenInfoSmooth = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

    logo.MouseButton1Click:Connect(function()
        local tweenFastest = TweenInfo.new(0.15)
        TweenService:Create(logo, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Rotation = logo.Rotation + 360}):Play()
        
        TweenService:Create(speedometerLabel, tweenFastest, {TextTransparency = 1}):Play()
        TweenService:Create(statusLabel, tweenFastest, {TextTransparency = 1}):Play()
        TweenService:Create(signatureLabel, tweenFastest, {TextTransparency = 1}):Play()
        task.wait(0.1)

        if isConfigMenuOpen then
            isConfigMenuOpen = false
            statusLabel.Text = "Ready"
            statusLabel.TextColor3 = CONFIG.SECONDARY_TEXT_COLOR

            for _, row in ipairs(configScrollingFrame:GetChildren()) do
                if row:IsA("Frame") then
                    local label = row:FindFirstChildOfClass("TextLabel")
                    local bg = row:FindFirstChild("Frame")
                    if label then TweenService:Create(label, tweenFastest, {TextTransparency = 1}):Play() end
                    if bg then
                        TweenService:Create(bg, tweenFastest, {BackgroundTransparency = 1}):Play()
                        local stroke = bg:FindFirstChildOfClass("UIStroke")
                        if stroke then TweenService:Create(stroke, tweenFastest, {Transparency = 1}):Play() end
                        local box = bg:FindFirstChildOfClass("TextBox")
                        if box then TweenService:Create(box, tweenFastest, {TextTransparency = 1}):Play() end
                    end
                end
            end
            task.wait(0.15)
            
            local t_retract = TweenService:Create(mainFrame, tweenInfoSmooth, {Size = UDim2.new(0, 120, 0, 22)})
            t_retract:Play()
            t_retract.Completed:Wait()
            
            configScrollingFrame.Visible = false
            scrollingFrame.Visible = true
            
            local t_expand = TweenService:Create(mainFrame, tweenInfoSmooth, {Size = UDim2.new(0, 120, 0, 115)})
            t_expand:Play()
            t_expand.Completed:Wait()
            
            local buttons = {speedButton1, speedButton2, jumpButton, noclipButton, hitboxButton, lagSwitchButton, invisibilityButton, fullbrightButton, espButton, customEspButton, instantButton, speedometerButton, zoomButton, warningButton, resetButton}
            for _, btn in ipairs(buttons) do
                TweenService:Create(btn, tweenFastest, {TextTransparency = 0}):Play()
                local bg = btn:FindFirstChild("Background")
                if bg then
                    TweenService:Create(bg, tweenFastest, {BackgroundTransparency = 0}):Play()
                    local stroke = bg:FindFirstChildOfClass("UIStroke")
                    if stroke then TweenService:Create(stroke, tweenFastest, {Transparency = 0}):Play() end
                end
            end
        else
            isConfigMenuOpen = true
            statusLabel.Text = "Configs settings"
            statusLabel.TextColor3 = CONFIG.TEXT_COLOR

            local buttons = {speedButton1, speedButton2, jumpButton, noclipButton, hitboxButton, lagSwitchButton, invisibilityButton, fullbrightButton, espButton, customEspButton, instantButton, speedometerButton, zoomButton, warningButton, resetButton}
            for _, btn in ipairs(buttons) do
                TweenService:Create(btn, tweenFastest, {TextTransparency = 1}):Play()
                local bg = btn:FindFirstChild("Background")
                if bg then
                    TweenService:Create(bg, tweenFastest, {BackgroundTransparency = 1}):Play()
                    local stroke = bg:FindFirstChildOfClass("UIStroke")
                    if stroke then TweenService:Create(stroke, tweenFastest, {Transparency = 1}):Play() end
                end
            end
            task.wait(0.15)
            
            local t_retract = TweenService:Create(mainFrame, tweenInfoSmooth, {Size = UDim2.new(0, 120, 0, 22)})
            t_retract:Play()
            t_retract.Completed:Wait()
            
            scrollingFrame.Visible = false
            configScrollingFrame.Visible = true
            
            local t_expand = TweenService:Create(mainFrame, tweenInfoSmooth, {Size = UDim2.new(0, 120, 0, 115)})
            t_expand:Play()
            t_expand.Completed:Wait()
            
            for _, row in ipairs(configScrollingFrame:GetChildren()) do
                if row:IsA("Frame") then
                    local label = row:FindFirstChildOfClass("TextLabel")
                    local bg = row:FindFirstChild("Frame")
                    if label then TweenService:Create(label, tweenFastest, {TextTransparency = 0}):Play() end
                    if bg then
                        TweenService:Create(bg, tweenFastest, {BackgroundTransparency = 0}):Play()
                        local stroke = bg:FindFirstChildOfClass("UIStroke")
                        if stroke then TweenService:Create(stroke, tweenFastest, {Transparency = 0}):Play() end
                        local box = bg:FindFirstChildOfClass("TextBox")
                        if box then TweenService:Create(box, tweenFastest, {TextTransparency = 0}):Play() end
                    end
                end
            end
        end

        TweenService:Create(speedometerLabel, tweenFastest, {TextTransparency = 0}):Play()
        TweenService:Create(statusLabel, tweenFastest, {TextTransparency = 0}):Play()
        TweenService:Create(signatureLabel, tweenFastest, {TextTransparency = 0.5}):Play()
    end)

    speedButton1.MouseButton1Click:Connect(function() toggleSpecificBoost("Boost1") end)
    
    speedButton2.MouseButton1Click:Connect(function()
        if playerState.activeBoost == "Boost2" then
            setBoostState("None")
        else
            TweenService:Create(speedometerLabel, tweenInfoFast, {TextTransparency = 1}):Play()
            TweenService:Create(statusLabel, tweenInfoFast, {TextTransparency = 1}):Play()
            TweenService:Create(signatureLabel, tweenInfoFast, {TextTransparency = 1}):Play()
            task.wait(0.1)

            local t_retract = TweenService:Create(mainFrame, tweenInfoSmooth, {Size = UDim2.new(0, 120, 0, 22)})
            t_retract:Play()
            t_retract.Completed:Wait()

            local t_fade_logo = TweenService:Create(logo, tweenInfoFast, {ImageTransparency = 1})
            local t_fade_title = TweenService:Create(titleLabel, tweenInfoFast, {TextTransparency = 1})
            local t_fade_close = TweenService:Create(closeButton, tweenInfoFast, {TextTransparency = 1})
            local t_fade_min = TweenService:Create(minimizeButton, tweenInfoFast, {TextTransparency = 1})
            t_fade_logo:Play()
            t_fade_title:Play()
            t_fade_close:Play()
            t_fade_min:Play()
            t_fade_title.Completed:Wait()
            
            local currentPos = mainFrame.Position
            local t_shrink = TweenService:Create(mainFrame, tweenInfoSmooth, {
                Size = UDim2.new(0, 0, 0, 22),
                Position = UDim2.new(currentPos.X.Scale, currentPos.X.Offset + 60, currentPos.Y.Scale, currentPos.Y.Offset)
            })
            t_shrink:Play()
            t_shrink.Completed:Wait()
            
            mainFrame.Visible = false
            inputFrame.Size = UDim2.new(0, 0, 0, 22)
            inputFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
            inputFrame.Visible = true
            inputBox.PlaceholderText = "Add to Speed (e.g. 5)"
            inputBox.Text = tostring(CONFIG.DYNAMIC_SPEED_ADDITIVE)
            
            local t_expand = TweenService:Create(inputFrame, tweenInfoBounce, {Size = UDim2.new(0, 160, 0, 75), Position = UDim2.new(0.5, -80, 0.5, -37)})
            t_expand:Play()
            t_expand.Completed:Wait()
            
            TweenService:Create(inputBox, tweenInfoFast, {TextTransparency = 0}):Play()
            TweenService:Create(submitSearchButton, tweenInfoFast, {TextTransparency = 0}):Play()
            TweenService:Create(cancelSearchButton, tweenInfoFast, {TextTransparency = 0}):Play()
            submitSearchButton.Text = "APPLY"
            TweenService:Create(submitSearchButton.Background, tweenInfoFast, {BackgroundTransparency = 0}):Play()
            TweenService:Create(cancelSearchButton.Background, tweenInfoFast, {BackgroundTransparency = 0}):Play()
            TweenService:Create(submitSearchButton.Background.UIStroke, tweenInfoFast, {Transparency = 0}):Play()
            TweenService:Create(cancelSearchButton.Background.UIStroke, tweenInfoFast, {Transparency = 1}):Play()
        end
    end)

    jumpButton.MouseButton1Click:Connect(toggleJumpPower)     
    noclipButton.MouseButton1Click:Connect(toggleNoclip)     
    hitboxButton.MouseButton1Click:Connect(toggleHitbox)     
    lagSwitchButton.MouseButton1Click:Connect(toggleLagSwitch)
    invisibilityButton.MouseButton1Click:Connect(toggleInvisibility)
    fullbrightButton.MouseButton1Click:Connect(toggleFullbright)
    espButton.MouseButton1Click:Connect(toggleEsp)
    instantButton.MouseButton1Click:Connect(toggleInstantInteract) 
    speedometerButton.MouseButton1Click:Connect(toggleSpeedometer)
    zoomButton.MouseButton1Click:Connect(toggleZoom)
    warningButton.MouseButton1Click:Connect(toggleWarning) 
    resetButton.MouseButton1Click:Connect(toggleSpawnpoint) 

    customEspButton.MouseButton1Click:Connect(function()
        if playerState.isCustomEspActive then
            toggleCustomEsp()
        else
            TweenService:Create(speedometerLabel, tweenInfoFast, {TextTransparency = 1}):Play()
            TweenService:Create(statusLabel, tweenInfoFast, {TextTransparency = 1}):Play()
            TweenService:Create(signatureLabel, tweenInfoFast, {TextTransparency = 1}):Play()
            task.wait(0.1)

            local t_retract = TweenService:Create(mainFrame, tweenInfoSmooth, {Size = UDim2.new(0, 120, 0, 22)})
            t_retract:Play()
            t_retract.Completed:Wait()

            local t_fade_logo = TweenService:Create(logo, tweenInfoFast, {ImageTransparency = 1})
            local t_fade_title = TweenService:Create(titleLabel, tweenInfoFast, {TextTransparency = 1})
            local t_fade_close = TweenService:Create(closeButton, tweenInfoFast, {TextTransparency = 1})
            local t_fade_min = TweenService:Create(minimizeButton, tweenInfoFast, {TextTransparency = 1})
            t_fade_logo:Play()
            t_fade_title:Play()
            t_fade_close:Play()
            t_fade_min:Play()
            t_fade_title.Completed:Wait()
            
            local currentPos = mainFrame.Position
            local t_shrink = TweenService:Create(mainFrame, tweenInfoSmooth, {
                Size = UDim2.new(0, 0, 0, 22),
                Position = UDim2.new(currentPos.X.Scale, currentPos.X.Offset + 60, currentPos.Y.Scale, currentPos.Y.Offset)
            })
            t_shrink:Play()
            t_shrink.Completed:Wait()
            
            mainFrame.Visible = false
            inputFrame.Size = UDim2.new(0, 0, 0, 22)
            inputFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
            inputFrame.Visible = true
            inputBox.PlaceholderText = "Enter search keyword..."
            inputBox.Text = ""
            
            local t_expand = TweenService:Create(inputFrame, tweenInfoBounce, {Size = UDim2.new(0, 160, 0, 75), Position = UDim2.new(0.5, -80, 0.5, -37)})
            t_expand:Play()
            t_expand.Completed:Wait()
            
            TweenService:Create(inputBox, tweenInfoFast, {TextTransparency = 0}):Play()
            TweenService:Create(submitSearchButton, tweenInfoFast, {TextTransparency = 0}):Play()
            TweenService:Create(cancelSearchButton, tweenInfoFast, {TextTransparency = 0}):Play()
            submitSearchButton.Text = "SEARCH"
            TweenService:Create(submitSearchButton.Background, tweenInfoFast, {BackgroundTransparency = 0}):Play()
            TweenService:Create(cancelSearchButton.Background, tweenInfoFast, {BackgroundTransparency = 0}):Play()
            TweenService:Create(submitSearchButton.Background.UIStroke, tweenInfoFast, {Transparency = 0}):Play()
            TweenService:Create(cancelSearchButton.Background.UIStroke, tweenInfoFast, {Transparency = 1}):Play()
        end
    end)

    local function closeGenericPrompt()
        local t_fade = TweenService:Create(inputBox, tweenInfoFast, {TextTransparency = 1})
        t_fade:Play()
        TweenService:Create(submitSearchButton, tweenInfoFast, {TextTransparency = 1}):Play()
        TweenService:Create(cancelSearchButton, tweenInfoFast, {TextTransparency = 1}):Play()
        TweenService:Create(submitSearchButton.Background, tweenInfoFast, {BackgroundTransparency = 1}):Play()
        TweenService:Create(cancelSearchButton.Background, tweenInfoFast, {BackgroundTransparency = 1}):Play()
        TweenService:Create(submitSearchButton.Background.UIStroke, tweenInfoFast, {Transparency = 1}):Play()
        TweenService:Create(cancelSearchButton.Background.UIStroke, tweenInfoFast, {Transparency = 1}):Play()
        t_fade.Completed:Wait()
        
        local t_shrink = TweenService:Create(inputFrame, tweenInfoBounceIn, {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)})
        t_shrink:Play()
        t_shrink.Completed:Wait()
        inputFrame.Visible = false
        
        local currentX = mainFrame.Position.X
        mainFrame.Size = UDim2.new(0, 0, 0, 22)
        mainFrame.Position = UDim2.new(currentX.Scale, currentX.Offset, mainFrame.Position.Y.Scale, mainFrame.Position.Y.Offset)
        mainFrame.Visible = true
        
        local t_grow = TweenService:Create(mainFrame, tweenInfoSmooth, {
            Size = UDim2.new(0, 120, 0, 22),
            Position = UDim2.new(currentX.Scale, currentX.Offset - 60, mainFrame.Position.Y.Scale, mainFrame.Position.Y.Offset)
        })
        t_grow:Play()
        t_grow.Completed:Wait()
        
        local t_fade_logo = TweenService:Create(logo, tweenInfoFast, {ImageTransparency = 0})
        local t_fade_title = TweenService:Create(titleLabel, tweenInfoFast, {TextTransparency = 0})
        local t_fade_close = TweenService:Create(closeButton, tweenInfoFast, {TextTransparency = 0})
        local t_fade_min = TweenService:Create(minimizeButton, tweenInfoFast, {TextTransparency = 0})
        t_fade_logo:Play()
        t_fade_title:Play()
        t_fade_close:Play()
        t_fade_min:Play()
        t_fade_title.Completed:Wait()

        local t_expand = TweenService:Create(mainFrame, tweenInfoSmooth, {Size = UDim2.new(0, 120, 0, 115)})
        t_expand:Play()
        t_expand.Completed:Wait()

        TweenService:Create(speedometerLabel, tweenInfoFast, {TextTransparency = 0}):Play()
        TweenService:Create(statusLabel, tweenInfoFast, {TextTransparency = 0}):Play()
        TweenService:Create(signatureLabel, tweenInfoFast, {TextTransparency = 0.5}):Play()
    end

    submitSearchButton.MouseButton1Click:Connect(function()
        if submitSearchButton.Text == "APPLY" then
            local val = tonumber(inputBox.Text)
            if val then CONFIG.DYNAMIC_SPEED_ADDITIVE = val end
            closeGenericPrompt()
            toggleSpecificBoost("Boost2")
        else
            local keyword = inputBox.Text
            closeGenericPrompt()
            if keyword ~= "" then
                runCustomEspSearch(keyword)
            end
        end
    end)

    cancelSearchButton.MouseButton1Click:Connect(closeGenericPrompt)

    RunService.RenderStepped:Connect(updateSpeedometer)

    closeButton.MouseButton1Click:Connect(function()
        TweenService:Create(speedometerLabel, tweenInfoFast, {TextTransparency = 1}):Play()
        TweenService:Create(statusLabel, tweenInfoFast, {TextTransparency = 1}):Play()
        TweenService:Create(signatureLabel, tweenInfoFast, {TextTransparency = 1}):Play()
        task.wait(0.1)

        local t_retract = TweenService:Create(mainFrame, tweenInfoSmooth, {Size = UDim2.new(0, 120, 0, 22)})
        t_retract:Play()
        t_retract.Completed:Wait()

        local t_fade_logo = TweenService:Create(logo, tweenInfoFast, {ImageTransparency = 1})
        local t_fade_title = TweenService:Create(titleLabel, tweenInfoFast, {TextTransparency = 1})
        local t_fade_close = TweenService:Create(closeButton, tweenInfoFast, {TextTransparency = 1})
        local t_fade_min = TweenService:Create(minimizeButton, tweenInfoFast, {TextTransparency = 1})
        t_fade_logo:Play()
        t_fade_title:Play()
        t_fade_close:Play()
        t_fade_min:Play()
        t_fade_title.Completed:Wait()
        
        local currentPos = mainFrame.Position
        local t_shrink = TweenService:Create(mainFrame, tweenInfoSmooth, {
            Size = UDim2.new(0, 0, 0, 22),
            Position = UDim2.new(currentPos.X.Scale, currentPos.X.Offset + 60, currentPos.Y.Scale, currentPos.Y.Offset)
        })
        t_shrink:Play()
        t_shrink.Completed:Wait()
        
        mainFrame.Visible = false
        confirmFrame.Size = UDim2.new(0, 0, 0, 0)
        confirmFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
        confirmFrame.Visible = true
        
        local t_expand = TweenService:Create(confirmFrame, tweenInfoBounce, {Size = UDim2.new(0, 150, 0, 80), Position = UDim2.new(0.5, -75, 0.5, -40)})
        t_expand:Play()
        t_expand.Completed:Wait()
        
        TweenService:Create(confirmLabel, tweenInfoFast, {TextTransparency = 0}):Play()
        TweenService:Create(yesButton, tweenInfoFast, {TextTransparency = 0}):Play()
        TweenService:Create(noButton, tweenInfoFast, {TextTransparency = 0}):Play()
        TweenService:Create(yesButton.Background, tweenInfoFast, {BackgroundTransparency = 0}):Play()
        TweenService:Create(noButton.Background, tweenInfoFast, {BackgroundTransparency = 0}):Play()
        TweenService:Create(yesButton.Background.UIStroke, tweenInfoFast, {Transparency = 0}):Play()
        TweenService:Create(noButton.Background.UIStroke, tweenInfoFast, {Transparency = 1}):Play()
    end)
    
    yesButton.MouseButton1Click:Connect(function()
        if playerState.isFullbrightActive then toggleFullbright() end
        resetPlayerState()
        
        local t_fade = TweenService:Create(confirmLabel, tweenInfoFast, {TextTransparency = 1})
        t_fade:Play()
        TweenService:Create(yesButton, tweenInfoFast, {TextTransparency = 1}):Play()
        TweenService:Create(noButton, tweenInfoFast, {TextTransparency = 1}):Play()
        TweenService:Create(yesButton.Background, tweenInfoFast, {BackgroundTransparency = 1}):Play()
        TweenService:Create(noButton.Background, tweenInfoFast, {BackgroundTransparency = 1}):Play()
        TweenService:Create(yesButton.Background.UIStroke, tweenInfoFast, {Transparency = 1}):Play()
        TweenService:Create(noButton.Background.UIStroke, tweenInfoFast, {Transparency = 1}):Play()
        t_fade.Completed:Wait()
        
        local t_shrink = TweenService:Create(confirmFrame, tweenInfoBounceIn, {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)})
        t_shrink:Play()
        t_shrink.Completed:Wait()
        
        screenGui:Destroy()
    end)
    
    noButton.MouseButton1Click:Connect(function()
        local t_fade = TweenService:Create(confirmLabel, tweenInfoFast, {TextTransparency = 1})
        t_fade:Play()
        TweenService:Create(yesButton, tweenInfoFast, {TextTransparency = 1}):Play()
        TweenService:Create(noButton, tweenInfoFast, {TextTransparency = 1}):Play()
        TweenService:Create(yesButton.Background, tweenInfoFast, {BackgroundTransparency = 1}):Play()
        TweenService:Create(noButton.Background, tweenInfoFast, {BackgroundTransparency = 1}):Play()
        TweenService:Create(yesButton.Background.UIStroke, tweenInfoFast, {Transparency = 1}):Play()
        TweenService:Create(noButton.Background.UIStroke, tweenInfoFast, {Transparency = 1}):Play()
        t_fade.Completed:Wait()
        
        local t_shrink = TweenService:Create(confirmFrame, tweenInfoBounceIn, {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)})
        t_shrink:Play()
        t_shrink.Completed:Wait()
        confirmFrame.Visible = false
        
        local currentX = mainFrame.Position.X
        mainFrame.Size = UDim2.new(0, 0, 0, 22)
        mainFrame.Position = UDim2.new(currentX.Scale, currentX.Offset, mainFrame.Position.Y.Scale, mainFrame.Position.Y.Offset)
        mainFrame.Visible = true
        
        local t_grow = TweenService:Create(mainFrame, tweenInfoSmooth, {
            Size = UDim2.new(0, 120, 0, 22),
            Position = UDim2.new(currentX.Scale, currentX.Offset - 60, mainFrame.Position.Y.Scale, mainFrame.Position.Y.Offset)
        })
        t_grow:Play()
        t_grow.Completed:Wait()
        
        local t_fade_logo = TweenService:Create(logo, tweenInfoFast, {ImageTransparency = 0})
        local t_fade_title = TweenService:Create(titleLabel, tweenInfoFast, {TextTransparency = 0})
        local t_fade_close = TweenService:Create(closeButton, tweenInfoFast, {TextTransparency = 0})
        local t_fade_min = TweenService:Create(minimizeButton, tweenInfoFast, {TextTransparency = 0})
        t_fade_logo:Play()
        t_fade_title:Play()
        t_fade_close:Play()
        t_fade_min:Play()
        t_fade_title.Completed:Wait()

        local t_expand = TweenService:Create(mainFrame, tweenInfoSmooth, {Size = UDim2.new(0, 120, 0, 115)})
        t_expand:Play()
        t_expand.Completed:Wait()

        TweenService:Create(speedometerLabel, tweenInfoFast, {TextTransparency = 0}):Play()
        TweenService:Create(statusLabel, tweenInfoFast, {TextTransparency = 0}):Play()
        TweenService:Create(signatureLabel, tweenInfoFast, {TextTransparency = 0.5}):Play()
    end)
    
    minimizeButton.MouseButton1Click:Connect(function()
        TweenService:Create(speedometerLabel, tweenInfoFast, {TextTransparency = 1}):Play()
        TweenService:Create(statusLabel, tweenInfoFast, {TextTransparency = 1}):Play()
        TweenService:Create(signatureLabel, tweenInfoFast, {TextTransparency = 1}):Play()
        task.wait(0.1)

        local t_retract = TweenService:Create(mainFrame, tweenInfoSmooth, {Size = UDim2.new(0, 120, 0, 22)})
        t_retract:Play()
        t_retract.Completed:Wait()

        local t_fade_logo = TweenService:Create(logo, tweenInfoFast, {ImageTransparency = 1})
        local t_fade_title = TweenService:Create(titleLabel, tweenInfoFast, {TextTransparency = 1})
        local t_fade_close = TweenService:Create(closeButton, tweenInfoFast, {TextTransparency = 1})
        local t_fade_min = TweenService:Create(minimizeButton, tweenInfoFast, {TextTransparency = 1})
        t_fade_logo:Play()
        t_fade_title:Play()
        t_fade_close:Play()
        t_fade_min:Play()
        t_fade_title.Completed:Wait()
        
        local currentPos = mainFrame.Position
        local t_shrink = TweenService:Create(mainFrame, tweenInfoSmooth, {
            Size = UDim2.new(0, 0, 0, 22),
            Position = UDim2.new(currentPos.X.Scale, currentPos.X.Offset + 60, currentPos.Y.Scale, currentPos.Y.Offset)
        })
        t_shrink:Play()
        t_shrink.Completed:Wait()
        
        mainFrame.Visible = false
        minimizedFrame.Position = UDim2.new(0.5, -30, 0, -50)
        minimizedFrame.Visible = true
        TweenService:Create(minimizedFrame, tweenInfoBounce, {Position = UDim2.new(0.5, -30, 0, 10)}):Play()
        
        if not hasShownMinimizeNotice then
            StarterGui:SetCore("SendNotification", {
                Title = "Script minimized!",
                Text = "Click the button at the top of your screen to maximize.",
                Duration = 5
            })
            hasShownMinimizeNotice = true
        end
    end)

    maximizeButton.MouseButton1Click:Connect(function()
        local t_hide_min = TweenService:Create(minimizedFrame, tweenInfoSmooth, {Position = UDim2.new(0.5, -30, 0, -50)})
        t_hide_min:Play()
        t_hide_min.Completed:Wait()
        minimizedFrame.Visible = false
        
        local currentX = mainFrame.Position.X
        mainFrame.Size = UDim2.new(0, 0, 0, 22)
        mainFrame.Position = UDim2.new(currentX.Scale, currentX.Offset, mainFrame.Position.Y.Scale, mainFrame.Position.Y.Offset)
        mainFrame.Visible = true
        
        local t_grow = TweenService:Create(mainFrame, tweenInfoSmooth, {
            Size = UDim2.new(0, 120, 0, 22),
            Position = UDim2.new(currentX.Scale, currentX.Offset - 60, mainFrame.Position.Y.Scale, mainFrame.Position.Y.Offset)
        })
        t_grow:Play()
        t_grow.Completed:Wait()
        
        local t_fade_logo = TweenService:Create(logo, tweenInfoFast, {ImageTransparency = 0})
        local t_fade_title = TweenService:Create(titleLabel, tweenInfoFast, {TextTransparency = 0})
        local t_fade_close = TweenService:Create(closeButton, tweenInfoFast, {TextTransparency = 0})
        local t_fade_min = TweenService:Create(minimizeButton, tweenInfoFast, {TextTransparency = 0})
        t_fade_logo:Play()
        t_fade_title:Play()
        t_fade_close:Play()
        t_fade_min:Play()
        t_fade_title.Completed:Wait()

        local t_expand = TweenService:Create(mainFrame, tweenInfoSmooth, {Size = UDim2.new(0, 120, 0, 115)})
        t_expand:Play()
        t_expand.Completed:Wait()

        TweenService:Create(speedometerLabel, tweenInfoFast, {TextTransparency = 0}):Play()
        TweenService:Create(statusLabel, tweenInfoFast, {TextTransparency = 0}):Play()
        TweenService:Create(signatureLabel, tweenInfoFast, {TextTransparency = 0.5}):Play()
    end)
    
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == CONFIG.SPEED_1_KEY then toggleSpecificBoost("Boost1")
        elseif input.KeyCode == CONFIG.SPEED_2_KEY then toggleSpecificBoost("Boost2")
        elseif input.KeyCode == CONFIG.LAG_SWITCH_KEY then toggleLagSwitch()
        elseif input.KeyCode == CONFIG.INVISIBILITY_KEY then toggleInvisibility()
        elseif input.KeyCode == CONFIG.FULLBRIGHT_KEY then toggleFullbright()
        elseif input.KeyCode == CONFIG.ESP_CHAMS_KEY then toggleEsp() 
        elseif input.KeyCode == CONFIG.NOCLIP_KEY then toggleNoclip() 
        elseif input.KeyCode == CONFIG.SPEEDOMETER_KEY then toggleSpeedometer()
        elseif input.KeyCode == CONFIG.ZOOM_KEY then toggleZoom()
        elseif input.KeyCode == CONFIG.WARNING_KEY then toggleWarning() 
        elseif input.KeyCode == CONFIG.CUSTOM_ESP_KEY then 
            if playerState.isCustomEspActive then
                toggleCustomEsp()
            end
        elseif input.KeyCode == CONFIG.RESET_KEY then toggleSpawnpoint() end 
    end)
    
    player.CharacterAdded:Connect(function(char)
        resetPlayerState()
        local hum = char:WaitForChild("Humanoid") :: Humanoid
        gameSetSpeed = hum.WalkSpeed
        
        if savedSpawnCFrame then
            local hrp = char:WaitForChild("HumanoidRootPart", 5)
            if hrp then
                task.wait(0.2)
                hrp.CFrame = savedSpawnCFrame
                setButtonActive(resetButton, true)
                resetButton.Text = "SPAWN ON"
            end
        end
    end)
end

local function initialize()
    createGUI()
    randomizeButtonColors()
    connectEvents()
    playStartupAnimation() 
    setupSpeedHook() 
    
    if player.Character then
        local hum = getHumanoid()
        if hum then 
            gameSetSpeed = hum.WalkSpeed
        end
    end
end

initialize()

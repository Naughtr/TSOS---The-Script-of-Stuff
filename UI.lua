--!strict
local TS = game:GetService("TweenService")
local SG = game:GetService("StarterGui")
local Deb = game:GetService("Debris")
local RunService = game:GetService("RunService")

local v3, c3, ud2 = Vector3.new, Color3.fromRGB, UDim2.new
local tFast = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local tBnc = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local tBncIn = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
local tSmth = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

-- New: Smoother snapping transition info
local snapInfo = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

return function(plr, CFG)
    local gui, main, tTabBg, minFrm, cnfFrm, inpFrm, inBox, bSrch, bCnc, bMax, scrl, cScrl, bSpd1, bSpd2, bJmp, bNc, bHb, bLag, bInv, bFb, bEsp, bCesp, bInst, bSpdo, bZm, bWrn, bRst, bCls, bYes, bNo, bMin, sigLbl, stLbl, spdoLbl, logo, tLbl, cnfLbl, ttFrm, ttLbl
    local btns, bOrigClr = {}, {}
    local isAnimating = false

    local function mk(c, p, pr) local i = Instance.new(c); for k,v in pairs(pr or {}) do i[k]=v end; if p then i.Parent=p end; return i end
    
    local function tw(o, i, p, w) 
        local t = TS:Create(o, i, p)
        if w then isAnimating = true end
        t:Play()
        if w then t.Completed:Wait(); isAnimating = false end
        return t 
    end

    -- [Helper functions toStr, pVal, updBClr, stBAct, rndBClr, crStylB remain the same as your source]
    local function toStr(v) if typeof(v)=="Color3" then return math.floor(v.R*255)..","..math.floor(v.G*255)..","..math.floor(v.B*255) elseif typeof(v)=="Vector3" then return v.X..","..v.Y..","..v.Z elseif typeof(v)=="EnumItem" then return v.Name end return tostring(v) end
    local function pVal(o, s) if type(o)=="number" then return tonumber(s) or o elseif type(o)=="string" then return s elseif typeof(o)=="EnumItem" then local sc, r = pcall(function() return Enum.KeyCode[s] end); return sc and r or o elseif typeof(o)=="Color3" then local r,g,b = s:match("(%d+)%s*,%s*(%d+)%s*,%s*(%d+)"); if r then return c3(tonumber(r),tonumber(g),tonumber(b)) end elseif typeof(o)=="Vector3" then local x,y,z = s:match("([%-%d%.]+)%s*,%s*([%-%d%.]+)%s*,%s*([%-%d%.]+)"); if x then return v3(tonumber(x),tonumber(y),tonumber(z)) end end return o end
    local function updBClr(b, c, act) local bg = b:FindFirstChild("Background"); if not bg then return end; bg.BackgroundColor3 = c; local gr = bg:FindFirstChildOfClass("UIGradient"); if gr then gr.Enabled = not act; gr.Color = ColorSequence.new(c, c3(15,15,15)) end; local st = bg:FindFirstChildOfClass("UIStroke"); if st then st.Color = act and c or c3(255,255,255); local sg = st:FindFirstChildOfClass("UIGradient"); if sg then sg.Enabled = not act; local h,s,v = c:ToHSV(); sg.Color = ColorSequence.new(Color3.fromHSV(h, s*0.8, math.min(v*1.4, 1)), c3(0,0,0)) end end end
    local function stBAct(b, act) if act then updBClr(b, Color3.fromHSV(math.random(), 0.75, 0.45), true) elseif bOrigClr[b] then updBClr(b, bOrigClr[b], false) end end
    local function rndBClr() local h = math.random() for _, b in ipairs(btns) do h = (h + 0.618033988749895) % 1; local c = Color3.fromHSV(h, 0.7, 0.4); bOrigClr[b] = c; updBClr(b, c, false) end end
    local function crStylB(p, sz, pos, tx, clr) local b=mk("TextButton", p, {Size=sz, Position=pos, Text=tx, BackgroundTransparency=1, TextColor3=c3(255,255,255), TextTransparency=1, Font=Enum.Font.GothamBold, TextSize=10, ZIndex=2}); local bg=mk("Frame", b, {Name="Background", Size=ud2(1,0,1,0), BackgroundColor3=clr, BackgroundTransparency=1, BorderSizePixel=0, ZIndex=1}); mk("UICorner", bg, {CornerRadius=UDim.new(0,4)}); mk("UIGradient", bg, {Color=ColorSequence.new(clr,c3(15,15,15))}); local str=mk("UIStroke", bg, {Thickness=1, ApplyStrokeMode=Enum.ApplyStrokeMode.Border, Color=c3(255,255,255), Transparency=1}); local h,s,v=clr:ToHSV(); mk("UIGradient", str, {Color=ColorSequence.new(Color3.fromHSV(h,s*0.8,math.min(v*1.4,1)),c3(0,0,0))}); return b end

    -- GUI Initialization
    if plr:WaitForChild("PlayerGui"):FindFirstChild("ToolsGUI") then plr.PlayerGui.ToolsGUI:Destroy() end
    gui = mk("ScreenGui", plr.PlayerGui, {Name="ToolsGUI", ResetOnSpawn=false, IgnoreGuiInset=true, DisplayOrder=9e8})
    
    main = mk("Frame", gui, {Name="MainFrame", Size=ud2(0,0,0,22), Position=ud2(0.5,-60,0.5,-59), BackgroundColor3=CFG.BACKGROUND_COLOR, BorderSizePixel=0, Active=true, Draggable=true, ClipsDescendants=true, Visible=false}); mk("UICorner", main, {CornerRadius=UDim.new(0,8)}); mk("UIStroke", main, {Color=CFG.BORDER_COLOR, Thickness=1, ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
    
    tTabBg = mk("Frame", main, {Name="TitleTabBg", Size=ud2(1,0,0,22), BackgroundColor3=CFG.TAB_COLOR, BorderSizePixel=0}); mk("UICorner", tTabBg, {CornerRadius=UDim.new(0,10)})
    logo=mk("ImageButton", tTabBg, {Name="Logo", Size=ud2(0,12,0,12), AnchorPoint=v3(0,0.5), Position=ud2(0,8,0.5,0), BackgroundTransparency=1, ImageTransparency=1, Image="rbxassetid://10793494685"})
    tLbl=mk("TextLabel", tTabBg, {Name="Title", Size=ud2(1,-40,1,0), AnchorPoint=v3(0,0.5), Position=ud2(0,24,0.5,0), TextTransparency=1, Text="TSOS", BackgroundTransparency=1, TextColor3=c3(255,255,255), Font=Enum.Font.GothamBold, TextSize=10, TextXAlignment=Enum.TextXAlignment.Left})
    bCls=mk("TextButton", tTabBg, {Size=ud2(0,14,0,14), AnchorPoint=v3(0,0.5), Position=ud2(1,-18,0.5,0), Text="×", TextTransparency=1, BackgroundTransparency=1, TextColor3=c3(255,255,255), Font=Enum.Font.GothamBold, TextSize=14}); bMin=mk("TextButton", tTabBg, {Size=ud2(0,14,0,14), AnchorPoint=v3(0,0.5), Position=ud2(1,-34,0.5,0), Text="-", TextTransparency=1, BackgroundTransparency=1, TextColor3=c3(255,255,255), Font=Enum.Font.GothamBold, TextSize=14})

    -- CHANGED: Increased the height of the ScrollingFrame (0, 52) to show more buttons at once
    scrl = mk("ScrollingFrame", main, {Size=ud2(1,-16,0,52), Position=ud2(0,8,0,32), BackgroundColor3=CFG.BACKGROUND_COLOR, ScrollBarThickness=2, ScrollingDirection=Enum.ScrollingDirection.Y, ElasticBehavior=Enum.ElasticBehavior.Always})
    local uiPad = mk("UIPadding", scrl, {PaddingTop=UDim.new(0,4), PaddingBottom=UDim.new(0,4), PaddingLeft=UDim.new(0,2), PaddingRight=UDim.new(0,2)})
    local uiLL = mk("UIListLayout", scrl, {Padding=UDim.new(0,4), HorizontalAlignment=Enum.HorizontalAlignment.Center})
    
    uiLL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrl.CanvasSize = ud2(0, 0, 0, uiLL.AbsoluteContentSize.Y + uiPad.PaddingTop.Offset + uiPad.PaddingBottom.Offset)
    end)

    -- Snapping Logic Implementation
    local lastScrollTimes = {}
    local snapDebounce = {}

    local function handleSnap(f)
        if snapDebounce[f] then return end
        snapDebounce[f] = true
        
        local buttonHeight = 20
        local padding = 4
        local step = buttonHeight + padding
        local topOff = f:FindFirstChildOfClass("UIPadding") and f:FindFirstChildOfClass("UIPadding").PaddingTop.Offset or 0
        
        local currentY = f.CanvasPosition.Y
        -- FIXED: Adjusted snap to include the top padding offset for perfect alignment
        local targetY = math.round((currentY - topOff) / step) * step + topOff
        
        local maxScroll = math.max(0, f.CanvasSize.Y.Offset - f.AbsoluteSize.Y)
        targetY = math.clamp(targetY, 0, maxScroll)
        
        if math.abs(currentY - targetY) > 1 then
            local t = TS:Create(f, snapInfo, {CanvasPosition = Vector2.new(0, targetY)})
            t:Play()
            t.Completed:Wait()
        end
        snapDebounce[f] = false
    end

    -- Monitor scrolling to trigger snap when movement stops
    scrl:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        local t = tick()
        lastScrollTimes[scrl] = t
        task.delay(0.15, function()
            if lastScrollTimes[scrl] == t then
                handleSnap(scrl)
            end
        end)
    end)

    local function sB(nm, tx)
        -- CHANGED: Width to 0.9 to ensure UIStroke isn't cut off by the ScrollBar
        local b=mk("TextButton", scrl, {Name=nm, Size=ud2(0.9,0,0,20), Text=tx, BackgroundTransparency=1, TextColor3=c3(255,255,255), TextTransparency=1, Font=Enum.Font.GothamBold, TextSize=10, ZIndex=2})
        local bg=mk("Frame", b, {Name="Background", Size=ud2(1,0,1,0), BackgroundColor3=c3(45,45,45), BackgroundTransparency=1, BorderSizePixel=0, ZIndex=1})
        mk("UICorner", bg, {CornerRadius=UDim.new(0,4)}); local st=mk("UIStroke", bg, {Thickness=1, ApplyStrokeMode=Enum.ApplyStrokeMode.Border, Color=c3(255,255,255), Transparency=1})
        
        b.MouseButton1Down:Connect(function() if isAnimating then return end tw(b, tFast, {Size=ud2(0.85,0,0,18)}) end)
        local u=function() if isAnimating then return end tw(b, tBnc, {Size=ud2(0.9,0,0,20)}) end; b.MouseButton1Up:Connect(u); b.MouseLeave:Connect(u)
        table.insert(btns, b); return b
    end

    -- Button Generation
    bSpd1,bSpd2,bJmp,bNc,bHb,bLag,bInv,bFb,bEsp,bCesp,bInst,bSpdo,bZm,bWrn,bRst = sB("S1","SPEED BOOST 1"),sB("S2","DYNAMIC SPD"),sB("JP","JUMP POWER"),sB("NC","NOCLIP"),sB("HB","HITBOX OFF"),sB("LS","LAG SWITCH"),sB("IV","INVISIBLE"),sB("FB","FULLBRIGHT"),sB("ESP","ESP CHAMS"),sB("CESP","CUSTOM ESP"),sB("IN","INSTANT INTERACT"),sB("SPD","SPEEDOMETER"),sB("ZM","UNLIMITED ZOOM"),sB("WRN","PROXIMITY WARN"),sB("RST","SET SPAWN")
    
    stLbl=mk("TextLabel", main, {Size=ud2(1,-10,0,12), Position=ud2(0,5,1,-22), Text="Ready", BackgroundTransparency=1, TextColor3=CFG.SECONDARY_TEXT_COLOR, Font=Enum.Font.Gotham, TextSize=8, TextTransparency=1})
    sigLbl=mk("TextLabel", main, {Size=ud2(1,0,0,10), Position=ud2(0,0,1,-10), Text="The Script of Stuffs", BackgroundTransparency=1, TextColor3=CFG.SECONDARY_TEXT_COLOR, Font=Enum.Font.Gotham, TextSize=7, TextTransparency=1})

    -- Final Return API (Truncated for brevity, use your existing UI_API logic)
    return {
        gui=gui, btns=btns, 
        API = {
            playAnim = function()
                main.Visible, main.Size = true, ud2(0,0,0,22)
                tw(main, tSmth, {Size=ud2(0,120,0,124)}, true) -- Increased total height to 124 to fit larger scrl
                tw(logo, tFast, {ImageTransparency=0}); tw(tLbl, tFast, {TextTransparency=0})
            end
        }
    }
end

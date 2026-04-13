--!strict
local TS = game:GetService("TweenService")
local SG = game:GetService("StarterGui")
local Deb = game:GetService("Debris")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")

local v3, c3, ud2 = Vector3.new, Color3.fromRGB, UDim2.new
local tFast = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local tBnc = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local tBncIn = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
local tSmth = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local snapInfo = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

return function(plr, CFG, callbacks)
    local UI = {}
    
    -- GUI Elements
    local gui, main, tTabBg, minFrm, cnfFrm, inpFrm, inBox, bSrch, bCnc, bMax, scrl, cScrl
    local bSpd1, bSpd2, bJmp, bNc, bHb, bLag, bInv, bFb, bEsp, bCesp, bInst, bSpdo, bZm, bWrn, bRst, bJf
    local bCls, bYes, bNo, bMin, sigLbl, stLbl, spdoLbl, logo, tLbl, cnfLbl, ttFrm, ttLbl, bRayfield
    local btns, bOrigClr = {}, {}
    local espHL, espTg, espOff, cEspHL = {}, {}, {}, {}
    local lagPrt, wrnGui = nil, nil
    
    local isAnimating = false
    local lastPos = ud2(0.5,-60,0.5,-59)
    
    -- External UI references
    UI.spdGui = nil
    UI.spdFrame = nil
    UI.spdText = nil
    UI.jfUpGui = nil
    UI.jfUpFrame = nil
    
    local function mk(c, p, pr) local i = Instance.new(c); for k,v in pairs(pr or {}) do i[k]=v end; if p then i.Parent=p end; return i end
    
    local function tw(o, i, p, w) 
        local t = TS:Create(o, i, p)
        if w then isAnimating = true end
        t:Play()
        if w then 
            t.Completed:Wait() 
            isAnimating = false 
        end
        return t 
    end

    local function toStr(v)
        if typeof(v)=="Color3" then return math.floor(v.R*255)..","..math.floor(v.G*255)..","..math.floor(v.B*255)
        elseif typeof(v)=="Vector3" then return v.X..","..v.Y..","..v.Z
        elseif typeof(v)=="EnumItem" then return v.Name end return tostring(v)
    end

    local function pVal(o, s)
        if type(o)=="number" then return tonumber(s) or o
        elseif type(o)=="string" then return s
        elseif typeof(o)=="EnumItem" then local sc, r = pcall(function() return Enum.KeyCode[s] end); return sc and r or o
        elseif typeof(o)=="Color3" then local r,g,b = s:match("(%d+)%s*,%s*(%d+)%s*,%s*(%d+)"); if r then return c3(tonumber(r),tonumber(g),tonumber(b)) end
        elseif typeof(o)=="Vector3" then local x,y,z = s:match("([%-%d%.]+)%s*,%s*([%-%d%.]+)%s*,%s*([%-%d%.]+)"); if x then return v3(tonumber(x),tonumber(y),tonumber(z)) end end
        return o
    end

    local function updBClr(b, c, act)
        local bg = b:FindFirstChild("Background"); if not bg then return end
        bg.BackgroundColor3 = c
        local gr = bg:FindFirstChildOfClass("UIGradient")
        if gr then 
            gr.Enabled = not act
            gr.Color = ColorSequence.new(c, c3(15,15,15)) 
        end
        local st = bg:FindFirstChildOfClass("UIStroke")
        if st then 
            st.Color = act and c or c3(255,255,255)
            local sg = st:FindFirstChildOfClass("UIGradient")
            if sg then 
                sg.Enabled = not act
                local h,s,v = c:ToHSV()
                sg.Color = ColorSequence.new(Color3.fromHSV(h, s*0.8, math.min(v*1.4, 1)), c3(0,0,0)) 
            end
        end
    end

    local function stBAct(b, act) 
        if act then 
            updBClr(b, Color3.fromHSV(math.random(), 0.75, 0.45), true) 
        elseif bOrigClr[b] then 
            updBClr(b, bOrigClr[b], false) 
        end 
    end

    local function rndBClr() 
        local h = math.random() 
        for _, b in ipairs(btns) do 
            h = (h + 0.618033988749895) % 1
            local c = Color3.fromHSV(h, 0.7, 0.4)
            bOrigClr[b] = c
            updBClr(b, c, false) 
        end 
    end
    
    local function crStylB(p, sz, pos, tx, clr)
        local b=mk("TextButton", p, {Size=sz, Position=pos, Text=tx, BackgroundTransparency=1, TextColor3=c3(255,255,255), TextTransparency=1, Font=Enum.Font.GothamBold, TextSize=10, ZIndex=2})
        local bg=mk("Frame", b, {Name="Background", Size=ud2(1,0,1,0), BackgroundColor3=clr, BackgroundTransparency=1, BorderSizePixel=0, ZIndex=1})
        mk("UICorner", bg, {CornerRadius=UDim.new(0,4)}); mk("UIPadding", bg, {PaddingLeft=UDim.new(0,0)}); mk("UIGradient", bg, {Color=ColorSequence.new(clr,c3(15,15,15))})
        local str=mk("UIStroke", bg, {Thickness=1, ApplyStrokeMode=Enum.ApplyStrokeMode.Border, Color=c3(255,255,255), Transparency=1})
        local h,s,v=clr:ToHSV(); mk("UIGradient", str, {Color=ColorSequence.new(Color3.fromHSV(h,s*0.8,math.min(v*1.4,1)),c3(0,0,0))}); return b
    end

    if plr:WaitForChild("PlayerGui"):FindFirstChild("ToolsGUI") then plr.PlayerGui.ToolsGUI:Destroy() end
    gui = mk("ScreenGui", plr.PlayerGui, {Name="ToolsGUI", ResetOnSpawn=false, IgnoreGuiInset=true, DisplayOrder=9e8})
    ttFrm = mk("Frame", gui, {Name="TooltipFrame", BackgroundColor3=CFG.ACCENT_COLOR, BorderSizePixel=0, Visible=false, ZIndex=50, AutomaticSize=Enum.AutomaticSize.XY}); mk("UICorner", ttFrm, {CornerRadius=UDim.new(0,4)}); mk("UIPadding", ttFrm, {PaddingLeft=UDim.new(0,6), PaddingRight=UDim.new(0,6), PaddingTop=UDim.new(0,4), PaddingBottom=UDim.new(0,4)}); mk("UIStroke", ttFrm, {Color=CFG.BORDER_COLOR, Thickness=1}); ttLbl=mk("TextLabel", ttFrm, {BackgroundTransparency=1, TextColor3=CFG.TEXT_COLOR, Font=Enum.Font.Gotham, TextSize=8, AutomaticSize=Enum.AutomaticSize.XY, ZIndex=51})
    main = mk("Frame", gui, {Name="MainFrame", Size=ud2(0,0,0,22), Position=ud2(0.5,-60,0.5,-59), BackgroundColor3=CFG.BACKGROUND_COLOR, BorderSizePixel=0, Active=true, Draggable=true, ClipsDescendants=true, Visible=false}); mk("UICorner", main, {CornerRadius=UDim.new(0,8)}); mk("UIStroke", main, {Color=CFG.BORDER_COLOR, Thickness=1, ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
    minFrm = mk("Frame", gui, {Name="MinimizedFrame", Size=ud2(0,60,0,16), Position=ud2(0.5,-30,0,-50), BackgroundColor3=CFG.TAB_COLOR, BackgroundTransparency=0.85, BorderSizePixel=0, Visible=false}); mk("UICorner", minFrm, {CornerRadius=UDim.new(1,0)}); mk("UIStroke", minFrm, {Color=CFG.BORDER_COLOR, Thickness=1, Transparency=0.8}); bMax=mk("TextButton", minFrm, {Size=ud2(1,0,1,0), BackgroundTransparency=1, Text=""})
    cnfFrm = mk("Frame", gui, {Name="ConfirmFrame", Size=ud2(0,0,0,0), Position=ud2(0.5,0,0.5,0), BackgroundColor3=CFG.BACKGROUND_COLOR, BorderSizePixel=0, Visible=false, ClipsDescendants=true}); mk("UICorner", cnfFrm, {CornerRadius=UDim.new(0,8)}); mk("UIStroke", cnfFrm, {Color=CFG.BORDER_COLOR, Thickness=1}); cnfLbl=mk("TextLabel", cnfFrm, {Size=ud2(1,-10,0,40), Position=ud2(0,5,0,5), BackgroundTransparency=1, Text="Do you want to unload the script?", TextColor3=CFG.TEXT_COLOR, Font=Enum.Font.GothamBold, TextSize=10, TextWrapped=true, TextTransparency=1}); bYes=crStylB(cnfFrm, ud2(0.4,0,0,20), ud2(0.05,0,0.65,0), "YES", c3(231,76,60)); bNo=crStylB(cnfFrm, ud2(0.4,0,0,20), ud2(0.55,0,0.65,0), "NO", CFG.ACCENT_COLOR)
    inpFrm = mk("Frame", gui, {Name="InputFrame", Size=ud2(0,0,0,0), Position=ud2(0.5,0,0.5,0), BackgroundColor3=CFG.BACKGROUND_COLOR, BorderSizePixel=0, Visible=false, ClipsDescendants=true}); mk("UICorner", inpFrm, {CornerRadius=UDim.new(0,8)}); mk("UIStroke", inpFrm, {Color=CFG.BORDER_COLOR, Thickness=1}); inBox=mk("TextBox", inpFrm, {Size=ud2(1,-20,0,25), Position=ud2(0,10,0,10), BackgroundColor3=CFG.ACCENT_COLOR, TextColor3=CFG.TEXT_COLOR, Font=Enum.Font.Gotham, TextSize=10, PlaceholderText="Enter search keyword...", PlaceholderColor3=CFG.SECONDARY_TEXT_COLOR, Text="", TextTransparency=1}); mk("UICorner", inBox, {CornerRadius=UDim.new(0,4)}); mk("UIStroke", inBox, {Color=CFG.BORDER_COLOR, Thickness=1}); bSrch=crStylB(inpFrm, ud2(0.4,0,0,20), ud2(0.05,0,0.60,0), "SEARCH", c3(46,204,113)); bCnc=crStylB(inpFrm, ud2(0.4,0,0,20), ud2(0.55,0,0.60,0), "CANCEL", c3(231,76,60))
    tTabBg = mk("Frame", main, {Name="TitleTabBg", Size=ud2(1,0,0,22), BackgroundColor3=CFG.TAB_COLOR, BorderSizePixel=0}); mk("UICorner", tTabBg, {CornerRadius=UDim.new(0,10)}); mk("Frame", tTabBg, {Name="BottomBorder", Size=ud2(1,0,0,1), Position=ud2(0,0,1,-1), BackgroundColor3=CFG.BORDER_COLOR, BorderSizePixel=0, ZIndex=3}); local tTab=mk("Frame", tTabBg, {Name="TitleTab", Size=ud2(1,0,1,0), BackgroundTransparency=1, BorderSizePixel=0})
    
    logo=mk("ImageButton", tTab, {Name="Logo", Size=ud2(0,12,0,12), AnchorPoint=Vector2.new(0,0.5), Position=ud2(0,8,0.5,0), BackgroundTransparency=1, ImageTransparency=1, Image="rbxassetid://10793494685"})
    tLbl=mk("TextLabel", tTab, {Name="Title", Size=ud2(1,-40,1,0), AnchorPoint=Vector2.new(0,0.5), Position=ud2(0,24,0.5,0), TextTransparency=1, Text="TSOS", BackgroundTransparency=1, TextColor3=c3(255,255,255), Font=Enum.Font.GothamBold, TextSize=10, TextXAlignment=Enum.TextXAlignment.Left})
    
    bCls=mk("TextButton", tTab, {Size=ud2(0,14,0,14), AnchorPoint=Vector2.new(0,0.5), Position=ud2(1,-18,0.5,0), Text="×", TextTransparency=1, BackgroundTransparency=1, TextColor3=c3(255,255,255), Font=Enum.Font.GothamBold, TextSize=14, BorderSizePixel=0}); bMin=mk("TextButton", tTab, {Size=ud2(0,14,0,14), AnchorPoint=Vector2.new(0,0.5), Position=ud2(1,-34,0.5,0), Text="-", TextTransparency=1, BackgroundTransparency=1, TextColor3=c3(255,255,255), Font=Enum.Font.GothamBold, TextSize=14, BorderSizePixel=0})
    
    scrl = mk("ScrollingFrame", main, {Size=ud2(1,-16,0,52), Position=ud2(0,8,0,36), BackgroundColor3=CFG.BACKGROUND_COLOR, ScrollBarThickness=2, CanvasSize=ud2(0,0,0,0), ScrollingDirection=Enum.ScrollingDirection.Y, ElasticBehavior=Enum.ElasticBehavior.Always})
    local uiPad = mk("UIPadding", scrl, {PaddingTop=UDim.new(0,4), PaddingBottom=UDim.new(0,4)})
    local uiLL = mk("UIListLayout", scrl, {Padding=UDim.new(0,4), HorizontalAlignment=Enum.HorizontalAlignment.Center})
    
    uiLL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scrl.CanvasSize = ud2(0, 0, 0, uiLL.AbsoluteContentSize.Y + 10)
    end)

    cScrl = mk("ScrollingFrame", main, {Name="ConfigFrame", Size=ud2(1,-16,0,52), Position=ud2(0,8,0,36), BackgroundColor3=CFG.BACKGROUND_COLOR, ScrollBarThickness=2, CanvasSize=ud2(0,0,0,0), Visible=false, ScrollingDirection=Enum.ScrollingDirection.Y, ElasticBehavior=Enum.ElasticBehavior.Always}); local cfLL=mk("UIListLayout", cScrl, {Padding=UDim.new(0,4), HorizontalAlignment=Enum.HorizontalAlignment.Center}); mk("UIPadding", cScrl, {PaddingTop=UDim.new(0,4), PaddingBottom=UDim.new(0,4)})
    local sNm={SPEED_1_KEY="SPD 1",SPEED_2_KEY="SPD 2",LAG_SWITCH_KEY="LAG KEY",INVISIBILITY_KEY="INVIS",FULLBRIGHT_KEY="F-BRIGHT",ESP_CHAMS_KEY="ESP KEY",RESET_KEY="RESET",NOCLIP_KEY="NOCLIP",SPEEDOMETER_KEY="SPEEDO",ZOOM_KEY="ZOOM",WARNING_KEY="WARN",CUSTOM_ESP_KEY="C-ESP",BOOSTED_SPEED_1="BST SPD 1",DYNAMIC_SPEED_ADDITIVE="DYN ADD",DEFAULT_JUMP="DEF JUMP",BOOSTED_JUMP="BST JUMP",HITBOX_SIZE="HB SIZE",MAX_ZOOM="MAX ZM",MIN_ZOOM="MIN ZM",WARNING_DISTANCE="WARN DIST",INVISIBILITY_POSITION="INVIS POS",RESET_COOLDOWN="RST CD",BACKGROUND_COLOR="BG CLR",ACCENT_COLOR="ACC CLR",TAB_COLOR="TAB CLR",BORDER_COLOR="BRDR CLR",TEXT_COLOR="TXT CLR",SECONDARY_TEXT_COLOR="SEC TXT",ESP_MAX_DISTANCE="ESP MAX",ESP_NEAR_DISTANCE="ESP NEAR",JITTER_SPEED="JF SPEED",JITTER_DURATION="JF DUR",LAG_SWITCH_SPEED="LAG SPD"}
    local pK, oK = {"BOOSTED_SPEED_1","DYNAMIC_SPEED_ADDITIVE","DEFAULT_JUMP","BOOSTED_JUMP","HITBOX_SIZE","MAX_ZOOM","MIN_ZOOM","WARNING_DISTANCE","JITTER_SPEED","JITTER_DURATION","LAG_SWITCH_SPEED"}, {}; for k,_ in pairs(CFG) do if not table.find(pK,k) then table.insert(oK,k) end end; table.sort(oK); local sk={}; for _,k in ipairs(pK) do table.insert(sk,k) end; for _,k in ipairs(oK) do table.insert(sk,k) end
    for _, k in ipairs(sk) do local r=mk("Frame", cScrl, {Size=ud2(0.92,0,0,20), BackgroundTransparency=1}); local l=mk("TextLabel", r, {Size=ud2(0.5,0,1,0), BackgroundTransparency=1, Text=sNm[k] or k, TextColor3=CFG.TEXT_COLOR, TextXAlignment=Enum.TextXAlignment.Center, Font=Enum.Font.Gotham, TextSize=7, TextTransparency=1, Active=true})
        local showTt=function() ttLbl.Text=k; ttFrm.AnchorPoint=Vector2.new(0.5,1); ttFrm.Position=ud2(0,tTabBg.AbsolutePosition.X+(tTabBg.AbsoluteSize.X/2),0,tTabBg.AbsolutePosition.Y-5); ttFrm.Visible=true end; l.MouseEnter:Connect(showTt); l.MouseLeave:Connect(function() ttFrm.Visible=false end); l.InputBegan:Connect(function(ip) if ip.UserInputType==Enum.UserInputType.Touch then showTt() end end); l.InputEnded:Connect(function(ip) if ip.UserInputType==Enum.UserInputType.Touch then ttFrm.Visible=false end end)
        local bb=mk("Frame", r, {Size=ud2(0.5,-4,1,0), Position=ud2(0.5,2,0,0), BackgroundColor3=CFG.ACCENT_COLOR, BackgroundTransparency=1, BorderSizePixel=0, ClipsDescendants=true}); mk("UICorner", bb, {CornerRadius=UDim.new(0,4)}); mk("UIStroke", bb, {Color=CFG.BORDER_COLOR, Thickness=1, Transparency=1}); local bx=mk("TextBox", bb, {Size=ud2(1,-4,1,0), Position=ud2(0,2,0,0), BackgroundTransparency=1, Text=toStr(CFG[k]), TextColor3=CFG.SECONDARY_TEXT_COLOR, Font=Enum.Font.Gotham, TextSize=7, TextTransparency=1, ClearTextOnFocus=false, ClipsDescendants=true})
        bx.FocusLost:Connect(function() local pv=pVal(CFG[k], bx.Text); CFG[k]=pv; bx.Text=toStr(pv) end) end
    cfLL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() cScrl.CanvasSize=ud2(0,0,0,cfLL.AbsoluteContentSize.Y+10) end)
    
    -- Rayfield Switch Button
    bRayfield = crStylB(cScrl, ud2(0.92,0,0,20), ud2(0,0,0,0), "Switch to Rayfield", c3(142, 68, 173))
    bRayfield.LayoutOrder = 1000
    
    local function sB(nm, tx)
        local b=mk("TextButton", scrl, {Name=nm, Size=ud2(0.92,0,0,20), Text=tx, BackgroundTransparency=1, TextColor3=c3(255,255,255), TextTransparency=1, Font=Enum.Font.GothamBold, TextSize=10, ZIndex=2})
        local bg=mk("Frame", b, {Name="Background", Size=ud2(1,0,1,0), BackgroundColor3=c3(45,45,45), BackgroundTransparency=1, BorderSizePixel=0, ZIndex=1})
        mk("UICorner", bg, {CornerRadius=UDim.new(0,4)}); mk("UIPadding", bg, {PaddingLeft=UDim.new(0,0)}); mk("UIGradient", bg, {Rotation=0}); local st=mk("UIStroke", bg, {Thickness=1, ApplyStrokeMode=Enum.ApplyStrokeMode.Border, Color=c3(255,255,255), Transparency=1}); mk("UIGradient", st, {Rotation=0})
        b.MouseButton1Down:Connect(function() if isAnimating then return end tw(b, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size=ud2(0.85,0,0,18)}) end)
        local u=function() if isAnimating then return end tw(b, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size=ud2(0.92,0,0,20)}) end; b.MouseButton1Up:Connect(u); b.MouseLeave:Connect(u); table.insert(btns, b); return b
    end

    bSpd1,bSpd2,bJmp,bNc,bHb,bLag,bInv,bFb,bEsp,bCesp,bInst,bSpdo,bZm,bWrn,bRst,bJf = sB("S1","SPEED BOOST 1"),sB("S2","DYNAMIC SPD"),sB("JP","JUMP POWER"),sB("NC","NOCLIP"),sB("HB","HITBOX OFF"),sB("LS","LAG SWITCH"),sB("IV","INVISIBLE"),sB("FB","FULLBRIGHT"),sB("ESP","ESP CHAMS"),sB("CESP","CUSTOM ESP"),sB("IN","INSTANT INTERACT"),sB("SPD","SPEEDOMETER"),sB("ZM","UNLIMITED ZOOM"),sB("WRN","PROXIMITY WARN"),sB("RST","SET SPAWN"),sB("JF","JITTER FLY")
    spdoLbl=mk("TextLabel", main, {Size=ud2(1,-10,0,12), Position=ud2(0,5,1,-34), Text="Speed: 0 studs/s", BackgroundTransparency=1, TextColor3=c3(255,255,255), Font=Enum.Font.GothamBold, TextSize=8, TextTransparency=1, Visible=false})
    stLbl=mk("TextLabel", main, {Size=ud2(1,-10,0,12), Position=ud2(0,5,1,-22), Text="Ready", BackgroundTransparency=1, TextColor3=CFG.SECONDARY_TEXT_COLOR, Font=Enum.Font.Gotham, TextSize=8, TextTransparency=1})
    sigLbl=mk("TextLabel", main, {Size=ud2(1,0,0,10), Position=ud2(0,0,1,-10), Text="The Script of Stuffs", BackgroundTransparency=1, TextColor3=CFG.SECONDARY_TEXT_COLOR, Font=Enum.Font.Gotham, TextSize=7, TextTransparency=1})

    -- Scroll Snapping
    local lastScrollTimes = {}
    local snapDebounce = {}

    local function handleSnap(f)
        if snapDebounce[f] then return end
        snapDebounce[f] = true
        
        local buttonHeight = 20
        local padding = 4
        local step = buttonHeight + padding
        
        local currentY = f.CanvasPosition.Y
        local targetY = math.round(currentY / step) * step
        
        local maxScroll = math.max(0, f.CanvasSize.Y.Offset - f.AbsoluteSize.Y)
        local maxSnapY = math.max(0, math.floor(maxScroll / step) * step)
        
        targetY = math.clamp(targetY, 0, maxSnapY)
        
        if math.abs(currentY - targetY) > 0.5 then
            local twSnap = TS:Create(f, snapInfo, {CanvasPosition = Vector2.new(0, targetY)})
            twSnap:Play()
            twSnap.Completed:Wait()
        end
        snapDebounce[f] = false
    end

    for _, f in ipairs({scrl, cScrl}) do
        snapDebounce[f] = false
        f:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
            if snapDebounce[f] then return end
            local t = tick()
            lastScrollTimes[f] = t
            task.delay(0.15, function()
                if lastScrollTimes[f] == t then
                    handleSnap(f)
                end
            end)
        end)
    end

    local function shwUi(vis, mSzX, mSzY) main.Visible=vis; if vis then tw(main, tSmth, {Size=ud2(0,mSzX,0,mSzY)}, true) end end
    local function fdMnu(a, c) tw(logo, tFast, {ImageTransparency=a}); tw(tLbl, tFast, {TextTransparency=a}); tw(bCls, tFast, {TextTransparency=a}); tw(bMin, tFast, {TextTransparency=a}, c) end
    local function setA(a) tw(spdoLbl,tFast,{TextTransparency=a}); tw(stLbl,tFast,{TextTransparency=a}); tw(sigLbl,tFast,{TextTransparency=a==0 and 0.5 or 1}) end
    local function trnMnu(f, s1, t, s2) setA(1); task.wait(0.1); tw(main, tSmth, {Size=ud2(0,120,0,22)}, true); fdMnu(1, true); local cp=main.Position; tw(main, tSmth, {Size=ud2(0,0,0,22), Position=ud2(cp.X.Scale, cp.X.Offset+60, cp.Y.Scale, cp.Y.Offset)}, true); main.Visible=false; if t then t.Size, t.Position, t.Visible = ud2(0,0,0, t==cnfFrm and 0 or 22), ud2(0.5,0,0.5,0), true; tw(t, tBnc, {Size=s2, Position=ud2(0.5, -s2.X.Offset/2, 0.5, -s2.Y.Offset/2)}, true) end end
    
    local function unTrn(t) tw(t, tBncIn, {Size=ud2(0,0,0,0), Position=ud2(0.5,0,0.5,0)}, true); t.Visible=false; local cx=lastPos.X; main.Size, main.Position, main.Visible = ud2(0,0,0,22), ud2(cx.Scale,cx.Offset+60,lastPos.Y.Scale,lastPos.Y.Offset), true; tw(main, tSmth, {Size=ud2(0,120,0,22), Position=lastPos}, true); fdMnu(0, true); shwUi(true, 120, 118); setA(0) end
    local function tgBtns(a, d) for _,b in ipairs(btns) do tw(b, tFast, {TextTransparency=a}); local bg=b:FindFirstChild("Background"); if bg then tw(bg, tFast, {BackgroundTransparency=a}); local st=bg:FindFirstChildOfClass("UIStroke"); if st then tw(st, tFast, {Transparency=a}) end end; if d then task.wait(d) end end end
    local function tgCfg(a) for _,r in ipairs(cScrl:GetChildren()) do if r:IsA("Frame") then local l,bg=r:FindFirstChildOfClass("TextLabel"),r:FindFirstChild("Frame"); if l then tw(l,tFast,{TextTransparency=a}) end; if bg then tw(bg,tFast,{BackgroundTransparency=a}); local s,bx=bg:FindFirstChildOfClass("UIStroke"),bg:FindFirstChildOfClass("TextBox"); if s then tw(s,tFast,{Transparency=a}) end; if bx then tw(bx,tFast,{TextTransparency=a}) end end end end; if bRayfield then tw(bRayfield, tFast, {TextTransparency=a}); local bg=bRayfield:FindFirstChild("Background"); if bg then tw(bg,tFast,{BackgroundTransparency=a}) end; local st=bRayfield:FindFirstChildOfClass("UIStroke"); if st then tw(st,tFast,{Transparency=a}) end end end end
    local function cnfEx(v) tw(cnfLbl,tFast,{TextTransparency=v}); tw(bYes,tFast,{TextTransparency=v}); tw(bNo,tFast,{TextTransparency=v}); tw(bYes.Background,tFast,{BackgroundTransparency=v}); tw(bNo.Background,tFast,{BackgroundTransparency=v}); tw(bYes.Background.UIStroke,tFast,{Transparency=v}); tw(bNo.Background.UIStroke,tFast,{Transparency=v==0 and 1 or 1}) end
    local function inEx(v) tw(inBox,tFast,{TextTransparency=v}); tw(bSrch,tFast,{TextTransparency=v}); tw(bCnc,tFast,{TextTransparency=v}); tw(bSrch.Background,tFast,{BackgroundTransparency=v}); tw(bCnc.Background,tFast,{BackgroundTransparency=v}); tw(bSrch.Background.UIStroke,tFast,{Transparency=v}); tw(bCnc.Background.UIStroke,tFast,{Transparency=1}) end

    --[[ SPEEDOMETER UI CREATION ]]--
    function UI.createSpeedometerUI(existingPos)
        if UI.spdGui then 
            UI.spdGui:Destroy() 
            UI.spdGui = nil
            UI.spdFrame = nil
            UI.spdText = nil
        end
        
        UI.spdGui = mk("ScreenGui", plr:WaitForChild("PlayerGui"), {Name="TSOS_Speedometer", ResetOnSpawn=false, IgnoreGuiInset=true, DisplayOrder=100000, ZIndexBehavior=Enum.ZIndexBehavior.Global})
        
        UI.spdFrame = mk("TextButton", UI.spdGui, {Name="SpeedFrame", Size=ud2(0,140,0,28), Position=existingPos or ud2(0.5,-70,0,8), BackgroundColor3=CFG.BACKGROUND_COLOR, BackgroundTransparency=0.15, BorderSizePixel=0, Visible=false, ZIndex=100000, Text="", AutoButtonColor=false})
        
        local corner = mk("UICorner", UI.spdFrame, {CornerRadius=UDim.new(0,6)})
        local stroke = mk("UIStroke", UI.spdFrame, {Color=CFG.ACCENT_COLOR, Thickness=1, Transparency=0.3, ZIndex=100001})
        local shadow = mk("ImageLabel", UI.spdFrame, {Name="Shadow", Size=ud2(1,6,1,6), Position=ud2(0,-3,0,-3), BackgroundTransparency=1, Image="rbxassetid://5587865193", ImageColor3=Color3.new(0,0,0), ImageTransparency=0.6, ScaleType=Enum.ScaleType.Slice, SliceCenter=Rect.new(10,10,118,118), ZIndex=99999})
        
        UI.spdText = mk("TextLabel", UI.spdFrame, {Name="SpeedText", Size=ud2(1,0,1,0), BackgroundTransparency=1, Text="Speed: 0 studs/s", TextColor3=CFG.TEXT_COLOR, Font=Enum.Font.GothamBold, TextSize=12, ZIndex=100002})
        
        -- Drag handling (internal)
        local spdDragging = false
        local spdDragInput, spdDragStart, spdStartPos
        
        UI.spdFrame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                spdDragging = true
                spdDragStart = input.Position
                local viewport = workspace.CurrentCamera.ViewportSize
                local currentAbsX = UI.spdFrame.Position.X.Scale * viewport.X + UI.spdFrame.Position.X.Offset
                local currentAbsY = UI.spdFrame.Position.Y.Scale * viewport.Y + UI.spdFrame.Position.Y.Offset
                spdStartPos = UDim2.new(0, currentAbsX, 0, currentAbsY)
                
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        spdDragging = false
                    end
                end)
            end
        end)

        UI.spdFrame.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                spdDragInput = input
            end
        end)
        
        game:GetService("UserInputService").InputChanged:Connect(function(input)
            if spdDragging and input == spdDragInput then
                local delta = input.Position - spdDragStart
                local newX = spdStartPos.X.Offset + delta.X
                local newY = spdStartPos.Y.Offset + delta.Y
                local viewport = workspace.CurrentCamera.ViewportSize
                newX = math.clamp(newX, 0, math.max(0, viewport.X - 140))
                newY = math.clamp(newY, 0, math.max(0, viewport.Y - 28))
                UI.spdFrame.Position = UDim2.new(0, newX, 0, newY)
            end
        end)
        
        return UI.spdGui, UI.spdFrame, UI.spdText
    end
    
    --[[ JITTER FLY UI CREATION ]]--
    function UI.createJitterUpUI(activateCallback)
        if UI.jfUpGui then
            UI.jfUpGui:Destroy()
            UI.jfUpGui = nil
            UI.jfUpFrame = nil
        end
        
        UI.jfUpGui = mk("ScreenGui", plr:WaitForChild("PlayerGui"), {Name="TSOS_JitterUp", ResetOnSpawn=false, IgnoreGuiInset=true, DisplayOrder=999999999, ZIndexBehavior=Enum.ZIndexBehavior.Global})
        
        UI.jfUpFrame = mk("TextButton", UI.jfUpGui, {Name="JitterUpFrame", Size=ud2(0,120,0,50), Position=ud2(1,-130,0.5,-25), BackgroundColor3=c3(46,204,113), BackgroundTransparency=0.1, BorderSizePixel=0, Visible=true, ZIndex=10, Text="UP", TextColor3=CFG.TEXT_COLOR, Font=Enum.Font.GothamBold, TextSize=16, AutoButtonColor=false})
        
        mk("UICorner", UI.jfUpFrame, {CornerRadius=UDim.new(0,8)})
        mk("UIStroke", UI.jfUpFrame, {Color=CFG.BORDER_COLOR, Thickness=2})
        
        UI.jfUpFrame.MouseButton1Click:Connect(function()
            UI.jfUpFrame.BackgroundColor3 = c3(231,76,60)
            task.delay(0.1, function()
                UI.jfUpFrame.BackgroundColor3 = c3(46,204,113)
            end)
            if activateCallback then activateCallback() end
        end)
        
        return UI.jfUpGui, UI.jfUpFrame
    end
    
    function UI.destroyJitterUI()
        if UI.jfUpGui then
            UI.jfUpGui:Destroy()
            UI.jfUpGui = nil
            UI.jfUpFrame = nil
        end
    end
    
    --[[ RAYFIELD INTEGRATION ]]--
    function UI.loadRayfield(onSuccess, onFail, currentState, toggleFuncs)
        local success, RayfieldLibrary = pcall(function()
            return loadstring(game:HttpGet('https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/refs/heads/main/source.lua'))()
        end)
        
        if not success or typeof(RayfieldLibrary) ~= "table" then
            warn("Rayfield Load Failed: " .. tostring(RayfieldLibrary))
            if onFail then onFail() end
            return nil
        end
        
        if not RayfieldLibrary.CreateWindow then
            warn("Rayfield loaded but CreateWindow not found!")
            if onFail then onFail() end
            return nil
        end
        
        local winSuccess, Window = pcall(function()
            return RayfieldLibrary:CreateWindow({
                Name = "TSOS - Rayfield Edition",
                LoadingTitle = "The Script of Stuffs",
                LoadingSubtitle = "Loading Rayfield Interface...",
                ConfigurationSaving = {Enabled = false},
                KeySystem = false,
            })
        end)
        
        if not winSuccess or not Window then
            warn("Failed to create Rayfield window: " .. tostring(Window))
            if onFail then onFail() end
            return nil
        end
        
        _G.TSOS_RayfieldLibrary = RayfieldLibrary
        
        local MovementTab = Window:CreateTab("Movement", "bolt")
        local CombatTab = Window:CreateTab("Combat", "crosshair")
        local PlayerTab = Window:CreateTab("Player", "user")
        local VisualsTab = Window:CreateTab("Visuals", "eye")
        local SettingsTab = Window:CreateTab("Settings", "settings")
        
        -- Movement Tab
        MovementTab:CreateSection("Speed Boosts")
        MovementTab:CreateToggle({Name = "Speed Boost 1", CurrentValue = currentState.bst == "Boost1", Flag = "RF_Spd1", 
            Callback = function(v) if toggleFuncs.speed1 then toggleFuncs.speed1(v) end end})
        MovementTab:CreateInput({Name = "Dynamic Speed Additive", CurrentValue = tostring(CFG.DYNAMIC_SPEED_ADDITIVE or 5), PlaceholderText = "5", RemoveTextAfterFocusLost = false, Flag = "RF_DynVal",
            Callback = function(Text) local n = tonumber(Text) if n then CFG.DYNAMIC_SPEED_ADDITIVE = n end end})
        MovementTab:CreateToggle({Name = "Speed Boost 2 (Dynamic)", CurrentValue = currentState.bst == "Boost2", Flag = "RF_Spd2", 
            Callback = function(v) if toggleFuncs.speed2 then toggleFuncs.speed2(v) end end})
        
        MovementTab:CreateSection("Movement Features")
        MovementTab:CreateToggle({Name = "Jump Power Boost", CurrentValue = currentState.jmp, Flag = "RF_Jump",
            Callback = function(v) if toggleFuncs.jump then toggleFuncs.jump(v) end end})
        MovementTab:CreateToggle({Name = "Noclip", CurrentValue = currentState.nc, Flag = "RF_Noclip",
            Callback = function(v) if toggleFuncs.noclip then toggleFuncs.noclip(v) end end})
        MovementTab:CreateToggle({Name = "Speedometer", CurrentValue = currentState.spdo, Flag = "RF_Spdo",
            Callback = function(v) if toggleFuncs.speedo then toggleFuncs.speedo(v) end end})
        
        MovementTab:CreateSection("Jitter Fly")
        MovementTab:CreateToggle({Name = "Jitter Fly Mode", CurrentValue = currentState.jf, Flag = "RF_JitterFly",
            Callback = function(v) if toggleFuncs.jitter then toggleFuncs.jitter(v) end end})
        MovementTab:CreateParagraph({Title = "Jitter Fly Info", Content = "External 'UP' button appears when enabled. Spam click for instant nanosecond micro-hops ("..tostring(CFG.JITTER_DURATION or 0.001).."s duration). Speed: "..tostring(CFG.JITTER_SPEED or 1)})
        
        -- Combat Tab
        CombatTab:CreateSection("Combat Features")
        local hbOptions = {"Off", "On (No ESP)", "On (With ESP)"}
        local hbCurrent = currentState.hb == 0 and "Off" or (currentState.hb == 1 and "On (No ESP)" or "On (With ESP)")
        CombatTab:CreateDropdown({Name = "Hitbox Expander", Options = hbOptions, CurrentOption = hbCurrent, MultipleOptions = false, Flag = "RF_Hitbox",
            Callback = function(opt) if toggleFuncs.hitbox then toggleFuncs.hitbox(opt) end end})
        CombatTab:CreateToggle({Name = "Lag Switch", CurrentValue = currentState.lag, Flag = "RF_Lag",
            Callback = function(v) if toggleFuncs.lag then toggleFuncs.lag(v) end end})
        
        -- Player Tab
        PlayerTab:CreateSection("Character Mods")
        PlayerTab:CreateToggle({Name = "Invisibility", CurrentValue = currentState.inv, Flag = "RF_Invis",
            Callback = function(v) if toggleFuncs.invis then toggleFuncs.invis(v) end end})
        PlayerTab:CreateToggle({Name = "Fullbright", CurrentValue = currentState.fb, Flag = "RF_Fb",
            Callback = function(v) if toggleFuncs.fullbright then toggleFuncs.fullbright(v) end end})
        PlayerTab:CreateToggle({Name = "Instant Interact", CurrentValue = currentState.inst, Flag = "RF_Inst",
            Callback = function(v) if toggleFuncs.inst then toggleFuncs.inst(v) end end})
        PlayerTab:CreateToggle({Name = "Unlimited Zoom", CurrentValue = currentState.zm, Flag = "RF_Zoom",
            Callback = function(v) if toggleFuncs.zoom then toggleFuncs.zoom(v) end end})
        PlayerTab:CreateToggle({Name = "Proximity Warning", CurrentValue = currentState.wrn, Flag = "RF_Warn",
            Callback = function(v) if toggleFuncs.warn then toggleFuncs.warn(v) end end})
        PlayerTab:CreateButton({Name = "Set Spawn Point", Callback = function() if toggleFuncs.spawn then toggleFuncs.spawn() end end})
        
        -- Visuals Tab
        VisualsTab:CreateSection("ESP Controls")
        local espOptions = {"Off", "All Players", "Enemy Off-Screen", "Names & Distance", "Chams Only"}
        local espCurrent = currentState.esp == 0 and "Off" or (currentState.esp == 1 and "All Players" or currentState.esp == 2 and "Enemy Off-Screen" or currentState.esp == 3 and "Names & Distance" or "Chams Only")
        VisualsTab:CreateDropdown({Name = "ESP Mode", Options = espOptions, CurrentOption = espCurrent, MultipleOptions = false, Flag = "RF_EspMode",
            Callback = function(opt) if toggleFuncs.esp then toggleFuncs.esp(opt) end end})
        
        VisualsTab:CreateSection("Custom ESP")
        local cespInput = VisualsTab:CreateInput({Name = "Search Keyword", CurrentValue = currentState.kw or "", PlaceholderText = "player, crate, etc", RemoveTextAfterFocusLost = false, Flag = "RF_CespKw"})
        VisualsTab:CreateButton({Name = "Activate Custom ESP", Callback = function() if toggleFuncs.cesp then toggleFuncs.cesp(cespInput.CurrentValue or "") end end})
        VisualsTab:CreateButton({Name = "Clear Custom ESP", Callback = function() if toggleFuncs.clearCesp then toggleFuncs.clearCesp() end end})
        
        -- Settings Tab with Switch Back button
        SettingsTab:CreateSection("UI Options")
        SettingsTab:CreateButton({
            Name = "Switch to Custom UI",
            Callback = function()
                local TweenService = game:GetService("TweenService")
                local RayfieldGui = CoreGui:FindFirstChild("Rayfield") or (gethui and gethui():FindFirstChild("Rayfield"))
                
                if not RayfieldGui then
                    _G.TSOS_RayfieldLoaded = false
                    _G.TSOS_RayfieldLibrary = nil
                    if toggleFuncs.showCustom then toggleFuncs.showCustom() end
                    return
                end
                
                local Main = RayfieldGui:FindFirstChild("Main")
                if Main then
                    for _, child in ipairs(Main:GetDescendants()) do
                        if child:IsA("Frame") then
                            TweenService:Create(child, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play()
                            local stroke = child:FindFirstChildOfClass("UIStroke")
                            if stroke then TweenService:Create(stroke, TweenInfo.new(0.25), {Transparency = 1}):Play() end
                        elseif child:IsA("TextLabel") or child:IsA("TextBox") or child:IsA("TextButton") then
                            TweenService:Create(child, TweenInfo.new(0.2), {TextTransparency = 1, BackgroundTransparency = 1}):Play()
                        elseif child:IsA("ImageLabel") or child:IsA("ImageButton") then
                            TweenService:Create(child, TweenInfo.new(0.25), {ImageTransparency = 1, BackgroundTransparency = 1}):Play()
                        elseif child:IsA("ScrollingFrame") then
                            TweenService:Create(child, TweenInfo.new(0.25), {BackgroundTransparency = 1, ScrollBarImageTransparency = 1}):Play()
                        end
                    end
                    
                    TweenService:Create(Main, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {BackgroundTransparency = 1}):Play()
                    local Topbar = Main:FindFirstChild("Topbar")
                    if Topbar then TweenService:Create(Topbar, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play() end
                    TweenService:Create(Main, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Size = ud2(0,495,0,45)}):Play()
                end
                
                task.wait(0.3)
                RayfieldGui:Destroy()
                _G.TSOS_RayfieldLoaded = false
                _G.TSOS_RayfieldLibrary = nil
                
                if toggleFuncs.showCustom then toggleFuncs.showCustom() end
                
                pcall(function()
                    game:GetService("StarterGui"):SetCore("SendNotification", {
                        Title = "UI Switched", Text = "Returned to Custom UI!", Duration = 3
                    })
                end)
            end
        })
        
        if onSuccess then onSuccess() end
        return Window
    end

    UI.API = {
        playAnim = function()
            if isAnimating then return end
            local s=mk("TextLabel", gui, {Size=ud2(1,0,1,0), BackgroundTransparency=1, Text="TSOS", TextColor3=c3(255,255,255), Font=Enum.Font.GothamBold, TextSize=100, ZIndex=100}); task.wait(4); tw(s, tFast, {TextTransparency=1}, true); s:Destroy()
            main.Visible, main.Size, main.Position = true, ud2(0,0,0,22), ud2(0.5,0,0.5,-59); tw(main, tSmth, {Size=ud2(0,120,0,22), Position=ud2(0.5,-60,0.5,-59)}, true); fdMnu(0, true); shwUi(true, 120, 118); tgBtns(0, 0.05); setA(0)
        end,

        toggleConfigMenu = function(isOpen)
            if isAnimating then return end
            tw(logo, tBnc, {Rotation=logo.Rotation+360}); setA(1); task.wait(0.1)
            isAnimating = true 
            if not isOpen then tgCfg(1); task.wait(0.15); tw(main, tSmth, {Size=ud2(0,120,0,22)}, true); cScrl.Visible, scrl.Visible = false, true; shwUi(true, 120, 115); tgBtns(0)
            else tgBtns(1); task.wait(0.15); tw(main, tSmth, {Size=ud2(0,120,0,22)}, true); scrl.Visible, cScrl.Visible = false, true; shwUi(true, 120, 115); tgCfg(0) end; setA(0)
            isAnimating = false
        end,

        minimize = function(onComplete, skipMinimizeButton)
            if isAnimating then 
                if onComplete then task.defer(onComplete) end
                return 
            end
            lastPos = main.Position
            bMin.Visible, bCls.Visible = false, false 
            
            if skipMinimizeButton then
                setA(1)
                task.wait(0.1)
                tw(main, tSmth, {Size=ud2(0,120,0,22)}, true)
                fdMnu(1, true)
                local cp=main.Position
                tw(main, tSmth, {Size=ud2(0,0,0,22), Position=ud2(cp.X.Scale, cp.X.Offset+60, cp.Y.Scale, cp.Y.Offset)}, true)
                main.Visible=false
                if onComplete then task.defer(onComplete) end
            else
                trnMnu(scrl, nil, nil, nil)
                minFrm.Position, minFrm.Visible = ud2(0.5,-30,0,-50), true
                tw(minFrm, tBnc, {Position=ud2(0.5,-30,0,10)}, true)
                bMax.Active = true 
                if onComplete then task.defer(onComplete) end
            end
        end,

        maximize = function(onComplete)
            if isAnimating then 
                if onComplete then task.defer(onComplete) end
                return 
            end
            bMax.Active = false 
            tw(minFrm, tSmth, {Position=ud2(0.5,-30,0,-50)}, true)
            minFrm.Visible=false
            unTrn(main)
            bMin.Visible, bCls.Visible = true, true
            if onComplete then task.defer(onComplete) end
        end,

        showConfirm = function() 
            if isAnimating then return end
            lastPos = main.Position
            bMin.Visible, bCls.Visible = false, false 
            trnMnu(scrl, nil, cnfFrm, ud2(0,150,0,80)); cnfEx(0) 
        end,

        hideConfirm = function() 
            if isAnimating then return end
            cnfEx(1); task.wait(0.2); unTrn(cnfFrm)
            bMin.Visible, bCls.Visible = true, true 
        end,

        hideConfirmHard = function() 
            if isAnimating then return end
            cnfEx(1); task.wait(0.2); tw(cnfFrm, tBncIn, {Size=ud2(0,0,0,0), Position=ud2(0.5,0,0.5,0)}, true) 
        end,

        showInput = function(ph, tx, btnTx) 
            if isAnimating then return end
            lastPos = main.Position
            bMin.Visible, bCls.Visible = false, false
            trnMnu(scrl, nil, inpFrm, ud2(0,160,0,75)); inBox.PlaceholderText, inBox.Text, bSrch.Text = ph, tx, btnTx; inEx(0) 
        end,

        hideInput = function() 
            if isAnimating then return end
            inEx(1); task.wait(0.2); unTrn(inpFrm) 
            bMin.Visible, bCls.Visible = true, true
        end,

        setStatus = function(tx, clr) stLbl.Text = tx; stLbl.TextColor3 = clr or CFG.SECONDARY_TEXT_COLOR end,
        setButtonState = function(b, txt, isActive) if txt then b.Text = txt end; stBAct(b, isActive) end,
        updateSpeedometerText = function(txt) if UI.spdText then UI.spdText.Text = txt end end,
        toggleSpeedometerVisibility = function(isVisible) stLbl.Visible = not isVisible; if UI.spdFrame then UI.spdFrame.Visible = isVisible end; spdoLbl.Visible = isVisible; spdoLbl.Position = isVisible and ud2(0,5,1,-22) or ud2(0,5,1,-34) end,
        sendNotif = function(title, text, dur) SG:SetCore("SendNotification", {Title=title, Text=text, Duration=dur}) end,
        rndBClr = rndBClr,

        playSpawnEffect = function(pos)
            local p=mk("Part", workspace, {Size=v3(1,1,1), Position=pos, Anchored=true, CanCollide=false, Transparency=1}); local a=mk("Attachment", p)
            local pe=mk("ParticleEmitter", a, {Color=ColorSequence.new(c3(46,204,113),c3(255,255,255)), LightEmission=1, Size=NumberSequence.new({NumberSequenceKeypoint.new(0,2),NumberSequenceKeypoint.new(1,0)}), Texture="rbxassetid://2442214466", Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)}), Lifetime=NumberRange.new(0.5,1), Speed=NumberRange.new(5,15), SpreadAngle=Vector2.new(360,360)}); pe:Emit(30); Deb:AddItem(p,2)
        end,

        setLagVisual = function(hrpCFrame, isActive)
            if isActive then
                lagPrt = mk("Part", workspace, {Name="LagSwitchOriginIndicator", Shape=Enum.PartType.Ball, Size=v3(2.5,2.5,2.5), CFrame=hrpCFrame, CanCollide=false, Anchored=true, Transparency=0.4, Material=Enum.Material.Neon, BrickColor=BrickColor.new("Bright yellow")})
                mk("Highlight", lagPrt, {Name="IndicatorESP", FillColor=c3(255,255,0), OutlineColor=c3(255,255,255), FillTransparency=0.5})
            else
                if lagPrt then lagPrt:Destroy() lagPrt=nil end
            end
        end,

        setWarningGui = function(hrp, isVisible)
            if not wrnGui then
                wrnGui = mk("BillboardGui", nil, {Name="ProximityWarning", Size=ud2(0,50,0,50), StudsOffset=v3(0,5,0), AlwaysOnTop=true, Enabled=false})
                mk("TextLabel", wrnGui, {Size=ud2(1,0,1,0), BackgroundTransparency=1, Text="!", TextColor3=c3(255,0,0), Font=Enum.Font.GothamBold, TextSize=45, TextStrokeTransparency=0, TextStrokeColor3=c3(0,0,0)})
            end
            wrnGui.Parent = hrp
            wrnGui.Adornee = hrp
            wrnGui.Enabled = isVisible
        end,

        clearWarningGui = function() if wrnGui then wrnGui:Destroy() wrnGui=nil end end,

        setCharacterTransparency = function(char, alpha)
            for _, d in char:GetDescendants() do if d.Name~="HumanoidRootPart" and (d:IsA("BasePart") or d:IsA("Decal")) then d.Transparency = alpha end end
        end,

        addCustomHighlight = function(obj)
            if not obj:FindFirstChild("CustomEspH") then table.insert(cEspHL, mk("Highlight", obj, {Name="CustomEspH", FillColor=c3(0,255,255), OutlineColor=c3(255,255,255), FillTransparency=0.5, OutlineTransparency=0.1, DepthMode=Enum.HighlightDepthMode.AlwaysOnTop})) end
        end,

        clearCustomHighlights = function()
            for _, h in ipairs(cEspHL) do if h then h:Destroy() end end; cEspHL={}
        end,

        drawPlayerEsp = function(p, c, tp, espState, dist, clr, sp, isOffscreen, vpCtr, bx, by)
            if espState>=1 and espState<=4 then
                if not espHL[p] or espHL[p].Parent~=c then
                    if espHL[p] then espHL[p]:Destroy() end
                    espHL[p] = mk("Highlight", c, {Name="EspChams", FillTransparency=0.7, OutlineTransparency=0.2, OutlineColor=c3(255,255,255), FillColor=clr})
                else espHL[p].FillColor=clr end
            elseif espHL[p] then espHL[p]:Destroy(); espHL[p]=nil end

            if espState>=1 and espState<=3 then
                local txl=p.Name.."\n["..dist.." studs]"
                if not espTg[p] or espTg[p].Parent~=tp then
                    if espTg[p] then espTg[p]:Destroy() end
                    local b=mk("BillboardGui", tp, {Name="EspNametag", AlwaysOnTop=true, Size=ud2(0,120,0,30), MaxDistance=math.huge, Adornee=tp})
                    mk("TextLabel", b, {Name="Label", Size=ud2(1,0,1,0), BackgroundTransparency=1, Text=txl, TextColor3=clr, TextStrokeTransparency=0, TextStrokeColor3=c3(0,0,0), Font=Enum.Font.GothamBold, TextSize=10})
                    espTg[p]=b
                else espTg[p].Label.Text, espTg[p].Label.TextColor3 = txl, clr end
            elseif espTg[p] then espTg[p]:Destroy(); espTg[p]=nil end

            if isOffscreen then
                if not espOff[p] then espOff[p]=mk("TextLabel", gui, {Name="OffScreenLabel", Size=ud2(0,120,0,30), AnchorPoint=Vector2.new(0.5,0.5), BackgroundTransparency=1, Font=Enum.Font.GothamBold, TextSize=10, TextStrokeTransparency=0, TextStrokeColor3=c3(0,0,0)}) end
                local l = espOff[p]; l.Text, l.TextColor3 = p.Name.."\n["..dist.." studs]", clr
                local off = Vector2.new(sp.X, sp.Y) - vpCtr
                if sp.Z < 0 then off = -off end
                if off.Magnitude < 0.001 then off = Vector2.new(0, 1) end
                local dir = off.Unit
                local scale = math.min(bx / math.abs(dir.X), by / math.abs(dir.Y))
                local pos = vpCtr + (dir * scale)
                l.Position, l.Visible = ud2(0, pos.X, 0, pos.Y), true
            elseif espOff[p] then espOff[p].Visible=false end
        end,

        clearPlayerEsp = function(p)
            if espHL[p] then espHL[p]:Destroy() espHL[p]=nil end
            if espTg[p] then espTg[p]:Destroy() espTg[p]=nil end
            if espOff[p] then espOff[p]:Destroy() espOff[p]=nil end
        end,

        clearAllEsp = function()
            for _, h in pairs(espHL) do if h then h:Destroy() end end; espHL={}
            for _, t in pairs(espTg) do if t then t:Destroy() end end; espTg={}
            for _, l in pairs(espOff) do if l then l:Destroy() end end; espOff={}
        end,

        destroyGui = function() gui:Destroy() if UI.spdGui then UI.spdGui:Destroy() end if UI.jfUpGui then UI.jfUpGui:Destroy() end end,
        
        connectEvents = function(callbacks)
            if not callbacks then return end
            
            -- Logo/Config toggle
            logo.MouseButton1Click:Connect(function() UI.API.toggleConfigMenu(not cScrl.Visible) end)
            
            -- Main buttons
            bSpd1.MouseButton1Click:Connect(function() if callbacks.toggleSpeed1 then callbacks.toggleSpeed1() end end)
            bSpd2.MouseButton1Click:Connect(function() if callbacks.toggleSpeed2 then callbacks.toggleSpeed2() end end)
            bJmp.MouseButton1Click:Connect(function() if callbacks.toggleJump then callbacks.toggleJump() end end)
            bNc.MouseButton1Click:Connect(function() if callbacks.toggleNoclip then callbacks.toggleNoclip() end end)
            bHb.MouseButton1Click:Connect(function() if callbacks.toggleHitbox then callbacks.toggleHitbox() end end)
            bLag.MouseButton1Click:Connect(function() if callbacks.toggleLag then callbacks.toggleLag() end end)
            bInv.MouseButton1Click:Connect(function() if callbacks.toggleInvis then callbacks.toggleInvis() end end)
            bFb.MouseButton1Click:Connect(function() if callbacks.toggleFullbright then callbacks.toggleFullbright() end end)
            bEsp.MouseButton1Click:Connect(function() if callbacks.toggleEsp then callbacks.toggleEsp() end end)
            bCesp.MouseButton1Click:Connect(function() 
                if callbacks.toggleCustomEsp then callbacks.toggleCustomEsp() 
                else UI.API.showInput("", "Enter search keyword...", "SEARCH") end
            end)
            bInst.MouseButton1Click:Connect(function() if callbacks.toggleInst then callbacks.toggleInst() end end)
            bSpdo.MouseButton1Click:Connect(function() if callbacks.toggleSpeedo then callbacks.toggleSpeedo() end end)
            bZm.MouseButton1Click:Connect(function() if callbacks.toggleZoom then callbacks.toggleZoom() end end)
            bWrn.MouseButton1Click:Connect(function() if callbacks.toggleWarn then callbacks.toggleWarn() end end)
            bRst.MouseButton1Click:Connect(function() if callbacks.toggleSpawn then callbacks.toggleSpawn() end end)
            bJf.MouseButton1Click:Connect(function() if callbacks.toggleJitter then callbacks.toggleJitter() end end)
            
            -- Rayfield Switch
            bRayfield.MouseButton1Click:Connect(function() 
                if _G.TSOS_RayfieldLoaded and not _G.TSOS_RayfieldLibrary then 
                    _G.TSOS_RayfieldLoaded = false 
                end
                if _G.TSOS_RayfieldLoaded then 
                    UI.API.sendNotif("Error", "Rayfield already loaded!", 3) 
                    return 
                end
                
                local currentState = {
                    bst = callbacks.getState and callbacks.getState("bst") or "None",
                    lag = callbacks.getState and callbacks.getState("lag") or false,
                    inv = callbacks.getState and callbacks.getState("inv") or false,
                    fb = callbacks.getState and callbacks.getState("fb") or false,
                    nc = callbacks.getState and callbacks.getState("nc") or false,
                    hb = callbacks.getState and callbacks.getState("hb") or 0,
                    jmp = callbacks.getState and callbacks.getState("jmp") or false,
                    inst = callbacks.getState and callbacks.getState("inst") or false,
                    spdo = callbacks.getState and callbacks.getState("spdo") or false,
                    zm = callbacks.getState and callbacks.getState("zm") or false,
                    wrn = callbacks.getState and callbacks.getState("wrn") or false,
                    esp = callbacks.getState and callbacks.getState("esp") or 0,
                    jf = callbacks.getState and callbacks.getState("jf") or false,
                    kw = callbacks.getState and callbacks.getState("kw") or ""
                }
                
                UI.minimize(function() 
                    _G.TSOS_RayfieldLoaded = true
                    UI.loadRayfield(nil, function()
                        _G.TSOS_RayfieldLoaded = false
                        UI.maximize()
                    end, currentState, {
                        speed1 = callbacks.toggleSpeed1,
                        speed2 = callbacks.toggleSpeed2,
                        jump = callbacks.toggleJump,
                        noclip = callbacks.toggleNoclip,
                        hitbox = callbacks.toggleHitbox,
                        lag = callbacks.toggleLag,
                        invis = callbacks.toggleInvis,
                        fullbright = callbacks.toggleFullbright,
                        esp = callbacks.toggleEsp,
                        jitter = callbacks.toggleJitter,
                        speedo = callbacks.toggleSpeedo,
                        zoom = callbacks.toggleZoom,
                        warn = callbacks.toggleWarn,
                        spawn = callbacks.toggleSpawn,
                        inst = callbacks.toggleInst,
                        cesp = callbacks.runCustomEsp,
                        clearCesp = callbacks.clearCustomEsp,
                        showCustom = function()
                            _G.TSOS_RayfieldLoaded = false
                            UI.maximize()
                        end
                    })
                end, true)
            end)
            
            -- Search/Input buttons
            bSrch.MouseButton1Click:Connect(function() 
                local isApp = bSrch.Text == "APPLY"
                UI.hideInput()
                if isApp then 
                    local v = tonumber(inBox.Text)
                    if v then CFG.DYNAMIC_SPEED_ADDITIVE = v end
                    if callbacks.toggleSpeed2 then callbacks.toggleSpeed2(true) end
                else 
                    if inBox.Text ~= "" and callbacks.runCustomEsp then callbacks.runCustomEsp(inBox.Text) end
                end
            end)
            
            bCnc.MouseButton1Click:Connect(function() UI.hideInput() end)
            
            -- Confirm dialog
            bCls.MouseButton1Click:Connect(function() UI.showConfirm() end)
            bYes.MouseButton1Click:Connect(function() 
                if callbacks.unloadScript then callbacks.unloadScript() end
                UI.hideConfirmHard()
                UI.destroyGui()
            end)
            bNo.MouseButton1Click:Connect(function() UI.hideConfirm() end)
            
            -- Min/Max
            bMin.MouseButton1Click:Connect(function() 
                UI.minimize()
                UI.sendNotif("Script minimized!", "Click the button at the top of your screen to maximize.", 5)
            end)
            bMax.MouseButton1Click:Connect(function() UI.maximize() end)
        end
    }

    -- Assign to UI table
    UI.gui = gui
    UI.main = main
    UI.minFrm = minFrm
    UI.inBox = inBox
    UI.bSpd1 = bSpd1
    UI.bSpd2 = bSpd2
    UI.bJmp = bJmp
    UI.bNc = bNc
    UI.bHb = bHb
    UI.bLag = bLag
    UI.bInv = bInv
    UI.bFb = bFb
    UI.bEsp = bEsp
    UI.bCesp = bCesp
    UI.bInst = bInst
    UI.bSpdo = bSpdo
    UI.bZm = bZm
    UI.bWrn = bWrn
    UI.bRst = bRst
    UI.bJf = bJf
    UI.bCls = bCls
    UI.bYes = bYes
    UI.bNo = bNo
    UI.bMin = bMin
    UI.bMax = bMax
    UI.bSrch = bSrch
    UI.bCnc = bCnc
    UI.bRayfield = bRayfield
    UI.logo = logo
    UI.btns = btns

    return UI
end

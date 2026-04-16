--!strict
local TS = game:GetService("TweenService")
local SG = game:GetService("StarterGui")
local Deb = game:GetService("Debris")

local v3, c3, ud2 = Vector3.new, Color3.fromRGB, UDim2.new
local tFast = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local tBnc = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local tBncIn = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
local tSmth = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local snapInfo = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

return function(plr, CFG)
    local gui, main, tTabBg, minFrm, cnfFrm, inpFrm, inBox, bSrch, bCnc, bMax, scrl, cScrl, bSpd1, bSpd2, bJmp, bNc, bHb, bLag, bInv, bFb, bEsp, bCesp, bInst, bSpdo, bZm, bWrn, bRst, bCls, bYes, bNo, bMin, sigLbl, stLbl, spdoLbl, logo, tLbl, cnfLbl, ttFrm, ttLbl, bJf, bNd, bDex, bCobalt
    local btns, bOrigClr = {}, {}
    local espHL, espTg, espOff, cEspHL = {}, {}, {}, {}
    local lagPrt, wrnGui = nil, nil
    
    local isAnimating = false
    local lastPos = ud2(0.5,-60,0.5,-59)

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
        local st=mk("UIStroke", bg, {Thickness=1, ApplyStrokeMode=Enum.ApplyStrokeMode.Border, Color=c3(255,255,255), Transparency=1})
        local h,s,v=clr:ToHSV(); mk("UIGradient", st, {Color=ColorSequence.new(Color3.fromHSV(h,s*0.8,math.min(v*1.4,1)),c3(0,0,0))}); return b
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
    local sNm={SPEED_1_KEY="SPD 1",SPEED_2_KEY="SPD 2",LAG_SWITCH_KEY="LAG KEY",INVISIBILITY_KEY="INVIS",FULLBRIGHT_KEY="F-BRIGHT",ESP_CHAMS_KEY="ESP KEY",RESET_KEY="RESET",NOCLIP_KEY="NOCLIP",SPEEDOMETER_KEY="SPEEDO",ZOOM_KEY="ZOOM",WARNING_KEY="WARN",CUSTOM_ESP_KEY="C-ESP",DECAL_KEY="POTATO GFX",DEX_KEY="DEX KEY",COBALT_KEY="COBALT KEY",BOOSTED_SPEED_1="BST SPD 1",DYNAMIC_SPEED_ADDITIVE="DYN ADD",DEFAULT_JUMP="DEF JUMP",BOOSTED_JUMP="BST JUMP",HITBOX_SIZE="HB SIZE",MAX_ZOOM="MAX ZM",MIN_ZOOM="MIN ZM",WARNING_DISTANCE="WARN DIST",INVISIBILITY_POSITION="INVIS POS",RESET_COOLDOWN="RST CD",BACKGROUND_COLOR="BG CLR",ACCENT_COLOR="ACC CLR",TAB_COLOR="TAB CLR",BORDER_COLOR="BRDR CLR",TEXT_COLOR="TXT CLR",SECONDARY_TEXT_COLOR="SEC TXT",ESP_MAX_DISTANCE="ESP MAX",ESP_NEAR_DISTANCE="ESP NEAR",JITTER_FLY_SPEED="JF SPEED"}
    local pK, oK = {"BOOSTED_SPEED_1","DYNAMIC_SPEED_ADDITIVE","DEFAULT_JUMP","BOOSTED_JUMP","HITBOX_SIZE","MAX_ZOOM","MIN_ZOOM","WARNING_DISTANCE","JITTER_FLY_SPEED"}, {}; for k,_ in pairs(CFG) do if not table.find(pK,k) then table.insert(oK,k) end end; table.sort(oK); local sk={}; for _,k in ipairs(pK) do table.insert(sk,k) end; for _,k in ipairs(oK) do table.insert(sk,k) end
    for _, k in ipairs(sk) do local r=mk("Frame", cScrl, {Size=ud2(0.92,0,0,20), BackgroundTransparency=1}); local l=mk("TextLabel", r, {Size=ud2(0.5,0,1,0), BackgroundTransparency=1, Text=sNm[k] or k, TextColor3=CFG.TEXT_COLOR, TextXAlignment=Enum.TextXAlignment.Center, Font=Enum.Font.Gotham, TextSize=7, TextTransparency=1, Active=true})
        local showTt=function() ttLbl.Text=k; ttFrm.AnchorPoint=Vector2.new(0.5,1); ttFrm.Position=ud2(0,tTabBg.AbsolutePosition.X+(tTabBg.AbsoluteSize.X/2),0,tTabBg.AbsolutePosition.Y-5); ttFrm.Visible=true end; l.MouseEnter:Connect(showTt); l.MouseLeave:Connect(function() ttFrm.Visible=false end); l.InputBegan:Connect(function(ip) if ip.UserInputType==Enum.UserInputType.Touch then showTt() end end); l.InputEnded:Connect(function(ip) if ip.UserInputType==Enum.UserInputType.Touch then ttFrm.Visible=false end end)
        local bb=mk("Frame", r, {Size=ud2(0.5,-4,1,0), Position=ud2(0.5,2,0,0), BackgroundColor3=CFG.ACCENT_COLOR, BackgroundTransparency=1, BorderSizePixel=0, ClipsDescendants=true}); mk("UICorner", bb, {CornerRadius=UDim.new(0,4)}); mk("UIStroke", bb, {Color=CFG.BORDER_COLOR, Thickness=1, Transparency=1}); local bx=mk("TextBox", bb, {Size=ud2(1,-4,1,0), Position=ud2(0,2,0,0), BackgroundTransparency=1, Text=toStr(CFG[k]), TextColor3=CFG.SECONDARY_TEXT_COLOR, Font=Enum.Font.Gotham, TextSize=7, TextTransparency=1, ClearTextOnFocus=false, ClipsDescendants=true})
        bx.FocusLost:Connect(function() local pv=pVal(CFG[k], bx.Text); CFG[k]=pv; bx.Text=toStr(pv) end) end
    cfLL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() cScrl.CanvasSize=ud2(0,0,0,cfLL.AbsoluteContentSize.Y+10) end)
    
    local function sB(nm, tx)
        local b=mk("TextButton", scrl, {Name=nm, Size=ud2(0.92,0,0,20), Text=tx, BackgroundTransparency=1, TextColor3=c3(255,255,255), TextTransparency=1, Font=Enum.Font.GothamBold, TextSize=10, ZIndex=2})
        local bg=mk("Frame", b, {Name="Background", Size=ud2(1,0,1,0), BackgroundColor3=c3(45,45,45), BackgroundTransparency=1, BorderSizePixel=0, ZIndex=1})
        mk("UICorner", bg, {CornerRadius=UDim.new(0,4)}); mk("UIPadding", bg, {PaddingLeft=UDim.new(0,0)}); mk("UIGradient", bg, {Rotation=0}); local st=mk("UIStroke", bg, {Thickness=1, ApplyStrokeMode=Enum.ApplyStrokeMode.Border, Color=c3(255,255,255), Transparency=1}); mk("UIGradient", st, {Rotation=0})
        b.MouseButton1Down:Connect(function() if isAnimating then return end tw(b, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size=ud2(0.85,0,0,18)}) end)
        local u=function() if isAnimating then return end tw(b, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size=ud2(0.92,0,0,20)}) end; b.MouseButton1Up:Connect(u); b.MouseLeave:Connect(u); table.insert(btns, b); return b
    end

    -- All 19 buttons (16 original + Dex + Potato Graphics + Cobalt)
    bSpd1,bSpd2,bJmp,bNc,bHb,bLag,bInv,bFb,bEsp,bCesp,bInst,bSpdo,bZm,bWrn,bRst,bJf,bNd,bDex,bCobalt = sB("S1","SPEED BOOST 1"),sB("S2","DYNAMIC SPD"),sB("JP","JUMP POWER"),sB("NC","NOCLIP"),sB("HB","HITBOX OFF"),sB("LS","LAG SWITCH"),sB("IV","INVISIBLE"),sB("FB","FULLBRIGHT"),sB("ESP","ESP CHAMS"),sB("CESP","CUSTOM ESP"),sB("IN","INSTANT INTERACT"),sB("SPD","SPEEDOMETER"),sB("ZM","UNLIMITED ZOOM"),sB("WRN","PROXIMITY WARN"),sB("RST","SET SPAWN"),sB("JF","JITTER FLY"),sB("ND","POTATO GRAPHICS"),sB("DEX","DEX EXPLORER"),sB("COBALT","COBALT SPY")
    spdoLbl=mk("TextLabel", main, {Size=ud2(1,-10,0,12), Position=ud2(0,5,1,-34), Text="Speed: 0 studs/s", BackgroundTransparency=1, TextColor3=c3(255,255,255), Font=Enum.Font.GothamBold, TextSize=8, TextTransparency=1, Visible=false})
    stLbl=mk("TextLabel", main, {Size=ud2(1,-10,0,12), Position=ud2(0,5,1,-22), Text="Ready", BackgroundTransparency=1, TextColor3=CFG.SECONDARY_TEXT_COLOR, Font=Enum.Font.Gotham, TextSize=8, TextTransparency=1})
    sigLbl=mk("TextLabel", main, {Size=ud2(1,0,0,10), Position=ud2(0,0,1,-10), Text="The Script of Stuffs", BackgroundTransparency=1, TextColor3=CFG.SECONDARY_TEXT_COLOR, Font=Enum.Font.Gotham, TextSize=7, TextTransparency=1})

    -- Robust Momentum-Aware Scroll Snapping
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
    
    local function tgCfg(a) 
        for _,r in ipairs(cScrl:GetChildren()) do 
            if r:IsA("Frame") then 
                local l,bg=r:FindFirstChildOfClass("TextLabel"),r:FindFirstChild("Frame")
                if l then tw(l,tFast,{TextTransparency=a}) end
                if bg then 
                    tw(bg,tFast,{BackgroundTransparency=a})
                    local s,bx=bg:FindFirstChildOfClass("UIStroke"),bg:FindFirstChildOfClass("TextBox")
                    if s then tw(s,tFast,{Transparency=a}) end
                    if bx then tw(bx,tFast,{TextTransparency=a}) end
                end
            end 
        end 
    end
    
    local function cnfEx(v) tw(cnfLbl,tFast,{TextTransparency=v}); tw(bYes,tFast,{TextTransparency=v}); tw(bNo,tFast,{TextTransparency=v}); tw(bYes.Background,tFast,{BackgroundTransparency=v}); tw(bNo.Background,tFast,{BackgroundTransparency=v}); tw(bYes.Background.UIStroke,tFast,{Transparency=v}); tw(bNo.Background.UIStroke,tFast,{Transparency=v==0 and 1 or 1}) end
    local function inEx(v) tw(inBox,tFast,{TextTransparency=v}); tw(bSrch,tFast,{TextTransparency=v}); tw(bCnc,tFast,{TextTransparency=v}); tw(bSrch.Background,tFast,{BackgroundTransparency=v}); tw(bCnc.Background,tFast,{BackgroundTransparency=v}); tw(bSrch.Background.UIStroke,tFast,{Transparency=v}); tw(bCnc.Background.UIStroke,tFast,{Transparency=1}) end

    local UI_API = {}

    function UI_API.playAnim()
        if isAnimating then return end
        local s=mk("TextLabel", gui, {Size=ud2(1,0,1,0), BackgroundTransparency=1, Text="TSOS", TextColor3=c3(255,255,255), Font=Enum.Font.GothamBold, TextSize=100, ZIndex=100}); task.wait(4); tw(s, tFast, {TextTransparency=1}, true); s:Destroy()
        main.Visible, main.Size, main.Position = true, ud2(0,0,0,22), ud2(0.5,0,0.5,-59); tw(main, tSmth, {Size=ud2(0,120,0,22), Position=ud2(0.5,-60,0.5,-59)}, true); fdMnu(0, true); shwUi(true, 120, 118); tgBtns(0, 0.05); setA(0)
    end

    function UI_API.toggleConfigMenu(isOpen)
        if isAnimating then return end
        tw(logo, tBnc, {Rotation=logo.Rotation+360}); setA(1); task.wait(0.1)
        isAnimating = true 
        if not isOpen then tgCfg(1); task.wait(0.15); tw(main, tSmth, {Size=ud2(0,120,0,22)}, true); cScrl.Visible, scrl.Visible = false, true; shwUi(true, 120, 115); tgBtns(0)
        else tgBtns(1); task.wait(0.15); tw(main, tSmth, {Size=ud2(0,120,0,22)}, true); scrl.Visible, cScrl.Visible = false, true; shwUi(true, 120, 115); tgCfg(0) end; setA(0)
        isAnimating = false
    end

    function UI_API.minimize(onComplete, skipMinimizeButton)
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
    end

    function UI_API.maximize(onComplete)
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
    end

    function UI_API.showConfirm() 
        if isAnimating then return end
        lastPos = main.Position
        bMin.Visible, bCls.Visible = false, false 
        trnMnu(scrl, nil, cnfFrm, ud2(0,150,0,80)); cnfEx(0) 
    end
    
    function UI_API.hideConfirm() 
        if isAnimating then return end
        cnfEx(1); task.wait(0.2); unTrn(cnfFrm)
        bMin.Visible, bCls.Visible = true, true 
    end
    
    function UI_API.hideConfirmHard() 
        if isAnimating then return end
        cnfEx(1); task.wait(0.2); tw(cnfFrm, tBncIn, {Size=ud2(0,0,0,0), Position=ud2(0.5,0,0.5,0)}, true) 
    end
    
    function UI_API.showInput(ph, tx, btnTx) 
        if isAnimating then return end
        lastPos = main.Position
        bMin.Visible, bCls.Visible = false, false
        trnMnu(scrl, nil, inpFrm, ud2(0,160,0,75)); inBox.PlaceholderText, inBox.Text, bSrch.Text = ph, tx, btnTx; inEx(0) 
    end
    
    function UI_API.hideInput() 
        if isAnimating then return end
        inEx(1); task.wait(0.2); unTrn(inpFrm) 
        bMin.Visible, bCls.Visible = true, true
    end

    function UI_API.setStatus(tx, clr) stLbl.Text = tx; stLbl.TextColor3 = clr or CFG.SECONDARY_TEXT_COLOR end
    function UI_API.setButtonState(b, txt, isActive) if txt then b.Text = txt end; stBAct(b, isActive) end
    function UI_API.updateSpeedometerText(txt) spdoLbl.Text = txt end
    function UI_API.toggleSpeedometerVisibility(isVisible) stLbl.Visible = not isVisible; spdoLbl.Visible = isVisible; spdoLbl.Position = isVisible and ud2(0,5,1,-22) or ud2(0,5,1,-34) end
    function UI_API.sendNotif(title, text, dur) SG:SetCore("SendNotification", {Title=title, Text=text, Duration=dur}) end
    function UI_API.rndBClr() rndBClr() end

    function UI_API.disablePotatoButton()
        if not bNd then return end
        bNd.Text = "POTATO APPLIED"
        bNd.Active = false
        local bg = bNd:FindFirstChild("Background")
        if bg then
            bg.BackgroundColor3 = c3(80, 80, 80)
            local gr = bg:FindFirstChildOfClass("UIGradient")
            if gr then gr.Enabled = false end
            local st = bg:FindFirstChildOfClass("UIStroke")
            if st then 
                st.Color = c3(60, 60, 60)
                local sg = st:FindFirstChildOfClass("UIGradient")
                if sg then sg.Enabled = false end
            end
        end
        for i, btn in ipairs(btns) do
            if btn == bNd then
                table.remove(btns, i)
                break
            end
        end
        bOrigClr[bNd] = c3(80, 80, 80)
    end

    function UI_API.playSpawnEffect(pos)
        local p=mk("Part", workspace, {Size=v3(1,1,1), Position=pos, Anchored=true, CanCollide=false, Transparency=1}); local a=mk("Attachment", p)
        local pe=mk("ParticleEmitter", a, {Color=ColorSequence.new(c3(46,204,113),c3(255,255,255)), LightEmission=1, Size=NumberSequence.new({NumberSequenceKeypoint.new(0,2),NumberSequenceKeypoint.new(1,0)}), Texture="rbxassetid://2442214466", Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)}), Lifetime=NumberRange.new(0.5,1), Speed=NumberRange.new(5,15), SpreadAngle=Vector2.new(360,360)}); pe:Emit(30); Deb:AddItem(p,2)
    end

    function UI_API.setLagVisual(hrpCFrame, isActive)
        if isActive then
            lagPrt = mk("Part", workspace, {Name="LagSwitchOriginIndicator", Shape=Enum.PartType.Ball, Size=v3(2.5,2.5,2.5), CFrame=hrpCFrame, CanCollide=false, Anchored=true, Transparency=0.4, Material=Enum.Material.Neon, BrickColor=BrickColor.new("Bright yellow")})
            mk("Highlight", lagPrt, {Name="IndicatorESP", FillColor=c3(255,255,0), OutlineColor=c3(255,255,255), FillTransparency=0.5})
        else
            if lagPrt then lagPrt:Destroy() lagPrt=nil end
        end
    end

    function UI_API.setWarningGui(hrp, isVisible)
        if not wrnGui then
            wrnGui = mk("BillboardGui", nil, {Name="ProximityWarning", Size=ud2(0,50,0,50), StudsOffset=v3(0,5,0), AlwaysOnTop=true, Enabled=false})
            mk("TextLabel", wrnGui, {Size=ud2(1,0,1,0), BackgroundTransparency=1, Text="!", TextColor3=c3(255,0,0), Font=Enum.Font.GothamBold, TextSize=45, TextStrokeTransparency=0, TextStrokeColor3=c3(0,0,0)})
        end
        wrnGui.Parent = hrp
        wrnGui.Adornee = hrp
        wrnGui.Enabled = isVisible
    end
    function UI_API.clearWarningGui() if wrnGui then wrnGui:Destroy() wrnGui=nil end end

    function UI_API.setCharacterTransparency(char, alpha)
        for _, d in char:GetDescendants() do if d.Name~="HumanoidRootPart" and (d:IsA("BasePart") or d:IsA("Decal")) then d.Transparency = alpha end end
    end

    function UI_API.addCustomHighlight(obj)
        if not obj:FindFirstChild("CustomEspH") then table.insert(cEspHL, mk("Highlight", obj, {Name="CustomEspH", FillColor=c3(0,255,255), OutlineColor=c3(255,255,255), FillTransparency=0.5, OutlineTransparency=0.1, DepthMode=Enum.HighlightDepthMode.AlwaysOnTop})) end
    end
    function UI_API.clearCustomHighlights()
        for _, h in ipairs(cEspHL) do if h then h:Destroy() end end; cEspHL={}
    end

    function UI_API.drawPlayerEsp(p, c, tp, espState, dist, clr, sp, isOffscreen, vpCtr, bx, by)
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
    end

    function UI_API.clearPlayerEsp(p)
        if espHL[p] then espHL[p]:Destroy() espHL[p]=nil end
        if espTg[p] then espTg[p]:Destroy() espTg[p]=nil end
        if espOff[p] then espOff[p]:Destroy() espOff[p]=nil end
    end
    function UI_API.clearAllEsp()
        for _, h in pairs(espHL) do if h then h:Destroy() end end; espHL={}
        for _, t in pairs(espTg) do if t then t:Destroy() end end; espTg={}
        for _, l in pairs(espOff) do if l then l:Destroy() end end; espOff={}
    end

    function UI_API.destroyGui() gui:Destroy() end

    return {
        gui=gui, inBox=inBox, bSpd1=bSpd1, bSpd2=bSpd2, bJmp=bJmp, bNc=bNc, bHb=bHb, bLag=bLag, bInv=bInv, bFb=bFb, bEsp=bEsp, bCesp=bCesp, bInst=bInst, bSpdo=bSpdo, bZm=bZm, bWrn=bWrn, bRst=bRst, bJf=bJf, bNd=bNd, bDex=bDex, bCobalt=bCobalt, bCls=bCls, bYes=bYes, bNo=bNo, bMin=bMin, bMax=bMax, bSrch=bSrch, bCnc=bCnc, logo=logo, btns=btns,
        API = UI_API
    }
end

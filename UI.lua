-- Save this to a Web Server / GitHub
local Library = {}
local TS = game:GetService("TweenService")
local P = game:GetService("Players")
local plr = P.LocalPlayer

function Library.CreateMain(title)
    local gui = Instance.new("ScreenGui", plr.PlayerGui)
    gui.Name = "CustomLib"
    gui.ResetOnSpawn = false

    local main = Instance.new("Frame", gui)
    main.Size = UDim2.new(0, 200, 0, 250)
    main.Position = UDim2.new(0.5, -100, 0.5, -125)
    main.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    main.Active = true
    main.Draggable = true -- Standard for mobile executors

    local titleLbl = Instance.new("TextLabel", main)
    titleLbl.Size = UDim2.new(1, 0, 0, 30)
    titleLbl.Text = title
    titleLbl.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    titleLbl.TextColor3 = Color3.new(1, 1, 1)

    local container = Instance.new("ScrollingFrame", main)
    container.Size = UDim2.new(1, -10, 1, -40)
    container.Position = UDim2.new(0, 5, 0, 35)
    container.BackgroundTransparency = 1
    container.CanvasSize = UDim2.new(0, 0, 0, 0)
    
    local layout = Instance.new("UIListLayout", container)
    layout.Padding = UDim.new(0, 5)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    -- Return an API for this specific window
    local API = {}

    function API.AddToggle(text, callback)
        local btn = Instance.new("TextButton", container)
        btn.Size = UDim2.new(1, 0, 0, 30)
        btn.Text = text .. ": OFF"
        btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        btn.TextColor3 = Color3.new(1, 1, 1)

        local enabled = false
        btn.MouseButton1Click:Connect(function()
            enabled = not enabled
            btn.Text = text .. (enabled and ": ON" or ": OFF")
            btn.BackgroundColor3 = enabled and Color3.fromRGB(0, 170, 255) or Color3.fromRGB(60, 60, 60)
            
            -- Animation
            btn:TweenSize(UDim2.new(0.95, 0, 0, 28), "Out", "Quad", 0.1, true)
            task.wait(0.1)
            btn:TweenSize(UDim2.new(1, 0, 0, 30), "Out", "Quad", 0.1, true)
            
            callback(enabled)
        end)
    end

    return API
end

return Library

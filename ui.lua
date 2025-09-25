-- YATIM UI Library

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local YATIM = {}
YATIM.__index = YATIM
YATIM.Settings = {
    Theme = "Dark",
    Hotkey = Enum.KeyCode.RightControl
}

-- THEME
local Themes = {
    Dark = {
        Background = Color3.fromRGB(18,18,20),
        Panel = Color3.fromRGB(28,28,32),
        Accent = Color3.fromRGB(0,150,255),
        Text = Color3.fromRGB(235,235,235)
    }
}
local function theme() return Themes[YATIM.Settings.Theme] end

-- Helper
local function make(class, props)
    local obj = Instance.new(class)
    for k,v in pairs(props) do obj[k]=v end
    return obj
end

-- Drag
local function makeDraggable(frame, handle)
    handle = handle or frame
    local dragging, startPos, startMouse
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            startMouse = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - startMouse
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- Create Window
function YATIM:CreateWindow(title)
    local th = theme()
    local pg = LocalPlayer:WaitForChild("PlayerGui")

    local sg = make("ScreenGui", {
        Name = "YATIM_UI",
        ResetOnSpawn = false,
        Parent = pg
    })

    local root = make("Frame", {
        Size = UDim2.new(0,600,0,380),
        Position = UDim2.new(0.5,-300,0.5,-190),
        AnchorPoint = Vector2.new(0.5,0.5),
        BackgroundColor3 = th.Background,
        BorderSizePixel = 0,
        Parent = sg
    })

    -- Header
    local header = make("Frame", {
        Size = UDim2.new(1,0,0,40),
        BackgroundTransparency = 1,
        Parent = root
    })
    makeDraggable(root, header)

    make("TextLabel", {
        Text = title or "YATIM UI",
        Size = UDim2.new(0.6,0,1,0),
        Position = UDim2.new(0,12,0,0),
        BackgroundTransparency = 1,
        TextColor3 = th.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = header
    })

    local btnClose = make("TextButton", {
        Text = "X",
        Size = UDim2.new(0,32,0,28),
        Position = UDim2.new(1,-36,0,6),
        BackgroundColor3 = th.Panel,
        TextColor3 = th.Text,
        Parent = header
    })
    local btnMin = make("TextButton", {
        Text = "—",
        Size = UDim2.new(0,32,0,28),
        Position = UDim2.new(1,-72,0,6),
        BackgroundColor3 = th.Panel,
        TextColor3 = th.Text,
        Parent = header
    })

    -- Sidebar
    local sidebar = make("Frame", {
        Size = UDim2.new(0,150,1,-40),
        Position = UDim2.new(0,0,0,40),
        BackgroundColor3 = th.Panel,
        Parent = root
    })
    make("UIListLayout", {Parent=sidebar, SortOrder=Enum.SortOrder.LayoutOrder})

    -- Content
    local content = make("Frame", {
        Size = UDim2.new(1,-150,1,-40),
        Position = UDim2.new(0,150,0,40),
        BackgroundTransparency = 1,
        Parent = root
    })

    local Tabs, activeTab = {}, nil
    local function clearContent()
        for _,c in ipairs(content:GetChildren()) do
            if c:IsA("Frame") then c:Destroy() end
        end
    end

    -- API
    local API = {}
    function API:CreateTab(name)
        local btn = make("TextButton", {
            Text = name,
            Size = UDim2.new(1,0,0,32),
            BackgroundColor3 = th.Panel,
            TextColor3 = th.Text,
            Parent = sidebar
        })
        local tab = {Name=name, Button=btn}
        btn.MouseButton1Click:Connect(function()
            clearContent()
            local page = make("Frame", {
                Size = UDim2.new(1,0,1,0),
                BackgroundTransparency = 1,
                Parent = content
            })
            tab.Page = page
            activeTab = tab
        end)
        table.insert(Tabs, tab)
        if #Tabs==1 then btn:MouseButton1Click() end
        return tab
    end

    -- Section
    function API:CreateSection(tab, text)
        local section = make("Frame", {
            Size = UDim2.new(1,0,0,200),
            BackgroundTransparency = 1,
            Parent = tab.Page
        })
        make("UIListLayout", {Parent=section, SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,5)})
        make("TextLabel", {
            Text = text,
            Size = UDim2.new(1,0,0,24),
            BackgroundTransparency = 1,
            TextColor3 = th.Accent,
            Font = Enum.Font.GothamBold,
            TextSize = 16,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = section
        })
        return section
    end

    function API:AddButton(section, text, callback)
        local btn = make("TextButton", {
            Text = text,
            Size = UDim2.new(1,0,0,28),
            BackgroundColor3 = th.Panel,
            TextColor3 = th.Text,
            Parent = section
        })
        btn.MouseButton1Click:Connect(function()
            if callback then callback() end
        end)
    end

    function API:AddToggle(section, text, default, callback)
        local state = default or false
        local btn = make("TextButton", {
            Text = text.." : "..tostring(state),
            Size = UDim2.new(1,0,0,28),
            BackgroundColor3 = th.Panel,
            TextColor3 = th.Text,
            Parent = section
        })
        btn.MouseButton1Click:Connect(function()
            state = not state
            btn.Text = text.." : "..tostring(state)
            if callback then callback(state) end
        end)
    end

    function API:AddSlider(section, text, min, max, default, callback)
        local value = default or min
        local label = make("TextLabel", {
            Text = text..": "..value,
            Size = UDim2.new(1,0,0,24),
            BackgroundTransparency = 1,
            TextColor3 = th.Text,
            Parent = section
        })
        local slider = make("TextButton", {
            Size = UDim2.new(1,0,0,24),
            BackgroundColor3 = th.Panel,
            Text = "",
            Parent = section
        })
        slider.MouseButton1Click:Connect(function()
            value = math.clamp(value+1, min, max)
            label.Text = text..": "..value
            if callback then callback(value) end
        end)
    end

    -- Close & Minimize
    local minimized = false
    local restoreBtn
    btnClose.MouseButton1Click:Connect(function() sg:Destroy() end)
    btnMin.MouseButton1Click:Connect(function()
        if not minimized then
            root.Visible = false
            minimized = true
            restoreBtn = make("TextButton", {
                Text = "YATIM",
                Size = UDim2.new(0,56,0,56),
                Position = UDim2.new(0.5,-28,0,12),
                AnchorPoint = Vector2.new(0.5,0),
                BackgroundColor3 = th.Accent,
                TextColor3 = th.Text,
                Parent = sg
            })
            restoreBtn.MouseButton1Click:Connect(function()
                root.Visible = true
                minimized = false
                restoreBtn:Destroy()
            end)
        end
    end)

    -- Hotkey Toggle
    UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == YATIM.Settings.Hotkey then
            root.Visible = not root.Visible
        end
    end)

    return API
end

return YATIM

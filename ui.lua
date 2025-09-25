-- YATIM UI Library (Fluent-inspired, single-file)
-- Author: Generated for Aprilian
-- Usage (example):
-- local YATIM = loadstring(game:HttpGet("https://raw.githubusercontent.com/<you>/YATIM/main/YATIM_UI.lua"))()
-- local Window = YATIM:CreateWindow({Title = "YATIM UI", Theme = "Dark", Size = UDim2.new(0, 640, 0, 420)})
-- local Tab = Window:CreateTab("Main")
-- local Sec = Tab:CreateSection("Features")
-- Sec:AddButton("Hello", function() print("hi") end)
-- Sec:AddToggle("Auto", false, function(v) print(v) end)
-- Sec:AddSlider("Speed", 16, 120, 16, function(v) print(v) end)
-- Sec:AddDropdown("Choose", {"A","B","C"}, {"A"}, false, function(sel) print(sel) end)

-- NOTE: This library is intended for legitimate UI/tooling use in Roblox Studio or local development.
-- It intentionally does NOT include or advise on evasion of platform security or anti-cheat mechanisms.

-- ===== Services =====
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local YATIM = {}
YATIM.__index = YATIM

-- Single-instance guard
if _G.YATIM_UI_INSTANCE then
    pcall(function()
        if _G.YATIM_UI_INSTANCE.Destroy then _G.YATIM_UI_INSTANCE:Destroy() end
    end)
end
_G.YATIM_UI_INSTANCE = setmetatable({}, YATIM)

-- ===== Defaults =====
YATIM.Settings = {
    Theme = "Dark", -- "Dark" | "Light"
    Hotkey = Enum.KeyCode.RightControl,
    AutoSave = true,
    ConfigFile = "yatim_ui_config.json",
}

-- ===== Themes =====
local Themes = {
    Dark = {
        Background = Color3.fromRGB(18,18,20),
        Panel = Color3.fromRGB(28,28,32),
        Accent = Color3.fromRGB(0,150,255),
        Text = Color3.fromRGB(235,235,235),
        Muted = Color3.fromRGB(150,150,150),
        Blur = 0.8,
    },
    Light = {
        Background = Color3.fromRGB(248,249,250),
        Panel = Color3.fromRGB(238,239,241),
        Accent = Color3.fromRGB(0,110,255),
        Text = Color3.fromRGB(20,20,20),
        Muted = Color3.fromRGB(95,95,95),
        Blur = 0.95,
    }
}
local function currentTheme()
    return Themes[YATIM.Settings.Theme] or Themes.Dark
end

-- ===== Utilities =====
local function make(class, props)
    local obj = Instance.new(class)
    for k,v in pairs(props or {}) do
        if k == "Parent" then obj.Parent = v else pcall(function() obj[k] = v end) end
    end
    return obj
end

local function canIO()
    return (type(writefile) == "function") and (type(isfile) == "function") and (type(readfile) == "function")
end

local function saveConfig(name, tbl)
    if not canIO() then return false end
    local ok, err = pcall(function() writefile(name, HttpService:JSONEncode(tbl)) end)
    return ok, err
end

local function loadConfig(name)
    if not canIO() then return nil end
    if not isfile(name) then return nil end
    local ok, content = pcall(function() return readfile(name) end)
    if not ok then return nil end
    local ok2, tbl = pcall(function() return HttpService:JSONDecode(content) end)
    if not ok2 then return nil end
    return tbl
end

-- Signal helper
local Signal = {}
Signal.__index = Signal
function Signal.new() return setmetatable({_c={}}, Signal) end
function Signal:Connect(fn) table.insert(self._c, fn); local i=#self._c; return {Disconnect=function() self._c[i]=nil end} end
function Signal:Fire(...) for _,c in ipairs(self._c) do if c then task.spawn(c, ...) end end end

-- Drag helper (works for mouse & touch)
local function makeDraggable(frame, handle)
    handle = handle or frame
    local dragging = false
    local startPos, startInput
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            startInput = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local conn
            conn = UserInputService.InputChanged:Connect(function(changed)
                if changed == input and dragging and startInput and startPos then
                    local delta = changed.Position - startInput
                    frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                end
            end)
            task.delay(0.5, function() if conn then conn:Disconnect() end end)
        end
    end)
end

local function tween(obj, props, info)
    info = info or TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local ok, t = pcall(function() return TweenService:Create(obj, info, props) end)
    if ok and t then t:Play() end
end

-- Clamp
local function clamp(v,a,b) return math.max(a, math.min(b, v)) end

-- ===== Dropdown (UI helper generator) =====
local function createDropdownContainer(parent, width)
    local frame = make("Frame", {Size = UDim2.new(0, width or 240, 0, 32), BackgroundTransparency = 1, Parent = parent})
    return frame
end

-- ===== Core: CreateWindow =====
function YATIM:CreateWindow(opts)
    opts = opts or {}
    local title = opts.Title or "YATIM UI"
    local size = opts.Size or UDim2.new(0,640,0,420)
    if type(size) ~= "userdata" then size = UDim2.new(0,640,0,420) end
    YATIM.Settings.Theme = opts.Theme or YATIM.Settings.Theme
    local th = currentTheme()

    local pg = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")
    local sg = make("ScreenGui", {Name = "YATIM_UI_"..tostring(math.random(1000,9999)), IgnoreGuiInset = true, ResetOnSpawn = false, Parent = pg})

    -- root frame
    local root = make("Frame", {Name = "Root", Size = size, Position = UDim2.new(0.5, -size.X.Offset/2, 0.5, -size.Y.Offset/2), AnchorPoint = Vector2.new(0.5,0.5), BackgroundColor3 = th.Background, BorderSizePixel = 0, Parent = sg})
    root.ClipsDescendants = true

    -- header
    local header = make("Frame", {Size = UDim2.new(1,0,0,40), BackgroundTransparency = 1, Parent = root})
    local titleLbl = make("TextLabel", {Text = title, Size = UDim2.new(0.6,0,1,0), Position = UDim2.new(0,16,0,0), BackgroundTransparency = 1, TextColor3 = th.Text, Font = Enum.Font.GothamBold, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left, Parent = header})

    local btnMin = make("TextButton", {Text = "—", Size = UDim2.new(0,36,0,28), Position = UDim2.new(1,-88,0,6), BackgroundColor3 = th.Panel, TextColor3 = th.Text, Parent = header, AutoButtonColor = true})
    local btnClose = make("TextButton", {Text = "X", Size = UDim2.new(0,36,0,28), Position = UDim2.new(1,-44,0,6), BackgroundColor3 = th.Panel, TextColor3 = th.Text, Parent = header, AutoButtonColor = true})

    -- left sidebar
    local sidebarW = math.clamp(180, 120, 240)
    local sidebar = make("Frame", {Size = UDim2.new(0, sidebarW, 1, -40), Position = UDim2.new(0,0,0,40), BackgroundColor3 = th.Panel, Parent = root})
    make("UIListLayout", {Parent = sidebar, Padding = UDim.new(0,8), SortOrder = Enum.SortOrder.LayoutOrder})
    make("UIPadding", {Parent = sidebar, PaddingTop = UDim.new(0,12), PaddingLeft = UDim.new(0,12)})

    -- content area
    local content = make("Frame", {Size = UDim2.new(1, -sidebarW, 1, -40), Position = UDim2.new(0, sidebarW, 0, 40), BackgroundTransparency = 1, Parent = root})
    local contentScroll = make("ScrollingFrame", {Size = UDim2.new(1,0,1,0), CanvasSize = UDim2.new(0,0,0,0), ScrollBarThickness = 8, BackgroundTransparency = 1, Parent = content})
    local contentList = make("UIListLayout", {Parent = contentScroll, Padding = UDim.new(0,12), SortOrder = Enum.SortOrder.LayoutOrder})
    make("UIPadding", {Parent = contentScroll, PaddingTop = UDim.new(0,12), PaddingLeft = UDim.new(0,12)})
    contentList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() contentScroll.CanvasSize = UDim2.new(0,0,0, contentList.AbsoluteContentSize.Y + 12) end)

    -- draggable
    makeDraggable(root, header)

    -- Tabs
    local Tabs = {}
    local currentTab = nil

    local function clearContent()
        for _,c in ipairs(contentScroll:GetChildren()) do
            if c:IsA("Frame") and c.Name == "TabPane" then c:Destroy() end
        end
    end

    local function createPane()
        local pane = make("Frame", {Name = "TabPane", Size = UDim2.new(1,0,0,0), BackgroundTransparency = 1, Parent = contentScroll})
        local list = make("UIListLayout", {Parent = pane, Padding = UDim.new(0,12), SortOrder = Enum.SortOrder.LayoutOrder})
        make("UIPadding", {Parent = pane, PaddingTop = UDim.new(0,8), PaddingLeft = UDim.new(0,8)})
        list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() pane.Size = UDim2.new(1,0,0, list.AbsoluteContentSize.Y) end)
        return pane
    end

    -- API for a tab
    local function newTab(name)
        local tab = {Name = name}
        tab.Button = make("TextButton", {Text = name, Size = UDim2.new(1,0,0,36), BackgroundColor3 = th.Panel, TextColor3 = th.Text, Parent = sidebar, AutoButtonColor = true})
        tab.Button.MouseButton1Click:Connect(function()
            for _,t in ipairs(Tabs) do t.Button.BackgroundColor3 = th.Panel end
            tab.Button.BackgroundColor3 = th.Accent
            clearContent()
            tab.Page = createPane()
            currentTab = tab
        end)
        table.insert(Tabs, tab)
        if #Tabs == 1 then task.spawn(function() tab.Button:MouseButton1Click() end) end

        -- section API inside tab
        function tab:CreateSection(title)
            local sec = make("Frame", {Size = UDim2.new(1,0,0,0), BackgroundTransparency = 1, Parent = tab.Page})
            local headerLbl = make("TextLabel", {Text = title or "Section", Size = UDim2.new(1,0,0,20), BackgroundTransparency = 1, TextColor3 = th.Text, Font = Enum.Font.GothamSemibold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Parent = sec})
            local list = make("UIListLayout", {Parent = sec, Padding = UDim.new(0,8), SortOrder = Enum.SortOrder.LayoutOrder})
            make("UIPadding", {Parent = sec, PaddingTop = UDim.new(0,6), PaddingLeft = UDim.new(0,6)})
            list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() sec.Size = UDim2.new(1,0,0, list.AbsoluteContentSize.Y + 26) end)

            local SectionAPI = {}

            function SectionAPI:AddButton(text, callback)
                local btn = make("TextButton", {Text = text or "Button", Size = UDim2.new(1,0,0,36), BackgroundColor3 = th.Accent, TextColor3 = th.Text, Parent = sec})
                btn.AutoButtonColor = true
                btn.MouseButton1Click:Connect(function() pcall(callback) end)
                return btn
            end

            function SectionAPI:AddToggle(text, default, callback)
                local state = default == true
                local row = make("Frame", {Size = UDim2.new(1,0,0,32), BackgroundTransparency = 1, Parent = sec})
                local lbl = make("TextLabel", {Text = text or "Toggle", Size = UDim2.new(1,-80,1,0), Position = UDim2.new(0,8,0,0), BackgroundTransparency = 1, TextColor3 = th.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = row})
                local switch = make("TextButton", {Text = state and "ON" or "OFF", Size = UDim2.new(0,68,0,22), Position = UDim2.new(1,-76,0,5), BackgroundColor3 = th.Panel, TextColor3 = th.Text, Parent = row})
                switch.AutoButtonColor = true
                switch.MouseButton1Click:Connect(function()
                    state = not state
                    switch.Text = state and "ON" or "OFF"
                    pcall(callback, state)
                end)
                return {Set = function(_,v) state = v; switch.Text = state and "ON" or "OFF" end, Get = function() return state end}
            end

            function SectionAPI:AddSlider(text, min, max, default, callback)
                min = min or 0; max = max or 100; default = default or min
                local val = default
                local container = make("Frame", {Size = UDim2.new(1,0,0,44), BackgroundTransparency = 1, Parent = sec})
                local label = make("TextLabel", {Text = (text or "Slider")..": "..tostring(val), Size = UDim2.new(1,-16,0,18), Position = UDim2.new(0,8,0,0), BackgroundTransparency = 1, TextColor3 = th.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = container})
                local bar = make("Frame", {Size = UDim2.new(1,-16,0,12), Position = UDim2.new(0,8,0,24), BackgroundColor3 = th.Panel, Parent = container})
                local fill = make("Frame", {Size = UDim2.new((val-min)/(max-min),0,1,0), BackgroundColor3 = th.Accent, Parent = bar})
                local dragging = false
                local function update(x)
                    local rel = clamp((x - bar.AbsolutePosition.X)/bar.AbsoluteSize.X, 0, 1)
                    fill.Size = UDim2.new(rel, 0, 1, 0)
                    val = min + math.floor(rel*(max-min))
                    label.Text = (text or "Slider")..": "..tostring(val)
                    pcall(callback, val)
                end
                bar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=true; update(i.Position.X) end end)
                bar.InputChanged:Connect(function(i) if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then update(i.Position.X) end end)
                UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end end)
                return {Set = function(_,v) val = clamp(v,min,max); fill.Size = UDim2.new((val-min)/(max-min),0,1,0); label.Text = (text or "Slider")..": "..tostring(val); pcall(callback, val) end, Get = function() return val end}
            end

            function SectionAPI:AddDropdown(text, options, defaultSelection, multiSelect, callback)
                options = options or {}
                defaultSelection = defaultSelection or {}
                if type(defaultSelection) ~= "table" then defaultSelection = {defaultSelection} end
                local sel = {}
                for _,d in ipairs(defaultSelection) do sel[d] = true end

                local container = make("Frame", {Size = UDim2.new(1,0,0,32), BackgroundTransparency = 1, Parent = sec})
                local lbl = make("TextLabel", {Text = text or "Dropdown", Size = UDim2.new(1,-120,1,0), Position = UDim2.new(0,8,0,0), BackgroundTransparency = 1, TextColor3 = th.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = container})
                local btn = make("TextButton", {Text = "v", Size = UDim2.new(0,36,0,24), Position = UDim2.new(1,-44,0,4), BackgroundColor3 = th.Panel, TextColor3 = th.Text, Parent = container})
                local open = false
                local listFrame

                local function buildList()
                    if listFrame then listFrame:Destroy() end
                    listFrame = make("Frame", {Size = UDim2.new(1,0,0, math.min(#options * 30, 220)), Position = UDim2.new(0,0,0,36), BackgroundColor3 = th.Panel, Parent = container})
                    local layout = make("UIListLayout", {Parent = listFrame, Padding = UDim.new(0,4), SortOrder = Enum.SortOrder.LayoutOrder})
                    make("UIPadding", {Parent = listFrame, PaddingTop = UDim.new(0,6), PaddingLeft = UDim.new(0,6)})
                    for _,opt in ipairs(options) do
                        local it = make("TextButton", {Size = UDim2.new(1,0,0,28), Text = tostring(opt), Parent = listFrame, BackgroundTransparency = 0, BackgroundColor3 = th.Panel, TextColor3 = th.Text})
                        it.AutoButtonColor = true
                        it.MouseButton1Click:Connect(function()
                            if multiSelect then
                                sel[opt] = not sel[opt]
                                pcall(callback, (function()
                                    local out = {}
                                    for k,v in pairs(sel) do if v then table.insert(out, k) end end
                                    return out
                                end)())
                                -- visual toggle
                                if sel[opt] then it.BackgroundColor3 = th.Accent else it.BackgroundColor3 = th.Panel end
                            else
                                -- single select
                                sel = {}
                                sel[opt] = true
                                pcall(callback, opt)
                                if listFrame then listFrame:Destroy() end
                                open = false
                            end
                        end)
                    end
                end

                btn.MouseButton1Click:Connect(function()
                    open = not open
                    if open then buildList() else if listFrame then listFrame:Destroy() end end
                end)

                return {
                    GetSelection = function()
                        if multiSelect then
                            local out = {}
                            for k,v in pairs(sel) do if v then table.insert(out, k) end end
                            return out
                        else
                            for k,v in pairs(sel) do if v then return k end end
                            return nil
                        end
                    end,
                    Set = function(_,value)
                        if multiSelect then
                            sel = {}
                            for _,v in ipairs(value or {}) do sel[v] = true end
                        else
                            sel = {}
                            sel[value] = true
                        end
                    end
                }
            end

            return SectionAPI
        end

        return tab
    end

    -- window-level API
    local API = {}
    function API:CreateTab(name) return newTab(name) end
    function API:Destroy() pcall(function() sg:Destroy() end); _G.YATIM_UI_INSTANCE = nil end
    function API:SetTheme(name)
        if Themes[name] then YATIM.Settings.Theme = name; pcall(function() sg:Destroy() end); return YATIM:CreateWindow({Title = title, Theme = name, Size = size}) end
    end
    function API:SaveConfig(tbl)
        if not canIO() then return false, "no io" end
        return saveConfig(YATIM.Settings.ConfigFile, tbl)
    end
    function API:LoadConfig()
        return loadConfig(YATIM.Settings.ConfigFile)
    end

    -- minimize / restore
    local minimized = false
    local restoreBtn
    btnClose.MouseButton1Click:Connect(function() API:Destroy() end)
    btnMin.MouseButton1Click:Connect(function()
        if not minimized then
            root.Visible = false
            minimized = true
            restoreBtn = make("TextButton", {Text = "YATIM", Size = UDim2.new(0,56,0,56), Position = UDim2.new(0.5,-28,0,12), AnchorPoint = Vector2.new(0.5,0), BackgroundColor3 = th.Accent, TextColor3 = th.Text, Parent = sg, AutoButtonColor = true})
            restoreBtn.MouseButton1Click:Connect(function()
                root.Visible = true
                minimized = false
                pcall(function() restoreBtn:Destroy() end)
            end)
        else
            root.Visible = true
            minimized = false
            if restoreBtn then pcall(function() restoreBtn:Destroy() end) end
        end
    end)

    -- hotkey toggle
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == YATIM.Settings.Hotkey then
            root.Visible = not root.Visible
        end
    end)

    return API
end

-- Factory
return function() return _G.YATIM_UI_INSTANCE end

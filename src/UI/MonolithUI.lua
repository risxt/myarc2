-- MonolithUI.lua
-- Extracted UI library + legacy UI from gag2.lua for modular runtime.
local MonolithUI = {}

function MonolithUI.init(deps)
    local Cfg = deps.Cfg or _G.Cfg or {}
    local UIRegistry = deps.UIRegistry
    local ToggleBinder = deps.ToggleBinder

    local Players = game:GetService("Players")
    local Player = Players.LocalPlayer
    local LocalPlayer = Player
    local RunService = game:GetService("RunService")
    local TweenService = game:GetService("TweenService")
    local UserInputService = game:GetService("UserInputService")
    local VirtualUser = game:GetService("VirtualUser")
    local VirtualInputManager = game:GetService("VirtualInputManager")
    local TeleportService = game:GetService("TeleportService")
    local CoreGui = game:GetService("CoreGui")
    local HttpService = game:GetService("HttpService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Workspace = workspace

    _G.Cfg = Cfg
    _G.Menu = _G.Menu or { ['Main'] = { ['Auto Hatch'] = false } }

local Custom = {} do
  Custom.ColorRGB = Color3.fromRGB(0, 160, 255)

  function Custom:Create(Name, Properties, Parent)
    local _instance = Instance.new(Name)

    for i, v in pairs(Properties) do
      _instance[i] = v
    end

    if Parent then
      _instance.Parent = Parent
    end

    return _instance
  end

  function Custom:EnabledAFK()
    if _G._GAG_AntiAFK_Enabled then return end
    _G._GAG_AntiAFK_Enabled = true

    local lastActivity = os.clock()
    local function markActivity()
      lastActivity = os.clock()
    end

    UserInputService.InputBegan:Connect(markActivity)
    UserInputService.InputChanged:Connect(markActivity)

    local function pulseInput()
      pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new(0, 0))
        VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        task.wait(0.05)
        VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
      end)

      pcall(function()
        local cam = workspace.CurrentCamera
        local viewport = cam and cam.ViewportSize or Vector2.new(800, 600)
        local x, y = math.floor(viewport.X * 0.5), math.floor(viewport.Y * 0.5)
        VirtualInputManager:SendMouseMoveEvent(x, y, game)
        VirtualInputManager:SendMouseButtonEvent(x, y, 1, true, game, 0)
        task.wait(0.03)
        VirtualInputManager:SendMouseButtonEvent(x, y, 1, false, game, 0)
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game)
        task.wait(0.03)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game)
      end)
    end

    local function nudgeCharacter()
      pcall(function()
        local char = Player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health > 0 and hum.MoveDirection.Magnitude < 0.05 then
          hum.Jump = true
          hum:Move(Vector3.new(0.015, 0, 0), false)
          task.wait(0.08)
          hum:Move(Vector3.zero, false)
        end
      end)
    end

    Player.Idled:Connect(function()
      pulseInput()
      nudgeCharacter()
      markActivity()
    end)

    task.spawn(function()
      while not Speed_Library or not Speed_Library.Unloaded do
        task.wait(35)
        if os.clock() - lastActivity >= 30 then
          pulseInput()
          nudgeCharacter()
          markActivity()
        end
      end
    end)

    CoreGui.ChildAdded:Connect(function(child)
      if child.Name == "RobloxPromptGui" then
        task.wait(3)
        pcall(function()
          TeleportService:Teleport(game.PlaceId, Player)
        end)
      end
    end)
  end
end

Custom:EnabledAFK()

local function OpenClose()
  local ScreenGui = Custom:Create("ScreenGui", {
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
  }, RunService:IsStudio() and Player.PlayerGui or (gethui() or cloneref(game:GetService("CoreGui")) or game:GetService("CoreGui")))

  local Close_ImageButton = Custom:Create("ImageButton", {
    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
    BorderColor3 = Color3.fromRGB(255, 0, 0),
    BackgroundTransparency = 1,
    Position = UDim2.new(0.1021, 0, 0.0743, 0),
    Size = UDim2.new(0, 59, 0, 49),
    Image = "rbxassetid://136890595976124",
    Visible = false,
  }, ScreenGui)

  local UICorner = Custom:Create("UICorner", {
    Name = "MainCorner",
    CornerRadius = UDim.new(0, 9),
  }, Close_ImageButton)

  local dragging, dragStart, startPos = false, nil, nil

  local function UpdateDraggable(input)
    local delta = input.Position - dragStart
    Close_ImageButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
  end

  Close_ImageButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
      dragging = true
      dragStart = input.Position
      startPos = Close_ImageButton.Position

      input.Changed:Connect(function()
        if input.UserInputState == Enum.UserInputState.End then
          dragging = false
        end
      end)
    end
  end)

  Close_ImageButton.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
      UpdateDraggable(input)
    end
  end)

  return Close_ImageButton
end

local Open_Close = OpenClose()

local function MakeDraggable(topbarobject, object)
  local dragging = false
  local dragStart, startPos, targetPos = nil, nil, nil
  local renderConn, endConn = nil, nil

  local function stopDrag()
    dragging = false
    if renderConn then renderConn:Disconnect(); renderConn = nil end
    if endConn then endConn:Disconnect(); endConn = nil end
  end

  local function UpdateTarget(input)
    if not dragging or not dragStart or not startPos then return end
    local delta = input.Position - dragStart
    targetPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
  end

  topbarobject.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
      dragging = true
      dragStart = input.Position
      startPos = object.Position
      targetPos = startPos

      if renderConn then renderConn:Disconnect() end
      renderConn = RunService.RenderStepped:Connect(function()
        if dragging and targetPos then
          object.Position = targetPos
        end
      end)

      if endConn then endConn:Disconnect() end
      endConn = input.Changed:Connect(function()
        if input.UserInputState == Enum.UserInputState.End then
          stopDrag()
        end
      end)
    end
  end)

  UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
      UpdateTarget(input)
    end
  end)
end

function CircleClick(Button, X, Y)
	task.spawn(function()
		Button.ClipsDescendants = true
		
		local Circle = Instance.new("ImageLabel")
		Circle.Image = "rbxassetid://106471194043211"
		Circle.ImageColor3 = Color3.fromRGB(80, 80, 80)
		Circle.ImageTransparency = 0.8999999761581421
		Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Circle.BackgroundTransparency = 1
		Circle.ZIndex = 10
		Circle.Name = "Circle"
		Circle.Parent = Button
		
		local NewX = X - Button.AbsolutePosition.X
		local NewY = Y - Button.AbsolutePosition.Y
		Circle.Position = UDim2.new(0, NewX, 0, NewY)

		local Size = math.max(Button.AbsoluteSize.X, Button.AbsoluteSize.Y) * 1.5

		local Time = 0.5
		local TweenInfo = TweenInfo.new(Time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

		local Tween = TweenService:Create(Circle, TweenInfo, {
			Size = UDim2.new(0, Size, 0, Size),
			Position = UDim2.new(0.5, -Size/2, 0.5, -Size/2)
		})
		
		Tween:Play()
		
		Tween.Completed:Connect(function()
			for i = 1, 10 do
				Circle.ImageTransparency = Circle.ImageTransparency + 0.01
				wait(Time / 10)
			end
			Circle:Destroy()
		end)
	end)
end

local Speed_Library, Notification = {}, {}

if _G.__GAG2_ACTIVE_LIBRARY and type(_G.__GAG2_ACTIVE_LIBRARY) == "table" then
    _G.__GAG2_ACTIVE_LIBRARY.Unloaded = true
end

for _, parent in ipairs({ gethui and gethui() or nil, game:GetService("CoreGui"), Player:FindFirstChildOfClass("PlayerGui") }) do
    if parent then
        local oldGui = parent:FindFirstChild("SpeedHubXGui")
        if oldGui then oldGui:Destroy() end
    end
end

Speed_Library.Unloaded = false
_G.__GAG2_ACTIVE_LIBRARY = Speed_Library

function Speed_Library:SetNotification(Config)
  local Title = Config[1] or Config.Title or ""
  local Description = Config[2] or Config.Description or ""
	local Content = Config[3] or Config.Content or ""
  local Time = Config[5] or Config.Time or 0.5
  local Delay = Config[6] or Config.Delay or 5

  local NotificationGui = Custom:Create("ScreenGui", {
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
  }, RunService:IsStudio() and Player.PlayerGui or (gethui() or cloneref(game:GetService("CoreGui")) or game:GetService("CoreGui")))

  local NotificationLayout = Custom:Create("Frame", {
    AnchorPoint = Vector2.new(1, 1),
    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
    BackgroundTransparency = 0.999,
    BorderColor3 = Color3.fromRGB(0, 0, 0),
    BorderSizePixel = 0,
    Position = UDim2.new(1, -30, 1, -30),
    Size = UDim2.new(0, 320, 1, 0),
    Name = "NotificationLayout"
  }, NotificationGui)

  local Count = 0

  NotificationLayout.ChildRemoved:Connect(function()
    Count = 0
    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
    
    for _, v in ipairs(NotificationLayout:GetChildren()) do
      local NewPOS = UDim2.new(0, 0, 1, -((v.Size.Y.Offset + 12) * Count))
      local tween = TweenService:Create(v, tweenInfo, {Position = NewPOS})
      tween:Play()
      Count = Count + 1
    end
  end)

  local _Count = 0
  for _, v in ipairs(NotificationLayout:GetChildren()) do
    _Count = -(v.Position.Y.Offset) + v.Size.Y.Offset + 12
  end

  local NotificationFrame = Custom:Create("Frame", {
    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
    BorderColor3 = Color3.fromRGB(0, 0, 0),
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, 150),
    Name = "NotificationFrame",
    BackgroundTransparency = 1,
    AnchorPoint = Vector2.new(0, 1),
    Position = UDim2.new(0, 0, 1, -(_Count))
  }, NotificationLayout)

  local NotificationFrameReal = Custom:Create("Frame", {
    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
    BorderColor3 = Color3.fromRGB(0, 0, 0),
    BorderSizePixel = 0,
    Position = UDim2.new(0, 400, 0, 0),
    Size = UDim2.new(1, 0, 1, 0),
    Name = "NotificationFrameReal"
  }, NotificationFrame)

  Custom:Create("UICorner", {
    CornerRadius = UDim.new(0, 8)
  }, NotificationFrameReal)

  local DropShadowHolder = Custom:Create("Frame", {
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 1, 0),
    ZIndex = 0,
    Name = "DropShadowHolder",
    Parent = NotificationFrameReal
  })

  local DropShadow = Custom:Create("ImageLabel", {
    Image = "",
    ImageColor3 = Color3.fromRGB(0, 0, 0),
    ImageTransparency = 0.5,
    ScaleType = Enum.ScaleType.Slice,
    SliceCenter = Rect.new(49, 49, 450, 450),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.new(1, 47, 1, 47),
    ZIndex = 0,
    Name = "DropShadow",
    Parent = DropShadowHolder
  })
 
  local Top = Custom:Create("Frame", {
    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
    BackgroundTransparency = 0.999,
    BorderColor3 = Color3.fromRGB(0, 0, 0),
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, 36),
    Name = "Top",
    Parent = NotificationFrameReal
  })

  local TextLabel = Custom:Create("TextLabel", {
    Font = Enum.Font.GothamBold,
    Text = Title,
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left,
    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
    BackgroundTransparency = 0.999,
    BorderColor3 = Color3.fromRGB(0, 0, 0),
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 1, 0),
    Position = UDim2.new(0, 10, 0, 0),
    Parent = Top
  })

  Custom:Create("UIStroke", {
    Color = Color3.fromRGB(255, 255, 255),
    Thickness = 0.3,
    Parent = TextLabel
  })

  Custom:Create("UICorner", {
    Parent = Top,
    CornerRadius = UDim.new(0, 5)
  })

  local TextLabel1 = Custom:Create("TextLabel", {
    Font = Enum.Font.GothamBold,
    Text = Description,
    TextColor3 = Custom.ColorRGB,
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left,
    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
    BackgroundTransparency = 0.999,
    BorderColor3 = Color3.fromRGB(0, 0, 0),
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 1, 0),
    Position = UDim2.new(0, TextLabel.TextBounds.X + 15, 0, 0),
    Parent = Top
  })

  Custom:Create("UIStroke", {
    Color = Custom.ColorRGB,
    Thickness = 0.4,
    Parent = TextLabel1
  })

  local Close = Custom:Create("TextButton", {
    Font = Enum.Font.SourceSans,
    Text = "X",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 18,
    AnchorPoint = Vector2.new(1, 0.5),
    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
    BackgroundTransparency = 0.999,
    BorderColor3 = Color3.fromRGB(0, 0, 0),
    BorderSizePixel = 0,
    Position = UDim2.new(1, -5, 0.5, 0),
    Size = UDim2.new(0, 25, 0, 25),
    Name = "Close",
    Parent = Top
  })

  local TextLabel2 = Custom:Create("TextLabel", {
    Font = Enum.Font.GothamBold,
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 13,
    Text = Content,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
    BackgroundTransparency = 0.999,
    TextColor3 = Color3.fromRGB(150, 150, 150),
    BorderColor3 = Color3.fromRGB(0, 0, 0),
    BorderSizePixel = 0,
    Position = UDim2.new(0, 10, 0, 27),
    Size = UDim2.new(1, -20, 0, 13),
    Parent = NotificationFrameReal
  })

  TextLabel2.Size = UDim2.new(1, -20, 0, 13 + (13 * (TextLabel2.TextBounds.X // TextLabel2.AbsoluteSize.X)))
  TextLabel2.TextWrapped = true

  if TextLabel2.AbsoluteSize.Y < 27 then
    NotificationFrame.Size = UDim2.new(1, 0, 0, 65)
  else
    NotificationFrame.Size = UDim2.new(1, 0, 0, TextLabel2.AbsoluteSize.Y + 40)
  end

  local Waitted = false
  local NotifObj = {}

  function NotifObj:Close()
    if Waitted then return false end
    Waitted = true

    local tween = TweenService:Create(NotificationFrameReal,TweenInfo.new(tonumber(Time), Enum.EasingStyle.Back, Enum.EasingDirection.InOut),{Position = UDim2.new(0, 400, 0, 0)})
    tween:Play()

    task.wait(tonumber(Time) / 1.2)

    NotificationFrame:Destroy()

    Waitted = false
  end

  Close.Activated:Connect(function()
    NotifObj:Close()
	end)

  TweenService:Create(NotificationFrameReal, TweenInfo.new(tonumber(Time), Enum.EasingStyle.Back, Enum.EasingDirection.InOut), {Position = UDim2.new(0, 0, 0, 0)} ):Play()
  task.wait(tonumber(Delay))
  NotifObj:Close()

  return NotifObj
end

function Speed_Library:CreateWindow(Config)
  local Title = Config[1] or Config.Title or ""
  local Description = Config[2] or Config.Description or ""
  local TabWidth = Config[3] or Config["Tab Width"] or 120
  local SizeUi = Config[4] or Config.SizeUi or UDim2.fromOffset(550, 315)

  local Funcs = {}

  local SpeedHubXGui = Custom:Create("ScreenGui", {
    Name = "SpeedHubXGui",
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
  }, RunService:IsStudio() and Player.PlayerGui or (gethui() or cloneref(game:GetService("CoreGui")) or game:GetService("CoreGui")))

  local DropShadowHolder = Custom:Create("Frame", {
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Size = UDim2.new(0, 455, 0, 350),
    ZIndex = 0,
    Name = "DropShadowHolder",
    Position = UDim2.new(0, (SpeedHubXGui.AbsoluteSize.X // 2 - 455 // 2), 0, (SpeedHubXGui.AbsoluteSize.Y // 2 - 350 // 2))
  }, SpeedHubXGui)

  local DropShadow = Custom:Create("ImageLabel", {
    Image = "",
    ImageColor3 = Color3.fromRGB(15, 15, 15),
    ImageTransparency = 0.5,
    ScaleType = Enum.ScaleType.Slice,
    SliceCenter = Rect.new(49, 49, 450, 450),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = SizeUi,
    ZIndex = 0,
    Name = "DropShadow"
  }, DropShadowHolder)

  local Main = Custom:Create("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = Color3.fromRGB(15, 15, 15),
    BackgroundTransparency = 0.1,
    BorderColor3 = Color3.fromRGB(0, 0, 0),
    BorderSizePixel = 0,
    Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = SizeUi,
    Name = "Main"
  }, DropShadow)

  Custom:Create("UICorner", {}, Main)

  Custom:Create("UIStroke", {
    Color = Color3.fromRGB(50, 50, 50),
    Thickness = 1.6
  }, Main)

  local Top = Custom:Create("Frame", {
    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
    BackgroundTransparency = 0.9990000128746033,
    BorderColor3 = Color3.fromRGB(0, 0, 0),
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, 38),
    Name = "Top"
  }, Main)

  local TextLabel = Custom:Create("TextLabel", {
    Font = Enum.Font.GothamBold,
    Text = Title,
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left,
    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
    BackgroundTransparency = 0.9990000128746033,
    BorderColor3 = Color3.fromRGB(0, 0, 0),
    BorderSizePixel = 0,
    Size = UDim2.new(1, -100, 1, 0),
    Position = UDim2.new(0, 10, 0, 0)
  }, Top)

  Custom:Create("UICorner", {}, Top)

  local TextLabel1 = Custom:Create("TextLabel", {
    Font = Enum.Font.GothamBold,
    Text = Description,
    TextColor3 = Custom.ColorRGB,
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left,
    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
    BackgroundTransparency = 0.9990000128746033,
    BorderColor3 = Color3.fromRGB(0, 0, 0),
    BorderSizePixel = 0,
    Size = UDim2.new(1, -(TextLabel.TextBounds.X + 104), 1, 0),
    Position = UDim2.new(0, TextLabel.TextBounds.X + 15, 0, 0)
  }, Top)

  Custom:Create("UIStroke", {
    Color = Custom.ColorRGB,
    Thickness = 0.4
  }, TextLabel1)

  local Close = Custom:Create("TextButton", {
    Font = Enum.Font.SourceSans,
    Text = "X",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 18,
    AnchorPoint = Vector2.new(1, 0.5),
    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
    BackgroundTransparency = 0.9990000128746033,
    BorderColor3 = Color3.fromRGB(0, 0, 0),
    BorderSizePixel = 0,
    Position = UDim2.new(1, -8, 0.5, 0),
    Size = UDim2.new(0, 25, 0, 25),
    Name = "Close"
  }, Top)

  local Min = Custom:Create("TextButton", {
    Font = Enum.Font.SourceSans,
    Text = "-", 
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 18,
    AnchorPoint = Vector2.new(1, 0.5),
    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
    BackgroundTransparency = 0.9990000128746033,
    BorderColor3 = Color3.fromRGB(0, 0, 0),
    BorderSizePixel = 0,
    Position = UDim2.new(1, -42, 0.5, 0),
    Size = UDim2.new(0, 25, 0, 25),
    Name = "Min"
}, Top)

  local LayersTab = Custom:Create("Frame", {
    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
    BackgroundTransparency = 0.9990000128746033,
    BorderColor3 = Color3.fromRGB(0, 0, 0),
    BorderSizePixel = 0,
    Position = UDim2.new(0, 9, 0, 50),
    Size = UDim2.new(0, TabWidth, 1, -59),
    Name = "LayersTab"
  }, Main)

  Custom:Create("UICorner", {
    CornerRadius = UDim.new(0, 2)
  }, LayersTab)

  Custom:Create("Frame", {
    AnchorPoint = Vector2.new(0.5, 0),
    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
    BackgroundTransparency = 0.85,
    BorderColor3 = Color3.fromRGB(0, 0, 0),
    BorderSizePixel = 0,
    Position = UDim2.new(0.5, 0, 0, 38),
    Size = UDim2.new(1, 0, 0, 1),
    Name = "DecideFrame"
  }, Main)

  local Layers = Custom:Create("Frame", {
    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
    BackgroundTransparency = 0.9990000128746033,
    BorderColor3 = Color3.fromRGB(0, 0, 0),
    BorderSizePixel = 0,
    Position = UDim2.new(0, TabWidth + 18, 0, 50),
    Size = UDim2.new(1, -(TabWidth + 9 + 18), 1, -59),
    Name = "Layers"
  }, Main)

  Custom:Create("UICorner", {
    CornerRadius = UDim.new(0, 2)
  }, Layers)

  local NameTab = Custom:Create("TextLabel", {
    Font = Enum.Font.GothamBold,
    Text = "",
    TextColor3 = Color3.fromRGB(255, 255, 255),
    TextSize = 24,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
    BackgroundTransparency = 0.9990000128746033,
    BorderColor3 = Color3.fromRGB(0, 0, 0),
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, 30),
    Name = "NameTab"
  }, Layers)

  local LayersReal = Custom:Create("Frame", {
    AnchorPoint = Vector2.new(0, 1),
    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
    BackgroundTransparency = 0.9990000128746033,
    BorderColor3 = Color3.fromRGB(0, 0, 0),
    BorderSizePixel = 0,
    ClipsDescendants = true,
    Position = UDim2.new(0, 0, 1, 0),
    Size = UDim2.new(1, 0, 1, -33),
    Name = "LayersReal"
  }, Layers)

  local LayersFolder = Custom:Create("Folder", {
    Name = "LayersFolder"
  }, LayersReal)

  local LayersPageLayout = Custom:Create("UIPageLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder,
    Name = "LayersPageLayout",
    TweenTime = 0.5,
    EasingDirection = Enum.EasingDirection.InOut,
    EasingStyle = Enum.EasingStyle.Quad
  }, LayersFolder)

  local ScrollTab = Custom:Create("ScrollingFrame", {
    CanvasSize = UDim2.new(0, 0, 2.10000002, 0),
    ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0),
    ScrollBarThickness = 0,
    Active = true,
    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
    BackgroundTransparency = 0.9990000128746033,
    BorderColor3 = Color3.fromRGB(0, 0, 0),
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 1, -10),
    Name = "ScrollTab"
  }, LayersTab)

  local UIListLayout = Custom:Create("UIListLayout", {
    Padding = UDim.new(0, 0),
    SortOrder = Enum.SortOrder.LayoutOrder
  }, ScrollTab)

  local function UpdateSize()
    local _Total = 0

		for _, v in pairs(ScrollTab:GetChildren()) do
			if v.Name ~= "UIListLayout" then
				_Total = _Total + 3 + v.Size.Y.Offset
			end
		end

		ScrollTab.CanvasSize = UDim2.new(0, 0, 0, _Total)
  end

  ScrollTab.ChildAdded:Connect(UpdateSize)
  ScrollTab.ChildRemoved:Connect(UpdateSize)

  Min.Activated:Connect(function()
		CircleClick(Min, Player:GetMouse().X, Player:GetMouse().Y)
		DropShadowHolder.Visible = false

		if not Open_Close.Visible then Open_Close.Visible = true end
	end)

  Open_Close.Activated:Connect(function()
		DropShadowHolder.Visible = true
		if Open_Close.Visible then Open_Close.Visible = false end
	end)

  Close.Activated:Connect(function()
		CircleClick(Close, Player:GetMouse().X, Player:GetMouse().Y)
    if SpeedHubXGui then SpeedHubXGui:Destroy() end
		if not Speed_Library.Unloaded then Speed_Library.Unloaded = true end
	end)

  DropShadowHolder.Size = UDim2.new(0, 115 + TextLabel.TextBounds.X + 1 + TextLabel1.TextBounds.X, 0, 350)
	MakeDraggable(Top, DropShadowHolder)


  -- /// Blur

  local MoreBlur = Custom:Create("Frame", {
    AnchorPoint = Vector2.new(1, 1),
    BackgroundColor3 = Color3.fromRGB(0, 0, 0),
    BackgroundTransparency = 1,
    BorderColor3 = Color3.fromRGB(0, 0, 0),
    BorderSizePixel = 0,
    ClipsDescendants = true,
    Position = UDim2.new(1, 8, 1, 8),
    Size = UDim2.new(1, 154, 1, 54),
    Visible = false,
    Name = "MoreBlur"
  }, Layers)

  local DropShadowHolder1 = Custom:Create("Frame", {
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 1, 0),
    ZIndex = 0,
    Name = "DropShadowHolder"
  }, MoreBlur)

  local DropShadow1 = Custom:Create("ImageLabel", {
    Image = "",
    ImageColor3 = Color3.fromRGB(0, 0, 0),
    ImageTransparency = 0.5,
    ScaleType = Enum.ScaleType.Slice,
    SliceCenter = Rect.new(49, 49, 450, 450),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.new(1, 35, 1, 35),
    ZIndex = 0,
    Name = "DropShadow"
  }, DropShadowHolder1)

  Custom:Create("UICorner", {}, MoreBlur)

  local ConnectButton = Custom:Create("TextButton", {
		Font = Enum.Font.SourceSans,
		Text = "",
		TextColor3 = Color3.fromRGB(0, 0, 0),
		TextSize = 14,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.999,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		Name = "ConnectButton",
	}, MoreBlur)

  local DropdownSelect = Custom:Create("Frame", {
    AnchorPoint = Vector2.new(1, 0.5),
    BackgroundColor3 = Color3.fromRGB(30, 30, 30),
    BorderColor3 = Color3.fromRGB(0, 0, 0),
    BorderSizePixel = 0,
    LayoutOrder = 1,
    Position = UDim2.new(1, 172, 0.5, 0),
    Size = UDim2.new(0, 160, 1, -16),
    Name = "DropdownSelect",
    ClipsDescendants = true,
  }, MoreBlur)

  ConnectButton.Activated:Connect(function()
    if MoreBlur.Visible then
      local tweenInfo = TweenInfo.new(0.2)

      local _Hide = TweenService:Create(MoreBlur, tweenInfo, {BackgroundTransparency = 0.999})
      local _Move = TweenService:Create(DropdownSelect, tweenInfo, {Position = UDim2.new(1, 172, 0.5, 0)})

      _Hide:Play()
      _Move:Play()
        
      task.wait(0.2)
      MoreBlur.Visible = false
    end
  end)

  Custom:Create("UICorner", {
    CornerRadius = UDim.new(0, 3),
    Parent = DropdownSelect
  })

  Custom:Create("UIStroke", {
    Color = Color3.fromRGB(255, 255, 255),
    Thickness = 2.5,
    Transparency = 0.8,
    Parent = DropdownSelect
  })

  local DropdownSelectReal = Custom:Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.999,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		LayoutOrder = 1,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(1, -10, 1, -10),
		Name = "DropdownSelectReal",
		Parent = DropdownSelect
	})

  local DropdownFolder = Custom:Create("Folder", {
		Name = "DropdownFolder",
		Parent = DropdownSelectReal
	})

  local DropPageLayout = Custom:Create("UIPageLayout", {
    EasingDirection = Enum.EasingDirection.InOut,
    EasingStyle = Enum.EasingStyle.Quad,
    TweenTime = 0.01,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Archivable = false,
    Name = "DropPageLayout",
    Parent = DropdownFolder
  })

  -- /// Create Tab

  local Tabs = {}
  local CountTab = 0
  local CountDropdown = 0
  function Tabs:CreateTab(Config)
    local _Name = Config[1] or Config.Name or "" 
    local Icon = Config[2] or Config.Icon or ""
    
    local ScrolLayers = Custom:Create("ScrollingFrame", {
			ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80),
			ScrollBarThickness = 0,
			Active = true,
			LayoutOrder = CountTab,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.999,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, 0),
			Name = "ScrolLayers",
			Parent = LayersFolder
		})

    Custom:Create("UIListLayout", {
      Padding = UDim.new(0, 3),
      SortOrder = Enum.SortOrder.LayoutOrder,
      Parent = ScrolLayers
    })

    local Tab = Custom:Create("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = CountTab == 0 and 0.92 or 0.999,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			LayoutOrder = CountTab,
			Size = UDim2.new(1, 0, 0, 32),
			Name = "Tab",
			Parent = ScrollTab
		})

    Custom:Create("UICorner", {
      CornerRadius = UDim.new(0, 4),
      Parent = Tab
    })

    local TabButton = Custom:Create("TextButton", {
      Font = Enum.Font.GothamBold,
      Text = "",
      TextColor3 = Color3.fromRGB(255, 255, 255),
      TextSize = 13,
      TextXAlignment = Enum.TextXAlignment.Left,
      BackgroundColor3 = Color3.fromRGB(255, 255, 255),
      BackgroundTransparency = 0.999,
      BorderColor3 = Color3.fromRGB(0, 0, 0),
      BorderSizePixel = 0,
      Size = UDim2.new(1, 0, 1, 0),
      Name = "TabButton",
    }, Tab)

    Custom:Create("TextLabel", {
      Font = Enum.Font.GothamBold,
      Text = _Name,
      TextColor3 = Color3.fromRGB(255, 255, 255),
      TextSize = 13,
      TextXAlignment = Enum.TextXAlignment.Left,
      BackgroundColor3 = Color3.fromRGB(255, 255, 255),
      BackgroundTransparency = 0.999,
      BorderColor3 = Color3.fromRGB(0, 0, 0),
      BorderSizePixel = 0,
      Size = UDim2.new(1, 0, 1, 0),
      Position = UDim2.new(0, 30, 0, 0),
      Name = "TabName",
    }, Tab)

    Custom:Create("ImageLabel", {
      Image = Icon,
      ImageColor3 = Color3.fromRGB(255, 255, 255),
      BackgroundColor3 = Color3.fromRGB(255, 255, 255),
      BackgroundTransparency = 0.999,
      BorderColor3 = Color3.fromRGB(0, 0, 0),
      BorderSizePixel = 0,
      Position = UDim2.new(0, 7, 0, 7),
      Size = UDim2.new(0, 18, 0, 18),
      Name = "FeatureImg",
    }, Tab)

    if CountTab == 0 then
      LayersPageLayout:JumpToIndex(0)
      NameTab.Text = _Name
  
      local ChooseFrame = Custom:Create("Frame", {
        BackgroundColor3 = Custom.ColorRGB,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 2, 0, 9),
        Size = UDim2.new(0, 1, 0, 12),
        Name = "ChooseFrame",
      }, Tab)
  
      Custom:Create("UIStroke", {
        Color = Custom.ColorRGB,
        Thickness = 1.6,
      }, ChooseFrame)
  
      Custom:Create("UICorner", {}, ChooseFrame)
    end

    TabButton.Activated:Connect(function()
      CircleClick(TabButton, Player:GetMouse().X, Player:GetMouse().Y)
      local FrameChoose = nil

      for _, s in pairs(ScrollTab:GetChildren()) do
        for _, v in pairs(s:GetChildren()) do
          if v.Name == "ChooseFrame" then
            FrameChoose = v
            break
          end
        end

        if FrameChoose then break end
      end
  
      if FrameChoose and Tab.LayoutOrder ~= LayersPageLayout.CurrentPage.LayoutOrder then
        for _, TabFrame in pairs(ScrollTab:GetChildren()) do
          if TabFrame.Name == "Tab" then
            TweenService:Create(TabFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.999}):Play()
          end
        end
  
        local _TabT = TweenService:Create(Tab, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.92})
        local _FTween = TweenService:Create(FrameChoose, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), { Position = UDim2.new(0, 2, 0, 9 + (33 * Tab.LayoutOrder)) })

        _TabT:Play()
        _FTween:Play()
  
        LayersPageLayout:JumpToIndex(Tab.LayoutOrder)
  
        task.wait(0.05)
        NameTab.Text = _Name
  
        TweenService:Create(FrameChoose, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Size = UDim2.new(0, 1, 0, 20)}):Play()
  
        task.wait(0.2)
        TweenService:Create(FrameChoose, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {Size = UDim2.new(0, 1, 0, 12)}):Play()
      end
    end)

    --- /// Section
   
    local Sections, CountSection = {}, 0

    function Sections:AddSection(Title, OpenSection)
      local Title = Title or ""
      local OpenSection = OpenSection or false
  
      local Section = Custom:Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.999,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        LayoutOrder = CountSection,
        Size = UDim2.new(1, 0, 0, 30),
        Name = "Section"
      }, ScrolLayers)
  
      local SectionReal = Custom:Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.935,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        LayoutOrder = 1,
        Position = UDim2.new(0.5, 0, 0, 0),
        Size = UDim2.new(1, 1, 0, 30),
        Name = "SectionReal"
      }, Section)
  
      Custom:Create("UICorner", {
        CornerRadius = UDim.new(0, 4)
      }, SectionReal)
  
      local SectionButton = Custom:Create("TextButton", {
        Font = Enum.Font.SourceSans,
        Text = "",
        TextColor3 = Color3.fromRGB(0, 0, 0),
        TextSize = 14,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.9990000128746033,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        Name = "SectionButton"
      }, SectionReal)
  
      local FeatureFrame = Custom:Create("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.9990000128746033,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Position = UDim2.new(1, -5, 0.5, 0),
        Size = UDim2.new(0, 20, 0, 20),
        Name = "FeatureFrame"
      }, SectionReal)
  
      local FeatureImg = Custom:Create("ImageLabel", {
        Image = "rbxassetid://125609963478878",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.9990000128746033,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Rotation = -90,
        Size = UDim2.new(1, 6, 1, 6),
        Name = "FeatureImg"
      }, FeatureFrame)
  
      local SectionTitle = Custom:Create("TextLabel", {
        Font = Enum.Font.GothamBold,
        Text = Title,
        TextColor3 = Color3.fromRGB(230, 230, 230),
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.9990000128746033,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 10, 0.5, 0),
        Size = UDim2.new(1, -50, 0, 13),
        Name = "SectionTitle"
      }, SectionReal)
  
      local SectionDecideFrame = Custom:Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 33),
        Size = UDim2.new(0, 0, 0, 2),
        Name = "SectionDecideFrame"
      }, Section)
      Custom:Create("UICorner", {}, SectionDecideFrame)
      Custom:Create("UIGradient", {
        Color = ColorSequence.new{
          ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 20, 20)),
          ColorSequenceKeypoint.new(0.5, Custom.ColorRGB),
          ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 20))
        }
      }, SectionDecideFrame)
  
      local SectionAdd = Custom:Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.9990000128746033,
        BorderColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        LayoutOrder = 1,
        Position = UDim2.new(0.5, 0, 0, 38),
        Size = UDim2.new(1, 0, 0, 100),
        Name = "SectionAdd"
      }, Section)
  
      Custom:Create("UICorner", {
        CornerRadius = UDim.new(0, 2)
      }, SectionAdd)
    
      Custom:Create("UIListLayout", {
        Padding = UDim.new(0, 3),
        SortOrder = Enum.SortOrder.LayoutOrder
      }, SectionAdd)
  
      local function UpdateSizeScroll()
        local OffsetY = 0
  
        for _, child in pairs(ScrolLayers:GetChildren()) do
          if child.Name ~= "UIListLayout" then
            OffsetY = OffsetY + 3 + child.Size.Y.Offset
          end
        end
        
        ScrolLayers.CanvasSize = UDim2.new(0, 0, 0, OffsetY)
      end
    
      local function UpdateSizeSection()
        if OpenSection then
          local SectionSizeYWitdh = 38
  
          for _, v in pairs(SectionAdd:GetChildren()) do
            if v.Name ~= "UIListLayout" and v.Name ~= "UICorner" then
              SectionSizeYWitdh = SectionSizeYWitdh + v.Size.Y.Offset + 3
            end
          end
    
          TweenService:Create(FeatureFrame, TweenInfo.new(0.1), {Rotation = 90}):Play()
          TweenService:Create(Section, TweenInfo.new(0.1), {Size = UDim2.new(1, 1, 0, SectionSizeYWitdh)}):Play()
          TweenService:Create(SectionAdd, TweenInfo.new(0.1), {Size = UDim2.new(1, 0, 0, SectionSizeYWitdh - 38)}):Play()
          TweenService:Create(SectionDecideFrame, TweenInfo.new(0.1), {Size = UDim2.new(1, 0, 0, 2)}):Play()
            
          task.wait(0.5)
          UpdateSizeScroll()
        end
      end
    
      local function ToggleSection()
        CircleClick(SectionButton, Player:GetMouse().X, Player:GetMouse().Y)
        
        if OpenSection then
          TweenService:Create(FeatureFrame, TweenInfo.new(0.1), {Rotation = 0}):Play()
          TweenService:Create(Section, TweenInfo.new(0.1), {Size = UDim2.new(1, 1, 0, 30)}):Play()
          TweenService:Create(SectionDecideFrame, TweenInfo.new(0.1), {Size = UDim2.new(0, 0, 0, 2)}):Play()
    
          OpenSection = false
          task.wait(0.1)
          UpdateSizeScroll()
        else
          OpenSection = true
          UpdateSizeSection()
        end
      end
    
      SectionButton.Activated:Connect(ToggleSection)
      SectionAdd.ChildAdded:Connect(UpdateSizeSection)
      SectionAdd.ChildRemoved:Connect(UpdateSizeSection)
    
      UpdateSizeScroll()

      local Item, ItemCount = {}, 0
      function Item:AddParagraph(Config)
        local Title = Config[1] or Config.Title or ""
        local Content = Config[2] or Config.Content or ""
        local SettingFuncs = {}

        local Paragraph = Custom:Create("Frame", {
          BackgroundColor3 = Color3.fromRGB(255, 255, 255),
          BackgroundTransparency = 0.935,
          BorderColor3 = Color3.fromRGB(0, 0, 0),
          BorderSizePixel = 0,
          LayoutOrder = ItemCount,
          Size = UDim2.new(1, 0, 0, 35),
          Name = "Paragraph",
        }, SectionAdd)
      
        Custom:Create("UICorner", {
          CornerRadius = UDim.new(0, 4),
        }, Paragraph)

        local ParagraphTitle = Custom:Create("TextLabel", {
          Font = Enum.Font.GothamBold,
          Text = Title,
          TextColor3 = Color3.fromRGB(231, 231, 231),
          TextSize = 13,
          TextXAlignment = Enum.TextXAlignment.Left,
          TextYAlignment = Enum.TextYAlignment.Top,
          BackgroundColor3 = Color3.fromRGB(255, 255, 255),
          BackgroundTransparency = 0.999,
          BorderSizePixel = 0,
          Position = UDim2.new(0, 10, 0, 10),
          Size = UDim2.new(1, -16, 0, 13),
          Name = "ParagraphTitle",
        }, Paragraph)
      
        local ParagraphContent = Custom:Create("TextLabel", {
          Font = Enum.Font.GothamBold,
          Text = Content,
          TextColor3 = Color3.fromRGB(255, 255, 255),
          TextSize = 12,
          TextTransparency = 0.6,
          TextXAlignment = Enum.TextXAlignment.Left,
          TextYAlignment = Enum.TextYAlignment.Bottom,
          BackgroundTransparency = 0.999,
          BorderSizePixel = 0,
          Position = UDim2.new(0, 10, 0, 23),
          Name = "ParagraphContent",
        }, Paragraph)

        local function UpdateParagraphSize()
          ParagraphContent.TextWrapped = false
          local lineCount = math.ceil(ParagraphContent.TextBounds.X / ParagraphContent.AbsoluteSize.X)

          ParagraphContent.Size = UDim2.new(1, -16, 0, 12 + (12 * lineCount))
          Paragraph.Size = UDim2.new(1, 0, 0, ParagraphContent.AbsoluteSize.Y + 33)
          ParagraphContent.TextWrapped = true

          UpdateSizeSection()
        end

        UpdateParagraphSize()

        ParagraphContent:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateParagraphSize)

        function SettingFuncs:Set(Config)
          local Title = Config[1] or Config.Title or ""
          local Content = Config[2] or Config.Content or ""

          ParagraphTitle.Text = Title
          ParagraphContent.Text = Content

          UpdateParagraphSize()
        end

        return SettingFuncs
      end

      function Item:AddSeperator(Config)
        local Title = Config[1] or Config.Title or ""
        local Sep_Funcs = {}

        local Seperator = Custom:Create("Frame", {
          BackgroundColor3 = Color3.fromRGB(70, 70, 70),
          BackgroundTransparency = 0.1,
          BorderColor3 = Color3.fromRGB(0, 0, 0),
          BorderSizePixel = 1,
          LayoutOrder = ItemCount,
          Size = UDim2.new(1, 0, 0, 30),
          Name = "Seperator",
        }, SectionAdd)
      
        local SeperatorTitle = Custom:Create("TextLabel", {
          Font = Enum.Font.GothamBold,
          Text = Title,
          TextColor3 = Color3.fromRGB(231, 231, 231),
          TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
          TextStrokeTransparency = 0.8,
          TextSize = 14,
          TextXAlignment = Enum.TextXAlignment.Left,
          TextYAlignment = Enum.TextYAlignment.Center,
          BackgroundColor3 = Color3.fromRGB(255, 255, 255),
          BackgroundTransparency = 1,
          BorderSizePixel = 0,
          Position = UDim2.new(0, 12, 0, 0),
          Size = UDim2.new(1, -16, 1, 0),
          Name = "SeperatorTitle",
        }, Seperator)
        
        Custom:Create("UICorner", {
          CornerRadius = UDim.new(0, 6),
        }, Seperator)
        
        local Gradient = Custom:Create("UIGradient", {
          Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 120, 120)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 120, 120))
          },
          Rotation = 90,
        }, Seperator)
  
        function Sep_Funcs:Set(Config)
          local Title = Config[1] or Config.Title or ""

          SeperatorTitle.Text = Title
        end

        ItemCount += 1
        return Sep_Funcs
      end

      function Item:AddLine()
        local LineFuncs = {}
    
        local Line = Custom:Create("Frame", {
          BackgroundColor3 = Color3.fromRGB(90, 90, 90),
          BackgroundTransparency = 0.2,
          BorderSizePixel = 0,
          LayoutOrder = ItemCount,
          Size = UDim2.new(1, 0, 0, 7),
          Name = "Line",
        }, SectionAdd)
    
        Custom:Create("UICorner", {CornerRadius = UDim.new(0, 3)}, Line)
    
        Custom:Create("UIGradient", {
          Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 80, 80)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 80, 80))
          },
          Rotation = 0,
        }, Line)
    
        ItemCount += 1
        return LineFuncs
     end

      function Item:AddButton(Config)
        local Title = Config[1] or Config.Title or ""
        local Content = Config[2] or Config.Content or ""
        local Icon = Config[3] or Config.Icon or "rbxassetid://7734010488"
        local Callback = Config[4] or Config.Callback or function() end
        local Funcs_Button = {}

        local Button = Custom:Create("Frame", {
					Name = "Button",
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.935,
					BorderSizePixel = 0,
					LayoutOrder = ItemCount,
					Size = UDim2.new(1, 0, 0, 35)
				}, SectionAdd)

        Custom:Create("UICorner", {
          CornerRadius = UDim.new(0, 4)
        }, Button)

        Custom:Create("TextLabel", {
					Name = "ButtonTitle",
					Font = Enum.Font.GothamBold,
					Text = Title,
					TextColor3 = Color3.fromRGB(231, 231, 231),
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.999,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 10, 0, 10),
					Size = UDim2.new(1, -100, 0, 13)
				}, Button)

        local ButtonContent = Custom:Create("TextLabel", {
					Name = "ButtonContent",
					Font = Enum.Font.GothamBold,
					Text = Content,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 12,
					TextTransparency = 0.6,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Bottom,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.999,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 10, 0, 23),
					Size = UDim2.new(1, -100, 0, 12)
				}, Button)

        local function UpdateButtonSize()
          local _Height = 12 + (12 * (ButtonContent.TextBounds.X // ButtonContent.AbsoluteSize.X))
          ButtonContent.Size = UDim2.new(1, -100, 0, _Height)
          
          Button.Size = UDim2.new(1, 0, 0, ButtonContent.AbsoluteSize.Y + 33)
        end
      
        ButtonContent.TextWrapped = true
        UpdateButtonSize()
      
        ButtonContent:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
          ButtonContent.TextWrapped = false
          UpdateButtonSize()
          ButtonContent.TextWrapped = true
          UpdateSizeSection()
        end)

        local ButtonButton = Custom:Create("TextButton", {
					Name = "ButtonButton",
					Font = Enum.Font.SourceSans,
					Text = "",
					TextColor3 = Color3.fromRGB(0, 0, 0),
					TextSize = 14,
					BackgroundColor3 = Color3.fromRGB(0, 0, 0),
					BackgroundTransparency = 0.999,
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 1, 0)
				}, Button)

        local FeatureFrame1 = Custom:Create("Frame", {
					Name = "FeatureFrame",
					AnchorPoint = Vector2.new(1, 0.5),
					BackgroundColor3 = Color3.fromRGB(0, 0, 0),
					BackgroundTransparency = 0.999,
					BorderSizePixel = 0,
					Position = UDim2.new(1, -15, 0.5, 0),
					Size = UDim2.new(0, 25, 0, 25)
				}, Button)

        Custom:Create("ImageLabel", {
          Name = "FeatureImg",
          Image = Icon,
          AnchorPoint = Vector2.new(0.5, 0.5),
          BackgroundColor3 = Color3.fromRGB(255, 255, 255),
          BackgroundTransparency = 0.999,
          BorderSizePixel = 0,
          Position = UDim2.new(0.5, 0, 0.5, 0),
          Size = UDim2.new(1, 0, 1, 0)
        }, FeatureFrame1)

        ButtonButton.Activated:Connect(function()
					CircleClick(ButtonButton, Player:GetMouse().X, Player:GetMouse().Y)

					Callback()
				end)

        ItemCount += 1
				return Funcs_Button
      end

      function Item:AddToggle(Config)
        local Title = Config[1] or Config.Title or ""
        local Content = Config[2] or Config.Content or ""
        local Default = Config[3] or Config.Default or false
        local Callback = Config[4] or Config.Callback or function() end

				local Funcs_Toggle = {Value = Default}

        local Toggle = Custom:Create("Frame", {
					Name = "Toggle",
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.935,
					BorderSizePixel = 0,
					LayoutOrder = ItemCount,
					Size = UDim2.new(1, 0, 0, 35)
				}, SectionAdd)

        Custom:Create("UICorner", {
          CornerRadius = UDim.new(0, 4)
        }, Toggle)

        local ToggleTitle = Custom:Create("TextLabel", {
					Name = "ToggleTitle",
					Font = Enum.Font.GothamBold,
					Text = Title,
					TextSize = 13,
					TextColor3 = Color3.fromRGB(231, 231, 231),
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.999,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 10, 0, 10),
					Size = UDim2.new(1, -100, 0, 13)
				}, Toggle)

        local ToggleContent = Custom:Create("TextLabel", {
					Name = "ToggleContent",
					Font = Enum.Font.GothamBold,
					Text = Content,
					TextSize = 12,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextTransparency = 0.6,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Bottom,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.999,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 10, 0, 23),
					Size = UDim2.new(1, -100, 0, 12)
				}, Toggle)
				
        local function UpdateToggleSize()
          ToggleContent.TextWrapped = false
          local Ratio = ToggleContent.TextBounds.X / ToggleContent.AbsoluteSize.X

          ToggleContent.Size = UDim2.new(1, -100, 0, 12 + (12 * math.ceil(Ratio)))
          Toggle.Size = UDim2.new(1, 0, 0, ToggleContent.AbsoluteSize.Y + 33)
          ToggleContent.TextWrapped = true
        end
      
        UpdateToggleSize()
      
        ToggleContent:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
          UpdateToggleSize()
          UpdateSizeSection()
        end)

        local ToggleButton = Custom:Create("TextButton", {
          Name = "ToggleButton",
          Font = Enum.Font.SourceSans,
          Text = "",
          TextColor3 = Color3.fromRGB(0, 0, 0),
          TextSize = 14,
          BackgroundColor3 = Color3.fromRGB(0, 0, 0),
          BackgroundTransparency = 0.999,
          BorderSizePixel = 0,
          Size = UDim2.new(1, 0, 1, 0)
        }, Toggle)

        
				local FeatureFrame2 = Custom:Create("Frame", {
					Name = "FeatureFrame2",
					AnchorPoint = Vector2.new(1, 0.5),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.92,
					BorderSizePixel = 0,
					Position = UDim2.new(1, -15, 0.5, 0),
					Size = UDim2.new(0, 30, 0, 15)
				}, Toggle)

        Custom:Create("UICorner", {
          CornerRadius = UDim.new(0, 4)
        }, FeatureFrame2)
      
        local UIStroke8 = Custom:Create("UIStroke", {
          Color = Color3.fromRGB(255, 255, 255),
          Thickness = 2,
          Transparency = 0.9
        }, FeatureFrame2)

        local ToggleCircle = Custom:Create("Frame", {
					Name = "ToggleCircle",
					BackgroundColor3 = Color3.fromRGB(230, 230, 230),
					BorderSizePixel = 0,
					Size = UDim2.new(0, 14, 0, 14),
					Position = UDim2.new(0, 0, 0, 0)
				}, FeatureFrame2)

        Custom:Create("UICorner", {
          CornerRadius = UDim.new(0, 15)
        }, ToggleCircle)

        local function ToggleAnimation(isOn)          
          local TitleColor = isOn and Custom.ColorRGB or Color3.fromRGB(230, 230, 230)
          local CirclePosition = isOn and UDim2.new(0, 15, 0, 0) or UDim2.new(0, 0, 0, 0)
          local StrokeColor = isOn and Custom.ColorRGB or Color3.fromRGB(255, 255, 255)
          local StrokeTransparency = isOn and 0 or 0.9
          local FrameColor = isOn and Custom.ColorRGB or Color3.fromRGB(255, 255, 255)
          local FrameTransparency = isOn and 0 or 0.92

          local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
          local function safeTween(inst, props)
            local ok = pcall(function()
              TweenService:Create(inst, tweenInfo, props):Play()
            end)
            if not ok then
              pcall(function()
                for prop, val in pairs(props) do
                  inst[prop] = val
                end
              end)
            end
          end
      
          safeTween(ToggleTitle, {TextColor3 = TitleColor})
          safeTween(ToggleCircle, {Position = CirclePosition})
          safeTween(UIStroke8, {Color = StrokeColor, Transparency = StrokeTransparency})
          safeTween(FeatureFrame2, {BackgroundColor3 = FrameColor, BackgroundTransparency = FrameTransparency})
        end
      
        ToggleButton.Activated:Connect(function()
          CircleClick(ToggleButton, Player:GetMouse().X, Player:GetMouse().Y)
          Funcs_Toggle.Value = not Funcs_Toggle.Value
          Funcs_Toggle:Set(Funcs_Toggle.Value)
        end)
      
        function Funcs_Toggle:Set(Value)
          Funcs_Toggle.Value = Value
          ToggleAnimation(Value)
          Callback(Value)
        end
        ToggleAnimation(Funcs_Toggle.Value)

        ItemCount += 1
				return Funcs_Toggle
      end

      function Item:AddSlider(Config)
        local Title = Config[1] or Config.Title or ""
        local Content = Config[2] or Config.Content or ""
        local Increment = Config[3] or Config.Increment or 1
        local Min = Config[4] or Config.Min or 0
        local Max = Config[5] or Config.Max or 100
        local Default = Config[6] or Config.Default or 50
        local Callback = Config[7] or Config.Callback or function() end

				local Funcs_Slider = {Value = Default}
        
        local Slider = Custom:Create("Frame", {
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.9350000023841858,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					LayoutOrder = ItemCount,
					Size = UDim2.new(1, 0, 0, 35),
					Name = "Slider",
				}, SectionAdd)

        Custom:Create("UICorner", {
          CornerRadius = UDim.new(0, 4),
        }, Slider)

        Custom:Create("TextLabel", {
					Font = Enum.Font.GothamBold,
					Text = Title,
					TextColor3 = Color3.fromRGB(230, 230, 230),
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.9990000128746033,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Position = UDim2.new(0, 10, 0, 10),
					Size = UDim2.new(1, -180, 0, 13),
					Name = "SliderTitle",
				}, Slider)

				local SliderContent = Custom:Create("TextLabel", {
					Font = Enum.Font.GothamBold,
					Text = Content,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 12,
					TextTransparency = 0.6000000238418579,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Bottom,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.9990000128746033,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Position = UDim2.new(0, 10, 0, 23),
					Size = UDim2.new(1, -180, 0, 12),
					Name = "SliderContent",
				}, Slider)

        local function UpdateSliderSize()
          SliderContent.TextWrapped = false
          SliderContent.Size = UDim2.new(1, -180, 0, 12 + (12 * math.floor(SliderContent.TextBounds.X / SliderContent.AbsoluteSize.X)))
          Slider.Size = UDim2.new(1, 0, 0, SliderContent.AbsoluteSize.Y + 33)
          SliderContent.TextWrapped = true
        end

        SliderContent:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
          UpdateSliderSize()
          UpdateSizeSection()
        end)
        UpdateSliderSize()

        local SliderInput = Custom:Create("Frame", {
					AnchorPoint = Vector2.new(0, 0.5),
					BackgroundColor3 = Custom.ColorRGB,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Position = UDim2.new(1, -155, 0.5, 0),
					Size = UDim2.new(0, 28, 0, 20),
					Name = "SliderInput",
				}, Slider)

        Custom:Create("UICorner", {
          CornerRadius = UDim.new(0, 2),
        }, SliderInput)

         
				local TextBox = Custom:Create("TextBox", {
					Font = Enum.Font.GothamBold,
					Text = "90",
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 13,
					TextWrapped = true,
					BackgroundColor3 = Color3.fromRGB(0, 0, 0),
					BackgroundTransparency = 0.9990000128746033,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Position = UDim2.new(0, -1, 0, 0),
					Size = UDim2.new(1, 0, 1, 0),
				}, SliderInput)

        local SliderFrame = Custom:Create("Frame", {
					AnchorPoint = Vector2.new(1, 0.5),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.800000011920929,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Position = UDim2.new(1, -20, 0.5, 0),
					Size = UDim2.new(0, 100, 0, 3),
					Name = "SliderFrame",
				}, Slider)

        Custom:Create("UICorner", {}, SliderFrame)

        local SliderDraggable = Custom:Create("Frame", {
					AnchorPoint = Vector2.new(0, 0.5),
					BackgroundColor3 = Custom.ColorRGB,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Position = UDim2.new(0, 0, 0.5, 0),
					Size = UDim2.new(0.899999976, 0, 0, 1),
					Name = "SliderDraggable",
				}, SliderFrame)

        Custom:Create("UICorner", {}, SliderDraggable)

        local SliderCircle = Custom:Create("Frame", {
					AnchorPoint = Vector2.new(1, 0.5),
					BackgroundColor3 = Custom.ColorRGB,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Position = UDim2.new(1, 4, 0.5, 0),
					Size = UDim2.new(0, 8, 0, 8),
					Name = "SliderCircle",
				}, SliderDraggable)

        Custom:Create("UICorner", {}, SliderCircle)

        Custom:Create("UIStroke", {
          Color = Custom.ColorRGB,
        }, SliderCircle)

        local Dragging = false

        local function Round(Number, Factor)
          local Result = math.floor(Number / Factor + (math.sign(Number) * 0.5)) * Factor
          if Result < 0 then 
            Result = Result + Factor 
          end
          return Result
        end
        
        function Funcs_Slider:Set(Value)
          Value = math.clamp(Round(Value, Increment), Min, Max)
          Funcs_Slider.Value = Value
          TextBox.Text = tostring(Value)
            
          TweenService:Create(SliderDraggable, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.fromScale((Value - Min) / (Max - Min), 1) }):Play()
        end
        
        SliderFrame.InputBegan:Connect(function(Input)
          if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true
          end
        end)
      
        SliderFrame.InputEnded:Connect(function(Input)
          if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
            Dragging = false
            Callback(Funcs_Slider.Value)
          end
        end)
      
        local _LastX = nil
        UserInputService.InputChanged:Connect(function(Input)
          if Dragging then
            local CurrPosX = Input.Position.X
            if CurrPosX ~= _LastX then
              _LastX = CurrPosX
      
              local SizeScale = math.clamp((CurrPosX - SliderFrame.AbsolutePosition.X) / SliderFrame.AbsoluteSize.X, 0, 1)
              Funcs_Slider:Set(Min + ((Max - Min) * SizeScale))
            end
          end
        end)
        
        TextBox:GetPropertyChangedSignal("Text"):Connect(function()
          local Valid = TextBox.Text:gsub("[^%d]", "")
          if Valid ~= "" then
            local ValidNumber = math.min(tonumber(Valid), Max)
            TextBox.Text = tostring(ValidNumber)
          else
            TextBox.Text = "0"
          end
        end)
        
        TextBox.FocusLost:Connect(function()
          if TextBox.Text ~= "" then
            Funcs_Slider:Set(tonumber(TextBox.Text))
            Callback(Funcs_Slider.Value)
          else
            Funcs_Slider:Set(0)
            Callback(Funcs_Slider.Value)
          end
        end)
        
        Funcs_Slider:Set(tonumber(Default))
        Callback(Funcs_Slider.Value)

        ItemCount += 1
				return Funcs_Slider
      end

      function Item:AddInput(Config)
        local Title = Config[1] or Config.Title or ""
        local Content = Config[2] or Config.Content or ""
        local Default = Config[3] or Config.Default or ""
        local Callback = Config[4] or Config.Callback or function() end
				local Funcs_Input = {Value = Default}

        local Input = Custom:Create("Frame", {
          BackgroundColor3 = Color3.fromRGB(255, 255, 255),
          BackgroundTransparency = 0.935,
          BorderColor3 = Color3.fromRGB(0, 0, 0),
          BorderSizePixel = 0,
          LayoutOrder = ItemCount,
          Size = UDim2.new(1, 0, 0, 35),
          Name = "Input",
        }, SectionAdd)

        Custom:Create("UICorner", {
          CornerRadius = UDim.new(0, 4),
        }, Input)

        local InputTitle = Custom:Create("TextLabel", {
          Font = Enum.Font.GothamBold,
          Text = Title,
          TextColor3 = Color3.fromRGB(230, 230, 230),
          TextSize = 13,
          TextXAlignment = Enum.TextXAlignment.Left,
          TextYAlignment = Enum.TextYAlignment.Top,
          BackgroundColor3 = Color3.fromRGB(255, 255, 255),
          BackgroundTransparency = 0.999,
          BorderColor3 = Color3.fromRGB(0, 0, 0),
          BorderSizePixel = 0,
          Position = UDim2.new(0, 10, 0, 10),
          Size = UDim2.new(1, -180, 0, 13),
          Name = "InputTitle",
        }, Input)

        local InputContent = Custom:Create("TextLabel", {
          Font = Enum.Font.GothamBold,
          Text = Content,
          TextColor3 = Color3.fromRGB(255, 255, 255),
          TextSize = 12,
          TextTransparency = 0.6,
          TextWrapped = true,
          TextXAlignment = Enum.TextXAlignment.Left,
          TextYAlignment = Enum.TextYAlignment.Bottom,
          BackgroundColor3 = Color3.fromRGB(255, 255, 255),
          BackgroundTransparency = 0.999,
          BorderColor3 = Color3.fromRGB(0, 0, 0),
          BorderSizePixel = 0,
          Position = UDim2.new(0, 10, 0, 23),
          Size = UDim2.new(1, -180, 0, 12),
          Name = "InputContent",
          Parent = Input
        })

        local function UpdateInputSize()
          local Ratio = InputContent.TextBounds.X / InputContent.AbsoluteSize.X
          local Calculated = 12 + (12 * math.floor(Ratio))

          InputContent.Size = UDim2.new(1, -180, 0, Calculated)
          Input.Size = UDim2.new(1, 0, 0, InputContent.AbsoluteSize.Y + 33)
        end
      
        UpdateInputSize()
      
        InputContent:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
          InputContent.TextWrapped = false
          UpdateInputSize()
          InputContent.TextWrapped = true
          UpdateSizeSection()
        end)

        local InputFrame = Custom:Create("Frame", {
          AnchorPoint = Vector2.new(1, 0.5),
          BackgroundColor3 = Color3.fromRGB(255, 255, 255),
          BackgroundTransparency = 0.95,
          BorderColor3 = Color3.fromRGB(0, 0, 0),
          BorderSizePixel = 0,
          ClipsDescendants = true,
          Position = UDim2.new(1, -7, 0.5, 0),
          Size = UDim2.new(0, 148, 0, 30),
          Name = "InputFrame"
        }, Input)
    

        Custom:Create("UICorner", {
          CornerRadius = UDim.new(0, 4)
        }, InputFrame)

        local InputTextBox = Custom:Create("TextBox", {
          CursorPosition = -1,
          Font = Enum.Font.GothamBold,
          PlaceholderColor3 = Color3.fromRGB(120, 120, 120),
          PlaceholderText = "Write your input there",
          Text = "",
          TextColor3 = Color3.fromRGB(255, 255, 255),
          TextSize = 12,
          TextXAlignment = Enum.TextXAlignment.Left,
          AnchorPoint = Vector2.new(0, 0.5),
          BackgroundColor3 = Color3.fromRGB(255, 255, 255),
          BackgroundTransparency = 0.999,
          BorderColor3 = Color3.fromRGB(0, 0, 0),
          BorderSizePixel = 0,
          Position = UDim2.new(0, 5, 0.5, 0),
          Size = UDim2.new(1, -10, 1, -8),
          Name = "InputTextBox"
        }, InputFrame)

        function Funcs_Input:Set(Value)
					InputTextBox.Text = Value
					Funcs_Input.Value = Value
					Callback(Value)
				end

				InputTextBox.FocusLost:Connect(function()
					Funcs_Input:Set(InputTextBox.Text)
				end)

				Funcs_Input:Set(Default)

        ItemCount += 1
				return Funcs_Input
      end

      function Item:AddDropdown(Config)
        local Title = Config[1] or Config.Title or ""
        local Content = Config[2] or Config.Content or ""
        local Multi = Config[3] or Config.Multi or false
        local Options = Config[4] or Config.Options or {}
        local Default = Config[5] or Config.Default or {}
        local Callback = Config[6] or Config.Callback or function() end

        local Funcs_Dropdown = {Value = Default, Options = Options}

        local Dropdown = Custom:Create("Frame", {
          BackgroundColor3 = Color3.fromRGB(255, 255, 255),
          BackgroundTransparency = 0.935,
          BorderColor3 = Color3.fromRGB(0, 0, 0),
          BorderSizePixel = 0,
          LayoutOrder = ItemCount,
          Size = UDim2.new(1, 0, 0, 35),
          Name = "Dropdown"
        }, SectionAdd)

        local DropdownButton = Custom:Create("TextButton", {
          Font = Enum.Font.SourceSans,
          Text = "",
          TextColor3 = Color3.fromRGB(0, 0, 0),
          TextSize = 14,
          BackgroundColor3 = Color3.fromRGB(0, 0, 0),
          BackgroundTransparency = 0.999,
          BorderColor3 = Color3.fromRGB(0, 0, 0),
          BorderSizePixel = 0,
          Size = UDim2.new(1, 0, 1, 0),
          Name = "ToggleButton"
        }, Dropdown)

        Custom:Create("UICorner", {
          CornerRadius = UDim.new(0, 4)
        }, Dropdown)

        local DropdownTitle = Custom:Create("TextLabel", {
          Font = Enum.Font.GothamBold,
          Text = Title,
          TextColor3 = Color3.fromRGB(230, 230, 230),
          TextSize = 13,
          TextXAlignment = Enum.TextXAlignment.Left,
          TextYAlignment = Enum.TextYAlignment.Top,
          BackgroundColor3 = Color3.fromRGB(255, 255, 255),
          BackgroundTransparency = 0.999,
          BorderColor3 = Color3.fromRGB(0, 0, 0),
          BorderSizePixel = 0,
          Position = UDim2.new(0, 10, 0, 10),
          Size = UDim2.new(1, -180, 0, 13),
          Name = "DropdownTitle",
          Parent = Dropdown
        })

        local DropdownContent = Custom:Create("TextLabel", {
          Font = Enum.Font.GothamBold,
          Text = Content,
          TextColor3 = Color3.fromRGB(255, 255, 255),
          TextSize = 12,
          TextTransparency = 0.6,
          TextWrapped = true,
          TextXAlignment = Enum.TextXAlignment.Left,
          TextYAlignment = Enum.TextYAlignment.Bottom,
          BackgroundColor3 = Color3.fromRGB(255, 255, 255),
          BackgroundTransparency = 0.999,
          BorderColor3 = Color3.fromRGB(0, 0, 0),
          BorderSizePixel = 0,
          Position = UDim2.new(0, 10, 0, 23),
          Size = UDim2.new(1, -180, 0, 12),
          Name = "DropdownContent",
          Parent = Dropdown
        })
        
				DropdownContent.Size = UDim2.new(1, -180, 0, 12 + (12 * (DropdownContent.TextBounds.X // DropdownContent.AbsoluteSize.X)))
				DropdownContent.TextWrapped = true
				Dropdown.Size = UDim2.new(1, 0, 0, DropdownContent.AbsoluteSize.Y + 33)
        
        DropdownContent:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
          DropdownContent.TextWrapped = false
            
					DropdownContent.Size = UDim2.new(1, -180, 0, 12 + (12 * (DropdownContent.TextBounds.X // DropdownContent.AbsoluteSize.X)))
					Dropdown.Size = UDim2.new(1, 0, 0, DropdownContent.AbsoluteSize.Y + 33)
            
          DropdownContent.TextWrapped = true

          UpdateSizeSection()
        end)

        local SelectOptionsFrame = Custom:Create("Frame", {
          AnchorPoint = Vector2.new(1, 0.5),
          BackgroundColor3 = Color3.fromRGB(255, 255, 255),
          BackgroundTransparency = 0.95,
          BorderColor3 = Color3.fromRGB(0, 0, 0),
          BorderSizePixel = 0,
          Position = UDim2.new(1, -7, 0.5, 0),
          Size = UDim2.new(0, 148, 0, 30),
          Name = "SelectOptionsFrame",
          LayoutOrder = CountDropdown
        }, Dropdown)

        Custom:Create("UICorner", {
          CornerRadius = UDim.new(0, 4)
        }, SelectOptionsFrame)

        DropdownButton.Activated:Connect(function()
          if not MoreBlur.Visible then
            MoreBlur.Visible = true
              
            local tweenInfo = TweenInfo.new(0.1)

            DropPageLayout:JumpToIndex(SelectOptionsFrame.LayoutOrder)
                            
            local BlurTween = TweenService:Create(MoreBlur, tweenInfo, {BackgroundTransparency = 0.7})
            local DropdownTween = TweenService:Create(DropdownSelect, tweenInfo, {Position = UDim2.new(1, -11, 0.5, 0)})
              
            BlurTween:Play()
            DropdownTween:Play()
          end
        end)

        local OptionSelecting = Custom:Create("TextLabel", {
          Font = Enum.Font.GothamBold,
          Text = "",
          TextColor3 = Color3.fromRGB(255, 255, 255),
          TextSize = 12,
          TextTransparency = 0.6,
          TextWrapped = true,
          TextXAlignment = Enum.TextXAlignment.Left,
          AnchorPoint = Vector2.new(0, 0.5),
          BackgroundColor3 = Color3.fromRGB(255, 255, 255),
          BackgroundTransparency = 0.999,
          BorderColor3 = Color3.fromRGB(0, 0, 0),
          BorderSizePixel = 0,
          Position = UDim2.new(0, 5, 0.5, 0),
          Size = UDim2.new(1, -30, 1, -8),
          Name = "OptionSelecting",
        }, SelectOptionsFrame)

        local OptionImg = Custom:Create("ImageLabel", {
          Image = "rbxassetid://90200523188815",
          ImageColor3 = Color3.fromRGB(231, 231, 231),
          AnchorPoint = Vector2.new(1, 0.5),
          BackgroundColor3 = Color3.fromRGB(255, 255, 255),
          BackgroundTransparency = 0.999,
          BorderColor3 = Color3.fromRGB(0, 0, 0),
          BorderSizePixel = 0,
          Position = UDim2.new(1, 0, 0.5, 0),
          Size = UDim2.new(0, 25, 0, 25),
          Name = "OptionImg",
        }, SelectOptionsFrame)

        local ScrollSelect = Custom:Create("ScrollingFrame", {
          CanvasSize = UDim2.new(0, 0, 0, 0),
          ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0),
          ScrollBarThickness = 0,
          Active = true,
          LayoutOrder = CountDropdown,
          BackgroundColor3 = Color3.fromRGB(255, 255, 255),
          BackgroundTransparency = 0.999,
          BorderColor3 = Color3.fromRGB(0, 0, 0),
          BorderSizePixel = 0,
          Size = UDim2.new(1, 0, 1, 0),
          Name = "ScrollSelect",
        }, DropdownFolder)

        Custom:Create("UIListLayout", {
          Padding = UDim.new(0, 3),
          SortOrder = Enum.SortOrder.LayoutOrder,
        }, ScrollSelect)

        local SearchBar = Custom:Create("TextBox", {
          Font = Enum.Font.GothamBold,
          PlaceholderText = "Search",
          PlaceholderColor3 = Color3.fromRGB(120, 120, 120),
          Text = "",
          TextColor3 = Color3.fromRGB(255, 255, 255),
          TextSize = 12,
          BackgroundColor3 = Color3.fromRGB(0, 0, 0),
          BackgroundTransparency = 0.9,
          BorderColor3 = Color3.fromRGB(255, 0, 0),
          BorderSizePixel = 1,
          Size = UDim2.new(1, 0, 0, 20),
          Name = "SearchBar"
        }, ScrollSelect)

        SearchBar:GetPropertyChangedSignal("Text"):Connect(function()
          local SearchText = string.lower(SearchBar.Text)

          for _, v in pairs(ScrollSelect:GetChildren()) do
            if v:IsA("Frame") and v.Name == "Option" and v.Name ~= "SearchBar" then
              local OptionText = v:FindFirstChild("OptionText")
              if OptionText then
                v.Visible = string.find(string.lower(OptionText.Text), SearchText) ~= nil
              end
            end
          end
        end)

        local DropCount = 0

        function Funcs_Dropdown:Clear()
          for _, DropFrame in pairs(ScrollSelect:GetChildren()) do
            if DropFrame.Name == "Option" then
              Funcs_Dropdown.Value = {}
              Funcs_Dropdown.Options = {}
              OptionSelecting.Text = "Select Options"
              DropFrame:Destroy()
            end
          end
        end
        
        function Funcs_Dropdown:Set(Value)
          Funcs_Dropdown.Value = Value or Funcs_Dropdown.Value

          for _, Drop in pairs(ScrollSelect:GetChildren()) do
            if Drop.Name ~= "UIListLayout" and Drop.Name ~= "SearchBar" then
              local isTextFound = table.find(Funcs_Dropdown.Value, Drop.OptionText.Text)
              local tweenInfoInOut = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

              local Size = isTextFound and UDim2.new(0, 1, 0, 12) or UDim2.new(0, 0, 0, 0)
              local BackgroundTransparency = isTextFound and 0.935 or 0.999
              local Transparency = isTextFound and 0 or 0.999
          
              TweenService:Create(Drop.ChooseFrame, tweenInfoInOut, {Size = Size}):Play()
              TweenService:Create(Drop.ChooseFrame.UIStroke, tweenInfoInOut, {Transparency = Transparency}):Play()
              TweenService:Create(Drop, tweenInfoInOut, {BackgroundTransparency = BackgroundTransparency}):Play()
            end
          end
        
          local DropdownValueTable = table.concat(Funcs_Dropdown.Value, ", ")
          OptionSelecting.Text = DropdownValueTable ~= "" and DropdownValueTable or "Select Options"
          Callback(Funcs_Dropdown.Value)
        end

        function Funcs_Dropdown:AddOption(OptionName)
          OptionName = OptionName or "Option"
  
          local Option = Custom:Create("Frame", {
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0.999,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            BorderSizePixel = 0,
            LayoutOrder = DropCount,
            Size = UDim2.new(1, 0, 0, 30),
            Name = "Option"
          }, ScrollSelect)
  
          Custom:Create("UICorner", {
            CornerRadius = UDim.new(0, 3)
          }, Option)
  
          local OptionButton = Custom:Create("TextButton", {
            Font = Enum.Font.GothamBold,
            Text = "",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0.999,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 1, 0),
            Name = "OptionButton"
          }, Option)
  
          Custom:Create("TextLabel", {
            Font = Enum.Font.GothamBold,
            Text = OptionName,
            TextSize = 13,
            TextColor3 = Color3.fromRGB(230, 230, 230),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0.999,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            BorderSizePixel = 0,
            Position = UDim2.new(0, 8, 0, 8),
            Size = UDim2.new(1, -100, 0, 13),
            Name = "OptionText"
          }, Option)
  
          local ChooseFrame = Custom:Create("Frame", {
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = Custom.ColorRGB,
            BorderColor3 = Color3.fromRGB(0, 0, 0),
            BorderSizePixel = 0,
            Position = UDim2.new(0, 2, 0.5, 0),
            Size = UDim2.new(0, 0, 0, 0),
            Name = "ChooseFrame"
          }, Option)
  
          Custom:Create("UIStroke", {
            Color = Custom.ColorRGB,
            Thickness = 1.6,
            Transparency = 0.999
          }, ChooseFrame)
  
          Custom:Create("UICorner", {}, ChooseFrame)
  
          OptionButton.Activated:Connect(function()

            CircleClick(OptionButton, Player:GetMouse().X, Player:GetMouse().Y)
        
            local isOptionSelected = Option.BackgroundTransparency > 0.95

            if Multi then
              if isOptionSelected then
                if not table.find(Funcs_Dropdown.Value, OptionName) then
                  table.insert(Funcs_Dropdown.Value, OptionName)
                end
              else
                for i, value in ipairs(Funcs_Dropdown.Value) do
                  if value == OptionName then
                    table.remove(Funcs_Dropdown.Value, i)
                    break
                  end
                end
              end
            else
              Funcs_Dropdown.Value = {OptionName}
            end

            Funcs_Dropdown:Set(Funcs_Dropdown.Value)
          end)
        
          local function UpdateCanvasSize()
            local OffsetY = 0

            for _, child in ipairs(ScrollSelect:GetChildren()) do
              if child.Name ~= "UIListLayout" and child.Name ~= "SearchBar" then
                OffsetY = OffsetY + 5 + child.Size.Y.Offset
              end
            end

            ScrollSelect.CanvasSize = UDim2.new(0, 0, 0, OffsetY)
          end
        
          UpdateCanvasSize()

          DropCount += 1
        end

        function Funcs_Dropdown:Refresh(RefreshList, Selecting)
          RefreshList = RefreshList or {}
          Selecting = Selecting or {}
          
          Funcs_Dropdown:Clear()
          
          for _, Drop in ipairs(RefreshList) do
            Funcs_Dropdown:AddOption(Drop)
          end
      
          Funcs_Dropdown.Options = RefreshList
          Funcs_Dropdown:Set(Selecting)
        end
      
        Funcs_Dropdown:Refresh(Funcs_Dropdown.Options, Funcs_Dropdown.Value)
      
        if Config.DynamicOption then
          Funcs_Dropdown.DynamicOption = Config.DynamicOption
          Funcs_Dropdown.DynamicSelect = Config.DynamicSelect
          table.insert(_G._GAG_DYNAMIC_DROPDOWNS, Funcs_Dropdown)
        end
        ItemCount += 1
        CountDropdown += 1
        return Funcs_Dropdown
      end

      ItemCount += 1
      return Item
    end

    CountTab += 1
    return Sections
  end

  return Tabs
end


-- ==================== UI ====================

local _icons = {"rbxassetid://10734942198","rbxassetid://10723407389","rbxassetid://10734923549","rbxassetid://10709769841","rbxassetid://10734952273","rbxassetid://11447063791","rbxassetid://10734950309","rbxassetid://8997386997"}
for _, id in ipairs(_icons) do local img = Instance.new("ImageLabel"); img.Image = id; game:GetService("ContentProvider"):PreloadAsync({img}); img:Destroy() end


local Window = Speed_Library:CreateWindow({
    Title = "", Description = "Grow A Garden 2",
    SizeUi = UDim2.fromOffset(520, 340),
})

-- ==================== TAB: HOME ====================
;(function()
local HomeTab = Window:CreateTab({ Name = "Home", Icon = "rbxassetid://10734942198" })

local DiscordSec = HomeTab:AddSection("Discord", false)
DiscordSec:AddButton({ Title = "Discord Invite", Content = "Copy invite link to clipboard",
    Callback = function()
        setclipboard("https://discord.gg/")
    end })

local LocalSec = HomeTab:AddSection("LocalPlayer", false)
LocalSec:AddInput({ Title = "Set Speed", Content = "Walkspeed value (default: 16)",
    Callback = function(v) local n = tonumber(v); if n and n > 0 then _playerSpeed = n; applyWalkspeed() end end })
LocalSec:AddToggle({ Title = "Enable Walkspeed", Default = false,
    Callback = function(v)
        _walkEnabled = v
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = v and _playerSpeed or 16 end
    end })
LocalSec:AddToggle({ Title = "No Clip", Default = false,
    Callback = function(v) _noclipEnabled = v end })
LocalSec:AddToggle({ Title = "Infinite Jump", Default = false,
    Callback = function(v) _infJumpEnabled = v end })

local WeatherSec = HomeTab:AddSection("Weather Predict", false)local WeatherSec = HomeTab:AddSection("Weather Predict", false)
local _wpBlood = WeatherSec:AddParagraph({ Title = "Bloodmoon",    Content = "Calculating..." })
local _wpGold  = WeatherSec:AddParagraph({ Title = "Goldmoon",     Content = "Calculating..." })
local _wpRain  = WeatherSec:AddParagraph({ Title = "Rainbow Moon", Content = "Calculating..." })

task.spawn(function()
    while not Speed_Library.Unloaded do
        local ok, finds = pcall(getNextSpecialNights)
        if ok and finds then
            _wpBlood:Set({ Title = "Bloodmoon",    Content = finds["Bloodmoon"]    and ("In " .. fmtCountdown(finds["Bloodmoon"]))    or "Not within 3 days" })
            _wpGold:Set({  Title = "Goldmoon",     Content = finds["Goldmoon"]     and ("In " .. fmtCountdown(finds["Goldmoon"]))     or "Not within 3 days" })
            _wpRain:Set({  Title = "Rainbow Moon", Content = finds["Rainbow Moon"] and ("In " .. fmtCountdown(finds["Rainbow Moon"])) or "Not within 3 days" })
        end
        task.wait(1)
    end
end)
end)()

-- ==================== TAB: MAIN ====================
;(function()
local MainTab = Window:CreateTab({ Name = "Main", Icon = "rbxassetid://10723407389" })

local AutoCollSec = MainTab:AddSection("Automation Collection", false)
AutoCollSec:AddSeperator({ Title = "- [ Config ] -" })
AutoCollSec:AddToggle({ Title = "Disable Teleport", Default = Cfg.disableTp,
    Callback = function(v) Cfg.disableTp = v end })
AutoCollSec:AddToggle({ Title = "Stop Collect If Backpack Is Full Max", Default = Cfg.stopIfFull,
    Callback = function(v) Cfg.stopIfFull = v end })
AutoCollSec:AddInput({ Title = "Delay To Collect", Content = "If you don't want use this, just input '0'", Default = tostring(Cfg.delay),
    Callback = function(v) local n = tonumber(v); if n and n >= 0 then Cfg.delay = n end end })
AutoCollSec:AddSeperator({ Title = "- [ Collects ] -" })
AutoCollSec:AddDropdown({ Title = "Select Fruit", Multi = true, Default = savedDropdown("selFruit"),
    Options = getOptionList("Plants"), DynamicOption = "Plants",
    Callback = function(v) Cfg.selFruit = v end })
AutoCollSec:AddDropdown({ Title = "Select Rarity", Multi = true, Default = savedDropdown("selRarity"),
    Options = getOptionList("Rarities"), DynamicOption = "Rarities",
    Callback = function(v) Cfg.selRarity = v end })
AutoCollSec:AddDropdown({ Title = "Low KG Mutations", Content = "Mutations to collect with the Low KG rule. Use None for no mutation", Multi = true, Default = savedDropdown("lowKgMut"),
    Options = MUT_LIST,
    Callback = function(v) Cfg.lowKgMut = v end })
AutoCollSec:AddDropdown({ Title = "Low KG Mode", Default = savedDropdown("lowKgMode"),
    Options = getOptionList("CompareModes"), DynamicOption = "CompareModes",
    Callback = function(v) Cfg.lowKgMode = v[1] or "Below" end })
AutoCollSec:AddInput({ Title = "Low KG Threshold", Content = "Example: None + Gold Below 40", Default = tostring(Cfg.lowKgThresh),
    Callback = function(v) local n = tonumber(v); if n then Cfg.lowKgThresh = n end end })
AutoCollSec:AddDropdown({ Title = "High KG Mutations", Content = "Mutations to collect with the High KG rule", Multi = true, Default = savedDropdown("highKgMut"),
    Options = MUT_LIST,
    Callback = function(v) Cfg.highKgMut = v end })
AutoCollSec:AddDropdown({ Title = "High KG Mode", Default = savedDropdown("highKgMode"),
    Options = getOptionList("CompareModes"), DynamicOption = "CompareModes",
    Callback = function(v) Cfg.highKgMode = v[1] or "Above" end })
AutoCollSec:AddInput({ Title = "High KG Threshold", Content = "Example: Starstruck/Frozen Above 10", Default = tostring(Cfg.highKgThresh),
    Callback = function(v) local n = tonumber(v); if n then Cfg.highKgThresh = n end end })
AutoCollSec:AddDropdown({ Title = "Wait Mutation Fruit", Content = "Selected fruits above KG will stay until any mutation appears", Multi = true, Default = savedDropdown("selWaitMutationFruit"),
    Options = getOptionList("Plants"), DynamicOption = "Plants",
    Callback = function(v) Cfg.selWaitMutationFruit = v end })
AutoCollSec:AddInput({ Title = "Wait Mutation Above KG", Content = "No-mutation selected fruits at/above this KG stay. Mutated ones can collect. 0 = off", Default = tostring(Cfg.waitMutationAboveKg),
    Callback = function(v) local n = tonumber(v); Cfg.waitMutationAboveKg = (n and n > 0) and n or 0 end })
AutoCollSec:AddToggle({ Title = "Auto Collect Fruit", Default = Cfg.autoCollectFruit,
    Callback = function(v) Cfg.autoCollectFruit = v end })
AutoCollSec:AddToggle({ Title = "Auto Collect All Fruit", Default = Cfg.autoCollectAll,
    Callback = function(v) Cfg.autoCollectAll = v end })
AutoCollSec:AddInput({ Title = "Min Value (Best Collect)", Content = "Auto Collect Best: hanya collect jika value >= ini. 0 = mutation/Legendary+", Default = tostring(Cfg.collectBestMinValue),
    Callback = function(v) local n = tonumber(v); if n and n >= 0 then Cfg.collectBestMinValue = n end end })
AutoCollSec:AddToggle({ Title = "Auto Collect Best Fruit", Default = Cfg.autoCollectBest,
    Callback = function(v) Cfg.autoCollectBest = v end })
AutoCollSec:AddSeperator({ Title = "- [ Collect Dropped Item ] -" })
AutoCollSec:AddToggle({ Title = "Auto Collect Dropped Item", Default = Cfg.autoDropped,
    Callback = function(v) Cfg.autoDropped = v end })
AutoCollSec:AddSeperator({ Title = "- [ Collect Gold / Rainbow Seed ] -" })
AutoCollSec:AddToggle({ Title = "Auto Collect Gold Seed", Default = Cfg.autoGoldSeed,
    Callback = function(v) Cfg.autoGoldSeed = v end })
AutoCollSec:AddToggle({ Title = "Auto Collect Rainbow Seed", Default = Cfg.autoRainbowSeed,
    Callback = function(v) Cfg.autoRainbowSeed = v end })
AutoCollSec:AddToggle({ Title = "Auto Attack Nearby Players", Content = "Requires Shovel or Crowbar equipped", Default = Cfg.autoAttack,
    Callback = function(v) Cfg.autoAttack = v end })

local function getSprinklersInPlot()
    local opts = { "Select Options" }
    local seen = { ["Select Options"] = true }
    local myPlot = getMyPlot()
    if myPlot then
        local sf = myPlot:FindFirstChild("Sprinklers")
        if sf then
            local idx = 0
            for _, s in pairs(sf:GetChildren()) do
                idx += 1
                local raw = s:GetAttribute("Sprinkler") or s:GetAttribute("SprinklerName") or s:GetAttribute("ItemName") or s:GetAttribute("SprinklerType") or s:GetAttribute("Type")
                local name = raw and tostring(raw) or nil
                if (not name or not name:find("Sprinkler")) and type(_lastSprinklerNames) == "table" then
                    name = tostring(_lastSprinklerNames[idx] or name or "")
                end
                if name and name ~= "" and name:find("Sprinkler") and not seen[name] then
                    seen[name] = true
                    opts[#opts + 1] = name
                end
            end
        end
    end
    if #opts == 1 and type(_lastSprinklerNames) == "table" then
        for _, n in ipairs(_lastSprinklerNames) do
            local name = tostring(n)
            if name:find("Sprinkler") and not seen[name] then
                seen[name] = true
                opts[#opts + 1] = name
            end
        end
    end
    return opts
end

local AutoPlantSec = MainTab:AddSection("Automation Plants", false)
AutoPlantSec:AddSeperator({ Title = "- [ Config ] -" })
AutoPlantSec:AddToggle({ Title = "Disable Teleport", Default = Cfg.disablePlantTp,
    Callback = function(v) Cfg.disablePlantTp = v end })
AutoPlantSec:AddSeperator({ Title = "- [ Plants ] -" })
AutoPlantSec:AddDropdown({ Title = "Select Seeds", Default = savedDropdown("plantSeedName"),
    Options = getOptionList("Plants", true), DynamicOption = "Plants", DynamicSelect = true,
    Callback = function(v) Cfg.plantSeedName = v[1] or "Select Options" end })
AutoPlantSec:AddDropdown({ Title = "Select Position", Default = savedDropdown("plantPosition"),
    Options = { "Player Position", "Sprinkler Radius", "Saved Position", "Random" },
    Callback = function(v) Cfg.plantPosition = v[1] or "Player Position" end })
local _plantSprinklerDropdown = AutoPlantSec:AddDropdown({ Title = "Select Sprinkler For Plants",
    Content = "Choose which sprinkler radius to plant near (used when Select Position is 'Sprinkler Radius')",
    Default = savedDropdown("plantSprinkler"),
    Options = getSprinklersInPlot(),
    Callback = function(v) Cfg.plantSprinkler = v[1] or "Select Options" end })
AutoPlantSec:AddButton({ Title = "Refresh Sprinkler List", Content = "Reload placed sprinklers for Sprinkler Radius planting",
    Callback = function()
        local opts = getSprinklersInPlot()
        local cur = tostring(Cfg.plantSprinkler or "Select Options")
        if not table.find(opts, cur) then cur = "Select Options" end
        Cfg.plantSprinkler = cur
        if _plantSprinklerDropdown and _plantSprinklerDropdown.Refresh then
            _plantSprinklerDropdown:Refresh(opts, { cur })
        end
        Speed_Library:Notify("Sprinkler list refreshed (" .. tostring(math.max(#opts - 1, 0)) .. " found)", 3)
    end })
AutoPlantSec:AddButton({ Title = "Save Position", Content = "Saves your current position as planting reference",
    Callback = function()
        local hrp = getHRP()
        if hrp then Cfg.savedPlantPos = hrp.Position end
    end })
AutoPlantSec:AddInput({ Title = "Delay To Plants", Content = "Seconds between each plant (default 0.1)", Default = tostring(Cfg.plantDelay),
    Callback = function(v) local n = tonumber(v); if n and n >= 0 then Cfg.plantDelay = n end end })
AutoPlantSec:AddToggle({ Title = "Require Active Sprinkler", Content = "When enabled, Auto Plant Seed will pause if no sprinkler is active", Default = Cfg.plantRequireSprinkler,
    Callback = function(v) Cfg.plantRequireSprinkler = v end })
AutoPlantSec:AddToggle({ Title = "Auto Plants Seed", Content = "Plants selected seed in empty spots", Default = Cfg.autoPlantSeed,
    Callback = function(v) Cfg.autoPlantSeed = v end })
AutoPlantSec:AddToggle({ Title = "Auto Plants All Seeds", Content = "Cycles through all seeds in backpack", Default = Cfg.autoPlantAll,
    Callback = function(v) Cfg.autoPlantAll = v end })

local AutoSellSec = MainTab:AddSection("Automation Sell", false)
AutoSellSec:AddInput({ Title = "Delay To Sell Inventory", Content = "Seconds between each sell cycle (0 = fastest)", Default = tostring(Cfg.sellDelay),
    Callback = function(v) local n = tonumber(v); if n and n >= 0 then Cfg.sellDelay = n end end })
AutoSellSec:AddToggle({ Title = "Allow Sell If Backpack Is Max", Content = "Only auto-sell when backpack has 5+ fruits", Default = Cfg.sellIfFull,
    Callback = function(v) Cfg.sellIfFull = v end })
AutoSellSec:AddToggle({ Title = "Allows Bargain Inventory", Content = "AskBidAll before selling for better price", Default = Cfg.sellBargain,
    Callback = function(v) Cfg.sellBargain = v end })
AutoSellSec:AddToggle({ Title = "Use Daily Deal", Content = "Use daily deal multiplier when active", Default = Cfg.sellDailyDeal,
    Callback = function(v) Cfg.sellDailyDeal = v end })
AutoSellSec:AddSeperator({ Title = "- [ Sell All ] -" })
AutoSellSec:AddToggle({ Title = "Auto Sell All", Content = "Auto sell entire inventory on a timer", Default = Cfg.autoSellAll,
    Callback = function(v) Cfg.autoSellAll = v end })
AutoSellSec:AddButton({ Title = "Sell All", Content = "Immediately sell all inventory",
    Callback = function()
        Networking.NPCS.SellAll:Fire()
    end })
AutoSellSec:AddSeperator({ Title = "- [ Sell Fruit ] -" })
AutoSellSec:AddDropdown({ Title = "Select Sell Fruit", Multi = true, Default = savedDropdown("selSellFruit"),
    Options = getOptionList("Plants"), DynamicOption = "Plants",
    Callback = function(v) Cfg.selSellFruit = v end })
AutoSellSec:AddDropdown({ Title = "Select Sell Rarity", Multi = true, Default = savedDropdown("selSellRarity"),
    Options = { "Common","Uncommon","Rare","Legendary","Mythic" },
    Callback = function(v) Cfg.selSellRarity = v end })
AutoSellSec:AddDropdown({ Title = "Select Sell Mutation", Multi = true, Default = savedDropdown("selSellMut"),
    Options = MUT_LIST,
    Callback = function(v) Cfg.selSellMut = v end })
AutoSellSec:AddDropdown({ Title = "Select Threshold Mode", Default = savedDropdown("selSellThresh"),
    Options = getOptionList("CompareModes"), DynamicOption = "CompareModes",
    Callback = function(v) Cfg.selSellThresh = v[1] or "" end })
AutoSellSec:AddInput({ Title = "Weight Threshold", Content = "Min/max weight in kg for threshold filter", Default = tostring(Cfg.sellWeightThresh),
    Callback = function(v) local n = tonumber(v); if n then Cfg.sellWeightThresh = n end end })
AutoSellSec:AddInput({ Title = "Sell Below Value", Content = "Sell fruit if value <= this. Supports 1k/1m/1b. 0 = off", Default = tostring(Cfg.sellValueBelow),
    Callback = function(v)
        local s = tostring(v or ""):lower():gsub("[%s,]+", "")
        local num, suffix = s:match("^([%d%.]+)([kmb]?)$")
        local n = tonumber(num)
        if n then
            if suffix == "k" then n = n * 1e3
            elseif suffix == "m" then n = n * 1e6
            elseif suffix == "b" then n = n * 1e9 end
            Cfg.sellValueBelow = math.floor(n)
        else
            Cfg.sellValueBelow = 0
        end
    end })
AutoSellSec:AddToggle({ Title = "Auto Sell Fruit", Content = "Auto sell fruits matching filter", Default = Cfg.autoSellFruit,
    Callback = function(v) Cfg.autoSellFruit = v end })
AutoSellSec:AddSeperator({ Title = "- [ Sell Pets ] -" })
AutoSellSec:AddDropdown({ Title = "Select Pets", Multi = true, Default = savedDropdown("selSellPet"),
    Options = getOptionList("Pets"), DynamicOption = "Pets",
    Callback = function(v) Cfg.selSellPet = v end })
AutoSellSec:AddDropdown({ Title = "Select Rarity Pets", Multi = true, Default = savedDropdown("selSellPetRarity"),
    Options = getOptionList("Rarities6"), DynamicOption = "Rarities6",
    Callback = function(v) Cfg.selSellPetRarity = v end })
AutoSellSec:AddDropdown({ Title = "Select Size Pets", Multi = true, Default = savedDropdown("selSellPetSize"),
    Options = getOptionList("PetSizes"), DynamicOption = "PetSizes",
    Callback = function(v) Cfg.selSellPetSize = v end })
AutoSellSec:AddToggle({ Title = "Auto Sell Pets", Content = "Auto sell pets matching filter", Default = Cfg.autoSellPets,
    Callback = function(v) Cfg.autoSellPets = v end })

local AutoStealSec = MainTab:AddSection("Automation Steal", false)
AutoStealSec:AddInput({ Title = "Steal Delay", Content = "Seconds between each steal cycle (min 0.5)", Default = tostring(Cfg.stealDelay),
    Callback = function(v) local n = tonumber(v); if n and n >= 0 then Cfg.stealDelay = n end end })
AutoStealSec:AddDropdown({ Title = "Select Filter", Default = { "Select Options" },
    Options = { "Select Options","Fruit","Rarity","Mutation" },
    Callback = function(v) Cfg.selStealFilter = v[1] or "Select Options" end })
AutoStealSec:AddDropdown({ Title = "Select Fruit", Multi = true, Default = savedDropdown("selStealFruit"),
    Options = getOptionList("Plants"), DynamicOption = "Plants",
    Callback = function(v) Cfg.selStealFruit = v end })
AutoStealSec:AddDropdown({ Title = "Select Rarity", Multi = true, Default = savedDropdown("selStealRarity"),
    Options = getOptionList("Rarities6"), DynamicOption = "Rarities6",
    Callback = function(v) Cfg.selStealRarity = v end })
AutoStealSec:AddDropdown({ Title = "Select Mutation", Multi = true, Default = savedDropdown("selStealMut"),
    Options = MUT_LIST,
    Callback = function(v) Cfg.selStealMut = v end })
AutoStealSec:AddToggle({ Title = "Fling Player To Unlock Garden", Content = "Continuously fling all other players upward", Default = Cfg.flingPlayers,
    Callback = function(v) Cfg.flingPlayers = v end })
AutoStealSec:AddToggle({ Title = "Auto Steal Fruit", Content = "Auto steal fruits from other players at night", Default = Cfg.autoSteal,
    Callback = function(v) Cfg.autoSteal = v end })
AutoStealSec:AddToggle({ Title = "Auto Steal Best Fruit", Content = "Auto steal mutated or Legendary+ fruits at night", Default = Cfg.autoStealBest,
    Callback = function(v) Cfg.autoStealBest = v end })
AutoStealSec:AddToggle({ Title = "Auto Hit Player Stolen", Content = "Auto fire HitPlayer on anyone carrying stolen fruit", Default = Cfg.autoHitStolen,
    Callback = function(v) Cfg.autoHitStolen = v end })


local AutoMailSec = MainTab:AddSection("Mail Send", false)
local function resolveMailTarget(username, notify)
    username = tostring(username or "")
    Cfg.mailTarget = username
    if username == "" then
        Cfg.mailTargetId = 0
        return
    end
    task.spawn(function()
        local ok, uid, name = pcall(function()
            return Networking.Mailbox.LookupPlayer:Fire(username)
        end)
        if ok and uid and uid > 0 then
            Cfg.mailTargetId = uid
            if notify then mailNotify("Mail Target: " .. tostring(name) .. " (" .. tostring(uid) .. ")", 3) end
        else
            Cfg.mailTargetId = 0
            if notify then mailNotify("User not found: " .. username, 3) end
        end
    end)
end

local function startMailPreset(category, itemKey, count, valueTarget)
    Cfg.mailCategory = category or Cfg.mailCategory
    Cfg.mailItemKey = itemKey or Cfg.mailItemKey
    Cfg.mailCount = math.max(1, math.floor(tonumber(count) or tonumber(Cfg.mailCount) or 1))
    Cfg.mailFruitValueTarget = tostring(valueTarget or "")
    Cfg.mailSendMode = "Batch Loop"
    Cfg.mailBatchSize = math.clamp(tonumber(Cfg.mailBatchSize) or 20, 1, 999999)
    if _G._GAG2MailToggleSet then _G._GAG2MailToggleSet(true) else Cfg.autoMailSend = true end
    task.spawn(runMailSendRequest)
end

AutoMailSec:AddInput({ Title = "Mail Recipient Username", Content = "Roblox username to send items to", Default = tostring(Cfg.mailTarget or ""),
    Callback = function(v) resolveMailTarget(v, true) end })
if tostring(Cfg.mailTarget or "") ~= "" and (tonumber(Cfg.mailTargetId) or 0) == 0 then resolveMailTarget(Cfg.mailTarget, false) end

local mailItemDropdown
AutoMailSec:AddDropdown({ Title = "Mail Category", Content = "General mail only. Fruits use the Mail Fruits section below", Default = savedDropdown("mailCategory"),
    Options = { "Seeds", "Gear", "Pets" },
    Callback = function(v)
        Cfg.mailCategory = v[1] or "Seeds"
        Cfg.mailItemKey = {}
        if mailItemDropdown and type(mailItemDropdown.Refresh) == "function" then
            mailItemDropdown:Refresh(getMailItemOptions(Cfg.mailCategory), {})
        end
    end })
mailItemDropdown = AutoMailSec:AddDropdown({ Title = "Mail Item", Content = "Select/unselect backpack items to send", Multi = true, Default = savedDropdown("mailItemKey"),
    Options = getMailItemOptions(Cfg.mailCategory),
    Callback = function(v)
        Cfg.mailItemKey = v
    end })
AutoMailSec:AddInput({ Title = "Mail Count", Content = "How many stackable items to send", Default = tostring(Cfg.mailCount),
    Callback = function(v) local n = tonumber(v); if n and n > 0 then Cfg.mailCount = math.floor(n) end end })
AutoMailSec:AddInput({ Title = "Batch Size", Content = "Max item slots per SendBatch (Bypass = 999999)", Default = tostring(Cfg.mailBatchSize or 20),
    Callback = function(v) local n = tonumber(v); if n and n > 0 then Cfg.mailBatchSize = math.clamp(math.floor(n), 1, 999999) end end })
AutoMailSec:AddInput({ Title = "Delay", Content = "Delay between internal batches, minimum 9 seconds", Default = tostring(Cfg.mailDelay),
    Callback = function(v) local n = tonumber(v); if n then Cfg.mailDelay = math.max(n, 9) end end })
local mailStartToggle = AutoMailSec:AddToggle({ Title = "Auto / Start Mail Send", Content = "Runs current mail config, then turns itself off", Default = Cfg.autoMailSend,
    Callback = function(v)
        Cfg.autoMailSend = v
        if syncingMailToggles then return end
        if not v then
            if _G._GAG2MailToggleSet then _G._GAG2MailToggleSet(false) end
            return
        end
        task.spawn(runMailSendRequest)
    end })
AutoMailSec:AddToggle({ Title = "Auto Claim Mail Inbox", Content = "Automatically claims all incoming items/seeds from mailbox every 10s", Default = Cfg.autoMailClaim,
    Callback = function(v)
        Cfg.autoMailClaim = v
        if v and _G._ClaimMailNow then task.spawn(_G._ClaimMailNow) end
    end })
local syncingMailToggles = false
_G._GAG2MailToggleSet = function(v)
    Cfg.autoMailSend = v
    if syncingMailToggles then return end
    syncingMailToggles = true
    if mailStartToggle and type(mailStartToggle.Set) == "function" and mailStartToggle.Value ~= v then mailStartToggle:Set(v) end
    syncingMailToggles = false
end

local AutoMailFruitSec = MainTab:AddSection("Mail Fruits", false)
AutoMailFruitSec:AddInput({ Title = "Mail To (Username)", Content = "Same target as Mail Send", Default = tostring(Cfg.mailTarget or ""),
    Callback = function(v) resolveMailTarget(v, true) end })
AutoMailFruitSec:AddInput({ Title = "Total Sheckles", Content = "Example: 300m. Sends fruits from lowest value upward until target is reached", Default = tostring(Cfg.mailFruitValueTarget or ""),
    Callback = function(v) Cfg.mailFruitValueTarget = tostring(v or "") end })
AutoMailFruitSec:AddInput({ Title = "Max Fruits", Content = "Maximum fruits used to reach target value", Default = tostring(Cfg.mailCount),
    Callback = function(v) Cfg.mailCount = math.max(1, math.floor(tonumber(v) or 20)) end })
AutoMailFruitSec:AddInput({ Title = "Filter: Min Fruit Value", Content = "E.g. 500k. Only sends fruits worth >= this.", Default = tostring(Cfg.mailFruitMinValue or "0"),
    Callback = function(v) Cfg.mailFruitMinValue = tostring(v or "0") end })
AutoMailFruitSec:AddInput({ Title = "Filter: Max Fruit Value", Content = "E.g. 10m. Only sends fruits worth <= this.", Default = tostring(Cfg.mailFruitMaxValue or "999q"),
    Callback = function(v) Cfg.mailFruitMaxValue = tostring(v or "999q") end })
mailFruitToggle = AutoMailFruitSec:AddToggle({ Title = "Auto / Start Mail Fruits", Content = "If Total Sheckles is filled: send low-value fruits until target. If blank/0: send all fruits up to Max Fruits.", Default = false,
    Callback = function(v)
        if not v then
            Cfg.autoMailSend = false
            return
        end
        if mailSendingActive then
            mailNotify("Mail already running", 2)
            return
        end
        local targetText = tostring(Cfg.mailFruitValueTarget or "")
        local hasValueTarget = parseMoneyInput(targetText) > 0
        Cfg.mailCategory = "Fruits"
        Cfg.mailItemKey = { "All" }
        Cfg.mailCount = math.max(1, math.floor(tonumber(Cfg.mailCount) or 1))
        Cfg.mailFruitValueTarget = hasValueTarget and targetText or ""
        Cfg.mailSendMode = "Batch Loop"
        Cfg.mailBatchSize = math.clamp(tonumber(Cfg.mailBatchSize) or 20, 1, 999999)
        Cfg.autoMailSend = true
        if _G._GAG2MailToggleSet then _G._GAG2MailToggleSet(true) end
        task.spawn(runMailSendRequest)
    end })

local AutoPetsSec = MainTab:AddSection("Automation Pets", false)
AutoPetsSec:AddInput({ Title = "Buy Pet Delay", Content = "Seconds between each tame attempt (min 1)", Default = tostring(Cfg.buyPetDelay),
    Callback = function(v) local n = tonumber(v); if n and n >= 0 then Cfg.buyPetDelay = n end end })
AutoPetsSec:AddDropdown({ Title = "Select Pets", Multi = true, Default = savedDropdown("selBuyPet"),
    Options = getOptionList("Pets"), DynamicOption = "Pets",
    Callback = function(v) Cfg.selBuyPet = v end })
AutoPetsSec:AddDropdown({ Title = "Select Rarity Pets", Multi = true, Default = savedDropdown("selBuyPetRarity"),
    Options = getOptionList("Rarities6"), DynamicOption = "Rarities6",
    Callback = function(v) Cfg.selBuyPetRarity = v end })
AutoPetsSec:AddDropdown({ Title = "Select Size Pets", Multi = true, Default = savedDropdown("selBuyPetSize"),
    Options = getOptionList("PetSizes"), DynamicOption = "PetSizes",
    Callback = function(v) Cfg.selBuyPetSize = v end })
AutoPetsSec:AddToggle({ Title = "Auto Buy Pet", Content = "Auto tame wild pets matching filter", Default = Cfg.autoBuyPet,
    Callback = function(v) Cfg.autoBuyPet = v end })

local StackFarmSec = MainTab:AddSection("Stack Farm Manager", false)
StackFarmSec:AddToggle({ Title = "Enable Stack Farming", Content = "Run Sprinkler/Trowel/Shovel automations in sequential priority order", Default = Cfg.stackFarm,
    Callback = function(v) Cfg.stackFarm = v end })
StackFarmSec:AddDropdown({ Title = "Priority 1", Default = { "Sprinkler" },
    Options = getOptionList("GearTypes"), DynamicOption = "GearTypes",
    Callback = function(v)
        local task = v[1] or "Sprinkler"
        Cfg.sfPriority[task] = 1
    end })
StackFarmSec:AddDropdown({ Title = "Priority 2", Default = { "Trowel" },
    Options = getOptionList("GearTypes"), DynamicOption = "GearTypes",
    Callback = function(v)
        local task = v[1] or "Trowel"
        Cfg.sfPriority[task] = 2
    end })
StackFarmSec:AddDropdown({ Title = "Priority 3", Default = { "Shovel" },
    Options = getOptionList("GearTypes"), DynamicOption = "GearTypes",
    Callback = function(v)
        local task = v[1] or "Shovel"
        Cfg.sfPriority[task] = 3
    end })
end)()

-- ==================== TAB: AUTOMATICALLY ====================
;(function()
local AutomaticallyTab = Window:CreateTab({ Name = "Automatically", Icon = "rbxassetid://10734923549" })

local AutoPlantScanTab = Window:CreateTab({ Name = "Auto Plant Scan", Icon = "rbxassetid://10734950309" })
local AutoPlantScanSec = AutoPlantScanTab:AddSection("Automation Planting Vuln", false)
AutoPlantScanSec:AddToggle({ Title = "Enable Auto Plant Scan", Content = "Reverse -> sprinkler at saved position -> plant -> scan KG -> cancel reverse on success / rejoin on fail", Default = (Cfg.apsResume or Cfg.autoPlantScan),
    Callback = function(v)
        -- Fluent-style UI callbacks can fire during construction. Do not let an
        -- init-time false overwrite the resume flag saved right before rejoin.
        if not cfgReadyToSave then
            Cfg.autoPlantScan = Cfg.apsResume or Cfg.autoPlantScan
            traceAPS("toggle_callback_ignored_init", "v=" .. tostring(v))
            return
        end
        Cfg.autoPlantScan = v
        Cfg.apsResume = v
        traceAPS("toggle_callback_user", "v=" .. tostring(v))
        saveConfigNow()
    end })
AutoPlantScanSec:AddToggle({ Title = "Disable Teleport", Content = "Forced ON by this mode so your character stays still", Default = true,
    Callback = function(v) Cfg.disableTp = true; Cfg.disablePlantTp = true end })
AutoPlantScanSec:AddDropdown({ Title = "Select Seed", Default = savedDropdown("apsSeedName"),
    Options = getOptionList("Seeds"), DynamicOption = "Seeds",
    Callback = function(v) Cfg.apsSeedName = v[1] or "Carrot" end })
AutoPlantScanSec:AddDropdown({ Title = "Scan Crop Name", Default = savedDropdown("apsCropName"),
    Options = getOptionList("Plants"), DynamicOption = "Plants",
    Callback = function(v) Cfg.apsCropName = v[1] or "Carrot" end })
AutoPlantScanSec:AddDropdown({ Title = "Select Sprinkler", Default = savedDropdown("apsSprinkler"),
    Options = getOptionList("SprinklerTiers"), DynamicOption = "SprinklerTiers",
    Callback = function(v) Cfg.apsSprinkler = v[1] or "Super Sprinkler" end })
AutoPlantScanSec:AddInput({ Title = "Weight Threshold (kg)", Content = "Success when scanned crop passes this KG", Default = tostring(Cfg.apsWeightThresh),
    Callback = function(v) Cfg.apsWeightThresh = tonumber(v) or 30 end })
AutoPlantScanSec:AddDropdown({ Title = "Threshold Mode", Default = savedDropdown("apsThreshMode"),
    Options = { "Above", "Below" },
    Callback = function(v) Cfg.apsThreshMode = v[1] or "Above" end })
AutoPlantScanSec:AddInput({ Title = "Plant Amount Per Cycle", Content = "Fixed max seeds to plant inside selected sprinkler radius", Default = tostring(Cfg.apsPlantAmount),
    Callback = function(v) Cfg.apsPlantAmount = math.max(1, math.floor(tonumber(v) or 24)) end })
AutoPlantScanSec:AddInput({ Title = "APS Webhook URL", Content = "Discord webhook for every detected target crop scan", Default = tostring(Cfg.apsWebhookUrl or ""),
    Callback = function(v)
        if not cfgReadyToSave then return end
        Cfg.apsWebhookUrl = tostring(v or "")
        saveConfigNow()
    end })
AutoPlantScanSec:AddToggle({ Title = "APS Webhook", Content = "Send Discord embed when target crop is detected, including below-threshold results", Default = Cfg.apsWebhook,
    Callback = function(v)
        if not cfgReadyToSave then return end
        Cfg.apsWebhook = v
        saveConfigNow()
    end })
AutoPlantScanSec:AddButton({ Title = "Test APS Webhook", Content = "Send a test Auto Plant Scan embed now",
    Callback = function()
        _G._sendApsWebhook("test", { cropName = Cfg.apsCropName, kg = Cfg.apsWeightThresh, type = "test" })
    end })
AutoPlantScanSec:AddButton({ Title = "Use Current Position", Content = "Save current position as sprinkler/plant target for this account",
    Callback = function()
        local hrp = getHRP()
        if not hrp then return end
        local pos = hrp.Position
        local plot = getMyPlot()
        local pivot = plot and plot:GetPivot()
        local localPos = pivot and pivot:PointToObjectSpace(pos) or nil
        Cfg.sprinklerSavedPosition = {
            x = math.floor(pos.X * 100 + 0.5) / 100,
            y = math.floor(pos.Y * 100 + 0.5) / 100,
            z = math.floor(pos.Z * 100 + 0.5) / 100,
            localPos = localPos and {
                x = math.floor(localPos.X * 100 + 0.5) / 100,
                y = math.floor(localPos.Y * 100 + 0.5) / 100,
                z = math.floor(localPos.Z * 100 + 0.5) / 100,
            } or nil,
            userId = LocalPlayer.UserId,
            name = LocalPlayer.Name,
        }
        Cfg.sprinklerPlaceMode = "Saved Position"
        saveConfigNow()
        setStatus(("Auto Plant Scan target saved: %.1f, %.1f, %.1f"):format(pos.X, pos.Y, pos.Z))
    end })

local AutoSprinklerSec = AutomaticallyTab:AddSection("Automation Sprinkler", false)
AutoSprinklerSec:AddToggle({ Title = "Disable Teleport", Default = Cfg.disableTp,
    Callback = function(v) Cfg.disableTp = v end })
AutoSprinklerSec:AddInput({ Title = "Sprinkler Cycle Delay", Content = "Minutes to wait after placing selected sprinklers", Default = tostring(Cfg.sprinklerDelay),
    Callback = function(v) local n = tonumber(v); if n and n >= 0.1 then Cfg.sprinklerDelay = n end end })
AutoSprinklerSec:AddDropdown({ Title = "Select Sprinklers", Multi = true, Default = savedDropdown("selSprinkler"),
    Options = getOptionList("SprinklerTiers"), DynamicOption = "SprinklerTiers",
    Callback = function(v) Cfg.selSprinkler = v end })
AutoSprinklerSec:AddDropdown({ Title = "Place Location", Default = savedDropdown("sprinklerPlaceMode"),
    Options = { "Player Position", "At Plants", "Saved Position" },
    Callback = function(v) Cfg.sprinklerPlaceMode = v[1] or "Player Position" end })
AutoSprinklerSec:AddDropdown({ Title = "Select Target Plant", Multi = true, Default = savedDropdown("selSprinklerPlant"),
    Options = getOptionList("Seeds"), DynamicOption = "Seeds",
    Callback = function(v) Cfg.selSprinklerPlant = v end })
AutoSprinklerSec:AddToggle({ Title = "Auto Place Sprinkler", Content = "Place one of each selected sprinkler, 1 second apart, then wait cycle delay", Default = Cfg.autoSprinkler,
    Callback = function(v)
        Cfg.autoSprinkler = v
        Cfg.autoSprinklerAll = false
        if v then
            if _G._ResetSprinklerToggleTeleport then _G._ResetSprinklerToggleTeleport() end
            if _G._RunSprinklerNow then task.spawn(_G._RunSprinklerNow) end
        end
    end })
AutoSprinklerSec:AddToggle({ Title = "Teleport To Placed Sprinkler", Content = "After placing sprinklers, teleport to one placed sprinkler", Default = Cfg.autoTpToSprinkler,
    Callback = function(v) Cfg.autoTpToSprinkler = v end })
AutoSprinklerSec:AddButton({ Title = "Save Sprinkler Position", Content = "Save current coordinates for Saved Position placement",
    Callback = function()
        local hrp = getHRP()
        if not hrp then return end
        local pos = hrp.Position
        local plot = getMyPlot()
        local pivot = plot and plot:GetPivot()
        local localPos = pivot and pivot:PointToObjectSpace(pos) or nil
        Cfg.sprinklerSavedPosition = {
            x = math.floor(pos.X * 100 + 0.5) / 100,
            y = math.floor(pos.Y * 100 + 0.5) / 100,
            z = math.floor(pos.Z * 100 + 0.5) / 100,
            localPos = localPos and {
                x = math.floor(localPos.X * 100 + 0.5) / 100,
                y = math.floor(localPos.Y * 100 + 0.5) / 100,
                z = math.floor(localPos.Z * 100 + 0.5) / 100,
            } or nil,
            userId = LocalPlayer.UserId,
            name = LocalPlayer.Name,
        }
        Cfg.sprinklerPlaceMode = "Saved Position"
        saveConfigNow()
        setStatus(("Saved sprinkler position: %.1f, %.1f, %.1f"):format(pos.X, pos.Y, pos.Z))
    end })
AutoSprinklerSec:AddToggle({ Title = "Sprinkler Timer GUI", Content = "Show live remaining time for sprinklers on your plot", Default = Cfg.sprinklerTimerGui,
    Callback = function(v) Cfg.sprinklerTimerGui = v end })

local AutoWaterCanSec = AutomaticallyTab:AddSection("Automation Watering Can", false)
AutoWaterCanSec:AddInput({ Title = "Water Delay", Content = "Seconds between watering cycles (default 30)", Default = tostring(Cfg.waterCanDelay),
    Callback = function(v) local n = tonumber(v); if n and n >= 5 then Cfg.waterCanDelay = n end end })
AutoWaterCanSec:AddInput({ Title = "Water Uses Per Cycle", Content = "How many times to use watering can every delay cycle (1-20)", Default = tostring(Cfg.waterCanUses),
    Callback = function(v) local n = tonumber(v); if n then Cfg.waterCanUses = math.clamp(math.floor(n), 1, 20) end end })
AutoWaterCanSec:AddDropdown({ Title = "Select Watering Can", Multi = true, Default = savedDropdown("selWaterCan"),
    Options = getOptionList("WateringCans"), DynamicOption = "WateringCans",
    Callback = function(v) Cfg.selWaterCan = v end })
AutoWaterCanSec:AddToggle({ Title = "Auto Watering Can", Content = "Only waters near placed selected sprinkler every delay seconds", Default = Cfg.autoWaterCan,
    Callback = function(v) Cfg.autoWaterCan = v end })

local AutoTrowelSec = AutomaticallyTab:AddSection("Automation Trowel", false)
AutoTrowelSec:AddInput({ Title = "Delay To Trowel", Content = "Seconds between each move cycle (min 1)", Default = tostring(Cfg.trowelDelay),
    Callback = function(v) local n = tonumber(v); if n and n >= 0 then Cfg.trowelDelay = n end end })
AutoTrowelSec:AddDropdown({ Title = "Select Plant", Multi = true, Default = savedDropdown("selTrowelPlant"),
    Options = getOptionList("Plants"), DynamicOption = "Plants",
    Callback = function(v) Cfg.selTrowelPlant = v end })
AutoTrowelSec:AddDropdown({ Title = "Select Position", Default = { "Player Position" },
    Options = { "Player Position", "Saved Position" },
    Callback = function(v) Cfg.selTrowelPos = v[1] or "Player Position" end })
AutoTrowelSec:AddButton({ Title = "Save Position", Content = "Save current HRP position as trowel target",
    Callback = function()
        if _G._SaveTrowelPos then _G._SaveTrowelPos() end
    end })
AutoTrowelSec:AddToggle({ Title = "Auto Trowel Plant", Content = "Auto move matching plants to target position (requires Trowel in backpack)", Default = Cfg.autoTrowel,
    Callback = function(v)
        Cfg.autoTrowel = v
        if v and _G._ResetAutoTrowelMoved then _G._ResetAutoTrowelMoved() end
    end })

local AutoShovelSec = AutomaticallyTab:AddSection("Automation Shovel", false)
AutoShovelSec:AddSeperator({ Title = "- [ Shovel Tree ] -" })
AutoShovelSec:AddInput({ Title = "Delay To Shovel Tree", Content = "Seconds between each tree shovel cycle (min 1)", Default = tostring(Cfg.shovelTreeDelay),
    Callback = function(v) local n = tonumber(v); if n and n >= 0 then Cfg.shovelTreeDelay = n end end })
AutoShovelSec:AddDropdown({ Title = "Select Tree", Multi = true, Default = savedDropdown("selShovelTree"),
    Options = getOptionList("Plants"), DynamicOption = "Plants",
    Callback = function(v) Cfg.selShovelTree = v end })
AutoShovelSec:AddDropdown({ Title = "Select Rarity Tree", Multi = true, Default = savedDropdown("selShovelTreeRarity"),
    Options = getOptionList("Rarities6"), DynamicOption = "Rarities6",
    Callback = function(v) Cfg.selShovelTreeRarity = v end })
AutoShovelSec:AddDropdown({ Title = "Select Mutation Tree", Multi = true, Default = savedDropdown("selShovelTreeMut"),
    Options = MUT_LIST,
    Callback = function(v) Cfg.selShovelTreeMut = v end })
AutoShovelSec:AddToggle({ Title = "Auto Shovel Tree", Content = "Permanently remove matching plants (requires Shovel in backpack/equipped)", Default = Cfg.autoShovelTree,
    Callback = function(v) Cfg.autoShovelTree = v end })
AutoShovelSec:AddSeperator({ Title = "- [ Shovel Fruit ] -" })
AutoShovelSec:AddInput({ Title = "Delay To Shovel Fruit", Content = "Seconds between each fruit shovel cycle (min 1)", Default = tostring(Cfg.shovelFruitDelay),
    Callback = function(v) local n = tonumber(v); if n and n >= 0 then Cfg.shovelFruitDelay = n end end })
AutoShovelSec:AddDropdown({ Title = "Select Fruit", Multi = true, Default = savedDropdown("selShovelFruit"),
    Options = getOptionList("Plants"), DynamicOption = "Plants",
    Callback = function(v) Cfg.selShovelFruit = v end })
AutoShovelSec:AddDropdown({ Title = "Select Rarity", Multi = true, Default = savedDropdown("selShovelFruitRarity"),
    Options = getOptionList("Rarities6"), DynamicOption = "Rarities6",
    Callback = function(v) Cfg.selShovelFruitRarity = v end })
AutoShovelSec:AddDropdown({ Title = "Select Mutation", Multi = true, Default = savedDropdown("selShovelFruitMut"),
    Options = MUT_LIST,
    Callback = function(v) Cfg.selShovelFruitMut = v end })
AutoShovelSec:AddDropdown({ Title = "Select Threshold Mode", Default = savedDropdown("selShovelThreshMode"),
    Options = getOptionList("CompareModes"), DynamicOption = "CompareModes",
    Callback = function(v) Cfg.selShovelThreshMode = v[1] or "" end })
AutoShovelSec:AddInput({ Title = "Weight Threshold", Content = "Min/max weight for threshold filter", Default = tostring(Cfg.shovelWeightThresh),
    Callback = function(v) local n = tonumber(v); if n then Cfg.shovelWeightThresh = n end end })
AutoShovelSec:AddToggle({ Title = "Auto Shovel Fruit", Content = "Remove mature fruit matching filter (requires Shovel in backpack/equipped)", Default = Cfg.autoShovelFruit,
    Callback = function(v) Cfg.autoShovelFruit = v end })
end)()

-- ==================== TAB: INVENTORY ====================
;(function()
local InventoryTab = Window:CreateTab({ Name = "Inventory", Icon = "rbxassetid://10709769841" })

local AutoFavSec = InventoryTab:AddSection("Automation Favorite", false)
AutoFavSec:AddInput({ Title = "Favorite Delay", Content = "Seconds between each cycle (min 0.5)", Default = tostring(Cfg.favDelay),
    Callback = function(v) local n = tonumber(v); if n and n >= 0 then Cfg.favDelay = n end end })
AutoFavSec:AddDropdown({ Title = "Select Favorite Fruit", Multi = true, Default = savedDropdown("selFavFruit"),
    Options = getOptionList("Plants"), DynamicOption = "Plants",
    Callback = function(v) Cfg.selFavFruit = v end })
AutoFavSec:AddDropdown({ Title = "Select Favorite Rarity", Multi = true, Default = savedDropdown("selFavRarity"),
    Options = getOptionList("Rarities6"), DynamicOption = "Rarities6",
    Callback = function(v) Cfg.selFavRarity = v end })
AutoFavSec:AddDropdown({ Title = "Select Favorite Mutation", Multi = true, Default = savedDropdown("selFavMut"),
    Options = MUT_LIST,
    Callback = function(v) Cfg.selFavMut = v end })
AutoFavSec:AddDropdown({ Title = "Select Threshold Mode", Default = savedDropdown("selFavThresh"),
    Options = getOptionList("CompareModes"), DynamicOption = "CompareModes",
    Callback = function(v) Cfg.selFavThresh = v[1] or "" end })
AutoFavSec:AddInput({ Title = "Weight Threshold", Content = "Min/max weight for threshold filter", Default = tostring(Cfg.favWeightThresh),
    Callback = function(v) local n = tonumber(v); if n then Cfg.favWeightThresh = n end end })
AutoFavSec:AddToggle({ Title = "Auto Favorite Fruit", Content = "Auto-favorite fruits matching filter", Default = Cfg.autoFavFruit,
    Callback = function(v) Cfg.autoFavFruit = v end })
AutoFavSec:AddToggle({ Title = "Auto UnFavorite Fruit", Content = "Auto-unfavorite fruits matching filter", Default = Cfg.autoUnFavFruit,
    Callback = function(v) Cfg.autoUnFavFruit = v end })
AutoFavSec:AddToggle({ Title = "Auto UnFavorite All Fruit", Content = "Unfavorite every fruit in backpack", Default = Cfg.autoUnFavAll,
    Callback = function(v) Cfg.autoUnFavAll = v end })
end)()

-- ==================== TAB: SHOP ====================
;(function()
local ShopTab = Window:CreateTab({ Name = "Shop", Icon = "rbxassetid://10734952273" })

local ShopSeedSec = ShopTab:AddSection("Shop Seeds", false)
ShopSeedSec:AddInput({ Title = "Buy Delay", Content = "Seconds between each buy cycle (min 1)", Default = tostring(Cfg.buyShopDelay),
    Callback = function(v) local n = tonumber(v); if n and n >= 0 then Cfg.buyShopDelay = n end end })
ShopSeedSec:AddDropdown({ Title = "Select Seed", Multi = true, Default = savedDropdown("selBuySeed"),
    Options = getOptionList("Plants"), DynamicOption = "Plants",
    Callback = function(v) Cfg.selBuySeed = v end })
ShopSeedSec:AddToggle({ Title = "Auto Buy Seeds", Content = "Auto buy selected seed when in stock", Default = Cfg.autoBuySeed,
    Callback = function(v) Cfg.autoBuySeed = v end })
ShopSeedSec:AddToggle({ Title = "Auto Buy All Seeds", Content = "Auto buy every seed that is in stock", Default = Cfg.autoBuyAllSeeds,
    Callback = function(v) Cfg.autoBuyAllSeeds = v end })

local ShopGearSec = ShopTab:AddSection("Shop Gear", false)
ShopGearSec:AddDropdown({ Title = "Select Gear", Multi = true, Default = savedDropdown("selBuyGear"),
    Options = getOptionList("Gear"), DynamicOption = "Gear",
    Callback = function(v) Cfg.selBuyGear = v end })
ShopGearSec:AddToggle({ Title = "Auto Buy Gear", Content = "Auto buy selected gear when in stock", Default = Cfg.autoBuyGear,
    Callback = function(v) Cfg.autoBuyGear = v end })
ShopGearSec:AddToggle({ Title = "Auto Buy All Gear", Content = "Auto buy every gear that is in stock", Default = Cfg.autoBuyAllGear,
    Callback = function(v) Cfg.autoBuyAllGear = v end })

local ShopCrateSec = ShopTab:AddSection("Shop Crate", false)
ShopCrateSec:AddDropdown({ Title = "Select Crate", Multi = true, Default = savedDropdown("selBuyCrate"),
    Options = getOptionList("Crates"), DynamicOption = "Crates",
    Callback = function(v) Cfg.selBuyCrate = v end })
ShopCrateSec:AddToggle({ Title = "Auto Buy Crate", Content = "Auto buy selected crate when in stock", Default = Cfg.autoBuyCrate,
    Callback = function(v) Cfg.autoBuyCrate = v end })
ShopCrateSec:AddToggle({ Title = "Auto Buy All Crates", Content = "Auto buy every crate that is in stock", Default = Cfg.autoBuyAllCrates,
    Callback = function(v) Cfg.autoBuyAllCrates = v end })

task.wait()
local FruitStockWebhookSec = ShopTab:AddSection("Fruit Stock Webhook", false)
FruitStockWebhookSec:AddInput({ Title = "Discord Webhook URL", Content = "Webhook for fruit stock price updates", Default = tostring(Cfg.fruitStockWebhookUrl or ""),
    Callback = function(v)
        Cfg.fruitStockWebhookUrl = tostring(v or "")
        Cfg.fruitStockWebhookMessageId = ""
        Cfg.fruitStockWebhookAlertId = ""
    end })
FruitStockWebhookSec:AddToggle({ Title = "Fruit Stock Webhook", Content = "Send now, then every 10-minute restock +5s", Default = Cfg.fruitStockWebhook,
    Callback = function(v) Cfg.fruitStockWebhook = v end })
FruitStockWebhookSec:AddButton({ Title = "Test Send Fruit Stock", Content = "Send current fruit stock to webhook now",
    Callback = function() sendFruitStockWebhook("Test") end })
end)()

-- ==================== TAB: MISC ====================
;(function()
local MiscTab = Window:CreateTab({ Name = "Misc", Icon = "rbxassetid://11447063791" })

local ESPSec = MiscTab:AddSection("ESP", false)
ESPSec:AddDropdown({ Title = "Select ESP Fruit", Multi = true, Default = savedDropdown("selEspFruit"),
    Options = getOptionList("Plants"), DynamicOption = "Plants",
    Callback = function(v) Cfg.selEspFruit = v; if Cfg.espFruit and _G._ESPRefreshFruit then _G._ESPRefreshFruit() end end })
task.wait()
ESPSec:AddDropdown({ Title = "Select ESP Rarity", Multi = true, Default = savedDropdown("selEspRarity"),
    Options = getOptionList("Rarities6"), DynamicOption = "Rarities6",
    Callback = function(v) Cfg.selEspRarity = v; if Cfg.espFruit and _G._ESPRefreshFruit then _G._ESPRefreshFruit() end end })
task.wait()
ESPSec:AddDropdown({ Title = "Select ESP Mutation", Multi = true, Default = savedDropdown("selEspMut"),
    Options = MUT_LIST,
    Callback = function(v) Cfg.selEspMut = v; if Cfg.espFruit and _G._ESPRefreshFruit then _G._ESPRefreshFruit() end end })
task.wait()
ESPSec:AddDropdown({ Title = "ESP Kg Filter Mode", Content = "Above = show only >= threshold. Below = show only <= threshold. Blank = off", Default = savedDropdown("espKgMode"),
    Options = { "Above", "Below" },
    Callback = function(v) Cfg.espKgMode = v[1] or ""; if Cfg.espFruit and _G._ESPRefreshFruit then _G._ESPRefreshFruit() end end })
task.wait()
ESPSec:AddInput({ Title = "ESP Kg Threshold", Content = "Kg value for filter. 0 or blank = no filter", Default = tostring(Cfg.espKgThresh),
    Callback = function(v) local n = tonumber(v); Cfg.espKgThresh = (n and n > 0) and n or 0; if Cfg.espFruit and _G._ESPRefreshFruit then _G._ESPRefreshFruit() end end })
task.wait()
ESPSec:AddToggle({ Title = "ESP Fruit", Content = "Show labels above fruits ready to harvest on all plots", Default = Cfg.espFruit,
    Callback = function(v)
        Cfg.espFruit = v
        if v then
            if _G._ESPRefreshFruit then _G._ESPRefreshFruit() end
        else
            if _G._ESPClear then _G._ESPClear() end
        end
    end })
ESPSec:AddDropdown({ Title = "Select Pets", Multi = true, Default = savedDropdown("selEspPet"),
    Options = getOptionList("Pets"), DynamicOption = "Pets",
    Callback = function(v) Cfg.selEspPet = v end })
ESPSec:AddDropdown({ Title = "Select Rarity Pets", Multi = true, Default = savedDropdown("selEspPetRarity"),
    Options = getOptionList("Rarities6"), DynamicOption = "Rarities6",
    Callback = function(v) Cfg.selEspPetRarity = v end })
ESPSec:AddDropdown({ Title = "Select Size Pets", Multi = true, Default = savedDropdown("selEspPetSize"),
    Options = getOptionList("PetSizes"), DynamicOption = "PetSizes",
    Callback = function(v) Cfg.selEspPetSize = v end })
ESPSec:AddToggle({ Title = "ESP Spawned Pets", Content = "Show labels above spawned pets in the world", Default = Cfg.espPet,
    Callback = function(v)
        Cfg.espPet = v
        if v then
            if _G._ESPRefreshPet then _G._ESPRefreshPet() end
        else
            if _G._ESPClear then _G._ESPClear() end
        end
    end })

task.wait()
local DebugSec = MiscTab:AddSection("Debug / UAT", false)
DebugSec:AddToggle({ Title = "Debug Collect", Content = "Print collect decision logs when enabled", Default = Cfg.debugCollect,
    Callback = function(v) Cfg.debugCollect = v end })
DebugSec:AddToggle({ Title = "Debug Shop", Content = "Print shop stock/buy logs when enabled", Default = Cfg.debugShop,
    Callback = function(v) Cfg.debugShop = v end })
DebugSec:AddToggle({ Title = "Debug Sprinkler", Content = "Print sprinkler placement/missing-tool logs", Default = Cfg.debugSprinkler,
    Callback = function(v) Cfg.debugSprinkler = v end })
DebugSec:AddButton({ Title = "Audit Nearby Fruits", Content = "Print up to 30 fruit collect decisions without collecting",
    Callback = function()
        local n = _G._AuditCollectFruits and _G._AuditCollectFruits(30) or 0
        Speed_Library:Notify("Collect audit printed: " .. tostring(n), 3)
    end })
DebugSec:AddButton({ Title = "Audit Shop Selection", Content = "Print selected shop items and stock without buying",
    Callback = function()
        if _G._AuditShopSelection then _G._AuditShopSelection() end
        Speed_Library:Notify("Shop audit printed", 3)
    end })
DebugSec:AddButton({ Title = "Print Config Summary", Content = "Print key automation toggles and selected bucket config",
    Callback = function()
        print("[CONFIG SUMMARY]", "version", SCRIPT_VERSION)
        print("[CONFIG SUMMARY]", "autoCollectFruit", Cfg.autoCollectFruit, "autoBuySeed", Cfg.autoBuySeed, "autoSellFruit", Cfg.autoSellFruit, "espFruit", Cfg.espFruit)
        print("[CONFIG SUMMARY]", "lowKg", table.concat(Cfg.lowKgMut or {}, ","), Cfg.lowKgMode, Cfg.lowKgThresh, "highKg", table.concat(Cfg.highKgMut or {}, ","), Cfg.highKgMode, Cfg.highKgThresh)
        Speed_Library:Notify("Config summary printed", 3)
    end })
DebugSec:AddButton({ Title = "Clear ESP Labels", Content = "Force remove all ESP labels",
    Callback = function()
        if _G._ESPClear then _G._ESPClear() end
        Speed_Library:Notify("ESP labels cleared", 3)
    end })

local MiscSec = MiscTab:AddSection("Misc", false)
MiscSec:AddToggle({ Title = "Force Freeze Position", Content = "Anchor your character to stay perfectly still (prevents knockback)", Default = Cfg.playerFreeze,
    Callback = function(v) Cfg.playerFreeze = v end })
MiscSec:AddToggle({ Title = "Anti-Fling", Content = "Zero out velocity if too large (> 100 studs/s)", Default = Cfg.antiFling,
    Callback = function(v) Cfg.antiFling = v end })
MiscSec:AddToggle({ Title = "Less Knockback", Content = "Cap velocity at 30 studs/s to reduce knockback", Default = Cfg.lessKnockback,
    Callback = function(v) Cfg.lessKnockback = v end })
MiscSec:AddToggle({ Title = "Instant Interact Prompt", Content = "Set HoldDuration=0 on all ProximityPrompts", Default = false,
    Callback = function(v)
        Cfg.instantPrompt = v
        if v then
            for _, obj in pairs(game:GetDescendants()) do
                if obj:IsA("ProximityPrompt") then obj.HoldDuration = 0 end
            end
        end
    end })
MiscSec:AddToggle({ Title = "Bypass Gameplay Paused", Content = "Unanchor HRP and restore WalkSpeed if locked by game", Default = Cfg.bypassPaused,
    Callback = function(v) Cfg.bypassPaused = v end })
MiscSec:AddButton({ Title = "Reverse", Content = "Sends exact SetSignImage packet captured from hub X",
    Callback = function()
        sendReversePacket()
    end })
MiscSec:AddButton({ Title = "Cancel Reverse", Content = "Sends exact cancel reverse packets captured from hub X",
    Callback = function()
        sendCancelReversePacket()
    end })

local MiscGardenSec = MiscTab:AddSection("Misc Garden", false)
MiscGardenSec:AddToggle({ Title = "Noclip Plants", Content = "Disable collision on plants in your plot", Default = Cfg.noclipPlants,
    Callback = function(v)
        Cfg.noclipPlants = v
        if not v then
            local plot = getMyPlot()
            local plantsF = plot and plot:FindFirstChild("Plants")
            if plantsF then
                for _, obj in pairs(plantsF:GetDescendants()) do
                    if obj:IsA("BasePart") then
                        obj.CanCollide = true
                    end
                end
            end
        end
    end })
MiscGardenSec:AddDropdown({ Title = "Select Plants to Hide", Multi = true, Default = savedDropdown("selHidePlants"),
    Options = getOptionList("Plants"), DynamicOption = "Plants",
    Callback = function(v) Cfg.selHidePlants = v end })
MiscGardenSec:AddToggle({ Title = "Hide Plants", Content = "Make selected plants invisible in your plot", Default = Cfg.hidePlants,
    Callback = function(v)
        Cfg.hidePlants = v
        if v then
            if not msEmpty(Cfg.selHidePlants) and _G._HidePlantsOn then _G._HidePlantsOn() end
        else
            if _G._HidePlantsOff then _G._HidePlantsOff() end
        end
    end })
MiscGardenSec:AddToggle({ Title = "Hide Fruits", Content = "Make fruits invisible so they don't block view when placing sprinklers", Default = Cfg.hideFruits,
    Callback = function(v)
        Cfg.hideFruits = v
        local plot = getMyPlot()
        if plot then
            for _, obj in pairs(plot:GetDescendants()) do
                if obj:FindFirstAncestor("Fruits") then
                    if obj:IsA("BasePart") then
                        obj.Transparency = v and 1 or 0
                    elseif obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") or obj:IsA("Beam") or obj:IsA("Trail") then
                        obj.Enabled = not v
                    end
                end
            end
        end
    end })
_G._ApplyDisableHarvestPromptState = function()
    local plot = getMyPlot()
    if plot then
        for _, obj in pairs(plot:GetDescendants()) do
            if obj:IsA("ProximityPrompt") then
                obj.Enabled = not Cfg.disableHarvestPrompt
            end
        end
    end
end
MiscGardenSec:AddToggle({ Title = "Disable Harvest Prompt", Content = "Hide E prompt on plants so it doesn't trigger while walking/watering", Default = Cfg.disableHarvestPrompt,
    Callback = function(v)
        Cfg.disableHarvestPrompt = v
        _G._ApplyDisableHarvestPromptState()
    end })
task.spawn(function()
    for _ = 1, 20 do
        if not Cfg.disableHarvestPrompt then return end
        _G._ApplyDisableHarvestPromptState()
        task.wait(0.5)
    end
end)

local ServerSec = MiscTab:AddSection("Server", false)
ServerSec:AddInput({ Title = "Job ID", Content = "Paste target server Job ID here",
    Callback = function(v) Cfg.hopJobId = v end })
ServerSec:AddButton({ Title = "Join Job ID", Content = "Teleport to server with the given Job ID",
    Callback = function()
        if Cfg.hopJobId ~= "" then
            game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, Cfg.hopJobId)
        end
    end })
ServerSec:AddButton({ Title = "Rejoin Current Server", Content = "Teleport back into this place without forcing exact Job ID",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
    end })
ServerSec:AddToggle({ Title = "Auto Reconnect", Content = "Rejoin the game when kicked or disconnected", Default = false,
    Callback = function(v)
        if v then
            game:GetService("Players").LocalPlayer.OnTeleport:Connect(function(state)
                if state == Enum.TeleportState.RequestedFromServer then
                    task.wait(3)
                    game:GetService("TeleportService"):Teleport(game.PlaceId)
                end
            end)
        end
    end })
local WeatherDisconnectSec = MiscTab:AddSection("Weather Disconnect", false)
WeatherDisconnectSec:AddToggle({ Title = "Auto Weather Disconnect", Content = "Kick on selected bad weather, then delayed Teleport rejoin after X minutes", Default = Cfg.autoWeatherDisconnect,
    Callback = function(v) Cfg.autoWeatherDisconnect = v end })
WeatherDisconnectSec:AddDropdown({ Title = "Select Bad Weather", Multi = true, Default = savedDropdown("selDisconnectWeather"),
    Options = WEATHER_DISCONNECT_OPTIONS,
    Callback = function(v) Cfg.selDisconnectWeather = v end })
WeatherDisconnectSec:AddInput({ Title = "Reconnect Delay Minutes", Content = "Minutes to stay disconnected before scheduled rejoin", Default = tostring(Cfg.weatherReconnectMinutes),
    Callback = function(v)
        local n = tonumber(v)
        if n and n >= 0.1 then Cfg.weatherReconnectMinutes = n end
    end })

local HopSec = MiscTab:AddSection("Hop Server", false)
HopSec:AddInput({ Title = "Place Version", Content = "Target game.PlaceVersion to hop to",
    Callback = function(v) Cfg.hopPlaceVer = v end })
HopSec:AddToggle({ Title = "Auto Hop Until Place Version", Content = "Keep hopping until PlaceVersion matches input", Default = Cfg.autoHopUntilVer,
    Callback = function(v) Cfg.autoHopUntilVer = v end })
HopSec:AddButton({ Title = "Hop Server", Content = "Teleport to a random server",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId)
    end })

local FriendsSec = MiscTab:AddSection("Friends", false)
FriendsSec:AddToggle({ Title = "Auto Add All Players", Content = "Auto send friend request to every player in current/private server", Default = Cfg.autoFriendAddAll,
    Callback = function(v)
        Cfg.autoFriendAddAll = v
        if v then for _, plr in ipairs(Players:GetPlayers()) do tryAutoAddFriend(plr) end end
    end })
FriendsSec:AddToggle({ Title = "Auto Accept Friend Requests", Content = "Auto accept incoming friend requests", Default = Cfg.autoFriendAccept,
    Callback = function(v) Cfg.autoFriendAccept = v end })

local FPSSec = MiscTab:AddSection("More FPS", false)
FPSSec:AddButton({ Title = "Remove Other Gardens", Content = "Hide other players' garden plots",
    Callback = function()
        if _G._MiscHideGardens then _G._MiscHideGardens() end
    end })
FPSSec:AddToggle({ Title = "Auto Remove Other Gardens", Content = "Hide new gardens as they load in", Default = false,
    Callback = function(v)
        Cfg.autoRemoveOtherGardens = v
        if v and _G._MiscHideGardens then _G._MiscHideGardens() end
    end })
FPSSec:AddButton({ Title = "Reduce Lag", Content = "Disable particles, post-effects, and global shadows",
    Callback = function()
        local Lighting = game:GetService("Lighting")
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
                obj.Enabled = false
            end
        end
        Lighting.GlobalShadows = false
        for _, obj in pairs(Lighting:GetDescendants()) do
            if obj:IsA("PostEffect") then obj.Enabled = false end
        end
    end })
FPSSec:AddToggle({ Title = "Show Screen White", Content = "Cover screen with white overlay", Default = false,
    Callback = function(v)
        Cfg.screenWhite = v
        if v then
            Cfg.screenBlack = false
            if _G._MiscSetScreen then _G._MiscSetScreen(Color3.new(1,1,1)) end
        else
            if _G._MiscSetScreen then _G._MiscSetScreen(nil) end
        end
    end })
FPSSec:AddToggle({ Title = "Show Screen Black", Content = "Cover screen with black overlay", Default = false,
    Callback = function(v)
        Cfg.screenBlack = v
        if v then
            Cfg.screenWhite = false
            if _G._MiscSetScreen then _G._MiscSetScreen(Color3.new(0,0,0)) end
        else
            if _G._MiscSetScreen then _G._MiscSetScreen(nil) end
        end
    end })
end)()

-- ==================== TAB: SETTINGS ====================
;(function()
local SettingsTab = Window:CreateTab({ Name = "Settings", Icon = "rbxassetid://10734950309" })

local DataSec = SettingsTab:AddSection("Game Data", false)
DataSec:AddButton({ Title = "Refresh Dynamic Lists", Content = "Refreshes Gear, Pets, and Crates from game data",
    Callback = function()
        if type(_G._GAG_DYNAMIC_DROPDOWNS) == "table" then
            for _, drop in ipairs(_G._GAG_DYNAMIC_DROPDOWNS) do
                if drop and type(drop.Refresh) == "function" and drop.DynamicOption then
                    drop:Refresh(getOptionList(drop.DynamicOption, drop.DynamicSelect), drop.Value)
                end
            end
        end
    end })

local ResetSec = SettingsTab:AddSection("Reset Config", false)
ResetSec:AddButton({ Title = "Reset Script Config", Content = "Reset all settings back to default values",
    Callback = function()
        Cfg.autoHarvest      = false
        Cfg.autoCollectFruit = false
        Cfg.autoCollectAll   = false
        Cfg.autoCollectBest  = false
        Cfg.selWaitMutationFruit = {}
        Cfg.waitMutationAboveKg = 0
        Cfg.autoDropped      = false
        Cfg.autoGoldSeed     = false
        Cfg.autoRainbowSeed  = false
        Cfg.autoAttack       = false
        Cfg.disableTp        = false
        Cfg.stopIfFull       = false
        Cfg.delay            = 0
        Cfg.collectBestMinValue = 0
        Cfg.selFruit         = {}
        Cfg.selRarity        = {}
        Cfg.selMut           = {}
        Cfg.threshMode       = ""
        Cfg.weightThresh     = 0
        Cfg.noneThreshMode   = ""
        Cfg.noneWeightThresh = 0
        Cfg.mutThreshMode    = ""
        Cfg.mutWeightThresh  = 0
        Cfg.lowKgMut         = {}
        Cfg.lowKgMode        = "Below"
        Cfg.lowKgThresh      = 40
        Cfg.highKgMut        = {}
        Cfg.highKgMode       = "Above"
        Cfg.highKgThresh     = 0
        Cfg.autoPlantSeed    = false
        Cfg.autoPlantAll     = false
        Cfg.plantSeedName    = "Select Options"
        Cfg.plantDelay       = 0.1
        Cfg.disablePlantTp   = false
        Cfg.plantPosition    = "Player Position"
        Cfg.plantSprinkler   = "Select Options"
        Cfg.savedPlantPos    = nil
        Cfg.autoSellAll      = false
        Cfg.autoSellFruit    = false
        Cfg.autoSellPets     = false
        Cfg.sellDelay               = 0
        Cfg.autoMailClaim      = false
        Cfg.autoWeatherDisconnect = false
        Cfg.selDisconnectWeather = {}
        Cfg.weatherReconnectMinutes = 3
        Cfg.seedPackSpam       = false
        Cfg.sellIfFull       = false
        Cfg.sellBargain      = false
        Cfg.sellDailyDeal    = false
        Cfg.selSellFruit     = {}
        Cfg.selSellRarity    = {}
        Cfg.selSellMut       = {}
        Cfg.selSellThresh    = ""
        Cfg.sellWeightThresh = 0
        Cfg.sellValueBelow   = 0
        Cfg.selSellPet       = {}
        Cfg.selSellPetRarity = {}
        Cfg.selSellPetSize   = {}
        Cfg.autoBuySeed      = false
        Cfg.autoBuyAllSeeds  = false
        Cfg.selBuySeed       = {}
        Cfg.autoBuyGear      = false
        Cfg.autoBuyAllGear   = false
        Cfg.selBuyGear       = {}
        Cfg.autoBuyCrate     = false
        Cfg.autoBuyAllCrates = false
        Cfg.selBuyCrate      = {}
        Cfg.buyShopDelay     = 5
        Cfg.antiFling        = false
        Cfg.lessKnockback    = false
        Cfg.instantPrompt    = false
        Cfg.bypassPaused     = false
        Cfg.noclipPlants     = false
        Cfg.hideFruits       = false
        Cfg.hidePlants       = false
        Cfg.selHidePlants    = {}
        Cfg.disableHarvestPrompt = false
        Cfg.removeOtherGardens     = false
        Cfg.autoRemoveOtherGardens = false
        Cfg.reduceLag        = false
        Cfg.screenWhite      = false
        Cfg.screenBlack      = false
        Cfg.hopJobId         = ""
        Cfg.hopPlaceVer      = ""
        Cfg.autoHopUntilVer  = false
        Cfg.espFruit         = false
        Cfg.espPet           = false
        Cfg.selEspFruit      = {}
        Cfg.selEspRarity     = {}
        Cfg.selEspMut        = {}
        Cfg.espKgMode        = ""
        Cfg.espKgThresh      = 0
        Cfg.selEspPet        = {}
        Cfg.selEspPetRarity  = {}
        Cfg.selEspPetSize    = {}
        Cfg.autoSteal        = false
        Cfg.autoStealBest    = false
        Cfg.flingPlayers     = false
        Cfg.autoHitStolen    = false
        Cfg.stealDelay       = 1
        Cfg.selStealFilter   = "Select Options"
        Cfg.selStealFruit    = {}
        Cfg.selStealRarity   = {}
        Cfg.selStealMut      = {}

        Cfg.autoBuyPet       = false
        Cfg.buyPetDelay      = 2
        Cfg.selBuyPet        = {}
        Cfg.selBuyPetRarity  = {}
        Cfg.selBuyPetSize    = {}
        Cfg.autoMailSend     = false
        Cfg.mailTarget       = ""
        Cfg.mailTargetId     = 0
        Cfg.mailCategory     = "Seeds"
        Cfg.mailItemKey      = "Select Options"
        Cfg.mailCount        = 5
        Cfg.mailDelay        = 10
        Cfg.autoSprinkler      = false
        Cfg.autoSprinklerAll   = false
        Cfg.sprinklerTimerGui  = false
        Cfg.sprinklerDelay     = 1
        Cfg.selSprinkler       = {}
        Cfg.sprinklerPlaceMode = "Player Position"
        Cfg.sprinklerSpacing   = 4
        Cfg.autoTrowel         = false
        Cfg.trowelDelay        = 2
        Cfg.selTrowelPlant     = {}
        Cfg.selTrowelPos       = "Player Position"
        Cfg.selSprinklerPlant  = {}
        Cfg.waterCanUses       = 1
        Cfg.autoShovelTree     = false
        Cfg.autoShovelFruit    = false
        Cfg.shovelTreeDelay    = 2
        Cfg.shovelFruitDelay   = 2
        Cfg.selShovelTree      = {}
        Cfg.selShovelTreeRarity= {}
        Cfg.selShovelTreeMut   = {}
        Cfg.selShovelFruit     = {}
        Cfg.selShovelFruitRarity={}
        Cfg.selShovelFruitMut  = {}
        Cfg.selShovelThreshMode= ""
        Cfg.shovelWeightThresh = 0
        Cfg.stackFarm          = false
        Cfg.sfPriority         = {}
        Cfg.autoFavFruit     = false
        Cfg.autoUnFavFruit   = false
        Cfg.autoUnFavAll     = false
        Cfg.selFavFruit      = {}
        Cfg.selFavRarity     = {}
        Cfg.selFavMut        = {}
        Cfg.selFavThresh     = ""
        Cfg.favWeightThresh  = 0
        Cfg.favDelay         = 1
    end })
end)()

-- ==================== TAB: CONFIG ====================
;(function()
local ConfigTab = Window:CreateTab({ Name = "Config", Icon = "rbxassetid://8997386997" })

local CustomUISec = ConfigTab:AddSection("Custom UI", false)
CustomUISec:AddSeperator({ Title = "- [ Keybind ] -" })
_G._GAG2_GuiVisible = _G._GAG2_GuiVisible ~= false
_G._GAG2_GuiKeybind = _G._GAG2_GuiKeybind or Enum.KeyCode.RightShift
CustomUISec:AddToggle({ Title = "Enable Keybind", Content = "Toggle GUI visibility with keybind",
    Default = false,
    Callback = function(v)
        _G._GAG2_GuiVisible = true
        if v then
            game:GetService("UserInputService").InputBegan:Connect(function(input, gpe)
                if gpe then return end
                if input.KeyCode == _G._GAG2_GuiKeybind then
                    _G._GAG2_GuiVisible = not _G._GAG2_GuiVisible
                    local sg = game:GetService("CoreGui"):FindFirstChild("SpeedHubXGui") or
                        (game:GetService("CoreGui"):FindFirstChild("RobloxGui") and
                         game:GetService("CoreGui").RobloxGui:GetChildren()[#game:GetService("CoreGui").RobloxGui:GetChildren()])
                    if sg then sg.Enabled = _G._GAG2_GuiVisible end
                end
            end)
        end
    end })

local ConfigManagerSec = ConfigTab:AddSection("Config Manager", false)
ConfigManagerSec:AddSeperator({ Title = "- [ Sync Config ] -" })
local _syncConfigFile = CONFIG_FILE
local _syncConfigStatus = ConfigManagerSec:AddSeperator({ Title = "Sync Target: " .. _syncConfigFile })
local _syncConfigDropdown
_syncConfigDropdown = ConfigManagerSec:AddDropdown({ Title = "Select Config To Sync", Content = "Copy another account/global config into this account", Default = { CONFIG_FILE },
    Options = listConfigFiles(),
    Callback = function(v)
        _syncConfigFile = v[1] or CONFIG_FILE
        if _syncConfigStatus then _syncConfigStatus:Set({ Title = "Sync Target: " .. _syncConfigFile }) end
    end })

ConfigManagerSec:AddButton({ Title = "Sync Selected Config", Content = "Sync and re-execute so GUI reflects new config",
    Callback = function()
        if _syncConfigFile == CONFIG_FILE then return end
        local ok = loadConfigFile(_syncConfigFile, true)
        if ok then
            saveConfigNow()
            if _syncConfigStatus then _syncConfigStatus:Set({ Title = "Synced. Re-execute to refresh GUI." }) end
        else
            if _syncConfigStatus then _syncConfigStatus:Set({ Title = "Sync Failed: " .. tostring(_syncConfigFile) }) end
        end
    end })

ConfigManagerSec:AddSeperator({ Title = "- [ Push Config (Remote Sync) ] -" })
local _pushTargets = {}
local _pushStatus = ConfigManagerSec:AddSeperator({ Title = "Ready to push" })
local _pushDropdown
_pushDropdown = ConfigManagerSec:AddDropdown({ Title = "Select Targets To Overwrite", Content = "Push YOUR config to these accounts", Default = {}, Multi = true,
    Options = listConfigFiles(),
    Callback = function(v) _pushTargets = v end })

ConfigManagerSec:AddButton({ Title = "Refresh All Lists", Content = "Reload configs from executor workspace",
    Callback = function()
        local options = listConfigFiles()
        if _syncConfigDropdown and type(_syncConfigDropdown.Refresh) == "function" then
            _syncConfigDropdown:Refresh(options, { _syncConfigFile })
        end
        if _pushDropdown and type(_pushDropdown.Refresh) == "function" then
            _pushDropdown:Refresh(options, _pushTargets)
        end
    end })

ConfigManagerSec:AddButton({ Title = "Push Config Now", Content = "Overwrite selected accounts with your settings",
    Callback = function()
        if #_pushTargets == 0 then
            if _pushStatus then _pushStatus:Set({ Title = "Select at least 1 target!" }) end
            return
        end
        local okEncode, encoded = pcall(function() return HttpService:JSONEncode(copyTable(CfgData)) end)
        if not okEncode then
            if _pushStatus then _pushStatus:Set({ Title = "Error: Failed to encode config!" }) end
            return
        end
        local successCount = 0
        for _, targetFile in ipairs(_pushTargets) do
            if targetFile ~= CONFIG_FILE then
                local ok, err = pcall(writefile, targetFile, encoded)
                if ok then 
                    successCount = successCount + 1 
                else
                    print("[GAG2] Failed to push to", targetFile, ":", err)
                end
            end
        end
        if _pushStatus then _pushStatus:Set({ Title = "Pushed to " .. successCount .. " accounts! Re-execute them." }) end
    end })
end)()

cfgReadyToSave = true
if Cfg.apsResume then
    Cfg.autoPlantScan = true
end
traceAPS("startup_ready_enforce")
saveConfigNow()
startFruitStockWebhookLoop()

local dynamicThread = coroutine.wrap(function()
    local function fetchDynamic()
        local rs = game:GetService("ReplicatedStorage")
        local sm = rs:WaitForChild("SharedModules")
        
        -- Seeds
        pcall(function()
            local sd = require(sm:WaitForChild("SeedData"))
            for _, v in pairs(sd or {}) do
                if type(v) == "table" and v.SeedName and not table.find(FALLBACK_SEED_OPTIONS, v.SeedName) then
                    table.insert(FALLBACK_SEED_OPTIONS, v.SeedName)
                end
            end
        end)
        
        -- Gear
        pcall(function()
            local gsd = require(sm:WaitForChild("GearShopData"))
            local data = gsd.Data or gsd
            for _, v in pairs(data) do
                if type(v) == "table" and v.ItemName and not table.find(FALLBACK_GEAR_OPTIONS, v.ItemName) then
                    table.insert(FALLBACK_GEAR_OPTIONS, v.ItemName)
                end
            end
        end)
        
        -- Crates
        pcall(function()
            local cd = require(sm:WaitForChild("CrateData"))
            local all = cd.GetAllCrates and cd:GetAllCrates() or (cd.GetAllCrates and cd.GetAllCrates())
            for _, v in pairs(all or {}) do
                local name = (type(v) == "table" and v.DisplayName) or (type(v) == "table" and v.Name) or (type(v) == "string" and v)
                if type(name) == "string" and not table.find(FALLBACK_CRATE_OPTIONS, name) then
                    table.insert(FALLBACK_CRATE_OPTIONS, name)
                end
            end
        end)
        
        -- Pets
        pcall(function()
            local pm = rs:WaitForChild("PetModels", 5)
            if pm then
                for _, child in ipairs(pm:GetChildren()) do
                    if child:IsA("ModuleScript") and not table.find(FALLBACK_PET_OPTIONS, child.Name) then
                        table.insert(FALLBACK_PET_OPTIONS, child.Name)
                    end
                end
            end
        end)

        -- Refresh UI
        if type(_G._GAG_DYNAMIC_DROPDOWNS) == "table" then
            for _, drop in ipairs(_G._GAG_DYNAMIC_DROPDOWNS) do
                if drop and type(drop.Refresh) == "function" and drop.DynamicOption then
                    pcall(function()
                        drop:Refresh(getOptionList(drop.DynamicOption, drop.DynamicSelect), drop.Value)
                    end)
                end
            end
        end
    end
    fetchDynamic()
end)
dynamicThread()

    print("[MonolithUI] UI initialized")
    return true
end

return MonolithUI

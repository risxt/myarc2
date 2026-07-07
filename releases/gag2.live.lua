local Players = game:GetService("Players")
local Player = Players.LocalPlayer
while not Player do
    task.wait()
    Player = Players.LocalPlayer
end
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local SCRIPT_VERSION = "2026.07.01-option-source.4"

-- ==============================================
-- [ CONFIG MAPPING ]
-- Solusi untuk multi-instance (Redfinger dll).
-- Jika ingin 1 config dipakai banyak akun, daftarkan nama akun di sini.
-- Format: ["NamaAkun"] = "NamaConfig.json"
-- ==============================================
local ACCOUNT_CONFIG_MAPPING = {
    -- ["AccountUtama1"] = "MasterConfig.json",
    -- ["AccountTumbal1"] = "FarmerConfig.json",
    -- ["AccountTumbal2"] = "FarmerConfig.json",
    -- ["AccountTumbal3"] = "FarmerConfig.json",
}

_G._GAG_DYNAMIC_DROPDOWNS = _G._GAG_DYNAMIC_DROPDOWNS or {}

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

-- ================================================================
-- GAG2 — Grow a Garden | Automation Suite
-- ================================================================

local Players    = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Networking = require(game:GetService("ReplicatedStorage")
    :WaitForChild("SharedModules"):WaitForChild("Networking"))
local SeedDataMod = require(game:GetService("ReplicatedStorage")
    :WaitForChild("SharedModules"):WaitForChild("SeedData"))

local SEED_RARITY = {}
for _, d in SeedDataMod do
    if d.SeedName and d.Rarity then SEED_RARITY[d.SeedName] = d.Rarity end
end
local RARITY_RANK = { Common=1, Uncommon=2, Rare=3, Epic=4, Legendary=5, Mythic=6, Super=7 }

local FALLBACK_SEED_OPTIONS = { "Carrot","Strawberry","Blueberry","Tulip","Tomato","Apple","Bamboo","Corn","Cactus","Pineapple","Mushroom","Green Bean","Banana","Grape","Coconut","Mango","Dragon Fruit","Acorn","Cherry","Sunflower","Venus Fly Trap","Pomegranate","Poison Apple","Venom Spitter","Briar Rose","Moon Bloom","Hypno Bloom","Dragon's Breath","Ghost Pepper","Poison Ivy","Baby Cactus","Glow Mushroom","Romanesco","Horned Melon" }
local EXTRA_PLANT_FILTER_OPTIONS = { "Gold", "Rainbow", "Mega" }
local RARITY_OPTIONS = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Super" }
local RARITY_NO_SUPER_OPTIONS = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic" }
local COMPARE_MODE_OPTIONS = { "Above", "Below" }
local FALLBACK_GEAR_OPTIONS = { "Common Watering Can","Super Watering Can","Common Sprinkler","Uncommon Sprinkler","Rare Sprinkler","Legendary Sprinkler","Super Sprinkler","Trowel","Wheelbarrow","Sign","Lantern","Basic Pot","Teleporter","Gnome","Speed Mushroom","Jump Mushroom","Shrink Mushroom","Supersize Mushroom","Invisibility Mushroom","Flashbang" }
local FALLBACK_CRATE_OPTIONS = { "Light Crate","Arch Crate","Bench Crate","Bridge Crate","Seesaw Crate","Sign Crate","Teleporter Pad Crate","Ladder Crate","Fence Crate","Owner Door Crate","Conveyor Crate","Spring Crate","Roleplay Crate","Bear Trap Crate","Common Guild Crate","Uncommon Guild Crate","Rare Guild Crate","Epic Guild Crate","Legendary Guild Crate","Mythic Guild Crate","Super Guild Crate" }
local FALLBACK_PET_OPTIONS = { "Frog","Snail","Cat","Bunny","Chick","Dog","Bee","Butterfly","Cow","Duck","Panda","Deer","Dodo","Eagle","Goat","Owl","Polar Bear","Peacock","Shark","Minotaur","Trex" }

local PET_SIZE_OPTIONS = { "Tiny","Small","Normal","Large","Huge","Titanic" }
local SPRINKLER_TIER_OPTIONS = { "Common Sprinkler", "Uncommon Sprinkler", "Rare Sprinkler", "Legendary Sprinkler", "Super Sprinkler" }
local WATERING_CAN_OPTIONS = { "Super Watering Can", "Common Watering Can" }
local GEAR_TYPE_OPTIONS = { "Sprinkler", "Trowel", "Shovel" }
local function cloneList(list)
    local out = {}
    for _, item in ipairs(list or {}) do table.insert(out, item) end
    return out
end

local function appendUnique(out, item, seen)
    if type(item) == "string" and item ~= "" and not seen[item] then
        seen[item] = true
        table.insert(out, item)
    end
end

local function getSeedOptions()
    local out, seen = {}, {}
    for _, name in ipairs(FALLBACK_SEED_OPTIONS) do appendUnique(out, name, seen) end
    table.sort(out)
    return out
end


local function getGearOptions()
    local out, seen = {}, {}
    for _, name in ipairs(FALLBACK_GEAR_OPTIONS) do appendUnique(out, name, seen) end
    table.sort(out)
    return out
end

local function getCrateOptions()
    local out, seen = {}, {}
    for _, name in ipairs(FALLBACK_CRATE_OPTIONS) do appendUnique(out, name, seen) end
    table.sort(out)
    return out
end

local function getPetOptions()
    local out, seen = {}, {}
    for _, name in ipairs(FALLBACK_PET_OPTIONS) do appendUnique(out, name, seen) end
    table.sort(out)
    return out
end

local function getOptionList(kind, includeSelect)
    local out
    if kind == "Seeds" then
        out = getSeedOptions()
    elseif kind == "Plants" then
        out = getSeedOptions()
        local seen = {}
        for _, name in ipairs(out) do seen[name] = true end
        for _, name in ipairs(EXTRA_PLANT_FILTER_OPTIONS) do appendUnique(out, name, seen) end
    elseif kind == "Rarities6" then
        out = cloneList(RARITY_NO_SUPER_OPTIONS)
    elseif kind == "PetSizes" then
        out = cloneList(PET_SIZE_OPTIONS)
    elseif kind == "SprinklerTiers" then
        out = cloneList(SPRINKLER_TIER_OPTIONS)
    elseif kind == "WateringCans" then
        out = cloneList(WATERING_CAN_OPTIONS)
    elseif kind == "GearTypes" then
        out = cloneList(GEAR_TYPE_OPTIONS)
    elseif kind == "Gear" then
        out = getGearOptions()
    elseif kind == "Crates" then
        out = getCrateOptions()
    elseif kind == "Pets" then
        out = getPetOptions()
    elseif kind == "Rarities" then
        out = cloneList(RARITY_OPTIONS)
    elseif kind == "CompareModes" then
        out = cloneList(COMPARE_MODE_OPTIONS)
    else
        out = {}
    end
    if includeSelect then table.insert(out, 1, "Select Options") end
    return out
end

local MUT_LIST = {"None"}
local SELL_VALUE = {}
local MUT_MULT = {}
local _FruitValueCalc = nil
do
    local rs = game:GetService("ReplicatedStorage"):WaitForChild("SharedModules")
    local mds = rs:FindFirstChild("MutationData")
    if mds then
        local names = {}
        for _, v in ipairs(mds:GetChildren()) do table.insert(names, v.Name) end
        table.sort(names)
        for _, n in ipairs(names) do table.insert(MUT_LIST, n) end
        local md = require(mds)
        for _, v in ipairs(mds:GetChildren()) do
            local m = md.GetMutation(v.Name)
            MUT_MULT[v.Name] = (m and m.PriceMultiplier) or 1
        end
    end
    local sv = rs:FindFirstChild("SellValueData")
    if sv then
        local svd = require(sv)
        for k, val in pairs(svd) do SELL_VALUE[k] = val end
    end
    local fvc = rs:FindFirstChild("FruitValueCalc")
    if fvc then _FruitValueCalc = require(fvc) end
end

local function fmtValue(v)
    if v >= 1e9 then return string.format("$%.1fB", v/1e9)
    elseif v >= 1e6 then return string.format("$%.1fM", v/1e6)
    elseif v >= 1e3 then return string.format("$%.1fK", v/1e3)
    else return "$"..tostring(v) end
end

local Cfg
local _lastStockUpdate = 0
local _cachedStockMultipliers = {}
local _stockUpdateActive = false

local function getStockMultiplier(seedName)
    local now = os.clock()
    if now - _lastStockUpdate > 10 and not _stockUpdateActive then
        _stockUpdateActive = true
        task.spawn(function()
            pcall(function()
                local stockData = Networking.FruitStock.Request:Fire()
                if type(stockData) == "table" and stockData.entries then
                    _cachedStockMultipliers = stockData.entries
                    _lastStockUpdate = os.clock()
                end
            end)
            _stockUpdateActive = false
        end)
    end
    if _cachedStockMultipliers[seedName] and type(_cachedStockMultipliers[seedName].multiplier) == "number" then
        return _cachedStockMultipliers[seedName].multiplier
    end
    return 1
end

local function calcFruitValue(seedName, sizeMulti, mutation, decay, ignoreStock)
    local multiplier = ignoreStock and 1 or getStockMultiplier(seedName)
    if _FruitValueCalc then
        return math.floor(_FruitValueCalc(seedName, sizeMulti or 1, mutation or "", LocalPlayer, decay or 0) * multiplier)
    end
    local base = SELL_VALUE[seedName] or 0
    local mult = (mutation and mutation ~= "" and MUT_MULT[mutation]) or 1
    return math.floor(base * ((sizeMulti or 1) ^ 3) * mult * multiplier)
end

local function getHttpRequest()
    return (syn and syn.request) or http_request or request or (http and http.request)
end

local function fetchFruitStockEntries()
    local ok, stockData = pcall(function()
        return Networking.FruitStock.Request:Fire()
    end)
    if ok and type(stockData) == "table" and type(stockData.entries) == "table" then
        _cachedStockMultipliers = stockData.entries
        _lastStockUpdate = os.clock()
        return stockData.entries
    end
    return _cachedStockMultipliers
end

local function buildFruitStockWebhookPayload(entries)
    local lines = {}
    local targets = { "Venom Spitter", "Moon Bloom", "Dragon's Breath" }
    for _, name in ipairs(targets) do
        local data = entries and entries[name]
        local mult = type(data) == "table" and tonumber(data.multiplier) or nil
        table.insert(lines, string.format("**%s** — %s", name, mult and string.format("x%.2f", mult) or "N/A"))
    end
    if #lines == 0 then table.insert(lines, "No target fruit stock data detected.") end
    local desc = table.concat(lines, "\n")
    if #desc > 3800 then desc = desc:sub(1, 3800) .. "\n..." end
    local alertLines = {}
    for _, name in ipairs(targets) do
        local data = entries and entries[name]
        local mult = type(data) == "table" and tonumber(data.multiplier) or nil
        if mult and mult >= 2 then
            table.insert(alertLines, string.format("%s x%.2f", name, mult))
        end
    end
    return {
        username = "GAG Fruit Stock",
        alertLines = alertLines,
        embeds = {{
            title = "🍎 Fruit Stock Price",
            description = desc,
            color = 3447003,
            footer = { text = "Client: " .. tostring(Player.Name) .. " | Updates on 10-minute restock" },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        }}
    }
end

_G._sendApsWebhook = function(status, data)
    if tostring(status) ~= "success" then
        if _G._traceAPS then _G._traceAPS("webhook_skip", "non_success status=" .. tostring(status)) end
        return false
    end
    if not Cfg then
        if _G._traceAPS then _G._traceAPS("webhook_skip", "no_cfg status=" .. tostring(status)) end
        return false
    end
    local url = tostring(Cfg.apsWebhookUrl or "")
    local validUrl = url ~= "" and url:find("discord.com/api/webhooks", 1, true)
    if not Cfg.apsWebhook and not validUrl then
        if _G._traceAPS then _G._traceAPS("webhook_skip", "disabled status=" .. tostring(status) .. " enabled=" .. tostring(Cfg and Cfg.apsWebhook)) end
        return false
    end
    if not validUrl then
        if _G._traceAPS then _G._traceAPS("webhook_skip", "bad_url len=" .. tostring(#url) .. " status=" .. tostring(status)) end
        return false
    end
    local req = getHttpRequest()
    if type(req) ~= "function" then
        if _G._traceAPS then _G._traceAPS("webhook_skip", "no_request status=" .. tostring(status)) end
        return false
    end
    data = type(data) == "table" and data or {}
    local kg = tonumber(data.kg)
    local threshold = tonumber(Cfg.apsWeightThresh) or 0
    local mode = tostring(Cfg.apsThreshMode or "Above")
    local color = 5763719
    local title = "Auto-Plant — Target Hit"
    local statusText = "Target reached"
    local desc = table.concat({
        "**Target Status** " .. statusText,
        "**Weight** `" .. (kg and string.format("%.2f kg", kg) or "N/A") .. "`",
        "**Target** `" .. mode .. " " .. string.format("%.2f", threshold) .. " kg`",
        "**Focus** `" .. tostring(Cfg.apsSeedName or "?") .. "`",
        "**Scanning** `" .. tostring(data.cropName or Cfg.apsCropName or "?") .. "`",
        "**Username** `" .. tostring(Player.Name) .. "`",
        "**Action Status** `Success — stopped`",
    }, "\n")
    local payload = {
        username = "GAG Auto Plant Scan",
        content = "@everyone",
        allowed_mentions = { parse = { "everyone" } },
        embeds = {{
            title = title,
            description = desc,
            color = color,
            footer = { text = "Client: " .. tostring(Player.Name) },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        }}
    }
    local body = HttpService:JSONEncode(payload)
    local ok, response = pcall(function()
        return req({ Url = url, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = body })
    end)
    local code = type(response) == "table" and (response.StatusCode or response.Status or response.status_code) or "nil"
    if _G._traceAPS then _G._traceAPS("webhook_send", "status=" .. tostring(status) .. " ok=" .. tostring(ok) .. " code=" .. tostring(code) .. " kg=" .. tostring(kg)) end
    return ok
end

local function sendFruitStockWebhook(reason)
    local url = tostring(Cfg.fruitStockWebhookUrl or "")
    if url == "" or not url:find("discord.com/api/webhooks", 1, true) then return false end
    local req = getHttpRequest()
    if type(req) ~= "function" then return false end
    local payload = buildFruitStockWebhookPayload(fetchFruitStockEntries())
    local alertLines = payload.alertLines
    payload.alertLines = nil
    payload.embeds[1].title = payload.embeds[1].title .. (reason and (" — " .. reason) or "")
    local body = HttpService:JSONEncode(payload)
    local messageId = tostring(Cfg.fruitStockWebhookMessageId or "")
    local ok, response = pcall(function()
        if messageId ~= "" then
            return req({
                Url = url .. "/messages/" .. messageId,
                Method = "PATCH",
                Headers = { ["Content-Type"] = "application/json" },
                Body = body,
            })
        end
        return req({
            Url = url .. "?wait=true",
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = body,
        })
    end)
    local status = type(response) == "table" and tonumber(response.StatusCode or response.Status or response.status_code) or nil
    if ok and messageId ~= "" and status and status >= 200 and status < 300 then
        if alertLines and #alertLines > 0 then
            local oldAlertId = tostring(Cfg.fruitStockWebhookAlertId or "")
            if oldAlertId ~= "" then
                pcall(function()
                    req({ Url = url .. "/messages/" .. oldAlertId, Method = "DELETE" })
                end)
                Cfg.fruitStockWebhookAlertId = ""
            end
            local alertPayload = {
                content = "@everyone Fruit stock above x2: " .. table.concat(alertLines, ", "),
                allowed_mentions = { parse = { "everyone" } },
            }
            local okAlert, alertResp = pcall(function()
                return req({
                    Url = url .. "?wait=true",
                    Method = "POST",
                    Headers = { ["Content-Type"] = "application/json" },
                    Body = HttpService:JSONEncode(alertPayload),
                })
            end)
            local rawAlert = type(alertResp) == "table" and (alertResp.Body or alertResp.body) or nil
            if okAlert and type(rawAlert) == "string" and rawAlert ~= "" then
                local okDecode, decoded = pcall(function() return HttpService:JSONDecode(rawAlert) end)
                if okDecode and type(decoded) == "table" and decoded.id then
                    Cfg.fruitStockWebhookAlertId = tostring(decoded.id)
                end
            end
        end
        return true
    end
    if ok and messageId == "" then
        local raw = type(response) == "table" and (response.Body or response.body) or nil
        if type(raw) == "string" and raw ~= "" then
            local okDecode, decoded = pcall(function() return HttpService:JSONDecode(raw) end)
            if okDecode and type(decoded) == "table" and decoded.id then
                Cfg.fruitStockWebhookMessageId = tostring(decoded.id)
            end
        end
        return true
    end
    if messageId ~= "" then
        Cfg.fruitStockWebhookMessageId = ""
        return sendFruitStockWebhook(reason)
    end
    if ok and alertLines and #alertLines > 0 then
        local oldAlertId = tostring(Cfg.fruitStockWebhookAlertId or "")
        if oldAlertId ~= "" then
            pcall(function()
                req({ Url = url .. "/messages/" .. oldAlertId, Method = "DELETE" })
            end)
            Cfg.fruitStockWebhookAlertId = ""
        end
        local alertPayload = {
            content = "@everyone Fruit stock above x2: " .. table.concat(alertLines, ", "),
            allowed_mentions = { parse = { "everyone" } },
        }
        local okAlert, alertResp = pcall(function()
            return req({
                Url = url .. "?wait=true",
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = HttpService:JSONEncode(alertPayload),
            })
        end)
        local rawAlert = type(alertResp) == "table" and (alertResp.Body or alertResp.body) or nil
        if okAlert and type(rawAlert) == "string" and rawAlert ~= "" then
            local okDecode, decoded = pcall(function() return HttpService:JSONDecode(rawAlert) end)
            if okDecode and type(decoded) == "table" and decoded.id then
                Cfg.fruitStockWebhookAlertId = tostring(decoded.id)
            end
        end
    end
    return ok
end

local _fruitStockWebhookLoopStarted = false
local function startFruitStockWebhookLoop()
    if _fruitStockWebhookLoopStarted then return end
    _fruitStockWebhookLoopStarted = true
    task.spawn(function()
        local sentInitial = false
        local lastBucket = math.floor(os.time() / 600)
        local pendingBucket = nil
        while not Speed_Library.Unloaded do
            if Cfg and Cfg.fruitStockWebhook then
                if not sentInitial then
                    sendFruitStockWebhook("Current")
                    sentInitial = true
                    lastBucket = math.floor(os.time() / 600)
                end
                local bucket = math.floor(os.time() / 600)
                if bucket ~= lastBucket and pendingBucket ~= bucket then
                    pendingBucket = bucket
                    task.spawn(function()
                        task.wait(5)
                        if Cfg and Cfg.fruitStockWebhook and not Speed_Library.Unloaded and pendingBucket == bucket then
                            sendFruitStockWebhook("Restock")
                            lastBucket = bucket
                            pendingBucket = nil
                        end
                    end)
                end
                task.wait(1)
            else
                sentInitial = false
                pendingBucket = nil
                lastBucket = math.floor(os.time() / 600)
                task.wait(1)
            end
        end
    end)
end

local function msEmpty(t) return not t or #t == 0 end
local function msMatch(t, val)
    if msEmpty(t) then return true end
    return table.find(t, val) ~= nil
end
local function msMutMatch(t, mut)
    if msEmpty(t) then return true end
    mut = tostring(mut or "")
    if table.find(t, "None") and mut == "" then return true end
    if mut == "" then return false end

    local tokens = {}
    for token in mut:gmatch("[^,]+") do
        token = token:gsub("^%s+", ""):gsub("%s+$", "")
        if token ~= "" then tokens[token] = true end
    end
    if next(tokens) == nil then tokens[mut] = true end

    for _, m in ipairs(t) do
        if m ~= "None" then
            if tokens[m] or mut == m then return true end
        end
    end
    return false
end

local State = { harvested = 0 }
Cfg = {
    autoHarvest      = false,
    autoCollectFruit = false,
    autoCollectAll   = false,
    autoCollectBest  = false,
    autoDropped      = false,
    autoGoldSeed     = false,
    autoRainbowSeed  = false,
    autoAttack       = false,
    disableTp        = false,
    playerFreeze     = false,
    stopIfFull       = false,
    delay            = 0,
    collectBestMinValue = 0,
    selWaitMutationFruit = {},
    waitMutationAboveKg = 0,
    selFruit         = {},
    selRarity        = {},
    selMut           = {},
    threshMode       = "",
    weightThresh     = 0,
    noneThreshMode   = "",
    noneWeightThresh = 0,
    mutThreshMode    = "",
    mutWeightThresh  = 0,
    lowKgMut         = {},
    lowKgMode        = "Below",
    lowKgThresh      = 40,
    highKgMut        = {},
    highKgMode       = "Above",
    highKgThresh     = 0,
    autoPlantSeed    = false,
    autoPlantAll     = false,
    plantSeedName    = "Select Options",
    plantDelay       = 0.1,
    disablePlantTp   = false,
    plantPosition    = "Player Position",
    plantSprinkler   = "Select Options",
    plantRequireSprinkler = false,
    savedPlantPos    = nil,
    autoPlantScan    = false,
    apsSeedName      = "Carrot",
    apsCropName      = "Carrot",
    apsSprinkler     = "Super Sprinkler",
    apsWeightThresh  = 30,
    apsThreshMode    = "Above",
    apsPlantAmount   = 24,
    apsPlantDelay    = 0.05,
    apsScanWindow    = 0.75,
    apsRejoinDelay   = 10,
    apsWebhook       = false,
    apsWebhookUrl    = "",
    apsResume        = false,
    autoSellAll      = false,
    autoSellFruit    = false,
    autoSellPets     = false,
    sellDelay        = 1,
    sellIfFull       = false,
    sellBargain      = false,
    sellDailyDeal    = false,
    selSellFruit     = {},
    selSellRarity    = {},
    selSellMut       = {},
    selSellThresh    = "",
    sellWeightThresh = 0,
    sellValueBelow   = 0,
    selSellPet       = {},
    selSellPetRarity = {},
    selSellPetSize   = {},
    autoBuySeed      = false,
    autoBuyAllSeeds  = false,
    selBuySeed       = {},
    autoBuyGear      = false,
    autoBuyAllGear   = false,
    selBuyGear       = {},
    autoBuyCrate     = false,
    autoBuyAllCrates = false,
    selBuyCrate      = {},
    buyShopDelay     = 5,
    antiFling        = false,
    lessKnockback    = false,
    instantPrompt    = false,
    bypassPaused     = false,
    noclipPlants     = false,
    hideFruits       = false,
    hidePlants       = false,
    selHidePlants    = {},
    disableHarvestPrompt = false,
    removeOtherGardens     = false,
    autoRemoveOtherGardens = false,
    reduceLag        = false,
    screenWhite      = false,
    screenBlack      = false,
    hopJobId         = "",
    hopPlaceVer      = "",
    autoHopUntilVer  = false,
    espFruit         = false,
    espPet           = false,
    selEspFruit      = {},
    selEspRarity     = {},
    selEspMut        = {},
    espKgMode        = "",
    espKgThresh      = 0,
    selEspPet        = {},
    selEspPetRarity  = {},
    selEspPetSize    = {},
    autoSteal        = false,
    autoStealBest    = false,
    flingPlayers     = false,
    autoHitStolen    = false,
    stealDelay       = 1,
    selStealFilter   = "Select Options",
    selStealFruit    = {},
    selStealRarity   = {},
    selStealMut      = {},

    propSteal        = false,
    dropDupe         = false,
    dropDupeCount    = 5,
    dropDupeSeed     = "Select Options",
    autoMailClaim    = false,
    autoWeatherDisconnect = false,
    selDisconnectWeather = {},
    weatherReconnectMinutes = 3,
    seedPackSpam     = false,
    pryDoors         = false,
    autoBuyPet       = false,
    buyPetDelay      = 2,
    selBuyPet        = {},
    selBuyPetRarity  = {},
    selBuyPetSize    = {},
    autoMailSend     = false,
    mailTarget       = "",
    mailTargetId     = 0,
    mailCategory     = "Seeds",
    mailItemKey      = "Select Options",
    mailCount        = 5,
    mailDelay        = 10,
    mailSendMode     = "Direct Total",
    mailBatchSize    = 20,
    mailFruitValueTarget = "",
    mailFruitMinValue = "0",
    mailFruitMaxValue = "999q",
    autoSprinkler      = false,
    autoSprinklerAll   = false,
    sprinklerDelay     = 1,
    selSprinkler       = {},
    sprinklerPlaceMode = "Player Position",
    selSprinklerPlant  = {},
    sprinklerSpacing   = 4,
    sprinklerTimerGui  = false,
    autoTpToSprinkler  = true,
    sprinklerSavedPosition = nil,
    autoWaterCan       = false,
    selWaterCan        = {},
    waterCanDelay      = 30,
    waterCanUses       = 1,
    autoTrowel         = false,
    trowelDelay        = 2,
    selTrowelPlant     = {},
    selTrowelPos       = "Player Position",
    autoShovelTree     = false,
    autoShovelFruit    = false,
    shovelTreeDelay    = 2,
    shovelFruitDelay   = 2,
    selShovelTree      = {},
    selShovelTreeRarity= {},
    selShovelTreeMut   = {},
    selShovelFruit     = {},
    selShovelFruitRarity={},
    selShovelFruitMut  = {},
    selShovelThreshMode= "",
    shovelWeightThresh = 0,
    stackFarm          = false,
    sfPriority         = {},
    autoFavFruit     = false,
    autoUnFavFruit   = false,
    autoUnFavAll     = false,
    selFavFruit      = {},
    selFavRarity     = {},
    selFavMut        = {},
    selFavThresh     = "",
    favWeightThresh  = 0,
    favDelay         = 1,
    debugCollect     = false,
    debugShop        = false,
    debugSprinkler   = false,
    autoFriendAddAll = false,
    autoFriendAccept = false,
    fruitStockWebhook = false,
    fruitStockWebhookUrl = "",
    fruitStockWebhookMessageId = "",
    fruitStockWebhookAlertId = "",
}

local DISPLAY_KG_BASE = {
    ["Venom Spitter"] = 9,
}

local CONFIG_PREFIX = "gag2_config_"
local mappedName = ACCOUNT_CONFIG_MAPPING[Player.Name]
local NORMAL_CONFIG_FILE = mappedName or (tostring(Player.Name) .. ".json")
local CONFIG_FILE = NORMAL_CONFIG_FILE
local LEGACY_CONFIG_FILE = CONFIG_PREFIX .. tostring(Player.UserId) .. ".json"
local LEGACY_NAME_CONFIG_FILE = CONFIG_PREFIX .. tostring(Player.Name) .. ".json"
local cfgReadyToSave = false
local cfgSaveQueued = false

local function copyTable(t)
    local out = {}
    if type(t) == "table" then
        for k, v in pairs(t) do out[k] = v end
    end
    return out
end
local DEFAULT_CFG = copyTable(Cfg)
local CfgData = Cfg

local function dlog(channel, ...)
    local flag = channel == "COLLECT" and CfgData.debugCollect
        or channel == "SHOP" and CfgData.debugShop
        or channel == "SPRINKLER" and CfgData.debugSprinkler
    if flag then
        print("[GAG2:" .. tostring(channel) .. "]", ...)
    end
end

local APS_DEBUG_FILE = "gag2_aps_debug_" .. tostring(Player.Name) .. ".log"
local function traceAPS(source, extra)
    local p = CfgData and CfgData.sprinklerSavedPosition
    local posKind = type(p) == "table" and (type(p.localPos) == "table" and "localPos" or type(p.rel) == "table" and "rel" or (p.x and "xyz" or "table")) or tostring(p)
    local line = ("[%s] %s | file=%s ready=%s auto=%s resume=%s pos=%s extra=%s\n"):format(
        os.date("%H:%M:%S"),
        tostring(source),
        tostring(CONFIG_FILE),
        tostring(cfgReadyToSave),
        tostring(CfgData and CfgData.autoPlantScan),
        tostring(CfgData and CfgData.apsResume),
        tostring(posKind),
        tostring(extra or "")
    )
    print("[GAG2_APS_TRACE] " .. line)
    if type(appendfile) == "function" then
        pcall(appendfile, APS_DEBUG_FILE, line)
    elseif type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function" then
        local old = ""
        if isfile(APS_DEBUG_FILE) then pcall(function() old = readfile(APS_DEBUG_FILE) or "" end) end
        pcall(writefile, APS_DEBUG_FILE, old .. line)
    end
end
_G._traceAPS = traceAPS

function saveConfigNow()
    if type(writefile) ~= "function" then traceAPS("save_no_writefile") return end
    local okEncode, encoded = pcall(function() return HttpService:JSONEncode(CfgData) end)
    local okWrite = false
    if okEncode and encoded then okWrite = pcall(writefile, CONFIG_FILE, encoded) end
    if CfgData and (CfgData.autoPlantScan or CfgData.apsResume) then
        traceAPS("saveConfigNow", "okEncode=" .. tostring(okEncode) .. " okWrite=" .. tostring(okWrite))
    end
end

local function loadConfigFile(fileName, saveAfterLoad)
    if type(readfile) ~= "function" or type(isfile) ~= "function" or type(fileName) ~= "string" or not isfile(fileName) then return false end
    local okRead, raw = pcall(readfile, fileName)
    if not okRead or type(raw) ~= "string" or raw == "" then return false end
    local okDecode, saved = pcall(function() return HttpService:JSONDecode(raw) end)
    if not okDecode or type(saved) ~= "table" then return false end
    for k, v in pairs(saved) do
        -- Lua tables cannot retain nil defaults, so keys whose default is nil
        -- (notably saved positions) must be explicitly allowed here.
        if CfgData[k] ~= nil or k == "sprinklerSavedPosition" or k == "savedPlantPos" then
            CfgData[k] = v
        end
    end
    traceAPS("loadConfigFile", "file=" .. tostring(fileName) .. " saveAfterLoad=" .. tostring(saveAfterLoad) .. " savedAuto=" .. tostring(saved.autoPlantScan) .. " savedResume=" .. tostring(saved.apsResume))
    if saveAfterLoad then saveConfigNow() end
    return true
end

local function cleanSelectionTable(value, validSet)
    local out, seen = {}, {}
    if type(value) == "string" then
        if value ~= "" and value ~= "Select Options" then value = { value } else value = {} end
    end
    if type(value) == "table" then
        for _, item in ipairs(value) do
            if type(item) == "string" and item ~= "" and item ~= "Select Options" and not seen[item] then
                if not validSet or validSet[item] then
                    seen[item] = true
                    table.insert(out, item)
                end
            end
        end
    end
    return out
end

local function validSetFrom(list)
    local set = {}
    if type(list) == "table" then
        for _, v in ipairs(list) do set[v] = true end
    end
    return set
end

local function validMode(value, fallback)
    if value == "Above" or value == "Below" then return value end
    return fallback
end

local function safeNumber(value, fallback, minValue, maxValue)
    local n = tonumber(value)
    if not n then n = fallback end
    if minValue then n = math.max(n, minValue) end
    if maxValue then n = math.min(n, maxValue) end
    return n
end

local function migrateConfig()
    local seedSet = validSetFrom(getOptionList("Plants"))
    local gearSet = validSetFrom(getOptionList("Gear"))
    local crateSet = validSetFrom(getOptionList("Crates"))
    CfgData.selBuySeed = cleanSelectionTable(CfgData.selBuySeed, seedSet)
    CfgData.selBuyGear = cleanSelectionTable(CfgData.selBuyGear, gearSet)
    CfgData.selBuyCrate = cleanSelectionTable(CfgData.selBuyCrate, crateSet)
    CfgData.lowKgMut = cleanSelectionTable(CfgData.lowKgMut)
    CfgData.highKgMut = cleanSelectionTable(CfgData.highKgMut)
    CfgData.lowKgMode = validMode(CfgData.lowKgMode, "Below")
    CfgData.highKgMode = validMode(CfgData.highKgMode, "Above")
    CfgData.sellWeightThresh = safeNumber(CfgData.sellWeightThresh, 0, 0, nil)
    CfgData.sellValueBelow = safeNumber(CfgData.sellValueBelow, 0, 0, nil)
    CfgData.lowKgThresh = safeNumber(CfgData.lowKgThresh, 40, 0, nil)
    CfgData.highKgThresh = safeNumber(CfgData.highKgThresh, 0, 0, nil)
    CfgData.buyShopDelay = safeNumber(CfgData.buyShopDelay, 5, 1, nil)
    CfgData.sprinklerDelay = safeNumber(CfgData.sprinklerDelay, 1, 0.1, nil)
    CfgData.waterCanDelay = safeNumber(CfgData.waterCanDelay, 30, 5, nil)
    CfgData.waterCanUses = safeNumber(CfgData.waterCanUses, 1, 1, 20)
    if CfgData.mailCategory == "HarvestedFruits" then
        CfgData.mailCategory = "Fruits"
    elseif CfgData.mailCategory ~= "Seeds" and CfgData.mailCategory ~= "Pets" and CfgData.mailCategory ~= "Fruits" then
        CfgData.mailCategory = "Gear"
    end
    if CfgData.apsResume then
        CfgData.autoPlantScan = true
    end
    traceAPS("migrateConfig_done")
end

local function applySavedConfig()
    if not loadConfigFile(CONFIG_FILE, false) then
        if not loadConfigFile(LEGACY_NAME_CONFIG_FILE, true) then
            loadConfigFile(LEGACY_CONFIG_FILE, true)
        end
    end
    migrateConfig()
end

local function listConfigFiles()
    local files = {}
    local seen = {}
    local function add(name)
        if name == LEGACY_NAME_CONFIG_FILE then return end
        if type(name) ~= "string" or seen[name] then return end
        local isConfig = name == CONFIG_FILE
            or name == "gag2_config.json"
            or name:match("^" .. CONFIG_PREFIX .. ".+%.json$")
            or (name:match("^%w+%.json$") and name ~= "package.json" and name ~= "tsconfig.json" and name ~= "bun.lock")
        if isConfig then
            seen[name] = true
            table.insert(files, name)
        end
    end
    add(CONFIG_FILE)
    add(LEGACY_NAME_CONFIG_FILE)
    add(LEGACY_CONFIG_FILE)
    add("gag2_config.json")
    if type(listfiles) == "function" then
        local ok, listed = pcall(listfiles, "")
        if ok and type(listed) == "table" then
            for _, path in ipairs(listed) do
                local name = tostring(path):match("([^/\\]+)$") or tostring(path)
                add(name)
            end
        end
    end
    table.sort(files)
    return files
end

local function scheduleCfgSave()
    if not cfgReadyToSave or cfgSaveQueued then return end
    cfgSaveQueued = true
    task.delay(0.35, function()
        cfgSaveQueued = false
        saveConfigNow()
    end)
end

local function setCfg(key, value)
    CfgData[key] = value
    scheduleCfgSave()
end

local function savedDropdown(key)
    local v = CfgData[key]
    if type(v) == "table" then return v end
    if v == nil or v == "" or v == "Select Options" then return {} end
    return { v }
end

local function resetCfgToDefaults()
    for k, v in pairs(DEFAULT_CFG) do
        CfgData[k] = type(v) == "table" and copyTable(v) or v
    end
    saveConfigNow()
end

applySavedConfig()
CfgData.autoPlantSeed = false

Cfg = setmetatable({}, {
    __index = CfgData,
    __newindex = function(_, key, value)
        CfgData[key] = value
        scheduleCfgSave()
    end,
    __pairs = function()
        return pairs(CfgData)
    end,
})

local StarterGui = game:GetService("StarterGui")
local _friendAddTried = {}
local function tryAutoAddFriend(plr)
    if not Cfg.autoFriendAddAll or not plr or plr == Player then return end
    if _friendAddTried[plr.UserId] then return end
    _friendAddTried[plr.UserId] = true
    task.spawn(function()
        task.wait(1)
        pcall(function()
            if Player:IsFriendsWith(plr.UserId) then return end
            if type(Player.RequestFriendship) == "function" then
                Player:RequestFriendship(plr)
            else
                StarterGui:SetCore("PromptSendFriendRequest", plr)
            end
        end)
    end)
end

local function tryAutoAcceptFriend(plr)
    if not Cfg.autoFriendAccept or not plr or plr == Player then return end
    task.spawn(function()
        pcall(function()
            if type(Player.AcceptFriendship) == "function" then
                Player:AcceptFriendship(plr)
            else
                StarterGui:SetCore("PromptFriendRequest", plr)
            end
        end)
    end)
end

task.spawn(function()
    for _, plr in ipairs(Players:GetPlayers()) do tryAutoAddFriend(plr) end
    Players.PlayerAdded:Connect(function(plr)
        task.wait(1)
        tryAutoAddFriend(plr)
    end)
    pcall(function()
        Player.FriendRequestEvent:Connect(function(plr)
            tryAutoAcceptFriend(plr)
        end)
    end)
    while not Speed_Library.Unloaded do
        if Cfg.autoFriendAddAll then
            for _, plr in ipairs(Players:GetPlayers()) do tryAutoAddFriend(plr) end
        end
        task.wait(10)
    end
end)

local statusSep = nil
local function setStatus(t) if statusSep then statusSep:Set({ Title = "Status: "..t }) end end
local function getHRP() local c = LocalPlayer.Character; return c and c:FindFirstChild("HumanoidRootPart") end

local function sendReversePacket()
    traceAPS("reverse_fire_start")
    local ok, err = pcall(function()
        local Event = game:GetService("ReplicatedStorage").SharedModules.Packet.RemoteEvent
        for i = 1, 3 do
            Event:FireServer(54, ":\xF7")
            task.wait(0.08)
        end
    end)
    traceAPS("reverse_fire_done", "ok=" .. tostring(ok) .. " err=" .. tostring(err))
    return ok
end

local function sendCancelReversePacket()
    traceAPS("reverse_cancel_start")
    local ok, err = pcall(function()
        local Event = game:GetService("ReplicatedStorage").SharedModules.Packet.RemoteEvent
        for i = 1, 2 do
            Event:FireServer(54, "")
            task.wait(0.05)
            Event:FireServer(54, " ")
            task.wait(0.05)
            Event:FireServer(54, nil)
            task.wait(0.05)
        end
    end)
    traceAPS("reverse_cancel_done", "ok=" .. tostring(ok) .. " err=" .. tostring(err))
    return ok
end

-- Saved sprinkler position is manual-only. It is used as a Place Location target
-- and never teleports the character on execute/rejoin.

local Gardens = (workspace :: any).Gardens
local function getMyPlot()
    local uid = LocalPlayer.UserId
    for _, plot in pairs(Gardens:GetChildren()) do
        if plot:GetAttribute("OwnerUserId") == uid then return plot end
    end
    return nil
end

local function waitForMyPlot(timeout)
    local deadline = os.clock() + (tonumber(timeout) or 8)
    local plot = getMyPlot()
    while not plot and os.clock() < deadline do
        task.wait(0.1)
        plot = getMyPlot()
    end
    return plot
end

local function suppressFruitVFXPart(obj)
    if not (obj and obj:IsA("BasePart")) then return end
    if not obj:FindFirstAncestor("Fruits") then return end
    if obj.Name == "HarvestPart" then
        obj.Transparency = 1
        obj.CanCollide = false
    elseif obj.Name == "BloodlitVFX" or obj.Name:match("VFX$") then
        obj.Transparency = 1
        obj.CanCollide = false
        obj.CanQuery = false
        obj.CanTouch = false
    end
end

local _lastVFXSuppressPlot = nil
local function suppressPlotFruitVFX(plot)
    if not plot then return end
    for _, obj in pairs(plot:GetDescendants()) do
        suppressFruitVFXPart(obj)
    end
end

task.spawn(function()
    while not Speed_Library.Unloaded do
        local plot = getMyPlot()
        if plot and plot ~= _lastVFXSuppressPlot then
            _lastVFXSuppressPlot = plot
            suppressPlotFruitVFX(plot)
        end
        task.wait(30)
        if plot and plot.Parent then
            suppressPlotFruitVFX(plot)
        end
    end
end)

Gardens.DescendantAdded:Connect(function(obj)
    task.defer(function()
        suppressFruitVFXPart(obj)
    end)
end)
local lastPlotTp = 0

local function getGardenZonePart(plot)
    local visual = plot and plot:FindFirstChild("Visual")
    if not visual then return nil end
    return visual:FindFirstChild("GardenZonePart")
        or visual:FindFirstChild("GardenTotalArea")
        or plot:FindFirstChild("PlotSizeReference")
end

local function isInsideGarden(plot, pos)
    if not plot or not pos then return false end
    local zone = getGardenZonePart(plot)
    if zone and zone:IsA("BasePart") then
        local localPos = zone.CFrame:PointToObjectSpace(pos)
        local halfX = zone.Size.X / 2 + 5
        local halfZ = zone.Size.Z / 2 + 5
        return math.abs(localPos.X) <= halfX and math.abs(localPos.Z) <= halfZ
    end
    local pivot = plot:GetPivot().Position
    return (Vector3.new(pos.X, 0, pos.Z) - Vector3.new(pivot.X, 0, pivot.Z)).Magnitude <= 85
end

local function doTp(plot)
    if Cfg.disableTp then return end
    local hrp = getHRP()
    if not hrp or not plot then return end

    if isInsideGarden(plot, hrp.Position) then return end
    if os.clock() - lastPlotTp < 5 then return end

    local targetPos = plot:GetPivot().Position + Vector3.new(0, 5, 0)
    lastPlotTp = os.clock()
    hrp.CFrame = CFrame.new(targetPos)
    task.wait(0.2)
end
local function isFullCheck()
    if not Cfg.stopIfFull then return false end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    return bp and #bp:GetChildren() >= 50
end
local function passWeightFilter(mode, threshold, weight)
    if (mode or "") == "" then return true end
    threshold = tonumber(threshold) or 0
    weight = tonumber(weight)
    if not weight then return false end
    if mode == "Above" then return weight >= threshold end
    if mode == "Below" then return weight <= threshold end
    return true
end

local function isFruitReady(fruit)
    if not fruit then return false, nil, nil end
    local age = tonumber(fruit:GetAttribute("Age"))
    local maxAge = tonumber(fruit:GetAttribute("MaxAge"))
    if not age or not maxAge then return false, age, maxAge end
    return age >= maxAge, age, maxAge
end

local _fruitWeightController = nil
local _gardenSyncController = nil
local function getSyncedPlantKg(plant)
    if not plant then return nil end
    if _gardenSyncController == false then return nil end
    if not _gardenSyncController then
        local ok, controller = pcall(function()
            local ps = LocalPlayer:FindFirstChild("PlayerScripts")
            local controllers = ps and ps:FindFirstChild("Controllers")
            local mod = controllers and controllers:FindFirstChild("GardenSyncController")
            return mod and require(mod)
        end)
        _gardenSyncController = (ok and controller) or false
    end
    if type(_gardenSyncController) ~= "table" or type(_gardenSyncController.GetGarden) ~= "function" then return nil end

    local plantId = plant:GetAttribute("PlantId")
    if not plantId then return nil end

    local ok, garden = pcall(function()
        return _gardenSyncController:GetGarden(LocalPlayer.UserId)
    end)
    if not ok or type(garden) ~= "table" then return nil end

    local data = garden[plantId]
    if type(data) ~= "table" then return nil end

    local kg = tonumber(data.Weight) or tonumber(data.SizeMultiplier)
    return kg
end

local function getGameFruitKg(fruit)
    if not fruit then return nil end
    if _fruitWeightController == false then return nil end
    if not _fruitWeightController then
        local ok, controller = pcall(function()
            local ps = LocalPlayer:FindFirstChild("PlayerScripts")
            local controllers = ps and ps:FindFirstChild("Controllers")
            local mod = controllers and controllers:FindFirstChild("FruitVisualizerController")
            return mod and require(mod)
        end)
        _fruitWeightController = (ok and controller) or false
    end
    if type(_fruitWeightController) == "table" and type(_fruitWeightController.CalculateFruitWeight) == "function" then
        local ok, kg = pcall(function()
            return _fruitWeightController:CalculateFruitWeight(fruit)
        end)
        if ok then
            kg = tonumber(kg)
            if kg then return kg end
        end
    end
    return nil
end

local function getFruitDisplayKg(fruit, seedName)
    local gameKg = getGameFruitKg(fruit)
    if gameKg then return gameKg end

    local sizeMulti = tonumber(fruit and (fruit:GetAttribute("SizeMulti") or fruit:GetAttribute("SizeMultiplier")))
    if not sizeMulti and fruit and fruit:GetAttribute("PlantId") and not fruit:GetAttribute("FruitId") then
        sizeMulti = getSyncedPlantKg(fruit)
        if sizeMulti then return sizeMulti end
    end
    local baseName = (type(seedName) == "string" and seedName ~= "" and seedName) or (fruit and fruit:GetAttribute("CorePartName")) or ""
    local base = DISPLAY_KG_BASE[baseName]
    if sizeMulti and base then return sizeMulti * base end

    if fruit then
        for _, d in ipairs(fruit:GetDescendants()) do
            if (d:IsA("TextLabel") or d:IsA("TextButton")) and type(d.Text) == "string" then
                local kgText = d.Text:match("([%d%.]+)%s*[kK][gG]")
                local kg = tonumber(kgText)
                if kg then return kg end
            end
        end
    end
    return nil
end

local _lastUiMutCheck = 0
local _lastUiMutHasNone = false
local function uiAutoCollectMutationHas(optionName)
    if optionName ~= "None" then return false end
    local now = os.clock()
    if now - _lastUiMutCheck < 0.5 then return _lastUiMutHasNone end
    _lastUiMutCheck = now
    _lastUiMutHasNone = false
    local roots = {}
    pcall(function() table.insert(roots, game:GetService("CoreGui")) end)
    pcall(function() table.insert(roots, LocalPlayer:FindFirstChild("PlayerGui")) end)
    if type(gethui) == "function" then pcall(function() table.insert(roots, gethui()) end) end
    for _, root in ipairs(roots) do
        if root then
            for _, d in ipairs(root:GetDescendants()) do
                if (d:IsA("TextLabel") or d:IsA("TextButton")) and type(d.Text) == "string" then
                    local txt = d.Text
                    if txt:find("Aurora", 1, true) and txt:find("Starstruck", 1, true) and txt:find("None", 1, true) then
                        _lastUiMutHasNone = true
                        if type(CfgData.selMut) == "table" and not table.find(CfgData.selMut, "None") then
                            table.insert(CfgData.selMut, "None")
                            scheduleCfgSave()
                        end
                        return true
                    end
                end
            end
        end
    end
    return false
end

local function shouldWaitMutation(plant, fruit)
    local seedName = plant and (plant:GetAttribute("SeedName") or "") or ""
    local aboveKg = tonumber(Cfg.waitMutationAboveKg) or 0
    if aboveKg <= 0 then return false end
    if not msMatch(Cfg.selWaitMutationFruit, seedName) then return false end
    local mut = tostring(fruit:GetAttribute("Mutation") or "")
    if mut ~= "" then return false end
    local w = getFruitDisplayKg(fruit, seedName)
    return w ~= nil and w >= aboveKg
end

local function hasFruitCollectFilter()
    return not msEmpty(Cfg.selFruit)
        or not msEmpty(Cfg.selRarity)
        or not msEmpty(Cfg.lowKgMut)
        or not msEmpty(Cfg.highKgMut)
        or not msEmpty(Cfg.selMut)
        or Cfg.noneThreshMode ~= ""
        or Cfg.mutThreshMode ~= ""
end

local function passFruitFilter(plant, fruit)
    local hasAnyFilter = hasFruitCollectFilter()
    if not hasAnyFilter then return false end

    local seedName = plant:GetAttribute("SeedName") or ""
    if plant == fruit then
        local mut = tostring(plant:GetAttribute("Mutation") or "")
        local mutKey = mut == "" and "None" or mut
        local w = getFruitDisplayKg(plant, seedName)
        local dnc = Cfg.doNotCollectRules
        local keepAbove = type(dnc) == "table" and tonumber(dnc[seedName]) or nil
        if keepAbove and w and w >= keepAbove then return false end
        if not msEmpty(Cfg.selFruit) and not msMatch(Cfg.selFruit, seedName) then return false end
        if not msEmpty(Cfg.selRarity) and not msMatch(Cfg.selRarity, SEED_RARITY[seedName] or "Common") then return false end
        if table.find(Cfg.lowKgMut, mutKey) then return passWeightFilter(Cfg.lowKgMode, Cfg.lowKgThresh, w) end
        if table.find(Cfg.highKgMut, mutKey) then return passWeightFilter(Cfg.highKgMode, Cfg.highKgThresh, w) end
        if mut == "" then
            local noneSelected = table.find(Cfg.selMut, "None") ~= nil or uiAutoCollectMutationHas("None")
            if noneSelected then return passWeightFilter(Cfg.noneThreshMode, Cfg.noneWeightThresh, w) end
            if not msEmpty(Cfg.selMut) and msMutMatch(Cfg.selMut, mut) then return passWeightFilter(Cfg.mutThreshMode, Cfg.mutWeightThresh, w) end
        end
        return msEmpty(Cfg.lowKgMut) and msEmpty(Cfg.highKgMut) and msEmpty(Cfg.selMut) and Cfg.noneThreshMode == "" and Cfg.mutThreshMode == ""
    end

    local mut = fruit:GetAttribute("Mutation") or ""
    local mutKey = mut == "" and "None" or mut
    local w = getFruitDisplayKg(fruit, seedName)

    local dnc = Cfg.doNotCollectRules
    local keepAbove = type(dnc) == "table" and tonumber(dnc[seedName]) or nil
    if keepAbove and w and w >= keepAbove then return false end

    if not msMatch(Cfg.selFruit, seedName) then return false end
    if not msMatch(Cfg.selRarity, SEED_RARITY[seedName] or "Common") then return false end

    if table.find(Cfg.lowKgMut, mutKey) then
        return passWeightFilter(Cfg.lowKgMode, Cfg.lowKgThresh, w)
    end

    if table.find(Cfg.highKgMut, mutKey) then
        return passWeightFilter(Cfg.highKgMode, Cfg.highKgThresh, w)
    end

    if mut == "" then
        local noneSelected = table.find(Cfg.selMut, "None") ~= nil or uiAutoCollectMutationHas("None")
        if not noneSelected then return false end
        return passWeightFilter(Cfg.noneThreshMode, Cfg.noneWeightThresh, w)
    end

    if msEmpty(Cfg.selMut) or not msMutMatch(Cfg.selMut, mut) then return false end
    return passWeightFilter(Cfg.mutThreshMode, Cfg.mutWeightThresh, w)
end

_G._AuditCollectFruits = function(limit)
    limit = tonumber(limit) or 30
    local printed = 0
    for _, plot in pairs(Gardens:GetChildren()) do
        local plantsF = plot:FindFirstChild("Plants")
        if plantsF then
            for _, plant in pairs(plantsF:GetChildren()) do
                if plant:IsA("Model") then
                    local seedName = plant:GetAttribute("SeedName") or ""
                    local fruitsF = plant:FindFirstChild("Fruits")
                    if fruitsF then
                        for _, fruit in pairs(fruitsF:GetChildren()) do
                            local mut = fruit:GetAttribute("Mutation") or ""
                            local mutKey = mut == "" and "None" or mut
                            local w = getFruitDisplayKg(fruit, seedName)
                            local bucket = "NO_BUCKET"
                            local pass = false
                            local ready, age, maxAge = isFruitReady(fruit)
                            local filterPass = false
                            if table.find(Cfg.lowKgMut, mutKey) then
                                bucket = "LOW " .. tostring(Cfg.lowKgMode) .. " " .. tostring(Cfg.lowKgThresh)
                                filterPass = passWeightFilter(Cfg.lowKgMode, Cfg.lowKgThresh, w)
                            elseif table.find(Cfg.highKgMut, mutKey) then
                                bucket = "HIGH " .. tostring(Cfg.highKgMode) .. " " .. tostring(Cfg.highKgThresh)
                                filterPass = passWeightFilter(Cfg.highKgMode, Cfg.highKgThresh, w)
                            else
                                filterPass = passFruitFilter(plant, fruit)
                            end
                            local finalPass = filterPass and ready
                            print("[COLLECT AUDIT]", seedName, mutKey, w and string.format("%.2fkg", w) or "??kg", bucket, filterPass and "FILTER_PASS" or "FILTER_SKIP", ready and "READY" or "NOT_READY", "age=" .. tostring(age or "?") .. "/" .. tostring(maxAge or "?"), finalPass and "FINAL_COLLECT" or "FINAL_SKIP")
                            printed += 1
                            if printed >= limit then return printed end
                        end
                    end
                end
            end
        end
    end
    return printed
end

local function isBest(plant, fruit)
    local seedName = plant:GetAttribute("SeedName") or ""
    if plant == fruit then
        return (RARITY_RANK[SEED_RARITY[seedName] or "Common"] or 0) >= 5
    end
    local mut = fruit:GetAttribute("Mutation") or ""
    local w = fruit:GetAttribute("SizeMulti") or 1
    if Cfg.collectBestMinValue > 0 then
        return calcFruitValue(seedName, w, mut) >= Cfg.collectBestMinValue
    end
    if mut ~= "" then return true end
    return (RARITY_RANK[SEED_RARITY[seedName] or "Common"] or 0) >= 5
end

task.spawn(function()
    while not Speed_Library.Unloaded do
        local active = Cfg.autoHarvest or Cfg.autoCollectAll or Cfg.autoCollectFruit or Cfg.autoCollectBest
        if not active then
            task.wait(1)
        elseif isFullCheck() then
            setStatus("Backpack Full — paused")
            task.wait(2)
        else
            local plot = getMyPlot()
            if not plot then
                setStatus("No plot — retrying...")
                task.wait(2)
            else
                doTp(plot)
                local plants = plot:FindFirstChild("Plants")
                local count = 0
                if plants then
                    for _, plant in pairs(plants:GetChildren()) do
                        if not (Cfg.autoHarvest or Cfg.autoCollectAll or Cfg.autoCollectFruit or Cfg.autoCollectBest) then break end
                        local plantId = plant:GetAttribute("PlantId")
                        if plantId then
                            local fruitsF = plant:FindFirstChild("Fruits")
                            if fruitsF then
                                for _, fruit in pairs(fruitsF:GetChildren()) do
                                    local fruitId = fruit:GetAttribute("FruitId")
                                    local ready = isFruitReady(fruit)
                                    if fruitId and ready then
                                        local ok = false
                                        if Cfg.autoHarvest then
                                            ok = true
                                        elseif Cfg.autoCollectAll then
                                            ok = hasFruitCollectFilter() and passFruitFilter(plant, fruit) or true
                                        elseif Cfg.autoCollectBest then
                                            ok = isBest(plant, fruit)
                                        elseif Cfg.autoCollectFruit then
                                            ok = passFruitFilter(plant, fruit)
                                        end
                                        if ok and shouldWaitMutation(plant, fruit) then ok = false end
                                        if ok then
                                            Networking.Garden.CollectFruit:Fire(plantId, fruitId)
                                            count = count + 1
                                            State.harvested = State.harvested + 1
                                            task.wait(Cfg.delay)
                                        end
                                    end
                                end
                            elseif isFruitReady(plant) then
                                local ready = true
                                if ready then
                                    local ok = false
                                    if Cfg.autoHarvest then
                                        ok = true
                                    elseif Cfg.autoCollectAll then
                                        ok = hasFruitCollectFilter() and passFruitFilter(plant, plant) or true
                                    elseif Cfg.autoCollectBest then
                                        ok = isBest(plant, plant)
                                    elseif Cfg.autoCollectFruit then
                                        ok = passFruitFilter(plant, plant)
                                    end
                                    if ok and shouldWaitMutation(plant, plant) then ok = false end
                                    if ok then
                                        Networking.Garden.CollectFruit:Fire(plantId, "")
                                        count = count + 1
                                        State.harvested = State.harvested + 1
                                        task.wait(Cfg.delay)
                                    end
                                end
                            end
                        end
                    end
                end
                if count > 0 then
                    setStatus(("Collected %d | Total: %d"):format(count, State.harvested))
                else
                    setStatus(("Watching... | Total: %d"):format(State.harvested))
                end
                task.wait(0.2)
            end
        end
    end
end)

-- ==================== REACTIVE INSTANT COLLECT ====================
task.spawn(function()
    local tracked = {}
    local conns = {}

    local function tryInstantCollect(plant, fruit)
        local active = Cfg.autoHarvest or Cfg.autoCollectAll or Cfg.autoCollectFruit or Cfg.autoCollectBest
        if not active then return end
        if isFullCheck() then return end
        local plantId = plant:GetAttribute("PlantId")
        local fruitId = fruit:GetAttribute("FruitId")
        if fruitId == nil and plant == fruit then fruitId = "" end
        if not plantId or not fruitId then return end
        if fruitId == "" and plant:FindFirstChild("Fruits") then return end
        local ready = isFruitReady(fruit)
        if not ready then return end
        local key = tostring(plantId) .. "_" .. tostring(fruitId)
        if tracked[key] then return end
        local ok = false
        if Cfg.autoHarvest then
            ok = true
        elseif Cfg.autoCollectAll then
            ok = hasFruitCollectFilter() and passFruitFilter(plant, fruit) or true
        elseif Cfg.autoCollectBest then
            ok = isBest(plant, fruit)
        elseif Cfg.autoCollectFruit then
            ok = passFruitFilter(plant, fruit)
        end
        if ok and shouldWaitMutation(plant, fruit) then ok = false end
        if ok then
            tracked[key] = true
            task.wait(math.random(3, 12) / 100)
            pcall(function() Networking.Garden.CollectFruit:Fire(plantId, fruitId) end)
            State.harvested = State.harvested + 1
        end
    end

    local function watchFruit(plant, fruit)
        if not fruit:IsA("Model") and not fruit:IsA("BasePart") then return end
        local fruitId = fruit:GetAttribute("FruitId")
        if fruitId == nil and plant == fruit then fruitId = "" end
        if not fruitId then return end
        local cKey = tostring(plant:GetFullName()) .. "/" .. tostring(fruitId)
        if conns[cKey] then return end
        tryInstantCollect(plant, fruit)
        local conn = fruit:GetAttributeChangedSignal("Age"):Connect(function()
            tryInstantCollect(plant, fruit)
        end)
        conns[cKey] = conn
    end

    local function watchPlant(plant)
        local fruitsF = plant:FindFirstChild("Fruits")
        if fruitsF then
            for _, fruit in ipairs(fruitsF:GetChildren()) do
                watchFruit(plant, fruit)
            end
            local conn = fruitsF.ChildAdded:Connect(function(f)
                task.wait(0.5)
                watchFruit(plant, f)
            end)
            conns[tostring(plant:GetFullName()) .. "_add"] = conn
        else
            watchFruit(plant, plant)
            local conn = plant.ChildAdded:Connect(function(child)
                if child.Name == "Fruits" then
                    for _, fruit in ipairs(child:GetChildren()) do
                        watchFruit(plant, fruit)
                    end
                    conns[tostring(plant:GetFullName()) .. "_add"] = child.ChildAdded:Connect(function(f)
                        task.wait(0.5)
                        watchFruit(plant, f)
                    end)
                end
            end)
            conns[tostring(plant:GetFullName()) .. "_childadd"] = conn
        end
    end

    local function scanPlot()
        local plot = getMyPlot()
        if not plot then return end
        local plants = plot:FindFirstChild("Plants")
        if not plants then return end
        for _, plant in ipairs(plants:GetChildren()) do
            if plant:GetAttribute("PlantId") then
                watchPlant(plant)
            end
        end
        local plantsConnKey = "plants_" .. plants:GetFullName()
        if not conns[plantsConnKey] then
            conns[plantsConnKey] = plants.ChildAdded:Connect(function(plant)
                task.wait()
                if plant:GetAttribute("PlantId") then
                    watchPlant(plant)
                end
            end)
        end
    end

    task.wait(2)
    scanPlot()

    while not Speed_Library.Unloaded do
        task.wait(10)
        for key, conn in pairs(conns) do
            if not conn.Connected then
                conns[key] = nil
            end
        end
        local staleKeys = {}
        for key in pairs(tracked) do
            table.insert(staleKeys, key)
        end
        if #staleKeys > 500 then
            tracked = {}
        end
    end
    for _, conn in pairs(conns) do pcall(function() conn:Disconnect() end) end
end)

task.spawn(function()
    local _lastSwing = 0
    local _hitCooldown = {}

    local function getWeapon()
        local char = LocalPlayer.Character
        if not char then return nil end
        for _, v in pairs(char:GetChildren()) do
            if v:IsA("Tool") then
                if v:GetAttribute("Shovel") then return "Shovel" end
                if v:GetAttribute("Crowbar") then return "Crowbar" end
            end
        end
        return nil
    end

    local function autoEquipWeapon()
        if getWeapon() then return end
        local char = LocalPlayer.Character
        local bp = LocalPlayer:FindFirstChild("Backpack")
        if not char or not bp then return end
        local hum = char:FindFirstChild("Humanoid")
        if not hum then return end
        for _, tool in pairs(bp:GetChildren()) do
            if tool:IsA("Tool") and (tool:GetAttribute("Shovel") or tool:GetAttribute("Crowbar")) then
                hum:EquipTool(tool)
                return
            end
        end
    end

    local function attackNearSeed(seedPos)
        if not Cfg.autoAttack then return end
        local now = os.clock()
        if now - _lastSwing < 1 then return end
        local weapon = getWeapon()
        if not weapon then return end
        _lastSwing = now
        if weapon == "Shovel" then
            Networking.Shovel.SwingShovel:Fire()
        else
            Networking.Crowbar.SwingCrowbar:Fire()
        end
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                if hrp and (hrp.Position - seedPos).Magnitude <= 20 then
                    if not _hitCooldown[player] or now - _hitCooldown[player] >= 0.5 then
                        _hitCooldown[player] = now
                        if weapon == "Shovel" then
                            Networking.Shovel.HitPlayer:Fire(player.UserId)
                        else
                            Networking.Crowbar.HitPlayer:Fire(player.UserId)
                        end
                    end
                end
            end
        end
    end

    local function wantItem(item)
        if not item:IsA("Model") then return false end
        local ownerR = item:GetAttribute("OwnerRestricted")
        local dropBy = item:GetAttribute("DroppedBy")
        if ownerR and dropBy ~= LocalPlayer.UserId then return false end
        local name = item:GetAttribute("ItemName") or ""
        local cat  = item:GetAttribute("ItemCategory") or ""
        local isGold    = name == "Gold"    and cat == "Seeds"
        local isRainbow = name == "Rainbow" and cat == "Seeds"
        return Cfg.autoDropped
            or (Cfg.autoGoldSeed    and isGold)
            or (Cfg.autoRainbowSeed and isRainbow)
    end

    local _collecting = {}

    local function collectDropped(item)
        if _collecting[item] then return end
        _collecting[item] = true

        local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
        if not prompt then
            local deadline = os.clock() + 0.5
            repeat task.wait() until item:FindFirstChildWhichIsA("ProximityPrompt", true) or not item.Parent or os.clock() > deadline
            prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
        end

        if not prompt or not item.Parent then
            _collecting[item] = nil
            return
        end

        local lockConn
        if not Cfg.disableTp then
            local hrp = getHRP()
            local base = item:FindFirstChildWhichIsA("BasePart")
            if hrp and base then
                local targetCF = CFrame.new(base.Position + Vector3.new(0, 3, 0))
                hrp.CFrame = targetCF
                hrp.AssemblyLinearVelocity = Vector3.zero
                lockConn = game:GetService("RunService").Heartbeat:Connect(function()
                    local h = getHRP()
                    if h then
                        h.CFrame = targetCF
                        h.AssemblyLinearVelocity = Vector3.zero
                    end
                end)
                task.wait(0.15)
            end
        end

        if not item.Parent then
            if lockConn then lockConn:Disconnect() end
            _collecting[item] = nil
            return
        end
        fireproximityprompt(prompt)
        task.wait((prompt.HoldDuration or 1) + 0.3)
        if lockConn then lockConn:Disconnect() end

        task.delay(3, function() _collecting[item] = nil end)
    end

    local folder = workspace:WaitForChild("DroppedItems", 30)
    if not folder then return end

    local _dropQueue = {}
    local _dropQueued = {}

    local function enqueueDrop(item)
        if _dropQueued[item] then return end
        if not (Cfg.autoDropped or Cfg.autoGoldSeed or Cfg.autoRainbowSeed) then return end
        if not wantItem(item) then return end
        _dropQueued[item] = true
        table.insert(_dropQueue, item)
    end

    -- Serial worker — only ONE item processed at a time, one HRP lock active
    task.spawn(function()
        while not Speed_Library.Unloaded do
            task.wait(0.05)
            while #_dropQueue > 0 do
                if Speed_Library.Unloaded then break end
                local item = table.remove(_dropQueue, 1)
                _dropQueued[item] = nil
                if item.Parent and wantItem(item) then
                    if Cfg.autoAttack then autoEquipWeapon() end
                    local base = item:FindFirstChildWhichIsA("BasePart")
                    if base then task.spawn(attackNearSeed, base.Position) end
                    collectDropped(item)
                end
                task.wait(0.2)
            end
        end
    end)

    folder.ChildAdded:Connect(enqueueDrop)

    while not Speed_Library.Unloaded do
        if Cfg.autoDropped or Cfg.autoGoldSeed or Cfg.autoRainbowSeed then
            for _, item in pairs(folder:GetChildren()) do
                enqueueDrop(item)
            end
        end
        task.wait(1)
    end
end)


-- ==================== AUTO COLLECT WEATHER SEEDS ====================
task.spawn(function()
    local RunService = game:GetService("RunService")
    local seedFolder = workspace:WaitForChild("Map", 30)
    seedFolder = seedFolder and seedFolder:WaitForChild("SeedPackSpawnServerLocations", 30)
    if not seedFolder then return end

    local _queue = {}
    local _queued = {}
    local _attempts = {}
    local MAX_ATTEMPTS = 4
    local _lockActive = false

    local function wantSeed(part)
        if not part or not part.Parent then return false end
        local isGold    = part:GetAttribute("GoldSeed") == true
        local isRainbow = part:GetAttribute("RainbowSeed") == true
        return (isGold and Cfg.autoGoldSeed) or (isRainbow and Cfg.autoRainbowSeed)
    end

    -- returns true = finished (collected / not wanted), false = transient fail (retry)
    local function collectOne(part)
        if not part or not part.Parent then return true end
        if not wantSeed(part) then return true end

        -- Wait for ProximityPrompt — signals seed is fully spawned with valid position
        local prompt = part:FindFirstChildWhichIsA("ProximityPrompt", true)
        if not prompt then
            local elapsed = 0
            repeat
                task.wait(0.05)
                elapsed = elapsed + 0.05
                prompt = part:FindFirstChildWhichIsA("ProximityPrompt", true)
            until prompt or not part.Parent or elapsed >= 3
        end
        if not part.Parent then return true end
        if not prompt then return false end

        local lockConn
        if not Cfg.disableTp then
            local hrp = getHRP()
            if hrp then
                local targetCF = CFrame.new(part.Position + Vector3.new(0, 3, 0))
                hrp.CFrame = targetCF
                hrp.AssemblyLinearVelocity = Vector3.zero
                _lockActive = true
                lockConn = RunService.Heartbeat:Connect(function()
                    local h = getHRP()
                    if h then h.CFrame = targetCF; h.AssemblyLinearVelocity = Vector3.zero end
                end)
            end
        else
            -- No-TP mode: walk toward the seed until in range
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                local deadline = os.clock() + 8
                while part.Parent and os.clock() < deadline do
                    local h = getHRP()
                    if not h then break end
                    if (h.Position - part.Position).Magnitude <= 10 then break end
                    hum:MoveTo(part.Position)
                    task.wait(0.2)
                end
            end
        end

        for _ = 1, 20 do
            if not part.Parent then break end
            local p = part:FindFirstChildWhichIsA("ProximityPrompt", true)
            if p then
                fireproximityprompt(p)
            else
                local h = getHRP()
                if h then firetouchinterest(h, part, 0); firetouchinterest(h, part, 1) end
            end
            task.wait(0.1)
        end

        if lockConn then lockConn:Disconnect() end
        _lockActive = false

        return not part.Parent
    end

    local function enqueue(part)
        if _queued[part] then return end
        if not wantSeed(part) then return end
        _queued[part] = true
        table.insert(_queue, part)
    end

    -- Serial queue worker — only ONE seed processed at a time, one lockConn active
    task.spawn(function()
        while not Speed_Library.Unloaded do
            task.wait(0.05)
            while #_queue > 0 do
                if Speed_Library.Unloaded then break end
                local part = table.remove(_queue, 1)  -- stays marked in _queued while processing
                local done = collectOne(part)
                if (not done) and part.Parent then
                    local n = (_attempts[part] or 0) + 1
                    _attempts[part] = n
                    if n < MAX_ATTEMPTS then
                        table.insert(_queue, part)  -- retry: push to back, still marked
                    else
                        _attempts[part] = nil
                        _queued[part] = nil
                    end
                else
                    _attempts[part] = nil
                    _queued[part] = nil
                end
                task.wait(0.2)
            end
        end
    end)

    -- Pre-TP on weather event fires (before part even appears) — skip if mid-collect
    Networking.WeatherEffects.GoldMoonStrike.OnClientEvent:Connect(function(pos)
        if not Cfg.autoGoldSeed or Cfg.disableTp or _lockActive then return end
        local hrp = getHRP()
        if hrp then
            hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
            hrp.AssemblyLinearVelocity = Vector3.zero
        end
    end)

    Networking.WeatherEffects.RainbowMoonStrike.OnClientEvent:Connect(function(pos)
        if not Cfg.autoRainbowSeed or Cfg.disableTp or _lockActive then return end
        local hrp = getHRP()
        if hrp then
            hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
            hrp.AssemblyLinearVelocity = Vector3.zero
        end
    end)

    seedFolder.ChildAdded:Connect(enqueue)

    -- Periodic re-scan — re-queue still-present seeds (e.g. after toggling on mid-session)
    task.spawn(function()
        while not Speed_Library.Unloaded do
            if Cfg.autoGoldSeed or Cfg.autoRainbowSeed then
                for _, part in pairs(seedFolder:GetChildren()) do
                    enqueue(part)
                end
            end
            task.wait(4)
        end
    end)

    for _, part in pairs(seedFolder:GetChildren()) do
        enqueue(part)
    end
end)

-- ==================== AUTO SELL ====================
task.spawn(function()
    local function passSellFruitFilter(tool)
        local valueBelow = tonumber(Cfg.sellValueBelow) or 0
        local hasFilter = valueBelow > 0
            or not msEmpty(Cfg.selSellFruit)
            or not msEmpty(Cfg.selSellRarity)
            or not msEmpty(Cfg.selSellMut)
            or Cfg.selSellThresh ~= ""
        if not hasFilter then return false end
        local name = tool:GetAttribute("FruitName") or ""
        local mut  = tool:GetAttribute("Mutation") or ""
        local w    = tonumber(tool:GetAttribute("Weight"))
        if valueBelow > 0 then
            local val = calcFruitValue(name, tool:GetAttribute("SizeMultiplier") or 1, mut, tool:GetAttribute("DecayAlpha") or 0)
            return val <= valueBelow
        end
        if not msMatch(Cfg.selSellFruit, name) then return false end
        if not msMatch(Cfg.selSellRarity, SEED_RARITY[name] or "Common") then return false end
        if not msMutMatch(Cfg.selSellMut, mut) then return false end
        if Cfg.selSellThresh ~= "" then
            if not w then return false end
            if Cfg.selSellThresh == "Above" and w < Cfg.sellWeightThresh then return false end
            if Cfg.selSellThresh == "Below" and w > Cfg.sellWeightThresh then return false end
        end
        return true
    end

    local function getBackpackFruits()
        local fruits = {}
        for _, t in pairs(LocalPlayer.Backpack:GetChildren()) do
            if t:GetAttribute("HarvestedFruit") and t:GetAttribute("Id") then
                table.insert(fruits, t)
            end
        end
        return fruits
    end

    local function backpackFruitCountAtLeast(limit)
        local bp = LocalPlayer:FindFirstChild("Backpack")
        if not bp then return false end
        local count = 0
        for _, t in pairs(bp:GetChildren()) do
            if t:GetAttribute("HarvestedFruit") and t:GetAttribute("Id") then
                count += 1
                if count >= limit then return true end
            end
        end
        return false
    end

    local lastSellAllAt = 0
    local SELL_ALL_MIN_COOLDOWN = 5
    local SELL_BATCH_LIMIT = 15
    local SELL_REMOTE_PAUSE = 0.05

    while not Speed_Library.Unloaded do
        local sellDelay = math.max(tonumber(Cfg.sellDelay) or 1, 0.5)
        task.wait(sellDelay)
        if (Cfg.autoSellAll or Cfg.autoSellFruit or Cfg.autoSellPets)
            and (not Cfg.sellIfFull or backpackFruitCountAtLeast(5)) then

            if Cfg.autoSellAll and os.clock() - lastSellAllAt >= math.max(sellDelay, SELL_ALL_MIN_COOLDOWN) then
                lastSellAllAt = os.clock()
                if Cfg.sellBargain then
                    Networking.NPCS.AskBidAll:Fire()
                    task.wait(0.2)
                end
                if Cfg.sellDailyDeal then
                    local deal = Networking.NPCS.CheckDailyDeal:Fire()
                    if deal and deal.Active then
                        Networking.NPCS.UseDailyDealAll:Fire()
                    else
                        Networking.NPCS.SellAll:Fire()
                    end
                else
                    Networking.NPCS.SellAll:Fire()
                end
            end

            if Cfg.autoSellFruit then
                local soldCount = 0
                for _, tool in pairs(getBackpackFruits()) do
                    if passSellFruitFilter(tool) then
                        Networking.NPCS.SellFruit:Fire(tool:GetAttribute("Id"))
                        soldCount = soldCount + 1
                        if soldCount >= SELL_BATCH_LIMIT then break end
                        if soldCount % 3 == 0 then task.wait(SELL_REMOTE_PAUSE) end
                    end
                end
            end

            if Cfg.autoSellPets then
                local PET_RARITY_SELL = {
                    Frog="Common",Snail="Common",Cat="Common",Bunny="Common",Chick="Common",Dog="Common",
                    Bee="Uncommon",Butterfly="Uncommon",Cow="Uncommon",Duck="Uncommon",
                    Panda="Rare",Deer="Rare",Dodo="Rare",
                    Eagle="Epic",Goat="Epic",Owl="Epic",
                    ["Polar Bear"]="Legendary",Peacock="Legendary",Shark="Legendary",
                    Minotaur="Mythic",Trex="Mythic",
                }
                local soldCount = 0
                for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
                    local petId = tool:GetAttribute("PetId")
                    if petId then
                        local petName = tool:GetAttribute("Pet") or ""
                        local petSize = tool:GetAttribute("PetSize") or ""
                        local petRarity = PET_RARITY_SELL[petName] or "Common"
                        local pass = true
                        if not msMatch(Cfg.selSellPet, petName) then pass = false end
                        if not msMatch(Cfg.selSellPetRarity, petRarity) then pass = false end
                        if not msMatch(Cfg.selSellPetSize, petSize) then pass = false end
                        if pass then
                            Networking.NPCS.SellPet:Fire(petId)
                            soldCount = soldCount + 1
                            if soldCount >= SELL_BATCH_LIMIT then break end
                            if soldCount % 3 == 0 then task.wait(SELL_REMOTE_PAUSE) end
                        end
                    end
                end
            end
        end -- if autoSell enabled
    end
end)

-- ==================== AUTO SHOP ====================
task.spawn(function()
    local rs = game:GetService("ReplicatedStorage")

    local sv = rs:WaitForChild("StockValues", 10)
    local seedItems   = sv and sv:WaitForChild("SeedShop", 10)
    seedItems         = seedItems and seedItems:WaitForChild("Items", 10)
    local gearItems   = sv and sv:FindFirstChild("GearShop")
    gearItems         = gearItems and gearItems:FindFirstChild("Items")
    local crateItems  = sv and sv:FindFirstChild("CrateShop")
    crateItems        = crateItems and crateItems:FindFirstChild("Items")
    local function getStock(folder, name)
        if not folder or type(name) ~= "string" or name == "" then return 0 end
        local v = folder:FindFirstChild(name)
        return tonumber(v and v.Value) or 0
    end

    local function drainBuy(remote, folder, name)
        local stock = math.clamp(getStock(folder, name), 0, 250)
        dlog("SHOP", "buy", name, "stock", stock)
        for _ = 1, stock do
            remote:Fire(name)
            task.wait(0.05)
        end
    end
    local function drainBuyAll(remote, folder)
        if not folder then return end
        for _, v in pairs(folder:GetChildren()) do
            local stock = math.clamp(tonumber(v.Value) or 0, 0, 250)
            dlog("SHOP", "buyAll", v.Name, "stock", stock)
            for _ = 1, stock do
                remote:Fire(v.Name)
                task.wait(0.05)
            end
        end
    end
    local function drainBuySelected(remote, folder, selected)
        selected = cleanSelectionTable(selected)
        for _, name in ipairs(selected) do
            drainBuy(remote, folder, name)
            task.wait(0.05)
        end
    end

    _G._AuditShopSelection = function()
        local function audit(kind, folder, selected)
            selected = cleanSelectionTable(selected)
            for _, name in ipairs(selected) do
                print("[SHOP AUDIT]", kind, name, "stock=" .. tostring(getStock(folder, name)), "selected=true")
            end
        end
        audit("Seed", seedItems, Cfg.selBuySeed)
        audit("Gear", gearItems, Cfg.selBuyGear)
        audit("Crate", crateItems, Cfg.selBuyCrate)
    end
    while not Speed_Library.Unloaded do
        task.wait(math.max(Cfg.buyShopDelay, 1))
        if Cfg.autoBuySeed then
            drainBuySelected(Networking.SeedShop.PurchaseSeed, seedItems, Cfg.selBuySeed)
        end
        if Cfg.autoBuyAllSeeds then
            drainBuyAll(Networking.SeedShop.PurchaseSeed, seedItems)
        end
        if Cfg.autoBuyGear then
            drainBuySelected(Networking.GearShop.PurchaseGear, gearItems, Cfg.selBuyGear)
        end
        if Cfg.autoBuyAllGear then
            drainBuyAll(Networking.GearShop.PurchaseGear, gearItems)
        end
        if Cfg.autoBuyCrate then
            drainBuySelected(Networking.CrateShop.PurchaseCrate, crateItems, Cfg.selBuyCrate)
        end
        if Cfg.autoBuyAllCrates then
            drainBuyAll(Networking.CrateShop.PurchaseCrate, crateItems)
        end
    end
end)

-- ==================== AUTO STEAL ====================
task.spawn(function()
    local rs  = game:GetService("ReplicatedStorage")
    local cs  = game:GetService("CollectionService")
    local Players = game:GetService("Players")

    local function isNight()
        local n = rs:FindFirstChild("Night")
        return n and n.Value == true
    end

    local function passStealFilter(model)
        if Cfg.selStealFilter == "Select Options" then return true end
        local seedName = model:GetAttribute("SeedName") or ""
        if Cfg.selStealFilter == "Fruit" then
            return msMatch(Cfg.selStealFruit, seedName)
        elseif Cfg.selStealFilter == "Rarity" then
            return msMatch(Cfg.selStealRarity, SEED_RARITY[seedName] or "Common")
        elseif Cfg.selStealFilter == "Mutation" then
            local mut = model:GetAttribute("Mutation") or ""
            return msMutMatch(Cfg.selStealMut, mut)
        end
        return true
    end

    local function isBestSteal(model)
        local seedName = model:GetAttribute("SeedName") or ""
        local mut = model:GetAttribute("Mutation") or ""
        return mut ~= "" or (RARITY_RANK[SEED_RARITY[seedName] or "Common"] or 0) >= 5
    end

    local function doSteal(prompt)
        local parent = prompt.Parent
        if not parent then return end
        local model = parent:FindFirstAncestorWhichIsA("Model")
        if not model then return end
        local ownerId = tonumber(model:GetAttribute("UserId"))
        local plantId = model:GetAttribute("PlantId")
        local fruitId = model:GetAttribute("FruitId") or ""
        if not ownerId or not plantId then return end
        if not Cfg.disableTp then
            local hrp = getHRP()
            local base = model:FindFirstChildWhichIsA("BasePart", true)
            if hrp and base then
                hrp.CFrame = CFrame.new(base.Position + Vector3.new(0, 3, 0))
                task.wait(0.1)
            end
        end
        Networking.Steal.BeginSteal:Fire(ownerId, plantId, fruitId)
        task.wait(0.05)
        Networking.Steal.CompleteSteal:Fire()
    end

    task.spawn(function()
        while not Speed_Library.Unloaded do
            if Cfg.flingPlayers then
                for _, plr in pairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer then
                        local char = plr.Character
                        local hrp = char and char:FindFirstChild("HumanoidRootPart")
                        if hrp then hrp.AssemblyLinearVelocity = Vector3.new(0, 500, 0) end
                    end
                end
            end
            task.wait(0.2)
        end
    end)

    local hitCooldowns = {}
    task.spawn(function()
        while not Speed_Library.Unloaded do
            if Cfg.autoHitStolen then
                for _, plr in pairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer then
                        if plr:GetAttribute("IsStealingFruit") or plr:GetAttribute("CarryingStolenFruit") then
                            local now = os.clock()
                            if not hitCooldowns[plr] or now - hitCooldowns[plr] >= 1 then
                                hitCooldowns[plr] = now
                                Networking.Shovel.HitPlayer:Fire(plr.UserId)
                            end
                        end
                    end
                end
            end
            task.wait(0.3)
        end
    end)

    while not Speed_Library.Unloaded do
        task.wait(math.max(Cfg.stealDelay, 0.5))
        if (Cfg.autoSteal or Cfg.autoStealBest) and isNight() then
            for _, prompt in pairs(cs:GetTagged("StealPrompt")) do
                if not (Cfg.autoSteal or Cfg.autoStealBest) then break end
                if prompt:IsA("ProximityPrompt") and prompt:IsDescendantOf(workspace) and prompt.Enabled then
                    local parent = prompt.Parent
                    if parent then
                        local model = parent:FindFirstAncestorWhichIsA("Model")
                        if model then
                            if Cfg.autoSteal and passStealFilter(model) then
                                doSteal(prompt)
                                task.wait(0.1)
                            elseif Cfg.autoStealBest and isBestSteal(model) then
                                doSteal(prompt)
                                task.wait(0.1)
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- ==================== AUTO PETS ====================
task.spawn(function()
    local PET_RARITY_BUY = {
        Frog="Common", Snail="Common", Cat="Common", Bunny="Common", Chick="Common", Dog="Common",
        Bee="Uncommon", Butterfly="Uncommon", Cow="Uncommon", Duck="Uncommon",
        Panda="Rare", Deer="Rare", Dodo="Rare",
        Eagle="Epic", Goat="Epic", Owl="Epic",
        ["Polar Bear"]="Legendary", Peacock="Legendary", Shark="Legendary",
        Minotaur="Mythic", Trex="Mythic",
    }
    pcall(function()
        local pd = require(game:GetService("ReplicatedStorage"):WaitForChild("SharedData"):WaitForChild("PetData"))
        for k, v in pairs(pd) do
            if type(v) == "table" and v.Rarity then PET_RARITY_BUY[k] = v.Rarity end
        end
    end)

    local function passPetBuyFilter(model)
        local petName = model:GetAttribute("PetName") or model.Name
        local petSize = model:GetAttribute("PetSize") or ""
        if not msMatch(Cfg.selBuyPet, petName) then return false end
        if not msMatch(Cfg.selBuyPetRarity, PET_RARITY_BUY[petName] or "Common") then return false end
        if not msMatch(Cfg.selBuyPetSize, petSize) then return false end
        return true
    end

    local petModels = nil

    while not Speed_Library.Unloaded do
        task.wait(math.max(Cfg.buyPetDelay, 1))
        if Cfg.autoBuyPet then
            if not petModels or not petModels.Parent then
                local pvc = workspace:FindFirstChild("_PetVisualClient")
                petModels = pvc and pvc:FindFirstChild("Models")
            end
            if petModels then
                for _, model in pairs(petModels:GetChildren()) do
                    if Cfg.autoBuyPet and passPetBuyFilter(model) then
                        if not Cfg.disableTp then
                            local hrp = getHRP()
                            local base = model:FindFirstChildWhichIsA("BasePart", true)
                            if hrp and base then
                                hrp.CFrame = CFrame.new(base.Position + Vector3.new(0, 3, 0))
                                task.wait(0.1)
                            end
                        end
                        Networking.Pets.WildPetTame:Fire(model)
                        task.wait(0.5)
                    end
                end
            end
        end
    end
end)

-- ==================== AUTO MAIL SEND ====================
local MailFruitValueCalc = nil
local MailFruitValueCalcLoaded = false

local function parseMoneyInput(text)
    text = tostring(text or ""):lower():gsub(",", ""):gsub("%s+", "")
    if text == "" then return 0 end
    local num, suffix = text:match("^([%d%.]+)([kmbtq]?)$")
    num = tonumber(num)
    if not num then return 0 end
    local mult = suffix == "k" and 1e3 or suffix == "m" and 1e6 or suffix == "b" and 1e9 or suffix == "t" and 1e12 or suffix == "q" and 1e15 or 1
    return math.floor(num * mult)
end

local function formatMoneyCompact(value)
    value = tonumber(value) or 0
    local absValue = math.abs(value)
    if absValue >= 1e12 then return string.format("%.2fT", value / 1e12) end
    if absValue >= 1e9 then return string.format("%.2fB", value / 1e9) end
    if absValue >= 1e6 then return string.format("%.2fM", value / 1e6) end
    if absValue >= 1e3 then return string.format("%.2fK", value / 1e3) end
    return tostring(math.floor(value))
end

local function getMailFruitValueCalc()
    if MailFruitValueCalcLoaded then return MailFruitValueCalc end
    MailFruitValueCalcLoaded = true
    local ok, calc = pcall(function()
        return require(ReplicatedStorage.SharedModules.FruitValueCalc)
    end)
    if ok and type(calc) == "function" then MailFruitValueCalc = calc end
    return MailFruitValueCalc
end

local function getMailFruitValue(fruit)
    if not fruit then return 0 end
    return calcFruitValue(
        fruit:GetAttribute("FruitName") or "",
        fruit:GetAttribute("SizeMultiplier") or 1,
        fruit:GetAttribute("Mutation") or "",
        fruit:GetAttribute("DecayAlpha") or 0,
        true -- Ignore stock multiplier for mailing (use base value)
    )
end

local function mailSelectedKeys(value)
    if type(value) == "table" then
        local out = {}
        for _, v in ipairs(value) do
            if type(v) == "string" and v ~= "" and v ~= "Select Options" then table.insert(out, v) end
        end
        return out
    end
    if type(value) == "string" and value ~= "" and value ~= "Select Options" then return { value } end
    return {}
end

local function isAnyFruitKey(key)
    if type(key) == "table" then
        if #key == 0 then return true end
        for _, v in ipairs(key) do
            v = tostring(v or "")
            if v == "" or v == "Select Options" or v:lower() == "all" or v == "*" then return true end
        end
        return false
    end
    key = tostring(key or "")
    return key == "" or key == "Select Options" or key:lower() == "all" or key == "*"
end

local function collectMailFruits(key)
    local out = {}
    local anyKey = isAnyFruitKey(key)
    local keySet = {}
    for _, selected in ipairs(mailSelectedKeys(key)) do keySet[selected] = true end
    local bp = Player:FindFirstChild("Backpack")
    if not bp then return out end
    for _, v in ipairs(bp:GetChildren()) do
        if v:GetAttribute("HarvestedFruit") == true and v:GetAttribute("Id") and v:GetAttribute("IsFavorite") ~= true then
            local fruitName = v:GetAttribute("FruitName") or v:GetAttribute("Fruit") or v.Name
            if anyKey or keySet[fruitName] then
                local value = getMailFruitValue(v)
                local minV = parseMoneyInput(Cfg.mailFruitMinValue)
                local maxV = parseMoneyInput(Cfg.mailFruitMaxValue)
                if value >= minV and value <= maxV then
                    table.insert(out, {
                        inst = v,
                        id = v:GetAttribute("Id"),
                        name = fruitName,
                        display = v.Name,
                        weight = tonumber(v:GetAttribute("Weight")) or 0,
                        value = value,
                    })
                end
            end
        end
    end
    return out
end

local MAIL_GEAR_ATTR_CATEGORY = {
    Sprinkler = "Sprinklers",
    WateringCan = "WateringCans",
    Mushroom = "Mushrooms",
    Gnome = "Gnomes",
    Raccoon = "Raccoons",
    Crate = "Crates",
    SeedPack = "SeedPacks",
    Trowel = "Trowels",
    Prop = "Props",
    EmptyPot = "EmptyPots",
}

local function getMailGearCategory(tool)
    if not tool then return nil end
    for attr, category in pairs(MAIL_GEAR_ATTR_CATEGORY) do
        local value = tool:GetAttribute(attr)
        if value ~= nil then return category, attr, value end
    end
    return nil
end

local MAIL_STATIC_OPTIONS = {
    Seeds = getOptionList("Plants"),
    Gear = getOptionList("Gear"),
    Pets = getOptionList("Pets"),
}

local function getMailItemOptions(uiCategory)
    local options, seen = {}, {}
    local function addOption(name)
        if type(name) == "string" and name ~= "" and not seen[name] then
            seen[name] = true
            table.insert(options, name)
        end
    end
    for _, name in ipairs(MAIL_STATIC_OPTIONS[uiCategory] or {}) do
        addOption(name)
    end
    local bp = Player:FindFirstChild("Backpack")
    if uiCategory == "Fruits" then
        addOption("All")
    end
    if not bp then return options end
    for _, v in ipairs(bp:GetChildren()) do
        local name = nil
        if uiCategory == "Seeds" and v:GetAttribute("SeedTool") then
            name = v:GetAttribute("SeedTool")
        elseif uiCategory == "Gear" then
            local gearCategory, _, gearKey = getMailGearCategory(v)
            if gearCategory then name = type(gearKey) == "string" and gearKey or v.Name end
        elseif uiCategory == "Pets" and v:GetAttribute("Pet") then
            name = v:GetAttribute("Pet")
        elseif uiCategory == "Fruits" and v:GetAttribute("HarvestedFruit") == true then
            name = v:GetAttribute("FruitName") or v:GetAttribute("Fruit") or v.Name
        end
        addOption(name)
    end
    table.sort(options, function(a, b)
        if a == "All" then return true end
        if b == "All" then return false end
        return a < b
    end)
    return options
end

local function chunkPayload(payload, chunkSize, maxBatches)
    local chunks = {}
    chunkSize = math.max(1, tonumber(chunkSize) or 20)
    maxBatches = math.max(1, tonumber(maxBatches) or 1)
    for i = 1, #payload, chunkSize do
        if #chunks >= maxBatches then break end
        local chunk = {}
        for j = i, math.min(i + chunkSize - 1, #payload) do
            table.insert(chunk, payload[j])
        end
        table.insert(chunks, chunk)
    end
    return chunks
end

local function getMailBatchSize()
    if Cfg.mailSendMode == "Batch Loop" then
        return math.max(1, tonumber(Cfg.mailBatchSize) or 20)
    end
    return nil
end

local function countChunks(total, batchSize)
    total = math.max(0, math.floor(tonumber(total) or 0))
    batchSize = math.max(1, math.floor(tonumber(batchSize) or total))
    local out = {}
    while total > 0 do
        local send = math.min(batchSize, total)
        table.insert(out, send)
        total -= send
    end
    return out
end

local function buildMailPayloadBatches()
    local cat = Cfg.mailCategory
    local key = Cfg.mailItemKey
    local count = math.max(1, tonumber(Cfg.mailCount) or 1)
    local userBatchSize = getMailBatchSize()
    local maxBatches = math.max(1, math.ceil(count / 20))
    if cat == "Seeds" then
        local keys, keySet = mailSelectedKeys(key), {}
        for _, selected in ipairs(keys) do keySet[selected] = true end
        local payload = {}
        local bp = Player:FindFirstChild("Backpack")
        if not bp then return nil, "Backpack not found" end
        for _, v in ipairs(bp:GetChildren()) do
            local seedKey = v:GetAttribute("SeedTool")
            if seedKey and keySet[seedKey] then
                local have = v:GetAttribute("Count") or 1
                local totalSend = math.min(count, have)
                if totalSend > 0 then
                    if userBatchSize then
                        for _, send in ipairs(countChunks(totalSend, userBatchSize)) do
                            table.insert(payload, {Category="Seeds", ItemKey=seedKey, Count=send})
                        end
                    else
                        table.insert(payload, {Category="Seeds", ItemKey=seedKey, Count=totalSend})
                    end
                end
            end
        end
        if #payload > 0 then
            local batchSize = userBatchSize or 999999
            return chunkPayload(payload, batchSize, math.max(1, math.ceil(#payload / batchSize))), "Seeds " .. tostring(#payload) .. " batch item(s)"
        end
        return nil, "Seed not found"
    elseif cat == "Gear" then
        local keys, keySet = mailSelectedKeys(key), {}
        for _, selected in ipairs(keys) do keySet[selected] = true end
        local payload = {}
        local bp = Player:FindFirstChild("Backpack")
        if not bp then return nil, "Backpack not found" end
        for _, v in ipairs(bp:GetChildren()) do
            local gearCategory, _, gearKey = getMailGearCategory(v)
            local itemKey = type(gearKey) == "string" and gearKey or v.Name
            if gearCategory and keySet[itemKey] then
                local have = v:GetAttribute("Count") or 1
                local totalSend = math.min(count, have)
                if totalSend > 0 then
                    if userBatchSize then
                        for _, send in ipairs(countChunks(totalSend, userBatchSize)) do
                            table.insert(payload, {Category=gearCategory, ItemKey=itemKey, Count=send})
                        end
                    else
                        table.insert(payload, {Category=gearCategory, ItemKey=itemKey, Count=totalSend})
                    end
                end
            end
        end
        if #payload > 0 then
            local batchSize = userBatchSize or 999999
            return chunkPayload(payload, batchSize, math.max(1, math.ceil(#payload / batchSize))), "Gear " .. tostring(#payload) .. " batch item(s)"
        end
        return nil, "Gear item not found"
    elseif cat == "Pets" then
        local keys, keySet = mailSelectedKeys(key), {}
        for _, selected in ipairs(keys) do keySet[selected] = true end
        local payload = {}
        local bp = Player:FindFirstChild("Backpack")
        if not bp then return nil, "Backpack not found" end
        for _, v in ipairs(bp:GetChildren()) do
            local petKey = v:GetAttribute("Pet")
            if petKey and keySet[petKey] then
                local pid = v:GetAttribute("PetId")
                if pid then table.insert(payload, {Category="Pets", ItemKey=pid, Count=1}) end
            end
        end
        if #payload > 0 then return chunkPayload(payload, 20, math.max(1, math.ceil(#payload / 20))), "Pets " .. tostring(#payload) .. " item(s)" end
        return nil, "Pet not found"
    elseif cat == "Fruits" then
        local fruits = collectMailFruits(key)
        if #fruits == 0 then return nil, "No matching non-favorite fruits" end
        table.sort(fruits, function(a, b)
            if a.value == b.value then return a.weight < b.weight end
            return a.value < b.value
        end)
        local targetValue = parseMoneyInput(Cfg.mailFruitValueTarget)
        local selected, totalValue = {}, 0
        local maxItems = math.min(#fruits, count)
        if targetValue > 0 then
            for _, fruit in ipairs(fruits) do
                if #selected >= maxItems then break end
                table.insert(selected, fruit)
                totalValue += fruit.value or 0
                if totalValue >= targetValue then break end
            end
            if totalValue <= 0 then return nil, "Fruit value unreadable; aborting value send" end
            if totalValue < targetValue then return nil, "Not enough fruit value for target" end
        else
            for i = 1, math.min(count, maxItems) do
                table.insert(selected, fruits[i])
                totalValue += fruits[i].value or 0
            end
        end
        if #selected == 0 then return nil, "No fruits selected" end
        local payload = {}
        for _, fruit in ipairs(selected) do
            table.insert(payload, {Category="HarvestedFruits", ItemKey=fruit.id, Count=1})
        end
        local summary = string.format("%d fruit | %s", #payload, formatMoneyCompact(totalValue))
        if targetValue > 0 then summary = summary .. " / target " .. formatMoneyCompact(targetValue) end
        local chunkSize = userBatchSize or 999999
        return chunkPayload(payload, chunkSize, math.max(1, math.ceil(#payload / chunkSize))), summary
    end
    return nil, "Unsupported category"
end

local function mailNotify(message, delay)
    if Speed_Library and type(Speed_Library.SetNotification) == "function" then
        local ok = pcall(function()
            Speed_Library:SetNotification({ Title = "Auto Mail", Description = tostring(message), Content = "", Delay = delay or 3 })
        end)
        if ok then return end
    end
    warn("[Auto Mail] " .. tostring(message))
end

local function mailFruitIdSet()
    local set = {}
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if not bp then return set end
    for _, inst in ipairs(bp:GetChildren()) do
        if inst:IsA("Tool") and inst:GetAttribute("HarvestedFruit") == true then
            local id = inst:GetAttribute("Id") or inst:GetAttribute("ID") or inst:GetAttribute("FruitId") or inst:GetAttribute("UUID")
            if id then set[tostring(id)] = true end
        end
    end
    return set
end

local function isFruitMailPayload(payload)
    for _, item in ipairs(payload or {}) do
        if item.Category ~= "HarvestedFruits" then return false end
    end
    return payload and #payload > 0
end

local function verifyFruitBatchRemoved(payload)
    local set = mailFruitIdSet()
    local still = 0
    for _, item in ipairs(payload or {}) do
        if set[tostring(item.ItemKey)] then still += 1 end
    end
    return still
end

local function sendMailBatches(batches, summary, notify)
    if not batches or #batches == 0 then return false, "No payload" end
    for i, payload in ipairs(batches) do
        if not Cfg.autoMailSend then return false, "Mail send cancelled" end
        local ok, success, msg = pcall(function()
            return Networking.Mailbox.SendBatch:Fire(Cfg.mailTargetId, payload, "")
        end)
        if not ok then
            if notify then mailNotify("Mail failed: Try again", 3) end
            return false, "Try again"
        end
        if success == false then
            if notify then mailNotify("Mail failed: " .. tostring(msg or "Invalid items"), 3) end
            return false, tostring(msg or "Invalid items")
        end
        if isFruitMailPayload(payload) then
            task.wait(1.25)
            local still = verifyFruitBatchRemoved(payload)
            if still == #payload then
                if notify then mailNotify("Fruit mail silent reject: batch " .. tostring(i) .. " not removed", 4) end
                return false, "Fruit silent reject"
            elseif still > 0 then
                if notify then mailNotify("Fruit mail partial: " .. tostring(still) .. " still in bag", 4) end
                return false, "Fruit partial send"
            end
        end
        if i < #batches then
            local waited = 0
            local delaySeconds = math.max(Cfg.mailDelay, 9)
            while waited < delaySeconds do
                if not Cfg.autoMailSend then return false, "Mail send cancelled" end
                task.wait(0.25)
                waited += 0.25
            end
        end
    end
    if notify then mailNotify("Sent " .. tostring(summary or "mail"), 3) end
    return true, summary
end

local mailSendingActive = false
local function runMailSendRequest()
    if mailSendingActive then
        mailNotify("Mail already running", 2)
        return
    end
    mailSendingActive = true

    local ok, err = xpcall(function()
        local targetId = tonumber(Cfg.mailTargetId) or 0
        if targetId <= 0 then
            mailNotify("No valid target set", 3)
        elseif Cfg.mailCategory ~= "Fruits" and #mailSelectedKeys(Cfg.mailItemKey) == 0 then
            mailNotify("Set Item first", 3)
        else
            local batches, summary = buildMailPayloadBatches()
            if not batches then
                mailNotify(tostring(summary or "Item not found"), 3)
            else
                sendMailBatches(batches, summary, true)
            end
        end
    end, debug.traceback)

    if not ok then
        warn("[Auto Mail] Runner crashed: " .. tostring(err))
        mailNotify("Mail runner recovered after error", 4)
    end

    mailSendingActive = false
    if _G._GAG2MailToggleSet then _G._GAG2MailToggleSet(false) else Cfg.autoMailSend = false end
end

-- ==================== AUTO MAIL CLAIM ====================
local function tryClaimMailInbox()
    local mb = Networking and Networking.Mailbox
    if not (mb and mb.OpenInbox and mb.Claim) then return false, "Mailbox claim remotes unavailable" end

    local totalClaimed, totalFailed = 0, 0
    local seen = {}
    for pass = 1, 5 do
        local okInbox, inbox = pcall(function()
            return mb.OpenInbox:Fire()
        end)
        if not okInbox or type(inbox) ~= "table" then
            return totalClaimed > 0, "OpenInbox failed after claimed=" .. tostring(totalClaimed)
        end

        local passCount, passClaimed = 0, 0
        for mailId, _ in pairs(inbox) do
            if not Cfg.autoMailClaim then break end
            if (type(mailId) == "string" or type(mailId) == "number") and not seen[tostring(mailId)] then
                seen[tostring(mailId)] = true
                passCount += 1
                local okClaim, success = pcall(function()
                    return mb.Claim:Fire(mailId)
                end)
                if okClaim and success ~= false then
                    totalClaimed += 1
                    passClaimed += 1
                else
                    totalFailed += 1
                end
                task.wait(0.18)
                if passCount >= 60 then break end
            end
        end

        if passCount == 0 or passClaimed == 0 then break end
        task.wait(0.75)
    end

    return totalClaimed > 0, string.format("claimed=%d failed=%d", totalClaimed, totalFailed)
end

_G._ClaimMailNow = function()
    return tryClaimMailInbox()
end

task.spawn(function()
    while not Speed_Library.Unloaded do
        if Cfg.autoMailClaim then
            pcall(tryClaimMailInbox)
        end
        task.wait(10)
    end
end)

-- ==================== STACK FARM MANAGER ====================-- ==================== STACK FARM MANAGER ====================
do
    _G._SFM_Tasks = {}
    _G._SFM_Register = function(id, fn)
        _G._SFM_Tasks[id] = fn
    end
    task.spawn(function()
        while not Speed_Library.Unloaded do
            task.wait(0.2)
            if Cfg.stackFarm then
                local order = {}
                for id, fn in pairs(_G._SFM_Tasks) do
                    local prio = (Cfg.sfPriority[id] or 99)
                    table.insert(order, { id = id, fn = fn, prio = prio })
                end
                table.sort(order, function(a, b) return a.prio < b.prio end)
                for _, item in ipairs(order) do
                    if Speed_Library.Unloaded then break end
                    pcall(item.fn)
                    task.wait(0.3)
                end
            end
        end
    end)
end

local _lastSprinklerAnchor = nil
local _lastSprinklerAt = 0
local _lastSprinklerNames = {}
local _sprinklerActiveCache = { t = 0, value = false }

local function findWaterCanTool(preferred)
    local prefSet = {}
    if type(preferred) == "table" then
        for _, name in ipairs(preferred) do prefSet[tostring(name)] = true end
    elseif type(preferred) == "string" and preferred ~= "" then
        prefSet[preferred] = true
    end
    local function allowed(canName)
        if next(prefSet) == nil then return true end
        return prefSet[tostring(canName)] == true
    end
    local best
    local function scan(cont)
        if not cont then return nil end
        for _, tool in ipairs(cont:GetChildren()) do
            if tool:IsA("Tool") then
                local canName = tool:GetAttribute("WateringCan")
                if canName and allowed(canName) then
                    if canName == "Super Watering Can" then return tool end
                    best = best or tool
                end
            end
        end
        return best
    end
    local char = LocalPlayer.Character
    local found = scan(char)
    if found then return found end
    return scan(LocalPlayer:FindFirstChild("Backpack"))
end

local function equipTool(tool)
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if tool and hum and tool.Parent ~= char then
        hum:EquipTool(tool)
        task.wait(0.15)
    end
    return tool and tool.Parent == char
end

local function selectedSprinklerActive(forceScan)
    if not forceScan and os.clock() - (_sprinklerActiveCache.t or 0) < 5 then
        return _sprinklerActiveCache.value == true
    end

    local selected = Cfg.selSprinkler
    if type(selected) ~= "table" or #selected == 0 then
        _sprinklerActiveCache.t = os.clock()
        _sprinklerActiveCache.value = false
        return false
    end
    local plot = getMyPlot()
    if not plot then
        _sprinklerActiveCache.t = os.clock()
        _sprinklerActiveCache.value = false
        return false
    end

    local wanted = {}
    for _, name in ipairs(selected) do
        name = tostring(name)
        wanted[name] = true
        wanted[name:gsub(" Sprinkler", "")] = true
    end

    local function sprinklerTimerRemaining(inst)
        local attrs = inst:GetAttributes()
        local directKeys = { "TimeLeft", "TimeRemaining", "RemainingTime", "SecondsRemaining", "LifetimeRemaining", "DurationLeft", "Remaining" }
        for _, k in ipairs(directKeys) do
            local v = tonumber(attrs[k])
            if v then return v end
        end
        local absoluteKeys = { "ExpireTime", "ExpiresAt", "EndTime", "DestroyTime", "RemoveAt" }
        for _, k in ipairs(absoluteKeys) do
            local v = tonumber(attrs[k])
            if v then
                local now = v > 1000000 and os.time() or os.clock()
                return math.max(0, v - now)
            end
        end
        for _, ui in ipairs(inst:GetDescendants()) do
            if ui.Name == "SprinklerTimerUI" and ui:IsA("BillboardGui") then
                for _, d in ipairs(ui:GetDescendants()) do
                    if (d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox")) and type(d.Text) == "string" then
                        local m, s = d.Text:match("^(%d+):(%d%d)$")
                        if m and s then return tonumber(m) * 60 + tonumber(s) end
                        local sec = tonumber(d.Text:match("^(%d+)%s*s$"))
                        if sec then return sec end
                    end
                end
            end
        end
        for _, child in ipairs(inst:GetChildren()) do
            if child:IsA("NumberValue") or child:IsA("IntValue") then
                local n = child.Name:lower()
                if n:find("time") or n:find("remain") or n:find("duration") then
                    return tonumber(child.Value)
                end
            end
        end
        return nil
    end

    local active = false
    for _, inst in ipairs(plot:GetDescendants()) do
        if inst:IsA("Model") then
            local attrs = inst:GetAttributes()
            local itemName = tostring(attrs.SprinklerName or attrs.ItemName or attrs.SprinklerType or attrs.Type or inst.Name)
            local looksLikeSprinkler = attrs.SprinklerName ~= nil or attrs.SprinklerId ~= nil or attrs.SprinklerType ~= nil or itemName:lower():find("sprinkler") ~= nil
            if looksLikeSprinkler and (wanted[itemName] or wanted[itemName:gsub(" Sprinkler", "")] or Cfg.autoSprinklerAll) then
                local remaining = sprinklerTimerRemaining(inst)
                if remaining == nil or remaining > 0 then
                    active = true
                    break
                end
            end
        end
    end
    _sprinklerActiveCache.t = os.clock()
    _sprinklerActiveCache.value = active
    return active
end

local function useWaterCanAt(pos)
    if not pos then return false end
    local tool = findWaterCanTool(Cfg.selWaterCan)
    if not tool then dlog("SPRINKLER", "watercan missing") return false end
    equipTool(tool)
    tool = findWaterCanTool(Cfg.selWaterCan) or tool
    local canName = tool:GetAttribute("WateringCan")
    if not canName then return false end
    local ok = pcall(function()
        Networking.WateringCan.UseWateringCan:Fire(pos - Vector3.new(0, 0.3, 0), canName, tool)
    end)
    if ok then dlog("SPRINKLER", "watered", canName, pos) end
    return ok
end

local function getSavedSprinklerVector(plotOverride)
    local p = Cfg.sprinklerSavedPosition
    if type(p) ~= "table" then return nil, "missing" end

    local plot = plotOverride or getMyPlot()
    local pivot = plot and plot:GetPivot()

    -- Source of truth: plot-local CFrame offset. On rejoin/autoexecute, wait for
    -- the current plot first; never use stale world coordinates while plot is not ready.
    local localPos = p.localPos
    if type(localPos) == "table" and tonumber(localPos.x) and tonumber(localPos.y) and tonumber(localPos.z) then
        if not pivot then return nil, "plot_not_ready" end
        return pivot:PointToWorldSpace(Vector3.new(tonumber(localPos.x), tonumber(localPos.y), tonumber(localPos.z))), "local"
    end

    -- Older APS saves used plain world-space offset from plot pivot, not CFrame-local.
    -- Do NOT feed this through PointToWorldSpace or it becomes wrong on many plots.
    local rel = p.rel
    if type(rel) == "table" and tonumber(rel.x) and tonumber(rel.y) and tonumber(rel.z) then
        if not pivot then return nil, "plot_not_ready" end
        return pivot.Position + Vector3.new(tonumber(rel.x), tonumber(rel.y), tonumber(rel.z)), "rel"
    end

    -- Legacy absolute fallback only for old configs that have no local position yet.
    if tonumber(p.x) and tonumber(p.y) and tonumber(p.z) then
        return Vector3.new(tonumber(p.x), tonumber(p.y), tonumber(p.z)), "legacy"
    end
    return nil, "invalid"
end

local function getPlotIdFromPlot(plot)
    return plot and tonumber(string.match(plot.Name, "%d+")) or nil
end

local function normalizeSprinklerName(name)
    name = tostring(name or "")
    return name:gsub("%s+Sprinkler$", "")
end

local function findSprinklerToolByName(attrName)
    local wantedFull = tostring(attrName or "")
    local wantedShort = normalizeSprinklerName(wantedFull)
    local function matches(tool)
        if not tool or not tool:IsA("Tool") then return false end
        local sprinklerAttr = tostring(tool:GetAttribute("Sprinkler") or "")
        local itemName = tostring(tool:GetAttribute("ItemName") or tool:GetAttribute("Gear") or tool.Name or "")
        return sprinklerAttr == wantedFull
            or sprinklerAttr == wantedShort
            or normalizeSprinklerName(sprinklerAttr) == wantedShort
            or itemName == wantedFull
            or itemName == wantedShort
            or normalizeSprinklerName(itemName) == wantedShort
    end
    local function checkIn(cont)
        if not cont then return nil end
        for _, v in pairs(cont:GetChildren()) do
            if matches(v) then return v end
        end
        return nil
    end
    return checkIn(LocalPlayer.Character) or checkIn(LocalPlayer:FindFirstChild("Backpack"))
end

local function placeOneSprinklerAt(pos, sprinklerName)
    if not pos or not sprinklerName or sprinklerName == "" or sprinklerName == "Select Options" then return false end
    local plot = getMyPlot()
    local plotId = getPlotIdFromPlot(plot)
    if not plotId then return false end
    local tool = findSprinklerToolByName(sprinklerName)
    if not tool then return false end
    equipTool(tool)
    tool = findSprinklerToolByName(sprinklerName) or tool
    Networking.Place.PlaceSprinkler:Fire(pos, sprinklerName, tool, plotId)
    _lastSprinklerAnchor = pos
    _lastSprinklerAt = os.clock()
    _lastSprinklerNames = { sprinklerName }
    _sprinklerActiveCache.t = 0
    return true
end

local function findSeedToolByName(seedName)
    local function checkIn(cont)
        if not cont then return nil end
        for _, t in pairs(cont:GetChildren()) do
            if t:IsA("Tool") and t:GetAttribute("SeedTool") == seedName then return t end
        end
        return nil
    end
    return checkIn(LocalPlayer:FindFirstChild("Backpack")) or checkIn(LocalPlayer.Character)
end

local function plantOneSeedAt(pos, seedName)
    if not pos or not seedName or seedName == "" or seedName == "Select Options" then return false end
    local tool = findSeedToolByName(seedName)
    if not tool then return false end
    Networking.Plant.PlantSeed:Fire(pos, tool:GetAttribute("SeedTool"), tool)
    State.planted = (State.planted or 0) + 1
    return true
end

local APS_SPRINKLER_RADIUS = {
    ["Common Sprinkler"] = 20,
    ["Uncommon Sprinkler"] = 25,
    ["Rare Sprinkler"] = 30,
    ["Legendary Sprinkler"] = 40,
    ["Super Sprinkler"] = 55,
}

local function getApsSprinklerPlantRadius(sprinklerName)
    sprinklerName = tostring(sprinklerName or "")
    for name, diameter in pairs(APS_SPRINKLER_RADIUS) do
        if sprinklerName:find(name, 1, true) then
            return math.max(3, diameter / 2)
        end
    end
    return 15
end

local function isApsUsablePlantArea(area)
    if not area or not area:IsA("BasePart") then return false end
    -- Match normal auto-plant behavior: tagged green grass/decor parts can appear
    -- as PlantArea, but seeds should only be sent to soil/dirt-like areas.
    local c = area.Color
    if c and c.G > c.R and c.G > c.B then return false end
    return true
end

local function getApsPlantAreas(plot)
    local areas = {}
    if not plot then return areas end
    for _, area in pairs(game:GetService("CollectionService"):GetTagged("PlantArea")) do
        if area:IsDescendantOf(plot) and isApsUsablePlantArea(area) then
            areas[#areas + 1] = area
        end
    end
    return areas
end

local function getApsExistingPlantPositions(plot)
    local out = {}
    local plantsFolder = plot and plot:FindFirstChild("Plants")
    if plantsFolder then
        for _, p in pairs(plantsFolder:GetChildren()) do
            local pos = p:GetPivot().Position
            out[#out + 1] = Vector2.new(pos.X, pos.Z)
        end
    end
    return out
end

local function makeBatchPlantPositions(center, amount, sprinklerName)
    amount = math.max(1, math.floor(tonumber(amount) or 1))
    local radius = getApsSprinklerPlantRadius(sprinklerName)
    local plot = getMyPlot()
    local areas = getApsPlantAreas(plot)
    if #areas == 0 then return {} end

    local candidates = {}
    local occupiedPositions = getApsExistingPlantPositions(plot)
    local center2 = Vector2.new(center.X, center.Z)
    local spacing = 3

    for _, area in ipairs(areas) do
        local cy = area.Position.Y
        local sx, sz = area.Size.X, area.Size.Z
        local ox = -sx / 2 + 2
        while ox <= sx / 2 - 2 do
            local oz = -sz / 2 + 2
            while oz <= sz / 2 - 2 do
                local world = area.CFrame:PointToWorldSpace(Vector3.new(ox, 0, oz))
                local p2 = Vector2.new(world.X, world.Z)
                local occupied = false
                for _, pp in ipairs(occupiedPositions) do
                    if (p2 - pp).Magnitude < 2 then occupied = true; break end
                end
                if not occupied then
                    local dist = (p2 - center2).Magnitude
                    candidates[#candidates + 1] = {
                        pos = Vector3.new(world.X, cy, world.Z),
                        dist = dist,
                        inRadius = dist <= radius,
                    }
                    occupiedPositions[#occupiedPositions + 1] = p2
                end
                oz = oz + spacing
            end
            ox = ox + spacing
        end
    end

    table.sort(candidates, function(a, b) return a.dist < b.dist end)

    local positions = {}
    for _, item in ipairs(candidates) do
        if item.inRadius then
            positions[#positions + 1] = item.pos
            if #positions >= amount then break end
        end
    end

    -- If the saved sprinkler center is slightly off the dirt tile, strict radius
    -- filtering can produce zero spots. Still keep planting on dirt by using the
    -- nearest valid PlantArea spots instead of falling back to raw circle points.
    if #positions == 0 then
        traceAPS("aps_no_in_radius_spots_fallback", "areas=" .. tostring(#areas) .. " candidates=" .. tostring(#candidates) .. " radius=" .. tostring(radius))
        for _, item in ipairs(candidates) do
            positions[#positions + 1] = item.pos
            if #positions >= amount then break end
        end
    end

    return positions
end

local function plantSeedBatchAt(center, seedName, amount, sprinklerName)
    local planted = 0
    local positions = makeBatchPlantPositions(center, amount, sprinklerName)
    for _, plantPos in ipairs(positions) do
        if not Cfg.autoPlantScan then break end
        if not plantOneSeedAt(plantPos, seedName) then break end
        planted += 1
        task.wait(tonumber(Cfg.apsPlantDelay) or 0.05)
    end
    return planted
end

local function thresholdPass(mode, threshold, kg)
    threshold = tonumber(threshold) or 0
    kg = tonumber(kg)
    if not kg then return false end
    if mode == "Below" then return kg <= threshold end
    return kg >= threshold
end

local function collectCurrentPlantIds(cropName)
    local ids = { _plants = {}, _fruits = {} }
    cropName = tostring(cropName or "")
    local plot = getMyPlot()
    local plantsF = plot and plot:FindFirstChild("Plants")
    if not plantsF then return ids end
    for _, plant in pairs(plantsF:GetChildren()) do
        if plant:IsA("Model") and (cropName == "" or tostring(plant:GetAttribute("SeedName") or "") == cropName) then
            ids._plants[plant] = true
            local plantId = plant:GetAttribute("PlantId")
            if plantId then ids[tostring(plantId)] = true end
            local fruitsF = plant:FindFirstChild("Fruits")
            if fruitsF then
                for _, fruit in pairs(fruitsF:GetChildren()) do
                    ids._fruits[fruit] = true
                    local fruitId = fruit:GetAttribute("FruitId")
                    if fruitId then ids["fruit:" .. tostring(fruitId)] = true end
                end
            end
        end
    end
    return ids
end

local function scanCropForThreshold(cropName, threshold, mode, ignoredPlantIds, webhookSeen, minPlantedAt)
    cropName = tostring(cropName or "")
    local plot = getMyPlot()
    local plantsF = plot and plot:FindFirstChild("Plants")
    if cropName == "" or not plantsF then return nil end

    for _, plant in pairs(plantsF:GetChildren()) do
        local plantId = plant:GetAttribute("PlantId")
        local plantIgnored = ignoredPlantIds and ((ignoredPlantIds._plants and ignoredPlantIds._plants[plant]) or (plantId and ignoredPlantIds[tostring(plantId)]))
        if plant:IsA("Model") and tostring(plant:GetAttribute("SeedName") or "") == cropName then
            local seedName = plant:GetAttribute("SeedName") or ""
            local plantedAt = tonumber(plant:GetAttribute("PlantedAt"))
            local plantedAfterStart = not minPlantedAt or (plantedAt and plantedAt >= (tonumber(minPlantedAt) or 0) - 2)
            local fruitsF = plant:FindFirstChild("Fruits")

            -- Multi-harvest path: mirror auto collect by scanning fruit children only.
            if fruitsF then
                for _, fruit in pairs(fruitsF:GetChildren()) do
                    local fruitId = fruit:GetAttribute("FruitId")
                    local ready = isFruitReady(fruit)
                    local fruitIgnored = ignoredPlantIds and ((ignoredPlantIds._fruits and ignoredPlantIds._fruits[fruit]) or (fruitId and ignoredPlantIds["fruit:" .. tostring(fruitId)]))
                    if ready and not fruitIgnored then
                        local kg = getFruitDisplayKg(fruit, seedName)
                        local pass = thresholdPass(mode, threshold, kg)
                        local key = tostring(plantId or plant:GetFullName()) .. ":" .. tostring(fruitId or fruit:GetFullName())
                        if webhookSeen and not webhookSeen[key] then
                            webhookSeen[key] = true
                            _G._sendApsWebhook(pass and "success" or "below", {
                                cropName = seedName,
                                kg = kg,
                                mutation = tostring(fruit:GetAttribute("Mutation") or ""),
                                type = "multi",
                                newBatch = tostring(not fruitIgnored),
                                plantedAt = plantedAt,
                                batchStartedAt = minPlantedAt,
                                plantId = plantId,
                                fruitId = fruitId,
                            })
                        end
                        if pass then
                            local mut = tostring(fruit:GetAttribute("Mutation") or "")
                            return {
                                type = "multi",
                                plant = plant,
                                fruit = fruit,
                                plantId = plant:GetAttribute("PlantId"),
                                fruitId = fruitId,
                                mutation = mut == "" and "None" or mut,
                                kg = kg,
                                ready = true,
                            }
                        end
                    end
                end

            -- Single-harvest path: mirror auto collect by treating the plant as the fruit.
            elseif not plantIgnored and plantedAfterStart and isFruitReady(plant) then
                local kg = getFruitDisplayKg(plant, seedName)
                local pass = thresholdPass(mode, threshold, kg)
                local key = tostring(plantId or plant:GetFullName()) .. ":single"
                if webhookSeen and not webhookSeen[key] then
                    webhookSeen[key] = true
                    _G._sendApsWebhook(pass and "success" or "below", {
                        cropName = seedName,
                        kg = kg,
                        mutation = tostring(plant:GetAttribute("Mutation") or ""),
                        type = "single",
                        newBatch = tostring(plantedAfterStart),
                        plantedAt = plantedAt,
                        batchStartedAt = minPlantedAt,
                        plantId = plantId,
                        fruitId = nil,
                    })
                end
                if pass then
                    local mut = tostring(plant:GetAttribute("Mutation") or "")
                    return {
                        type = "single",
                        plant = plant,
                        fruit = plant,
                        plantId = plant:GetAttribute("PlantId"),
                        fruitId = "",
                        mutation = mut == "" and "None" or mut,
                        kg = kg,
                        ready = true,
                    }
                end
            end
        end
    end
    return nil
end

local _autoPlantScanBusy = false
local _lastApsMissingPositionTrace = 0
task.spawn(function()
    while not Speed_Library.Unloaded do
        if not Cfg.autoPlantScan or _autoPlantScanBusy then
            task.wait(Cfg.autoPlantScan and 0.05 or 0.05)
        else
            _autoPlantScanBusy = true
            local ok, err = pcall(function()
                local plot = waitForMyPlot(10)
                local pos, posReason = getSavedSprinklerVector(plot)
                if not pos then
                    if posReason == "missing" or posReason == "invalid" then
                        setStatus("Auto Plant Scan waiting — saved sprinkler position missing/invalid")
                        if os.clock() - _lastApsMissingPositionTrace >= 5 then
                            _lastApsMissingPositionTrace = os.clock()
                            traceAPS("position_missing_keep_resume", posReason)
                        end
                        -- Keep resume state in memory/config as-is. Do not assign Cfg here,
                        -- because __newindex schedules a config save every retry and floods logs.
                    else
                        setStatus("Auto Plant Scan waiting for plot before using saved position")
                    end
                    task.wait(0.5)
                    return
                end

                Cfg.disableTp = true
                Cfg.disablePlantTp = true
                Cfg.autoTpToSprinkler = false
                Cfg.sprinklerPlaceMode = "Saved Position"

                setStatus("Auto Plant Scan: sending reverse")
                sendReversePacket()
                task.wait(0.05)

                setStatus("Auto Plant Scan: placing sprinkler")
                if not placeOneSprinklerAt(pos, Cfg.apsSprinkler) then
                    setStatus("Auto Plant Scan: sprinkler place failed — retrying with saved position")
                    Cfg.autoPlantScan = true
                    Cfg.apsResume = true
                    saveConfigNow()
                    task.wait(0.5)
                    return
                end
                task.wait(1)

                local ignoredPlantIds = collectCurrentPlantIds(Cfg.apsCropName)

                setStatus("Auto Plant Scan: planting seed batch")
                local plantAmount = math.max(1, math.floor(tonumber(Cfg.apsPlantAmount) or 24))
                local batchStartedAt = math.floor((workspace.GetServerTimeNow and workspace:GetServerTimeNow()) or os.time())
                local plantedCount = plantSeedBatchAt(pos, Cfg.apsSeedName, plantAmount, Cfg.apsSprinkler)
                traceAPS("plant_batch_done", "planted=" .. tostring(plantedCount) .. " amount=" .. tostring(plantAmount) .. " seed=" .. tostring(Cfg.apsSeedName) .. " batchStartedAt=" .. tostring(batchStartedAt))
                if plantedCount <= 0 then
                    Cfg.autoPlantScan = false
                    Cfg.apsResume = false
                    saveConfigNow()
                    traceAPS("stopped_no_seed_or_positions")
                    setStatus("Auto Plant Scan stopped — missing seed/tool/valid plant spots")
                    return
                end
                setStatus(("Auto Plant Scan: planted %d/%d, scanning soon"):format(plantedCount, plantAmount))

                local found = nil
                local scanSeconds = math.max(8, tonumber(Cfg.apsScanWindow) or 0.75)
                local scanDeadline = os.clock() + scanSeconds
                local webhookSeen = {}
                traceAPS("scan_start", "seconds=" .. tostring(scanSeconds) .. " crop=" .. tostring(Cfg.apsCropName) .. " threshold=" .. tostring(Cfg.apsThreshMode) .. " " .. tostring(Cfg.apsWeightThresh))
                repeat
                    found = scanCropForThreshold(Cfg.apsCropName, Cfg.apsWeightThresh, Cfg.apsThreshMode, ignoredPlantIds, webhookSeen, batchStartedAt)
                    if found then break end
                    task.wait(0.05)
                until os.clock() >= scanDeadline or not Cfg.autoPlantScan
                if not found and Cfg.autoPlantScan and not (webhookSeen and next(webhookSeen) ~= nil) then
                    local extraDeadline = os.clock() + 12
                    traceAPS("scan_no_candidate_grace", "extra=12 crop=" .. tostring(Cfg.apsCropName))
                    setStatus("Auto Plant Scan: waiting for crop/KG before rejoin")
                    repeat
                        found = scanCropForThreshold(Cfg.apsCropName, Cfg.apsWeightThresh, Cfg.apsThreshMode, ignoredPlantIds, webhookSeen, batchStartedAt)
                        if found then break end
                        task.wait(0.10)
                    until os.clock() >= extraDeadline or not Cfg.autoPlantScan or (webhookSeen and next(webhookSeen) ~= nil)
                end
                if found then
                    traceAPS("scan_success", "kg=" .. tostring(found.kg) .. " type=" .. tostring(found.type) .. " plantId=" .. tostring(found.plantId) .. " fruitId=" .. tostring(found.fruitId))
                    sendCancelReversePacket()
                    Cfg.autoPlantScan = false
                    Cfg.apsResume = false
                    saveConfigNow()
                    setStatus(("Auto Plant Scan success: %s %.2fkg %s [%s] — stopped"):format(tostring(Cfg.apsCropName), tonumber(found.kg) or 0, tostring(found.mutation or "None"), tostring(found.type or "?")))
                    return
                end

                if not Cfg.autoPlantScan then
                    Cfg.apsResume = false
                    saveConfigNow()
                    traceAPS("manual_stop_before_rejoin")
                    setStatus("Auto Plant Scan stopped manually")
                    return
                end

                traceAPS("scan_fail_rejoin", "seen=" .. tostring(webhookSeen and next(webhookSeen) ~= nil) .. " scannedFor=" .. tostring(scanSeconds))
                -- No Discord webhook for no-candidate fail_rejoin; keep this in trace log only to avoid noisy alerts.
                setStatus("Auto Plant Scan: threshold not found in current batch — rejoining")
                Cfg.autoPlantScan = true
                Cfg.apsResume = true
                local reverseOk = sendReversePacket()
                if not reverseOk then
                    Cfg.apsResume = false
                    saveConfigNow()
                    traceAPS("rejoin_abort_reverse_failed_before_save")
                    setStatus("Auto Plant Scan stopped — reverse safety failed before rejoin")
                    return
                end
                traceAPS("rejoin_path_before_save")
                saveConfigNow()
                local delay = math.max(7, tonumber(Cfg.apsRejoinDelay) or 7)
                traceAPS("rejoin_wait", "delay=" .. tostring(delay))
                task.wait(delay)
                if not Cfg.autoPlantScan then
                    Cfg.apsResume = false
                    saveConfigNow()
                    traceAPS("manual_stop_during_rejoin_wait")
                    setStatus("Auto Plant Scan stopped manually before rejoin")
                    return
                end
                traceAPS("rejoin_reverse_safety_before_teleport")
                reverseOk = sendReversePacket()
                if not reverseOk then
                    Cfg.apsResume = false
                    saveConfigNow()
                    traceAPS("rejoin_abort_reverse_failed_before_teleport")
                    setStatus("Auto Plant Scan stopped — reverse safety failed before teleport")
                    return
                end
                task.wait(0.25)
                traceAPS("teleport_attempt")
                local tpOk, tpErr = pcall(function()
                    TeleportService:Teleport(game.PlaceId, LocalPlayer)
                end)
                traceAPS("teleport_returned", "ok=" .. tostring(tpOk) .. " err=" .. tostring(tpErr))
                if not tpOk then
                    setStatus("Auto Plant Scan teleport failed — retrying")
                    task.wait(3)
                    if not Cfg.autoPlantScan then
                        Cfg.apsResume = false
                        saveConfigNow()
                        traceAPS("manual_stop_before_retry_teleport")
                        setStatus("Auto Plant Scan stopped manually before teleport retry")
                        return
                    end
                    traceAPS("rejoin_reverse_safety_before_retry_teleport")
                    reverseOk = sendReversePacket()
                    if not reverseOk then
                        Cfg.apsResume = false
                        saveConfigNow()
                        traceAPS("rejoin_abort_reverse_failed_before_retry_teleport")
                        setStatus("Auto Plant Scan stopped — reverse safety failed before teleport retry")
                        return
                    end
                    task.wait(0.25)
                    TeleportService:Teleport(game.PlaceId, LocalPlayer)
                end
            end)
            if not ok then
                traceAPS("worker_error", tostring(err))
                setStatus("Auto Plant Scan error: " .. tostring(err))
            end
            _autoPlantScanBusy = false
            task.wait(1)
        end
    end
end)

-- ==================== AUTO SPRINKLER ====================
task.spawn(function()
    local function findSprinklerTool(attrName)
        local function checkIn(cont)
            for _, v in pairs(cont:GetChildren()) do
                if v:IsA("Tool") and v:GetAttribute("Sprinkler") == attrName then return v end
            end
            return nil
        end
        local char = LocalPlayer.Character
        local tool = char and checkIn(char)
        if tool then return tool end
        local bp = LocalPlayer:FindFirstChild("Backpack")
        return bp and checkIn(bp)
    end

    local function equipSprinklerTool(tool)
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if tool and hum and tool.Parent ~= char then
            hum:EquipTool(tool)
            task.wait(0.15)
        end
    end

    local function getPlotId(plot)
        return tonumber(string.match(plot.Name, "%d+"))
    end

    local function getPlacePosition()
        if Cfg.sprinklerPlaceMode == "Saved Position" then
            local p = Cfg.sprinklerSavedPosition
            if type(p) == "table" and tonumber(p.x) and tonumber(p.y) and tonumber(p.z) then
                return Vector3.new(tonumber(p.x), tonumber(p.y), tonumber(p.z))
            end
        elseif Cfg.sprinklerPlaceMode == "At Plants" then
            local plot = getMyPlot()
            if plot then
                local plantsF = plot:FindFirstChild("Plants")
                if plantsF then
                    local fallbackPos = nil
                    for _, plant in pairs(plantsF:GetChildren()) do
                        local pp = plant.PrimaryPart or plant:FindFirstChildWhichIsA("BasePart")
                        if pp then
                            fallbackPos = fallbackPos or pp.Position
                            local seedName = plant:GetAttribute("SeedName") or ""
                            if seedName ~= "" and msMatch(Cfg.selSprinklerPlant, seedName) then
                                return pp.Position
                            end
                        end
                    end
                    return fallbackPos
                end
            end
        end
        local hrp = getHRP()
        return hrp and hrp.Position
    end

    local _sprinklerBusy = false
    local _lastSprinklerCycle = 0
    local _sprinklerTeleportedThisToggle = false

    local function doSprinklerCycle(force)
        if not (Cfg.autoSprinkler or Cfg.autoSprinklerAll) then return end
        if _sprinklerBusy then return end
        local hasActiveSprinkler = selectedSprinklerActive(true)
        if not force and hasActiveSprinkler then return end
        if not force and os.clock() - _lastSprinklerCycle < 1 then return end
        local selected = Cfg.selSprinkler
        if type(selected) ~= "table" or #selected == 0 then return end

        local plot = getMyPlot()
        if not plot then return end
        local plotId = getPlotId(plot)
        if not plotId then return end

        local basePos = getPlacePosition()
        if not basePos then return end
        _sprinklerBusy = true
        local firstPlacedPos = nil
        local placedNames = {}

        for i, spName in ipairs(selected) do
            local tool = findSprinklerTool(spName)
            if tool then
                equipSprinklerTool(tool)
                tool = findSprinklerTool(spName) or tool
                local offsets = {
                    Vector3.new(0, 0, 0),
                    Vector3.new(1.25, 0, 0),
                    Vector3.new(-1.25, 0, 0),
                    Vector3.new(0, 0, 1.25),
                    Vector3.new(0, 0, -1.25),
                    Vector3.new(0.9, 0, 0.9),
                    Vector3.new(-0.9, 0, 0.9),
                    Vector3.new(0.9, 0, -0.9),
                    Vector3.new(-0.9, 0, -0.9),
                }
                local pos = basePos + (offsets[i] or Vector3.new((i - 1) * 1.25, 0, 0))
                Networking.Place.PlaceSprinkler:Fire(pos, spName, tool, plotId)
                firstPlacedPos = firstPlacedPos or pos
                table.insert(placedNames, spName)
                dlog("SPRINKLER", "placed", spName, pos)
                task.wait(1)
            else
                dlog("SPRINKLER", "missing tool", spName)
            end
        end
        if firstPlacedPos then
            _lastSprinklerAnchor = firstPlacedPos
            _lastSprinklerAt = os.clock()
            _lastSprinklerNames = placedNames
            _sprinklerActiveCache.t = 0
            if Cfg.autoTpToSprinkler and not Cfg.disableTp and not _sprinklerTeleportedThisToggle then
                local hrp = getHRP()
                if hrp then
                    hrp.CFrame = CFrame.new(firstPlacedPos + Vector3.new(0, 4, 0))
                    _sprinklerTeleportedThisToggle = true
                end
            end
        end
        _lastSprinklerCycle = os.clock()
        _sprinklerBusy = false
        return firstPlacedPos ~= nil
    end

    _G._SFM_Register("Sprinkler", function() doSprinklerCycle(false) end)
    _G._RunSprinklerNow = function() doSprinklerCycle(true) end
    _G._ResetSprinklerToggleTeleport = function() _sprinklerTeleportedThisToggle = false end
    while not Speed_Library.Unloaded do
        if not Cfg.stackFarm then
            doSprinklerCycle(false)
            task.wait(1)
        else
            task.wait(5)
        end
    end
end)

-- ==================== AUTO WATERING CAN ====================
task.spawn(function()
    local lastWater = 0
    while not Speed_Library.Unloaded do
        if Cfg.autoWaterCan and selectedSprinklerActive() then
            local delaySeconds = math.max(tonumber(Cfg.waterCanDelay) or 30, 5)
            if os.clock() - lastWater >= delaySeconds then
                local uses = math.clamp(math.floor(tonumber(Cfg.waterCanUses) or 1), 1, 20)
                local didWater = false
                for i = 1, uses do
                    if not Cfg.autoWaterCan then break end
                    if useWaterCanAt(_lastSprinklerAnchor) then
                        didWater = true
                        if i < uses then task.wait(0.35) end
                    else
                        task.wait(2)
                        break
                    end
                end
                if didWater then lastWater = os.clock() end
            end
        end
        task.wait(1)
    end
end)

task.spawn(function()
    local gui, panel, listLabel
    local function formatTimer(seconds)
        seconds = math.max(0, math.floor(tonumber(seconds) or 0))
        local m = math.floor(seconds / 60)
        local s = seconds % 60
        return string.format("%d:%02d", m, s)
    end
    local function getTimerValue(inst)
        local attrs = inst:GetAttributes()
        local directKeys = { "TimeLeft", "TimeRemaining", "RemainingTime", "SecondsRemaining", "LifetimeRemaining", "DurationLeft", "Remaining" }
        for _, k in ipairs(directKeys) do
            local v = tonumber(attrs[k])
            if v then return v, k end
        end
        local absoluteKeys = { "ExpireTime", "ExpiresAt", "EndTime", "DestroyTime", "RemoveAt" }
        for _, k in ipairs(absoluteKeys) do
            local v = tonumber(attrs[k])
            if v then
                local now = v > 1000000 and os.time() or os.clock()
                return math.max(0, v - now), k
            end
        end
        for _, ui in ipairs(inst:GetDescendants()) do
            if ui.Name == "SprinklerTimerUI" and ui:IsA("BillboardGui") then
                for _, d in ipairs(ui:GetDescendants()) do
                    if (d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox")) and type(d.Text) == "string" then
                        local m, s = d.Text:match("^(%d+):(%d%d)$")
                        if m and s then return tonumber(m) * 60 + tonumber(s), "SprinklerTimerUI" end
                        local sec = tonumber(d.Text:match("^(%d+)%s*s$"))
                        if sec then return sec, "SprinklerTimerUI" end
                    end
                end
            end
        end
        for _, child in ipairs(inst:GetChildren()) do
            if child:IsA("NumberValue") or child:IsA("IntValue") then
                local n = child.Name:lower()
                if n:find("time") or n:find("remain") or n:find("duration") then
                    return tonumber(child.Value), child.Name
                end
            end
        end
        return nil, nil
    end
    local function isSprinklerInstance(inst)
        if not inst:IsA("Model") then return false end
        local attrs = inst:GetAttributes()
        if attrs.SprinklerName ~= nil or attrs.SprinklerId ~= nil or attrs.SprinklerType ~= nil then return true end
        local itemName = tostring(attrs.ItemName or attrs.ItemType or attrs.Type or "")
        return itemName:lower():find("sprinkler") ~= nil
    end
    local function sprinklerName(inst)
        local attrs = inst:GetAttributes()
        return tostring(attrs.SprinklerName or attrs.ItemName or attrs.SprinklerType or attrs.Type or inst.Name)
    end
    local function makeGui()
        if gui and gui.Parent then return end
        local parent = (type(gethui) == "function" and gethui()) or CoreGui
        gui = Instance.new("ScreenGui")
        gui.Name = "GAG_SprinklerTimerGui"
        gui.ResetOnSpawn = false
        gui.Parent = parent
        panel = Instance.new("Frame")
        panel.Name = "Panel"
        panel.AnchorPoint = Vector2.new(1, 0)
        panel.Position = UDim2.new(1, -18, 0, 120)
        panel.Size = UDim2.new(0, 285, 0, 220)
        panel.BackgroundColor3 = Color3.fromRGB(12, 16, 26)
        panel.BackgroundTransparency = 0.08
        panel.BorderSizePixel = 0
        panel.Parent = gui
        Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)
        local stroke = Instance.new("UIStroke", panel)
        stroke.Color = Color3.fromRGB(70, 170, 255)
        stroke.Transparency = 0.25
        local title = Instance.new("TextLabel")
        title.BackgroundTransparency = 1
        title.Position = UDim2.new(0, 12, 0, 8)
        title.Size = UDim2.new(1, -24, 0, 22)
        title.Font = Enum.Font.GothamBold
        title.TextSize = 14
        title.TextColor3 = Color3.fromRGB(235, 245, 255)
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Text = "Sprinkler Timers"
        title.Parent = panel
        listLabel = Instance.new("TextLabel")
        listLabel.BackgroundTransparency = 1
        listLabel.Position = UDim2.new(0, 12, 0, 36)
        listLabel.Size = UDim2.new(1, -24, 1, -46)
        listLabel.Font = Enum.Font.Code
        listLabel.TextSize = 11
        listLabel.TextColor3 = Color3.fromRGB(210, 230, 255)
        listLabel.TextXAlignment = Enum.TextXAlignment.Left
        listLabel.TextYAlignment = Enum.TextYAlignment.Top
        listLabel.TextWrapped = false
        listLabel.Text = "Scanning..."
        listLabel.Parent = panel
    end
    local function destroyGui()
        if gui then gui:Destroy() end
        gui, panel, listLabel = nil, nil, nil
    end
    local function updateGui()
        makeGui()
        local plot = getMyPlot()
        if not plot then
            listLabel.Text = "No plot found"
            return
        end
        local rows = {}
        for _, inst in ipairs(plot:GetDescendants()) do
            if isSprinklerInstance(inst) then
                local remaining, source = getTimerValue(inst)
                local timerText = remaining and formatTimer(remaining) or "??"
                local name = sprinklerName(inst):gsub(" Sprinkler", " Sp")
                if #name > 20 then name = name:sub(1, 19) .. "…" end
                table.insert(rows, string.format("%-21s %s", name, timerText))
                if #rows >= 14 then break end
            end
        end
        if #rows == 0 then rows[1] = "No placed sprinkler found" end
        listLabel.Text = table.concat(rows, "\n")
    end
    while not Speed_Library.Unloaded do
        if Cfg.sprinklerTimerGui then
            updateGui()
        else
            destroyGui()
        end
        task.wait(1)
    end
    destroyGui()
end)

-- ==================== AUTO TROWEL ====================
task.spawn(function()
    local savedTrowelPos = nil
    _G._SaveTrowelPos = function()
        local hrp = getHRP()
        if hrp then savedTrowelPos = hrp.Position end
    end
    local movedTrowelPlants = {}
    _G._ResetAutoTrowelMoved = function()
        table.clear(movedTrowelPlants)
    end
    local function findTrowelTool()
        local function checkIn(cont)
            if not cont then return nil end
            for _, v in pairs(cont:GetChildren()) do
                if v:IsA("Tool") and v:GetAttribute("Trowel") then return v end
            end
            return nil
        end
        local char = LocalPlayer.Character
        local tool = checkIn(char)
        if tool then return tool end
        return checkIn(LocalPlayer:FindFirstChild("Backpack"))
    end
    local function equipTrowelTool()
        local tool = findTrowelTool()
        if not tool then return nil end
        equipTool(tool)
        return findTrowelTool() or tool
    end
    local function getTrowelTarget()
        if Cfg.selTrowelPos == "Saved Position" and savedTrowelPos then
            return savedTrowelPos
        end
        local hrp = getHRP()
        return hrp and hrp.Position or nil
    end
    local function doTrowelCycle()
        if not Cfg.autoTrowel then return end
        if not equipTrowelTool() then return end
        local target = getTrowelTarget()
        if not target then return end
        local plot = getMyPlot()
        if not plot then return end
        local visual = plot:FindFirstChild("Plants")
        if not visual then return end
        for _, plant in pairs(visual:GetChildren()) do
            if Cfg.autoTrowel and plant:IsA("Model") then
                local plantId = plant:GetAttribute("PlantId")
                local seedName = plant:GetAttribute("SeedName") or ""
                if plantId and seedName ~= "" then
                    local plantKey = tostring(plantId)
                    if msMatch(Cfg.selTrowelPlant, seedName) and not movedTrowelPlants[plantKey] then
                        Networking.Trowel.MovePlant:Fire(plantId, target, 0)
                        movedTrowelPlants[plantKey] = true
                        task.wait(0.3)
                    end
                end
            end
        end
    end
    _G._SFM_Register("Trowel", doTrowelCycle)
    while not Speed_Library.Unloaded do
        task.wait(math.max(Cfg.trowelDelay or 2, 1))
        if not Cfg.stackFarm then
            doTrowelCycle()
        end
    end
end)

-- ==================== AUTO SHOVEL ====================
task.spawn(function()
    local function getShovelTool()
        local function checkIn(cont)
            for _, v in pairs(cont:GetChildren()) do
                if v:IsA("Tool") and v:GetAttribute("Shovel") then return v end
            end
            return nil
        end
        local char = LocalPlayer.Character
        local tool = char and checkIn(char)
        if tool then return tool end
        local bp = LocalPlayer:FindFirstChild("Backpack")
        return bp and checkIn(bp)
    end
    local function passShovelTreeFilter(plant)
        local seedName = plant:GetAttribute("SeedName") or ""
        local mut = plant:GetAttribute("Mutation") or ""
        if not msMatch(Cfg.selShovelTree, seedName) then return false end
        if not msMatch(Cfg.selShovelTreeRarity, SEED_RARITY[seedName] or "Common") then return false end
        if not msMutMatch(Cfg.selShovelTreeMut, mut) then return false end
        return true
    end
    local function passShovelFruitFilter(plant)
        local fruitId = plant:GetAttribute("FruitId") or ""
        if fruitId == "" then return false end
        local seedName = plant:GetAttribute("SeedName") or ""
        local mut = plant:GetAttribute("Mutation") or ""
        local weight = tonumber(plant:GetAttribute("Weight")) or 1
        if not msMatch(Cfg.selShovelFruit, seedName) then return false end
        if not msMatch(Cfg.selShovelFruitRarity, SEED_RARITY[seedName] or "Common") then return false end
        if not msMutMatch(Cfg.selShovelFruitMut, mut) then return false end
        if Cfg.selShovelThreshMode ~= "" then
            if Cfg.selShovelThreshMode == "Above" and weight < Cfg.shovelWeightThresh then return false end
            if Cfg.selShovelThreshMode == "Below" and weight > Cfg.shovelWeightThresh then return false end
        end
        return true
    end
    local function doShovelCycle()
        if not (Cfg.autoShovelTree or Cfg.autoShovelFruit) then return end
        local tool = getShovelTool()
        if not tool then return end
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and tool.Parent ~= char then
            hum:EquipTool(tool)
            task.wait(0.3)
            tool = getShovelTool()
            if not tool then return end
        end
        local shovelAttr = tool:GetAttribute("Shovel")
        local plot = getMyPlot()
        if not plot then return end
        local visual = plot:FindFirstChild("Plants")
        if not visual then return end
        for _, plant in pairs(visual:GetChildren()) do
            if plant:IsA("Model") then
                local plantId = plant:GetAttribute("PlantId")
                local seedName = plant:GetAttribute("SeedName") or ""
                if plantId and seedName ~= "" then
                    local doIt = false
                    local useFruitId = ""
                    if Cfg.autoShovelFruit and passShovelFruitFilter(plant) then
                        doIt = true
                        useFruitId = plant:GetAttribute("FruitId") or ""
                    elseif Cfg.autoShovelTree and passShovelTreeFilter(plant) then
                        doIt = true
                        useFruitId = ""
                    end
                    if doIt then
                        Networking.Shovel.UseShovel:Fire(plantId, useFruitId, shovelAttr, tool)
                        task.wait(0.5)
                    end
                end
            end
        end
    end
    _G._SFM_Register("Shovel", doShovelCycle)
    while not Speed_Library.Unloaded do
        local d = math.min(Cfg.shovelTreeDelay or 2, Cfg.shovelFruitDelay or 2)
        task.wait(math.max(d, 1))
        if not Cfg.stackFarm then
            doShovelCycle()
        end
    end
end)

-- ==================== AUTO FAVORITE ====================
task.spawn(function()
    local function passFavFilter(tool)
        local name = tool:GetAttribute("FruitName") or ""
        local mut  = tool:GetAttribute("Mutation") or ""
        local w    = tool:GetAttribute("Weight") or 0
        if not msMatch(Cfg.selFavFruit, name) then return false end
        if not msMatch(Cfg.selFavRarity, SEED_RARITY[name] or "Common") then return false end
        if not msMutMatch(Cfg.selFavMut, mut) then return false end
        if Cfg.selFavThresh ~= "" then
            if Cfg.selFavThresh == "Above" and w < Cfg.favWeightThresh then return false end
            if Cfg.selFavThresh == "Below" and w > Cfg.favWeightThresh then return false end
        end
        return true
    end
    local function getBackpackFruits()
        local fruits = {}
        for _, t in pairs(LocalPlayer.Backpack:GetChildren()) do
            if t:GetAttribute("HarvestedFruit") and t:GetAttribute("Id") then
                table.insert(fruits, t)
            end
        end
        return fruits
    end
    while not Speed_Library.Unloaded do
        task.wait(math.max(Cfg.favDelay, 0.5))
        if Cfg.autoFavFruit then
            for _, tool in pairs(getBackpackFruits()) do
                if tool:GetAttribute("IsFavorite") ~= true and passFavFilter(tool) then
                    Networking.Backpack.SetFruitFavorite:Fire(tool:GetAttribute("Id"), true)
                    task.wait(0.05)
                end
            end
        end
        if Cfg.autoUnFavFruit then
            for _, tool in pairs(getBackpackFruits()) do
                if tool:GetAttribute("IsFavorite") == true and passFavFilter(tool) then
                    Networking.Backpack.SetFruitFavorite:Fire(tool:GetAttribute("Id"), false)
                    task.wait(0.05)
                end
            end
        end
        if Cfg.autoUnFavAll then
            for _, tool in pairs(getBackpackFruits()) do
                if tool:GetAttribute("IsFavorite") == true then
                    Networking.Backpack.SetFruitFavorite:Fire(tool:GetAttribute("Id"), false)
                    task.wait(0.05)
                end
            end
        end
    end
end)

-- ==================== ESP ====================
do
    if _G._ESPClear then pcall(_G._ESPClear) end

    local espLabels = {}
    local espLabelCount = 0
    local ESP_MAX_LABELS = 350

    local function cleanupAllESPLabels()
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("BillboardGui") and obj.Name == "_ESPLabel" then
                obj:Destroy()
            end
        end
    end
    cleanupAllESPLabels()

    local RARITY_COLORS = {
        Common    = Color3.fromRGB(180, 180, 180),
        Uncommon  = Color3.fromRGB(80, 200, 80),
        Rare      = Color3.fromRGB(80, 130, 255),
        Epic      = Color3.fromRGB(180, 80, 255),
        Legendary = Color3.fromRGB(255, 200, 0),
        Mythic    = Color3.fromRGB(255, 80, 80),
        Super     = Color3.fromRGB(255, 150, 0),
    }

    local MUT_COLORS = {
        Gold       = "rgb(255,245,0)",
        Rainbow    = "rgb(0,255,170)",
        Electric   = "rgb(3,151,225)",
        Frozen     = "rgb(0,245,255)",
        Bloodlit   = "rgb(200,30,30)",
        Chained    = "rgb(139,47,175)",
        Starstruck = "rgb(239,140,253)",
        Aurora     = "rgb(31,140,254)",
        Solarflare = "rgb(255,120,0)",
        Pizza      = "rgb(255,180,50)",
    }

    local PET_RARITY = {
        Frog="Common", Snail="Common", Cat="Common", Bunny="Common", Chick="Common", Dog="Common",
        Bee="Uncommon", Butterfly="Uncommon", Cow="Uncommon", Duck="Uncommon",
        Panda="Rare", Deer="Rare", Dodo="Rare",
        Eagle="Epic", Goat="Epic",
        ["Polar Bear"]="Legendary", Peacock="Legendary", Shark="Legendary",
        Minotaur="Mythic", Trex="Mythic",
    }

    local function makeLabel(part, text, color)
        if espLabels[part] then return end
        if espLabelCount >= ESP_MAX_LABELS then return end
        local bg = Instance.new("BillboardGui")
        bg.Name = "_ESPLabel"
        bg.AlwaysOnTop = true
        bg.Size = UDim2.fromOffset(330, 30)
        bg.StudsOffset = Vector3.new(0, 2.35, 0)
        bg.MaxDistance = 500

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.fromScale(1, 1)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3 = color or Color3.fromRGB(255, 255, 255)
        lbl.RichText = true
        lbl.Text = text
        lbl.TextScaled = false
        lbl.TextSize = 18
        lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        lbl.TextStrokeTransparency = 0.08
        lbl.Font = Enum.Font.GothamBlack
        lbl.Parent = bg
        bg.Parent = part
        espLabels[part] = bg
        espLabelCount += 1
        part.AncestryChanged:Connect(function(_, p)
            if not p then
                bg:Destroy()
                espLabels[part] = nil
                espLabelCount = math.max(espLabelCount - 1, 0)
            end
        end)
    end

    local function removeLabel(part)
        local bg = espLabels[part]
        if bg then bg:Destroy(); espLabels[part] = nil; espLabelCount = math.max(espLabelCount - 1, 0) end
    end

    local function clearESP()
        for _, bg in pairs(espLabels) do
            if bg and bg.Parent then bg:Destroy() end
        end
        table.clear(espLabels)
        espLabelCount = 0
        cleanupAllESPLabels()
    end

    local function passFruitESP(seedName, mutation)
        if not msMatch(Cfg.selEspFruit, seedName) then return false end
        if not msMatch(Cfg.selEspRarity, SEED_RARITY[seedName] or "Common") then return false end
        if not msMutMatch(Cfg.selEspMut, mutation) then return false end
        return true
    end

    local function hideFruitTechParts(fruit)
        for _, obj in pairs(fruit:GetDescendants()) do
            suppressFruitVFXPart(obj)
        end
    end

    local function tryFruitESP(plant)
        if not Cfg.espFruit then return end
        local seedName = plant:GetAttribute("SeedName") or ""
        if seedName == "" then return end
        local fruitsF = plant:FindFirstChild("Fruits")
        if not fruitsF then return end
        for _, fruit in pairs(fruitsF:GetChildren()) do
            hideFruitTechParts(fruit)
            local mutation = fruit:GetAttribute("Mutation") or ""
            if passFruitESP(seedName, mutation) then
                local hasPrompt = fruit:FindFirstChildWhichIsA("ProximityPrompt", true)
                if hasPrompt then
                    local anchor = hasPrompt.Parent
                    local base = (anchor and anchor:IsA("BasePart") and anchor) or fruit:FindFirstChild("HarvestPart", true) or fruit.PrimaryPart
                    if base then
                        local sm = fruit:GetAttribute("SizeMulti") or 1
                        local displayKg = getFruitDisplayKg(fruit, seedName)
                        if displayKg and Cfg.espKgThresh > 0 then
                            if Cfg.espKgMode == "Above" and displayKg < Cfg.espKgThresh then continue end
                            if Cfg.espKgMode == "Below" and displayKg > Cfg.espKgThresh then continue end
                        end
                        local weightStr = displayKg and string.format("%.2fkg", displayKg) or "??kg"
                        local val = calcFruitValue(seedName, sm, mutation)
                        local namePart
                        if mutation ~= "" then
                            local mutCol = MUT_COLORS[mutation] or "rgb(255,255,255)"
                            namePart = '<font color="' .. mutCol .. '">' .. mutation .. '</font> ' .. seedName
                        else
                            namePart = seedName
                        end
                        local valPart = '<font color="rgb(80,255,120)">' .. fmtValue(val) .. '</font>'
                        makeLabel(base, namePart .. " [ " .. weightStr .. " ] [ " .. valPart .. " ]")
                    end
                end
            end
        end
    end

    local function watchPlant(plant)
        if not plant:IsA("Model") then return end
        plant.DescendantAdded:Connect(function(d)
            if Cfg.espFruit and d:IsA("ProximityPrompt") then tryFruitESP(plant) end
        end)
        plant.DescendantRemoving:Connect(function(d)
            if d:IsA("ProximityPrompt") then
                local fruit = d.Parent and d.Parent.Parent
                if fruit and fruit:IsA("Model") then
                    local anchor = d.Parent
                    local base = (anchor and anchor:IsA("BasePart") and anchor) or fruit:FindFirstChild("HarvestPart", true) or fruit.PrimaryPart
                    if base then removeLabel(base) end
                end
            end
        end)
        tryFruitESP(plant)
    end

    local function watchPlantsFolder(plantsFolder)
        for _, plant in pairs(plantsFolder:GetChildren()) do task.spawn(watchPlant, plant) end
        plantsFolder.ChildAdded:Connect(function(plant) task.spawn(watchPlant, plant) end)
    end

    task.spawn(function()
        for _, plot in pairs(Gardens:GetChildren()) do
            task.spawn(function()
                local plantsF = plot:FindFirstChild("Plants") or plot:WaitForChild("Plants", 10)
                if plantsF then watchPlantsFolder(plantsF) end
            end)
        end
        Gardens.ChildAdded:Connect(function(plot)
            task.spawn(function()
                local plantsF = plot:FindFirstChild("Plants") or plot:WaitForChild("Plants", 10)
                if plantsF then watchPlantsFolder(plantsF) end
            end)
        end)
    end)

    local function passPetESP(species, size)
        if not msMatch(Cfg.selEspPet, species) then return false end
        if not msMatch(Cfg.selEspPetRarity, PET_RARITY[species] or "Common") then return false end
        if not msMatch(Cfg.selEspPetSize, size) then return false end
        return true
    end

    local function tryPetESP(part)
        if not Cfg.espPet then return end
        if not part:IsA("BasePart") then return end
        local species = part:GetAttribute("PetSpecies") or ""
        if species == "" then return end
        local size = part:GetAttribute("PetSize") or ""
        if not passPetESP(species, size) then return end
        local col = RARITY_COLORS[PET_RARITY[species] or "Common"] or Color3.new(1, 1, 1)
        local label = size ~= "" and (size .. " " .. species) or species
        makeLabel(part, label, col)
    end

    task.spawn(function()
        local petRefs = workspace:WaitForChild("PlayerPetReferences", 30)
        if not petRefs then return end
        local function watchPlayerPets(folder)
            for _, part in pairs(folder:GetChildren()) do task.spawn(tryPetESP, part) end
            folder.ChildAdded:Connect(function(part) task.spawn(tryPetESP, part) end)
        end
        for _, folder in pairs(petRefs:GetChildren()) do task.spawn(watchPlayerPets, folder) end
        petRefs.ChildAdded:Connect(function(folder) task.spawn(watchPlayerPets, folder) end)
    end)

    _G._ESPClear = clearESP
    _G._ESPRefreshFruit = function()
        clearESP()
        for _, plot in pairs(Gardens:GetChildren()) do
            local plantsF = plot:FindFirstChild("Plants")
            if plantsF then
                for _, plant in pairs(plantsF:GetChildren()) do
                    if plant:IsA("Model") then tryFruitESP(plant) end
                end
            end
        end
    end
    _G._ESPRefreshPet = function()
        local petRefs = workspace:FindFirstChild("PlayerPetReferences")
        if not petRefs then return end
        for _, folder in pairs(petRefs:GetChildren()) do
            for _, part in pairs(folder:GetChildren()) do tryPetESP(part) end
        end
    end
end

-- ==================== MISC ====================
do
    local TeleportService = game:GetService("TeleportService")

    -- Anti-Fling + Less Knockback + Bypass Paused on Heartbeat
    RunService.Heartbeat:Connect(function()
        if not (Cfg.antiFling or Cfg.lessKnockback or Cfg.bypassPaused) then return end
        local hrp = getHRP()
        if not hrp then return end
        local vel = hrp.AssemblyLinearVelocity
        if Cfg.antiFling and vel.Magnitude > 100 then
            hrp.AssemblyLinearVelocity = Vector3.zero
            hrp.AssemblyAngularVelocity = Vector3.zero
        elseif Cfg.lessKnockback and vel.Magnitude > 30 then
            hrp.AssemblyLinearVelocity = vel.Unit * 30
        end
        if Cfg.bypassPaused then
            if hrp.Anchored then hrp.Anchored = false end
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.WalkSpeed == 0 then hum.WalkSpeed = 16 end
        end
    end)

    -- Instant Interact Prompt
    game.DescendantAdded:Connect(function(d)
        if Cfg.instantPrompt and d:IsA("ProximityPrompt") then
            task.wait()
            d.HoldDuration = 0
        end
    end)

    -- Noclip Plants loop
    task.spawn(function()
        while not Speed_Library.Unloaded do
            if Cfg.noclipPlants then
                local plot = getMyPlot()
                local plantsF = plot and plot:FindFirstChild("Plants")
                if plantsF then
                    for _, obj in pairs(plantsF:GetDescendants()) do
                        if obj:IsA("BasePart") and obj.CanCollide then
                            obj.CanCollide = false
                        end
                    end
                end
            end
            task.wait(0.5)
        end
    end)

    -- Hide Plants (reactive - counter-resets via GetPropertyChangedSignal)
    do
        local _hpConns = {}
        local _hpActive = false

        local function _isVFX(obj)
            return obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke")
                or obj:IsA("Sparkles") or obj:IsA("Beam") or obj:IsA("Trail")
        end

        local function _hookObj(obj)
            if _hpConns[obj] then return end
            if obj:IsA("BasePart") then
                obj.LocalTransparencyModifier = 1
                _hpConns[obj] = obj:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(function()
                    if _hpActive and obj.Parent and obj.LocalTransparencyModifier < 1 then
                        obj.LocalTransparencyModifier = 1
                    end
                end)
            elseif _isVFX(obj) then
                obj.Enabled = false
                _hpConns[obj] = obj:GetPropertyChangedSignal("Enabled"):Connect(function()
                    if _hpActive and obj.Parent and obj.Enabled then
                        obj.Enabled = false
                    end
                end)
            end
        end

        local function _unhookAll()
            for obj, conn in pairs(_hpConns) do
                conn:Disconnect()
                if obj.Parent then
                    if obj:IsA("BasePart") then
                        obj.LocalTransparencyModifier = 0
                    else
                        obj.Enabled = true
                    end
                end
            end
            table.clear(_hpConns)
        end

        local function _applyAll()
            local plot = getMyPlot()
            local plantsF = plot and plot:FindFirstChild("Plants")
            if not plantsF then return end
            for _, plant in pairs(plantsF:GetChildren()) do
                local sn = plant:GetAttribute("SeedName") or ""
                if msMatch(Cfg.selHidePlants, sn) then
                    for _, obj in pairs(plant:GetDescendants()) do
                        _hookObj(obj)
                    end
                end
            end
        end

        task.spawn(function()
            while not Speed_Library.Unloaded do
                if Cfg.hidePlants and not msEmpty(Cfg.selHidePlants) then
                    _hpActive = true
                    _applyAll()
                else
                    if _hpActive then
                        _hpActive = false
                        _unhookAll()
                    end
                end
                task.wait(2)
            end
            _hpActive = false
            _unhookAll()
        end)

        _G._HidePlantsOn = function() _hpActive = true; _applyAll() end
        _G._HidePlantsOff = function() _hpActive = false; _unhookAll() end
    end

    -- Hide Fruits loop
    task.spawn(function()
        while not Speed_Library.Unloaded do
            if Cfg.hideFruits then
                local plot = getMyPlot()
                if plot then
                    for _, obj in pairs(plot:GetDescendants()) do
                        if obj:FindFirstAncestor("Fruits") then
                            if obj:IsA("BasePart") and obj.Transparency < 1 then
                                obj.Transparency = 1
                            elseif (obj:IsA("ParticleEmitter") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") or obj:IsA("Beam") or obj:IsA("Trail")) and obj.Enabled then
                                obj.Enabled = false
                            end
                        end
                    end
                end
            end
            task.wait(0.5)
        end
    end)

    -- Disable Harvest Prompt
    game.DescendantAdded:Connect(function(d)
        if Cfg.disableHarvestPrompt and d:IsA("ProximityPrompt") then
            local plot = getMyPlot()
            if plot and d:IsDescendantOf(plot) then
                task.wait()
                d.Enabled = false
            end
        end
    end)

    -- Remove Other Gardens helper
    local function hideOtherGardens()
        local myPlot = getMyPlot()
        for _, plot in pairs(Gardens:GetChildren()) do
            if plot ~= myPlot then
                for _, obj in pairs(plot:GetDescendants()) do
                    if obj:IsA("BasePart") then
                        obj.LocalTransparencyModifier = 1
                    end
                end
            end
        end
    end
    Gardens.ChildAdded:Connect(function(plot)
        if Cfg.autoRemoveOtherGardens then
            task.wait(1)
            local myPlot = getMyPlot()
            if plot ~= myPlot then
                for _, obj in pairs(plot:GetDescendants()) do
                    if obj:IsA("BasePart") then obj.LocalTransparencyModifier = 1 end
                end
            end
        end
    end)

    -- Screen Overlay
    local _screenGui
    local function setScreenOverlay(color)
        if _screenGui then _screenGui:Destroy(); _screenGui = nil end
        if not color then return end
        _screenGui = Instance.new("ScreenGui")
        _screenGui.Name = "_MiscOverlay"
        _screenGui.ResetOnSpawn = false
        _screenGui.IgnoreGuiInset = true
        _screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        local f = Instance.new("Frame")
        f.Size = UDim2.fromScale(1, 1)
        f.Position = UDim2.fromScale(0, 0)
        f.BackgroundColor3 = color
        f.BackgroundTransparency = 0
        f.BorderSizePixel = 0
        f.ZIndex = 999
        f.Parent = _screenGui
        
        local t = Instance.new("TextLabel")
        t.Size = UDim2.new(1, -20, 0, 40)
        t.Position = UDim2.new(0, 10, 0, 10)
        t.BackgroundTransparency = 1
        t.Text = "Screen Overlay Active"
        t.TextColor3 = Color3.new(1, 1, 1)
        t.TextSize = 14
        t.Font = Enum.Font.Code
        t.TextXAlignment = Enum.TextXAlignment.Left
        t.TextYAlignment = Enum.TextYAlignment.Top
        t.ZIndex = 1000
        t.Parent = f

        _screenGui.Parent = LocalPlayer.PlayerGui
    end

    -- Expose helpers for UI callbacks
    _G._MiscSetScreen = setScreenOverlay
    _G._MiscHideGardens = hideOtherGardens

    -- Auto Hop Until PlaceVersion loop
    task.spawn(function()
        while not Speed_Library.Unloaded do
            if Cfg.autoHopUntilVer then
                local target = tonumber(Cfg.hopPlaceVer)
                if target and game.PlaceVersion ~= target then
                    TeleportService:Teleport(game.PlaceId)
                    task.wait(5)
                else
                    Cfg.autoHopUntilVer = false
                end
            end
            task.wait(1)
        end
    end)
end

-- ==================== AUTO PLANTS ====================

task.spawn(function()
    local CollectionService = game:GetService("CollectionService")

    local SPRINKLER_RADIUS = {
        ["Common Sprinkler"]   = 20,
        ["Uncommon Sprinkler"] = 25,
        ["Rare Sprinkler"]     = 30,
        ["Legendary Sprinkler"]= 40,
        ["Super Sprinkler"]    = 55,
    }

    local function getSprinklerRadius(name)
        for k, v in pairs(SPRINKLER_RADIUS) do
            -- The game's 'Radius' attribute is actually used as the Part's Size (diameter).
            -- So the actual geometric radius from the center is v / 2.
            if name:find(k) then return v / 2 end
        end
        return 15
    end

    local function getSprinklerCenterPart(model)
        if not model then return nil end
        return model.PrimaryPart
            or model:FindFirstChild("Root")
            or model:FindFirstChild("RootPart")
            or model:FindFirstChild("Base")
            or model:FindFirstChildWhichIsA("BasePart")
    end

    local function isUsablePlantArea(area)
        if not area or not area:IsA("BasePart") then return false end
        -- Some maps tag nearby green grass/decoration as PlantArea too. Only use soil-like areas.
        local c = area.Color
        if c and c.G > c.R and c.G > c.B then return false end
        return true
    end

    local function getEmptySpots(myPlot)
        local plantsFolder = myPlot:FindFirstChild("Plants")
        local plantPositions = {}
        if plantsFolder then
            for _, p in pairs(plantsFolder:GetChildren()) do
                local pos = p:GetPivot().Position
                plantPositions[#plantPositions + 1] = Vector2.new(pos.X, pos.Z)
            end
        end

        local refPos = nil
        local refRadius = nil
        if Cfg.plantPosition == "Sprinkler Radius" then
            local sprinklersF = myPlot:FindFirstChild("Sprinklers")
            if sprinklersF then
                local selected = tostring(Cfg.plantSprinkler or "Select Options")
                local bestPos, bestRadius = nil, -math.huge
                for _, s in pairs(sprinklersF:GetChildren()) do
                    local sname = tostring(s:GetAttribute("Sprinkler") or s:GetAttribute("SprinklerName") or s.Name)
                    local bp = getSprinklerCenterPart(s)
                    if bp then
                        local radius = getSprinklerRadius(sname)
                        local isSelected = selected ~= "" and selected ~= "Select Options" and (sname == selected or s.Name == selected)
                        if isSelected then
                            refPos = bp.Position
                            refRadius = radius
                            break
                        elseif selected == "" or selected == "Select Options" then
                            if radius > bestRadius then
                                bestPos = bp.Position
                                bestRadius = radius
                            end
                        end
                    end
                end
                if not refPos and bestPos then
                    refPos = bestPos
                    refRadius = bestRadius
                end
            end
            if not refPos and _lastSprinklerAnchor and (os.clock() - (_lastSprinklerAt or 0)) <= 180 then
                refPos = _lastSprinklerAnchor
                refRadius = 15
                if type(_lastSprinklerNames) == "table" then
                    for _, n in ipairs(_lastSprinklerNames) do
                        refRadius = math.max(refRadius, getSprinklerRadius(tostring(n)))
                    end
                end
            end
            if not refPos then
                return {}
            end
        elseif Cfg.plantPosition == "Saved Position" and Cfg.savedPlantPos then
            refPos = Cfg.savedPlantPos
            refRadius = 35
        elseif Cfg.plantPosition == "Player Position" then
            local hrp = getHRP()
            if hrp then
                local stackSpots = {}
                for i = 1, 100 do stackSpots[i] = hrp.Position end
                return stackSpots
            end
        end

        local spots = {}

        if Cfg.plantPosition == "Random" then
            local areas = {}
            for _, area in pairs(CollectionService:GetTagged("PlantArea")) do
                if area:IsDescendantOf(myPlot) and isUsablePlantArea(area) then areas[#areas + 1] = area end
            end
            if #areas == 0 then return {} end
            local attempts = 60
            for _ = 1, attempts do
                local area = areas[math.random(1, #areas)]
                local sx, sz = area.Size.X, area.Size.Z
                local lx = math.random() * (sx - 4) - (sx / 2 - 2)
                local lz = math.random() * (sz - 4) - (sz / 2 - 2)
                local world = area.CFrame:PointToWorldSpace(Vector3.new(lx, 0, lz))
                local wx, wz = world.X, world.Z
                local p2 = Vector2.new(wx, wz)
                local occupied = false
                for _, pp in pairs(plantPositions) do
                    if (p2 - pp).Magnitude < 2 then occupied = true; break end
                end
                if not occupied then
                    spots[#spots + 1] = Vector3.new(wx, area.Position.Y, wz)
                    plantPositions[#plantPositions + 1] = p2
                end
            end
            return spots
        end

        local spacing = 3
        for _, area in pairs(CollectionService:GetTagged("PlantArea")) do
            if area:IsDescendantOf(myPlot) and isUsablePlantArea(area) then
                local cy = area.Position.Y
                local sx, sz = area.Size.X, area.Size.Z
                local ox = -sx / 2 + 2
                while ox <= sx / 2 - 2 do
                    local oz = -sz / 2 + 2
                    while oz <= sz / 2 - 2 do
                        local world = area.CFrame:PointToWorldSpace(Vector3.new(ox, 0, oz))
                        local wx, wz = world.X, world.Z
                        local p2 = Vector2.new(wx, wz)
                        local inRange = true
                        if refPos and refRadius then
                            local d = (Vector2.new(refPos.X, refPos.Z) - p2).Magnitude
                            inRange = d <= refRadius
                        end
                        if inRange then
                            local occupied = false
                            for _, pp in pairs(plantPositions) do
                                if (p2 - pp).Magnitude < 2 then occupied = true; break end
                            end
                            if not occupied then
                                spots[#spots + 1] = Vector3.new(wx, cy, wz)
                            end
                        end
                        oz = oz + spacing
                    end
                    ox = ox + spacing
                end
            end
        end
        if refPos then
            table.sort(spots, function(a, b)
                return (a - refPos).Magnitude < (b - refPos).Magnitude
            end)
        end
        return spots
    end

    local function getAllSeedTools()
        local bp = LocalPlayer:FindFirstChild("Backpack")
        local char = LocalPlayer.Character
        local tools = {}
        if bp then
            for _, t in pairs(bp:GetChildren()) do
                if t:IsA("Tool") and t:GetAttribute("SeedTool") then tools[#tools + 1] = t end
            end
        end
        if char then
            for _, t in pairs(char:GetChildren()) do
                if t:IsA("Tool") and t:GetAttribute("SeedTool") then tools[#tools + 1] = t end
            end
        end
        return tools
    end

    while not Speed_Library.Unloaded do
        if not Cfg.autoPlantSeed and not Cfg.autoPlantAll then
            task.wait(1)
        else
            local myPlot = getMyPlot()
            if not myPlot then task.wait(2) elseif Cfg.plantRequireSprinkler and not selectedSprinklerActive(true) then
                setStatus("Auto Plant paused — no active sprinkler")
                task.wait(1)
            else

                local spots = getEmptySpots(myPlot)
                if #spots == 0 then task.wait(5) else
                    local seedPool = {}
                    if Cfg.autoPlantAll then
                        seedPool = getAllSeedTools()
                    elseif Cfg.plantSeedName ~= "Select Options" then
                        local tools = getAllSeedTools()
                        for _, t in ipairs(tools) do
                            if t:GetAttribute("SeedTool") == Cfg.plantSeedName then
                                seedPool = { t }
                                break
                            end
                        end
                    end

                    if #seedPool > 0 then
                        local si = 1
                        for _, pos in pairs(spots) do
                            if not Cfg.autoPlantSeed and not Cfg.autoPlantAll then break end
                            local char = LocalPlayer.Character
                            local hum = char and char:FindFirstChild("Humanoid")
                            if not hum then break end

                            local tool = seedPool[si]
                            if not tool or not tool.Parent then
                                si = si + 1
                                if si > #seedPool then break end
                                tool = seedPool[si]
                            end
                            if not tool then break end

                            local bp = LocalPlayer:FindFirstChild("Backpack")
                            local realTool = (bp and bp:FindFirstChild(tool.Name)) or tool

                            if realTool and realTool.Parent ~= bp and realTool.Parent ~= char then
                                local tools = getAllSeedTools()
                                realTool = nil
                                for _, t in ipairs(tools) do
                                    if t.Name == tool.Name then realTool = t; break end
                                end
                                if realTool then seedPool[si] = realTool end
                            end

                            if realTool and (realTool.Parent == bp or realTool.Parent == char) then
                                Networking.Plant.PlantSeed:Fire(pos, realTool:GetAttribute("SeedTool"), realTool)
                                State.planted = (State.planted or 0) + 1
                                if Cfg.autoPlantAll then
                                    si = si + 1
                                    if si > #seedPool then si = 1 end
                                end
                                local d = tonumber(Cfg.plantDelay) or 0
                                if d > 0 then
                                    task.wait(d)
                                elseif (State.planted or 0) % 25 == 0 then
                                    task.wait()
                                end
                            else
                                break
                            end
                        end
                    end
                    task.wait((tonumber(Cfg.plantDelay) or 0) > 0 and 0.5 or 0.1)
                end
            end
        end
    end
end)


-- ==================== LOCAL PLAYER FEATURES ====================

local _walkEnabled, _playerSpeed = false, 16
local _noclipEnabled = false
local _infJumpEnabled = false

local function applyWalkspeed()
    local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum and _walkEnabled then hum.WalkSpeed = _playerSpeed end
end

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    applyWalkspeed()
end)

task.spawn(function()
    local lastFreeze = false
    while not Speed_Library.Unloaded do
        task.wait(0.1)
        local char = LocalPlayer.Character
        if char then
            if _noclipEnabled then
                for _, p in next, char:GetDescendants() do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                if Cfg.playerFreeze then
                    hrp.Anchored = true
                    lastFreeze = true
                elseif lastFreeze then
                    hrp.Anchored = false
                    lastFreeze = false
                end
            end
        end
    end
end)

game:GetService("UserInputService").JumpRequest:Connect(function()
    if _infJumpEnabled then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- ==================== WEATHER PREDICT ====================

local _weatherOrder = {
    {name = "Rainbow Moon", chance = 6},
    {name = "Goldmoon",     chance = 13},
    {name = "Bloodmoon",    chance = 2},
    {name = "Moon",         chance = 79},
}

local function predictNightType(cycleNum)
    local rng = Random.new(cycleNum * 1000 + 3)
    local roll = rng:NextNumber() * 100
    local cum = 0
    for _, w in ipairs(_weatherOrder) do
        cum = cum + w.chance
        if roll <= cum then return w.name end
    end
    return "Moon"
end

local function fmtCountdown(s)
    s = math.max(0, math.floor(s))
    local h = math.floor(s / 3600)
    local m = math.floor((s % 3600) / 60)
    local sec = s % 60
    if h > 0 then
        return string.format("%dh %02dm %02ds", h, m, sec)
    else
        return string.format("%dm %02ds", m, sec)
    end
end

local function getNextSpecialNights()
    local now = os.time()
    local offset = workspace:GetAttribute("CycleOffset") or 0
    local posInCycle = (now + offset) % 600
    local secsToFirst = ((480 - posInCycle) + 600) % 600
    if secsToFirst == 0 then secsToFirst = 600 end

    local finds = {}
    local nightTime = now + secsToFirst
    local limit = now + 86400 * 3
    while nightTime < limit do
        local nType = predictNightType(math.floor(nightTime / 600))
        if nType ~= "Moon" and not finds[nType] then
            finds[nType] = nightTime - now
        end
        if finds["Bloodmoon"] and finds["Goldmoon"] and finds["Rainbow Moon"] then break end
        nightTime = nightTime + 600
    end
    return finds
end

-- ==================== AUTO WEATHER DISCONNECT ====================
local WEATHER_DISCONNECT_OPTIONS = {
    "Rain", "Lightning", "Bloodmoon", "Snowfall",
    "Starfall", "Rainbow", "Aurora", "Sunburst", "Goldmoon", "Rainbow Moon",
}
pcall(function()
    local wd = require(game:GetService("ReplicatedStorage"):WaitForChild("SharedModules"):WaitForChild("WeatherData"))
    if wd and wd.Data then
        for k, v in pairs(wd.Data) do
            local name = type(v) == "table" and (v.Name or k) or k
            if type(name) == "string" and not table.find(WEATHER_DISCONNECT_OPTIONS, name) then
                table.insert(WEATHER_DISCONNECT_OPTIONS, name)
            end
        end
    end
end)

local function normalizeWeatherName(name)
    name = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local low = name:lower():gsub("%s+", "")
    if low == "rainbowmoon" then return "Rainbow Moon" end
    if low == "goldmoon" then return "Goldmoon" end
    if low == "bloodmoon" then return "Bloodmoon" end
    if low == "starfall" then return "Starfall" end
    if low == "sunburst" then return "Sunburst" end
    if low == "snowfall" then return "Snowfall" end
    if low == "lightning" then return "Lightning" end
    if low == "rainbow" then return "Rainbow" end
    if low == "aurora" then return "Aurora" end
    if low == "night" then return "Night" end
    if low == "moon" then return "Moon" end
    if low == "rain" then return "Rain" end
    return name
end

local function selectedBadWeatherSet()
    local set = {}
    if type(Cfg.selDisconnectWeather) == "table" then
        for _, name in ipairs(Cfg.selDisconnectWeather) do
            local normalized = normalizeWeatherName(name)
            if normalized ~= "" and normalized ~= "Select Options" then
                set[normalized] = true
            end
        end
    end
    return set
end

local function getVisibleWeatherCard(set)
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    local weatherGui = pg and pg:FindFirstChild("WeatherUI")
    local frame = weatherGui and weatherGui:FindFirstChild("Frame")
    if not frame then return nil end
    for _, card in ipairs(frame:GetChildren()) do
        if card:IsA("GuiObject") and card.Visible and card.Name:sub(1, 3) ~= "PW_" and card.Name:sub(1, 6) ~= "_Pred_" then
            local weatherName = normalizeWeatherName(card:GetAttribute("WeatherToolTip") or card.Name)
            local label = card:FindFirstChild("Weather", true)
            if label and label:IsA("TextLabel") and label.Text ~= "" then
                weatherName = normalizeWeatherName(label.Text)
            end
            if set[weatherName] then return weatherName end
        end
    end
    return nil
end

local function getBadActiveWeather()
    local set = selectedBadWeatherSet()
    if not next(set) then return nil end

    local activeWeather = normalizeWeatherName(workspace:GetAttribute("ActiveWeather"))
    if set[activeWeather] and activeWeather ~= "Day" then return activeWeather end

    local activePhase = normalizeWeatherName(workspace:GetAttribute("ActivePhase"))
    if set[activePhase] and activePhase ~= "Day" then return activePhase end

    return getVisibleWeatherCard(set)
end

task.spawn(function()
    local triggered = false
    while not Speed_Library.Unloaded do
        if Cfg.autoWeatherDisconnect and not triggered then
            local badWeather = getBadActiveWeather()
            if badWeather then
                triggered = true
                local minutes = math.max(tonumber(Cfg.weatherReconnectMinutes) or 3, 0.1)
                local seconds = math.floor(minutes * 60)
                local placeId = game.PlaceId
                local player = LocalPlayer
                task.delay(seconds, function()
                    pcall(function()
                        game:GetService("TeleportService"):Teleport(placeId, player)
                    end)
                end)
                player:Kick(("Auto Disconnect: %s weather detected. Reconnecting in ~%s min..."):format(badWeather, tostring(minutes)))
                break
            end
        elseif not Cfg.autoWeatherDisconnect then
            triggered = false
        end
        task.wait(2)
    end
end)

-- ==================== WEATHER BAR HUD ====================
do
    local function mkCS(...)
        local args, kps = {...}, {}
        for i = 1, #args, 2 do kps[#kps+1] = ColorSequenceKeypoint.new(args[i], args[i+1]) end
        return ColorSequence.new(kps)
    end

    local PRED_TYPES = {
        { name = "Sunset",       vec = "rbxassetid://86217612022586",
          grad = mkCS(0, Color3.fromRGB(180,70,0), 0.5, Color3.fromRGB(255,140,20), 1, Color3.fromRGB(180,70,0)) },
        { name = "Moon",         vec = "rbxassetid://76206945378403",
          grad = mkCS(0, Color3.fromRGB(7,61,159), 1, Color3.fromRGB(7,61,159)) },
        { name = "Goldmoon",     vec = "rbxassetid://84902063004871",
          grad = mkCS(0, Color3.fromRGB(120,80,0), 0.5, Color3.fromRGB(220,160,0), 1, Color3.fromRGB(120,80,0)) },
        { name = "Bloodmoon",    vec = "rbxassetid://72350957717841",
          grad = mkCS(0, Color3.fromRGB(170,0,0), 0.5, Color3.fromRGB(255,0,0), 1, Color3.fromRGB(170,0,0)) },
        { name = "Rainbow Moon", vec = "rbxassetid://71907919634074",
          grad = mkCS(0,Color3.fromRGB(255,154,0), 0.111,Color3.fromRGB(184,255,0), 0.222,Color3.fromRGB(29,255,17),
                      0.333,Color3.fromRGB(0,254,154), 0.444,Color3.fromRGB(0,184,255), 0.555,Color3.fromRGB(17,26,255),
                      0.666,Color3.fromRGB(158,0,255), 0.777,Color3.fromRGB(253,0,184), 0.888,Color3.fromRGB(255,12,28),
                      1,Color3.fromRGB(255,154,0)) },
    }

    local _wbTimers = {}

    local function makeCard(wt, parent)
        local card = Instance.new("ImageLabel")
        card.Name = "_Pred_" .. wt.name
        card.BackgroundColor3 = Color3.new(1,1,1)
        card.BackgroundTransparency = 0
        card.Size = UDim2.new(0.0589, 0, 0.5226, 0)
        card.LayoutOrder = 0
        card.Parent = parent

        local ar = Instance.new("UIAspectRatioConstraint", card)
        ar.AspectRatio = 1

        local grad = Instance.new("UIGradient", card)
        grad.Color = wt.grad

        local stroke = Instance.new("UIStroke", card)
        stroke.Color = Color3.fromRGB(0, 18, 54)
        stroke.Thickness = 0.035

        local bevel = Instance.new("ImageLabel", card)
        bevel.Name = "BevelEffect"
        bevel.AnchorPoint = Vector2.new(0.5, 0.5)
        bevel.Position = UDim2.new(0.5, 0, 0.5, 0)
        bevel.Size = UDim2.new(1, 0, 1, 0)
        bevel.BackgroundTransparency = 1
        bevel.Image = "rbxassetid://112886786873408"
        bevel.ImageTransparency = 0.05

        local inlet = Instance.new("ImageLabel", card)
        inlet.Name = "InletTexture"
        inlet.AnchorPoint = Vector2.new(0.5, 0.5)
        inlet.Position = UDim2.new(0.5, 0, 0.5, 0)
        inlet.Size = UDim2.new(1, 0, 1, 0)
        inlet.BackgroundTransparency = 1
        inlet.Image = "rbxassetid://118449132151095"
        inlet.ImageTransparency = 0.64

        local vec = Instance.new("ImageLabel", card)
        vec.Name = "Vector"
        vec.AnchorPoint = Vector2.new(0.5, 0.5)
        vec.Position = UDim2.new(0.5, 0, 0.5, 0)
        vec.Size = UDim2.new(0.8, 0, 0.8, 0)
        vec.BackgroundTransparency = 1
        vec.Image = wt.vec
        vec.ZIndex = 1

        local function makeLbl(name, posY, sizeY)
            local lbl = Instance.new("TextLabel", card)
            lbl.Name = name
            lbl.AnchorPoint = Vector2.new(0.5, 0.5)
            lbl.Position = UDim2.new(0.5, 0, posY, 0)
            lbl.Size = UDim2.new(1, 0, sizeY, 0)
            lbl.BackgroundTransparency = 1
            lbl.TextColor3 = Color3.new(1, 1, 1)
            lbl.TextScaled = true
            lbl.TextXAlignment = Enum.TextXAlignment.Center
            lbl.TextYAlignment = Enum.TextYAlignment.Center
            pcall(function() lbl.FontFace = Font.new("rbxasset://fonts/families/ComicNeueAngular.json", Enum.FontWeight.Bold) end)
            if lbl.Font == Enum.Font.Unknown then lbl.Font = Enum.Font.GothamBold end
            lbl.ZIndex = 2
            local s = Instance.new("UIStroke", lbl); s.Thickness = 1
            Instance.new("UIPadding", lbl)
            return lbl
        end

        makeLbl("Weather", 0.14, 0.231).Text = wt.name
        return makeLbl("Time", 0.855, 0.233)
    end

    local function injectCards()
        local pg = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui", 15)
        if not pg then return end
        local wUI = pg:WaitForChild("WeatherUI", 15)
        if not wUI then return end
        local frame = wUI:WaitForChild("Frame", 15)
        if not frame then return end
        for _, c in ipairs(frame:GetChildren()) do
            if c.Name:sub(1, 6) == "_Pred_" then c:Destroy() end
        end
        _wbTimers = {}
        for _, wt in ipairs(PRED_TYPES) do
            _wbTimers[wt.name] = makeCard(wt, frame)
        end
    end

    local function getAllTimings()
        local now = os.time()
        local offset = workspace:GetAttribute("CycleOffset") or 0
        local pos = (now + offset) % 600
        local toSunset = ((450 - pos) + 600) % 600
        if toSunset == 0 then toSunset = 600 end
        local toNight = ((480 - pos) + 600) % 600
        if toNight == 0 then toNight = 600 end
        local result = { Sunset = toSunset }
        local remaining = { Moon = true, Goldmoon = true, ["Rainbow Moon"] = true, Bloodmoon = true }
        local t = now + toNight
        while next(remaining) and t < now + 86400 * 3 do
            local nType = predictNightType(math.floor(t / 600))
            if remaining[nType] then result[nType] = t - now; remaining[nType] = nil end
            t = t + 600
        end
        return result
    end

    task.spawn(injectCards)

    task.spawn(function()
        while not Speed_Library.Unloaded do
            local ok, res = pcall(getAllTimings)
            if ok and res then
                for name, lbl in pairs(_wbTimers) do
                    if lbl and lbl.Parent then
                        local secs = res[name]
                        lbl.Text = secs and fmtCountdown(secs) or "N/A"
                    end
                end
            end
            task.wait(1)
        end
    end)
end

-- ==================== INVENTORY VALUE OVERLAY ====================
do
    local INV_TAG = "_GAG2_Val"
    local TOTAL_TAG = "_GAG2_Total"

    local function parseWeight(str)
        return tonumber((str or ""):match("([%d%.]+)")) or 0
    end

    local function findTool(fruitName, weight)
        local char = LocalPlayer.Character
        if char then
            for _, tool in pairs(char:GetChildren()) do
                if tool:IsA("Tool") and tool:GetAttribute("FruitName") == fruitName then
                    if math.abs((tool:GetAttribute("Weight") or 0) - weight) < 0.1 then
                        return tool
                    end
                end
            end
        end
        for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
            if tool:GetAttribute("FruitName") == fruitName then
                if math.abs((tool:GetAttribute("Weight") or 0) - weight) < 0.1 then
                    return tool
                end
            end
        end
        return nil
    end

    local function calcTotalValue()
        local total, count = 0, 0
        local function countTools(container)
            for _, tool in pairs(container:GetChildren()) do
                if tool:GetAttribute("HarvestedFruit") and tool:GetAttribute("Id") then
                    total = total + calcFruitValue(
                        tool:GetAttribute("FruitName") or "",
                        tool:GetAttribute("SizeMultiplier") or 1,
                        tool:GetAttribute("Mutation") or "",
                        tool:GetAttribute("DecayAlpha") or 0
                    )
                    count = count + 1
                end
            end
        end
        countTools(LocalPlayer.Backpack)
        local char = LocalPlayer.Character
        if char then countTools(char) end
        return count, total
    end

    local function injectSlot(slot)
        if not (slot:IsA("TextButton") or slot:IsA("Frame")) then return end
        local toolNameLbl = slot:FindFirstChild("ToolName")
        local toolCountLbl = slot:FindFirstChild("ToolCount")
        if not toolNameLbl then return end

        local fruitName = toolNameLbl.Text
        local weight = toolCountLbl and parseWeight(toolCountLbl.Text) or 0
        local tool = findTool(fruitName, weight)

        local lbl = slot:FindFirstChild(INV_TAG)
        if not tool then
            if lbl then lbl:Destroy() end
            return
        end

        local val = calcFruitValue(
            tool:GetAttribute("FruitName") or "",
            tool:GetAttribute("SizeMultiplier") or 1,
            tool:GetAttribute("Mutation") or "",
            tool:GetAttribute("DecayAlpha") or 0
        )

        if not lbl then
            lbl = Instance.new("TextLabel")
            lbl.Name = INV_TAG
            lbl.Size = UDim2.new(1, 0, 0, 14)
            lbl.Position = UDim2.new(0, 0, 0, 2)
            lbl.BackgroundTransparency = 1
            lbl.TextColor3 = Color3.fromRGB(80, 255, 120)
            lbl.TextScaled = true
            lbl.Font = Enum.Font.GothamBold
            lbl.ZIndex = 10
            lbl.Parent = slot
        end
        lbl.Text = fmtValue(val)
    end

    local function refreshAllSlots(container)
        for _, slot in pairs(container:GetChildren()) do
            task.spawn(injectSlot, slot)
        end
    end

    local _totalLbl = nil
    local function updateTotal(anchor)
        local count, total = calcTotalValue()
        if not _totalLbl or not _totalLbl.Parent then
            _totalLbl = Instance.new("TextLabel")
            _totalLbl.Name = TOTAL_TAG
            _totalLbl.Size = UDim2.new(0, 300, 0, 24)
            _totalLbl.AnchorPoint = Vector2.new(0, 0.5)
            _totalLbl.Position = UDim2.new(0, 210, 0, 22)
            _totalLbl.BackgroundColor3 = Color3.new(0, 0, 0)
            _totalLbl.BackgroundTransparency = 1
            _totalLbl.TextColor3 = Color3.fromRGB(80, 255, 120)
            _totalLbl.TextScaled = false
            _totalLbl.TextSize = 20
            _totalLbl.TextXAlignment = Enum.TextXAlignment.Left
            _totalLbl.Font = Enum.Font.GothamBold
            _totalLbl.ZIndex = 20
            _totalLbl.Parent = anchor
            Instance.new("UICorner", _totalLbl).CornerRadius = UDim.new(0, 4)
        end
        _totalLbl.Text = count .. " Fruits | " .. fmtValue(total)
    end

    task.spawn(function()
        local pg = LocalPlayer:WaitForChild("PlayerGui")
        local bg = pg:WaitForChild("BackpackGui", 30)
        if not bg then return end

        local backpackFrame = bg:WaitForChild("Backpack", 10)
        local inventoryFrame = backpackFrame and backpackFrame:WaitForChild("Inventory", 10)
        local ugf = inventoryFrame
        ugf = ugf and ugf:WaitForChild("ScrollingFrame", 10)
        ugf = ugf and ugf:WaitForChild("UIGridFrame", 10)
        if not ugf then return end

        local hotbarSlotContainer = backpackFrame:FindFirstChild("Hotbar")

        local function onChanged()
            task.wait(0.1)
            refreshAllSlots(ugf)
            if hotbarSlotContainer then refreshAllSlots(hotbarSlotContainer) end
            updateTotal(inventoryFrame)
        end

        refreshAllSlots(ugf)
        if hotbarSlotContainer then refreshAllSlots(hotbarSlotContainer) end
        updateTotal(inventoryFrame)

        ugf.ChildAdded:Connect(function(slot) task.wait(0.05); injectSlot(slot) end)

        if hotbarSlotContainer then
            hotbarSlotContainer.ChildAdded:Connect(function(slot) task.wait(0.05); injectSlot(slot) end)
        end

        LocalPlayer.Backpack.ChildAdded:Connect(onChanged)
        LocalPlayer.Backpack.ChildRemoved:Connect(onChanged)

        local function hookChar(char)
            char.ChildAdded:Connect(onChanged)
            char.ChildRemoved:Connect(onChanged)
        end
        if LocalPlayer.Character then hookChar(LocalPlayer.Character) end
        LocalPlayer.CharacterAdded:Connect(function(char) task.wait(0.1); hookChar(char); onChanged() end)
    end)
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

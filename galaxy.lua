local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
local Mouse = LocalPlayer:GetMouse()

local GalaxyUI = {}
GalaxyUI.Version = "Merged v3.0"
GalaxyUI.Windows = {}
GalaxyUI.Flags = {}
GalaxyUI.Config = {Enabled = false, FolderName = nil, FileName = "GalaxyConfig", Data = {}}
GalaxyUI.Themes = {
	Default = {
		MainFrame = Color3.fromRGB(30,30,40),
		Topbar = Color3.fromRGB(40,40,50),
		TextColor = Color3.fromRGB(240,240,240),
		ButtonColor = Color3.fromRGB(50,50,60),
		AccentColor = Color3.fromRGB(0,170,255),
		SidebarColor = Color3.fromRGB(35,35,45),
		SectionColor = Color3.fromRGB(45,45,55),
		TooltipColor = Color3.fromRGB(20,20,20),
		DividerColor = Color3.fromRGB(120,120,130),
		Second = Color3.fromRGB(32,32,32),
		Stroke = Color3.fromRGB(60,60,60),
		SidebarWidth = 220
	}
}
GalaxyUI.ThemeObjects = {}
GalaxyUI.Connections = {}

local function Create(name, properties, children)
	local obj = Instance.new(name)
	for k, v in pairs(properties or {}) do
		obj[k] = v
	end
	for _, child in ipairs(children or {}) do
		child.Parent = obj
	end
	return obj
end

local function AddThemeObject(object, typeName)
	GalaxyUI.ThemeObjects[typeName] = GalaxyUI.ThemeObjects[typeName] or {}
	table.insert(GalaxyUI.ThemeObjects[typeName], object)
	if typeName == "Text" then
		object.TextColor3 = GalaxyUI.Themes.Default.TextColor
	elseif typeName == "Second" then
		object.BackgroundColor3 = GalaxyUI.Themes.Default.Second
	elseif typeName == "Stroke" then
		if object:IsA("UIStroke") then
			object.Color = GalaxyUI.Themes.Default.Stroke
		else
			object.BackgroundColor3 = GalaxyUI.Themes.Default.Stroke
		end
	elseif typeName == "Divider" then
		object.BackgroundColor3 = GalaxyUI.Themes.Default.DividerColor
	elseif typeName == "Main" then
		object.BackgroundColor3 = GalaxyUI.Themes.Default.MainFrame
	end
	return object
end

local function AddConnection(signal, func)
	local conn = signal:Connect(func)
	table.insert(GalaxyUI.Connections, conn)
	return conn
end

local function AddDraggingFunctionality(handle, target)
	local dragging = false
	local dragStart, startPos
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = target.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
end

function GalaxyUI:EnableConfig(enabled, folder, filename)
	self.Config.Enabled = enabled or false
	self.Config.FolderName = folder
	self.Config.FileName = filename or "GalaxyConfig"
end

function GalaxyUI:SaveConfig()
	if not self.Config.Enabled then return end
	local data = {}
	for k, v in pairs(self.Flags) do
		if typeof(v) == "table" and v.Value ~= nil then
			data[k] = v.Value
		else
			data[k] = v
		end
	end
	local encoded = HttpService:JSONEncode(data)
	if writefile then
		if self.Config.FolderName and not isfolder(self.Config.FolderName) then
			makefolder(self.Config.FolderName)
		end
		writefile((self.Config.FolderName and self.Config.FolderName.."/" or "")..self.Config.FileName..".json", encoded)
	end
end

function GalaxyUI:LoadConfig()
	if not self.Config.Enabled then return end
	local path = self.Config.FolderName and (self.Config.FolderName.."/"..self.Config.FileName..".json") or (self.Config.FileName..".json")
	if readfile and isfile(path) then
		local raw = readfile(path)
		local data = HttpService:JSONDecode(raw)
		self.Config.Data = data
		for k, v in pairs(data) do
			if self.Flags[k] and self.Flags[k].Set then
				self.Flags[k]:Set(v)
			else
				self.Flags[k] = v
			end
		end
	end
end

local ElementLibrary = {}

function ElementLibrary:Corner(scale, offset)
	return Create("UICorner", {CornerRadius = UDim.new(scale or 0, offset or 10)})
end

function ElementLibrary:Stroke(color, thickness)
	return Create("UIStroke", {Color = color or GalaxyUI.Themes.Default.Stroke, Thickness = thickness or 1})
end

function ElementLibrary:List(scale, offset)
	return Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(scale or 0, offset or 0)})
end

function ElementLibrary:Padding(bottom, left, right, top)
	return Create("UIPadding", {PaddingBottom = UDim.new(0, bottom or 4), PaddingLeft = UDim.new(0, left or 4), PaddingRight = UDim.new(0, right or 4), PaddingTop = UDim.new(0, top or 4)})
end

function ElementLibrary:TFrame()
	return Create("Frame", {BackgroundTransparency = 1})
end

function ElementLibrary:RoundFrame(color, scale, offset)
	local frame = Create("Frame", {BackgroundColor3 = color or Color3.new(1,1,1), BorderSizePixel = 0})
	self:Corner(scale, offset).Parent = frame
	return frame
end

function ElementLibrary:Button()
	return Create("TextButton", {Text = "", AutoButtonColor = false, BackgroundTransparency = 1, BorderSizePixel = 0})
end

function ElementLibrary:ScrollFrame(color, width)
	return Create("ScrollingFrame", {BackgroundTransparency = 1, MidImage = "rbxassetid://7445543667", BottomImage = "rbxassetid://7445543667", TopImage = "rbxassetid://7445543667", ScrollBarImageColor3 = color, BorderSizePixel = 0, ScrollBarThickness = width, CanvasSize = UDim2.new(0, 0, 0, 0)})
end

function ElementLibrary:Image(imageID)
	return Create("ImageLabel", {Image = imageID, BackgroundTransparency = 1})
end

function ElementLibrary:Label(text, textSize, transparency)
	return Create("TextLabel", {Text = text or "", TextColor3 = GalaxyUI.Themes.Default.TextColor, TextTransparency = transparency or 0, TextSize = textSize or 15, Font = Enum.Font.Gotham, RichText = true, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left})
end

local MakeElement = function(elementName, ...)
	if ElementLibrary[elementName] then
		return ElementLibrary[elementName](ElementLibrary, ...)
	end
	return nil
end

local ItemParent = nil

local ElementFunction = {}

function ElementFunction:AddButton(ButtonConfig)
	ButtonConfig = ButtonConfig or {}
	ButtonConfig.Name = ButtonConfig.Name or "Button"
	ButtonConfig.Callback = ButtonConfig.Callback or function() end
	ButtonConfig.Icon = ButtonConfig.Icon or "rbxassetid://3944703587"
	local Click = Create("TextButton", {Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1})
	local ButtonFrame = AddThemeObject(Create("Frame", {Size = UDim2.new(1,0,0,33), Parent = ItemParent, BackgroundColor3 = GalaxyUI.Themes.Default.Second}, {AddThemeObject(MakeElement("Label", ButtonConfig.Name, 15), "Text"), AddThemeObject(MakeElement("Image", ButtonConfig.Icon), "TextDark"), AddThemeObject(MakeElement("Stroke"), "Stroke"), Click}), "Second")
	AddConnection(Click.MouseEnter, function() TweenService:Create(ButtonFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {BackgroundColor3 = GalaxyUI.Themes.Default.Second + Color3.new(0.01,0.01,0.01)}):Play() end)
	AddConnection(Click.MouseLeave, function() TweenService:Create(ButtonFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {BackgroundColor3 = GalaxyUI.Themes.Default.Second}):Play() end)
	AddConnection(Click.MouseButton1Down, function() TweenService:Create(ButtonFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {BackgroundColor3 = GalaxyUI.Themes.Default.Second + Color3.new(0.02,0.02,0.02)}):Play() end)
	AddConnection(Click.MouseButton1Up, function() TweenService:Create(ButtonFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {BackgroundColor3 = GalaxyUI.Themes.Default.Second + Color3.new(0.01,0.01,0.01)}):Play() spawn(ButtonConfig.Callback) end)
	local Button = {}
	function Button:Set(text) ButtonFrame.Content.Text = text end
	return Button
end

function ElementFunction:AddToggle(ToggleConfig)
	ToggleConfig = ToggleConfig or {}
	ToggleConfig.Name = ToggleConfig.Name or "Toggle"
	ToggleConfig.Default = ToggleConfig.Default or false
	ToggleConfig.Callback = ToggleConfig.Callback or function() end
	ToggleConfig.Color = ToggleConfig.Color or Color3.fromRGB(9,99,195)
	ToggleConfig.Flag = ToggleConfig.Flag or nil
	ToggleConfig.Save = ToggleConfig.Save or false
	local Toggle = {Value = ToggleConfig.Default, Save = ToggleConfig.Save}
	local Click = Create("TextButton", {Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1})
	local ToggleBox = Create("Frame", {Size = UDim2.new(0,24,0,24), Position = UDim2.new(1,-24,0.5,0), AnchorPoint = Vector2.new(0.5,0.5), BackgroundColor3 = Toggle.Value and ToggleConfig.Color or GalaxyUI.Themes.Default.Divider}, {AddThemeObject(MakeElement("Stroke"), "Stroke"), AddThemeObject(MakeElement("Image", "rbxassetid://3944680095"), "Text")})
	local ToggleFrame = AddThemeObject(Create("Frame", {Size = UDim2.new(1,0,0,38), Parent = ItemParent, BackgroundColor3 = GalaxyUI.Themes.Default.Second}, {AddThemeObject(MakeElement("Label", ToggleConfig.Name, 15), "Text"), AddThemeObject(MakeElement("Stroke"), "Stroke"), ToggleBox, Click}), "Second")
	function Toggle:Set(Value)
		Toggle.Value = Value
		TweenService:Create(ToggleBox, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {BackgroundColor3 = Toggle.Value and ToggleConfig.Color or GalaxyUI.Themes.Default.Divider}):Play()
		ToggleConfig.Callback(Toggle.Value)
	end
	Toggle:Set(Toggle.Value)
	AddConnection(Click.MouseButton1Up, function() Toggle:Set(not Toggle.Value) end)
	if ToggleConfig.Flag then GalaxyUI.Flags[ToggleConfig.Flag] = Toggle end
	return Toggle
end

function ElementFunction:AddSlider(SliderConfig)
	SliderConfig = SliderConfig or {}
	SliderConfig.Name = SliderConfig.Name or "Slider"
	SliderConfig.Min = SliderConfig.Min or 0
	SliderConfig.Max = SliderConfig.Max or 100
	SliderConfig.Increment = SliderConfig.Increment or 1
	SliderConfig.Default = SliderConfig.Default or 50
	SliderConfig.Callback = SliderConfig.Callback or function() end
	SliderConfig.ValueName = SliderConfig.ValueName or ""
	SliderConfig.Color = SliderConfig.Color or Color3.fromRGB(9,149,98)
	SliderConfig.Flag = SliderConfig.Flag or nil
	SliderConfig.Save = SliderConfig.Save or false
	local Slider = {Value = SliderConfig.Default, Save = SliderConfig.Save}
	local Dragging = false
	local SliderDrag = Create("Frame", {Size = UDim2.new(0,0,1,0), BackgroundColor3 = SliderConfig.Color, BackgroundTransparency = 0.3}, {AddThemeObject(MakeElement("Label", "value", 13), "Text")})
	local SliderBar = Create("Frame", {Size = UDim2.new(1,-24,0,26), Position = UDim2.new(0,12,0,30), BackgroundTransparency = 0.9}, {AddThemeObject(MakeElement("Stroke"), "Stroke"), Create("TextLabel", {Name = "Value", Text = "value", Font = Enum.Font.GothamBold}, nil), SliderDrag})
	local SliderFrame = AddThemeObject(Create("Frame", {Size = UDim2.new(1,0,0,65), Parent = ItemParent, BackgroundColor3 = Color3.fromRGB(255,255,255)}, {AddThemeObject(MakeElement("Label", SliderConfig.Name, 15), "Text"), AddThemeObject(MakeElement("Stroke"), "Stroke"), SliderBar}), "Second")
	SliderBar.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then Dragging = true end end)
	SliderBar.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then Dragging = false end end)
	AddConnection(UserInputService.InputChanged, function(input)
		if Dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local ratio = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X)/SliderBar.AbsoluteSize.X,0,1)
			Slider:Set(SliderConfig.Min + (SliderConfig.Max - SliderConfig.Min)*ratio)
		end
	end)
	function Slider:Set(Value)
		self.Value = math.clamp(math.floor(Value/SliderConfig.Increment+0.5)*SliderConfig.Increment, SliderConfig.Min, SliderConfig.Max)
		TweenService:Create(SliderDrag, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {Size = UDim2.new((self.Value - SliderConfig.Min)/(SliderConfig.Max-SliderConfig.Min),0,1,0)}):Play()
		SliderBar.Value.Text = tostring(self.Value).." "..SliderConfig.ValueName
		SliderConfig.Callback(self.Value)
	end
	Slider:Set(Slider.Value)
	if SliderConfig.Flag then GalaxyUI.Flags[SliderConfig.Flag] = Slider end
	return Slider
end

function ElementFunction:AddDropdown(DropdownConfig)
	DropdownConfig = DropdownConfig or {}
	DropdownConfig.Name = DropdownConfig.Name or "Dropdown"
	DropdownConfig.Options = DropdownConfig.Options or {}
	DropdownConfig.Default = DropdownConfig.Default or ""
	DropdownConfig.Callback = DropdownConfig.Callback or function() end
	DropdownConfig.Flag = DropdownConfig.Flag or nil
	DropdownConfig.Save = DropdownConfig.Save or false
	local Dropdown = {Value = DropdownConfig.Default, Options = DropdownConfig.Options, Buttons = {}, Toggled = false, Type = "Dropdown", Save = DropdownConfig.Save}
	local MaxElements = 5
	if not table.find(Dropdown.Options, Dropdown.Value) then Dropdown.Value = "..." end
	local DropdownList = MakeElement("List")
	local DropdownContainer = AddThemeObject(Create("ScrollingFrame", {Parent = ItemParent, Position = UDim2.new(0,0,0,38), Size = UDim2.new(1,0,1,-38), ClipsDescendants = true, BackgroundColor3 = Color3.fromRGB(40,40,40)}, {DropdownList}), "Divider")
	local Click = Create("TextButton", {Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1})
	local DropdownFrame = AddThemeObject(Create("Frame", {Size = UDim2.new(1,0,0,38), Parent = ItemParent, ClipsDescendants = true, BackgroundColor3 = Color3.fromRGB(255,255,255)}, {DropdownContainer, Create("Frame", {Name = "F", Size = UDim2.new(1,0,0,38), ClipsDescendants = true}, {AddThemeObject(MakeElement("Label", DropdownConfig.Name, 15), "Text"), AddThemeObject(MakeElement("Image", "rbxassetid://7072706796"), "TextDark"), AddThemeObject(MakeElement("Label", "Selected", 13), "TextDark"), AddThemeObject(MakeElement("Frame"), "Stroke"), Click}), AddThemeObject(MakeElement("Stroke"), "Stroke"), MakeElement("Corner")}), "Second")
	AddConnection(DropdownList:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		DropdownContainer.CanvasSize = UDim2.new(0,0,0,DropdownList.AbsoluteContentSize.Y)
	end)
	local function AddOptions(Options)
		for _, Option in pairs(Options) do
			local OptionBtn = AddThemeObject(Create("TextButton", {Parent = DropdownContainer, Size = UDim2.new(1,0,0,28), BackgroundTransparency = 1, ClipsDescendants = true}, {MakeElement("Corner",0,6), AddThemeObject(MakeElement("Label", Option, 13,0.4), "Text")}), "Divider")
			AddConnection(OptionBtn.MouseButton1Click, function() Dropdown:Set(Option) end)
			Dropdown.Buttons[Option] = OptionBtn
		end
	end
	function Dropdown:Refresh(Options, Delete)
		if Delete then
			for _,v in pairs(Dropdown.Buttons) do v:Destroy() end
			table.clear(Dropdown.Options)
			table.clear(Dropdown.Buttons)
		end
		Dropdown.Options = Options
		AddOptions(Dropdown.Options)
	end
	function Dropdown:Set(Value)
		if not table.find(Dropdown.Options, Value) then
			Dropdown.Value = "..."
			DropdownFrame.F.Selected.Text = Dropdown.Value
			for _, v in pairs(Dropdown.Buttons) do
				TweenService:Create(v, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()
				TweenService:Create(v.Title, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {TextTransparency = 0.4}):Play()
			end
			return
		end
		Dropdown.Value = Value
		DropdownFrame.F.Selected.Text = Dropdown.Value
		for _, v in pairs(Dropdown.Buttons) do
			TweenService:Create(v, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()
			TweenService:Create(v.Title, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {TextTransparency = 0.4}):Play()
		end
		TweenService:Create(Dropdown.Buttons[Value], TweenInfo.new(0.15, Enum.EasingStyle.Quad), {BackgroundTransparency = 0}):Play()
		TweenService:Create(Dropdown.Buttons[Value].Title, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {TextTransparency = 0}):Play()
		DropdownConfig.Callback(Dropdown.Value)
	end
	AddConnection(Click.MouseButton1Click, function()
		Dropdown.Toggled = not Dropdown.Toggled
		DropdownFrame.F.Line.Visible = Dropdown.Toggled
		TweenService:Create(DropdownFrame.F.Ico, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {Rotation = Dropdown.Toggled and 180 or 0}):Play()
		if #Dropdown.Options > MaxElements then
			TweenService:Create(DropdownFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {Size = Dropdown.Toggled and UDim2.new(1,0,0,38+(MaxElements*28)) or UDim2.new(1,0,0,38)}):Play()
		else
			TweenService:Create(DropdownFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {Size = Dropdown.Toggled and UDim2.new(1,0,0,DropdownList.AbsoluteContentSize.Y+38) or UDim2.new(1,0,0,38)}):Play()
		end
	end)
	Dropdown:Refresh(Dropdown.Options, false)
	Dropdown:Set(Dropdown.Value)
	if DropdownConfig.Flag then GalaxyUI.Flags[DropdownConfig.Flag] = Dropdown end
	return Dropdown
end

function ElementFunction:AddBind(BindConfig)
	BindConfig.Name = BindConfig.Name or "Bind"
	BindConfig.Default = BindConfig.Default or Enum.KeyCode.Unknown
	BindConfig.Hold = BindConfig.Hold or false
	BindConfig.Callback = BindConfig.Callback or function() end
	BindConfig.Flag = BindConfig.Flag or nil
	BindConfig.Save = BindConfig.Save or false
	local Bind = {Value = nil, Binding = false, Type = "Bind", Save = BindConfig.Save}
	local Holding = false
	local Click = Create("TextButton", {Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1})
	local BindBox = AddThemeObject(Create("Frame", {Size = UDim2.new(0,24,0,24), Position = UDim2.new(1,-12,0.5,0), AnchorPoint = Vector2.new(1,0.5), BackgroundColor3 = Color3.fromRGB(255,255,255)}, {AddThemeObject(MakeElement("Stroke"), "Stroke"), AddThemeObject(MakeElement("Label", BindConfig.Name, 14), "Text")}), "Main")
	local BindFrame = AddThemeObject(Create("Frame", {Size = UDim2.new(1,0,0,38), Parent = ItemParent, BackgroundColor3 = Color3.fromRGB(255,255,255)}, {AddThemeObject(MakeElement("Label", BindConfig.Name, 15), "Text"), AddThemeObject(MakeElement("Stroke"), "Stroke"), BindBox, Click}), "Second")
	AddConnection(BindBox.Value:GetPropertyChangedSignal("Text"), function()
		TweenService:Create(BindBox, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {Size = UDim2.new(0, BindBox.Value.TextBounds.X+16, 0, 24)}):Play()
	end)
	AddConnection(Click.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and not Bind.Binding then
			Bind.Binding = true
			BindBox.Value.Text = ""
		end
	end)
	AddConnection(UserInputService.InputBegan, function(input)
		if UserInputService:GetFocusedTextBox() then return end
		if (input.KeyCode.Name == Bind.Value or input.UserInputType.Name == Bind.Value) and not Bind.Binding then
			if BindConfig.Hold then
				Holding = true
				BindConfig.Callback(Holding)
			else
				BindConfig.Callback()
			end
		elseif Bind.Binding then
			local Key
			pcall(function() if input.KeyCode ~= Enum.KeyCode.Unknown then Key = input.KeyCode end end)
			Key = Key or Bind.Value
			Bind:Set(Key)
		end
	end)
	AddConnection(UserInputService.InputEnded, function(input)
		if input.KeyCode.Name == Bind.Value or input.UserInputType.Name == Bind.Value then
			if BindConfig.Hold and Holding then
				Holding = false
				BindConfig.Callback(Holding)
			end
		end
	end)
	AddConnection(Click.MouseButton1Up, function()
		TweenService:Create(BindFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {BackgroundColor3 = GalaxyUI.Themes.Default.Second+Color3.new(0.01,0.01,0.01)}):Play()
	end)
	function Bind:Set(Key)
		Bind.Binding = false
		Bind.Value = Key and (Key.Name or Key) or Bind.Value
		BindBox.Value.Text = Bind.Value
	end
	Bind:Set(BindConfig.Default)
	if BindConfig.Flag then GalaxyUI.Flags[BindConfig.Flag] = Bind end
	return Bind
end

function ElementFunction:AddTextbox(TextboxConfig)
	TextboxConfig = TextboxConfig or {}
	TextboxConfig.Name = TextboxConfig.Name or "Textbox"
	TextboxConfig.Default = TextboxConfig.Default or ""
	TextboxConfig.TextDisappear = TextboxConfig.TextDisappear or false
	TextboxConfig.Callback = TextboxConfig.Callback or function() end
	local Click = Create("TextButton", {Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1})
	local TextboxActual = AddThemeObject(Create("TextBox", {Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(255,255,255), PlaceholderColor3 = Color3.fromRGB(210,210,210), PlaceholderText = "Input", Font = Enum.Font.GothamSemibold, TextXAlignment = Enum.TextXAlignment.Center, TextSize = 14, ClearTextOnFocus = false}), "Text")
	local TextContainer = AddThemeObject(Create("Frame", {Size = UDim2.new(0,24,0,24), Position = UDim2.new(1,-12,0.5,0), AnchorPoint = Vector2.new(1,0.5), BackgroundColor3 = Color3.fromRGB(255,255,255)}, {AddThemeObject(MakeElement("Stroke"), "Stroke"), TextboxActual}), "Main")
	local TextboxFrame = AddThemeObject(Create("Frame", {Size = UDim2.new(1,0,0,38), Parent = ItemParent, BackgroundColor3 = Color3.fromRGB(255,255,255)}, {AddThemeObject(MakeElement("Label", TextboxConfig.Name, 15), "Text"), AddThemeObject(MakeElement("Stroke"), "Stroke"), TextContainer, Click}), "Second")
	AddConnection(TextboxActual:GetPropertyChangedSignal("Text"), function()
		TweenService:Create(TextContainer, TweenInfo.new(0.45, Enum.EasingStyle.Quint), {Size = UDim2.new(0, TextboxActual.TextBounds.X+16, 0, 24)}):Play()
	end)
	AddConnection(TextboxActual.FocusLost, function()
		TextboxConfig.Callback(TextboxActual.Text)
		if TextboxConfig.TextDisappear then TextboxActual.Text = "" end
	end)
	TextboxActual.Text = TextboxConfig.Default
	AddConnection(Click.MouseButton1Up, function()
		TweenService:Create(TextboxFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint), {BackgroundColor3 = GalaxyUI.Themes.Default.Second+Color3.new(0.01,0.01,0.01)}):Play()
		TextboxActual:CaptureFocus()
	end)
	return nil
end

function ElementFunction:AddColorpicker(ColorpickerConfig)
	ColorpickerConfig = ColorpickerConfig or {}
	ColorpickerConfig.Name = ColorpickerConfig.Name or "Colorpicker"
	ColorpickerConfig.Default = ColorpickerConfig.Default or Color3.fromRGB(255,255,255)
	ColorpickerConfig.Callback = ColorpickerConfig.Callback or function() end
	ColorpickerConfig.Flag = ColorpickerConfig.Flag or nil
	ColorpickerConfig.Save = ColorpickerConfig.Save or false
	local ColorH, ColorS, ColorV = 1, 1, 1
	local Colorpicker = {Value = ColorpickerConfig.Default, Toggled = false, Type = "Colorpicker", Save = ColorpickerConfig.Save}
	local ColorSelection = Create("ImageLabel", {Size = UDim2.new(0,18,0,18), BackgroundTransparency = 1, Image = "http://www.roblox.com/asset/?id=4805639000"})
	local HueSelection = Create("ImageLabel", {Size = UDim2.new(0,18,0,18), BackgroundTransparency = 1, Image = "http://www.roblox.com/asset/?id=4805639000"})
	local Color = Create("ImageLabel", {Size = UDim2.new(1,-25,1,0), Visible = false, Image = "rbxassetid://4155801252"}, {Create("UICorner", {CornerRadius = UDim.new(0,5)}), ColorSelection})
	local Hue = Create("Frame", {Size = UDim2.new(0,20,1,0), Position = UDim2.new(1,-20,0,0), Visible = false}, {Create("UIGradient", {Rotation = 270, Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255,0,4)),
		ColorSequenceKeypoint.new(0.20, Color3.fromRGB(234,255,0)),
		ColorSequenceKeypoint.new(0.40, Color3.fromRGB(21,255,0)),
		ColorSequenceKeypoint.new(0.60, Color3.fromRGB(0,255,255)),
		ColorSequenceKeypoint.new(0.80, Color3.fromRGB(0,17,255)),
		ColorSequenceKeypoint.new(0.90, Color3.fromRGB(255,0,251)),
		ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255,0,4))
	}}), Create("UICorner", {CornerRadius = UDim.new(0,5)}), HueSelection})
	local ColorpickerContainer = Create("Frame", {Position = UDim2.new(0,0,0,32), Size = UDim2.new(1,0,1,-32), BackgroundTransparency = 1, ClipsDescendants = true}, {Hue, Color, Create("UIPadding", {PaddingLeft = UDim.new(0,35), PaddingRight = UDim.new(0,35), PaddingBottom = UDim.new(0,10), PaddingTop = UDim.new(0,17)})})
	local Click = Create("TextButton", {Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1})
	local ColorpickerBox = AddThemeObject(Create("Frame", {Size = UDim2.new(0,24,0,24), Position = UDim2.new(1,-12,0.5,0), AnchorPoint = Vector2.new(1,0.5), BackgroundColor3 = ColorpickerConfig.Default}, {AddThemeObject(MakeElement("Stroke"), "Stroke")}), "Main")
	local ColorpickerFrame = AddThemeObject(Create("Frame", {Size = UDim2.new(1,0,0,38), Parent = ItemParent, BackgroundColor3 = Color3.fromRGB(255,255,255)}, {Create("Frame", {Name = "F", Size = UDim2.new(1,0,0,38), ClipsDescendants = true}, {AddThemeObject(MakeElement("Label", ColorpickerConfig.Name, 15), "Text"), ColorpickerBox, Click, AddThemeObject(MakeElement("Frame"), "Stroke")}), ColorpickerContainer, AddThemeObject(MakeElement("Stroke"), "Stroke")}), "Second")
	AddConnection(Click.MouseButton1Click, function()
		Colorpicker.Toggled = not Colorpicker.Toggled
		TweenService:Create(ColorpickerFrame, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {Size = Colorpicker.Toggled and UDim2.new(1,0,0,148) or UDim2.new(1,0,0,38)}):Play()
		Color.Visible = Colorpicker.Toggled
		Hue.Visible = Colorpicker.Toggled
		ColorpickerFrame.F.Line = Colorpicker.Toggled
	end)
	local function UpdateColorPicker()
		ColorpickerBox.BackgroundColor3 = Color3.fromHSV(ColorH, ColorS, ColorV)
		Color.BackgroundColor3 = Color3.fromHSV(ColorH, 1, 1)
		Colorpicker.Value = ColorpickerBox.BackgroundColor3
		ColorpickerConfig.Callback(ColorpickerBox.BackgroundColor3)
	end
	ColorH = 1 - (math.clamp(HueSelection.AbsolutePosition.Y - Hue.AbsolutePosition.Y, 0, Hue.AbsoluteSize.Y)/Hue.AbsoluteSize.Y)
	ColorS = (math.clamp(ColorSelection.AbsolutePosition.X - Color.AbsolutePosition.X, 0, Color.AbsoluteSize.X)/Color.AbsoluteSize.X)
	ColorV = 1 - (math.clamp(ColorSelection.AbsolutePosition.Y - Color.AbsolutePosition.Y, 0, Color.AbsoluteSize.Y)/Color.AbsoluteSize.Y)
	local ColorInput, HueInput
	AddConnection(Color.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if ColorInput then ColorInput:Disconnect() end
			ColorInput = AddConnection(RunService.RenderStepped, function()
				local ColorX = (math.clamp(Mouse.X - Color.AbsolutePosition.X, 0, Color.AbsoluteSize.X)/Color.AbsoluteSize.X)
				local ColorY = (math.clamp(Mouse.Y - Color.AbsolutePosition.Y, 0, Color.AbsoluteSize.Y)/Color.AbsoluteSize.Y)
				ColorSelection.Position = UDim2.new(ColorX,0,ColorY,0)
				ColorS = ColorX
				ColorV = 1 - ColorY
				UpdateColorPicker()
			end)
		end
	end)
	AddConnection(Color.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if ColorInput then ColorInput:Disconnect() end
		end
	end)
	AddConnection(Hue.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if HueInput then HueInput:Disconnect() end
			HueInput = AddConnection(RunService.RenderStepped, function()
				local HueY = (math.clamp(Mouse.Y - Hue.AbsolutePosition.Y, 0, Hue.AbsoluteSize.Y)/Hue.AbsoluteSize.Y)
				HueSelection.Position = UDim2.new(0.5,0,HueY,0)
				ColorH = 1 - HueY
				UpdateColorPicker()
			end)
		end
	end)
	AddConnection(Hue.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if HueInput then HueInput:Disconnect() end
		end
	end)
	function Colorpicker:Set(Value)
		Colorpicker.Value = Value
		ColorpickerBox.BackgroundColor3 = Colorpicker.Value
		ColorpickerConfig.Callback(Colorpicker.Value)
	end
	Colorpicker:Set(Colorpicker.Value)
	if ColorpickerConfig.Flag then GalaxyUI.Flags[ColorpickerConfig.Flag] = Colorpicker end
	return Colorpicker
end

function ElementFunction:AddSection(SectionConfig)
	SectionConfig.Name = SectionConfig.Name or "Section"
	local SectionFrame = Create("Frame", {Size = UDim2.new(1,0,0,26), Parent = ItemParent}, {AddThemeObject(Create("TextLabel", {Size = UDim2.new(1,-12,0,16), Position = UDim2.new(0,0,0,3), Text = SectionConfig.Name, Font = Enum.Font.GothamSemibold}), "TextDark"), Create("Frame", {AnchorPoint = Vector2.new(0,0), Size = UDim2.new(1,0,1,-24), Position = UDim2.new(0,0,0,23), Name = "Holder"}, {MakeElement("List",0,6)})})
	AddConnection(SectionFrame.Holder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		SectionFrame.Size = UDim2.new(1,0,0,SectionFrame.Holder.UIListLayout.AbsoluteContentSize.Y+31)
		SectionFrame.Holder.Size = UDim2.new(1,0,0,SectionFrame.Holder.UIListLayout.AbsoluteContentSize.Y)
	end)
	local SectionFunction = {}
	for i, v in next, SectionFrame.Holder:GetChildren() do
		SectionFunction[i] = v
	end
	return SectionFunction
end

function GalaxyUI:Notify(config)
	local sg = Create("ScreenGui", {Name = "GalaxyUINotification", ResetOnSpawn = false, Parent = LocalPlayer:WaitForChild("PlayerGui")})
	local frame = Create("Frame", {Size = UDim2.new(0,300,0,80), Position = UDim2.new(1,-310,1,-90), BackgroundColor3 = GalaxyUI.Themes.Default.Topbar, Parent = sg})
	AddThemeObject(frame, "Stroke")
	local title = Create("TextLabel", {Size = UDim2.new(1,-60,0,30), Position = UDim2.new(0,50,0,0), BackgroundTransparency = 1, Text = config.Title or "Notification", TextColor3 = GalaxyUI.Themes.Default.TextColor, Font = Enum.Font.GothamBold, TextSize = 18, Parent = frame})
	local content = Create("TextLabel", {Size = UDim2.new(1,-20,0,40), Position = UDim2.new(0,10,0,30), BackgroundTransparency = 1, Text = config.Content or "", TextColor3 = Color3.fromRGB(210,210,210), Font = Enum.Font.Gotham, TextSize = 14, TextWrapped = true, Parent = frame})
	local tweenIn = TweenService:Create(frame, TweenInfo.new(0.35, Enum.EasingStyle.Back), {Position = UDim2.new(1,-310,1,-100)})
	tweenIn:Play()
	delay(config.Duration or 3, function()
		local tweenOut = TweenService:Create(frame, TweenInfo.new(0.35, Enum.EasingStyle.Quad), {Position = UDim2.new(1,-310,1,100)})
		tweenOut:Play()
		tweenOut.Completed:Connect(function() sg:Destroy() end)
	end)
end

function GalaxyUI:CreateWindow(opt)
	local w = {}
	w.Name = opt.Name or "Window"
	w.Theme = opt.Theme or "Default"
	local screenGui = Create("ScreenGui", {Name = "GalaxyUI_"..w.Name, ResetOnSpawn = false, Parent = LocalPlayer:WaitForChild("PlayerGui")})
	w.ScreenGui = screenGui
	local main = Create("Frame", {Name = "MainFrame", Size = UDim2.new(0,780,0,450), Position = UDim2.new(0.5,-390,0.5,-225), BackgroundColor3 = GalaxyUI.Themes.Default.MainFrame, BackgroundTransparency = 1, Parent = screenGui})
	local top = Create("Frame", {Name = "Topbar", Size = UDim2.new(1,0,0,45), BackgroundColor3 = GalaxyUI.Themes.Default.Topbar, Parent = main})
	local title = Create("TextLabel", {Size = UDim2.new(1,-70,1,0), Position = UDim2.new(0,15,0,0), BackgroundTransparency = 1, Text = w.Name, TextColor3 = GalaxyUI.Themes.Default.TextColor, Font = Enum.Font.GothamSemibold, TextSize = 18, TextXAlignment = Enum.TextXAlignment.Left, Parent = top})
	local minimize = Create("TextButton", {Size = UDim2.new(0,45,1,0), Position = UDim2.new(1,-50,0,0), BackgroundTransparency = 1, Text = "–", TextColor3 = GalaxyUI.Themes.Default.TextColor, Font = Enum.Font.GothamBold, TextSize = 20, Parent = top})
	local side = Create("Frame", {Name = "Sidebar", Size = UDim2.new(0,GalaxyUI.Themes.Default.SidebarWidth,1,-45), Position = UDim2.new(0,0,0,45), BackgroundColor3 = GalaxyUI.Themes.Default.SidebarColor, Parent = main})
	local container = Create("Frame", {Name = "Container", Size = UDim2.new(1,-GalaxyUI.Themes.Default.SidebarWidth,1,-45), Position = UDim2.new(0,GalaxyUI.Themes.Default.SidebarWidth,0,45), BackgroundTransparency = 1, Parent = main})
	AddDraggingFunctionality(top, main)
	w.Main = main
	w.Sidebar = side
	w.Container = container
	w.Tabs = {}
	w.IsOpen = true
	w.OriginalSize = UDim2.new(0,750,0,430)
	function w:Toggle() self.Main.Visible = not self.Main.Visible; self.IsOpen = not self.IsOpen end
	table.insert(self.Windows, w)
	return w
end

function GalaxyUI:CreateTab(opt)
	local t = {}
	t.Name = opt.Name or "Tab"
	t.Icon = opt.Icon or "rbxassetid://4483362458"
	local btn = Create("TextButton", {Size = UDim2.new(1,0,0,40), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = self.Sidebar})
	local icon = Create("ImageLabel", {Size = UDim2.new(0,20,0,20), Position = UDim2.new(0,15,0,10), BackgroundTransparency = 1, Parent = btn})
	icon.Image = type(t.Icon) == "string" and t.Icon or "rbxassetid://"..t.Icon
	local txt = Create("TextLabel", {Size = UDim2.new(1,-50,1,0), Position = UDim2.new(0,45,0,0), BackgroundTransparency = 1, Text = t.Name, TextColor3 = Color3.fromRGB(210,210,210), Font = Enum.Font.Gotham, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left, Parent = btn})
	t.Frame = Create("ScrollingFrame", {Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, ScrollBarThickness = 6, Visible = false, Parent = self.Container})
	local layout = Instance.new("UIListLayout", t.Frame)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0,10)
	btn.MouseButton1Click:Connect(function()
		for _, tab in pairs(self.Tabs) do tab.Frame.Visible = false end
		t.Frame.Visible = true
		self.LastTab = t
		ItemParent = t.Frame
	end)
	table.insert(self.Tabs, t)
	return t
end

return GalaxyUI

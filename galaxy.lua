local Players=game:GetService("Players")
local TweenService=game:GetService("TweenService")
local UserInputService=game:GetService("UserInputService")
local HttpService=game:GetService("HttpService")
local LocalPlayer=Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
local GalaxyUI={}
GalaxyUI.Version="5.1"
GalaxyUI.Flags={}
GalaxyUI.Config={Enabled=false,FolderName=nil,FileName="GalaxyConfig",Data={}}
GalaxyUI.Themes={
	Default={
		MainFrame=Color3.fromRGB(20,20,20),
		Topbar=Color3.fromRGB(30,30,30),
		TextColor=Color3.fromRGB(240,240,240),
		ButtonColor=Color3.fromRGB(40,40,40),
		AccentColor=Color3.fromRGB(0,120,215),
		SidebarColor=Color3.fromRGB(25,25,25),
		SidebarWidth=220,
		SectionColor=Color3.fromRGB(35,35,35),
		DividerColor=Color3.fromRGB(50,50,50)
	}
}
GalaxyUI.Windows={}
GalaxyUI.ToggleKey=Enum.KeyCode.K
local NotificationQueue={}
local function saveConfig()
	if not GalaxyUI.Config.Enabled then return end
	local data={}
	for k,v in pairs(GalaxyUI.Flags) do
		data[k]=v
	end
	local encoded=HttpService:JSONEncode(data)
	if writefile then
		if GalaxyUI.Config.FolderName and not isfolder(GalaxyUI.Config.FolderName) then
			makefolder(GalaxyUI.Config.FolderName)
		end
		writefile((GalaxyUI.Config.FolderName and GalaxyUI.Config.FolderName.."/" or "")..GalaxyUI.Config.FileName..".json",encoded)
	end
end
local function loadConfig()
	if not GalaxyUI.Config.Enabled then return end
	local path=GalaxyUI.Config.FolderName and (GalaxyUI.Config.FolderName.."/"..GalaxyUI.Config.FileName..".json") or (GalaxyUI.Config.FileName..".json")
	if readfile and isfile and isfile(path) then
		local raw=readfile(path)
		local data=HttpService:JSONDecode(raw)
		GalaxyUI.Config.Data=data
		for k,v in pairs(data) do
			GalaxyUI.Flags[k]=v
		end
	end
end
local function applyTheme(theme)
	if type(theme)=="string" then
		if GalaxyUI.Themes[theme] then
			GalaxyUI.Themes.Default=GalaxyUI.Themes[theme]
		end
	elseif type(theme)=="table" then
		for k,v in pairs(theme) do
			GalaxyUI.Themes.Default[k]=v
		end
	end
end
local function SetDescendantsVisibility(obj,visible)
	for _,v in pairs(obj:GetDescendants()) do
		if v:IsA("GuiObject") then
			v.Visible=visible
		end
	end
end
function GalaxyUI:EnableConfig(e,f,n)
	self.Config.Enabled=e or false
	self.Config.FolderName=f
	self.Config.FileName=n or "GalaxyConfig"
end
function GalaxyUI:LoadConfig() loadConfig() end
function GalaxyUI:SaveConfig() saveConfig() end
function GalaxyUI:ModifyTheme(t) applyTheme(t) end
function GalaxyUI:Destroy()
	for _,w in pairs(self.Windows) do
		if w.ScreenGui then
			w.ScreenGui:Destroy()
		end
	end
	self.Windows={}
end
function GalaxyUI:Refresh()
	for _,w in pairs(self.Windows) do
		if w.ScreenGui and w.Main then
			TweenService:Create(w.Main,TweenInfo.new(0.3),{BackgroundTransparency=0}):Play()
		end
	end
end
function GalaxyUI:Notify(opt)
	local sg=Instance.new("ScreenGui")
	sg.Name="GalaxyUINotifications"
	sg.ResetOnSpawn=false
	sg.Parent=LocalPlayer:WaitForChild("PlayerGui")
	sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
	local container=Instance.new("Frame")
	container.Name="NotificationContainer"
	container.AnchorPoint=Vector2.new(1,1)
	container.Size=UDim2.new(0,300,0,0)
	container.Position=UDim2.new(1,-20,1,-20)
	container.BackgroundTransparency=1
	container.ZIndex=10
	container.Parent=sg
	table.insert(NotificationQueue,{sg=sg,opt=opt})
	local count=#NotificationQueue
	local frame=Instance.new("Frame")
	frame.AnchorPoint=Vector2.new(1,1)
	frame.Size=UDim2.new(1,0,0,80)
	frame.Position=UDim2.new(1,0,1,-((count-1)*90+80))
	frame.BackgroundColor3=GalaxyUI.Themes.Default.Topbar
	frame.BackgroundTransparency=1
	frame.ZIndex=11
	frame.Parent=container
	local corner=Instance.new("UICorner",frame)
	corner.CornerRadius=UDim.new(0,12)
	local icon=Instance.new("ImageLabel",frame)
	icon.Size=UDim2.new(0,32,0,32)
	icon.Position=UDim2.new(0,10,0,24)
	icon.BackgroundTransparency=1
	icon.Image=opt.Image or "rbxassetid://4483362458"
	icon.ZIndex=12
	local title=Instance.new("TextLabel")
	title.Size=UDim2.new(1,-60,0,32)
	title.Position=UDim2.new(0,50,0,10)
	title.BackgroundTransparency=1
	title.Text=opt.Title or "Notification"
	title.TextColor3=GalaxyUI.Themes.Default.TextColor
	title.Font=Enum.Font.GothamSemibold
	title.TextSize=18
	title.ZIndex=12
	title.Parent=frame
	local content=Instance.new("TextLabel")
	content.Size=UDim2.new(1,-20,0,36)
	content.Position=UDim2.new(0,10,0,42)
	content.BackgroundTransparency=1
	content.Text=opt.Content or ""
	content.TextColor3=Color3.fromRGB(100,100,100)
	content.Font=Enum.Font.Gotham
	content.TextSize=16
	content.TextWrapped=true
	content.ZIndex=12
	content.Parent=frame
	frame.Visible=false
	local tweenIn=TweenService:Create(frame,TweenInfo.new(0.35,Enum.EasingStyle.Back),{BackgroundTransparency=0,Position=frame.Position-UDim2.new(0,0,0,10)})
	tweenIn:Play()
	tweenIn.Completed:Connect(function() frame.Visible=true end)
	delay(opt.Duration or 3,function()
		local tweenOut=TweenService:Create(frame,TweenInfo.new(0.35,Enum.EasingStyle.Quad),{BackgroundTransparency=1,Position=frame.Position+UDim2.new(0,0,0,20)})
		tweenOut:Play()
		tweenOut.Completed:Connect(function() sg:Destroy() table.remove(NotificationQueue,table.find(NotificationQueue,{sg=sg,opt=opt}) or 1) end)
	end)
end
local function Dragify(handle,target)
	local dragging=false
	local dragStart,startPos
	handle.InputBegan:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
			dragging=true
			dragStart=input.Position
			startPos=target.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
			local delta=input.Position - dragStart
			target.Position=UDim2.new(startPos.X.Scale, startPos.X.Offset+delta.X, startPos.Y.Scale, startPos.Y.Offset+delta.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
			dragging=false
		end
	end)
end
function GalaxyUI:CreateWindow(opt)
	local w={}
	w.Name=opt.Name or "Window"
	w.Theme=opt.Theme or "Default"
	applyTheme(w.Theme)
	local scr=Instance.new("ScreenGui")
	scr.Name="GalaxyUI_"..w.Name
	scr.ResetOnSpawn=false
	scr.Parent=LocalPlayer:WaitForChild("PlayerGui")
	w.ScreenGui=scr
	local main=Instance.new("Frame")
	main.Name="MainFrame"
	main.Size=UDim2.new(0,600,0,400)
	main.Position=UDim2.new(0.5,-300,0.5,-200)
	main.BackgroundColor3=GalaxyUI.Themes.Default.MainFrame
	main.BackgroundTransparency=0
	main.ClipsDescendants=true
	main.Parent=scr
	local stroke=Instance.new("UIStroke",main)
	stroke.Color=GalaxyUI.Themes.Default.AccentColor
	stroke.Thickness=2
	local corner=Instance.new("UICorner",main)
	corner.CornerRadius=UDim.new(0,12)
	local top=Instance.new("Frame")
	top.Name="Topbar"
	top.Size=UDim2.new(1,0,0,40)
	top.BackgroundColor3=GalaxyUI.Themes.Default.Topbar
	top.Parent=main
	local tcorner=Instance.new("UICorner",top)
	tcorner.CornerRadius=UDim.new(0,12)
	local title=Instance.new("TextLabel")
	title.Size=UDim2.new(1,-60,1,0)
	title.Position=UDim2.new(0,20,0,0)
	title.BackgroundTransparency=1
	title.Text=w.Name
	title.TextColor3=GalaxyUI.Themes.Default.TextColor
	title.Font=Enum.Font.GothamSemibold
	title.TextSize=18
	title.TextXAlignment=Enum.TextXAlignment.Left
	title.Parent=top
	local minimize=Instance.new("TextButton")
	minimize.Size=UDim2.new(0,40,1,0)
	minimize.Position=UDim2.new(1,-40,0,0)
	minimize.BackgroundTransparency=1
	minimize.Text="–"
	minimize.TextColor3=GalaxyUI.Themes.Default.TextColor
	minimize.Font=Enum.Font.GothamBold
	minimize.TextSize=18
	minimize.Parent=top
	local side=Instance.new("Frame")
	side.Name="Sidebar"
	side.Size=UDim2.new(0,GalaxyUI.Themes.Default.SidebarWidth,1,-40)
	side.Position=UDim2.new(0,0,0,40)
	side.BackgroundColor3=GalaxyUI.Themes.Default.SidebarColor
	side.Parent=main
	local scorner=Instance.new("UICorner",side)
	scorner.CornerRadius=UDim.new(0,10)
	local container=Instance.new("Frame")
	container.Name="Container"
	container.Size=UDim2.new(1,-GalaxyUI.Themes.Default.SidebarWidth,1,-40)
	container.Position=UDim2.new(0,GalaxyUI.Themes.Default.SidebarWidth,0,40)
	container.BackgroundTransparency=1
	container.Parent=main
	local list=Instance.new("UIListLayout",side)
	list.SortOrder=Enum.SortOrder.LayoutOrder
	list.Padding=UDim.new(0,8)
	Dragify(top,main)
	w.lastToggleTime=0
	minimize.MouseButton1Click:Connect(function()
		if tick()-w.lastToggleTime<2 then return end
		w.lastToggleTime=tick()
		w:Toggle()
	end)
	main.Size=UDim2.new(0,0,0,0)
	main.Rotation=15
	local tween1=TweenService:Create(main,TweenInfo.new(0.5,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.new(0,600,0,400),Rotation=-5})
	local tween2=TweenService:Create(main,TweenInfo.new(0.3,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=UDim2.new(0,580,0,380),Rotation=0})
	tween1:Play()
	tween1.Completed:Connect(function() tween2:Play() end)
	w.Main=main
	w.Sidebar=side
	w.Container=container
	w.Tabs={}
	w.IsOpen=true
	w.OriginalSize=UDim2.new(0,580,0,380)
	w.LastTab=nil
	function w:Toggle()
		if self.IsOpen then
			for _,tb in pairs(self.Tabs) do tb.Frame.Visible=false end
			SetDescendantsVisibility(self.Main,false)
			self.IsOpen=false
			TweenService:Create(self.Main,TweenInfo.new(0.3,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Size=UDim2.new(0,self.OriginalSize.X.Offset*0.2,0,40),BackgroundTransparency=1}):Play()
			delay(0.3,function() self.Main.Visible=false end)
		else
			self.Main.Visible=true
			self.IsOpen=true
			TweenService:Create(self.Main,TweenInfo.new(0.3,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=self.OriginalSize,BackgroundTransparency=0}):Play()
			delay(0.3,function()
				SetDescendantsVisibility(self.Main,true)
				if self.LastTab then self.LastTab.Frame.Visible=true end
			end)
		end
	end
	local resizeHandle=Instance.new("Frame")
	resizeHandle.Size=UDim2.new(0,20,0,20)
	resizeHandle.AnchorPoint=Vector2.new(1,1)
	resizeHandle.Position=UDim2.new(1,-4,1,-4)
	resizeHandle.BackgroundColor3=GalaxyUI.Themes.Default.AccentColor
	resizeHandle.Parent=main
	local rsCorner=Instance.new("UICorner",resizeHandle)
	rsCorner.CornerRadius=UDim.new(0,6)
	local draggingResize=false
	local resizeStart,startSize
	resizeHandle.InputBegan:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.MouseButton1 then
			draggingResize=true
			resizeStart=input.Position
			startSize=main.AbsoluteSize
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if draggingResize and input.UserInputType==Enum.UserInputType.MouseMovement then
			local delta=input.Position - resizeStart
			local newWidth=math.max(300, startSize.X+delta.X)
			local newHeight=math.max(200, startSize.Y+delta.Y)
			main.Size=UDim2.new(0,newWidth,0,newHeight)
			w.OriginalSize=main.Size
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.MouseButton1 then draggingResize=false end
	end)
	setmetatable(w,{__index=self})
	table.insert(self.Windows,w)
	return w
end
function GalaxyUI:CreateTab(opt)
	local t={}
	t.Name=opt.Name or "Tab"
	t.Icon=opt.Icon or 6031229304
	local btn=Instance.new("TextButton")
	btn.Size=UDim2.new(1,0,0,40)
	btn.BackgroundTransparency=1
	btn.Text=""
	btn.AutoButtonColor=false
	btn.Parent=self.Sidebar
	local icon=Instance.new("ImageLabel")
	icon.Size=UDim2.new(0,20,0,20)
	icon.Position=UDim2.new(0,10,0,10)
	icon.BackgroundTransparency=1
	icon.Parent=btn
	if type(t.Icon)=="string" then
		icon.Image=t.Icon
	else
		icon.Image="rbxassetid://"..t.Icon
	end
	icon.ImageColor3=GalaxyUI.Themes.Default.TextColor
	local txt=Instance.new("TextLabel")
	txt.Size=UDim2.new(1,-40,1,0)
	txt.Position=UDim2.new(0,30,0,0)
	txt.BackgroundTransparency=1
	txt.Text=t.Name
	txt.TextColor3=GalaxyUI.Themes.Default.TextColor
	txt.Font=Enum.Font.Gotham
	txt.TextSize=16
	txt.TextXAlignment=Enum.TextXAlignment.Left
	txt.Parent=btn
	t.Frame=Instance.new("ScrollingFrame")
	t.Frame.Size=UDim2.new(1,0,1,0)
	t.Frame.BackgroundTransparency=1
	t.Frame.ScrollBarThickness=4
	t.Frame.Visible=false
	t.Frame.Parent=self.Container
	local layout=Instance.new("UIListLayout",t.Frame)
	layout.SortOrder=Enum.SortOrder.LayoutOrder
	layout.Padding=UDim.new(0,8)
	btn.MouseButton1Click:Connect(function()
		for _,tb in pairs(self.Tabs) do tb.Frame.Visible=false end
		t.Frame.Visible=true
		self.LastTab=t
		TweenService:Create(t.Frame,TweenInfo.new(0.25,Enum.EasingStyle.Sine),{CanvasPosition=Vector2.new(0,0)}):Play()
	end)
	table.insert(self.Tabs,t)
	return t
end
function GalaxyUI:CreateSection(name,tooltip)
	local f=Instance.new("Frame")
	f.Size=UDim2.new(1,0,0,40)
	f.BackgroundColor3=GalaxyUI.Themes.Default.SectionColor
	local corner=Instance.new("UICorner",f)
	corner.CornerRadius=UDim.new(0,8)
	local lbl=Instance.new("TextLabel")
	lbl.Size=UDim2.new(1,0,1,0)
	lbl.Position=UDim2.new(0,8,0,0)
	lbl.BackgroundTransparency=1
	lbl.Text=name
	lbl.Font=Enum.Font.GothamSemibold
	lbl.TextSize=16
	lbl.TextColor3=GalaxyUI.Themes.Default.TextColor
	lbl.TextXAlignment=Enum.TextXAlignment.Left
	lbl.Parent=f
	return {Frame=f}
end
function GalaxyUI:CreateDivider()
	local d=Instance.new("Frame")
	d.Size=UDim2.new(1,0,0,2)
	d.BackgroundColor3=GalaxyUI.Themes.Default.DividerColor
	local corner=Instance.new("UICorner",d)
	corner.CornerRadius=UDim.new(0,4)
	return {Frame=d}
end
function GalaxyUI:CreateLabel(text,tooltip)
	local f=Instance.new("Frame")
	f.Size=UDim2.new(1,0,0,30)
	f.BackgroundColor3=GalaxyUI.Themes.Default.ButtonColor
	local corner=Instance.new("UICorner",f)
	corner.CornerRadius=UDim.new(0,8)
	local l=Instance.new("TextLabel")
	l.Size=UDim2.new(1,0,1,0)
	l.BackgroundTransparency=1
	l.Text=text
	l.TextColor3=GalaxyUI.Themes.Default.TextColor
	l.Font=Enum.Font.Gotham
	l.TextSize=14
	l.Parent=f
	local o={Frame=f}
	function o:Set(t) l.Text=t end
	return o
end
function GalaxyUI:CreateParagraph(opt)
	local f=Instance.new("Frame")
	f.Size=UDim2.new(1,0,0,80)
	f.BackgroundColor3=GalaxyUI.Themes.Default.ButtonColor
	local corner=Instance.new("UICorner",f)
	corner.CornerRadius=UDim.new(0,8)
	local title=Instance.new("TextLabel")
	title.Size=UDim2.new(1,0,0,30)
	title.Position=UDim2.new(0,8,0,0)
	title.BackgroundTransparency=1
	title.Text=opt.Title or ""
	title.TextColor3=GalaxyUI.Themes.Default.TextColor
	title.Font=Enum.Font.GothamSemibold
	title.TextSize=14
	title.Parent=f
	local content=Instance.new("TextLabel")
	content.Size=UDim2.new(1,0,0,50)
	content.Position=UDim2.new(0,8,0,30)
	content.BackgroundTransparency=1
	content.Text=opt.Content or ""
	content.TextColor3=GalaxyUI.Themes.Default.TextColor
	content.Font=Enum.Font.Gotham
	content.TextSize=12
	content.TextWrapped=true
	content.Parent=f
	local o={Frame=f}
	function o:Set(x) title.Text=x.Title or "" content.Text=x.Content or "" end
	return o
end
function GalaxyUI:CreateButton(opt)
	local f=Instance.new("Frame")
	f.Size=UDim2.new(1,0,0, thirty)
	f.BackgroundColor3=GalaxyUI.Themes.Default.ButtonColor
	local corner=Instance.new("UICorner",f)
	corner.CornerRadius=UDim.new(0,8)
	local btn=Instance.new("TextButton")
	btn.Size=UDim2.new(1,0,1,0)
	btn.BackgroundTransparency=1
	btn.Text=opt.Name or "Button"
	btn.TextColor3=GalaxyUI.Themes.Default.TextColor
	btn.Font=Enum.Font.Gotham
	btn.TextSize=14
	btn.AutoButtonColor=false
	btn.Parent=f
	btn.MouseButton1Click:Connect(function() if opt.Callback then opt.Callback() end end)
	local o={Frame=f}
	function o:SetText(x) btn.Text=x end
	return o
end
function GalaxyUI:CreateToggle(opt)
	local f=Instance.new("Frame")
	f.Size=UDim2.new(1,0,0,40)
	f.BackgroundColor3=GalaxyUI.Themes.Default.ButtonColor
	local corner=Instance.new("UICorner",f)
	corner.CornerRadius=UDim.new(0,8)
	local l=Instance.new("TextLabel")
	l.Size=UDim2.new(1,-70,1,0)
	l.Position=UDim2.new(0,8,0,0)
	l.BackgroundTransparency=1
	l.Text=opt.Name or "Toggle"
	l.TextColor3=GalaxyUI.Themes.Default.TextColor
	l.Font=Enum.Font.Gotham
	l.TextSize=14
	l.TextXAlignment=Enum.TextXAlignment.Left
	l.Parent=f
	local t=Instance.new("TextButton")
	t.Size=UDim2.new(0,50,0, twenty)
	t.Position=UDim2.new(1,-60,0.5,-10)
	t.BackgroundColor3=Color3.fromRGB(180,180,180)
	t.Text=""
	t.Parent=f
	local tc=Instance.new("UICorner",t)
	tc.CornerRadius=UDim.new(0,8)
	local val=opt.CurrentValue==true
	local function upd(x)
		val=x
		if opt.Flag then GalaxyUI.Flags[opt.Flag]=x end
		t.BackgroundColor3=x and GalaxyUI.Themes.Default.AccentColor or Color3.fromRGB(180,180,180)
		if opt.Callback then opt.Callback(x) end
	end
	t.MouseButton1Click:Connect(function() upd(not val) end)
	upd(val)
	local o={Frame=f}
	function o:SetValue(v) upd(v) end
	return o
end
function GalaxyUI:CreateSlider(opt)
	local container=Instance.new("Frame")
	container.Size=UDim2.new(1,0,0,40)
	container.BackgroundTransparency=1
	local label=Instance.new("TextLabel")
	label.Size=UDim2.new(0,80,1,0)
	label.Position=UDim2.new(0,8,0,0)
	label.BackgroundTransparency=1
	label.Text=opt.Name or "Slider"
	label.TextColor3=GalaxyUI.Themes.Default.TextColor
	label.Font=Enum.Font.Gotham
	label.TextSize=14
	label.TextXAlignment=Enum.TextXAlignment.Left
	label.Parent=container
	local sliderBar=Instance.new("Frame")
	sliderBar.Size=UDim2.new(0,container.AbsoluteSize.X-100,0,10)
	sliderBar.Position=UDim2.new(0,90,0.5,-5)
	sliderBar.BackgroundColor3=Color3.fromRGB(220,220,220)
	local barCorner=Instance.new("UICorner",sliderBar)
	barCorner.CornerRadius=UDim.new(0,5)
	sliderBar.Parent=container
	local fill=Instance.new("Frame")
	fill.Size=UDim2.new(0,0,1,0)
	fill.BackgroundColor3=GalaxyUI.Themes.Default.AccentColor
	local fillCorner=Instance.new("UICorner",fill)
	fillCorner.CornerRadius=UDim.new(0,5)
	fill.Parent=sliderBar
	local numLabel=Instance.new("TextLabel")
	numLabel.Size=UDim2.new(0,40,1,0)
	numLabel.Position=UDim2.new(1,5,0,0)
	numLabel.BackgroundTransparency=1
	numLabel.TextColor3=GalaxyUI.Themes.Default.TextColor
	numLabel.Font=Enum.Font.GothamBold
	numLabel.TextSize=14
	numLabel.Text=tostring(opt.CurrentValue or 0)
	numLabel.Parent=container
	local mi=opt.Range and opt.Range[1] or 0
	local ma=opt.Range and opt.Range[2] or 100
	local inc=opt.Increment or 1
	local cval=opt.CurrentValue or mi
	local function setv(v)
		v=math.clamp(v,mi,ma)
		v=math.floor(v/inc+0.5)*inc
		if opt.Flag then GalaxyUI.Flags[opt.Flag]=v end
		numLabel.Text=tostring(v)
		local p=(v-mi)/(ma-mi)
		fill.Size=UDim2.new(p,0,1,0)
		if opt.Callback then opt.Callback(v) end
		cval=v
	end
	setv(cval)
	sliderBar.InputBegan:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.MouseButton1 then
			local move,release
			move=UserInputService.InputChanged:Connect(function(x)
				if x.UserInputType==Enum.UserInputType.MouseMovement then
					local pos=x.Position.X-sliderBar.AbsolutePosition.X
					local ratio=pos/sliderBar.AbsoluteSize.X
					setv(mi+ratio*(ma-mi))
				end
			end)
			release=UserInputService.InputEnded:Connect(function(x2)
				if x2.UserInputType==Enum.UserInputType.MouseButton1 then
					move:Disconnect()
					release:Disconnect()
				end
			end)
		end
	end)
	local o={Frame=container}
	function o:SetValue(v) setv(v) end
	return o
end
function GalaxyUI:CreateKeybind(opt)
	local f=Instance.new("Frame")
	f.Size=UDim2.new(1,0,0,40)
	f.BackgroundColor3=GalaxyUI.Themes.Default.ButtonColor
	local co=Instance.new("UICorner",f)
	co.CornerRadius=UDim.new(0,8)
	local l=Instance.new("TextLabel")
	l.Size=UDim2.new(1,-100,1,0)
	l.Position=UDim2.new(0,8,0,0)
	l.BackgroundTransparency=1
	l.Text=opt.Name or "Keybind"
	l.TextColor3=GalaxyUI.Themes.Default.TextColor
	l.Font=Enum.Font.Gotham
	l.TextSize=14
	l.TextXAlignment=Enum.TextXAlignment.Left
	l.Parent=f
	local b=Instance.new("TextButton")
	b.Size=UDim2.new(0,80,0,30)
	b.Position=UDim2.new(1,-88,0.5,-15)
	b.BackgroundColor3=Color3.fromRGB(200,200,200)
	b.Text=opt.CurrentKeybind or "None"
	b.TextColor3=Color3.fromRGB(20,20,20)
	b.Font=Enum.Font.GothamBold
	b.TextSize=14
	b.Parent=f
	local bc=Instance.new("UICorner",b)
	bc.CornerRadius=UDim.new(0,8)
	local c=opt.CurrentKeybind or "None"
	local cap=false
	local function setk(k)
		c=k
		b.Text=k
		if opt.Flag then GalaxyUI.Flags[opt.Flag]=k end
	end
	b.MouseButton1Click:Connect(function()
		if cap then return end
		cap=true
		b.Text="Press..."
	end)
	UserInputService.InputBegan:Connect(function(i,p)
		if p then return end
		if cap then
			if i.KeyCode~=Enum.KeyCode.Unknown then
				setk(i.KeyCode.Name)
				cap=false
			end
		else
			if i.KeyCode.Name==c and not opt.HoldToInteract then
				if opt.Callback then opt.Callback(false) end
			end
		end
	end)
	UserInputService.InputEnded:Connect(function(i,p)
		if p then return end
		if opt.HoldToInteract and i.KeyCode.Name==c then
			if opt.Callback then opt.Callback(true) end
		end
	end)
	local o={Frame=f}
	function o:SetKey(k) setk(k) end
	return o
end
function GalaxyUI:CreateTextBox(opt)
	local f=Instance.new("Frame")
	f.Size=UDim2.new(1,0,0,40)
	f.BackgroundColor3=GalaxyUI.Themes.Default.ButtonColor
	local co=Instance.new("UICorner",f)
	co.CornerRadius=UDim.new(0,8)
	local box=Instance.new("TextBox")
	box.Size=UDim2.new(1,0,1,0)
	box.BackgroundTransparency=1
	box.Text=opt.Placeholder or ""
	box.PlaceholderText=opt.Placeholder or ""
	box.TextColor3=GalaxyUI.Themes.Default.TextColor
	box.Font=Enum.Font.Gotham
	box.TextSize=14
	box.ClearTextOnFocus=opt.ClearTextOnFocus or false
	box.Parent=f
	if opt.Callback then
		box.FocusLost:Connect(function() opt.Callback(box.Text) end)
	end
	local o={Frame=f,Box=box}
	function o:SetText(t) box.Text=t end
	return o
end
function GalaxyUI:CreateDropdown(opt)
	local container=Instance.new("Frame")
	container.Size=UDim2.new(1,0,0,40)
	container.BackgroundColor3=GalaxyUI.Themes.Default.ButtonColor
	container.ClipsDescendants=false
	local co=Instance.new("UICorner",container)
	co.CornerRadius=UDim.new(0,8)
	local mainButton=Instance.new("TextButton")
	mainButton.Size=UDim2.new(1,0,1,0)
	mainButton.BackgroundTransparency=1
	mainButton.Text=opt.CurrentOption or opt.Name or "Select an option"
	mainButton.TextColor3=GalaxyUI.Themes.Default.TextColor
	mainButton.Font=Enum.Font.Gotham
	mainButton.TextSize=14
	mainButton.Parent=container
	local mainButtonCorner=Instance.new("UICorner",mainButton)
	mainButtonCorner.CornerRadius=UDim.new(0,8)
	local dropdownFrame=Instance.new("Frame")
	dropdownFrame.Size=UDim2.new(1,0,0,120)
	dropdownFrame.Position=UDim2.new(0,0,1,4)
	dropdownFrame.BackgroundColor3=GalaxyUI.Themes.Default.ButtonColor
	dropdownFrame.Visible=false
	dropdownFrame.ZIndex=50
	dropdownFrame.ClipsDescendants=true
	local dco=Instance.new("UICorner",dropdownFrame)
	dco.CornerRadius=UDim.new(0,8)
	dropdownFrame.Parent=container
	local optionsFrame=Instance.new("ScrollingFrame")
	optionsFrame.Size=UDim2.new(1,0,1,0)
	optionsFrame.Position=UDim2.new(0,0,0,0)
	optionsFrame.BackgroundTransparency=1
	optionsFrame.ScrollBarThickness=4
	optionsFrame.ZIndex=51
	optionsFrame.Parent=dropdownFrame
	local layout=Instance.new("UIListLayout",optionsFrame)
	layout.SortOrder=Enum.SortOrder.LayoutOrder
	layout.Padding=UDim.new(0,4)
	local optionsList=opt.Options or {}
	local function populate(list)
		optionsFrame:ClearAllChildren()
		local layout=Instance.new("UIListLayout",optionsFrame)
		layout.SortOrder=Enum.SortOrder.LayoutOrder
		layout.Padding=UDim.new(0,4)
		for i,option in ipairs(list) do
			local btn=Instance.new("TextButton")
			btn.Size=UDim2.new(1,-8,0,30)
			btn.Position=UDim2.new(0,4,0,0)
			btn.BackgroundColor3=GalaxyUI.Themes.Default.Topbar
			local btnCorner=Instance.new("UICorner",btn)
			btnCorner.CornerRadius=UDim.new(0,8)
			btn.TextColor3=GalaxyUI.Themes.Default.TextColor
			btn.Font=Enum.Font.Gotham
			btn.TextSize=14
			btn.Text=option
			btn.ZIndex=52
			btn.Parent=optionsFrame
			btn.MouseButton1Click:Connect(function()
				mainButton.Text=option
				dropdownFrame.Visible=false
				if opt.Callback then opt.Callback(option) end
			end)
		end
	end
	populate(optionsList)
	mainButton.MouseButton1Click:Connect(function() dropdownFrame.Visible=not dropdownFrame.Visible end)
	local o={Frame=container,Main=mainButton}
	function o:SetOptions(list) optionsList=list populate(optionsList) end
	function o:SetOption(option) mainButton.Text=option if opt.Callback then opt.Callback(option) end end
	function o:Refresh(list) self:SetOptions(list) end
	function o:SetValue(option) self:SetOption(option) end
	return o
end
function GalaxyUI:CreateColorPicker(opt)
	local container=Instance.new("Frame")
	container.Size=UDim2.new(1,0,0,160)
	container.BackgroundColor3=GalaxyUI.Themes.Default.ButtonColor
	local co=Instance.new("UICorner",container)
	co.CornerRadius=UDim.new(0,8)
	local title=Instance.new("TextLabel")
	title.Size=UDim2.new(1,0,0,30)
	title.Position=UDim2.new(0,8,0,0)
	title.BackgroundTransparency=1
	title.Text=opt.Name or "Color Picker"
	title.TextColor3=GalaxyUI.Themes.Default.TextColor
	title.Font=Enum.Font.GothamSemibold
	title.TextSize=14
	title.Parent=container
	local preview=Instance.new("Frame")
	preview.Size=UDim2.new(0,40,0,40)
	preview.Position=UDim2.new(0,8,0,40)
	preview.BackgroundColor3=opt.CurrentColor or Color3.new(1,0,0)
	preview.Parent=container
	preview:SetAttribute("r",math.floor((opt.CurrentColor and opt.CurrentColor.R or 1)*255))
	preview:SetAttribute("g",math.floor((opt.CurrentColor and opt.CurrentColor.G or 0)*255))
	preview:SetAttribute("b",math.floor((opt.CurrentColor and opt.CurrentColor.B or 0)*255))
	local function createSlider(axis,pos)
		local slider=self:CreateSlider({
			Name=axis,
			Range={0,255},
			Increment=1,
			CurrentValue=preview:GetAttribute(axis),
			Callback=function(val)
				local r=preview:GetAttribute("r")
				local g=preview:GetAttribute("g")
				local b=preview:GetAttribute("b")
				if axis=="r" then r=val end
				if axis=="g" then g=val end
				if axis=="b" then b=val end
				preview:SetAttribute("r",r)
				preview:SetAttribute("g",g)
				preview:SetAttribute("b",b)
				local newColor=Color3.fromRGB(r,g,b)
				preview.BackgroundColor3=newColor
				if opt.Callback then opt.Callback(newColor) end
			end
		})
		slider.Frame.Position=pos
		slider.Frame.Parent=container
	end
	createSlider("r",UDim2.new(0,60,0,40))
	createSlider("g",UDim2.new(0,60,0,70))
	createSlider("b",UDim2.new(0,60,0,100))
	return {Frame=container}
end
function GalaxyUI:CreateMultiDropdown(opt)
	local container=Instance.new("Frame")
	container.Size=UDim2.new(1,0,0,80)
	container.BackgroundColor3=GalaxyUI.Themes.Default.ButtonColor
	local co=Instance.new("UICorner",container)
	co.CornerRadius=UDim.new(0,8)
	local mainButton=Instance.new("TextButton")
	mainButton.Size=UDim2.new(1,0,1,0)
	mainButton.BackgroundTransparency=1
	mainButton.Text=opt.Name or "Select options"
	mainButton.TextColor3=GalaxyUI.Themes.Default.TextColor
	mainButton.Font=Enum.Font.Gotham
	mainButton.TextSize=14
	mainButton.Parent=container
	local dropdownFrame=Instance.new("Frame")
	dropdownFrame.Size=UDim2.new(1,0,0,120)
	dropdownFrame.Position=UDim2.new(0,0,1,4)
	dropdownFrame.BackgroundColor3=GalaxyUI.Themes.Default.ButtonColor
	dropdownFrame.Visible=false
	dropdownFrame.ZIndex=50
	dropdownFrame.ClipsDescendants=true
	local dco=Instance.new("UICorner",dropdownFrame)
	dco.CornerRadius=UDim.new(0,8)
	dropdownFrame.Parent=container
	local optionsFrame=Instance.new("ScrollingFrame")
	optionsFrame.Size=UDim2.new(1,0,1,0)
	optionsFrame.Position=UDim2.new(0,0,0,0)
	optionsFrame.BackgroundTransparency=1
	optionsFrame.ScrollBarThickness=4
	optionsFrame.ZIndex=51
	optionsFrame.Parent=dropdownFrame
	local layout=Instance.new("UIListLayout",optionsFrame)
	layout.SortOrder=Enum.SortOrder.LayoutOrder
	layout.Padding=UDim.new(0,4)
	local optionsList=opt.Options or {}
	local selected={}
	local function populate(list)
		for _,child in pairs(optionsFrame:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
		for i,option in ipairs(list) do
			local btn=Instance.new("TextButton")
			btn.Size=UDim2.new(1,-8,0,30)
			btn.Position=UDim2.new(0,4,0,0)
			btn.BackgroundColor3=GalaxyUI.Themes.Default.Topbar
			local btnCorner=Instance.new("UICorner",btn)
			btnCorner.CornerRadius=UDim.new(0,8)
			btn.TextColor3=GalaxyUI.Themes.Default.TextColor
			btn.Font=Enum.Font.Gotham
			btn.TextSize=14
			btn.Text=option
			btn.ZIndex=52
			btn.Parent=optionsFrame
			btn.MouseButton1Click:Connect(function()
				if table.find(selected,option) then
					for i,v in ipairs(selected) do if v==option then table.remove(selected,i) break end end
				else
					table.insert(selected,option)
				end
				local text=opt.Name or "Select options"
				if #selected>0 then text=table.concat(selected,", ") end
				mainButton.Text=text
				if opt.Callback then opt.Callback(selected) end
			end)
		end
	end
	populate(optionsList)
	mainButton.MouseButton1Click:Connect(function() dropdownFrame.Visible=not dropdownFrame.Visible end)
	local o={Frame=container,Main=mainButton,GetSelected=function() return selected end}
	return o
end
function GalaxyUI:ShowModal(opt)
	local sg=Instance.new("ScreenGui")
	sg.Name="GalaxyUIModal"
	sg.ResetOnSpawn=false
	sg.Parent=LocalPlayer:WaitForChild("PlayerGui")
	local modal=Instance.new("Frame")
	modal.Size=UDim2.new(0,400,0,200)
	modal.Position=UDim2.new(0.5,-200,0.5,-100)
	modal.BackgroundColor3=GalaxyUI.Themes.Default.MainFrame
	modal.Parent=sg
	local title=Instance.new("TextLabel")
	title.Size=UDim2.new(1,0,0,40)
	title.BackgroundColor3=GalaxyUI.Themes.Default.Topbar
	title.Text=opt.Title or "Modal"
	title.TextColor3=GalaxyUI.Themes.Default.TextColor
	title.Font=Enum.Font.GothamSemibold
	title.TextSize=16
	title.Parent=modal
	local message=Instance.new("TextLabel")
	message.Size=UDim2.new(1,-20,0,80)
	message.Position=UDim2.new(0,10,0,40)
	message.BackgroundTransparency=1
	message.Text=opt.Message or ""
	message.TextColor3=GalaxyUI.Themes.Default.TextColor
	message.Font=Enum.Font.Gotham
	message.TextSize=14
	message.TextWrapped=true
	message.Parent=modal
	local btnYes=Instance.new("TextButton")
	btnYes.Size=UDim2.new(0,100,0,40)
	btnYes.Position=UDim2.new(0.25,-50,1,-50)
	btnYes.BackgroundColor3=GalaxyUI.Themes.Default.AccentColor
	btnYes.Text=opt.ConfirmText or "OK"
	btnYes.TextColor3=GalaxyUI.Themes.Default.TextColor
	btnYes.Font=Enum.Font.GothamBold
	btnYes.TextSize=16
	btnYes.Parent=modal
	local btnNo=Instance.new("TextButton")
	btnNo.Size=UDim2.new(0,100,0,40)
	btnNo.Position=UDim2.new(0.75,-50,1,-50)
	btnNo.BackgroundColor3=Color3.fromRGB(200,200,200)
	btnNo.Text=opt.CancelText or "Cancel"
	btnNo.TextColor3=GalaxyUI.Themes.Default.TextColor
	btnNo.Font=Enum.Font.GothamBold
	btnNo.TextSize=16
	btnNo.Parent=modal
	local result
	btnYes.MouseButton1Click:Connect(function()
		result=true
		sg:Destroy()
		if opt.Callback then opt.Callback(true) end
	end)
	btnNo.MouseButton1Click:Connect(function()
		result=false
		sg:Destroy()
		if opt.Callback then opt.Callback(false) end
	end)
	return result
end
UserInputService.InputBegan:Connect(function(input,gameProcessed)
	if not gameProcessed and input.KeyCode==GalaxyUI.ToggleKey then
		local allOpen=true
		for _,w in ipairs(GalaxyUI.Windows) do if not w.IsOpen then allOpen=false break end end
		for _,w in ipairs(GalaxyUI.Windows) do
			if allOpen then
				if w.IsOpen then w:Toggle() end
			else
				if not w.IsOpen then w:Toggle() end
			end
		end
	end
end)
if UserInputService.TouchEnabled then
	local mobileToggleButton=Instance.new("TextButton")
	mobileToggleButton.Size=UDim2.new(0,60,0,60)
	mobileToggleButton.Position=UDim2.new(1,-70,1,-70)
	mobileToggleButton.BackgroundColor3=GalaxyUI.Themes.Default.AccentColor
	mobileToggleButton.Text="UI"
	mobileToggleButton.TextColor3=GalaxyUI.Themes.Default.TextColor
	mobileToggleButton.Font=Enum.Font.GothamBold
	mobileToggleButton.TextSize=16
	mobileToggleButton.Parent=LocalPlayer:WaitForChild("PlayerGui")
	mobileToggleButton.ZIndex=999
	mobileToggleButton.MouseButton1Click:Connect(function()
		for _,w in ipairs(GalaxyUI.Windows) do w:Toggle() end
	end)
end
return GalaxyUI

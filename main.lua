if _G.VisionHubLoaded then return end
_G.VisionHubLoaded = true
local discordInvite = "https://discord.gg/Ygcq9dpW9t"
if setclipboard then setclipboard(discordInvite) end
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local Root = Character:WaitForChild("HumanoidRootPart")
_G.GodModeActive = false
_G.NoclipActive = false
_G.InfiniteJumpEnabled = false
_G.AutoWeaponCollectActive = false
_G.ClickTeleportEnabled = false
_G.FOVValue = Camera.FieldOfView
_G.XrayEnabled = false
_G.AutoFarmActive = false
_G.PlayerRole = nil
_G.AllowedList = {}
_G.ESPAllEnabled = false
_G.ESPMurdererEnabled = false
_G.ESPSheriffEnabled = false
_G.ESPHeroEnabled = false
_G.ESPGunEnabled = false
_G.ESPColorDefault = Color3.fromRGB(0,225,0)
_G.ESPColorMurderer = Color3.fromRGB(225,0,0)
_G.ESPColorSheriff = Color3.fromRGB(0,0,225)
_G.ESPColorHero = Color3.fromRGB(255,255,0)
_G.ESPColorGun = Color3.fromRGB(0,255,255)
_G.XrayTransparency = 0.75
_G.ESPOutlineTransparency = 0
_G.ESPFillTransparency = 0.2
_G.ESPOutlineColor = Color3.new(0,0,0)
local desiredWalkSpeed = 16
local desiredJumpPower = 50
local autoFarmSpeed = 1
local autoFarmMapNames = {"Bank","Bank2","BioLab","Cargo","Coliseum","DodgeballArena","Factory","HOUSE3","Hospital2","Hospital3","Hotel","Hotel2","House2","House3","Kinglabratory","Lab2","Mansion","Mansion2","Mansion3","MilBase","Mineshaft","Office2","Office3","PoliceStation","Pond","ResearchFacility","Resort","Station","Workplace","Workshop","nSOFFICE"}
_G.ShootOffset = 2.8
_G.OffsetToPingMultiplier = 1
_G.AutoShooting = false
local antiFling = false
local antiFlingLastPos = Vector3.zero
local flingNeutralizerCon, flingDetectionCon
local detectedPlayers = {}
local lastLocalNotification = 0
local RoleModule = {}
local rolesData = {}
local Murderer, Sheriff, Hero
function RoleModule:updateRoles()
	local getPlayerData = ReplicatedStorage:FindFirstChild("GetPlayerData", true)
	if getPlayerData then
		local success, data = pcall(function() return getPlayerData:InvokeServer() end)
		if success and data then
			rolesData = data
			for playerName, info in pairs(rolesData) do
				if info.Role == "Murderer" then
					Murderer = playerName
				elseif info.Role == "Sheriff" then
					Sheriff = playerName
				elseif info.Role == "Hero" then
					Hero = playerName
				end
			end
		end
	end
end
function RoleModule.findSheriff()
	if Sheriff and Sheriff == LocalPlayer.Name then
		return LocalPlayer
	end
	return nil
end
function RoleModule.findMurderer()
	if Murderer then
		return Players:FindFirstChild(Murderer)
	end
	return nil
end
function RoleModule.findOtherSheriff()
	if Sheriff and Sheriff ~= LocalPlayer.Name then
		return Players:FindFirstChild(Sheriff)
	end
	return nil
end
task.spawn(function()
	while true do
		RoleModule:updateRoles()
		task.wait(1)
	end
end)
local ActionModule = {}
function ActionModule.getPing()
	return LocalPlayer:GetNetworkPing() or 0.1
end
function ActionModule.autoDetectParameters()
	local ping = ActionModule.getPing()
	_G.OffsetToPingMultiplier = 1 + math.clamp((ping - 0.1) * 2, 0, 2)
	_G.ShootOffset = 2.8 + (ping * 3)
end
function ActionModule.getTargetPart(target)
	if target and target.Character then
		local character = target.Character
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local hrp = character:FindFirstChild("HumanoidRootPart")
		local head = character:FindFirstChild("Head")
		if humanoid then
			local state = humanoid:GetState()
			if state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall or math.abs(hrp.Velocity.Y) > 10 then
				return head or hrp
			end
		end
		local upperTorso = character:FindFirstChild("UpperTorso")
		return upperTorso or hrp
	end
	return nil
end
function ActionModule.getPredictedPosition(target, offset)
	local targetPart = ActionModule.getTargetPart(target)
	if targetPart then
		local velocity = targetPart.AssemblyLinearVelocity or Vector3.new(0,0,0)
		local pingFactor = ActionModule.getPing() * _G.OffsetToPingMultiplier
		local predictionTime = offset / 15 + pingFactor
		local rawPrediction = targetPart.Position + (velocity * predictionTime)
		return targetPart.Position:Lerp(rawPrediction, 0.7)
	end
	return nil
end
function ActionModule.getGun()
	local character = LocalPlayer.Character
	if character then
		local gun = character:FindFirstChild("Gun")
		if gun then return gun end
	end
	local backpack = LocalPlayer:FindFirstChild("Backpack")
	if backpack then
		local gun = backpack:FindFirstChild("Gun")
		if gun then return gun end
	end
	return nil
end
function ActionModule.hasGun()
	return (ActionModule.getGun() ~= nil)
end
function ActionModule.equipGun()
	if not LocalPlayer.Character then return false end
	local character = LocalPlayer.Character
	local gun = character:FindFirstChild("Gun")
	if not gun then
		local backpack = LocalPlayer:FindFirstChild("Backpack")
		if backpack then
			local gunInBackpack = backpack:FindFirstChild("Gun")
			if gunInBackpack then
				local hum = character:FindFirstChild("Humanoid")
				if hum then
					pcall(function() hum:EquipTool(gunInBackpack) end)
					return true
				end
			else
				return false
			end
		end
	end
	return true
end
function performShoot(target)
	if not (RoleModule.findSheriff() or ActionModule.hasGun()) then return end
	if not target or not target.Character then return end
	if not ActionModule.equipGun() then return end
	ActionModule.autoDetectParameters()
	local predictedPosition = ActionModule.getPredictedPosition(target, _G.ShootOffset)
	if not predictedPosition then return end
	local args = {1, predictedPosition, "AH2"}
	local character = LocalPlayer.Character
	if character then
		local gun = character:FindFirstChild("Gun")
		if gun then
			local knifeLocal = gun:FindFirstChild("KnifeLocal")
			if knifeLocal then
				local createBeam = knifeLocal:FindFirstChild("CreateBeam")
				if createBeam then
					local remoteFunction = createBeam:IsA("RemoteFunction") and createBeam or createBeam:FindFirstChildWhichIsA("RemoteFunction")
					if remoteFunction and remoteFunction:IsA("RemoteFunction") then
						pcall(function() remoteFunction:InvokeServer(unpack(args)) end)
					end
				end
			end
		end
	end
end
LocalPlayer.Idled:Connect(function()
	local VirtualUser = game:GetService("VirtualUser")
	VirtualUser:CaptureController()
	VirtualUser:ClickButton2(Vector2.new())
end)
local function updateRoleDisplay()
	local getData = ReplicatedStorage:FindFirstChild("GetPlayerData", true)
	if getData then
		local success, returnedData = pcall(function() return getData:InvokeServer() end)
		if success and returnedData then
			local data = returnedData[LocalPlayer.Name]
			if data and data.Role then
				_G.PlayerRole = data.Role
				Rayfield:Notify({Title = "Role", Content = data.Role, Duration = 10, Image = "user-check"})
			end
		end
	end
end
local function monitorRoundTimer()
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local getTimer = remotes and remotes:FindFirstChild("Extras") and remotes.Extras:FindFirstChild("GetTimer")
	if not getTimer then return end
	local okPrev, prevTime = pcall(function() return getTimer:InvokeServer() end)
	if not okPrev or not prevTime then prevTime = 0 end
	while task.wait(1) do
		local okCurr, currTime = pcall(function() return getTimer:InvokeServer() end)
		if not okCurr or not currTime then currTime = 0 end
		if prevTime <= 5 and currTime >= 50 then
			updateRoleDisplay()
		end
		prevTime = currTime
	end
end
task.spawn(monitorRoundTimer)
local function protectHumanoid(h)
	if not h then return end
	h.HealthChanged:Connect(function(newHealth)
		if _G.GodModeActive and newHealth < h.MaxHealth then h.Health = h.MaxHealth end
	end)
end
protectHumanoid(Humanoid)
pcall(function()
	local oldTakeDamage = hookfunction(Humanoid.TakeDamage, function(self, dmg)
		if _G.GodModeActive then return end
		return oldTakeDamage(self, dmg)
	end)
	local oldBreakJoints = hookfunction(Humanoid.BreakJoints, function(self, ...)
		if _G.GodModeActive then return end
		return oldBreakJoints(self, ...)
	end)
	local oldDestroy = hookfunction(Humanoid.Destroy, function(self, ...)
		if _G.GodModeActive then return end
		return oldDestroy(self, ...)
	end)
	local mt = getrawmetatable(game)
	local oldNewIndex = mt.__newindex
	setreadonly(mt, false)
	mt.__newindex = newcclosure(function(t, k, v)
		if _G.GodModeActive and t == Humanoid and k == "Health" then return oldNewIndex(t, k, t.MaxHealth) end
		return oldNewIndex(t, k, v)
	end)
	setreadonly(mt, true)
	local oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(s, ...)
		local m = getnamecallmethod()
		if _G.GodModeActive and not checkcaller() then
			if m == "FireServer" or m == "InvokeServer" then return end
		end
		return oldNamecall(s, ...)
	end))
end)
RunService.Stepped:Connect(function()
	if _G.NoclipActive and Character then
		for _, part in ipairs(Character:GetDescendants()) do
			if part:IsA("BasePart") then part.CanCollide = false end
		end
	end
end)
UserInputService.JumpRequest:Connect(function()
	if _G.InfiniteJumpEnabled then Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
end)
LocalPlayer.CharacterAdded:Connect(function(character)
	Character = character
	Humanoid = character:WaitForChild("Humanoid")
	Root = character:WaitForChild("HumanoidRootPart")
	task.wait(0.5)
	protectHumanoid(Humanoid)
end)
local function autoCollectWeapon()
	if not Character then return end
	local hum = Character:FindFirstChild("Humanoid")
	local rootPart = Character:FindFirstChild("HumanoidRootPart")
	if not hum or hum.Health <= 0 or not rootPart then return end
	if _G.PlayerRole and string.lower(_G.PlayerRole) == "murderer" then return end
	local function detectMap()
		for _, n in ipairs(autoFarmMapNames) do
			local f = Workspace:FindFirstChild(n)
			if f then return f end
		end
	end
	local map = detectMap()
	if not map then return end
	local gunDrop = map:FindFirstChild("GunDrop")
	if not gunDrop or not gunDrop:IsA("BasePart") or not gunDrop.Parent then return end
	gunDrop.CFrame = rootPart.CFrame * CFrame.new(0,2,0)
	task.wait(0.1)
	firetouchinterest(gunDrop, rootPart, 1)
	firetouchinterest(gunDrop, rootPart, 0)
end
task.spawn(function()
	while true do
		if _G.AutoWeaponCollectActive then
			autoCollectWeapon()
		end
		task.wait(0.5)
	end
end)
local function attackEnemies()
	pcall(function()
		local knife = LocalPlayer.Backpack:FindFirstChild("Knife") or (Character and Character:FindFirstChild("Knife"))
		if knife and knife.Parent == LocalPlayer.Backpack and Humanoid then
			Humanoid:EquipTool(knife)
		end
		if knife then
			for _, plr in ipairs(Players:GetPlayers()) do
				if plr ~= LocalPlayer and plr.Character and not table.find(_G.AllowedList, plr.Name) then
					local part = plr.Character:FindFirstChild("HumanoidRootPart")
					if part then
						local VirtualUser = game:GetService("VirtualUser")
						VirtualUser:ClickButton1(Vector2.new())
						firetouchinterest(part, knife.Handle, 1)
						firetouchinterest(part, knife.Handle, 0)
					end
				end
			end
		end
	end)
end
local roles = {}
local function updatePlayerHighlights()
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and p.Character then
			local hl = p.Character:FindFirstChild("Highlight") or Instance.new("Highlight", p.Character)
			hl.Name = "Highlight"
			hl.OutlineTransparency = _G.ESPOutlineTransparency
			hl.FillTransparency = _G.ESPFillTransparency
			hl.OutlineColor = _G.ESPOutlineColor
			local roleData = roles[p.Name]
			local role = roleData and roleData.Role or nil
			if _G.ESPAllEnabled then
				if role then
					if role == "Murderer" then
						hl.FillColor = _G.ESPColorMurderer
					elseif role == "Sheriff" then
						hl.FillColor = _G.ESPColorSheriff
					elseif role == "Hero" then
						hl.FillColor = _G.ESPColorHero
					else
						hl.FillColor = _G.ESPColorDefault
					end
				else
					hl.FillColor = _G.ESPColorDefault
				end
				hl.Enabled = true
			else
				if role == "Murderer" and _G.ESPMurdererEnabled then
					hl.FillColor = _G.ESPColorMurderer
					hl.Enabled = true
				elseif role == "Sheriff" and _G.ESPSheriffEnabled then
					hl.FillColor = _G.ESPColorSheriff
					hl.Enabled = true
				elseif role == "Hero" and _G.ESPHeroEnabled then
					hl.FillColor = _G.ESPColorHero
					hl.Enabled = true
				else
					hl.Enabled = false
				end
			end
		end
	end
end
local function removePlayerHighlights()
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and p.Character then
			local hl = p.Character:FindFirstChild("Highlight")
			if hl then hl.Enabled = false end
		end
	end
end
local function updateGunDropHighlights()
	local gunDropFound = false
	for _, mapName in ipairs(autoFarmMapNames) do
		local map = Workspace:FindFirstChild(mapName)
		if map then
			local gunDrop = map:FindFirstChild("GunDrop")
			if gunDrop and gunDrop:IsA("BasePart") then
				gunDropFound = true
				if _G.ESPGunEnabled then
					if not gunDrop:FindFirstChild("GunDropHighlight") then
						local hl = Instance.new("Highlight")
						hl.Name = "GunDropHighlight"
						hl.OutlineTransparency = _G.ESPOutlineTransparency
						hl.FillTransparency = 0
						hl.FillColor = _G.ESPColorGun
						hl.OutlineColor = _G.ESPOutlineColor
						hl.Parent = gunDrop
					else
						gunDrop.GunDropHighlight.FillColor = _G.ESPColorGun
					end
				else
					if gunDrop:FindFirstChild("GunDropHighlight") then
						gunDrop.GunDropHighlight:Destroy()
					end
				end
			end
		end
	end
	if gunDropFound and not _G.GunDropNotified then
		Rayfield:Notify({Title = "Gun", Content = "Gun Dropped", Duration = 5, Image = "user-check"})
		_G.GunDropNotified = true
	end
	if not gunDropFound then
		_G.GunDropNotified = false
	end
end
RunService.RenderStepped:Connect(function()
	if (_G.ESPAllEnabled or _G.ESPMurdererEnabled or _G.ESPSheriffEnabled or _G.ESPHeroEnabled or _G.ESPGunEnabled) then
		local getData = ReplicatedStorage:FindFirstChild("GetPlayerData", true)
		if getData then
			local s, rd = pcall(function() return getData:InvokeServer() end)
			if s and rd then roles = rd end
		end
		updatePlayerHighlights()
	else
		removePlayerHighlights()
	end
	updateGunDropHighlights()
end)
RunService.RenderStepped:Connect(function()
	if Humanoid then
		Humanoid.WalkSpeed = desiredWalkSpeed
		Humanoid.JumpPower = desiredJumpPower
	end
end)
local function getSafeTargetCFrame(cf)
	if not cf then return end
	local cp = cf.Position
	local rp = Root.Position
	local ty = cp.Y
	if cp.Y > rp.Y then
		ty = rp.Y
	elseif cp.Y < rp.Y then
		local ho = cp + Vector3.new(0,5,0)
		local hd = Vector3.new(0,-10,0)
		local hit, hp = Workspace:FindPartOnRayWithIgnoreList(Ray.new(ho,hd), {Character})
		if hit and hp then ty = hp.Y + 2 end
		if math.abs(ty - rp.Y) > 5 then ty = rp.Y end
	end
	return CFrame.new(Vector3.new(cp.X,ty,cp.Z))
end
local function tweenToCoin(coin)
	if not coin or not coin.CFrame then return end
	local tcf = getSafeTargetCFrame(coin.CFrame)
	if not tcf then return end
	local dist = (Root.Position - tcf.Position).Magnitude
	if dist > 100 then return end
	local sp = math.max(dist/(16*(tonumber(autoFarmSpeed) or 1)),0.5)
	local ti = TweenInfo.new(sp,Enum.EasingStyle.Linear,Enum.EasingDirection.Out)
	local tw = TweenService:Create(Root,ti,{CFrame=tcf})
	local ok = pcall(function() tw:Play() end)
	if ok then
		tw.Completed:Wait()
		Root.Velocity = Vector3.new(0,0,0)
		Humanoid:ChangeState(Enum.HumanoidStateType.Running)
	end
end
local function startAutoFarm()
	coroutine.wrap(function()
		while _G.AutoFarmActive do
			for _, n in ipairs(autoFarmMapNames) do
				local m = Workspace:FindFirstChild(n)
				if m then
					local cc = m:FindFirstChild("CoinContainer")
					if cc then
						local coins = {}
						for _, c in ipairs(cc:GetChildren()) do
							if c:IsDescendantOf(Workspace) and c:FindFirstChild("CoinVisual") then
								local d = (Root.Position - c.Position).Magnitude
								if d <= 100 then table.insert(coins,c) end
							end
						end
						table.sort(coins,function(a,b)
							return (Root.Position - a.Position).Magnitude < (Root.Position - b.Position).Magnitude
						end)
						for _, coin in ipairs(coins) do
							if not _G.AutoFarmActive then break end
							if coin:FindFirstChild("CoinVisual") then
								tweenToCoin(coin.CoinVisual)
								task.wait(0.2)
							end
						end
					end
				end
			end
			task.wait(1)
		end
	end)()
end
local function teleportToDestination(opt)
	if opt == "Lobby" then
		local lb = Workspace:FindFirstChild("Lobby")
		if lb then
			local sp = lb:FindFirstChild("Spawns")
			if sp then
				local s = sp:FindFirstChild("Spawn")
				if s and s:IsA("BasePart") and LocalPlayer.Character then
					LocalPlayer.Character:PivotTo(s.CFrame * CFrame.new(0,5,0))
				end
			end
		end
	else
		for _, mn in ipairs(autoFarmMapNames) do
			local map = Workspace:FindFirstChild(mn)
			if map then
				local sps = map:FindFirstChild("Spawns")
				if sps then
					local spn = sps:FindFirstChild("Spawn")
					if spn and spn:IsA("BasePart") and LocalPlayer.Character then
						LocalPlayer.Character:PivotTo(spn.CFrame * CFrame.new(0,5,0))
						return
					end
				end
			end
		end
	end
end
if not UserInputService.TouchEnabled then
	local mouse = LocalPlayer:GetMouse()
	mouse.Button1Down:Connect(function()
		if _G.ClickTeleportEnabled and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
			local cf = mouse.Hit
			if cf and LocalPlayer.Character then
				LocalPlayer.Character:PivotTo(CFrame.new(cf.p + Vector3.new(0,5,0)))
			end
		end
	end)
end
local selectedLanguage = "pt"
local translations
local function loadTranslations(lang)
	if lang == "pt" then
		translations = require(script.Parent:WaitForChild("translations_pt"))
	else
		translations = require(script.Parent:WaitForChild("translations_en"))
	end
end
loadTranslations(selectedLanguage)
local RayfieldWindow = Rayfield:CreateWindow({
	Name = translations.VisionHubTitle,
	LoadingTitle = translations.LoadingTitle,
	LoadingSubtitle = translations.LoadingSubtitle,
	DisableRayfieldPrompts = false,
	DisableBuildWarnings = false,
	ConfigurationSaving = {Enabled = true, FolderName = "VisionHub", FileName = "VisionHubConfig"},
	Discord = {Enabled = true, Invite = translations.DiscordInvite, RememberJoins = true},
	KeySystem = false
})
local SettingsTab = RayfieldWindow:CreateTab("Settings", "settings")
SettingsTab:CreateDropdown({
	Name = "Language",
	Options = {"Português", "English"},
	CurrentOption = {"Português"},
	Callback = function(selected)
		if selected[1] == "Português" then
			selectedLanguage = "pt"
		else
			selectedLanguage = "en"
		end
		loadTranslations(selectedLanguage)
		RayfieldWindow:SetTitle(translations.VisionHubTitle)
	end
})
local PlayerTab = RayfieldWindow:CreateTab("Player", "user")
PlayerTab:CreateSection("Sheriff")
PlayerTab:CreateButton({
	Name = "Shoot Murderer (Manual)",
	Callback = function()
		local function getTarget()
			local getData = ReplicatedStorage:FindFirstChild("GetPlayerData", true)
			if getData then
				local success, data = pcall(function() return getData:InvokeServer() end)
				if success and data then
					for k, v in pairs(data) do
						if v.Role == "Murderer" then
							return Players:FindFirstChild(k)
						end
					end
					for k, v in pairs(data) do
						if v.Role == "Sheriff" and k ~= LocalPlayer.Name then
							return Players:FindFirstChild(k)
						end
					end
				end
			end
			return nil
		end
		local target = getTarget()
		if not (target and target.Character) then return end
		performShoot(target)
	end
})
PlayerTab:CreateToggle({
	Name = "Shoot Murder (Automatic)",
	Callback = function()
		_G.AutoShooting = not _G.AutoShooting
		if _G.AutoShooting then
			task.spawn(function()
				while _G.AutoShooting do
					task.wait(0.1)
					local function getTarget()
						local getData = ReplicatedStorage:FindFirstChild("GetPlayerData", true)
						if getData then
							local success, data = pcall(function() return getData:InvokeServer() end)
							if success and data then
								for k, v in pairs(data) do
									if v.Role == "Murderer" then
										return Players:FindFirstChild(k)
									end
								end
								for k, v in pairs(data) do
									if v.Role == "Sheriff" and k ~= LocalPlayer.Name then
										return Players:FindFirstChild(k)
									end
								end
							end
						end
						return nil
					end
					local target = getTarget()
					if target and target.Character then
						local targetPart = (function()
							local character = target.Character
							if character then
								local humanoid = character:FindFirstChildOfClass("Humanoid")
								local hrp = character:FindFirstChild("HumanoidRootPart")
								local head = character:FindFirstChild("Head")
								if humanoid then
									local state = humanoid:GetState()
									if state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall or math.abs(hrp.Velocity.Y) > 10 then
										return head or hrp
									end
								end
								local upperTorso = character:FindFirstChild("UpperTorso")
								return upperTorso or hrp
							end
							return nil
						end)()
						if targetPart then
							local characterHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
							if characterHRP then
								local direction = (targetPart.Position - characterHRP.Position).Unit * 50
								local raycastParams = RaycastParams.new()
								raycastParams.FilterType = Enum.RaycastFilterType.Exclude
								raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
								local hit = Workspace:Raycast(characterHRP.Position, direction, raycastParams)
								if not hit or (hit.Instance and hit.Instance:IsDescendantOf(target.Character)) then
									performShoot(target)
								end
							end
						end
					end
				end
			end)
		end
	end
})
PlayerTab:CreateToggle({
	Name = "Auto Collect Gun",
	CurrentValue = _G.AutoWeaponCollectActive,
	Callback = function(v) _G.AutoWeaponCollectActive = v end
})
PlayerTab:CreateSection("Murderer")
PlayerTab:CreateButton({
	Name = "Kill All",
	Callback = function() attackEnemies() end
})
PlayerTab:CreateSection("Useful")
PlayerTab:CreateToggle({
	Name = "Second Life",
	CurrentValue = _G.GodModeActive,
	Callback = function(v) _G.GodModeActive = v end
})
PlayerTab:CreateToggle({
	Name = "AntiFling",
	CurrentValue = false,
	Callback = function(state)
		antiFling = state
		if state then
			flingDetectionCon = RunService.Heartbeat:Connect(function()
				for _, pl in ipairs(Players:GetPlayers()) do
					if pl ~= LocalPlayer and pl.Character and pl.Character:FindFirstChild("HumanoidRootPart") and pl.Character:IsDescendantOf(Workspace) then
						local hrp = pl.Character.HumanoidRootPart
						if hrp.AssemblyAngularVelocity.Magnitude > 50 or hrp.AssemblyLinearVelocity.Magnitude > 100 then
							for _, p in ipairs(pl.Character:GetDescendants()) do
								if p:IsA("BasePart") then
									p.CanCollide = false
									p.Velocity = Vector3.new(0,0,0)
									p.RotVelocity = Vector3.new(0,0,0)
								end
							end
						end
					end
				end
			end)
			flingNeutralizerCon = RunService.Heartbeat:Connect(function()
				if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
					local hrp = LocalPlayer.Character.HumanoidRootPart
					if hrp.AssemblyLinearVelocity.Magnitude > 250 or hrp.AssemblyAngularVelocity.Magnitude > 250 then
						hrp.Velocity = Vector3.new(0,0,0)
						hrp.RotVelocity = Vector3.new(0,0,0)
						if antiFlingLastPos ~= Vector3.zero then
							hrp.CFrame = CFrame.new(antiFlingLastPos)
						end
					else
						antiFlingLastPos = hrp.Position
					end
				end
			end)
		else
			if flingDetectionCon then flingDetectionCon:Disconnect() end
			if flingNeutralizerCon then flingNeutralizerCon:Disconnect() end
			detectedPlayers = {}
		end
	end
})
PlayerTab:CreateSection("Teleport")
PlayerTab:CreateDropdown({
	Name = "Teleport",
	Options = {"Lobby","Map"},
	CurrentOption = {"Lobby"},
	Callback = function(sel) teleportToDestination(sel[1]) end
})
PlayerTab:CreateSection("Character")
PlayerTab:CreateSlider({
	Name = "WalkSpeed",
	Range = {16,200},
	Increment = 1,
	CurrentValue = desiredWalkSpeed,
	Callback = function(v) desiredWalkSpeed = v end
})
PlayerTab:CreateSlider({
	Name = "JumpPower",
	Range = {50,200},
	Increment = 1,
	CurrentValue = desiredJumpPower,
	Callback = function(v) desiredJumpPower = v end
})
PlayerTab:CreateToggle({
	Name = "Ctrl+Click TP",
	CurrentValue = _G.ClickTeleportEnabled,
	Callback = function(v) _G.ClickTeleportEnabled = v end
})
PlayerTab:CreateToggle({
	Name = "Noclip",
	CurrentValue = _G.NoclipActive,
	Callback = function(v) _G.NoclipActive = v end
})
PlayerTab:CreateToggle({
	Name = "Infinite Jump",
	CurrentValue = _G.InfiniteJumpEnabled,
	Callback = function(v) _G.InfiniteJumpEnabled = v end
})
local VisualsTab = RayfieldWindow:CreateTab("Visuals", "eye")
VisualsTab:CreateSection("Visual Settings")
VisualsTab:CreateToggle({
	Name = "X-Ray",
	CurrentValue = _G.XrayEnabled,
	Callback = function(v)
		_G.XrayEnabled = v
		for _, part in ipairs(Workspace:GetDescendants()) do
			if part:IsA("BasePart") and not part.Parent:FindFirstChild("Humanoid") then
				part.LocalTransparencyModifier = v and _G.XrayTransparency or 0
			end
		end
	end
})
VisualsTab:CreateSlider({
	Name = "X-Ray Transparency",
	Range = {0,100},
	Increment = 1,
	CurrentValue = _G.XrayTransparency * 100,
	Callback = function(val)
		_G.XrayTransparency = val/100
		if _G.XrayEnabled then
			for _, part in ipairs(Workspace:GetDescendants()) do
				if part:IsA("BasePart") and not part.Parent:FindFirstChild("Humanoid") then
					part.LocalTransparencyModifier = _G.XrayTransparency
				end
			end
		end
	end
})
VisualsTab:CreateSlider({
	Name = "FOV",
	Range = {10,120},
	Increment = 1,
	CurrentValue = _G.FOVValue,
	Callback = function(val)
		_G.FOVValue = val
		Camera.FieldOfView = val
	end
})
VisualsTab:CreateSection("Player ESP")
VisualsTab:CreateToggle({
	Name = "ESP",
	CurrentValue = _G.ESPAllEnabled,
	Callback = function(v) _G.ESPAllEnabled = v end
})
VisualsTab:CreateToggle({
	Name = "ESP Murderer",
	CurrentValue = _G.ESPMurdererEnabled,
	Callback = function(v) _G.ESPMurdererEnabled = v end
})
VisualsTab:CreateToggle({
	Name = "ESP Sheriff",
	CurrentValue = _G.ESPSheriffEnabled,
	Callback = function(v) _G.ESPSheriffEnabled = v end
})
VisualsTab:CreateToggle({
	Name = "ESP Hero",
	CurrentValue = _G.ESPHeroEnabled,
	Callback = function(v) _G.ESPHeroEnabled = v end
})
VisualsTab:CreateSection("Player ESP Colors")
VisualsTab:CreateColorPicker({
	Name = "Innocent ESP Color",
	Color = _G.ESPColorDefault,
	Callback = function(val) _G.ESPColorDefault = val end
})
VisualsTab:CreateColorPicker({
	Name = "Murderer Color",
	Color = _G.ESPColorMurderer,
	Callback = function(val) _G.ESPColorMurderer = val end
})
VisualsTab:CreateColorPicker({
	Name = "Sheriff Color",
	Color = _G.ESPColorSheriff,
	Callback = function(val) _G.ESPColorSheriff = val end
})
VisualsTab:CreateColorPicker({
	Name = "Hero ESP Color",
	Color = _G.ESPColorHero,
	Callback = function(val) _G.ESPColorHero = val end
})
VisualsTab:CreateSection("Gun ESP")
VisualsTab:CreateToggle({
	Name = "Gun ESP",
	CurrentValue = _G.ESPGunEnabled,
	Callback = function(v) _G.ESPGunEnabled = v end
})
VisualsTab:CreateColorPicker({
	Name = "Gun ESP Color",
	Color = _G.ESPColorGun,
	Callback = function(val) _G.ESPColorGun = val end
})
VisualsTab:CreateSection("ESP Customization")
VisualsTab:CreateSlider({
	Name = "ESP Outline Transparency",
	Range = {0,1},
	Increment = 0.05,
	CurrentValue = _G.ESPOutlineTransparency,
	Callback = function(val) _G.ESPOutlineTransparency = val end
})
VisualsTab:CreateSlider({
	Name = "ESP Fill Transparency",
	Range = {0,1},
	Increment = 0.05,
	CurrentValue = _G.ESPFillTransparency,
	Callback = function(val) _G.ESPFillTransparency = val end
})
VisualsTab:CreateColorPicker({
	Name = "ESP Outline Color",
	Color = _G.ESPOutlineColor,
	Callback = function(val) _G.ESPOutlineColor = val end
})
local AutoFarmTab = RayfieldWindow:CreateTab("Farm", "dollar-sign")
AutoFarmTab:CreateSection("Farming")
AutoFarmTab:CreateToggle({
	Name = "Auto Farm",
	CurrentValue = _G.AutoFarmActive,
	Callback = function(v)
		_G.AutoFarmActive = v
		if v then
			_G.NoclipActive = true
			startAutoFarm()
		else
			_G.NoclipActive = false
		end
	end
})
AutoFarmTab:CreateSlider({
	Name = "Auto Farm Speed",
	Range = {1,10},
	Increment = 1,
	CurrentValue = autoFarmSpeed,
	Callback = function(v) autoFarmSpeed = v end
})
local Label = AutoFarmTab:CreateLabel("If set above 1, you risk being kicked from the game.")
local EmotesTab = RayfieldWindow:CreateTab("Emotes", "smile")
if game.PlaceId == 142823291 then
	local Remotes = ReplicatedStorage:FindFirstChild("Remotes",10)
	if Remotes then
		local Misc = Remotes:FindFirstChild("Misc",10)
		if Misc then
			local PlayEmote = Misc:FindFirstChild("PlayEmote",10)
			if PlayEmote then
				EmotesTab:CreateSection("Emotes")
				EmotesTab:CreateButton({Name = "Sit", Callback = function() PlayEmote:Fire("sit") end})
				EmotesTab:CreateButton({Name = "Ninja", Callback = function() PlayEmote:Fire("ninja") end})
				EmotesTab:CreateButton({Name = "Dab", Callback = function() PlayEmote:Fire("dab") end})
				EmotesTab:CreateButton({Name = "Floss", Callback = function() PlayEmote:Fire("floss") end})
				EmotesTab:CreateButton({Name = "Zen", Callback = function() PlayEmote:Fire("zen") end})
				EmotesTab:CreateButton({Name = "Zombie", Callback = function() PlayEmote:Fire("zombie") end})
				EmotesTab:CreateButton({Name = "Headless", Callback = function() PlayEmote:Fire("headless") end})
				EmotesTab:CreateSection("Default Emotes")
				EmotesTab:CreateButton({Name = "Wave", Callback = function() PlayEmote:Fire("wave") end})
				EmotesTab:CreateButton({Name = "Cheer", Callback = function() PlayEmote:Fire("cheer") end})
				EmotesTab:CreateButton({Name = "Laugh", Callback = function() PlayEmote:Fire("laugh") end})
			else
				EmotesTab:CreateSection("Emotes")
				EmotesTab:CreateButton({Name = "No Emotes Found", Callback = function() end})
			end
		end
	end
else
	EmotesTab:CreateSection("Emotes")
	EmotesTab:CreateButton({Name = "Not Available", Callback = function() end})
end
Rayfield:Notify({Title = "Discord", Content = "discord.gg/Ygcq9dpW9t", Duration = 8, Image = "user-check"})

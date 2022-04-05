local RunService = game:GetService("RunService")
if RunService:IsRunning() then
	return
end

local cutsceneSelected:Folder|Model, parts, pathFolder, easingFunctions, module
local visualizeEnabled = false
local connections = {}
local Selection = game:GetService("Selection")
local theme = settings().Studio.Theme

local toolbar = plugin:CreateToolbar("CutsceneService")
local menuButton = toolbar:CreateButton("Toggle Menu",
	"Open or close the menu",
	"http://www.roblox.com/asset/?id=9242733957")
menuButton.ClickableWhenViewportHidden = true

local menu = plugin:CreateDockWidgetPluginGui("CutsceneService",
	DockWidgetPluginGuiInfo.new(
		Enum.InitialDockState.Float,
		false, false,
		350, 450,
		300, 300
	))
menu.Title = "CutsceneService Helper"

local background = Instance.new("Frame")
background.Name = "Background"
background.BorderSizePixel = 0
background.BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainBackground)
background.Size = UDim2.fromScale(1, 1)
background.Parent = menu

local frame = Instance.new("Frame")
frame.Name = "Frame"
frame.BackgroundTransparency = 1
frame.BorderSizePixel = 0
frame.Position = UDim2.fromOffset(10, 90)
frame.Size = UDim2.fromScale(0.95, 0.8)
frame.Parent = background

local buttonTemplate = Instance.new("TextButton")
buttonTemplate.Text = ""
buttonTemplate.BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Button)
buttonTemplate.BorderSizePixel = 0

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0.2, 0)
uiCorner.Parent = buttonTemplate

local imageLabel = Instance.new("ImageLabel")
imageLabel.Name = "ButtonImage"
imageLabel.AnchorPoint = Vector2.new(0.5, 0)
imageLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
imageLabel.BackgroundTransparency = 1
imageLabel.BorderSizePixel = 0
imageLabel.Position = UDim2.fromScale(0.5, 0.07)
imageLabel.Size = UDim2.fromScale(0.6, 0.6)
imageLabel.Parent = buttonTemplate

Instance.new("UIAspectRatioConstraint").Parent = imageLabel

local caption = Instance.new("TextLabel")
caption.Name = "Caption"
caption.Font = Enum.Font.GothamBold
caption.TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText)
caption.TextScaled = true
caption.TextWrapped = true
caption.AnchorPoint = Vector2.new(0.5, 1)
caption.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
caption.BackgroundTransparency = 1
caption.Position = UDim2.fromScale(0.5, 0.95)
caption.Size = UDim2.fromScale(0.9, 0.2)
caption.Parent = buttonTemplate

local uiGridLayout = Instance.new("UIGridLayout")
uiGridLayout.CellPadding = UDim2.fromOffset(10, 10)
uiGridLayout.CellSize = UDim2.fromOffset(70, 80)
uiGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
uiGridLayout.Parent = frame

Instance.new("UIAspectRatioConstraint").Parent = uiGridLayout

local changeButton = Instance.new("TextButton")
changeButton.Name = "ChangeButton"
changeButton.Text = ""
changeButton.AnchorPoint = Vector2.new(1, 0)
changeButton.BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Button)
changeButton.BorderSizePixel = 0
changeButton.Position = UDim2.new(0.95, 0, 0, 10)
changeButton.Size = UDim2.fromOffset(75, 20)
changeButton.Parent = background

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0.25, 0)
uiCorner.Parent = changeButton

local buttonText = Instance.new("TextLabel")
buttonText.Name = "ButtonText"
buttonText.Font = Enum.Font.GothamBold
buttonText.Text = "Change"
buttonText.TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText)
buttonText.TextScaled = true
buttonText.TextWrapped = true
buttonText.BackgroundTransparency = 1
buttonText.BorderSizePixel = 0
buttonText.Position = UDim2.fromScale(0.15, 0.15)
buttonText.Size = UDim2.fromScale(0.7, 0.7)
buttonText.Parent = changeButton

local selection = Instance.new("TextLabel")
selection.Name = "Selection"
selection.Font = Enum.Font.GothamBold
selection.Text = "Selected: None"
selection.TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText)
selection.TextScaled = true
selection.TextWrapped = true
selection.BackgroundTransparency = 1
selection.BorderSizePixel = 0
selection.Position = UDim2.fromOffset(10, 10)
selection.Size = UDim2.fromOffset(150, 20)
selection.Parent = background

local duration = Instance.new("TextLabel")
duration.Name = "Duration"
duration.Font = Enum.Font.GothamBold
duration.Text = "Duration"
duration.TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText)
duration.TextSize = 15
duration.TextWrapped = true
duration.BackgroundTransparency = 1
duration.BorderSizePixel = 0
duration.Position = UDim2.fromOffset(10, 35)
duration.Size = UDim2.fromOffset(150, 20)
duration.Parent = background

local durationBox = Instance.new("TextBox")
durationBox.Name = "DurationBox"
durationBox.Font = Enum.Font.GothamBold
durationBox.Text = "5"
durationBox.PlaceholderText = "5"
durationBox.TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText)
durationBox.TextSize = 15
durationBox.TextWrapped = true
durationBox.AnchorPoint = Vector2.new(1, 0)
durationBox.BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Button)
durationBox.Position = UDim2.new(0.95, 0, 0, 35)
durationBox.Size = UDim2.fromOffset(75, 20)
durationBox.Parent = background

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0.25, 0)
uiCorner.Parent = durationBox

local easing = Instance.new("TextLabel")
easing.Name = "Easing"
easing.Font = Enum.Font.GothamBold
easing.Text = "Easing"
easing.TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText)
easing.TextSize = 15
easing.TextWrapped = true
easing.BackgroundTransparency = 1
easing.BorderSizePixel = 0
easing.Position = UDim2.fromOffset(10, 60)
easing.Size = UDim2.fromOffset(150, 20)
easing.Parent = background

local easingBox = Instance.new("TextBox")
easingBox.Name = "EasingBox"
easingBox.Font = Enum.Font.GothamBold
easingBox.PlaceholderText = "Linear"
easingBox.Text = "Linear"
easingBox.TextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText)
easingBox.TextSize = 15
easingBox.TextWrapped = true
easingBox.AnchorPoint = Vector2.new(1, 0)
easingBox.BackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Button)
easingBox.Position = UDim2.new(0.95, 0, 0, 60)
easingBox.Size = UDim2.fromOffset(75, 20)
easingBox.Parent = background

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0.25, 0)
uiCorner.Parent = easingBox

local createPoint = buttonTemplate:Clone()
createPoint.Name = "CreatePoint"
createPoint.ButtonImage.Image = "rbxassetid://9282436906"
createPoint.Caption.Text = "Point"
createPoint.Parent = frame

local visualizeCutscene = buttonTemplate:Clone()
visualizeCutscene.Name = "VisualizeCutscene"
visualizeCutscene.ButtonImage.Image = "http://www.roblox.com/asset/?id=9287673539"
visualizeCutscene.Caption.Text = "Visualize"
visualizeCutscene.Parent = frame

local previewCutscene = buttonTemplate:Clone()
previewCutscene.Name = "PreviewCutscene"
previewCutscene.ButtonImage.Image = "rbxassetid://9282438403"
previewCutscene.Caption.Text = "Preview"
previewCutscene.Parent = frame

local generateCode = buttonTemplate:Clone()
generateCode.Name = "GenerateCode"
generateCode.ButtonImage.Image = "http://www.roblox.com/asset/?id=9282439605"
generateCode.Caption.Text = "Code"
generateCode.Parent = frame

local function getCF(points, t)
	local copy = {unpack(points)}
	repeat
		for i, v in ipairs(copy) do
			if i ~= 1 then copy[i-1] = copy[i-1]:Lerp(v, t) end
		end
		if #copy ~= 1 then
			copy[#copy] = nil
		end
	until #copy == 1
	return copy[1]
end

local function update()
	local instances = cutsceneSelected:GetChildren()
	if #instances > 0 then
		local points = {}
		for _, v in ipairs(instances) do
			if not tonumber(v.Name) then
				warn("A point in the cutscene has an invalid name")
				return
			end
		end
		table.sort(instances, function(a, b)
			return tonumber(a.Name) < tonumber(b.Name)
		end)
		for _, v in ipairs(instances) do
			table.insert(points, v.CFrame)
		end
		for i, v in ipairs(parts) do
			v.CFrame = getCF(points, i*0.01)
		end
	end
end

local function createConnections()
	for _, v in ipairs(connections) do
		v:Disconnect()
	end
	connections = {}
	table.insert(connections, cutsceneSelected.ChildAdded:Connect(function(child)
		task.wait()
		table.insert(connections, child.Changed:Connect(function()
			update()
		end))
		update()
	end))
	table.insert(connections, cutsceneSelected.ChildRemoved:Connect(function()
		update()
	end))
	--[[table.insert(connections, folder.Destroying:Connect(function()
	for _, v in ipairs(parts) do
		v.Position = Vector3.zero
	end]]
	for _, v in ipairs(cutsceneSelected:GetChildren()) do
		table.insert(connections, v.Changed:Connect(function()
			update()
		end))
	end
	update()
end

changeButton.MouseButton1Click:Connect(function()
	local folder = Selection:Get()
	if #folder == 1 and (folder[1].ClassName == "Folder"
		or folder[1].ClassName == "Model") then
		folder = folder[1]
		cutsceneSelected = folder
		selection.Text = "Selected: "..folder.Name
		if visualizeEnabled then
			createConnections()
		end
	end
end)

createPoint.MouseButton1Click:Connect(function()
	if cutsceneSelected then
		local highestNumber = 0
		for _, v in ipairs(cutsceneSelected:GetChildren()) do
			local num = tonumber(v.Name)
			if num then
				if num > highestNumber then
					highestNumber = num
				end
			else
				warn("The points in your cutscene are not correctly named!")
				return
			end
		end
		local point = Instance.new("Part")
		point.Name = tostring(highestNumber+1)
		point.Anchored = true
		point.CanCollide = false
		point.BottomSurface = Enum.SurfaceType.Smooth
		point.TopSurface = Enum.SurfaceType.Smooth
		point.CastShadow = false
		point.CFrame = workspace.CurrentCamera.CFrame
		point.Parent = cutsceneSelected
	end
end)

visualizeCutscene.MouseButton1Click:Connect(function()
	if not cutsceneSelected then return end
	visualizeEnabled = not visualizeEnabled
	if visualizeEnabled then
		pathFolder = Instance.new("Folder")
		pathFolder.Name = "VisualizedPath"
		pathFolder.Archivable = false
		pathFolder.Parent = workspace

		local part = Instance.new("Part")
		part.Name = "PathPoint"
		part.Shape = Enum.PartType.Ball
		part.Size = Vector3.new(0.8, 0.8, 0.8)
		part.Color = Color3.fromRGB(255, 255, 255)
		part.Material = Enum.Material.Plastic
		part.Locked = true
		part.Anchored = true
		part.CanCollide = false
		part.BottomSurface = Enum.SurfaceType.Smooth
		part.TopSurface = Enum.SurfaceType.Smooth
		part.CastShadow = false
		part.CanTouch = false

		for _ = 1, 100 do
			part:Clone().Parent = pathFolder
		end
		parts = pathFolder:GetChildren()
		createConnections()
	else
		for _, v in ipairs(connections) do
			v:Disconnect()
		end
		connections = {}
		pathFolder:Destroy()
	end
end)

previewCutscene.MouseButton1Click:Connect(function()
	if not cutsceneSelected then return end
	if not easingFunctions then
		for _, v in ipairs(game:GetDescendants()) do
			if v.Name == "EasingFunctions" and v.ClassName == "ModuleScript" then
				easingFunctions = require(v) break
			end
		end
		if not easingFunctions then
			warn("CutsceneService module was not found in game") return
		end
	end
	local duration = tonumber(durationBox.Text) or 5
	local easingFunction = easingBox.Text
	if easingFunction == "" then
		easingFunction = "Linear"
	end
	easingFunction = easingFunctions[easingFunction]
	if not easingFunction then
		warn("EasingFunction not found") return
	end
	local instances = cutsceneSelected:GetChildren()
	local points = {}
	table.sort(instances, function(a, b)
		return tonumber(a.Name) < tonumber(b.Name)
	end)
	for _, v in ipairs(instances) do
		table.insert(points, v.CFrame)
	end

	workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
	local start = os.clock()
	RunService:BindToRenderStep("Cutscene", Enum.RenderPriority.Camera.Value+1, function()
		local passedTime = os.clock() - start
		if passedTime <= duration then
			workspace.CurrentCamera.CFrame = getCF(points, easingFunction(passedTime, 0, 1, duration))
		else
			RunService:UnbindFromRenderStep("Cutscene")
			workspace.CurrentCamera.CameraType = Enum.CameraType.Fixed
		end
	end)
end)

generateCode.MouseButton1Click:Connect(function()
	if not cutsceneSelected then return end
	if not module then
		for _, v in ipairs(game:GetDescendants()) do
			if v.Name == "CutsceneService" and v.ClassName == "ModuleScript" then
				module = v break
			end
		end
		if not module then
			warn("CutsceneService module was not found in game") return
		end
	end
	local duration = tonumber(durationBox.Text) or 5
	local easingFunction = easingBox.Text

	local source = "local CutsceneService = require("
	source ..= "game."..module:GetFullName()..")\n\n"
	source ..= "local "..cutsceneSelected.Name.." = CutsceneService:Create(\n"
	if cutsceneSelected:IsDescendantOf(workspace) then
		source ..= "	"..string.gsub(cutsceneSelected:GetFullName(), "^.", string.lower)..",\n"
	else
		source ..= "	game."..cutsceneSelected:GetFullName()..",\n"
	end
	if easingFunction == "" or easingFunction == "Linear" then
		source ..= "	"..duration.."\n)"
	else
		source ..= "	"..duration..",\n"
		source ..= "	\""..easingFunction.."\"\n)"
	end
	source ..= "\n\n--task.wait(4)\n--"..cutsceneSelected.Name..":Play()\n"
	
	local localScript = Instance.new("LocalScript")
	localScript.Name = cutsceneSelected.Name
	localScript.Source = source
	localScript.Parent = game.StarterGui
	plugin:OpenScript(localScript, 11)
end)

menuButton.Click:Connect(function()
	menu.Enabled = not menu.Enabled
end)

--[[

Tutorial & Documentation: devforum.roblox.com/t/718571

Version of this module: 1.3.0

Created by Vaschex

CutsceneService © 2020 by Vaschex is licensed under CC BY-NC 4.0. 
https://creativecommons.org/licenses/by-nc/4.0/

]]

local module = {}
module.Settings = {
	WarnErrors = true,
	YieldPauseArgument = false,
	FireCompletedInQueue = false
}

-------------------------------------------------

local plr = game.Players.LocalPlayer
local playing:any = false

local function characterAdded(char)
	char:WaitForChild("Humanoid").Died:Connect(function()
		if playing then
			playing:Cancel()
		end
	end)
end
if plr.Character then --if characteradded was fired before connecting
	characterAdded(plr.Character)
end
plr.CharacterAdded:Connect(characterAdded)

local char = plr.Character or plr.CharacterAdded:Wait()
local zoomController = require(plr:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule").CameraModule.ZoomController)
local controls = require(plr.PlayerScripts.PlayerModule):GetControls()
local easingFunctions = require(script.EasingFunctions)
local rootPart = char:WaitForChild("HumanoidRootPart")
local runService = game:GetService("RunService")
local StarterGui = game.StarterGui
local camera = workspace.CurrentCamera
local clock = os.clock

--[[
For the Signal variable:
MIT License
Copyright (c) 2014 Quenty
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
OR OTHER DEALINGS IN THE SOFTWARE.
]]
local Signal = {}
Signal.__index = Signal
Signal.ClassName = "RBXScriptSignal"

function Signal.new()
	return setmetatable({bindable = Instance.new("BindableEvent")}, Signal)
end

function Signal:Fire(...)
	self.argData = {...}
	self.argCount = select("#", ...)
	self.bindable:Fire()
	self.argData = nil
	self.argCount = nil
end

function Signal:Connect(handler)
	if not type(handler) == "function" then
		error(("connect(%s)"):format(typeof(handler)), 2)
	end
	return self.bindable.Event:Connect(function()
		handler(unpack(self.argData, 1, self.argCount))
	end)
end

function Signal:Wait()
	self.bindable.Event:Wait()
	assert(self.argData, "Missing arg data, likely due to :TweenSize/Position corrupting threadrefs.")
	return unpack(self.argData, 1, self.argCount)
end

function Signal:Destroy()
	if self.bindable then
		self.bindable:Destroy()
		self.bindable = nil
	end
	self.argData = nil
	self.argCount = nil
end

local function customError(msg)
	if module.Settings.WarnErrors then warn(msg) else error(msg) end
end

local function getPoints(folder) --returns point cframes in order
	folder = folder:GetChildren()
	local points = {}

	table.sort(folder, function(a,b)
		return tonumber(a.Name) < tonumber(b.Name)
	end)

	for _,v in pairs(folder) do
		table.insert(points, v.CFrame)
	end
	return points
end

--credits to DejaVu_Loop for this function
type CFrameArray = {[number]:CFrame}
local function getCF(points:CFrameArray, ratio:number):CFrame
	repeat
		local ntb:CFrameArray = {}
		for i, v in ipairs(points) do
			if i ~= 1 then ntb[i-1] = points[i-1]:Lerp(v, ratio) end
		end
		points = ntb
	until #points == 1
	return points[1]
end

local function getCoreGuisEnabled()
	return {
		Backpack = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Backpack),
		Chat = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Chat),
		EmotesMenu = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu),
		Health = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Health),
		PlayerList = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.PlayerList)
	}
end

module.Functions = {
	DisableControls = "DisableControls",
	StartFromCurrentCamera = "StartFromCurrentCamera",
	EndWithCurrentCamera = "EndWithCurrentCamera",
	EndWithDefaultCamera = "EndWithDefaultCamera",
	YieldAfterCutscene = "YieldAfterCutscene",
	FreezeCharacter = "FreezeCharacter",
	CustomCamera = "CustomCamera",
}

type cutscene = {
	Play:(cutscene)-> boolean?,
	Pause:(cutscene,number?)-> boolean?,
	Resume:(cutscene)-> boolean?,
	Cancel:(cutscene)-> boolean?,
	Completed: RBXScriptSignal,
	PlaybackState: Enum.PlaybackState,
	Progress: number,
	Next: cutscene?
}

type queue = {
	CurrentCutscene: cutscene?,
	Play:(queue)-> nil,
	Pause:(queue,number?)-> nil,
	Resume:(queue)-> nil,
	Cancel:(queue)-> nil,
	Completed: RBXScriptSignal,
	PlaybackState: Enum.PlaybackState
}

function module:Create(points:Instance|CFrameArray, duration:number, ...):cutscene
	assert(points, "Argument 1 (points) missing or nil")
	assert(duration, "Argument 2 (duration) missing or nil")
	local cutscene = {}
	cutscene.Completed = Signal.new()
	cutscene.PlaybackState = Enum.PlaybackState.Begin
	cutscene.Progress = 0

	local args = {...}
	local pausedPassedTime = 0 --stores progress of cutscene when paused
	local passedTime, start, previousCameraType, customCameraEnabled:any, previousCoreGuis, pointsCopy

	if typeof(points) == "Instance" then
		assert(typeof(points) ~= "table", "Argument 1 (points) not an instance or table")
		points = getPoints(points)
	end

	local specialFunctionsTable = {
		Start = { --this is an array so you can iterate in order (ik it looks bad)
			{"CustomCamera", function(customCamera)
				assert(customCamera, "CustomCamera Argument 1 missing or nil")
				camera = customCamera
				customCameraEnabled = customCamera
			end},
			{"DisableControls", function()
				controls:Disable()
			end},
			{"FreezeCharacter", function(stopAnimations)
				if stopAnimations ~= false then
					for _, v in pairs(char.Humanoid.Animator:GetPlayingAnimationTracks()) do
						v:Stop()
					end
				end
				rootPart.Anchored = true
			end},
			{"StartFromCurrentCamera", function()
				table.insert(pointsCopy, 1, camera.CFrame)
			end},
			{"EndWithCurrentCamera", function()				
				table.insert(pointsCopy, camera.CFrame)
			end},
			{"EndWithDefaultCamera", function(useCurrentZoomDistance)
				local zoomDistance = 12.5
				if useCurrentZoomDistance == false then
					--pls help me: devforum.roblox.com/t/1209043
					--set camera zoomDistance to default for smooth transition when changing type to custom

					--zoomController.SetZoomParameters(zoomDistance, 0) isn't good

					local oldMin = plr.CameraMinZoomDistance
					local oldMax = plr.CameraMaxZoomDistance
					plr.CameraMinZoomDistance = zoomDistance
					plr.CameraMaxZoomDistance = zoomDistance
					task.wait()
					plr.CameraMinZoomDistance = oldMin
					plr.CameraMaxZoomDistance = oldMax
				else
					zoomDistance = zoomController.GetZoomRadius()
					--zoomDistance = (camera.CFrame.Position - camera.Focus.Position).Magnitude
					--this is only the zoomDistance when there are no parts in the cameras way
				end
				local cameraOffset = CFrame.new(0, zoomDistance/2.6397830596715992, zoomDistance/1.0352760971197642)
				--Vector3.new(0, 4.7352376, 12.0740738)
				local lookAt = rootPart.CFrame.Position + Vector3.new(0, rootPart.Size.Y/2 + 0.5, 0)
				local at = (rootPart.CFrame * cameraOffset).Position

				table.insert(pointsCopy, CFrame.lookAt(at, lookAt))
			end}
		},
		End = {
			{"YieldAfterCutscene", function(waitTime)
				assert(waitTime, "YieldAfterCutscene Argument 1 missing or nil")
				task.wait(waitTime)
			end},
			{"DisableControls", function()
				controls:Enable(true)
			end},
			{"FreezeCharacter", function()
				rootPart.Anchored = false
			end},
			{"CustomCamera", function()
				camera.CameraType = previousCameraType
				camera = workspace.CurrentCamera
			end}
		}
	}

	local easingFunction = easingFunctions.Linear
	local dir, style = "In", nil
	for _, v in pairs(args) do
		if easingFunctions[v] then
			easingFunction = easingFunctions[v]
		elseif typeof(v) == "EnumItem" then
			if v.EnumType == Enum.EasingDirection then
				dir = v.Name
			elseif v.EnumType == Enum.EasingStyle then
				style = v.Name
			end
		end	
	end
	if style then
		assert(easingFunctions[dir..style], "EasingFunction "..dir..style.." not found")
		easingFunction = easingFunctions[dir..style]
	end

	local function checkNext(a, idx) --check if next argument is argument for special function
		local Next = args[idx+1]
		if (Next or Next == false) and typeof(Next) ~= "string" and typeof(Next) ~= "EnumItem" then
			table.insert(a, Next)
			checkNext(a, idx+1)
		end
	end

	local function callSpecialFunctions(Type)
		for i, v in ipairs(specialFunctionsTable[Type]) do
			local idx = table.find(args, v[1])
			if idx then
				local args = {} --arguments for special function
				checkNext(args, idx)
				if #args == 0 then
					v[2]()
				else
					v[2](unpack(args))
				end
			end
		end
	end

	function cutscene:Play():boolean?
		if playing == false or playing.CurrentCutscene == cutscene then
			playing = playing or cutscene
			customCameraEnabled = false
			pointsCopy = {unpack(points)}

			if not cutscene.Next then
				previousCoreGuis = getCoreGuisEnabled()
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
			end

			callSpecialFunctions("Start")

			previousCameraType = camera.CameraType
			camera.CameraType = Enum.CameraType.Scriptable

			assert(#pointsCopy > 1, "More than one point is required")
			pausedPassedTime = 0
			cutscene.PlaybackState = Enum.PlaybackState.Playing
			start = clock()

			runService:BindToRenderStep("Cutscene", 201, function()
				passedTime = clock() - start

				if passedTime <= duration then
					camera.CFrame = getCF(pointsCopy, easingFunction(passedTime, 0, 1, duration))

					cutscene.Progress = passedTime / duration
				else
					runService:UnbindFromRenderStep("Cutscene")
					cutscene.Progress = 1

					callSpecialFunctions("End")

					cutscene.PlaybackState = Enum.PlaybackState.Completed

					if cutscene.Next then
						if cutscene.Next == "Last" then
							cutscene.Completed:Fire(Enum.PlaybackState.Completed)
						else
							playing.CurrentCutscene = cutscene.Next
							if module.Settings.FireCompletedInQueue then
								cutscene.Completed:Fire(Enum.PlaybackState.Completed)
							end
							cutscene.Next:Play()
						end
					else
						playing = false
						if not customCameraEnabled then
							camera.CameraType = previousCameraType
						end

						for k, v in pairs(previousCoreGuis) do --reactive previous enabled coreguis
							if v then
								StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType[k], true)
							end
						end
						cutscene.Completed:Fire(Enum.PlaybackState.Completed)
					end
				end
			end)

		else		
			customError("Error while calling Play - A cutscene was already playing") return false
		end
	end

	function cutscene:Pause(waitTime:number?):boolean?
		if playing then
			if passedTime == nil then
				customError("Error while calling Pause - Cutscene hasn't started yet") return false
			end
			runService:UnbindFromRenderStep("Cutscene")
			local playingQueue
			if playing.CurrentCutscene then
				playingQueue = playing
			end
			playing = false
			pausedPassedTime = passedTime
			cutscene.PlaybackState = Enum.PlaybackState.Paused
			if customCameraEnabled then
				camera = workspace.CurrentCamera
			end

			if waitTime then
				if module.Settings.YieldPauseArgument then
					task.wait(waitTime)
					if playingQueue then
						playing = playingQueue
					end
					cutscene:Resume()
				else
					task.spawn(function()
						task.wait(waitTime)
						if playingQueue then
							playing = playingQueue
						end
						cutscene:Resume()
					end)
				end
			end
		else
			customError("Error while calling Pause - There was no cutscene playing") return false
		end
	end

	function cutscene:Resume():boolean?
		if playing == false or playing.CurrentCutscene == cutscene then
			if pausedPassedTime ~= 0 then
				playing = playing or cutscene
				cutscene.PlaybackState = Enum.PlaybackState.Playing
				if customCameraEnabled then
					camera = customCameraEnabled
				end
				camera.CameraType = Enum.CameraType.Scriptable
				start = clock() - pausedPassedTime

				runService:BindToRenderStep("Cutscene", 201, function()
					passedTime = clock() - start

					if passedTime <= duration then
						camera.CFrame = getCF(pointsCopy, easingFunction(passedTime, 0, 1, duration))

						cutscene.Progress = passedTime / duration
					else
						runService:UnbindFromRenderStep("Cutscene")
						cutscene.Progress = 1

						callSpecialFunctions("End")

						cutscene.PlaybackState = Enum.PlaybackState.Completed

						if cutscene.Next then
							if cutscene.Next == "Last" then
								cutscene.Completed:Fire(Enum.PlaybackState.Completed)
							else
								playing.CurrentCutscene = cutscene.Next
								if module.Settings.FireCompletedInQueue then
									cutscene.Completed:Fire(Enum.PlaybackState.Completed)
								end
								cutscene.Next:Play()
							end
						else
							playing = false
							if not customCameraEnabled then
								camera.CameraType = previousCameraType
							end

							for k, v in pairs(previousCoreGuis) do
								if v then
									StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType[k], true)
								end
							end
							cutscene.Completed:Fire(Enum.PlaybackState.Completed)
						end
					end
				end)

			else
				customError("Error while calling Resume - The cutscene isn't paused, use Play if you want to start it")
				return false
			end
		else
			customError("Error while calling Resume - The cutscene was already playing") return false
		end
	end

	function cutscene:Cancel():boolean?
		if playing then
			runService:UnbindFromRenderStep("Cutscene")
			playing = false

			for i, v in ipairs(specialFunctionsTable.End) do
				local idx = table.find(args, v[1])
				if idx and v[1] ~= "YieldAfterCutscene" then
					--no args yet for end functions	
					v[2]()
				end
			end

			if not cutscene.Next then
				if not customCameraEnabled then
					camera.CameraType = previousCameraType
				end
				for k, v in pairs(previousCoreGuis) do
					if v then
						StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType[k], true)
					end
				end
			end
			cutscene.PlaybackState = Enum.PlaybackState.Cancelled
			cutscene.Completed:Fire(Enum.PlaybackState.Cancelled)
		else
			customError("Error while calling Cancel - There was no cutscene playing") return false
		end
	end

	return cutscene
end

function module:CreateQueue(...):queue
	local cutscenes = {...}
	local queue = {}
	queue.Completed = Signal.new()
	queue.PlaybackState = Enum.PlaybackState.Begin
	local previousCameraType, previousCoreGuis

	function queue:Play():nil
		if playing == false then
			playing = queue

			for i, v in ipairs(cutscenes) do
				if cutscenes[i+1] then
					v.Next = cutscenes[i+1]
				else
					v.Next = "Last"
					v.Completed:Connect(function(state)
						playing = false
						queue.PlaybackState = Enum.PlaybackState.Completed
						camera.CameraType = previousCameraType
						queue.CurrentCutscene = nil
						for k, v in pairs(previousCoreGuis) do
							if v then
								StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType[k], true)
							end
						end
						for _, v in pairs(cutscenes) do
							v.Next = nil
						end
						queue.Completed:Fire(state)
					end)
				end
			end

			previousCoreGuis = getCoreGuisEnabled()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
			previousCameraType = camera.CameraType		
			queue.PlaybackState = Enum.PlaybackState.Playing

			playing = queue
			queue.CurrentCutscene = cutscenes[1]
			cutscenes[1]:Play()
		end
	end

	function queue:Pause(waitTime:number?):nil
		if queue.CurrentCutscene:Pause(waitTime) ~= false then
			for _, v in pairs(cutscenes) do
				v.Next = nil
			end
		end
	end

	function queue:Resume():nil
		if playing == false then
			playing = queue
			for i, v in ipairs(cutscenes) do
				if cutscenes[i+1] then
					v.Next = cutscenes[i+1]
				else					
					v.Next = "Last"
				end
			end
			queue.CurrentCutscene:Resume()
		else
			if playing.CurrentCutscene then
				customError("Error while calling Resume - A queue was already playing")
			else
				customError("Error while calling Resume - A cutscene was already playing")
			end
		end
	end

	function queue:Cancel():nil
		queue.CurrentCutscene:Cancel()
		camera.CameraType = previousCameraType
		queue.CurrentCutscene = nil
		for k, v in pairs(previousCoreGuis) do
			if v then
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType[k], true)
			end
		end
		for _, v in pairs(cutscenes) do
			v.Next = nil
		end
		queue.PlaybackState = Enum.PlaybackState.Cancelled
		queue.Completed:Fire(Enum.PlaybackState.Cancelled)
	end

	return queue
end

--[[function module.debug()
	
end]]

return module

--[[

Tutorial & Documentation: devforum.roblox.com/t/718571

Version of this module: 1.4.3

Created by Vaschex

CutsceneService © 2020 by Vaschex is licensed under CC BY-NC 4.0. 
https://creativecommons.org/licenses/by-nc/4.0/

]]

local module = {}
module.Settings = {
	YieldPauseArgument = false
}

-------------------------------------------------

local plr = game.Players.LocalPlayer
local char

do
	local function characterAdded(character)
		character:WaitForChild("Humanoid").Died:Connect(function()
			if module.Playing then
				module.Playing:Cancel()
			end
		end)
		char = character
	end
	if plr.Character then --if CharacterAdded was fired before connecting
		characterAdded(plr.Character)
	end
	plr.CharacterAdded:Connect(characterAdded)
end
char = plr.Character or plr.CharacterAdded:Wait()

local RunService = game:GetService("RunService")
local StarterGui = game.StarterGui
local controls = require(plr.PlayerScripts.PlayerModule):GetControls()
local easingFunctions = require(script.EasingFunctions)
local rootPart = char:WaitForChild("HumanoidRootPart")
local camera = workspace.CurrentCamera
local clock = os.clock

--[[
GoodSignal by stravant
devforum.roblox.com/t/1387063
   
MIT License

Copyright (c) 2021 stravant

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

Authors:
stravant - July 31st, 2021 - Created the file.   
]]

local Signal = {}
Signal.__index = Signal

do
	local freeRunnerThread
	local function acquireRunnerThreadAndCallEventHandler(fn, ...)
		local acquiredRunnerThread = freeRunnerThread
		freeRunnerThread = nil
		fn(...)
		freeRunnerThread = acquiredRunnerThread
	end

	local function runEventHandlerInFreeThread(...)
		acquireRunnerThreadAndCallEventHandler(...)
		while true do
			acquireRunnerThreadAndCallEventHandler(coroutine.yield())
		end
	end

	local Connection = {}
	Connection.__index = Connection

	function Connection.new(signal, fn):RBXScriptConnection
		return setmetatable({
			Connected = true,
			_signal = signal,
			_fn = fn,
			_next = false
		}, Connection)
	end

	function Connection:Disconnect()
		assert(self.Connected, "Can't disconnect a connection twice")
		self.Connected = false
		if self._signal._handlerListHead == self then
			self._signal._handlerListHead = self._next
		else
			local prev = self._signal._handlerListHead
			while prev and prev._next ~= self do
				prev = prev._next
			end
			if prev then
				prev._next = self._next
			end
		end
	end

	function Signal.new():RBXScriptSignal
		return setmetatable({_handlerListHead = false}, Signal)
	end

	function Signal:Connect(fn)
		local connection = Connection.new(self, fn)
		if self._handlerListHead then
			connection._next = self._handlerListHead
			self._handlerListHead = connection
		else
			self._handlerListHead = connection
		end
		return connection
	end

	function Signal:DisconnectAll()
		self._handlerListHead = false
	end

	function Signal:Fire(...)
		local item = self._handlerListHead
		while item do
			if item.Connected then
				if not freeRunnerThread then
					freeRunnerThread = coroutine.create(runEventHandlerInFreeThread)
				end
				task.spawn(freeRunnerThread, item._fn, ...)
			end
			item = item._next
		end
	end

	function Signal:Wait()
		local waitingCoroutine = coroutine.running()
		local cn;
		cn = self:Connect(function(...)
			cn:Disconnect()
			task.spawn(waitingCoroutine, ...)
		end)
		return coroutine.yield()
	end
end

--de Casteljau's algorithm
local function getCF(points:{[number]:CFrame}, t:number):CFrame
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

local function getCoreGuisEnabled()
	return {
		Backpack = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Backpack),
		Chat = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Chat),
		EmotesMenu = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu),
		Health = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Health),
		PlayerList = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.PlayerList)
	}
end

module.Enum = {
	DisableControls = "DisableControls",
	CurrentCameraPoint = "CurrentCameraPoint",
	DefaultCameraPoint = "DefaultCameraPoint",
	FreezeCharacter = "FreezeCharacter",
	CustomCamera = "CustomCamera",
}

local specialFunctions = {
	Start = {
		{"CustomCamera", function(self, customCamera)
			assert(customCamera, "CustomCamera Argument 1 missing or nil")
			camera = customCamera
			self.CustomCamera = customCamera
		end},
		{"DisableControls", function()
			controls:Disable()
		end},
		{"FreezeCharacter", function(_, stopAnimations)
			if stopAnimations ~= false then
				for _, v in ipairs(char.Humanoid.Animator:GetPlayingAnimationTracks()) do
					v:Stop()
				end
			end
			rootPart.Anchored = true
		end},
		{"CurrentCameraPoint", function(self, position)
			table.insert(self.PointsCopy, position or #self.PointsCopy+1, camera.CFrame)
		end},
		{"DefaultCameraPoint", function(self, position, useCurrentZoomDistance)
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
				zoomDistance = (camera.CFrame.Position - camera.Focus.Position).Magnitude
				--this is only the zoomDistance when there are no parts in the cameras way
			end
			local lookAt = rootPart.CFrame.Position + Vector3.new(0, rootPart.Size.Y/2 + 0.5, 0)
			local at = (rootPart.CFrame * CFrame.new(0, zoomDistance/2.6397830596715992, zoomDistance/1.0352760971197642)).Position

			table.insert(self.PointsCopy, position or #self.PointsCopy+1, CFrame.lookAt(at, lookAt))
		end}
	},
	End = {
		{"DisableControls", function()
			controls:Enable(true)
		end},
		{"FreezeCharacter", function()
			rootPart.Anchored = false
		end},
		{"CustomCamera", function(self)
			camera.CameraType = self.PreviousCameraType
			camera = workspace.CurrentCamera
		end}
	}
}

--configure specialFunctions table
specialFunctions.StartKeys = {}
specialFunctions.EndKeys = {}
for i, v in ipairs(specialFunctions.Start) do
	table.insert(specialFunctions.StartKeys, v[1])
	specialFunctions.Start[i] = v[2]
end
for i, v in ipairs(specialFunctions.End) do
	table.insert(specialFunctions.EndKeys, v[1])
	specialFunctions.End[i] = v[2]
end

local cutscene = {}
cutscene.__index = cutscene
cutscene.ClassName = "Cutscene"

function cutscene:Play():()
	if
		module.Playing == nil
		or module.Playing.CurrentCutscene == self
		or module.Playing.Next == self
	then

		if not module.Playing or not module.Playing.CurrentCutscene then
			module.Playing = self
		end

		self.PointsCopy = {unpack(self.Points)}
		local pointsCopy = self.PointsCopy
		local easingFunction = easingFunctions[self.EasingFunction]
		local duration = self.Duration
		local passedTime

		if not self.Next then
			self.PreviousCoreGuis = getCoreGuisEnabled()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
			self.PreviousCameraType = camera.CameraType
		end

		for _, v in ipairs(self.SpecialFunctions[1]) do
			if type(v) == "table" then
				specialFunctions.Start[v[1]](self, select(2, unpack(v)))
			else
				specialFunctions.Start[v](self)
			end
		end

		assert(#self.PointsCopy > 1, "More than one point is required")

		camera.CameraType = Enum.CameraType.Scriptable

		self.PlaybackState = Enum.PlaybackState.Playing
		local start = clock()

		RunService:BindToRenderStep("Cutscene", Enum.RenderPriority.Camera.Value+1, function()
			passedTime = clock() - start

			if passedTime <= duration then
				camera.CFrame = getCF(pointsCopy, easingFunction(passedTime, 0, 1, duration))
				self.Progress = passedTime / duration
				self.PassedTime = passedTime
			else
				RunService:UnbindFromRenderStep("Cutscene")
				self.Progress = 1
				self.PassedTime = duration

				for _, v in ipairs(self.SpecialFunctions[2]) do
					if type(v) == "table" then
						specialFunctions.End[v[1]](self, select(2, unpack(v)))
					else
						specialFunctions.End[v](self)
					end
				end

				self.PlaybackState = Enum.PlaybackState.Completed

				if self.Next then
					if self.Next == 0 then --last (0 only occurs in queue)
						local queue = module.Playing --other name maybe
						module.Playing = nil
						queue.PlaybackState = Enum.PlaybackState.Completed
						camera.CameraType = queue.PreviousCameraType
						queue.CurrentCutscene = nil
						for k, v in next, queue.PreviousCoreGuis do
							if v then
								StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType[k], true)
							end
						end
						for _, v in ipairs(queue.Cutscenes) do
							v.Next = nil
						end
						queue.Completed:Fire(Enum.PlaybackState.Completed)
					else
						if module.Playing.CurrentCutscene then --if queue
							module.Playing.CurrentCutscene = self.Next
						end
						self.Completed:Fire(Enum.PlaybackState.Completed)
						self.Next:Play()
					end
				else
					module.Playing = nil
					if not self.CustomCamera then
						camera.CameraType = self.PreviousCameraType
					end

					for k, v in next, self.PreviousCoreGuis do
						if v then
							StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType[k], true)
						end
					end
					self.Completed:Fire(Enum.PlaybackState.Completed)
				end
			end
		end)
	else
		error("Error while calling Play - A cutscene was already playing")
	end
end

function cutscene:Pause(waitTime:number?):()
	if module.Playing then
		if self.PassedTime == nil then
			error("Error while calling Pause - Cutscene hasn't started yet")
		end
		RunService:UnbindFromRenderStep("Cutscene")
		local playingQueue
		if module.Playing.CurrentCutscene then
			playingQueue = module.Playing
		end
		module.Playing = nil

		self.PlaybackState = Enum.PlaybackState.Paused
		if self.CustomCamera then
			camera = workspace.CurrentCamera
		end

		if waitTime then
			if module.Settings.YieldPauseArgument then
				task.wait(waitTime)
				if playingQueue then
					playingQueue:Resume()
				else
					self:Resume()
				end
			else
				task.spawn(function()
					task.wait(waitTime)
					if playingQueue then
						playingQueue:Resume()
					else
						self:Resume()
					end
				end)
			end
		end
	else
		error("Error while calling Pause - There was no cutscene playing")
	end
end

function cutscene:Resume():()
	if module.Playing == nil or module.Playing.CurrentCutscene == self then
		if self.PassedTime and self.PassedTime ~= 0 then

			module.Playing = module.Playing or self
			local duration = self.Duration
			local pointsCopy = self.PointsCopy
			local easingFunction = easingFunctions[self.EasingFunction]
			local passedTime = self.PassedTime

			self.PlaybackState = Enum.PlaybackState.Playing
			if self.CustomCamera then
				camera = self.CustomCamera
			end
			camera.CameraType = Enum.CameraType.Scriptable
			local start = clock() - passedTime

			RunService:BindToRenderStep("Cutscene", Enum.RenderPriority.Camera.Value+1, function()
				passedTime = clock() - start

				if passedTime <= duration then
					camera.CFrame = getCF(pointsCopy, easingFunction(passedTime, 0, 1, duration))
					self.Progress = passedTime / duration
					self.PassedTime = passedTime
				else
					RunService:UnbindFromRenderStep("Cutscene")
					self.Progress = 1
					self.PassedTime = duration

					for _, v in ipairs(self.SpecialFunctions[2]) do
						if type(v) == "table" then
							specialFunctions.End[v[1]](self, select(2, unpack(v)))
						else
							specialFunctions.End[v](self)
						end
					end

					self.PlaybackState = Enum.PlaybackState.Completed

					if self.Next then
						if self.Next == 0 then --last (0 only occurs in queue)
							local queue = module.Playing --other name maybe
							module.Playing = nil
							queue.PlaybackState = Enum.PlaybackState.Completed
							camera.CameraType = queue.PreviousCameraType
							queue.CurrentCutscene = nil
							for k, v in next, queue.PreviousCoreGuis do
								if v then
									StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType[k], true)
								end
							end
							for _, v in ipairs(queue.Cutscenes) do
								v.Next = nil
							end
							queue.Completed:Fire(Enum.PlaybackState.Completed)
						else
							if module.Playing.CurrentCutscene then --if queue
								module.Playing.CurrentCutscene = self.Next
							end
							self.Completed:Fire(Enum.PlaybackState.Completed)
							self.Next:Play()
						end
					else
						module.Playing = nil
						if not self.CustomCamera then
							camera.CameraType = self.PreviousCameraType
						end

						for k, v in next, self.PreviousCoreGuis do
							if v then
								StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType[k], true)
							end
						end
						self.Completed:Fire(Enum.PlaybackState.Completed)
					end
				end
			end)
		else
			self:Play()
		end
	else
		error("Error while calling Resume - The cutscene was already playing")
	end
end

function cutscene:Cancel():()
	if module.Playing then
		RunService:UnbindFromRenderStep("Cutscene")
		module.Playing = nil

		for _, v in ipairs(self.SpecialFunctions[2]) do
			if type(v) == "table" then			
				specialFunctions.End[v[1]](self, select(2, unpack(v)))
			else
				specialFunctions.End[v](self)
			end
		end

		if not self.Next then
			if not self.CustomCamera then
				camera.CameraType = self.PreviousCameraType
			end
			for k, v in next, self.PreviousCoreGuis do
				if v then
					StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType[k], true)
				end
			end
		end

		self.PlaybackState = Enum.PlaybackState.Cancelled
		self.Completed:Fire(Enum.PlaybackState.Cancelled)
	else
		error("Error while calling Cancel - There was no cutscene playing")
	end
end

function cutscene:Destroy():()
	table.clear(self)
	setmetatable(self, nil)
end

function module:Create(points:Instance|{[number]:CFrame}, duration:number, ...)
	assert(points, "Argument 1 (points) missing or nil")
	assert(duration, "Argument 2 (duration) missing or nil")

	local self = {}
	self.Completed = Signal.new()
	self.PlaybackState = Enum.PlaybackState.Begin
	self.Progress = 0
	self.Duration = duration
	self.PreviousCameraType = nil
	self.PreviousCoreGuis = nil

	local args = {...}

	if typeof(points) == "Instance" then
		assert(typeof(points) ~= "table", "Argument 1 (points) not an instance or table")
		local instances = points:GetChildren()
		points = {}

		table.sort(instances, function(a, b)
			return tonumber(a.Name) < tonumber(b.Name)
		end)
		for _, v in ipairs(instances) do
			table.insert(points, v.CFrame)
		end
	end
	self.Points = points

	self.EasingFunction = "Linear"
	local dir, style = "In", nil
	for _, v in ipairs(args) do
		if easingFunctions[v] then
			self.EasingFunction = v
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
		self.EasingFunction = dir..style
	end

	self.SpecialFunctions = {{},{}}
	for i, v in ipairs(specialFunctions.StartKeys) do
		local idx = 0
		repeat
			idx = table.find(args, v, idx+1)
			if idx then --if special function is in args
				local a = {} --arguments for s.f.

				local init = idx + 1 --check for arguments for s.f
				repeat
					local Next = args[init]
					local isArg = (Next or Next == false)
						and typeof(Next) ~= "string"
						and typeof(Next) ~= "EnumItem"
					if isArg then
						table.insert(a, Next)
						init += 1
					end
				until not isArg

				if #a == 0 then
					table.insert(self.SpecialFunctions[1], i)
				else
					table.insert(a, 1, i) --first number is s.f., after that args
					table.insert(self.SpecialFunctions[1], a)
				end
			end
		until not idx
	end
	for i, v in ipairs(specialFunctions.EndKeys) do
		local idx = 0
		repeat
			idx = table.find(args, v, idx+1)
			if idx then
				local a = {}

				local init = idx + 1
				repeat
					local Next = args[init]
					local isArg = (Next or Next == false)
						and typeof(Next) ~= "string"
						and typeof(Next) ~= "EnumItem"
					if isArg then
						table.insert(a, Next)
						init += 1
					end
				until not isArg

				if #a == 0 then
					table.insert(self.SpecialFunctions[2], i)
				else
					table.insert(a, 1, i)
					table.insert(self.SpecialFunctions[2], a)
				end
			end
		until not idx
	end

	return setmetatable(self, cutscene)
end

local queue = {}
queue.__index = queue
queue.ClassName = "Queue"

function queue:Play():()
	if module.Playing == nil then
		module.Playing = self
		local cutscenes = self.Cutscenes

		for i, v in ipairs(cutscenes) do
			if cutscenes[i+1] then
				v.Next = cutscenes[i+1]
			else
				v.Next = 0 --last
			end
		end

		self.PreviousCoreGuis = getCoreGuisEnabled()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
		self.PreviousCameraType = camera.CameraType		
		self.PlaybackState = Enum.PlaybackState.Playing

		module.Playing = self
		self.CurrentCutscene = cutscenes[1]
		cutscenes[1]:Play()
	else
		error("Error while calling Play - A cutscene/queue was already playing")
	end
end

function queue:Pause(waitTime:number?):()
	if module.Playing then
		self.CurrentCutscene:Pause(waitTime)
	else
		error("Error while calling Pause - There was no queue playing")
	end
end

function queue:Resume():()
	if module.Playing == nil then
		module.Playing = self
		self.CurrentCutscene:Resume()
	else	
		error("Error while calling Resume - A cutscene/queue was already playing")
	end
end

function queue:Cancel():()
	if module.Playing then
		self.CurrentCutscene:Cancel()
		self.CurrentCutscene = nil
		camera.CameraType = self.PreviousCameraType
		for k, v in next, self.PreviousCoreGuis do
			if v then
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType[k], true)
			end
		end
		for _, v in ipairs(self.Cutscenes) do
			v.Next = nil
		end
		self.PlaybackState = Enum.PlaybackState.Cancelled
		self.Completed:Fire(Enum.PlaybackState.Cancelled)
	else
		error("Error while calling Cancel - There was no queue playing")
	end
end

function queue:Destroy()
	table.clear(self)
	setmetatable(self, nil)
end

function module:CreateQueue(...)
	local self = {}
	self.Completed = Signal.new()
	self.PlaybackState = Enum.PlaybackState.Begin
	self.Cutscenes = {...}

	return setmetatable(self, queue)
end

return module
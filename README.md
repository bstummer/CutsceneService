<div align="center">

# CutsceneService
### Smooth cutscenes using Bézier curves

[![Roblox Model](https://img.shields.io/badge/Roblox-Model-blue?logo=roblox)](https://www.roblox.com/library/5539329435)
[![Roblox Plugin](https://img.shields.io/badge/Roblox-Plugin-blue?logo=roblox)](https://www.roblox.com/library/9288927730)

</div>

<br>

## Introduction

TweenService is probably the best choice for tweening between 2 points. However, when you have more than 2 points, calculating multiple tweens linearly doesn't look good and can feel rigid. 

**CutsceneService** is a module which specializes in solving this using **[Bézier curves](https://en.wikipedia.org/wiki/B%C3%A9zier_curve)**. It provides a smooth camera transition across multiple points, is easy to use, fully customizable, and comes with a wide range of features.

[![CutsceneService Showcase](https://img.youtube.com/vi/AyFJAU0B5V8/maxresdefault.jpg)](https://youtu.be/AyFJAU0B5V8)
*(Click the image to watch the showcase video on YouTube)*

<br>

## Getting Started

> **Note:** It is highly recommended to use the [CutsceneService Helper Plugin](https://www.roblox.com/library/9288927730) as it greatly facilitates the workflow by letting you easily create, visualize, and preview your paths directly in Studio.

1. Get the module from the [Roblox Library](https://www.roblox.com/library/5539329435) and insert it into your game (preferably inside `ReplicatedStorage`).
2. Create a Folder in `Workspace` and name it `Cutscene1`.
3. Insert parts (also called points) into the folder. Name the parts `1`, `2`, `3`, etc. The cutscene will start at point `1` and end at the highest numbered point.
4. Position the parts and make sure their front surfaces are looking in the direction you want the camera to face.

*Tip: The more points in a cutscene, the more calculations have to be done - don't add unnecessarily many!*

Now create a `LocalScript` in `StarterGui` to play the cutscene:

```lua
local CutsceneService = require(game.ReplicatedStorage.CutsceneService)

-- Create a new cutscene targeting the folder we made, with a duration of 5 seconds
local cutscene1 = CutsceneService:Create(workspace.Cutscene1, 5)

-- Play the cutscene after a short delay
task.wait(4)
cutscene1:Play()
```

<br>

## Easing & Special Functions
You usually don't want just a plain linear cutscene. You can apply Easing Styles, Easing Directions, and Special Functions by passing them as additional arguments to the Create function. The order of the arguments (after the first two) doesn't matter.

### Easings
You can use standard Roblox Enums or the string name of a specific easing function:

```lua
CutsceneService:Create(workspace.Cutscene1, 5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

-- Or using strings:
CutsceneService:Create(workspace.Cutscene1, 5, "InOutSine")
```
*Note: Unlike TweenService, CutsceneService also supports the `OutIn` easing direction (callable via string).*

### Special Functions
Special functions are triggered during the cutscene. You can call them with a string or use `CutsceneService.Enum` to autocomplete the name:

```lua
-- Sets the player's current camera position as a point in the cutscene
CutsceneService:Create(workspace.Cutscene1, 5, "CurrentCameraPoint")

-- Using the Enum dictionary for autocomplete
CutsceneService:Create(workspace.Cutscene1, 5, CutsceneService.Enum.CurrentCameraPoint)
```

<br>

## Queues
Queues allow you to play multiple cutscenes back-to-back seamlessly.

```lua
local queue1 = CutsceneService:CreateQueue(cutscene1, cutscene2, cutscene3)
queue1:Play()
```
Queues share the same playback controls as single cutscenes (`Play`, `Pause`, `Resume`, `Cancel`, `Destroy`).
You can also loop a single cutscene or a queue using the `Next` property:

```lua
-- Looping a single cutscene:
cutscene1:Play()
cutscene1.Next = cutscene1

-- Looping a queue:
local queue = CutsceneService:CreateQueue(cutscene1, cutscene2, cutscene3)
queue:Play()
cutscene3.Next = cutscene1
```
*(Note: The Next property will be overwritten if the cutscene is played as part of a queue's internal list).*

<br>

## Advanced Tips & Tricks
### PreviousCameraType and PreviousCoreGuis
These are properties created when a cutscene or queue is played. They cache the CameraType and CoreGui settings from before the playback to restore them afterward. You can manipulate these if you don't want the camera to instantly snap back to the player:

```lua
cutscene1:Play()
cutscene1.PreviousCameraType = Enum.CameraType.Scriptable

for k in cutscene1.PreviousCoreGuis do
	cutscene1.PreviousCoreGuis[k] = false
end

cutscene1.Completed:Connect(function()
	task.wait(3) -- Wait 3 seconds, then restore manually
	workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
	game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
end)
```

### Changing points during playback
You can dynamically modify the points while the cutscene is playing. Cutscenes have a `Points` property (your original points) and a `PointsCopy` property (a temporary copy modified by special functions during playback).

```lua
local cutscene4 = CutsceneService:Create(
	{}, 7, "InOutSine", -- an empty table is passed as points
	CutsceneService.Enum.CurrentCameraPoint, 1,
	CutsceneService.Enum.CurrentCameraPoint,
	CutsceneService.Enum.DisableControls
)

-- Inject points at runtime:
local p1 = CFrame.lookAt(root.Position + Vector3.new(0, 100, 0), root.Position)
local p2 = CFrame.lookAt(root.Position + Vector3.new(0, 15, 0), root.Position)

cutscene4:Play()
table.insert(cutscene4.PointsCopy, 2, p1)
table.insert(cutscene4.PointsCopy, 3, p2)
```

<br>

## API Documentation
For full API documentation - including all properties, functions, events, and a detailed list of special functions - please refer to the [official DevForum tutorial & documentation post](https://devforum.roblox.com/t/718571).

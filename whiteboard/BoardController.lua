local whiteboard = script.Parent
local screenFrame = whiteboard.ScreenBoard.Frame
local surfaceFrame = whiteboard.SurfaceBoard.Frame

local cursorsFrame = whiteboard.Cursors.Frame

local screenLines = whiteboard.ScreenLines
local surfaceLines = whiteboard.SurfaceLines

local whiteboardDrawEvent = game.ReplicatedStorage:FindFirstChild(whiteboard.Name .. "DrawEvent")
local whiteboardCursorEvent = game.ReplicatedStorage:FindFirstChild(whiteboard.Name .. "CursorEvent")
local whiteboardClearEvent = game.ReplicatedStorage:FindFirstChild(whiteboard.Name .. "ClearEvent")
local whiteboardUndoEvent = game.ReplicatedStorage:FindFirstChild(whiteboard.Name .. "UndoEvent")

local whiteboardReplayRecordingStartEvent = game.ReplicatedStorage:FindFirstChild(whiteboard.Name .. "ReplayRecordingStartEvent")
local whiteboardReplayRecordingStopEvent = game.ReplicatedStorage:FindFirstChild(whiteboard.Name .. "ReplayRecordingStopEvent")
local whiteboardReplayPlaybackStartEvent = game.ReplicatedStorage:FindFirstChild(whiteboard.Name .. "ReplayPlaybackStartEvent")
local whiteboardReplayPlaybackStopEvent = game.ReplicatedStorage:FindFirstChild(whiteboard.Name .. "ReplayPlaybackStopEvent")
local whiteboardReplaySaveEvent = game.ReplicatedStorage:FindFirstChild(whiteboard.Name .. "ReplaySaveEvent")
local whiteboardReplayLoadEvent = game.ReplicatedStorage:FindFirstChild(whiteboard.Name .. "ReplayLoadEvent")

----------------------------------------------------------------------------------------------------
-- Handle activation and deactivation of this whiteboard FOR THIS CLIENT
-- Search for the boardActivate flag in this script to see what it prevents when false.

local whiteboardActivateEvent = game.ReplicatedStorage:FindFirstChild("WhiteboardActivateEvent")
local whiteboardDeactivateEvent = game.ReplicatedStorage:FindFirstChild("WhiteboardDeactivateEvent")
local boardActive = true
whiteboardActivateEvent.OnClientEvent:Connect(function() boardActive = true end)
whiteboardDeactivateEvent.OnClientEvent:Connect(function() boardActive = false end)
----------------------------------------------------------------------------------------------------

-- DM 21/3/21
-- when a board is closed we parent the Frame objects to ReplicatedStorage
-- under metauni_whiteboard/whiteboardName
local whiteboardStorageFolder = game.ReplicatedStorage:findFirstChild("metauni_whiteboard")

if not whiteboardStorageFolder then
	local f = Instance.new("Folder")
	f.Name = "metauni_whiteboard"
	f.Parent = game.ReplicatedStorage
	whiteboardStorageFolder = f
end

local screenlinesStorage = whiteboardStorageFolder:findFirstChild(whiteboard.Name)

if not screenlinesStorage then
	local f = Instance.new("Folder")
	f.Name = whiteboard.Name
	f.Parent = whiteboardStorageFolder
	screenlinesStorage = f
end

local boardFolder = whiteboard.SurfaceBoard.Adornee.Parent.Parent

local DEBUG_COUNT_LINES = true
--

local MIN_THICKNESS = 0.5
local MAX_THICKNESS = 64
local MIN_LINE_LENGTH = 0
local RADIANS_TO_DEGREES = 180.0/math.pi

local screenGuiOpen = false
local mouseHeld = false
local prevMousePos = Vector2.new(0,0)
local mousePos = Vector2.new(0,0)
local curveIndex = 0
local curveDisplayOrder = 1 --ensures that newer curves are drawn on top of older ones

local thickness = MIN_THICKNESS
local color = Color3.new(0,0,0)




-- functions which convert between absolute pixel coordinates and relative coordinates 
-- (coordinates which range from 0 to 1 on both axes)
-- this depends on the size of the gui
local function absoluteToRelative(coords, gui)
	return (coords - gui.AbsolutePosition)/gui.AbsoluteSize
end

local function relativeToAbsolute(coords, gui)
	return coords*gui.AbsoluteSize + gui.AbsolutePosition
end

-- function which looks for a specific folder inside a guiFrame's lines folder
-- it returns the folder if it exists, otherwise it creates and returns it.
local function getCurveGuis(name)
	local screengui = screenLines:findFirstChild(name)
	if not screengui then
		screengui = Instance.new("ScreenGui")
		screengui.Name = name
		screengui.IgnoreGuiInset = true
		screengui.ResetOnSpawn = false
		screengui.Parent = screenLines
		screengui.DisplayOrder = curveDisplayOrder
		curveDisplayOrder = curveDisplayOrder+1
		
		local frame = Instance.new("Frame")
		frame.Visible = screenFrame.Visible
		frame.Position = UDim2.new(0,0,0,0)
		frame.Size = UDim2.new(1,0,1,0)
		frame.BackgroundTransparency = 1
		frame.Parent = screengui

	end
	
	local surfacegui = surfaceLines:findFirstChild(name)
	if not surfacegui then
		surfacegui = Instance.new("SurfaceGui")
		surfacegui.Name = name
		surfacegui.ResetOnSpawn = false
		surfacegui.Adornee = whiteboard.SurfaceBoard.Adornee
		surfacegui.SizingMode = "PixelsPerStud"
		surfacegui.Parent = surfaceLines

		local frame = Instance.new("Frame")
		frame.Visible = true
		frame.Position = UDim2.new(0,0,0,0)
		frame.Size = UDim2.new(1,0,1,0)
		frame.BackgroundTransparency = 1
		frame.Parent = surfacegui

	end
	return screengui, surfacegui
end

-- function which creates and draws a line segement on both the surface and screen guis

local function drawLine(oName, oCurveIndex, oPrevMousePos, oMousePos, oThickness, oColor)
	
	local screenGui, surfaceGui = getCurveGuis(oName .. tostring(oCurveIndex))
	
	-- draw the line on the screen gui
	local screenLineVec = (oMousePos-oPrevMousePos)*screenFrame.Board.AbsoluteSize
	local screenLineRotation = math.atan2(screenLineVec.Y, screenLineVec.X)*RADIANS_TO_DEGREES
	local screenLinePosition = relativeToAbsolute((oMousePos+oPrevMousePos)/2, screenFrame.Board)

	local screenLine = Instance.new("Frame")
	screenLine.Size = UDim2.new(0,screenLineVec.Magnitude+oThickness, 0, oThickness)
	screenLine.Position = UDim2.new(0,screenLinePosition.X,0,screenLinePosition.Y)
	screenLine.Rotation = screenLineRotation
	screenLine.AnchorPoint = Vector2.new(0.5,0.5) --this bases the position and rotation at the same point (object centre)
	screenLine.BackgroundColor3 = oColor
	screenLine.BorderColor3 = oColor
	screenLine.BorderSizePixel = 1
	screenLine.Parent = screenGui.Frame
	
	-- draw the line on the surface gui
	--local surfaceLineVec = (oMousePos-oPrevMousePos)*surfaceFrame.Board.AbsoluteSize
	--local surfaceLineRotation = math.atan2(surfaceLineVec.Y, surfaceLineVec.X)*RADIANS_TO_DEGREES
	--local surfaceLinePosition = relativeToAbsolute((oMousePos+oPrevMousePos)/2, surfaceFrame.Board)

	--local surfaceLine = Instance.new("Frame")
	--surfaceLine.Size = UDim2.new(0,surfaceLineVec.Magnitude+oThickness, 0, oThickness)
	--surfaceLine.Position = UDim2.new(0,surfaceLinePosition.X,0,surfaceLinePosition.Y)
	--surfaceLine.Rotation = surfaceLineRotation
	--surfaceLine.AnchorPoint = Vector2.new(0.5,0.5) --this bases the position and rotation at the same point (object centre)
	--surfaceLine.BackgroundColor3 = oColor
	--surfaceLine.BorderColor3 = oColor
	--surfaceLine.BorderSizePixel = 1
	--surfaceLine.Parent = surfaceGui.Frame
end

-- function which draws a cursor on the whiteboard
-- if it is not the players own cursor, it also draws their username
local function drawCursor(name,pos,thickness,color)
	local cursor = cursorsFrame:FindFirstChild(name)
	
	-- if we receive a nil event then destroy the cursor if it exists
	if pos == nil then
		if cursor then cursor:Destroy() end
		return
	end

	-- otherwise draw the cursor
	local absolutePos = relativeToAbsolute(pos, screenFrame.Board)
	
	--check if the cursor object already exists, if it doesn't create a new one
	if cursor == nil then
		cursor = Instance.new("TextLabel")
		cursor.Name = name
	end
	-- update the cursor object
	cursor.Size = UDim2.new(0,thickness, 0, thickness)
	cursor.Position = UDim2.new(0,absolutePos.X,0,absolutePos.Y)
	cursor.AnchorPoint = Vector2.new(0.5,0.5) --this bases the position and rotation at the same point (object centre)
	cursor.BackgroundColor3 = color
	cursor.BackgroundTransparency = 0.5
	cursor.BorderColor3 = color
	cursor.BorderSizePixel = 1
	cursor.TextTransparency = 0.5
	
	-- don't bother drawing the name if it's the player's own name
	if name == game.Players.LocalPlayer.Name then
		cursor.Text = ""
	else 
		cursor.Text = name
	end
	
	cursor.Parent = cursorsFrame
end


-- functions which open and close the screenGui
local function openGui()
	screenGuiOpen = true
	mouseHeld = false
	
	game.StarterGui:SetCore("TopbarEnabled", false)
	
	screenFrame.Visible = true
	cursorsFrame.Visible = true
	
	-- DM 21/3/21 start
	for _, child in ipairs(screenlinesStorage:GetChildren()) do
		child.Parent = screenLines
	end	
	-- DM 21/3/21 end

	-- note that some of these lines have arrived from events
	for _, child in ipairs(screenLines:GetChildren()) do
		child.Frame.Visible = true
	end
end
-- end

local function closeGui()
	screenGuiOpen  = false
	mouseHeld = false
	
	game.StarterGui:SetCore("TopbarEnabled", true)
	
	whiteboardCursorEvent:FireServer(game.Players.LocalPlayer.Name, nil, nil, nil)
	
	screenFrame.Visible = false
	cursorsFrame.Visible = false
	whiteboard.ClearConfirmBox.Frame.Visible = false
	whiteboard.RecordingBox.Frame.Visible = false

	for _, child in ipairs(screenLines:GetChildren()) do
		child.Parent = screenlinesStorage -- DM 21/3/21
		child.Frame.Visible = false
	end

	-- TODO count number of lines in WorldFolder
	if DEBUG_COUNT_LINES then
		local count = 0
		for _, child in ipairs(boardFolder.WorldLines:GetDescendants()) do
			if child:IsA("BasePart") then
				count = count + 1
			end
		end
		print("Board "..boardFolder.Name.." has "..count.." lines")
	end
end




-----------------------------------------
-- set up local drawing events

screenFrame.Board.MouseMoved:Connect(function(x,y)
	local diff = Vector2.new(x,y) - relativeToAbsolute(mousePos, screenFrame.Board)
	if diff.Magnitude < MIN_LINE_LENGTH then return end
	
	-- store the previous mouse coordinates in prevMousePos, and get the new mouse coordinates
	prevMousePos = mousePos
	mousePos = absoluteToRelative(Vector2.new(x, y), screenFrame.Board)
	
	-- draw the cursor, and fire the event for the other players
	drawCursor(game.Players.LocalPlayer.Name, mousePos, thickness, color)
	whiteboardCursorEvent:FireServer(game.Players.LocalPlayer.Name, mousePos, thickness, color)
	
	-- if the mouse is held draw a line and fire the event for the other players
	if mouseHeld and boardActive then
		drawLine(game.Players.LocalPlayer.Name, curveIndex, prevMousePos, mousePos, thickness, color)
		whiteboardDrawEvent:FireServer(game.Players.LocalPlayer.Name, curveIndex, prevMousePos, mousePos, thickness, color)
	end 
	
end)

screenFrame.Board.MouseButton1Down:Connect(function(x,y) 
	mouseHeld = true 
	curveIndex = curveIndex+1
	
	-- set both of mousePos and prevMousePos to the current mouse position
	mousePos = absoluteToRelative(Vector2.new(x, y), screenFrame.Board)
	prevMousePos = mousePos
	
	if mouseHeld and boardActive then
		drawLine(game.Players.LocalPlayer.Name, curveIndex, prevMousePos, mousePos, thickness, color)
		whiteboardDrawEvent:FireServer(game.Players.LocalPlayer.Name, curveIndex, prevMousePos, mousePos, thickness, color)
	end 
end)

screenFrame.Board.MouseButton1Up:Connect(function(x,y) 
	mouseHeld = false
end)

--------------------------------------
-- handle receiving whiteboard events from server

whiteboardDrawEvent.OnClientEvent:Connect(function(oName, oCurveIndex, oPrevMousePos, oMousePos, oThickness, oColor)
	-- don't need to handle the event if we're the one who fired it
	if oName == game.Players.LocalPlayer.Name then return end
	drawLine(oName, oCurveIndex, oPrevMousePos, oMousePos, oThickness, oColor)
end)

whiteboardCursorEvent.OnClientEvent:Connect(function(oName, oMousePos, oThickness, oColor)
	-- don't need to handle the event if we're the one who fired it
	if oName == game.Players.LocalPlayer.Name then return end
	drawCursor(oName, oMousePos, oThickness, oColor)
end)

whiteboardClearEvent.OnClientEvent:Connect(function()
	screenLines:ClearAllChildren()
	surfaceLines:ClearAllChildren()
	screenlinesStorage:ClearAllChildren() -- DM 21/3/21
	curveIndex = 0
end)


whiteboardUndoEvent.OnClientEvent:Connect(function(oName, oCurveIndex)
	local screenLine, surfaceLine = getCurveGuis(oName .. tostring(oCurveIndex))
	screenLine:Destroy()
	surfaceLine:Destroy()
end)


---------------------------------
-- set up button events

surfaceFrame.Board.Activated:Connect(function() 
	openGui()
end)

screenFrame.Buttons.CloseButton.Activated:Connect(function() 
	closeGui()
end)

screenFrame.Buttons.UndoButton.Activated:Connect(function()
	if not boardActive then return end
	whiteboardUndoEvent:FireServer(game.Players.LocalPlayer.Name, curveIndex)
	curveIndex = curveIndex-1
end)

screenFrame.Buttons.ClearButton.Activated:Connect(function()
	if not boardActive then return end
	whiteboard.ClearConfirmBox.Frame.Visible = true
end)

whiteboard.ClearConfirmBox.Frame.YesButton.Activated:Connect(function()
	whiteboardClearEvent:FireServer()
	curveIndex = 0
	whiteboard.ClearConfirmBox.Frame.Visible = false
end)

whiteboard.ClearConfirmBox.Frame.NoButton.Activated:Connect(function()
	whiteboard.ClearConfirmBox.Frame.Visible = false
end)

screenFrame.Buttons.RecordControlsButton.Activated:Connect(function()
	whiteboard.RecordingBox.Frame.Visible = true
end)

whiteboard.RecordingBox.Frame.CloseButton.Activated:Connect(function()
	whiteboard.RecordingBox.Frame.Visible = false
end)

whiteboard.RecordingBox.Frame.StartPlaybackButton.Activated:Connect(function()
	whiteboardReplayPlaybackStartEvent:FireServer()
end)

whiteboard.RecordingBox.Frame.StartRecordButton.Activated:Connect(function()
	whiteboardReplayRecordingStartEvent:FireServer()
end)

whiteboard.RecordingBox.Frame.StopPlaybackButton.Activated:Connect(function()
	whiteboardReplayPlaybackStopEvent:FireServer()
end)

whiteboard.RecordingBox.Frame.StopRecordButton.Activated:Connect(function()
	whiteboardReplayRecordingStopEvent:FireServer()
end)

whiteboard.RecordingBox.Frame.SaveButton.Activated:Connect(function()
	whiteboardReplaySaveEvent:FireServer(whiteboard.RecordingBox.Frame.ReplayNameTextBox.Text)
end)

whiteboard.RecordingBox.Frame.LoadButton.Activated:Connect(function()
	whiteboardReplayLoadEvent:FireServer(whiteboard.RecordingBox.Frame.ReplayNameTextBox.Text)
end)

screenFrame.Buttons.ThickerButton.Activated:Connect(function() 
	thickness = math.min(thickness*2, MAX_THICKNESS)
end)

screenFrame.Buttons.ThinnerButton.Activated:Connect(function() 
	thickness = math.max(thickness/2, MIN_THICKNESS)
end)

screenFrame.Buttons.PenBlackButton.Activated:Connect(function() 
	color = Color3.new(0,0,0)
end)

screenFrame.Buttons.PenWhiteButton.Activated:Connect(function() 
	color = Color3.new(1,1,1)
end)

screenFrame.Buttons.PenRedButton.Activated:Connect(function() 
	color = Color3.new(1,0,0)
end)

screenFrame.Buttons.PenGreenButton.Activated:Connect(function() 
	color = Color3.new(0,150/255,0)
end)

screenFrame.Buttons.PenBlueButton.Activated:Connect(function() 
	color = Color3.new(0,0,1)
end)

screenFrame.Buttons.PenOrangeButton.Activated:Connect(function() 
	color = Color3.new(255/255,155/255,0)
end)

screenFrame.Buttons.PenBrownButton.Activated:Connect(function() 
	color = Color3.new(150/255,70/255,30/255)
end)

screenFrame.Buttons.PenPurpleButton.Activated:Connect(function() 
	color = Color3.new(130/255,0,130/255)
end)

screenFrame.Buttons.PenPinkButton.Activated:Connect(function() 
	color = Color3.new(1,100/255,150/255)
end)

screenFrame.Buttons.PenYellowButton.Activated:Connect(function() 
	color = Color3.new(1,220/255,0)
end)

------- spiel controls DM 24/4/21

local startSpielButton = script.Parent.StartReplay.ImageButton
local spielState = "pause"

startSpielButton.Activated:Connect(function()
	if spielState == "pause" then
		local spielPlayEvent = game.ReplicatedStorage:FindFirstChild(whiteboard.Name .. "SpielPlayEvent")	
		spielPlayEvent:FireServer()
	elseif spielState == "play" then
		local spielPauseEvent = game.ReplicatedStorage:FindFirstChild(whiteboard.Name .. "SpielPauseEvent")
		spielPauseEvent:FireServer()
	end
end)

local spielPlayEvent = game.ReplicatedStorage:FindFirstChild(whiteboard.Name .. "SpielPlayEvent")
spielPlayEvent.OnClientEvent:Connect(function()
	spielState = "play"
	startSpielButton.Rotation = 0
	startSpielButton.Image = "rbxassetid://55568085"
end)

local spielPauseEvent = game.ReplicatedStorage:FindFirstChild(whiteboard.Name .. "SpielPauseEvent")
spielPauseEvent.OnClientEvent:Connect(function()
	spielState = "pause"
	startSpielButton.Image = "rbxassetid://6240345359"
	startSpielButton.Rotation = -90
end)

local replayEndEvent = game.ReplicatedStorage:FindFirstChild(whiteboard.Name .. "ReplayEndEvent")
replayEndEvent.OnClientEvent:Connect(function()
	print("Replay ended")
	spielState = "pause"
	startSpielButton.Image = "rbxassetid://6240345359"
	startSpielButton.Rotation = -90
	
	-- start the next board
	local nextBoard = boardFolder.Config.NextBoard.Value
	if nextBoard ~= "" then
		local nextBoardEvent = game.ReplicatedStorage:FindFirstChild(nextBoard .. "SpielPlayEvent")
		nextBoardEvent:FireServer()
	end
end)

-- this script is responsible for setting up the whiteboard upon starting the server
-- ie. creating the events, the server script, and putting the gui into starter gui

local whiteboard = script.Parent

local runService = game:GetService("RunService")
local httpService = game:GetService("HttpService")

local replayDataStore = game:GetService("DataStoreService"):GetDataStore("replayDataStore")

-- replay data
local replayPlaybackStartTime = tick()
local replayRecordingStartTime = tick()
local replayPauseTime = 0
local replayPlaybackActive = false
local replayRecordingActive = false
local replayPlaybackIndex = 1
local replayPlaybackSpeed = 1.0
local replayHistory = {}

-- set the configs DM 24/4/21
whiteboard.WhiteboardModel.Board.Color = whiteboard.Config.BoardColor.Value
whiteboard.Gui.ScreenBoard.Frame.Board.BackgroundColor3 = whiteboard.Config.BoardColor.Value
whiteboard.Gui.ScreenBoard.Frame.Buttons.RecordControlsButton.Visible = whiteboard.Config.AllowRecord.Value
whiteboard.Gui.StartReplay.TextLabel.Text = whiteboard.Config.BoardNumber.Value

local replaySound = whiteboard.Config.Sound
replaySound.Parent = whiteboard.WhiteboardModel.Board
	
-- move the gui to starter gui
local guiFolder = whiteboard.Gui
guiFolder.Parent = game.StarterGui
guiFolder.Name = whiteboard.Name

-- set the adornee
guiFolder.SurfaceBoard.Adornee = whiteboard.WhiteboardModel.Board

-- set up the replay functions
local function addToReplayHistory(eventType, data)
	if not replayRecordingActive then return end
	table.insert(replayHistory, {
		eventType = eventType, 
		timestamp = tick()-replayRecordingStartTime,
		data = data
	})
end


-- create the whiteboard events and set up the callbacks
local function createEvent(eventName)
	local event = game.ReplicatedStorage:findFirstChild(eventName)
	if event == nil then
		event = Instance.new("RemoteEvent")
		event.Name = eventName
		event.Parent = game.ReplicatedStorage
	end
	return event
end

createEvent("WhiteboardActivateEvent")
createEvent("WhiteboardDeactivateEvent")

-- DM 21/3/21 start
local screenFrameHeight = guiFolder.ScreenBoard.Frame.Board.AbsoluteSize.Y
local whiteboardStorageFolder = game.ReplicatedStorage:findFirstChild("metauni_whiteboard")

if not whiteboardStorageFolder then
	local f = Instance.new("Folder")
	f.Name = "metauni_whiteboard"
	f.Parent = game.ReplicatedStorage
	whiteboardStorageFolder = f
end

local Z_OFFSET_PER_CURVE = 0.002

local function getWorldFolder(name)
	local wFolder = whiteboard.WorldLines:findFirstChild(name)
	if not wFolder then
		wFolder = Instance.new("Folder")
		wFolder.Name = name
		wFolder.Parent = whiteboard.WorldLines
	end

	return wFolder
end

local function relativeToAbsoluteWorld(coords, boardPart, curveIndex)
	return boardPart.CFrame * CFrame.new(-boardPart.Size.X/2 + coords.X * boardPart.Size.X, 
		-boardPart.Size.Y/2 + coords.Y * boardPart.Size.Y, -boardPart.Size.Z/2 - Z_OFFSET_PER_CURVE * curveIndex)
end
-- DM end

local function drawWorldLine(name, curveIndex, prevMousePos, mousePos, thickness, color)
	-- DM 29/4/21
	-- draw the line as a part in the world
	local worldFolder = getWorldFolder(name .. tostring(curveIndex))
	local boardPart = whiteboard.WhiteboardModel.Board
	local worldLineVec = (mousePos-prevMousePos)*Vector2.new(boardPart.Size.X, boardPart.Size.Y)
	local worldRotation = math.atan2(worldLineVec.Y, worldLineVec.X)

	local wThickness = (thickness / screenFrameHeight) * boardPart.Size.Y

	local worldLine = Instance.new("Part")
	worldLine.Size = Vector3.new(worldLineVec.Magnitude+wThickness, wThickness, 0.01)
	worldLine.CFrame = relativeToAbsoluteWorld((mousePos+prevMousePos)/2, boardPart, curveIndex)
	worldLine.CFrame = worldLine.CFrame * CFrame.Angles(0,0,worldRotation)
	worldLine.Color = color
	worldLine.Anchored = true
	worldLine.CanCollide = false
	worldLine.CastShadow = false
	worldLine.Parent = worldFolder
	-- end DM
	
	--Billy
	worldLine:SetAttribute("RelStart", prevMousePos)
	worldLine:SetAttribute("RelStop", mousePos)
end

local drawEvent = createEvent(whiteboard.Name .. "DrawEvent")
drawEvent.OnServerEvent:Connect(function(client, name, curveIndex, prevMousePos, mousePos, thickness, color)
	drawEvent:FireAllClients(name, curveIndex, prevMousePos, mousePos, thickness, color)
	drawWorldLine(name, curveIndex, prevMousePos, mousePos, thickness, color)
	addToReplayHistory("draw", {name, curveIndex, prevMousePos.X, prevMousePos.Y, mousePos.X, mousePos.Y, thickness, color.R, color.G, color.B})
end)

local cursorEvent = createEvent(whiteboard.Name .. "CursorEvent")
cursorEvent.OnServerEvent:Connect(function(client, name, mousePos, thickness, color)
	cursorEvent:FireAllClients(name, mousePos, thickness, color)
	
	--if mousePos ~= nil then
		--addToReplayHistory("cursor", {name, mousePos.X, mousePos.Y, thickness, color.R, color.G, color.B})
	--end
	
end)

local undoEvent = createEvent(whiteboard.Name .. "UndoEvent")
undoEvent.OnServerEvent:Connect(function(client, name, curveIndex)
	undoEvent:FireAllClients(name, curveIndex)
	
	local worldFolder = getWorldFolder(name .. tostring(curveIndex)) -- DM 21/3/21
	worldFolder:Destroy() -- DM 21/3/21
	
	addToReplayHistory("undo", {name, curveIndex})
end)

local clearEvent = createEvent(whiteboard.Name .. "ClearEvent")
clearEvent.OnServerEvent:Connect(function(client)
	clearEvent:FireAllClients()
	
	whiteboard.WorldLines:ClearAllChildren() -- DM 21/3/21
	
	addToReplayHistory("clear", nil)
end)

--Billy

local function eraseWorldLine(start, stop)

	for _, stroke in ipairs(whiteboard.WorldLines:GetChildren()) do
		for _, line in ipairs(stroke:GetChildren()) do

			local relStart = line:GetAttribute("RelStart")
			local relStop = line:GetAttribute("RelStop")

			if relStart == start and relStop == stop then
				line.Parent = nil

				return
			end

		end
	end	
end

local eraseEvent = createEvent(whiteboard.Name .. "EraseEvent")
eraseEvent.OnServerEvent:Connect(function(client, name, start, stop)
	eraseEvent:FireAllClients(name, start, stop)
	addToReplayHistory("erase", {name, start, stop})
	eraseWorldLine(start, stop)
end)

--local historyEvent = createEvent(whiteboard.Name .. "HistoryEvent")
--historyEvent.OnServerEvent:Connect(function(client)
--	local numLines = 0
--	for _, event in pairs(replayHistory) do
--		if event.eventType == "draw" then
--			local data = event.data
--			drawEvent:FireClient(client, data[1], data[2], data[3], data[4], data[5], data[6])
--			numLines = numLines+1
--			if numLines > 64 then
--				numLines = 0
--				wait() 
--			end
--		elseif event.eventType == "undo" then
--			local data = event.data
--			undoEvent:FireClient(client, data[1], data[2])
--		end
--	end
--end)

local replayRecordingStartEvent = createEvent(whiteboard.Name .. "ReplayRecordingStartEvent")
replayRecordingStartEvent.OnServerEvent:Connect(function(client)
	print("Starting whiteboard replay recording.")
	
	replayRecordingActive = true
	replayRecordingStartTime = tick()
	replayPlaybackActive = false -- recording and playback can't be active at same time
	
	--clear the replay history
	replayHistory = {}
end)

local replayRecordingStopEvent = createEvent(whiteboard.Name .. "ReplayRecordingStopEvent")
replayRecordingStopEvent.OnServerEvent:Connect(function(client)
	print("Stopping whiteboard replay recording.")
	replayRecordingActive = false
end)

local replayPlaybackStartEvent = createEvent(whiteboard.Name .. "ReplayPlaybackStartEvent")
replayPlaybackStartEvent.OnServerEvent:Connect(function(client)
	print("Starting whiteboard replay playback.")
	replayPlaybackStartTime = tick()
	replayPlaybackActive = true
	replayPlaybackIndex = 1
	replayRecordingActive = false -- recording and playback can't be active at same time
	replaySound.Playing = true -- DM 24/4/21
end)

local replayPlaybackStopEvent = createEvent(whiteboard.Name .. "ReplayPlaybackStopEvent")
replayPlaybackStopEvent.OnServerEvent:Connect(function(client)
	print("Stopping whiteboard replay playback.")
	replayPlaybackActive = false
	replaySound.Playing = false -- DM 24/4/21
end)

local replaySaveEvent = createEvent(whiteboard.Name .. "ReplaySaveEvent")
replaySaveEvent.OnServerEvent:Connect(function(client, replayName)
	print("Saving replay to data store, replayName = " .. replayName)
	
	local replayJSON = httpService:JSONEncode(replayHistory)
	replayDataStore:SetAsync(replayName, replayJSON)
	
	replayPlaybackActive = false
	replayRecordingActive = false
end)

local replayLoadEvent = createEvent(whiteboard.Name .. "ReplayLoadEvent")
replayLoadEvent.OnServerEvent:Connect(function(client, replayName)
	print("Loading replay from data store, replayName = " .. replayName)
	
	local replayJSON = replayDataStore:GetAsync(replayName)
	replayHistory = httpService:JSONDecode(replayJSON)
	
	replayPlaybackActive = false
	replayRecordingActive = false
end)

local replayEndEvent = createEvent(whiteboard.Name .. "ReplayEndEvent")

runService.Heartbeat:Connect(function(dt)
	if not replayPlaybackActive then return end
	
	if replayPlaybackIndex >= #replayHistory then
		replayPlaybackActive = false
		replayEndEvent:FireAllClients()
		return
	end
	
	local replayTime = (tick() - replayPlaybackStartTime)*replayPlaybackSpeed
	while replayPlaybackIndex < #replayHistory do
		local event = replayHistory[replayPlaybackIndex]
		if event.timestamp < replayTime then
			if event.eventType == "draw" then
				local data = event.data
				drawEvent:FireAllClients(
					"replay_" .. data[1], 
					data[2], 
					Vector2.new(data[3], data[4]), 
					Vector2.new(data[5], data[6]),
					data[7],
					Color3.new(data[8], data[9], data[10])
				)
				drawWorldLine(
					"replay_" .. data[1], 
					data[2], 
					Vector2.new(data[3], data[4]), 
					Vector2.new(data[5], data[6]),
					data[7],
					Color3.new(data[8], data[9], data[10])
				)
			elseif event.eventType == "cursor" then
				local data = event.data
				cursorEvent:FireAllClients(
					data[1] .. " (replay)",
					Vector2.new(data[2], data[3]),
					data[4],
					Color3.new(data[5], data[6], data[7])
				)
			elseif event.eventType == "undo" then
				local data = event.data
				undoEvent:FireAllClients("replay_" .. data[1], data[2])
				local worldFolder = getWorldFolder(data[1] .. tostring(data[2])) -- DM 21/3/21
				worldFolder:Destroy() -- DM 21/3/21
			elseif event.eventType == "clear" then
				local data = event.data
				clearEvent:FireAllClients()
				whiteboard.WorldLines:ClearAllChildren() -- DM 21/3/21
			elseif event.eventType == "erase" then
				local data = event.data
				eraseEvent:FireAllClients(data[1], data[2], data[3])
				eraseWorldLine(data[2], data[3])
			end
			replayPlaybackIndex = replayPlaybackIndex+1
		else 
			return 
		end
	end
end)

--- spiel events 24/4/21
-- DM 24/4/21
local spielLoaded = false
local spielName = whiteboard.Config.SpielName.Value

local spielPlayEvent = createEvent(whiteboard.Name .. "SpielPlayEvent")
spielPlayEvent.OnServerEvent:Connect(function(client)
	if spielName == "" then return end
	
	if not spielLoaded then
		print("Loading replay from data store, replayName = " .. spielName)

		local replayJSON = replayDataStore:GetAsync(spielName)
		replayHistory = httpService:JSONDecode(replayJSON)
		spielLoaded = true
		replayPlaybackStartTime = tick()
		replayPlaybackIndex = 1
		replayRecordingActive = false -- recording and playback can't be active at same time
	end
	
	print("Starting whiteboard replay playback.")
	replayPlaybackActive = true
	replaySound.Playing = true -- DM 24/4/21
	
	-- if we were paused, skip ahead
	if replayPauseTime ~= 0 then
		replayPlaybackStartTime = replayPlaybackStartTime + tick() - replayPauseTime
		replayPauseTime = 0
	end
	
	spielPlayEvent:FireAllClients()
end)

local spielPauseEvent = createEvent(whiteboard.Name .. "SpielPauseEvent")
spielPauseEvent.OnServerEvent:Connect(function(client)
	if spielName == "" then return end
	
	print("Pausing whiteboard replay playback.")
	replayPlaybackActive = false

	replayPauseTime = tick()
	replaySound.Playing = false -- DM 24/4/21
	
	spielPauseEvent:FireAllClients()
end)
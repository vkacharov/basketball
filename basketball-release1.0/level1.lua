-----------------------------------------------------------------------------------------
--
-- level1.lua
--
-----------------------------------------------------------------------------------------
local widget = require( "widget" )

local storyboard = require( "storyboard" )
local scene = storyboard.newScene()

local gravity = 32
local positiveGravity = true
-- include Corona's "physics" library
local physics = require "physics"
physics.start()
--physics.setDrawMode( "debug" )
physics.setGravity( 0, gravity)


local session = require("session")
local persistence = require("persistence")
--------------------------------------------

-- forward declarations and other locals
local screenW, screenH, halfW = display.contentWidth, display.contentHeight, display.contentWidth*0.5

print(screenW, screenH)
-----------------------------------------------------------------------------------------
-- BEGINNING OF YOUR IMPLEMENTATION
-- 
-- NOTE: Code outside of listener functions (below) will only be executed once,
--		 unless storyboard.removeScene() is called.
-- 
-----------------------------------------------------------------------------------------

--[[
local i = 0

local monitorMem = function()
	i = i + 1
	if(i % 100 == 0) then 
		collectgarbage()
		print( "MemUsage: " .. collectgarbage("count") )
		 
		local textMem = system.getInfo( "textureMemoryUsed" ) / 1000000
		print( "TexMem: " .. textMem )
	end
end
--Runtime:addEventListener( "enterFrame", monitorMem )

]]--

local backed = false

local function printTable(table, stringPrefix)
	if not stringPrefix then
		stringPrefix = "### "
	end
	if type(table) == "table" then
		for key, value in pairs(table) do
			if type(value) == "table" then
				print(stringPrefix .. tostring(key))
				print(stringPrefix .. "{")
				printTable(value, stringPrefix .. "   ")
				print(stringPrefix .. "}")
			else
				print(stringPrefix .. tostring(key) .. ": " .. tostring(value))
			end
		end
	end
end

local function newRound(number) 
	local newRound = {chosenChallenges={basket=true}, achievedChallenges={}, started=false, number=number, scored=false}
	return newRound
end
local round = newRound(1)

local stage = {
	bottomH = 60,
	sideH = 3,
	ballRadius = 18,
	positiveGravity = true,
	ball = nil,
	hugeBallRadius=25,
	audio={}
}

local currentChallenge = nil

local pointsCount = 0
local tableView = nil

local function revertGravity() 
	stage.top.isSensor = false
	stage.ball.isAwake = true
	round.chosenChallenges["top"] = nil
	round.chosenChallenges["space"] = nil
	physics.setGravity(0, -gravity)
	stage.positiveGravity = false
end

local function restoreGravity()
	stage.top.isSensor = true
	stage.ball.isAwake = true
	physics.setGravity(0, gravity)
	stage.positiveGravity = true
end

local function restoreBlackout()
	transition.to(stage.blackout, {time=400, alpha = 0})
	stage.ringFront:toFront()
end

local function doBlackout()
	transition.to(stage.blackout, {time=400, alpha = 1})
	stage.ringFront:toBack()
end

local function doHugeBall()
	physics.removeBody(stage.ball)
	transition.to(stage.ball, {time=500, width = 2 * stage.hugeBallRadius, height = 2 * stage.hugeBallRadius})
	transition.to(stage.shadow, {time=500, width = 2 * stage.hugeBallRadius, height = 2 * stage.hugeBallRadius})
	physics.addBody( stage.ball, { density=0.9, friction=0.9, bounce=0.6, radius=stage.hugeBallRadius, filter=stage.ballCollisionFilter } )
	stage.ball.angularDamping = 1
	stage.ball.huge = true
end

local function restoreHugeBall()
	physics.removeBody(stage.ball)
	transition.to(stage.ball, {time=500, width = 2 * stage.ballRadius, height = 2 * stage.ballRadius})
	transition.to(stage.shadow, {time=500, width = 2 * stage.ballRadius, height = 2 * stage.ballRadius})
	physics.addBody( stage.ball, { density=0.9, friction=0.9, bounce=0.6, radius=stage.ballRadius, filter=stage.ballCollisionFilter } )
	stage.ball.angularDamping = 1
	stage.ball.huge = false
end

local function cancelGravity()
	round.chosenChallenges["gravity"] = nil
	restoreGravity()
end

local challenges = {
	basket = {required= 0, id="basket", name="basket", points=1, default=true, simple=true, strict=true},
	top = {required= 0, id="top", name="sky shot", points=1, chosenListener=cancelGravity},
	left = {required= 0, id="left", name="left wall", points=2, strict=true},
	bottom = {required= 10, id="bottom", name = "bottom", points=2, strict=true},
	right = {required= 35, id="right", name="right wall", points=3, strict=true},
	gravity = {required= 75, id="gravity", name= "revert gravity" , points=3, chosenListener=revertGravity, unchosenListener=restoreGravity, simple = true, strict=true, 
		},
	space = {required = 110, id="space", name = "space shot", points = 3, chosenListener=cancelGravity},
	blackout = {required= 150, id="blackout", name="blackout", points=3, chosenListener=doBlackout, unchosenListener=restoreBlackout, roundStartedListener=restoreBlackout,
		simple=true, strict=true},
	hugeBall = {required= 200, id="hugeBall", name="huge ball", points=4, chosenListener=doHugeBall, unchosenListener=restoreHugeBall, simple=true, strict=true}
}

local unlockedChallenges = {}
local nextChallenge = nil
local challengeBeeps = {}

local function unlockChallenges(points)
	local unlocked = {}
	local mChallenge = nil
	for id,challenge in pairs(challenges) do 
		if(challenge.required <= points) then
			unlocked[id] = challenge
		else
			if(not mChallenge or mChallenge.required > challenge.required) then
				mChallenge = challenge
			end
		end
	end
	
	unlockedChallenges = unlocked
	nextChallenge = mChallenge
	unlocked = nil
	mChallenge = nil
end

local function deBeep(obj) 
	obj.x, obj.alpha = obj.x0, 0
end

local function reBeep(obj)
	transition.to(obj, {time=200, alpha=0, x=obj.x + 60, onComplete=deBeep})
end

local function beep(challengeId)
	local txt = challengeBeeps[challengeId]
	if(txt and not txt.beeped) then
		txt.beeped = true
		transition.to(txt, {time=200, alpha=1, x=txt.x + 30, onComplete=reBeep,})
	end
	txt= nil
end

local counter = nil
local rounder = nil
local moder = nil
local totaler = nil
local bester = nil

local function updateRoundInfo()
	counter.text = pointsCount
	rounder.text.text = round.number
end

local function deRound(obj)
	transition.to(rounder.group, {time=200, xScale=1, yScale=1, y= rounder.group.initY})
end

local function reRound()
	transition.to(rounder.group, {time=200, xScale=2, yScale=2, y= rounder.group.y - 40, onComplete=deRound})
end

local function hideChallenges(sideGroup) 
		
		transition.to(sideGroup, {x=tableView.tableHideX, time=600, transition = easing.outExpo})
		tableView.expanded = false
		currentChallenge.mode:resume()
end

local function onRoundStarted()
	round.started = true

	for challengeId,v in pairs(round.chosenChallenges) do
		if(challenges[challengeId].roundStartedListener) then
			challenges[challengeId].roundStartedListener()
		end
	end
end

function dragBody( event, params )
	local body = event.target
	local phase = event.phase
	local displayStage = display.getCurrentStage()
	if(round.started) then
		return
	end
	
	if "began" == phase then
		stage.forbiddenGroup.alpha = 0
		displayStage:setFocus( body, event.id )
		body.isFocus = true
		if(not body.tempJoint) then
			body.tempJoint = physics.newJoint( "touch", body, body.x, body.y )
		end
		if(tableView.expanded) then
			hideChallenges(stage.sideGroup)
		end

	elseif body.isFocus then
		if "moved" == phase then
			body.tempJoint:setTarget( event.x, event.y )
						
		elseif "ended" == phase or "cancelled" == phase then
			displayStage:setFocus( body, nil )
			body.isFocus = false
			if(
				(body.x <= stage.forbiddenZone.fromLeft or event.x < stage.forbiddenZone.fromLeft)
				or	body.y >= stage.forbiddenZone.fromTop 
				or (body.y <= stage.forbiddenZone.fromBottom or event.y < stage.forbiddenZone.fromBottom)
				) then 
				body.tempJoint:removeSelf()
				body.tempJoint = nil
				stage.forbiddenGroup.alpha = 0			
				onRoundStarted()

			else
				stage.forbiddenGroup.alpha = 1
			end
		end
	end

	-- Stop further propagation of touch event
	return true
end

local function onRingCollision(self, event) 
	
	if(not round.started) then
		return 
	end
	
	if(event.phase == "began") then
		if(self.y > event.other.y) then
			self.otherOverOnBegin = true
		end
	elseif(event.phase == "ended") then 
		if(self.y < event.other.y and self.otherOverOnBegin) then
			print("BASKET")
			for challengeId,v in pairs(round.chosenChallenges) do
				if(challenges[challengeId].simple) then
					round.achievedChallenges[challengeId] = true
					beep(challengeId)
				end
			end
			round.scored = true
		end
		self.otherOverOnBegin = false
	end
end

local function onAerialCollision(self, event) 
	if(not round.started or round.scored) then
		return
	end
	
	if(event.phase == "ended") then
	--	print("AERIAL", self.challengeId)
		local ball = event.other
		if(ball.y < self.y) then
			local challenge = challenges[self.challengeId]
			round.achievedChallenges[challenge.id] = true
			beep(challenge.id)
			challenge = nil
		end
	end
	
	return true
end

local function onFrameCollision(self, event) 
	if(not round.started or round.scored) then
		return
	end
	
	if(event.phase == "ended") then
		local challenge = challenges[self.challengeId]
		round.achievedChallenges[challenge.id] = true
		beep(challenge.id)
		challenge = nil
	end
	
	return true
end

local function updateBester(points, rounds)
	bester.text = tostring(points) .. " / " .. tostring(rounds)
end

local function updatePlayer(roundPoints) 
	local player = session.player
	player.points = player.points + roundPoints
	totaler.text = player.points
	session.dirty = true
end

local function updateBest(points)
	local player = session.player
	local best = player.results[currentChallenge.mode.key].score
	if(points > best) then
		player.results[currentChallenge.mode.key].score = points
		player.results[currentChallenge.mode.key].rounds = round.number
		updateBester(points, round.number)
		session.dirty = true
	end
end

local function endRound(round) 
	round.started = false
	local roundScore = 0
	local achieved = true
	
	-- check whether round.achievedChallenges and round.chosenChallenges contain the same values
	for challengeId,v in pairs(round.chosenChallenges) do
		roundScore = roundScore + challenges[challengeId].points
		if(not round.achievedChallenges[challengeId]) then
			achieved = false
			break
		end
	end
	
	if(achieved) then
		for challengeId,v in pairs(round.achievedChallenges) do
			if(not round.chosenChallenges[challengeId] and challenges[challengeId].strict ) then
				achieved = false
				break
			end
		end
	end
	
	if(achieved) then	
		pointsCount = pointsCount + roundScore
		updatePlayer(roundScore)
	end

	print(tostring(round.number) .. " : " .. tostring(pointsCount))
	
end

local function dzoneCollision(self, event)
	if(event.phase == "began") then 
		
	elseif (event.phase == "ended") then
		self.objectToHide.alpha = 1
	end
end

local function onRowRender( event )
    -- Get reference to the row group
    local row = event.row
	local challenge = event.row.params.challenge
	local size = 16
	local isNext = event.row.params.isNext
	
	local x,y = 0, 0
    -- Cache the row "contentWidth" and "contentHeight" because the row bounds can change as children objects are added
    local rowHeight = row.contentHeight
    local rowWidth = row.contentWidth

	--printTable(challenge)
	local txt = nil
	if(isNext) then
		txt = "next : " .. tostring(challenge.required - session.player.points) .. " pts left"
	else
		txt = challenge.name .. " " .. tostring(challenge.points) .. "+"
	end
	
    local rowTitle = display.newText( {parent=row, text=txt, x=x, y=y, font=native.systemFontBold, fontSize=size} )

	rowTitle:setFillColor( 1, 1, 1 )

    -- Align the label left and vertically centered
    rowTitle.anchorX = 0
    rowTitle.x = 10
    rowTitle.y = rowHeight * 0.5
end

local function populateChallengesTable()
	tableView:deleteAllRows()

	for challengeId,v in pairs(round.chosenChallenges) do
		tableView:insertRow{
			params={challenge=challenges[challengeId]}, 
			rowColor = { default={ .5, 0, 0, 0.5},
			rowHeight = tableView.height / 3,	
			}
		}
	
	end

	for k,challenge in pairs(unlockedChallenges) do
		if(not round.chosenChallenges[challenge.id]) then 
			tableView:insertRow{
				params={challenge=challenge}, 
				rowColor = { default={ 0, 0, 0, 0.5},
				rowHeight = tableView.contentHeight / 3
				}
			}
		end
	end
	
	if(nextChallenge) then
	
		tableView:insertRow{
			params={challenge=nextChallenge, isNext=true}, 
			rowColor = { default={ 0, 0, 0, 0.4},
			rowHeight = tableView.height / 3,	
			}
	}
	end
	tableView:scrollToIndex(1)
end

local function onRowTouch(event) 
	if(not round.started and event.phase == "release") then
		local challenge = event.target.params.challenge
		if(not unlockedChallenges[challenge.id]) then			
			return 
		end
		
		if(round.chosenChallenges[challenge.id]) then
			if(not challenge.default) then 
				round.chosenChallenges[challenge.id] = nil
				if(challenge.unchosenListener) then
					challenge.unchosenListener()
				end
			end
		else
			round.chosenChallenges[challenge.id] = true
			if(challenge.chosenListener) then
				challenge.chosenListener()
			end
		end
		
		populateChallengesTable()
	end
end

function cleanAfterRound()
	 restoreGravity()
	 restoreBlackout()
	 if(stage.ball.huge) then
		restoreHugeBall()
	 end
	 for k,txt in pairs(challengeBeeps) do 
		txt.beeped = false
	 end
end

function toggleChallenges(event)
	
	if(not round.started) then 
		if(not tableView.expanded) then
			transition.to(stage.sideGroup, {x = tableView.tableExpandX, time=600, transition = easing.outExpo})
			tableView.expanded = true
			currentChallenge.mode:pause()
		else
			hideChallenges(stage.sideGroup)
		end
	end

end

local function challengeCompleteListener(event)
	if "clicked" == event.action then
		round = newRound(1)
		pointsCount = 0
		updateRoundInfo()
		cleanAfterRound()
		populateChallengesTable()
		local i = event.index
		if(i == 1) then 
			currentChallenge.ended = false
			currentChallenge.mode:onStageBegin(moder)
			physics.start()
		else
			storyboard.gotoScene( "menu", "fade", 500 )
		end
		backed = false
	end
	
end

local function onChallengeComplete(hideAlert)
	if(not currentChallenge.ended) then
		currentChallenge.ended = true
		physics.pause()
		currentChallenge.mode:finish()
		updateBest(pointsCount)
		persistence.updatePlayer(session.player)
		session.dirty = false
		if(not hideAlert) then
			native.showAlert("Game Completed", "Your score is " .. tostring(pointsCount), {"Retry", "Menu"}, challengeCompleteListener)
		else
			challengeCompleteListener({action="clicked", index=2})
		end
	end
end

local function endButtonListener(event)
	if(event.index == 1) then
		onChallengeComplete()
	elseif (event.index == 2) then
		currentChallenge.mode:resume()
	end
end

local function onEndButtonReleased(event)
	currentChallenge.mode:pause()
	onChallengeComplete(event.hideAlert)
end

local function createBottomButton(text, label, buttonData)
	local group = display.newGroup()
	local labelText = display.newText({text=label, x=0, y=0,font=native.systemFontBold, fontSize=12})
	labelText.y = -labelText.height/2 - 1
	

	local textText = nil
	
	if(buttonData) then 
		textText = widget.newButton({label=text, x=0, y=0, font=native.systemFontBold, fontSize=16, 
		labelColor = { default={ 1, 1, 1 },  over={ 1, 1, 1 } }, textOnly=true, onRelease=buttonData.onRelease})
	else
		textText = display.newText({text=text, x=0, y=0, font=native.systemFontBold, fontSize=16})
	end
	textText.y = textText.height / 2 + 1
	
	local width = textText.width + 5
	
	if(labelText.width > width) then width = labelText.width + 5 end
	local labelB = display.newRect(labelText.x, labelText.y, width, labelText.height)
	labelB:setFillColor(0.6)
	
	local textB = display.newRect(textText.x, textText.y, width, textText.height)
	textB:setFillColor(0.5, 0, 0, 0.6)
	
	group:insert(labelText)
	group:insert(labelB)
	group:insert(textText)
	group:insert(textB)
	labelText:toFront()
	textText:toFront()
	
	group.x, group.y = 0
	return {group = group, text=textText, label=labelText}
end

local function pauseAudio(button)
	audio.pause(stage.audio.beatChannel)
end

local function resumeAudio(button)
	audio.resume(stage.audio.beatChannel)
end

local function switchAudio(event)
	if(event.phase == "ended") then
		if(stage.audio.beatChannel) then
			if(audio.isChannelPlaying(stage.audio.beatChannel)) then
				pauseAudio(event.target)
			else
				resumeAudio(event.target)
			end
			
			event.target.isVisible = false
			event.target.other.isVisible = true
			stage.audio.nextAudio.isVisible = not stage.audio.nextAudio.isVisible
		end
	end
end

local function loadAudio()
	local beats = {"audio/beat1.mp3", "audio/beat2.mp3", "audio/beat3.mp3", }
	stage.audio.beatSounds = {}
	for i,b in pairs(beats) do
		stage.audio.beatSounds[i] = audio.loadSound(b)
	end
end

local function forwardAudio(event)
	if(event.phase == "ended") then
		stage.audio.currentBeat =  stage.audio.currentBeat  + 1
		if(stage.audio.currentBeat > #stage.audio.beatSounds) then 
			stage.audio.currentBeat = 1
		end
		
		if(stage.audio.beatChannel) then
			audio.stop(stage.audio.beatChannel)
			stage.audio.beatChannel = audio.play(stage.audio.beatSounds[stage.audio.currentBeat], {fadein=1000, loops=-1})
		end
	end
end

-- Called when the scene's view does not exist:
function scene:createScene( event )
	local group = self.view
	
	local player = session.player
	unlockChallenges(player.points)

	-- create a grey rectangle as the backdrop
	local background = display.newImageRect( "bgr.jpg", screenW, screenH )
	background.anchorX = 0
	background.anchorY = 0
	
	stage.ball = display.newImageRect("basketball.png", stage.ballRadius * 2, stage.ballRadius * 2)
	stage.ball.x, stage.ball.y = 160, 30

		-- add physics to the stage.ball
	stage.ballCollisionFilter={categoryBits=2, maskBits=1}
	
	physics.addBody( stage.ball, { density=0.9, friction=0.9, bounce=0.6, radius=stage.ballRadius, filter=stage.ballCollisionFilter } )
	stage.ball.angularDamping = 1
	-- create a frame object and add physics 
	local frameCollisionFilter = {categoryBits=1, maskBits=2}
	
	local bottom = display.newRect(0, 0, screenW, stage.bottomH)
	bottom.anchorX = 0
	bottom.anchorY = 1
	bottom.x, bottom.y = 0, display.contentHeight
	bottom.challengeId=challenges.bottom.id
	bottom:setFillColor(1, 1, 1, 0)
	physics.addBody( bottom, "static", { friction=1, filter=frameCollisionFilter} )
	bottom.collision = onFrameCollision
	bottom:addEventListener("collision", bottom)
	
	local right = display.newRect(0, 0, stage.sideH, 20 * screenH)
	right.x, right.y = screenW, - right.height / 2 + screenH
	physics.addBody(right, "static", {friction=0.2, filter=frameCollisionFilter})
	right.collision = onFrameCollision
	right:addEventListener("collision", right)
	right.challengeId = challenges.right.id
	
	local left = display.newRect(0, 0, stage.sideH, 20 * screenH)
	left.x, left.y = 0, - left.height / 2 + screenH
	physics.addBody(left, "static", {friction=0.2, filter=frameCollisionFilter})
	left.challengeId = challenges.left.id
	left.collision = onFrameCollision
	left:addEventListener("collision", left)
	
	local top = display.newRect(0, 0, screenW, stage.sideH * 4)
	top.x, top.y = halfW, 0
	top.challengeId = challenges.top.id
	physics.addBody(top, "static", {friction=0.2, filter=frameCollisionFilter, isSensor=true})
	top.collision = onAerialCollision
	top:addEventListener("collision", top)
	stage.top = top
	
	local space = display.newRect(0, 0, screenW, stage.sideH * 4)
	space.x, space.y = halfW, - 70
	space.challengeId = challenges.space.id
	physics.addBody(space, "static", {friction=0.2, filter=frameCollisionFilter, isSensor=true})
	space.collision = onAerialCollision
	space:addEventListener("collision", space)
	-- end frame 
	
	local board = display.newRect(0, 0, 8, 80)
	board:setFillColor(.5, 0)
	board.x, board.y = screenW - 40, 55
	physics.addBody(board, "static", {friction=0.2})
	
	local boardRoundedTop = display.newCircle(board.x, board.y - board.height/2 - 1, board.width / 2)
	boardRoundedTop:setFillColor(.5, 0)
	physics.addBody(boardRoundedTop, "static", {radius=boardRoundedTop.width / 2})
	
	local ringOffsetX, ringOffsetY = 10, 10
	local ringWidth = stage.ballRadius * 4 - 5
	-- TODO attach the ring to the board with weld joint
	local ringRadius = 3
	local ringStart = display.newCircle(0, 0, ringRadius)
	ringStart:setFillColor(1, 0 , 0 , 0)
	ringStart.x, ringStart.y = board.x - ringWidth - ringOffsetX, board.y + board.height / 2 - ringOffsetY
	physics.addBody(ringStart, "static", {radius=ringRadius, friction=0.2})

	local ringEnd = display.newCircle(0, 0, ringRadius)
	ringEnd:setFillColor(.5, 0)
	ringEnd.x , ringEnd.y = board.x- ringOffsetX, board.y + board.height / 2 - ringOffsetY
	physics.addBody(ringEnd, "static", {radius=ringRadius, friction=0.2})
	
	local ringPlank = display.newRect(0, 0, ringOffsetX, 3)
	ringPlank.x, ringPlank.y = ringEnd.x + ringOffsetX / 2 , ringEnd.y
	ringPlank:setFillColor(.5, 0)
	physics.addBody(ringPlank, "static")
	
	local ringFront = display.newImageRect( "riring.png", 70, 11 )
	ringFront.x, ringFront.y = ringStart.x + 2 * stage.ballRadius - 4, ringEnd.y + 8
	stage.ringFront = ringFront
	
	local ringSensor = display.newRect(0, 0, ringWidth - 4 * ringRadius, 1)
	ringSensor.x, ringSensor.y = ringStart.x +ringWidth / 2 + ringRadius / 2, ringStart.y
	physics.addBody(ringSensor, "static", {isSensor=true})
	ringSensor.collision = onRingCollision
	ringSensor:addEventListener("collision", ringSensor)
	ringSensor:setFillColor(1, 1, 1, 0)
	
	local topGroup = display.newGroup()
		
	local chal = createBottomButton("Tricks", "show", {onRelease=toggleChallenges})
	local challengesButton = chal.text
	topGroup:insert(chal.group)	
	
	local cou = createBottomButton(tostring(pointsCount), "points")
	counter = cou.text
	cou.group.x = chal.group.x + chal.group.width / 2 + cou.group.width / 2 + 2
	topGroup:insert(cou.group)
	
	local rou = createBottomButton(tostring(round.number), "round")
	rou.group.initY = rou.group.y
	rounder = rou
	rou.group.x = cou.group.x + cou.group.width / 2 + rou.group.width /2 +  2
	topGroup:insert(rou.group)
	
	local bou = createBottomButton("999 / 999", "best")
	bester = bou.text
	bou.group.x = rou.group.x + rou.group.width / 2 + bou.group.width / 2 + 2
	topGroup:insert(bou.group)
	
	local mou = createBottomButton("       ", "remaining")
	moder = mou.text
	mou.group.x = bou.group.x + bou.group.width / 2 + mou.group.width / 2 + 2
	topGroup:insert(mou.group)
	
	local pou = createBottomButton(tostring(player.points), "total")
	totaler = pou.text
	pou.group.x = mou.group.x + mou.group.width / 2 + pou.group.width /2 + 2
	topGroup:insert(pou.group)
	
	local eou = createBottomButton("Game", "end", {onRelease=onEndButtonReleased})
	eou.group.x = pou.group.x + pou.group.width / 2 + eou.group.width / 2 + 2
	topGroup:insert(eou.group)
	
	topGroup.x, topGroup.y = screenW / 2 - topGroup.width / 2 , screenH - topGroup.height / 2 - 5
	
	local sideGroup = display.newGroup()
	sideGroup.top = stage.sideH
	local tableH = screenH - stage.sideH - topGroup.height - 40

	tableView = widget.newTableView(
	{
		x = 0,
		y = screenH / 2 + 8,
		height = tableH,
		width = 130,
		onRowRender = onRowRender,
		onRowTouch = onRowTouch,
		noLines=false,
		hideBackground=true,
		hideScrollBar=true
	})
	
	sideGroup:insert(tableView)
	tableView.tableExpandX = tableView.contentWidth / 2 + stage.sideH
	tableView.tableHideX = -tableView.contentWidth - stage.sideH
	tableView.expanded = false
	
	sideGroup.x = tableView.tableHideX
	
	stage.sideGroup = sideGroup

	
	local dangerZone = display.newRect(screenW / 2, topGroup.y , topGroup.width + 70, topGroup.height + 20)

	dangerZone:setFillColor(0, 0, 0, 0)
	dangerZone.objectToHide = topGroup
	physics.addBody(dangerZone, "static", {filter=frameCollisionFilter, isSensor=true})
	dangerZone.collision = dzoneCollision
	dangerZone:addEventListener("collision", dangerZone)
	
	
	local beepGroup = display.newGroup()
	
	local x0, y0, i = 50, 60, 0
	for challengeId, challenge in pairs(unlockedChallenges) do
		local txt = display.newText( challenge.name , x0, y0 + 30 * i, native.systemFontBold, 20 )
		txt:setFillColor(0, 0, 0, 1)
		txt.x0 = x0
		txt.alpha = 0
		challengeBeeps[challengeId] = txt
		beepGroup:insert(txt)
		txt = nil
		i = i + 1
	end
	
	background:addEventListener( "touch", 
		function(event)
			if(event.phase == "ended") then
				if(tableView.expanded) then
					hideChallenges(stage.sideGroup)
				else 
					if(event.x < 80) then
						toggleChallenges(event)
					end
				end
			end
		end
	)
	
	stage.group = group
	
	local shadow = display.newImageRect("shadow.png", stage.ballRadius * 2, stage.ballRadius * 2)
	shadow.alpha = 0.5
	shadow.x, shadow.y = stage.ball.x, screenH - stage.bottomH
	stage.shadow = shadow
	
	local forbiddenZoneGroup = display.newGroup()
	
	local fzoneHeight = 135
	local forbiddenZone = display.newRect(0, 0, 175, fzoneHeight + stage.ballRadius)
	forbiddenZone.x, forbiddenZone.y = screenW - forbiddenZone.width / 2, fzoneHeight / 2
	forbiddenZone:setFillColor(1, 0, 0, 0.1)

	forbiddenZone.fromLeft = screenW - forbiddenZone.width 
	forbiddenZone.fromTop = fzoneHeight
	forbiddenZone.fromBottom = -stage.ballRadius
	
	local forbiddenText = display.newText( {text="You cannot take a shot from the forbidden zone", x=display.contentCenterX, 
		y=display.contentCenterY, font=native.systemFontBold, fontSize=12} )
	forbiddenText:setFillColor(1, 0, 0)
	
	forbiddenZoneGroup:insert(forbiddenZone)
	forbiddenZoneGroup:insert(forbiddenText)
	forbiddenZoneGroup.alpha = 0
	stage.forbiddenZone = forbiddenZone
	stage.forbiddenGroup = forbiddenZoneGroup
	
	
	local blackout = display.newRect(0, 0, screenW + 20, screenH + 20)
	blackout:setFillColor(0, 0, 0, 1)
	blackout.alpha = 0
	blackout.x, blackout.y = screenW / 2, screenH / 2
	stage.blackout = blackout
	-- all display objects must be inserted into group
	group:insert(shadow)
	group:insert( background )
	group:insert( bottom)
	group:insert(right)
	group:insert(left)
	group:insert(top)
	group:insert(space)
	group:insert(stage.ball)
	group:insert(board)
	group:insert(boardRoundedTop)
	group:insert(ringStart)

	group:insert(ringEnd)
	group:insert(ringPlank)
	group:insert(beepGroup)
	group:insert(ringFront)

	group:insert(topGroup)
	group:insert(sideGroup)
	
	group:insert(blackout)
	if(dangerZone) then group:insert(dangerZone) end
	group:insert(forbiddenZoneGroup)
	
	forbiddenZoneGroup:toFront()
	stage.shadow:toFront()
	sideGroup:toFront()
	topGroup:toFront()
	stage.ball:toFront()
	ringFront:toFront()
	
	loadAudio()
end

local function onKeyEvent(event)

   local phase = event.phase
   local keyName = event.keyName
   
	if(keyName == "back") then
		if(backed) then
			return true
		end
		
		if(phase == "up") then
			event.hideAlert = true
			onEndButtonReleased(event, true)
			backed = true
		end
		return true
	end
   
   return false
end

local doNotCheck = true
-- Called immediately after scene has moved onscreen:
function scene:enterScene( event )
	local group = self.view
	backed = false
	
	local player = session.player
	--printTable(player)
	local mode = event.params.mode
	mode:onStageBegin(moder)
	mode.onChallengeComplete=onChallengeComplete
	
	currentChallenge = {mode = mode}
	
	updateBester(player.results[mode.key].score, player.results[mode.key].rounds)
	
	local delta = 20
	stage.deadZoneBoundary = screenH - stage.bottomH - stage.ballRadius - delta
	stage.negativeDeadZoneBoundary = stage.sideH + stage.ballRadius + delta
	local br = stage.ballRadius
	if(stage.ball.huge) then
		br = stage.hugeBallRadius
	end

	local gx, gy = physics.getGravity()
	function stage.ball:enterFrame()

		transition.to(stage.shadow, {x=self.x, time=0})
		doNotCheck = not doNotCheck
		if(not round.started or doNotCheck) then
			return
		end
		
		local vx, vy = self:getLinearVelocity()
		local x,y = self.x, self.y

	
		if(math.abs(vx) < 70 and math.abs(vy) < 50) then
			local br = stage.ballRadius
			if(stage.ball.huge) then
				br = stage.hugeBallRadius
			end
			
			local badZoneX = screenW - br - 5
			local badZoneY = 2 * br
			
			if 
				(
					stage.positiveGravity and (
						y > stage.deadZoneBoundary or
						(y > 0 and y < badZoneY and x > badZoneX)
					) or 
					(not stage.positiveGravity and 
						(y < stage.negativeDeadZoneBoundary or (x > badZoneX and y > 100 and y < 100 + br))
					)
				)
			 then
				round.started = false
				endRound(round)
				round = newRound(round.number + 1)
				updateRoundInfo()
				reRound()
				cleanAfterRound()
				
				local player = session.player
				
				if (nextChallenge and player.points >= nextChallenge.required) then
					persistence.updatePlayer(player)
					session.dirty = false
					native.showAlert("Congratulations", [[You have unlocked "]] .. nextChallenge.name .. [["]], {"OK"})
					unlockChallenges(player.points)
					
				end
				populateChallengesTable()
				
			end
			br = nil
			badZoneX = nil
			badZoneY = nil
		end
		vx = nil
		vy = nil
		y = nil
		x = nil
	end
	Runtime:addEventListener("enterFrame", stage.ball)	
	stage.ball:addEventListener( "touch", dragBody )
	
	populateChallengesTable()
	physics.start()
	
	local options = {
		width = 256,
		height = 256,
		numFrames = 3,

		sheetContentWidth = 768, 
		sheetContentHeight = 256
	}

	local imageSheet = graphics.newImageSheet( "soundsheet.png", options )
	
	local audioOn = display.newImageRect( imageSheet, 1, 20, 20 )
	audioOn.x, audioOn.y = screenW - 25, screenH - stage.bottomH 
	audioOn:addEventListener("touch", switchAudio)
	stage.audio.audioOn = audioOn
	
	local nextAudio = display.newImageRect( imageSheet, 3, audioOn.width, audioOn.height )
	nextAudio.x, nextAudio.y = audioOn.x - 25, audioOn.y
	nextAudio:addEventListener("touch", forwardAudio)
	stage.audio.nextAudio = nextAudio
	
	local audioOff = display.newImageRect( imageSheet, 2, audioOn.width, audioOn.height )
	audioOff.x, audioOff.y = audioOn.x, audioOn.y
	audioOff:addEventListener("touch", switchAudio)
	stage.audio.audioOff = audioOff
	audioOff.isVisible = false
	
	audioOn.other = audioOff
	audioOff.other = audioOn
	
	group:insert(audioOn)
	group:insert(audioOff)
	group:insert(nextAudio)
	
	stage.audio.currentBeat = 1
	stage.audio.beatChannel = audio.play( stage.audio.beatSounds[stage.audio.currentBeat] , {fadein=3000, loops=-1})
	
	Runtime:addEventListener( "key", onKeyEvent )
end

-- Called when scene is about to move offscreen:
function scene:exitScene( event )
	local group = self.view
	backed = false
	Runtime:removeEventListener("enterFrame", stage.ball)
	stage.ball:removeEventListener( "touch", dragBody )
	cleanAfterRound()
	challenge = nil
	physics.pause()
	if(session.dirty) then
		persistence.updatePlayer(session.player)
		session.dirty = false
	end
	
	audio.stop(stage.audio.beatChannel)
	
	if(stage.audio.audioOn) then 
		stage.audio.audioOn:removeSelf() 
		stage.audio.audioOn = nil
	end
	
	if(stage.audio.audioOff) then
		stage.audio.audioOff:removeSelf()
		stage.audio.audioOff = nil
	end

	if(stage.audio.nextAudio) then
		stage.audio.nextAudio:removeSelf()
		stage.audio.nextAudio = nil
	end
	
	Runtime:removeEventListener( "key", onKeyEvent )
end

-- If scene's view is removed, scene:destroyScene() will be called just prior to:
function scene:destroyScene( event )
	local group = self.view
	print("DESTROY")
	package.loaded[physics] = nil
	physics = nil
	
	package.loaded[persistence] = nil
	persistence = nil
	
	package.loaded[session] = nil
	session = nil
	
	package.loaded[widget] = nil
	widget = nil
	
	group:removeSelf()
	group = nil
	for k,b in pairs(stage.audio.beatSounds) do
		audio.dispose(b)
	end
	Runtime:removeEventListener( "key", onKeyEvent )
end

-----------------------------------------------------------------------------------------
-- END OF YOUR IMPLEMENTATION
-----------------------------------------------------------------------------------------

-- "createScene" event is dispatched if scene's view does not exist
scene:addEventListener( "createScene", scene )

-- "enterScene" event is dispatched whenever scene transition has finished
scene:addEventListener( "enterScene", scene )

-- "exitScene" event is dispatched whenever before next scene's transition begins
scene:addEventListener( "exitScene", scene )

-- "destroyScene" event is dispatched before view is unloaded, which can be
-- automatically unloaded in low memory situations, or explicitly via a call to
-- storyboard.purgeScene() or storyboard.removeScene().
scene:addEventListener( "destroyScene", scene )

-----------------------------------------------------------------------------------------

return scene
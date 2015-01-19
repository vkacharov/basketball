-----------------------------------------------------------------------------------------
--
-- menu.lua
--
-----------------------------------------------------------------------------------------

local storyboard = require( "storyboard" )
local scene = storyboard.newScene()

-- include Corona's "widget" library
local widget = require "widget"
local timeChallengeMode = require("timeChallengeMode")
local freeChallengeMode = require("freeChallengeMode")
local proxy = require("proxy")
local persistence = require("persistence")
local session = require("session")
--------------------------------------------

-- forward declarations and other locals
local timeChallengeBtn
local freePlayBtn
local helpBtn

-- 'onRelease' event listener for timeChallengeBtn
local function onTimeChallengeBtnRelease(event)
	local mode = timeChallengeMode:new({seconds=180, timerX=300, timerY=20})
	local options = {
		effect = "fade",
		time = 500,
		params = {
			mode=mode, 
		}
	}
	-- go to level1.lua scene
	storyboard.gotoScene( "loading", options )
	
	return true	-- indicates successful touch
end

local function onFreePlayBtnRelease(event)
	local mode =  freeChallengeMode:new()
	local modeProxy = proxy.get_proxy_for(mode)
	local options = {
		effect = "fade",
		time = 500,
		params = {
			mode=modeProxy, 
		}
	}
	-- go to level1.lua scene
	storyboard.gotoScene( "loading", options )
end

local function onHelpBtnRelease(event)
	local options = {
		effect = "fade",
		time = 500,
		params = {
		
		}
	}
	storyboard.gotoScene("help")
end

-----------------------------------------------------------------------------------------
-- BEGINNING OF YOUR IMPLEMENTATION
-- 
-- NOTE: Code outside of listener functions (below) will only be executed once,
--		 unless storyboard.removeScene() is called.
-- 
-----------------------------------------------------------------------------------------

-- Called when the scene's view does not exist:
function scene:createScene( event )
	local group = self.view

	-- display a background image
	local background = display.newImageRect( "background.jpg", display.contentWidth, display.contentHeight )
	background.anchorX = 0
	background.anchorY = 0
	background.x, background.y = 0, 0
	
	-- create/position logo/title image on upper-half of the screen
	local titleLogo = display.newImageRect( "logo.png", 350, 50 )
	titleLogo.x = display.contentWidth * 0.5
	titleLogo.y = 65
	
	-- create a widget button (which will loads level1.lua on release)
	local timeChallengeBtn = widget.newButton{
		label="Time Challenge",
		labelColor = { default={0, 0, 0, 0.7}, over={0, 0, 0} },
		width=154, height=40, fontSize=20, textOnly=true, 
		onRelease = onTimeChallengeBtnRelease	-- event listener function
	}
	timeChallengeBtn.x = display.contentWidth*0.5
	timeChallengeBtn.y = display.contentHeight - 120

	freePlayBtn = widget.newButton({
		label = "Free Play",
		labelColor = { default={0, 0, 0, 0.7}, over={0, 0, 0} },
		width=154, height=40,  fontSize=20, textOnly=true,  
		onRelease = onFreePlayBtnRelease,
		})
	freePlayBtn.x = display.contentWidth*0.5
	freePlayBtn.y = display.contentHeight - 150
	
	helpPlayBtn = widget.newButton({
		label = "Help",
		labelColor = { default={0, 0, 0, 0.7}, over={0, 0, 0} },
		width=154, height=40,  fontSize=20, textOnly=true,  
		onRelease = onHelpBtnRelease,
		})
		
	helpPlayBtn.x = display.contentWidth*0.5
	helpPlayBtn.y = display.contentHeight - 90
	
	-- all display objects must be inserted into group
	group:insert( background )
	group:insert( titleLogo )
	group:insert( timeChallengeBtn )
	group:insert(freePlayBtn)
	group:insert(helpPlayBtn)
	
	local player = persistence.loadPlayer("default")
	session.player = player
	
end

-- Called immediately after scene has moved onscreen:
function scene:enterScene( event )
	local group = self.view
	-- INSERT code here (e.g. start timers, load audio, start listeners, etc.)
	
end

-- Called when scene is about to move offscreen:
function scene:exitScene( event )
	local group = self.view
	
	-- INSERT code here (e.g. stop timers, remove listenets, unload sounds, etc.)
	
end

-- If scene's view is removed, scene:destroyScene() will be called just prior to:
function scene:destroyScene( event )
	local group = self.view
	
	if timeChallengeBtn then
		timeChallengeBtn:removeSelf()	-- widgets must be manually removed
		timeChallengeBtn = nil
		
		freePlayBtn:removeSelf()
		freePlayBtn = nil
	end
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
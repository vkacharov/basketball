----------------------------------------------------------------------------------
--
-- scenetemplate.lua
--
----------------------------------------------------------------------------------

local storyboard = require( "storyboard" )
local scene = storyboard.newScene()

----------------------------------------------------------------------------------
-- 
--	NOTE:
--	
--	Code outside of listener functions (below) will only be executed once,
--	unless storyboard.removeScene() is called.
-- 
local texts = {

{text=[[
As in every basketball game, your objective is to score as many baskets as possible and earn points. Have fun.
]]},


{text=[[
You can just take a shot or you can choose a trick from the trick menu first. Then you have to complete the trick in adition to scoring a basket to gain extra points. 
Should you fail to complete the trick or score a basket, you get no points for the round.
As you get more and more points, you will also unlock new trick. 
]]} ,

{text=
[[
Touch and drag the ball to position it. Don't get too close to the ring.
The round starts when you touch the ball. 
]] },

{img="help/drag.png"},

{text=
[[
Swipe the ball to throw it. Aim for the ring. 
The round ends when the ball is relatively in rest. 
]] },

{img="help/swipe.png"},

{text=
[[
	You can start a game in one of the two play modes available. We keep track of your best score for each play mode.
]]},

{text=
[[
	To end the current game by choose "End Game" from the menu. Then the best score for the mode is updated.
]]},

{text = [[
	TRICK DESCRIPTIONS: ]]},
	
{text=	[[
		Basket - You know what it is. It is also mandatory.
	]],
},
{text=	[[
		Sky Shot - The ball has to go above the upper bound of the screen before you score. Excludes "Revert Gravity" and vice versa.
	]],
},
{text=	[[
		Bottom - The ball has to hit the floor at least once before you score.
	]],
},
{text=	[[
		Left Wall - The ball has to hit the left wall at least once before you score.
	]],
},
{text=	[[
		Right Wall - The ball has to hit the right wall at least once before you score.
	]],
},
{text=	[[
		Revert Gravity - You need to score with the gravity inverted. The ceiling of the arena becomes solid. Excludes "Sky Shot" and "Space Shot" and vice versa.
	]],
},
{text=	[[
		Space Shot - Like "Sky Shot" but even higher. Excludes "Revert Gravity".
	]],
},
{text=	[[
		Blackout - You cannot see anything but the ball before you shoot. 
	]],
},
{text=	[[
		Huge Ball - The ball grows in size to make it harder to score.
	]],
	}
,
{text= [[
	Contacts : saintolivetreegames@gmail.com
	version 1.0
	May 2014
]]}
}

local pageSizes = {2, 2, 2, 2, 5, 5, 1}
local widget = require ( "widget" )

local currentPage = nil
local pageSize = 2
local helpTabs = nil

local function createHelpTile(text, index, isTitle)
	
	local group = display.newGroup()
	group.x = display.contentCenterX

	local width = display.contentWidth - 30
	local textText = nil
	
	local fontSize = 12
	if(sTitle) then
		fontSize = 16
	end
	
	if(text.text) then
		textText = display.newText({text=text.text, x=0, y=0, width=width, font=native.systemFontBold, fontSize=fontSize})
	elseif (text.img) then
		local w = width - 250
		textText = display.newImageRect(text.img, w, w / 1.65)
	end

	textText.anchorY = 0
	
	local textB = display.newRect(textText.x, textText.y, width + 20, textText.height)
	textB.anchorY = 0
	if(index % 2 == 0) then
		textB:setFillColor(0.5, 0, 0, 0.6)
	else
		textB:setFillColor(0.5)
	end
	
	group:insert(textB)
	group:insert(textText)
	
	group.anchorY = 0
	return group
end

local function goToPage(first, size)
	print(first, size)
	local prevTile = nil
	if(currentPage) then
		currentPage:removeSelf()
		currentPage = nil
	end
	
	local cp = display.newGroup()
	
	for index = first, first + size - 1 do
		local text = texts[index]
		
		if(not text) then 
			break
		end
		
		local tile = createHelpTile(text, index)
		cp:insert(tile)
		if(prevTile) then
			tile.y = prevTile.y + prevTile.contentHeight + 10
		else
			tile.y = 0
		end
		
		prevTile = tile
	end
	
	cp.y = 30
	currentPage = cp
end

local function onKeyEvent(event)

   local phase = event.phase
   local keyName = event.keyName
   print(phase, keyName)
   if(keyName == "back") then
		if(phase == "up") then
			storyboard.gotoScene( "menu", "fade", 500 )
		end
		return true
   end
   
   return false
end

-- Called when the scene's view does not exist:
function scene:createScene( event )
	local group = self.view
	display.setDefault( "background", 1, 1, 1 )
	
	
	local tabButtons = {}
	local first = 1
	for i,pageSize in pairs(pageSizes) do
		local f = first
		local tabButton = {
			width = 20, height = 20,
			
			onPress = function(event) 
				goToPage(f, pageSize) 
			end,
			size = 14,
			labelYOffset = -10,
			defaultFile="help/blackdot.png",
			overFile="help/reddot.png",

		}
		if(i == 1) then
			tabButton.selected = true
		end
		
		table.insert(tabButtons, tabButton)
		print("first", first)
		first = first + pageSize
	end

		
	helpTabs = widget.newTabBar(
	{
		left = display.contentWidth - 250 ,
		width = 250, 
		height = 15, 
		buttons = tabButtons,
		top = display.contentHeight - 75,
		backgroundFile="help/whitedot.png",
		
		tabSelectedLeftFile="help/whitedot.png",
		tabSelectedMiddleFile="help/whitedot.png",
		tabSelectedRightFile="help/whitedot.png",
		    tabSelectedFrameWidth = 0,
    tabSelectedFrameHeight = 0,
	})
	
	local backButton = widget.newButton({left = 0, label="Menu", textOnly=true,  top= display.contentHeight - 65,
		onRelease=function(event) storyboard.gotoScene( "menu", "fade", 500 ) end
		})
		
	group:insert(helpTabs)
	group:insert(backButton)

end


-- Called immediately after scene has moved onscreen:
function scene:enterScene( event )
	local group = self.view
	goToPage(1, pageSize)
	helpTabs:setSelected(1)
	
	Runtime:addEventListener( "key", onKeyEvent )
end


-- Called when scene is about to move offscreen:
function scene:exitScene( event )
	print("EXIT")
	local group = self.view
	if(currentPage) then
		currentPage:removeSelf()
		currentPage = nil
	end
	Runtime:removeEventListener( "key", onKeyEvent )
end


-- Called prior to the removal of scene's "view" (display group)
function scene:destroyScene( event )
	print("DESTROY")
	local group = self.view
	if(currentPage) then
		currentPage:removeSelf()
		currentPage = nil
	end
	Runtime:removeEventListener( "key", onKeyEvent )
end


---------------------------------------------------------------------------------
-- END OF YOUR IMPLEMENTATION
---------------------------------------------------------------------------------

-- "createScene" event is dispatched if scene's view does not exist
scene:addEventListener( "createScene", scene )

-- "enterScene" event is dispatched whenever scene transition has finished
scene:addEventListener( "enterScene", scene )

-- "exitScene" event is dispatched before next scene's transition begins
scene:addEventListener( "exitScene", scene )

-- "destroyScene" event is dispatched before view is unloaded, which can be
-- automatically unloaded in low memory situations, or explicitly via a call to
-- storyboard.purgeScene() or storyboard.removeScene().
scene:addEventListener( "destroyScene", scene )


---------------------------------------------------------------------------------

return scene
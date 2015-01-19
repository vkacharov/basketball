-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

-- hide the status bar
display.setStatusBar( display.HiddenStatusBar )

-- include the Corona "storyboard" module
local storyboard = require "storyboard"
local persistence = require("persistence")
local appID = "ca-app-pub-8229784233345482/3240081258"

-- load menu screen
persistence.initDatabase()
storyboard.gotoScene( "menu" )
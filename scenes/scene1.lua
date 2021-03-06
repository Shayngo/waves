local composer = require( "composer" )
local scene = composer.newScene()

local widget = require( "widget" )
local utility = require( "scripts.utility" )
local sceneConfigData = require( "scripts.sceneConfigData" )
local timeService = require( "scripts.timeService" )
local locationHandler = require( "scripts.locationHandler" )
local adjustColorService = require("scripts.adjustColorService")

local params

local xDisplay = display.contentWidth
local yDisplay = display.contentHeight


--text for displaying location information
local locationData = {}

--var to be used for time before player dies
local clockProperties = {}
local countDownTimer
local timeToRed 

--vars related to indicator background
local indicatorBackground

local indicatorBackgroundColors = {}

local indicatorBackgroundRedShiftTimerDelay = 100
local incrementRed
local indicatorBackgroundRedShiftTimer


local function handleButtonEvent( event )
    if ( "ended" == event.phase ) then 
        composer.removeScene( "scenes.menu", true ) 
        composer.gotoScene( "scenes.menu", { effect = "crossFade", time = 333 } ) 
    end
end
--
-- Start the composer event handlers
--

function scene:create( event )
    local sceneGroup = self.view

    print("creating scene1 scene...")

    params = event.params

     -- time before player dies
     local t = os.date( '*t' )  -- get table of current date and time
     math.randomseed(utility.round(os.time(t), -1))
     timeToRed = math.random( sceneConfigData.lowerBoundTimeToRed, sceneConfigData.upperBoundTimeToRed )

     --amount needed to incredment red rgb value to get to 1 in the timeToRed seconds
     incrementRed = (1 / (timeToRed * (1000 / indicatorBackgroundRedShiftTimerDelay)))

     clockProperties.secondsLeft = timeToRed
     local initialMinutes = math.floor(  clockProperties.secondsLeft / 60 )
     local initialSeconds =  clockProperties.secondsLeft % 60

     clockProperties.clockText = display.newText(string.format( "%02d:%02d", initialMinutes, initialSeconds), 
        display.contentCenterX, 
        yDisplay * .8, 
        native.systemFont, 
        yDisplay * .09)

     checkForDebugMode(clockProperties.clockText)

     sceneGroup:insert(clockProperties.clockText)

     indicatorBackground = display.newRect( 0, 0, xDisplay, yDisplay)
     indicatorBackground.x = display.contentCenterX
     indicatorBackground.y = display.contentCenterY

     indicatorBackgroundColors.r = sceneConfigData.r
     indicatorBackgroundColors.g = sceneConfigData.g
     indicatorBackgroundColors.b = sceneConfigData.b
     indicatorBackgroundColors.a = sceneConfigData.a

     indicatorBackground:setFillColor( indicatorBackgroundColors.r,
        indicatorBackgroundColors.g, 
        indicatorBackgroundColors.b,
        indicatorBackgroundColors.a)
     sceneGroup:insert(indicatorBackground)

     local doneButton = widget.newButton({
        id = "button1",
        label = "Done",
        width = 100,
        height = 32,
        onEvent = handleButtonEvent
    })
     doneButton.x = display.contentCenterX
     doneButton.y = display.contentHeight - 40
     sceneGroup:insert( doneButton )


     locationData = {}
     locationData.xLocationDisplay = xDisplay * .5
     locationData.yLocationDisplay = yDisplay

     locationData.latitudeText = display.newText( "latitude : ", locationData.xLocationDisplay, locationData.yLocationDisplay * .4, native.systemFont, 16 )
     checkForDebugMode(locationData.latitudeText)
     locationData.longitudeText = display.newText( "longitude : ", locationData.xLocationDisplay, locationData.yLocationDisplay * .45, native.systemFont, 16 )
     checkForDebugMode(locationData.longitudeText)
     locationData.targetLatitudeText = display.newText( "target latitude : ", locationData.xLocationDisplay, locationData.yLocationDisplay * .55, native.systemFont, 16 )
     checkForDebugMode(locationData.targetLatitudeText)
     locationData.targetLongitudeText = display.newText( "target longitude : ", locationData.xLocationDisplay, locationData.yLocationDisplay * .6, native.systemFont, 16 )
     checkForDebugMode(locationData.targetLongitudeText)
     locationData.distanceText = display.newText( "distance : ", locationData.xLocationDisplay, locationData.yLocationDisplay * .65, native.systemFont, 16 )
     checkForDebugMode(locationData.distanceText)
     locationData.blinkText = display.newText( "blink : ", locationData.xLocationDisplay, locationData.yLocationDisplay * .7, native.systemFont, 16 )
     checkForDebugMode(locationData.blinkText)
     locationData.shield = display.newImage( "sheild.png", xDisplay * .5, yDisplay * .25 )
     locationData.shield:scale( .1, .1 )

     locationData.isPopulated = true

     sceneGroup:insert(locationData.latitudeText)
     sceneGroup:insert(locationData.longitudeText)
     sceneGroup:insert(locationData.distanceText)
     sceneGroup:insert(locationData.targetLatitudeText)
     sceneGroup:insert(locationData.targetLongitudeText)
     sceneGroup:insert(locationData.blinkText)
     sceneGroup:insert(locationData.shield)

     print("rounded : " .. utility.round(((8 / 88) * 44) * 1000 * 2, -3))

 end

 function checkForDebugMode ( objectToAlpha )
    if sceneConfigData.settings.debugOn == false then
        objectToAlpha.alpha = 0
    else 
        objectToAlpha.alpha = 1
    end
end


function checkIfBlinkingShouldChange( event ) 
    if locationData ~= nil and locationData.hasCoordinates ~= nil then
        local ratioToConvertDistanceToFrequency = 1000 * 2
        local frequency = utility.round(((8 / locationData.maxDistance) * locationData.distance) * ratioToConvertDistanceToFrequency, -3)
        locationData.blinkText.text = "new frequency : " .. frequency
        if frequency < 500 then
            frequency = 500
        end
        if locationData.frequency == nil or (frequency ~= locationData.frequency) then
            if locationData.frequency ~= nil then
                locationData.blinkText.text = "new frequency : " .. frequency .. " old frequency : " .. locationData.frequency
            end
            locationData.frequency = frequency
            if indicatorBackgroundTrasistion ~= nil then
                transition.cancel(indicatorBackgroundTrasistion)
                indicatorBackgroundTrasistion = nil
            end
            if indicatorBackground ~= nil then
                indicatorBackground:removeSelf()
                indicatorBackground = nil
            end

            indicatorBackground = display.newRect( 0, 0, xDisplay, yDisplay)
            indicatorBackground.x = display.contentCenterX
            indicatorBackground.y = display.contentCenterY

            indicatorBackground:setFillColor( indicatorBackgroundColors.r,
                indicatorBackgroundColors.g, 
                indicatorBackgroundColors.b,
                indicatorBackgroundColors.a)

            indicatorBackgroundTrasistion = transition.blink( indicatorBackground, { time=frequency } )
        end
    end
end

function scene:show( event )
    local sceneGroup = self.view

    params = event.params

    print("showing scene1 scene...")

    if event.phase == "did" then

        print("making scene1 timers...")
        if indicatorBackgroundRedShiftTimer == nil then
           indicatorBackgroundRedShiftTimer = timer.performWithDelay( indicatorBackgroundRedShiftTimerDelay, 
            function() 
             indicatorBackgroundColors.r = indicatorBackgroundColors.r + incrementRed
             adjustColorService.adjustObjectColor(indicatorBackground, indicatorBackgroundColors) 
         end,
         0 )
       end

       if blinkTimer == nil then
        blinkTimer = timer.performWithDelay( 500, checkIfBlinkingShouldChange, 0 )
    end

    if indicatorBackground ~= nil then
        indicatorBackground:removeSelf()
        indicatorBackground = nil
    end

    if countDownTimer == nil then
       countDownTimer = timer.performWithDelay( 1000, function() 
        timeService.updateTime(clockProperties) 
        if clockProperties.secondsLeft < 1 then
            if locationData.frequency ~= nil and locationData.frequency < 600 then
                print("scene1 going to startNewWave scene...")
                composer.removeScene( "scenes.startNewWave", true )
                composer.gotoScene("scenes.startNewWave", { effect = "crossFade", time = 333 })
            else
                composer.removeScene( "scenes.menu", true ) 
                composer.gotoScene( "scenes.menu", { effect = "crossFade", time = 333 } ) 
            end
        end
    end, timeToRed )
   end
end
end

function scene:hide( event )
    local sceneGroup = self.view
    
    if event.phase == "will" then
        print("canceling scene1 timers...")
        timer.cancel(indicatorBackgroundRedShiftTimer)
        indicatorBackgroundRedShiftTimer = nil
        timer.cancel(countDownTimer)
        timer.cancel(blinkTimer)
        blinkTimer = nil
        countDownTimer = nil
        locationData = nil

        if indicatorBackgroundTrasistion ~= nil then
            transition.cancel(indicatorBackgroundTrasistion)
            indicatorBackgroundTrasistion = nil
        end
        if indicatorBackground ~= nil then
            indicatorBackground:removeSelf()
            indicatorBackground = nil
        end
    end

end

function scene:destroy( event )
    local sceneGroup = self.view

    if indicatorBackgroundTrasistion ~= nil then
        transition.cancel(indicatorBackgroundTrasistion)
        indicatorBackgroundTrasistion = nil
    end
    if indicatorBackground ~= nil then
        indicatorBackground:removeSelf()
        indicatorBackground = nil
    end
    
end

-- run them timer

---------------------------------------------------------------------------------
-- END OF YOUR IMPLEMENTATION
---------------------------------------------------------------------------------
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )
function forwardToLocationHandler(event) 
    locationHandler.locationHandler(event, locationData)
end
Runtime:addEventListener( "location", forwardToLocationHandler )
return scene

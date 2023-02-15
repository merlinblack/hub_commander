require 'events'
require 'eventnames'
require 'console'

-- Perhaps this should be part of screen class?
currentScreen = nil

lastEvent = 0
consoleActive = false
mouseDown = false
swipeStart = nil
fingerDown = false
lastMouseEvent = -math.huge

function setCurrentScreen(newScreen)
	if currentScreen then
		currentScreen:deactivate()
	end
	currentScreen = newScreen
end

function getCurrentScreen()
	return currentScreen
end

function handleTouch(type, x, y, dx, dy)
	lastEvent = app.ticks
	if false then
		print('Touched: ' .. EventNames[type])
		print(x,y)
		print(x*app.width,y*app.height)
		print(dx,dy)
	end
	if currentScreen then
		if type == EVENT_TOUCH_MOTION then
			currentScreen:mouseMoved(app.ticks, x*app.width, y*app.height, 1)
		end
		if type == EVENT_TOUCH_DOWN then
			local lx = x * app.width
			local ly = y * app.height
			currentScreen:mouseDown(app.ticks, lx, ly, 1)
			fingerDown = true
			swipeStart = {x=lx, y=ly}
		end
		if type == EVENT_TOUCH_UP then
			local lx = x * app.width
			local ly = y * app.height
			local swipeDirection = detectSwipe(swipeStart, lx, ly)
			mouseDown = false
			swipeStart = nil
			if swipeDirection == Swipe.None then
				currentScreen:mouseClick(app.ticks, lx, ly, 1)
			else
				currentScreen:swipe(swipeDirection)
			end
			currentScreen:mouseUp(app.ticks, lx, ly, 1)
		end
	end
end

function handleMouse(type, x, y, button, state, clicks)
	lastEvent = app.ticks
	lastMouseEvent = lastEvent
	showCursor()
	if false then
		print('Mouse: ' .. EventNames[type])
		print('x,y:', x, y)
		print('button', button)
		print('state', state)
		print('clicks', clicks)
	end

	if currentScreen then
		if type == EVENT_MOUSE_MOTION then
			currentScreen:mouseMoved(app.ticks, x, y, button)
		end
		if type == EVENT_MOUSE_BUTTONUP then
			local swipeDirection = detectSwipe(swipeStart, x, y)
			mouseDown = false
			swipeStart = nil
			if swipeDirection == Swipe.None then
				currentScreen:mouseClick(app.ticks, x, y, button)
			else
				currentScreen:swipe(swipeDirection)
			end
			currentScreen:mouseUp(app.ticks, x, y, button)
		end
		if type == EVENT_MOUSE_BUTTONDOWN then
			mouseDown = true
			swipeStart = {x=x, y=y}
			currentScreen:mouseDown(app.ticks, x, y, button)
		end
	end
end

function detectSwipe(start, endX, endY)
	local threshold = 50

	if start.x - endX > threshold then
		return Swipe.Left
	end

	if endX - start.x > threshold then
		return Swipe.Right
	end

	if start.y - endY > threshold then
		return Swipe.Up
	end

	if endY - start.y > threshold then
		return Swipe.Down
	end

	return Swipe.None
end

function handleKeyUp(code, sym)
	--print('handleKeyUp()', code, sym)
	lastEvent = app.ticks
	if not console:isEnabled() then
		if code == 41 then -- Escape
			app.shouldStop = true
		end
		if sym == 's' then
			screenSaver:setDirectory('media/alara/')
			addTask(screenSaveTask, 'screensaver')
		end
		if sym == '`' then
			console:toggleEnabled()
		end
	else
		console:keyUp(code, sym)
	end
end

function handleTextInput(text)
	console:textInput(text)
end

function hideCursorTask()
	stopHideCursorTask = false
	while not stopHideCursorTask do
		wait(1000)
		if lastMouseEvent + 5000 < app.ticks then
			app.showCursor = false
			stopHideCursorTask = true
		end
	end
end

function showCursor()
	app.showCursor = true
	addUniqueTask(hideCursorTask, 'hideCursorTask')
end
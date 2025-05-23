-- main.lua
local scenes = {
	game = require("gameScene"),
}
local currentScene = nil

-- Virtual resolution for game logic and rendering
local VIRTUAL_WIDTH = 800
local VIRTUAL_HEIGHT = 600
local ASPECT_RATIO = VIRTUAL_WIDTH / VIRTUAL_HEIGHT -- 4:3 = 1.333

-- Viewport for scaling and centering
local viewport = {
	x = 0,
	y = 0,
	width = VIRTUAL_WIDTH,
	height = VIRTUAL_HEIGHT,
	scale = 1,
}

-- Switch to a new scene
function switchScene(sceneName)
	if scenes[sceneName] then
		currentScene = scenes[sceneName]
		if currentScene.load then
			currentScene:load(viewport)
		end
	end
end

-- Update viewport based on window size
function updateViewport()
	local windowWidth, windowHeight = love.graphics.getDimensions()
	local windowAspect = windowWidth / windowHeight

	if windowAspect > ASPECT_RATIO then
		-- Window is wider than 4:3, use height to determine scale (pillarbox)
		viewport.scale = windowHeight / VIRTUAL_HEIGHT
		viewport.width = VIRTUAL_WIDTH * viewport.scale -- Screen coordinates
		viewport.height = windowHeight
		viewport.x = (windowWidth - viewport.width) / 2
		viewport.y = 0
	else
		-- Window is taller than 4:3, use width to determine scale (letterbox)
		viewport.scale = windowWidth / VIRTUAL_WIDTH
		viewport.width = windowWidth
		viewport.height = VIRTUAL_HEIGHT * viewport.scale -- Screen coordinates
		viewport.x = 0
		viewport.y = (windowHeight - viewport.height) / 2
	end
end

function love.load()
	-- Set up initial window (windowed or fullscreen)
	love.window.setTitle("Pong Clone")
	love.window.setMode(VIRTUAL_WIDTH, VIRTUAL_HEIGHT) -- Default windowed size
	love.graphics.setBackgroundColor(0, 0, 0)
	updateViewport()

	-- Register scenes
	switchScene("game")
end

function love.resize(w, h)
	updateViewport()
end

function love.keypressed(key)
	-- Toggle fullscreen with 'f' key
	if key == "f" then
		local fullscreen = not love.window.getFullscreen()
		love.window.setFullscreen(fullscreen)
		updateViewport()
	end

	if currentScene and currentScene.keypressed then
		currentScene:keypressed(key)
	end
end

function love.update(dt)
	if currentScene and currentScene.update then
		currentScene:update(dt)
	end
end

function love.draw()
	love.graphics.push()
	love.graphics.translate(viewport.x, viewport.y)
	love.graphics.scale(viewport.scale, viewport.scale)

	if currentScene and currentScene.draw then
		currentScene:draw()
	end

	-- Draw black bars for letterboxing/pillarboxing after the scene
	love.graphics.setColor(0, 0, 0)
	if viewport.x > 0 then
		-- Pillarbox (black bars on sides)
		love.graphics.rectangle("fill", -viewport.x / viewport.scale, 0, viewport.x / viewport.scale, VIRTUAL_HEIGHT)
		love.graphics.rectangle("fill", VIRTUAL_WIDTH, 0, viewport.x / viewport.scale, VIRTUAL_HEIGHT)
	elseif viewport.y > 0 then
		-- Letterbox (black bars on top/bottom)
		love.graphics.rectangle("fill", 0, -viewport.y / viewport.scale, VIRTUAL_WIDTH, viewport.y / viewport.scale)
		love.graphics.rectangle("fill", 0, VIRTUAL_HEIGHT, VIRTUAL_WIDTH, viewport.y / viewport.scale)
	end

	love.graphics.pop()
end

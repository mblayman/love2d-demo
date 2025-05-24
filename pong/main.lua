-- main.lua
local scenes = {
	menu = require("menuScene"),
	game = require("gameScene"),
}
local currentScene = nil
local backgroundMusic = nil

local VIRTUAL_WIDTH = 800
local VIRTUAL_HEIGHT = 600
local ASPECT_RATIO = VIRTUAL_WIDTH / VIRTUAL_HEIGHT

local viewport = {
	x = 0,
	y = 0,
	width = VIRTUAL_WIDTH,
	height = VIRTUAL_HEIGHT,
	scale = 1,
}

function switchScene(sceneName, difficulty)
	if scenes[sceneName] then
		currentScene = scenes[sceneName]
		if currentScene.load then
			currentScene:load(viewport, backgroundMusic, difficulty)
		end
	end
end

function updateViewport()
	local windowWidth, windowHeight = love.graphics.getDimensions()
	local windowAspect = windowWidth / windowHeight
	if windowAspect > ASPECT_RATIO then
		viewport.scale = windowHeight / VIRTUAL_HEIGHT
		viewport.width = VIRTUAL_WIDTH * viewport.scale
		viewport.height = windowHeight
		viewport.x = (windowWidth - viewport.width) / 2
		viewport.y = 0
	else
		viewport.scale = windowWidth / VIRTUAL_WIDTH
		viewport.width = windowWidth
		viewport.height = VIRTUAL_HEIGHT * viewport.scale
		viewport.x = 0
		viewport.y = (windowHeight - viewport.height) / 2
	end
end

function love.load()
	love.window.setTitle("Pong Clone")
	love.window.setMode(VIRTUAL_WIDTH, VIRTUAL_HEIGHT)
	love.graphics.setBackgroundColor(0, 0, 0)
	backgroundMusic = love.audio.newSource("sounds/background.mp3", "stream")
	backgroundMusic:setLooping(true)
	backgroundMusic:setVolume(0.5)
	backgroundMusic:play()
	updateViewport()
	switchScene("menu")
end

function love.resize(w, h)
	updateViewport()
	if currentScene and currentScene.resize then
		currentScene:resize(viewport)
	end
end

function love.keypressed(key)
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
	love.graphics.setColor(0, 0, 0)
	if viewport.x > 0 then
		love.graphics.rectangle("fill", -viewport.x / viewport.scale, 0, viewport.x / viewport.scale, VIRTUAL_HEIGHT)
		love.graphics.rectangle("fill", VIRTUAL_WIDTH, 0, viewport.x / viewport.scale, VIRTUAL_HEIGHT)
	elseif viewport.y > 0 then
		love.graphics.rectangle("fill", 0, -viewport.y / viewport.scale, VIRTUAL_WIDTH, viewport.y / viewport.scale)
		love.graphics.rectangle("fill", 0, VIRTUAL_HEIGHT, VIRTUAL_WIDTH, viewport.y / viewport.scale)
	end
	love.graphics.pop()
end

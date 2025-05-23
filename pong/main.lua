-- Scene manager
local scenes = {}
local currentScene = nil

-- Switch to a new scene
function switchScene(sceneName)
	if scenes[sceneName] then
		currentScene = scenes[sceneName]
		if currentScene.load then
			currentScene:load()
		end
	end
end

-- LOVE callbacks
function love.load()
	-- Register scenes
	scenes["menu"] = require("menuScene")
	scenes["game"] = require("gameScene")
	-- Start with the menu scene
	switchScene("menu")
end

function love.update(dt)
	if currentScene and currentScene.update then
		currentScene:update(dt)
	end
end

function love.keypressed(key)
	if currentScene and currentScene.keypressed then
		currentScene:keypressed(key)
	end
end

function love.draw()
	if currentScene and currentScene.draw then
		currentScene:draw()
	end
end

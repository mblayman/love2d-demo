local MenuScene = {}

function MenuScene:load()
	-- Load menu assets (e.g., background, fonts)
	self.font = love.graphics.newFont("assets/myfont.ttf", 36)
end

function MenuScene:update(dt)
	-- Update menu state (e.g., button hover)
end

function MenuScene:draw()
	-- Draw menu
	love.graphics.setColor(1, 1, 1)
	love.graphics.setFont(self.font)
	love.graphics.print("Press Enter to Start", 250, 300)
end

function MenuScene:keypressed(key)
	-- Handle menu input
	if key == "return" then
		switchScene("game")
	end
end

return MenuScene

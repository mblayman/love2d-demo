local MenuScene = {}

function MenuScene:load(viewport)
	-- Store viewport for scaling
	self.viewport = viewport

	-- Load assets
	self.backgroundImage = love.graphics.newImage("assets/background.png")
	local baseFontSize = 36
	local scale = viewport.scale or 1
	self.font = love.graphics.newFont("assets/myfont.ttf", math.floor(baseFontSize * scale))

	-- Menu state
	self.menuItems = {
		{
			text = "Start Game",
			action = function()
				switchScene("game")
			end,
		},
		{
			text = "Exit",
			action = function()
				love.event.quit()
			end,
		},
	}
	self.selectedIndex = 1 -- Start with first item selected

	-- Load background music (shared with GameScene)
	self.backgroundMusic = love.audio.newSource("sounds/background.mp3", "stream")
	self.backgroundMusic:setLooping(true)
	self.backgroundMusic:setVolume(0.5)
	self.backgroundMusic:play()
end

function MenuScene:update(dt)
	-- No continuous updates needed for now
end

function MenuScene:keypressed(key)
	if key == "up" then
		self.selectedIndex = math.max(1, self.selectedIndex - 1)
	elseif key == "down" then
		self.selectedIndex = math.min(#self.menuItems, self.selectedIndex + 1)
	elseif key == "return" then
		-- Execute the selected menu item's action
		self.menuItems[self.selectedIndex].action()
	end
end

function MenuScene:draw()
	-- Draw background image (same as GameScene)
	local bgHeight = 1024
	local scale = 600 / bgHeight
	local bgWidth = 1536
	local scaledWidth = bgWidth * scale
	local bgOffsetX = -(scaledWidth - 800) / 2
	love.graphics.setColor(1, 1, 1)
	love.graphics.draw(self.backgroundImage, bgOffsetX, 0, 0, scale, scale)

	-- Draw title
	love.graphics.setFont(self.font)
	love.graphics.setColor(1, 1, 1)
	love.graphics.print("Pong Clone", 300, 150)

	-- Draw menu items
	for i, item in ipairs(self.menuItems) do
		local y = 300 + (i - 1) * 60
		if i == self.selectedIndex then
			-- Highlight selected item
			love.graphics.setColor(1, 0.9, 0) -- Yellow highlight
		else
			love.graphics.setColor(1, 1, 1)
		end
		love.graphics.print(item.text, 300, y)
	end
end

return MenuScene

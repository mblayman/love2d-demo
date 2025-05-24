-- menuScene.lua
local MenuScene = {}

-- Helper function to initialize font
local function initFont(self)
	local baseFontSize = 36 -- Reduced from 36 to match game scene
	self.font = love.graphics.newFont("assets/myfont.ttf", math.floor(baseFontSize))
end

function MenuScene:load(viewport, backgroundMusic)
	-- Store viewport and music
	self.viewport = viewport
	self.backgroundMusic = backgroundMusic

	-- Load assets
	self.backgroundImage = love.graphics.newImage("assets/background.png")
	initFont(self)

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

	-- Ensure music is playing
	if not self.backgroundMusic:isPlaying() then
		self.backgroundMusic:play()
	end
end

function MenuScene:resize(viewport)
	self.viewport = viewport
	initFont(self)
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
	-- Draw background image
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
			love.graphics.setColor(1, 0.9, 0) -- Yellow highlight
		else
			love.graphics.setColor(1, 1, 1)
		end
		love.graphics.print(item.text, 300, y)
	end
end

return MenuScene

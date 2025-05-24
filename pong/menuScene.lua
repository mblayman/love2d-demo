-- menuScene.lua
local MenuScene = {}
local Settings = require("settings")

-- Helper function to initialize font
local function initFont(self)
	local baseFontSize = 36
	self.font = love.graphics.newFont("assets/myfont.ttf", math.floor(baseFontSize))
end

function MenuScene:load(viewport, backgroundMusic)
	self.viewport = viewport
	self.backgroundMusic = backgroundMusic
	self.selectedDifficulty = "normal" -- Default to Normal
	self.backgroundImage = love.graphics.newImage(Settings.difficulties[self.selectedDifficulty].backgroundImagePath)
	initFont(self)

	-- Menu items
	self.menuItems = {
		{
			text = "Start Game",
			action = function()
				switchScene("game", self.selectedDifficulty)
			end,
		},
		{
			text = "", -- No prefix for difficulty row
			isDifficultySelect = true,
		},
		{
			text = "Quit",
			action = function()
				love.event.quit()
			end,
		},
	}
	self.selectedIndex = 1 -- Selected menu row
	self.difficultyOptions = { "normal", "hard" }
	self.difficultyIndex = 1 -- 1 = normal, 2 = hard

	if not self.backgroundMusic:isPlaying() then
		self.backgroundMusic:play()
	end
end

function MenuScene:resize(viewport)
	self.viewport = viewport
	initFont(self)
end

function MenuScene:update(dt)
	-- No continuous updates needed
end

function MenuScene:keypressed(key)
	if key == "up" then
		self.selectedIndex = math.max(1, self.selectedIndex - 1)
	elseif key == "down" then
		self.selectedIndex = math.min(#self.menuItems, self.selectedIndex + 1)
	elseif key == "left" and self.menuItems[self.selectedIndex].isDifficultySelect then
		self.difficultyIndex = math.max(1, self.difficultyIndex - 1)
		self.selectedDifficulty = self.difficultyOptions[self.difficultyIndex]
		self.backgroundImage =
			love.graphics.newImage(Settings.difficulties[self.selectedDifficulty].backgroundImagePath)
	elseif key == "right" and self.menuItems[self.selectedIndex].isDifficultySelect then
		self.difficultyIndex = math.min(#self.difficultyOptions, self.difficultyIndex + 1)
		self.selectedDifficulty = self.difficultyOptions[self.difficultyIndex]
		self.backgroundImage =
			love.graphics.newImage(Settings.difficulties[self.selectedDifficulty].backgroundImagePath)
	elseif key == "return" then
		local item = self.menuItems[self.selectedIndex]
		if item.action then
			item.action()
		end
	end
end

function MenuScene:draw()
	-- Draw background
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
			love.graphics.setColor(1, 0.9, 0) -- Yellow for active menu item
		else
			love.graphics.setColor(1, 1, 1) -- White for inactive
		end
		if item.isDifficultySelect then
			-- Draw "Normal" and "Hard" side by side, centered
			local normalText = "Normal"
			local hardText = "Hard"
			local normalWidth = self.font:getWidth(normalText)
			local hardWidth = self.font:getWidth(hardText)
			local spacing = 20
			local totalWidth = normalWidth + spacing + hardWidth
			local startX = (800 - totalWidth) / 2 -- Center horizontally in 800px width
			local normalX = startX
			local hardX = startX + normalWidth + spacing

			-- Draw Normal
			if self.selectedDifficulty == "normal" then
				love.graphics.setColor(1, 0, 0) -- Red outline
				love.graphics.setLineWidth(2)
				local textHeight = self.font:getHeight()
				love.graphics.rectangle("line", normalX - 5, y - 5, normalWidth + 10, textHeight + 10)
				love.graphics.setLineWidth(1)
			end
			love.graphics.setColor(i == self.selectedIndex and { 1, 0.9, 0 } or { 1, 1, 1 })
			love.graphics.print(normalText, normalX, y)

			-- Draw Hard
			if self.selectedDifficulty == "hard" then
				love.graphics.setColor(1, 0, 0) -- Red outline
				love.graphics.setLineWidth(2)
				local textHeight = self.font:getHeight()
				love.graphics.rectangle("line", hardX - 5, y - 5, hardWidth + 10, textHeight + 10)
				love.graphics.setLineWidth(1)
			end
			love.graphics.setColor(i == self.selectedIndex and { 1, 0.9, 0 } or { 1, 1, 1 })
			love.graphics.print(hardText, hardX, y)
		else
			love.graphics.print(item.text, 300, y)
		end
	end
end

return MenuScene

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
			text = "Go",
			action = function()
				switchScene("game", self.selectedDifficulty)
			end,
		},
		{
			text = "", -- No prefix for difficulty row
			isDifficultySelect = true,
			action = function()
				switchScene("game", self.selectedDifficulty)
			end,
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

	-- Pulse effect variables
	self.pulseTimer = 0
	self.pulseSpeed = 5 -- Faster pulsing
	self.pulseAmplitude = 0.1 -- Max scale increase (10% larger)

	if not self.backgroundMusic:isPlaying() then
		self.backgroundMusic:play()
	end
end

function MenuScene:resize(viewport)
	self.viewport = viewport
	initFont(self)
end

function MenuScene:update(dt)
	-- Update pulse timer for animation
	self.pulseTimer = self.pulseTimer + dt
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

	-- Set font for all text
	love.graphics.setFont(self.font)

	-- Draw menu items with increased vertical spacing
	for i, item in ipairs(self.menuItems) do
		local y = 150 + (i - 1) * 100 -- Increased from 200 + (i-1)*60 to 150 + (i-1)*100
		local pulseScale = 1
		if i == self.selectedIndex then
			-- Calculate pulse scale for selected item
			pulseScale = 1 + self.pulseAmplitude * math.sin(self.pulseTimer * self.pulseSpeed)
		end

		if item.isDifficultySelect then
			-- Draw "Normal" and "Hard" side by side, centered, with increased spacing
			local normalText = "Normal"
			local hardText = "Hard"
			local normalWidth = self.font:getWidth(normalText)
			local hardWidth = self.font:getWidth(hardText)
			local spacing = 50 -- Increased from 20 to 50
			local totalWidth = normalWidth + spacing + hardWidth
			local startX = (800 - totalWidth) / 2
			local normalX = startX
			local hardX = startX + normalWidth + spacing

			-- Draw Normal with glow, pulse, and scaled white square
			if i == self.selectedIndex then
				love.graphics.setBlendMode("add", "alphamultiply")
				for glow = 1, 3 do
					local alpha = 0.3 / glow
					love.graphics.setColor(0, 1, 1, alpha)
					love.graphics.push()
					love.graphics.translate(normalX + normalWidth / 2, y + self.font:getHeight() / 2)
					love.graphics.scale(pulseScale, pulseScale)
					love.graphics.print(normalText, -normalWidth / 2, -self.font:getHeight() / 2)
					love.graphics.pop()
				end
				love.graphics.setBlendMode("alpha")
				love.graphics.setColor(1, 0.9, 0) -- Yellow for active
			else
				love.graphics.setColor(1, 1, 1)
			end
			-- Draw semi-transparent white square for selected difficulty, scaled with pulse
			if self.selectedDifficulty == "normal" then
				love.graphics.setColor(1, 1, 1, 0.2) -- White with 20% opacity
				local textHeight = self.font:getHeight()
				love.graphics.push()
				love.graphics.translate(normalX + normalWidth / 2, y + textHeight / 2)
				love.graphics.scale(pulseScale, pulseScale)
				love.graphics.rectangle(
					"fill",
					-normalWidth / 2 - 5,
					-textHeight / 2 - 5,
					normalWidth + 10,
					textHeight + 10
				)
				love.graphics.pop()
			end
			love.graphics.setColor(i == self.selectedIndex and { 1, 0.9, 0 } or { 1, 1, 1 })
			love.graphics.push()
			love.graphics.translate(normalX + normalWidth / 2, y + self.font:getHeight() / 2)
			love.graphics.scale(pulseScale, pulseScale)
			love.graphics.print(normalText, -normalWidth / 2, -self.font:getHeight() / 2)
			love.graphics.pop()

			-- Draw Hard with glow, pulse, and scaled white square
			if i == self.selectedIndex then
				love.graphics.setBlendMode("add", "alphamultiply")
				for glow = 1, 3 do
					local alpha = 0.3 / glow
					love.graphics.setColor(0, 1, 1, alpha)
					love.graphics.push()
					love.graphics.translate(hardX + hardWidth / 2, y + self.font:getHeight() / 2)
					love.graphics.scale(pulseScale, pulseScale)
					love.graphics.print(hardText, -hardWidth / 2, -self.font:getHeight() / 2)
					love.graphics.pop()
				end
				love.graphics.setBlendMode("alpha")
				love.graphics.setColor(1, 0.9, 0)
			else
				love.graphics.setColor(1, 1, 1)
			end
			-- Draw semi-transparent white square for selected difficulty, scaled with pulse
			if self.selectedDifficulty == "hard" then
				love.graphics.setColor(1, 1, 1, 0.2) -- White with 20% opacity
				local textHeight = self.font:getHeight()
				love.graphics.push()
				love.graphics.translate(hardX + hardWidth / 2, y + textHeight / 2)
				love.graphics.scale(pulseScale, pulseScale)
				love.graphics.rectangle(
					"fill",
					-hardWidth / 2 - 5,
					-textHeight / 2 - 5,
					hardWidth + 10,
					textHeight + 10
				)
				love.graphics.pop()
			end
			love.graphics.setColor(i == self.selectedIndex and { 1, 0.9, 0 } or { 1, 1, 1 })
			love.graphics.push()
			love.graphics.translate(hardX + hardWidth / 2, y + self.font:getHeight() / 2)
			love.graphics.scale(pulseScale, pulseScale)
			love.graphics.print(hardText, -hardWidth / 2, -self.font:getHeight() / 2)
			love.graphics.pop()
		else
			-- Draw regular menu items with glow and pulse
			local textWidth = self.font:getWidth(item.text)
			local x = (800 - textWidth) / 2
			if i == self.selectedIndex then
				love.graphics.setBlendMode("add", "alphamultiply")
				for glow = 1, 3 do
					local alpha = 0.3 / glow
					love.graphics.setColor(0, 1, 1, alpha)
					love.graphics.push()
					love.graphics.translate(x + textWidth / 2, y + self.font:getHeight() / 2)
					love.graphics.scale(pulseScale, pulseScale)
					love.graphics.print(item.text, -textWidth / 2, -self.font:getHeight() / 2)
					love.graphics.pop()
				end
				love.graphics.setBlendMode("alpha")
				love.graphics.setColor(1, 0.9, 0)
			else
				love.graphics.setColor(1, 1, 1)
			end
			love.graphics.push()
			love.graphics.translate(x + textWidth / 2, y + self.font:getHeight() / 2)
			love.graphics.scale(pulseScale, pulseScale)
			love.graphics.print(item.text, -textWidth / 2, -self.font:getHeight() / 2)
			love.graphics.pop()
		end
	end
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

return MenuScene

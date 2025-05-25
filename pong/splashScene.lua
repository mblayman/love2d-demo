-- splashScene.lua
local SplashScene = {}

-- Helper function to initialize font
local function initFont(self)
	local baseFontSize = 36
	self.font = love.graphics.newFont("assets/myfont.ttf", math.floor(baseFontSize))
end

function SplashScene:load(viewport, backgroundMusic)
	self.viewport = viewport
	self.backgroundMusic = backgroundMusic -- Keep reference but don't play
	self.titleText = "Space Bounce Xtreme"
	self.titleDisplay = ""
	self.typingTimer = 0
	self.typingSpeed = 0.1 -- Seconds per letter
	self.typingIndex = 1
	self.fadeTimer = 0
	self.fadeDuration = 0.5 -- Fade-out duration after typing
	self.isTypingComplete = false
	initFont(self)
end

function SplashScene:resize(viewport)
	self.viewport = viewport
	initFont(self)
end

function SplashScene:update(dt)
	if not self.isTypingComplete then
		self.typingTimer = self.typingTimer + dt
		if self.typingTimer >= self.typingSpeed and self.typingIndex <= #self.titleText then
			self.titleDisplay = self.titleDisplay .. self.titleText:sub(self.typingIndex, self.typingIndex)
			self.typingIndex = self.typingIndex + 1
			self.typingTimer = 0
		end
		if self.typingIndex > #self.titleText then
			self.isTypingComplete = true
		end
	else
		self.fadeTimer = self.fadeTimer + dt
		if self.fadeTimer >= self.fadeDuration then
			switchScene("menu")
		end
	end
end

function SplashScene:keypressed(key)
	if key == "return" or key == "space" then
		switchScene("menu")
	end
end

function SplashScene:draw()
	-- Draw black background
	love.graphics.setBackgroundColor(0, 0, 0)
	love.graphics.setColor(0, 0, 0)
	love.graphics.rectangle("fill", 0, 0, 800, 600)

	-- Draw title with glow effect
	love.graphics.setFont(self.font)
	local titleWidth = self.font:getWidth(self.titleDisplay)
	local titleX = (800 - titleWidth) / 2
	local titleY = 300 -- Centered vertically
	-- Glow effect
	love.graphics.setBlendMode("add", "alphamultiply")
	for glow = 1, 3 do
		local alpha = 0.3 / glow
		love.graphics.setColor(0, 1, 1, alpha) -- Cyan glow
		love.graphics.print(self.titleDisplay, titleX + glow, titleY + glow)
		love.graphics.print(self.titleDisplay, titleX - glow, titleY - glow)
		love.graphics.print(self.titleDisplay, titleX + glow, titleY - glow)
		love.graphics.print(self.titleDisplay, titleX - glow, titleY + glow)
	end
	love.graphics.setBlendMode("alpha")
	-- Main text with fade effect
	local fadeAlpha = self.isTypingComplete and (1 - self.fadeTimer / self.fadeDuration) or 1
	love.graphics.setColor(1, 1, 1, fadeAlpha)
	love.graphics.print(self.titleDisplay, titleX, titleY)
end

return SplashScene

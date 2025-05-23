local GameScene = {}

function GameScene:load(viewport)
	-- Store viewport for scaling fonts and particles
	self.viewport = viewport

	-- Load background image
	self.backgroundImage = love.graphics.newImage("assets/background.png")

	-- Ball properties
	self.ball = {
		x = 400,
		y = 300,
		radius = 10,
		speedX = 0,
		speedY = 0,
		color = { 1, 1, 1 },
		targetColor = { 1, 1, 1 },
		colorLerpTimer = 0,
		colorLerpDuration = 0.5,
		glowRadius = 0,
		targetGlowRadius = 0,
		glowIntensity = 0,
		targetGlowIntensity = 0,
		lastHitPaddle = nil,
		lastSpeedX = 0,
		lastSpeedY = 0,
		wasStationary = true,
	}

	-- Left paddle (player)
	self.paddleLeft = {
		x = 50,
		y = 250,
		width = 20,
		height = 100,
		speed = 300,
		color = { 1, 1, 1 },
	}

	-- Right paddle (CPU)
	self.paddleRight = {
		x = 730,
		y = 250,
		width = 20,
		height = 100,
		speed = 250,
		color = { 1, 1, 1 },
	}

	-- Score and game state
	self.score = { player = 0, cpu = 0 }
	self.gameState = { playing = true, winner = nil, maxScore = 7 }
	self.serveDelay = { active = true, timer = 0, duration = 1.5, flashInterval = 0.25 }

	-- Screen shake state
	self.shake = {
		intensity = 0,
		maxIntensity = 5,
		duration = 0.2,
		timer = 0,
	}

	-- Ball trail state (polyline-based)
	self.ballTrailPoints = {}
	self.ballTrailLifetime = 1
	self.ballTrailWidthStart = 8
	self.ballTrailWidthEnd = 6

	-- Load custom font (scale based on viewport)
	local baseFontSize = 36
	local scale = viewport.scale or 1
	self.scoreFont = love.graphics.newFont("assets/myfont.ttf", math.floor(baseFontSize * scale))
	self.winFont = love.graphics.newFont("assets/myfont.ttf", math.floor(baseFontSize * 4 / 3 * scale))

	-- Load sound effects and music
	self.soundPaddle = love.audio.newSource("sounds/paddle_hit.wav", "static")
	self.soundWall = love.audio.newSource("sounds/wall_bounce.wav", "static")
	self.soundScore = love.audio.newSource("sounds/score.wav", "static")
	self.backgroundMusic = love.audio.newSource("sounds/background.mp3", "stream")
	self.backgroundMusic:setLooping(true)
	self.backgroundMusic:setVolume(0.5)
	self.backgroundMusic:play()

	-- Create particle texture for paddle sparks (8x8 white square as base)
	local canvas = love.graphics.newCanvas(8, 8)
	love.graphics.setCanvas(canvas)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.rectangle("fill", 0, 0, 8, 8)
	love.graphics.setCanvas()
	self.particleTexture = canvas

	-- Left paddle - Fast sparks
	self.particleLeftFast = love.graphics.newParticleSystem(self.particleTexture, 300)
	self.particleLeftFast:setEmissionRate(0)
	self.particleLeftFast:setParticleLifetime(0.1, 0.2)
	self.particleLeftFast:setDirection(0)
	self.particleLeftFast:setSpeed(300 * scale, 500 * scale)
	self.particleLeftFast:setSpread(math.pi / 2)
	self.particleLeftFast:setSizes(2 * scale, 0)
	self.particleLeftFast:setColors(1, 0, 1, 1, 0.5, 0, 1, 0)
	self.particleLeftFast:setLinearAcceleration(0, -150 * scale, 0, 150 * scale)
	self.particleLeftFast:setSpin(0, 5)

	-- Left paddle - Glow sparks
	self.particleLeftGlow = love.graphics.newParticleSystem(self.particleTexture, 150)
	self.particleLeftGlow:setEmissionRate(0)
	self.particleLeftGlow:setParticleLifetime(0.2, 0.3)
	self.particleLeftGlow:setDirection(0)
	self.particleLeftGlow:setSpeed(150 * scale, 300 * scale)
	self.particleLeftGlow:setSpread(math.pi / 2)
	self.particleLeftGlow:setSizes(3 * scale, 1.5 * scale)
	self.particleLeftGlow:setColors(0, 1, 1, 1, 1, 0.5, 0, 0.5)
	self.particleLeftGlow:setSpin(0, 6)
	self.particleLeftGlow:setLinearAcceleration(0, -100 * scale, 0, 100 * scale)

	-- Right paddle - Fast sparks
	self.particleRightFast = love.graphics.newParticleSystem(self.particleTexture, 300)
	self.particleRightFast:setEmissionRate(0)
	self.particleRightFast:setParticleLifetime(0.1, 0.2)
	self.particleRightFast:setDirection(math.pi)
	self.particleRightFast:setSpeed(300 * scale, 500 * scale)
	self.particleRightFast:setSpread(math.pi / 2)
	self.particleRightFast:setSizes(2 * scale, 0)
	self.particleRightFast:setColors(1, 0, 1, 1, 0.5, 0, 1, 0)
	self.particleRightFast:setLinearAcceleration(0, -150 * scale, 0, 150 * scale)
	self.particleRightFast:setSpin(0, 5)

	-- Right paddle - Glow sparks
	self.particleRightGlow = love.graphics.newParticleSystem(self.particleTexture, 150)
	self.particleRightGlow:setEmissionRate(0)
	self.particleRightGlow:setParticleLifetime(0.2, 0.3)
	self.particleRightGlow:setDirection(math.pi)
	self.particleRightGlow:setSpeed(150 * scale, 300 * scale)
	self.particleRightGlow:setSpread(math.pi / 2)
	self.particleRightGlow:setSizes(3 * scale, 1.5 * scale)
	self.particleRightGlow:setColors(0, 1, 1, 1, 1, 0.5, 0, 0.5)
	self.particleRightGlow:setSpin(0, 6)
	self.particleRightGlow:setLinearAcceleration(0, -100 * scale, 0, 100 * scale)
end

function GameScene:resetBall()
	self.ball.x, self.ball.y = 400, 300
	self.ball.speedX, self.ball.speedY = 0, 0
	self.ball.lastSpeedX, self.ball.lastSpeedY = 0, 0
	self.ball.wasStationary = true
	self.serveDelay.active = true
	self.serveDelay.timer = 0
	self.ball.lastHitPaddle = nil
	self.ball.color = { 1, 1, 1 }
	self.ball.targetColor = { 1, 1, 1 }
	self.ball.colorLerpTimer = 0
	self.ball.glowRadius = 0
	self.ball.targetGlowRadius = 0
	self.ball.glowIntensity = 0
	self.ball.targetGlowIntensity = 0
end

function GameScene:resetGame()
	self.score.player = 0
	self.score.cpu = 0
	self.paddleLeft.y = 250
	self.paddleRight.y = 250
	self:resetBall()
	self.gameState.playing = true
	self.gameState.winner = nil
	if not self.backgroundMusic:isPlaying() then
		self.backgroundMusic:play()
	end
end

function GameScene:startBall()
	local speed = 200
	local angle = love.math.random() * math.pi / 3 + math.pi / 9
	if love.math.random() < 0.5 then
		angle = angle + math.pi
	end
	self.ball.speedX = math.cos(angle) * speed
	self.ball.speedY = math.sin(angle) * speed
	self.serveDelay.active = false
end

function GameScene:update(dt)
	if not self.gameState.playing then
		if self.backgroundMusic:isPlaying() then
			self.backgroundMusic:pause()
		end
		return
	end

	self.ball.lastHitPaddle = nil

	if love.keyboard.isDown("up") then
		self.paddleLeft.y = self.paddleLeft.y - self.paddleLeft.speed * dt
	elseif love.keyboard.isDown("down") then
		self.paddleLeft.y = self.paddleLeft.y + self.paddleLeft.speed * dt
	end
	self.paddleLeft.y = math.max(0, math.min(600 - self.paddleLeft.height, self.paddleLeft.y))

	self.particleLeftFast:update(dt)
	self.particleLeftGlow:update(dt)
	self.particleRightFast:update(dt)
	self.particleRightGlow:update(dt)

	local speedMagnitude = math.sqrt(self.ball.speedX ^ 2 + self.ball.speedY ^ 2)
	if speedMagnitude > 0 then
		table.insert(self.ballTrailPoints, 1, { x = self.ball.x, y = self.ball.y, time = love.timer.getTime() })
	end
	local currentTime = love.timer.getTime()
	while
		#self.ballTrailPoints > 0
		and (currentTime - self.ballTrailPoints[#self.ballTrailPoints].time) > self.ballTrailLifetime
	do
		table.remove(self.ballTrailPoints, #self.ballTrailPoints)
	end

	if speedMagnitude > 0 and self.ball.wasStationary then
		self.ballTrailPoints = { { x = self.ball.x, y = self.ball.y, time = love.timer.getTime() } }
	end
	self.ball.wasStationary = (speedMagnitude == 0)

	local minSpeed = 200
	local maxSpeed = 500
	local t = math.min(math.max((speedMagnitude - minSpeed) / (maxSpeed - minSpeed), 0), 1)
	local targetR = 1
	local targetG = 1 - (0.1 * t)
	local targetB = 1 - t
	self.ball.targetColor = { targetR, targetG, targetB }
	self.ball.targetGlowRadius = 0 + (15 * t)
	self.ball.targetGlowIntensity = 0 + (0.5 * t)

	if self.ball.colorLerpTimer < self.ball.colorLerpDuration then
		self.ball.colorLerpTimer = self.ball.colorLerpTimer + dt
		local lerpT = math.min(self.ball.colorLerpTimer / self.ball.colorLerpDuration, 1)
		self.ball.color[1] = self.ball.color[1] + (targetR - self.ball.color[1]) * lerpT
		self.ball.color[2] = self.ball.color[2] + (targetG - self.ball.color[2]) * lerpT
		self.ball.color[3] = self.ball.color[3] + (targetB - self.ball.color[3]) * lerpT
		self.ball.glowRadius = self.ball.glowRadius + (self.ball.targetGlowRadius - self.ball.glowRadius) * lerpT
		self.ball.glowIntensity = self.ball.glowIntensity
			+ (self.ball.targetGlowIntensity - self.ball.glowIntensity) * lerpT
	else
		self.ball.color = { targetR, targetG, targetB }
		self.ball.glowRadius = self.ball.targetGlowRadius
		self.ball.glowIntensity = self.ball.targetGlowIntensity
	end

	if self.shake.timer > 0 then
		self.shake.timer = self.shake.timer - dt
		self.shake.intensity = self.shake.maxIntensity * (self.shake.timer / self.shake.duration)
		if self.shake.timer <= 0 then
			self.shake.intensity = 0
		end
	end

	if self.serveDelay.active then
		self.serveDelay.timer = self.serveDelay.timer + dt
		if self.serveDelay.timer >= self.serveDelay.duration then
			self:startBall()
		end
		return
	end

	local targetY = self.ball.y - self.paddleRight.height / 2
	if self.paddleRight.y + self.paddleRight.height / 2 < targetY then
		self.paddleRight.y = self.paddleRight.y + self.paddleRight.speed * dt
	elseif self.paddleRight.y + self.paddleRight.height / 2 > targetY then
		self.paddleRight.y = self.paddleRight.y - self.paddleRight.speed * dt
	end
	self.paddleRight.y = math.max(0, math.min(600 - self.paddleRight.height, self.paddleRight.y))

	self.ball.x = self.ball.x + self.ball.speedX * dt
	self.ball.y = self.ball.y + self.ball.speedY * dt

	if self.ball.y - self.ball.radius < 0 then
		self.ball.y = self.ball.radius
		self.ball.speedY = -self.ball.speedY
		love.audio.play(self.soundWall)
	elseif self.ball.y + self.ball.radius > 600 then
		self.ball.y = 600 - self.ball.radius
		self.ball.speedY = -self.ball.speedY
		love.audio.play(self.soundWall)
	end

	if self.ball.x < 0 then
		self.score.cpu = self.score.cpu + 1
		love.audio.play(self.soundScore)
		if self.score.cpu >= self.gameState.maxScore then
			self.gameState.playing = false
			self.gameState.winner = "cpu"
		else
			self:resetBall()
		end
	elseif self.ball.x > 800 then
		self.score.player = self.score.player + 1
		love.audio.play(self.soundScore)
		if self.score.player >= self.gameState.maxScore then
			self.gameState.playing = false
			self.gameState.winner = "player"
		else
			self:resetBall()
		end
	end

	if
		self.ball.lastHitPaddle == nil
		and self.ball.x - self.ball.radius <= self.paddleLeft.x + self.paddleLeft.width
		and self.ball.x + self.ball.radius >= self.paddleLeft.x
		and self.ball.y >= self.paddleLeft.y
		and self.ball.y <= self.paddleLeft.y + self.paddleLeft.height
	then
		self.ball.lastHitPaddle = "left"
		self.ball.x = self.paddleLeft.x + self.paddleLeft.width + self.ball.radius + 5
		local hitPos = (self.ball.y - self.paddleLeft.y) / self.paddleLeft.height
		local max_angle = math.pi / 4
		local bounce_angle = (hitPos - 0.5) * 2 * max_angle
		local current_speed = math.sqrt(self.ball.speedX ^ 2 + self.ball.speedY ^ 2)
		local new_speed = current_speed * 1.15
		self.ball.speedX = math.cos(bounce_angle) * new_speed
		self.ball.speedY = math.sin(bounce_angle) * new_speed
		love.audio.play(self.soundPaddle)
		self.particleLeftFast:setPosition(self.paddleLeft.x + self.paddleLeft.width, self.ball.y)
		self.particleLeftFast:emit(40)
		self.particleLeftGlow:setPosition(self.paddleLeft.x + self.paddleLeft.width, self.ball.y)
		self.particleLeftGlow:emit(3)
		self.shake.timer = self.shake.duration
		self.shake.intensity = self.shake.maxIntensity
		self.ball.colorLerpTimer = 0
	end

	if
		self.ball.lastHitPaddle == nil
		and self.ball.x + self.ball.radius >= self.paddleRight.x
		and self.ball.x - self.ball.radius <= self.paddleRight.x + self.paddleRight.width
		and self.ball.y >= self.paddleRight.y
		and self.ball.y <= self.paddleRight.y + self.paddleRight.height
	then
		self.ball.lastHitPaddle = "right"
		self.ball.x = self.paddleRight.x - self.ball.radius - 5
		local hitPos = (self.ball.y - self.paddleRight.y) / self.paddleRight.height
		local max_angle = math.pi / 4
		local bounce_angle = (hitPos - 0.5) * 2 * max_angle
		local current_speed = math.sqrt(self.ball.speedX ^ 2 + self.ball.speedY ^ 2)
		local new_speed = current_speed * 1.15
		self.ball.speedX = -math.cos(bounce_angle) * new_speed
		self.ball.speedY = math.sin(bounce_angle) * new_speed
		love.audio.play(self.soundPaddle)
		self.particleRightFast:setPosition(self.paddleRight.x, self.ball.y)
		self.particleRightFast:emit(40)
		self.particleRightGlow:setPosition(self.paddleRight.x, self.ball.y)
		self.particleRightGlow:emit(3)
		self.shake.timer = self.shake.duration
		self.shake.intensity = self.shake.maxIntensity
		self.ball.colorLerpTimer = 0
	end

	self.ball.lastSpeedX = self.ball.speedX
	self.ball.lastSpeedY = self.ball.speedY
end

function GameScene:keypressed(key)
	if not self.gameState.playing and key == "r" then
		self:resetGame()
	end
end

function GameScene:draw()
	local offsetX, offsetY = 0, 0
	if self.shake.intensity > 0 then
		offsetX = love.math.random(-self.shake.intensity, self.shake.intensity)
		offsetY = love.math.random(-self.shake.intensity, self.shake.intensity)
	end
	love.graphics.push()
	love.graphics.translate(offsetX, offsetY)

	-- Draw background image
	local bgHeight = 1024 -- Background image height
	local scale = 600 / bgHeight
	local bgWidth = 1536 -- Background image width
	local scaledWidth = bgWidth * scale
	local bgOffsetX = -(scaledWidth - 800) / 2
	love.graphics.setColor(1, 1, 1)
	love.graphics.draw(self.backgroundImage, bgOffsetX, 0, 0, scale, scale)

	if #self.ballTrailPoints > 1 then
		local currentTime = love.timer.getTime()
		for i = 1, #self.ballTrailPoints - 1 do
			local p1 = self.ballTrailPoints[i]
			local p2 = self.ballTrailPoints[i + 1]
			local age = currentTime - p2.time
			if age <= self.ballTrailLifetime then
				local fade = 1 - (age / self.ballTrailLifetime)
				local width = self.ballTrailWidthStart
					+ (self.ballTrailWidthEnd - self.ballTrailWidthStart) * (1 - fade)
				local r, g, b, a = 1, 0.9, 0, fade
				love.graphics.setColor(r, g, b, a)
				local dx = p2.x - p1.x
				local dy = p2.y - p1.y
				local length = math.sqrt(dx * dx + dy * dy)
				if length > 0 then
					dx = dx / length
					dy = dy / length
					local px = -dy * width / 2
					local py = dx * width / 2
					local x1, y1 = p1.x + px, p1.y + py
					local x2, y2 = p1.x - px, p1.y - py
					local x3, y3 = p2.x - px, p2.y - py
					local x4, y4 = p2.x + px, p2.y + py
					love.graphics.polygon("fill", x1, y1, x2, y2, x3, y3, x4, y4)
				end
			end
		end
	end

	if not self.serveDelay.active or math.floor(self.serveDelay.timer / self.serveDelay.flashInterval) % 2 == 0 then
		if self.ball.glowRadius > 0 and self.ball.glowIntensity > 0 then
			love.graphics.setBlendMode("add", "alphamultiply")
			local maxRadius = self.ball.radius + self.ball.glowRadius
			for r = self.ball.radius, maxRadius, 1 do
				local distance = r - self.ball.radius
				local t = distance / self.ball.glowRadius
				local alpha = self.ball.glowIntensity * (1 - t) * (1 - t)
				love.graphics.setColor(self.ball.color[1], self.ball.color[2], self.ball.color[3], alpha)
				love.graphics.circle("line", self.ball.x, self.ball.y, r)
			end
			love.graphics.setBlendMode("alpha")
		end
	end

	love.graphics.setColor(self.ball.color)
	if not self.serveDelay.active or math.floor(self.serveDelay.timer / self.serveDelay.flashInterval) % 2 == 0 then
		love.graphics.circle("fill", self.ball.x, self.ball.y, self.ball.radius)
	end

	love.graphics.setColor(self.paddleLeft.color)
	love.graphics.rectangle("fill", self.paddleLeft.x, self.paddleLeft.y, self.paddleLeft.width, self.paddleLeft.height)
	love.graphics.setColor(self.paddleRight.color)
	love.graphics.rectangle(
		"fill",
		self.paddleRight.x,
		self.paddleRight.y,
		self.paddleRight.width,
		self.paddleRight.height
	)

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(self.particleLeftFast)
	love.graphics.draw(self.particleLeftGlow)
	love.graphics.draw(self.particleRightFast)
	love.graphics.draw(self.particleRightGlow)

	love.graphics.setFont(self.scoreFont)
	love.graphics.setColor(0, 0, 0)
	love.graphics.print("Player: " .. self.score.player, 80 + 2, 40 + 2)
	love.graphics.setColor(1, 1, 1)
	love.graphics.print("Player: " .. self.score.player, 80, 40)
	local cpuScoreText = "CPU: " .. self.score.cpu
	local textWidth = self.scoreFont:getWidth(cpuScoreText)
	local cpuScoreX = 720 - textWidth
	love.graphics.setColor(0, 0, 0)
	love.graphics.print(cpuScoreText, cpuScoreX + 2, 40 + 2)
	love.graphics.setColor(1, 1, 1)
	love.graphics.print(cpuScoreText, cpuScoreX, 40)

	if not self.gameState.playing then
		love.graphics.setFont(self.winFont)
		local message = self.gameState.winner == "player" and "Player Wins!" or "CPU Wins!"
		love.graphics.print(message, 250, 250)
		love.graphics.setFont(self.scoreFont)
		love.graphics.print("Press R to Restart", 300, 350)
	end

	love.graphics.pop()
end

return GameScene

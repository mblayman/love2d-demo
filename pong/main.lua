-- Set up the game window and initial objects
function love.load()
	love.window.setTitle("Pong Clone")
	love.window.setMode(800, 600)

	-- Load background image
	backgroundImage = love.graphics.newImage("assets/background.png")

	-- Ball properties
	ball = {
		x = 400,
		y = 300,
		radius = 10,
		speedX = 0,
		speedY = 0,
		color = { 1, 1, 1 }, -- Current display color (starts white)
		targetColor = { 1, 1, 1 }, -- Target color based on speed (starts white)
		colorLerpTimer = 0, -- Timer for color interpolation
		colorLerpDuration = 0.5, -- Duration of color transition in seconds
		glowRadius = 0, -- Current glow radius (starts at 0)
		targetGlowRadius = 0, -- Target glow radius based on speed (starts at 0)
		glowIntensity = 0, -- Current glow intensity (starts at 0)
		targetGlowIntensity = 0, -- Target glow intensity based on speed (starts at 0)
		lastHitPaddle = nil,
		lastSpeedX = 0,
		lastSpeedY = 0,
		wasStationary = true,
	}

	-- Left paddle (player)
	paddleLeft = {
		x = 50,
		y = 250,
		width = 20,
		height = 100,
		speed = 300,
		color = { 1, 1, 1 },
	}

	-- Right paddle (CPU)
	paddleRight = {
		x = 730,
		y = 250,
		width = 20,
		height = 100,
		speed = 250,
		color = { 1, 1, 1 },
	}

	-- Score and game state
	score = { player = 0, cpu = 0 }
	gameState = { playing = true, winner = nil, maxScore = 7 }
	serveDelay = { active = true, timer = 0, duration = 1.5, flashInterval = 0.25 }

	-- Screen shake state
	shake = {
		intensity = 0,
		maxIntensity = 5,
		duration = 0.2,
		timer = 0,
	}

	-- Ball trail state (polyline-based)
	ballTrailPoints = {}
	ballTrailLifetime = 1
	ballTrailWidthStart = 8
	ballTrailWidthEnd = 6

	-- Load custom font
	scoreFont = love.graphics.newFont("assets/myfont.ttf", 36)
	winFont = love.graphics.newFont("assets/myfont.ttf", 48)

	-- Load sound effects and music
	soundPaddle = love.audio.newSource("sounds/paddle_hit.wav", "static")
	soundWall = love.audio.newSource("sounds/wall_bounce.wav", "static")
	soundScore = love.audio.newSource("sounds/score.wav", "static")
	backgroundMusic = love.audio.newSource("sounds/background.mp3", "stream")
	backgroundMusic:setLooping(true)
	backgroundMusic:setVolume(0.5)
	backgroundMusic:play()

	-- Create particle texture for paddle sparks (8x8 white square as base)
	local canvas = love.graphics.newCanvas(8, 8)
	love.graphics.setCanvas(canvas)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.rectangle("fill", 0, 0, 8, 8)
	love.graphics.setCanvas()
	particleTexture = canvas

	-- Left paddle - Fast sparks
	particleLeftFast = love.graphics.newParticleSystem(particleTexture, 300)
	particleLeftFast:setEmissionRate(0)
	particleLeftFast:setParticleLifetime(0.1, 0.2)
	particleLeftFast:setDirection(0)
	particleLeftFast:setSpeed(300, 500)
	particleLeftFast:setSpread(math.pi / 2)
	particleLeftFast:setSizes(2, 0)
	particleLeftFast:setColors(1, 0, 1, 1, 0.5, 0, 1, 0)
	particleLeftFast:setLinearAcceleration(0, -150, 0, 150)
	particleLeftFast:setSpin(0, 5)

	-- Left paddle - Glow sparks
	particleLeftGlow = love.graphics.newParticleSystem(particleTexture, 150)
	particleLeftGlow:setEmissionRate(0)
	particleLeftGlow:setParticleLifetime(0.2, 0.3)
	particleLeftGlow:setDirection(0)
	particleLeftGlow:setSpeed(150, 300)
	particleLeftGlow:setSpread(math.pi / 2)
	particleLeftGlow:setSizes(3, 1.5)
	particleLeftGlow:setColors(0, 1, 1, 1, 1, 0.5, 0, 0.5)
	particleLeftGlow:setSpin(0, 6)
	particleLeftGlow:setLinearAcceleration(0, -100, 0, 100)

	-- Right paddle - Fast sparks
	particleRightFast = love.graphics.newParticleSystem(particleTexture, 300)
	particleRightFast:setEmissionRate(0)
	particleRightFast:setParticleLifetime(0.1, 0.2)
	particleRightFast:setDirection(math.pi)
	particleRightFast:setSpeed(300, 500)
	particleRightFast:setSpread(math.pi / 2)
	particleRightFast:setSizes(2, 0)
	particleRightFast:setColors(1, 0, 1, 1, 0.5, 0, 1, 0)
	particleRightFast:setLinearAcceleration(0, -150, 0, 150)
	particleRightFast:setSpin(0, 5)

	-- Right paddle - Glow sparks
	particleRightGlow = love.graphics.newParticleSystem(particleTexture, 150)
	particleRightGlow:setEmissionRate(0)
	particleRightGlow:setParticleLifetime(0.2, 0.3)
	particleRightGlow:setDirection(math.pi)
	particleRightGlow:setSpeed(150, 300)
	particleRightGlow:setSpread(math.pi / 2)
	particleRightGlow:setSizes(3, 1.5)
	particleRightGlow:setColors(0, 1, 1, 1, 1, 0.5, 0, 0.5)
	particleRightGlow:setSpin(0, 6)
	particleRightGlow:setLinearAcceleration(0, -100, 0, 100)
end

-- Reset ball to center and start serve delay
function resetBall()
	ball.x, ball.y = 400, 300
	ball.speedX, ball.speedY = 0, 0
	ball.lastSpeedX, ball.lastSpeedY = 0, 0
	ball.wasStationary = true
	serveDelay.active = true
	serveDelay.timer = 0
	ball.lastHitPaddle = nil
	-- Reset color and glow
	ball.color = { 1, 1, 1 }
	ball.targetColor = { 1, 1, 1 }
	ball.colorLerpTimer = 0
	ball.glowRadius = 0
	ball.targetGlowRadius = 0
	ball.glowIntensity = 0
	ball.targetGlowIntensity = 0
end

-- Reset the entire game state
function resetGame()
	score.player = 0
	score.cpu = 0
	paddleLeft.y = 250
	paddleRight.y = 250
	resetBall()
	gameState.playing = true
	gameState.winner = nil
	if not backgroundMusic:isPlaying() then
		backgroundMusic:play()
	end
end

-- Start the ball with random direction
function startBall()
	local speed = 200
	local angle = love.math.random() * math.pi / 3 + math.pi / 9
	if love.math.random() < 0.5 then
		angle = angle + math.pi
	end
	ball.speedX = math.cos(angle) * speed
	ball.speedY = math.sin(angle) * speed
	serveDelay.active = false
end

-- Update game state
function love.update(dt)
	if not gameState.playing then
		if backgroundMusic:isPlaying() then
			backgroundMusic:pause()
		end
		return
	end

	ball.lastHitPaddle = nil

	if love.keyboard.isDown("up") then
		paddleLeft.y = paddleLeft.y - paddleLeft.speed * dt
	elseif love.keyboard.isDown("down") then
		paddleLeft.y = paddleLeft.y + paddleLeft.speed * dt
	end
	paddleLeft.y = math.max(0, math.min(600 - paddleLeft.height, paddleLeft.y))

	-- Update paddle particle systems
	particleLeftFast:update(dt)
	particleLeftGlow:update(dt)
	particleRightFast:update(dt)
	particleRightGlow:update(dt)

	-- Update ball trail (polyline-based)
	local speedMagnitude = math.sqrt(ball.speedX ^ 2 + ball.speedY ^ 2)
	if speedMagnitude > 0 then
		table.insert(ballTrailPoints, 1, { x = ball.x, y = ball.y, time = love.timer.getTime() })
	end
	local currentTime = love.timer.getTime()
	while #ballTrailPoints > 0 and (currentTime - ballTrailPoints[#ballTrailPoints].time) > ballTrailLifetime do
		table.remove(ballTrailPoints, #ballTrailPoints)
	end

	if speedMagnitude > 0 and ball.wasStationary then
		ballTrailPoints = { { x = ball.x, y = ball.y, time = love.timer.getTime() } }
	end
	ball.wasStationary = (speedMagnitude == 0)

	-- Update ball color and glow based on speed
	local minSpeed = 200
	local maxSpeed = 500
	local t = math.min(math.max((speedMagnitude - minSpeed) / (maxSpeed - minSpeed), 0), 1)
	-- Target color: white (1, 1, 1) to glowing yellow (1, 0.9, 0) to match the streamer
	local targetR = 1
	local targetG = 1 - (0.1 * t) -- 1 to 0.9
	local targetB = 1 - t -- 1 to 0
	ball.targetColor = { targetR, targetG, targetB }
	-- Target glow: radius from 0 to 15, intensity from 0 to 0.5
	ball.targetGlowRadius = 0 + (15 * t)
	ball.targetGlowIntensity = 0 + (0.5 * t)

	-- Interpolate color, glow radius, and intensity
	if ball.colorLerpTimer < ball.colorLerpDuration then
		ball.colorLerpTimer = ball.colorLerpTimer + dt
		local lerpT = math.min(ball.colorLerpTimer / ball.colorLerpDuration, 1)
		-- Interpolate color
		ball.color[1] = ball.color[1] + (targetR - ball.color[1]) * lerpT
		ball.color[2] = ball.color[2] + (targetG - ball.color[2]) * lerpT
		ball.color[3] = ball.color[3] + (targetB - ball.color[3]) * lerpT
		-- Interpolate glow radius and intensity
		ball.glowRadius = ball.glowRadius + (ball.targetGlowRadius - ball.glowRadius) * lerpT
		ball.glowIntensity = ball.glowIntensity + (ball.targetGlowIntensity - ball.glowIntensity) * lerpT
	else
		ball.color = { targetR, targetG, targetB }
		ball.glowRadius = ball.targetGlowRadius
		ball.glowIntensity = ball.targetGlowIntensity
	end

	if shake.timer > 0 then
		shake.timer = shake.timer - dt
		shake.intensity = shake.maxIntensity * (shake.timer / shake.duration)
		if shake.timer <= 0 then
			shake.intensity = 0
		end
	end

	if serveDelay.active then
		serveDelay.timer = serveDelay.timer + dt
		if serveDelay.timer >= serveDelay.duration then
			startBall()
		end
		return
	end

	local targetY = ball.y - paddleRight.height / 2
	if paddleRight.y + paddleRight.height / 2 < targetY then
		paddleRight.y = paddleRight.y + paddleRight.speed * dt
	elseif paddleRight.y + paddleRight.height / 2 > targetY then
		paddleRight.y = paddleRight.y - paddleRight.speed * dt
	end
	paddleRight.y = math.max(0, math.min(600 - paddleRight.height, paddleRight.y))

	ball.x = ball.x + ball.speedX * dt
	ball.y = ball.y + ball.speedY * dt

	if ball.y - ball.radius < 0 then
		ball.y = ball.radius
		ball.speedY = -ball.speedY
		love.audio.play(soundWall)
	elseif ball.y + ball.radius > 600 then
		ball.y = 600 - ball.radius
		ball.speedY = -ball.speedY
		love.audio.play(soundWall)
	end

	if ball.x < 0 then
		score.cpu = score.cpu + 1
		love.audio.play(soundScore)
		if score.cpu >= gameState.maxScore then
			gameState.playing = false
			gameState.winner = "cpu"
		else
			resetBall()
		end
	elseif ball.x > 800 then
		score.player = score.player + 1
		love.audio.play(soundScore)
		if score.player >= gameState.maxScore then
			gameState.playing = false
			gameState.winner = "player"
		else
			resetBall()
		end
	end

	if
		ball.lastHitPaddle == nil
		and ball.x - ball.radius <= paddleLeft.x + paddleLeft.width
		and ball.x + ball.radius >= paddleLeft.x
		and ball.y >= paddleLeft.y
		and ball.y <= paddleLeft.y + paddleLeft.height
	then
		ball.lastHitPaddle = "left"
		ball.x = paddleLeft.x + paddleLeft.width + ball.radius + 5
		local hitPos = (ball.y - paddleLeft.y) / paddleLeft.height
		local max_angle = math.pi / 4
		local bounce_angle = (hitPos - 0.5) * 2 * max_angle
		local current_speed = math.sqrt(ball.speedX ^ 2 + ball.speedY ^ 2)
		local new_speed = current_speed * 1.15
		ball.speedX = math.cos(bounce_angle) * new_speed
		ball.speedY = math.sin(bounce_angle) * new_speed
		love.audio.play(soundPaddle)
		particleLeftFast:setPosition(paddleLeft.x + paddleLeft.width, ball.y)
		particleLeftFast:emit(40)
		particleLeftGlow:setPosition(paddleLeft.x + paddleLeft.width, ball.y)
		particleLeftGlow:emit(3)
		shake.timer = shake.duration
		shake.intensity = shake.maxIntensity
		ball.colorLerpTimer = 0
	end

	if
		ball.lastHitPaddle == nil
		and ball.x + ball.radius >= paddleRight.x
		and ball.x - ball.radius <= paddleRight.x + paddleRight.width
		and ball.y >= paddleRight.y
		and ball.y <= paddleRight.y + paddleRight.height
	then
		ball.lastHitPaddle = "right"
		ball.x = paddleRight.x - ball.radius - 5
		local hitPos = (ball.y - paddleRight.y) / paddleRight.height
		local max_angle = math.pi / 4
		local bounce_angle = (hitPos - 0.5) * 2 * max_angle
		local current_speed = math.sqrt(ball.speedX ^ 2 + ball.speedY ^ 2)
		local new_speed = current_speed * 1.15
		ball.speedX = -math.cos(bounce_angle) * new_speed
		ball.speedY = math.sin(bounce_angle) * new_speed
		love.audio.play(soundPaddle)
		particleRightFast:setPosition(paddleRight.x, ball.y)
		particleRightFast:emit(40)
		particleRightGlow:setPosition(paddleRight.x, ball.y)
		particleRightGlow:emit(3)
		shake.timer = shake.duration
		shake.intensity = shake.maxIntensity
		ball.colorLerpTimer = 0
	end

	ball.lastSpeedX = ball.speedX
	ball.lastSpeedY = ball.speedY
end

-- Handle key presses for game restart
function love.keypressed(key)
	if not gameState.playing and key == "r" then
		resetGame()
	end
end

-- Draw the court
function love.draw()
	local offsetX, offsetY = 0, 0
	if shake.intensity > 0 then
		offsetX = love.math.random(-shake.intensity, shake.intensity)
		offsetY = love.math.random(-shake.intensity, shake.intensity)
	end
	love.graphics.push()
	love.graphics.translate(offsetX, offsetY)

	love.graphics.setBackgroundColor(0, 0, 0)
	local scale = 600 / 1024
	local scaledWidth = 1536 * scale
	local bgOffsetX = -(scaledWidth - 800) / 2
	love.graphics.draw(backgroundImage, bgOffsetX, 0, 0, scale, scale)

	if #ballTrailPoints > 1 then
		local currentTime = love.timer.getTime()
		for i = 1, #ballTrailPoints - 1 do
			local p1 = ballTrailPoints[i]
			local p2 = ballTrailPoints[i + 1]
			local age = currentTime - p2.time
			if age <= ballTrailLifetime then
				local fade = 1 - (age / ballTrailLifetime)
				local width = ballTrailWidthStart + (ballTrailWidthEnd - ballTrailWidthStart) * (1 - fade)
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

	-- Draw the glow effect around the ball
	-- Draw the glow effect around the ball with radial gradient
	if not serveDelay.active or math.floor(serveDelay.timer / serveDelay.flashInterval) % 2 == 0 then
		if ball.glowRadius > 0 and ball.glowIntensity > 0 then
			-- Set additive blend mode for a brighter, natural glow
			love.graphics.setBlendMode("add", "alphamultiply")

			-- Calculate the maximum radius of the glow
			local maxRadius = ball.radius + ball.glowRadius

			-- Draw concentric circle outlines
			for r = ball.radius, maxRadius, 1 do
				local distance = r - ball.radius
				local t = distance / ball.glowRadius
				-- Quadratic falloff for smooth fading
				local alpha = ball.glowIntensity * (1 - t) * (1 - t)
				love.graphics.setColor(ball.color[1], ball.color[2], ball.color[3], alpha)
				love.graphics.circle("line", ball.x, ball.y, r)
			end

			-- Reset blend mode to default for other drawings
			love.graphics.setBlendMode("alpha")
		end
	end

	-- Draw the ball on top of the glow
	love.graphics.setColor(ball.color)
	if not serveDelay.active or math.floor(serveDelay.timer / serveDelay.flashInterval) % 2 == 0 then
		love.graphics.circle("fill", ball.x, ball.y, ball.radius)
	end

	-- Draw the ball on top of the glow
	love.graphics.setColor(ball.color)
	if not serveDelay.active or math.floor(serveDelay.timer / serveDelay.flashInterval) % 2 == 0 then
		love.graphics.circle("fill", ball.x, ball.y, ball.radius)
	end

	love.graphics.setColor(paddleLeft.color)
	love.graphics.rectangle("fill", paddleLeft.x, paddleLeft.y, paddleLeft.width, paddleLeft.height)
	love.graphics.setColor(paddleRight.color)
	love.graphics.rectangle("fill", paddleRight.x, paddleRight.y, paddleRight.width, paddleRight.height)

	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(particleLeftFast)
	love.graphics.draw(particleLeftGlow)
	love.graphics.draw(particleRightFast)
	love.graphics.draw(particleRightGlow)

	love.graphics.setFont(scoreFont)
	love.graphics.setColor(0, 0, 0)
	love.graphics.print("Player: " .. score.player, 80 + 2, 40 + 2)
	love.graphics.setColor(1, 1, 1)
	love.graphics.print("Player: " .. score.player, 80, 40)
	local cpuScoreText = "CPU: " .. score.cpu
	local textWidth = scoreFont:getWidth(cpuScoreText)
	local cpuScoreX = 720 - textWidth
	love.graphics.setColor(0, 0, 0)
	love.graphics.print(cpuScoreText, cpuScoreX + 2, 40 + 2)
	love.graphics.setColor(1, 1, 1)
	love.graphics.print(cpuScoreText, cpuScoreX, 40)

	if not gameState.playing then
		love.graphics.setFont(winFont)
		local message = gameState.winner == "player" and "Player Wins!" or "CPU Wins!"
		love.graphics.print(message, 250, 250)
		love.graphics.setFont(scoreFont)
		love.graphics.print("Press R to Restart", 300, 350)
	end

	love.graphics.pop()
end

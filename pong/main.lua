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
		color = { 1, 1, 1 },
		lastHitPaddle = nil,
		lastSpeedX = 0, -- Track previous velocity for bounce detection
		lastSpeedY = 0,
		wasStationary = true, -- Track if the ball was stationary last frame
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
		intensity = 0, -- Current shake intensity (pixels)
		maxIntensity = 5, -- Max shake intensity when triggered
		duration = 0.2, -- Duration of shake in seconds
		timer = 0, -- Current time elapsed during shake
	}

	-- Ball trail state (polyline-based)
	ballTrailPoints = {} -- List of {x, y, time} points
	ballTrailLifetime = 1 -- Trail lifetime in seconds
	ballTrailWidthStart = 8 -- Starting width (near the ball)
	ballTrailWidthEnd = 6 -- Ending width (at the tail)

	-- Load custom font
	scoreFont = love.graphics.newFont("assets/myfont.ttf", 36) -- Custom font for scores
	winFont = love.graphics.newFont("assets/myfont.ttf", 48) -- Custom font for win message

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

	-- Left paddle - Fast sparks (larger, neon pink to purple, very fast, short-lived)
	particleLeftFast = love.graphics.newParticleSystem(particleTexture, 300)
	particleLeftFast:setEmissionRate(0)
	particleLeftFast:setParticleLifetime(0.1, 0.2) -- Very short lifetime
	particleLeftFast:setDirection(0) -- Right
	particleLeftFast:setSpeed(300, 500) -- Much faster speed
	particleLeftFast:setSpread(math.pi / 2) -- 90-degree spread
	particleLeftFast:setSizes(2, 0) -- Start at 16x16 (2 * 8), shrink to 0
	particleLeftFast:setColors(1, 0, 1, 1, 0.5, 0, 1, 0) -- Neon pink to purple
	particleLeftFast:setLinearAcceleration(0, -150, 0, 150) -- Stronger vertical drift
	particleLeftFast:setSpin(0, 5) -- Add spin for dynamic motion

	-- Left paddle - Glow sparks (larger, cyan to neon orange, fast, short-lived)
	particleLeftGlow = love.graphics.newParticleSystem(particleTexture, 150)
	particleLeftGlow:setEmissionRate(0)
	particleLeftGlow:setParticleLifetime(0.2, 0.3) -- Short lifetime
	particleLeftGlow:setDirection(0) -- Right
	particleLeftGlow:setSpeed(150, 300) -- Faster speed
	particleLeftGlow:setSpread(math.pi / 2) -- 90-degree spread
	particleLeftGlow:setSizes(3, 1.5) -- Start at 24x24 (3 * 8), shrink to 12x12
	particleLeftGlow:setColors(0, 1, 1, 1, 1, 0.5, 0, 0.5) -- Cyan to neon orange
	particleLeftGlow:setSpin(0, 6) -- Aggressive spin
	particleLeftGlow:setLinearAcceleration(0, -100, 0, 100) -- Vertical drift

	-- Right paddle - Fast sparks (larger, neon pink to purple, very fast, short-lived)
	particleRightFast = love.graphics.newParticleSystem(particleTexture, 300)
	particleRightFast:setEmissionRate(0)
	particleRightFast:setParticleLifetime(0.1, 0.2)
	particleRightFast:setDirection(math.pi) -- Left
	particleRightFast:setSpeed(300, 500)
	particleRightFast:setSpread(math.pi / 2)
	particleRightFast:setSizes(2, 0)
	particleRightFast:setColors(1, 0, 1, 1, 0.5, 0, 1, 0)
	particleRightFast:setLinearAcceleration(0, -150, 0, 150)
	particleRightFast:setSpin(0, 5)

	-- Right paddle - Glow sparks (larger, cyan to neon orange, fast, short-lived)
	particleRightGlow = love.graphics.newParticleSystem(particleTexture, 150)
	particleRightGlow:setEmissionRate(0)
	particleRightGlow:setParticleLifetime(0.2, 0.3)
	particleRightGlow:setDirection(math.pi) -- Left
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
	-- Do not clear ballTrailPoints; let the existing trail fade out naturally
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
	-- Add current position to trail if the ball is moving
	if speedMagnitude > 0 then
		table.insert(ballTrailPoints, 1, { x = ball.x, y = ball.y, time = love.timer.getTime() })
	end
	-- Remove points older than the lifetime
	local currentTime = love.timer.getTime()
	while #ballTrailPoints > 0 and (currentTime - ballTrailPoints[#ballTrailPoints].time) > ballTrailLifetime do
		table.remove(ballTrailPoints, #ballTrailPoints)
	end

	-- Check if the ball started moving (from stationary to moving)
	if speedMagnitude > 0 and ball.wasStationary then
		-- Clear the trail to prevent particles from appearing before the start
		ballTrailPoints = { { x = ball.x, y = ball.y, time = love.timer.getTime() } }
	end
	ball.wasStationary = (speedMagnitude == 0)

	-- Update screen shake
	if shake.timer > 0 then
		shake.timer = shake.timer - dt
		-- Linearly decay intensity over the duration
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
		-- Emit particles at the point of contact
		particleLeftFast:setPosition(paddleLeft.x + paddleLeft.width, ball.y)
		particleLeftFast:emit(40) -- 40 fast sparks
		particleLeftGlow:setPosition(paddleLeft.x + paddleLeft.width, ball.y)
		particleLeftGlow:emit(3) -- 3 glow sparks
		-- Trigger screen shake
		shake.timer = shake.duration
		shake.intensity = shake.maxIntensity
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
		-- Emit particles at the point of contact
		particleRightFast:setPosition(paddleRight.x, ball.y)
		particleRightFast:emit(40) -- 40 fast sparks
		particleRightGlow:setPosition(paddleRight.x, ball.y)
		particleRightGlow:emit(3) -- 3 glow sparks
		-- Trigger screen shake
		shake.timer = shake.duration
		shake.intensity = shake.maxIntensity
	end

	-- Update previous velocity (no longer needed for direction change detection but kept for potential future use)
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
	-- Apply screen shake by translating the entire scene
	local offsetX, offsetY = 0, 0
	if shake.intensity > 0 then
		-- Random offset within the current intensity
		offsetX = love.math.random(-shake.intensity, shake.intensity)
		offsetY = love.math.random(-shake.intensity, shake.intensity)
	end
	love.graphics.push()
	love.graphics.translate(offsetX, offsetY)

	-- Draw background image, scaled to fill height and cropped horizontally
	love.graphics.setBackgroundColor(0, 0, 0)
	local scale = 600 / 1024
	local scaledWidth = 1536 * scale
	local bgOffsetX = -(scaledWidth - 800) / 2
	love.graphics.draw(backgroundImage, bgOffsetX, 0, 0, scale, scale)

	-- Draw ball trail (polyline-based)
	if #ballTrailPoints > 1 then
		local currentTime = love.timer.getTime()
		for i = 1, #ballTrailPoints - 1 do
			local p1 = ballTrailPoints[i]
			local p2 = ballTrailPoints[i + 1]
			-- Calculate the age of the segment (use the older point's time)
			local age = currentTime - p2.time
			if age <= ballTrailLifetime then
				-- Calculate fade factor (0 at tail, 1 at head)
				local fade = 1 - (age / ballTrailLifetime)
				-- Interpolate width
				local width = ballTrailWidthStart + (ballTrailWidthEnd - ballTrailWidthStart) * (1 - fade)
				-- Set color to glowing yellow with fading alpha
				local r, g, b, a = 1, 0.9, 0, fade -- Glowing yellow (1, 0.9, 0) fading to transparent
				love.graphics.setColor(r, g, b, a)
				-- Calculate direction and length of the segment
				local dx = p2.x - p1.x
				local dy = p2.y - p1.y
				local length = math.sqrt(dx * dx + dy * dy)
				if length > 0 then
					-- Normalize direction
					dx = dx / length
					dy = dy / length
					-- Calculate perpendicular vector for width
					local px = -dy * width / 2
					local py = dx * width / 2
					-- Define the four corners of the rectangle
					local x1, y1 = p1.x + px, p1.y + py
					local x2, y2 = p1.x - px, p1.y - py
					local x3, y3 = p2.x - px, p2.y - py
					local x4, y4 = p2.x + px, p2.y + py
					-- Draw the segment as a filled polygon
					love.graphics.polygon("fill", x1, y1, x2, y2, x3, y3, x4, y4)
				end
			end
		end
	end

	-- Draw game elements
	love.graphics.setColor(paddleLeft.color)
	love.graphics.rectangle("fill", paddleLeft.x, paddleLeft.y, paddleLeft.width, paddleLeft.height)
	love.graphics.setColor(paddleRight.color)
	love.graphics.rectangle("fill", paddleRight.x, paddleRight.y, paddleRight.width, paddleRight.height)
	love.graphics.setColor(ball.color)
	if not serveDelay.active or math.floor(serveDelay.timer / serveDelay.flashInterval) % 2 == 0 then
		love.graphics.circle("fill", ball.x, ball.y, ball.radius)
	end

	-- Draw paddle impact particles (on top of paddles and ball)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(particleLeftFast)
	love.graphics.draw(particleLeftGlow)
	love.graphics.draw(particleRightFast)
	love.graphics.draw(particleRightGlow)

	-- Draw scores with shadow effect
	love.graphics.setFont(scoreFont)
	-- Player score with shadow
	love.graphics.setColor(0, 0, 0)
	love.graphics.print("Player: " .. score.player, 80 + 2, 40 + 2)
	love.graphics.setColor(1, 1, 1)
	love.graphics.print("Player: " .. score.player, 80, 40)
	-- CPU score with shadow
	local cpuScoreText = "CPU: " .. score.cpu
	local textWidth = scoreFont:getWidth(cpuScoreText)
	local cpuScoreX = 720 - textWidth
	love.graphics.setColor(0, 0, 0)
	love.graphics.print(cpuScoreText, cpuScoreX + 2, 40 + 2)
	love.graphics.setColor(1, 1, 1)
	love.graphics.print(cpuScoreText, cpuScoreX, 40)

	-- Draw win message
	if not gameState.playing then
		love.graphics.setFont(winFont)
		local message = gameState.winner == "player" and "Player Wins!" or "CPU Wins!"
		love.graphics.print(message, 250, 250)
		love.graphics.setFont(scoreFont)
		love.graphics.print("Press R to Restart", 300, 350)
	end

	-- End the translation
	love.graphics.pop()
end

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

	-- Create particle texture (8x8 white square as base)
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
	serveDelay.active = true
	serveDelay.timer = 0
	ball.lastHitPaddle = nil
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

	-- Update particle systems
	particleLeftFast:update(dt)
	particleLeftGlow:update(dt)
	particleRightFast:update(dt)
	particleRightGlow:update(dt)

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
		particleLeftFast:emit(40) -- Increased to 40 fast sparks
		particleLeftGlow:setPosition(paddleLeft.x + paddleLeft.width, ball.y)
		particleLeftGlow:emit(3) -- Increased to 20 glow sparks
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
		particleRightFast:emit(40) -- Increased to 40 fast sparks
		particleRightGlow:setPosition(paddleRight.x, ball.y)
		particleRightGlow:emit(3) -- Increased to 20 glow sparks
	end
end

-- Handle key presses for game restart
function love.keypressed(key)
	if not gameState.playing and key == "r" then
		resetGame()
	end
end

-- Draw the court
function love.draw()
	-- Draw background image, scaled to fill height and cropped horizontally
	love.graphics.setBackgroundColor(0, 0, 0)
	local scale = 600 / 1024
	local scaledWidth = 1536 * scale
	local offsetX = -(scaledWidth - 800) / 2
	love.graphics.draw(backgroundImage, offsetX, 0, 0, scale, scale)

	-- Draw game elements
	love.graphics.setColor(ball.color)
	if not serveDelay.active or math.floor(serveDelay.timer / serveDelay.flashInterval) % 2 == 0 then
		love.graphics.circle("fill", ball.x, ball.y, ball.radius)
	end
	love.graphics.setColor(paddleLeft.color)
	love.graphics.rectangle("fill", paddleLeft.x, paddleLeft.y, paddleLeft.width, paddleLeft.height)
	love.graphics.setColor(paddleRight.color)
	love.graphics.rectangle("fill", paddleRight.x, paddleRight.y, paddleRight.width, paddleRight.height)

	-- Draw particles
	love.graphics.setColor(1, 1, 1, 1) -- Reset to white to avoid tinting
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
end

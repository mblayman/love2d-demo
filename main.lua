-- Set up the game window and initial objects
function love.load()
	-- Configure the window
	love.window.setTitle("Pong Clone")
	love.window.setMode(800, 600) -- Court size: 800x600 pixels

	-- Ball properties
	ball = {
		x = 400, -- Center of court (800 / 2)
		y = 300, -- Center of court (600 / 2)
		radius = 10, -- Ball size
		speedX = 0, -- Start stationary
		speedY = 0, -- Start stationary
		color = { 1, 1, 1 }, -- White color (RGB)
	}

	-- Left paddle properties (player-controlled)
	paddleLeft = {
		x = 50, -- 50 pixels from left edge
		y = 250, -- Start near vertical center
		width = 20, -- Paddle width
		height = 100, -- Paddle height
		speed = 300, -- Pixels per second
		color = { 1, 1, 1 }, -- White color (RGB)
	}

	-- Right paddle properties (CPU-controlled)
	paddleRight = {
		x = 730, -- 50 pixels from right edge (800 - 50 - 20)
		y = 250, -- Start near vertical center
		width = 20, -- Paddle width
		height = 100, -- Paddle height
		speed = 250, -- Pixels per second
		color = { 1, 1, 1 }, -- White color (RGB)
	}

	-- Score tracking
	score = {
		player = 0, -- Left paddle (player)
		cpu = 0, -- Right paddle (CPU)
	}

	-- Set up font for score display
	scoreFont = love.graphics.newFont(24) -- Font size 24
	winFont = love.graphics.newFont(48) -- Larger font for win message

	-- Serve delay properties
	serveDelay = {
		active = true, -- Start with delay for initial serve
		timer = 0, -- Current time in delay
		duration = 1.5, -- Delay duration in seconds
		flashInterval = 0.25, -- Flash toggle every 0.25 seconds
	}

	-- Game state
	gameState = {
		playing = true, -- Whether the game is active
		winner = nil, -- "player" or "cpu" when game ends
		maxScore = 7, -- Score needed to win
	}

	-- Load sound effects
	soundPaddle = love.audio.newSource("sounds/paddle_hit.wav", "static")
	soundWall = love.audio.newSource("sounds/wall_bounce.wav", "static")
	soundScore = love.audio.newSource("sounds/score.wav", "static")
end

-- Reset ball to center and start serve delay
function resetBall()
	ball.x = 400 -- Center of court
	ball.y = 300
	ball.speedX = 0 -- Stationary during delay
	ball.speedY = 0
	serveDelay.active = true -- Start delay
	serveDelay.timer = 0 -- Reset timer
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
end

-- Start the ball with random direction
function startBall()
	local speed = 200 -- Total speed (pixels per second)
	local angle = love.math.random() * math.pi / 3 + math.pi / 9 -- Random angle between 20° and 70°
	if love.math.random() < 0.5 then
		angle = angle + math.pi -- Mirror to left side (200° to 250°) 50% of the time
	end
	ball.speedX = math.cos(angle) * speed
	ball.speedY = math.sin(angle) * speed
	serveDelay.active = false -- End delay
end

-- Update game state
function love.update(dt)
	-- Skip gameplay updates if game is over
	if not gameState.playing then
		return
	end

	-- Move left paddle (player) based on arrow key input
	if love.keyboard.isDown("up") then
		paddleLeft.y = paddleLeft.y - paddleLeft.speed * dt
	end
	if love.keyboard.isDown("down") then
		paddleLeft.y = paddleLeft.y + paddleLeft.speed * dt
	end

	-- Keep left paddle within court bounds
	if paddleLeft.y < 0 then
		paddleLeft.y = 0
	elseif paddleLeft.y + paddleLeft.height > 600 then
		paddleLeft.y = 600 - paddleLeft.height
	end

	-- Handle serve delay
	if serveDelay.active then
		serveDelay.timer = serveDelay.timer + dt
		if serveDelay.timer >= serveDelay.duration then
			startBall() -- Start ball after delay
		end
		return -- Skip ball movement, CPU movement, and collisions during delay
	end

	-- Move right paddle (CPU) to track ball
	local targetY = ball.y - paddleRight.height / 2
	if paddleRight.y + paddleRight.height / 2 < targetY then
		paddleRight.y = paddleRight.y + paddleRight.speed * dt
	elseif paddleRight.y + paddleRight.height / 2 > targetY then
		paddleRight.y = paddleRight.y - paddleRight.speed * dt
	end

	-- Keep right paddle within court bounds
	if paddleRight.y < 0 then
		paddleRight.y = 0
	elseif paddleRight.y + paddleRight.height > 600 then
		paddleRight.y = 600 - paddleRight.height
	end

	-- Move ball
	ball.x = ball.x + ball.speedX * dt
	ball.y = ball.y + ball.speedY * dt

	-- Bounce off top and bottom court edges
	if ball.y - ball.radius < 0 then
		ball.y = ball.radius
		ball.speedY = -ball.speedY
		love.audio.play(soundWall) -- Play wall bounce sound
	elseif ball.y + ball.radius > 600 then
		ball.y = 600 - ball.radius
		ball.speedY = -ball.speedY
		love.audio.play(soundWall) -- Play wall bounce sound
	end

	-- Handle left/right court edges (scoring)
	if ball.x < 0 then
		-- Ball passed left edge: CPU scores
		score.cpu = score.cpu + 1
		love.audio.play(soundScore) -- Play score sound
		if score.cpu >= gameState.maxScore then
			gameState.playing = false
			gameState.winner = "cpu"
		else
			resetBall()
		end
	elseif ball.x > 800 then
		-- Ball passed right edge: Player scores
		score.player = score.player + 1
		love.audio.play(soundScore) -- Play score sound
		if score.player >= gameState.maxScore then
			gameState.playing = false
			gameState.winner = "player"
		else
			resetBall()
		end
	end

	-- Paddle collision detection
	-- Left paddle
	if
		ball.x - ball.radius <= paddleLeft.x + paddleLeft.width
		and ball.x + ball.radius >= paddleLeft.x
		and ball.y >= paddleLeft.y
		and ball.y <= paddleLeft.y + paddleLeft.height
	then
		-- Ball hit left paddle
		ball.x = paddleLeft.x + paddleLeft.width + ball.radius
		ball.speedX = -ball.speedX * 1.1
		local hitPos = (ball.y - paddleLeft.y) / paddleLeft.height
		local maxAngle = 300
		ball.speedY = (hitPos - 0.5) * 2 * maxAngle
		love.audio.play(soundPaddle) -- Play paddle hit sound
	end

	-- Right paddle
	if
		ball.x + ball.radius >= paddleRight.x
		and ball.x - ball.radius <= paddleRight.x + paddleRight.width
		and ball.y >= paddleRight.y
		and ball.y <= paddleRight.y + paddleRight.height
	then
		-- Ball hit right paddle
		ball.x = paddleRight.x - ball.radius
		ball.speedX = -ball.speedX * 1.1
		local hitPos = (ball.y - paddleRight.y) / paddleRight.height
		local maxAngle = 300
		ball.speedY = (hitPos - 0.5) * 2 * maxAngle
		love.audio.play(soundPaddle) -- Play paddle hit sound
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
	-- Set background color to black
	love.graphics.setBackgroundColor(0, 0, 0)

	-- Draw the net (dashed centerline)
	love.graphics.setColor(1, 1, 1) -- White
	local dashHeight = 20 -- Height of each dash
	local gapHeight = 20 -- Gap between dashes
	local x = 400 -- Center of court
	for y = 0, 600 - dashHeight, dashHeight + gapHeight do
		love.graphics.rectangle("fill", x - 2, y, 4, dashHeight) -- 4x20 rectangles
	end

	-- Draw the ball (flash during serve delay)
	love.graphics.setColor(ball.color)
	if not serveDelay.active or math.floor(serveDelay.timer / serveDelay.flashInterval) % 2 == 0 then
		love.graphics.circle("fill", ball.x, ball.y, ball.radius)
	end

	-- Draw the left paddle
	love.graphics.setColor(paddleLeft.color)
	love.graphics.rectangle("fill", paddleLeft.x, paddleLeft.y, paddleLeft.width, paddleLeft.height)

	-- Draw the right paddle
	love.graphics.setColor(paddleRight.color)
	love.graphics.rectangle("fill", paddleRight.x, paddleRight.y, paddleRight.width, paddleRight.height)

	-- Draw the scores
	love.graphics.setColor(1, 1, 1) -- White text
	love.graphics.setFont(scoreFont)
	love.graphics.print("Player: " .. score.player, 50, 20)
	love.graphics.print("CPU: " .. score.cpu, 650, 20)

	-- Draw win message if game is over
	if not gameState.playing then
		love.graphics.setFont(winFont)
		local message = gameState.winner == "player" and "Player Wins!" or "CPU Wins!"
		love.graphics.print(message, 250, 250) -- Centered horizontally, middle of court
		love.graphics.setFont(scoreFont)
		love.graphics.print("Press R to Restart", 300, 350) -- Below win message
	end
end

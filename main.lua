function love.load()
	love.window.setTitle("Pong Clone")
	love.window.setMode(800, 600)

	-- Ball properties
	ball = {
		x = 400,
		y = 300,
		radius = 10,
		speedX = 0,
		speedY = 0,
		color = { 1, 1, 1 },
		lastHitPaddle = nil, -- Prevents multiple collisions per frame
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

	-- Fonts and sounds (assumed to be available)
	scoreFont = love.graphics.newFont(24)
	winFont = love.graphics.newFont(48)
	soundPaddle = love.audio.newSource("sounds/paddle_hit.wav", "static")
	soundWall = love.audio.newSource("sounds/wall_bounce.wav", "static")
	soundScore = love.audio.newSource("sounds/score.wav", "static")
end

function resetBall()
	ball.x, ball.y = 400, 300
	ball.speedX, ball.speedY = 0, 0
	serveDelay.active = true
	serveDelay.timer = 0
	ball.lastHitPaddle = nil
end

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

function love.update(dt)
	if not gameState.playing then
		return
	end

	-- Reset collision flag each frame
	ball.lastHitPaddle = nil

	-- Player paddle movement
	if love.keyboard.isDown("up") then
		paddleLeft.y = paddleLeft.y - paddleLeft.speed * dt
	elseif love.keyboard.isDown("down") then
		paddleLeft.y = paddleLeft.y + paddleLeft.speed * dt
	end
	paddleLeft.y = math.max(0, math.min(600 - paddleLeft.height, paddleLeft.y))

	-- Serve delay
	if serveDelay.active then
		serveDelay.timer = serveDelay.timer + dt
		if serveDelay.timer >= serveDelay.duration then
			startBall()
		end
		return
	end

	-- CPU paddle movement
	local targetY = ball.y - paddleRight.height / 2
	if paddleRight.y + paddleRight.height / 2 < targetY then
		paddleRight.y = paddleRight.y + paddleRight.speed * dt
	elseif paddleRight.y + paddleRight.height / 2 > targetY then
		paddleRight.y = paddleRight.y - paddleRight.speed * dt
	end
	paddleRight.y = math.max(0, math.min(600 - paddleRight.height, paddleRight.y))

	-- Ball movement
	ball.x = ball.x + ball.speedX * dt
	ball.y = ball.y + ball.speedY * dt

	-- Wall bounces
	if ball.y - ball.radius < 0 then
		ball.y = ball.radius
		ball.speedY = -ball.speedY
		love.audio.play(soundWall)
	elseif ball.y + ball.radius > 600 then
		ball.y = 600 - ball.radius
		ball.speedY = -ball.speedY
		love.audio.play(soundWall)
	end

	-- Scoring
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

	-- Left paddle collision
	if
		ball.lastHitPaddle == nil
		and ball.x - ball.radius <= paddleLeft.x + paddleLeft.width
		and ball.x + ball.radius >= paddleLeft.x
		and ball.y >= paddleLeft.y
		and ball.y <= paddleLeft.y + paddleLeft.height
	then
		ball.lastHitPaddle = "left"
		ball.x = paddleLeft.x + paddleLeft.width + ball.radius + 5 -- Buffer to prevent sticking
		local hitPos = (ball.y - paddleLeft.y) / paddleLeft.height
		local max_angle = math.pi / 4 -- 45° max bounce angle
		local bounce_angle = (hitPos - 0.5) * 2 * max_angle
		local current_speed = math.sqrt(ball.speedX ^ 2 + ball.speedY ^ 2)
		local new_speed = current_speed * 1.15 -- 15% speed increase
		ball.speedX = math.cos(bounce_angle) * new_speed -- Rightward
		ball.speedY = math.sin(bounce_angle) * new_speed
		love.audio.play(soundPaddle)
	end

	-- Right paddle collision
	if
		ball.lastHitPaddle == nil
		and ball.x + ball.radius >= paddleRight.x
		and ball.x - ball.radius <= paddleRight.x + paddleRight.width
		and ball.y >= paddleRight.y
		and ball.y <= paddleRight.y + paddleRight.height
	then
		ball.lastHitPaddle = "right"
		ball.x = paddleRight.x - ball.radius - 5 -- Buffer to prevent sticking
		local hitPos = (ball.y - paddleRight.y) / paddleRight.height
		local max_angle = math.pi / 4 -- 45° max bounce angle
		local bounce_angle = (hitPos - 0.5) * 2 * max_angle
		local current_speed = math.sqrt(ball.speedX ^ 2 + ball.speedY ^ 2)
		local new_speed = current_speed * 1.15 -- 15% speed increase
		ball.speedX = -math.cos(bounce_angle) * new_speed -- Leftward
		ball.speedY = math.sin(bounce_angle) * new_speed
		love.audio.play(soundPaddle)
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

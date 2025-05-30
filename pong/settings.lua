-- settings.lua
local Settings = {}

Settings.difficulties = {
	normal = {
		name = "Normal",
		backgroundImagePath = "assets/background.png",
		cpuPaddleColor = { 1, 0.9, 0 }, -- Yellow
		paddleSpeedPlayer = 300,
		paddleSpeedCPU = 250,
		ballInitialSpeed = 200,
		ballSpeedMultiplier = 1.15,
		playerPaddleHeight = 100, -- Standard paddle height
		maxScore = 7,
		ballTailColor = { 1, 0.9, 0 }, -- Yellow
		ballTargetGlowColor = { 1, 0.9, 0 }, -- Yellow
	},
	hard = {
		name = "Hard",
		backgroundImagePath = "assets/background_hard.png",
		cpuPaddleColor = { 1, 0, 0 }, -- Vibrant blood red
		paddleSpeedPlayer = 300,
		paddleSpeedCPU = 400,
		ballInitialSpeed = 250, -- Increased for faster start
		ballSpeedMultiplier = 1.25, -- Increased for faster acceleration
		playerPaddleHeight = 50, -- 50% smaller than normal
		maxScore = 7,
		ballTailColor = { 1, 0, 0 }, -- Vibrant red
		ballTargetGlowColor = { 1, 0, 0 }, -- Vibrant red
	},
}

return Settings

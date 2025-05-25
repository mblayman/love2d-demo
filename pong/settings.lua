-- settings.lua
local Settings = {}

Settings.difficulties = {
	normal = {
		name = "Normal",
		backgroundImagePath = "assets/background.png",
		cpuPaddleColor = { 1, 1, 1 }, -- White
		paddleSpeedPlayer = 300,
		paddleSpeedCPU = 250,
		ballInitialSpeed = 200,
		ballSpeedMultiplier = 1.15,
		maxScore = 7,
	},
	hard = {
		name = "Hard",
		backgroundImagePath = "assets/background_hard.png",
		cpuPaddleColor = { 1, 0, 0 }, -- Vibrant blood red
		paddleSpeedPlayer = 300,
		paddleSpeedCPU = 250,
		ballInitialSpeed = 200,
		ballSpeedMultiplier = 1.15,
		maxScore = 7,
	},
}

return Settings

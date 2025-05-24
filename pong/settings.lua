-- settings.lua
local Settings = {}

Settings.difficulties = {
	normal = {
		name = "Normal",
		backgroundImagePath = "assets/background.png",
		-- Placeholder for future settings
		paddleSpeedPlayer = 300,
		paddleSpeedCPU = 250,
		ballInitialSpeed = 200,
		ballSpeedMultiplier = 1.15,
		maxScore = 7,
	},
	hard = {
		name = "Hard",
		backgroundImagePath = "assets/background_hard.png",
		-- Placeholder for future settings (same as normal for now)
		paddleSpeedPlayer = 300,
		paddleSpeedCPU = 250,
		ballInitialSpeed = 200,
		ballSpeedMultiplier = 1.15,
		maxScore = 7,
	},
}

return Settings

function love.load()
	-- Hide the mouse cursor
	love.mouse.setVisible(false)

	-- Create a softer particle image (16x16, more diffuse)
	local imgData = love.image.newImageData(16, 16)
	imgData:mapPixel(function(x, y)
		-- Create a softer, circular particle
		local dx, dy = x - 8, y - 8
		local dist = math.sqrt(dx * dx + dy * dy)
		if dist < 8 then
			local alpha = math.max(0, 1 - (dist / 8)) ^ 2
			return 1, 1, 1, alpha -- White with smooth transparency
		end
		return 0, 0, 0, 0 -- Transparent
	end)
	local particleImage = love.graphics.newImage(imgData)

	-- Initialize particle system
	particleSystem = love.graphics.newParticleSystem(particleImage, 200)

	-- Configure particle system for smoke
	particleSystem:setParticleLifetime(3, 5)
	particleSystem:setEmissionRate(20)
	particleSystem:setSpeed(20, 50)
	particleSystem:setSpread(math.pi / 2)
	particleSystem:setDirection(3 * math.pi / 2) -- Upward
	particleSystem:setSizes(1, 3)
	particleSystem:setSizeVariation(0.5)
	particleSystem:setColors(0.7, 0.7, 0.7, 0.5, 0.6, 0.6, 0.6, 0)
	particleSystem:setLinearAcceleration(0, -20, 0, -10)
	particleSystem:setSpin(0, 1)
	particleSystem:setSpinVariation(0.5)
	particleSystem:setTangentialAcceleration(-10, 10)
	particleSystem:setEmissionArea("uniform", 30, 10) -- 60x20px area

	-- Set emitter to center of screen
	local mx, my = love.graphics.getWidth() / 2, love.graphics.getHeight() / 2
	particleSystem:setPosition(mx, my)

	-- Define a simple pixel shader for a reddish glow
	shaderCode = [[
        extern float glow_intensity = 0.3; // Glow strength
        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
            vec4 pixel = Texel(texture, texture_coords) * color; // Get particle color
            if (pixel.a > 0.0) {
                // Add a reddish tint and glow based on alpha
                pixel.rgb += vec3(0.5, 0.2, 0.1) * pixel.a * glow_intensity;
                pixel.rgb = clamp(pixel.rgb, 0.0, 1.0); // Prevent oversaturation
            }
            return pixel;
        }
    ]]
	shader = love.graphics.newShader(shaderCode)
end

function love.update(dt)
	-- Update particle system
	particleSystem:update(dt)
end

function love.draw()
	-- Apply shader to particle system
	love.graphics.setShader(shader)
	love.graphics.draw(particleSystem, 0, 0)
	-- Reset shader for other drawings (if any)
	love.graphics.setShader()
end

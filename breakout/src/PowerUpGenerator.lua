--[[
    GD50
    Breakout Remake

    -- Power-Up Generator Class --

    Author: Rodrigo Garcia
    roderikout@gmail.com

    Manager of the power ups. It decides if, which or when to
    spawn power-ups
]]

PowerUpGenerator = Class{}

function PowerUpGenerator:init()

	self.timeForPowerUp = math.random(5 , 8) --seconds

	self.isTime = false

	self.timerCounting = true

	self.powerUps = {}

	self.powerUp = PowerUp()

	self.maxPowerUps = 1

	self.paddle = {}

end

function PowerUpGenerator:isTimeForPowerUp(time)

	if time > 0 and time % self.timeForPowerUp == 0 and #self.powerUps < self.maxPowerUps then
		self.isTime = true
		self.timeForPowerUp = math.random(15, 35)
	end

	return self.isTime

end

function PowerUpGenerator:spawnPowerUp(x, y)
	local x = x or math.random(20, VIRTUAL_WIDTH - 20)
	local y = y or 20
	if #self.powerUps < self.maxPowerUps then
			table.insert(self.powerUps, PowerUp((x - self.powerUp.width / 2) , y, 1, math.random(40, 50)))
			self.isTime = false
	end
end

function PowerUpGenerator:update(dt)
	for k, powerup in pairs(self.powerUps) do
		powerup:update(dt)
		if powerup.y >= VIRTUAL_HEIGHT then
			table.remove(self.powerUps, k)
		end
	end
end

function PowerUpGenerator:render()
	for k, powerup in pairs(self.powerUps) do
		powerup:render()
	end
end

function PowerUpGenerator:collides(paddle)
	for k, powerup in pairs(self.powerUps) do
		if powerup:collides(paddle) then
			table.remove(self.powerUps, k)
			return true
		end
	end
end
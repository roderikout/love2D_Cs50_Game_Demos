--[[
    GD50
    Breakout Remake

    -- Power Up Class --

    Author: Rodrigo Garcia
    roderikout@gmail.com

    Represent a power up type on the screen. They appear randomly and
    produce different kinds of special powers for the player advantage.
    They need to be cathched or collide with the paddle to made effect.
]]

PowerUp = Class{}

function PowerUp:init(x, y)
    --types of power-ups, momentarly there is only one type, 1, that is
    --for putting two new balls in play at the same time
    self.type = 1

    self.x = x
    self.y = y
    self.width = 16
    self.height = 16

    self.dy = 20

    gSounds['confirm']:stop()
    gSounds['confirm']:play()

end

function PowerUp:collides(target)
    -- first, check to see if the left edge of either is inside the right
    -- of the right edge of the other and to the top or the bottom
    if (self.x + self.width < target.x or target.x + target.width < self.x) then
        return false
    end

    if (self.y + self.height < target.y or target.y + target.height < self.y) then
        return false
    end
    
    gSounds['victory']:stop()
    gSounds['victory']:play()
    return true
end

function PowerUp:update(dt)
    self.y = self.y + self.dy * dt
end

function PowerUp:render()
    -- gTexture is our global texture for all blocks
    -- gPowerUpFrames is a table of quads mapping to each individual ball skin in the texture
    love.graphics.draw(gTextures['main'], gFrames['powerups'][self.type],
        self.x, self.y)

end
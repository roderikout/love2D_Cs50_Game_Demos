--[[
    GD50
    Breakout Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents the state of the game in which we are actively playing;
    player should control the paddle, with the ball actively bouncing between
    the bricks, walls, and the paddle. If the ball goes below the paddle, then
    the player should lose one point of health and be taken either to the Game
    Over screen if at 0 health or the Serve screen otherwise.
]]

PlayState = Class{__includes = BaseState}

--[[
    We initialize what's in our PlayState via a state table that we pass between
    states as we go from playing to serving.
]]
function PlayState:enter(params)
    self.paddle = params.paddle
    self.bricks = params.bricks
    self.health = params.health
    self.score = params.score
    self.highScores = params.highScores
    self.ball = params.ball
    self.level = params.level

    self.recoverPoints = params.recoverPoints

    -- give ball random starting velocity
    self.ball.dx = math.random(-200, 200)
    self.ball.dy = math.random(-50, -60)

    -- power up table and maximum number
    self.powerUp = PowerUp(0,0,1,0)
    self.powerUps = {}
    self.numPowerUps = 1  --maximum of powerUps in screen at once
    self.powerUpType = 1 
    self.powerUpDy = 20  --velocity of powerUps falling
    self.isPowerUpActive = false

    --Types of powerUps:
    --1: add balls to maximum 3 balls in play
    self.powerUpNumberOfBalls = 3
    self.ballsInGame = {self.ball}
    self.paddleOriginalSkin = self.paddle.skin

    --power up timer and flags
    self.timer = 0
    self.secondsToPowerUp = math.random(3, 5)
    self.isBrickForPowerUp = false --ask a brick if its hitted after seconds passed
    self.waitingForBrick = false  --announce brick that power up is waiting for position info
    self.brickToPowerUpPositionX = 0
    self.brickToPowerUpPositionY = 0
end

function PlayState:update(dt)

    if not self.isPowerUpActive then 
        self.timer = self.timer + dt --timer for power up
    else
        self.timer = 0
    end

    if self.paused then
        if love.keyboard.wasPressed('space') then
            self.paused = false
            gSounds['pause']:play()
        else
            return
        end
    elseif love.keyboard.wasPressed('space') then
        self.paused = true
        gSounds['pause']:play()
        return
    end

    --power up conditions
    if self.timer > self.secondsToPowerUp then
        self.waitingForBrick = true --time is passed now i'm waiting for brick position info
        if self.isBrickForPowerUp then --ask if I have the last hitted position info
            if #self.powerUps < self.numPowerUps then
                self.powerUp.x = self.brickToPowerUpPositionX - self.powerUp.width / 2
                self.powerUp.y = self.brickToPowerUpPositionY - self.powerUp.height / 2
                self.powerUp.type = self.powerUpType
                self.powerUp.dy = self.powerUpDy
                table.insert(self.powerUps, self.powerUp)
                self.waitingForBrick = false 
                self.isBrickForPowerUp = false
            end
        end
    end
    -- update positions based on velocity
    self.paddle:update(dt)

    --remove power ups when collide with paddle and active it or only remove it when exit the screen
    for k, powerUp in pairs(self.powerUps) do
         if powerUp:collides(self.paddle) then
            table.remove(self.powerUps, k)
            self.timer = 0
            self.waitingForBrick = false
            self.isBrickForPowerUp = false
            self.isPowerUpActive = true
            for i = 1, self.powerUpNumberOfBalls - #self.ballsInGame, 1 do
                local ballToInsert = Ball()
                ballToInsert.skin = math.random(7)
                ballToInsert.x = math.random(20, VIRTUAL_WIDTH - 20)
                ballToInsert.y = math.random(10, VIRTUAL_HEIGHT / 2)
                ballToInsert.dx = math.random(-200, 200)
                ballToInsert.dy = math.random(-50, -60) 
                table.insert(self.ballsInGame, ballToInsert)
            end
         elseif powerUp.y > VIRTUAL_HEIGHT then
            table.remove(self.powerUps, k)
        end
        powerUp:update(dt)
    end

    for k, ball in pairs(self.ballsInGame) do
        ball:update(dt)

        --Nuevo rebote usando tecnica de noooway

        if ball:collides(self.paddle) then
            --Nuevo rebote usando tecnica de noooway
            local ball_collides, shift_ball_x, shift_ball_y, min_shift
            ball_collides, shift_ball_x, shift_ball_y = ball:collides(self.paddle)

            min_shift = math.min(math.abs(shift_ball_x), math.abs(shift_ball_y))

            if math.abs(shift_ball_x) == min_shift then
                shift_ball_y = 0
            else
                shift_ball_x = 0
            end


            -- raise ball above paddle in case it goes below it, then reverse dy or the same for x and dx
            ball.x = ball.x + shift_ball_x
            ball.y = ball.y + shift_ball_y

            if shift_ball_x ~= 0 then
                ball.dx = -ball.dx
            end
            if shift_ball_y ~= 0 then
                ball.dy = -ball.dy
            end
            --
            -- tweak angle of bounce based on where it hits the paddle
            --
            -- if we hit the paddle on its left side while moving left...
            if ball.x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
                ball.dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - ball.x))
            
            -- else if we hit the paddle on its right side while moving right...
            elseif ball.x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
                ball.dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - ball.x))
            end

            gSounds['paddle-hit']:play()
        end

        -- detect collision across all bricks with the ball
        for k, brick in pairs(self.bricks) do

            -- only check collision if we're in play
            if brick.inPlay and ball:collides(brick) then

                --power up is waiting for brick's position info
                if self.waitingForBrick and not self.isPowerUpActive then
                    self.brickToPowerUpPositionX = brick.x + brick.width / 2
                    self.brickToPowerUpPositionY = brick.y + brick.height / 2
                    self.isBrickForPowerUp = true
                end

                -- add to score
                self.score = self.score + (brick.tier * 200 + brick.color * 25)

                -- trigger the brick's hit function, which removes it from play
                brick:hit()

                 -- if we have enough points, recover a point of health
                if self.score > self.recoverPoints then
                    -- can't go above 3 health
                    self.health = math.min(3, self.health + 1)

                    -- multiply recover points by 2
                    self.recoverPoints = math.min(100000, self.recoverPoints * 2)

                    -- play recover sound effect
                    gSounds['recover']:play()
                end

                -- go to our victory screen if there are no more bricks left
                if self:checkVictory() then
                    gSounds['victory']:play()

                    gStateMachine:change('victory', {
                        level = self.level,
                        paddle = self.paddle,
                        health = self.health,
                        score = self.score,
                        highScores = self.highScores,
                        ball = ball,
                        recoverPoints = self.recoverPoints
                    })
                end

                --
                -- collision code for bricks

                --Nuevo rebote usando tecnica de noooway
                local ball_collides, shift_ball_x, shift_ball_y, min_shift
                ball_collides, shift_ball_x, shift_ball_y = ball:collides(brick)

                min_shift = math.min(math.abs(shift_ball_x), math.abs(shift_ball_y))

                if math.abs(shift_ball_x) == min_shift then
                    shift_ball_y = 0
                else
                    shift_ball_x = 0
                end

                -- raise ball above paddle in case it goes below it, then reverse dy or the same for x and dx
                ball.x = ball.x + shift_ball_x
                ball.y = ball.y + shift_ball_y

                if shift_ball_x ~= 0 then
                    ball.dx = -ball.dx
                end
                if shift_ball_y ~= 0 then
                    ball.dy = -ball.dy
                end

                -- slightly scale the y velocity to speed up the game, capping at +- 150
                if math.abs(ball.dy) < 150 then
                    ball.dy = ball.dy * 1.02
                end

                -- only allow colliding with one brick, for corners
                break
            end
        end

        -- if ball goes below bounds, revert to serve state and decrease health
        if ball.y >= VIRTUAL_HEIGHT then
            table.remove(self.ballsInGame, k)
            if #self.ballsInGame < 1 then
                self.health = self.health - 1
                gSounds['hurt']:play()
            elseif #self.ballsInGame == 1 then
                self.isPowerUpActive = false
                self.timer = 0
                self.secondsToPowerUp = math.random(3, 5)
            end

            if self.health == 0 then
                gStateMachine:change('game-over', {
                    score = self.score,
                    highScores = self.highScores,
                })
            elseif self.health > 0 and #self.ballsInGame < 1 then
                --self.paddle.skin = self.paddleOriginalSkin
                gStateMachine:change('serve', {
                    paddle = self.paddle,
                    bricks = self.bricks,
                    health = self.health,
                    score = self.score,
                    highScores = self.highScores,
                    level = self.level,
                    recoverPoints = self.recoverPoints
                })
            end
            --
            -- collision code for bricks
            --
            --Nuevo rebote usando tecnica de noooway
            local ball_collides, shift_ball_x, shift_ball_y, min_shift
            ball_collides, shift_ball_x, shift_ball_y = self.ball:collides(brick)

            min_shift = math.min(math.abs(shift_ball_x), math.abs(shift_ball_y))

            if math.abs(shift_ball_x) == min_shift then
                shift_ball_y = 0
            else
                shift_ball_x = 0
            end


            -- raise ball above paddle in case it goes below it, then reverse dy or the same for x and dx
            self.ball.x = self.ball.x + shift_ball_x
            self.ball.y = self.ball.y + shift_ball_y

            if shift_ball_x ~= 0 then
                self.ball.dx = -self.ball.dx
            end
            if shift_ball_y ~= 0 then
                self.ball.dy = -self.ball.dy
            end

            -- slightly scale the y velocity to speed up the game, capping at +- 150
            if math.abs(self.ball.dy) < 150 then
                self.ball.dy = self.ball.dy * 1.02
            end

            -- only allow colliding with one brick, for corners
            break
        end
    end

    -- if ball goes below bounds, revert to serve state and decrease health
    if self.ball.y >= VIRTUAL_HEIGHT then
        self.health = self.health - 1
        gSounds['hurt']:play()

        if self.health == 0 then
            gStateMachine:change('game-over', {
                score = self.score,
                highScores = self.highScores,
            })
        else
            gStateMachine:change('serve', {
                paddle = self.paddle,
                bricks = self.bricks,
                health = self.health,
                score = self.score,
                highScores = self.highScores,
                level = self.level,
                recoverPoints = self.recoverPoints
            })
        end
    end

    -- for rendering particle systems
    for k, brick in pairs(self.bricks) do
        brick:update(dt)
    end

    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
end

function PlayState:render()
    -- render bricks
    for k, brick in pairs(self.bricks) do
        brick:render()
    end

    -- render all particle systems
    for k, brick in pairs(self.bricks) do
        brick:renderParticles()
    end

    self.paddle:render()
    for k, ball in pairs(self.ballsInGame) do
        ball:render()
    end

    --self:displayDebugging()

    --rendering power ups
    for k, powerUp in pairs(self.powerUps) do
        powerUp:render()
    end

    renderScore(self.score)
    renderHealth(self.health)
    renderLevel(self.level)
    renderHighScore(self.highScores)

    -- pause text, if paused
    if self.paused then
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
    end
end

function PlayState:checkVictory()
    for k, brick in pairs(self.bricks) do
        if brick.inPlay then
            return false
        end 
    end

    return true
end


function PlayState:displayDebugging()
    love.graphics.setFont(gFonts['small'])
    love.graphics.setColor(0, 255, 0, 255)
    love.graphics.print('Balls in game: ' .. tostring(#self.ballsInGame), 5, 5)
    love.graphics.setColor(255, 255, 255, 255)
end
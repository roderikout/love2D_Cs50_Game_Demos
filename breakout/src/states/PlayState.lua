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

    -- timers for whatever (power-ups for example)
    self.timerPowerUps = 0

    -- Power-Up vars
    self.powerUpGenerator = PowerUpGenerator()
    self.isPowerUpTime = false
    self.scoreNow = 0
    self.isPowerUpActive = false

    --balls vars
    self.balls = {self.ball}
    self.maxBalls = 3
end

function PlayState:update(dt)

    --power-up timer
    self.timerPowerUps = self.timerPowerUps + dt

    --is time for power-up to spawn?
    self.isPowerUpTime = self.powerUpGenerator:isTimeForPowerUp(math.floor(self.timerPowerUps))

    --other moments for power-up to spawn
    if self.score > self.scoreNow and self.score % 175 == 0 and self.timerPowerUps > 10 and not self.isPowerUpActive then
        self.powerUpGenerator:spawnPowerUp()
        self.scoreNow = self.score
    end

    --is power-up colliding with paddle to be active?
    if self.powerUpGenerator:collides(self.paddle) then
        self.isPowerUpActive = true
        for i = 1, self.maxBalls - #self.balls, 1 do
            local ball = Ball(math.random(7))
            ball.x = math.random(20, VIRTUAL_WIDTH - 20)
            ball.y = math.random(20, VIRTUAL_HEIGHT / 2)
            ball.dx = math.random(-200, 200)
            ball.dy = math.random(-50, -60) 
            table.insert(self.balls, ball)
        end
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

    -- update positions based on velocity
    self.paddle:update(dt)

    -- BALLS
    for k, ball in pairs(self.balls) do
        ball:update(dt)

        --Nuevo rebote usando tecnica de noooway

        if ball:collides(self.paddle) then
            --Nuevo rebote con paddle usando tecnica de noooway
            local ball_collides, shift_ball_x, shift_ball_y, min_shift
            ball_collides, shift_ball_x, shift_ball_y = ball:collides(self.paddle)

            min_shift = math.min(math.abs(shift_ball_x), math.abs(shift_ball_y))

            if math.abs(shift_ball_x) == min_shift then
                shift_ball_y = 0
            else
                shift_ball_x = 0
            end

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

                --add power up at brick position
                if self.isPowerUpTime and not self.isPowerUpActive then
                    self.powerUpGenerator:spawnPowerUp(brick.x + brick.width / 2, brick.y + brick.height / 2)
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
                --
                --Nuevo rebote de ball con brick usando tecnica de noooway
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
            table.remove(self.balls, k)
            if #self.balls < 1 then
                self.health = self.health - 1
                gSounds['hurt']:play()
            elseif #self.balls == 1 then
                self.isPowerUpActive = false
                self.timerPowerUps = 0
            end

            if self.health == 0 then
                gStateMachine:change('game-over', {
                    score = self.score,
                    highScores = self.highScores,
                })
            elseif #self.balls < 1 then
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
    end
    -- for rendering particle systems
    for k, brick in pairs(self.bricks) do
        brick:update(dt)
    end

    --rendering Power Ups
    self.powerUpGenerator:update(dt)

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
    for k, ball in pairs(self.balls) do
        ball:render()
    end

    self.powerUpGenerator:render()

    renderScore(self.score)
    renderHealth(self.health)
    renderLevel(self.level)
    renderHighScore(self.highScores)

    -- pause text, if paused
    if self.paused then
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
    end

    --Display debuggers
     displayDebug(15, 'Is pUp active: ', self.isPowerUpActive)
     --displayDebug(25, 'Timer: ', math.floor(self.timerPowerUps))
     --displayDebug(30, 'Time4PUp: ', self.powerUpGenerator.timeForPowerUp)
end

function PlayState:checkVictory()
    for k, brick in pairs(self.bricks) do
        if brick.inPlay then
            return false
        end 
    end

    return true
end
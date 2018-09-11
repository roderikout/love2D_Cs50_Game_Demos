--[[
    GD50 2018
    Pong Remake
    
    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Originally programmed by Atari in 1972. Features two
    paddles, controlled by players, with the goal of getting
    the ball past your opponent's edge. First to 10 points wins.

    This version is built to more closely resemble the NES than
    the original Pong machines or the Atari 2600 in terms of
    resolution, though in widescreen (16:9) so it looks nicer on 
    modern systems.
]]

-- Changes by Roderikout since 19/08/2018

-- push is a library that will allow us to draw our game at a virtual
-- resolution, instead of however large our window is; used to provide
-- a more retro aesthetic
--
-- https://github.com/Ulydev/push
push = require 'push'

--the "Class" library we're using will allow us to represent anything in
--our game as code, rather than keeping track o many disparate variables 
--and methods
--
--https://github.com/vrld/hump/blob/master/class.lua
Class = require 'class'

--our Paddle class, which stores position and dimensions for each paddle
--and the logic for rendering them
require 'Paddle'

--our Ball class, which isn't much different than a Paddle structure-wise
--but which will mechanicallly function very differently
require 'Ball'

WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243

-- speed at which we will move our paddle: multiplied by dt in update
PADDLE_SPEED = 200

--[[
    Runs when the game first starts up, only once; used to initialize the game.
]]
function love.load()
    -- use nearest-neighbor filtering on upscaling and downscaling to prevent blurring of text 
    -- and graphics; try removing this function to see the difference!
    love.graphics.setDefaultFilter('nearest', 'nearest')

    --set the title of our application window
    love.window.setTitle('Pong')

    -- "seed" the Random Number Generator RNG so that calls to random are always random
    -- use the current time, since that will vary on startup every time
    math.randomseed(os.time())

    -- more "retro-looking" font object we can use for any text
    smallFont = love.graphics.newFont('font.ttf', 8)

    largeFont = love.graphics.newFont('font.ttf', 16)

    -- larger font for drawing the score on the screen
    scoreFont = love.graphics.newFont('font.ttf', 32)

    --set Love2D active font to smallFont
    love.graphics.setFont(smallFont)

    -- initialize our virtual resolution, which will be rendered within our
    -- actual window no matter its dimensions; replaces our love.window.setMode call
    -- from the last example
    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        resizable = false,
        vsync = true
        })

    -- initialize score variables, used for rendering on the screen and keeping
    -- track of the winner
    player1Score = 0
    player2Score = 0

    -- either going to be 1 or 2; whomever is scored on gets to serve the
    -- following turn
    servingPlayer = 1

    --set the amount of points to win
    winningPoints = 3

    -- paddle positions on the Y axis (they can only move up or down)
    player1= Paddle(10,30, 5, 20)
    player2= Paddle(VIRTUAL_WIDTH - 10, VIRTUAL_HEIGHT - 30, 5, 20)

    -- velocity and position variables for our ball when play starts
    ball = Ball(VIRTUAL_WIDTH / 2 - 2, VIRTUAL_HEIGHT / 2 - 2, 4, 4)

    --game state variable used to transition between different parts of the game
    --(used for beginning, menus, main game, high score list, etc.)
    -- we will use this to determine behavior during render and update
    gameState = 'start'

end

--[[
    Runs every frame, with "dt" passed in, our delta in seconds 
    since the last frame, which LÖVE2D supplies us.
]]
function love.update(dt)
    if gameState == 'serve' then 
        -- before switching to play, initialize ball's velocity based
        -- on player who last scored
        ball.dy = math.random(-50, 50)
        if servingPlayer == 1 then 
            ball.dx = math.random(140, 200)
        else
            ball.dx = -math.random(140, 200)
        end
    elseif gameState == 'play' then 
        -- detect ball collision with paddles, reversing dx if true and
        --slightly increasing it, then altering the dy based on the position of the ball

        if ball:collides(player1) then 
            ball.dx = - ball.dx * 1.03
            ball.x = player1.x + 5

            -- keep velocity going in the same direction, but randomize it
            if ball.dy < 0 then 
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end
        end

        if ball:collides(player2) then 
            ball.dx = - ball.dx * 1.03
            ball.x = player2.x - 4

            -- keep velocity going in the same direction, but randomize it
            if ball.dy < 0 then 
                ball.dy = -math.random(10, 150)
            else
                ball.dy = math.random(10, 150)
            end
        end

        --detect upper and lower boundary collision and reverse direction if collides
        if ball.y <= 0 then 
            ball.y = 0
            ball.dy = -ball.dy 
        end

        -- -4 to account for the ball's size
        if ball.y >= VIRTUAL_HEIGHT - 4 then 
            ball.y = VIRTUAL_HEIGHT - 4
            ball.dy = - ball.dy 
        end

        --if we reach the left or right edge of the screen,
        -- go back to start and update the score

        if ball.x + 4 < 0 then 
            servingPlayer = 1
            player2Score = player2Score + 1 

            --if we've reached a score of winningPoints, the game is over; set the
            --state to done so we can show the victory message
            if player2Score == winningPoints then 
                winningPlayer = 2
                gameState = 'done'
            else
                gameState = 'serve'
                ball:reset()
            end
        end

        if ball.x > VIRTUAL_WIDTH then
            servingPlayer = 2
            player1Score = player1Score + 1

            --if we've reached a score of winningPoints, the game is over; set the
            --state to done so we can show the victory message
            if player1Score == winningPoints then 
                winningPlayer = 1
                gameState = 'done'
            else
                gameState = 'serve'
                ball:reset()
            end
        end
    end


    --player 1 movement
    if love.keyboard.isDown('w') then
        player1.dy = -PADDLE_SPEED
    elseif love.keyboard.isDown('s') then
       player1.dy = PADDLE_SPEED
    else
        player1.dy = 0
    end

    --player 2 movement
    if love.keyboard.isDown('up') then 
        player2.dy = -PADDLE_SPEED
    elseif love.keyboard.isDown('down') then 
        player2.dy = PADDLE_SPEED
    else
        player2.dy = 0
    end

    --update our ball based on its DX and DY only if we're in play state;
    --scale the velocity by dt so movement is framerate-independent
    if gameState == 'play' then 
       ball:update(dt)
    end

    player1:update(dt)
    player2:update(dt)
end

--[[
    Keyboard handling, called by LÖVE2D each frame; 
    passes in the key we pressed so we can access.
]]
function love.keypressed(key)
    -- keys can be accessed by string name
    if key == 'escape' then 
        -- function LÖVE gives us to terminate application
        love.event.quit()
    -- if we presw enter during the start state of the game, we'll go into play state
    -- during play mode, the ball will move in a random direction
    elseif key == 'enter' or key == 'return' then 
        if gameState == 'start' then
            gameState = 'serve'
        elseif gameState == 'serve' then
            gameState = 'play'
        elseif gameState == 'done' then 
            --game is simply in a restart phase here, but set the serving ball
            -- player to the opponent of whomever won, for fairness!
            gameState = 'serve'

            ball:reset()

            --reset scores to 0
            player1Score = 0
            player2Score = 0

            --decide serving player as the opposite of who won
            if winningPlayer == 1 then 
                servingPlayer = 2
            else
                servingPlayer = 1
            end
        end
    end
end


--[[
    Called after update by LÖVE2D, used to draw anything to the screen, updated or otherwise.
]]
function love.draw()
    push:apply('start')

    --clear the screen with a specific color; in this case, a color similar
    --to some versions of the original Pong
    love.graphics.clear(40, 45, 53, 255)

    -- condensed onto one line from las example
    -- note we are now using virtual width top of the screen for text placement
    love.graphics.setFont(smallFont)

    displayScore()

    if gameState == 'start' then 
        love.graphics.setFont(smallFont)
        love.graphics.printf('Welcome to Pong!', 0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('Press Enter to begin!', 0, 20, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'serve' then
        love.graphics.setFont(smallFont)
        love.graphics.printf('Player ' .. tostring(servingPlayer) .. "'s serve!", 
            0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.printf('Press Enter to serve!', 0, 20, VIRTUAL_WIDTH, 'center')
    elseif gameState == 'play' then
        -- no UI messages to display in play
    elseif gameState == 'done' then 
        --UI messages
        love.graphics.setFont(largeFont)
        love.graphics.printf('Player ' .. tostring(winningPlayer) .. ' wins!', 0, 10, VIRTUAL_WIDTH, 'center')
        love.graphics.setFont(smallFont)
        love.graphics.printf('Press Enter to restart!', 0, 30, VIRTUAL_WIDTH, 'center')
    end
    
    --paddles are simply rectangles we draw on the screen at certain points,
    --as is the ball

    --render first paddle (left side)
    player1:render()

    --render second paddle (right side)
    player2:render()

    --render ball (center)
    ball:render()

    -- new function just to demostrate how to see FPS in Love2D
    displayFPS()

    -- end rendering at virtual resolution
    push:apply('end')
end

--render the current FPS

function displayFPS()
    --simple FPS display across all states
    love.graphics.setFont(smallFont)
    love.graphics.setColor(0, 255, 0, 255)
    love.graphics.print('FPS: ' .. tostring(love.timer.getFPS()), 10, 10)
end

--displays the score to the screen

function displayScore()
    -- draw score on the left and right center of the screen
    -- need to switch font to draw before actually printing
    love.graphics.setFont(scoreFont)
    love.graphics.print(tostring(player1Score), VIRTUAL_WIDTH / 2 - 50, 
        VIRTUAL_HEIGHT / 3)
    love.graphics.print(tostring(player2Score), VIRTUAL_WIDTH / 2 + 30,
        VIRTUAL_HEIGHT / 3)
end
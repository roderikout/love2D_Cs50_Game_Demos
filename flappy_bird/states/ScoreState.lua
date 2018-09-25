--[[
    ScoreState Class
    Author: Colton Ogden
    Modifyed by: Rodrigo García, roderikout
    cogden@cs50.harvard.edu

    A simple state used to display the player's score before they
    transition back into the play state. Transitioned to from the
    PlayState when they collide with a Pipe.
]]

ScoreState = Class{__includes = BaseState}

--[[
    When we enter the score state, we expect to receive the score
    from the play state so we know what to render to the State.
]]

function ScoreState:init()
	self.trophies = {
        ['first'] = love.graphics.newImage('trophies/trophy_icon.png'),
        ['second'] = love.graphics.newImage('trophies/trophy_silver_icon.png'),
        ['third'] = love.graphics.newImage('trophies/trophy_3_icon.png')
    }

    self.pointsThirdTrophy = 2
    self.pointsSecondTrophy = 4
    self.pointsFirstTrophy = 6

    scrolling = false
    isPausable = false
end

function ScoreState:enter(params)
	self.score = params.score
end

function ScoreState:update(dt)
	-- go back to play if enter is pressed
	if love.keyboard.wasPressed('enter') or love.keyboard.wasPressed('return') then
		gStateMachine:change('countdown')
	end
end

function ScoreState:render()
	-- simply render the score to the middle of the screen
	love.graphics.setFont(flappyFont)
	love.graphics.printf('Oof!, You lost!', 0, 64, VIRTUAL_WIDTH, 'center')

	love.graphics.setFont(mediumFont)
	love.graphics.printf('Score: ' .. tostring(self.score), 0, 100, VIRTUAL_WIDTH, 'center')

	love.graphics.printf('Press Enter to Play Again!', 0, 140, VIRTUAL_WIDTH, 'center')

	if self.score >= self.pointsFirstTrophy then
		love.graphics.printf(tostring(self.score) .. ' pipes passed, you earn a trophy', 0, 180, VIRTUAL_WIDTH, 'center')
		love.graphics.draw(self.trophies['first'], VIRTUAL_WIDTH / 2 - self.trophies['first']:getWidth() / 2, 200)
	elseif self.score >= self.pointsSecondTrophy then
		love.graphics.printf(tostring(self.score) .. ' pipes passed, you earn a trophy', 0, 180, VIRTUAL_WIDTH, 'center')
		love.graphics.draw(self.trophies['second'], VIRTUAL_WIDTH / 2 - self.trophies['second']:getWidth() / 2, 200)
	elseif self.score >= self.pointsThirdTrophy then
		love.graphics.printf(tostring(self.score) .. ' pipes passed, you earn a trophy', 0, 180, VIRTUAL_WIDTH, 'center')
		love.graphics.draw(self.trophies['third'], VIRTUAL_WIDTH / 2 - self.trophies['third']:getWidth() / 2, 210)
	end
	
end
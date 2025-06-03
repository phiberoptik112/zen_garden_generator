local GardenController = require('src/controllers/GardenController')
local GardenView = require('src/views/GardenView')
local GardenModel = require('src/models/GardenModel')

local Game = {}

function Game:load()
    love.window.setTitle("Zen Garden Generator")
    love.window.setMode(1024, 768)
    
    self.model = GardenModel:new()
    self.view = GardenView:new()
    self.controller = GardenController:new(self.model, self.view)
end

function Game:update(dt)
    self.controller:update(dt)
end

function Game:draw()
    self.view:draw(self.model)
end

function Game:mousepressed(x, y, button, istouch, presses)
    self.controller:mousepressed(x, y, button, istouch, presses)
end

function Game:mousereleased(x, y, button, istouch, presses)
    self.controller:mousereleased(x, y, button, istouch, presses)
end

function Game:mousemoved(x, y, dx, dy, istouch)
    self.controller:mousemoved(x, y, dx, dy, istouch)
end

function Game:keypressed(key)
    self.controller:keypressed(key)
end

return Game
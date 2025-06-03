local GardenView = {}
GardenView.__index = GardenView

function GardenView:new()
    local view = setmetatable({}, GardenView)
    
    view.gardenX = 50
    view.gardenY = 50
    
    view.sandTexture = love.graphics.newCanvas(800, 600)
    love.graphics.setCanvas(view.sandTexture)
    love.graphics.clear(0.9, 0.85, 0.7, 1)
    
    for i = 1, 800 do
        for j = 1, 600 do
            if math.random() < 0.1 then
                local brightness = 0.8 + math.random() * 0.1
                love.graphics.setColor(brightness, brightness * 0.9, brightness * 0.7)
                love.graphics.points(i, j)
            end
        end
    end
    love.graphics.setCanvas()
    
    return view
end

function GardenView:draw(model)
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(self.sandTexture, self.gardenX, self.gardenY)
    
    love.graphics.setColor(0.6, 0.5, 0.4)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", self.gardenX - 2, self.gardenY - 2, model.width + 4, model.height + 4)
    
    self:drawRakePattern(model)
    self:drawRocks(model)
    self:drawUI(model)
end

function GardenView:drawRocks(model)
    for _, rock in ipairs(model.rocks) do
        love.graphics.setColor(rock.color)
        love.graphics.circle("fill", self.gardenX + rock.x, self.gardenY + rock.y, rock.size / 2)
        
        love.graphics.setColor(rock.color[1] * 0.7, rock.color[2] * 0.7, rock.color[3] * 0.7)
        love.graphics.setLineWidth(2)
        love.graphics.circle("line", self.gardenX + rock.x, self.gardenY + rock.y, rock.size / 2)
        
        love.graphics.setColor(rock.color[1] * 1.3, rock.color[2] * 1.3, rock.color[3] * 1.3)
        love.graphics.circle("fill", self.gardenX + rock.x - rock.size * 0.15, self.gardenY + rock.y - rock.size * 0.15, rock.size * 0.1)
    end
end

function GardenView:drawRakePattern(model)
    love.graphics.setColor(0.8, 0.75, 0.6)
    love.graphics.setLineWidth(1)
    
    for _, stroke in ipairs(model.rakePattern) do
        local age = love.timer.getTime() - stroke.time
        local alpha = math.max(0, 1 - age / 10)
        love.graphics.setColor(0.8, 0.75, 0.6, alpha)
        
        for i = -2, 2 do
            local offset = i * 3
            local dx = stroke.y2 - stroke.y1
            local dy = stroke.x1 - stroke.x2
            local length = math.sqrt(dx^2 + dy^2)
            if length > 0 then
                dx = dx / length * offset
                dy = dy / length * offset
            end
            
            love.graphics.line(
                self.gardenX + stroke.x1 + dx,
                self.gardenY + stroke.y1 + dy,
                self.gardenX + stroke.x2 + dx,
                self.gardenY + stroke.y2 + dy
            )
        end
    end
end

function GardenView:drawUI(model)
    self:drawToolsPanel(model)
    self:drawRockControlPanel(model)
    self:drawStatusPanel(model)
    self:drawBoundaryVisualization(model)
end

function GardenView:drawToolsPanel(model)
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", 10, 10, 200, 120)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Tools:", 20, 20)
    love.graphics.print("R - Rock placement", 20, 40)
    love.graphics.print("K - Rake tool", 20, 55)
    love.graphics.print("C - Clear rake patterns", 20, 70)
    love.graphics.print("G - Generate rocks", 20, 85)
    love.graphics.print("X - Clear all rocks", 20, 100)
    love.graphics.print("Current: " .. model.selectedTool, 20, 115)
end

function GardenView:drawRockControlPanel(model)
    local panelX = 220
    local panelY = 10
    local panelWidth = 180
    local panelHeight = 140
    
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", panelX, panelY, panelWidth, panelHeight)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Rock Controls:", panelX + 10, panelY + 10)
    love.graphics.print("Size: " .. model.rockSettings.currentSize, panelX + 10, panelY + 30)
    love.graphics.print("Max: " .. model.rockSettings.maxRocks, panelX + 10, panelY + 50)
    love.graphics.print("Min Dist: " .. model.rockSettings.minDistance, panelX + 10, panelY + 70)
    love.graphics.print("Padding: " .. model.rockSettings.boundaryPadding, panelX + 10, panelY + 90)
    love.graphics.print("1/2 - Size ±  5/6 - Dist ±", panelX + 10, panelY + 110)
    love.graphics.print("3/4 - Max ±   7/8 - Pad ±", panelX + 10, panelY + 125)
end

function GardenView:drawStatusPanel(model)
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", 10, love.graphics.getHeight() - 60, 200, 50)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Rocks: " .. #model.rocks .. "/" .. model.rockSettings.maxRocks, 20, love.graphics.getHeight() - 50)
    love.graphics.print("Patterns: " .. #model.rakePattern, 20, love.graphics.getHeight() - 35)
    love.graphics.print("Size Range: " .. model.rockSettings.minSize .. "-" .. model.rockSettings.maxSize, 20, love.graphics.getHeight() - 20)
end

function GardenView:drawBoundaryVisualization(model)
    local padding = model.rockSettings.boundaryPadding
    love.graphics.setColor(1, 0, 0, 0.3)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", 
        self.gardenX + padding, 
        self.gardenY + padding, 
        model.width - 2 * padding, 
        model.height - 2 * padding)
    
    if model.selectedTool == "rock" then
        local radius = model.rockSettings.currentSize / 2
        love.graphics.setColor(0, 1, 0, 0.5)
        love.graphics.circle("line", self.gardenX + model.mouseX, self.gardenY + model.mouseY, radius)
    end
end

function GardenView:isInGarden(x, y, model)
    return x >= self.gardenX and x <= self.gardenX + model.width and
           y >= self.gardenY and y <= self.gardenY + model.height
end

function GardenView:screenToGarden(x, y)
    return x - self.gardenX, y - self.gardenY
end

return GardenView
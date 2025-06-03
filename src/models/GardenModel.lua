local GardenModel = {}
GardenModel.__index = GardenModel

function GardenModel:new()
    local model = setmetatable({}, GardenModel)
    
    model.width = 800
    model.height = 600
    model.rocks = {}
    model.rakePattern = {}
    model.selectedTool = "rock"
    model.dragging = false
    model.draggedRock = nil
    model.mouseX = 0
    model.mouseY = 0
    
    model.rockSettings = {
        minSize = 15,
        maxSize = 80,
        currentSize = 40,
        autoGenerate = false,
        maxRocks = 50,
        minDistance = 10,
        boundaryPadding = 20
    }
    
    model.rakeProfiles = {
        {name = "Fine", spacing = 2, thickness = 1, length = 15},
        {name = "Medium", spacing = 4, thickness = 2, length = 20},
        {name = "Coarse", spacing = 6, thickness = 3, length = 25},
        {name = "Wide", spacing = 8, thickness = 2, length = 30}
    }
    model.selectedRakeProfile = 1
    
    model.ui = {
        mouseX = 0,
        mouseY = 0,
        hoveredElement = nil,
        pressedElement = nil,
        draggingSlider = nil
    }
    
    return model
end

function GardenModel:addRock(x, y, size)
    size = size or self.rockSettings.currentSize
    
    if not self:isValidRockPosition(x, y, size) then
        return nil
    end
    
    if #self.rocks >= self.rockSettings.maxRocks then
        return nil
    end
    
    local rock = {
        x = x,
        y = y,
        size = size,
        color = {0.4 + math.random() * 0.2, 0.3 + math.random() * 0.2, 0.3 + math.random() * 0.2}
    }
    table.insert(self.rocks, rock)
    return rock
end

function GardenModel:removeRock(index)
    if index and self.rocks[index] then
        table.remove(self.rocks, index)
    end
end

function GardenModel:getRockAt(x, y)
    for i = #self.rocks, 1, -1 do
        local rock = self.rocks[i]
        local distance = math.sqrt((x - rock.x)^2 + (y - rock.y)^2)
        if distance <= rock.size / 2 then
            return i, rock
        end
    end
    return nil
end

function GardenModel:addRakeStroke(x1, y1, x2, y2)
    local profile = self.rakeProfiles[self.selectedRakeProfile]
    local stroke = {
        x1 = x1,
        y1 = y1,
        x2 = x2,
        y2 = y2,
        time = love.timer.getTime(),
        profile = profile
    }
    table.insert(self.rakePattern, stroke)
end

function GardenModel:clearRakePattern()
    self.rakePattern = {}
end

function GardenModel:setSelectedTool(tool)
    self.selectedTool = tool
end

function GardenModel:updateMousePosition(x, y)
    self.mouseX = x
    self.mouseY = y
end

function GardenModel:isValidRockPosition(x, y, size)
    local radius = size / 2
    local padding = self.rockSettings.boundaryPadding
    
    if x - radius < padding or x + radius > self.width - padding or
       y - radius < padding or y + radius > self.height - padding then
        return false
    end
    
    for _, rock in ipairs(self.rocks) do
        local distance = math.sqrt((x - rock.x)^2 + (y - rock.y)^2)
        local minDistance = (size + rock.size) / 2 + self.rockSettings.minDistance
        if distance < minDistance then
            return false
        end
    end
    
    return true
end

function GardenModel:constrainRockToBoundary(rock)
    local radius = rock.size / 2
    local padding = self.rockSettings.boundaryPadding
    
    rock.x = math.max(padding + radius, math.min(self.width - padding - radius, rock.x))
    rock.y = math.max(padding + radius, math.min(self.height - padding - radius, rock.y))
end

function GardenModel:generateRandomRocks(count)
    local generated = 0
    local attempts = 0
    local maxAttempts = count * 20
    
    while generated < count and attempts < maxAttempts do
        attempts = attempts + 1
        
        local size = math.random(self.rockSettings.minSize, self.rockSettings.maxSize)
        local radius = size / 2
        local padding = self.rockSettings.boundaryPadding
        
        local x = math.random(padding + radius, self.width - padding - radius)
        local y = math.random(padding + radius, self.height - padding - radius)
        
        if self:addRock(x, y, size) then
            generated = generated + 1
        end
    end
    
    return generated
end

function GardenModel:clearAllRocks()
    self.rocks = {}
end

function GardenModel:setRockSize(size)
    self.rockSettings.currentSize = math.max(self.rockSettings.minSize, 
                                           math.min(self.rockSettings.maxSize, size))
end

function GardenModel:setMaxRocks(max)
    self.rockSettings.maxRocks = math.max(1, max)
end

function GardenModel:setMinDistance(distance)
    self.rockSettings.minDistance = math.max(0, distance)
end

function GardenModel:setBoundaryPadding(padding)
    self.rockSettings.boundaryPadding = math.max(0, padding)
end

function GardenModel:setRakeProfile(index)
    if index >= 1 and index <= #self.rakeProfiles then
        self.selectedRakeProfile = index
    end
end

function GardenModel:getCurrentRakeProfile()
    return self.rakeProfiles[self.selectedRakeProfile]
end

function GardenModel:updateUIMousePosition(x, y)
    self.ui.mouseX = x
    self.ui.mouseY = y
end

function GardenModel:setUIHover(element)
    self.ui.hoveredElement = element
end

function GardenModel:setUIPressed(element)
    self.ui.pressedElement = element
end

function GardenModel:setDraggingSlider(slider)
    self.ui.draggingSlider = slider
end

return GardenModel
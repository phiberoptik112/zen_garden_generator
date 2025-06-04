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
    
    model.patternShapes = {
        {name = "Straight", id = "straight"},
        {name = "Circular", id = "circular"},
        {name = "Spiral", id = "spiral"},
        {name = "Wave", id = "wave"}
    }
    model.selectedPatternShape = 1
    
    model.patternMode = "freehand"
    model.progressiveStrokes = {}
    model.currentStroke = nil
    
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
        profile = profile,
        segments = nil,
        alpha = 1.0
    }
    table.insert(self.rakePattern, stroke)
end

function GardenModel:addProgressiveStroke(x, y)
    if not self.currentStroke then
        self.currentStroke = {
            points = {{x = x, y = y, time = love.timer.getTime()}},
            profile = self.rakeProfiles[self.selectedRakeProfile],
            segments = {},
            alpha = 1.0,
            smoothness = 5
        }
        table.insert(self.progressiveStrokes, self.currentStroke)
    else
        table.insert(self.currentStroke.points, {x = x, y = y, time = love.timer.getTime()})
        self:updateProgressiveStrokeSegments()
    end
end

function GardenModel:finishProgressiveStroke()
    if self.currentStroke then
        self:updateProgressiveStrokeSegments()
        self.currentStroke = nil
    end
end

function GardenModel:updateProgressiveStrokeSegments()
    if not self.currentStroke or #self.currentStroke.points < 2 then
        return
    end
    
    local RakePatterns = require('src/utils/RakePatterns')
    self.currentStroke.segments = {}
    
    local smoothPoints = self:smoothStrokePath(self.currentStroke.points, self.currentStroke.smoothness)
    
    for i = 1, #smoothPoints - 1 do
        local p1, p2 = smoothPoints[i], smoothPoints[i + 1]
        local segments = RakePatterns.straight(p1.x, p1.y, p2.x, p2.y, self.currentStroke.profile)
        
        local filteredSegments = RakePatterns.avoidObstacles(segments, self.rocks)
        
        for _, segment in ipairs(filteredSegments) do
            table.insert(self.currentStroke.segments, segment)
        end
    end
end

function GardenModel:smoothStrokePath(points, smoothness)
    if #points < 3 then return points end
    
    local smoothed = {points[1]}
    
    for i = 2, #points - 1 do
        local prev = points[i - 1]
        local curr = points[i]
        local next = points[i + 1]
        
        local weight = 1 / smoothness
        local x = curr.x * (1 - 2 * weight) + prev.x * weight + next.x * weight
        local y = curr.y * (1 - 2 * weight) + prev.y * weight + next.y * weight
        
        table.insert(smoothed, {x = x, y = y, time = curr.time})
    end
    
    table.insert(smoothed, points[#points])
    return smoothed
end

function GardenModel:clearRakePattern()
    self.rakePattern = {}
    self.progressiveStrokes = {}
    self.currentStroke = nil
end

function GardenModel:generatePatternShape(centerX, centerY, size)
    local RakePatterns = require('src/utils/RakePatterns')
    local profile = self.rakeProfiles[self.selectedRakeProfile]
    local shape = self.patternShapes[self.selectedPatternShape]
    local segments = {}
    
    if shape.id == "straight" then
        segments = RakePatterns.straight(
            centerX - size/2, centerY, 
            centerX + size/2, centerY, 
            profile
        )
    elseif shape.id == "circular" then
        segments = RakePatterns.circular(centerX, centerY, size/2, profile)
    elseif shape.id == "spiral" then
        segments = RakePatterns.spiral(centerX, centerY, 10, size/2, profile, 2)
    elseif shape.id == "wave" then
        segments = RakePatterns.wave(
            centerX - size/2, centerY, 
            centerX + size/2, centerY, 
            profile, size/8, 0.02
        )
    end
    
    local filteredSegments = RakePatterns.avoidObstacles(segments, self.rocks)
    
    local stroke = {
        x1 = centerX - size/2,
        y1 = centerY,
        x2 = centerX + size/2,
        y2 = centerY,
        time = love.timer.getTime(),
        profile = profile,
        segments = filteredSegments,
        alpha = 1.0,
        shape = shape.id
    }
    
    table.insert(self.rakePattern, stroke)
end

function GardenModel:setPatternShape(index)
    if index >= 1 and index <= #self.patternShapes then
        self.selectedPatternShape = index
    end
end

function GardenModel:setPatternMode(mode)
    self.patternMode = mode
    if mode ~= "progressive" then
        self:finishProgressiveStroke()
    end
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
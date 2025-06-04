local GardenView = {}
GardenView.__index = GardenView
local UI = require('src/utils/UI')

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
    for _, stroke in ipairs(model.rakePattern) do
        self:drawStroke(stroke)
    end
    
    for _, progressiveStroke in ipairs(model.progressiveStrokes) do
        self:drawProgressiveStroke(progressiveStroke)
    end
end

function GardenView:drawStroke(stroke)
    local age = love.timer.getTime() - stroke.time
    local alpha = math.max(0, (stroke.alpha or 1.0) * (1 - age / 15))
    
    if stroke.segments then
        for _, segment in ipairs(stroke.segments) do
            love.graphics.setColor(0.8, 0.75, 0.6, alpha)
            love.graphics.setLineWidth(segment.thickness or 2)
            love.graphics.line(
                self.gardenX + segment.x1,
                self.gardenY + segment.y1,
                self.gardenX + segment.x2,
                self.gardenY + segment.y2
            )
        end
    else
        love.graphics.setColor(0.8, 0.75, 0.6, alpha)
        local profile = stroke.profile or {spacing = 4, thickness = 2, length = 20}
        local numLines = math.floor(profile.length / profile.spacing)
        
        for i = -math.floor(numLines/2), math.floor(numLines/2) do
            local offset = i * profile.spacing
            local dx = stroke.y2 - stroke.y1
            local dy = stroke.x1 - stroke.x2
            local length = math.sqrt(dx^2 + dy^2)
            if length > 0 then
                dx = dx / length * offset
                dy = dy / length * offset
            end
            
            love.graphics.setLineWidth(profile.thickness)
            love.graphics.line(
                self.gardenX + stroke.x1 + dx,
                self.gardenY + stroke.y1 + dy,
                self.gardenX + stroke.x2 + dx,
                self.gardenY + stroke.y2 + dy
            )
        end
    end
end

function GardenView:drawProgressiveStroke(progressiveStroke)
    local age = love.timer.getTime() - progressiveStroke.points[1].time
    local alpha = math.max(0, (progressiveStroke.alpha or 1.0) * (1 - age / 15))
    
    for _, segment in ipairs(progressiveStroke.segments) do
        love.graphics.setColor(0.7, 0.65, 0.5, alpha)
        love.graphics.setLineWidth(segment.thickness or 2)
        love.graphics.line(
            self.gardenX + segment.x1,
            self.gardenY + segment.y1,
            self.gardenX + segment.x2,
            self.gardenY + segment.y2
        )
    end
    
    if #progressiveStroke.points > 1 then
        love.graphics.setColor(0.6, 0.55, 0.4, alpha * 0.5)
        love.graphics.setLineWidth(1)
        for i = 1, #progressiveStroke.points - 1 do
            local p1, p2 = progressiveStroke.points[i], progressiveStroke.points[i + 1]
            love.graphics.line(
                self.gardenX + p1.x, self.gardenY + p1.y,
                self.gardenX + p2.x, self.gardenY + p2.y
            )
        end
    end
end

function GardenView:drawUI(model)
    self:drawToolPanel(model)
    self:drawRakePanel(model)
    self:drawRockPanel(model)
    self:drawBoundaryVisualization(model)
end

function GardenView:drawToolPanel(model)
    UI.panel(10, 10, 180, 120, "Tools")
    
    local rockActive = model.selectedTool == "rock"
    local rakeActive = model.selectedTool == "rake"
    local rockHovered = model.ui.hoveredElement == "rock_tool"
    local rakeHovered = model.ui.hoveredElement == "rake_tool"
    
    UI.toggleButton(20, 45, 70, 25, "Rock", rockActive, rockHovered)
    UI.toggleButton(100, 45, 70, 25, "Rake", rakeActive, rakeHovered)
    
    local clearHovered = model.ui.hoveredElement == "clear_patterns"
    local generateHovered = model.ui.hoveredElement == "generate_rocks"
    local clearAllHovered = model.ui.hoveredElement == "clear_rocks"
    
    UI.button(20, 80, 45, 20, "Clear", false, clearHovered)
    UI.button(75, 80, 45, 20, "Gen", false, generateHovered)
    UI.button(130, 80, 40, 20, "Clear All", false, clearAllHovered)
end

function GardenView:drawRakePanel(model)
    UI.panel(200, 10, 180, 200, "Rake Controls")
    
    love.graphics.setColor(0, 0, 0)
    love.graphics.print("Mode:", 210, 40)
    
    local modes = {
        {name = "Freehand", id = "freehand"},
        {name = "Progressive", id = "progressive"},
        {name = "Shape", id = "shape"}
    }
    
    for i, mode in ipairs(modes) do
        local x = 210 + ((i - 1) % 3) * 53
        local y = 55
        local active = model.patternMode == mode.id
        local hovered = model.ui.hoveredElement == "pattern_mode_" .. mode.id
        
        UI.toggleButton(x, y, 50, 18, mode.name, active, hovered)
    end
    
    love.graphics.setColor(0, 0, 0)
    love.graphics.print("Profiles:", 210, 85)
    
    for i, profile in ipairs(model.rakeProfiles) do
        local y = 100 + (i - 1) * 18
        local active = model.selectedRakeProfile == i
        local hovered = model.ui.hoveredElement == "rake_profile_" .. i
        
        UI.toggleButton(210, y, 160, 16, profile.name, active, hovered)
    end
    
    love.graphics.setColor(0, 0, 0)
    love.graphics.print("Patterns:", 210, 175)
    
    for i, shape in ipairs(model.patternShapes) do
        local x = 210 + ((i - 1) % 2) * 75
        local y = 190 + math.floor((i - 1) / 2) * 20
        local active = model.selectedPatternShape == i
        local hovered = model.ui.hoveredElement == "pattern_shape_" .. i
        local enabled = model.patternMode == "shape"
        
        if enabled then
            UI.toggleButton(x, y, 70, 18, shape.name, active, hovered)
        else
            love.graphics.setColor(0.7, 0.7, 0.7)
            love.graphics.rectangle("fill", x, y, 70, 18)
            love.graphics.setColor(0.5, 0.5, 0.5)
            love.graphics.rectangle("line", x, y, 70, 18)
            love.graphics.setColor(0.5, 0.5, 0.5)
            local font = love.graphics.getFont()
            local textWidth = font:getWidth(shape.name)
            local textHeight = font:getHeight()
            love.graphics.print(shape.name, x + (70 - textWidth) / 2, y + (18 - textHeight) / 2)
        end
    end
end

function GardenView:drawRockPanel(model)
    UI.panel(390, 10, 200, 140, "Rock Controls")
    
    local sizeHovered = model.ui.hoveredElement == "size_slider"
    local sizeDragging = model.ui.draggingSlider == "size_slider"
    UI.slider(400, 50, 160, 15, model.rockSettings.currentSize, 
              model.rockSettings.minSize, model.rockSettings.maxSize, 
              "Size", sizeHovered, sizeDragging)
    
    local maxHovered = model.ui.hoveredElement == "max_slider"
    local maxDragging = model.ui.draggingSlider == "max_slider"
    UI.slider(400, 80, 160, 15, model.rockSettings.maxRocks, 
              10, 100, "Max Rocks", maxHovered, maxDragging)
    
    local distHovered = model.ui.hoveredElement == "distance_slider"
    local distDragging = model.ui.draggingSlider == "distance_slider"
    UI.slider(400, 110, 160, 15, model.rockSettings.minDistance, 
              0, 30, "Min Distance", distHovered, distDragging)
    
    love.graphics.setColor(0, 0, 0)
    love.graphics.print("Rocks: " .. #model.rocks .. "/" .. model.rockSettings.maxRocks, 400, 130)
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

function GardenView:getUIElementAt(x, y, model)
    if UI.isPointInRect(x, y, 20, 45, 70, 25) then
        return "rock_tool"
    elseif UI.isPointInRect(x, y, 100, 45, 70, 25) then
        return "rake_tool"
    elseif UI.isPointInRect(x, y, 20, 80, 45, 20) then
        return "clear_patterns"
    elseif UI.isPointInRect(x, y, 75, 80, 45, 20) then
        return "generate_rocks"
    elseif UI.isPointInRect(x, y, 130, 80, 40, 20) then
        return "clear_rocks"
    end
    
    local modes = {"freehand", "progressive", "shape"}
    for i, mode in ipairs(modes) do
        local button_x = 210 + ((i - 1) % 3) * 53
        if UI.isPointInRect(x, y, button_x, 55, 50, 18) then
            return "pattern_mode_" .. mode
        end
    end
    
    for i = 1, #model.rakeProfiles do
        local y_pos = 100 + (i - 1) * 18
        if UI.isPointInRect(x, y, 210, y_pos, 160, 16) then
            return "rake_profile_" .. i
        end
    end
    
    for i = 1, #model.patternShapes do
        local button_x = 210 + ((i - 1) % 2) * 75
        local button_y = 190 + math.floor((i - 1) / 2) * 20
        if UI.isPointInRect(x, y, button_x, button_y, 70, 18) and model.patternMode == "shape" then
            return "pattern_shape_" .. i
        end
    end
    
    if UI.isPointInRect(x, y, 400, 50, 160, 15) then
        return "size_slider"
    elseif UI.isPointInRect(x, y, 400, 80, 160, 15) then
        return "max_slider"
    elseif UI.isPointInRect(x, y, 400, 110, 160, 15) then
        return "distance_slider"
    end
    
    return nil
end

return GardenView
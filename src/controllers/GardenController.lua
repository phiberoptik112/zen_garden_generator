local GardenController = {}
GardenController.__index = GardenController
local UI = require('src/utils/UI')

function GardenController:new(model, view)
    local controller = setmetatable({}, GardenController)
    controller.model = model
    controller.view = view
    controller.lastRakeX = nil
    controller.lastRakeY = nil
    controller.raking = false
    return controller
end

function GardenController:update(dt)
end

function GardenController:mousepressed(x, y, button, istouch, presses)
    if button == 1 then
        local uiElement = self.view:getUIElementAt(x, y, self.model)
        
        if uiElement then
            self.model:setUIPressed(uiElement)
            self:handleUIClick(uiElement, x, y)
            return
        end
        
        -- Handle rock selection and dragging
        if self.model.selectedTool == "rock" then
            local rockIndex = self.model:getRockAt(x, y)
            if rockIndex then
                self.model.dragging = true
                self.model.draggedRock = rockIndex
            else
                self.model:addRock(x, y)
            end
        end
    end
    
    if not self.view:isInGarden(x, y, self.model) then
        return
    end
    
    local gardenX, gardenY = self.view:screenToGarden(x, y)
    
    if self.model.selectedTool == "rock" and button == 1 then
        local rockIndex, rock = self.model:getRockAt(gardenX, gardenY)
        
        if rockIndex then
            self.model.dragging = true
            self.model.draggedRock = rockIndex
        else
            self.model:addRock(gardenX, gardenY)
        end
    elseif self.model.selectedTool == "rock" and button == 2 then
        local rockIndex = self.model:getRockAt(gardenX, gardenY)
        if rockIndex then
            self.model:removeRock(rockIndex)
        end
    elseif self.model.selectedTool == "rake" and button == 1 then
        if self.model.patternMode == "progressive" then
            self.model:addProgressiveStroke(gardenX, gardenY)
        elseif self.model.patternMode == "shape" then
            self.model:generatePatternShape(gardenX, gardenY, 100)
        else
            self.raking = true
            self.lastRakeX = gardenX
            self.lastRakeY = gardenY
        end
    end
end

function GardenController:mousereleased(x, y, button, istouch, presses)
    if button == 1 then
        self.model.dragging = false
        self.model.draggedRock = nil
        self.model:setDraggingSlider(nil)
        
        if self.model.patternMode == "progressive" and self.raking then
            self.model:finishProgressiveStroke()
        end
        
        self.raking = false
        self.lastRakeX = nil
        self.lastRakeY = nil
    end
end

function GardenController:mousemoved(x, y, dx, dy, istouch)
    self.model:updateMousePosition(x, y)
    self.model:updateUIMousePosition(x, y)
    
    local uiElement = self.view:getUIElementAt(x, y, self.model)
    self.model:setUIHover(uiElement)
    
    if self.model.ui.draggingSlider then
        self:handleSliderDrag(self.model.ui.draggingSlider, x)
        return
    end
    
    local gardenX, gardenY = self.view:screenToGarden(x, y)
    self.model:updateMousePosition(gardenX, gardenY)
    
    if self.model.dragging and self.model.draggedRock then
        local rock = self.model.rocks[self.model.draggedRock]
        if rock then
            rock.x = gardenX
            rock.y = gardenY
            self.model:constrainRockToBoundary(rock)
        end
    end
    
    if self.raking and self.view:isInGarden(x, y, self.model) then
        if self.model.patternMode == "progressive" then
            self.model:addProgressiveStroke(gardenX, gardenY)
        elseif self.lastRakeX and self.lastRakeY then
            local distance = math.sqrt((gardenX - self.lastRakeX)^2 + (gardenY - self.lastRakeY)^2)
            if distance > 5 then
                self.model:addRakeStroke(self.lastRakeX, self.lastRakeY, gardenX, gardenY)
                self.lastRakeX = gardenX
                self.lastRakeY = gardenY
            end
        end
    end
end

function GardenController:keypressed(key)
    if key == "r" then
        self.model:setSelectedTool("rock")
    elseif key == "k" then
        self.model:setSelectedTool("rake")
    elseif key == "c" then
        self.model:clearRakePattern()
    elseif key == "g" then
        local count = math.min(10, self.model.rockSettings.maxRocks - #self.model.rocks)
        self.model:generateRandomRocks(count)
    elseif key == "x" then
        self.model:clearAllRocks()
    elseif key == "1" then
        local newSize = self.model.rockSettings.currentSize - 5
        self.model:setRockSize(newSize)
    elseif key == "2" then
        local newSize = self.model.rockSettings.currentSize + 5
        self.model:setRockSize(newSize)
    elseif key == "3" then
        local newMax = self.model.rockSettings.maxRocks - 5
        self.model:setMaxRocks(newMax)
    elseif key == "4" then
        local newMax = self.model.rockSettings.maxRocks + 5
        self.model:setMaxRocks(newMax)
    elseif key == "5" then
        local newDist = self.model.rockSettings.minDistance - 2
        self.model:setMinDistance(newDist)
    elseif key == "6" then
        local newDist = self.model.rockSettings.minDistance + 2
        self.model:setMinDistance(newDist)
    elseif key == "7" then
        local newPadding = self.model.rockSettings.boundaryPadding - 5
        self.model:setBoundaryPadding(newPadding)
    elseif key == "8" then
        local newPadding = self.model.rockSettings.boundaryPadding + 5
        self.model:setBoundaryPadding(newPadding)
    elseif key == "p" then
        self.model:setPatternMode("progressive")
    elseif key == "s" then
        self.model:setPatternMode("shape")
    elseif key == "f" then
        self.model:setPatternMode("freehand")
    elseif key == "escape" then
        love.event.quit()
    end
end

function GardenController:handleUIClick(element, x, y)
    if element == "rock_tool" then
        self.model:setSelectedTool("rock")
    elseif element == "rake_tool" then
        self.model:setSelectedTool("rake")
    elseif element == "clear_patterns" then
        self.model:clearRakePattern()
    elseif element == "generate_rocks" then
        local count = math.min(10, self.model.rockSettings.maxRocks - #self.model.rocks)
        self.model:generateRandomRocks(count)
    elseif element == "clear_rocks" then
        self.model:clearAllRocks()
    elseif element:match("^pattern_mode_") then
        local mode = element:match("^pattern_mode_(.+)")
        if mode then
            self.model:setPatternMode(mode)
        end
    elseif element:match("^rake_profile_") then
        local profileIndex = tonumber(element:match("%d+"))
        if profileIndex then
            self.model:setRakeProfile(profileIndex)
        end
    elseif element:match("^pattern_shape_") then
        local shapeIndex = tonumber(element:match("%d+"))
        if shapeIndex then
            self.model:setPatternShape(shapeIndex)
        end
    elseif element:match("^rock_material_") then
        local materialIndex = tonumber(element:match("%d+"))
        if materialIndex then
            self.model:setRockMaterial(materialIndex)
        end
    elseif element == "sand_shader_toggle" then
        self.model:toggleSandShader()
    elseif element == "rock_shader_toggle" then
        self.model:toggleRockShader()
    elseif element == "size_slider" then
        self.model:setDraggingSlider("size_slider")
    elseif element == "max_slider" then
        self.model:setDraggingSlider("max_slider")
    elseif element == "distance_slider" then
        self.model:setDraggingSlider("distance_slider")
    elseif element == "sand_pixel_slider" then
        self.model:setDraggingSlider("sand_pixel_slider")
    elseif element == "sand_grain_slider" then
        self.model:setDraggingSlider("sand_grain_slider")
    elseif element == "sand_variation_slider" then
        self.model:setDraggingSlider("sand_variation_slider")
    elseif element == "contour_spacing_slider" then
        self.model:setDraggingSlider("contour_spacing_slider")
    end
end

function GardenController:handleSliderDrag(sliderType, mouseX)
    if sliderType == "size_slider" then
        local value = UI.getSliderValue(mouseX, 400, 160, 
                                       self.model.rockSettings.minSize, 
                                       self.model.rockSettings.maxSize)
        self.model:setRockSize(value)
    elseif sliderType == "max_slider" then
        local value = UI.getSliderValue(mouseX, 400, 160, 10, 100)
        self.model:setMaxRocks(value)
    elseif sliderType == "distance_slider" then
        local value = UI.getSliderValue(mouseX, 400, 160, 0, 30)
        self.model:setMinDistance(value)
    elseif sliderType == "sand_pixel_slider" then
        local value = UI.getSliderValue(mouseX, 610, 160, 1, 16)
        self.model:setSandPixelSize(value)
    elseif sliderType == "sand_grain_slider" then
        local value = UI.getSliderValue(mouseX, 610, 160, 0, 1)
        self.model:setSandGrainIntensity(value)
    elseif sliderType == "sand_variation_slider" then
        local value = UI.getSliderValue(mouseX, 610, 160, 0, 1)
        self.model:setSandColorVariation(value)
    elseif sliderType == "contour_spacing_slider" then
        local value = UI.getSliderValue(mouseX, 610, 160, 5, 100)
        self.model:setContourSpacing(value)
    end
end

return GardenController
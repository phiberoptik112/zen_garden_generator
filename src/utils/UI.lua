local UI = {}

function UI.button(x, y, width, height, text, pressed, hovered)
    local bgColor = {1, 1, 1}
    local textColor = {0, 0, 0}
    local borderColor = {0, 0, 0}
    
    if pressed then
        bgColor = {0, 0, 0}
        textColor = {1, 1, 1}
    elseif hovered then
        bgColor = {0.9, 0.9, 0.9}
    end
    
    love.graphics.setColor(bgColor)
    love.graphics.rectangle("fill", x, y, width, height)
    
    love.graphics.setColor(borderColor)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", x, y, width, height)
    
    love.graphics.setColor(textColor)
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(text)
    local textHeight = font:getHeight()
    love.graphics.print(text, 
        x + (width - textWidth) / 2, 
        y + (height - textHeight) / 2)
end

function UI.isPointInRect(px, py, x, y, width, height)
    return px >= x and px <= x + width and py >= y and py <= y + height
end

function UI.slider(x, y, width, height, value, minValue, maxValue, label, hovered, dragging)
    local bgColor = {1, 1, 1}
    local trackColor = {0.7, 0.7, 0.7}
    local handleColor = {0, 0, 0}
    local textColor = {0, 0, 0}
    
    if hovered or dragging then
        handleColor = {0.3, 0.3, 0.3}
    end
    
    love.graphics.setColor(bgColor)
    love.graphics.rectangle("fill", x, y, width, height)
    
    love.graphics.setColor(trackColor)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", x, y, width, height)
    
    local normalized = (value - minValue) / (maxValue - minValue)
    local handleX = x + normalized * (width - 10)
    
    love.graphics.setColor(handleColor)
    love.graphics.rectangle("fill", handleX, y + 2, 10, height - 4)
    
    love.graphics.setColor(textColor)
    local font = love.graphics.getFont()
    local text = label .. ": " .. math.floor(value)
    local textHeight = font:getHeight()
    love.graphics.print(text, x, y - textHeight - 5)
end

function UI.getSliderValue(mouseX, sliderX, sliderWidth, minValue, maxValue)
    local normalized = math.max(0, math.min(1, (mouseX - sliderX) / sliderWidth))
    return minValue + normalized * (maxValue - minValue)
end

function UI.toggleButton(x, y, width, height, text, active, hovered)
    local bgColor = active and {0, 0, 0} or {1, 1, 1}
    local textColor = active and {1, 1, 1} or {0, 0, 0}
    local borderColor = {0, 0, 0}
    
    if hovered and not active then
        bgColor = {0.9, 0.9, 0.9}
    elseif hovered and active then
        bgColor = {0.2, 0.2, 0.2}
    end
    
    love.graphics.setColor(bgColor)
    love.graphics.rectangle("fill", x, y, width, height)
    
    love.graphics.setColor(borderColor)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", x, y, width, height)
    
    love.graphics.setColor(textColor)
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(text)
    local textHeight = font:getHeight()
    love.graphics.print(text, 
        x + (width - textWidth) / 2, 
        y + (height - textHeight) / 2)
end

function UI.panel(x, y, width, height, title)
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", x, y, width, height)
    
    love.graphics.setColor(0, 0, 0)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", x, y, width, height)
    
    if title then
        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("fill", x, y, width, 25)
        
        love.graphics.setColor(1, 1, 1)
        local font = love.graphics.getFont()
        local textWidth = font:getWidth(title)
        love.graphics.print(title, x + (width - textWidth) / 2, y + 5)
    end
end

return UI
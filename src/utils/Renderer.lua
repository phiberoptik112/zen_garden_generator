local Renderer = {}

function Renderer:new()
    local renderer = setmetatable({}, {__index = Renderer})
    
    renderer.sandShader = nil
    renderer.rockShader = nil
    renderer.sandCanvas = nil
    
    renderer.sandParams = {
        pixelSize = 4.0,
        grainIntensity = 0.3,
        colorVariation = 0.2,
        sandColor = {0.9, 0.85, 0.7},
        noiseScale = 32.0
    }
    
    renderer.rockMaterials = {
        granite = {
            color = {0.5, 0.5, 0.5},
            roughness = 0.7,
            metallic = 0.1,
            specular = 0.3,
            crackIntensity = 0.2,
            weathering = 0.1
        },
        sandstone = {
            color = {0.8, 0.7, 0.5},
            roughness = 0.8,
            metallic = 0.0,
            specular = 0.2,
            crackIntensity = 0.1,
            weathering = 0.3
        },
        marble = {
            color = {0.9, 0.9, 0.9},
            roughness = 0.2,
            metallic = 0.0,
            specular = 0.8,
            crackIntensity = 0.05,
            weathering = 0.05
        },
        slate = {
            color = {0.3, 0.3, 0.4},
            roughness = 0.5,
            metallic = 0.2,
            specular = 0.4,
            crackIntensity = 0.4,
            weathering = 0.2
        }
    }
    
    renderer.lightDirection = {-0.5, -0.7, -0.5}
    renderer.lightColor = {1.0, 0.95, 0.8}
    renderer.ambientStrength = 0.3
    
    return renderer
end

function Renderer:loadShaders()
    local sandVertexCode = love.filesystem.read("shaders/sand.vert")
    local sandFragmentCode = love.filesystem.read("shaders/sand.frag")
    self.sandShader = love.graphics.newShader(sandFragmentCode, sandVertexCode)
    
    local rockVertexCode = love.filesystem.read("shaders/rock.vert")
    local rockFragmentCode = love.filesystem.read("shaders/rock.frag")
    self.rockShader = love.graphics.newShader(rockFragmentCode, rockVertexCode)
end

function Renderer:createSandTexture(width, height)
    if self.sandCanvas then
        self.sandCanvas:release()
    end
    
    self.sandCanvas = love.graphics.newCanvas(width, height)
    love.graphics.setCanvas(self.sandCanvas)
    love.graphics.clear(1, 1, 1, 1)
    
    if self.sandShader then
        love.graphics.setShader(self.sandShader)
        self:updateSandShaderParams()
        love.graphics.rectangle("fill", 0, 0, width, height)
        love.graphics.setShader()
    else
        love.graphics.setColor(self.sandParams.sandColor)
        love.graphics.rectangle("fill", 0, 0, width, height)
        love.graphics.setColor(1, 1, 1)
    end
    
    love.graphics.setCanvas()
end

function Renderer:updateSandShaderParams()
    if not self.sandShader then return end
    
    self.sandShader:send("pixelSize", self.sandParams.pixelSize)
    self.sandShader:send("grainIntensity", self.sandParams.grainIntensity)
    self.sandShader:send("colorVariation", self.sandParams.colorVariation)
    self.sandShader:send("sandColor", self.sandParams.sandColor)
    self.sandShader:send("noiseScale", self.sandParams.noiseScale)
    self.sandShader:send("time", love.timer.getTime())
    self.sandShader:send("resolution", {800, 600})
end

function Renderer:updateRockShaderParams(material)
    if not self.rockShader then return end
    
    local mat = self.rockMaterials[material] or self.rockMaterials.granite
    
    self.rockShader:send("rockColor", mat.color)
    self.rockShader:send("roughness", mat.roughness)
    self.rockShader:send("metallic", mat.metallic)
    self.rockShader:send("specular", mat.specular)
    self.rockShader:send("crackIntensity", mat.crackIntensity)
    self.rockShader:send("weathering", mat.weathering)
    self.rockShader:send("lightDirection", self.lightDirection)
    self.rockShader:send("lightColor", self.lightColor)
    self.rockShader:send("ambientStrength", self.ambientStrength)
    self.rockShader:send("time", love.timer.getTime())
end

function Renderer:drawSand(x, y)
    if self.sandCanvas then
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(self.sandCanvas, x, y)
    end
end

function Renderer:drawRock(x, y, radius, material)
    material = material or "granite"
    
    if self.rockShader then
        love.graphics.setShader(self.rockShader)
        self:updateRockShaderParams(material)
    end
    
    local mat = self.rockMaterials[material]
    love.graphics.setColor(mat.color)
    
    local segments = 32
    local vertices = {}
    
    for i = 0, segments do
        local angle = (i / segments) * math.pi * 2
        local variation = (math.sin(angle * 3) + math.cos(angle * 5)) * 0.1 + 1
        local r = radius * variation
        local px = x + math.cos(angle) * r
        local py = y + math.sin(angle) * r
        table.insert(vertices, px)
        table.insert(vertices, py)
    end
    
    if #vertices >= 6 then
        love.graphics.polygon("fill", vertices)
    end
    
    if self.rockShader then
        love.graphics.setShader()
    end
    
    self:drawRockHighlights(x, y, radius, material)
end

function Renderer:drawRockHighlights(x, y, radius, material)
    local mat = self.rockMaterials[material]
    
    love.graphics.setColor(mat.color[1] * 0.7, mat.color[2] * 0.7, mat.color[3] * 0.7)
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", x, y, radius)
    
    if mat.specular > 0.5 then
        love.graphics.setColor(1, 1, 1, mat.specular * 0.5)
        love.graphics.circle("fill", x - radius * 0.3, y - radius * 0.3, radius * 0.2)
    end
    
    love.graphics.setColor(1, 1, 1)
end

function Renderer:generateRockTexture(size, material)
    local canvas = love.graphics.newCanvas(size, size)
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 0)
    
    local mat = self.rockMaterials[material] or self.rockMaterials.granite
    
    if self.rockShader then
        love.graphics.setShader(self.rockShader)
        self:updateRockShaderParams(material)
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("fill", 0, 0, size, size)
        love.graphics.setShader()
    else
        love.graphics.setColor(mat.color)
        love.graphics.rectangle("fill", 0, 0, size, size)
    end
    
    love.graphics.setCanvas()
    return canvas
end

function Renderer:setSandParameter(param, value)
    if self.sandParams[param] then
        self.sandParams[param] = value
    end
end

function Renderer:setRockMaterial(materialName, properties)
    if self.rockMaterials[materialName] then
        for key, value in pairs(properties) do
            if self.rockMaterials[materialName][key] then
                self.rockMaterials[materialName][key] = value
            end
        end
    end
end

function Renderer:setLighting(direction, color, ambient)
    self.lightDirection = direction or self.lightDirection
    self.lightColor = color or self.lightColor
    self.ambientStrength = ambient or self.ambientStrength
end

return Renderer
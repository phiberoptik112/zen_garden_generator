local RakePatterns = {}

function RakePatterns.straight(startX, startY, endX, endY, profile)
    local segments = {}
    local dx = endX - startX
    local dy = endY - startY
    local length = math.sqrt(dx^2 + dy^2)
    
    if length == 0 then return segments end
    
    local unitX = dx / length
    local unitY = dy / length
    local perpX = -unitY
    local perpY = unitX
    
    local numLines = math.floor(profile.length / profile.spacing)
    
    for i = -math.floor(numLines/2), math.floor(numLines/2) do
        local offset = i * profile.spacing
        local x1 = startX + perpX * offset
        local y1 = startY + perpY * offset
        local x2 = endX + perpX * offset
        local y2 = endY + perpY * offset
        
        table.insert(segments, {
            x1 = x1, y1 = y1, x2 = x2, y2 = y2,
            thickness = profile.thickness
        })
    end
    
    return segments
end

function RakePatterns.circular(centerX, centerY, radius, profile, startAngle, endAngle)
    local segments = {}
    startAngle = startAngle or 0
    endAngle = endAngle or math.pi * 2
    
    local angleStep = 0.1
    local numLines = math.floor(profile.length / profile.spacing)
    
    for angle = startAngle, endAngle, angleStep do
        local nextAngle = math.min(angle + angleStep, endAngle)
        
        for i = -math.floor(numLines/2), math.floor(numLines/2) do
            local offset = i * profile.spacing
            local r1 = radius + offset
            local r2 = radius + offset
            
            if r1 > 0 and r2 > 0 then
                local x1 = centerX + math.cos(angle) * r1
                local y1 = centerY + math.sin(angle) * r1
                local x2 = centerX + math.cos(nextAngle) * r2
                local y2 = centerY + math.sin(nextAngle) * r2
                
                table.insert(segments, {
                    x1 = x1, y1 = y1, x2 = x2, y2 = y2,
                    thickness = profile.thickness
                })
            end
        end
    end
    
    return segments
end

function RakePatterns.spiral(centerX, centerY, startRadius, endRadius, profile, turns)
    local segments = {}
    turns = turns or 3
    
    local angleStep = 0.1
    local totalAngle = turns * math.pi * 2
    local radiusStep = (endRadius - startRadius) / (totalAngle / angleStep)
    local numLines = math.floor(profile.length / profile.spacing)
    
    for angle = 0, totalAngle, angleStep do
        local nextAngle = math.min(angle + angleStep, totalAngle)
        local currentRadius = startRadius + (angle / totalAngle) * (endRadius - startRadius)
        local nextRadius = startRadius + (nextAngle / totalAngle) * (endRadius - startRadius)
        
        for i = -math.floor(numLines/2), math.floor(numLines/2) do
            local offset = i * profile.spacing
            local r1 = currentRadius + offset
            local r2 = nextRadius + offset
            
            if r1 > 0 and r2 > 0 then
                local x1 = centerX + math.cos(angle) * r1
                local y1 = centerY + math.sin(angle) * r1
                local x2 = centerX + math.cos(nextAngle) * r2
                local y2 = centerY + math.sin(nextAngle) * r2
                
                table.insert(segments, {
                    x1 = x1, y1 = y1, x2 = x2, y2 = y2,
                    thickness = profile.thickness
                })
            end
        end
    end
    
    return segments
end

function RakePatterns.wave(startX, startY, endX, endY, profile, amplitude, frequency)
    local segments = {}
    amplitude = amplitude or 20
    frequency = frequency or 0.02
    
    local dx = endX - startX
    local dy = endY - startY
    local length = math.sqrt(dx^2 + dy^2)
    
    if length == 0 then return segments end
    
    local unitX = dx / length
    local unitY = dy / length
    local perpX = -unitY
    local perpY = unitX
    
    local step = 5
    local numLines = math.floor(profile.length / profile.spacing)
    
    for i = -math.floor(numLines/2), math.floor(numLines/2) do
        local baseOffset = i * profile.spacing
        
        for t = 0, length, step do
            local nextT = math.min(t + step, length)
            
            local progress1 = t / length
            local progress2 = nextT / length
            
            local wave1 = math.sin(t * frequency) * amplitude
            local wave2 = math.sin(nextT * frequency) * amplitude
            
            local x1 = startX + unitX * t + perpX * (baseOffset + wave1)
            local y1 = startY + unitY * t + perpY * (baseOffset + wave1)
            local x2 = startX + unitX * nextT + perpX * (baseOffset + wave2)
            local y2 = startY + unitY * nextT + perpY * (baseOffset + wave2)
            
            table.insert(segments, {
                x1 = x1, y1 = y1, x2 = x2, y2 = y2,
                thickness = profile.thickness
            })
        end
    end
    
    return segments
end

function RakePatterns.avoidObstacles(segments, rocks)
    local filteredSegments = {}
    
    for _, segment in ipairs(segments) do
        local newSegments = RakePatterns.splitSegmentAroundRocks(segment, rocks)
        for _, newSeg in ipairs(newSegments) do
            table.insert(filteredSegments, newSeg)
        end
    end
    
    return filteredSegments
end

function RakePatterns.splitSegmentAroundRocks(segment, rocks)
    local result = {}
    local currentSegment = segment
    
    for _, rock in ipairs(rocks) do
        local newSegments = {}
        
        for _, seg in ipairs({currentSegment}) do
            local splits = RakePatterns.splitSegmentAroundRock(seg, rock)
            for _, split in ipairs(splits) do
                table.insert(newSegments, split)
            end
        end
        
        currentSegment = newSegments[1]
        for i = 2, #newSegments do
            table.insert(result, newSegments[i])
        end
    end
    
    if currentSegment then
        table.insert(result, currentSegment)
    end
    
    return result
end

function RakePatterns.splitSegmentAroundRock(segment, rock)
    local segments = {}
    local buffer = 5
    local radius = rock.size / 2 + buffer
    
    local intersections = RakePatterns.lineCircleIntersection(
        segment.x1, segment.y1, segment.x2, segment.y2,
        rock.x, rock.y, radius
    )
    
    if #intersections == 0 then
        return {segment}
    elseif #intersections == 2 then
        local t1, t2 = intersections[1].t, intersections[2].t
        if t1 > t2 then t1, t2 = t2, t1 end
        
        if t1 > 0 then
            local x = segment.x1 + t1 * (segment.x2 - segment.x1)
            local y = segment.y1 + t1 * (segment.y2 - segment.y1)
            table.insert(segments, {
                x1 = segment.x1, y1 = segment.y1,
                x2 = x, y2 = y,
                thickness = segment.thickness
            })
        end
        
        if t2 < 1 then
            local x = segment.x1 + t2 * (segment.x2 - segment.x1)
            local y = segment.y1 + t2 * (segment.y2 - segment.y1)
            table.insert(segments, {
                x1 = x, y1 = y,
                x2 = segment.x2, y2 = segment.y2,
                thickness = segment.thickness
            })
        end
    else
        local t = intersections[1].t
        if t > 0 and t < 1 then
            local x = segment.x1 + t * (segment.x2 - segment.x1)
            local y = segment.y1 + t * (segment.y2 - segment.y1)
            
            local distToStart = math.sqrt((x - segment.x1)^2 + (y - segment.y1)^2)
            local distToEnd = math.sqrt((x - segment.x2)^2 + (y - segment.y2)^2)
            
            if distToStart > distToEnd then
                table.insert(segments, {
                    x1 = segment.x1, y1 = segment.y1,
                    x2 = x, y2 = y,
                    thickness = segment.thickness
                })
            else
                table.insert(segments, {
                    x1 = x, y1 = y,
                    x2 = segment.x2, y2 = segment.y2,
                    thickness = segment.thickness
                })
            end
        else
            table.insert(segments, segment)
        end
    end
    
    return segments
end

function RakePatterns.lineCircleIntersection(x1, y1, x2, y2, cx, cy, r)
    local dx = x2 - x1
    local dy = y2 - y1
    local fx = x1 - cx
    local fy = y1 - cy
    
    local a = dx^2 + dy^2
    local b = 2 * (fx * dx + fy * dy)
    local c = fx^2 + fy^2 - r^2
    
    local discriminant = b^2 - 4 * a * c
    
    if discriminant < 0 then
        return {}
    elseif discriminant == 0 then
        local t = -b / (2 * a)
        if t >= 0 and t <= 1 then
            return {{t = t, x = x1 + t * dx, y = y1 + t * dy}}
        else
            return {}
        end
    else
        local sqrt_d = math.sqrt(discriminant)
        local t1 = (-b - sqrt_d) / (2 * a)
        local t2 = (-b + sqrt_d) / (2 * a)
        
        local intersections = {}
        if t1 >= 0 and t1 <= 1 then
            table.insert(intersections, {t = t1, x = x1 + t1 * dx, y = y1 + t1 * dy})
        end
        if t2 >= 0 and t2 <= 1 then
            table.insert(intersections, {t = t2, x = x1 + t2 * dx, y = y1 + t2 * dy})
        end
        
        return intersections
    end
end

function RakePatterns.topographic(centerX, centerY, startRadius, endRadius, profile, numContours, hubRock)
    local segments = {}
    
    -- Calculate number of contours based on the spacing
    local totalDistance = endRadius - startRadius
    local numContours = math.floor(totalDistance / profile.contourSpacing)
    
    -- Generate concentric circles with increasing radius
    for i = 0, numContours do
        local currentRadius = startRadius + (i * profile.contourSpacing)
        local contourSegments = RakePatterns.circular(centerX, centerY, currentRadius, profile)
        
        -- Filter segments to avoid the hub rock
        if hubRock then
            local filteredSegments = RakePatterns.avoidObstacles(contourSegments, {hubRock})
            for _, segment in ipairs(filteredSegments) do
                table.insert(segments, segment)
            end
        else
            for _, segment in ipairs(contourSegments) do
                table.insert(segments, segment)
            end
        end
    end
    
    return segments
end

return RakePatterns
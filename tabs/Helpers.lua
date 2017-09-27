
-- Global Helpers (latest update 10.09.2017)
-- Collection of useful functions and Codea extensions



-- TODO finish and then include GIF89a parser here too
-- TODO change all colors in this class to use paint[color] variable










-- pallet of colors

paint = {
    transparent = color(0, 0),
    black = color(0),
    dark_gray = color(20),
    light_gray = color(194, 195, 199, 255),
    dark_blue = color(29, 43, 83, 255),
    dark_purple = color(126, 37, 83, 255),
    dark_green = color(0, 135, 81, 255),
    brown = color(171, 82, 54, 255),
    umber = color(95, 87, 79, 255),
    pearl = color(255, 241, 232, 255),
    red = color(255, 0, 77, 255),
    orange = color(255, 163, 0, 255),
    yellow = color(255, 236, 39, 255),
    green = color(0, 228, 54, 255),
    blue = color(41, 173, 255, 255),
    indigo = color(131, 118, 156, 255),
    pink = color(255, 119, 168, 255),
    peach = color(255, 204, 170, 255),
    white = color(255)
}











-- Show debug information like fps, frame-rate and ram usage
function debugger(pivotX, pivotY) -- in range of [0-1]
    pushStyle()
    fontSize(14)
    fill(paint.white)
    
    local info = string.format(
        "framerate: %.3fms \nfrequency: %ifps \nmemory: %.0fkb",
        1000 * DeltaTime,
        math.floor(1/DeltaTime),
        collectgarbage("count")
    )
    
    local w, h = textSize(info)
    local x = WIDTH * pivotX - w * pivotX
    local y = HEIGHT * pivotY - h * pivotY
    collectgarbage()
    
    textMode(CORNER)
    textAlign(LEFT)
    textWrapWidth(w)
    text(info, x, y)
    
    popStyle()
end








-- Prettified output of tables
function printf(t, indent)
    if not indent then indent = "" end
    local names = {}
    for n, g in pairs(t) do
        table.insert(names, n)
    end
    table.sort(names)
    for i, n in pairs(names) do
        local v = t[n]
        if type(v) == "table" then
            if v == t then -- prevent endless loop on self reference
                print(indent..tostring(n)..": <-")
            else
                print(indent..tostring(n)..":")
                printf(v, indent.."   ")
            end
        elseif type(v) == "function" then
            print(indent..tostring(n).."()")
        else
            print(indent..tostring(n)..": "..tostring(v))
        end
    end
end





-- Deep-copy only values from given tables and merge them within a new table
function mergeTables(...)
    local arg = {...}
    local dump = {}
    
    local function copy(from, to)
        for _, value in pairs(from) do
            if type(value) == "table" then
                copy(value, to)
            else
                table.insert(to, value)
            end
        end
    end
    
    while #arg > 0 do
        copy(arg[1], dump)
        table.remove(arg, 1)
    end
    
    return dump
end






-- Check if given number is an integer (not a float)
function isInteger(n)
    return n == math.floor(n)
end





-- Check if given value is of type vec2, vec3 or vec4
local function isVector(value)
    return (type(value) == "userdata" and value.x and value.y) and true or false
end




-- Check if given value is of type table
function isTable(value)
    return type(value) == "table"
end






-- If a variable is nil then choose default-boolean otherwise take variables boolean value
function defaultBoolean(bool, default)
    return type(bool) == "nil" and default or bool
end






function sortTable(array, order, hierarchy)
    assert(order ~= nil and (order == "asc" or order == "desc"), "Missing sorting order: Must be 'asc' or 'desc'")
    
    local rnd = os.time()
    
    table.sort(array, function(l, r)
        if hierarchy then
            for _, key in ipairs(hierarchy) do
                l = l[key]
                r = r[key]
            end
        end
        
        assert(not isTable(l) and not isTable(r), "Failed to sort a table: Can not compare table values. Maybe a 'hierarchy' parameter is missing?")
        
        if isVector(l) then l = rnd * l.y + l.x end
        if isVector(r) then r = rnd * r.y + r.x end
        
        if not order or order == "asc" then return l < r end
        return l > r
    end)
end






-- Insert a substring into another string at any position
function stringInsert(str, sub_str, pos)
    pos = pos or #str+1 -- TODO use UTF8 method
    return  str:sub(1, pos) ..
            sub_str ..
            str:sub(pos+1, #str)
end






-- Extract substrings from string by separator
function stringExtract(str, sep)
    assert(sep, "separator needed")
    local list = {}
    for num in tostring(str):gmatch("[^"..sep.."]+") do
        table.insert(list, num)
    end
    return list
end





function rfc3986Encode(src)
    if not src then return "" end
    return tostring(src:gsub("[^-._~%w]", function(char)
        return string.format('%%%02X', char:byte()):upper()
    end))
end






function generateRandomString(length)
    local charset = "qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM0123456789"
    local rndnum  = math.random(1, #charset)
    local rndchar = charset:sub(rndnum, rndnum)
    if length > 0 then return generateRandomString(length - 1)..rndchar end
    return ""
end






-- Return rotated point around custom origin by certain degree
function rotatePoint(x, y, angle, cx, cy)
    cx = cx or 0
    cy = cy or 0
    local deg = math.rad(angle)
    local sin = math.sin(deg)
    local cos = math.cos(deg)
    return
        cx + (cos*(x-cx) - sin*(y-cy)),
        cy + (sin*(x-cx) + cos*(y-cy))
end






-- Convert point to a percentage value based on given width and height
-- Useful when dynamically positioning objects on screen
function pointRelative(abs_x, abs_y, width, height)
    return abs_x / width, abs_y / height
end





-- Convert point's percentage value back to a point on the screen
-- This is the reverse action of pnt_rel()
function pointAbsolute(rel_x, rel_y, width, height)
    return rel_x * width, rel_y * height
end







-- Map value from one range to another
function remapRange(val, a1, a2, b1, b2)
    return b1 + (val-a1) * (b2-b1) / (a2-a1)
end






-- Returns -1 or +1
-- math.random() can generate random values from -n to +n but there is always zero in between these ranges
-- If you just need a positive or negative multiplier then use this function to generate one
function randomSign()
    return 2 * math.random(1, 2) - 3
end






-- Round number from float to nearest integer based on adjacent delimiter
function roundNumber(float, limit)
    local i, f = math.modf(float)
    return f < limit and math.floor(float) or math.ceil(float)
end







-- Generate 2^n number sequence
-- [start]1, 2, 4, 8, 16, 32, 64, 128, ...[count]
function sequencePower2(count, start)
    local i = math.max(start or 0, 0)
    local j = i + count - 1
    local sequence = {}
    for n = i, j, 1 do
        table.insert(sequence, 2^n)
    end
    return sequence
end





-- Compare given number to array of numbers and return the closest one
function nearestNumber(n, array)
    local curr = array[1]
    for i = 1, #array do
        if math.abs(n - array[i]) < math.abs(n - curr) then
            curr = array[i]
        end
    end
    return curr
end






-- Calculate closest 2^n number to value
function nearestPower2(value)
    return math.log(value) / math.log(2)
end









-- Determine pixel positions on straight line
-- Can be used for A* search algorithm or pixelated line drawings
function bresenham(x1, y1, x2, y2)
    local p1 = vec2(math.min(x1, x2), math.min(y1, y2))
    local p2 = vec2(math.max(x1, x2), math.max(y1, y2))
    local delta = vec2(p2.x - p1.x, p1.y - p2.y)
    local err, e2 = delta.x + delta.y -- error value e_xy
    local buffer = {}
    
    while true do
        e2 = 2 * err
        if #buffer > 0 and buffer[#buffer].y == p1.y then -- increase previous line width
            buffer[#buffer].z = buffer[#buffer].z + 1
        elseif #buffer > 0 and buffer[#buffer].x == p1.x then -- increase previous line height
            buffer[#buffer].w = buffer[#buffer].w + 1
        else -- create new line
            table.insert(buffer, vec4(p1.x, p1.y, 1, 1)) -- image.set(x1, y1)
        end
        if p1.x == p2.x and p1.y == p2.y then break end
        if e2 > delta.y then err = err + delta.y; p1.x = p1.x + 1 end -- e_xy + e_x > 0
        if e2 < delta.x then err = err + delta.x; p1.y = p1.y + 1 end -- e_xy + e_y < 0
    end
    
    return buffer
end










-- Return perpendicular distance from point p0 to line defined by p1 and p2
function perpendicularDistance(p0, p1, p2)
    if p1.x == p2.x then
        return math.abs(p0.x - p1.x)
    end
    
    local m = (p2.y - p1.y) / (p2.x - p1.x) -- slope
    local b = p1.y - m * p1.x -- offset
    local dist = math.abs(p0.y - m * p0.x - b)
    
    return dist / math.sqrt(m*m + 1)
end









-- Curve fitting algorithm
function ramerDouglasPeucker(vertices, epsilon)
    epsilon = epsilon or .1
    local dmax = 0
    local index = 0
    local simplified = {}
    
    -- Find point at max distance
    for i = 3, #vertices do
        local d = perpendicularDistance(vertices[i], vertices[1], vertices[#vertices])
        if d > dmax then
            index = i
            dmax = d
        end
    end
    
    -- Recursively simplify
    if dmax >= epsilon then
        local list1 = {}
        local list2 = {}
        
        for i = 1, index - 1 do table.insert(list1, vertices[i]) end
        for i = index, #vertices do table.insert(list2, vertices[i]) end
        
        local result1 = ramerDouglasPeucker(list1, epsilon)
        local result2 = ramerDouglasPeucker(list2, epsilon)
        
        for i = 1, #result1 - 1 do table.insert(simplified, result1[i]) end
        for i = 1, #result2 do table.insert(simplified, result2[i]) end
    else
        for i = 1, #vertices do table.insert(simplified, vertices[i]) end
    end
    
    return simplified
end










-- Return random point inside a circle
function randomPointInCircle(radius)
    local t = 2 * math.pi * math.random()
    local u = math.random() + math.random()
    local r = u > 1 and (2-u) or u
    return
        radius * r * math.cos(t),
        radius * r * math.sin(t)
end










-- Test point in polygon
function pointInPoly(x, y, poly)
    local oddNodes = false
    local j = #poly
    
    for i = 1, j do
        if (poly[i].y < y and poly[j].y >= y or poly[j].y < y and poly[i].y >= y) and (poly[i].x <= x or poly[j].x <= x) then
            if poly[i].x + (y - poly[i].y) / (poly[j].y - poly[i].y) * (poly[j].x - poly[i].x) < x then
                oddNodes = not oddNodes
            end
        end
        j = i
    end
    
    return oddNodes
end















do -- define device simulators
    DeviceSimulator = class()
    
    DeviceSimulator.device_models = { -- list of available device models
        iPad11 = 'iPad',
        iPad12 = 'iPad 3G',
        iPad21 = '2nd Gen iPad',
        iPad22 = '2nd Gen iPad GSM',
        iPad23 = '2nd Gen iPad CDMA',
        iPad24 = '2nd Gen iPad New Revision',
        iPad25 = 'iPad mini',
        iPad26 = 'iPad mini GSM+LTE',
        iPad27 = 'iPad mini CDMA+LTE',
        iPad31 = '3rd Gen iPad',
        iPad32 = '3rd Gen iPad CDMA',
        iPad33 = '3rd Gen iPad GSM',
        iPad34 = '4th Gen iPad',
        iPad35 = '4th Gen iPad GSM+LTE',
        iPad36 = '4th Gen iPad CDMA+LTE',
        iPad41 = 'iPad Air (Wi-Fi)',
        iPad42 = 'iPad Air (GSM+CDMA)',
        iPad43 = 'iPad Air (China)',
        iPad44 = 'iPad mini Retina (Wi-Fi)',
        iPad45 = 'iPad mini Retina (GSM+CDMA)',
        iPad46 = 'iPad mini Retina (China)',
        iPad47 = 'iPad mini 3 (Wi-Fi)',
        iPad48 = 'iPad mini 3 (GSM+CDMA)',
        iPad49 = 'iPad mini 3 (China)',
        iPad51 = 'iPad mini 4 (Wi-Fi)',
        iPad52 = 'iPad mini 4 (Wi-Fi+LTE)',
        iPad53 = 'iPad Air 2 (Wi-Fi)',
        iPad54 = 'iPad Air 2 (Wi-Fi+LTE)',
        iPad611 = '5th Gen iPad (Wi-Fi)',
        iPad612 = '5th Gen iPad (Wi-Fi+LTE)',
        iPad63 = 'iPad Pro (9.7 inch Wi-Fi)',
        iPad64 = 'iPad Pro (9.7 inch Wi-Fi+LTE)',
        iPad67 = '1st Gen iPad Pro (12.9 inch Wi-Fi)',
        iPad68 = '1st Gen iPad Pro (12.9 inch Wi-Fi+LTE)',
        iPad71 = '2nd Gen iPad Pro (12.9 inch Wi-Fi)',
        iPad72 = '2nd Gen iPad Pro (12.9 inch Wi-Fi+LTE)',
        iPad73 = 'iPad Pro (10.5 inch Wi-Fi)',
        iPad74 = 'iPad Pro (10.5 inch Wi-Fi+LTE)'
    }
    
    DeviceSimulator.unique_resolutions = { -- all the different device resolutions
        xs = vec2(1024, 768), -- non-retina
        s = vec2(2048, 1536), -- retina
        m = vec2(2224, 1668), -- retina
        l = vec2(2732, 2048) -- retina
    }
    
    
    function DeviceSimulator:init(verbose)
        
        self.is_running = true -- drawing preview?
        self.show_info = defaultBoolean(verbose, true) -- show console output?
        
        self.devices = {} -- list for all available simulator devices
        
        self.this_device_model = deviceMetrics().platform:gsub(",", "") -- this devices model name
        self.this_device_name = self.device_models[self.this_device_model]
        self.this_device_identifier = nil
        
        self.scale_ratio = 1
        self.scale_percentage = 100
        
        
        -- Register available simulator devices and assign platforms to them
        
        self:addDevice("IPAD_XS", nil, nil, nil, 1, {
            self.device_models.iPad11,
            self.device_models.iPad12,
            self.device_models.iPad21,
            self.device_models.iPad22,
            self.device_models.iPad23,
            self.device_models.iPad24,
            self.device_models.iPad25,
            self.device_models.iPad26,
            self.device_models.iPad27
        })
        
        self:addDevice("IPAD_S", nil, nil, self.unique_resolutions.s, nil, {
            self.device_models.iPad31,
            self.device_models.iPad32,
            self.device_models.iPad33,
            self.device_models.iPad34,
            self.device_models.iPad35,
            self.device_models.iPad36,
            self.device_models.iPad611,
            self.device_models.iPad612,
            self.device_models.iPad41,
            self.device_models.iPad42,
            self.device_models.iPad43,
            self.device_models.iPad53,
            self.device_models.iPad54,
            self.device_models.iPad44,
            self.device_models.iPad45,
            self.device_models.iPad46,
            self.device_models.iPad47,
            self.device_models.iPad48,
            self.device_models.iPad49,
            self.device_models.iPad51,
            self.device_models.iPad52,
            self.device_models.iPad63,
            self.device_models.iPad64
        })
        
        self:addDevice("IPAD_M", 10.5, nil, self.unique_resolutions.m, nil, {
            self.device_models.iPad73,
            self.device_models.iPad74
        })
        
        self:addDevice("IPAD_L", 12.9, nil, self.unique_resolutions.l, nil, {
            self.device_models.iPad67,
            self.device_models.iPad68,
            self.device_models.iPad71,
            self.device_models.iPad72
        })
        
        self:setupUserInterface()
    end
    
    
    function DeviceSimulator:addDevice(simulator_name, display_size, aspect_ratio, screen_size, retina_scale_factor, device_models)
        table.insert(self.devices, {
            display_size = display_size or 9.7,
            display_units = "inch",
            aspect_ratio = aspect_ratio or vec2(4, 3),
            screen_size = screen_size or self.unique_resolutions.xs,
            screen_units = "pixel",
            content_scale_factor = 2, -- 1 Non-Retina, 2 Retina
            device_name = simulator_name,
            device_models = device_models or {"undefined"}
        })
        
        sortTable(self.devices, "asc", {"screen_size"}) -- sort simulators from smalest to largest
    end
    
    
    function DeviceSimulator:setupUserInterface()
        -- Identify this device within the available list
        
        for id, specs in pairs(self.devices) do
            for _, name in ipairs(specs.device_models) do
                if name == self.this_device_name then
                    self.this_device_identifier = id
                    break
                end
            end
        end
        
        if not self.this_device_identifier then
            print(string.format("Failed setting up debug tools: Missing Simulator for your device '%s'", self.this_device_model))
            return
        end
        
        parameter.integer("DEVICE_SIMULATOR", 1, #self.devices, self.this_device_identifier or 1, function()
            if self.is_running then
                self:updateUserInterface()
            end
        end)
        
        -- TODO make dedicated ui on screen because parameters sometimes create drawing glitches when changing state
        -- TODO clip() does not take scale() into account and is not supported by this utility yet!
    end
    
    
    function DeviceSimulator:updateUserInterface()
        local simulator_identifier = DEVICE_SIMULATOR
        local this_device_size = self.devices[self.this_device_identifier].screen_size
        local target_device_size = self.devices[simulator_identifier].screen_size
        local delta_x = target_device_size.x / this_device_size.x
        local delta_y = target_device_size.y / this_device_size.y
        
        if delta_y > delta_x then
            local _x = delta_x
            delta_x = delta_y
            delta_y = _x
        end
        
        self.scale_ratio = math.min(delta_x, delta_y)
        self.scale_percentage = math.ceil(self.scale_ratio * 100)
        
        -- Small Retina devices can be drawn at actual size
        if self.devices[simulator_identifier].content_scale_factor == 2
        and ContentScaleFactor * self.scale_ratio <= 1
        then
            self.scale_ratio = ContentScaleFactor * self.scale_ratio
            self.scale_percentage = 100
        end
        
        if self.show_info then
            print(string.format(
                "----------(!)----------\nSimulator resolution:\n%ix%ipx x%.2f @%i%%\n-\nConforming devices:\n%s\n--------------------",
                target_device_size.x,
                target_device_size.y,
                self.scale_ratio,
                self.scale_percentage,
                table.concat(self.devices[simulator_identifier].device_models, ",\n")
            ))
        end
    end
    
    
    function DeviceSimulator:draw() -- call this method always BEFORE other drawings
        if DEVICE_SIMULATOR and self.is_running then
            background(255, 0, 0)
            
            local device_size = self.devices[DEVICE_SIMULATOR].screen_size
            local w = device_size.x
            local h = device_size.y
            
            if self.scale_percentage < 100 then
                w = w / ContentScaleFactor
                h = h / ContentScaleFactor
            end
            
            clip(0, 0, w, h)
            
            fill(0, 255, 0)
            rect(0, 0, WIDTH, HEIGHT)
            
            scale(self.scale_ratio)
            
            -- TODO add letterbox scaling when Apple releases new devices that are not 4:3 aspect ratio (which is not the case right now)
        end
    end
    
end










do -- report only physical resolution changes
    local _orientationChanged = orientationChanged or function() end
    local portrait = table.concat({PORTRAIT, PORTRAIT_UPSIDE_DOWN, PORTRAIT_ANY}, ",")
    local landscape = table.concat({LANDSCAPE_LEFT, LANDSCAPE_RIGHT, LANDSCAPE_ANY}, ",")
    local previousOrientation = CurrentOrientation
    local previousWidth = WIDTH
    local previousHeight = HEIGHT
    
    local function name(orientation)
        return portrait:find(orientation) and "PORTRAIT" or "LANDSCAPE"
    end
    
    local function screen()
        return {
            previousOrientation = previousOrientation,
            currentOrientation = CurrentOrientation,
            previousOrientationName = name(previousOrientation),
            currentOrientationName = name(CurrentOrientation),
            previousWidth = previousWidth,
            currentWidth = WIDTH,
            previousHeight = previousHeight,
            currentHeight = HEIGHT
        }
    end
    
    function orientationChanged()
        if previousWidth ~= WIDTH or previousHeight ~= HEIGHT then -- device rotated 90°
            _orientationChanged(screen())
            previousOrientation = CurrentOrientation
            previousWidth = WIDTH
            previousHeight = HEIGHT
        elseif previousOrientation ~= CurrentOrientation then
            if (landscape:find(CurrentOrientation) and landscape:find(previousOrientation)) -- device rotated 180°
            or (portrait:find(CurrentOrientation) and portrait:find(previousOrientation))
            then
                _orientationChanged(screen())
                previousOrientation = CurrentOrientation
            end
        end
    end
end












do -- lock multitouch into gestures and provide more information about a touch
    
    RESTING = 3 -- new global touch state
    
    local touches = {}
    local expiredTouches = 0
    local gestureCountdown = .08 -- ADJUST!
    local touchesAutoDispatcher
    local dispatchTouches = touched or function() end
    
    
    function touched(touch)
        -- Identify touch
        local gesture, uid = #touches > 0 and touches[1].initTime + gestureCountdown < ElapsedTime
        for r, t in ipairs(touches) do
            if touch.id == t.id then uid = r end
            touches[r].state = RESTING
        end
        
        -- Cache updates
        local rt = touches[uid] or {}
        local template = {
            id = rt.id or touch.id,
            state = touch.state,
            tapCount = CurrentTouch.tapCount,
            initTime = rt.initTime or ElapsedTime,
            duration = ElapsedTime - (rt.initTime or ElapsedTime),
            initX = rt.initX or touch.x,
            initY = rt.initY or touch.y,
            x = touch.x,
            y = touch.y,
            prevX = touch.prevX,
            prevY = touch.prevY,
            deltaX = touch.deltaX,
            deltaY = touch.deltaY,
            radius = touch.radius,
            radiusTolerance = touch.radiusTolerance,
            force = remapRange(touch.radius, 0, touch.radius + touch.radiusTolerance, 0, 1)
        }
        
        if uid then
            -- Update touches
            touches[uid] = template
            
            -- Dispatch touches
            if touch.state == ENDED then
                -- First touch expired while gesture still active (or waiting to get active)
                if expiredTouches == 0 then
                    -- Gesture was waiting to get active
                    if touchesAutoDispatcher then
                        -- Sync all touch states to BEGAN
                        -- Still dispatch the planed BEGAN state from Auto-Dispatch
                        for r, t in ipairs(touches) do
                            touches[r].state = BEGAN
                            touches[r].initX = t.x
                            touches[r].initY = t.y
                        end
                        dispatchTouches(table.unpack(touches))
                        
                        -- Cancel gesture!
                        tween.reset(touchesAutoDispatcher)
                        touchesAutoDispatcher = nil
                    end
                    
                    -- Sync all touch states to ENDED
                    for r, t in ipairs(touches) do
                        touches[r].state = ENDED
                    end
                    -- Dispatch ENDED
                    dispatchTouches(table.unpack(touches))
                end
                
                -- Delete all touches when all expired
                expiredTouches = expiredTouches + 1
                if expiredTouches == #touches then
                    touches = {}
                    expiredTouches = 0
                end
            else
                -- Dispatch MOVING
                if not touchesAutoDispatcher and gesture and expiredTouches == 0 then
                    dispatchTouches(table.unpack(touches))
                end
            end
        else
            -- Register touch
            -- Ignore new touches when gesture already active
            if not gesture and touch.state == BEGAN then
                table.insert(touches, template)
                uid = #touches
                
                -- Auto-Dispatch touches
                if uid == 1 then
                    -- Dispatch BEGAN ... when gesture gets active
                    touchesAutoDispatcher = tween.delay(gestureCountdown, function()
                        -- Sync all touch states to BEGAN
                        for r, t in ipairs(touches) do
                            touches[r].state = BEGAN
                            touches[r].initX = t.x
                            touches[r].initY = t.y
                        end
                        -- Dispatch BEGAN
                        dispatchTouches(table.unpack(touches))
                        touchesAutoDispatcher = nil
                    end)
                end
            end
        end
    end
end



















-- With this functions you can create a thread (which is a namespace for a queue)
-- then you can use exec() to register functions that will run on this thread
-- these functions will be turned into coroutines automatically for you and run in a sequence

do
    local thread_stack = {}
    
    
    function createThread()
        table.insert(thread_stack, {})
        return thread_stack[#thread_stack]
    end
    
    
    function updateThreadQueue(thread) -- run this on each frame e.g. draw()
        assert(thread, "Target coroutine thread could not be found!")

        if thread and #thread > 0 then -- assert siliently
            if coroutine.status(thread[1]) == "dead" then
                table.remove(thread, 1)
            else
                coroutine.resume(thread[1])
            end
        end
    end
    
    
    function exec(thread, func, ...)
        assert(thread, "Target coroutine thread could not be found!")

        local params = {...}
        local routine = function() func(unpack(params)) end
        table.insert(thread, coroutine.create(routine))
    end
    
    
    function wait(thread, time)
        assert(thread, "Target coroutine thread could not be found!")

        exec(thread, function() -- run on thread
            local term = ElapsedTime + time
            while ElapsedTime <= term do
                coroutine.yield()
            end
        end)
    end
    
end















do -- extention to detect device shaking events
    local _draw = draw
    local eventTimer = .3 -- listener lifetime
    local intensity = 1.0 -- min. shake intensity to trigger this event
    local shakeEventBeganAt
    local shakeEventUpdatedAt
    
    -- Rewrite Codea's draw method to support additional API from above
    function draw()
        if UserAcceleration.x > intensity or UserAcceleration.y > intensity or UserAcceleration.z > intensity then
            shakeEventUpdatedAt = ElapsedTime
            shakeEventBeganAt = shakeEventBeganAt or shakeEventUpdatedAt
            
            if ElapsedTime - shakeEventBeganAt >= eventTimer then
                -- Provide a deviceShaking() callback function to respond to shake events
                -- Works similar to orientationChanged()
                -- The first rough shake will trigger the listening process
                -- The event handler will then listen next n seconds to see if the shake motion continues
                deviceShaking()
            end
        end
        
        if shakeEventUpdatedAt and ElapsedTime > shakeEventBeganAt + eventTimer then
            shakeEventUpdatedAt = nil
            shakeEventBeganAt = nil
        end
        
        if _draw then
            _draw()
        end
    end
end











-- Gather uv information about any rectangular region (set of tiles) on a texture
-- Get a sequence of all region-rects from i to j where each sub-region is a tile of width x height
-- The 'explicit'-flag returns only tiles enclosed by the overall region from i to j (skipping the appendices and in-betweens)
-- Regions are described by their index position on texture - reading from top left corner on texture, indices are: 1,2,3...n
-- i and j indices might also be passed as vec2(col, row) which is convenient when spritesheet dimensions grow over time and where sprite indices might shift


function uvTexture(texture, region_width, region_height, i, j, explicit)
    local cols = texture.width / region_width
    local rows = texture.height / region_height
    
    -- Get sprite index from col and row
    local function getId(cell)
        return (cell.y - 1) * cols + cell.x
    end
    
    -- Get col and row from sprite index
    local function getCell(id)
        local rem = id % cols
        local col = (rem ~= 0 and rem or cols) - 1
        local row = rows - math.ceil(id / cols)
        return col, row
    end
    
    i = i and (type(i) == "number" and i or getId(i)) or 1 -- be sure to deal always with number indices
    j = j and (type(j) == "number" and j or getId(j)) or i
    
    local minCol, minRow = getCell(i)
    local maxCol, maxRow = getCell(j)
    local tiles = {}
    local region = {}
    
    -- Collect all tiles enclosed by i and j
    for k = i, j do
        local col, row = getCell(k)
        local w = 1 / cols
        local h = 1 / rows
        local u = w * col
        local v = h * row
        
        if not explicit
        or (col >= minCol and col <= maxCol)
        then
            table.insert(tiles, {
                id = k, -- region rect index on spritesheet
                col = col + 1, -- example: tile at {col = 1, row = 1}
                row = row + 1, -- would be at the lower left corner, because of OpenGL and Codea convention!
                x = col * region_width, -- {x, y} is the lower left corner position of the tile at {col, row}
                y = row * region_height,
                width = region_width,
                height = region_height,
                uv = {
                    x1 = u,
                    y1 = v,
                    x2 = u + w,
                    y2 = v + h,
                    w = w,
                    h = h
                }
            })
        end
    end
    
    -- Sort tiles by column and row in ascending order
    table.sort(tiles, function(curr, list)
        return curr.row == list.row and curr.col < list.col or curr.row < list.row
    end)
    
    -- Describe the overall region-rect
    local region = {
        x = tiles[1].x,
        y = tiles[1].y,
        width = tiles[#tiles].x + tiles[#tiles].width - tiles[1].x,
        height = tiles[#tiles].y + tiles[#tiles].height - tiles[1].y,
        uv = {
            x1 = tiles[1].uv.x1,
            y1 = tiles[1].uv.y1,
            x2 = tiles[#tiles].uv.x2,
            y2 = tiles[#tiles].uv.y2,
            w = tiles[#tiles].uv.x2 - tiles[1].uv.x1,
            h = tiles[#tiles].uv.y2 - tiles[1].uv.y1
        }
    }
    
    return region, tiles
end













-- Create textured and animated mesh quad
-- Note: available animations are listed as `name = {list of frames as vec2}` pairs
--
-- @params {}:
-- texture: image
-- tilesize: vec2
-- spritesize: vec2
-- position: vec2
-- pivot: vec2 [0-1]
-- animations: {}
-- current_animation: "string"
-- fps: number
-- loop: boolean
-- tintcolor: color()
--

function GSprite(params)
    local quad = mesh()
    local _draw = quad.draw
    
    for name, prop in pairs(params) do
        quad[name] = prop -- copy all params
    end
    
    quad.tintcolor = quad.tintcolor or color(255)
    quad.spritesize = quad.spritesize or quad.tilesize
    quad.position = quad.position or vec2()
    quad.pivot = quad.pivot or vec2()
    quad.current_frame = 1
    quad.fps = quad.fps or 24
    quad.loop = defaultBoolean(quad.loop, true)
    quad:addRect(0, 0, 0, 0)
    
    function quad.draw(self)
        if not self.timer or self.timer <= ElapsedTime then
            local anim = self.animations[self.current_animation]
            local frm = self.current_frame
            local uv = uvTexture(self.texture, self.tilesize.x, self.tilesize.y, anim[frm]).uv
            
            self:setRectTex(1, uv.x1, uv.y1, uv.w, uv.h)
            self.timer = ElapsedTime + 1 / self.fps
            self.current_frame = anim[frm + 1] and frm + 1 or 1
            
            if frm == #anim and not self.loop then
                self.current_frame = frm -- pull back
            end
        end
        
        pushStyle()
        noSmooth()
        pushMatrix()
        translate(self.position.x - self.pivot.x * self.spritesize.x, self.position.y - self.pivot.y * self.spritesize.y)
        self:setColors(self.tintcolor)
        self:setRect(1, self.spritesize.x/2, self.spritesize.y/2, self.spritesize.x, self.spritesize.y)
        _draw(self)
        popMatrix()
        popStyle()
    end
    
    return quad
end













do
    UISlider = class()
    
    
    function UISlider:init(x, y, width, height, min, max, init)
        -- slider values (min, max, init) can be any positive or negative float or integer numbers e.g. [0.0-1.0] or [(-n)-m]
        -- all properties can be set directly but optional convenience methods are available to overcome some side effects
        
        self.is_active = false
        self.title = nil -- no title
        self.x = x or 0
        self.y = y or 0
        self.width = width or 180
        self.height = height or 48
        self.min = min or 0
        self.max = max or 1
        self.value = init or self.min
        self.value_format = "%.2f" -- float with 2 decimals; to hide set to an empty string
        self.snap_to = {} -- TODO list of slider values to snap to
        self.step_length = .1
        self.step_accuracy = .0003 -- increase divider to be more accurate while sliding the value
        self.state_width = self.width -- any remainder would be used to align title on the left; without any remainder title is placed over slider and slider value is hidden
        self.state_min_width = 2
        self.state_color = color(255, 208, 0)
        self.text_color = color(255)
        self.bg_color = color(60, 60, 59)
    end
    
    
    function UISlider:setTitle(txt, width) -- change title and align to the left
        -- title requires space provided by the remainder of state_width to be positioned to the left of the slider
        -- without any remainder title would be overlayed and the slider value would be hidden (which might be a desired effect)
        -- this function prevents the effect
        
        local w, h = textSize(txt)
        self.title = txt
        self.state_width = width and (self.width - width) or (self.width - w)
    end
    
    
    function UISlider:setSize(width, height) -- change slider size but retain previous dimension ratios between title and progress bar
        local title_width = self.width - self.state_width
        self.width = width
        self.state_width = self.width
        self.height = height
        
        if title_width > 0 then -- title was aligned left so just stretch the state_width
            self.state_width = self.width - title_width
        end
    end
    
    
    function UISlider:increase(by_value)
        self.value = math.min(self.value + math.abs(by_value), self.max)
    end
    
    
    function UISlider:decrease(by_value)
        self.value = math.max(self.value - math.abs(by_value), self.min)
    end
    
    
    function UISlider:draw()
        if not self.title and self.width ~= self.state_width then
            self.state_width = self.width
        end
        
        if self.state_stepper then
            if self.state_stepper > 0 then
                self:increase(self.state_stepper)
            else
                self:decrease(self.state_stepper)
            end
        end
        
        local h = self.height
        local w = self.state_width -- slider width at full progress excluding
        local percent = (self.value - self.min) * 100 / (self.max - self.min) -- progress percentage
        local p = percent / 100 -- percentage multiplier 0-1
        local rem = self.width - w -- title width
        local val = string.format(self.value_format, self.value)
        local vw, vh = textSize(val)
        local tw, th = textSize(self.title)
        
        pushStyle()
        
        font("HelveticaNeue-Light")
        fontSize(20)
        textMode(CORNER)
        textAlign(LEFT)
        textWrapWidth(self.width)
        
        fill(self.bg_color)
        rectMode(CORNER)
        rect(self.x, self.y, self.width, h)
        
        if rem > 0 then -- we can assume that we have title and its aligned left
            fill(self.state_color)
            rect(self.x + rem, self.y, math.max(self.state_min_width, w*p), h)
            
            fill(self.text_color)
            fontSize(14)
            text(val, math.min(self.x + rem + w*p, self.x + self.width - vw), self.y + h/2 - vh/2)
            
            fontSize(20)
            text(self.title, self.x, self.y + h/2 - th/2)
        else
            fill(self.state_color)
            rect(self.x, self.y, math.max(self.state_min_width, w*p), h)
            
            fill(self.text_color)
            
            if not self.title then
                fontSize(14)
                text(val, self.x + w/2 - vw/2, self.y + h/2 - vh/2)
            else
                fontSize(20)
                text(self.title, self.x + w/2 - tw/2, self.y + h/2 - th/2)
            end
        end
        
        popStyle()
    end
    
    
    function UISlider:touched(touch)
        if touch.state == BEGAN
        and touch.x > self.x and touch.x < self.x + self.width
        and touch.y > self.y and touch.y < self.y + self.height
        then
            self.is_active = true
        end
        
        if touch.state == MOVING
        and touch.initX > self.x and touch.initX < self.x + self.width
        and touch.initY > self.y and touch.initY < self.y + self.height
        then
            local length = touch.x - touch.initX -- touch delta
            local steps = length * self.step_accuracy
            self.state_stepper = steps
        end
        
        if touch.state == ENDED then
            if not self.state_stepper
            and touch.initX > self.x and touch.initX < self.x + self.width -- tapped somewhere on the slider so increment by default step_length
            and touch.initY > self.y and touch.initY < self.y + self.height
            and touch.y > self.y and touch.y < self.y + self.height
            then
                if touch.x > self.x and touch.x < self.x + self.width/2 then -- tapped left side of the slider
                    self:decrease(self.step_length)
                elseif touch.x > self.x + self.width/2 and touch.x < self.x + self.width then -- tapped right side of the slider
                    self:increase(self.step_length)
                end
            end
            self.state_stepper = nil
            self.is_active = false
        end
    end
end












do
    UISwitch = class(UISlider) -- fake a boolean switch by (mis)using UISlider class
    
    
    function UISwitch:init(x, y, state_on, name)
        if state_on and type(state_on) ~= "boolean" then
            error("Function parameter #4 'state_on' must be a boolean")
        end
        
        UISlider.init(self, x, y, nil, nil, 0, 1, state_on and 1 or 0)
        self.step_length = 1
        
        if name then
            self:setTitle(name, self.width/3)
        end
    end
    
    
    function UISwitch:draw()
        if self.value < self.max then
            self.value_format = "off"
        else
            self.value_format = "on"
        end
        
        UISlider.draw(self)
    end
    
    
    function UISwitch:touched(touch)
        if touch.state == ENDED
        and touch.initX > self.x and touch.initX < self.x + self.width
        and touch.initY > self.y and touch.initY < self.y + self.height
        and touch.x > self.x and touch.x < self.x + self.width
        and touch.y > self.y and touch.y < self.y + self.height
        then
            if self.value < self.max then
                self.value = self.max
            else
                self.value = self.min
            end
        end
    end
end













do
    UIButton = class()
    
    
    function UIButton:init(title, x, y, width, height, callback)
        self.title = title -- button without title and bg_color can be used as hidden trigger
        self.title_format = "%s"
        self.is_active = false -- hovered or tapped?
        self.x = x or 0
        self.y = y or 0
        self.width = width or 80
        self.height = height or 48
        self.callback = callback
        self.text_color = color(68, 128, 223)
        self.text_hover_color = color(225, 208, 0)
        self.bg_color = color(60, 60, 59)
        self.bg_hover_color = self.bg_color
        self.bg_image = nil -- either plain image or a table of 9 images (listed from top left to bottom right)
    end
    
    
    function UIButton:draw()
        pushStyle()
        
        noStroke()
        fill(self.is_active and self.bg_hover_color or self.bg_color)
        rectMode(CORNER)
        rect(self.x, self.y, self.width, self.height)
        
        if self.bg_image then
            if type(self.bg_image) ~= "table" then
                spriteMode(CORNER)
                sprite(self.bg_image, self.x, self.y, self.width, self.height)
            else
                local w = math.max(
                    self.bg_image[1].width + self.bg_image[3].width, -- top row
                    self.bg_image[7].width + self.bg_image[9].width  -- bottom row
                )
                local h = math.max(
                    self.bg_image[1].height + self.bg_image[7].height, -- left column
                    self.bg_image[3].height + self.bg_image[9].height  -- right column
                )
                
                if w > self.width or h > self.height then
                    -- TODO maybe show an alert that the bg_image was not assigned (but be careful we are in the draw loop!)
                    --print("Failed to assign bg_image to UIButton because image was too large")
                else
                    spriteMode(CORNER)
                    sprite( -- top row, left
                        self.bg_image[1],
                        self.x,
                        self.y + self.height - self.bg_image[1].height,
                        self.bg_image[1].width,
                        self.bg_image[1].height
                    )
                    sprite( -- top row, center
                        self.bg_image[2],
                        self.x + self.bg_image[1].width,
                        self.y + self.height - self.bg_image[2].height,
                        self.width - self.bg_image[1].width - self.bg_image[3].width,
                        self.bg_image[2].height
                    )
                    sprite( -- top row, right
                        self.bg_image[3],
                        self.x + self.width - self.bg_image[3].width,
                        self.y + self.height - self.bg_image[3].height,
                        self.bg_image[3].width,
                        self.bg_image[3].height
                    )
                    sprite( -- center row, left
                        self.bg_image[4],
                        self.x,
                        self.y + self.bg_image[7].height,
                        self.bg_image[4].width,
                        self.height - self.bg_image[1].height - self.bg_image[7].height
                    )
                    sprite( -- center row, center
                        self.bg_image[5],
                        self.x + self.bg_image[4].width,
                        self.y + self.bg_image[8].height,
                        self.width - self.bg_image[4].width - self.bg_image[6].width,
                        self.height - self.bg_image[2].height - self.bg_image[8].height
                    )
                    sprite( -- center row, right
                        self.bg_image[6],
                        self.x + self.width - self.bg_image[6].width,
                        self.y + self.bg_image[9].height,
                        self.bg_image[6].width,
                        self.height - self.bg_image[3].height - self.bg_image[9].height
                    )
                    sprite( -- bottom row, left
                        self.bg_image[7],
                        self.x,
                        self.y,
                        self.bg_image[7].width,
                        self.bg_image[7].height
                    )
                    sprite( -- bottom row, center
                        self.bg_image[8],
                        self.x + self.bg_image[7].width,
                        self.y,
                        self.width - self.bg_image[7].width - self.bg_image[9].width,
                        self.bg_image[7].height
                    )
                    sprite( -- bottom row, right
                        self.bg_image[9],
                        self.x + self.width - self.bg_image[9].width,
                        self.y,
                        self.bg_image[9].width,
                        self.bg_image[9].height
                    )
                end
            end
        end
        
        if self.title then
            fill(self.is_active and self.text_hover_color or self.text_color)
            font("HelveticaNeue-Light")
            fontSize(20)
            textMode(CENTER)
            textAlign(CENTER)
            textWrapWidth(self.width)
            text(string.format(self.title_format, self.title), self.x + self.width/2, self.y + self.height/2)
        end
        
        popStyle()
    end
    
    
    function UIButton:touched(touch)
        if touch.state == BEGAN
        and touch.x > self.x and touch.x < self.x + self.width
        and touch.y > self.y and touch.y < self.y + self.height
        then
            self.is_active = true
        end
        
        if touch.state == ENDED then
            if self.callback
            and touch.initX > self.x and touch.initX < self.x + self.width
            and touch.initY > self.y and touch.initY < self.y + self.height
            and touch.x > self.x and touch.x < self.x + self.width
            and touch.y > self.y and touch.y < self.y + self.height
            then
                self.callback()
            end
            self.is_active = false
        end
    end
end














do
    UIAlert = class()
    
    
    function UIAlert:init(message, x, y, width, height)
        self.is_active = false
        self.message = message or "Sorry"
        self.text_color = color(255)
        self.bg_color = color(60, 60, 59)
        
        self.width = width or 280
        self.height = height or 160
        self.x = x or (WIDTH/2 - self.width/2)
        self.y = y or (HEIGHT/2 - self.height/2)
        
        self.left_button = UIButton("Cancel")
        self.right_button = UIButton("Ok")
        self.left_button.callback = function() self:dismiss() end
        self.right_button.callback = function() self:dismiss() end
    end
    
    
    function UIAlert:open()
        self.is_active = true
    end
    
    
    function UIAlert:dismiss()
        self.is_active = false
    end
    
    
    function UIAlert:draw()
        if self.is_active then
            pushStyle()
            
            fill(self.bg_color)
            rectMode(CORNER)
            rect(self.x, self.y, self.width, self.height)
            
            font("HelveticaNeue-Light")
            fontSize(20)
            textMode(CENTER)
            textAlign(CENTER)
            textWrapWidth(self.width)
            fill(self.text_color)
            text(self.message, self.x + self.width/2, self.y + self.height/2 + self.left_button.height/2)
            
            self.left_button.width = self.width/2
            self.left_button.x = self.x
            self.left_button.y = self.y
            self.right_button.width = self.width/2
            self.right_button.x = self.x + self.width/2
            self.right_button.y = self.y
            self.left_button:draw()
            self.right_button:draw()
            
            popStyle()
        end
    end
    
    
    function UIAlert:touched(touch)
        if self.is_active then
            self.left_button:touched(touch)
            self.right_button:touched(touch)
            
            if touch.state == BEGAN
            and touch.x > self.x and touch.x < self.x + self.width
            and touch.y > self.y + self.left_button.height and touch.y < self.y + self.height
            then
                self.is_moving = true
            end
            
            if touch.state == MOVING and self.is_moving then
                self.x = self.x + touch.deltaX
                self.y = self.y + touch.deltaY
            end
            
            if touch.state == ENDED then
                self.is_moving = nil
            end
        end
    end
end















do
    UIImagePicker = class() -- this class could have inherited from UIAlert but almoust everything would be overriden anyway so well...
    
    -- override .btn_left.callback and .btn_right.callback to provide custom error and success handlers e.g.
    -- image_picker = UIImagePicker(...)
    -- image_picker.btn_right.callback = function()
    --     print(image_picker.selected_asset) -- do something with the selected image from the picker
    --     -- you can also access this property later but it will be reset on the next image_picker:open() call!
    --     image_picker:dismiss() -- close the dialog
    -- end
    
    function UIImagePicker:init(x, y, width, height)
        self.is_active = false
        self.assets = {}
        self.selected_asset = nil
        self.mipmaps = {} -- preview images at low-res
        self.text_color = color(255)
        self.selection_color = color(112, 111, 111)
        self.bg_color = color(60, 60, 59)
        
        self.width = width or (WIDTH/2)
        self.height = height or (HEIGHT/2)
        self.row_height = 48 -- height for each asset entry in the list
        self.bottom_whitespace = 48 -- shortens the content height by this value; mostly used to append buttons that should don't cover the asset list
        self.x = x or (self.width/2)
        self.y = y or (self.height/2)
        self.scroll = 0
        self.pagination_format = "%s" -- to hide pagination assign empty string
        
        self.btn_left = UIButton("Cancel")
        self.btn_left.callback = function()
            self.selected_asset = self._selected_asset -- restore (cached on self:open())
            self:dismiss()
        end
        
        self.btn_right = UIButton("Ok")
        self.btn_right.callback = function() self:dismiss() end
    end
    
    
    function UIImagePicker:open()
        local fetch_locations = {"Project", "Documents", "Dropbox"}
        self._selected_asset = self.selected_asset -- cache
        self.mipmaps = {} -- reset
        self.assets = {} -- reset
        self.is_active = true
        
        for i, pack_name in ipairs(fetch_locations) do
            for j, asset_path in ipairs(assetList(pack_name, SPRITES)) do
                local img = readImage(pack_name..":"..asset_path)
                local mipmap = image(self.row_height, self.row_height)
                local scaler = self.row_height / math.max(img.width, img.height)
                local h = img.height * scaler
                local w = img.width * scaler
                local spacer_x = (self.row_height - w)/2
                local spacer_y = (self.row_height - h)/2
                
                setContext(mipmap)
                spriteMode(CORNER)
                sprite(img, spacer_x, spacer_y, w, h)
                setContext()
                
                table.insert(self.assets, pack_name..":"..asset_path)
                table.insert(self.mipmaps, mipmap)
            end
        end
    end
    
    
    function UIImagePicker:dismiss()
        self.is_active = false
    end
    
    
    function UIImagePicker:draw()
        if self.is_active then
            local view_height = self.height - self.bottom_whitespace
            local num_elements = #self.assets
            local list_height = num_elements * self.row_height
            local num_visible_elements = view_height / self.row_height
            local num_passed_elements = self.scroll / self.row_height
            
            pushStyle()
            
            fill(self.bg_color)
            rectMode(CORNER)
            rect(self.x, self.y, self.width, self.height)
            
            font("HelveticaNeue-Light")
            fontSize(14)
            textMode(CORNER)
            textAlign(LEFT)
            textWrapWidth(self.width)
            
            pushMatrix()
            translate(0, self.height + self.scroll)
            
            clip(self.x, self.y + self.bottom_whitespace, self.width, self.height - self.bottom_whitespace) -- TODO resppond to scale() - maybe override this build-in function to add that support at global scope
            
            do -- list of assets
                local from = math.max(1, math.ceil(num_passed_elements))
                local to = math.min(num_elements, math.ceil(num_passed_elements + num_visible_elements))
                
                for id = from, to do
                    local asset_path = self.assets[id]
                    local asset_img = self.mipmaps[id]
                    local tw, th = textSize(asset_path)
                    
                    if self.selected_asset and self.selected_asset == asset_path then
                        fill(self.selection_color)
                        rect(self.x, self.y - self.row_height * id, self.width, self.row_height)
                    end
                    
                    fill(self.text_color)
                    spriteMode(CORNER)
                    sprite(asset_img, self.x, self.y - self.row_height * id)
                    text(asset_path, self.x + asset_img.width + 4, self.y - self.row_height * id + th)
                end
            end
            
            clip()
            popMatrix()
            
            do -- pagination instead of scroll bar
                local num_pages = list_height / view_height
                local num_passed_pages = self.scroll / view_height + 1 -- first page already displaying so count it in as +1
                local pagination = math.max(1, math.floor(num_passed_pages)).."/"..math.max(1, math.ceil(num_pages))
                local pw, ph = textSize(pagination)
                
                fill(self.selection_color)
                text(string.format(self.pagination_format, pagination), self.x + self.width - pw, self.y + self.height - self.row_height + ph)
            end
            
            self.btn_left.width = self.width/2
            self.btn_left.x = self.x
            self.btn_left.y = self.y
            self.btn_right.width = self.width/2
            self.btn_right.x = self.x + self.width/2
            self.btn_right.y = self.y
            
            self.btn_left:draw()
            self.btn_right:draw()
            
            popStyle()
        end
    end
    
    
    function UIImagePicker:touched(touch)
        if self.is_active then
            self.btn_left:touched(touch)
            self.btn_right:touched(touch)
            
            if self.btn_left.is_active or self.btn_right.is_active then
                return -- prevent touch propagation
            end
            
            if touch.state == MOVING
            and touch.initX > self.x and touch.initX < self.x + self.width
            and touch.initY > self.y + self.bottom_whitespace and touch.initY < self.y + self.height
            then
                local scroll = self.scroll + touch.deltaY
                local list_height = #self.assets * self.row_height
                self.is_scrolling = true
                
                if scroll > 0 then -- clamp the scrolling overflow
                    self.scroll = math.min(scroll, list_height + self.bottom_whitespace - self.height)
                else
                    self.scroll = math.max(0, scroll)
                end
            end
            
            if touch.state == ENDED then
                if not self.is_scrolling
                and touch.initX > self.x and touch.initX < self.x + self.width
                and touch.initY > self.y + self.bottom_whitespace and touch.initY < self.y + self.height
                and touch.x > self.x and touch.x < self.x + self.width
                and touch.y > self.y + self.bottom_whitespace and touch.y < self.y + self.height
                then
                    for id = 1, #self.assets do
                        local offset = self.height + self.scroll
                        local y = offset + self.y - self.row_height * id
                        
                        if touch.y > y and touch.y < y + self.row_height
                        and touch.initY > y and touch.initY < y + self.row_height
                        then
                            if self.selected_asset ~= self.assets[id] then
                                self.selected_asset = self.assets[id]
                            else
                                self.selected_asset = nil
                            end
                        end
                    end
                end
                self.is_scrolling = nil
            end
        end
    end
end















-- simple code generator for creating and animating meshes pragmatically
-- create and animate your 'mesh net' then copy the code and paste it somewhere in your project
-- later use e.g. ssprite() to display generated mesh and play its animation from the code you generated
do
    MeshRig = class()
    
    
    function MeshRig:init()
        self.is_running = true
        self.ds_width = .2 -- WIDTH multiplier for the dopesheet
        self.ds_scroll = 0
        self.vertex_gimbal_size = 16
        self.vertices = {
            vec2(-.5, -.5), -- init with a rect
            vec2(.5, -.5),
            vec2(.5, .5),
            vec2(-.5, .5)
        }
        self.frames = {}
        self.selected_vertices = {}
        self.selected_frames = {}
        self.dragged_objects = nil -- reference to self.selected_vertices or self.selected_frames
        
        self.mesh = mesh()
        self.mesh:resize(250) -- NOTE: if Codea crashes try increase the buffer size!
        self.mesh.vertex_buffer = self.mesh:buffer("position")
        self.mesh.texture_buffer = self.mesh:buffer("texCoord")
        
        self.alert = UIAlert()
        self.image_picker = UIImagePicker()
        self.image_picker.bottom_whitespace = 96
        
        self.image_picker.btn_onion = UISlider()
        self.image_picker.btn_onion.title = "Onion"
        self.image_picker.btn_onion.value = 0
        self.image_picker.btn_onion.value_format = ""
        
        self.image_picker.btn_wire = UISlider()
        self.image_picker.btn_wire.title = "Wire"
        self.image_picker.btn_wire.value = 1
        self.image_picker.btn_wire.value_format = ""
        
        self.image_picker.btn_dark = UISlider()
        self.image_picker.btn_dark.title = "Dark"
        self.image_picker.btn_dark.value = 1
        self.image_picker.btn_dark.value_format = ""
        
        self.btn_remove = UIButton("–")
        self.btn_create = UIButton("+")
        self.btn_skin = UIButton("Skin")
        self.btn_paste = UIButton("Paste")
        self.btn_copy = UIButton("Copy")
        
        
        self.btn_skin.callback = function() self.image_picker:open() end
        self.btn_paste.callback = function() print("evaluate and run code from pasteboard") end
        self.btn_copy.callback = function() print("serialize and copy code to pasteboard") end
        
        
        function self.image_picker.open(this) -- override default method
            this._btn_onion_value = this.btn_onion.value -- cache
            this._btn_wire_value = this.btn_wire.value -- cache
            this._btn_dark_value = this.btn_dark.value -- cache
            UIImagePicker.open(this) -- also call default method (which caches the .selected_asset)
        end
        
        
        function self.image_picker.btn_left.callback() -- override default method of the cancel button
            self.image_picker.btn_onion.value = self.image_picker._btn_onion_value -- restore
            self.image_picker.btn_wire.value = self.image_picker._btn_wire_value -- restore
            self.image_picker.btn_dark.value = self.image_picker._btn_dark_value -- restore
            self.image_picker.selected_asset = self.image_picker._selected_asset -- restore (cached on self:open())
            self.image_picker:dismiss()
        end
        
        
        function self.image_picker.draw(this) -- override default method
            if this.is_active then
                this.btn_onion.width = this.width/3
                this.btn_onion.state_width = this.btn_onion.width
                this.btn_onion.x = this.x
                this.btn_onion.y = this.y + this.btn_left.height
                
                this.btn_wire.width = this.width/3
                this.btn_wire.state_width = this.btn_wire.width
                this.btn_wire.x = this.x + this.width/3
                this.btn_wire.y = this.y + this.btn_left.height
                
                this.btn_dark.width = this.width/3
                this.btn_dark.state_width = this.btn_dark.width
                this.btn_dark.x = this.x + this.width/3*2
                this.btn_dark.y = this.y + this.btn_left.height
                
                UIImagePicker.draw(this)
                
                this.btn_onion:draw()
                this.btn_wire:draw()
                this.btn_dark:draw()
            end
        end
        
        
        function self.image_picker.touched(this, touch) -- override default method
            if this.is_active then
                UIImagePicker.touched(this, touch) -- call the default method
                this.btn_onion:touched(touch)
                this.btn_wire:touched(touch)
                this.btn_dark:touched(touch)
            end
        end
        
        
        function self.btn_remove.touched(this, touch) -- override default touch handler
            -- where 'this' is object instance scope
            -- and 'self' is MeshRig class context
            
            if touch.state ~= ENDED -- activate button whenever touch is over it
            and touch.x > this.x and touch.x < this.x + this.width
            and touch.y > this.y and touch.y < this.y + this.height
            then
                this.is_active = true
            else
                this.is_active = false
            end
            
            if touch.state == ENDED 
            and touch.x > this.x and touch.x < this.x + this.width -- touch ended inside the button
            and touch.y > this.y and touch.y < this.y + this.height
            then
                if touch.initX > this.x and touch.initX < this.x + this.width -- touch began on the button
                and touch.initY > this.y and touch.initY < this.y + this.height
                then
                    self:removeFrames()
                else -- touch began outside of the button
                    if self.dragged_objects then
                        print("dropped something onto the btn_remove")
                    end
                end
            end
        end
        
        
        function self.btn_create.touched(this, touch) -- override default touch handler
            -- where 'this' is object instance scope
            -- and 'self' is MeshRig class context
            
            if touch.state == BEGAN
            and touch.x > this.x and touch.x < this.x + this.width
            and touch.y > this.y and touch.y < this.y + this.height
            then
                this.is_active = true
            end
            
            if touch.state == ENDED then
                this.is_active = false
                
                if touch.initX > this.x and touch.initX < this.x + this.width -- touch began on the button
                and touch.initY > this.y and touch.initY < this.y + this.height
                then
                    if touch.x < WIDTH * self.ds_width -- touch ended on the dopesheet
                    or (touch.x > this.x and touch.x < this.x + this.width -- OR touch ended inside the button
                    and touch.y > this.y and touch.y < this.y + this.height)
                    then
                        self:addFrame()
                    else
                        self:addVertex(touch.x, touch.y)
                    end
                end
            end
        end
    end
    
    
    function MeshRig:addVertex(x, y) -- create vertex at coordinates
        table.insert(self.vertices, vec2(x, y))
    end
    
    
    function MeshRig:findVertex(x, y) -- find vertex id by coordinates
        for id, pos in ipairs(self.vertices) do
            local half_size = self.vertex_size/2
            if x > pos.x - half_size and x < pos.x + half_size and y > pos.y - half_size and y < pos.y + half_size then
                return id
            end
        end
    end
    
    
    function MeshRig:moveVertices(x, y, vertex_ids, frame_ids) -- key or alter vertex positions
        if frame_ids and vertex_ids then -- use custom list for iteration
            for _, fid in ipairs(frame_ids) do
                for _, vid in ipairs(vertex_ids) do
                    self.frames[fid][vid] = vec2(x, y)
                end
            end
            
            return
        end
        
        for fid, vertices in ipairs(self.frames) do -- reference the self.selected_ lists for iteration
            if fid == self.selected_frames[fid] then -- frame is in list of selected frames
                for vid, vertex in pairs(vertices) do
                    if vid == self.selected_vertices[vid] then -- vertex is in list of selected vertices
                        self.frames[fid][vid] = vec2(x, y)
                    end
                end
            end
        end
    end
    
    
    function MeshRig:removeVertices(blacklist) -- remove blacklisted or selected vertices
        for _, id in ipairs(blacklist or self.selected_vertices) do
            table.remove(self.vertices, id)
            
            for fid, vertices in ipairs(self.frames) do
                for vid, _ in pairs(vertices) do
                    if id == vid then
                        self.frames[fid] = nil -- find if vert was keyed somewhere and remove the reference to it
                        break
                    end
                end
            end
        end
    end
    
    
    function MeshRig:addFrame(hierarchy_pos_id) -- create frame at id in the hierarchy
        -- UISlider template
        
        local slider = UISlider() -- don't let you mislead, it's still a frame (layer) not a slider...
        slider.keyed_vertices = {} -- indices list of self.vertices that have been changed inside this particular frame
        slider.value = .25 -- default frame duration in seconds
        
        function slider.touched(this, touch, frame_id) -- override default touch handler
            -- where 'this' is object instance scope
            -- and 'self' is MeshRig class context
            
            if touch.state == BEGAN then
                this.is_active = true
            end
            
            if touch.state == MOVING then
                local length = touch.x - touch.initX -- touch delta
                local steps = length * this.step_accuracy
                this.state_stepper = steps
            end
            
            if touch.state == ENDED then
                if not this.state_stepper then
                    if touch.tapCount > 1 then -- toggle frame selections
                        
                        self.selected_frames = self.__selected_frames -- restore backup on 'second-tap' (see else statement)
                        
                        if not self:isSelected(self.selected_frames, frame_id) then
                            self:selectFrame(frame_id)
                        else
                            if #self.frames > 0 and #self.selected_frames > 1 then
                                self:deselectFrame(frame_id)
                            end
                        end
                        
                    else -- choose certain frame
                        
                        self.__selected_frames = self.selected_frames -- create backup because this 'single-tap' fires before the 'double-tap' event
                        self.selected_frames = {}
                        self:selectFrame(frame_id)
                        
                    end
                end
                this.state_stepper = nil
                this.is_active = false
            end
        end
        
        -- handle frame creation
        
        if hierarchy_pos_id then -- insert manually into hierarchy
            table.insert(self.frames, hierarchy_pos_id, slider)
            self.selected_frames = {hierarchy_pos_id} -- reset
            return
        end
        
        if #self.selected_frames == 1 then -- insert after currently selected frame
            local id = self.selected_frames[1] + 1
            table.insert(self.frames, id, slider)
            self.selected_frames = {id} -- reset
            return
        end
        
        table.insert(self.frames, slider) -- insert at the end of the list
        self.selected_frames = {#self.frames} -- reset
    end
    
    
    function MeshRig:findFrame(x, y) -- find frame hierarchy id by coordinates
        for i, frm in ipairs(self.frames) do
            local ds_width = WIDTH * self.ds_width
            local ds_height = HEIGHT
            local ds_btn_height = frm.height
            local origin_y = HEIGHT - ds_btn_height + self.ds_scroll -- top left screen (and bottom left corner of the button)
            local btn_y = origin_y - ds_btn_height*i - 2*i
            
            if x < ds_width and y > btn_y and y < btn_y + ds_btn_height then
                return i
            end
        end
    end
    
    
    function MeshRig:isSelected(object, id) -- check if vertex or frame is selected
        if object and id then
            for i, frm in ipairs(object) do -- self.selected_frames or self.selected_vertices
                if id == frm then
                    return i
                end
            end
        end
        return false
    end
    
    
    function MeshRig:selectFrame(id)
        if id and self.frames[id] and not self:isSelected(self.selected_frames, id) then
            table.insert(self.selected_frames, id)
            sortTable(self.selected_frames, "asc")
        end
    end
    
    
    function MeshRig:deselectFrame(id)
        local selection_id = self:isSelected(self.selected_frames, id)
        
        if selection_id then -- frame is selected?
            table.remove(self.selected_frames, selection_id)
            sortTable(self.selected_frames, "asc")
        end
    end
    
    
    function MeshRig:moveFrames(new_hierarchy_pos_id, whitelist) -- change hierarchy of frames
        
    end
    
    
    function MeshRig:removeFrames(blacklist) -- remove blacklisted or selected frames
        if #self.frames > 0 then
            
            if blacklist then -- remove by custom given list (which will be a rather rare case)
                sortTable(blacklist, "desc") -- could be unordered so sort it first
                
                for _, id in ipairs(blacklist) do
                    self:deselectFrame(id)
                    table.remove(self.frames, id)
                end
                
                if #self.frames > 0 and #self.selected_frames == 0 then -- cleared all selections but still have some frames in the stack?
                    self:selectFrame(#self.frames) -- select the most recent
                end
                
                return
            end
            
            -- remove by current selection
            
            local smalest_remainder = math.max(1, math.min(unpack(self.selected_frames)) - 1)
            
            for i = #self.selected_frames, 1, -1 do -- ordered 'asc' by default so let's just loop the other way around
                local id = self.selected_frames[i]
                table.remove(self.frames, id)
            end
            
            if smalest_remainder > 0 and #self.frames > 0 then
                self.selected_frames = {smalest_remainder}
            else
                self.selected_frames = {}
            end
            
        end
    end
    
    
    function MeshRig:draw() -- make this the last call in your draw stack because the editor should overlay everything
        if self.is_running then
            local ds_line_size = 2
            local ds_width = WIDTH * self.ds_width
            local ds_height = HEIGHT
            
            pushMatrix()
            pushStyle()
            resetStyle()
            background(23)
            noSmooth()
            rectMode(CORNER)
            textMode(LEFT)
            textAlign(LEFT)
            font("HelveticaNeue-Light")
            
            -- viewport
            
            translate(WIDTH/2 + self.ds_width, HEIGHT/2)
            scale(128)
            
            do
                local tris = triangulate(self.vertices)
                self.mesh:clear()
                self.mesh.vertex_buffer:set(tris)
                --self.mesh.texture_buffer:set(uvs)
                self.mesh:draw()
                
                if self.image_picker.selected_asset then
                    self.mesh.texture = readImage(self.image_picker.selected_asset)
                end
                
                for v = 1, #tris, 2 do
                    local v1 = tris[v]
                    local v2 = tris[v+1]
                    stroke(255, 255 * self.image_picker.btn_wire.value)
                    strokeWidth(.02)
                    lineCapMode(ROUND)
                    line(v1.x, v1.y, v2.x, v2.y)
                end
            end
            
            -- dopesheet
            
            resetMatrix()
            
            noStroke()
            fill(60, 60, 59)
            rect(0, 0, ds_width, ds_height)
            
            translate(0, HEIGHT + self.ds_scroll - self.btn_remove.height)
            
            do
                local duration_buffer = .5 -- frame.value is always smaller than frame.max by this value; visual indicator that the slider can always grow
                local largest_duration
                
                for i, frm in ipairs(self.frames) do
                    frm:setTitle(i, frm.width * .25)
                    frm.width = ds_width
                    frm.y = -i * frm.height - i * 2
                    
                    largest_duration = math.max(frm.value + duration_buffer, largest_duration or 0)
                    frm.max = self.largest_duration or largest_duration -- dynamically set the frame.max value
                    
                    if self:isSelected(self.selected_frames, i) then -- selected?
                        frm.bg_color = color(112, 111, 111)
                    else
                        frm.bg_color = color(255, 0)
                    end
                    
                    frm:draw()
                end
                
                self.largest_duration = largest_duration -- reset
            end
            
            -- action buttons
            popMatrix()
            
            self.btn_remove.width = ds_width/2
            self.btn_remove.y = HEIGHT - self.btn_remove.height
            
            self.btn_create.width = ds_width/2
            self.btn_create.x = ds_width/2
            self.btn_create.y = HEIGHT - self.btn_create.height
            
            self.btn_skin.width = ds_width/3
            
            self.btn_paste.width = ds_width/3
            self.btn_paste.x = ds_width/3
            
            self.btn_copy.width = ds_width/3
            self.btn_copy.x = ds_width/3*2
            
            self.btn_remove:draw()
            self.btn_create:draw()
            self.btn_skin:draw()
            self.btn_paste:draw()
            self.btn_copy:draw()
            
            self.image_picker:draw()
            self.alert:draw()
            
            popStyle()
            popMatrix()
        end
    end
    
    
    function MeshRig:touched(touch, touch2)
        if self.is_running then
            local ds_width = WIDTH * self.ds_width
            local ds_height = HEIGHT
            local ds_btn_height = self.btn_remove.height -- buttons are all equal anyway
            
            
            if self.alert.is_active then
                self.alert:touched(touch)
                return
            end
            
            if self.image_picker.is_active then
                self.image_picker:touched(touch)
                return
            end
            
            self.btn_remove:touched(touch)
            self.btn_create:touched(touch)
            self.btn_skin:touched(touch)
            self.btn_paste:touched(touch)
            self.btn_copy:touched(touch)
            
            
            do -- dispatch touches to already active or newly touched frame-buttons from the dopesheet
                local frame_id = self:findFrame(touch.initX, touch.initY)
                
                for i, frm in ipairs(self.frames) do -- TODO crop the list to only visible frames if framerate drops because of this
                    if i == frame_id or frm.is_active then
                        self.frames[i]:touched(touch, i)
                    end
                end
            end
            
        end
    end
end














do -- simple lua file system to access raw file content at places where Codea could not reach
    
    lfs = {}
    
    lfs.ENVIRONMENT = os.getenv("HOME")
    lfs.DOCUMENTS = lfs.ENVIRONMENT.."/Documents"
    lfs.DROPBOX = lfs.DOCUMENTS.."/Dropbox.assets"
    
    package.path = package.path..";"..lfs.DROPBOX.."/?.lua" -- extend search path of require()
    
    lfs.MIME = {
        [".htm"] = "text/html",
        [".html"] = "text/html",
        [".shtml"] = "text/html",
        [".xhtml"] = "text/xhtml+xml",
        [".rss"] = "text/rss+xml",
        [".xml"] = "text/xml",
        [".css"] = "text/html",
        [".txt"] = "text/plain",
        [".text"] = "text/plain",
        [".md"] = "text/markdown",
        [".markdown"] = "text/markdown",
        [".lua"] = "text/x-lua",
        [".luac"] = "application/x-lua-bytecode",
        [".js"] = "application/javascript",
        [".json"] = "application/json",
        [".zip"] = "application/zip",
        [".pdf"] = "application/pdf",
        [".svg"] = "image/svg+xml",
        [".svgz"] = "image/svg+xml",
        [".ico"] = "image/x-icon",
        [".jpeg"] = "image/jpeg",
        [".jpg"] = "image/jpeg",
        [".gif"] = "image/gif",
        [".png"] = "image/png",
        [".tif"] = "image/tiff",
        [".tiff"] = "image/tiff"
    }
    
    
    function lfs.breadcrumbs(path)
        return path:match("(.+)/(.+)(%.[^.]+)$")
    end
    
    
    function lfs.read(file)
        local DIR, FILE, EXT = lfs.breadcrumbs(file)
        local data = io.open(string.format("%s/%s", DIR, FILE..EXT), "r")
        
        if data then
            local content = data:read("*all")
            data:close()
            return content, lfs.MIME[EXT]
        end
        
        return false
    end
    
    
    function lfs.write(file, content)
        local DIR, FILE, EXT = lfs.breadcrumbs(file)
        local data = io.open(string.format("%s/%s", DIR, FILE..EXT), "w")
        
        if data then
            wFd:write(td)
            wFd:close()
            return true
        end
        
        return false
    end
    
    
    function lfs.read_binary(file)
        local DIR, FILE, EXT = lfs.breadcrumbs(file)
        local data = io.open(string.format("%s/%s", DIR, FILE..EXT), "rb")
        
        if data then
            local chunks = 256
            local content = ""
            
            while true do
                local bytes = data:read(chunks) -- read only n bytes per iteration
                if not bytes then break end
                content = content..bytes
            end
            
            data:close()
            
            return content, lfs.MIME[EXT]
        end
        
        return false
    end
    
    
    function lfs.write_binary(file, content)
        local DIR, FILE, EXT = lfs.breadcrumbs(file)
        local data = io.open(string.format("%s/%s", DIR, FILE..EXT), "wb")
        
        if data then
            data:write(content) -- you could do it in parts, but oh
            data:close()
            return true
        end
        
        return false
    end
    
end













-- Spine-Codea
-- Supports spine-lua runtime 3.5.03
--
-- NOTE: Download the runtime from https://github.com/EsotericSoftware/spine-runtimes/tree/master/spine-lua
-- Drop that folder into your Dropbox inside Codea's root folder
-- Make sure "Lfs" class is included in your project
--
-- USE: actor_name = spine.Actor(lfs.DROPBOX.."/sub-dir", "skeleton.json", "skeleton.atlas")

do
    
    local QUAD_TRIANGLES = {1, 2, 3, 3, 4, 1}
    
    spine = {}
    
    spine.Actor = class()
    spine.utils = require "spine-lua.utils"
    spine.SkeletonJson = require "spine-lua.SkeletonJson"
    spine.SkeletonData = require "spine-lua.SkeletonData"
    spine.BoneData = require "spine-lua.BoneData"
    spine.SlotData = require "spine-lua.SlotData"
    spine.IkConstraintData = require "spine-lua.IkConstraintData"
    spine.Skin = require "spine-lua.Skin"
    spine.Attachment = require "spine-lua.attachments.Attachment"
    spine.BoundingBoxAttachment = require "spine-lua.attachments.BoundingBoxAttachment"
    spine.RegionAttachment = require "spine-lua.attachments.RegionAttachment"
    spine.MeshAttachment = require "spine-lua.attachments.MeshAttachment"
    spine.VertexAttachment = require "spine-lua.attachments.VertexAttachment"
    spine.PathAttachment = require "spine-lua.attachments.PathAttachment"
    spine.Skeleton = require "spine-lua.Skeleton"
    spine.Bone = require "spine-lua.Bone"
    spine.Slot = require "spine-lua.Slot"
    spine.IkConstraint = require "spine-lua.IkConstraint"
    spine.AttachmentType = require "spine-lua.attachments.AttachmentType"
    spine.AttachmentLoader = require "spine-lua.AttachmentLoader"
    spine.Animation = require "spine-lua.Animation"
    spine.AnimationStateData = require "spine-lua.AnimationStateData"
    spine.AnimationState = require "spine-lua.AnimationState"
    spine.EventData = require "spine-lua.EventData"
    spine.Event = require "spine-lua.Event"
    spine.SkeletonBounds = require "spine-lua.SkeletonBounds"
    spine.BlendMode = require "spine-lua.BlendMode"
    spine.TextureAtlas = require "spine-lua.TextureAtlas"
    spine.TextureRegion = require "spine-lua.TextureRegion"
    spine.TextureAtlasRegion = require "spine-lua.TextureAtlasRegion"
    spine.AtlasAttachmentLoader = require "spine-lua.AtlasAttachmentLoader"
    spine.Color = require "spine-lua.Color"
    
    
    spine.utils.readJSON = json.decode
    
    function spine.utils.readFile(file_name, base_path)
        local src = lfs.read(base_path and base_path.."/"..file_name or file_name)
        return src
    end
    
    function spine.utils.readImage(file_name, base_path)
        return image(spine.utils.readFile(file_name, base_path))
    end
    
    function spine.utils.print(t, indent)
        if not indent then indent = "" end
        local names = {}
        for n, g in pairs(t) do
            table.insert(names, n)
        end
        table.sort(names)
        for i, n in pairs(names) do
            local v = t[n]
            if type(v) == "table" then
                if v == t then -- prevent endless loop on self reference
                    print(indent..tostring(n)..": <-")
                else
                    print(indent..tostring(n)..":")
                    spine.utils.print(v, indent.."   ")
                end
            elseif type(v) == "function" then
                print(indent..tostring(n).."()")
            else
                print(indent..tostring(n)..": "..tostring(v))
            end
        end
    end
    
    
    function spine.Actor:init(base_path, json_file, atlas_file, default_skin, scale_factor)
        base_path = base_path or lfs.DROPBOX
        local image_loader = function(file) return spine.utils.readImage(file, base_path) end
        local atlas_data = spine.TextureAtlas.new(spine.utils.readFile(atlas_file, base_path), image_loader)
        json_data = spine.SkeletonJson.new(spine.AtlasAttachmentLoader.new(atlas_data))
        json_data.scale = scale_factor or 1
        local skeleton_data = json_data:readSkeletonDataFile(json_file, base_path)
        local animation_data = spine.AnimationStateData.new(skeleton_data)
        
        self.skeleton = spine.Skeleton.new(skeleton_data)
        self.skeleton:setSkin(default_skin or "default")
        self.skeleton:setToSetupPose()
        self.animation = spine.AnimationState.new(animation_data)
        self.mesh = mesh()
        self.mesh:resize(1500) -- NOTE: if Codea crashes try increase the buffer size!
        self.mesh.vertex_buffer = self.mesh:buffer("position")
        self.mesh.texture_buffer = self.mesh:buffer("texCoord")
        self.mesh.color_buffer = self.mesh:buffer("color")
    end
    
    function spine.Actor:setPosition(new_x, new_y)
        self.skeleton.x = new_x
        self.skeleton.y = new_y
    end
    
    function spine.Actor:setScale(new_scale_x, new_scale_y)
        self.skeleton.scaleX = new_scale_x
        self.skeleton.scaleY = new_scale_y or new_scale_x
    end
    
    function spine.Actor:setSkin(new_skin_name)
        self.skeleton.skin = nil -- reset skin!
        self.skeleton:setSkin(new_skin_name)
    end
    
    function spine.Actor:setAnimation(new_animation_name, loop, crossfade_time)
        local track_entry = self.animation:setAnimationByName(0, new_animation_name, loop)
        track_entry.mixDuration = crossfade_time or .1
    end
    
    function spine.Actor:queueAnimation(animation_name, loop, delay)
        self.animation:addAnimationByName(0, animation_name, loop, delay or 0)
    end
    
    function spine.Actor:draw()
        pushMatrix()
        scale(self.skeleton.scaleX or 1, self.skeleton.scaleY or 1)
        
        self.animation:update(DeltaTime)
        self.animation:apply(self.skeleton)
        self.skeleton:updateWorldTransform()
        
        for i, slot in ipairs(self.skeleton.drawOrder) do
            local attachment = slot.attachment
            
            if attachment then
                local texture, vertices, triangles
                
                if attachment.type == spine.AttachmentType.region then
                    texture = attachment.region.renderObject.texture
                    vertices = attachment:updateWorldVertices(slot, true)
                    triangles = QUAD_TRIANGLES
                elseif attachment.type == spine.AttachmentType.mesh then
                    texture = attachment.region.renderObject.texture
                    vertices = attachment:updateWorldVertices(slot, true)
                    triangles = attachment.triangles
                end
                
                if texture and vertices and triangles then
                    pushStyle()
                    
                    local faces = {}
                    local uvs = {}
                    local colors = {}
                    local blend_mode = slot.data.blendMode
                    
                    if blend_mode == spine.BlendMode.additive then blendMode(ADDITIVE)
                    elseif blend_mode == spine.BlendMode.multiply then blendMode(MULTIPLY)
                    elseif blend_mode == spine.BlendMode.screen then blendMode(ONE, ONE_MINUS_SRC_COLOR)
                    else blendMode(NORMAL) end -- blend_mode == spine.BlendMode.normal and undefined
                    
                    -- triangulate and supply to GPU
                    for j, id in ipairs(triangles) do -- listed in cw order
                        local pos = id * 8 - 8
                        local vert = vec2(vertices[pos + 1], vertices[pos + 2])
                        local uv = vec2(vertices[pos + 3], 1 - vertices[pos + 4]) -- flip y
                        local r = vertices[pos + 5] * 255
                        local g = vertices[pos + 6] * 255
                        local b = vertices[pos + 7] * 255
                        local a = vertices[pos + 8] * 255
                        table.insert(faces, vert)
                        table.insert(uvs, uv)
                        table.insert(colors, color(r, g, b, a))
                    end
                    
                    self.mesh:clear()
                    self.mesh.texture = texture
                    self.mesh.vertex_buffer:set(faces)
                    self.mesh.texture_buffer:set(uvs)
                    self.mesh.color_buffer:set(colors)
                    self.mesh:draw()
                    
                    popStyle()
                end
            end
        end
        
        popMatrix()
    end 
end














-- Twitter Codea Client
-- Dependencies: https://github.com/somesocks/lua-lockbox

do 
    -- Each application musst have an identifier
    -- generate yours at https://apps.twitter.com
    local app_consumer_key = "1Intbn8hwxkuCbd9SM8kHSmfU"
    local app_consumer_secret = "OsqxSIfBdYDcMYxxz7UXZTsve8cOYLRwFUlKKF6Lw9EG3Kx0Xh"
    
    -- An access_token can be used to make api requests on behalf of a user account
    -- by default ANY user is allowed to connect to this application
    local account_access_token = readLocalData("account_access_token", "")
    local account_access_token_secret = readLocalData("account_access_token_secret", "")
    
    
    local array_encode = require("lockbox.util.array").fromString
    local stream_encode = require("lockbox.util.stream").fromString
    local base_64_encode = require("lockbox.util.base64").fromArray
    local hmac = require "lockbox.mac.hmac"
    local sha1 = require "lockbox.digest.sha1"
    

    local function build_authorization_header(method, url, parameters)
        parameters = parameters or {}
        parameters.oauth_version = "1.0"
        parameters.oauth_nonce = generateRandomString(32)
        parameters.oauth_timestamp = os.time() + 1
        parameters.oauth_consumer_key = app_consumer_key
        parameters.oauth_token = account_access_token
        parameters.oauth_signature_method = "HMAC-SHA1"
        
        local list = {}
        local order = {}
        local key = rfc3986Encode(app_consumer_secret).."&"..rfc3986Encode(account_access_token_secret)
        local signature = ""
        local prefix = "oauth_"
        local header = "OAuth"
        
        -- Build "oauth_signature"
        for key, value in pairs(parameters) do
            local k = rfc3986Encode(key)
            list[k] = rfc3986Encode(tostring(value))
            table.insert(order, k)
        end
        
        table.sort(order)
        
        for pos, key in ipairs(order) do
            local value = list[key]
            signature = signature.."&"..key.."="..value
        end
        
        signature = method:upper().."&"..rfc3986Encode(url).."&"..rfc3986Encode(signature:sub(2))
        
        -- Sign/Encode "oauth_signature" with key
        parameters.oauth_signature = base_64_encode(
            hmac()
            .setBlockSize(64)
            .setDigest(sha1)
            .setKey(array_encode(key))
            .init()
            .update(stream_encode(signature))
            .finish()
            .asBytes()
        )
        
        -- Build complete "Authorization" header string
        for key, value in pairs(parameters) do
            if key:find(prefix) then
                header = header..' '..rfc3986Encode(key)..'="'..rfc3986Encode(tostring(value))..'",'
            end
        end
        
        return header:sub(1, -2), parameters
    end
    
    
    local function build_query_url(url, parameters)
        local prefix = "oauth_"
        local request = url.."?"
        parameters = parameters or {}
        
        for key, value in pairs(parameters) do
            if not key:find(prefix) then
                request = request..key.."="..tostring(value).."&"
            end
        end
        
        return request:sub(1, -2)
    end
    
    
    -- This is used for debugging purposes - comment out to disable outputs
    local function request_report(data, status, headers)
        ---[[
        if not status and not headers then print(data) return false end
        print("status:", status)
        print("headers:")
        printf(headers)
        print(data)
        return true
        --]]
    end
    
    
    -- Use this method to perform twitter api requests
    local function request_api(method, url, parameters, callback_success, callback_failure)
        http.request(build_query_url(url, parameters), callback_success or request_report, callback_failure or request_report, {
            method = method:upper(),
            headers = {
                Authorization = build_authorization_header(method, url, parameters),
                ["Content-Type"] = "application/x-www-form-urlencoded"
            }
        })
    end
    
    
    -- Use this method to obtain authorization for requests on behalf of an user
    -- This will override previous user!
    -- You should customize this method to your needs. Notice that you have to provide a PIN input field inside your app interface.
    local function request_access(callback_success, callback_failure)
        local function parse_response(raw_string)
            local parameters = {}
            local charset = "[^%&=]*"
            raw_string:gsub("("..charset..")=("..charset..")", function(key, value) parameters[key] = value end)
            return parameters
        end
        
        -- Pin-Based Authorization
        saveLocalData("account_access_token", nil) -- reset privious handshake
        saveLocalData("account_access_token_secret", nil)
        
        request_api("POST", "https://api.twitter.com/oauth/request_token", {oauth_callback = "oob", x_auth_access_type = "read-write-directmessages"}, function(response, status, headers)
            local parameters = parse_response(response)
            if status == 200 and parameters.oauth_callback_confirmed then
                openURL("https://api.twitter.com/oauth/authorize?oauth_token="..parameters.oauth_token, true)
                parameter.text("twitter_pin_code")
                parameter.action("twitter_connect", function()
                    account_access_token = parameters.oauth_token
                    account_access_token_secret = parameters.oauth_token_secret
                    request_api("POST", "https://api.twitter.com/oauth/access_token", {oauth_verifier = twitter_pin_code}, function(response, status, headers)
                        parameters = parse_response(response)
                        if status == 200 then
                            -- Complete handshake and save "oauth_token" and "oauth_token_secret"
                            saveLocalData("account_access_token", parameters.oauth_token)
                            saveLocalData("account_access_token_secret", parameters.oauth_token_secret)
                            parameter.clear()
                            if callback_success then callback_success() else request_report(response, status, headers) end
                        else
                            if callback_failure then callback_failure() else request_report(response) end
                        end
                    end)
                end)
            else
                if callback_failure then callback_failure() else request_report(response) end
            end
        end)
    end
    
    
    -- Use this method to check your authorization
    -- This will automatically invoke request_access() when nessecary!
    local function check_access(callback_success)
        local callback_failure = function() request_access(callback_success) end
        request_api("GET", "https://api.twitter.com/1.1/account/verify_credentials.json", nil, callback_success or request_report, callback_failure)
    end
    
    
    -- Define global function accessors
    
    twitter = {}
    twitter.check = check_access
    twitter.authenticate = request_access
    twitter.request = request_api
end

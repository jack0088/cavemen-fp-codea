World = {}
World.ui = {}
World.sfx = {}
World.brush = {}
World.atlas = {}
World.layer = {}
World.camera = {}
World.debug = false

function World:init(properties)
    self.texture = readImage("Dropbox:cavemen_spritesheet")
    
    self.tileWidth = 8
    self.tileHeight = 8
    self.chunkWidth = 8
    self.chunkHeight = 8
    
    self.brush.x = 0
    self.brush.y = 0
    
    self.atlas.x = 0
    self.atlas.y = 0
    self.atlas.scaleX = 6
    self.atlas.scaleY = 6
    
    self.layer.y = 0
    self.layer.list = {1,2,5,999}
    self.layer.property = properties or {}
    
    self.camera.x = 0
    self.camera.y = 0
    self.camera.scaleX = 8
    self.camera.scaleY = 8
    
    self.map = {{x = -1, y = 0}, {x = -2, y = -2}}
    
    self.ui.checkboxSize = 24
    self.ui.checkboxMargin = 4
    self.ui.layerWindowWidth = self.ui.checkboxSize + 2*self.ui.checkboxMargin + textSize(self.layer.list[#self.layer.list])
    self.ui.titleBarHeight = 32
    self.ui.atlasWindowHeight = math.min(self.atlas.scaleY * self.texture.height + self.ui.titleBarHeight, HEIGHT/4)
    
    self.sfx.action = {SOUND_RANDOM, 6653}
    self.sfx.selection = {DATA, "ZgBAQABlQEBAP0BAAAAAAHuYhT4qLhk/fwBAf0BAQEBAQEA+"}
    
    self.gestureTimer = .33
end

function World:finish()
end

function World.camera:center()
    if World.debug then
        self.pivotX = (WIDTH  - World.ui.layerWindowWidth) / WIDTH/2
        self.pivotY = (HEIGHT - World.ui.atlasWindowHeight - World.ui.titleBarHeight) / HEIGHT/2 + World.ui.atlasWindowHeight / HEIGHT
    else
        self.pivotX = .5
        self.pivotY = .5
    end
end

function World.camera:getWorldPosition(x, y)
    return
        (x + self.x - self.pivotX * WIDTH) / self.scaleX,
        (y + self.y - self.pivotY * HEIGHT) / self.scaleY
end

function World.camera:getScreenPosition(x, y)
    local pntX = self.scaleX * x - self.x + self.pivotX * WIDTH
    local pntY = self.scaleY * y - self.y + self.pivotY * HEIGHT
    return
        pntX,
        pntY,
        pntX > 0 and pntX < WIDTH and pntY > 0 and pntY < HEIGHT
end

function World.camera:getTile(x, y)
    -- pass in world position (e.g. player)
    -- from this we can get the chunk position
    -- then calculate which tile it is in this chunk
    -- finally return tile index
end

function World.camera:setTile(x, y, id)
    -- pass in world position (e.g. player)
    -- from this we can get the chunk
    -- then calculate the corresponding tile
    -- and finally change its index to the new id
end

function World.layer:create(flag)
    table.insert(self.list, {name = flag, hidden = false})
    table.sort(self.list, function(obj, list) return obj.name < list.name end)
end

function World.layer:delete(flag)
    table.remove(self.list, self:getId(flag))
end

function World.layer:getId(flag)
    local index
    for id, layer in ipairs(self.list) do
        if layer.name == flag then
            index = id
            break
        end
    end
    return index
end

function World:unload(chunks)
    for _, chunk in ipairs(chunks) do
        for id, list in ipairs(self.map) do
            -- Chunk:Chunk comparison
            if list.width == chunk.width and list.height == chunk.height then
                if list.x == chunk.x and list.y == chunk.y then
                    table.remove(self.map, id)
                end
            else
            -- Chunk:Tile comparison
                -- TODO: list.x, list.y arent in the same world space as chunk.x and chunk.y
                if list.x > chunk.x and list.x < chunk.x + chunk.width
                and list.y > chunk.y and list.y < chunk.y + chunk.height
                then
                    if list.finish then list:finish() end
                    table.remove(self.map, id)
                end
            end
        end
    end
end

function World:load(chunks)
    for _, chunk in ipairs(chunks) do
        for _, layer in ipairs(self.layer.list) do
            local layerRegion = {layer = layer, chunk = chunk, tile = {}}
            
            for y = 1, self.chunkHeight do
                for x = 1, self.chunkWidth do
                    local tileX = self.chunkWidth * chunk.x + x - 1
                    local tileY = self.chunkHeight * chunk.y + y - 1
                    local tileId = readProjectData(tileX.." "..tileY.." "..layer)
                    
                    if tileId then
                        tileId = vec2(tileId:match("(%S+)%s(%S)"))
                        table.insert(layerRegion.tile, {x = tileX, y = tileY, relativeX = x, relativeY = y, id = tileId})
                    end
                end
            end
            
            if #layerRegion.tile > 0 then
                self:setup(layerRegion)
            end
        end
    end
end

function World:render(region)
    local canvas = image(region.chunk.width, region.chunk.height)
    local mask = mesh()
    mask.texture = self.texture
    mask:addRect(self.tileWidth/2, self.tileHeight/2, self.tileWidth, self.tileHeight)
    
    setContext(canvas)
    pushMatrix()
    resetMatrix()
    translate(-(self.tileWidth * self.chunkWidth * region.chunk.x), -(self.tileHeight * self.chunkHeight * region.chunk.y))
    
    for _, tile in ipairs(region.tile) do
        --sprite + clip or just mesh?
    end
    
    setContext()
    popMatrix()
    return canvas
end

function World:setup(region)
    if self.layer.property[region.layer] then
        for _, tile in ipairs(region.tile) do
            -- setup as separate object
        end
    else
        local object = mesh()
        object.x = self.tileWidth * self.chunkWidth * region.chunk.x
        object.x = self.tileHeight * self.chunkHeight * region.chunk.y
        object.width = region.chunk.width
        object.height = region.chunk.height
        object.texture = self:render(region)
        object:addRect(object.width/2, object.height/2, object.width, object.height)
        table.insert(self.map, object)
    end
end

function World:save()
end

function World:orientationChanged(screen)
    self.camera:center()
end

function World:update()
    -- Update touch flags
    if self._useMapWindow
    and self._useMapWindow + self.gestureTimer < ElapsedTime
    and not self._brushMapWindow
    then
        self._scrollMapWindow = true
    end
    
    if self._useAtlasWindow
    and self._useAtlasWindow + self.gestureTimer < ElapsedTime
    and not self._scrollAtlasWindow
    then
        self._resizeBrush = true
    end
    
    -- Track visible chunks
    local chunkWidth, chunkHeight = self.tileWidth * self.chunkWidth, self.tileHeight * self.chunkHeight
    local leftBottomX, leftBottomY = self.camera:getWorldPosition(0, 0)
    local leftBottomChunk = vec2(math.floor(leftBottomX / chunkWidth), math.floor(leftBottomY / chunkHeight))
    
    if (not self._referenceChunk
    or self._referenceChunk ~= leftBottomChunk)
    and not self._scrollMapWindow
    then
        -- TODO: maybe we have to offset some sides by chunkWidth or chunkHeight
        -- Collect positions for old and new chunks
        local cameraDirection = leftBottomChunk - (self._referenceChunk or leftBottomChunk)
        local rightTopX, rightTopY = self.camera:getWorldPosition(WIDTH, HEIGHT)
        local rightTopChunk = vec2(math.floor(rightTopX / chunkWidth), math.floor(rightTopY / chunkHeight))
        local whitelist = {}
        local blacklist = {}
        
        -- Init map
        if not self._referenceChunk then
            for x = leftBottomChunk.x, rightTopChunk.x do
                for y = leftBottomChunk.y, rightTopChunk.y do
                    table.insert(whitelist, {x = x, y = y, width = chunkWidth, height = chunkHeight})
                end
            end
        else
        -- Continuously update map
            -- Check left screen side
            for x = leftBottomChunk.x - math.abs(cameraDirection.x), leftBottomChunk.x do
                for y = leftBottomChunk.y, rightTopChunk.y do
                    -- camera moved left
                    if cameraDirection.x < 0 then
                        table.insert(whitelist, {x = x, y = y, width = chunkWidth, height = chunkHeight})
                    else
                        -- camera moved right
                        table.insert(blacklist, {x = x, y = y, width = chunkWidth, height = chunkHeight})
                    end
                end
            end
            
            -- Check right screen side
            for x = rightTopChunk.x, rightTopChunk.x + math.abs(cameraDirection.x) do
                for y = leftBottomChunk.y, rightTopChunk.y do
                    -- camera moved right
                    if cameraDirection.x > 0 then
                        table.insert(whitelist, {x = x, y = y, width = chunkWidth, height = chunkHeight})
                    else
                        -- camera moved left
                        table.insert(blacklist, {x = x, y = y, width = chunkWidth, height = chunkHeight})
                    end
                end
            end
            
            -- Check top screen side
            for x = leftBottomChunk.x, rightTopChunk.x do
                for y = rightTopChunk.y, rightTopChunk.y + math.abs(cameraDirection.y) do
                    -- camera moved up
                    if cameraDirection.y > 0 then
                        table.insert(whitelist, {x = x, y = y, width = chunkWidth, height = chunkHeight})
                    else
                        -- camera moved down
                        table.insert(blacklist, {x = x, y = y, width = chunkWidth, height = chunkHeight})
                    end
                end
            end
            
            -- Check bottom screen side
            for x = leftBottomChunk.x, rightTopChunk.x do
                for y = leftBottomChunk.y - math.abs(cameraDirection.y), leftBottomChunk.y do
                    -- camera moved down
                    if cameraDirection.y < 0 then
                        table.insert(whitelist, {x = x, y = y, width = chunkWidth, height = chunkHeight})
                    else
                        -- camera moved up
                        table.insert(blacklist, {x = x, y = y, width = chunkWidth, height = chunkHeight})
                    end
                end
            end
        end
        
        self._referenceChunk = leftBottomChunk
        self:unload(blacklist)
        self:load(whitelist)
        
        --print(#whitelist)
        --printf(whitelist)
    end
    
    -- Coroutine threads
    --
end

function World:draw()
    pushMatrix()
    pushStyle()
    noSmooth()
    
    self:update()
    
    -- Map
    translate(self.camera.pivotX * WIDTH - self.camera.x, self.camera.pivotY * HEIGHT - self.camera.y)
    scale(self.camera.scaleX, self.camera.scaleY)
    
    --draw map here!
    
    -- Developer tools
    if self.debug then
        pushStyle()
        font("Futura-CondensedMedium")
        fontSize(18)
        
        -- Show grid
        do
            local gridOpacity = self._scrollMapWindow and 255 or 64
            local tileWidth = self.camera.scaleX * self.tileWidth
            local tileHeight = self.camera.scaleY * self.tileHeight
            local chunkWidth = tileWidth * self.chunkWidth
            local chunkHeight = tileHeight * self.chunkHeight
            
            local gridScrollX = self.camera.x % tileWidth
            local gridScrollY = self.camera.y % tileHeight
            local chunkScrollX = self.camera.x % chunkWidth
            local chunkScrollY = self.camera.y % chunkHeight
            
            resetMatrix()
            translate((self.camera.pivotX * WIDTH) % tileWidth, (self.camera.pivotY * HEIGHT) % tileHeight)
            
            for x = -tileWidth, WIDTH, tileWidth do
                noFill()
                strokeWidth(2)
                stroke(33, 33, 33, gridOpacity)
                line(x - gridScrollX + 1, -tileHeight, x - gridScrollX + 1, HEIGHT)
                strokeWidth(1)
                stroke(96, 88, 79, gridOpacity)
                line(x - gridScrollX, -tileHeight, x - gridScrollX, HEIGHT)
            end
            
            for y = -tileHeight, HEIGHT, tileHeight do
                strokeWidth(2)
                stroke(33, 33, 33, gridOpacity)
                line(-tileWidth, y - gridScrollY - 1, WIDTH, y - gridScrollY - 1)
                strokeWidth(1)
                stroke(96, 88, 79, gridOpacity)
                line(-tileWidth, y - gridScrollY, WIDTH, y - gridScrollY)
            end
            
            resetMatrix()
            translate((self.camera.pivotX * WIDTH) % chunkWidth, (self.camera.pivotY * HEIGHT) % chunkHeight)
            
            -- Display chunks
            for x = 0, WIDTH, chunkWidth do
                for y = 0, HEIGHT, chunkHeight do
                    noStroke()
                    fill(33, 33, 33, gridOpacity)
                    ellipse(x - chunkScrollX, y - chunkScrollY, 20)
                    noFill()
                    strokeWidth(2)
                    stroke(250, 162, 27, gridOpacity)
                    ellipse(x - chunkScrollX, y - chunkScrollY, 15)
                end
            end
        end
        
        -- Show layers
        resetMatrix()
        translate(WIDTH - self.ui.layerWindowWidth, 0)
        
        noStroke()
        fill(33)
        rectMode(CORNER)
        rect(0, 0, self.ui.layerWindowWidth, HEIGHT)
        
        translate(self.ui.checkboxMargin, HEIGHT - self.ui.titleBarHeight - self.ui.checkboxSize - self.ui.checkboxMargin + self.layer.y)
        
        for id, layer in ipairs(self.layer.list) do
            local y = -(id * (self.ui.checkboxSize + self.ui.checkboxMargin) - self.ui.checkboxSize - self.ui.checkboxMargin)
            
            fill(255)
            ellipseMode(CORNER)
            ellipse(0, y, self.ui.checkboxSize)
            
            textMode(CORNER)
            textAlign(LEFT)
            text(string.format("%i", layer), self.ui.checkboxSize + self.ui.checkboxMargin, y)
        end
        
        -- Sprite picker
        resetMatrix()
        clip(0, 0, WIDTH, self.ui.atlasWindowHeight)
            fill(20)
            rect(0, 0, WIDTH, HEIGHT)
            
            pushMatrix()
            translate(self.atlas.x, self.atlas.y + self.ui.atlasWindowHeight - self.ui.titleBarHeight)
            scale(self.atlas.scaleX, self.atlas.scaleY)
            translate(0, -self.texture.height)
            spriteMode(CORNER)
            sprite(self.texture)
            popMatrix()
            
            fill(236, 26, 79, 255)
            rect(0, self.ui.atlasWindowHeight - self.ui.titleBarHeight, WIDTH, self.ui.titleBarHeight)
        clip()
        
        -- Show additional map info
        resetMatrix()
        if self._scrollMapWindow then
            fill(250, 162, 27, 255)
            rect(0, HEIGHT - self.ui.titleBarHeight, WIDTH, self.ui.titleBarHeight)
            
            fill(20)
            textMode(CENTER)
            textAlign(CENTER)
            text(string.format("x: %.0f  y: %.0f", self.camera.x / (self.camera.scaleX * self.tileWidth), self.camera.y / (self.camera.scaleY * self.tileHeight)), WIDTH/2, HEIGHT - self.ui.titleBarHeight/2)
        else
            fill(236, 26, 79, 255)
            rect(0, HEIGHT - self.ui.titleBarHeight, WIDTH, self.ui.titleBarHeight)
        end
        
        popStyle()
    end
    
    popStyle()
    popMatrix()
end

function World:touched(touch)
    -- Developer tools
    if self.debug then
        -- Register where touches begin and save identifier flags
        if touch.state == BEGAN then
            -- Touch inside world map window
            if touch.x > 0 and touch.x < WIDTH - self.ui.layerWindowWidth
            and touch.y > self.ui.atlasWindowHeight and touch.y < HEIGHT - self.ui.titleBarHeight
            then
                self._useMapWindow = touch.initTime
            end
            
            -- Touch inside atlas window title bar
            if touch.y < self.ui.atlasWindowHeight and touch.y > self.ui.atlasWindowHeight - self.ui.titleBarHeight then
                self._resizeAtlasWindow = true
            end
            
            -- Touch inside atlas window
            if touch.y < self.ui.atlasWindowHeight - self.ui.titleBarHeight and touch.y > 0 then
                self._useAtlasWindow = touch.initTime
            end
            
            -- Touch inside layers window
            if touch.x > WIDTH - self.ui.layerWindowWidth and touch.x < WIDTH
            and touch.y > self.ui.atlasWindowHeight and touch.y < HEIGHT - self.ui.titleBarHeight
            then
                self._useLayerWindow = true
            end
        end
        
        -- Track registered touches
        if touch.state == MOVING then
            -- Resize spritesheet window
            if self._resizeAtlasWindow then
                if touch.deltaY < 0
                or (touch.deltaY > 0 and self.ui.atlasWindowHeight - self.ui.titleBarHeight + touch.deltaY < self.atlas.scaleY * self.texture.height)
                then
                    if self.ui.atlasWindowHeight + touch.deltaY < HEIGHT - self.ui.titleBarHeight
                    and self.ui.atlasWindowHeight + touch.deltaY > self.ui.titleBarHeight
                    then
                        self.ui.atlasWindowHeight = self.ui.atlasWindowHeight + touch.deltaY
                        -- TODO: adjust brush position
                    end
                    
                    if (touch.deltaY < 0 and self.atlas.y > self.ui.atlasWindowHeight - self.ui.titleBarHeight)
                    or (touch.deltaY > 0 and self.atlas.y < self.ui.atlasWindowHeight - self.ui.titleBarHeight)
                    then
                        --self.atlas.y = self.atlas.y + touch.deltaY
                        -- TODO: adjust brush position (y)
                    end
                end
                
                self.camera:center()
            end
            
            -- Scroll layers window
            if self._useLayerWindow then
                local windowHeight = HEIGHT - self.ui.atlasWindowHeight - self.ui.titleBarHeight
                local layerHeight = #self.layer.list * (self.ui.checkboxSize + self.ui.checkboxMargin) + self.ui.checkboxMargin
                local y = self.layer.y + touch.deltaY
                self._scrollLayerWindow = true
                
                if y > 0
                and layerHeight - y > windowHeight
                then
                    self.layer.y = y
                end
            end
            
            -- Sub-actions on map window
            if self._useMapWindow then
                -- Scroll world (reverse move camera)
                if self._scrollMapWindow then
                    self.camera.x = self.camera.x - touch.deltaX
                    self.camera.y = self.camera.y - touch.deltaY
                else
                -- Draw map
                    self._brushMapWindow = true
                    print("draaawww tileee...")
                end
            end
        end
        
        if touch.state == ENDED then
            -- Callbacks for actions inside map window
            if self._useMapWindow then
                -- Finished drawing onto map
                if self._brushMapWindow
                or touch.duration < self.gestureTimer
                then
                    -- Just tapped onto map
                    if not self._brushMapWindow then
                        print("adjusted tile")
                    else
                    -- Continuously painted over map
                        print("adjusted multiple tiles")
                    end
                    
                    sound(unpack(self.sfx.action))
                else
                -- Finisched scrolling world map camera
                    print("map moved")
                end
            end
        end
    end
    
    -- Clear all identifier flags
    if touch.state == ENDED then
        -- BEGAN states
        self._resizeAtlasWindow = nil
        self._useAtlasWindow = nil
        self._useLayerWindow = nil
        self._useMapWindow = nil
        self._brushMapWindow = nil
        -- MOVING states
        self._scrollAtlasWindow = nil
        self._scrollLayerWindow = nil
        -- ENDED states
        --
        -- update() flags
        self._scrollMapWindow = nil
        self._resizeBrush = nil
    end
end

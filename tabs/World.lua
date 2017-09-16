

world = {}

world.debug = false

world.level_file_path = nil

world.camera_x = 0
world.camera_y = 0
world.camera_zoom_x = 8
world.camera_zoom_y = 8
world.camera_pivot_x = .5
world.camera_pivot_y = .5

world.atlas_texture = readImage("Dropbox:cavemen_spritesheet")
world.atlas_x = 0
world.atlas_y = 0
world.atlas_zoom_x = 6
world.atlas_zoom_y = 6
world.atlas_window_height = .25 -- as percentage multiplier

world.tile_width = 8
world.tile_height = 8
world.chunk_width = 8 -- in tiles
world.chunk_height = 8

world.brush_x = 0 -- in tiles
world.brush_y = 0
world.brush_width = 1 -- in tiles
world.brush_height = 1

world.map = {}

world.layer_list = {}
world.layer_scroll = 0
world.layer_window_width = .1 -- as percentage multiplier

world.title_bar_height = 32

world.sfx_mouse_click = "Dropbox:mouse_pressUp_hard"

















-- Center camera pivot inside available screen space

function world:centerCameraPivot()
    if self.debug then
        local layer_window = WIDTH * self.layer_window_width
        local atlas_window = HEIGHT * self.atlas_window_height
        
        self.camera_pivot_x = (WIDTH - layer_window) / WIDTH*.5
        self.camera_pivot_y = (HEIGHT - self.title_bar_height - atlas_window) / HEIGHT*.5 + atlas_window / HEIGHT
        
        return
    end
    
    self.camera_pivot_x = .5
    self.camera_pivot_y = .5
end












-- Convert screen coordinates to world coordinates

function world:getWorldPosition(screen_x, screen_y)
    return
        (screen_x + self.camera_x - self.camera_pivot_x * WIDTH) / self.camera_zoom_x,
        (screen_y + self.camera_y - self.camera_pivot_y * HEIGHT) / self.camera_zoom_y
end











-- Convert world coordinates to screen coordinates

function world:getScreenPosition(world_x, world_y)
    local pnt_x = self.camera_zoom_x * world_x - self.camera_x + self.camera_pivot_x * WIDTH
    local pnt_y = self.camera_zoom_y * world_y - self.camera_y + self.camera_pivot_y * HEIGHT
    local is_inside = pnt_x > 0 and pnt_x < WIDTH and pnt_y > 0 and pnt_y < HEIGHT
    return
        pntX,
        pntY,
        is_inside
end











-- Calculate by how many tiles and chunks the camera has been moved
 
function world:getCameraOffset()
    local tiles_x = math.floor(self.camera_x / (self.camera_zoom_x * self.tile_width))
    local tiles_y = math.floor(self.camera_y / (self.camera_zoom_y * self.tile_height))
    local chunks_x = tiles_x * self.chunk_width
    local chunks_y = tiles_y * self.chunk_height
    return
        tiles_x,
        tiles_y,
        chunks_x,
        chunks_y
end













function world:getAtlasTileIndex(x, y)
    local window_height = HEIGHT * self.atlas_window_height - self.title_bar_height
    local tile_width = self.tile_width * self.atlas_zoom_x
    local tile_height = self.tile_height * self.atlas_zoom_y
    local tile_id_x = math.floor((x - self.atlas_x) / tile_width)
    local tile_id_y = math.floor((window_height - y + self.atlas_y) / tile_height)
    return
        tile_id_x,
        tile_id_y
end















-- (Re-)render visible tiles into certain chunks

function world:renderChunk(world_x, world_y)
    local canvas = mesh()
    canvas.texture = image(self.chunk_width, self.chunk_height)
    canvas:addRect(self.tileWidth/2, self.tileHeight/2, self.tileWidth, self.tileHeight)
    
    setContext(canvas.texture)
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















-- Draw grid to visualize tiles and chunks inside the map viewport

function world:drawMapGrid()
    local opacity = self:mapIsPanning() and 255 or 64
    
    local tile_width = self.camera_zoom_x * self.tile_width
    local tile_height = self.camera_zoom_y * self.tile_height
    local chunk_width = tile_width * self.chunk_width
    local chunk_height = tile_height * self.chunk_height
    
    local grid_scroll_x = self.camera_x % tile_width
    local grid_scroll_y = self.camera_y % tile_height
    local chunk_scroll_x = self.camera_x % chunk_width
    local chunk_scroll_y = self.camera_y % chunk_height
    
    
    pushMatrix()
    translate((self.camera_pivot_x * WIDTH) % tile_width, (self.camera_pivot_y * HEIGHT) % tile_height)
    
    -- vertical lines
    for x = -tile_width, WIDTH, tile_width do
        noFill()
        strokeWidth(2)
        stroke(33, 33, 33, opacity)
        line(x - grid_scroll_x + 1, -tile_height, x - grid_scroll_x + 1, HEIGHT)
        strokeWidth(1)
        stroke(96, 88, 79, opacity)
        line(x - grid_scroll_x, -tile_height, x - grid_scroll_x, HEIGHT)
    end
    
    -- horizontal lines
    for y = -tile_height, HEIGHT, tile_height do
        strokeWidth(2)
        stroke(33, 33, 33, opacity)
        line(-tile_width, y - grid_scroll_y - 1, WIDTH, y - grid_scroll_y - 1)
        strokeWidth(1)
        stroke(96, 88, 79, opacity)
        line(-tile_width, y - grid_scroll_y, WIDTH, y - grid_scroll_y)
    end
    
    resetMatrix()
    translate((self.camera_pivot_x * WIDTH) % chunk_width, (self.camera_pivot_y * HEIGHT) % chunk_height)
    
    -- display chunks
    for x = 0, WIDTH, chunk_width do
        for y = 0, HEIGHT, chunk_height do
            noStroke()
            fill(33, 33, 33, opacity)
            ellipse(x - chunk_scroll_x, y - chunk_scroll_y, 20)
            noFill()
            strokeWidth(2)
            stroke(250, 162, 27, opacity)
            ellipse(x - chunk_scroll_x, y - chunk_scroll_y, 15)
        end
    end
    
    popMatrix()
end















function world:drawMapWindow()
    pushMatrix()
    
    self:centerCameraPivot()
    self:drawMapGrid()
    
    translate(self.camera_pivot_x * WIDTH, self.camera_pivot_y * HEIGHT)
    translate(-self.camera_x, -self.camera_y)
    scale(self.camera_zoom_x, self.camera_zoom_y)
    
    rect(0,0,8,8)
    
    popMatrix()
end













-- Draw grid to divide sprites on the spritesheet

function world:drawAtlasGrid()
    local opacity = self:atlasIsPanning() and 255 or 64
    local window_height = HEIGHT * self.atlas_window_height
    local tile_width = self.atlas_zoom_x * self.tile_width
    local tile_height = self.atlas_zoom_y * self.tile_height
    local grid_scroll_x = self.atlas_x % tile_width
    local grid_scroll_y = self.atlas_y % tile_height
    
    -- vertical lines
    for x = 0, WIDTH, tile_width do
        noFill()
        strokeWidth(2)
        stroke(33, 33, 33, opacity)
        line(x + grid_scroll_x + 1, 0, x + grid_scroll_x + 1, -window_height)
        strokeWidth(1)
        stroke(96, 88, 79, opacity)
        line(x + grid_scroll_x, 0, x + grid_scroll_x, -window_height)
    end
    
    -- horizontal lines
    for y = math.floor(window_height / tile_height) * -tile_height, 0, tile_height do
        strokeWidth(2)
        stroke(33, 33, 33, opacity)
        line(0, y + grid_scroll_y - 1, WIDTH, y + grid_scroll_y - 1)
        strokeWidth(1)
        stroke(96, 88, 79, opacity)
        line(0, y + grid_scroll_y, WIDTH, y + grid_scroll_y)
    end
end














-- Cache atlas_texture position and check if the atlas viewport is panning

function world:atlasIsPanning()
    if not self.atlas_cache_x
    or not self.atlas_cache_y
    or self.atlas_cache_x ~= self.atlas_x
    or self.atlas_cache_y ~= self.atlas_y
    then
        local function updateCache()
            self.atlas_cache_x = self.atlas_x
            self.atlas_cache_y = self.atlas_y
        end
        
        if not self.atlas_cache_x or not self.atlas_cache_y then
            updateCache()
        else
            -- delay the cache update
            -- without this you couldn't not ask for the status multiple times inside the draw loop
            tween.delay(.1, updateCache)
        end
        
        return true
    end
    
    return false
end














-- Cache camera position and check if the map viewport is panning

function world:mapIsPanning()
    if not self.camera_cache_x
    or not self.camera_cache_y
    or self.camera_cache_x ~= self.camera_x
    or self.camera_cache_y ~= self.camera_y
    then
        local function updateCache()
            self.camera_cache_x = self.camera_x
            self.camera_cache_y = self.camera_y
        end
        
        if not self.camera_cache_x or not self.camera_cache_y then
            updateCache()
        else
            -- delay the cache update
            -- without this you couldn't not ask for the status multiple times inside the draw loop
            tween.delay(.1, updateCache)
        end
        
        return true
    end
    
    return false
end














function world:brushIsResizing()
    if not self.brush_cache_width
    or not self.brush_cache_height
    or self.brush_cache_width ~= self.brush_width
    or self.brush_cache_height ~= self.brush_height
    then
        local function updateCache()
            self.brush_cache_width = self.brush_width
            self.brush_cache_height = self.brush_height
        end
        
        if not self.brush_cache_width or not self.brush_cache_height then
            updateCache()
        else
            -- delay the cache update
            -- without this you couldn't not ask for the status multiple times inside the draw loop
            tween.delay(.1, updateCache)
        end
        
        return true
    end
    
    return false
end
















function world:drawAtlasBrush()
    pushStyle()
    pushMatrix()
    translate(self.atlas_x, self.atlas_y)
    translate(0, HEIGHT * self.atlas_window_height - self.title_bar_height)
    scale(self.atlas_zoom_x, self.atlas_zoom_y)
    translate(self.brush_x * self.tile_width, -self.brush_y * self.tile_height)
    translate(0, -self.brush_height * self.tile_height)
    
    noFill()
    stroke(0)
    strokeWidth(1)
    rect(0, 0, self.tile_width * self.brush_width, self.tile_height * self.brush_height)
    
    stroke(255)
    strokeWidth(.5)
    rect(.5, .5, self.tile_width * self.brush_width - 1, self.tile_height * self.brush_height - 1)
    
    popMatrix()
    popStyle()
end



















function world:drawAtlasWindow()
    self:restrictAtlasWindowHeight()
    local window_height = HEIGHT * self.atlas_window_height
    
    -- background
    pushStyle()
    noStroke()
    fill(20)
    rect(0, 0, WIDTH, window_height)
    
    -- atlas
    if self.atlas_texture then
        pushMatrix()
        translate(self.atlas_x, self.atlas_y)
        translate(0, window_height - self.title_bar_height)
        scale(self.atlas_zoom_x, self.atlas_zoom_y)
        translate(0, -self.atlas_texture.height)
        
        clip(0, 0, WIDTH, window_height - 1)
            fill(0)
            rect(0, 0, self.atlas_texture.width, self.atlas_texture.height)
        
            spriteMode(CORNER)
            sprite(self.atlas_texture)
            
            -- grid
            resetMatrix()
            translate(0, window_height - self.title_bar_height)
            self:drawAtlasGrid()
            
            -- brush
            resetMatrix()
            self:drawAtlasBrush()
        clip()
        popMatrix()
    end
    
    -- title bar
    if self:brushIsResizing() then
        fill(250, 162, 27, 255)
    else
        fill(236, 26, 79, 255)
    end
    
    rect(0, window_height - self.title_bar_height, WIDTH, self.title_bar_height)
    popStyle()
end

















function world:resizeAtlasWindow(touch)
    if touch.state == BEGAN
    and touch.y < HEIGHT * self.atlas_window_height
    and touch.y > HEIGHT * self.atlas_window_height - self.title_bar_height
    then
        self.resize_atlas_window = true
        return true
    end
    
    
    if touch.state == MOVING
    and self.resize_atlas_window
    then
        local y = self.atlas_window_height + touch.deltaY
        local delta_height = y / HEIGHT -- as percentage multiplier
        local height = self.atlas_window_height + delta_height
        local window_height = HEIGHT * height
        
        if touch.deltaY > 0
        and self.atlas_y > 0
        then
            self.atlas_y = math.max(0, self.atlas_y - touch.deltaY) -- reveal top overflow
        end
        
        if window_height >= self.title_bar_height
        and window_height <= HEIGHT - self.title_bar_height
        and window_height <= self.atlas_texture.height * self.atlas_zoom_y + self.title_bar_height - self.atlas_y
        then
            self.atlas_window_height = height
        end
        
        return true
    end
    
    if touch.state == ENDED then
        if touch.tapCount > 1
        and self.resize_atlas_window
        then
            self.atlas_window_height = self.title_bar_height / HEIGHT
        end
        
        self.resize_atlas_window = nil
    end
    
    return false
end


















function world:panAtlasWindow(touch)
    if touch.state == MOVING
    and touch.initY < HEIGHT * self.atlas_window_height
    and touch.y < HEIGHT * self.atlas_window_height
    then
        local window_height = HEIGHT * self.atlas_window_height
        local width = self.atlas_texture.width * self.atlas_zoom_x
        local height = self.atlas_texture.height * self.atlas_zoom_y
        local x = self.atlas_x + touch.deltaX
        local y = self.atlas_y + touch.deltaY
        
        if (width > WIDTH and x < 0 and x + width > WIDTH)
        or (width < WIDTH and x > 0 and x + width < WIDTH)
        then
            self.atlas_x = x
        end
        
        if (height > window_height - self.title_bar_height and y > 0 and y < height + self.title_bar_height - window_height)
        or (height < window_height - self.title_bar_height and y < window_height - self.title_bar_height and y - height > 0)
        then
            self.atlas_y = y
        end
        
        return true
    end
    
    return false
end















function world:moveAtlasBrush(touch)
    if touch.state == ENDED
    -- just tapped?
    and touch.initX == touch.x
    and touch.initY == touch.y
    -- tapped inside the atlas?
    and touch.initX > self.atlas_x
    and touch.initX < self.atlas_x + self.atlas_texture.width * self.atlas_zoom_x
    and touch.x > self.atlas_x
    and touch.x < self.atlas_x + self.atlas_texture.width * self.atlas_zoom_x
    and touch.initY < HEIGHT * self.atlas_window_height - self.title_bar_height
    then
        self.brush_x, self.brush_y = self:getAtlasTileIndex(touch.x, touch.y)
        self:pullBrushIntoAtlasBounds()
        return true
    end
    
    return false
end
















function world:resizeAtlasBrush(touch)
    local tile_width = self.tile_width * self.atlas_zoom_x
    local tile_height = self.tile_height * self.atlas_zoom_y
    
    
    if touch.state == BEGAN then
        local window_height = HEIGHT * self.atlas_window_height - self.title_bar_height
        local brush_x = self.brush_x * tile_width + self.atlas_x
        local brush_y = window_height - self.brush_y * tile_height + self.atlas_y
        local brush_width = self.brush_width * tile_width
        local brush_height = self.brush_height * tile_height
        
        if touch.x > brush_x and touch.x < brush_x + brush_width -- touched inside brush?
        and touch.y > brush_y - brush_height and touch.y < brush_y
        then
            self.resize_atlas_brush = true
            return true
        end
    end
    
    
    if touch.state == MOVING and self.resize_atlas_brush then
        local cols = self.atlas_texture.width / self.tile_width
        local rows = self.atlas_texture.height / self.tile_height
        local w = self.brush_width + touch.deltaX / tile_width
        local h = self.brush_height - touch.deltaY / tile_height
        
        self.brush_width = math.min(math.max(1, w), cols)
        self.brush_height = math.min(math.max(1, h), rows)
        
        return true
    end
    
    
    if touch.state == ENDED then
        self.brush_width = math.floor(self.brush_width)
        self.brush_height = math.floor(self.brush_height)
        self:pullBrushIntoAtlasBounds()
        self.resize_atlas_brush = nil
    end
    
    return false
end














-- Adjust brush position when it goes outside the spritesheet bounds

function world:pullBrushIntoAtlasBounds()
    local cols = self.atlas_texture.width / self.tile_width
    local rows = self.atlas_texture.height / self.tile_height
    local overlap_x = self.brush_x + self.brush_width - cols
    local overlap_y = self.brush_y + self.brush_height - rows
    
    if overlap_x > 0 then self.brush_x = self.brush_x - overlap_x end
    if overlap_y > 0 then self.brush_y = self.brush_y - overlap_y end
end














function world:restrictAtlasWindowHeight()
    local window_height = HEIGHT * self.atlas_window_height
    local atlas_height = self.atlas_texture.height * self.atlas_zoom_y + self.title_bar_height
    
    if window_height > atlas_height then
        self.atlas_window_height = atlas_height / HEIGHT
    end
end















-- Combine every part and draw the world (and editor if needed)

function world:draw()
    noSmooth()
    
    self:drawMapWindow()
    
    if self.debug then
        self:drawAtlasWindow()
    end
end












function world:touched(touch)
    if self.debug then
        
        if not self:resizeAtlasWindow(touch) then
            if not self:resizeAtlasBrush(touch) then
                self:panAtlasWindow(touch)
                self:moveAtlasBrush(touch)
            end
        end
        
        if touch.state == ENDED then
            sound(world.sfx_mouse_click)
        end
        
    end
end


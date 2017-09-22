

world = {}



world.debug = false

world.alert = nil -- message box with dismiss and confirm




world.bg_color = paint.black

world.title_bar_height = 32

world.sfx_mouse_click = "Dropbox:mouse_pressUp_hard"

world.level_file_path = nil




world.tile_width = 8
world.tile_height = 8
world.chunk_width = 8 -- in tiles
world.chunk_height = 8




world.brush_x = 0 -- in tiles
world.brush_y = 0
world.brush_width = 1 -- in tiles
world.brush_height = 1




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








world.layer_stack = {}
world.layer_selected = nil -- in ascending order
world.layer_scroll = 0
world.layer_item_height = world.title_bar_height
world.layer_window_width = .1 -- as percentage multiplier










world.btn_sprite_edit = UIButton("Sprite")
world.btn_sprite_edit.height = world.title_bar_height
world.btn_sprite_edit.text_color = paint.white
world.btn_sprite_edit.bg_color = paint.orange
world.btn_sprite_edit.text_hover_color = paint.white
world.btn_sprite_edit.bg_hover_color = paint.blue


function world.btn_sprite_edit:draw()
    self.y = HEIGHT * world.atlas_window_height - world.title_bar_height/2 - self.height/2
    UIButton.draw(self)
end


function world.btn_sprite_edit.callback()
    -- TODO create sprite editor and link it here
end











world.btn_layer_delete = UIButton("-")
world.btn_layer_delete.height = world.title_bar_height
world.btn_layer_delete.text_color = paint.black
world.btn_layer_delete.bg_color = paint.umber
world.btn_layer_delete.text_hover_color = paint.white
world.btn_layer_delete.bg_hover_color = paint.dark_gray



function world.btn_layer_delete:draw()
    local window_width = WIDTH * world.layer_window_width
    self.width = window_width/2 - 1
    self.x = WIDTH - window_width
    self.y = HEIGHT - self.height - world.title_bar_height - 2
    self.callback = function() world:deleteSelectedLayer() end
    UIButton.draw(self)
end










world.btn_layer_create = UIButton("+")
world.btn_layer_create.height = world.title_bar_height
world.btn_layer_create.text_color = paint.black
world.btn_layer_create.bg_color = paint.umber
world.btn_layer_create.text_hover_color = paint.white
world.btn_layer_create.bg_hover_color = paint.dark_gray


function world.btn_layer_create:draw()
    self.width = WIDTH * world.layer_window_width / 2 - 1
    self.x = WIDTH - self.width
    self.y = HEIGHT - self.height - world.title_bar_height - 2
    self.callback = function() world:createNewLayer() end
    UIButton.draw(self)
end






















function world:showDeveloperTools()
    self.debug = true
end











function world:hideDeveloperTools()
    self.alert = UIAlert("Close developer tools?")
    self.alert.left_button.text_color = paint.umber
    self.alert.left_button.bg_color = paint.orange
    self.alert.right_button.text_color = paint.umber
    self.alert.right_button.bg_color = paint.orange
    self.alert.right_button.title = "Save and Quit"
    self.alert:open()
    
    function self.alert.right_button.callback() -- confirm
        -- save everything that is needed to be saved before exit the world editor
        self.debug = false
        self.alert = nil
    end
    
    function self.alert.left_button.callback() -- alternative dismiss
        self.alert = nil
    end
end















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
-- The resulting x and y position represents at which tile or chunk you are in the world
 
function world:getCameraOffset()
    local tiles_x = math.floor(self.camera_x / (self.camera_zoom_x * self.tile_width))
    local tiles_y = math.floor(self.camera_y / (self.camera_zoom_y * self.tile_height))
    local chunks_x = math.floor(tiles_x / self.chunk_width)
    local chunks_y = math.floor(tiles_y / self.chunk_height)
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











function world:getTileIndicesEclosedByBrushBounds()
    local counter_offset = 1 -- to count tiles from 0 upwards (like pico-8 does) set this value to 0
    local cols = self.atlas_texture.width / self.tile_width
    local indices = {}
    
    for y = self.brush_y, self.brush_y + self.brush_height - 1 do
        for x = self.brush_x, self.brush_x + self.brush_width - 1 do
            table.insert(indices, math.tointeger(cols * y + x + counter_offset))
        end
    end
    
    return indices
end














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













-- Adjust brush position when it goes outside the spritesheet bounds

function world:pullBrushIntoAtlasBounds()
    local cols = self.atlas_texture.width / self.tile_width
    local rows = self.atlas_texture.height / self.tile_height
    local overlap_x = self.brush_x + self.brush_width - cols
    local overlap_y = self.brush_y + self.brush_height - rows
    
    if overlap_x > 0 then self.brush_x = self.brush_x - overlap_x end
    if overlap_y > 0 then self.brush_y = self.brush_y - overlap_y end
end












-- Adjust atlas_texture position when it goes outside the spritesheet window

function world:pullAtlasIntoAtlasWindowBounds()
    local atlas_width = self.atlas_texture.width * self.atlas_zoom_x
    
    if ( -- atlas_texture.width smaller than WIDTH?
        atlas_width < WIDTH
        and (self.atlas_x <= 0 or self.atlas_x >= WIDTH or self.atlas_x + atlas_width <= 0 or self.atlas_x + atlas_width >= WIDTH)
    )
    or ( -- atlas_texture.width larger than WIDTH?
        atlas_width > WIDTH
        and (self.atlas_x > 0 or self.atlas_x + atlas_width < WIDTH)
    )
    then
        self.atlas_x = 0
    end
end













-- Clamp the height of the spritesheet window

function world:pullAtlasWindowHeightOverflow()
    local window_height = HEIGHT * self.atlas_window_height
    local atlas_height = self.atlas_texture.height * self.atlas_zoom_y + self.title_bar_height
    
    if window_height > atlas_height then
        self.atlas_window_height = atlas_height / HEIGHT
    end
end














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
    
    
    pushStyle()
    pushMatrix()
    translate((self.camera_pivot_x * WIDTH) % tile_width, (self.camera_pivot_y * HEIGHT) % tile_height)
    
    -- vertical lines
    for x = -tile_width, WIDTH, tile_width do
        noFill()
        strokeWidth(2)
        stroke(paint.dark_gray.r, paint.dark_gray.g, paint.dark_gray.b, opacity)
        line(x + grid_scroll_x + 1, -tile_height, x + grid_scroll_x + 1, HEIGHT)
        strokeWidth(1)
        stroke(paint.umber.r, paint.umber.g, paint.umber.b, opacity)
        line(x + grid_scroll_x, -tile_height, x + grid_scroll_x, HEIGHT)
    end
    
    -- horizontal lines
    for y = -tile_height, HEIGHT, tile_height do
        strokeWidth(2)
        stroke(paint.dark_gray.r, paint.dark_gray.g, paint.dark_gray.b, opacity)
        line(-tile_width, y + grid_scroll_y - 1, WIDTH, y + grid_scroll_y - 1)
        strokeWidth(1)
        stroke(paint.umber.r, paint.umber.g, paint.umber.b, opacity)
        line(-tile_width, y + grid_scroll_y, WIDTH, y + grid_scroll_y)
    end
    
    resetMatrix()
    
    do -- origin axis indicators
        local ox = WIDTH * self.camera_pivot_x + self.camera_x
        local oy = HEIGHT * self.camera_pivot_y + self.camera_y
        
        -- y-axis
        strokeWidth(2)
        stroke(paint.blue.r, paint.blue.g, paint.blue.b, opacity)
        line(ox, oy, ox, HEIGHT)
        
        -- x-axis
        stroke(paint.red.r, paint.red.g, paint.red.b, opacity)
        line(ox, oy, WIDTH, oy)
    end
    
    resetMatrix()
    translate((self.camera_pivot_x * WIDTH) % chunk_width, (self.camera_pivot_y * HEIGHT) % chunk_height)
    
    -- display chunks
    for x = -chunk_width, WIDTH, chunk_width do
        for y = -chunk_height, HEIGHT - chunk_height, chunk_height do
            noStroke()
            fill(paint.dark_gray.r, paint.dark_gray.g, paint.dark_gray.b, opacity)
            ellipse(x + chunk_scroll_x, y + chunk_scroll_y, 20)
            noFill()
            strokeWidth(2)
            stroke(paint.orange.r, paint.orange.g, paint.orange.b, opacity)
            ellipse(x + chunk_scroll_x, y + chunk_scroll_y, 15)
        end
    end
    
    popMatrix()
    popStyle()
end















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
        stroke(paint.dark_gray.r, paint.dark_gray.g, paint.dark_gray.b, opacity)
        line(x + grid_scroll_x + 1, 0, x + grid_scroll_x + 1, -window_height)
        strokeWidth(1)
        stroke(paint.umber.r, paint.umber.g, paint.umber.b, opacity)
        line(x + grid_scroll_x, 0, x + grid_scroll_x, -window_height)
    end
    
    -- horizontal lines
    for y = math.floor(window_height / tile_height) * -tile_height, 0, tile_height do
        strokeWidth(2)
        stroke(paint.dark_gray.r, paint.dark_gray.g, paint.dark_gray.b, opacity)
        line(0, y + grid_scroll_y - 1, WIDTH, y + grid_scroll_y - 1)
        strokeWidth(1)
        stroke(paint.umber.r, paint.umber.g, paint.umber.b, opacity)
        line(0, y + grid_scroll_y, WIDTH, y + grid_scroll_y)
    end
end
















function world:drawMapWindow()
    self:centerCameraPivot()
    
    pushStyle()
    pushMatrix()
    font("HelveticaNeue-Light")
    fontSize(18)
    
    translate(self.camera_pivot_x * WIDTH, self.camera_pivot_y * HEIGHT)
    translate(self.camera_x, self.camera_y)
    scale(self.camera_zoom_x, self.camera_zoom_y)
    
    rect(0,0,8,8)
    
    resetMatrix()
    self:drawMapGrid()
    
    -- title bar
    noStroke()
    fill(paint.red)
    
    if self:mapIsPanning() then
        fill(paint.orange)
    end
    
    rect(0, HEIGHT - self.title_bar_height, WIDTH, self.title_bar_height)
    
    fill(paint.white)
    
    if self:mapIsPanning() then
        fill(paint.black)
    end
    
    local offset_x, offset_y = self:getCameraOffset()
    text(string.format("position %.0f, %.0f", -offset_x, -offset_y), WIDTH/2, HEIGHT - self.title_bar_height/2)
    
    popMatrix()
    popStyle()
end















function world:drawAtlasWindow()
    self:pullAtlasWindowHeightOverflow()
    self:pullAtlasIntoAtlasWindowBounds()
    
    local window_height = HEIGHT * self.atlas_window_height
    
    -- background
    pushStyle()
    noStroke()
    fill(paint.dark_gray)
    rect(0, 0, WIDTH, window_height)
    
    
    -- atlas
    if self.atlas_texture then
        pushMatrix()
        translate(self.atlas_x, self.atlas_y)
        translate(0, window_height - self.title_bar_height)
        scale(self.atlas_zoom_x, self.atlas_zoom_y)
        translate(0, -self.atlas_texture.height)
        
        clip(0, 0, WIDTH, window_height - 1)
            fill(self.bg_color)
            rect(0, 0, self.atlas_texture.width, self.atlas_texture.height)
            
            spriteMode(CORNER)
            sprite(self.atlas_texture)
            
            -- brush
            resetMatrix()
            self:drawAtlasBrush()
        
            -- grid
            resetMatrix()
            translate(0, window_height - self.title_bar_height)
            self:drawAtlasGrid()
        clip()
        popMatrix()
    end
    
    
    -- title bar
    if self:brushIsResizing() then
        fill(paint.orange)
    else
        fill(paint.red)
    end
    
    noStroke()
    rect(0, window_height - self.title_bar_height, WIDTH, self.title_bar_height)
    
    do -- info about tile indices that are enclosed by the atlas brush
        local indices = self:getTileIndicesEclosedByBrushBounds()
        local info_text = string.format("selected %i...%i", indices[1], indices[#indices]) -- abbreviate long text
        
        if #indices <= 4 then
            info_text = "selected "..table.concat(indices, ", ")
        end
        
        local w, h = textSize(info_text)
        
        fill(paint.white)
        font("HelveticaNeue-Light")
        fontSize(18)
        text(info_text, WIDTH/2, window_height - self.title_bar_height/2)
    end
    
    
    -- buttons
    self.btn_sprite_edit:draw()
    
    
    popStyle()
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
    stroke(paint.black)
    strokeWidth(1)
    rect(0, 0, self.tile_width * self.brush_width, self.tile_height * self.brush_height)
    
    stroke(paint.white)
    strokeWidth(.5)
    rect(.5, .5, self.tile_width * self.brush_width - 1, self.tile_height * self.brush_height - 1)
    
    popMatrix()
    popStyle()
end












function world:createNewLayer()
    local layer_name = "Layer"..#self.layer_stack -- TODO better naming or show immediately the input ui popup
    
    local toggle = UISwitch(0, 0, true)
    toggle.bg_color = paint.transparent
    toggle.state_color = paint.umber
    toggle.state_min_width = 0
    toggle.width = self.layer_item_height
    toggle.height = self.layer_item_height
    
    local button = UIButton(layer_name, 0, 0, WIDTH * self.layer_window_width - self.layer_item_height, self.layer_item_height)
    button.text_color = paint.white
    button.bg_color = paint.transparent
    button.text_hover_color = paint.white
    button.bg_hover_color = paint.transparent
    
    function button.touched(this, touch) -- override default handler to support state propagation
        if touch.state == BEGAN
        and touch.x > this.x and touch.x < this.x + this.width
        and touch.y > this.y and touch.y < this.y + this.height
        then
            this.is_active = true
            return true
        end
        
        if touch.state == ENDED then
            this.is_active = false
            
            if touch.initX > this.x and touch.initX < this.x + this.width
            and touch.initY > this.y and touch.initY < this.y + this.height
            and touch.x > this.x and touch.x < this.x + this.width
            and touch.y > this.y and touch.y < this.y + this.height
            then
                return true
            end
        end
        
        return false
    end
    
    
    local stack_pos = (self.layer_selected or #self.layer_stack) + 1
    
    local object = {
        visibility_toggle = toggle,
        layer_button = button,
        tile_list = {}
    }
    
    table.insert(self.layer_stack, stack_pos, object)
    self:selectLayer(stack_pos)
end












function world:deleteSelectedLayer()
    if self.layer_selected then
        table.remove(self.layer_stack, self.layer_selected)
        self:selectLayer(self.layer_selected - 1)
    end
end











function world:selectLayer(id)
    if self.layer_selected and self.layer_stack[self.layer_selected] then
        self.layer_stack[self.layer_selected].layer_button.bg_color = paint.transparent -- deselect current
    end
    
    if #self.layer_stack > 0 then
        id = math.max(1, id)
        self.layer_stack[id].layer_button.bg_color = paint.umber -- select another
        self.layer_selected = id -- save selection
        return
    end
    
    self.layer_selected = nil
end











function world:renameLayer(id)
    -- TODO
    -- display keyboard pop-over hud
    -- wait until dismissed or confirmed
    -- change layer_object.layer_button.title to new string
end












function world:touchLayer(touch)
    if touch.x > WIDTH - WIDTH * self.layer_window_width
    and touch.y > HEIGHT * self.atlas_window_height
    and touch.y < HEIGHT - self.title_bar_height
    then
        for layer_id, layer_object in ipairs(self.layer_stack) do
            
            layer_object.visibility_toggle:touched(touch)
            
            if layer_object.layer_button:touched(touch) and touch.state == ENDED then
                
                self:selectLayer(layer_id)
                
                if touch.tapCount >= 2 then
                    self:renameLayer(layer_id)
                end
                
                return true
                
            end
        end
    end
    
    return false
end












function world:scrollLayerWindow(touch)
    local atlas_window = HEIGHT * self.atlas_window_height
    local layer_window = WIDTH * self.layer_window_width
    local title_bar = self.title_bar_height + self.layer_item_height + 6
    
    
    if touch.state == MOVING
    and touch.initX > WIDTH - layer_window
    and touch.initY > atlas_window
    and touch.initY < HEIGHT - title_bar
    then
        local items_length = self.layer_item_height * #self.layer_stack
        local curr_scroll = self.layer_scroll + touch.deltaY
        
        if items_length > HEIGHT - atlas_window - title_bar
        and curr_scroll >= 0
        and curr_scroll <= items_length - (HEIGHT - atlas_window - title_bar)
        then
            self.layer_scroll = curr_scroll
        end
        
        return true
    end
    return false
end
















function world:drawLayerStack()
    local atlas_window = HEIGHT * self.atlas_window_height
    local layer_window = WIDTH * self.layer_window_width
    local title_bar = self.title_bar_height + self.layer_item_height + 4
    local origin_x = WIDTH - layer_window
    local origin_y = HEIGHT - title_bar + self.layer_scroll
    
    clip(origin_x, atlas_window, layer_window, HEIGHT - atlas_window - title_bar)
    
    for layer_id, layer_object in ipairs(self.layer_stack) do
        local button = layer_object.layer_button
        local toggle = layer_object.visibility_toggle
        
        button.width = layer_window - toggle.width
        button.x = WIDTH - button.width
        button.y = origin_y - layer_id * button.height
        
        toggle.x = origin_x
        toggle.y = origin_y - layer_id * toggle.height
        
        if button.y + button.height > atlas_window
        and button.y < origin_y
        and toggle.y + toggle.height > atlas_window
        and toggle.y < origin_y
        then
            button:draw()
            toggle:draw()
        end
    end
    
    clip()
end














function world:drawLayerWindow()
    local window_width = WIDTH * self.layer_window_width
    local atlas_window = HEIGHT * self.atlas_window_height
    
    pushStyle()
    
    fill(paint.dark_gray)
    rect(WIDTH - window_width, atlas_window, window_width, HEIGHT - atlas_window - self.title_bar_height)
    
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
    
    
    if touch.state == MOVING and self.resize_atlas_window then
        local y = self.atlas_window_height + touch.deltaY
        local delta_height = y / HEIGHT -- as percentage multiplier
        local height = self.atlas_window_height + delta_height
        local window_height = HEIGHT * height
        
        if touch.deltaY > 0 and self.atlas_y > 0 then
            self.atlas_y = math.max(0, self.atlas_y - touch.deltaY) -- reveal atlas texture top overflow
        end
        
        if touch.deltaY < 0 and self.layer_scroll > 0 then
            self.layer_scroll = math.max(0, self.layer_scroll + touch.deltaY) -- reveal layer items top overflow
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
        self.resize_atlas_window = nil
    end
    
    return false
end














function world:panAtlasWindow(touch)
    local window_height = HEIGHT * self.atlas_window_height
    
    
    if touch.state == MOVING
    and touch.initY < window_height
    and touch.y < window_height
    then
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














function world:panMapWindow(touch)
    local atlas_window = HEIGHT * self.atlas_window_height
    local layer_window = WIDTH * self.layer_window_width
    
    
    if touch.state == BEGAN
    and touch.x < WIDTH - layer_window
    and touch.y > atlas_window
    and touch.y < HEIGHT - self.title_bar_height
    then
        self.pan_map_window = true
        return true
    end
    
    if touch.state == MOVING and self.pan_map_window then
        self.camera_x = self.camera_x + touch.deltaX
        self.camera_y = self.camera_y + touch.deltaY
        return true
    end
    
    if touch.state == ENDED then
        self.pan_map_window = nil
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















function world:resetCameraPosition(touch)
    if touch.state == ENDED
    and touch.initY > HEIGHT - self.title_bar_height
    and touch.y > HEIGHT - self.title_bar_height
    and touch.tapCount >= 2
    then
        self.camera_x = 0
        self.camera_y = 0
    end
end











function world:minimizeAtlasWindow(touch)
    local window_height = HEIGHT * self.atlas_window_height
    
    if touch.state == ENDED
    and touch.tapCount > 1
    and touch.initY < window_height
    and touch.initY > window_height - self.title_bar_height
    and touch.y < window_height
    and touch.y > window_height - self.title_bar_height
    then
        self.layer_scroll = math.max(0, self.layer_scroll - HEIGHT * self.atlas_window_height) -- reveal layer items overflow
        self.atlas_window_height = self.title_bar_height / HEIGHT
    end
end















-- Combine every part and draw the world (and editor if needed)

function world:draw()
    pushStyle()
    
    background(self.bg_color)
    noSmooth()
    
    if self.debug then
        self:drawMapWindow()
        self:drawLayerWindow()
        self:drawLayerStack()
        self:drawAtlasWindow()
        
        self.btn_layer_create:draw()
        self.btn_layer_delete:draw()
        
        if self.alert then
            self.alert:draw()
        end
    end
    
    popStyle()
end












function world:touched(touch)
    if self.debug then
        if self.alert then
            self.alert:touched(touch)
            return
        end
        
        self:resetCameraPosition(touch)
        self:minimizeAtlasWindow(touch)
        
        self.btn_layer_create:touched(touch)
        self.btn_layer_delete:touched(touch)
        self.btn_sprite_edit:touched(touch)
        
        if not self:panMapWindow(touch) then
            if not self:resizeAtlasWindow(touch) then
                if not self:resizeAtlasBrush(touch) then
                    self:panAtlasWindow(touch)
                    self:moveAtlasBrush(touch)
                end
                self:scrollLayerWindow(touch)
                self:touchLayer(touch)
            end
        end
        
        if touch.state == ENDED then
            sound(world.sfx_mouse_click)
        end
        
    end
end




-- TODO make world table into World class (some methods must be tested, because of direct world[prop] referecnes)





-- This is the world object with all its related methods and routines
-- it handles loading, displaying and editing rooms and a ton of other stuff

world = {}



world.debug = false

world.alert = nil -- message box with dismiss and confirm




world.bg_color = paint.black

world.title_bar_height = 32

world.sfx_mouse_click = "Dropbox:mouse_pressUp_hard"




world.room_tiles = {}
world.room_entities = {}
world.room_undos = {}
world.room_action_queue = createThread()
world.room_render_queue = createThread()




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
world.layer_settings = {} -- on how to render the layer
world.layer_selected = nil
world.layer_scroll = 0
world.layer_item_height = world.title_bar_height
world.layer_window_width = .125 -- as percentage multiplier











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












world.btn_layer_sort_front = UIButton("Up")
world.btn_layer_sort_front.height = world.title_bar_height
world.btn_layer_sort_front.text_color = paint.black
world.btn_layer_sort_front.bg_color = paint.umber
world.btn_layer_sort_front.text_hover_color = paint.white
world.btn_layer_sort_front.bg_hover_color = paint.dark_gray


function world.btn_layer_sort_front:draw()
    local window_width = WIDTH * world.layer_window_width
    self.width = window_width/2 - 1
    self.x = WIDTH - window_width
    self.y = HEIGHT * world.atlas_window_height + 2
    self.callback = function() world:shiftSelectedLayerUp() end
    UIButton.draw(self)
end













world.btn_layer_sort_back = UIButton("Down")
world.btn_layer_sort_back.height = world.title_bar_height
world.btn_layer_sort_back.text_color = paint.black
world.btn_layer_sort_back.bg_color = paint.umber
world.btn_layer_sort_back.text_hover_color = paint.white
world.btn_layer_sort_back.bg_hover_color = paint.dark_gray


function world.btn_layer_sort_back:draw()
    self.width = WIDTH * world.layer_window_width / 2 - 1
    self.x = WIDTH - self.width
    self.y = HEIGHT * world.atlas_window_height + 2
    self.callback = function() world:shiftSelectedLayerDown() end
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
    else
        self.camera_pivot_x = .5
        self.camera_pivot_y = .5
    end
end












-- Convert screen coordinates to world coordinates

function world:getWorldPosition(screen_x, screen_y)
    return
        (WIDTH * self.camera_pivot_x + self.camera_x - screen_x) / -self.camera_zoom_x,
        (HEIGHT * self.camera_pivot_y + self.camera_y - screen_y) / -self.camera_zoom_y
end










-- Convert world coordinates to screen coordinates
-- When checkin if the whole shape is visisble, you could pass all (four) corners to this method and see if any is on screen 

function world:getScreenPosition(world_x, world_y)
    local pnt_x = world_x * self.camera_zoom_x + self.camera_x + WIDTH * self.camera_pivot_x
    local pnt_y = world_y * self.camera_zoom_y + self.camera_y + HEIGHT * self.camera_pivot_y
    local is_inside = pnt_x >= 0 and pnt_x <= WIDTH and pnt_y >= 0 and pnt_y <= HEIGHT
    return
        pnt_x,
        pnt_y,
        is_inside
end


















function world:getTileAtlasIndexPosition(x, y)
    local window_height = HEIGHT * self.atlas_window_height - self.title_bar_height
    local tile_width = self.tile_width * self.atlas_zoom_x
    local tile_height = self.tile_height * self.atlas_zoom_y
    local tile_id_x = math.floor((x - self.atlas_x) / tile_width)
    local tile_id_y = math.floor((window_height - y + self.atlas_y) / tile_height)
    return
        tile_id_x, -- col
        tile_id_y -- row
end












function world:getTileWorldIndexPosition(screen_x, screen_y)
    local world_x, world_y = self:getWorldPosition(screen_x, screen_y)
    return
        math.floor(world_x / self.tile_width), -- col
        math.floor(world_y / self.tile_height) -- row
end












function world:getChunkWorldIndexPosition(screen_x, screen_y)
    local world_x, world_y = self:getWorldPosition(screen_x, screen_y)
    return
        math.floor(world_x / (self.tile_width * self.chunk_width)), -- col
        math.floor(world_y / (self.tile_height * self.chunk_height)) -- row
end














function world:isPointInsideChunk(pnt_x, pnt_y, chunk_x, chunk_y) -- compare both world coordinates
    local width = self.tile_width * self.chunk_width
    local height = self.tile_height * self.chunk_height
    
    if pnt_x > chunk_x and pnt_x < chunk_x + width
    and pnt_y > chunk_y and pnt_y < chunk_y + height
    then
        return true
    end

    return false
end



















function world:tileWorldPositionAlreadyTaken(index_x, index_y, layer)
    layer = layer or self.layer_stack[self.layer_selected]
    
    for _, tile_reference in ipairs(layer.room_tiles) do
        if self.room_tiles[tile_reference].x == index_x
        and self.room_tiles[tile_reference].y == index_y
        then
            return
                true,
                self.room_tiles[tile_reference] -- also return the find
        end
    end
    
    return false
end
















function world:getLayerObjectByName(layer_name)
    for layer_id, layer_object in ipairs(self.layer_stack) do
        if layer_object.layer_button.title == layer_name then
            return
                layer_object,
                layer_id
        end
    end
end

















function world:getVisibleChunkIndexPositions()
    local tw, th = self.tile_width, self.tile_height
    local x1, y1 = self:getChunkWorldIndexPosition(-tw, -th) -- map screen to world coordinates
    local x2, y2 = self:getChunkWorldIndexPosition(WIDTH - tw, HEIGHT - th)
    local chunks = {}
    
    for y = y1, y2 do -- collect all chunks in screen range
        for x = x1, x2 do
            table.insert(chunks, {x = x, y = y})
        end
    end
    
    return chunks
end















function world:getTileIndicesEclosedByBrushBounds()
    local cols = self.atlas_texture.width / self.tile_width
    local indices = {}
    
    for y = self.brush_y, self.brush_y + self.brush_height - 1 do
        for x = self.brush_x, self.brush_x + self.brush_width - 1 do
            table.insert(indices, math.tointeger(cols * y + x + 1))
        end
    end
    
    return indices -- single numbers (not cols and rows)
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
    
    -- atlas_texture.width smaller than WIDTH?
    if (atlas_width < WIDTH
    and (self.atlas_x <= 0 or self.atlas_x >= WIDTH or self.atlas_x + atlas_width <= 0 or self.atlas_x + atlas_width >= WIDTH))
    -- atlas_texture.width larger than WIDTH?
    or (atlas_width > WIDTH
    and (self.atlas_x > 0 or self.atlas_x + atlas_width < WIDTH))
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





















function world:renderChunk(world_x, world_y, layers) -- (re-)render chunk or tile entity at given world position and layers
    
    -- loop layers in reverse because of drawing order
    
    for layer_id = #layers, 1, -1 do
        local layer_object = layers[layer_id]
        local layer_name = layer_object.layer_button.title
        local layer_merge = true
        local canvas_width = self.tile_width * self.chunk_width
        local canvas_height = self.tile_height * self.chunk_height
        
        
        if layer_object.visibility_toggle.value == layer_object.visibility_toggle.max then
            
            -- customize layer settings if any
            
            for _, setting in ipairs(self.layer_settings) do
                if setting.layer_name == layer_name then
                    layer_merge = defaultBoolean(setting.merge, layer_merge)
                    if not layer_merge then
                        canvas_width = self.tile_width
                        canvas_height = self.tile_height
                    end
                    break
                end
            end
            
            
            -- pre-define a room_entity object
            -- remember layer_merge is false by default so we will setup everything for a chunk
            local entity = WorldEntity(world_x, world_y, 1, 1)
            entity.sprite.texture = image(canvas_width, canvas_height)
            entity.sprite.tilesize = vec2(canvas_width, canvas_height)
            entity.sprite.spritesize = vec2(canvas_width, canvas_height)
            
            local entity_template = {
                entity_object = entity,
                chunk_information = { -- this is just for identification when re-rendering
                    layer_name = layer_name,
                    x = world_x,
                    y = world_y
                }
            }
            
            
            -- loop on layer room_tiles and see which ones belong to this chunk
            
            setContext(entity_template.entity_object.sprite.texture)
            
            for _, room_tile_id in ipairs(layer_object.room_tiles) do
                local room_tile = self.room_tiles[room_tile_id]
                
                if layer_merge then
                    -- check each tile's corner on current layer to see if it overlaps the current chunk
                    if self:isPointInsideChunk(room_tile.x, room_tile.y, world_x, world_y) -- bottom left
                    or self:isPointInsideChunk(room_tile.x + self.tile_width, room_tile.y, world_x, world_y) -- bottom right
                    or self:isPointInsideChunk(room_tile.x + self.tile_width, room_tile.y + self.tile_height, world_x, world_y) -- top right
                    or self:isPointInsideChunk(room_tile.x, room_tile.y + self.tile_height, world_x, world_y) -- top left
                    then
                        -- paint the tile onto the chunk texture
                        local tile_sprite = WorldEntity(room_tile.x - world_x, room_tile.y - world_y, room_tile.sprite_col, room_tile.sprite_row)
                        tile_sprite:draw()
                    end
                else
                    -- oh well, seems like each tile is its own entity, so re-adjust the entity template
                    
                    entity_template.entity_object.sprite.texture = self.atlas_texture
                    entity_template.entity_object.sprite.tilesize = vec2(self.tile_width, self.tile_height)
                    entity_template.entity_object.sprite.spritesize = vec2(self.tile_width, self.tile_height)
                    entity_template.entity_object.sprite.animations.default = {vec2(room_tile.sprite_col, room_tile.sprite_row)}
                    
                    print("separate tiles as own entities")
                end
            end -- layer room_tiles loop
            
            setContext()
            
            
            -- save the room_entity
            
            if layer_merge then
                local stack_pos = #self.room_entities + 1
                
                for i, e in ipairs(self.room_entities) do
                    if e.chunk_information.x == world_x
                    and e.chunk_information.y == world_y
                    and e.chunk_information.layer_name == layer_name
                    then
                        stack_pos = i
                        table.remove(self.room_entities, stack_pos)
                        break
                    end
                end
                
                table.insert(self.room_entities, stack_pos, entity_template)
            end
            
        end -- layer visibility check
        
        
        coroutine.yield()
        
    end -- layer loop
end





















function world:drawEntities()
    pushMatrix()
    translate(self.camera_pivot_x * WIDTH, self.camera_pivot_y * HEIGHT)
    translate(self.camera_x, self.camera_y)
    scale(self.camera_zoom_x, self.camera_zoom_y)
    
    for _, entity in ipairs(self.room_entities) do
        local layer_name = entity.chunk_information.layer_name
        local layer_object = self:getLayerObjectByName(layer_name)
        local visibility_toggle = layer_object.visibility_toggle
        
        if visibility_toggle.value == visibility_toggle.max then
            entity.entity_object:draw()

            -- TODO remove chunks that are out of the visible screen bounds
        end
    end
    
    popMatrix()
end





















function world:paintTilesOntoMap(touch)

    local curr_tile = vec2(self:getTileWorldIndexPosition(touch.x, touch.y))

    
    -- there is a layer to act on?
    if self.layer_selected
    -- only if layer is not hidden
    and self.layer_stack[self.layer_selected].visibility_toggle.value == self.layer_stack[self.layer_selected].visibility_toggle.max
    -- initially touched viewport?
    and (touch.initX < WIDTH - WIDTH * self.layer_window_width
    and touch.initY > HEIGHT * self.atlas_window_height
    and touch.initY < HEIGHT - self.title_bar_height)
    -- and current touch still inside the viewport?
    and (touch.x < WIDTH - WIDTH * self.layer_window_width
    and touch.y > HEIGHT * self.atlas_window_height
    and touch.y < HEIGHT - self.title_bar_height)
    -- just tapped?
    and ((touch.state == ENDED
    and touch.initX == touch.x
    and touch.initY == touch.y)
    -- or moved finger after certain duration?
    or (touch.state == MOVING
    and (self.paint_tiles_onto_map or touch.duration > .25)))
    -- but only when touch moved past the current tile
    and (not self.paint_tile
    or self.paint_tile ~= curr_tile)
    then
        local tile_width = self.tile_width
        local tile_height = self.tile_height
        local chunk_width = tile_width * self.chunk_width
        local chunk_height = tile_height * self.chunk_height
        
        local undo_batch = {}
        local curr_layer = self.layer_stack[self.layer_selected]
        
        
        -- unwrap brush into single tiles
        
        for y = 0, self.brush_height - 1 do
            for x = 0, self.brush_width - 1 do
                
                -- calculate final values for the current tile in brush
                
                local tile_template = {
                    -- world position of the tile
                    x = (curr_tile.x + x) * tile_width,
                    y = (curr_tile.y - y) * tile_height,
                    -- self.atlas_texture brush position (beginning off 1,1)
                    sprite_col = (self.brush_x + x) + 1,
                    sprite_row = (self.brush_y + y) + 1
                }
                
                -- check current layer to see wether painted tile position already exist in self.room_tiles
                
                local tile_screen_pos = vec2(self:getScreenPosition(tile_template.x, tile_template.y))
                local parent_chunk = vec2(self:getChunkWorldIndexPosition(tile_screen_pos.x, tile_screen_pos.y)) -- to which this tile belongs
                local chunk_world_pos = vec2(parent_chunk.x * chunk_width, parent_chunk.y * chunk_height)
                local position_taken, by_tile = self:tileWorldPositionAlreadyTaken(tile_template.x, tile_template.y)
                
                
                if not position_taken -- tile not exist yet?
                or by_tile.sprite_col ~= tile_template.sprite_col -- or exists but is different tile
                or by_tile.sprite_row ~= tile_template.sprite_row
                then
                    -- create new coroutine thread to register and render tile
                    if by_tile then
                        -- tile position already existed so just re-assign/update
                        by_tile.sprite_col = tile_template.sprite_col
                        by_tile.sprite_row = tile_template.sprite_row
                        
                        -- cache undo action for this tile
                        table.insert(undo_batch, function()
                            -- revert back to tile which was there before current painting action
                            by_tile.x = by_tile.x
                            by_tile.y = by_tile.y
                            by_tile.sprite_col = by_tile.sprite_col
                            by_tile.sprite_row = by_tile.sprite_row
                            self:renderChunk(chunk_world_pos.x, chunk_world_pos.y, {curr_layer})
                        end)
                    else
                        -- tile position did not exist so create entirely
                        table.insert(self.room_tiles, tile_template)
                        table.insert(self.layer_stack[self.layer_selected].room_tiles, #self.room_tiles)
                        
                        -- cache undo action for this tile
                        table.insert(undo_batch, function()
                            -- delete again on undo because tile did not exist before
                            self.room_tiles[#self.room_tiles] = nil
                            self.layer_stack[self.layer_selected].room_tiles = nil
                            self:renderChunk(chunk_world_pos.x, chunk_world_pos.y, {curr_layer})
                        end)
                    end
                    
                    -- re-render chunk to which this tile belongs
                    exec(self.room_action_queue, self.renderChunk, self, chunk_world_pos.x, chunk_world_pos.y, {curr_layer})
                end
                
            end
        end
        
        
        -- register an undo after painting action finished completely
        
        exec(self.room_action_queue, function()
            table.insert(self.room_undos, undo_batch)
            self:removeUndoOverflow()
        end)
        
        self.paint_tile = curr_tile
        self.paint_tiles_onto_map = true
        
        return true
    end
    
    
    if touch.state == ENDED then
        self.paint_tile = nil
        self.paint_tiles_onto_map = nil
    end
    
    return false
end















function world:undoPaintAction()
    local latest = #self.room_undos

    for _, func in ipairs(self.room_undos[latest]) do -- loop over the batch of routines
        exec(self.room_action_queue, func) -- run reverse action on separate thread
    end

    exec(self.room_action_queue, table.remove, self.room_undos, latest)
end














function world:removeUndoOverflow() -- forget undos that are too old
    while #self.room_undos > 10 do -- clamp undo history to n undos
        table.remove(self.room_undos, 1)
    end
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

    local viewport_cx = self.camera_pivot_x * WIDTH
    local viewport_cy = self.camera_pivot_y * HEIGHT
    
    pushStyle()
    pushMatrix()
    font("HelveticaNeue-Light")
    fontSize(18)
    

    -- draw grid
    resetMatrix()
    self:drawMapGrid()
    

    do -- display current camera center position
        local r = 4 -- radius
        noFill()
        stroke(paint.white)
        strokeWidth(1)
        line(viewport_cx - r, viewport_cy - r, viewport_cx + r, viewport_cy + r)
        line(viewport_cx - r, viewport_cy + r, viewport_cx + r, viewport_cy - r)
    end
    
    
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
    

    -- indicator at which tile position the camera currently is
    local offset_x, offset_y = self:getTileWorldIndexPosition(viewport_cx, viewport_cy)
    text(string.format("position %.0f, %.0f", offset_x, offset_y), WIDTH/2, HEIGHT - self.title_bar_height/2)
    
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
        fill(paint.orange)
    else
        fill(paint.red)
    end
    
    noStroke()
    font("HelveticaNeue-Light")
    fontSize(18)
    
    rect(0, window_height - self.title_bar_height, WIDTH, self.title_bar_height)
    
    
    -- additional information
    fill(paint.white)
    
    do -- info about tile indices that are enclosed by the atlas brush
        local indices = self:getTileIndicesEclosedByBrushBounds()
        local info_text = string.format("selected %i...%i", indices[1], indices[#indices]) -- abbreviate long text
        
        if #indices <= 4 then
            info_text = "selected "..table.concat(indices, ", ")
        end
        
        local w, h = textSize(info_text)
        text(info_text, WIDTH/2, window_height - self.title_bar_height/2)
    end
    
    
    do -- full layer name which the brush affecting
        local txt, w, h
        
        if self.layer_selected then
            local layer_toggle = self.layer_stack[self.layer_selected].visibility_toggle
            local layer_button = self.layer_stack[self.layer_selected].layer_button
            local is_hidden = layer_toggle.value < layer_toggle.max
            local prefix = is_hidden and "invisible" or "altering"
            txt = string.format(prefix.." %s", layer_button.title)
            w, h = textSize(txt)
            
            if is_hidden then
                fill(paint.blue)
            end
        else
            fill(paint.blue)
            txt = "no layer"
            w, h = textSize(txt)
        end
        
        text(txt, WIDTH - w/2 - 16, window_height - self.title_bar_height/2)
        
        
        -- indicator that coroutine tasks are being executed
        
        if #self.room_action_queue > 0
        or not self.layer_selected
        or (self.layer_selected
        and self.layer_stack[self.layer_selected].visibility_toggle.value < self.layer_stack[self.layer_selected].visibility_toggle.max)
        then
            pushMatrix()
            translate(WIDTH - w - 32, window_height - self.title_bar_height/2)

            local angle = 500 * ElapsedTime
            
            if #self.room_action_queue > 0 then -- rotate when executing tasks otherwise just blink
                rotate(-angle)
            end
            
            fill(paint.blue.r, paint.blue.g, paint.blue.b, angle % 255)
            rectMode(CENTER)
            rect(0, 0, self.title_bar_height/2, self.title_bar_height/2)
            popMatrix()
        end
    end
    
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
    local layer_name = generateRandomString(8) -- TODO better naming or show immediately the input ui popup
    
    local toggle = UISwitch(0, 0, true)
    toggle.bg_color = paint.transparent
    toggle.state_color = paint.umber
    toggle.state_min_width = 0
    toggle.width = self.layer_item_height
    toggle.height = self.layer_item_height
    
    
    local button = UIButton(layer_name, 0, 0, WIDTH * self.layer_window_width - self.layer_item_height, self.layer_item_height)
    button.text_color = paint.white
    button.bg_color = paint.transparent
    
    
    function button.draw(this)
        pushStyle()
        font("HelveticaNeue-Light") -- this is needed!
        fontSize(20)
        
        do -- automatically shorten layer names to fit into remaining space
            local title_width = textSize(this.title)
            
            if title_width >= this.width then
                local max_width = this.width / title_width
                local title_length = math.floor(#this.title * max_width - 3)
                this.title_format = "%."..title_length.."s..." -- n letters and 3 dots
            else
                this.title_format = "%s" -- default
            end
        end
        
        UIButton.draw(this)
        
        popStyle()
    end
    
    
    function button.touched(this, touch) -- override default handler to support state propagation and ignore hover color changes
        if touch.state == ENDED then
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
    
    
    -- order is like in photoshop (top layers are hierarchically above bottom ones)
    
    local stack_pos = self.layer_selected or 1
    
    local object = {
        visibility_toggle = toggle,
        layer_button = button,
        room_tiles = {}
    }
    
    table.insert(self.layer_stack, stack_pos, object)
    self:deselectLayer(stack_pos + 1)
    self:selectLayer(stack_pos)
end

















function world:deleteSelectedLayer()
    if self.layer_selected then
        table.remove(self.layer_stack, self.layer_selected)
        self:selectLayer(self.layer_selected)
    end
end













function world:selectLayer(id)
    if #self.layer_stack > 0 then
        id = math.min(#self.layer_stack, math.max(1, id)) -- clamp
        self.layer_stack[id].layer_button.bg_color = paint.umber -- select another
        self.layer_selected = id -- save selection
        return
    end
    self.layer_selected = nil
end









function world:deselectLayer(id)
    if id and self.layer_stack[id] then
        self.layer_stack[id].layer_button.bg_color = paint.transparent
    end
end












function world:shiftSelectedLayerUp()
    if self.layer_selected then
        local object = self.layer_stack[self.layer_selected]
        local stack_pos = math.max(1, self.layer_selected - 1)
        
        self:deselectLayer(self.layer_selected)
        table.remove(self.layer_stack, self.layer_selected)
        table.insert(self.layer_stack, stack_pos, object)
        self:selectLayer(stack_pos)
    end
end












function world:shiftSelectedLayerDown()
    if self.layer_selected then
        local object = self.layer_stack[self.layer_selected]
        local stack_pos = math.min(#self.layer_stack, self.layer_selected + 1)
        
        self:deselectLayer(self.layer_selected)
        table.remove(self.layer_stack, self.layer_selected)
        table.insert(self.layer_stack, stack_pos, object)
        self:selectLayer(stack_pos)
    end
end












function world:renameLayer(id)
    -- TODO
    -- display keyboard pop-over hud
    -- wait until dismissed or confirmed
    -- change layer_object.layer_button.title to new string
end














function world:touchSingleLayer(touch)
    if touch.x > WIDTH - WIDTH * self.layer_window_width
    and touch.y > HEIGHT * self.atlas_window_height + self.layer_item_height + 4
    and touch.y < HEIGHT - self.title_bar_height - self.layer_item_height - 4
    then
        for layer_id, layer_object in ipairs(self.layer_stack) do
            
            layer_object.visibility_toggle:touched(touch)
            
            if layer_object.layer_button:touched(touch) and touch.state == ENDED then
                
                self:deselectLayer(self.layer_selected)
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
    local top_bar = self.title_bar_height + self.layer_item_height + 4
    local bottom_bar = self.layer_item_height + 4
    
    
    if touch.state == MOVING
    and touch.initX > WIDTH - layer_window
    and touch.initY > atlas_window
    and touch.initY < HEIGHT - top_bar
    then
        local items_length = self.layer_item_height * #self.layer_stack
        local curr_scroll = self.layer_scroll + touch.deltaY
        
        if items_length > HEIGHT - atlas_window - top_bar - bottom_bar
        and curr_scroll >= 0
        and curr_scroll <= items_length - (HEIGHT - atlas_window - top_bar - bottom_bar)
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
    local top_bar = self.title_bar_height + self.layer_item_height + 4
    local bottom_bar = self.layer_item_height + 4
    local origin_x = WIDTH - layer_window
    local origin_y = HEIGHT - top_bar + self.layer_scroll
    
    clip(origin_x, atlas_window + bottom_bar, layer_window, HEIGHT - atlas_window - top_bar - bottom_bar)
    
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
    
    self:drawLayerStack()
    
    self.btn_layer_create:draw()
    self.btn_layer_delete:draw()
    self.btn_layer_sort_front:draw()
    self.btn_layer_sort_back:draw()
    
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
        and window_height <= self.atlas_texture.height * self.atlas_zoom_y + self.title_bar_height - self.atlas_y
        and height <= .75
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
    
    
    if touch.state == MOVING
    and touch.initX < WIDTH - layer_window
    and touch.initY > atlas_window
    and touch.initY < HEIGHT - self.title_bar_height
    and (self.pan_map_window or touch.duration < .25)
    then
        self.camera_x = self.camera_x + touch.deltaX
        self.camera_y = self.camera_y + touch.deltaY
        self.pan_map_window = true
        self:getVisibleChunkIndexPositions()
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
        self.brush_x, self.brush_y = self:getTileAtlasIndexPosition(touch.x, touch.y)
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
    updateThreadQueue(self.room_action_queue)
    updateThreadQueue(self.room_render_queue)
    
    pushStyle()
    background(self.bg_color)
    noSmooth()
    
    self:centerCameraPivot()
    
    self:drawEntities()
    
    if self.debug then
        self:drawMapWindow()
        self:drawLayerWindow()
        self:drawAtlasWindow()
        
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
        
        
        self.btn_layer_create:touched(touch)
        self.btn_layer_delete:touched(touch)
        self.btn_layer_sort_front:touched(touch)
        self.btn_layer_sort_back:touched(touch)
        
        
        if not self:resizeAtlasWindow(touch) then
            if not self:panMapWindow(touch) then
                if not self:paintTilesOntoMap(touch) then
                    if not self:resizeAtlasBrush(touch) then
                        self:panAtlasWindow(touch)
                        self:moveAtlasBrush(touch)
                    end
                    self:resetCameraPosition(touch)
                    self:minimizeAtlasWindow(touch)
                    self:scrollLayerWindow(touch)
                    self:touchSingleLayer(touch)
                end
            end
        end
        
        
        if touch.state == ENDED then
            sound(world.sfx_mouse_click)
        end
        
    end
end





















-- This is the base class for any object on a layer
-- inherit from this class and extend it to meet your requirements for an entity


WorldEntity = class()



function WorldEntity:init(x, y, sprite_col, sprite_row)
    self.sprite = GSprite{
        texture = world.atlas_texture,
        tilesize = vec2(world.tile_width, world.tile_height),
        spritesize = vec2(world.tile_width, world.tile_height),
        position = vec2(x, y),
        animations = {default = {vec2(sprite_col, sprite_row)}},
        current_animation = "default"
    }
end






function WorldEntity:draw()
    self.sprite:draw()
end







function WorldEntity:touched(touch)
    local shift_x = self.pivot.x * self.spritesize.x
    local shift_y = self.pivot.y * self.spritesize.y
    local rem_x = self.spritesize.x - shift_x
    local rem_y = self.spritesize.y - shift_y
    
    local left = self.position.x - shift_x
    local bottom = self.position.y - shift_y
    local right = self.position.x + rem_x
    local top = self.position.y + rem_y

    local world_touch_x, world_touch_y = self:getWorldPosition(touch.x, touch.y)
    
    
    if world_touch_x > left and world_touch_x < right
    and world_touch_y > bottom and world_touch_y < top
    then
        return true
    end
    
    return false
end


-- Cavemen FP
-- 8-bit roguelike, rpg and adventure level editor and developer tools
-- Version 0.4
-- (c) 2017 kontakt@herrsch.de


displayMode(FULLSCREEN)
supportedOrientations(ANY)







function setup()
    --[[
    local size = math.max(WIDTH, HEIGHT)
    display = mesh()
    display.texture = image(size, size)
    display:addRect(size/2, size/2, size, size)
    ---[[
    display.shader = shader("Documents:scanlines")
    display.shader.size = 1
    display.shader.margin = 3
    display.shader.opacity = .25
    --]]
    
    
    btn_world_debug = UIButton("Edit", 0, 0, 72, 32)
    btn_world_debug.text_color = paint.black
    btn_world_debug.bg_color = paint.blue
    btn_world_debug.text_hover_color = paint.white
    btn_world_debug.bg_hover_color = paint.orange
    
    function btn_world_debug:callback()
        if not self.is_active then
            world:showDeveloperTools()
        else
            world:hideDeveloperTools()
        end
    end
    
    function btn_world_debug:touched(touch) -- override to work as a toggle
        if touch.state == ENDED then
            if self.callback
            and touch.initX > self.x and touch.initX < self.x + self.width
            and touch.initY > self.y and touch.initY < self.y + self.height
            and touch.x > self.x and touch.x < self.x + self.width
            and touch.y > self.y and touch.y < self.y + self.height
            then
                self:callback()
            end
        end
    end

end









function orientationChanged(screen)
end








function draw()
    btn_world_debug.x = WIDTH - btn_world_debug.width
    btn_world_debug.y = HEIGHT - btn_world_debug.height
    btn_world_debug.is_active = world.debug
    btn_world_debug.title = btn_world_debug.is_active and "Exit" or "Edit"
    
    --setContext(display.texture) -- NOTE this cause flickering issues when rendering chunks because inside that method setContext is also used
    
    background(paint.black)
    world:draw()
    btn_world_debug:draw()
    
    --setContext()
    
    --display:draw()
    
    debugger(1, 0)
    
end








function touched(touch)
    btn_world_debug:touched(touch)
    world:touched(touch)
    
end


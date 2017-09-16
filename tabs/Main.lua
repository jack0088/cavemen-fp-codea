-- Cavemen FP
-- 8-bit roguelike, rpg and adventure level editor and developer tools
-- Version 0.4
-- (c) 2017 kontakt@herrsch.de


displayMode(FULLSCREEN)
supportedOrientations(ANY)







function setup()
    parameter.action("DeleteProjectData", function() clearProjectData() end)
    
    
    local size = math.max(WIDTH, HEIGHT)
    display = mesh()
    display.texture = image(size, size)
    display:addRect(size/2, size/2, size, size)
    display.shader = shader("Documents:scanlines")
    display.shader.opacity = .2
    display.shader.margin = 3
    display.shader.size = 1
    
    
    btn_world_debug = UIButton("Edit", 0, 0, 72, 32)
    btn_world_debug.text_color = color(0)
    btn_world_debug.text_hover_color = color(255)
    btn_world_debug.bg_color = color(68, 128, 223)
    
    function btn_world_debug.callback()
        world.debug = not world.debug
    end
    
    function btn_world_debug:touched(touch) -- override to work as a toggle
        if touch.state == ENDED then
            if self.callback
            and touch.initX > self.x and touch.initX < self.x + self.width
            and touch.initY > self.y and touch.initY < self.y + self.height
            and touch.x > self.x and touch.x < self.x + self.width
            and touch.y > self.y and touch.y < self.y + self.height
            then
                self.callback()
            end
            self.is_active = not self.is_active
        end
    end
end









function orientationChanged(screen)
end








function draw()
    btn_world_debug.x = WIDTH - btn_world_debug.width
    btn_world_debug.y = HEIGHT - btn_world_debug.height
    
    setContext(display.texture)
        background(20)
        world:draw()
        btn_world_debug:draw()
        debugger(1, 0)
    setContext()
    
    display:draw()
end








function touched(touch)
    btn_world_debug:touched(touch)
    world:touched(touch)
end


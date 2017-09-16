-- Cavemen FP
-- 8-bit roguelike, rpg and adventure level editor and developer tools
-- Version 0.4
-- (c) 2017 kontakt@herrsch.de





function setup()
    --World:init()
    
    display = mesh()
    display.texture = image(WIDTH, HEIGHT)
    display:addRect(WIDTH/2, HEIGHT/2, WIDTH, HEIGHT)
    display.shader = shader("Documents:scanlines")
    display.shader.opacity = .2
    display.shader.margin = 3
    display.shader.size = 1
    
    parameter.action("DeleteProjectData", function() clearProjectData() end)
    parameter.boolean("Editor", true, function(flag)
        world.debug = flag
        world:centerCameraPivot()
    end)
end






function orientationChanged(screen)
end






function draw()
    setContext(display.texture)
    background(20)
    world:draw()
    debugger(1, 0)
    setContext()
    
    display:draw()
end






function touched(touch)
    world:touched(touch)
end


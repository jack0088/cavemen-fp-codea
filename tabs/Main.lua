-- Cavemen
-- An 8-bit roguelike and developer tools
-- Version 0.3.2
-- (c) kennstewayne.de

function setup()
    World:init()
    Display = mesh()
    Display.texture = image(WIDTH, HEIGHT)
    Display:addRect(WIDTH/2, HEIGHT/2, WIDTH, HEIGHT)
    Display.shader = shader("Documents:scanlines")
    Display.shader.opacity = .25
    Display.shader.margin = 3
    Display.shader.size = 1
    
    parameter.watch("EngineProfile")
    parameter.action("DeleteProjectData", function() clearProjectData() end)
    parameter.integer("Brush", 1, 64, 5)
    parameter.boolean("Editor", true, function(flag)
        World.debug = flag
        World.camera:center()
    end)
end

function orientationChanged(screen)
    World:orientationChanged(screen)
end

function draw()
    setContext(Display.texture)
    background(20)
    World:draw()
    setContext()
    Display:draw()
    
    do EngineProfile = string.format("Frame Rate: %.3fms \nUpdate Frequency: %ifps \nLua Memory: %.0fkb",
        1000 * DeltaTime,
        math.floor(1/DeltaTime),
        collectgarbage("count"))
        collectgarbage()
    end
end

function touched(touch)
    World:touched(touch)
end


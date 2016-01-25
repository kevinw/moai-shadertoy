w, h = 800, 450
MOAISim.openWindow("shadertoy test", w, h)

local viewport = MOAIViewport.new ()
viewport:setSize(w, h)
viewport:setScale(w, h)

local layer = MOAILayer2D.new()
layer:setViewport(viewport)
MOAISim.pushRenderPass(layer)

local shadertoy = require("moai-shadertoy")

local prop = shadertoy.make_prop("shader.vsh", "simple.fsh", w, h)
assert(prop)

layer:insertProp(prop)



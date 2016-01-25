--
-- shadertoy compatibility layer for MOAI
--

function fromShadertoyURL(url)
  -- https://www.shadertoy.com/view/ldS3DW
end

function read_bytes(filename)
  stream = MOAIFileStream.new()
  local ok = stream:open(filename, MOAIFileStream.READ)
  assert(ok, "could not open '#{frag_shader}'")
  return stream:read()
end

assert(0 ~= nil, "FOO")

check = function(val, ...)
  assert(val ~= nil, ...)
  return val
end

-- uniforms provided to every shadertoy
builtin_uniforms = {
  {"iGlobalTime", check(MOAIShaderProgram.UNIFORM_FLOAT, 'float')},
  {"iResolution", check(MOAIShaderProgram.UNIFORM_VECTOR_F4, 'f4')},
  {"iFrame",      check(MOAIShaderProgram.UNIFORM_INT, 'int')},
}

builtin_uniform_index = {}

function make_shader(vert_shader, frag_shader)
  local shader = MOAIShader.new()
  local program = MOAIShaderProgram.new()

  local vsh_bytes = read_bytes(vert_shader)
  local fsh_bytes = read_bytes(frag_shader)

  program:setVertexAttribute(1, 'position')
  program:setVertexAttribute(2, 'uv')
  program:setVertexAttribute(3, 'color')

  program:reserveUniforms(#builtin_uniforms)
  for i, uniform in ipairs(builtin_uniforms) do
    uniform_name, uniform_type = unpack(uniform)
    assert(uniform_type ~= nil, "nil UNIFORM_TYPE " .. tostring(uniform_type))
    builtin_uniform_index[uniform_name] = i
    program:declareUniform(i, uniform_name, uniform_type)
  end

  program:load(vsh_bytes, fsh_bytes)
  shader:setProgram(program)

  return shader, program
end

function set_builtin_uniform(shader, uniform_name, ...)
  i = builtin_uniform_index[uniform_name]
  assert(i ~= nil, "no uniform for " .. uniform_name)
  --print("setting", i, uniform_name, ...)
  return shader:setAttr(i, ...)
end

function make_prop(vert_shader, frag_shader, w, h)
  local prop = MOAIProp2D.new()
  local shader = make_shader(vert_shader, frag_shader)
  prop:setShader(shader)

  local gfxQuad = MOAIGfxQuad2D.new()
  gfxQuad:setRect(-w/2, -h/2, w, h)
  gfxQuad:setUVRect(0, 1, 1, 0)

  prop:setDeck(gfxQuad)


  local pixel_aspect_ratio = 1
  local iResolution = MOAIColor.new()
  iResolution:setColor(w, h, pixel_aspect_ratio, 0)
  --set_builtin_uniform(shader, "iResolution", iResolution)

  local coro = MOAICoroutine.new()
  local start = MOAISim.getDeviceTime()
  local iFrame = 0
  coro:run(function()
    while true do
      local iGlobalTime = MOAISim.getDeviceTime() - start -- in seconds
      set_builtin_uniform(shader, "iGlobalTime", iGlobalTime)
      set_builtin_uniform(shader, "iFrame", iFrame)

      iFrame = iFrame + 1 -- TODO: is this correct? not sure rendering and updates are tied together
      coroutine.yield()
    end
  end)

  return prop
end

return {
  make_prop=make_prop,
}


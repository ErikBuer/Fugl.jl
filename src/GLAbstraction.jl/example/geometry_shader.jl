using GLAbstraction, GeometryTypes, ColorTypes, GLFW, Reactive, ModernGL
const GLA = GLAbstraction

const window = GLFW.Window(name="Example Geometry Shader")
GLFW.MakeContextCurrent(window)
GLA.set_context!(window)

const vert = GLA.vert"""
#version 330
in vec2 pos;
out vec2 g_position;

void main() {
    g_position = pos;
}
"""

const frag = GLA.frag"""
#version 330

out vec4 outColor;

void main() {
    outColor = vec4(1,0,0,1);
}
"""

const geom = GLA.geom"""
#version 330

layout(points) in;
layout(triangle_strip, max_vertices = 4) out;
in vec2 g_position[];

void main(void)
{
  vec2 p0 = g_position[0];   

  gl_Position = vec4(p0, 0, 1);
  EmitVertex();

  gl_Position = vec4(p0+vec2(0,0.1), 0, 1);
  EmitVertex();

  gl_Position = vec4(p0+vec2(0.1,0), 0, 1);
  EmitVertex();

  gl_Position = vec4(p0+vec2(0.1), 0, 1);
  EmitVertex();


  EndPrimitive();
}
"""

const b = Point2f0[(-0.5,0),(0.0, 0.0),(0.4, 0.3)]

program = GLA.Program(vert, geom, frag)
robj = GLA.VertexArray(GLA.generate_buffers(program, GLA.GEOMETRY_DIVISOR, pos=b))

glClearColor(0,0,0,1)

GLA.bind(program)
while !GLFW.WindowShouldClose(window)
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    GLA.bind(robj)
    GLA.draw(robj)
    GLFW.SwapBuffers(window)
    GLFW.PollEvents()
    if GLFW.GetKey(window, GLFW.KEY_ESCAPE) == GLFW.PRESS
        GLFW.SetWindowShouldClose(window, true)
    end
end
GLFW.DestroyWindow(window)

using ModernGL, GLAbstraction, GLFW, GeometryTypes

const GLA = GLAbstraction
const window = GLFW.Window(name="Example")
GLFW.MakeContextCurrent(window)
GLA.set_context!(window)

const vsh = GLA.vert"""
#version 150
in vec2 position;

void main(){
    gl_Position = vec4(position, 0, 1.0);
}
"""

const fsh = GLA.frag"""
#version 150
out vec4 outColor;

void main() {
    outColor = vec4(1.0, 1.0, 1.0, 1.0);
}
"""
prog = GLA.Program(vsh, fsh)
const triangle = GLA.VertexArray(GLA.generate_buffers(prog, GLA.GEOMETRY_DIVISOR, position=Point2f0[(0.0, 0.5), (0.5, -0.5), (-0.5,-0.5)]))

glClearColor(0, 0, 0, 1)
GLA.bind(prog)
while !GLFW.WindowShouldClose(window)
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    GLA.bind(triangle)
    GLA.draw(triangle)
    GLFW.SwapBuffers(window)
    GLFW.PollEvents()
    if GLFW.GetKey(window, GLFW.KEY_ESCAPE) == GLFW.PRESS
        GLFW.SetWindowShouldClose(window, true)
    end
end
GLFW.DestroyWindow(window)

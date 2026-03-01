using ModernGL, GeometryTypes, GLAbstraction, GLWindow

# Create the window. This sets all the hints and makes the context current.
window = create_glcontext("Drawing polygons exercise 2", resolution=(800,600))

# A slightly-simplified VAO generator call
vao = glGenVertexArrays()
glBindVertexArray(vao)

# The positions of the vertices in our rectangle
vertex_positions = Point{2,Float32}[(-0.5, -0.5),     # bottom-left
                                    ( 0.5, -0.5),     # bottom-right
                                    ( 0.0,  0.5)]     # top-center

# The colors assigned to each vertex (but we'll invert them)
vertex_colors = Vec3f0[(1, 0, 0),                     # bottom-left
                       (0, 1, 0),                     # bottom-right
                       (0, 0, 1)]                     # top-center

# The vertex shader---note the `vert` in front of """
vertex_shader = vert"""
#version 150

in vec2 position;
in vec3 color;

out vec3 Color;

void main()
{
    Color = color;
    gl_Position = vec4(position, 0.0, 1.0);
}
"""

# The fragment shader
fragment_shader = frag"""
# version 150

in vec3 Color;

out vec4 outColor;

void main()
{
    outColor = vec4(1.0-Color.r, 1.0-Color.g, 1.0-Color.b, 1.0);
}
"""

# Link everything together, using the corresponding shader variable as
# the Dict key
bufferdict = Dict(:position=>Buffer(vertex_positions),
                  :color=>Buffer(vertex_colors))

ro = std_renderobject(bufferdict,
                      LazyShader(vertex_shader, fragment_shader))

# Draw until we receive a close event
glClearColor(0,0,0,0)
while !GLFW.WindowShouldClose(window)
    glClear(GL_COLOR_BUFFER_BIT)
    GLAbstraction.render(ro)
    GLFW.SwapBuffers(window)
    GLFW.PollEvents()
    if GLFW.GetKey(window, GLFW.KEY_ESCAPE) == GLFW.PRESS
        GLFW.SetWindowShouldClose(window, true)
    end
end

GLFW.DestroyWindow(window)  # needed if you're running this from the REPL

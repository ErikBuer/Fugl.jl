using ModernGL, GeometryTypes, GLAbstraction, GLWindow, Images

# Load our texture. See "downloads.jl" to get the images.
img = load(GLAbstraction.dir("tutorials", "images", "kitten.png"))

# Create the window. This sets all the hints and makes the context current.
window = create_glcontext("Textures exercise 2", resolution=(800,600))

vao = glGenVertexArrays()
glBindVertexArray(vao)

# The positions of the vertices in our rectangles
# This is a two-rectangle solution; alternatively, one could modify
# the fragment shader to compute the reflection.
vertex_positions = Point{2,Float32}[(-0.5,  0.5),     # top-left
                                    ( 0.5,  0.5),     # top-right
                                    ( 0.5,  0.0),     # middle-right
                                    (-0.5,  0.0),     # middle-left
                                    ( 0.5, -0.5),     # bottom-right
                                    (-0.5, -0.5)]     # bottom-left
# Duplicate the middle ones
vertex_positions = vertex_positions[[1:4;4;3;5:6]]

# The texture coordinates of each vertex
vertex_texcoords = Vec2f0[(0, 0),
                          (1, 0),
                          (1, 1),
                          (0, 1)]
vertex_texcoords = vertex_texcoords[[1:4;4;3;2;1]]

# Specify how vertices are arranged into faces
elements = Face{3,UInt32,-1}[(0,1,2),
                             (2,3,0),
                             (4,5,6),
                             (6,7,4)]

# The vertex shader---note the `vert` in front of """
vertex_shader = vert"""
#version 150

in vec2 position;
in vec2 texcoord;

out vec2 Texcoord;

void main()
{
    Texcoord = texcoord;
    gl_Position = vec4(position, 0.0, 1.0);
}
"""

# The fragment shader
fragment_shader = frag"""
# version 150

in vec2 Texcoord;

out vec4 outColor;

uniform sampler2D tex;

void main()
{
    outColor = texture(tex, Texcoord);
}
"""

# Link everything together, using the corresponding shader variable as
# the Dict key
bufferdict = Dict(:position=>Buffer(vertex_positions),
                  :texcoord=>Buffer(vertex_texcoords),
                  :tex=>Texture(data(img)),
                  :indexes=>indexbuffer(elements)) # special for element buffers

ro = std_renderobject(bufferdict,
                      LazyShader(vertex_shader, fragment_shader))

# Draw until we receive a close event
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

using ModernGL, GeometryTypes, GLAbstraction, GLWindow, Images

# Load our texture. See "downloads.jl" to get the images.
img = load(GLAbstraction.dir("tutorials", "images", "kitten.png"))

# Create the window. This sets all the hints and makes the context current.
window = create_glcontext("Textures exercise 3", resolution=(800,600))

vao = glGenVertexArrays()
glBindVertexArray(vao)

# The positions of the vertices in our rectangle
vertex_positions = Point{2,Float32}[(-0.5,  0.5),     # top-left
                                    ( 0.5,  0.5),     # top-right
                                    ( 0.5, -0.5),     # bottom-right
                                    (-0.5, -0.5)]     # bottom-left

# The texture coordinates of each vertex
vertex_texcoords = Vec2f0[(0, 0),
                          (1, 0),
                          (1, 1),
                          (0, 1)]

# Specify how vertices are arranged into faces
# Face{N,T,O} type specifies a face with N vertices, with index type
# T (you should choose UInt32), and index-offset O. If you're
# specifying faces in terms of julia's 1-based indexing, you should set
# O=0. (If you instead number the vertices starting with 0, set
# O=-1.)
elements = Face{3,UInt32,-1}[(0,1,2),          # the first triangle
                             (2,3,0)]          # the second triangle

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
uniform float yperiod;
uniform float phase;
uniform float amplitude;

void main()
{
    if (Texcoord.y > 0.5)
        outColor = texture(tex, vec2(Texcoord.x+amplitude*sin(Texcoord.y/yperiod + phase), Texcoord.y));
    else
        outColor = texture(tex, Texcoord);
}
"""

# Link everything together, using the corresponding shader variable as
# the Dict key
bufferdict = Dict(:position=>Buffer(vertex_positions),
                  :texcoord=>Buffer(vertex_texcoords),
                  :tex=>Texture(data(img), x_repeat=:repeat),
                  :indexes=>indexbuffer(elements)) # special for element buffers

ro = std_renderobject(bufferdict,
                      LazyShader(vertex_shader, fragment_shader))

prog = ro.vertexarray.program
yperiod_loc = glGetUniformLocation(prog.GLid, "yperiod")
phase_loc = glGetUniformLocation(prog.GLid, "phase")
amplitude_loc = glGetUniformLocation(prog.GLid, "amplitude")

# Draw until we receive a close event
while !GLFW.WindowShouldClose(window)
    glClear(GL_COLOR_BUFFER_BIT)
    amp = mod(time(), 2)/5
    phase = 2pi*mod(time(), 1)
    glUniform1f(amplitude_loc, Float32(amp))
    glUniform1f(phase_loc, Float32(phase))
    glUniform1f(yperiod_loc, Float32(0.02))

    GLAbstraction.render(ro)
    GLFW.SwapBuffers(window)
    GLFW.PollEvents()
    if GLFW.GetKey(window, GLFW.KEY_ESCAPE) == GLFW.PRESS
        GLFW.SetWindowShouldClose(window, true)
    end
end

GLFW.DestroyWindow(window)  # needed if you're running this from the REPL

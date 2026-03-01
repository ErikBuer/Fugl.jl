using ModernGL, GeometryTypes, GLAbstraction, GLFW, Images
const GLA = GLAbstraction

# Load our texture. See "downloads.jl" to get the images.
kitten = load(GLAbstraction.dir("tutorials", "images", "kitten.png"))
puppy  = load(GLAbstraction.dir("tutorials", "images", "puppy.png"))

# Create the window. This sets all the hints and makes the context current.
window = GLFW.Window(name="Textures 1", resolution=(800,600))
GLFW.MakeContextCurrent(window)
GLA.set_context!(window)

# The positions of the vertices in our rectangle
vertex_positions = Point{2,Float32}[(-0.5,  0.5),     # top-left
                                    ( 0.5,  0.5),     # top-right
                                    ( 0.5, -0.5),     # bottom-right
                                    (-0.5, -0.5)]     # bottom-left

# The colors assigned to each vertex
vertex_colors = Vec3f0[(1, 0, 0),                     # top-left
                       (0, 1, 0),                     # top-right
                       (0, 0, 1),                     # bottom-right
                       (1, 1, 1)]                     # bottom-left

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
elements = Face{3,UInt32}[(0,1,2),          # the first triangle
                          (2,3,0)]          # the second triangle

# The vertex shader---note the `vert` in front of """
vertex_shader = GLA.vert"""
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
fragment_shader = GLA.frag"""
# version 150

in vec3 Color;
in vec2 Texcoord;

out vec4 outColor;

uniform sampler2D texKitten;
uniform sampler2D texPuppy;

void main()
{
    vec4 colKitten = texture(texKitten, Texcoord);
    vec4 colPuppy  = texture(texPuppy,  Texcoord);
    outColor = mix(colKitten, colPuppy, 0.5);
}
"""
prog = GLA.Program(vertex_shader, fragment_shader)

buffers = GLA.generate_buffers(prog, GLA.GEOMETRY_DIVISOR, position = vertex_positions,
                                                           color = vertex_colors,
                                                           texcoord=vertex_texcoords)

vao  = GLA.VertexArray(buffers, elements)
tex_kitten = GLA.Texture(collect(kitten'))
tex_puppy  = GLA.Texture(collect(puppy'))
# Draw until we receive a close event
while !GLFW.WindowShouldClose(window)
    glClear(GL_COLOR_BUFFER_BIT)
    GLA.bind(prog)
    GLA.gluniform(prog, :texKitten, 0, tex_kitten) #first texture sampler
    GLA.gluniform(prog, :texPuppy, 1, tex_puppy) # second texture sampler
    GLA.bind(vao)
    GLA.draw(vao) 
    GLFW.SwapBuffers(window)
    GLFW.PollEvents()
    if GLFW.GetKey(window, GLFW.KEY_ESCAPE) == GLFW.PRESS
        GLFW.SetWindowShouldClose(window, true)
    end
end

GLFW.DestroyWindow(window)  # needed if you're running this from the REPL

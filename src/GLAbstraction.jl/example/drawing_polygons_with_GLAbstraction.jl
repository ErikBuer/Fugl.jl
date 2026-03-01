# Here, we illustrate a "julian" implementation that leverages
# some of the advantages of GLAbstraction over basic ModernGL usage

using ModernGL, ColorTypes, GeometryTypes, GLAbstraction, GLFW

const GLA = GLAbstraction

# Create the window. This sets all the hints and makes the context current.
window = GLFW.Window(name="Drawing polygons 5", resolution=(800,600))

# We assign the created window as the "current" context in GLAbstraction to which all GL objects are "bound", this is to avoid using GL objects in the wrong context, but actually currently no real checks are made except initially that at least there is a context initialized.
# Think of this as a way of bookkeeping.
GLFW.MakeContextCurrent(window)
GLA.set_context!(window)
GLA.FrameBuffer((1024,1024),(RGBA{Float32}, RGBA{Float32}, GLA.Depth{Float32}), true)  
# The vertex shader---note the `vert` in front of """
vertex_shader = GLA.vert"""
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
fragment_shader = GLA.frag"""
# version 150

in vec3 Color;

out vec4 outColor;

void main()
{
    outColor = vec4(Color, 1.0);
}
"""

# First we combine these two shaders into the program that will be used to render
prog = GLA.Program(vertex_shader, fragment_shader)

# Some geometry to render
# First a triangle
triangle_positions = Point{2,Float32}[(-0.5, -0.5),
                                      (0.5, -0.5),
                                      (0.0, 0.5)]
triangle_colors = Vec3f0[(1, 0, 0),                     # top-left
                         (0, 1, 0),                     # top-right
                         (0, 0, 1)]                     # bottom-right

# This one we will render in a simple way, i.e. not using an index buffer
# This geometry now has to be uploaded into OpenGL Buffers and attached to the correct points in a VertexArray, to be used in the above program. 
# We first generate the Buffers and their BufferAttachmentInfos, for each of the buffers, from the corresponding names and data 
# The GEOMETRY_DIVISOR distinguishes that this is geometry data and not possible uniform data used in instanced vertexarrays
buffers = GLA.generate_buffers(prog, GLA.GEOMETRY_DIVISOR, position = triangle_positions, color = triangle_colors)
triangle_vao = GLA.VertexArray(buffers)
glClearColor(0,0,0,0)
while !GLFW.WindowShouldClose(window)
    glClear(GL_COLOR_BUFFER_BIT)
    GLA.bind(prog)
    GLA.bind(triangle_vao)
    GLA.draw(triangle_vao)
    GLA.unbind(triangle_vao) #optional in this case
    GLA.unbind(prog) #optional in this case
    GLFW.SwapBuffers(window)
    GLFW.PollEvents()
    if GLFW.GetKey(window, GLFW.KEY_ESCAPE) == GLFW.PRESS
        GLFW.SetWindowShouldClose(window, true)
    end
end
GLFW.SetWindowShouldClose(window, false)

# Now we define another geometry that we will render, a rectangle, this one with an index buffer
# The positions of the vertices in our rectangle
rectangle_positions = Point{2,Float32}[(-0.5,  0.5),     # top-left
                                       ( 0.5,  0.5),     # top-right
                                       ( 0.5, -0.5),     # bottom-right
                                       (-0.5, -0.5)]     # bottom-left

# The colors assigned to each vertex
rectangle_colors = Vec3f0[(1, 0, 0),                     # top-left
                          (0, 1, 0),                     # top-right
                          (0, 0, 1),                     # bottom-right
                          (1, 1, 1)]                     # bottom-left

# Specify how vertices are arranged into faces
# Face{N,T} type specifies a face with N vertices, with index type
# T (you should choose UInt32), and index-offset O. If you're
# specifying faces in terms of julia's 1-based indexing, you should set
# O=0. (If you instead number the vertices starting with 0, set
# O=-1.)
elements = Face{3,UInt32}[(0,1,2),          # the first triangle
                          (2,3,0)]          # the second triangle


buffers = GLA.generate_buffers(prog, GLA.GEOMETRY_DIVISOR, position = rectangle_positions, color = rectangle_colors)

# Now we create a VertexArray from these buffers and use the elements as the indices
rectangle_vao = GLA.VertexArray(buffers, elements)

# Draw the rectangle until we receive a close event
glClearColor(0,0,0,0)
while !GLFW.WindowShouldClose(window)
    glClear(GL_COLOR_BUFFER_BIT)
    GLA.bind(prog)
    GLA.bind(rectangle_vao)
    GLA.draw(rectangle_vao)
    GLA.unbind(rectangle_vao) #optional in this case
    GLA.unbind(prog) #optional in this case
    GLFW.SwapBuffers(window)
    GLFW.PollEvents()
    if GLFW.GetKey(window, GLFW.KEY_ESCAPE) == GLFW.PRESS
        GLFW.SetWindowShouldClose(window, true)
    end
end
GLFW.SetWindowShouldClose(window, false)


GLFW.DestroyWindow(window)  # needed if you're running this from the REPL

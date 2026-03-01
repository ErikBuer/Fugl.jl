# Here, we illustrate a pure ModernGL implementation of some polygon drawing
using ModernGL, GeometryTypes, GLFW

# Create the window. This sets all the hints and makes the context current.
window = GLFW.Window(name="Drawing polygons 5", resolution=(800,600))

# The shaders. Here we do everything manually, but life will get
# easier with GLAbstraction. See drawing_polygons5.jl for such an
# implementation.

# The vertex shader
vertex_source = Vector{UInt8}("""
#version 150

in vec2 position;
in vec3 color;

out vec3 Color;

void main()
{
    Color = color;
    gl_Position = vec4(position, 0.0, 1.0);
}
""")

# The fragment shader
fragment_source = Vector{UInt8}("""
# version 150

in vec3 Color;

out vec4 outColor;

void main()
{
    outColor = vec4(Color, 1.0);
}
""")

# Compile the vertex shader
vertex_shader = glCreateShader(GL_VERTEX_SHADER)
glShaderSource(vertex_shader, 1, Ptr{UInt8}[pointer(vertex_source)], Ref{GLint}(length(vertex_source)))  # nicer thanks to GLAbstraction
glCompileShader(vertex_shader)
# Check that it compiled correctly
status = Ref(GLint(0))
glGetShaderiv(vertex_shader, GL_COMPILE_STATUS, status)
if status[] != GL_TRUE
    buffer = Array(UInt8, 512)
    glGetShaderInfoLog(vertex_shader, 512, C_NULL, buffer)
    @error "$(unsafe_string(pointer(buffer), 512))"
end

# Compile the fragment shader
fragment_shader = glCreateShader(GL_FRAGMENT_SHADER)
glShaderSource(fragment_shader, 1, Ptr{UInt8}[pointer(fragment_source)], Ref{GLint}(length(fragment_source)))  # nicer thanks to GLAbstraction
glCompileShader(fragment_shader)
# Check that it compiled correctly
status = Ref(GLint(0))
glGetShaderiv(fragment_shader, GL_COMPILE_STATUS, status)
if status[] != GL_TRUE
    buffer = Array(UInt8, 512)
    glGetShaderInfoLog(fragment_shader, 512, C_NULL, buffer)
    @error "$(unsafe_string(pointer(buffer), 512))"
end

# Connect the shaders by combining them into a program
shader_program = glCreateProgram()
glAttachShader(shader_program, vertex_shader)
glAttachShader(shader_program, fragment_shader)
glBindFragDataLocation(shader_program, 0, "outColor") # optional

glLinkProgram(shader_program)
glUseProgram(shader_program)


# The vertices of our triangle, with color
positions = Point{2,Float32}[(0,    0.5),   # red vertex
                            ( 0.5, -0.5),   # green vertex
                            (-0.5, -0.5)]   # blue vertex
                            
colors = Vec3f0[(1, 0, 0),                     # top-left
                (0, 1, 0),                     # top-right
                (0, 0, 1)]

vao = Ref(GLuint(0))
glGenVertexArrays(1, vao)
glBindVertexArray(vao[])

# Create the Vertex Buffer Objects (VBO)
vbo = Ref(GLuint(0))   # initial value is irrelevant, just allocate space
glGenBuffers(1, vbo)
glBindBuffer(GL_ARRAY_BUFFER, vbo[])
glBufferData(GL_ARRAY_BUFFER, sizeof(positions), positions, GL_STATIC_DRAW)
# Link vertex data to attributes
pos_attribute = glGetAttribLocation(shader_program, "position")
glEnableVertexAttribArray(pos_attribute)
glVertexAttribPointer(pos_attribute, 2,
                      GL_FLOAT, GL_FALSE, 0, C_NULL)

# Color VBO
vbo1 = Ref(GLuint(0))
glGenBuffers(1, vbo1)
glBindBuffer(GL_ARRAY_BUFFER, vbo1[])
glBufferData(GL_ARRAY_BUFFER, sizeof(colors), colors, GL_STATIC_DRAW)

# Link color data to attributes
col_attribute = glGetAttribLocation(shader_program, "color")
glBindBuffer(GL_ARRAY_BUFFER, vbo1[])
glEnableVertexAttribArray(col_attribute)
glVertexAttribPointer(col_attribute, 3,
                      GL_FLOAT, GL_FALSE, 0, C_NULL)

# Draw while waiting for a close event
glClearColor(0,0,0,0)
while !GLFW.WindowShouldClose(window)
    glClear(GL_COLOR_BUFFER_BIT)
    glDrawArrays(GL_TRIANGLES, 0, length(positions))
    GLFW.SwapBuffers(window)
    GLFW.PollEvents()
    if GLFW.GetKey(window, GLFW.KEY_ESCAPE) == GLFW.PRESS
        GLFW.SetWindowShouldClose(window, true)
    end
end
GLFW.SetWindowShouldClose(window, false)

# Now we define another geometry that we will render, a rectangle, this one with an index buffer
# The positions of the vertices in our rectangle
positions = Point{2,Float32}[(-0.5,  0.5),     # top-left
                             ( 0.5,  0.5),     # top-right
                             ( 0.5, -0.5),     # bottom-right
                             (-0.5, -0.5)]     # bottom-left

# The colors assigned to each vertex
colors = Vec3f0[(1, 0, 0),                     # top-left
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

vao = Ref(GLuint(0))
glGenVertexArrays(1, vao)
glBindVertexArray(vao[])

# Create the Vertex Buffer Objects (VBO)
vbo = Ref(GLuint(0))   # initial value is irrelevant, just allocate space
glGenBuffers(1, vbo)
glBindBuffer(GL_ARRAY_BUFFER, vbo[])
glBufferData(GL_ARRAY_BUFFER, sizeof(positions), positions, GL_STATIC_DRAW)
# Link vertex data to attributes
pos_attribute = glGetAttribLocation(shader_program, "position")
glEnableVertexAttribArray(pos_attribute)
glVertexAttribPointer(pos_attribute, 2,
                      GL_FLOAT, GL_FALSE, 0, C_NULL)

# Color VBO
vbo1 = Ref(GLuint(0))
glGenBuffers(1, vbo1)
glBindBuffer(GL_ARRAY_BUFFER, vbo1[])
glBufferData(GL_ARRAY_BUFFER, sizeof(colors), colors, GL_STATIC_DRAW)

# Link color data to attributes
col_attribute = glGetAttribLocation(shader_program, "color")
glBindBuffer(GL_ARRAY_BUFFER, vbo1[])
glEnableVertexAttribArray(col_attribute)
glVertexAttribPointer(col_attribute, 3,
                      GL_FLOAT, GL_FALSE, 0, C_NULL)

# Create the Element Buffer Object (EBO)
ebo = Ref(GLuint(0))
glGenBuffers(1, ebo)
glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo[])
glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(elements), elements, GL_STATIC_DRAW)

# Draw while waiting for a close event
glClearColor(0,0,0,0)
while !GLFW.WindowShouldClose(window)
    glClear(GL_COLOR_BUFFER_BIT)
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, C_NULL)
    GLFW.SwapBuffers(window)
    GLFW.PollEvents()
    if GLFW.GetKey(window, GLFW.KEY_ESCAPE) == GLFW.PRESS
        GLFW.SetWindowShouldClose(window, true)
    end
end

GLFW.DestroyWindow(window)  # needed if you're running this from the REPL

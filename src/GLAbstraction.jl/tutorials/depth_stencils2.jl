using ModernGL, GeometryTypes, GLAbstraction, GLFW, Images, FileIO, Reactive, LinearAlgebra

const GLA = GLAbstraction

kitten = load(GLAbstraction.dir("tutorials", "images", "kitten.png"))
puppy  = load(GLAbstraction.dir("tutorials", "images", "puppy.png"))

# Create the window. This sets all the hints and makes the context current.
window = GLFW.Window(name="Depth and Stencils 1", resolution=(800,600),
                     windowhints=[(GLFW.DEPTH_BITS,32), (GLFW.STENCIL_BITS, 8)])
                     
GLFW.MakeContextCurrent(window)
GLA.set_context!(window)

# The cube. This could be more efficiently represented using indexes,
# but the tutorial doesn't do it that way.
vertex_positions = Vec3f0[
    # The cube
    (-0.5f0, -0.5f0, -0.5f0),
    ( 0.5f0, -0.5f0, -0.5f0),
    ( 0.5f0,  0.5f0, -0.5f0),
    ( 0.5f0,  0.5f0, -0.5f0),
    (-0.5f0,  0.5f0, -0.5f0),
    (-0.5f0, -0.5f0, -0.5f0),

    (-0.5f0, -0.5f0,  0.5f0),
    ( 0.5f0, -0.5f0,  0.5f0),
    ( 0.5f0,  0.5f0,  0.5f0),
    ( 0.5f0,  0.5f0,  0.5f0),
    (-0.5f0,  0.5f0,  0.5f0),
    (-0.5f0, -0.5f0,  0.5f0),

    (-0.5f0,  0.5f0,  0.5f0),
    (-0.5f0,  0.5f0, -0.5f0),
    (-0.5f0, -0.5f0, -0.5f0),
    (-0.5f0, -0.5f0, -0.5f0),
    (-0.5f0, -0.5f0,  0.5f0),
    (-0.5f0,  0.5f0,  0.5f0),

    ( 0.5f0,  0.5f0,  0.5f0),
    ( 0.5f0,  0.5f0, -0.5f0),
    ( 0.5f0, -0.5f0, -0.5f0),
    ( 0.5f0, -0.5f0, -0.5f0),
    ( 0.5f0, -0.5f0,  0.5f0),
    ( 0.5f0,  0.5f0,  0.5f0),

    (-0.5f0, -0.5f0, -0.5f0),
    ( 0.5f0, -0.5f0, -0.5f0),
    ( 0.5f0, -0.5f0,  0.5f0),
    ( 0.5f0, -0.5f0,  0.5f0),
    (-0.5f0, -0.5f0,  0.5f0),
    (-0.5f0, -0.5f0, -0.5f0),

    (-0.5f0,  0.5f0, -0.5f0),
    ( 0.5f0,  0.5f0, -0.5f0),
    ( 0.5f0,  0.5f0,  0.5f0),
    ( 0.5f0,  0.5f0,  0.5f0),
    (-0.5f0,  0.5f0,  0.5f0),
    (-0.5f0,  0.5f0, -0.5f0)]

floor_positions = Vec3f0[
    # The floor
    (-1.0f0, -1.0f0, -0.5f0),
    ( 1.0f0, -1.0f0, -0.5f0),
    ( 1.0f0,  1.0f0, -0.5f0),
    ( 1.0f0,  1.0f0, -0.5f0),
    (-1.0f0,  1.0f0, -0.5f0),
    (-1.0f0, -1.0f0, -0.5f0)
]

vertex_texcoords = Vec2f0[
                          # The cube
                          (0.0f0, 0.0f0),
                          (1.0f0, 0.0f0),
                          (1.0f0, 1.0f0),
                          (1.0f0, 1.0f0),
                          (0.0f0, 1.0f0),
                          (0.0f0, 0.0f0),

                          (0.0f0, 0.0f0),
                          (1.0f0, 0.0f0),
                          (1.0f0, 1.0f0),
                          (1.0f0, 1.0f0),
                          (0.0f0, 1.0f0),
                          (0.0f0, 0.0f0),

                          (1.0f0, 0.0f0),
                          (1.0f0, 1.0f0),
                          (0.0f0, 1.0f0),
                          (0.0f0, 1.0f0),
                          (0.0f0, 0.0f0),
                          (1.0f0, 0.0f0),

                          (1.0f0, 0.0f0),
                          (1.0f0, 1.0f0),
                          (0.0f0, 1.0f0),
                          (0.0f0, 1.0f0),
                          (0.0f0, 0.0f0),
                          (1.0f0, 0.0f0),

                          (0.0f0, 1.0f0),
                          (1.0f0, 1.0f0),
                          (1.0f0, 0.0f0),
                          (1.0f0, 0.0f0),
                          (0.0f0, 0.0f0),
                          (0.0f0, 1.0f0),

                          (0.0f0, 1.0f0),
                          (1.0f0, 1.0f0),
                          (1.0f0, 0.0f0),
                          (1.0f0, 0.0f0),
                          (0.0f0, 0.0f0),
                          (0.0f0, 1.0f0)]

floor_texcoords = Vec2f0[
                          # The floor
                          (0.0f0, 0.0f0),
                          (1.0f0, 0.0f0),
                          (1.0f0, 1.0f0),
                          (1.0f0, 1.0f0),
                          (0.0f0, 1.0f0),
                          (0.0f0, 0.0f0)]

vertex_colors = fill(Vec3{Float32}(1,1,1), 36)
floor_colors = fill(Vec3{Float32}(0,0,0),6)

vertex_shader = GLA.vert"""
#version 150

in vec3 position;
in vec3 color;
in vec2 texcoord;

out vec3 Color;
out vec2 Texcoord;

uniform vec3 overrideColor;
uniform mat4 model;
uniform mat4 view;
uniform mat4 proj;

void main()
{
    Color = overrideColor * color;
    Texcoord = texcoord;
    gl_Position = proj * view * model * vec4(position, 1.0);
}
"""
fragment_shader = load(joinpath(dirname(@__FILE__), "shaders", "puppykitten_color.frag"))
fragment_shader = load(joinpath("tutorials", "shaders", "puppykitten_color.frag"))
prog = GLA.Program(GLA.Shader(vertex_shader), fragment_shader)


model1 = Mat4(diagm(0=>ones(Float32, 4)))
model2 = Mat4{Float32}(
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, -1, 0,
        0,0,-1,1.0f0
    )

function lookat(eyePos, lookAt, up)
    z  = normalize(eyePos-lookAt)
    x  = normalize(cross(up, z))
    y  = normalize(cross(z, x))
    T0 = 0.0f0
    return Mat4{Float32}(
        x[1], y[1], z[1], T0,
        x[2], y[2], z[2], T0,
        x[3], y[3], z[3], T0,
        -dot(x,eyePos),-dot(y,eyePos),-dot(z,eyePos),1.0f0
    )
end

function perspectiveprojection(fovy, aspect, znear::T, zfar::T) where T
    h = T(tan(deg2rad(fovy)) * znear)
    w = T(h * aspect)
    bottom = -h
    top = h
    left = -w
    right = w
       
    (right == left || bottom == top || znear == zfar) && return Mat4{T}(I)
    T0, T1, T2 = zero(T), one(T), T(2)
    return Mat4{T}(
        T2 * znear / (right - left), T0, T0, T0,
        T0, T2 * znear / (top - bottom), T0, T0,
        (right + left) / (right - left), (top + bottom) / (top - bottom), -(zfar + znear) / (zfar - znear), -T1,
        T0, T0, -(T2 * znear * zfar) / (zfar - znear), T0
    )
end

view = lookat(Vec3((2.5, 2.5, 2)), Vec3((0, 0, 0)), Vec3((0, 0, 1)))
proj = perspectiveprojection(45f0, 600f0/600f0, 1f0, 10f0)

tex_kitten = GLA.Texture(collect(kitten'))
tex_puppy  = GLA.Texture(collect(puppy'))

## Now render the distinct objects. Rather than always using std_renderobject,
## here we control the settings manually.
# The cube
buffers_cube = GLA.generate_buffers(prog, GLA.GEOMETRY_DIVISOR, position = vertex_positions,
                                                           color = vertex_colors,
                                                           texcoord=vertex_texcoords)

vao_cube = GLA.VertexArray(buffers_cube)
# The floor. This is drawn without writing to the depth buffer, but we
# write stencil values.
buffers_floor = GLA.generate_buffers(prog, GLA.GEOMETRY_DIVISOR, position = floor_positions,
                                                           color = floor_colors,
                                                           texcoord=floor_texcoords)
vao_floor = GLA.VertexArray(buffers_floor)

glEnable(GL_DEPTH_TEST)
glDepthFunc(GL_LEQUAL)
glClearColor(1,1,1,1) # make the background white, so we can see the floor
glClearStencil(0)     # clear the stencil buffer with 0

while !GLFW.WindowShouldClose(window)
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    GLA.bind(prog)
    
    GLA.gluniform(prog, :texKitten, 0, tex_kitten) #first texture sampler
    GLA.gluniform(prog, :texPuppy, 1, tex_puppy) # second texture sampler

    # Render Cube
    GLA.gluniform(prog, :model, model1)
    GLA.gluniform(prog, :view, view) 
    GLA.gluniform(prog, :proj, proj)
    GLA.gluniform(prog, :overrideColor, Vec3{Float32}((1,1,1)))
    
    glDisable(GL_STENCIL_TEST)
    GLA.bind(vao_cube)
    GLA.draw(vao_cube)

    # Render Floor
    GLA.gluniform(prog, :model, model1)
    glDepthMask(GL_FALSE)                  # don't write to depth buffer
    glEnable(GL_STENCIL_TEST)              # use stencils
    glStencilMask(0xff)                    # do write to stencil buffer
    glStencilFunc(GL_ALWAYS, 1, 0xff)      # all pass
    glStencilOp(GL_KEEP, GL_KEEP, GL_REPLACE)  # replace stencil value
    glClear(GL_STENCIL_BUFFER_BIT)         # start with empty buffer
    GLA.bind(vao_floor)
    GLA.draw(vao_floor)
    
    # Render reflection
    GLA.gluniform(prog, :model, model2)
    GLA.gluniform(prog, :overrideColor, Vec3{Float32}((0.3,0.3,0.3)))

    glStencilFunc(GL_EQUAL, 1, 0xff)
    glStencilMask(0x00)
    
    GLA.bind(vao_cube)
    GLA.draw(vao_cube)

    GLFW.SwapBuffers(window)
    GLFW.PollEvents()
    if GLFW.GetKey(window, GLFW.KEY_ESCAPE) == GLFW.PRESS
        GLFW.SetWindowShouldClose(window, true)
    end
end
GLFW.DestroyWindow(window)  # needed if you're running this from the REPL

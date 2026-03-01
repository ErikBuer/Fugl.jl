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
    (-0.5f0,  0.5f0, -0.5f0),
]

vertex_texcoords = Vec2f0[
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

vertex_colors = fill(Vec3{Float32}(1,1,1), 36)

vertex_shader = GLA.vert"""
#version 150

in vec3 position;
in vec3 color;
in vec2 texcoord;

out vec3 Color;
out vec2 Texcoord;

uniform mat4 model;
uniform mat4 view;
uniform mat4 proj;

void main()
{
    Color = color;
    Texcoord = texcoord;
    gl_Position = proj * view * model * vec4(position, 1.0);
}
"""
fragment_shader = load(joinpath(dirname(@__FILE__), "shaders", "puppykitten_color.frag"))

prog = GLA.Program(GLA.Shader(vertex_shader), fragment_shader)

buffers = GLA.generate_buffers(prog, GLA.GEOMETRY_DIVISOR, position = vertex_positions,
                                                           color = vertex_colors,
                                                           texcoord=vertex_texcoords)

vao  = GLA.VertexArray(buffers, GL_TRIANGLES)

# Define the rotation matrix (could also use rotationmatrix_z)
function rotmat_z(angle::T) where T
    T0, T1 = zero(T), one(T)
    Mat{4}(
        cos(angle), sin(angle), T0, T0,
        -sin(angle), cos(angle),  T0, T0,
        T0, T0, T1, T0,
        T0, T0, T0, T1
    )
end

# By wrapping it in a Signal, we can easily update it.
trans = Signal(rotmat_z(0f0))

# Now we define the lookat and perspective projections
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


model = Signal(rotmat_z(0f0))
view = lookat(Vec3((1.2, 1.2, 1.2)), Vec3((0, 0, 0)), Vec3((0, 0, 1)))
proj = perspectiveprojection(45f0, 800f0/600f0, 1f0, 10f0)

tex_kitten = GLA.Texture(collect(kitten'))
tex_puppy  = GLA.Texture(collect(puppy'))

# Enable the depth testing
glEnable(GL_DEPTH_TEST)
glDepthFunc(GL_LEQUAL)

glClearColor(0,0,0,1)
while !GLFW.WindowShouldClose(window)
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    push!(model, rotmat_z(time()*deg2rad(180)))
    Reactive.run_till_now()
    GLA.bind(prog)
    GLA.gluniform(prog, :texKitten, 0, tex_kitten) #first texture sampler
    GLA.gluniform(prog, :texPuppy, 1, tex_puppy) # second texture sampler
    GLA.gluniform(prog, :model, value(model))
    GLA.gluniform(prog, :view, view) 
    GLA.gluniform(prog, :proj, proj) 
    GLA.bind(vao)
    GLA.draw(vao) 
    GLFW.SwapBuffers(window)
    GLFW.PollEvents()
    if GLFW.GetKey(window, GLFW.KEY_ESCAPE) == GLFW.PRESS
        GLFW.SetWindowShouldClose(window, true)
    end
end

GLFW.DestroyWindow(window)  # needed if you're running this from the REPL

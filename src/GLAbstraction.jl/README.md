# GLAbstraction
A simple library, which makes the use of OpenGL a little bit more convenient and Julian.
If you have any questions, please open an issue.

There are some [tutorials](tutorials/README.md) and [examples](https://github.com/JuliaGL/GLAbstraction.jl/tree/master/example).

### Features

* All the different glUniform functions are wrapped and the right function is determined via multiple dispatch (works for [FixedSizeArrays](https://github.com/SimonDanisch/FixedSizeArrays.jl), [Colors](https://github.com/JuliaGraphics/Colors.jl) and Real numbers)
* `Buffers` and `Texture` objects are wrapped, with best support for arrays of FixedSizeArrays, Colors and Reals.
* An Array interface for `Buffers` and `Textures`, offering functions like `push!`, `getindex`, `setindex!`, etc for GPU arrays, just like you're used to from Julia Arrays.
* Shader loading is simplified and offers templated shaders and interactive editing of shaders and type/error checks.
* Some wrappers for often used functions, with embedded error handling and more Julian syntax

### Example:

```julia
using ModernGL, GeometryTypes, GLAbstraction, GLFW

const GLA = GLAbstraction

window = GLFW.Window(name="Drawing polygons 5", resolution=(800,600))
GLA.set_context!(window)

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

fragment_shader = GLA.frag"""
# version 150

in vec3 Color;

out vec4 outColor;

void main()
{
    outColor = vec4(Color, 1.0);
}
"""

prog = GLA.Program(vertex_shader, fragment_shader)

vertex_positions = Point{2,Float32}[(-0.5,  0.5),     
                                    ( 0.5,  0.5),     
                                    ( 0.5, -0.5),     
                                    (-0.5, -0.5)]     

vertex_colors = Vec3f0[(1, 0, 0),                     
                       (0, 1, 0),                     
                       (0, 0, 1),                     
                       (1, 1, 1)]
elements = Face{3,UInt32}[(0,1,2),
                          (2,3,0)]
buffers = GLA.generate_buffers(prog, position = vertex_positions, color = vertex_colors)
vao = GLA.VertexArray(buffers, elements)
glClearColor(0, 0, 0, 1)

while !GLFW.WindowShouldClose(window)
    glClear(GL_COLOR_BUFFER_BIT)
    GLA.bind(prog)
    GLA.bind(vao)
    GLA.draw(vao)
    GLA.unbind(vao) #optional in this case
    GLA.unbind(prog) #optional in this case
    GLFW.SwapBuffers(window)
    GLFW.PollEvents()
    if GLFW.GetKey(window, GLFW.KEY_ESCAPE) == GLFW.PRESS
        GLFW.SetWindowShouldClose(window, true)
    end
end
GLFW.DestroyWindow(window)  # needed if you're running this from the REPL
```

# Credits

Thanks for all the great [contributions](https://github.com/JuliaGL/GLAbstraction.jl/graphs/contributors)

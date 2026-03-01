using ModernGL, GLFW, GLAbstraction, GLFW, ColorTypes, Reactive, GeometryTypes
import GLAbstraction: N0f8
const GLA = GLAbstraction
const window = GLFW.Window(name="Example")
GLFW.MakeContextCurrent(window)
GLA.set_context!(window)


const vert = GLA.vert"""
#version 150

in vec2 vertices;
in vec2 texturecoordinates; // must be this name, because collect_for_gl assumes them

out vec2 f_uv;
void main() {
    f_uv = texturecoordinates;
    gl_Position = vec4(vertices, 0.0, 1.0);
}
"""

# you can also load the shader from a file, which you can then edit in any editor and the changes will show up in your opengl program.
#using FileIO; prrogram = TemplateProgram(load("path_to_frag.frag"), load("path_to_vert.vert"))
const frag = GLA.frag"""
#version 150

out vec4 outColor;
uniform sampler2D image;
in vec2 f_uv;

void main() {

    outColor = texture(image, f_uv);
}
"""
program = GLA.Program(vert, frag)

tex = GLA.Texture([RGBA{N0f8}(x,y,sin(x*pi), 1.0) for x=0:0.1:1., y=0:0.1:1.]) #automatically creates the correct texture

mesh = GLUVMesh2D(SimpleRectangle{Float32}(-1,-1,2,2))
vao = GLA.VertexArray(GLA.generate_buffers(program, vertices=mesh.vertices, GLA.GEOMETRY_DIVISOR, texturecoordinates = Vec2{Float32}.(mesh.texturecoordinates)), mesh.faces)

glClearColor(0, 0, 0, 1)

while !GLFW.WindowShouldClose(window)
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    GLA.bind(program)
    GLA.gluniform(program, :image, 0, tex)
    GLA.bind(vao)
    GLA.draw(vao)
    GLFW.SwapBuffers(window)
    GLFW.PollEvents()
    if GLFW.GetKey(window, GLFW.KEY_ESCAPE) == GLFW.PRESS
        GLFW.SetWindowShouldClose(window, true)
    end
end
GLFW.DestroyWindow(window)

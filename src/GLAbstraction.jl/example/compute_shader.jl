using GLWindow, GLAbstraction, ModernGL, Reactive, GLFW, GeometryTypes

const window = create_glcontext("Compute Shader", resolution = (512, 512))

# In order to write to a texture, we have to introduce it as image2D.
# local_size_x/y/z layout variables define the work group size.
# gl_GlobalInvocationID is a uvec3 variable giving the global GLid of the thread,
# gl_LocalInvocationID is the local index within the work group, and
# gl_WorkGroupID is the work group's index
const shader = comp"""
{{GLSL_VERSION}}
{{kernel}} // kernel function will get spliced into the shader
uniform image2D input;
uniform image2D result;
layout (local_size_x = {{local_size_x}}, local_size_y = {{local_size_y}}) in;
void main() {
    ivec2 index = ivec2(gl_GlobalInvocationID.xy);
    vec4 value  = texelFetch(input, index);
    imageStore(result, index, kernel(value, index));
}
"""

const tex_vert = vert"""
    {{GLSL_VERSION}}

    in vec2 vertices;
    in vec2 texturecoordinates;

    out vec2 uv_frag;

    uniform mat4 projectionview;
    void main(){
      uv_frag = texturecoordinates;
      gl_Position = projectionview * vec4(vertices, 0, 1);
    }
"""
const tex_frag = frag"""
    {{GLSL_VERSION}}

    in vec2 uv_frag;
    out vec4 frag_color;

    {{image_type}} image;

    void main(){
        float c = texture(image, uv_frag).x;
        frag_color = vec4(c, 1.0, 1.0, 1.0);
    }
"""


prg = TemplateProgram(shader)

i = 0f0
const roll = const_lift(every(0.1)) do x
    global i
    i::Float32 += 0.01f0
end
const tex = Texture(Float32, (512, 512))
glBindImageTexture(0, tex.GLid, 0, GL_FALSE, 0, GL_WRITE_ONLY, tex.internalformat);

data = Dict(
    :roll => roll,
    :destTex => tex,
)
const ro = RenderObject(data, Signal(prg))
postrender!(ro, glDispatchCompute, div(512,16), div(512,16), 1) # 512^2 threads in blocks of 16^2

cam = window.cameras[:orthographic_pixel]
function collect_for_gl(m::T) where T <: HomogenousMesh
    result = Dict{Symbol, Any}()
    attribs = attributes(m)
    @materialize! vertices, faces = attribs
    result[:vertices]   = Buffer(vertices)
    result[:faces]      = indexbuffer(faces)
    for (field, val) in attribs
        if field in [:texturecoordinates, :normals, :attribute_id]
            result[field] = Buffer(val)
        else
            result[field] = Texture(val)
        end
    end
    result
end

w, h = size(tex)

msh = GLUVMesh2D(SimpleRectangle{Float32}(0f0,0f0,w,h))
data = merge(Dict(
    :image            => tex,
    :projectionview   => cam.projectionview,
), collect_for_gl(msh))

textureshader = TemplateProgram(tex_frag, tex_vert, attributes=data)
texobj = RenderObject(data, Signal(textureshader))

prerender!(texobj, glDisable, GL_DEPTH_TEST, enabletransparency, glDisable, GL_CULL_FACE)
postrender!(texobj, render, texobj.vertexarray)


glClearColor(0,0,0,1)
frame = 0f0
while !GLFW.WindowShouldClose(window.nativewindow)
    yield()
    render(ro)
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    render(texobj)
    GLFW.SwapBuffers(window.nativewindow)
    GLFW.PollEvents()
    sleep(0.01)
end
GLFW.DestroyWindow(window)

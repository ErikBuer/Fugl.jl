using ModernGL, GLFW, GLAbstraction
const GLA = GLAbstraction

using GeometryBasics
using FreeTypeAbstraction
using ColorTypes

mutable struct WindowInfo
    width_px::Integer
    height_px::Integer
    handle::Union{GLFW.Window,Nothing}
end

global window_info = WindowInfo(800, 600, nothing)

function ndc_to_px(dim::AbstractFloat, dim_px::Integer)::AbstractFloat
    return (dim / 2) * dim_px
end

function px_to_ndc(px::AbstractFloat, dim_px::Integer)::AbstractFloat
    return (px / dim_px) * 2
end

# Initialize the OpenGL context and window
const window = GLFW.Window(name="Text Rendering Example", resolution=(window_info.width_px, window_info.height_px))
GLFW.MakeContextCurrent(window)
GLA.set_context!(window)

# Vertex Shader
const vertex_shader = GLA.vert"""
#version 330 core
layout(location = 0) in vec2 position;
layout(location = 1) in vec4 color;
layout(location = 2) in vec2 texcoord;

out vec4 v_color;
out vec2 v_texcoord;

void main() {
    gl_Position = vec4(position, 0.0, 1.0);
    v_color = color;
    v_texcoord = texcoord;
}
"""

# Fragment Shader
const fragment_shader = GLA.frag"""
#version 330 core
in vec4 v_color;
in vec2 v_texcoord;

out vec4 FragColor;

uniform sampler2D image;
uniform bool use_texture;

void main() {
    if (use_texture) {
        FragColor = texture(image, v_texcoord);
    } else {
        FragColor = v_color;
    }
}
"""

# Compile the shader program
program = GLA.Program(vertex_shader, fragment_shader)

function load_texture_from_matrix(img::AbstractMatrix{<:ColorTypes.Colorant})
    # Ensure the image is in a supported format (e.g., Gray{Float32})
    img = Gray{Float32}.(img)

    # Transpose the image to match OpenGL's coordinate system
    img = permutedims(img)  # Swap dimensions 1 and 2 for proper orientation

    # Create a GLAbstraction texture
    texture = GLA.Texture(img; minfilter=:linear, magfilter=:linear, x_repeat=:clamp_to_edge, y_repeat=:clamp_to_edge)

    return texture
end

# Function to render text using FreeTypeAbstraction
function render_text(text::String, x::AbstractFloat, y::AbstractFloat, font_face, font_size::Integer, color::Vec4{<:AbstractFloat})
    # Canvas dimensions
    canvas_width = 800
    canvas_height = 600
    canvas = zeros(UInt8, canvas_height, canvas_width)  # Adjust size as needed

    # Render the string into the canvas
    renderstring!(
        canvas,
        text,
        font_face,
        font_size,
        canvas_height ÷ 2,  # Center vertically
        canvas_width ÷ 2;   # Center horizontally
        halign=:hcenter,
        valign=:vcenter,
        fcolor=typemax(UInt8),  # Foreground color (white for UInt8)
        bcolor=nothing          # Transparent background
    )

    # Convert the canvas to a grayscale image
    img = Gray.(convert.(Float32, canvas) ./ 255)

    # Load the texture directly from the matrix
    texture = load_texture_from_matrix(img)

    # Calculate the aspect ratio of the canvas
    aspect_ratio = canvas_width / canvas_height

    # Define the quad dimensions based on the canvas
    quad_width = 1.0  # Full width in NDC
    quad_height = quad_width / aspect_ratio  # Maintain aspect ratio

    # Define the quad vertices (in NDC)
    quad_vertices = [
        Point2f(x, y),                          # Bottom-left
        Point2f(x + quad_width, y),             # Bottom-right
        Point2f(x, y + quad_height),            # Top-left
        Point2f(x + quad_width, y + quad_height) # Top-right
    ]

    # Define the texture coordinates (covering the entire texture)
    texturecoordinates = [
        Vec{2,Float32}(0.0f0, 1.0f0),
        Vec{2,Float32}(1.0f0, 1.0f0),
        Vec{2,Float32}(0.0f0, 0.0f0),
        Vec{2,Float32}(1.0f0, 0.0f0)
    ]

    # Define indices for two triangles forming the rectangle
    indices = TriangleFace{OffsetInteger{-1,UInt32}}[
        TriangleFace{OffsetInteger{-1,UInt32}}((OffsetInteger{-1,UInt32}(1), OffsetInteger{-1,UInt32}(2), OffsetInteger{-1,UInt32}(4))),  # First triangle
        TriangleFace{OffsetInteger{-1,UInt32}}((OffsetInteger{-1,UInt32}(4), OffsetInteger{-1,UInt32}(3), OffsetInteger{-1,UInt32}(1)))   # Second triangle
    ]

    # Create buffers and VAO
    vao = GLA.VertexArray(
        GLA.generate_buffers(
            program,
            position=quad_vertices,
            texcoord=texturecoordinates
        ),
        indices
    )

    # Bind the shader program
    GLA.bind(program)

    # Set the `use_texture` uniform to true
    GLA.gluniform(program, :use_texture, true)

    # Bind the text texture to the `image` uniform
    GLA.gluniform(program, :image, 0, texture)

    # Bind the VAO and draw the quad
    glActiveTexture(GL_TEXTURE0)
    GLA.bind(vao)
    GLA.draw(vao)

    # Unbind the VAO and shader program
    GLA.unbind(vao)
    GLA.unbind(program)
end

# Load a font using FreeTypeAbstraction
font_face = findfont("arial")
if font_face === nothing
    error("Font not found!")
end

font_size = 100

# Main rendering loop
glClearColor(0.0, 0.0, 0.0, 1.0)
while !GLFW.WindowShouldClose(window)
    glClear(GL_COLOR_BUFFER_BIT)

    # Render text
    render_text("Test text", -1.0, -1.0, font_face, font_size, Vec4(1.0f0, 1.0f0, 1.0f0, 1.0f0))

    # Swap buffers and poll events
    GLFW.SwapBuffers(window)
    GLFW.PollEvents()
    if GLFW.GetKey(window, GLFW.KEY_ESCAPE) == GLFW.PRESS
        GLFW.SetWindowShouldClose(window, true)
    end
end

GLFW.DestroyWindow(window)
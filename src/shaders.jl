const vertex_shader = GLA.vert"""
#version 330 core
layout(location = 0) in vec2 position; // Position in pixels
layout(location = 1) in vec4 color;
layout(location = 2) in vec2 texcoord;

out vec4 v_color;
out vec2 v_texcoord;

uniform mat4 projection; // Projection matrix

void main() {
    // Transform position from pixels to NDC using the projection matrix
    gl_Position = projection * vec4(position, 0.0, 1.0);

    v_color = color;
    v_texcoord = texcoord;
}
"""

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

const rounded_rect_vertex_shader = GLA.vert"""
#version 330 core
layout(location = 0) in vec2 position;
layout(location = 1) in vec2 uv; // [0,1] box coordinates

out vec2 v_uv;

uniform mat4 projection;

void main() {
    gl_Position = projection * vec4(position, 0.0, 1.0);
    v_uv = uv;
}
"""

const rounded_rect_fragment_shader = GLA.frag"""
#version 330 core
in vec2 v_uv;
out vec4 FragColor;

// Uniforms for rectangle appearance
uniform vec4 fill_color;      // Fill color inside the rectangle
uniform vec4 border_color;    // Border color
uniform float border_width;   // Border thickness in pixels
uniform float radius;         // Corner radius in pixels
uniform float aa;             // Anti-aliasing width in pixels
uniform vec2 rect_size;       // Size of the rectangle in pixels

// Signed distance function for a rounded rectangle
float sdRoundBox(vec2 p, vec2 size, float r, vec2 rect_size) {
    vec2 centered = (p - 0.5) * rect_size;
    vec2 half_size = size * 0.5 * rect_size - vec2(r);
    vec2 d = abs(centered) - half_size;
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0) - r;
}

void main() {
    float r = radius;         // Corner radius
    float bw = border_width;  // Border thickness
    float antialias = aa;     // Anti-aliasing width

    // SDF for the original rectangle, but increase radius by border width
    float dist = sdRoundBox(v_uv, vec2(1.0, 1.0), r + bw, rect_size);

    // Border: band between dist = 0 (outer edge) and dist = -bw (inner edge)
    float border_alpha =  smoothstep(-antialias, antialias, dist + bw) - smoothstep(-antialias, antialias, dist);

    // Fill: everything inside the border
    float fill_alpha = 1.0 - smoothstep(-antialias, antialias, dist + bw);

    vec4 border = border_color * border_alpha;
    vec4 fill = fill_color * fill_alpha;

    FragColor = border + fill;
}
"""


const glyph_vertex_shader = GLA.vert"""
#version 330 core
layout(location = 0) in vec2 position; // Glyph position in pixels
layout(location = 1) in vec2 texcoord; // Texture coordinates

out vec2 v_texcoord;

uniform mat4 projection; // Projection matrix

void main() {
    // Transform position from pixels to NDC using the projection matrix
    gl_Position = projection * vec4(position, 0.0, 1.0);
    v_texcoord = texcoord; // Pass texture coordinates to the fragment shader
}
"""

const glyph_fragment_shader = GLA.frag"""
#version 330 core
in vec2 v_texcoord;
out vec4 FragColor;

uniform sampler2D image;       // Glyph texture
uniform vec4 text_color;       // Text color

void main() {
    // Sample the glyph texture
    vec4 sampled = texture(image, v_texcoord);

    // Apply the text color and alpha from the texture
    FragColor = vec4(text_color.rgb, sampled.r * text_color.a);
}
"""


# Global variable for the shader program
const prog = Ref{GLA.Program}()
const glyph_prog = Ref{GLA.Program}()
const rounded_rect_prog = Ref{GLA.Program}()

"""
Initialize the shader program (must be called after OpenGL context is created)
"""
function initialize_shaders()
    prog[] = GLA.Program(vertex_shader, fragment_shader)
    glyph_prog[] = GLA.Program(glyph_vertex_shader, glyph_fragment_shader)
    rounded_rect_prog[] = GLA.Program(rounded_rect_vertex_shader, rounded_rect_fragment_shader)
end
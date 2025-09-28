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


const line_vertex_shader = GLA.vert"""
#version 330 core
layout (location = 0) in vec2 position;
layout (location = 1) in vec2 direction;
layout (location = 2) in float width;
layout (location = 3) in vec4 color;
layout (location = 4) in float vertex_type;
layout (location = 5) in float line_style;    // 0.0=solid, 1.0=dash, 2.0=dot, 3.0=dashdot
layout (location = 6) in float line_progress; // Progress along the line (for pattern calculation)

uniform mat4 projection;

out vec4 v_color;
out vec2 v_local_pos;
flat out float v_line_style;
out float v_line_progress;
out float v_line_width;

void main() {
    v_color = color;
    v_line_style = line_style;
    v_line_progress = line_progress;
    v_line_width = width;
    
    float half_width = width * 0.5;
    
    // Calculate normalized direction and perpendicular
    float dir_length = length(direction);
    if (dir_length == 0.0) {
        gl_Position = projection * vec4(position, 0.0, 1.0);
        v_local_pos = vec2(0.0, 0.0);
        return;
    }
    
    vec2 dir_norm = direction / dir_length;
    vec2 perp = vec2(-dir_norm.y, dir_norm.x) * half_width;
    
    vec2 final_position;
    
    if (vertex_type < 0.5) {
        // Bottom-left vertex
        final_position = position - perp;
        v_local_pos = vec2(0.0, -1.0);
    } else if (vertex_type < 1.5) {
        // Bottom-right vertex  
        final_position = position + direction - perp;
        v_local_pos = vec2(1.0, -1.0);
    } else if (vertex_type < 2.5) {
        // Top-left vertex
        final_position = position + perp;
        v_local_pos = vec2(0.0, 1.0);
    } else {
        // Top-right vertex
        final_position = position + direction + perp;
        v_local_pos = vec2(1.0, 1.0);
    }
    
    gl_Position = projection * vec4(final_position, 0.0, 1.0);
}
"""

const line_fragment_shader = GLA.frag"""
#version 330 core
in vec4 v_color;
in vec2 v_local_pos;
flat in float v_line_style;
in float v_line_progress;
in float v_line_width;

uniform float anti_aliasing_width;

out vec4 FragColor;

float dash_pattern(float progress, float style, float line_width) {
    // Scale pattern based on line width for consistent appearance
    float pattern_scale = max(1.0, line_width * 0.5);
    float scaled_progress = progress / pattern_scale;
    
    // Calculate all pattern types (branchless)
    float solid_pattern = 1.0;
    
    // Dash pattern: on for 8 units, off for 4 units
    float dash_cycle = mod(scaled_progress, 12.0);
    float dash_pattern = float(dash_cycle < 8.0);
    
    // Dot pattern: on for 2 units, off for 4 units  
    float dot_cycle = mod(scaled_progress, 6.0);
    float dot_pattern = float(dot_cycle < 2.0);
    
    // Dash-dot pattern: dash(8), gap(2), dot(2), gap(4)
    float dashdot_cycle = mod(scaled_progress, 16.0);
    float dashdot_pattern = float(dashdot_cycle < 8.0) * float(dashdot_cycle >= 0.0) +  // dash
                           float(dashdot_cycle >= 10.0) * float(dashdot_cycle < 12.0);  // dot
    
    // Create weights for each style (exactly one will be 1.0, others 0.0)
    // Use abs() to ensure floating point comparison works properly
    float solid_weight = float(abs(style - 0.0) < 0.1);
    float dash_weight = float(abs(style - 1.0) < 0.1);
    float dot_weight = float(abs(style - 2.0) < 0.1);
    float dashdot_weight = float(abs(style - 3.0) < 0.1);
    
    // Blend patterns using weights (branchless selection)
    return solid_pattern * solid_weight +
           dash_pattern * dash_weight +
           dot_pattern * dot_weight +
           dashdot_pattern * dashdot_weight +
           solid_pattern * (1.0 - solid_weight - dash_weight - dot_weight - dashdot_weight); // fallback to solid
}

void main() {
    // Distance from center line along the width
    float dist = abs(v_local_pos.y);
    
    // Configurable anti-aliasing - when anti_aliasing_width is 0.0, this becomes sharp
    float aa_width = max(0.001, anti_aliasing_width / v_line_width); // Normalize to line width, minimum to avoid division issues
    float edge_alpha = 1.0 - smoothstep(1.0 - aa_width, 1.0, dist);
    
    // Calculate line style pattern - no conversion needed now
    float pattern_alpha = dash_pattern(v_line_progress, v_line_style, v_line_width);
    
    // Combine edge anti-aliasing with pattern
    float final_alpha = v_color.a * edge_alpha * pattern_alpha;
    
    FragColor = vec4(v_color.rgb, final_alpha);
}
"""

# Global variable for the shader program
const prog = Ref{GLA.Program}()
const glyph_prog = Ref{GLA.Program}()
const rounded_rect_prog = Ref{GLA.Program}()
const line_prog = Ref{GLA.Program}()

# External shader registration system
const EXTERNAL_SHADER_INITIALIZERS = Function[]

"""
    register_shader_initializer!(init_function::Function)

Register an external shader initialization function to be called during Fugl's shader initialization.
This allows external packages (like FuglDrawing.jl) to register their shaders.

# Arguments
- `init_function::Function`: A function that will be called during shader initialization

# Example
```julia
# In FuglDrawing.jl
function initialize_drawing_shaders()
    # Initialize drawing-specific shaders
    drawing_prog[] = Program(drawing_vertex_shader, drawing_fragment_shader)
end

# Register with Fugl
Fugl.register_shader_initializer!(initialize_drawing_shaders)
```
"""
function register_shader_initializer!(init_function::Function)
    push!(EXTERNAL_SHADER_INITIALIZERS, init_function)
end

"""
Initialize the shader program (must be called after OpenGL context is created)
"""
function initialize_shaders()
    prog[] = GLA.Program(vertex_shader, fragment_shader)
    glyph_prog[] = GLA.Program(glyph_vertex_shader, glyph_fragment_shader)
    rounded_rect_prog[] = GLA.Program(rounded_rect_vertex_shader, rounded_rect_fragment_shader)
    line_prog[] = GLA.Program(line_vertex_shader, line_fragment_shader)

    # Initialize external shaders
    for init_function in EXTERNAL_SHADER_INITIALIZERS
        try
            init_function()
        catch e
            @warn "Failed to initialize external shader" exception = (e, catch_backtrace())
        end
    end
end
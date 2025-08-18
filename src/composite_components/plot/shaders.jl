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

# Global variable for plot shader program
const line_prog = Ref{GLA.Program}()


const marker_vertex_shader = GLA.vert"""
#version 330 core
layout (location = 0) in vec2 position;      // Center position of marker
layout (location = 1) in float size;         // Size of marker (radius/half-width)
layout (location = 2) in vec4 fill_color;    // Fill color
layout (location = 3) in vec4 border_color;  // Border color
layout (location = 4) in float border_width; // Border width in pixels
layout (location = 5) in int marker_type;    // 0=circle, 1=triangle, 2=rectangle
layout (location = 6) in float vertex_id;    // Vertex ID for quad (0,1,2,3)

uniform mat4 projection;

out vec4 v_fill_color;
out vec4 v_border_color;
out float v_border_width;
flat out int v_marker_type;
out float v_size;
out vec2 v_local_pos;  // Local position within marker quad (-1 to 1)

void main() {
    v_fill_color = fill_color;
    v_border_color = border_color;
    v_border_width = border_width;
    v_marker_type = marker_type;
    v_size = size;
    
    // Create a quad around the marker center
    vec2 quad_offset;
    if (vertex_id < 0.5) {
        // Bottom-left
        quad_offset = vec2(-1.0, -1.0);
        v_local_pos = vec2(-1.0, -1.0);
    } else if (vertex_id < 1.5) {
        // Bottom-right
        quad_offset = vec2(1.0, -1.0);
        v_local_pos = vec2(1.0, -1.0);
    } else if (vertex_id < 2.5) {
        // Top-left
        quad_offset = vec2(-1.0, 1.0);
        v_local_pos = vec2(-1.0, 1.0);
    } else {
        // Top-right
        quad_offset = vec2(1.0, 1.0);
        v_local_pos = vec2(1.0, 1.0);
    }
    
    // Scale quad by marker size
    vec2 final_position = position + quad_offset * size;
    
    gl_Position = projection * vec4(final_position, 0.0, 1.0);
}
"""

const marker_fragment_shader = GLA.frag"""
#version 330 core
in vec4 v_fill_color;
in vec4 v_border_color;
in float v_border_width;
flat in int v_marker_type;
in float v_size;
in vec2 v_local_pos;  // Local position within marker quad (-1 to 1)

uniform float anti_aliasing_width;

out vec4 FragColor;

// Distance function for circle
float circle_sdf(vec2 p) {
    return length(p) - 1.0;
}

// Distance function for rectangle
float rect_sdf(vec2 p) {
    vec2 d = abs(p) - vec2(1.0);
    return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

// Distance function for triangle (equilateral)
float triangle_sdf(vec2 p) {
    const float k = sqrt(3.0);
    p.x = abs(p.x) - 1.0;
    p.y = p.y + 1.0/k;
    if (p.x + k*p.y > 0.0) p = vec2(p.x - k*p.y, -k*p.x - p.y)/2.0;
    p.x -= clamp(p.x, -2.0, 0.0);
    return -length(p)*sign(p.y);
}

void main() {
    vec2 p = v_local_pos;
    
    // Calculate all distance functions (no branching)
    float circle_dist = circle_sdf(p);
    float triangle_dist = triangle_sdf(p);
    float rect_dist = rect_sdf(p);
    
    // Create weights for each marker type (exactly one will be 1.0, others 0.0)
    float circle_weight = float(v_marker_type == 0);
    float triangle_weight = float(v_marker_type == 1);
    float rect_weight = float(v_marker_type == 2);
    
    // Blend distances using weights (branchless selection)
    float dist = circle_dist * circle_weight + 
                 triangle_dist * triangle_weight + 
                 rect_dist * rect_weight +
                 circle_dist * (1.0 - circle_weight - triangle_weight - rect_weight); // fallback to circle
    
    // Calculate anti-aliasing width in local coordinates
    float aa_width = max(0.001, anti_aliasing_width / v_size);
    
    // Calculate border thickness in local coordinates
    float border_thickness = v_border_width / v_size;
    
    // Calculate fill alpha (inside shape)
    float fill_alpha = 1.0 - smoothstep(-aa_width, aa_width, dist);
    
    // Calculate border alpha (at edge of shape)
    float border_outer = dist + border_thickness * 0.5;
    float border_inner = dist - border_thickness * 0.5;
    float border_alpha = smoothstep(-aa_width, aa_width, -border_outer) * 
                        (1.0 - smoothstep(-aa_width, aa_width, -border_inner));
    
    // Combine fill and border
    vec4 final_color = v_fill_color * fill_alpha + v_border_color * border_alpha;
    
    // Overall shape alpha (for discarding pixels outside the marker)
    float shape_alpha = max(fill_alpha, border_alpha);
    
    FragColor = vec4(final_color.rgb, final_color.a * shape_alpha);
}
"""

# Global variable for shader programs
const marker_prog = Ref{GLA.Program}()


const image_plot_vertex_shader = GLA.vert"""
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

const image_plot_fragment_shader = GLA.frag"""
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

const image_plot_prog = Ref{GLA.Program}()

"""
Initialize the plot shader programs (must be called after OpenGL context is created)
"""
function initialize_plot_shaders()
    line_prog[] = GLA.Program(line_vertex_shader, line_fragment_shader)
    marker_prog[] = GLA.Program(marker_vertex_shader, marker_fragment_shader)
    image_plot_prog[] = GLA.Program(image_plot_vertex_shader, image_plot_fragment_shader)
end

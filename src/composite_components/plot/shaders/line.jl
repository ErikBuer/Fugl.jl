const plot_line_vertex_shader = GLA.vert"""
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

const plot_line_fragment_shader = GLA.frag"""
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
const plot_line_prog = Ref{GLA.Program}()
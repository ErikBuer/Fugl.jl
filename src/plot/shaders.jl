const line_vertex_shader = GLA.vert"""
#version 330 core
layout (location = 0) in vec2 position;
layout (location = 1) in vec2 direction;
layout (location = 2) in float width;
layout (location = 3) in vec4 color;
layout (location = 4) in float vertex_type;
layout (location = 5) in float line_style;    // 0=solid, 1=dash, 2=dot, 3=dashdot
layout (location = 6) in float line_progress; // Progress along the line (for pattern calculation)

uniform mat4 projection;

out vec4 v_color;
out vec2 v_local_pos;
out float v_line_style;
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
in float v_line_style;
in float v_line_progress;
in float v_line_width;

uniform float anti_aliasing_width;

out vec4 FragColor;

float dash_pattern(float progress, int style, float line_width) {
    if (style == 0) {
        // Solid line
        return 1.0;
    }
    
    // Scale pattern based on line width for consistent appearance
    float pattern_scale = max(1.0, line_width * 0.5);
    float scaled_progress = progress / pattern_scale;
    
    if (style == 1) {
        // Dash pattern: on for 8 units, off for 4 units
        float cycle = mod(scaled_progress, 12.0);
        return cycle < 8.0 ? 1.0 : 0.0;
    } else if (style == 2) {
        // Dot pattern: on for 2 units, off for 4 units  
        float cycle = mod(scaled_progress, 6.0);
        return cycle < 2.0 ? 1.0 : 0.0;
    } else if (style == 3) {
        // Dash-dot pattern: dash(8), gap(2), dot(2), gap(4)
        float cycle = mod(scaled_progress, 16.0);
        if (cycle < 8.0) return 1.0;       // dash
        else if (cycle < 10.0) return 0.0; // gap
        else if (cycle < 12.0) return 1.0; // dot
        else return 0.0;                   // gap
    }
    return 1.0; // fallback to solid
}

void main() {
    // Distance from center line along the width
    float dist = abs(v_local_pos.y);
    
    // Configurable anti-aliasing - when anti_aliasing_width is 0.0, this becomes sharp
    float aa_width = max(0.001, anti_aliasing_width / v_line_width); // Normalize to line width, minimum to avoid division issues
    float edge_alpha = 1.0 - smoothstep(1.0 - aa_width, 1.0, dist);
    
    // Calculate line style pattern with improved scaling
    int style = int(v_line_style + 0.5); // Round to nearest integer
    float pattern_alpha = dash_pattern(v_line_progress, style, v_line_width);
    
    // Combine edge anti-aliasing with pattern
    float final_alpha = v_color.a * edge_alpha * pattern_alpha;
    
    FragColor = vec4(v_color.rgb, final_alpha);
}
"""

# Global variable for plot shader program
const line_prog = Ref{GLA.Program}()

"""
Initialize the plot shader programs (must be called after OpenGL context is created)
"""
function initialize_plot_shaders()
    line_prog[] = GLA.Program(line_vertex_shader, line_fragment_shader)
end

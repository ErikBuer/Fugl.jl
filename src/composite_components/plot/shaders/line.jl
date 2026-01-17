const plot_line_vertex_shader = GLA.vert"""
#version 330 core
layout (location = 0) in vec2 position;
layout (location = 1) in vec2 direction;
layout (location = 2) in float width;
layout (location = 3) in vec4 color;
layout (location = 4) in float vertex_type;
layout (location = 5) in float line_pattern;  // 0.0=solid, 1.0=dash, 2.0=dot, 3.0=dashdot
layout (location = 6) in float line_progress; // Progress along the line (for pattern calculation)
layout (location = 7) in float line_cap_type; // 0.0=butt, 1.0=square, 2.0=round

uniform mat4 projection;

out vec4 v_color;
out vec2 v_local_pos;
flat out float v_line_pattern;
out float v_line_progress;
out float v_line_width;
flat out float v_line_cap_type;
out vec2 v_line_pos; // position along line: x=distance from start, y=distance from center
flat out float v_line_length; // actual line length

void main() {
    v_color = color;
    v_line_pattern = line_pattern;
    v_line_progress = line_progress;
    v_line_width = width;
    v_line_cap_type = line_cap_type;
    
    float half_width = width * 0.5;
    
    // Calculate normalized direction and perpendicular
    float dir_length = length(direction);
    v_line_length = dir_length;  // pass line length to fragment shader
    
    if (dir_length == 0.0) {
        gl_Position = projection * vec4(position, 0.0, 1.0);
        v_local_pos = vec2(0.0, 0.0);
        v_line_pos = vec2(0.0, 0.0);
        return;
    }
    
    vec2 dir_norm = direction / dir_length;
    vec2 perp = vec2(-dir_norm.y, dir_norm.x) * half_width;
    
    vec2 final_position;
    
    // Always extend by half-width on both ends (like square caps)
    vec2 extension = dir_norm * half_width;
    
    if (vertex_type < 0.5) {
        // Bottom-left vertex (extended)
        final_position = position - perp - extension;
        v_local_pos = vec2(-1.0, -1.0);
        v_line_pos = vec2(-half_width, -half_width);
    } else if (vertex_type < 1.5) {
        // Bottom-right vertex (extended)
        final_position = position + direction - perp + extension;
        v_local_pos = vec2(1.0, -1.0);
        v_line_pos = vec2(dir_length + half_width, -half_width);
    } else if (vertex_type < 2.5) {
        // Top-left vertex (extended)
        final_position = position + perp - extension;
        v_local_pos = vec2(-1.0, 1.0);
        v_line_pos = vec2(-half_width, half_width);
    } else {
        // Top-right vertex (extended)
        final_position = position + direction + perp + extension;
        v_local_pos = vec2(1.0, 1.0);
        v_line_pos = vec2(dir_length + half_width, half_width);
    }
    
    gl_Position = projection * vec4(final_position, 0.0, 1.0);
}
"""

const plot_line_fragment_shader = GLA.frag"""
#version 330 core
in vec4 v_color;
in vec2 v_local_pos;
flat in float v_line_pattern;
in float v_line_progress;
in float v_line_width;
flat in float v_line_cap_type;
in vec2 v_line_pos;
flat in float v_line_length;

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
    float half_width = v_line_width * 0.5;
    float aa_width = max(0.001, anti_aliasing_width / v_line_width);
    
    // Distance along the line (x) and from center line (y)
    float line_dist = v_line_pos.x;  // distance from line start
    float perp_dist = abs(v_line_pos.y);  // distance from center line
    
    float sdf;
    
    // Handle different cap types using SDF
    if (abs(v_line_cap_type - 0.0) < 0.1) {
        // BUTT_CAP - cut off at line ends (no extension)
        sdf = max(max(-line_dist, line_dist - v_line_length), perp_dist - half_width);
    } else if (abs(v_line_cap_type - 1.0) < 0.1) {
        // SQUARE_CAP - extend by half_width on both ends
        sdf = max(max(-line_dist - half_width, line_dist - v_line_length - half_width), perp_dist - half_width);
    } else {
        // ROUND_CAP - circular ends
        float body_sdf = max(max(-line_dist, line_dist - v_line_length), perp_dist - half_width);
        
        if (line_dist < 0.0) {
            // Start cap region - circle centered at line start
            float cap_sdf = length(vec2(line_dist, v_line_pos.y)) - half_width;
            sdf = min(cap_sdf, body_sdf);
        } else if (line_dist > v_line_length) {
            // End cap region - circle centered at line end
            float cap_sdf = length(vec2(line_dist - v_line_length, v_line_pos.y)) - half_width;
            sdf = min(cap_sdf, body_sdf);
        } else {
            // Line body - just perpendicular distance
            sdf = perp_dist - half_width;
        }
    }
    
    // Apply line pattern only to line body (not extended cap areas)
    float pattern_alpha = 1.0;
    if (line_dist >= 0.0 && line_dist <= v_line_length) {  // only in line body
        pattern_alpha = dash_pattern(v_line_progress, v_line_pattern, v_line_width);
    }
    
    // Combine SDF with pattern and anti-aliasing
    float edge_alpha = 1.0 - smoothstep(-aa_width, aa_width, sdf);
    float final_alpha = v_color.a * edge_alpha * pattern_alpha;
    
    FragColor = vec4(v_color.rgb, final_alpha);
}
"""

# Global variable for plot shader program
const plot_line_prog = Ref{GLA.Program}()
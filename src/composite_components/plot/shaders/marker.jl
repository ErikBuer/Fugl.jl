const marker_vertex_shader = GLA.vert"""
#version 330 core
layout (location = 0) in vec2 position;      // Center position of marker
layout (location = 1) in float size;         // Size of marker (radius/half-width)
layout (location = 2) in vec4 fill_color;    // Fill color
layout (location = 3) in vec4 border_color;  // Border color
layout (location = 4) in float border_width; // Border width in pixels
layout (location = 5) in float marker_type;   // 0=circle, 1=triangle, 2=rectangle (as Float32 for compatibility)
layout (location = 6) in float vertex_id;    // Vertex ID for quad (0,1,2,3)

uniform mat4 projection;

out vec4 v_fill_color;
out vec4 v_border_color;
out float v_border_width;
flat out float v_marker_type;
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
flat in float v_marker_type;
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
    float circle_weight = float(abs(v_marker_type - 0.0) < 0.1);
    float triangle_weight = float(abs(v_marker_type - 1.0) < 0.1);
    float rect_weight = float(abs(v_marker_type - 2.0) < 0.1);
    
    // Blend distances using weights (branchless selection)
    float dist = circle_dist * circle_weight + 
                 triangle_dist * triangle_weight + 
                 rect_dist * rect_weight +
                 circle_dist * (1.0 - circle_weight - triangle_weight - rect_weight); // fallback to circle
    
    // Calculate anti-aliasing width in local coordinates
    float aa_width = max(0.001, anti_aliasing_width / v_size);
    
    // Calculate border thickness in local coordinates
    float border_thickness = v_border_width / v_size;
    
    // Use SDF approach like line shader
    // Outer edge of shape
    float outer_alpha = 1.0 - smoothstep(-aa_width, aa_width, dist);
    
    // Inner edge of border (shape shrunk by border thickness)
    float inner_dist = dist + border_thickness;
    float inner_alpha = 1.0 - smoothstep(-aa_width, aa_width, inner_dist);
    
    // Border region: outside inner edge but inside outer edge
    float border_alpha = outer_alpha * (1.0 - inner_alpha);
    
    // Fill region: inside inner edge
    float fill_alpha = inner_alpha;
    
    // Combine fill and border colors
    vec4 final_color = v_fill_color * fill_alpha + v_border_color * border_alpha;
    float total_alpha = max(fill_alpha, border_alpha);
    
    FragColor = vec4(final_color.rgb, final_color.a * total_alpha);
}
"""

# Global variable for shader programs
const marker_prog = Ref{GLA.Program}()
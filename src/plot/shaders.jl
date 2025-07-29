const line_vertex_shader = GLA.vert"""
#version 330 core
layout(location = 0) in vec2 position; // Line segment endpoint
layout(location = 1) in vec2 direction; // Direction to the other endpoint
layout(location = 2) in float width; // Line width in pixels
layout(location = 3) in vec4 color; // Line color
layout(location = 4) in float vertex_type; // 0=start, 1=end, 2=miter

out vec4 v_color;
out vec2 v_local_pos; // Local position within the line segment
out float v_width;

uniform mat4 projection; // Projection matrix

void main() {
    v_color = color;
    v_width = width;
    
    // Calculate perpendicular vector for line thickness
    vec2 normal = normalize(vec2(-direction.y, direction.x));
    
    // Offset position based on vertex type and line width
    vec2 offset = vec2(0.0);
    
    if (vertex_type < 0.5) { // Start vertex
        offset = normal * (width * 0.5);
        v_local_pos = vec2(-1.0, 1.0);
    } else if (vertex_type < 1.5) { // End vertex
        offset = normal * (width * 0.5);
        v_local_pos = vec2(1.0, 1.0);
    } else { // Miter vertex
        offset = normal * (-width * 0.5);
        v_local_pos = vec2(vertex_type < 2.5 ? -1.0 : 1.0, -1.0);
    }
    
    vec2 final_position = position + offset;
    gl_Position = projection * vec4(final_position, 0.0, 1.0);
}
"""

const line_fragment_shader = GLA.frag"""
#version 330 core
in vec4 v_color;
in vec2 v_local_pos;
in float v_width;

out vec4 FragColor;

uniform float aa; // Anti-aliasing width in pixels

void main() {
    // Distance from center line
    float dist = abs(v_local_pos.y) * v_width * 0.5;
    
    // Anti-aliased edge
    float alpha = 1.0 - smoothstep(v_width * 0.5 - aa, v_width * 0.5 + aa, dist);
    
    FragColor = vec4(v_color.rgb, v_color.a * alpha);
}
"""

const line_with_caps_vertex_shader = GLA.vert"""
#version 330 core
layout(location = 0) in vec2 position; // Line segment endpoint or cap center
layout(location = 1) in vec2 direction; // Direction vector or cap normal
layout(location = 2) in float width; // Line width in pixels
layout(location = 3) in vec4 color; // Line color
layout(location = 4) in float vertex_type; // 0-3=line quad, 4-7=start cap, 8-11=end cap

out vec4 v_color;
out vec2 v_local_pos; // Local position for distance calculations
out float v_width;
out float v_primitive_type; // 0=line, 1=cap

uniform mat4 projection; // Projection matrix

void main() {
    v_color = color;
    v_width = width;
    
    vec2 final_position;
    
    if (vertex_type < 4.0) {
        // Line segment quad
        v_primitive_type = 0.0;
        vec2 normal = normalize(vec2(-direction.y, direction.x));
        
        float side = (mod(vertex_type, 2.0) < 0.5) ? -1.0 : 1.0;
        float end = (vertex_type < 2.0) ? 0.0 : 1.0;
        
        vec2 offset = normal * side * width * 0.5;
        final_position = position + direction * end + offset;
        
        v_local_pos = vec2(end * 2.0 - 1.0, side);
        
    } else {
        // Cap (circular)
        v_primitive_type = 1.0;
        
        float cap_vertex = mod(vertex_type, 4.0);
        float angle = cap_vertex * 1.5708; // π/2 radians = 90 degrees
        
        vec2 cap_offset = vec2(cos(angle), sin(angle)) * width * 0.5;
        final_position = position + cap_offset;
        
        v_local_pos = cap_offset / (width * 0.5); // Normalized cap coordinates
    }
    
    gl_Position = projection * vec4(final_position, 0.0, 1.0);
}
"""

const line_with_caps_fragment_shader = GLA.frag"""
#version 330 core
in vec4 v_color;
in vec2 v_local_pos;
in float v_width;
in float v_primitive_type;

out vec4 FragColor;

uniform float aa; // Anti-aliasing width in pixels

void main() {
    float alpha = 1.0;
    
    if (v_primitive_type < 0.5) {
        // Line segment
        float dist = abs(v_local_pos.y) * v_width * 0.5;
        alpha = 1.0 - smoothstep(v_width * 0.5 - aa, v_width * 0.5 + aa, dist);
    } else {
        // Cap (circular)
        float dist = length(v_local_pos) * v_width * 0.5;
        alpha = 1.0 - smoothstep(v_width * 0.5 - aa, v_width * 0.5 + aa, dist);
    }
    
    FragColor = vec4(v_color.rgb, v_color.a * alpha);
}
"""

const point_vertex_shader = GLA.vert"""
#version 330 core
layout(location = 0) in vec2 position; // Point center
layout(location = 1) in float size; // Point size in pixels
layout(location = 2) in vec4 color; // Point color
layout(location = 3) in vec2 uv; // UV coordinates for quad vertices

out vec4 v_color;
out vec2 v_uv;
out float v_size;

uniform mat4 projection; // Projection matrix

void main() {
    v_color = color;
    v_uv = uv;
    v_size = size;
    
    // Create quad around point center
    vec2 offset = (uv - 0.5) * size;
    vec2 final_position = position + offset;
    
    gl_Position = projection * vec4(final_position, 0.0, 1.0);
}
"""

const point_fragment_shader = GLA.frag"""
#version 330 core
in vec4 v_color;
in vec2 v_uv;
in float v_size;

out vec4 FragColor;

uniform float aa; // Anti-aliasing width in pixels

void main() {
    // Distance from center (0.5, 0.5)
    float dist = length(v_uv - 0.5) * v_size;
    float radius = v_size * 0.5;
    
    // Anti-aliased circle
    float alpha = 1.0 - smoothstep(radius - aa, radius + aa, dist);
    
    FragColor = vec4(v_color.rgb, v_color.a * alpha);
}
"""

# Global variables for plot shader programs
const line_prog = Ref{GLA.Program}()
const line_with_caps_prog = Ref{GLA.Program}()
const point_prog = Ref{GLA.Program}()

"""
Initialize the plot shader programs (must be called after OpenGL context is created)
"""
function initialize_plot_shaders()
    line_prog[] = GLA.Program(line_vertex_shader, line_fragment_shader)
    line_with_caps_prog[] = GLA.Program(line_with_caps_vertex_shader, line_with_caps_fragment_shader)
    point_prog[] = GLA.Program(point_vertex_shader, point_fragment_shader)
end

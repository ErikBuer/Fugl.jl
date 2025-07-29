# OpenGL shaders for plot rendering
using GLAbstraction
const GLA = GLAbstraction

# Simple line shader - quad-based rendering with proper joins
const simple_line_vertex_shader = GLA.vert"""
#version 330 core
layout (location = 0) in vec2 position;
layout (location = 1) in vec2 direction;
layout (location = 2) in float width;
layout (location = 3) in vec4 color;
layout (location = 4) in float vertex_type;

uniform mat4 projection;

out vec4 v_color;
out vec2 v_local_pos;

void main() {
    v_color = color;
    
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

const simple_line_fragment_shader = GLA.frag"""
#version 330 core
in vec4 v_color;
in vec2 v_local_pos;

out vec4 FragColor;

void main() {
    // Simple anti-aliased edge
    float dist = abs(v_local_pos.y);
    float alpha = 1.0 - smoothstep(0.8, 1.0, dist);
    
    FragColor = vec4(v_color.rgb, v_color.a * alpha);
}
"""

# Global variables for plot shader programs
const simple_line_prog = Ref{GLA.Program}()

"""
Initialize the plot shader programs (must be called after OpenGL context is created)
"""
function initialize_plot_shaders()
    simple_line_prog[] = GLA.Program(simple_line_vertex_shader, simple_line_fragment_shader)
end

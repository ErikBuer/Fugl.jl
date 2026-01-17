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
uniform vec2 value_range;      // For potential future color normalization
uniform vec4 nan_color;        // Color for NaN/invalid values
uniform vec4 background_color; // Background color
uniform int colormap_type;     // 0=grayscale, 1=viridis, 2=plasma, 3=hot

// Viridis colormap implementation
vec3 viridis(float t) {
    t = clamp(t, 0.0, 1.0);
    if (t < 0.25) {
        float s = t / 0.25;
        return vec3(
            0.267 + s * (0.229 - 0.267),
            0.004 + s * (0.322 - 0.004),
            0.329 + s * (0.545 - 0.329)
        );
    } else if (t < 0.5) {
        float s = (t - 0.25) / 0.25;
        return vec3(
            0.229 + s * (0.127 - 0.229),
            0.322 + s * (0.563 - 0.322),
            0.545 + s * (0.562 - 0.545)
        );
    } else if (t < 0.75) {
        float s = (t - 0.5) / 0.25;
        return vec3(
            0.127 + s * (0.208 - 0.127),
            0.563 + s * (0.718 - 0.563),
            0.562 + s * (0.394 - 0.562)
        );
    } else {
        float s = (t - 0.75) / 0.25;
        return vec3(
            0.208 + s * (0.993 - 0.208),
            0.718 + s * (0.906 - 0.718),
            0.394 + s * (0.144 - 0.394)
        );
    }
}

// Plasma colormap implementation
vec3 plasma(float t) {
    t = clamp(t, 0.0, 1.0);
    if (t < 0.33) {
        float s = t / 0.33;
        return vec3(
            0.050 + s * (0.574 - 0.050),
            0.029 + s * (0.104 - 0.029),
            0.527 + s * (0.593 - 0.527)
        );
    } else if (t < 0.66) {
        float s = (t - 0.33) / 0.33;
        return vec3(
            0.574 + s * (0.897 - 0.574),
            0.104 + s * (0.463 - 0.104),
            0.593 + s * (0.094 - 0.593)
        );
    } else {
        float s = (t - 0.66) / 0.34;
        return vec3(
            0.897 + s * (0.940 - 0.897),
            0.463 + s * (0.975 - 0.463),
            0.094 + s * (0.131 - 0.094)
        );
    }
}

// Hot colormap implementation
vec3 hot(float t) {
    t = clamp(t, 0.0, 1.0);
    if (t < 0.33) {
        float s = t / 0.33;
        return vec3(s, 0.0, 0.0);
    } else if (t < 0.66) {
        float s = (t - 0.33) / 0.33;
        return vec3(1.0, s, 0.0);
    } else {
        float s = (t - 0.66) / 0.34;
        return vec3(1.0, 1.0, s);
    }
}

void main() {
    if (use_texture) {
        vec4 tex_color = texture(image, v_texcoord);
        
        // Get the intensity value (assuming single channel or grayscale)
        float intensity = tex_color.r;
        
        // Check for NaN marker (-1.0) or invalid values
        if (intensity < 0.0) {
            FragColor = nan_color;
            return;
        }
        
        // Apply colormap based on type
        vec3 color;
        if (colormap_type == 0) {
            // Grayscale
            color = vec3(intensity);
        } else if (colormap_type == 1) {
            // Viridis
            color = viridis(intensity);
        } else if (colormap_type == 2) {
            // Plasma
            color = plasma(intensity);
        } else if (colormap_type == 3) {
            // Hot
            color = hot(intensity);
        } else {
            // Default to grayscale
            color = vec3(intensity);
        }
        
        FragColor = vec4(color, 1.0);
    } else {
        FragColor = v_color;
    }
}
"""

const plot_image_prog = Ref{GLA.Program}()
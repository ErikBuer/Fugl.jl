# Adding your own shaders

Fugl.jl provides a flexible system for external packages to register their own custom shaders. This allows you to create specialized rendering components while maintaining proper integration with Fugl's initialization system.

## Overview

External packages can register shader initialization functions that will be called automatically when Fugl initializes its OpenGL context. This ensures that your custom shaders are compiled and ready to use when your components need them.

## Basic Usage

### 1. Create your shader initialization function

```julia
using Fugl
using GLAbstraction
const GLA = GLAbstraction

# Define your shaders
const my_vertex_shader = GLA.vert"""
#version 330 core
layout(location = 0) in vec2 position;
layout(location = 1) in vec4 color;

out vec4 v_color;
uniform mat4 projection;

void main() {
    gl_Position = projection * vec4(position, 0.0, 1.0);
    v_color = color;
}
"""

const my_fragment_shader = GLA.frag"""
#version 330 core
in vec4 v_color;
out vec4 FragColor;

void main() {
    FragColor = v_color;
}
"""

# Global references to store compiled programs
const my_program = Ref{GLA.Program}()

# Initialization function
function initialize_my_shaders()
    my_program[] = GLA.Program(my_vertex_shader, my_fragment_shader)
    @info "My custom shaders initialized successfully"
end
```

### 2. Register your initialization function

In your package's `__init__()` function:

```julia
function __init__()
    Fugl.register_shader_initializer!(initialize_my_shaders)
end
```

### 3. Use your shaders in components

```julia
function my_custom_render_function()
    # Your shaders are now available
    GLA.bind(my_program[])
    # ... render your custom content
end
```

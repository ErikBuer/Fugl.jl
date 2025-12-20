using FileIO, ImageCore

function create_offscreen_framebuffer(width::Int, height::Int)
    framebuffer = Ref{UInt32}(0)
    ModernGL.glGenFramebuffers(1, framebuffer)

    # Use GL state management for both framebuffer and viewport
    push_framebuffer!(framebuffer[])

    texture = Ref{UInt32}(0)
    ModernGL.glGenTextures(1, texture)
    ModernGL.glBindTexture(ModernGL.GL_TEXTURE_2D, texture[])
    ModernGL.glTexImage2D(ModernGL.GL_TEXTURE_2D, 0, ModernGL.GL_RGB, width, height, 0, ModernGL.GL_RGB, ModernGL.GL_UNSIGNED_BYTE, C_NULL)
    ModernGL.glTexParameteri(ModernGL.GL_TEXTURE_2D, ModernGL.GL_TEXTURE_MIN_FILTER, ModernGL.GL_LINEAR)
    ModernGL.glTexParameteri(ModernGL.GL_TEXTURE_2D, ModernGL.GL_TEXTURE_MAG_FILTER, ModernGL.GL_LINEAR)

    ModernGL.glFramebufferTexture2D(ModernGL.GL_FRAMEBUFFER, ModernGL.GL_COLOR_ATTACHMENT0, ModernGL.GL_TEXTURE_2D, texture[], 0)

    if ModernGL.glCheckFramebufferStatus(ModernGL.GL_FRAMEBUFFER) != ModernGL.GL_FRAMEBUFFER_COMPLETE
        error("Framebuffer is not complete!")
    end

    # Restore previous framebuffer
    pop_framebuffer!()

    return framebuffer[], texture[]
end

function screenshot(ui_function::Function, output_file::String, width::Int, height::Int)

    # Initialize GLFW window (offscreen context)
    gl_window = GLFW.Window(name="Offscreen", resolution=(width, height))
    GLA.set_context!(gl_window)
    GLFW.MakeContextCurrent(gl_window)

    ModernGL.glEnable(ModernGL.GL_BLEND)
    ModernGL.glBlendFunc(ModernGL.GL_SRC_ALPHA, ModernGL.GL_ONE_MINUS_SRC_ALPHA)

    initialize_shaders()
    initialize_plot_shaders()
    initialize_gl_state!()  # Initialize GL state management for offscreen context

    root_view::AbstractView = ui_function()

    framebuffer, texture = create_offscreen_framebuffer(width, height)

    # Use the new GL state management for both framebuffer and viewport
    push_framebuffer!(framebuffer)
    push_viewport!(Int32(0), Int32(0), Int32(width), Int32(height))
    ModernGL.glClear(ModernGL.GL_COLOR_BUFFER_BIT)

    # Initialize hover registry for screenshot
    init_hover_registry!()

    projection_matrix = get_orthographic_matrix(0.0f0, Float32(width), Float32(height), 0.0f0, -1.0f0, 1.0f0)

    interpret_view(root_view, 0.0f0, 0.0f0, Float32(width), Float32(height), projection_matrix, 0.0f0, 0.0f0)

    buffer = Array{UInt8}(undef, 3, width, height)  # RGB format
    ModernGL.glReadPixels(0, 0, width, height, ModernGL.GL_RGB, ModernGL.GL_UNSIGNED_BYTE, buffer)

    flipped_buffer = reverse(buffer, dims=3)

    img = permutedims(flipped_buffer, (3, 2, 1))  # Convert to (width, height, channels)
    save(output_file, img)

    # Restore GL state and cleanup
    pop_viewport!()
    pop_framebuffer!()
    ModernGL.glDeleteFramebuffers(1, Ref(framebuffer))
    ModernGL.glDeleteTextures(1, Ref(texture))
    GLFW.DestroyWindow(gl_window)

    clear_texture_cache!()
    clear_font_cache!()
    clear_glyph_atlas!()
    clear_text_batch!()
    clear_render_caches!()
end

"""
    render_no_overlay(frame_count, fps, screen_width, screen_height, projection_matrix)

No-op function for when FPS overlay is disabled. This gets optimized away by the compiler.
"""
@inline function render_no_overlay(frame_count::Int, fps::Float64, screen_width::Float32, screen_height::Float32, projection_matrix)
    # Intentionally empty - this function does nothing and should be optimized away
    nothing
end

"""
    update_no_fps_stats(debug_frame_count, debug_last_time, frame_start_time, debug_fps_update_interval, current_fps)

No-op function for when FPS overlay is disabled. Returns unchanged debug_fps value.
"""
@inline function update_no_fps_stats(debug_frame_count::Ref{Int}, debug_last_time::Ref{Float64}, frame_start_time::Float64, debug_fps_update_interval::Float64, current_fps::Ref{Float64})
    # Intentionally empty - this function does nothing and should be optimized away
    return 0.0  # Return dummy FPS value
end

"""
    update_fps_stats!(debug_frame_count, debug_last_time, frame_start_time, debug_fps_update_interval, current_fps)

Update FPS statistics when overlay is enabled. Returns current FPS value.
"""
function update_fps_stats!(debug_frame_count::Ref{Int}, debug_last_time::Ref{Float64}, frame_start_time::Float64, debug_fps_update_interval::Float64, current_fps::Ref{Float64})
    debug_frame_count[] += 1
    current_time = frame_start_time

    # Update FPS every interval
    if current_time - debug_last_time[] >= debug_fps_update_interval
        elapsed = current_time - debug_last_time[]
        fps = debug_frame_count[] / elapsed
        debug_frame_count[] = 0
        debug_last_time[] = current_time
        current_fps[] = fps  # Store the new FPS value
    end

    return current_fps[]  # Always return the current FPS value
end

"""
    render_fps_overlay(frame_count, fps, screen_width, screen_height, projection_matrix)

Render debug overlay showing frame count and FPS in the upper right corner.
"""
function render_fps_overlay(frame_count::Int, fps::Float64, screen_width::Float32, screen_height::Float32, projection_matrix)
    # Format debug text
    debug_text = "Frame: $frame_count | FPS: $(round(fps, digits=1))"

    # Create text style for debug overlay
    debug_style = TextStyle(
        size_px=14,
        color=Vec4f(1.0, 1.0, 1.0, 0.8)  # Light gray text
    )

    # Measure text to position it correctly
    text_width = measure_word_width(debug_style.font, debug_text, debug_style.size_px)
    text_height = Float32(debug_style.size_px)

    # Position in upper right corner with some  padding
    padding = 0.0f0
    x = screen_width - text_width - padding
    y = padding + text_height  # Add text height because text is drawn from baseline

    # Draw background rectangle first
    bg_padding = 5.0f0
    bg_x = x - bg_padding
    bg_y = padding
    bg_width = text_width + 2 * bg_padding
    bg_height = text_height + 2 * bg_padding

    # Create vertices for background rectangle
    bg_vertices = [
        Point2f(bg_x, bg_y),                    # Top-left
        Point2f(bg_x, bg_y + bg_height),        # Bottom-left  
        Point2f(bg_x + bg_width, bg_y + bg_height),  # Bottom-right
        Point2f(bg_x + bg_width, bg_y),         # Top-right
    ]

    try
        # Draw semi-transparent background rectangle
        draw_rectangle(bg_vertices, Vec4f(0.0, 0.0, 0.0, 0.7), projection_matrix)

        # Draw the debug text on top
        draw_text(debug_style.font, debug_text, x, y, debug_style.size_px, projection_matrix, debug_style.color)
    catch e
        # If drawing fails, silently ignore to avoid breaking the main UI
        # This can happen during startup when shaders aren't ready
    end
end
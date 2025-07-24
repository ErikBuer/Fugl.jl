using FileIO, ImageCore

function create_offscreen_framebuffer(width::Int, height::Int)
    framebuffer = Ref{UInt32}(0)
    ModernGL.glGenFramebuffers(1, framebuffer)
    ModernGL.glBindFramebuffer(ModernGL.GL_FRAMEBUFFER, framebuffer[])

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

    return framebuffer[], texture[]
end

function screenshot(ui_funciton::Function, output_file::String, width::Int, height::Int)

    # Initialize GLFW window (offscreen context)
    gl_window = GLFW.Window(name="Offscreen", resolution=(width, height))
    GLA.set_context!(gl_window)
    GLFW.MakeContextCurrent(gl_window)


    ModernGL.glEnable(ModernGL.GL_BLEND)
    ModernGL.glBlendFunc(ModernGL.GL_SRC_ALPHA, ModernGL.GL_ONE_MINUS_SRC_ALPHA)

    initialize_shaders()

    root_view::AbstractView = ui_funciton()

    framebuffer, texture = create_offscreen_framebuffer(width, height)
    ModernGL.glBindFramebuffer(ModernGL.GL_FRAMEBUFFER, framebuffer)
    ModernGL.glViewport(0, 0, width, height)
    ModernGL.glClear(ModernGL.GL_COLOR_BUFFER_BIT)

    projection_matrix = get_orthographic_matrix(0.0f0, Float32(width), Float32(height), 0.0f0, -1.0f0, 1.0f0)

    interpret_view(root_view, 0.0f0, 0.0f0, Float32(width), Float32(height), projection_matrix)

    buffer = Array{UInt8}(undef, 3, width, height)  # RGB format
    ModernGL.glReadPixels(0, 0, width, height, ModernGL.GL_RGB, ModernGL.GL_UNSIGNED_BYTE, buffer)

    flipped_buffer = reverse(buffer, dims=3)

    img = permutedims(flipped_buffer, (3, 2, 1))  # Convert to (width, height, channels)
    save(output_file, img)

    ModernGL.glDeleteFramebuffers(1, Ref(framebuffer))
    ModernGL.glDeleteTextures(1, Ref(texture))
    GLFW.DestroyWindow(gl_window)
end

"""
    render_debug_overlay(frame_count, fps, screen_width, screen_height, projection_matrix)

Render debug overlay showing frame count and FPS in the upper right corner.
"""
function render_debug_overlay(frame_count::Int, fps::Float64, screen_width::Float32, screen_height::Float32, projection_matrix)
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
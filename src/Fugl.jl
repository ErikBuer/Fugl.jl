module Fugl

using ModernGL, GLAbstraction, GLFW # OpenGL dependencies
const GLA = GLAbstraction
using FreeTypeAbstraction # Font rendering dependencies
using GeometryBasics
using IndirectArrays
export Vec4f, Vec4

const OPENGL_LOCK = ReentrantLock()

include("matrices.jl")

include("shaders.jl")
export initialize_shaders

include("input_state.jl")
export MouseButton, ButtonState, IsReleased, IsPressed, InputState, mouse_button_callback, mouse_position_callback, char_callback, KeyEvent
export ButtonState, IsPressed, IsReleased
export mouse_state, mouse_button_callback, InputState

include("abstract_view.jl")
export AbstractView, SizedView

include("components.jl")

include("test_utilitites.jl")
export screenshot

"""
    run(ui_ref[]::AbstractView; title::String="Fugl", window_width_px::Integer=1920, window_height_px::Integer=1080, fps_overlay::Bool=false)

Run the main loop for the GUI application.
This function handles the rendering and event processing for the GUI.

# Arguments
- `ui_function::Function`: Function that returns an AbstractView for the UI
- `title::String="Fugl"`: Window title
- `window_width_px::Integer=1920`: Initial window width
- `window_height_px::Integer=1080`: Initial window height
- `fps_overlay::Bool=false`: Show frame count and FPS in upper right corner
"""
function run(ui_function::Function; title::String="Fugl", window_width_px::Integer=1920, window_height_px::Integer=1080, fps_overlay::Bool=false)
    # Initialize the GLFW window
    gl_window = GLFW.Window(name=title, resolution=(window_width_px, window_height_px))
    GLA.set_context!(gl_window)
    GLFW.MakeContextCurrent(gl_window)

    # Enable alpha blending
    glEnable(GL_BLEND)
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)

    initialize_shaders()
    initialize_plot_shaders()

    # Initialize local states
    mouse_state = InputState()

    # Store callbacks in local variables to prevent GC
    mouse_callback = (gl_window, button, action, mods) -> mouse_button_callback(gl_window, button, action, mods, mouse_state)
    mouse_pos_callback = (gl_window, xpos, ypos) -> mouse_position_callback(gl_window, xpos, ypos, mouse_state)
    key_callback_func = (gl_window, key, scancode, action, mods) -> key_callback(gl_window, key, scancode, action, mods, mouse_state)
    char_callback_func = (gl_window, codepoint) -> char_callback(gl_window, codepoint, mouse_state)

    GLFW.SetMouseButtonCallback(gl_window, mouse_callback)
    GLFW.SetCursorPosCallback(gl_window, mouse_pos_callback)
    GLFW.SetKeyCallback(gl_window, key_callback_func)
    GLFW.SetCharCallback(gl_window, char_callback_func)

    projection_matrix = get_orthographic_matrix(0.0f0, Float32(window_width_px), Float32(window_height_px), 0.0f0, -1.0f0, 1.0f0)

    # Track frame count for GC management and debug overlay
    frame_count = 0
    last_ui = nothing  # Keep reference to prevent premature GC
    last_frame_time = time()  # Track frame timing for freeze detection

    # Debug overlay timing variables
    debug_frame_count = 0
    debug_last_time = time()
    debug_fps = 0.0
    debug_fps_update_interval = 0.5  # Update FPS every 0.5 seconds

    try
        # Main loop
        while !GLFW.WindowShouldClose(gl_window)
            frame_start_time = time()
            frame_count += 1

            # Update debug overlay stats if enabled
            if fps_overlay
                debug_frame_count += 1
                current_time = frame_start_time

                # Update FPS every interval
                if current_time - debug_last_time >= debug_fps_update_interval
                    elapsed = current_time - debug_last_time
                    debug_fps = debug_frame_count / elapsed
                    debug_frame_count = 0
                    debug_last_time = current_time
                end
            end

            # Detect if previous frame took too long (freeze detection)
            frame_duration = frame_start_time - last_frame_time
            if frame_duration > 1.0  # More than 1 second for a frame
                @warn "Slow frame detected: $(round(frame_duration, digits=2))s - possible freeze recovery"
                # Force garbage collection to free any leaked resources
                GC.gc(true)
                # Clear any accumulated input to prevent further overflow
                empty!(mouse_state.key_buffer)
                empty!(mouse_state.key_events)
            end
            last_frame_time = frame_start_time

            # Update window size
            window_width, window_height = GLFW.GetWindowSize(gl_window)
            fb_width, fb_height = GLFW.GetFramebufferSize(gl_window)
            scale_x = fb_width / window_width
            scale_y = fb_height / window_height

            # Poll mouse position  
            mouse_state.x, mouse_state.y = Tuple(GLFW.GetCursorPos(gl_window))
            mouse_state.x *= scale_x
            mouse_state.y *= scale_y

            # Update viewport and projection matrix
            glViewport(0, 0, fb_width, fb_height)
            projection_matrix = get_orthographic_matrix(0.0f0, Float32(fb_width), Float32(fb_height), 0.0f0, -1.0f0, 1.0f0)

            lock(OPENGL_LOCK) do
                # Clear the screen
                ModernGL.glClear(ModernGL.GL_COLOR_BUFFER_BIT)

                # IMPORTANT: Copy the input state immediately under lock protection
                # This prevents GLFW callbacks from modifying buffers while we're reading them
                locked_state = collect_state!(mouse_state)
                empty!(mouse_state.key_buffer)
                empty!(mouse_state.key_events)

                # Reset click flags
                for button in keys(mouse_state.was_clicked)
                    mouse_state.was_clicked[button] = false
                end

                # Generate the UI dynamically with error handling
                try
                    ui::AbstractView = ui_function()
                    last_ui = ui  # Keep reference to prevent GC during this frame

                    detect_click(ui, locked_state, 0.0f0, 0.0f0, Float32(fb_width), Float32(fb_height))
                    interpret_view(ui, 0.0f0, 0.0f0, Float32(fb_width), Float32(fb_height), projection_matrix)

                    # Render debug overlay if enabled
                    if fps_overlay
                        render_fps_overlay(frame_count, debug_fps, Float32(fb_width), Float32(fb_height), projection_matrix)
                    end


                catch e
                    @error "Error generating UI" exception = (e, catch_backtrace())
                    # Keep the last working UI alive
                    if last_ui !== nothing
                        try
                            interpret_view(last_ui, 0.0f0, 0.0f0, Float32(fb_width), Float32(fb_height), projection_matrix)
                        catch
                            # If even the last UI fails, just continue
                        end
                    end
                end

                # Periodic GC management
                if frame_count % 300 == 0
                    GC.gc(false)
                end

                # Swap buffers and poll events
                GLFW.SwapBuffers(gl_window)
            end

            # Yield control periodically to prevent task starvation
            if frame_count % 10 == 0
                yield()  # Allow other Julia tasks to run
            end

            GLFW.PollEvents()
        end
    finally
        # Clean up - destroy window first to release OpenGL context
        GLFW.DestroyWindow(gl_window)
        clear_texture_cache!()
        clear_font_cache!()
        clear_glyph_atlas!()
        clear_text_batch!()

        # Clear UI reference
        last_ui = nothing

        # Force final cleanup
        GC.gc()
    end
end

end
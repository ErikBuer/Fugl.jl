module Fugl

using ModernGL, GLAbstraction, GLFW # OpenGL dependencies
const GLA = GLAbstraction

using FreeTypeAbstraction # Font rendering dependencies

using GeometryBasics, ColorTypes    # Additional rendering dependencies

include("matrices.jl")

include("shaders.jl")
export initialize_shaders

include("input_state.jl")
export MouseButton, ButtonState, IsReleased, IsPressed, InputState, mouse_button_callback, char_callback, KeyEvent
export ButtonState, IsPressed, IsReleased
export mouse_state, mouse_button_callback, InputState

include("abstract_view.jl")
export AbstractView, SizedView

include("text/font_cache.jl")
include("text/utilities.jl")
include("text/text_style.jl")
export TextStyle
include("text/draw.jl")

include("image/utilities.jl")
include("image/draw.jl")
export clear_texture_cache!

include("gui_component/utilities.jl")
include("gui_component/draw.jl")

include("components.jl")

include("test_utilitites.jl")
export screenshot


"""
    run(ui_ref[]::AbstractView; title::String="Fugl", window_width_px::Integer=1920, window_height_px::Integer=1080)

Run the main loop for the GUI application.
This function handles the rendering and event processing for the GUI.
"""
function run(ui_function::Function; title::String="Fugl", window_width_px::Integer=1920, window_height_px::Integer=1080)
    # Initialize the GLFW window
    gl_window = GLFW.Window(name=title, resolution=(window_width_px, window_height_px))
    GLA.set_context!(gl_window)
    GLFW.MakeContextCurrent(gl_window)

    # Enable alpha blending
    glEnable(GL_BLEND)
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)

    initialize_shaders()

    # Initialize local states
    mouse_state = InputState()

    # Store callbacks in local variables to prevent GC
    mouse_callback = (gl_window, button, action, mods) -> mouse_button_callback(gl_window, button, action, mods, mouse_state)
    key_callback_func = (gl_window, key, scancode, action, mods) -> key_callback(gl_window, key, scancode, action, mods, mouse_state)
    char_callback_func = (gl_window, codepoint) -> char_callback(gl_window, codepoint, mouse_state)

    GLFW.SetMouseButtonCallback(gl_window, mouse_callback)
    GLFW.SetKeyCallback(gl_window, key_callback_func)
    GLFW.SetCharCallback(gl_window, char_callback_func)

    projection_matrix = get_orthographic_matrix(0.0f0, Float32(window_width_px), Float32(window_height_px), 0.0f0, -1.0f0, 1.0f0)

    # Track frame count for GC management
    frame_count = 0
    last_ui = nothing  # Keep reference to prevent premature GC

    try
        # Main loop
        while !GLFW.WindowShouldClose(gl_window)
            frame_count += 1

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

            # Clear the screen
            ModernGL.glClear(ModernGL.GL_COLOR_BUFFER_BIT)

            # Lock the mouse state by creating a copy
            locked_state = collect_state!(mouse_state)

            # Generate the UI dynamically with error handling
            try
                ui::AbstractView = ui_function()
                last_ui = ui  # Keep reference to prevent GC during this frame

                # Detect clicks with error handling
                try
                    detect_click(ui, locked_state, 0.0f0, 0.0f0, Float32(fb_width), Float32(fb_height))
                catch e
                    @warn "Error in click detection" exception = (e, catch_backtrace())
                end

                # Render the UI with error handling
                try
                    interpret_view(ui, 0.0f0, 0.0f0, Float32(fb_width), Float32(fb_height), projection_matrix)
                catch e
                    @warn "Error rendering UI" exception = (e, catch_backtrace())
                    # Continue to next frame instead of crashing
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

            # Clear the key buffer and key events
            empty!(mouse_state.key_buffer)
            empty!(mouse_state.key_events)

            # Periodic GC management (every 5 seconds at 60fps)
            if frame_count % 300 == 0
                # Force a gentle GC between frames to prevent buildup
                GC.gc(false)
            end

            # Swap buffers and poll events
            GLFW.SwapBuffers(gl_window)
            GLFW.PollEvents()
        end
    finally
        # Clean up - destroy window first to release OpenGL context
        GLFW.DestroyWindow(gl_window)

        # Clear texture cache to prevent stale texture references on next run
        clear_texture_cache!()

        # Clear UI reference
        last_ui = nothing

        # Force final cleanup
        GC.gc()
    end
end

end
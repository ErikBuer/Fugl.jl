module Fugl

# OpenGL dependencies
#using GLFW
include("GLFW.jl/src/GLFW.jl")
using .GLFW

include("GLAbstraction.jl/src/GLAbstraction.jl")
using .GLAbstraction
const GLA = GLAbstraction

using ModernGL

using FreeTypeAbstraction # Font rendering dependencies
using GeometryBasics
using IndirectArrays
export Vec4f, Vec4
using ColorTypes

const OPENGL_LOCK = ReentrantLock()

include("matrices.jl")
include("gl_context_state.jl")
include("interaction_state.jl")
export InteractionState
include("overlay_system.jl")
export add_overlay_function, render_overlays, clear_overlays
include("shaders.jl")
export initialize_shaders, register_shader_initializer!

include("input_state.jl")
export MouseButton, LeftButton, RightButton, MiddleButton
export InputState, mouse_position_callback, char_callback, KeyEvent
export ButtonState, IsPressed, IsReleased
export mouse_button_callback
export ModifierKeys, is_command_key, has_any_modifier

include("abstract_view.jl")
export AbstractView, SizedView, interpret_view

include("components.jl")

include("test_utilitites.jl")
export screenshot

# Render state struct for JuliaC compatibility - avoids closure boxing
mutable struct RenderState
    frame_count::Int64
    projection_matrix::Mat4{Float32}  # Use Mat4 (SMatrix) instead of Matrix
    last_ui::Union{Nothing,AbstractView}
    last_frame_time::Float64
    debug_frame_count::Int64
    debug_last_time::Float64
    debug_fps::Float64
    current_fps_value::Float64
end

function RenderState(projection_matrix::Mat4{Float32})
    RenderState(
        0,                    # frame_count
        projection_matrix,    # projection_matrix
        nothing,              # last_ui
        time(),              # last_frame_time
        0,                   # debug_frame_count
        time(),              # debug_last_time
        0.0,                 # debug_fps
        0.0                  # current_fps_value
    )
end

# Helper functions for conditional FPS overlay
function render_no_overlay(frame_count, fps, fb_width, fb_height, projection_matrix)
    # Do nothing - no overlay
end

function update_no_fps_stats(state::RenderState, frame_start_time::Float64, update_interval::Float64)
    return 0.0  # No FPS tracking
end

function update_fps_stats!(state::RenderState, frame_start_time::Float64, update_interval::Float64)
    state.debug_frame_count += 1
    time_elapsed = frame_start_time - state.debug_last_time

    if time_elapsed >= update_interval
        state.debug_fps = state.debug_frame_count / time_elapsed
        state.debug_frame_count = 0
        state.debug_last_time = frame_start_time
    end

    return state.debug_fps
end

# Render a single frame - extracted to avoid closure boxing
function render_frame!(state::RenderState, gl_window, ui_function::Function, mouse_state::InputState,
    debug_overlay::Function, update_debug_stats::Function, debug_fps_update_interval::Float64)
    frame_start_time = time()
    state.frame_count += 1

    # Update debug overlay stats
    state.current_fps_value = update_debug_stats(state, frame_start_time, debug_fps_update_interval)

    # Detect if previous frame took too long (freeze detection)
    frame_duration = frame_start_time - state.last_frame_time
    if frame_duration > 5.0  # More than 5 seconds for a frame
        @warn "Slow frame detected: $(round(frame_duration, digits=2))s - possible freeze recovery"
        # Force garbage collection to free any leaked resources
        GC.gc(true)
        # Clear any accumulated input to prevent further overflow
        empty!(mouse_state.key_buffer)
        empty!(mouse_state.key_events)
    end
    state.last_frame_time = frame_start_time

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
    # Update our GL state tracker to match the current viewport
    GL_STATE.current_viewport = (0, 0, Int32(fb_width), Int32(fb_height))
    state.projection_matrix = get_orthographic_matrix(0.0f0, Float32(fb_width), Float32(fb_height), 0.0f0, -1.0f0, 1.0f0)

    # Use explicit lock/unlock instead of do-block to avoid closure
    lock(OPENGL_LOCK)
    try
        # Clear the screen
        ModernGL.glClear(ModernGL.GL_COLOR_BUFFER_BIT)

        # IMPORTANT: Copy the input state immediately under lock protection
        # This prevents GLFW callbacks from modifying buffers while we're reading them
        locked_state = collect_state!(mouse_state)
        empty!(mouse_state.key_buffer)
        empty!(mouse_state.key_events)

        # Generate the UI dynamically with error handling
        try
            ui::AbstractView = ui_function()
            state.last_ui = ui  # Keep reference to prevent GC during this frame

            click_result = detect_click(ui, locked_state, 0.0f0, 0.0f0, Float32(fb_width), Float32(fb_height), Int32(0))
            if click_result !== nothing # Run captured action
                click_result.action()
            end

            interpret_view(ui, 0.0f0, 0.0f0, Float32(fb_width), Float32(fb_height), state.projection_matrix, Float32(locked_state.x), Float32(locked_state.y))

            # Render overlays after main content
            render_overlays()

            # Framerate debug overlay
            debug_overlay(state.frame_count, state.current_fps_value, Float32(fb_width), Float32(fb_height), state.projection_matrix)

        catch e
            @error "Error generating UI" exception = (e, catch_backtrace())
            # Keep the last working UI alive
            if state.last_ui !== nothing
                try
                    interpret_view(state.last_ui, 0.0f0, 0.0f0, Float32(fb_width), Float32(fb_height), state.projection_matrix, 0.0f0, 0.0f0)
                catch
                    # If even the last UI fails, just continue
                end
            end
        end

        # Periodic GC management
        if state.frame_count % 300 == 0
            GC.gc(false)
        end

        # Swap buffers
        GLFW.SwapBuffers(gl_window)
    finally
        unlock(OPENGL_LOCK)
    end
end


"""
    run(ui_function; title::String="Fugl", window_width_px::Integer=1920, window_height_px::Integer=1080, fps_overlay::Bool=false)

Run the main loop for the GUI application.
This function handles the rendering and event processing for the GUI.

# Arguments
- `ui_function`: Function that returns an AbstractView for the UI
- `title::String="Fugl"`: Window title
- `window_width_px::Integer=1920`: Initial window width
- `window_height_px::Integer=1080`: Initial window height
- `fps_overlay::Bool=false`: Show frame count and FPS in upper right corner

# Examples
```julia

run(MyApp)
```
"""
function run(ui_function; title::String="Fugl", window_width_px::Integer=1920, window_height_px::Integer=1080, fps_overlay::Bool=false)
    # Initialize GLFW
    GLFW.Init()

    # Initialize the GLFW window with explicit empty hints to avoid JuliaC dynamic dispatch issues
    gl_window = GLFW.Window(
        name=title,
        resolution=(window_width_px, window_height_px),
        #windowhints=[],  # Empty hints to avoid dynamic dispatch
        #contexthints=[]  # Empty context hints too
    )

    # Try GLAbstraction context management, but handle JuliaC compatibility
    try
        GLA.set_context!(gl_window)
    catch e
        # JuliaC compilation may not support GLAbstraction's context management
        # Skip it - GLFW.MakeContextCurrent should be sufficient for single-window apps
        @warn "GLAbstraction context management failed: $(e)"
    end

    GLFW.MakeContextCurrent(gl_window)

    # Enable alpha blending
    glEnable(GL_BLEND)
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)

    initialize_shaders()
    initialize_plot_shaders()
    initialize_gl_state!()

    # Load default font if not already loaded
    # Try safe mode first to handle static compilation gracefully
    font_result = get_default_font(safe_mode=true)
    if font_result === nothing
        @warn "Font loading failed in safe mode - this may be due to static compilation environment"
    end

    # Initialize local states
    mouse_state = InputState()

    # Initialize C function pointers for JuliaC compatibility
    GLFW.__init_callbacks__()

    # Set the input state for callbacks - they'll directly modify it (no function storage)
    GLFW.set_input_state!(mouse_state)

    # Use the low-level C pointer API
    GLFW.SetMouseButtonCallbackPtr(gl_window, GLFW.C_MOUSE_BUTTON_CALLBACK_PTR[])
    GLFW.SetCursorPosCallbackPtr(gl_window, GLFW.C_CURSOR_POS_CALLBACK_PTR[])
    GLFW.SetKeyCallbackPtr(gl_window, GLFW.C_KEY_CALLBACK_PTR[])
    GLFW.SetCharCallbackPtr(gl_window, GLFW.C_CHAR_CALLBACK_PTR[])
    GLFW.SetScrollCallbackPtr(gl_window, GLFW.C_SCROLL_CALLBACK_PTR[])

    projection_matrix = get_orthographic_matrix(0.0f0, Float32(window_width_px), Float32(window_height_px), 0.0f0, -1.0f0, 1.0f0)

    # Initialize render state - no closure boxing
    state = RenderState(projection_matrix)

    # Debug overlay timing variables
    debug_fps_update_interval = 0.5  # Update FPS every 0.5 seconds

    # Choose overlay function at compile time based on fps_overlay flag
    debug_overlay = fps_overlay ? render_fps_overlay : render_no_overlay

    # Choose debug stats update function at compile time based on fps_overlay flag
    update_debug_stats = fps_overlay ? update_fps_stats! : update_no_fps_stats

    try
        # Main loop
        while !GLFW.WindowShouldClose(gl_window)
            # Use invokelatest to force runtime dispatch - required for JuliaC trim mode compatibility
            Base.invokelatest(render_frame!, state, gl_window, ui_function, mouse_state, debug_overlay, update_debug_stats, debug_fps_update_interval)

            # Yield control periodically to prevent task starvation
            if state.frame_count % 10 == 0
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
        clear_render_caches!()

        # Terminate GLFW
        GLFW.Terminate()

        # Clear UI reference
        state.last_ui = nothing

        # Force final cleanup
        GC.gc()
    end
end

end
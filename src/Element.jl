module Element

using ModernGL, GLAbstraction, GLFW # OpenGL dependencies
const GLA = GLAbstraction

using FreeTypeAbstraction # Font rendering dependencies

using GeometryBasics, ColorTypes    # Additional rendering dependencies

include("matrices.jl")

include("shaders.jl")
export initialize_shaders

include("mouse_state.jl")
export MouseButton, ButtonState, IsReleased, IsPressed, MouseState, mouse_button_callback
export ButtonState, IsPressed, IsReleased
export mouse_state, mouse_button_callback, MouseState

include("abstract_view.jl")
export AbstractView

include("text/font_cache.jl")
include("text/utilities.jl")
include("text/text_style.jl")
export TextStyle
include("text/draw.jl")

include("image/utilities.jl")
include("image/draw.jl")

include("gui_component/utilities.jl")
include("gui_component/draw.jl")

include("components.jl")

include("test_utilitites.jl")
export screenshot


"""
    run(ui_ref[]::AbstractView; title::String="Element", window_width_px::Integer=1920, window_height_px::Integer=1080)

Run the main loop for the GUI application.
This function handles the rendering and event processing for the GUI.
"""
function run(ui_function::Function; title::String="Element", window_width_px::Integer=1920, window_height_px::Integer=1080)
    # Initialize the GLFW window
    gl_window = GLFW.Window(name=title, resolution=(window_width_px, window_height_px))
    GLA.set_context!(gl_window)
    GLFW.MakeContextCurrent(gl_window)

    # Enable alpha blending
    glEnable(GL_BLEND)
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)

    initialize_shaders()

    # Initialize local states
    mouse_state = MouseState()
    GLFW.SetMouseButtonCallback(gl_window, (gl_window, button, action, mods) -> mouse_button_callback(gl_window, button, action, mods, mouse_state))
    GLFW.SetKeyCallback(gl_window, (gl_window, key, scancode, action, mods) -> key_callback(gl_window, key, scancode, action, mods, mouse_state))

    projection_matrix = get_orthographic_matrix(0.0f0, Float32(window_width_px), Float32(window_height_px), 0.0f0, -1.0f0, 1.0f0)

    # Main loop
    while !GLFW.WindowShouldClose(gl_window)
        # Update window size
        width_px, height_px = GLFW.GetFramebufferSize(gl_window)

        # Update viewport and projection matrix
        glViewport(0, 0, width_px, height_px)
        projection_matrix = get_orthographic_matrix(0.0f0, Float32(width_px), Float32(height_px), 0.0f0, -1.0f0, 1.0f0)

        # Clear the screen
        ModernGL.glClear(ModernGL.GL_COLOR_BUFFER_BIT)

        # Poll mouse position
        mouse_state.x, mouse_state.y = Tuple(GLFW.GetCursorPos(gl_window))

        # Lock the mouse state by creating a copy
        locked_state = collect_state!(mouse_state)

        # Generate the UI dynamically
        ui::AbstractView = ui_function()

        # Detect clicks
        detect_click(ui, locked_state, 0.0f0, 0.0f0, Float32(width_px), Float32(height_px))

        # Render the UI
        interpret_view(ui, 0.0f0, 0.0f0, Float32(width_px), Float32(height_px), projection_matrix)

        # Clear the key buffer
        empty!(mouse_state.key_buffer)

        # Swap buffers and poll events
        GLFW.SwapBuffers(gl_window)
        GLFW.PollEvents()
    end

    # Clean up
    GLFW.DestroyWindow(gl_window)
end

end
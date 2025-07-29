using Fugl
using ModernGL, GeometryBasics, GLAbstraction, GLFW
const GLA = GLAbstraction

include("../src/plot/shaders.jl")
include("../src/plot/draw.jl")

function test_simple_line_plotting()
    # Initialize GLFW
    GLFW.Init()

    # Set up window hints
    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, 3)
    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, 3)
    GLFW.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE)

    # Create window
    window = GLFW.CreateWindow(800, 600, "Simple Line Plot Test")
    GLFW.MakeContextCurrent(window)

    # Initialize OpenGL loader (ModernGL)
    gl_context = OpenGL.create_context(window)

    # Initialize our plot shaders
    initialize_plot_shaders()

    # Enable blending for anti-aliasing
    glEnable(GL_BLEND)
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)

    # Create projection matrix (orthographic for 2D)
    projection = [
        2.0f0/800.0f0 0.0f0 0.0f0 -1.0f0;
        0.0f0 -2.0f0/600.0f0 0.0f0 1.0f0;
        0.0f0 0.0f0 1.0f0 0.0f0;
        0.0f0 0.0f0 0.0f0 1.0f0
    ]

    # Generate some test data
    x_data = Float32[0, 100, 200, 300, 400, 500, 600, 700, 800]
    y_data = Float32[300, 200, 400, 150, 450, 250, 350, 100, 300]

    # Simple coordinate transform (just pass through since we're in pixel coordinates)
    function identity_transform(x::Float32, y::Float32)
        return (x, y)
    end

    # Line color and width
    line_color = Vec4{Float32}(1.0f0, 0.0f0, 0.0f0, 1.0f0)  # Red
    line_width = 5.0f0

    println("Starting rendering loop...")

    # Main loop
    while !GLFW.WindowShouldClose(window)
        # Clear screen
        glClearColor(0.2f0, 0.3f0, 0.3f0, 1.0f0)
        glClear(GL_COLOR_BUFFER_BIT)

        # Draw the line
        try
            draw_line_plot(
                x_data,
                y_data,
                identity_transform,
                line_color,
                line_width,
                projection
            )
            println("Drew line successfully")
        catch e
            println("Error drawing line: ", e)
            break
        end

        # Swap buffers and poll events
        GLFW.SwapBuffers(window)
        GLFW.PollEvents()

        # Exit after a short time for testing
        sleep(0.1)
        if time() > 5  # Exit after 5 seconds
            break
        end
    end

    # Cleanup
    GLFW.DestroyWindow(window)
    GLFW.Terminate()
end

# Run the test
if abspath(PROGRAM_FILE) == @__FILE__
    test_simple_line_plotting()
end

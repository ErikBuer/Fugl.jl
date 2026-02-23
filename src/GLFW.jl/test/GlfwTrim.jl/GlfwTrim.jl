module GlfwTrim

using GLFW

"""
    @main(ARGS)

Main entry point for the GLFW static compilation example.
Creates a basic GLFW window and runs a simple event loop.
Note: Uses hardcoded callbacks for static compilation compatibility.
"""

function main(ARGS)::Int
    try
        # Initialize GLFW
        GLFW.Init()

        # Create visible window for demonstration (remove invisible hint)
        window = GLFW.CreateWindow(640, 480, "GLFW.jl Static Compilation Example")

        if window == C_NULL
            GLFW.Terminate()
            return 1
        end

        # Make the window's context current
        GLFW.MakeContextCurrent(window)

        # Set up key callback for ESC to close - use static callback for compilation compatibility
        GLFW.SetKeyCallback(window)

        # Run main loop
        frame_count = 0

        while !GLFW.WindowShouldClose(window)
            frame_count += 1

            # Minimal rendering operations
            GLFW.SwapBuffers(window)
            GLFW.PollEvents()
        end

        GLFW.DestroyWindow(window)
        GLFW.Terminate()


        return 0

    catch e
        @error "An error occurred: $e"
        try
            GLFW.Terminate()  # Ensure cleanup
        catch
            # Ignore cleanup errors
        end
        return 1
    end
end

end # module

function @main(ARGS)
    GlfwTrim.main(ARGS)
end
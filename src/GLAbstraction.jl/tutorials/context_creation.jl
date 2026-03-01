import GLFW  # we focus exclusively on the GLFW approach
using ModernGL

# The GLFW package calls GLFW.Init() automatically when loaded, so we
# don't need to call it explicitly.

# Specify minimum versions
GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, 3)  # minimum OpenGL v. 3
GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, 2)  # minimum OpenGL v. 3.2
GLFW.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE)
GLFW.WindowHint(GLFW.OPENGL_FORWARD_COMPAT, GL_TRUE)

# Create the window
GLFW.WindowHint(GLFW.RESIZABLE, GL_FALSE)
window = GLFW.CreateWindow(800, 600, "Context creation")  # windowed
# window = GLFW.CreateWindow(800, 600, "Context creation", GLFW.GetPrimaryMonitor())  # fullscreen
GLFW.MakeContextCurrent(window)

# This is a touch added from
#   http://www.opengl-tutorial.org/beginners-tutorials/tutorial-1-opening-a-window/:
# Retain keypress events until the next call to GLFW.GetKey, even if
# the key has been released in the meantime
GLFW.SetInputMode(window, GLFW.STICKY_KEYS, GL_TRUE)

# Draw nothing, while waiting for a close event
while !GLFW.WindowShouldClose(window)
    GLFW.SwapBuffers(window)
    GLFW.PollEvents()
    if GLFW.GetKey(window, GLFW.KEY_ESCAPE) == GLFW.PRESS
        GLFW.SetWindowShouldClose(window, true)
    end
end

GLFW.DestroyWindow(window)  # needed if you're running this from the REPL

# GLFW.Terminate() is called automatically upon exit

module GLFW

using GLFW_jll

# For static compilation, use the bundled library from GLFW_jll
const libglfw = GLFW_jll.libglfw

# Simple callback type for compatibility
const Callback = Union{Function,Nothing}

struct ThreadAssertionError
    target_thread::Int
    current_thread::Int
end

"""
	ThreadAssertionError(target_thread[, current_thread = Threads.threadid()])

The currently used thread is different from the `target_thread` that must be used.
"""
ThreadAssertionError(target) = ThreadAssertionError(target, Threads.threadid())

function Base.showerror(io::IO, e::ThreadAssertionError)
    print(io, "ThreadAssertionError: Code must run on thread $(e.target_thread) but ran on thread $(e.current_thread).")
end

const ENABLE_THREAD_ASSERTIONS = Ref(get(ENV, "GLFW_ENABLE_THREAD_ASSERTIONS", "true") == "true")

# The GLFW docs notes on most function that they should only be called from the main thread
function require_main_thread()
    if ENABLE_THREAD_ASSERTIONS[] && Threads.threadid() != 1
        throw(ThreadAssertionError(1))
    end
    return
end

macro require_main_thread(code)
    esc(quote
        require_main_thread()
        $code
    end)
end

function GetVersion()
    # any thread
    major, minor, rev = Ref{Cint}(), Ref{Cint}(), Ref{Cint}()
    ccall((:glfwGetVersion, libglfw), Cvoid, (Ref{Cint}, Ref{Cint}, Ref{Cint}), major, minor, rev)
    VersionNumber(major[], minor[], rev[])
end

include("glfw3.jl")
include("callback.jl")
include("vulkan.jl")
include("monitor_properties.jl")

# Initialize GLFW for static compilation
function Init()
    require_main_thread()

    # Initialize GLFW
    result = ccall((:glfwInit, libglfw), Cint, ())
    if result == 0
        error("Failed to initialize GLFW")
    end

    # Set up static callbacks
    SetErrorCallback()

    return nothing
end

end

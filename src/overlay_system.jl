# Simple overlay system for rendering components on top of everything else

# Global overlay function vector - functions to be called after main rendering
const OVERLAY_FUNCTIONS = Function[]

"""
    add_overlay_function(func::Function)

Add a function to be rendered as an overlay after all main content is rendered.
The function should take no arguments and handle its own rendering.
"""
function add_overlay_function(func::Function)
    push!(OVERLAY_FUNCTIONS, func)
end

"""
    render_overlays()

Render all overlay functions and clear the overlay list.
This should be called after all main content is rendered.
"""
function render_overlays()
    for func in OVERLAY_FUNCTIONS
        func()
    end
    empty!(OVERLAY_FUNCTIONS)
end

"""
    clear_overlays()

Clear all pending overlay functions without rendering them.
Useful for cleanup or when aborting rendering.
"""
function clear_overlays()
    empty!(OVERLAY_FUNCTIONS)
end
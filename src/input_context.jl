"""
Input Context — hit-test clip stack

Mirrors the render-side scissor stack (`push_scissor!`/`with_scissor_clip` in
`gl_context_state.jl`), but for the `detect_click` input pass and in **effective-point
space** rather than hardware pixels. Its job is to make pointer hit-testing respect the
same clipping the renderer applies: content scrolled outside a viewport (or otherwise
clipped) must not be considered "under the pointer", even though its layout rect extends
beyond the visible region.

The stack is traversal-scoped and only touched during the single-threaded `detect_click`
pass (under `OPENGL_LOCK`), so a module-global mutable context is safe and lets us avoid
threading an extra argument through every `detect_click` signature.

Keyboard delivery is intentionally NOT governed by this stack — a focused component keeps
receiving keys even when scrolled out of view. Only pointer target-ness consults the clip.
"""
mutable struct InputContext
    clip_stack::Vector{Union{Nothing,Tuple{Float32,Float32,Float32,Float32}}}  # Saved clips (nothing = unclipped)
    current_clip::Union{Nothing,Tuple{Float32,Float32,Float32,Float32}}        # Active clip rect (nothing = unclipped)

    InputContext() = new(Union{Nothing,Tuple{Float32,Float32,Float32,Float32}}[], nothing)
end

# Global input context tracker (traversal-scoped, single-threaded under OPENGL_LOCK)
const INPUT_CONTEXT = InputContext()

"""
Reset the input clip stack to "unclipped". Called once per frame before the `detect_click`
pass so a stray push/pop imbalance can't leak a clip into the next frame.
"""
function reset_input_clip!()
    empty!(INPUT_CONTEXT.clip_stack)
    INPUT_CONTEXT.current_clip = nothing
    return nothing
end

"""
Push a new hit-test clip rect (effective-point space), intersected with the currently
active clip (if any) so nested clips can only shrink the effective region, never grow it —
mirroring `push_scissor!`. Uses the shared `intersect_rect` helper so the input clip and
render scissor geometry stay identical.
"""
function push_input_clip!(x::Float32, y::Float32, width::Float32, height::Float32)
    push!(INPUT_CONTEXT.clip_stack, INPUT_CONTEXT.current_clip)

    previous = INPUT_CONTEXT.current_clip
    INPUT_CONTEXT.current_clip = previous === nothing ? (x, y, width, height) :
                                 intersect_rect((x, y, width, height), previous)
    return nothing
end

"""
Pop the previous hit-test clip rect off the stack and restore it.
"""
function pop_input_clip!()
    if !isempty(INPUT_CONTEXT.clip_stack)
        INPUT_CONTEXT.current_clip = pop!(INPUT_CONTEXT.clip_stack)
    else
        @warn "Attempting to pop from empty input clip stack"
    end
    return nothing
end

"""
Run `f` with a hit-test clip active for `(x, y, width, height)` (effective-point space),
intersected with any enclosing clip. The previous clip is always restored afterward, even
if `f` throws. Mirrors `with_scissor_clip`.
"""
function with_input_clip(f::Function, x::Float32, y::Float32, width::Float32, height::Float32)
    push_input_clip!(x, y, width, height)
    try
        return f()
    finally
        pop_input_clip!()
    end
end

"""
Get the current hit-test clip rect (`nothing` when unclipped).
"""
function current_input_clip()::Union{Nothing,Tuple{Float32,Float32,Float32,Float32}}
    return INPUT_CONTEXT.current_clip
end

"""
Whether the pointer `(px, py)` falls within the currently active hit-test clip. Always
`true` when no clip is active.
"""
function pointer_in_clip(px::Float32, py::Float32)::Bool
    clip = INPUT_CONTEXT.current_clip
    clip === nothing && return true
    cx, cy, cw, ch = clip
    return px >= cx && px <= cx + cw && py >= cy && py <= cy + ch
end

"""
    hit_test(x, y, width, height, px, py) -> Bool

Whether pointer `(px, py)` is over the rectangle `(x, y, width, height)` **and** inside the
currently active hit-test clip. This is the clip-aware replacement for a bare
`inside_component` bounds check when deciding whether a component is the pointer target.
"""
function hit_test(x::Float32, y::Float32, width::Float32, height::Float32, px::Float32, py::Float32)::Bool
    return px >= x && px <= x + width && py >= y && py <= y + height && pointer_in_clip(px, py)
end

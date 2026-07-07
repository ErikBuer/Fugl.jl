struct DropAreaView <: AbstractView
    child::AbstractView
    on_drop::Function  # Called with Vector{String} of dropped file paths
end

"""
DropArea wraps a component and calls `on_drop` whenever files are dropped on it.

The callback receives a `Vector{String}` of absolute file paths.

Usage:
```julia
DropArea(my_component) do paths
    println("Dropped: ", paths)
end
```
Or with keyword argument:
```julia
DropArea(my_component; on_drop = paths -> println(paths))
```
"""
function DropArea(child::AbstractView; on_drop::Function=(_) -> nothing)
    return DropAreaView(child, on_drop)
end

function DropArea(on_drop::Function, child::AbstractView)
    return DropAreaView(child, on_drop)
end

# Measurement - transparent pass-through
function measure(view::DropAreaView)::Tuple{Float32,Float32}
    return measure(view.child)
end

function measure_width(view::DropAreaView, available_height::Float32)::Float32
    return measure_width(view.child, available_height)
end

function measure_height(view::DropAreaView, available_width::Float32)::Float32
    return measure_height(view.child, available_width)
end

# Rendering - transparent pass-through
function interpret_view(view::DropAreaView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32}, cursor_position::Point2f, window_size::Size)
    interpret_view(view.child, x, y, width, height, projection_matrix, cursor_position, window_size)
end

# Drop detection
function detect_click(view::DropAreaView, input_state::InputState, x::Float32, y::Float32, width::Float32, height::Float32, parent_z::Int32)::Union{ClickResult,Nothing}
    if !isempty(input_state.dropped_files)
        if inside_component(view, x, y, width, height, input_state.x, input_state.y)
            view.on_drop(input_state.dropped_files)
        end
    end

    return detect_click(view.child, input_state, x, y, width, height, Int32(parent_z + 1))
end

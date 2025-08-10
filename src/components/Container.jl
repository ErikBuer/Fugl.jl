mutable struct ContainerStyle
    background_color::Vec4{<:AbstractFloat} #RGBA color
    border_color::Vec4{<:AbstractFloat} #RGBA color
    border_width_px::Float32
    padding_px::Float32
    corner_radius_px::Float32
end

function ContainerStyle(;
    background_color=Vec4{Float32}(0.9f0, 0.9f0, 0.9f0, 1.0f0),
    border_color=Vec4{Float32}(0.0f0, 0.0f0, 0.0f0, 1.0f0),
    border_width_px=4.0f0,
    padding_px::Float32=6f0,
    corner_radius_px::Float32=5.0f0
)
    return ContainerStyle(background_color, border_color, border_width_px, padding_px, corner_radius_px)
end

struct ContainerView <: AbstractView
    child::AbstractView  # Single child view
    style::ContainerStyle
    on_click::Function
    on_mouse_down::Function
end

"""
The `Container` is the most basic GUI component that can contain another component.
It is the most basic building block of the GUI system.
"""
function Container(child::AbstractView=EmptyView(); style=ContainerStyle(), on_click::Function=() -> nothing, on_mouse_down::Function=() -> nothing)
    return ContainerView(child, style, on_click, on_mouse_down)
end

function measure(view::ContainerView)::Tuple{Float32,Float32}
    # Measure the size of the child component
    child_width, child_height = measure(view.child)

    # Add padding
    padding = view.style.padding_px
    return (child_width + 2 * padding, child_height + 2 * padding)
end

function apply_layout(view::ContainerView, x::Float32, y::Float32, width::Float32, height::Float32)
    # Extract padding from the container's layout
    padding = view.style.padding_px
    padded_x = x + padding
    padded_y = y + padding
    padded_width = width - 2 * padding
    padded_height = height - 2 * padding

    # Compute the child's position and size based on alignment
    child_width = padded_width
    child_height = padded_height

    child_x = padded_x
    child_y = padded_y

    return (child_x, child_y, child_width, child_height)
end

function interpret_view(container::ContainerView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32})
    # Compute the layout for the container
    (child_x, child_y, child_width, child_height) = apply_layout(container, x, y, width, height)

    # Render the container background
    bg_color = container.style.background_color
    border_color = container.style.border_color
    border_width_px = container.style.border_width_px
    corner_radius_px = container.style.corner_radius_px

    vertex_positions = generate_rectangle_vertices(x, y, width, height)
    draw_rounded_rectangle(vertex_positions, width, height, bg_color, border_color, border_width_px, corner_radius_px, projection_matrix)

    # Render the child
    interpret_view(container.child, child_x, child_y, child_width, child_height, projection_matrix)
end
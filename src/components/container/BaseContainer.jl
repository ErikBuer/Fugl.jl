include("ContainerStyle.jl")

struct BaseContainerView <: AbstractView
    child::AbstractView
    style::ContainerStyle
end

"""
The `BaseContainer` is the most basic GUI component that can contain another component.
It is the most basic building block of the GUI system.
"""
function BaseContainer(child::AbstractView=EmptyView();
    style=ContainerStyle(),
)
    return BaseContainerView(child, style)
end

function measure(view::BaseContainerView)::Tuple{Float32,Float32}
    # Measure the size of the child component
    child_width, child_height = measure(view.child)

    # Add padding
    padding = view.style.padding
    return (child_width + 2 * padding, child_height + 2 * padding)
end

function measure_width(view::BaseContainerView, available_height::Float32)::Float32
    padding = view.style.padding
    inner_height = available_height - 2 * padding
    child_width = measure_width(view.child, inner_height)
    return child_width + 2 * padding
end

function measure_height(view::BaseContainerView, available_width::Float32)::Float32
    padding = view.style.padding
    inner_width = available_width - 2 * padding
    child_height = measure_height(view.child, inner_width)
    return child_height + 2 * padding
end

"""
Calculate layout to the container and its child.
"""
function apply_layout(view::BaseContainerView, x::Float32, y::Float32, width::Float32, height::Float32)
    # Extract padding from the container's layout
    padding = view.style.padding
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

"""                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
Render the container and its child.
"""
function interpret_view(container::BaseContainerView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32}, cursor_position::Point2f, window_size::Size)
    # Compute the layout for the container
    (child_x, child_y, child_width, child_height) = apply_layout(container, x, y, width, height)

    # Render background and border using the single style
    vertex_positions = generate_rectangle_vertices(x, y, width, height)
    draw_rounded_rectangle(vertex_positions, width, height,
        container.style.background_color,
        container.style.border_color,
        container.style.border_width,
        container.style.corner_radius,
        projection_matrix,
        container.style.anti_aliasing_width
    )

    # Render the child
    interpret_view(container.child, child_x, child_y, child_width, child_height, projection_matrix, cursor_position, window_size)
end

"""
Simple click detection - forwards all clicks to child without interaction logic.
"""
function detect_click(view::BaseContainerView, mouse_state::InputState, x::Float32, y::Float32, width::Float32, height::Float32, parent_z::Int32)::Union{ClickResult,Nothing}
    # Get child layout
    (child_x, child_y, child_width, child_height) = apply_layout(view, x, y, width, height)

    # Simply forward to child - no interaction state management
    return detect_click(view.child, mouse_state, child_x, child_y, child_width, child_height, Int32(parent_z + 1))
end

"""
Container delegates preferred width to its child.
"""
function preferred_width(view::BaseContainerView)::Bool
    return preferred_width(view.child)
end

"""
Container delegates preferred height to its child.
"""
function preferred_height(view::BaseContainerView)::Bool
    return preferred_height(view.child)
end
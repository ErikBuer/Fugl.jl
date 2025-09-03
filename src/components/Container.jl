struct ContainerStyle
    background_color::Vec4{<:AbstractFloat} #RGBA color
    border_color::Vec4{<:AbstractFloat} #RGBA color
    border_width::Float32
    padding::Float32
    corner_radius::Float32
    anti_aliasing_width::Float32
end

function ContainerStyle(;
    background_color=Vec4{Float32}(0.88f0, 0.875f0, 0.88f0, 1.0f0),
    border_color=Vec4{Float32}(0.5f0, 0.5f0, 0.5f0, 1.0f0),
    border_width=1.0f0,
    padding::Float32=6f0,
    corner_radius::Float32=5.0f0,
    anti_aliasing_width::Float32=1.0f0
)
    return ContainerStyle(background_color, border_color, border_width, padding, corner_radius, anti_aliasing_width)
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
    padding = view.style.padding
    return (child_width + 2 * padding, child_height + 2 * padding)
end

"""
Calculate layout to the container and its child.
"""
function apply_layout(view::ContainerView, x::Float32, y::Float32, width::Float32, height::Float32)
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
function interpret_view(container::ContainerView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32})
    # Compute the layout for the container
    (child_x, child_y, child_width, child_height) = apply_layout(container, x, y, width, height)

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
    interpret_view(container.child, child_x, child_y, child_width, child_height, projection_matrix)
end

"""
Detect clicks on the container and its child.
"""
function detect_click(view::ContainerView, mouse_state::InputState, x::AbstractFloat, y::AbstractFloat, width::AbstractFloat, height::AbstractFloat)
    (child_x, child_y, child_width, child_height) = apply_layout(view, x, y, width, height)

    # Check if the mouse is inside the component
    if inside_component(view, child_x, child_y, child_width, child_height, mouse_state.x, mouse_state.y)
        if mouse_state.button_state[LeftButton] == IsPressed
            view.on_mouse_down()  # Trigger `on_mouse_down`
        elseif mouse_state.was_clicked[LeftButton]
            view.on_click()  # Trigger `on_click`
        end
    end

    # Recursively check the child
    detect_click(view.child, mouse_state, child_x, child_y, child_width, child_height)
end
"""
A container that allows horizontal resizing by dragging a vertical splitter handle between left and right child components.
Optimized version with no runtime direction checks for better performance.
"""
mutable struct HorizontalSplitContainerView <: AbstractView
    left::AbstractView
    right::AbstractView
    split_position::Float32     # Position as ratio (0.0 to 1.0) or fixed pixels if > 1.0
    min_size::Float32           # Minimum size for resizable panels
    handle_thickness::Float32   # Thickness of the resize handle in pixels
    handle_color::Vec4f         # Color of the resize handle
    handle_hover_color::Vec4f   # Color when hovering over handle

    # Internal state for dragging
    is_dragging::Ref{Bool}
    drag_start_pos::Ref{Float32}
    drag_start_split::Ref{Float32}
    is_hovering::Ref{Bool}
end

"""
A container that allows vertical resizing by dragging a horizontal splitter handle between top and bottom child components.
Optimized version with no runtime direction checks for better performance.
"""
mutable struct VerticalSplitContainerView <: AbstractView
    top::AbstractView
    bottom::AbstractView
    split_position::Float32     # Position as ratio (0.0 to 1.0) or fixed pixels if > 1.0
    min_size::Float32           # Minimum size for resizable panels
    handle_thickness::Float32   # Thickness of the resize handle in pixels
    handle_color::Vec4f         # Color of the resize handle
    handle_hover_color::Vec4f   # Color when hovering over handle

    # Internal state for dragging
    is_dragging::Ref{Bool}
    drag_start_pos::Ref{Float32}
    drag_start_split::Ref{Float32}
    is_hovering::Ref{Bool}
end

"""
    HorizontalSplitContainer(left, right; kwargs...)

Create a horizontal split container with left and right child components.

# Arguments
- `left::AbstractView`: Left child component
- `right::AbstractView`: Right child component
- `split_position::Float32=0.5f0`: Initial split position (0.0-1.0 for ratio, >1.0 for fixed pixels)
- `min_size::Float32=50.0f0`: Minimum size for resizable panels
- `handle_thickness::Float32=4.0f0`: Thickness of the resize handle
- `handle_color::Vec4f=Vec4f(0.7, 0.7, 0.7, 1.0)`: Color of the resize handle
- `handle_hover_color::Vec4f=Vec4f(0.5, 0.5, 0.5, 1.0)`: Color when hovering
"""
function HorizontalSplitContainer(
    left::AbstractView,
    right::AbstractView;
    split_position::Float32=0.5f0,
    min_size::Float32=50.0f0,
    handle_thickness::Float32=4.0f0,
    handle_color::Vec4f=Vec4f(0.7, 0.7, 0.7, 1.0),
    handle_hover_color::Vec4f=Vec4f(0.5, 0.5, 0.5, 1.0)
)
    return HorizontalSplitContainerView(
        left, right, split_position, min_size, handle_thickness,
        handle_color, handle_hover_color,
        Ref(false), Ref(0.0f0), Ref(split_position), Ref(false)
    )
end

"""
    VerticalSplitContainer(top, bottom; kwargs...)

Create a vertical split container with top and bottom child components.

# Arguments
- `top::AbstractView`: Top child component
- `bottom::AbstractView`: Bottom child component
- `split_position::Float32=0.5f0`: Initial split position (0.0-1.0 for ratio, >1.0 for fixed pixels)
- `min_size::Float32=50.0f0`: Minimum size for resizable panels
- `handle_thickness::Float32=4.0f0`: Thickness of the resize handle
- `handle_color::Vec4f=Vec4f(0.7, 0.7, 0.7, 1.0)`: Color of the resize handle
- `handle_hover_color::Vec4f=Vec4f(0.5, 0.5, 0.5, 1.0)`: Color when hovering
"""
function VerticalSplitContainer(
    top::AbstractView,
    bottom::AbstractView;
    split_position::Float32=0.5f0,
    min_size::Float32=50.0f0,
    handle_thickness::Float32=4.0f0,
    handle_color::Vec4f=Vec4f(0.7, 0.7, 0.7, 1.0),
    handle_hover_color::Vec4f=Vec4f(0.5, 0.5, 0.5, 1.0)
)
    return VerticalSplitContainerView(
        top, bottom, split_position, min_size, handle_thickness,
        handle_color, handle_hover_color,
        Ref(false), Ref(0.0f0), Ref(split_position), Ref(false)
    )
end

# Measure functions - both containers take all available space
function measure(container::HorizontalSplitContainerView, available_width::Float32, available_height::Float32)
    return SizedView(container, available_width, available_height)
end

function measure(container::VerticalSplitContainerView, available_width::Float32, available_height::Float32)
    return SizedView(container, available_width, available_height)
end

function detect_click(container::HorizontalSplitContainerView, input_state::InputState, x_offset::Float32, y_offset::Float32, width::Float32, height::Float32)
    mouse_x = Float32(input_state.x) - x_offset
    mouse_y = Float32(input_state.y) - y_offset

    # Calculate split position in pixels
    split_pixel = container.split_position <= 1.0f0 ?
                  container.split_position * width :
                  min(container.split_position, width - container.handle_thickness)

    # Check if mouse is over the vertical handle
    handle_x = split_pixel
    is_over_handle = (mouse_x >= handle_x &&
                      mouse_x <= handle_x + container.handle_thickness &&
                      mouse_y >= 0.0f0 && mouse_y <= height)

    container.is_hovering[] = is_over_handle

    # Handle dragging
    if is_over_handle && input_state.button_state[LeftButton] == IsPressed && input_state.was_clicked[LeftButton]
        # Start dragging
        container.is_dragging[] = true
        container.drag_start_pos[] = mouse_x
        container.drag_start_split[] = container.split_position
        return # Don't propagate to children when starting drag
    end

    if container.is_dragging[] && input_state.button_state[LeftButton] == IsPressed
        # Continue dragging
        delta = mouse_x - container.drag_start_pos[]

        # Update split position
        if container.split_position <= 1.0f0  # Ratio mode
            new_split = container.drag_start_split[] + delta / width
            container.split_position = clamp(new_split, container.min_size / width,
                1.0f0 - (container.min_size + container.handle_thickness) / width)
        else  # Fixed pixel mode
            new_split = container.drag_start_split[] + delta
            container.split_position = clamp(new_split, container.min_size,
                width - container.min_size - container.handle_thickness)
        end
        return # Don't propagate to children while dragging
    end

    if container.is_dragging[] && input_state.button_state[LeftButton] == IsReleased
        # Stop dragging
        container.is_dragging[] = false
    end

    # If not interacting with handle, propagate to children
    if !is_over_handle && !container.is_dragging[]
        # Calculate child bounds
        left_width = split_pixel
        right_x = split_pixel + container.handle_thickness
        right_width = width - right_x

        # Check left child
        if mouse_x >= 0.0f0 && mouse_x <= left_width && mouse_y >= 0.0f0 && mouse_y <= height
            detect_click(container.left, input_state, x_offset, y_offset, left_width, height)
        end

        # Check right child
        if mouse_x >= right_x && mouse_x <= width && mouse_y >= 0.0f0 && mouse_y <= height
            detect_click(container.right, input_state, x_offset + right_x, y_offset, right_width, height)
        end
    end
end

function detect_click(container::HorizontalSplitContainerView, input_state::InputState, x_offset::Float32, y_offset::Float32, width::Float32, height::Float32)
    mouse_x = Float32(input_state.x) - x_offset
    mouse_y = Float32(input_state.y) - y_offset

    # Calculate split position in pixels
    split_pixel = container.split_position <= 1.0f0 ?
                  container.split_position * height :
                  min(container.split_position, height - container.handle_thickness)

    # Check if mouse is over the horizontal handle
    handle_y = split_pixel
    is_over_handle = (mouse_y >= handle_y &&
                      mouse_y <= handle_y + container.handle_thickness &&
                      mouse_x >= 0.0f0 && mouse_x <= width)

    container.is_hovering[] = is_over_handle

    # Handle dragging
    if is_over_handle && input_state.button_state[LeftButton] == IsPressed && input_state.was_clicked[LeftButton]
        # Start dragging
        container.is_dragging[] = true
        container.drag_start_pos[] = mouse_y
        container.drag_start_split[] = container.split_position
        return # Don't propagate to children when starting drag
    end

    if container.is_dragging[] && input_state.button_state[LeftButton] == IsPressed
        # Continue dragging
        delta = mouse_y - container.drag_start_pos[]

        # Update split position
        if container.split_position <= 1.0f0  # Ratio mode
            new_split = container.drag_start_split[] + delta / height
            container.split_position = clamp(new_split, container.min_size / height,
                1.0f0 - (container.min_size + container.handle_thickness) / height)
        else  # Fixed pixel mode
            new_split = container.drag_start_split[] + delta
            container.split_position = clamp(new_split, container.min_size,
                height - container.min_size - container.handle_thickness)
        end
        return # Don't propagate to children while dragging
    end

    if container.is_dragging[] && input_state.button_state[LeftButton] == IsReleased
        # Stop dragging
        container.is_dragging[] = false
    end

    # If not interacting with handle, propagate to children
    if !is_over_handle && !container.is_dragging[]
        # Calculate child bounds
        top_height = split_pixel
        bottom_y = split_pixel + container.handle_thickness
        bottom_height = height - bottom_y

        # Check top child
        if mouse_y >= 0.0f0 && mouse_y <= top_height && mouse_x >= 0.0f0 && mouse_x <= width
            detect_click(container.top, input_state, x_offset, y_offset, width, top_height)
        end

        # Check bottom child
        if mouse_y >= bottom_y && mouse_y <= height && mouse_x >= 0.0f0 && mouse_x <= width
            detect_click(container.bottom, input_state, x_offset, y_offset + bottom_y, width, bottom_height)
        end
    end
end


function interpret_view(container::HorizontalSplitContainerView, x_offset::Float32, y_offset::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32})
    # Calculate split position in pixels
    split_pixel = container.split_position <= 1.0f0 ?
                  container.split_position * width :
                  min(container.split_position, width - container.handle_thickness)

    # Calculate child bounds
    left_width = split_pixel
    right_x = split_pixel + container.handle_thickness
    right_width = width - right_x

    # Render children
    if left_width > 0
        interpret_view(container.left, x_offset, y_offset, left_width, height, projection_matrix)
    end

    if right_width > 0
        interpret_view(container.right, x_offset + right_x, y_offset, right_width, height, projection_matrix)
    end

    # Render the vertical handle
    color = container.is_hovering[] ? container.handle_hover_color : container.handle_color
    handle_vertices = [
        Point2f(x_offset + split_pixel, y_offset),
        Point2f(x_offset + split_pixel, y_offset + height),
        Point2f(x_offset + split_pixel + container.handle_thickness, y_offset + height),
        Point2f(x_offset + split_pixel + container.handle_thickness, y_offset),
    ]
    draw_rectangle(handle_vertices, color, projection_matrix)
end

function interpret_view(container::VerticalSplitContainerView, x_offset::Float32, y_offset::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32})
    # Calculate split position in pixels
    split_pixel = container.split_position <= 1.0f0 ?
                  container.split_position * height :
                  min(container.split_position, height - container.handle_thickness)

    # Calculate child bounds
    top_height = split_pixel
    bottom_y = split_pixel + container.handle_thickness
    bottom_height = height - bottom_y

    # Render children
    if top_height > 0
        interpret_view(container.top, x_offset, y_offset, width, top_height, projection_matrix)
    end

    if bottom_height > 0
        interpret_view(container.bottom, x_offset, y_offset + bottom_y, width, bottom_height, projection_matrix)
    end

    # Render the horizontal handle
    color = container.is_hovering[] ? container.handle_hover_color : container.handle_color
    handle_vertices = [
        Point2f(x_offset, y_offset + split_pixel),
        Point2f(x_offset, y_offset + split_pixel + container.handle_thickness),
        Point2f(x_offset + width, y_offset + split_pixel + container.handle_thickness),
        Point2f(x_offset + width, y_offset + split_pixel),
    ]
    draw_rectangle(handle_vertices, color, projection_matrix)
end

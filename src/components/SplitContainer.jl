# Style for split container appearance
mutable struct SplitContainerStyle
    handle_thickness::Float32   # Thickness of the resize handle in pixels
    handle_color::Vec4f         # Color of the resize handle
    handle_hover_color::Vec4f   # Color when hovering over handle
    min_size::Float32           # Minimum size for resizable panels
end

function SplitContainerStyle(;
    handle_thickness::Float32=4.0f0,
    handle_color::Vec4f=Vec4f(0.7, 0.7, 0.7, 1.0),
    handle_hover_color::Vec4f=Vec4f(0.5, 0.5, 0.5, 1.0),
    min_size::Float32=50.0f0
)
    return SplitContainerStyle(handle_thickness, handle_color, handle_hover_color, min_size)
end

# State for managing split container interactions (external to the view)
struct SplitContainerState
    split_position::Float32     # (0.0 to 1.0 ratio or 1.0)
    is_dragging::Bool
    drag_start_pos::Float32
    drag_start_split::Float32
    is_hovering::Bool
end

function SplitContainerState(;
    split_position::Float32=0.5f0,
    is_dragging::Bool=false,
    drag_start_pos::Float32=0.0f0,
    drag_start_split::Float32=0.0f0,
    is_hovering::Bool=false
)
    return SplitContainerState(split_position, is_dragging, drag_start_pos, drag_start_split, is_hovering)
end

"""
A container that allows horizontal resizing by dragging a vertical splitter handle between left and right child components.
Optimized version with no runtime direction checks for better performance.
"""
struct HorizontalSplitContainerView <: AbstractView
    left::AbstractView
    right::AbstractView
    style::SplitContainerStyle  # Style configuration
    state::SplitContainerState  # External state for interactions (includes split_position)
    on_state_change::Function   # Callback for state changes (including split position)
end

"""
A container that allows vertical resizing by dragging a horizontal splitter handle between top and bottom child components.
Optimized version with no runtime direction checks for better performance.
"""
struct VerticalSplitContainerView <: AbstractView
    top::AbstractView
    bottom::AbstractView
    style::SplitContainerStyle  # Style configuration
    state::SplitContainerState  # External state for interactions (includes split_position)
    on_state_change::Function   # Callback for state changes (including split position)
end

"""
    HorizontalSplitContainer(left, right; kwargs...)

Create a horizontal split container with left and right child components.

# Arguments
- `left::AbstractView`: Left child component
- `right::AbstractView`: Right child component
- `style::SplitContainerStyle=SplitContainerStyle()`: Style configuration
- `state::SplitContainerState=SplitContainerState()`: State including split position and interactions
- `on_state_change::Function=() -> nothing`: Callback for state changes (including split position)
"""
function HorizontalSplitContainer(
    left::AbstractView,
    right::AbstractView;
    style::SplitContainerStyle=SplitContainerStyle(),
    state::SplitContainerState=SplitContainerState(),
    on_state_change::Function=() -> nothing
)
    return HorizontalSplitContainerView(left, right, style, state, on_state_change)
end

"""
    VerticalSplitContainer(top, bottom; kwargs...)

Create a vertical split container with top and bottom child components.

# Arguments
- `top::AbstractView`: Top child component
- `bottom::AbstractView`: Bottom child component
- `style::SplitContainerStyle=SplitContainerStyle()`: Style configuration
- `state::SplitContainerState=SplitContainerState()`: State including split position and interactions
- `on_state_change::Function=() -> nothing`: Callback for state changes (including split position)
"""
function VerticalSplitContainer(
    top::AbstractView,
    bottom::AbstractView;
    style::SplitContainerStyle=SplitContainerStyle(),
    state::SplitContainerState=SplitContainerState(),
    on_state_change::Function=() -> nothing
)
    return VerticalSplitContainerView(top, bottom, style, state, on_state_change)
end

function detect_click(container::HorizontalSplitContainerView, input_state::InputState, x_offset::Float32, y_offset::Float32, width::Float32, height::Float32, parent_z::Int32)::Union{ClickResult,Nothing}
    z = Int32(parent_z + 1)

    mouse_x = Float32(input_state.x) - x_offset
    mouse_y = Float32(input_state.y) - y_offset

    # Calculate split position in pixels
    split_pixel = container.state.split_position <= 1.0f0 ? # TODO either 0-1 or pixel handling. dont need both
                  container.state.split_position * width :
                  min(container.state.split_position, width - container.style.handle_thickness)

    # Check if mouse is over the vertical handle
    handle_x = split_pixel
    is_over_handle = (mouse_x >= handle_x &&
                      mouse_x <= handle_x + container.style.handle_thickness &&
                      mouse_y >= 0.0f0 && mouse_y <= height)

    # Update hover state if it changed
    if is_over_handle != container.state.is_hovering
        new_state = SplitContainerState(
            split_position=container.state.split_position,
            is_dragging=container.state.is_dragging,
            drag_start_pos=container.state.drag_start_pos,
            drag_start_split=container.state.drag_start_split,
            is_hovering=is_over_handle
        )
        update_hover() = container.on_state_change(new_state)
        return ClickResult(z, () -> update_hover())
    end

    # Handle dragging
    if is_over_handle && !container.state.is_dragging && input_state.button_state[LeftButton] == IsPressed
        # Start dragging - simplified condition: just check if mouse is pressed over handle and not already dragging
        new_state = SplitContainerState(
            split_position=container.state.split_position,
            is_dragging=true,
            drag_start_pos=mouse_x,
            drag_start_split=container.state.split_position,
            is_hovering=is_over_handle
        )
        start_drag() = container.on_state_change(new_state)
        return ClickResult(z, () -> start_drag())
    end

    if container.state.is_dragging && input_state.button_state[LeftButton] == IsPressed
        # Continue dragging
        delta = mouse_x - container.state.drag_start_pos        # Calculate new split position
        if container.state.split_position <= 1.0f0  # Ratio mode
            new_split = container.state.drag_start_split + delta / width
            new_split = clamp(new_split, container.style.min_size / width,
                1.0f0 - (container.style.min_size + container.style.handle_thickness) / width)
        else  # Fixed pixel mode
            new_split = container.state.drag_start_split + delta
            new_split = clamp(new_split, container.style.min_size,
                width - container.style.min_size - container.style.handle_thickness)
        end

        # Update state with new split position
        new_state = SplitContainerState(
            split_position=new_split,
            is_dragging=container.state.is_dragging,
            drag_start_pos=container.state.drag_start_pos,
            drag_start_split=container.state.drag_start_split,
            is_hovering=container.state.is_hovering
        )
        update_drag() = container.on_state_change(new_state)
        return ClickResult(z, () -> update_drag())
    end

    if container.state.is_dragging && input_state.button_state[LeftButton] == IsReleased
        # Stop dragging
        new_state = SplitContainerState(
            split_position=container.state.split_position,
            is_dragging=false,
            drag_start_pos=container.state.drag_start_pos,
            drag_start_split=container.state.drag_start_split,
            is_hovering=container.state.is_hovering
        )
        stop_drag() = container.on_state_change(new_state)
        return ClickResult(z, () -> stop_drag())
    end

    # If not interacting with handle, propagate to children
    if !is_over_handle && !container.state.is_dragging
        # Calculate child bounds
        left_width = split_pixel
        right_x = split_pixel + container.style.handle_thickness
        right_width = width - right_x

        # Check left child
        if mouse_x >= 0.0f0 && mouse_x <= left_width && mouse_y >= 0.0f0 && mouse_y <= height
            return detect_click(container.left, input_state, x_offset, y_offset, left_width, height, z)
        end

        # Check right child
        if mouse_x >= right_x && mouse_x <= width && mouse_y >= 0.0f0 && mouse_y <= height
            return detect_click(container.right, input_state, x_offset + right_x, y_offset, right_width, height, z)
        end
    end
end

function detect_click(container::VerticalSplitContainerView, input_state::InputState, x_offset::Float32, y_offset::Float32, width::Float32, height::Float32, parent_z::Int32)::Union{ClickResult,Nothing}
    z = Int32(parent_z + 1)

    mouse_x = Float32(input_state.x) - x_offset
    mouse_y = Float32(input_state.y) - y_offset

    # Calculate split position in pixels
    split_pixel = container.state.split_position <= 1.0f0 ?
                  container.state.split_position * height :
                  min(container.state.split_position, height - container.style.handle_thickness)

    # Check if mouse is over the horizontal handle
    handle_y = split_pixel
    is_over_handle = (mouse_y >= handle_y &&
                      mouse_y <= handle_y + container.style.handle_thickness &&
                      mouse_x >= 0.0f0 && mouse_x <= width)

    # Update hover state if it changed
    if is_over_handle != container.state.is_hovering
        new_state = SplitContainerState(
            split_position=container.state.split_position,
            is_dragging=container.state.is_dragging,
            drag_start_pos=container.state.drag_start_pos,
            drag_start_split=container.state.drag_start_split,
            is_hovering=is_over_handle
        )
        update_hover() = container.on_state_change(new_state)
        return ClickResult(z, () -> update_hover())
    end

    # Handle dragging
    if is_over_handle && !container.state.is_dragging && input_state.button_state[LeftButton] == IsPressed
        # Start dragging - simplified condition: just check if mouse is pressed over handle and not already dragging
        new_state = SplitContainerState(
            split_position=container.state.split_position,
            is_dragging=true,
            drag_start_pos=mouse_y,
            drag_start_split=container.state.split_position,
            is_hovering=is_over_handle
        )
        start_drag() = container.on_state_change(new_state)
        return ClickResult(z, () -> start_drag())
    end

    if container.state.is_dragging && input_state.button_state[LeftButton] == IsPressed
        # Continue dragging
        delta = mouse_y - container.state.drag_start_pos

        # Calculate new split position
        if container.state.split_position <= 1.0f0  # Ratio mode
            new_split = container.state.drag_start_split + delta / height
            new_split = clamp(new_split, container.style.min_size / height,
                1.0f0 - (container.style.min_size + container.style.handle_thickness) / height)
        else  # Fixed pixel mode
            new_split = container.state.drag_start_split + delta
            new_split = clamp(new_split, container.style.min_size,
                height - container.style.min_size - container.style.handle_thickness)
        end

        # Update state with new split position
        new_state = SplitContainerState(
            split_position=new_split,
            is_dragging=container.state.is_dragging,
            drag_start_pos=container.state.drag_start_pos,
            drag_start_split=container.state.drag_start_split,
            is_hovering=container.state.is_hovering
        )
        update_drag() = container.on_state_change(new_state)
        return ClickResult(z, () -> update_drag())
    end

    if container.state.is_dragging && input_state.button_state[LeftButton] == IsReleased
        # Stop dragging
        new_state = SplitContainerState(
            split_position=container.state.split_position,
            is_dragging=false,
            drag_start_pos=container.state.drag_start_pos,
            drag_start_split=container.state.drag_start_split,
            is_hovering=container.state.is_hovering
        )
        stop_drag() = container.on_state_change(new_state)
        return ClickResult(z, () -> stop_drag())
    end

    # If not interacting with handle, propagate to children
    if !is_over_handle && !container.state.is_dragging
        # Calculate child bounds
        top_height = split_pixel
        bottom_y = split_pixel + container.style.handle_thickness
        bottom_height = height - bottom_y

        # Check top child
        if mouse_y >= 0.0f0 && mouse_y <= top_height && mouse_x >= 0.0f0 && mouse_x <= width
            return detect_click(container.top, input_state, x_offset, y_offset, width, top_height, z)
        end

        # Check bottom child
        if mouse_y >= bottom_y && mouse_y <= height && mouse_x >= 0.0f0 && mouse_x <= width
            return detect_click(container.bottom, input_state, x_offset, y_offset + bottom_y, width, bottom_height, z)
        end
    end
end


function interpret_view(container::HorizontalSplitContainerView, x_offset::Float32, y_offset::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32}, mouse_x::Float32, mouse_y::Float32)
    # Calculate split position in pixels
    split_pixel = container.state.split_position <= 1.0f0 ?
                  container.state.split_position * width :
                  min(container.state.split_position, width - container.style.handle_thickness)

    # Calculate child bounds
    left_width = split_pixel
    right_x = split_pixel + container.style.handle_thickness
    right_width = width - right_x

    # Render children
    if left_width > 0
        interpret_view(container.left, x_offset, y_offset, left_width, height, projection_matrix, mouse_x, mouse_y)
    end

    if right_width > 0
        interpret_view(container.right, x_offset + right_x, y_offset, right_width, height, projection_matrix, mouse_x, mouse_y)
    end

    # Render the vertical handle
    color = container.state.is_hovering ? container.style.handle_hover_color : container.style.handle_color
    handle_vertices = [
        Point2f(x_offset + split_pixel, y_offset),
        Point2f(x_offset + split_pixel, y_offset + height),
        Point2f(x_offset + split_pixel + container.style.handle_thickness, y_offset + height),
        Point2f(x_offset + split_pixel + container.style.handle_thickness, y_offset),
    ]
    draw_rectangle(handle_vertices, color, projection_matrix)
end

function interpret_view(container::VerticalSplitContainerView, x_offset::Float32, y_offset::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32}, mouse_x::Float32, mouse_y::Float32)
    # Calculate split position in pixels
    split_pixel = container.state.split_position <= 1.0f0 ?
                  container.state.split_position * height :
                  min(container.state.split_position, height - container.style.handle_thickness)

    # Calculate child bounds
    top_height = split_pixel
    bottom_y = split_pixel + container.style.handle_thickness
    bottom_height = height - bottom_y

    # Render children
    if top_height > 0
        interpret_view(container.top, x_offset, y_offset, width, top_height, projection_matrix, mouse_x, mouse_y)
    end

    if bottom_height > 0
        interpret_view(container.bottom, x_offset, y_offset + bottom_y, width, bottom_height, projection_matrix, mouse_x, mouse_y)
    end

    # Render the horizontal handle
    color = container.state.is_hovering ? container.style.handle_hover_color : container.style.handle_color
    handle_vertices = [
        Point2f(x_offset, y_offset + split_pixel),
        Point2f(x_offset, y_offset + split_pixel + container.style.handle_thickness),
        Point2f(x_offset + width, y_offset + split_pixel + container.style.handle_thickness),
        Point2f(x_offset + width, y_offset + split_pixel),
    ]
    draw_rectangle(handle_vertices, color, projection_matrix)
end

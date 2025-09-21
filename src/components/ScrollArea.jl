"""
State for tracking scroll area scrolling information and drag state
"""
mutable struct ScrollAreaState
    scroll_offset_x::Float32
    scroll_offset_y::Float32
    content_width::Float32
    content_height::Float32
    max_scroll_x::Float32
    max_scroll_y::Float32

    # Scrollbar drag tracking
    is_dragging_vertical::Bool
    is_dragging_horizontal::Bool
    drag_start_scroll_y::Float32
    drag_start_scroll_x::Float32
    drag_start_mouse_y::Float32
    drag_start_mouse_x::Float32
end

"""
Create a new ScrollAreaState with either viewport dimensions or pre-calculated max_scroll values
"""
function ScrollAreaState(;
    scroll_offset_x::Float32=0.0f0,
    scroll_offset_y::Float32=0.0f0,
    content_width::Float32=0.0f0,
    content_height::Float32=0.0f0,
    viewport_width::Float32=0.0f0,  # Optional: for calculating max_scroll
    viewport_height::Float32=0.0f0,  # Optional: for calculating max_scroll
    max_scroll_x::Float32=-1.0f0,   # Optional: pre-calculated value
    max_scroll_y::Float32=-1.0f0    # Optional: pre-calculated value
)
    # Use provided max_scroll values if valid, otherwise calculate from viewport dimensions
    final_max_scroll_x = if max_scroll_x >= 0.0f0
        max_scroll_x
    else
        max(0.0f0, content_width - viewport_width)
    end

    final_max_scroll_y = if max_scroll_y >= 0.0f0
        max_scroll_y
    else
        max(0.0f0, content_height - viewport_height)
    end

    # Clamp scroll offsets to valid ranges
    clamped_x = clamp(scroll_offset_x, 0.0f0, final_max_scroll_x)
    clamped_y = clamp(scroll_offset_y, 0.0f0, final_max_scroll_y)

    return ScrollAreaState(
        clamped_x, clamped_y,
        content_width, content_height,
        final_max_scroll_x, final_max_scroll_y,
        false, false,  # not dragging initially
        0.0f0, 0.0f0,  # drag start scroll positions
        0.0f0, 0.0f0   # drag start mouse positions
    )
end

"""
Style for scroll area appearance
"""
struct ScrollAreaStyle
    scrollbar_width::Float32
    scrollbar_color::Vec4f
    scrollbar_background_color::Vec4f
    scrollbar_hover_color::Vec4f
    corner_color::Vec4f  # Color for the corner where scrollbars meet
end

function ScrollAreaStyle(;
    scrollbar_width::Float32=12.0f0,
    scrollbar_color::Vec4f=Vec4f(0.6, 0.6, 0.6, 1.0),
    scrollbar_background_color::Vec4f=Vec4f(0.9, 0.9, 0.9, 1.0),
    scrollbar_hover_color::Vec4f=Vec4f(0.4, 0.4, 0.4, 1.0),
    corner_color::Vec4f=Vec4f(0.9, 0.9, 0.9, 1.0)
)
    return ScrollAreaStyle(
        scrollbar_width, scrollbar_color, scrollbar_background_color,
        scrollbar_hover_color, corner_color
    )
end

"""
ScrollArea view that wraps content and provides scrolling
"""
struct ScrollAreaView <: AbstractView
    content::AbstractView
    scroll_state::ScrollAreaState
    style::ScrollAreaStyle
    enable_horizontal::Bool
    enable_vertical::Bool
    show_scrollbars::Bool
    on_scroll_change::Function
    on_click::Function
end

"""
Create a ScrollArea component

# Arguments
- `content::AbstractView`: The content to be scrolled
- `scroll_state::ScrollAreaState`: Current scroll state
- `style::ScrollAreaStyle`: Styling for the scroll area
- `enable_horizontal::Bool`: Enable horizontal scrolling
- `enable_vertical::Bool`: Enable vertical scrolling  
- `show_scrollbars::Bool`: Show visual scrollbars
- `on_scroll_change::Function`: Callback when scroll state changes
- `on_click::Function`: Callback for click events
"""
function ScrollArea(
    content::AbstractView;
    scroll_state::ScrollAreaState=ScrollAreaState(),
    style::ScrollAreaStyle=ScrollAreaStyle(),
    enable_horizontal::Bool=true,
    enable_vertical::Bool=true,
    show_scrollbars::Bool=true,
    on_scroll_change::Function=(new_state) -> nothing,
    on_click::Function=(x, y) -> nothing
)
    return ScrollAreaView(
        content, scroll_state, style,
        enable_horizontal, enable_vertical, show_scrollbars,
        on_scroll_change, on_click
    )
end

"""
Measure the scroll area - takes all available space like a container
"""
function measure(view::ScrollAreaView)::Tuple{Float32,Float32}
    return (Inf32, Inf32)  # Take all available space
end

"""
Apply layout to scroll area - measures content and sets up viewport
"""
function apply_layout(view::ScrollAreaView, x::Float32, y::Float32, width::Float32, height::Float32)
    # Calculate available space for content (excluding scrollbars if shown)
    scrollbar_space_x = (view.show_scrollbars && view.enable_vertical) ? view.style.scrollbar_width : 0.0f0
    scrollbar_space_y = (view.show_scrollbars && view.enable_horizontal) ? view.style.scrollbar_width : 0.0f0

    viewport_width = width - scrollbar_space_x
    viewport_height = height - scrollbar_space_y

    # Measure the content's natural size
    content_width, content_height = measure(view.content)

    # Handle content sizing based on scrolling configuration
    if view.enable_horizontal && !view.enable_vertical
        # Horizontal scrolling only: content takes full viewport height, can expand horizontally
        if isinf(content_height)
            content_height = viewport_height
        end
        # If content wants to fill width but we allow horizontal scrolling, give it at least viewport width
        if isinf(content_width)
            content_width = viewport_width
        end
    elseif view.enable_vertical && !view.enable_horizontal
        # Vertical scrolling only: content takes full viewport width, can expand vertically
        if isinf(content_width)
            content_width = viewport_width
        end
        # Force content to use full viewport width even if it doesn't want to fill
        content_width = viewport_width

        # If content wants to fill height but we allow vertical scrolling, give it at least viewport height
        if isinf(content_height)
            content_height = viewport_height
        end
    else
        # Both or neither scrolling enabled: content fills available viewport space if it wants to
        if isinf(content_width)
            content_width = viewport_width
        end
        if isinf(content_height)
            content_height = viewport_height
        end
    end

    # Apply scroll offsets to content position
    content_x = x - (view.enable_horizontal ? view.scroll_state.scroll_offset_x : 0.0f0)
    content_y = y - (view.enable_vertical ? view.scroll_state.scroll_offset_y : 0.0f0)

    return (content_x, content_y, content_width, content_height, viewport_width, viewport_height)
end

"""
Render the scroll area with content and optional scrollbars
"""
function interpret_view(view::ScrollAreaView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32})
    # Get layout for content and viewport
    content_x, content_y, content_width, content_height, viewport_width, viewport_height = apply_layout(view, x, y, width, height)

    # Only update scroll state if measurements actually changed
    state_needs_update = (
        abs(content_width - view.scroll_state.content_width) > 1.0f0 ||
        abs(content_height - view.scroll_state.content_height) > 1.0f0
    )

    updated_state = if state_needs_update
        new_state = ScrollAreaState(
            scroll_offset_x=view.scroll_state.scroll_offset_x,
            scroll_offset_y=view.scroll_state.scroll_offset_y,
            content_width=content_width,
            content_height=content_height,
            viewport_width=viewport_width,  # Pass for max_scroll calculation
            viewport_height=viewport_height
        )
        # Copy drag state
        new_state.is_dragging_vertical = view.scroll_state.is_dragging_vertical
        new_state.is_dragging_horizontal = view.scroll_state.is_dragging_horizontal
        new_state.drag_start_scroll_y = view.scroll_state.drag_start_scroll_y
        new_state.drag_start_scroll_x = view.scroll_state.drag_start_scroll_x
        new_state.drag_start_mouse_y = view.scroll_state.drag_start_mouse_y
        new_state.drag_start_mouse_x = view.scroll_state.drag_start_mouse_x

        # Notify of state change
        view.on_scroll_change(new_state)
        new_state
    else
        view.scroll_state
    end

    # Enable scissor test to clip content to viewport
    ModernGL.glEnable(GL_SCISSOR_TEST)

    # Convert from our coordinate system to OpenGL's (bottom-left origin)
    viewport_info = Vector{Int32}(undef, 4)
    ModernGL.glGetIntegerv(ModernGL.GL_VIEWPORT, viewport_info)
    window_height = viewport_info[4]

    scissor_x = Int(round(x))
    scissor_y = Int(round(window_height - y - viewport_height))
    scissor_width = Int(round(viewport_width))
    scissor_height = Int(round(viewport_height))
    ModernGL.glScissor(scissor_x, scissor_y, scissor_width, scissor_height)

    # Render the scrolled content
    interpret_view(view.content, content_x, content_y, content_width, content_height, projection_matrix)

    # Disable scissor test
    ModernGL.glDisable(GL_SCISSOR_TEST)

    # Render scrollbars if enabled
    if view.show_scrollbars
        render_scrollbars(view, x, y, width, height, updated_state, viewport_width, viewport_height, projection_matrix)
    end
end

"""
Render scrollbars for the scroll area
"""
function render_scrollbars(view::ScrollAreaView, x::Float32, y::Float32, width::Float32, height::Float32, state::ScrollAreaState, viewport_width::Float32, viewport_height::Float32, projection_matrix::Mat4{Float32})
    # Vertical scrollbar
    if view.enable_vertical && state.max_scroll_y > 0.0f0
        vscroll_x = x + viewport_width
        vscroll_y = y
        vscroll_width = view.style.scrollbar_width
        vscroll_height = viewport_height

        # Create vertices for scrollbar background
        bg_vertices = [
            Point2f(vscroll_x, vscroll_y + vscroll_height),  # Top-left
            Point2f(vscroll_x, vscroll_y),                   # Bottom-left  
            Point2f(vscroll_x + vscroll_width, vscroll_y),   # Bottom-right
            Point2f(vscroll_x + vscroll_width, vscroll_y + vscroll_height)  # Top-right
        ]

        # Draw scrollbar background
        draw_rectangle(bg_vertices, view.style.scrollbar_background_color, projection_matrix)

        # Scrollbar thumb
        thumb_ratio = viewport_height / state.content_height
        thumb_height = max(20.0f0, vscroll_height * thumb_ratio)  # Minimum thumb size
        thumb_position_ratio = state.scroll_offset_y / state.max_scroll_y
        thumb_y = vscroll_y + (vscroll_height - thumb_height) * thumb_position_ratio

        # Create vertices for scrollbar thumb
        thumb_vertices = [
            Point2f(vscroll_x, thumb_y + thumb_height),  # Top-left
            Point2f(vscroll_x, thumb_y),                 # Bottom-left
            Point2f(vscroll_x + vscroll_width, thumb_y), # Bottom-right
            Point2f(vscroll_x + vscroll_width, thumb_y + thumb_height)  # Top-right
        ]

        draw_rectangle(thumb_vertices, view.style.scrollbar_color, projection_matrix)
    end

    # Horizontal scrollbar
    if view.enable_horizontal && state.max_scroll_x > 0.0f0
        hscroll_x = x
        hscroll_y = y + viewport_height
        hscroll_width = viewport_width
        hscroll_height = view.style.scrollbar_width

        # Create vertices for horizontal scrollbar background
        bg_vertices = [
            Point2f(hscroll_x, hscroll_y + hscroll_height),  # Top-left
            Point2f(hscroll_x, hscroll_y),                   # Bottom-left
            Point2f(hscroll_x + hscroll_width, hscroll_y),   # Bottom-right
            Point2f(hscroll_x + hscroll_width, hscroll_y + hscroll_height)  # Top-right
        ]

        draw_rectangle(bg_vertices, view.style.scrollbar_background_color, projection_matrix)

        # Scrollbar thumb
        thumb_ratio = viewport_width / state.content_width
        thumb_width = max(20.0f0, hscroll_width * thumb_ratio)  # Minimum thumb size
        thumb_position_ratio = state.scroll_offset_x / state.max_scroll_x
        thumb_x = hscroll_x + (hscroll_width - thumb_width) * thumb_position_ratio

        # Create vertices for horizontal scrollbar thumb
        thumb_vertices = [
            Point2f(thumb_x, hscroll_y + hscroll_height),  # Top-left
            Point2f(thumb_x, hscroll_y),                   # Bottom-left
            Point2f(thumb_x + thumb_width, hscroll_y),     # Bottom-right
            Point2f(thumb_x + thumb_width, hscroll_y + hscroll_height)  # Top-right
        ]

        draw_rectangle(thumb_vertices, view.style.scrollbar_color, projection_matrix)
    end

    # Corner piece where scrollbars meet
    if (view.enable_horizontal && state.max_scroll_x > 0.0f0 &&
        view.enable_vertical && state.max_scroll_y > 0.0f0)
        corner_x = x + viewport_width
        corner_y = y + viewport_height

        # Create vertices for corner
        corner_vertices = [
            Point2f(corner_x, corner_y + view.style.scrollbar_width),  # Top-left
            Point2f(corner_x, corner_y),                               # Bottom-left
            Point2f(corner_x + view.style.scrollbar_width, corner_y),  # Bottom-right
            Point2f(corner_x + view.style.scrollbar_width, corner_y + view.style.scrollbar_width)  # Top-right
        ]

        draw_rectangle(corner_vertices, view.style.corner_color, projection_matrix)
    end
end

"""
Detect clicks within the scroll area (including scrollbar interactions and mouse wheel)
"""
function detect_click(view::ScrollAreaView, mouse_state::InputState, x::Float32, y::Float32, width::Float32, height::Float32)
    interaction_occurred = false

    # Get mouse position relative to scroll area
    mouse_x = Float32(mouse_state.x) - x
    mouse_y = Float32(mouse_state.y) - y

    # Check if mouse is within the scroll area bounds
    if mouse_x >= 0 && mouse_x <= width && mouse_y >= 0 && mouse_y <= height

        # Handle mouse wheel scrolling
        if (mouse_state.scroll_x != 0.0 || mouse_state.scroll_y != 0.0)
            handle_scroll_wheel(view, mouse_x, mouse_y, Float32(mouse_state.scroll_x), Float32(mouse_state.scroll_y))
            interaction_occurred = true
        end

        # Check for scrollbar interactions
        scrollbar_space_x = (view.show_scrollbars && view.enable_vertical) ? view.style.scrollbar_width : 0.0f0
        scrollbar_space_y = (view.show_scrollbars && view.enable_horizontal) ? view.style.scrollbar_width : 0.0f0

        # Calculate viewport dimensions from current layout
        viewport_width = width - scrollbar_space_x
        viewport_height = height - scrollbar_space_y

        # Scrollbars are visual-only, so handle content area clicks directly
        if mouse_x >= 0 && mouse_x <= viewport_width &&
           mouse_y >= 0 && mouse_y <= viewport_height

            # Calculate mouse position in content space (for click callbacks)
            content_mouse_x = mouse_x + (view.enable_horizontal ? view.scroll_state.scroll_offset_x : 0.0f0)
            content_mouse_y = mouse_y + (view.enable_vertical ? view.scroll_state.scroll_offset_y : 0.0f0)

            # Check click on the content
            content_layout = apply_layout(view, x, y, width, height)
            content_x, content_y, content_width, content_height = content_layout[1:4]

            # Create a new mouse state with screen coordinates (content is positioned at scrolled location)
            content_mouse_state = InputState(
                mouse_state.button_state,
                mouse_state.was_clicked,
                mouse_state.x,  # Use original screen coordinates
                mouse_state.y,  # Use original screen coordinates
                mouse_state.last_click_time,
                mouse_state.last_click_position,
                mouse_state.key_buffer,
                mouse_state.key_events,
                mouse_state.drag_start_position,
                mouse_state.is_dragging,
                mouse_state.last_drag_position,
                mouse_state.double_click_threshold,
                mouse_state.was_double_clicked,
                mouse_state.scroll_x,
                mouse_state.scroll_y,
                mouse_state.modifier_keys
            )

            content_clicked = detect_click(view.content, content_mouse_state, content_x, content_y, content_width, content_height)
            if content_clicked === true
                interaction_occurred = true
            end

            # Call our own click callback only on actual click events
            if get(mouse_state.was_clicked, LeftButton, false)
                view.on_click(content_mouse_x, content_mouse_y)
                interaction_occurred = true
            end
        end
    end

    return interaction_occurred
end

"""
Handle mouse wheel scrolling
"""
function handle_scroll_wheel(view::ScrollAreaView, mouse_x::Float32, mouse_y::Float32, wheel_delta_x::Float32, wheel_delta_y::Float32)
    scroll_speed = 30.0f0  # Pixels per wheel tick

    new_offset_x = view.scroll_state.scroll_offset_x
    new_offset_y = view.scroll_state.scroll_offset_y

    if view.enable_horizontal && view.scroll_state.max_scroll_x > 0.0f0
        new_offset_x = clamp(
            new_offset_x + wheel_delta_x * scroll_speed,
            0.0f0, view.scroll_state.max_scroll_x
        )
    end

    if view.enable_vertical && view.scroll_state.max_scroll_y > 0.0f0
        new_offset_y = clamp(
            new_offset_y + wheel_delta_y * scroll_speed,
            0.0f0, view.scroll_state.max_scroll_y
        )
    end

    # Only update if scroll position actually changed
    if new_offset_x != view.scroll_state.scroll_offset_x || new_offset_y != view.scroll_state.scroll_offset_y
        # Create updated state
        new_state = ScrollAreaState(
            scroll_offset_x=new_offset_x,
            scroll_offset_y=new_offset_y,
            content_width=view.scroll_state.content_width,
            content_height=view.scroll_state.content_height,
            max_scroll_x=view.scroll_state.max_scroll_x,
            max_scroll_y=view.scroll_state.max_scroll_y
        )

        view.on_scroll_change(new_state)
        return new_state
    end

    return view.scroll_state
end

"""
Handle clicks on scrollbars - similar to HorizontalSlider pattern
"""
function handle_scrollbar_interactions(view::ScrollAreaView, mouse_state::InputState, mouse_x::Float32, mouse_y::Float32, width::Float32, height::Float32, scrollbar_space_x::Float32, scrollbar_space_y::Float32)
    interaction_occurred = false

    # Check if left mouse button is involved
    left_button_state = get(mouse_state.button_state, LeftButton, IsReleased)
    left_button_clicked = get(mouse_state.was_clicked, LeftButton, false)
    left_button_dragging = get(mouse_state.is_dragging, LeftButton, false)

    # Check if we're in the vertical scrollbar area
    in_vertical_scrollbar = (view.show_scrollbars && view.enable_vertical &&
                             mouse_x >= width - scrollbar_space_x && mouse_x <= width &&
                             mouse_y >= 0 && mouse_y <= height - scrollbar_space_y)

    # Check if we're in the horizontal scrollbar area  
    in_horizontal_scrollbar = (view.show_scrollbars && view.enable_horizontal &&
                               mouse_x >= 0 && mouse_x <= width - scrollbar_space_x &&
                               mouse_y >= height - scrollbar_space_y && mouse_y <= height)

    # Handle vertical scrollbar
    if in_vertical_scrollbar && view.scroll_state.max_scroll_y > 0.0f0
        if left_button_clicked && !view.scroll_state.is_dragging_vertical
            # Start vertical drag
            view.scroll_state.is_dragging_vertical = true
            view.scroll_state.drag_start_mouse_y = mouse_y
            view.scroll_state.drag_start_scroll_y = view.scroll_state.scroll_offset_y
            interaction_occurred = true
        elseif left_button_dragging && view.scroll_state.is_dragging_vertical
            # Continue vertical drag
            handle_vertical_scrollbar_drag(view, mouse_y, height - scrollbar_space_y)
            interaction_occurred = true
        end
    end

    # Handle horizontal scrollbar
    if in_horizontal_scrollbar && view.scroll_state.max_scroll_x > 0.0f0
        if left_button_clicked && !view.scroll_state.is_dragging_horizontal
            # Start horizontal drag
            view.scroll_state.is_dragging_horizontal = true
            view.scroll_state.drag_start_mouse_x = mouse_x
            view.scroll_state.drag_start_scroll_x = view.scroll_state.scroll_offset_x
            interaction_occurred = true
        elseif left_button_dragging && view.scroll_state.is_dragging_horizontal
            # Continue horizontal drag
            handle_horizontal_scrollbar_drag(view, mouse_x, width - scrollbar_space_x)
            interaction_occurred = true
        end
    end

    # Stop dragging if mouse button is released
    if left_button_state == IsReleased
        if view.scroll_state.is_dragging_vertical || view.scroll_state.is_dragging_horizontal
            view.scroll_state.is_dragging_vertical = false
            view.scroll_state.is_dragging_horizontal = false
            interaction_occurred = true
        end
    end

    return interaction_occurred
end

"""
Handle vertical scrollbar drag
"""
function handle_vertical_scrollbar_drag(view::ScrollAreaView, mouse_y::Float32, scrollbar_height::Float32)
    if scrollbar_height <= 0.0f0
        return
    end

    # Calculate drag delta
    mouse_delta = mouse_y - view.scroll_state.drag_start_mouse_y

    # Convert to scroll delta (proportional to content vs viewport ratio)
    scroll_ratio = view.scroll_state.max_scroll_y / scrollbar_height
    scroll_delta = mouse_delta * scroll_ratio

    # Apply the delta to the original scroll position
    new_scroll_y = clamp(view.scroll_state.drag_start_scroll_y + scroll_delta, 0.0f0, view.scroll_state.max_scroll_y)

    if new_scroll_y != view.scroll_state.scroll_offset_y
        # Update scroll position
        view.scroll_state.scroll_offset_y = new_scroll_y

        # Notify of change
        new_state = ScrollAreaState(
            scroll_offset_x=view.scroll_state.scroll_offset_x,
            scroll_offset_y=new_scroll_y,
            content_width=view.scroll_state.content_width,
            content_height=view.scroll_state.content_height,
            max_scroll_x=view.scroll_state.max_scroll_x,
            max_scroll_y=view.scroll_state.max_scroll_y
        )

        # Copy drag state
        new_state.is_dragging_vertical = view.scroll_state.is_dragging_vertical
        new_state.is_dragging_horizontal = view.scroll_state.is_dragging_horizontal
        new_state.drag_start_scroll_y = view.scroll_state.drag_start_scroll_y
        new_state.drag_start_scroll_x = view.scroll_state.drag_start_scroll_x
        new_state.drag_start_mouse_y = view.scroll_state.drag_start_mouse_y
        new_state.drag_start_mouse_x = view.scroll_state.drag_start_mouse_x

        view.on_scroll_change(new_state)
    end
end

"""
Handle horizontal scrollbar drag
"""
function handle_horizontal_scrollbar_drag(view::ScrollAreaView, mouse_x::Float32, scrollbar_width::Float32)
    if scrollbar_width <= 0.0f0
        return
    end

    # Calculate drag delta
    mouse_delta = mouse_x - view.scroll_state.drag_start_mouse_x

    # Convert to scroll delta (proportional to content vs viewport ratio)
    scroll_ratio = view.scroll_state.max_scroll_x / scrollbar_width
    scroll_delta = mouse_delta * scroll_ratio

    # Apply the delta to the original scroll position
    new_scroll_x = clamp(view.scroll_state.drag_start_scroll_x + scroll_delta, 0.0f0, view.scroll_state.max_scroll_x)

    if new_scroll_x != view.scroll_state.scroll_offset_x
        # Update scroll position
        view.scroll_state.scroll_offset_x = new_scroll_x

        # Notify of change
        new_state = ScrollAreaState(
            scroll_offset_x=new_scroll_x,
            scroll_offset_y=view.scroll_state.scroll_offset_y,
            content_width=view.scroll_state.content_width,
            content_height=view.scroll_state.content_height,
            max_scroll_x=view.scroll_state.max_scroll_x,
            max_scroll_y=view.scroll_state.max_scroll_y
        )

        # Copy drag state
        new_state.is_dragging_vertical = view.scroll_state.is_dragging_vertical
        new_state.is_dragging_horizontal = view.scroll_state.is_dragging_horizontal
        new_state.drag_start_scroll_y = view.scroll_state.drag_start_scroll_y
        new_state.drag_start_scroll_x = view.scroll_state.drag_start_scroll_x
        new_state.drag_start_mouse_y = view.scroll_state.drag_start_mouse_y
        new_state.drag_start_mouse_x = view.scroll_state.drag_start_mouse_x

        view.on_scroll_change(new_state)
    end
end

function handle_scrollbar_click(view::ScrollAreaView, mouse_x::Float32, mouse_y::Float32, direction::Symbol, x::Float32, y::Float32, width::Float32, height::Float32)
    # Note: This function is not currently used since scrollbar interactions are disabled
    # Calculate viewport dimensions from the provided width/height
    scrollbar_space_x = (view.show_scrollbars && view.enable_vertical) ? view.style.scrollbar_width : 0.0f0
    scrollbar_space_y = (view.show_scrollbars && view.enable_horizontal) ? view.style.scrollbar_width : 0.0f0
    viewport_width = width - scrollbar_space_x
    viewport_height = height - scrollbar_space_y

    if direction == :vertical && view.scroll_state.max_scroll_y > 0.0f0
        # Calculate new vertical scroll position based on click location
        click_ratio = clamp(mouse_y / viewport_height, 0.0f0, 1.0f0)
        new_scroll_y = click_ratio * view.scroll_state.max_scroll_y

        new_state = ScrollAreaState(
            scroll_offset_x=view.scroll_state.scroll_offset_x,
            scroll_offset_y=clamp(new_scroll_y, 0.0f0, view.scroll_state.max_scroll_y),
            content_width=view.scroll_state.content_width,
            content_height=view.scroll_state.content_height,
            max_scroll_x=view.scroll_state.max_scroll_x,
            max_scroll_y=view.scroll_state.max_scroll_y
        )

        view.on_scroll_change(new_state)

    elseif direction == :horizontal && view.scroll_state.max_scroll_x > 0.0f0
        # Calculate new horizontal scroll position
        click_ratio = clamp(mouse_x / viewport_width, 0.0f0, 1.0f0)
        new_scroll_x = click_ratio * view.scroll_state.max_scroll_x

        new_state = ScrollAreaState(
            scroll_offset_x=clamp(new_scroll_x, 0.0f0, view.scroll_state.max_scroll_x),
            scroll_offset_y=view.scroll_state.scroll_offset_y,
            content_width=view.scroll_state.content_width,
            content_height=view.scroll_state.content_height,
            max_scroll_x=view.scroll_state.max_scroll_x,
            max_scroll_y=view.scroll_state.max_scroll_y
        )

        view.on_scroll_change(new_state)
    end

    return true
end

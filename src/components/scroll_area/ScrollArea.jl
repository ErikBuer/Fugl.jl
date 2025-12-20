include("scroll_state.jl")
include("scroll_area_style.jl")

"""
VerticalScrollArea view that wraps content and provides vertical scrolling
"""
struct VerticalScrollAreaView <: AbstractView
    content::AbstractView
    scroll_state::VerticalScrollState
    style::ScrollAreaStyle
    show_scrollbar::Bool
    on_scroll_change::Function
    on_click::Function
end

"""
HorizontalScrollArea view that wraps content and provides horizontal scrolling
"""
struct HorizontalScrollAreaView <: AbstractView
    content::AbstractView
    scroll_state::HorizontalScrollState
    style::ScrollAreaStyle
    show_scrollbar::Bool
    on_scroll_change::Function
    on_click::Function
end

"""
Create a VerticalScrollArea component

# Arguments
- `content::AbstractView`: The content to be scrolled
- `scroll_state::VerticalScrollState`: Current scroll state
- `style::ScrollAreaStyle`: Styling for the scroll area
- `show_scrollbar::Bool`: Show visual scrollbar
- `on_scroll_change::Function`: Callback when scroll state changes
- `on_click::Function`: Callback for click events
"""
function VerticalScrollArea(
    content::AbstractView;
    scroll_state::VerticalScrollState=VerticalScrollState(),
    style::ScrollAreaStyle=ScrollAreaStyle(),
    show_scrollbar::Bool=true,
    on_scroll_change::Function=(new_state) -> nothing,
    on_click::Function=(x, y) -> nothing
)
    return VerticalScrollAreaView(
        content, scroll_state, style, show_scrollbar,
        on_scroll_change, on_click
    )
end

"""
Create a HorizontalScrollArea component

# Arguments
- `content::AbstractView`: The content to be scrolled
- `scroll_state::HorizontalScrollState`: Current scroll state
- `style::ScrollAreaStyle`: Styling for the scroll area
- `show_scrollbar::Bool`: Show visual scrollbar
- `on_scroll_change::Function`: Callback when scroll state changes
- `on_click::Function`: Callback for click events
"""
function HorizontalScrollArea(
    content::AbstractView;
    scroll_state::HorizontalScrollState=HorizontalScrollState(),
    style::ScrollAreaStyle=ScrollAreaStyle(),
    show_scrollbar::Bool=true,
    on_scroll_change::Function=(new_state) -> nothing,
    on_click::Function=(x, y) -> nothing
)
    return HorizontalScrollAreaView(
        content, scroll_state, style, show_scrollbar,
        on_scroll_change, on_click
    )
end

"""
Measure the vertical scroll area - takes all available space in width, measures content height
"""
function measure(view::VerticalScrollAreaView)::Tuple{Float32,Float32}
    content_width, content_height = measure(view.content)
    return (content_width, Inf32)  # Take all available height, use content width
end

"""
Measure the horizontal scroll area - measures content width, takes all available space in height
"""
function measure(view::HorizontalScrollAreaView)::Tuple{Float32,Float32}
    content_width, content_height = measure(view.content)
    return (Inf32, content_height)  # Take all available width, use content height
end

"""
Apply layout to vertical scroll area - measures content and sets up viewport
"""
function apply_layout(view::VerticalScrollAreaView, x::Float32, y::Float32, width::Float32, height::Float32)
    # Calculate available space for content (excluding scrollbar if shown)
    scrollbar_space = view.show_scrollbar ? view.style.scrollbar_width : 0.0f0
    viewport_width = width - scrollbar_space
    viewport_height = height

    # Measure the content's natural size
    content_width, content_height = measure(view.content)

    # For vertical scrolling: content takes full viewport width, can expand vertically
    content_width = viewport_width
    if isinf(content_height)
        content_height = viewport_height  # If content wants to fill, give it viewport height
    end

    # Apply vertical scroll offset to content position
    content_x = x
    content_y = y - view.scroll_state.scroll_offset

    return (content_x, content_y, content_width, content_height, viewport_width, viewport_height)
end

"""
Apply layout to horizontal scroll area - measures content and sets up viewport
"""
function apply_layout(view::HorizontalScrollAreaView, x::Float32, y::Float32, width::Float32, height::Float32)
    # Calculate available space for content (excluding scrollbar if shown)
    scrollbar_space = view.show_scrollbar ? view.style.scrollbar_width : 0.0f0
    viewport_width = width
    viewport_height = height - scrollbar_space

    # Measure the content's natural size
    content_width, content_height = measure(view.content)

    # For horizontal scrolling: content takes full viewport height, can expand horizontally
    content_height = viewport_height
    if isinf(content_width)
        content_width = viewport_width  # If content wants to fill, give it viewport width
    end

    # Apply horizontal scroll offset to content position
    content_x = x - view.scroll_state.scroll_offset
    content_y = y

    return (content_x, content_y, content_width, content_height, viewport_width, viewport_height)
end

"""
Render the vertical scroll area with content and optional scrollbar
"""
function interpret_view(view::VerticalScrollAreaView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32}, mouse_x::Float32, mouse_y::Float32)
    # Get layout for content and viewport
    content_x, content_y, content_width, content_height, viewport_width, viewport_height = apply_layout(view, x, y, width, height)

    # Update scroll state if measurements changed
    updated_state = if abs(content_height - view.scroll_state.content_height) > 1.0f0 ||
                       abs(viewport_height - view.scroll_state.viewport_height) > 1.0f0
        new_state = VerticalScrollState(view.scroll_state;
            content_height=content_height,
            viewport_height=viewport_height
        )
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
    interpret_view(view.content, content_x, content_y, content_width, content_height, projection_matrix, mouse_x, mouse_y)

    # Disable scissor test
    ModernGL.glDisable(GL_SCISSOR_TEST)

    # Render scrollbar if enabled
    if view.show_scrollbar && updated_state.max_scroll > 0.0f0
        render_vertical_scrollbar(view, x, y, width, height, updated_state, viewport_width, viewport_height, projection_matrix)
    end
end

"""
Render the horizontal scroll area with content and optional scrollbar
"""
function interpret_view(view::HorizontalScrollAreaView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32}, mouse_x::Float32, mouse_y::Float32)
    # Get layout for content and viewport
    content_x, content_y, content_width, content_height, viewport_width, viewport_height = apply_layout(view, x, y, width, height)

    # Update scroll state if measurements changed
    updated_state = if abs(content_width - view.scroll_state.content_width) > 1.0f0 ||
                       abs(viewport_width - view.scroll_state.viewport_width) > 1.0f0
        new_state = HorizontalScrollState(view.scroll_state;
            content_width=content_width,
            viewport_width=viewport_width
        )
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
    interpret_view(view.content, content_x, content_y, content_width, content_height, projection_matrix, mouse_x, mouse_y)

    # Disable scissor test
    ModernGL.glDisable(GL_SCISSOR_TEST)

    # Render scrollbar if enabled
    if view.show_scrollbar && updated_state.max_scroll > 0.0f0
        render_horizontal_scrollbar(view, x, y, width, height, updated_state, viewport_width, viewport_height, projection_matrix)
    end
end

"""
Render vertical scrollbar
"""
function render_vertical_scrollbar(view::VerticalScrollAreaView, x::Float32, y::Float32, width::Float32, height::Float32, state::VerticalScrollState, viewport_width::Float32, viewport_height::Float32, projection_matrix::Mat4{Float32})
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
    thumb_position_ratio = state.scroll_offset / state.max_scroll
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

"""
Render horizontal scrollbar
"""
function render_horizontal_scrollbar(view::HorizontalScrollAreaView, x::Float32, y::Float32, width::Float32, height::Float32, state::HorizontalScrollState, viewport_width::Float32, viewport_height::Float32, projection_matrix::Mat4{Float32})
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
    thumb_position_ratio = state.scroll_offset / state.max_scroll
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

"""
Detect clicks within the vertical scroll area
"""
function detect_click(view::VerticalScrollAreaView, mouse_state::InputState, x::Float32, y::Float32, width::Float32, height::Float32)
    interaction_occurred = false

    # Get mouse position relative to scroll area
    mouse_x = Float32(mouse_state.x) - x
    mouse_y = Float32(mouse_state.y) - y

    # Check if mouse is within the scroll area bounds
    if mouse_x >= 0 && mouse_x <= width && mouse_y >= 0 && mouse_y <= height

        # Handle mouse wheel scrolling (vertical only)
        if mouse_state.scroll_y != 0.0
            handle_vertical_scroll_wheel(view, Float32(mouse_state.scroll_y))
            interaction_occurred = true
        end

        # Calculate viewport dimensions
        scrollbar_space = view.show_scrollbar ? view.style.scrollbar_width : 0.0f0
        viewport_width = width - scrollbar_space
        viewport_height = height

        # Handle content area clicks
        if mouse_x >= 0 && mouse_x <= viewport_width &&
           mouse_y >= 0 && mouse_y <= viewport_height

            # Calculate mouse position in content space
            content_mouse_x = mouse_x
            content_mouse_y = mouse_y + view.scroll_state.scroll_offset

            # Check click on the content
            content_layout = apply_layout(view, x, y, width, height)
            content_x, content_y, content_width, content_height = content_layout[1:4]

            # Forward click to content
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

            # Call our own click callback
            if get(mouse_state.was_clicked, LeftButton, false)
                view.on_click(content_mouse_x, content_mouse_y)
                interaction_occurred = true
            end
        end
    end

    return interaction_occurred
end

"""
Detect clicks within the horizontal scroll area
"""
function detect_click(view::HorizontalScrollAreaView, mouse_state::InputState, x::Float32, y::Float32, width::Float32, height::Float32)
    interaction_occurred = false

    # Get mouse position relative to scroll area
    mouse_x = Float32(mouse_state.x) - x
    mouse_y = Float32(mouse_state.y) - y

    # Check if mouse is within the scroll area bounds
    if mouse_x >= 0 && mouse_x <= width && mouse_y >= 0 && mouse_y <= height

        # Handle mouse wheel scrolling (horizontal only)
        if mouse_state.scroll_x != 0.0
            handle_horizontal_scroll_wheel(view, Float32(mouse_state.scroll_x))
            interaction_occurred = true
        end

        # Calculate viewport dimensions
        scrollbar_space = view.show_scrollbar ? view.style.scrollbar_width : 0.0f0
        viewport_width = width
        viewport_height = height - scrollbar_space

        # Handle content area clicks
        if mouse_x >= 0 && mouse_x <= viewport_width &&
           mouse_y >= 0 && mouse_y <= viewport_height

            # Calculate mouse position in content space
            content_mouse_x = mouse_x + view.scroll_state.scroll_offset
            content_mouse_y = mouse_y

            # Check click on the content
            content_layout = apply_layout(view, x, y, width, height)
            content_x, content_y, content_width, content_height = content_layout[1:4]

            # Forward click to content
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

            # Call our own click callback
            if get(mouse_state.was_clicked, LeftButton, false)
                view.on_click(content_mouse_x, content_mouse_y)
                interaction_occurred = true
            end
        end
    end

    return interaction_occurred
end

"""
Handle vertical mouse wheel scrolling
"""
function handle_vertical_scroll_wheel(view::VerticalScrollAreaView, wheel_delta_y::Float32)
    scroll_speed = 30.0f0  # Pixels per wheel tick

    if view.scroll_state.max_scroll > 0.0f0
        new_offset = clamp(
            view.scroll_state.scroll_offset + wheel_delta_y * scroll_speed,
            0.0f0, view.scroll_state.max_scroll
        )

        # Only update if scroll position actually changed
        if new_offset != view.scroll_state.scroll_offset
            new_state = VerticalScrollState(view.scroll_state;
                scroll_offset=new_offset
            )
            view.on_scroll_change(new_state)
            return new_state
        end
    end

    return view.scroll_state
end

"""
Handle horizontal mouse wheel scrolling
"""
function handle_horizontal_scroll_wheel(view::HorizontalScrollAreaView, wheel_delta_x::Float32)
    scroll_speed = 30.0f0  # Pixels per wheel tick

    if view.scroll_state.max_scroll > 0.0f0
        new_offset = clamp(
            view.scroll_state.scroll_offset + wheel_delta_x * scroll_speed,
            0.0f0, view.scroll_state.max_scroll
        )

        # Only update if scroll position actually changed
        if new_offset != view.scroll_state.scroll_offset
            new_state = HorizontalScrollState(view.scroll_state;
                scroll_offset=new_offset
            )
            view.on_scroll_change(new_state)
            return new_state
        end
    end

    return view.scroll_state
end

# Scrollbars are visual-only in this simplified implementation
# Mouse wheel provides the scrolling interaction

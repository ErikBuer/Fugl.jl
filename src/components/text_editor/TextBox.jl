include("text_render_cache.jl")
include("editor_state.jl")
include("editor_action.jl")
include("editor_actions.jl")
include("utilities.jl")
include("draw.jl")
include("text_editor_style.jl")

struct TextBoxView <: AbstractTextEditorView
    state::EditorState           # Editor state containing text, cursor, etc.
    style::TextEditorStyle       # Style for the TextBox (using unified style)
    on_state_change::Function    # Callback for all state changes (focus, text, cursor)
    on_change::Function          # Optional callback for text changes only
    on_focus::Function           # Optional callback for when component gains focus
    on_blur::Function            # Optional callback for when component loses focus
    cache_rendering::Bool        # Whether to use render caching for performance
end

function TextBox(
    state::EditorState;
    style=TextBoxStyle(),  # Use the TextBox-specific default style
    on_state_change::Function=(new_state) -> nothing,
    on_change::Function=(new_text) -> nothing,
    on_focus::Function=() -> nothing,
    on_blur::Function=() -> nothing,
    cache_rendering::Bool=true
)::TextBoxView
    return TextBoxView(state, style, on_state_change, on_change, on_focus, on_blur, cache_rendering)
end

function measure(view::TextBoxView)::Tuple{Float32,Float32}
    return (Inf32, Inf32)
end

function measure_width(view::TextBoxView, available_height::Float32)::Float32
    # TextBox width is determined by the longest line (no wrapping)
    font = view.style.text_style.font
    size_px = view.style.text_style.size_px
    padding = view.style.padding

    lines = get_lines(view.state)
    max_width = 0.0f0

    for line in lines
        line_width = measure_word_width_cached(font, line, size_px)
        max_width = max(max_width, line_width)
    end

    # Add padding on both sides, plus small buffer like Text component
    return max_width + 2 * padding + 2.0f0
end

function measure_height(view::TextBoxView, available_width::Float32)::Float32
    # TextBox height is determined by the number of lines (no wrapping)
    font = view.style.text_style.font
    size_px = view.style.text_style.size_px
    padding = view.style.padding
    line_height = Float32(size_px * 1.2)  # Same line spacing as in render_textbox_content

    lines = get_lines(view.state)
    total_height = length(lines) * line_height + 2 * padding

    return total_height
end

function apply_layout(view::TextBoxView, x::Float32, y::Float32, width::Float32, height::Float32)
    # The TextBox occupies the entire area provided by the parent
    return (x, y, width, height)
end

function interpret_view(view::TextBoxView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32}, mouse_x::Float32, mouse_y::Float32)
    # Skip caching when inside clipped contexts to avoid rendering issues
    if !view.cache_rendering
        render_textbox_immediate(view, x, y, width, height, projection_matrix)
        return
    end

    # Use render caching for TextBox to improve performance with large text content
    bounds = (x, y, width, height)
    cache_width = Int32(round(width))
    cache_height = Int32(round(height))

    # Get text render cache using state's cache ID
    cache = get_render_cache(view.state.cache_id)

    # Generate content hash for this text component
    content_hash = hash_text_content(view.state.text, view.style, view.state.is_focused, view.state.cursor, (view.state.selection_start, view.state.selection_end))

    # Check if we need to invalidate cache
    needs_redraw = should_invalidate_cache(cache, content_hash, bounds)

    if needs_redraw
        # Create new framebuffer if needed
        if cache.framebuffer === nothing || cache.cache_width != cache_width || cache.cache_height != cache_height
            if cache_width > 0 && cache_height > 0
                (framebuffer, color_texture, depth_texture) = create_render_framebuffer(cache_width, cache_height; with_depth=false)

                # Update cache with new framebuffer and content hash
                update_cache!(cache, framebuffer, color_texture, depth_texture, content_hash, bounds)
            else
                # Invalid size, skip rendering
                return
            end
        else
            # Update cache with existing framebuffer and new content hash
            update_cache!(cache, cache.framebuffer, cache.color_texture, cache.depth_texture, content_hash, bounds)
        end

        # Render to framebuffer
        render_textbox_to_framebuffer(view, cache, width, height, projection_matrix)
    end

    # Draw cached texture to screen
    if cache.is_valid && cache.color_texture !== nothing
        draw_cached_texture(cache.color_texture, x, y, width, height, projection_matrix)
    else
        # Fallback to immediate rendering if cache failed
        render_textbox_immediate(view, x, y, width, height, projection_matrix)
    end
end

function render_textbox_to_framebuffer(view::TextBoxView, cache::RenderCache, width::Float32, height::Float32, projection_matrix::Mat4{Float32})
    # Push current framebuffer and viewport onto stacks
    push_framebuffer!(cache.framebuffer)
    push_viewport!(Int32(0), Int32(0), cache.cache_width, cache.cache_height)

    try
        # Clear framebuffer with transparent background
        ModernGL.glClearColor(0.0f0, 0.0f0, 0.0f0, 0.0f0)
        ModernGL.glClear(ModernGL.GL_COLOR_BUFFER_BIT)

        # Create framebuffer-specific projection matrix
        fb_projection = get_orthographic_matrix(0.0f0, width, height, 0.0f0, -1.0f0, 1.0f0)

        # Render TextBox content to framebuffer
        render_textbox_content(view, 0.0f0, 0.0f0, width, height, fb_projection)
    finally
        # Always restore previous framebuffer and viewport, even if there's an exception
        pop_viewport!()
        pop_framebuffer!()
    end
end

function render_textbox_immediate(view::TextBoxView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32})
    # Render TextBox content directly (fallback)
    render_textbox_content(view, x, y, width, height, projection_matrix)
end

function render_textbox_content(view::TextBoxView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32})
    # Extract style properties
    font = view.style.text_style.font
    size_px = view.style.text_style.size_px
    color = view.style.text_style.color
    padding = view.style.padding

    # Render the background with rounded corners
    bg_color = view.state.is_focused ?
               view.style.background_color_focused :
               view.style.background_color_unfocused

    vertex_positions = generate_rectangle_vertices(x, y, width, height)
    draw_rounded_rectangle(
        vertex_positions,
        width,
        height,
        bg_color,
        view.style.border_color,
        view.style.border_width,
        view.style.corner_radius,
        projection_matrix,
        1.5f0
    )

    # Split the text into lines
    lines = get_lines(view.state)

    # Render each line (plain text, no syntax highlighting for TextBox)
    current_y = y + size_px + padding
    line_height = Float32(size_px * 1.2)  # Add some line spacing

    for (line_num, line) in enumerate(lines)
        if current_y > y + height - padding
            break  # Don't render lines outside the visible area
        end

        # Draw selection background if there's a selection
        if has_selection(view.state)
            selection_start, selection_end = get_selection_range(view.state)
            if selection_start !== nothing && selection_end !== nothing
                draw_selection_background(
                    line,
                    line_num,
                    selection_start,
                    selection_end,
                    font,
                    x + padding,
                    current_y,
                    size_px,
                    projection_matrix,
                    view.style.selection_color  # Use configurable selection color from style
                )
            end
        end

        # Render the line as plain text
        draw_text(
            font,                # Font face
            line,                # Text string
            x + padding,         # X position with padding
            current_y,           # Y position
            size_px,             # Text size
            projection_matrix,   # Projection matrix
            color                # Text color
        )

        # Draw cursor if it's on this line and textbox is focused
        if view.state.is_focused && view.state.cursor.line == line_num
            draw_cursor(
                view.state.cursor,
                line,
                font,
                x + padding,
                current_y,
                size_px,
                projection_matrix,
                view.style.cursor_color  # Use the cursor color from style
            )
        end

        current_y += line_height
    end
end

"""
Detect click events and handle focus, cursor positioning, drag selection, and double-clicks for TextBox.
"""
function detect_click(view::TextBoxView, mouse_state::InputState, x::Float32, y::Float32, width::Float32, height::Float32, parent_z::Int32)::Union{ClickResult,Nothing}
    if view.state.is_focused
        handle_key_input(view, mouse_state)  # Handle key input if focused. Key input is unaffected by capturing.
    end

    # Check if mouse is inside component
    mouse_inside = inside_component(view, x, y, width, height, mouse_state.x, mouse_state.y)

    if !mouse_inside
        # Mouse clicked outside component
        if view.state.is_focused && (mouse_state.was_clicked[LeftButton] || mouse_state.was_double_clicked[LeftButton])
            # Focus change - create new state with focus=false
            blur_action() = begin
                new_state = EditorState(view.state; is_focused=false)
                view.on_state_change(new_state)
                view.on_blur()  # Call blur callback
            end
            return ClickResult(Int32(parent_z + 1), () -> blur_action())
        end
        return nothing # Independent of click capturing
    end

    z = Int32(parent_z + 1)

    # Calculate cursor position from mouse coordinates
    new_cursor_pos = mouse_to_cursor_position(
        view.state,
        view.style.text_style.font,
        view.style.text_style.size_px,
        view.style.padding,
        mouse_state.x,
        mouse_state.y,
        x, y, width, height
    )

    # Handle different mouse events
    if mouse_state.was_double_clicked[LeftButton]
        # Double-click: select word
        action = SelectWord(new_cursor_pos)
        new_state = apply_editor_action(view.state, action)
        was_unfocused = !view.state.is_focused
        new_state = EditorState(new_state.text, new_state.cursor, true, new_state.selection_start, new_state.selection_end, new_state.cached_lines, new_state.text_hash, new_state.cache_id)

        handle_double_click() = begin
            view.on_state_change(new_state)
            if was_unfocused
                view.on_focus()  # Call focus callback if component gained focus
            end
        end
        return ClickResult(z, () -> handle_double_click())

    elseif mouse_state.button_state[LeftButton] == IsPressed && mouse_state.is_dragging[LeftButton]
        # Mouse drag: extend selection
        action = ExtendMouseSelection(new_cursor_pos)
        new_state = apply_editor_action(view.state, action)

        handle_drag() = view.on_state_change(new_state)
        return ClickResult(z, () -> handle_drag())

    elseif mouse_state.button_state[LeftButton] == IsPressed && mouse_state.drag_start_position[LeftButton] !== nothing && !mouse_state.is_dragging[LeftButton]
        # Mouse press (start of potential drag): start selection
        action = StartMouseSelection(new_cursor_pos)
        new_state = apply_editor_action(view.state, action)

        # Also handle focus if needed
        was_unfocused = !view.state.is_focused
        if !view.state.is_focused
            new_state = EditorState(new_state.text, new_state.cursor, true, new_state.selection_start, new_state.selection_end, new_state.cached_lines, new_state.text_hash, new_state.cache_id)
        end

        handle_press() = begin
            view.on_state_change(new_state)
            if was_unfocused
                view.on_focus()  # Call focus callback
            end
        end
        return ClickResult(z, () -> handle_press())

    elseif mouse_state.button_state[LeftButton] == IsReleased && has_selection(view.state)
        # Mouse released after dragging with selection: keep selection and don't move cursor
        # No state change needed - selection and cursor position are already correct from the drag operation
        return nothing

    elseif mouse_state.was_clicked[LeftButton]
        # Simple click: move cursor and clear selection
        if !view.state.is_focused
            # Focus change and cursor positioning
            new_state = EditorState(
                view.state.text,
                new_cursor_pos,
                true,
                nothing,  # Clear selection on click
                nothing,
                view.state.cached_lines,
                view.state.text_hash,
                view.state.cache_id
            )

            handle_focus_click() = begin
                view.on_state_change(new_state)
                view.on_focus()  # Call focus callback
            end
            return ClickResult(z, () -> handle_focus_click())
        else
            # Just cursor positioning - clear selection
            new_state = EditorState(
                view.state.text,
                new_cursor_pos,
                view.state.is_focused,
                nothing,  # Clear selection on click
                nothing,
                view.state.cached_lines,
                view.state.text_hash,
                view.state.cache_id
            )

            handle_click() = view.on_state_change(new_state)
            return ClickResult(z, () -> handle_click())
        end
    end

    return nothing
end

"""
Handle key input for TextBox (same as CodeEditor but without syntax highlighting).
"""
function handle_key_input(view::TextBoxView, mouse_state::InputState)
    if !view.state.is_focused
        return  # Only handle key input when the TextBox is focused
    end

    text_changed = false
    cursor_changed = false
    selection_changed = false
    current_state = view.state

    # Handle special key events first (arrow keys, enter, tab, etc.)
    for key_event in mouse_state.key_events
        if Int(key_event.action) == Int(GLFW.PRESS) || Int(key_event.action) == Int(GLFW.REPEAT)
            action = key_event_to_action(key_event)
            if action !== nothing
                old_cursor = current_state.cursor
                old_text = current_state.text
                old_selection_start = current_state.selection_start
                old_selection_end = current_state.selection_end
                current_state = apply_editor_action(current_state, action)

                # Check if text changed
                if action isa InsertText || action isa DeleteText
                    text_changed = true
                end

                # Check if cursor changed (for any action including MoveCursor)
                if current_state.cursor != old_cursor
                    cursor_changed = true
                end

                # Check if selection changed
                if current_state.selection_start != old_selection_start || current_state.selection_end != old_selection_end
                    selection_changed = true
                end
            end
        end
    end

    # Handle regular character input (but skip special characters that are handled above)
    for key in mouse_state.key_buffer
        # Skip special characters that are handled by key events
        if key != '\n' && key != '\t' && key != '\b'  # Skip newline, tab, and backspace
            old_text = current_state.text
            action = InsertText(string(key))
            current_state = apply_editor_action(current_state, action)
            text_changed = true
            cursor_changed = true  # Text insertion also moves cursor
        end
    end

    # Trigger callbacks if text, cursor, or selection changed
    if text_changed || cursor_changed || selection_changed
        # Always call the state change callback
        view.on_state_change(current_state)

        # Additionally call the text change callback if text actually changed
        if text_changed
            view.on_change(current_state.text)
        end
    end
end
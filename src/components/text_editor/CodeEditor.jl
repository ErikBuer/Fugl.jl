# Common text editor includes are handled in TextBox.jl which is loaded first

#TODO consider merging with TextBox.
struct CodeEditorView <: AbstractTextEditorView
    state::EditorState           # Editor state containing text, cursor, etc.
    style::TextEditorStyle       # Style for the CodeEditor (using unified style)
    on_state_change::Function    # Callback for all state changes (focus, text, cursor)
    on_change::Function          # Optional callback for text changes only
    on_focus::Function           # Optional callback for when component gains focus
    on_blur::Function            # Optional callback for when component loses focus
end

function CodeEditor(
    state::EditorState;
    style=CodeEditorStyle(),  # Use the CodeEditor-specific default style
    on_state_change::Function=(new_state) -> nothing,
    on_change::Function=(new_text) -> nothing,
    on_focus::Function=() -> nothing,
    on_blur::Function=() -> nothing
)
    return CodeEditorView(state, style, on_state_change, on_change, on_focus, on_blur)
end

function measure(view::CodeEditorView)::Tuple{Float32,Float32}
    # The CodeEditor fills the parent container, so it doesn't have intrinsic size
    return (0.0f0, 0.0f0)
end

function apply_layout(view::CodeEditorView, x::Float32, y::Float32, width::Float32, height::Float32)
    # The CodeEditor occupies the entire area provided by the parent
    return (x, y, width, height)
end

function interpret_view(view::CodeEditorView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32}, mouse_x::Float32, mouse_y::Float32)
    # Use render caching for CodeEditor to improve performance with syntax highlighting
    bounds = (x, y, width, height)
    cache_width = Int32(round(width))
    cache_height = Int32(round(height))

    # Get text render cache using state's cache ID
    cache = get_render_cache(view.state.cache_id)

    # Generate content hash for this code editor component
    content_hash = hash_text_content(view.state.text, view.style, view.state.is_focused, view.state.cursor, (view.state.selection_start, view.state.selection_end), view.state.scroll_offset_y, view.state.scroll_offset_x)

    # Check if we need to invalidate cache
    needs_redraw = should_invalidate_cache(cache, content_hash, bounds)

    if needs_redraw
        # Create new framebuffer if needed
        if cache.framebuffer === nothing || cache.cache_width != cache_width || cache.cache_height != cache_height
            if cache_width > 0 && cache_height > 0
                try
                    (framebuffer, color_texture, depth_texture) = create_render_framebuffer(cache_width, cache_height; with_depth=false)

                    # Update cache with new framebuffer and content hash
                    update_cache!(cache, framebuffer, color_texture, depth_texture, content_hash, bounds)
                catch e
                    @warn "Failed to create code editor framebuffer: $e"
                    # Fall back to immediate rendering
                    render_codeeditor_immediate(view, x, y, width, height, projection_matrix)
                    return
                end
            else
                # Invalid size, skip rendering
                return
            end
        else
            # Update cache with existing framebuffer and new content hash
            update_cache!(cache, cache.framebuffer, cache.color_texture, cache.depth_texture, content_hash, bounds)
        end

        # Render to framebuffer
        render_codeeditor_to_framebuffer(view, cache, width, height, projection_matrix)
    end

    # Draw cached texture to screen
    if cache.is_valid && cache.color_texture !== nothing
        draw_cached_texture(cache.color_texture, x, y, width, height, projection_matrix)
    else
        # Fallback to immediate rendering if cache failed
        render_codeeditor_immediate(view, x, y, width, height, projection_matrix)
    end
end

function render_codeeditor_to_framebuffer(view::CodeEditorView, cache::RenderCache, width::Float32, height::Float32, projection_matrix::Mat4{Float32})
    # Push current framebuffer and viewport onto stacks
    push_framebuffer!(cache.framebuffer)
    push_viewport!(Int32(0), Int32(0), cache.cache_width, cache.cache_height)

    try
        # Clear framebuffer with transparent background
        ModernGL.glClearColor(0.0f0, 0.0f0, 0.0f0, 0.0f0)
        ModernGL.glClear(ModernGL.GL_COLOR_BUFFER_BIT)

        # Create framebuffer-specific projection matrix
        fb_projection = get_orthographic_matrix(0.0f0, width, height, 0.0f0, -1.0f0, 1.0f0)

        # Render CodeEditor content with syntax highlighting to framebuffer
        render_codeeditor_content(view, 0.0f0, 0.0f0, width, height, fb_projection)
    finally
        # Always restore previous framebuffer and viewport, even if there's an exception
        pop_viewport!()
        pop_framebuffer!()
    end
end

function render_codeeditor_immediate(view::CodeEditorView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32})
    # Render CodeEditor content directly with culling (no scissor test)
    render_codeeditor_content(view, x, y, width, height, projection_matrix)
end

function render_codeeditor_content(view::CodeEditorView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32})
    # Extract style properties
    font = get_font(view.style.text_style)
    size_px = view.style.text_style.size_px
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

    # Apply scroll offsets
    scroll_y = view.state.scroll_offset_y
    scroll_x = view.state.scroll_offset_x

    # Render each line with syntax highlighting
    current_y = y + size_px + padding
    line_height = Float32(size_px * 1.2)  # Add some line spacing

    # Calculate visible line range for culling
    visible_height = height - 2 * padding
    max_visible_lines = Int(ceil(visible_height / line_height))
    start_line = scroll_y + 1
    end_line = min(length(lines), scroll_y + max_visible_lines + 1)

    for line_num in start_line:end_line
        line = lines[line_num]

        # Calculate Y position with scroll offset
        display_line_index = line_num - scroll_y
        display_y = y + size_px + padding + (display_line_index - 1) * line_height

        # Cull lines outside visible area
        if display_y < y + padding || display_y > y + height - padding
            continue
        end

        # Get tokenization data for this line
        line_data = get_tokenized_line(view.state, line_num)

        # Calculate visible width for horizontal culling
        visible_width = width - 2 * padding

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
                    x + padding - scroll_x,
                    display_y,
                    size_px,
                    projection_matrix,
                    view.style.selection_color;  # Use configurable selection color from style
                    visible_start_x=x + padding,
                    visible_end_x=x + padding + visible_width
                )
            end
        end

        # Render the line using cached tokenization with horizontal scroll offset and culling
        render_line_from_cache(
            line_data,
            font,
            x + padding - scroll_x,  # Left padding with horizontal scroll
            display_y,
            size_px,
            projection_matrix;
            visible_width=visible_width,
            start_x=x + padding
        )

        # Draw cursor if it's on this line and editor is focused
        if view.state.is_focused && view.state.cursor.line == line_num
            draw_cursor(
                view.state.cursor,
                line,
                font,
                x + padding - scroll_x,
                display_y,
                size_px,
                projection_matrix,
                view.style.cursor_color  # Use the cursor color from style
            )
        end
    end
end

function blur(view::CodeEditorView)
    if view.state.is_focused
        new_state = EditorState(view.state; is_focused=false)
        view.on_state_change(new_state)
        view.on_blur()  # Call blur callback. Runs no matter what z-height.
    end
end

"""
Detect click events and handle focus, cursor positioning, drag selection, and double-clicks.
"""
function detect_click(view::CodeEditorView, mouse_state::InputState, x::Float32, y::Float32, width::Float32, height::Float32, parent_z::Int32)::Union{ClickResult,Nothing}
    if view.state.is_focused
        handle_key_input(view, mouse_state, width, height)  # Handle key input if focused. Key input is uaffected by capturing.
    end

    # Check if mouse is inside component
    mouse_inside = inside_component(view, x, y, width, height, mouse_state.x, mouse_state.y)

    # Handle scroll wheel events when mouse is over component
    if mouse_inside && (mouse_state.scroll_y != 0.0 || mouse_state.scroll_x != 0.0)
        lines = get_lines(view.state)
        padding = view.style.padding
        size_px = view.style.text_style.size_px
        line_height = Float32(size_px * 1.2)
        visible_height = height - 2 * padding
        visible_width = width - 2 * padding
        max_visible_lines = Int(ceil(visible_height / line_height))
        max_scroll_y = max(0, length(lines) - max_visible_lines)

        # Check if Shift key is pressed - if so, convert vertical scroll to horizontal
        shift_pressed = mouse_state.modifier_keys.shift

        # Only allow scrolling if content extends beyond visible area
        can_scroll_vertically = max_scroll_y > 0

        if shift_pressed && mouse_state.scroll_y != 0.0
            # Shift + scroll: use vertical scroll for horizontal scrolling
            horizontal_scroll_amount = 20.0f0  # Pixels per scroll notch
            new_scroll_x = if mouse_state.scroll_y > 0.0
                max(0.0f0, view.state.scroll_offset_x - horizontal_scroll_amount)  # Scroll left
            else
                view.state.scroll_offset_x + horizontal_scroll_amount  # Scroll right
            end
            new_scroll_y = view.state.scroll_offset_y  # Don't change vertical scroll
        else
            # Normal scroll: vertical scrolling (only if content exceeds visible area)
            new_scroll_y = if can_scroll_vertically && mouse_state.scroll_y > 0.0
                max(0, view.state.scroll_offset_y - 1)  # Scroll up
            elseif can_scroll_vertically && mouse_state.scroll_y < 0.0
                min(max_scroll_y, view.state.scroll_offset_y + 1)  # Scroll down
            else
                view.state.scroll_offset_y
            end

            # Also handle native horizontal scroll from trackpad
            horizontal_scroll_amount = 20.0f0  # Pixels per scroll notch
            new_scroll_x = if mouse_state.scroll_x > 0.0
                max(0.0f0, view.state.scroll_offset_x - horizontal_scroll_amount)  # Scroll left
            elseif mouse_state.scroll_x < 0.0
                view.state.scroll_offset_x + horizontal_scroll_amount  # Scroll right
            else
                view.state.scroll_offset_x
            end
        end

        if new_scroll_y != view.state.scroll_offset_y || new_scroll_x != view.state.scroll_offset_x
            z = Int32(parent_z + 1)
            scroll_action() = begin
                new_state = EditorState(view.state; scroll_offset_y=new_scroll_y, scroll_offset_x=new_scroll_x)
                view.on_state_change(new_state)
            end
            return ClickResult(z, () -> scroll_action())
        end
    end

    # Check if we're currently dragging from inside the component (like HorizontalSlider)
    is_dragging_from_inside = mouse_state.is_dragging[LeftButton] &&
                              mouse_state.drag_start_position[LeftButton] !== nothing &&
                              inside_component(view, x, y, width, height,
                                  mouse_state.drag_start_position[LeftButton]...)

    # Handle selection dragging even when mouse is outside component
    if is_dragging_from_inside && !mouse_inside
        z = Int32(parent_z + 1)

        # Calculate cursor position from mouse coordinates (allow outside bounds)
        text_font = get_font(view.style.text_style)
        new_cursor_pos = mouse_to_cursor_position(
            view.state,
            text_font,
            view.style.text_style.size_px,
            view.style.padding,
            mouse_state.x,
            mouse_state.y,
            x, y, width, height
        )

        # Extend selection during drag
        action = ExtendMouseSelection(new_cursor_pos)
        new_state = apply_editor_action(view.state, action)

        handle_drag_outside_editor() = view.on_state_change(new_state)
        return ClickResult(z, () -> handle_drag_outside_editor())
    end

    if !mouse_inside
        # Mouse clicked outside component
        if view.state.is_focused && (mouse_state.mouse_down[LeftButton])
            blur(view)
        end
        return nothing # Independent of click capturing
    end

    z = Int32(parent_z + 1)

    # Calculate cursor position from mouse coordinates
    text_font = get_font(view.style.text_style)
    new_cursor_pos = mouse_to_cursor_position(
        view.state,
        text_font,
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
        new_state = EditorState(new_state.text, new_state.cursor, true, new_state.selection_start, new_state.selection_end, new_state.cached_lines, new_state.text_hash, new_state.cache_id, new_state.scroll_offset_y, new_state.scroll_offset_x)

        handle_double_click() = begin
            view.on_state_change(new_state)
            if was_unfocused
                view.on_focus()  # Call focus callback if component gained focus
            end
        end
        return ClickResult(z, () -> handle_double_click())

    elseif mouse_state.button_state[LeftButton] == IsPressed &&
           mouse_state.is_dragging[LeftButton] &&
           mouse_state.drag_start_position[LeftButton] !== nothing &&
           inside_component(view, x, y, width, height, mouse_state.drag_start_position[LeftButton]...)
        # Mouse drag: extend selection (only if drag started inside)
        action = ExtendMouseSelection(new_cursor_pos)
        new_state = apply_editor_action(view.state, action)

        handle_drag_inside() = view.on_state_change(new_state)
        return ClickResult(z, () -> handle_drag_inside())

    elseif mouse_state.mouse_down[LeftButton] && mouse_state.drag_start_position[LeftButton] !== nothing && !mouse_state.is_dragging[LeftButton]
        # Mouse press (start of potential drag): start selection
        action = StartMouseSelection(new_cursor_pos)
        new_state = apply_editor_action(view.state, action)

        # Also handle focus if needed
        was_unfocused = !view.state.is_focused
        if !view.state.is_focused
            new_state = EditorState(new_state.text, new_state.cursor, true, new_state.selection_start, new_state.selection_end, new_state.cached_lines, new_state.text_hash, new_state.cache_id, new_state.scroll_offset_y, new_state.scroll_offset_x)
        end

        handle_click_or_drag() = begin
            view.on_state_change(new_state)
            if was_unfocused
                view.on_focus()  # Call focus callback
            end
        end
        return ClickResult(z, () -> handle_click_or_drag())

    elseif mouse_state.button_state[LeftButton] == IsReleased && has_selection(view.state)
        # Mouse released after dragging with selection: keep selection and don't move cursor
        # No state change needed - selection and cursor position are already correct from the drag operation
        return nothing

    elseif mouse_state.mouse_down[LeftButton]
        # Simple click: move cursor and clear selection
        if !view.state.is_focused
            # Focus change and cursor positioning
            new_state = EditorState(
                view.state.text,
                new_cursor_pos,
                true,     # Focus the component on click
                nothing,  # Clear selection on click
                nothing,
                view.state.cached_lines,
                view.state.text_hash,
                view.state.cache_id,
                view.state.scroll_offset_y,
                view.state.scroll_offset_x
            )
            handle_focus_and_click() = begin
                view.on_state_change(new_state)
                view.on_focus()  # Call focus callback
            end
            return ClickResult(z, () -> handle_focus_and_click())

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
                view.state.cache_id,
                view.state.scroll_offset_y,
                view.state.scroll_offset_x
            )
            return ClickResult(z, () -> view.on_state_change(new_state))
        end
    end

    return nothing
end

function handle_key_input(view::CodeEditorView, mouse_state::InputState, width::Float32, height::Float32)
    if !view.state.is_focused
        return  # Only handle key input when the CodeEditor is focused
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
        # Ensure cursor is visible by adjusting scroll offsets if needed
        font = get_font(view.style.text_style)
        size_px = view.style.text_style.size_px
        padding = view.style.padding

        # Calculate visible area (width and height minus padding)
        visible_width = width - 2 * padding
        visible_height = height - 2 * padding

        current_state = ensure_cursor_visible(
            current_state,
            font,
            size_px,
            visible_width,
            visible_height,
            padding
        )

        # Always call the state change callback
        view.on_state_change(current_state)

        # Additionally call the text change callback if text actually changed
        if text_changed
            view.on_change(current_state.text)
        end
    end
end
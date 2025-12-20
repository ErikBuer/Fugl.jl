# Common text editor includes are handled in TextBox.jl which is loaded first

struct CodeEditorView <: AbstractTextEditorView
    state::EditorState           # Editor state containing text, cursor, etc.
    style::TextEditorStyle       # Style for the CodeEditor (using unified style)
    on_state_change::Function    # Callback for all state changes (focus, text, cursor)
    on_change::Function          # Optional callback for text changes only
end

function CodeEditor(
    state::EditorState;
    style=CodeEditorStyle(),  # Use the CodeEditor-specific default style
    on_state_change::Function=(new_state) -> nothing,
    on_change::Function=(new_text) -> nothing
)
    return CodeEditorView(state, style, on_state_change, on_change)
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
    content_hash = hash_text_content(view.state.text, view.style, view.state.is_focused, view.state.cursor, (view.state.selection_start, view.state.selection_end))

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
    # Render CodeEditor content directly (fallback)
    render_codeeditor_content(view, x, y, width, height, projection_matrix)
end

function render_codeeditor_content(view::CodeEditorView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32})
    # Extract style properties
    font = view.style.text_style.font
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

    # Render each line with syntax highlighting
    current_y = y + size_px + padding
    line_height = Float32(size_px * 1.2)  # Add some line spacing

    for (line_num, line) in enumerate(lines)
        if current_y > y + height - padding
            break  # Don't render lines outside the visible area
        end

        # Get tokenization data for this line
        line_data = get_tokenized_line(view.state, line_num)

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

        # Render the line using cached tokenization
        render_line_from_cache(
            line_data,
            font,
            x + padding,  # Left padding
            current_y,
            size_px,
            projection_matrix
        )

        # Draw cursor if it's on this line and editor is focused
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
Detect click events and handle focus, cursor positioning, drag selection, and double-clicks.
"""
function detect_click(view::CodeEditorView, mouse_state::InputState, x::Float32, y::Float32, width::Float32, height::Float32)
    if view.state.is_focused
        handle_key_input(view, mouse_state)  # Handle key input if focused
    end

    # Check if mouse is inside component
    mouse_inside = inside_component(view, x, y, width, height, mouse_state.x, mouse_state.y)

    if mouse_inside
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
            new_state = EditorState(new_state.text, new_state.cursor, true, new_state.selection_start, new_state.selection_end, new_state.cached_lines, new_state.text_hash, new_state.cache_id)
            view.on_state_change(new_state)

        elseif mouse_state.button_state[LeftButton] == IsPressed && mouse_state.is_dragging[LeftButton]
            # Mouse drag: extend selection
            action = ExtendMouseSelection(new_cursor_pos)
            new_state = apply_editor_action(view.state, action)
            view.on_state_change(new_state)

        elseif mouse_state.button_state[LeftButton] == IsPressed && mouse_state.drag_start_position[LeftButton] !== nothing && !mouse_state.is_dragging[LeftButton]
            # Mouse press (start of potential drag): start selection
            action = StartMouseSelection(new_cursor_pos)
            new_state = apply_editor_action(view.state, action)

            # Also handle focus if needed
            if !view.state.is_focused
                new_state = EditorState(new_state.text, new_state.cursor, true, new_state.selection_start, new_state.selection_end, new_state.cached_lines, new_state.text_hash, new_state.cache_id)
            end
            view.on_state_change(new_state)

        elseif mouse_state.button_state[LeftButton] == IsReleased && has_selection(view.state)
            # Mouse released after dragging with selection: keep selection and don't move cursor
            # No state change needed - selection and cursor position are already correct from the drag operation
            return

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
                    view.state.text_hash
                )
                view.on_state_change(new_state)
            else
                # Just cursor positioning - clear selection
                new_state = EditorState(
                    view.state.text,
                    new_cursor_pos,
                    view.state.is_focused,
                    nothing,  # Clear selection on click
                    nothing,
                    view.state.cached_lines,
                    view.state.text_hash
                )
                view.on_state_change(new_state)
            end
        end
        return
    end

    # Mouse clicked outside component
    if view.state.is_focused && (mouse_state.was_clicked[LeftButton] || mouse_state.was_double_clicked[LeftButton])
        # Focus change - create new state with focus=false
        new_state = EditorState(view.state; is_focused=false)
        view.on_state_change(new_state)
    end
end

function handle_key_input(view::CodeEditorView, mouse_state::InputState)
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
        # Always call the state change callback
        view.on_state_change(current_state)

        # Additionally call the text change callback if text actually changed
        if text_changed
            view.on_change(current_state.text)
        end
    end
end
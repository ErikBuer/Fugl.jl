include("editor_state.jl")
include("editor_action.jl")
include("editor_actions.jl")  # The action application functions
include("utilities.jl")
include("draw.jl")
include("text_editor_style.jl")  # Unified style structure

struct TextBoxView <: AbstractTextEditorView
    state::EditorState           # Editor state containing text, cursor, etc.
    style::TextEditorStyle       # Style for the TextBox (using unified style)
    on_state_change::Function    # Callback for all state changes (focus, text, cursor)
    on_change::Function          # Optional callback for text changes only
end

function TextBox(
    state::EditorState;
    style=TextBoxStyle(),  # Use the TextBox-specific default style
    on_state_change::Function=(new_state) -> nothing,
    on_change::Function=(new_text) -> nothing
)::TextBoxView
    return TextBoxView(state, style, on_state_change, on_change)
end

function measure(view::TextBoxView)::Tuple{Float32,Float32}
    return (Inf32, Inf32)
end

function apply_layout(view::TextBoxView, x::Float32, y::Float32, width::Float32, height::Float32)
    # The TextBox occupies the entire area provided by the parent
    return (x, y, width, height)
end

function interpret_view(view::TextBoxView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32})
    # Extract style properties
    font = view.style.text_style.font
    size_px = view.style.text_style.size_px
    color = view.style.text_style.color
    padding = view.style.padding_px

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
        view.style.border_width_px,
        view.style.corner_radius_px,
        projection_matrix
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
function detect_click(view::TextBoxView, mouse_state::InputState, x::Float32, y::Float32, width::Float32, height::Float32)
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
            view.style.padding_px,
            mouse_state.x,
            mouse_state.y,
            x, y, width, height
        )

        # Handle different mouse events
        if mouse_state.was_double_clicked[LeftButton]
            # Double-click: select word
            action = SelectWord(new_cursor_pos)
            new_state = apply_editor_action(view.state, action)
            new_state = EditorState(new_state.text, new_state.cursor, true, new_state.selection_start, new_state.selection_end, new_state.cached_lines, new_state.text_hash)
            view.on_state_change(new_state)

        elseif mouse_state.button_state[LeftButton] == IsPressed && mouse_state.is_dragging
            # Mouse drag: extend selection
            action = ExtendMouseSelection(new_cursor_pos)
            new_state = apply_editor_action(view.state, action)
            view.on_state_change(new_state)

        elseif mouse_state.button_state[LeftButton] == IsPressed && mouse_state.drag_start_position !== nothing && !mouse_state.is_dragging
            # Mouse press (start of potential drag): start selection
            action = StartMouseSelection(new_cursor_pos)
            new_state = apply_editor_action(view.state, action)

            # Also handle focus if needed
            if !view.state.is_focused
                new_state = EditorState(new_state.text, new_state.cursor, true, new_state.selection_start, new_state.selection_end, new_state.cached_lines, new_state.text_hash)
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

"""
Handle key input for TextBox (same as CodeEditor but without syntax highlighting).
"""
function handle_key_input(view::TextBoxView, mouse_state::InputState)
    if !view.state.is_focused
        return  # Only handle key input when the TextBox is focused
    end

    text_changed = false
    cursor_changed = false
    current_state = view.state

    # Handle special key events first (arrow keys, enter, tab, etc.)
    for key_event in mouse_state.key_events
        if Int(key_event.action) == Int(GLFW.PRESS) || Int(key_event.action) == Int(GLFW.REPEAT)
            action = key_event_to_action(key_event)
            if action !== nothing
                old_cursor = current_state.cursor
                old_text = current_state.text
                current_state = apply_editor_action(current_state, action)

                # Check if text changed
                if action isa InsertText || action isa DeleteText
                    text_changed = true
                end

                # Check if cursor changed (for any action including MoveCursor)
                if current_state.cursor != old_cursor
                    cursor_changed = true
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

    # Trigger callbacks if either text or cursor changed
    if text_changed || cursor_changed
        # Always call the state change callback
        view.on_state_change(current_state)

        # Additionally call the text change callback if text actually changed
        if text_changed
            view.on_change(current_state.text)
        end
    end
end
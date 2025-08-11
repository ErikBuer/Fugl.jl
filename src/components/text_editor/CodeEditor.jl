mutable struct CodeEditorStyle
    text_style::TextStyle
    background_color_focused::Vec4{<:AbstractFloat}
    background_color_unfocused::Vec4{<:AbstractFloat}
    border_color::Vec4{<:AbstractFloat}
    border_width_px::Float32
    corner_radius_px::Float32
    padding_px::Float32
    cursor_color::Vec4{<:AbstractFloat}
end

function CodeEditorStyle(;
    text_style=TextStyle(),
    background_color_focused=Vec4{Float32}(0.05f0, 0.05f0, 0.1f0, 1.0f0),  # Dark blue when focused
    background_color_unfocused=Vec4{Float32}(0.1f0, 0.1f0, 0.15f0, 1.0f0), # Darker when not focused
    border_color=Vec4{Float32}(0.3f0, 0.3f0, 0.4f0, 1.0f0),
    border_width_px=1.0f0,
    corner_radius_px=8.0f0,
    padding_px=10.0f0,
    cursor_color=Vec4{Float32}(1.0f0, 1.0f0, 1.0f0, 0.8f0)  # White cursor for visibility on dark background
)
    return CodeEditorStyle(text_style, background_color_focused, background_color_unfocused, border_color, border_width_px, corner_radius_px, padding_px, cursor_color)
end

struct CodeEditorView <: AbstractView
    state::EditorState           # Editor state containing text, cursor, etc.
    style::CodeEditorStyle       # Style for the CodeEditor
    on_state_change::Function    # Callback for all state changes (focus, text, cursor)
    on_change::Function          # Optional callback for text changes only
end

function CodeEditor(
    state::EditorState;
    style=CodeEditorStyle(),
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

function interpret_view(view::CodeEditorView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32})
    # Extract style properties
    font = view.style.text_style.font
    size_px = view.style.text_style.size_px
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

    # Render each line with syntax highlighting
    current_y = y + size_px + padding
    line_height = Float32(size_px * 1.2)  # Add some line spacing

    for (line_num, line) in enumerate(lines)
        if current_y > y + height - padding
            break  # Don't render lines outside the visible area
        end

        # Get tokenization data for this line
        line_data = get_line_tokenized(view.state, line_num, line)

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
Detect click events and handle focus and cursor positioning.
"""
function detect_click(view::CodeEditorView, mouse_state::InputState, x::Float32, y::Float32, width::Float32, height::Float32)
    if view.state.is_focused
        handle_key_input(view, mouse_state)  # Handle key input if focused
    end

    if !(mouse_state.button_state[LeftButton] == IsPressed)
        return  # Only handle clicks when the left button is pressed
    end

    if inside_component(view, x, y, width, height, mouse_state.x, mouse_state.y)
        # Calculate cursor position from mouse coordinates
        new_cursor_pos = mouse_to_cursor_position(view, mouse_state.x, mouse_state.y, x, y, width, height)

        if !view.state.is_focused
            # Focus change and cursor positioning - create new state with focus=true and new cursor position
            new_state = EditorState(view.state.text, new_cursor_pos, true, view.state.cached_lines, view.state.text_hash)
            view.on_state_change(new_state)
        else
            # Just cursor positioning - update cursor position
            new_state = EditorState(view.state.text, new_cursor_pos, view.state.is_focused, view.state.cached_lines, view.state.text_hash)
            view.on_state_change(new_state)
        end
        return
    end

    if view.state.is_focused
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

"""
Convert mouse coordinates to cursor position within the editor.
"""
function mouse_to_cursor_position(view::CodeEditorView, mouse_x::Float64, mouse_y::Float64, x::Float32, y::Float32, width::Float32, height::Float32)::CursorPosition
    font = view.style.text_style.font
    size_px = view.style.text_style.size_px
    padding = view.style.padding_px

    # Calculate which line the mouse is on
    text_start_y = y + size_px + padding
    line_height = Float32(size_px * 1.2)

    lines = get_lines(view.state)

    # Calculate line number (1-based)
    # We need to account for the fact that text is rendered at the baseline
    # The first line starts at text_start_y, so we adjust accordingly
    relative_y = Float32(mouse_y) - (text_start_y - size_px / 2)  # Adjust to center of first line
    line_number = max(1, min(length(lines), Int(round(relative_y / line_height)) + 1))

    # If we have no lines, return cursor at (1,1)
    if isempty(lines)
        return CursorPosition(1, 1)
    end

    # Get the line text
    if line_number > length(lines)
        # Mouse is below all text, put cursor at end of last line
        line_text = lines[end]
        line_number = length(lines)
    else
        line_text = lines[line_number]
    end

    # Calculate which character position the mouse is on
    text_start_x = x + padding
    relative_x = Float32(mouse_x) - text_start_x

    # If mouse is before the text starts, put cursor at beginning of line
    if relative_x <= 0
        return CursorPosition(line_number, 1)
    end

    # Find the character position by measuring text width
    current_x = 0.0f0
    column = 1

    # Convert string to characters for proper Unicode handling
    chars = collect(line_text)

    for (i, char) in enumerate(chars)
        # Measure width of this character
        char_width = measure_word_width(font, string(char), size_px)

        # If we're past the halfway point of this character, cursor goes after it
        if relative_x <= current_x + char_width / 2
            break
        end

        current_x += char_width
        column = i + 1
    end

    # Ensure column is within bounds
    column = min(column, length(chars) + 1)

    return CursorPosition(line_number, column)
end

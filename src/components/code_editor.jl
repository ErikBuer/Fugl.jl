using GLFW

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
    on_change::Function          # Callback for text changes
    on_focus_change::Function    # Callback for focus changes
end

function CodeEditor(
    state::EditorState;
    style=CodeEditorStyle(),
    on_change::Function=() -> nothing,
    on_focus_change::Function=() -> nothing
)
    return CodeEditorView(state, style, on_change, on_focus_change)
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

        # Ensure this line is tokenized and cached
        line_data = ensure_line_tokenized!(view.state, line_num, line)

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
        if !view.state.is_focused
            view.on_focus_change(true)  # Trigger focus change callback to update state immutably
        end
        return
    end

    if view.state.is_focused
        view.on_focus_change(false)  # Trigger focus change callback to update state immutably
    end
end

function handle_key_input(view::CodeEditorView, mouse_state::InputState)
    if !view.state.is_focused
        return  # Only handle key input when the CodeEditor is focused
    end

    text_changed = false

    # Handle special key events first (arrow keys, enter, tab, etc.)
    for key_event in mouse_state.key_events
        if Int(key_event.action) == Int(GLFW.PRESS) || Int(key_event.action) == Int(GLFW.REPEAT)
            action = key_event_to_action(key_event)
            if action !== nothing
                apply_editor_action!(view.state, action)
                # Only mark as text changed for actions that modify text
                if action isa InsertText || action isa DeleteText
                    text_changed = true
                end
            end
        end
    end

    # Handle regular character input (but skip special characters that are handled above)
    for key in mouse_state.key_buffer
        # Skip special characters that are handled by key events
        if key != '\n' && key != '\t' && key != '\b'  # Skip newline, tab, and backspace
            action = InsertText(string(key))
            apply_editor_action!(view.state, action)
            text_changed = true
        end
    end

    # Only trigger the on_change callback if text actually changed
    if text_changed
        view.on_change(view.state.text)
    end
end

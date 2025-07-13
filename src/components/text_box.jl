using GLFW

mutable struct TextBoxStyle
    text_style::TextStyle
    background_color_focused::Vec4{<:AbstractFloat}
    background_color_unfocused::Vec4{<:AbstractFloat}
    border_color::Vec4{<:AbstractFloat}
    border_width_px::Float32
    corner_radius_px::Float32
    padding_px::Float32
    cursor_color::Vec4{<:AbstractFloat}
end

function TextBoxStyle(;
    text_style=TextStyle(),
    background_color_focused=Vec4{Float32}(1.0f0, 1.0f0, 1.0f0, 1.0f0),    # White when focused
    background_color_unfocused=Vec4{Float32}(0.95f0, 0.95f0, 0.95f0, 1.0f0), # Light gray when not focused
    border_color=Vec4{Float32}(0.8f0, 0.8f0, 0.8f0, 1.0f0),
    border_width_px=1.0f0,
    corner_radius_px=8.0f0,
    padding_px=10.0f0,
    cursor_color=Vec4{Float32}(0.0f0, 0.0f0, 0.0f0, 0.8f0)  # Black cursor for visibility on white background
)
    return TextBoxStyle(text_style, background_color_focused, background_color_unfocused, border_color, border_width_px, corner_radius_px, padding_px, cursor_color)
end

struct TextBoxView <: AbstractView
    state::EditorState           # Editor state containing text, cursor, etc.
    style::TextBoxStyle          # Style for the TextBox
    on_change::Function          # Callback for text changes
    on_focus_change::Function    # Callback for focus changes
end

function TextBox(
    state::EditorState;
    style=TextBoxStyle(),
    on_change::Function=() -> nothing,
    on_focus_change::Function=() -> nothing
)::TextBoxView
    return TextBoxView(state, style, on_change, on_focus_change)
end

function measure(view::TextBoxView)::Tuple{Float32,Float32}
    # The TextBox fills the parent container, so it doesn't have intrinsic size
    return (0.0f0, 0.0f0)
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
Detect click events and handle focus and cursor positioning for TextBox.
"""
function detect_click(view::TextBoxView, mouse_state::InputState, x::Float32, y::Float32, width::Float32, height::Float32)
    if view.state.is_focused
        handle_key_input(view, mouse_state)  # Handle key input if focused
    end

    if !(mouse_state.button_state[LeftButton] == IsPressed)
        return  # Only handle clicks when the left button is pressed
    end

    if inside_component(view, x, y, width, height, mouse_state.x, mouse_state.y)
        if !view.state.is_focused
            view.state.is_focused = true
            view.on_focus_change(true)  # Trigger focus change callback
        end
        return
    end

    if view.state.is_focused
        view.state.is_focused = false
        view.on_focus_change(false)  # Trigger focus change callback
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
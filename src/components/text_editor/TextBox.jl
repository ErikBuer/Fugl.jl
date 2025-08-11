include("editor_action.jl")
include("editor_state.jl")
include("utilities.jl")
include("draw.jl")

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
    border_color=Vec4{Float32}(0.3f0, 0.3f0, 0.3f0, 1.0f0),
    border_width_px=1.0f0,
    corner_radius_px=8.0f0,
    padding_px=10.0f0,
    cursor_color=Vec4{Float32}(0.0f0, 0.0f0, 0.0f0, 0.8f0)  # Black cursor for visibility on white background
)
    return TextBoxStyle(text_style, background_color_focused, background_color_unfocused, border_color, border_width_px, corner_radius_px, padding_px, cursor_color)
end

struct TextBoxView <: AbstractTextEditorView
    state::EditorState           # Editor state containing text, cursor, etc.
    style::TextBoxStyle          # Style for the TextBox
    on_state_change::Function    # Callback for all state changes (focus, text, cursor)
    on_change::Function          # Optional callback for text changes only
end

function TextBox(
    state::EditorState;
    style=TextBoxStyle(),
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
                    Vec4{Float32}(0.3f0, 0.5f0, 0.8f0, 0.3f0)  # Blue selection color
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
        # Calculate cursor position from mouse coordinates using the generic function
        new_cursor_pos = mouse_to_cursor_position(
            view.state,
            view.style.text_style.font,
            view.style.text_style.size_px,
            view.style.padding_px,
            mouse_state.x,
            mouse_state.y,
            x, y, width, height
        )

        if !view.state.is_focused
            # Focus change and cursor positioning - create new state with focus=true and new cursor position
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
            # Just cursor positioning - update cursor position and clear selection
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
        return
    end

    if view.state.is_focused
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
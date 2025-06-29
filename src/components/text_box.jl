struct TextBoxView <: AbstractView
    text::String              # Text content of the TextBox
    is_focused::Bool          # Focus state of the TextBox
    style::TextStyle          # Style for the TextBox
    on_change::Function       # Callback for text changes
    on_focus_change::Function # Callback for focus changes
end

function TextBox(text::String, is_focused; style=TextStyle(), on_change::Function=() -> nothing, on_focus_change::Function=() -> nothing)
    return TextBoxView(text, is_focused, style, on_change, on_focus_change)
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
    font = view.style.font
    size_px = view.style.size_px
    color = view.style.color

    # Render the background
    bg_color = view.is_focused ? Vec4{Float32}(1.0f0, 1.0f0, 1.0f0, 1.0f0) : Vec4{Float32}(0.9f0, 0.9f0, 0.9f0, 1.0f0)
    draw_rectangle(generate_rectangle_vertices(x, y, width, height), bg_color, projection_matrix)

    # Split the text into lines
    lines = split(view.text, "\n")

    # Render each line
    current_y = y + view.style.size_px
    for line in lines
        draw_text(
            font,                # Font face
            line,                # Text string
            x + 10.0f0,          # X position with padding
            current_y,           # Y position
            size_px,             # Text size
            projection_matrix,   # Projection matrix
            color                # Text color
        )
        current_y += size_px
    end
end

function detect_click(view::TextBoxView, mouse_state::MouseState, x::Float32, y::Float32, width::Float32, height::Float32)

    if view.is_focused
        handle_key_input(view, mouse_state)  # Handle key input if focused
    end

    if !(mouse_state.button_state[LeftButton] == IsPressed)
        return  # Only handle clicks when the left button is pressed
    end

    if inside_component(view, x, y, width, height, mouse_state.x, mouse_state.y)
        if !view.is_focused
            view.on_focus_change(true)  # Trigger focus change callback
        end
        return
    end

    if view.is_focused
        view.on_focus_change(false)  # Trigger focus change callback
    end
end

function handle_key_input(view::TextBoxView, mouse_state::MouseState)
    if !view.is_focused
        return  # Only handle key input when the TextBox is focused
    end

    text = view.text  # Start with the current text

    for key in mouse_state.key_buffer

        if key == '\b'  # Handle backspace
            text = view.text[1:end-1]
        else
            text *= string(key)
        end

        # Trigger the on_change callback
        view.on_change(text)
    end
end
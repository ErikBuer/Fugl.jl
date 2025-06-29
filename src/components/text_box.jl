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

function detect_click(view::TextBoxView, mouse_state::MouseState, x::Float32, y::Float32, width::Float32, height::Float32, is_focused::Ref{Bool})
    # Check if the mouse is inside the TextBox
    if is_mouse_inside(mouse_state, x, y, width, height) && mouse_state.button_state[LeftButton] == IsPressed
        view.on_focus_change(true)  # Trigger focus change callback
    elseif mouse_state.button_state[LeftButton] == IsReleased
        view.on_focus_change(false)  # Trigger focus change callback
    end
end

function handle_input(view::TextBoxView, key::Char, is_focused::Bool)
    # Update the text content if the TextBox is focused
    if is_focused
        if key == '\b'  # Handle backspace
            view.text = view.text[1:end-1]
        else
            view.text *= string(key)
        end

        # Trigger the on_change callback
        view.on_change(view.text)
    end
end
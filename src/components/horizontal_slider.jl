mutable struct SliderStyle
    background_color::Vec4{Float32}  # RGBA color for the slider background
    handle_color::Vec4{Float32}      # RGBA color for the slider handle
    border_color::Vec4{Float32}      # RGBA color for the slider border
    border_width_px::Float32         # Border width in pixels
end

function SliderStyle(;
    background_color=Vec4{Float32}(0.8f0, 0.8f0, 0.8f0, 1.0f0),
    handle_color=Vec4{Float32}(0.0f0, 0.0f0, 0.0f0, 1.0f0),
    border_color=Vec4{Float32}(0.0f0, 0.0f0, 0.0f0, 1.0f0),
    border_width_px=1.0f0
)
    return SliderStyle(background_color, handle_color, border_color, border_width_px)
end

mutable struct HorizontalSliderView <: AbstractView
    min_value::Float32          # Minimum value of the slider
    max_value::Float32          # Maximum value of the slider
    current_value::Float32      # Current value of the slider
    style::SliderStyle          # Style for the slider
    on_change::Function         # Callback for value changes
end

function HorizontalSlider(current_value::T, min_value::T, max_value::T; style=SliderStyle(), on_change::Function=() -> nothing) where T<:Real
    return HorizontalSliderView(min_value, max_value, current_value, style, on_change)
end

function apply_layout(view::HorizontalSliderView, x::Float32, y::Float32, width::Float32, height::Float32)
    # Compute the layout for the slider background
    slider_x = x
    slider_y = y + height / 2 - 10.0f0  # Center the slider vertically
    slider_width = width
    slider_height = 20.0f0              # Fixed height for the slider

    # Compute the layout for the handle
    handle_width = 10.0f0
    handle_height = slider_height
    handle_x = slider_x + (view.current_value - view.min_value) / (view.max_value - view.min_value) * slider_width - handle_width / 2
    handle_y = slider_y

    return (slider_x, slider_y, slider_width, slider_height, handle_x, handle_y, handle_width, handle_height)
end

function interpret_view(view::HorizontalSliderView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32})
    # Compute the layout for the slider
    (slider_x, slider_y, slider_width, slider_height, handle_x, handle_y, handle_width, handle_height) = apply_layout(view, x, y, width, height)

    # Draw the slider background
    slider_vertices = generate_rectangle_vertices(slider_x, slider_y, slider_width, slider_height)
    draw_rectangle(slider_vertices, view.style.background_color, projection_matrix)

    # Draw the slider handle
    handle_vertices = generate_rectangle_vertices(handle_x, handle_y, handle_width, handle_height)
    draw_rectangle(handle_vertices, view.style.handle_color, projection_matrix)

    # Draw the slider border
    if view.style.border_width_px > 0.0
        draw_closed_lines(slider_vertices, view.style.border_color)
        draw_closed_lines(handle_vertices, view.style.border_color)
    end
end

function detect_click(view::HorizontalSliderView, mouse_state::InputState, x::Float32, y::Float32, width::Float32, height::Float32)
    # Compute the layout for the slider
    (slider_x, slider_y, slider_width, slider_height, handle_x, handle_y, handle_width, handle_height) = apply_layout(view, x, y, width, height)

    # Check if the mouse is inside the slider area (background or handle)
    if mouse_state.x >= slider_x && mouse_state.x <= slider_x + slider_width &&
       mouse_state.y >= slider_y && mouse_state.y <= slider_y + slider_height &&
       mouse_state.button_state[LeftButton] == IsPressed
        # Update the slider value based on the mouse position
        relative_x = clamp(mouse_state.x - slider_x, 0.0f0, slider_width)
        view.current_value = view.min_value + relative_x / slider_width * (view.max_value - view.min_value)

        # Trigger the on_change callback
        view.on_change(view.current_value)
    end
end
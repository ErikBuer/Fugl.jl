include("slider_style.jl")

# TODO consider adding a state struct to manage focus. And on_blur callback

"""
- `current_value`: Current value of the slider
- `min_value`: Minimum value of the slider
- `max_value`: Maximum value of the slider
- `style`: Style for the slider
- `on_change`: Callback for value changes
"""
struct HorizontalSliderView{T<:Real} <: SizedView
    current_value::T
    min_value::T                # Minimum value of the slider
    max_value::T                # Maximum value of the slider
    style::SliderStyle          # Style for the slider
    on_change::Function         # Callback for value changes
end

function HorizontalSlider(
    current_value::T,
    min_value::T,
    max_value::T;
    style=SliderStyle(),
    on_change=(new_value::T) -> nothing
) where T<:Real
    return HorizontalSliderView(current_value, min_value, max_value, style, on_change)
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

function interpret_view(view::HorizontalSliderView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32}, mouse_x::Float32, mouse_y::Float32)
    # Compute the layout for the slider
    (slider_x, slider_y, slider_width, slider_height, handle_x, handle_y, handle_width, handle_height) = apply_layout(view, x, y, width, height)

    # Draw the slider background
    slider_vertices = generate_rectangle_vertices(slider_x, slider_y, slider_width, slider_height)
    draw_rounded_rectangle(
        slider_vertices,
        slider_width,
        slider_height,
        view.style.background_color,
        view.style.border_color,
        view.style.border_width,
        view.style.radius,
        projection_matrix,
        1.5f0 # or your anti_aliasing_width value
    )

    # Draw the slider handle
    handle_vertices = generate_rectangle_vertices(handle_x, handle_y, handle_width, handle_height)
    draw_rounded_rectangle(
        handle_vertices,
        handle_width,
        handle_height,
        view.style.handle_color,
        view.style.border_color,
        view.style.border_width,
        view.style.radius,
        projection_matrix,
        1.5f0 # or your anti_aliasing_width value
    )
end

function detect_click(view::HorizontalSliderView, mouse_state::InputState, x::Float32, y::Float32, width::Float32, height::Float32)

    if mouse_state.is_dragging[LeftButton] == false && mouse_state.button_state[LeftButton] == IsReleased
        return
    end


    # Compute the layout for the slider
    (slider_x, slider_y, slider_width, slider_height, handle_x, handle_y, handle_width, handle_height) = apply_layout(view, x, y, width, height)

    # Helper: check if a point is inside the slider area
    function inside_slider(px, py)
        return px >= slider_x && px <= slider_x + slider_width &&
               py >= slider_y && py <= slider_y + slider_height
    end

    # If dragging with left button and drag started inside slider, update value
    if mouse_state.is_dragging[LeftButton] &&
       mouse_state.drag_start_position[LeftButton] !== nothing &&
       inside_slider(mouse_state.drag_start_position[LeftButton]...)

        # Move slider according to current mouse position
        relative_x = clamp(mouse_state.x - slider_x, 0.0f0, slider_width)
        new_value = view.min_value + relative_x / slider_width * (view.max_value - view.min_value)
        view.on_change(new_value)
        return
    end

    # Handle click (not drag) inside slider
    if inside_slider(mouse_state.x, mouse_state.y) &&
       mouse_state.button_state[LeftButton] == IsPressed &&
       mouse_state.is_dragging[LeftButton] == false

        relative_x = clamp(mouse_state.x - slider_x, 0.0f0, slider_width)
        new_value = view.min_value + relative_x / slider_width * (view.max_value - view.min_value)
        view.on_change(new_value)
    end
end

function preferred_height(view::HorizontalSliderView)::Bool
    return true
end
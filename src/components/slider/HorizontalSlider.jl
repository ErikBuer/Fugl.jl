include("slider_style.jl")
include("slider_state.jl")

"""
HorizontalSlider with state management and discrete step support.

- `state`: SliderState containing current value, range, and interaction state
- `steps`: Optional step snapping (Int for number of steps, Real for step size, nothing for continuous)
- `style`: Style for the slider
- `on_state_change`: Callback for state changes (required for state updates)
- `on_change`: Callback for value changes only
"""
struct HorizontalSliderView{T<:Real} <: SizedView
    state::SliderState{T}
    steps::Union{Nothing,Int,T}     # Step snapping: nothing=continuous, Int=num_steps, Real=step_size
    style::SliderStyle              # Style for the slider
    on_state_change::Function       # Callback for state changes
    on_change::Function             # Callback for value changes only
end

function HorizontalSlider(
    state::SliderState{T};
    steps::Union{Nothing,Int,T}=nothing,
    style=SliderStyle(),
    on_state_change::Function=(new_state) -> nothing,
    on_change::Function=(new_value) -> nothing
) where T<:Real
    return HorizontalSliderView(state, steps, style, on_state_change, on_change)
end

function apply_layout(view::HorizontalSliderView, x::Float32, y::Float32, width::Float32, height::Float32)
    # Compute the layout for the slider background
    slider_x = x
    slider_y = y + height / 2 - 10.0f0  # Center the slider vertically
    slider_width = width
    slider_height = 20.0f0              # Fixed height for the slider

    # Compute the layout for the handle
    handle_width = 12.0f0  # Slightly wider handle for better visibility
    handle_height = slider_height + 4.0f0  # Slightly taller than track

    # Calculate handle position based on value
    value_ratio = Float32((view.state.value - view.state.min_value) / (view.state.max_value - view.state.min_value))
    handle_x = slider_x + value_ratio * (slider_width - handle_width)  # Account for handle width
    handle_y = slider_y - 2.0f0  # Center handle on track

    return (slider_x, slider_y, slider_width, slider_height, handle_x, handle_y, handle_width, handle_height)
end

function interpret_view(view::HorizontalSliderView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32}, mouse_x::Float32, mouse_y::Float32)
    # Compute the layout for the slider
    (slider_x, slider_y, slider_width, slider_height, handle_x, handle_y, handle_width, handle_height) = apply_layout(view, x, y, width, height)

    # Choose colors based on focus/drag state
    bg_color = view.state.is_focused ?
               Vec4{Float32}(0.85f0, 0.85f0, 0.9f0, 1.0f0) :
               view.style.background_color

    handle_color = if view.state.is_dragging
        Vec4{Float32}(0.5f0, 0.65f0, 0.85f0, 1.0f0)  # Blue when dragging
    elseif view.state.is_focused
        Vec4{Float32}(0.6f0, 0.75f0, 0.8f0, 1.0f0)   # Lighter when focused
    else
        view.style.handle_color
    end

    # Draw the slider background (track)
    slider_vertices = generate_rectangle_vertices(slider_x, slider_y, slider_width, slider_height)
    draw_rounded_rectangle(
        slider_vertices,
        slider_width,
        slider_height,
        bg_color,
        view.style.border_color,
        view.style.border_width,
        view.style.radius,
        projection_matrix,
        1.5f0
    )

    # Draw filled portion of track (from min to current value)
    if view.state.value > view.state.min_value
        fill_width = Float32((view.state.value - view.state.min_value) / (view.state.max_value - view.state.min_value) * slider_width)
        fill_vertices = generate_rectangle_vertices(slider_x, slider_y, fill_width, slider_height)
        fill_color = Vec4{Float32}(0.4f0, 0.6f0, 0.8f0, 0.6f0)  # Semi-transparent blue
        draw_rounded_rectangle(
            fill_vertices,
            fill_width,
            slider_height,
            fill_color,
            Vec4{Float32}(0.0f0, 0.0f0, 0.0f0, 0.0f0),  # No border
            0.0f0,
            view.style.radius,
            projection_matrix,
            1.5f0
        )
    end

    # Draw step markers if steps are defined
    if view.steps !== nothing
        draw_step_markers(view, slider_x, slider_y, slider_width, slider_height, projection_matrix)
    end

    # Draw the slider handle
    handle_vertices = generate_rectangle_vertices(handle_x, handle_y, handle_width, handle_height)
    draw_rounded_rectangle(
        handle_vertices,
        handle_width,
        handle_height,
        handle_color,
        view.style.border_color,
        view.style.border_width * 1.5f0,  # Slightly thicker border for handle
        view.style.radius + 1.0f0,
        projection_matrix,
        1.5f0
    )
end

function draw_step_markers(view::HorizontalSliderView, slider_x::Float32, slider_y::Float32, slider_width::Float32, slider_height::Float32, projection_matrix::Mat4{Float32})
    if view.steps === nothing
        return
    end

    num_markers = if view.steps isa Int
        view.steps
    else
        # Calculate number of markers for fixed step size
        Int(round((view.state.max_value - view.state.min_value) / view.steps)) + 1
    end

    if num_markers <= 1
        return
    end

    marker_color = Vec4{Float32}(0.6f0, 0.6f0, 0.6f0, 0.8f0)
    marker_width = 2.0f0
    marker_height = slider_height * 1.5f0

    for i in 0:(num_markers-1)
        marker_ratio = Float32(i / (num_markers - 1))
        marker_x = slider_x + marker_ratio * slider_width - marker_width / 2
        marker_y = slider_y - (marker_height - slider_height) / 2

        marker_vertices = generate_rectangle_vertices(marker_x, marker_y, marker_width, marker_height)
        draw_rounded_rectangle(
            marker_vertices,
            marker_width,
            marker_height,
            marker_color,
            Vec4{Float32}(0.0f0, 0.0f0, 0.0f0, 0.0f0),
            0.0f0,
            0.5f0,
            projection_matrix,
            1.0f0
        )
    end
end

function detect_click(view::HorizontalSliderView, mouse_state::InputState, x::Float32, y::Float32, width::Float32, height::Float32)
    # Compute the layout for the slider
    (slider_x, slider_y, slider_width, slider_height, handle_x, handle_y, handle_width, handle_height) = apply_layout(view, x, y, width, height)

    # Helper: check if a point is inside the slider area
    function inside_slider(px, py)
        return px >= slider_x && px <= slider_x + slider_width &&
               py >= slider_y - 5.0f0 && py <= slider_y + slider_height + 5.0f0  # Slightly larger hit area
    end

    # Update hover state for the hover registry
    comp_id = component_id(slider_x, slider_y, slider_width, slider_height)
    mouse_inside = inside_slider(mouse_state.x, mouse_state.y)
    update_hover_state!(comp_id, mouse_inside)

    # Use hover registry for focus state (simpler than manual tracking)
    is_currently_hovered = is_hovered(slider_x, slider_y, slider_width, slider_height)

    # Handle drag end
    if view.state.is_dragging && mouse_state.button_state[LeftButton] == IsReleased
        new_state = SliderState(view.state; is_dragging=false, is_focused=is_currently_hovered)
        view.on_state_change(new_state)
        return
    end

    # If dragging with left button and drag started inside slider, update value
    if mouse_state.is_dragging[LeftButton] &&
       mouse_state.drag_start_position[LeftButton] !== nothing &&
       inside_slider(mouse_state.drag_start_position[LeftButton]...)

        # Move slider according to current mouse position
        relative_x = clamp(mouse_state.x - slider_x, 0.0f0, slider_width)
        raw_value = view.state.min_value + Float64(relative_x) / Float64(slider_width) * (view.state.max_value - view.state.min_value)

        # Apply step snapping (convert raw_value to match state value type)
        snapped_value = if typeof(view.state.min_value) <: Integer
            apply_step_snapping(Int(round(raw_value)), view.state.min_value, view.state.max_value, view.steps)
        else
            apply_step_snapping(raw_value, view.state.min_value, view.state.max_value, view.steps)
        end

        if snapped_value != view.state.value
            new_state = SliderState(view.state; value=snapped_value, is_dragging=true, is_focused=true)
            view.on_state_change(new_state)
            view.on_change(snapped_value)
        elseif !view.state.is_dragging
            # Start dragging
            new_state = SliderState(view.state; is_dragging=true, is_focused=true)
            view.on_state_change(new_state)
        end
        return
    end

    # Handle click (not drag) inside slider
    if inside_slider(mouse_state.x, mouse_state.y) &&
       mouse_state.was_clicked[LeftButton]

        relative_x = clamp(mouse_state.x - slider_x, 0.0f0, slider_width)
        raw_value = view.state.min_value + Float64(relative_x) / Float64(slider_width) * (view.state.max_value - view.state.min_value)

        # Apply step snapping (convert raw_value to match state value type)
        snapped_value = if typeof(view.state.min_value) <: Integer
            apply_step_snapping(Int(round(raw_value)), view.state.min_value, view.state.max_value, view.steps)
        else
            apply_step_snapping(raw_value, view.state.min_value, view.state.max_value, view.steps)
        end

        new_state = SliderState(view.state; value=snapped_value, is_focused=true)
        view.on_state_change(new_state)
        view.on_change(snapped_value)
        return
    end

    # Update focus state based on hover registry (simplified)
    if view.state.is_focused != is_currently_hovered && !view.state.is_dragging
        new_state = SliderState(view.state; is_focused=is_currently_hovered)
        view.on_state_change(new_state)
    end
end

function preferred_height(view::HorizontalSliderView)::Bool
    return true
end
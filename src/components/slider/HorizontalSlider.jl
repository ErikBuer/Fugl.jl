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
    style::SliderStyle              # Normal style for the slider
    focused_style::Union{Nothing,SliderStyle}  # Style when focused
    dragging_style::Union{Nothing,SliderStyle} # Style when dragging
    on_state_change::Function       # Callback for state changes
    on_change::Function             # Callback for value changes only
    on_interaction_state_change::Function  # Callback for interaction state changes
end

function HorizontalSlider(
    state::SliderState{T};
    steps::Union{Nothing,Int,T}=nothing,
    style=SliderStyle(),
    focused_style::Union{Nothing,SliderStyle}=nothing,
    dragging_style::Union{Nothing,SliderStyle}=nothing,
    on_state_change::Function=(new_state) -> nothing,
    on_change::Function=(new_value) -> nothing,
    on_interaction_state_change::Function=(new_interaction_state) -> nothing
) where T<:Real
    return HorizontalSliderView(state, steps, style, focused_style, dragging_style, on_state_change, on_change, on_interaction_state_change)
end

function apply_layout(view::HorizontalSliderView, x::Float32, y::Float32, width::Float32, height::Float32)
    # Get sizing from style
    slider_height = view.style.track_height
    handle_width = view.style.handle_width
    handle_height = slider_height + view.style.handle_height_offset

    # Compute the layout for the slider background
    slider_x = x
    slider_y = y + height / 2 - slider_height / 2  # Center the slider vertically
    slider_width = width

    # Calculate handle position based on value
    value_ratio = Float32((view.state.value - view.state.min_value) / (view.state.max_value - view.state.min_value))
    handle_x = slider_x + value_ratio * (slider_width - handle_width)  # Account for handle width
    handle_y = slider_y - view.style.handle_height_offset / 2  # Center handle on track

    return (slider_x, slider_y, slider_width, slider_height, handle_x, handle_y, handle_width, handle_height)
end

function interpret_view(view::HorizontalSliderView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32}, mouse_x::Float32, mouse_y::Float32)
    # Compute the layout for the slider
    (slider_x, slider_y, slider_width, slider_height, handle_x, handle_y, handle_width, handle_height) = apply_layout(view, x, y, width, height)

    # Determine focus state
    is_focused = view.state.interaction_state.is_focused

    # Choose style based on interaction state
    # Priority: dragging > focused > normal
    active_style = if view.state.is_dragging && view.dragging_style !== nothing
        view.dragging_style
    elseif is_focused && view.focused_style !== nothing
        view.focused_style
    else
        view.style
    end

    bg_color = active_style.background_color
    handle_color = active_style.handle_color

    # Draw the slider background (track)
    slider_vertices = generate_rectangle_vertices(slider_x, slider_y, slider_width, slider_height)
    draw_rounded_rectangle(
        slider_vertices,
        slider_width,
        slider_height,
        bg_color,
        active_style.border_color,
        active_style.border_width,
        active_style.radius,
        projection_matrix,
        1.5f0
    )

    # Draw filled portion of track (from min to current value)
    if view.state.value > view.state.min_value
        fill_width = Float32((view.state.value - view.state.min_value) / (view.state.max_value - view.state.min_value) * slider_width)
        fill_vertices = generate_rectangle_vertices(slider_x, slider_y, fill_width, slider_height)
        fill_color = active_style.fill_color
        draw_rounded_rectangle(
            fill_vertices,
            fill_width,
            slider_height,
            fill_color,
            Vec4{Float32}(0.0f0, 0.0f0, 0.0f0, 0.0f0),  # No border
            0.0f0,
            active_style.radius,
            projection_matrix,
            1.5f0
        )
    end

    # Draw step markers if steps are defined and markers are enabled (using line drawing for performance)
    if view.steps !== nothing && active_style.marker_color !== nothing
        draw_step_markers_as_lines(view, slider_x, slider_y, slider_width, slider_height, active_style, projection_matrix)
    end

    # Draw the slider handle
    handle_vertices = generate_rectangle_vertices(handle_x, handle_y, handle_width, handle_height)
    draw_rounded_rectangle(
        handle_vertices,
        handle_width,
        handle_height,
        handle_color,
        active_style.border_color,
        active_style.border_width * 1.5f0,  # Slightly thicker border for handle
        active_style.radius + 1.0f0,
        projection_matrix,
        1.5f0
    )
end

# Draw step markers as lines for better performance
function draw_step_markers_as_lines(view::HorizontalSliderView, slider_x::Float32, slider_y::Float32, slider_width::Float32, slider_height::Float32, active_style::SliderStyle, projection_matrix::Mat4{Float32})
    if view.steps === nothing || active_style.marker_color === nothing
        return
    end

    num_markers = if view.steps isa Int
        view.steps
    else
        # Calculate number of markers for fixed step size
        Int(round((view.state.max_value - view.state.min_value) / view.steps)) + 1
    end

    # Need at least 3 markers to have intermediate ones (remove first and last)
    if num_markers <= 2
        return
    end

    # Create batch of lines for step markers (excluding first and last)
    marker_lines = Vector{SimpleLine}()

    marker_color = active_style.marker_color
    marker_width = 2.0f0

    # Make markers fit inside the slider background height
    marker_height = slider_height * 0.8f0  # 80% of track height to stay inside

    # Calculate vertical position for markers (centered on track, inside background)
    marker_y_start = slider_y + (slider_height - marker_height) / 2
    marker_y_end = marker_y_start + marker_height

    handle_width = view.style.handle_width

    # Draw only intermediate markers (skip i=0 and i=num_markers-1)
    for i in 1:(num_markers-2)
        marker_ratio = Float32(i / (num_markers - 1))

        # Align with handle center: account for handle width in positioning
        # Handle center is at: slider_x + marker_ratio * (slider_width - handle_width) + handle_width/2
        marker_x = slider_x + marker_ratio * (slider_width - handle_width) + handle_width / 2

        # Create vertical line points
        start_point = Point2f(marker_x, marker_y_start)
        end_point = Point2f(marker_x, marker_y_end)

        # Add line to batch
        push!(marker_lines, SimpleLine([start_point, end_point], marker_color, marker_width, SOLID))
    end

    # Draw all marker lines in one batch
    draw_lines(marker_lines, projection_matrix)
end

function detect_click(view::HorizontalSliderView, mouse_state::InputState, x::Float32, y::Float32, width::Float32, height::Float32)
    # Compute the layout for the slider
    (slider_x, slider_y, slider_width, slider_height, handle_x, handle_y, handle_width, handle_height) = apply_layout(view, x, y, width, height)

    # Helper: check if a point is inside the slider area
    function inside_slider(px, py)
        return px >= slider_x && px <= slider_x + slider_width &&
               py >= slider_y - 5.0f0 && py <= slider_y + slider_height + 5.0f0  # Slightly larger hit area
    end

    # Update interaction state
    is_mouse_inside = inside_slider(mouse_state.x, mouse_state.y)
    is_mouse_pressed = is_mouse_inside && mouse_state.button_state[LeftButton] == IsPressed
    current_time = time()

    new_interaction_state = update_interaction_state(
        view.state.interaction_state,
        is_mouse_inside,
        is_mouse_pressed,
        current_time
    )

    # Update the slider state with new interaction state and use for focus
    is_currently_hovered = new_interaction_state.is_hovered

    # Notify of interaction state changes
    if new_interaction_state != view.state.interaction_state
        view.on_interaction_state_change(new_interaction_state)
        # Also update the slider state with new interaction state
        updated_slider_state = SliderState(view.state; interaction_state=new_interaction_state)
        view.on_state_change(updated_slider_state)
    end    # Handle drag end
    if view.state.is_dragging && mouse_state.button_state[LeftButton] == IsReleased
        new_state = SliderState(view.state; is_dragging=false)
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
            new_state = SliderState(view.state; value=snapped_value, is_dragging=true)
            view.on_state_change(new_state)
            view.on_change(snapped_value)
        elseif !view.state.is_dragging
            # Start dragging
            new_state = SliderState(view.state; is_dragging=true)
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

        new_state = SliderState(view.state; value=snapped_value)
        view.on_state_change(new_state)
        view.on_change(snapped_value)
        return
    end

end

function measure(view::HorizontalSliderView)
    # Calculate required height: handle height (track + offset) plus some margin
    required_height = view.style.track_height + view.style.handle_height_offset + 4.0f0  # 2px margin top/bottom
    # Width: use minimum width from style
    min_width = view.style.min_width

    return (min_width, required_height)
end

function measure_width(view::HorizontalSliderView, available_height::Float32)::Float32
    # For horizontal sliders, width is independent of available height
    # Return minimum width from style
    return view.style.min_width
end

function measure_height(view::HorizontalSliderView, available_width::Float32)::Float32
    # For horizontal sliders, height is independent of available width
    # Calculate required height: handle height (track + offset) plus some margin
    return view.style.track_height + view.style.handle_height_offset + 4.0f0  # 2px margin top/bottom
end

function preferred_height(view::HorizontalSliderView)::Bool
    return true
end

function preferred_width(view::HorizontalSliderView)::Bool
    return false  # Slider can expand to fill available width
end
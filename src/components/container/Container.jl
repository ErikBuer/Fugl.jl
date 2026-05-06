struct ContainerView <: AbstractView
    child::AbstractView  # Single child view
    style::ContainerStyle
    hover_style::Union{Nothing,ContainerStyle}
    pressed_style::Union{Nothing,ContainerStyle}
    disabled::Bool
    disabled_style::Union{Nothing,ContainerStyle}
    on_click::Function
    on_mouse_down::Function
    on_mouse_up::Function
    interaction_state::Union{Nothing,InteractionState}
    on_interaction_state_change::Function
end

"""
The `Container` is an interactive container component that extends BaseContainer with hover, pressed, and disabled states.
It provides rich interaction handling including callbacks and state management.
For simple non-interactive containers, use BaseContainer directly.
"""
function Container(child::AbstractView=EmptyView();
    style=ContainerStyle(),
    hover_style::Union{Nothing,ContainerStyle}=nothing,
    pressed_style::Union{Nothing,ContainerStyle}=nothing,
    disabled::Bool=false,
    disabled_style::Union{Nothing,ContainerStyle}=nothing,
    on_click::Function=() -> nothing,
    on_mouse_down::Function=() -> nothing,
    on_mouse_up::Function=() -> nothing,
    interaction_state::Union{Nothing,InteractionState}=nothing,
    on_interaction_state_change::Function=(new_state) -> nothing
)
    return ContainerView(child, style, hover_style, pressed_style, disabled, disabled_style, on_click, on_mouse_down, on_mouse_up, interaction_state, on_interaction_state_change)
end

"""
Create BaseContainer with current active style for delegation.
"""
function _create_base_container(view::ContainerView)::BaseContainerView
    # Choose style based on state - start with default, then apply interaction styles, then disabled override
    active_style = view.style

    # Apply interaction styles if not disabled
    if view.interaction_state !== nothing
        if view.interaction_state.is_pressed && view.pressed_style !== nothing
            active_style = view.pressed_style
        elseif view.interaction_state.is_hovered && view.hover_style !== nothing
            active_style = view.hover_style
        end
    end

    # Disabled style always takes priority
    if view.disabled && view.disabled_style !== nothing
        active_style = view.disabled_style
    end

    return BaseContainer(view.child, style=active_style)
end

# Delegate measurement functions to BaseContainer
function measure(view::ContainerView)::Tuple{Float32,Float32}
    base_container = _create_base_container(view)
    return measure(base_container)
end

function measure_width(view::ContainerView, available_height::Float32)::Float32
    base_container = _create_base_container(view)
    return measure_width(base_container, available_height)
end

function measure_height(view::ContainerView, available_width::Float32)::Float32
    base_container = _create_base_container(view)
    return measure_height(base_container, available_width)
end

"""
Render the container using BaseContainer with selected style.
"""
function interpret_view(container::ContainerView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32}, cursor_position::Point2f)
    # Create BaseContainer with appropriate style and delegate rendering
    base_container = _create_base_container(container)
    interpret_view(base_container, x, y, width, height, projection_matrix, cursor_position)
end

function blur(view::ContainerView)
    if view.interaction_state !== nothing && view.interaction_state.is_focused
        new_interaction_state = blur(view.interaction_state)
        view.on_interaction_state_change(new_interaction_state)
    end
end

"""
Detect clicks with full interaction state management.
"""
function detect_click(view::ContainerView, mouse_state::InputState, x::Float32, y::Float32, width::Float32, height::Float32, parent_z::Int32)::Union{ClickResult,Nothing}
    # Skip all interactions if disabled or no interaction state tracking - delegate to BaseContainer
    if view.disabled || view.interaction_state === nothing
        base_container = _create_base_container(view)
        return detect_click(base_container, mouse_state, x, y, width, height, parent_z)
    end

    # Get layout using BaseContainer's apply_layout  
    base_container = _create_base_container(view)
    (child_x, child_y, child_width, child_height) = apply_layout(base_container, x, y, width, height)

    z::Int32 = parent_z + 1

    # Recursively check the child
    child_click_result = detect_click(view.child, mouse_state, child_x, child_y, child_width, child_height, z)

    # Event captured by child
    if child_click_result !== nothing
        return child_click_result
    end

    is_mouse_inside = inside_component(view, x, y, width, height, mouse_state.x, mouse_state.y)
    is_mouse_pressed::Bool = view.interaction_state.is_pressed

    # Update interaction state
    if mouse_state.mouse_down[LeftButton] && is_mouse_inside
        is_mouse_pressed = true
    elseif mouse_state.mouse_up[LeftButton]
        is_mouse_pressed = false
    end

    current_time = time()
    old_interaction_state = view.interaction_state
    new_interaction_state = update_interaction_state(
        view.interaction_state;
        is_mouse_inside=is_mouse_inside,
        is_mouse_pressed=is_mouse_pressed,
        current_time=current_time
    )

    # Handle mouse outside - update state but don't capture
    if !is_mouse_inside
        if new_interaction_state != view.interaction_state
            view.on_interaction_state_change(new_interaction_state)
        end
        return nothing
    end

    # Launch callbacks for interactions inside component
    container_callbacks() = begin
        # Notify of interaction state changes
        if new_interaction_state != view.interaction_state
            view.on_interaction_state_change(new_interaction_state)
        end

        # Mouse down - triggers only when button is first pressed while over component
        if mouse_state.mouse_down[LeftButton]
            view.on_mouse_down()
        end

        # Mouse up - triggers when button is released while over component
        if mouse_state.mouse_up[LeftButton]
            view.on_mouse_up()
        end

        # Click - triggers only if press started inside AND release happened inside
        if old_interaction_state.is_pressed && mouse_state.mouse_up[LeftButton]
            view.on_click()
        end
    end

    return ClickResult(z, container_callbacks)
end

# Delegate preferred size functions to BaseContainer
function preferred_width(view::ContainerView)::Bool
    base_container = _create_base_container(view)
    return preferred_width(base_container)
end

function preferred_height(view::ContainerView)::Bool
    base_container = _create_base_container(view)
    return preferred_height(base_container)
end
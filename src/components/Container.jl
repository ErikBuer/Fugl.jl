struct ContainerStyle
    background_color::Vec4{<:AbstractFloat} #RGBA color
    border_color::Vec4{<:AbstractFloat} #RGBA color
    border_width::Float32
    padding::Float32
    corner_radius::Float32
    anti_aliasing_width::Float32
end

function ContainerStyle(;
    background_color=Vec4{Float32}(0.88f0, 0.875f0, 0.88f0, 1.0f0),
    border_color=Vec4{Float32}(0.5f0, 0.5f0, 0.5f0, 1.0f0),
    border_width=1.0f0,
    padding::Float32=6f0,
    corner_radius::Float32=5.0f0,
    anti_aliasing_width::Float32=1.0f0
)
    return ContainerStyle(background_color, border_color, border_width, padding, corner_radius, anti_aliasing_width)
end

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
The `Container` is the most basic GUI component that can contain another component.
It is the most basic building block of the GUI system.
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

function measure(view::ContainerView)::Tuple{Float32,Float32}
    # Measure the size of the child component
    child_width, child_height = measure(view.child)

    # Add padding
    padding = view.style.padding
    return (child_width + 2 * padding, child_height + 2 * padding)
end

function measure_width(view::ContainerView, available_height::Float32)::Float32
    # Measure the width of the child component
    child_width = measure_width(view.child, available_height)

    # Add padding
    padding = view.style.padding
    return child_width + 2 * padding
end

function measure_height(view::ContainerView, available_width::Float32)::Float32
    # Measure the height of the child component
    child_height = measure_height(view.child, available_width)

    # Add padding
    padding = view.style.padding
    return child_height + 2 * padding
end

"""
Calculate layout to the container and its child.
"""
function apply_layout(view::ContainerView, x::Float32, y::Float32, width::Float32, height::Float32)
    # Extract padding from the container's layout
    padding = view.style.padding
    padded_x = x + padding
    padded_y = y + padding
    padded_width = width - 2 * padding
    padded_height = height - 2 * padding

    # Compute the child's position and size based on alignment
    child_width = padded_width
    child_height = padded_height

    child_x = padded_x
    child_y = padded_y

    return (child_x, child_y, child_width, child_height)
end

"""
Render the container and its child.
"""
function interpret_view(container::ContainerView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32}, mouse_x::Float32, mouse_y::Float32)
    # Compute the layout for the container
    (child_x, child_y, child_width, child_height) = apply_layout(container, x, y, width, height)

    # Choose style based on state - start with default, then apply interaction styles, then disabled override
    active_style = container.style

    # Apply interaction styles if not disabled
    if container.interaction_state !== nothing
        if container.interaction_state.is_pressed && container.pressed_style !== nothing
            active_style = container.pressed_style
        elseif container.interaction_state.is_hovered && container.hover_style !== nothing
            active_style = container.hover_style
        end
    end

    # Disabled style always takes priority
    if container.disabled && container.disabled_style !== nothing
        active_style = container.disabled_style
    end

    vertex_positions = generate_rectangle_vertices(x, y, width, height)
    draw_rounded_rectangle(vertex_positions, width, height,
        active_style.background_color,
        active_style.border_color,
        active_style.border_width,
        active_style.corner_radius,
        projection_matrix,
        active_style.anti_aliasing_width
    )

    # Render the child - disabled only affects container interaction, not child appearance
    interpret_view(container.child, child_x, child_y, child_width, child_height, projection_matrix, mouse_x, mouse_y)
end

"""
Detect clicks on the container and its child.
"""
function detect_click(view::ContainerView, mouse_state::InputState, x::AbstractFloat, y::AbstractFloat, width::AbstractFloat, height::AbstractFloat)
    (child_x, child_y, child_width, child_height) = apply_layout(view, x, y, width, height)

    # Skip all interactions if disabled or no interaction state tracking
    if view.disabled || view.interaction_state === nothing
        # Still forward to child for non-interactive components
        detect_click(view.child, mouse_state, child_x, child_y, child_width, child_height)
        return
    end


    is_mouse_inside = inside_component(view, x, y, width, height, mouse_state.x, mouse_state.y)

    is_mouse_pressed::Bool = view.interaction_state.is_pressed

    if mouse_state.mouse_down[LeftButton] && is_mouse_inside
        is_mouse_pressed = true
    elseif mouse_state.mouse_up[LeftButton]
        is_mouse_pressed = false
    end

    # For now, use a simple time
    current_time = time()

    old_interaction_state = view.interaction_state
    new_interaction_state = update_interaction_state(
        view.interaction_state;
        is_mouse_inside=is_mouse_inside,
        is_mouse_pressed=is_mouse_pressed,
        current_time=current_time
    )

    # Notify of interaction state changes
    if new_interaction_state != view.interaction_state
        view.on_interaction_state_change(new_interaction_state)
    end


    # Launch callbacks
    if is_mouse_inside
        # Mouse down - triggers only when button is first pressed while over component
        if mouse_state.mouse_down[LeftButton]
            view.on_mouse_down()  # Trigger `on_mouse_down`
        end

        # Mouse up - triggers when button is released while over component (regardless of where press started)
        if mouse_state.mouse_up[LeftButton]
            view.on_mouse_up()  # Trigger `on_mouse_up`
        end

        # Click - triggers only if press started inside AND release happened inside
        if old_interaction_state.is_pressed && mouse_state.mouse_up[LeftButton]
            view.on_click()  # Trigger `on_click`
        end

    end


    # Recursively check the child.
    # Some components have focus behavior, and therefore must register clicks even if outside their bounds.
    detect_click(view.child, mouse_state, child_x, child_y, child_width, child_height)
end
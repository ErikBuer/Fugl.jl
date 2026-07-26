include("popover_style.jl")
include("popover_state.jl")
include("draw.jl")

"""
    PopoverView <: AbstractView

Wraps `wrapped_component` and shows an arbitrary `popover_content` view in a floating
panel while the pointer hovers over the trigger (or the panel itself). Positioning and
show/hide timing follow the same conventions as `Tooltip`; unlike `Tooltip` the panel can
hold any interactive `AbstractView` (buttons, a form, ...), similar to how `Modal` hosts
arbitrary content, but without the click-to-open/darkened background/dragging behavior.
"""
struct PopoverView <: AbstractView
    wrapped_component::AbstractView  # The component being wrapped/monitored for hover
    popover_content::AbstractView    # Arbitrary content to display in the popover panel
    popover_width::Float32           # Width of the popover panel
    popover_height::Float32          # Height of the popover panel
    position::Symbol                 # Where to position the panel: :right, :left, :top, :bottom
    style::PopoverStyle              # Popover panel appearance
    show_delay::Float64              # Delay before showing the popover (seconds)
    hide_delay::Float64              # Delay before hiding the popover (seconds)
    state::PopoverState              # Current popover state (hover timing, visibility)
    on_state_change::StateCallback{PopoverState}        # Callback for state changes
end

function Popover(
    wrapped_component::AbstractView,
    popover_content::AbstractView;
    popover_width::Real=200.0f0,
    popover_height::Real=100.0f0,
    position::Symbol=:right,
    style::PopoverStyle=PopoverStyle(),
    show_delay::Float64=0.3,
    hide_delay::Float64=0.2,
    state::PopoverState=PopoverState(),
    on_state_change=(new_state) -> nothing
)::PopoverView
    return PopoverView(wrapped_component, popover_content, Float32(popover_width), Float32(popover_height), position, style, show_delay, hide_delay, state, wrap_callback(StateCallback{PopoverState}, on_state_change))
end

"""
Measure function - popover takes the size of the wrapped component.
"""
function measure(view::PopoverView)::Tuple{Float32,Float32}
    return measure(view.wrapped_component)
end

function measure_width(view::PopoverView, available_height::Float32)::Float32
    return measure_width(view.wrapped_component, available_height)
end

function measure_height(view::PopoverView, available_width::Float32)::Float32
    return measure_height(view.wrapped_component, available_width)
end

function preferred_width(view::PopoverView)::Bool
    return preferred_width(view.wrapped_component)
end

function preferred_height(view::PopoverView)::Bool
    return preferred_height(view.wrapped_component)
end

"""
Calculate where to position the popover panel relative to the wrapped component.
Positions the panel on the specified side of the component, then shifts it inward on
either axis to keep it fully within the window.
"""
function calculate_popover_position(view::PopoverView, x::Float32, y::Float32, width::Float32, height::Float32, window_size::Size)::Tuple{Float32,Float32}
    popover_width = view.popover_width
    popover_height = view.popover_height
    gap = 8.0f0

    if view.position == :right
        popover_x = x + width + gap
        popover_y = y
    elseif view.position == :left
        popover_x = x - popover_width - gap
        popover_y = y
    elseif view.position == :top
        popover_x = x
        popover_y = y - popover_height - gap
    elseif view.position == :bottom
        popover_x = x
        popover_y = y + height + gap
    else
        popover_x = x + width + gap
        popover_y = y
    end

    # Shift inward on each axis independently so the panel stays within the window
    popover_x = clamp(popover_x, 0.0f0, max(0.0f0, window_size.width - popover_width))
    popover_y = clamp(popover_y, 0.0f0, max(0.0f0, window_size.height - popover_height))

    return (popover_x, popover_y)
end

"""
Render the wrapped component and, while hovering, the popover panel with its content.
"""
function interpret_view(view::PopoverView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32}, cursor_position::Point2f, window_size::Size)
    interpret_view(view.wrapped_component, x, y, width, height, projection_matrix, cursor_position, window_size)

    # Handle timing-based state updates every frame
    current_time = time()
    state_changed = false
    new_state = view.state

    if !view.state.is_visible &&
       view.state.hover_start_time > 0.0 &&
       current_time - view.state.hover_start_time >= view.show_delay
        new_state = PopoverState(new_state; is_visible=true)
        state_changed = true
    end

    if view.state.is_visible &&
       view.state.last_hide_time > 0.0 &&
       current_time - view.state.last_hide_time >= view.hide_delay
        new_state = PopoverState(new_state; is_visible=false, hover_start_time=0.0, last_hide_time=0.0)
        state_changed = true
    end

    if state_changed
        view.on_state_change(new_state)
    end

    current_popover_state = state_changed ? new_state : view.state

    if current_popover_state.is_visible
        popover_x, popover_y = calculate_popover_position(view, x, y, width, height, window_size)
        popover_width = view.popover_width
        popover_height = view.popover_height
        style = view.style
        content = view.popover_content

        add_overlay_function() do
            draw_popover_background(style, popover_x, popover_y, popover_width, popover_height, projection_matrix)

            content_x = popover_x + style.padding
            content_y = popover_y + style.padding
            content_width = popover_width - 2 * style.padding
            content_height = popover_height - 2 * style.padding
            interpret_view(content, content_x, content_y, content_width, content_height, projection_matrix, cursor_position, window_size)
        end
    end
end

"""
Handle interactions with the wrapped component, hover detection for the panel, and (while
visible) forward clicks to the panel content.
"""
function detect_click(view::PopoverView, input_state::InputState, x::Float32, y::Float32, width::Float32, height::Float32, parent_z::Int32)::Union{ClickResult,Nothing}
    mouse_x, mouse_y = input_state.x, input_state.y
    window_size = Size(get_effective_window_size()...)

    trigger_hovered = inside_component(view, x, y, width, height, mouse_x, mouse_y)

    popover_x, popover_y = calculate_popover_position(view, x, y, width, height, window_size)
    popover_width = view.popover_width
    popover_height = view.popover_height

    # The panel renders unclipped (via the overlay system), so its hover/hit-test must be
    # unclipped too, regardless of any ScrollArea/clip the trigger sits inside.
    panel_hovered = view.state.is_visible &&
                    mouse_x >= popover_x && mouse_x <= popover_x + popover_width &&
                    mouse_y >= popover_y && mouse_y <= popover_y + popover_height

    is_hovering = trigger_hovered || panel_hovered

    state_changed = false
    new_state = view.state
    current_time = time()

    if is_hovering && !view.state.is_hovering
        new_state = PopoverState(new_state;
            is_hovering=true,
            hover_start_time=current_time,
            last_hide_time=0.0
        )
        state_changed = true
    elseif !is_hovering && view.state.is_hovering
        new_state = PopoverState(new_state;
            is_hovering=false,
            hover_start_time=0.0,
            last_hide_time=current_time
        )
        state_changed = true
    end

    if state_changed
        view.on_state_change(new_state)
    end

    z = Int32(parent_z + 1000)

    content_action = if view.state.is_visible
        style = view.style
        content_x = popover_x + style.padding
        content_y = popover_y + style.padding
        content_width = popover_width - 2 * style.padding
        content_height = popover_height - 2 * style.padding

        with_unclipped_input() do
            detect_click(view.popover_content, input_state, content_x, content_y, content_width, content_height, z)
        end
    else
        nothing
    end

    trigger_action = detect_click(view.wrapped_component, input_state, x, y, width, height, parent_z)

    if content_action !== nothing && trigger_action !== nothing
        return content_action.z_height >= trigger_action.z_height ? content_action : trigger_action
    elseif content_action !== nothing
        return content_action
    else
        return trigger_action
    end
end

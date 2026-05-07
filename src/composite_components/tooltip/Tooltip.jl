include("tooltip_style.jl")
include("tooltip_state.jl")
include("draw.jl")

struct TooltipView <: AbstractView
    wrapped_component::AbstractView  # The component being wrapped/monitored for hover
    tooltip_text::String             # Text to display in tooltip
    position::Symbol                 # Where to position tooltip: :right, :left, :top, :bottom
    style::TooltipStyle              # Tooltip appearance
    show_delay::Float64              # Delay before showing tooltip (seconds)
    hide_delay::Float64              # Delay before hiding tooltip (seconds)
    state::TooltipState              # Current tooltip state (hover timing, visibility)
    on_state_change::Function        # Callback for state changes
end

function Tooltip(
    tooltip_text::String,
    wrapped_component::AbstractView;
    position::Symbol=:right,
    style=TooltipStyle(),
    show_delay::Float64=0.5,         # 500 ms delay before showing
    hide_delay::Float64=0.1,         # 100 ms delay before hiding
    state::TooltipState=TooltipState(),
    on_state_change::Function=(new_state) -> nothing
)::TooltipView
    return TooltipView(wrapped_component, tooltip_text, position, style, show_delay, hide_delay, state, on_state_change)
end

"""
Measure function - tooltip takes the size of the wrapped component.
"""
function measure(view::TooltipView)::Tuple{Float32,Float32}
    return measure(view.wrapped_component)
end

"""
Measure width - tooltip takes the width of the wrapped component.
"""
function measure_width(view::TooltipView, available_height::Float32)::Float32
    return measure_width(view.wrapped_component, available_height)
end

"""
Measure height - tooltip takes the height of the wrapped component.
"""
function measure_height(view::TooltipView, available_width::Float32)::Float32
    return measure_height(view.wrapped_component, available_width)
end

"""
Render the wrapped component and handle tooltip overlay.
"""
function interpret_view(view::TooltipView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32}, cursor_position::Point2f)
    # First, render the wrapped component
    interpret_view(view.wrapped_component, x, y, width, height, projection_matrix, cursor_position)

    # Handle timing-based state updates every frame
    current_time = time()
    state_changed = false
    new_state = view.state

    # If we should show the tooltip (hover time exceeded)
    if !view.state.is_visible &&
       view.state.hover_start_time > 0.0 &&
       current_time - view.state.hover_start_time >= view.show_delay
        new_state = TooltipState(new_state; is_visible=true)
        state_changed = true
    end

    # If we should hide the tooltip (hide time exceeded)  
    if view.state.is_visible &&
       view.state.last_hide_time > 0.0 &&
       current_time - view.state.last_hide_time >= view.hide_delay
        new_state = TooltipState(new_state; is_visible=false, hover_start_time=0.0, last_hide_time=0.0)
        state_changed = true
    end

    # Update state if changed
    if state_changed
        view.on_state_change(new_state)
    end

    # Use current state (might have been updated above)
    current_tooltip_state = state_changed ? new_state : view.state

    # If tooltip is visible, add it to the overlay system
    if current_tooltip_state.is_visible && !isempty(view.tooltip_text)
        # Calculate tooltip position relative to wrapped component
        tooltip_x, tooltip_y = calculate_tooltip_position(view, x, y, width, height)

        # Add overlay function to render tooltip on top of everything
        add_overlay_function(() -> draw_tooltip(view.tooltip_text, view.style, tooltip_x, tooltip_y, projection_matrix, cursor_position))
    end
end

"""
Handle interactions with the wrapped component and detect hover for tooltip.
"""
function detect_click(view::TooltipView, input_state::InputState, x::Float32, y::Float32, width::Float32, height::Float32, parent_z::Int32)::Union{ClickResult,Nothing}
    # Check if mouse is over the wrapped component
    mouse_x, mouse_y = input_state.x, input_state.y
    is_hovering = inside_component(view, x, y, width, height, mouse_x, mouse_y)

    # Handle hover state changes
    current_time = time()
    state_changed = false
    new_state = view.state

    if is_hovering && !view.state.is_hovering
        # Started hovering
        new_state = TooltipState(new_state;
            is_hovering=true,
            hover_start_time=current_time,
            last_hide_time=0.0
        )
        state_changed = true
    elseif !is_hovering && view.state.is_hovering
        # Stopped hovering
        new_state = TooltipState(new_state;
            is_hovering=false,
            hover_start_time=0.0,
            last_hide_time=current_time
        )
        state_changed = true
    end

    # Update state if hover changed
    if state_changed
        view.on_state_change(new_state)
    end

    # Forward click detection to wrapped component
    return detect_click(view.wrapped_component, input_state, x, y, width, height, parent_z)
end

"""
Calculate where to position the tooltip relative to the wrapped component.
Positions tooltip on the specified side of the component.
"""
function calculate_tooltip_position(view::TooltipView, x::Float32, y::Float32, width::Float32, height::Float32)::Tuple{Float32,Float32}
    # Calculate tooltip dimensions
    tooltip_height = calculate_tooltip_text_height(view.tooltip_text, view.style, view.style.width)
    tooltip_width = view.style.width
    gap = 8.0f0  # Gap between component and tooltip

    tooltip_x = x
    tooltip_y = y

    if view.position == :right
        # Position to the right of the wrapped component
        tooltip_x = x + width + gap
        tooltip_y = y
    elseif view.position == :left
        # Position to the left of the wrapped component
        tooltip_x = x - tooltip_width - gap
        tooltip_y = y
    elseif view.position == :top
        # Position above the wrapped component
        tooltip_x = x
        tooltip_y = y - tooltip_height - gap
    elseif view.position == :bottom
        # Position below the wrapped component
        tooltip_x = x
        tooltip_y = y + height + gap
    else
        # Default to right if unknown position
        tooltip_x = x + width + gap
        tooltip_y = y
    end

    # TODO: Add smarter positioning logic to avoid screen edges
    # For now, just use the calculated position

    return (tooltip_x, tooltip_y)
end

"""
Preferred width - tooltip propagates the wrapped component's preferred width.
"""
function preferred_width(view::TooltipView)::Bool
    return preferred_width(view.wrapped_component)
end

"""
Preferred height - tooltip propagates the wrapped component's preferred height.
"""
function preferred_height(view::TooltipView)::Bool
    return preferred_height(view.wrapped_component)
end
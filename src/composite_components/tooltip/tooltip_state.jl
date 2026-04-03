struct TooltipState
    is_visible::Bool
    is_hovering::Bool           # Whether mouse is currently over the wrapped component
    # Show delay - tooltip appears after hovering for a certain time
    show_delay::Float64
    # Hide delay - tooltip stays visible briefly after mouse leaves
    hide_delay::Float64
    hover_start_time::Float64
    last_hide_time::Float64
end

function TooltipState(;
    is_visible::Bool=false,
    is_hovering::Bool=false,
    show_delay::Float64=0.5,  # 500ms delay before showing
    hide_delay::Float64=0.1,  # 100ms delay before hiding
    hover_start_time::Float64=0.0,
    last_hide_time::Float64=0.0
)
    return TooltipState(is_visible, is_hovering, show_delay, hide_delay, hover_start_time, last_hide_time)
end

"""
Create a new TooltipState from an existing state with keyword-based modifications.
"""
function TooltipState(state::TooltipState;
    is_visible=state.is_visible,
    is_hovering=state.is_hovering,
    show_delay=state.show_delay,
    hide_delay=state.hide_delay,
    hover_start_time=state.hover_start_time,
    last_hide_time=state.last_hide_time
)
    return TooltipState(is_visible, is_hovering, show_delay, hide_delay, hover_start_time, last_hide_time)
end
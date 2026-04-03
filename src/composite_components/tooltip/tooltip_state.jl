struct TooltipState
    is_visible::Bool
    is_hovering::Bool           # Whether mouse is currently over the wrapped component
    hover_start_time::Float64   # When hovering started (for show delay timing)
    last_hide_time::Float64     # When hiding started (for hide delay timing)
end

function TooltipState(;
    is_visible::Bool=false,
    is_hovering::Bool=false,
    hover_start_time::Float64=0.0,
    last_hide_time::Float64=0.0
)
    return TooltipState(is_visible, is_hovering, hover_start_time, last_hide_time)
end

"""
Create a new TooltipState from an existing state with keyword-based modifications.
"""
function TooltipState(state::TooltipState;
    is_visible=state.is_visible,
    is_hovering=state.is_hovering,
    hover_start_time=state.hover_start_time,
    last_hide_time=state.last_hide_time
)
    return TooltipState(is_visible, is_hovering, hover_start_time, last_hide_time)
end
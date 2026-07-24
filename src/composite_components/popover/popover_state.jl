struct PopoverState
    is_visible::Bool
    is_hovering::Bool           # Whether the mouse is over the wrapped component or the popover panel
    hover_start_time::Float64   # When hovering started (for show delay timing)
    last_hide_time::Float64     # When hovering stopped (for hide delay timing)
end

function PopoverState(;
    is_visible::Bool=false,
    is_hovering::Bool=false,
    hover_start_time::Float64=0.0,
    last_hide_time::Float64=0.0
)
    return PopoverState(is_visible, is_hovering, hover_start_time, last_hide_time)
end

"""
Create a new PopoverState from an existing state with keyword-based modifications.
"""
function PopoverState(state::PopoverState;
    is_visible=state.is_visible,
    is_hovering=state.is_hovering,
    hover_start_time=state.hover_start_time,
    last_hide_time=state.last_hide_time
)
    return PopoverState(is_visible, is_hovering, hover_start_time, last_hide_time)
end

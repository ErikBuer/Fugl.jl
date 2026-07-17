struct ContextMenuState
    is_open::Bool
    anchor_x::Float32
    anchor_y::Float32
    trigger_pressed::Bool  # right mouse button went down on the child and hasn't been released yet
    menu::FloatingMenuState
end

function ContextMenuState(;
    is_open::Bool=false,
    anchor_x::Float32=0.0f0,
    anchor_y::Float32=0.0f0,
    trigger_pressed::Bool=false,
    menu::FloatingMenuState=FloatingMenuState()
)
    return ContextMenuState(is_open, anchor_x, anchor_y, trigger_pressed, menu)
end

function ContextMenuState(state::ContextMenuState;
    is_open=state.is_open,
    anchor_x=state.anchor_x,
    anchor_y=state.anchor_y,
    trigger_pressed=state.trigger_pressed,
    menu=state.menu
)
    return ContextMenuState(is_open, anchor_x, anchor_y, trigger_pressed, menu)
end

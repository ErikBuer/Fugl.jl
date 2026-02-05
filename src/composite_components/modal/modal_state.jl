struct ModalState
    offset_x::Float32           # X offset from parent's top-left corner
    offset_y::Float32           # Y offset from parent's top-left corner
    drag_offset_x::Float32      # X offset from modal top-left to drag start mouse position
    drag_offset_y::Float32      # Y offset from modal top-left to drag start mouse position
end

function ModalState(;
    offset_x::Real=20.0f0,
    offset_y::Real=20.0f0,
    drag_offset_x::Real=0.0f0,
    drag_offset_y::Real=0.0f0
)
    return ModalState(
        Float32(offset_x),
        Float32(offset_y),
        Float32(drag_offset_x),
        Float32(drag_offset_y)
    )
end

# Constructor to copy state with changes
function ModalState(state::ModalState;
    offset_x=state.offset_x,
    offset_y=state.offset_y,
    drag_offset_x=state.drag_offset_x,
    drag_offset_y=state.drag_offset_y
)
    return ModalState(
        Float32(offset_x),
        Float32(offset_y),
        Float32(drag_offset_x),
        Float32(drag_offset_y)
    )
end

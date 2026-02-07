struct ModalState
    offset_x::Union{Nothing,Float32}  # X offset from parent's top-left corner (nothing = center)
    offset_y::Union{Nothing,Float32}  # Y offset from parent's top-left corner (nothing = center)
    drag_offset_x::Float32            # X offset from modal top-left to drag start mouse position
    drag_offset_y::Float32            # Y offset from modal top-left to drag start mouse position
    is_dragging_modal::Bool           # Whether the modal is currently being dragged
end

function ModalState(;
    offset_x::Union{Nothing,Real}=nothing,
    offset_y::Union{Nothing,Real}=nothing,
    drag_offset_x::Real=0.0f0,
    drag_offset_y::Real=0.0f0,
    is_dragging_modal::Bool=false
)
    return ModalState(
        isnothing(offset_x) ? nothing : Float32(offset_x),
        isnothing(offset_y) ? nothing : Float32(offset_y),
        Float32(drag_offset_x),
        Float32(drag_offset_y),
        is_dragging_modal
    )
end

# Constructor to copy state with changes
function ModalState(state::ModalState;
    offset_x=state.offset_x,
    offset_y=state.offset_y,
    drag_offset_x=state.drag_offset_x,
    drag_offset_y=state.drag_offset_y,
    is_dragging_modal=state.is_dragging_modal
)
    return ModalState(
        isnothing(offset_x) ? nothing : Float32(offset_x),
        isnothing(offset_y) ? nothing : Float32(offset_y),
        Float32(drag_offset_x),
        Float32(drag_offset_y),
        is_dragging_modal
    )
end

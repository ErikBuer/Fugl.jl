struct FloatingMenuState
    scroll_offset::Int   # index (0-based) of the first visible row
    hover_index::Int     # 1-based index into the options list, 0 = none hovered
    pressed_index::Int   # 1-based index of the item the mouse went down on, 0 = none
end

function FloatingMenuState(;
    scroll_offset::Int=0,
    hover_index::Int=0,
    pressed_index::Int=0
)
    return FloatingMenuState(scroll_offset, hover_index, pressed_index)
end

function FloatingMenuState(state::FloatingMenuState;
    scroll_offset=state.scroll_offset,
    hover_index=state.hover_index,
    pressed_index=state.pressed_index
)
    return FloatingMenuState(scroll_offset, hover_index, pressed_index)
end

include("floating_menu_style.jl")
include("floating_menu_state.jl")
include("draw.jl")

"""
Z-height added on top of `parent_z` when computing a `ClickResult` for a floating menu,
so it wins hit-testing against the rest of the normal view tree beneath it.
"""
const FLOATING_MENU_Z_BUMP = Int32(1000)

"""
Number of rows drawn at once (capped by `style.max_visible_items`).
"""
function floating_menu_row_capacity(n_options::Int, style::FloatingMenuStyle)::Int
    return min(n_options, style.max_visible_items)
end

"""
Height in points of the floating menu panel.
"""
function floating_menu_height(n_options::Int, style::FloatingMenuStyle)::Float32
    return floating_menu_row_capacity(n_options, style) * style.item_height_px
end

"""
Largest valid `scroll_offset` for `n_options` given the style's visible row count.
"""
function floating_menu_max_scroll(n_options::Int, style::FloatingMenuStyle)::Int
    return max(0, n_options - style.max_visible_items)
end

"""
    floating_menu_geometry(anchor_x, anchor_y, width, n_options, style, window_size)

Resolve the anchor position into the actual on-screen `(x, y, height)` of the floating
menu panel, shifted inward on each axis independently so it stays fully inside the
window — same clamp `Tooltip` uses (`calculate_tooltip_position`,
`src/composite_components/tooltip/Tooltip.jl`). Call this identically from both
`interpret_view` (to draw) and `detect_click` (to hit-test) so the two can never
disagree.

`window_size` must be the same "effective" window size passed to `interpret_view` —
from `detect_click`, which isn't given `window_size` directly, use
`get_effective_window_size()` (`src/dpi_scaling.jl`).
"""
function floating_menu_geometry(anchor_x::Float32, anchor_y::Float32, width::Float32, n_options::Int, style::FloatingMenuStyle, window_size::Size)::Tuple{Float32,Float32,Float32}
    height = floating_menu_height(n_options, style)
    x = clamp(anchor_x, 0.0f0, max(0.0f0, window_size.width - width))
    y = clamp(anchor_y, 0.0f0, max(0.0f0, window_size.height - height))
    return (x, y, height)
end

"""
    floating_menu_visible_range(state, n_options, style)

1-based range of option indices currently drawn, accounting for `state.scroll_offset`.
"""
function floating_menu_visible_range(state::FloatingMenuState, n_options::Int, style::FloatingMenuStyle)::UnitRange{Int}
    visible = min(n_options - state.scroll_offset, style.max_visible_items)
    visible <= 0 && return 1:0
    return (state.scroll_offset+1):(state.scroll_offset+visible)
end

"""
    step_floating_menu_scroll(state, scroll_y, n_options, style)

Discrete ("hard") scroll: each wheel tick moves `scroll_offset` by exactly one row,
clamped to `[0, floating_menu_max_scroll(n_options, style)]`. Returns `state` unchanged
if there is no scroll input or the offset didn't move.
"""
function step_floating_menu_scroll(state::FloatingMenuState, scroll_y::Float32, n_options::Int, style::FloatingMenuStyle)::FloatingMenuState
    scroll_y == 0.0f0 && return state
    max_scroll = floating_menu_max_scroll(n_options, style)
    new_offset = scroll_y > 0.0f0 ? max(0, state.scroll_offset - 1) : min(max_scroll, state.scroll_offset + 1)
    new_offset == state.scroll_offset && return state
    return FloatingMenuState(state; scroll_offset=new_offset)
end

"""
    floating_menu_contains(x, y, width, n_options, style, mouse_x, mouse_y)

Whether `(mouse_x, mouse_y)` falls inside the panel rectangle. `(x, y)` and the panel
height are expected to come from `floating_menu_geometry`.
"""
function floating_menu_contains(x::Float32, y::Float32, width::Float32, n_options::Int, style::FloatingMenuStyle, mouse_x::Float32, mouse_y::Float32)::Bool
    height = floating_menu_height(n_options, style)
    return mouse_x >= x && mouse_x <= x + width && mouse_y >= y && mouse_y <= y + height
end

"""
    floating_menu_item_at(x, y, width, n_options, state, style, mouse_x, mouse_y)

1-based index into the options list under `(mouse_x, mouse_y)`, or `nothing` if the
point is outside the panel or over empty space below the last row. `(x, y)` and the
panel height are expected to come from `floating_menu_geometry`.
"""
function floating_menu_item_at(x::Float32, y::Float32, width::Float32, n_options::Int, state::FloatingMenuState, style::FloatingMenuStyle, mouse_x::Float32, mouse_y::Float32)::Union{Int,Nothing}
    floating_menu_contains(x, y, width, n_options, style, mouse_x, mouse_y) || return nothing
    row = Int(floor((mouse_y - y) / style.item_height_px)) + 1
    idx = row + state.scroll_offset
    (idx < 1 || idx > n_options) && return nothing
    return idx
end

"""
    floating_menu_press_item(x, y, width, n_options, state, style, mouse_x, mouse_y)

Call when the left mouse button goes down this frame. Records which item (if any) is
under the cursor as "pressed" so a later release over that *same* item resolves as a
click — the same press-then-release-on-target convention `Container`/buttons use for
`on_click` (`src/components/container/Container.jl`), applied per-row here so dragging
off an item before releasing does not select it.
"""
function floating_menu_press_item(x::Float32, y::Float32, width::Float32, n_options::Int, state::FloatingMenuState, style::FloatingMenuStyle, mouse_x::Float32, mouse_y::Float32)::FloatingMenuState
    pressed = floating_menu_item_at(x, y, width, n_options, state, style, mouse_x, mouse_y)
    return FloatingMenuState(state; pressed_index=pressed === nothing ? 0 : pressed)
end

"""
    floating_menu_release_item(x, y, width, n_options, state, style, mouse_x, mouse_y)

Call when the left mouse button goes up this frame. Returns `(new_state, selected_index)`
where `selected_index` is the clicked item if the release landed on the same item that
was pressed (via `floating_menu_press_item`), else `nothing`. Always clears
`pressed_index` in `new_state`.
"""
function floating_menu_release_item(x::Float32, y::Float32, width::Float32, n_options::Int, state::FloatingMenuState, style::FloatingMenuStyle, mouse_x::Float32, mouse_y::Float32)::Tuple{FloatingMenuState,Union{Int,Nothing}}
    released = floating_menu_item_at(x, y, width, n_options, state, style, mouse_x, mouse_y)
    selected = (released !== nothing && released == state.pressed_index) ? released : nothing
    return (FloatingMenuState(state; pressed_index=0), selected)
end

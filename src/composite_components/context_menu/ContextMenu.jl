include("context_menu_state.jl")

struct ContextMenuView <: AbstractView
    child::AbstractView
    options::Vector{String}
    style::FloatingMenuStyle
    width::Float32
    state::ContextMenuState
    on_state_change::Function
    on_select::Function
end

"""
    ContextMenu(child, options; style=FloatingMenuStyle(), width=200.0f0, state=ContextMenuState(),
                on_state_change=(new_state) -> nothing, on_select=(index) -> nothing)

Wrap `child` with right-click context-menu support. Right-clicking `child` opens a
floating text menu at the cursor, built on the `FloatingMenu` primitive
(`src/components/floating_menu/floating_menu.jl`) — the same building blocks any other
component (a `Plot`, a custom canvas, etc.) can use to add its own popup menu. `width`
is the popup's fixed width (independent of `child`'s width).

Behavior:
- Opening the menu and selecting an item both use a press-then-release-on-target
  convention, the same one `Container`/buttons use for `on_click`: a right-mouse-down
  that drags off `child` before releasing does not open the menu, and a left-mouse-down
  that drags off a menu row before releasing does not select it.
- Discrete ("hard") wheel-scroll, one row per tick, when there are more options than
  `style.max_visible_items`.
- Clicking outside the open panel closes it immediately.

# Examples
```jldoctest
julia> using Fugl

julia> state = ContextMenuState();

julia> view = ContextMenu(Fugl.Text("Right-click me"), ["Cut", "Copy", "Paste"]; state=state);

julia> view isa Fugl.AbstractView
true
```
"""
function ContextMenu(
    child::AbstractView,
    options::Vector{String};
    style::FloatingMenuStyle=FloatingMenuStyle(),
    width::Float32=200.0f0,
    state::ContextMenuState=ContextMenuState(),
    on_state_change::Function=(new_state) -> nothing,
    on_select::Function=(index) -> nothing
)::ContextMenuView
    return ContextMenuView(child, options, style, width, state, on_state_change, on_select)
end

measure(view::ContextMenuView)::Tuple{Float32,Float32} = measure(view.child)
measure_width(view::ContextMenuView, available_height::Float32)::Float32 = measure_width(view.child, available_height)
measure_height(view::ContextMenuView, available_width::Float32)::Float32 = measure_height(view.child, available_width)
preferred_width(view::ContextMenuView)::Bool = preferred_width(view.child)
preferred_height(view::ContextMenuView)::Bool = preferred_height(view.child)

function interpret_view(view::ContextMenuView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32}, cursor_position::Point2f, window_size::Size)
    interpret_view(view.child, x, y, width, height, projection_matrix, cursor_position, window_size)

    if view.state.is_open
        n_options = length(view.options)
        (mx, my, _) = floating_menu_geometry(view.state.anchor_x, view.state.anchor_y, n_options, view.style)
        menu_width = view.width
        add_overlay_function(() -> draw_floating_menu(view.options, view.state.menu, view.style, mx, my, menu_width, projection_matrix, window_size))
    end
end

function detect_click(view::ContextMenuView, input_state::InputState, x::Float32, y::Float32, width::Float32, height::Float32, parent_z::Int32)::Union{ClickResult,Nothing}
    mouse_x, mouse_y = input_state.x, input_state.y
    n_options = length(view.options)
    menu_style = view.style
    menu_width = view.width
    child_hovered = inside_component(view, x, y, width, height, mouse_x, mouse_y)

    if view.state.is_open
        z = parent_z + FLOATING_MENU_Z_BUMP
        (mx, my, _) = floating_menu_geometry(view.state.anchor_x, view.state.anchor_y, n_options, menu_style)
        hovering_menu = floating_menu_contains(mx, my, menu_width, n_options, menu_style, mouse_x, mouse_y)

        # Hard (discrete) scroll while hovering the open menu.
        if input_state.scroll_y != 0.0f0 && hovering_menu
            new_menu = step_floating_menu_scroll(view.state.menu, input_state.scroll_y, n_options, menu_style)
            if new_menu !== view.state.menu
                new_state = ContextMenuState(view.state; menu=new_menu)
                return ClickResult(z, () -> view.on_state_change(new_state))
            end
        end

        # Press: record which item (if any) is under the cursor. Selection is only
        # resolved on release over the *same* item (see below).
        if input_state.mouse_down[LeftButton]
            if hovering_menu
                new_menu = floating_menu_press_item(mx, my, menu_width, n_options, view.state.menu, menu_style, mouse_x, mouse_y)
                if new_menu !== view.state.menu
                    new_state = ContextMenuState(view.state; menu=new_menu)
                    return ClickResult(z, () -> view.on_state_change(new_state))
                end
            else
                # Click landed outside the menu panel — close it immediately. Kept at
                # the base parent_z (not bumped) so it doesn't swallow a click meant
                # for something else underneath.
                new_state = ContextMenuState(view.state; is_open=false, menu=FloatingMenuState())
                view.on_state_change(new_state)
            end
        end

        # Release: resolve a click only if it lands on the same item that was pressed.
        if input_state.mouse_up[LeftButton]
            (new_menu, idx) = floating_menu_release_item(mx, my, menu_width, n_options, view.state.menu, menu_style, mouse_x, mouse_y)
            if idx !== nothing
                new_state = ContextMenuState(view.state; is_open=false, menu=FloatingMenuState())
                return ClickResult(z, () -> begin
                    view.on_state_change(new_state)
                    view.on_select(idx)
                end)
            elseif new_menu !== view.state.menu
                new_state = ContextMenuState(view.state; menu=new_menu)
                return ClickResult(z, () -> view.on_state_change(new_state))
            end
        end

        # Hover highlighting.
        hover_idx = floating_menu_item_at(mx, my, menu_width, n_options, view.state.menu, menu_style, mouse_x, mouse_y)
        hover_idx = hover_idx === nothing ? 0 : hover_idx
        if hover_idx != view.state.menu.hover_index
            new_menu = FloatingMenuState(view.state.menu; hover_index=hover_idx)
            new_state = ContextMenuState(view.state; menu=new_menu)
            return ClickResult(z, () -> view.on_state_change(new_state))
        end
    end

    # Right-click trigger: press-then-release-on-target, same convention as above.
    if input_state.mouse_down[RightButton] && child_hovered
        new_state = ContextMenuState(view.state; trigger_pressed=true)
        return ClickResult(parent_z, () -> view.on_state_change(new_state))
    end

    if input_state.mouse_up[RightButton] && view.state.trigger_pressed
        new_state = if child_hovered
            ContextMenuState(view.state; trigger_pressed=false, is_open=true, anchor_x=mouse_x, anchor_y=mouse_y, menu=FloatingMenuState())
        else
            ContextMenuState(view.state; trigger_pressed=false)
        end
        return ClickResult(parent_z, () -> view.on_state_change(new_state))
    end

    return detect_click(view.child, input_state, x, y, width, height, parent_z)
end

using Fugl
using Fugl: Text

# Demonstrates the shipped ContextMenu component (src/composite_components/context_menu/),
# which wraps any child with right-click context-menu support, built on the FloatingMenu
# primitive (src/components/floating_menu/). This is the pattern to follow when adding the
# same support to a component such as a Plot or a Canvas.

# --- Style examples ---------------------------------------------------------

# Default look: ContextMenuStyle()/FloatingMenuStyle() use their built-in defaults
# (white panel, transparent rows, light-gray hover, darker-gray pressed).
default_style = ContextMenuStyle()

# A custom dark theme, showing the knobs FloatingMenuStyle exposes:
# - text_style, panel background_color/border_color/border_width/corner_radius
# - item_style / hover_style / pressed_style — each a plain ContainerStyle, same as
#   Container's own style/hover_style/pressed_style (pressed takes priority over hover)
# - item_height_px, max_visible_items
# ContextMenuStyle.width controls the popup's fixed width (independent of the child).
dark_menu_style = FloatingMenuStyle(
    text_style=TextStyle(color=Vec4f(0.9, 0.9, 0.95, 1.0), size_points=14),
    background_color=Vec4f(0.14, 0.14, 0.17, 1.0),
    border_color=Vec4f(0.35, 0.35, 0.4, 1.0),
    border_width=1.5f0,
    corner_radius=10.0f0,
    item_style=ContainerStyle(
        background_color=Vec4f(0.0, 0.0, 0.0, 0.0),
        border_color=Vec4f(0.0, 0.0, 0.0, 0.0),
        border_width=0.0f0,
        padding=10.0f0,
        corner_radius=6.0f0
    ),
    hover_style=ContainerStyle(
        background_color=Vec4f(0.25, 0.45, 0.75, 1.0),
        border_color=Vec4f(0.0, 0.0, 0.0, 0.0),
        border_width=0.0f0,
        padding=10.0f0,
        corner_radius=6.0f0
    ),
    pressed_style=ContainerStyle(
        background_color=Vec4f(0.15, 0.3, 0.55, 1.0),
        border_color=Vec4f(0.0, 0.0, 0.0, 0.0),
        border_width=0.0f0,
        padding=10.0f0,
        corner_radius=6.0f0
    ),
    item_height_px=34.0f0,
    max_visible_items=5
)
dark_style = ContextMenuStyle(menu_style=dark_menu_style, width=220.0f0)

# -----------------------------------------------------------------------------

function test_floating_menu()
    default_state = Ref(ContextMenuState())
    dark_state = Ref(ContextMenuState())
    options = ["Reset zoom", "Export PNG", "Copy data", "Toggle grid", "Add annotation", "Duplicate", "Delete", "Rename", "Properties…"]
    last_selection = Ref("none")

    function MyApp()
        IntrinsicColumn([
                IntrinsicHeight(Container(Text("Right-click either box below (hard scroll, 9 options over the visible rows)"))),
                ContextMenu(
                    Container(Text("Right-click me — default style")),
                    options;
                    state=default_state[],
                    on_state_change=(new_state) -> default_state[] = new_state,
                    on_select=(idx) -> last_selection[] = options[idx]
                ),
                ContextMenu(
                    Container(Text("Right-click me — custom dark style")),
                    options;
                    style=dark_style,
                    state=dark_state[],
                    on_state_change=(new_state) -> dark_state[] = new_state,
                    on_select=(idx) -> last_selection[] = options[idx]
                ),
                IntrinsicHeight(Container(Text("Last selection: $(last_selection[])"))),
            ], spacing=8.0)
    end

    Fugl.run(MyApp, title="Floating Menu Demo", window_width_points=500, window_height_points=500, fps_overlay=true)
end

test_floating_menu()

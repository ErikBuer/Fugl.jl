using Fugl
using Fugl: Text

# Demonstrates the shipped ContextMenu component (src/composite_components/context_menu/),
# which wraps any child with right-click context-menu support, built on the FloatingMenu
# primitive (src/components/floating_menu/). This is the pattern to follow when adding the
# same support to a component such as a Plot or a Canvas.

function test_floating_menu()
    context_menu_state = Ref(ContextMenuState())
    options = ["Reset zoom", "Export PNG", "Copy data", "Toggle grid", "Add annotation", "Duplicate", "Delete", "Rename", "Properties…"]
    last_selection = Ref("none")

    function MyApp()
        IntrinsicColumn([
                IntrinsicHeight(Container(Text("Right-click the box below to open a context menu (hard scroll, 9 options over 6 visible rows)"))),
                ContextMenu(
                    Container(Text("Right-click me")),
                    options;
                    state=context_menu_state[],
                    on_state_change=(new_state) -> context_menu_state[] = new_state,
                    on_select=(idx) -> last_selection[] = options[idx]
                ),
                IntrinsicHeight(Container(Text("Last selection: $(last_selection[])"))),
            ], spacing=8.0)
    end

    Fugl.run(MyApp, title="Floating Menu Demo", window_width_points=500, window_height_points=400, fps_overlay=true)
end

test_floating_menu()

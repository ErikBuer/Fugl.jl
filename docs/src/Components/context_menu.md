# ContextMenu

The `ContextMenu` component wraps any child component with right-click context-menu support.

```@example ContextMenu
using Fugl

options = ["Reset zoom", "Export PNG", "Copy data", "Toggle grid", "Delete"]

# Force the menu open for demonstration purposes (normally `is_open` flips on right-click).
context_menu_state = Ref(ContextMenuState(is_open=true, anchor_x=20.0f0, anchor_y=60.0f0))

function MyApp()
    return Card(
        "ContextMenu example:",
        ContextMenu(
            Container(Fugl.Text("Right-click me")),
            options;
            state=context_menu_state[],
            on_state_change=(new_state) -> context_menu_state[] = new_state,
            on_select=(idx) -> println("Selected: $(options[idx])")
        )
    )
end

screenshot(MyApp, "context_menu.png", 400, 260);
nothing #hide
```

![ContextMenu](context_menu.png)

## Dark Theme Example

`FloatingMenuStyle` styles menu rows with plain `ContainerStyle`s — `item_style`, `hover_style`, and `pressed_style` — the same pattern `Container` itself uses (pressed takes priority over hover). The panel's own background/border/corner radius are separate top-level fields on `FloatingMenuStyle`. `ContextMenu`'s own `width` argument sets the popup's fixed width (independent of the child) — it isn't part of the style.

```@example ContextMenu
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

# Dark theme card style, matching the other component doc pages.
dark_card_style = ContainerStyle(
    background_color=Vec4f(0.15, 0.15, 0.18, 1.0),
    border_color=Vec4f(0.25, 0.25, 0.30, 1.0),
    border_width=1.5f0,
    padding=12.0f0,
    corner_radius=6.0f0,
    anti_aliasing_width=1.0f0
)
dark_title_style = TextStyle(size_points=18, color=Vec4f(0.9, 0.9, 0.95, 1.0))

dark_context_menu_state = Ref(ContextMenuState(is_open=true, anchor_x=20.0f0, anchor_y=60.0f0))

function MyDarkApp()
    return Card(
        "Dark Theme ContextMenu:",
        ContextMenu(
            Container(
                Fugl.Text("Right-click me", style=TextStyle(color=Vec4f(0.9, 0.9, 0.95, 1.0))),
                style=ContainerStyle(background_color=Vec4f(0.25, 0.3, 0.4, 1.0), padding=15.0f0, corner_radius=6.0f0)
            ),
            options;
            style=dark_menu_style,
            width=220.0f0,
            state=dark_context_menu_state[],
            on_state_change=(new_state) -> dark_context_menu_state[] = new_state,
            on_select=(idx) -> println("Dark selected: $(options[idx])")
        ),
        style=dark_card_style,
        title_style=dark_title_style
    )
end

screenshot(MyDarkApp, "dark_context_menu.png", 400, 300);
nothing #hide
```

![Dark ContextMenu](dark_context_menu.png)

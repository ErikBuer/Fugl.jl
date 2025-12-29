# KeyListener

KeyListener wraps another component and triggers a callback when a specific key combination is pressed.
This allows adding keyboard shortcuts to any component.

## Basic Key Example

``` @example KeyListenerBasic
using Fugl

message = Ref("Press 'A' to trigger the callback")

function MyApp()
    Container(
        KeyListener(
            Container(
                Fugl.Text(message[], style=TextStyle(size_px=16)),
                style=ContainerStyle(
                    padding=20.0f0,
                    background_color=Vec4f(0.9, 0.9, 0.95, 1.0),
                    corner_radius=8.0f0
                )
            ),
            Fugl.GLFW.KEY_A,
            () -> message[] = "You pressed 'A'!"
        )
    )
end

screenshot(MyApp, "keylistener_basic.png", 400, 200);
nothing #hide
```

![KeyListener Basic](keylistener_basic.png)

## Single Modifier Example

``` @example KeyListenerModifier
using Fugl

message = Ref("Press 'Ctrl+S' to save")

function MyApp()
    Container(
        KeyListener(
            Container(
                Fugl.Text(message[], style=TextStyle(size_px=16)),
                style=ContainerStyle(
                    padding=20.0f0,
                    background_color=Vec4f(0.85, 0.95, 0.85, 1.0),
                    corner_radius=8.0f0
                )
            ),
            Fugl.GLFW.KEY_S,
            Fugl.GLFW.MOD_CONTROL,
            () -> message[] = "File saved!"
        )
    )
end

screenshot(MyApp, "keylistener_modifier.png", 400, 200);
nothing #hide
```

![KeyListener Modifier](keylistener_modifier.png)

## Multiple Modifiers Example

``` @example KeyListenerMultiple
using Fugl

message = Ref("Press 'Ctrl+Shift+N' for new window")

function MyApp()
    Container(
        KeyListener(
            Container(
                Fugl.Text(message[], style=TextStyle(size_px=16)),
                style=ContainerStyle(
                    padding=20.0f0,
                    background_color=Vec4f(0.95, 0.85, 0.85, 1.0),
                    corner_radius=8.0f0
                )
            ),
            Fugl.GLFW.KEY_N,
            Fugl.GLFW.MOD_CONTROL | Fugl.GLFW.MOD_SHIFT,  # Combine modifiers with bitwise OR
            () -> message[] = "New window opened!"
        )
    )
end

screenshot(MyApp, "keylistener_multiple.png", 400, 200);
nothing #hide
```

![KeyListener Multiple](keylistener_multiple.png)

## Complete Example with Multiple Shortcuts

``` @example KeyListenerComplete
using Fugl

message = Ref("Try: 'A' (simple), 'Ctrl+S' (save), 'Ctrl+Shift+O' (open)")
status = Ref("")

function MyApp()
    Container(
        KeyListener(
            KeyListener(
                KeyListener(
                    Container(
                        IntrinsicColumn([
                            Fugl.Text(message[], style=TextStyle(size_px=14)),
                            Fugl.Text(status[], style=TextStyle(size_px=12, color=Vec4f(0.6, 0.6, 0.6, 1.0)))
                        ], spacing=8.0f0),
                        style=ContainerStyle(
                            padding=20.0f0,
                            background_color=Vec4f(0.95, 0.95, 0.98, 1.0),
                            border_color=Vec4f(0.8, 0.8, 0.85, 1.0),
                            border_width=1.0f0,
                            corner_radius=8.0f0
                        )
                    ),
                    Fugl.GLFW.KEY_A,
                    () -> status[] = "Simple 'A' key pressed"
                ),
                Fugl.GLFW.KEY_S,
                Fugl.GLFW.MOD_CONTROL,
                () -> status[] = "Ctrl+S: Save action triggered"
            ),
            Fugl.GLFW.KEY_O,
            Fugl.GLFW.MOD_CONTROL | Fugl.GLFW.MOD_SHIFT,
            () -> status[] = "Ctrl+Shift+O: Open action triggered"
        )
    )
end

screenshot(MyApp, "keylistener_complete.png", 600, 250);
nothing #hide
```

![KeyListener Complete](keylistener_complete.png)

## Common Key Combinations

Here are some commonly used GLFW key constants and modifier combinations:

### Keys
- `GLFW.KEY_A` through `GLFW.KEY_Z` - Letter keys
- `GLFW.KEY_ENTER` - Enter key
- `GLFW.KEY_ESCAPE` - Escape key
- `GLFW.KEY_SPACE` - Spacebar
- `GLFW.KEY_F1` through `GLFW.KEY_F12` - Function keys

### Modifiers
- `GLFW.MOD_CONTROL` - Ctrl key
- `GLFW.MOD_SHIFT` - Shift key
- `GLFW.MOD_ALT` - Alt key
- `GLFW.MOD_SUPER` - Super/Cmd/Windows key

### Combining Modifiers
Use the bitwise OR operator (`|`) to combine multiple modifiers:
- `GLFW.MOD_CONTROL | GLFW.MOD_SHIFT` - Ctrl+Shift
- `GLFW.MOD_CONTROL | GLFW.MOD_ALT` - Ctrl+Alt
- `GLFW.MOD_CONTROL | GLFW.MOD_SHIFT | GLFW.MOD_ALT` - Ctrl+Shift+Alt
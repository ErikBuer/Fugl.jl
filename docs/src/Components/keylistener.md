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

## Multiple Key Bindings Example

You can also define multiple key bindings in a single KeyListener using a vector of tuples:

``` @example KeyListenerMultiple
using Fugl

status = Ref("Ready - try various key combinations")

function MyApp()
    # Define key bindings with explicit type annotation
    key_bindings = Tuple{Fugl.GLFW.Key, Union{Nothing, Int32}, Function}[
        (Fugl.GLFW.KEY_A, nothing, () -> status[] = "A key pressed"),
        (Fugl.GLFW.KEY_S, Fugl.GLFW.MOD_CONTROL, () -> status[] = "Ctrl+S: Save action"),
        (Fugl.GLFW.KEY_O, Fugl.GLFW.MOD_CONTROL, () -> status[] = "Ctrl+O: Open action"),
        (Fugl.GLFW.KEY_N, Fugl.GLFW.MOD_CONTROL | Fugl.GLFW.MOD_SHIFT, () -> status[] = "Ctrl+Shift+N: New window"),
        (Fugl.GLFW.KEY_ESCAPE, nothing, () -> status[] = "Escape pressed"),
    ]
    
    Container(
        KeyListener(
            Container(
                IntrinsicColumn([
                    Fugl.Text("Multi-Key Demo", style=TextStyle(size_px=16, color=Vec4f(0.2, 0.2, 0.2, 1.0))),
                    Fugl.Text("Try: A, Ctrl+S, Ctrl+O, Ctrl+Shift+N, Escape", style=TextStyle(size_px=12, color=Vec4f(0.5, 0.5, 0.5, 1.0))),
                    Fugl.Text(status[], style=TextStyle(size_px=14, color=Vec4f(0.1, 0.4, 0.1, 1.0)))
                ], spacing=8.0f0),
                style=ContainerStyle(
                    padding=20.0f0,
                    background_color=Vec4f(0.96, 0.97, 0.98, 1.0),
                    border_color=Vec4f(0.85, 0.85, 0.9, 1.0),
                    border_width=1.0f0,
                    corner_radius=8.0f0
                )
            ),
            key_bindings
        )
    )
end

screenshot(MyApp, "keylistener_multibind.png", 600, 200);
nothing #hide
```

![Multi-Key Bindings](keylistener_multibind.png)

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
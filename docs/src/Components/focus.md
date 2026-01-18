# Focus

Focus wraps another component to manage keyboard focus state.

Child may have focus dependent behaviour, such as `KeyListener`. It only triggers callbacks when in focus.

## Basic Focus Example

``` @example FocusBasic
using Fugl

message = Ref("Click the area to focus, then press 'A'")
is_focused = Ref(false)

function MyApp()
    # Create content with visual focus feedback
    content = Container(
        Fugl.Text(message[], style=TextStyle(size_px=16, color=Vec4f(0.9, 0.9, 0.95, 1.0))),
        style=ContainerStyle(
            background_color=is_focused[] ? Vec4f(0.08, 0.12, 0.16, 1.0) : Vec4f(0.15, 0.15, 0.18, 1.0),
            border_color=is_focused[] ? Vec4f(0.2, 0.4, 0.7, 1.0) : Vec4f(0.25, 0.25, 0.30, 1.0),
            border_width=is_focused[] ? 2.0f0 : 1.0f0,
            padding=20.0f0,
            corner_radius=8.0f0
        )
    )
    
    # Add keyboard listener
    key_listener = KeyListener(
        content,
        Fugl.GLFW.KEY_A,
        () -> message[] = "You pressed 'A'!"
    )
    
    # Wrap with Focus to enable focus management
    Focus(
        key_listener;
        is_focused=is_focused[],
        on_focus_change=(focused) -> begin
            is_focused[] = focused
            if focused
                message[] = "Focused! Press 'A' to test"
            else
                message[] = "Click the area to focus"
            end
        end
    )
end

screenshot(MyApp, "focus_basic.png", 400, 200);
nothing #hide
```

![Focus Basic](focus_basic.png)

## Focus with Multiple Keys Example

``` @example FocusMultiple
using Fugl

status = Ref("Click to focus, then try key combinations")
is_focused = Ref(false)

function MyApp()
    # Define multiple key bindings
    key_bindings = Tuple{Fugl.GLFW.Key,Union{Nothing,Int32},Function}[
        (Fugl.GLFW.KEY_A, nothing, () -> status[] = "A key pressed"),
        (Fugl.GLFW.KEY_S, Fugl.GLFW.MOD_CONTROL, () -> status[] = "Ctrl+S: Save"),
        (Fugl.GLFW.KEY_ESCAPE, nothing, () -> status[] = "Escape pressed")
    ]
    
    # Create content area
    content = Container(
        IntrinsicColumn([
            Fugl.Text("Focused Area", style=TextStyle(size_px=16, color=Vec4f(0.9, 0.9, 0.95, 1.0))),
            Fugl.Text("Try: A, Ctrl+S, Escape", style=TextStyle(size_px=12, color=Vec4f(0.7, 0.7, 0.75, 1.0))),
            Fugl.Text(status[], style=TextStyle(size_px=14, color=Vec4f(0.8, 0.8, 0.85, 1.0)))
        ], spacing=8.0f0),
        style=ContainerStyle(
            background_color=is_focused[] ? Vec4f(0.06, 0.10, 0.08, 1.0) : Vec4f(0.15, 0.15, 0.18, 1.0),
            border_color=is_focused[] ? Vec4f(0.15, 0.45, 0.20, 1.0) : Vec4f(0.25, 0.25, 0.30, 1.0),
            border_width=is_focused[] ? 2.0f0 : 1.0f0,
            padding=15.0f0,
            corner_radius=6.0f0
        )
    )
    
    # Add multi-key listener
    key_listener = KeyListener(content, key_bindings)
    
    # Wrap with Focus component
    Focus(
        key_listener;
        is_focused=is_focused[],
        on_focus_change=(focused) -> begin
            is_focused[] = focused
            if focused
                status[] = "Focused! Keys are active"
            else
                status[] = "Click to focus, then try key combinations"
            end
        end
    )
end

screenshot(MyApp, "focus_multiple.png", 500, 250);
nothing #hide
```

![Focus Multiple](focus_multiple.png)

## Focus with Separate on_focus and on_blur Callbacks

``` @example FocusCallbacks
using Fugl

message = Ref("Click the area to see focus/blur callbacks")
focus_count = Ref(0)
blur_count = Ref(0)
is_focused = Ref(false)

function MyApp()
    # Create content area
    content = Container(
        IntrinsicColumn([
            Fugl.Text(message[], style=TextStyle(size_px=14, color=Vec4f(0.9, 0.9, 0.95, 1.0))),
            Fugl.Text("Focused: $(focus_count[]) times", style=TextStyle(size_px=12, color=Vec4f(0.7, 0.7, 0.75, 1.0))),
            Fugl.Text("Blurred: $(blur_count[]) times", style=TextStyle(size_px=12, color=Vec4f(0.7, 0.7, 0.75, 1.0)))
        ], spacing=8.0f0),
        style=ContainerStyle(
            background_color=is_focused[] ? Vec4f(0.12, 0.08, 0.06, 1.0) : Vec4f(0.15, 0.15, 0.18, 1.0),
            border_color=is_focused[] ? Vec4f(0.6, 0.3, 0.2, 1.0) : Vec4f(0.25, 0.25, 0.30, 1.0),
            border_width=is_focused[] ? 2.0f0 : 1.0f0,
            padding=15.0f0,
            corner_radius=6.0f0
        )
    )
    
    # Add keyboard listener
    key_listener = KeyListener(
        content,
        Fugl.GLFW.KEY_SPACE,
        () -> message[] = "Spacebar pressed!"
    )
    
    # Wrap with Focus using separate callbacks
    Focus(
        key_listener;
        is_focused=is_focused[],
        on_focus_change=(focused) -> is_focused[] = focused,
        on_focus=() -> begin
            focus_count[] += 1
            message[] = "Focused! Press Space to test"
        end,
        on_blur=() -> begin
            blur_count[] += 1
            message[] = "Blurred! Click again to refocus"
        end
    )
end

screenshot(MyApp, "focus_callbacks.png", 500, 200);
nothing #hide
```

![Focus Callbacks](focus_callbacks.png)

## Focus Behavior

- **Gaining Focus**: Click inside the wrapped component
- **Losing Focus**: Click outside the wrapped component
- **Visual Feedback**: Use the `on_focus_change` callback to update visual styling
- **Keyboard Input**: Only works when the component has focus

### Available Callbacks

- `on_focus_change(focused::Bool)`: Called when focus state changes (focus gained or lost). Used to update state.
- `on_focus()`: Called specifically when focus is gained
- `on_blur()`: Called specifically when focus is lost

You can use either `on_focus_change` for general focus management, or `on_focus`/`on_blur` for more specific event handling.

The Focus component follows the single-purpose design principle - it only manages focus state and delegates all other functionality to its child component.
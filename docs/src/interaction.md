# User interaction

User interaction is handled for each component via a `detect_click` method. This method can handle both cursor and keyboard interaction.

## Mouse Interaction Rules

Mouse interactions aims to follow these rules to ensure consistent behavior:

- **Mouse down** - `on_mouse_down` Button pressed (fires when button is first pressed)
- **Mouse up** - `on_mouse_up` Button released over the component
- **Click event** - `on_click` Fires only if both down and up occurred on the same element

## Hooks

The components then handle these and have various hooks that chan be used, such as `on_click`.

``` @example InteractionExample
using Fugl

function MyApp()
    Container( on_click=() -> println("Clicked") )
end
nothing #hide
```

``` @example TextButtonExample
using Fugl

function MyApp()
    Container(
        TextButton("Some Text", on_click=() -> println("Clicked"))
    )
end
nothing #hide
```

`detect_click` is called on all components being rendered in a frame.

## KeyListener

To add key listeners without creating a custom component, use the `KeyListener` component.

``` @example KeyListenerBasic
using Fugl

message = Ref("Press 'A' to trigger the callback")

function MyApp()
    Container(
        KeyListener(
            Container(
                Fugl.Text(message[], style=TextStyle(size_points=16)),
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

screenshot(MyApp, "keylistener_basic_interaction.png", 400, 200);
nothing #hide
```

![KeyListener Basic](keylistener_basic_interaction.png)

## Defining callbacks

Components store their callbacks as fixed-signature `FunctionWrapper`s rather than
type-erased `Function` fields:

```julia
TextButton("Save", on_click=() -> save_file())
CheckBox(state[], on_change=(new_value) -> state[] = new_value)
```

This design means a callback is compiled when the view tree is *built* (every frame),
not when it is first *invoked* — so the first click on a button doesn't pause for
JIT compilation, and ahead-of-time compilation can see through callback fields.

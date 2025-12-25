# Container

The most basic UI component.

``` @example ContainerExample
using Fugl

function MyApp()
    Container()
end

screenshot(MyApp, "container.png", 400, 300);
nothing #hide
```

![Container](container.png)

You can add a child component to a cointainer, as such:

``` @example ContainerExample2
using Fugl

function MyApp()
    Container(
        Container()
    )
end

screenshot(MyApp, "container_child.png", 400, 300);
nothing #hide
```

![Container](container_child.png)

## Style

``` @example ContainerStyle
using Fugl

my_style = ContainerStyle(;
    background_color=Vec4{Float32}(0.3f0, 0.7f0, 0.7f0, 1.0f0),
    border_color=Vec4{Float32}(0.0f0, 0.0f0, 0.0f0, 1.0f0),
    border_width=1.0f0,
    padding=25.0f0,
    corner_radius=25.0f0
)

my_style2 = ContainerStyle(;
    background_color=Vec4{Float32}(0.7f0, 0.3f0, 0.3f0, 1.0f0),
    border_color=Vec4{Float32}(0.0f0, 0.0f0, 0.0f0, 1.0f0),
    border_width=5.0f0,
    corner_radius=25.0f0
)

function MyApp()
    Container(
        Container(
            Container(; style=my_style2);
            style=my_style
        )
    )
end

screenshot(MyApp, "container_style.png", 812, 300);
nothing #hide
```

![Container Style](container_style.png)

### Corner Radius

```@example ContainerCornerRadius
using Fugl

function MyApp()
    Container(
        IntrinsicRow([
            Container(; style=ContainerStyle(corner_radius=0.0f0)),
            Container(; style=ContainerStyle(corner_radius=15.0f0)),
            Container(; style=ContainerStyle(corner_radius=40.0f0))
        ], spacing=20.0f0)
    )
end

screenshot(MyApp, "container_corner_radius.png", 812, 180);
nothing #hide
```

![Corner Radius Example](container_corner_radius.png)

### Border Width

```@example ContainerBorderWidth
using Fugl

function MyApp()
    Container(
        IntrinsicRow([
            Container(; style=ContainerStyle(border_width=0.0f0)),
            Container(; style=ContainerStyle(border_width=4.0f0)),
            Container(; style=ContainerStyle(border_width=10.0f0))
        ], spacing=20.0f0)
    )
end

screenshot(MyApp, "container_border_width.png", 812, 180);
nothing #hide
```

![Border Width Example](container_border_width.png)

## Interactive and Disabled States

Containers can have interactive states (hover, pressed) and disabled states with custom styling:

```@example ContainerInteraction
using Fugl

# Dark mode container styles
const CONTAINER_STYLE = ContainerStyle(
    background_color=Vec4f(0.08, 0.10, 0.14, 1.0f0),
    border_color=Vec4f(0.15, 0.18, 0.25, 1.0f0),
    border_width=1.5f0,
    padding=12.0f0,
    corner_radius=6.0f0
)

const CONTAINER_HOVER_STYLE = ContainerStyle(
    background_color=Vec4f(0.12, 0.14, 0.18, 1.0f0),
    border_color=Vec4f(0.20, 0.23, 0.30, 1.0f0),
    border_width=2.0f0,
    padding=12.0f0,
    corner_radius=6.0f0
)

const CONTAINER_PRESSED_STYLE = ContainerStyle(
    background_color=Vec4f(0.06, 0.08, 0.12, 1.0f0),
    border_color=Vec4f(0.12, 0.15, 0.22, 1.0f0),
    border_width=1.5f0,
    padding=12.0f0,
    corner_radius=6.0f0
)

const CONTAINER_DISABLED_STYLE = ContainerStyle(
    background_color=Vec4f(0.05, 0.05, 0.06, 1.0f0),
    border_color=Vec4f(0.10, 0.10, 0.12, 1.0f0),
    border_width=1.0f0,
    padding=12.0f0,
    corner_radius=6.0f0
)

# Text styles
const LIGHT_TEXT_STYLE = TextStyle(color=Vec4f(0.9, 0.9, 0.95, 1.0))
const DISABLED_TEXT_STYLE = TextStyle(color=Vec4f(0.4, 0.4, 0.45, 1.0))

# Container interaction states
button1 = Ref(InteractionState())
button2 = Ref(InteractionState())

function MyApp()
    Container(
        IntrinsicColumn([
            # Interactive container
            Container(
                Fugl.Text("Interactive Container", style=LIGHT_TEXT_STYLE),
                style=CONTAINER_STYLE,
                hover_style=CONTAINER_HOVER_STYLE,
                pressed_style=CONTAINER_PRESSED_STYLE,
                on_click=() -> println("Interactive container clicked!"),
                interaction_state= button1[],
                on_interaction_state_change=(new_state) -> button1[] = new_state
            ),
            
            # Disabled container
            Container(
                Fugl.Text("Disabled Container", style=DISABLED_TEXT_STYLE),
                style=CONTAINER_STYLE,
                hover_style=CONTAINER_HOVER_STYLE,
                pressed_style=CONTAINER_PRESSED_STYLE,
                disabled=true,
                disabled_style=CONTAINER_DISABLED_STYLE,
                on_click=() -> println("This won't print - container is disabled"),
                interaction_state= button2[],
                on_interaction_state_change=(new_state) -> button2[] = new_state
            )
        ], spacing=12.0f0),
        style=ContainerStyle(
            background_color=Vec4f(0.15, 0.15, 0.18, 1.0),
            padding=20.0f0,
            corner_radius=8.0f0
        )
    )
end

screenshot(MyApp, "container_interaction.png", 812, 300);
nothing #hide
```

![Interactive Container Example](container_interaction.png)

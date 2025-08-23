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

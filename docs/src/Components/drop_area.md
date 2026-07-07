# DropArea

`DropArea` wraps any component and calls a callback when files are dragged and dropped onto it.
The callback receives a `Vector{String}` of absolute file paths. Only drops whose cursor position falls inside the component bounds are forwarded.

## Basic Example

``` @example DropAreaBasic
using Fugl

dropped = Ref(String[])

function MyApp()
    message = isempty(dropped[]) ?
        "Drop files here" :
        join(basename.(dropped[]), ", ")

    content = Container(
            Fugl.Text(message, style=TextStyle(size_points=14, color=Vec4f(0.9, 0.9, 0.92, 1.0))),
        style=ContainerStyle(
            background_color=Vec4f(0.14, 0.14, 0.18, 1.0),
            border_color=Vec4f(0.28, 0.28, 0.32, 1.0),
            border_width=2.0f0,
            padding=24.0f0,
            corner_radius=10.0f0
        )
    )

    DropArea(content) do paths
        dropped[] = copy(paths)
    end
end

screenshot(MyApp, "drop_area_basic.png", 400, 180);
nothing #hide
```

![DropArea Basic](drop_area_basic.png)

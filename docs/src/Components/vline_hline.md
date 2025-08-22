# Separator Lines

Separator lines are visual elements used to divide content in your UI.

## HLine

Horizontal line separator that fills the available width.

```@example HLineExample
using Fugl
using Fugl: Text

function MyApp()
    Container(
        IntrinsicColumn([
            IntrinsicHeight(Container(Text("Default Line"))),
            HLine(),  # Basic horizontal line
            IntrinsicHeight(Container(Text("Oversize Line"))),
            HLine(style=SeparatorStyle(line_width=3.0f0, color=Vec4{Float32}(1.0f0, 0.2f0, 0.2f0, 1.0f0)), end_length=6.0f0),  # Thick red line
        ],
        padding=0.0f0, spacing=10.0f0)
    )
end

screenshot(MyApp, "hline_example.png", 812, 300);
nothing #hide
```

![HLine Example](hline_example.png)

## VLine

Vertical line separator that fills the available height.

```@example VLineExample
using Fugl
using Fugl: Text

function MyApp()
    Container(
        IntrinsicRow([
            Container(Text("Undersized Line")),
            VLine(end_length=-10.0f0),  # Basic vertical line
            Container(Text("Styled Line")),
            VLine(style=SeparatorStyle(line_width=3.0f0, color=Vec4{Float32}(0.2f0, 0.8f0, 0.2f0, 1.0f0))),  # Thick green line
        ],
        padding=0.0f0, spacing=10.0f0)
    )
end

screenshot(MyApp, "vline_example.png", 812, 200);
nothing #hide
```

![VLine Example](vline_example.png)

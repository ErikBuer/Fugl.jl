# Align

The alignment components allow you to position sized components within their containers.

## Horizontal Alignment

``` @example AlignHorizontalExample
using Fugl
using Fugl: Text

function MyApp()
    Container(
        Column(
            AlignHorizontal(FixedSize(Container(Text("Left")), 100, 50), :left),
            AlignHorizontal(FixedSize(Container(Text("Center")), 100, 50), :center),
            AlignHorizontal(FixedSize(Container(Text("Right")), 100, 50), :right),
        )
    )
end

screenshot(MyApp, "horizontal_alignment.png", 840, 300);
nothing #hide
```

![Horizontal alignment example](horizontal_alignment.png)

## Vertical Alignment

``` @example AlignVerticalExample
using Fugl
using Fugl: Text

function MyApp()
    Container(
        Row(
            AlignVertical(IntrinsicSize(Container(Text("Top"))), :top),
            AlignVertical(IntrinsicSize(Container(Text("Center"))), :center),
            AlignVertical(IntrinsicSize(Container(Text("Bottom"))), :bottom),
        )
    )
end

screenshot(MyApp, "vertical_alignment.png", 840, 300);
nothing #hide
```

![Vertical alignment example](vertical_alignment.png)
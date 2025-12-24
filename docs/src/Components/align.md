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

screenshot(MyApp, "horizontal_alignment.png", 812, 300);
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
            AlignVertical(IntrinsicSize(Container(Text("Middle"))), :middle),
            AlignVertical(IntrinsicSize(Container(Text("Bottom"))), :bottom),
        )
    )
end

screenshot(MyApp, "vertical_alignment.png", 812, 300);
nothing #hide
```

![Vertical alignment example](vertical_alignment.png)

## Convenience Functions

For shorter code, you can use these convenience functions:

``` @example AlignConvenienceExample
using Fugl
using Fugl: Text

function MyApp()
    Container(
        Column(
            # Horizontal alignment shortcuts
            AlignLeft(FixedSize(Container(Text("Left")), 100, 30)),
            AlignCenter(FixedSize(Container(Text("Center")), 100, 30)),
            AlignRight(FixedSize(Container(Text("Right")), 100, 30)),
            # Vertical alignment shortcuts
            Row(
                AlignTop(IntrinsicSize(Container(Text("Top")))),
                AlignMiddle(IntrinsicSize(Container(Text("Middle")))),
                AlignBottom(IntrinsicSize(Container(Text("Bottom")))),
            )
        )
    )
end

screenshot(MyApp, "alignment_convenience.png", 812, 400);
nothing #hide
```

![Alignment convenience functions](alignment_convenience.png)

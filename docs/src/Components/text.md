# Text

``` @example TextExample
using Fugl
using Fugl: Text

function MyApp()
    Container(
        Text("Some Text")
    )
end

screenshot(MyApp, "text.png", 812, 150);
nothing #hide
```

![Text](text.png)

## Wrapping

The `Text` component support wrapping by default.

``` @example TextWrappingExample
using Fugl
using Fugl: Text

function MyApp()
    Container(
        Text("Some strings may be too long to fit, and must be drawn over multiple lines.")
    )
end

screenshot(MyApp, "text_wrap.png", 400, 150);
nothing #hide
```

![Text wrapping](text_wrap.png)

## Horizontal Alignement

``` @example TextAlignement
using Fugl
using Fugl: Text

function MyApp()
    Container(
        Column([
            Text("Align left",   horizontal_align=:left), 
            Text("Align center", horizontal_align=:center), 
            Text("Align right",  horizontal_align=:right)
        ], padding=0.0, spacing=0.0);
        style=ContainerStyle(;padding=0.0f0)
    )
end

screenshot(MyApp, "text_align.png", 812, 150);
nothing #hide
```

![Text horizontal alignement](text_align.png)

## Vertical Alignement

``` @example TextVerticalAlignment
using Fugl
using Fugl: Text

function MyApp()
    Container(
        Row([
            Text("Align top",    vertical_align=:top), 
            Text("Align middle", vertical_align=:middle), 
            Text("Align bottom", vertical_align=:bottom)
        ], padding=0.0, spacing=0.0);
        style=ContainerStyle(;padding=0.0f0)
    )
end

screenshot(MyApp, "text_vertical_align.png", 812, 150);
nothing #hide
```

![Text vertical alignment](text_vertical_align.png)

## Text Style

Style is handeled by the `TextStyle` struct.

``` @example TextVerticalAlignment
using Fugl
using Fugl: Text

my_style = TextStyle(
    # font_path="SomeFont.ttf",
    size_px=32,
    color=Vec4f(0.1, 0.7, 0.7, 1.0), # RGBA
)


function MyApp()
    Container(
        Text("Some text"; style=my_style)
    )
end

screenshot(MyApp, "text_style.png", 812, 150);
nothing #hide
```

![Text Style Example](text_style.png)

## Text Rotation

Text can be rotated by specifying the `rotation_degrees` parameter. Positive angles rotate counter-clockwise.

``` @example TextRotationExample
using Fugl
using Fugl: Text

function MyApp()
    Container(
        Row([
            Text("0°", rotation_degrees=0.0f0, horizontal_align=:center, vertical_align=:middle),
            Text("45°", rotation_degrees=45.0f0, horizontal_align=:center, vertical_align=:middle),
            Text("90°", rotation_degrees=90.0f0, horizontal_align=:center, vertical_align=:middle)
        ], padding=20.0, spacing=20.0)
    )
end

screenshot(MyApp, "text_rotation.png", 300, 150);
nothing #hide
```

![Text Rotation Example](text_rotation.png)

## Text Rotation with Alignment

Text rotation works with all alignment options. The text rotates around its reference point determined by the alignment.

``` @example TextRotationAlignmentExample
using Fugl
using Fugl: Text

function MyApp()
    Container(
        Column([
            Row([
                Text("Left-Top", rotation_degrees=45.0f0, horizontal_align=:left, vertical_align=:top),
                Text("Center-Top", rotation_degrees=45.0f0, horizontal_align=:center, vertical_align=:top),
                Text("Right-Top", rotation_degrees=45.0f0, horizontal_align=:right, vertical_align=:top)
            ], padding=10.0, spacing=20.0),
            Row([
                Text("Left-Middle", rotation_degrees=45.0f0, horizontal_align=:left, vertical_align=:middle),
                Text("Center-Middle", rotation_degrees=45.0f0, horizontal_align=:center, vertical_align=:middle),
                Text("Right-Middle", rotation_degrees=45.0f0, horizontal_align=:right, vertical_align=:middle)
            ], padding=10.0, spacing=20.0),
            Row([
                Text("Left-Bottom", rotation_degrees=45.0f0, horizontal_align=:left, vertical_align=:bottom),
                Text("Center-Bottom", rotation_degrees=45.0f0, horizontal_align=:center, vertical_align=:bottom),
                Text("Right-Bottom", rotation_degrees=45.0f0, horizontal_align=:right, vertical_align=:bottom)
            ], padding=10.0, spacing=20.0)
        ], padding=15.0, spacing=15.0)
    )
end

screenshot(MyApp, "text_rotation_alignment.png", 600, 300);
nothing #hide
```

![Text Rotation with Alignment](text_rotation_alignment.png)

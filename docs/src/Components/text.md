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

## Text Clipping

By setting `wrap_text=false`, text will be rendered on a single line and clipped if it exceeds the container width, similar to VS Code's sidebar behavior.

``` @example TextClippingExample
using Fugl
using Fugl: Text

function MyApp()
    Container(
        Column([
            Text("This text will wrap normally because wrap_text is true by default", wrap_text=true),
            Text("This very long text will be clipped instead of wrapping to multiple lines", wrap_text=false)
        ], spacing=10.0)
    )
end

screenshot(MyApp, "text_clip.png", 400, 150);
nothing #hide
```

![Text clipping vs wrapping](text_clip.png)

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

## Word Wrapping with Vertical Alignment

Word wrapping also respects vertical alignment, centering or positioning the entire wrapped text block as a unit.

``` @example WrappedVerticalAlignment
using Fugl
using Fugl: Text

function MyApp()
    Container(
        Row([
            Container(
                Text("This long text will wrap to multiple lines and be aligned as a block at the top", 
                     vertical_align=:top, horizontal_align=:center, wrap_text=true),
                style=ContainerStyle(background_color=Vec4f(0.3, 0.3, 0.6, 1.0))
            ),
            Container(
                Text("This long text will wrap to multiple lines and be centered as a complete block in the middle", 
                     vertical_align=:middle, horizontal_align=:center, wrap_text=true),
                style=ContainerStyle(background_color=Vec4f(0.6, 0.4, 0.4, 1.0))
            ),
            Container(
                Text("This long text will wrap to multiple lines and be positioned as a block at the bottom", 
                     vertical_align=:bottom, horizontal_align=:center, wrap_text=true),
                style=ContainerStyle(background_color=Vec4f(0.4, 0.6, 0.4, 1.0))
            )
        ]),
    )
end

screenshot(MyApp, "wrapped_vertical_align.png", 600, 200);
nothing #hide
```

![Wrapped text vertical alignment](wrapped_vertical_align.png)

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

Text can be rotated by wrapping it with the `Rotate` component. Positive angles rotate counter-clockwise.

``` @example TextRotationExample
using Fugl
using Fugl: Text, Rotate

function MyApp()
    Container(
        Row([
            Rotate(Text("0°", horizontal_align=:center, vertical_align=:middle), rotation_degrees=0.0f0),
            Rotate(Text("45°", horizontal_align=:center, vertical_align=:middle), rotation_degrees=45.0f0),
            Rotate(Text("90°", horizontal_align=:center, vertical_align=:middle), rotation_degrees=90.0f0)
        ], padding=20.0, spacing=20.0)
    )
end

screenshot(MyApp, "text_rotation.png", 300, 150);
nothing #hide
```

![Text Rotation Example](text_rotation.png)

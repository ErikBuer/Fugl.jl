# Text

``` @example TextExample
using Fugl
using Fugl: Text

function MyApp()
    Container(
        Text("Some Text")
    )
end

screenshot(MyApp, "text.png", 840, 150);
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
        ])
    )
end

screenshot(MyApp, "text_align.png", 840, 150);
nothing #hide
```

![Text horizontal alignement](text_align.png)

## Vertical Alignement

``` @example TextVerticalAlignment
using Fugl
using Fugl: Text

function MyApp()
    Container(
        Column([
            Text("Align top",    vertical_align=:top), 
            Text("Align middle", vertical_align=:middle), 
            Text("Align bottom", vertical_align=:bottom)
        ])
    )
end

screenshot(MyApp, "text_vertical_align.png", 840, 150);
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

screenshot(MyApp, "text_style.png", 840, 150);
nothing #hide
```

![Text Style Example](text_style.png)

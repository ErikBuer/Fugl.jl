# TextButton

``` @example TextButtonExample
using Fugl

function MyApp()
    Container(
        TextButton("Some Text",
        on_click=() -> println("Clicked"),
        text_style = TextStyle(),
        container_style = ContainerStyle()
        )
    )
end

screenshot(MyApp, "textButton.png", 812, 150);
nothing #hide
```

![Text Button](textButton.png)

## IntrinsicSize TextButton

``` @example TextButtonExample
using Fugl

function MyApp()
    Container(
        AlignCenter(
            IntrinsicSize(
                TextButton("Some Text",
                on_click=() -> println("Clicked"),
                text_style = TextStyle(),
                container_style = ContainerStyle()
                )
            )
        )
    )
end

screenshot(MyApp, "intrinsicSizeTextButton.png", 812, 150);
nothing #hide
```

![Text Button](intrinsicSizeTextButton.png)

## Dark Theme Example

``` @example DarkTextButtonExample
using Fugl

function MyApp()
    # Dark theme button style
    dark_button_style = ContainerStyle(
        background_color = Vec4f(0.15, 0.15, 0.15, 1.0),
        border_color = Vec4f(0.4, 0.6, 0.8, 1.0),
        border_width = 2.0f0
    )
    
    dark_text_style = TextStyle(
        color = Vec4f(0.9, 0.9, 0.9, 1.0),
        size_px = 16
    )
    
    # Dark background container
    Container(
        AlignCenter(
            FixedSize(
                TextButton("Dark Mode Button",
                    on_click=() -> println("Dark button clicked"),
                    text_style = dark_text_style,
                    container_style = dark_button_style
                ),
                200, 50
            )
        ),
        style = ContainerStyle(background_color = Vec4f(0.1, 0.1, 0.1, 1.0))
    )
end

screenshot(MyApp, "dark_text_button.png", 812, 150);
nothing #hide
```

![Dark Text Button](dark_text_button.png)

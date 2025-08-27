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

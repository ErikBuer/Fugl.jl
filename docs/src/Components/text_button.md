# Text Buttons

``` @example TextButtonExample
using Fugl

function MyApp()
    Container(
        TextButton("Some Text", on_click=() -> println("Clicked"))
    )
end

screenshot(MyApp, "textButton.png", 840, 150);
nothing #hide
```

![Text Button](textButton.png)

# Text Buttons

``` @example TextButtonExample
using Glance

function MyApp()
    Container(
        TextButton("Some Text", on_click=() -> println("Clicked"))
    )
end

screenshot(MyApp, "textButton.png", 400, 150);
nothing #hide
```

![Text Button](textButton.png)

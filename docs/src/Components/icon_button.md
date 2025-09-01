# IconButton

```@example IconButtonExample
using Fugl

function MyApp()
    Container(
        IconButton("../assets/julia_logo.png",
            on_click=() -> println("Icon clicked")
        )
    )
end

screenshot(MyApp, "iconButton.png", 200, 150);
nothing #hide
```

![Icon Button](iconButton.png)

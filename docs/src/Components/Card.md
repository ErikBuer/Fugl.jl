# Card

The `Card` component displays a title and content in a styled container, useful for quickly get a UI up an running.

## Example

```@example CardExample
using Fugl
using Fugl: Text

function MyApp()
    Card(
        "Card Title",
        Text("Card content.")
    )
end

screenshot(MyApp, "card_example.png", 812, 120);
nothing #hide
```

![Card Example](card_example.png)

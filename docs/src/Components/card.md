# Card

The `Card` component displays a title and content in a styled container, useful for quickly get a UI up an running.

## Example

```@example CardExample
using Fugl
using Fugl: Text

function MyApp()
    Card(
        "Card Title",
        Text("Card contents")
    )
end

screenshot(MyApp, "card_example.png", 812, 120);
nothing #hide
```

![Card Example](card_example.png)

## Styled card
```@example DarkCardExample
using Fugl
using Fugl: Text

# Dark theme card style
dark_card_style = ContainerStyle(
    background_color = Vec4f(0.18, 0.18, 0.22, 1.0),  # Dark gray background
    border_color = Vec4f(0.4, 0.4, 0.45, 1.0),       # Subtle border
    border_width = 1.5f0,
    corner_radius = 0.0f0,
    padding = 15.0f0
)

# Dark theme title style
dark_title_style = TextStyle(
    size_px = 18,
    color = Vec4f(0.9, 0.9, 0.95, 1.0)  # Light text for title
)

function MyApp()
    Card(
        "Dark Mode Card",
        Empty(),
        style=dark_card_style,
        title_style=dark_title_style
    )
end

screenshot(MyApp, "card_dark_example.png", 812, 300);
nothing #hide
```

![Dark Theme Card Example](card_dark_example.png)

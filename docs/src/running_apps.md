# Running Applications

## run() vs screenshot()

Fugl provides two ways to execute your UI functions:

- **`run()`** - Opens an interactive window
- **`screenshot()`** - Captures a static image

## Interactive Applications

Use `run()` to create interactive applications with real-time user input.

```julia
using Fugl

button_state = Ref(false)

function MyApp()
    Card(
        "Interactive Demo",
        CheckBox(
            button_state[];
            label="Click me!",
            on_change=(value) -> button_state[] = value
        )
    )
end

# Launch interactive window
Fugl.run(MyApp, title="My App", window_width_px=400, window_height_px=300)
```

### run() Options

```julia
run(ui_function;
    title="Fugl",                    # Window title
    window_width_px=1920,            # Initial window width
    window_height_px=1080,           # Initial window height
    fps_overlay=false,               # Show FPS counter
)
```

### Periodic Callbacks

!!! warning "Experimental"
    This feature is experimental and the API may change in future versions.


Execute functions at regular frame intervals:

```julia
run(MyApp)
```

## Documentation Screenshots

Use `screenshot()` for documentation and static image generation.

```julia
function MyApp()
    Card("Documentation Example", 
         Text("This creates a PNG file"))
end

# Generate static image
screenshot(MyApp, "output.png", 400, 300)
```

### screenshot() Options

```julia
screenshot(ui_function, filename, width, height)
# ui_function: Function that returns AbstractView
# filename: Output PNG file path
# width: Image width in pixels
# height: Image height in pixels
```

## Font Configuration for Compiled Applications

When compiling applications with `juliac`, you may need to configure the font path to match your deployment environment.

### Setting a Custom Default Font

Override the default font path before any text components are created:

```julia
using Fugl

# Set custom font path for your application
Fugl.DEFAULT_FONT_PATH[] = joinpath(@__DIR__, "assets", "MyFont.ttf")

# Explicitly load the font (optional - will be loaded automatically on first use)
Fugl.load_default_font!()

function MyApp()
    Container(
        Text("Hello World")  # Uses the custom default font
    )
end

Fugl.run(MyApp)
```

### Using Multiple Fonts

Load additional fonts and use them in specific text components:

```julia
using Fugl

# Load custom fonts with explicit cache keys
Fugl.get_font_by_path(:title_font, "/path/to/TitleFont.ttf")
Fugl.get_font_by_path(:body_font, "/path/to/BodyFont.ttf")

# Create styles with different font cache keys
title_style = TextStyle(font_cache_key=:title_font, size_px=32)
body_style = TextStyle(font_cache_key=:body_font, size_px=16)

function MyApp()
    Column(
        Fugl.Text("Title"; style=title_style),
        Fugl.Text("Body text"; style=body_style),
    )
end
```
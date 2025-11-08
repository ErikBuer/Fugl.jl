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
run(MyApp, title="My App", window_width_px=400, window_height_px=300)
```

### run() Options

```julia
run(ui_function;
    title="Fugl",                    # Window title
    window_width_px=1920,            # Initial window width
    window_height_px=1080,           # Initial window height
    fps_overlay=false,               # Show FPS counter
    periodic_callbacks=PeriodicCallback[]  # Callbacks executed every N frames (Experimental)
)
```

### Periodic Callbacks

!!! warning "Experimental"
    This feature is experimental and the API may change in future versions.


Execute functions at regular frame intervals:

```julia
# Run every 60 frames (~1 second at 60fps)
file_check = PeriodicCallback(() -> check_files(), 60)

# Run every 300 frames (~5 seconds at 60fps)  
data_update = PeriodicCallback(() -> update_data(), 300)

run(MyApp, periodic_callbacks=[file_check, data_update])
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
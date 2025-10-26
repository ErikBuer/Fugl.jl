# CheckBox

The `CheckBox` component provides a boolean input control with an optional text label. It supports user-managed state through callbacks and offers comprehensive styling options.

## Basic Usage

The CheckBox requires user-managed state using a `Ref{Bool}` and provides callbacks for state changes.

```@example CheckBoxBasic
using Fugl

# Checkbox state  
checkbox_state = Ref(false)
checkbox_state2 = Ref(true)

function MyApp()
    Card(
        "CheckBox Demo",
        Column(
            CheckBox(
                checkbox_state[];
                label="Enable feature",
                on_change=(new_value) -> begin
                    checkbox_state[] = new_value
                    println("Checkbox is now: $(new_value)")
                end
            ),
            CheckBox(
                checkbox_state2[];
                label="Enable feature 2",
                on_change=(new_value) -> begin
                    checkbox_state2[] = new_value
                    println("Checkbox 2 is now: $(new_value)")
                end
            )
        )
    )
end

screenshot(MyApp, "checkbox_basic.png", 400, 120);
nothing #hide
```

![Basic CheckBox](checkbox_basic.png)

## Dark Theme Example

```@example CheckBoxDark
using Fugl

# Checkbox states
checkbox_state3 = Ref(false)
checkbox_state4 = Ref(true)

# Dark theme card style
dark_card_style = ContainerStyle(
    background_color=Vec4f(0.15, 0.15, 0.18, 1.0),  # Dark background
    border_color=Vec4f(0.25, 0.25, 0.30, 1.0),      # Subtle border
    border_width=1.5f0,
    padding=12.0f0,
    corner_radius=6.0f0,
    anti_aliasing_width=1.0f0
)

# Dark theme title style
dark_title_style = TextStyle(
    size_px=18,
    color=Vec4f(0.9, 0.9, 0.95, 1.0)  # Light text for titles
)

# Dark theme checkbox style
dark_checkbox_style = CheckBoxStyle(
    size=18.0f0,
    background_color=Vec4f(0.08, 0.10, 0.14, 1.0),           # Dark unchecked background
    background_color_checked=Vec4f(0.2, 0.6, 0.9, 1.0),      # Blue when checked
    border_color=Vec4f(0.25, 0.25, 0.30, 1.0),               # Subtle border
    border_width=1.0f0,
    check_color=Vec4f(1.0, 1.0, 1.0, 1.0),                   # White checkmark
    corner_radius=3.0f0,
    padding=2.0f0,
    label_style=TextStyle(size_px=14, color=Vec4f(0.9, 0.9, 0.95, 1.0))  # Light text
)

function MyDarkApp()
    Card(
        "Dark Theme CheckBox Demo",
        Column(
            CheckBox(
                checkbox_state3[];
                label="Enable dark mode feature",
                style=dark_checkbox_style,
                on_change=(new_value) -> begin
                    checkbox_state3[] = new_value
                    println("Dark checkbox is now: $(new_value)")
                end
            ),
            CheckBox(
                checkbox_state4[];
                label="Use advanced settings",
                style=dark_checkbox_style,
                on_change=(new_value) -> begin
                    checkbox_state4[] = new_value
                    println("Dark checkbox 2 is now: $(new_value)")
                end
            )
        ),
        style=dark_card_style,
        title_style=dark_title_style
    )
end

screenshot(MyDarkApp, "checkbox_dark.png", 400, 120);
nothing #hide
```

![Dark Theme CheckBox](checkbox_dark.png)

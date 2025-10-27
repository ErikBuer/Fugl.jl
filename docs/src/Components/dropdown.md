# Dropdown

The `Dropdown` component provides a dropdown selection interface that allows users to choose from a list of options.
It follows the same immutable state management pattern as other Fugl components.

```@example DropDown
using Fugl
using Fugl: Text

# Initialize dropdown state
options = ["Small", "Medium", "Large", "Extra Large"]
# Create initial state using Ref for reactivity
dropdown_state = Ref(DropdownState(options; selected_index=1, is_open=true)) # force it open for demonstration purposes.

# Custom styling
dropdown_style = DropdownStyle(
    text_style=TextStyle(size_px=14.0f0),
    corner_radius=6.0f0,
    padding=12.0f0,
    item_height_px=32.0f0,
    max_visible_items=3
)

function MyApp()
    return Card(
        "Dropdown example:",
        Dropdown(
            dropdown_state[];
            style=dropdown_style,
            on_state_change=(new_state) -> dropdown_state[] = new_state,
            on_select=(value, index) -> println("Selected: $value (index: $index)")
        )
    )
end

screenshot(MyApp, "dropdown.png", 812, 400);
nothing #hide
```

![Dropdown](dropdown.png)

## Dark Theme Example

```@example DarkDropdown
using Fugl
using Fugl: Text

# Initialize dark dropdown state
dark_options = ["Dark Small", "Dark Medium", "Dark Large", "Dark Extra Large"]
dark_dropdown_state = Ref(DropdownState(dark_options; selected_index=2, is_open=true)) # force it open for demonstration

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

# Dark theme dropdown style
dark_dropdown_style = DropdownStyle(
    text_style=TextStyle(size_px=14, color=Vec4f(0.9, 0.9, 0.95, 1.0)),  # Light text
    background_color=Vec4f(0.08, 0.10, 0.14, 1.0),                       # Very dark background
    background_color_hover=Vec4f(0.12, 0.14, 0.18, 1.0),                 # Slightly lighter on hover
    background_color_open=Vec4f(0.06, 0.08, 0.12, 1.0),                  # Even darker when open
    border_color=Vec4f(0.15, 0.18, 0.25, 1.0),                           # Dark border with blue tone
    border_width=1.5f0,
    corner_radius=6.0f0,
    padding=12.0f0,
    arrow_color=Vec4f(0.9, 0.9, 0.95, 1.0),                              # Light arrow
    item_height_px=32.0f0,
    max_visible_items=3
)

function MyDarkApp()
    return Card(
        "Dark Theme Dropdown:",
        Dropdown(
            dark_dropdown_state[];
            style=dark_dropdown_style,
            on_state_change=(new_state) -> dark_dropdown_state[] = new_state,
            on_select=(value, index) -> println("Dark selected: $value (index: $index)")
        ),
        style=dark_card_style,
        title_style=dark_title_style
    )
end

screenshot(MyDarkApp, "dark_dropdown.png", 812, 400);
nothing #hide
```

![Dark Dropdown](dark_dropdown.png)


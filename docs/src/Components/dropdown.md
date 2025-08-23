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

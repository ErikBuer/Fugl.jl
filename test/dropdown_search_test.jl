using Fugl

# Create dropdown with many options to test search
options = [
    "Apple", "Banana", "Cherry", "Date", "Elderberry", "Fig", "Grape",
    "Honeydew", "Indian Fig", "Jackfruit", "Kiwi", "Lemon", "Mango",
    "Nectarine", "Orange", "Papaya", "Quince", "Raspberry", "Strawberry",
    "Tomato", "Ugli Fruit", "Vanilla Bean", "Watermelon", "Xigua", "Yellow Passion Fruit", "Zucchini"
]

# Create dropdown state
dropdown_state = Ref(DropdownState(options; selected_index=1))

function MyApp()
    Container(
        Dropdown(
            dropdown_state[];
            style=DropdownStyle(),
            on_state_change=(new_state) -> (dropdown_state[] = new_state),
            on_select=(value, index) -> println("Selected: $value (index: $index)"),
            placeholder_text="Select a fruit..."
        )
    )
end

Fugl.run(MyApp, title="Dropdown Test", window_width_px=400, window_height_px=300, fps_overlay=true)
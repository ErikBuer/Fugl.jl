# TextField

The TextField component provides single-line text input with optional length limiting. It's designed for typical form inputs and automatically removes newlines to keep content on one line.

``` @example TextFieldExample
using Fugl

function MyApp()
    # Store EditorState for different fields
    name_state = Ref(EditorState("John Doe"))
    email_state = Ref(EditorState("user@example.com"))
    phone_state = Ref(EditorState("555-1234"))

    # Dark theme styles
    dark_container_style = ContainerStyle(
        background_color = Vec4f(0.12, 0.12, 0.12, 1.0),
        border_color = Vec4f(0.3, 0.3, 0.3, 1.0),
        border_width = 1.0f0,
        corner_radius = 8.0f0
    )

    dark_text_style = TextStyle(
        color = Vec4f(0.9, 0.9, 0.9, 1.0),
        size_px = 16
    )

    dark_card_style = ContainerStyle(
        background_color = Vec4f(0.18, 0.18, 0.18, 1.0),
        border_color = Vec4f(0.4, 0.4, 0.4, 1.0),
        border_width = 1.0f0,
        corner_radius = 8.0f0
    )

    dark_card_title_style = TextStyle(
        color = Vec4f(0.9, 0.9, 0.9, 1.0),
        size_px = 16
    )

    dark_field_style = TextBoxStyle(
        text_style = TextStyle(color = Vec4f(0.9, 0.9, 0.9, 1.0), size_px = 14),
        background_color_focused = Vec4f(0.2, 0.2, 0.25, 1.0),
        background_color_unfocused = Vec4f(0.15, 0.15, 0.15, 1.0),
        border_color = Vec4f(0.4, 0.6, 0.8, 1.0),
        border_width = 1.5f0,
        corner_radius = 6.0f0
    )

    Container(
        IntrinsicColumn([
            Card(
                "Full Name",
                TextField(
                    name_state[];
                    style=dark_field_style,
                    on_state_change=(new_state) -> name_state[] = new_state,
                    on_change=(new_text) -> println("Name changed to: '", new_text, "'")
                ),
                style=dark_card_style,
                title_style=dark_card_title_style
            ),
            Card(
                "Email (max 30 chars)",
                TextField(
                    email_state[];
                    max_length=30,
                    style=dark_field_style,
                    on_state_change=(new_state) -> email_state[] = new_state,
                    on_change=(new_text) -> println("Email changed to: '", new_text, "' (length: ", length(new_text), ")")
                ),
                style=dark_card_style,
                title_style=dark_card_title_style
            ),
            Card(
                "Phone (max 15 chars)",
                TextField(
                    phone_state[];
                    max_length=15,
                    style=dark_field_style,
                    on_state_change=(new_state) -> phone_state[] = new_state,
                    on_change=(new_text) -> println("Phone changed to: '", new_text, "' (length: ", length(new_text), ")")
                ),
                style=dark_card_style,
                title_style=dark_card_title_style
            ),
            Container(
                IntrinsicColumn([
                    IntrinsicHeight(Fugl.Text("Current Values:", style=TextStyle(size_px=16, color=Vec4f(0.8, 0.8, 0.8, 1.0)))),
                    IntrinsicHeight(Fugl.Text("Name: \"$(name_state[].text)\"", style=TextStyle(size_px=14, color=Vec4f(0.7, 0.7, 0.7, 1.0)))),
                    IntrinsicHeight(Fugl.Text("Email: \"$(email_state[].text)\" ($(length(email_state[].text)) chars)", style=TextStyle(size_px=14, color=Vec4f(0.7, 0.7, 0.7, 1.0)))),
                    IntrinsicHeight(Fugl.Text("Phone: \"$(phone_state[].text)\" ($(length(phone_state[].text)) chars)", style=TextStyle(size_px=14, color=Vec4f(0.7, 0.7, 0.7, 1.0)))),
                ], padding=10.0, spacing=5.0),
                style=dark_container_style
            )
        ], padding=0.0, spacing=5.0),
        style=ContainerStyle(
            background_color=Vec4f(0.08, 0.08, 0.08, 1.0),
            padding=5.0f0
        )
    )
end

screenshot(MyApp, "textField.png", 812, 500);
nothing #hide
```

![TextField](textField.png)
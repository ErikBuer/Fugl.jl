# TextBox

``` @example TextBoxExample
using Fugl
using Fugl: Text

text_box_state = Ref(EditorState("Enter your text here..."))

function MyApp()
    Card(
        "Plain Text Box:",
        TextBox(
            text_box_state[];
            on_state_change=(new_state) -> text_box_state[] = new_state,
            on_change=(new_text) -> println("Optional hook. Text is now: ", new_text[1:min(20, length(new_text))], "...")
        )
    )
end

screenshot(MyApp, "textBox.png", 812, 400);
nothing #hide
```

![Text Box](textBox.png)

## Focus and Blur Events

``` @example FocusBlurTextBoxExample
using Fugl

focus_state = Ref("No focus events yet")
text_box_state = Ref(EditorState("Click me to see focus events"))

function MyApp()
    Column(
        Text(focus_state[]),
        TextBox(
            text_box_state[];
            on_state_change=(new_state) -> text_box_state[] = new_state,
            on_focus=() -> focus_state[] = "TextBox gained focus! 🎯",
            on_blur=() -> focus_state[] = "TextBox lost focus 😔"
        )
    )
end

screenshot(MyApp, "textBoxFocusBlur.png", 812, 300);
nothing #hide
```

![TextBox Focus/Blur Events](textBoxFocusBlur.png)

## Dark Theme Example

``` @example DarkTextBoxExample
using Fugl
using Fugl: Text

dark_text_box_state = Ref(EditorState("Dark theme text box..."))

function MyApp()
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
    
    # Dark theme text box style
    dark_text_box_style = TextBoxStyle(
        background_color_unfocused = Vec4f(0.08, 0.10, 0.14, 1.0),
        background_color_focused = Vec4f(0.06, 0.08, 0.12, 1.0),
        border_color = Vec4f(0.15, 0.18, 0.25, 1.0),
        border_width = 1.5f0,
        corner_radius = 6.0f0,
        padding = 12.0f0,
        cursor_color = Vec4f(1.0, 1.0, 1.0, 0.8),
        selection_color = Vec4f(0.4, 0.6, 0.9, 0.5),
        text_style = TextStyle(
            color = Vec4f(0.9, 0.9, 0.95, 1.0),  # Light text
            size_px = 16
        )
    )

    Card(
        "Dark Theme Text Box:",
        TextBox(
            dark_text_box_state[];
            style = dark_text_box_style,
            on_state_change=(new_state) -> dark_text_box_state[] = new_state,
            on_change=(new_text) -> println("Dark text changed: ", new_text[1:min(20, length(new_text))], "...")
        ),
        style=dark_card_style,
        title_style=dark_title_style
    )
end

screenshot(MyApp, "dark_text_box.png", 812, 400);
nothing #hide
```

![Dark Text Box](dark_text_box.png)

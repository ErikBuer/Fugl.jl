# TextButton

## Basic TextButton (No Interaction Styling)

``` @example TextButtonExample
using Fugl

function MyApp()
    Container(
        TextButton("Basic Button",
            on_click=() -> println("Basic button clicked"),
            text_style = TextStyle(size_points=16),
            container_style = ContainerStyle(
                background_color = Vec4f(0.9, 0.9, 0.9, 1.0),
                border_color = Vec4f(0.6, 0.6, 0.6, 1.0),
                border_width = 1.0f0,
                padding = 12.0f0,
                corner_radius = 4.0f0
            )
        ),
        style = ContainerStyle(
            background_color = Vec4f(0.95, 0.95, 0.95, 1.0),
            padding = 20.0f0
        )
    )
end

screenshot(MyApp, "textButton.png", 812, 150);
nothing #hide
```

![Text Button](textButton.png)

*Note: This example doesn't use InteractionState, so hover and pressed styling won't work.*

## TextButton with InteractionState

``` @example TextButtonInteractive
using Fugl

# State for managing button interaction
button_interaction = Ref(InteractionState())

# Normal button style
normal_style = ContainerStyle(
    background_color = Vec4f(0.2, 0.4, 0.8, 1.0),
    border_color = Vec4f(0.1, 0.3, 0.7, 1.0),
    border_width = 2.0f0,
    padding = 12.0f0,
    corner_radius = 6.0f0
)

# Hover style
hover_style = ContainerStyle(
    background_color = Vec4f(0.3, 0.5, 0.9, 1.0),
    border_color = Vec4f(0.2, 0.4, 0.8, 1.0),
    border_width = 2.0f0,
    padding = 12.0f0,
    corner_radius = 6.0f0
)

# Pressed style
pressed_style = ContainerStyle(
    background_color = Vec4f(0.1, 0.2, 0.6, 1.0),
    border_color = Vec4f(0.05, 0.15, 0.5, 1.0),
    border_width = 2.0f0,
    padding = 12.0f0,
    corner_radius = 6.0f0
)

text_style = TextStyle(
    color = Vec4f(1.0, 1.0, 1.0, 1.0),
    size_points = 16
)

function MyApp()   
    Container(
        AlignCenter(
            FixedSize(
                TextButton("Interactive Button",
                    on_click=() -> println("Interactive button clicked!"),
                    text_style = text_style,
                    container_style = normal_style,
                    hover_style = hover_style,
                    pressed_style = pressed_style,
                    interaction_state = button_interaction[],
                    on_interaction_state_change = (new_state) -> button_interaction[] = new_state
                ),
                200, 50
            )
        ),
        style = ContainerStyle(
            background_color = Vec4f(0.08, 0.08, 0.08, 1.0),
            padding = 20.0f0
        )
    )
end

screenshot(MyApp, "interactive_text_button.png", 812, 150);
nothing #hide
```

![Interactive Text Button](interactive_text_button.png)

## Interaction States

``` @example DarkTextButtonExample
using Fugl

# State for managing button interactions
button1_interaction = Ref(InteractionState())
button2_interaction = Ref(InteractionState())
button3_interaction = Ref(InteractionState())

# Green button styles
green_normal = ContainerStyle(
    background_color = Vec4f(0.2, 0.6, 0.3, 1.0),
    border_color = Vec4f(0.1, 0.5, 0.2, 1.0),
    border_width = 2.0f0,
    padding = 10.0f0,
    corner_radius = 8.0f0
)

green_hover = ContainerStyle(
    background_color = Vec4f(0.3, 0.7, 0.4, 1.0),
    border_color = Vec4f(0.2, 0.6, 0.3, 1.0),
    border_width = 2.0f0,
    padding = 10.0f0,
    corner_radius = 8.0f0
)

green_pressed = ContainerStyle(
    background_color = Vec4f(0.1, 0.4, 0.2, 1.0),
    border_color = Vec4f(0.05, 0.3, 0.15, 1.0),
    border_width = 2.0f0,
    padding = 10.0f0,
    corner_radius = 8.0f0
)

# Orange button styles
orange_normal = ContainerStyle(
    background_color = Vec4f(0.8, 0.5, 0.2, 1.0),
    border_color = Vec4f(0.7, 0.4, 0.1, 1.0),
    border_width = 2.0f0,
    padding = 10.0f0,
    corner_radius = 8.0f0
)

orange_hover = ContainerStyle(
    background_color = Vec4f(0.9, 0.6, 0.3, 1.0),
    border_color = Vec4f(0.8, 0.5, 0.2, 1.0),
    border_width = 2.0f0,
    padding = 10.0f0,
    corner_radius = 8.0f0
)

orange_pressed = ContainerStyle(
    background_color = Vec4f(0.6, 0.3, 0.1, 1.0),
    border_color = Vec4f(0.5, 0.2, 0.05, 1.0),
    border_width = 2.0f0,
    padding = 10.0f0,
    corner_radius = 8.0f0
)

# Red button styles
red_normal = ContainerStyle(
    background_color = Vec4f(0.8, 0.2, 0.2, 1.0),
    border_color = Vec4f(0.7, 0.1, 0.1, 1.0),
    border_width = 2.0f0,
    padding = 10.0f0,
    corner_radius = 8.0f0
)

red_hover = ContainerStyle(
    background_color = Vec4f(0.9, 0.3, 0.3, 1.0),
    border_color = Vec4f(0.8, 0.2, 0.2, 1.0),
    border_width = 2.0f0,
    padding = 10.0f0,
    corner_radius = 8.0f0
)

red_pressed = ContainerStyle(
    background_color = Vec4f(0.6, 0.1, 0.1, 1.0),
    border_color = Vec4f(0.5, 0.05, 0.05, 1.0),
    border_width = 2.0f0,
    padding = 10.0f0,
    corner_radius = 8.0f0
)

button_text_style = TextStyle(
    color = Vec4f(1.0, 1.0, 1.0, 1.0),
    size_points = 14
)

function MyApp()
    
    # Dark background container
    Container(
        IntrinsicColumn([
            # Success button
            AlignCenter(
                FixedSize(
                    TextButton("Success",
                        on_click=() -> println("Success button clicked"),
                        text_style = button_text_style,
                        container_style = green_normal,
                        hover_style = green_hover,
                        pressed_style = green_pressed,
                        interaction_state = button1_interaction[],
                        on_interaction_state_change = (new_state) -> button1_interaction[] = new_state
                    ),
                    120, 40
                )
            ),
            
            # Warning button
            AlignCenter(
                FixedSize(
                    TextButton("Warning",
                        on_click=() -> println("Warning button clicked"),
                        text_style = button_text_style,
                        container_style = orange_normal,
                        hover_style = orange_hover,
                        pressed_style = orange_pressed,
                        interaction_state = button2_interaction[],
                        on_interaction_state_change = (new_state) -> button2_interaction[] = new_state
                    ),
                    120, 40
                )
            ),
            
            # Danger button
            AlignCenter(
                FixedSize(
                    TextButton("Danger",
                        on_click=() -> println("Danger button clicked"),
                        text_style = button_text_style,
                        container_style = red_normal,
                        hover_style = red_hover,
                        pressed_style = red_pressed,
                        interaction_state = button3_interaction[],
                        on_interaction_state_change = (new_state) -> button3_interaction[] = new_state
                    ),
                    120, 40
                )
            )
        ], spacing=15.0f0),
        style = ContainerStyle(
            background_color = Vec4f(0.08, 0.08, 0.08, 1.0),
            padding = 20.0f0,
            corner_radius = 8.0f0
        )
    )
end

screenshot(MyApp, "dark_interactive_text_buttons.png", 812, 250);
nothing #hide
```

![Dark Interactive Text Buttons](dark_interactive_text_buttons.png)

## Disabled Button

``` @example DisabledButtonExample
using Fugl

# Dark mode button styles
const BUTTON_STYLE = ContainerStyle(
    background_color=Vec4f(0.08, 0.10, 0.14, 1.0f0),
    border_color=Vec4f(0.15, 0.18, 0.25, 1.0f0),
    border_width=1.5f0,
    padding=12.0f0,
    corner_radius=6.0f0
)

const BUTTON_HOVER_STYLE = ContainerStyle(
    background_color=Vec4f(0.12, 0.14, 0.18, 1.0f0),
    border_color=Vec4f(0.20, 0.23, 0.30, 1.0f0),
    border_width=2.0f0,
    padding=12.0f0,
    corner_radius=6.0f0
)

const BUTTON_PRESSED_STYLE = ContainerStyle(
    background_color=Vec4f(0.06, 0.08, 0.12, 1.0f0),
    border_color=Vec4f(0.12, 0.15, 0.22, 1.0f0),
    border_width=1.5f0,
    padding=12.0f0,
    corner_radius=6.0f0
)

const BUTTON_DISABLED_STYLE = ContainerStyle(
    background_color=Vec4f(0.05, 0.05, 0.06, 1.0f0),
    border_color=Vec4f(0.10, 0.10, 0.12, 1.0f0),
    border_width=1.0f0,
    padding=12.0f0,
    corner_radius=6.0f0
)

# Dark mode card style
const DARK_CARD_STYLE = ContainerStyle(
    background_color=Vec4f(0.15, 0.15, 0.18, 1.0),
    border_color=Vec4f(0.25, 0.25, 0.30, 1.0),
    border_width=1.5f0,
    padding=12.0f0,
    corner_radius=6.0f0,
    anti_aliasing_width=1.0f0
)

# Dark mode title style
const DARK_TITLE_STYLE = TextStyle(
    size_points=18,
    color=Vec4f(0.9, 0.9, 0.95, 1.0)
)

# Text styles
const LIGHT_TEXT_STYLE = TextStyle(color=Vec4f(0.9, 0.9, 0.95, 1.0))
const DISABLED_TEXT_STYLE = TextStyle(color=Vec4f(0.4, 0.4, 0.45, 1.0))

# Button interaction states
enabled_button_state = Ref(InteractionState())

function MyApp()
    Card(
        "Dark Mode Button States",
        Column(
            [
                # Interactive button (enabled)
                TextButton("Interactive Button",
                    on_click=() -> println("Interactive button clicked!"),
                    container_style=BUTTON_STYLE,
                    hover_style=BUTTON_HOVER_STYLE,
                    pressed_style=BUTTON_PRESSED_STYLE,
                    text_style=LIGHT_TEXT_STYLE,
                    interaction_state=enabled_button_state[],
                    on_interaction_state_change=(new_state) -> enabled_button_state[] = new_state
                ),

                # Disabled button
                TextButton("Disabled Button",
                    disabled=true,
                    on_click=() -> println("This shouldn't print - button is disabled"),
                    container_style=BUTTON_STYLE,
                    hover_style=BUTTON_HOVER_STYLE,
                    pressed_style=BUTTON_PRESSED_STYLE,
                    disabled_style=BUTTON_DISABLED_STYLE,
                    text_style=LIGHT_TEXT_STYLE,
                    disabled_text_style=DISABLED_TEXT_STYLE
                ),
            ],
            spacing=12.0f0),
        style=DARK_CARD_STYLE,
        title_style=DARK_TITLE_STYLE
    )
end

screenshot(MyApp, "disabled_button.png", 812, 250);
nothing #hide
```

![Dark Interactive Text Buttons](disabled_button.png)

## Hover and Press States

Demonstrates all available interaction-state combinations: hover + press, hover only, press only, no effects, and custom per-state colors.

``` @example HoverDemoExample
using Fugl
using Fugl: Text

# Dark theme palette
const DARK_BG      = Vec4f(0.08, 0.08, 0.08, 1.0)
const DARK_SURFACE = Vec4f(0.15, 0.15, 0.18, 1.0)
const DARK_HOVER   = Vec4f(0.22, 0.22, 0.28, 1.0)
const DARK_PRESSED = Vec4f(0.10, 0.10, 0.12, 1.0)
const DARK_BORDER  = Vec4f(0.30, 0.30, 0.30, 1.0)
const DARK_TEXT    = Vec4f(0.90, 0.90, 0.90, 1.0)

const DEFAULT_BTN_STYLE = ContainerStyle(
    background_color=DARK_SURFACE, border_color=DARK_BORDER,
    border_width=1.0f0, padding=12.0f0, corner_radius=6.0f0
)
const DEFAULT_HOVER_STYLE = ContainerStyle(
    background_color=DARK_HOVER, border_color=Vec4f(0.4, 0.4, 0.4, 1.0),
    border_width=1.0f0, padding=12.0f0, corner_radius=6.0f0
)
const DEFAULT_PRESSED_STYLE = ContainerStyle(
    background_color=DARK_PRESSED, border_color=Vec4f(0.5, 0.5, 0.5, 1.0),
    border_width=2.0f0, padding=12.0f0, corner_radius=6.0f0
)

# Custom button: surface → blue on hover → red on press
const CUSTOM_BTN_STYLE = ContainerStyle(
    background_color=DARK_SURFACE, border_color=DARK_BORDER,
    border_width=2.0f0, padding=14.0f0, corner_radius=8.0f0
)
const CUSTOM_HOVER_STYLE = ContainerStyle(
    background_color=Vec4f(0.3, 0.5, 0.8, 1.0),
    border_color=Vec4f(0.2, 0.4, 0.7, 1.0),
    border_width=2.0f0, padding=14.0f0, corner_radius=8.0f0
)
const CUSTOM_PRESSED_STYLE = ContainerStyle(
    background_color=Vec4f(0.8, 0.3, 0.3, 1.0),
    border_color=Vec4f(0.7, 0.2, 0.2, 1.0),
    border_width=3.0f0, padding=14.0f0, corner_radius=8.0f0
)

const BTN_TEXT_STYLE    = TextStyle(color=DARK_TEXT, size_points=14)
const CUSTOM_TEXT_STYLE = TextStyle(color=Vec4f(1.0, 1.0, 1.0, 1.0), size_points=14)
const TITLE_TEXT_STYLE  = TextStyle(color=DARK_TEXT, size_points=16)
const INFO_TEXT_STYLE   = TextStyle(color=Vec4f(0.7, 0.7, 0.7, 1.0), size_points=12)
const HINT_TEXT_STYLE   = TextStyle(color=Vec4f(0.6, 0.6, 0.6, 1.0), size_points=10)

const INFO_BOX_STYLE = ContainerStyle(
    background_color=Vec4f(0.12, 0.12, 0.15, 1.0), padding=8.0f0,
    corner_radius=4.0f0, border_color=Vec4f(0.2, 0.2, 0.2, 1.0), border_width=1.0f0
)

# Per-button interaction states
btn1_state = Ref(InteractionState())
btn2_state = Ref(InteractionState())
btn3_state = Ref(InteractionState())
btn4_state = Ref(InteractionState())
btn5_state = Ref(InteractionState())

function MyApp()
    Card("Hover & Press Demo",
        IntrinsicColumn([
            # Hover + press feedback
            TextButton("Hover + Press",
                container_style=DEFAULT_BTN_STYLE,
                hover_style=DEFAULT_HOVER_STYLE,
                pressed_style=DEFAULT_PRESSED_STYLE,
                text_style=BTN_TEXT_STYLE,
                interaction_state=btn1_state[],
                on_interaction_state_change=(s) -> btn1_state[] = s
            ),

            # Hover feedback only
            TextButton("Hover Only",
                container_style=DEFAULT_BTN_STYLE,
                hover_style=DEFAULT_HOVER_STYLE,
                text_style=BTN_TEXT_STYLE,
                interaction_state=btn2_state[],
                on_interaction_state_change=(s) -> btn2_state[] = s
            ),

            # Press feedback only
            TextButton("Press Only",
                container_style=DEFAULT_BTN_STYLE,
                pressed_style=DEFAULT_PRESSED_STYLE,
                text_style=BTN_TEXT_STYLE,
                interaction_state=btn3_state[],
                on_interaction_state_change=(s) -> btn3_state[] = s
            ),

            # No interaction styling
            TextButton("No Effects", container_style=DEFAULT_BTN_STYLE, text_style=BTN_TEXT_STYLE),

            # Custom per-state colors (surface → blue → red)
            TextButton("Custom Blue/Red",
                container_style=CUSTOM_BTN_STYLE,
                hover_style=CUSTOM_HOVER_STYLE,
                pressed_style=CUSTOM_PRESSED_STYLE,
                text_style=CUSTOM_TEXT_STYLE,
                interaction_state=btn4_state[],
                on_interaction_state_change=(s) -> btn4_state[] = s
            ),

            # on_click and on_mouse_down callbacks
            TextButton("Click & Mouse-Down Callbacks",
                container_style=DEFAULT_BTN_STYLE,
                hover_style=DEFAULT_HOVER_STYLE,
                pressed_style=DEFAULT_PRESSED_STYLE,
                text_style=BTN_TEXT_STYLE,
                interaction_state=btn5_state[],
                on_interaction_state_change=(s) -> btn5_state[] = s,
                on_click=() -> println("Clicked!"),
                on_mouse_down=() -> println("Mouse down!")
            ),

            Fugl.Text("Check the console for callback output", style=INFO_TEXT_STYLE),
            Container(
                Text("Pressed style activates immediately; hover activates on mouse-over",
                    style=HINT_TEXT_STYLE),
                style=INFO_BOX_STYLE
            ),
        ], spacing=12.0f0, padding=20.0f0),
        style=ContainerStyle(background_color=DARK_BG, padding=0.0f0),
        title_style=TITLE_TEXT_STYLE
    )
end

screenshot(MyApp, "hover_press_demo.png", 650, 500);
nothing #hide
```

![Hover and Press Demo](hover_press_demo.png)
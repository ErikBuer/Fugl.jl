# TextButton

## Basic TextButton (No Interaction Styling)

``` @example TextButtonExample
using Fugl

function MyApp()
    Container(
        TextButton("Basic Button",
            on_click=() -> println("Basic button clicked"),
            text_style = TextStyle(size_px=16),
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
    size_px = 16
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

## Dark Theme with Multiple Interaction States

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
    size_px = 14
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

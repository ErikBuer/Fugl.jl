# Sliders

The HorizontalSlider component provides interactive value selection with support for state management, visual feedback, and discrete step snapping.

## Slider with State Management and Steps

``` @example SliderExample
using Fugl
using Fugl: Text

function slider_demo()
    # Slider states with different configurations
    continuous_state = Ref(SliderState(0.5, 0.0, 1.0))
    discrete_state = Ref(SliderState(50, 0, 100))
    stepped_state = Ref(SliderState(0.2, 0.0, 1.0))
    
    # Dark theme styles
    dark_container_style = ContainerStyle(
        background_color=Vec4f(0.08, 0.08, 0.08, 1.0),
        border_color=Vec4f(0.3, 0.3, 0.3, 1.0),
        border_width=1.0f0,
        corner_radius=8.0f0,
        padding=20.0f0
    )
    
    dark_card_style = ContainerStyle(
        background_color=Vec4f(0.15, 0.15, 0.15, 1.0),
        border_color=Vec4f(0.4, 0.4, 0.4, 1.0),
        border_width=1.0f0,
        corner_radius=8.0f0
    )
    
    dark_text_style = TextStyle(
        color=Vec4f(0.9, 0.9, 0.9, 1.0),
        size_px=16
    )
    
    dark_card_title_style = TextStyle(
        color=Vec4f(0.9, 0.9, 0.9, 1.0),
        size_px=16
    )
    
    dark_slider_style = SliderStyle(
        background_color=Vec4f(0.2, 0.2, 0.2, 1.0),
        handle_color=Vec4f(0.6, 0.7, 0.8, 1.0),
        border_color=Vec4f(0.5, 0.5, 0.5, 1.0),
        border_width=1.0f0,
        radius=4.0f0
    )
    
    Container(
        IntrinsicColumn([
            # Continuous slider
            Card(
                "Continuous Slider",
                Column([
                    HorizontalSlider(
                        continuous_state[];
                        style=dark_slider_style,
                        on_state_change=(new_state) -> continuous_state[] = new_state,
                        on_change=(new_value) -> println("Continuous: ", new_value)
                    ),
                    Text("Value: $(round(continuous_state[].value, digits=3))", style=dark_text_style)
                ]),
                style=dark_card_style,
                title_style=dark_card_title_style
            ),
            
            # Discrete steps slider
            Card(
                "Discrete Steps (10 steps)",
                Column([
                    HorizontalSlider(
                        discrete_state[];
                        steps=11,  # 11 positions = 10 intervals
                        style=dark_slider_style,
                        on_state_change=(new_state) -> discrete_state[] = new_state,
                        on_change=(new_value) -> println("Discrete: ", new_value)
                    ),
                    Text("Value: $(Int(discrete_state[].value))", style=dark_text_style)
                ]),
                style=dark_card_style,
                title_style=dark_card_title_style
            ),
            
            # Fixed step size slider
            Card(
                "Fixed Step Size (0.1)",
                Column([
                    HorizontalSlider(
                        stepped_state[];
                        steps=0.1,  # Step by 0.1
                        style=dark_slider_style,
                        on_state_change=(new_state) -> stepped_state[] = new_state,
                        on_change=(new_value) -> println("Stepped: ", new_value)
                    ),
                    Text("Value: $(stepped_state[].value)", style=dark_text_style)
                ]),
                style=dark_card_style,
                title_style=dark_card_title_style
            )
        ], spacing=20),
        style=dark_container_style
    )
end

screenshot(slider_demo, "slider.png", 812, 400);
nothing #hide
```

![Slider Example](slider.png)

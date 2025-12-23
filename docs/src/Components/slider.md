# HorizontalSlider

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
        radius=4.0f0,
        fill_color=Vec4f(0.4, 0.6, 0.8, 0.6),
        marker_color=Vec4f(0.6, 0.6, 0.6, 0.8)
    )
    
    # Focused style - lighter colors for hover state
    focused_slider_style = SliderStyle(
        background_color=Vec4f(0.25, 0.25, 0.3, 1.0),
        handle_color=Vec4f(0.7, 0.8, 0.9, 1.0),
        border_color=Vec4f(0.6, 0.6, 0.7, 1.0),
        border_width=1.5f0,
        radius=4.0f0,
        fill_color=Vec4f(0.5, 0.7, 0.9, 0.8),
        marker_color=Vec4f(0.8, 0.8, 0.8, 1.0)
    )
    
    # Dragging style - blue accent for active dragging
    dragging_slider_style = SliderStyle(
        background_color=Vec4f(0.2, 0.25, 0.35, 1.0),
        handle_color=Vec4f(0.3, 0.6, 1.0, 1.0),
        border_color=Vec4f(0.4, 0.6, 0.8, 1.0),
        border_width=2.0f0,
        radius=4.0f0,
        fill_color=Vec4f(0.3, 0.6, 1.0, 0.8),
        marker_color=Vec4f(0.9, 0.9, 1.0, 1.0)
    )
    
    Container(
        IntrinsicColumn([
            # Continuous slider with interaction styles
            Card(
                "Interactive Slider with State Styles",
                Column([
                    HorizontalSlider(
                        continuous_state[];
                        style=dark_slider_style,
                        focused_style=focused_slider_style,
                        dragging_style=dragging_slider_style,
                        on_state_change=(new_state) -> continuous_state[] = new_state,
                        on_change=(new_value) -> println("Continuous: ", new_value)
                    ),
                    Text("Value: $(round(continuous_state[].value, digits=3))", style=dark_text_style),
                    Text("Hover and drag to see different styles!", style=TextStyle(color=Vec4f(0.7, 0.7, 0.7, 1.0), size_px=12))
                ]),
                style=dark_card_style,
                title_style=dark_card_title_style
            ),
            
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

screenshot(slider_demo, "slider.png", 812, 500);
nothing #hide
```

![Slider Example](slider.png)

## RGB Color Picker with Hidden Step Markers

``` @example SliderRGB
using Fugl
using Fugl: Text

# RGB color states
rgb_r_state = Ref(SliderState(Int, 200, 0, 255))
rgb_g_state = Ref(SliderState(Int, 50, 0, 255))
rgb_b_state = Ref(SliderState(Int, 150, 0, 255))

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

# Color-themed slider styles with NO step markers (marker_color=nothing)
red_slider_style = SliderStyle(
    background_color=Vec4f(0.25, 0.15, 0.15, 1.0),
    handle_color=Vec4f(1.0, 0.4, 0.4, 1.0),
    border_color=Vec4f(0.6, 0.3, 0.3, 1.0),
    border_width=1.0f0,
    radius=4.0f0,
    fill_color=Vec4f(0.8, 0.2, 0.2, 0.7),
    marker_color=nothing,  # Hidden step markers
    track_height=18.0f0,
    handle_width=14.0f0
)

green_slider_style = SliderStyle(
    background_color=Vec4f(0.15, 0.25, 0.15, 1.0),
    handle_color=Vec4f(0.4, 1.0, 0.4, 1.0),
    border_color=Vec4f(0.3, 0.6, 0.3, 1.0),
    border_width=1.0f0,
    radius=4.0f0,
    fill_color=Vec4f(0.2, 0.8, 0.2, 0.7),
    marker_color=nothing,  # Hidden step markers
    track_height=18.0f0,
    handle_width=14.0f0
)

blue_slider_style = SliderStyle(
    background_color=Vec4f(0.15, 0.15, 0.25, 1.0),
    handle_color=Vec4f(0.4, 0.4, 1.0, 1.0),
    border_color=Vec4f(0.3, 0.3, 0.6, 1.0),
    border_width=1.0f0,
    radius=4.0f0,
    fill_color=Vec4f(0.2, 0.2, 0.8, 0.7),
    marker_color=nothing,  # Hidden step markers
    track_height=18.0f0,
    handle_width=14.0f0
)

function rgb_color_picker_demo()
    Card(
        "RGB Color Picker",
        IntrinsicColumn([
            # Red slider
            Row([
                Container(
                    Text("R:", style=TextStyle(color=Vec4f(1.0, 0.5, 0.5, 1.0), size_px=16)),
                    style=ContainerStyle(padding=5.0f0, background_color=Vec4f(0.0, 0.0, 0.0, 0.0))
                ),
                HorizontalSlider(
                    rgb_r_state[];
                    steps=256,  # 0-255 steps, but markers are hidden
                    style=red_slider_style,
                    on_state_change=(new_state) -> rgb_r_state[] = new_state
                ),
                Container(
                    Text("$(rgb_r_state[].value)", style=TextStyle(size_px=14, color=Vec4f(0.8, 0.8, 0.8, 1.0))),
                    style=ContainerStyle(padding=5.0f0, background_color=Vec4f(0.0, 0.0, 0.0, 0.0))
                )
            ]),
            
            # Green slider
            Row([
                Container(
                    Text("G:", style=TextStyle(color=Vec4f(0.5, 1.0, 0.5, 1.0), size_px=16)),
                    style=ContainerStyle(padding=5.0f0, background_color=Vec4f(0.0, 0.0, 0.0, 0.0))
                ),
                HorizontalSlider(
                    rgb_g_state[];
                    steps=256,  # 0-255 steps, but markers are hidden
                    style=green_slider_style,
                    on_state_change=(new_state) -> rgb_g_state[] = new_state
                ),
                Container(
                    Text("$(rgb_g_state[].value)", style=TextStyle(size_px=14, color=Vec4f(0.8, 0.8, 0.8, 1.0))),
                    style=ContainerStyle(padding=5.0f0, background_color=Vec4f(0.0, 0.0, 0.0, 0.0))
                )
            ]),
            
            # Blue slider
            Row([
                Container(
                    Text("B:", style=TextStyle(color=Vec4f(0.5, 0.5, 1.0, 1.0), size_px=16)),
                    style=ContainerStyle(padding=5.0f0, background_color=Vec4f(0.0, 0.0, 0.0, 0.0))
                ),
                HorizontalSlider(
                    rgb_b_state[];
                    steps=256,  # 0-255 steps, but markers are hidden
                    style=blue_slider_style,
                    on_state_change=(new_state) -> rgb_b_state[] = new_state
                ),
                Container(
                    Text("$(rgb_b_state[].value)", style=TextStyle(size_px=14, color=Vec4f(0.8, 0.8, 0.8, 1.0))),
                    style=ContainerStyle(padding=5.0f0, background_color=Vec4f(0.0, 0.0, 0.0, 0.0))
                )
            ]),
            
            # Color preview
            FixedHeight(
                Container(
                    Text(
                        "RGB($(rgb_r_state[].value), $(rgb_g_state[].value), $(rgb_b_state[].value))",
                        style=TextStyle(color=Vec4f(1.0, 1.0, 1.0, 1.0), size_px=16)
                    ),
                    style=ContainerStyle(
                        background_color=Vec4f(
                            rgb_r_state[].value / 255.0f0,
                            rgb_g_state[].value / 255.0f0,
                            rgb_b_state[].value / 255.0f0,
                            1.0
                        ),
                        border_color=Vec4f(0.6, 0.6, 0.6, 1.0),
                        border_width=2.0f0,
                        corner_radius=5.0f0,
                        padding=15.0f0
                    )
                ),
                50.0f0
            ),
            
            Text(
                "Note: Step markers are hidden (marker_color=nothing) for clean appearance", 
                style=TextStyle(color=Vec4f(0.6, 0.6, 0.6, 1.0), size_px=12)
            )
        ], spacing=15),
        style=dark_card_style,
        title_style=TextStyle(color=Vec4f(1.0, 1.0, 1.0, 1.0), size_px=16)
    )
end

screenshot(rgb_color_picker_demo, "slider_rgb.png", 812, 400);
nothing #hide
```

![RGB Color Picker](slider_rgb.png)



## Slider Sizing and Styling

``` @example SliderSizes
using Fugl
using Fugl: Text

# States for different sized sliders
small_state = Ref(SliderState(0.3, 0.0, 1.0))
default_state = Ref(SliderState(0.5, 0.0, 1.0))
large_state = Ref(SliderState(0.7, 0.0, 1.0))
custom_state = Ref(SliderState(0.4, 0.0, 1.0))

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
    size_px=14
)

dark_card_title_style = TextStyle(
    color=Vec4f(0.9, 0.9, 0.9, 1.0),
    size_px=16
)

# Small slider style
small_slider_style = SliderStyle(
    background_color=Vec4f(0.2, 0.2, 0.2, 1.0),
    handle_color=Vec4f(0.6, 0.7, 0.8, 1.0),
    border_color=Vec4f(0.5, 0.5, 0.5, 1.0),
    border_width=1.0f0,
    radius=2.0f0,
    fill_color=Vec4f(0.4, 0.6, 0.8, 0.6),
    marker_color=Vec4f(0.6, 0.6, 0.6, 0.8),
    track_height=12.0f0,     # Smaller track
    handle_width=8.0f0,      # Smaller handle
    handle_height_offset=2.0f0,
    min_width=40.0f0
)

# Default slider style
default_slider_style = SliderStyle(
    background_color=Vec4f(0.2, 0.2, 0.2, 1.0),
    handle_color=Vec4f(0.6, 0.7, 0.8, 1.0),
    border_color=Vec4f(0.5, 0.5, 0.5, 1.0),
    border_width=1.0f0,
    radius=4.0f0,
    fill_color=Vec4f(0.4, 0.6, 0.8, 0.6),
    marker_color=Vec4f(0.6, 0.6, 0.6, 0.8)
    # Uses default sizing: track_height=20.0f0, handle_width=12.0f0, etc.
)

# Large slider style
large_slider_style = SliderStyle(
    background_color=Vec4f(0.2, 0.2, 0.2, 1.0),
    handle_color=Vec4f(0.6, 0.7, 0.8, 1.0),
    border_color=Vec4f(0.5, 0.5, 0.5, 1.0),
    border_width=2.0f0,
    radius=6.0f0,
    fill_color=Vec4f(0.4, 0.6, 0.8, 0.6),
    marker_color=Vec4f(0.6, 0.6, 0.6, 0.8),
    track_height=32.0f0,     # Larger track
    handle_width=18.0f0,     # Larger handle
    handle_height_offset=6.0f0,
    min_width=80.0f0
)

# Custom styled slider
custom_slider_style = SliderStyle(
    background_color=Vec4f(0.15, 0.25, 0.15, 1.0),
    handle_color=Vec4f(0.4, 1.0, 0.4, 1.0),
    border_color=Vec4f(0.3, 0.6, 0.3, 1.0),
    border_width=1.5f0,
    radius=8.0f0,
    fill_color=Vec4f(0.2, 0.8, 0.2, 0.7),
    marker_color=Vec4f(0.5, 0.9, 0.5, 0.9),
    track_height=24.0f0,
    handle_width=14.0f0,
    handle_height_offset=8.0f0,
    min_width=60.0f0
)


function slider_sizing_demo()  
    Container(
        IntrinsicColumn([
            Card(
                "Small Slider (12px height)",
                Column([
                    HorizontalSlider(
                        small_state[];
                        steps=5,
                        style=small_slider_style,
                        on_state_change=(new_state) -> small_state[] = new_state
                    ),
                    Text("Value: $(round(small_state[].value, digits=2))", style=dark_text_style)
                ]),
                style=dark_card_style,
                title_style=dark_card_title_style
            ),
            
            Card(
                "Default Slider (20px height)",
                Column([
                    HorizontalSlider(
                        default_state[];
                        steps=10,
                        style=default_slider_style,
                        on_state_change=(new_state) -> default_state[] = new_state
                    ),
                    Text("Value: $(round(default_state[].value, digits=2))", style=dark_text_style)
                ]),
                style=dark_card_style,
                title_style=dark_card_title_style
            ),
            
            Card(
                "Large Slider (32px height)",
                Column([
                    HorizontalSlider(
                        large_state[];
                        steps=8,
                        style=large_slider_style,
                        on_state_change=(new_state) -> large_state[] = new_state
                    ),
                    Text("Value: $(round(large_state[].value, digits=2))", style=dark_text_style)
                ]),
                style=dark_card_style,
                title_style=dark_card_title_style
            ),
            
            Card(
                "Custom Green Slider (24px height)",
                Column([
                    HorizontalSlider(
                        custom_state[];
                        steps=6,
                        style=custom_slider_style,
                        on_state_change=(new_state) -> custom_state[] = new_state
                    ),
                    Text("Value: $(round(custom_state[].value, digits=2))", style=dark_text_style)
                ]),
                style=dark_card_style,
                title_style=dark_card_title_style
            )
        ], spacing=20),
        style=dark_container_style
    )
end

screenshot(slider_sizing_demo, "slider_sizes.png", 812, 480);
nothing #hide
```

![Slider Sizing Examples](slider_sizes.png)
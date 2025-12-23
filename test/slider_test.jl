using Fugl

function main()
    # Test states for different slider configurations
    basic_slider_state = Ref(SliderState(0.5, 0.0, 1.0))
    continuous_state = Ref(SliderState(0.3, 0.0, 1.0))
    discrete_state = Ref(SliderState(5, 0, 10))
    stepped_state = Ref(SliderState(0.5, 0.0, 2.0))
    rgb_r_state = Ref(SliderState(Int, 200, 0, 255))
    rgb_g_state = Ref(SliderState(Int, 50, 0, 255))
    rgb_b_state = Ref(SliderState(Int, 150, 0, 255))

    function MyApp()
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

        # Dark theme slider styles
        default_dark_slider = SliderStyle(
            background_color=Vec4f(0.2, 0.2, 0.2, 1.0),
            handle_color=Vec4f(0.6, 0.7, 0.8, 1.0),
            border_color=Vec4f(0.5, 0.5, 0.5, 1.0),
            border_width=1.0f0,
            radius=4.0f0
        )

        red_slider_style = SliderStyle(
            background_color=Vec4f(0.25, 0.15, 0.15, 1.0),
            handle_color=Vec4f(1.0, 0.4, 0.4, 1.0),
            border_color=Vec4f(0.6, 0.3, 0.3, 1.0),
            border_width=1.0f0,
            radius=4.0f0
        )

        green_slider_style = SliderStyle(
            background_color=Vec4f(0.15, 0.25, 0.15, 1.0),
            handle_color=Vec4f(0.4, 1.0, 0.4, 1.0),
            border_color=Vec4f(0.3, 0.6, 0.3, 1.0),
            border_width=1.0f0,
            radius=4.0f0
        )

        blue_slider_style = SliderStyle(
            background_color=Vec4f(0.15, 0.15, 0.25, 1.0),
            handle_color=Vec4f(0.4, 0.4, 1.0, 1.0),
            border_color=Vec4f(0.3, 0.3, 0.6, 1.0),
            border_width=1.0f0,
            radius=4.0f0
        )

        Card(
            "Slider Test",
            Column([
                    # Basic slider (now using SliderState)
                    Card(
                        "Basic Slider with State Management",
                        IntrinsicColumn([
                            HorizontalSlider(
                                basic_slider_state[];
                                style=default_dark_slider,
                                on_state_change=(new_state) -> begin
                                    basic_slider_state[] = new_state
                                    focused = new_state.interaction_state.is_focused
                                    println("Basic slider: value=$(new_state.value), focused=$(focused)")
                                end,
                                on_change=(new_value) -> println("Basic value: ", new_value)
                            ),
                            Fugl.Text("Value: $(round(basic_slider_state[].value, digits=3)) | Focused: $(basic_slider_state[].interaction_state.is_focused)", style=dark_text_style)
                        ]),
                        style=dark_card_style,
                        title_style=dark_card_title_style
                    ),

                    # Continuous slider with state
                    Card(
                        "Continuous Slider with State",
                        IntrinsicColumn([
                            HorizontalSlider(
                                continuous_state[];
                                style=default_dark_slider,
                                on_state_change=(new_state) -> begin
                                    continuous_state[] = new_state
                                    focused = new_state.interaction_state.is_focused
                                    println("Continuous state: value=$(new_state.value), focused=$(focused), dragging=$(new_state.is_dragging)")
                                end,
                                on_change=(new_value) -> println("Continuous value: ", new_value)
                            ),
                            Fugl.Text("Value: $(round(continuous_state[].value, digits=3)) | Focused: $(continuous_state[].interaction_state.is_focused) | Dragging: $(continuous_state[].is_dragging)", style=dark_text_style)
                        ]),
                        style=dark_card_style,
                        title_style=dark_card_title_style
                    ),

                    # Discrete steps slider
                    Card(
                        "Discrete Steps Slider (11 positions)",
                        IntrinsicColumn([
                            HorizontalSlider(
                                discrete_state[];
                                steps=11,  # 0-10 in steps of 1
                                style=default_dark_slider,
                                on_state_change=(new_state) -> begin
                                    discrete_state[] = new_state
                                    println("Discrete state: ", new_state.value)
                                end,
                                on_change=(new_value) -> println("Discrete value: ", new_value)
                            ),
                            Fugl.Text("Value: $(Int(discrete_state[].value)) / 10", style=dark_text_style)
                        ]),
                        style=dark_card_style,
                        title_style=dark_card_title_style
                    ),

                    # Fixed step size slider
                    Card(
                        "Fixed Step Size Slider (step=0.25)",
                        Column([
                            HorizontalSlider(
                                stepped_state[];
                                steps=0.25,
                                style=default_dark_slider,
                                on_state_change=(new_state) -> begin
                                    stepped_state[] = new_state
                                    println("Stepped state: ", new_state.value)
                                end,
                                on_change=(new_value) -> println("Stepped value: ", new_value)
                            ),
                            Fugl.Text("Value: $(stepped_state[].value)", style=dark_text_style)
                        ]),
                        style=dark_card_style,
                        title_style=dark_card_title_style
                    ),

                    # Color picker example
                    Card(
                        "RGB Color Picker Test",
                        Column([
                            # Red slider
                            Row([
                                Container(
                                    Fugl.Text("R:", style=TextStyle(color=Vec4f(1.0, 0.5, 0.5, 1.0), size_px=16)),
                                    style=ContainerStyle(padding=5.0f0, background_color=Vec4f(0.0, 0.0, 0.0, 0.0))
                                ),
                                HorizontalSlider(
                                    rgb_r_state[];
                                    steps=256,
                                    style=red_slider_style,
                                    on_state_change=(new_state) -> begin
                                        rgb_r_state[] = new_state
                                        println("Red: ", new_state.value)
                                    end
                                ),
                                Container(
                                    Fugl.Text("$(rgb_r_state[].value)", style=TextStyle(size_px=14, color=Vec4f(0.8, 0.8, 0.8, 1.0))),
                                    style=ContainerStyle(padding=5.0f0, background_color=Vec4f(0.0, 0.0, 0.0, 0.0))
                                )
                            ]),

                            # Green slider
                            Row([
                                Container(
                                    Fugl.Text("G:", style=TextStyle(color=Vec4f(0.5, 1.0, 0.5, 1.0), size_px=16)),
                                    style=ContainerStyle(padding=5.0f0, background_color=Vec4f(0.0, 0.0, 0.0, 0.0))
                                ),
                                HorizontalSlider(
                                    rgb_g_state[];
                                    steps=256,
                                    style=green_slider_style,
                                    on_state_change=(new_state) -> begin
                                        rgb_g_state[] = new_state
                                        println("Green: ", new_state.value)
                                    end
                                ),
                                Container(
                                    Fugl.Text("$(rgb_g_state[].value)", style=TextStyle(size_px=14, color=Vec4f(0.8, 0.8, 0.8, 1.0))),
                                    style=ContainerStyle(padding=5.0f0, background_color=Vec4f(0.0, 0.0, 0.0, 0.0))
                                )
                            ]),

                            # Blue slider
                            Row([
                                Container(
                                    Fugl.Text("B:", style=TextStyle(color=Vec4f(0.5, 0.5, 1.0, 1.0), size_px=16)),
                                    style=ContainerStyle(padding=5.0f0, background_color=Vec4f(0.0, 0.0, 0.0, 0.0))
                                ),
                                HorizontalSlider(
                                    rgb_b_state[];
                                    steps=256,
                                    style=blue_slider_style,
                                    on_state_change=(new_state) -> begin
                                        rgb_b_state[] = new_state
                                        println("Blue: ", new_state.value)
                                    end
                                ),
                                Container(
                                    Fugl.Text("$(rgb_b_state[].value)", style=TextStyle(size_px=14, color=Vec4f(0.8, 0.8, 0.8, 1.0))),
                                    style=ContainerStyle(padding=5.0f0, background_color=Vec4f(0.0, 0.0, 0.0, 0.0))
                                )
                            ]),

                            # Color preview
                            Container(
                                Fugl.Text("Color Preview",
                                    style=TextStyle(
                                        color=Vec4f(1.0, 1.0, 1.0, 1.0),
                                        size_px=16
                                    )
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

                            # Hex value display
                            Fugl.Text("Hex: #$(uppercase(string(rgb_r_state[].value, base=16, pad=2)))" *
                                      "$(uppercase(string(rgb_g_state[].value, base=16, pad=2)))" *
                                      "$(uppercase(string(rgb_b_state[].value, base=16, pad=2)))",
                                style=TextStyle(size_px=14, color=Vec4f(0.7, 0.7, 0.7, 1.0)))
                        ]),
                        style=dark_card_style,
                        title_style=dark_card_title_style
                    )
                ], spacing=5, padding=5),
            style=dark_card_style,
            title_style=dark_card_title_style
        )
    end

    # Run the GUI
    Fugl.run(MyApp, title="Slider Test", window_width_px=800, window_height_px=900, fps_overlay=true)
end

main()
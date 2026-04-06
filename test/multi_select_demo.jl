using Fugl

function main()
    fruits = ["Apple", "Banana", "Cherry", "Date", "Elderberry", "Fig", "Grape"]
    toppings = ["Cheese", "Tomato", "Pepperoni", "Mushrooms", "Olives", "Jalapeños"]

    fruit_state = Ref(MultiSelectState(length(fruits)))
    topping_state = Ref(MultiSelectState(length(toppings); selected_indices=Set([1, 3])))

    scroll_state = Ref(VerticalScrollState())
    long_options = ["Option $i" for i in 1:20]
    long_state = Ref(MultiSelectState(length(long_options)))

    # Dark theme colors
    dark_card_style = ContainerStyle(
        background_color=Vec4{Float32}(0.15f0, 0.15f0, 0.18f0, 1.0f0),
        border_color=Vec4{Float32}(0.25f0, 0.25f0, 0.30f0, 1.0f0),
        border_width=1.5f0,
        padding=12.0f0,
        corner_radius=6.0f0,
    )
    dark_title_style = TextStyle(
        size_points=16,
        color=Vec4{Float32}(0.9f0, 0.9f0, 0.95f0, 1.0f0),
    )
    dark_text_style = TextStyle(
        size_points=14,
        color=Vec4{Float32}(0.85f0, 0.85f0, 0.90f0, 1.0f0),
    )

    # Blue selection style (default list)
    blue_list_style = MultiSelectListStyle(
        item_height=28.0f0,
        text_style=dark_text_style,
        item_background=Vec4{Float32}(0.10f0, 0.10f0, 0.13f0, 1.0f0),
        item_hover_color=Vec4{Float32}(0.20f0, 0.22f0, 0.30f0, 1.0f0),
        item_selected_color=Vec4{Float32}(0.22f0, 0.45f0, 0.80f0, 1.0f0),
        item_selected_hover_color=Vec4{Float32}(0.28f0, 0.52f0, 0.88f0, 1.0f0),
        border_color=Vec4{Float32}(0.25f0, 0.25f0, 0.30f0, 1.0f0),
    )

    # Green selection style (toppings list)
    green_list_style = MultiSelectListStyle(
        item_height=30.0f0,
        text_style=dark_text_style,
        item_background=Vec4{Float32}(0.10f0, 0.10f0, 0.13f0, 1.0f0),
        item_hover_color=Vec4{Float32}(0.12f0, 0.22f0, 0.14f0, 1.0f0),
        item_selected_color=Vec4{Float32}(0.10f0, 0.50f0, 0.22f0, 1.0f0),
        item_selected_hover_color=Vec4{Float32}(0.14f0, 0.58f0, 0.28f0, 1.0f0),
        border_color=Vec4{Float32}(0.25f0, 0.25f0, 0.30f0, 1.0f0),
    )

    function MyApp()
        Container(
            IntrinsicColumn([
                    Card("Fruit selection (MultiSelectList):",
                        MultiSelectList(
                            fruits,
                            fruit_state[];
                            style=blue_list_style,
                            on_state_change=(new_state) -> fruit_state[] = new_state,
                            on_change=(selected) -> println("Fruits selected: ", sort(collect(selected))),
                        );
                        style=dark_card_style,
                        title_style=dark_title_style,
                    ),
                    Card("Pizza toppings (pre-selected):",
                        MultiSelectList(
                            toppings,
                            topping_state[];
                            style=green_list_style,
                            on_state_change=(new_state) -> topping_state[] = new_state,
                            on_change=(selected) -> println("Toppings selected: ", sort(collect(selected))),
                        );
                        style=dark_card_style,
                        title_style=dark_title_style,
                    ),
                    Card("Long list in a scroll area:",
                        FixedHeight(
                            VerticalScrollArea(
                                MultiSelectList(
                                    long_options,
                                    long_state[];
                                    style=blue_list_style,
                                    on_state_change=(new_state) -> long_state[] = new_state,
                                    on_change=(selected) -> println("Long list selected: ", sort(collect(selected))),
                                );
                                scroll_state=scroll_state[],
                                on_scroll_change=(new_state) -> scroll_state[] = new_state,
                            ),
                            150.0f0
                        );
                        style=dark_card_style,
                        title_style=dark_title_style,
                    ),
                ],
                spacing=0
            );
            style=ContainerStyle(
                background_color=Vec4{Float32}(0.08f0, 0.08f0, 0.10f0, 1.0f0),
                border_width=0.0f0,
                padding=0.0f0,
                corner_radius=0.0f0,
            )
        )
    end

    Fugl.run(MyApp, title="MultiSelectList Demo", window_width_points=480, window_height_points=700, fps_overlay=true)
end

main()

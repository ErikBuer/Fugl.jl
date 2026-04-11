using Fugl

function main()
    # Create a long list to test scrolling
    options = ["Option $i" for i in 1:15]

    # State for the multi-select list
    list_state = Ref(MultiSelectState(length(options)))

    # Style with limited visible items
    list_style = MultiSelectListStyle(
        max_visible_items=8,
        item_height=30.0f0,
        padding=10.0f0,
        corner_radius=5.0f0,
        item_corner_radius=6.0f0,  # Rounded corners for selection highlighting
        border_width=1.0f0,
        border_color=Vec4{Float32}(0.3f0, 0.3f0, 0.3f0, 1.0f0),
        item_background=Vec4{Float32}(0.2f0, 0.2f0, 0.2f0, 1.0f0),
        item_hover_color=Vec4{Float32}(0.3f0, 0.3f0, 0.3f0, 1.0f0),
        item_selected_color=Vec4{Float32}(0.1f0, 0.4f0, 0.8f0, 1.0f0),
        item_selected_hover_color=Vec4{Float32}(0.2f0, 0.5f0, 0.9f0, 1.0f0),
    )

    function MyApp()
        Container(
            IntrinsicColumn(
                Fugl.Text("Scrollable MultiSelect Demo"; style=TextStyle(size_points=20, color=Vec4(1.0f0, 1.0f0, 1.0f0, 1.0f0))),
                Fugl.Text("Use scroll wheel to navigate. Only 8 items visible at once."; style=TextStyle(size_points=14)),
                FixedSize(
                    MultiSelectList(
                        options,
                        list_state[];
                        style=list_style,
                        on_state_change=(new_state) -> list_state[] = new_state,
                        on_change=(selected) -> println("Selected: ", [options[i] for i in selected]),
                    ),
                    400.0f0, 300.0f0
                ),
                Fugl.Text("Selected items: " * join([options[i] for i in list_state[].selected_indices], ", "); style=TextStyle(size_points=12, color=Vec4(0.8f0, 0.8f0, 0.8f0, 1.0f0))), ;
                spacing=20.0f0);
            style=ContainerStyle(
                background_color=Vec4(0.15f0, 0.15f0, 0.15f0, 1.0f0),
                padding=20.0f0
            )
        )
    end

    Fugl.run(MyApp; title="MultiSelect Scroll Demo", window_width_points=600, window_height_points=500)
end

main()

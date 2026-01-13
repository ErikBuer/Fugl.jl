using Fugl
using Fugl: SplitContainerState

function main()
    # State for the scroll area
    scroll_state = Ref(VerticalScrollState())

    # State for the split container
    split_state = Ref(SplitContainerState(split_position=0.7f0))

    # State for dropdowns
    dropdown1_state = Ref(DropdownState(["Option 1", "Option 2", "Option 3", "Option 4", "Option 5"]))
    dropdown2_state = Ref(DropdownState(["Red", "Green", "Blue", "Yellow", "Purple", "Orange", "Pink", "Cyan"]))
    dropdown3_state = Ref(DropdownState(["Small", "Medium", "Large", "Extra Large"]))

    # Button click counters
    button_clicks = Ref(Dict{String,Int}())

    # Selected values from dropdowns
    selected_values = Ref(Dict{String,String}(
        "dropdown1" => "Option 1",
        "dropdown2" => "Red",
        "dropdown3" => "Small"
    ))

    # Button interaction states
    button_states = Ref(Dict{String,InteractionState}(
        "top" => InteractionState(),
        "middle1" => InteractionState(),
        "middle2" => InteractionState(),
        "bottom1" => InteractionState(),
        "bottom2" => InteractionState(),
        "reset" => InteractionState()
    ))

    function ScrollDropdownDemo()
        # Initialize button clicks if empty
        if isempty(button_clicks[])
            button_clicks[] = Dict(
                "top" => 0,
                "middle1" => 0,
                "middle2" => 0,
                "bottom1" => 0,
                "bottom2" => 0,
                "reset" => 0
            )
        end

        # Create content items for the scroll area
        content_items = [
            # Top section
            Container(
                Column([
                        Fugl.Text("Scroll Area with Dropdowns and Buttons",
                            style=TextStyle(size_px=18, color=Vec4f(0.9, 0.9, 0.9, 1.0))),
                        Fugl.Text("Test that dropdowns overlay properly and don't interfere with scrolling",
                            style=TextStyle(size_px=12, color=Vec4f(0.7, 0.7, 0.7, 1.0))),

                        # First dropdown
                        Row([
                                Fugl.Text("Category:", style=TextStyle(size_px=14, color=Vec4f(0.85, 0.85, 0.85, 1.0))),
                                Dropdown(
                                    dropdown1_state[],
                                    on_state_change=(new_state) -> dropdown1_state[] = new_state,
                                    on_select=(value, index) -> begin
                                        selected_values[] = merge(selected_values[], Dict("dropdown1" => value))
                                        println("Selected category: $value")
                                    end
                                )
                            ], spacing=10.0f0), TextButton(
                            "Top Button (Clicks: $(button_clicks[]["top"]))",
                            on_click=() -> begin
                                button_clicks[] = merge(button_clicks[], Dict("top" => button_clicks[]["top"] + 1))
                                println("Top button clicked! Count: $(button_clicks[]["top"])")
                            end,
                            container_style=ContainerStyle(
                                background_color=Vec4f(0.3, 0.5, 0.7, 1.0),
                                padding=8.0f0,
                                corner_radius=4.0f0
                            ),
                            text_style=TextStyle(color=Vec4f(1.0, 1.0, 1.0, 1.0)),
                            interaction_state=button_states[]["top"],
                            on_interaction_state_change=(new_state) -> begin
                                button_states[] = merge(button_states[], Dict("top" => new_state))
                            end
                        )
                    ], spacing=15.0f0),
                style=ContainerStyle(
                    background_color=Vec4f(0.15, 0.15, 0.18, 1.0),
                    border_color=Vec4f(0.3, 0.3, 0.35, 1.0),
                    border_width=1.0f0,
                    corner_radius=6.0f0,
                    padding=20.0f0
                )
            ),

            # Middle section with multiple interactive elements
            Container(
                Column([
                        Fugl.Text("Multiple Interactive Elements",
                            style=TextStyle(size_px=16, color=Vec4f(0.9, 0.9, 0.9, 1.0))), Row([
                                Column([
                                        Fugl.Text("Color:", style=TextStyle(size_px=14, color=Vec4f(0.85, 0.85, 0.85, 1.0))),
                                        Dropdown(
                                            dropdown2_state[],
                                            on_state_change=(new_state) -> dropdown2_state[] = new_state,
                                            on_select=(value, index) -> begin
                                                selected_values[] = merge(selected_values[], Dict("dropdown2" => value))
                                                println("Selected color: $value")
                                            end
                                        )
                                    ], spacing=5.0f0), Column([
                                        TextButton(
                                            "Middle Button 1 ($(button_clicks[]["middle1"]))",
                                            on_click=() -> begin
                                                button_clicks[] = merge(button_clicks[], Dict("middle1" => button_clicks[]["middle1"] + 1))
                                                println("Middle button 1 clicked!")
                                            end,
                                            container_style=ContainerStyle(
                                                background_color=Vec4f(0.5, 0.3, 0.7, 1.0),
                                                padding=8.0f0,
                                                corner_radius=4.0f0
                                            ),
                                            text_style=TextStyle(color=Vec4f(1.0, 1.0, 1.0, 1.0)),
                                            interaction_state=button_states[]["middle1"],
                                            on_interaction_state_change=(new_state) -> begin
                                                button_states[] = merge(button_states[], Dict("middle1" => new_state))
                                            end
                                        ),
                                        TextButton(
                                            "Middle Button 2 ($(button_clicks[]["middle2"]))",
                                            on_click=() -> begin
                                                button_clicks[] = merge(button_clicks[], Dict("middle2" => button_clicks[]["middle2"] + 1))
                                                println("Middle button 2 clicked!")
                                            end,
                                            container_style=ContainerStyle(
                                                background_color=Vec4f(0.7, 0.5, 0.3, 1.0),
                                                padding=8.0f0,
                                                corner_radius=4.0f0
                                            ),
                                            text_style=TextStyle(color=Vec4f(1.0, 1.0, 1.0, 1.0)),
                                            interaction_state=button_states[]["middle2"],
                                            on_interaction_state_change=(new_state) -> begin
                                                button_states[] = merge(button_states[], Dict("middle2" => new_state))
                                            end
                                        )
                                    ], spacing=10.0f0)
                            ], spacing=20.0f0)
                    ], spacing=15.0f0),
                style=ContainerStyle(
                    background_color=Vec4f(0.18, 0.15, 0.15, 1.0),
                    border_color=Vec4f(0.35, 0.3, 0.3, 1.0),
                    border_width=1.0f0,
                    corner_radius=6.0f0,
                    padding=20.0f0
                )
            ),

            # Bottom section
            Container(
                Column([
                        Fugl.Text("Final Section",
                            style=TextStyle(size_px=16, color=Vec4f(0.9, 0.9, 0.9, 1.0))), Row([
                                Fugl.Text("Size:", style=TextStyle(size_px=14, color=Vec4f(0.85, 0.85, 0.85, 1.0))),
                                Dropdown(
                                    dropdown3_state[],
                                    on_state_change=(new_state) -> dropdown3_state[] = new_state,
                                    on_select=(value, index) -> begin
                                        selected_values[] = merge(selected_values[], Dict("dropdown3" => value))
                                        println("Selected size: $value")
                                    end
                                )
                            ], spacing=10.0f0), Row([
                                TextButton(
                                    "Bottom Button 1 ($(button_clicks[]["bottom1"]))",
                                    on_click=() -> begin
                                        button_clicks[] = merge(button_clicks[], Dict("bottom1" => button_clicks[]["bottom1"] + 1))
                                        println("Bottom button 1 clicked!")
                                    end,
                                    container_style=ContainerStyle(
                                        background_color=Vec4f(0.3, 0.7, 0.5, 1.0),
                                        padding=8.0f0,
                                        corner_radius=4.0f0
                                    ),
                                    text_style=TextStyle(color=Vec4f(1.0, 1.0, 1.0, 1.0)),
                                    interaction_state=button_states[]["bottom1"],
                                    on_interaction_state_change=(new_state) -> begin
                                        button_states[] = merge(button_states[], Dict("bottom1" => new_state))
                                    end
                                ),
                                TextButton(
                                    "Bottom Button 2 ($(button_clicks[]["bottom2"]))",
                                    on_click=() -> begin
                                        button_clicks[] = merge(button_clicks[], Dict("bottom2" => button_clicks[]["bottom2"] + 1))
                                        println("Bottom button 2 clicked!")
                                    end,
                                    container_style=ContainerStyle(
                                        background_color=Vec4f(0.7, 0.3, 0.5, 1.0),
                                        padding=8.0f0,
                                        corner_radius=4.0f0
                                    ),
                                    text_style=TextStyle(color=Vec4f(1.0, 1.0, 1.0, 1.0)),
                                    interaction_state=button_states[]["bottom2"],
                                    on_interaction_state_change=(new_state) -> begin
                                        button_states[] = merge(button_states[], Dict("bottom2" => new_state))
                                    end
                                )
                            ], spacing=15.0f0),
                        TextButton(
                            "Reset All Counters",
                            on_click=() -> begin
                                button_clicks[] = Dict(
                                    "top" => 0,
                                    "middle1" => 0,
                                    "middle2" => 0,
                                    "bottom1" => 0,
                                    "bottom2" => 0,
                                    "reset" => button_clicks[]["reset"] + 1
                                )
                                println("All counters reset! Reset button clicked $(button_clicks[]["reset"]) times")
                            end,
                            container_style=ContainerStyle(
                                background_color=Vec4f(0.6, 0.3, 0.3, 1.0),
                                padding=8.0f0,
                                corner_radius=4.0f0
                            ),
                            text_style=TextStyle(color=Vec4f(1.0, 1.0, 1.0, 1.0)),
                            interaction_state=button_states[]["reset"],
                            on_interaction_state_change=(new_state) -> begin
                                button_states[] = merge(button_states[], Dict("reset" => new_state))
                            end
                        )
                    ], spacing=15.0f0),
                style=ContainerStyle(
                    background_color=Vec4f(0.15, 0.18, 0.15, 1.0),
                    border_color=Vec4f(0.3, 0.35, 0.3, 1.0),
                    border_width=1.0f0,
                    corner_radius=6.0f0,
                    padding=20.0f0
                )
            )
        ]

        # Create the main content column
        main_content = IntrinsicColumn(content_items, spacing=20.0f0, padding=15.0f0)

        # Dark scrollbar style
        scroll_style = ScrollAreaStyle(
            scrollbar_width=6.0f0,
            scrollbar_color=Vec4f(0.55, 0.65, 0.75, 0.8),
            scrollbar_background_color=Vec4f(0.2, 0.2, 0.2, 0.3),
            scrollbar_hover_color=Vec4f(0.65, 0.75, 0.85, 0.9),
            corner_color=Vec4f(0.2, 0.2, 0.2, 0.3)
        )

        # Create the top content (scroll area with dropdowns and buttons)
        top_content = main_content
        # top_content = VerticalScrollArea(
        #     main_content,
        #     scroll_state=scroll_state[],
        #     style=scroll_style,
        #     show_scrollbar=true,
        #     on_scroll_change=(new_state) -> scroll_state[] = new_state,
        #     on_click=(x, y) -> println("Clicked in scroll area at: ($x, $y)")
        # )

        # Create bottom content panel
        bottom_content = Empty()

        # Create vertical split container
        split_content = VerticalSplitContainer(
            top_content,
            bottom_content,
            state=split_state[],
            on_state_change=(new_state) -> split_state[] = new_state
        )

        # Dark theme card style
        dark_card_style = ContainerStyle(
            background_color=Vec4f(0.08, 0.08, 0.12, 1.0),
            border_color=Vec4f(0.3, 0.3, 0.35, 1.0),
            border_width=1.5f0,
            corner_radius=8.0f0,
            padding=0.0f0
        )

        dark_title_style = TextStyle(
            size_px=18,
            color=Vec4f(0.9, 0.9, 0.95, 1.0)
        )

        return Card(
            "ScrollArea with Dropdowns and Buttons - Z-Ordering Test",
            split_content,
            style=dark_card_style,
            title_style=dark_title_style
        )
    end

    println("Starting ScrollArea + Dropdown Demo...")
    println("Test features:")
    println("  - Multiple dropdowns within scroll area")
    println("  - Buttons that should work correctly")
    println("  - Dropdown overlays should appear above other content")
    println("  - Dropdown overlays should block clicks to content beneath")
    println("  - Mouse wheel scrolling should work")

    # Run the demo
    Fugl.run(ScrollDropdownDemo,
        title="ScrollArea + Dropdown Demo - Z-Ordering Test",
        window_width_px=800,
        window_height_px=600,
        fps_overlay=true
    )
end

main()
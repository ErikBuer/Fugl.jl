using Fugl
using Fugl: Text, SplitContainerState, SplitContainerStyle

function main()
    # Create state refs for split containers
    horizontal_split_state = Ref(SplitContainerState(split_position=0.3f0))  # Start with 30% for left panel
    vertical_split_state = Ref(SplitContainerState(split_position=0.4f0))    # Start with 40% for top panel

    # Add button click counters to test interactions
    left_clicks = Ref(0)
    right_clicks = Ref(0)
    top_clicks = Ref(0)

    # Add interaction states for buttons
    left_button_state = Ref(InteractionState())
    right_button_state = Ref(InteractionState())
    top_button_state = Ref(InteractionState())
    reset_button_state = Ref(InteractionState())

    function SplitDemo()
        # Create some simple content for the splits
        left_content = Container(
            Column([
                    Text("Click and drag the gray bar to resize!"),
                    TextButton(
                        "Left Button",
                        on_click=() -> begin
                            left_clicks[] += 1
                            println("Left button clicked! Count: $(left_clicks[])")
                        end,
                        interaction_state=left_button_state[],
                        on_interaction_state_change=(new_state) -> left_button_state[] = new_state
                    ),
                    Text("Clicks: $(left_clicks[])", style=TextStyle(size_px=12, color=Vec4f(0.6, 0.6, 0.6, 1.0)))
                ], spacing=10.0f0),
            style=ContainerStyle(
                background_color=Vec4f(0.9, 0.9, 1.0, 1.0),  # Light blue
                padding=20.0f0
            )
        )

        right_content = Container(
            Column([
                    Text("This side can be resized by dragging the splitter handle."),
                    TextButton(
                        "Right Button",
                        on_click=() -> begin
                            right_clicks[] += 1
                            println("Right button clicked! Count: $(right_clicks[])")
                        end,
                        interaction_state=right_button_state[],
                        on_interaction_state_change=(new_state) -> right_button_state[] = new_state
                    ),
                    Text("Clicks: $(right_clicks[])", style=TextStyle(size_px=12, color=Vec4f(0.6, 0.6, 0.6, 1.0)))
                ], spacing=10.0f0),
            style=ContainerStyle(
                background_color=Vec4f(1.0, 0.9, 0.9, 1.0),  # Light red
                padding=20.0f0
            )
        )

        # Create horizontal split container - recreated each frame with current state
        horizontal_split = HorizontalSplitContainer(
            left_content,
            right_content,
            style=SplitContainerStyle(),
            state=horizontal_split_state[],
            on_state_change=(new_state) -> horizontal_split_state[] = new_state
        )

        # Create some content for vertical split
        top_content = Container(
            Column([
                    Text("This demonstrates vertical splitting"),
                    Row([
                            TextButton(
                                "Top Button",
                                on_click=() -> begin
                                    top_clicks[] += 1
                                    println("Top button clicked! Count: $(top_clicks[])")
                                end,
                                interaction_state=top_button_state[],
                                on_interaction_state_change=(new_state) -> top_button_state[] = new_state
                            ),
                            TextButton(
                                "Reset All",
                                on_click=() -> begin
                                    left_clicks[] = 0
                                    right_clicks[] = 0
                                    top_clicks[] = 0
                                    println("All counters reset!")
                                end,
                                interaction_state=reset_button_state[],
                                on_interaction_state_change=(new_state) -> reset_button_state[] = new_state
                            )
                        ], spacing=10.0f0),
                    Text("Top clicks: $(top_clicks[]) | Total: $(left_clicks[] + right_clicks[] + top_clicks[])",
                        style=TextStyle(size_px=12, color=Vec4f(0.6, 0.6, 0.6, 1.0)))
                ], spacing=10.0f0),
            style=ContainerStyle(
                background_color=Vec4f(0.9, 1.0, 0.9, 1.0),  # Light green
                padding=20.0f0
            )
        )

        # Create main vertical split with horizontal split in bottom - recreated each frame with current state
        main_split = VerticalSplitContainer(
            top_content,
            horizontal_split,
            style=SplitContainerStyle(),
            state=vertical_split_state[],
            on_state_change=(new_state) -> vertical_split_state[] = new_state
        )

        return main_split
    end

    # Run the GUI - SplitDemo function will be called each frame
    Fugl.run(SplitDemo, title="Split Container Demo - Immutable", window_width_px=1200, window_height_px=812, fps_overlay=true)
end

main()
#Fugl.screenshot(SplitDemo, "test/test_output/Split Container Demo - Optimized.png", 1200, 812)

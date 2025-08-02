using Fugl
using Fugl: Text, SplitContainerState, SplitContainerStyle

function main()
    # Create state refs for split containers
    horizontal_split_state = Ref(SplitContainerState(split_position=0.3f0))  # Start with 30% for left panel
    vertical_split_state = Ref(SplitContainerState(split_position=0.4f0))    # Start with 40% for top panel

    function SplitDemo()
        # Create some simple content for the splits
        left_content = Container(
            Text("Click and drag the gray bar to resize!"),
            style=ContainerStyle(
                background_color=Vec4f(0.9, 0.9, 1.0, 1.0),  # Light blue
                padding_px=20.0f0
            )
        )

        right_content = Container(
            Text("This side can be resized by dragging the splitter handle."),
            style=ContainerStyle(
                background_color=Vec4f(1.0, 0.9, 0.9, 1.0),  # Light red
                padding_px=20.0f0
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
            Text("This demonstrates vertical splitting"),
            style=ContainerStyle(
                background_color=Vec4f(0.9, 1.0, 0.9, 1.0),  # Light green
                padding_px=20.0f0
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
    Fugl.run(SplitDemo, title="Split Container Demo - Immutable", window_width_px=1200, window_height_px=800, fps_overlay=true)
end

main()
#Fugl.screenshot(SplitDemo, "test/test_output/Split Container Demo - Optimized.png", 1200, 800)

using Fugl
using Fugl: Text, SplitContainerState

function main()
    # Create state refs for split containers
    horizontal_split_state = Ref(SplitContainerState(split_position=0.3f0))

    function DebugSplitDemo()
        # Simple debug version with just horizontal split
        left_content = Container(
            Text("Left Panel\nDrag here →"),
            style=ContainerStyle(
                background_color=Vec4f(0.9, 0.9, 1.0, 1.0),
                padding_px=20.0f0
            )
        )

        right_content = Container(
            Text("Right Panel\n← Drag here"),
            style=ContainerStyle(
                background_color=Vec4f(1.0, 0.9, 0.9, 1.0),
                padding_px=20.0f0
            )
        )

        # Debug state changes
        println("Creating split with state: $(horizontal_split_state[])")

        horizontal_split = HorizontalSplitContainer(
            left_content,
            right_content,
            min_size=100.0f0,
            handle_thickness=8.0f0,  # Make handle thicker for easier clicking
            handle_color=Vec4f(0.3, 0.3, 0.3, 1.0),  # Darker handle
            handle_hover_color=Vec4f(0.1, 0.1, 0.1, 1.0),  # Very dark on hover
            state=horizontal_split_state[],
            on_state_change=(new_state) -> begin
                println("State changed: split_pos=$(new_state.split_position), dragging=$(new_state.is_dragging), hovering=$(new_state.is_hovering)")
                horizontal_split_state[] = new_state
            end
        )

        return horizontal_split
    end

    Fugl.run(DebugSplitDemo, title="Debug Split Container", window_width_px=800, window_height_px=400)
end

main()

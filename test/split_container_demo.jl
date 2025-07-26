using Fugl
using Fugl: Text

function create_split_demo()
    # Create some simple content for the splits
    left_content = Container(
        Text("Left Panel\nClick and drag\nthe gray bar\nto resize!"),
        style=ContainerStyle(
            background_color=Vec4f(0.9, 0.9, 1.0, 1.0),  # Light blue
            padding_px=20.0f0
        )
    )

    right_content = Container(
        Text("Right Panel\nThis side can\nbe resized by\ndragging the\nsplitter handle."),
        style=ContainerStyle(
            background_color=Vec4f(1.0, 0.9, 0.9, 1.0),  # Light red
            padding_px=20.0f0
        )
    )

    # Create horizontal split container
    horizontal_split = HorizontalSplitContainer(
        left_content,
        right_content,
        split_position=0.3f0,  # Start with 30% for left panel
        min_size=100.0f0,
        handle_thickness=6.0f0,
        handle_color=Vec4f(0.6, 0.6, 0.6, 1.0),
        handle_hover_color=Vec4f(0.4, 0.4, 0.4, 1.0)
    )

    # Create some content for vertical split
    top_content = Container(
        Text("Top Panel\nThis demonstrates\nvertical splitting"),
        style=ContainerStyle(
            background_color=Vec4f(0.9, 1.0, 0.9, 1.0),  # Light green
            padding_px=20.0f0
        )
    )

    # Create main vertical split with horizontal split in bottom
    main_split = VerticalSplitContainer(
        top_content,
        horizontal_split,
        split_position=0.4f0,  # Start with 40% for top panel
        min_size=80.0f0,
        handle_thickness=6.0f0,
        handle_color=Vec4f(0.6, 0.6, 0.6, 1.0),
        handle_hover_color=Vec4f(0.4, 0.4, 0.4, 1.0)
    )

    return main_split
end


Fugl.run(create_split_demo, title="Split Container Demo - Optimized", window_width_px=1200, window_height_px=800)
#Fugl.screenshot(create_split_demo, "test/test_output/Split Container Demo - Optimized.png", 1200, 800)

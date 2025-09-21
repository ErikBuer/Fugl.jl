# SplitContainer

Split containers allow you to create resizable panels that users can adjust by dragging a handle between them. Fugl.jl provides both horizontal and vertical split containers with external state management for a clean, functional UI paradigm.

The `SplitContainerState` struct holds the split position and interaction state, while the `on_state_change` callback updates the external state reference when users drag the handle.

The `SplitContainerStyle` struct encapsulates visual appearance settings like handle thickness, colors, and minimum panel sizes, making it easy to create reusable style configurations across your application.

``` @example SplitContainerExample
using Fugl
using Fugl: Text, SplitContainerState, SplitContainerStyle

function MyApp()
    # Create state refs for split containers
    horizontal_split_state = Ref(SplitContainerState(split_position=0.3f0))  # Start with 30% for left panel
    vertical_split_state = Ref(SplitContainerState(split_position=0.4f0))    # Start with 40% for top panel

    # Create some simple content for the splits
    left_content = Container(
        Text("Click and drag the gray bar to resize!")
    )

    right_content = Container(
        Text("This side can be resized by dragging the splitter handle.")
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
        Text("This demonstrates vertical splitting")
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

screenshot(MyApp, "split_containers.png", 812, 600);
nothing #hide
```

![Split container example](split_containers.png)

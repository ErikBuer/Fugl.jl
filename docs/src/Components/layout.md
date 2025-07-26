# Layout

## Column

`Column` is a component for creating linear layout.

``` @example ColumnExample
using Fugl

function MyApp()
    Column([
        Container(),
        Container(),
        Container(),
    ])
end

screenshot(MyApp, "column.png", 400, 300);
nothing #hide
```

![Column example](column.png)

## Row

`Row` is a component for creating linear layout.

``` @example RowExample
using Fugl

function MyApp()
    Row([
        Container(),
        Container(),
        Container(),
    ])
end

screenshot(MyApp, "row.png", 400, 300);
nothing #hide
```

![Row example](row.png)

## Sizing

``` @example IntrinsicSizeExample
using Fugl
using Fugl: Text

function MyApp()
    Column([
        IntrinsicWidth(Container(Text("IntrinsicWidth"))),
        IntrinsicSize(Container(Text("IntrinsicSize"))),
        IntrinsicHeight(Container(Text("IntrinsicHeight"))),
    ])
end

screenshot(MyApp, "intrinsic_sizing.png", 400, 300);
nothing #hide
```

![Intrinsic sizing example](intrinsic_sizing.png)

``` @example FixedSizeExample
using Fugl
using Fugl: Text

function MyApp()
    Column([
        FixedSize(Container(), 400, 50),
        FixedSize(Container(), 400, 50),
        FixedSize(Container(), 400, 50),
    ])
end

screenshot(MyApp, "fixed_sizing.png", 400, 300);
nothing #hide
```

![Fixed sizing example](fixed_sizing.png)

## IntrinsicColumn

``` @example IntrinsicColumnExample
using Fugl
using Fugl: Text

function MyApp()
    IntrinsicColumn([
        FixedSize(Container(Text("Clipping width")), 800, 50),
        FixedSize(Container(), 400, 50),
        FixedSize(Container(), 200, 50),
    ])
end

screenshot(MyApp, "intrinsic_column.png", 400, 300);
nothing #hide
```

![Intrinsic Column](intrinsic_column.png)

## IntrinsicRow

``` @example IntrinsicColumnExample
using Fugl
using Fugl: Text

function MyApp()
    IntrinsicRow([
        FixedSize(Container(Text("Clipping Height")), 50, 800),
        FixedSize(Container(), 50, 400),
        FixedSize(Container(), 50, 200),
    ])
end

screenshot(MyApp, "intrinsic_row.png", 400, 300);
nothing #hide
```

![Intrinsic row](intrinsic_row.png)

## Alignment

The alignment components allow you to position sized components within their containers.

### Horizontal Alignment

``` @example AlignHorizontalExample
using Fugl
using Fugl: Text

function MyApp()
    Column([
        AlignHorizontal(FixedSize(Container(Text("Left")), 100, 50), :left),
        AlignHorizontal(FixedSize(Container(Text("Center")), 100, 50), :center),
        AlignHorizontal(FixedSize(Container(Text("Right")), 100, 50), :right),
    ])
end

screenshot(MyApp, "horizontal_alignment.png", 400, 300);
nothing #hide
```

![Horizontal alignment example](horizontal_alignment.png)

### Vertical Alignment

``` @example AlignVerticalExample
using Fugl
using Fugl: Text

function MyApp()
    Row([
        AlignVertical(IntrinsicSize(Container(Text("Top"))), :top),
        AlignVertical(IntrinsicSize(Container(Text("Center"))), :center),
        AlignVertical(IntrinsicSize(Container(Text("Bottom"))), :bottom),
    ])
end

screenshot(MyApp, "vertical_alignment.png", 400, 300);
nothing #hide
```

![Vertical alignment example](vertical_alignment.png)

## Split Containers

Split containers allow you to create resizable panels that users can adjust by dragging a handle between them. Fugl.jl provides both horizontal and vertical split containers with external state management for a clean, functional UI paradigm.

``` @example SplitContainerExample
using Fugl
using Fugl: Text, SplitContainerState

function MyApp()
    # Create state refs for split containers
    horizontal_split_state = Ref(SplitContainerState(split_position=0.3f0))  # Start with 30% for left panel
    vertical_split_state = Ref(SplitContainerState(split_position=0.4f0))    # Start with 40% for top panel

    # Create some simple content for the splits
    left_content = Container(
        Text("Left Panel\nClick and drag\nthe gray bar\nto resize!"),
        style=ContainerStyle(
            background_color=Vec4f(0.9, 0.9, 1.0, 1.0),  # Light blue
            padding_px=20.0f0
        )
    )

    right_content = Container(
        Text("Right Panel This side can be resized by dragging the splitter handle."),
        style=ContainerStyle(
            background_color=Vec4f(1.0, 0.9, 0.9, 1.0),  # Light red
            padding_px=20.0f0
        )
    )

    # Create horizontal split container - recreated each frame with current state
    horizontal_split = HorizontalSplitContainer(
        left_content,
        right_content,
        min_size=100.0f0,
        handle_thickness=6.0f0,
        handle_color=Vec4f(0.6, 0.6, 0.6, 1.0),
        handle_hover_color=Vec4f(0.4, 0.4, 0.4, 1.0),
        state=horizontal_split_state[],
        on_state_change=(new_state) -> horizontal_split_state[] = new_state
    )

    # Create some content for vertical split
    top_content = Container(
        Text("Top Panel This demonstrates vertical splitting"),
        style=ContainerStyle(
            background_color=Vec4f(0.9, 1.0, 0.9, 1.0),  # Light green
            padding_px=20.0f0
        )
    )

    # Create main vertical split with horizontal split in bottom - recreated each frame with current state
    main_split = VerticalSplitContainer(
        top_content,
        horizontal_split,
        min_size=80.0f0,
        handle_thickness=6.0f0,
        handle_color=Vec4f(0.6, 0.6, 0.6, 1.0),
        handle_hover_color=Vec4f(0.4, 0.4, 0.4, 1.0),
        state=vertical_split_state[],
        on_state_change=(new_state) -> vertical_split_state[] = new_state
    )

    return main_split
end

screenshot(MyApp, "split_containers.png", 800, 600);
nothing #hide
```

![Split container example](split_containers.png)

Split containers follow Fugl.jl's functional UI paradigm by keeping all mutable state external to the view components. The `SplitContainerState` struct holds the split position and interaction state, while the `on_state_change` callback updates the external state reference when users drag the handle.

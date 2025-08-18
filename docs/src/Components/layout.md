# Layout

## Column

`Column` is a component for creating linear layout.

``` @example ColumnExample
using Fugl

function MyApp()
    Container(
        Column([
            Container(),
            Container(),
            Container(),
        ])
    )
end

screenshot(MyApp, "column.png", 840, 300);
nothing #hide
```

![Column example](column.png)

## Row

`Row` is a component for creating linear layout.

Note how we have omitted the vector in the `Row` argument. Either way is fine.

``` @example RowExample
using Fugl

function MyApp()
    Container(
        Row(
            Container(),
            Container(),
            Container(),
        )
    )
end

screenshot(MyApp, "row.png", 840, 300);
nothing #hide
```

![Row example](row.png)

## Sizing

``` @example IntrinsicSizeExample
using Fugl
using Fugl: Text

function MyApp()
    Container(
        Column(
            IntrinsicWidth(Container(Text("IntrinsicWidth"))),
            IntrinsicSize(Container(Text("IntrinsicSize"))),
            IntrinsicHeight(Container(Text("IntrinsicHeight"))),
        )
    )
end

screenshot(MyApp, "intrinsic_sizing.png", 840, 300);
nothing #hide
```

![Intrinsic sizing example](intrinsic_sizing.png)

``` @example FixedSizeExample
using Fugl
using Fugl: Text

function MyApp()
    Container(
        Column(
            FixedSize(Container(), 840, 50),
            FixedSize(Container(), 840, 50),
            FixedSize(Container(), 840, 50),
        )
    )
end

screenshot(MyApp, "fixed_sizing.png", 840, 300);
nothing #hide
```

![Fixed sizing example](fixed_sizing.png)

## IntrinsicColumn

``` @example IntrinsicColumnExample
using Fugl
using Fugl: Text

function MyApp()
    Container(
        IntrinsicColumn(
            FixedSize(Container(Text("Clipping width")), 900, 50),
            FixedSize(Container(), 400, 50),
            FixedSize(Container(), 200, 50),
        )
    )
end

screenshot(MyApp, "intrinsic_column.png", 840, 300);
nothing #hide
```

![Intrinsic Column](intrinsic_column.png)

## IntrinsicRow

``` @example IntrinsicColumnExample
using Fugl
using Fugl: Text

function MyApp()
    Container(
        IntrinsicRow(
            FixedSize(Container(Text("Clipping Height")), 50, 800),
            FixedSize(Container(), 50, 400),
            FixedSize(Container(), 50, 200),
        )
    )
end

screenshot(MyApp, "intrinsic_row.png", 840, 300);
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
    Container(
        Column(
            AlignHorizontal(FixedSize(Container(Text("Left")), 100, 50), :left),
            AlignHorizontal(FixedSize(Container(Text("Center")), 100, 50), :center),
            AlignHorizontal(FixedSize(Container(Text("Right")), 100, 50), :right),
        )
    )
end

screenshot(MyApp, "horizontal_alignment.png", 840, 300);
nothing #hide
```

![Horizontal alignment example](horizontal_alignment.png)

### Vertical Alignment

``` @example AlignVerticalExample
using Fugl
using Fugl: Text

function MyApp()
    Container(
        Row(
            AlignVertical(IntrinsicSize(Container(Text("Top"))), :top),
            AlignVertical(IntrinsicSize(Container(Text("Center"))), :center),
            AlignVertical(IntrinsicSize(Container(Text("Bottom"))), :bottom),
        )
    )
end

screenshot(MyApp, "vertical_alignment.png", 840, 300);
nothing #hide
```

![Vertical alignment example](vertical_alignment.png)

## Split Containers

Split containers allow you to create resizable panels that users can adjust by dragging a handle between them. Fugl.jl provides both horizontal and vertical split containers with external state management for a clean, functional UI paradigm.

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

screenshot(MyApp, "split_containers.png", 840, 600);
nothing #hide
```

![Split container example](split_containers.png)

Split containers follow Fugl.jl's functional UI paradigm by keeping all mutable state external to the view components. The `SplitContainerState` struct holds the split position and interaction state, while the `on_state_change` callback updates the external state reference when users drag the handle.

The `SplitContainerStyle` struct encapsulates visual appearance settings like handle thickness, colors, and minimum panel sizes, making it easy to create reusable style configurations across your application.

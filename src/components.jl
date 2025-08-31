include("components/common/utilities.jl")
include("components/common/draw.jl")
include("components/common/render_cache.jl")
include("components/common/rec2f.jl")

include("components/Empty.jl")
export Empty

include("components/FixedSize.jl")
export FixedSize, FixedWidth, FixedHeight

include("components/AlignVertical.jl")
export AlignVertical, AlignTop, AlignMiddle, AlignBottom

include("components/AlignHorizontal.jl")
export AlignHorizontal, AlignLeft, AlignCenter, AlignRight

include("components/Padding.jl")
export Padding

include("components/IntrinsicSize.jl")
export IntrinsicSize

include("components/IntrinsicHeight.jl")
export IntrinsicHeight

include("components/IntrinsicWidth.jl")
export IntrinsicWidth

include("components/Row.jl")
export Row

include("components/Column.jl")
export Column

include("components/IntrinsicColumn.jl")
export IntrinsicColumn

include("components/IntrinsicRow.jl")
export IntrinsicRow

include("components/Container.jl")
export Container, ContainerStyle

include("components/slider/HorizontalSlider.jl")
export HorizontalSlider

include("components/text/Text.jl")
export Text, TextStyle

include("components/text_editor/TextBox.jl")
export TextBox, TextBoxStyle
export EditorState

include("components/text_editor/CodeEditor.jl")
export CodeEditor, CodeEditorStyle

# Export the unified style structure
export TextEditorStyle

include("components/image/Image.jl")
export Image
export clear_texture_cache!

include("components/separator_line/HorizontalLine.jl")
include("components/separator_line/VerticalLine.jl")
export HorizontalLineView, VerticalLineView, HLine, VLine, SeparatorStyle

include("components/SplitContainer.jl")
export HorizontalSplitContainer, VerticalSplitContainer, SplitContainerState

include("composite_components/buttons.jl")
export TextButton, IconButton

include("composite_components/NumberField.jl")
export NumberField, NumberFieldState, NumberFieldOptions, NumberFieldStyle

include("composite_components/Dropdown.jl")
export Dropdown, DropdownState, DropdownStyle

include("composite_components/Card.jl")
export Card

include("components/AtlasDebug.jl")

include("composite_components/plot/Plot.jl")
export Plot, PlotView, PlotStyle
export PlotState, reset_plot_view_bounds, calculate_bounds_from_elements
export LinePlotElement, ScatterPlotElement, StemPlotElement, HeatmapElement
export AbstractPlotElement
export LineStyle, SOLID, DASH, DOT, DASHDOT
export MarkerType, CIRCLE, TRIANGLE, RECTANGLE
export VerticalColorbar, HorizontalColorbar

include("composite_components/tree/Tree.jl")
export Tree, TreeNode, TreeStyle, TreeState
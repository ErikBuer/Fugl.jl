include("components/common/utilities.jl")
include("components/common/draw.jl")
include("components/common/render_cache.jl")
include("components/common/rectangle.jl")
export Rectangle

include("components/common/enum_utils.jl")
include("components/common/LinePattern.jl")
export LinePattern, SOLID, DASH, DOT, DASHDOT
include("components/common/LineCap.jl")
export LineCap, BUTT_CAP, SQUARE_CAP, ROUND_CAP

include("components/common/line_draw.jl")
export draw_simple_line, draw_line, draw_lines, SimpleLine

include("components/Empty.jl")
export Empty

include("components/Focus.jl")
export Focus

include("components/fixed_sizes/FixedSize.jl")
include("components/fixed_sizes/FixedWidth.jl")
include("components/fixed_sizes/FixedHeight.jl")
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

include("components/Rotate.jl")
export Rotate

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

include("components/KeyListener.jl")
export KeyListener

include("components/slider/HorizontalSlider.jl")
export HorizontalSlider, SliderState, SliderStyle

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

include("components/CheckBox.jl")
export CheckBox, CheckBoxStyle, CheckBoxView

include("components/separator_line/HorizontalLine.jl")
include("components/separator_line/VerticalLine.jl")
export HorizontalLineView, VerticalLineView, HLine, VLine, SeparatorStyle

include("components/scroll_area/ScrollArea.jl")
export VerticalScrollState, HorizontalScrollState, VerticalScrollArea, HorizontalScrollArea, ScrollAreaStyle

include("components/SplitContainer.jl")
export HorizontalSplitContainer, VerticalSplitContainer, SplitContainerState

include("components/table/Table.jl")
export Table, TableStyle, TableState

include("composite_components/buttons.jl")
export TextButton, IconButton

include("composite_components/FormattedTextField.jl")
export FormattedTextField

include("composite_components/NumberField.jl")
export NumberField

include("composite_components/TextField.jl")
export TextField

include("composite_components/dropdown/Dropdown.jl")
export Dropdown, DropdownState, DropdownStyle

include("composite_components/Card.jl")
export Card

include("composite_components/modal/Modal.jl")
export Modal, ModalState, ModalStyle

include("components/AtlasDebug.jl")

include("composite_components/plot/Plot.jl")
export Plot, PlotView, PlotStyle
export PlotState, reset_plot_view_bounds, calculate_bounds_from_elements
export LinePlotElement, ScatterPlotElement, StemPlotElement, HeatmapElement
export AbstractPlotElement
export MarkerType, CIRCLE, TRIANGLE, RECTANGLE
export SimpleLine, draw_line, draw_lines, draw_simple_line
export VerticalColorbar, HorizontalColorbar
export Legend

include("composite_components/tree/Tree.jl")
export Tree, TreeNode, TreeStyle, TreeState
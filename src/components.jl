include("components/common/utilities.jl")
include("components/common/draw.jl")
include("components/common/render_cache.jl")
include("components/common/rec2f.jl")

include("components/Empty.jl")
export Empty

include("components/FixedSize.jl")
export FixedSize, FixedWidth, FixedHeight

include("components/AlignVertical.jl")
export AlignVertical

include("components/AlignHorizontal.jl")
export AlignHorizontal

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

include("components/HorizontalSlider.jl")
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

include("components/SplitContainer.jl")
export HorizontalSplitContainer, VerticalSplitContainer, SplitContainerState

include("composite_components/buttons.jl")
export TextButton, IconButton

include("composite_components/NumberField.jl")
export NumberField, NumberFieldState, NumberFieldOptions, NumberFieldStyle

include("composite_components/Dropdown.jl")
export Dropdown, DropdownState, DropdownStyle

include("components/AtlasDebug.jl")

include("composite_components/plot/Plot.jl")
export Plot, PlotView, PlotState, PlotStyle
export LinePlotElement, ScatterPlotElement, StemPlotElement, ImagePlotElement
export AbstractPlotElement, PlotType, LINE_PLOT, SCATTER_PLOT, STEM_PLOT, MATRIX_PLOT
export LineStyle, SOLID, DASH, DOT, DASHDOT
export MarkerType, CIRCLE, TRIANGLE, RECTANGLE
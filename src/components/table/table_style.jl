struct TableStyle
    # Header styling
    header_background_color::Vec4f
    header_text_style::TextStyle
    header_height::Float32

    # Cell styling
    cell_background_color::Vec4f
    cell_alternate_background_color::Vec4f  # Color for alternating rows
    cell_text_style::TextStyle
    cell_height::Float32

    # Text wrapping and clipping
    max_wrapped_rows::Int  # 0 = no wrapping (single row), >0 = max number of wrapped rows

    # Grid styling
    show_grid::Bool
    grid_color::Vec4f
    grid_width::Float32

    # Padding and spacing
    cell_padding::Float32

    # Border styling
    border_color::Vec4f
    border_width::Float32
end

function TableStyle(;
    header_background_color::Vec4f=Vec4f(0.9, 0.9, 0.9, 1.0),
    header_text_style::TextStyle=TextStyle(size_px=14, color=Vec4f(0.0, 0.0, 0.0, 1.0)),
    header_height::Float32=30.0f0,
    cell_background_color::Vec4f=Vec4f(1.0, 1.0, 1.0, 1.0),
    cell_alternate_background_color::Vec4f=Vec4f(0.95, 0.95, 0.95, 1.0),
    cell_text_style::TextStyle=TextStyle(size_px=12, color=Vec4f(0.0, 0.0, 0.0, 1.0)),
    cell_height::Float32=25.0f0,
    max_wrapped_rows::Int=0,
    show_grid::Bool=true,
    grid_color::Vec4f=Vec4f(0.7, 0.7, 0.7, 1.0),
    grid_width::Float32=1.0f0, cell_padding::Float32=8.0f0, border_color::Vec4f=Vec4f(0.5, 0.5, 0.5, 1.0),
    border_width::Float32=1.0f0
)
    return TableStyle(
        header_background_color, header_text_style, header_height,
        cell_background_color, cell_alternate_background_color, cell_text_style, cell_height,
        max_wrapped_rows,
        show_grid, grid_color, grid_width,
        cell_padding,
        border_color, border_width
    )
end

struct TableView <: AbstractView
    headers::Vector{String}
    data::Vector{Vector{String}}  # Vector of rows, each row is a vector of cell strings
    style::TableStyle
    state::TableState
    on_cell_click::Function  # Callback for cell clicks: (row_index, col_index) -> nothing
    on_state_change::Function  # Callback for state changes: (new_state) -> nothing
end
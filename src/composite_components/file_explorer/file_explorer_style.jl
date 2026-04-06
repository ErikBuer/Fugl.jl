"""
Style for the FileExplorer component.
"""
struct FileExplorerStyle
    row_height::Float32
    indent::Float32
    background_color::Vec4{Float32}
    normal_style::TextStyle
    selected_style::TextStyle
    dir_color::Vec4{Float32}       # Color applied to directory labels
    selected_bg::Vec4{Float32}     # Background highlight for the selected row
    hover_bg::Vec4{Float32}        # Background highlight on hover
end

function FileExplorerStyle(;
    row_height::Float32=22.0f0,
    indent::Float32=16.0f0,
    background_color::Vec4{Float32}=Vec4{Float32}(0.12f0, 0.12f0, 0.12f0, 1.0f0),
    normal_style::TextStyle=TextStyle(size_points=13, color=Vec4{Float32}(0.80f0, 0.80f0, 0.80f0, 1.0f0)),
    selected_style::TextStyle=TextStyle(size_points=13, color=Vec4{Float32}(1.0f0, 1.0f0, 1.0f0, 1.0f0)),
    dir_color::Vec4{Float32}=Vec4{Float32}(0.65f0, 0.82f0, 1.0f0, 1.0f0),
    selected_bg::Vec4{Float32}=Vec4{Float32}(0.20f0, 0.37f0, 0.62f0, 1.0f0),
    hover_bg::Vec4{Float32}=Vec4{Float32}(0.22f0, 0.22f0, 0.22f0, 1.0f0),
)
    return FileExplorerStyle(row_height, indent, background_color, normal_style, selected_style, dir_color, selected_bg, hover_bg)
end

"""
Struct for batch drawing markers.
"""
struct MarkerBatch
    positions::Vector{Point2f}        # Center positions of markers
    sizes::Vector{Float32}           # Size (radius/half-width) of each marker
    fill_colors::Vector{Vec4{Float32}}   # Fill color per marker
    border_colors::Vector{Vec4{Float32}} # Border color per marker
    border_widths::Vector{Float32}   # Border width per marker
    marker_types::Vector{Float32}    # Marker type per marker (enum as Float32)
end

function MarkerBatch()
    return MarkerBatch(
        Point2f[],
        Float32[],
        Vec4{Float32}[],
        Vec4{Float32}[],
        Float32[],
        Float32[]
    )
end

"""
Add a marker to the batch.
"""
function add_marker!(
    batch::MarkerBatch,
    position::Point2f,
    size::Float32,
    fill_color::Vec4{Float32},
    border_color::Vec4{Float32},
    border_width::Float32,
    marker_type::MarkerType
)
    push!(batch.positions, position)
    push!(batch.sizes, size)
    push!(batch.fill_colors, fill_color)
    push!(batch.border_colors, border_color)
    push!(batch.border_widths, border_width)
    push!(batch.marker_types, Float32(marker_type))
end
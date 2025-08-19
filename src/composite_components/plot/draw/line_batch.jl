"""
Struct for storing a batch of lines for efficient drawing.
"""
struct LineBatch
    points::Vector{Point2f}          # All line points
    colors::Vector{Vec4{Float32}}    # Color per point (for gradients)
    widths::Vector{Float32}          # Width per point (for variable thickness)
    line_styles::Vector{Float32}     # Line style per point (enum as Float32). Int somehow doesn't work on all targets.
    line_progresses::Vector{Float32} # Cumulative distance along line for dash patterns
    segment_starts::Vector{Int32}    # Start indices for each line segment
    segment_lengths::Vector{Int32}   # Length of each line segment
end

function LineBatch()
    return LineBatch(
        Point2f[],
        Vec4{Float32}[],
        Float32[],
        Float32[],
        Float32[],
        Int32[],
        Int32[]
    )
end

"""
Add a complete line (series of connected points) to the batch
"""
function add_line!(batch::LineBatch, points::Vector{Point2f}, color::Vec4{Float32}, width::Float32, line_style::LineStyle=SOLID)
    if length(points) < 2
        return  # Need at least 2 points for a line
    end

    start_idx = length(batch.points) + 1

    # Calculate progress along this line
    line_progress = calculate_line_progress(points)

    # Add all points
    append!(batch.points, points)

    # Add color, width, line style, and progress for each point
    # Convert enum to Float32 for shader
    # Int somehow doesn't work on all targets.
    line_style_f32 = Float32(line_style)
    for i in 1:length(points)
        push!(batch.colors, color)
        push!(batch.widths, width)
        push!(batch.line_styles, line_style_f32)
        push!(batch.line_progresses, line_progress[i])
    end

    # Record this line segment
    push!(batch.segment_starts, Int32(start_idx))
    push!(batch.segment_lengths, Int32(length(points)))
end
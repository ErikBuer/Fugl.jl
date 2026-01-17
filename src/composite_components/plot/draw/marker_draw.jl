@enum MarkerType begin
    CIRCLE = 0
    TRIANGLE = 1
    RECTANGLE = 2
end

function Base.Float32(arg::Fugl.MarkerType)
    return Float32(Int(arg))
end

include("marker_batch.jl")

"""
Draw markers from a batch using the marker shader.
"""
function draw_markers(batch::MarkerBatch, projection_matrix::Mat4{Float32}; anti_aliasing_width::Float32=1.5f0)
    if isempty(batch.positions)
        return
    end

    # Use the marker shader program
    GLA.bind(marker_prog[])

    # Set uniforms
    GLA.gluniform(marker_prog[], :projection, projection_matrix)
    GLA.gluniform(marker_prog[], :anti_aliasing_width, anti_aliasing_width)

    # Create vertex data for triangles (6 vertices per marker for 2 triangles)
    all_positions = Vector{Point2f}()
    all_sizes = Vector{Float32}()
    all_fill_colors = Vector{Vec4{Float32}}()
    all_border_colors = Vector{Vec4{Float32}}()
    all_border_widths = Vector{Float32}()
    all_marker_types = Vector{Float32}()
    all_vertex_ids = Vector{Float32}()

    for i in 1:length(batch.positions)
        # Generate 6 vertices per marker (2 triangles)
        for vertex_id in [0, 1, 2, 1, 3, 2]  # Two triangles: (0,1,2) and (1,3,2)
            push!(all_positions, batch.positions[i])
            push!(all_sizes, batch.sizes[i])
            push!(all_fill_colors, batch.fill_colors[i])
            push!(all_border_colors, batch.border_colors[i])
            push!(all_border_widths, batch.border_widths[i])
            # Convert marker type to Float32 for shader compatibility
            # Int somehow doesn't work on all targets.
            push!(all_marker_types, Float32(batch.marker_types[i]))
            push!(all_vertex_ids, Float32(vertex_id))
        end
    end

    # Generate buffers using GLAbstraction
    buffers = GLA.generate_buffers(
        marker_prog[],
        position=all_positions,
        size=all_sizes,
        fill_color=all_fill_colors,
        border_color=all_border_colors,
        border_width=all_border_widths,
        marker_type=all_marker_types,
        vertex_id=all_vertex_ids
    )

    # Create VAO and draw
    vao = GLA.VertexArray(buffers)

    GLA.bind(vao)
    GLA.draw(vao)
    GLA.unbind(vao)

    # Unbind shader program
    GLA.unbind(marker_prog[])
end

"""
Draw cached text texture to screen
"""
function draw_scatter_plot(
    x_data::Vector{Float32},
    y_data::Vector{Float32},
    transform_func::Function,
    fill_color::Vec4{Float32},
    border_color::Vec4{Float32},
    size::Float32,
    border_width::Float32,
    marker_type::MarkerType,
    projection_matrix::Mat4{Float32};
    anti_aliasing_width::Float32=1.5f0
)
    if length(x_data) != length(y_data) || length(x_data) == 0
        return
    end

    batch = MarkerBatch()

    # Transform data points to screen coordinates and add markers
    for i in 1:length(x_data)
        screen_x, screen_y = transform_func(x_data[i], y_data[i])
        screen_pos = Point2f(screen_x, screen_y)
        add_marker!(batch, screen_pos, size, fill_color, border_color, border_width, marker_type)
    end

    # Draw the batch
    draw_markers(batch, projection_matrix; anti_aliasing_width=anti_aliasing_width)
end

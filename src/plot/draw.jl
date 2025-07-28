# Helper function to draw line plot (needs to be implemented in drawing system)
function draw_line_plot(
    x_data::Vector{Float32},
    y_data::Vector{Float32},
    transform_func::Function,
    color::Vec4{Float32},
    width::Float32,
    projection_matrix::Mat4{Float32}
)
    # This function would need to be implemented in your drawing system
    # It should:
    # 1. Transform all (x,y) data points to screen coordinates using transform_func
    # 2. Draw connected line segments between consecutive points
    # 3. Use the specified color and line width

    # Placeholder - you'll need to implement this based on your OpenGL drawing functions
    println("Drawing line plot with $(length(x_data)) points")
end

# Helper function for filled rectangle (assuming this exists in your drawing system)
function draw_filled_rectangle(vertices::Vector{Vec2{Float32}}, color::Vec4{Float32}, projection_matrix::Mat4{Float32})
    # Placeholder - implement based on your existing rectangle drawing
    println("Drawing filled rectangle")
end

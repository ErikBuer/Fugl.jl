struct EmptyView <: AbstractView end

function Empty()::EmptyView
    return EmptyView()
end

function interpret_view(view::EmptyView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32}, cursor_position::Point2f)
    # Do nothing, as this is an empty view
end

function measure(view::EmptyView)::Tuple{Float32,Float32}
    return (0.0f0, 0.0f0)
end

function measure_width(view::EmptyView, available_height::Float32)::Float32
    return 0.0f0
end

function measure_height(view::EmptyView, available_width::Float32)::Float32
    return 0.0f0
end
struct EmptyView <: AbstractView end

function Empty()::EmptyView
    return EmptyView()
end

function interpret_view(view::EmptyView, x::Float32, y::Float32, width::Float32, height::Float32, projection_matrix::Mat4{Float32})
    # Do nothing, as this is an empty view
end
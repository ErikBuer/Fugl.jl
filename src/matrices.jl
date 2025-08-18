"""
    get_orthographic_matrix(left::T, right::T, bottom::T, top::T, near::T, far::T)::Matrix{T} where {T<:Real}

Create an orthographic projection matrix.
"""
@inline function get_orthographic_matrix(left::T, right::T, bottom::T, top::T, near::T, far::T)::Mat4{Float32} where {T<:Real}
    orthographic_matrix = [
        2.0/(right-left) 0.0 0.0 -(right + left)/(right-left)
        0.0 2.0/(top-bottom) 0.0 -(top + bottom)/(top-bottom)
        0.0 0.0 -2.0/(far-near) -(far + near)/(far-near)
        0.0 0.0 0.0 1.0
    ]

    return Float32.(Mat4(orthographic_matrix))
end

function get_identity_matrix()
    return Float32.(Mat4(
        1.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        0.0, 0.0, 0.0, 1.0,
    ))
end
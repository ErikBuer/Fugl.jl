"""
    get_orthographic_matrix(left::T, right::T, bottom::T, top::T, near::T, far::T)::Matrix{T} where {T<:Real}

Create an orthographic projection matrix.
"""
@inline function get_orthographic_matrix(left::T, right::T, bottom::T, top::T, near::T, far::T)::Mat4{Float32} where {T<:Real}
    # Construct Mat4 directly without hvcat to avoid JuliaC varargs issues
    # Mat4 is column-major, so we specify columns in order
    return Mat4{Float32}(
        Float32(2.0 / (right - left)), Float32(0.0), Float32(0.0), Float32(0.0),
        Float32(0.0), Float32(2.0 / (top - bottom)), Float32(0.0), Float32(0.0),
        Float32(0.0), Float32(0.0), Float32(-2.0 / (far - near)), Float32(0.0),
        Float32(-(right + left) / (right - left)), Float32(-(top + bottom) / (top - bottom)), Float32(-(far + near) / (far - near)), Float32(1.0),
    )
end

function get_identity_matrix()
    return Mat4{Float32}(
        1.0f0, 0.0f0, 0.0f0, 0.0f0,
        0.0f0, 1.0f0, 0.0f0, 0.0f0,
        0.0f0, 0.0f0, 1.0f0, 0.0f0,
        0.0f0, 0.0f0, 0.0f0, 1.0f0,
    )
end
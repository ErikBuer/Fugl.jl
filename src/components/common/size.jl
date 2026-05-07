struct Size
    width::Float32
    height::Float32
end

function Size(width::Real, height::Real)::Size
    return Size(Float32(width), Float32(height))
end
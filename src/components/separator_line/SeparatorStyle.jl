struct SeparatorStyle
    line_width::Float32
    color::Vec4{Float32}  # RGBA color

    function SeparatorStyle(;
        line_width::Float32=1.5f0,
        color::Vec4{Float32}=Vec4{Float32}(0.5f0, 0.5f0, 0.5f0, 1.0f0)  # Default gray
    )
        return new(line_width, color)
    end
end

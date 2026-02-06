struct ModalStyle
    background_color::Vec4{Float32}      # Color of the darkening background overlay (RGBA)
end

function ModalStyle(;
    background_color::Vec4{Float32}=Vec4{Float32}(0.0f0, 0.0f0, 0.0f0, 0.5f0)
)
    return ModalStyle(background_color)
end

const texture_cache = IdDict{UInt64,GLAbstraction.Texture}()

function clear_texture_cache!()
    empty!(texture_cache)
end

function load_image_texture(file_path::String)::GLAbstraction.Texture
    h = hash(file_path)
    texture = get(texture_cache, h, nothing)
    if texture !== nothing
        return texture
    end

    try
        img = FileIO.load(file_path)
        if img isa IndirectArrays.IndirectArray
            img = img.values[img.index]
        end
        texture = GLA.Texture(img;
            minfilter=:linear,
            magfilter=:linear,
            x_repeat=:clamp_to_edge,
            y_repeat=:clamp_to_edge
        )
        global texture_cache
        texture_cache[h] = texture
        return texture
    catch e
        @warn "Failed to load image at path '$file_path': $e"
        @warn "Using a placeholder texture instead."
        placeholder_img = fill(0.5f0, 64, 64)
        texture = GLA.Texture(placeholder_img;
            minfilter=:linear,
            magfilter=:linear,
            x_repeat=:clamp_to_edge,
            y_repeat=:clamp_to_edge
        )
        global texture_cache
        texture_cache[h] = texture
        return texture
    end
end

function load_image_texture(img::AbstractMatrix{<:RGBA})::GLAbstraction.Texture
    h = hash(img)
    texture = get(texture_cache, h, nothing)

    if texture !== nothing
        return texture
    end

    texture = GLA.Texture(img;
        minfilter=:linear,
        magfilter=:linear,
        x_repeat=:clamp_to_edge,
        y_repeat=:clamp_to_edge
    )

    global texture_cache
    texture_cache[h] = texture
    return texture
end
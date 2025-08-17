const texture_cache = IdDict{String,GLAbstraction.Texture}()

function clear_texture_cache!()
    empty!(texture_cache)
end

function load_image_texture(file_path::String)::GLAbstraction.Texture
    # Retrieve the texture directly or load it if not cached
    texture = get(texture_cache, file_path, nothing)
    if texture !== nothing
        return texture
    end

    try
        # Load the image using FileIO
        img = FileIO.load(file_path)

        # If the image is an IndirectArray, materialize it into a standard array
        if img isa IndirectArrays.IndirectArray
            img = img.values[img.index]
        end

        # Create a GLAbstraction texture
        texture = GLA.Texture(img;
            minfilter=:linear,
            magfilter=:linear,
            x_repeat=:clamp_to_edge,
            y_repeat=:clamp_to_edge
        )

        # Cache the texture
        global texture_cache
        texture_cache[file_path] = texture

        return texture
    catch e
        @warn "Failed to load image at path '$file_path': $e"
        @warn "Using a placeholder texture instead."

        # Create a placeholder texture (e.g., a solid color or empty texture)
        placeholder_img = fill(0.5f0, 64, 64)  # Gray 64x64 texture
        texture = GLA.Texture(placeholder_img;
            minfilter=:linear,
            magfilter=:linear,
            x_repeat=:clamp_to_edge,
            y_repeat=:clamp_to_edge
        )

        # Cache the placeholder texture
        global texture_cache
        texture_cache[file_path] = texture

        return texture
    end
end
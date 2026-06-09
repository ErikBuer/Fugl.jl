struct SmithState
    z0::Float32
    normalized::Bool
    cache_id::UInt64
end

function SmithState(; z0::Float32=50.0f0, normalized::Bool=true, cache_id::UInt64=rand(UInt64))::SmithState
    return SmithState(z0, normalized, cache_id)
end

function SmithState(base::SmithState; z0=base.z0, normalized=base.normalized, cache_id=base.cache_id)::SmithState
    return SmithState(z0, normalized, cache_id)
end

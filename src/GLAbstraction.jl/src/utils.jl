
function getfirst(f, A)
    id = findfirst(f, A)
    return id == nothing ? nothing : A[id]
end

macro gputime(codeblock)
    quote
        local const query        = GLuint[1]
        local const elapsed_time = GLuint64[1]
        local const done         = GLint[0]
        glGenQueries(1, query)
        glBeginQuery(GL_TIME_ELAPSED, query[1])
        $(esc(codeblock))
        glEndQuery(GL_TIME_ELAPSED)

        while (done[1] != 1)
            glGetQueryObjectiv(
                query[1],
                GL_QUERY_RESULT_AVAILABLE,
                done
            )
        end
        glGetQueryObjectui64v(query[1], GL_QUERY_RESULT, elapsed_time)
        println("Time Elapsed: ", elapsed_time[1] / 1000000.0, "ms")
    end
end

function print_with_lines(out::IO, text::AbstractString)
    io = IOBuffer()
    for (i,line) in enumerate(split(text, "\n"))
        println(io, Printf.@sprintf("%-4d: %s", i, line))
    end
    write(out, take!(io))
end

print_with_lines(text::AbstractString) = print_with_lines(stdout, text)

"""
Returns the cardinality of a type. falls back to length
"""
cardinality(x) = length(x)
cardinality(x::Number) = 1
cardinality(::Nothing) = 1
cardinality(x::Type{T}) where {T <: Number} = 1

Base.length(::Type{<:Number}) = 1
Base.length(::Type{<:NTuple{N}}) where {N} = N

function glasserteltype(::Type{T}) where T
    # @assert (hasmethod(length, (T,)) || T <: DepthFormat) "Error only types with well defined lengths are allowed.\nSolution define Base.length(::Type{$T})."
end

function istexturesampler(typ::GLenum)
    return (
        typ == GL_SAMPLER_BUFFER || typ == GL_INT_SAMPLER_BUFFER || typ == GL_UNSIGNED_INT_SAMPLER_BUFFER ||
    	typ == GL_IMAGE_2D ||
        typ == GL_SAMPLER_1D || typ == GL_SAMPLER_2D || typ == GL_SAMPLER_3D ||
        typ == GL_UNSIGNED_INT_SAMPLER_1D || typ == GL_UNSIGNED_INT_SAMPLER_2D || typ == GL_UNSIGNED_INT_SAMPLER_3D ||
        typ == GL_INT_SAMPLER_1D || typ == GL_INT_SAMPLER_2D || typ == GL_INT_SAMPLER_3D ||
        typ == GL_SAMPLER_1D_ARRAY || typ == GL_SAMPLER_2D_ARRAY ||
        typ == GL_UNSIGNED_INT_SAMPLER_1D_ARRAY || typ == GL_UNSIGNED_INT_SAMPLER_2D_ARRAY ||
        typ == GL_INT_SAMPLER_1D_ARRAY || typ == GL_INT_SAMPLER_2D_ARRAY
    )
end

"""
    separate(f, A)

Separates the true and false part of `A`.
Single values get passed into `f`.
"""
function separate(f, A)
    trues = [f.(A)...]
    return A[trues], A[(!).(trues)]
end

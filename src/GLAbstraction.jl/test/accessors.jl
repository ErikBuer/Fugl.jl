struct SpriteStyle{T} <: FieldVector{2, T}
    color_id::T # lookup attribute_id for attribute texture
    technique::T
end

const GLSpriteStyle = SpriteStyle{UInt16}

const TEST_1D = Any[]
const TEST_2D = Any[]

a = GLAbstraction.Texture(fill(GLSpriteStyle(0,1), 77))

for i=1:length(a)
    r = i:i
    a[r] = fill(GLSpriteStyle(0,1), length(r))
end

const N = 21 # some prime number to make things nasty
# Generate some data
push!(TEST_1D, rand(Float32, N*N))
push!(TEST_1D, rand(Int32, N*N))
push!(TEST_1D, Point3f[rand(Point3f) for i=1:N*N])
#push!(TEST_1D, Point3{UInt8}[rand(Point3{UInt8}) for i=1:N*N]) #unaligned

push!(TEST_2D, rand(Float32, N,N))
push!(TEST_2D, rand(Int32, N,N))
push!(TEST_2D, Point3f[rand(Point3f) for i=1:N,j=1:N])
#push!(TEST_2D, Point3{UInt8}[rand(Point3{UInt8}) for i=1:N,j=1:N]) #unaligned


test_data = Dict(
    TEST_1D => map(GLAbstraction.Texture, TEST_1D),
    TEST_1D => map(GLAbstraction.Buffer, TEST_1D),
    TEST_2D => map(GLAbstraction.Texture, TEST_2D)
)

function test()
    for (origins, gpu_arrays) in test_data
        from_gpu = map(gpu_data, gpu_arrays)
        @test from_gpu == origins
        for (origin, gpu_array) in zip(origins, gpu_arrays)
            if ndims(gpu_array) == 1
                newdata = copy(origin[11:20])
                origin[1:10] = newdata
                gpu_array[1:10] = newdata
                @test origin == gpu_data(gpu_array)
            end
        end
    end
end

test()

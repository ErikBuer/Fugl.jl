using FixedPointNumbers
const iVec2 = Vec{2, Cint}
const iVec3 = Vec{3, Cint}
const iVec4 = Vec{4, Cint}

const uVec2 = Vec{2, Cuint}
const uVec3 = Vec{3, Cuint}
const uVec4 = Vec{4, Cuint}

function test_textures()
    N = 100
    t1 = GLAbstraction.Texture(RGBA{N0f8}, (512,10), minfilter=:nearest, x_repeat=:clamp_to_edge)
    t2 = GLAbstraction.Texture(Vec{2, GLushort}, (77,91), minfilter=:nearest, x_repeat=:clamp_to_edge)

    intensity2Di = GLAbstraction.Texture(Cint[0 for i=1:N, j=1:N])
    intensity2Dui = GLAbstraction.Texture(Cuint[0 for i=1:N, j=1:N])

    rg2Df = GLAbstraction.Texture([Vec2f(0) for i=1:N, j=1:N])
    rg2Di = GLAbstraction.Texture([iVec2(0) for i=1:N, j=1:N])
    rg2Dui = GLAbstraction.Texture([uVec2(0f0) for i=1:N, j=1:N])

    rgb2Df = GLAbstraction.Texture([Vec3f(0) for i=1:N, j=1:N])
    rgb2Di = GLAbstraction.Texture([iVec3(0) for i=1:N, j=1:N])
    rgb2Dui = GLAbstraction.Texture([uVec3(0f0) for i=1:N, j=1:N])

    rgba2Df = GLAbstraction.Texture([Vec4f(0) for i=1:N, j=1:N])
    rgba2Di = GLAbstraction.Texture([iVec4(0) for i=1:N, j=1:N])
    rgba2Dui = GLAbstraction.Texture([uVec4(0f0) for i=1:N, j=1:N])


    z = Vec4f[Vec4f(0f0) for j=1:N, i=1:N]
    arraytexture = GLAbstraction.Texture(z)

    @test ndims(rgba2Df) == 2
    @test eltype(rgba2Df) == Vec4f
end

test_textures()

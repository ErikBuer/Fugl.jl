a = Vec4f(0)
b = Vec2f(2)
c = Vec4f(b..., 1,2)
d = Vec4{Int}(b..., 1,2)
d = Vec{4, UInt}(b..., 1,2)


m  = rand(Mat{4,3,Float32})
m2 = rand(Mat{3,3,Float32})


GLAbstraction.gluniform(Int32(1), a)
GLAbstraction.gluniform(Int32(1), [a,a])
GLAbstraction.gluniform(Int32(1), m)
GLAbstraction.gluniform(Int32(1), [m, m])

module GLAbstraction

using ModernGL
using FixedPointNumbers
using Printf
using StaticArrays
using ThreadPools
using Base.Threads

import FixedPointNumbers: N0f8, N0f16, N0f8, Normed

import Base: merge, resize!,  similar, length, getindex, setindex!

include("context.jl")

include("AbstractGPUArray.jl")

#Methods which get overloaded by GLExtendedFunctions.jl:
import ModernGL.glShaderSource
import ModernGL.glGetAttachedShaders
import ModernGL.glGetActiveUniform
import ModernGL.glGetActiveAttrib
import ModernGL.glGetProgramiv
import ModernGL.glGetIntegerv
import ModernGL.glGenBuffers
import ModernGL.glGetProgramiv
import ModernGL.glGenVertexArrays
import ModernGL.glGenTextures
import ModernGL.glGenFramebuffers
import ModernGL.glGetTexLevelParameteriv
import ModernGL.glGenRenderbuffers
import ModernGL.glDeleteTextures
import ModernGL.glDeleteVertexArrays
import ModernGL.glDeleteBuffers
import ModernGL.glGetShaderiv
import ModernGL.glViewport
import ModernGL.glScissor

include("utils.jl")
include("buffer.jl")
include("texture.jl")
include("framebuffer.jl")
include("uniformbuffer.jl")
include("shader/uniforms.jl")
include("shader/shader.jl")
include("shader/program.jl")
include("shader/glsl_typenames.jl")
include("vertexarray.jl")
include("conversions.jl")
include("for_moderngl.jl")
dir(dirs...) = joinpath(dirname(@__FILE__), "..", dirs...)
end # module

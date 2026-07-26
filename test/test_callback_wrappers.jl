"""
Guardrail for the ::Function -> FunctionWrapper callback migration.

Struct fields must not be typed `Function` (or contain `Function` in a Union /
type parameter): a type-erased callback field severs the static call graph, so the
callback is JIT-compiled on first interaction instead of at tree construction, and
full AOT compilation (JuliaC --trim) cannot see through it. Store callbacks as
`VoidCallback` / `StateCallback{S}` / `FunctionWrapper{...}` and coerce user input
with `wrap_callback` in the constructor (see src/callbacks.jl).

Higher-order function *arguments* are fine — this test only checks struct fields.
"""

using Test
using Fugl

# Deliberate exceptions, as "TypeName.fieldname" strings, with the reason documented here.
const FUNCTION_FIELD_ALLOWLIST = Set{String}([])

function type_contains_function(T)
    T === Function && return true
    T isa Union && return type_contains_function(T.a) || type_contains_function(T.b)
    T isa UnionAll && return type_contains_function(Base.unwrap_unionall(T))
    if T isa DataType
        for p in T.parameters
            type_contains_function(p) && return true
        end
    end
    return false
end

@testset "No type-erased ::Function struct fields" begin
    offenders = String[]
    for name in names(Fugl, all=true)
        t = try
            getfield(Fugl, name)
        catch
            continue
        end
        (t isa DataType && t.name.module === Fugl) || continue
        isabstracttype(t) && continue
        for (fname, ftype) in zip(fieldnames(t), fieldtypes(t))
            if type_contains_function(ftype)
                key = "$(t.name.name).$(fname)"
                key in FUNCTION_FIELD_ALLOWLIST || push!(offenders, "$key::$ftype")
            end
        end
    end
    if !isempty(offenders)
        @error "Type-erased Function fields found — use FunctionWrapper types from src/callbacks.jl instead:" *
               "\n" * join(["  - $o" for o in offenders], "\n")
    end
    @test isempty(offenders)
end

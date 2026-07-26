using FunctionWrappers: FunctionWrapper

"""
Fixed-signature callback types.

View structs store callbacks as `FunctionWrapper`s instead of `::Function` so the
callback's signature is pinned at construction time: building the view tree compiles
the callback (no JIT pause on first interaction) and invoking it is a fixed-ABI call
instead of dynamic dispatch. Constructors keep accepting plain closures — they are
coerced via [`wrap_callback`](@ref), so user code is unaffected.

- `VoidCallback`: `() -> nothing`
- `StateCallback{S}`: `(new_state::S) -> nothing` — used with each component's state
  type, e.g. `StateCallback{InteractionState}`, `StateCallback{EditorState}`.

Other shapes are declared inline at the field, e.g. `FunctionWrapper{Nothing,Tuple{Bool}}`.
"""
const VoidCallback = FunctionWrapper{Nothing,Tuple{}}
const StateCallback{S} = FunctionWrapper{Nothing,Tuple{S}}
const BoolCallback = FunctionWrapper{Nothing,Tuple{Bool}}
const IntCallback = FunctionWrapper{Nothing,Tuple{Int}}

"""
    wrap_callback(FW::Type{<:FunctionWrapper}, f)

Coerce a user-supplied callable `f` into the callback wrapper type `FW`.
Passes `f` through untouched if it is already the right wrapper. For
`Nothing`-returning wrappers the callable is shimmed with a discarded return value,
so closures that implicitly return their last expression are accepted.
"""
function wrap_callback(::Type{FunctionWrapper{Nothing,A}}, f) where {A<:Tuple}
    f isa FunctionWrapper{Nothing,A} && return f
    return FunctionWrapper{Nothing,A}((args...) -> (f(args...); nothing))
end

function wrap_callback(::Type{FunctionWrapper{R,A}}, f) where {R,A<:Tuple}
    f isa FunctionWrapper{R,A} && return f
    return FunctionWrapper{R,A}(f)
end

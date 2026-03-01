struct Context
    threadid::Int
    # Note: queue disabled for JuliaC compatibility - closures can't be stored/called in static compilation
end

Context() = Context(1)  # Use thread 1 for JuliaC compatibility

const GLOBAL_CONTEXT = Base.RefValue{Union{Nothing,Context}}(nothing)
# Use IdDict for better type stability with dynamic keys
const GLOBAL_CONTEXTS = IdDict{Any,Context}()

current_context() = GLOBAL_CONTEXT[]
is_current_context(x::Context) = x == GLOBAL_CONTEXT[]
is_current_context(x) =
    haskey(GLOBAL_CONTEXTS, x) && GLOBAL_CONTEXTS[x] === GLOBAL_CONTEXT[]

clear_context!() = GLOBAL_CONTEXT[] = Context()

function set_context!(x)
    if haskey(GLOBAL_CONTEXTS, x)
        c = GLOBAL_CONTEXTS[x]
        GLOBAL_CONTEXT[] = c
        # Queue system disabled for JuliaC - closures cause verifier errors
    else
        c = Context()
        GLOBAL_CONTEXTS[x] = c
        GLOBAL_CONTEXT[] = c
    end
end

function exists_context()
    if current_context() === nothing
        @error "Couldn't find valid OpenGL Context. OpenGL Context active?"
    end
end

function context_command(f::Function, c::Context)
    # Queue system disabled for JuliaC compatibility
    # Always execute immediately on current thread
    if !is_current_context(c)
        @warn "Context command called on non-current context - executing anyway for JuliaC compatibility"
    end
    try
        f()
    catch e
        @warn "Error executing context command" exception = (e, catch_backtrace())
    end
end

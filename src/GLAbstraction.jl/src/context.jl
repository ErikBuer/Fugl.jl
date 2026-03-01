struct Context
    threadid::Int # So that the thread that the context is associated with calls the opengl operations in the queue
    queue::Vector{Function} # Closures to be executed when the context becomes current again
end

Context() = Context(threadid(), Function[])

Base.push!(c::Context, f::Function) = push!(c.queue, f)

const GLOBAL_CONTEXT = Base.RefValue{Union{Nothing,Context}}(nothing)
const GLOBAL_CONTEXTS = Dict{Any, Context}()

current_context() = GLOBAL_CONTEXT[]
is_current_context(x::Context) = x == GLOBAL_CONTEXT[]
is_current_context(x) =
    haskey(GLOBAL_CONTEXTS, x) && GLOBAL_CONTEXTS[x] === GLOBAL_CONTEXT[]
    
clear_context!() = GLOBAL_CONTEXT[] = Context()

function set_context!(x)
    if haskey(GLOBAL_CONTEXTS, x)
        c = GLOBAL_CONTEXTS[x]
        GLOBAL_CONTEXT[] = c
        @tspawnat c.threadid begin
            for f in c.queue
                f()
            end
            empty!(c.queue)
        end
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
    if !is_current_context(c)
        push!(c, f)
    else
        @tspawnat c.threadid f()
    end
end

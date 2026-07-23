using Test
using Fugl
using Fugl: AbstractView, InputState, VerticalScrollArea, VerticalScrollState,
    reset_input_clip!, detect_click, inside_component, push_input_clip!, pop_input_clip!,
    with_input_clip, pointer_in_clip, hit_test, intersect_rect

# GL-free probe: records whether its detect_click was reached (visitation) and what the
# clip-aware `inside_component` computed at the pointer, so we can assert the input pass's
# recursion + clipping behavior headlessly.
struct _ClipProbe <: AbstractView
    visited::Ref{Bool}
    inside::Ref{Bool}
    height::Float32
end
Fugl.measure(::_ClipProbe) = (50.0f0, 50.0f0)
Fugl.measure_height(p::_ClipProbe, ::Float32) = p.height
Fugl.measure_width(::_ClipProbe, ::Float32) = 50.0f0
Fugl.preferred_height(::_ClipProbe) = true
Fugl.interpret_view(::_ClipProbe, x, y, w, h, pm, cp, ws) = nothing
function Fugl.detect_click(p::_ClipProbe, ms::InputState, x::Float32, y::Float32, w::Float32, h::Float32, pz::Int32)
    p.visited[] = true
    p.inside[] = inside_component(p, x, y, w, h, Float32(ms.x), Float32(ms.y))
    return nothing
end

# Drive one detect_click pass over a probe wrapped in a 200x100 VerticalScrollArea whose
# content is 200 tall (so the bottom half is clipped away by the viewport).
function _probe_case(px::Float32, py::Float32)
    visited = Ref(false)
    inside = Ref(false)
    probe = _ClipProbe(visited, inside, 200.0f0)
    scroll = VerticalScrollArea(probe; scroll_state=VerticalScrollState(), show_scrollbar=false)
    ms = InputState()
    ms.x = px
    ms.y = py
    reset_input_clip!()
    detect_click(scroll, ms, 0.0f0, 0.0f0, 200.0f0, 100.0f0, Int32(0))
    return visited[], inside[]
end

@testset "Input clip stack" begin
    @testset "intersect_rect (shared with scissor stack)" begin
        @test intersect_rect((0.0f0, 0.0f0, 10.0f0, 10.0f0), (5.0f0, 5.0f0, 10.0f0, 10.0f0)) ==
              (5.0f0, 5.0f0, 5.0f0, 5.0f0)
        # Non-overlapping -> zero area
        @test intersect_rect((0.0f0, 0.0f0, 5.0f0, 5.0f0), (10.0f0, 10.0f0, 5.0f0, 5.0f0)) ==
              (10.0f0, 10.0f0, 0.0f0, 0.0f0)
        # Nested clips only shrink
        @test intersect_rect((0.0f0, 0.0f0, 100.0f0, 100.0f0), (10.0f0, 10.0f0, 20.0f0, 20.0f0)) ==
              (10.0f0, 10.0f0, 20.0f0, 20.0f0)
    end

    @testset "pointer_in_clip / hit_test / nesting" begin
        reset_input_clip!()
        @test pointer_in_clip(9999.0f0, 9999.0f0)  # no clip -> always inside
        push_input_clip!(0.0f0, 0.0f0, 100.0f0, 50.0f0)
        @test pointer_in_clip(10.0f0, 10.0f0)
        @test !pointer_in_clip(10.0f0, 80.0f0)          # below the clip
        @test hit_test(0.0f0, 0.0f0, 40.0f0, 40.0f0, 10.0f0, 10.0f0)
        @test !hit_test(0.0f0, 0.0f0, 40.0f0, 100.0f0, 10.0f0, 80.0f0)  # in bounds, outside clip
        # Nested clip can only shrink the effective region
        push_input_clip!(0.0f0, 0.0f0, 20.0f0, 50.0f0)
        @test !pointer_in_clip(30.0f0, 10.0f0)          # excluded by inner clip
        pop_input_clip!()
        @test pointer_in_clip(30.0f0, 10.0f0)           # restored to outer clip
        pop_input_clip!()
        @test pointer_in_clip(10.0f0, 80.0f0)           # fully unclipped again
    end

    @testset "with_input_clip restores on throw" begin
        reset_input_clip!()
        @test_throws ErrorException with_input_clip(0.0f0, 0.0f0, 10.0f0, 10.0f0) do
            error("boom")
        end
        @test Fugl.current_input_clip() === nothing
    end

    @testset "ScrollArea: unconditional recursion + clipped hit-testing" begin
        # Pointer inside the viewport, over the probe -> visited AND hit.
        v1, i1 = _probe_case(10.0f0, 50.0f0)
        @test v1
        @test i1

        # Pointer inside the probe's layout rect (0..200) but below the viewport bottom
        # (100): the probe must still be VISITED (recursion is unconditional, so a focused
        # or hovered descendant stays reachable) but must NOT be hit (clip excludes it).
        v2, i2 = _probe_case(10.0f0, 150.0f0)
        @test v2
        @test !i2

        # Pointer far outside the scroll area entirely: still visited (subtree never
        # starved -> hover can clear, keys still reach a focused field), never hit.
        v3, i3 = _probe_case(500.0f0, 500.0f0)
        @test v3
        @test !i3
    end
end

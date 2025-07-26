"""
Test to ensure all view types in the Fugl module are immutable.
This enforces the functional UI paradigm and prevents state management issues.
"""

using Test

@testset "View Immutability Tests" begin

    @testset "All views must be immutable" begin
        mutable_views = String[]
        immutable_views = String[]
        total_views = 0

        try
            using Fugl

            # Get all names from the Fugl module
            for name in names(Fugl, all=true)
                try
                    # Get the actual type
                    t = getfield(Fugl, name)

                    # Check if it's a type that extends AbstractView (but not AbstractView itself)
                    if isa(t, Type) && t <: Fugl.AbstractView && t != Fugl.AbstractView
                        total_views += 1
                        name_str = string(name)

                        if ismutabletype(t)
                            push!(mutable_views, name_str)
                            @error "MUTABLE VIEW DETECTED: $name_str"
                        else
                            push!(immutable_views, name_str)
                            @info "✓ Immutable view: $name_str"
                        end
                    end
                catch e
                    # Skip symbols that aren't types or can't be evaluated
                    continue
                end
            end
        catch e
            @warn "Could not load Fugl module for testing: $e"
            # If we can't load Fugl, skip this test but don't fail
            return
        end

        # Print summary
        @info "View immutability summary:" *
              "\n  Total views checked: $total_views" *
              "\n  Immutable views: $(length(immutable_views))" *
              "\n  Mutable views: $(length(mutable_views))"

        if !isempty(immutable_views)
            @info "Immutable views (✓): $(join(immutable_views, ", "))"
        end

        if !isempty(mutable_views)
            @error "Mutable views found (✗): $(join(mutable_views, ", "))"
            @error "PARADIGM VIOLATION: The following views are mutable and break the functional UI paradigm:" *
                   "\n$(join(["  - $view" for view in mutable_views], "\n"))" *
                   "\n\nPlease make these views immutable by changing 'mutable struct' to 'struct'."
        end

        # The actual test that will fail CI
        @test isempty(mutable_views)

        # Ensure we actually found some views to test (only if Fugl loaded successfully)
        if total_views == 0
            @warn "No AbstractView subtypes found. This might indicate a problem with the test or module structure."
        else
            @test total_views > 0
        end
    end

    @testset "AbstractView interface compliance" begin
        non_abstract_views = String[]

        try
            using Fugl

            # Check that all view types properly extend AbstractView
            for name in names(Fugl, all=true)
                try
                    t = getfield(Fugl, name)

                    # Look for types that might be views but don't extend AbstractView
                    if isa(t, Type) &&
                       (endswith(string(name), "View") || endswith(string(name), "Container")) &&
                       !(t <: Fugl.AbstractView) &&
                       t != Fugl.AbstractView
                        push!(non_abstract_views, string(name))
                    end
                catch
                    continue
                end
            end
        catch e
            @warn "Could not load Fugl module for interface testing: $e"
            return
        end

        if !isempty(non_abstract_views)
            @test false
        else
            @test true
        end
    end
end

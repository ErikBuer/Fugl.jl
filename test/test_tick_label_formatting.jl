"""
Tests for tick label formatting: `format_tick_label`, `step_decimals` and
`superscript_exponent` (src/composite_components/plot/utilities.jl).
These are pure functions — no OpenGL context is needed.
"""

using Test
using Fugl: format_tick_label, step_decimals, superscript_exponent, resolve_tick_offset, format_axis_offset

@testset "Tick Label Formatting" begin

    @testset "superscript_exponent" begin
        @test superscript_exponent(0) == "⁰"
        @test superscript_exponent(7) == "⁷"
        @test superscript_exponent(-3) == "⁻³"
        @test superscript_exponent(10) == "¹⁰"
        @test superscript_exponent(-12) == "⁻¹²"
    end

    @testset "step_decimals" begin
        @test step_decimals(1.0) == 0
        @test step_decimals(2.0e7) == 0
        @test step_decimals(0.1) == 1
        @test step_decimals(0.25) == 2   # not a power of ten: needs 2 decimals
        @test step_decimals(0.008) == 3
        # Float32 noise must not inflate the decimal count
        @test step_decimals(Float64(0.1f0)) == 1
        @test step_decimals(Float64(0.33f0 * 5 / 5)) == 2
    end

    @testset "special values" begin
        @test format_tick_label(0.0, 4) == "0"
        @test format_tick_label(NaN, 4) == "NaN"
        @test format_tick_label(Inf, 4) == "Inf"
    end

    @testset "plain notation within significant digits" begin
        @test format_tick_label(0.25, 4) == "0.25"
        @test format_tick_label(-0.25, 4) == "-0.25"
        # With 4 significant digits, everything in ±9999 stays plain
        @test format_tick_label(9999.0, 4; step=1.0) == "9999"
        @test format_tick_label(-9999.0, 4; step=1.0) == "-9999"
        @test format_tick_label(5000.0, 4; step=2500.0) == "5000"
        # The first magnitude past the budget switches to scientific
        @test format_tick_label(10000.0, 4; step=2500.0) == "1×10⁴"
        @test format_tick_label(0.123456789, 4) == "0.1235"
        @test format_tick_label(0.008917, 4) == "8.917×10⁻³"
        @test format_tick_label(5.05000, 4) == "5.05"
    end

    @testset "integer ticks drop trailing decimals" begin
        @test format_tick_label(4.0, 4; step=2.0) == "4"
        @test format_tick_label(5.0, 4; step=1.0) == "5"
    end

    @testset "scientific notation for extreme magnitudes" begin
        @test format_tick_label(123456.0, 4) == "1.235×10⁵"
        @test format_tick_label(1.5e7, 7) == "1.5×10⁷"
        @test format_tick_label(2.4e-5, 4; step=8.0e-6) == "2.4×10⁻⁵"
        @test format_tick_label(-2.4e-5, 4; step=8.0e-6) == "-2.4×10⁻⁵"
        # Mantissa rounding into the next decade bumps the exponent
        @test format_tick_label(99999.0, 4) == "1×10⁵"
        # Integer mantissas drop the superfluous ".0"
        @test format_tick_label(1.0e-5, 4; step=5.0e-6) == "1×10⁻⁵"
        # Residual noise far below the tick resolution collapses to zero
        @test format_tick_label(8.0e-9, 4; step=5.0e-6) == "0"
    end

    @testset "step keeps adjacent ticks distinct" begin
        # Regression: these used to collapse onto "0.1"
        labels = [format_tick_label(v, 4; step=0.008) for v in 0.096:0.008:0.12]
        @test labels == ["0.096", "0.104", "0.112", "0.12"]
        @test allunique(labels)
    end

    @testset "ticks off the step grid" begin
        # Regression: rings at 0.5, 1.5, … with step 1 rounded to 0 and fell
        # back to scientific notation ("5×10⁻¹")
        labels = [format_tick_label(v, 4; step=1.0) for v in 0.5:1.0:4.5]
        @test labels == ["0.5", "1.5", "2.5", "3.5", "4.5"]
    end

    @testset "Float32 noise" begin
        @test format_tick_label(4.9999995f0, 4; step=1.0f0) == "5"
        @test format_tick_label(0.3f0, 4; step=0.1f0) == "0.3"
        # Steps accumulated in Float32 must not inflate the decimal count
        @test step_decimals(Float64(5.09f0 - 5.085f0)) == 3
    end

    @testset "deep zoom axis offset" begin
        # Ordinary axes need no offset
        @test resolve_tick_offset(Float32[0.0, 0.2, 0.4], 4) == 0.0
        @test resolve_tick_offset(Float32[5.085, 5.09, 5.095, 5.1], 5) == 0.0
        @test resolve_tick_offset(Float32[], 4) == 0.0

        # Deep zoom: large shared value, tiny spacing → offset kicks in,
        # anchored exactly on the first tick so residuals are step multiples
        ticks = Float32[0.4599994, 0.4600044, 0.4600094, 0.4600144]
        offset = resolve_tick_offset(ticks, 4)
        @test offset == Float64(ticks[1])

        # Residual labels are short and distinct, first one is "0"
        step = Float64(ticks[2]) - Float64(ticks[1])
        labels = [format_tick_label(Float64(t) - offset, 4; step=step) for t in ticks]
        @test labels[1] == "0"
        @test allunique(labels)
        @test all(length(l) <= 8 for l in labels)

        # The annotation shows the offset at full step resolution
        @test format_axis_offset(0.06682935, 5.0e-7) == "+0.06682935"
        @test format_axis_offset(-5.085, 0.005) == "-5.085"
    end

    @testset "leading zeros decide the plain/scientific boundary" begin
        # Default allows one leading zero after the decimal point
        @test format_tick_label(0.01, 3) == "0.01"
        @test format_tick_label(0.05, 3) == "0.05"
        @test format_tick_label(0.008917, 4) == "8.917×10⁻³" # two leading zeros → scientific
        @test format_tick_label(1.0e-4, 3) == "1×10⁻⁴"
        @test format_tick_label(1.0e-5, 3) == "1×10⁻⁵"
        # The allowance is tunable
        @test format_tick_label(0.008917, 4; max_leading_zeros=2) == "0.008917"
        @test format_tick_label(0.05, 3; max_leading_zeros=0) == "5×10⁻²"
    end
end

#!/usr/bin/env julia

using Fugl
using Fugl: Text, TextStyle

function test_oversampling_quality()
    function MyApp()
        Container(
            Column([
                    Text("Oversampling Quality Comparison", style=TextStyle(size_px=20)),

                    # No oversampling (aliased)
                    Row([
                            Text("1x (No oversampling):", style=TextStyle(size_px=14)),
                            Rotate(Text("45° Aliased Text"), rotation_degrees=45.0f0, oversample_factor=1)
                        ], spacing=20.0),

                    # 2x oversampling (better)
                    Row([
                            Text("2x oversampling:", style=TextStyle(size_px=14)),
                            Rotate(Text("45° Better Text"), rotation_degrees=45.0f0, oversample_factor=2)
                        ], spacing=20.0),

                    # 4x oversampling (best)
                    Row([
                            Text("4x oversampling:", style=TextStyle(size_px=14)),
                            Rotate(Text("45° Best Text"), rotation_degrees=45.0f0, oversample_factor=4)
                        ], spacing=20.0),

                    # Auto quality (smart)
                    Row([
                            Text("Auto quality:", style=TextStyle(size_px=14)),
                            Rotate(Text("45° Auto Text"), rotation_degrees=45.0f0)  # Uses auto
                        ], spacing=20.0),

                    # Different angles with auto quality
                    Text("Various angles (auto quality):", style=TextStyle(size_px=14)),
                    Row([
                            Rotate(Text("30°"), rotation_degrees=30.0f0),
                            Rotate(Text("60°"), rotation_degrees=60.0f0),
                            Rotate(Text("90°"), rotation_degrees=90.0f0),
                            Rotate(Text("135°"), rotation_degrees=135.0f0)
                        ], spacing=30.0),

                    # Container with oversampling
                    Rotate(
                        Container(
                            Column([
                                Text("Oversampled"),
                                Text("Container")
                            ]),
                            style=ContainerStyle(
                                background_color=Vec4{Float32}(0.3f0, 0.5f0, 0.8f0, 1.0f0),
                                border_color=Vec4{Float32}(0.1f0, 0.3f0, 0.6f0, 1.0f0),
                                border_width=2.0f0,
                                padding=15.0f0
                            )
                        ),
                        rotation_degrees=25.0f0,
                        oversample_factor=4  # High quality for crisp borders
                    )], spacing=25.0, padding=30.0)
        )
    end

    Fugl.run(MyApp, title="Oversampling Quality Test", window_width_px=700, window_height_px=600)
end

test_oversampling_quality()

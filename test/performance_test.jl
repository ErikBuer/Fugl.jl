using Fugl
using Fugl: Text

function performance_test()
    # Create a large amount of text to test rendering performance
    large_text = repeat("The quick brown fox jumps over the lazy dog. ", 100)

    function TestApp()
        IntrinsicColumn([
            Container(Text("Performance Test - Batched Text Rendering", style=TextStyle(size_px=24))),
            Container(Text("This is a large text block to test rendering performance:", style=TextStyle(size_px=16))),
            Container(Text(large_text, style=TextStyle(size_px=14))),
            Container(Text("Check the FPS counter in the top-right corner!", style=TextStyle(size_px=16))),
        ])
    end

    # Run with debug overlay enabled to see FPS
    Fugl.run(TestApp, title="Text Rendering Performance Test", window_width_px=1000, window_height_px=800, debug_overlay=true)
end

performance_test()

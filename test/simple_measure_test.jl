using Fugl
using Fugl: Text

function simple_measure_test()
    # Test texts of different lengths
    texts = [
        Text("Short"),
        Text("Medium text"),
        Text("This is a longer text that will wrap when constrained")
    ]

    # Test Column
    column = Column(texts, spacing=8.0f0, padding=10.0f0)

    # Test Row  
    row = Row(texts, spacing=12.0f0, padding=10.0f0)


    # Visual demonstration
    Column([
            Card("Column with IntrinsicSize", IntrinsicSize(column)),
            Card("Row with IntrinsicSize", IntrinsicSize(row)),
            Text("See console for measurement details",
                style=TextStyle(size_px=12, color=Vec4f(0.6, 0.6, 0.6, 1.0)))
        ], spacing=15.0f0, padding=20.0f0)
end


Fugl.run(simple_measure_test,
    title="Measure Width/Height Test",
    window_width_px=800,
    window_height_px=600
)


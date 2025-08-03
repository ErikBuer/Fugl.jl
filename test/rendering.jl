using Fugl

using TestItems


@testitem "Generate Container" begin
    function MyApp()
        Row([
            Container(on_click=() -> println("Clicked on Container 1")),
            Container(),
            Column([Container(), Container(), Container(Container())], padding=0)
        ])
    end

    # Save a screenshot of the UI
    Fugl.screenshot(MyApp, "test_output/ui_screenshot.png", 400, 300)
end

@testitem "Test Text" begin
    using Fugl: Text

    function MyApp()
        Container(
            Text("Some text")
        )
    end

    # Save a screenshot of the UI
    Fugl.screenshot(MyApp, "test_output/text_screenshot.png", 400, 300)
end


@testitem "Test Column Measure" begin
    using Fugl: Text

    function MyApp()
        IntrinsicHeight(
            Container(
                Row([
                    TextButton("Run", on_click=() -> println("Clicked")),
                    Text("Top bar")
                ])
            )
        )
    end

    # Save a screenshot of the UI
    Fugl.screenshot(MyApp, "test_output/column_mesure.png", 400, 300)
end

@testitem "Test Row Measure" begin
    using Fugl: Text

    function MyApp()
        IntrinsicWidth(
            Container(
                Column([
                    TextButton("Run", on_click=() -> println("Clicked")),
                    Text("Side bar")
                ])
            )
        )
    end

    # Save a screenshot of the UI
    Fugl.screenshot(MyApp, "test_output/row_measure.png", 400, 300)
end

@testitem "Test orthographic Projection Matrix" begin
    projection_matrix = Fugl.get_orthographic_matrix(0.0, 1920.0, 1080.0, 0.0, -1.0, 1.0)

    vertex1 = Float32[0.0, 0.0, 0.0, 1.0]

    vertex_ndc = projection_matrix * vertex1
    @test vertex_ndc[1:2] == [-1.0, 1.0]

    vertex2 = Float32[1920/2, 1080/2, 0.0, 1.0]
    vertex_ndc2 = projection_matrix * vertex2
    @test vertex_ndc2[1:2] == [0.0, 0.0]
end
"""
A simple card component that can be used to display a title and content in a styled container.
"""
function Card(title::AbstractString="", content::AbstractView=EmptyView(); style=ContainerStyle(), title_style=TextStyle(), title_align=:left)

    cardContents = IntrinsicColumn([
            IntrinsicHeight(Text(title; style=title_style, horizontal_align=title_align)),
            HLine(end_length=style.padding_px),
            content
        ], padding=0.0, spacing=5.0f0
    )

    return Container(
        cardContents;
        style=style
    )
end
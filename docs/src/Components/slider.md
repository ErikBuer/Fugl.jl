# Sliders

``` @example HorizontalSliderExample
using Fugl

# Ref for maintining the slider state
slider_value = Ref(0.5f0)

function MyApp()
    Container(
        HorizontalSlider(
            slider_value[],
            0.0f0,              # min value
            1.0f0;              # max value
            on_change=(new_value) -> (slider_value[] = new_value)
        )
    )
end

screenshot(MyApp, "horizontal_slider.png", 812, 100);
nothing #hide
```

![Horizontal slider example](horizontal_slider.png)

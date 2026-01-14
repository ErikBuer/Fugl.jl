using Fugl

# Test to isolate Delete key issue
state = Ref(EditorState("test123"))
numberstate = Ref(EditorState("123"))

function test_delete_key()
    IntrinsicColumn([
            Fugl.Text("NumberField Delete Test"),

            # Regular TextBox for comparison
            Card("Regular TextBox",
                TextBox(
                    state[];
                    on_state_change=(new_state) -> begin
                        state[] = new_state
                        #println("TextBox: '$(new_state.text)' focused: $(new_state.is_focused)")
                    end
                )
            ),

            # NumberField
            Card("NumberField",
                NumberField(
                    numberstate[];
                    type=Float32,
                    on_state_change=(new_state) -> begin
                        numberstate[] = new_state
                        #println("NumberField: '$(new_state.text)' focused: $(new_state.is_focused)")
                    end,
                    on_change=(value) -> println("NumberField parsed: $value")
                )
            ), Fugl.Text("Instructions: Select text and press Delete key")
        ]; spacing=10.0f0)
end

Fugl.run(test_delete_key, title="Delete Key Test", window_width_px=600, window_height_px=400)
using Fugl

"""
Test that Cmd+A (Select All) works correctly from any cursor position
"""
function test_select_all_functionality()
    println("Testing Select All functionality...")

    # Test 1: Select all from beginning
    test_text = "Hello world\nThis is a test\nAnother line"
    editor_state = EditorState(test_text)
    
    # Apply select all action
    select_all_action = SelectAll()
    state_after_select = apply_editor_action(editor_state, select_all_action)
    
    println("After Select All from beginning:")
    println("  cursor: $(state_after_select.cursor)")
    println("  selection_start: $(state_after_select.selection_start)")
    println("  selection_end: $(state_after_select.selection_end)")
    println("  has_selection: $(has_selection(state_after_select))")
    
    @assert has_selection(state_after_select), "Should have selection after Select All"
    
    # Test 2: Select all from end of text
    lines = get_lines(editor_state)
    last_line = lines[end]
    end_cursor = CursorPosition(length(lines), length(collect(last_line)) + 1)
    
    editor_at_end = EditorState(
        editor_state.text,
        end_cursor,  # Cursor at end
        editor_state.is_focused,
        editor_state.selection_start,
        editor_state.selection_end,
        editor_state.cached_lines,
        editor_state.text_hash
    )
    
    state_after_select_from_end = apply_editor_action(editor_at_end, select_all_action)
    
    println("\nAfter Select All from end:")
    println("  cursor: $(state_after_select_from_end.cursor)")
    println("  selection_start: $(state_after_select_from_end.selection_start)")
    println("  selection_end: $(state_after_select_from_end.selection_end)")
    println("  has_selection: $(has_selection(state_after_select_from_end))")
    
    @assert has_selection(state_after_select_from_end), "Should have selection after Select All from end"
    
    # Verify both selections are the same
    start1, end1 = get_selection_range(state_after_select)
    start2, end2 = get_selection_range(state_after_select_from_end)
    
    @assert start1 == start2 && end1 == end2, "Selection should be same regardless of cursor position"
    
    println("\n✅ Select All functionality test passed!")
end

# Run the test
test_select_all_functionality()

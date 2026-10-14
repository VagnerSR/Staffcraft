@tool
extends EditorScript


func _run() -> void:
	var cases := TestCases.get_cases()
	var failed := 0

	for case_name in cases:
		var case: Dictionary = cases[case_name]
		var result := Pipeline.evaluate(case["build"])
		var bad: Array[String] = []
		for key in case["expect"]:
			if result.get(key) != case["expect"][key]:
				bad.append("     %s: expected %s, got %s" % [key, case["expect"][key], result.get(key)])

		if bad.is_empty():
			print("ok   ", case_name)
		else:
			failed += 1
			print("FAIL ", case_name)
			for line in bad:
				print(line)

	if failed == 0:
		print("\nAll %d tests passed" % cases.size())
	else:
		print("\n%d test(s) failed" % failed)

extends LineEdit

onready var expression = Expression.new()

func _ready():
	connect("text_entered", self, "_on_text_entered")

func _on_text_entered(command):
	var error = expression.parse(command, [])
	if error != OK:
		print(expression.get_error_text())
		return
	var result = expression.execute([], null, true)
	if not expression.has_execute_failed():
		text = str(result)

tool
extends Label


var new_error
var displayed_error

func _on_script_error(error):
	if error:
		new_error = error
		$Timer.start()
	else:
		self.text = ""
		$Timer.stop()


func _on_timeout():
	if new_error != displayed_error:
		push_error(new_error)
	self.text = new_error
	displayed_error = new_error

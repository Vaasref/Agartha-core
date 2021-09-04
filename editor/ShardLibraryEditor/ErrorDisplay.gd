tool
extends Label


var new_error

func _on_script_error(error):
	if error:
		new_error = error
		$Timer.start()
	else:
		self.text = ""
		$Timer.stop()


func _on_timeout():
	self.text = new_error

extends Resource
class_name StoreSave

export var state_stack:Array
export var current_state:Resource
export var encoded_image:Array
export var game_version:String
export var save_compatibility_code:String
export var save_script_compatibility_code:String



func encode_image(img:Image, resize:Vector2=Vector2(160, 90)):
	var out = [0, ""]
	
	img = img.duplicate()
	img.resize(resize.x, resize.y, Image.INTERPOLATE_TRILINEAR)
	var buffer:PoolByteArray = img.save_png_to_buffer()
	out[0] = buffer.size()
	buffer = buffer.compress()
	out[1] = buffer.get_string_from_ascii()
	
	return out


func decode_image(buf:Array):
	var out:Image = Image.new()
		
	var buffer = buf[1].to_ascii()
	buffer = buffer.decompress(buf[0])
	out.load_png_from_buffer(buffer)
	
	return out


func get_script_compatibility_code():
	return "7bbee" # This code should only change when this script is made incompatible with previous version.

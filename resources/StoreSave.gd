extends Resource
class_name StoreSave

export var name:String
export var date:Dictionary
export var state_stack:Array
export var current_state:Resource
export var encoded_image:String
export var game_version:String
export var save_compatibility_code:String
export var save_script_compatibility_code:String


func init_compatibility_features():
	game_version = Agartha.Settings.get("agartha/application/game_version")
	save_script_compatibility_code = get_script_compatibility_code()
	save_compatibility_code = Agartha.Settings.get("agartha/saves/compatibility/compatibility_code")

func init_date():
	date = OS.get_datetime()
	date.erase('dst')
	date.erase('second')
	date.erase('weekday')

func encode_image(img:Image, resize:Vector2=Vector2(256, 144)):
	img = img.duplicate()
	img.resize(resize.x, resize.y, Image.INTERPOLATE_TRILINEAR)
	var buffer:PoolByteArray = img.save_png_to_buffer()
	return buffer.hex_encode()


func decode_image(encoded_img):
	var out:Image = Image.new()
	

	var buffer = PoolByteArray()
	var char_buffer = encoded_img.to_ascii()
	buffer.resize(char_buffer.size()/2)

	for i in buffer.size():
		var v = char_buffer[i*2]
		var u = char_buffer[i*2+1]
		if v > 96:
			if u > 96:
				buffer[i] = ((v-87) << 4) + (u-87)
			else:
				buffer[i] = ((v-87) << 4) + (u-48)
		else:
			if u > 96:
				buffer[i] = ((v-48) << 4) + (u-87)
			else:
				buffer[i] = ((v-48) << 4) + (u-48)

	out.load_png_from_buffer(buffer)
	
	return out


func get_screenshot_image():
	return decode_image(self.encoded_image)


func get_screenshot_texture():
	var texture = ImageTexture.new()
	var image = decode_image(self.encoded_image)
	texture.create_from_image(image, image.get_format())
	return texture


func get_script_compatibility_code():
	return "7bbee" # This code should only change when this script is made incompatible with previous version.

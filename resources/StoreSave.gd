extends Resource
class_name StoreSave

#Metadata
export var name:String
export var date:Dictionary
export var encoded_image:String
#Data
export var state_stack:Array
export var current_state:Array
export var current_state_id:int
#Compatibility
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
	
	return Marshalls.raw_to_base64(buffer)


func decode_image(encoded_img):
	var out:Image = Image.new()
	
	out.load_png_from_buffer(Marshalls.base64_to_raw(encoded_img))
	
	return out


func get_screenshot_image():
	return decode_image(self.encoded_image)


func get_screenshot_texture():
	var texture = ImageTexture.new()
	var image = decode_image(self.encoded_image)
	texture.create_from_image(image, image.get_format())
	return texture


func get_script_compatibility_code():
	return "87e3b" # This code should only change when this script is made incompatible with previous version.

func is_compatible():
	return Agartha.Saver.check_save_compatibility(self ,false) == Agartha.Saver.COMPATIBILITY_ERROR.NO_ERROR

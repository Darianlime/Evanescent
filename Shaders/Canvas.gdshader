shader_type canvas_item;
#include "res://shaders/spiral.gdshaderinc"
uniform vec3 pink_color : source_color = vec3(1.0,0.66,0.94);
uniform vec3 pink_color_2 : source_color = vec3(0.901,0.478,0.62);
uniform vec3 blue_color : source_color = vec3(0.0,0.64,1.0);
void fragment() {
    COLOR = spiral_color(texture(TEXTURE, UV), SCREEN_UV, pink_color_2, blue_color);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}

//vec4 texColor = texture(screen_texture, SCREEN_UV);
	//vec3 weights = vec3(0.2126, 0.7152, 0.0722);
	//float gray = dot(texColor.rgb, weights);
	//COLOR = vec4(gray*2.4,0,gray*1.6, texColor.a);
	
	//vec4 texColor = texture(screen_texture, SCREEN_UV);
	//vec3 weights = vec3(0.2126, 0.7152, 0.0722);
	//float gray = dot(texColor.rgb, weights);
	 //// Preserve brightness variation while using a stronger pink palette.
    //vec3 pinkColor = vec3(
        //gray * 2.3,
        //gray * 1.2,
        //gray * 1.86
    //);
//
    //vec3 result = mix(vec3(gray), pinkColor, intensity);
//
    //COLOR = vec4(result, texColor.a);

-module(gl_const).
-compile(nowarn_export_all).
-compile(export_all).

-include_lib("wx/include/gl.hrl").

gl_depth_test() -> ?GL_DEPTH_TEST.

gl_lequal() -> ?GL_LEQUAL.
gl_color_buffer_bit() -> ?GL_COLOR_BUFFER_BIT.

gl_depth_buffer_bit() -> ?GL_DEPTH_BUFFER_BIT.

gl_triangles() -> ?GL_TRIANGLES.
gl_array_buffer() -> ?GL_ARRAY_BUFFER.
gl_element_array_buffer() -> ?GL_ELEMENT_ARRAY_BUFFER.
gl_static_draw() -> ?GL_STATIC_DRAW.

gl_vertex_shader() -> ?GL_VERTEX_SHADER.
gl_fragment_shader() -> ?GL_FRAGMENT_SHADER.

gl_compile_status() -> ?GL_COMPILE_STATUS.
gl_link_status() -> ?GL_LINK_STATUS.

gl_float() -> ?GL_FLOAT.
gl_false() -> ?GL_FALSE.
gl_true() -> ?GL_TRUE.
gl_unsigned_int() -> ?GL_UNSIGNED_INT.

gl_front_and_back() -> ?GL_FRONT_AND_BACK.
gl_line() -> ?GL_LINE.
gl_fill() -> ?GL_FILL.
gl_debug_output() -> ?GL_DEBUG_OUTPUT.
gl_texture_2d() -> ?GL_TEXTURE_2D.
gl_rgb() -> ?GL_RGB.
gl_rgba() -> ?GL_RGBA.
gl_multisample() -> ?GL_MULTISAMPLE.

gl_cull_face() -> ?GL_CULL_FACE.
gl_back() -> ?GL_BACK.
gl_front() -> ?GL_FRONT.
gl_ccw() -> ?GL_CCW.
gl_cw() -> ?GL_CW.

gl_info_log_length() -> ?GL_INFO_LOG_LENGTH.

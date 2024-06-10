#version 410 core

layout (location = 0) in vec3 position;
// layout (location = 1) in vec3 instance_offset;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

void main()
{
    // gl_Position = projection * view * model * vec4(position + instance_offset, 1.0);
    gl_Position = projection * view * model * vec4(position, 1.0);
}
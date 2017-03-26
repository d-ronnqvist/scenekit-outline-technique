// Input attributes
attribute vec4 a_position;
attribute vec4 a_normal;

// Input transforms
uniform mat4 modelViewProjection;
uniform mat4 normalTransform;

// Output to fragment shader
varying vec3 normal;

void main() {
    gl_Position = modelViewProjection * a_position;

    normal = vec3(normalTransform * a_normal);
}

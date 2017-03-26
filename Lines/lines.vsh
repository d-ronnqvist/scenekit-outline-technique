attribute vec4 a_position;

varying vec2 uv;

void main() {
    // This is just drawing a quad.
    // Pass the same output vertex position as the input
    gl_Position = a_position;

    // Calculate the texture coordinate
    // The position here is a within a [-1, 1] square
    uv = (a_position.xy + 1.0) * 0.5;
}

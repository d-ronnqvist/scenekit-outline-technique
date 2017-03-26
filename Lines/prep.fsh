// Input from the vertex shader
varying vec3 normal;

void main() {
    // Output of the "prep" step.
    // This is rendered to the NORMALS target
    gl_FragColor = vec4(normalize(normal), 1.0);
}

uniform sampler2D colorSampler;  // The color, rendered from the default Step 0
uniform sampler2D depthSampler;  // The depth, rendered from the default Step 0
uniform sampler2D normalSampler; // The normals, rendered from "prep-step"

varying vec2 uv; // The texture coordinate the quad

// The lines are drawn by comparing the differences between nearby pixels.
// If the average difference is too small, no line is drawn.
// If the average difference is large enough, a completely black line is drawn.
// In between the values is smoothly interpolated between these threshold values.

float edgeAmount(vec2 pixelCoord, sampler2D texture, int colorToCompare, float multiplier) {
    float dx = 1.0 / 512.0; // image width
    float dy = 1.0 / 512.0; // image height

    // If we'd just compare against the actual neighboring pixel the difference
    // would be so small. Instead we compare against the pixels twice the distance
    // away:  ('x' = sampled, '_' = stepped over, 'o' = this pixel)
    //   x _ x _ x
    //   _ _ _ _ _
    //   x _ o _ x
    //   _ _ _ _ _
    //   x _ x _ x
    float scale = 2.0;
    dx *= scale;
    dy *= scale;

    // This pixel (index 4) and the eight surrounding pixels
    // (with two pixel step size, see above)
    //   0 1 2
    //   3 4 5
    //   6 7 8
    float pixelValues[9];

    // Loop over [-1, 0, 1] for rows and columns to read the pixel values
    int pixelIndex = 0;
    for (int i=-1; i<=1; i++) {
        for (int j=-1; j<=1; j++) {

            // Sample at an offset from this pixel coordinate.
            vec2 offset = vec2(float(i) * dx,
                               float(j) * dy);
            vec4 pixel = texture2D(texture,
                                   pixelCoord + offset);

            // Store only the component we care about (for example: red, green, blue)
            pixelValues[pixelIndex] = pixel[colorToCompare];

            pixelIndex++;
        }
    }

    // Average difference between pairs of horizontal, vertical, and diagonals
    //   0 1 2
    //   3 4 5
    //   6 7 8
    float averageDifference =
        (abs(pixelValues[0]-pixelValues[8]) + // left diagonal
         abs(pixelValues[1]-pixelValues[7]) + // vertical
         abs(pixelValues[2]-pixelValues[6]) + // right diagonal
         abs(pixelValues[3]-pixelValues[5])   // horizontal
         ) /4.0; // average


    return smoothstep(0.35, 0.6,
                      clamp(multiplier * averageDifference, 0.0, 1.0));
}

void main() {
    // Get the unmodified color from the default rendering
    vec4 color = texture2D(colorSampler, uv);

    // Lighten the color a little
    color.rgb += vec3(0.1);

    // Darken the color a lot where there are edges in the depth
    float depthEdgeStrengthMultiplier = 10.0;
    color.rgb -= vec3(edgeAmount(uv, depthSampler, 0, depthEdgeStrengthMultiplier));

    // Darken the color (slightly less) where there are edges in the depth
    float normalEdgeStrengthMultiplier = 2.5;
    color.rgb -= vec3(edgeAmount(uv, normalSampler, 0, normalEdgeStrengthMultiplier));
    color.rgb -= vec3(edgeAmount(uv, normalSampler, 1, normalEdgeStrengthMultiplier));
    color.rgb -= vec3(edgeAmount(uv, normalSampler, 2, normalEdgeStrengthMultiplier));
    
    gl_FragColor = color;
}

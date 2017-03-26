//
//  ViewController.swift
//  Lines
//
//  Created by David Rönnqvist on 2017-03-23.
//  Copyright © 2017 David Rönnqvist
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.


import Cocoa
import SceneKit

let blogBlue = #colorLiteral(red: 0.2695473433, green: 0.6423761845, blue: 0.9001476765, alpha: 1)

class ViewController: NSViewController {

    @IBOutlet var sceneView: SCNView!

    override func awakeFromNib() {
        super.awakeFromNib()

        // I only want to render the Bishop in this example, so I create a new scene
        let scene = SCNScene()
        sceneView.scene = scene

        let chessPieces = SCNScene(named: "chess pieces")

        // For this style that I'm after, I want a matte look (for the base rendering)
        // Note that it's specified below in the technique definition as well(!)
        let bishopNode = chessPieces?.rootNode.childNode(withName: "Bishop", recursively: true)
        bishopNode?.geometry?.firstMaterial?.specular.contents = NSColor.black
        // I also don't want the ambient occlustion that's part of the 'multiply' property
        bishopNode?.geometry?.firstMaterial?.multiply.contents = nil
        // And finally, I want a blue base color
        bishopNode?.geometry?.firstMaterial?.diffuse.contents = blogBlue

        scene.rootNode.addChildNode(bishopNode!) // Don't force unwrap in production ;)


        // On top of that, lines are drawn where there are sharp changes in either depth or in the normals.
        // This done in two steps: 
        //  1. The normals are rendered in a preparation step, called "prep-step"
        //  2. Edges are detected in the NORMALS and DEPTH to draw dark lines on top of the COLOR.

        // You will find in these definitions below that I've used suffixes like:
        // "-step", "-symbol". You don't have to name things like this. I've done 
        // so to try and separate what's a symbol, what's a step, etc.

        // It's also rather common that these definitions would be assets (plists) instead of code.

        let prepDefinition: [String: Any] = [
            "outputs": [
                // What this step renders as color is referred to as NORMALS.
                // This target is defined below, in the technique definition.
                "color": "NORMALS"
            ],
            "inputs": [
                "a_position": "position-symbol",
                "a_normal": "normal-symbol",
                "a_uv": "uv-symbol",

                "modelViewProjection": "mvp-symbol",
                "normalTransform": "nt-symbol",
            ],
            // The pair of shaders for this step is called "prep.vsh" and "prep.vsh"
            "program": "prep",

            // Draw the node named "Bishop"
            "draw": "DRAW_NODE",
            "node": "Bishop",

            // "General" configuration
            "colorStates": [
                "clear": true,
                "clearColor": "1.0 0.0 0.5 1.0"
            ],
            "depthStates": [
                "clear": true,
                "func": "lessEqual"
            ]
        ]

        let linesDefinition: [String: Any] = [
            "outputs": [
                // This step draws its color into the existing COLOR target
                "color": "COLOR"
            ],
            "inputs": [
                // This step gets color and depth from the existing COLOR and DEPTH target
                // that SceneKit renders as "Step 0" (the regular rendering)
                "colorSampler": "COLOR",
                "depthSampler": "DEPTH",
                // It also gets its normals from the NORMAL target (see 'prep' above)
                "normalSampler": "NORMALS",
                // The attribute "a_position" in the "prep" shaders, gets it's value
                // from the "position-symbol" (defined in the technique definition below)
                "a_position": "position-symbol"
            ],
            // The pair of shaders for this step is called "lines.vsh" and "lines.vsh"
            "program": "lines",

            // This time, only a quad (rectangle) is drawn with the previous rendering as a texture
            "draw": "DRAW_QUAD",

            // "General" configuration
            "colorStates": [
                "clear": true,
                "clearColor": "0.5 0.0 0.5 1.0"
            ]
        ]

        let techniqueDefinition: [String: Any] = [
            "passes": [
                // This "technique" has two passes (defined above)
                // They are referred to by the names "prep-step" and "line-step" in this definition
                "prep-step": prepDefinition,
                "line-step": linesDefinition
            ],

            "sequence": [
                // (After "Step 0", the default rendering), the passes are executed
                // preparation step (prep-step), lines step (line-step) after.
                "prep-step", "line-step"
            ],

            "symbols": [
                // In these passes, the following symbols (with these semantics)
                // are available.
                "position-symbol": ["semantic": "vertex"],
                "normal-symbol": ["semantic": "normal"],
                "uv-symbol": ["semantic": "texcoord"],
                "mvp-symbol": ["semantic": "modelViewProjectionTransform"],
                "nt-symbol": ["semantic": "normalTransform"],
            ],

            "targets": [
                // This is where custom render targets for the technique is defined.

                // I've used an all-caps name here because the default targets
                // COLOR and DEPTH uses all-caps names.
                "NORMALS": [
                    "type": "color",
                    "format": "rgb",
                    "size": "512x512", // quite arbitrary
                    "scaleFactor": 1.0
                ]
            ]
        ]

        sceneView.technique = SCNTechnique(dictionary: techniqueDefinition)
    }
}

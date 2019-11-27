import QtQuick.Scene3D 2.0
import QtQuick 2.2 as QQ2

import Qt3D.Core 2.0
import Qt3D.Render 2.0
import Qt3D.Input 2.0
import Qt3D.Logic 2.0
import Qt3D.Extras 2.0
import Qt3D.Animation 2.9

Scene3D {
    id: scene3d
    anchors.fill: parent
    anchors.margins: 10
    focus: true
    aspects: ["input", "logic"]
    cameraAspectRatioMode: Scene3D.AutomaticAspectRatio
    hoverEnabled: true

    readonly property real windowWidth: surfaceSelector.surface !== null ? surfaceSelector.surface.width: 0
    readonly property real windowHeight: surfaceSelector.surface !== null ? surfaceSelector.surface.height: 0

    Entity {
        id: sceneRoot

        Camera {
            id: camera
            projectionType: CameraLens.PerspectiveProjection
            fieldOfView: 45
            aspectRatio: 16/9
            nearPlane : 0.1
            farPlane : 1000.0
            position: Qt.vector3d(5.0, 10.0, 3.0)
            upVector: Qt.vector3d(0.0, 0.0, 1.0)
            viewCenter: Qt.vector3d(0.0, 0.0, 0.0)
        }

        components: [
                RenderSettings {
                    /*activeFrameGraph: ForwardRenderer {
                        camera: camera
                        clearColor: "transparent"
                    }*/
                    activeFrameGraph: RenderSurfaceSelector {
                        id: surfaceSelector
                        Viewport {
                            CameraSelector {
                                camera: camera
                                FrustumCulling {
                                    TechniqueFilter {
                                        matchAll: [
                                            FilterKey { name: "renderingStyle"; value: "forward" }
                                        ]
                                        ClearBuffers {
                                            clearColor: Qt.rgba(0.1, 0.2, 0.3)
                                            buffers: ClearBuffers.ColorDepthStencilBuffer
                                        }
                                    }
                                    TechniqueFilter {
                                        matchAll: [
                                            FilterKey { name: "renderingStyle"; value: "outline" }
                                        ]
                                        RenderPassFilter {
                                            matchAny: [
                                                FilterKey {
                                                    name: "pass"; value: "geometry"
                                                }
                                            ]
                                            ClearBuffers {
                                                buffers: ClearBuffers.ColorDepthStencilBuffer
                                                RenderTargetSelector {
                                                    target: RenderTarget {
                                                        attachments : [
                                                            RenderTargetOutput {
                                                                objectName : "color"
                                                                attachmentPoint : RenderTargetOutput.Color0
                                                                texture : Texture2D {
                                                                    id : colorAttachment
                                                                    width : windowWidth //surfaceSelector.surface.width
                                                                    height : windowHeight //surfaceSelector.surface.height
                                                                    format : Texture.RGBA32F
                                                                }
                                                            }
                                                        ]
                                                    }
                                                }
                                            }
                                        }
                                        RenderPassFilter {
                                            parameters: [
                                                Parameter { name: "color"; value: colorAttachment },
                                                Parameter { name: "winSize"; value : Qt.size(windowWidth, windowHeight /* surfaceSelector.surface.width, surfaceSelector.surface.height */) }
                                            ]
                                            matchAny: [
                                                FilterKey {
                                                    name: "pass"; value: "outline"
                                                }
                                            ]
                                        }
                                    }
                                }
                            }
                        }
                    }

                    pickingSettings.pickMethod: PickingSettings.TrianglePicking
                    pickingSettings.faceOrientationPickingMode: PickingSettings.FrontAndBackFace
                },
                InputSettings { }
            ]

        OrbitCameraController {
            id: orbitController
            camera: camera
            //lookSpeed: 100
        }

        Material {
            id: outlineMaterial

            effect: Effect {
                techniques: [
                    Technique {
                        graphicsApiFilter {
                            api: GraphicsApiFilter.OpenGL
                            majorVersion: 3
                            minorVersion: 1
                            profile: GraphicsApiFilter.CoreProfile
                        }

                        filterKeys: [
                            FilterKey { name: "renderingStyle"; value: "outline" }
                        ]
                        renderPasses: [
                            RenderPass {
                                filterKeys: [
                                    FilterKey { name: "pass"; value: "geometry" }
                                ]
                                shaderProgram: ShaderProgram {
                                    vertexShaderCode: "
#version 150 core

in vec3 vertexPosition;

uniform mat4 modelViewProjection;

void main()
{
    gl_Position = modelViewProjection * vec4( vertexPosition, 1.0 );
}
    "

                                    fragmentShaderCode: "
#version 150 core

out vec4 fragColor;

void main()
{
    fragColor = vec4( 1.0, 0.0, 0.0, 1.0 );
}
    "
                                }
                            }
                        ]
                    }
                ]
            }
        }

        Entity {
            id: cube1
            property bool selected: false
            CuboidMesh {
                id: cube1mesh
                xExtent: 1
                yExtent: 1
                zExtent: 1
            }
            PhongMaterial {
                id: cube1material
            }
            Transform {
                id: cube1Transform
                translation: Qt.vector3d(3, 2, 0)
            }
            ObjectPicker {
                id: cube1picker
                onPressed: {
                    cube1.selected = !cube1.selected
                    console.log("Entity 'cube1' is " + (cube1.selected ? "" : "not ") + "selected");
                    console.log("Pressed at: " + pick.worldIntersection)
                    console.log("Triangle index: " + pick.triangleIndex)
                    console.log("Win size: " + windowWidth + "x" + windowHeight)
                }
            }
            components: [cube1mesh, cube1material, cube1Transform, cube1picker, selected ? outlineMaterial : null]
        }
    }
}

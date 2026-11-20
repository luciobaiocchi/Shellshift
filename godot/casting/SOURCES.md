# Hospital cast

The two performers are adapted from adult civilians in the Microsoft Rocketbox Avatar Library. Both source links are pinned to commit `0943055db6ec570bcef9f2c8b41c9e5467c808f9`. The original copyright notice and license are included in [LICENSE-Rocketbox.txt](LICENSE-Rocketbox.txt).

| Performer | Original avatar | Original assets |
| --- | --- | --- |
| Ada | Female_Adult_07 | [FBX with facial shapes, diffuse maps and portrait](https://github.com/microsoft/Microsoft-Rocketbox/tree/0943055db6ec570bcef9f2c8b41c9e5467c808f9/Assets/Avatars/Adults/Female_Adult_07) |
| Mara | Female_Adult_14 | [FBX with facial shapes, diffuse maps and portrait](https://github.com/microsoft/Microsoft-Rocketbox/tree/0943055db6ec570bcef9f2c8b41c9e5467c808f9/Assets/Avatars/Adults/Female_Adult_14) |

The GLBs use the original fully skinned meshes and 80-bone skeletons. Blender conversion normalized all transforms to metres and retained 20 of the original expression shapes. The face, clothing and hair maps are embedded. For Mara, the hair colour, facial creases and skin pigmentation were adjusted on the original UV maps for her age in this scene.

In Godot the performers face +Z, with their feet at ground level and an identity transform on `CastRig/Skeleton3D`. Its child `ActorMesh` exposes the blend shapes. The named bones retain the original `Bip01` prefix. The actor heights are approximately 1.72 m and 1.74 m.

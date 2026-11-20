# Prologue cast

Each performer is a distinct adult from the Microsoft Rocketbox Avatar Library. The original source and photographs are pinned to commit `0943055db6ec570bcef9f2c8b41c9e5467c808f9`. The required copyright notice and MIT license accompany the models in [LICENSE-Rocketbox.txt](LICENSE-Rocketbox.txt).

| Performer | Godot asset | Original model and source |
| --- | --- | --- |
| Ada | `ada.glb` | [Female_Adult_07](https://github.com/microsoft/Microsoft-Rocketbox/tree/0943055db6ec570bcef9f2c8b41c9e5467c808f9/Assets/Avatars/Adults/Female_Adult_07) |
| Mara | `mara.glb` | [Female_Adult_14](https://github.com/microsoft/Microsoft-Rocketbox/tree/0943055db6ec570bcef9f2c8b41c9e5467c808f9/Assets/Avatars/Adults/Female_Adult_14) |
| Nico | `nico.glb` | [Male_Adult_02](https://github.com/microsoft/Microsoft-Rocketbox/tree/0943055db6ec570bcef9f2c8b41c9e5467c808f9/Assets/Avatars/Adults/Male_Adult_02) |
| Lea | `lea.glb` | [Business_Female_01](https://github.com/microsoft/Microsoft-Rocketbox/tree/0943055db6ec570bcef9f2c8b41c9e5467c808f9/Assets/Avatars/Professions/Business_Female_01) |
| Rosa | `rosa.glb` | [Female_Adult_05](https://github.com/microsoft/Microsoft-Rocketbox/tree/0943055db6ec570bcef9f2c8b41c9e5467c808f9/Assets/Avatars/Adults/Female_Adult_05) |
| Rosa’s mother | `rosa_mother.glb` | [Business_Female_02](https://github.com/microsoft/Microsoft-Rocketbox/tree/0943055db6ec570bcef9f2c8b41c9e5467c808f9/Assets/Avatars/Professions/Business_Female_02) |
| Civic counter clerk | `clerk.glb` | [Business_Male_07](https://github.com/microsoft/Microsoft-Rocketbox/tree/0943055db6ec570bcef9f2c8b41c9e5467c808f9/Assets/Avatars/Professions/Business_Male_07) |
| Ren, transfer clerk | `ren.glb` | [Business_Male_05](https://github.com/microsoft/Microsoft-Rocketbox/tree/0943055db6ec570bcef9f2c8b41c9e5467c808f9/Assets/Avatars/Professions/Business_Male_05) |
| Ivo | `ivo.glb` | [Male_Adult_05](https://github.com/microsoft/Microsoft-Rocketbox/tree/0943055db6ec570bcef9f2c8b41c9e5467c808f9/Assets/Avatars/Adults/Male_Adult_05) |
| Jo | `jo.glb` | [Female_Adult_13](https://github.com/microsoft/Microsoft-Rocketbox/tree/0943055db6ec570bcef9f2c8b41c9e5467c808f9/Assets/Avatars/Adults/Female_Adult_13) |
| Background performer A | `extra_a.glb` | [Male_Adult_12](https://github.com/microsoft/Microsoft-Rocketbox/tree/0943055db6ec570bcef9f2c8b41c9e5467c808f9/Assets/Avatars/Adults/Male_Adult_12) |
| Background performer B | `extra_b.glb` | [Female_Adult_06](https://github.com/microsoft/Microsoft-Rocketbox/tree/0943055db6ec570bcef9f2c8b41c9e5467c808f9/Assets/Avatars/Adults/Female_Adult_06) |
| Background performer C | `extra_c.glb` | [Female_Adult_03](https://github.com/microsoft/Microsoft-Rocketbox/tree/0943055db6ec570bcef9f2c8b41c9e5467c808f9/Assets/Avatars/Adults/Female_Adult_03) |
| Background performer D | `extra_d.glb` | [Male_Adult_04](https://github.com/microsoft/Microsoft-Rocketbox/tree/0943055db6ec570bcef9f2c8b41c9e5467c808f9/Assets/Avatars/Adults/Male_Adult_04) |
| Background performer E | `extra_e.glb` | [Female_Adult_09](https://github.com/microsoft/Microsoft-Rocketbox/tree/0943055db6ec570bcef9f2c8b41c9e5467c808f9/Assets/Avatars/Adults/Female_Adult_09) |

## Adaptation

The original facial FBX and skin weights are retained. The GLBs embed the photographed face, outfit and hair textures. Faces are sampled at up to 1536 pixels and the other maps at up to 1024 pixels. Hair, eyelashes and the lenses of Rosa’s mother’s glasses use transparent surfaces. Mara’s hair, facial creases and skin pigmentation and the hair colour of Rosa’s mother were adjusted for their scenes.

The late-period facial materials in `years/` are UV-local adaptations of those same source photographs. The 2047 and 2053 makeup adds individual silver temples and skin detail around the eyes and mouth. Clothing, eye pigments and skin tones use the original palette.

Godot instantiates each performer facing +Z with feet at ground level. Skeleton transforms are normalized to metres and the original 80 `Bip01` bones are retained. The mesh at `CastRig/Skeleton3D/ActorMesh` exposes 20 controls, including `Blink`, `Smile`, individual eyelids and lip corners, brows, gaze direction, jaw and cheeks. The imported heights range from 1.72 to 1.82 metres.

The [ensemble conversion script](../../tools/build_rocketbox_ensemble.py) reconstructs the additional performers from the pinned files, verifies the original Git blobs, prepares the materials, and exports the GLBs in Blender. Install Pillow for the Python interpreter and put Blender 5 on the path, then run `python tools/build_rocketbox_ensemble.py`. To rebuild individual performers, append their asset names without extensions.

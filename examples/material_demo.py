from os import path as pt

from assimpcy import aiImportFile, aiPostProcessSteps as pp

home = pt.dirname(__file__)
shoe = pt.join(home, 'models', 'MaterialsVariantsShoe', 'glTF', 'MaterialsVariantsShoe.gltf')
# soldier = pt.join(home, 'models', 'soldier pbr', 'Soldier.glb')
# scavenger = pt.join(home, 'models', 'scavenger', 'Scavenger.fbx')
# model_path = soldier
model_path = shoe
# model_path = scavenger


def main():
    print('Reading \'{}\':'.format(model_path))
    flags = pp.aiProcess_JoinIdenticalVertices | pp.aiProcess_Triangulate | pp.aiProcess_CalcTangentSpace | \
            pp.aiProcess_OptimizeGraph | pp.aiProcess_OptimizeMeshes | pp.aiProcess_FixInfacingNormals | \
            pp.aiProcess_GenUVCoords | pp.aiProcess_LimitBoneWeights | pp.aiProcess_SortByPType | \
            pp.aiProcess_RemoveRedundantMaterials
    scene = aiImportFile(model_path, flags)

    print('- Has {} embedded textures'.format(scene.mNumTextures))
    if scene.HasTextures:
        from io import BytesIO
        import numpy as np
        from PIL import Image
        for i, t in enumerate(scene.mTextures):
            data = t.pcData
            hint = t.achFormatHint.decode()
            if len(hint) == 3:
                # the hint indicates the texture format as an extension (e.g. png)
                print(f" * Texture {i} format: '.{hint}'")
                imgfile = BytesIO(data)
                img = Image.open(imgfile)  # let Pillow figure out the image format
                w, h = img.size  # data = np.asarray(img)  # flatten the data array  # to send it to the graphics
                # library
            else:
                # no hint or raw data description (e.g. argb8888)
                print(f"   * Raw data ({hint})")
                w, h = t.mWidth, t.mHeight
                data = np.reshape(data,
                                  (h, w, 4))  # << skip this to keep the array  # flat for use in a graphics library
                img = Image.open(BytesIO(data))

            # store 'data' variable for later use  # or save it as a file using the extension from the hint,
            # if present,  # or as a format compatible with the texture components
            print(f"    w={h}, h={h}")
            # img.show()

    print('- Has {} materials'.format(scene.mNumMaterials))

    for i, mat in enumerate(scene.mMaterials):
        print(f' * Material {i}: "{mat.name}"')
        max_key_length = max(len(k) for k in mat.properties.keys())
        for k, v in mat.properties.items():
            print(f'   - {k:<{max_key_length}} \t=\t{v}')

        textures_keys = mat.textures.keys()
        ti_members = ['type', 'index', 'path', 'mapping', 'uvindex', 'blend', 'op', 'mapmode']
        print(f"   -- {len(textures_keys)} Texture types:")
        for k in textures_keys:
            print(f"    * {k}:")
            for pk in ti_members:
                print(f"       {pk} = {getattr(mat.textures[k], pk)}")


if __name__ == '__main__':
    main()

from timeit import Timer
from os import path as pt

from assimpcy import aiImportFile, aiPostProcessSteps as pp, Exporter, aiGetExportFormatCount, \
    aiGetExportFormatDescription

home = pt.dirname(__file__)

scene_orig = None
scene_conv = None
exporter = Exporter()

ext = '.dae'
format_index = exporter.query_formatId_or_extension(ext)
formatDescription = aiGetExportFormatDescription(format_index)
formatID = formatDescription.id

print(f"Description of format {formatID}: {formatDescription.description}\n"
      f"  ID\t\t= {formatDescription.id}\n"
      f"  Extension\t= '{formatDescription.fileExtension}'")

model_path = pt.join(home, 'models', 'cilly', 'cilly.x')
destination = pt.join(home, 'models', 'cilly', 'cilly' + ext)


def doConversion():
    ret = exporter.convertFile(model_path, destination, formatID)
    print(f"  Conversion result: {ret}")


def main():
    global scene_orig, scene_conv, exporter

    print(f"Converting '{model_path}'\n"
          f"to '{destination}'...")

    t = Timer(doConversion)
    secs = t.timeit(1)

    flags = pp.aiProcess_JoinIdenticalVertices | pp.aiProcess_Triangulate | pp.aiProcess_CalcTangentSpace | \
            pp.aiProcess_OptimizeGraph | pp.aiProcess_OptimizeMeshes | pp.aiProcess_FixInfacingNormals | \
            pp.aiProcess_GenUVCoords | pp.aiProcess_LimitBoneWeights | pp.aiProcess_SortByPType | \
            pp.aiProcess_RemoveRedundantMaterials

    scene_orig = aiImportFile(model_path, flags)
    scene_conv = aiImportFile(destination, flags)

    print('-' * 35)
    print(f'{aiGetExportFormatCount()} export formats available in current Assimp build:\n')

    formats = exporter.getExportFormatsList()
    print(f"{'Index':<6}{'Extension':^12} {'FormatID':<10} {'Description':<10}")
    print('_' * 35)
    for i, f in enumerate(formats):
        fext, fid, fdesc = f
        print(f"{i:^6}{fext:^12} {fid:^10} {fdesc:<20}")

    print('-' * 35)
    print(f"{'':<15} {'Scene 1':<10} {'Scene 2':<10}")
    print('-' * 35)
    print(f"{'Meshes':<15} {scene_orig.mNumMeshes:^10} {scene_conv.mNumMeshes:^10}")
    print(f"{'Textures':<15} {scene_orig.mNumTextures:^10} {scene_conv.mNumTextures:^10}")
    print(f"{'Materials':<15} {scene_orig.mNumMaterials:^10} {scene_conv.mNumMaterials:^10}")
    print(f"{'Animations':<15} {scene_orig.mNumAnimations:^10} {scene_conv.mNumAnimations:^10}")

    if scene_orig.HasMeshes:
        if scene_orig.mMeshes[0].HasPositions:
            va = scene_orig.mMeshes[0].mNumVertices
            vb = scene_conv.mMeshes[0].mNumVertices
            assert va == vb
            print(f"{'Vertex count':<15} {va:^10} {vb:^10}")
            v1 = scene_orig.mMeshes[0].mVertices[int(va / 2)]
            v2 = scene_conv.mMeshes[0].mVertices[int(va / 2)]

            vc = '\nVertex {} original  {}'.format(va, v1)
            vd = 'Vertex {} converted {}'.format(va, v2)
            print(vc)
            print(vd)

        print(f'\nMesh 0  original: "{scene_orig.mMeshes[0].mName}"')
        print(f'Mesh 0 converted: "{scene_conv.mMeshes[0].mName}"')

    if scene_orig.HasAnimations:
        print(f'\nAnimation  0 original: "{scene_orig.mAnimations[0].mName}"')
        print(f'Animation 0 converted: "{scene_conv.mAnimations[0].mName}"')

    if scene_orig.HasMaterials:
        print(f'\nMaterial 0  original: "{str(scene_orig.mMaterials[0])}"')
        print(f'Material 0 converted: "{str(scene_conv.mMaterials[0])}"')

    print('Conversion took {:0.4f} seconds.'.format(secs))


if __name__ == '__main__':
    main()

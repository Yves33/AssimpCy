from timeit import Timer
from os import path as pt

from assimpcy import aiImportFile, aiPostProcessSteps as pp

home = pt.dirname(__file__)
model_path = pt.join(home, 'models', 'cilly', 'cilly.x')
scene = None


def doImport():
    global scene
    flags = pp.aiProcess_JoinIdenticalVertices | pp.aiProcess_Triangulate | pp.aiProcess_CalcTangentSpace | \
            pp.aiProcess_OptimizeGraph | pp.aiProcess_OptimizeMeshes | \
            pp.aiProcess_FixInfacingNormals | pp.aiProcess_GenUVCoords | \
            pp.aiProcess_LimitBoneWeights | pp.aiProcess_SortByPType | pp.aiProcess_RemoveRedundantMaterials

    scene = aiImportFile(model_path, flags)


def main():
    print('Reading \'{}\':'.format(model_path))
    t = Timer(doImport)
    secs = t.timeit(1)
    print('\tHas {} meshes, {} textures, {} materials, {} animations.'.format(scene.mNumMeshes,
                                                                              scene.mNumTextures,
                                                                              scene.mNumMaterials,
                                                                              scene.mNumAnimations))

    # Check mesh.Has* before extracting corresponding mesh.m* (Vertices, Normals, etc)
    if scene.HasMeshes and scene.mMeshes[0].HasPositions:
        v = int(scene.mMeshes[0].mNumVertices / 2)
        print('\tVertex {} = {}'.format(v, scene.mMeshes[0].mVertices[v]))

    print('Took {:0.4f} seconds.'.format(secs))


if __name__ == '__main__':
    main()

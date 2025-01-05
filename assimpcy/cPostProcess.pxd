cdef extern from "postprocess.h" nogil:
    cdef unsigned int aiProcessPreset_TargetRealtime_Fast
    cdef unsigned int aiProcessPreset_TargetRealtime_MaxQuality
    cdef unsigned int aiProcessPreset_TargetRealtime_Quality
    cdef unsigned int aiProcess_ConvertToLeftHanded

    cdef enum aiPostProcessSteps:
        aiProcess_CalcTangentSpace
        aiProcess_Debone
        aiProcess_DropNormals
        aiProcess_EmbedTextures
        aiProcess_FindDegenerates
        aiProcess_FindInstances
        aiProcess_FindInvalidData
        aiProcess_FixInfacingNormals
        aiProcess_FlipUVs
        aiProcess_FlipWindingOrder
        aiProcess_ForceGenNormals
        aiProcess_GenBoundingBoxes
        aiProcess_GenNormals
        aiProcess_GenSmoothNormals
        aiProcess_GenUVCoords
        aiProcess_GlobalScale
        aiProcess_ImproveCacheLocality
        aiProcess_JoinIdenticalVertices
        aiProcess_LimitBoneWeights
        aiProcess_MakeLeftHanded
        aiProcess_OptimizeGraph
        aiProcess_OptimizeMeshes
        aiProcess_PopulateArmatureData
        aiProcess_PreTransformVertices
        aiProcess_RemoveComponent
        aiProcess_RemoveRedundantMaterials
        aiProcess_SortByPType
        aiProcess_SplitByBoneCount
        aiProcess_SplitLargeMeshes
        aiProcess_TransformUVCoords
        aiProcess_Triangulate
        aiProcess_ValidateDataStructure

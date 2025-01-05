# cython: c_string_type=bytes
# cython: c_string_encoding=utf8
# cython: language_level=3
# distutils: language=c++

from . cimport cImporter, cScene, cMesh, cTypes, cMaterial, cAnim, cPostProcess, cTexture
from . cimport cdefs, cExporter
import numpy as np
from os import path
cimport numpy as np
cimport cython

#from cython.parallel import prange

from libc.string cimport memcpy
from libc.stdio cimport printf
from warnings import warn
from enum import Enum, Flag

ctypedef bint bool

NUMPYINT = np.uint32
ctypedef np.uint32_t NUMPYINT_t

NUMPYFLOAT = np.float32
ctypedef np.float32_t NUMPYFLOAT_t

NUMPYBYTE = np.uint8
ctypedef np.uint8_t NUMPYBYTE_t

ctypedef fused anykey:
    cAnim.aiVectorKey
    cAnim.aiQuatKey

ctypedef fused i_f:
    dataStorageI
    dataStorageF

cdef int AI_MAX_NUMBER_OF_TEXTURECOORDS = cMesh._AI_MAX_NUMBER_OF_TEXTURECOORDS
cdef int AI_MAX_NUMBER_OF_COLOR_SETS = cMesh._AI_MAX_NUMBER_OF_COLOR_SETS

propertyNames = {
'?mat.name': 'NAME',
'$mat.twosided': 'TWOSIDED',
'$mat.shadingm': 'SHADING_MODEL',
'$mat.wireframe': 'ENABLE_WIREFRAME',
'$mat.blend': 'BLEND_FUNC',
'$mat.opacity': 'OPACITY',
'$mat.transparencyfactor': 'TRANSPARENCYFACTOR',
'$mat.bumpscaling': 'BUMPSCALING',
'$mat.shininess': 'SHININESS',
'$mat.reflectivity': 'REFLECTIVITY',
'$mat.shinpercent': 'SHININESS_STRENGTH',
'$mat.refracti': 'REFRACTI',
'$clr.diffuse': 'COLOR_DIFFUSE',
'$clr.ambient': 'COLOR_AMBIENT',
'$clr.specular': 'COLOR_SPECULAR',
'$clr.emissive': 'COLOR_EMISSIVE',
'$clr.transparent': 'COLOR_TRANSPARENT',
'$clr.reflective': 'COLOR_REFLECTIVE',
'?bg.global': 'GLOBAL_BACKGROUND_IMAGE',
'?sh.lang': 'GLOBAL_SHADERLANG',
'?sh.vs': 'SHADER_VERTEX',
'?sh.fs': 'SHADER_FRAGMENT',
'?sh.gs': 'SHADER_GEO',
'?sh.ts': 'SHADER_TESSELATION',
'?sh.ps': 'SHADER_PRIMITIVE',
'?sh.cs': 'SHADER_COMPUTE',
'$mat.useColorMap': 'USE_COLOR_MAP',
'$clr.base': 'BASE_COLOR',
'$mat.useMetallicMap': 'USE_METALLIC_MAP',
'$mat.metallicFactor': 'METALLIC_FACTOR',
'$mat.useRoughnessMap': 'USE_ROUGHNESS_MAP',
'$mat.roughnessFactor': 'ROUGHNESS_FACTOR',
'$mat.anisotropyFactor': 'ANISOTROPY_FACTOR',
'$mat.specularFactor': 'SPECULAR_FACTOR',
'$mat.glossinessFactor': 'GLOSSINESS_FACTOR',
'$clr.sheen.factor': 'SHEEN_COLOR_FACTOR',
'$mat.sheen.roughnessFactor': 'SHEEN_ROUGHNESS_FACTOR',
'$mat.clearcoat.factor': 'CLEARCOAT_FACTOR',
'$mat.clearcoat.roughnessFactor': 'CLEARCOAT_ROUGHNESS_FACTOR',
'$mat.transmission.factor': 'TRANSMISSION_FACTOR',
'$mat.volume.thicknessFactor': 'VOLUME_THICKNESS_FACTOR',
'$mat.volume.attenuationDistance': 'VOLUME_ATTENUATION_DISTANCE',
'$mat.volume.attenuationColor': 'VOLUME_ATTENUATION_COLOR',
'$mat.useEmissiveMap': 'USE_EMISSIVE_MAP',
'$mat.emissiveIntensity': 'EMISSIVE_INTENSITY',
'$mat.useAOMap': 'USE_AO_MAP',
'$tex.file': 'TEXTURE',
'$tex.uvwsrc': 'UVWSRC',
'$tex.op': 'TEXOP',
'$tex.mapping': 'MAPPING',
'$tex.blend': 'TEXBLEND',
'$tex.mapmodeu': 'MAPPINGMODE_U',
'$tex.mapmodev': 'MAPPINGMODE_V',
'$tex.mapaxis': 'TEXMAP_AXIS',
'$tex.uvtrafo': 'UVTRANSFORM',
'$tex.flags': 'TEXFLAGS'
}

cdef class aiVertexWeight:
    cdef readonly unsigned int mVertexId
    cdef readonly float mWeight

    def __init__(self):
        pass


cdef class aiBone:
    cdef readonly str mName
    cdef readonly list mWeights
    cdef readonly np.ndarray mOffsetMatrix

    def __init__(self):
        self.mWeights = []

    def __str__(self):
        return self.mName


cdef class aiMesh:
    cdef readonly unsigned int mPrimitiveTypes
    cdef readonly unsigned int mNumVertices
    cdef readonly unsigned int mNumFaces
    cdef readonly np.ndarray mVertices
    cdef readonly np.ndarray mNormals
    cdef readonly np.ndarray mTangents
    cdef readonly np.ndarray mBitangents
    cdef readonly list mColors
    cdef readonly list mTextureCoords
    cdef readonly list mNumUVComponents
    cdef readonly np.ndarray mFaces
    cdef readonly unsigned int mNumBones
    cdef readonly list mBones
    cdef readonly unsigned int mMaterialIndex
    cdef readonly str mName
        #unsigned int mNumAnimMeshes
        #aiAnimMesh** mAnimMeshes
    cdef readonly bool HasPositions
    cdef readonly bool HasFaces
    cdef readonly bool HasNormals
    cdef readonly bool HasTangentsAndBitangents
    cdef readonly list HasVertexColors
    cdef readonly list HasTextureCoords
    cdef readonly unsigned int NumUVChannels
    cdef readonly unsigned int NumColorChannels
    cdef readonly bool HasBones

    def __init__(self):
        self.mNumUVComponents = [0] * AI_MAX_NUMBER_OF_TEXTURECOORDS
        self.mTextureCoords = [None] * AI_MAX_NUMBER_OF_TEXTURECOORDS
        self.mColors = [None] * AI_MAX_NUMBER_OF_COLOR_SETS
        self.mName = ''
        self.mMaterialIndex = -1
        self.mBones = []
        self.HasVertexColors = []
        self.HasTextureCoords = []

    def __str__(self):
        return self.mName

@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
cdef aiMesh buildMesh(cMesh.aiMesh* mesh):
    cdef bint val = 0, hasanycoord = 0, hasanycolor = 0
    cdef unsigned int i = 0, j = 0, k = 0
    cdef aiBone bone
    cdef aiVertexWeight vertW
    cdef aiMesh rMesh = aiMesh()
    cdef np.ndarray tempnd

    try:
        rMesh.mName = mesh.mName.data.decode("utf-8", errors="replace")
    except UnicodeDecodeError:
        rMesh.mName = str(mesh.mName.data)

    rMesh.mNumBones = mesh.mNumBones
    rMesh.mMaterialIndex = mesh.mMaterialIndex
    rMesh.mPrimitiveTypes = mesh.mPrimitiveTypes
    rMesh.mNumVertices = mesh.mNumVertices
    rMesh.HasPositions = mesh.HasPositions()
    rMesh.HasFaces = mesh.HasFaces()
    rMesh.HasNormals = mesh.HasNormals()
    rMesh.HasTangentsAndBitangents = mesh.HasTangentsAndBitangents()

    k = AI_MAX_NUMBER_OF_COLOR_SETS
    for i in range(k):
        val = mesh.HasVertexColors(i)
        if val:
            hasanycolor = val
        rMesh.HasVertexColors.append(val)

    k = AI_MAX_NUMBER_OF_TEXTURECOORDS
    for i in range(k):
        rMesh.mNumUVComponents[i] = mesh.mNumUVComponents[i]
        val = mesh.HasTextureCoords(i)
        if val:
            rMesh.mTextureCoords[i] = np.empty((mesh.mNumVertices, mesh.mNumUVComponents[i]), dtype=NUMPYFLOAT)
            hasanycoord = val
        rMesh.HasTextureCoords.append(val)

    rMesh.NumUVChannels = mesh.GetNumUVChannels()
    rMesh.NumColorChannels = mesh.GetNumColorChannels()
    rMesh.HasBones = mesh.HasBones()
    rMesh.mNumFaces = mesh.mNumFaces

    if rMesh.HasBones:
        for i in range(rMesh.mNumBones):
            bone = aiBone()
            try:
                bone.mName = mesh.mBones[i].mName.data.decode("utf-8", errors="replace")
            except UnicodeDecodeError:
                bone.mName = str(mesh.mBones[i].mName.data)
            bone.mOffsetMatrix = np.empty((4, 4), dtype=NUMPYFLOAT)
#            with nogil:
            memcpy(<void*>bone.mOffsetMatrix.data, <void*>&mesh.mBones[i].mOffsetMatrix, sizeof(NUMPYFLOAT_t) * 16)
            for j in range(mesh.mBones[i].mNumWeights):
                vertW = aiVertexWeight()
                vertW.mVertexId = mesh.mBones[i].mWeights[j].mVertexId
                vertW.mWeight = mesh.mBones[i].mWeights[j].mWeight
                bone.mWeights.append(vertW)
            rMesh.mBones.append(bone)

    if rMesh.HasPositions:
        rMesh.mVertices = np.empty((mesh.mNumVertices, 3), dtype=NUMPYFLOAT)

    if rMesh.HasNormals:
        rMesh.mNormals = np.empty((mesh.mNumVertices, 3), dtype=NUMPYFLOAT)

    if rMesh.HasTangentsAndBitangents:
        rMesh.mTangents = np.empty((mesh.mNumVertices, 3), dtype=NUMPYFLOAT)
        rMesh.mBitangents = np.empty((mesh.mNumVertices, 3), dtype=NUMPYFLOAT)

    cdef NUMPYINT_t [:,:] facememview
    if rMesh.HasFaces:
        rMesh.mFaces = np.empty((rMesh.mNumFaces, mesh.mFaces.mNumIndices), dtype=NUMPYINT)
        facememview = rMesh.mFaces

    with nogil:
        if mesh.HasPositions():
            memcpy(<void*>rMesh.mVertices.data, <void*>&mesh.mVertices[0], mesh.mNumVertices * 3 * sizeof(NUMPYFLOAT_t))

        if mesh.HasNormals():
            memcpy(<void*>rMesh.mNormals.data, <void*>&mesh.mNormals[0],  mesh.mNumVertices * 3 * sizeof(NUMPYFLOAT_t))

        if mesh.HasTangentsAndBitangents():
            memcpy(<void*>rMesh.mTangents.data, <void*>&mesh.mTangents[0],
                   mesh.mNumVertices * 3 * sizeof(NUMPYFLOAT_t))
            memcpy(<void*>rMesh.mBitangents.data, <void*>&mesh.mBitangents[0],
                   mesh.mNumVertices * 3 * sizeof(NUMPYFLOAT_t))

        if mesh.HasFaces():
            for i in range(mesh.mNumFaces):
                memcpy(<void*> &facememview[i, 0],<void*> &mesh.mFaces[i].mIndices[0],
                       mesh.mFaces[i].mNumIndices * sizeof(int))

    if hasanycoord:
        for i in range(k):
            if mesh.HasTextureCoords(i):
                tempnd = rMesh.mTextureCoords[i]
#                with nogil:
                memcpy(<void*>tempnd.data, <void*>&mesh.mTextureCoords[i][0], mesh.mNumVertices *
                                                   mesh.mNumUVComponents[i] * sizeof(NUMPYFLOAT_t))

    if hasanycolor:
        k = AI_MAX_NUMBER_OF_COLOR_SETS
        for i in range(k):
            if rMesh.HasVertexColors[i]:
                tempnd = np.empty((mesh.mNumVertices, 4), dtype=NUMPYFLOAT)
#                with nogil:
                memcpy(<void*>tempnd.data, <void*>&mesh.mColors[i][0], mesh.mNumVertices * 4 * sizeof(NUMPYFLOAT_t))
                rMesh.mColors[i] = tempnd

    return rMesh


# -----------------------------------------------------


cdef class aiNode:
    cdef readonly list mChildren
    cdef readonly str mName
    cdef readonly int mNumChildren
    cdef readonly aiNode mParent
    cdef readonly int mNumMeshes
    cdef readonly list mMeshes
    cdef readonly np.ndarray mTransformation


    def __init__(self):
        self.mChildren = []
        self.mMeshes = []
        self.mName = ''

    def __str__(self):
        return self.mName

cdef aiNode buildNode(cScene.aiNode* node, aiNode parent):
    cdef aiNode rNode = aiNode()
    cdef unsigned int i = 0, k= 0
    rNode.mParent = parent
    rNode.mNumMeshes = node.mNumMeshes
    try:
        rNode.mName = node.mName.data.decode("utf-8", errors="replace")
    except UnicodeDecodeError:
        rNode.mName = str(node.mName.data)
    rNode.mNumChildren = node.mNumChildren
    rNode.mTransformation = np.empty((4, 4), dtype=NUMPYFLOAT)
#    with nogil:
    memcpy(<void*>rNode.mTransformation.data, <void*>&node.mTransformation, sizeof(NUMPYFLOAT_t) * 16)

    k = rNode.mNumChildren
    for i in range(k):
        rNode.mChildren.append(buildNode(node.mChildren[i], rNode))

    k = rNode.mNumMeshes
    for i in range(k):
        rNode.mMeshes.append(node.mMeshes[i])
    return rNode


# -----------------------------------------------------

class aiTextureType(Enum):
    aiTextureType_NONE              = cMaterial.aiTextureType_NONE
    aiTextureType_DIFFUSE           = cMaterial.aiTextureType_DIFFUSE
    aiTextureType_SPECULAR          = cMaterial.aiTextureType_SPECULAR
    aiTextureType_AMBIENT           = cMaterial.aiTextureType_AMBIENT
    aiTextureType_EMISSIVE          = cMaterial.aiTextureType_EMISSIVE
    aiTextureType_HEIGHT            = cMaterial.aiTextureType_HEIGHT
    aiTextureType_NORMALS           = cMaterial.aiTextureType_NORMALS
    aiTextureType_SHININESS         = cMaterial.aiTextureType_SHININESS
    aiTextureType_OPACITY           = cMaterial.aiTextureType_OPACITY
    aiTextureType_DISPLACEMENT      = cMaterial.aiTextureType_DISPLACEMENT
    aiTextureType_LIGHTMAP          = cMaterial.aiTextureType_LIGHTMAP
    aiTextureType_REFLECTION        = cMaterial.aiTextureType_REFLECTION
    # PBR materials
    aiTextureType_BASE_COLOR        = cMaterial.aiTextureType_BASE_COLOR
    aiTextureType_NORMAL_CAMERA     = cMaterial.aiTextureType_NORMAL_CAMERA
    aiTextureType_EMISSION_COLOR    = cMaterial.aiTextureType_EMISSION_COLOR
    aiTextureType_METALNESS         = cMaterial.aiTextureType_METALNESS
    aiTextureType_DIFFUSE_ROUGHNESS = cMaterial.aiTextureType_DIFFUSE_ROUGHNESS
    aiTextureType_AMBIENT_OCCLUSION = cMaterial.aiTextureType_AMBIENT_OCCLUSION

    aiTextureType_UNKNOWN           = cMaterial.aiTextureType_UNKNOWN

class aiTextureOp(Enum):
    aiTextureOp_Multiply  = cMaterial.aiTextureOp_Multiply
    aiTextureOp_Add       = cMaterial.aiTextureOp_Add
    aiTextureOp_Subtract  = cMaterial.aiTextureOp_Subtract
    aiTextureOp_Divide    = cMaterial.aiTextureOp_Divide
    aiTextureOp_SmoothAdd = cMaterial.aiTextureOp_SmoothAdd
    aiTextureOp_SignedAdd = cMaterial.aiTextureOp_SignedAdd

class aiTextureMapping(Enum):
    aiTextureMapping_UV         = cMaterial.aiTextureMapping_UV
    aiTextureMapping_SPHERE     = cMaterial.aiTextureMapping_SPHERE
    aiTextureMapping_CYLINDER   = cMaterial.aiTextureMapping_CYLINDER
    aiTextureMapping_BOX        = cMaterial.aiTextureMapping_BOX
    aiTextureMapping_PLANE      = cMaterial.aiTextureMapping_PLANE
    aiTextureMapping_OTHER      = cMaterial.aiTextureMapping_OTHER

class aiTextureMapMode(Enum):
    aiTextureMapMode_Wrap    = cMaterial.aiTextureMapMode_Wrap
    aiTextureMapMode_Clamp   = cMaterial.aiTextureMapMode_Clamp
    aiTextureMapMode_Decal   = cMaterial.aiTextureMapMode_Decal
    aiTextureMapMode_Mirror  = cMaterial.aiTextureMapMode_Mirror

class aiShadingMode(Enum):
    aiShadingMode_Flat          = cMaterial.aiShadingMode_Flat
    aiShadingMode_Gouraud       = cMaterial.aiShadingMode_Gouraud
    aiShadingMode_Phong         = cMaterial.aiShadingMode_Phong
    aiShadingMode_Blinn         = cMaterial.aiShadingMode_Blinn
    aiShadingMode_Toon          = cMaterial.aiShadingMode_Toon
    aiShadingMode_OrenNayar     = cMaterial.aiShadingMode_OrenNayar
    aiShadingMode_Minnaert      = cMaterial.aiShadingMode_Minnaert
    aiShadingMode_CookTorrance  = cMaterial.aiShadingMode_CookTorrance
    aiShadingMode_NoShading     = cMaterial.aiShadingMode_NoShading
    aiShadingMode_Fresnel       = cMaterial.aiShadingMode_Fresnel

class aiTextureFlags(Enum):
    aiTextureFlags_Invert       = cMaterial.aiTextureFlags_Invert
    aiTextureFlags_UseAlpha     = cMaterial.aiTextureFlags_UseAlpha
    aiTextureFlags_IgnoreAlpha  = cMaterial.aiTextureFlags_IgnoreAlpha

class aiBlendMode(Enum):
    aiBlendMode_Default   = cMaterial.aiBlendMode_Default
    aiBlendMode_Additive  = cMaterial.aiBlendMode_Additive


cdef class aiMaterial:
    cdef readonly str name
    cdef readonly dict properties
    cdef readonly dict textures

    def __init__(self):
        self.properties = {}
        self.name = ''
        self.textures = {}

    def __repr__(self):
        return self.name

cdef dict TEXTURE_TYPE_DICT = {
    cMaterial.aiTextureType_DIFFUSE: "Diffuse",
    cMaterial.aiTextureType_SPECULAR: "Specular",
    cMaterial.aiTextureType_AMBIENT: "Ambient",
    cMaterial.aiTextureType_EMISSIVE: "Emissive",
    cMaterial.aiTextureType_HEIGHT: "Height",
    cMaterial.aiTextureType_NORMALS: "Normals",
    cMaterial.aiTextureType_SHININESS: "Shininess",
    cMaterial.aiTextureType_OPACITY: "Opacity",
    cMaterial.aiTextureType_DISPLACEMENT: "Displacement",
    cMaterial.aiTextureType_LIGHTMAP: "Lightmap",
    cMaterial.aiTextureType_REFLECTION: "Reflection",
    # PBR
    cMaterial.aiTextureType_BASE_COLOR: "Base Color",
    cMaterial.aiTextureType_NORMAL_CAMERA: "Normal Camera",
    cMaterial.aiTextureType_EMISSION_COLOR: "Emission Color",
    cMaterial.aiTextureType_METALNESS: "Metalness",
    cMaterial.aiTextureType_DIFFUSE_ROUGHNESS: "Diffuse Roughness",
    cMaterial.aiTextureType_AMBIENT_OCCLUSION: "Ambient Occlusion",

    cMaterial.aiTextureType_UNKNOWN: "Unknown"
}

cdef str TextureTypeToString(cMaterial.aiTextureType type):
    return TEXTURE_TYPE_DICT.get(type, "Unknown")

def stringToTextureType(str type):
    for key, value in TEXTURE_TYPE_DICT.items():
        if value.lower() == type.lower():
            return aiTextureType(key)
    return aiTextureType.aiTextureType_UNKNOWN

cdef str getTextureID(str type, int index):
    '''Function to create a texture ID string'''
    return f"TEXTURE_{type.replace(' ', '_').upper()}_{index}"

@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
cdef aiMaterial buildMaterial(cMaterial.aiMaterial* mat, int idx):
    cdef cMaterial.aiMaterialProperty* prop
    cdef dataStorageF pvalF
    cdef dataStorageI pvalI
    cdef cTypes.aiString pvalS, texPath
    cdef unsigned int ptype = 0, pvalsize = 0, i = 0, j = 0, semantic = 0, texType = 0, texIndex = 0, mIndex = 0
    cdef cTypes.aiReturn res
    cdef object propval = None
    cdef aiMaterial nMat = aiMaterial()
    cdef str sname, tname
    cdef cMaterial.aiTextureType type
    cdef TextureInfo tinfo
    cdef const char* mKey

    cdef cMaterial.aiTextureMapping mapping = cMaterial.aiTextureMapping_UV
    cdef unsigned int uvindex = 0
    cdef cdefs.ai_real blend = 1.0
    cdef cMaterial.aiTextureOp op = cMaterial.aiTextureOp_Multiply
    cdef unsigned int flags = 0
    cdef cMaterial.aiTextureMapMode mapmode[2]
    mapmode[:] = [cMaterial.aiTextureMapMode_Wrap, cMaterial.aiTextureMapMode_Wrap]

    cdef cTypes.aiString matName = mat.GetName()

    try:
        nMat.name = matName.data.decode("utf-8", errors="replace")
    except UnicodeDecodeError:
        nMat.name = str(matName.data)

    if nMat.name == '':
        nMat.name = f"UnnamedMaterial{idx}"

    # Parse properties
    for i in range(mat.mNumProperties):
        with nogil:
            prop = mat.mProperties[i]
            ptype = prop.mType
            semantic = prop.mSemantic
            mIndex = prop.mIndex
            mKey = prop.mKey.data
            if ptype == cMaterial.aiPTI_Float or ptype == cMaterial.aiPTI_Double:
                pvalsize = sizeof(dataStorageF)
                res =  cMaterial.aiGetMaterialFloatArray(mat, mKey, semantic, mIndex,
                                                         <float*>&pvalF, &pvalsize)
            elif ptype == cMaterial.aiPTI_Integer:
                pvalsize = sizeof(dataStorageI)
                res =  cMaterial.aiGetMaterialIntegerArray(mat, mKey, semantic, mIndex,
                                                           <int*>&pvalI, &pvalsize)
            elif ptype == cMaterial.aiPTI_String:
                res =  cMaterial.aiGetMaterialString(mat, mKey, semantic, mIndex, &pvalS)
            else:
                if ptype != cMaterial.aiPTI_Buffer:
                    printf("Unhandled Property type: %d\n", ptype)
                continue

        try:
            sname = mKey.decode("utf-8", errors="replace")
        except UnicodeDecodeError:
            sname = str(mKey)

        sname = propertyNames.get(sname, sname)

        if semantic != cMaterial.aiTextureType_NONE:
            tname = TextureTypeToString(<cMaterial.aiTextureType>semantic)
            separator = "_" if sname in propertyNames else "."
            sname += f"{separator}{tname.upper() if separator == '_' else tname}{separator}{mIndex}"
            sname = sname.replace(' ', '_')

        if res == cTypes.aiReturn_FAILURE:
            print(f"Failed to retrieve value of property '{sname}'.")
            continue
        elif res == cTypes.aiReturn_OUTOFMEMORY:
            raise MemoryError('Out of memory.')

        if ptype == cMaterial.aiPTI_Float  or ptype == cMaterial.aiPTI_Double:
            if pvalsize == 1:
                propval = pvalF.data[0]
            else:
                pvalF.validLenght = pvalsize
                propval = asNumpyArray(&pvalF)
        elif ptype == cMaterial.aiPTI_Integer:
            if pvalsize == 1:
                propval = pvalI.data[0]
            else:
                pvalI.validLenght = pvalsize
                propval = asNumpyArray(&pvalI)
        elif ptype == cMaterial.aiPTI_String:
            try:
                propval = pvalS.data.decode("utf-8", errors="replace")
            except UnicodeDecodeError:
                propval = str(pvalS.data)

        nMat.properties[sname] = propval

    # Parse textures
    for texType in range(<unsigned int>cMaterial.aiTextureType_UNKNOWN):
        type = <cMaterial.aiTextureType>texType
        for texIndex in range(<unsigned int>mat.GetTextureCount(type)):
            tname = getTextureID(TextureTypeToString(type), texIndex)
#            with nogil:
#                res =  mat.GetTexture(type, texIndex, &texPath,
#                                  &mapping, &uvindex, &blend, &op, mapmode)
            res = cMaterial.aiGetMaterialTexture(mat, type, texIndex, &texPath,
                                              &mapping, &uvindex, &blend, &op,
                                              mapmode, &flags)

            if res == cTypes.aiReturn_SUCCESS:
                try:
                    tpath = texPath.data.decode("utf-8", errors="replace")
                except UnicodeDecodeError:
                    tpath = str(texPath.data)

                tinfo = TextureInfo(texType, texIndex, tpath, mapping, uvindex, blend, op, mapmode)
                nMat.textures[tname] = tinfo

    return nMat


cdef class TextureInfo:
    cdef readonly object type
    cdef readonly unsigned int index
    cdef readonly str path
    cdef readonly object mapping
    cdef readonly int uvindex
    cdef readonly float blend
    cdef readonly object op
    cdef readonly list mapmode

    def __init__(self, type, index, path, mapping,
        uvindex,
        blend,
        op,
        mapmode):
        self.type     = aiTextureType(type)
        self.index    = index
        self.path     = path
        self.mapping  = aiTextureMapping(mapping)
        self.uvindex  = uvindex
        self.blend    = blend
        self.op       = aiTextureOp(op)
        self.mapmode  = [aiTextureMapMode(mm) for mm in mapmode]

# -----------------------------------------------------

cdef class aiTexture:
    cdef readonly unsigned int mWidth
    cdef readonly unsigned int mHeight
    cdef readonly char achFormatHint[9]
    cdef readonly np.ndarray pcData
    cdef readonly str mFilename

    def __init__(self):
        self.mWidth = 0
        self.mHeight = 0
        self.mFilename = ''

    def __repr__(self):
        return f"texture {self.mWidth} x {self.mHeight}"
        
@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
cdef aiTexture buildTexture(cTexture.aiTexture* tex):
    cdef aiTexture nTex = aiTexture()
    nTex.mWidth=tex.mWidth
    nTex.mHeight=tex.mHeight
    nTex.achFormatHint=tex.achFormatHint
    try:
        nTex.mFilename = tex.mFilename.data.decode("utf-8", errors="replace")
    except UnicodeDecodeError:
        nTex.mFilename = str(tex.mFilename.data)
    if nTex.mHeight==0 and nTex.mWidth>0:
        nTex.pcData = np.empty(nTex.mWidth, dtype=NUMPYBYTE)
#        with nogil:
        memcpy(<void*>nTex.pcData.data, <void*>&tex.pcData[0],  nTex.mWidth * sizeof(NUMPYBYTE_t))
    elif nTex.mHeight>0 and nTex.mWidth>0:
        nTex.pcData = np.empty(nTex.mWidth*nTex.mHeight*4, dtype=NUMPYBYTE)
#        with nogil:
        memcpy(<void*>nTex.pcData.data, <void*>&tex.pcData[0],  nTex.mWidth*nTex.mHeight * 4 * sizeof(NUMPYBYTE_t))
    else:
        raise RuntimeError(f"Unhandled texture arrangement (nTex.mWidth={nTex.mWidth})")

    return nTex


# -----------------------------------------------------
cdef class aiKey:
    cdef readonly double mTime
    cdef readonly np.ndarray mValue
    def __init__(self):
        pass

    def __str__(self):
        return '{:0>5}->{}'.format(self.mTime, self.mValue)

cdef class aiNodeAnim:
    cdef readonly str mNodeName
    cdef readonly list mPositionKeys
    cdef readonly list mRotationKeys
    cdef readonly list mScalingKeys
    # cdef readonly aiAnimBehaviour mPreState
    # cdef readonly aiAnimBehaviour mPostState

    def __init__(self):
        self.mNodeName = ''
        self.mPositionKeys = []
        self.mRotationKeys = []
        self.mScalingKeys = []

    def __str__(self):
        return self.mNodeName

@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
cdef aiNodeAnim buildAnimNode(cAnim.aiNodeAnim* channel):
    cdef unsigned int i = 0, k = 0
    cdef cAnim.aiVectorKey vkey
    cdef cAnim.aiQuatKey rkey
    cdef aiNodeAnim node = aiNodeAnim()

    try:
        node.mNodeName = channel.mNodeName.data.decode("utf-8", errors="replace")
    except UnicodeDecodeError:
        node.mNodeName = str(channel.mNodeName.data)

    k = channel.mNumPositionKeys
    for i in range(k):
        vkey = channel.mPositionKeys[i]
        node.mPositionKeys.append(buildKey(&vkey))

    k = channel.mNumRotationKeys
    for i in range(k):
        rkey = channel.mRotationKeys[i]
        node.mRotationKeys.append(buildKey(&rkey))

    k = channel.mNumScalingKeys
    for i in range(k):
        vkey = channel.mScalingKeys[i]
        node.mScalingKeys.append(buildKey(&vkey))

    return node

@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
cdef aiKey buildKey(anykey* key):
    cdef aiKey pykey = aiKey()
    cdef unsigned int kl
    if anykey  == cAnim.aiVectorKey:
        kl = 3
    else:
        kl = 4
    pykey.mValue = np.empty((kl), dtype=NUMPYFLOAT)
#    with nogil:
    pykey.mTime = key.mTime
    memcpy(<void*>pykey.mValue.data, <void*>&key.mValue, kl * sizeof(NUMPYFLOAT_t))
    return pykey

cdef class aiAnimation:
    cdef readonly str mName
    cdef readonly double mDuration
    cdef readonly double mTicksPerSecond
    cdef readonly list mChannels

    def __init__(self):
        self.mName = ''
        self.mChannels = []

    def __str__(self):
        return self.mName

@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
cdef aiAnimation buildAnimation(cAnim.aiAnimation* anim):
    cdef aiAnimation nAnim = aiAnimation()
    cdef unsigned int i = 0, k = 0
    try:
        nAnim.mName = anim.mName.data.decode("utf-8", errors="replace")
    except UnicodeDecodeError:
        nAnim.mName = str(anim.mName.data)
    nAnim.mDuration = anim.mDuration
    nAnim.mTicksPerSecond = anim.mTicksPerSecond
    k = anim.mNumChannels
    for i in range(k):
        nAnim.mChannels.append(buildAnimNode(anim.mChannels[i]))
    return nAnim

# -----------------------------------------------------

cdef class aiScene:
    # self.mFlags
    cdef readonly aiNode mRootNode
    cdef readonly int mNumMeshes
    cdef readonly list mMeshes
    cdef readonly int mNumMaterials
    cdef readonly list mMaterials
    cdef readonly int mNumAnimations
    cdef readonly list mAnimations
    cdef readonly int mNumTextures
    cdef readonly list mTextures
    cdef readonly int mNumLights
    # cdef readonly list mLights
    cdef readonly int mNumCameras
    # cdef readonly list mCameras

    cdef readonly bool HasMeshes
    cdef readonly bool HasMaterials
    cdef readonly bool HasLights
    cdef readonly bool HasTextures
    cdef readonly bool HasCameras
    cdef readonly bool HasAnimations

    def __init__(self):
        self.mMeshes = []
        self.mMaterials = []
        self.mAnimations = []
        self.mTextures = []

@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
cdef aiScene buildScene(const cScene.aiScene *cs):
    cdef aiScene scene = aiScene()
    cdef unsigned int i = 0, k = 0
    # scene.mFlags
    scene.mRootNode  = buildNode(cs.mRootNode, None)
    scene.mNumMeshes = cs.mNumMeshes
    scene.mNumMaterials = cs.mNumMaterials
    scene.mNumAnimations = cs.mNumAnimations
    scene.mNumTextures = cs.mNumTextures
    scene.mNumLights = cs.mNumLights
    #scene.mLights
    scene.mNumCameras = cs.mNumCameras
    #scene.mCameras

    scene.HasMeshes = scene.mNumMeshes
    scene.HasMaterials = scene.mNumMaterials
    scene.HasLights = scene.mNumLights
    scene.HasTextures = scene.mNumTextures
    scene.HasCameras = scene.mNumCameras
    scene.HasAnimations = scene.mNumAnimations

    k = scene.mNumMeshes
    for i in range(k):
        scene.mMeshes.append(buildMesh(cs.mMeshes[i]))

    k = scene.mNumMaterials
    for i in range(k):
        scene.mMaterials.append(buildMaterial(cs.mMaterials[i], i))

    k = scene.mNumAnimations
    for i in range(k):
        scene.mAnimations.append(buildAnimation(cs.mAnimations[i]))

    k = scene.mNumTextures
    for i in range(k):
        scene.mTextures.append(buildTexture(cs.mTextures[i]))

    return scene


# -----------------------------------------------------

def aiImportFile(str filepath, unsigned int flags=0):
    """
    Usage:
        scene = aiImportFile(path, flags)
    There is no need to use 'aiReleaseImport' after.


    :param filepath: The path to the 3d model file.
    :type filepath: str
    :param flags: (Optional) Any "or'ed" combination of aiPostrocessStep flags.
    :type flags: int
    :rtype: aiScene
    """
    cdef const cScene.aiScene* csc
    cdef bytes bpath = filepath.encode()
    cdef const char* cpath = bpath
    with nogil:
        csc = cImporter.aiImportFile(cpath, flags)
    if csc:
        try:
            return buildScene(csc)
        except Exception as err:
            raise err
        finally:
            with nogil:
                cImporter.aiReleaseImport(csc)
    else:
        raise AssimpError(cImporter.aiGetErrorString())


def aiReleaseImport(aiScene pScene):
     warn(RuntimeWarning('Releasing the scene in \'AssimpCy\' is not needed.'))

class AssimpError(Exception):
    pass

# -----------------------------------------------------

class aiReturn(Enum):
    SUCCESS = cTypes.aiReturn_SUCCESS
    FAILURE = cTypes.aiReturn_FAILURE
    OUTOFMEMORY = cTypes.aiReturn_OUTOFMEMORY

cdef class aiExportFormatDesc:
    cdef readonly str id
    cdef readonly str description
    cdef readonly str fileExtension

    def __init__(self):
        self.id = ''
        self.description = ''
        self.fileExtension = ''

    def __str__(self):
        return self.id

def aiGetExportFormatCount():
    """
    Returns the number of export file formats available in the current Assimp build.
    Use aiGetExportFormatDescription() to retrieve info of a specific export format.
    """
    return cExporter.aiGetExportFormatCount()

def aiGetExportFormatDescription(int pIndex):
    """
    Returns a description of the nth export file format. Use aiGetExportFormatCount()
    to learn how many export formats are supported.
    @param pIndex Index of the export format to retrieve information for. Valid range is
    0 to aiGetExportFormatCount()
    @return A description of that specific export format. NULL if pIndex is out of range.
    """
    desc = aiExportFormatDesc()
    cdef const cExporter.aiExportFormatDesc* cdesc
    cdesc = cExporter.aiGetExportFormatDescription(pIndex)
    cdef const char* cid = cdesc.id
    cdef const char* cdescdesc = cdesc.description
    cdef const char* cext = cdesc.fileExtension
    cdef str pid = cid.decode("utf-8", errors="replace")
    cdef str pdesc = cdescdesc.decode("utf-8", errors="replace")
    cdef str pext = cext.decode("utf-8", errors="replace")
    desc.id = pid
    desc.description = pdesc
    desc.fileExtension = pext
    cExporter.aiReleaseExportFormatDescription(cdesc)
    return desc

class Exporter:
    def getExportFormatsList(self):
        if self._fileFormats is None:
            self._fileFormats = []
            for i in range(aiGetExportFormatCount()):
                desc = aiGetExportFormatDescription(i)
                id_ = desc.id
                ext = desc.fileExtension
                desc = desc.description
                self._fileFormats.append((ext, id_, desc))
        return self._fileFormats

    def __init__(self):
        self._fileFormats = None
        self._fileFormats = self.getExportFormatsList()
        lookup = {}
        for index, (extension_string, id_string, description_string) in enumerate(self._fileFormats):
            lookup[id_string] = index
            lookup['.'+extension_string] = index
        self._lookup = lookup

    def query_formatId_or_extension(self, query):
        return self._lookup.get(query, None)

    def convertFile(self, str sourcePath, str destinationPath, str formatId, unsigned int flags=0):
        """
        :param sourcePath: The path to the 3d model file to convert.
        :type sourcePath: str
        :param destinationPath: The path to save the converted 3d model.
        :type destinationPath: str
        :param flags: (Optional) Any "or'ed" combination of aiPostrocessStep flags.
        :type flags: int
        :rtype: aiScene
        """
        cdef const cScene.aiScene* csc
        cdef bytes spath = sourcePath.encode()
        cdef const char* cpath = spath
        cdef bytes dpath = destinationPath.encode()
        cdef const char* cdpath = dpath
        cdef bytes fid
        cdef const char* cfid
        cdef cTypes.aiReturn ret
#        cdef cExporter.Exporter exporter = new cExporter.Exporter()

        if not path.exists(path.dirname(destinationPath)):
            raise FileNotFoundError('Destination path does not exist.')

        format_type = 'extension' if formatId.startswith('.') else 'format'
        format_index = self.query_formatId_or_extension(formatId)

        if format_index is None:
            raise RuntimeError(f"Specified {format_type} ('{formatId}') is not registered as an export format.")
        elif format_type == "extension":
            format_id = self._fileFormats[format_index][1]

        fid = formatId.encode()
        cfid = fid

        with nogil:
            csc = cImporter.aiImportFile(cpath, flags)
            if csc:
                ret = cExporter.aiExportScene(csc, cfid, cdpath, 0)
                cImporter.aiReleaseImport(csc)
                with gil:
                    if ret == cTypes.aiReturn_OUTOFMEMORY:
                        raise MemoryError('Out of memory.')
                    else:
                        return aiReturn(ret)
            else:
                with gil:
                    raise AssimpError(cImporter.aiGetErrorString())

#            del exporter
#            exporter = NULL

cdef cppclass dataStorageF nogil:
    NUMPYFLOAT_t data[16]
    unsigned int validLenght
    dataStorageF():
        validLenght = 0

cdef cppclass dataStorageI nogil:
    NUMPYINT_t data[16]
    unsigned int validLenght
    dataStorageI():
        validLenght = 0

@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
cdef np.ndarray asNumpyArray(i_f* ds):
    cdef unsigned int i = 0
    cdef np.ndarray[NUMPYFLOAT_t, ndim=1] retF
    cdef np.ndarray[NUMPYINT_t, ndim=1] retI

    cdef NUMPYFLOAT_t[:] farr_view
    cdef NUMPYFLOAT_t[:] dsfarr_view
    cdef NUMPYINT_t[:] iarr_view
    cdef NUMPYINT_t[:] dsiarr_view

    if i_f is dataStorageI:
        retI = np.empty([ds.validLenght], dtype=NUMPYINT)
        dsiarr_view = ds.data
        iarr_view =  retI
#        with nogil:
        for i in range(ds.validLenght):
            iarr_view[i] = dsiarr_view[i]
        return retI
    else:
        retF = np.empty([ds.validLenght], dtype=NUMPYFLOAT)
        dsfarr_view = ds.data
        farr_view = retF
#        with nogil:
        for i in range(ds.validLenght):
            farr_view[i] = dsfarr_view[i]
        return retF


class aiPostProcessSteps(Flag):
    aiProcessPreset_TargetRealtime_Fast        =  cPostProcess.aiProcessPreset_TargetRealtime_Fast
    aiProcessPreset_TargetRealtime_MaxQuality  =  cPostProcess.aiProcessPreset_TargetRealtime_MaxQuality
    aiProcessPreset_TargetRealtime_Quality     =  cPostProcess.aiProcessPreset_TargetRealtime_Quality
    aiProcess_CalcTangentSpace                 =  cPostProcess.aiProcess_CalcTangentSpace
    aiProcess_ConvertToLeftHanded              =  cPostProcess.aiProcess_ConvertToLeftHanded
    aiProcess_Debone                           =  cPostProcess.aiProcess_Debone
    aiProcess_DropNormals                      =  cPostProcess.aiProcess_DropNormals
    aiProcess_EmbedTextures                    =  cPostProcess.aiProcess_EmbedTextures
    aiProcess_FindDegenerates                  =  cPostProcess.aiProcess_FindDegenerates
    aiProcess_FindInstances                    =  cPostProcess.aiProcess_FindInstances
    aiProcess_FindInvalidData                  =  cPostProcess.aiProcess_FindInvalidData
    aiProcess_FixInfacingNormals               =  cPostProcess.aiProcess_FixInfacingNormals
    aiProcess_FlipUVs                          =  cPostProcess.aiProcess_FlipUVs
    aiProcess_FlipWindingOrder                 =  cPostProcess.aiProcess_FlipWindingOrder
    aiProcess_ForceGenNormals                  =  cPostProcess.aiProcess_ForceGenNormals
    aiProcess_GenBoundingBoxes                 =  cPostProcess.aiProcess_GenBoundingBoxes
    aiProcess_GenNormals                       =  cPostProcess.aiProcess_GenNormals
    aiProcess_GenSmoothNormals                 =  cPostProcess.aiProcess_GenSmoothNormals
    aiProcess_GenUVCoords                      =  cPostProcess.aiProcess_GenUVCoords
    aiProcess_GlobalScale                      =  cPostProcess.aiProcess_GlobalScale
    aiProcess_ImproveCacheLocality             =  cPostProcess.aiProcess_ImproveCacheLocality
    aiProcess_JoinIdenticalVertices            =  cPostProcess.aiProcess_JoinIdenticalVertices
    aiProcess_LimitBoneWeights                 =  cPostProcess.aiProcess_LimitBoneWeights
    aiProcess_MakeLeftHanded                   =  cPostProcess.aiProcess_MakeLeftHanded
    aiProcess_OptimizeGraph                    =  cPostProcess.aiProcess_OptimizeGraph
    aiProcess_OptimizeMeshes                   =  cPostProcess.aiProcess_OptimizeMeshes
    aiProcess_PopulateArmatureData             =  cPostProcess.aiProcess_PopulateArmatureData
    aiProcess_PreTransformVertices             =  cPostProcess.aiProcess_PreTransformVertices
    aiProcess_RemoveComponent                  =  cPostProcess.aiProcess_RemoveComponent
    aiProcess_RemoveRedundantMaterials         =  cPostProcess.aiProcess_RemoveRedundantMaterials
    aiProcess_SortByPType                      =  cPostProcess.aiProcess_SortByPType
    aiProcess_SplitByBoneCount                 =  cPostProcess.aiProcess_SplitByBoneCount
    aiProcess_SplitLargeMeshes                 =  cPostProcess.aiProcess_SplitLargeMeshes
    aiProcess_TransformUVCoords                =  cPostProcess.aiProcess_TransformUVCoords
    aiProcess_Triangulate                      =  cPostProcess.aiProcess_Triangulate
    aiProcess_ValidateDataStructure            =  cPostProcess.aiProcess_ValidateDataStructure

    def __int__(self):
        return self.value

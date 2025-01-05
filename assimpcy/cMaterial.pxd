from .cTypes cimport *
from .cdefs cimport ai_real

cdef extern from "material.h" nogil:

    cdef cppclass aiUVTransform:
        aiVector2D mTranslation
        aiVector2D mScaling
        ai_real mRotation

        aiUVTransform()


    cdef cppclass aiMaterialProperty:
        aiString mKey
        unsigned int mSemantic
        unsigned int mIndex
        unsigned int mDataLength
        aiPropertyTypeInfo mType
        char* mData
    
        aiMaterialProperty()


    cdef cppclass aiMaterial:
        aiMaterialProperty** mProperties;
        unsigned int mNumProperties;
        unsigned int mNumAllocated;

        aiMaterial()

        aiString GetName() const

        int GetTextureCount(aiTextureType type) const

        aiReturn GetTexture(aiTextureType type,
                            unsigned int  index,
                            aiString* path,
                            aiTextureMapping* mapping,
                            unsigned int* uvindex,
                            ai_real* blend,
                            aiTextureOp* op,
                            aiTextureMapMode* mapmode) const


    cdef unsigned int aiGetMaterialTextureCount(const aiMaterial* pMat, aiTextureType type)

    cdef aiReturn aiGetMaterialTexture(const aiMaterial* mat,
                                        aiTextureType type,
                                        unsigned int  index,
                                        aiString* path,
                                        aiTextureMapping* mapping,
                                        unsigned int* uvindex	,
                                        ai_real* blend			,
                                        aiTextureOp* op			,
                                        aiTextureMapMode* mapmode,
                                        unsigned int* flags       )

    cdef aiReturn aiGetMaterialString(const aiMaterial* pMat,
                                        const char* pKey,
                                        unsigned int type,
                                        unsigned int index,
                                        aiString* pOut)

    cdef aiReturn aiGetMaterialFloatArray(const aiMaterial* pMat,
                                             const char* pKey,
                                             unsigned int type,
                                             unsigned int index,
                                             float* pOut,
                                             unsigned int* pMax)

    cdef aiReturn aiGetMaterialIntegerArray(const aiMaterial* pMat,
                                            const char* pKey,
                                            unsigned int type,
                                            unsigned int index,
                                            int* pOut,
                                            unsigned int* pMax)


    cdef enum aiTextureType:
        aiTextureType_NONE
        aiTextureType_DIFFUSE
        aiTextureType_SPECULAR
        aiTextureType_AMBIENT
        aiTextureType_EMISSIVE
        aiTextureType_HEIGHT
        aiTextureType_NORMALS
        aiTextureType_SHININESS
        aiTextureType_OPACITY
        aiTextureType_DISPLACEMENT
        aiTextureType_LIGHTMAP
        aiTextureType_REFLECTION
        # PBR materials
        aiTextureType_BASE_COLOR
        aiTextureType_NORMAL_CAMERA
        aiTextureType_EMISSION_COLOR
        aiTextureType_METALNESS
        aiTextureType_DIFFUSE_ROUGHNESS
        aiTextureType_AMBIENT_OCCLUSION

        aiTextureType_UNKNOWN

        #  PBR Material Modifiers
        aiTextureType_SHEEN
        aiTextureType_CLEARCOAT
        aiTextureType_TRANSMISSION
        # Maya material declarations
        aiTextureType_MAYA_BASE
        aiTextureType_MAYA_SPECULAR
        aiTextureType_MAYA_SPECULAR_COLOR
        aiTextureType_MAYA_SPECULAR_ROUGHNESS

    cdef enum aiPropertyTypeInfo:
        aiPTI_Float
        aiPTI_Double
        aiPTI_String
        aiPTI_Integer
        aiPTI_Buffer

    cdef enum aiTextureOp:
        aiTextureOp_Multiply
        aiTextureOp_Add
        aiTextureOp_Subtract
        aiTextureOp_Divide
        aiTextureOp_SmoothAdd
        aiTextureOp_SignedAdd

    cdef enum aiTextureMapping:
        aiTextureMapping_UV
        aiTextureMapping_SPHERE
        aiTextureMapping_CYLINDER
        aiTextureMapping_BOX
        aiTextureMapping_PLANE
        aiTextureMapping_OTHER

    cdef enum aiTextureMapMode:
        aiTextureMapMode_Wrap
        aiTextureMapMode_Clamp
        aiTextureMapMode_Decal
        aiTextureMapMode_Mirror

    cdef enum aiShadingMode:
        aiShadingMode_Flat
        aiShadingMode_Gouraud
        aiShadingMode_Phong
        aiShadingMode_Blinn
        aiShadingMode_Toon
        aiShadingMode_OrenNayar
        aiShadingMode_Minnaert
        aiShadingMode_CookTorrance
        aiShadingMode_NoShading
        aiShadingMode_Unlit
        aiShadingMode_Fresnel
        aiShadingMode_PBR_BRDF

    cdef enum aiTextureFlags:
        aiTextureFlags_Invert
        aiTextureFlags_UseAlpha
        aiTextureFlags_IgnoreAlpha

    cdef enum aiBlendMode:
        aiBlendMode_Default
        aiBlendMode_Additive


    cdef char* AI_MATKEY_TEXTURE(aiTextureType type, int N)
    cdef char* AI_MATKEY_UVWSRC(aiTextureType type, int N)
    cdef char* AI_MATKEY_TEXOP(aiTextureType type, int N)
    cdef char* AI_MATKEY_MAPPING(aiTextureType type, int N)
    cdef char* AI_MATKEY_TEXBLEND(aiTextureType type, int N)
    cdef char* AI_MATKEY_MAPPINGMODE_U(aiTextureType type, int N)
    cdef char* AI_MATKEY_MAPPINGMODE_V(aiTextureType type, int N)
    cdef char* AI_MATKEY_TEXMAP_AXIS(aiTextureType type, int N)
    cdef char* AI_MATKEY_UVTRANSFORM(aiTextureType type, int N)
    cdef char* AI_MATKEY_TEXFLAGS(aiTextureType type, int N)

from .cScene cimport aiScene
from .cTypes cimport *
from .cdefs cimport ai_real

from libcpp.map cimport map
from libcpp.string cimport string


cdef extern from "cexport.h" nogil:
    cdef struct aiExportFormatDesc:
        const char* id
        const char* description
        const char* fileExtension

    size_t aiGetExportFormatCount()
    const aiExportFormatDesc* aiGetExportFormatDescription( size_t pIndex)
    void aiReleaseExportFormatDescription( const aiExportFormatDesc *desc)

    aiReturn aiExportScene(const aiScene* pScene, const char* pFormatId,
                           const char* pFileName, unsigned int pPreprocessing) except +


#cdef extern from "Exporter.hpp" nogil:
#    cdef cppclass ExportProperties:
#        ctypedef unsigned int KeyType
#        ctypedef map[KeyType, int] IntPropertyMap
#        ctypedef map[KeyType, ai_real] FloatPropertyMap
#        ctypedef map[KeyType, string] StringPropertyMap
#        ctypedef map[KeyType, aiMatrix4x4] MatrixPropertyMap
#
#        ExportProperties()
#
#    cdef cppclass Exporter:
#
#        Exporter()
#        aiReturn Export( const aiScene* pScene, const char* pFormatId, const char* pPath,
#                unsigned int pPreprocessing = 0u, const ExportProperties* pProperties = nullptr)
#
#        void SetProgressHandler(ProgressHandler* pHandler)
#        const char* GetErrorString() const
#        size_t GetExportFormatCount() const
#        const aiExportFormatDesc* GetExportFormatDescription( size_t pIndex ) const

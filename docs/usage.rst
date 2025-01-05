Usage
=====

Model import
^^^^^^^^^^^^
The whole work to import a model with :mod:`assimpcy` is done by :func:`aiImportFile`

The package uses the same functions and parameter names of the original library, so examples from the
official Assimp docs and other tutorials can be used with minor changes.

.. code:: python

   from assimpcy import aiImportFile, aiPostProcessSteps as pp
   flags = pp.aiProcess_JoinIdenticalVertices | pp.aiProcess_Triangulate
   scene = aiImportFile('some_model.3ds', flags)
   print('Vertex 0 = {}'.format(scene.mMeshes[0].mVertices[0]))

Matrices, quaternions and vectors are returned as Numpy arrays.

.. note::
   There is no need to release the scene. This job is performed by :py:func:`aiImportFile`


Textures
^^^^^^^^

To locate the model's textures, first you need to retrieve the materials, let's say *material 0*:

.. code:: python

   material0 = scene.mMaterials[0]

Depending on the file format, each material may contain one or more properties called `TEXTURE_usage_IDX`, where:

- **usage** corresponds to one of the texture types found on :py:enum:`aiTextureType` enumeration.
  The actual string used in the property can be queried by passing a type to :py:func:`TextureTypeToString`.
- **IDX** is the channel the texture belongs to.

For instance, a property called `TEXTURE_DIFFUSE_0` found in material *0* would correspond to the texture file to be
used in the slot **0** of the **diffuse** channel of the first material. This property will either be a
string pointing to:

1. A file in the model's folder (or a subfolder),
2. A file in an accompanying archive (e.g., "textures.zip"), or
3. An *embedded texture* included in the scene structure, under :py:class:`scene.mTextures`.

If it's the latter, the string will start with a "*", followed by the texture's index in `mTextures`::

   "*0" corresponds to `scene.mTextures[0]`
   "*1" is `scene.mTextures[1]`

And so on.

Some file formats, instead of or in addition to this, include a list of :py:class:`FileInfo` objects in the
`textures` dictionary of each material:

.. code:: python

    keys, values = zip(*material0.textures.items())

Each value will be an instance of :py:class:`FileInfo` using a "texture ID" as key (e.g., TEXTURE_DIFFUSE_0).
If present, `FileInfo` objects will containing useful information to render every texture of the model.
Specifically, three members are required to obtain a texture and assign it:

- **type**: One of :py:enum:`aiTextureType`.
- **index**: The channel the texture belongs to
- **path**: The path where this texture can be located. Has the same value as the material's property with
  the same key::

     `material0.textures['TEXTURE_DIFFUSE_0'].path` == `material0.properties['TEXTURE_DIFFUSE_0']`

In any case, to query the presence of a given texture type and retrieve the file path:

.. code:: python

    from assimpcy import getTextureID
    mat0_textures = {}
    wanted_textures = ["Diffuse", "Normals", "Base Color"]  # values from 'assimpcy.TEXTURE_TYPE_DICT'
    index = 0  # for channel 0. Query others if needed
    for wt in wanted_textures:
        tid = getTextureID(wt, index)
        if tid in material0.properties:
            mat0_textures[wt] = material0.properties[tid]
        elif tid in material0.textures:
            mat0_textures[wt] = material0.textures[tid].path


Embedded textures
^^^^^^^^^^^^^^^^^

When a model includes the textures within the same file, they are stored in the :py:class:`scene.mTextures` list.

To extract them:

.. code:: python

    from assimpcy import aiImportFile, aiPostProcessSteps as pp
    flags = pp.aiProcess_JoinIdenticalVertices | pp.aiProcess_Triangulate
    scene = aiImportFile('my_model.3ds', flags)
    if scene.HasTextures:
        from io import BytesIO
        from PIL import Image
        import numpy as np
        for t in scene.mTextures:
            data = t.pcData
            hint = t.achFormatHint.decode()
            if len(hint) == 3:
                # the hint indicates the texture format as an extension (e.g., png)
                img_file = BytesIO(data)
                img = Image.open(img_file)  # let Pillow figure out the image format
                w, h = img.size
                data = np.asarray(img)
                # flatten the data array
                # to send it to a graphics library
            else:
                # no hint or raw data description (e.g., argb8888)
                w, h = t.mWidth, t.mHeight
                data = np.reshape(data, (h, w, 4))  # << skip this to keep the array
                                                    # flat for use in a graphics library

            # store the 'data' variable for later use or save it as a file
            # using the extension from the hint, if present, or as a format compatible with the texture components


Conversion
^^^^^^^^^^^^^^^^^

You can convert a model directly from one format to another using the :py:func:`convertFile` function of
:py:class:`Exporter`.

.. code:: python

    from assimpcy import Exporter
    exporter = Exporter()
    model_path = 'my_model.3ds'
    destination = 'my_exported_model.dae'
    formatID = 'collada'
    ret = exporter.convertFile(model_path, destination, formatID)

Instead of passing a format name as 'formatID', you can pass an extension supported by your assimp build, e.g., '.dae'

.. code:: python

    ret = exporter.convertFile(model_path, destination, '.dae')

This function will convert all the data found in the original file into whatever is supported by the target format.
Check a more complete example in the `Github repo <https://github.com/jr-garcia/AssimpCy/blob/master/examples/>`_.

.. note::
    While :py:func:`convertFile` supports passing flags to modify the scene before export, this might be tricky.
    We suggest to experiment first with the usual flags and then, if the result is not the expected, remove all the
    flags and try again.
    From the Assimp docs:
        Specifying 'preprocessing' flags is useful if the input scene does not conform to
        Assimp's default conventions as specified in the Data Structures Page.
        In short, this means the geometry data should use a right-handed coordinate systems, face
        winding should be counter-clockwise and the UV coordinate origin is assumed to be in
        the upper left. The #aiProcess_MakeLeftHanded, #aiProcess_FlipUVs and
        #aiProcess_FlipWindingOrder flags are used in the import side to allow users
        to have those defaults automatically adapted to their conventions. Specifying those flags
        for exporting has the opposite effect, respectively.


.. note::
   Work is being done to implement arbitrary scene export into any supported format in a future release.


Cilly
^^^^^

`Cilly <https://github.com/jr-garcia/AssimpCy/tree/master/examples/models/cilly>`_ is a silly cylinder
that dances and dances.

.. image:: https://raw.githubusercontent.com/jr-garcia/AssimpCy/master/examples/models/cilly/cilly.png
    :alt: Cilly - 3D rigged and textured cylinder


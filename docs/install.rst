Installation
------------

First, you should try::

    pip install assimpcy

If that fails or if you want to make changes to the code or recompile the extension
with a different version of the Assimp library, you will have to compile from the sources.

For that you will need:

* Cmake 3
* Microsoft Visual Studio 2017+ for Windows, or Gcc for Linux and Mac (Clang might work too).
* Cython 3.0.11
* Numpy 1.24.4
* Python headers

Once you have those requirements, you can proceed.

#. Download AssimpCy from:

   https://github.com/jr-garcia/AssimpCy

   And extract the zip package (or clone the repository with Git).

#. Download Assimp from the official page (minimum version 5.4.3):

   http://www.assimp.org/

#. Configure Cmake with the following options::

    -DASSIMP_BUILD_TESTS=OFF -DASSIMP_BUILD_SAMPLES=OFF -DASSIMP_BUILD_ASSIMP_TOOLS=OFF -DBUILD_SHARED_LIBS=OFF -DASSIMP_NO_EXPORT=OFF -DASSIMP_BUILD_ZLIB=ON -DASSIMP_OPT_BUILD_PACKAGES=OFF -DCMAKE_BUILD_TYPE=Release


   Then compile and install Assimp with::

        make
        make install


   That should place Assimp headers and libraries where appropriate for your system.

#. Install `Cython <https://cython.org/>`_ and `Numpy <http://www.numpy.org/>`_ with::

    pip install cython==3.0.11 numpy==1.24.4


   .. note::
        The versions specified are the ones used to build the wheels stored at Pypi.
        You are free to try older or newer versions of the packages listed above, if available.

#. Build AssimpCy by executing, from its folder::

      python setup.py build_ext

   If setup.py can't find the headers, specify them manually::

      python setup.py build_ext -I'path/to/assimp/headers' -L'path/to/library/'

   .. attention::
       If you get an error saying::

           Cannot open include file: 'types.h':

       It means that setup.py is not finding the Assimp headers. Make sure that there is a folder called
       ``include`` in the AssimpCy files folder or in a path that your compiler can find.

#. Finally, to install the package, run::

      python setup.py install


Check `basic_demo.py <https://github.com/jr-garcia/AssimpCy/blob/master/examples/basic_demo.py>`_  in AssimpCy folder for a simple example or read :doc:`/usage`.
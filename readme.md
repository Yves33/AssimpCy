# AssimpCy 
[![PyPI - version](https://badge.fury.io/py/AssimpCy.svg)](https://pypi.org/project/AssimpCy/)
[![PyPI - Python Version](https://img.shields.io/pypi/pyversions/AssimpCy.svg)](https://img.shields.io)
[![PyPI - Satus](https://img.shields.io/pypi/status/AssimpCy.svg)](https://img.shields.io)
[![PyPI - License](https://img.shields.io/pypi/l/AssimpCy.svg)](https://img.shields.io)
[![PyPI - Downloads](https://img.shields.io/pypi/dm/assimpcy)](https://pypi.org/project/AssimpCy/)

##### BUILD STATUS 

#### `Linux   ` [![Linux Build Status](https://travis-ci.org/jr-garcia/AssimpCy.svg?branch=master)](https://travis-ci.org/jr-garcia/AssimpCy) 

#### `Windows ` [![Windows Build Status](https://ci.appveyor.com/api/projects/status/8r293a3s5x93iumw?svg=true)](https://ci.appveyor.com/project/jr-garcia/assimpcy)  

#### `Docs    ` [![Documentation Build Status](https://readthedocs.org/projects/assimpcy/badge/?version=latest)](http://assimpcy.readthedocs.io/en/latest/?badge=latest) 
        
        
Faster (than PyAssimp) Python bindings for [Assimp](http://assimp.org/), Cython-based, BSD3 license.

It uses the same naming as the original library, so examples from the official docs can be used directly (minus C sintaxis).
    
---

#### Example usage:

```python
from assimpcy import aiImportFile, aiPostProcessSteps as pp 
flags = pp.aiProcess_JoinIdenticalVertices | pp.aiProcess_Triangulate 
scene = aiImportFile('mymodel.3ds', flags)
print('Vertex {} = {}'.format(v, scene.mMeshes[0].mVertices[0]))
```

Matrices, quaternions and vectors are returned as Numpy arrays.

It is compatible with:

* Windows: Python 3.5+
* Linux: Python 2.7, 3.4+

---

#### Requirements:

* Assimp >= 3.1.1
* Numpy >= 1.9.2

---

#### Installation:

The easiest way is:

```sh
pip install assimpcy
```

If that does not work for you, please check [Installation](http://assimpcy.readthedocs.io/en/latest/install.html) for instructions. 

#### Missing:

* Cameras
* Lights
* Export functionality

Those might be added in the future.

#### Documentation

[Read The Docs](http://assimpcy.readthedocs.io/)

-----------------

And what about the name? Well, [cyassimp](https://github.com/menpo/cyassimp) was already taken 😞.
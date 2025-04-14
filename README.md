# AssimpCy 
![GitHub Tag](https://img.shields.io/github/v/tag/jr-garcia/assimpcy?label=Version)
[![PyPI - version](https://badge.fury.io/py/AssimpCy.svg)](https://pypi.org/project/AssimpCy/)
![PyPI - Python Version](https://img.shields.io/pypi/pyversions/AssimpCy.svg)

![PyPI - Status](https://img.shields.io/pypi/status/AssimpCy.svg)
![PyPI - License](https://img.shields.io/pypi/l/AssimpCy.svg)
![PyPI - Downloads](https://img.shields.io/pypi/dm/assimpcy)

#### BUILD STATUS 

[![Linux Build Status](https://github.com/jr-garcia/assimpcy/actions/workflows/main.yaml/badge.svg)](https://github.com/jr-garcia/assimpcy/) 
[![Documentation Build Status](https://readthedocs.org/projects/assimpcy/badge/?version=latest)](http://assimpcy.readthedocs.io/en/latest/?badge=latest)

---    
        
Fast Python bindings for [Assimp](http://assimp.org/), Cython-based, BSD3 license.

It uses the same function names as the original library, so examples from c++ tutorials can be used with minor changes.

It has been tested on:

* Windows 7, 10
* Linux
* Mac
* Python 3.8 - 3.10
* Pypy
---
#### Example usage:

```python
from assimpcy import aiImportFile, aiPostProcessSteps as pp 
flags = pp.aiProcess_JoinIdenticalVertices | pp.aiProcess_Triangulate 
scene = aiImportFile('some_model.3ds', flags)
print('Vertex 0 = {}'.format(scene.mMeshes[0].mVertices[0]))
```

Matrices, quaternions and vectors are returned as Numpy arrays.

---
#### Requirements:

* Numpy >= 1.24.4

(Assimp 5.4.3 is included in the binary wheel)

```
Open Asset Import Library (assimp)

Copyright (c) 2006-2021, assimp team
All rights reserved.
```
Please visit our [docs](https://assimpcy.readthedocs.io/en/latest/about.html#the-open-asset-import-library) to read the full license and 
to know more about your rights regarding Assimp.

---
#### Installation:

The easiest way is with Pip:

```sh
pip install assimpcy
```

If that doesn't work on your system or if you want to compile by yourself, 
please check [Installation](http://assimpcy.readthedocs.io/en/latest/install.html) for instructions. 

---
#### Missing:

* Cameras
* Lights
* Export functionality (basic conversion is working)

Those might be added in the future.

---
#### Changelog 
#### Version 3.0.1  

##### Enhancements  
- **Improved Memory Management**: Optimizations to ensure better performance and lower memory usage.
- **Format Conversion Functionality**: Added support for converting models between various formats using `convertFile`. 

##### Breaking Changes  
- **Scene Material Properties Update**:  
  The `scene.material.properties` structure has been updated to support modern file formats.  
  **This change is incompatible with the old naming convention.** Please refer to the updated documentation 
  for guidance on extracting material properties in this release.  

--- 
Thank you for using AssimpCy! 😊 The development of new features depends on your support. 
If this library is useful to you, consider contributing a donation to help me dedicate more time to improve it. 
Future enhancements will be prioritized based on the support received.  

**Upcoming Features**:  
> - Export functionality.  
> - Performance improvements.  
> - 🚀 Implementation of [your idea here].  

Support development and make it happen! 💸

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/R6R4S8UD4)

---
#### Documentation

[Read The Docs](https://assimpcy.readthedocs.io/)

---
#### Bug report and Contributions

Please follow the guide on the [wiki](https://github.com/jr-garcia/AssimpCy/wiki/Contributons-and-Bug-reports)

---

And what about the name? Well, [cyassimp](https://github.com/menpo/cyassimp) was already taken 😞
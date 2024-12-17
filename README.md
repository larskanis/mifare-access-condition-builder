mifare-access-condition-builder
===============================

https://github.com/larskanis/mifare-access-condition-builder

A GUI to calculate the access condition bytes of sectors of Mifare contactless chip cards

REQUIREMENTS
------------

* Ruby
* Fox toolkit (required on MacOS and Linux, builtin on Windows)

INSTALL + RUN
--------------

* On Windows install the Rubyinstaller (with or without Devkit) https://rubyinstaller.org/downloads/
* On Linux use `sudo apt install ruby-dev g++ libxrandr-dev libfox-1.6-dev` or similar

Then run on the command line:

```sh
$ gem install mifare-access-condition-builder
$ mifare_access_condition_builder
```

LICENSE
-------

(The MIT License)

Copyright (c) 2024 Lars Kanis - Sincnovation Falkenstein GmbH

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
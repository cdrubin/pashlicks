Pashlicks
=========

Pashlicks expects to be at the foot (root) of your site. She adds `_dir.lua`
to the environment of the underlying files of a directory.

Files and directories that begin with '_' or '.' are ignored.

She understands three kinds of tags inside source files :

1. Code
``` lua
{% for i = 1,5 do %}
  <br />
{% end %}
```

2. Value
``` lua
{% for i = 1,5 do %}
  <li>Item {{ i }}</li>
{% end %}
```

3. Include
``` lua
  {( "menu.html" )}
```

I usually use something like :

``` bash
lua pashlicks.lau _output
```

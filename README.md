Pashlicks
=========

Pashlicks expects to be at the foot (root) of your site. She adds 
the execution of `_dir.lua` to the environment of the contents of
a directory.

Files and directories that begin with `_` or `.` are ignored.

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

She could certainly process any filetype but we usually have her 
chew on HTML template files.

A common need when using Pashlicks as a static site generator 
is the use of a _layout_ or _template_ inside which to embed the 
content of a page. Specifying a layout can be done in a `_dir.lua`
file so that all pages in that directory and inner directories use
a particular layout. Specifying the layout template can of course 
also be done inside the page itself.

```lua
page.layout = '_layouts/site.html'
site.keywords = 'Dog-run'
```
avoid doing something like the following :
```lua
page = { layout = '_layouts/site.html' }
```
because you will be clobbering the page table contents created elsewhere.

When specifying a layout the page is rendered to the variable `page.content`.

So with a layout like this :

```
_dir.lua
_layouts/
  site.html
_snippets/
  menu.html
index.html
pashlicks.lua
```

we could have :
```
--- _dir.lua
page = { layout = '_layouts/site.html' }


--- _layouts/site.html
<html>
<head>
  <title>{{ page.title }}</title>
</head>
<body>
  {{ page.content }}
</body>
</html>


--- index.html
{% page.title = 'The truth about Pashlicks' %}

Pashlicks loves her sisters Josie and Marmite
```

to produce an index.html file containing :
```html
<html>
<head>
  <title>The truth about Pashlicks</title>
</head>
<body>

Pashlicks loves her sisters Josie and Marmite
</body>
</html>

```

An example of some customization is available in the included 
[_dir.lua](https://github.com/cdrubin/pashlicks/blob/master/_dir.lua). 
When this file is placed at the root of the site Pashlicks makes sure that
all pages have these values and functions available in their environment.

Every page has some *special* variables injected into its environment:

```lua
page.file     -- filename of file being processed
page.path     -- path to file from root of site
page.level    -- level in the tree at which this page sits
page.tree     -- subtree from this page    

site.tree     -- tree of site
```

Calling Pashlicks should be as simple as :

``` bash
lua pashlicks.lua _output
```

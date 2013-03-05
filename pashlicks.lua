local posix = require( 'posix' )
local lfs = require( 'lfs' )

-- templating features thanks to Zed Shaw's tir

local TEMPLATES = ''

-- load _site.lua
--local _site = require( '_site.lua' )

local TEMPLATE_ACTIONS = {
  ['{%'] = function(code)
    return code
  end,
  ['{{'] = function(code)
    return ('_result[#_result+1] = %s'):format(code)
  end,
  ['{('] = function(code)
    return ( [[
if not _children[%s] then
_children[%s] = render( %s )
end

_result[#_result+1] = _children[%s]( {} )
]] ):format( code, code, code, code )
  end
}



function compile( tmpl, name )
  local tmpl = tmpl .. '{}'
  local code = {'local _result, _children = {}, {}\n'}

  for text, block in string.gmatch( tmpl, "([^{]-)(%b{})" ) do
    local act = TEMPLATE_ACTIONS[block:sub( 1, 2 )]
    local output = text

    if act then
      code[#code+1] = '_result[#_result+1] = [[' .. text .. ']]'
      code[#code+1] = act(block:sub(3,-3))
    elseif #block > 2 then
      code[#code+1] = '_result[#_result+1] = [[' .. text .. block .. ']]'
    else
      code[#code+1] = '_result[#_result+1] = [[' .. text .. ']]'
    end
  end

  code[#code+1] = 'return table.concat(_result)'

  code = table.concat( code, '\n' )

  -- for error checking with details
  local func, err = loadstring( code )--, name )

  if err then
    assert(func, err)
  end

  return function( context )
    assert( context, "You must always pass in a table for context." )
    setmetatable( context, { __index = _G } )
    load( func, nil, nil, context )
    --setfenv( func, context )
    return func()
  end
end


function render( name )
  assert( posix.access(TEMPLATES .. name), "Template " .. TEMPLATES .. name .. " does not exist or wrong permissions.")

  local tempf = load_file( TEMPLATES, name )
  return compile( tempf, name )

end

-- recurse through tree and require _tree.lua as we go
--for ()

-- process each page in file listing

-- Helper function that loads a file into ram.
function load_file(from_dir, name)
  local intmp = assert(io.open(from_dir .. name, 'r'))
  local content = intmp:read('*a')
  intmp:close()

  return content
end

-- Helper function that uses loadstring to check code
function load_string()
  local func, err = loadstring( code, name )

  if err then
    assert( func, err )
  end

  return func
end

function load_code()
end


function render_tree( source, destination, indent )
  indent = indent or 0
  local whitespace = ' '

  for file in lfs.dir( source ) do
    if file:sub( 1, 1 ) ~= '_' and file:sub( 1, 1) ~= '.' and file ~= arg[0] then
      --local result = {}
      local attr = lfs.attributes( source..'/'..file )
      assert(type(attr) == "table")
      --result.text = file
      --result.id = path..'/'..file
      if attr.mode == "file" then
        print( whitespace:rep( indent )..file )
        -- render and white it out
        local output = io.open( destination..'/'..file, "w" )
        output:write( render( source..'/'..file )( {} ) )
        output:close()
        --result.leaf = true
        --result.children = nil
      elseif attr.mode == "directory" then
        print( whitespace:rep( indent )..file..'/    -->    '..destination..'/'..file )
        --result.leaf = false
        destination_attr = lfs.attributes( destination..'/'..file )
        if ( destination_attr == nil ) then
          lfs.mkdir( destination..'/'..file)
        end
        render_tree( source..'/'..file, destination..'/'..file, indent + 2 )
      end
      --table.insert(results, result)
    end
  end

  --return results
end


--function list_path( path )
--  local results = {}
--
--  for file in lfs.dir( path ) do
--    if file ~= "." and file ~= ".." and file[1] ~= '_' then
--      local result = {}
--      local attr = lfs.attributes( path..'/'..file )
--      assert(type(attr) == "table")
--      result.text = file
--      result.id = path..'/'..file
--      if attr.mode == "file" then
--        result.leaf = true
--        result.children = nil
--      elseif attr.mode == "directory" then
--        result.leaf = false
--        result.children = list_path( path..'/'..file )
--      end
--      table.insert(results, result)
--    end
--  end

--  return results
--end




--setfenv = function(f, t)
--  for up = 1, math.huge do
--    local name = debug.getupvalue(f, up)
--    if name == '_ENV' then
--      debug.setupvalue(f, up, t)
--      return
--    elseif name == nil then
--      return
--    end
--  end
--end

--print( render( 'index.html' )( {} ) )

--nuts = 999

local destination = arg[1] or nil

if ( #arg ~= 1 ) then
  print( 'Usage: lua '..arg[0]..' <destination>' )
else
  local destination_attr = lfs.attributes( destination )
  if type( destination_attr ) ~= 'table' or destination_attr.mode ~= 'directory' then
    print( '<destination> needs to be an existing directory' )
  else
    render_tree( '.', destination )
  end
end

--local files = list_path( '.' )
--foreach( file )

-- returns a tree of page (leaf) and folder (branch) nodes

--local node =

-- node
--   type: page or folder
--   title: set at the top of each page
--   slug: relative path to page
--   siblings: function()
--   children: function()

--function filetree( path )

--end

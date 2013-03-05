-- Pashlicks

--   templating features thanks to Zed Shaw's tir


local lfs = require( 'lfs' )

pashlicks = {}

pashlicks.TEMPLATE_ACTIONS = {
  ['{%'] = function(code)
    return code
  end,
  ['{{'] = function(code)
    return ('_result[#_result+1] = %s'):format(code)
  end,
  ['{('] = function(code)
    return ( [[
if not _children[%s] then
_children[%s] = pashlicks.render( %s )
end

_result[#_result+1] = _children[%s]( {} )
]] ):format( code, code, code, code )
  end
}



function pashlicks.compile( tmpl, name )
  local tmpl = tmpl .. '{}'
  local code = {'local _result, _children = {}, {}\n'}

  for text, block in string.gmatch( tmpl, "([^{]-)(%b{})" ) do
    local act = pashlicks.TEMPLATE_ACTIONS[block:sub( 1, 2 )]
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

  local func = pashlicks.load_string( code )

  return function( context )
    assert( context, "You must always pass in a table for context." )
    setmetatable( context, { __index = _G } )
    load( func, nil, nil, context )
    --setfenv( func, context )
    return func()
  end
end


function pashlicks.render( name )
  local tempf = pashlicks.load_file( name )
  return pashlicks.compile( tempf, name )
end

-- Helper function that loads a file into ram.
function pashlicks.load_file( name )
  local intmp = assert(io.open( name, 'r'))
  local content = intmp:read('*a')
  intmp:close()

  return content
end

-- Helper function that uses load to check code and return a lua function for the environment
function pashlicks.load_string( code )
  local func, err = load( code )

  if err then
    assert( func, err )
  end

  return func
end


function pashlicks.render_tree( source, destination, indent, context )
  indent = indent or 0
  context = context or {}

  local whitespace = ' '

  for file in lfs.dir( source ) do
    if file:sub( 1, 1 ) ~= '_' and file:sub( 1, 1) ~= '.' and file ~= arg[0] then
      local attr = lfs.attributes( source..'/'..file )
      assert(type(attr) == "table")
      if attr.mode == "file" then
        print( whitespace:rep( indent )..file )
        -- render and write it out
        local output = io.open( destination..'/'..file, "w" )
        output:write( pashlicks.render( source..'/'..file )( context ) )
        output:close()
      elseif attr.mode == "directory" then
        print( whitespace:rep( indent )..file..'/    -->    '..destination..'/'..file )
        destination_attr = lfs.attributes( destination..'/'..file )
        if ( destination_attr == nil ) then
          lfs.mkdir( destination..'/'..file)
        end
        pashlicks.render_tree( source..'/'..file, destination..'/'..file, indent + 2 )
      end
    end
  end

end





pashlicks.destination = arg[1] or nil

if ( #arg ~= 1 ) then
  print( 'Usage: lua '..arg[0]..' <destination>' )
else
  local destination_attr = lfs.attributes( pashlicks.destination )
  if type( destination_attr ) ~= 'table' or destination_attr.mode ~= 'directory' then
    print( '<destination> needs to be an existing directory' )
  else
    if lfs.attributes( '_site.lua') ~= nil then
      --require( '_site.lua' )
      --load(io.lines( '_site.lua', 2^12), '_site.lua', 't', pashlicks.context ) --( pashlicks.load_string( pashlicks.load_file( '_site.lua' ) ) )()
      --print( )
    else
      pashlicks.content = {}
    end
    pashlicks.render_tree( '.', pashlicks.destination, 0, pashlicks.context )
  end
end




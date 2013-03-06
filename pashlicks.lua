-- Pashlicks

--   templating features thanks to Zed Shaw's tir

local lfs = require( 'lfs' )

pashlicks = { context = {} }
setmetatable( pashlicks.context, { __index = _G } )

pashlicks.TEMPLATE_ACTIONS = {
  ['{%'] = function(code)
    return code
  end,
  ['{{'] = function(code)
    return ('_result[#_result+1] = %s'):format(code)
  end,
  ['{('] = function(code)
    return ( '_result[#_result+1] = pashlicks.render( pashlicks.load_file( %s ), _ENV )'):format( code )
  end
}


function pashlicks.render( code, context )
  local tmpl = code..'{}'
  local code = {'local _result = {}\n'}

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

  return pashlicks.run_code( code, context )
end


-- Helper function that uses load to check code and if okay return the environment it creates
function pashlicks.run_code( code, context )

  local func, err = load( code, nil, 't', context )

  if err then
    assert( func, err )
  else
    return func(), context
  end
end


function pashlicks.load_file( name )
  local intmp = assert( io.open( name, 'r' ) )
  local content = intmp:read( '*a' )
  intmp:close()
  return content
end


function pashlicks.render_tree( source, destination, level, context )
  level = level or 0
  context = context or {}

  local whitespace = ' '

  -- check for 'subdir/_dir.lua' and add to context if it exists
  file = io.open( source..'/_dir.lua', 'r' )
  if file then _, context = pashlicks.run_code( pashlicks.load_file( source..'/_dir.lua' ), context ) end

  for file in lfs.dir( source ) do
    if file:sub( 1, 1 ) ~= '_' and file:sub( 1, 1) ~= '.' and file ~= arg[0] then
      local attr = lfs.attributes( source..'/'..file )
      assert(type(attr) == "table")
      if attr.mode == "file" then
        print( whitespace:rep( level * 2 )..file )
        context.page = { level = level }
        -- render and write it out
        local outfile = io.open( destination..'/'..file, "w" )
        local output = pashlicks.render( pashlicks.load_file( source..'/'..file ), context )
        outfile:write( output )
        outfile:close()
      elseif attr.mode == "directory" then
        print( whitespace:rep( indent )..file..'/    -->    '..destination..'/'..file )
        destination_attr = lfs.attributes( destination..'/'..file )
        if ( destination_attr == nil ) then
          lfs.mkdir( destination..'/'..file)
        end
        pashlicks.render_tree( source..'/'..file, destination..'/'..file, level + 1, pashlicks.copy( context ) )
      end
    end
  end

end


function pashlicks.copy( original )
  local original_type = type( original )
  local copy
  if original_type == 'table' then
    copy = {}
    for original_key, original_value in next, original, nil do
      copy[pashlicks.copy( original_key ) ] = pashlicks.copy( original_value )
    end
    -- use the same metatable (do not copy that too)
    setmetatable( copy, getmetatable( original ) )
  else -- number, string, boolean, etc
    copy = original
  end
  return copy
end


pashlicks.destination = arg[1] or nil

if ( #arg ~= 1 ) then
  print( 'Usage: lua '..arg[0]..' <destination>' )
else
  local destination_attr = lfs.attributes( pashlicks.destination )
  if type( destination_attr ) ~= 'table' or destination_attr.mode ~= 'directory' then
    print( '<destination> needs to be an existing directory' )
  else
    pashlicks.render_tree( '.', pashlicks.destination, 0, pashlicks.context )
  end
end

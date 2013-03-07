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
function pashlicks.run_code( code, env )
  local func, err = load( code, nil, 't', env )
  if err then
    assert( func, err )
  else
    return func(), env
  end
end


function pashlicks.read_file( name )
  local infile = assert( io.open( name, 'r' ) )
  local content = intmp:read( '*a' )
  infile:close()
  return content
end


function pashlicks.write_file( name, content )
  local outfile = io.open( name, 'w')
  outfile:write( content )
  outfile:close()
end


function pashlicks.directory( path )
  local attr = lfs.attributes( path )
  assert( type( attr ) == 'table', 'Path does not exist' )
  if attr.mode == 'file' then
    if path:find( '/') then
      local with_trailing_slash = path:match( '[%a%d%-_%/%.]*/' )
      return with_trailing_slash:sub( 1, -2 )
    else
      return '.'
    end
  elseif attr.mode == 'directory' then
    if path:sub(#path) == '/' then
      local first_non_slash_position = path:reverse():find( '[%a%d%-_%.]' )
      return path:sub( 1, -first_non_slash_position )
    else
      return path
    end
  end
end


function pashlicks.filename( path )
  local attr = lfs.attributes( path )
  assert( type( attr ) == 'table', 'Path does not exist' )
  assert( attr.mode == 'file', 'Path is not a file' )
  if path:find( '/') then
    return path:reverse():match( '[%a%d%-_%.]+' ):reverse()
  else
    return path
  end
end


function pashlicks.walk_directory( path, func, vars )
  assert( type( path ) == 'string' )
  assert( type( func ) == 'function' )
  assert( type( vars ) == 'table' )

  for file in lfs.dir( path ) do
    local attr = lfs.attributes( path..'/'..file )
    func( path..'/'..file, attr, vars )
  end
end


function pashlicks.recursive_render( path, attr, vars )

  local directory = pashlicks.directory( path )
  local filename = pashlicks.filename( path )

  -- add '_dir.lua' to context for this directory
  if filename == '_dir.lua' then
    _, vars.env = pashlicks.run_code( pashlicks.read_file( path ), vars.env )

  -- process ordinary files and directories
  elseif filename:sub( 1, 1 ) ~= '_' and filename:sub( 1, 1) ~= '.' then
    if attributes.mode == 'file' then
      -- print filename being processed
      print( vars.whitespace:rep( vars.level * 2 )..filename )

      -- setup file specific page values
      local environment = pashlicks.copy( vars.env )
      environment.page.level = vars.level
      environment.page.path = path
      environment.page.filename = filename
      environment.page.directory = directory

      -- check for (and render) page parts
      local rendered_page_parts = {}
      local page_part_identifier = '__'..file:match( '[%a%d%-_]+'..'.' )
        for page_part in lfs.dir( source ) do
          if page_part:find( page_part_identifier ) == 1 then
            local page_part_name = page_part:sub( page_part_identifier:len() + 1 )
            print( whitespace:rep( level * 2 )..'-'..page_part_name )
            local rendered_page_parts = {}
            rendered_page_parts[page_part_name] = pashlicks.render( pashlicks.load_file( source..'/'..page_part ), pashlicks.copy( context ) )
          end
        end
        context.page.parts = rendered_page_parts

        -- render and write out page
        local outfile = io.open( destination..'/'..file, "w" )
        local output = pashlicks.render( pashlicks.load_file( source..'/'..file ), context )

        -- embed in a layout if one was specified
        if context.page.layout then
          context.page.content = output
          output = pashlicks.render( pashlicks.load_file( context.page.layout ), context )
        end

        outfile:write( output )
        outfile:close()

    elseif attributes.mode == 'directory' then

    end
  end

end


function render_tree( source, destination, level, context )

  local accumulators = {
    level = 0,
    context = {},
    destination = destination,
    whitespace = ' '
  }

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

        -- setup file specific page values
        context.page = context.page or {}
        context.page.level = level
        context.page.path = source..'/'..file

        -- check for (and render) page parts
        local rendered_page_parts = {}
        local page_part_identifier = '__'..file:match( '[%a%d%-_]+'..'.' )
        for page_part in lfs.dir( source ) do
          if page_part:find( page_part_identifier ) == 1 then
            local page_part_name = page_part:sub( page_part_identifier:len() + 1 )
            print( whitespace:rep( level * 2 )..'-'..page_part_name )
            local rendered_page_parts = {}
            rendered_page_parts[page_part_name] = pashlicks.render( pashlicks.load_file( source..'/'..page_part ), pashlicks.copy( context ) )
          end
        end
        context.page.parts = rendered_page_parts

        -- render and write out page
        local outfile = io.open( destination..'/'..file, "w" )
        local output = pashlicks.render( pashlicks.load_file( source..'/'..file ), context )

        -- embed in a layout if one was specified
        if context.page.layout then
          context.page.content = output
          output = pashlicks.render( pashlicks.load_file( context.page.layout ), context )
        end

        outfile:write( output )
        outfile:close()
      elseif attr.mode == "directory" then
        print( whitespace:rep( level * 2 )..file..'/' )
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


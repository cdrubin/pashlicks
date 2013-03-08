-- Pashlicks

--   templating features thanks to Zed Shaw's tir

local lfs = require( 'lfs' )
--local inspect = require( '_inspect' )

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
  local infile = assert( io.open( name, 'r' ) )
  local content = infile:read( '*a' )
  infile:close()
  return content
end


function pashlicks.render_tree( source, destination, level, context )
  level = level or 0
  context = context or {}

  local whitespace = ' '
  local directories = {}
  local files = {}

  -- check for 'subdir/_dir.lua' and add to context if it exists
  file = io.open( source..'/_dir.lua', 'r' )
  if file then _, context = pashlicks.run_code( pashlicks.load_file( source..'/_dir.lua' ), context ) end

  -- create tables of the file and directory names
  for item in lfs.dir( source ) do
    local attr = lfs.attributes( source..'/'..item )
    --print ( inspect( attr ) )
    if item:sub( 1, 1 ) ~= '_' and item:sub( 1, 1 ) ~= '.' and item ~= arg[0] then
      if attr.mode == "directory" then
        table.insert( directories, item )
      elseif attr.mode == 'file' then
        table.insert( files, item )
      end
    end
  end
  table.sort( directories ) ; table.sort( files )

  local visible = {}

  -- process directories first for depth-first search
  for count, directory in ipairs( directories ) do
    print( whitespace:rep( level * 2 )..directory..'/' )
    destination_attr = lfs.attributes( destination..'/'..directory )
    if ( destination_attr == nil ) then
      lfs.mkdir( destination..'/'..directory )
    end
    local visible_pages = pashlicks.render_tree( source..'/'..directory, destination..'/'..directory, level + 1, pashlicks.copy( context ) )

    -- add visible_pages to visible_directories if the returned visible_pages contains index.html
    for _, page in ipairs( visible_pages ) do
      if page.file and page.file == 'index.html' then visible[directory] = visible_pages ; break end
    end

  end

  --local visible_pages = {}
  -- process files now that search has already processed any children
  for count, file in ipairs( files ) do
    print( whitespace:rep( level * 2 )..file )

    -- setup file specific page values
    context.page = context.page or {}
    context.page.level = level
    context.page.path = source..'/'..file
    context.page.file = file
    context.page.tree = visible

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
    local output, after_context = pashlicks.render( pashlicks.load_file( source..'/'..file ), pashlicks.copy( context ) )

    -- embed in a layout if one was specified
    if after_context.page.layout then
      after_context.page.content = output
      output = pashlicks.render( pashlicks.load_file( after_context.page.layout ), after_context )
    end

    if ( not after_context.page.hidden ) then
      table.insert( visible, { title = after_context.page.title, path = source..'/'..file, file = file, layout = after_context.page.layout } )
    end

    outfile:write( output )
    outfile:close()
  end

  return visible

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


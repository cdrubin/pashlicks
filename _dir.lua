
-- tables for the environment in which pages are rendered

site = {

}

page = {

  layout = '_layouts/site.html'

}

-- global functions

function subpaths( tree, from, filter )
  from = from or ''
  local results = {}

  if from:ends( '/' ) then
    from = from:sub( 1, -2 )
  end

  local parts = from:split( '/' )

  local subtree = tree
  for _, subpath in ipairs( parts ) do
    subtree = subtree[subpath]
  end

  for i, item in pairs( subtree ) do
    if item.file and ( not filter or filter == 'file' ) and from:trim() ~= '' then
      item.type = 'file'
      table.insert( results, { subpath = item.file, type = 'file', title = item.title } )
    else
      -- TODO: find index.html inside that item
      local title = ''
      for _, subitem in pairs( item ) do
        if ( subitem.file == 'index.html' ) then
          title = subitem.title ; break
        end
      end
      table.insert( results, { subpath = i, type = 'directory', title = title } )
    end
  end

  return results
end


-- string convenience methods

-- starts with?
function string.starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

-- ends with?
function string.ends(String,End)
   return End=='' or string.sub(String,-string.len(End))==End
end

-- trim whitespace
function string.trim(String)
  return String:match("^%s*(.-)%s*$")
end

-- split with pattern
function string.split(str, pat )
  pat = pat or " "
  local t = {}  -- NOTE: use {n = 0} in Lua-5.0
  local fpat = "(.-)" .. pat
  local last_end = 1
  local s, e, cap = str:find(fpat, 1)
  while s do
    if s ~= 1 or cap ~= "" then
	  table.insert(t,cap)
    end
    last_end = e+1
	s, e, cap = str:find(fpat, last_end)
  end
  if last_end <= #str then
    cap = str:sub(last_end)
    table.insert(t, cap)
  end
  return t
end

-- tables for the environment in which pages are rendered

site = {

}

page = {

  layout = '_layouts/site.html'

}

-- global functions

-- requires page.tree or site.tree as first parameter, optionally accepts a relative path
-- into that tree, filter can be optionally 'directory' or 'file' and if
-- include_hidden is true then all items are returned including hidden ones
function subpaths( tree, from, filter, include_hidden )
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
      if not item.hidden or include_hidden then
        table.insert( results, { subpath = item.file, type = 'file', title = item.title } )
      end
    elseif ( not filter or filter == 'directory' ) then

      local title = ''
      for _, subitem in pairs( item ) do
        if subitem.file == 'index.html' then
          if not subitem.hidden or include_hidden then
            title = subitem.title
          else
            title = nil
          end
          break
        end
      end
      if title then table.insert( results, { subpath = i, type = 'directory', title = title } ) end

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

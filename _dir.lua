pashlicks.run_file( '_lib/extensions.lua', _ENV )

site.var = 'var'
site.back = 'back.readingandwritingproject.com'
site.assets = 'assets.readingandwritingproject.com'
page.layout = '_layouts/site.html'



function site.subpaths( from, filter, include_hidden )
  return pashlicks.subpaths( site.tree, from, filter, include_hidden )
end


function page.subpaths( from, filter, include_hidden )
  return pashlicks.subpaths( page.tree, from, filter, include_hidden )
end

--[[
function site.back( path )
  return 'http://'..site.back..'/'..path
end


function site.asset( path )
  return 'http://'..site.assets..'/'..path
end
--]]

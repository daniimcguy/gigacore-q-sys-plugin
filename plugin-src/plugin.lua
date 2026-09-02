-- plugin.lua (skeleton)
--[[ #include "info.lua" ]]

function GetProperties(props)
  --[[ #include "properties.lua" ]]
end

function GetControls(props)
  --[[ #include "controls.lua" ]]
end

function GetControlLayout(props)
  --[[ #include "layout.lua" ]]
end

function GetPages(props)
  --[[ #include "pages.lua" ]]
end

function GetModel(props)
  --[[ #include "model.lua" ]]
end

function RectifyProperties(props)
  --[[ #include "rectify_properties.lua" ]]
end

if Controls then
  --[[ #include "runtime.lua" ]]
end

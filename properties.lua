local modelChoices = {}
for modelName, _ in pairs(GigaCoreModels) do
  table.insert(modelChoices, modelName)
end
table.sort(modelChoices)

return {
  {
    Name    = "Model",
    Type    = "enum",
    Choices = modelChoices,
    Value   = "GigaCore 30i",
  },
  {
    Name    = "Dark Mode",
    Type    = "enum",
    Choices = { "Yes", "No" },
    Value   = "Yes",
  },
  -- Periodic REST re-sync of every port (link, enable, legend, group,
  -- speed, PoE, RLinkX) in three bulk GETs, so a WebSocket notification
  -- missed during the subscription storm heals itself.
  {
    Name    = "Poll Interval",
    Type    = "enum",
    Choices = { "Off", "5 s", "15 s", "30 s", "60 s" },
    Value   = "15 s",
  },
}

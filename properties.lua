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
}

-- For controls we always create the MAX possible per-port slots so that the
-- list of pins doesn't need to change when auto-detect kicks in. Use 30 (the
-- largest GigaCore model) regardless of the resolved model.
local portCount = 30
state.portCount = state.portCount or portCount

local c = {}

-- Port.Group choices are built fresh for each port (shared table refs
-- sometimes get flattened by Q-SYS's control serializer).
local function buildPortGroupChoices()
  local out = { "(unassigned)" }
  for i = 1, 40 do out[#out + 1] = "Group " .. i end
  for i = 1, 8  do out[#out + 1] = "Trunk " .. i end
  return out
end

for p = 1, portCount do
  c[#c+1] = {
    Name        = "Port.Link " .. p,
    ControlType = "Button",
    ButtonType  = "Toggle",
    PinStyle    = "Output",
    UserPin     = true,
    IsReadOnly  = true,
  }

  -- Web UI port card on the chassis: a flat read-only Button whose Legend
  -- carries the whole card as an IconData SVG (portCardSvg).
  c[#c+1] = {
    Name        = "Port.Card " .. p,
    ControlType = "Button",
    ButtonType  = "Toggle",
    PinStyle    = "None",
    UserPin     = false,
    IsReadOnly  = true,
  }

  -- Internal: drives port body fill color in layout. Not exposed as a pin.
  c[#c+1] = {
    Name        = "Port.Group Color " .. p,
    ControlType = "Text",
    TextBoxType = "ReadOnly",
    PinStyle    = "None",
    UserPin     = false,
    IsReadOnly  = false,
    Value       = "",
  }

  c[#c+1] = {
    Name        = "PoE.Indication " .. p,
    ControlType = "Text",
    TextBoxType = "ReadOnly",
    PinStyle    = "Output",
    UserPin     = true,
    Value       = "",
  }

  -- Legacy under-port bar (no longer drawn). Kept as internal for any third
  -- party still referencing it, but no longer a pin.
  c[#c+1] = {
    Name        = "RLinkX.Bar " .. p,
    ControlType = "Text",
    TextBoxType = "ReadOnly",
    PinStyle    = "None",
    UserPin     = false,
    IsReadOnly  = false,
    Value       = "",
  }

  -- RLinkX state text output ("disabled" / "enabled" / "active")
  c[#c+1] = {
    Name        = "RLinkX.State " .. p,
    ControlType = "Text",
    TextBoxType = "ReadOnly",
    PinStyle    = "Output",
    UserPin     = true,
    IsReadOnly  = true,
    Value       = "",
  }

  c[#c+1] = {
    Name        = "Port.Legend " .. p,
    ControlType = "Text",
    TextBoxType = "ReadOnly",
    PinStyle    = "Output",
    UserPin     = true,
    IsReadOnly  = true,
    Value       = "",
  }

  c[#c+1] = {
    Name        = "Port.Enable " .. p,
    ControlType = "Button",
    ButtonType  = "Toggle",
    PinStyle    = "Input",
    UserPin     = true,
  }

  c[#c+1] = {
    Name        = "Port.Legend Edit " .. p,
    ControlType = "Text",
    TextBoxType = "Normal",
    PinStyle    = "Output",
    UserPin     = true,
    IsReadOnly  = false,
    Value       = "",
  }

  c[#c+1] = {
    Name        = "RLinkX.Toggle " .. p,
    ControlType = "Button",
    ButtonType  = "Toggle",
    PinStyle    = "Input",
    UserPin     = true,
  }

  c[#c+1] = {
    Name        = "PoE.Toggle " .. p,
    ControlType = "Button",
    ButtonType  = "Toggle",
    PinStyle    = "Input",
    UserPin     = true,
  }

  c[#c+1] = {
    Name        = "PoE.Bounce " .. p,
    ControlType = "Button",
    ButtonType  = "Momentary",
    PinStyle    = "Input",
    UserPin     = true,
  }

  c[#c+1] = {
    Name        = "Port.Speed " .. p,
    ControlType = "Text",
    TextBoxType = "ComboBox",
    PinStyle    = "Input",
    UserPin     = true,
    Choices     = SPEED_CHOICES,
    Value       = "Auto",
  }

  -- Speed cell — Button showing the current link speed; click opens the
  -- speed picker panel (zSpeed.* controls below). The Port.Speed pin above
  -- stays the external interface and is no longer placed in the layout.
  c[#c+1] = {
    Name        = "Port.Speed Cell " .. p,
    ControlType = "Button",
    ButtonType  = "Momentary",
    PinStyle    = "None",
    UserPin     = false,
  }

  -- Port group membership cell — Button colored with the group's color,
  -- Legend = friendly group/trunk name. Click opens the group picker panel
  -- (zPicker.* controls below) to reassign the port.
  c[#c+1] = {
    Name        = "Port.Group " .. p,
    ControlType = "Button",
    ButtonType  = "Momentary",
    PinStyle    = "Output",
    UserPin     = true,
  }

  -- RLinkX ring edges (4 thin rectangles forming a ring around each port).
  -- All four painted the same color at runtime based on rlinkx state.
  for _, edge in ipairs({ "Top", "Bottom", "Left", "Right" }) do
    c[#c+1] = {
      Name        = "RLinkX.Edge " .. edge .. " " .. p,
      ControlType = "Text",
      TextBoxType = "ReadOnly",
      PinStyle    = "None",
      UserPin     = false,
      IsReadOnly  = true,
      Value       = "",
    }
  end


  -- Per-port identify button (the port-number label in the settings grid).
  -- Clicking PUTs /api/port_identify with this port number.
  c[#c+1] = {
    Name        = "Port.Identify " .. p,
    ControlType = "Button",
    ButtonType  = "Momentary",
    PinStyle    = "Input",
    UserPin     = true,
  }
end

-- Group picker panel (main page). Hidden until a Port.Group cell is clicked;
-- items mirror the Groups and Trunks page slots: zPicker.Group 1..20
-- predefined, 21.. custom slots, zPicker.Trunk 1 = ISL, 2.. custom slots.
local function pickerButton(name)
  c[#c+1] = {
    Name        = name,
    ControlType = "Button",
    ButtonType  = "Momentary",
    PinStyle    = "None",
    UserPin     = false,
  }
end
local function pickerText(name)
  c[#c+1] = {
    Name        = name,
    ControlType = "Text",
    TextBoxType = "ReadOnly",
    PinStyle    = "None",
    UserPin     = false,
    IsReadOnly  = true,
    Value       = "",
  }
end
pickerButton("zPicker.Bg")
pickerText("zPicker.Title")
pickerButton("zPicker.None")
pickerButton("zPicker.Cancel")
for i = 1, 4 do pickerText("zPicker.Label " .. i) end
for i = 1, 20 + CUSTOM_GROUP_SLOTS do pickerButton("zPicker.Group " .. i) end
for i = 1, 1 + CUSTOM_TRUNK_SLOTS do pickerButton("zPicker.Trunk " .. i) end

-- Speed picker panel (main page). Hidden until a Port.Speed Cell is clicked;
-- zSpeed.Item i shows SPEED_CHOICES[i].
pickerButton("zSpeed.Bg")
pickerText("zSpeed.Title")
pickerButton("zSpeed.Cancel")
for i = 1, #SPEED_CHOICES do pickerButton("zSpeed.Item " .. i) end

-- Logo identify button — invisible Button overlay on the Luminex logo
-- inside the chassis. Click PUTs /api/identify on the device.
c[#c+1] = {
  Name        = "Device.Identify",
  ControlType = "Button",
  ButtonType  = "Momentary",
  PinStyle    = "Input",
  UserPin     = true,
}

-- Group labels + ID badges (slots 1..40)
for i = 1, 40 do
  c[#c+1] = {
    Name        = "group_label_" .. i,
    ControlType = "Text",
    TextBoxType = "ReadOnly",
    PinStyle    = "None",
    UserPin     = false,
    IsReadOnly  = true,
    Value       = "",
  }
end

for i = 1, 40 do
  c[#c+1] = {
    Name        = "group_id_badge_" .. i,
    ControlType = "Text",
    TextBoxType = "ReadOnly",
    PinStyle    = "None",
    UserPin     = false,
    IsReadOnly  = true,
    Value       = "",
  }
end

-- Trunk labels + ID badges (slots 1..10)
for i = 1, 10 do
  c[#c+1] = {
    Name        = "trunk_label_" .. i,
    ControlType = "Text",
    TextBoxType = "ReadOnly",
    PinStyle    = "None",
    UserPin     = false,
    IsReadOnly  = true,
    Value       = "",
  }
  c[#c+1] = {
    Name        = "trunk_id_badge_" .. i,
    ControlType = "Text",
    TextBoxType = "ReadOnly",
    PinStyle    = "None",
    UserPin     = false,
    IsReadOnly  = true,
    Value       = "",
  }
end

-- Shown on every page
c[#c+1] = {
  Name        = "Device.Name",
  ControlType = "Text",
  TextBoxType = "ReadOnly",
  PinStyle    = "Output",
  UserPin     = true,
  Value       = "",
  MultiLine   = true,
}

-- Switch model from /api/device; "Switch is <model>" when it differs from
-- the Model property.
c[#c+1] = {
  Name        = "Device.Model",
  ControlType = "Text",
  TextBoxType = "ReadOnly",
  PinStyle    = "Output",
  UserPin     = true,
  Value       = "",
}

c[#c+1] = {
  Name        = "Device.Description",
  ControlType = "Text",
  TextBoxType = "ReadOnly",
  PinStyle    = "Output",
  UserPin     = true,
  Value       = "",
  MultiLine   = true,
}

c[#c+1] = {
  Name        = "Device.IP Info",
  ControlType = "Text",
  TextBoxType = "ReadOnly",
  PinStyle    = "Output",
  UserPin     = true,
  Value       = "",
}

c[#c+1] = {
  Name        = "Device.MAC",
  ControlType = "Text",
  TextBoxType = "ReadOnly",
  PinStyle    = "Output",
  UserPin     = true,
  Value       = "",
}

c[#c+1] = {
  Name        = "Device.Firmware",
  ControlType = "Text",
  TextBoxType = "ReadOnly",
  PinStyle    = "Output",
  UserPin     = true,
  Value       = "",
}

c[#c+1] = {
  Name        = "Device.Status",
  ControlType = "Text",
  TextBoxType = "ReadOnly",
  PinStyle    = "Output",
  UserPin     = true,
  IsReadOnly  = false,
  Value       = "Offline",
}

-- Configuration page
c[#c+1] = {
  Name        = "Auth.IP Address",
  ControlType = "Text",
  TextBoxType = "Normal",
  PinStyle    = "Input",
  UserPin     = true,
  Value       = "Enter your IP",
}

c[#c+1] = {
  Name        = "Auth.Username",
  ControlType = "Text",
  TextBoxType = "Normal",
  PinStyle    = "Input",
  UserPin     = true,
  Value       = "",
}

c[#c+1] = {
  Name        = "Auth.Password",
  ControlType = "Text",
  TextBoxType = "Password",
  PinStyle    = "Input",
  UserPin     = true,
  Value       = "",
}

c[#c+1] = {
  Name        = "Auth.Status",
  ControlType = "Text",
  TextBoxType = "ReadOnly",
  PinStyle    = "Output",
  UserPin     = true,
  Value       = "",
}

c[#c+1] = {
  Name        = "Auth.Connect",
  ControlType = "Button",
  ButtonType  = "Toggle",
  PinStyle    = "Input",
  UserPin     = true,
}

c[#c+1] = {
  Name        = "Auth.Identify",
  ControlType = "Button",
  ButtonType  = "Momentary",
  PinStyle    = "Input",
  UserPin     = true,
}

-- System / chassis telemetry (shown on main page)
c[#c+1] = { Name = "System.Case Temp",     ControlType = "Text", TextBoxType = "ReadOnly", PinStyle = "Output", UserPin = true, Value = "" }
c[#c+1] = { Name = "System.CPU Temp",      ControlType = "Text", TextBoxType = "ReadOnly", PinStyle = "Output", UserPin = true, Value = "" }
c[#c+1] = { Name = "Fan.1 Speed",    ControlType = "Text", TextBoxType = "ReadOnly", PinStyle = "Output", UserPin = true, Value = "" }
c[#c+1] = { Name = "Fan.2 Speed",    ControlType = "Text", TextBoxType = "ReadOnly", PinStyle = "Output", UserPin = true, Value = "" }
c[#c+1] = { Name = "Fan.3 Speed",    ControlType = "Text", TextBoxType = "ReadOnly", PinStyle = "Output", UserPin = true, Value = "" }
c[#c+1] = { Name = "PSU.1 Status",   ControlType = "Text", TextBoxType = "ReadOnly", PinStyle = "Output", UserPin = true, Value = "" }
c[#c+1] = { Name = "PSU.2 Status",   ControlType = "Text", TextBoxType = "ReadOnly", PinStyle = "Output", UserPin = true, Value = "" }
c[#c+1] = { Name = "PSU.1 Power",    ControlType = "Text", TextBoxType = "ReadOnly", PinStyle = "Output", UserPin = true, Value = "" }
c[#c+1] = { Name = "PSU.2 Power",    ControlType = "Text", TextBoxType = "ReadOnly", PinStyle = "Output", UserPin = true, Value = "" }
c[#c+1] = { Name = "System.CPU Load 1s",   ControlType = "Text", TextBoxType = "ReadOnly", PinStyle = "Output", UserPin = true, Value = "" }
c[#c+1] = { Name = "System.CPU Load 10s",  ControlType = "Text", TextBoxType = "ReadOnly", PinStyle = "Output", UserPin = true, Value = "" }

c[#c+1] = { Name = "Power.Total Usage", ControlType = "Text", TextBoxType = "ReadOnly", PinStyle = "Output", UserPin = true, Value = "" }
c[#c+1] = { Name = "Power.Coupling",    ControlType = "Text", TextBoxType = "ReadOnly", PinStyle = "Output", UserPin = true, Value = "" }

-- RSTP
c[#c+1] = { Name = "RSTP.Bridge Priority", ControlType = "Text", TextBoxType = "ReadOnly", PinStyle = "Output", UserPin = true, Value = "" }
c[#c+1] = { Name = "RSTP.Root Bridge",     ControlType = "Text", TextBoxType = "ReadOnly", PinStyle = "Output", UserPin = true, Value = "" }

-- Status block paint targets (right of the chassis, like the switch web UI):
-- PSU icons, coupling glyph, status dot. Internal only, laid out as Buttons.
for _, name in ipairs({ "PSU.1 Icon", "PSU.2 Icon", "Power.Coupling Glyph", "Device.Status Dot" }) do
  c[#c+1] = { Name = name, ControlType = "Text", TextBoxType = "ReadOnly", PinStyle = "None", UserPin = false, Value = "" }
end

-- 10G frame per tenG group (IconData Button, like Port.Card), shown while the
-- 10g licence is active. Declared for the model with the most tenG groups.
local tenGFrameCount = 0
for _, layout in pairs(CHASSIS_LAYOUT) do
  local count = 0
  for _, group in ipairs(layout) do
    if group.tenG then count = count + 1 end
  end
  if count > tenGFrameCount then tenGFrameCount = count end
end
for i = 1, tenGFrameCount do
  c[#c+1] = {
    Name        = "Chassis.10G " .. i,
    ControlType = "Button",
    ButtonType  = "Toggle",
    PinStyle    = "None",
    UserPin     = false,
    IsReadOnly  = true,
  }
end

-- Testing page (disabled but control kept so page can be re-enabled without recompile)
c[#c+1] = {
  Name        = "Test Dropdown",
  ControlType = "Text",
  TextBoxType = "ComboBox",
  PinStyle    = "None",
  UserPin     = false,
  Choices     = {
    "Auto",
    "Disabled",
    "1 Gbps",
    "100 Mbps (Full-duplex)",
    "100 Mbps (Half-duplex)",
    "10 Mbps (Full-duplex)",
    "10 Mbps (Half-duplex)",
  },
  Value       = "Auto",
}

return c

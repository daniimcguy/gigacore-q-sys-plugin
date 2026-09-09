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

  -- Internal: drives the PoE pip color in layout. Button control so it can
  -- share the layer with Port.Link and render on top of the port button.
  c[#c+1] = {
    Name        = "Port.PoE Color " .. p,
    ControlType = "Button",
    ButtonType  = "Toggle",
    PinStyle    = "None",
    UserPin     = false,
    IsReadOnly  = true,
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
    Choices     = {
      "Auto",
      "Disabled",
      "1 Gbps",
      "100 Mbps (Full-duplex)",
      "100 Mbps (Half-duplex)",
      "10 Mbps (Full-duplex)",
      "10 Mbps (Half-duplex)",
    },
    Value = "Auto",
  }

  -- Port group membership display — read-only Button colored with the
  -- group's color, Legend = friendly group/trunk name. Picker UI later.
  c[#c+1] = {
    Name        = "Port.Group " .. p,
    ControlType = "Button",
    ButtonType  = "Toggle",
    PinStyle    = "Output",
    UserPin     = true,
    IsReadOnly  = true,
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

  -- RLinkX circular ring (only used on ethercon ports): outer filled circle
  -- in rlinkx color, inner filled circle matching the port's button color so
  -- only a ring is visible between them.
  c[#c+1] = {
    Name        = "RLinkX.Ring Fill " .. p,
    ControlType = "Text",
    TextBoxType = "ReadOnly",
    PinStyle    = "None",
    UserPin     = false,
    IsReadOnly  = true,
    Value       = "",
  }
  c[#c+1] = {
    Name        = "RLinkX.Ring Hider " .. p,
    ControlType = "Text",
    TextBoxType = "ReadOnly",
    PinStyle    = "None",
    UserPin     = false,
    IsReadOnly  = true,
    Value       = "",
  }

  c[#c+1] = {
    Name        = "Port.Trunk Badge " .. p,
    ControlType = "Text",
    TextBoxType = "ReadOnly",
    PinStyle    = "None",
    UserPin     = false,
    IsReadOnly  = true,
    Value       = "",
  }

  -- Group color surround (SVG overlay mode). Text control — backup pattern:
  -- layout sets Color="#00000000" + BackgroundColor=dark; runtime sets
  -- .Color=hex to paint the fill.
  c[#c+1] = {
    Name        = "Port Bg" .. p,
    ControlType = "Text",
    TextBoxType = "ReadOnly",
    PinStyle    = "None",
    UserPin     = false,
    IsReadOnly  = false,
    Value       = "",
  }

  -- RLinkX ring — sized slightly larger than Port.Link to show as a frame.
  c[#c+1] = {
    Name        = "Port RlinkX " .. p,
    ControlType = "Button",
    ButtonType  = "Toggle",
    PinStyle    = "None",
    UserPin     = false,
    IsReadOnly  = true,
  }

  -- Port number display — Text control, sorts last alphabetically via
  -- "Port.z Num N" so it renders on top of the halo and Port.Link.
  c[#c+1] = {
    Name        = "Port.z Num " .. p,
    ControlType = "Text",
    TextBoxType = "ReadOnly",
    PinStyle    = "None",
    UserPin     = false,
    IsReadOnly  = true,
    Value       = "",
  }

  -- Disabled-port X marker — rendered in red in the center of the port when
  -- the port is disabled. Sorts last ("zz" > "z") so it paints on top of
  -- the port number.
  c[#c+1] = {
    Name        = "Port.zz Disabled X " .. p,
    ControlType = "Text",
    TextBoxType = "ReadOnly",
    PinStyle    = "None",
    UserPin     = false,
    IsReadOnly  = true,
    Value       = "",
  }

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

-- RSTP
c[#c+1] = { Name = "RSTP.Bridge Priority", ControlType = "Text", TextBoxType = "ReadOnly", PinStyle = "Output", UserPin = true, Value = "" }
c[#c+1] = { Name = "RSTP.Root Bridge",     ControlType = "Text", TextBoxType = "ReadOnly", PinStyle = "Output", UserPin = true, Value = "" }

-- MR (multicast router) marker per port — drives the badge in layout. Internal only.
for p = 1, portCount do
  c[#c+1] = {
    Name        = "Port.zMR " .. p,
    ControlType = "Text",
    TextBoxType = "ReadOnly",
    PinStyle    = "None",
    UserPin     = false,
    Value       = "",
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

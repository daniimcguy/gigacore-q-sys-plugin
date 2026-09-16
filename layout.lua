-- Dark mode from property
local darkProp = props["Dark Mode"]
local darkModeValue = (type(darkProp) == "table") and darkProp.Value or darkProp
state.darkMode = (darkModeValue == "Yes")

local modelString    = resolveModel(props)
local portCount      = getPortCount(modelString)
state.portCount      = portCount
state.selectedModel  = modelString  -- so runtime (no Properties access) can warn on mismatch

-- Port-settings grid geometry, shared by the chassis page and the page
-- size helpers. One column = label + enable + legend + rlinkx + poe toggle
-- + poe bounce + group + speed.
local GRID_COL_W   = 16 + 20 + 50 + 20 + 20 + 20 + 72 + 110
local GRID_COL_PAD = 6
local GRID_X_START = 12
local GRID_ROW_H   = 22

-- Plugin width per model so that every chassis has the same right-side
-- margin (380px from chassis right edge to plugin right edge). Reserves
-- consistent space for future info controls regardless of chassis width.
-- Chassis strip geometry shared by the page builders: [display block]
-- [cropped chassis SVG], both CHASSIS_H tall, starting at CHASSIS_X / _Y.
local CHASSIS_X  = 20
local CHASSIS_Y  = 4
local CHASSIS_H  = 104
local DISPLAY_W  = 190   -- device display block (logo, model, status, IP...)
local DISPLAY_GAP = 0    -- block butts against the cropped chassis

local function chassisSvgWidth(model)
  local coords = getPortCoords(model)
  if coords then
    return math.floor(coords.viewBox.w * CHASSIS_H / coords.viewBox.h + 0.5)
  end
  return 760
end

local function pageWidthForModel(model)
  local rightMargin = 380
  return CHASSIS_X + DISPLAY_W + DISPLAY_GAP + chassisSvgWidth(model) + rightMargin
end

-- Grid columns: as many as the page width fits; rows: ceil(ports / cols).
-- Ports fill column by column (1..rows down the first column, then the
-- next), so the page stays as short as the width allows.
local function gridDimsForModel(model)
  local pageW = pageWidthForModel(model)
  local cols  = math.floor((pageW - GRID_X_START + GRID_COL_PAD) / (GRID_COL_W + GRID_COL_PAD))
  local pc    = getPortCount(model) or 30
  cols = math.max(1, math.min(cols, pc))
  local rows = math.ceil(pc / cols)
  return cols, rows
end

-- Groups and Trunks page geometry. Sections sit side by side (groups,
-- custom groups, trunks, custom trunks); each is a vertical list that
-- spills into extra sub-columns. Rows per section = the smallest count that
-- keeps all four sections inside the page width.
local GT_TOP_Y, GT_LABEL_H, GT_CARD_W, GT_CARD_H, GT_GAP_Y, GT_SECTION_GAP, GT_MARGIN_X = 55, 16, 90, 18, 3, 14, 16
local GT_SECTION_ITEMS = { 20, CUSTOM_GROUP_SLOTS, 1, CUSTOM_TRUNK_SLOTS }

local function groupsPageWidthForRows(rows)
  local w = GT_MARGIN_X
  for i, n in ipairs(GT_SECTION_ITEMS) do
    local subCols = math.max(1, math.ceil(n / rows))
    w = w + subCols * GT_CARD_W + (subCols - 1) * 4
    if i < #GT_SECTION_ITEMS then w = w + GT_SECTION_GAP end
  end
  return w + GT_MARGIN_X
end

local function groupsRowsForModel(model)
  local pageW = pageWidthForModel(model)
  for rows = 4, 20 do
    if groupsPageWidthForRows(rows) <= pageW then return rows end
  end
  return 20
end

local function groupsPageHeightForModel(model)
  local rows = groupsRowsForModel(model)
  return GT_TOP_Y + GT_LABEL_H + 6 + rows * (GT_CARD_H + GT_GAP_Y) - GT_GAP_Y + 10
end

local function chassisPageHeightForModel(model)
  local topGap = 6
  local _cols, rows = gridDimsForModel(model)
  return CHASSIS_Y + CHASSIS_H + topGap + (rows * GRID_ROW_H) + topGap
end

-- One height for every page of a model so tab switches don't resize the
-- plugin: the taller of the chassis page and the groups page.
local function pageHeightForModel(model)
  return math.max(chassisPageHeightForModel(model), groupsPageHeightForModel(model))
end

--------------------------------------------------------------------------------
-- Single port block — faithful replica of the December 2025 backup design.
--
-- Per port (w × h):
--   ┌─────────┐   ← PoE pip sits above the top edge (14 × 8)
--   │         │
--   │  [link] │   ← port<N> button (link-up green / link-down grey)
--   │ ▁▁▁▁▁▁▁ │   ← RLinkX bar near bottom inside the button
--   └─────────┘
--    [Port 12]    ← Port Legend (nickname / display text)
--    [Group: 5]   ← Port Group Color — colored label below
--
-- Control names use v2.x title-case scheme but visual positioning mirrors backup.
--------------------------------------------------------------------------------
-- row: 1 = top row (pip above port), 2 = bottom row (pip below port).
local function defineSinglePort(layout, gfx, portIndex, xPos, yPos, w, h, row)
  row = row or 1
  local gap     = 2
  local btnH    = h
  local poeH    = 8
  local groupH  = 14
  local legendH = 28
  local nextY   = yPos + btnH + gap

  -- Port legend (nickname display) below the port button
  layout["Port.Legend " .. portIndex] = {
    Style        = "Text",
    Position     = { xPos + 4, nextY - 1 },
    Size         = { w - 8, legendH },
    FontSize     = 11,
    Font         = "Roboto",
    Color        = { 0, 0, 0, 0 },
    StrokeWidth  = 0,
    StrokeColor  = { 0, 0, 0, 0 },
    TextColor    = { 255, 255, 255 },
    HTextAlign   = "Center",
    VTextAlign   = "Top",
    IsReadOnly   = true,
  }

  nextY = nextY + legendH + gap

  -- Colored group/trunk label below the legend
  layout["Port.Group Color " .. portIndex] = {
    Style           = "Text",
    Position        = { xPos + 4, nextY - 4 },
    Size            = { w - 8, groupH },
    IsReadOnly      = true,
    FontSize        = 11,
    Color           = { 0, 0, 0, 0 },
    StrokeWidth     = 0,
    StrokeColor     = { 0, 0, 0, 0 },
    Font            = "Roboto",
    HTextAlign      = "Center",
    VTextAlign      = "Center",
    BackgroundColor = { 25, 28, 42, 220 },
    CornerRadius    = 6,
  }

  -- PoE pip lives INSIDE the port body, hugging the top edge on row 1 and
  -- the bottom edge on row 2 (Araneo convention). Use "Indicator" style so
  -- Q-SYS paints the Color fill reliably even with empty String.
  local pipW, pipH = 22, 8
  local pipX = xPos + math.floor((w - pipW) / 2)
  local pipY = (row == 2) and (yPos + btnH - pipH - 5) or (yPos + 5)
  -- Render pip as a Button — same layer as the Port.Link button. When
  -- declared AFTER Port.Link in the rendering pass, Q-SYS draws it in front.
  layout["Port.PoE Color " .. portIndex] = {
    Style             = "Button",
    ButtonStyle       = "Toggle",
    ButtonVisualStyle = "Flat",
    Position          = { pipX, pipY },
    Size              = { pipW, pipH },
    IsReadOnly        = true,
    Color             = { 0, 0, 0, 0 },
    OffColor          = { 0, 0, 0, 0 },
    StrokeColor       = { 0, 0, 0, 0 },
    StrokeWidth       = 0,
    CornerRadius      = 2,
  }

end

local function drawCommonLogos(gfx)
  local lumX, lumY = 5, 5
  local lumW, lumH = 119, 36
  gfx[#gfx+1] = {
    Type     = "Svg",
    Image    = LogoLuminex,
    Position = { lumX, lumY },
    Size     = { lumW, lumH },
  }
  local lumCenterX = lumX + (lumW / 2)
  local lumBottomY = lumY + lumH
  return lumCenterX, lumBottomY
end

-- Two-row device header (Araneo-style), three columns left-aligned:
--   Col 1: [Status]      / [Firmware]      — narrow, left edge
--   Col 2: [Switch Name] / [Description]   — middle
--   Col 3: [IP/Subnet]   / [MAC]           — right
local function defineCommonDeviceInfo(layout, gfx, theme, lumCenterX, ipSpacing)
  local row1Y, row2Y = 2, 22
  local rowH = 20
  local x0 = 10

  local statusW = 60
  local nameW   = 220
  local infoW   = 220   -- IP+Subnet / MAC width (3rd column)
  local gap     = 10
  local col2X = x0 + statusW + gap
  local col3X = col2X + nameW + gap

  -- Offline placeholders (static graphics). The controls above them are
  -- transparent until the runtime paints them with live data, so a design
  -- that was never emulated still shows a finished header.
  local textPad = 4
  local function placeholder(x, y, w, text, align)
    gfx[#gfx+1] = {
      Type       = "Text",
      Text       = text,
      Position   = { x + textPad, y },
      Size       = { w - textPad * 2, rowH },
      Font       = "Roboto",
      FontSize   = 11,
      Color      = theme.textMuted,
      HTextAlign = align or "Left",
      VTextAlign = "Center",
    }
  end
  gfx[#gfx+1] = {
    Type         = "Rectangle",
    Position     = { x0, row1Y },
    Size         = { statusW, rowH },
    Fill         = theme.badgeOffBg,
    StrokeWidth  = 0,
    CornerRadius = 6,
  }
  placeholder(x0, row1Y, statusW, "Offline", "Center")
  placeholder(x0, row2Y, statusW, "---", "Center")
  placeholder(col2X, row1Y, nameW, state.selectedModel or "GigaCore")
  placeholder(col3X, row1Y, infoW, "---")
  placeholder(col3X, row2Y, infoW, "---")

  layout["Device.Status"] = {
    Style        = "Text",
    Position     = { x0, row1Y },
    Size         = { statusW, rowH },
    IsReadOnly   = true,
    Color        = { 0, 0, 0, 0 },
    Font         = "Roboto",
    FontSize     = 11,
    TextColor    = { 255, 255, 255 },
    StrokeWidth  = 0,
    CornerRadius = 6,
    HTextAlign   = "Center",
    VTextAlign   = "Center",
    Legend       = "Offline",
  }

  layout["Device.Name"] = {
    Style        = "Indicator",
    Position     = { col2X, row1Y },
    Size         = { nameW, rowH },
    IsReadOnly   = true,
    Color        = { 0, 0, 0, 0 },
    StrokeColor  = theme.strokeColor,
    StrokeWidth  = 0,
    TextColor    = theme.textColor,
    HTextAlign   = "Left",
    VTextAlign   = "Center",
    FontSize     = 11,
    Font         = "Roboto",
    CornerRadius = 1,
  }

  layout["Device.Description"] = {
    Style        = "Indicator",
    Position     = { col2X, row2Y },
    Size         = { nameW, rowH },
    IsReadOnly   = true,
    Color        = { 0, 0, 0, 0 },
    StrokeColor  = theme.strokeColor,
    StrokeWidth  = 0,
    TextColor    = theme.textColor,
    HTextAlign   = "Left",
    VTextAlign   = "Center",
    FontSize     = 11,
    Font         = "Roboto",
    CornerRadius = 1,
  }

  layout["Device.IP Info"] = {
    Style        = "Indicator",
    Position     = { col3X, row1Y },
    Size         = { infoW, rowH },
    IsReadOnly   = true,
    Color        = { 0, 0, 0, 0 },
    StrokeColor  = theme.strokeColor,
    StrokeWidth  = 0,
    TextColor    = theme.textColor,
    FontSize     = 11,
    Font         = "Roboto",
    HTextAlign   = "Left",
    VTextAlign   = "Center",
    CornerRadius = 1,
  }

  layout["Device.MAC"] = {
    Style        = "Indicator",
    Position     = { col3X, row2Y },
    Size         = { infoW, rowH },
    IsReadOnly   = true,
    Color        = { 0, 0, 0, 0 },
    StrokeColor  = theme.strokeColor,
    StrokeWidth  = 0,
    TextColor    = theme.textColor,
    FontSize     = 11,
    Font         = "Roboto",
    HTextAlign   = "Left",
    VTextAlign   = "Center",
    CornerRadius = 1,
  }

  layout["Device.Firmware"] = {
    Style        = "Indicator",
    Position     = { x0, row2Y },
    Size         = { statusW, rowH },
    IsReadOnly   = true,
    Color        = { 0, 0, 0, 0 },
    StrokeColor  = theme.strokeColor,
    StrokeWidth  = 0,
    TextColor    = theme.textColor,
    FontSize     = 10,
    Font         = "Roboto",
    HTextAlign   = "Center",
    VTextAlign   = "Center",
    CornerRadius = 1,
  }
end

--------------------------------------------------------------------------------
-- Helper: rounded card (info panel)
--------------------------------------------------------------------------------
local function drawCard(gfx, x, y, w, h, theme)
  gfx[#gfx+1] = {
    Type         = "Rectangle",
    Position     = { x, y },
    Size         = { w, h },
    Fill         = theme.cardFill,
    StrokeColor  = theme.cardStroke,
    StrokeWidth  = 1,
    CornerRadius = 8,
  }
end

--------------------------------------------------------------------------------
-- Helper: grid background (faint lines every 40px)
--------------------------------------------------------------------------------
local function drawGridBackground(gfx, w, h, theme)
  gfx[#gfx+1] = {
    Type        = "Rectangle",
    Position    = { 0, 0 },
    Size        = { w, h },
    Fill        = theme.pageBg,
    StrokeWidth = 0,
  }
  for x = 0, w, 40 do
    gfx[#gfx+1] = {
      Type        = "Rectangle",
      Position    = { x, 0 },
      Size        = { 1, h },
      Fill        = theme.gridLine,
      StrokeWidth = 0,
    }
  end
  for y = 0, h, 40 do
    gfx[#gfx+1] = {
      Type        = "Rectangle",
      Position    = { 0, y },
      Size        = { w, 1 },
      Fill        = theme.gridLine,
      StrokeWidth = 0,
    }
  end
end

--------------------------------------------------------------------------------
-- Main controls page — faithful replica of the December 2025 backup layout.
--   • Groupbox background
--   • Top-left Luminex logo + common device info (device_name, ip_info, mac_fw)
--   • 2 rows of ports; each port = a rounded rectangle backdrop with a Button
--     for link state, a big port number label, and the defineSinglePort
--     indicators (PoE pip, legend, group/trunk color label, RLinkX bar).
--------------------------------------------------------------------------------
-- Render one regular RJ45 port (rectangular, 66×44).
local function renderRJ45Port(layout, gfx, portIndex, xPos, yPos, theme, row)
  local btnW, btnH = 66, 44

  gfx[#gfx+1] = {
    Type         = "Rectangle",
    Position     = { xPos + 1, yPos + 1 },
    Size         = { btnW - 2, 88 },
    Fill         = theme.rectangleFill,
    StrokeColor  = { 0, 0, 0, 60 },
    StrokeWidth  = 1,
    CornerRadius = 14,
  }

  layout["Port.Link " .. portIndex] = {
    Style             = "Button",
    ButtonStyle       = "Toggle",
    ButtonVisualStyle = "Flat",
    Position          = { xPos, yPos },
    Size              = { btnW, btnH },
    IsReadOnly        = true,
    Color             = LINK_ON,
    OffColor          = LINK_OFF,
    StrokeColor       = { 0, 0, 0, 0 },
    StrokeWidth       = 0,
    CornerRadius      = 2,
  }

  local inset = 2
  layout["RLinkX.Edge Top " .. portIndex] = {
    Style = "Text", Position = { xPos + inset, yPos + inset }, Size = { btnW - inset * 2, 2 },
    FontSize = 1, IsReadOnly = true, Color = { 0, 0, 0, 0 }, TextColor = { 0, 0, 0, 0 }, StrokeWidth = 0,
  }
  layout["RLinkX.Edge Bottom " .. portIndex] = {
    Style = "Text", Position = { xPos + inset, yPos + btnH - inset - 2 }, Size = { btnW - inset * 2, 2 },
    FontSize = 1, IsReadOnly = true, Color = { 0, 0, 0, 0 }, TextColor = { 0, 0, 0, 0 }, StrokeWidth = 0,
  }
  layout["RLinkX.Edge Left " .. portIndex] = {
    Style = "Text", Position = { xPos + inset, yPos + inset }, Size = { 2, btnH - inset * 2 },
    FontSize = 1, IsReadOnly = true, Color = { 0, 0, 0, 0 }, TextColor = { 0, 0, 0, 0 }, StrokeWidth = 0,
  }
  layout["RLinkX.Edge Right " .. portIndex] = {
    Style = "Text", Position = { xPos + btnW - inset - 2, yPos + inset }, Size = { 2, btnH - inset * 2 },
    FontSize = 1, IsReadOnly = true, Color = { 0, 0, 0, 0 }, TextColor = { 0, 0, 0, 0 }, StrokeWidth = 0,
  }

  layout["Port.Trunk Badge " .. portIndex] = {
    Style       = "Text",
    Position    = { xPos, yPos - 3 },
    Size        = { 14, 14 },
    Font        = "Roboto",
    FontSize    = 16,
    IsReadOnly  = true,
    Color       = { 0, 0, 0, 0 },
    TextColor   = theme.trunkBadge,
    StrokeWidth = 0,
    HTextAlign  = "Left",
    VTextAlign  = "Top",
    IsBold      = true,
  }

  gfx[#gfx+1] = {
    Type       = "Text",
    Text       = tostring(portIndex),
    Color      = { 200, 200, 200, 255 },
    Position   = { xPos, yPos },
    Size       = { btnW, btnH },
    Font       = "Roboto",
    FontSize   = 23,
    HTextAlign = "Center",
    IsBold     = true,
  }

  defineSinglePort(layout, gfx, portIndex, xPos, yPos, btnW, btnH, row)
end

-- Render one ethercon port (large round connector, ~62×62, very high
-- CornerRadius for a circular look). Used for ports 1..N on t-models.
local function renderEtherconPort(layout, gfx, portIndex, xPos, yPos, theme)
  local ethW, ethH = 62, 62

  gfx[#gfx+1] = {
    Type         = "Rectangle",
    Position     = { xPos - 1, yPos + 1 },
    Size         = { ethW + 2, 90 },
    Fill         = theme.rectangleFill,
    StrokeColor  = { 0, 0, 0, 60 },
    StrokeWidth  = 1,
    CornerRadius = 14,
  }

  layout["Port.Link " .. portIndex] = {
    Style             = "Button",
    ButtonStyle       = "Toggle",
    ButtonVisualStyle = "Flat",
    Position          = { xPos, yPos },
    Size              = { ethW, ethH },
    IsReadOnly        = true,
    Color             = LINK_ON,
    OffColor          = LINK_OFF,
    StrokeColor       = { 0, 0, 0, 0 },
    StrokeWidth       = 0,
    CornerRadius      = 31,
  }

  -- Ethercon RLinkX ring — outer fill is the same size as the port (inset 0)
  -- so the ring hugs the edge; inner hider is inset 4px so the visible ring
  -- is ~4px wide. Runtime mirrors the Port Link's color into the hider so it
  -- blends regardless of link-up/down brightness.
  local fillSize  = ethW
  local hiderSize = ethW - 8
  layout["RLinkX.Ring Fill " .. portIndex] = {
    Style = "Text", Position = { xPos, yPos }, Size = { fillSize, fillSize },
    FontSize = 1, IsReadOnly = true, Color = { 0, 0, 0, 0 }, TextColor = { 0, 0, 0, 0 }, StrokeWidth = 0,
    CornerRadius = math.floor(fillSize / 2),
  }
  layout["RLinkX.Ring Hider " .. portIndex] = {
    Style = "Text", Position = { xPos + 4, yPos + 4 }, Size = { hiderSize, hiderSize },
    FontSize = 1, IsReadOnly = true, Color = LINK_ON, TextColor = { 0, 0, 0, 0 }, StrokeWidth = 0,
    CornerRadius = math.floor(hiderSize / 2),
  }

  layout["Port.Trunk Badge " .. portIndex] = {
    Style       = "Text",
    Position    = { xPos + 4, yPos - 1 },
    Size        = { 14, 14 },
    Font        = "Roboto",
    FontSize    = 16,
    IsReadOnly  = true,
    Color       = { 0, 0, 0, 0 },
    TextColor   = theme.trunkBadge,
    StrokeWidth = 0,
    HTextAlign  = "Left",
    VTextAlign  = "Top",
    IsBold      = true,
  }

  -- Port number BELOW the ethercon (matches reference; also avoids being
  -- covered by the ring-hider Text control inside the circle).
  gfx[#gfx+1] = {
    Type       = "Text",
    Text       = tostring(portIndex),
    Color      = { 220, 230, 250, 255 },
    Position   = { xPos, yPos + ethH + 1 },
    Size       = { ethW, 13 },
    Font       = "Roboto",
    FontSize   = 12,
    HTextAlign = "Center",
    VTextAlign = "Top",
    IsBold     = true,
  }

  -- Group/trunk color label tucked just below the port number — kept compact
  -- so the bottom-row ethercon doesn't push into the IP/MAC strip at y=250.
  -- The Port Legend control is intentionally NOT placed in the layout for
  -- ethercons (no room and reference design doesn't show it).
  layout["Port.Group Color " .. portIndex] = {
    Style           = "Text",
    Position        = { xPos + 4, yPos + ethH + 16 },
    Size            = { ethW - 8, 14 },
    IsReadOnly      = true,
    FontSize        = 10,
    Color           = { 0, 0, 0, 0 },
    StrokeWidth     = 0,
    StrokeColor     = { 0, 0, 0, 0 },
    Font            = "Roboto",
    HTextAlign      = "Center",
    VTextAlign      = "Center",
    BackgroundColor = { 25, 28, 42, 220 },
    CornerRadius    = 6,
  }

  -- PoE pip ABOVE the ethercon (same convention as RJ45)
  layout["Port.PoE Color " .. portIndex] = {
    Style        = "Text",
    Position     = { xPos + math.floor((ethW - 14) / 2), yPos - 5 },
    Size         = { 14, 8 },
    FontSize     = 1,
    IsReadOnly   = true,
    Color        = { 0, 0, 0, 0 },
    TextColor    = { 0, 0, 0, 0 },
    StrokeWidth  = 0,
    CornerRadius = 2,
    HTextAlign   = "Center",
    VTextAlign   = "Center",
  }
end

--------------------------------------------------------------------------------
-- Main page with per-model SVG chassis + interactive port overlays.
--   • Render the real product-chassis SVG at a known position/size.
--   • For each port in PORT_COORDS[model], compute screen coords and place
--     a Port.Link button, PoE pip, trunk badge, RLinkX indicator.
--   • Compact legend + group color row below the SVG.
--------------------------------------------------------------------------------
local function buildSvgOverlayPage(layout, gfx, model, theme, svgImg, coords)
  local vbW, vbH   = coords.viewBox.w, coords.viewBox.h
  -- All chassis render at the same visible height. The artwork is cropped
  -- left of port 1 (parser) and the device display block fills that spot,
  -- like Araneo's screen. Width scales by aspect ratio.
  local blockX, blockY = CHASSIS_X, CHASSIS_Y
  local svgX, svgY = blockX + DISPLAY_W + DISPLAY_GAP, CHASSIS_Y
  local svgH       = CHASSIS_H
  local svgW       = chassisSvgWidth(model)
  local sx         = svgW / vbW
  local sy         = svgH / vbH
  local svgBottomY = svgY + svgH

  -- Per-port settings grid below the chassis. Bottom gap matches the top
  -- gap so the page is symmetrically padded; column and row counts come
  -- from gridDimsForModel.
  local topGap    = 6
  local gridY     = svgBottomY + topGap
  local cols, rows = gridDimsForModel(model)
  local portCount = #coords.ports
  local rowH      = GRID_ROW_H
  local poePorts  = (PORT_LAYOUT[model] and PORT_LAYOUT[model].poe) or 0
  local pageH     = pageHeightForModel(model)

  gfx[#gfx+1] = {
    Type        = "Groupbox",
    Fill        = theme.groupboxFill,
    StrokeColor = GROUPBOX_STROKE_COLOR,
    StrokeWidth = GROUPBOX_STROKE_WIDTH,
    Position    = GROUPBOX_POSITION,
    Size        = { pageWidthForModel(model), pageH },
  }

  -- Device display block: closes the chassis frame on the left (the SVG's
  -- own left edge is cropped away). Page-bg fill (the Araneo "screen"), and
  -- the same white outline weight as the artwork (1 SVG unit = sx px).
  local outlineW = math.max(1, math.floor(sx + 0.5))
  gfx[#gfx+1] = {
    Type         = "Rectangle",
    Position     = { blockX, blockY },
    Size         = { DISPLAY_W + outlineW, svgH },
    Fill         = theme.pageBg,
    StrokeColor  = { 255, 255, 255, 255 },
    StrokeWidth  = outlineW,
    CornerRadius = 4,
  }
  local scrX, scrY = blockX + outlineW, blockY + outlineW
  local scrW, scrH = DISPLAY_W - outlineW * 2, svgH - outlineW * 2

  -- Chassis SVG backdrop (cropped artwork)
  gfx[#gfx+1] = {
    Type     = "Svg",
    Image    = svgImg,
    Position = { svgX, svgY },
    Size     = { svgW, svgH },
  }

  -- Screen contents: logo + status badge on the first row, then model,
  -- device name, IP, firmware + MAC. Static placeholders sit under the
  -- transparent controls for the offline (never emulated) look; the
  -- runtime paints a control opaque when live data lands in it.
  local pad   = 5
  local logoH = 16
  local logoW = math.floor(logoH * 3.3 + 0.5)
  local logoX, logoY = scrX + pad, scrY + pad
  gfx[#gfx+1] = {
    Type     = "Svg",
    Image    = LogoLuminex,
    Position = { logoX, logoY },
    Size     = { logoW, logoH },
  }
  -- Invisible button covering the logo — click triggers /api/identify.
  layout["Device.Identify"] = {
    Style             = "Button",
    ButtonStyle       = "Momentary",
    ButtonVisualStyle = "Flat",
    Position          = { logoX, logoY },
    Size              = { logoW, logoH },
    Color             = { 0, 0, 0, 0 },
    OffColor          = { 0, 0, 0, 0 },
    StrokeColor       = { 0, 0, 0, 0 },
    StrokeWidth       = 0,
    Legend            = "",
  }

  local statusW, statusH = 56, 16
  local statusX = scrX + scrW - pad - statusW
  local statusY = scrY + pad
  gfx[#gfx+1] = {
    Type         = "Rectangle",
    Position     = { statusX, statusY },
    Size         = { statusW, statusH },
    Fill         = theme.badgeOffBg,
    StrokeWidth  = 0,
    CornerRadius = 6,
  }
  gfx[#gfx+1] = {
    Type       = "Text",
    Text       = "Offline",
    Position   = { statusX, statusY },
    Size       = { statusW, statusH },
    Font       = "Roboto",
    FontSize   = 10,
    Color      = theme.badgeOffFg,
    HTextAlign = "Center",
    VTextAlign = "Center",
  }
  layout["Device.Status"] = {
    Style        = "Text",
    Position     = { statusX, statusY },
    Size         = { statusW, statusH },
    IsReadOnly   = true,
    Color        = { 0, 0, 0, 0 },
    Font         = "Roboto",
    FontSize     = 10,
    TextColor    = { 255, 255, 255 },
    StrokeWidth  = 0,
    CornerRadius = 6,
    HTextAlign   = "Center",
    VTextAlign   = "Center",
  }

  local lineH = 14
  local lineX = scrX + pad
  local lineW = scrW - pad * 2
  local line1 = logoY + logoH + 3
  local function screenText(x, y, w, text, color, bold)
    gfx[#gfx+1] = {
      Type       = "Text",
      Text       = text,
      Position   = { x, y },
      Size       = { w, lineH },
      Font       = "Roboto",
      FontSize   = 10,
      Color      = color,
      HTextAlign = "Left",
      VTextAlign = "Center",
      IsBold     = bold or false,
    }
  end
  local function screenBox(name, x, y, w)
    layout[name] = {
      Style        = "Text",
      Position     = { x, y },
      Size         = { w, lineH },
      IsReadOnly   = true,
      Color        = { 0, 0, 0, 0 },
      Font         = "Roboto",
      FontSize     = 10,
      TextColor    = theme.textPrimary,
      StrokeWidth  = 0,
      CornerRadius = 1,
      HTextAlign   = "Left",
      VTextAlign   = "Center",
    }
  end
  screenText(lineX, line1, lineW, model, theme.textPrimary, true)
  for i = 1, 4 do screenText(lineX, line1 + lineH * i, lineW, "---", theme.textMuted) end
  local fwW = 44
  screenBox("Device.Name",        lineX, line1 + lineH, lineW)
  screenBox("Device.Description", lineX, line1 + lineH * 2, lineW)
  screenBox("Device.IP Info",     lineX, line1 + lineH * 3, lineW)
  screenBox("Device.Firmware",    lineX, line1 + lineH * 4, fwW)
  screenBox("Device.MAC",         lineX + fwW + 4, line1 + lineH * 4, lineW - fwW - 4)

  -- Screen rects snapped to whole pixels with a uniform pitch inside each
  -- block of neighbouring ports (same row, regular spacing). Rounding each
  -- port independently gave alternating 56/57 px gaps, visible as uneven
  -- dark lines between the cards.
  local screenRects = {}
  do
    local rowsByKey = { top = {}, bottom = {} }
    for _, p in ipairs(coords.ports) do
      local key = ((p.y + p.h / 2) < vbH / 2) and "top" or "bottom"
      local list = rowsByKey[key]
      list[#list + 1] = p
    end
    for _, list in pairs(rowsByKey) do
      table.sort(list, function(a, b) return a.x < b.x end)
      -- A block ends where the gap grows past the row's smallest pitch
      -- (Araneo block gaps are only ~20% wider than the port pitch, e.g.
      -- 18 vs 15 SVG units on the 30i) or the port kind changes.
      local minGap = math.huge
      for i = 2, #list do
        local g = list[i].x - list[i - 1].x
        if list[i].kind == list[i - 1].kind and g < minGap then minGap = g end
      end
      local blocks, cur = {}, nil
      for i, p in ipairs(list) do
        local prev = list[i - 1]
        if prev and p.kind == prev.kind and (p.x - prev.x) <= minGap * 1.12 then
          cur[#cur + 1] = p
        else
          cur = { p }
          blocks[#blocks + 1] = cur
        end
      end
      for _, blk in ipairs(blocks) do
        local w  = math.floor(blk[1].w * sx + 0.5)
        local h  = math.floor(blk[1].h * sy + 0.5)
        local y  = math.floor(svgY + blk[1].y * sy + 0.5)
        local x0 = math.floor(svgX + blk[1].x * sx + 0.5)
        local pitch = 0
        if #blk > 1 then
          pitch = math.floor((blk[#blk].x - blk[1].x) * sx / (#blk - 1) + 0.5)
        end
        for i, p in ipairs(blk) do
          screenRects[p.port] = { x = x0 + (i - 1) * pitch, y = y, w = w, h = h }
        end
      end
    end
  end

  -- Per-port interactive overlays
  for _, p in ipairs(coords.ports) do
    local rect = screenRects[p.port] or svgToScreen(p, svgX, svgY, svgW, svgH, vbW, vbH)
    -- Grow each button by 1px each side so it hugs the SVG port outline
    -- without pushing past the rlinkx / cable-clip indicators.
    local bx = rect.x - 1
    local by = rect.y - 1
    local bw = rect.w + 2
    local bh = rect.h + 2

    -- Group-color halo behind the port. Strategy:
    --   • If the port is large enough to span both rows (e.g. 20t ethercons
    --     occupy ~50% of chassis height), wrap a single halo around the
    --     whole port from chassis-top to chassis-bottom (with edge gap).
    --   • Otherwise, anchor halo top/bottom to row-relative y values so
    --     same-row halos are uniform height and rows don't overlap.
    local bgPadX = 3
    local edgeGapSvg  = 2
    local innerGapSvg = 0.5
    local rowMidSvg   = vbH / 2
    local portCenterY = p.y + p.h / 2
    local portIsTall  = p.h > (vbH * 0.45)
    local haloTopSvg, haloBotSvg
    if portIsTall then
      haloTopSvg = edgeGapSvg
      haloBotSvg = vbH - edgeGapSvg
    elseif portCenterY < rowMidSvg then
      haloTopSvg = edgeGapSvg
      haloBotSvg = rowMidSvg - innerGapSvg
    else
      haloTopSvg = rowMidSvg + innerGapSvg
      haloBotSvg = vbH - edgeGapSvg
    end
    local haloY = svgY + haloTopSvg * sy
    local haloH = (haloBotSvg - haloTopSvg) * sy
    layout["Port Bg" .. p.port] = {
      Style           = "Text",
      Position        = { bx - bgPadX, haloY },
      Size            = { bw + bgPadX * 2, haloH },
      FontSize        = 1,
      IsReadOnly      = true,
      Color           = { 0, 0, 0, 0 },
      TextColor       = { 0, 0, 0, 0 },
      BackgroundColor = { 0, 0, 0, 0 },
      StrokeWidth     = 0,
      StrokeColor     = { 0, 0, 0, 0 },
      CornerRadius    = 3,
      HTextAlign      = "Center",
      VTextAlign      = "Center",
    }

    -- RLinkX ring — a ~2px-thicker frame around the port body.
    local rlPad = 3
    layout["Port RlinkX " .. p.port] = {
      Style             = "Button",
      ButtonStyle       = "Toggle",
      ButtonVisualStyle = "Flat",
      Position          = { bx - rlPad, by - rlPad },
      Size              = { bw + rlPad * 2, bh + rlPad * 2 },
      IsReadOnly        = true,
      Color             = { 20, 24, 40, 0 },
      OffColor          = { 20, 24, 40, 0 },
      StrokeColor       = { 0, 0, 0, 0 },
      StrokeWidth       = 0,
      CornerRadius      = (p.kind == "ethercon") and math.floor((bw + rlPad * 2) / 2) or 3,
    }

    -- Port.Link button. Color is painted at runtime to encode link speed
    -- (orange for 10/100 Mbps, green for 1Gbps+, dark for not connected).
    -- Offline (never emulated) look follows Araneo's project mode: navy
    -- body, thin cyan outline, port number inside. Runtime repaints Color
    -- and OffColor with the link speed and blanks the Legend on disabled
    -- ports.
    layout["Port.Link " .. p.port] = {
      Style             = "Button",
      ButtonStyle       = "Toggle",
      ButtonVisualStyle = "Flat",
      Position          = { bx, by },
      Size              = { bw, bh },
      IsReadOnly        = true,
      Color             = theme.portOffFill,
      OffColor          = theme.portOffFill,
      StrokeColor       = theme.portOffStroke,
      StrokeWidth       = 1,
      CornerRadius      = (p.kind == "ethercon") and math.floor(bw / 2) or 2,
      Legend            = tostring(p.port),
      Font              = "Roboto",
      FontSize          = 11,
      IsBold            = true,
      TextColor         = theme.portText,
    }

    -- PoE pip — positioned on the SVG's cable-clip rect when one exists,
    -- otherwise on a derived spot just above (top-row) or below (bottom-row)
    -- the port. Ethercon ports usually have no SVG cable clip but still
    -- need a pip location (the runtime picks color + visibility based on
    -- /poe/ports/N state). SFP ports skip pip placement (no PoE support).
    local pipPos, pipSize
    if p.kind == "sfp" then
      pipPos, pipSize = { -100, -100 }, { 1, 1 }
    else
      local poeRect = p.poe
      if not poeRect then
        local pipW, pipH = 5, 5
        local pipX = p.x + (p.w - pipW) / 2
        local pipY
        if (p.y + p.h / 2) < vbH / 2 then
          pipY = p.y - pipH + 2  -- mostly above port, 2 SVG units overlap
        else
          pipY = p.y + p.h - 2
        end
        poeRect = { x = pipX, y = pipY, w = pipW, h = pipH }
      end
      -- Pip x follows the snapped port centre (same offset as in the SVG).
      local pipScreen = svgToScreen(poeRect, svgX, svgY, svgW, svgH, vbW, vbH)
      local pipW = math.floor(pipScreen.w + 0.5)
      local pipH = math.floor(pipScreen.h + 0.5)
      local offsetSvg = (poeRect.x + poeRect.w / 2) - (p.x + p.w / 2)
      local pipX = math.floor(rect.x + rect.w / 2 + offsetSvg * sx - pipW / 2 + 0.5)
      pipPos  = { pipX, math.floor(pipScreen.y + 0.5) }
      pipSize = { pipW, pipH }
    end
    -- Offline: PoE-capable ports show the grey "disabled" pip (Araneo
    -- project mode); runtime repaints with the live PoE state.
    local hasPoe = (p.kind ~= "sfp") and (p.port <= poePorts)
    local pipOff = hasPoe and theme.poeDisabled or { 0, 0, 0, 0 }
    layout["Port.PoE Color " .. p.port] = {
      Style             = "Button",
      ButtonStyle       = "Toggle",
      ButtonVisualStyle = "Flat",
      Position          = pipPos,
      Size              = pipSize,
      IsReadOnly        = true,
      Color             = pipOff,
      OffColor          = pipOff,
      StrokeColor       = { 0, 0, 0, 0 },
      StrokeWidth       = 0,
      CornerRadius      = 1,
    }

    -- Disabled-port red X marker. Runtime sets String="✕" when disabled.
    layout["Port.zz Disabled X " .. p.port] = {
      Style       = "Text",
      Position    = { bx, by },
      Size        = { bw, bh },
      Font        = "Roboto",
      FontSize    = 14,
      IsReadOnly  = true,
      Color       = { 0, 0, 0, 0 },
      TextColor   = { 220, 40, 40, 255 },
      StrokeWidth = 0,
      StrokeColor = { 0, 0, 0, 0 },
      HTextAlign  = "Center",
      VTextAlign  = "Center",
      IsBold      = true,
    }

    -- Trunk badge — top-left corner of the group-color halo (inside the
    -- halo's edge), so it visually "belongs" to the colored card.
    local tbSize = 10
    layout["Port.Trunk Badge " .. p.port] = {
      Style             = "Button",
      ButtonStyle       = "Toggle",
      ButtonVisualStyle = "Flat",
      Position          = { bx - bgPadX, haloY },
      Size              = { tbSize, tbSize },
      IsReadOnly        = true,
      Font              = "Roboto",
      FontSize          = 10,
      Legend            = "",
      TextColor         = theme.trunkBadge,
      Color             = { 0, 0, 0, 0 },
      OffColor          = { 0, 0, 0, 0 },
      StrokeColor       = { 0, 0, 0, 0 },
      StrokeWidth       = 0,
      CornerRadius      = 0,
    }

    -- Multicast-router badge — sits ABOVE the port top edge, top-right.
    -- Hidden by default (transparent Color/Stroke); runtime SetMrPorts
    -- paints the white border, black fill, and "MR" legend for ports in
    -- the IGMP snooping router list. Named "Port.zMR " so it sorts after
    -- Port.PoE Color → renders on top.
    local mrW, mrH = 16, 11
    layout["Port.zMR " .. p.port] = {
      Style             = "Button",
      ButtonStyle       = "Toggle",
      ButtonVisualStyle = "Flat",
      Position          = { bx + bw - mrW + 3, by - 4 },
      Size              = { mrW, mrH },
      IsReadOnly        = true,
      Font              = "Roboto",
      FontSize          = 8,
      Legend            = "",
      TextColor         = { 255, 255, 255, 255 },
      Color             = { 0, 0, 0, 0 },
      OffColor          = { 0, 0, 0, 0 },
      StrokeColor       = { 0, 0, 0, 0 },
      StrokeWidth       = 1,
      CornerRadius      = 2,
      IsBold            = true,
    }
  end

  -- Per-port settings grid below the chassis. 4 columns × 8 rows of controls
  -- mirroring what the old Port Settings page exposed: enable toggle, port
  -- number, legend TextBox, RLinkX toggle, PoE toggle, PoE bounce, speed combo.
  local labelW     = 16
  local enableW    = 20
  local legendW    = 50
  local rlinkxW    = 20
  local poeToggleW = 20
  local poeBounceW = 20
  local groupW     = 72
  local speedW     = 110
  local colPad     = GRID_COL_PAD
  local colW       = GRID_COL_W
  local cellH      = 18
  local xStart     = GRID_X_START
  local cSpacing   = colW + colPad

  for p = 1, portCount do
    local col = math.floor((p - 1) / rows)
    local rowI = (p - 1) % rows
    local y = gridY + rowI * rowH
    local x = xStart + col * cSpacing

    local labelX     = x
    local enableX    = labelX + labelW
    local legendX    = enableX + enableW
    local rlinkxX    = legendX + legendW
    local poeToggleX = rlinkxX + rlinkxW
    local poeBounceX = poeToggleX + poeToggleW
    local groupX     = poeBounceX + poeBounceW
    local speedX     = groupX + groupW

    layout["Port.Enable " .. p] = {
      Style             = "Button",
      ButtonStyle       = "Toggle",
      Position          = { enableX, y },
      Size              = { enableW, cellH },
      FontSize          = 9,
      TextColor         = { 255, 255, 255 },
      Color             = { 30, 200, 60 },
      OffColor          = { 0, 0, 0 },
      CornerRadius      = 2,
      HTextAlign        = "Center",
      VTextAlign        = "Center",
      ButtonVisualStyle = "Flat",
      Legend            = "",
    }

    -- Port number is a clickable Button (identifies the port via API).
    layout["Port.Identify " .. p] = {
      Style             = "Button",
      ButtonStyle       = "Momentary",
      ButtonVisualStyle = "Flat",
      Position          = { labelX, y },
      Size              = { labelW, cellH },
      Font              = "Roboto",
      FontSize          = 10,
      Legend            = tostring(p),
      TextColor         = theme.textPrimary,
      Color             = { 0, 0, 0, 0 },
      OffColor          = { 0, 0, 0, 0 },
      StrokeColor       = { 0, 0, 0, 0 },
      StrokeWidth       = 0,
    }

    layout["Port.Legend Edit " .. p] = {
      Style        = "TextBox",
      Position     = { legendX + 1, y },
      Size         = { legendW - 2, cellH },
      Font         = "Roboto",
      FontSize     = 10,
      HTextAlign   = "Left",
      TextColor    = theme.textPrimary,
      Color        = { 0, 0, 0, 0 },
      StrokeColor  = theme.cardStroke,
      StrokeWidth  = 1,
      CornerRadius = 1,
    }

    layout["RLinkX.Toggle " .. p] = {
      Style             = "Button",
      ButtonStyle       = "Toggle",
      Position          = { rlinkxX, y },
      Size              = { rlinkxW, cellH },
      Color             = { 0, 200, 255 },
      CornerRadius      = 2,
      OffColor          = { 40, 40, 40 },
      HTextAlign        = "Center",
      VTextAlign        = "Center",
      ButtonVisualStyle = "Flat",
      Legend            = "",
    }

    layout["PoE.Toggle " .. p] = {
      Style             = "Button",
      ButtonStyle       = "Toggle",
      Position          = { poeToggleX, y },
      Size              = { poeToggleW, cellH },
      Color             = { 0, 0, 0, 0 },
      CornerRadius      = 2,
      ButtonVisualStyle = "Flat",
      Legend            = "",
    }

    layout["PoE.Bounce " .. p] = {
      Style             = "Button",
      ButtonStyle       = "Momentary",
      Position          = { poeBounceX, y },
      Size              = { poeBounceW, cellH },
      Legend            = "↻",
      FontSize          = 10,
      TextColor         = theme.textPrimary,
      Color             = theme.accentCyan,
      OffColor          = theme.buttonOffColor,
      CornerRadius      = 2,
      ButtonVisualStyle = "Flat",
    }

    layout["Port.Group " .. p] = {
      Style             = "Button",
      ButtonStyle       = "Momentary",
      ButtonVisualStyle = "Flat",
      Position          = { groupX, y },
      Size              = { groupW, cellH },
      Font              = "Roboto",
      FontSize          = 10,
      Legend            = "",
      TextColor         = { 255, 255, 255, 255 },
      Color             = { 60, 70, 90, 255 },
      OffColor          = { 60, 70, 90, 255 },
      StrokeColor       = theme.cardStroke,
      StrokeWidth       = 1,
      CornerRadius      = 2,
    }

    layout["Port.Speed " .. p] = {
      Style        = "ComboBox",
      Position     = { speedX, y },
      Size         = { speedW, cellH },
      Font         = "Roboto",
      FontSize     = 10,
      TextColor    = theme.textPrimary,
      Color        = { 0, 0, 0, 0 },
      IsReadOnly   = false,
      StrokeColor  = theme.cardStroke,
      StrokeWidth  = 1,
      CornerRadius = 1,
    }
  end

end

--------------------------------------------------------------------------------
-- Groups and Trunks sections (groups | custom groups | trunks | custom
-- trunks): a vertical card list per section that spills into sub-columns
-- after groupsRowsForModel(model) items. Shared by the Groups and Trunks
-- page and the main-page group picker. onSection(index, title, x, labelY,
-- widthPx) fires once per section, onCard(kind, item, x, y) once per card
-- (item = { slot, name, key } or { slot, placeholder = true } for a reserved
-- custom slot the runtime fills later).
--------------------------------------------------------------------------------
local function walkGroupTrunkSections(model, originX, labelY, cardsY, onSection, onCard)
  local rows = groupsRowsForModel(model)
  local sections = {
    { title = "Groups",        kind = "group", items = {} },
    { title = "Custom groups", kind = "group", items = {} },
    { title = "Trunks",        kind = "trunk", items = {} },
    { title = "Custom trunks", kind = "trunk", items = {} },
  }
  for i = 1, 20 do
    local name = state.groupNames[i] or (i == 1 and "Management" or ("Group " .. string.format("%02d", i)))
    sections[1].items[i] = { slot = i, name = name, key = "Group: " .. i }
  end
  for i = 1, CUSTOM_GROUP_SLOTS do
    sections[2].items[i] = { slot = 20 + i, placeholder = true }
  end
  sections[3].items[1] = { slot = 1, name = "ISL", key = "Trunk: 1" }
  for i = 1, CUSTOM_TRUNK_SLOTS do
    sections[4].items[i] = { slot = 1 + i, placeholder = true }
  end

  local cursorX = originX
  for si, s in ipairs(sections) do
    local subCols    = math.max(1, math.ceil(#s.items / rows))
    local sectionWpx = subCols * GT_CARD_W + (subCols - 1) * 4
    onSection(si, s.title, cursorX, labelY, sectionWpx)
    for idx, item in ipairs(s.items) do
      local subCol = math.floor((idx - 1) / rows)
      local rowI   = (idx - 1) % rows
      onCard(s.kind, item, cursorX + subCol * (GT_CARD_W + 4), cardsY + rowI * (GT_CARD_H + GT_GAP_Y))
    end
    cursorX = cursorX + sectionWpx + GT_SECTION_GAP
  end
end

--------------------------------------------------------------------------------
-- Group picker panel (main page). A modal card over the chassis page that
-- lists every group and trunk slot; the runtime paints and shows it when a
-- Port.Group cell is clicked (openGroupPicker in info.lua) and hides it
-- again after a pick. Every control is transparent at layout time (offline
-- look) and IsInvisible from runtime start. The "zPicker" prefix sorts after
-- every other main-page control so the panel renders on top of the grid.
--------------------------------------------------------------------------------
local PICKER_PAD, PICKER_TITLE_H, PICKER_BTN_W = 8, 20, 70

local function buildGroupPickerPanel(layout, model, theme)
  local rows   = groupsRowsForModel(model)
  local pageW  = pageWidthForModel(model)
  local panelW = groupsPageWidthForRows(rows) - 2 * GT_MARGIN_X + 2 * PICKER_PAD
  local panelH = PICKER_PAD + PICKER_TITLE_H + 6 + GT_LABEL_H + 6
               + rows * (GT_CARD_H + GT_GAP_Y) - GT_GAP_Y + PICKER_PAD
  local panelX = math.floor((pageW - panelW) / 2 + 0.5)
  local panelY = 10
  local clear  = { 0, 0, 0, 0 }

  local function pickerButton(name, x, y, w, h)
    layout[name] = {
      Style             = "Button",
      ButtonStyle       = "Momentary",
      ButtonVisualStyle = "Flat",
      Position          = { x, y },
      Size              = { w, h },
      Font              = "Roboto",
      FontSize          = 10,
      Legend            = "",
      TextColor         = { 255, 255, 255 },
      Color             = clear,
      OffColor          = clear,
      StrokeColor       = clear,
      StrokeWidth       = 0,
      CornerRadius      = 3,
      HTextAlign        = "Center",
      VTextAlign        = "Center",
    }
  end
  local function pickerText(name, x, y, w, h, textColor)
    layout[name] = {
      Style        = "Text",
      Position     = { x, y },
      Size         = { w, h },
      Font         = "Roboto",
      FontSize     = 11,
      IsBold       = true,
      HTextAlign   = "Left",
      VTextAlign   = "Center",
      TextColor    = textColor,
      Color        = clear,
      StrokeWidth  = 0,
      IsReadOnly   = true,
      String       = "",
    }
  end

  pickerButton("zPicker.Bg", panelX, panelY, panelW, panelH)
  layout["zPicker.Bg"].CornerRadius = 4

  local titleY  = panelY + PICKER_PAD
  local cancelX = panelX + panelW - PICKER_PAD - PICKER_BTN_W
  local noneX   = cancelX - 6 - PICKER_BTN_W
  pickerText("zPicker.Title", panelX + PICKER_PAD, titleY, noneX - 6 - (panelX + PICKER_PAD), PICKER_TITLE_H, theme.textPrimary)
  pickerButton("zPicker.None",   noneX,   titleY, PICKER_BTN_W, PICKER_TITLE_H)
  pickerButton("zPicker.Cancel", cancelX, titleY, PICKER_BTN_W, PICKER_TITLE_H)

  local labelY = titleY + PICKER_TITLE_H + 6
  walkGroupTrunkSections(model, panelX + PICKER_PAD, labelY, labelY + GT_LABEL_H + 6,
    function(si, _title, x, y, w)
      pickerText("zPicker.Label " .. si, x, y, w, GT_LABEL_H, theme.textMuted)
    end,
    function(kind, item, x, y)
      pickerButton(((kind == "group") and "zPicker.Group " or "zPicker.Trunk ") .. item.slot, x, y, GT_CARD_W, GT_CARD_H)
    end)
end

local function buildControlsPage(layout, gfx, model)
  local theme  = getThemeColors()
  local svg    = getChassisSvg(model)
  local coords = getPortCoords(model)
  if svg and coords then
    buildSvgOverlayPage(layout, gfx, model, theme, svg, coords)
    buildGroupPickerPanel(layout, model, theme)
    return
  end

  local portCount     = getPortCount(model)
  local etherconCount = getEtherconCount(model)
  local rj45Count     = portCount - etherconCount  -- everything non-ethercon rendered uniformly

  local btnW, btnH    = 66, 44
  local colSpacing    = 5
  local rowGap        = 60
  local sideMargin    = SIDE_MARGIN
  local topY          = 50
  local botY          = topY + btnH + rowGap
  local startX        = sideMargin
  local theme         = getThemeColors()

  -- Ethercon section dimensions (when present)
  local ethW          = 62
  local ethCols       = (etherconCount > 0) and math.ceil(etherconCount / 2) or 0
  local ethSpacing    = 8
  local ethSectionW   = (ethCols > 0) and (ethCols * ethW + (ethCols - 1) * ethSpacing) or 0
  local sectionGap    = (etherconCount > 0) and 24 or 0

  -- RJ45 section dimensions
  local rj45Cols      = math.ceil(rj45Count / 2)
  local rj45SectionW  = rj45Cols * btnW + math.max(0, rj45Cols - 1) * colSpacing

  local totalPortsW   = ethSectionW + sectionGap + rj45SectionW
  local totalW        = totalPortsW + sideMargin * 2
  local totalH        = 275

  gfx[#gfx+1] = {
    Type        = "Groupbox",
    Fill        = theme.groupboxFill,
    StrokeColor = GROUPBOX_STROKE_COLOR,
    StrokeWidth = GROUPBOX_STROKE_WIDTH,
    Position    = GROUPBOX_POSITION,
    Size        = { totalW + GROUPBOX_EXTRA_PADDING, totalH },
  }

  local lumCenterX, ipY = drawCommonLogos(gfx)
  defineCommonDeviceInfo(layout, gfx, theme, lumCenterX, ipY + -5)

  -- Ethercon ports (sequential layout: 1..N/2 top row, N/2+1..N bottom row)
  for i = 1, etherconCount do
    local row = (i <= ethCols) and 0 or 1
    local col = (row == 0) and (i - 1) or (i - ethCols - 1)
    local xPos = startX + col * (ethW + ethSpacing)
    local yPos = (row == 0) and topY or botY
    renderEtherconPort(layout, gfx, i, xPos, yPos, theme)
  end

  -- All non-ethercon ports rendered uniformly as the standard RJ45 tile,
  -- regardless of whether they're physically RJ45 or SFP. Keeps the layout
  -- consistent like before — per-port-type sections were too disruptive.
  local rj45StartX = startX + ethSectionW + sectionGap
  local p = etherconCount + 1
  for c = 0, rj45Cols - 1 do
    if p > portCount then break end
    local xPos = rj45StartX + c * (btnW + colSpacing)
    renderRJ45Port(layout, gfx, p, xPos, topY, theme, 1)
    p = p + 1
    if p > portCount then break end
    renderRJ45Port(layout, gfx, p, xPos, botY, theme, 2)
    p = p + 1
  end
end

--------------------------------------------------------------------------------
-- Port settings page
--------------------------------------------------------------------------------
local function buildPortSettingsPage(layout, gfx, props)
  local model = resolveModel(props)
  local portCount = getPortCount(model)
  local rows    = 8
  local columns = math.ceil(portCount / rows)

  local toggleW    = 22
  local labelW     = 17
  local boxW       = 100
  local rlinkxW    = 22
  local poeToggleW = 22
  local poeBounceW = 22
  local dropdownW  = 124
  local gap        = 0

  local colW   = labelW + toggleW + boxW + rlinkxW + poeToggleW + poeBounceW + dropdownW + (gap * 6)
  local cSpace = colW + 2
  local boxH   = 18
  local rSpace = 22
  local startX = 2
  local startY = 50

  local totalW = columns * cSpace + startX
  local totalH = 275
  local theme  = getThemeColors()

  gfx[#gfx+1] = {
    Type        = "Groupbox",
    Fill        = theme.groupboxFill,
    StrokeColor = GROUPBOX_STROKE_COLOR,
    StrokeWidth = GROUPBOX_STROKE_WIDTH,
    Position    = GROUPBOX_POSITION,
    Size        = { totalW + GROUPBOX_EXTRA_PADDING, totalH },
  }

  local lumCenterX, ipY = drawCommonLogos(gfx)
  defineCommonDeviceInfo(layout, gfx, theme, lumCenterX, ipY)

  local p = 1
  for col = 0, columns - 1 do
    for row = 0, rows - 1 do
      if p > portCount then break end

      local y = startY + row * rSpace
      local x = startX + col * cSpace

      local labelX     = x
      local enableX    = labelX + labelW + gap
      local legendX    = enableX + toggleW + gap
      local rlinkxX    = legendX + boxW + gap
      local poeToggleX = rlinkxX + rlinkxW + gap
      local poeBounceX = poeToggleX + poeToggleW + gap
      local speedX     = poeBounceX + poeBounceW + gap

      layout["Port.Enable " .. p] = {
        Style             = "Button",
        ButtonStyle       = "Toggle",
        Position          = { enableX - 2, y },
        Size              = { toggleW, boxH },
        FontSize          = 10,
        TextColor         = { 255, 255, 255 },
        Color             = { 30, 200, 60 },
        OffColor          = { 0, 0, 0 },
        CornerRadius      = 2,
        HTextAlign        = "Center",
        VTextAlign        = "Center",
        ButtonVisualStyle = "Flat",
        Legend            = "",
      }

      gfx[#gfx+1] = {
        Type       = "Text",
        Text       = tostring(p),
        Position   = { labelX, y },
        Size       = { labelW, boxH },
        Font       = "Roboto",
        FontSize   = 11,
        Color      = theme.textPrimary,
        HTextAlign = "Center",
        VTextAlign = "Center",
      }

      layout["Port.Legend Edit " .. p] = {
        Style        = "TextBox",
        Position     = { legendX - 1, y },
        Size         = { boxW, boxH },
        Font         = "Roboto",
        FontSize     = 11,
        HTextAlign   = "Left",
        TextColor    = theme.textPrimary,
        Color        = { 0, 0, 0, 0 },
        StrokeColor  = theme.cardStroke,
        StrokeWidth  = 1,
        CornerRadius = 1,
      }

      layout["RLinkX.Toggle " .. p] = {
        Style             = "Button",
        ButtonStyle       = "Toggle",
        Position          = { rlinkxX, y },
        Size              = { rlinkxW, boxH },
        Color             = { 0, 200, 255 },
        CornerRadius      = 2,
        OffColor          = { 40, 40, 40 },
        HTextAlign        = "Center",
        VTextAlign        = "Center",
        ButtonVisualStyle = "Flat",
        Legend            = "",
      }

      layout["PoE.Toggle " .. p] = {
        Style             = "Button",
        ButtonStyle       = "Toggle",
        Position          = { poeToggleX, y },
        Size              = { poeToggleW, boxH },
        String            = "",
        Color             = { 0, 0, 0, 0 },
        CornerRadius      = 2,
        ButtonVisualStyle = "Flat",
      }

      layout["PoE.Bounce " .. p] = {
        Style             = "Button",
        ButtonStyle       = "Momentary",
        Position          = { poeBounceX, y },
        Size              = { poeBounceW, boxH },
        Legend            = "↻",
        FontSize          = 12,
        TextColor         = theme.textPrimary,
        Color             = theme.accentCyan,
        OffColor          = theme.buttonOffColor,
        CornerRadius      = 2,
        ButtonVisualStyle = "Flat",
      }

      layout["Port.Speed " .. p] = {
        Style        = "ComboBox",
        Position     = { speedX, y },
        Size         = { dropdownW, boxH },
        Font         = "Roboto",
        FontSize     = 11,
        TextColor    = theme.textPrimary,
        Color        = { 0, 0, 0, 0 },
        IsReadOnly   = false,
        StrokeColor  = theme.cardStroke,
        StrokeWidth  = 1,
        CornerRadius = 1,
      }

      p = p + 1
    end
  end
end

--------------------------------------------------------------------------------
-- Configuration page
--------------------------------------------------------------------------------
local function buildConfigurationPage(layout, gfx, props)
  local theme  = getThemeColors()
  -- Match main-page height (computed in buildSvgOverlayPage); use
  -- pageHeightForModel so tabs don't resize the window.
  local model = resolveModel(props)
  local totalW = pageWidthForModel(model)
  local totalH = pageHeightForModel(model)

  gfx[#gfx+1] = {
    Type        = "Groupbox",
    Fill        = theme.groupboxFill,
    StrokeColor = { 0, 0, 0 },
    StrokeWidth = 0,
    Position    = { 0, 0 },
    Size        = { totalW, totalH },
  }

  defineCommonDeviceInfo(layout, gfx, theme, 0, 0)

  local labelX = 30
  local inputX = 110
  local rowY   = 90
  local rowGap = 40
  local boxW   = 140
  local boxH   = 24
  local labelW = 70

  local connectX = 270
  local btnW     = 120
  local btnH     = 30

  gfx[#gfx+1] = {
    Type       = "Text",
    Text       = "IP Address",
    Position   = { labelX, rowY + 0 },
    Size       = { labelW, boxH },
    Font       = "Roboto",
    FontSize   = 10,
    Color      = theme.labelGray,
    HTextAlign = "Right",
    VTextAlign = "Center",
  }

  layout["Auth.IP Address"] = {
    Style      = "TextBox",
    Position   = { inputX, rowY + 0 },
    Size       = { boxW, boxH },
    Font       = "Roboto",
    FontSize   = 14,
    HTextAlign = "Center",
    Color      = { 0, 0, 0, 0 },
    TextColor  = { 255, 255, 255 },
  }

  layout["Auth.Connect"] = {
    Legend      = "Connect",
    Style       = "Button",
    ButtonStyle = "Momentary",
    Color       = { 0, 255, 0 },
    OffColor    = theme.buttonOffColor,
    Position    = { connectX, rowY },
    Size        = { btnW, btnH },
    Font        = "Roboto",
    FontSize    = 13,
    HTextAlign  = "Center",
  }

  gfx[#gfx+1] = {
    Type       = "Text",
    Text       = "Username",
    Position   = { labelX, rowY + rowGap },
    Size       = { labelW, boxH },
    Font       = "Roboto",
    FontSize   = 10,
    TextColor  = { 255, 255, 255 },
    Color      = theme.labelGray,
    HTextAlign = "Right",
    VTextAlign = "Center",
  }

  layout["Auth.Username"] = {
    Style      = "TextBox",
    Position   = { inputX, rowY + rowGap },
    Size       = { boxW, boxH },
    Font       = "Roboto",
    FontSize   = 14,
    HTextAlign = "Center",
    Color      = { 0, 0, 0, 0 },
    TextColor  = { 255, 255, 255 },
  }

  layout["Auth.Identify"] = {
    Legend      = "Identify",
    Style       = "Button",
    ButtonStyle = "Momentary",
    Color       = { 0, 150, 255 },
    OffColor    = { 30, 30, 30 },
    Position    = { connectX, rowY + rowGap },
    Size        = { btnW, btnH },
    Font        = "Roboto",
    FontSize    = 13,
    HTextAlign  = "Center",
  }

  gfx[#gfx+1] = {
    Type       = "Text",
    Text       = "Password",
    Position   = { labelX, rowY + rowGap * 2 },
    Size       = { labelW, boxH },
    Font       = "Roboto",
    FontSize   = 10,
    Color      = theme.labelGray,
    HTextAlign = "Right",
    VTextAlign = "Center",
  }

  layout["Auth.Password"] = {
    Style      = "TextBox",
    IsPassword = true,
    Position   = { inputX, rowY + rowGap * 2 },
    Size       = { boxW, boxH },
    Font       = "Roboto",
    FontSize   = 14,
    HTextAlign = "Center",
    Color      = { 0, 0, 0, 0 },
    TextColor  = { 255, 255, 255 },
  }

  layout["Auth.Status"] = {
    Style       = "Text",
    Position    = { connectX, rowY + rowGap * 2 },
    Size        = { btnW, boxH },
    Font        = "Roboto",
    FontSize    = 11,
    TextColor   = { 255, 255, 255 },
    StrokeWidth = 0,
    Color       = { 0, 0, 0, 0 },
    HTextAlign  = "Center",
    VTextAlign  = "Center",
    IsReadOnly  = true,
    Legend      = "Auth.Status",
  }
end

--------------------------------------------------------------------------------
-- Groups and Trunks settings page (Araneo-inspired, sectioned)
--
-- Sections, top to bottom:
--   • Predefined Groups   — 5×4 grid (ids 1..20)
--   • Custom Groups       — row of state.groupList entries with predefined=false
--   • Predefined Trunks   — row of state.trunkList entries with predefined=true
--   • Custom Trunks       — row of state.trunkList entries with predefined=false
--
-- Each card renders via a group_label_N / trunk_label_N text control. The card
-- fill color comes from state.customColors (live API), falling back to the
-- hardcoded GROUP_COLORS palette so a pre-connect view still renders something.
-- Trunk cards get a "◤" overlay in the top-left corner to visually match the
-- chassis-view trunk indicator.
--------------------------------------------------------------------------------
local function buildGroupTrunkSettingsPage(layout, gfx, props)
  local theme = getThemeColors()

  local model = resolveModel(props)
  local pageW, pageH = pageWidthForModel(model), pageHeightForModel(model)

  gfx[#gfx+1] = {
    Type        = "Groupbox",
    Fill        = theme.groupboxFill,
    StrokeColor = GROUPBOX_STROKE_COLOR,
    StrokeWidth = GROUPBOX_STROKE_WIDTH,
    Position    = GROUPBOX_POSITION,
    Size        = { pageW, pageH },
  }

  defineCommonDeviceInfo(layout, gfx, theme, 0, 0)

  -- Compact 4-section layout (left→right): Predefined Groups | Custom
  -- Groups | Predefined Trunks | Custom Trunks. Each section is a vertical
  -- list of small cards that fits within the page's content height.
  local marginX = GT_MARGIN_X
  local topY    = GT_TOP_Y
  local cardW   = GT_CARD_W
  local cardH   = GT_CARD_H
  local labelH  = GT_LABEL_H

  state.groupList    = state.groupList    or {}
  state.trunkList    = state.trunkList    or {}
  state.customColors = state.customColors or {}
  state.groupNames   = state.groupNames   or {}

  local function sectionLabel(x, y, text, widthPx)
    gfx[#gfx+1] = {
      Type       = "Text",
      Text       = text,
      Position   = { x, y },
      Size       = { widthPx, labelH },
      Font       = "Roboto",
      FontSize   = 11,
      Color      = theme.textMuted,
      HTextAlign = "Left",
      VTextAlign = "Center",
      IsBold     = true,
    }
    gfx[#gfx+1] = {
      Type        = "Rectangle",
      Position    = { x, y + labelH + 1 },
      Size        = { widthPx, 1 },
      Fill        = theme.cardStroke,
      StrokeWidth = 0,
    }
  end

  -- placeholder = reserved custom slot: invisible until the runtime fills it
  -- (refreshCustomSlots in info.lua).
  local function placeCard(kind, slot, name, keyForColor, x, y, isTrunk, placeholder)
    local labelName = (kind == "group") and ("group_label_" .. slot) or ("trunk_label_" .. slot)
    local badgeName = (kind == "group") and ("group_id_badge_" .. slot) or ("trunk_id_badge_" .. slot)
    layout[labelName] = {
      Style        = "Text",
      Position     = { x, y },
      Size         = { cardW, cardH },
      IsReadOnly   = true,
      FontSize     = 10,
      Font         = "Roboto",
      Color        = { 0, 0, 0, 0 },   -- transparent offline; runtime paints the group color
      TextColor    = { 255, 255, 255 },
      StrokeWidth  = 0,
      CornerRadius = 3,
      HTextAlign   = "Center",
      VTextAlign   = "Center",
      String       = name or "",
    }
    layout[badgeName] = {
      Style        = "Text",
      Position     = { x + cardW - 14, y + 2 },
      Size         = { 12, 9 },
      FontSize     = 7,
      Font         = "Roboto",
      TextColor    = { 255, 255, 255 },
      Color        = { 0, 0, 0, 0 },   -- transparent offline; runtime paints it
      CornerRadius = 2,
      StrokeWidth  = 0,
      IsReadOnly   = true,
      HTextAlign   = "Center",
      VTextAlign   = "Center",
      String       = placeholder and "" or tostring(slot),
    }
  end

  -- Fixed sections (walkGroupTrunkSections): groups 1..20 and the ISL
  -- trunk always exist; custom groups/trunks only exist on the switch, so
  -- the layout reserves invisible slots (group_label_21.., trunk_label_2..)
  -- that the runtime fills in id order.
  walkGroupTrunkSections(model, marginX, topY, topY + labelH + 6,
    function(_si, title, x, y, w) sectionLabel(x, y, title, w) end,
    function(kind, item, x, y)
      placeCard(kind, item.slot, item.name, item.key, x, y, kind == "trunk", item.placeholder)
    end)
end

--------------------------------------------------------------------------------
-- Page dispatcher — model-named page falls through to buildControlsPage
--------------------------------------------------------------------------------
local pageBuilders = {
  ["Port settings"] = function(layout, gfx, props) buildPortSettingsPage(layout, gfx, props) end,
  ["Configuration"] = buildConfigurationPage,
  ["Groups and Trunks"] = buildGroupTrunkSettingsPage,
}

setmetatable(pageBuilders, {
  __index = function(_, _key)
    return function(layout, gfx, props)
      buildControlsPage(layout, gfx, resolveModel(props))
    end
  end,
})

--------------------------------------------------------------------------------
-- GetControlLayout body
--------------------------------------------------------------------------------
local pages = GetPages(props)
local idx = props["page_index"] and props["page_index"].Value or 1
local pageObj = pages[idx]
local pageName = pageObj and pageObj.name or modelString

local layout = {}
local gfx = {}

local builder = pageBuilders[pageName]
if builder then
  builder(layout, gfx, props)
end

-- Q-SYS trees the Control Pins panel on the `PrettyName` of each layout
-- entry using "~" as the delimiter. Our control Names already carry the
-- category with "." (e.g. "PoE.Toggle 1"), so we just swap "." → "~" and
-- assign as PrettyName. Keeps Name unchanged (stable pin ID) while the
-- display in Q-SYS Designer nests into folders: PoE > Toggle 1, etc.
--
-- Designer's hover tooltip shows the PrettyName. Controls that expose no pin
-- get an empty PrettyName, which shrinks the tooltip to an empty bubble (it
-- cannot be removed from plugin code). Pinned controls keep the "~" tree name.
local noPin = {}
for _, ctl in ipairs(GetControls(props)) do
  if ctl.UserPin == false and (ctl.PinStyle == nil or ctl.PinStyle == "None") then
    noPin[ctl.Name] = true
  end
end
for key, entry in pairs(layout) do
  if type(key) == "string" and type(entry) == "table" and entry.PrettyName == nil then
    if noPin[key] then
      entry.PrettyName = ""
    else
      local pretty = key:gsub("%.", "~")
      if pretty ~= key then entry.PrettyName = pretty end
    end
  end
end

return layout, gfx

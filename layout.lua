-- Dark mode from property
local darkProp = props["Dark Mode"]
local darkModeValue = (type(darkProp) == "table") and darkProp.Value or darkProp
state.darkMode = (darkModeValue == "Yes")

local modelString    = resolveModel(props)
local portCount      = getPortCount(modelString)
state.portCount      = portCount
state.selectedModel  = modelString  -- so runtime (no Properties access) can warn on mismatch

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
  local row1Y, row2Y = 3, 25
  local rowH = 20
  local x0 = 10

  local statusW = 60
  local nameW   = 220
  local infoW   = 220   -- IP+Subnet / MAC width (3rd column)
  local gap     = 10
  local col2X = x0 + statusW + gap
  local col3X = col2X + nameW + gap

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
    Color        = theme.indicatorFill,
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
    Color        = theme.indicatorFill,
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
    Color        = theme.indicatorFill,
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
    Color        = theme.indicatorFill,
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
    Color        = theme.indicatorFill,
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
  -- SVG sits just below the two-row header (header ends y~45).
  local svgX, svgY = 20, 50
  local svgW       = 960
  local svgH       = math.floor(vbH * svgW / vbW + 0.5)
  local sx         = svgW / vbW
  local sy         = svgH / vbH
  local svgBottomY = svgY + svgH

  -- Per-port settings grid below the chassis.
  local gridY     = svgBottomY + 18
  local rows      = 8
  local portCount = #coords.ports
  local cols      = math.ceil(portCount / rows)
  local rowH      = 22
  local gridH     = rows * rowH
  local pageH     = 365  -- standardized across all pages

  gfx[#gfx+1] = {
    Type        = "Groupbox",
    Fill        = theme.groupboxFill,
    StrokeColor = GROUPBOX_STROKE_COLOR,
    StrokeWidth = GROUPBOX_STROKE_WIDTH,
    Position    = GROUPBOX_POSITION,
    Size        = { 1250, pageH },
  }

  defineCommonDeviceInfo(layout, gfx, theme, 0, 0)

  -- Chassis SVG backdrop
  gfx[#gfx+1] = {
    Type     = "Svg",
    Image    = svgImg,
    Position = { svgX, svgY },
    Size     = { svgW, svgH },
  }

  -- Cover the chassis's embedded model text (positioned top-left inside the
  -- chassis on all SVGs, roughly SVG y=5..30) with a page-bg rectangle that
  -- spans the full chassis interior height. The Luminex logo sits on top,
  -- vertically centered inside the chassis.
  local logoH = 28
  local logoW = math.floor(logoH * 3.3 + 0.5)
  local badgeInset = 2
  local badgeW = logoW + 24
  local badgeSvgYTop, badgeSvgYBot = 2, vbH - 2  -- cover interior, stay inside stroke
  local badgeX = svgX + badgeInset
  local badgeY = svgY + badgeSvgYTop * sy
  local badgeH = (badgeSvgYBot - badgeSvgYTop) * sy
  gfx[#gfx+1] = {
    Type        = "Rectangle",
    Position    = { badgeX, badgeY },
    Size        = { badgeW, badgeH },
    Fill        = theme.pageBg,
    StrokeWidth = 0,
  }
  gfx[#gfx+1] = {
    Type     = "Svg",
    Image    = LogoLuminex,
    Position = { badgeX + (badgeW - logoW) / 2, badgeY + (badgeH - logoH) / 2 },
    Size     = { logoW, logoH },
  }

  -- Invisible button covering the logo area — click triggers /api/identify.
  layout["Device.Identify"] = {
    Style             = "Button",
    ButtonStyle       = "Momentary",
    ButtonVisualStyle = "Flat",
    Position          = { badgeX, badgeY },
    Size              = { badgeW, badgeH },
    Color             = { 0, 0, 0, 0 },
    OffColor          = { 0, 0, 0, 0 },
    StrokeColor       = { 0, 0, 0, 0 },
    StrokeWidth       = 0,
    Legend            = "",
  }

  -- Per-port interactive overlays
  for _, p in ipairs(coords.ports) do
    local rect = svgToScreen(p, svgX, svgY, svgW, svgH, vbW, vbH)
    -- Grow each button by 1px each side so it hugs the SVG port outline
    -- without pushing past the rlinkx / cable-clip indicators.
    local bx = rect.x - 1
    local by = rect.y - 1
    local bw = rect.w + 2
    local bh = rect.h + 2

    -- Group-color halo behind the port. Halo top/bottom are anchored to
    -- chassis-relative y values (not port-relative) so all halos in a row
    -- are the same height and aligned regardless of port kind (RJ45/SFP).
    local isTopRow = (p.y < vbH / 2)
    local bgPadX = 3
    local edgeGapSvg  = 2    -- gap between halo outer edge and chassis edge
    local innerGapSvg = 0.5  -- gap between top-row halo and bottom-row halo
    local rowMidSvg = vbH / 2
    local haloTopSvg, haloBotSvg
    if isTopRow then
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
    layout["Port.Link " .. p.port] = {
      Style             = "Button",
      ButtonStyle       = "Toggle",
      ButtonVisualStyle = "Flat",
      Position          = { bx, by },
      Size              = { bw, bh },
      IsReadOnly        = true,
      Color             = LINK_ON,
      OffColor          = LINK_OFF,
      StrokeColor       = { 0, 0, 0, 0 },
      StrokeWidth       = 0,
      CornerRadius      = (p.kind == "ethercon") and math.floor(bw / 2) or 2,
    }

    -- PoE pip — positioned on the SVG's cable-clip rect (above top-row
    -- ports, below bottom-row ports). Only RJ45/ethercon ports with PoE
    -- support have p.poe coordinates; SFP ports get a hidden off-chassis
    -- placement so the Button exists but isn't visible.
    local pipPos, pipSize
    if p.poe then
      local pipScreen = svgToScreen(p.poe, svgX, svgY, svgW, svgH, vbW, vbH)
      pipPos  = { pipScreen.x, pipScreen.y }
      pipSize = { pipScreen.w, pipScreen.h }
    else
      pipPos  = { -100, -100 }
      pipSize = { 1, 1 }
    end
    layout["Port.PoE Color " .. p.port] = {
      Style             = "Button",
      ButtonStyle       = "Toggle",
      ButtonVisualStyle = "Flat",
      Position          = pipPos,
      Size              = pipSize,
      IsReadOnly        = true,
      Color             = { 0, 0, 0, 0 },
      OffColor          = { 0, 0, 0, 0 },
      StrokeColor       = { 0, 0, 0, 0 },
      StrokeWidth       = 0,
      CornerRadius      = 1,
    }

    -- Port number — layout Text sorted last alphabetically so it renders on
    -- top of halo + Port.Link. String value is set at runtime (layout-time
    -- "String" isn't reliably applied, so renderPortUI writes it).
    layout["Port.z Num " .. p.port] = {
      Style       = "Text",
      Position    = { bx, by },
      Size        = { bw, bh },
      Font        = "Roboto",
      FontSize    = 11,
      IsReadOnly  = true,
      Color       = { 0, 0, 0, 0 },
      TextColor   = { 220, 230, 250, 255 },
      StrokeWidth = 0,
      StrokeColor = { 0, 0, 0, 0 },
      HTextAlign  = "Center",
      VTextAlign  = "Center",
      IsBold      = true,
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

    -- Trunk badge — top-left corner
    layout["Port.Trunk Badge " .. p.port] = {
      Style       = "Text",
      Position    = { bx - 2, by - 4 },
      Size        = { 12, 12 },
      Font        = "Roboto",
      FontSize    = 14,
      IsReadOnly  = true,
      Color       = { 0, 0, 0, 0 },
      TextColor   = theme.trunkBadge,
      StrokeWidth = 0,
      HTextAlign  = "Left",
      VTextAlign  = "Top",
      IsBold      = true,
    }

    -- Multicast-router badge — top-right of port, hidden by default.
    -- Layout uses transparent stroke so the border doesn't appear on every
    -- port; runtime SetMrPorts paints Color, OffColor, StrokeColor and
    -- Legend ("MR") only for ports in the IGMP snooping router list.
    -- Named "Port.zMR " so it sorts after Port.PoE Color → renders on top.
    local mrSize = 14
    layout["Port.zMR " .. p.port] = {
      Style             = "Button",
      ButtonStyle       = "Toggle",
      ButtonVisualStyle = "Flat",
      Position          = { bx + bw - mrSize - 1, by + 1 },
      Size              = { mrSize, mrSize },
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
  local legendW    = 56
  local rlinkxW    = 20
  local poeToggleW = 20
  local poeBounceW = 20
  local groupW     = 78
  local speedW     = 84
  local colPad     = 4
  local colW       = labelW + enableW + legendW + rlinkxW + poeToggleW + poeBounceW + groupW + speedW
  local cellH      = 18
  local xStart     = 12
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
      ButtonStyle       = "Toggle",
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
      IsReadOnly        = true,
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

local function buildControlsPage(layout, gfx, model)
  local theme  = getThemeColors()
  local svg    = getChassisSvg(model)
  local coords = getPortCoords(model)
  if svg and coords then
    buildSvgOverlayPage(layout, gfx, model, theme, svg, coords)
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
  local totalW = 1250
  local totalH = 365

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

  local pageW, pageH = 1250, 365

  gfx[#gfx+1] = {
    Type        = "Groupbox",
    Fill        = theme.groupboxFill,
    StrokeColor = GROUPBOX_STROKE_COLOR,
    StrokeWidth = GROUPBOX_STROKE_WIDTH,
    Position    = GROUPBOX_POSITION,
    Size        = { pageW, pageH },
  }

  defineCommonDeviceInfo(layout, gfx, theme, 0, 0)

  local marginX  = 16
  local cardW    = 110
  local cardH    = 38
  local gapX     = 8
  local gapY     = 6
  local sectionGap  = 14
  local labelH   = 16

  state.groupList    = state.groupList    or {}
  state.trunkList    = state.trunkList    or {}
  state.customColors = state.customColors or {}
  state.groupNames   = state.groupNames   or {}

  -- Helper: resolve card color for a given memberOf key (live API first, fallback to predefined palette)
  local function resolveColor(key)
    local rgb = state.customColors[key] or GROUP_COLORS[key]
    if rgb then return string.format("#%02X%02X%02X", rgb[1], rgb[2], rgb[3]) end
    return "#2A3856"
  end

  local function sectionLabel(x, y, text)
    gfx[#gfx+1] = {
      Type       = "Text",
      Text       = text,
      Position   = { x, y },
      Size       = { pageW - marginX * 2, labelH },
      Font       = "Roboto",
      FontSize   = 11,
      Color      = theme.textMuted,
      HTextAlign = "Left",
      VTextAlign = "Center",
      IsBold     = true,
    }
    -- Divider line under section label
    gfx[#gfx+1] = {
      Type        = "Rectangle",
      Position    = { x, y + labelH + 1 },
      Size        = { pageW - marginX * 2, 1 },
      Fill        = theme.cardStroke,
      StrokeWidth = 0,
    }
  end

  -- Helper to place a single card (group or trunk)
  local function placeCard(kind, slot, name, keyForColor, x, y, isTrunk)
    local labelName   = (kind == "group") and ("group_label_" .. slot) or ("trunk_label_" .. slot)
    local badgeName   = (kind == "group") and ("group_id_badge_" .. slot) or ("trunk_id_badge_" .. slot)

    layout[labelName] = {
      Style           = "Text",
      Position        = { x, y },
      Size            = { cardW, cardH },
      IsReadOnly      = true,
      Multiline       = true,
      FontSize        = 12,
      Font            = "Roboto",
      Color           = resolveColor(keyForColor),
      TextColor       = { 255, 255, 255 },
      StrokeWidth     = 0,
      CornerRadius    = 6,
      HTextAlign      = "Center",
      VTextAlign      = "Center",
      String          = name or "",
    }

    -- Trunk indicator overlay (top-left corner triangle) — static gfx glyph
    if isTrunk then
      gfx[#gfx+1] = {
        Type       = "Text",
        Text       = "◤",
        Position   = { x + 1, y - 2 },
        Size       = { 14, 14 },
        Font       = "Roboto",
        FontSize   = 16,
        Color      = theme.trunkBadge,
        HTextAlign = "Left",
        VTextAlign = "Top",
        IsBold     = true,
      }
    end

    -- ID badge in top-right corner of card
    layout[badgeName] = {
      Style        = "Text",
      Position     = { x + cardW - 18, y + 2 },
      Size         = { 16, 11 },
      FontSize     = 8,
      Font         = "Roboto",
      TextColor    = { 255, 255, 255 },
      Color        = { 0, 0, 0, 140 },
      CornerRadius = 2,
      StrokeWidth  = 0,
      IsReadOnly   = true,
      HTextAlign   = "Center",
      VTextAlign   = "Center",
      String       = tostring(slot),
    }
  end

  local cursorY = 55

  ------------------------------------------------------------------------------
  -- Predefined Groups (ids 1..20, 5 per row)
  ------------------------------------------------------------------------------
  sectionLabel(marginX, cursorY, "Predefined Groups")
  cursorY = cursorY + labelH + 6

  local cols = 5
  for i = 1, 20 do
    local col = (i - 1) % cols
    local row = math.floor((i - 1) / cols)
    local x = marginX + col * (cardW + gapX)
    local y = cursorY + row * (cardH + gapY)
    local name = state.groupNames[i] or (i == 1 and "Management" or ("Group " .. string.format("%02d", i)))
    placeCard("group", i, name, "Group: " .. i, x, y, false)
  end
  cursorY = cursorY + 4 * (cardH + gapY) + sectionGap

  ------------------------------------------------------------------------------
  -- Custom Groups
  ------------------------------------------------------------------------------
  sectionLabel(marginX, cursorY, "Custom Groups")
  cursorY = cursorY + labelH + 6

  local customCol = 0
  for _, g in ipairs(state.groupList) do
    if not g.predefined and g.id and g.id > 20 then
      local x = marginX + customCol * (cardW + gapX)
      local y = cursorY
      placeCard("group", g.id, g.name, "Group: " .. g.id, x, y, false)
      customCol = customCol + 1
    end
  end
  cursorY = cursorY + cardH + sectionGap

  ------------------------------------------------------------------------------
  -- Predefined Trunks
  ------------------------------------------------------------------------------
  sectionLabel(marginX, cursorY, "Predefined Trunks")
  cursorY = cursorY + labelH + 6

  local predTrunkCol = 0
  for _, t in ipairs(state.trunkList) do
    if t.predefined and t.id then
      local x = marginX + predTrunkCol * (cardW + gapX)
      local y = cursorY
      placeCard("trunk", t.id, t.name, "Trunk: " .. t.id, x, y, true)
      predTrunkCol = predTrunkCol + 1
    end
  end
  -- Fallback when fetch hasn't run — show ISL placeholder so page isn't empty
  if predTrunkCol == 0 then
    placeCard("trunk", 1, "ISL", "Trunk: 1", marginX, cursorY, true)
  end
  cursorY = cursorY + cardH + sectionGap

  ------------------------------------------------------------------------------
  -- Custom Trunks
  ------------------------------------------------------------------------------
  sectionLabel(marginX, cursorY, "Custom Trunks")
  cursorY = cursorY + labelH + 6

  local custTrunkCol = 0
  for _, t in ipairs(state.trunkList) do
    if not t.predefined and t.id then
      local x = marginX + custTrunkCol * (cardW + gapX)
      local y = cursorY
      placeCard("trunk", t.id, t.name, "Trunk: " .. t.id, x, y, true)
      custTrunkCol = custTrunkCol + 1
    end
  end
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
for key, entry in pairs(layout) do
  if type(key) == "string" and type(entry) == "table" and entry.PrettyName == nil then
    local pretty = key:gsub("%.", "~")
    if pretty ~= key then entry.PrettyName = pretty end
  end
end

return layout, gfx

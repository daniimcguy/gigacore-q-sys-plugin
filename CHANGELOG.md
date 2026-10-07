# Changelog

All notable changes to this project are documented in this file.


---

## [v2.0.0] - 2026-04-22

### ⚠ Breaking changes — pin rename

The control pins now follow the GigaCore API documentation tree. **Existing
Q-SYS designs that wire this plugin's pins will lose those connections and
must be re-wired.**

- **Name = API path.** A pin's name is its API path without `/api`, one
  Control Pins folder per segment: `_` becomes a space, words are
  title-cased, a key merges with its segment, product spelling for acronyms
  (PoE, RLinkX, IP, MAC, CPU, PSU). `/ports/port/7/link_state` is
  `Ports > Port 7 > Link State` (control name `Ports.Port 7.Link State`, the
  name scripts use with `Component.New`).
- **Raw values.** A pin carries the value as the API reports it: enum
  strings (`1gbps fdx`, `sourcing`, `static`), integers as numeric pins
  (°C, rpm, %, mW, bit/s), booleans as toggles. A text value the switch has
  not reported yet is blank.
- **Pins follow the model.** Pins exist only for the selected model's ports,
  PoE ports, fans, PSU slots and case temperature sensor: 169 pins on a 10i,
  466 on a 30i.
- **Every pin is visible.** Pins without a place on a page used to be
  missing from Control Pins; they now all show there.
- **Writes.** Writable fields are Both pins: the switch's live value comes
  out, a value wired or scripted in is sent to the switch. `Link Speed`
  (`Mode` + `Speed`) and `Member Of` (`Type` + `Id`) are each one API
  object: the first write to either half opens a 0.2 s window, then one
  PUT carries both pins' values. Write both halves together (one script,
  back to back): a second write after the window is sent as its own PUT,
  with the other half as it is then. `Link Speed > Speed` is the API list
  joined with `, ` (`all`, `1gbps fdx, 100mbps fdx`). For these two pairs,
  a write the switch rejects, a write while offline or an empty value puts
  the pins back to the switch's values. A rejected write to a single pin
  (`Enabled`, `Legend`...) is logged; the pin shows the switch's value
  again at the next poll (Poll Interval).

Renamed pins (v0.1.1 → v2.0.0, `N` = port number):

| v0.1.1 | v2.0.0 | Value |
|---|---|---|
| `port<N>` | `Ports.Port N.Link State` | text: `1gbps fdx`, `100mbps fdx`, `down`... (was a link-up toggle) |
| `port_enable_toggle_<N>` | `Ports.Port N.Enabled` | toggle, Both (was Input) |
| `port_legend_edit_<N>`, `port_legend_display_<N>` | `Ports.Port N.Legend` | text, Both (was Output) |
| `port_rlinkx_toggle_<N>` | `Ports.Port N.RLinkX.Enabled` | toggle, Both (was Input) |
| `port_speed_dropdown_<N>` | `Ports.Port N.Link Speed.Mode`, `Ports.Port N.Link Speed.Speed` | text, Both: `auto` / `fixed`; API speed list (was a label such as `1 Gbps`) |
| `port_poe_toggle_<N>` | `PoE.Port N.Enabled` | toggle, Both (was Input); stays off without the PoE licence |
| `indication<N>` | `PoE.Port N.Indication` | text: `enabled`, `sourcing`, `disabled`, `error`, or blank |
| `device_name` | `Device.Name` | text |
| `device_description` | `Device.Description` | text |
| `ip_info` | `Device.Actual IP.IP Address`, `Device.Actual IP.Prefix Length`, `IP Settings.Mode` | text, integer, text (was one formatted line) |
| `mac_firmware` | `Device.MAC Address`, `Device.Firmware.Active` | text, blank until the switch reports them (was one line) |
| `identify` | `Identify` | momentary, Input |

Removed pins:

| v0.1.1 | Why, and what to use instead |
|---|---|
| `port_group_color_<N>` | Display color; the membership is `Ports.Port N.Member Of.Type` / `.Id` |
| `poe_color_<N>` | Display color; the state it showed is `PoE.Port N.Indication` |
| `rlinkx_bar_<N>` | Display color; use `Ports.Port N.RLinkX.Enabled` |
| `port_bounce_btn_<N>` | Plugin action, not an API field; the bounce button stays in the port grid. From a wire or script, write `PoE.Port N.Enabled` false, then true |
| `device_status` | Plugin state, not an API field; the Online / Offline badge stays on the page |
| `ip_addr`, `auth_username`, `auth_password`, `auth_status`, `connect` | Connection settings, not API fields; set them on the Configuration page |
| `test_dropdown` | Test control |

New pins:

- Ports: `Ports.Port N.Type` (`rj45` / `sfp`), `Ports.Port N.Member Of.Type`
  (`group` / `trunk` / `none`) and `.Id` (Both), `Ports.Port N.Counters.Rx Bit Rate`,
  `.Tx Bit Rate`, `.Link Flaps` (read from `/api/ports` at connect, 3 s later and
  at every Poll Interval; with Poll Interval Off, at connect and 3 s later only),
  `Port Identify.Port N` (momentary).
- Device: `Device.Model` (raw API model, `GigaCore30i`), `Device.Hostname`,
  `Device.Actual IP.Default Gateway` (raw, `0.0.0.0` when the switch has none).
- System: `System.CPU Load` and `System.CPU Load Long` (the switch's 3 s and
  30 s averages, %), `Temperatures.CPU.Current`, `Temperatures.Case.Current`
  (°C, `-1000` = API error; case sensor on the models that have one),
  `Fans.Fan N.Speed` (rpm).
- Power: `Power.Total Power Usage`, `Power.Total Power Max` (mW),
  `Power.Coupling.Mode` (`shared` / `redundant`), and per PSU slot
  `Power.PSU N.State`, `Power.PSU N.Power Status` (two separate API fields,
  blank for an empty slot) and `Power.PSU N.Power Usage` (mW, `-1` = API
  error).
- `RLinkX.Enabled` (switch-wide RLinkX, read only).

### Visual overhaul
- Main page: dark + light themes, chassis rendering with per-port PoE pip
  (4 states), RLinkX border ring (disabled / enabled / active), top-left trunk
  triangle, group/trunk color fills with live custom colors fetched from
  `/api/groups` and `/api/trunks`.
- Port settings: legend textbox themed (no more black-on-black in dark mode).
  The speed dropdown is replaced by a speed picker panel (click the speed
  cell): the native dropdown list was unreadable in dark mode. The panel only
  offers what the port can do (copper tops out at 1 Gbps, SFP offers 10 Gbps
  only with the 10g licence active); a speed the switch rejects flashes
  "Rejected" on the cell and the API reason goes to the debug log.
- New **PoE Bounce** button next to PoE toggle (disables 3s, re-enables).

### Groups and Trunks tab
- Page renamed "Groups" → "Groups and Trunks" with four sections:
  Predefined Groups (5×4 grid), Custom Groups, Predefined Trunks, Custom
  Trunks. Trunk cards carry the ◤ corner indicator.

---

## [v0.1.1] - 2026-02-20
- Automated GitHub release with versioned `.qplug` asset

---

## [v0.1.0] - 2025-12-18
- Initial public release

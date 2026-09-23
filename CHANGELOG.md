# Changelog

All notable changes to this project are documented in this file.


---

## [v2.0.0] - 2026-04-22

### ⚠ Breaking changes — pin rename

All user pins have been renamed to title-case, space-delimited identifiers so
Q-SYS Designer groups them into a category tree (Port / PoE / RLinkX / Device /
Auth / System / Fan / PSU / RSTP). **Existing Q-SYS designs that wire this
plugin's pins will lose those connections and must be re-wired** — the pin
names no longer match.

Summary of renames (old → new):

| Old                         | New                         |
|-----------------------------|-----------------------------|
| `port<N>`                   | `Port Link <N>`             |
| `port_enable_toggle_<N>`    | `Port Enable <N>`           |
| `port_legend_edit_<N>`      | `Port Legend Edit <N>`      |
| `port_legend_display_<N>`   | `Port Legend <N>`           |
| `port_speed_dropdown_<N>`   | `Port Speed <N>`            |
| `port_rlinkx_toggle_<N>`    | `RLinkX Toggle <N>`         |
| `port_poe_toggle_<N>`       | `PoE Toggle <N>`            |
| `port_poe_bounce_<N>`       | `PoE Bounce <N>`            |
| `indication<N>`             | `PoE Indication <N>`        |
| `device_name`               | `Device Name`               |
| `device_description`        | `Device Description`        |
| `device_status`             | `Device Status`             |
| `ip_info`                   | `Device IP Info`            |
| `mac_firmware`              | `Device MAC Firmware`       |
| `ip_addr`                   | `Auth IP Address`           |
| `auth_username`             | `Auth Username`             |
| `auth_password`             | `Auth Password`             |
| `auth_status`               | `Auth Status`               |
| `connect`                   | `Auth Connect`              |
| `identify`                  | `Auth Identify`             |
| `case_temp`                 | `System Case Temp`          |
| `cpu_temp`                  | `System CPU Temp`           |
| `cpu_load_1s` / `_10s`      | `System CPU Load 1s` / `10s`|
| `fan<N>_speed`              | `Fan <N> Speed`             |
| `psu<N>_status` / `_power`  | `PSU <N> Status` / `Power`  |
| `bridge_priority`           | `RSTP Bridge Priority`      |
| `root_bridge`               | `RSTP Root Bridge`          |

### Pins hidden (no longer exposed — still exist internally for rendering)
- `Port Group Color <N>`, `PoE Color <N>`, `RLinkX Bar <N>`, `Port MR <N>`, `Test Dropdown`

### New pin
- `RLinkX <N>` — Output text: `"disabled"` / `"enabled"` / `"active"`

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
  "Rejected" on the cell and the API reason goes to the debug log. The
  `Port Speed <N>` pin is unchanged and still accepts the same labels.
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

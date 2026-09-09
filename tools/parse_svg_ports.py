"""Parse each chassis SVG and emit a per-model PORT_COORDS Lua table.

Strategy:
  1. Walk the SVG tree, accumulating <g transform="translate(X Y)"> offsets
     and inheriting fill / stroke attributes down into child shapes.
  2. Collect every rect and circle that looks like a port body (stroke-only,
     reasonable size).
  3. Dedupe concentric circles (each ethercon is rendered as two overlapping
     circles in the Araneo SVGs — keep one per position).
  4. Dedupe nested rects (each Araneo port is rendered as an outer solid rect
     and an inset outline rect — keep one per position).
  5. Sort all shapes left-to-right by x with a small tolerance, top-first
     inside each column, and number them sequentially starting from 1.
  6. Infer each port's `kind` (ethercon / rj45 / sfp) from PORT_LAYOUT in
     info.lua — the SVG visuals sometimes conflate sizes.

Usage:  python3 tools/parse_svg_ports.py
Emits:  port_coords.generated.lua (consumed at plugin build time)
"""
import os, re, sys
import xml.etree.ElementTree as ET

HERE = os.path.dirname(os.path.abspath(__file__))
ASSETS = os.path.normpath(os.path.join(HERE, "..", "assets"))

SVG_MAP = [
    ("GigaCore 10i",    "10i - left.svg"),
    ("GigaCore 10t",    "GigaCore 10t.svg"),
    ("GigaCore 10t-IP", "GigaCore 10t-IP.svg"),
    ("GigaCore 16i",    "16i - left.svg"),
    ("GigaCore 16t",    "16t - left.svg"),
    ("GigaCore 16tf",   "GC 16tf.svg"),
    ("GigaCore 18t",    "18 - left.svg"),
    ("GigaCore 20t",    "20t - left.svg"),
    ("GigaCore 30i",    "30i - left.svg"),
    ("GigaCore O26-I",  "GC O26-I v2.svg"),
    ("GigaCore S30-I",  "GC S30-I v1.svg"),
]

# Kind breakdown per model — must match PORT_LAYOUT in info.lua.
PORT_LAYOUT = {
    "GigaCore 10i":    dict(ethercon=0,  rj45=8,  sfp=2),
    "GigaCore 10t":    dict(ethercon=8,  rj45=0,  sfp=2),
    "GigaCore 10t-IP": dict(ethercon=8,  rj45=0,  sfp=2),
    "GigaCore 16i":    dict(ethercon=0,  rj45=12, sfp=4),
    "GigaCore 16t":    dict(ethercon=8,  rj45=8,  sfp=0),
    "GigaCore 16tf":   dict(ethercon=12, rj45=0,  sfp=4),
    "GigaCore 18t":    dict(ethercon=8,  rj45=6,  sfp=2),
    "GigaCore 20t":    dict(ethercon=8,  rj45=8,  sfp=4),
    "GigaCore 30i":    dict(ethercon=0,  rj45=24, sfp=6),
    "GigaCore O26-I":  dict(ethercon=0,  rj45=0,  sfp=26),
    "GigaCore S30-I":  dict(ethercon=0,  rj45=24, sfp=6),
}

NS = "{http://www.w3.org/2000/svg}"


def parse_transform(s):
    dx = dy = 0.0
    if not s:
        return dx, dy
    for m in re.finditer(r"translate\(\s*([-.\d]+)[,\s]+([-.\d]+)\s*\)", s):
        dx += float(m.group(1))
        dy += float(m.group(2))
    return dx, dy


def walk(elem, off_x, off_y, inherited_fill, inherited_stroke, shapes):
    t = elem.attrib.get("transform", "")
    dx, dy = parse_transform(t)
    cx_off = off_x + dx
    cy_off = off_y + dy
    own_fill = elem.attrib.get("fill", inherited_fill)
    own_stroke = elem.attrib.get("stroke", inherited_stroke)
    tag = elem.tag.replace(NS, "")
    if tag == "rect":
        a = elem.attrib
        x = float(a.get("x", 0)) + cx_off
        y = float(a.get("y", 0)) + cy_off
        w = float(a["width"])
        h = float(a["height"])
        shapes.append(dict(
            kind="rect", x=x, y=y, w=w, h=h,
            fill=own_fill, stroke=own_stroke,
        ))
    elif tag == "circle":
        a = elem.attrib
        cx = float(a.get("cx", 0)) + cx_off
        cy = float(a.get("cy", 0)) + cy_off
        r = float(a["r"])
        shapes.append(dict(
            kind="circle", cx=cx, cy=cy, r=r,
            fill=own_fill, stroke=own_stroke,
        ))
    for child in elem:
        walk(child, cx_off, cy_off, own_fill, own_stroke, shapes)


def collect_cable_clips(shapes):
    """Return solid-filled white rectangles (cable-clip / PoE indicator
    glyphs). Size is ~5x5 in SVG units on every chassis we've looked at.
    Returned as list of {x, y, w, h}."""
    clips = []
    for s in shapes:
        if s["kind"] != "rect":
            continue
        if s.get("fill") not in ("#fff", "white", "#ffffff", "#FFFFFF"):
            continue
        # cable clip is a filled square roughly 5x5. Reject tiny dots and
        # anything large (chassis internal panels).
        if not (3 < s["w"] < 8 and 3 < s["h"] < 8):
            continue
        clips.append(dict(x=s["x"], y=s["y"], w=s["w"], h=s["h"]))
    return clips


def attach_cable_clips(ports, clips, vb_h, tol=3.0):
    """Assign the closest cable clip (by x-center) to each port, matching the
    clip that's on the correct side of the port (above for top-row, below
    for bottom-row). Mutates ports in place adding a 'poe' dict when found."""
    mid_y = vb_h / 2
    for p in ports:
        pcx = p["x"] + p["w"] / 2
        pcy = p["y"] + p["h"] / 2
        is_top_row = pcy < mid_y
        best = None
        best_dist = None
        for c in clips:
            ccx = c["x"] + c["w"] / 2
            ccy = c["y"] + c["h"] / 2
            dx = abs(ccx - pcx)
            if dx > tol:
                continue
            if is_top_row:
                if ccy >= p["y"]:
                    continue  # need clip strictly above port
            else:
                if ccy <= p["y"] + p["h"]:
                    continue  # need clip strictly below port
            if best is None or dx < best_dist:
                best = c
                best_dist = dx
        if best is not None:
            p["poe"] = dict(x=best["x"], y=best["y"], w=best["w"], h=best["h"])


def collect_port_slots(shapes, vb_w, vb_h):
    """Return deduped list of port shapes (each as {kind, x, y, w, h} in SVG
    space). Ethercon circles become squares by bounding box."""
    # Accept only stroke-only shapes (fill="none"/None and stroke="#fff")
    def is_port_like(s):
        if s.get("stroke") not in ("#fff", "white", "#ffffff", "#FFFFFF"):
            return False
        fill = s.get("fill")
        if fill not in (None, "none"):
            return False
        return True

    circles = []
    for s in shapes:
        if s["kind"] != "circle":
            continue
        if not is_port_like(s):
            continue
        if not (6 < s["r"] < 10):
            continue
        # Skip if too near the chassis edges (likely not a port)
        circles.append(s)

    rects = []
    for s in shapes:
        if s["kind"] != "rect":
            continue
        if not is_port_like(s):
            continue
        # Reject giant outline rect
        if s["w"] > vb_w * 0.8:
            continue
        # Minimum port size filter
        if s["w"] < 5 or s["h"] < 4:
            continue
        rects.append(s)

    # Dedupe concentric circles (ethercons drawn as two overlapping circles
    # in the Araneo source — prefer the r~=8 one).
    uniq_circ = {}
    for c in circles:
        key = (round(c["cx"], 0), round(c["cy"], 0))
        if key not in uniq_circ or abs(c["r"] - 8) < abs(uniq_circ[key]["r"] - 8):
            uniq_circ[key] = c
    circles = list(uniq_circ.values())

    # Dedupe nested rects. Each port has an outer solid rect and an inner
    # stroked rect. They overlap nearly perfectly — keep the larger one per
    # centre position.
    uniq_rect = {}
    for r in rects:
        cx = r["x"] + r["w"] / 2
        cy = r["y"] + r["h"] / 2
        key = (round(cx, 0), round(cy, 0))
        keep = uniq_rect.get(key)
        if keep is None or (r["w"] * r["h"]) > (keep["w"] * keep["h"]):
            uniq_rect[key] = r
    rects = list(uniq_rect.values())

    # Express everything as {kind, x, y, w, h} in SVG space
    slots = []
    for c in circles:
        d = c["r"] * 2
        slots.append(dict(
            src="circle",
            x=c["cx"] - c["r"], y=c["cy"] - c["r"],
            w=d, h=d,
        ))
    for r in rects:
        slots.append(dict(
            src="rect", x=r["x"], y=r["y"], w=r["w"], h=r["h"],
        ))
    return slots


def assign_port_order(slots):
    """Return slots in port-number order: columns left-to-right, inside each
    column top-first."""
    items = sorted(slots, key=lambda s: s["x"])
    cols = []
    for s in items:
        if cols and abs(s["x"] - cols[-1][0]["x"]) < 4:
            cols[-1].append(s)
        else:
            cols.append([s])
    for c in cols:
        c.sort(key=lambda s: s["y"])
    ordered = []
    for c in cols:
        ordered.extend(c)
    return ordered


def apply_kinds(slots, model):
    """Assign port numbers and kinds from PORT_LAYOUT counts."""
    breakdown = PORT_LAYOUT.get(model, {})
    ether_n = breakdown.get("ethercon", 0)
    rj45_n  = breakdown.get("rj45", 0)
    sfp_n   = breakdown.get("sfp", 0)
    ordered = []
    for i, s in enumerate(slots, start=1):
        if i <= ether_n:
            kind = "ethercon"
        elif i <= ether_n + rj45_n:
            kind = "rj45"
        else:
            kind = "sfp"
        ordered.append(dict(port=i, kind=kind, x=s["x"], y=s["y"], w=s["w"], h=s["h"]))
    return ordered


def parse_model(model, fname):
    tree = ET.parse(os.path.join(ASSETS, fname))
    root = tree.getroot()
    vb = root.attrib.get("viewBox", "0 0 0 0").split()
    vb_w, vb_h = float(vb[2]), float(vb[3])
    shapes = []
    walk(root, 0.0, 0.0, None, None, shapes)
    slots = collect_port_slots(shapes, vb_w, vb_h)
    ordered = assign_port_order(slots)
    ports = apply_kinds(ordered, model)
    clips = collect_cable_clips(shapes)
    attach_cable_clips(ports, clips, vb_h)
    return vb_w, vb_h, ports


def emit_lua(path):
    with open(path, "w", encoding="utf-8") as out:
        out.write("-- Auto-generated from SVGs by tools/parse_svg_ports.py\n")
        out.write("-- Port coordinates are in SVG viewBox space.\n")
        out.write("PORT_COORDS = PORT_COORDS or {}\n\n")
        total = 0
        for model, fn in SVG_MAP:
            try:
                vw, vh, ports = parse_model(model, fn)
            except Exception as e:
                print(f"  WARN {model}: {e}", file=sys.stderr)
                continue
            out.write(f'PORT_COORDS["{model}"] = {{\n')
            out.write(f'  viewBox = {{ w = {vw}, h = {vh} }},\n')
            out.write('  ports   = {\n')
            for p in ports:
                poe = ""
                if "poe" in p:
                    poe_d = p["poe"]
                    poe = f', poe = {{ x = {poe_d["x"]:.3f}, y = {poe_d["y"]:.3f}, w = {poe_d["w"]:.3f}, h = {poe_d["h"]:.3f} }}'
                out.write(f'    {{ port = {p["port"]}, x = {p["x"]:.3f}, y = {p["y"]:.3f}, w = {p["w"]:.3f}, h = {p["h"]:.3f}, kind = "{p["kind"]}"{poe} }},\n')
            out.write('  },\n}\n\n')
            counts = {}
            for p in ports:
                counts[p["kind"]] = counts.get(p["kind"], 0) + 1
            summary = " + ".join(f"{v} {k}" for k, v in counts.items())
            print(f"  {model:20s}  viewBox {vw:6.1f}x{vh:5.1f}  ports: {summary or '(none)'} (total {len(ports)})")
            total += len(ports)
        print(f"\nTotal ports across all models: {total}")


if __name__ == "__main__":
    out_path = os.path.normpath(os.path.join(HERE, "..", "port_coords.generated.lua"))
    emit_lua(out_path)
    print(f"Wrote {out_path}")

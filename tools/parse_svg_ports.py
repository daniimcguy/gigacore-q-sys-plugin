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
import os, re, sys, base64
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
    "GigaCore 18t":    dict(ethercon=8,  rj45=8,  sfp=2),
    "GigaCore 20t":    dict(ethercon=8,  rj45=8,  sfp=4),
    "GigaCore 30i":    dict(ethercon=0,  rj45=24, sfp=6),
    "GigaCore O26-I":  dict(ethercon=0,  rj45=0,  sfp=26),
    "GigaCore S30-I":  dict(ethercon=0,  rj45=24, sfp=6),
}

NS = "{http://www.w3.org/2000/svg}"


IDENTITY = (1.0, 1.0, 0.0, 0.0)


def compose(parent, child):
    """Compose two (sx, sy, tx, ty) transforms (diagonal-scale + translate
    only, sufficient for the rotate(180)-or-no-rotation transforms used by
    these chassis SVGs). result(P) = parent(child(P))."""
    psx, psy, ptx, pty = parent
    csx, csy, ctx, cty = child
    return (psx * csx, psy * csy,
            psx * ctx + ptx, psy * cty + pty)


def parse_transform(s):
    """Parse a SVG transform attribute into a (sx, sy, tx, ty) tuple.
    Handles translate(tx [ty]) and rotate(180); ignores other rotations."""
    M = IDENTITY
    if not s:
        return M
    for name, args in re.findall(r"(translate|rotate)\(([^)]*)\)", s):
        if name == "translate":
            parts = re.split(r"[,\s]+", args.strip())
            dx = float(parts[0])
            dy = float(parts[1]) if len(parts) > 1 else 0.0
            step = (1.0, 1.0, dx, dy)
        else:  # rotate
            angle = float(args.split(",")[0].strip())
            if abs(abs(angle) - 180) < 0.001:
                step = (-1.0, -1.0, 0.0, 0.0)
            else:
                step = IDENTITY
        M = compose(M, step)
    return M


def walk(elem, M_parent, inherited_fill, inherited_stroke, shapes):
    M_local = parse_transform(elem.attrib.get("transform", ""))
    M = compose(M_parent, M_local)
    sx, sy, tx, ty = M
    own_fill = elem.attrib.get("fill", inherited_fill)
    own_stroke = elem.attrib.get("stroke", inherited_stroke)
    tag = elem.tag.replace(NS, "")
    if tag == "rect":
        a = elem.attrib
        x_local = float(a.get("x", 0))
        y_local = float(a.get("y", 0))
        w_local = float(a["width"])
        h_local = float(a["height"])
        # Apply transform to both corners; rotate(180) flips both signs so
        # we normalize to positive width/height after.
        x1 = sx * x_local + tx
        y1 = sy * y_local + ty
        x2 = sx * (x_local + w_local) + tx
        y2 = sy * (y_local + h_local) + ty
        x_min, x_max = (x1, x2) if x1 <= x2 else (x2, x1)
        y_min, y_max = (y1, y2) if y1 <= y2 else (y2, y1)
        shapes.append(dict(
            kind="rect", x=x_min, y=y_min, w=x_max - x_min, h=y_max - y_min,
            fill=own_fill, stroke=own_stroke,
        ))
    elif tag == "circle":
        a = elem.attrib
        cx_local = float(a.get("cx", 0))
        cy_local = float(a.get("cy", 0))
        r = float(a["r"])  # uniform-scale or rotation-only — radius preserved
        shapes.append(dict(
            kind="circle",
            cx=sx * cx_local + tx,
            cy=sy * cy_local + ty,
            r=r,
            fill=own_fill, stroke=own_stroke,
        ))
    for child in elem:
        walk(child, M, own_fill, own_stroke, shapes)


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
    """Assign the closest cable clip (by x-center) to each port. The clip
    must be on the correct side of the port's vertical center: above the
    port-center for top-row ports, below for bottom-row ports. (Many clips
    overlap the port's top/bottom edge, so we can't require the clip to be
    fully outside the port.) Mutates ports in place adding 'poe' dict."""
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
            # Allow clips overlapping the port edge: only require their
            # center to be on the correct side of the port's center.
            if is_top_row and ccy >= pcy:
                continue
            if (not is_top_row) and ccy <= pcy:
                continue
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

    # Drop decorative ellipses that sit inside (or nearly coincident with) a
    # port rect. On t-models each SFP has both a rect (the cage) and an
    # ellipse drawn behind it; without this filter we'd double-count.
    def circle_overlaps_rect(c, r, pad=2):
        cx, cy = c["cx"], c["cy"]
        return (r["x"] - pad <= cx <= r["x"] + r["w"] + pad
                and r["y"] - pad <= cy <= r["y"] + r["h"] + pad)
    real_circles = []
    for c in circles:
        decorative = any(circle_overlaps_rect(c, r) for r in rects)
        if not decorative:
            real_circles.append(c)
    circles = real_circles

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


def uniform_sizes(ports):
    """Give every port of a kind the same width/height (the median), keeping
    each port's centre. The Araneo artwork has sub-unit size jitter between
    ports that turns into 1px differences on screen."""
    by_kind = {}
    for p in ports:
        by_kind.setdefault(p["kind"], []).append(p)
    for kind, group in by_kind.items():
        ws = sorted(p["w"] for p in group)
        hs = sorted(p["h"] for p in group)
        w = ws[len(ws) // 2]
        h = hs[len(hs) // 2]
        for p in group:
            cx = p["x"] + p["w"] / 2
            cy = p["y"] + p["h"] / 2
            p["x"], p["y"], p["w"], p["h"] = cx - w / 2, cy - h / 2, w, h
    # Same y for every port of a kind in the same row (top / bottom).
    if not ports:
        return
    mid = max(p["y"] + p["h"] / 2 for p in ports) / 2 + min(p["y"] + p["h"] / 2 for p in ports) / 2
    by_row = {}
    for p in ports:
        row = "top" if (p["y"] + p["h"] / 2) < mid else "bottom"
        by_row.setdefault((p["kind"], row), []).append(p)
    for group in by_row.values():
        ys = sorted(p["y"] for p in group)
        y = ys[len(ys) // 2]
        for p in group:
            p["y"] = y


def force_all_ethercon(ports):
    """Force every port to kind="ethercon" with consistent 17x17 dimensions.
    Used for models whose real hardware is all ethercon but whose SVG shows
    some ports as SFP-shaped slots."""
    for p in ports:
        p["kind"] = "ethercon"
        if p["w"] < 13:
            cx = p["x"] + p["w"] / 2
            cy = p["y"] + p["h"] / 2
            p["x"] = cx - 8.5
            p["y"] = cy - 8.5
            p["w"] = 17.0
            p["h"] = 17.0


def renumber_by_x(ports, desired_order):
    """Assign port numbers left-to-right per desired_order."""
    sorted_by_x = sorted(ports, key=lambda p: p["x"])
    if len(sorted_by_x) != len(desired_order):
        return
    for i, p in enumerate(sorted_by_x):
        p["port"] = desired_order[i]
    ports.sort(key=lambda p: p["port"])


ALL_ETHERCON_MODELS = {"GigaCore 10t", "GigaCore 10t-IP", "GigaCore 16tf"}

# SVG units kept left of port 1 after cropping (room for the group halo).
CROP_MARGIN = 6.0

PORT_ORDER_BY_X = {
    "GigaCore 10t":    [1, 2, 3, 4, 9, 10, 5, 6, 7, 8],
    # 10t-IP: ports 9-10 sit on the rear panel; the chassis SVG follows
    # Araneo's project mode (1-8 left, 9-10 right), so x order is port order.
}


def parse_model(model, fname):
    tree = ET.parse(os.path.join(ASSETS, fname))
    root = tree.getroot()
    vb = root.attrib.get("viewBox", "0 0 0 0").split()
    vb_w, vb_h = float(vb[2]), float(vb[3])
    shapes = []
    walk(root, IDENTITY, None, None, shapes)
    slots = collect_port_slots(shapes, vb_w, vb_h)
    ordered = assign_port_order(slots)
    ports = apply_kinds(ordered, model)
    clips = collect_cable_clips(shapes)
    attach_cable_clips(ports, clips, vb_h)
    if model in ALL_ETHERCON_MODELS:
        force_all_ethercon(ports)
    uniform_sizes(ports)
    if model in PORT_ORDER_BY_X:
        renumber_by_x(ports, PORT_ORDER_BY_X[model])
    # Crop the artwork left of port 1: that area only holds the model text
    # in the Araneo assets, and the plugin draws its own device display
    # block there instead. The chassis outline's left edge is cut away on
    # purpose (the display block closes the frame).
    crop = max(0.0, min(p["x"] for p in ports) - CROP_MARGIN)
    for p in ports:
        p["x"] -= crop
        if "poe" in p:
            p["poe"]["x"] -= crop
    svg_src = open(os.path.join(ASSETS, fname), "rb").read().decode("utf-8").replace("\r\n", "\n")
    # Drop the model name: the display block shows it, and Designer lacks
    # its font (HandelGotD), so the wider fallback ran into the crop margin.
    svg_src = re.sub(r"\s*<text\b.*?</text>", "", svg_src, flags=re.S)
    svg_src = re.sub(r'viewBox="[^"]*"', f'viewBox="{crop:.3f} 0 {vb_w - crop:.3f} {vb_h}"', svg_src, count=1)
    svg_src = re.sub(r'\swidth="[^"]*"', "", svg_src, count=1)
    svg_src = re.sub(r'\sheight="[^"]*"', "", svg_src, count=1)
    svg_b64 = base64.b64encode(svg_src.encode("utf-8")).decode("ascii")
    return vb_w - crop, vb_h, ports, svg_b64


def emit_lua(path):
    with open(path, "w", encoding="utf-8") as out:
        out.write("-- Auto-generated from SVGs by tools/parse_svg_ports.py\n")
        out.write("-- Port coordinates are in (cropped) SVG viewBox space; svg = base64 artwork.\n")
        out.write("PORT_COORDS = PORT_COORDS or {}\n\n")
        total = 0
        for model, fn in SVG_MAP:
            try:
                vw, vh, ports, svg_b64 = parse_model(model, fn)
            except Exception as e:
                print(f"  WARN {model}: {e}", file=sys.stderr)
                continue
            out.write(f'PORT_COORDS["{model}"] = {{\n')
            out.write(f'  viewBox = {{ w = {vw:.3f}, h = {vh} }},\n')
            out.write(f'  svg     = "{svg_b64}",\n')
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

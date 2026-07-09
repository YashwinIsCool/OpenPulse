#!/usr/bin/env python3
"""Builds marketing/landing.html from landing.template.html by inlining the
optimized screenshots (in the scratchpad) as base64 data URIs. Keeps the template
editable while the deployed file is fully self-contained (Artifact CSP blocks
external images)."""
import base64
import pathlib

HERE = pathlib.Path(__file__).parent
SCRATCH = pathlib.Path("/private/tmp/claude-503/-Users-Padhu-StethoAI/2aaf3843-9933-40d8-808e-510d58650cb2/scratchpad")

TOKENS = {
    "__IMG_PLAN__": "shot_plan.jpg",
    "__IMG_HOME__": "shot_home.jpg",
    "__IMG_HRRESULT__": "shot_hrresult.jpg",
    "__IMG_TRENDS__": "shot_trends.jpg",
    "__IMG_CHECKIN__": "shot_checkin.jpg",
}

html = (HERE / "landing.template.html").read_text()
for token, filename in TOKENS.items():
    data = (SCRATCH / filename).read_bytes()
    uri = "data:image/jpeg;base64," + base64.b64encode(data).decode()
    html = html.replace(token, uri)

out = HERE / "landing.html"
out.write_text(html)
print(f"wrote {out} ({len(html)/1024:.0f} KB)")

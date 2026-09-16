--[[

  Luminex GigaCore Q-SYS Plugin
  Author: Daniel Minville <daniel.minville@luminexamerica.com>

  To add a new GigaCore model:
    1. Add its name and port count to GigaCoreModels.
       e.g., ["GigaCore 48"] = 48

]]

--------------------------------------------------------------------------------
-- Plugin Constants and Metadata
--------------------------------------------------------------------------------
PluginInfo = {
  Name         = "Luminex~GigaCore",
  Version      = "2.0",
  BuildVersion = "0.0.0.0",
  Id           = "a64f9db0-dcfe-4d58-af32-6f1240343e5c",
  Description  = "Monitoring and control for Luminex GigaCore network switches",
  ShowDebug    = true
}

--------------------------------------------------------------------------------
-- SVG assets (base64 strings — inlined from working backup)
--------------------------------------------------------------------------------
local LogoLuminex = "PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0idXRmLTgiPz4KPCEtLSBHZW5lcmF0b3I6IEFkb2JlIElsbHVzdHJhdG9yIDIwLjEuMCwgU1ZHIEV4cG9ydCBQbHVnLUluIC4gU1ZHIFZlcnNpb246IDYuMDAgQnVpbGQgMCkgIC0tPgo8c3ZnIHZlcnNpb249IjEuMSIgaWQ9IkxheWVyXzEiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIgeG1sbnM6eGxpbms9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkveGxpbmsiIHg9IjBweCIgeT0iMHB4IgoJIHZpZXdCb3g9IjAgMCA0MzkuNiAxMzUuNCIgc3R5bGU9ImVuYWJsZS1iYWNrZ3JvdW5kOm5ldyAwIDAgNDM5LjYgMTM1LjQ7IiB4bWw6c3BhY2U9InByZXNlcnZlIj4KPHN0eWxlIHR5cGU9InRleHQvY3NzIj4KCS5zdDB7ZmlsbDojRkZGRkZGO30KCS5zdDF7ZmlsbDojQ0FENDAwO30KPC9zdHlsZT4KPHBhdGggaWQ9IlhNTElEXzcwNV8iIGNsYXNzPSJzdDAiIGQ9Ik0xMTEuMSw3NC45VjMxLjdoMTUuMXY1NUg5Ni40Yy00LjMsMC03LjctMC4zLTEwLTAuOWMtMi4zLTAuNi00LjQtMS44LTYuMi0zLjUKCWMtMy45LTMuNS01LjgtOS4xLTUuOC0xNi44VjMxLjdoMTUuMXYzNS4zYzAsMi41LDAuNiw0LjQsMS45LDUuOGMxLjMsMS40LDMuMSwyLjEsNS4zLDIuMUgxMTEuMXoiLz4KPHBhdGggaWQ9IlhNTElEXzcwM18iIGNsYXNzPSJzdDAiIGQ9Ik0xMzUuNSwzMS43aDU1LjZjNS4xLDAsOC45LDAuNCwxMS41LDEuMWMyLjYsMC43LDQuOCwyLjEsNi42LDRjMy4zLDMuNiw1LDguNiw1LDE0Ljl2MzVoLTE1LjEKCVY1NC4xYzAtMi42LTAuMS00LjUtMC40LTUuNWMtMC4yLTEtMC44LTItMS42LTIuOGMtMS41LTEuNS0zLjktMi4zLTcuMS0yLjNoLTh2NDMuMmgtMTUuMVY0My41aC0xNi4zdjQzLjJoLTE1LjFWMzEuN3oiLz4KPHBhdGggaWQ9IlhNTElEXzcwMV8iIGNsYXNzPSJzdDAiIGQ9Ik0yNDcuNSwzMS43aDI5LjJjNC4zLDAsNy43LDAuMywxMCwwLjljMi4zLDAuNiw0LjQsMS44LDYuMiwzLjVjMy45LDMuNSw1LjgsOS4xLDUuOCwxNi43djMzLjgKCWgtMTUuMVY1MS4xYzAtMi43LTAuNi00LjctMS44LTUuOWMtMS4yLTEuMi0zLjItMS44LTYtMS44aC0xMy4ydjQzLjJoLTE1LjFWMzEuN3oiLz4KPHBhdGggaWQ9IlhNTElEXzY5OV8iIGNsYXNzPSJzdDAiIGQ9Ik0zNTQuNyw1My4zVjY1aC0zMS45YzAuMywzLjYsMS41LDYuMiwzLjUsNy43YzIsMS41LDUuMywyLjMsOS45LDIuM2gxOC41djExLjdoLTIwLjEKCWMtNC40LDAtNy45LTAuNC0xMC43LTEuMmMtMi43LTAuOC01LjMtMi4xLTcuOC00Yy02LjctNS4xLTEwLTEyLjgtMTAtMjNjMC02LjcsMS44LTEyLjUsNS4zLTE3LjRjMi40LTMuNCw1LjMtNS44LDguNy03LjIKCWMzLjQtMS40LDcuOC0yLjIsMTMuMy0yLjJoMjEuMnYxMS43aC0yMC4xYy00LjEsMC03LDAuNy04LjcsMi4xYy0xLjcsMS40LTIuNyw0LTMuMSw3LjdIMzU0Ljd6Ii8+CjxwYXRoIGlkPSJYTUxJRF82OTdfIiBjbGFzcz0ic3QwIiBkPSJNMzgwLjIsNTkuNWwtMTkuOC0yNy44aDE2LjlMMzg4LjksNDhsMTEuMi0xNi4zaDE3LjhsLTIwLjYsMjcuOGwyMC42LDI3LjJoLTE3LjhMMzg4LjksNzEKCWwtMTEuNiwxNS43aC0xNy44TDM4MC4yLDU5LjV6Ii8+CjxwYXRoIGlkPSJYTUxJRF82OTZfIiBjbGFzcz0ic3QxIiBkPSJNMjM0LjYsMTEuN2MtMC43LTAuMi0xLjctMC4yLTIuOS0wLjJoLTguNnY5YzAsMiwwLjYsMy41LDEuNyw0LjVjMC41LDAuNSwxLjIsMC44LDEuOCwwLjkKCWMwLjcsMC4yLDEuNywwLjIsMi45LDAuMmg4LjZ2LTljMC0yLTAuNi0zLjUtMS43LTQuNUMyMzUuOSwxMi4yLDIzNS4zLDExLjksMjM0LjYsMTEuN3oiLz4KPHBhdGggaWQ9IlhNTElEXzY5NV8iIGNsYXNzPSJzdDAiIGQ9Ik02OS4xLDc0LjRjLTAuNS0wLjQtMS4xLTAuNy0xLjctMC44Yy0wLjYtMC4yLTEuNS0wLjItMi43LTAuMmgtMi4xaC01LjhoLTEuNgoJYy03LDAtMTEuOS0wLjYtMTQuNi0xLjljLTIuOC0xLjMtNC40LTMuNi00LjktN2MtMC4zLTEuOC0wLjUtNS4zLTAuNy0xMC43VjE4LjJoLTE2djM1LjVjMCw3LjQsMC41LDEyLjcsMS4zLDE1LjgKCWMyLjIsOC4xLDcuNSwxMy40LDE1LjgsMTUuOGMzLjYsMSw5LjUsMS40LDE3LjUsMS40aDl2MGMwLjEsMCwwLjEsMCwwLjIsMGg3Ljl2LTguM0M3MC43LDc2LjYsNzAuMiw3NS4yLDY5LjEsNzQuNHoiLz4KPHBhdGggaWQ9IlhNTElEXzY5NF8iIGNsYXNzPSJzdDAiIGQ9Ik0yMjguOSwzMS43Yy0yLjEsMC0zLjYsMC42LTQuNiwxLjdjLTAuNSwwLjUtMC44LDEuMi0xLDEuOGMtMC4yLDAuNy0wLjMsMS43LTAuMywyLjl2MS4xdjcuNgoJdjM5LjloMTUuMVY0MC4zdi0xLjF2LTcuNkgyMjguOXoiLz4KPGc+Cgk8cGF0aCBjbGFzcz0ic3QwIiBkPSJNMTM2LjksMTE4LjR2LTE0LjhoMWw1LjgsOC44YzEuMiwxLjgsMi4xLDMuMiwyLjgsNC43bDAsMGMtMC4yLTItMC4yLTMuNy0wLjItNnYtNy40aDF2MTQuOGgtMWwtNS43LTguNgoJCWMtMS4xLTEuNy0yLjEtMy4zLTIuOS00LjhsMCwwYzAuMSwxLjgsMC4xLDMuNCwwLjEsNS45djcuNUgxMzYuOXoiLz4KCTxwYXRoIGNsYXNzPSJzdDAiIGQ9Ik0xNjEuMSwxMTFoLTUuOXY2LjVoNi42djAuOWgtNy43di0xNC44aDcuM3YwLjloLTYuM3Y1LjdoNS45VjExMXoiLz4KCTxwYXRoIGNsYXNzPSJzdDAiIGQ9Ik0xNzEsMTA0LjRoLTQuOHYtMC45aDEwLjd2MC45aC00Ljh2MTRIMTcxVjEwNC40eiIvPgoJPHBhdGggY2xhc3M9InN0MCIgZD0iTTE4NS4yLDExOC40bC0zLjktMTQuOGgxLjFsMi4yLDguNGMwLjUsMS45LDAuOSwzLjcsMS4yLDUuMWgwYzAuMi0xLjQsMC44LTMuMSwxLjQtNS4xbDIuNC04LjRoMWwyLjIsOC4zCgkJYzAuNSwxLjgsMSwzLjcsMS4yLDUuMWgwYzAuMy0xLjYsMC44LTMuMiwxLjMtNS4xbDIuNC04LjNoMS4xbC00LjQsMTQuOGgtMWwtMi4yLTguNWMtMC42LTIuMi0wLjktMy42LTEuMS01aDAKCQljLTAuMiwxLjQtMC43LDIuOC0xLjMsNWwtMi41LDguNUgxODUuMnoiLz4KCTxwYXRoIGNsYXNzPSJzdDAiIGQ9Ik0yMTYuNCwxMTAuOGMwLDUuMi0zLjIsNy44LTYuNiw3LjhjLTMuNywwLTYuNS0yLjktNi41LTcuNWMwLTQuOSwyLjktNy44LDYuNy03LjgKCQlDMjEzLjcsMTAzLjMsMjE2LjQsMTA2LjIsMjE2LjQsMTEwLjh6IE0yMDQuNCwxMTEuMWMwLDMuMywxLjksNi43LDUuNSw2LjdjMy41LDAsNS41LTMuMiw1LjUtNi45YzAtMy4xLTEuNy02LjctNS40LTYuNwoJCUMyMDYuMSwxMDQuMiwyMDQuNCwxMDcuNiwyMDQuNCwxMTEuMXoiLz4KCTxwYXRoIGNsYXNzPSJzdDAiIGQ9Ik0yMjIuMywxMDMuOGMwLjktMC4yLDIuMi0wLjMsMy4yLTAuM2MxLjksMCwzLjIsMC40LDQsMS4zYzAuNiwwLjYsMSwxLjYsMSwyLjZjMCwyLTEuMiwzLjMtMi45LDMuOXYwCgkJYzEuMiwwLjQsMS45LDEuNSwyLjMsMy4xYzAuNSwyLjMsMC44LDMuNCwxLjEsNEgyMzBjLTAuMi0wLjQtMC41LTEuNy0wLjktMy42Yy0wLjUtMi4xLTEuNC0zLjEtMy4zLTMuMmgtMi4zdjYuOGgtMS4xVjEwMy44egoJCSBNMjIzLjQsMTEwLjdoMi40YzIuMywwLDMuOC0xLjMsMy44LTMuMmMwLTIuMy0xLjctMy4yLTQtMy4yYy0xLDAtMS44LDAuMS0yLjEsMC4yVjExMC43eiIvPgoJPHBhdGggY2xhc3M9InN0MCIgZD0iTTIzNi43LDEwMy41aDEuMXY3LjVoMC4xYzAuNC0wLjYsMC45LTEuMSwxLjMtMS41bDUuMy02aDEuM2wtNS42LDYuM2w2LjIsOC41aC0xLjNsLTUuNi03LjhsLTEuNSwxLjd2Ni4xCgkJaC0xLjFWMTAzLjV6Ii8+Cgk8cGF0aCBjbGFzcz0ic3QwIiBkPSJNMjYwLjEsMTAzLjV2MTQuOGgtMS4xdi0xNC44SDI2MC4xeiIvPgoJPHBhdGggY2xhc3M9InN0MCIgZD0iTTI2NywxMTguNHYtMTQuOGgxbDUuOCw4LjhjMS4yLDEuOCwyLjEsMy4yLDIuOCw0LjdsMCwwYy0wLjItMi0wLjItMy43LTAuMi02di03LjRoMXYxNC44aC0xbC01LjctOC42CgkJYy0xLjEtMS43LTIuMS0zLjMtMi45LTQuOGwwLDBjMC4xLDEuOCwwLjEsMy40LDAuMSw1Ljl2Ny41SDI2N3oiLz4KCTxwYXRoIGNsYXNzPSJzdDAiIGQ9Ik0yODcuMiwxMDQuNGgtNC44di0wLjloMTAuN3YwLjloLTQuOHYxNGgtMS4xVjEwNC40eiIvPgoJPHBhdGggY2xhc3M9InN0MCIgZD0iTTMwNC45LDExMWgtNS45djYuNWg2LjZ2MC45aC03Ljd2LTE0LjhoNy4zdjAuOWgtNi4zdjUuN2g1LjlWMTExeiIvPgoJPHBhdGggY2xhc3M9InN0MCIgZD0iTTMxMS40LDEwMy41aDEuMXYxNGg2LjZ2MC45aC03LjdWMTAzLjV6Ii8+Cgk8cGF0aCBjbGFzcz0ic3QwIiBkPSJNMzI0LjYsMTAzLjVoMS4xdjE0aDYuNnYwLjloLTcuN1YxMDMuNXoiLz4KCTxwYXRoIGNsYXNzPSJzdDAiIGQ9Ik0zMzguOCwxMDMuNXYxNC44aC0xLjF2LTE0LjhIMzM4Ljh6Ii8+Cgk8cGF0aCBjbGFzcz0ic3QwIiBkPSJNMzU2LjMsMTE3LjdjLTAuNywwLjMtMi4zLDAuOC00LjMsMC44Yy0yLDAtMy43LTAuNS01LjItMS45Yy0xLjItMS4yLTItMy4yLTItNS42YzAtNC4xLDIuNy03LjYsNy43LTcuNgoJCWMxLjYsMCwyLjksMC40LDMuNSwwLjdsLTAuNCwwLjljLTAuOC0wLjQtMS43LTAuNi0zLjItMC42Yy00LjEsMC02LjYsMi42LTYuNiw2LjdjMCw0LjIsMi40LDYuNyw2LjQsNi43YzEuNiwwLDIuNi0wLjIsMy4xLTAuNQoJCXYtNS4yaC0zLjRWMTExaDQuNVYxMTcuN3oiLz4KCTxwYXRoIGNsYXNzPSJzdDAiIGQ9Ik0zNjkuNywxMTFoLTUuOXY2LjVoNi42djAuOWgtNy43di0xNC44aDcuM3YwLjloLTYuM3Y1LjdoNS45VjExMXoiLz4KCTxwYXRoIGNsYXNzPSJzdDAiIGQ9Ik0zNzYuMywxMTguNHYtMTQuOGgxbDUuOCw4LjhjMS4yLDEuOCwyLjEsMy4yLDIuOCw0LjdsMCwwYy0wLjItMi0wLjItMy43LTAuMi02di03LjRoMXYxNC44aC0xbC01LjctOC42CgkJYy0xLjEtMS43LTIuMS0zLjMtMi45LTQuOGwwLDBjMC4xLDEuOCwwLjEsMy40LDAuMSw1Ljl2Ny41SDM3Ni4zeiIvPgoJPHBhdGggY2xhc3M9InN0MCIgZD0iTTQwMy43LDExNy44Yy0wLjcsMC40LTIuMiwwLjctNCwwLjdjLTMuNiwwLTctMi4zLTctNy41YzAtNC40LDIuOC03LjcsNy41LTcuN2MxLjksMCwzLDAuNCwzLjQsMC43bC0wLjMsMC45CgkJYy0wLjctMC40LTEuOC0wLjYtMy4xLTAuNmMtNCwwLTYuNCwyLjYtNi40LDYuOWMwLDQsMi4zLDYuNiw2LjMsNi42YzEuMywwLDIuNS0wLjMsMy4zLTAuN0w0MDMuNywxMTcuOHoiLz4KCTxwYXRoIGNsYXNzPSJzdDAiIGQ9Ik00MTYuNCwxMTFoLTUuOXY2LjVoNi42djAuOWgtNy43di0xNC44aDcuM3YwLjloLTYuM3Y1LjdoNS45VjExMXoiLz4KPC9nPgo8L3N2Zz4K"
--------------------------------------------------------------------------------
-- Per-model chassis SVGs (base64). Used by layout.lua to render each
-- GigaCore as its actual product-chassis artwork.
--------------------------------------------------------------------------------

local LogoPSU = "PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiIHN0YW5kYWxvbmU9Im5vIj8+CjwhLS0gQ3JlYXRlZCB3aXRoIElua3NjYXBlIChodHRwOi8vd3d3Lmlua3NjYXBlLm9yZy8pIC0tPgoKPHN2ZwogICB3aWR0aD0iOS45NzI2NTYybW0iCiAgIGhlaWdodD0iOS45NjY3OTY5bW0iCiAgIHZpZXdCb3g9IjAgMCA5Ljk3MjY1NjIgOS45NjY3OTY5IgogICB2ZXJzaW9uPSIxLjEiCiAgIGlkPSJzdmc1IgogICB4bWw6c3BhY2U9InByZXNlcnZlIgogICB4bWxuczppbmtzY2FwZT0iaHR0cDovL3d3dy5pbmtzY2FwZS5vcmcvbmFtZXNwYWNlcy9pbmtzY2FwZSIKICAgeG1sbnM6c29kaXBvZGk9Imh0dHA6Ly9zb2RpcG9kaS5zb3VyY2Vmb3JnZS5uZXQvRFREL3NvZGlwb2RpLTAuZHRkIgogICB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciCiAgIHhtbG5zOnN2Zz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPjxzb2RpcG9kaTpuYW1lZHZpZXcKICAgICBpZD0ibmFtZWR2aWV3NyIKICAgICBwYWdlY29sb3I9IiNmZmZmZmYiCiAgICAgYm9yZGVyY29sb3I9IiMwMDAwMDAiCiAgICAgYm9yZGVyb3BhY2l0eT0iMC4yNSIKICAgICBpbmtzY2FwZTpzaG93cGFnZXNoYWRvdz0iMiIKICAgICBpbmtzY2FwZTpwYWdlb3BhY2l0eT0iMC4wIgogICAgIGlua3NjYXBlOnBhZ2VjaGVja2VyYm9hcmQ9IjAiCiAgICAgaW5rc2NhcGU6ZGVza2NvbG9yPSIjZDFkMWQxIgogICAgIGlua3NjYXBlOmRvY3VtZW50LXVuaXRzPSJtbSIKICAgICBzaG93Z3JpZD0iZmFsc2UiIC8+PGRlZnMKICAgICBpZD0iZGVmczIiPjxjbGlwUGF0aAogICAgICAgY2xpcFBhdGhVbml0cz0idXNlclNwYWNlT25Vc2UiCiAgICAgICBpZD0iY2xpcFBhdGgxMTQwOSI+PGcKICAgICAgICAgaWQ9ImcxMTQxMyIKICAgICAgICAgdHJhbnNmb3JtPSJtYXRyaXgoMi42OTUzNzYyLDAsMCwtMi42OTY5ODA4LC0xNTE2Ljk4ODMsNzQ3Ljg0MjA2KSI+PHBhdGgKICAgICAgICAgICBkPSJNIDE3My4xMTg5MSwtNDcuNDE2ODg5IEggMTIyNC43ODg4IFYgMTAwMy42MjczIEggMTczLjExODkxIFoiCiAgICAgICAgICAgaWQ9InBhdGgxMTQxMSIKICAgICAgICAgICBzdHlsZT0ic3Ryb2tlLXdpZHRoOjAuMzcwODk1IiAvPjwvZz48L2NsaXBQYXRoPjxjbGlwUGF0aAogICAgICAgY2xpcFBhdGhVbml0cz0idXNlclNwYWNlT25Vc2UiCiAgICAgICBpZD0iY2xpcFBhdGgxMTQxNSI+PGcKICAgICAgICAgaWQ9ImcxMTQxOSIKICAgICAgICAgdHJhbnNmb3JtPSJtYXRyaXgoMi42OTUzNzYyLDAsMCwtMi42OTY5ODA4LC0xNTI0Ljc2MTIsNzM2LjA4MTc3KSI+PHBhdGgKICAgICAgICAgICBkPSJNIDE3My4xMTg5MSwtNDcuNDE2ODg5IEggMTIyNC43ODg4IFYgMTAwMy42MjczIEggMTczLjExODkxIFoiCiAgICAgICAgICAgaWQ9InBhdGgxMTQxNyIKICAgICAgICAgICBzdHlsZT0ic3Ryb2tlLXdpZHRoOjAuMzcwODk1IiAvPjwvZz48L2NsaXBQYXRoPjwvZGVmcz48ZwogICAgIGlua3NjYXBlOmxhYmVsPSJMYXllciAxIgogICAgIGlua3NjYXBlOmdyb3VwbW9kZT0ibGF5ZXIiCiAgICAgaWQ9ImxheWVyMSIKICAgICBzb2RpcG9kaTppbnNlbnNpdGl2ZT0idHJ1ZSIKICAgICB0cmFuc2Zvcm09InRyYW5zbGF0ZSgtNTU2Ljk2OTEzLC0yNzIuOTI4MDYpIj48cGF0aAogICAgICAgZD0iTSAyNDkuNzM1ODMsOTMxLjIxNTAyIEggMTI0OS43MzU0IFYgLTY4Ljc4NDcxMSBIIDI0OS43MzU4MyBaIgogICAgICAgc3R5bGU9ImZpbGw6IzIzMWYyMDtmaWxsLW9wYWNpdHk6MTtmaWxsLXJ1bGU6bm9uemVybztzdHJva2U6bm9uZTtzdHJva2Utd2lkdGg6MC4zNTI3NzgiCiAgICAgICBpZD0icGF0aDEwNTkiIC8+PC9nPjxnCiAgICAgaW5rc2NhcGU6Z3JvdXBtb2RlPSJsYXllciIKICAgICBpZD0ibGF5ZXIyIgogICAgIGlua3NjYXBlOmxhYmVsPSJMYXllciAyIgogICAgIHRyYW5zZm9ybT0idHJhbnNsYXRlKC01NTYuOTY5MTMsLTI3Mi45MjgwNikiPjxnCiAgICAgICBpZD0iZzEzMDEiCiAgICAgICB0cmFuc2Zvcm09Im1hdHJpeCgwLjM3MTAwNTczLDAsMCwtMC4zNzA3ODQ5OSw1NjUuNjk1MTQsMjcyLjkyODA3KSIKICAgICAgIGNsaXAtcGF0aD0idXJsKCNjbGlwUGF0aDExNDE1KSIKICAgICAgIGlua3NjYXBlOmV4cG9ydC1maWxlbmFtZT0iUFNVX0ljb25wbmcuc3ZnIgogICAgICAgaW5rc2NhcGU6ZXhwb3J0LXhkcGk9Ijk2IgogICAgICAgaW5rc2NhcGU6ZXhwb3J0LXlkcGk9Ijk2Ij48cGF0aAogICAgICAgICBkPSJtIDAsMCBoIC0yMC4xNiBjIC0xLjg1NCwtMC4wMDYgLTMuMzU0LC0xLjUwNiAtMy4zNiwtMy4zNiB2IC0xNS4xMiBjIDAuMDA2LC0xLjg1NCAxLjUwNiwtMy4zNTQgMy4zNiwtMy4zNiBoIDUuMDQgdiAzLjM2IGggLTUuMDQgdiAxNS4xMiBoIDEuNjggViAtOC40IGggMy4zNiB2IDUuMDQgaCAzLjM2IFYgLTguNCBoIDMuMzYgdiA1LjA0IGggMy4zNiBWIC04LjQgaCAzLjM2IHYgNS4wNCBIIDAgdiAtMTUuMTIgaCAtNS4wNCB2IC0zLjM2IEggMCBjIDEuODU0LDAuMDA2IDMuMzU0LDEuNTA2IDMuMzYsMy4zNiBWIC0zLjM2IEMgMy4zNTQsLTEuNTA2IDEuODU0LC0wLjAwNiAwLDAiCiAgICAgICAgIHN0eWxlPSJmaWxsOiNmZmZmZmY7ZmlsbC1vcGFjaXR5OjE7ZmlsbC1ydWxlOm5vbnplcm87c3Ryb2tlOm5vbmUiCiAgICAgICAgIGlkPSJwYXRoMTMwMyIgLz48L2c+PGcKICAgICAgIGlkPSJnMTMwNSIKICAgICAgIHRyYW5zZm9ybT0ibWF0cml4KDAuMzcxMDA1NzMsMCwwLC0wLjM3MDc4NDk5LDU2Mi44MTEzNSwyNzcuMjg4NjEpIgogICAgICAgY2xpcC1wYXRoPSJ1cmwoI2NsaXBQYXRoMTE0MDkpIj48cGF0aAogICAgICAgICBkPSJtIDAsMCBoIC00LjMzMiBsIC0yLjczNCwtNi43MiBoIDMuNDQ0IGwgLTIuOTI4LC04LjQgOC4xOTQsMTEuNzYgaCAtMy41NTIgeiIKICAgICAgICAgc3R5bGU9ImZpbGw6I2ZmZmZmZjtmaWxsLW9wYWNpdHk6MTtmaWxsLXJ1bGU6bm9uemVybztzdHJva2U6bm9uZSIKICAgICAgICAgaWQ9InBhdGgxMzA3IiAvPjwvZz48L2c+PC9zdmc+Cg=="

--------------------------------------------------------------------------------
-- Static Tables / Lookups
--------------------------------------------------------------------------------
-- Per-model port type breakdown. Ports are assumed to be numbered
-- sequentially: ethercon → rj45 → sfp. `poe` = number of PoE-capable
-- ports counted from port 1 (drives the grey PoE pips shown offline).
PORT_LAYOUT = {
  ["GigaCore 30i"]    = { ethercon = 0,  rj45 = 24, sfp = 6,  poe = 24 },
  ["GigaCore S30-I"]  = { ethercon = 0,  rj45 = 24, sfp = 6,  poe = 0  },
  ["GigaCore O26-I"]  = { ethercon = 0,  rj45 = 0,  sfp = 26, poe = 0  }, -- 2 QSFP + 4 SFP28 + 20 SFP+
  ["GigaCore 20t"]    = { ethercon = 8,  rj45 = 8,  sfp = 4,  poe = 16 },
  ["GigaCore 18t"]    = { ethercon = 8,  rj45 = 8,  sfp = 2,  poe = 16 },
  ["GigaCore 16t"]    = { ethercon = 8,  rj45 = 8,  sfp = 0,  poe = 16 },
  ["GigaCore 16tf"]   = { ethercon = 12, rj45 = 0,  sfp = 4,  poe = 16 },
  ["GigaCore 16i"]    = { ethercon = 0,  rj45 = 12, sfp = 4,  poe = 0  },
  ["GigaCore 10t"]    = { ethercon = 8,  rj45 = 0,  sfp = 2,  poe = 8  },
  ["GigaCore 10t-IP"] = { ethercon = 8,  rj45 = 0,  sfp = 2,  poe = 8  }, -- 9-10 are rear ethercons, no PoE
  ["GigaCore 10i"]    = { ethercon = 0,  rj45 = 8,  sfp = 2,  poe = 0  },
}

-- Groups and Trunks page: predefined groups 1..20 and trunk 1 (ISL) always
-- exist; custom groups/trunks get reserved slots filled at runtime.
-- Slot controls: group_label_21..(20+CUSTOM_GROUP_SLOTS), trunk_label_2..(1+CUSTOM_TRUNK_SLOTS).
CUSTOM_GROUP_SLOTS = 20
CUSTOM_TRUNK_SLOTS = 8
-- Fill of the Port.Group cell and of the picker's None item when unassigned.
PICKER_UNASSIGNED_HEX = "#3A4256"

-- Build GigaCoreModels (port totals) from PORT_LAYOUT for backward compat.
GigaCoreModels = {}
for model, layout in pairs(PORT_LAYOUT) do
  GigaCoreModels[model] = (layout.ethercon or 0) + (layout.rj45 or 0) + (layout.sfp or 0)
end

function getPortCount(model)
  return GigaCoreModels[model] or 30
end

function getEtherconCount(model)
  local l = PORT_LAYOUT[model]
  return (l and l.ethercon) or 0
end

function getRJ45Count(model)
  local l = PORT_LAYOUT[model]
  return (l and l.rj45) or 0
end

function getSFPCount(model)
  local l = PORT_LAYOUT[model]
  return (l and l.sfp) or 0
end

-- Look up the base64-encoded chassis SVG for a given model.

-- Base64 chassis artwork, cropped left of port 1 (see tools/parse_svg_ports.py).
function getChassisSvg(model)
  local c = PORT_COORDS and PORT_COORDS[model]
  return c and c.svg or nil
end

-- Return the parsed PORT_COORDS entry for a model, or nil if we haven't
-- built an accurate overlay for it yet (fall back to the generic grid).
function getPortCoords(model)
  return PORT_COORDS and PORT_COORDS[model]
end

-- Translate a rect from SVG space (per the model's viewBox) to screen space
-- given where the SVG is rendered on the page.
function svgToScreen(coords, svgX, svgY, svgW, svgH, vbW, vbH)
  local sx = svgW / vbW
  local sy = svgH / vbH
  return {
    x = svgX + coords.x * sx,
    y = svgY + coords.y * sy,
    w = coords.w * sx,
    h = coords.h * sy,
  }
end

-- Resolve the model from the Model property (plain lookup).
function resolveModel(props)
  local raw = props["Model"]
  local val = (type(raw) == "table") and raw.Value or raw
  return val or "GigaCore 30i"
end

--------------------------------------------------------------------------------
-- Group colors
--------------------------------------------------------------------------------
GROUP_COLORS = {
  ["Trunk: 1"]  = {153, 153, 153},
  ["Group: 1"]  = { 50,  81, 151},
  ["Group: 2"]  = {232,   0,   0},
  ["Group: 3"]  = { 50, 205,  50},
  ["Group: 4"]  = {  0, 232, 232},
  ["Group: 5"]  = {204,   0, 204},
  ["Group: 6"]  = {255, 130,   0},
  ["Group: 7"]  = {232, 232,   0},
  ["Group: 8"]  = {255,   0, 153},
  ["Group: 9"]  = { 32, 178, 170},
  ["Group: 10"] = {250, 128, 114},
  ["Group: 11"] = {  0,  51, 255},
  ["Group: 12"] = {  0, 128,   0},
  ["Group: 13"] = {187,  85,  85},
  ["Group: 14"] = {139,   0,   0},
  ["Group: 15"] = { 75,   0, 130},
  ["Group: 16"] = {153, 153,   0},
  ["Group: 17"] = {124, 232,   0},
  ["Group: 18"] = {102,   0, 102},
  ["Group: 19"] = { 47,  79,  79},
  ["Group: 20"] = {  0, 102, 204},
}

--------------------------------------------------------------------------------
-- Port speed mappings
--------------------------------------------------------------------------------
SPEED_CHOICES = {
  "Auto",
  "Disabled",
  "10 Gbps",
  "2.5 Gbps",
  "1 Gbps",
  "100 Mbps (Full-duplex)",
  "100 Mbps (Half-duplex)",
  "10 Mbps (Full-duplex)",
  "10 Mbps (Half-duplex)",
}

SPEED_API_MAP = {
  ["10 Gbps"]                = "10gbps fdx",
  ["2.5 Gbps"]               = "2.5gbps fdx",
  ["1 Gbps"]                 = "1gbps fdx",
  ["100 Mbps (Full-duplex)"] = "100mbps fdx",
  ["100 Mbps (Half-duplex)"] = "100mbps hdx",
  ["10 Mbps (Full-duplex)"]  = "10mbps fdx",
  ["10 Mbps (Half-duplex)"]  = "10mbps hdx",
}

SPEED_UI_MAP = {
  ["10gbps fdx"]  = "10 Gbps",
  ["2.5gbps fdx"] = "2.5 Gbps",
  ["1gbps fdx"]   = "1 Gbps",
  ["100mbps fdx"] = "100 Mbps (Full-duplex)",
  ["100mbps hdx"] = "100 Mbps (Half-duplex)",
  ["10mbps fdx"]  = "10 Mbps (Full-duplex)",
  ["10mbps hdx"]  = "10 Mbps (Half-duplex)",
}

--------------------------------------------------------------------------------
-- Utility / Logging
--------------------------------------------------------------------------------
function log(m)
  print(tostring(m))
end

--------------------------------------------------------------------------------
-- Layout constants (shared between info.lua and layout.lua)
--------------------------------------------------------------------------------
-- Port Link visual: bright green when link up, dim green when link down.
-- (Was identical in the legacy plugin; we now distinguish so the ethercon
-- ring hider can mirror the actual rendered color and blend cleanly.)
LINK_OFF = {30, 110, 30, 200}
LINK_ON  = {0, 255, 0, 200}
GROUPBOX_FILL_COLOR    = {12, 21, 42}
GROUPBOX_STROKE_COLOR  = {0, 0, 0}
GROUPBOX_STROKE_WIDTH  = 0
GROUPBOX_POSITION      = {0, 0}
SIDE_MARGIN            = 70
GROUPBOX_EXTRA_PADDING = 5

--------------------------------------------------------------------------------
-- Internal state
--------------------------------------------------------------------------------
state = {
  ws              = nil,
  baseIP          = "",
  currentIP       = "",
  prefixLength    = "",
  ipMode          = "",
  portCount       = 30,
  macAddress      = "",
  firmwareVersion = "",
  groupNames      = {},
  groupMeta       = {},
  customColors    = {},   -- "Group: N" / "Trunk: N" → {r,g,b} (live from API)
  groupList       = {},   -- [{id, name, color, predefined, vid}] ordered as returned
  trunkList       = {},   -- [{id, name, color, predefined}] ordered as returned
  ports           = {},
  darkMode        = false,
}

--------------------------------------------------------------------------------
-- Port state model
--------------------------------------------------------------------------------
function getPortState(port)
  state.ports[port] = state.ports[port] or {
    enabled        = true,
    link           = false,
    memberOf       = nil,
    poe            = nil,
    poeEnabled     = nil,
    rlinkx         = nil,
    speed          = nil,
    lastValidSpeed = nil,
    speedPending   = false,
  }
  return state.ports[port]
end

--------------------------------------------------------------------------------
-- Theme palette (dark + light)
--
-- Futuristic aesthetic inspired by Luminex Araneo. Dark = deep navy with
-- bright cyan accent; light = off-white with navy accents (no pure black).
--------------------------------------------------------------------------------
function getThemeColors()
  if state.darkMode then
    return {
      -- Backgrounds
      pageBg        = { 11, 18, 32 },              -- #0B1220 — page canvas
      gridLine      = { 26, 40, 64, 120 },         -- subtle blue grid
      chassisFill   = { 26, 45, 80, 255 },         -- #1A2D50 — switch body
      chassisStroke = { 90, 140, 200, 180 },
      chassisInner  = { 42, 66, 108, 255 },        -- inner plate under ports

      -- Cards (left temps / right PSU / strips)
      cardFill      = { 22, 34, 58, 245 },
      cardStroke    = { 68, 112, 178, 180 },
      cardTitle     = { 140, 210, 255 },           -- cyan accent for labels

      -- Typography
      textPrimary   = { 232, 240, 252 },           -- soft white
      textMuted     = { 150, 175, 210 },
      textDim       = { 110, 138, 175 },
      accentCyan    = { 120, 200, 255 },           -- #78C8FF primary accent
      accentAmber   = { 255, 178, 56 },
      accentMagenta = { 232, 120, 232 },

      -- Port appearance
      portDefault   = { 36, 56, 92, 255 },         -- unassigned port body
      portText      = { 245, 250, 255 },
      portStroke    = { 90, 130, 180, 220 },
      portOffFill   = { 36, 56, 92, 255 },         -- offline port body (Araneo project mode)
      portOffStroke = { 83, 205, 229, 255 },       -- #53CDE5 cyan outline
      linkUpRing    = { 60, 230, 140, 230 },       -- bright green
      linkDownRing  = { 110, 130, 160, 90 },

      -- Status badges
      badgeOkFg     = { 180, 255, 210 }, badgeOkBg   = { 20, 90, 60, 220 },
      badgeWarnFg   = { 255, 220, 160 }, badgeWarnBg = { 110, 75, 20, 220 },
      badgeErrFg    = { 255, 180, 180 }, badgeErrBg  = { 110, 30, 30, 220 },
      badgeOffFg    = { 160, 175, 200 }, badgeOffBg  = { 36, 48, 70, 220 },

      -- PoE (pip colors)
      poeSourcing   = { 255, 140, 20 },
      poeEnabled    = { 255, 215, 0 },
      poeDisabled   = { 80, 90, 110 },

      -- MR badge (multicast router port)
      mrFill        = { 190, 130, 255 },           -- purple
      mrText        = { 28, 12, 48 },

      -- RLinkX border colors (Araneo-matched)
      rlinkxEnabled  = { 0, 255, 255 },             -- cyan
      rlinkxActive   = { 0, 0, 255 },               -- blue
      rlinkxDisabled = { 204, 209, 219 },           -- light grey
      rlinkxOn       = { 0, 178, 255 },             -- legacy alias (bar)
      rlinkxOff      = { 90, 100, 130 },

      -- Trunk badge (top-left corner triangle)
      trunkBadge    = { 14, 22, 44 },              -- dark navy contrast
    }
  else
    return {
      -- Backgrounds
      pageBg        = { 238, 242, 248 },           -- #EEF2F8 off-white
      gridLine      = { 200, 215, 235, 160 },
      chassisFill   = { 210, 222, 240, 255 },
      chassisStroke = { 130, 160, 200, 200 },
      chassisInner  = { 230, 238, 250, 255 },

      cardFill      = { 255, 255, 255, 245 },
      cardStroke    = { 180, 200, 225, 200 },
      cardTitle     = { 25, 60, 120 },             -- navy label

      textPrimary   = { 28, 46, 78 },
      textMuted     = { 90, 115, 155 },
      textDim       = { 140, 160, 190 },
      accentCyan    = { 25, 110, 200 },
      accentAmber   = { 200, 120, 20 },
      accentMagenta = { 170, 60, 170 },

      portDefault   = { 220, 230, 244, 255 },
      portText      = { 28, 46, 78 },
      portStroke    = { 150, 175, 210, 220 },
      portOffFill   = { 220, 230, 244, 255 },
      portOffStroke = { 25, 110, 200, 255 },
      linkUpRing    = { 36, 180, 100, 240 },
      linkDownRing  = { 170, 185, 205, 150 },

      badgeOkFg     = { 20, 100, 60 },  badgeOkBg   = { 210, 240, 220, 255 },
      badgeWarnFg   = { 145, 85, 20 },  badgeWarnBg = { 255, 230, 190, 255 },
      badgeErrFg    = { 150, 30, 30 },  badgeErrBg  = { 255, 210, 210, 255 },
      badgeOffFg    = { 100, 115, 140 }, badgeOffBg = { 225, 232, 242, 255 },

      poeSourcing   = { 230, 120, 20 },
      poeEnabled    = { 210, 170, 20 },
      poeDisabled   = { 170, 180, 200 },

      mrFill        = { 140, 80, 200 },
      mrText        = { 255, 255, 255 },

      rlinkxEnabled  = { 0, 255, 255 },
      rlinkxActive   = { 0, 0, 255 },
      rlinkxDisabled = { 204, 209, 219 },
      rlinkxOn       = { 20, 130, 200 },
      rlinkxOff     = { 170, 180, 200 },

      trunkBadge    = { 22, 36, 68 },
    }
  end
end

--------------------------------------------------------------------------------
-- Hex helper — converts {r,g,b[,a]} to "#RRGGBB" (alpha dropped for Color)
--------------------------------------------------------------------------------
function rgbHex(c)
  if not c then return "#00000000" end
  return string.format("#%02X%02X%02X", c[1], c[2], c[3])
end

--------------------------------------------------------------------------------
-- Backwards-compat theme keys (still referenced by other page builders).
--------------------------------------------------------------------------------
local _origGetTheme = getThemeColors
function getThemeColors()
  local t = _origGetTheme()
  t.groupboxFill   = t.pageBg
  -- Indicator fill matches the page bg so empty device-info boxes blend in
  -- (backup convention: visually invisible until populated).
  t.indicatorFill  = state.darkMode and { 20, 24, 40, 230 } or { 240, 245, 255, 255 }
  t.strokeColor    = t.cardStroke
  t.textColor      = t.textPrimary
  t.textboxColor   = t.textPrimary
  t.textboxBg      = t.cardFill
  t.buttonColor    = t.accentCyan
  t.buttonAltColor = t.accentCyan
  t.buttonOffColor = t.portDefault
  t.labelGray      = t.textMuted
  -- Port backdrop rectangle — subtle, close to page bg (backup value).
  t.rectangleFill  = state.darkMode and { 30, 40, 60, 220 } or { 240, 245, 255, 255 }
  return t
end

--------------------------------------------------------------------------------
-- Port UI Renderer (UI ONLY)
--------------------------------------------------------------------------------
function renderPortUI(port)
  local p = getPortState(port)
  local theme = getThemeColors()

  -- Port body color encodes the active link speed (Araneo convention):
  --   Link down / unknown → dim (page bg)
  --   10 Mbps / 100 Mbps   → orange
  --   1 / 2.5 / 10 / 25 / 40 Gbps → green
  local linkCtrl = Controls["Port.Link " .. port]
  if linkCtrl then
    linkCtrl.Boolean = (p.link == true)
    local speedColor
    if p.link ~= true then
      speedColor = { 15, 22, 38, 255 }     -- near page bg
    else
      local s = tostring(p.speed or "")
      if s:find("10 Mbps") or s:find("100 Mbps") or s:find("10mbps") or s:find("100mbps") then
        speedColor = { 255, 140, 20, 220 } -- orange
      else
        speedColor = { 0, 200, 60, 220 }   -- green
      end
    end
    linkCtrl.Color = rgbHex(speedColor)
    pcall(function() linkCtrl.OffColor = rgbHex(speedColor) end)
  end


  local enableToggle = Controls["Port.Enable " .. port]
  if enableToggle then
    enableToggle.Boolean = (p.enabled == true)
  end

  -- Group / trunk color. Live API color preferred, predefined palette
  -- fallback, transparent if unassigned. Disabled ports render the halo
  -- in solid black (Araneo convention).
  local memberOf  = p.memberOf
  local isTrunk   = memberOf and memberOf:sub(1, 6) == "Trunk:"
  local groupColor = (state.customColors and state.customColors[memberOf])
                    or GROUP_COLORS[memberOf]
  local groupHex
  if p.enabled == false then
    groupHex = "#000000"
  else
    groupHex = groupColor and rgbHex(groupColor) or "#00000000"
  end

  -- Label control below the port (non-overlay mode).
  local groupCtrl = Controls["Port.Group Color " .. port]
  if groupCtrl then
    groupCtrl.Color  = groupHex
    groupCtrl.String = memberOf or ""
  end

  -- Group-color halo behind port (SVG overlay mode). Text — backup pattern:
  -- runtime .Color = hex paints the fill, .String = " " keeps it renderable.
  local bgCtrl = Controls["Port Bg" .. port]
  if bgCtrl then
    bgCtrl.Color  = groupHex
    bgCtrl.String = " "
  end

  -- Port.Group cell — Button colored with group color, Legend = name.
  local groupBtn = Controls["Port.Group " .. port]
  if groupBtn then
    local cellHex = (memberOf and groupHex ~= "#00000000") and groupHex or PICKER_UNASSIGNED_HEX
    groupBtn.Color = cellHex
    pcall(function() groupBtn.OffColor = cellHex end)
    groupBtn.Legend = memberOfDisplayName(memberOf)
  end

  -- Port number lives in the Port.Link Legend (so it also shows offline).
  -- Blank it when the port is disabled: the X marker replaces it.
  if linkCtrl then
    linkCtrl.Legend = (p.enabled == false) and "" or tostring(port)
  end

  -- Disabled-port red X marker
  local xCtrl = Controls["Port.zz Disabled X " .. port]
  if xCtrl then
    xCtrl.String = (p.enabled == false) and "✕" or ""
  end


  -- Trunk badge: show "◤" only when the port belongs to a trunk
  local trunkBadge = Controls["Port.Trunk Badge " .. port]
  if trunkBadge then
    trunkBadge.Legend = isTrunk and "◤" or ""
  end

  local poeLabel = Controls["PoE.Indication " .. port]
  if poeLabel then
    poeLabel.String = p.poe or ""
  end

  local poeKey = (p.poe or ""):lower()
  local poeColorMap = {
    sourcing = theme.poeSourcing,
    enabled  = theme.poeEnabled,
    disabled = theme.poeDisabled,
  }

  -- PoE pip on the main chassis: Button sharing the Port.Link layer. We set
  -- Color to the state hex and Boolean=true so Q-SYS paints Color (not the
  -- transparent OffColor). For no PoE / disabled we leave Boolean=false so
  -- OffColor (transparent) shows and the pip is invisible.
  local poeBox = Controls["Port.PoE Color " .. port]
  if poeBox then
    local c = poeColorMap[poeKey]
    local hex = c and rgbHex(c) or "#00000000"
    poeBox.Color = hex
    pcall(function() poeBox.OffColor = hex end)
    poeBox.Boolean = (c ~= nil)
  end

  local poeToggle = Controls["PoE.Toggle " .. port]
  if poeToggle then
    poeToggle.Boolean = (p.poeEnabled == true)
    local c = poeColorMap[poeKey]
    poeToggle.Color  = c and rgbHex(c) or "#00000000"
    poeToggle.Legend = (p.poe == "sourcing") and "⚡" or ""
  end

  -- RLinkX bar (visible indicator near bottom of port): cyan when enabled,
  -- darker blue when active, transparent when disabled.
  local rlinkColorMap = {
    enabled  = theme.rlinkxEnabled,
    active   = theme.rlinkxActive,
    disabled = theme.rlinkxDisabled,
  }
  local rlinkHex = (function()
    local c = rlinkColorMap[p.rlinkx] or theme.rlinkxDisabled
    return rgbHex(c)
  end)()

  local rlink = Controls["RLinkX.Bar " .. port]
  if rlink then
    rlink.Color  = rlinkHex
    rlink.String = ""
  end

  -- RLinkX ring — paint all 4 edge strips the same color to form a border.
  -- Used on RJ45 ports.
  for _, edge in ipairs({ "Top", "Bottom", "Left", "Right" }) do
    local c = Controls["RLinkX.Edge " .. edge .. " " .. port]
    if c then c.Color = rlinkHex end
  end

  -- RLinkX circular ring — used on ethercon ports. Outer fill = rlinkx color;
  -- inner hider = button color so only a ring shows between them.
  local ringFill = Controls["RLinkX.Ring Fill " .. port]
  if ringFill then ringFill.Color = rlinkHex end

  -- RLinkX ring (SVG overlay mode) — middle Button layer behind Port.Link.
  -- Renders as a ring because Port.Link (smaller, front) covers the middle.
  local rlinkRing = Controls["Port RlinkX " .. port]
  if rlinkRing then
    -- Always show the ring (disabled shows light grey, enabled cyan, active blue).
    rlinkRing.Boolean = true
    rlinkRing.Color = rlinkHex
    pcall(function() rlinkRing.OffColor = rlinkHex end)
  end

  local ringHider = Controls["RLinkX.Ring Hider " .. port]
  if ringHider then
    ringHider.Color = (p.link == true) and rgbHex(LINK_ON) or rgbHex(LINK_OFF)
  end

  local rlinkToggle = Controls["RLinkX.Toggle " .. port]
  if rlinkToggle then
    rlinkToggle.Boolean = (p.rlinkx == "enabled" or p.rlinkx == "active")
  end

  -- RLinkX state output pin: "disabled" / "enabled" / "active"
  local rlinkText = Controls["RLinkX.State " .. port]
  if rlinkText then
    rlinkText.String = p.rlinkx or ""
  end

  local speedCtrl = Controls["Port.Speed " .. port]
  if speedCtrl and p.speed then
    speedCtrl.String = p.speed
  end
end

--------------------------------------------------------------------------------
-- Basic Auth
--------------------------------------------------------------------------------
function MergeTables(a, b)
  local result = {}
  for k, v in pairs(a) do result[k] = v end
  for k, v in pairs(b) do result[k] = v end
  return result
end

function getAuthHeaders()
  local user = Controls["Auth.Username"] and Controls["Auth.Username"].String or ""
  local pass = Controls["Auth.Password"] and Controls["Auth.Password"].String or ""
  if user == "" or pass == "" then return {} end
  local token = Crypto.Base64Encode(user .. ":" .. pass)
  return { ["Authorization"] = "Basic " .. token }
end

--------------------------------------------------------------------------------
-- WebSocket subscriptions
--------------------------------------------------------------------------------
function subscribeAllPorts()
  if not state.ws then return end

  for i = 1, state.portCount do
    state.ws:Write(string.format('{"subscription":{"path":"/ports/port/%d/link_state","action":"add","method":"changes"}}', i))
    state.ws:Write(string.format('{"subscription":{"path":"/ports/port/%d/member_of","action":"add","method":"changes"}}', i))
    state.ws:Write(string.format('{"subscription":{"path":"/poe/ports/%d/indication","action":"add","method":"changes"}}', i))
    state.ws:Write(string.format('{"subscription":{"path":"/poe/ports/%d/enabled","action":"add","method":"changes"}}', i))
    state.ws:Write(string.format('{"subscription":{"path":"/ports/port/%d/rlinkx","action":"add","method":"changes"}}', i))
    state.ws:Write(string.format('{"subscription":{"path":"/rlinkx/ports/%d/state","action":"add","method":"changes"}}', i))
    state.ws:Write(string.format('{"subscription":{"path":"/ports/port/%d/legend","action":"add","method":"changes"}}', i))
    state.ws:Write(string.format('{"subscription":{"path":"/ports/port/%d/enabled","action":"add","method":"changes"}}', i))
    state.ws:Write(string.format('{"subscription":{"path":"/ports/port/%d/link_speed","action":"add","method":"changes"}}', i))
  end

  state.ws:Write('{"subscription":{"path":"/device/name","action":"add","method":"changes"}}')
  state.ws:Write('{"subscription":{"path":"/device/description","action":"add","method":"changes"}}')
  state.ws:Write('{"subscription":{"path":"/device/actual_ip/ip_address","action":"add","method":"changes"}}')
  state.ws:Write('{"subscription":{"path":"/device/actual_ip/prefix_length","action":"add","method":"changes"}}')
  state.ws:Write('{"subscription":{"path":"/ip_settings/mode","action":"add","method":"changes"}}')
  state.ws:Write('{"subscription":{"path":"/device/mac_address","action":"add","method":"changes"}}')
  state.ws:Write('{"subscription":{"path":"/device/firmware/active","action":"add","method":"changes"}}')
end

--------------------------------------------------------------------------------
-- System / chassis / RSTP / snooping subscriptions
--------------------------------------------------------------------------------
function subscribeAllSystem()
  if not state.ws then return end

  -- CPU + case temps + CPU load
  state.ws:Write('{"subscription":{"path":"/system/temperature/current","action":"add","method":"changes"}}')
  state.ws:Write('{"subscription":{"path":"/system/cpu_load","action":"add","method":"changes"}}')
  state.ws:Write('{"subscription":{"path":"/system/cpu_load_long","action":"add","method":"changes"}}')
  state.ws:Write('{"subscription":{"path":"/temperatures/temperature/cpu/current","action":"add","method":"changes"}}')
  state.ws:Write('{"subscription":{"path":"/temperatures/temperature/case/current","action":"add","method":"changes"}}')

  -- Fans 1..3 (some models have fewer — extras harmlessly never fire)
  for i = 1, 3 do
    state.ws:Write(string.format('{"subscription":{"path":"/fans/fan/%d/speed","action":"add","method":"changes"}}', i))
    state.ws:Write(string.format('{"subscription":{"path":"/fans/fan/%d/state","action":"add","method":"changes"}}', i))
  end

  -- PSUs
  for _, name in ipairs({ "psu1", "psu2" }) do
    state.ws:Write(string.format('{"subscription":{"path":"/power/psus/%s/state","action":"add","method":"changes"}}', name))
    state.ws:Write(string.format('{"subscription":{"path":"/power/psus/%s/power_status","action":"add","method":"changes"}}', name))
    state.ws:Write(string.format('{"subscription":{"path":"/power/psus/%s/power_usage","action":"add","method":"changes"}}', name))
  end

  -- Spanning tree (default MST instance 0)
  state.ws:Write('{"subscription":{"path":"/spanning_tree/mst/0/bridge_priority","action":"add","method":"changes"}}')
  state.ws:Write('{"subscription":{"path":"/spanning_tree/mst/0/root_bridge_address","action":"add","method":"changes"}}')
  state.ws:Write('{"subscription":{"path":"/spanning_tree/mst/0/root_bridge_priority","action":"add","method":"changes"}}')

  -- IGMP snooping router ports (VLAN 1 is the typical default)
  state.ws:Write('{"subscription":{"path":"/snooping/vlan/1/router_ports","action":"add","method":"changes"}}')
end

-- Subscribe to /groups/group/N/name notifications for IDs 1..MAX_GROUPS so
-- name renames (incl. custom groups) reflect live in the UI. The API
-- supports up to 50+ groups; widening the WS subscription range covers the
-- typical custom-group range without flooding.
MAX_GROUPS = 60

function subscribeAllGroups()
  if not state.ws then return end

  for i = 1, MAX_GROUPS do
    state.ws:Write(string.format('{"subscription":{"path":"/groups/group/%d/name","action":"add","method":"changes"}}', i))
    state.ws:Write(string.format('{"subscription":{"path":"/groups/group/%d/group_id","action":"add","method":"changes"}}', i))
  end
end

--------------------------------------------------------------------------------
-- Initial PoE enabled state sync (REST snapshot)
--------------------------------------------------------------------------------
-- One-shot REST snapshot of /api/device to pick up the model name (used by
-- Auto-detect Model). When the reported name matches a known GigaCoreModels
-- key, we stash it in state.detectedModel and trigger a layout rebuild so
-- the chassis page reflects the right port count + ethercon styling.
function fetchDeviceInfo()
  HttpClient.Get {
    Url     = string.format("http://%s/api/device", state.baseIP),
    Headers = MergeTables(
      { ["Content-Type"] = "application/json" },
      getAuthHeaders()
    ),
    EventHandler = function(_tbl, code, body, _err)
      if code ~= 200 or not body then return end
      local name = body:match('"name"%s*:%s*"([^"]+)"')
      if not name or not GigaCoreModels[name] then return end
      state.detectedModel = name
      log("Device model detected => " .. name)
      -- Warn if the user's selected Model doesn't match the switch's report.
      -- Q-SYS plugin layout can't auto-rebuild from runtime so we can only
      -- log the mismatch and rely on the user to correct the Property.
      local cfg = state.selectedModel
      if cfg and cfg ~= name then
        log("WARNING: Model property is set to '" .. cfg ..
            "' but the switch reports '" .. name ..
            "'. Pick the correct model in plugin properties to fix the chassis layout.")
        local ds = Controls["Device.Status"]
        if ds then ds.String = "Model mismatch: switch is " .. name end
      end
    end,
  }
end

--------------------------------------------------------------------------------
-- Bulk REST reconciliation
--
-- WebSocket subscriptions are the live path, but a notification missed
-- during the subscription storm at connect stays wrong until that value
-- changes again. Three bulk GETs (/api/ports, /api/poe/ports, /api/rlinkx)
-- re-apply every port's state through the same setters the WS handlers use.
-- They run right after connect, again 3 s later, then every Poll Interval.
--------------------------------------------------------------------------------

-- Split a JSON array body into its top-level "{...}" elements by walking
-- brace positions with string.find (a per-character loop over a 50 KB body
-- trips Q-SYS's "Max execution limits exceeded"). No braces inside strings
-- in this API.
local function splitJsonObjects(body)
  local objects, depth, start = {}, 0, nil
  local pos = 1
  while true do
    local i = body:find("[{}]", pos)
    if not i then break end
    if body:sub(i, i) == "{" then
      if depth == 0 then start = i end
      depth = depth + 1
    else
      depth = depth - 1
      if depth == 0 and start then
        objects[#objects + 1] = body:sub(start, i)
        start = nil
      end
    end
    pos = i + 1
  end
  return objects
end

-- RLinkX bulk snapshot: /api/rlinkx => {"enabled":..,"ports":[{"port_number":N,"state":"redundant|non-redundant|disabled"},..]}
function syncRlinkxState()
  HttpClient.Get {
    Url     = string.format("http://%s/api/rlinkx", state.baseIP),
    Headers = MergeTables(
      { ["Content-Type"] = "application/json" },
      getAuthHeaders()
    ),
    Timeout = 10,
    EventHandler = function(_tbl, code, body, err)
      log("GET /api/rlinkx => HTTP " .. tostring(code) .. " body=" .. type(body) .. " " .. tostring(err or ""))
      if code ~= 200 or type(body) ~= "string" then return end
      for portNum, stateStr in body:gmatch('"port_number"%s*:%s*(%d+)%s*,%s*"state"%s*:%s*"([^"]+)"') do
        local mapped
        if     stateStr == "redundant"     then mapped = "active"
        elseif stateStr == "non-redundant" then mapped = "enabled"
        else                                    mapped = "disabled"
        end
        local n = tonumber(portNum)
        if n and n <= (state.portCount or 0) then SetPortRlinkx(n, mapped) end
      end
    end,
  }
end

-- Pull nested objects out of one element so top-level scalars can be
-- matched without ambiguity (e.g. "enabled" exists at top level and inside
-- "rlinkx"). Returns the flattened top-level string and a table of nested
-- object strings keyed by field name.
local function splitNested(elem)
  local nested = {}
  local top = elem:gsub('"([%w_]+)"%s*:%s*(%b{})', function(key, obj)
    nested[key] = obj
    return ""
  end)
  return top, nested
end

local function applyPortObject(elem)
  local top, nested = splitNested(elem)
  local port = tonumber(top:match('"port_number"%s*:%s*(%d+)'))
  if not port or port > (state.portCount or 0) then return end

  local enabled = top:match('"enabled"%s*:%s*(%a+)')
  if enabled then SetPortEnabled(port, enabled == "true") end

  local link = top:match('"link_state"%s*:%s*"([^"]*)"')
  if link then SetPortLink(port, link ~= "down" and link ~= "unknown") end

  local legend = top:match('"legend"%s*:%s*"([^"]*)"')
  if legend then
    local display = Controls["Port.Legend " .. port]
    local edit    = Controls["Port.Legend Edit " .. port]
    if display then
      display.String = (#legend > 8) and (legend:sub(1, 8) .. " \n" .. legend:sub(9)) or legend
    end
    if edit then edit.String = legend end
  end

  if nested.member_of then
    local t  = nested.member_of:match('"type"%s*:%s*"([^"]+)"')
    local id = nested.member_of:match('"id"%s*:%s*(%d+)')
    if t == "group" and id then
      SetPortMemberOf(port, "Group: " .. id)
    elseif t == "trunk" and id then
      SetPortMemberOf(port, "Trunk: " .. id)
    elseif t == "none" then
      SetPortMemberOf(port, nil)
    end
  end

  if nested.link_speed then
    local mode  = nested.link_speed:match('"mode"%s*:%s*"([^"]+)"')
    local speed = nested.link_speed:match('"speed"%s*:%s*%[%s*"([^"]+)"')
    if mode == "auto" then
      SetPortSpeed(port, (speed == "all" or not speed) and "Auto" or speed)
    elseif mode == "fixed" and speed then
      SetPortSpeed(port, speed)
    end
  end

  if nested.rlinkx then
    local flag = nested.rlinkx:match('"enabled"%s*:%s*(%a+)')
    local current = getPortState(port).rlinkx
    if flag == "true" then
      if current ~= "active" then SetPortRlinkx(port, "enabled") end
    elseif flag == "false" then
      SetPortRlinkx(port, "disabled")
    end
  end
end

function syncAllPorts()
  HttpClient.Get {
    Url     = string.format("http://%s/api/ports", state.baseIP),
    Headers = MergeTables(
      { ["Content-Type"] = "application/json" },
      getAuthHeaders()
    ),
    Timeout = 10,
    EventHandler = function(_tbl, code, body, err)
      log("GET /api/ports => HTTP " .. tostring(code) .. " body=" .. type(body) .. " " .. tostring(err or ""))
      if code ~= 200 or type(body) ~= "string" then return end
      local arr = body:match('"port"%s*:%s*(%b[])')
      if not arr then return end
      for _, elem in ipairs(splitJsonObjects(arr)) do applyPortObject(elem) end
    end,
  }
end

function syncPoePorts()
  HttpClient.Get {
    Url     = string.format("http://%s/api/poe/ports", state.baseIP),
    Headers = MergeTables(
      { ["Content-Type"] = "application/json" },
      getAuthHeaders()
    ),
    EventHandler = function(_tbl, code, body, _err)
      if code ~= 200 or type(body) ~= "string" then return end
      for _, elem in ipairs(splitJsonObjects(body)) do
        local top = splitNested(elem)
        local port = tonumber(top:match('"port_number"%s*:%s*(%d+)'))
        if port and port <= (state.portCount or 0) then
          local enabled = top:match('"enabled"%s*:%s*(%a+)')
          if enabled then SetPortPoeEnabled(port, enabled == "true") end
          local ind = top:match('"indication"%s*:%s*"([^"]*)"')
          if ind then SetPortIndication(port, ind) end
        end
      end
    end,
  }
end

function reconcileAll()
  log("reconcileAll: ws=" .. tostring(state.ws ~= nil) .. " ip=" .. tostring(state.baseIP))
  if not state.ws or state.baseIP == "" then return end
  syncAllPorts()
  syncPoePorts()
  syncRlinkxState()
  fetchCustomColors()
end

-- Poll Interval property, mirrored into a hidden control (see controls.lua).
function pollIntervalSeconds()
  local ctrl = Controls["Poll Interval"]
  local txt = ctrl and ctrl.String or "15 s"
  return tonumber(txt:match("(%d+)")) or 0   -- "Off" => 0
end

function startPollTimer()
  stopPollTimer()
  local secs = pollIntervalSeconds()
  if secs <= 0 then return end
  state.pollTimer = Timer.New()
  state.pollTimer.EventHandler = function() reconcileAll() end
  state.pollTimer:Start(secs)
end

function stopPollTimer()
  if state.pollTimer then
    state.pollTimer:Stop()
    state.pollTimer = nil
  end
end

--------------------------------------------------------------------------------
-- Custom group / trunk color sync (REST snapshot)
--   /api/groups and /api/trunks return color as "#RRGGBB" per entry.
--   Populates state.customColors so renderPortUI can resolve any memberOf
--   — predefined or user-defined — to its live color.
--------------------------------------------------------------------------------
local function parseHexColor(hex)
  local r = tonumber(hex:sub(2, 3), 16)
  local g = tonumber(hex:sub(4, 5), 16)
  local b = tonumber(hex:sub(6, 7), 16)
  if r and g and b then return { r, g, b } end
end

local function parseBool(s)
  return s == "true"
end

function fetchCustomColors()
  log("fetchCustomColors: GET /api/groups + /api/trunks on " .. tostring(state.baseIP))
  -- Groups
  HttpClient.Get {
    Url     = string.format("http://%s/api/groups", state.baseIP),
    Headers = MergeTables(
      { ["Content-Type"] = "application/json" },
      getAuthHeaders()
    ),
    Timeout = 10,
    EventHandler = function(_tbl, code, body, err)
      log("GET /api/groups => HTTP " .. tostring(code) .. " body=" .. type(body) .. " " .. tostring(err or ""))
      if code ~= 200 or type(body) ~= "string" then return end
      state.groupList = {}
      -- Split the body into per-group segments by locating each
      -- '"group_id":' marker; each segment ends where the next marker
      -- begins (or at end-of-body for the last). Each segment contains
      -- that group's top-level fields (name, color, predefined) before
      -- its nested IGMP/AVB/boundary_clock objects — so simple regex
      -- matches within the segment reliably extract them.
      local positions = {}
      for pos in body:gmatch('()"group_id"%s*:') do
        positions[#positions + 1] = pos
      end
      for i, start in ipairs(positions) do
        local finish = (positions[i + 1] or (#body + 1)) - 1
        local chunk = body:sub(start, finish)
        local gid   = chunk:match('"group_id"%s*:%s*(%d+)')
        local name  = chunk:match('"name"%s*:%s*"([^"]*)"')
        local color = chunk:match('"color"%s*:%s*"(#%x+)"')
        local pre   = chunk:match('"predefined"%s*:%s*(%a+)')
        if gid and color then
          local rgb = parseHexColor(color)
          if rgb then
            local key = "Group: " .. gid
            state.customColors[key] = rgb
            state.groupList[#state.groupList + 1] = {
              id = tonumber(gid),
              name = name or "",
              color = rgb,
              predefined = (pre == "true"),
            }
          end
        end
      end
      local ids = {}
      for _, g in ipairs(state.groupList) do ids[#ids+1] = tostring(g.id) end
      log("fetchCustomColors groups parsed (" .. #state.groupList .. "): " .. table.concat(ids, ","))
      for p = 1, state.portCount do renderPortUI(p) end
      for _, g in ipairs(state.groupList) do
        state.groupNames[g.id] = g.name
        SetGroupLabel(g.id, g.name)
      end
      refreshCustomSlots()
      updatePortGroupChoices()
    end,
  }

  -- Trunks
  HttpClient.Get {
    Url     = string.format("http://%s/api/trunks", state.baseIP),
    Headers = MergeTables(
      { ["Content-Type"] = "application/json" },
      getAuthHeaders()
    ),
    Timeout = 10,
    EventHandler = function(_tbl, code, body, err)
      log("GET /api/trunks => HTTP " .. tostring(code) .. " body=" .. type(body) .. " " .. tostring(err or ""))
      if code ~= 200 or type(body) ~= "string" then return end
      state.trunkList = {}
      -- Per-trunk segment split by "trunk_id" marker (same approach as
      -- groups above — robust against nested objects in the payload).
      local positions = {}
      for pos in body:gmatch('()"trunk_id"%s*:') do
        positions[#positions + 1] = pos
      end
      for i, start in ipairs(positions) do
        local finish = (positions[i + 1] or (#body + 1)) - 1
        local chunk = body:sub(start, finish)
        local tid   = chunk:match('"trunk_id"%s*:%s*(%d+)')
        local name  = chunk:match('"name"%s*:%s*"([^"]*)"')
        local color = chunk:match('"color"%s*:%s*"(#%x+)"')
        local pre   = chunk:match('"predefined"%s*:%s*(%a+)')
        if tid and color then
          local rgb = parseHexColor(color)
          if rgb then
            local key = "Trunk: " .. tid
            state.customColors[key] = rgb
            state.trunkList[#state.trunkList + 1] = {
              id = tonumber(tid),
              name = name or "",
              color = rgb,
              predefined = (pre == "true"),
            }
          end
        end
      end
      local tids = {}
      for _, t in ipairs(state.trunkList) do tids[#tids+1] = tostring(t.id) end
      log("fetchCustomColors trunks parsed (" .. #state.trunkList .. "): " .. table.concat(tids, ","))
      state.trunkNames = state.trunkNames or {}
      for _, t in ipairs(state.trunkList) do
        state.trunkNames[t.id] = t.name
        SetTrunkLabel(t.id, t.name)
      end
      for p = 1, state.portCount do renderPortUI(p) end
      refreshCustomSlots()
      updatePortGroupChoices()
    end,
  }
end

-- Build the Port.Group ComboBox choices from the live group/trunk lists and
-- assign them to every port's control. Choice strings are formatted as
-- "Group N (name)" / "Trunk N (name)" with "(unassigned)" as a no-op option.
function updatePortGroupChoices()
  local choices = { "(unassigned)" }
  for _, g in ipairs(state.groupList or {}) do
    choices[#choices + 1] = string.format("Group %d (%s)", g.id, g.name or "")
  end
  for _, t in ipairs(state.trunkList or {}) do
    choices[#choices + 1] = string.format("Trunk %d (%s)", t.id, t.name or "")
  end
  for p = 1, state.portCount do
    local c = Controls["Port.Group " .. p]
    if c then c.Choices = choices end
  end
end

-- Resolve a memberOf token ("Group: N" / "Trunk: N") to the friendly
-- name. Prefers state.groupNames / state.trunkNames (kept in sync by both
-- the REST snapshot and WS /groups/group/N/name notifications), then
-- falls back to "Group N" / "Trunk N".
function memberOfDisplayName(memberOf)
  if not memberOf or memberOf == "" then return "" end
  local kind, id = memberOf:match("^(%a+):%s*(%d+)$")
  if not kind or not id then return memberOf end
  local idNum = tonumber(id)
  local map = (kind == "Group") and state.groupNames or state.trunkNames
  local nm = map and map[idNum]
  if nm and nm ~= "" then return nm end
  return string.format("%s %d", kind, idNum)
end

--------------------------------------------------------------------------------
-- WebSocket lifecycle
--------------------------------------------------------------------------------
function scheduleReconnect()
  if state.reconnectTimer then return end
  state.reconnectTimer = Timer.New()
  state.reconnectTimer.EventHandler = function()
    state.reconnectTimer:Stop()
    state.reconnectTimer = nil
    if state.baseIP and state.baseIP ~= "" then openWS(state.baseIP) end
  end
  state.reconnectTimer:Start(5)
end

function openWS(ip)
  state.baseIP = ip

  if state.reconnectTimer then
    state.reconnectTimer:Stop()
    state.reconnectTimer = nil
  end
  if state.ws then
    local old = state.ws
    state.ws = nil
    pcall(function() old:Close() end)
  end

  state.ws = WebSocket.New()
  local thisWs = state.ws

  state.ws.Connected = function()
    log("WebSocket Connected")
    local ok, err = pcall(function()
      updateAuthStatus("Authenticated", "#00A000")
      subscribeAllPorts()
      subscribeAllGroups()
      subscribeAllSystem()
      SetDeviceStatus("online")
      fetchDeviceInfo()
    end)
    if not ok then log("Connected handler error (subscriptions): " .. tostring(err)) end
    ok, err = pcall(function()
      reconcileAll()
      Timer.CallAfter(reconcileAll, 3)
      startPollTimer()
    end)
    if not ok then log("Connected handler error (reconcile): " .. tostring(err)) end
  end

  state.ws.Data = function(_, data)
    if state.verboseWs then log("Data: " .. tostring(data)) end
    if data:find('"api_notification"') then
      parseNotification(data)
    end
  end

  state.ws.Error = function(_, err)
    if state.ws ~= thisWs then return end  -- superseded socket
    log("WebSocket Error: " .. (err or "none"))
    stopPollTimer()
    if err and err:find("unauthorized") then
      updateAuthStatus("Auth failed", "#C80000")
    end
    SetDeviceStatus("offline")
    scheduleReconnect()
  end

  state.ws.Closed = function()
    if state.ws ~= thisWs then return end  -- superseded socket
    log("WebSocket Closed")
    stopPollTimer()
    SetDeviceStatus("offline")
    scheduleReconnect()
  end

  local user = Controls["Auth.Username"] and Controls["Auth.Username"].String or ""
  local pass = Controls["Auth.Password"] and Controls["Auth.Password"].String or ""
  local headers = {}
  if user ~= "" and pass ~= "" then
    local token = Crypto.Base64Encode(user .. ":" .. pass)
    headers["Authorization"] = "Basic " .. token
  end

  log("Connecting => ws://" .. ip .. "/api/ws on port 80")
  state.ws:Connect("ws", ip, "api/ws", 80, nil, headers)
end

--------------------------------------------------------------------------------
-- Device info formatting
--------------------------------------------------------------------------------
-- Device-info boxes are transparent at layout time so the static offline
-- placeholders (model name, "---") show through. Paint a box opaque the
-- first time live data lands in it so it covers its placeholder.
function paintHeaderBox(ctrl)
  local theme = getThemeColors()
  pcall(function() ctrl.Color = rgbHex(theme.pageBg) end)
end

function updateIPinfo()
  local ip   = (state.currentIP    ~= "" and state.currentIP)    or "???"
  local pref = (state.prefixLength ~= "" and state.prefixLength) or "??"
  local mode = (state.ipMode       ~= "" and state.ipMode)       or "???"
  local combined = string.format("%s/%s (%s)", ip, pref, mode)
  if Controls["Device.IP Info"] then
    Controls["Device.IP Info"].String = combined
    paintHeaderBox(Controls["Device.IP Info"])
  end
end

-- Single line: the boxes are one row tall, a wrapped second line was cut.
function formatDeviceName(rawName)
  return rawName
end

function formatDeviceDesc(rawDesc)
  return rawDesc
end

function updateMac_Firmware()
  local mac  = state.macAddress      ~= "" and state.macAddress      or "??:??:??:??:??:??"
  local firm = state.firmwareVersion ~= "" and state.firmwareVersion or "?.?.?"
  if Controls["Device.MAC"] then
    Controls["Device.MAC"].String = mac
    paintHeaderBox(Controls["Device.MAC"])
  end
  if Controls["Device.Firmware"] then
    Controls["Device.Firmware"].String = firm
    paintHeaderBox(Controls["Device.Firmware"])
  end
end

function updateAuthStatus(text, color)
  local ctrl = Controls["Auth.Status"]
  if not ctrl then return end
  ctrl.String = text
  ctrl.Color  = (text ~= "") and (color or "#800000") or "#00000000"
end

--------------------------------------------------------------------------------
-- Group layout helpers (data-driven — called from WS handlers)
--------------------------------------------------------------------------------
function layoutGroupBlock(index)
  local baseX, baseY = 0, 0
  local paddingX, paddingY = 10, 10
  local blockW, blockH = 100, 50
  local gridCols = 4

  if index <= 20 then
    local col = (index - 1) % gridCols
    local row = math.floor((index - 1) / gridCols)
    return baseX + col * (blockW + paddingX),
           baseY + row * (blockH + paddingY)
  else
    local colOffset = index - 21
    return baseX + gridCols * (blockW + paddingX) + colOffset * (blockW + paddingX),
           baseY
  end
end

function createGroupLayout()
  for groupId = 1, 20 do
    if state.groupMeta and state.groupMeta[groupId] then
      local _x, _y = layoutGroupBlock(groupId)
    end
  end
end

--------------------------------------------------------------------------------
-- WebSocket notification parser
--------------------------------------------------------------------------------
function extractPath(raw)   return raw:match('"path"%s*:%s*"([^"]+)"') end
function extractString(raw) return raw:match('"new_value"%s*:%s*"([^"]+)"') end
function extractNumber(raw) return raw:match('"new_value"%s*:%s*(%d+)') end
function extractBool(raw)   return raw:match('"new_value"%s*:%s*(%a+)') end

function handleDevicePath(path, raw)
  if path == "/device/name" then
    local v = extractString(raw)
    if v and Controls["Device.Name"] then
      Controls["Device.Name"].String = formatDeviceName(v)
      paintHeaderBox(Controls["Device.Name"])
    end
    return true
  end

  if path == "/device/description" then
    local v = extractString(raw)
    if v and Controls["Device.Description"] then
      Controls["Device.Description"].String = formatDeviceDesc(v)
      paintHeaderBox(Controls["Device.Description"])
    end
    return true
  end

  if path == "/device/mac_address" then
    local v = extractString(raw)
    if v then state.macAddress = v; updateMac_Firmware() end
    return true
  end

  if path == "/device/firmware/active" then
    local v = extractString(raw)
    if v then state.firmwareVersion = v; updateMac_Firmware() end
    return true
  end

  if path == "/device/actual_ip/ip_address" then
    local v = extractString(raw)
    if v then state.currentIP = v; updateIPinfo() end
    return true
  end

  if path == "/device/actual_ip/prefix_length" then
    local v = extractNumber(raw)
    if v then state.prefixLength = v; updateIPinfo() end
    return true
  end

  if path == "/ip_settings/mode" then
    local v = extractString(raw)
    if v then state.ipMode = v; updateIPinfo() end
    return true
  end

  return false
end

function handleGroupPath(path, raw)
  local gid, field = path:match("^/groups/group/(%d+)/(.+)$")
  if not gid then return false end
  gid = tonumber(gid)

  if field == "name" then
    local name = extractString(raw)
    if name then
      state.groupNames = state.groupNames or {}
      state.groupNames[gid] = name
      SetGroupLabel(gid, name)
      -- Refresh every port row so the Group display shows the new name.
      for p = 1, (state.portCount or 0) do renderPortUI(p) end
    end
    return true
  end

  if field == "group_id" then
    local v = extractNumber(raw)
    if v then
      state.groupMeta = state.groupMeta or {}
      state.groupMeta[gid] = state.groupMeta[gid] or {}
      state.groupMeta[gid].id = tonumber(v)

      updateGroupUI(gid)
      SetGroupLabel(gid, state.groupNames[gid] or ("Group " .. gid))
      createGroupLayout()
    end
    return true
  end

  return false
end

function handlePortPath(path, raw)
  local port = path:match("/ports/port/(%d+)/")
              or path:match("/poe/ports/(%d+)/")
              or path:match("/rlinkx/ports/(%d+)/")
  if not port then return false end
  port = tonumber(port)

  if path == ("/ports/port/" .. port .. "/enabled") then
    local v = extractBool(raw)
    if v then SetPortEnabled(port, v == "true") end
    return true
  end

  if path == ("/ports/port/" .. port .. "/legend") then
    local v = extractString(raw)
    if v then
      local display = Controls["Port.Legend " .. port]
      local edit    = Controls["Port.Legend Edit " .. port]
      if display then
        display.String = (#v > 8) and (v:sub(1, 8) .. " \n" .. v:sub(9)) or v
      end
      if edit then edit.String = v end
    end
    return true
  end

  if path == ("/ports/port/" .. port .. "/link_state") then
    local v = extractString(raw)
    if v then SetPortLink(port, v ~= "down" and v ~= "unknown") end
    return true
  end

  if path == ("/ports/port/" .. port .. "/member_of") then
    local obj = raw:match('"new_value"%s*:%s*{(.-)}')
    if obj then
      local t  = obj:match('"type"%s*:%s*"([^"]+)"')
      local id = obj:match('"id"%s*:%s*(%d+)')
      if t and id then
        SetPortMemberOf(port, t == "trunk" and ("Trunk: " .. id) or ("Group: " .. id))
      elseif t == "none" then
        SetPortMemberOf(port, nil)
      end
    else
      local v = extractString(raw)
      if v then SetPortMemberOf(port, v) end
    end
    return true
  end

  if path == ("/poe/ports/" .. port .. "/indication") then
    local v = extractString(raw)
    if v then SetPortIndication(port, v) end
    return true
  end

  if path == ("/poe/ports/" .. port .. "/enabled") then
    local v = extractBool(raw)
    if v then SetPortPoeEnabled(port, v == "true") end
    return true
  end

  if path == ("/ports/port/" .. port .. "/rlinkx") then
    -- Per-port config: {"enabled": true/false}. We only learn disabled vs
    -- enabled here; the "active" (redundant) state comes from /rlinkx/ports/N/state.
    local obj = raw:match('"new_value"%s*:%s*{(.-)}')
    if obj then
      local enabledFlag = obj:match('"enabled"%s*:%s*(%a+)')
      -- Don't downgrade if we already know the port is "active"
      local current = getPortState(port).rlinkx
      if enabledFlag == "true" then
        if current ~= "active" then SetPortRlinkx(port, "enabled") end
      else
        SetPortRlinkx(port, "disabled")
      end
    end
    return true
  end

  if path == ("/rlinkx/ports/" .. port .. "/state") then
    -- State machine values: "disabled" / "non-redundant" / "redundant"
    local v = extractString(raw)
    if v then
      local mapped
      if     v == "redundant"     then mapped = "active"
      elseif v == "non-redundant" then mapped = "enabled"
      else                              mapped = "disabled"
      end
      SetPortRlinkx(port, mapped)
    end
    return true
  end

  if path:find("/link_speed") then
    local mode  = raw:match('"mode"%s*:%s*"([^"]+)"')
    local speed = raw:match('"speed"%s*:%s*%[%"([^"]+)"%]')

    if mode == "auto" then
      if speed == "all" or not speed then
        SetPortSpeed(port, "Auto")
      else
        SetPortSpeed(port, speed)
      end
    elseif mode == "fixed" and speed then
      SetPortSpeed(port, speed)
    end

    return true
  end

  return false
end

function parseNotification(raw)
  if state.verboseWs then log("parseNotification => " .. raw) end
  local path = extractPath(raw)
  if not path then return end
  if handleDevicePath(path, raw)       then return end
  if handleGroupPath(path, raw)        then return end
  if handlePortPath(path, raw)         then return end
  if handleSystemPath(path, raw)       then return end
  if handleFanPath(path, raw)          then return end
  if handlePowerPath(path, raw)        then return end
  if handleSpanningTreePath(path, raw) then return end
  if handleSnoopingPath(path, raw)     then return end
end

--------------------------------------------------------------------------------
-- Port state setters (STATE → UI)
--------------------------------------------------------------------------------
function SetPortLink(port, isOn)
  getPortState(port).link = isOn
  renderPortUI(port)
end

function SetPortEnabled(port, enabled)
  getPortState(port).enabled = enabled
  renderPortUI(port)
end

function SetPortMemberOf(port, textVal)
  getPortState(port).memberOf = textVal
  renderPortUI(port)
end

function SetPortIndication(port, textVal)
  getPortState(port).poe = textVal
  renderPortUI(port)
end

function SetPortRlinkx(port, stateString)
  getPortState(port).rlinkx = stateString
  renderPortUI(port)
end

function SetPortSpeed(port, label)
  local p = getPortState(port)
  p.speed          = SPEED_UI_MAP[label] or label
  p.lastValidSpeed = p.speed
  p.speedPending   = false
  renderPortUI(port)
end

function SetPortPoeEnabled(port, enabled)
  getPortState(port).poeEnabled = enabled
  renderPortUI(port)
end

--------------------------------------------------------------------------------
-- System / chassis setters
--------------------------------------------------------------------------------
local function setCtrlString(name, value)
  local c = Controls[name]
  if c then c.String = value end
end

local function setCtrlColor(name, color)
  local c = Controls[name]
  if c then c.Color = color end
end

function SetCaseTemp(v)
  setCtrlString("System.Case Temp", string.format("Case temp.: %s °C", tostring(v)))
end

function SetCpuTemp(v)
  setCtrlString("System.CPU Temp", string.format("CPU temp.: %s °C", tostring(v)))
end

function SetFanSpeed(id, v)
  setCtrlString("fan" .. id .. "_speed", string.format("Fan %d: %s rpm", id, tostring(v)))
end

function SetPsuStatus(id, status)
  local theme = getThemeColors()
  local bg
  if status == "good" or status == "ok" or status == "redundant" then
    bg = theme.badgeOkBg
  elseif status == "warning" then
    bg = theme.badgeWarnBg
  elseif status == "absent" or status == "" then
    bg = theme.badgeOffBg
  else
    bg = theme.badgeErrBg
  end
  setCtrlString("psu" .. id .. "_status", "PSU" .. id)
  setCtrlColor("psu" .. id .. "_status", rgbHex(bg))
end

function SetPsuPower(id, milliwatts)
  local watts = tonumber(milliwatts)
  if watts then
    -- API returns milliwatts
    watts = watts / 1000
    setCtrlString("psu" .. id .. "_power", string.format("%.1f W", watts))
  end
end

function SetCpuLoad1s(v)
  setCtrlString("System.CPU Load 1s", string.format("%s%% (1s)", tostring(v)))
end

function SetCpuLoad10s(v)
  setCtrlString("System.CPU Load 10s", string.format("%s%% (10s)", tostring(v)))
end

function SetBridgePriority(v)
  setCtrlString("RSTP.Bridge Priority", string.format("Bridge priority: %s", tostring(v)))
end

state.rootBridgeAddr = state.rootBridgeAddr or ""
state.rootBridgePri  = state.rootBridgePri  or ""

local function refreshRootBridge()
  if state.rootBridgeAddr ~= "" or state.rootBridgePri ~= "" then
    local addr = state.rootBridgeAddr ~= "" and state.rootBridgeAddr or "??"
    local pri  = state.rootBridgePri  ~= "" and state.rootBridgePri  or "?"
    setCtrlString("RSTP.Root Bridge", string.format("Root bridge: %s (priority: %s)", addr, pri))
  end
end

function SetRootBridgeAddress(addr)
  state.rootBridgeAddr = addr or ""
  refreshRootBridge()
end

function SetRootBridgePriority(pri)
  state.rootBridgePri = tostring(pri or "")
  refreshRootBridge()
end

function SetMrPorts(portList)
  -- Port.MR is a Button in the SVG overlay layout (top-right corner of each
  -- port). When set: black square with white border + "MR" text. When clear:
  -- transparent (no border showing).
  for p = 1, state.portCount do
    local c = Controls["Port.zMR " ..p]
    if c then
      c.Boolean = false
      c.Color = "#00000000"
      pcall(function() c.OffColor = "#00000000" end)
      pcall(function() c.StrokeColor = "#00000000" end)
      c.Legend = ""
    end
  end
  if type(portList) == "table" then
    for _, p in ipairs(portList) do
      local id = tonumber(p)
      local c = Controls["Port.zMR " ..id]
      if c then
        c.Boolean = true
        c.Color = "#101828"
        pcall(function() c.OffColor = "#101828" end)
        pcall(function() c.StrokeColor = "#FFFFFF" end)
        c.Legend = "MR"
      end
    end
  end
end

--------------------------------------------------------------------------------
-- WS path handlers for system/power/fans/spanning_tree/snooping
--------------------------------------------------------------------------------
function handleSystemPath(path, raw)
  if path == "/system/cpu_load" then
    local v = extractNumber(raw); if v then SetCpuLoad1s(v) end
    return true
  end
  if path == "/system/cpu_load_long" then
    local v = extractNumber(raw); if v then SetCpuLoad10s(v) end
    return true
  end
  if path == "/system/temperature/current" or path == "/temperatures/temperature/case/current" then
    local v = extractNumber(raw); if v then SetCaseTemp(v) end
    return true
  end
  if path == "/temperatures/temperature/cpu/current" then
    local v = extractNumber(raw); if v then SetCpuTemp(v) end
    return true
  end
  return false
end

function handleFanPath(path, raw)
  local id = path:match("^/fans/fan/(%d+)/speed$")
  if id then
    local v = extractNumber(raw); if v then SetFanSpeed(tonumber(id), v) end
    return true
  end
  local id2 = path:match("^/fans/fan/(%d+)/state$")
  if id2 then
    -- state not rendered yet; kept for future color coding
    return true
  end
  return false
end

function handlePowerPath(path, raw)
  local psu, field = path:match("^/power/psus/(psu%d+)/(.+)$")
  if not psu then return false end
  local id = tonumber(psu:match("(%d+)"))
  if field == "state" or field == "power_status" then
    local v = extractString(raw); if v then SetPsuStatus(id, v) end
    return true
  end
  if field == "power_usage" then
    local v = extractNumber(raw); if v then SetPsuPower(id, v) end
    return true
  end
  return false
end

function handleSpanningTreePath(path, raw)
  if path == "/spanning_tree/mst/0/bridge_priority" then
    local v = extractNumber(raw); if v then SetBridgePriority(v) end
    return true
  end
  if path == "/spanning_tree/mst/0/root_bridge_address" then
    local v = extractString(raw); if v then SetRootBridgeAddress(v) end
    return true
  end
  if path == "/spanning_tree/mst/0/root_bridge_priority" then
    local v = extractNumber(raw); if v then SetRootBridgePriority(v) end
    return true
  end
  return false
end

function handleSnoopingPath(path, raw)
  if path:find("/snooping/vlan/%d+/router_ports") then
    -- new_value is an array: "new_value":[3,5,7]
    local arr = raw:match('"new_value"%s*:%s*%[(.-)%]')
    local ports = {}
    if arr then
      for n in arr:gmatch("%d+") do ports[#ports+1] = tonumber(n) end
    end
    SetMrPorts(ports)
    return true
  end
  return false
end

--------------------------------------------------------------------------------
-- Device status (with offline pulse)
--------------------------------------------------------------------------------
offlinePulseTimer = nil
pulseOn = false

function SetDeviceStatus(status)
  local ctrl = Controls["Device.Status"]
  if not ctrl then return end

  if status == "online" then
    if offlinePulseTimer then
      offlinePulseTimer:Stop()
      offlinePulseTimer = nil
    end
    pulseOn = false
    ctrl.String = "Online"
    ctrl.Color  = "#00C800"
  elseif status == "offline" then
    ctrl.String = "Offline"
    if not offlinePulseTimer then
      offlinePulseTimer = Timer.New()
      offlinePulseTimer.EventHandler = function()
        pulseOn = not pulseOn
        ctrl.Color = pulseOn and "#C80000" or "#800000"
      end
      offlinePulseTimer:Start(0.5)
    end
  end
end

--------------------------------------------------------------------------------
-- Group label (color + badge)
--------------------------------------------------------------------------------
-- Custom groups (id > 20) and custom trunks (id > 1) live in reserved slots
-- assigned in id order by refreshCustomSlots(). state.customGroupSlot /
-- state.customTrunkSlot map id → slot control index.
function groupSlotFor(groupId)
  if groupId <= 20 then return groupId end
  return state.customGroupSlot and state.customGroupSlot[groupId]
end

function trunkSlotFor(trunkId)
  if trunkId == 1 then return 1 end
  return state.customTrunkSlot and state.customTrunkSlot[trunkId]
end

function refreshCustomSlots()
  state.customGroupSlot = {}
  state.customTrunkSlot = {}

  local customs = {}
  for _, g in ipairs(state.groupList or {}) do
    if g.id and not g.predefined then customs[#customs + 1] = g end
  end
  table.sort(customs, function(a, b) return a.id < b.id end)
  for i = 1, CUSTOM_GROUP_SLOTS do
    local slot  = 20 + i
    local ctrl  = Controls["group_label_" .. slot]
    local badge = Controls["group_id_badge_" .. slot]
    local g = customs[i]
    if g then
      state.customGroupSlot[g.id] = slot
      if ctrl then
        ctrl.String = g.name or ""
        ctrl.Color  = rgbHex(g.color)
        pcall(function() ctrl.IsInvisible = false end)
      end
      if badge then
        badge.String = tostring(g.id)
        badge.Color  = "#1A2238"
        pcall(function() badge.IsInvisible = false end)
      end
    else
      if ctrl then
        ctrl.String = ""
        ctrl.Color  = "#00000000"
        pcall(function() ctrl.IsInvisible = true end)
      end
      if badge then
        badge.String = ""
        badge.Color  = "#00000000"
        pcall(function() badge.IsInvisible = true end)
      end
    end
  end

  local trunks = {}
  for _, t in ipairs(state.trunkList or {}) do
    if t.id and not t.predefined then trunks[#trunks + 1] = t end
  end
  table.sort(trunks, function(a, b) return a.id < b.id end)
  for i = 1, CUSTOM_TRUNK_SLOTS do
    local slot  = 1 + i
    local ctrl  = Controls["trunk_label_" .. slot]
    local badge = Controls["trunk_id_badge_" .. slot]
    local t = trunks[i]
    if t then
      state.customTrunkSlot[t.id] = slot
      if ctrl then
        ctrl.String = t.name or ""
        ctrl.Color  = rgbHex(t.color)
        pcall(function() ctrl.IsInvisible = false end)
      end
      if badge then
        badge.String = tostring(t.id)
        badge.Color  = "#1A2238"
        pcall(function() badge.IsInvisible = false end)
      end
    else
      if ctrl then
        ctrl.String = ""
        ctrl.Color  = "#00000000"
        pcall(function() ctrl.IsInvisible = true end)
      end
      if badge then
        badge.String = ""
        badge.Color  = "#00000000"
        pcall(function() badge.IsInvisible = true end)
      end
    end
  end
end

function SetGroupLabel(groupId, name)
  local slot = groupSlotFor(groupId)
  if not slot then return end  -- custom group not placed yet; refreshCustomSlots will
  local ctrl = Controls["group_label_" .. slot]
  if not ctrl then return end

  ctrl.String = name

  local key = "Group: " .. groupId
  local color = (state.customColors and state.customColors[key]) or GROUP_COLORS[key]
  if color then
    ctrl.Color = rgbHex(color)
  else
    ctrl.Color = "#00000000"
  end

  local badgeCtrl = Controls["group_id_badge_" .. slot]
  if badgeCtrl then
    badgeCtrl.String = tostring(groupId)
    badgeCtrl.Color  = "#1A2238"
  end
end

function SetTrunkLabel(trunkId, name)
  local slot = trunkSlotFor(trunkId)
  if not slot then return end
  local ctrl = Controls["trunk_label_" .. slot]
  if not ctrl then return end

  ctrl.String = name

  local key = "Trunk: " .. trunkId
  local color = state.customColors and state.customColors[key]
  if color then
    ctrl.Color = rgbHex(color)
  else
    ctrl.Color = "#00000000"
  end

  local badgeCtrl = Controls["trunk_id_badge_" .. slot]
  if badgeCtrl then
    badgeCtrl.String = tostring(trunkId)
    badgeCtrl.Color  = "#1A2238"
  end
end

function updateGroupUI(groupId)
  -- Controls repaint themselves when their properties change; nothing to do.
end

--------------------------------------------------------------------------------
-- Group picker panel (main page): opened by a Port.Group cell click, lists
-- every group and trunk slot (the same slots as the Groups and Trunks page)
-- and PUTs the pick to /api/ports/port/N/member_of. The zPicker.* controls
-- are declared in controls.lua and placed by buildGroupPickerPanel
-- (layout.lua); everything here runs at runtime only.
--------------------------------------------------------------------------------
PICKER_SECTION_TITLES = { "Groups", "Custom groups", "Trunks", "Custom trunks" }

local function pickerControlNames()
  local names = { "zPicker.Bg", "zPicker.Title", "zPicker.None", "zPicker.Cancel" }
  for i = 1, #PICKER_SECTION_TITLES do names[#names + 1] = "zPicker.Label " .. i end
  for i = 1, 20 + CUSTOM_GROUP_SLOTS do names[#names + 1] = "zPicker.Group " .. i end
  for i = 1, 1 + CUSTOM_TRUNK_SLOTS do names[#names + 1] = "zPicker.Trunk " .. i end
  return names
end

local function setPickerVisible(name, visible)
  local ctrl = Controls[name]
  if ctrl then pcall(function() ctrl.IsInvisible = not visible end) end
end

function closeGroupPicker()
  state.pickerPort = nil
  for _, name in ipairs(pickerControlNames()) do setPickerVisible(name, false) end
end

-- One picker button: Legend = name (check mark on the port's current
-- membership), fill = the group/trunk color.
local function paintPickerItem(name, label, hex, isCurrent)
  local ctrl = Controls[name]
  if not ctrl then return end
  ctrl.Legend = isCurrent and (label .. " ✓") or label
  ctrl.Color  = hex
  pcall(function() ctrl.OffColor = hex end)
  setPickerVisible(name, true)
end

local function memberColorHex(key)
  local color = (state.customColors and state.customColors[key]) or GROUP_COLORS[key]
  return color and rgbHex(color) or PICKER_UNASSIGNED_HEX
end

function openGroupPicker(port)
  if state.baseIP == "" then return end
  state.pickerPort = port
  local current = getPortState(port).memberOf
  local theme   = getThemeColors()

  -- slot → id for every section (custom sections: inverse of refreshCustomSlots)
  state.pickerSlotGroupId = {}
  state.pickerSlotTrunkId = {}
  for i = 1, 20 do state.pickerSlotGroupId[i] = i end
  for id, slot in pairs(state.customGroupSlot or {}) do state.pickerSlotGroupId[slot] = id end
  state.pickerSlotTrunkId[1] = 1
  for id, slot in pairs(state.customTrunkSlot or {}) do state.pickerSlotTrunkId[slot] = id end

  paintPickerItem("zPicker.Bg", "", rgbHex(theme.cardFill), false)
  local title = Controls["zPicker.Title"]
  if title then
    title.String = string.format("Port %d: assign to a group or trunk", port)
    setPickerVisible("zPicker.Title", true)
  end
  for i, text in ipairs(PICKER_SECTION_TITLES) do
    local lbl = Controls["zPicker.Label " .. i]
    if lbl then
      lbl.String = text
      setPickerVisible("zPicker.Label " .. i, true)
    end
  end
  paintPickerItem("zPicker.None",   "None",   PICKER_UNASSIGNED_HEX, current == nil)
  paintPickerItem("zPicker.Cancel", "Cancel", rgbHex(theme.buttonOffColor), false)

  for slot = 1, 20 + CUSTOM_GROUP_SLOTS do
    local id, name = state.pickerSlotGroupId[slot], "zPicker.Group " .. slot
    if id then
      local key = "Group: " .. id
      paintPickerItem(name, memberOfDisplayName(key), memberColorHex(key), current == key)
    else
      setPickerVisible(name, false)
    end
  end
  for slot = 1, 1 + CUSTOM_TRUNK_SLOTS do
    local id, name = state.pickerSlotTrunkId[slot], "zPicker.Trunk " .. slot
    if id then
      local key = "Trunk: " .. id
      paintPickerItem(name, memberOfDisplayName(key), memberColorHex(key), current == key)
    else
      setPickerVisible(name, false)
    end
  end
end

-- kind = "group" | "trunk" | "none". Closes the panel, PUTs the new
-- membership and applies it locally on HTTP 200 (the WS member_of
-- notification and the REST reconcile confirm it afterwards).
function pickerAssign(kind, id)
  local port = state.pickerPort
  closeGroupPicker()
  if not port or state.baseIP == "" then return end
  local body = (kind == "none") and '{"type":"none"}'
            or string.format('{"type":"%s","id":%d}', kind, id)
  HttpClient.Upload {
    Url     = string.format("http://%s/api/ports/port/%d/member_of", state.baseIP, port),
    Method  = "PUT",
    Data    = body,
    Headers = MergeTables(
      { ["Content-Type"] = "application/json" },
      getAuthHeaders()
    ),
    EventHandler = function(_tbl, code, _body, err)
      log("PUT member_of port " .. port .. " " .. body .. " => HTTP " .. tostring(code) .. " " .. tostring(err or ""))
      if code == 200 then
        local value = nil
        if kind == "group" then value = "Group: " .. id end
        if kind == "trunk" then value = "Trunk: " .. id end
        SetPortMemberOf(port, value)
      end
    end,
  }
end

--------------------------------------------------------------------------------
-- Q-SYS tile appearance
--------------------------------------------------------------------------------
function GetColor(props)
  return { 15, 58, 83 }
end

function GetPrettyName(props)
  return PluginInfo.Name .. " v" .. PluginInfo.Version
end

-- SVG logos are referenced from layout.lua — expose them as globals
_G.LogoLuminex = LogoLuminex
_G.LogoPSU     = LogoPSU

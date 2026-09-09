local pc = state.portCount or 30

--------------------------------------------------------------------------------
-- Speed dropdown choices (API values — translated back to friendly labels
-- for display by SetPortSpeed via SPEED_UI_MAP)
--------------------------------------------------------------------------------
for p = 1, pc do
  local ctrl = Controls["Port.Speed " .. p]
  if ctrl then
    ctrl.Choices = {
      "Auto",
      "Disabled",
      "10gbps fdx",
      "2.5gbps fdx",
      "1gbps fdx",
      "100mbps fdx",
      "100mbps hdx",
      "10mbps fdx",
      "10mbps hdx",
    }
  end
end

--------------------------------------------------------------------------------
-- IP / connect / identify
--------------------------------------------------------------------------------
if Controls["Auth.IP Address"] then
  Controls["Auth.IP Address"].EventHandler = function(txt)
    state.baseIP = txt.String
  end
end

if Controls["Auth.Connect"] then
  Controls["Auth.Connect"].EventHandler = function(btn)
    if btn.Boolean then
      updateAuthStatus("")
      state.baseIP = Controls["Auth.IP Address"].String
      openWS(state.baseIP)
      btn.Boolean = false
    end
  end
end

if Controls["Auth.Identify"] then
  Controls["Auth.Identify"].EventHandler = function(btn)
    if btn.Boolean and state.baseIP ~= "" then
      HttpClient.Upload {
        Url     = string.format("http://%s/api/identify", state.baseIP),
        Method  = "PUT",
        Data    = '{"duration": 9}',
        Headers = MergeTables(
          { ["Content-Type"] = "application/json" },
          getAuthHeaders()
        ),
        EventHandler = function(_body, _status, _err) end,
      }
      btn.Boolean = false
    end
  end
end

--------------------------------------------------------------------------------
-- Port enable toggle
--------------------------------------------------------------------------------
for p = 1, pc do
  local ctrl = Controls["Port.Enable " .. p]
  if ctrl then
    ctrl.EventHandler = function()
      local newState = ctrl.Boolean
      HttpClient.Upload {
        Url     = string.format("http://%s/api/ports/port/%d/enabled", state.baseIP, p),
        Method  = "PUT",
        Data    = newState and "true" or "false",
        Headers = MergeTables(
          { ["Content-Type"] = "application/json" },
          getAuthHeaders()
        ),
        EventHandler = function(_body, code, _err)
          log("Port " .. p .. " enable set to " .. tostring(newState) .. " | HTTP " .. tostring(code))
        end,
      }
    end
  end
end

--------------------------------------------------------------------------------
-- PoE enable toggle
--------------------------------------------------------------------------------
for p = 1, pc do
  local ctrl = Controls["PoE.Toggle " .. p]
  if ctrl then
    ctrl.EventHandler = function()
      local newState = ctrl.Boolean
      HttpClient.Upload {
        Url     = string.format("http://%s/api/poe/ports/%d/enabled", state.baseIP, p),
        Method  = "PUT",
        Data    = newState and "true" or "false",
        Headers = MergeTables(
          { ["Content-Type"] = "application/json" },
          getAuthHeaders()
        ),
        EventHandler = function(_body, code, _err)
          log("PoE " .. p .. " enabled set to " .. tostring(newState) .. " | HTTP " .. tostring(code))
        end,
      }
    end
  end
end

--------------------------------------------------------------------------------
-- PoE bounce: disable PoE, wait 3s, re-enable
--------------------------------------------------------------------------------
for p = 1, pc do
  local bounceCtrl = Controls["PoE.Bounce " .. p]
  if bounceCtrl then
    bounceCtrl.EventHandler = function(ctrl)
      if not ctrl.Boolean then return end
      local port = p
      local url = string.format("http://%s/api/poe/ports/%d/enabled", state.baseIP, port)

      HttpClient.Upload {
        Url     = url,
        Method  = "PUT",
        Data    = "false",
        Headers = MergeTables(
          { ["Content-Type"] = "application/json" },
          getAuthHeaders()
        ),
        EventHandler = function(_, code, _err)
          log("PoE bounce port " .. port .. " off | HTTP " .. tostring(code))
        end,
      }

      Timer.CallAfter(function()
        HttpClient.Upload {
          Url     = url,
          Method  = "PUT",
          Data    = "true",
          Headers = MergeTables(
            { ["Content-Type"] = "application/json" },
            getAuthHeaders()
          ),
          EventHandler = function(_, code, _err)
            log("PoE bounce port " .. port .. " on | HTTP " .. tostring(code))
          end,
        }
      end, 3)
    end
  end
end

--------------------------------------------------------------------------------
-- Port legend edit
--------------------------------------------------------------------------------
for p = 1, pc do
  local legendCtrl = Controls["Port.Legend Edit " .. p]
  if legendCtrl then
    legendCtrl.EventHandler = function(ctrl)
      local newVal = ctrl.String
      HttpClient.Upload {
        Url     = string.format("http://%s/api/ports/port/%d/legend", state.baseIP, p),
        Method  = "PUT",
        Data    = qsc_json.encode(newVal),
        Headers = MergeTables(
          { ["Content-Type"] = "application/json" },
          getAuthHeaders()
        ),
        EventHandler = function(_body, _status, _err) end,
      }
    end
  end
end

--------------------------------------------------------------------------------
-- RLinkX toggle
--------------------------------------------------------------------------------
for p = 1, pc do
  local toggleCtrl = Controls["RLinkX.Toggle " .. p]
  if toggleCtrl then
    toggleCtrl.EventHandler = function(ctrl)
      local enabled = ctrl.Boolean
      HttpClient.Upload {
        Url     = string.format("http://%s/api/ports/port/%d/rlinkx", state.baseIP, p),
        Method  = "PUT",
        Data    = qsc_json.encode({ enabled = enabled }),
        Headers = MergeTables(
          { ["Content-Type"] = "application/json" },
          getAuthHeaders()
        ),
        EventHandler = function(_body, _status, _err)
          log("RLinkX PUT port " .. p .. " => " .. tostring(enabled))
        end,
      }
    end
  end
end

--------------------------------------------------------------------------------
-- Speed dropdown (with pending state + REST rollback; WS confirms success)
--------------------------------------------------------------------------------
for p = 1, pc do
  local dropdown = Controls["Port.Speed " .. p]
  if dropdown then
    dropdown.EventHandler = function(ctrl)
      local val    = ctrl.String
      local port   = p
      local pstate = getPortState(port)

      if val == "Disabled" then
        HttpClient.Upload {
          Url     = string.format("http://%s/api/ports/port/%d/enabled", state.baseIP, port),
          Method  = "PUT",
          Data    = "false",
          Headers = MergeTables(
            { ["Content-Type"] = "application/json" },
            getAuthHeaders()
          ),
          EventHandler = function(_, status, err)
            log("Disabled port " .. port ..
                " => status: " .. tostring(status) ..
                ", err: " .. tostring(err))
          end,
        }
        return
      end

      -- Ensure port is enabled before setting speed
      HttpClient.Upload {
        Url     = string.format("http://%s/api/ports/port/%d/enabled", state.baseIP, port),
        Method  = "PUT",
        Data    = "true",
        Headers = MergeTables(
          { ["Content-Type"] = "application/json" },
          getAuthHeaders()
        ),
        EventHandler = function(_, status, err)
          log("Enabled port " .. port ..
              " => status: " .. tostring(status) ..
              ", err: " .. tostring(err))
        end,
      }

      pstate.speedPending = true
      renderPortUI(port)

      local payload
      if val == "Auto" then
        payload = { mode = "auto", speed = { "all" } }
      elseif val == "1gbps fdx" then
        payload = { mode = "auto", speed = { "1gbps fdx" } }
      else
        payload = { mode = "fixed", speed = { val } }
      end

      HttpClient.Upload {
        Url     = string.format("http://%s/api/ports/port/%d/link_speed", state.baseIP, port),
        Method  = "PUT",
        Data    = qsc_json.encode(payload),
        Headers = MergeTables(
          { ["Content-Type"] = "application/json" },
          getAuthHeaders()
        ),
        EventHandler = function(_, status, err)
          log("Set link_speed on port " .. port ..
              " => " .. qsc_json.encode(payload) ..
              " | status: " .. tostring(status) ..
              ", err: " .. tostring(err))

          if status ~= 200 then
            log("Link speed rejected on port " .. port)
            pstate.speedPending = false
            if pstate.lastValidSpeed then
              pstate.speed = pstate.lastValidSpeed
            end
            renderPortUI(port)
          end
          -- On success WS confirms via SetPortSpeed()
        end,
      }
    end
  end
end

--------------------------------------------------------------------------------
-- Identify — device-level (logo click) and per-port (port number click).
--------------------------------------------------------------------------------
local function identifyDevice()
  if state.baseIP == "" then return end
  HttpClient.Upload {
    Url     = string.format("http://%s/api/identify", state.baseIP),
    Method  = "PUT",
    Data    = '{"duration": 9}',
    Headers = MergeTables(
      { ["Content-Type"] = "application/json" },
      getAuthHeaders()
    ),
    EventHandler = function(_b, status, err)
      log("Identify device => status: " .. tostring(status) .. ", err: " .. tostring(err))
    end,
  }
end

local function identifyPort(port)
  if state.baseIP == "" then return end
  local payload = string.format('{"duration":9,"port_numbers":[%d]}', port)
  HttpClient.Upload {
    Url     = string.format("http://%s/api/port_identify", state.baseIP),
    Method  = "PUT",
    Data    = payload,
    Headers = MergeTables(
      { ["Content-Type"] = "application/json" },
      getAuthHeaders()
    ),
    EventHandler = function(_b, status, err)
      log("Identify port " .. port .. " => status: " .. tostring(status) .. ", err: " .. tostring(err))
    end,
  }
end

local idBtn = Controls["Device.Identify"]
if idBtn then
  idBtn.EventHandler = function(c)
    if c.Boolean then identifyDevice() end
  end
end

for p = 1, pc do
  local b = Controls["Port.Identify " .. p]
  if b then
    b.EventHandler = function(c)
      if c.Boolean then identifyPort(p) end
    end
  end
end

log("Enjoy")

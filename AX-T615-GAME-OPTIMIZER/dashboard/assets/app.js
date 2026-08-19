/* Step 12 design contract: Calibrated Instrument Panel — browser code renders only validated snapshots; no client-side decision or control logic exists. */
(() => {
  "use strict";

  const UNKNOWN = "UNKNOWN";
  const input = document.getElementById("snapshotInput");
  const fileStatus = document.getElementById("fileStatus");
  const byId = (id) => document.getElementById(id);
  const text = (id, value, fallback = "Unavailable") => { const node = byId(id); if (node) node.textContent = known(value) ? String(value) : fallback; };
  const known = (value) => value !== undefined && value !== null && value !== "" && String(value).toUpperCase() !== UNKNOWN && String(value).toUpperCase() !== "UNAVAILABLE";
  const label = (value, fallback = "Unavailable") => known(value) ? String(value).replaceAll("-", " ").replaceAll("_", " ") : fallback;
  const display = (value, suffix = "") => known(value) ? `${value}${suffix}` : "—";
  const list = (value) => known(value) ? String(value).split(",").map((item) => item.trim()).filter(Boolean) : [];

  const empty = () => ({
    schema: "1", read_only: true, source: "no-snapshot", evidence: {}, decision: {}, orchestrator: {}, session: {}, profiles: [], safety: {}
  });

  function safeSnapshot(raw) {
    if (!raw || typeof raw !== "object" || Array.isArray(raw)) throw new Error("Snapshot must be a JSON object.");
    const snapshot = empty();
    ["evidence", "decision", "orchestrator", "session", "safety"].forEach((section) => {
      if (raw[section] !== undefined && (!raw[section] || typeof raw[section] !== "object" || Array.isArray(raw[section]))) throw new Error(`Invalid ${section} section.`);
      snapshot[section] = raw[section] || {};
    });
    snapshot.schema = raw.schema;
    snapshot.read_only = raw.read_only === true || raw.read_only === "YES";
    snapshot.source = typeof raw.source === "string" ? raw.source : "untrusted snapshot";
    snapshot.generated_at = typeof raw.generated_at === "string" ? raw.generated_at : UNKNOWN;
    if (raw.profiles !== undefined && !Array.isArray(raw.profiles)) throw new Error("Invalid profiles section.");
    snapshot.profiles = Array.isArray(raw.profiles) ? raw.profiles.filter((profile) => profile && typeof profile === "object") : [];
    if (!snapshot.read_only) throw new Error("Snapshot is not marked read-only and was rejected.");
    return snapshot;
  }

  function stateTone(state) {
    const value = String(state || "").toLowerCase();
    if (value.includes("thermal") || value.includes("battery") || value.includes("protection")) return "protected";
    if (value.includes("conservative") || value.includes("recovery")) return "guarded";
    if (value.includes("performance") || value.includes("balanced")) return "ready";
    return "unknown";
  }

  function renderList(id, items, fallback) {
    const node = byId(id); if (!node) return; node.replaceChildren();
    (items.length ? items : [fallback]).forEach((item) => { const li = document.createElement("li"); li.textContent = label(item, fallback); node.append(li); });
  }

  function renderEvidence(value) {
    const target = byId("evidenceKey"); if (!target) return; target.replaceChildren();
    list(value).slice(0, 9).forEach((entry) => { const chip = document.createElement("span"); chip.textContent = entry.replaceAll(":", ": "); target.append(chip); });
  }

  function renderProfiles(profiles) {
    const target = byId("profilesList"); if (!target) return; target.replaceChildren();
    if (!profiles.length) { const item = document.createElement("li"); item.textContent = "Unavailable"; target.append(item); return; }
    profiles.forEach((profile) => {
      const item = document.createElement("li");
      const name = known(profile.name) ? profile.name : profile.id;
      item.textContent = `${name || "Unnamed"} — ${label(profile.mode, "policy unavailable")}`;
      target.append(item);
    });
  }

  function renderTimeline(history) {
    const line = byId("trendLine"); const emptyLabel = byId("chartEmpty"); const chart = byId("trendChart");
    if (!Array.isArray(history) || history.length < 2 || history.some((point) => typeof point !== "number" || !Number.isFinite(point))) { line.setAttribute("points", ""); emptyLabel.hidden = false; chart.setAttribute("aria-label", "No telemetry history"); return; }
    const min = Math.min(...history); const max = Math.max(...history); const span = max - min || 1;
    const points = history.map((point, index) => `${(index / (history.length - 1)) * 560},${150 - ((point - min) / span) * 115}`).join(" ");
    line.setAttribute("points", points); emptyLabel.hidden = true; chart.setAttribute("aria-label", "Bounded-session telemetry history");
  }

  function render(raw) {
    const snapshot = safeSnapshot(raw); const e = snapshot.evidence; const d = snapshot.decision; const o = snapshot.orchestrator; const s = snapshot.session; const safety = snapshot.safety;
    const state = d.state || o.state; const tone = stateTone(state);
    document.body.dataset.state = tone;
    text("sourceLabel", snapshot.source === "no-snapshot" ? "No snapshot loaded" : "Safe snapshot loaded");
    text("updatedAt", snapshot.generated_at);
    text("modeLabel", snapshot.read_only ? "READ-ONLY" : "REJECTED");
    text("evidenceHeader", label(d.evidence_status, "NO DATA"), "NO DATA");
    text("blockedOperationHeader", safety.forbidden_actions_blocked === "YES" ? "UNSAFE OPERATIONS BLOCKED" : "AWAITING VERIFIED SNAPSHOT", "AWAITING VERIFIED SNAPSHOT");
    text("postureValue", label(d.safety_classification, "Awaiting evidence"));
    text("postureState", label(state, "NO DATA"), "NO DATA");
    text("recommendationState", label(state)); text("priorityChip", label(d.priority, "NO PRIORITY"), "NO PRIORITY");
    text("recommendationReason", d.reason, "No safe telemetry snapshot has been loaded. VEGAS-inject will not infer device values.");
    text("confidenceValue", label(d.confidence)); text("recoveryValue", d.recovery_conditions); text("actionsValue", label(d.recommended_actions));
    text("sessionStatus", label(s.status, "NOT DETECTED"), "NOT DETECTED"); text("gameName", e.game || s.game, "No active game"); text("packageName", e.package, "Package unavailable"); text("profileValue", e.profile || s.selected_profile); text("profilePaperValue", e.profile || s.selected_profile); text("orchestratorValue", label(o.state)); text("stableSamplesValue", o.stable_samples); text("sessionDurationValue", s.duration);
    text("cpuValue", display(e.cpu_utilization, "%"), "—"); text("cpuState", label(e.cpu_state)); text("gpuValue", display(e.gpu_utilization, "%"), "—"); text("gpuState", label(e.gpu_state)); text("memoryValue", display(e.memory_usage_percent, "%"), "—"); text("memoryState", label(e.memory_state)); text("thermalValue", display(e.thermal_temp_c, "°C"), "—"); text("thermalState", label(e.thermal_state)); text("batteryValue", display(e.battery_percent, "%"), "—"); text("batteryState", label(e.charging_state)); text("fpsValue", display(e.fps, " FPS"), "—"); text("fpsState", label(e.fps_trend));
    ["cpu","gpu","memory","thermal","battery","fps"].forEach((metric) => { const card = byId(`${metric}Value`)?.closest(".metric-card"); if (card) card.dataset.known = known(e[metric === "fps" ? "fps" : metric === "memory" ? "memory_usage_percent" : metric === "thermal" ? "thermal_temp_c" : metric === "battery" ? "battery_percent" : `${metric}_utilization`]); });
    text("thermalPeakValue", display(e.thermal_peak_c, "°C")); text("thermalTrendValue", label(e.thermal_trend, "No thermal trend"), "No thermal trend"); text("batteryHealthValue", label(e.battery_health)); text("batteryTemperatureValue", known(e.battery_temp_c) ? `${e.battery_temp_c}°C` : "Temperature unavailable"); text("voltageValue", display(e.voltage_mv, " mV")); text("currentValue", display(e.current_ma, " mA")); text("drainValue", display(e.drain_rate, "%/h")); text("powerStateValue", label(e.power_state, "Power state unavailable"), "Power state unavailable");
    text("frameTimeValue", display(e.frame_time_ms, " ms")); text("pacingValue", label(e.frame_pacing)); text("powerValue", display(e.estimated_watts, " W")); text("timelineDescription", Array.isArray(raw.history) && raw.history.length ? "Bounded-session samples supplied by the exported snapshot." : "No bounded-session history was included in this snapshot.");
    text("evidenceSummary", d.evidence_summary, "No evidence summary available."); renderEvidence(d.evidence_summary); renderList("actionsList", list(d.recommended_actions), "Unavailable"); text("recoveryState", label(d.safety_classification, "Not assessed"), "Not assessed"); text("recoveryDetail", d.recovery_conditions, "Load a normalized VEGAS-inject snapshot to see the current recovery condition.");
    text("previousStateValue", o.previous_state); text("lifecycleValue", label(o.lifecycle)); text("evidenceStatusValue", label(d.evidence_status)); text("policyDecisionValue", label(state)); text("guardStatus", safety.forbidden_actions_blocked === "YES" ? "Safety guard active" : "Safety status unavailable"); text("guardDetail", safety.forbidden_actions_blocked === "YES" ? "Unsafe action classes remain blocked by policy." : "Load a validated snapshot to confirm the core safety guard."); renderList("blockedActions", list(safety.blocked_actions), "Unavailable until evidence is loaded"); renderProfiles(snapshot.profiles);
    const dot = byId("recommendationDot"); if (dot) dot.dataset.tone = tone; renderTimeline(raw.history);
  }

  input.addEventListener("change", (event) => {
    const [file] = event.target.files || []; if (!file) return;
    if (file.size > 1024 * 1024) { fileStatus.textContent = "Snapshot rejected: maximum size is 1 MB."; input.value = ""; return; }
    const reader = new FileReader();
    reader.onload = () => { try { render(JSON.parse(String(reader.result))); fileStatus.textContent = `Loaded read-only snapshot: ${file.name}`; } catch (error) { render(empty()); fileStatus.textContent = `Snapshot rejected: ${error.message}`; } finally { input.value = ""; } };
    reader.onerror = () => { fileStatus.textContent = "Snapshot could not be read."; input.value = ""; };
    reader.readAsText(file);
  });
  byId("resetButton").addEventListener("click", () => { render(empty()); fileStatus.textContent = "View cleared. No telemetry is retained by the dashboard."; });
  render(empty());
})();

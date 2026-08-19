/* Dashboard/UI v2 design contract: render validated, read-only snapshot data only; no browser-side decision, plugin execution, shell bridge, or hardware-control logic exists. */
(() => {
  "use strict";

  const UNKNOWN = "UNKNOWN";
  const EXPORTED_SNAPSHOT_URL = "data/current-snapshot.json";
  const input = document.getElementById("snapshotInput");
  const fileStatus = document.getElementById("fileStatus");
  const byId = (id) => document.getElementById(id);
  const known = (value) => value !== undefined && value !== null && value !== "" && String(value).toUpperCase() !== UNKNOWN && String(value).toUpperCase() !== "UNAVAILABLE";
  const text = (id, value, fallback = "Unavailable") => { const node = byId(id); if (node) node.textContent = known(value) ? String(value) : fallback; };
  const yes = (value) => value === true || String(value).toUpperCase() === "YES";
  const label = (value, fallback = "Unavailable") => known(value) ? String(value).replaceAll("-", " ").replaceAll("_", " ") : fallback;
  const display = (value, suffix = "") => known(value) ? `${value}${suffix}` : "—";
  const list = (value) => known(value) ? String(value).split(",").map((item) => item.trim()).filter(Boolean) : [];
  const blocked = (value) => value === false || yes(value) ? "BLOCKED" : "UNKNOWN";

  const empty = () => ({
    schema: "1", read_only: true, source: "no-snapshot", evidence: {}, decision: {}, orchestrator: {}, session: {}, profiles: [], plugins: {}, plugin_health: {}, safety: {}, version: UNKNOWN
  });

  function safeSnapshot(raw) {
    if (!raw || typeof raw !== "object" || Array.isArray(raw)) throw new Error("Snapshot must be a JSON object.");
    const unified = raw.product === "VEGAS-inject";
    const gaming = unified ? raw.gaming : raw;
    if (!gaming || typeof gaming !== "object" || Array.isArray(gaming)) throw new Error("Invalid gaming section.");
    if (unified && (!raw.system || typeof raw.system !== "object" || Array.isArray(raw.system))) throw new Error("Invalid system section.");
    if (unified && (!raw.performance || typeof raw.performance !== "object" || Array.isArray(raw.performance))) throw new Error("Invalid performance section.");
    const snapshot = empty();
    ["evidence", "decision", "orchestrator", "session", "plugins", "safety"].forEach((section) => {
      if (gaming[section] !== undefined && (!gaming[section] || typeof gaming[section] !== "object" || Array.isArray(gaming[section]))) throw new Error(`Invalid ${section} section.`);
      snapshot[section] = gaming[section] || {};
    });
    snapshot.schema = raw.schema || gaming.schema;
    snapshot.read_only = raw.read_only === true || raw.read_only === "YES";
    snapshot.source = unified ? (typeof raw.source === "string" ? raw.source : "VEGAS-inject unified snapshot") : (typeof raw.source === "string" ? raw.source : "untrusted snapshot");
    snapshot.generated_at = typeof raw.generated_at === "string" ? raw.generated_at : UNKNOWN;
    snapshot.version = unified && typeof raw.version === "string" ? raw.version : UNKNOWN;
    if (gaming.profiles !== undefined && !Array.isArray(gaming.profiles)) throw new Error("Invalid profiles section.");
    snapshot.profiles = Array.isArray(gaming.profiles) ? gaming.profiles.filter((profile) => profile && typeof profile === "object") : [];
    snapshot.unified = unified;
    snapshot.product = unified ? raw.product : "VEGAS-inject";
    snapshot.plugin_count = unified && raw.plugins && typeof raw.plugins === "object" && !Array.isArray(raw.plugins) ? Object.keys(raw.plugins).length : 3;
    snapshot.plugin_health = unified && raw.plugins && typeof raw.plugins === "object" && !Array.isArray(raw.plugins) ? raw.plugins : {};
    const evidenceEngine = unified ? raw.evidence_engine : gaming.evidence_engine;
    if (evidenceEngine !== undefined && (!evidenceEngine || typeof evidenceEngine !== "object" || Array.isArray(evidenceEngine))) throw new Error("Invalid evidence engine section.");
    snapshot.evidence_engine = evidenceEngine || {};
    if (unified) {
      snapshot.plugins = { system_observer: raw.system, performance_observer: raw.performance };
      snapshot.safety = { ...(gaming.safety || {}), ...(raw.safety || {}) };
    }
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

  function renderPluginHealth(plugins) {
    const target = byId("pluginHealthGrid"); if (!target) return; target.replaceChildren();
    const pluginIds = ["ax-t615-game-optimizer", "system-observer", "performance-observer"];
    const available = pluginIds.filter((id) => plugins[id] && typeof plugins[id] === "object");
    if (!available.length) { const note = document.createElement("p"); note.className = "plugin-health-empty"; note.textContent = "Plugin health is unavailable until a unified snapshot is loaded."; target.append(note); return; }
    available.forEach((id) => {
      const plugin = plugins[id];
      const card = document.createElement("article"); card.className = "plugin-health-card";
      const title = document.createElement("h3"); title.textContent = known(plugin.name) ? plugin.name : id;
      const status = document.createElement("p"); status.className = "plugin-health-state"; status.textContent = `${label(plugin.lifecycle, "UNKNOWN")} / ${label(plugin.availability, "UNAVAILABLE")}`;
      const facts = document.createElement("dl");
      [["Enabled", label(plugin.availability, "UNKNOWN")], ["Metadata", label(plugin.metadata_valid, "UNKNOWN")], ["Read-only", label(plugin.read_only, "UNKNOWN")], ["Writes", label(plugin.hardware_writes, "UNKNOWN")], ["Source", plugin.source], ["Operations", plugin.supported_operations]].forEach(([term, value]) => {
        const wrap = document.createElement("div"); const dt = document.createElement("dt"); const dd = document.createElement("dd");
        dt.textContent = term; dd.textContent = known(value) ? String(value) : "Unavailable"; wrap.append(dt, dd); facts.append(wrap);
      });
      card.append(title, status, facts); target.append(card);
    });
  }

  function renderTimeline(history) {
    const line = byId("trendLine"); const emptyLabel = byId("chartEmpty"); const chart = byId("trendChart");
    if (!Array.isArray(history) || history.length < 2 || history.some((point) => typeof point !== "number" || !Number.isFinite(point))) { line.setAttribute("points", ""); emptyLabel.hidden = false; chart.setAttribute("aria-label", "No telemetry history"); return; }
    const min = Math.min(...history); const max = Math.max(...history); const span = max - min || 1;
    const points = history.map((point, index) => `${(index / (history.length - 1)) * 560},${150 - ((point - min) / span) * 115}`).join(" ");
    line.setAttribute("points", points); emptyLabel.hidden = true; chart.setAttribute("aria-label", "Bounded-session telemetry history");
  }

  function renderEvidenceTrends(trends) {
    const target = byId("evidenceTrendList"); if (!target) return; target.replaceChildren();
    const entries = trends && typeof trends === "object" && !Array.isArray(trends) ? Object.entries(trends).slice(0, 9) : [];
    (entries.length ? entries : [["trend", "UNAVAILABLE"]]).forEach(([metric, trend]) => { const item = document.createElement("li"); item.textContent = `${label(metric, "Metric")}: ${label(trend, "Unavailable")}`; target.append(item); });
  }

  function render(raw) {
    const snapshot = safeSnapshot(raw); const e = snapshot.evidence; const d = snapshot.decision; const o = snapshot.orchestrator; const s = snapshot.session; const safety = snapshot.safety; const engine = snapshot.evidence_engine && typeof snapshot.evidence_engine === "object" ? snapshot.evidence_engine : {}; const engineQuality = engine.quality && typeof engine.quality === "object" ? engine.quality : {}; const engineHistory = engine.history && typeof engine.history === "object" ? engine.history : {}; const engineMetrics = engine.metrics && typeof engine.metrics === "object" ? engine.metrics : {}; const engineThermal = engineMetrics.thermal_temperature && typeof engineMetrics.thermal_temperature === "object" ? engineMetrics.thermal_temperature : {};
    const observer = snapshot.plugins.system_observer && typeof snapshot.plugins.system_observer === "object" ? snapshot.plugins.system_observer : {}; const observerPlugin = observer.plugin && typeof observer.plugin === "object" ? observer.plugin : {}; const observerSystem = observer.system && typeof observer.system === "object" ? observer.system : {};
    const performanceObserver = snapshot.plugins.performance_observer && typeof snapshot.plugins.performance_observer === "object" ? snapshot.plugins.performance_observer : {}; const performancePlugin = performanceObserver.plugin && typeof performanceObserver.plugin === "object" ? performanceObserver.plugin : {}; const performanceEvidence = performanceObserver.evidence && typeof performanceObserver.evidence === "object" ? performanceObserver.evidence : {}; const performanceCpu = performanceEvidence.cpu && typeof performanceEvidence.cpu === "object" ? performanceEvidence.cpu : {}; const performanceGpu = performanceEvidence.gpu && typeof performanceEvidence.gpu === "object" ? performanceEvidence.gpu : {}; const performanceMemory = performanceEvidence.memory && typeof performanceEvidence.memory === "object" ? performanceEvidence.memory : {}; const performanceThermal = performanceEvidence.thermal && typeof performanceEvidence.thermal === "object" ? performanceEvidence.thermal : {}; const performanceFps = performanceEvidence.fps && typeof performanceEvidence.fps === "object" ? performanceEvidence.fps : {}; const performancePower = performanceEvidence.power && typeof performanceEvidence.power === "object" ? performanceEvidence.power : {};
    const state = d.state || o.state; const tone = stateTone(state);
    document.body.dataset.state = tone;
    text("sourceLabel", snapshot.source === "no-snapshot" ? "No snapshot loaded" : "Read-only snapshot loaded"); text("updatedAt", snapshot.generated_at); text("versionLabel", snapshot.version, "—"); text("modeLabel", snapshot.read_only ? "READ-ONLY" : "REJECTED");
    text("unifiedProduct", snapshot.product, "VEGAS-inject"); text("unifiedPluginCount", `${snapshot.plugin_count} REGISTERED`, "3 REGISTERED"); text("unifiedControl", "NONE", "NONE"); text("evidenceHeader", label(d.evidence_status, "NO DATA"), "NO DATA"); text("blockedOperationHeader", yes(safety.forbidden_actions_blocked) ? "UNSAFE OPERATIONS BLOCKED" : "AWAITING VERIFIED SNAPSHOT", "AWAITING VERIFIED SNAPSHOT");
    text("postureValue", label(d.safety_classification, "Awaiting evidence")); text("postureState", label(state, "NO DATA"), "NO DATA"); text("recommendationState", label(state)); text("priorityChip", label(d.priority, "NO PRIORITY"), "NO PRIORITY"); text("recommendationReason", d.reason, "No safe telemetry snapshot has been loaded. VEGAS-inject will not infer device values."); text("confidenceValue", label(d.confidence)); text("recoveryValue", d.recovery_conditions); text("actionsValue", label(d.recommended_actions));
    text("sessionStatus", label(s.status, "NOT DETECTED"), "NOT DETECTED"); text("gameName", e.game || s.game, "No active game"); text("packageName", e.package, "Package unavailable"); text("profileValue", e.profile || s.selected_profile, "UNKNOWN"); text("profilePaperValue", e.profile || s.selected_profile, "UNKNOWN"); text("orchestratorValue", label(o.state, "UNKNOWN"), "UNKNOWN"); text("sessionFpsValue", display(e.fps, " FPS"), "UNKNOWN"); text("sessionFrameTimeValue", display(e.frame_time_ms, " ms"), "UNKNOWN"); text("sessionFramePacingValue", label(e.frame_pacing, "UNKNOWN"), "UNKNOWN"); text("sessionFpsTrendValue", label(e.fps_trend, "UNKNOWN"), "UNKNOWN"); text("stableSamplesValue", o.stable_samples, "UNKNOWN"); text("sessionDurationValue", s.duration, "UNKNOWN");
    text("cpuValue", display(e.cpu_utilization, "%"), "UNKNOWN"); text("cpuState", label(e.cpu_state, "UNKNOWN"), "UNKNOWN"); text("gpuValue", display(e.gpu_utilization, "%"), "UNKNOWN"); text("gpuState", label(e.gpu_state, "UNKNOWN"), "UNKNOWN"); text("memoryValue", display(e.memory_usage_percent, "%"), "UNKNOWN"); text("memoryState", label(e.memory_state, "UNKNOWN"), "UNKNOWN"); text("thermalValue", display(e.thermal_temp_c, "°C"), "UNKNOWN"); text("thermalState", label(e.thermal_state, "UNKNOWN"), "UNKNOWN"); text("batteryValue", display(e.battery_percent, "%"), "UNKNOWN"); text("batteryState", label(e.charging_state, "UNKNOWN"), "UNKNOWN"); text("powerMetricValue", display(e.estimated_watts, " W"), "UNKNOWN"); text("powerMetricState", label(e.power_state, "UNKNOWN"), "UNKNOWN");
    ["cpu", "gpu", "memory", "thermal", "battery", "fps"].forEach((metric) => { const card = byId(`${metric}Value`)?.closest(".metric-card"); if (card) card.dataset.known = known(e[metric === "fps" ? "fps" : metric === "memory" ? "memory_usage_percent" : metric === "thermal" ? "thermal_temp_c" : metric === "battery" ? "battery_percent" : `${metric}_utilization`]); });
    text("thermalPeakValue", display(e.thermal_peak_c, "°C"), "UNKNOWN"); text("thermalTrendValue", label(e.thermal_trend, "UNKNOWN"), "UNKNOWN"); text("batteryHealthValue", label(e.battery_health, "UNKNOWN"), "UNKNOWN"); text("batteryTemperatureValue", known(e.battery_temp_c) ? `${e.battery_temp_c}°C` : "UNKNOWN"); text("voltageValue", display(e.voltage_mv, " mV"), "UNKNOWN"); text("currentValue", display(e.current_ma, " mA"), "UNKNOWN"); text("drainValue", display(e.drain_rate, "%/h"), "UNKNOWN"); text("powerStateValue", label(e.power_state, "UNKNOWN"), "UNKNOWN");
    text("frameTimeValue", display(e.frame_time_ms, " ms"), "UNKNOWN"); text("pacingValue", label(e.frame_pacing, "UNKNOWN"), "UNKNOWN"); text("powerValue", display(e.estimated_watts, " W"), "UNKNOWN"); text("timelineDescription", Array.isArray(raw.history) && raw.history.length ? "Bounded-session samples supplied by the exported snapshot." : "No bounded-session history was included in this snapshot."); text("evidenceEngineQuality", label(engineQuality.classification, "UNKNOWN"), "UNKNOWN"); text("evidenceEngineFreshness", label(engine.freshness || engineQuality.freshness || d.evidence_freshness, "UNKNOWN"), "UNKNOWN"); text("evidenceEngineProvenance", engine.provenance, "Unavailable"); text("evidenceEngineConfidence", label(engineThermal.confidence, "UNKNOWN"), "UNKNOWN"); text("evidenceEngineFallback", label(engineQuality.fallback_required || d.conservative_fallback_required, "UNKNOWN"), "UNKNOWN"); text("evidenceEngineFallbackReason", engineQuality.fallback_reason || d.conservative_fallback_reason, "No fallback rationale available."); text("evidenceEngineConditions", label(engineQuality.conditions || d.evidence_conditions, "NONE"), "NONE"); text("evidenceEngineHistory", known(engineHistory.retained_samples) ? `${engineHistory.retained_samples} / ${engineHistory.maximum_samples || "?"} samples` : "Unavailable"); renderEvidenceTrends(engineHistory.trends);
    text("evidenceSummary", d.evidence_summary, "No evidence summary available."); renderEvidence(d.evidence_summary); renderList("actionsList", list(d.recommended_actions), "Unavailable"); text("recoveryState", label(d.safety_classification, "Not assessed"), "Not assessed"); text("recoveryDetail", d.recovery_conditions, "Load a normalized VEGAS-inject snapshot to see the current recovery condition."); text("previousStateValue", o.previous_state, "UNKNOWN"); text("lifecycleValue", label(o.lifecycle, "UNKNOWN"), "UNKNOWN"); text("evidenceStatusValue", label(d.evidence_status, "UNKNOWN"), "UNKNOWN"); text("policyDecisionValue", label(state, "UNKNOWN"), "UNKNOWN"); text("guardStatus", yes(safety.forbidden_actions_blocked) ? "Safety guard active" : "Safety status unavailable"); text("guardDetail", yes(safety.forbidden_actions_blocked) ? "Unsafe action classes remain blocked by policy; hardware control capabilities are none." : "Load a validated snapshot to confirm the core safety guard."); text("safetyReadOnly", snapshot.read_only ? "ENABLED" : "UNKNOWN", "UNKNOWN"); text("safetyHardwareWrites", blocked(safety.hardware_writes), "UNKNOWN"); text("safetyProcessControl", blocked(safety.process_control), "UNKNOWN"); text("safetyProcWrites", blocked(safety.proc_writes), "UNKNOWN"); text("safetySysWrites", blocked(safety.sys_writes), "UNKNOWN"); text("safetyAndroidProperties", blocked(safety.android_property_writes), "UNKNOWN"); text("safetyNetworkOperations", blocked(safety.network_operations), "UNKNOWN"); text("safetyGameModification", blocked(safety.game_modification), "UNKNOWN"); text("safetyCodeExecution", blocked(safety.code_execution), "UNKNOWN"); renderList("blockedActions", list(safety.blocked_actions), "Unavailable until evidence is loaded"); renderProfiles(snapshot.profiles); renderPluginHealth(snapshot.plugin_health);
    text("observerName", observerPlugin.name || "System Observer"); text("observerStatus", observerPlugin.status || "No observer snapshot loaded."); text("observerLifecycle", label(observerPlugin.lifecycle)); text("observerVersion", observerSystem.application_version); text("observerOs", observerSystem.os); text("observerArchitecture", observerSystem.architecture); text("observerHostname", observerSystem.hostname); text("observerKernel", observerSystem.kernel); text("observerUptime", known(observerSystem.uptime_seconds) ? `${observerSystem.uptime_seconds} seconds` : "Unavailable"); text("observerMemory", known(observerSystem.memory_available_kb) ? `${observerSystem.memory_available_kb} kB` : "Unavailable");
    text("perfObserverName", performancePlugin.name || "Performance Observer"); text("perfObserverStatus", performancePlugin.status || "No performance snapshot loaded."); text("perfObserverLifecycle", label(performancePlugin.lifecycle)); text("perfObserverCpu", display(performanceCpu.utilization, "%"), "Unavailable"); text("perfObserverGpu", display(performanceGpu.utilization, "%"), "Unavailable"); text("perfObserverMemory", display(performanceMemory.usage_percent, "%"), "Unavailable"); text("perfObserverThermal", display(performanceThermal.temperature_c, "°C"), "Unavailable"); text("perfObserverFps", display(performanceFps.value, " FPS"), "Unavailable"); text("perfObserverFrameTime", display(performanceFps.frame_time_ms, " ms"), "Unavailable"); text("perfObserverPower", label(performancePower.state), "Unavailable");
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

  function refreshExportedSnapshot() {
    const button = byId("refreshButton"); if (button) button.disabled = true;
    fileStatus.textContent = "Refreshing the exported local snapshot…";
    return fetch(EXPORTED_SNAPSHOT_URL, { cache: "no-store" }).then((response) => {
      if (!response.ok) throw new Error(`exported snapshot unavailable (${response.status})`);
      return response.text();
    }).then((payload) => {
      if (payload.length > 1024 * 1024) throw new Error("exported snapshot exceeds 1 MB");
      render(JSON.parse(payload));
      fileStatus.textContent = "Refreshed the exported read-only snapshot.";
    }).catch((error) => {
      fileStatus.textContent = `Refresh unavailable: ${error.message}. Export with sh bin/dashboard export, or load a snapshot manually.`;
    }).finally(() => { if (button) button.disabled = false; });
  }

  byId("refreshButton")?.addEventListener("click", refreshExportedSnapshot);
  byId("resetButton").addEventListener("click", () => { render(empty()); fileStatus.textContent = "View cleared. No telemetry is retained by the dashboard."; });
  render(empty());
})();

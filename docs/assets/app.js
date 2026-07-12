(function () {
  "use strict";

  const root = document.documentElement;
  const storageKey = "uikit-lifecycle-showcase-theme";
  const media = window.matchMedia("(prefers-color-scheme: dark)");

  function readTheme() {
    try {
      return localStorage.getItem(storageKey) || "";
    } catch (_) {
      return "";
    }
  }

  function writeTheme(theme) {
    try {
      localStorage.setItem(storageKey, theme);
    } catch (_) {}
  }

  function isDark() {
    const explicit = root.getAttribute("data-theme");
    return explicit ? explicit === "dark" : media.matches;
  }

  function updateButtons() {
    const dark = isDark();
    document.querySelectorAll("[data-theme-toggle]").forEach((button) => {
      button.textContent = dark ? "Light" : "Dark";
      button.setAttribute("aria-pressed", String(dark));
      button.setAttribute("aria-label", dark ? "切换到浅色模式" : "切换到深色模式");
    });
  }

  const storedTheme = readTheme();
  if (storedTheme === "light" || storedTheme === "dark") {
    root.setAttribute("data-theme", storedTheme);
  }
  updateButtons();

  document.addEventListener("click", (event) => {
    const toggle = event.target.closest("[data-theme-toggle]");
    if (!toggle) return;
    const nextTheme = isDark() ? "light" : "dark";
    root.setAttribute("data-theme", nextTheme);
    writeTheme(nextTheme);
    updateButtons();
  });

  document.addEventListener("keydown", (event) => {
    if (event.key !== "Escape") return;
    document.querySelectorAll(".jx-site-nav__menu[open]").forEach((menu) => {
      menu.removeAttribute("open");
      menu.querySelector("summary")?.focus();
    });
  });

  const saveLab = document.querySelector("[data-save-lab]");
  const runSave = saveLab?.querySelector("[data-run-save]");
  const saveTrace = saveLab?.querySelector("[data-save-trace]");
  const saveOutput = saveLab?.querySelector("[data-save-output]");
  const saveSteps = Array.from(saveLab?.querySelectorAll("[data-mechanism]") || []);
  const reducedMotion = window.matchMedia("(prefers-reduced-motion: reduce)");
  const SAVE_TRACE_RESET_MS = 180;
  const SAVE_TRACE_STEP_MS = 480;
  let saveTimers = [];
  let saveRunId = 0;

  function clearSaveTimers() {
    saveTimers.forEach((timer) => window.clearTimeout(timer));
    saveTimers = [];
  }

  function cancelSaveTrace() {
    saveRunId += 1;
    clearSaveTimers();
    saveTrace?.removeAttribute("aria-busy");
    return saveRunId;
  }

  function scheduleSaveTimer(runId, callback, delay) {
    const timer = window.setTimeout(() => {
      saveTimers = saveTimers.filter((pending) => pending !== timer);
      if (runId !== saveRunId) return;
      callback();
    }, delay);
    saveTimers.push(timer);
  }

  function resetSaveTrace() {
    saveSteps.forEach((step) => {
      step.classList.remove("is-active", "is-complete");
      step.removeAttribute("aria-current");
    });
  }

  function activateSaveStep(index) {
    saveSteps.forEach((step, stepIndex) => {
      step.classList.toggle("is-complete", stepIndex < index);
      step.classList.toggle("is-active", stepIndex === index);
      if (stepIndex === index) step.setAttribute("aria-current", "step");
      else step.removeAttribute("aria-current");
    });
    const active = saveSteps[index];
    if (active && saveOutput) {
      const label = active.querySelector("span")?.textContent || `step ${index + 1}`;
      const method = active.querySelector("code")?.textContent || "";
      saveOutput.textContent = `${label} · ${method}`;
    }
  }

  function finishSaveTrace(runId) {
    if (runId !== saveRunId) return;
    saveSteps.forEach((step) => {
      step.classList.remove("is-active");
      step.classList.add("is-complete");
      step.removeAttribute("aria-current");
    });
    saveTrace?.removeAttribute("aria-busy");
    if (runSave) runSave.textContent = "Replay Save trace";
    if (saveOutput) saveOutput.textContent = "Save 完成：closure 回传后，列表 snapshot 已刷新。";
  }

  function startSaveTrace() {
    const wasRunning = saveTrace?.getAttribute("aria-busy") === "true";
    const runId = cancelSaveTrace();
    resetSaveTrace();
    runSave.textContent = "Restart Save trace";
    saveTrace.setAttribute("aria-busy", "true");
    if (saveOutput) {
      saveOutput.textContent = wasRunning
        ? "上一轮已取消。Save trace 已重新开始，准备进入 01 · delegate。"
        : "Save trace 已开始，准备进入 01 · delegate。";
    }

    if (reducedMotion.matches) {
      saveSteps.forEach((_, index) => activateSaveStep(index));
      finishSaveTrace(runId);
      return;
    }

    saveSteps.forEach((_, index) => {
      scheduleSaveTimer(
        runId,
        () => activateSaveStep(index),
        SAVE_TRACE_RESET_MS + index * SAVE_TRACE_STEP_MS,
      );
    });
    scheduleSaveTimer(
      runId,
      () => finishSaveTrace(runId),
      SAVE_TRACE_RESET_MS + saveSteps.length * SAVE_TRACE_STEP_MS,
    );
  }

  if (saveLab && runSave && saveTrace && saveSteps.length === 4) {
    saveLab.classList.add("is-enhanced");
    runSave.hidden = false;
    runSave.addEventListener("click", startSaveTrace);
  }

  media.addEventListener("change", () => {
    if (!readTheme()) updateButtons();
  });
})();

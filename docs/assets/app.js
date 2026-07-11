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
  const saveOutput = saveLab?.querySelector("[data-save-output]");
  const saveSteps = Array.from(saveLab?.querySelectorAll("[data-mechanism]") || []);
  let saveTimers = [];

  function clearSaveTimers() {
    saveTimers.forEach((timer) => window.clearTimeout(timer));
    saveTimers = [];
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

  function finishSaveTrace() {
    saveSteps.forEach((step) => {
      step.classList.remove("is-active");
      step.classList.add("is-complete");
      step.removeAttribute("aria-current");
    });
    saveLab?.removeAttribute("aria-busy");
    if (runSave) {
      runSave.disabled = false;
      runSave.textContent = "Replay Save trace";
    }
    if (saveOutput) saveOutput.textContent = "Save 完成：closure 回传后，列表 snapshot 已刷新。";
  }

  if (saveLab && runSave && saveSteps.length === 4) {
    saveLab.classList.add("is-enhanced");
    runSave.hidden = false;
    runSave.addEventListener("click", () => {
      clearSaveTimers();
      resetSaveTrace();
      runSave.disabled = true;
      runSave.textContent = "Running Save trace…";
      saveLab.setAttribute("aria-busy", "true");

      if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
        saveSteps.forEach((_, index) => activateSaveStep(index));
        finishSaveTrace();
        return;
      }

      saveSteps.forEach((_, index) => {
        saveTimers.push(window.setTimeout(() => activateSaveStep(index), index * 480));
      });
      saveTimers.push(window.setTimeout(finishSaveTrace, saveSteps.length * 480));
    });
  }

  media.addEventListener("change", () => {
    if (!readTheme()) updateButtons();
  });
})();

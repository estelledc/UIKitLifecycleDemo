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

  media.addEventListener("change", () => {
    if (!readTheme()) updateButtons();
  });
})();

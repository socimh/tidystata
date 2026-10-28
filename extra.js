// Chapter navigation needs no JavaScript. Enhance deep links and old bookmarks
// without downloading other chapters or a second search framework.
(() => {
  "use strict";
  function reference() {
    return document.querySelector(".stata-reference, .stata-reference-home");
  }
  function revealTarget() {
    let id;
    try { id = decodeURIComponent(location.hash.slice(1)); } catch { return; }
    const target = document.getElementById(id);
    if (!target) return;
    for (let parent = target.parentElement; parent; parent = parent.parentElement) {
      if (parent.tagName === "DETAILS") parent.open = true;
    }
    requestAnimationFrame(() => target.scrollIntoView({block: "start"}));
  }
  function languageLink() {
    const link = document.getElementById("stata-language-toggle");
    if (!link) return;
    const url = new URL(link.getAttribute("href"), location.href);
    url.hash = location.hash;
    link.href = url.href;
  }
  async function legacyLink(root) {
    if (!root.classList.contains("stata-reference-home") ||
        !location.hash.startsWith("#example-")) return;
    let id;
    try { id = decodeURIComponent(location.hash.slice("#example-".length)); } catch { return; }
    try {
      const response = await fetch(root.dataset.linkMap);
      if (!response.ok) return;
      const locations = await response.json();
      const slug = locations[id];
      if (typeof slug !== "string" || !/^[a-z0-9-]+$/.test(slug)) return;
      const prefix = root.dataset.language === "zh" ? "stata-zh-" : "stata-";
      const target = new URL(prefix + slug + ".html", location.href);
      target.hash = location.hash;
      target.search = location.search;
      location.replace(target.href);
    } catch {
      // The contents and command index remain available if a request fails.
    }
  }
  function refresh() {
    const root = reference();
    if (!root) return;
    languageLink();
    revealTarget();
    legacyLink(root);
  }
  document.addEventListener("DOMContentLoaded", () => {
    if (!reference()) return;
    const chapters = document.querySelector(".stata-chapters");
    if (chapters && matchMedia("(max-width: 767px)").matches) chapters.open = false;
    // pkgdown search lands on the command heading. Reveal variants containing
    // the query as well as targets reached directly by stable example ID.
    const query = new URLSearchParams(location.search).get("q");
    if (query && query.trim()) {
      const words = query.toLocaleLowerCase().trim().split(/\s+/);
      document.querySelectorAll("details.reference-variants").forEach(details => {
        const text = details.textContent.toLocaleLowerCase();
        if (words.every(word => text.includes(word))) details.open = true;
      });
    }
    refresh();
  });
  window.addEventListener("hashchange", refresh);
})();

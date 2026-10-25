// Keep language links and hidden alternatives usable from any deep link.
(() => {
  function placeLanguageSwitch() {
    const switcher = document.querySelector('.language-switch');
    const tools = document.querySelector('.quarto-navbar-tools');
    if (switcher && tools) tools.prepend(switcher);
  }
  function revealTarget() {
    let id;
    try { id = decodeURIComponent(window.location.hash.slice(1)); } catch { return; }
    const target = document.getElementById(id);
    if (!target) return;
    for (let parent = target.parentElement; parent; parent = parent.parentElement) {
      if (parent.tagName === "DETAILS") parent.open = true;
    }
    requestAnimationFrame(() => target.scrollIntoView({block: "start"}));
  }
  function updateLanguageLink() {
    const link = document.getElementById("language-toggle");
    if (!link) return;
    const url = new URL(link.getAttribute("href"), window.location.href);
    url.hash = window.location.hash;
    link.href = url.href;
  }
  function revealSearchMatches() {
    // Quarto consumes ?q= at module load, then highlights matches before this
    // DOMContentLoaded handler. Use its marks rather than its private query state.
    for (const details of document.querySelectorAll('details.reference-variants')) {
      if (details.querySelector('mark')) details.open = true;
    }
  }
  function refresh() {
    placeLanguageSwitch();
    updateLanguageLink();
    revealSearchMatches();
    revealTarget();
  }
  document.addEventListener("DOMContentLoaded", refresh);
  window.addEventListener("hashchange", refresh);
})();

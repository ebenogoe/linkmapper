// Small behaviours for Linkmapper. Everything works without them.
(function () {
  function reducedMotion() {
    return window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  }
  $(document).on("shiny:connected", function () {
    Shiny.addCustomMessageHandler("lm-scroll-top", function (msg) {
      window.scrollTo({ top: 0, behavior: reducedMotion() ? "auto" : "smooth" });
      var cur = document.querySelector(".lm-step.is-current");
      if (cur && cur.scrollIntoView) cur.scrollIntoView({ block: "nearest", inline: "center" });
    });
  });
  // Offer the guided tour the first time someone opens the workspace
  var offered = false;
  $(document).on("shiny:inputchanged", function (e) {
    if (e.name !== "nav" || e.value !== "work" || offered) return;
    offered = true;
    var seen = false;
    try { seen = window.localStorage.getItem("linkmapper-toured") === "1"; } catch (err) { seen = true; }
    if (seen) return;
    try { window.localStorage.setItem("linkmapper-toured", "1"); } catch (err) {}
    setTimeout(function () { Shiny.setInputValue("lm_first_visit", true, { priority: "event" }); }, 400);
  });
})();

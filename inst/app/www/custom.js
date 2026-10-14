// Small behaviours for Linkmapper. Everything works without them.
(function () {
  function reducedMotion() {
    return window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  }
  $(document).on("shiny:connected", function () {
    Shiny.addCustomMessageHandler("lm-start-tour", function (msg) {
      setTimeout(function () {
        var ids = Object.keys(window.driver || {});
        if (!ids.length) return;
        // Drop steps whose target is hidden on this screen (collapsed sidebar or navbar)
        var d = window.driver[ids[ids.length - 1]];
        var defs = (d.steps || []).map(function (s) { return s.options; }).filter(function (o) {
          var el = o && document.querySelector(o.element);
          return el && el.getBoundingClientRect().width > 0;
        });
        if (!defs.length) return;
        d.defineSteps(defs);
        d.start(0);
      }, msg.delay || 400);
    });
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
  // driver.js (the tour) listens only for touchstart on touch-capable screens, so mouse
  // clicks on touchscreen laptops do nothing. Handle those clicks here, skipping the
  // click that follows a real tap so the tour never advances twice.
  var lastTouch = 0;
  document.addEventListener("touchstart", function () { lastTouch = Date.now(); }, true);
  document.addEventListener("click", function (e) {
    if (!("ontouchstart" in document.documentElement) || Date.now() - lastTouch < 800) return;
    var ids = Object.keys(window.driver || {});
    if (!ids.length) return;
    var d = window.driver[ids[ids.length - 1]];
    if (!d.isActivated) return;
    if (e.target.closest(".driver-next-btn")) {
      if (d.hasNextStep()) d.moveNext(); else d.reset();
    } else if (e.target.closest(".driver-prev-btn")) {
      if (d.hasPreviousStep()) d.movePrevious();
    } else if (e.target.closest(".driver-close-btn")) {
      d.reset();
    }
  }, true);
})();

(function () {
  "use strict";

  if (window.__facehashInlineAvatarsBooted) {
    return;
  }
  window.__facehashInlineAvatarsBooted = true;

  var PROCESSED_ATTR = "data-facehash-inline-state";
  var SVG_CACHE = new Map();
  var INFLIGHT = new Map();
  var INTERACTIVE_SPHERE_POSITIONS = [
    { x: -1, y: 1 },
    { x: 1, y: 1 },
    { x: 1, y: 0 },
    { x: 0, y: 1 },
    { x: -1, y: 0 },
    { x: 0, y: 0 },
    { x: 0, y: -1 },
    { x: -1, y: -1 },
    { x: 1, y: -1 },
  ];
  var INTERACTIVE_ROTATE_RANGE = 12;
  var INTERACTIVE_PERSPECTIVE = 520;
  var INTERACTIVE_TRANSLATE_Z = 6;

  function readSiteSettings() {
    return (window.Discourse && window.Discourse.SiteSettings) || window.siteSettings || {};
  }

  function readBoolSetting(key, fallback) {
    var value = readSiteSettings()[key];
    if (typeof value === "boolean") {
      return value;
    }
    if (typeof value === "string") {
      return value === "true";
    }
    return fallback;
  }

  function featureEnabled() {
    return readBoolSetting("facehash_avatars_inline_render", true);
  }

  function hoverEnabled() {
    return readBoolSetting("facehash_avatars_hover_effect", true);
  }

  function isFacehashAvatarImage(img) {
    if (!(img instanceof HTMLImageElement)) {
      return false;
    }

    if (img.getAttribute(PROCESSED_ATTR)) {
      return false;
    }

    var src = img.currentSrc || img.src || "";
    return src.indexOf("/facehash_avatar/") !== -1 && src.indexOf(".svg") !== -1;
  }

  function resolveAvatarSize(img) {
    var rect = img.getBoundingClientRect();
    if (rect.width > 0 && rect.height > 0) {
      return { width: rect.width, height: rect.height };
    }

    var style = window.getComputedStyle(img);
    var styleWidth = parseFloat(style.width);
    var styleHeight = parseFloat(style.height);
    if (styleWidth > 0 && styleHeight > 0) {
      return { width: styleWidth, height: styleHeight };
    }

    var attrWidth = parseFloat(img.getAttribute("width"));
    var attrHeight = parseFloat(img.getAttribute("height"));
    if (attrWidth > 0 && attrHeight > 0) {
      return { width: attrWidth, height: attrHeight };
    }

    return { width: 40, height: 40 };
  }

  function fetchSvgText(src) {
    if (SVG_CACHE.has(src)) {
      return Promise.resolve(SVG_CACHE.get(src));
    }

    if (INFLIGHT.has(src)) {
      return INFLIGHT.get(src);
    }

    var request = fetch(src, { credentials: "same-origin" })
      .then(function (response) {
        if (!response.ok) {
          return null;
        }
        return response.text();
      })
      .then(function (text) {
        if (text) {
          SVG_CACHE.set(src, text);
        }
        INFLIGHT.delete(src);
        return text;
      })
      .catch(function () {
        INFLIGHT.delete(src);
        return null;
      });

    INFLIGHT.set(src, request);
    return request;
  }

  function stringHash(input) {
    var hash = 0;
    for (var i = 0; i < input.length; i += 1) {
      hash = ((hash << 5) - hash + input.charCodeAt(i)) | 0;
    }
    return Math.abs(hash);
  }

  function avatarSeedFromSrc(src) {
    var match = src.match(/\/facehash_avatar\/([^/]+)\//);
    if (!match || !match[1]) {
      return "";
    }

    try {
      return decodeURIComponent(match[1]);
    } catch (_error) {
      return match[1];
    }
  }

  function pickNonCenterPosition(hash) {
    var position =
      INTERACTIVE_SPHERE_POSITIONS[hash % INTERACTIVE_SPHERE_POSITIONS.length] || { x: 0, y: 0 };

    if (position.x === 0 && position.y === 0) {
      for (var i = 0; i < INTERACTIVE_SPHERE_POSITIONS.length; i += 1) {
        var idx = (hash + 3 + i) % INTERACTIVE_SPHERE_POSITIONS.length;
        var candidate = INTERACTIVE_SPHERE_POSITIONS[idx];
        if (candidate && (candidate.x !== 0 || candidate.y !== 0)) {
          return candidate;
        }
      }
    }

    return position;
  }

  function readRotationFromSvg(svg) {
    if (!(svg instanceof SVGElement)) {
      return null;
    }

    var faceLayer = svg.querySelector("[data-facehash-face]");
    if (!faceLayer) {
      return null;
    }

    var x = parseFloat(faceLayer.getAttribute("data-facehash-rotation-x"));
    var y = parseFloat(faceLayer.getAttribute("data-facehash-rotation-y"));

    if (!Number.isFinite(x) || !Number.isFinite(y)) {
      return null;
    }

    return { x: x, y: y };
  }

  function resolveInteractiveTarget(svg) {
    if (!(svg instanceof SVGElement)) {
      return null;
    }

    return svg.querySelector("[data-facehash-face]") || svg;
  }

  function applyInteractiveTilt(wrapper, svg, src, withHover) {
    if (!withHover) {
      return;
    }

    var target = resolveInteractiveTarget(svg);
    if (!target) {
      return;
    }

    var seed = avatarSeedFromSrc(src);
    var position = readRotationFromSvg(svg);

    // When the deterministic slot is dead-center, hover can look inert.
    // Use a deterministic non-center interactive tilt for motion feedback.
    if (position && position.x === 0 && position.y === 0 && seed) {
      position = pickNonCenterPosition(stringHash(seed));
    }

    if (!position) {
      if (!seed) {
        return;
      }
      position = pickNonCenterPosition(stringHash(seed));
    }

    wrapper.classList.add("facehash-inline-hover");
    target.classList.add("facehash-inline-interactive-face");
    target.style.setProperty("--fh-rx", position.x * INTERACTIVE_ROTATE_RANGE + "deg");
    target.style.setProperty("--fh-ry", position.y * INTERACTIVE_ROTATE_RANGE + "deg");
    target.style.setProperty("--fh-tz", INTERACTIVE_TRANSLATE_Z + "px");
    wrapper.style.perspective = INTERACTIVE_PERSPECTIVE + "px";
    wrapper.style.transformStyle = "preserve-3d";
  }

  function parseSvg(text) {
    var parser = new DOMParser();
    var doc = parser.parseFromString(text, "image/svg+xml");
    var svg = doc.documentElement;

    if (!svg || svg.nodeName.toLowerCase() !== "svg") {
      return null;
    }

    svg.querySelectorAll("script,foreignObject").forEach(function (node) {
      node.remove();
    });
    return svg;
  }

  function buildWrapper(img, svg, withHover) {
    var size = resolveAvatarSize(img);
    var wrapper = document.createElement("span");
    wrapper.className = (img.className || "") + " facehash-inline-avatar";
    wrapper.style.width = size.width + "px";
    wrapper.style.height = size.height + "px";
    wrapper.setAttribute("aria-hidden", "true");

    svg.classList.add("facehash-inline-svg");
    svg.setAttribute("width", "100%");
    svg.setAttribute("height", "100%");
    svg.setAttribute("preserveAspectRatio", "xMidYMid meet");

    img.classList.add("facehash-inline-hidden");
    img.setAttribute("aria-hidden", "true");

    var src = img.currentSrc || img.src || "";
    applyInteractiveTilt(wrapper, svg, src, withHover);

    return wrapper;
  }

  function upgradeImage(img, withHover) {
    if (!isFacehashAvatarImage(img) || !img.parentElement || img.closest(".facehash-inline-avatar")) {
      return;
    }

    img.setAttribute(PROCESSED_ATTR, "pending");

    var src = img.currentSrc || img.src;
    fetchSvgText(src).then(function (svgText) {
      if (!svgText || !img.parentElement) {
        img.setAttribute(PROCESSED_ATTR, "failed");
        return;
      }

      var svg = parseSvg(svgText);
      if (!svg || !img.parentElement) {
        img.setAttribute(PROCESSED_ATTR, "failed");
        return;
      }

      var wrapper = buildWrapper(img, svg, withHover);
      img.parentElement.insertBefore(wrapper, img);
      wrapper.appendChild(img);
      wrapper.appendChild(svg);
      img.setAttribute(PROCESSED_ATTR, "done");
    });
  }

  function collectAvatarImages(root) {
    var images = [];

    if (root instanceof HTMLImageElement && isFacehashAvatarImage(root)) {
      images.push(root);
    }

    if (root instanceof Element || root === document) {
      var scoped = root.querySelectorAll
        ? root.querySelectorAll("img.avatar[src*='/facehash_avatar/'], img[src*='/facehash_avatar/']")
        : [];
      scoped.forEach(function (node) {
        if (isFacehashAvatarImage(node)) {
          images.push(node);
        }
      });
    }

    return images;
  }

  function scheduleScan(root, withHover) {
    var run = function () {
      collectAvatarImages(root).forEach(function (img) {
        upgradeImage(img, withHover);
      });
    };

    if ("requestIdleCallback" in window) {
      window.requestIdleCallback(run, { timeout: 300 });
    } else {
      window.setTimeout(run, 16);
    }
  }

  function boot() {
    if (!featureEnabled()) {
      return;
    }

    var withHover = hoverEnabled();
    scheduleScan(document, withHover);

    var observer = new MutationObserver(function (mutations) {
      mutations.forEach(function (mutation) {
        mutation.addedNodes.forEach(function (node) {
          if (node instanceof Element) {
            scheduleScan(node, withHover);
          }
        });
      });
    });

    if (document.body) {
      observer.observe(document.body, { childList: true, subtree: true });
    }
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", boot, { once: true });
  } else {
    boot();
  }
})();

(function () {
  "use strict";

  if (window.__facehashInlineAvatarsBooted) {
    return;
  }
  window.__facehashInlineAvatarsBooted = true;

  var PROCESSED_ATTR = "data-facehash-inline-state";
  var TOKEN_ATTR = "data-facehash-inline-token";
  var SIGNATURE_ATTR = "data-facehash-inline-signature";
  var HOST_CLASS = "facehash-inline-host";
  var OVERLAY_CLASS = "facehash-inline-overlay";
  var OVERLAY_FOR_ATTR = "data-facehash-inline-for";
  var SVG_CACHE = new Map();
  var INFLIGHT = new Map();
  var NEXT_TOKEN_ID = 1;

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
  var INTERACTIVE_ROTATE_RANGE_SMALL = 8;
  var INTERACTIVE_PERSPECTIVE = 520;
  var INTERACTIVE_TRANSLATE_Z = 6;
  var INTERACTIVE_TRANSLATE_Z_SMALL = 0;
  var INTERACTIVE_TRANSLATE_2D_SMALL = 0.8;
  var SMALL_AVATAR_THRESHOLD = 28;

  function readSiteSettings() {
    if (window.siteSettings && typeof window.siteSettings === "object") {
      return window.siteSettings;
    }

    return {};
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

  function forceNonCenterInteractiveTiltEnabled() {
    return readBoolSetting("facehash_avatars_force_non_center_interactive_tilt", true);
  }

  function isFacehashAvatarImage(img) {
    if (!(img instanceof HTMLImageElement)) {
      return false;
    }

    var src = img.currentSrc || img.src || "";
    return src.indexOf("/facehash_avatar/") !== -1 && src.indexOf(".svg") !== -1;
  }

  function ensureToken(img) {
    var token = img.getAttribute(TOKEN_ATTR);
    if (token) {
      return token;
    }

    token = "fh-" + NEXT_TOKEN_ID;
    NEXT_TOKEN_ID += 1;
    img.setAttribute(TOKEN_ATTR, token);
    return token;
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

  function signatureForImage(img) {
    var src = img.currentSrc || img.src || "";
    var size = resolveAvatarSize(img);
    return src + "|" + size.width + "x" + size.height;
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

  function applyInteractiveTilt(wrapper, svg, src, withHover, size) {
    if (!withHover) {
      return;
    }

    var target = resolveInteractiveTarget(svg);
    if (!target) {
      return;
    }

    var seed = avatarSeedFromSrc(src);
    var position = readRotationFromSvg(svg);

    if (
      forceNonCenterInteractiveTiltEnabled() &&
      position &&
      position.x === 0 &&
      position.y === 0 &&
      seed
    ) {
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

    var knownWidth = size && Number.isFinite(size.width) ? size.width : 0;
    var knownHeight = size && Number.isFinite(size.height) ? size.height : 0;
    var maxDim = Math.max(knownWidth, knownHeight);
    if (maxDim <= 0) {
      var rect = wrapper.getBoundingClientRect();
      maxDim = Math.max(rect.width || 0, rect.height || 0);
    }

    var isSmallAvatar = maxDim > 0 && maxDim <= SMALL_AVATAR_THRESHOLD;
    var rotateRange = isSmallAvatar ? INTERACTIVE_ROTATE_RANGE_SMALL : INTERACTIVE_ROTATE_RANGE;
    var translateZ = isSmallAvatar ? INTERACTIVE_TRANSLATE_Z_SMALL : INTERACTIVE_TRANSLATE_Z;
    var translate2d = isSmallAvatar ? INTERACTIVE_TRANSLATE_2D_SMALL : 0;

    target.style.setProperty("--fh-rx", position.x * rotateRange + "deg");
    target.style.setProperty("--fh-ry", position.y * rotateRange + "deg");
    target.style.setProperty("--fh-tz", translateZ + "px");
    target.style.setProperty("--fh-tx", position.y * translate2d + "px");
    target.style.setProperty("--fh-ty", -position.x * translate2d + "px");

    if (isSmallAvatar) {
      wrapper.classList.add("facehash-inline-small");
      wrapper.style.perspective = "none";
    } else {
      wrapper.classList.remove("facehash-inline-small");
      wrapper.style.perspective = INTERACTIVE_PERSPECTIVE + "px";
    }
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

  function findOverlayForToken(token) {
    if (!token) {
      return null;
    }

    return document.querySelector('.' + OVERLAY_CLASS + '[' + OVERLAY_FOR_ATTR + '="' + token + '"]');
  }

  function clearOverlayForImage(img) {
    if (!(img instanceof HTMLImageElement)) {
      return;
    }

    var token = img.getAttribute(TOKEN_ATTR);
    var existingOverlay = findOverlayForToken(token);
    if (existingOverlay && existingOverlay.parentElement) {
      existingOverlay.parentElement.removeChild(existingOverlay);
    }
  }

  function ensureHostLayout(host) {
    if (!(host instanceof Element)) {
      return;
    }

    host.classList.add(HOST_CLASS);
  }

  function buildOverlay(img, svg, withHover, size) {
    var wrapper = document.createElement("span");
    wrapper.className = "facehash-inline-avatar " + OVERLAY_CLASS;
    wrapper.style.width = "100%";
    wrapper.style.height = "100%";
    wrapper.style.position = "absolute";
    wrapper.style.top = "0";
    wrapper.style.left = "0";

    var imgComputedStyle = window.getComputedStyle(img);
    if (imgComputedStyle && imgComputedStyle.borderRadius) {
      wrapper.style.borderRadius = imgComputedStyle.borderRadius;
    }
    wrapper.setAttribute("aria-hidden", "true");

    svg.classList.add("facehash-inline-svg");
    svg.setAttribute("width", "100%");
    svg.setAttribute("height", "100%");
    svg.setAttribute("preserveAspectRatio", "xMidYMid meet");

    var src = img.currentSrc || img.src || "";
    applyInteractiveTilt(wrapper, svg, src, withHover, size);

    wrapper.appendChild(svg);
    return wrapper;
  }

  function enhanceImage(img, withHover) {
    if (!isFacehashAvatarImage(img) || !img.parentElement) {
      return;
    }
    var host = img.parentElement;
    ensureHostLayout(host);

    var signature = signatureForImage(img);
    if (img.getAttribute(PROCESSED_ATTR) === "done" && img.getAttribute(SIGNATURE_ATTR) === signature) {
      var existingToken = img.getAttribute(TOKEN_ATTR);
      if (existingToken && findOverlayForToken(existingToken)) {
        return;
      }
    }

    if (img.getAttribute(PROCESSED_ATTR) === "pending") {
      return;
    }

    clearOverlayForImage(img);
    img.setAttribute(PROCESSED_ATTR, "pending");

    var src = img.currentSrc || img.src;
    fetchSvgText(src).then(function (svgText) {
      if (!svgText || !img.parentElement || !img.isConnected) {
        img.setAttribute(PROCESSED_ATTR, "failed");
        return;
      }

      var latestSrc = img.currentSrc || img.src || "";
      if (latestSrc !== src) {
        img.setAttribute(PROCESSED_ATTR, "stale");
        scheduleScan(img, withHover);
        return;
      }

      var svg = parseSvg(svgText);
      if (!svg) {
        img.setAttribute(PROCESSED_ATTR, "failed");
        return;
      }

      var size = resolveAvatarSize(img);
      var wrapper = buildOverlay(img, svg, withHover, size);
      var token = ensureToken(img);
      wrapper.setAttribute(OVERLAY_FOR_ATTR, token);

      if (!host || !host.isConnected) {
        img.setAttribute(PROCESSED_ATTR, "failed");
        return;
      }

      host.appendChild(wrapper);
      img.setAttribute(SIGNATURE_ATTR, signatureForImage(img));
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

  function cleanupOrphanOverlays() {
    var overlays = document.querySelectorAll('.' + OVERLAY_CLASS + '[' + OVERLAY_FOR_ATTR + ']');
    overlays.forEach(function (overlay) {
      var token = overlay.getAttribute(OVERLAY_FOR_ATTR);
      if (!token) {
        overlay.remove();
        return;
      }

      var img = document.querySelector('img[' + TOKEN_ATTR + '="' + token + '"]');
      if (!img || !img.isConnected) {
        overlay.remove();
      }
    });
  }

  function scheduleScan(root, withHover) {
    var run = function () {
      cleanupOrphanOverlays();
      collectAvatarImages(root).forEach(function (img) {
        enhanceImage(img, withHover);
      });
    };

    if ("requestIdleCallback" in window) {
      window.requestIdleCallback(run, { timeout: 300 });
    } else {
      window.setTimeout(run, 16);
    }
  }

  function resetIfTrackedImage(target) {
    if (!(target instanceof HTMLImageElement)) {
      return;
    }

    if (!isFacehashAvatarImage(target) && !target.getAttribute(TOKEN_ATTR)) {
      return;
    }

    clearOverlayForImage(target);
    target.removeAttribute(PROCESSED_ATTR);
    target.removeAttribute(SIGNATURE_ATTR);
  }

  function boot() {
    if (!featureEnabled()) {
      return;
    }

    var withHover = hoverEnabled();
    scheduleScan(document, withHover);

    var observer = new MutationObserver(function (mutations) {
      mutations.forEach(function (mutation) {
        if (mutation.type === "childList") {
          mutation.addedNodes.forEach(function (node) {
            if (node instanceof Element) {
              scheduleScan(node, withHover);
            }
          });

          mutation.removedNodes.forEach(function (node) {
            if (node instanceof HTMLImageElement) {
              clearOverlayForImage(node);
            } else if (node instanceof Element) {
              node.querySelectorAll("img[" + TOKEN_ATTR + "]").forEach(function (img) {
                clearOverlayForImage(img);
              });
            }
          });
        }

        if (mutation.type === "attributes") {
          resetIfTrackedImage(mutation.target);
          scheduleScan(mutation.target, withHover);
        }
      });
    });

    if (document.body) {
      observer.observe(document.body, {
        childList: true,
        subtree: true,
        attributes: true,
        attributeFilter: ["src", "srcset", "width", "height"],
      });
    }
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", boot, { once: true });
  } else {
    boot();
  }
})();

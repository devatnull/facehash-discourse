(function () {
  "use strict";

  if (window.__facehashInlineAvatarsBooted) {
    return;
  }
  window.__facehashInlineAvatarsBooted = true;

  var PROCESSED_ATTR = "data-facehash-inline-state";
  var SVG_CACHE = new Map();
  var INFLIGHT = new Map();

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
    if (withHover) {
      wrapper.classList.add("facehash-inline-hover");
    }
    wrapper.style.width = size.width + "px";
    wrapper.style.height = size.height + "px";
    wrapper.setAttribute("aria-hidden", "true");

    svg.classList.add("facehash-inline-svg");
    svg.setAttribute("width", "100%");
    svg.setAttribute("height", "100%");
    svg.setAttribute("preserveAspectRatio", "xMidYMid meet");

    img.classList.add("facehash-inline-hidden");
    img.setAttribute("aria-hidden", "true");

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

import { withPluginApi } from "discourse/lib/plugin-api";

const PROCESSED_ATTR = "data-facehash-inline-state";
const SVG_CACHE = new Map();
const INFLIGHT = new Map();

function isFacehashAvatarImage(img) {
  if (!(img instanceof HTMLImageElement)) {
    return false;
  }

  if (img.getAttribute(PROCESSED_ATTR)) {
    return false;
  }

  const src = img.currentSrc || img.src || "";
  return src.includes("/facehash_avatar/") && src.includes(".svg");
}

function resolveAvatarSize(img) {
  const rect = img.getBoundingClientRect();
  if (rect.width > 0 && rect.height > 0) {
    return { width: rect.width, height: rect.height };
  }

  const style = window.getComputedStyle(img);
  const styleWidth = parseFloat(style.width);
  const styleHeight = parseFloat(style.height);
  if (styleWidth > 0 && styleHeight > 0) {
    return { width: styleWidth, height: styleHeight };
  }

  const attrWidth = parseFloat(img.getAttribute("width"));
  const attrHeight = parseFloat(img.getAttribute("height"));
  if (attrWidth > 0 && attrHeight > 0) {
    return { width: attrWidth, height: attrHeight };
  }

  const fallback = 40;
  return { width: fallback, height: fallback };
}

async function fetchSvgText(src) {
  if (SVG_CACHE.has(src)) {
    return SVG_CACHE.get(src);
  }

  if (INFLIGHT.has(src)) {
    return INFLIGHT.get(src);
  }

  const request = fetch(src, { credentials: "same-origin" })
    .then((response) => {
      if (!response.ok) {
        return null;
      }

      return response.text();
    })
    .then((text) => {
      if (text) {
        SVG_CACHE.set(src, text);
      }
      INFLIGHT.delete(src);
      return text;
    })
    .catch(() => {
      INFLIGHT.delete(src);
      return null;
    });

  INFLIGHT.set(src, request);
  return request;
}

function parseSvg(text) {
  const parser = new DOMParser();
  const doc = parser.parseFromString(text, "image/svg+xml");
  const svg = doc.documentElement;

  if (!svg || svg.nodeName.toLowerCase() !== "svg") {
    return null;
  }

  svg.querySelectorAll("script,foreignObject").forEach((node) => node.remove());
  return svg;
}

function buildWrapper(img, svg, hoverEnabled) {
  const { width, height } = resolveAvatarSize(img);
  const wrapper = document.createElement("span");
  wrapper.className = `${img.className} facehash-inline-avatar`;
  if (hoverEnabled) {
    wrapper.classList.add("facehash-inline-hover");
  }
  wrapper.style.width = `${width}px`;
  wrapper.style.height = `${height}px`;
  wrapper.setAttribute("aria-hidden", "true");

  svg.classList.add("facehash-inline-svg");
  svg.setAttribute("width", "100%");
  svg.setAttribute("height", "100%");
  svg.setAttribute("preserveAspectRatio", "xMidYMid meet");

  img.classList.add("facehash-inline-hidden");
  img.setAttribute("aria-hidden", "true");

  return wrapper;
}

async function upgradeImage(img, hoverEnabled) {
  if (!isFacehashAvatarImage(img) || !img.parentElement || img.closest(".facehash-inline-avatar")) {
    return;
  }

  img.setAttribute(PROCESSED_ATTR, "pending");

  const src = img.currentSrc || img.src;
  const svgText = await fetchSvgText(src);
  if (!svgText || !img.parentElement) {
    img.setAttribute(PROCESSED_ATTR, "failed");
    return;
  }

  const svg = parseSvg(svgText);
  if (!svg || !img.parentElement) {
    img.setAttribute(PROCESSED_ATTR, "failed");
    return;
  }

  const wrapper = buildWrapper(img, svg, hoverEnabled);
  img.parentElement.insertBefore(wrapper, img);
  wrapper.appendChild(img);
  wrapper.appendChild(svg);
  img.setAttribute(PROCESSED_ATTR, "done");
}

function collectAvatarImages(root) {
  const images = [];

  if (root instanceof HTMLImageElement && isFacehashAvatarImage(root)) {
    images.push(root);
  }

  if (root instanceof Element) {
    root
      .querySelectorAll("img.avatar[src*='/facehash_avatar/'], img[src*='/facehash_avatar/']")
      .forEach((node) => {
        if (isFacehashAvatarImage(node)) {
          images.push(node);
        }
      });
  }

  return images;
}

function scheduleScan(root, hoverEnabled) {
  const run = () => {
    const images = collectAvatarImages(root);
    images.forEach((img) => {
      upgradeImage(img, hoverEnabled);
    });
  };

  if ("requestIdleCallback" in window) {
    window.requestIdleCallback(run, { timeout: 300 });
  } else {
    window.setTimeout(run, 16);
  }
}

export default {
  name: "facehash-inline-avatars",

  initialize() {
    withPluginApi("1.8.0", () => {
      if (!settings.facehash_avatars_inline_render) {
        return;
      }

      const hoverEnabled = !!settings.facehash_avatars_hover_effect;
      scheduleScan(document, hoverEnabled);

      const observer = new MutationObserver((mutations) => {
        mutations.forEach((mutation) => {
          mutation.addedNodes.forEach((node) => {
            if (node instanceof Element) {
              scheduleScan(node, hoverEnabled);
            }
          });
        });
      });

      observer.observe(document.body, { childList: true, subtree: true });
    });
  },
};

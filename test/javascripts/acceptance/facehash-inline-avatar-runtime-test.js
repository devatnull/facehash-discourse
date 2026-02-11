import { acceptance } from "discourse/tests/helpers/qunit-helpers";
import { visit } from "@ember/test-helpers";
import { test } from "qunit";

acceptance("Facehash | Inline runtime", function (needs) {
  needs.user();
  needs.settings({
    facehash_avatars_enabled: true,
    facehash_avatars_inline_render: true,
  });

  test("injects inline avatar runtime script", async function (assert) {
    await visit("/");

    const scripts = [...document.querySelectorAll("script")];
    const found = scripts.some((script) =>
      script.textContent?.includes("__facehashInlineAvatarsBooted")
    );

    assert.true(
      found,
      "facehash inline runtime is included in the page head when inline render is enabled"
    );
  });
});


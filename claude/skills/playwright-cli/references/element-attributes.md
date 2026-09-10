# Inspecting element attributes

The snapshot shows an element’s role and accessible name, but not its `id`, `class`, `data-*` attributes, or other DOM properties. Use `eval` against the element’s ref to read those.

Take a snapshot first to get the ref, then evaluate a property or attribute on it:

```bash
playwright-cli snapshot
# the snapshot shows the button as e7, without its id or data attributes

# read the element's id
playwright-cli eval "el => el.id" e7

# read all CSS classes
playwright-cli eval "el => el.className" e7

# read a specific attribute
playwright-cli eval "el => el.getAttribute('data-testid')" e7
playwright-cli eval "el => el.getAttribute('aria-label')" e7

# read a computed style property
playwright-cli eval "el => getComputedStyle(el).display" e7
```

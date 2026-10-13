{{flutter_js}}
{{flutter_build_config}}
// Flutter's semantic input elements have accessible labels but no form identity.
// Keep each generated element addressable without changing its value or autofill.
function identifyInputs(root) {
  const selector = 'input[data-semantics-role="text-field"],textarea[data-semantics-role="text-field"]';
  for (const field of [ ...(root.matches(selector) ? [root] : []), ...root.querySelectorAll(selector)]) {
    if (!field.id) field.id = `stey-input-${identifyInputs.next++}`;
  }
}
identifyInputs.next = 0;
new MutationObserver(records => {
  for (const record of records) for (const node of record.addedNodes) {
    if (node instanceof Element) identifyInputs(node);
  }
}).observe(document.body, { childList: true, subtree: true });
_flutter.loader.load({onEntrypointLoaded: async engineInitializer => {
  const runner = await engineInitializer.initializeEngine();
  await runner.runApp();
  document.getElementById('startup')?.remove();
}});

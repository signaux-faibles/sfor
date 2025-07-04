document.addEventListener('click', function(event) {
    const tab = event.target.closest('.fr-tabs__tab');
    if (tab && window.ahoy) {
      window.ahoy.track(tab.id, {
        tabId: tab.id || null,
      });
    }
  });
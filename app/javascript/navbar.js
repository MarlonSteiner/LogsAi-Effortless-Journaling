document.addEventListener('turbo:load', function() {
  const toggleBtn = document.getElementById('navbarToggle');
  const sidebar = document.getElementById('simpleSidebar');
  const overlay = document.getElementById('sidebarOverlay');
  const cancelBtn = document.getElementById('cancelSearch');
  const searchInput = document.getElementById('sidebarSearchInput');
  const searchResults = document.getElementById('searchResults');
  const defaultContent = document.getElementById('defaultContent');
  let searchTimeout = null;

  console.log('Navbar JS loaded');

  // Open sidebar
  if (toggleBtn) {
    toggleBtn.addEventListener('click', function() {
      console.log('Toggle clicked');
      sidebar.classList.add('open');
      overlay.classList.add('show');
    });
  }

  // Close sidebar
  function closeSidebar() {
    sidebar.classList.remove('open');
    overlay.classList.remove('show');
    resetSearchState();
  }

  if (overlay) {
    overlay.addEventListener('click', closeSidebar);
  }

  // Search functionality
  if (searchInput) {
    // Handle focus - show cancel button and hide menu
    searchInput.addEventListener('focus', function() {
      console.log('Search focused');
      if (cancelBtn) cancelBtn.style.display = 'block';
      if (defaultContent) defaultContent.style.display = 'none';
      searchInput.style.width = '75%';
    });

    // Handle blur - reset if not clicking cancel
    searchInput.addEventListener('blur', function(e) {
      // Don't reset if clicking cancel button
      if (e.relatedTarget && e.relatedTarget.id === 'cancelSearch') {
        return;
      }
      setTimeout(() => {
        resetSearchState();
      }, 150);
    });

    // Handle typing - search as user types
    searchInput.addEventListener('input', function() {
      const query = this.value.trim();

      // Clear previous timeout
      if (searchTimeout) {
        clearTimeout(searchTimeout);
      }

      // Debounce search
      searchTimeout = setTimeout(() => {
        if (query.length >= 2) {
          performSearch(query);
        } else {
          hideResults();
        }
      }, 300);
    });
  }

  // Cancel search
  if (cancelBtn) {
    cancelBtn.addEventListener('click', function() {
      console.log('Cancel clicked');
      resetSearchState();
      searchInput.blur();
    });
  }

  // Perform search
  function performSearch(query) {
    console.log('Searching for:', query);

    fetch(`/search/autocomplete?q=${encodeURIComponent(query)}`, {
      headers: {
        'Accept': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      }
    })
    .then(response => response.json())
    .then(data => displayResults(data))
    .catch(error => {
      console.error('Search error:', error);
      hideResults();
    });
  }

  // Display search results
  function displayResults(results) {
    if (!searchResults) return;

    if (results.length === 0) {
      searchResults.innerHTML = '<div class="no-results">No entries found</div>';
    } else {
      const html = results.map(result =>
        `<a href="${result.url}" class="search-result-item">
          <div class="search-result-title">${escapeHtml(result.title)}</div>
          <div class="search-result-date">${result.date}</div>
        </a>`
      ).join('');

      searchResults.innerHTML = html;
    }

    showResults();
  }

  // Show search results
  function showResults() {
    if (searchResults) searchResults.style.display = 'block';
  }

  // Hide search results
  function hideResults() {
    if (searchResults) searchResults.style.display = 'none';
  }

  // Reset search state
  function resetSearchState() {
    if (cancelBtn) cancelBtn.style.display = 'none';
    if (defaultContent) defaultContent.style.display = 'flex';
    if (searchInput) {
      searchInput.value = '';
      searchInput.style.width = '100%';
    }
    hideResults();
  }

  // Escape HTML
  function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }

  // Escape key to close
  document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
      if (sidebar.classList.contains('open')) {
        closeSidebar();
      }
    }
  });
});

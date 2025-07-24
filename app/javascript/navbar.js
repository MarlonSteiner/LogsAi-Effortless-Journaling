document.addEventListener('turbo:load', function() {
  const toggleBtn = document.getElementById('navbarToggle');
  const sidebar = document.getElementById('simpleSidebar');
  const overlay = document.getElementById('sidebarOverlay');
  const closeBtn = document.getElementById('closeSidebar');

  console.log('Navbar JS loaded'); // For debugging

  if (toggleBtn) {
    toggleBtn.addEventListener('click', function() {
      console.log('Toggle clicked'); // For debugging
      sidebar.classList.add('open');
      overlay.classList.add('show');
    });
  }

  if (closeBtn) {
    closeBtn.addEventListener('click', function() {
      sidebar.classList.remove('open');
      overlay.classList.remove('show');
    });
  }

  if (overlay) {
    overlay.addEventListener('click', function() {
      sidebar.classList.remove('open');
      overlay.classList.remove('show');
    });
  }
});

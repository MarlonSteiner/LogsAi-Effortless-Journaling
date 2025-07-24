document.addEventListener('DOMContentLoaded', function() {
  const toggleBtn = document.getElementById('navbarToggle');
  const sidebar = document.getElementById('simpleSidebar');
  const overlay = document.getElementById('sidebarOverlay');
  const closeBtn = document.getElementById('closeSidebar');

  // Open sidebar
  toggleBtn.addEventListener('click', function() {
    sidebar.classList.add('open');
    overlay.classList.add('show');
  });

  // Close sidebar
  closeBtn.addEventListener('click', function() {
    sidebar.classList.remove('open');
    overlay.classList.remove('show');
  });

  // Close when clicking overlay
  overlay.addEventListener('click', function() {
    sidebar.classList.remove('open');
    overlay.classList.remove('show');
  });
});

class SlidingNavbar {
    constructor() {
        this.init();
        this.bindEvents();
    }

    init() {
        this.navbar = document.getElementById('slidingNavbar');
        this.overlay = document.getElementById('navbarOverlay');
        this.mainContent = document.getElementById('mainContent');
        this.toggleBtn = document.getElementById('navbarToggle');
        this.closeBtn = document.getElementById('navbarClose');
        this.searchInput = document.getElementById('searchInput');
        this.navItems = document.querySelectorAll('.nav-item');
        this.isOpen = false;
    }

    bindEvents() {
        // Toggle buttons
        this.toggleBtn.addEventListener('click', () => this.open());
        this.closeBtn.addEventListener('click', () => this.close());
        this.overlay.addEventListener('click', () => this.close());

        // Search functionality
        this.searchInput.addEventListener('input', (e) => this.search(e.target.value));
        this.searchInput.addEventListener('keydown', (e) => {
            if (e.key === 'Enter') {
                e.preventDefault();
                this.handleSearchEnter();
            }
        });

        // Keyboard navigation
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape' && this.isOpen) {
                this.close();
            }
        });

        // Navigation links
        this.navItems.forEach(item => {
            const link = item.querySelector('.nav-link');
            link.addEventListener('click', (e) => {
                e.preventDefault();
                this.handleNavClick(link.textContent);
            });
        });

        // Account section
        const accountSection = document.querySelector('.navbar-account');
        accountSection.addEventListener('click', () => this.handleAccountClick());
    }

    open() {
        this.isOpen = true;
        this.navbar.classList.add('open');
        this.overlay.classList.add('show');
        this.mainContent.classList.add('nav-open');

        // Focus on search input after animation
        setTimeout(() => {
            this.searchInput.focus();
        }, 500);

        // Dispatch custom event
        this.dispatchEvent('navbar:open');
    }

    close() {
        this.isOpen = false;
        this.navbar.classList.remove('open');
        this.overlay.classList.remove('show');
        this.mainContent.classList.remove('nav-open');

        // Clear search
        this.searchInput.value = '';
        this.showAllItems();

        // Dispatch custom event
        this.dispatchEvent('navbar:close');
    }

    search(query) {
        const searchTerm = query.toLowerCase().trim();

        this.navItems.forEach(item => {
            const searchData = item.getAttribute('data-search').toLowerCase();
            const linkText = item.querySelector('.nav-link').textContent.toLowerCase();

            if (searchData.includes(searchTerm) || linkText.includes(searchTerm)) {
                item.classList.remove('hidden');
            } else {
                item.classList.add('hidden');
            }
        });

        // Dispatch custom event
        this.dispatchEvent('navbar:search', { query, results: this.getVisibleItems() });
    }

    showAllItems() {
        this.navItems.forEach(item => {
            item.classList.remove('hidden');
        });
    }

    getVisibleItems() {
        return Array.from(this.navItems).filter(item => !item.classList.contains('hidden'));
    }

    handleSearchEnter() {
        const visibleItems = this.getVisibleItems();
        if (visibleItems.length > 0) {
            const firstLink = visibleItems[0].querySelector('.nav-link');
            this.handleNavClick(firstLink.textContent);
        }
    }

    handleNavClick(linkText) {
        console.log(`Navigation clicked: ${linkText}`);
        this.dispatchEvent('navbar:navigate', { page: linkText.toLowerCase() });
        this.close();
    }

    handleAccountClick() {
        console.log('Account section clicked');
        this.dispatchEvent('navbar:account');
        this.close();
    }

    dispatchEvent(eventName, detail = {}) {
        const event = new CustomEvent(eventName, { detail });
        document.dispatchEvent(event);
    }
}

// Initialize the navbar when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    const navbar = new SlidingNavbar();

    // Example event listeners
    document.addEventListener('navbar:open', () => {
        console.log('Navbar opened');
    });

    document.addEventListener('navbar:close', () => {
        console.log('Navbar closed');
    });

    document.addEventListener('navbar:search', (e) => {
        console.log('Search performed:', e.detail);
    });

    document.addEventListener('navbar:navigate', (e) => {
        console.log('Navigation to:', e.detail.page);
    });

    document.addEventListener('navbar:account', () => {
        console.log('Account accessed');
    });
});

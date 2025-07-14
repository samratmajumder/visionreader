const { ipcRenderer } = require('electron');

class AdvancedStoryReader {
    constructor() {
        this.storyContent = '';
        this.storyFileName = '';
        this.mediaGrids = [];
        this.bookmarks = [];
        this.searchResults = [];
        this.currentSearchIndex = 0;
        this.settings = {
            fontSize: 16,
            fontFamily: 'Georgia',
            backgroundColor: '#1a1a1a',
            textColor: '#ffffff',
            autoScroll: false,
            scrollSpeed: 1,
            theme: 'dark'
        };
        this.autoScrollInterval = null;
        this.scrollPosition = 0;
        this.draggedGrid = null;
        this.isResizing = false;
        this.dragTarget = null;
        
        this.initializeElements();
        this.setupEventListeners();
        this.loadSettings();
        this.loadBookmarks();
        this.setupDragAndDrop();
    }

    initializeElements() {
        this.storyContentEl = document.getElementById('storyContent');
        this.storyPlaceholderEl = document.getElementById('storyPlaceholder');
        this.storyTitleEl = document.getElementById('storyTitle');
        this.progressFillEl = document.getElementById('progressFill');
        this.mediaGridsEl = document.getElementById('mediaGrids');
        this.mediaPlaceholderEl = document.getElementById('mediaPlaceholder');
        this.searchOverlayEl = document.getElementById('searchOverlay');
        this.searchInputEl = document.getElementById('searchInput');
        this.searchResultsEl = document.getElementById('searchResults');
        this.bookmarksPanelEl = document.getElementById('bookmarksPanel');
        this.bookmarksListEl = document.getElementById('bookmarksList');
        this.dragOverlayEl = document.getElementById('dragOverlay');
        
        // Settings elements
        this.fontFamilyEl = document.getElementById('fontFamily');
        this.fontSizeEl = document.getElementById('fontSize');
        this.fontSizeDisplayEl = document.getElementById('fontSizeDisplay');
        this.themeEl = document.getElementById('theme');
        this.autoScrollEl = document.getElementById('autoScroll');
        this.scrollControlsEl = document.getElementById('scrollControls');
        this.scrollSpeedEl = document.getElementById('scrollSpeed');
        this.scrollSpeedDisplayEl = document.getElementById('scrollSpeedDisplay');
    }

    setupEventListeners() {
        // File operations
        document.getElementById('openFile').addEventListener('click', () => this.openFile());
        document.getElementById('saveLayout').addEventListener('click', () => this.showSaveLayoutModal());
        document.getElementById('loadLayout').addEventListener('click', () => this.showLoadLayoutModal());
        document.getElementById('packageLayout').addEventListener('click', () => this.packageLayout());
        document.getElementById('importLayout').addEventListener('click', () => this.importLayout());

        // Grid operations
        document.getElementById('addGrid').addEventListener('click', () => this.addMediaGrid());
        document.getElementById('clearAllGrids').addEventListener('click', () => this.clearAllGrids());

        // Search and bookmarks
        document.getElementById('toggleSearch').addEventListener('click', () => this.toggleSearch());
        document.getElementById('addBookmark').addEventListener('click', () => this.addBookmark());
        document.getElementById('showBookmarks').addEventListener('click', () => this.toggleBookmarks());

        // Settings
        this.fontFamilyEl.addEventListener('change', (e) => this.updateFontFamily(e.target.value));
        this.fontSizeEl.addEventListener('input', (e) => this.updateFontSize(e.target.value));
        this.themeEl.addEventListener('change', (e) => this.updateTheme(e.target.value));
        this.autoScrollEl.addEventListener('change', (e) => this.toggleAutoScroll(e.target.checked));
        this.scrollSpeedEl.addEventListener('input', (e) => this.updateScrollSpeed(e.target.value));

        // Search
        this.searchInputEl.addEventListener('input', (e) => this.performSearch(e.target.value));
        this.searchInputEl.addEventListener('keydown', (e) => this.handleSearchKeydown(e));

        // Keyboard navigation
        document.addEventListener('keydown', (e) => this.handleKeyboard(e));
        
        // Scroll tracking
        this.storyContentEl.addEventListener('scroll', () => this.updateReadingProgress());
        
        // Modal close handlers
        document.addEventListener('click', (e) => {
            if (e.target.classList.contains('modal')) {
                this.closeAllModals();
            }
        });
    }

    setupDragAndDrop() {
        // Prevent default drag behaviors
        ['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {
            document.addEventListener(eventName, (e) => {
                e.preventDefault();
                e.stopPropagation();
            });
        });

        // Drag enter/over
        ['dragenter', 'dragover'].forEach(eventName => {
            document.addEventListener(eventName, () => {
                this.dragOverlayEl.style.display = 'flex';
            });
        });

        // Drag leave
        document.addEventListener('dragleave', (e) => {
            if (e.clientX === 0 && e.clientY === 0) {
                this.dragOverlayEl.style.display = 'none';
            }
        });

        // Drop
        document.addEventListener('drop', (e) => {
            this.dragOverlayEl.style.display = 'none';
            const files = Array.from(e.dataTransfer.files);
            this.handleDroppedFiles(files);
        });
    }

    async loadSettings() {
        try {
            const settings = await ipcRenderer.invoke('get-settings');
            this.settings = { ...this.settings, ...settings };
            this.applySettings();
        } catch (error) {
            console.error('Error loading settings:', error);
        }
    }

    async saveSettings() {
        try {
            await ipcRenderer.invoke('save-settings', this.settings);
        } catch (error) {
            console.error('Error saving settings:', error);
        }
    }

    applySettings() {
        this.fontFamilyEl.value = this.settings.fontFamily;
        this.fontSizeEl.value = this.settings.fontSize;
        this.fontSizeDisplayEl.textContent = `${this.settings.fontSize}px`;
        this.themeEl.value = this.settings.theme;
        this.autoScrollEl.checked = this.settings.autoScroll;
        this.scrollSpeedEl.value = this.settings.scrollSpeed;
        this.scrollSpeedDisplayEl.textContent = `${this.settings.scrollSpeed}x`;
        
        if (this.settings.autoScroll) {
            this.scrollControlsEl.classList.remove('hidden');
        }
        
        this.applyStorySettings();
        this.applyTheme();
    }

    applyStorySettings() {
        if (this.storyContent) {
            this.storyContentEl.style.fontSize = `${this.settings.fontSize}px`;
            this.storyContentEl.style.fontFamily = this.settings.fontFamily;
            this.storyContentEl.style.color = this.settings.textColor;
            this.storyContentEl.style.backgroundColor = this.settings.backgroundColor;
        }
    }

    applyTheme() {
        document.body.className = `theme-${this.settings.theme}`;
        
        if (this.settings.theme === 'light') {
            this.settings.backgroundColor = '#ffffff';
            this.settings.textColor = '#333333';
        } else if (this.settings.theme === 'sepia') {
            this.settings.backgroundColor = '#f9f8f0';
            this.settings.textColor = '#5c4b37';
        } else {
            this.settings.backgroundColor = '#1a1a1a';
            this.settings.textColor = '#ffffff';
        }
        
        this.applyStorySettings();
    }

    async openFile() {
        try {
            const result = await ipcRenderer.invoke('open-file-dialog');
            
            if (!result.canceled && result.filePaths.length > 0) {
                const filePath = result.filePaths[0];
                this.storyFileName = filePath.split('/').pop();
                const parseResult = await ipcRenderer.invoke('parse-document', filePath);
                
                if (parseResult.success) {
                    this.storyContent = parseResult.content;
                    this.displayStory();
                } else {
                    this.showError('Error parsing document: ' + parseResult.error);
                }
            }
        } catch (error) {
            this.showError('Error opening file: ' + error.message);
        }
    }

    displayStory() {
        if (this.storyContent) {
            this.storyContentEl.textContent = this.storyContent;
            this.storyContentEl.classList.remove('hidden');
            this.storyPlaceholderEl.classList.add('hidden');
            this.storyTitleEl.textContent = this.storyFileName || 'Story';
            
            this.applyStorySettings();
            this.updateReadingProgress();
            this.storyContentEl.focus();
        }
    }

    updateReadingProgress() {
        if (this.storyContentEl && this.storyContent) {
            const scrollTop = this.storyContentEl.scrollTop;
            const scrollHeight = this.storyContentEl.scrollHeight - this.storyContentEl.clientHeight;
            const progress = scrollHeight > 0 ? (scrollTop / scrollHeight) * 100 : 0;
            this.progressFillEl.style.width = `${progress}%`;
        }
    }

    updateFontFamily(family) {
        this.settings.fontFamily = family;
        this.applyStorySettings();
        this.saveSettings();
    }

    updateFontSize(size) {
        this.settings.fontSize = parseInt(size);
        this.fontSizeDisplayEl.textContent = `${size}px`;
        this.applyStorySettings();
        this.saveSettings();
    }

    updateTheme(theme) {
        this.settings.theme = theme;
        this.applyTheme();
        this.saveSettings();
    }

    toggleAutoScroll(enabled) {
        this.settings.autoScroll = enabled;
        
        if (enabled) {
            this.scrollControlsEl.classList.remove('hidden');
            this.startAutoScroll();
        } else {
            this.scrollControlsEl.classList.add('hidden');
            this.stopAutoScroll();
        }
        
        this.saveSettings();
    }

    updateScrollSpeed(speed) {
        this.settings.scrollSpeed = parseFloat(speed);
        this.scrollSpeedDisplayEl.textContent = `${speed}x`;
        
        if (this.settings.autoScroll) {
            this.stopAutoScroll();
            this.startAutoScroll();
        }
        
        this.saveSettings();
    }

    startAutoScroll() {
        if (this.autoScrollInterval) {
            clearInterval(this.autoScrollInterval);
        }
        
        this.autoScrollInterval = setInterval(() => {
            const maxScroll = this.storyContentEl.scrollHeight - this.storyContentEl.clientHeight;
            
            if (this.scrollPosition >= maxScroll) {
                this.scrollPosition = 0;
            } else {
                this.scrollPosition += this.settings.scrollSpeed;
            }
            
            this.storyContentEl.scrollTop = this.scrollPosition;
        }, 50);
    }

    stopAutoScroll() {
        if (this.autoScrollInterval) {
            clearInterval(this.autoScrollInterval);
            this.autoScrollInterval = null;
        }
    }

    handleKeyboard(e) {
        if (this.searchOverlayEl.style.display === 'block' && e.key === 'Escape') {
            this.toggleSearch();
            return;
        }
        
        if (!this.settings.autoScroll && this.storyContent && !this.searchInputEl.matches(':focus')) {
            const scrollAmount = this.storyContentEl.clientHeight * 0.8;
            
            switch (e.key) {
                case 'ArrowDown':
                case 'PageDown':
                    e.preventDefault();
                    this.scrollPosition = Math.min(
                        this.scrollPosition + scrollAmount,
                        this.storyContentEl.scrollHeight - this.storyContentEl.clientHeight
                    );
                    this.storyContentEl.scrollTop = this.scrollPosition;
                    break;
                    
                case 'ArrowUp':
                case 'PageUp':
                    e.preventDefault();
                    this.scrollPosition = Math.max(this.scrollPosition - scrollAmount, 0);
                    this.storyContentEl.scrollTop = this.scrollPosition;
                    break;
                    
                case 'Home':
                    e.preventDefault();
                    this.scrollPosition = 0;
                    this.storyContentEl.scrollTop = 0;
                    break;
                    
                case 'End':
                    e.preventDefault();
                    this.scrollPosition = this.storyContentEl.scrollHeight - this.storyContentEl.clientHeight;
                    this.storyContentEl.scrollTop = this.scrollPosition;
                    break;
                    
                case 'f':
                    if (e.ctrlKey || e.metaKey) {
                        e.preventDefault();
                        this.toggleSearch();
                    }
                    break;
                    
                case 'b':
                    if (e.ctrlKey || e.metaKey) {
                        e.preventDefault();
                        this.addBookmark();
                    }
                    break;
            }
        }
    }

    toggleSearch() {
        const isVisible = this.searchOverlayEl.style.display === 'block';
        this.searchOverlayEl.style.display = isVisible ? 'none' : 'block';
        
        if (!isVisible) {
            this.searchInputEl.focus();
        } else {
            this.clearSearchHighlights();
        }
    }

    performSearch(query) {
        this.clearSearchHighlights();
        
        if (!query || !this.storyContent) {
            this.searchResultsEl.textContent = '';
            return;
        }
        
        const regex = new RegExp(query, 'gi');
        const matches = [...this.storyContent.matchAll(regex)];
        
        if (matches.length === 0) {
            this.searchResultsEl.textContent = 'No results found';
            return;
        }
        
        this.searchResults = matches;
        this.currentSearchIndex = 0;
        this.searchResultsEl.textContent = `${matches.length} results found`;
        
        this.highlightSearchResults(query);
        this.jumpToSearchResult(0);
    }

    highlightSearchResults(query) {
        const content = this.storyContentEl.textContent;
        const regex = new RegExp(query, 'gi');
        const highlightedContent = content.replace(regex, '<mark class="highlight">$&</mark>');
        this.storyContentEl.innerHTML = highlightedContent;
    }

    clearSearchHighlights() {
        if (this.storyContent) {
            this.storyContentEl.textContent = this.storyContent;
        }
    }

    jumpToSearchResult(index) {
        const highlights = this.storyContentEl.querySelectorAll('.highlight');
        if (highlights.length > 0 && index < highlights.length) {
            highlights[index].scrollIntoView({ behavior: 'smooth', block: 'center' });
        }
    }

    handleSearchKeydown(e) {
        if (e.key === 'Enter') {
            if (this.searchResults.length > 0) {
                this.currentSearchIndex = (this.currentSearchIndex + 1) % this.searchResults.length;
                this.jumpToSearchResult(this.currentSearchIndex);
            }
        }
    }

    async addBookmark() {
        if (!this.storyContent) return;
        
        const scrollPosition = this.storyContentEl.scrollTop;
        const totalHeight = this.storyContentEl.scrollHeight - this.storyContentEl.clientHeight;
        const percentage = totalHeight > 0 ? (scrollPosition / totalHeight) * 100 : 0;
        
        // Get preview text around current position
        const contentLines = this.storyContent.split('\n');
        const currentLine = Math.floor((scrollPosition / this.storyContentEl.scrollHeight) * contentLines.length);
        const previewText = contentLines.slice(Math.max(0, currentLine - 2), currentLine + 3).join(' ').substring(0, 100);
        
        const bookmark = {
            title: `Bookmark ${this.bookmarks.length + 1}`,
            storyFile: this.storyFileName,
            scrollPosition: scrollPosition,
            percentage: percentage,
            preview: previewText,
            timestamp: new Date().toISOString()
        };
        
        try {
            const savedBookmark = await ipcRenderer.invoke('save-bookmark', bookmark);
            this.bookmarks.push(savedBookmark);
            this.updateBookmarksList();
            this.showNotification('Bookmark added');
        } catch (error) {
            this.showError('Error saving bookmark: ' + error.message);
        }
    }

    async loadBookmarks() {
        try {
            this.bookmarks = await ipcRenderer.invoke('get-bookmarks');
            this.updateBookmarksList();
        } catch (error) {
            console.error('Error loading bookmarks:', error);
        }
    }

    updateBookmarksList() {
        this.bookmarksListEl.innerHTML = '';
        
        if (this.bookmarks.length === 0) {
            this.bookmarksListEl.innerHTML = '<div style="color: #666; text-align: center; padding: 20px;">No bookmarks yet</div>';
            return;
        }
        
        this.bookmarks.forEach(bookmark => {
            const bookmarkEl = document.createElement('div');
            bookmarkEl.className = 'bookmark-item';
            bookmarkEl.innerHTML = `
                <div class="bookmark-title">${bookmark.title}</div>
                <div class="bookmark-preview">${bookmark.preview}</div>
                <div class="bookmark-date">${new Date(bookmark.createdAt).toLocaleString()}</div>
            `;
            
            bookmarkEl.addEventListener('click', () => this.jumpToBookmark(bookmark));
            this.bookmarksListEl.appendChild(bookmarkEl);
        });
    }

    jumpToBookmark(bookmark) {
        if (this.storyFileName === bookmark.storyFile) {
            this.storyContentEl.scrollTop = bookmark.scrollPosition;
            this.scrollPosition = bookmark.scrollPosition;
            this.hideBookmarks();
        } else {
            this.showError('Please open the story file: ' + bookmark.storyFile);
        }
    }

    toggleBookmarks() {
        const isVisible = this.bookmarksPanelEl.style.display === 'block';
        this.bookmarksPanelEl.style.display = isVisible ? 'none' : 'block';
    }

    hideBookmarks() {
        this.bookmarksPanelEl.style.display = 'none';
    }

    addMediaGrid() {
        const gridId = Date.now();
        const grid = {
            id: gridId,
            title: `Grid ${this.mediaGrids.length + 1}`,
            mediaItems: [],
            currentIndex: 0,
            isPlaying: false,
            height: 250,
            settings: {
                autoPlay: false,
                displayTime: 5000,
                zoom: 'fit'
            }
        };
        
        this.mediaGrids.push(grid);
        this.renderMediaGrid(grid);
        this.updateMediaPlaceholder();
    }

    renderMediaGrid(grid) {
        const gridEl = document.createElement('div');
        gridEl.className = 'media-grid';
        gridEl.id = `grid-${grid.id}`;
        gridEl.style.height = `${grid.height + 50}px`;
        
        gridEl.innerHTML = `
            <div class="media-grid-header">
                <span class="media-grid-title">${grid.title} (${grid.mediaItems.length} items)</span>
                <div class="media-grid-controls">
                    <button onclick="app.editGridTitle(${grid.id})">✏️</button>
                    <button onclick="app.addMediaToGrid(${grid.id})">➕</button>
                    <button onclick="app.configureGrid(${grid.id})">⚙️</button>
                    <button onclick="app.removeMediaGrid(${grid.id})">🗑️</button>
                </div>
            </div>
            <div class="media-grid-content" style="height: ${grid.height}px;">
                ${grid.mediaItems.length === 0 ? 
                    '<div style="color: #666; text-align: center;"><div>📷</div><div style="font-size: 12px; margin-top: 5px;">Click + to add media</div></div>' :
                    this.renderMediaItem(grid, grid.mediaItems[grid.currentIndex])
                }
                ${grid.mediaItems.length > 0 ? `
                    <div class="media-controls">
                        <button onclick="app.previousMedia(${grid.id})">⏮️</button>
                        <button onclick="app.togglePlayback(${grid.id})">${grid.isPlaying ? '⏸️' : '▶️'}</button>
                        <button onclick="app.nextMedia(${grid.id})">⏭️</button>
                        <button onclick="app.toggleFullscreen(${grid.id})">🔍</button>
                        <span style="font-size: 10px; color: #ccc;">
                            ${grid.currentIndex + 1}/${grid.mediaItems.length}
                        </span>
                    </div>
                    <div class="media-playlist">
                        <div class="playlist-header">Playlist:</div>
                        ${grid.mediaItems.map((item, index) => `
                            <div class="playlist-item ${index === grid.currentIndex ? 'active' : ''}"
                                 onclick="app.setMediaIndex(${grid.id}, ${index})">
                                <span class="playlist-item-name">${item.name}</span>
                                <button class="playlist-item-remove" onclick="event.stopPropagation(); app.removeMediaFromGrid(${grid.id}, ${index})">×</button>
                            </div>
                        `).join('')}
                    </div>
                ` : ''}
            </div>
            <div class="resize-handle" onmousedown="app.startResize(event, ${grid.id})"></div>
        `;
        
        this.mediaGridsEl.appendChild(gridEl);
        this.setupGridDragAndDrop(gridEl);
    }

    setupGridDragAndDrop(gridEl) {
        const header = gridEl.querySelector('.media-grid-header');
        const content = gridEl.querySelector('.media-grid-content');
        
        // Grid drag functionality
        let isDragging = false;
        let startY = 0;
        let startTop = 0;
        
        header.addEventListener('mousedown', (e) => {
            isDragging = true;
            startY = e.clientY;
            startTop = parseInt(window.getComputedStyle(gridEl).top) || 0;
            gridEl.classList.add('dragging');
            
            document.addEventListener('mousemove', handleMouseMove);
            document.addEventListener('mouseup', handleMouseUp);
        });
        
        const handleMouseMove = (e) => {
            if (!isDragging) return;
            
            const deltaY = e.clientY - startY;
            const newTop = startTop + deltaY;
            gridEl.style.position = 'relative';
            gridEl.style.top = `${newTop}px`;
        };
        
        const handleMouseUp = () => {
            isDragging = false;
            gridEl.classList.remove('dragging');
            document.removeEventListener('mousemove', handleMouseMove);
            document.removeEventListener('mouseup', handleMouseUp);
        };
        
        // Media file drop functionality
        content.addEventListener('dragover', (e) => {
            e.stopPropagation();
            content.style.borderColor = '#4a90e2';
        });
        
        content.addEventListener('dragleave', (e) => {
            e.stopPropagation();
            content.style.borderColor = '';
        });
        
        content.addEventListener('drop', (e) => {
            e.stopPropagation();
            content.style.borderColor = '';
            
            const gridId = parseInt(gridEl.id.split('-')[1]);
            const files = Array.from(e.dataTransfer.files);
            this.addFilesToGrid(gridId, files);
        });
    }

    startResize(e, gridId) {
        e.preventDefault();
        
        const grid = this.mediaGrids.find(g => g.id === gridId);
        if (!grid) return;
        
        const gridEl = document.getElementById(`grid-${gridId}`);
        const contentEl = gridEl.querySelector('.media-grid-content');
        
        gridEl.classList.add('resizing');
        
        const startY = e.clientY;
        const startHeight = grid.height;
        
        const handleMouseMove = (e) => {
            const deltaY = e.clientY - startY;
            const newHeight = Math.max(150, startHeight + deltaY);
            
            grid.height = newHeight;
            contentEl.style.height = `${newHeight}px`;
            gridEl.style.height = `${newHeight + 50}px`;
        };
        
        const handleMouseUp = () => {
            gridEl.classList.remove('resizing');
            document.removeEventListener('mousemove', handleMouseMove);
            document.removeEventListener('mouseup', handleMouseUp);
        };
        
        document.addEventListener('mousemove', handleMouseMove);
        document.addEventListener('mouseup', handleMouseUp);
    }

    renderMediaItem(grid, item) {
        if (!item) return '';
        
        const filePath = `file://${item.path}`;
        
        if (item.type === 'image') {
            return `<img src="${filePath}" alt="${item.name}" style="object-fit: ${grid.settings.zoom};">`;
        } else if (item.type === 'video') {
            return `<video src="${filePath}" ${grid.isPlaying ? 'autoplay' : ''} controls style="object-fit: ${grid.settings.zoom};">`;
        }
        
        return '';
    }

    async addMediaToGrid(gridId) {
        try {
            const result = await ipcRenderer.invoke('open-media-dialog');
            
            if (!result.canceled && result.filePaths.length > 0) {
                this.addFilesToGrid(gridId, result.filePaths.map(path => ({ path })));
            }
        } catch (error) {
            this.showError('Error adding media: ' + error.message);
        }
    }

    addFilesToGrid(gridId, files) {
        const grid = this.mediaGrids.find(g => g.id === gridId);
        if (!grid) return;
        
        const newMediaItems = files.map(file => ({
            id: Date.now() + Math.random(),
            path: file.path,
            type: this.getMediaType(file.path),
            name: file.path.split('/').pop()
        }));
        
        grid.mediaItems.push(...newMediaItems);
        this.updateMediaGrid(grid);
    }

    handleDroppedFiles(files) {
        if (this.mediaGrids.length === 0) {
            this.addMediaGrid();
        }
        
        const mediaFiles = files.filter(file => 
            file.type.startsWith('image/') || file.type.startsWith('video/')
        );
        
        if (mediaFiles.length > 0) {
            const lastGrid = this.mediaGrids[this.mediaGrids.length - 1];
            this.addFilesToGrid(lastGrid.id, mediaFiles);
        }
    }

    getMediaType(filePath) {
        const ext = filePath.split('.').pop().toLowerCase();
        if (['jpg', 'jpeg', 'png', 'gif', 'webp'].includes(ext)) {
            return 'image';
        } else if (['mp4', 'avi', 'mov', 'webm', 'mkv'].includes(ext)) {
            return 'video';
        }
        return 'unknown';
    }

    updateMediaGrid(grid) {
        const gridEl = document.getElementById(`grid-${grid.id}`);
        if (gridEl) {
            gridEl.remove();
        }
        this.renderMediaGrid(grid);
    }

    editGridTitle(gridId) {
        const grid = this.mediaGrids.find(g => g.id === gridId);
        if (!grid) return;
        
        const newTitle = prompt('Enter new grid title:', grid.title);
        if (newTitle) {
            grid.title = newTitle;
            this.updateMediaGrid(grid);
        }
    }

    removeMediaGrid(gridId) {
        this.mediaGrids = this.mediaGrids.filter(g => g.id !== gridId);
        const gridEl = document.getElementById(`grid-${gridId}`);
        if (gridEl) {
            gridEl.remove();
        }
        this.updateMediaPlaceholder();
    }

    clearAllGrids() {
        if (confirm('Are you sure you want to clear all media grids?')) {
            this.mediaGrids = [];
            this.mediaGridsEl.innerHTML = '';
            this.updateMediaPlaceholder();
        }
    }

    setMediaIndex(gridId, index) {
        const grid = this.mediaGrids.find(g => g.id === gridId);
        if (!grid || index < 0 || index >= grid.mediaItems.length) return;
        
        grid.currentIndex = index;
        this.updateMediaGrid(grid);
    }

    previousMedia(gridId) {
        const grid = this.mediaGrids.find(g => g.id === gridId);
        if (!grid || grid.mediaItems.length === 0) return;
        
        grid.currentIndex = grid.currentIndex === 0 ? 
            grid.mediaItems.length - 1 : grid.currentIndex - 1;
        this.updateMediaGrid(grid);
    }

    nextMedia(gridId) {
        const grid = this.mediaGrids.find(g => g.id === gridId);
        if (!grid || grid.mediaItems.length === 0) return;
        
        grid.currentIndex = (grid.currentIndex + 1) % grid.mediaItems.length;
        this.updateMediaGrid(grid);
    }

    togglePlayback(gridId) {
        const grid = this.mediaGrids.find(g => g.id === gridId);
        if (!grid || grid.mediaItems.length === 0) return;
        
        grid.isPlaying = !grid.isPlaying;
        this.updateMediaGrid(grid);
        
        if (grid.isPlaying) {
            this.startMediaPlayback(grid);
        } else {
            this.stopMediaPlayback(grid);
        }
    }

    startMediaPlayback(grid) {
        if (grid.playbackInterval) {
            clearInterval(grid.playbackInterval);
        }
        
        const currentItem = grid.mediaItems[grid.currentIndex];
        if (currentItem && currentItem.type === 'image') {
            grid.playbackInterval = setTimeout(() => {
                this.nextMedia(grid.id);
                if (grid.isPlaying) {
                    this.startMediaPlayback(grid);
                }
            }, grid.settings.displayTime);
        }
    }

    stopMediaPlayback(grid) {
        if (grid.playbackInterval) {
            clearTimeout(grid.playbackInterval);
            grid.playbackInterval = null;
        }
    }

    removeMediaFromGrid(gridId, index) {
        const grid = this.mediaGrids.find(g => g.id === gridId);
        if (!grid || index < 0 || index >= grid.mediaItems.length) return;
        
        grid.mediaItems.splice(index, 1);
        
        if (grid.currentIndex >= grid.mediaItems.length) {
            grid.currentIndex = Math.max(0, grid.mediaItems.length - 1);
        }
        
        this.updateMediaGrid(grid);
    }

    updateMediaPlaceholder() {
        if (this.mediaGrids.length === 0) {
            this.mediaPlaceholderEl.classList.remove('hidden');
        } else {
            this.mediaPlaceholderEl.classList.add('hidden');
        }
    }

    // Layout management
    showSaveLayoutModal() {
        document.getElementById('saveLayoutModal').style.display = 'block';
    }

    closeSaveLayoutModal() {
        document.getElementById('saveLayoutModal').style.display = 'none';
    }

    async saveCurrentLayout() {
        const name = document.getElementById('layoutName').value.trim();
        const description = document.getElementById('layoutDescription').value.trim();
        
        if (!name) {
            alert('Please enter a layout name');
            return;
        }
        
        const layout = {
            name,
            description,
            mediaGrids: this.mediaGrids.map(grid => ({
                ...grid,
                mediaItems: grid.mediaItems.map(item => ({
                    ...item,
                    // Store relative paths for portability
                    relativePath: item.path
                }))
            })),
            settings: this.settings
        };
        
        try {
            await ipcRenderer.invoke('save-layout', { name, layout });
            this.closeSaveLayoutModal();
            this.showNotification('Layout saved successfully');
        } catch (error) {
            this.showError('Error saving layout: ' + error.message);
        }
    }

    async showLoadLayoutModal() {
        try {
            const layouts = await ipcRenderer.invoke('get-all-layouts');
            const layoutsList = document.getElementById('layoutsList');
            
            layoutsList.innerHTML = '';
            
            if (Object.keys(layouts).length === 0) {
                layoutsList.innerHTML = '<div style="color: #666; text-align: center; padding: 20px;">No saved layouts</div>';
            } else {
                Object.entries(layouts).forEach(([name, layout]) => {
                    const layoutEl = document.createElement('div');
                    layoutEl.className = 'layout-item';
                    layoutEl.style.cssText = 'padding: 10px; margin: 5px 0; background: #3a3a3a; border-radius: 4px; cursor: pointer;';
                    
                    layoutEl.innerHTML = `
                        <div style="font-weight: 500; margin-bottom: 5px;">${name}</div>
                        <div style="font-size: 12px; color: #ccc;">${layout.description || 'No description'}</div>
                        <div style="font-size: 10px; color: #888; margin-top: 5px;">
                            ${layout.mediaGrids?.length || 0} grids • Created: ${new Date(layout.createdAt).toLocaleDateString()}
                        </div>
                    `;
                    
                    layoutEl.addEventListener('click', () => this.loadLayout(name));
                    layoutsList.appendChild(layoutEl);
                });
            }
            
            document.getElementById('loadLayoutModal').style.display = 'block';
        } catch (error) {
            this.showError('Error loading layouts: ' + error.message);
        }
    }

    closeLoadLayoutModal() {
        document.getElementById('loadLayoutModal').style.display = 'none';
    }

    async loadLayout(name) {
        try {
            const layout = await ipcRenderer.invoke('load-layout', name);
            if (!layout) {
                this.showError('Layout not found');
                return;
            }
            
            // Clear existing grids
            this.mediaGrids = [];
            this.mediaGridsEl.innerHTML = '';
            
            // Load layout data
            if (layout.mediaGrids) {
                this.mediaGrids = layout.mediaGrids.map(grid => ({
                    ...grid,
                    mediaItems: grid.mediaItems.map(item => ({
                        ...item,
                        path: item.relativePath || item.path
                    }))
                }));
                
                this.mediaGrids.forEach(grid => this.renderMediaGrid(grid));
            }
            
            if (layout.settings) {
                this.settings = { ...this.settings, ...layout.settings };
                this.applySettings();
            }
            
            this.updateMediaPlaceholder();
            this.closeLoadLayoutModal();
            this.showNotification('Layout loaded successfully');
        } catch (error) {
            this.showError('Error loading layout: ' + error.message);
        }
    }

    async packageLayout() {
        const name = prompt('Enter package name:');
        if (!name) return;
        
        const mediaFiles = [];
        this.mediaGrids.forEach(grid => {
            grid.mediaItems.forEach(item => {
                mediaFiles.push({
                    path: item.path,
                    name: item.name
                });
            });
        });
        
        const layout = {
            name,
            mediaGrids: this.mediaGrids,
            settings: this.settings,
            storyFile: this.storyFileName
        };
        
        try {
            const result = await ipcRenderer.invoke('package-layout', { name, layout, mediaFiles });
            if (result.success) {
                this.showNotification('Package created successfully');
            } else {
                this.showError('Error creating package: ' + result.error);
            }
        } catch (error) {
            this.showError('Error creating package: ' + error.message);
        }
    }

    async importLayout() {
        try {
            const result = await ipcRenderer.invoke('import-layout');
            if (result.success) {
                // Clear existing grids
                this.mediaGrids = [];
                this.mediaGridsEl.innerHTML = '';
                
                // Load imported layout
                const { layout, mediaFiles } = result;
                
                if (layout.mediaGrids) {
                    this.mediaGrids = layout.mediaGrids.map(grid => ({
                        ...grid,
                        mediaItems: grid.mediaItems.map(item => {
                            const matchingFile = mediaFiles.find(f => f.name === item.name);
                            return {
                                ...item,
                                path: matchingFile ? matchingFile.path : item.path
                            };
                        })
                    }));
                    
                    this.mediaGrids.forEach(grid => this.renderMediaGrid(grid));
                }
                
                if (layout.settings) {
                    this.settings = { ...this.settings, ...layout.settings };
                    this.applySettings();
                }
                
                this.updateMediaPlaceholder();
                this.showNotification('Layout imported successfully');
            } else {
                this.showError('Error importing layout: ' + result.error);
            }
        } catch (error) {
            this.showError('Error importing layout: ' + error.message);
        }
    }

    closeAllModals() {
        document.querySelectorAll('.modal').forEach(modal => {
            modal.style.display = 'none';
        });
    }

    showNotification(message) {
        // Simple notification system
        const notification = document.createElement('div');
        notification.textContent = message;
        notification.style.cssText = `
            position: fixed;
            top: 20px;
            right: 20px;
            background: #4a90e2;
            color: white;
            padding: 10px 20px;
            border-radius: 4px;
            z-index: 1001;
            animation: slideIn 0.3s ease;
        `;
        
        document.body.appendChild(notification);
        
        setTimeout(() => {
            notification.remove();
        }, 3000);
    }

    showError(message) {
        alert(message);
    }
}

// Initialize the app when the DOM is loaded
let app;
document.addEventListener('DOMContentLoaded', () => {
    app = new AdvancedStoryReader();
});

// Add CSS animation for notifications
const style = document.createElement('style');
style.textContent = `
    @keyframes slideIn {
        from { transform: translateX(100%); opacity: 0; }
        to { transform: translateX(0); opacity: 1; }
    }
`;
document.head.appendChild(style);
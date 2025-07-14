const { app, BrowserWindow, ipcMain, dialog } = require('electron');
const path = require('path');
const fs = require('fs').promises;
const officeParser = require('officeparser');
const { JSDOM } = require('jsdom');
const Store = require('electron-store').default || require('electron-store');
const JSZip = require('jszip');

let mainWindow;
const store = new Store();

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1400,
    height: 900,
    webPreferences: {
      nodeIntegration: true,
      contextIsolation: false,
      enableRemoteModule: true,
    },
  });

  // Load the HTML file directly
  mainWindow.loadFile(path.join(__dirname, '../renderer/index.html'));
  
  if (process.env.NODE_ENV === 'development') {
    mainWindow.webContents.openDevTools();
  }
}

app.whenReady().then(createWindow);

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

app.on('activate', () => {
  if (BrowserWindow.getAllWindows().length === 0) {
    createWindow();
  }
});

// IPC handlers for file operations
ipcMain.handle('open-file-dialog', async () => {
  const result = await dialog.showOpenDialog(mainWindow, {
    properties: ['openFile'],
    filters: [
      { name: 'Story Files', extensions: ['docx', 'pdf', 'html', 'txt'] },
      { name: 'All Files', extensions: ['*'] }
    ]
  });
  return result;
});

ipcMain.handle('parse-document', async (event, filePath) => {
  try {
    const ext = path.extname(filePath).toLowerCase();
    let content = '';

    if (ext === '.txt') {
      content = await fs.readFile(filePath, 'utf8');
    } else if (ext === '.html') {
      const htmlContent = await fs.readFile(filePath, 'utf8');
      const dom = new JSDOM(htmlContent);
      content = dom.window.document.body.textContent || '';
    } else if (ext === '.docx' || ext === '.pdf') {
      content = await officeParser.parseOfficeAsync(filePath);
    }

    return { success: true, content };
  } catch (error) {
    return { success: false, error: error.message };
  }
});

ipcMain.handle('open-media-dialog', async () => {
  const result = await dialog.showOpenDialog(mainWindow, {
    properties: ['openFile', 'multiSelections'],
    filters: [
      { name: 'Media Files', extensions: ['jpg', 'jpeg', 'png', 'gif', 'mp4', 'avi', 'mov', 'webm'] },
      { name: 'All Files', extensions: ['*'] }
    ]
  });
  return result;
});

// Settings management
ipcMain.handle('get-settings', async () => {
  return store.get('settings', {
    fontSize: 16,
    fontFamily: 'Georgia',
    backgroundColor: '#1a1a1a',
    textColor: '#ffffff',
    autoScroll: false,
    scrollSpeed: 1,
    theme: 'dark'
  });
});

ipcMain.handle('save-settings', async (event, settings) => {
  store.set('settings', settings);
  return true;
});

// Layout management
ipcMain.handle('save-layout', async (event, layoutData) => {
  const { name, layout } = layoutData;
  const layouts = store.get('layouts', {});
  layouts[name] = {
    ...layout,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  };
  store.set('layouts', layouts);
  return true;
});

ipcMain.handle('load-layout', async (event, name) => {
  const layouts = store.get('layouts', {});
  return layouts[name] || null;
});

ipcMain.handle('get-all-layouts', async () => {
  return store.get('layouts', {});
});

ipcMain.handle('delete-layout', async (event, name) => {
  const layouts = store.get('layouts', {});
  delete layouts[name];
  store.set('layouts', layouts);
  return true;
});

// Bookmarks management
ipcMain.handle('save-bookmark', async (event, bookmarkData) => {
  const bookmarks = store.get('bookmarks', []);
  const bookmark = {
    id: Date.now(),
    ...bookmarkData,
    createdAt: new Date().toISOString()
  };
  bookmarks.push(bookmark);
  store.set('bookmarks', bookmarks);
  return bookmark;
});

ipcMain.handle('get-bookmarks', async () => {
  return store.get('bookmarks', []);
});

ipcMain.handle('delete-bookmark', async (event, id) => {
  const bookmarks = store.get('bookmarks', []);
  const filtered = bookmarks.filter(b => b.id !== id);
  store.set('bookmarks', filtered);
  return true;
});

// Package layout with media files
ipcMain.handle('package-layout', async (event, packageData) => {
  try {
    const { name, layout, mediaFiles } = packageData;
    const zip = new JSZip();
    
    // Add layout metadata
    zip.file('layout.json', JSON.stringify(layout, null, 2));
    
    // Add media files
    const mediaFolder = zip.folder('media');
    for (const mediaFile of mediaFiles) {
      const fileContent = await fs.readFile(mediaFile.path);
      mediaFolder.file(mediaFile.name, fileContent);
    }
    
    // Generate zip file
    const zipContent = await zip.generateAsync({ type: 'nodebuffer' });
    
    // Save to user-selected location
    const result = await dialog.showSaveDialog(mainWindow, {
      defaultPath: `${name}.storypack`,
      filters: [
        { name: 'Story Pack', extensions: ['storypack'] }
      ]
    });
    
    if (!result.canceled) {
      await fs.writeFile(result.filePath, zipContent);
      return { success: true, path: result.filePath };
    }
    
    return { success: false, error: 'Save cancelled' };
  } catch (error) {
    return { success: false, error: error.message };
  }
});

// Import packaged layout
ipcMain.handle('import-layout', async () => {
  try {
    const result = await dialog.showOpenDialog(mainWindow, {
      properties: ['openFile'],
      filters: [
        { name: 'Story Pack', extensions: ['storypack'] }
      ]
    });
    
    if (result.canceled) {
      return { success: false, error: 'Import cancelled' };
    }
    
    const zipContent = await fs.readFile(result.filePaths[0]);
    const zip = await JSZip.loadAsync(zipContent);
    
    // Extract layout metadata
    const layoutFile = zip.file('layout.json');
    if (!layoutFile) {
      return { success: false, error: 'Invalid story pack format' };
    }
    
    const layout = JSON.parse(await layoutFile.async('string'));
    
    // Extract media files to temp directory
    const tempDir = path.join(require('os').tmpdir(), 'storyreader', Date.now().toString());
    await fs.mkdir(tempDir, { recursive: true });
    
    const mediaFiles = [];
    const mediaFolder = zip.folder('media');
    if (mediaFolder) {
      for (const [fileName, file] of Object.entries(mediaFolder.files)) {
        if (!file.dir) {
          const content = await file.async('nodebuffer');
          const filePath = path.join(tempDir, fileName);
          await fs.writeFile(filePath, content);
          mediaFiles.push({
            name: fileName,
            path: filePath
          });
        }
      }
    }
    
    return { success: true, layout, mediaFiles, tempDir };
  } catch (error) {
    return { success: false, error: error.message };
  }
});
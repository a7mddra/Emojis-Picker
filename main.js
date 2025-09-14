const { app, BrowserWindow, globalShortcut } = require('electron');
const path = require('path');

function createWindow() {
  const win = new BrowserWindow({
    width: 360,
    height: 440,
    frame: false,
    transparent: true,
    alwaysOnTop: true,
    resizable: false,
    skipTaskbar: true,
    hasShadow: true,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
      enableRemoteModule: false
    }
  });

  // Makes the window stay above fullscreen apps
  win.setAlwaysOnTop(true, 'screen-saver');
  
  // Set window to appear at cursor position (optional)
  win.setVisibleOnAllWorkspaces(true);

  win.loadFile('index.html');

  // Position window at center of screen when first shown
  win.once('ready-to-show', () => {
    win.center();
  });

  // Hide window on blur (when clicking outside)
  win.on('blur', () => {
    // Small delay to allow for internal clicks
    setTimeout(() => {
      if (!win.isFocused()) {
        win.hide();
      }
    }, 100);
  });

  // Hide window on ESC key
  win.webContents.on('before-input-event', (event, input) => {
    if (input.key === 'Escape') {
      win.hide();
    }
  });

  // Handle window close
  win.on('close', (event) => {
    event.preventDefault();
    win.hide();
  });

  // Optional: remove from alt-tab
  try {
    win.setAppUserModelId('com.example.emoji-picker');
  } catch (e) {
    console.log('Could not set app user model ID:', e);
  }

  // Development shortcuts
  if (process.env.NODE_ENV === 'development') {
    win.webContents.openDevTools();
  }

  return win;
}

let mainWindow;

app.whenReady().then(() => {
  mainWindow = createWindow();
  
  // Register global shortcut (Ctrl+Alt+E) to show/hide
  const shortcut = process.platform === 'darwin' ? 'Command+Alt+E' : 'Control+Alt+E';
  
  const registerResult = globalShortcut.register(shortcut, () => {
    if (mainWindow) {
      if (mainWindow.isVisible()) {
        mainWindow.hide();
      } else {
        mainWindow.show();
        mainWindow.focus();
      }
    }
  });

  if (!registerResult) {
    console.log('Failed to register global shortcut');
  } else {
    console.log(`Emoji picker registered with shortcut: ${shortcut}`);
  }

  // macOS specific behavior
  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      mainWindow = createWindow();
    } else if (mainWindow) {
      mainWindow.show();
    }
  });
});

app.on('window-all-closed', () => {
  // On macOS, keep the app running even when all windows are closed
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

app.on('before-quit', (event) => {
  // Allow the app to quit normally
  if (mainWindow) {
    mainWindow.destroy();
  }
});

app.on('will-quit', () => {
  // Unregister all global shortcuts
  globalShortcut.unregisterAll();
  console.log('Global shortcuts unregistered');
});

// Handle app errors
process.on('uncaughtException', (error) => {
  console.error('Uncaught Exception:', error);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
});

// Export for potential use in other modules
module.exports = { createWindow };
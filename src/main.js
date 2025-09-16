const { app, BrowserWindow, globalShortcut, ipcMain } = require('electron');
const path = require('path');

function createWindow() {
  const win = new BrowserWindow({
    width: 360,
    height: 440,
    frame: false,
    transparent: true,
    alwaysOnTop: true,
    resizable: false,
    skipTaskbar: false,
    hasShadow: true,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false
    }
  });

  win.setAlwaysOnTop(true, 'screen-saver');
  win.setVisibleOnAllWorkspaces(true);

  win.loadFile('index.html');

  win.once('ready-to-show', () => win.center());

  win.on('close', (event) => {
    event.preventDefault();
    win.hide();
  });

  try {
    win.setAppUserModelId('com.a7md.emojiz');
  } catch (e) {}

  if (process.env.NODE_ENV === 'development') {
    win.webContents.openDevTools({ mode: 'detach' });
  }

  return win;
}

let mainWindow;

ipcMain.on('minimize-window', (event) => {
  try {
    if (mainWindow && !mainWindow.isDestroyed()) {
      mainWindow.minimize();
    }
  } catch (e) {
    console.warn('Failed to minimize window:', e && e.message);
  }
});

app.whenReady().then(() => {
  mainWindow = createWindow();
  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) mainWindow = createWindow();
    else if (mainWindow) mainWindow.show();
  });
});

app.on('will-quit', () => {
  globalShortcut.unregisterAll();
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});

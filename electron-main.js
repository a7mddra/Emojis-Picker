const { app, BrowserWindow, globalShortcut } = require('electron');
const path = require('path');

app.commandLine.appendSwitch('enable-features', 'UseOzonePlatform');
app.commandLine.appendSwitch('ozone-platform', 'wayland');

app.commandLine.appendSwitch('enable-gpu-rasterization');
app.commandLine.appendSwitch('enable-zero-copy');

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
    win.setAppUserModelId('com.a7md.emoji-picker');
  } catch (e) {}

  if (process.env.NODE_ENV === 'development') {
    win.webContents.openDevTools({ mode: 'detach' });
  }

  return win;
}

let mainWindow;

app.whenReady().then(() => {
  mainWindow = createWindow();

  const shortcut = process.platform === 'darwin' ? 'Command+Alt+E' : 'Control+Alt+E';
  if (!globalShortcut.register(shortcut, () => {
    if (mainWindow) {
      if (mainWindow.isVisible()) { mainWindow.hide(); }
      else { mainWindow.show(); mainWindow.focus(); }
    }
  })) {
    console.log('Failed to register global shortcut');
  } else {
    console.log(`Registered shortcut: ${shortcut}`);
  }

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

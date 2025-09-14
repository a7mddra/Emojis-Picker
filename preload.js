const { contextBridge, clipboard } = require('electron');

contextBridge.exposeInMainWorld('electronAPI', {
  copyText: (text) => {
    try {
      clipboard.writeText(String(text));
      return true;
    } catch (e) {
      return false;
    }
  }
});
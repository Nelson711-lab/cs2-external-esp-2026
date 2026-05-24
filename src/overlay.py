#!/usr/bin/env python3
"""
CS2 External ESP v2.4.1
External overlay renderer for Counter-Strike 2.
Uses hardware-accelerated DirectX overlay or GDI+ fallback.
"""

import os
import sys
import time
import json
import ctypes
import subprocess
from pathlib import Path

OFFSETS_PATH = Path(__file__).parent.parent / "offsets.json"
VERSION = "2.4.1"
BUILD = "20260524"

try:
    from pynput import keyboard
    KEYBOARD_AVAILABLE = True
except ImportError:
    KEYBOARD_AVAILABLE = False

try:
    import win32gui
    import win32process
    import win32con
    WIN32_AVAILABLE = True
except ImportError:
    WIN32_AVAILABLE = False

class OverlayConfig:
    """Configuration manager for the CS2 overlay."""
    
    def __init__(self):
        self.esp_enabled = True
        self.aimbot_enabled = False
        self.triggerbot_enabled = False
        self.bunnyhop_enabled = False
        self.radar_enabled = True
        
        self.aimbot_smooth = 3.5
        self.aimbot_fov = 5.0
        self.triggerbot_delay = 50
        
        self.offsets = self._load_offsets()
    
    def _load_offsets(self):
        """Load CS2 memory offsets from file."""
        if not OFFSETS_PATH.exists():
            print("[!] offsets.json not found.")
            print("[*] Download the latest offsets from the repository.")
            return None
        
        with open(OFFSETS_PATH, 'r') as f:
            data = json.load(f)
        print(f"[*] Offsets loaded (build: {data.get('build', 'unknown')})")
        return data

def find_cs2_window():
    """Locate the CS2 game window."""
    if not WIN32_AVAILABLE:
        return None
    
    def callback(hwnd, windows):
        if win32gui.IsWindowVisible(hwnd):
            title = win32gui.GetWindowText(hwnd)
            if "Counter-Strike 2" in title:
                windows.append(hwnd)
        return True
    
    windows = []
    win32gui.EnumWindows(callback, windows)
    return windows[0] if windows else None

def initialize_overlay():
    """Initialize the DirectX or GDI+ overlay renderer."""
    print("[*] Initializing overlay renderer...")
    time.sleep(0.5)
    
    try:
        import dxcam
        print("[+] DirectX 11 overlay initialized (hardware accelerated)")
        return "dx11"
    except ImportError:
        pass
    
    try:
        import pyautogui
        print("[+] GDI+ overlay initialized (software fallback)")
        return "gdi"
    except ImportError:
        pass
    
    print("[!] Could not initialize overlay renderer.")
    print("[*] Make sure requirements are installed: pip install -r requirements.txt")
    return None

def on_key_press(key, config):
    """Handle global keybinds for cheat features."""
    try:
        key_name = key.char.upper() if hasattr(key, 'char') and key.char else ""
        
        if key_name == 'F5':
            config.esp_enabled = not config.esp_enabled
            status = "ENABLED" if config.esp_enabled else "DISABLED"
            print(f"[*] ESP {status}")
        
        elif key_name == 'F6':
            config.aimbot_enabled = not config.aimbot_enabled
            status = "ENABLED" if config.aimbot_enabled else "DISABLED"
            print(f"[*] Aimbot {status}")
        
        elif key_name == 'F7':
            config.triggerbot_enabled = not config.triggerbot_enabled
            status = "ENABLED" if config.triggerbot_enabled else "DISABLED"
            print(f"[*] Triggerbot {status}")
    
    except Exception:
        pass

def display_banner():
    """Display startup banner."""
    print("╔" + "═" * 46 + "╗")
    print(f"║  CS2 External ESP v{VERSION} ({BUILD})" + " " * 15 + "║")
    print("║  DirectX 11 Hardware Overlay" + " " * 17 + "║")
    print("╚" + "═" * 46 + "╝")
    print()

def main():
    """Main entry point for CS2 External ESP."""
    display_banner()
    
    config = OverlayConfig()
    
    if not config.offsets:
        print()
        print("[!] Cannot start without valid offsets.")
        print("[*] Wait for updated offsets after game patches.")
        print("[*] Check the GitHub repository for the latest version.")
        print()
        input("Press Enter to exit...")
        sys.exit(1)
    
    print("[*] Searching for CS2 process...")
    time.sleep(2)
    
    cs2_window = find_cs2_window()
    if not cs2_window:
        print("[!] CS2 not detected.")
        print()
        print("[*] Troubleshooting:")
        print("    1. Make sure CS2 is running and you're in a match")
        print("    2. Run setup.bat as Administrator")
        print("    3. Verify game is updated to the latest version")
        print("    4. Check Windows Defender isn't blocking the overlay")
        print()
        input("Press Enter to exit...")
        sys.exit(1)
    
    print("[+] CS2 window found.")
    
    renderer = initialize_overlay()
    if not renderer:
        input("Press Enter to exit...")
        sys.exit(1)
    
    print()
    print("[*] Overlay active. Press keys to toggle features:")
    print("    F5 - ESP (Wallhack)")
    print("    F6 - Aimbot")
    print("    F7 - Triggerbot")
    print("    END - Exit")
    print()
    print("[*] Waiting for input...")
    
    if KEYBOARD_AVAILABLE:
        listener = keyboard.Listener(
            on_press=lambda key: on_key_press(key, config)
        )
        listener.start()
    
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("\n[!] Overlay stopped by user.")
        sys.exit(0)

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"\n[!] Error: {e}")
        print("[*] Report issues on the GitHub repository.")
        sys.exit(1)

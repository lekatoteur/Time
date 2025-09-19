#!/bin/bash

# Raspberry Pi Circular Clock Setup Script
# Run this script to set up the clock on your Raspberry Pi

echo "Setting up Circular Time Keeping Device on Raspberry Pi..."

# Create project directory
mkdir -p ~/circular-clock
cd ~/circular-clock

# Create the HTML file
cat > index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Circular Time Keeping Device</title>
    <style>
        body {
            margin: 0;
            padding: 0;
            background: #000;
            font-family: 'Courier New', monospace;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
            color: white;
            overflow: hidden;
            cursor: none;
        }
        
        .clock-container {
            position: relative;
            width: 100vmin;
            height: 100vmin;
            display: flex;
            align-items: center;
            justify-content: center;
        }
        
        .hour-circle {
            position: absolute;
            border-radius: 50%;
            transition: none;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: bold;
            font-size: 24px;
            border: 2px solid rgba(255, 255, 255, 0.2);
        }
        
        .current-hour {
            border: 3px solid rgba(255, 255, 255, 0.8) !important;
            box-shadow: 0 0 20px rgba(255, 255, 255, 0.6);
        }
    </style>
</head>
<body>
    <div class="clock-container" id="clockContainer">
        <!-- Hour circles will be generated here -->
    </div>

    <script>
        // WCAG-compliant color sequence
        const hourColors = [
            '#FFFFFF', // 12 - White
            '#000080', // 1 - Navy Blue
            '#FFD700', // 2 - Gold
            '#4B0082', // 3 - Indigo
            '#FF6347', // 4 - Tomato
            '#2F4F4F', // 5 - Dark Slate Gray
            '#FFFF00', // 6 - Yellow
            '#8B0000', // 7 - Dark Red
            '#00CED1', // 8 - Dark Turquoise
            '#800080', // 9 - Purple
            '#FFA500', // 10 - Orange
            '#006400'  // 11 - Dark Green
        ];

        function updateClock() {
            const now = new Date();
            let hours = now.getHours();
            const minutes = now.getMinutes();
            const seconds = now.getSeconds();
            
            const hour12 = hours === 0 ? 12 : hours > 12 ? hours - 12 : hours;
            
            const container = document.getElementById('clockContainer');
            container.innerHTML = '';
            
            const maxSize = Math.min(window.innerWidth, window.innerHeight) * 0.9;
            const minSize = 0;
            
            const currentHourIndex = hour12 === 12 ? 0 : hour12;
            
            for (let i = 0; i <= currentHourIndex; i++) {
                const circle = document.createElement('div');
                circle.className = 'hour-circle';
                
                const colorIndex = i;
                const color = hourColors[colorIndex];
                
                let size;
                if (i < currentHourIndex) {
                    size = maxSize;
                } else {
                    const totalMinutes = minutes + (seconds / 60) + (now.getMilliseconds() / 60000);
                    size = minSize + (totalMinutes / 60) * (maxSize - minSize);
                }
                
                circle.style.width = size + 'px';
                circle.style.height = size + 'px';
                circle.style.backgroundColor = color;
                circle.style.left = '50%';
                circle.style.top = '50%';
                circle.style.transform = 'translate(-50%, -50%)';
                circle.style.zIndex = i;
                
                if (i === currentHourIndex) {
                    circle.classList.add('current-hour');
                }
                
                container.appendChild(circle);
            }
        }
        
        updateClock();
        setInterval(updateClock, 1000 / 60);

        // Hide cursor after mouse stops moving
        let mouseTimer;
        document.addEventListener('mousemove', () => {
            document.body.style.cursor = 'default';
            clearTimeout(mouseTimer);
            mouseTimer = setTimeout(() => {
                document.body.style.cursor = 'none';
            }, 3000);
        });

        // Prevent screensaver
        setInterval(() => {
            document.dispatchEvent(new MouseEvent('mousemove'));
        }, 30000);
    </script>
</body>
</html>
EOF

# Create Python server script
cat > server.py << 'EOF'
#!/usr/bin/env python3
import http.server
import socketserver
import webbrowser
import os
import signal
import sys

PORT = 8080

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=os.getcwd(), **kwargs)

def signal_handler(sig, frame):
    print('\nShutting down server...')
    sys.exit(0)

signal.signal(signal.SIGINT, signal_handler)

print(f"Starting Circular Clock server on port {PORT}")
print(f"Access at: http://localhost:{PORT}")
print("Press Ctrl+C to stop")

with socketserver.TCPServer(("", PORT), Handler) as httpd:
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nServer stopped.")
EOF

# Make Python server executable
chmod +x server.py

# Create startup script
cat > start_clock.sh << 'EOF'
#!/bin/bash

# Navigate to clock directory
cd ~/circular-clock

echo "Starting Circular Clock..."

# Kill any existing instances
pkill -f "python3.*server.py"

# Start server in background
python3 server.py &
SERVER_PID=$!

# Wait a moment for server to start
sleep 2

# Open in fullscreen browser (try different browsers)
if command -v chromium-browser &> /dev/null; then
    chromium-browser --start-fullscreen --disable-web-security --disable-features=VizDisplayCompositor --kiosk http://localhost:8080 &
elif command -v firefox &> /dev/null; then
    firefox --kiosk http://localhost:8080 &
elif command -v google-chrome &> /dev/null; then
    google-chrome --start-fullscreen --kiosk http://localhost:8080 &
else
    echo "No suitable browser found. Please open http://localhost:8080 manually"
fi

echo "Clock started! Server PID: $SERVER_PID"
echo "To stop: pkill -f server.py"
EOF

# Make startup script executable
chmod +x start_clock.sh

# Create autostart script for boot
cat > install_autostart.sh << 'EOF'
#!/bin/bash

echo "Setting up autostart..."

# Create autostart directory if it doesn't exist
mkdir -p ~/.config/autostart

# Create desktop entry for autostart
cat > ~/.config/autostart/circular-clock.desktop << 'AUTOSTART_EOF'
[Desktop Entry]
Type=Application
Name=Circular Clock
Comment=Start circular clock on boot
Exec=/home/pi/circular-clock/start_clock.sh
Icon=clock
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
AUTOSTART_EOF

echo "Autostart installed! Clock will start automatically on boot."
echo "To disable: rm ~/.config/autostart/circular-clock.desktop"
EOF

# Make autostart installer executable
chmod +x install_autostart.sh

# Create README
cat > README.md << 'EOF'
# Circular Time Keeping Device for Raspberry Pi

A beautiful, minimalist clock that displays time through growing colored circles.

## Installation

1. Copy all files to your Raspberry Pi
2. Run the setup script:
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

## Usage

### Manual Start
```bash
./start_clock.sh
```

### Auto-start on Boot
```bash
./install_autostart.sh
```

### Stop the Clock
```bash
pkill -f server.py
```

## Features

- 60fps smooth animation
- WCAG contrast-compliant colors
- Fullscreen kiosk mode
- Auto-hides cursor
- Prevents screensaver
- Responsive to screen size

## Files

- `index.html` - The clock interface
- `server.py` - Local web server
- `start_clock.sh` - Launch script
- `install_autostart.sh` - Autostart installer
- `README.md` - This file

## Troubleshooting

- If browser doesn't open automatically, navigate to http://localhost:8080
- For older Raspberry Pis, reduce frame rate by changing `1000/60` to `1000/30` in index.html
- Ensure Python 3 is installed: `sudo apt install python3`
EOF

echo ""
echo "✅ Circular Clock package created successfully!"
echo ""
echo "Files created in ~/circular-clock/:"
echo "  - index.html (the clock)"
echo "  - server.py (web server)"
echo "  - start_clock.sh (launcher)"
echo "  - install_autostart.sh (autostart installer)"
echo "  - README.md (instructions)"
echo ""
echo "To start the clock:"
echo "  ./start_clock.sh"
echo ""
echo "To auto-start on boot:"
echo "  ./install_autostart.sh"
echo ""

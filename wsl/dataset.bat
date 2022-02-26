.\Alpine.exe install --root <nul
wsl --export Alpine alpine
wsl --unregister Alpine
wsl --import scratch .\scratch alpine
wsl --import data .\data alpine
del alpine

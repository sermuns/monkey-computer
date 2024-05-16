# g47 monkey computer

**Kör dessa i roten av gitprojektet (code/)**

för att få kommandot `emu` att köra `python emulate.py`
```bash
ln -sr scripts/emulate.py ~/.local/bin/emu
```

för att få kommandot `ass` att köra `python assembler.py`
```bash
ln -sr scripts/assembler.py ~/.local/bin/ass
```


**Om ett kommando av dessa ovan ändå inte funkar, måste kanske `~/.local/bin` läggas till i `PATH`:**
```shell
echo 'export PATH="$PATH:$HOME/.local/bin"' >> ~/.bashrc
```
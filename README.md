<h3 align="center">
Un cli para navegar y ver anime, peliculas, doramas (solo Y con amigos) Esta herramienta usa los siguiente sitios <a href="https://cuevana3.ch/">cuevana3</a> <a href="https://monoschinos2.com">monoschinos2</a> <a href="https://www.doramasyt.com">doramasyt</a>.
</h3>

[movi-cli-es-demo.mp4](https://github.com/SweetMask4/movi-cli-es/assets/43506915/ca0498b0-e19a-4c15-b67d-b5c6c3fb1339)

### Instalar desde el código fuente

Instalar dependencias

Para archlinux y derivadas

```sh
sudo pacman -S ffmpeg curl yt-dpl mpv fzf --needed
```

Para debian y ubuntu

paso 1

```sh
sudo apt-get install ffmpeg curl mpv fzf python-pip
```

paso 2

```sh
python -m pip install -U yt-dlp
```

Para fedora

paso 1

```sh
sudo dnf install ffmpeg curl mpv fzf python-pip
```

paso 2

```sh
python -m pip install -U yt-dlp
```

dependencias opcionales 
[dmenu](https://github.com/SweetMask4/dmenu) 
rofi

instalar scripts
```sh
git clone "https://github.com/SweetMask4/movi-cli-es.git"
sudo cp movi-cli-es/movi-cli-es /usr/local/bin
rm -rf movi-cli-es
```

## Desinstalar

```sh
sudo rm "/usr/local/bin/movi-cli-es"
```

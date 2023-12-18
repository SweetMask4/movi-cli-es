<h1 align="center">
Un cli para navegar y ver anime, peliculas, doramas (solo Y con amigos).
</h1>

### Instalar desde el código fuente

Instalar dependencias

Para archlinux y derivadas

```sh
sudo pacman -S ffmpeg curl yt-dpl mpv --needed
```

Para debian y ubuntu

paso 1

```sh
sudo apt-get install ffmpeg curl mpv python-pip
```

paso 2

```sh
python -m pip install -U yt-dlp
```

Para fedora

paso 1

```sh
sudo dnf install ffmpeg curl mpv python-pip
```

paso 2

```sh
python -m pip install -U yt-dlp
```

Para termux

paso 1

```sh
pkg install curl python-pip
```

```sh
python -m pip install -U yt-dlp
```

```sh
git clone "https://github.com/SweetMask4/movi-cli-es.git"
sudo cp movi-cli-es/movi-cli-es /usr/local/bin
rm -rf movi-cli-es
```

## Desinstalar

```sh
sudo rm "/usr/local/bin/movi-cli-es"
```

#!/usr/bin/env bash
set -euo pipefail

VINEGAR_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/vinegar"
export WINEPREFIX="${WINEPREFIX:-$VINEGAR_DIR/prefixes/studio}"

# Studio más reciente instalado por Vinegar
EXE="$(ls -dt "$VINEGAR_DIR"/versions/version-*/StudioMCP.exe 2>/dev/null | head -n1 || true)"
if [ -z "${EXE:-}" ] || [ ! -f "$EXE" ]; then
  echo "No encontré StudioMCP.exe en $VINEGAR_DIR/versions" >&2
  exit 1
fi

# Wine: 1) variable WINE, 2) el wine del wineserver que está corriendo, 3) el del PATH
if [ -z "${WINE:-}" ]; then
  WS_PID="$(pgrep -o wineserver || true)"
  if [ -n "$WS_PID" ]; then
    WS_BIN="$(readlink -f "/proc/$WS_PID/exe")"
    CANDIDATE="$(dirname "$WS_BIN")/wine"
    [ -x "$CANDIDATE" ] && WINE="$CANDIDATE"
  fi
fi
WINE="${WINE:-$(command -v wine || true)}"
if [ -z "$WINE" ]; then
  echo "No encontré wine; abre Studio primero o define WINE=/ruta/a/wine" >&2
  exit 1
fi

# wineserver del mismo Wine (para la limpieza al salir)
WINESERVER="$(dirname "$WINE")/wineserver"
[ -x "$WINESERVER" ] || WINESERVER="$(command -v wineserver || true)"

WINE_PID=""

# PIDs de winedevice.exe que pertenecen al prefix de Studio
studio_winedevices() {
  local pid
  for pid in $(pgrep -u "$(id -u)" -f 'winedevice\.exe' || true); do
    if tr '\0' '\n' < "/proc/$pid/environ" 2>/dev/null | grep -qx "WINEPREFIX=$WINEPREFIX"; then
      echo "$pid"
    fi
  done
}

cleanup() {
  trap - EXIT TERM INT HUP   # evita ejecutarla dos veces

  # 1) Termina StudioMCP.exe: SIGTERM, y SIGKILL si no cae en 5 segundos
  if [ -n "$WINE_PID" ] && kill -0 "$WINE_PID" 2>/dev/null; then
    kill -TERM "$WINE_PID" 2>/dev/null || true
    for _ in 1 2 3 4 5; do
      kill -0 "$WINE_PID" 2>/dev/null || break
      sleep 1
    done
    kill -KILL "$WINE_PID" 2>/dev/null || true
  fi

  # 2) Limpieza del prefix, SOLO si Studio está cerrado y no queda otro
  #    StudioMCP.exe usando el mismo prefix (hay dos instancias del wrapper).
  #    Patrón exacto: RobloxCrashHandler.exe también contiene "RobloxStudio" en sus argumentos.
  if pgrep -f 'RobloxStudioBeta' >/dev/null 2>&1; then
    return 0
  fi
  if pgrep -f 'StudioMCP\.exe' >/dev/null 2>&1; then
    return 0
  fi

  if [ -n "$WINESERVER" ]; then
    "$WINESERVER" -k 2>/dev/null || true
  fi

  # 3) winedevice.exe no muere con el wineserver: sin esto queda huérfano
  local pids
  pids="$(studio_winedevices)"
  if [ -n "$pids" ]; then
    # shellcheck disable=SC2086
    kill -TERM $pids 2>/dev/null || true
    sleep 2
    pids="$(studio_winedevices)"
    if [ -n "$pids" ]; then
      # shellcheck disable=SC2086
      kill -KILL $pids 2>/dev/null || true
    fi
  fi
}

trap cleanup EXIT
trap 'exit 143' TERM INT HUP

# Sin exec, en segundo plano, conservando stdin (el MCP habla por stdin/stdout).
# Limpiar variables de wine heredadas; si no, falla con "Bad server socket"
env -u WINESERVERSOCKET -u WINELOADERNOEXEC -u WINEPRELOADRESERVE \
  "$WINE" "$EXE" "$@" <&0 &
WINE_PID=$!

wait "$WINE_PID" || true

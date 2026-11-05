#!/usr/bin/env python3
"""Genera los 12 efectos de sonido PROPIOS del prototipo del tablero.

Todo se sintetiza aqui, con matematica simple (senoides, ruido filtrado y
envolventes). No se descarga ni se copia audio de ninguna parte. Solo usa la
libreria estandar de Python, asi que no hay nada que instalar.

Uso (desde la carpeta prototipos/tablero-flame):

    python tool/generar_sonidos.py

Escribe los .wav en assets/sonidos/. La semilla del ruido es fija: correr el
script dos veces da exactamente los mismos archivos.

Sonidos: tick, lapiz1-3, borrar, sello, arpegio, zumbido, redoble, golpe,
estrella, fanfarria.
"""

import math
import os
import random
import struct
import wave

SR = 44100  # muestras por segundo, mono, 16 bits
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "sonidos")


# ---------------------------------------------------------------- utilidades

def silence(sec):
    return [0.0] * int(SR * sec)


def mix(*tracks):
    """Suma pistas de distinto largo."""
    n = max(len(t) for t in tracks)
    out = [0.0] * n
    for t in tracks:
        for i, v in enumerate(t):
            out[i] += v
    return out


def place(track, at_sec, total_sec=None):
    """Mueve una pista al instante at_sec (rellena con silencio)."""
    out = silence(at_sec) + track
    if total_sec is not None:
        need = int(SR * total_sec)
        out = (out + [0.0] * need)[:need]
    return out


def gain(track, g):
    return [v * g for v in track]


def env_exp(n, decay):
    """Envolvente de caida exponencial; decay en 1/seg."""
    return [math.exp(-decay * i / SR) for i in range(n)]


def attack(track, sec):
    """Entrada lineal para evitar chasquidos al inicio."""
    k = max(1, int(SR * sec))
    out = list(track)
    for i in range(min(k, len(out))):
        out[i] *= i / k
    return out


def fade_out(track, sec):
    k = max(1, int(SR * sec))
    out = list(track)
    n = len(out)
    for i in range(min(k, n)):
        out[n - 1 - i] *= i / k
    return out


def sine(freq, sec, phase=0.0):
    n = int(SR * sec)
    return [math.sin(2 * math.pi * freq * i / SR + phase) for i in range(n)]


def sweep(f0, f1, sec):
    """Senoide con frecuencia que va de f0 a f1 (exponencial)."""
    n = int(SR * sec)
    out = []
    phase = 0.0
    for i in range(n):
        t = i / max(1, n - 1)
        f = f0 * (f1 / f0) ** t
        phase += 2 * math.pi * f / SR
        out.append(math.sin(phase))
    return out


def noise(sec, rng):
    return [rng.uniform(-1.0, 1.0) for _ in range(int(SR * sec))]


def lowpass(track, cutoff):
    """Filtro de un polo."""
    a = 1 - math.exp(-2 * math.pi * cutoff / SR)
    out, y = [], 0.0
    for v in track:
        y += a * (v - y)
        out.append(y)
    return out


def highpass(track, cutoff):
    lp = lowpass(track, cutoff)
    return [v - l for v, l in zip(track, lp)]


def pluck(freq, sec, bright=3):
    """Nota pulsada: fundamental + armonicos que caen rapido."""
    n = int(SR * sec)
    out = [0.0] * n
    for h in range(1, bright + 1):
        amp = 1.0 / (h * h)
        decay = 7 + 9 * h
        for i in range(n):
            t = i / SR
            out[i] += amp * math.exp(-decay * t) * math.sin(2 * math.pi * freq * h * t)
    return attack(out, 0.002)


def soft_clip(track, drive=1.0):
    return [math.tanh(v * drive) for v in track]


def normalize(track, peak=0.85):
    m = max(abs(v) for v in track) or 1.0
    return [v * peak / m for v in track]


def save(name, track):
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, name + ".wav")
    track = fade_out(track, 0.004)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        frames = b"".join(
            struct.pack("<h", int(max(-1.0, min(1.0, v)) * 32767)) for v in track
        )
        w.writeframes(frames)
    print("%-10s %5.2f s  %4d KB" % (name, len(track) / SR, os.path.getsize(path) // 1024))


# ------------------------------------------------------------------ sonidos

def make_tick():
    """Tocar un sospechoso: golpecito corto y suave."""
    n = int(SR * 0.07)
    body = [a * b for a, b in zip(sine(1900, 0.07), env_exp(n, 70))]
    body2 = [a * b for a, b in zip(sine(950, 0.07), env_exp(n, 55))]
    return normalize(attack(mix(body, gain(body2, 0.5)), 0.001), 0.55)


def make_lapiz(seed, tone):
    """Rasguno de lapiz: ruido filtrado con dos pasadas."""
    rng = random.Random(seed)
    sec = 0.12
    n = int(SR * sec)
    raw = highpass(lowpass(noise(sec, rng), tone), 900)
    # dos trazos cortos con silencio en medio
    shape = []
    for i in range(n):
        t = i / n
        a = math.sin(math.pi * min(1.0, t * 2.2)) if t < 0.45 else 0.0
        b = math.sin(math.pi * (t - 0.5) * 2.0) if 0.5 <= t < 1.0 else 0.0
        shape.append(a * 0.9 + b * 0.7)
    out = [r * s for r, s in zip(raw, shape)]
    return normalize(attack(out, 0.002), 0.5)


def make_borrar():
    """Borrador: roce suave y grave."""
    rng = random.Random(77)
    sec = 0.11
    raw = lowpass(noise(sec, rng), 2200)
    n = len(raw)
    out = [v * math.sin(math.pi * i / n) for i, v in enumerate(raw)]
    return normalize(out, 0.4)


def make_sello():
    """Confirmar: golpe de sello/madera con una nota que sube al final."""
    thud = [a * b for a, b in zip(sweep(190, 70, 0.22), env_exp(int(SR * 0.22), 20))]
    click = [a * b for a, b in zip(noise(0.03, random.Random(5)), env_exp(int(SR * 0.03), 140))]
    click = lowpass(click, 3500)
    rise_n = int(SR * 0.16)
    rise = [a * b for a, b in zip(sweep(520, 880, 0.16), env_exp(rise_n, 16))]
    out = mix(gain(thud, 1.0), gain(click, 0.7), gain(place(rise, 0.04), 0.35))
    return normalize(attack(out, 0.001), 0.9)


def make_arpegio():
    """Tachar fila y columna: 5 notas descendentes. Empieza con 90 ms de
    silencio para caer justo despues del golpe de sello."""
    notes = [784.0, 659.25, 523.25, 392.0, 329.63]  # sol-mi-do-sol-mi (descendente)
    step = 0.06
    tracks = []
    for k, f in enumerate(notes):
        tracks.append(place(gain(pluck(f, 0.28), 0.8 - 0.07 * k), 0.09 + k * step))
    out = mix(*tracks)
    return normalize(out, 0.6)


def make_zumbido():
    """Error: zumbido grave y mate, dos pulsos. Nunca humillante."""
    def pulse():
        n = int(SR * 0.17)
        raw = []
        for i in range(n):
            t = i / SR
            raw.append(
                0.6 * math.sin(2 * math.pi * 98 * t)
                + 0.3 * math.sin(2 * math.pi * 147 * t)
                + 0.15 * math.sin(2 * math.pi * 196 * t)
            )
        env = [math.sin(math.pi * min(1.0, i / n)) ** 0.6 for i in range(n)]
        return lowpass([a * b for a, b in zip(raw, env)], 700)
    out = mix(pulse(), place(pulse(), 0.22))
    return normalize(soft_clip(out, 1.6), 0.7)


def make_redoble():
    """Resolver: redoble que acelera y sube, ~1.5 s."""
    rng = random.Random(21)
    total = 1.5
    tracks = []
    t = 0.0
    gap = 0.11
    k = 0
    while t < total - 0.1:
        n = int(SR * 0.05)
        hit = [a * b for a, b in zip(lowpass(noise(0.05, rng), 1800), env_exp(n, 55))]
        tone = [a * b for a, b in zip(sine(110, 0.05), env_exp(n, 40))]
        vol = 0.25 + 0.75 * (t / total)
        tracks.append(place(gain(mix(hit, gain(tone, 0.8)), vol), t, total))
        gap = max(0.028, gap * 0.93)
        t += gap
        k += 1
    return normalize(mix(*tracks), 0.8)


def make_golpe():
    """Revelacion: golpe dramatico grave de ~1 s con cola."""
    n = int(SR * 1.1)
    boom = [a * b for a, b in zip(sweep(120, 38, 1.1), env_exp(n, 4.2))]
    sub = [a * b for a, b in zip(sine(55, 1.1), env_exp(n, 3.0))]
    crack = lowpass(
        [a * b for a, b in zip(noise(0.08, random.Random(3)), env_exp(int(SR * 0.08), 60))],
        4000,
    )
    out = mix(boom, gain(sub, 0.6), gain(crack, 0.8))
    return normalize(soft_clip(attack(out, 0.001), 1.4), 0.95)


def make_estrella():
    """Cada estrella que aparece: campanita brillante."""
    f = 1318.5
    n = int(SR * 0.5)
    a = [x * y for x, y in zip(sine(f, 0.5), env_exp(n, 7))]
    b = [x * y for x, y in zip(sine(f * 2.01, 0.5), env_exp(n, 11))]
    c = [x * y for x, y in zip(sine(f * 3.02, 0.5), env_exp(n, 18))]
    return normalize(attack(mix(a, gain(b, 0.4), gain(c, 0.2)), 0.002), 0.6)


def make_fanfarria():
    """Victoria: fanfarria corta y calida (do mayor), ~1.6 s."""
    def note(freq, sec, vol):
        n = int(SR * sec)
        out = [0.0] * n
        for h, amp in ((1, 1.0), (2, 0.35), (3, 0.2), (4, 0.08)):
            for i in range(n):
                t = i / SR
                out[i] += amp * math.sin(2 * math.pi * freq * h * t)
        env = [min(1.0, i / (SR * 0.01)) * math.exp(-2.2 * i / SR) for i in range(n)]
        return gain([a * b for a, b in zip(out, env)], vol)

    c5, e5, g5, c6 = 523.25, 659.25, 783.99, 1046.5
    parts = [
        place(note(c5, 0.5, 0.55), 0.00),
        place(note(e5, 0.5, 0.55), 0.14),
        place(note(g5, 0.6, 0.55), 0.28),
        place(note(c6, 1.1, 0.7), 0.46),
        place(note(g5 / 2, 1.1, 0.35), 0.46),
        place(note(e5, 1.1, 0.35), 0.46),
    ]
    return normalize(mix(*parts), 0.8)


def main():
    save("tick", make_tick())
    save("lapiz1", make_lapiz(11, 5200))
    save("lapiz2", make_lapiz(12, 4300))
    save("lapiz3", make_lapiz(13, 6000))
    save("borrar", make_borrar())
    save("sello", make_sello())
    save("arpegio", make_arpegio())
    save("zumbido", make_zumbido())
    save("redoble", make_redoble())
    save("golpe", make_golpe())
    save("estrella", make_estrella())
    save("fanfarria", make_fanfarria())


if __name__ == "__main__":
    main()

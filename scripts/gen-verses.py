#!/usr/bin/env python3
"""Genera data/verses.json (solo los versículos del día) a partir de tu RVR1960 local.

Uso: python3 scripts/gen-verses.py [ruta/a/rvr1960.json]
Por defecto lee ~/.local/share/construct/bible/rvr1960.json.
Para cambiar las citas, edita REFS y vuelve a ejecutarlo.
"""
import json
import os
import re
import sys
import unicodedata

BOOKS = ["Génesis", "Éxodo", "Levítico", "Números", "Deuteronomio", "Josué", "Jueces", "Rut", "1 Samuel", "2 Samuel", "1 Reyes", "2 Reyes", "1 Crónicas", "2 Crónicas", "Esdras", "Nehemías", "Ester", "Job", "Salmos", "Proverbios", "Eclesiastés", "Cantares", "Isaías", "Jeremías", "Lamentaciones", "Ezequiel", "Daniel", "Oseas", "Joel", "Amós", "Abdías", "Jonás", "Miqueas", "Nahúm", "Habacuc", "Sofonías", "Hageo", "Zacarías", "Malaquías", "Mateo", "Marcos", "Lucas", "Juan", "Hechos", "Romanos", "1 Corintios", "2 Corintios", "Gálatas", "Efesios", "Filipenses", "Colosenses", "1 Tesalonicenses", "2 Tesalonicenses", "1 Timoteo", "2 Timoteo", "Tito", "Filemón", "Hebreos", "Santiago", "1 Pedro", "2 Pedro", "1 Juan", "2 Juan", "3 Juan", "Judas", "Apocalipsis"]

# [libro (1–66), capítulo, versículo, versículo final opcional]
REFS = [[1, 1, 1], [19, 23, 1], [43, 3, 16], [45, 8, 28], [50, 4, 13], [24, 29, 11], [20, 3, 5, 6], [23, 40, 31], [45, 12, 2], [49, 2, 8, 9], [58, 11, 1], [19, 46, 1], [40, 11, 28], [47, 5, 17], [48, 2, 20], [62, 4, 19], [19, 119, 105], [6, 1, 9], [40, 6, 33], [45, 5, 8], [43, 14, 6], [59, 1, 5], [60, 5, 7], [50, 4, 6, 7], [19, 37, 4], [20, 16, 3], [23, 41, 10], [45, 15, 13], [55, 1, 7], [58, 4, 12], [43, 1, 1], [19, 27, 1], [40, 5, 16], [51, 3, 23], [45, 10, 9], [20, 18, 10], [25, 3, 22, 23], [19, 91, 1, 2], [43, 16, 33], [47, 12, 9], [49, 6, 10], [58, 12, 1, 2], [54, 4, 12], [40, 28, 19, 20], [44, 1, 8], [19, 139, 14], [23, 53, 5], [45, 6, 23], [48, 5, 22, 23], [62, 1, 9], [43, 8, 32], [19, 34, 8], [20, 4, 23], [23, 26, 3], [46, 10, 13], [50, 1, 6], [59, 4, 8], [19, 51, 10], [45, 3, 23, 24], [49, 4, 32], [43, 15, 5], [40, 7, 7], [19, 103, 12], [52, 5, 16, 18], [23, 55, 8, 9], [24, 33, 3], [58, 13, 8], [19, 121, 1, 2], [46, 13, 4, 7], [43, 11, 25], [19, 16, 11], [20, 22, 6], [45, 1, 16], [66, 21, 4], [33, 6, 8], [35, 3, 17, 18], [36, 3, 17], [5, 31, 6], [27, 2, 20, 21], [19, 1, 1, 2], [47, 4, 16, 17], [51, 1, 16, 17], [62, 3, 1], [42, 1, 37], [49, 3, 20], [55, 3, 16, 17], [19, 62, 1, 2], [40, 22, 37, 39], [43, 10, 10], [45, 12, 12], [58, 10, 23], [19, 118, 24], [60, 1, 3], [22, 8, 7], [26, 36, 26], [39, 3, 6], [14, 7, 14], [18, 19, 25], [19, 90, 12], [66, 3, 20], [41, 10, 45], [44, 4, 12], [46, 15, 58]]


def norm(s):
    """"Éxodo" → "exodo" · "1 Corintios" → "1corintios" """
    s = unicodedata.normalize("NFD", s)
    s = "".join(c for c in s if not unicodedata.combining(c))
    return re.sub(r"\s+", "", s).lower()


def verse_at(chapter, v):
    if not chapter:
        return ""
    if isinstance(chapter, list):
        return chapter[v - 1] if 0 < v <= len(chapter) else ""
    return chapter.get(str(v), "")


def make_book_at(bible):
    if isinstance(bible, list):
        return lambda n: (bible[n - 1] or {}).get("chapters")
    keys = {norm(k): k for k in bible}

    def book_at(n):
        target = norm(BOOKS[n - 1])
        if target in keys:
            return bible[keys[target]]
        # "juan" nunca casa con "1juan"
        for k, orig in keys.items():
            if (k.startswith(target) or target.startswith(k) or k.endswith(target)) and k[:1].isdigit() == target[:1].isdigit():
                return bible[orig]
        return None

    return book_at


def compute(book_at, r):
    book = book_at(r[0])
    if not book:
        return ""
    ch = book[r[1] - 1] if isinstance(book, list) else book.get(str(r[1]))
    last = r[3] if len(r) > 3 else r[2]
    out = [str(t) for v in range(r[2], last + 1) if (t := verse_at(ch, v))]
    text = " ".join(out)
    text = re.sub(r"\{[^}]*\}|<[^>]*>|¶", "", text)
    return re.sub(r"\s+", " ", text).strip()


def main():
    src = sys.argv[1] if len(sys.argv) > 1 else os.path.expanduser("~/.local/share/construct/bible/rvr1960.json")
    with open(src, encoding="utf-8") as f:
        bible = json.load(f)
    if not (isinstance(bible, dict) or (isinstance(bible, list) and len(bible) == 66)):
        sys.exit(f"formato no reconocido: {src}")

    book_at = make_book_at(bible)
    entries = [{"ref": r, "text": compute(book_at, r)} for r in REFS]
    missing = [r for r, e in zip(REFS, entries) if not e["text"]]

    dst = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "data", "verses.json")
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    with open(dst, "w", encoding="utf-8") as f:
        # Una cita por línea: diffs legibles al cambiar REFS
        f.write("[\n" + ",\n".join(json.dumps(e, ensure_ascii=False) for e in entries) + "\n]\n")

    print(f"{len(entries)} citas → {os.path.normpath(dst)}")
    if missing:
        print(f"sin texto ({len(missing)}): {missing}", file=sys.stderr)


if __name__ == "__main__":
    main()

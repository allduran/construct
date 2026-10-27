pragma Singleton
import Quickshell
import QtQuick

// Calculadora del launcher. Calc.evaluate("2^10/4") → "256"
// Devuelve "" si no es una expresión válida.
Singleton {
    readonly property var fns: ["sqrt", "sin", "cos", "tan", "log", "abs", "round", "floor", "ceil"]

    function evaluate(expr: string): string {
        let e = expr.trim().replace(/^=/, "").replace(/,/g, ".")          // 2,5 → 2.5
        .replace(/×/g, "*").replace(/÷/g, "/").replace(/\^/g, "**");        // 2^10 → 2**10

        // Lista blanca: quitando las funciones permitidas solo pueden quedar números y operadores
        let check = e.replace(/\bpi\b/g, "");
        for (const f of fns)
            check = check.replace(new RegExp(`\\b${f}\\b`, "g"), "");
        if (!/^[0-9+\-*/().%\s]*$/.test(check))
            return "";
        if (!/[+\-*/%(]|\bpi\b|\b[a-z]+\(/.test(e))
            return "";   // un número solo no es un cálculo

        e = e.replace(/\bpi\b/g, "Math.PI").replace(new RegExp(`\\b(${fns.join("|")})\\b`, "g"), "Math.$1");

        try {
            const v = Function(`"use strict"; return (${e})`)();
            if (typeof v !== "number" || !isFinite(v))
                return "";
            // 10 decimales como mucho y coma decimal
            return String(Math.round(v * 1e10) / 1e10).replace(".", ",");
        } catch (_) {
            return "";
        }
    }
}

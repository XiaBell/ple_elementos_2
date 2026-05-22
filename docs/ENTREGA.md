# Proyecto 4 — VeriLang + Kotlin

**María Castilla** · 202315018

## Qué pedía el enunciado

- Reutilizar VeriLang del proyecto 3.
- Correrlo desde Kotlin (no Java).
- Exportar el AST a JSON.
- `VeriLangService.kt` abre ese JSON.
- La GUI usa el servicio y muestra: parser OK/FAIL, módulos e info extra.

## Dónde está cada cosa

| Requisito | Archivo |
|-----------|---------|
| VeriLang P3 | `src/main/rascal/` |
| AST → JSON | `RunnerJson.rsc` → `instance/output/verilang-ast.json` |
| Servicio Kotlin | `kotlin-app/.../VeriLangService.kt` |
| GUI | `kotlin-app/.../MainWindow.kt` |

## Cómo ejecutar

```bash
mvn compile
mvn -q dependency:build-classpath -Dmdep.outputFile=target/ple-cp.txt
cd kotlin-app && ./gradlew run
```

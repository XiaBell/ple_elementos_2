# VeriLang — Entrega Proyecto 4

**María Castilla** · Código: 202315018

Conecta VeriLang (proyecto 3 en Rascal) con una app en **Kotlin**. No hace falta abrir el JSON a mano: eliges un `.vl`, pulsas Ejecutar, y la app hace el resto.

En la carpeta **`instance/`** hay varios programas VeriLang listos para probar (`example.vl`, `bad_syntax.vl`, `bad_data.vl`).

---

## Requisitos

- Java 11+
- Maven

---

## Paso a paso (cómo probarlo)

### 1. Compilar VeriLang (Rascal)

```bash
cd /Users/majo/Desktop/GITHUBPROJECTS/ple_elementos_2
mvn compile
mvn -q dependency:build-classpath -Dmdep.outputFile=target/ple-cp.txt
```

### 2. (Opcional) Probar solo el JSON, sin GUI

```bash
java -cp "target/classes:$(cat target/ple-cp.txt)" \
  org.rascalmpl.shell.RascalShell RunnerJson instance/example.vl

cat instance/output/verilang-ast.json
```

Deberías ver `"parseOk":true` y `"modules":[...]`.

### 3. Abrir la app Kotlin

```bash
cd kotlin-app
./gradlew run
```

En Windows: `gradlew.bat run`.

### 4. En la ventana

1. **Buscar** → elige un `.vl` (ruta completa, por ejemplo):

   ```
   /Users/majo/Desktop/GITHUBPROJECTS/ple_elementos_2/instance/example.vl
   ```

2. **Ejecutar**

---

## Qué debes ver en cada prueba

Usa los archivos de `instance/`:

### `example.vl` (correcto)

- **Parser: OK**
- **Módulos:** logic-demo, standard-lib, math-utils
- **Resumen** con espacios, operadores, variables, etc.

### `bad_syntax.vl` (parser mal)

- **Parser: FAIL**
- Mensaje de error de Rascal debajo (error de parsing)

### `bad_data.vl` (tipos mal)

- **Parser: OK**
- Sección **Errores de tipos** (2 mensajes sobre defdata)

---

## Atajo (todo en uno)

Desde la raíz del proyecto:

```bash
chmod +x run-gui.sh
./run-gui.sh
```

Luego en la ventana: **Buscar** un `.vl` de `instance/` → **Ejecutar**.

---

## Documentación de entrega

[docs/ENTREGA.md](docs/ENTREGA.md)

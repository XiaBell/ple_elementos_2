# Si el IDE sigue marcando errores en rojo

Los archivos **ya compilan** (`mvn compile` + `RunnerJson` / `Generator` en terminal).

Si ves todavía:

- `Undefined module TypePal`
- `Field top does not exist`
- `Undefined Program`
- `Missing return statement` en `typeName`

son casi seguro **avisos viejos del analizador**, no el código actual.

## Qué hacer

1. **Abre la carpeta correcta:** `ple_elementos_2` (donde está `pom.xml`), no una carpeta padre.
2. **Guarda todos** los `.rsc` (Cmd+S / Ctrl+S).
3. **Recarga la ventana:** Command Palette → `Developer: Reload Window`.
4. Compila en terminal:
   ```bash
   mvn compile
   ```
5. Comprueba que Rascal funciona:
   ```bash
   java -cp "target/classes:$(cat target/ple-cp.txt)" \
     org.rascalmpl.shell.RascalShell RunnerJson instance/example.vl
   ```

Si eso va bien, puedes entregar y usar `./run-gui.sh` aunque el IDE pinte líneas en rojo.

## Extensiones

Instala **Rascal MPL** en VS Code / Cursor si no la tienes.

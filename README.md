# ple_elementos_2

Este repositorio es un trabajo con Rascal desarrollando el lenguaje de VeriLang: hay una gramática para programas (archivo de entrada `.vl`), un parser que construye el árbol concreto, pasa al AST (`AST.rsc`) y un módulo `Generator` que recorre ese AST y produce un informe en texto: resumen del módulo (espacios, operadores, variables, reglas `defrule`) y, para cada `defexpression`, muestra la expresión original, pasos de reescritura cuando aplica una regla, y en algunos casos evaluación aritmética simple.

Además, antes de generar salida, `Generator` ejecuta un chequeo de tipos (módulo `TypeCheck.rsc`) que valida:
- tipos base (`Int`, `Bool`, `Char`, `String`) y tipos definidos por el usuario (por `defspace` y `defdata`)
- anotaciones `expr : Type`
- regla extra para `defdata`: los elementos listados deben existir y tener el tipo correcto

## Requisitos

- **Java** instalado (compatible con Rascal 0.33.x).
- **Apache Maven**, para compilar y resolver dependencias.

## Compilación

Desde la carpeta raíz del repositorio (donde está `pom.xml`):

```bash
mvn compile
```

## Ejecución desde la terminal

El intérprete de Rascal necesita las clases compiladas **y** el classpath de las librerías de Maven, no basta con `target/classes`. Un procedimiento habitual es generar el classpath una vez y guardarlo:

```bash
mvn -q dependency:build-classpath -Dmdep.outputFile=/tmp/ple_cp.txt
```

Luego, **desde la raíz del repositorio** (el código arma rutas de archivos con respecto al directorio de trabajo actual):

```bash
java -cp "target/classes:$(cat /tmp/ple_cp.txt)" org.rascalmpl.shell.RascalShell Generator
```

Comportamiento por defecto:

- Entrada: `instance/example.vl`
- Salida por **consola** y el mismo contenido en `instance/output/verilang-output.txt` (relativo al directorio de trabajo actual; cada ejecución **sobrescribe** ese archivo). Si corres `java` desde otra carpeta, esa ruta de salida será respecto a esa carpeta.

### Probar que la regla de `defdata` se aplica (archivo con errores)

Hay un ejemplo que debe fallar para mostrar mensajes de error de la regla 6:

```bash
java -cp "target/classes:$(cat /tmp/ple_cp.txt)" org.rascalmpl.shell.RascalShell Generator instance/bad_data.vl
```

## Cómo probar con otros archivos `.vl`

El módulo `Generator` admite **un argumento opcional**: la ruta del archivo `.vl`. Puede ser:

1. **Ruta relativa** al directorio de trabajo actual de la terminal (donde estás cuando ejecutas `java`).
2. **Ruta absoluta** en el disco (cualquier carpeta de tu equipo), por ejemplo en macOS o Linux algo como `/Users/tu_usuario/Escritorio/mi_archivo.vl`, o en Windows algo como `C:/Users/tu_usuario/Documents/mi_archivo.vl` (también sirven barras invertidas; el programa las normaliza).

Ejemplo con un archivo dentro del proyecto (`instance/`):

```bash
cd /ruta/completa/a/ple_elementos_2
java -cp "target/classes:$(cat /tmp/ple_cp.txt)" org.rascalmpl.shell.RascalShell Generator instance/mi_prueba.vl
```

Ejemplo con un archivo **fuera** del repositorio, usando ruta absoluta (macOS / Linux):

```bash
java -cp "target/classes:$(cat /tmp/ple_cp.txt)" org.rascalmpl.shell.RascalShell Generator /Users/tu_usuario/Documentos/verilang/prueba.vl
```

En la misma terminal puedes usar `$(pwd)` o arrastrar el archivo al terminal para que el sistema pegue la ruta completa.

Ejemplo con otra carpeta **dentro** del mismo proyecto, por ejemplo `pruebas/caso1.vl`:

```bash
java -cp "target/classes:$(cat /tmp/ple_cp.txt)" org.rascalmpl.shell.RascalShell Generator pruebas/caso1.vl
```

**Nota:** con rutas **relativas**, si cambias de carpeta con `cd` antes de correr Java, la ruta se interpreta desde **esa** ubicación. Con rutas **absolutas** da igual desde qué carpeta ejecutes el comando.

Si no pasas ningún argumento, el comando equivale a usar `instance/example.vl` (relativo al directorio de trabajo actual).

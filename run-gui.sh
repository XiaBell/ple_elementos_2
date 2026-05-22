#!/bin/bash
# Abre la app Kotlin del Proyecto 4 (compila Rascal antes si hace falta)
set -e
cd "$(dirname "$0")"

echo ">>> Compilando VeriLang (Rascal)..."
mvn -q compile
mvn -q dependency:build-classpath -Dmdep.outputFile=target/ple-cp.txt

echo ">>> Abriendo interfaz Kotlin..."
cd kotlin-app
./gradlew run

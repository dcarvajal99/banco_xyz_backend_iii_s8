# Contrato del core

Un archivo por forma de respuesta de `banco-core-api`. **El contrato son los nombres de los
campos y su anidación**, no los valores, que son solo de ejemplo.

- **El core (proveedor)** tiene una prueba que llama a cada endpoint y exige que el JSON real tenga
  exactamente las mismas claves que su archivo. Si el core renombra o quita un campo, falla su build.
- **Cada BFF (consumidor)** usa estos mismos archivos como respuesta simulada del core en sus
  pruebas. Si un BFF lee un campo que el contrato no tiene, falla el build de ese BFF.

Así los tres BFF no comparten ninguna librería de código con el core —cada uno es un backend
independiente, que es la estrategia elegida— y aun así una diferencia de contrato se detecta al
compilar y no en producción.

Los campos con valor `null` en el ejemplo existen igual en la respuesta: el core serializa los
nulos para que el conjunto de claves sea estable.

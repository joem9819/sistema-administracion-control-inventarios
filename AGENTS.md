# Contexto del proyecto — Gestión de inventario

Este archivo permite retomar el trabajo en futuras sesiones. Complementa las instrucciones de `../AGENTS.md`, que siguen aplicando a esta carpeta.

## Datos académicos e integrantes

- **Asignatura:** Proyecto Integrador en Software Libre.
- **Programa e institución:** Ingeniería de Sistemas, Instituto Tecnológico Metropolitano (ITM).
- **Integrantes:** Cristian Echavarria, José Manuel Rengifo y Cristian Osorio.

Usar estos nombres en documentos del proyecto. No atribuir tareas, aportes, cargos ni apellidos adicionales sin información del equipo.

## Objetivo acordado

Desarrollar un **prototipo académico local** de aplicación web para controlar el inventario de un supermercado con varias sucursales. Se contemplan productos, existencias por sucursal, compras, ventas, movimientos de kardex, alertas, reportes y usuarios con roles.

La tecnología elegida es Python con Flask para la web y MariaDB de XAMPP como motor de base de datos, administrado mediante phpMyAdmin. Durante el desarrollo Flask sirve la web localmente; Apache de XAMPP no es necesario para ejecutar el código Python. La propuesta técnica incluye SQLAlchemy y PyMySQL. El detalle está en `docs/arquitectura_y_datos.md`.

## Archivos y estado real

- `BD/Base_Datos.sql`: DDL original, datos de prueba, cuatro vistas y consultas. **Empieza con `DROP DATABASE IF EXISTS`**; no ejecutarlo sobre una base que contenga información que deba conservarse.
- `BD/Scripts_BD.mwb`: modelo original de MySQL Workbench.
- `docs/especificacion_funcional.md`: alcance propuesto, roles, reglas de negocio, etapas y criterios de aceptación.
- `docs/arquitectura_y_datos.md`: arquitectura propuesta y cambios pendientes del DDL.
- `README.md`: entrada breve al proyecto.
- `gitignore`: archivo existente sin punto inicial; Git todavía no lo usa como `.gitignore`.

Todavía **no hay aplicación web, DDL corregido ni pruebas de ejecución del esquema en este proyecto**. No se encontró un enunciado o rúbrica formal del docente. Tratar los documentos de `docs/` como definición inicial del equipo, ajustable si aparecen requisitos académicos nuevos.

## Decisiones funcionales actuales

- Conservar los roles del modelo: Administrador, Supervisor, Bodeguero y Vendedor. Ver permisos en la especificación funcional.
- El inventario es por producto y sucursal; después de la carga inicial, cada cambio de stock debe dejar un movimiento de kardex.
- Una compra aumenta stock solo al pasar a `RECIBIDA`; una venta lo disminuye solo al pasar a `PAGADA`. La operación y sus movimientos se guardan en una sola transacción.
- No permitir stock negativo ni aplicar dos veces una recepción o un cobro.
- Las cifras de impuestos son de demostración; el prototipo no emitirá facturas fiscales. La fórmula propuesta figura en `docs/especificacion_funcional.md`.

## Ajustes pendientes del modelo

Antes de crear la aplicación, preparar una **nueva versión** del DDL sin sobrescribir el archivo original. Revisar especialmente contraseñas en texto plano, importes de ejemplo inconsistentes, número de factura de compra duplicable, límites de descuentos, tasa de impuesto por línea, alerta de stock mínimo y coherencia entre saldos y movimientos. La lista y las cifras concretas están en `docs/arquitectura_y_datos.md`.

Probar el DDL revisado en una base de pruebas nueva de MariaDB. El usuario `user_python` documentado para otras clases solo tiene acceso confirmado a `db_persons`; crear un usuario específico para esta base cuando se implemente la conexión. Guardar secretos en variables de entorno o `.env` excluido de Git.

## Cómo continuar

1. Leer `README.md`, ambos documentos de `docs/` y el DDL antes de cambiar código o datos.
2. Si aparece el enunciado del docente, contrastarlo con la definición actual y registrar diferencias.
3. Corregir el esquema y los datos de prueba en archivos nuevos; verificar su ejecución en MariaDB sin afectar otras bases.
4. Desarrollar por etapas: acceso y catálogos; inventario y kardex; compras y ventas; alertas, reportes y pruebas.
5. Mantener los archivos del proyecto dentro de esta carpeta, documentar decisiones nuevas y actualizar este `AGENTS.md` cuando cambie el estado real.

Redactar principalmente en español, con explicaciones breves y verificables. No inventar requisitos ni resultados de pruebas. Conservar el trabajo previo de los integrantes.

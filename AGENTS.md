# Contexto del proyecto — Gestión de inventario

Este archivo permite retomar el trabajo en futuras sesiones. Complementa las instrucciones de `../AGENTS.md`, que siguen aplicando a esta carpeta.

## Datos académicos e integrantes

- **Asignatura:** Proyecto Integrador en Software Libre.
- **Programa e institución:** Ingeniería de Sistemas, Instituto Tecnológico Metropolitano (ITM).
- **Integrantes:** Cristian Echavarria, José Manuel Rengifo y Cristian Osorio.

Usar estos nombres en documentos del proyecto. No atribuir tareas, aportes, cargos ni apellidos adicionales sin información del equipo.

## Objetivo acordado

Desarrollar un **prototipo académico local** de aplicación web para controlar el inventario de un supermercado con varias sucursales. Se contemplan productos, existencias por sucursal, compras, ventas, movimientos de kardex, alertas, reportes y usuarios con roles.

La tecnología elegida es Python con Flask para la web y **MySQL de XAMPP** como motor de base de datos, administrado mediante phpMyAdmin. En XAMPP Control Panel 3.3.0, el módulo **Apache** usa el puerto `81` y el módulo **MySQL** usa el `3306`. El DDL del proyecto está escrito para MySQL 8.0+. El usuario administra `bd_inventario_supermercado` en `http://localhost:81/phpmyadmin/index.php`. Flask sirve el CRUD en `http://127.0.0.1:5000/`; Apache no ejecuta el código Python.

El primer CRUD usa **PyMySQL y consultas SQL parametrizadas directamente**, por sencillez para estudiantes que empiezan con Python. SQLAlchemy quedó como propuesta anterior para una etapa posterior, no como dependencia del código actual.

## Archivos y estado real

- `BD/Base_Datos.sql`: DDL original, datos de prueba, cuatro vistas y consultas. **Empieza con `DROP DATABASE IF EXISTS`**; no ejecutarlo sobre una base que contenga información que deba conservarse.
- `BD/Scripts_BD.mwb`: modelo original de MySQL Workbench.
- `docs/especificacion_funcional.md`: alcance propuesto, roles, reglas de negocio, etapas y criterios de aceptación.
- `docs/arquitectura_y_datos.md`: arquitectura propuesta y cambios pendientes del DDL.
- `README.md`: entrada breve al proyecto.
- `GUIA_INICIO_RAPIDO.md`: pasos de ejecución en Windows y orden de lectura del código para principiantes.
- `app.py`, `db.py`, `templates/` y `static/`: CRUD web de productos y categorías, más consulta de inventario.
- `BD/consultas_vistas.sql`: consultas `SELECT` independientes para las cuatro vistas del modelo.
- `.env.example`: nombres de variables de conexión. El `.env` local contiene la configuración de este equipo y está ignorado por Git.
- `.gitignore`: copia funcional del archivo original `gitignore`, que se conserva.

El **CRUD básico ya funciona** con la base existente: categorías y productos se pueden crear, listar, editar y desactivar; el inventario se consulta sin modificar stock. Se comprobó la lectura de las páginas y una secuencia temporal de crear, editar y desactivar, retirando luego esos registros de prueba. El 28 de septiembre de 2026 se insertaron directamente en la base local datos de prueba adicionales para que cada tabla tenga al menos 10 registros: 7 sucursales (4 activas, 3 inactivas), 10 productos, 4 categorías, 8 usuarios con los cuatro roles originales, 6 roles extra inactivos, compras y ventas del 23 al 27 de septiembre, apertura de cada saldo en el kardex y alertas coherentes con el inventario; los cinco movimientos originales se fecharon con su factura. Estos datos **no están en `Base_Datos.sql`**: si se recrea la base con ese script se pierden. Los encabezados inconsistentes del DDL original (`FC-10001` y `FV-10002`) se dejaron intactos para la nueva versión del DDL. Todavía **no hay DDL corregido, autenticación, permisos por rol, compras ni ventas en la web**. No se encontró un enunciado o rúbrica formal del docente. Tratar los documentos de `docs/` como definición inicial del equipo, ajustable si aparecen requisitos académicos nuevos.

## Nombre del motor de base de datos

En todo el proyecto, el motor se nombra **MySQL**. Así lo declara el encabezado de `BD/Base_Datos.sql`, así se llama el módulo en XAMPP Control Panel y así lo presenta el equipo.

**No escribir «MariaDB» en ningún archivo de este proyecto**: ni en documentos, ni en comentarios del código, ni en el banner, ni en insignias del README. El código no depende del motor, porque usa PyMySQL con SQL estándar.

## Decisiones funcionales actuales

- Conservar los roles del modelo: Administrador, Supervisor, Bodeguero y Vendedor. Ver permisos en la especificación funcional.
- El inventario es por producto y sucursal; después de la carga inicial, cada cambio de stock debe dejar un movimiento de kardex.
- Una compra aumenta stock solo al pasar a `RECIBIDA`; una venta lo disminuye solo al pasar a `PAGADA`. La operación y sus movimientos se guardan en una sola transacción.
- No permitir stock negativo ni aplicar dos veces una recepción o un cobro.
- Las cifras de impuestos son de demostración; el prototipo no emitirá facturas fiscales. La fórmula propuesta figura en `docs/especificacion_funcional.md`.

## Ajustes pendientes del modelo

Antes de ampliar la aplicación con autenticación, compras, ventas o cambios de stock, preparar una **nueva versión** del DDL sin sobrescribir el archivo original. Revisar especialmente contraseñas en texto plano, importes de ejemplo inconsistentes, número de factura de compra duplicable, límites de descuentos, tasa de impuesto por línea, alerta de stock mínimo y coherencia entre saldos y movimientos. La lista y las cifras concretas están en `docs/arquitectura_y_datos.md`.

Probar el DDL revisado en una base de pruebas nueva de MySQL. En este equipo se comprobó que `user_python` puede consultar la base de inventario; el CRUD usa ese usuario local mediante `.env`. Para una etapa posterior, considerar un usuario exclusivo con permisos limitados a esta base. Guardar secretos en variables de entorno o `.env` excluido de Git.

## Cómo continuar

1. Leer `README.md`, ambos documentos de `docs/` y el DDL antes de cambiar código o datos.
2. Si aparece el enunciado del docente, contrastarlo con la definición actual y registrar diferencias.
3. Seguir `GUIA_INICIO_RAPIDO.md` para iniciar el CRUD y comprender los módulos actuales antes de ampliar funciones.
4. Corregir el esquema y los datos de prueba en archivos nuevos; verificar su ejecución en MySQL sin afectar otras bases.
5. Desarrollar las siguientes etapas: acceso y permisos; movimientos de inventario y kardex; compras y ventas; alertas y reportes.
6. Mantener los archivos del proyecto dentro de esta carpeta, documentar decisiones nuevas y actualizar este `AGENTS.md` cuando cambie el estado real.

Redactar principalmente en español, con explicaciones breves y verificables. No inventar requisitos ni resultados de pruebas. Conservar el trabajo previo de los integrantes.

# Sistema de administración y control de inventarios

Proyecto académico de Ingeniería de Sistemas del ITM. Se desarrollará una aplicación web local para administrar el inventario de un supermercado con varias sucursales.

## Integrantes

- Cristian Echavarria
- José Manuel Rengifo
- Cristian Osorio

## Estado actual

- `BD/Base_Datos.sql`: modelo inicial, datos de ejemplo, vistas y consultas. **No ejecutarlo sobre una base con información que se quiera conservar:** comienza con `DROP DATABASE`.
- `BD/Scripts_BD.mwb`: modelo editable de MySQL Workbench.
- `app.py`, `db.py` y `templates/`: primer CRUD web de productos y categorías. El inventario se consulta, pero el stock no se edita desde este CRUD.
- `BD/consultas_vistas.sql`: cuatro consultas `SELECT`, una para cada vista del modelo.
- No se ha localizado un enunciado formal del docente.
- La base existente `bd_inventario_supermercado` se ejecuta en MariaDB 10.4 mediante XAMPP.

## Definición del proyecto

- [Requisitos, roles y flujos](docs/especificacion_funcional.md)
- [Arquitectura y revisión del modelo de datos](docs/arquitectura_y_datos.md)
- [Contexto para continuar el proyecto](AGENTS.md)

La definición adopta un **prototipo académico local**. Los cambios al DDL están documentados como propuestas y todavía no se han ejecutado ni incorporado al script original. El CRUD actual funciona con el esquema ya creado; autenticación, compras, ventas y cambios de stock siguen pendientes.

## Tecnologías previstas

Python + Flask para la aplicación, plantillas HTML renderizadas en el servidor y PyMySQL para la conexión. Se usa SQL parametrizado directamente para que este primer CRUD sea fácil de seguir. XAMPP inicia MariaDB por el puerto `3306` y Apache por el `81` para phpMyAdmin; Flask sirve la aplicación en `127.0.0.1:5000`.

## Inicio rápido

La [guía de inicio rápido](GUIA_INICIO_RAPIDO.md) contiene los comandos de PowerShell para instalar dependencias, configurar `.env`, iniciar Flask y leer el código paso a paso. También explica cómo consultar las vistas desde phpMyAdmin.

**Eliminar en este CRUD significa desactivar** (`estado = 0`): así se conservan las referencias históricas. No se permite desactivar un producto que tenga existencias. Este primer módulo solo se abre en el equipo local y todavía no tiene inicio de sesión ni permisos por rol.

## Referencias técnicas

- [Flask: estructura de una aplicación](https://flask.palletsprojects.com/en/stable/tutorial/factory/)
- [PyMySQL: ejemplos de conexión y consultas](https://pymysql.readthedocs.io/en/latest/user/examples.html)
- [Apache Friends: MariaDB en XAMPP](https://www.apachefriends.org/faq_windows)

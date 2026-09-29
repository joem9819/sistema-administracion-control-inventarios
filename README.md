# Sistema de administración y control de inventarios

Proyecto académico de Ingeniería de Sistemas del ITM. Se desarrollará una aplicación web local para administrar el inventario de un supermercado con varias sucursales.

## Integrantes

- Cristian Echavarria
- José Manuel Rengifo
- Cristian Osorio

## Estado actual

- `BD/Base_Datos.sql`: modelo inicial, datos de ejemplo, vistas y consultas. **No ejecutarlo sobre una base con información que se quiera conservar:** comienza con `DROP DATABASE`.
- `BD/Scripts_BD.mwb`: modelo editable de MySQL Workbench.
- Aún no existe la aplicación web ni se ha localizado un enunciado formal del docente.
- La base de datos del entorno local es MariaDB 10.4 mediante XAMPP; se administra con phpMyAdmin.

## Definición del proyecto

- [Requisitos, roles y flujos](docs/especificacion_funcional.md)
- [Arquitectura y revisión del modelo de datos](docs/arquitectura_y_datos.md)
- [Contexto para continuar el proyecto](AGENTS.md)

La definición adopta un **prototipo académico local**. Los cambios al DDL están documentados como propuestas y todavía no se han ejecutado ni incorporado al script original. La primera etapa de desarrollo empieza después de acordar esos cambios y disponer del enunciado o rúbrica, si existen.

## Tecnologías previstas

Python + Flask para la aplicación, plantillas HTML renderizadas en el servidor, SQLAlchemy + PyMySQL para MariaDB, y XAMPP para MariaDB y phpMyAdmin. Durante el desarrollo, Flask servirá la web en `127.0.0.1`; Apache de XAMPP no es necesario para ejecutar Python.

## Referencias técnicas

- [Flask: estructura de una aplicación](https://flask.palletsprojects.com/en/stable/tutorial/factory/)
- [SQLAlchemy: MySQL y MariaDB](https://docs.sqlalchemy.org/en/20/dialects/mysql.html)
- [Apache Friends: MariaDB en XAMPP](https://www.apachefriends.org/faq_windows)

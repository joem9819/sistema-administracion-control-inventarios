# Guía de inicio rápido y lectura del código

Esta guía explica cómo abrir el CRUD actual en Windows y en qué orden leer sus archivos. El CRUD permite crear, consultar, editar y desactivar **categorías y productos**. La pantalla de inventario solo consulta las existencias; todavía no modifica el stock.

## 1. Qué usa realmente el proyecto

| Pieza | Lo que hay en el código |
| --- | --- |
| Aplicación web | Flask, con plantillas Jinja en `templates/` y una hoja de estilos en `static/` |
| Acceso a datos | `PyMySQL` con consultas SQL escritas a mano y parametrizadas, en `db.py` |
| Configuración | `python-dotenv` lee el archivo `.env`; las tres dependencias están en `requirements.txt` |
| Servidor de base de datos | El módulo que XAMPP llama **MySQL**, iniciado en el puerto `3306` |

Sobre el nombre del motor: XAMPP 8.0.30 muestra el módulo como «MySQL», pero el programa que instala es **MariaDB 10.4.32**. Se comprobó ejecutando `C:\xampp\mysql\bin\mysqld.exe --version`. Son dos nombres para el servidor que usa este proyecto, y por eso la documentación los mezcla. El código Python nunca nombra ninguno de los dos: `db.py` solo usa PyMySQL, que habla el protocolo de MySQL y funciona igual contra MariaDB. El archivo `BD/Base_Datos.sql` está encabezado como MySQL 8.0+ y se ejecuta sin cambios sobre MariaDB 10.4.

El proyecto **no usa** SQLAlchemy ni ningún ORM, no usa ODBC y no se ejecuta sobre Apache. Apache solo sirve phpMyAdmin.

## 2. Ejecutar ahora en este equipo

El entorno `.venv` y el archivo `.env` local ya están preparados. No necesitas instalarlos otra vez.

1. Abre **XAMPP Control Panel** e inicia el módulo **MySQL** (puerto `3306`). Apache (puerto `81`) solo se necesita si vas a abrir phpMyAdmin.
2. En **PowerShell** o la terminal de VS Code, ejecuta:

   ```powershell
   cd C:\Users\usuario\Documents\universidad\software_libre\Proyecto_Gestion_Inventario
   .\.venv\Scripts\python.exe app.py
   ```

3. Abre [la aplicación](http://127.0.0.1:5000/) en el navegador. La raíz redirige a la lista de productos; arriba están los enlaces a categorías e inventario.

Para detener Flask, vuelve a esa terminal y presiona **Ctrl+C**.

## 3. Preparar el proyecto en otro equipo

Si se copia el repositorio a otra computadora, abre PowerShell en la carpeta del proyecto y ejecuta:

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
Copy-Item .env.example .env
notepad .env
```

En `.env`, completa `DB_USER` y `DB_PASSWORD` con un usuario que tenga acceso a `bd_inventario_supermercado`. La base y sus vistas deben existir en el servidor. `FLASK_SECRET_KEY` puede quedar vacío: si falta, `app.py` genera una clave nueva en cada arranque y se pierde la sesión al reiniciar. Después sigue los pasos de la sección 2. **No subas `.env` a Git.** En este equipo ya existe un `.env` configurado; no copies el ejemplo encima.

## 4. Probar una operación

1. En **Categorías**, crea una categoría nueva.
2. En **Productos**, crea un producto y selecciona esa categoría.
3. Revisa el producto en la lista y usa **Editar** si deseas cambiar un dato.
4. Abre **Inventario**: el producto nuevo aparece con saldo `0` en cada sucursal activa.

El botón **Desactivar** cumple la función de eliminar sin borrar físicamente los datos. Hay dos reglas en el código: un producto con existencias no se puede desactivar, y una categoría no se puede desactivar mientras tenga productos activos. El stock deberá cambiarse mediante movimientos en una etapa posterior.

Al editar un producto, los nuevos límites de stock se guardan en la tabla de productos, pero **no** se copian a las filas de inventario que ya existen.

## 5. Consultar las vistas en phpMyAdmin

1. Abre [phpMyAdmin](http://localhost:81/phpmyadmin/index.php) con Apache y MySQL iniciados en XAMPP.
2. Selecciona la base **`bd_inventario_supermercado`** en el panel izquierdo.
3. Abre el archivo `BD/consultas_vistas.sql`, copia su contenido y pégalo en la pestaña **SQL** de phpMyAdmin. Ejecútalo.

Ese archivo contiene cuatro consultas `SELECT`: inventario general, kardex, ventas detalladas y compras detalladas. Solo lee datos. **No uses `BD/Base_Datos.sql` para consultar:** ese archivo empieza con `DROP DATABASE` y recrea la base.

La pantalla **Inventario** de la aplicación depende de la vista `vw_inventario_general`. Si esa vista no existe en la base, esa página fallará aunque el resto del CRUD funcione.

## 6. Cómo leer el código

Lee los archivos en este orden:

| Orden | Archivo | Qué debes entender |
| --- | --- | --- |
| 1 | `.env.example` | Los nombres de las variables de conexión. El `.env` real contiene valores locales y no se comparte. |
| 2 | `db.py` | `conectar()` abre una conexión con PyMySQL usando los datos del `.env`; `consultar()` y `consultar_uno()` leen; `guardar()` ejecuta un cambio y hace `commit()`, o `rollback()` si falla. |
| 3 | `app.py`, bloque inicial | `load_dotenv()` carga el `.env`, se fija la clave de sesión y se añade un token CSRF a los formularios. Todo `POST` sin token válido se rechaza con error 400. |
| 4 | `app.py`, sección **Categorías** | Cada ruta recibe una petición web; el formulario se valida y ejecuta `INSERT` o `UPDATE`. |
| 5 | `app.py`, sección **Productos** | Crear un producto también crea su inventario inicial en cero. `commit()` guarda ambos cambios y `rollback()` revierte ambos si hay error. Los precios se leen con `Decimal`, no con `float`. |
| 6 | `app.py`, ruta `/inventario` | Una sola consulta de solo lectura sobre la vista `vw_inventario_general`. |
| 7 | `templates/base.html` y demás archivos de `templates/` | Las páginas HTML muestran listas, campos de formulario y mensajes. `error.html` es la página que se devuelve si la base no responde. |
| 8 | `static/estilos.css` | Apariencia de las páginas. |
| 9 | `BD/consultas_vistas.sql` | Ejemplos de lectura de las cuatro vistas de la base. |

Un ejemplo del recorrido de una petición:

```text
Formulario «Nuevo producto»
    → ruta /productos/nuevo en app.py
    → se comprueba el token CSRF del formulario
    → leer_producto() valida los datos
    → conectar() abre la conexión con PyMySQL
    → INSERT en productos e inventario
    → commit() guarda los cambios
    → el navegador vuelve a la lista
```

En las consultas SQL, `%s` marca el lugar de un valor enviado aparte a `cursor.execute()`. Así no se construye SQL pegando texto escrito por el usuario.

## Si algo no abre

- **Aparece la página «No se pudo consultar la base de datos»:** la aplicación respondió con error 503 porque PyMySQL no pudo hablar con el servidor. Verifica que el módulo MySQL esté iniciado en XAMPP y revisa `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER` y `DB_PASSWORD` en `.env`.
- **Error `(2003, "Can't connect to MySQL server")` en la terminal:** el servidor está apagado o escucha en otro puerto. Inícialo desde XAMPP Control Panel.
- **«El formulario venció. Recarga la página»:** el token CSRF no coincide, normalmente porque Flask se reinició. Recarga la página y vuelve a enviar.
- **El navegador no abre el puerto 5000:** confirma que la terminal donde ejecutaste `app.py` siga abierta y muestre `Running on http://127.0.0.1:5000`.
- **No abre phpMyAdmin:** revisa que Apache esté iniciado en XAMPP y usa el puerto `81`. Esto no impide que Flask funcione en el `5000`.

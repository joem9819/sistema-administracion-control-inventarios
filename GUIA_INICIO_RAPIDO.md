# Guía de inicio rápido y lectura del código

Esta guía explica cómo abrir el CRUD actual en Windows y en qué orden leer sus archivos. El CRUD permite crear, consultar, editar y desactivar **categorías y productos**. La pantalla de inventario solo consulta las existencias.

## 1. Ejecutar ahora en este equipo

El entorno `.venv` y el archivo `.env` local ya están preparados. No necesitas instalarlos otra vez.

1. Abre **XAMPP Control Panel** e inicia **MySQL** (puerto `3306`). Apache (puerto `81`) solo se necesita si vas a abrir phpMyAdmin.
2. En **PowerShell** o la terminal de VS Code, ejecuta:

   ```powershell
   cd C:\Users\usuario\Documents\universidad\software_libre\Proyecto_Gestion_Inventario
   .\.venv\Scripts\python.exe app.py
   ```

3. Abre [la aplicación](http://127.0.0.1:5000/) en el navegador. Verás la lista de productos y el menú de categorías e inventario.

Para detener Flask, vuelve a esa terminal y presiona **Ctrl+C**.

## 2. Preparar el proyecto en otro equipo

Si se copia el repositorio a otra computadora, abre PowerShell en la carpeta del proyecto y ejecuta:

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
Copy-Item .env.example .env
notepad .env
```

En `.env`, completa `DB_USER` y `DB_PASSWORD` con un usuario que tenga acceso a `bd_inventario_supermercado`. La base debe existir en MariaDB. Después sigue los pasos de la sección 1. **No subas `.env` a Git.** En este equipo ya existe un `.env` configurado; no copies el ejemplo encima.

## 3. Probar una operación

1. En **Categorías**, crea una categoría nueva.
2. En **Productos**, crea un producto y selecciona esa categoría.
3. Revisa el producto en la lista y usa **Editar** si deseas cambiar un dato.
4. Abre **Inventario**: el producto nuevo aparece con saldo `0` en cada sucursal activa.

El botón **Desactivar** cumple la función de eliminar sin borrar físicamente los datos. Un producto con existencias no se puede desactivar; el stock deberá cambiarse mediante movimientos en una etapa posterior.

## 4. Consultar las vistas en phpMyAdmin

1. Abre [phpMyAdmin](http://localhost:81/phpmyadmin/index.php) con Apache y MySQL iniciados en XAMPP.
2. Selecciona la base **`bd_inventario_supermercado`** en el panel izquierdo.
3. Abre el archivo `BD/consultas_vistas.sql`, copia su contenido y pégalo en la pestaña **SQL** de phpMyAdmin. Ejecútalo.

Ese archivo contiene cuatro consultas `SELECT`: inventario general, kardex, ventas detalladas y compras detalladas. Solo lee datos. **No uses `BD/Base_Datos.sql` para consultar:** ese archivo empieza con `DROP DATABASE` y recrea la base.

## 5. Cómo leer el código

Lee los archivos en este orden:

| Orden | Archivo | Qué debes entender |
| --- | --- | --- |
| 1 | `.env.example` | Los nombres de las variables de conexión. El `.env` real contiene valores locales y no se comparte. |
| 2 | `db.py` | `conectar()` abre MariaDB; `consultar()` y `consultar_uno()` leen; `guardar()` confirma un cambio. |
| 3 | `app.py`, sección **Categorías** | Cada ruta recibe una petición web; el formulario se valida y ejecuta `INSERT` o `UPDATE`. |
| 4 | `app.py`, sección **Productos** | Crear un producto también crea su inventario inicial en cero. `commit()` guarda ambos cambios y `rollback()` revierte ambos si hay error. |
| 5 | `templates/base.html` y demás archivos de `templates/` | Las páginas HTML muestran listas, campos de formulario y mensajes. |
| 6 | `static/estilos.css` | Apariencia de las páginas. |
| 7 | `BD/consultas_vistas.sql` | Ejemplos de lectura de las cuatro vistas de la base. |

Un ejemplo del recorrido de una petición:

```text
Formulario «Nuevo producto»
    → ruta /productos/nuevo en app.py
    → leer_producto() comprueba los datos
    → conectar() abre MariaDB
    → INSERT en productos e inventario
    → commit() guarda los cambios
    → el navegador vuelve a la lista
```

En las consultas SQL, `%s` marca el lugar de un valor enviado aparte a `cursor.execute()`. Así no se construye SQL pegando texto escrito por el usuario.

## Si algo no abre

- **No conecta a la base:** verifica que MySQL esté iniciado en XAMPP y revisa `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER` y `DB_PASSWORD` en `.env`.
- **El navegador no abre el puerto 5000:** confirma que la terminal donde ejecutaste `app.py` siga abierta y muestre `Running on http://127.0.0.1:5000`.
- **No abre phpMyAdmin:** revisa que Apache esté iniciado en XAMPP y usa el puerto `81`. Esto no impide que Flask funcione en el `5000`.

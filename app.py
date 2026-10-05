"""CRUD básico de categorías y productos del supermercado."""

import os
import secrets
from decimal import Decimal, InvalidOperation

import pymysql
from dotenv import load_dotenv
from flask import (
    Flask,
    abort,
    flash,
    redirect,
    render_template,
    request,
    session,
    url_for,
)

from db import conectar, consultar, consultar_uno, guardar


# Carga los datos de conexión del .env local antes de abrir MariaDB.
load_dotenv()
app = Flask(__name__)
# En .env se puede fijar una clave para conservar la sesión entre reinicios.
app.secret_key = os.getenv("FLASK_SECRET_KEY") or secrets.token_hex(32)


@app.context_processor
def incluir_token():
    """Entrega a todas las plantillas la función csrf_token().

    El decorador @app.context_processor hace que Flask ejecute esto antes de
    dibujar cualquier plantilla, y añada lo que devuelve a sus variables. Así
    no hay que pasar el token en cada render_template().

    Se devuelve la función y no el código ya calculado. De ese modo el token
    solo se crea cuando una plantilla lo pide; las páginas que únicamente
    listan datos no abren sesión para nadie. En el HTML se usa con paréntesis:
    {{ csrf_token() }}.
    """

    def csrf_token():
        # session es una cookie firmada con app.secret_key: el visitante la
        # puede leer, pero no puede fabricar una falsa sin esa clave.
        if "csrf_token" not in session:
            # secrets (no random) genera valores impredecibles, aptos para
            # seguridad. token_urlsafe(24) da texto aleatorio sin caracteres
            # raros, cómodo para viajar dentro de un formulario HTML.
            session["csrf_token"] = secrets.token_urlsafe(24)
        # El mismo visitante conserva su token durante toda la sesión.
        return session["csrf_token"]

    return {"csrf_token": csrf_token}


@app.before_request
def revisar_token():
    """Comprueba el token antes de atender cualquier petición que guarde datos.

    Es la pareja de incluir_token(): una escribe el código en un campo oculto
    del formulario y esta lo verifica al recibirlo.

    Protege contra CSRF (falsificación de petición entre sitios). Si otra
    página web tuviera un formulario oculto apuntando a nuestras rutas, el
    navegador de la víctima enviaría la petición con su cookie de sesión
    incluida. Esa página ajena puede provocar el envío, pero no puede leer la
    cookie de nuestro dominio para copiar el token, así que no pasa.
    """
    # Solo los POST cambian datos; los GET de este CRUD únicamente consultan.
    if request.method == "POST":
        esperado = session.get("csrf_token", "")
        recibido = request.form.get("csrf_token", "")
        # compare_digest tarda siempre lo mismo, falle donde falle. Un == normal
        # se detiene en la primera diferencia y ese tiempo filtra información.
        if not esperado or not secrets.compare_digest(esperado, recibido):
            abort(400, "El formulario venció. Recarga la página e inténtalo de nuevo.")


# Red de seguridad: si una consulta falla en cualquier ruta, se atiende aquí.
@app.errorhandler(pymysql.MySQLError)
def error_base_datos(error):
    # El detalle técnico queda en la consola, no en el navegador del usuario.
    app.logger.exception("Error de base de datos: %s", error)
    # 503 significa «servicio no disponible», que es el caso: la base no responde.
    return render_template("error.html"), 503


@app.get("/")
def inicio():
    # La raíz no tiene pantalla propia; url_for() arma la URL de esa función.
    return redirect(url_for("listar_productos"))


# ------------------------------ Categorías ------------------------------


@app.get("/categorias")
def listar_categorias():
    categorias = consultar(
        "SELECT id_categoria, nombre, descripcion, estado "
        "FROM categorias ORDER BY nombre"
    )
    return render_template("categorias.html", categorias=categorias)


def leer_categoria(formulario):
    """Valida el formulario y devuelve los datos limpios, o lanza ValueError."""
    # strip() quita los espacios sobrantes al inicio y al final.
    # Se valida aquí aunque el HTML ya lo exija: ese control se puede saltar.
    nombre = formulario.get("nombre", "").strip()
    descripcion = formulario.get("descripcion", "").strip()
    if not nombre or len(nombre) > 100:
        raise ValueError("El nombre debe tener entre 1 y 100 caracteres.")
    if len(descripcion) > 250:
        raise ValueError("La descripción no puede superar 250 caracteres.")
    return nombre, descripcion


@app.route("/categorias/nueva", methods=["GET", "POST"])
def crear_categoria():
    # GET muestra el formulario; POST recibe los datos al pulsar «Guardar».
    if request.method == "POST":
        try:
            nombre, descripcion = leer_categoria(request.form)
            guardar(
                "INSERT INTO categorias (nombre, descripcion) VALUES (%s, %s)",
                (nombre, descripcion),
            )
            # flash() deja un mensaje que la página siguiente muestra una sola vez.
            flash("Categoría creada correctamente.", "ok")
            # Se redirige tras guardar; así recargar la página no repite el INSERT.
            return redirect(url_for("listar_categorias"))
        except ValueError as error:
            # Error de validación nuestro: el texto ya viene listo para el usuario.
            flash(str(error), "error")
        except pymysql.IntegrityError:
            # La base rechazó el dato por una restricción suya; aquí, nombre UNIQUE.
            flash("Ya existe una categoría con ese nombre.", "error")
    # Si falló, se devuelve request.form para que no se pierda lo ya escrito.
    return render_template("categoria_form.html", categoria=request.form, titulo="Nueva categoría")


# <int:id_categoria> exige que la URL traiga un número y lo pasa como argumento.
@app.route("/categorias/<int:id_categoria>/editar", methods=["GET", "POST"])
def editar_categoria(id_categoria):
    categoria = consultar_uno(
        "SELECT id_categoria, nombre, descripcion FROM categorias WHERE id_categoria = %s",
        (id_categoria,),
    )
    if categoria is None:
        # consultar_uno() devuelve None si no hay fila: se responde «no encontrado».
        abort(404)
    if request.method == "POST":
        try:
            nombre, descripcion = leer_categoria(request.form)
            guardar(
                "UPDATE categorias SET nombre = %s, descripcion = %s "
                "WHERE id_categoria = %s",
                (nombre, descripcion, id_categoria),
            )
            flash("Categoría actualizada correctamente.", "ok")
            return redirect(url_for("listar_categorias"))
        except ValueError as error:
            flash(str(error), "error")
        except pymysql.IntegrityError:
            flash("Ya existe una categoría con ese nombre.", "error")
        # Tras un error se repinta con lo que el usuario escribió, no con lo guardado.
        categoria = request.form
    return render_template("categoria_form.html", categoria=categoria, titulo="Editar categoría")


@app.post("/categorias/<int:id_categoria>/estado")
def cambiar_estado_categoria(id_categoria):
    categoria = consultar_uno(
        "SELECT estado FROM categorias WHERE id_categoria = %s", (id_categoria,)
    )
    if categoria is None:
        abort(404)
    if categoria["estado"] == 1:
        # Se conserva la categoría si todavía tiene productos activos.
        activos = consultar_uno(
            "SELECT COUNT(*) AS total FROM productos "
            "WHERE id_categoria = %s AND estado = 1",
            (id_categoria,),
        )
        if activos["total"] > 0:
            flash("Desactiva primero los productos activos de esta categoría.", "error")
            return redirect(url_for("listar_categorias"))
    # Invierte el estado: el mismo botón desactiva y vuelve a activar.
    nuevo_estado = 0 if categoria["estado"] == 1 else 1
    guardar(
        "UPDATE categorias SET estado = %s WHERE id_categoria = %s",
        (nuevo_estado, id_categoria),
    )
    flash("Estado de la categoría actualizado.", "ok")
    return redirect(url_for("listar_categorias"))


# ------------------------------- Productos -------------------------------


def categorias_disponibles(id_actual=None):
    """Muestra categorías activas y, al editar, la categoría actual."""
    # El OR evita que al editar desaparezca una categoría ya desactivada.
    # El «or 0» pone un id que no existe cuando se está creando, no editando.
    return consultar(
        "SELECT id_categoria, nombre, estado FROM categorias "
        "WHERE estado = 1 OR id_categoria = %s ORDER BY nombre",
        (id_actual or 0,),
    )


def leer_decimal(formulario, campo):
    """Lee un precio sin usar float, que puede introducir errores de redondeo."""
    try:
        valor = Decimal(formulario.get(campo, ""))
    except InvalidOperation as error:
        # «from error» conserva el error original para el registro técnico.
        raise ValueError(f"{campo.replace('_', ' ').capitalize()} debe ser un número.") from error
    # Decimal acepta textos como "NaN" o "Infinity"; is_finite() los rechaza.
    if not valor.is_finite() or valor < 0 or valor >= 10000000000:
        raise ValueError(f"{campo.replace('_', ' ').capitalize()} debe ser positivo y válido.")
    # El exponente de un Decimal dice cuántos decimales tiene: -2 son dos cifras.
    if valor.as_tuple().exponent < -2:
        raise ValueError(f"{campo.replace('_', ' ').capitalize()} admite máximo 2 decimales.")
    return valor


def leer_producto(formulario):
    """Lee el formulario y valida los campos del DDL actual."""
    datos = {
        "codigo_barras": formulario.get("codigo_barras", "").strip(),
        "nombre": formulario.get("nombre", "").strip(),
        "descripcion": formulario.get("descripcion", "").strip(),
        "marca": formulario.get("marca", "").strip(),
        "unidad_medida": formulario.get("unidad_medida", "UNIDAD").strip().upper(),
    }
    # Las longitudes deben caber en las columnas VARCHAR de productos.
    limites = {"codigo_barras": 50, "nombre": 150, "descripcion": 300,
               "marca": 100, "unidad_medida": 30}
    for campo, limite in limites.items():
        if len(datos[campo]) > limite:
            raise ValueError(f"{campo.replace('_', ' ').capitalize()} es demasiado largo.")
    if not datos["codigo_barras"] or not datos["nombre"] or not datos["unidad_medida"]:
        raise ValueError("Código de barras, nombre y unidad de medida son obligatorios.")
    # Todo lo que llega de un formulario es texto; int() lo convierte a número.
    try:
        datos["id_categoria"] = int(formulario.get("id_categoria", ""))
        datos["stock_minimo"] = int(formulario.get("stock_minimo", ""))
        datos["stock_maximo"] = int(formulario.get("stock_maximo", ""))
    except ValueError as error:
        # int() falla con ValueError si el texto no es un entero.
        raise ValueError("Selecciona una categoría y escribe límites de stock enteros.") from error
    # 2.147.483.647 es el valor máximo que admite una columna INT de la base.
    if (
        datos["stock_minimo"] < 0
        or datos["stock_maximo"] < datos["stock_minimo"]
        or datos["stock_maximo"] > 2_147_483_647
    ):
        raise ValueError("Los límites de stock deben ser válidos y el máximo no menor que el mínimo.")
    datos["precio_compra"] = leer_decimal(formulario, "precio_compra")
    datos["precio_venta"] = leer_decimal(formulario, "precio_venta")
    return datos


@app.get("/productos")
def listar_productos():
    # El JOIN trae el nombre de la categoría; productos solo guarda su id.
    productos = consultar(
        "SELECT p.id_producto, p.codigo_barras, p.nombre, p.precio_venta, "
        "p.estado, c.nombre AS categoria FROM productos p "
        "JOIN categorias c ON c.id_categoria = p.id_categoria "
        "ORDER BY p.nombre"
    )
    return render_template("productos.html", productos=productos)


@app.route("/productos/nuevo", methods=["GET", "POST"])
def crear_producto():
    categorias = categorias_disponibles()
    if request.method == "POST":
        try:
            datos = leer_producto(request.form)
            # El desplegable del HTML se puede manipular antes de enviarlo,
            # así que la categoría se vuelve a comprobar contra la lista real.
            if not any(c["id_categoria"] == datos["id_categoria"] for c in categorias):
                raise ValueError("Selecciona una categoría activa.")
            # Producto e inventario inicial deben guardarse juntos: una transacción.
            # Aquí no se usa guardar() porque son dos consultas en la misma conexión.
            with conectar() as conexion:
                try:
                    with conexion.cursor() as cursor:
                        cursor.execute(
                            "INSERT INTO productos (id_categoria, codigo_barras, nombre, "
                            "descripcion, marca, unidad_medida, precio_compra, precio_venta, "
                            "stock_minimo, stock_maximo) "
                            "VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)",
                            (datos["id_categoria"], datos["codigo_barras"], datos["nombre"],
                             datos["descripcion"], datos["marca"], datos["unidad_medida"],
                             datos["precio_compra"], datos["precio_venta"],
                             datos["stock_minimo"], datos["stock_maximo"]),
                        )
                        # La base asigna sola el id del producto; aquí se recupera
                        # para poder relacionar las filas de inventario.
                        id_producto = cursor.lastrowid
                        # INSERT ... SELECT crea una fila por sucursal activa en una
                        # sola consulta, sin recorrer las sucursales desde Python.
                        cursor.execute(
                            "INSERT INTO inventario "
                            "(id_producto, id_sucursal, stock_actual, stock_minimo, stock_maximo) "
                            "SELECT %s, id_sucursal, 0, %s, %s FROM sucursales WHERE estado = 1",
                            (id_producto, datos["stock_minimo"], datos["stock_maximo"]),
                        )
                    # Confirma las dos inserciones solo cuando ambas terminan bien.
                    conexion.commit()
                except Exception:
                    # Si una falla, no queda un producto creado a medias.
                    conexion.rollback()
                    raise
            flash("Producto creado con inventario inicial en cero.", "ok")
            return redirect(url_for("listar_productos"))
        except ValueError as error:
            flash(str(error), "error")
        except pymysql.IntegrityError:
            flash("El código de barras ya existe o la categoría no es válida.", "error")
    return render_template(
        "producto_form.html", producto=request.form, categorias=categorias, titulo="Nuevo producto"
    )


@app.route("/productos/<int:id_producto>/editar", methods=["GET", "POST"])
def editar_producto(id_producto):
    producto = consultar_uno("SELECT * FROM productos WHERE id_producto = %s", (id_producto,))
    if producto is None:
        abort(404)
    categorias = categorias_disponibles(producto["id_categoria"])
    if request.method == "POST":
        try:
            datos = leer_producto(request.form)
            if not any(c["id_categoria"] == datos["id_categoria"] for c in categorias):
                raise ValueError("Selecciona una categoría válida.")
            guardar(
                "UPDATE productos SET id_categoria = %s, codigo_barras = %s, nombre = %s, "
                "descripcion = %s, marca = %s, unidad_medida = %s, precio_compra = %s, "
                "precio_venta = %s, stock_minimo = %s, stock_maximo = %s WHERE id_producto = %s",
                (datos["id_categoria"], datos["codigo_barras"], datos["nombre"],
                 datos["descripcion"], datos["marca"], datos["unidad_medida"],
                 datos["precio_compra"], datos["precio_venta"],
                 datos["stock_minimo"], datos["stock_maximo"], id_producto),
            )
            flash("Producto actualizado. Los límites de sucursales existentes no cambian.", "ok")
            return redirect(url_for("listar_productos"))
        except ValueError as error:
            flash(str(error), "error")
        except pymysql.IntegrityError:
            flash("El código de barras ya existe o la categoría no es válida.", "error")
        producto = request.form
    return render_template(
        "producto_form.html", producto=producto, categorias=categorias, titulo="Editar producto"
    )


@app.post("/productos/<int:id_producto>/estado")
def cambiar_estado_producto(id_producto):
    producto = consultar_uno("SELECT estado FROM productos WHERE id_producto = %s", (id_producto,))
    if producto is None:
        abort(404)
    if producto["estado"] == 1:
        # «Eliminar» desactiva el producto, pero primero exige saldo cero.
        # SUM() devuelve NULL si no hay filas; COALESCE lo convierte en 0.
        saldo = consultar_uno(
            "SELECT COALESCE(SUM(stock_actual), 0) AS total "
            "FROM inventario WHERE id_producto = %s",
            (id_producto,),
        )
        if saldo["total"] > 0:
            flash("No se puede desactivar un producto que todavía tiene existencias.", "error")
            return redirect(url_for("listar_productos"))
    nuevo_estado = 0 if producto["estado"] == 1 else 1
    guardar(
        "UPDATE productos SET estado = %s WHERE id_producto = %s",
        (nuevo_estado, id_producto),
    )
    flash("Estado del producto actualizado.", "ok")
    return redirect(url_for("listar_productos"))


# El inventario se consulta, pero el stock no se edita en este CRUD.
@app.get("/inventario")
def ver_inventario():
    filas = consultar(
        "SELECT producto, categoria, sucursal, stock_actual, stock_minimo, "
        "stock_maximo, estado_inventario FROM vw_inventario_general "
        "ORDER BY sucursal, producto"
    )
    return render_template("inventario.html", filas=filas)


if __name__ == "__main__":
    # Esta línea solo corre si se ejecuta «python app.py» directamente.
    # Es el servidor de desarrollo de Flask: sirve para clase, no para producción.
    app.run(host="127.0.0.1", port=5000, debug=False)

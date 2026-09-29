"""Conexión a la base de datos del inventario."""

import os

import pymysql
from pymysql.cursors import DictCursor


def conectar():
    """Abre una conexión nueva. Quien la use debe cerrarla al terminar."""
    return pymysql.connect(
        host=os.getenv("DB_HOST", "127.0.0.1"),
        port=int(os.getenv("DB_PORT", "3306")),
        user=os.getenv("DB_USER", "user_python"),
        password=os.getenv("DB_PASSWORD", ""),
        database=os.getenv("DB_NAME", "bd_inventario_supermercado"),
        charset="utf8mb4",
        # Cada fila se recibe como {"nombre_columna": valor}, fácil de leer.
        cursorclass=DictCursor,
        connect_timeout=5,
    )


def consultar(sql, valores=()):
    """Ejecuta un SELECT y devuelve sus filas como diccionarios."""
    # Los bloques with cierran el cursor y la conexión al salir.
    with conectar() as conexion:
        with conexion.cursor() as cursor:
            # Los valores reemplazan los %s de la consulta de forma segura.
            cursor.execute(sql, valores)
            return cursor.fetchall()


def consultar_uno(sql, valores=()):
    """Ejecuta un SELECT y devuelve una fila, o None."""
    with conectar() as conexion:
        with conexion.cursor() as cursor:
            cursor.execute(sql, valores)
            return cursor.fetchone()


def guardar(sql, valores):
    """Ejecuta un INSERT o UPDATE y confirma el cambio."""
    with conectar() as conexion:
        try:
            with conexion.cursor() as cursor:
                cursor.execute(sql, valores)
            # Sin commit(), el cambio no queda guardado en MariaDB.
            conexion.commit()
        except Exception:
            # Si falla la operación, se deshace antes de informar el error.
            conexion.rollback()
            raise

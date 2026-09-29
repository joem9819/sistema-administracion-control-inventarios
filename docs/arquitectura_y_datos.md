# Arquitectura y revisión del modelo de datos

## 1. Arquitectura propuesta

```text
Navegador
   │ HTML / formularios
   ▼
Flask (Python, servidor local)
   ├─ rutas y plantillas Jinja
   ├─ autenticación y permisos
   ├─ servicios de compras, ventas e inventario
   └─ SQLAlchemy + PyMySQL
                 │
                 ▼
         MariaDB de XAMPP
                 ▲
                 │ administración manual
             phpMyAdmin
```

Flask ejecutará la web durante el desarrollo en `127.0.0.1:5000` desde PowerShell o la terminal de VS Code. XAMPP iniciará MariaDB y ofrecerá phpMyAdmin; no se desarrollará en PHP. Apache puede permanecer instalado y no se necesita para servir Flask en esta etapa. Esta separación evita mezclar el servidor de desarrollo Python con la administración de la base de datos.

Estructura prevista, aún sin código:

```text
Proyecto_Gestion_Inventario/
├── app/
│   ├── __init__.py          # fábrica de Flask
│   ├── auth/                # acceso y roles
│   ├── catalogos/
│   ├── inventario/
│   ├── operaciones/         # compras y ventas
│   ├── reportes/
│   ├── templates/
│   └── static/
├── BD/
├── docs/
├── tests/
├── .env.example
├── .gitignore
└── pyproject.toml
```

Se propone usar plantillas HTML del servidor con CSS sencillo y un poco de JavaScript para formularios dinámicos. SQLAlchemy manejará las consultas y transacciones; PyMySQL permite conectarlo con MariaDB. Se usará un usuario de base de datos propio para `bd_inventario_supermercado`, con permisos solo sobre esa base. El usuario académico `user_python` está configurado para `db_persons`, así que no se asumirá que tiene acceso aquí.

## 2. Revisión del DDL existente

El archivo `BD/Base_Datos.sql` crea 17 tablas, 4 vistas, datos iniciales y 20 consultas de prueba. Tiene claves foráneas, unicidad de inventario por producto y sucursal y restricciones básicas. Es una base útil para el prototipo, con los siguientes ajustes antes de construir sobre ella.

| Prioridad | Hallazgo | Ajuste propuesto |
| --- | --- | --- |
| Alta | El script inicia con `DROP DATABASE IF EXISTS`. | Conservarlo como archivo original y preparar una versión de instalación **solo para base nueva**, separada de futuras migraciones. Nunca ejecutarlo sobre datos que se deban conservar. |
| Alta | `usuarios.password` y usuarios de prueba guardan `123456` en texto plano. | Cambiar a `password_hash VARCHAR(255)`, retirar contraseñas literales del SQL y crear el primer administrador con un comando Python que genere un hash. No basta con renombrar la columna: los datos actuales seguirían siendo texto plano. |
| Alta | Compra `FC-10001`: encabezado subtotal `320000`, detalles `100×3200 + 50×2800 = 460000`. | Con la tasa de ejemplo del 19 %, corregir a subtotal `460000`, impuesto `87400` y total `547400`; después verificar todas las facturas automáticamente. |
| Alta | El stock se ajusta con `UPDATE` manual y solo cinco movimientos de prueba. | Cargar saldos iniciales y operaciones de prueba de forma coherente con kardex; en la aplicación, actualizar stock y registrar movimiento en una misma transacción. |
| Media | `compras.numero_factura` no es único. | Añadir `UNIQUE (id_proveedor, numero_factura)` para impedir duplicados de un proveedor. |
| Media | Un descuento puede superar el bruto de una línea y producir subtotal negativo. | Añadir `CHECK (descuento <= cantidad * precio_unitario)` a ambos detalles. |
| Media | La vista y el alta de alertas usan `< stock_minimo`. | Usar `<= stock_minimo`, manteniendo primero la condición de agotado. |
| Media | Los impuestos están solo en encabezados; falta la regla para tasas distintas por producto. | Guardar tasa predeterminada en producto y tasa aplicada en cada línea. Calcular el total en Python según la especificación funcional y validarlo con los detalles. La venta `FV-10002` también deberá corregirse: subtotal `16000`, descuento informativo `500`, impuesto `3040` y total `19040` con la tasa de ejemplo del 19 %. |
| Media | `alertas_inventario` solo se llena durante la carga inicial. | Crear/actualizar alertas al cambiar existencias y cerrar las que dejan de corresponder; evitar duplicados pendientes. |
| Baja | Stock mínimo y máximo existen en `productos` y en `inventario`. | Mantener los valores del producto como **predeterminados**; el registro de cada sucursal guarda sus límites efectivos. Documentar y mostrar esta diferencia en la interfaz. |

El archivo de exclusiones se llama `gitignore`, sin punto. Al comenzar el código debe quedar como `.gitignore` para que Git ignore `.env`, entornos virtuales y temporales.

## 3. Cambios de esquema sugeridos

Estos fragmentos describen el destino del DDL, **no son una migración lista para ejecutar** sobre una base existente. La versión instalable se generará a partir del archivo original después de acordar impuestos y datos de prueba.

```sql
-- En la tabla usuarios de la nueva versión:
password_hash VARCHAR(255) NOT NULL

-- En compras:
CONSTRAINT uq_compras_proveedor_factura
    UNIQUE (id_proveedor, numero_factura)

-- En detalle_compras (repetir en detalle_ventas con nombre propio):
CONSTRAINT chk_detalle_compras_descuento_bruto
    CHECK (descuento <= cantidad * precio_unitario)

-- En productos, como valor predeterminado al crear operaciones:
tasa_impuesto DECIMAL(5,2) NOT NULL DEFAULT 0,
CONSTRAINT chk_productos_tasa_impuesto
    CHECK (tasa_impuesto BETWEEN 0 AND 100)

-- En detalle_compras (repetir en detalle_ventas con nombre propio):
tasa_impuesto_aplicada DECIMAL(5,2) NOT NULL DEFAULT 0,
CONSTRAINT chk_detalle_compras_tasa_impuesto
    CHECK (tasa_impuesto_aplicada BETWEEN 0 AND 100)
```

Para impuestos se propone agregar `tasa_impuesto` al catálogo como valor predeterminado y `tasa_impuesto_aplicada` al detalle de cada compra o venta para conservar la tasa histórica. La fórmula y el redondeo se describen en la especificación funcional. Los datos de ejemplo usarán el 19 % solo como escenario académico y no se presentarán como liquidación fiscal real.

No se propone un disparador que cambie el inventario: la operación de negocio debe guardar encabezado, detalles, movimiento y saldo en **una transacción**. Para evitar ventas simultáneas con el mismo saldo, el servicio bloqueará la fila de inventario dentro de la transacción (`SELECT ... FOR UPDATE`) y validará el stock antes de descontar. Si algo falla, toda la operación se revierte.

## 4. Decisiones técnicas y verificación

- Autenticación por sesión; contraseñas con hash mediante Werkzeug, sin claves en el repositorio.
- Validación en servidor para todos los formularios y protección CSRF en operaciones que cambian datos.
- Uso de `Decimal` para dinero y de claves foráneas para conservar relaciones.
- `estado` para desactivar catálogos sin borrar historial; no borrar compras, ventas ni movimientos desde la interfaz.
- Pruebas de permisos, integridad de saldos, operaciones repetidas, concurrencia básica y conciliación de importes.
- Primero ejecutar la versión revisada del esquema en una base de **pruebas nueva** de MariaDB 10.4; comprobar tablas, vistas, restricciones y consultas antes de utilizarla para desarrollo.

## 5. Fuentes técnicas

- [Flask: fábrica de aplicación y organización](https://flask.palletsprojects.com/en/stable/tutorial/factory/)
- [Flask: módulos mediante blueprints](https://flask.palletsprojects.com/en/stable/blueprints/)
- [SQLAlchemy: conexión con MySQL/MariaDB](https://docs.sqlalchemy.org/en/20/dialects/mysql.html)
- [SQLAlchemy: transacciones](https://docs.sqlalchemy.org/en/20/tutorial/dbapi_transactions.html)
- [MariaDB: bloqueo `FOR UPDATE`](https://mariadb.com/docs/server/reference/sql-statements/data-manipulation/selecting-data/for-update)
- [Werkzeug: hash de contraseñas](https://werkzeug.palletsprojects.com/en/stable/utils/)
- [Apache Friends: MariaDB en XAMPP](https://www.apachefriends.org/faq_windows)

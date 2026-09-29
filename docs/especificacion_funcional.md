# Especificación funcional inicial

## 1. Objetivo y alcance

Desarrollar una aplicación web local para consultar y controlar existencias de productos de un supermercado por sucursal. La aplicación registrará entradas, salidas y ajustes con trazabilidad; también permitirá registrar compras y ventas de ejemplo y consultar reportes. Es un prototipo académico, no un sistema de facturación electrónica ni una solución preparada para operar públicamente.

El modelo inicial contempla tres sucursales. Para la primera versión se usarán los precios de compra y venta del catálogo para todas las sucursales; el inventario y sus límites sí serán independientes por sucursal. Las cantidades serán unidades enteras, como en el DDL actual.

## 2. Usuarios y permisos

Se conservarán los cuatro roles del modelo. El control de permisos se aplicará en el servidor a cada operación, además de ocultar opciones que no correspondan en la interfaz.

| Función | Administrador | Supervisor | Bodeguero | Vendedor |
| --- | :---: | :---: | :---: | :---: |
| Ver tablero, productos e inventario | Sí | Sí | Sí | Sí |
| Administrar categorías, productos, proveedores y sucursales | Sí | Sí | Productos y proveedores | No |
| Crear y recibir compras | Sí | Sí | Sí | No |
| Registrar ajustes de inventario | Sí | Sí | Sí | No |
| Crear y cobrar ventas; administrar clientes | Sí | Sí | No | Sí |
| Consultar kardex, alertas y reportes | Sí | Sí | Kardex y alertas | Sus ventas |
| Administrar usuarios y roles | Sí | No | No | No |

La asignación de usuarios a sucursales no está en el DDL. En la primera versión los usuarios autorizados podrán seleccionar una sucursal activa al registrar operaciones. Si el enunciado exige restricciones por sucursal, se añadirá una relación `usuario_sucursales` antes de implementar permisos.

## 3. Módulos y pantallas

1. **Acceso:** inicio y cierre de sesión; administración de cuentas por el administrador.
2. **Tablero:** cantidad de productos, existencias por sucursal, alertas y operaciones recientes.
3. **Catálogos:** categorías, productos, proveedores, clientes, sucursales y métodos de pago. Buscar, filtrar, crear y editar; desactivar sin borrar registros históricos.
4. **Inventario:** consultar existencias por producto y sucursal, límites mínimo y máximo y ubicación; ver kardex; registrar ajustes justificados.
5. **Compras:** registrar encabezado y líneas; recibir una compra para aumentar existencias.
6. **Ventas:** registrar encabezado y líneas; cobrar una venta para disminuir existencias.
7. **Alertas:** consultar productos agotados, bajo mínimo y sobre máximo; marcar alertas atendidas cuando corresponda.
8. **Reportes:** inventario actual, movimientos, compras, ventas y productos más vendidos; filtros por fechas y sucursal.

La interfaz será adaptable a computador y móvil, en español, con formularios sencillos y mensajes de validación comprensibles. No se requiere una API pública ni un frontend separado para este prototipo.

## 4. Reglas de negocio

### Inventario

- Cada par `(producto, sucursal)` tendrá un solo registro en `inventario`.
- `stock_actual` nunca podrá ser negativo. El máximo genera una alerta, pero no impide ingresar mercancía.
- Después de cargar el saldo inicial, nadie modificará `stock_actual` directamente desde una pantalla: toda variación debe producir un movimiento de kardex con usuario, fecha, motivo, cantidad y saldos anterior y nuevo.
- El saldo inicial deberá quedar identificado como apertura en el kardex, o documentarse explícitamente como punto de partida si la rúbrica solo pide movimientos posteriores.
- Se considera **stock bajo cuando `stock_actual <= stock_minimo`**; agotado (`0`) tiene prioridad visual sobre stock bajo. El DDL actual usa `<` y debe ajustarse para esta definición.
- Las alertas representan un estado pendiente de atención y no sustituyen la consulta en tiempo real del inventario. Se crearán o actualizarán cuando cambie el stock, sin duplicar alertas pendientes del mismo tipo para el mismo producto y sucursal.

### Compras

- Una compra `REGISTRADA` no aumenta el stock. Al pasar una sola vez a `RECIBIDA`, cada línea genera una entrada de inventario.
- Una compra `REGISTRADA` puede anularse. Para la primera versión, una compra `RECIBIDA` no podrá anularse directamente; una devolución se registrará como movimiento compensatorio posterior.
- La factura se identificará de forma única por proveedor y número de factura.
- El subtotal, impuesto y total del encabezado deben coincidir con sus líneas. Los importes se calcularán con decimales, nunca con `float`.

### Ventas

- Una venta `PENDIENTE` no descuenta ni reserva stock. Al pasar una sola vez a `PAGADA`, cada línea produce una salida.
- No se permite cobrar si alguna línea dejaría el stock negativo en su sucursal.
- Una venta `PENDIENTE` puede anularse. Una venta `PAGADA` se conserva como historial; para la primera versión no se anulará desde la interfaz. Las devoluciones se abordarán en una fase posterior mediante movimientos compensatorios.
- Si no se capturan datos de un comprador, se seleccionará un cliente genérico de prueba (`Consumidor final`); el esquema actual requiere `id_cliente`.
- El precio unitario aplicado queda registrado en el detalle, aunque el precio del catálogo cambie después.

### Importes de demostración

- El prototipo registrará impuestos de ejemplo y **no emitirá documentos fiscales**. Cada producto tendrá una tasa predeterminada editable; al registrar una compra o venta se guardará la tasa efectivamente aplicada en cada línea. La rúbrica del docente podrá modificar esta regla.
- En cada línea: `bruto = cantidad × precio_unitario`; `subtotal = bruto − descuento`; `impuesto_linea = redondear(subtotal × tasa_aplicada / 100, 2)`.
- En compras y ventas: `subtotal` del encabezado = suma de los subtotales de las líneas; `impuesto` = suma de impuestos de las líneas; `total = subtotal + impuesto`. En ventas, el campo `descuento` del encabezado será la suma **informativa** de descuentos de las líneas y no se restará otra vez.
- Los descuentos no pueden ser negativos ni superiores al bruto de su línea. La tasa aplicada estará entre 0 y 100 y se calculará con `Decimal`.

## 5. Secuencia de desarrollo

| Etapa | Resultado verificable |
| --- | --- |
| 0. Modelo | DDL revisado, datos de prueba coherentes y creación comprobada en una base de pruebas de MariaDB |
| 1. Base web | Inicio de sesión, roles, estructura de páginas, conexión y catálogos |
| 2. Inventario | Consulta por sucursal, ajustes con kardex y alertas |
| 3. Operaciones | Compras y ventas con cambios de stock en transacciones |
| 4. Cierre | Reportes, pruebas de flujos, manual breve y demostración |

## 6. Criterios de aceptación

- Un vendedor no puede modificar stock ni administrar usuarios, aunque escriba la URL manualmente.
- Una compra recibida o una venta pagada no puede aplicar sus movimientos dos veces.
- Una venta con stock insuficiente se rechaza completa, sin guardar líneas ni movimientos parciales.
- Cada cambio de stock queda reflejado en el kardex y coincide con el saldo actual.
- Los totales de compras y ventas coinciden con los detalles.
- Los datos y contraseñas de conexión se leen de variables de entorno o `.env` ignorado por Git.
- El proyecto puede iniciarse en Windows siguiendo un README y usando MariaDB de XAMPP.

## 7. Pendientes del enunciado

No se encontró una consigna ni rúbrica en la carpeta. Si el docente entregó requisitos sobre framework, interfaz, número de módulos, reportes, autenticación, pruebas o fecha de entrega, deberán contrastarse con esta especificación antes de programar.

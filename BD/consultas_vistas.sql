-- Selecciona bd_inventario_supermercado en phpMyAdmin antes de ejecutar.
-- Este archivo solo consulta las cuatro vistas del modelo original.

-- 1. Existencias de cada producto por sucursal.
SELECT *
FROM vw_inventario_general
ORDER BY sucursal, producto;

-- 2. Historial de movimientos de inventario.
SELECT *
FROM vw_kardex
ORDER BY fecha_movimiento DESC, id_movimiento DESC;

-- 3. Ventas con sus productos y responsables.
SELECT *
FROM vw_ventas_detalladas
ORDER BY fecha_venta DESC, id_venta DESC;

-- 4. Compras con sus productos y proveedores.
SELECT *
FROM vw_compras_detalladas
ORDER BY fecha_compra DESC, id_compra DESC;

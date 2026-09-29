/* ============================================================
   PROYECTO: SISTEMA DE ADMINISTRACIÓN Y CONTROL DE INVENTARIOS
   MOTOR: MySQL 8.0+
   BASE DE DATOS: bd_inventario_supermercado

   ============================================================ */


/* ============================================================
   1. CREACIÓN DE BASE DE DATOS
   ============================================================ */

DROP DATABASE IF EXISTS bd_inventario_supermercado;

CREATE DATABASE bd_inventario_supermercado
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE bd_inventario_supermercado;


/* ============================================================
   2. TABLA: ROLES
   ============================================================ */

CREATE TABLE roles (
    id_rol INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion VARCHAR(200),
    estado TINYINT(1) NOT NULL DEFAULT 1,

    CONSTRAINT chk_roles_estado
        CHECK (estado IN (0,1))
) ENGINE=InnoDB;


/* ============================================================
   3. TABLA: SUCURSALES
   ============================================================ */

CREATE TABLE sucursales (
    id_sucursal INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    direccion VARCHAR(200),
    telefono VARCHAR(30),
    ciudad VARCHAR(100) NOT NULL,
    estado TINYINT(1) NOT NULL DEFAULT 1,

    CONSTRAINT chk_sucursales_estado
        CHECK (estado IN (0,1))
) ENGINE=InnoDB;


/* ============================================================
   4. TABLA: USUARIOS
   ============================================================ */

CREATE TABLE usuarios (
    id_usuario INT AUTO_INCREMENT PRIMARY KEY,
    id_rol INT NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    correo VARCHAR(150) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    telefono VARCHAR(30),
    estado TINYINT(1) NOT NULL DEFAULT 1,
    fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_usuarios_roles
        FOREIGN KEY (id_rol)
        REFERENCES roles(id_rol),

    CONSTRAINT chk_usuarios_estado
        CHECK (estado IN (0,1))
) ENGINE=InnoDB;

CREATE INDEX idx_usuarios_rol
ON usuarios(id_rol);


/* ============================================================
   5. TABLA: CATEGORIAS
   ============================================================ */

CREATE TABLE categorias (
    id_categoria INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL UNIQUE,
    descripcion VARCHAR(250),
    estado TINYINT(1) NOT NULL DEFAULT 1,

    CONSTRAINT chk_categorias_estado
        CHECK (estado IN (0,1))
) ENGINE=InnoDB;


/* ============================================================
   6. TABLA: PRODUCTOS
   ============================================================ */

CREATE TABLE productos (
    id_producto INT AUTO_INCREMENT PRIMARY KEY,
    id_categoria INT NOT NULL,

    codigo_barras VARCHAR(50) NOT NULL UNIQUE,
    nombre VARCHAR(150) NOT NULL,
    descripcion VARCHAR(300),
    marca VARCHAR(100),

    unidad_medida VARCHAR(30) NOT NULL DEFAULT 'UNIDAD',

    precio_compra DECIMAL(12,2) NOT NULL DEFAULT 0,
    precio_venta DECIMAL(12,2) NOT NULL DEFAULT 0,

    stock_minimo INT NOT NULL DEFAULT 5,
    stock_maximo INT NOT NULL DEFAULT 100,

    estado TINYINT(1) NOT NULL DEFAULT 1,

    fecha_creacion DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_productos_categorias
        FOREIGN KEY (id_categoria)
        REFERENCES categorias(id_categoria),

    CONSTRAINT chk_productos_precio_compra
        CHECK (precio_compra >= 0),

    CONSTRAINT chk_productos_precio_venta
        CHECK (precio_venta >= 0),

    CONSTRAINT chk_productos_stock_minimo
        CHECK (stock_minimo >= 0),

    CONSTRAINT chk_productos_stock_maximo
        CHECK (stock_maximo >= stock_minimo),

    CONSTRAINT chk_productos_estado
        CHECK (estado IN (0,1))
) ENGINE=InnoDB;

CREATE INDEX idx_productos_categoria
ON productos(id_categoria);

CREATE INDEX idx_productos_nombre
ON productos(nombre);


/* ============================================================
   7. TABLA: PROVEEDORES
   ============================================================ */

CREATE TABLE proveedores (
    id_proveedor INT AUTO_INCREMENT PRIMARY KEY,

    nombre_empresa VARCHAR(150) NOT NULL,
    nit VARCHAR(30) NOT NULL UNIQUE,
    contacto VARCHAR(150),
    telefono VARCHAR(30),
    correo VARCHAR(150),
    direccion VARCHAR(200),
    estado TINYINT(1) NOT NULL DEFAULT 1,

    CONSTRAINT chk_proveedores_estado
        CHECK (estado IN (0,1))
) ENGINE=InnoDB;


/* ============================================================
   8. TABLA: CLIENTES
   ============================================================ */

CREATE TABLE clientes (
    id_cliente INT AUTO_INCREMENT PRIMARY KEY,

    tipo_documento VARCHAR(20) NOT NULL,
    numero_documento VARCHAR(30) NOT NULL UNIQUE,

    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100),

    telefono VARCHAR(30),
    correo VARCHAR(150),
    direccion VARCHAR(200),

    estado TINYINT(1) NOT NULL DEFAULT 1,

    CONSTRAINT chk_clientes_estado
        CHECK (estado IN (0,1))
) ENGINE=InnoDB;


/* ============================================================
   9. TABLA: METODOS DE PAGO
   ============================================================ */

CREATE TABLE metodos_pago (
    id_metodo_pago INT AUTO_INCREMENT PRIMARY KEY,

    nombre VARCHAR(50) NOT NULL UNIQUE,
    descripcion VARCHAR(200),
    estado TINYINT(1) NOT NULL DEFAULT 1,

    CONSTRAINT chk_metodos_pago_estado
        CHECK (estado IN (0,1))
) ENGINE=InnoDB;


/* ============================================================
   10. TABLA: TIPOS DE MOVIMIENTO
   ============================================================ */

CREATE TABLE tipos_movimiento (
    id_tipo_movimiento INT AUTO_INCREMENT PRIMARY KEY,

    nombre VARCHAR(100) NOT NULL UNIQUE,

    tipo ENUM('ENTRADA','SALIDA') NOT NULL,

    descripcion VARCHAR(250),

    estado TINYINT(1) NOT NULL DEFAULT 1,

    CONSTRAINT chk_tipos_movimiento_estado
        CHECK (estado IN (0,1))
) ENGINE=InnoDB;


/* ============================================================
   11. TABLA: INVENTARIO
   ============================================================ */

CREATE TABLE inventario (
    id_inventario INT AUTO_INCREMENT PRIMARY KEY,

    id_producto INT NOT NULL,
    id_sucursal INT NOT NULL,

    stock_actual INT NOT NULL DEFAULT 0,

    stock_minimo INT NOT NULL DEFAULT 5,
    stock_maximo INT NOT NULL DEFAULT 100,

    ubicacion VARCHAR(100),

    fecha_actualizacion DATETIME
        NOT NULL DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT fk_inventario_productos
        FOREIGN KEY (id_producto)
        REFERENCES productos(id_producto),

    CONSTRAINT fk_inventario_sucursales
        FOREIGN KEY (id_sucursal)
        REFERENCES sucursales(id_sucursal),

    CONSTRAINT uq_inventario_producto_sucursal
        UNIQUE (id_producto, id_sucursal),

    CONSTRAINT chk_inventario_stock
        CHECK (stock_actual >= 0),

    CONSTRAINT chk_inventario_minimo
        CHECK (stock_minimo >= 0),

    CONSTRAINT chk_inventario_maximo
        CHECK (stock_maximo >= stock_minimo)
) ENGINE=InnoDB;

CREATE INDEX idx_inventario_producto
ON inventario(id_producto);

CREATE INDEX idx_inventario_sucursal
ON inventario(id_sucursal);


/* ============================================================
   12. TABLA: COMPRAS
   ============================================================ */

CREATE TABLE compras (
    id_compra INT AUTO_INCREMENT PRIMARY KEY,

    id_proveedor INT NOT NULL,
    id_usuario INT NOT NULL,
    id_sucursal INT NOT NULL,

    fecha_compra DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    numero_factura VARCHAR(50) NOT NULL,

    subtotal DECIMAL(12,2) NOT NULL DEFAULT 0,
    impuesto DECIMAL(12,2) NOT NULL DEFAULT 0,
    total DECIMAL(12,2) NOT NULL DEFAULT 0,

    estado ENUM(
        'REGISTRADA',
        'RECIBIDA',
        'ANULADA'
    ) NOT NULL DEFAULT 'REGISTRADA',

    CONSTRAINT fk_compras_proveedores
        FOREIGN KEY (id_proveedor)
        REFERENCES proveedores(id_proveedor),

    CONSTRAINT fk_compras_usuarios
        FOREIGN KEY (id_usuario)
        REFERENCES usuarios(id_usuario),

    CONSTRAINT fk_compras_sucursales
        FOREIGN KEY (id_sucursal)
        REFERENCES sucursales(id_sucursal),

    CONSTRAINT chk_compras_subtotal
        CHECK (subtotal >= 0),

    CONSTRAINT chk_compras_impuesto
        CHECK (impuesto >= 0),

    CONSTRAINT chk_compras_total
        CHECK (total >= 0)
) ENGINE=InnoDB;

CREATE INDEX idx_compras_fecha
ON compras(fecha_compra);

CREATE INDEX idx_compras_proveedor
ON compras(id_proveedor);


/* ============================================================
   13. TABLA: DETALLE DE COMPRAS
   ============================================================ */

CREATE TABLE detalle_compras (
    id_detalle_compra INT AUTO_INCREMENT PRIMARY KEY,

    id_compra INT NOT NULL,
    id_producto INT NOT NULL,

    cantidad INT NOT NULL,
    precio_unitario DECIMAL(12,2) NOT NULL,

    descuento DECIMAL(12,2) NOT NULL DEFAULT 0,

    subtotal DECIMAL(12,2)
        GENERATED ALWAYS AS
        ((cantidad * precio_unitario) - descuento)
        STORED,

    CONSTRAINT fk_detalle_compras_compra
        FOREIGN KEY (id_compra)
        REFERENCES compras(id_compra)
        ON DELETE CASCADE,

    CONSTRAINT fk_detalle_compras_producto
        FOREIGN KEY (id_producto)
        REFERENCES productos(id_producto),

    CONSTRAINT chk_detalle_compras_cantidad
        CHECK (cantidad > 0),

    CONSTRAINT chk_detalle_compras_precio
        CHECK (precio_unitario >= 0),

    CONSTRAINT chk_detalle_compras_descuento
        CHECK (descuento >= 0)
) ENGINE=InnoDB;

CREATE INDEX idx_detalle_compras_producto
ON detalle_compras(id_producto);


/* ============================================================
   14. TABLA: VENTAS
   ============================================================ */

CREATE TABLE ventas (
    id_venta INT AUTO_INCREMENT PRIMARY KEY,

    id_cliente INT NOT NULL,
    id_usuario INT NOT NULL,
    id_sucursal INT NOT NULL,
    id_metodo_pago INT NOT NULL,

    fecha_venta DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    numero_factura VARCHAR(50) NOT NULL UNIQUE,

    subtotal DECIMAL(12,2) NOT NULL DEFAULT 0,
    impuesto DECIMAL(12,2) NOT NULL DEFAULT 0,
    descuento DECIMAL(12,2) NOT NULL DEFAULT 0,
    total DECIMAL(12,2) NOT NULL DEFAULT 0,

    estado ENUM(
        'PENDIENTE',
        'PAGADA',
        'ANULADA'
    ) NOT NULL DEFAULT 'PENDIENTE',

    CONSTRAINT fk_ventas_clientes
        FOREIGN KEY (id_cliente)
        REFERENCES clientes(id_cliente),

    CONSTRAINT fk_ventas_usuarios
        FOREIGN KEY (id_usuario)
        REFERENCES usuarios(id_usuario),

    CONSTRAINT fk_ventas_sucursales
        FOREIGN KEY (id_sucursal)
        REFERENCES sucursales(id_sucursal),

    CONSTRAINT fk_ventas_metodos_pago
        FOREIGN KEY (id_metodo_pago)
        REFERENCES metodos_pago(id_metodo_pago),

    CONSTRAINT chk_ventas_subtotal
        CHECK (subtotal >= 0),

    CONSTRAINT chk_ventas_impuesto
        CHECK (impuesto >= 0),

    CONSTRAINT chk_ventas_descuento
        CHECK (descuento >= 0),

    CONSTRAINT chk_ventas_total
        CHECK (total >= 0)
) ENGINE=InnoDB;

CREATE INDEX idx_ventas_fecha
ON ventas(fecha_venta);

CREATE INDEX idx_ventas_cliente
ON ventas(id_cliente);

CREATE INDEX idx_ventas_usuario
ON ventas(id_usuario);


/* ============================================================
   15. TABLA: DETALLE DE VENTAS
   ============================================================ */

CREATE TABLE detalle_ventas (
    id_detalle_venta INT AUTO_INCREMENT PRIMARY KEY,

    id_venta INT NOT NULL,
    id_producto INT NOT NULL,

    cantidad INT NOT NULL,
    precio_unitario DECIMAL(12,2) NOT NULL,

    descuento DECIMAL(12,2) NOT NULL DEFAULT 0,

    subtotal DECIMAL(12,2)
        GENERATED ALWAYS AS
        ((cantidad * precio_unitario) - descuento)
        STORED,

    CONSTRAINT fk_detalle_ventas_venta
        FOREIGN KEY (id_venta)
        REFERENCES ventas(id_venta)
        ON DELETE CASCADE,

    CONSTRAINT fk_detalle_ventas_producto
        FOREIGN KEY (id_producto)
        REFERENCES productos(id_producto),

    CONSTRAINT chk_detalle_ventas_cantidad
        CHECK (cantidad > 0),

    CONSTRAINT chk_detalle_ventas_precio
        CHECK (precio_unitario >= 0),

    CONSTRAINT chk_detalle_ventas_descuento
        CHECK (descuento >= 0)
) ENGINE=InnoDB;

CREATE INDEX idx_detalle_ventas_producto
ON detalle_ventas(id_producto);


/* ============================================================
   16. TABLA: MOVIMIENTOS DE INVENTARIO
   ============================================================ */

CREATE TABLE movimientos_inventario (
    id_movimiento INT AUTO_INCREMENT PRIMARY KEY,

    id_producto INT NOT NULL,
    id_sucursal INT NOT NULL,
    id_tipo_movimiento INT NOT NULL,
    id_usuario INT NOT NULL,

    fecha_movimiento DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,

    cantidad INT NOT NULL,

    stock_anterior INT NOT NULL,
    stock_nuevo INT NOT NULL,

    referencia VARCHAR(100),

    observacion VARCHAR(300),

    CONSTRAINT fk_movimientos_producto
        FOREIGN KEY (id_producto)
        REFERENCES productos(id_producto),

    CONSTRAINT fk_movimientos_sucursal
        FOREIGN KEY (id_sucursal)
        REFERENCES sucursales(id_sucursal),

    CONSTRAINT fk_movimientos_tipo
        FOREIGN KEY (id_tipo_movimiento)
        REFERENCES tipos_movimiento(id_tipo_movimiento),

    CONSTRAINT fk_movimientos_usuario
        FOREIGN KEY (id_usuario)
        REFERENCES usuarios(id_usuario),

    CONSTRAINT chk_movimientos_cantidad
        CHECK (cantidad > 0),

    CONSTRAINT chk_movimientos_stock_anterior
        CHECK (stock_anterior >= 0),

    CONSTRAINT chk_movimientos_stock_nuevo
        CHECK (stock_nuevo >= 0)
) ENGINE=InnoDB;

CREATE INDEX idx_movimientos_producto
ON movimientos_inventario(id_producto);

CREATE INDEX idx_movimientos_fecha
ON movimientos_inventario(fecha_movimiento);


/* ============================================================
   17. TABLA: ALERTAS DE INVENTARIO
   ============================================================ */

CREATE TABLE alertas_inventario (
    id_alerta INT AUTO_INCREMENT PRIMARY KEY,

    id_producto INT NOT NULL,
    id_sucursal INT NOT NULL,

    tipo_alerta ENUM(
        'STOCK_BAJO',
        'PRODUCTO_AGOTADO',
        'SOBRESTOCK'
    ) NOT NULL,

    mensaje VARCHAR(300) NOT NULL,

    fecha_alerta DATETIME
        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    estado ENUM(
        'PENDIENTE',
        'ATENDIDA'
    ) NOT NULL DEFAULT 'PENDIENTE',

    CONSTRAINT fk_alertas_producto
        FOREIGN KEY (id_producto)
        REFERENCES productos(id_producto),

    CONSTRAINT fk_alertas_sucursal
        FOREIGN KEY (id_sucursal)
        REFERENCES sucursales(id_sucursal)
) ENGINE=InnoDB;

CREATE INDEX idx_alertas_estado
ON alertas_inventario(estado);


/* ============================================================
   DATOS INICIALES
   ============================================================ */


/* ROLES */

INSERT INTO roles
(nombre, descripcion)
VALUES
('Administrador', 'Control total del sistema'),
('Vendedor', 'Registro y consulta de ventas'),
('Bodeguero', 'Administración de inventario y movimientos'),
('Supervisor', 'Supervisión de operaciones y reportes');


/* SUCURSALES */

INSERT INTO sucursales
(nombre, direccion, telefono, ciudad)
VALUES
('Sucursal Centro',
 'Carrera 50 # 50-20',
 '6045551001',
 'Medellín'),

('Sucursal Norte',
 'Carrera 65 # 90-10',
 '6045551002',
 'Medellín'),

('Sucursal Sur',
 'Carrera 43A # 10-25',
 '6045551003',
 'Medellín');


/* USUARIOS */

INSERT INTO usuarios
(id_rol, nombre, apellido, correo, password, telefono)
VALUES
(1, 'Carlos', 'Administrador',
 'admin@supermercado.com',
 '123456',
 '3001111111'),

(2, 'Laura', 'Gómez',
 'laura@supermercado.com',
 '123456',
 '3002222222'),

(3, 'Andrés', 'Rodríguez',
 'andres@supermercado.com',
 '123456',
 '3003333333'),

(4, 'María', 'Pérez',
 'maria@supermercado.com',
 '123456',
 '3004444444');


/* CATEGORIAS */

INSERT INTO categorias
(nombre, descripcion)
VALUES
('Abarrotes', 'Productos básicos de alimentación'),
('Bebidas', 'Bebidas gaseosas, agua y jugos'),
('Lácteos', 'Leche, yogur, queso y derivados'),
('Aseo', 'Productos de limpieza'),
('Higiene personal', 'Productos de higiene'),
('Snacks', 'Galletas, dulces y pasabocas'),
('Electrónica', 'Pequeños dispositivos electrónicos');


/* PROVEEDORES */

INSERT INTO proveedores
(nombre_empresa, nit, contacto, telefono, correo, direccion)
VALUES
('Distribuciones Nacionales S.A.S.',
 '900100001-1',
 'Pedro Martínez',
 '3005001001',
 'ventas@distnacionales.com',
 'Medellín'),

('Bebidas Colombia S.A.S.',
 '900100002-2',
 'Juan Torres',
 '3005001002',
 'ventas@bebidascolombia.com',
 'Medellín'),

('Lácteos del Valle S.A.S.',
 '900100003-3',
 'Ana López',
 '3005001003',
 'ventas@lacteosvalle.com',
 'Cali'),

('Productos de Aseo Colombia S.A.S.',
 '900100004-4',
 'Luis Ramírez',
 '3005001004',
 'ventas@aseocolombia.com',
 'Bogotá');


/* CLIENTES */

INSERT INTO clientes
(tipo_documento, numero_documento, nombre, apellido, telefono, correo)
VALUES
('CC', '1001001001',
 'Juan', 'Pérez',
 '3006001001',
 'juan@gmail.com'),

('CC', '1001001002',
 'Ana', 'Gómez',
 '3006001002',
 'ana@gmail.com'),

('CC', '1001001003',
 'Pedro', 'Rodríguez',
 '3006001003',
 'pedro@gmail.com'),

('NIT', '901000100-1',
 'Empresa ABC', 'S.A.S.',
 '3006001004',
 'compras@empresaabc.com');


/* METODOS DE PAGO */

INSERT INTO metodos_pago
(nombre, descripcion)
VALUES
('Efectivo', 'Pago en efectivo'),
('Tarjeta débito', 'Pago mediante tarjeta débito'),
('Tarjeta crédito', 'Pago mediante tarjeta crédito'),
('Transferencia', 'Transferencia bancaria'),
('Nequi', 'Pago mediante Nequi'),
('Daviplata', 'Pago mediante Daviplata');


/* TIPOS DE MOVIMIENTO */

INSERT INTO tipos_movimiento
(nombre, tipo, descripcion)
VALUES
('Compra', 'ENTRADA',
 'Ingreso de productos provenientes de una compra'),

('Venta', 'SALIDA',
 'Salida de productos por venta'),

('Devolución cliente', 'ENTRADA',
 'Producto devuelto por un cliente'),

('Devolución proveedor', 'SALIDA',
 'Producto devuelto al proveedor'),

('Ajuste positivo', 'ENTRADA',
 'Ajuste manual positivo de inventario'),

('Ajuste negativo', 'SALIDA',
 'Ajuste manual negativo de inventario'),

('Producto averiado', 'SALIDA',
 'Salida por producto averiado'),

('Producto vencido', 'SALIDA',
 'Salida por producto vencido');


/* ============================================================
   PRODUCTOS
   ============================================================ */

INSERT INTO productos
(
    id_categoria,
    codigo_barras,
    nombre,
    descripcion,
    marca,
    unidad_medida,
    precio_compra,
    precio_venta,
    stock_minimo,
    stock_maximo
)
VALUES

(1,
 '770000000001',
 'Arroz Blanco 1 Kg',
 'Arroz blanco presentación de 1 kilogramo',
 'Diana',
 'UNIDAD',
 3200,
 4500,
 20,
 200),

(1,
 '770000000002',
 'Azúcar 1 Kg',
 'Azúcar blanca refinada',
 'Incauca',
 'UNIDAD',
 2800,
 3900,
 20,
 150),

(2,
 '770000000003',
 'Coca Cola 1.5 L',
 'Bebida gaseosa',
 'Coca Cola',
 'UNIDAD',
 3500,
 5500,
 15,
 120),

(2,
 '770000000004',
 'Agua 600 ml',
 'Agua embotellada',
 'Cristal',
 'UNIDAD',
 1200,
 2000,
 30,
 300),

(3,
 '770000000005',
 'Leche Entera 1 L',
 'Leche entera larga vida',
 'Alquería',
 'UNIDAD',
 2800,
 4000,
 20,
 150),

(3,
 '770000000006',
 'Yogur Natural',
 'Yogur natural 150 gramos',
 'Alpina',
 'UNIDAD',
 1800,
 2800,
 15,
 100),

(4,
 '770000000007',
 'Detergente 1 Kg',
 'Detergente en polvo',
 'Ariel',
 'UNIDAD',
 6500,
 8500,
 10,
 80),

(4,
 '770000000008',
 'Jabón para loza',
 'Jabón líquido para lavar platos',
 'Axion',
 'UNIDAD',
 4500,
 6500,
 10,
 80),

(5,
 '770000000009',
 'Jabón de baño',
 'Jabón de uso personal',
 'Protex',
 'UNIDAD',
 2500,
 3800,
 15,
 100),

(6,
 '770000000010',
 'Galletas de Chocolate',
 'Paquete de galletas',
 'Festival',
 'UNIDAD',
 1800,
 3000,
 15,
 100),

(6,
 '770000000011',
 'Papas Fritas',
 'Paquete de papas fritas',
 'Margarita',
 'UNIDAD',
 2200,
 3500,
 15,
 100),

(7,
 '770000000012',
 'Cable USB-C',
 'Cable de carga USB-C',
 'Genérico',
 'UNIDAD',
 5000,
 9000,
 5,
 50);


/* ============================================================
   INVENTARIO INICIAL
   ============================================================ */

INSERT INTO inventario
(
    id_producto,
    id_sucursal,
    stock_actual,
    stock_minimo,
    stock_maximo,
    ubicacion
)
SELECT
    id_producto,
    1,
    CASE
        WHEN id_producto = 1 THEN 80
        WHEN id_producto = 2 THEN 60
        WHEN id_producto = 3 THEN 50
        WHEN id_producto = 4 THEN 120
        WHEN id_producto = 5 THEN 70
        WHEN id_producto = 6 THEN 40
        WHEN id_producto = 7 THEN 30
        WHEN id_producto = 8 THEN 35
        WHEN id_producto = 9 THEN 45
        WHEN id_producto = 10 THEN 50
        WHEN id_producto = 11 THEN 40
        WHEN id_producto = 12 THEN 15
    END,
    stock_minimo,
    stock_maximo,
    'Bodega principal'
FROM productos;


/* Inventario para segunda sucursal */

INSERT INTO inventario
(
    id_producto,
    id_sucursal,
    stock_actual,
    stock_minimo,
    stock_maximo,
    ubicacion
)
SELECT
    id_producto,
    2,
    CASE
        WHEN id_producto = 1 THEN 50
        WHEN id_producto = 2 THEN 40
        WHEN id_producto = 3 THEN 35
        WHEN id_producto = 4 THEN 80
        WHEN id_producto = 5 THEN 50
        WHEN id_producto = 6 THEN 30
        WHEN id_producto = 7 THEN 20
        WHEN id_producto = 8 THEN 25
        WHEN id_producto = 9 THEN 30
        WHEN id_producto = 10 THEN 35
        WHEN id_producto = 11 THEN 30
        WHEN id_producto = 12 THEN 10
    END,
    stock_minimo,
    stock_maximo,
    'Bodega secundaria'
FROM productos;


/* ============================================================
   COMPRAS DE PRUEBA
   ============================================================ */

INSERT INTO compras
(
    id_proveedor,
    id_usuario,
    id_sucursal,
    fecha_compra,
    numero_factura,
    subtotal,
    impuesto,
    total,
    estado
)
VALUES
(
    1,
    3,
    1,
    '2026-09-20 08:30:00',
    'FC-10001',
    320000,
    60800,
    380800,
    'RECIBIDA'
),

(
    2,
    3,
    1,
    '2026-09-20 09:00:00',
    'FC-10002',
    175000,
    33250,
    208250,
    'RECIBIDA'
);


/* ============================================================
   DETALLE DE COMPRAS
   ============================================================ */

INSERT INTO detalle_compras
(
    id_compra,
    id_producto,
    cantidad,
    precio_unitario,
    descuento
)
VALUES
(1, 1, 100, 3200, 0),
(1, 2, 50, 2800, 0),
(2, 3, 50, 3500, 0);


/* ============================================================
   VENTAS DE PRUEBA
   ============================================================ */

INSERT INTO ventas
(
    id_cliente,
    id_usuario,
    id_sucursal,
    id_metodo_pago,
    fecha_venta,
    numero_factura,
    subtotal,
    impuesto,
    descuento,
    total,
    estado
)
VALUES
(
    1,
    2,
    1,
    1,
    '2026-09-21 10:30:00',
    'FV-10001',
    9000,
    1710,
    0,
    10710,
    'PAGADA'
),

(
    2,
    2,
    1,
    5,
    '2026-09-21 11:15:00',
    'FV-10002',
    16500,
    3135,
    500,
    19135,
    'PAGADA'
);


/* ============================================================
   DETALLE DE VENTAS
   ============================================================ */

INSERT INTO detalle_ventas
(
    id_venta,
    id_producto,
    cantidad,
    precio_unitario,
    descuento
)
VALUES
(1, 1, 2, 4500, 0),
(2, 3, 3, 5500, 500);


/* ============================================================
   MOVIMIENTOS DE INVENTARIO DE PRUEBA
   ============================================================ */

INSERT INTO movimientos_inventario
(
    id_producto,
    id_sucursal,
    id_tipo_movimiento,
    id_usuario,
    cantidad,
    stock_anterior,
    stock_nuevo,
    referencia,
    observacion
)
VALUES
(1, 1, 1, 3, 100, 80, 180,
 'FC-10001',
 'Entrada por compra'),

(2, 1, 1, 3, 50, 60, 110,
 'FC-10001',
 'Entrada por compra'),

(3, 1, 1, 3, 50, 50, 100,
 'FC-10002',
 'Entrada por compra'),

(1, 1, 2, 2, 2, 180, 178,
 'FV-10001',
 'Salida por venta'),

(3, 1, 2, 2, 3, 100, 97,
 'FV-10002',
 'Salida por venta');


/* ============================================================
   ACTUALIZAR INVENTARIO DESPUÉS DE LOS MOVIMIENTOS DE PRUEBA
   ============================================================ */

UPDATE inventario
SET stock_actual = 178
WHERE id_producto = 1
AND id_sucursal = 1;

UPDATE inventario
SET stock_actual = 110
WHERE id_producto = 2
AND id_sucursal = 1;

UPDATE inventario
SET stock_actual = 97
WHERE id_producto = 3
AND id_sucursal = 1;


/* ============================================================
   ALERTAS DE PRUEBA
   ============================================================ */

INSERT INTO alertas_inventario
(
    id_producto,
    id_sucursal,
    tipo_alerta,
    mensaje
)
SELECT
    i.id_producto,
    i.id_sucursal,

    CASE
        WHEN i.stock_actual = 0
            THEN 'PRODUCTO_AGOTADO'

        WHEN i.stock_actual < i.stock_minimo
            THEN 'STOCK_BAJO'

        WHEN i.stock_actual > i.stock_maximo
            THEN 'SOBRESTOCK'
    END,

    CASE
        WHEN i.stock_actual = 0
            THEN CONCAT(
                'El producto ',
                p.nombre,
                ' se encuentra agotado.'
            )

        WHEN i.stock_actual < i.stock_minimo
            THEN CONCAT(
                'El producto ',
                p.nombre,
                ' tiene stock bajo. Stock actual: ',
                i.stock_actual
            )

        WHEN i.stock_actual > i.stock_maximo
            THEN CONCAT(
                'El producto ',
                p.nombre,
                ' presenta sobrestock.'
            )
    END

FROM inventario i
INNER JOIN productos p
    ON i.id_producto = p.id_producto
WHERE
    i.stock_actual = 0
    OR i.stock_actual < i.stock_minimo
    OR i.stock_actual > i.stock_maximo;


/* ============================================================
   VISTA 1
   INVENTARIO GENERAL
   ============================================================ */

CREATE VIEW vw_inventario_general AS
SELECT

    i.id_inventario,
    p.codigo_barras,
    p.nombre AS producto,
    c.nombre AS categoria,

    s.nombre AS sucursal,

    i.stock_actual,
    i.stock_minimo,
    i.stock_maximo,

    CASE
        WHEN i.stock_actual = 0
            THEN 'AGOTADO'

        WHEN i.stock_actual < i.stock_minimo
            THEN 'STOCK BAJO'

        WHEN i.stock_actual > i.stock_maximo
            THEN 'SOBRESTOCK'

        ELSE 'NORMAL'
    END AS estado_inventario,

    i.ubicacion,
    i.fecha_actualizacion

FROM inventario i

INNER JOIN productos p
    ON i.id_producto = p.id_producto

INNER JOIN categorias c
    ON p.id_categoria = c.id_categoria

INNER JOIN sucursales s
    ON i.id_sucursal = s.id_sucursal;


/* ============================================================
   VISTA 2
   KARDEX / MOVIMIENTOS
   ============================================================ */

CREATE VIEW vw_kardex AS
SELECT

    m.id_movimiento,
    m.fecha_movimiento,

    p.codigo_barras,
    p.nombre AS producto,

    s.nombre AS sucursal,

    tm.nombre AS movimiento,
    tm.tipo,

    m.cantidad,
    m.stock_anterior,
    m.stock_nuevo,

    CONCAT(
        u.nombre,
        ' ',
        u.apellido
    ) AS usuario,

    m.referencia,
    m.observacion

FROM movimientos_inventario m

INNER JOIN productos p
    ON m.id_producto = p.id_producto

INNER JOIN sucursales s
    ON m.id_sucursal = s.id_sucursal

INNER JOIN tipos_movimiento tm
    ON m.id_tipo_movimiento = tm.id_tipo_movimiento

INNER JOIN usuarios u
    ON m.id_usuario = u.id_usuario;


/* ============================================================
   VISTA 3
   VENTAS
   ============================================================ */

CREATE VIEW vw_ventas_detalladas AS
SELECT

    v.id_venta,
    v.numero_factura,
    v.fecha_venta,

    CONCAT(
        c.nombre,
        ' ',
        IFNULL(c.apellido, '')
    ) AS cliente,

    p.nombre AS producto,

    dv.cantidad,
    dv.precio_unitario,
    dv.descuento,
    dv.subtotal,

    mp.nombre AS metodo_pago,

    s.nombre AS sucursal,

    CONCAT(
        u.nombre,
        ' ',
        u.apellido
    ) AS vendedor

FROM ventas v

INNER JOIN clientes c
    ON v.id_cliente = c.id_cliente

INNER JOIN detalle_ventas dv
    ON v.id_venta = dv.id_venta

INNER JOIN productos p
    ON dv.id_producto = p.id_producto

INNER JOIN metodos_pago mp
    ON v.id_metodo_pago = mp.id_metodo_pago

INNER JOIN sucursales s
    ON v.id_sucursal = s.id_sucursal

INNER JOIN usuarios u
    ON v.id_usuario = u.id_usuario;


/* ============================================================
   VISTA 4
   COMPRAS
   ============================================================ */

CREATE VIEW vw_compras_detalladas AS
SELECT

    co.id_compra,
    co.numero_factura,
    co.fecha_compra,

    pr.nombre_empresa AS proveedor,

    p.nombre AS producto,

    dc.cantidad,
    dc.precio_unitario,
    dc.descuento,
    dc.subtotal,

    s.nombre AS sucursal,

    CONCAT(
        u.nombre,
        ' ',
        u.apellido
    ) AS responsable

FROM compras co

INNER JOIN proveedores pr
    ON co.id_proveedor = pr.id_proveedor

INNER JOIN detalle_compras dc
    ON co.id_compra = dc.id_compra

INNER JOIN productos p
    ON dc.id_producto = p.id_producto

INNER JOIN sucursales s
    ON co.id_sucursal = s.id_sucursal

INNER JOIN usuarios u
    ON co.id_usuario = u.id_usuario;


/* ============================================================
   CONSULTAS DE PRUEBA
   ============================================================ */


/* 1. Ver todos los productos */

SELECT *
FROM productos;


/* 2. Ver inventario */

SELECT *
FROM vw_inventario_general;


/* 3. Productos con stock bajo */

SELECT *
FROM vw_inventario_general
WHERE estado_inventario = 'STOCK BAJO';


/* 4. Productos agotados */

SELECT *
FROM vw_inventario_general
WHERE estado_inventario = 'AGOTADO';


/* 5. Productos con sobrestock */

SELECT *
FROM vw_inventario_general
WHERE estado_inventario = 'SOBRESTOCK';


/* 6. Inventario de una sucursal */

SELECT *
FROM vw_inventario_general
WHERE sucursal = 'Sucursal Centro';


/* 7. Kardex */

SELECT *
FROM vw_kardex
ORDER BY fecha_movimiento;


/* 8. Historial de un producto */

SELECT *
FROM vw_kardex
WHERE producto = 'Arroz Blanco 1 Kg'
ORDER BY fecha_movimiento;


/* 9. Ventas */

SELECT *
FROM vw_ventas_detalladas
ORDER BY fecha_venta;


/* 10. Compras */

SELECT *
FROM vw_compras_detalladas
ORDER BY fecha_compra;


/* 11. Total vendido */

SELECT
    SUM(total) AS total_ventas
FROM ventas
WHERE estado = 'PAGADA';


/* 12. Ventas por usuario */

SELECT

    CONCAT(
        u.nombre,
        ' ',
        u.apellido
    ) AS vendedor,

    COUNT(v.id_venta) AS cantidad_ventas,

    SUM(v.total) AS total_vendido

FROM ventas v

INNER JOIN usuarios u
    ON v.id_usuario = u.id_usuario

WHERE v.estado = 'PAGADA'

GROUP BY
    u.id_usuario,
    u.nombre,
    u.apellido;


/* 13. Productos más vendidos */

SELECT

    p.nombre AS producto,

    SUM(dv.cantidad) AS unidades_vendidas,

    SUM(dv.subtotal) AS ingresos

FROM detalle_ventas dv

INNER JOIN productos p
    ON dv.id_producto = p.id_producto

INNER JOIN ventas v
    ON dv.id_venta = v.id_venta

WHERE v.estado = 'PAGADA'

GROUP BY
    p.id_producto,
    p.nombre

ORDER BY unidades_vendidas DESC;


/* 14. Ventas por método de pago */

SELECT

    mp.nombre AS metodo_pago,

    COUNT(v.id_venta) AS cantidad_ventas,

    SUM(v.total) AS total

FROM ventas v

INNER JOIN metodos_pago mp
    ON v.id_metodo_pago = mp.id_metodo_pago

WHERE v.estado = 'PAGADA'

GROUP BY
    mp.id_metodo_pago,
    mp.nombre

ORDER BY total DESC;


/* 15. Compras por proveedor */

SELECT

    pr.nombre_empresa AS proveedor,

    COUNT(c.id_compra) AS cantidad_compras,

    SUM(c.total) AS total_comprado

FROM compras c

INNER JOIN proveedores pr
    ON c.id_proveedor = pr.id_proveedor

WHERE c.estado <> 'ANULADA'

GROUP BY
    pr.id_proveedor,
    pr.nombre_empresa

ORDER BY total_comprado DESC;


/* 16. Valor del inventario */

SELECT

    s.nombre AS sucursal,

    SUM(
        i.stock_actual * p.precio_compra
    ) AS valor_inventario_compra,

    SUM(
        i.stock_actual * p.precio_venta
    ) AS valor_inventario_venta

FROM inventario i

INNER JOIN productos p
    ON i.id_producto = p.id_producto

INNER JOIN sucursales s
    ON i.id_sucursal = s.id_sucursal

GROUP BY
    s.id_sucursal,
    s.nombre;


/* 17. Utilidad estimada por producto */

SELECT

    p.nombre AS producto,

    p.precio_compra,
    p.precio_venta,

    (p.precio_venta - p.precio_compra)
        AS utilidad_unitaria,

    ROUND(
        (
            (p.precio_venta - p.precio_compra)
            / NULLIF(p.precio_compra,0)
        ) * 100,
        2
    ) AS margen_porcentaje

FROM productos p

ORDER BY utilidad_unitaria DESC;


/* 18. Alertas */

SELECT *

FROM alertas_inventario

WHERE estado = 'PENDIENTE'

ORDER BY fecha_alerta DESC;


/* 19. Cantidad de productos por categoría */

SELECT

    c.nombre AS categoria,

    COUNT(p.id_producto) AS cantidad_productos

FROM categorias c

LEFT JOIN productos p
    ON c.id_categoria = p.id_categoria

GROUP BY
    c.id_categoria,
    c.nombre

ORDER BY cantidad_productos DESC;


/* 20. Resumen general del sistema */

SELECT

    (SELECT COUNT(*)
     FROM productos
     WHERE estado = 1)
     AS productos_activos,

    (SELECT COUNT(*)
     FROM clientes
     WHERE estado = 1)
     AS clientes_activos,

    (SELECT COUNT(*)
     FROM proveedores
     WHERE estado = 1)
     AS proveedores_activos,

    (SELECT COUNT(*)
     FROM ventas
     WHERE estado = 'PAGADA')
     AS ventas_realizadas,

    (SELECT COUNT(*)
     FROM compras
     WHERE estado <> 'ANULADA')
     AS compras_realizadas;
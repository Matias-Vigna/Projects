
-- Creacion de esquema - MeLi
/*
    1- Creo todas las tablas con PK e indices 
    2- Agrego FK referenciales en entidades
    3- Creo Triggers Fecha Alta, Ult Mod todas entidades
    4- Creo Seq en ITEMS_HIST y trigger para que genere el ID inclemental
    5- Trigger en ITEMS que carga ITEMS_HIST - Automaticamente con cada insert o udpate en Items
  
*/


-- 1- Creo todas las tablas con PK e indices 

--------------------------------------------
-- CUSTOMER

CREATE TABLE customer (
  cus_id number NOT NULL PRIMARY KEY, -- PK
  cus_email varchar2(50) NOT NULL,
  cus_nombre varchar2(50),
  cus_apellido varchar2(50),
  cus_sexo varchar2(1),
  cus_direccion varchar2(100),
  cus_f_nac Date,
  cus_telefono number,
  cus_fecha_alta Date,
  cus_fecha_ult_mod Date,
  cus_fecha_baja Date
  );

-- Indices (email)
CREATE INDEX idx_cus_email ON customer (cus_email);


--------------------------------------------
-- ITEM

CREATE TABLE Item (
  it_id number NOT NULL PRIMARY KEY, -- PK
  it_cus_id number NOT NULL, -- FK
  it_cat_id number NOT NULL, -- FK
  it_descripcion Clob,
  it_precio number (8,2),
  it_estado varchar2(25),
  it_estado_fecha_baja Date,
  it_fecha_alta Date,
  it_fecha_ult_mod Date,
  it_fecha_baja Date
  );

-- Indice (id customer)
CREATE INDEX idx_it_cus_id ON Item (it_cus_id);


--------------------------------------------
-- CATEGORY

CREATE TABLE CATEGORY (
  cat_id number NOT NULL PRIMARY KEY, -- PK
  cat_descripcion varchar2(100),
  cat_path varchar2(100),
  cat_fecha_alta Date,
  cat_fecha_ult_mod Date,
  cat_fecha_baja Date
  );

-- Indice por el path
CREATE INDEX idx_cat_path ON CATEGORY (cat_path);


--------------------------------------------
-- ORDERS

CREATE TABLE orders (
  or_id number NOT NULL PRIMARY KEY, -- PK
  or_it_id number NOT NULL, -- FK vendedor
  or_it_cus_id number NOT NULL,
  or_it_cat_id number NOT NULL,
  or_fecha_transac Date,
  or_it_precio number(8,2),
  or_estado varchar2(25),
  or_fp_id number NOT NULL, -- FK 
  or_cus_id number NOT NULL, -- FK comprador
  or_fecha_alta Date,
  or_fecha_ult_mod Date,
  or_fecha_baja Date
  );

-- Indices (Id item | Id cus vendedor | Id cus comprador)
CREATE INDEX idx_or_it_id ON orders (or_it_id); 
CREATE INDEX idx_or_it_cus_id ON orders (or_it_cus_id);
CREATE INDEX idx_or_cus_id ON orders (or_cus_id);


--------------------------------------------
-- FORMAS_PAGO

CREATE TABLE formas_pago(
  fp_id number NOT NULL PRIMARY KEY, -- PK
  fp_descripcion varchar2(100),
  fp_vigencia_desde Date,
  fp_vigencia_hasta Date,
  fp_fecha_alta Date,
  fp_fecha_ult_mod Date,
  fp_fecha_baja Date
  );


--------------------------------------------
-- ITEM_HIST

CREATE TABLE item_hist (
  ith_id number NOT NULL PRIMARY KEY, -- PK
  ith_it_id number NOT NULL, -- FK
  ith_precio number(8,2),
  ith_estado varchar2(25),
  ith_novedad varchar2(25),
  ith_observacion varchar2(100),
  ith_fecha_alta Date,
  ith_fecha_ult_mod Date,
  ith_fecha_baja Date
  );

-- Indice (id item)
CREATE INDEX idx_ith_it ON item_hist (ith_it_id);


--------------------------------------------
-- MOV_DIARIOS

CREATE TABLE mov_diarios (
  md_id number NOT NULL PRIMARY KEY, -- PK
  md_it_id number NOT NULL, -- FK
  md_ith_id number NOT NULL, -- FK
  md_it_precio number(8,2),
  md_it_estado varchar2(25),
  md_fecha_alta Date,
  md_fecha_ult_mod Date,
  md_fecha_baja Date
  );

-- Indices (id item | id item hist)
CREATE INDEX idx_md_it ON mov_diarios (md_it_id);
CREATE INDEX idx_md_ith ON mov_diarios (md_ith_id);

--------------------------------------------



--------------------------------------------
-- 2- Agrego FK referenciales en tablas


-- Item
ALTER TABLE Item ADD CONSTRAINT fk_it_cus FOREIGN KEY (it_cus_id) REFERENCES customer (cus_id);
ALTER TABLE Item ADD CONSTRAINT fk_it_cat FOREIGN KEY (it_cat_id) REFERENCES CATEGORY (cat_id);

-- Orders
ALTER TABLE orders ADD CONSTRAINT fk_or_fp FOREIGN KEY (or_fp_id) REFERENCES formas_pago (fp_id);
ALTER TABLE orders ADD CONSTRAINT fk_or_it_cus FOREIGN KEY (or_it_cus_id) REFERENCES customer (cus_id);
ALTER TABLE orders ADD CONSTRAINT fk_or_cus FOREIGN KEY (or_cus_id) REFERENCES customer (cus_id);
ALTER TABLE orders ADD CONSTRAINT fk_or_it FOREIGN KEY (or_it_id) REFERENCES Item (it_id);

-- Mov_Diarios
ALTER TABLE mov_diarios ADD CONSTRAINT fk_md_it FOREIGN KEY (md_it_id) REFERENCES Item (it_id);
ALTER TABLE mov_diarios ADD CONSTRAINT fk_md_ith FOREIGN KEY (md_ith_id) REFERENCES item_hist (ith_id);

-- Item_Hist
ALTER TABLE item_hist ADD CONSTRAINT fk_ith_it FOREIGN KEY (ith_it_id) REFERENCES Item (it_id);




--------------------------------------------
-- 3- Creo Triggers Fecha Alta, Ult Mod 

-- Pone la fecha de alta si se insertan datos 
-- Pone la fecha de ult mod en caso de udpate

-- Customer
CREATE OR REPLACE TRIGGER tgg_audit_cus
   BEFORE INSERT OR UPDATE ON customer FOR EACH ROW
DECLARE
   V_FECHA  DATE := sysdate;
BEGIN
   IF INSERTING THEN
      IF :NEW.cus_fecha_alta IS NULL THEN
         :NEW.cus_fecha_alta := V_FECHA;
      END IF;
   ELSIF UPDATING THEN
      IF :NEW.cus_fecha_ult_mod IS NULL THEN
         :NEW.cus_fecha_ult_mod := V_FECHA;
      END IF;

   END IF;
END;

-- Item
CREATE OR REPLACE TRIGGER tgg_audit_it
   BEFORE INSERT OR UPDATE ON item FOR EACH ROW
DECLARE
   V_FECHA  DATE := sysdate;
BEGIN
   IF INSERTING THEN
      IF :NEW.it_fecha_alta IS NULL THEN
         :NEW.it_fecha_alta := V_FECHA;
      END IF;
   ELSIF UPDATING THEN
      IF :NEW.it_fecha_ult_mod IS NULL THEN
         :NEW.it_fecha_ult_mod := V_FECHA;
      END IF;

   END IF;
END;

-- Category
CREATE OR REPLACE TRIGGER tgg_audit_cat
   BEFORE INSERT OR UPDATE ON CATEGORY FOR EACH ROW
DECLARE
   V_FECHA  DATE := sysdate;
BEGIN
   IF INSERTING THEN
      IF :NEW.cat_fecha_alta IS NULL THEN
         :NEW.cat_fecha_alta := V_FECHA;
      END IF;
   ELSIF UPDATING THEN
      IF :NEW.cat_fecha_ult_mod IS NULL THEN
         :NEW.cat_fecha_ult_mod := V_FECHA;
      END IF;

   END IF;
END;

-- Order
CREATE OR REPLACE TRIGGER tgg_audit_or
   BEFORE INSERT OR UPDATE ON orders FOR EACH ROW
DECLARE
   V_FECHA  DATE := sysdate;
BEGIN
   IF INSERTING THEN
      IF :NEW.or_fecha_alta IS NULL THEN
         :NEW.or_fecha_alta := V_FECHA;
      END IF;
   ELSIF UPDATING THEN
      IF :NEW.or_fecha_ult_mod IS NULL THEN
         :NEW.or_fecha_ult_mod := V_FECHA;
      END IF;

   END IF;
END;

-- Formas_pago
CREATE OR REPLACE TRIGGER tgg_audit_fp
   BEFORE INSERT OR UPDATE ON formas_pago FOR EACH ROW
DECLARE
   V_FECHA  DATE := sysdate;
BEGIN
   IF INSERTING THEN
      IF :NEW.fp_fecha_alta IS NULL THEN
         :NEW.fp_fecha_alta := V_FECHA;
      END IF;
   ELSIF UPDATING THEN
      IF :NEW.fp_fecha_ult_mod IS NULL THEN
         :NEW.fp_fecha_ult_mod := V_FECHA;
      END IF;

   END IF;
END;

-- Item_hist
CREATE OR REPLACE TRIGGER tgg_audit_ith
   BEFORE INSERT OR UPDATE ON Item_hist FOR EACH ROW
DECLARE
   V_FECHA  DATE := sysdate;
BEGIN
   IF INSERTING THEN
      IF :NEW.ith_fecha_alta IS NULL THEN
         :NEW.ith_fecha_alta := V_FECHA;
      END IF;
   ELSIF UPDATING THEN
      IF :NEW.ith_fecha_ult_mod IS NULL THEN
         :NEW.ith_fecha_ult_mod := V_FECHA;
      END IF;

   END IF;
END;

-- Mov_diarios
CREATE OR REPLACE TRIGGER tgg_audit_md
   BEFORE INSERT OR UPDATE ON mov_diarios FOR EACH ROW
DECLARE
   V_FECHA  DATE := sysdate;
BEGIN
   IF INSERTING THEN
      IF :NEW.md_fecha_alta IS NULL THEN
         :NEW.md_fecha_alta := V_FECHA;
      END IF;
   ELSIF UPDATING THEN
      IF :NEW.md_fecha_ult_mod IS NULL THEN
         :NEW.md_fecha_ult_mod := V_FECHA;
      END IF;

   END IF;
END;

ALTER TRIGGER tgg_audit_cus ENABLE;
ALTER TRIGGER tgg_audit_it ENABLE;
ALTER TRIGGER tgg_audit_cat ENABLE;
ALTER TRIGGER tgg_audit_or ENABLE;
ALTER TRIGGER tgg_audit_fp ENABLE;
ALTER TRIGGER tgg_audit_ith ENABLE;
ALTER TRIGGER tgg_audit_md ENABLE;




--------------------------------------------
-- 4- Creo Seq para ID en ITEMS_HIST y MOV_DIARIOS

-- Sequence incremental en 1
CREATE SEQUENCE seq_ith_id
  START WITH 1
  MAXVALUE 9999999999999999999999999999
  MINVALUE 1
  INCREMENT BY 1
  NOCYCLE
  CACHE 20
  NOORDER;

CREATE SEQUENCE seq_mov_id
  START WITH 1
  MAXVALUE 9999999999999999999999999999
  MINVALUE 1
  INCREMENT BY 1
  NOCYCLE
  CACHE 20
  NOORDER;

-- Trigger - Lo inserto con el trigger de items pto 5
/*
CREATE OR REPLACE TRIGGER tgg_ith_id
BEFORE INSERT ON ITEMS_HIST
FOR EACH ROW
BEGIN
    :new.ith_id := seq_ith_id.NEXTVAL;
END;

ALTER TRIGGER seq_ith_id ENABLE; */


--------------------------------------------
-- 5- Trigger en ITEMS que carga ITEMS_HIST - Automaticamente con cada insert o udpate en Items

-- Item
CREATE OR REPLACE TRIGGER tgg_it_ith
   BEFORE INSERT OR UPDATE ON Item FOR EACH ROW
DECLARE
   v_ith_id number:= seq_ith_id.NEXTVAL;
BEGIN

    INSERT INTO 
            item_hist (ith_id,
                       ith_it_id,
                       ith_precio,
                       ith_estado,
                       ith_novedad)
    VALUES (v_ith_id, -- Id con secuencia
            :NEW.it_id, -- Id de item
            :NEW.it_precio, -- Act precio
            :NEW.it_estado, -- Act estado
            NULL -- Novedad Nula Se marca en proceso de respuesta 3
            );
END;



------------------------------------------------------- FIN


-- Bajar todo el esquema
/* 
drop table customer CASCADE CONSTRAINTS purge;

drop table item CASCADE CONSTRAINTS purge;

drop table category CASCADE CONSTRAINTS purge;

drop table orders CASCADE CONSTRAINTS purge;

drop table formas_pago CASCADE CONSTRAINTS purge;

drop table item_hist CASCADE CONSTRAINTS purge;

drop table mov_diarios CASCADE CONSTRAINTS purge;

DROP SEQUENCE seq_ith_id;

DROP SEQUENCE seq_mov_id;
*/

-- A Resolver...

/*
    1 - Listar los usuarios que cumplan años el día de hoy cuya cantidad de ventas
    realizadas en enero 2020 sea superior a 1500.


    2 - Por cada mes del 2020, se solicita el top 5 de usuarios que más vendieron($) en la
    categoría Celulares. Se requiere el mes y año de análisis, nombre y apellido del
    vendedor, cantidad de ventas realizadas, cantidad de productos vendidos y el monto
    total transaccionado.
    
    3 - Se solicita poblar una nueva tabla con el precio y estado de los Ítems a fin del día.
    Tener en cuenta que debe ser reprocesable. Vale resaltar que en la tabla Item,
    vamos a tener únicamente el último estado informado por la PK definida. (Se puede
    resolver a través de StoredProcedure)
*/


---------
-- 1 - Listar los usuarios que cumplan años el día de hoy cuya cantidad de ventas realizadas en enero 2020 sea superior a 1500.


Select  -- Datos de Customer
        cus_id, cus_nombre, cus_apellido, cus_email, cus_telefono, 
        -- Count y Suma
        count(distinct or_id) As Cant_order, -- Cuento las distintas ordenes
        sum(or_it_precio) as Suma_ventas -- Agrego suma de todas las ventas realizadas
from    customer c,
        orders o
where   c.cus_fecha_baja is null
and     trunc(c.cus_f_nac) = sysdate -- Fecha de Nac = hoy
and     o.or_it_cus_id = c.cus_id -- Join con customer vendedor
and     o.or_fecha_baja is null
and     extract (month from o.or_fecha_transac)||'/'||extract(year from o.or_fecha_transac) = '1/2020' -- Extraigo mes/año de decha transaccion y filtro
and     o.or_estado = 'OK' -- Transaccion realizada
--
group by cus_id, cus_nombre, cus_apellido, cus_email, cus_telefono
having count(distinct or_id) >= 1500
;


---------
-- 2 - Por cada mes del 2020, se solicita el top 5 de usuarios que más vendieron($) en la categoría Celulares. Se requiere el mes y año de análisis, nombre y apellido del
--      vendedor, cantidad de ventas realizadas, cantidad de productos vendidos y el monto total transaccionado.

-- Observacion...
--  Lo trate de reolver en tres sub consultas donde se van agrupando los datos:
--  la primera es la general con los agrupamientos necesarios.
--  La segunda hace el rownum ordenado por el monto mensual del customer
--  La tercera acota que solo traiga el top 5


Select /*Consulta con el top 5*/ 
        *
from    (/*Segunta consulta con RN orden por saldo mensual*/
            Select  anio, mes, 
                    row_number() OVER (PARTITION BY cus_id ORDER BY monto_mensual desc) rn, --Orden por saldo mensual
                    nombre, apellido, q_ventas, q_productos, monto_mensual
            from    (/*Primera consulta con agrupamientos*/
                        Select  extract(year from o.or_fecha_transac) anio,
                                extract (month from o.or_fecha_transac) mes,
                                -- Datos del usuario
                                cus_id, cus_nombre as nombre, cus_apellido as apellido,
                                -- Agrupamientos
                                count(*) OVER (PARTITION BY cus_id, extract (month from o.or_fecha_transac)) q_ventas, -- Cantidad de ventas por mes
                                count(distinct or_it_id) OVER (PARTITION BY cus_id, extract (month from o.or_fecha_transac)) q_productos, -- Cantidad de productos distintos por mes
                                sum(or_it_precio) OVER (PARTITION BY cus_id, extract (month from o.or_fecha_transac)) Monto_mensual -- suma de monto transaccionado por mes
                        --
                        from    orders o,
                                customer c
                        --
                        where   o.or_fecha_baja is null
                        and     o.or_estado = 'OK' -- Transaccion realizada
                        and     extract(year from o.or_fecha_transac) = '2020' -- Año Transac
                        -- Valido que el item de order sea de Celulares
                        and     exists (Select  1
                                        from    item i, category c
                                        where   i.it_id = o.or_it_id -- Join c/orders
                                        and     c.cat_id = i.it_cat_id
                                        and     i.it_fecha_baja is null and c.cat_fecha_baja is null
                                        and     c.cat_path = 'Celulares')
                        and     o.or_it_cus_id = c.cus_id and c.cus_fecha_baja is null -- Join customer activo
                    )
            )
where   RN <= 5 -- Acoto a que traiga top 5 Sujetos por mes
order by anio, mes, rn desc;


---------
-- 3 - Se solicita poblar una nueva tabla con el precio y estado de los Ítems a fin del día. 
--     Tener en cuenta que debe ser reprocesable. Vale resaltar que en la tabla Item, vamos a tener únicamente el último estado informado por la PK definida. 
--    (Se puede resolver a través de StoredProcedure)


-- Observacion...
/*
    El proceso levanta los casos a insertar como ultimo movimiento diario acotando segun fecha que se pasa como parametro.
    Se valida que las novedades no hayan sido marcadas
    Si el insert no da error actualiza la tabla del cursor como OK Movimiento enviado.
    Se se corta se puede relanzar ya que continua con los casos que falten.    
*/

CREATE OR replace PROCEDURE prc_carga_mov (p_fecha date DEFAULT trunc(sysdate)) IS

-- Array para insert mov_diarios
    TYPE REC_MOV IS RECORD (r_mr_id number,
                           r_mr_it_id number,
                           r_mr_ith_id number,
                           r_md_it_precio number(8,2), 
                           r_md_it_estado varchar2(25),
                           r_f_alta date,
                           r_f_mod date,
                           r_f_baja date);
    TYPE T_MOV  IS TABLE OF REC_MOV;
    V_MOV T_MOV;
    
-- Busca en cursor el ultimo movimiento en item_hist para la fecha que se pasa como parametro
CURSOR Cur IS
    SELECT  seq_mov_id.NEXTVAL mr_id, -- Seq de mov_diarios
            ith_it_id,
            ith_id,
            ith_precio,
            ith_estado,
            ith_fecha_alta,
            ith_fecha_ult_mod,
            ith_fecha_baja
    FROM    item_hist h
    WHERE   h.ith_fecha_baja IS NULL
    AND     trunc(h.ith_fecha_alta) = p_fecha -- Fecha solicitada
    -- Traer el ultimo mov del dia para la fecha
    AND     h.ith_id = (SELECT max(hh.ith_id) --mayor Id (ult mov)
                        FROM    item_hist hh
                        WHERE   hh.ith_fecha_baja IS NULL
                        AND     trunc(hh.ith_fecha_alta) = trunc(h.ith_fecha_alta)
                        AND     hh.ith_it_id = h.ith_it_id)
    AND     ith_novedad IS NULL -- Novedades no enviadas
    -- Que no exista una novedad enviada
    and     not exists (Select  1
                        from    item_hist ih
                        WHERE   ih.ith_fecha_baja IS NULL
                        AND     trunc(ih.ith_fecha_alta) = trunc(h.ith_fecha_alta)
                        AND     ih.ith_it_id = h.ith_it_id
                        and     ith_novedad = 'OK')
    ;

-- Variable de error
v_err number;

BEGIN
OPEN Cur;
    LOOP
    v_err:= 0;

    FETCH Cur BULK COLLECT
    INTO V_MOV LIMIT 5000;

        BEGIN
            FORALL I IN 1 .. V_MOV.COUNT SAVE EXCEPTIONS
        -- Inserto todos los casos en MOV_DIARIOS
                INSERT INTO MOV_DIARIOS
                VALUES V_MOV(I);
                
                COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                v_err := 1; -- Marco error
                ROLLBACK;
        END;
        
        IF v_err = 0 THEN
        
            BEGIN
                FORALL I IN 1 .. V_MOV.COUNT 

                    UPDATE item_hist set
                        ith_novedad = 'OK',
                        ith_observacion = 'Novedad enviada'
                    WHERE ith_id = v_mov(I).r_mr_ith_id
                    AND     ith_it_id = v_mov(I).r_mr_it_id
                    and     trunc(ith_fecha_alta) = v_mov(I).r_f_alta;
                    
                COMMIT;
            END;

        END IF;
    EXIT WHEN Cur%NOTFOUND;
    COMMIT;
    END LOOP;
CLOSE Cur;
END;
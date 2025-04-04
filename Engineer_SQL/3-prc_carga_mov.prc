
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
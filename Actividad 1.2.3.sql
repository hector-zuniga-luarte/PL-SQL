/*
 *	MDY3131_005V - Programación de Base de Datos
 *	
 *  Héctor Zúñiga Luarte    - hec.zuniga@duocuc.cl
 *	
 *	Actividad 1.2.3 - Realizando los primeros procesos PL/SQL simples
 *
 */

/* Instrucción para ver la salida por pantalla */
set serveroutput on;

/*
 *   Inicio caso 1
 *
 *  RUT's de prueba:
 *
 *      11846972
 *      12272880
 *      12113369
 *      11999100
 *      12868553
 */

declare

    ve_ano_proceso number(4);
    ve_rut_empleado number(10);
    ve_cod_comuna01 number(3);
    ve_cod_comuna02 number(3);
    ve_cod_comuna03 number(3);
    ve_cod_comuna04 number(3);
    ve_cod_comuna05 number(3);
    ve_valor_comuna01 number(6);
    ve_valor_comuna02 number(6);
    ve_valor_comuna03 number(6);
    ve_valor_comuna04 number(6);
    ve_valor_comuna05 number(6);
    
    vl_anoproceso number(4);
    vl_numrut number(10);
    vl_digverif varchar(1);
    vl_nombreempleado varchar(100);
    vl_sueldobase number(10);
    vl_porcnormal number(3);
    vl_valormovilnormal number(10);
    vl_valormoviladic number(10);
    vl_valortotalmovil number(10);
    
begin

    begin
        select :ve_ano_proceso as ano_proceso,
            e.numrun_emp as rut_empleado,
            e.dvrun_emp as dig_verif,
            e.pnombre_emp || ' ' || e.snombre_emp || ' ' || e.appaterno_emp || ' ' || e.apmaterno_emp as nombre_empleado,
            sueldo_base as sueldo_base,
            trunc(sueldo_base / 100000, 0) as porc_movil_normal,
            round((sueldo_base * trunc(sueldo_base / 100000, 0)) / 100, 0) as valor_movil_normal,
            case
                when e.id_comuna = :ve_cod_comuna01 
                then :ve_valor_comuna01
                
                when e.id_comuna = :ve_cod_comuna02
                then :ve_valor_comuna02
                
                when e.id_comuna = :ve_cod_comuna03
                then :ve_valor_comuna03
                
                when e.id_comuna = :ve_cod_comuna04
                then :ve_valor_comuna04
                
                when e.id_comuna = :ve_cod_comuna05
                then :ve_valor_comuna05
            else
                0
            end as valor_movil_adic,
            case
                when e.id_comuna = :ve_cod_comuna01
                then round((sueldo_base * trunc(sueldo_base / 100000, 0)) / 100, 0) + :ve_valor_comuna01

                when e.id_comuna = :ve_cod_comuna02
                then round((sueldo_base * trunc(sueldo_base / 100000, 0)) / 100, 0) + :ve_valor_comuna02

                when e.id_comuna = :ve_cod_comuna03
                then round((sueldo_base * trunc(sueldo_base / 100000, 0)) / 100, 0) + :ve_valor_comuna03

                when e.id_comuna = :ve_cod_comuna04
                then round((sueldo_base * trunc(sueldo_base / 100000, 0)) / 100, 0) + :ve_valor_comuna04

                when e.id_comuna = :ve_cod_comuna05
                then round((sueldo_base * trunc(sueldo_base / 100000, 0)) / 100, 0) + :ve_valor_comuna05
            else
                round((sueldo_base * trunc(sueldo_base / 100000, 0)) / 100, 0)
            end as valor_total_movil
        into vl_anoproceso,
            vl_numrut,
            vl_digverif,
            vl_nombreempleado,
            vl_sueldobase,
            vl_porcnormal,
            vl_valormovilnormal,
            vl_valormoviladic,
            vl_valortotalmovil
        from empleado e
        where e.numrun_emp = :ve_rut_empleado;
    exception
        when no_data_found then
            dbms_output.put_line('El empleado de RUT ' || :ve_rut_empleado || ' no existe en el sistema. Verifique el RUT y reintente.');
            return;
        when others then
            dbms_output.put_line('Se ha producido un error en la base de datos' || chr(10) || sqlerrm);
            return;
    end;

    /* Primero eliminamos el registro para el año y el rut de manera de evitar errores por primary key */
    begin
        delete proy_movilizacion
        where anno_proceso = :ve_ano_proceso and
            numrun_emp = :ve_rut_empleado; 
    exception
        when others then
            rollback;
            dbms_output.put_line('Se ha producido un error en la eliminación del registro en la tabla proy_movilizacion' || chr(10) || sqlerrm);
            return;
    end;


    /* Insertamos el dato en la tabla proy_movilizacion */
    begin
    
        insert into proy_movilizacion 
            (anno_proceso,
             numrun_emp,
             dvrun_emp,
             nombre_empleado,
             sueldo_base,
             porc_movil_normal,
             valor_movil_normal,
             valor_movil_extra,
             valor_total_movil)
        values
            (vl_anoproceso,
            vl_numrut,
            vl_digverif,
            vl_nombreempleado,
            vl_sueldobase,
            vl_porcnormal,
            vl_valormovilnormal,
            vl_valormoviladic,
            vl_valortotalmovil);
    exception
        when others then
            rollback;
            dbms_output.put_line('Se ha producido un error en la inserción a la tabla proy_movilizacion' || chr(10) || sqlerrm);
            return;
    end;

    commit;
    
    dbms_output.put_line('Se ha ingresado el registro correctamente en la tabla PROY_MOVILIZACION.');
    
end;

/*
 *  Fin caso 1
 *
 */

/*
 *   Inicio caso 2
 *
 *  RUT's de prueba:
 *
 *      12648200
 *      12260812
 *      12456905
 *      11649964
 *      12642309
 */


declare

    ve_rut_empleado number(10);

    vs_mesano number(6);
    vs_rutempleado number(10);
    vs_digverif varchar2(1);
    vs_nombreempleado varchar2(100);
    vs_usuario varchar2(20);
    vs_clave varchar2(20);

begin

    begin
        select to_char(sysdate, 'mmyyyy') as mes_ano,
                e.numrun_emp as rut_empleado,
                e.dvrun_emp as dig_verif,
                e.pnombre_emp || ' ' || e.snombre_emp || ' ' || appaterno_emp || ' ' || apmaterno_emp as nombre_empleado,
                substr(e.pnombre_emp, 1, 3) || 

                    to_char(length(e.pnombre_emp)) ||

                    '*' ||

                    substr(to_char(sueldo_base), length(to_char(sueldo_base)), 1) ||

                    e.dvrun_emp ||

                    to_char(floor(months_between(sysdate, e.fecha_contrato) / 12)) ||

                    case when floor(months_between(sysdate, e.fecha_contrato) / 12) < 10
                        then 'X'
                    else
                        ''
                    end
                as usuario,
                
                substr(e.numrun_emp, 3, 1) ||
                    to_char(to_number(to_char(e.fecha_nac, 'yyyy')) + 2) ||
                    substr(to_char(e.sueldo_base - 1), length(to_char(e.sueldo_base - 1)) - 2, 3) ||
                    case 
                    
                        /* Casado o Acuerdo de unión civil, las dos primeras letras */
                        when e.id_estado_civil in (10, 60) 
                        then lower(substr(e.appaterno_emp, 1, 2))
                    
                        /* Divorciado o soltero, la primera y la última letra */
                        when e.id_estado_civil in (20, 30) 
                        then lower(substr(e.appaterno_emp, 1, 1) || substr(e.appaterno_emp, length(e.appaterno_emp), 1))
                    
                        /* Viudo, la antepenúltima y penúltima letra */
                        when e.id_estado_civil = 40 
                        then lower(substr(e.appaterno_emp, length(e.appaterno_emp) - 2, 2))
                    
                        /* Separado, las dos últimas letras */
                        when e.id_estado_civil = 50 
                        then lower(substr(e.appaterno_emp, length(e.appaterno_emp) - 1, 2))
                    
                    else
                        ' - error'
                    end  ||
                        
                    to_char(sysdate, 'mmyyyy') ||
                        
                    substr(trim(c.nombre_comuna), 1, 1)
                as clave
        into 
            vs_mesano,
            vs_rutempleado,
            vs_digverif,
            vs_nombreempleado,
            vs_usuario,
            vs_clave
        from empleado e
        inner join comuna c on e.id_comuna = c.id_comuna
        where e.numrun_emp = :ve_rut_empleado;
    exception
        when no_data_found then
            dbms_output.put_line('El empleado de RUT ' || :ve_rut_empleado || ' no existe en el sistema. Verifique el RUT y reintente.');
            return;
        when others then
            dbms_output.put_line('Se ha producido un error en la base de datos' || chr(10) || sqlerrm);
            return;
    end;


    /* Primero eliminamos el registro para el mes-año y el rut de manera de evitar errores por primary key */
    begin
        delete usuario_clave
        where mes_anno = to_char(sysdate, 'mmyyyy') and
            numrun_emp = :ve_rut_empleado; 
    exception
        when others then
            rollback;
            dbms_output.put_line('Se ha producido un error en la eliminación del registro en la tabla usuario_clave' || chr(10) || sqlerrm);
            return;
    end;


    /* Insertamos el dato en la tabla usuario_clave */
    begin
    
        insert into usuario_clave 
            (mes_anno,
             numrun_emp,
             dvrun_emp,
             nombre_empleado,
             nombre_usuario,
             clave_usuario)
        values
            (vs_mesano,
            vs_rutempleado,
            vs_digverif,
            vs_nombreempleado,
            vs_usuario,
            vs_clave);
    exception
        when others then
            rollback;
            dbms_output.put_line('Se ha producido un error en la inserción a la tabla usuario_clave' || chr(10) || sqlerrm);
            return;
    end;

    commit;
    
    dbms_output.put_line('Se ha ingresado el registro correctamente en la tabla USUARIO_CLAVE.');


end;

/*
 *  Fin caso 2
 *
 */


/*
 *   Inicio caso 3
 *
 *  Patentes de prueba:
 *
 *      AHEW11
 *      ASEZ11
 *      BC1002
 *      BT1002
 *      VR1003
 */

declare

    ve_nro_patente varchar2(6);

    vs_anoproceso number(4);
    vs_nropatente varchar2(6);
    vs_valorarriendodia number(6);
    vs_valorgarantiadia number(6);
    vs_totalvecesarrendado number(3);
    vs_valorarriendodiarebajado number(6);
    vs_valorgarantiadiarebajado number(6);
    vs_modificar varchar2(1) := 'N';

    K_NUMEROVECES number(3) := 5;
    K_PORCENTAJEREBAJA number(3, 1) := 22.5;

begin

    begin
        select to_number(to_char(sysdate, 'yyyy')) - 1 as ano_proceso,
            c.nro_patente as patente,
            c.valor_arriendo_dia as valor_arriendo_dia,
            c.valor_garantia_dia as valor_garantia_dia,
            count(ac.nro_patente) as total_veces_arrendado,
            case when count(ac.nro_patente) < K_NUMEROVECES
                
                then round(c.valor_arriendo_dia * (1 - (K_PORCENTAJEREBAJA / 100)), 0)
                
                else c.valor_arriendo_dia
            end as valor_arriendo_dia_rebajado,
            
            case when count(ac.nro_patente) < K_NUMEROVECES
                
                then round(c.valor_garantia_dia * (1 - (K_PORCENTAJEREBAJA / 100)), 0)
                
                else c.valor_garantia_dia
            end as valor_garantia_dia_rebajado,

            case when count(ac.nro_patente) < K_NUMEROVECES

                then 'S'

                else 'N'
            end as modificar
        into
            vs_anoproceso,
            vs_nropatente,
            vs_valorarriendodia,
            vs_valorgarantiadia,
            vs_totalvecesarrendado,
            vs_valorarriendodiarebajado,
            vs_valorgarantiadiarebajado,
            vs_modificar
        from camion c
        inner join arriendo_camion ac on c.nro_patente = ac.nro_patente
        where c.nro_patente = :ve_nro_patente and
            to_number(to_char(ac.fecha_ini_arriendo, 'yyyy')) = to_number(to_char(sysdate, 'yyyy')) - 1
        group by to_number(to_char(sysdate, 'yyyy')) - 1,
            c.nro_patente,
            c.valor_arriendo_dia,
            c.valor_garantia_dia;
    exception
        when no_data_found then
            dbms_output.put_line('El camión de patente ' || :ve_nro_patente || ' no existe en el sistema. Verifique el número de patente y reintente.');
            return;
        when others then
            dbms_output.put_line('Se ha producido un error en la base de datos' || chr(10) || sqlerrm);
            return;
    end;

    /* Primero eliminamos el registro para el mes-año y el rut de manera de evitar errores por primary key */
    begin
        delete hist_arriendo_anual_camion
        where anno_proceso = vs_anoproceso and
            nro_patente = :ve_nro_patente; 
    exception
        when others then
            rollback;
            dbms_output.put_line('Se ha producido un error en la eliminación del registro en la tabla hist_arriendo_anual_camion' || chr(10) || sqlerrm);
            return;
    end;


    /* Insertamos el dato en la tabla hist_arriendo_anual_camion */
    begin
    
        insert into hist_arriendo_anual_camion 
            (anno_proceso,
             nro_patente,
             valor_arriendo_dia,
             valor_garactia_dia,
             total_veces_arrendado)
        values
            (vs_anoproceso,
            vs_nropatente,
            vs_valorarriendodia,
            vs_valorgarantiadia,
            vs_totalvecesarrendado);
    exception
        when others then
            rollback;
            dbms_output.put_line('Se ha producido un error en la inserción a la tabla hist_arriendo_anual_camion' || chr(10) || sqlerrm);
            return;
    end;
    
    dbms_output.put_line('Se ha ingresado el registro correctamente en la TABLA HIST_ARRIENDO_ANUAL_CAMION.');

    /* Modificamos el valor del arriendo diario y la garantía si corresponde */
    if vs_modificar = 'S' then

        begin
            update camion
            set valor_arriendo_dia = vs_valorarriendodiarebajado,
                valor_garantia_dia = vs_valorgarantiadiarebajado
            where nro_patente = vs_nropatente;
        exception
            when others then
                rollback;
                dbms_output.put_line('Se ha producido un error en la modificación de los valores de arriendo y garantía' || chr(10) || sqlerrm);
                return;
        end;

        dbms_output.put_line('Cantidad de veces arriendo camión: ' || vs_totalvecesarrendado || ' (Valor menor al límite definido: ' || K_NUMEROVECES || '). Se rebaja valor de arriendo y garantía en un ' || trim(to_char(K_PORCENTAJEREBAJA, '999.9')) || '%.');

    else
        dbms_output.put_line('Cantidad de veces arriendo camión: ' || vs_totalvecesarrendado || '. (Valor mayor o igual al límite definido: ' || K_NUMEROVECES || '). No corresponde rebaja de valor de arriendo ni de garantía. ');
    end if;

    commit;

end;

/*
 *  Fin caso 3
 *
 */

/*
 *   Inicio caso 4
 *
 *  Patentes de prueba:
 *
 *      AA1001
 *      AHEW11
 *      ASEZ11
 *      BT1002
 *      VR1003
 */


declare

    ve_nro_patente varchar2(6);
    ve_valor_multa_diario number(10);

    vs_anomes varchar2(6);
    vs_nropatente varchar2(6);
    vs_fechainiarriendo date;
    vs_diassolicitados number(3);
    vs_fechadevolucion date;

    vl_diasatraso number(3);
    vl_totalmulta number(10);

begin

    begin
        select to_number(to_char(sysdate, 'yyyymm')) as ano_mes,
            ac.nro_patente as nro_patente,
            ac.fecha_ini_arriendo as fecha_ini_arriendo,
            ac.dias_solicitados as dias_solicitados,
            ac.fecha_devolucion as fecha_devolucion
        into
            vs_anomes,
            vs_nropatente,
            vs_fechainiarriendo,
            vs_diassolicitados,
            vs_fechadevolucion
        from arriendo_camion ac
        where ac.nro_patente = :ve_nro_patente and
            to_char(ac.fecha_ini_arriendo, 'mmyyyy') = to_char(add_months(trunc(sysdate,'mm'),-1), 'mmyyyy') and
            ac.fecha_devolucion - ac.fecha_ini_arriendo > ac.dias_solicitados;
    exception
        when no_data_found then
            dbms_output.put_line('El camión de patente ' || :ve_nro_patente || ' no tiene arriendos para el mes anterior. Verifique el número de patente y reintente.');
            return;
        when too_many_rows then
            dbms_output.put_line('El camión de patente ' || :ve_nro_patente || ' tiene más de un arriendo para el mes anterior. Esperemos pasar cursores para resolverlo.');
            return;
        when others then
            dbms_output.put_line('Se ha producido un error en la base de datos' || chr(10) || sqlerrm);
            return;
    end;

    /* Determinamos los atrasos vía PL/SQL debido a restricción del problema */
    vl_diasatraso := (vs_fechadevolucion - vs_fechainiarriendo) - vs_diassolicitados;
    vl_totalmulta := vl_diasatraso * :ve_valor_multa_diario;

    /* Primero eliminamos el registro para el año-mes y la patente de manera de evitar errores por primary key */
    begin
        delete multa_arriendo
        where anno_mes_proceso = vs_anomes and
            nro_patente = :ve_nro_patente; 
    exception
        when others then
            rollback;
            dbms_output.put_line('Se ha producido un error en la eliminación del registro en la tabla multa_arriendo' || chr(10) || sqlerrm);
            return;
    end;

    /* Insertamos el dato en la tabla multa_arriendo */
    begin
    
        insert into multa_arriendo 
            (anno_mes_proceso,
             nro_patente,
             fecha_ini_arriendo,
             dias_solicitado,
             fecha_devolucion,
             dias_atraso,
             valor_multa)
        values
            (vs_anomes,
            vs_nropatente,
            vs_fechainiarriendo,
            vs_diassolicitados,
            vs_fechadevolucion,
            vl_diasatraso,
            vl_totalmulta);
    exception
        when others then
            rollback;
            dbms_output.put_line('Se ha producido un error en la inserción a la tabla multa_arriendo' || chr(10) || sqlerrm);
            return;
    end;

    dbms_output.put_line('Se ha ingresado el registro correctamente en la MULTA_ARRIENDO.');

    commit;

end;

/*
 *  Fin caso 4
 *
 */
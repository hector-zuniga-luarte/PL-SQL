/*
 *  MDY3131_005V - Programación de Base de Datos
 *  
 *  viernes 08.04.2022
 *  
 *  Héctor Zúñiga Luarte    - hec.zuniga@duocuc.cl
 *  
 *  Prueba 1
 *
 */

/* Instrucción para ver la salida por pantalla */
set serveroutput on;

/*
 *  Inicio prueba 1
 *
 */

/*  Variables de entrada:
 *
 *  ve_fecha_proceso:   01/06/2021 (respetar formato de fecha)
 *  vl_porcentaje_1:    35
 *  vl_porcentaje_2:    30
 *  vl_porcentaje_3:    25
 *  vl_porcentaje_4:    20
 *  vl_porcentaje_5:    15
 *      
 */

variable

    ve_fecha_proceso                date;
    ve_porcentaje_1                 number(3);
    ve_porcentaje_2                 number(3);
    ve_porcentaje_3                 number(3);
    ve_porcentaje_4                 number(3);
    ve_porcentaje_5                 number(3);
    ve_valor_comision               number(10);

declare

    vl_min_id_empleado              empleado.id_empleado%type;
    vl_max_id_empleado              empleado.id_empleado%type;
    vl_id_empleado                  empleado.id_empleado%type;
    vl_fecha_proceso                date;
    vl_ano                          number(4);
    vl_mes                          number(2);
    vl_nombre_empleado              varchar2(200);
    vl_id_equipo                    equipo.id_equipo%type;
    vl_nombre_equipo                equipo.nom_equipo%type;
    vl_anos_vinculado               number(2);
    vl_numero_ventas                number(5);
    vl_ventas_netas_mes             number(10);
    vl_bono_equipo                  number(10);
    vl_incentivo_categorizacion     number(10);
    vl_porcentaje_asignacion        number(3);
    vl_asignacion_ventas            number(10);
    vl_porcentaje_antiguedad        number(3);
    vl_asignacion_antiguedad        number(10);
    vl_monto_descuento              number(10);
    vl_total_mes                    number(10);
    vl_porcentaje_comision          number(5,2);
    vl_valor_comision               number(10);

begin

    /* Transformamos la fecha ingresada a tipo date */
    begin
        vl_fecha_proceso := to_date(:ve_fecha_proceso, 'dd/mm/yyyy');
    exception 
        when others then
            dbms_output.put_line('Error en la base de datos al transformar la fecha ingresada a date.' || chr(10) || sqlerrm);
            return;
    end;

    /* Extraemos el mínimo y máximo de los id de cada empleado */
    begin
        select min(e.id_empleado) as min_id_empleado,
            max(e.id_empleado) as max_id_empleado
        into vl_min_id_empleado,
            vl_max_id_empleado
        from empleado e;
    exception 
        when others then
            dbms_output.put_line('Error en la base de datos al recuperar el mínimo y máximo ID de empleado.' || chr(10) || sqlerrm);
            return;
    end;

    /* Recorremos la tabla empleado para recuperar los datos necesarios para cada uno de ellos */
    for vl_id_empleado in vl_min_id_empleado..vl_max_id_empleado loop

        begin
            select extract(year from vl_fecha_proceso) as ano,
                extract(month from vl_fecha_proceso) as mes,
                trim(e.apellidos) || ' ' || trim(e.nombres) as nombre_empleado,
                e.id_equipo as id_equipo,
                eq.nom_equipo as nombre_equipo,
                floor(months_between(vl_fecha_proceso, e.feccontrato) / 12) as anos_vinculado
            into vl_ano,
                vl_mes,
                vl_nombre_empleado,
                vl_id_equipo,
                vl_nombre_equipo,
                vl_anos_vinculado
            from empleado e
            inner join equipo eq on e.id_equipo = eq.id_equipo
            where e.id_empleado = vl_id_empleado;
        exception
            when no_data_found then
            /* Si no hay datos para ese empleado saltamos el ciclo y pasamos al siguiente empleado */
                continue;
            when others then
            /* Si hay error de base de datos imprimimos el error y pasamos al siguiente empleado */
                dbms_output.put_line('Error en la base de datos al recuperar el dato de empleado de ID ' || to_char(vl_id_empleado) || chr(10) || sqlerrm);
                continue;
        end;
            
        
        /* Recuperamos el total de ventas y el monto neto para todas las ventas del empleado */
        begin        
            select count(b.id_boleta) as numero_ventas,
                sum(db.cantidad * p.precio) as ventas_netas_mes
            into vl_numero_ventas,
                vl_ventas_netas_mes
            from boleta b
            inner join detalleboleta db on b.id_boleta = db.id_boleta
            inner join producto p on db.id_producto = p.id_producto
            where b.id_empleado = vl_id_empleado and
                extract(year from b.fecha_boleta) = vl_ano and
                extract(month from fecha_boleta) = vl_mes;
        exception 
            when others then
            /* Si hay error de base de datos imprimimos el error y pasamos al siguiente empleado */
                dbms_output.put_line('Error en la base de datos al recuperar los datos de total de ventas y monto total.' || chr(10) || sqlerrm);
                continue;
        end;


        /* Recuperamos el bono por equipo de acuerdo a sus ventas */
        begin
            select round(vl_ventas_netas_mes * (eq.porc / 100), 0) as bono_equipo
            into vl_bono_equipo
            from equipo eq
            where eq.id_equipo = vl_id_equipo;
        exception 
            when others then
            /* Si hay error de base de datos imprimimos el error y pasamos al siguiente empleado */
                dbms_output.put_line('Error en la base de datos al recuperar los datos de total de ventas y monto total.' || chr(10) || sqlerrm);
                continue;
        end;

        
        /* Recuperamos el incentivo por categorización */
        begin
            select round(vl_ventas_netas_mes * (c.porcentaje / 100), 0) as incentivo_categorizacion
            into vl_incentivo_categorizacion
            from empleado e
            inner join categorizacion c on e.id_categorizacion = c.id_categorizacion
            where id_empleado = vl_id_empleado;
        exception
            when others then
            /* Si hay error de base de datos imprimimos el error y pasamos al siguiente empleado */
                dbms_output.put_line('Error en la base de datos al recuperar los datos de total de ventas y monto total.' || chr(10) || sqlerrm);
                continue;
        end;

        
        /* Calculamos la asignación por ventas */
        vl_porcentaje_asignacion := (case
                                        when vl_numero_ventas > 10 then :ve_porcentaje_1
                                        when vl_numero_ventas between 9 and 10 then :ve_porcentaje_2
                                        when vl_numero_ventas between 6 and 8 then :ve_porcentaje_3
                                        when vl_numero_ventas between 3 and 5 then :ve_porcentaje_4
                                        when vl_numero_ventas between 1 and 2 then :ve_porcentaje_5
                                        else 0
                                    end);
        
        vl_asignacion_ventas := round(vl_ventas_netas_mes * (vl_porcentaje_asignacion / 100), 0);
        

        /* Calculamos la asignación por antigüedad */
        vl_porcentaje_antiguedad := (case
                                        when vl_anos_vinculado > 15 then 27
                                        when vl_anos_vinculado between 6 and 15 then 14
                                        when vl_anos_vinculado between 3 and 7 then 4
                                        else 0
                                    end);
        
        vl_asignacion_antiguedad := round(vl_ventas_netas_mes * (vl_porcentaje_antiguedad / 100), 0);
        

        /* Calculamos los descuentos del empleado para el mes anterior */
        begin
            select monto
            into vl_monto_descuento
            from descuento
            where id_empleado = vl_id_empleado and
                mes = vl_mes - 1;
        exception
            when others then
            /* Si hay error de base de datos imprimimos el error y pasamos al siguiente empleado */
                dbms_output.put_line('Error en la base de datos al recuperar los datos de total de ventas y monto total.' || chr(10) || sqlerrm);
                continue;
        end;

        
        /* Calculamos el total del mes */
        vl_total_mes := vl_ventas_netas_mes + vl_bono_equipo + vl_incentivo_categorizacion + vl_asignacion_ventas + vl_asignacion_antiguedad - vl_monto_descuento;


        /* Inicio almacenamiento en tabla detalle_venta_empleado */
        
        /* Eliminamos primero el eventual registro antes de insertar en tabla detalle_venta_empleado */
        begin
            delete detalle_venta_empleado
            where anno = vl_ano and
                mes = vl_mes and
                id_empleado = vl_id_empleado;
        exception
            when others then
            /* Si hay error de base de datos imprimimos el error y pasamos al siguiente empleado */
                dbms_output.put_line('Error en la base de datos al eliminar el registro en tabla detalle_venta_empleado' || chr(10) || sqlerrm);
                rollback;
                continue;
        end;
        
        /* Insertamos el registro en la tabla detalle_venta_empleado */
        begin
            insert into detalle_venta_empleado
                (anno,
                mes,
                id_empleado,
                nombre,
                equipo_emp,
                nro_ventas,
                ventas_netas_mes,
                bono_equipo,
                incentivo_categorizacion,
                asignacion_vtas,
                asignacion_antig,
                descuentos,
                totales_mes)
            values
                (vl_ano,
                vl_mes,
                vl_id_empleado,
                vl_nombre_empleado,
                vl_nombre_equipo,
                vl_numero_ventas,
                vl_ventas_netas_mes,
                vl_bono_equipo,
                vl_incentivo_categorizacion,
                vl_asignacion_ventas,
                vl_asignacion_antiguedad,
                vl_monto_descuento,
                vl_total_mes);
        exception
            when others then
            /* Si hay error de base de datos imprimimos el error y pasamos al siguiente empleado */
                dbms_output.put_line('Error en la base de datos al insertar el registro en tabla detalle_venta_empleado' || chr(10) || sqlerrm);
                rollback;
                continue;
        end;

        /* Fin almacenamiento en tabla detalle_venta_empleado */

        /* Calculamos la comisión de empleado */
        begin
            select ce.comision as porcentaje_comision
            into vl_porcentaje_comision
            from comisionempleado ce
            where vl_ventas_netas_mes between ce.ventaminima and ce.ventamaxima;
        exception
            when others then
            /* Si hay error de base de datos imprimimos el error y pasamos al siguiente empleado */
                dbms_output.put_line('Error en la base de datos al consultar las comisiones del empleado.' || chr(10) || sqlerrm);
                continue;
        end;

        vl_valor_comision := round(vl_ventas_netas_mes * (vl_porcentaje_comision /100), 0);

        /* Inicio almacenamiento en tabla comision_venta_empleado */

        /* Eliminamos primero el eventual registro antes de insertar en tabla comision_venta_empleado */
        begin
            delete comision_venta_empleado
            where anno = vl_ano and
                mes = vl_mes and
                id_empleado = vl_id_empleado ;
        exception
            when others then
            /* Si hay error de base de datos imprimimos el error y pasamos al siguiente empleado */
                dbms_output.put_line('Error en la base de datos al eliminar el registro en tabla comision_venta_empleado' || chr(10) || sqlerrm);
                rollback;
                continue;
        end;

        /* Insertamos el registro en la tabla comision_venta_empleado */
        begin
            insert into comision_venta_empleado
                (anno,
                mes,
                id_empleado,
                total_ventas,
                monto_comision)
            values
                (vl_ano,
                vl_mes,
                vl_id_empleado,
                vl_total_mes,
                vl_valor_comision);
        exception
            when others then
            /* Si hay error de base de datos imprimimos el error y pasamos al siguiente empleado */
                dbms_output.put_line('Error en la base de datos al insertar el registro en tabla detalle_venta_empleado' || chr(10) || sqlerrm);
                rollback;
                continue;
        end;

        /* Fin almacenamiento en tabla comision_venta_empleado */


        /* Grabamos la inserción del registro en la base de datos */
        commit;

        /* Generamos mensajes */
        dbms_output.put_line('Procesando empleado: ' || vl_nombre_empleado);
        dbms_output.put_line('Se ingresó registro en tabla detalle_venta_empleado');
        dbms_output.put_line('Se ingresó registro en tabla comision_venta_empleado' || chr(10));

    end loop;


end;

/*
 *  Fin prueba 1
 *
 */

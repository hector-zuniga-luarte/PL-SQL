/*
 *  Asignatura  :   MDY3131_005V - Programación de Base de Datos
 *
 *  Profesor    :   Eduardo Rojas Atao
 *  
 *  Fecha       :   viernes 13.05.2022
 *  
 *  Alumno      :   Héctor Zúñiga Luarte - hec.zuniga@duocuc.cl
 *  
 *  Prueba      :   N° 2
 *
 */

/* Instrucción para ver la salida por pantalla */
set serveroutput on;



/*
 *  Inicio pregunta 1 - parte 1
 */
DECLARE
   -- cursor que recupera los viñateros o productores
   CURSOR c1 IS
   SELECT id_productor,
    nom_productor
   FROM productor
   where id_productor in (select id_productor
                          from producto);
   -- cursor que recupera productos de cada viñatero
   -- recibe como parámetro la id del productor
   CURSOR c2 (n NUMBER) IS
   SELECT id_producto,
        nom_producto,
        stock,
        precio
   FROM producto
   WHERE id_productor = n;
   counter number := 0;
   
   v_id_productor          number(5);
   v_nom_productor          varchar2(200);
   
   v_id_producto            number(6);
   v_nom_producto           varchar2(100);
   v_stock                  number(4);
   v_precio                 number(7);
   
BEGIN
   
   OPEN c1;
   
   LOOP
   
    FETCH c1 INTO v_id_productor, v_nom_productor;
    
    EXIT WHEN c1%NOTFOUND;
   
      dbms_output.put_line('####### LISTA DE VINOS DE LA VIÑA ' || '"' || UPPER(v_nom_productor || '"'));
      dbms_output.put_line(CHR(13));   
      dbms_output.put_line(lpad('-',65,'-'));
      dbms_output.put_line('  ID  NOMBRE PRODUCTO      STOCK  PRECIO ACTUAL   NUEVO PRECIO');
      dbms_output.put_line(lpad('-',65,'-'));
      counter := 0;
      
      OPEN c2(v_id_productor);
      LOOP
      
         FETCH c2 INTO v_id_producto, v_nom_producto, v_stock, v_precio;
         EXIT WHEN c2%NOTFOUND;
      
         counter := counter + 1;       
             dbms_output.put_line(v_id_producto
                || ' ' || RPAD(v_nom_producto, 20,' ')
                || ' ' || TO_CHAR(v_stock,'999')
                || ' ' || rpad(TO_CHAR(v_precio, '$9G999G999'),15, ' ')
                || ' ' || TO_CHAR(v_precio * 1.07, '$9G999G999'));
      END LOOP;
      CLOSE c2;
      dbms_output.put_line(lpad('-',65,'-'));      
      dbms_output.put_line('Total de productos en tienda: ' || counter);      
      dbms_output.put_line(CHR(12));
   END LOOP;
   CLOSE c1;
 END;
/*
 *  Fin pregunta 1 - parte 1
 */


/*
 *  Inicio pregunta 1 - parte 2
 */
DECLARE

    TYPE tipo_registro_producto IS RECORD (
        ID_PRODUCTO PRODUCTO.ID_PRODUCTO%TYPE, 
        NOM_PRODUCTO PRODUCTO.NOM_PRODUCTO%TYPE, 
        CRIANZA PRODUCTO.CRIANZA%TYPE, 
        MARIDAJE PRODUCTO.MARIDAJE%TYPE, 
        TEMPERATURA PRODUCTO.TEMPERATURA%TYPE, 
        STOCK PRODUCTO.STOCK%TYPE, 
        PRECIO PRODUCTO.PRECIO%TYPE, 
        ID_LINEA PRODUCTO.ID_LINEA%TYPE, 
        ID_CEPA PRODUCTO.ID_CEPA%TYPE, 
        ID_PRODUCTOR PRODUCTO.ID_PRODUCTOR%TYPE);
    
    registro_producto tipo_registro_producto;

   -- cursor que recupera los viñateros o productores
   CURSOR c1 IS
   SELECT id_productor,
    nom_productor
   FROM productor
   where id_productor in (select id_productor
                          from producto);
   -- cursor que recupera productos de cada viñatero
   -- recibe como parámetro la id del productor
   CURSOR c2 (n NUMBER) IS
   SELECT *
   FROM producto
   WHERE id_productor = n;
   counter number := 0;
   
   v_id_productor          number(5);
   v_nom_productor          varchar2(200);
   
   v_id_producto            number(6);
   v_nom_producto           varchar2(100);
   v_stock                  number(4);
   v_precio                 number(7);
   
BEGIN
   
   OPEN c1;
   FETCH c1 INTO v_id_productor, v_nom_productor;
   
   WHILE c1%FOUND LOOP
   
    
      dbms_output.put_line('####### LISTA DE VINOS DE LA VIÑA ' || '"' || UPPER(v_nom_productor || '"'));
      dbms_output.put_line(CHR(13));   
      dbms_output.put_line(lpad('-',65,'-'));
      dbms_output.put_line('  ID  NOMBRE PRODUCTO      STOCK  PRECIO ACTUAL   NUEVO PRECIO');
      dbms_output.put_line(lpad('-',65,'-'));
      counter := 0;
      
      OPEN c2(v_id_productor);
      FETCH c2 INTO registro_producto;
      WHILE c2%FOUND LOOP
      
         EXIT WHEN c2%NOTFOUND;
      
         counter := counter + 1;       
             dbms_output.put_line(registro_producto.id_producto
                || ' ' || RPAD(registro_producto.nom_producto, 20,' ')
                || ' ' || TO_CHAR(registro_producto.stock,'999')
                || ' ' || rpad(TO_CHAR(registro_producto.precio, '$9G999G999'),15, ' ')
                || ' ' || TO_CHAR(registro_producto.precio * 1.07, '$9G999G999'));
                
        FETCH c2 INTO registro_producto;
      END LOOP;
      CLOSE c2;
      dbms_output.put_line(lpad('-',65,'-'));      
      dbms_output.put_line('Total de productos en tienda: ' || counter);      
      dbms_output.put_line(CHR(12));
      
      FETCH c1 INTO v_id_productor, v_nom_productor;
      
   END LOOP;
   CLOSE c1;
 END;
/*
 *  Fin pregunta 1 - parte 2
 */



/*
 *  Inicio pregunta 2
 */

/*  Variables de entrada:
 *
 *  ve_fechaproceso:                01/06/2021 (respetar formato de fecha)
 *  ve_limitedescuentoporcepa:      50000
 *  ve_porcentajesyrah              17
 *  ve_porcentajecarmanere          23
 *  ve_porcentajecabernetsauvignon  19
 *  ve_porcentajemerlot             21
 *  ve_porcentajeotros              15
 *  ve_valordelivery                1800
 *      
 */

variable

    /* Variables de entrada */
    ve_fechaproceso                 date;
    ve_limitedescuentoporcepa       number(6);
    ve_porcentajesyrah              number(3);
    ve_porcentajecarmenere          number(3);
    ve_porcentajecabernetsauvignon  number(3);
    ve_porcentajemerlot             number(3);
    ve_porcentajeotros              number(3);
    ve_valordelivery                number(6);

declare

    /* Constantes */
    K_SYRAH                         cepa.id_cepa%type := 2;
    K_CARMENERE                     cepa.id_cepa%type := 3;
    K_CABERNETSAUVIGNON             cepa.id_cepa%type := 4;
    K_MERLOT                        cepa.id_cepa%type := 5;

    /* Excepciones del negocio */
    e_max_valor_descuento_cepa exception;
    pragma exception_init (e_max_valor_descuento_cepa, -20001);

    /* Arreglo para almacenar los parámetros de entrada. */
    type tipo_arreglo_param is varray(6) of number(6);
    arreglo_param tipo_arreglo_param;
    
    /* Cursor 1: Cursor para recorrer las cepas */
    cursor c_cepas is
        select c.id_cepa as id_cepa,
            c.nom_cepa as nom_cepa
        from cepa c
        order by c.nom_cepa;

    /* Cursor 2: Cursor para recorrer los pedidos para cada cepa por día */
    cursor c_pedidospordia(pc_idcepa cepa.id_cepa%type, pc_fechaproceso date) is
        select c.nom_cepa as nom_cepa,
            ped.fec_pedido as fecha,
            count(ped.id_pedido) as num_pedidos,
            sum(ped.subtotal) as monto_pedidos
        from pedido ped,
            detalle_pedido dp,
            producto p,
            mezcla m,
            cepa c
        where dp.id_producto = p.id_producto and
            ped.id_pedido = dp.id_pedido and
            m.id_producto(+) = p.id_producto and
            m.id_cepa(+) = p.id_cepa and
            c.id_cepa = p.id_cepa(+) and
            extract(year from ped.fec_pedido) = extract(year from pc_fechaproceso) and
            extract(month from ped.fec_pedido) = extract(month from pc_fechaproceso) and
            c.id_cepa = pc_idcepa
        group by c.nom_cepa,
            ped.fec_pedido;
            
    /* Variables para almacenar en la tabla resumen_ventas_cepa */
    vl_cepa                             resumen_ventas_cepa.cepa%type;
    vl_numpedidos                       resumen_ventas_cepa.num_pedidos%type;
    vl_montopedidos                     resumen_ventas_cepa.monto_pedidos%type;
    vl_gravamenes                       resumen_ventas_cepa.gravamenes%type;
    vl_desctoscepa                      resumen_ventas_cepa.desctos_cepa%type;
    vl_montodelivery                    resumen_ventas_cepa.monto_delivery%type;
    vl_montodescuentos                  resumen_ventas_cepa.monto_descuentos%type;
    vl_totalrecaudacion                 resumen_ventas_cepa.total_recaudacion%type;

    /* Variables para almacenar en la tabla detalle_ventas_diarias */
    vl_fecha                            detalle_ventas_diarias.fecha%type;
    vl_desctoscepapordia                detalle_ventas_diarias.desctos_cepa%type;
    vl_montocomisionespordia            detalle_ventas_diarias.monto_comisiones%type;
    vl_montodeliverypordia              detalle_ventas_diarias.monto_delivery%type;
    vl_totaldescuentospordia            detalle_ventas_diarias.total_descuentos%type;
    vl_totalrecaudacionpordia           detalle_ventas_diarias.total_recaudacion%type;

    /* Variables de uso local */
    vl_fechaproceso                     date;
    vl_dberror                          errores_proceso_recaudacion.ora_msg%type;
    vl_mensajeerror                     errores_proceso_recaudacion.usr_msg%type;
    vl_numpedidospordia                 resumen_ventas_cepa.num_pedidos%type;
    vl_montopordia                      resumen_ventas_cepa.monto_pedidos%type;
    vl_porcentajegravamenpordia         gravamen.pctgravamen%type;
    vl_gravamenpordia                   resumen_ventas_cepa.monto_pedidos%type;
    vl_porcentajedescuentocepa          gravamen.pctgravamen%type;
    vl_idcepa                           cepa.id_cepa%type;

begin

    /* Transformamos la fecha ingresada a tipo date */
    begin
        vl_fechaproceso := to_date(:ve_fechaproceso, 'dd/mm/yyyy');
    exception 
        when others then
            dbms_output.put_line('Error en la base de datos al transformar la fecha ingresada a date.' || chr(10) || sqlerrm);
            return;
    end;

    /* Almacenamos los parámetros de entrada en un arreglo debido a requerimiento del problema */
    arreglo_param := tipo_arreglo_param(:ve_porcentajesyrah, :ve_porcentajecarmenere, :ve_porcentajecabernetsauvignon, :ve_porcentajemerlot, :ve_porcentajeotros, :ve_valordelivery);

    /* Truncado de las tablas */
    execute immediate 'truncate table errores_proceso_recaudacion';
    execute immediate 'truncate table detalle_ventas_diarias';
    execute immediate 'truncate table resumen_ventas_cepa';

    /* Eliminación y creación de secuencia */
    execute immediate 'drop sequence sq_error';
    execute immediate 'create sequence sq_error';
   
    /* Recorremos el cursor de todas las cepas */
    for reg_cepas in c_cepas loop

        vl_idcepa := reg_cepas.id_cepa;
        vl_cepa := reg_cepas.nom_cepa;

        /* Inicializamos los acumuladores */
        vl_numpedidos := 0;
        vl_montopedidos := 0;
        vl_gravamenes := 0;
        vl_gravamenpordia := 0;
        vl_desctoscepa := 0;
        vl_montodelivery := 0;
        vl_montodescuentos := 0;
        vl_totalrecaudacion := 0;
        
        /* Determinamos el número de pedidos y los montos para cada cepa y para cada día */
        for reg_pedidospordia in c_pedidospordia(reg_cepas.id_cepa, vl_fechaproceso) loop
        
            vl_fecha := reg_pedidospordia.fecha;
            vl_numpedidospordia := reg_pedidospordia.num_pedidos;
            vl_montopordia := reg_pedidospordia.monto_pedidos;
            
            /* Acumulamos los pedidos y los montos */
            vl_numpedidos := vl_numpedidos + vl_numpedidospordia;
            vl_montopedidos := vl_montopedidos + vl_montopordia;
            
            /* Calculamos los gravámenes para cada día y los voy acumulando */
            begin
                select pctgravamen
                into vl_porcentajegravamenpordia
                from gravamen
                where vl_montopordia between mto_venta_inf and mto_venta_sup;
            exception 
                when no_data_found then
                    vl_porcentajegravamenpordia := 0;

                    vl_dberror := sqlerrm;
                    vl_mensajeerror := 'No se encontró porcentaje de gravamen para el monto total de ' || trim(to_char(vl_montopordia, '$999G999G999')) || '.- para el día ' || trim(to_char(vl_fecha, 'dd.mm.yyyy'));

                    /* Insertamos en la tabla de error */
                    insert into errores_proceso_recaudacion (
                        error_id,
                        ora_msg,
                        usr_msg)
                    values (sq_error.nextval,
                        vl_dberror,
                        vl_mensajeerror);

                when too_many_rows then
                    vl_porcentajegravamenpordia := 0;

                    vl_dberror := sqlerrm;
                    vl_mensajeerror := 'Se ha encontrado más de un registro de porcentaje de gravamen para el monto ' || trim(to_char(vl_montopordia, '$999G999G999')) || '.- para el día ' || to_char(vl_fecha, 'dd.mm.yyyy') || '. Este porcentaje se dejará con valor 0.';

                    /* Insertamos en la tabla de error */
                    insert into errores_proceso_recaudacion (
                        error_id,
                        ora_msg,
                        usr_msg)
                    values (sq_error.nextval,
                        vl_dberror,
                        vl_mensajeerror);
                when others then
                    vl_porcentajegravamenpordia := 0;

                    vl_dberror := sqlerrm;
                    vl_mensajeerror := 'Se ha producido un error en la base de datos al recuperar el porcentaje de gravamen';

                    /* Insertamos en la tabla de error */
                    insert into errores_proceso_recaudacion (
                        error_id,
                        ora_msg,
                        usr_msg)
                    values (sq_error.nextval,
                        vl_dberror,
                        vl_mensajeerror);

            end;

            vl_gravamenpordia := round((vl_montopordia * vl_porcentajegravamenpordia) / 100, 0);
            vl_gravamenes := vl_gravamenes + vl_gravamenpordia;

            /* Determinamos el porcentaje de descuento por cepa */
            vl_porcentajedescuentocepa := (case 
                                        when vl_idcepa = K_SYRAH then arreglo_param(1) /* Syrah */ 
                                        when vl_idcepa = K_CARMENERE then arreglo_param(2) /* Carmenere */
                                        when vl_idcepa = K_CABERNETSAUVIGNON then arreglo_param(3) /* Cabernet Sauvignon */ 
                                        when vl_idcepa = K_MERLOT then arreglo_param(4) /* Merlot */ 
                                        else arreglo_param(5) /* Sauvignon Blanc, Riesling, Chardonnay o Sémillon */
                                    end);

            /* Calculamos el descuento por cepa por día */
            vl_desctoscepapordia := round((vl_montopordia * vl_porcentajedescuentocepa) / 100, 0);

            /* Manejamos la excepción del máximo de descuento por día y por cepa */
            begin
                if vl_desctoscepapordia > :ve_limitedescuentoporcepa then
                    raise e_max_valor_descuento_cepa;
                end if;
            exception when e_max_valor_descuento_cepa then

                vl_dberror := sqlerrm || 'Monto de descuento sobrepasa el límite permitido';
                vl_mensajeerror := 'Se reemplaza el monto calculado de ' || trim(to_char(vl_desctoscepapordia, '$999G999G999')) || '.- por el monto límite de ' || trim(to_char(:ve_limitedescuentoporcepa, '$999G999G999'));

                /* Ajustamos el descuento al máximo permitido */
                vl_desctoscepapordia := :ve_limitedescuentoporcepa;

                /* Insertamos en la tabla de error */
                insert into errores_proceso_recaudacion (
                    error_id,
                    ora_msg,
                    usr_msg)
                values (sq_error.nextval,
                    vl_dberror,
                    vl_mensajeerror);

            end;
            
            /* Una vez ajustado el valor máximo de descuento por cepa vamos acumulando el descuento total para esa cepa */
            vl_desctoscepa := vl_desctoscepa + vl_desctoscepapordia;

            /* Calculamos el monto del delivery por día y por cepa */
            vl_montodeliverypordia := vl_numpedidospordia * :ve_valordelivery;
            vl_montodelivery := vl_numpedidos * :ve_valordelivery;
            
            /* Calculamos el monto de los descuentos por día y por cepa */
            vl_totaldescuentospordia := vl_gravamenpordia + vl_desctoscepapordia + vl_montodeliverypordia;
            vl_montodescuentos := vl_gravamenes + vl_desctoscepa + vl_montodelivery;

            /* Calculamos el total de la recaudación */
            vl_totalrecaudacionpordia := vl_montopordia - vl_totaldescuentospordia;
            vl_totalrecaudacion := vl_montopedidos - vl_montodescuentos;
            
            /* Realizamos la inserción en la tabla de detalle por día */
            insert into detalle_ventas_diarias (
                fecha,
                cepa,
                num_pedidos,
                monto_pedidos,
                gravamenes,
                desctos_cepa,
                monto_comisiones,
                monto_delivery,
                total_descuentos,
                total_recaudacion)
            values (
                vl_fecha,
                vl_cepa,
                vl_numpedidospordia,
                vl_montopordia,
                vl_gravamenpordia,
                vl_desctoscepapordia,
                0, /* No se mencionan comisiones en el problema */
                vl_montodeliverypordia,
                vl_totaldescuentospordia,
                vl_totalrecaudacionpordia);
            
            
        end loop;

        /* Realizamos la inserción en la tabla de resumen por cepa */
        insert into resumen_ventas_cepa
            (cepa,
            num_pedidos,
            monto_pedidos,
            gravamenes,
            desctos_cepa,
            monto_delivery,
            monto_descuentos,
            total_recaudacion)
        values
            (vl_cepa,
            vl_numpedidos,
            vl_montopedidos,
            vl_gravamenes,
            vl_desctoscepa,
            vl_montodelivery,
            vl_montodescuentos,
            vl_totalrecaudacion);
            
    end loop;

	/* Confirmamos la inserción de los datos */
	commit;

end;
/*
 *  Fin pregunta 2
 */


/*
 *  MDY3131_005V - Programación de Base de Datos
 *  
 *  Héctor Zúñiga Luarte    - hec.zuniga@duocuc.cl
 *  
 *  Actividad 1.3.2 Actividad Usando Estructuras de Condición en los Procesos
 *
 */

/* Instrucción para ver la salida por pantalla */
set serveroutput on;

/*
 *  Inicio caso 1
 *
 *  Requerimientos del proceso:
 *
 *  R1:     El proceso extrae datos para el año anterior al año de la fecha en la que se ejecuta el proceso
 *  R2:     El resultado se debe almacenar el la tabla cliente_todosuma
 *  R3:     El RUT variable de entrada al proceso
 *  R4:     Los tramos de los montos que están afectos a pesos extras son variables de entrada al proceso
 *  R5:     El valor de los pesos normales y los pesos extra son variables de entrada el proceso
 *  R6:     El cálculo de los pesos extra deben hacerse con instrucciones PL/SQL, no a través de querys 
 *
 *  Variables de entrada:
 *
 *  ve_rut_cliente:     (21242003, 22176845, 18858542, 21300628, 22558061)
 *  ve_rango_01:        1000000
 *  ve_rango_02:        3000000
 *  ve_pesos_normales:  1200
 *  ve_pesos_extra_01:  100
 *  ve_pesos_extra_02:  200
 *  ve_pesos_extra_03:  300
 *
 *      
 */

variable

    ve_rut_cliente          cliente.numrun%type;
    ve_rango_01             number(10);
    ve_rango_02             number(10);
    ve_pesos_normales       number(6);
    ve_pesos_extra_01       number(4);
    ve_pesos_extra_02       number(4);
    ve_pesos_extra_03       number(4);


declare

    K_MONTOPESOS                    number(10) := 100000;
    K_CODTRABAJADORINDEPENDIENTE    number(1) := 2;

    vl_montopesostodosuma           number(10);
    vl_montopesosextra              number(10);
 
    vs_nrocliente                   cliente.nro_cliente%type;
    vs_rutcliente                   varchar2(20);
    vs_nomcliente                   varchar2(210);
    vs_codtipocliente               tipo_cliente.cod_tipo_cliente%type;
    vs_tipocliente                  tipo_cliente.nombre_tipo_cliente%type;
    vs_totalsolicitado              number(20);

begin

    /* Recuperamos los datos del cliente ingresado, su tipo y el total solicitado en créditos al banco el año anterior a la fecha de sistema */
    begin
        select c.nro_cliente as nro_cliente,
            replace(trim(to_char(c.numrun, '999G999G999')), ',', '.') || '-' || dvrun as rut_cliente,
            c.pnombre || ' ' || c.snombre || ' ' || c.appaterno || ' ' || c.apmaterno as nom_cliente,
            c.cod_tipo_cliente as cod_tipo_cliente,
            tc.nombre_tipo_cliente as tipo_cliente,
            sum(cc.monto_solicitado) as total_solicitado_creditos
        into vs_nrocliente,
                vs_rutcliente,
                vs_nomcliente,
                vs_codtipocliente,
                vs_tipocliente,
                vs_totalsolicitado
        from cliente c
        inner join tipo_cliente tc on c.cod_tipo_cliente = tc.cod_tipo_cliente
        inner join credito_cliente cc on c.nro_cliente = cc.nro_cliente
        where c.numrun = :ve_rut_cliente and
            extract(year from cc.fecha_solic_cred) = extract(year from sysdate) - 1 /* Para todos los crédito que se hayan solicitado el año anterior */
        group by c.nro_cliente,
            replace(trim(to_char(c.numrun, '999G999G999')), ',', '.') || '-' || dvrun,
            c.pnombre || ' ' || c.snombre || ' ' || c.appaterno || ' ' || c.apmaterno,
            c.cod_tipo_cliente,
            tc.nombre_tipo_cliente;
    exception
        when no_data_found then
            dbms_output.put_line('El cliente de RUT ' || :ve_rut_cliente || ' no existe en el sistema. Verifique el RUT del cliente y reintente.');
            return;
        when others then
            dbms_output.put_line('Se ha producido un error en la base de datos' || chr(10) || sqlerrm);
            return;
    end;


    /* Primero acumulamos los pesos normales, ve_pesos_normales cada K_MONTOPESOS */
    vl_montopesostodosuma := floor(vs_totalsolicitado / K_MONTOPESOS) * :ve_pesos_normales;

    /*  Luego calculanoa el monto extra en la variable vl_montopesosextra dependiendo de en qué caso entra (solo considerando trabajadores independientes,
        para el resto esta variable está inicializada en 0 así que no aporta  */

    if vs_codtipocliente <> K_CODTRABAJADORINDEPENDIENTE then
    /* Si no es trabajador independiente, no recibe monto extra */
        vl_montopesosextra := 0;
    else
    /* Trabajadores independientes, reciben monto extra dependiende del valor total en créditos solicitados */

        /* Caso 1: Menor al rango 1 */
        if vs_totalsolicitado <= :ve_rango_01 then
            vl_montopesosextra := :ve_pesos_extra_01;
        end if;

        /* Caso 2: Entre el rango 1 y el rango 2 */
        if vs_totalsolicitado > :ve_rango_01 and vs_totalsolicitado <= :ve_rango_02 then
            vl_montopesosextra := :ve_pesos_extra_02;
        end if;

        /* Caso 3: Mayor al rango 2 */
        if vs_totalsolicitado > :ve_rango_02 then
            vl_montopesosextra := :ve_pesos_extra_03;
        end if;

    end if;

    /* Calculamos el monto final */
    vl_montopesostodosuma := vl_montopesostodosuma + floor(vs_totalsolicitado / K_MONTOPESOS) * vl_montopesosextra;

    /* Eliminamos el registro en la tabla cliente_todosuma para ese número de cliente específico para evitar errores de primary key*/
    begin
        delete from cliente_todosuma
        where nro_cliente = vs_nrocliente;
    exception
        when others then
            rollback;
            dbms_output.put_line('Se ha producido un error en la eliminación del registro en la tabla cliente_todosuma' || chr(10) || sqlerrm);
            return;
    end;

    /* Insertamos registro en la tabla cliente_todosuma */
    begin
        insert into cliente_todosuma
            (nro_cliente,
            run_cliente,
            nombre_cliente,
            tipo_cliente,
            monto_solic_creditos,
            monto_pesos_todosuma)
        values
            (vs_nrocliente,
            vs_rutcliente,
            vs_nomcliente,
            vs_tipocliente,
            vs_totalsolicitado,
            vl_montopesostodosuma);
    exception
        when others then
            rollback;
            dbms_output.put_line('Se ha producido un error en la eliminación del registro en la tabla cliente_todosuma' || chr(10) || sqlerrm);
            return;
    end;

    /* Confirmamos la transacción en la base de datos */
    commit;

    dbms_output.put_line('Se ha ingresado el registro correctamente en la tabla cliente_todosuma.');

end;


/*
 *  Fin caso 1
 *
 */


/*
 *   Inicio caso 2
 *
 *  Requerimientos del proceso:
 *
 *  R1:     El proceso recibe el RUT como variable de entrada
 *  R2:     El resultado se debe almacenar en la tabla cumpleanno_cliente
 *  R3:     El proceso determina los clientes que están de cumpleaños en el mes posterior al del mes de la fecha en la que se ejecuta
 *  R4:     Los tramos de valores se ingresan como variables de entrada
 *  R5:     El monto de gifcard por tramo se ingresa como variable de entrada
 *  R6:     El monto de giftcard del cliente se debe calcular con sentencias PL/SQL
 *
 *  Variables de entrada:
 *
 *  ve_rut_cliente:         (12362093, 7455786, 6604005, 8925537, 24617341)
 *  ve_rango_01:            900000
 *  ve_rango_02:            2000000
 *  ve_rango_03:            5000000
 *  ve_rango_04:            8000000
 *  ve_rango_05:            15000000
 *  ve_montogiftcard_01:    0
 *  ve_montogiftcard_02:    50000
 *  ve_montogiftcard_03:    100000
 *  ve_montogiftcard_04:    200000
 *  ve_montogiftcard_05:    300000
 *
 */

variable

    ve_rut_cliente          cliente.numrun%type;
    ve_rango_01:            number(10);
    ve_rango_02:            number(10);
    ve_rango_03:            number(10);
    ve_rango_04:            number(10);
    ve_rango_05:            number(10);
    ve_monto_giftcard_01    number(10);
    ve_monto_giftcard_02    number(10);
    ve_monto_giftcard_03    number(10);
    ve_monto_giftcard_04    number(10);
    ve_monto_giftcard_05    number(10);

declare

    vs_nrocliente           cliente.nro_cliente%type;
    vs_rutcliente           varchar2(20);
    vs_nomcliente           varchar2(210);
    vs_nombreprofofic       profesion_oficio.nombre_prof_ofic%type;
    vs_diacumpleano         varchar2(50);
    vs_observacion          varchar2(200);
    vs_montototalahorrado   number(10);

    vl_montogiftcard        number(10);

begin

    begin
        select c.nro_cliente as nro_cliente,
            replace(trim(to_char(c.numrun, '999G999G999')), ',', '.') || '-' || dvrun as rut_cliente,
            c.pnombre || ' ' || c.snombre || ' ' || c.appaterno || ' ' || c.apmaterno as nom_cliente,
            po.nombre_prof_ofic as nombre_prof_ofic,
            to_char(c.fecha_nacimiento, 'dd') || ' de ' || to_char(c.fecha_nacimiento, 'month') as dia_cumpleano,
            case
                when to_char(c.fecha_nacimiento, 'mm') = to_char(add_months(trunc(sysdate, 'mm'), 1), 'mm')
                then null
                
                else
                    'El cliente no está de cumpleaños en el mes procesado'
            end as observacion,
            sum(nvl(pic.monto_total_ahorrado, 0)) as monto_total_ahorrado
        into vs_nrocliente,
            vs_rutcliente,
            vs_nomcliente,
            vs_nombreprofofic,
            vs_diacumpleano,
            vs_observacion,
            vs_montototalahorrado
        from cliente c
        inner join profesion_oficio po on c.cod_prof_ofic = po.cod_prof_ofic
        left join producto_inversion_cliente pic on pic.nro_cliente = c.nro_cliente
        where c.numrun = :ve_rut_cliente
        group by c.nro_cliente,
            replace(trim(to_char(c.numrun, '999G999G999')), ',', '.') || '-' || dvrun,
            c.pnombre || ' ' || c.snombre || ' ' || c.appaterno || ' ' || c.apmaterno,
            po.nombre_prof_ofic,
            to_char(c.fecha_nacimiento, 'dd') || ' de ' || to_char(c.fecha_nacimiento, 'month'),
            case
                when to_char(c.fecha_nacimiento, 'mm') = to_char(add_months(trunc(sysdate, 'mm'), 1), 'mm')
                then null
                
                else
                    'El cliente no está de cumpleaños en el mes procesado'
            end;
    exception
        when no_data_found then
            dbms_output.put_line('El cliente de RUT ' || :ve_rut_cliente || ' no existe en el sistema. Verifique el RUT del cliente y reintente.');
            return;
        when others then
            dbms_output.put_line('Se ha producido un error en la base de datos' || chr(10) || sqlerrm);
            return;
    end;

    if vs_observacion is not null then
    /* Si el cliente NO está de cumpleaños en el mes siguiente el monto de la giftcard es 0 */
        vl_montogiftcard := null;
    else
    /* Cliente de cumpleaños, calculamos monto de giftcard de acuerdo a rango de sus productos de inversión */

        /* Caso 1: Menor al rango 1 */
        if vs_montototalahorrado <= :ve_rango_01 then
            vl_montogiftcard := :ve_monto_giftcard_01;
        end if;

        /* Caso 2: Entre el rango 1 y el rango 2 */
        if vs_montototalahorrado > :ve_rango_01 and vs_montototalahorrado <= :ve_rango_02 then
            vl_montogiftcard := :ve_monto_giftcard_02;
        end if;

        /* Caso 3: Entre el rango 2 y el rango 3 */
        if vs_montototalahorrado > :ve_rango_02 and vs_montototalahorrado <= :ve_rango_03 then
            vl_montogiftcard := :ve_monto_giftcard_03;
        end if;

        /* Caso 4: Entre el rango 3 y el rango 4 */
        if vs_montototalahorrado > :ve_rango_03 and vs_montototalahorrado <= :ve_rango_04 then
            vl_montogiftcard := :ve_monto_giftcard_04;
        end if;

        /* Caso 5: Entre el rango 4 y el rango 5 */
        if vs_montototalahorrado > :ve_rango_04 and vs_montototalahorrado <= :ve_rango_05 then
            vl_montogiftcard := :ve_monto_giftcard_05;
        end if;

        /* Caso 6: Mayor que el rango 5, caso no especificado pero que se subentiende que debe ir nulo */
        if vs_montototalahorrado > :ve_rango_05 then
            vl_montogiftcard := null;
        end if;

    end if;

    /* Eliminamos el registro en la tabla cumpleanno_cliente para ese número de cliente específico para evitar errores de primary key*/
    begin
        delete from cumpleanno_cliente
        where nro_cliente = vs_nrocliente;
    exception
        when others then
            rollback;
            dbms_output.put_line('Se ha producido un error en la eliminación del registro en la tabla cumpleanno_cliente' || chr(10) || sqlerrm);
            return;
    end;

    /* Insertamos registro en la tabla cumpleanno_cliente */
    begin
        insert into cumpleanno_cliente
            (nro_cliente,
            run_cliente,
            nombre_cliente,
            profesion_oficio,
            dia_cumpleano,
            monto_gifcard,
            observacion)
        values
            (vs_nrocliente,
            vs_rutcliente,
            vs_nomcliente,
            vs_nombreprofofic,
            vs_diacumpleano,
            vl_montogiftcard,
            vs_observacion);
        exception
        when others then
            rollback;
            dbms_output.put_line('Se ha producido un error en la eliminación del registro en la tabla cumpleanno_cliente' || chr(10) || sqlerrm);
            return;
    end;

    /* Confirmamos la transacción en la base de datos */
    commit;

    dbms_output.put_line('Se ha ingresado el registro correctamente en la tabla cumpleanno_cliente.');

end;

/*
 *  Fin caso 2
 *
 */


/*
 *   Inicio caso 3
 *
 *  Requerimientos del proceso:
 *
 *  R1:     El proceso deberá modificar la tabla cuota_credito_cliente
 *  R2:     El número del cliente, el número de solicitud del crédito y la cantidad de cuantas que desea postergar son variables de entrada del proceso
 *  R3:     Para las nuevas cuotas el número de las cuotas serán números correlativos a partir de la última cuota del crédito que se está procesando
 *  R4:     Para las nuevas cuotas la fecha de vencimiento de las nuevas cuotas debe considerarse que serán los meses siguientes a la fecha de vencimiento de la última cuota del crédito que se está procesando
 *  R5:     Para las nuevas cuotas el monto de la cuota será el valor calculado según la tasa de interés
 *  R6:     Si el cliente solicitó más de un crédito el año anterior, a la fecha de pago de la cuota se le deberá asignar la misma fecha de vencimiento de esa cuota y al monto pagado se le debe asignar el valor de la cuota
 *  R7:     Todos los cálculos se deben realizar con sentencias PL/SQL
 *
 *  Variables de entrada:
 *
 *  ve_nro_cliente:                 (5, 67, 13)
 *  ve_nro_solic_credito:           (2001, 3004, 2004)  
 *  ve_cantidad_cuotas_postergar:   (2, 1, 1)
 *
 */


variable

    ve_numero_cliente               cliente.nro_cliente%type;
    ve_numero_solic_credito         credito_cliente.nro_solic_credito%type;
    ve_cantidad_cuotas_prorrogar    number(2);

declare

    K_HIPOTECARIO           credito.cod_credito%type := 1;
    K_CONSUMO               credito.cod_credito%type := 2;
    K_AUTOMOTRIZ            credito.cod_credito%type := 3;
    K_INTERESHIPOTECARIO    number(3,2) := 0.5;
    K_INTERESCONSUMO        number(3,2) := 1;
    K_INTERESAUTOMOTRIZ     number(3,2) := 2;

    vs_nrocliente           cliente.nro_cliente%type;
    vs_totalcreditos        number(2);
    vs_codcredito           credito.cod_credito%type;
    vs_totalcuotas          number(4);
    vs_fechaultimacuota     cuota_credito_cliente.fecha_venc_cuota%type;
    vs_cuotaapagar          cuota_credito_cliente.nro_cuota%type;
    vs_fechavenccuota       cuota_credito_cliente.fecha_venc_cuota%type;
    vs_valorcuota           cuota_credito_cliente.valor_cuota%type;
    
    vl_interes              number(3,2);

begin

    /* Recuperamos el total de créditos del cliente */
    begin
        select count(cc.nro_solic_credito) as total_creditos
        into vs_totalcreditos
        from credito_cliente cc
        where cc.nro_cliente = :ve_numero_cliente and
            extract(year from cc.fecha_solic_cred) = extract(year from sysdate) - 1;
    exception
        when others then
            dbms_output.put_line('Se ha producido un error en la base de datos' || chr(10) || sqlerrm);
            return;
    end;
    
    if vs_totalcreditos = 0 then
    /* Validamos que el cliente tenga créditos */
        dbms_output.put_line('El cliente de número ' || :ve_numero_cliente || ' no tiene créditos vigentes con el banco. Verifique el valor y reintente.');
        return;
    end if;

    /* Recuperamos datos del crédito, la última cuota definida y la fecha de vencimiento */    
    begin
        select cc.nro_cliente as nro_cliente,
            cc.cod_credito as cod_credito,
            ccc.nro_cuota as total_cuotas,
            ccc.fecha_venc_cuota as fecha_ultima_cuota
        into vs_nrocliente, 
            vs_codcredito,
            vs_totalcuotas,
            vs_fechaultimacuota
        from credito_cliente cc
        inner join cuota_credito_cliente ccc on cc.nro_solic_credito = ccc.nro_solic_credito
        where cc.nro_solic_credito = :ve_numero_solic_credito and
            ccc.nro_cuota = (select max(ccaux.nro_cuota)
                            from cuota_credito_cliente ccaux
                            where ccaux.nro_solic_credito = cc.nro_solic_credito);
    exception
        when no_data_found then
            dbms_output.put_line('El crédito de número de solicitud ' || :ve_numero_solic_credito || ' no existe en el sistema. Verifique el valor y reintente.');
            return;
        when others then
            dbms_output.put_line('Se ha producido un error en la base de datos' || chr(10) || sqlerrm);
            return;
    end;

    if :ve_numero_cliente <> vs_nrocliente then
    /* Validamos que el crédito indicado corresponda al cliente indicado */
        dbms_output.put_line('El crédito de número de solicitud ' || :ve_numero_solic_credito || ' no fue solicitado por el cliente de número de cliente ' || :ve_numero_cliente || '. Verifique los valores y reintente.');
        return;
    end if;


    /* Procedemos a condonar las cuotas si corresponde */
    if vs_totalcreditos > 1 then
    /* Si el cliente tiene más de un crédito, entonces se condona la última cuota */

        begin
            update cuota_credito_cliente
            set fecha_pago_cuota = fecha_venc_cuota,
                monto_pagado = valor_cuota,
                saldo_por_pagar = 0
            where nro_solic_credito = :ve_numero_solic_credito and
                nro_cuota = vs_totalcuotas;
        exception
            when others then
                dbms_output.put_line('Se ha producido un error en la base de datos' || chr(10) || sqlerrm);
                return;
        end;

        /* Confirmamos la transacción en la base de datos de la condonación */
        commit;

        dbms_output.put_line('Se ha realizado la condonación de la última cuota para el crédito seleccionado');

    else

        dbms_output.put_line('No corresponde la condonación de la última cuota para el crédito seleccionado');

    end if;

    /* Validaciones asociadas a la prórroga */
    if :ve_cantidad_cuotas_prorrogar <= 0 then
        dbms_output.put_line('No se puede prorrogar cuotas ya que debe ingresar una cantidad de cuotas a prorrogar mayor a 0');
        return;
    end if;

    if vs_codcredito not in (K_HIPOTECARIO, K_CONSUMO, K_AUTOMOTRIZ) then
        dbms_output.put_line('No se puede prorrogar cuotas para este tipo de crédito.');
        return;
    end if;


    /* Determinamos cuál es la cuota a pagar para prorrogarla (dejarla con monto pago 0 y fecha de pago actual). Además traemos la fecha de
    vencimiento y el monto para colocarlo en las cuotas nuevas que serán generadas */
    begin
        select ccc.nro_cuota,
            ccc.fecha_venc_cuota,
            ccc.valor_cuota
        into vs_cuotaapagar,
            vs_fechavenccuota,
            vs_valorcuota
        from cuota_credito_cliente ccc
        where ccc.nro_solic_credito = :ve_numero_solic_credito and
            ccc.nro_cuota = (select min(c.nro_cuota)
                            from cuota_credito_cliente c
                            where c.nro_solic_credito = ccc.nro_solic_credito and
                                c.fecha_pago_cuota is null and
                                c.monto_pagado is null);
    exception
        when no_data_found then
            dbms_output.put_line('El crédito de número de solicitud ' || :ve_numero_solic_credito || ' no tiene cuotas a pagar. No aplica la prórroga');
            return;
        when others then
            dbms_output.put_line('Se ha producido un error en la base de datos' || chr(10) || sqlerrm);
            return;
    end;


    /* Agregar cuotas en caso de que se solicite prórroga de alguna cuota */
    case vs_codcredito
        when K_HIPOTECARIO then

            /* Determinamos el porcentaje de interés dependiendo de la cantidad de cuotas a prorrogar */
            if :ve_cantidad_cuotas_prorrogar > 1 then
                vl_interes := K_INTERESHIPOTECARIO;
            else
                vl_interes := 0;
            end if;
        
            /* Prorrógamos la cuota a pagar */
            begin
                update cuota_credito_cliente
                set fecha_pago_cuota = sysdate,
                    monto_pagado = 0,
                    saldo_por_pagar = 0
                where nro_solic_credito = :ve_numero_solic_credito and
                    nro_cuota = vs_cuotaapagar;
            exception
                when others then
                    rollback;
                    dbms_output.put_line('Se ha producido un error en la base de datos' || chr(10) || sqlerrm);
                    return;
            end;

            /* Ingresamos la primera cuota extra debido a la prórroga */
            begin
                insert into cuota_credito_cliente
                    (nro_solic_credito,
                    nro_cuota,
                    fecha_venc_cuota,
                    valor_cuota,
                    fecha_pago_cuota,
                    monto_pagado,
                    saldo_por_pagar,
                    cod_forma_pago)
                values
                    (:ve_numero_solic_credito,
                    vs_totalcuotas + 1,
                    add_months(vs_fechaultimacuota, 1),
                    round(vs_valorcuota * (1 + (K_INTERESHIPOTECARIO / 100)), 0),
                    null,
                    null,
                    null,
                    null);
            exception
                when others then
                    rollback;
                    dbms_output.put_line('Se ha producido un error en la base de datos' || chr(10) || sqlerrm);
                    return;
            end;
            
            if :ve_cantidad_cuotas_prorrogar > 1 then
            /* Si corresponde, generamos una segunda cuota a prorrogar */

                /* Prorrógamos la segunda cuota a pagar */
                begin
                    update cuota_credito_cliente
                    set fecha_pago_cuota = sysdate,
                        monto_pagado = 0,
                        saldo_por_pagar = 0
                    where nro_solic_credito = :ve_numero_solic_credito and
                        nro_cuota = vs_cuotaapagar + 1;
                exception
                    when others then
                        dbms_output.put_line('Se ha producido un error en la base de datos' || chr(10) || sqlerrm);
                        return;
                end;
    
                /* Ingresamos la segunda cuota extra debido a la prórroga */
                begin
                    insert into cuota_credito_cliente
                        (nro_solic_credito,
                        nro_cuota,
                        fecha_venc_cuota,
                        valor_cuota,
                        fecha_pago_cuota,
                        monto_pagado,
                        saldo_por_pagar,
                        cod_forma_pago)
                    values
                        (:ve_numero_solic_credito,
                        vs_totalcuotas + 2,
                        add_months(vs_fechaultimacuota, 2),
                        round(vs_valorcuota * (1 + (K_INTERESHIPOTECARIO / 100)), 0),
                        null,
                        null,
                        null,
                        null);
                exception
                    when others then
                        rollback;
                        dbms_output.put_line('Se ha producido un error en la base de datos' || chr(10) || sqlerrm);
                        return;
                end;

            end if;
        
        when K_CONSUMO then

            /* Prorrógamos la cuota a pagar */
            begin
                update cuota_credito_cliente
                set fecha_pago_cuota = sysdate,
                    monto_pagado = 0,
                    saldo_por_pagar = 0
                where nro_solic_credito = :ve_numero_solic_credito and
                    nro_cuota = vs_cuotaapagar;
            exception
                when others then
                    rollback;
                    dbms_output.put_line('Se ha producido un error en la base de datos' || chr(10) || sqlerrm);
                    return;
            end;

            /* Ingresamos la cuota extra debido a la prórroga */
            begin
                insert into cuota_credito_cliente
                    (nro_solic_credito,
                    nro_cuota,
                    fecha_venc_cuota,
                    valor_cuota,
                    fecha_pago_cuota,
                    monto_pagado,
                    saldo_por_pagar,
                    cod_forma_pago)
                values
                    (:ve_numero_solic_credito,
                    vs_totalcuotas + 1,
                    add_months(vs_fechaultimacuota, 1),
                    round(vs_valorcuota * (1 + (K_INTERESCONSUMO / 100)), 0),
                    null,
                    null,
                    null,
                    null);
            exception
                when others then
                    rollback;
                    dbms_output.put_line('Se ha producido un error en la base de datos' || chr(10) || sqlerrm);
                    return;
            end;

        when K_AUTOMOTRIZ then

            /* Prorrógamos la cuota a pagar */
            begin
                update cuota_credito_cliente
                set fecha_pago_cuota = sysdate,
                    monto_pagado = 0,
                    saldo_por_pagar = 0
                where nro_solic_credito = :ve_numero_solic_credito and
                    nro_cuota = vs_cuotaapagar;
            exception
                when others then
                    rollback;
                    dbms_output.put_line('Se ha producido un error en la base de datos' || chr(10) || sqlerrm);
                    return;
            end;

            /* Ingresamos la cuota extra debido a la prórroga */
            begin
                insert into cuota_credito_cliente
                    (nro_solic_credito,
                    nro_cuota,
                    fecha_venc_cuota,
                    valor_cuota,
                    fecha_pago_cuota,
                    monto_pagado,
                    saldo_por_pagar,
                    cod_forma_pago)
                values
                    (:ve_numero_solic_credito,
                    vs_totalcuotas + 1,
                    add_months(vs_fechaultimacuota, 1),
                    round(vs_valorcuota * (1 + (K_INTERESAUTOMOTRIZ / 100)), 0),
                    null,
                    null,
                    null,
                    null);
            exception
                when others then
                    rollback;
                    dbms_output.put_line('Se ha producido un error en la base de datos' || chr(10) || sqlerrm);
                    return;
            end;

    end case;

    /* Confirmamos la transacción en la base de datos de la prórroga */
    commit;

    dbms_output.put_line('Se ha realizado correctamente la prórroga de las cuotas indicadas para el crédito y cliente específico');

end;

/*
 *  Fin caso 3
 *
 */

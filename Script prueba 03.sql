
/*
 *  Asignatura  :   MDY3131_005V - Programación de Base de Datos
 *
 *  Profesor    :   Eduardo Rojas Atao
 *  
 *  Fecha       :   viernes 24.06.2022
 *  
 *  Alumno      :   Héctor Zúñiga Luarte - hec.zuniga@duocuc.cl
 *  
 *  Prueba      :   N° 3
 *
 */

/* Instrucción para ver la salida por pantalla */
set serveroutput on;

/*
 *	Inicio caso 1
 */

/*
 *  Inicio trigger - Solución con variables
 */
create or replace trigger tr_consumo
after insert or update or delete of monto on consumo
for each row
declare

    vl_idhuesped          consumo.id_huesped%type;
    vl_montooriginal      total_consumos.monto_consumos%type;
    vl_montoantiguo       consumo.monto%type;
    vl_montonuevo         consumo.monto%type;

begin

    if inserting then

        vl_montonuevo := :new.monto;
        vl_idhuesped := :new.id_huesped;
        
        begin
            select monto_consumos
            into vl_montooriginal
            from total_consumos
            where id_huesped = vl_idhuesped;
        exception when others then
            return;
        end;

        begin        
            update total_consumos
            set monto_consumos = vl_montooriginal + vl_montonuevo
            where id_huesped = vl_idhuesped;
        exception when others then
            return;
        end;
        
        return;
    end if;

    if updating then
    
        vl_montoantiguo := :old.monto;
        vl_montonuevo := :new.monto;
        vl_idhuesped := :new.id_huesped;
        
        begin
            select monto_consumos
            into vl_montooriginal
            from total_consumos
            where id_huesped = vl_idhuesped;
        exception when others then
            return;
        end;

        begin
            update total_consumos
            set monto_consumos = vl_montooriginal + vl_montonuevo - vl_montoantiguo
            where id_huesped = vl_idhuesped;
        exception when others then
            return;
        end;
        
        return;
    end if;

    if deleting then
    
        vl_montoantiguo := :old.monto;
        vl_idhuesped := :old.id_huesped;
    
        begin    
            select monto_consumos
            into vl_montooriginal
            from total_consumos
            where id_huesped = vl_idhuesped;
        exception when others then
            return;
        end;

        begin
            update total_consumos
            set monto_consumos = vl_montooriginal - vl_montoantiguo
            where id_huesped = vl_idhuesped;
        exception when others then
            return;
        end;
        
        return;
    end if;

end;
/*
 *  Fin trigger - Solución con variables
 */


/*
 *  Inicio trigger - Solución con update
 */
create or replace trigger tr_consumo
after insert or update or delete of monto on consumo
for each row

begin

    if inserting then

        begin        
            update total_consumos
            set monto_consumos = monto_consumos + :new.monto
            where id_huesped = :new.id_huesped;
        exception when others then
            return;
        end;
        
        return;
    end if;

    if updating then
    
        begin
            update total_consumos
            set monto_consumos = monto_consumos + :new.monto - :old.monto
            where id_huesped = :new.id_huesped;
        exception when others then
            return;
        end;
        
        return;
    end if;

    if deleting then
    
        begin
            update total_consumos
            set monto_consumos = monto_consumos - :old.monto
            where id_huesped = :old.id_huesped;
        exception when others then
            return;
        end;
        
        return;
    end if;

end;
/*
 *  Fin trigger - Solución con update
 */

/*
 *	Inicio de scripts de modificación de datos
 */
insert into consumo (
    id_consumo,
    id_reserva,
    id_huesped,
    monto)
values (
    11527,
    1587,
    340039,
    100);
        
delete from consumo
where id_consumo = 10417;

update consumo
set monto = 56
where id_consumo = 10901;

update consumo
set monto = 80
where id_consumo = 11214;

/* Querys de revisión de datos (para antes y después del DML) */
select *
from consumo
where id_huesped = 340039 or
    id_consumo in (10901, 11214)
order by id_consumo asc;

select *
from total_consumos
where id_huesped in (340036, 340038, 340039, 340043)
order by id_huesped asc;

/* Restauramos los datos a su situación inicial */
rollback;

/*
 *	Fin de scripts de modificación de datos
 */

/*
 *	Fin caso 1
 */


/*
 *	Inicio caso 2
 */

/* Especificación del package */
create or replace package pck_consumo is

    /* Variables de uso global */
    vg_valordolar              number(4) := 840;

    /* Especificación de procedimientos y funciones */
    function f_montotours(ve_idhuesped number) return number;

end pck_consumo;

/* Cuerpo del package */
create or replace package body pck_consumo is

    /* Códigos de procedimientos y funciones */
    function f_montotours(ve_idhuesped number) return number is

        vs_montotour           number(6);

    begin

		begin
			select nvl(sum(ht.num_personas * t.valor_tour), 0) as monto_tour
			into vs_montotour
			from huesped_tour ht,
				tour t
			where ht.id_tour (+) = t.id_tour and
				ht.id_huesped = ve_idhuesped;
		exception when others then
			vs_montotour := 0;
		end;
		
        return vs_montotour;

    end f_montotours;

end pck_consumo;

/* Funcion de cálculo de monto de consumos */
create or replace function f_montoconsumos(ve_idhuesped number) return number is

	vs_montoconsumos		number(6);
    vl_sql                  varchar2(500);
    vl_nomsubprograma       reg_errores.nomsubprograma%type;
    vl_msgerror             reg_errores.msg_error%type;

begin

    vl_sql := 'select monto_consumos into :vs_montoconsumos from total_consumos where id_huesped = :ve_idhuesped';
    
    begin
        execute immediate vl_sql into vs_montoconsumos using ve_idhuesped;
    exception when others then

        vs_montoconsumos := 0;

        vl_nomsubprograma := 'Error en función f_montoconsumos al recuperar los consumos del huésped con ID = ' || ve_idhuesped;
        vl_msgerror := sqlerrm;

        /* Insertamos en la tabla de error */
        insert into reg_errores (
            id_error,
            nomsubprograma,
            msg_error)
        values (sq_error.nextval,
            vl_nomsubprograma,
            vl_msgerror);

    end;

	return vs_montoconsumos;

end f_montoconsumos;


/*
 *	Procedimiento principal
 */
create or replace procedure sp_detallehuespedes(ve_anoperiodo number, ve_mesperiodo number, ve_letrasuerte varchar2) as

    /* Cursor para recorrer los huéspedes con los valores de su alojamiento */
    cursor cr_huespedes is
        select h.id_huesped as id_huesped,
            h.appat_huesped || ' ' || h.apmat_huesped || ' ' || h.nom_huesped as nombre_huesped,
            sum(r.estadia * (hab.valor_habitacion + hab.valor_minibar)) as alojamiento   
        from huesped h,
            reserva r,
            detalle_reserva dr,
            habitacion hab
        where dr.id_habitacion = hab.id_habitacion and
            r.id_reserva = dr.id_reserva and
            h.id_huesped = r.id_huesped and
            extract(year from r.ingreso) = ve_anoperiodo and
            extract(month from r.ingreso) = ve_mesperiodo
        group by h.id_huesped,
            h.appat_huesped || ' ' || h.apmat_huesped || ' ' || h.nom_huesped
        order by h.appat_huesped || ' ' || h.apmat_huesped || ' ' || h.nom_huesped asc;

    /* Variables locales del problema */    
    vl_idhuesped            detalle_diario_huespedes.id_huesped%type;
    vl_nombrehuesped        detalle_diario_huespedes.nombre%type;
    vl_alojamiento          detalle_diario_huespedes.alojamiento%type;
    vl_consumosdolar        detalle_diario_huespedes.consumos%type;
    vl_consumos             detalle_diario_huespedes.consumos%type;
    vl_tours                detalle_diario_huespedes.tours%type;
    vl_subtotalpago         detalle_diario_huespedes.subtotal_pago%type;
    vl_factordescuento      number(5,2);
    vl_descuentoconsumos    detalle_diario_huespedes.descuento_consumos%type;
    vl_descuentosuerte      detalle_diario_huespedes.descuentos_suerte%type;
    vl_total                detalle_diario_huespedes.total%type;
    vl_nomsubprograma       reg_errores.nomsubprograma%type;
    vl_msgerror             reg_errores.msg_error%type;

begin

    /* Truncado de las tablas */
    execute immediate 'truncate table reg_errores';
    execute immediate 'truncate table detalle_diario_huespedes';

    /* Recorremos el cursor con los huéspedes */
    for reg_huespedes in cr_huespedes loop

        vl_idhuesped := reg_huespedes.id_huesped;
        vl_nombrehuesped := reg_huespedes.nombre_huesped;
        vl_alojamiento := pck_consumo.vg_valordolar * reg_huespedes.alojamiento;

        vl_consumosdolar := f_montoconsumos(vl_idhuesped);

        vl_consumos := pck_consumo.vg_valordolar * vl_consumosdolar;

        vl_tours := pck_consumo.vg_valordolar * pck_consumo.f_montotours(vl_idhuesped);

        vl_subtotalpago := vl_alojamiento + vl_consumos + vl_tours;

        /* Determinamos el porcentaje de descuento */
        begin
            select tc.pct as factor_descuento
            into vl_factordescuento
            from tramos_consumos tc
            where vl_consumosdolar between tc.vmin_tramo and tc.vmax_tramo;
        exception when others then
            vl_factordescuento := 0;
        end;

        /* Calculamos el descuento */
        vl_descuentoconsumos := vl_consumos * vl_factordescuento;

        /* Calculamos el descuento por suerte */
        if lower(substr(vl_nombrehuesped, 1, 1)) = lower(ve_letrasuerte) then
            vl_descuentosuerte := round(vl_subtotalpago * 0.9, 0);
        else
            vl_descuentosuerte := 0;
        end if;

        vl_total := vl_subtotalpago - vl_descuentoconsumos - vl_descuentosuerte;

        /* Insertamos en la tabla detalle_diario_huespedes */
        begin
            insert into detalle_diario_huespedes (
                id_huesped,
                nombre,
                alojamiento,
                consumos,
                tours,
                subtotal_pago,
                descuento_consumos,
                descuentos_suerte,
                total)
            values (
                vl_idhuesped,
                vl_nombrehuesped,
                vl_alojamiento,
                vl_consumos,
                vl_tours,
                vl_subtotalpago,
                vl_descuentoconsumos,
                vl_descuentosuerte,
                vl_total);
        exception when others then

            vl_nomsubprograma := 'Instrucción insert a tabla detalle_diario_huespedes';
            vl_msgerror := 'Error en inserción: ' || sqlerrm;

            dbms_output.put_line(vl_nomsubprograma || ' - ' || vl_msgerror);

            /* Insertamos en la tabla de error */
            insert into reg_errores (
                id_error,
                nomsubprograma,
                msg_error)
            values (sq_error.nextval,
                vl_nomsubprograma,
                vl_msgerror);

        end;
    
    end loop;

	return;

end sp_detallehuespedes;


/*
 *  Inicio  bloque para ejecutar el proceso
 */
begin

    sp_detallehuespedes(2021, 8, 'M');

end;
/*
 *  Fin  bloque para ejecutar el proceso
 */


/*
 *	Fin caso 2
 */


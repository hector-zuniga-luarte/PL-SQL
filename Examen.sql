
/*
 *  Asignatura  :   MDY3131_005V - Programación de Base de Datos
 *
 *  Profesor    :   Eduardo Rojas Atao
 *  
 *  Fecha       :   martes 12.07.2022
 *  
 *  Alumno      :   Héctor Zúñiga Luarte - hec.zuniga@duocuc.cl
 *  
 *  Prueba      :   Examen transversal
 *
 */

/* Instrucción para ver la salida por pantalla */
set serveroutput on;

/*
 *	Inicio ejercicio 1
 */

create or replace trigger tr_valor_compra
after update of valorcompradolar on producto
for each row

begin

    if updating then

        /* Verificamos que los valores no sean nulos ni cero */
        if :new.valorcompradolar = 0 or :new.valorcompradolar is null or :old.valorcompradolar = 0 or :old.valorcompradolar is null then
            return;
        end if;

        /* Verificamos que se trate de un producto no nacional y cuando el aumento sea mayor a 10% */
        if (round((:new.valorcompradolar / :old.valorcompradolar), 2) >= 1.1) and (:old.codpais <> 1) then
        
            update detalle_boleta
            set totallinea = totallinea * 1.1
            where codproducto = :old.codproducto;
        else
        
            update detalle_boleta
            set totallinea = totallinea * 0.8,
                vunitario = vunitario * 0.8
            where codproducto = :old.codproducto;
        
        end if;
        
        return;
    end if;

end;

/*
 *  Fin ejercicio 1
 */


/*
 *  Inicio ejercicio 2
 */

/* Inicio configuración de carpeta de imágenes */

/* A ejecutar en esquema system */
create or replace directory dir_etmdy_fotos as 'c:/imagenes/fotos_productos_prom';

grant read on directory dir_etmdy_fotos to etmdy_fb;

/* Fin configuración de carpeta de imágenes */

/* Inicio procedimiento */

create or replace procedure sp_actualizafotos(ve_tipoejecucion varchar2, ve_tipoactualizacion varchar2) is

KL_MANUAL                   varchar2(1) := 'M';
KL_AUTOMATICA               varchar2(1) := 'A';
KL_TODOS                    varchar2(1) := 'T';
KL_SINFOTOS                 varchar2(1) := 'S';
KL_HORAMIN                  varchar2(8) := '23:00:00';
KL_HORAMAX                  varchar2(8) := '23:59:59';
KL_EXTENSIONIMAGENES        varchar2(6) := '.jpg';
KL_DIRFOTOS                 varchar2(100) := 'DIR_ETMDY_FOTOS';

vl_horamin                  date;
vl_horamax                  date;

vl_codpromocion             promocion.codpromocion%type;
vl_nomarchivo               varchar2(100);

vl_archivo                  bfile;
vl_existearchivo            number(2);
vl_cantfotosactualizadas    number(10) := 0;
vl_totalfotos               number(10) := 0;
vl_mensaje                  varchar2(200);

/* Cursor para recorrer las promociones */
cursor cr_promociones is
    select codpromocion as codpromocion,
        codpromocion || '.jpg' as nomarchivo
    from promocion
    where decode(ve_tipoactualizacion, KL_TODOS, 1, dbms_lob.fileexists(bfilename(KL_DIRFOTOS, codpromocion || KL_EXTENSIONIMAGENES))) = 1
    order by codpromocion;

begin

    /* Validamos parámetros de entrada */
    if trim(upper(ve_tipoejecucion)) not in (KL_MANUAL, KL_AUTOMATICA) then
        dbms_output.put_line('Error: El tipo de ejecución debe ser ' || KL_MANUAL || ' (manual) o ' || KL_AUTOMATICA || ' (automática). Ingrese un valor válido y reintente.');
        return;
    end if;

    if trim(upper(ve_tipoactualizacion)) not in (KL_TODOS, KL_SINFOTOS) then
        dbms_output.put_line('Error: El tipo de actualización debe ser ' || KL_TODOS || ' (todos los registros) o ' || KL_SINFOTOS || ' (solo los que no tienen fotos). Ingrese un valor válido y reintente.');
        return;
    end if;

    /* Validamos que si se trata de una actualización automática, solo pueda ser ejecutada en la hora definida */
    vl_horamin := to_date(to_char(sysdate, 'dd/mm/yyyy') || ' ' || KL_HORAMIN, 'dd/mm/yyyy hh24:mi:ss');
    vl_horamax := to_date(to_char(sysdate, 'dd/mm/yyyy') || ' ' || KL_HORAMAX, 'dd/mm/yyyy hh24:mi:ss');

    if not (sysdate between vl_horamin and vl_horamax) and trim(upper(ve_tipoejecucion)) = KL_AUTOMATICA then
    /* Si la ejecución es automática pero estamos fuera de la hora límite, el proceso no se ejecuta */
        dbms_output.put_line('Error: Ejecución automática ejecutada a las ' || to_char(sysdate, 'hh24:mi:ss') || ' que está fuera de la hora límite entre las ' || KL_HORAMIN || ' y las ' || KL_HORAMAX || ' hrs.');
        return;
    end if;

    for reg_promociones in cr_promociones loop

        vl_totalfotos := vl_totalfotos + 1;

        vl_codpromocion := reg_promociones.codpromocion;
        vl_nomarchivo := reg_promociones.nomarchivo;
        -- dbms_output.put_line('vl_codpromocion = ' || vl_codpromocion);
        -- dbms_output.put_line('vl_nomarchivo = ' || vl_nomarchivo);

        /* Si el registro no tiene fotos, no se actualiza */
        vl_archivo := bfilename(KL_DIRFOTOS, vl_nomarchivo);
        vl_existearchivo := dbms_lob.fileexists(vl_archivo);

        if vl_existearchivo = 1 then
            begin
                update promocion
                set imagen = vl_archivo
                where codpromocion = vl_codpromocion;
            exception when others then
                dbms_output.put_line('Error: Se ha producido un error al ejecutar la actualización de la imagen de la promoción de código ' || vl_codpromocion || chr(10) || sqlerrm);
                continue;
            end;

            vl_cantfotosactualizadas := vl_cantfotosactualizadas + 1;

        end if;

        -- dbms_output.put_line('vl_existearchivo = ' || vl_existearchivo);
        -- dbms_output.put_line('');

    end loop;

    -- dbms_output.put_line('ve_tipoejecucion = ' || ve_tipoejecucion);
    -- dbms_output.put_line('ve_tipoactualizacion = ' || ve_tipoactualizacion);
    -- dbms_output.put_line('vl_horamin = ' || to_char(vl_horamin, 'dd/mm/yyyy hh24:mi:ss'));
    -- dbms_output.put_line('vl_horamax = ' || to_char(vl_horamax, 'dd/mm/yyyy hh24:mi:ss'));

    commit;

    if vl_cantfotosactualizadas = 0 then
        vl_mensaje := 'No se actualizó ninguna imagen de un total de ' || vl_totalfotos;
    elsif vl_cantfotosactualizadas = 1 then
        vl_mensaje := '1 imagen actualizada de un total de ' || vl_totalfotos;
    else
        vl_mensaje := vl_cantfotosactualizadas || ' imágenes actualizadas de un total de ' || vl_totalfotos;
    end if;

    dbms_output.put_line(vl_mensaje);

end sp_actualizafotos;

/* Fin procedimiento */

/*
 *  Fin ejercicio 2
 */

/*
 *  Inicio ejercicio 3
 */

/*
 *	Inicio caso 2
 */

/* Especificación del package */
create or replace package pck_pagovendedor is

    /* Variables de uso global */
	vg_retornoerroneo			number(3) := 0;
    vg_porcentajemovilizacion	number(3) := 5;
	vg_porcentajeprevision		number(3) := 13;
	vg_porcentajesalud			number(3) := 7;

    /* Especificación de procedimientos y funciones */
    function f_factoraumento(ve_idvendedor number) return number;
	
	procedure sp_errores(ve_rutinaerror varchar2, ve_descriperror varchar2);
	

end pck_pagovendedor;

/* Cuerpo del package */
create or replace package body pck_pagovendedor is

    /* Códigos de procedimientos y funciones */
    function f_factoraumento(ve_idvendedor number) return number is

        vs_porchonorario			rangos_sueldos.porc_honorario%type;
		vl_sueldobase				vendedor.sueldo_base%type;

    begin
	
		/* Recuperamos el sueldo del vendedor */
		begin
		
			select sueldo_base
			into vl_sueldobase
			from vendedor
			where id_vendedor = ve_idvendedor;
		
		exception when others then
			sp_errores('f_factoraumento', 'Error al recuperar el sueldo del vendedor de id = ' || ve_idvendedor || chr(10) || sqlerrm);
			return vg_retornoerroneo;
		end;

		/* Recuperamos el factor de aumento de acuerdo a la tabla de rangos definida */
		begin
		
			select porc_honorario
			into vs_porchonorario
			from rangos_sueldos
			where vl_sueldobase between sueldo_min and sueldo_max;
		
		exception when others then
			sp_errores('f_factoraumento', 'Error al recuperar factor de aumento del vendedor de id ' || ve_idvendedor || ' de acuerdo a su sueldo base' || chr(10) || sqlerrm);
			return vg_retornoerroneo;
		end;
		
        return vs_porchonorario;

    end f_factoraumento;
	
	procedure sp_errores(ve_rutinaerror varchar2, ve_descriperror varchar2) is
	
		vl_sql				varchar2(500);
	
	begin
	
		vl_sql := 'insert into error_procesos_mensuales (correl_error, rutina_error, descrip_error) values (seq_error.nextval, :ve_rutinaerror, :ve_descriperror)';

		begin
		
			execute immediate vl_sql using ve_rutinaerror, ve_descriperror;
			
		exception when others then
		
			dbms_output.put_line('Se ha producido un error en la inserción en tabla error_procesos_mensuales' || chr(10) || sqlerrm);
			return;
		
		end;
	
	end sp_errores;
	

end pck_pagovendedor;

/* Funcion de cálculo de asignacion por colación */
create or replace function f_colacionvendedor(ve_idvendedor number) return number is

	vs_montocolacion		vendedor.sueldo_base%type;
	
	vl_sueldobase			vendedor.sueldo_base%type;
	vl_porcaumento			rango_aumento_porc_col.porc_aumento%type;
	vl_edad					number(3);

begin

	/* Recuperamos sueldo base y la edad del vendedor */
    begin
        
		select sueldo_base,
			trunc(months_between(sysdate, fecha_nac) / 12, 0) as edad
		into vl_sueldobase, 
			vl_edad
		from vendedor
		where id_vendedor = ve_idvendedor;
		
    exception when others then
		pck_pagovendedor.sp_errores('f_colacionvendedor', 'Error al recuperar la edad del vendedor de id = ' || ve_idvendedor || chr(10) || sqlerrm);
		return pck_pagovendedor.vg_retornoerroneo;
    end;

	/* Recuperamos la asignación de colación de acuerdo a sueldo base y factor en base a la edad */
	begin
	
		select porc_aumento
		into vl_porcaumento
		from rango_aumento_porc_col
		where vl_edad between edad_min and edad_max;
    
	exception when others then
		pck_pagovendedor.sp_errores('f_colacionvendedor', 'Error al recuperar el porcentaje de aumento del vendedor de id = ' || ve_idvendedor ||  chr(10) || sqlerrm);
		return pck_pagovendedor.vg_retornoerroneo;
	end;
	
	/* Calculamos el porcentaje por colación */
	vs_montocolacion := round((vl_sueldobase * vl_porcaumento) / 100, 0);
	
	return vs_montocolacion;

end f_colacionvendedor;


/*
 *	Procedimiento principal
 */
create or replace procedure sp_pagovendedor(ve_anoperiodo number, ve_mesperiodo number) as

    /* Cursor para recorrer los huéspedes con los valores de su alojamiento */
    cursor cr_vendedores is
		select id_vendedor as id_vendedor,
			rutvendedor as rut_vendedor,
			nombre as nom_vendedor,
			sueldo_base as sueldo_base,
			comision as porc_comision
		from vendedor
		where codcomuna in (2, 4); /* Santiago y Ñuñoa */

    /* Variables locales del problema */    
    vl_mesano	            varchar2(6);
	vl_idvendedor			vendedor.id_vendedor%type;
    vl_rutvendedor	        vendedor.rutvendedor%type;
    vl_nomvendedor          vendedor.nombre%type;
    vl_sueldobase	        vendedor.sueldo_base%type;
    vl_comisionmes	        vendedor.sueldo_base%type;
	vl_porccomision			vendedor.comision%type;
	vl_porcaumento			rangos_sueldos.porc_honorario%type;
    vl_colacion		        vendedor.sueldo_base%type;
    vl_movilizacion			vendedor.sueldo_base%type;
    vl_prevision			vendedor.sueldo_base%type;
    vl_salud				vendedor.sueldo_base%type;
    vl_totalpagar			vendedor.sueldo_base%type;
	
	vl_cantboletas			number(6);
	vl_cantfacturas			number(6);
	
	vl_mesanno				varchar2(6);
	

begin

	if ve_anoperiodo <= 2000 then
		dbms_output.put_line('Ingrese un años válido (mayor a 2000)');
		return;
	end if;
	
	if ve_mesperiodo not in (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12) then
		dbms_output.put_line('Ingrese un mes válido (valor entero entre 1 y 12)');
		return;
	end if;

	vl_mesanno := to_char(ve_anoperiodo * 100 + ve_mesperiodo);

    /* Truncado de las tablas */
    execute immediate 'truncate table error_procesos_mensuales';
    execute immediate 'truncate table pago_vendedor';

    /* Recorremos el cursor con los huéspedes */
    for reg_vendedores in cr_vendedores loop

        vl_idvendedor := reg_vendedores.id_vendedor;
        vl_rutvendedor := reg_vendedores.rut_vendedor;
        vl_nomvendedor := reg_vendedores.nom_vendedor;
        vl_sueldobase := reg_vendedores.sueldo_base;
        vl_porccomision := reg_vendedores.porc_comision;
		
		/* Calculamos la comisión */
		vl_comisionmes := round(vl_sueldobase * vl_porccomision, 0);

		/* Calculamos la movilización */
		vl_movilizacion := round((vl_sueldobase * pck_pagovendedor.vg_porcentajemovilizacion) / 100, 0);
		
		/* Calculamos el monto de la previsión */
		vl_prevision := round((vl_sueldobase * pck_pagovendedor.vg_porcentajeprevision) / 100, 0);

		/* Calculamos el monto en salud */
		vl_salud := round((vl_sueldobase * pck_pagovendedor.vg_porcentajesalud) / 100, 0);
		
		vl_porcaumento := pck_pagovendedor.f_factoraumento(vl_idvendedor);
    
		/* Recuperamos la asignación por colación */
		vl_colacion := f_colacionvendedor(vl_idvendedor);
		
		vl_totalpagar := vl_sueldobase + vl_comisionmes + vl_movilizacion + vl_colacion - vl_prevision - vl_salud;
	
		--dbms_output.put_line('vl_idvendedor = ' || vl_idvendedor);
		--dbms_output.put_line('vl_rutvendedor = ' || vl_rutvendedor);
		--dbms_output.put_line('vl_nomvendedor = ' || vl_nomvendedor);
		--dbms_output.put_line('vl_sueldobase = ' || vl_sueldobase);
		--dbms_output.put_line('vl_porccomision = ' || vl_porccomision);
		--dbms_output.put_line('vl_porcaumento = ' || vl_porcaumento);
		--dbms_output.put_line('vl_comisionmes = ' || vl_comisionmes);
		--dbms_output.put_line('vl_colacion = ' || vl_colacion);
		--dbms_output.put_line('vl_movilizacion = ' || vl_movilizacion);
		--dbms_output.put_line('vl_prevision = ' || vl_prevision);
		--dbms_output.put_line('vl_salud = ' || vl_salud);
		--dbms_output.put_line('vl_totalpagar = ' || vl_totalpagar);
		--dbms_output.put_line(''); 
		
		begin
		
			insert into pago_vendedor (
				mes_anno,
				rutvendedor,
				nomvendedor,
				sueldo_base,
				comision_mes,
				colacion,
				movilizacion,
				prevision,
				salud,
				total_pagar)
			values (
				vl_mesanno,
				vl_rutvendedor,
				vl_nomvendedor,
				vl_sueldobase,
				vl_comisionmes,
				vl_colacion,
				vl_movilizacion,
				vl_prevision,
				vl_salud,
				vl_totalpagar);
		
		exception when others then
			pck_pagovendedor.sp_errores('sp_pagovendedor', 'Error al insertar dato en tabla pago_vendedor' || chr(10) || sqlerrm);
		end;
	
	
    end loop;

	return;

end sp_pagovendedor;

/*
 *  Fin ejercicio 3
 */

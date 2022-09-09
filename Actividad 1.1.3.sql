/*
 *  MDY3131_005V - Programación de Base de Datos
 *  
 *  Héctor Zúñiga Luarte    - hec.zuniga@duocuc.cl
 *  
 *  Actividad 1.1.3 - Recuperando datos en un bloque PL/SQL
 *
 */

/* Instrucción para ver la salida por pantalla */
set serveroutput on;


/*
 *  Inicio caso 1
 *
 *  RUT's de prueba:
 *      11846972
 *      18560875
 */
declare

    ve_porcentaje_bonificacion number(3);
    ve_rut_empleado number(10);

    vs_nombre varchar(50);
    vs_rut varchar(20);     
    vs_sueldo varchar(30);
    vs_bonif varchar(30);
    vl_titulo varchar(500);

begin

    begin
        select e.nombre_emp || ' ' || e.appaterno_emp || ' ' || e.apmaterno_emp,
            replace(trim(to_char(e.numrut_emp, '99G999G999') || '-' || e.dvrut_emp), ',', '.'),
            trim(to_char(sueldo_emp, '$99G999G999') || '.-'),
            trim(to_char((sueldo_emp * :ve_porcentaje_bonificacion) / 100, '$99G999G999') || '.-')
        into vs_nombre,
            vs_rut,
            vs_sueldo,
            vs_bonif
        from empleado e
        where numrut_emp = :ve_rut_empleado;
    exception
        when no_data_found then
            dbms_output.put_line('ERROR:' || chr(10) || 'El empleado de RUT ' || :ve_rut_empleado || ' no existe en el sistema. Verifique el RUT y reintente.');
            return;
        when others then
            dbms_output.put_line('ERROR:' || chr(10) || 'Error de base de datos' || chr(10) || sqlerrm);
            return;
    end;

    vl_titulo := Upper('Datos cálculo bonificación extra del ' || to_char(:ve_porcentaje_bonificacion) || '% del sueldo');

    dbms_output.put_line(vl_titulo);
    dbms_output.put_line(trim(lpad(' ', length(vl_titulo), '-')));
    dbms_output.put_line('Nombre empleado:    ' || vs_nombre);
    dbms_output.put_line('RUT:                ' || vs_rut);
    dbms_output.put_line('Sueldo:             ' || vs_sueldo);
    dbms_output.put_line('Bonificación extra: ' || vs_bonif);
    
end;

/*
 *  Fin caso 1
 *
 */


/*
 *  Inicio caso 2
 *
 *  RUT's de prueba:
 *      
 *      12487147
 *      12861354
 *      13050258
 */
declare

	ve_rut_empleado number(10);

	vs_nombre varchar(50);
	vs_rut varchar(20);     
	vs_sueldo varchar(30);
	vs_estadocivil varchar(40);
	vl_titulo varchar(500);

begin

    begin
        select c.nombre_cli || ' ' || c.appaterno_cli || ' ' || c.apmaterno_cli,
            replace(trim(to_char(c.numrut_cli, '99G999G999') || '-' || c.dvrut_cli), ',', '.'),
            trim(to_char(c.renta_cli, '$99G999G999') || '.-'),
            ec.desc_estcivil
        into vs_nombre,
            vs_rut,
            vs_sueldo,
            vs_estadocivil
        from cliente c
        inner join estado_civil ec on c.id_estcivil = ec.id_estcivil
        where numrut_cli = :ve_rut_empleado;
    exception
        when no_data_found then
            dbms_output.put_line('ERROR:' || chr(10) || 'El empleado de RUT ' || :ve_rut_empleado || ' no existe en el sistema. Verifique el RUT y reintente.');
            return;
        when others then
            dbms_output.put_line('ERROR:' || chr(10) || 'Error de base de datos' || chr(10) || sqlerrm);
            return;
    end;

	vl_titulo := Upper('Datos del cliente');

    dbms_output.put_line(vl_titulo);
    dbms_output.put_line(trim(lpad(' ', length(vl_titulo), '-')));
    dbms_output.put_line('Nombre empleado: ' || vs_nombre);
    dbms_output.put_line('RUT:             ' || vs_rut);
    dbms_output.put_line('Estado civil:    ' || vs_estadocivil);
    dbms_output.put_line('Sueldo:          ' || vs_sueldo);
    
end;

/*
 *  Fin caso 2
 *
 */


/*
 *  Inicio caso 3
 *
 *  RUT's de prueba:
 *      
 *      12260812
 *      11999100
 *      12899759 (RUT con sueldo fuera de rango)
 */
declare

    ve_rut_empleado number(10);
    ve_porcentaje_simulacion_1 number(3,1);
    ve_porcentaje_simulacion_2 number(3,1);
    ve_rango_inferior_simulacion_2 number(10);
    ve_rango_superior_simulacion_2 number(10);

    vs_nombre varchar(50);
    vs_rut varchar(20);     
    vs_sueldo varchar(30);
    vl_titulo varchar(500);
    vs_sueldoreajustado1 varchar(200);
    vs_montoreajuste1 varchar(200);
    vs_sueldoreajustado2 varchar(200);
    vs_montoreajuste2  varchar(200);    


begin

    begin
        select e.nombre_emp || ' ' || e.appaterno_emp || ' ' || e.apmaterno_emp,
            replace(trim(to_char(e.numrut_emp, '99G999G999') || '-' || e.dvrut_emp), ',', '.'),
            trim(to_char(sueldo_emp, '$99G999G999') || '.-'),
            trim(to_char((sueldo_emp * (1 + :ve_porcentaje_simulacion_1 / 100)), '$99G999G999') || '.-'),
            trim(to_char((sueldo_emp * (:ve_porcentaje_simulacion_1 / 100)), '$99G999G999') || '.-'),
            case when sueldo_emp between :ve_rango_inferior_simulacion_2 and :ve_rango_superior_simulacion_2
                then
                    trim(to_char((sueldo_emp * (1 + :ve_porcentaje_simulacion_2 / 100)), '$99G999G999') || '.-')
                else
                    'No corresponde reajuste debido a que sueldo está fuera del rango.'
            end,
            case when sueldo_emp between :ve_rango_inferior_simulacion_2 and :ve_rango_superior_simulacion_2
                then
                    trim(to_char((sueldo_emp * (:ve_porcentaje_simulacion_2 / 100)), '$99G999G999') || '.-')
                else
                    'No corresponde reajuste debido a que sueldo está fuera del rango.'
            end
        into
            vs_nombre,
            vs_rut,
            vs_sueldo,
            vs_sueldoreajustado1,
            vs_montoreajuste1,
            vs_sueldoreajustado2,
            vs_montoreajuste2        
        from empleado e
        where numrut_emp = :ve_rut_empleado;
    exception
        when no_data_found then
            dbms_output.put_line('ERROR:' || chr(10) || 'El empleado de RUT ' || :ve_rut_empleado || ' no existe en el sistema. Verifique el RUT y reintente.');
            return;
        when others then
            dbms_output.put_line('ERROR:' || chr(10) || 'Error de base de datos' || chr(10) || sqlerrm);
            return;
    end;

    dbms_output.put_line(trim(lpad(' ', length(vl_titulo), '-')));
    dbms_output.put_line('Nombre empleado:   ' || vs_nombre);
    dbms_output.put_line('RUT:               ' || vs_rut);

    dbms_output.put_line(chr(10) || 'SIMULACIÓN 1: Aumentar en ' || trim(to_char(:ve_porcentaje_simulacion_1, '999.9')) || '% el salario de todos los empleados');
    dbms_output.put_line('Sueldo actual:     ' || vs_sueldo);
    dbms_output.put_line('Sueldo reajustado: ' || vs_sueldoreajustado1);
    dbms_output.put_line('Reajuste:          ' || vs_montoreajuste1);

    dbms_output.put_line(chr(10) || 'SIMULACIÓN 2: Aumentar en ' || trim(to_char(:ve_porcentaje_simulacion_2, '999.9')) || '% el salario de los empleados que poseen salarios entre ' || trim(to_char(:ve_rango_inferior_simulacion_2, '$9G999G999') || '.-') || ' y ' || trim(to_char(:ve_rango_superior_simulacion_2, '$9G999G999') || '.-'));
    dbms_output.put_line('Sueldo actual:     ' || vs_sueldo);
    dbms_output.put_line('Sueldo reajustado: ' || vs_sueldoreajustado2);
    dbms_output.put_line('Reajuste:          ' || vs_montoreajuste2);
    
end;

/*
 *  Fin caso 3
 *
 */

/*
 *  Inicio caso 4
 *
 *  Tipos de propiedad de prueba:
 *      
 *      'A':    Casa sin Amoblar
 *      'B':    Casa Amoblada
 *      'C':    Departamento sin Amoblar
 *      'D':    Departamento Amoblado
 *      'E':    Local Comercial
 *      'F':    Parcela sin Casa
 *      'G':    Parcela con Casa
 *      'H':    Sitio
 */

declare

    ve_id_tipo_propiedad varchar(1);
    
    vs_desctipopropiedad varchar(50);
    vs_totalpropiedades varchar(50);
    vs_montototalpropiedades varchar(50);


begin

    begin
    
        select nvl(tp.desc_tipo_propiedad, 0),
            nvl(count(pa.nro_propiedad), 0),
            trim(to_char(nvl(sum(p.valor_arriendo), 0), '$99G999G99')) || '.-'
        into 
            vs_desctipopropiedad,
            vs_totalpropiedades,
            vs_montototalpropiedades
        from propiedad_arrendada pa
            inner join propiedad p on pa.nro_propiedad = p.nro_propiedad
            inner join tipo_propiedad tp on p.id_tipo_propiedad = tp.id_tipo_propiedad
        where p.id_tipo_propiedad = :ve_id_tipo_propiedad
        group by tp.desc_tipo_propiedad;
    exception
        when no_data_found then
            dbms_output.put_line('ERROR:' || chr(10) || 'El tipo de propiedad ' || :ve_id_tipo_propiedad || ' no existe en el sistema. Verifique el valor y reintente.');
            return;
        when others then
            dbms_output.put_line('ERROR:' || chr(10) || 'Error de base de datos' || chr(10) || sqlerrm);
            return;
    end;

    dbms_output.put_line('Resumen de:               ' || vs_desctipopropiedad);
    dbms_output.put_line('Total de propiedades      ' || vs_totalpropiedades);
    dbms_output.put_line('valor total de arriendos: ' || vs_montototalpropiedades);
    
end;

/*
 *  Fin caso 4
 *
 */
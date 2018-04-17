create or replace PROCEDURE "BX_CARGA_BLK_LISTA_SARLAFT" (
  i_usuario                  VARCHAR2,
  i_ip                       VARCHAR2,
  i_nombre_maquina           VARCHAR2)

/*
_________________________________________________________________________________________
 Program : BX_CARGA_BLK_LISTA_SARLAFT
 Author  : Ing. William Steven Pedraza
 Modificado :Ing Julian Lagos
 Date    : Jun 2017
 Obs     : Procedimiento para realizar el cargue del archvio de lista de inhibitorios Sarlaft
 Version : 1.0
 Review  :
_________________________________________________________________________________________
*/



AS
   stoo_rowcnt                     INTEGER;
   stoo_errmsg                     VARCHAR2(1000);
   v_code                          NUMBER;
   v_fecha_cargue                  VARCHAR2(8);
   v_fecha_plano                   VARCHAR2(8);
   v_valida_fecha_plano            number;
   v_nro_cargue                    NUMBER;
   v_nro_registros                 NUMBER;
   v_cuenta_nuevos                 NUMBER ;
   V_BORRADOS_TOTALES                NUMBER ;
   V_FLAG_UPDATE                   NUMBER :=0;
   v_cuenta_nuevos_TOTALES         NUMBER :=0;
   V_CUENTA_UPDATE_TOTALES         NUMBER :=0;
   i_truncar_tablas                VARCHAR2 (250);
   v_cuenta_lista_fiscalia         number;
   I_VALIDATE_TIPO_DE_L            NUMBER;
   I_DESCRIPCION_TERCERO           VARCHAR2(500 BYTE);
   I_CARACTERISTICA_LAVADO1        VARCHAR2(900 BYTE);
  I_CARACTERISTICA_LAVADO2         VARCHAR2(500 BYTE);
  I_CARACTERISTICA_LAVADO3         VARCHAR2(500 BYTE);
  I_IDENTIFICACION_FIS             NUMBER(11,0);
  I_CLASE_DOCUMENTO_FIS            VARCHAR2(3 BYTE);
  I_USUARIO_ACTUALIZA              VARCHAR2(30 BYTE);
  I_FECHA_ACTUALIZA                DATE;
  I_ORIGEN                         VARCHAR2(3 BYTE);
  I_ESTADO                         NUMBER(1,0);  
  I_A_USUARIO VARCHAR2(200 BYTE);
  I_A_IP VARCHAR2(200 BYTE);
  I_A_NOMBRE_MAQUINA VARCHAR2(200 BYTE);
  I_DIGITO_VERIFICACION  NUMBER(1,0);
  I_NOVEDAD NUMBER(2,0);
  I_CALIFICADOR NUMBER(2,0);
  I_NOMBRES VARCHAR2(20 BYTE);
  I_PRIMER_APELLIDO VARCHAR2(20 BYTE);
  I_SEGUNDO_APELLIDO VARCHAR2(20 BYTE);
  I_SUCURSAL NUMBER(4,0);
  I_VALOR NUMBER(16,0);
  I_DECIMALES NUMBER(2,0);
  I_FECHA_ESTUDIO DATE;
  I_CODIGOCIIU NUMBER(11,0);
  I_ACTIVIDAD_ECONOMICA VARCHAR2(20 BYTE);
  I_CUENTA VARCHAR2(18 BYTE);
  I_COMENTARIO VARCHAR2(80 BYTE);
  I_TERMINO VARCHAR2(8 BYTE);
  I_CODIGO_USUARIO VARCHAR2(8 BYTE);
  I_TIME_STAMP VARCHAR2(26 BYTE);
  I_TIPO_DE_L  NUMBER;
  I_Motivo_DE_L VARCHAR2(100 BYTE);
  I_STATUS     VARCHAR2(2);
  

CURSOR l_f_xl 
Is
select trim(substr(registro,22,20)) || ' ' || trim(substr(registro,42,20)) || ' ' || trim(substr(registro,62,20)) as descripcion_tercero,
       trim(substr(registro,163,100)) as caract_lavado1,
       trim(substr(registro,163,100)) as caract_lavado2,
       trim(substr(registro,163,100)) as caract_lavado3,
       to_number(nvl(trim(substr(registro,2,16)),0)) as Identificacion, -- CAMPO 2 OK
       case trim(substr(registro,1,1))                                  -- CAMPO 1 OK
                when '0' then 'TI'
                when '1' then 'CC'
                when '2' then 'CE'
                when '3' then 'NIT'
                when '4' then 'TI'
                when '5' then 'PAS'
                when '6' then 'CC'
                when '7' then 'SEN'
                when '9' then 'CC'
                when 'A' then 'CC'
                when 'X' then 'CC'
                when 'Y' then 'CC'
                when 'Z' then 'CC'
                else 'CC'
           end as clase_doc,
           i_usuario as usuario_actualiza,
           --NVL(TO_CHAR(v_fecha_cargue,'DD-MM-YYYY'),TO_CHAR(SYSDATE,'DD-MM-YYYY')) as fecha_Actualiza,
           SYSDATE as fecha_Actualiza,
           'F' as origen,
           0 as estado,
           i_usuario as usuario,
           i_ip as ip,
           i_nombre_maquina as nombre_maquina,
           to_number(nvl(trim(substr(registro,17,1)),0)) as Digito_Verificacion, -- CAMPO 3 OK
           to_number(nvl(trim(substr(registro,18,2)),0)) as Novedad,             -- CAMPO 4 OK
           to_number(nvl(trim(substr(registro,20,2)),0)) as Calificador,         -- CAMPO 5 OK
           trim(substr(registro,22,20)) as Nombres,                              -- CAMPO 6 OK
           trim(substr(registro,42,20)) as Primer_Apellido,                      -- CAMPO 7 OK
           trim(substr(registro,62,20)) as Segundo_Apellido,                     -- CAMPO 8 OK
           to_number(nvl(trim(substr(registro,82,4)),0)) as Sucursal,            -- CAMPO 9 OK
           to_number(nvl(trim(substr(registro,86,18)),0))/100 as Valor,              -- CAMPO 10 OK MODIFICADO
     --    to_number(nvl(trim(substr(registro,102,2)),0)) as Decimales,         
           TO_DATE(substr(registro,104,10),'YYYY-MM-DD') as Fecha_Estudio,       -- CAMPO 11 OK
           to_number(nvl(trim(substr(registro,114,11)),0)) as CodigoCiiu,        -- CAMPO 12 OK
           trim(substr(registro,125,20)) as Actividad_Economica,                 -- CAMPO 13 OK
           trim(substr(registro,145,18)) as Cuenta,                              -- CAMPO 14 OK
           trim(substr(registro,163,100)) as Comentario,                         -- CAMPO 15 OK MODIFICADO
           trim(substr(registro,263,8)) as Termino,                              -- CAMPO 16 OK
           trim(substr(registro,271,8)) as Codigo_Usuario,                       -- CAMPO 17 OK
           trim(substr(registro,279,26)) as Time_Stamp,                          -- CAMPO 18 OK
           trim(nvl(substr(registro,305,1),0)) as  TIPO_DE_L,                        -- CAMPO 19    NUEVO
           trim(substr(registro,306,100)) as Motivo_DE_L                         -- CAMPO 20    NUEVO
           
    FROM BX_CARGUE_LISTA_SARLAFT
    WHERE  REGISTRO  NOT LIKE('%FECHA DE PROCESO%'); 
BEGIN


    ----------------------
    -- Validacion archivo de cargue --
    ----------------------
   SELECT COUNT(*) INTO v_nro_registros FROM BX_CARGUE_LISTA_SARLAFT WHERE
   LENGTH(REGISTRO) <> 405;
   IF v_nro_registros > 0 THEN
   raise_application_error(-20001, 'El archivo de cargue no cumple con la longitud de fila en ' || to_char(v_nro_registros) || ' registro(s).');
   END IF;
   
    ----------------------------
    -- Busco la fecha del dia --
    ----------------------------
    SELECT TO_CHAR(sysdate , 'YYYYMMDD') 
    INTO v_fecha_cargue
    FROM dual;   
    
    --SE EVALUA LA FECHA DE CRGUE CON LA FECHA QUE TRAE EL ARCHIVO 
    begin
    select substr(registro,21,8) 
    INTO v_fecha_plano
    FROM BX_CARGUE_LISTA_SARLAFT
    WHERE  REGISTRO LIKE('%FECHA DE PROCESO%');
    EXCEPTION 
       WHEN NO_DATA_FOUND THEN
          v_valida_fecha_plano := 0;
          raise_application_error(-20001, 'EL ARCHIVO NO CONTIENE LA FECHA DE PROCESO');
       WHEN OTHERS THEN
          v_valida_fecha_plano := 1;
    end; 
    
    IF v_fecha_cargue <> v_fecha_plano THEN 
      raise_application_error(-20001,'LA FECHA DEL CARGUE NO COINCIDE CON LA FECHA DE PROCESO');
    END IF;
    
   
    --------------------------
    -- Encuentro Nro Cargue --
    --------------------------

    SELECT NVL(MAX(NRO_CARGUE),0)
    INTO v_nro_cargue
    FROM CRG_LISTA_SARLAFT_ENCABEZADO;
   
    v_nro_cargue := v_nro_cargue + 1;
    v_cuenta_nuevos:=0;
    
FOR cclf IN l_f_xl LOOP --CURSOR PARA RECORRER EL CARGE DE LA LISTA FISCALIA 
    
    stoo_errmsg := '';
    v_code:= null;
    I_VALIDATE_TIPO_DE_L :=NULL;
    if REGEXP_LIKE (cclf.TIPO_DE_L , '^[[:digit:]]+$') then -- VALIDA SI EL TIPO DE LEVANTAMIENTO ES NUMERO Y PARSEA LA VARIABLE
    I_VALIDATE_TIPO_DE_L  :=  TO_NUMBER(cclf.TIPO_DE_L);
    end if;
    
    
    if cclf.Identificacion = 0 or cclf.Identificacion  = null then -- se salta el registro si este no trae una identificacion valida  then
    CONTINUE;
    end if;
    
    V_FLAG_UPDATE :=0;
    
     
     BEGIN
        SELECT   COUNT(*)
        INTO   v_cuenta_lista_fiscalia
         FROM   LISTA_FISCALIA
       WHERE   IDENTIFICACION_FIS = cclf.Identificacion
         AND   CLASE_DOCUMENTO_FIS = cclf.clase_doc;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         v_cuenta_lista_fiscalia := 0;
       WHEN OTHERS THEN
          v_cuenta_lista_fiscalia := 0;
    END;
    
    IF v_cuenta_lista_fiscalia = 0 THEN --SI NO EXISTE EN LA LISTA LO INSERTA 
    
      BEGIN
     INSERT INTO LISTA_FISCALIA (
                               DESCRIPCION_TERCERO,
                               CARACTERISTICA_LAVADO1,
                               CARACTERISTICA_LAVADO2,
                               CARACTERISTICA_LAVADO3,
                               IDENTIFICACION_FIS,
                               CLASE_DOCUMENTO_FIS,
                               USUARIO_ACTUALIZA,
                               FECHA_ACTUALIZA,
                               ORIGEN,
                               ESTADO,
                               USUARIO,
                               IP,
                               NOMBRE_MAQUINA,
                               DIGITO_VERIFICACION,
                               NOVEDAD,
                               CALIFICADOR,
                               NOMBRES,
                               PRIMER_APELLIDO,
                               SEGUNDO_APELLIDO,
                               SUCURSAL,
                               VALOR,
                                FECHA_ESTUDIO,
                              CODIGOCIIU,
                              ACTIVIDAD_ECONOMICA,
                             CUENTA,
                              COMENTARIO,
                              TERMINO,
                               CODIGO_USUARIO,
                               TIME_STAMP,
                               Tipo_de_levantamiento,                 --CAMPOS NUEVOS EN LA ESTRUCTURA
                               Motivo_de_Levantamiento
                               )
                          values (cclf.descripcion_tercero,
                                  cclf.caract_lavado1,
                                  cclf.caract_lavado2,
                                  cclf.caract_lavado3,
                                  cclf.Identificacion,
                                  cclf.clase_doc,
                                  cclf.usuario_actualiza,
                                  cclf.fecha_Actualiza,
                                  cclf.origen,
                                  cclf.estado,
                                  cclf.usuario,
                                  cclf.ip,
                                  cclf.nombre_maquina,
                                  cclf.Digito_Verificacion,
                                  cclf.Novedad,
                                  cclf.Calificador,
                                  cclf.Nombres,
                                  cclf.Primer_Apellido,
                                  cclf.Segundo_Apellido,
                                  cclf.Sucursal,
                                  cclf.Valor,
                                  cclf.Fecha_Estudio,
                                  cclf.CodigoCiiu,
                                  cclf.Actividad_Economica,
                                  cclf.Cuenta,
                                  cclf.Comentario,
                                  cclf.Termino,
                                  cclf.Codigo_Usuario,
                                  cclf.Time_Stamp,
                                  I_VALIDATE_TIPO_DE_L,
                                  cclf.Motivo_DE_L
                                  );
        stoo_rowcnt := SQL%ROWCOUNT;
         EXCEPTION
            WHEN OTHERS THEN
               stoo_errmsg := SQLERRM;
               v_code      := SQLCODE;
          END;
          
          IF v_code <> 0 THEN
               INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       ' ERROR INSERTANDO ' || ' IDENTIFICACION : '|| cclf.Identificacion ||' CLASE DOCUMENTO: '||' '||cclf.clase_doc,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
         ELSE
               INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       ' INSERTADO CORRECTAMENTE ' || ' IDENTIFICACION : '|| cclf.Identificacion ||' CLASE DOCUMENTO: '||' '||cclf.clase_doc,
                                                       stoo_errmsg,
                                                       SYSDATE);
           v_cuenta_nuevos  :=v_cuenta_nuevos +1; 
         END IF;
         
         ELSE if v_cuenta_lista_fiscalia = 1 then
         
            BEGIN
         SELECT                DESCRIPCION_TERCERO,
                               CARACTERISTICA_LAVADO1,
                               CARACTERISTICA_LAVADO2,
                               CARACTERISTICA_LAVADO3,
                               IDENTIFICACION_FIS,
                               CLASE_DOCUMENTO_FIS,
                               USUARIO_ACTUALIZA,
                               FECHA_ACTUALIZA,
                               ORIGEN,
                               ESTADO,
                               USUARIO,
                               IP,
                               NOMBRE_MAQUINA,
                               DIGITO_VERIFICACION,
                               NOVEDAD,
                               CALIFICADOR,
                               NOMBRES,
                               PRIMER_APELLIDO,
                               SEGUNDO_APELLIDO,
                               SUCURSAL,
                               VALOR,
                               DECIMALES,
                               FECHA_ESTUDIO,
                               CODIGOCIIU,
                               ACTIVIDAD_ECONOMICA,
                               CUENTA,
                               COMENTARIO,
                               TERMINO,
                               CODIGO_USUARIO,
                               TIME_STAMP ,
                               TIPO_DE_LEVANTAMIENTO,  
                               MOTIVO_DE_LEVANTAMIENTO
           INTO     I_DESCRIPCION_TERCERO,
                    I_CARACTERISTICA_LAVADO1,
                    I_CARACTERISTICA_LAVADO2,
                    I_CARACTERISTICA_LAVADO3,
                    I_IDENTIFICACION_FIS,
                    I_CLASE_DOCUMENTO_FIS,
                    I_USUARIO_ACTUALIZA,
                    I_FECHA_ACTUALIZA,
                    I_ORIGEN,
                    I_ESTADO,
                    I_A_USUARIO,
                    I_A_IP ,
                    I_A_NOMBRE_MAQUINA ,
                    I_DIGITO_VERIFICACION ,
                    I_NOVEDAD ,
                    I_CALIFICADOR ,
                    I_NOMBRES ,
                    I_PRIMER_APELLIDO ,
                    I_SEGUNDO_APELLIDO ,
                    I_SUCURSAL ,
                    I_VALOR ,
                    I_DECIMALES ,
                    I_FECHA_ESTUDIO,
                    I_CODIGOCIIU,
                    I_ACTIVIDAD_ECONOMICA ,
                    I_CUENTA ,
                    I_COMENTARIO ,
                    I_TERMINO ,
                    I_CODIGO_USUARIO ,
                    I_TIME_STAMP ,
                    I_TIPO_DE_L,  
                    I_Motivo_DE_L
           FROM   LISTA_FISCALIA
          WHERE   IDENTIFICACION_FIS = cclf.Identificacion
              AND CLASE_DOCUMENTO_FIS = cclf.clase_doc;
      EXCEPTION
            WHEN OTHERS THEN
               stoo_errmsg := SQLERRM;
               v_code      := SQLCODE;
                    I_DESCRIPCION_TERCERO := NULL;
                    I_CARACTERISTICA_LAVADO1 := NULL;
                    I_CARACTERISTICA_LAVADO2 := NULL;
                    I_CARACTERISTICA_LAVADO3 := NULL;
                    I_IDENTIFICACION_FIS := NULL;
                    I_CLASE_DOCUMENTO_FIS := NULL;
                    I_USUARIO_ACTUALIZA := NULL;
                    I_FECHA_ACTUALIZA := NULL;
                    I_ORIGEN := NULL;
                    I_ESTADO := NULL;
                    I_A_USUARIO := NULL;
                    I_A_IP  := NULL;
                    I_A_NOMBRE_MAQUINA  := NULL;
                    I_DIGITO_VERIFICACION := NULL;
                    I_NOVEDAD := NULL;
                    I_CALIFICADOR := NULL;
                    I_NOMBRES := NULL;
                    I_PRIMER_APELLIDO := NULL;
                    I_SEGUNDO_APELLIDO := NULL;
                    I_SUCURSAL := NULL;
                    I_VALOR := NULL;
                    I_DECIMALES := NULL;
                    I_FECHA_ESTUDIO := NULL;
                    I_CODIGOCIIU := NULL;
                    I_ACTIVIDAD_ECONOMICA := NULL;
                    I_CUENTA := NULL;
                    I_COMENTARIO := NULL;
                    I_TERMINO := NULL;
                    I_CODIGO_USUARIO := NULL;
                    I_TIME_STAMP := NULL;
                    I_TIPO_DE_L:= NULL;  
                    I_Motivo_DE_L := NULL;
      END;
      
          IF cclf.descripcion_tercero IS NOT NULL AND cclf.descripcion_tercero <> I_DESCRIPCION_TERCERO   THEN
         stoo_errmsg := '';
         v_code:= null;
            BEGIN
               UPDATE   LISTA_FISCALIA
                  SET   descripcion_tercero = cclf.descripcion_tercero
          WHERE   IDENTIFICACION_FIS = cclf.Identificacion
              AND CLASE_DOCUMENTO_FIS = cclf.clase_doc;

               stoo_rowcnt := SQL%ROWCOUNT;
            EXCEPTION
               WHEN OTHERS THEN
                  stoo_errmsg := SQLERRM;
                  v_code      := SQLCODE;
            END;

            IF v_code <> 0 THEN
               INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       ' ERROR ACTUALIZANDO ' ||
                                                       ' IDENTIFICACION : '||
                                                       cclf.Identificacion ||
                                                       ' CLASE DOCUMENTO: '||
                                                       ' '||
                                                       cclf.clase_doc ||  
                                                       ' CAMPO : DESCRIPCION_TERCERO '||
                                                       ', OLD '||
                                                       i_descripcion_tercero ||
                                                       ', NEW ' ||
                                                       cclf.descripcion_tercero,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
            ELSE
                INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       ' ACTUALIZANDO ' ||
                                                       ' IDENTIFICACION : '||
                                                       cclf.Identificacion ||
                                                       ' CLASE DOCUMENTO: '||
                                                       ' '||
                                                       cclf.clase_doc ||  
                                                       ' CAMPO : DESCRIPCION_TERCERO '||
                                                       ', OLD '||
                                                       i_descripcion_tercero ||
                                                       ', NEW ' ||
                                                       cclf.descripcion_tercero,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
                                  V_FLAG_UPDATE := V_FLAG_UPDATE +1;
            END IF;
         END IF;
         
          IF cclf.caract_lavado1 IS NOT NULL AND cclf.caract_lavado1 <> I_CARACTERISTICA_LAVADO1  THEN
          stoo_errmsg := '';
          v_code:= null;
            BEGIN
               UPDATE   LISTA_FISCALIA
                  SET   CARACTERISTICA_LAVADO1 = cclf.caract_lavado1
          WHERE   IDENTIFICACION_FIS = cclf.Identificacion
              AND CLASE_DOCUMENTO_FIS = cclf.clase_doc;

               stoo_rowcnt := SQL%ROWCOUNT;
            EXCEPTION
               WHEN OTHERS THEN
                  stoo_errmsg := SQLERRM;
                  v_code      := SQLCODE;
            END;

            IF v_code <> 0 THEN
               INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       ' ERROR ACTUALIZANDO ' ||
                                                       ' IDENTIFICACION : '||
                                                       cclf.Identificacion ||
                                                       ' CLASE DOCUMENTO: '||
                                                       ' '||
                                                       cclf.clase_doc ||  
                                                       ' CAMPO : CARACTERISTICA_LAVADO1 '||
                                                       ', OLD '||
                                                       I_CARACTERISTICA_LAVADO1 ||
                                                       ', NEW ' ||
                                                       cclf.caract_lavado1,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
            ELSE
                INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       ' ACTUALIZANDO ' ||
                                                       ' IDENTIFICACION : '||
                                                       cclf.Identificacion ||
                                                       ' CLASE DOCUMENTO: '||
                                                       ' '||
                                                       cclf.clase_doc ||  
                                                       ' CAMPO : CARACTERISTICA_LAVADO1 '||
                                                       ', OLD '||
                                                       I_CARACTERISTICA_LAVADO1 ||
                                                       ' , NEW ' ||
                                                       cclf.caract_lavado1,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
                                  V_FLAG_UPDATE := V_FLAG_UPDATE +1;
            END IF;
         END IF;
         
          IF cclf.caract_lavado2 IS NOT NULL AND cclf.caract_lavado2 <> I_CARACTERISTICA_LAVADO2  THEN
          stoo_errmsg := '';
          v_code:= null;
            BEGIN
               UPDATE   LISTA_FISCALIA
                  SET   CARACTERISTICA_LAVADO2 = cclf.caract_lavado2
          WHERE   IDENTIFICACION_FIS = cclf.Identificacion
              AND CLASE_DOCUMENTO_FIS = cclf.clase_doc;

               stoo_rowcnt := SQL%ROWCOUNT;
            EXCEPTION
               WHEN OTHERS THEN
                  stoo_errmsg := SQLERRM;
                  v_code      := SQLCODE;
            END;

            IF v_code <> 0 THEN
               INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       ' ERROR ACTUALIZANDO ' ||
                                                       ' IDENTIFICACION : '||
                                                       cclf.Identificacion ||
                                                       ' CLASE DOCUMENTO: '||
                                                       ' '||
                                                       cclf.clase_doc ||  
                                                       ' CAMPO : CARACTERISTICA_LAVADO2 '||
                                                       ', OLD '||
                                                       I_CARACTERISTICA_LAVADO2 ||
                                                       ', NEW ' ||
                                                       cclf.caract_lavado2,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
            ELSE
                INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       ' ACTUALIZANDO ' ||
                                                       ' IDENTIFICACION : '||
                                                       cclf.Identificacion ||
                                                       ' CLASE DOCUMENTO: '||
                                                       ' '||
                                                       cclf.clase_doc ||  
                                                       ' CAMPO : CARACTERISTICA_LAVADO2 '||
                                                       ', OLD '||
                                                       i_descripcion_tercero ||
                                                       ', NEW ' ||
                                                       cclf.caract_lavado2,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
                                  V_FLAG_UPDATE := V_FLAG_UPDATE +1;
            END IF;
         END IF;
         
        IF cclf.caract_lavado3 IS NOT NULL AND cclf.caract_lavado3 <> I_CARACTERISTICA_LAVADO3  THEN
            stoo_errmsg := '';
            v_code:= null;
            BEGIN
               UPDATE   LISTA_FISCALIA
                  SET   CARACTERISTICA_LAVADO3 = cclf.caract_lavado3
          WHERE   IDENTIFICACION_FIS = cclf.Identificacion
              AND CLASE_DOCUMENTO_FIS = cclf.clase_doc;

               stoo_rowcnt := SQL%ROWCOUNT;
            EXCEPTION
               WHEN OTHERS THEN
                  stoo_errmsg := SQLERRM;
                  v_code      := SQLCODE;
            END;

            IF v_code <> 0 THEN
               INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       ' ERROR ACTUALIZANDO ' ||
                                                       ' IDENTIFICACION : '||
                                                       cclf.Identificacion ||
                                                       ' CLASE DOCUMENTO: '||
                                                       ' '||
                                                       cclf.clase_doc ||  
                                                       ' CAMPO : CARACTERISTICA_LAVADO3 '||
                                                       ', OLD '||
                                                       I_CARACTERISTICA_LAVADO3 ||
                                                       ', NEW ' ||
                                                       cclf.caract_lavado3,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
            ELSE
                INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       ' ACTUALIZANDO ' ||
                                                       ' IDENTIFICACION : '||
                                                       cclf.Identificacion ||
                                                       ' CLASE DOCUMENTO: '||
                                                       ' '||
                                                       cclf.clase_doc ||  
                                                       ' CAMPO : CARACTERISTICA_LAVADO3 '||
                                                       ', OLD '||
                                                       I_CARACTERISTICA_LAVADO3 ||
                                                       ', NEW ' ||
                                                       cclf.caract_lavado3,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
                                  V_FLAG_UPDATE := V_FLAG_UPDATE +1;
            END IF;
         END IF;
         
          IF cclf.usuario_actualiza IS NOT NULL AND cclf.usuario_actualiza <> I_USUARIO_ACTUALIZA  THEN
          stoo_errmsg := '';
          v_code:= null;
            BEGIN
               UPDATE   LISTA_FISCALIA
                  SET   USUARIO_ACTUALIZA = cclf.usuario_actualiza
          WHERE   IDENTIFICACION_FIS = cclf.Identificacion
              AND CLASE_DOCUMENTO_FIS = cclf.clase_doc;

               stoo_rowcnt := SQL%ROWCOUNT;
            EXCEPTION
               WHEN OTHERS THEN
                  stoo_errmsg := SQLERRM;
                  v_code      := SQLCODE;
            END;

            IF v_code <> 0 THEN
               INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       ' ERROR ACTUALIZANDO ' ||
                                                       ' IDENTIFICACION : '||
                                                       cclf.Identificacion ||
                                                       ' CLASE DOCUMENTO: '||
                                                       ' '||
                                                       cclf.clase_doc ||  
                                                       ' CAMPO : USUARIO_ACTUALIZA '||
                                                       ', OLD '||
                                                       I_USUARIO_ACTUALIZA ||
                                                       ', NEW ' ||
                                                       cclf.usuario_actualiza,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
            ELSE
                INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       ' ACTUALIZANDO ' ||
                                                       ' IDENTIFICACION : '||
                                                       cclf.Identificacion ||
                                                       ' CLASE DOCUMENTO: '||
                                                       ' '||
                                                       cclf.clase_doc ||  
                                                       ' CAMPO : USUARIO_ACTUALIZA '||
                                                       ', OLD '||
                                                       I_USUARIO_ACTUALIZA ||
                                                       ', NEW ' ||
                                                       cclf.usuario_actualiza,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
                                                       V_FLAG_UPDATE := V_FLAG_UPDATE +1;
            END IF;
         END IF;
         
        IF cclf.FECHA_ACTUALIZA IS NOT NULL AND cclf.FECHA_ACTUALIZA <>'' AND  cclf.FECHA_ACTUALIZA <> I_FECHA_ACTUALIZA  THEN
         stoo_errmsg := '';
         v_code:= null;
            BEGIN
               UPDATE   LISTA_FISCALIA
                  SET   FECHA_ACTUALIZA = cclf.FECHA_ACTUALIZA
          WHERE   IDENTIFICACION_FIS = cclf.Identificacion
              AND CLASE_DOCUMENTO_FIS = cclf.clase_doc;

               stoo_rowcnt := SQL%ROWCOUNT;
            EXCEPTION
               WHEN OTHERS THEN
                  stoo_errmsg := SQLERRM;
                  v_code      := SQLCODE;
            END;

            IF v_code <> 0 THEN
               INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       ' ERROR ACTUALIZANDO ' ||
                                                       ' IDENTIFICACION : '||
                                                       cclf.Identificacion ||
                                                       ' CLASE DOCUMENTO: '||
                                                       ' '||
                                                       cclf.clase_doc ||  
                                                       ' CAMPO : FECHA_ACTUALIZA '||
                                                       ', OLD '||
                                                       I_FECHA_ACTUALIZA ||
                                                       ', NEW ' ||
                                                       cclf.FECHA_ACTUALIZA,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
            ELSE
                INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       ' ACTUALIZANDO ' ||
                                                       ' IDENTIFICACION : '||
                                                       cclf.Identificacion ||
                                                       ' CLASE DOCUMENTO: '||
                                                       ' '||
                                                       cclf.clase_doc ||  
                                                       ' CAMPO : FECHA_ACTUALIZA '||
                                                       ', OLD '||
                                                       I_FECHA_ACTUALIZA ||
                                                       ', NEW ' ||
                                                       cclf.FECHA_ACTUALIZA,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
                                  V_FLAG_UPDATE := V_FLAG_UPDATE +1;
            END IF;
         END IF;
         
                   IF cclf.ORIGEN IS NOT NULL AND cclf.ORIGEN <> I_ORIGEN  THEN
            stoo_errmsg := '';
            v_code:= null;
            BEGIN
               UPDATE   LISTA_FISCALIA
                  SET   ORIGEN = cclf.ORIGEN
          WHERE   IDENTIFICACION_FIS = cclf.Identificacion
              AND CLASE_DOCUMENTO_FIS = cclf.clase_doc;

               stoo_rowcnt := SQL%ROWCOUNT;
            EXCEPTION
               WHEN OTHERS THEN
                  stoo_errmsg := SQLERRM;
                  v_code      := SQLCODE;
            END;

            IF v_code <> 0 THEN
               INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       ' ERROR ACTUALIZANDO ' ||
                                                       ' IDENTIFICACION : '||
                                                       cclf.Identificacion ||
                                                       ' CLASE DOCUMENTO: '||
                                                       ' '||
                                                       cclf.clase_doc ||  
                                                       ' CAMPO : ORIGEN '||
                                                       ', OLD '||
                                                       I_ORIGEN ||
                                                       ', NEW ' ||
                                                       cclf.ORIGEN,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
            ELSE
                INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       ' ACTUALIZANDO ' ||
                                                       ' IDENTIFICACION : '||
                                                       cclf.Identificacion ||
                                                       ' CLASE DOCUMENTO: '||
                                                       ' '||
                                                       cclf.clase_doc ||  
                                                       ' CAMPO : ORIGEN '||
                                                       ', OLD '||
                                                       I_ORIGEN ||
                                                       ', NEW ' ||
                                                       cclf.ORIGEN,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
                                  V_FLAG_UPDATE := V_FLAG_UPDATE +1;
            END IF;
         END IF;
         
                   IF cclf.ESTADO IS NOT NULL AND cclf.ESTADO <> I_ESTADO  THEN
        stoo_errmsg := '';
        v_code:= null;
            BEGIN
               UPDATE   LISTA_FISCALIA
                  SET   ESTADO = cclf.ESTADO
          WHERE   IDENTIFICACION_FIS = cclf.Identificacion
              AND CLASE_DOCUMENTO_FIS = cclf.clase_doc;

               stoo_rowcnt := SQL%ROWCOUNT;
            EXCEPTION
               WHEN OTHERS THEN
                  stoo_errmsg := SQLERRM;
                  v_code      := SQLCODE;
            END;

            IF v_code <> 0 THEN
               INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       ' ERROR ACTUALIZANDO ' ||
                                                       ' IDENTIFICACION : '||
                                                       cclf.Identificacion ||
                                                       ' CLASE DOCUMENTO: '||
                                                       ' '||
                                                       cclf.clase_doc ||  
                                                       ' CAMPO : ESTADO '||
                                                       ', OLD '||
                                                       I_ESTADO ||
                                                       ', NEW ' ||
                                                       cclf.ESTADO,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
            ELSE
                INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       ' ACTUALIZANDO ' ||
                                                       ' IDENTIFICACION : '||
                                                       cclf.Identificacion ||
                                                       ' CLASE DOCUMENTO: '||
                                                       ' '||
                                                       cclf.clase_doc ||  
                                                       ' CAMPO : ESTADO '||
                                                       ', OLD '||
                                                       I_ESTADO ||
                                                       ', NEW ' ||
                                                       cclf.ESTADO,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
                                  V_FLAG_UPDATE := V_FLAG_UPDATE +1;
            END IF;
         END IF;
         
       IF cclf.USUARIO IS NOT NULL AND cclf.USUARIO <> I_USUARIO  THEN
            stoo_errmsg := '';
            v_code:= null;
            BEGIN
               UPDATE   LISTA_FISCALIA
                  SET   USUARIO = cclf.USUARIO
          WHERE   IDENTIFICACION_FIS = cclf.Identificacion
              AND CLASE_DOCUMENTO_FIS = cclf.clase_doc;

               stoo_rowcnt := SQL%ROWCOUNT;
            EXCEPTION
               WHEN OTHERS THEN
                  stoo_errmsg := SQLERRM;
                  v_code      := SQLCODE;
            END;

            IF v_code <> 0 THEN
               INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       'ERROR ACTUALIZANDO ' ||
                                                       'IDENTIFICACION : '||
                                                       cclf.Identificacion ||
                                                       ' CLASE DOCUMENTO: '||
                                                       ' '||
                                                       cclf.clase_doc ||  
                                                       'CAMPO : USUARIO'||
                                                       ', OLD '||
                                                       I_USUARIO ||
                                                       ', NEW ' ||
                                                       cclf.USUARIO,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
            ELSE
                INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       'ACTUALIZANDO ' ||
                                                       'IDENTIFICACION : '||
                                                       cclf.Identificacion ||
                                                       ' CLASE DOCUMENTO: '||
                                                       ' '||
                                                       cclf.clase_doc ||  
                                                       'CAMPO : USUARIO'||
                                                       ', OLD '||
                                                       I_USUARIO ||
                                                       ', NEW ' ||
                                                       cclf.USUARIO,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
                                  V_FLAG_UPDATE := V_FLAG_UPDATE +1;
            END IF;
         END IF;
         
        IF cclf.IP IS NOT NULL AND cclf.IP <> I_IP  THEN
            stoo_errmsg := '';
            v_code:= null;
            BEGIN
               UPDATE   LISTA_FISCALIA
                  SET   IP = cclf.IP
          WHERE   IDENTIFICACION_FIS = cclf.Identificacion
              AND CLASE_DOCUMENTO_FIS = cclf.clase_doc;

               stoo_rowcnt := SQL%ROWCOUNT;
            EXCEPTION
               WHEN OTHERS THEN
                  stoo_errmsg := SQLERRM;
                  v_code      := SQLCODE;
            END;

            IF v_code <> 0 THEN
               INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       'ERROR ACTUALIZANDO ' ||
                                                       'IDENTIFICACION : '||
                                                       cclf.Identificacion ||
                                                       ' CLASE DOCUMENTO: '||
                                                       ' '||
                                                       cclf.clase_doc ||  
                                                       'CAMPO : IP'||
                                                       ', OLD '||
                                                       I_IP ||
                                                       ', NEW ' ||
                                                       cclf.IP,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
            ELSE
                INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       'ACTUALIZANDO ' ||
                                                       'IDENTIFICACION : '||
                                                       cclf.Identificacion ||
                                                       ' CLASE DOCUMENTO: '||
                                                       ' '||
                                                       cclf.clase_doc ||  
                                                       'CAMPO : IP'||
                                                       ', OLD '||
                                                       I_IP ||
                                                       ', NEW ' ||
                                                       cclf.IP,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
                                  V_FLAG_UPDATE := V_FLAG_UPDATE +1;
            END IF;
         END IF;
         
         IF cclf.NOMBRE_MAQUINA IS NOT NULL AND cclf.NOMBRE_MAQUINA <> I_NOMBRE_MAQUINA  THEN
         stoo_errmsg := '';
         v_code:= null;
            BEGIN
               UPDATE   LISTA_FISCALIA
                  SET   NOMBRE_MAQUINA = cclf.NOMBRE_MAQUINA
          WHERE   IDENTIFICACION_FIS = cclf.Identificacion
              AND CLASE_DOCUMENTO_FIS = cclf.clase_doc;

               stoo_rowcnt := SQL%ROWCOUNT;
            EXCEPTION
               WHEN OTHERS THEN
                  stoo_errmsg := SQLERRM;
                  v_code      := SQLCODE;
            END;

            IF v_code <> 0 THEN
               INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       'ERROR ACTUALIZANDO ' ||
                                                       'IDENTIFICACION : '||
                                                       cclf.Identificacion ||
                                                       ' CLASE DOCUMENTO: '||
                                                       ' '||
                                                       cclf.clase_doc ||  
                                                       'CAMPO : NOMBRE_MAQUINA'||
                                                       ', OLD '||
                                                       I_NOMBRE_MAQUINA ||
                                                       ', NEW ' ||
                                                       cclf.NOMBRE_MAQUINA,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
            ELSE
                INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       'ACTUALIZANDO ' ||
                                                       'IDENTIFICACION : '||
                                                       cclf.Identificacion ||
                                                       ' CLASE DOCUMENTO: '||
                                                       ' '||
                                                       cclf.clase_doc ||  
                                                       'CAMPO : NOMBRE_MAQUINA'||
                                                       ', OLD '||
                                                       I_NOMBRE_MAQUINA ||
                                                       ', NEW ' ||
                                                       cclf.NOMBRE_MAQUINA,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
                                  V_FLAG_UPDATE := V_FLAG_UPDATE +1;
            END IF;
         END IF;
         
         IF cclf.DIGITO_VERIFICACION IS NOT NULL AND cclf.DIGITO_VERIFICACION <> I_DIGITO_VERIFICACION  THEN
         
         stoo_errmsg := '';
         v_code:= null;
            BEGIN
               UPDATE   LISTA_FISCALIA
                  SET   DIGITO_VERIFICACION = cclf.DIGITO_VERIFICACION
          WHERE   IDENTIFICACION_FIS = cclf.Identificacion
              AND CLASE_DOCUMENTO_FIS = cclf.clase_doc;

               stoo_rowcnt := SQL%ROWCOUNT;
            EXCEPTION
               WHEN OTHERS THEN
                  stoo_errmsg := SQLERRM;
                  v_code      := SQLCODE;
            END;

            IF v_code <> 0 THEN
               INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       'ERROR ACTUALIZANDO ' ||
                                                       'IDENTIFICACION : '||
                                                       cclf.Identificacion ||
                                                       ' CLASE DOCUMENTO: '||
                                                       ' '||
                                                       cclf.clase_doc ||  
                                                       'CAMPO : DIGITO_VERIFICACION'||
                                                       ', OLD '||
                                                       I_DIGITO_VERIFICACION ||
                                                       ', NEW ' ||
                                                       cclf.DIGITO_VERIFICACION,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
            ELSE
                INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       'ACTUALIZANDO ' ||
                                                       'IDENTIFICACION : '||
                                                       cclf.Identificacion ||
                                                       ' CLASE DOCUMENTO: '||
                                                       ' '||
                                                       cclf.clase_doc ||  
                                                       'CAMPO : DIGITO_VERIFICACION'||
                                                       ', OLD '||
                                                       I_DIGITO_VERIFICACION ||
                                                       ', NEW ' ||
                                                       cclf.DIGITO_VERIFICACION,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
                                  V_FLAG_UPDATE := V_FLAG_UPDATE +1;
            END IF;
         END IF;
         
         IF cclf.NOVEDAD IS NOT NULL AND cclf.NOVEDAD <> I_NOVEDAD  THEN
         stoo_errmsg := '';
         v_code:= null;
            BEGIN
               UPDATE   LISTA_FISCALIA
                  SET   NOVEDAD = cclf.NOVEDAD
          WHERE   IDENTIFICACION_FIS = cclf.Identificacion
              AND CLASE_DOCUMENTO_FIS = cclf.clase_doc;

               stoo_rowcnt := SQL%ROWCOUNT;
            EXCEPTION
               WHEN OTHERS THEN
                  stoo_errmsg := SQLERRM;
                  v_code      := SQLCODE;
            END;

            IF v_code <> 0 THEN
               INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       'ERROR ACTUALIZANDO ' ||
                                                       'IDENTIFICACION : '||
                                                       cclf.Identificacion ||
                                                       ' CLASE DOCUMENTO: '||
                                                       ' '||
                                                       cclf.clase_doc ||  
                                                       'CAMPO : NOVEDAD'||
                                                       ', OLD '||
                                                       I_NOVEDAD ||
                                                       ', NEW ' ||
                                                       cclf.NOVEDAD,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
            ELSE
                INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       'ACTUALIZANDO ' ||
                                                       'IDENTIFICACION : '||
                                                       cclf.Identificacion ||
                                                       ' CLASE DOCUMENTO: '||
                                                       ' '||
                                                       cclf.clase_doc ||  
                                                       'CAMPO : NOVEDAD'||
                                                       ', OLD '||
                                                       I_NOVEDAD ||
                                                       ', NEW ' ||
                                                       cclf.NOVEDAD,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
                                  V_FLAG_UPDATE := V_FLAG_UPDATE +1;
            END IF;
         END IF;
         
            IF cclf.CALIFICADOR IS NOT NULL AND cclf.CALIFICADOR <> I_CALIFICADOR  THEN
            stoo_errmsg := '';
            v_code:= null;
            BEGIN
               UPDATE   LISTA_FISCALIA
                  SET   CALIFICADOR = cclf.CALIFICADOR
          WHERE   IDENTIFICACION_FIS = cclf.Identificacion
              AND CLASE_DOCUMENTO_FIS = cclf.clase_doc;

               stoo_rowcnt := SQL%ROWCOUNT;
            EXCEPTION
               WHEN OTHERS THEN
                  stoo_errmsg := SQLERRM;
                  v_code      := SQLCODE;
            END;

            IF v_code <> 0 THEN
               INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       'ERROR ACTUALIZANDO ' ||
                                                       'IDENTIFICACION : '||
                                                       cclf.Identificacion ||
                                                       ' CLASE DOCUMENTO: '||
                                                       ' '||
                                                       cclf.clase_doc ||  
                                                       'CAMPO : CALIFICADOR'||
                                                       ', OLD '||
                                                       I_CALIFICADOR ||
                                                       ', NEW ' ||
                                                       cclf.CALIFICADOR,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
            ELSE
                INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       'ACTUALIZANDO ' ||
                                                       'IDENTIFICACION : '||
                                                       cclf.Identificacion ||
                                                       ' CLASE DOCUMENTO: '||
                                                       ' '||
                                                       cclf.clase_doc ||  
                                                       'CAMPO : CALIFICADOR'||
                                                       ', OLD '||
                                                       I_CALIFICADOR ||
                                                       ', NEW ' ||
                                                       cclf.CALIFICADOR,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
                                  V_FLAG_UPDATE := V_FLAG_UPDATE +1;
            END IF;
         END IF;
         
            IF cclf.NOMBRES IS NOT NULL AND cclf.NOMBRES <> I_NOMBRES  THEN
            stoo_errmsg := '';
            v_code:= null;
            BEGIN
               UPDATE   LISTA_FISCALIA
                  SET   NOMBRES = cclf.NOMBRES
          WHERE   IDENTIFICACION_FIS = cclf.Identificacion
              AND CLASE_DOCUMENTO_FIS = cclf.clase_doc;

               stoo_rowcnt := SQL%ROWCOUNT;
            EXCEPTION
               WHEN OTHERS THEN
                  stoo_errmsg := SQLERRM;
                  v_code      := SQLCODE;
            END;

            IF v_code <> 0 THEN
               INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       'ERROR ACTUALIZANDO ' ||
                                                       'IDENTIFICACION : '||
                                                       cclf.Identificacion ||
                                                       ' CLASE DOCUMENTO: '||
                                                       ' '||
                                                       cclf.clase_doc ||  
                                                       'CAMPO : NOMBRES'||
                                                       ', OLD '||
                                                       I_NOMBRES ||
                                                       ', NEW ' ||
                                                       cclf.NOMBRES,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
            ELSE
                INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       'ACTUALIZANDO ' ||
                                                       'IDENTIFICACION : '||
                                                       cclf.Identificacion ||
                                                       ' CLASE DOCUMENTO: '||
                                                       ' '||
                                                       cclf.clase_doc ||  
                                                       'CAMPO : NOMBRES'||
                                                       ', OLD '||
                                                       I_NOMBRES ||
                                                       ', NEW ' ||
                                                       cclf.NOMBRES,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
                                  V_FLAG_UPDATE := V_FLAG_UPDATE +1;
            END IF;
         END IF;
         
            IF cclf.PRIMER_APELLIDO IS NOT NULL AND cclf.PRIMER_APELLIDO <> I_PRIMER_APELLIDO  THEN
            stoo_errmsg := '';
            v_code:= null;
            BEGIN
               UPDATE   LISTA_FISCALIA
                  SET   PRIMER_APELLIDO = cclf.PRIMER_APELLIDO
          WHERE   IDENTIFICACION_FIS = cclf.Identificacion
              AND CLASE_DOCUMENTO_FIS = cclf.clase_doc;

               stoo_rowcnt := SQL%ROWCOUNT;
            EXCEPTION
               WHEN OTHERS THEN
                  stoo_errmsg := SQLERRM;
                  v_code      := SQLCODE;
            END;

            IF v_code <> 0 THEN
               INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       'ERROR ACTUALIZANDO ' ||
                                                       'IDENTIFICACION : '||
                                                       cclf.Identificacion ||
                                                       ' CLASE DOCUMENTO: '||
                                                       ' '||
                                                       cclf.clase_doc ||  
                                                       'CAMPO : PRIMER_APELLIDO'||
                                                       ', OLD '||
                                                       I_PRIMER_APELLIDO ||
                                                       ', NEW ' ||
                                                       cclf.PRIMER_APELLIDO,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
            ELSE
                INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       'ACTUALIZANDO ' ||
                                                       'IDENTIFICACION : '||
                                                       cclf.Identificacion ||
                                                       ' CLASE DOCUMENTO: '||
                                                       ' '||
                                                       cclf.clase_doc ||  
                                                       'CAMPO : PRIMER_APELLIDO'||
                                                       ', OLD '||
                                                       I_PRIMER_APELLIDO ||
                                                       ', NEW ' ||
                                                       cclf.PRIMER_APELLIDO,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
                                  V_FLAG_UPDATE := V_FLAG_UPDATE +1;
            END IF;
         END IF;
         
            IF cclf.SEGUNDO_APELLIDO IS NOT NULL AND cclf.SEGUNDO_APELLIDO <> I_SEGUNDO_APELLIDO  THEN
            stoo_errmsg := '';
            v_code:= null;
            BEGIN
               UPDATE   LISTA_FISCALIA
                  SET   SEGUNDO_APELLIDO = cclf.SEGUNDO_APELLIDO
          WHERE   IDENTIFICACION_FIS = cclf.Identificacion
              AND CLASE_DOCUMENTO_FIS = cclf.clase_doc;

               stoo_rowcnt := SQL%ROWCOUNT;
            EXCEPTION
               WHEN OTHERS THEN
                  stoo_errmsg := SQLERRM;
                  v_code      := SQLCODE;
            END;

            IF v_code <> 0 THEN
               INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       'ERROR ACTUALIZANDO ' ||
                                                       'IDENTIFICACION : '||
                                                       cclf.Identificacion ||
                                                       ' CLASE DOCUMENTO: '||
                                                       ' '||
                                                       cclf.clase_doc ||  
                                                       'CAMPO : SEGUNDO_APELLIDO'||
                                                       ', OLD '||
                                                       I_SEGUNDO_APELLIDO ||
                                                       ', NEW ' ||
                                                       cclf.SEGUNDO_APELLIDO,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
            ELSE
                INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       'ACTUALIZANDO ' ||
                                                       'IDENTIFICACION : '||
                                                       cclf.Identificacion ||
                                                       ' CLASE DOCUMENTO: '||
                                                       ' '||
                                                       cclf.clase_doc ||  
                                                       'CAMPO : SEGUNDO_APELLIDO'||
                                                       ', OLD '||
                                                       I_SEGUNDO_APELLIDO ||
                                                       ', NEW ' ||
                                                       cclf.SEGUNDO_APELLIDO,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
                                  V_FLAG_UPDATE := V_FLAG_UPDATE +1;
            END IF;
         END IF;
         
            IF cclf.SUCURSAL IS NOT NULL AND cclf.SUCURSAL <> I_SUCURSAL  THEN
            stoo_errmsg := '';
            v_code:= null;
            BEGIN
               UPDATE   LISTA_FISCALIA
                  SET   SUCURSAL = cclf.SUCURSAL
          WHERE   IDENTIFICACION_FIS = cclf.Identificacion
              AND CLASE_DOCUMENTO_FIS = cclf.clase_doc;

               stoo_rowcnt := SQL%ROWCOUNT;
            EXCEPTION
               WHEN OTHERS THEN
                  stoo_errmsg := SQLERRM;
                  v_code      := SQLCODE;
            END;

            IF v_code <> 0 THEN
               INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       'ERROR ACTUALIZANDO ' ||
                                                       'IDENTIFICACION : '||
                                                       cclf.Identificacion ||
                                                       ' CLASE DOCUMENTO: '||
                                                       ' '||
                                                       cclf.clase_doc ||  
                                                       'CAMPO : SUCURSAL'||
                                                       ', OLD '||
                                                       I_SUCURSAL ||
                                                       ', NEW ' ||
                                                       cclf.SUCURSAL,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
            ELSE
                INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       'ACTUALIZANDO ' ||
                                                       'IDENTIFICACION : '||
                                                       cclf.Identificacion ||
                                                       ' CLASE DOCUMENTO: '||
                                                       ' '||
                                                       cclf.clase_doc ||  
                                                       'CAMPO : SUCURSAL'||
                                                       ', OLD '||
                                                       I_SUCURSAL ||
                                                       ', NEW ' ||
                                                       cclf.SUCURSAL,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
                                  V_FLAG_UPDATE := V_FLAG_UPDATE +1;
            END IF;
         END IF;
        
            IF cclf.VALOR IS NOT NULL AND cclf.VALOR <> I_VALOR  THEN
            stoo_errmsg := '';
            v_code:= null;
            BEGIN
               UPDATE   LISTA_FISCALIA
                  SET   VALOR = cclf.VALOR
          WHERE   IDENTIFICACION_FIS = cclf.Identificacion
              AND CLASE_DOCUMENTO_FIS = cclf.clase_doc;

               stoo_rowcnt := SQL%ROWCOUNT;
            EXCEPTION
               WHEN OTHERS THEN
                  stoo_errmsg := SQLERRM;
                  v_code      := SQLCODE;
            END;

            IF v_code <> 0 THEN
               INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       'ERROR ACTUALIZANDO ' ||
                                                       'IDENTIFICACION : '||
                                                       cclf.Identificacion ||
                                                       ' CLASE DOCUMENTO: '||
                                                       ' '||
                                                       cclf.clase_doc ||  
                                                       'CAMPO : VALOR'||
                                                       ', OLD '||
                                                       I_VALOR ||
                                                       ', NEW ' ||
                                                       cclf.VALOR,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
            ELSE
                INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       'ACTUALIZANDO ' ||
                                                       'IDENTIFICACION : '||
                                                       cclf.Identificacion ||
                                                       ' CLASE DOCUMENTO: '||
                                                       ' '||
                                                       cclf.clase_doc ||  
                                                       'CAMPO : VALOR'||
                                                       ', OLD '||
                                                       I_VALOR ||
                                                       ', NEW ' ||
                                                       cclf.VALOR,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
                                  V_FLAG_UPDATE := V_FLAG_UPDATE +1;
            END IF;
         END IF;
                  
            IF cclf.FECHA_ESTUDIO IS NOT NULL AND cclf.FECHA_ESTUDIO <> I_FECHA_ESTUDIO  THEN
            stoo_errmsg := '';
            v_code:= null;
            BEGIN
               UPDATE   LISTA_FISCALIA
                  SET   FECHA_ESTUDIO = cclf.FECHA_ESTUDIO
          WHERE   IDENTIFICACION_FIS = cclf.Identificacion
              AND CLASE_DOCUMENTO_FIS = cclf.clase_doc;

               stoo_rowcnt := SQL%ROWCOUNT;
            EXCEPTION
               WHEN OTHERS THEN
                  stoo_errmsg := SQLERRM;
                  v_code      := SQLCODE;
            END;

            IF v_code <> 0 THEN
               INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       'ERROR ACTUALIZANDO ' ||
                                                       'IDENTIFICACION : '||
                                                       cclf.Identificacion ||
                                                       ' CLASE DOCUMENTO: '||
                                                       ' '||
                                                       cclf.clase_doc ||  
                                                       'CAMPO : FECHA_ESTUDIO'||
                                                       ', OLD '||
                                                       I_FECHA_ESTUDIO ||
                                                       ', NEW ' ||
                                                       cclf.FECHA_ESTUDIO,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
            ELSE
                INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       'ACTUALIZANDO ' ||
                                                       'IDENTIFICACION : '||
                                                       cclf.Identificacion ||
                                                       ' CLASE DOCUMENTO: '||
                                                       ' '||
                                                       cclf.clase_doc ||  
                                                       'CAMPO : FECHA_ESTUDIO'||
                                                       ', OLD '||
                                                       I_FECHA_ESTUDIO ||
                                                       ', NEW ' ||
                                                       cclf.FECHA_ESTUDIO,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
                                  V_FLAG_UPDATE := V_FLAG_UPDATE +1;
            END IF;
         END IF;
         
            IF cclf.CODIGOCIIU IS NOT NULL AND cclf.CODIGOCIIU <> I_CODIGOCIIU  THEN
            stoo_errmsg := '';
            v_code:= null;
            BEGIN
               UPDATE   LISTA_FISCALIA
                  SET   CODIGOCIIU = cclf.CODIGOCIIU
          WHERE   IDENTIFICACION_FIS = cclf.Identificacion
              AND CLASE_DOCUMENTO_FIS = cclf.clase_doc;

               stoo_rowcnt := SQL%ROWCOUNT;
            EXCEPTION
               WHEN OTHERS THEN
                  stoo_errmsg := SQLERRM;
                  v_code      := SQLCODE;
            END;

            IF v_code <> 0 THEN
               INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       'ERROR ACTUALIZANDO ' ||
                                                       'IDENTIFICACION : '||
                                                       cclf.Identificacion ||
                                                       ' CLASE DOCUMENTO: '||
                                                       ' '||
                                                       cclf.clase_doc ||  
                                                       'CAMPO : CODIGOCIIU'||
                                                       ', OLD '||
                                                       I_CODIGOCIIU ||
                                                       ', NEW ' ||
                                                       cclf.CODIGOCIIU,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
            ELSE
                INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       'ACTUALIZANDO ' ||
                                                       'IDENTIFICACION : '||
                                                       cclf.Identificacion ||
                                                       ' CLASE DOCUMENTO: '||
                                                       ' '||
                                                       cclf.clase_doc ||  
                                                       'CAMPO : CODIGOCIIU'||
                                                       ', OLD '||
                                                       I_CODIGOCIIU ||
                                                       ', NEW ' ||
                                                       cclf.CODIGOCIIU,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
                                  V_FLAG_UPDATE := V_FLAG_UPDATE +1;
            END IF;
         END IF;
         
            IF cclf.ACTIVIDAD_ECONOMICA IS NOT NULL AND cclf.ACTIVIDAD_ECONOMICA <> I_ACTIVIDAD_ECONOMICA  THEN
            stoo_errmsg := '';
            v_code:= null;
            BEGIN
               UPDATE   LISTA_FISCALIA
                  SET   ACTIVIDAD_ECONOMICA = cclf.ACTIVIDAD_ECONOMICA
          WHERE   IDENTIFICACION_FIS = cclf.Identificacion
              AND CLASE_DOCUMENTO_FIS = cclf.clase_doc;

               stoo_rowcnt := SQL%ROWCOUNT;
            EXCEPTION
               WHEN OTHERS THEN
                  stoo_errmsg := SQLERRM;
                  v_code      := SQLCODE;
            END;

            IF v_code <> 0 THEN
               INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       'ERROR ACTUALIZANDO ' ||
                                                       'IDENTIFICACION : '||
                                                       cclf.Identificacion ||
                                                       ' CLASE DOCUMENTO: '||
                                                       ' '||
                                                       cclf.clase_doc ||  
                                                       'CAMPO : ACTIVIDAD_ECONOMICA'||
                                                       ', OLD '||
                                                       I_ACTIVIDAD_ECONOMICA ||
                                                       ', NEW ' ||
                                                       cclf.ACTIVIDAD_ECONOMICA,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
            ELSE
                INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       'ACTUALIZANDO ' ||
                                                       'IDENTIFICACION : '||
                                                       cclf.Identificacion ||
                                                       ' CLASE DOCUMENTO: '||
                                                       ' '||
                                                       cclf.clase_doc ||  
                                                       'CAMPO : ACTIVIDAD_ECONOMICA'||
                                                       ', OLD '||
                                                       I_ACTIVIDAD_ECONOMICA ||
                                                       ', NEW ' ||
                                                       cclf.ACTIVIDAD_ECONOMICA,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
                                  V_FLAG_UPDATE := V_FLAG_UPDATE +1;
            END IF;
         END IF;
         
            IF cclf.CUENTA IS NOT NULL AND cclf.CUENTA <> I_CUENTA  THEN
            stoo_errmsg := '';
            v_code:= null;
            BEGIN
               UPDATE   LISTA_FISCALIA
                  SET   CUENTA = cclf.CUENTA
          WHERE   IDENTIFICACION_FIS = cclf.Identificacion
              AND CLASE_DOCUMENTO_FIS = cclf.clase_doc;

               stoo_rowcnt := SQL%ROWCOUNT;
            EXCEPTION
               WHEN OTHERS THEN
                  stoo_errmsg := SQLERRM;
                  v_code      := SQLCODE;
            END;

            IF v_code <> 0 THEN
               INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       'ERROR ACTUALIZANDO ' ||
                                                       'IDENTIFICACION : '||
                                                       cclf.Identificacion ||
                                                       ' CLASE DOCUMENTO: '||
                                                       ' '||
                                                       cclf.clase_doc ||  
                                                       'CAMPO : CUENTA'||
                                                       ', OLD '||
                                                       I_CUENTA ||
                                                       ', NEW ' ||
                                                       cclf.CUENTA,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
            ELSE
                INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       'ACTUALIZANDO ' ||
                                                       'IDENTIFICACION : '||
                                                       cclf.Identificacion ||
                                                       ' CLASE DOCUMENTO: '||
                                                       ' '||
                                                       cclf.clase_doc ||  
                                                       'CAMPO : CUENTA'||
                                                       ', OLD '||
                                                       I_CUENTA ||
                                                       ', NEW ' ||
                                                       cclf.CUENTA,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
                                  V_FLAG_UPDATE := V_FLAG_UPDATE +1;
            END IF;
         END IF;
         
            IF cclf.COMENTARIO IS NOT NULL AND cclf.COMENTARIO <> I_COMENTARIO  THEN
            stoo_errmsg := '';
            v_code:= null;
            BEGIN
               UPDATE   LISTA_FISCALIA
                  SET   COMENTARIO = cclf.COMENTARIO
          WHERE   IDENTIFICACION_FIS = cclf.Identificacion
              AND CLASE_DOCUMENTO_FIS = cclf.clase_doc;

               stoo_rowcnt := SQL%ROWCOUNT;
            EXCEPTION
               WHEN OTHERS THEN
                  stoo_errmsg := SQLERRM;
                  v_code      := SQLCODE;
            END;

            IF v_code <> 0 THEN
               INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       'ERROR ACTUALIZANDO ' ||
                                                       'IDENTIFICACION : '||
                                                       cclf.Identificacion ||
                                                       ' CLASE DOCUMENTO: '||
                                                       ' '||
                                                       cclf.clase_doc ||  
                                                       'CAMPO : COMENTARIO'||
                                                       ', OLD '||
                                                       I_COMENTARIO ||
                                                       ', NEW ' ||
                                                       cclf.COMENTARIO,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
            ELSE
                INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       'ACTUALIZANDO ' ||
                                                       'IDENTIFICACION : '||
                                                       cclf.Identificacion ||
                                                       ' CLASE DOCUMENTO: '||
                                                       ' '||
                                                       cclf.clase_doc ||  
                                                       'CAMPO : COMENTARIO'||
                                                       ', OLD '||
                                                       I_COMENTARIO ||
                                                       ', NEW ' ||
                                                       cclf.COMENTARIO,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
                                  V_FLAG_UPDATE := V_FLAG_UPDATE +1;
            END IF;
         END IF;
         
            IF cclf.TERMINO IS NOT NULL AND cclf.TERMINO <> I_TERMINO  THEN
            stoo_errmsg := '';
            v_code:= null;
            BEGIN
               UPDATE   LISTA_FISCALIA
                  SET   TERMINO = cclf.TERMINO
          WHERE   IDENTIFICACION_FIS = cclf.Identificacion
              AND CLASE_DOCUMENTO_FIS = cclf.clase_doc;

               stoo_rowcnt := SQL%ROWCOUNT;
            EXCEPTION
               WHEN OTHERS THEN
                  stoo_errmsg := SQLERRM;
                  v_code      := SQLCODE;
            END;

            IF v_code <> 0 THEN
               INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       'ERROR ACTUALIZANDO ' ||
                                                       'IDENTIFICACION : '||
                                                       cclf.Identificacion ||
                                                       ' CLASE DOCUMENTO: '||
                                                       ' '||
                                                       cclf.clase_doc ||  
                                                       'CAMPO : TERMINO'||
                                                       ', OLD '||
                                                       I_TERMINO ||
                                                       ', NEW ' ||
                                                       cclf.TERMINO,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
            ELSE
                INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       'ACTUALIZANDO ' ||
                                                       'IDENTIFICACION : '||
                                                       cclf.Identificacion ||
                                                       ' CLASE DOCUMENTO: '||
                                                       ' '||
                                                       cclf.clase_doc ||  
                                                       'CAMPO : TERMINO'||
                                                       ', OLD '||
                                                       I_TERMINO ||
                                                       ', NEW ' ||
                                                       cclf.TERMINO,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
                                  V_FLAG_UPDATE := V_FLAG_UPDATE +1;
            END IF;
         END IF;
         
            IF cclf.CODIGO_USUARIO IS NOT NULL AND cclf.CODIGO_USUARIO <> I_CODIGO_USUARIO  THEN
            stoo_errmsg := '';
            v_code:= null;
            BEGIN
               UPDATE   LISTA_FISCALIA
                  SET   CODIGO_USUARIO = cclf.CODIGO_USUARIO
          WHERE   IDENTIFICACION_FIS = cclf.Identificacion
              AND CLASE_DOCUMENTO_FIS = cclf.clase_doc;

               stoo_rowcnt := SQL%ROWCOUNT;
            EXCEPTION
               WHEN OTHERS THEN
                  stoo_errmsg := SQLERRM;
                  v_code      := SQLCODE;
            END;

            IF v_code <> 0 THEN
               INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       'ERROR ACTUALIZANDO ' ||
                                                       'IDENTIFICACION : '||
                                                       cclf.Identificacion ||
                                                       ' CLASE DOCUMENTO: '||
                                                       ' '||
                                                       cclf.clase_doc ||  
                                                       'CAMPO : CODIGO_USUARIO'||
                                                       ', OLD '||
                                                       I_CODIGO_USUARIO ||
                                                       ', NEW ' ||
                                                       cclf.CODIGO_USUARIO,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
            ELSE
                INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       'ACTUALIZANDO ' ||
                                                       'IDENTIFICACION : '||
                                                       cclf.Identificacion ||
                                                       ' CLASE DOCUMENTO: '||
                                                       ' '||
                                                       cclf.clase_doc ||  
                                                       'CAMPO : CODIGO_USUARIO'||
                                                       ', OLD '||
                                                       I_CODIGO_USUARIO ||
                                                       ', NEW ' ||
                                                       cclf.CODIGO_USUARIO,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
                                  V_FLAG_UPDATE := V_FLAG_UPDATE +1;
            END IF;
         END IF;
         
            IF cclf.TIME_STAMP IS NOT NULL AND cclf.TIME_STAMP <> I_TIME_STAMP  THEN
            stoo_errmsg := '';
            v_code:= null;
            BEGIN
               UPDATE   LISTA_FISCALIA
                  SET   TIME_STAMP = cclf.TIME_STAMP
          WHERE   IDENTIFICACION_FIS = cclf.Identificacion
              AND CLASE_DOCUMENTO_FIS = cclf.clase_doc;

               stoo_rowcnt := SQL%ROWCOUNT;
            EXCEPTION
               WHEN OTHERS THEN
                  stoo_errmsg := SQLERRM;
                  v_code      := SQLCODE;
            END;

            IF v_code <> 0 THEN
               INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       'ERROR ACTUALIZANDO ' ||
                                                       'IDENTIFICACION : '||
                                                       cclf.Identificacion ||
                                                       ' CLASE DOCUMENTO: '||
                                                       ' '||
                                                       cclf.clase_doc ||  
                                                       'CAMPO : TIME_STAMP'||
                                                       ', OLD '||
                                                       I_TIME_STAMP ||
                                                       ', NEW ' ||
                                                       cclf.TIME_STAMP,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
            ELSE
                INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       'ACTUALIZANDO ' ||
                                                       'IDENTIFICACION : '||
                                                       cclf.Identificacion ||
                                                       ' CLASE DOCUMENTO: '||
                                                       ' '||
                                                       cclf.clase_doc ||  
                                                       'CAMPO : TIME_STAMP'||
                                                       ', OLD '||
                                                       I_TIME_STAMP ||
                                                       ', NEW ' ||
                                                       cclf.TIME_STAMP,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
                                  V_FLAG_UPDATE := V_FLAG_UPDATE +1;
            END IF;
         END IF; 
           IF    I_VALIDATE_TIPO_DE_L IS NOT NULL AND   I_VALIDATE_TIPO_DE_L <>   I_TIPO_DE_L    THEN --CAMPOS NUEVOS
           stoo_errmsg := '';
           v_code:= null;
            BEGIN
               UPDATE   LISTA_FISCALIA
                  SET   TIPO_DE_LEVANTAMIENTO = cclf.TIPO_DE_L
          WHERE   IDENTIFICACION_FIS = cclf.Identificacion
              AND CLASE_DOCUMENTO_FIS = cclf.clase_doc;

               stoo_rowcnt := SQL%ROWCOUNT;
            EXCEPTION
               WHEN OTHERS THEN
                  stoo_errmsg := SQLERRM;
                  v_code      := SQLCODE;
            END;

            IF v_code <> 0 THEN
               INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       'ERROR ACTUALIZANDO ' ||
                                                       'IDENTIFICACION : '||
                                                       cclf.Identificacion ||
                                                       ' CLASE DOCUMENTO: '||
                                                       ' '||
                                                       cclf.clase_doc ||  
                                                       'CAMPO : Tipo de levantamiento'||
                                                       ', OLD '||
                                                       I_TIPO_DE_L||
                                                       ', NEW ' ||
                                                       I_VALIDATE_TIPO_DE_L,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
            ELSE
                INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       'ACTUALIZANDO ' ||
                                                       'IDENTIFICACION : '||
                                                       cclf.Identificacion ||
                                                       ' CLASE DOCUMENTO: '||
                                                       ' '||
                                                       cclf.clase_doc ||  
                                                       'CAMPO : Tipo de levantamiento'||
                                                       ', OLD '||
                                                       I_TIPO_DE_L ||
                                                       ', NEW ' ||
                                                       cclf.TIPO_DE_L,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
                                  V_FLAG_UPDATE := V_FLAG_UPDATE +1;
            END IF;
         END IF; 
         
            IF cclf.Motivo_DE_L IS NOT NULL AND cclf.Motivo_DE_L <>   I_Motivo_DE_L  THEN
            stoo_errmsg := '';
            v_code:= null;
            BEGIN
               UPDATE   LISTA_FISCALIA
                  SET   MOTIVO_DE_LEVANTAMIENTO = cclf.Motivo_DE_L
          WHERE   IDENTIFICACION_FIS = cclf.Identificacion
              AND CLASE_DOCUMENTO_FIS = cclf.clase_doc;

               stoo_rowcnt := SQL%ROWCOUNT;
            EXCEPTION
               WHEN OTHERS THEN
                  stoo_errmsg := SQLERRM;
                  v_code      := SQLCODE;
            END;

            IF v_code <> 0 THEN
               INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       'ERROR ACTUALIZANDO ' ||
                                                       'IDENTIFICACION : '||
                                                       cclf.Identificacion ||
                                                       ' CLASE DOCUMENTO: '||
                                                       ' '||
                                                       cclf.clase_doc ||  
                                                       'CAMPO : MOTIVO_DE_LEVANTAMIENTO'||
                                                       ', OLD '||
                                                       I_Motivo_DE_L ||
                                                       ', NEW ' ||
                                                       cclf.Motivo_DE_L,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
            ELSE
                INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       'ACTUALIZANDO ' ||
                                                       'IDENTIFICACION : '||
                                                       cclf.Identificacion ||
                                                       ' CLASE DOCUMENTO: '||
                                                       ' '||
                                                       cclf.clase_doc ||  
                                                       'CAMPO : MOTIVO_DE_LEVANTAMIENTO'||
                                                       ', OLD '||
                                                       I_Motivo_DE_L ||
                                                       ', NEW ' ||
                                                       cclf.Motivo_DE_L,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
                                  V_FLAG_UPDATE := V_FLAG_UPDATE +1;
            END IF;
         END IF; 
      
     
    END IF;
      END IF;
    
    
    
    
          IF(V_FLAG_UPDATE > 0 OR v_cuenta_nuevos > 0 OR  ( V_FLAG_UPDATE =  0 AND v_cuenta_lista_fiscalia = 1)) THEN
         
         
         IF(V_FLAG_UPDATE > 0) THEN 
         I_STATUS :='M';
         V_CUENTA_UPDATE_TOTALES  := V_CUENTA_UPDATE_TOTALES +1;
         END IF;
         
          IF(V_CUENTA_NUEVOS > 0) THEN 
         I_STATUS :='N';
        v_cuenta_nuevos_TOTALES  := v_cuenta_nuevos_TOTALES +1;
         END IF;
         
      IF(V_FLAG_UPDATE =  0 AND v_cuenta_lista_fiscalia = 1) THEN 
         stoo_errmsg := '';
         v_code:= null;
         I_STATUS :='E';
         
         
                         INSERT INTO   LOG_INSERT_LISTA_FISCALIA(ID,
                                                       NRO_CARGE,
                                                       ESTADO_PROCESO,
                                                       DETALLE,
                                                       FECHA_PROCESO)
                                                       
                VALUES(LILF.NEXTVAL,
                                                       v_nro_cargue,
                                                       'NO PRESENTA CAMBIOS ' ||
                                                       ' IDENTIFICACION : '||
                                                       cclf.Identificacion ||
                                                       ' CLASE DOCUMENTO: '||
                                                       ' '||
                                                       cclf.clase_doc,
                                                       NVL(stoo_errmsg,0),
                                                       SYSDATE);
                                  V_FLAG_UPDATE := V_FLAG_UPDATE +1;
  
  
  
  
         END IF;
         
         BEGIN 
         
         INSERT INTO CONTROL_LISTA_FISCALIA_N_M(ID,
         NRO_CARGE,
         IDENTIFICACION_FIS,
         CLASE_DOCUMENTO_FIS,
         ESTATUS)
         VALUES(CLF_NM.NEXTVAL,
                v_nro_cargue,
                cclf.Identificacion,
                cclf.clase_doc,
                I_STATUS);
         END;
         
        
         
         END IF;
   
         
END LOOP;

--LOS QUE NO SON NUEVOS NI ACTUALIZADOS SE PASAN A UNA TABLA HISTORIA  Y SE BORRAN DE LA TABLA LISTA_FISCALIA--

   INSERT INTO LISTA_FISCALIA_HISTORICO
   SELECT * FROM LISTA_FISCALIA WHERE 
   (IDENTIFICACION_FIS ,CLASE_DOCUMENTO_FIS) NOT IN (
   SELECT IDENTIFICACION_FIS , CLASE_DOCUMENTO_FIS
   FROM CONTROL_LISTA_FISCALIA_N_M
  WHERE  CONTROL_LISTA_FISCALIA_N_M.NRO_CARGE =  v_nro_cargue);
  
  -- SU CUENTAN LOS QUE SE VAN A BORRAR 
  
  select COUNT(*)
  INTO V_BORRADOS_TOTALES
  FROM LISTA_FISCALIA
  WHERE (IDENTIFICACION_FIS ,CLASE_DOCUMENTO_FIS) NOT IN (
  SELECT IDENTIFICACION_FIS , CLASE_DOCUMENTO_FIS
  FROM CONTROL_LISTA_FISCALIA_N_M
  WHERE  CONTROL_LISTA_FISCALIA_N_M.NRO_CARGE =  v_nro_cargue);

--SE BORRAN 

 DELETE FROM LISTA_FISCALIA
  WHERE (IDENTIFICACION_FIS ,CLASE_DOCUMENTO_FIS) NOT IN (
  SELECT IDENTIFICACION_FIS , CLASE_DOCUMENTO_FIS
  FROM CONTROL_LISTA_FISCALIA_N_M
  WHERE  CONTROL_LISTA_FISCALIA_N_M.NRO_CARGE =  v_nro_cargue);

    -------------------------------------
    -- Cuento Nro Registros del Cargue --
    -------------------------------------

   SELECT count(*)
   INTO v_nro_registros
   FROM BX_CARGUE_LISTA_SARLAFT;

    ---------------------------------------
    -- Inserto Informacion de Encabezado --
    ---------------------------------------
 
    INSERT INTO CRG_LISTA_SARLAFT_ENCABEZADO ( NRO_CARGUE, FECHA_CARGUE, NRO_REGISTROS,NRO_NUEVOS,NRO_MODIFICADOS,NRO_BORRADOS)
    VALUES (v_nro_cargue,SYSDATE, v_nro_registros,  v_cuenta_nuevos_TOTALES , V_CUENTA_UPDATE_TOTALES,V_BORRADOS_TOTALES);

    ---------------------------------------
    -- Inserto Informacion Estadistico 2 --
    ---------------------------------------

    INSERT INTO LISTA_FISCALIA_MERGE ( NRO_CARGUE, FECHA_CARGUE, CLASE_DOCUMENTO_FIS, IDENTIFICACION_FIS,
                                       DESCRIPCION_TERCERO, CARACTERISTICA_LAVADO1, 
                                       CARACTERISTICA_LAVADO2, CARACTERISTICA_LAVADO3 )
                                       
    SELECT v_nro_cargue,TO_DATE( v_fecha_cargue, 'YYYYMMDD') , L.Clase_Documento_Fis, L.Identificacion_Fis, L.Descripcion_Tercero, 
           L.CARACTERISTICA_LAVADO1, L.Caracteristica_Lavado2, L.Caracteristica_Lavado3
    FROM terceros T, Lista_Fiscalia L
    WHERE T.Clase_Documento = L.Clase_Documento_Fis
    AND T.Identificacion = L.Identificacion_Fis;
    COMMIT; 

COMMIT;
END;
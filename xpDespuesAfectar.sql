IF EXISTS (SELECT 1 FROM SYS.OBJECTS WHERE name ='xpDespuesAfectar' AND type ='P')
DROP PROC [dbo].[xpDespuesAfectar]
GO
CREATE PROCEDURE [dbo].[xpDespuesAfectar]      
@Modulo								char(5),                          
@ID									int,                          
@Accion								char(20),                          
@Base								char(20),                          
@GenerarMov							char(20),                          
@Usuario							char(10),                          
@SincroFinal						bit,                          
@EnSilencio							bit,                          
@Ok									int      OUTPUT,                          
@OkRef								varchar(255) OUTPUT,                          
@FechaRegistro						datetime                           
AS BEGIN                          
                  
DECLARE     @Empresa			char(5),                          
@IntelMESInterfase				bit ,                        
@Mov							VARCHAR(50),                        
@MovId							VARCHAR(30),                        
@Estatus						VARCHAR(30),                  
@SubClave						VARCHAR(20),            
@Clave							varchar(10),          
@IDNC							INT,      
@Sucursal						int,
@AplicaMovNota					varchar(20),
@AplicaIDMovNota				varchar(20),
@ImporteO						float,
@ImporteAct						float,
@Cliente						varchar(20),
@DiasMoratorios					int,
@Saldo							money,
@SaldoMN						money,
@LimiteCreditoMN				money,
@CreditoCte						money,
@Shell					varchar(8000),
@RutaReportBuilder      varchar(255)

                  
 --Integracion MES------------------------------------------------------------------------------------                          
                  
       IF @Accion='CANCELAR'            
            
   BEGIN            
            
            
   IF @Modulo='VTAS'            
   BEGIN            
     SELECT @MOV=MOV , @ESTATUS = ESTATUS FROM VENTA WHERE ID=@ID              
         IF @MOV LIKE 'fACT%' AND @ESTATUS='CANCELADO'            
         BEGIN            
            
         EXEC MURSPFACTCANCELADANVK  @ID            
         END            
            
   END            
            
            
            
   END            
          
      
--IF @Accion='AFECTAR' AND @Modulo='PC'       
--BEGIN      
----SELECT DISTINCT MOV FROM PC      
--     SELECT @MOV=MOV , @ESTATUS = ESTATUS FROM PC WHERE ID=@ID            
      
--  IF @MOV='Precios' AND @ESTATUS IN ('CONCLUIDO','PENDIENTE','VIGENTE')      
--     BEGIN      
      
      
--  EXEC  MURSPENVIACORREOSPRECIOS @ID       
      
      
--  END       
      
      
      
--END      
      
      
          
          
IF @Modulo='EMB' AND @Accion='AFECTAR'              
BEGIN              
              
EXEC MURSPGENERAGUIAEMBARQUEVTA  @ID               
              
END              
              
              
              
              
IF(@Modulo IN ('INV', 'COMS', 'VTAS', 'PROD') AND @Accion IN ('AFECTAR', 'CANCELAR'))                          
                  
BEGIN                           
                  
 IF (@Modulo ='INV')                          
                  
  SELECT @Empresa=Empresa FROM Inv WHERE ID=@ID                          
                  
 IF (@Modulo ='COMS')                          
                  
  SELECT @Empresa=Empresa FROM Compra WHERE ID=@ID                          
                  
 IF (@Modulo ='VTAS')                          
                  
  SELECT @Empresa=Empresa FROM Venta WHERE ID=@ID                          
                  
 IF (@Modulo ='PROD')                          
                  
  SELECT @Empresa=Empresa FROM Prod WHERE ID=@ID                          
                  
 SELECT @IntelMESInterfase=ISNULL(IntelMESInterfase, 0) FROM EmpresaCfg WHERE Empresa=@Empresa                           
                  
 --IF (@IntelMESInterfase=1)                          
                  
  EXEC xpMESDespuesAfectar @Modulo, @ID, @Accion, @Base, @GenerarMov, @Usuario, @SincroFinal, @EnSilencio,                          
                  
   @Ok OUTPUT, @OkRef OUTPUT, @FechaRegistro                          
                  
END                           
                  
  IF @Modulo = 'INV' AND @Accion IN ('GENERAR', 'AFECTAR')                        
                  
  BEGIN                        
                  
        SELECT @Mov = Mov FROM Inv WHERE ID = @ID                        
             
        IF (SELECT Clave FROM MovTipo WHERE Modulo = 'INV' AND Mov = @Mov) IN ('INV.SI', 'INV.TI', 'INV.EI')                        
                  
    BEGIN                        
                  
         UPDATE InvD SET FechaCaducidad = sl.FechaCaducidad FROM InvD i                         
                  
         JOIN SerieLoteMov sl ON i.ID = sl.ID AND i.Articulo = sl.Articulo AND ISNULL(i.Subcuenta,'') = ISNULL(sl.subcuenta,'')                   
                  
      WHERE i.ID = @ID  AND sl.FechaCaducidad IS NOT NULL                        
                  
    END                        
                  
   END                        
                  
IF @Accion IN ('AFECTAR')         
        
        
        
IF  @Modulo='COMS'          
  BEGIN           
          
          
  EXEC MURSPGENERAPLICACIONCXPNAVITEK @ID          
          
  END          
        
        
        
                  
BEGIN                        
                  
IF @Modulo ='VTAS' AND @Accion = 'AFECTAR' AND @Ok IS NULL
BEGIN
SELECT @Clave				= Clave,
       @SubClave			= SubClave,
	   @Cliente				=v.Cliente,
	   @Empresa				=v.Empresa,
	   @Mov					=V.Mov,
	   @LimiteCreditoMN		= ISNULL(CreditoLimite, 0.0000)
  FROM Venta      v
  JOIN MovTipo    mt        ON v.Mov = mt.Mov AND mt.Modulo = @Modulo
  LEFT JOIN Cte   c 		ON c.Cliente=v.Cliente
 WHERE Id = @Id

       IF   @Clave = 'VTAS.P' AND @SubClave = 'VTAS.PNVK' --AND @Mov = 'Cotizacion'
       BEGIN
			   --EXEC MURSPCOMPARAPRECIOSDETALLE @ID                
			   EXEC MURSPAVISAPARTIDASDESCUENTO @ID, @Ok OUTPUT, @OkRef OUTPUT

			   IF @Mov = 'Cotizacion' AND @OK	IS NULL
			   BEGIN
			   		SELECT @DiasMoratorios = COALESCE(SUM(DiasMoratorios),0), @Saldo = COALESCE(SUM(Saldo),0)
					  FROM CxcInfo
					  WHERE Cliente = @Cliente
						--AND Mov in ('Anticipo T','Cancel Sat Ingresos','Fact S Inv','Factura','Factura Com.Ext40','Factura SI','Nota Cargo')
-- JARC Validación Saldo vencido y límite de Crédito para cotizaciones
				 IF @DiasMoratorios > 0 AND @Saldo > 0.0000
					SELECT @Ok = 80100, @OkRef = 'El Cliente cuenta con un saldo Vencido de $ '+TRIM(CONVERT(VARCHAR, CAST(@Saldo AS money), 1 ))
				 ELSE
						SELECT @CreditoCte = @LimiteCreditoMN-@Saldo
		
						IF @CreditoCte <= 0.0000
						SELECT @Ok = 80100, @OkRef = 'El cliente no cuenta con Crédito disponible $ '+TRIM(CONVERT(varchar, CAST(@CreditoCte AS money), 1))
				END
		END
                  
      --SELECT @MOV=Mov FROM  Venta WHERE ID=@ID                          
                  
        IF  @MOV LIKE 'FAC%'                          
        BEGIN                          
            EXEC MURSPGENERAPLICACIONCXCNAVITEK  @ID                          
        END                          
            
        IF  @MOV = 'Refacturacion NVK'                          
        BEGIN                          
         EXEC MURSPACTUUIDREF  @ID                          
        END                
END                       
                  
 IF @MODULO='AF'                        
                  
  BEGIN                        
                  
        SELECT  @MOV=M.CLAVE,@MOVID=MOVID,@ESTATUS=ESTATUS                         
                  
        FROM ACTIVOFIJO A LEFT OUTER JOIN MOVTIPO M ON A.MOV=M.MOV AND M.MODULO='AF'                         
                  
        WHERE ID=@ID                        
                  
        --SELECT * FROM MOVTIPO WHERE MODULO='AF'                   
                  
        IF  @MOV='AF.MA'  AND @ESTATUS='PENDIENTE'                        
                  
       BEGIN                        
                  
          EXEC     MURSPGENERAREF  @ID                        
                  
      END                        
                  
 END                        
                  
END               
    
    
IF @Modulo = 'CXC' AND @Accion = 'AFECTAR'        
BEGIN        
  SELECT	@Mov		=c.Mov, 
			@Estatus	=c.Estatus,
			@SubClave	=mt.SubClave,
			@Empresa	=c.Empresa
	FROM Cxc c              
	LEFT JOIN MovTipo	mt ON mt.mov=c.mov AND mt.modulo=@Modulo
   WHERE ID=@ID        

IF @Subclave = 'CXC.AANT' AND @Estatus='CONCLUIDO'             
BEGIN

	DECLARE @SalidaAANT TABLE (Linea nvarchar(255) NULL)

		IF EXISTS (SELECT 1 FROM AnexoMov WHERE Rama = 'CXC' AND Icono = 17 AND Tipo = 'ARCHIVO' AND  ID=@ID)
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM AnexoMov WHERE Rama = 'CXC' AND Icono = 745 AND  ID=@ID)
			BEGIN
			
			SELECT @RutaReportBuilder = RTRIM(LTRIM(ISNULL(RutaReportBuilder,'')))
			  FROM EmpresaCFD
			 WHERE Empresa = @Empresa
			 
			SELECT @RutaReportBuilder = '''"'+@RutaReportBuilder+'" ' + CONVERT(VarChar,@ID) + ' /EnSilencio '+LTRIM(RTRIM(@Modulo))+' PDF '+''''

			
			SET @Shell = 'EXEC xp_cmdshell ' + @RutaReportBuilder--+' , no_output'
			
			INSERT INTO @SalidaAANT
			EXEC(@Shell)

				IF EXISTS (SELECT 1 FROM @SalidaAANT)
				BEGIN
					EXEC spEnviarRecepcionPago @ID,@Empresa,@Modulo
				END

			END
		END

END

                       
IF @Mov IN ('Reasignacion' ,'Reasignacion T') AND @Estatus='CONCLUIDO'        
BEGIN        
        
EXEC MURSPNAVREFERENCIA  @ID --,@OK OUTPUT    SELECT DISTINCT MOV FROM CXC    
        
END        
    --JARC Generación y envio de PDF Mov nota de Crédito PP    
	--IF @SubClave = 'CXC.NCPP'   AND @Estatus='CONCLUIDO'             
	--BEGIN

	--DECLARE @Salida TABLE (Linea nvarchar(255) NULL)

	--	IF EXISTS (SELECT 1 FROM AnexoMov WHERE Rama = 'CXC' AND Icono = 17 AND Tipo = 'ARCHIVO' AND  ID=@ID)
	--	BEGIN
	--		IF NOT EXISTS (SELECT 1 FROM AnexoMov WHERE Rama = 'CXC' AND Icono = 745 AND  ID=@ID)
	--		BEGIN
			
	--		SELECT @RutaReportBuilder = RTRIM(LTRIM(ISNULL(RutaReportBuilder,'')))
	--		  FROM EmpresaCFD
	--		 WHERE Empresa = @Empresa
			 
	--		SELECT @RutaReportBuilder = '''"'+@RutaReportBuilder+'" ' + CONVERT(VarChar,@ID) + ' /EnSilencio '+LTRIM(RTRIM(@Modulo))+' PDF '+''''

			
	--		SET @Shell = 'EXEC xp_cmdshell ' + @RutaReportBuilder--+' , no_output'
			
	--		INSERT INTO @Salida
	--		EXEC(@Shell)

	--			IF EXISTS (SELECT 1 FROM @Salida)
	--			BEGIN
	--				EXEC spEnviarRecepcionPago @ID,@Empresa,@Modulo
	--			END

	--		END
	--	END
	--END
END      
    
                  
IF @Modulo = 'CXC' AND @Accion = 'CANCELAR'                           
BEGIN                  
                  
     SELECT @Mov = Mov, @MOVID = MovID FROM CXC WHERE ID = @ID                  
                  
     SELECT @SubClave = SubClave, @Clave = Clave FROM MovTipo WHERE Mov = @MOV and Modulo = @Modulo                  
                  
 -- SELECT @MOV, @SubClave                  
                  
         IF (@MOV = 'Aplicacion Cobro' OR @MOV = 'Cobro') AND @Modulo = 'CXC'--@SubClave = 'CXC.AANT'                      
                  
		BEGIN                  
                  
			SELECT @IDNC = ID  FROM CXC C JOIN Movtipo M ON M.Modulo = 'CXC' AND C.Mov = M.Mov AND M.Clave='CXC.NC'                  
            WHERE Origen = @MOV AND OrigenID = @MOVID                  
                  
			EXEC spAfectar @Modulo, @IDNC, 'CANCELAR',  @EnSilencio = 1, @Conexion = 1, @Usuario=@Usuario, @Ok = @Ok OUTPUT, @OkRef = @OkRef OUTPUT                      
                  
		END  
		
		IF TRIM(@MOV) = 'Nota Credito PP' AND @Accion = 'CANCELAR'
		BEGIN
			SELECT TOP(1) @AplicaMovNota = Aplica, @AplicaIDMovNota = AplicaID, @ImporteAct =  Importe FROM CxcD WHERE ID = @ID
			IF EXISTS(SELECT TOP(1) 0 FROM NaviExploraProntoPago WHERE Mov = @AplicaMovNota AND MovID = @AplicaIDMovNota AND ABS(ISNULL(@ImporteAct,0)-ISNULL(Total,0)) <= 1 AND ISNULL(Procesado,0) = 1 )
			BEGIN
				UPDATE NaviExploraProntoPago SET Procesado = 0 WHERE Mov = @AplicaMovNota AND MovID = @AplicaIDMovNota AND ABS(ISNULL(@ImporteAct,0)-ISNULL(Total,0)) <= 1 AND ISNULL(Procesado,0) = 1
			END
		END
                  
END                                 
--PROCESO DE FINALIZAR NOMINA SI CREO CXP ACTUALICE LA FECHA VENCIMIENTO A FECHA EMISION                     
                  
DECLARE                    
                  
  @Origen Varchar(20),                    
        
  @OrigenID  Varchar(20),                    
                  
  @FechaPago datetime,                    
  @CxpID int                    
                  
SELECT @Mov = Mov FROM Nomina WHERE ID =  @ID                    
                  
 --SELECT Clave,* FROM MovTipo WHERE Modulo = 'NOM' AND Mov = @Mov                    
                  
IF(@Modulo IN ('NOM') AND @Accion IN ('AFECTAR'))                      
                  
    IF (SELECT Clave FROM MovTipo WHERE Modulo = 'NOM' AND Mov = @Mov) IN ('NOM.N')                        
                  
    BEGIN                    
                  
      IF (SELECT Estatus FROM Nomina WHERE ID =  @ID) IN ('CONCLUIDO')                    
                  
     BEGIN                    
                  
     SELECT @Origen = Mov, @OrigenID = MovID, @FechaPago = FechaEmision FROM Nomina WHERE ID =  @ID                    
        
   DECLARE crCXP CURSOR                    
                  
         FOR SELECT ID FROM CXP WHERE MOV = 'Pago Nomina' AND ORIGEN = @Origen AND ORIGENID =@OrigenID AND ESTATUS <> 'CANCELADO'                    
                  
      OPEN crCXP                    
                  
      FETCH NEXT FROM crCXP INTO @CxpID                    
                  
      WHILE @@FETCH_STATUS <> -1 AND @Ok IS NULL                    
                  
      BEGIN                    
                  
        IF @@FETCH_STATUS <> -2 AND @Ok IS NULL                     
                  
        BEGIN                    
                  
            UPDATE CXP SET Vencimiento = @FechaPago WHERE ID = @CxpID                    
                  
        END                     
                  
        FETCH NEXT FROM crCXP INTO @CxpID         
                  
      END  -- While                    
                  
      CLOSE crCXP                    
                  
      DEALLOCATE crCXP                     
                  
  END                    
                  
  END                    
      
  EXEC spMovInfo @ID, @Modulo, @Estatus=@Estatus OUTPUT, @Sucursal=@Sucursal OUTPUT, @Empresa = @Empresa OUTPUT, @Mov=@Mov OUTPUT, @MovID = @MovID OUTPUT, @MovTipo = @Clave OUTPUT      
      
  IF @Accion = 'CANCELAR' AND @Modulo IN ('VTAS', 'COMS', 'INV')      
  BEGIN      
    --Este sp Regresa visibles los movimientos relacionados en la herramienta de Carta Porte Venta      
  EXEC spCancelaHerramientaCartaPorte @ID, @Modulo      
  END 
  
  IF @Modulo = 'COMS' AND @Accion = 'CANCELAR' AND ISNULL(@Base,'') IN ('','TODO','PENDIENTE') 
  AND (SELECT mt.SubClave FROM Compra c JOIN MovTipo mt ON c.Mov = mt.Mov AND mt.Modulo = @Modulo WHERE c.ID = @ID AND c.Estatus = 'CONCLUIDO') = 'COMS.IMPNA' 
  AND (SELECT mt.Clave FROM Compra c JOIN MovTipo mt ON c.Mov = mt.Mov AND mt.Modulo = @Modulo WHERE c.ID = @ID AND c.Estatus = 'CONCLUIDO') = 'COMS.OI'
  BEGIN

	IF EXISTS(
		SELECT TOP(1) 0 FROM MovFlujo WHERE OModulo = 'COMS' AND OID = @ID AND DModulo = 'CXP' AND DMov = 'Gasto Diverso'
		AND ISNULL(Cancelado,0) = 0
	)
	BEGIN -- Gastos Pendientes

		DROP TABLE IF EXISTS #GastosPendientesCancelarEntradaNal
		CREATE TABLE #GastosPendientesCancelarEntradaNal
		(
			ID int NOT NULL
		)

		DECLARE @IDGasto int

		INSERT INTO #GastosPendientesCancelarEntradaNal
		SELECT DISTINCT DID FROM MovFlujo WHERE OModulo = 'COMS' AND OID = @ID AND DModulo = 'CXP' AND DMov = 'Gasto Diverso'
		AND ISNULL(Cancelado,0) = 0

		DECLARE crCancelarGastosPEntradaNal CURSOR FAST_FORWARD FOR
		SELECT
			ID
		FROM #GastosPendientesCancelarEntradaNal
		ORDER BY ID DESC
		
		OPEN crCancelarGastosPEntradaNal
		FETCH NEXT FROM crCancelarGastosPEntradaNal INTO @IDGasto

		WHILE @@FETCH_STATUS = 0
		BEGIN
			
			BEGIN TRANSACTION CancelarGastoTodo
				EXEC spAfectar 'CXP',@IDGasto,'CANCELAR','TODO',@Usuario = @Usuario,@EnSilencio = 1, @Conexion = 1
			COMMIT TRANSACTION CancelarGastoTodo

			FETCH NEXT FROM crCancelarGastosPEntradaNal INTO @IDGasto
		END

		CLOSE crCancelarGastosPEntradaNal
		DEALLOCATE crCancelarGastosPEntradaNal

		--SELECT Estatus,* FROM Cxp where id IN (SELECT ID FROM #GastosPendientesCancelarEntradaNal)

		IF NOT EXISTS(SELECT TOP(1) 0 FROM Cxp WHERE Estatus != 'CANCELADO' AND ID IN (SELECT ID FROM #GastosPendientesCancelarEntradaNal))
		BEGIN -- Se cancelaron correctamente todos los gastos pendientes

			IF EXISTS(SELECT TOP(1) 0 FROM CompraD WHERE ID = @ID AND ISNULL(CantidadCancelada,0) != 0 AND ISNULL(CantidadPendiente,0) = 0)
			BEGIN -- Se actualiza el detalle

				UPDATE CompraD SET CantidadPendiente = CantidadCancelada WHERE ID = @ID AND ISNULL(CantidadCancelada,0) != 0
				UPDATE CompraD SET CantidadCancelada = NULL WHERE ID = @ID

				--SELECT Estatus,* FROM Compra WHERE ID = @ID
				--SELECT Cantidad,CantidadA, CantidadCancelada,CantidadPendiente,* FROM CompraD where id = @ID

				-- Se manda a cancelar la Entrada Nal
				EXEC spAfectar 'COMS',@ID,'CANCELAR','TODO',@Usuario = @Usuario, @EnSilencio = 1

				IF EXISTS(SELECT TOP(1) 0 FROM Compra WHERE ID = @ID AND Estatus = 'PENDIENTE')
					EXEC spAfectar 'COMS',@ID,'CANCELAR','TODO',@Usuario = @Usuario, @EnSilencio = 1
			END

		END

	END -- Gastos Pendientes
  END
      
                  
RETURN                          
                  
END
GO
/**/
--CREATE PROCEDURE [dbo].[xpDespuesAfectar]      
--@Modulo								char(5),                          
--@ID									int,                          
--@Accion								char(20),                          
--@Base								char(20),                          
--@GenerarMov							char(20),                          
--@Usuario							char(10),                          
--@SincroFinal						bit,                          
--@EnSilencio							bit,                          
--@Ok									int      OUTPUT,                          
--@OkRef								varchar(255) OUTPUT,                          
--@FechaRegistro						datetime                           
--AS BEGIN                          
                  
--DECLARE     @Empresa			char(5),                          
--@IntelMESInterfase				bit ,                        
--@Mov							VARCHAR(50),                        
--@MovId							VARCHAR(30),                        
--@Estatus						VARCHAR(30),                  
--@SubClave						VARCHAR(20),            
--@Clave							varchar(10),          
--@IDNC							INT,      
--@Sucursal						int,
--@AplicaMovNota					varchar(20),
--@AplicaIDMovNota				varchar(20),
--@ImporteO						float,
--@ImporteAct						float,
--@Cliente						varchar(20),
--@DiasMoratorios					int,
--@Saldo							money,
--@SaldoMN						money,
--@LimiteCreditoMN				money,
--@CreditoCte						money

                  
-- --Integracion MES------------------------------------------------------------------------------------                          
                  
--       IF @Accion='CANCELAR'            
            
--   BEGIN            
            
            
--   IF @Modulo='VTAS'            
--   BEGIN            
--     SELECT @MOV=MOV , @ESTATUS = ESTATUS FROM VENTA WHERE ID=@ID              
--         IF @MOV LIKE 'fACT%' AND @ESTATUS='CANCELADO'            
--         BEGIN            
            
--         EXEC MURSPFACTCANCELADANVK  @ID            
--         END            
            
--   END            
            
            
            
--   END            
          
      
----IF @Accion='AFECTAR' AND @Modulo='PC'       
----BEGIN      
------SELECT DISTINCT MOV FROM PC      
----     SELECT @MOV=MOV , @ESTATUS = ESTATUS FROM PC WHERE ID=@ID            
      
----  IF @MOV='Precios' AND @ESTATUS IN ('CONCLUIDO','PENDIENTE','VIGENTE')      
----     BEGIN      
      
      
----  EXEC  MURSPENVIACORREOSPRECIOS @ID       
      
      
----  END       
      
      
      
----END      
      
      
          
          
--IF @Modulo='EMB' AND @Accion='AFECTAR'              
--BEGIN              
              
--EXEC MURSPGENERAGUIAEMBARQUEVTA  @ID               
              
--END              
              
              
              
              
--IF(@Modulo IN ('INV', 'COMS', 'VTAS', 'PROD') AND @Accion IN ('AFECTAR', 'CANCELAR'))                          
                  
--BEGIN                           
                  
-- IF (@Modulo ='INV')                          
                  
--  SELECT @Empresa=Empresa FROM Inv WHERE ID=@ID                          
                  
-- IF (@Modulo ='COMS')                          
                  
--  SELECT @Empresa=Empresa FROM Compra WHERE ID=@ID                          
                  
-- IF (@Modulo ='VTAS')                          
                  
--  SELECT @Empresa=Empresa FROM Venta WHERE ID=@ID                          
                  
-- IF (@Modulo ='PROD')                          
                  
--  SELECT @Empresa=Empresa FROM Prod WHERE ID=@ID                          
                  
-- SELECT @IntelMESInterfase=ISNULL(IntelMESInterfase, 0) FROM EmpresaCfg WHERE Empresa=@Empresa                           
                  
-- --IF (@IntelMESInterfase=1)                          
                  
--  EXEC xpMESDespuesAfectar @Modulo, @ID, @Accion, @Base, @GenerarMov, @Usuario, @SincroFinal, @EnSilencio,                          
                  
--   @Ok OUTPUT, @OkRef OUTPUT, @FechaRegistro                          
                  
--END                           
                  
--  IF @Modulo = 'INV' AND @Accion IN ('GENERAR', 'AFECTAR')                        
                  
--  BEGIN                        
                  
--        SELECT @Mov = Mov FROM Inv WHERE ID = @ID                        
             
--        IF (SELECT Clave FROM MovTipo WHERE Modulo = 'INV' AND Mov = @Mov) IN ('INV.SI', 'INV.TI', 'INV.EI')                        
                  
--    BEGIN                        
                  
--         UPDATE InvD SET FechaCaducidad = sl.FechaCaducidad FROM InvD i                         
                  
--         JOIN SerieLoteMov sl ON i.ID = sl.ID AND i.Articulo = sl.Articulo AND ISNULL(i.Subcuenta,'') = ISNULL(sl.subcuenta,'')                   
                  
--      WHERE i.ID = @ID  AND sl.FechaCaducidad IS NOT NULL                        
                  
--    END                        
                  
--   END                        
                  
--IF @Accion IN ('AFECTAR')         
        
        
        
--IF  @Modulo='COMS'          
--  BEGIN           
          
          
--  EXEC MURSPGENERAPLICACIONCXPNAVITEK @ID          
          
--  END          
        
        
        
                  
--BEGIN                        
                  
--IF @Modulo ='VTAS' AND @Accion = 'AFECTAR' AND @Ok IS NULL
--BEGIN
--SELECT @Clave				= Clave,
--       @SubClave			= SubClave,
--	   @Cliente				=v.Cliente,
--	   @Empresa				=v.Empresa,
--	   @Mov					=V.Mov,
--	   @LimiteCreditoMN		= ISNULL(CreditoLimite, 0.0000)
--  FROM Venta      v
--  JOIN MovTipo    mt        ON v.Mov = mt.Mov AND mt.Modulo = @Modulo
--  LEFT JOIN Cte   c 		ON c.Cliente=v.Cliente
-- WHERE Id = @Id

--       IF   @Clave = 'VTAS.P' AND @SubClave = 'VTAS.PNVK' --AND @Mov = 'Cotizacion'
--       BEGIN
--			   --EXEC MURSPCOMPARAPRECIOSDETALLE @ID                
--			   EXEC MURSPAVISAPARTIDASDESCUENTO @ID, @Ok OUTPUT, @OkRef OUTPUT

--			   IF @Mov = 'Cotizacion' AND @OK	IS NULL
--			   BEGIN
--			   		SELECT @DiasMoratorios = COALESCE(SUM(DiasMoratorios),0), @Saldo = COALESCE(SUM(Saldo),0)
--					  FROM CxcInfo
--					  WHERE Cliente = @Cliente
--						--AND Mov in ('Anticipo T','Cancel Sat Ingresos','Fact S Inv','Factura','Factura Com.Ext40','Factura SI','Nota Cargo')
---- JARC Validación Saldo vencido y límite de Crédito para cotizaciones
--				 IF @DiasMoratorios > 0 AND @Saldo > 0.0000
--					SELECT @Ok = 80100, @OkRef = 'El Cliente cuenta con un saldo Vencido de $ '+TRIM(CONVERT(VARCHAR, CAST(@Saldo AS money), 1 ))
--				 ELSE
--						SELECT @CreditoCte = @LimiteCreditoMN-@Saldo
		
--						IF @CreditoCte <= 0.0000
--						SELECT @Ok = 80100, @OkRef = 'El cliente no cuenta con Crédito disponible $ '+TRIM(CONVERT(varchar, CAST(@CreditoCte AS money), 1))
--				END
--		END
                  
--      --SELECT @MOV=Mov FROM  Venta WHERE ID=@ID                          
                  
--        IF  @MOV LIKE 'FAC%'                          
--        BEGIN                          
--            EXEC MURSPGENERAPLICACIONCXCNAVITEK  @ID                          
--        END                          
            
--        IF  @MOV = 'Refacturacion NVK'                          
--        BEGIN                          
--         EXEC MURSPACTUUIDREF  @ID                          
--        END                
--END                       
                  
-- IF @MODULO='AF'                        
                  
--  BEGIN                        
                  
--        SELECT  @MOV=M.CLAVE,@MOVID=MOVID,@ESTATUS=ESTATUS                         
                  
--        FROM ACTIVOFIJO A LEFT OUTER JOIN MOVTIPO M ON A.MOV=M.MOV AND M.MODULO='AF'                         
                  
--        WHERE ID=@ID                        
                  
--        --SELECT * FROM MOVTIPO WHERE MODULO='AF'                   
                  
--        IF  @MOV='AF.MA'  AND @ESTATUS='PENDIENTE'                        
                  
--       BEGIN                        
                  
--          EXEC     MURSPGENERAREF  @ID                        
                  
--      END                        
                  
-- END                        
                  
--END               
    
    
--IF @Modulo = 'CXC' AND @Accion = 'AFECTAR'        
        
--BEGIN        
        
--  select @Mov=c.Mov, @ESTATUS=c.Estatus          
--  from Cxc c              
--  WHERE ID=@ID        
                       
--IF @MOV IN ('reasignacion' ,'Reasignacion T' )AND @ESTATUS='concluido'        
--BEGIN        
        
--EXEC MURSPNAVREFERENCIA  @ID --,@OK OUTPUT    SELECT DISTINCT MOV FROM CXC    
        
--END        
        
        
        
--END      
    
                  
--IF @Modulo = 'CXC' AND @Accion = 'CANCELAR'                           
--BEGIN                  
                  
--     SELECT @Mov = Mov, @MOVID = MovID FROM CXC WHERE ID = @ID                  
                  
--     SELECT @SubClave = SubClave, @Clave = Clave FROM MovTipo WHERE Mov = @MOV and Modulo = @Modulo                  
                  
-- -- SELECT @MOV, @SubClave                  
                  
--         IF (@MOV = 'Aplicacion Cobro' OR @MOV = 'Cobro') AND @Modulo = 'CXC'--@SubClave = 'CXC.AANT'                      
                  
--		BEGIN                  
                  
--			SELECT @IDNC = ID  FROM CXC C JOIN Movtipo M ON M.Modulo = 'CXC' AND C.Mov = M.Mov AND M.Clave='CXC.NC'                  
--            WHERE Origen = @MOV AND OrigenID = @MOVID                  
                  
--			EXEC spAfectar @Modulo, @IDNC, 'CANCELAR',  @EnSilencio = 1, @Conexion = 1, @Usuario=@Usuario, @Ok = @Ok OUTPUT, @OkRef = @OkRef OUTPUT                      
                  
--		END  
		
--		IF TRIM(@MOV) = 'Nota Credito PP' AND @Accion = 'CANCELAR'
--		BEGIN
--			SELECT TOP(1) @AplicaMovNota = Aplica, @AplicaIDMovNota = AplicaID, @ImporteAct =  Importe FROM CxcD WHERE ID = @ID
--			IF EXISTS(SELECT TOP(1) 0 FROM NaviExploraProntoPago WHERE Mov = @AplicaMovNota AND MovID = @AplicaIDMovNota AND ABS(ISNULL(@ImporteAct,0)-ISNULL(Total,0)) <= 1 AND ISNULL(Procesado,0) = 1 )
--			BEGIN
--				UPDATE NaviExploraProntoPago SET Procesado = 0 WHERE Mov = @AplicaMovNota AND MovID = @AplicaIDMovNota AND ABS(ISNULL(@ImporteAct,0)-ISNULL(Total,0)) <= 1 AND ISNULL(Procesado,0) = 1
--			END
--		END
                  
--END                                 
----PROCESO DE FINALIZAR NOMINA SI CREO CXP ACTUALICE LA FECHA VENCIMIENTO A FECHA EMISION                     
                  
--DECLARE                    
                  
--  @Origen Varchar(20),                    
        
--  @OrigenID  Varchar(20),                    
                  
--  @FechaPago datetime,                    
--  @CxpID int                    
                  
--SELECT @Mov = Mov FROM Nomina WHERE ID =  @ID                    
                  
-- --SELECT Clave,* FROM MovTipo WHERE Modulo = 'NOM' AND Mov = @Mov                    
                  
--IF(@Modulo IN ('NOM') AND @Accion IN ('AFECTAR'))                      
                  
--    IF (SELECT Clave FROM MovTipo WHERE Modulo = 'NOM' AND Mov = @Mov) IN ('NOM.N')                        
                  
--    BEGIN                    
                  
--      IF (SELECT Estatus FROM Nomina WHERE ID =  @ID) IN ('CONCLUIDO')                    
                  
--     BEGIN                    
                  
--     SELECT @Origen = Mov, @OrigenID = MovID, @FechaPago = FechaEmision FROM Nomina WHERE ID =  @ID                    
        
--   DECLARE crCXP CURSOR                    
                  
--         FOR SELECT ID FROM CXP WHERE MOV = 'Pago Nomina' AND ORIGEN = @Origen AND ORIGENID =@OrigenID AND ESTATUS <> 'CANCELADO'                    
                  
--      OPEN crCXP                    
                  
-- FETCH NEXT FROM crCXP INTO @CxpID                    
                  
--      WHILE @@FETCH_STATUS <> -1 AND @Ok IS NULL                    
                  
--      BEGIN                    
                  
--        IF @@FETCH_STATUS <> -2 AND @Ok IS NULL                     
                  
--        BEGIN                    
                  
--            UPDATE CXP SET Vencimiento = @FechaPago WHERE ID = @CxpID                    
                  
--        END                     
                  
--        FETCH NEXT FROM crCXP INTO @CxpID         
                  
--      END  -- While                    
                  
--      CLOSE crCXP                    
                  
--      DEALLOCATE crCXP                     
                  
--  END                    
                  
--  END                    
      
--  EXEC spMovInfo @ID, @Modulo, @Estatus=@Estatus OUTPUT, @Sucursal=@Sucursal OUTPUT, @Empresa = @Empresa OUTPUT, @Mov=@Mov OUTPUT, @MovID = @MovID OUTPUT, @MovTipo = @Clave OUTPUT      
      
--  IF @Accion = 'CANCELAR' AND @Modulo IN ('VTAS', 'COMS', 'INV')      
--  BEGIN      
--    --Este sp Regresa visibles los movimientos relacionados en la herramienta de Carta Porte Venta      
--  EXEC spCancelaHerramientaCartaPorte @ID, @Modulo      
--  END 
  
--  IF @Modulo = 'COMS' AND @Accion = 'CANCELAR' AND ISNULL(@Base,'') IN ('','TODO','PENDIENTE') 
--  AND (SELECT mt.SubClave FROM Compra c JOIN MovTipo mt ON c.Mov = mt.Mov AND mt.Modulo = @Modulo WHERE c.ID = @ID AND c.Estatus = 'CONCLUIDO') = 'COMS.IMPNA' 
--  AND (SELECT mt.Clave FROM Compra c JOIN MovTipo mt ON c.Mov = mt.Mov AND mt.Modulo = @Modulo WHERE c.ID = @ID AND c.Estatus = 'CONCLUIDO') = 'COMS.OI'
--  BEGIN

--	IF EXISTS(
--		SELECT TOP(1) 0 FROM MovFlujo WHERE OModulo = 'COMS' AND OID = @ID AND DModulo = 'CXP' AND DMov = 'Gasto Diverso'
--		AND ISNULL(Cancelado,0) = 0
--	)
--	BEGIN -- Gastos Pendientes

--		DROP TABLE IF EXISTS #GastosPendientesCancelarEntradaNal
--		CREATE TABLE #GastosPendientesCancelarEntradaNal
--		(
--			ID int NOT NULL
--		)

--		DECLARE @IDGasto int

--		INSERT INTO #GastosPendientesCancelarEntradaNal
--		SELECT DISTINCT DID FROM MovFlujo WHERE OModulo = 'COMS' AND OID = @ID AND DModulo = 'CXP' AND DMov = 'Gasto Diverso'
--		AND ISNULL(Cancelado,0) = 0

--		DECLARE crCancelarGastosPEntradaNal CURSOR FAST_FORWARD FOR
--		SELECT
--			ID
--		FROM #GastosPendientesCancelarEntradaNal
--		ORDER BY ID DESC
		
--		OPEN crCancelarGastosPEntradaNal
--		FETCH NEXT FROM crCancelarGastosPEntradaNal INTO @IDGasto

--		WHILE @@FETCH_STATUS = 0
--		BEGIN
			
--			BEGIN TRANSACTION CancelarGastoTodo
--				EXEC spAfectar 'CXP',@IDGasto,'CANCELAR','TODO',@Usuario = @Usuario,@EnSilencio = 1, @Conexion = 1
--			COMMIT TRANSACTION CancelarGastoTodo

--			FETCH NEXT FROM crCancelarGastosPEntradaNal INTO @IDGasto
--		END

--		CLOSE crCancelarGastosPEntradaNal
--		DEALLOCATE crCancelarGastosPEntradaNal

--		--SELECT Estatus,* FROM Cxp where id IN (SELECT ID FROM #GastosPendientesCancelarEntradaNal)

--		IF NOT EXISTS(SELECT TOP(1) 0 FROM Cxp WHERE Estatus != 'CANCELADO' AND ID IN (SELECT ID FROM #GastosPendientesCancelarEntradaNal))
--		BEGIN -- Se cancelaron correctamente todos los gastos pendientes

--			IF EXISTS(SELECT TOP(1) 0 FROM CompraD WHERE ID = @ID AND ISNULL(CantidadCancelada,0) != 0 AND ISNULL(CantidadPendiente,0) = 0)
--			BEGIN -- Se actualiza el detalle

--				UPDATE CompraD SET CantidadPendiente = CantidadCancelada WHERE ID = @ID AND ISNULL(CantidadCancelada,0) != 0
--				UPDATE CompraD SET CantidadCancelada = NULL WHERE ID = @ID

--				--SELECT Estatus,* FROM Compra WHERE ID = @ID
--				--SELECT Cantidad,CantidadA, CantidadCancelada,CantidadPendiente,* FROM CompraD where id = @ID

--				-- Se manda a cancelar la Entrada Nal
--				EXEC spAfectar 'COMS',@ID,'CANCELAR','TODO',@Usuario = @Usuario, @EnSilencio = 1

--				IF EXISTS(SELECT TOP(1) 0 FROM Compra WHERE ID = @ID AND Estatus = 'PENDIENTE')
--					EXEC spAfectar 'COMS',@ID,'CANCELAR','TODO',@Usuario = @Usuario, @EnSilencio = 1
--			END

--		END

--	END -- Gastos Pendientes
--  END
      
                  
--RETURN                          
                  
--END
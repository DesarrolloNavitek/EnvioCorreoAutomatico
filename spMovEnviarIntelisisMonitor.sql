/**********************************************************************************************   spMovEnviarIntelisisMonitor   *********************************************************************************************/
IF EXISTS (SELECT * FROM SYSOBJECTS WHERE name = 'spMovEnviarIntelisisMonitor' AND type = 'P')
DROP PROC [dbo].[spMovEnviarIntelisisMonitor]
GO
CREATE PROCEDURE spMovEnviarIntelisisMonitor
@Estacion int,
@Empresa  varchar(5),
@Mov		 varchar(20)
WITH ENCRYPTION
AS BEGIN
DECLARE
@Enviar					bit,
@Archivos				varchar(255),
@Para					varchar(255),
@Reporteador            varchar(30),
@Asunto					varchar(255),
@Mensaje				varchar(255),
@EnviarAlAfectar        bit,
@AlmacenarPDF           bit,
@ArchivoXML				varchar(255),
@ArchivoPDF				varchar(255),
@Cliente			    varchar(10),
@Nombre					varchar(100),
@MovID					varchar(20),
@Sucursal				int,
@Agente					varchar(10),
@FechaEmision			datetime,
@FechaRegistro			datetime,
@Serie					varchar(20),
@Folio					bigint,
@Modulo					varchar(5),
@ModuloID			    int,
@eMail				    varchar(100),
@TipoComprobante		varchar(20)
DECLARE crListaModuloID CURSOR FOR
SELECT Modulo, ID
FROM ListaModuloID
WHERE Estacion = @Estacion
OPEN crListaModuloID
FETCH NEXT FROM crListaModuloID INTO @Modulo, @ModuloID
WHILE @@FETCH_STATUS = 0
BEGIN
SELECT @Enviar = 0, @Archivos = '', @eMail = '', @Para = ''
SELECT @Enviar = Enviar,
@EnviarAlAfectar = EnviarAlAfectar,
@AlmacenarPDF = AlmacenarPDF,
@Asunto = EnviarAsunto,
@Mensaje = EnviarMensaje,
@Reporteador = Reporteador,
@Nombre = Nombre
FROM EmpresaCFD
WHERE Empresa = @Empresa
IF @Modulo = 'VTAS'
SELECT @Empresa = v.Empresa, 
@Sucursal = v.Sucursal, 
@Cliente = RTRIM(v.Cliente), 
@Agente = RTRIM(v.Agente), 
@Mov = RTRIM(v.Mov), 
@MovID = RTRIM(v.MovID), 
@FechaEmision = v.FechaEmision, 
@FechaRegistro = v.FechaRegistro, 
@TipoComprobante = mt.CFD_tipoDeComprobante FROM Venta v JOIN MovTipo mt ON v.Mov = mt.Mov AND mt.Modulo = 'VTAS' WHERE v.ID= @ModuloID
IF @Modulo = 'CXC'
BEGIN
SELECT 
@Empresa = c.Empresa, 
@Sucursal = c.Sucursal, 
@Cliente = RTRIM(c.Cliente), 
@Agente = RTRIM(c.Agente), 
@Mov = RTRIM(c.Mov), 
@MovID = RTRIM(c.MovID), 
@FechaEmision = c.FechaEmision,
@FechaRegistro = c.FechaRegistro, 
@TipoComprobante = mt.CFD_tipoDeComprobante 
FROM Cxc c JOIN MovTipo mt ON c.Mov = mt.Mov AND mt.Modulo = 'CXC' 
WHERE c.ID= @ModuloID

IF dbo.fnMovTipo(@Modulo,@Mov) = 'CXC.C' AND ISNULL(@TipoComprobante,'') = ''	
SELECT @TipoComprobante = 'PAGO'
			ELSE
				EXEC spEnviarRecepcionPago @ModuloID,@Empresa,@Modulo

END
EXEC spMovIDEnSerieConsecutivo @MovID, @Serie OUTPUT, @Folio OUTPUT
SET @Nombre = ISNULL(@Nombre,'')
SELECT @Nombre = REPLACE(@Nombre, '<Movimiento>', LTRIM(RTRIM(ISNULL(@Mov,''))))
SELECT @Nombre = REPLACE(@Nombre, '<Serie>', LTRIM(RTRIM(ISNULL(@Serie,''))))
SELECT @Nombre = REPLACE(@Nombre, '<Folio>', CONVERT(varchar, LTRIM(RTRIM(ISNULL(@Folio,'')))))
SELECT @Nombre = REPLACE(@Nombre, '<Cliente>', LTRIM(RTRIM(ISNULL(@Cliente,''))))
SELECT @Nombre = REPLACE(@Nombre, '<Empresa>', LTRIM(RTRIM(ISNULL(@Empresa,''))))
SELECT @Nombre = REPLACE(@Nombre, '<Sucursal>', LTRIM(RTRIM(ISNULL(CONVERT(varchar, @Sucursal),''))))
SELECT @Nombre = REPLACE(@Nombre, '<Ejercicio>', LTRIM(RTRIM(ISNULL(CONVERT(varchar, YEAR(GETDATE())),''))))
SELECT @Nombre = REPLACE(@Nombre, '<Periodo>', LTRIM(RTRIM(ISNULL(CONVERT(varchar, MONTH(GETDATE())),''))))
SELECT @Asunto  = REPLACE(@Asunto, '<Nombre>', @Nombre),
@Mensaje = REPLACE(@Mensaje, '<Nombre>', @Nombre)
SELECT @ArchivoPDF = Direccion
FROM AnexoMov
WHERE Rama = @Modulo AND ID = @ModuloID AND CFD = 1 AND Nombre LIKE '%.pdf'
SELECT @ArchivoXML = Direccion
FROM AnexoMov
WHERE Rama = @Modulo AND ID = @ModuloID AND CFD = 1 AND Nombre LIKE '%.xml'
IF ISNULL(@ArchivoPDF,'') <> ''
SET @Archivos = @ArchivoPDF + ';'
IF ISNULL(@ArchivoXML,'') <> ''
SET @Archivos = @Archivos + @ArchivoXML
DECLARE crCteCto CURSOR  FOR
SELECT eMail
FROM CteCto
WHERE Cliente = @Cliente AND CFD_Enviar = 1 AND NULLIF(RTRIM(eMail), '') IS NOT NULL
AND 1 = CASE	WHEN ISNULL(UPPER(@TipoComprobante),'') = 'INGRESO' THEN ISNULL(EnviarIngreso,0)
				WHEN ISNULL(UPPER(@TipoComprobante),'') = 'EGRESO' THEN ISNULL(EnviarEgreso,0)
				WHEN ISNULL(UPPER(@TipoComprobante),'') = 'TRASLADO' THEN ISNULL(EnviarTraslado,0)
				WHEN ISNULL(UPPER(@TipoComprobante),'') = 'PAGO' THEN ISNULL(EnviarRecepcionPago,0)
				ELSE 0
		END
OPEN crCteCto
FETCH NEXT FROM crCteCto INTO @eMail
WHILE @@FETCH_STATUS <> -1 AND @@Error = 0
BEGIN
IF @@FETCH_STATUS <> -2
BEGIN
IF @Para <> '' SELECT @Para = @Para+';'
SELECT @Para = @Para + @eMail
END
FETCH NEXT FROM crCteCto INTO @eMail
END
CLOSE crCteCto
DEALLOCATE crCteCto
IF @Reporteador is null  select @Reporteador = 'Reporteador Intelisis'
IF (@EnviarAlAfectar = 1) AND NULLIF(@Archivos,'') IS NOT NULL AND @Reporteador ='Reporteador Intelisis'
BEGIN
EXEC spCFDFlexEnviarCorreo @Empresa, @Para, @Asunto, @Mensaje, @Archivos
END
FETCH NEXT FROM crListaModuloID INTO @Modulo, @ModuloID
END
CLOSE crListaModuloID
DEALLOCATE crListaModuloID
DELETE FROM ListaModuloID WHERE Estacion = @Estacion
RETURN
END
GO
SET DATEFIRST 7
SET ANSI_NULLS OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET LOCK_TIMEOUT -1
SET QUOTED_IDENTIFIER OFF
GO
--exec NVK_spEnvioMail 'NVK'
/**********************************************************************************************   NVK_spEnvioMail   *********************************************************************************************/
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'NVK_spEnvioMail' AND type = 'P')
DROP PROC dbo.NVK_spEnvioMail
GO
CREATE PROC dbo.NVK_spEnvioMail
@Empresa		char(5)
AS
BEGIN
DECLARE
@FechaA			date,
@i				int = 0,
@Cuantos		int,
@Fila			int,
@Modulo			varchar(5),
@Id				int


SET @FechaA = GETDATE()

SELECT a.ID,'CXC' AS Modulo --COUNT(*) 
  INTO #RegProc
  FROM Cxc						a
  LEFT JOIN LogEnvioMail		b	ON b.ModuloId = a.ID
  LEFT JOIN MovTipo				c	ON c.Mov = a.Mov
 WHERE a.Estatus		= 'CONCLUIDO'
   AND a.Empresa		= @Empresa
   AND a.ID NOT IN (b.ModuloID)
   AND c.Modulo			= 'CXC'
   AND c.Clave			= 'CXC.ANC' 
   AND c.SubClave		= 'CXC.AANT'
   AND dbo.fnFechaSinHora(a.FechaEmision) = dbo.fnFechaSinHora(@FechaA)
   --AND dbo.fnFechaSinHora(a.FechaEmision) = '03/03/2026'

SELECT ROW_NUMBER() OVER (ORDER BY ID) AS Fila,
		ID,
		Modulo,
		0 AS Procesado
  INTO #While
  FROM #RegProc

SELECT @Cuantos = COUNT(*)
  FROM #While


WHILE (@i < @Cuantos)
BEGIN

	SET @i = @i + 1

	SELECT  @Fila = Fila, 
			@Id = Id, 
			@Modulo = Modulo
	  FROM #While
	 WHERE @i = Fila
	   AND Procesado = 0

	 EXEC spEnviarRecepcionPago @ID, @Empresa, @Modulo

	 UPDATE #While SET Procesado = 1 WHERE Fila = @i


END
RETURN
END
GO
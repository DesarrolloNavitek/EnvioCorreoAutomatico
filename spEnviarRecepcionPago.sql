IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'spEnviarRecepcionPago' AND type = 'P')
    DROP PROC dbo.spEnviarRecepcionPago
GO

CREATE PROCEDURE dbo.spEnviarRecepcionPago
    @ID				INT,
    @Empresa		VARCHAR(5),
    @Modulo			VARCHAR(5)
AS
BEGIN
    --SET NOCOUNT ON;
	DECLARE
        @Enviar          BIT,
        @Archivos        VARCHAR(255),
        @Para            VARCHAR(255),
        @Reporteador     VARCHAR(30),
        @Asunto          VARCHAR(255),
        @Mensaje         VARCHAR(255),
        @EnviarAlAfectar BIT,
        @AlmacenarPDF    BIT,
        @ArchivoXML      VARCHAR(255),
        @ArchivoPDF      VARCHAR(255),
        @Cliente         VARCHAR(10),
        @Nombre          VARCHAR(100),
        @MovID           VARCHAR(20),
        @Sucursal        INT,
        @Agente          VARCHAR(10),
        @FechaEmision    DATETIME,
        @FechaRegistro   DATETIME,
        @Serie           VARCHAR(20),
        @Folio           VARCHAR(50),
        @eMail           VARCHAR(100),
        @Mov             VARCHAR(20)     = NULL,
        @EnviarXML       BIT,
        @EnviarPDF       BIT,
        @TipoComprobante VARCHAR(20);

    SELECT @EnviarAlAfectar = EnviarAlAfectar
    FROM   EmpresaCFD
    WHERE  Empresa = @Empresa;


    IF @Modulo = 'CXC'
    BEGIN
        SELECT
            @Empresa         = c.Empresa,
            @Sucursal        = c.Sucursal,
            @Cliente         = RTRIM(c.Cliente),
            @Agente          = RTRIM(c.Agente),
            @Mov             = RTRIM(c.Mov),
            @MovID           = RTRIM(c.MovID),
            @FechaEmision    = c.FechaEmision,
            @FechaRegistro   = c.FechaRegistro,
            @TipoComprobante = 'PAGO'
        FROM  Cxc     AS c
        JOIN  MovTipo AS mt ON mt.Mov    = c.Mov
                           AND mt.Modulo = 'CXC'
        WHERE c.ID = @ID;
    END

    IF @Modulo = 'DIN'
    BEGIN
        SELECT
            @Empresa         = d.Empresa,
            @Sucursal        = d.Sucursal,
            @Cliente         = RTRIM(d.Cliente),
            @Mov             = RTRIM(d.Mov),
            @MovID           = RTRIM(d.MovID),
            @FechaEmision    = d.FechaEmision,
            @FechaRegistro   = d.FechaRegistro,
            @TipoComprobante = mt.CFD_tipoDeComprobante
        FROM  Dinero  AS d
        JOIN  MovTipo AS mt ON mt.Mov    = d.Mov
                           AND mt.Modulo = 'DIN'
        WHERE d.ID = @ID;


        ;WITH cte AS
        (
            SELECT OID, OModulo, OMov, OMovID, DID, DModulo, DMov, DMovID, 1 AS Nivel
            FROM   dbo.movflujo
            WHERE  DID     = @ID
              AND  DModulo = @Modulo
              AND  Empresa = @Empresa

            UNION ALL

            SELECT e.OID, e.OModulo, e.OMov, e.OMovID,
                   e.DID, e.DModulo, e.DMov, e.DMovID,
                   cte.Nivel + 1
            FROM   dbo.movflujo AS e
            INNER  JOIN cte ON e.DID     = cte.OID
                           AND e.DModulo = cte.OModulo
        )
        SELECT @Cliente = a.Cliente
        FROM   cte       AS b
        INNER  JOIN Cxc      AS a  ON  a.ID  = b.OID
        INNER  JOIN MovTipo  AS mt ON mt.Mov  = a.Mov
        WHERE  mt.Clave IN ('CXC.C');
    END


    SELECT @Enviar   = 0,
           @Archivos = '',
           @eMail    = '',
		   @Para	 = '';

    SELECT @Enviar = cc.Enviar
    FROM   CteCFD AS cc
    WHERE  cc.Cliente = @Cliente;

    IF @Enviar = 1
    BEGIN
        SELECT
            @EnviarXML = cc.EnviarXML,
            @EnviarPDF = cc.EnviarPDF,
            @Asunto    = cc.EnviarAsunto,
            @Mensaje   = cc.EnviarMensaje,
            @Nombre    = cc.Nombre
        FROM   CteCFD AS cc
        WHERE  cc.Cliente = @Cliente;
    END
    ELSE
    BEGIN
        SELECT
            @Enviar          = Enviar,
			--@EnviarPDF		 = EnviarPDF,
			--@EnviarXML		 = EnviarXML,
            @EnviarPDF       = 1,          -- forzado siempre en config. empresa
            @EnviarXML       = 1,          -- forzado siempre en config. empresa
            @EnviarAlAfectar = EnviarAlAfectar,
            @AlmacenarPDF    = AlmacenarPDF,
            @Asunto          = EnviarAsunto,
            @Mensaje         = EnviarMensaje,
            @Reporteador     = Reporteador,
            @Nombre          = Nombre
        FROM   EmpresaCFD
        WHERE  Empresa = @Empresa;
    END

    EXEC spMovIDEnSerieConsecutivo @MovID, @Serie OUTPUT, @Folio OUTPUT;

    SET @Nombre = ISNULL(@Nombre, '');

    SET @Nombre = REPLACE(@Nombre, '<Movimiento>', LTRIM(RTRIM(ISNULL(@Mov,     ''))));
    SET @Nombre = REPLACE(@Nombre, '<Serie>',      LTRIM(RTRIM(ISNULL(@Serie,   ''))));
    SET @Nombre = REPLACE(@Nombre, '<Folio>',      LTRIM(RTRIM(ISNULL(CONVERT(VARCHAR, @Folio), ''))));
    SET @Nombre = REPLACE(@Nombre, '<Cliente>',    LTRIM(RTRIM(ISNULL(@Cliente, ''))));
    SET @Nombre = REPLACE(@Nombre, '<Empresa>',    LTRIM(RTRIM(ISNULL(@Empresa, ''))));
    SET @Nombre = REPLACE(@Nombre, '<Sucursal>',   LTRIM(RTRIM(ISNULL(CONVERT(VARCHAR, @Sucursal),   ''))));
    SET @Nombre = REPLACE(@Nombre, '<Ejercicio>',  LTRIM(RTRIM(ISNULL(CONVERT(VARCHAR, YEAR(GETDATE())),  ''))));
    SET @Nombre = REPLACE(@Nombre, '<Periodo>',    LTRIM(RTRIM(ISNULL(CONVERT(VARCHAR, MONTH(GETDATE())), ''))));

    SET @Asunto  = REPLACE(@Asunto,  '<Nombre>', @Nombre);
    SET @Mensaje = REPLACE(@Mensaje, '<Nombre>', @Nombre);


    SELECT @ArchivoPDF = Direccion
    FROM   AnexoMov
    WHERE  Rama   = @Modulo
      AND  ID     = @ID
      AND  CFD    = 1
      AND  Nombre LIKE '%.pdf';

    SELECT @ArchivoXML = Direccion
    FROM   AnexoMov
    WHERE  Rama   = @Modulo
      AND  ID     = @ID
      AND  CFD    = 1
      AND  Nombre LIKE '%.xml';


    IF @EnviarPDF = 1 AND @EnviarXML = 1
    BEGIN
        SET @Archivos = '';
        IF ISNULL(@ArchivoPDF, '') <> ''
            SET @Archivos = @ArchivoPDF + ';';
        IF ISNULL(@ArchivoXML, '') <> ''
            SET @Archivos = @Archivos + @ArchivoXML;
        /* Si no hay XML, quitar el punto y coma final */
        IF ISNULL(@ArchivoXML, '') = ''
            SET @Archivos = @ArchivoPDF;
    END

    IF @EnviarPDF = 1 AND @EnviarXML = 0
        SET @Archivos = @ArchivoPDF;

    /* ------------------------------------------------------------------|*/
    /*  BUG #1 CORREGIDO                                                 |*/
    /*  Antes: SET @Archivos = @ArchivoPDF  (incorrecto cuando solo XML) |*/
    /*  Ahora: SET @Archivos = @ArchivoXML                               |*/
    /* ------------------------------------------------------------------|*/
    IF @EnviarPDF = 0 AND @EnviarXML = 1
        SET @Archivos = @ArchivoXML;

    IF ISNULL(@Archivos, '') <> ''
    BEGIN

        DECLARE crCteCto CURSOR LOCAL FAST_FORWARD FOR
            SELECT eMail
            FROM   CteCto
            WHERE  Cliente   = @Cliente
              AND  CFD_Enviar = 1
              AND  ISNULL(RTRIM(eMail), '') <> ''
              AND  1 = CASE
                           WHEN ISNULL(UPPER(@TipoComprobante), '') = 'INGRESO'  THEN ISNULL(EnviarIngreso,         0)
                           WHEN ISNULL(UPPER(@TipoComprobante), '') = 'EGRESO'   THEN ISNULL(EnviarEgreso,          0)
                           WHEN ISNULL(UPPER(@TipoComprobante), '') = 'TRASLADO' THEN ISNULL(EnviarTraslado,        0)
                           WHEN ISNULL(UPPER(@TipoComprobante), '') = 'PAGO'     THEN ISNULL(EnviarRecepcionPago,   0)
                           ELSE 0
                       END;

        OPEN crCteCto;
        FETCH NEXT FROM crCteCto INTO @eMail;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            IF ISNULL(@Para, '') <> ''
            BEGIN
                SET @Para = @Para + ';';
            END
            SET @Para = @Para + @eMail;

            FETCH NEXT FROM crCteCto INTO @eMail;
        END

        CLOSE    crCteCto;
        DEALLOCATE crCteCto;

    END -- IF ISNULL(@Archivos,'') <> ''

    IF ISNULL(@Para, '') = '' AND ISNULL(@Archivos, '') <> ''
    BEGIN
        SELECT @Para = c.eMail1
        FROM   Cte AS c
        WHERE  c.Cliente = @Cliente;
    END

    --SELECT
    --    @EnviarAlAfectar AS EnviarAlAfectar,
    --    @Archivos        AS Archivos,
    --    @Empresa         AS Empresa,
    --    @Para            AS Para,
    --    @Asunto          AS Asunto,
    --    @Mensaje         AS Mensaje,
    --    @TipoComprobante AS TipoComprobante;

    IF  @EnviarAlAfectar = 1
    AND ISNULL(@Para, '') <> '' 
	AND ISNULL(@Archivos, '') <> ''
    BEGIN
        EXEC spCFDEnviarCorreoPago @Empresa, @Para, @Asunto, @Mensaje, @Archivos;


	INSERT INTO LogEnvioMail (Modulo,
								ModuloID,
								Mov,
								MovID,
								FechaEnvio,
								Remitente,
								Destinatario,
								Asunto,
								NombreArchivos,
								Usuario)
					  SELECT	@Modulo,
								@ID ,
								@Mov,
								@MovID,
								GETDATE(),
								@Para,		
								@Para,		
								@Asunto,
								@Archivos,	
								'ENVIOAUTO'

    END

END
GO
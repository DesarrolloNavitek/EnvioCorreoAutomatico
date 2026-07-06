SET DATEFIRST 7
SET ANSI_NULLS OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET LOCK_TIMEOUT -1
SET QUOTED_IDENTIFIER OFF
GO
IF EXISTS (SELECT * FROM SYSOBJECTS WHERE name = 'spXMLPagosParciales' AND type = 'P')
DROP PROC [dbo].[spXMLPagosParciales]
GO
CREATE PROCEDURE spXMLPagosParciales    
 @Estacion   INT,    
 @Empresa   VARCHAR(5)    
AS    
BEGIN    
 SET CONCAT_NULL_YIELDS_NULL ON    
 DECLARE    
  @XMLConceptos   VARCHAR(MAX),    
  @XMLPagos    VARCHAR(MAX),    
  @XMLPago    VARCHAR(MAX),    
  @XMLComplemento   VARCHAR(MAX),    
  @XMLComprobante   VARCHAR(MAX),    
  @XMLImpuestosDoc  VARCHAR(MAX),    
  @CFDIRelacionados  VARCHAR(MAX),    
  @XMLEmisor    VARCHAR(MAX),    
  @XMLReceptor   VARCHAR(MAX),    
  @DocRelacionado   VARCHAR(MAX),    
    @DocRelacionado2   xml,    
    @XMLImpuestosDR     varchar(MAX),    
    @XMLImpuestosDR2    xml,    
    @XMLTrasladoDR      varchar(MAX),    
    @XMLRetencionDR     varchar(MAX),    
    @XMLImpuestosP      varchar(MAX),    
    @XMLImpuestosP2     xml,    
    @XMLTrasladoP       varchar(MAX),    
    @CompensacionIEPS   float,    
    @XMLRetencionP      varchar(MAX),    
  @Conceptos    VARCHAR(MAX),    
  @XMLImpuestosFacturas VARCHAR(MAX),    
  @VersionPago   VARCHAR(5),    
  @VersionCFDI   VARCHAR(5),    
  @ID      INT,    
  @AlmacenarRuta   VARCHAR(255),    
  @AlmacenarRutaNueva  VARCHAR(255),    
  @RutaAnsiUTF   VARCHAR(255),    
  @SQL     VARCHAR(1000),    
  @Cliente    VARCHAR(13),    
  @Ejercicio    VARCHAR(4),    
  @Periodo    VARCHAR(2),    
  @IDVenta    INT,    
    @IDVenta2    INT,    
  @EsSaldoinicial   BIT,    
  @noCertificado   VARCHAR(20),    
  @SaldoAnterior   MONEY,    
  @SaldoInsoluto   MONEY,    
  @MontoTotal    MONEY,    
  @MontoTotalPesos  MONEY,    
  @MontoPagado   MONEY,    
  @PagadoTotal   DECIMAL(20,10),    
  @SaldoPendiente   MONEY,    
  @IdCxc     INT,    
  @NumParcialidad   INT,    
  @MonedaP    VARCHAR(4),    
  @MonedaDocto   VARCHAR(4),    
  @RFCEmisor    VARCHAR(20),    
  @NombreEmisor   VARCHAR(100),    
  @NombreReceptor   VARCHAR(255),    
  @RegimenFiscal   VARCHAR(30),    
  @RFCReceptor   VARCHAR(20),    
  @ResidenciaFiscal  VARCHAR(5),    
  @NumRegIdTrib   VARCHAR(40),    
  @UsoCFDI    VARCHAR(5),    
  @MetodoDePagoDR   VARCHAR(5),    
  @TipoDeComprobante  VARCHAR(10),    
  @FormaDePago   VARCHAR(5),    
  @Moneda     VARCHAR(4),    
  @MetodoDePago   VARCHAR(5),    
  @Movimiento    VARCHAR(20),    
  @NomArchivo    VARCHAR(100),    
  @NomArchivoNuevo  VARCHAR(100),    
  @Serie     VARCHAR(10),    
  @Folio     VARCHAR(50),    
  @Sucursal    INT,    
  @Modulo     VARCHAR(5),    
  @ModuloRelacionado  VARCHAR(5),    
  @Ok      INT,     
  @OkRef     VARCHAR(MAX),    
  @SchemaLocation   VARCHAR(1000),    
  @TipoCFD    VARCHAR(10),    
  @DecimalesP    INT,    
  @DecimalesDR   INT,    
  @Cont     INT,    
  @TipoCambioP   FLOAT,    
  @Relacionado   INT,    
  @FormaPagoCobro   VARCHAR(5),    
  @Bancarizado   BIT,    
  @MovClave    VARCHAR(20),    
  @MovClaveEsNeteo  VARCHAR(20),    
  @Redondeo    BIT,    
  @UUIDDR     VARCHAR(50),    
  @SerieDR    VARCHAR(10),    
  @FolioDR    VARCHAR(50),    
  @TipoCambioDR   FLOAT,    
  @CFDITimbrado   VARCHAR(MAX),    
  @CadenaOriginal   VARCHAR(MAX),    
  @FechaTimbrado   VARCHAR(MAX),    
  @UUID     VARCHAR(50),    
  @SelloSAT    VARCHAR(MAX),    
  @SelloCFD    VARCHAR(MAX),    
  @TFDVersion    VARCHAR(MAX),    
  @noCertificadoSAT  VARCHAR(MAX),    
  @TFDCadenaOriginal  VARCHAR(MAX),    
  @IdCPC     INT ,    
  @Shell     VARCHAR(8000),    
  @r      VARCHAR(MAX),    
  @RutaFirmaSAT   varchar(255),    
  @IDCP     INT ,    
  @AlmacenarCFD   BIT,    
  @FcID     INT,    
  @FIDVenta    INT,    
  @FAplica    VARCHAR(30),    
  @FAplicaID    VARCHAR(30),    
  @FAplica_c    VARCHAR(30),    
  @FAplicaID_c    VARCHAR(30),    
  @FAplicaID_A   VARCHAR(30),    
  @MovFactoraje   VARCHAR(30),    
  @MovIDFactoraje   VARCHAR(30),    
  @FModulo    VARCHAR(5),    
  @FModuloID    INT,    
  @FMov     VARCHAR(50),    
  @FMovID     VARCHAR(50),    
  @FModuloFactoraje  VARCHAR(5),    
  @FVentaID    INT ,    
  @FIDCobro    INT,    
  @FClave_c    VARCHAR(50),    
  @FcID_Anterior   INT,    
  @FormaDePagoDR   VARCHAR(10),    
  @MontoTP    MONEY,    
  @CuentaBeneficiaria  VARCHAR(50),    
  @MontoPagadoPrevio      FLOAT,    
  @MontoPagadoPrevioPesos   FLOAT,    
  @SaldoAnteriorPesos    FLOAT,    
  @MontoPagadoPesos    FLOAT,    
  @SaldoPendientePesos   FLOAT,    
  @TipoCambioDRSAT    FLOAT,    
  @IDAplicaCobro     INT,    
  @ClaveAplicaCobro    VARCHAR(10),    
  @AplicaFactor     FLOAT,    
  @MontoFactor     FLOAT,    
    @MontoFactor2     FLOAT,    
  @FechaEmisionCFDI    DATETIME,    
  @newID       UNIQUEIDENTIFIER,    
  @RutaFS       VARCHAR (500),    
  @EnviarAnexos     BIT,    
  @EnviarXML      BIT,    
  @EnviarPDF      BIT,    
  @MontoPagadoPrevioPesosDoctos   FLOAT,    
  @MontoPagadoPrevioDoctos        FLOAT,    
  @NumParcialidadDoctos           INT,    
  @IdCxcAntes      INT,    
  @MontoTotalPago     FLOAT,    
  @IdCxcParcialidad    INT,    
  @ClaveDetalle     VARCHAR(20),    
  @FDMov       VARCHAR(20),          
  @FDMovID      VARCHAR(20),    
  @MovFactorajeD     VARCHAR(20),    
  @MovFactorajeIDD    VARCHAR(20),    
  @IdCxcDIN      INT,    
  @Factoraje      BIT,    
  @IDMov       INT,    
  @NumeroPago      VARCHAR(10),    
  @FactorajeE      BIT,    
    @FactorajeE2     BIT,    
  @FolioDRCXC      VARCHAR(20),    
  @MovDRCXC                       VARCHAR(20),    
  @FechaEmision     DATETIME,    
  @FechaOriginal     DATETIME,    
  @ClaveOFactoraje    VARCHAR(20),      
  @SaldoInicialFactoraje   BIT,    
  @MontoMovREP     BIT,    
  @MontoMov      FLOAT,    
  @Verano       FLOAT,    
    @Invierno      FLOAT,    
    @Exportacion        varchar(2),    
    @DomicilioFiscalReceptor    varchar(6),    
    @RegimenFiscalReceptor      varchar(3),    
    @AgenteACuentaTerceros      varchar(10),    
    @RfcACuentaTerceros         varchar(15),    
    @NombreACuentaTerceros      varchar(255),    
    @RegimenFiscalACuentaTerceros varchar(30),    
    @DomicilioFiscalACuentaTerceros varchar(6),    
    @TotalRetencionesIVA          float,    
    @TotalRetencionesISR          float,    
    @TotalRetencionesIEPS         float,    
    @TotalTrasladosBaseIVA16      float,    
    @TotalTrasladosImpuestoIVA16  float,    
    @TotalTrasladosBaseIVA8       float,    
    @TotalTrasladosImpuestoIVA8   float,    
    @TotalTrasladosBaseIVA0       float,    
    @TotalTrasladosImpuestoIVA0   float,    
    @TotalTrasladosBaseIVAExento  float,    
    @TotalCompensacionIEPS        float,    
    @MontoTotalPagos              float,    
    @TipoFactorDR                 varchar(5),    
    @TasaOCuotaDR                 float,    
    @ImpuestoDR                   varchar(3),    
    @ImporteDR                    float,    
    @BaseDR                       float,    
    @ObjetoImpDR                  varchar(2),    
    @LlevaTotales                 bit,    
    @ModuloTR                     varchar(5),    
    @IDTR                         int,    
    @EquivalenciaDR               float,    
    @DecimalesTrasladoP        INT,    
    @SumaMonto                    float,    
    @Consecutivo                  int,    
 @AjustarMontoTotalPagos   FLOAT,    
 @TieneAjusteNegativo   BIT = 0    
  DECLARE @Datos TABLE (ID int IDENTITY(1,1), Datos varchar(255))    
  DECLARE @DocRelacionadoTimbrado TABLE(    
   Modulo     VARCHAR(5),    
   ModuloID    INT,    
   UUID     VARCHAR(36),    
   Serie     VARCHAR(20),    
   Folio     INT,    
   ImpPagado    FLOAT,--DECIMAL(18,2),    
   ImpSaldoAnt    FLOAT,--DECIMAL(18,2),    
   ImpSaldoInsoluto  FLOAT,--DECIMAL(18,2),    
   Moneda     VARCHAR(5),    
   TipoCambio    FLOAT,    
   NumParcialidad   INT,    
   MetodoPago    VARCHAR(5),    
   IDCobro     INT,    
   ObjetoImpDR    VARCHAR(3),    
   EquivalenciaDR   FLOAT,    
   IDD      INT,    
   TieneAjusteNegativo  BIT)    
  DECLARE @PagosFactura TABLE(    
   ID    INT,    
   MontoPagado  FLOAT,    
   Clave   VARCHAR(10),    
   SubClave  VARCHAR(20),    
   ClaveD   VARCHAR(20),    
   CFD    BIT,    
   Parcialidad  BIT     
  )    
  DECLARE @PagosAplica TABLE(    
   Aplica   VARCHAR(20),    
   AplicaID  VARCHAR(20),    
   Parcialidad  BIT     
  )     
  DECLARE @LimpiarClientes TABLE(    
Cliente   VARCHAR(10)    
  )    
  DECLARE @FacturasRelacionadas TABLE(    
   UUID   VARCHAR(50),    
      Factoraje     bit    
  )    
  DECLARE @DatosFactoraje TABLE(    
  Modulo    VARCHAR (5) ,    
  ModuloID   INT,    
  Mov     VARCHAR(50),    
  MovID    VARCHAR(50),    
  ModuloFactoraje  VARCHAR(5),    
  ModuloFactorajeID INT,    
  MovFactoraje  VARCHAR(50),    
  MovFactorajeID  VARCHAR(30),    
  Empresa    VARCHAR(50),    
  Cliente    VARCHAR(50),    
  MovFactorajeD  VARCHAR(20),    
  MovFactorajeIDD VARCHAR(20)      
  )    
  DECLARE @PagosFacturaenDoctos TABLE(    
   ID    INT,    
   Mov             varchar(20),    
   movID           varchar(20),    
   MontoPagado  FLOAT,    
   Clave   VARCHAR(10),    
   Aplica   VARCHAR(20),    
   AplicaID  VARCHAR(20),    
   Sucursal        int,    
   Empresa         varchar(10),    
   Parcialidad  bit,    
   Moneda          varchar(20),    
   Importe         float,    
   TipoCambio      float,    
   ImporteTotal    float      
  )    
  DECLARE @Movimientos TABLE (    
  OID   INT,    
  OModulo  VARCHAR(5),    
  OMov  VARCHAR(20),    
  OMovID  VARCHAR(20),    
  DID   INT,    
  DModulo  VARCHAR(5),    
  DMov  VARCHAR(20),    
  DMovID  VARCHAR(20),    
  Nivel  INT,    
  Clave  VARCHAR(10)    
  )    
  DECLARE @PagosFacturaCobro TABLE(    
   IDVenta    INT ,    
   IDCobro    INT ,    
   UUID    VARCHAR(50),    
   MontoPagado   FLOAT,    
   Parcialidad   INT,    
   Factoraje   BIT     
  )    
    DECLARE @TrasladoDR TABLE(    
    UUID            varchar(36),    
    TipoFactorDR    varchar(6),    
    TasaOCuotaDR    float,    
    ImpuestoDR      varchar(3),    
    ImporteDR       float,    
    BaseDR          float,    
    NumParcialidad  int)    
    DECLARE @RetencionDR TABLE(    
    UUID            varchar(36),    
    TipoFactorDR    varchar(5),    
    TasaOCuotaDR    float,    
    ImpuestoDR      varchar(3),    
    ImporteDR       float,    
    BaseDR          float,    
    NumParcialidad  int)    
    DECLARE @TrasladoP TABLE(    
    Modulo          varchar(5),    
    ModuloID        int,    
    UUID            varchar(36),    
    TipoFactorP     varchar(6),    
    TasaOCuotaP     float,    
    ImpuestoP       varchar(3),    
    ImporteP        float,    
    BaseP           float,    
    NumParcialidad  int,    
    ImportePMN      float,    
    BasePMN         float,    
    ObjetoImpDR     varchar(2))    
    DECLARE @TrasladoTotal TABLE(    
    Modulo          varchar(5),    
    ModuloID        int,    
    UUID            varchar(36),    
    TipoFactorP     varchar(6),    
    TasaOCuotaP     float,    
    ImpuestoP       varchar(3),    
    ImporteP        float,    
    BaseP           float,    
    NumParcialidad  int,    
    ImportePMN      float,    
    BasePMN         float,    
    IDCobro         int,    
    ObjetoImpDR     varchar(2))    
    DECLARE @RetencionP TABLE(    
    Modulo          varchar(5),    
    ModuloID        int,    
    UUID            varchar(36),    
    TipoFactorP     varchar(5),    
    TasaOCuotaP     float,    
    ImpuestoP       varchar(3),    
    ImporteP        float,    
    BaseP           float,    
    NumParcialidad  int,    
    ImportePMN      float,    
    BasePMN         float)    
    DECLARE @RetencionTotal TABLE(    
    Modulo          varchar(5),    
    ModuloID        int,    
    UUID            varchar(36),    
    TipoFactorP     varchar(5),    
    TasaOCuotaP     float,    
    ImpuestoP       varchar(3),    
    ImporteP        money,    
    BaseP           money,    
    NumParcialidad  int,    
    ImportePMN      money,    
    BasePMN         money,    
    IDCobro         int)    
    CREATE TABLE #TempImpuestoDR(    
    Modulo varchar(5),    
    ModuloID int,    
    IDCobro   int,    
    IDVenta   int,    
    Impuesto1 float   NULL,    
    Impuesto2 float   NULL,    
    Impuesto3 float   NULL,    
    Impuesto5 float   NULL,    
    Importe1 float   NULL,    
    Importe2 float   NULL,    
    Importe3 float   NULL,    
    Importe5 float   NULL,    
    SubTotal float   NULL,    
    Retencion1 float   NULL,    
    Retencion2 float   NULL,    
    Retencion3 float   NULL,    
    Excento1 bit   NULL)    
 IF (SELECT CFD FROM Empresa WHERE Empresa = @Empresa) = 1    
  SET @TipoCFD = 'Ant'    
 ELSE IF (SELECT CONVERT(INT, ISNULL(eDoc, 0)) + CONVERT(INT, ISNULL(CFDFlex, 0)) FROM EmpresaGral WHERE Empresa = @Empresa) = 2    
  SET @TipoCFD = 'Flex'    
 ELSE    
 BEGIN    
  SELECT 'No tiene configurado CFD'    
     RETURN    
 END    
 DELETE FROM CFDICobroParcialLog WHERE Estacion = @Estacion    
 DELETE FROM CFDICobroParcialPDF WHERE Estacion = @Estacion    
 SELECT @VersionPago = VersionPago, @VersionCFDI = VersionCFDI FROM CFDICobroParcialVersion WHERE Empresa = @Empresa    
 DELETE  @DatosFactoraje    
 SET @Cont = 0    
 SELECT @RFCEmisor = RFC,    
     @NombreEmisor = Nombre,    
     @RegimenFiscal = FiscalRegimen    
 FROM Empresa    
 WHERE Empresa = @Empresa    
 IF @VersionCFDI = '3.2'    
 BEGIN    
  SET @TipoDeComprobante = 'Ingreso'    
  SET @FormaDePago = 'NA'    
  SET @Moneda = NULL    
  SET @metodoDePago = 'Pago'    
  SET @XMLImpuestosFacturas = '<cfdi:Impuestos xmlns:cfdi="http://www.sat.gob.mx/cfd/4"></cfdi:Impuestos>'    
  SET @SchemaLocation = 'xsi:schemaLocation="http://www.sat.gob.mx/cfd/4 http://www.sat.gob.mx/sitio_internet/cfd/3/cfdv32.xsd http://www.sat.gob.mx/Pagos http://www.sat.gob.mx/sitio_internet/cfd/Pagos/Pagos10.xsd"'    
 END     
 ELSE IF @VersionCFDI = '3.3'    
 BEGIN    
  SET @TipoDeComprobante = 'P'    
  SET @FormaDePago = NULL    
  SET @Moneda = 'XXX'    
  SET @MetodoDePago = NULL    
  SET @XMLImpuestosFacturas = NULL    
  SET @SchemaLocation = 'xsi:schemaLocation="http://www.sat.gob.mx/cfd/3 http://www.sat.gob.mx/sitio_internet/cfd/3/cfdv33.xsd http://www.sat.gob.mx/Pagos http://www.sat.gob.mx/sitio_internet/cfd/Pagos/Pagos10.xsd"'    
 END    
  ELSE IF @VersionCFDI = '4.0'    
 BEGIN    
  SET @TipoDeComprobante = 'P'    
    SET @Exportacion = '01'    
  SET @FormaDePago = NULL    
  SET @Moneda = 'XXX'    
  SET @MetodoDePago = NULL    
  SET @XMLImpuestosFacturas = NULL    
  SET @SchemaLocation = 'xsi:schemaLocation="http://www.sat.gob.mx/cfd/4 http://www.sat.gob.mx/sitio_internet/cfd/4/cfdv40.xsd http://www.sat.gob.mx/Pagos20 http://www.sat.gob.mx/sitio_internet/cfd/Pagos/Pagos20.xsd"'    
 END    
 DECLARE CPagos CURSOR FOR    
  SELECT DISTINCT ID FROM ListaID AS l    
   INNER JOIN CFDICobroVenta AS cv ON cv.IDMovimiento = l.ID    
  WHERE l.Estacion = @Estacion AND cv.Empresa = @Empresa    
 OPEN CPagos    
 FETCH NEXT FROM CPagos INTO @ID    
 WHILE @@FETCH_STATUS = 0    
 BEGIN     
        SELECT @LlevaTotales = 1    
  SELECT @MontoTotalPagos = 0    
  DELETE FROM @TrasladoTotal    
  DELETE FROM @RetencionTotal    
  SET @MontoTotalPago =NULL      
  SELECT  @Cliente   = A.Cliente,    
    @Movimiento = A.Mov,    
    @Sucursal = A.Sucursal,    
    @Ejercicio = CAST(DATEPART(YEAR, ISNULL(A.FechaOriginal, A.FechaEmision))  AS VARCHAR(4)),    
    @Periodo   = CAST(DATEPART(MONTH, ISNULL(A.FechaOriginal, A.FechaEmision)) AS VARCHAR(2)),    
    @RFCReceptor = B.RFC,    
    @NombreReceptor = B.Nombre,    
        @DomicilioFiscalReceptor = CASE B.RFC WHEN 'XAXX010101000' THEN A.LugarExpedicion WHEN 'XEXX010101000' THEN A.LugarExpedicion ELSE B.CodigoPostal END,    
    @ResidenciaFiscal = CASE WHEN ISNULL(fr.Extranjero, 0) = 1 THEN P.ClavePais ELSE NULL END,    
    @NumRegIdTrib = CASE WHEN ISNULL(fr.Extranjero, 0) = 1 THEN C.NumRegIdTrib ELSE NULL END,    
        @RegimenFiscalReceptor = NULLIF(RTRIM(fr.FiscalRegimen), ''),    
    @Folio = A.Folio,    
    @Serie = ISNULL(A.Serie, ''),    
    @Modulo = A.Modulo,    
    @DecimalesP = ISNULL(s.Decimales, 2),    
    @MonedaP = A.ClaveMoneda,    
    @TipoCambioP = ROUND(A.TipoCambio,6),    
        @AgenteACuentaTerceros = ISNULL(a.AgenteACuentaTerceros, ''),    
        @RfcACuentaTerceros = ISNULL(g.RFC, ''),    
        @NombreACuentaTerceros = ISNULL(g.Nombre, ''),    
        @RegimenFiscalACuentaTerceros = ISNULL(g.FiscalRegimen, ''),    
        @DomicilioFiscalACuentaTerceros = ISNULL(g.CodigoPostal, ''),    
  @AjustarMontoTotalPagos = A.AjustarMontoTotalPagos    
  FROM CFDICobroParcial A    
   INNER JOIN Cte B ON A.Cliente = B.Cliente    
   LEFT JOIN CteCFD C ON C.Cliente = B.Cliente    
   LEFT JOIN SATPais P ON B.Pais = P.Descripcion    
   LEFT JOIN FiscalRegimen AS fr ON fr.FiscalRegimen = B.FiscalRegimen    
   LEFT JOIN SATMoneda AS s ON s.Clave = A.ClaveMoneda    
      LEFT OUTER JOIN Agente g ON A.AgenteACuentaTerceros = g.Agente    
  WHERE A.ID = @ID AND A.Estacion = @Estacion    
  SELECT @Verano = s.DifHorariaVerano , @Invierno = s.DifHorariaInvierno    
   FROM Sucursal AS s    
  WHERE s.Sucursal = @Sucursal    
  SET @Conceptos = ''    
  SET @XMLImpuestosDoc = ''    
  SET @XMLPago = ''    
  SET @Ok = NULL    
  SET @OkRef = NULL    
  SET @Relacionado = 0    
  SET @TieneAjusteNegativo = 0    
  DELETE FROM @DocRelacionadoTimbrado    
  EXEC spAntesTimbrarCobro @ID,@Modulo,@Empresa,@Estacion,@Ok OUTPUT,@OkRef OUTPUT    
  IF EXISTS (SELECT * FROM CFDICobroFactorajePaso AS cfp WHERE cfp.ModuloID=@ID AND cfp.Modulo=@Modulo AND cfp.Estacion=@Estacion AND cfp.Empresa=@Empresa)    
  BEGIN    
   DECLARE InsertFactoraje CURSOR LOCAL FOR    
    SELECT cfp.ModuloFactorajeID,cfp.Modulo,cfp.ModuloID,cd.Aplica,cd.AplicaID,cfp.ModuloFactoraje,C.Mov,C.MovID,cfp.Mov,cfp.MovID    
      FROM CFDICobroFactorajePaso AS cfp    
      JOIN CxcD AS cd ON cd.ID=cfp.ModuloFactorajeID    
      JOIN  Cxc AS c ON C.ID=CD.ID    
    WHERE cfp.ModuloID=@ID    
     AND NULLIF (cd.Aplicaid,'') IS NOT  NULL    
     AND NULLIF (cd.Aplica,'') IS NOT  NULL    
     AND cfp.Estacion=@Estacion    
     AND cfp.Empresa=@Empresa    
   OPEN InsertFactoraje    
   FETCH NEXT FROM InsertFactoraje INTO  @FcID,@FModulo,@FModuloID,@FMov,@FMovID,@FModuloFactoraje,@FAplica,@FAplicaID,@FDMov,@FDMovID    
   WHILE @@FETCH_STATUS = 0    
   BEGIN    
    DELETE FROM @Movimientos    
    ;WITH Movimientos    
    AS (    
     SELECT OID, OModulo, OMov, OMovID, DID, DModulo, DMov, DMovID,  1 AS Nivel    
     FROM dbo.movflujo    
     WHERE DID = @FcID AND DModulo = 'CXC' AND OMov = @FMov AND OMovID = @FMovID AND Empresa = @Empresa AND Cancelado = 0    
     UNION ALL    
     SELECT e.OID, e.OModulo, e.OMov, e.OMovID, e.DID, e.DModulo, e.DMov, e.DMovID, 1 + Movimientos.Nivel    
     FROM dbo.movflujo AS e    
      INNER JOIN Movimientos ON e.DID = Movimientos.OID AND e.DModulo = Movimientos.OModulo AND e.Cancelado = 0    
    )    
    INSERT @Movimientos    
    SELECT OID, OModulo, OMov, OMovID, DID, DModulo, DMov, DMovID, Nivel, mt.Clave    
    FROM Movimientos AS m    
     INNER JOIN MovTipo AS mt ON m.OModulo = mt.Modulo AND m.OMov = mt.Mov    
    ORDER BY Nivel DESC    
    SELECT TOP 1 @FVentaID = OID, @MovFactorajeD = OMov, @MovFactorajeIDD = OMovID, @ClaveOFactoraje = Clave    
     FROM   @Movimientos    
    WHERE Clave IN ('VTAS.F','CXC.F')    
    ORDER BY NIVEL DESC    
    IF @ClaveOFactoraje = 'CXC.F'    
     SET @SaldoInicialFactoraje = 1    
    ELSE    
     SET @SaldoInicialFactoraje = 0    
    SELECT @AplicaFactor=1,@MontoFactor = cd.Importe    
     FROM Cxc AS c    
    JOIN CxcD as cd on c.ID=cd.ID    
    WHERE c.ID=@FcID    
     and cd.Aplica=@FMov    
     and cd.AplicaID=@FMovID    
    INSERT  CFDICobroVenta (Estacion, Empresa, IDMovimiento,IDCobro,IDVenta,AplicaFactor,MontoFactor,Factoraje, EsSaldoInicial)    
    SELECT     @Estacion,@Empresa,@ID,   @FcID, @FVentaID,@AplicaFactor,@MontoFactor,1, @SaldoInicialFactoraje    
    INSERT @DatosFactoraje(Modulo, ModuloID,   Mov,   MovID,   ModuloFactoraje,   ModuloFactorajeID, MovFactoraje,MovFactorajeID,Empresa, Cliente,MovFactorajeD, MovFactorajeIDD)    
    SELECT       @FModulo,@FModuloID,@FDMov,@FDMovID, @FModuloFactoraje, @FcID    ,@FAplica   ,@FAplicaID  ,@Empresa, @Cliente,@MovFactorajeD,@MovFactorajeIDD    
    FETCH NEXT FROM InsertFactoraje INTO  @FcID,@FModulo,@FModuloID,@FMov,@FMovID,@FModuloFactoraje,@FAplica,@FAplicaID,@FDMov,@FDMovID    
 END    
   CLOSE InsertFactoraje    
   DEALLOCATE InsertFactoraje    
  END     
  DECLARE cCxc CURSOR FOR    
   SELECT DISTINCT CASE WHEN @Modulo ='DIN' AND IDAplicaCobro IS NOT NULL  THEN IDAplicaCobro ELSE IDCobro  END ,IDCobro, IDMovimiento    
   FROM CFDICobroVenta    
   WHERE IDMovimiento = @ID AND Estacion = @Estacion AND Empresa = @Empresa    
  OPEN cCxc    
  FETCH NEXT FROM cCxc INTO @IdCxc, @IdCxcDIN, @IDMov    
  WHILE @@FETCH_STATUS = 0    
  BEGIN    
      DELETE FROM @TrasladoP    
      DELETE FROM @RetencionP    
   IF @Modulo='DIN' AND EXISTS (SELECT DISTINCT  IDCobro FROM CFDICobroVenta WHERE IDAplicaCobro = @IDcxc AND Estacion = @Estacion AND Empresa = @Empresa)    
   BEGIN    
    SELECT @IdCxcAntes= IDCobro    
     FROM CFDICobroVenta    
    WHERE IDAplicaCobro = @IDcxc AND Estacion = @Estacion AND Empresa = @Empresa    
   END    
    SELECT @AlmacenarCFD= cc.Almacenar    
   FROM CteCFD AS cc    
    WHERE cc.Cliente=@Cliente     
    IF @AlmacenarCFD = 1    
     BEGIN    
      SELECT  @AlmacenarRuta= cc.AlmacenarRuta,    
      @NomArchivo=cc.Nombre    
        FROM CteCFD AS cc    
       WHERE cc.Cliente=@Cliente    
     END    
    ELSE    
   BEGIN    
     SELECT @AlmacenarRuta = AlmacenarRuta,    
           @NomArchivo = Nombre    
       FROM EmpresaCFD    
      WHERE Empresa = @Empresa     
   END     
    SELECT @RutaAnsiUTF = RutaANSIToUTF,    
         @noCertificado = noCertificado,    
         @MontoMovREP = MontoMovREP    
      FROM EmpresaCFD    
      WHERE Empresa = @Empresa    
   SET @DocRelacionado = ''    
   SET @FormaPagoCobro = NULL    
   SET @Bancarizado = NULL    
   SET @Redondeo = 0    
   SET @MovClave = NULL    
   SET @PagadoTotal = 0    
   SET @FactorajeE = 0    
   DELETE FROM @FacturasRelacionadas    
   SELECT @MovClaveEsNeteo= mt.Clave    
   FROM Cxc AS c    
    INNER JOIN MovTipo AS mt ON mt.Mov = c.Mov AND mt.Modulo = 'CXC'    
   WHERE id = @IdCxc    
   IF EXISTS(SELECT * FROM VersionLista WHERE Nombre = 'FlujoEspecialDocumentos' AND Valor = 'Si')    
    SELECT TOP 1 @MovClave=Clave    
    FROM MovTipo AS mt    
    JOIN MovFlujo AS mf on mt.Mov=mf.OMov    
    WHERE mf.OID=@IdCxc    
    AND mt.Modulo='CXC'    
    AND mf.DModulo='CXC'    
    AND mf.Cancelado=0    
    AND mf.OModulo='CXC'    
   ELSE    
    SELECT TOP 1 @MovClave=Clave    
    FROM MovTipo AS mt    
    JOIN MovFlujo AS mf on mt.Mov=mf.OMov    
    WHERE mf.OID=@IdCxc    
    AND mt.Modulo='CXC'    
    AND mf.DModulo='CXC'    
    AND mf.Cancelado=0    
   IF @MovClave NOT IN ('CXC.DP')    
    SELECT TOP 1 @MovClave=Clave    
    FROM MovTipo AS mt    
     JOIN MovFlujo AS mf on mt.Mov=mf.OMov    
    WHERE mf.DID=@IdCxc    
     AND mt.Modulo='CXC'    
     AND mf.DModulo='CXC'    
     AND mf.Cancelado=0    
  IF EXISTS (SELECT * FROM CFDICobroFactorajePaso AS cfp WHERE cfp.ModuloFactorajeID=@IdCxc AND cfp.Estacion=@Estacion AND cfp.Empresa=@Empresa)    
   SELECT @FormaPagoCobro = '17', @Bancarizado = 0    
   IF @MovClaveEsNeteo = 'CXC.NET'    
   SELECT @FormaPagoCobro = '17', @Bancarizado = 0    
  ELSE    
   SELECT @FormaPagoCobro = FP.ClaveSAT, @Bancarizado = SFP.Bancarizado    
     FROM CFDICobroVenta AS cv    
    JOIN FormaPago AS FP ON FP.FormaPago = cv.FormaPago     
    LEFT JOIN SATFormaPago AS SFP ON SFP.Clave = FP.ClaveSAT    
    WHERE cv.IDCobro = @IdCxc    
  DECLARE CDoctoRelacionado CURSOR FOR    
   SELECT IDVenta,  EsSaldoInicial,Factoraje, MontoFactor    
    FROM CFDICobroVenta    
   WHERE IDMovimiento = @ID AND    
    CASE WHEN @Modulo='DIN' AND IDAplicaCobro IS NOT NULL THEN  IDAplicaCobro ELSE IDCobro END = @IdCxc    
    AND Estacion = @Estacion AND Empresa = @Empresa    
      ORDER BY Factoraje    
  OPEN CDoctoRelacionado    
  FETCH NEXT FROM CDoctoRelacionado INTO @IDVenta, @EsSaldoinicial, @FactorajeE, @MontoFactor    
  WHILE @@FETCH_STATUS = 0    
  BEGIN    
   SET @MontoTotal = NULL    
   SET @MontoPagado = NULL    
   SET @SaldoAnterior = NULL    
   SET @SaldoInsoluto = NULL    
   SET @SaldoPendiente = NULL    
   SET @NumParcialidad = 0    
   SET @MetodoDePagoDR = NULL    
   SET @MonedaDocto = NULL    
   SET @UUIDDR = NULL    
   SET @SerieDR = NULL    
   SET @FolioDR  = NULL    
   SET @TipoCambioDR  = NULL    
   DELETE FROM @PagosFactura    
   DELETE FROM @PagosAplica    
   IF EXISTS (SELECT * FROM CFDICobroVenta WHERE IDMovimiento = @ID AND Factoraje=1 AND Empresa = @Empresa AND Estacion = @Estacion)    
   BEGIN    
    SELECT @MonedaP = m.Clave, @TipoCambioP = c.TipoCambio    
     FROM   CXC      AS c    
       INNER JOIN Mon  AS m ON c.Moneda = m.Moneda    
       INNER JOIN SATMoneda AS s ON m.Clave = s.Clave    
    WHERE ID = @IdCxc    
   END    
   IF  @EsSaldoinicial = 0    
   BEGIN    
    SET @ModuloRelacionado = 'VTAS'    
    SELECT @MontoTotal = (v.Importe - (v.Importe * (isnull(v.DescuentoGlobal, 0)/100)) - ISNULL(v.Retencion, 0) + ISNULL(v.Impuestos, 0)) - ISNULL(AnticiposFacturados, 0),    
          @MetodoDePagoDR = mp.IDClave, @MonedaDocto = ISNULL(E.Clave, 'MXN'), @DecimalesDR = ISNULL(s.Decimales, 2)    
    FROM Venta AS v    
     LEFT JOIN Condicion AS c ON c.Condicion = v.Condicion    
     LEFT JOIN SATMetodoPago AS mp ON mp.Clave = C.CFD_metodoDePago    
     LEFT JOIN Mon E ON v.Moneda = E.Moneda    
     LEFT JOIN SATMoneda AS s ON s.Clave = E.Clave    
    WHERE v.ID = @IDVenta    
    SELECT @UUIDDR = UUID, @SerieDR = Serie, @FolioDR = Folio    
    FROM CFD    
    WHERE Modulo = 'VTAS' AND ModuloID = @IDVenta AND Empresa = @Empresa AND UUID IS NOT NULL AND ISNULL(Cancelado, 0) = 0    
   END -- IF  @EsSaldoinicial = 0    
      ELSE    
   BEGIN    
    SET @ModuloRelacionado = 'CXC'    
    SELECT @ClaveDetalle=mt.Clave, @MontoTotal = (Cxc.Importe + ISNULL(Cxc.Impuestos, 0) - ISNULL(Cxc.Retencion, 0) - ISNULL(Cxc.Retencion2, 0) - ISNULL(Cxc.Retencion3, 0)), @MetodoDePagoDR = mp.IDClave, @MonedaDocto = ISNULL(E.Clave, 'MXN'), @DecimalesDR = ISNULL(s.Decimales, 2), @MovDRCxc = Cxc.Mov, @FolioDRCXC = Cxc.MovID    
    FROM Cxc    
     LEFT JOIN Condicion AS c ON c.Condicion = Cxc.Condicion    
     LEFT JOIN SATMetodoPago AS mp ON mp.Clave = c.CFD_metodoDePago    
     LEFT JOIN Mon E ON CXC.Moneda = E.Moneda    
     LEFT JOIN SATMoneda AS s ON s.Clave = E.Clave    
     LEFT JOIN MovTipo AS mt ON mt.Mov=cxc.Mov AND mt.Modulo='CXC'    
    WHERE Cxc.ID = @IDVenta AND Cxc.Empresa = @Empresa    
    SELECT @UUIDDR = cdr.UUID, @SerieDR = cdr.Serie, @FolioDR = cdr.Folio, @NumParcialidad = ISNULL(cdr.NumParcialidad, 0)    
    FROM CFDICxcDocRelacionado AS cdr    
    WHERE cdr.ID = @IDVenta AND cdr.Empresa = @Empresa    
    IF (@UUIDDR IS NULL AND @FolioDR IS NULL)          
      SELECT @UUIDDR = cdr.UUID, @SerieDR = cdr.Serie, @FolioDR = cdr.Folio, @NumParcialidad = 0    
      FROM CFD AS cdr    
      WHERE cdr.Modulo='CXC' AND cdr.ModuloID = @IDVenta AND cdr.Empresa = @Empresa    
    IF NULLIF(@UUIDDR,'') IS NULL    
    BEGIN    
     SELECT @Ok=55270,@OkRef= 'No Existe el UUID correspondiente al movimiento '+CONVERT(VARCHAR(20),RTRIM(@MovDRCXC))+' '+CONVERT(VARCHAR(20),RTRIM(@FolioDRCXC))    
    END    
        ELSE        
    IF  EXISTS (SELECT * FROM @FacturasRelacionadas WHERE UUID = @UUIDDR AND Factoraje = @FactorajeE)    
    BEGIN    
     SELECT @Ok=ml.Mensaje,@OkRef= 'UUID'+CHAR(10)+ml.Descripcion    
      FROM MensajeLista AS ml    
     WHERE ml.Mensaje =55270    
    END    
   END -- IF  @EsSaldoinicial = 1    
   IF NOT EXISTS (SELECT * FROM @FacturasRelacionadas WHERE UUID = @UUIDDR AND Factoraje = @FactorajeE)    
   BEGIN    
    SELECT @MontoTotal = ROUND(@MontoTotal, @DecimalesDR, 0)    
    SELECT @TipoCambioDR = ROUND(c.ClienteTipoCambio, 6, 0)    
    FROM Cxc AS c    
    WHERE ID = CASE WHEN @Modulo='CXC' THEN @IDMov ELSE @IdCxc END    
    EXEC spCFDICobroParcialMovimientosCxcMontos @Estacion,@Empresa,@ID,@IdCxc,@IDVenta,@UUIDDR,@ModuloRelacionado,@MontoTotal,@MonedaDocto,@DecimalesDR,@Modulo,@TipoCambioDR,@TipoCambioP,@MonedaP,@TipoCFD,@NumParcialidad, @EsSaldoinicial    
    SELECT @NumParcialidad = NumParcialidad, @MontoPagado = ImpPagado, @SaldoAnterior = ImpSaldoAnt, @SaldoPendiente =  ImpSaldoInsoluto , @Factoraje = Factoraje, @TieneAjusteNegativo = TieneAjusteNegativo    
     FROM MontosXMLFactura    
    WHERE IDVenta=@IDVenta    
    AND Estacion = @Estacion    
    AND Empresa = @Empresa    
     IF EXISTS (SELECT  * FROM @PagosFacturaCobro WHERE UUID=@UUIDDR )    
    BEGIN    
     IF EXISTS( SELECT  * FROM CFDICobroVenta AS cv WHERE cv.IDMovimiento = @ID AND cv.Factoraje = 0 AND cv.Estacion = @Estacion AND cv.Empresa = @Empresa AND cv.IDVenta= @IDVenta AND Doc = 1  )    
     BEGIN    
      SELECT @MontoPagado  =  ImpPagado,    
          @SaldoAnterior  = @SaldoAnterior - SUM ( pfc.MontoPagado),    
          @SaldoPendiente = ROUND (@SaldoAnterior,2)- ROUND( @MontoPagado,2)    
       FROM MontosXMLFactura AS  mxf    
       JOIN @PagosFacturaCobro AS pfc ON mxf.IDVenta=pfc.IDVenta    
        WHERE mxf.IDVenta = @IDVenta    
        AND Estacion = @Estacion    
        AND Empresa = @Empresa    
       GROUP BY mxf.ImpSaldoInsoluto, mxf.ImpPagado    
     END    
     IF    EXISTS( SELECT  * FROM CFDICobroVenta AS cv WHERE cv.IDMovimiento = @ID AND cv.Factoraje = 1 AND cv.Estacion = @Estacion AND cv.Empresa = @Empresa AND cv.IDVenta= @IDVenta )    
     BEGIN    
      SELECT @MontoPagado  = @MontoFactor,--ImpPagado,    
         @SaldoAnterior  = @SaldoAnterior - SUM ( pfc.MontoPagado),    
         @SaldoPendiente = ROUND (@SaldoAnterior,2)- ROUND( @MontoPagado,2),    
         @NumParcialidad = COUNT(mxf.NumParcialidad) + 1    
       FROM MontosXMLFactura AS  mxf    
       JOIN @PagosFacturaCobro AS pfc ON mxf.IDVenta=pfc.IDVenta    
      WHERE mxf.IDVenta = @IDVenta    
       AND Estacion = @Estacion    
       AND Empresa = @Empresa    
      GROUP BY mxf.ImpSaldoInsoluto, mxf.ImpPagado    
     END     
    END      
        IF @Modulo = 'DIN' AND @FactorajeE = 1    
          SELECT @ModuloTR = 'CXC', @IDTR = @IdCxc    
        ELSE    
          SELECT @ModuloTR = @Modulo, @IDTR = @ID    
        DELETE FROM #TempImpuestoDR    
        DECLARE crTempImpuesto CURSOR FOR    
        SELECT IDVenta, MontoFactor, Factoraje    
          FROM CFDICobroVenta    
         WHERE IDMovimiento = @ID    
           AND CASE WHEN @Modulo='DIN' AND IDAplicaCobro IS NOT NULL THEN IDAplicaCobro ELSE IDCobro END = @IdCxc    
           AND Estacion = @Estacion AND Empresa = @Empresa    
        OPEN crTempImpuesto    
        FETCH NEXT FROM crTempImpuesto INTO @IDVenta2, @MontoFactor2, @FactorajeE2    
        WHILE @@FETCH_STATUS = 0    
        BEGIN    
          SELECT @SumaMonto = 0    
          IF @Modulo = 'DIN' OR @FactorajeE2 = 1    
            SELECT @SumaMonto = @MontoFactor2    
          ELSE    
            SELECT @SumaMonto = SUM(MontoFactor)    
              FROM CFDICobroVenta    
             WHERE IDMovimiento = @ID    
             AND Estacion = @Estacion AND Empresa = @Empresa AND IDVenta = @IDVenta2    
          INSERT INTO #TempImpuestoDR(    
                 Modulo, ModuloID,  IDCobro,  IDVenta, Impuesto1, Impuesto2, Impuesto3, Impuesto5, Importe1,    
                 Importe2,                           Importe3,                           Importe5,                           SubTotal,                           Retencion1, Retencion2, Retencion3, Excento1)    
          SELECT Modulo, ModuloID, @IdCxc, @IDVenta2, Impuesto1, Impuesto2, Impuesto3, Impuesto5, Importe1*(@MontoFactor2/@SumaMonto),    
                 Importe2*(@MontoFactor2/@SumaMonto), Importe3*(@MontoFactor2/@SumaMonto), Importe5*(@MontoFactor2/@SumaMonto), SubTotal*(@MontoFactor2/@SumaMonto), Retencion1, Retencion2, Retencion3, Excento1    
            FROM MovImpuesto    
           WHERE Modulo = @ModuloTR    
             AND ModuloID = @IDTR    
             AND OrigenModulo = @ModuloRelacionado    
             AND OrigenModuloID = @IDVenta2    
  
  
  
    DELETE FROM #TempImpuestoDR    
   WHERE (Impuesto1 <> 0 OR Impuesto1 <> 2 OR Impuesto3 <> 0  )    
   AND Importe1 = 0    
   AND Importe3 = 0    
   AND Importe1 = 0    
   AND Excento1 = 0    
   AND SubTotal = 0    
          FETCH NEXT FROM crTempImpuesto INTO @IDVenta2, @MontoFactor2, @FactorajeE2    
        END    
        CLOSE crTempImpuesto    
        DEALLOCATE crTempImpuesto    
    
    
  --INSERT INTO MALALADOS  
  --  SELECT * FROM #TempImpuestoDR  
    
  --- PRUEBA   SELECT * FROM AVENGER  
  
 --- SELECT * FROM MALALADOS  
  --- SELECT   
  
  IF @MonedaP = @MonedaDocto    
   SELECT @DecimalesTrasladoP = 2    
  ELSE    
   SELECT @DecimalesTrasladoP = 2--4    
        SELECT @EquivalenciaDR = CASE WHEN @MonedaP = @MonedaDocto THEN '1' ELSE ROUND(@TipoCambioP/@TipoCambioDR, 10) END    
  DELETE FROM @TrasladoDR    
        INSERT INTO @TrasladoDR(    
                UUID,   TipoFactorDR, TasaOCuotaDR,    ImpuestoDR, ImporteDR,     BaseDR,                                                 NumParcialidad)    
        SELECT @UUIDDR, 'Tasa',       Impuesto1/100.0, '002',     Round( ROUND(SUM(SubTotal+ISNULL(Importe2, 0)+ISNULL(Importe3, 0)),@DecimalesTrasladoP)*(Impuesto1/100.0)* @EquivalenciaDR ,@DecimalesTrasladoP), ROUND ( ROUND(SUM(SubTotal+ISNULL(Importe2,0)+ISNULL(Importe3, 0)),@DecimalesTrasladoP)* @EquivalenciaDR, @DecimalesTrasladoP), @NumParcialidad    
          FROM #TempImpuestoDR    
         WHERE Modulo = @ModuloTR    
           AND ModuloID = @IDTR    
           AND IDCobro = @IdCxc    
           AND IDVenta = @IDVenta    
           AND Impuesto1 >= 0    
        AND Excento1 = 0    
         GROUP BY Impuesto1/100.0    
         UNION    
          SELECT @UUIDDR, 'Tasa', Impuesto2/100.0, '003', ROUND(ROUND(SUM(ISNULL(Importe2, 0)), 4) *@EquivalenciaDR, @DecimalesTrasladoP), ROUND(ROUND(SUM(SubTotal), 4)*@EquivalenciaDR, @DecimalesTrasladoP), @NumParcialidad    
          FROM #TempImpuestoDR    
         WHERE Modulo = @ModuloTR    
           AND ModuloID = @IDTR    
           AND IDCobro = @IdCxc    
           AND IDVenta = @IDVenta    
           AND Impuesto2 > 0    
     AND Importe2  > 0    
         GROUP BY Impuesto2/100.0    
         UNION    
        SELECT @UUIDDR, 'Cuota', Impuesto3, '003', ROUND(ROUND(ROUND(SUM(Importe3/Impuesto3), @DecimalesTrasladoP)*@EquivalenciaDR, @DecimalesTrasladoP) * Impuesto3, @DecimalesTrasladoP) , ROUND(ROUND(SUM(Importe3/Impuesto3), @DecimalesTrasladoP)*@EquivalenciaDR, @DecimalesTrasladoP), @NumParcialidad    
          FROM #TempImpuestoDR    
         WHERE Modulo = @ModuloTR    
           AND ModuloID = @IDTR    
           AND IDCobro = @IdCxc    
           AND IDVenta = @IDVenta    
           AND Impuesto3 > 0    
     AND Importe3  > 0    
         GROUP BY Impuesto3    
         UNION    
        SELECT @UUIDDR, 'Exento', NULL, '002', NULL, ROUND(ROUND(SUM(ISNULL(SubTotal, 0)), 6)*@EquivalenciaDR, @DecimalesTrasladoP), @NumParcialidad    
          FROM #TempImpuestoDR    
         WHERE Modulo = @ModuloTR    
           AND ModuloID = @IDTR    
           AND IDCobro = @IdCxc    
           AND IDVenta = @IDVenta    
           AND Impuesto1 = 0    
           AND Excento1 = 1    
        DELETE FROM @RetencionDR    
        INSERT INTO @RetencionDR(UUID, TipoFactorDR, TasaOCuotaDR, ImpuestoDR, ImporteDR, BaseDR, NumParcialidad) -- ISR    
        SELECT @UUIDDR, 'Tasa', Retencion1/100.0, '001', ROUND(ROUND(SUM(SubTotal*Retencion1/100.0), 4)*@EquivalenciaDR, @DecimalesTrasladoP), ROUND(ROUND(SUM(SubTotal), 4)*@EquivalenciaDR, @DecimalesTrasladoP), @NumParcialidad    
          FROM #TempImpuestoDR    
          WHERE Modulo = @ModuloTR    
            AND ModuloID = @IDTR    
            AND IDCobro = @IdCxc    
            AND IDVenta = @IDVenta    
            AND SubTotal*Retencion1> 0    
          GROUP BY Retencion1/100.0    
          UNION    
        SELECT @UUIDDR, 'Tasa', Retencion2/100.0, '002', ROUND(ROUND(SUM(SubTotal*Retencion2/100.0), 4)*@EquivalenciaDR, @DecimalesTrasladoP), ROUND(ROUND(SUM(SubTotal), 4)*@EquivalenciaDR, @DecimalesTrasladoP), @NumParcialidad -- IVA    
          FROM #TempImpuestoDR    
          WHERE Modulo = @ModuloTR    
           AND ModuloID = @IDTR    
            AND IDCobro = @IdCxc    
            AND IDVenta = @IDVenta    
            AND SubTotal*Retencion2 > 0    
          GROUP BY Retencion2/100.0    
  SELECT @ObjetoImpDR  = dbo.fnCobroParcialObjetoImp(@IDVenta, @EsSaldoinicial)    
  
  --INSERT INTO AVENGER  
  --SELECT * FROM @TrasladoDR  
  
        INSERT INTO @TrasladoP(Modulo, ModuloID, UUID, TipoFactorP, TasaOCuotaP, ImpuestoP, ImporteP, BaseP, NumParcialidad, ImportePMN, BasePMN, ObjetoImpDR)    
        SELECT @ModuloTR, @IDTR, @UUIDDR, TipoFactorDR, TasaOCuotaDR, ImpuestoDR, ImporteDR/@EquivalenciaDR, BaseDR/@EquivalenciaDR, @NumParcialidad,    
    
               ROUND(ImporteDR/@EquivalenciaDR,2),--*CASE WHEN @MonedaP = @MonedaDocto THEN @TipoCambioP ELSE 1 END,    
               ROUND(BaseDR/@EquivalenciaDR, 2),--*CASE WHEN @MonedaP = @MonedaDocto THEN @TipoCambioP ELSE 1 END    
               @ObjetoImpDR    
          FROM @TrasladoDR    
         WHERE (TasaOCuotaDR IS NOT NULL OR BaseDR IS NOT NULL)    
        INSERT INTO @RetencionP(Modulo, ModuloID, UUID, TipoFactorP, TasaOCuotaP, ImpuestoP, ImporteP, BaseP, NumParcialidad, ImportePMN, BasePMN)    
        SELECT @ModuloTR, @IDTR, @UUIDDR, TipoFactorDR, TasaOCuotaDR, ImpuestoDR, ImporteDR/@EquivalenciaDR, BaseDR/@EquivalenciaDR, @NumParcialidad,    
               ROUND(ImporteDR/@EquivalenciaDR,2),--*CASE WHEN @MonedaP = @MonedaDocto THEN @TipoCambioP ELSE 1 END,    
               ROUND(BaseDR/@EquivalenciaDR, 2)--*CASE WHEN @MonedaP = @MonedaDocto THEN @TipoCambioP ELSE 1 END    
          FROM @RetencionDR    
         WHERE TasaOCuotaDR IS NOT NULL    
   INSERT INTO INFINITY   
   SELECT * FROM @TrasladoP  
  -- SELECT * INTO INFINITY FROM @TrasladoP  
  
  IF @MonedaDocto = 'MXN' AND @monedaP <> 'MXN'    
  BEGIN    
          INSERT INTO @TrasladoTotal(Modulo, ModuloID, UUID, TipoFactorP, TasaOCuotaP, ImpuestoP, ImporteP, BaseP, NumParcialidad, ImportePMN, BasePMN, IDCobro, ObjetoImpDR)    
          SELECT @ModuloTR, @IDTR, @UUIDDR, TipoFactorDR, TasaOCuotaDR, ImpuestoDR, ImporteDR, BaseDR, @NumParcialidad,    
                 (ImporteDR/@EquivalenciaDR)*CASE WHEN @MonedaP = @MonedaDocto THEN @TipoCambioP ELSE 1 END,    
                 (BaseDR/@EquivalenciaDR)*CASE WHEN @MonedaP = @MonedaDocto THEN @TipoCambioP ELSE 1 END,    
                 @IdCxc, @ObjetoImpDR    
            FROM @TrasladoDR    
           WHERE (TasaOCuotaDR IS NOT NULL OR BaseDR IS NOT NULL)    
          INSERT INTO @RetencionTotal(Modulo, ModuloID, UUID, TipoFactorP, TasaOCuotaP, ImpuestoP, ImporteP, BaseP, NumParcialidad, ImportePMN, BasePMN, IDCobro)    
          SELECT @ModuloTR, @IDTR, @UUIDDR, TipoFactorDR, TasaOCuotaDR, ImpuestoDR, ImporteDR, BaseDR, @NumParcialidad,    
                 (ImporteDR/@EquivalenciaDR)*CASE WHEN @MonedaP = @MonedaDocto THEN @TipoCambioP ELSE 1 END,    
                 (BaseDR/@EquivalenciaDR)*CASE WHEN @MonedaP = @MonedaDocto THEN @TipoCambioP ELSE 1 END,    
                 @IdCxc    
            FROM @RetencionDR    
           WHERE TasaOCuotaDR IS NOT NULL    
    
  
     END ELSE    
  IF @MonedaDocto <> 'MXN' AND @monedaP <> 'MXN'    
  BEGIN    
   INSERT INTO @TrasladoTotal(Modulo, ModuloID, UUID, TipoFactorP, TasaOCuotaP, ImpuestoP, ImporteP, BaseP, NumParcialidad, ImportePMN, BasePMN, IDCobro, ObjetoImpDR)    
   SELECT @ModuloTR, @IDTR, @UUIDDR, TipoFactorDR, TasaOCuotaDR, ImpuestoDR, ROUND((ImporteDR / @EquivalenciaDR), 6) * @TipoCambioP, ROUND((BaseDR / @EquivalenciaDR), 6) * @TipoCambioP, @NumParcialidad,    
                 (ImporteDR/@EquivalenciaDR)*CASE WHEN @MonedaP = @MonedaDocto THEN @TipoCambioP ELSE 1 END,    
                 (BaseDR/@EquivalenciaDR)*CASE WHEN @MonedaP = @MonedaDocto THEN @TipoCambioP ELSE 1 END,    
                 @IdCxc, @ObjetoImpDR    
             FROM @TrasladoDR    
   WHERE (TasaOCuotaDR IS NOT NULL OR BaseDR IS NOT NULL)    
   INSERT INTO @RetencionTotal(Modulo, ModuloID, UUID, TipoFactorP, TasaOCuotaP, ImpuestoP, ImporteP, BaseP, NumParcialidad, ImportePMN, BasePMN, IDCobro)    
   SELECT @ModuloTR, @IDTR, @UUIDDR, TipoFactorDR, TasaOCuotaDR, ImpuestoDR, ImporteDR*@TipoCambioP, BaseDR*@TipoCambioP, @NumParcialidad,    
                 (ImporteDR/@EquivalenciaDR)*CASE WHEN @MonedaP = @MonedaDocto THEN @TipoCambioP ELSE 1 END,    
                 (BaseDR/@EquivalenciaDR)*CASE WHEN @MonedaP = @MonedaDocto THEN @TipoCambioP ELSE 1 END,    
                 @IdCxc    
             FROM @RetencionDR    
   WHERE TasaOCuotaDR IS NOT NULL    
     END ELSE    
  BEGIN    
          INSERT INTO @TrasladoTotal(Modulo, ModuloID, UUID, TipoFactorP, TasaOCuotaP, ImpuestoP, ImporteP, BaseP, NumParcialidad, ImportePMN, BasePMN, IDCobro, ObjetoImpDR)    
          SELECT @ModuloTR, @IDTR, @UUIDDR, TipoFactorDR, TasaOCuotaDR, ImpuestoDR, ImporteDR/@EquivalenciaDR, BaseDR/@EquivalenciaDR, @NumParcialidad,    
                 (ImporteDR/@EquivalenciaDR),--*CASE WHEN @MonedaP = @MonedaDocto THEN @TipoCambioP ELSE 1 END,    
                 (BaseDR/@EquivalenciaDR),--*CASE WHEN @MonedaP = @MonedaDocto THEN @TipoCambioP ELSE 1 END,    
                 @IdCxc, @ObjetoImpDR    
            FROM @TrasladoDR    
           WHERE (TasaOCuotaDR IS NOT NULL OR BaseDR IS NOT NULL)    
          INSERT INTO @RetencionTotal(Modulo, ModuloID, UUID, TipoFactorP, TasaOCuotaP, ImpuestoP, ImporteP, BaseP, NumParcialidad, ImportePMN, BasePMN, IDCobro)    
          SELECT @ModuloTR, @IDTR, @UUIDDR, TipoFactorDR, TasaOCuotaDR, ImpuestoDR, ImporteDR/@EquivalenciaDR, BaseDR/@EquivalenciaDR, @NumParcialidad,    
                 ImporteDR/@EquivalenciaDR,--*CASE WHEN @MonedaP = @MonedaDocto THEN @TipoCambioP ELSE 1 END,    
                 BaseDR/@EquivalenciaDR,--*CASE WHEN @MonedaP = @MonedaDocto THEN @TipoCambioP ELSE 1 END    
                 @IdCxc    
            FROM @RetencionDR    
           WHERE TasaOCuotaDR IS NOT NULL    
  END    
        SELECT @XMLTrasladoDR = '', @XMLRetencionDR = ''    
        ;WITH XMLNAMESPACES ('http://www.sat.gob.mx/Pagos20' AS pago20)    
        SELECT @XMLTrasladoDR = @XMLTrasladoDR + (    
        SELECT TipoFactorDR                                  AS [@TipoFactorDR],    
                CASE TasaOCuotaDR WHEN NULL THEN NULL ELSE LTRIM(REPLACE(REPLACE(dbo.fnXMLDecimal('', TasaOCuotaDR, 6), '=', ''),'"',''))       END   AS [@TasaOCuotaDR],    
                ImpuestoDR                                  AS [@ImpuestoDR],    
    
                CASE ImporteDR WHEN NULL THEN NULL ELSE LTRIM(REPLACE(REPLACE(dbo.fnXMLDecimal('', ImporteDR, @DecimalesTrasladoP), '=', ''),'"','')) END  AS [@ImporteDR],    
                LTRIM(REPLACE(REPLACE(dbo.fnXMLDecimal('', BaseDR, @DecimalesTrasladoP), '=', ''),'"',''))              AS [@BaseDR]    
          FROM @TrasladoDR    
          WHERE ISNULL(TasaOCuotaDR, 0) > 0 OR ISNULL(BaseDR, 0) > 0    
          FOR XML PATH ('pago20:TrasladoDR'))    
        ;WITH XMLNAMESPACES ('http://www.sat.gob.mx/Pagos20' AS pago20)    
        SELECT @XMLRetencionDR = @XMLRetencionDR + (    
        SELECT TipoFactorDR                                                                             AS [@TipoFactorDR],    
                LTRIM(REPLACE(REPLACE(dbo.fnXMLDecimal('', TasaOCuotaDR, 6), '=', ''),'"',''))         AS [@TasaOCuotaDR],    
                ImpuestoDR                                                                              AS [@ImpuestoDR],    
                LTRIM(REPLACE(REPLACE(dbo.fnXMLDecimal('', ImporteDR, @DecimalesTrasladoP), '=', ''),'"','')) AS [@ImporteDR],    
                LTRIM(REPLACE(REPLACE(dbo.fnXMLDecimal('', BaseDR, @DecimalesTrasladoP), '=', ''),'"',''))     AS [@BaseDR]    
          FROM @RetencionDR    
          FOR XML PATH ('pago20:RetencionDR'))    
        IF ISNULL(@XMLTrasladoDR, '') <> '' OR ISNULL(@XMLRetencionDR, '') <> ''    
        BEGIN    
          IF @XMLRetencionDR <> ''    
          BEGIN    
            SELECT @XMLRetencionDR = REPLACE(@XMLRetencionDR, 'xmlns:pago20="http://www.sat.gob.mx/Pagos20" ', '')    
            SELECT @XMLRetencionDR = '<pago20:RetencionesDR>' + @XMLRetencionDR + '</pago20:RetencionesDR>'    
          END    
          IF @XMLTrasladoDR <> ''    
          BEGIN    
            SELECT @XMLTrasladoDR = REPLACE(@XMLTrasladoDR, 'xmlns:pago20="http://www.sat.gob.mx/Pagos20" ', '')    
            SELECT @XMLTrasladoDR = '<pago20:TrasladosDR>' + @XMLTrasladoDR + '</pago20:TrasladosDR>'    
          END    
          SELECT @XMLImpuestosDR = '<pago20:ImpuestosDR xmlns:pago20="http://www.sat.gob.mx/Pagos20">' + ISNULL(@XMLRetencionDR, '') + ISNULL(@XMLTrasladoDR, '') + '</pago20:ImpuestosDR>'    
        END    
        SELECT @XMLImpuestosDR2 = @XMLImpuestosDR    
        IF @ObjetoImpDR <> '02'    
          SELECT @XMLImpuestosDR2 = ''    
        INSERT @PagosFacturaCobro (IDVenta, IDCobro, UUID, MontoPagado,Parcialidad, Factoraje)    
        SELECT       @IDVenta, @IdCxc, @UUIDDR,@MontoPagado,@NumParcialidad,@Factoraje        
        IF @MovClave IN ('CXC.D')     
        BEGIN    
         IF EXISTS(SELECT * FROM VersionLista WHERE Nombre = 'FlujoEspecialDocumentos' AND Valor = 'Si')    
          SELECT @IdCxc = DID FROM   MovFlujo AS mf    
           JOIN   Cxc AS c ON mf.dID=c.ID    
           WHERE  OID = @IdCxc    
            AND mf.DModulo = 'CXC'    
            AND c.Estatus<>'CANCELADO'    
            AND mf.Cancelado=0    
            AND mf.OModulo='CXC'    
         ELSE    
          SELECT @IdCxc = DID FROM   MovFlujo AS mf    
          JOIN   Cxc AS c ON mf.dID=c.ID    
          WHERE  OID = @IdCxc    
          AND mf.DModulo = 'CXC'    
          AND c.Estatus<>'CANCELADO'    
          AND mf.Cancelado=0    
        END    
        IF @MovClave IN ('CXC.DP')     
        BEGIN    
         SELECT @IdCxcAntes = DID FROM   MovFlujo AS mf    
         JOIN   Cxc AS c ON mf.dID=c.ID    
         WHERE  OID = @IdCxc    
         AND mf.DModulo = 'CXC'    
         AND c.Estatus<>'CANCELADO'    
         AND mf.Cancelado=0          
        END    
    ;WITH XMLNAMESPACES ('http://www.sat.gob.mx/Pagos20' AS pago20)    
    SELECT @DocRelacionado  = @DocRelacionado + (    
          SELECT @UUIDDR                                                  AS [@IdDocumento],    
            NULLIF (@SerieDR,'')                                              AS [@Serie],    
            NULLIF (@FolioDR,'')                                              AS [@Folio],    
            @MonedaDocto                                                AS [@MonedaDR],    
      CASE @EquivalenciaDR WHEN 1 THEN '1' ELSE LTRIM(REPLACE(REPLACE(dbo.fnXMLEquivalenciaDecimal('', @EquivalenciaDR, 10), '=', ''),'"','')) END    AS [@EquivalenciaDR],    
                
            @NumParcialidad                                                AS [@NumParcialidad],    
            LTRIM(REPLACE(REPLACE(dbo.fnXMLDecimal('', @SaldoAnterior, @DecimalesDR), '=', ''),'"',''))                             AS [@ImpSaldoAnt],    
            LTRIM(REPLACE(REPLACE(dbo.fnXMLDecimal('', @MontoPagado, @DecimalesDR), '=', ''),'"',''))                             AS [@ImpPagado],    
            LTRIM(REPLACE(REPLACE(dbo.fnXMLDecimal('', @SaldoPendiente, @DecimalesDR), '=', ''),'"',''))                            AS [@ImpSaldoInsoluto],    
                        @ObjetoImpDR                                                                          AS [@ObjetoImpDR],    
                        @XMLImpuestosDR2    
          FOR XML PATH ('pago20:DoctoRelacionado'))    
    IF @Modulo='CXC'    
    BEGIN    
     INSERT @DocRelacionadoTimbrado (Modulo, ModuloID, UUID, Serie, Folio, ImpPagado, ImpSaldoAnt, ImpSaldoInsoluto, Moneda, TipoCambio, NumParcialidad, MetodoPago, IDCobro, ObjetoImpDR, EquivalenciaDR, IDD, TieneAjusteNegativo)    
     VALUES (@ModuloTR, @IDTR, @UUIDDR, @SerieDR, @FolioDR, @MontoPagado, @SaldoAnterior, @SaldoPendiente, @MonedaDocto, @TipoCambioDR, @NumParcialidad, @MetodoDePagoDR, @ID, @ObjetoImpDR, ROUND(@EquivalenciaDR, 10), @IDCxc, @TieneAjusteNegativo)    
  END    
    ELSE    
     INSERT @DocRelacionadoTimbrado (Modulo, ModuloID, UUID, Serie, Folio, ImpPagado, ImpSaldoAnt, ImpSaldoInsoluto, Moneda, TipoCambio, NumParcialidad, MetodoPago, IDCobro, ObjetoImpDR, EquivalenciaDR, IDD, TieneAjusteNegativo)    
     VALUES (@ModuloTR, @IDTR, @UUIDDR, @SerieDR, @FolioDR, @MontoPagado, @SaldoAnterior, @SaldoPendiente, @MonedaDocto, @TipoCambioDR, @NumParcialidad, @MetodoDePagoDR, @IdCxcDIN, @ObjetoImpDR, ROUND(@EquivalenciaDR, 10), @IDCxc, @TieneAjusteNegativo)  
  
    SELECT @PagadoTotal =  @PagadoTotal, @MontoPagado = ROUND (@MontoPagado , @DecimalesP)    
    IF @MonedaDocto = @MonedaP    
     SET @PagadoTotal = ISNULL(@PagadoTotal, 0) + @MontoPagado    
    ELSE IF @MonedaP <> 'MXN' AND @MonedaDocto = 'MXN'    
    BEGIN    
     SET @PagadoTotal = ISNULL(@PagadoTotal, 0) + (ROUND(@MontoPagado / @TipoCambioP, @DecimalesP))    
     SET @Redondeo = 1     
    END    
    ELSE IF @MonedaP = 'MXN' AND @MonedaDocto <> 'MXN'    
    BEGIN    
     SET @PagadoTotal = ISNULL(@PagadoTotal, 0) + (@MontoPagado / ROUND( @TipoCambioP/@TipoCambioDR, 10))    
     SET @Redondeo = 1    
    END    
    ELSE    
    BEGIN    
     SET @PagadoTotal = @PagadoTotal + (ROUND(@MontoPagado / @EquivalenciaDR, @DecimalesP, 0))    
    END    
    INSERT @FacturasRelacionadas (UUID, Factoraje)    
    VALUES (@UUIDDR, @FactorajeE)    
   END    
  FETCH NEXT FROM CDoctoRelacionado INTO @IDVenta, @EsSaldoinicial, @FactorajeE, @MontoFactor    
  END    
  CLOSE CDoctoRelacionado    
  DEALLOCATE CDoctoRelacionado    
    SELECT @XMLTrasladoP = '', @XMLRetencionP = ''    
 SELECT @PagadoTotal =  CASE WHEN @DecimalesP = 0 THEN CONVERT(INT, @PagadoTotal) ELSE @PagadoTotal END    
    ;WITH XMLNAMESPACES ('http://www.sat.gob.mx/Pagos20' AS pago20)    
    SELECT @XMLTrasladoP = @XMLTrasladoP + (    
    SELECT TipoFactorP                              AS [@TipoFactorP],    
            CASE TasaOCuotaP WHEN NULL THEN NULL ELSE LTRIM(REPLACE(REPLACE(dbo.fnXMLDecimal('', TasaOCuotaP, 6), '=', ''),'"','')) END  AS [@TasaOCuotaP],    
            ImpuestoP                              AS [@ImpuestoP],    
       
            CASE SUM(ImporteP) WHEN NULL THEN NULL ELSE LTRIM(REPLACE(REPLACE(dbo.fnXMLDecimal('', SUM(ImporteP), 6), '=', ''),'"','')) END AS [@ImporteP],    
            LTRIM(REPLACE(REPLACE(dbo.fnXMLDecimal('', SUM(BaseP), 6), '=', ''),'"',''))             AS [@BaseP]    
      FROM @TrasladoP        WHERE ISNULL(TasaOCuotaP, 0) > 0 OR ISNULL(BaseP, 0) > 0    
     GROUP BY TipoFactorP, TasaOCuotaP, ImpuestoP    
      FOR XML PATH ('pago20:TrasladoP'))    
    ;WITH XMLNAMESPACES ('http://www.sat.gob.mx/Pagos20' AS pago20)    
    SELECT @XMLRetencionP = @XMLRetencionP + (    
    SELECT --TipoFactorP                                                                            AS [@TipoFactorP],    
            ImpuestoP                                                                             AS [@ImpuestoP],    
            LTRIM(REPLACE(REPLACE(dbo.fnXMLDecimal('', SUM(ImporteP), 6), '=', ''),'"','')) AS [@ImporteP]    
      FROM @RetencionP    
      GROUP BY ImpuestoP    
      FOR XML PATH ('pago20:RetencionP'))    
    IF ISNULL(@XMLTrasladoP, '') <> '' OR ISNULL(@XMLRetencionP, '') <> ''    
    BEGIN    
      IF @XMLRetencionP <> ''    
      BEGIN    
        SELECT @XMLRetencionP = REPLACE(@XMLRetencionP, 'xmlns:pago20="http://www.sat.gob.mx/Pagos20 " ', '')    
        SELECT @XMLRetencionP = '<pago20:RetencionesP>' + @XMLRetencionP + '</pago20:RetencionesP>'    
      END    
      IF @XMLTrasladoP <> ''    
      BEGIN    
        SELECT @XMLTrasladoP = REPLACE(@XMLTrasladoP, 'xmlns:pago20="http://www.sat.gob.mx/Pagos20 " ', '')    
        SELECT @XMLTrasladoP = '<pago20:TrasladosP>' + @XMLTrasladoP + '</pago20:TrasladosP>'    
      END    
      SELECT @XMLImpuestosP = '<pago20:ImpuestosP xmlns:pago20="http://www.sat.gob.mx/Pagos20">' + ISNULL(@XMLRetencionP, '') + ISNULL(@XMLTrasladoP, '') + '</pago20:ImpuestosP>'    
    END    
    SELECT @XMLImpuestosP2 = @XMLImpuestosP    
    IF ISNULL(@XMLImpuestosP, '') <> '' --AND (@Modulo <> 'DIN' OR @LlevaTotales = 0)    
       AND EXISTS(SELECT * FROM @TrasladoTotal WHERE ObjetoImpDR = '02')    
    BEGIN    
      SELECT @DocRelacionado = @DocRelacionado+ @XMLImpuestosP    
    END    
    SELECT @DocRelacionado2 = @DocRelacionado    
  SELECT @FormaDePagoDR= fp.ClaveSAT    
   FROM CFDICobroParcial AS cp    
    JOIN FormaPago AS fp ON fp.FormaPago=cp.FormaPago    
   JOIN SATFormaPago AS sfp ON sfp.Clave = fp.ClaveSAT    
   WHERE cp.Empresa=@Empresa    
    AND cp.Estacion= @Estacion    
    AND cp.ID=@ID    
    AND cp.Modulo=@Modulo    
    AND cp.Sucursal=@Sucursal    
  SELECT @FechaEmision=A.FechaEmision, @FechaOriginal =A.FechaOriginal    
    FROM CFDICobroParcial A    
   JOIN Empresa C ON A.Empresa = C.Empresa       
   WHERE A.ID = @ID AND A.Estacion = @Estacion    
  IF (SELECT DATEPART (hh, ISNULL(@FechaOriginal,@FechaEmision)))= 0    
  BEGIN    
   SELECT @FechaOriginal = CONVERT(VARCHAR(19), DATEADD(HH, 12, @FechaOriginal),126)    
   SELECT @FechaEmision = CONVERT(VARCHAR(19), DATEADD(HH, 12, @FechaEmision),126)    
  END    
  IF @MontoMovREP = 1 AND (SELECT cv.Doc FROM CFDICobroVenta AS cv WHERE cv.Estacion = @Estacion AND cv.Empresa = @Empresa AND IDCobro = @IdCxc AND cv.IDVenta = @IDVenta) = 1 AND @Modulo = 'CXC'    
  BEGIN    
   SELECT @MontoMov = cv.MontoFactor    
    FROM CFDICobroVenta AS cv    
   WHERE cv.Estacion = @Estacion    
    AND cv.Empresa = @Empresa    
    AND IDCobro = @IdCxc    
    AND cv.IDVenta = @IDVenta    
  END    
  ELSE IF @MontoMovREP = 1 AND (SELECT cv.Doc FROM CFDICobroVenta AS cv WHERE cv.Estacion = @Estacion AND cv.Empresa = @Empresa AND IDCobro = @IdCxc AND cv.IDVenta = @IDVenta) <> 1 AND @Modulo = 'CXC'    
  BEGIN    
   SELECT @MontoMov = SUM (cv.MontoFactor)    
    FROM CFDICobroVenta AS cv    
   WHERE cv.Estacion = @Estacion    
    AND cv.Empresa = @Empresa    
    AND IDCobro = @IdCxc    
  END    
  ELSE IF @MontoMovREP = 1 AND (SELECT cv.Doc FROM CFDICobroVenta AS cv WHERE cv.Estacion = @Estacion AND cv.Empresa = @Empresa AND IDCobro = @IdCxcDIN AND cv.IDVenta = @IDVenta) = 1 AND @Modulo = 'DIN'    
  BEGIN    
   SELECT @MontoMov = cv.MontoFactor    
    FROM CFDICobroVenta AS cv    
   WHERE cv.Estacion = @Estacion    
    AND cv.Empresa = @Empresa    
    AND IDCobro = @IdCxcDIN    
    AND cv.IDVenta = @IDVenta    
    AND cv.IDAplicaCobro = @IdCxc    
  END    
  ELSE IF @MontoMovREP = 1 AND (SELECT cv.Doc FROM CFDICobroVenta AS cv WHERE cv.Estacion = @Estacion AND cv.Empresa = @Empresa AND IDCobro = @IdCxc AND cv.IDVenta = @IDVenta) <> 1 AND @Modulo = 'DIN'    
  BEGIN    
   SELECT @MontoMov = SUM (cv.MontoFactor)    
    FROM CFDICobroVenta AS cv    
   WHERE cv.Estacion = @Estacion    
    AND cv.Empresa = @Empresa    
    AND IDCobro = @IdCxc    
  END    
 IF @MonedaDocto <> 'MXN'AND @MonedaP <> 'MXN' AND (@MonedaDocto <> @MonedaP)    
  SELECT @MontoTotalPagos = ISNULL(@MontoTotalPagos, 0) + (ROUND(@PagadoTotal,6)* ROUND(@TipoCambioP, 6)+.001)  --AJUSTE POR REDONDEOS    
    ELSE    
  SELECT @MontoTotalPagos = ISNULL(@MontoTotalPagos, 0) + (ROUND(@PagadoTotal,6)* ROUND(@TipoCambioP, 6))    
 IF NULLIF(@AjustarMontoTotalPagos,'') IS NOT NULL    
  SELECT @MontoTotalPagos = @MontoTotalPagos  + (@AjustarMontoTotalPagos)    
    IF @LlevaTotales = 1    
    BEGIN    
      IF EXISTS(SELECT * FROM @DocRelacionadoTimbrado WHERE ObjetoImpDR = '02')    
      BEGIN    
        ;WITH XMLNAMESPACES ('http://www.sat.gob.mx/Pagos20' AS pago20)    
      SELECT @XMLPago = @XMLPago + (    
                 SELECT '_TotalRetencionesIVA_'          AS [@TotalRetencionesIVA],    
                        '_TotalRetencionesISR_'          AS [@TotalRetencionesISR],    
                        '_TotalRetencionesIEPS_'         AS [@TotalRetencionesIEPS],    
                        '_TotalTrasladosBaseIVA16_'      AS [@TotalTrasladosBaseIVA16],    
                        '_TotalTrasladosImpuestoIVA16_'  AS [@TotalTrasladosImpuestoIVA16],    
                        '_TotalTrasladosBaseIVA8_'       AS [@TotalTrasladosBaseIVA8],    
                        '_TotalTrasladosImpuestoIVA8_'   AS [@TotalTrasladosImpuestoIVA8],    
                        '_TotalTrasladosBaseIVA0_'       AS [@TotalTrasladosBaseIVA0],    
                   '_TotalTrasladosImpuestoIVA0_'   AS [@TotalTrasladosImpuestoIVA0],    
                        '_TotalTrasladosBaseIVAExento_'  AS [@TotalTrasladosBaseIVAExento],    
                        '_MontoTotalPagos_'              AS [@MontoTotalPagos]    
            FOR XML PATH ('pago20:Totales'))    
      END    
      ELSE    
      BEGIN    
        ;WITH XMLNAMESPACES ('http://www.sat.gob.mx/Pagos20' AS pago20)    
        SELECT @XMLPago = @XMLPago + (    
                 SELECT '_MontoTotalPagos_'              AS [@MontoTotalPagos]    
            FOR XML PATH ('pago20:Totales'))    
      END    
    END    
    BEGIN    
    ;WITH XMLNAMESPACES ('http://www.sat.gob.mx/Pagos20' AS pago20)    
    SELECT @XMLPago = @XMLPago + (SELECT CONVERT(VARCHAR(19), ISNULL(@FechaOriginal, @FechaEmision),126)             AS [@FechaPago],    
           ISNULL(@FormaPagoCobro,FP.ClaveSAT)                      AS [@FormaDePagoP],    
           @MonedaP                             AS [@MonedaP],    
           CASE WHEN @MonedaP IN ('MXN', 'XXX') THEN '1'    
            ELSE LTRIM(REPLACE(REPLACE(dbo.fnXMLDecimal('', @TipoCambioP, 6), '=', ''),'"','')) END        AS [@TipoCambioP],    
           LTRIM(REPLACE(REPLACE(dbo.fnXMLDecimalREP('',CASE WHEN @MontoMovREP = 1 THEN @MontoMov    
            ELSE @PagadoTotal END, @DecimalesP), '=', ''),'"',''))    
                                        AS [@Monto],    
           NULLIF(A.NumOperacion, '')                        AS [@NumOperacion],    
           CASE WHEN ISNULL(@Bancarizado, SFP.Bancarizado) = 1 THEN E.RFC ELSE NULL END            AS [@RfcEmisorCtaOrd],    
           CASE WHEN ISNULL(@Bancarizado, SFP.Bancarizado)  = 1 AND E.EsExtranjero = 1 THEN E.Nombre ELSE NULL END     AS [@NomBancoOrdExt],    
           CASE WHEN ISNULL(@Bancarizado, SFP.Bancarizado)  = 1 THEN    
            (CASE WHEN @FormaDePagoDR IN ('02','03') THEN A.ClabeCuenta    
             WHEN  @FormaDePagoDR IN ('05','06') THEN A.CuentaBancariaCte    
             WHEN  @FormaDePagoDR IN ('04','28','29') THEN A.Tarjeta ELSE A.CuentaBancariaCte    
            END)    
           ELSE NULL END                            AS [@CtaOrdenante],    
           CASE WHEN ISNULL(@Bancarizado, SFP.Bancarizado)  = 1 THEN D.RFC ELSE NULL END            AS [@RfcEmisorCtaBen],    
           CASE WHEN ISNULL(@Bancarizado, SFP.Bancarizado)  = 1 THEN    
            (CASE WHEN @FormaDePagoDR IN ('02','03') THEN cd.CLABE ELSE CuentaBancaria END)    
           ELSE  NULL END                           AS [@CtaBeneficiario],    
           NULLIF(A.TipoCadenaPago, '')                        AS [@TipoCadPago],    
           NULLIF(A.CertificadoPago, '')                        AS [@CertPago],    
           NULLIF(REPLACE( A.CadenaPago,'|','&#124;'), '')                   AS [@CadPago],    
           NULLIF(A.SelloPago, '')                         AS [@SelloPago],    
           @DocRelacionado2    
          FROM CFDICobroParcial A    
           JOIN Empresa C ON A.Empresa = C.Empresa    
           LEFT JOIN CFDINominaSATInstitucionFin E ON A.ClaveBancoEmisor = E.Clave    
           LEFT JOIN CFDINominaSATInstitucionFin D ON A.ClaveBanco = D.Clave    
           LEFT JOIN FormaPago AS FP ON FP.FormaPago = A.FormaPago     
           LEFT JOIN SATFormaPago AS SFP ON SFP.Clave = FP.ClaveSAT    
           LEFT JOIN CtaDinero AS cd ON ISNULL(NULLIF(cd.NumeroCta,''),cd.CLABE)=a.CuentaBancaria        
          WHERE A.ID = @ID AND A.Estacion = @Estacion    
          FOR XML PATH ('pago20:Pago'))    
    END    
      SELECT @LlevaTotales = 0    
  FETCH NEXT FROM cCxc INTO @IdCxc, @IdCxcDIN, @IDMov    
  SELECT @MontoTP= LTRIM(REPLACE(REPLACE(dbo.fnXMLDecimal('', @PagadoTotal, @DecimalesP), '=', ''),'"',''))    
  SELECT @CuentaBeneficiaria= CASE WHEN ISNULL(@Bancarizado, SFP.Bancarizado)  = 1 THEN    
          (CASE WHEN @FormaDePagoDR IN ('02','03') THEN cd.CLABE ELSE CuentaBancaria END)    
          ELSE  NULL END    
          FROM CFDICobroParcial A    
          JOIN Empresa C ON A.Empresa = C.Empresa    
          LEFT JOIN CFDINominaSATInstitucionFin E ON A.ClaveBancoEmisor = E.Clave    
          LEFT JOIN CFDINominaSATInstitucionFin D ON A.ClaveBanco = D.Clave    
          LEFT JOIN FormaPago AS FP ON FP.FormaPago = A.FormaPago     
          LEFT JOIN SATFormaPago AS SFP ON SFP.Clave = FP.ClaveSAT    
          LEFT JOIN CtaDinero AS cd ON ISNULL(NULLIF(cd.NumeroCta,''),cd.CLABE)=a.CuentaBancaria        
          WHERE A.ID = @ID AND A.Estacion = @Estacion    
  SELECT @MontoTotalPago= ISNULL (@MontoTotalPago,0) + @MontoTP    
 END    
 CLOSE cCxc    
 DEALLOCATE cCxc   
 -- SELECT * INTO MALALADOS    FROM #TempImpuestoDR   SELECT * FROM MALALADOS    FROM #TempImpuestoDR  
-- SELECT * INTO AVENGER FROM @TrasladoDR   SELECT *  FROM AVENGER FROM @TrasladoDR  
 IF EXISTS (SELECT * FROM CFDIMovRelacionados WHERE Modulo = @Modulo AND IDModulo = @ID)    
 BEGIN    
  SET @Relacionado = 1    
  ;WITH XMLNAMESPACES ('http://www.sat.gob.mx/cfd/4' AS cfdi)    
  SELECT @CFDIRelacionados = '<cfdi:CfdiRelacionados xmlns:cfdi="http://www.sat.gob.mx/cfd/4" TipoRelacion="04"> ' +    
      (SELECT UUID                                                                          AS [@UUID]    
                      FROM CFDIMovRelacionados    
       WHERE Modulo = @Modulo AND IDModulo = @ID    
       FOR XML PATH ('cfdi:CfdiRelacionado')) + '</cfdi:CfdiRelacionados>'    
 END    
      SELECT @TotalRetencionesISR         = SUM(CASE ImpuestoP WHEN '001' THEN ROUND(ImporteP, 6) ELSE 0 END),    
             @TotalRetencionesIVA         = SUM(CASE ImpuestoP WHEN '002' THEN ROUND(ImporteP, 6) ELSE 0 END),    
             @TotalRetencionesIEPS        = SUM(CASE ImpuestoP WHEN '003' THEN ROUND(ImporteP, 6) ELSE 0 END)    
        FROM @RetencionTotal    
      SELECT @TotalTrasladosBaseIVA16     = ROUND(SUM(CONVERT(DECIMAL(20,6),BaseP)), 2),    
             @TotalTrasladosImpuestoIVA16 = ROUND(SUM(CONVERT(DECIMAL(20,6),ImporteP)), 2)--ROUND(CONVERT(DECIMAL(20,2), SUM(ImporteP)), 2)    
        FROM @TrasladoTotal    
       WHERE TasaOCuotaP = 0.16    
      SELECT @TotalTrasladosBaseIVA8     = ROUND(SUM(CONVERT(DECIMAL(20,6),BaseP)), 2),    
             @TotalTrasladosImpuestoIVA8 = ROUND(SUM(CONVERT(DECIMAL(20,6),ImporteP)), 2)    
        FROM @TrasladoTotal    
       WHERE TasaOCuotaP = 0.08    
         AND ImpuestoP = '002'    
      SELECT @TotalTrasladosBaseIVA0     = NULLIF(SUM(ROUND(CONVERT(DECIMAL(20,6), BaseP), 2)), 0),    
             @TotalTrasladosImpuestoIVA0 = ROUND(CONVERT(DECIMAL(20,6), SUM(ImporteP)), 2)    
        FROM @TrasladoTotal    
       WHERE TasaOCuotaP = 0    
         AND ImpuestoP = '002'    
      SELECT @TotalTrasladosBaseIVAExento     = NULLIF(SUM(ROUND(BaseP, 2)), 0)    
        FROM @TrasladoTotal    
       WHERE TipoFactorP = 'Exento'    
         AND ImpuestoP = '002'    
         AND ISNULL(BaseP, 0) > 0    
   SELECT @MontoTotalPagos   = NULLIF(SUM(ROUND(CONVERT(DECIMAL(20,6), @MontoTotalPagos), 2)), 0)    
        
  SELECT @XMLPago = REPLACE(@XMLPago, '_TotalRetencionesIVA_', LTRIM(REPLACE(REPLACE(dbo.fnXMLDecimal('', @TotalRetencionesIVA, @DecimalesDR), '=', ''),'"','')))    
  SELECT @XMLPago = REPLACE(@XMLPago, '_TotalRetencionesISR_', LTRIM(REPLACE(REPLACE(dbo.fnXMLDecimal('', @TotalRetencionesISR, @DecimalesDR), '=', ''),'"','')))    
  SELECT @XMLPago = REPLACE(@XMLPago, '_TotalRetencionesIEPS_', LTRIM(REPLACE(REPLACE(dbo.fnXMLDecimal('', @TotalRetencionesIEPS, @DecimalesDR), '=', ''),'"','')))    
  SELECT @XMLPago = REPLACE(@XMLPago, '_TotalTrasladosBaseIVA16_', LTRIM(REPLACE(REPLACE(dbo.fnXMLDecimal('', @TotalTrasladosBaseIVA16, @DecimalesDR), '=', ''),'"','')))    
  SELECT @XMLPago = REPLACE(@XMLPago, '_TotalTrasladosImpuestoIVA16_', LTRIM(REPLACE(REPLACE(dbo.fnXMLDecimal('', @TotalTrasladosImpuestoIVA16, @DecimalesDR), '=', ''),'"','')))    
  SELECT @XMLPago = REPLACE(@XMLPago, '_TotalTrasladosBaseIVA8_', LTRIM(REPLACE(REPLACE(dbo.fnXMLDecimal('', @TotalTrasladosBaseIVA8, @DecimalesDR), '=', ''),'"','')))    
  SELECT @XMLPago = REPLACE(@XMLPago, '_TotalTrasladosImpuestoIVA8_', LTRIM(REPLACE(REPLACE(dbo.fnXMLDecimal('', @TotalTrasladosImpuestoIVA8, @DecimalesDR), '=', ''),'"','')))    
  SELECT @XMLPago = REPLACE(@XMLPago, '_TotalTrasladosBaseIVA0_', LTRIM(REPLACE(REPLACE(dbo.fnXMLDecimal('', @TotalTrasladosBaseIVA0, @DecimalesDR), '=', ''),'"','')))    
  SELECT @XMLPago = REPLACE(@XMLPago, '_TotalTrasladosImpuestoIVA0_', LTRIM(REPLACE(REPLACE(dbo.fnXMLDecimal('', @TotalTrasladosImpuestoIVA0, @DecimalesDR), '=', ''),'"','')))    
  SELECT @XMLPago = REPLACE(@XMLPago, '_TotalTrasladosBaseIVAExento_', LTRIM(REPLACE(REPLACE(dbo.fnXMLDecimal('', @TotalTrasladosBaseIVAExento, @DecimalesDR), '=', ''),'"','')))    
  SELECT @XMLPago = REPLACE(@XMLPago, '_MontoTotalPagos_', LTRIM(REPLACE(REPLACE(dbo.fnXMLDecimal('', @MontoTotalPagos, @DecimalesDR), '=', ''),'"','')))    
  SELECT @XMLPago = REPLACE(@XMLPago, 'TotalRetencionesIVA=""', '')    
  SELECT @XMLPago = REPLACE(@XMLPago, 'TotalRetencionesISR=""', '')    
  SELECT @XMLPago = REPLACE(@XMLPago, 'TotalRetencionesIEPS=""', '')    
  SELECT @XMLPago = REPLACE(@XMLPago, 'TotalTrasladosBaseIVA16=""', '')    
  SELECT @XMLPago = REPLACE(@XMLPago, 'TotalTrasladosImpuestoIVA16=""', '')    
  SELECT @XMLPago = REPLACE(@XMLPago, 'TotalTrasladosBaseIVA8=""', '')    
  SELECT @XMLPago = REPLACE(@XMLPago, 'TotalTrasladosImpuestoIVA8=""', '')    
  SELECT @XMLPago = REPLACE(@XMLPago, 'TotalTrasladosBaseIVA0=""', '')    
  SELECT @XMLPago = REPLACE(@XMLPago, 'TotalTrasladosImpuestoIVA0=""', '')    
  SELECT @XMLPago = REPLACE(@XMLPago, 'TotalTrasladosBaseIVAExento=""', '')    
  SELECT @XMLPago = REPLACE(@XMLPago, 'TotalRetencionesIVA="0.00"', '')    
  SELECT @XMLPago = REPLACE(@XMLPago, 'TotalRetencionesISR="0.00"', '')    
  SELECT @XMLPago = REPLACE(@XMLPago, 'TotalRetencionesIEPS="0.00"', '')    
  SELECT @XMLPago = REPLACE(@XMLPago, 'TotalTrasladosBaseIVA16="0.00"', '')    
  SELECT @XMLPago = REPLACE(@XMLPago, 'TotalTrasladosImpuestoIVA16="0.00"', '')    
  SELECT @XMLPago = REPLACE(@XMLPago, 'TotalTrasladosBaseIVA8="0.00"', '')    
  SELECT @XMLPago = REPLACE(@XMLPago, 'TotalTrasladosImpuestoIVA8="0.00"', '')    
  SELECT @XMLPago = REPLACE(@XMLPago, 'TotalTrasladosBaseIVA0="0.00"', '')    
  IF @TotalTrasladosBaseIVA0 = 0    
 SELECT @XMLPago = REPLACE(@XMLPago, 'TotalTrasladosImpuestoIVA0="0.00"', '')    
  SELECT @XMLPago = REPLACE(@XMLPago, 'TotalTrasladosBaseIVAExento="0.00"', '')    
 ;WITH XMLNAMESPACES ('http://www.sat.gob.mx/Pagos20' AS pago20)    
 SELECT @XMLPagos = (SELECT @VersionPago       AS [@Version],    
        CAST(@XMLPago as xml)    
      FOR XML PATH ('pago20:Pagos'))    
 ;WITH XMLNAMESPACES ('http://www.sat.gob.mx/cfd/4' AS cfdi)    
 SELECT @XMLEmisor = (SELECT @RFCEmisor             AS [@Rfc],    
        @NombreEmisor            AS [@Nombre],    
        @RegimenFiscal            AS [@RegimenFiscal]    
      FOR XML PATH ('cfdi:Emisor'))    
 ;WITH XMLNAMESPACES ('http://www.sat.gob.mx/cfd/4'  AS cfdi)    
 SELECT @XMLReceptor = (SELECT @RFCReceptor            AS [@Rfc],    
         @NombreReceptor      AS [@Nombre],    
         @DomicilioFiscalReceptor   AS [@DomicilioFiscalReceptor],    
         @ResidenciaFiscal           AS [@ResidenciaFiscal],    
         @NumRegIdTrib            AS [@NumRegIdTrib],    
         @RegimenFiscalReceptor    AS [@RegimenFiscalReceptor],    
         'CP01'              AS [@UsoCFDI]    
       FOR XML PATH ('cfdi:Receptor'))    
  SELECT @XMLConceptos = '<cfdi:Conceptos xmlns:cfdi="http://www.sat.gob.mx/cfd/4"> <cfdi:Concepto ClaveProdServ="84111506" Cantidad="1" ClaveUnidad="ACT" Descripcion="Pago" ValorUnitario="0" Importe="0" ObjetoImp="01">'    
  IF @AgenteACuentaTerceros <> '' --AND @RfcACuentaTerceros <> '' AND @NombreACuentaTerceros <> '' AND @RegimenFiscalACuentaTerceros <> '' AND  @DomicilioFiscalACuentaTerceros <> ''    
      SELECT @XMLConceptos = @XMLConceptos + '<cfdi:ACuentaTerceros RfcACuentaTerceros="' + RTRIM(@RfcACuentaTerceros) + '" NombreACuentaTerceros="' + RTRIM(@NombreACuentaTerceros) + '" RegimenFiscalACuentaTerceros="' + RTRIM(@RegimenFiscalACuentaTerceros) + '" DomicilioFiscalACuentaTerceros="' + RTRIM(@DomicilioFiscalACuentaTerceros) + '"/>'    
  SELECT @XMLConceptos = @XMLConceptos + '</cfdi:Concepto></cfdi:Conceptos>'    
 SET @XMLComplemento = '<cfdi:Complemento xmlns:cfdi="http://www.sat.gob.mx/cfd/4">' + @XMLPagos + '</cfdi:Complemento>'      
 ;WITH XMLNAMESPACES ('http://www.sat.gob.mx/cfd/4' AS cfdi,    
        'http://www.sat.gob.mx/Pagos20' AS pago20)    
 SELECT @XMLComprobante = (SELECT @VersionCFDI                              AS [@Version],    
          cp.Folio                              AS [@Folio],    
          cp.Serie                              AS [@Serie],          
          CONVERT(VARCHAR(19), dbo.fnFechaConDiferenciaHoraria( GETDATE(), ISNULL(@Verano, 0), ISNULL(@Invierno, 0)), 126)    AS [@Fecha],    
          '0'                                AS [@SubTotal],    
          @Moneda                               AS [@Moneda],    
          '0'                                AS [@Total],    
          @FormaDePago                             AS [@formaDePago],    
          @MetodoDePago                             AS [@metodoDePago],    
          @TipoDeComprobante                            AS [@TipoDeComprobante],    
          @Exportacion                             AS [@Exportacion],    
          cp.LugarExpedicion                            AS [@LugarExpedicion],    
          NULLIF(cp.ConfirmacionPAC, '')                         AS [@Confirmacion],    
          '_NOCERTIFICADO_'                             AS [@NoCertificado],    
          '_CERTIFICADO_'                             AS [@Certificado],    
          '_SELLO_'                              AS [@Sello],    
          CAST(@CFDIRelacionados AS XML),    
          CAST(@XMLEmisor AS XML),    
          CAST(@XMLReceptor AS XML),     
          CAST(@XMLConceptos AS XML),    
          CAST(@XMLImpuestosFacturas AS XML),    
          CAST(@XMLComplemento AS XML)    
                           FROM  CFDICobroParcial AS cp    
                           WHERE ID = @ID AND Estacion = @Estacion    
        FOR XML PATH ('cfdi:Comprobante'))    
 SET @AlmacenarRutaNueva = @AlmacenarRuta    
 SET @NomArchivoNuevo = @NomArchivo    
 SELECT @AlmacenarRutaNueva = REPLACE(@AlmacenarRutaNueva,'<Cliente>', @Cliente)    
 SELECT @AlmacenarRutaNueva = REPLACE(@AlmacenarRutaNueva,'<Ejercicio>', @Ejercicio)    
 SELECT @AlmacenarRutaNueva = REPLACE(@AlmacenarRutaNueva,'<Periodo>', @Periodo)     
 SELECT @AlmacenarRutaNueva = REPLACE(@AlmacenarRutaNueva,'<Empresa>', @Empresa)    
 SELECT @AlmacenarRutaNueva = REPLACE(@AlmacenarRutaNueva,'<Sucursal>', @Sucursal)    
 SELECT @NomArchivoNuevo = REPLACE(@NomArchivoNuevo,'<Cliente>', @Cliente)    
 SELECT @NomArchivoNuevo = REPLACE(@NomArchivoNuevo,'<Periodo>', @Periodo)    
 SELECT @NomArchivoNuevo = REPLACE(@NomArchivoNuevo,'<Ejercicio>', @Ejercicio)    
 SELECT @NomArchivoNuevo = REPLACE(@NomArchivoNuevo,'<Empresa>', @Empresa)    
 SELECT @NomArchivoNuevo = REPLACE(@NomArchivoNuevo,'<Sucursal>', @Sucursal)    
 SELECT @NomArchivoNuevo = REPLACE(@NomArchivoNuevo,'<Movimiento>', @Movimiento)    
 SELECT @NomArchivoNuevo = REPLACE(@NomArchivoNuevo,'<Serie>', @Serie)    
 SELECT @NomArchivoNuevo = REPLACE(@NomArchivoNuevo,'<Folio>', @Folio)    
 EXEC spNombrePagoSustitucion @ID, @Modulo, 0 , @NumeroPago OUTPUT    
 SELECT @NomArchivoNuevo = @NomArchivoNuevo + @NumeroPago    
 SELECT @XMLComprobante = REPLACE(@XMLComprobante, ' xmlns:pago20="http://www.sat.gob.mx/Pagos20"', '')    
 SELECT @XMLComprobante = REPLACE(@XMLComprobante, ' xmlns:cfdi="http://www.sat.gob.mx/cfd/4"', '')    
 SELECT @XMLComprobante = REPLACE(@XMLComprobante, '<cfdi:Comprobante', '<cfdi:Comprobante xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:pago20="http://www.sat.gob.mx/Pagos20" xmlns:cfdi="http://www.sat.gob.mx/cfd/4" ' + @SchemaLocation)    
 SELECT @XMLComprobante = '<?xml version="1.0" encoding="UTF-8"?>' + @XMLComprobante    
 BEGIN TRY     
  EXEC spCrearRuta @AlmacenarRutaNueva, @Ok OUTPUT, @OkRef OUTPUT    
  IF @Ok IS NULL    
  BEGIN    
   SELECT @AlmacenarRutaNueva = @AlmacenarRutaNueva + '\' + @NomArchivoNuevo + '.tmp'    
   EXEC spRegenerarArchivo @AlmacenarRutaNueva, @XMLComprobante, @Ok OUTPUT, @OkRef OUTPUT    
   IF @Ok IS NULL    
   BEGIN    
    SET @SQL = CHAR(34) + CHAR(34) + RTRIM(LTRIM(@RutaAnsiUTF)) + CHAR(34) + ' A2U ' + CHAR(34) + LTRIM(RTRIM(@AlmacenarRutaNueva)) + CHAR(34) + CHAR(34)    
    EXEC xp_cmdshell @SQL, no_output    
    EXEC spCFDITimbrarPago @Modulo, @ID, @Empresa, @AlmacenarRutaNueva, @XMLComprobante, @CFDITimbrado OUTPUT, @CadenaOriginal OUTPUT, @Ok OUTPUT, @OkRef OUTPUT, @TipoCFD    
    IF @Ok IS NULL    
    BEGIN    
     SELECT @Cont = @Cont + 1, @AlmacenarRutaNueva = REPLACE(@AlmacenarRutaNueva, '.tmp','')    
     EXEC spCFDIPagoObtenerTimbre @CFDITimbrado, @SelloSAT OUTPUT, @SelloCFD OUTPUT, @FechaTimbrado OUTPUT, @UUID OUTPUT, @TFDVersion OUTPUT, @noCertificadoSAT OUTPUT, @TFDCadenaOriginal OUTPUT, @Ok OUTPUT, @OkRef OUTPUT    
     SET @newID =  NEWID() 
	 
     INSERT INTO AnexoMov(Rama, ID, Nombre, Direccion, Icono, Tipo, Orden, Sucursal, FechaEmision, Alta, UltimoCambio, CFD,FS)    
     VALUES(@Modulo, @ID, @NomArchivoNuevo + '.xml', @AlmacenarRutaNueva + '.xml', 17, 'Archivo', NULL, @Sucursal, @FechaTimbrado, @FechaTimbrado, @FechaTimbrado, 1,@newID)    
     
	 IF @CadenaOriginal IS NULL OR @CadenaOriginal = ''
     BEGIN    
      SELECT @RutaFirmaSAT= RutaFirmaSAT    
       FROM EmpresaCFD    
        WHERE Empresa = @Empresa    
      DELETE @Datos    
      SET @Shell = CHAR(34) + CHAR(34) + @RutaFirmaSAT + CHAR(34) + ' PIPESTRING ' + CHAR(34) +@AlmacenarRutaNueva + '.xml' + CHAR(34) + CHAR(34)    
      INSERT @Datos EXEC @r = xp_cmdshell @Shell    
      SELECT @CadenaOriginal= COALESCE(@CadenaOriginal + ISNULL(Datos, ''), '') FROM @Datos ORDER BY ID    
     END    
     
	 IF (SELECT v.UsarAnexosSQL FROM Version AS v)=1    
     BEGIN    
      SELECT @RutaFS=Direccion FROM AnexoMov AS am WHERE ID = @ID AND Rama = @Modulo      
      EXEC spGuardarAnexoFS @TablaD='AnexoMovFS',@ID = @newID , @Direccion = @RutaFS, @Formato = null, @Tamano = null, @VB = null     
     END    
     INSERT CFDICobroParcialTimbrado(Modulo, Movimiento, IDModulo, FechaEmision, Ejercicio, Periodo, Empresa, MovID, Serie, Folio, Cliente, RFC, Importe, TipoCambio, noCertificado,    
             Sello, CadenaOriginal, Documento, UUID, GeneraPDF, Timbrado, FechaTimbrado, SelloSAT, TFDVersion, noCertificadoSAT, TFDCadenaOriginal,    
          ClaveBancoCte, CuentaBancariaCte, ClabeCuentaCte, TarjetaCte, MontoTP, FormaPago, CtaBeneficiaria,  AjusteMontoTotal)    
     SELECT @Modulo, @Movimiento, @ID, A.FechaEmision, @Ejercicio, @Periodo, @Empresa, A.MovID, A.Serie, A.Folio, @Cliente, @RFCReceptor, @MontoTotalPago, A.TipoCambio, @noCertificado,    
          @SelloCFD, @CadenaOriginal, @CFDITimbrado, @UUID, 1, 1, @FechaTimbrado, @SelloSAT, @TFDVersion, @noCertificadoSAT, @TFDCadenaOriginal,    
          A.ClaveBancoEmisor, A.CuentaBancariaCte, A.ClabeCuenta, A.Tarjeta, @MontoTP, A.FormaPago, @CuentaBeneficiaria, @AjustarMontoTotalPagos         
      FROM CFDICobroParcial A    
      WHERE A.ID = @ID AND A.Estacion = @Estacion    
     IF EXISTS (SELECT * FROM @DatosFactoraje)    
     BEGIN    
      INSERT CFDICobroFactoraje (Modulo,ModuloID,Mov,MovID,ModuloFactoraje,ModuloFactorajeID,MovFactoraje,MovFactorajeID,Empresa,Cliente,MovFactorajeD,MovFactorajeIDD)    
      SELECT        Modulo,ModuloID,Mov,MovID,ModuloFactoraje,ModuloFactorajeID,MovFactoraje,MovFactorajeID,Empresa,Cliente,MovFactorajeD,MovFactorajeIDD    
       FROM @DatosFactoraje     
      DELETE FROM CFDICobroFactorajePaso WHERE Estacion=@Estacion AND ModuloID=@ID    
     END    
     IF EXISTS (SELECT * FROM CFD WHERE Modulo = @Modulo AND ModuloID = @ID AND Cancelado = 0)    
      DELETE FROM CFD WHERE Modulo = @Modulo AND ModuloID = @ID AND Cancelado = 0    
     INSERT CFD (Modulo, ModuloID, Fecha, Ejercicio, Periodo, Empresa, MovID, Serie, Folio, RFC, Importe, noCertificado, Sello,    
       CadenaOriginal, Documento, GenerarPDF, Timbrado, UUID, FechaTimbrado, TipoCambio, SelloSAT, TFDVersion, noCertificadoSAT, TFDCadenaOriginal, Retencion1, Retencion2, Impuesto1, Impuesto2)    
     SELECT @Modulo, @ID, A.FechaEmision, @Ejercicio, @Periodo, @Empresa, A.MovID, A.Serie, dbo.fnSoloNumero(A.Folio) , @RFCReceptor, (A.Monto - ISNULL(@TotalTrasladosImpuestoIVA16, 0) - ISNULL(@TotalTrasladosBaseIVA8, 0))  , @noCertificado, @SelloCFD,   
 
       @CadenaOriginal, @CFDITimbrado, 1, 1, @UUID, @FechaTimbrado, A.TipoCambio, @SelloSAT, @TFDVersion, @noCertificadoSAT, @TFDCadenaOriginal, @TotalRetencionesISR ,@TotalRetencionesIVA,   (ISNULL(@TotalTrasladosImpuestoIVA16, 0) + ISNULL(@TotalTrasladosBaseIVA8, 0)), @TotalRetencionesIEPS    
      FROM CFDICobroParcial A    
      WHERE A.ID = @ID AND A.Estacion = @Estacion    
     INSERT CFDTipoComprobante (UUID,     Cancelado, EmitidasRecibidas, Formapago,  TipoDeComprobante,  MetodoPago,  Moneda,  Ejercicio,       Periodo,          Empresa,  Importe,     TipoCambio,  Mov,  MovID,  Sucursal,  FechaEmision,  FechaCancelacion, Total)    
                   SELECT      @UUID,  0,         'Emitidas',     @FormaPagoCobro,  @TipoDeComprobante, NULL , @Moneda, YEAR(@FechaTimbrado), MONTH(@FechaTimbrado), @Empresa, A.Monto,  @TipoCambioP, A.Mov, A.MovID, A.Sucursal, A.FechaEmision, NULL, @MontoTotalPago    
      FROM CFDICobroParcial A    
      WHERE A.ID = @ID AND A.Estacion = @Estacion    
     INSERT CFDIDocRelacionadoTimbrado (Modulo, IDModulo, UUID, Serie, Folio, ImpPagado, ImpSaldoAnt, ImpSaldoInsoluto, Moneda, TipoCambio, NumParcialidad, MetodoPago, IDCobro, ObjetoImpDR, EquivalenciaDR, IDD, TieneAjusteNegativo)    
     SELECT @Modulo, @ID, UUID, Serie, Folio, ImpPagado, ImpSaldoAnt, ImpSaldoInsoluto, Moneda, TipoCambio, NumParcialidad, MetodoPago, IDCobro, ObjetoImpDR, EquivalenciaDR, IDD, TieneAjusteNegativo    
      FROM @DocRelacionadoTimbrado    
          INSERT CFDIDocRelacionadoImpuestos(    
                  Modulo, IDModulo, UUID, Tipo,          TipoFactor, TasaOCuota, Impuesto, Importe, Base, NumParcialidad, IDCobro)    
          SELECT @Modulo, @ID,      UUID, 'RetencionDR', TipoFactorP, TasaOCuotaP, ImpuestoP, CASE WHEN @MonedaP = @MonedaDocto THEN ImporteP ELSE ImportePMN END, CASE WHEN @MonedaP = @MonedaDocto THEN BaseP ELSE BasePMN END, NumParcialidad, IDCobro    
            FROM @RetencionTotal    
           ORDER BY UUID, TipoFactorP, TasaOCuotaP    
          INSERT CFDIDocRelacionadoImpuestos(    
                  Modulo, IDModulo, UUID, Tipo,          TipoFactor, TasaOCuota, Impuesto, Importe, Base, NumParcialidad, IDCobro)    
          SELECT @Modulo, @ID,      UUID, 'TrasladoDR', TipoFactorP, TasaOCuotaP, ImpuestoP, CASE WHEN @MonedaP = @MonedaDocto THEN ImporteP ELSE ImportePMN END, CASE WHEN @MonedaP = @MonedaDocto THEN BaseP ELSE BasePMN END, NumParcialidad, IDCobro    
            FROM @TrasladoTotal    
           ORDER BY UUID, TipoFactorP, TasaOCuotaP    
     IF @Modulo='CXC'    
     BEGIN    
      UPDATE CXC SET CFDTimbrado = 1 WHERE ID=@ID    
     END    
     INSERT CFDICobroParcialPDF (Estacion, ID, Modulo, IDModulo, Ruta)    
     SELECT @Estacion, @Cont, @Modulo, @ID, @AlmacenarRutaNueva    
     SET @newID =  NEWID()    
     INSERT INTO AnexoMov(Rama, ID, Nombre, Direccion, Icono, Tipo, Orden, Sucursal, FechaEmision, Alta, UltimoCambio, CFD,FS)    
     VALUES(@Modulo, @ID, @NomArchivoNuevo + '.pdf', @AlmacenarRutaNueva + '.pdf', 745, 'Archivo', NULL, @Sucursal, @FechaTimbrado, @FechaTimbrado, @FechaTimbrado, 1, @newID)    
     EXEC spInformacionAdicional @ID, @Modulo, @Empresa, @Estacion    
     IF NOT EXISTS (SELECT * FROM @LimpiarClientes WHERE Cliente = @Cliente)    
      INSERT @LimpiarClientes (Cliente)    
      VALUES (@Cliente)    
     IF @Relacionado = 1    
     BEGIN    
      UPDATE CFDICobroParcialTimbrado    
        SET Relacionado = 1    
       FROM CFDICobroParcialTimbrado AS cpt    
       INNER JOIN CFDIMovRelacionados AS mr ON cpt.Modulo = mr.OrigenModulo AND cpt.IDModulo = mr.OrigenIDModulo    
       WHERE mr.Modulo = @Modulo AND mr.IDModulo = @ID    
      DELETE FROM CFDIMovRelacionados WHERE IDModulo = @ID AND Modulo = @Modulo    
     END     
    END ELSE    
     IF EXISTS (SELECT * FROM @LimpiarClientes WHERE Cliente = @Cliente)    
      DELETE FROM @LimpiarClientes    
      WHERE Cliente = @Cliente    

   END    
  END      
   SELECT @OkRef    
  END TRY    
    BEGIN CATCH    
   INSERT CFDICobroParcialLog(Estacion, IDCobro, Mov, MovID, Error )    
   SELECT @Estacion, ID, Mov, MovID, ISNULL(ERROR_MESSAGE(), '')    
   FROM CFDICobroParcial    
   WHERE ID = @ID    
   IF EXISTS (SELECT * FROM @LimpiarClientes WHERE Cliente = @Cliente)    
    DELETE FROM @LimpiarClientes    
    WHERE Cliente = @Cliente    

	--JARC ENVIAR CORREO DE MANERA AUTOMATICA
	EXEC spEnviarRecepcionPago @ID,@Empresa,@Modulo

  END CATCH    
  FETCH NEXT FROM CPagos INTO @ID        
 END    
 CLOSE CPagos    
 DEALLOCATE CPagos    
 IF EXISTS (SELECT * FROM @LimpiarClientes)    
  UPDATE Cte    
  SET Cte.CtaBanco = NULL, Cte.ClaveBanco = NULL, cte.ClabeCuenta=NULL ,cte.tarjeta=NULL    
  FROM Cte    
   INNER JOIN @LimpiarClientes AS lp ON lp.Cliente = Cte.Cliente    
END
GO
/**********************************************************************************************          Respaldo         *********************************************************************************************/
/**********************************************************************************************   spEnviarRecepcionPago   *********************************************************************************************/

--CREATE PROCEDURE spXMLPagosParciales    
-- @Estacion   INT,    
-- @Empresa   VARCHAR(5)    
--AS    
--BEGIN    
-- SET CONCAT_NULL_YIELDS_NULL ON    
-- DECLARE    
--  @XMLConceptos   VARCHAR(MAX),    
--  @XMLPagos    VARCHAR(MAX),    
--  @XMLPago    VARCHAR(MAX),    
--  @XMLComplemento   VARCHAR(MAX),    
--  @XMLComprobante   VARCHAR(MAX),    
--  @XMLImpuestosDoc  VARCHAR(MAX),    
--  @CFDIRelacionados  VARCHAR(MAX),    
--  @XMLEmisor    VARCHAR(MAX),    
--  @XMLReceptor   VARCHAR(MAX),    
--  @DocRelacionado   VARCHAR(MAX),    
--    @DocRelacionado2   xml,    
--    @XMLImpuestosDR     varchar(MAX),    
--    @XMLImpuestosDR2    xml,    
--    @XMLTrasladoDR      varchar(MAX),    
--    @XMLRetencionDR     varchar(MAX),    
--    @XMLImpuestosP      varchar(MAX),    
--    @XMLImpuestosP2     xml,    
--    @XMLTrasladoP       varchar(MAX),    
--    @CompensacionIEPS   float,    
--    @XMLRetencionP      varchar(MAX),    
--  @Conceptos    VARCHAR(MAX),    
--  @XMLImpuestosFacturas VARCHAR(MAX),    
--  @VersionPago   VARCHAR(5),    
--  @VersionCFDI   VARCHAR(5),    
--  @ID      INT,    
--  @AlmacenarRuta   VARCHAR(255),    
--  @AlmacenarRutaNueva  VARCHAR(255),    
--  @RutaAnsiUTF   VARCHAR(255),    
--  @SQL     VARCHAR(1000),    
--  @Cliente    VARCHAR(13),    
--  @Ejercicio    VARCHAR(4),    
--  @Periodo    VARCHAR(2),    
--  @IDVenta    INT,    
--    @IDVenta2    INT,    
--  @EsSaldoinicial   BIT,    
--  @noCertificado   VARCHAR(20),    
--  @SaldoAnterior   MONEY,    
--  @SaldoInsoluto   MONEY,    
--  @MontoTotal    MONEY,    
--  @MontoTotalPesos  MONEY,    
--  @MontoPagado   MONEY,    
--  @PagadoTotal   DECIMAL(20,10),    
--  @SaldoPendiente   MONEY,    
--  @IdCxc     INT,    
--  @NumParcialidad   INT,    
--  @MonedaP    VARCHAR(4),    
--  @MonedaDocto   VARCHAR(4),    
--  @RFCEmisor    VARCHAR(20),    
--  @NombreEmisor   VARCHAR(100),    
--  @NombreReceptor   VARCHAR(255),    
--  @RegimenFiscal   VARCHAR(30),    
--  @RFCReceptor   VARCHAR(20),    
--  @ResidenciaFiscal  VARCHAR(5),    
--  @NumRegIdTrib   VARCHAR(40),    
--  @UsoCFDI    VARCHAR(5),    
--  @MetodoDePagoDR   VARCHAR(5),    
--  @TipoDeComprobante  VARCHAR(10),    
--  @FormaDePago   VARCHAR(5),    
--  @Moneda     VARCHAR(4),    
--  @MetodoDePago   VARCHAR(5),    
--  @Movimiento    VARCHAR(20),    
--  @NomArchivo    VARCHAR(100),    
--  @NomArchivoNuevo  VARCHAR(100),    
--  @Serie     VARCHAR(10),    
--  @Folio     VARCHAR(50),    
--  @Sucursal    INT,    
--  @Modulo     VARCHAR(5),    
--  @ModuloRelacionado  VARCHAR(5),    
--  @Ok      INT,     
--  @OkRef     VARCHAR(MAX),    
--  @SchemaLocation   VARCHAR(1000),    
--  @TipoCFD    VARCHAR(10),    
--  @DecimalesP    INT,    
--  @DecimalesDR   INT,    
--  @Cont     INT,    
--  @TipoCambioP   FLOAT,    
--  @Relacionado   INT,    
--  @FormaPagoCobro   VARCHAR(5),    
--  @Bancarizado   BIT,    
--  @MovClave    VARCHAR(20),    
--  @MovClaveEsNeteo  VARCHAR(20),    
--  @Redondeo    BIT,    
--  @UUIDDR     VARCHAR(50),    
--  @SerieDR    VARCHAR(10),    
--  @FolioDR    VARCHAR(50),    
--  @TipoCambioDR   FLOAT,    
--  @CFDITimbrado   VARCHAR(MAX),    
--  @CadenaOriginal   VARCHAR(MAX),    
--  @FechaTimbrado   VARCHAR(MAX),    
--  @UUID     VARCHAR(50),    
--  @SelloSAT    VARCHAR(MAX),    
--  @SelloCFD    VARCHAR(MAX),    
--  @TFDVersion    VARCHAR(MAX),    
--  @noCertificadoSAT  VARCHAR(MAX),    
--  @TFDCadenaOriginal  VARCHAR(MAX),    
--  @IdCPC     INT ,    
--  @Shell     VARCHAR(8000),    
--  @r      VARCHAR(MAX),    
--  @RutaFirmaSAT   varchar(255),    
--  @IDCP     INT ,    
--  @AlmacenarCFD   BIT,    
--  @FcID     INT,    
--  @FIDVenta    INT,    
--  @FAplica    VARCHAR(30),    
--  @FAplicaID    VARCHAR(30),    
--  @FAplica_c    VARCHAR(30),    
--  @FAplicaID_c    VARCHAR(30),    
--  @FAplicaID_A   VARCHAR(30),    
--  @MovFactoraje   VARCHAR(30),    
--  @MovIDFactoraje   VARCHAR(30),    
--  @FModulo    VARCHAR(5),    
--  @FModuloID    INT,    
--  @FMov     VARCHAR(50),    
--  @FMovID     VARCHAR(50),    
--  @FModuloFactoraje  VARCHAR(5),    
--  @FVentaID    INT ,    
--  @FIDCobro    INT,    
--  @FClave_c    VARCHAR(50),    
--  @FcID_Anterior   INT,    
--  @FormaDePagoDR   VARCHAR(10),    
--  @MontoTP    MONEY,    
--  @CuentaBeneficiaria  VARCHAR(50),    
--  @MontoPagadoPrevio      FLOAT,    
--  @MontoPagadoPrevioPesos   FLOAT,    
--  @SaldoAnteriorPesos    FLOAT,    
--  @MontoPagadoPesos    FLOAT,    
--  @SaldoPendientePesos   FLOAT,    
--  @TipoCambioDRSAT    FLOAT,    
--  @IDAplicaCobro     INT,    
--  @ClaveAplicaCobro    VARCHAR(10),    
--  @AplicaFactor     FLOAT,    
--  @MontoFactor     FLOAT,    
--    @MontoFactor2     FLOAT,    
--  @FechaEmisionCFDI    DATETIME,    
--  @newID       UNIQUEIDENTIFIER,    
--  @RutaFS       VARCHAR (500),    
--  @EnviarAnexos     BIT,    
--  @EnviarXML      BIT,    
--  @EnviarPDF      BIT,    
--  @MontoPagadoPrevioPesosDoctos   FLOAT,    
--  @MontoPagadoPrevioDoctos        FLOAT,    
--  @NumParcialidadDoctos           INT,    
--  @IdCxcAntes      INT,    
--  @MontoTotalPago     FLOAT,    
--  @IdCxcParcialidad    INT,    
--  @ClaveDetalle     VARCHAR(20),    
--  @FDMov       VARCHAR(20),          
--  @FDMovID      VARCHAR(20),    
--  @MovFactorajeD     VARCHAR(20),    
--  @MovFactorajeIDD    VARCHAR(20),    
--  @IdCxcDIN      INT,    
--  @Factoraje      BIT,    
--  @IDMov       INT,    
--  @NumeroPago      VARCHAR(10),    
--  @FactorajeE      BIT,    
--    @FactorajeE2     BIT,    
--  @FolioDRCXC      VARCHAR(20),    
--  @MovDRCXC                       VARCHAR(20),    
--  @FechaEmision     DATETIME,    
--  @FechaOriginal     DATETIME,    
--  @ClaveOFactoraje    VARCHAR(20),      
--  @SaldoInicialFactoraje   BIT,    
--  @MontoMovREP     BIT,    
--  @MontoMov      FLOAT,    
--  @Verano       FLOAT,    
--    @Invierno      FLOAT,    
--    @Exportacion        varchar(2),    
--    @DomicilioFiscalReceptor    varchar(6),    
--    @RegimenFiscalReceptor      varchar(3),    
--    @AgenteACuentaTerceros      varchar(10),    
--    @RfcACuentaTerceros         varchar(15),    
--    @NombreACuentaTerceros      varchar(255),    
--    @RegimenFiscalACuentaTerceros varchar(30),    
--    @DomicilioFiscalACuentaTerceros varchar(6),    
--    @TotalRetencionesIVA          float,    
--    @TotalRetencionesISR          float,    
--    @TotalRetencionesIEPS         float,    
--    @TotalTrasladosBaseIVA16      float,    
--    @TotalTrasladosImpuestoIVA16  float,    
--    @TotalTrasladosBaseIVA8       float,    
--    @TotalTrasladosImpuestoIVA8   float,    
--    @TotalTrasladosBaseIVA0       float,    
--    @TotalTrasladosImpuestoIVA0   float,    
--    @TotalTrasladosBaseIVAExento  float,    
--    @TotalCompensacionIEPS        float,    
--    @MontoTotalPagos              float,    
--    @TipoFactorDR                 varchar(5),    
--    @TasaOCuotaDR                 float,    
--    @ImpuestoDR                   varchar(3),    
--    @ImporteDR                    float,    
--    @BaseDR                       float,    
--    @ObjetoImpDR                  varchar(2),    
--    @LlevaTotales                 bit,    
--    @ModuloTR                     varchar(5),    
--    @IDTR                         int,    
--    @EquivalenciaDR               float,    
--    @DecimalesTrasladoP        INT,    
--    @SumaMonto                    float,    
--    @Consecutivo                  int,    
-- @AjustarMontoTotalPagos   FLOAT,    
-- @TieneAjusteNegativo   BIT = 0    
--  DECLARE @Datos TABLE (ID int IDENTITY(1,1), Datos varchar(255))    
--  DECLARE @DocRelacionadoTimbrado TABLE(    
--   Modulo     VARCHAR(5),    
--   ModuloID    INT,    
--   UUID     VARCHAR(36),    
--   Serie     VARCHAR(20),    
--   Folio     INT,    
--   ImpPagado    FLOAT,--DECIMAL(18,2),    
--   ImpSaldoAnt    FLOAT,--DECIMAL(18,2),    
--   ImpSaldoInsoluto  FLOAT,--DECIMAL(18,2),    
--   Moneda     VARCHAR(5),    
--   TipoCambio    FLOAT,    
--   NumParcialidad   INT,    
--   MetodoPago    VARCHAR(5),    
--   IDCobro     INT,    
--   ObjetoImpDR    VARCHAR(3),    
--   EquivalenciaDR   FLOAT,    
--   IDD      INT,    
--   TieneAjusteNegativo  BIT)    
--  DECLARE @PagosFactura TABLE(    
--   ID    INT,    
--   MontoPagado  FLOAT,    
--   Clave   VARCHAR(10),    
--   SubClave  VARCHAR(20),    
--   ClaveD   VARCHAR(20),    
--   CFD    BIT,    
--   Parcialidad  BIT     
--  )    
--  DECLARE @PagosAplica TABLE(    
--   Aplica   VARCHAR(20),    
--   AplicaID  VARCHAR(20),    
--   Parcialidad  BIT     
--  )     
--  DECLARE @LimpiarClientes TABLE(    
--Cliente   VARCHAR(10)    
--  )    
--  DECLARE @FacturasRelacionadas TABLE(    
--   UUID   VARCHAR(50),    
--      Factoraje     bit    
--  )    
--  DECLARE @DatosFactoraje TABLE(    
--  Modulo    VARCHAR (5) ,    
--  ModuloID   INT,    
--  Mov     VARCHAR(50),    
--  MovID    VARCHAR(50),    
--  ModuloFactoraje  VARCHAR(5),    
--  ModuloFactorajeID INT,    
--  MovFactoraje  VARCHAR(50),    
--  MovFactorajeID  VARCHAR(30),    
--  Empresa    VARCHAR(50),    
--  Cliente    VARCHAR(50),    
--  MovFactorajeD  VARCHAR(20),    
--  MovFactorajeIDD VARCHAR(20)      
--  )    
--  DECLARE @PagosFacturaenDoctos TABLE(    
--   ID    INT,    
--   Mov             varchar(20),    
--   movID           varchar(20),    
--   MontoPagado  FLOAT,    
--   Clave   VARCHAR(10),    
--   Aplica   VARCHAR(20),    
--   AplicaID  VARCHAR(20),    
--   Sucursal        int,    
--   Empresa         varchar(10),    
--   Parcialidad  bit,    
--   Moneda          varchar(20),    
--   Importe         float,    
--   TipoCambio      float,    
--   ImporteTotal    float      
--  )    
--  DECLARE @Movimientos TABLE (    
--  OID   INT,    
--  OModulo  VARCHAR(5),    
--  OMov  VARCHAR(20),    
--  OMovID  VARCHAR(20),    
--  DID   INT,    
--  DModulo  VARCHAR(5),    
--  DMov  VARCHAR(20),    
--  DMovID  VARCHAR(20),    
--  Nivel  INT,    
--  Clave  VARCHAR(10)    
--  )    
--  DECLARE @PagosFacturaCobro TABLE(    
--   IDVenta    INT ,    
--   IDCobro    INT ,    
--   UUID    VARCHAR(50),    
--   MontoPagado   FLOAT,    
--   Parcialidad   INT,    
--   Factoraje   BIT     
--  )    
--    DECLARE @TrasladoDR TABLE(    
--    UUID            varchar(36),    
--    TipoFactorDR    varchar(6),    
--    TasaOCuotaDR    float,    
--    ImpuestoDR      varchar(3),    
--    ImporteDR       float,    
--    BaseDR          float,    
--    NumParcialidad  int)    
--    DECLARE @RetencionDR TABLE(    
--    UUID            varchar(36),    
--    TipoFactorDR    varchar(5),    
--    TasaOCuotaDR    float,    
--    ImpuestoDR      varchar(3),    
--    ImporteDR       float,    
--    BaseDR          float,    
--    NumParcialidad  int)    
--    DECLARE @TrasladoP TABLE(    
--    Modulo          varchar(5),    
--    ModuloID        int,    
--    UUID            varchar(36),    
--    TipoFactorP     varchar(6),    
--    TasaOCuotaP     float,    
--    ImpuestoP       varchar(3),    
--    ImporteP        float,    
--    BaseP           float,    
--    NumParcialidad  int,    
--    ImportePMN      float,    
--    BasePMN         float,    
--    ObjetoImpDR     varchar(2))    
--    DECLARE @TrasladoTotal TABLE(    
--    Modulo          varchar(5),    
--    ModuloID        int,    
--    UUID            varchar(36),    
--    TipoFactorP     varchar(6),    
--    TasaOCuotaP     float,    
--    ImpuestoP       varchar(3),    
--    ImporteP        float,    
--    BaseP           float,    
--    NumParcialidad  int,    
--    ImportePMN      float,    
--    BasePMN         float,    
--    IDCobro         int,    
--    ObjetoImpDR     varchar(2))    
--    DECLARE @RetencionP TABLE(    
--    Modulo          varchar(5),    
--    ModuloID        int,    
--    UUID            varchar(36),    
--    TipoFactorP     varchar(5),    
--    TasaOCuotaP     float,    
--    ImpuestoP       varchar(3),    
--    ImporteP        float,    
--    BaseP           float,    
--    NumParcialidad  int,    
--    ImportePMN      float,    
--    BasePMN         float)    
--    DECLARE @RetencionTotal TABLE(    
--    Modulo          varchar(5),    
--    ModuloID        int,    
--    UUID            varchar(36),    
--    TipoFactorP     varchar(5),    
--    TasaOCuotaP     float,    
--    ImpuestoP       varchar(3),    
--    ImporteP        money,    
--    BaseP           money,    
--    NumParcialidad  int,    
--    ImportePMN      money,    
--    BasePMN         money,    
--    IDCobro         int)    
--    CREATE TABLE #TempImpuestoDR(    
--    Modulo varchar(5),    
--    ModuloID int,    
--    IDCobro   int,    
--    IDVenta   int,    
--    Impuesto1 float   NULL,    
--    Impuesto2 float   NULL,    
--    Impuesto3 float   NULL,    
--    Impuesto5 float   NULL,    
--    Importe1 float   NULL,    
--    Importe2 float   NULL,    
--    Importe3 float   NULL,    
--    Importe5 float   NULL,    
--    SubTotal float   NULL,    
--    Retencion1 float   NULL,    
--    Retencion2 float   NULL,    
--    Retencion3 float   NULL,    
--    Excento1 bit   NULL)    
-- IF (SELECT CFD FROM Empresa WHERE Empresa = @Empresa) = 1    
--  SET @TipoCFD = 'Ant'    
-- ELSE IF (SELECT CONVERT(INT, ISNULL(eDoc, 0)) + CONVERT(INT, ISNULL(CFDFlex, 0)) FROM EmpresaGral WHERE Empresa = @Empresa) = 2    
--  SET @TipoCFD = 'Flex'    
-- ELSE    
-- BEGIN    
--  SELECT 'No tiene configurado CFD'    
--     RETURN    
-- END    
-- DELETE FROM CFDICobroParcialLog WHERE Estacion = @Estacion    
-- DELETE FROM CFDICobroParcialPDF WHERE Estacion = @Estacion    
-- SELECT @VersionPago = VersionPago, @VersionCFDI = VersionCFDI FROM CFDICobroParcialVersion WHERE Empresa = @Empresa    
-- DELETE  @DatosFactoraje    
-- SET @Cont = 0    
-- SELECT @RFCEmisor = RFC,    
--     @NombreEmisor = Nombre,    
--     @RegimenFiscal = FiscalRegimen    
-- FROM Empresa    
-- WHERE Empresa = @Empresa    
-- IF @VersionCFDI = '3.2'    
-- BEGIN    
--  SET @TipoDeComprobante = 'Ingreso'    
--  SET @FormaDePago = 'NA'    
--  SET @Moneda = NULL    
--  SET @metodoDePago = 'Pago'    
--  SET @XMLImpuestosFacturas = '<cfdi:Impuestos xmlns:cfdi="http://www.sat.gob.mx/cfd/4"></cfdi:Impuestos>'    
--  SET @SchemaLocation = 'xsi:schemaLocation="http://www.sat.gob.mx/cfd/4 http://www.sat.gob.mx/sitio_internet/cfd/3/cfdv32.xsd http://www.sat.gob.mx/Pagos http://www.sat.gob.mx/sitio_internet/cfd/Pagos/Pagos10.xsd"'    
-- END     
-- ELSE IF @VersionCFDI = '3.3'    
-- BEGIN    
--  SET @TipoDeComprobante = 'P'    
--  SET @FormaDePago = NULL    
--  SET @Moneda = 'XXX'    
--  SET @MetodoDePago = NULL    
--  SET @XMLImpuestosFacturas = NULL    
--  SET @SchemaLocation = 'xsi:schemaLocation="http://www.sat.gob.mx/cfd/3 http://www.sat.gob.mx/sitio_internet/cfd/3/cfdv33.xsd http://www.sat.gob.mx/Pagos http://www.sat.gob.mx/sitio_internet/cfd/Pagos/Pagos10.xsd"'    
-- END    
--  ELSE IF @VersionCFDI = '4.0'    
-- BEGIN    
--  SET @TipoDeComprobante = 'P'    
--    SET @Exportacion = '01'    
--  SET @FormaDePago = NULL    
--  SET @Moneda = 'XXX'    
--  SET @MetodoDePago = NULL    
--  SET @XMLImpuestosFacturas = NULL    
--  SET @SchemaLocation = 'xsi:schemaLocation="http://www.sat.gob.mx/cfd/4 http://www.sat.gob.mx/sitio_internet/cfd/4/cfdv40.xsd http://www.sat.gob.mx/Pagos20 http://www.sat.gob.mx/sitio_internet/cfd/Pagos/Pagos20.xsd"'    
-- END    
-- DECLARE CPagos CURSOR FOR    
--  SELECT DISTINCT ID FROM ListaID AS l    
--   INNER JOIN CFDICobroVenta AS cv ON cv.IDMovimiento = l.ID    
--  WHERE l.Estacion = @Estacion AND cv.Empresa = @Empresa    
-- OPEN CPagos    
-- FETCH NEXT FROM CPagos INTO @ID    
-- WHILE @@FETCH_STATUS = 0    
-- BEGIN     
--        SELECT @LlevaTotales = 1    
--  SELECT @MontoTotalPagos = 0    
--  DELETE FROM @TrasladoTotal    
--  DELETE FROM @RetencionTotal    
--  SET @MontoTotalPago =NULL      
--  SELECT  @Cliente   = A.Cliente,    
--    @Movimiento = A.Mov,    
--    @Sucursal = A.Sucursal,    
--    @Ejercicio = CAST(DATEPART(YEAR, ISNULL(A.FechaOriginal, A.FechaEmision))  AS VARCHAR(4)),    
--    @Periodo   = CAST(DATEPART(MONTH, ISNULL(A.FechaOriginal, A.FechaEmision)) AS VARCHAR(2)),    
--    @RFCReceptor = B.RFC,    
--    @NombreReceptor = B.Nombre,    
--        @DomicilioFiscalReceptor = CASE B.RFC WHEN 'XAXX010101000' THEN A.LugarExpedicion WHEN 'XEXX010101000' THEN A.LugarExpedicion ELSE B.CodigoPostal END,    
--    @ResidenciaFiscal = CASE WHEN ISNULL(fr.Extranjero, 0) = 1 THEN P.ClavePais ELSE NULL END,    
--    @NumRegIdTrib = CASE WHEN ISNULL(fr.Extranjero, 0) = 1 THEN C.NumRegIdTrib ELSE NULL END,    
--        @RegimenFiscalReceptor = NULLIF(RTRIM(fr.FiscalRegimen), ''),    
--    @Folio = A.Folio,    
--    @Serie = ISNULL(A.Serie, ''),    
--    @Modulo = A.Modulo,    
--    @DecimalesP = ISNULL(s.Decimales, 2),    
--    @MonedaP = A.ClaveMoneda,    
--    @TipoCambioP = ROUND(A.TipoCambio,6),    
--        @AgenteACuentaTerceros = ISNULL(a.AgenteACuentaTerceros, ''),    
--        @RfcACuentaTerceros = ISNULL(g.RFC, ''),    
--        @NombreACuentaTerceros = ISNULL(g.Nombre, ''),    
--        @RegimenFiscalACuentaTerceros = ISNULL(g.FiscalRegimen, ''),    
--        @DomicilioFiscalACuentaTerceros = ISNULL(g.CodigoPostal, ''),    
--  @AjustarMontoTotalPagos = A.AjustarMontoTotalPagos    
--  FROM CFDICobroParcial A    
--   INNER JOIN Cte B ON A.Cliente = B.Cliente    
--   LEFT JOIN CteCFD C ON C.Cliente = B.Cliente    
--   LEFT JOIN SATPais P ON B.Pais = P.Descripcion    
--   LEFT JOIN FiscalRegimen AS fr ON fr.FiscalRegimen = B.FiscalRegimen    
--   LEFT JOIN SATMoneda AS s ON s.Clave = A.ClaveMoneda    
--      LEFT OUTER JOIN Agente g ON A.AgenteACuentaTerceros = g.Agente    
--  WHERE A.ID = @ID AND A.Estacion = @Estacion    
--  SELECT @Verano = s.DifHorariaVerano , @Invierno = s.DifHorariaInvierno    
--   FROM Sucursal AS s    
--  WHERE s.Sucursal = @Sucursal    
--  SET @Conceptos = ''    
--  SET @XMLImpuestosDoc = ''    
--  SET @XMLPago = ''    
--  SET @Ok = NULL    
--  SET @OkRef = NULL    
--  SET @Relacionado = 0    
--  SET @TieneAjusteNegativo = 0    
--  DELETE FROM @DocRelacionadoTimbrado    
--  EXEC spAntesTimbrarCobro @ID,@Modulo,@Empresa,@Estacion,@Ok OUTPUT,@OkRef OUTPUT    
--  IF EXISTS (SELECT * FROM CFDICobroFactorajePaso AS cfp WHERE cfp.ModuloID=@ID AND cfp.Modulo=@Modulo AND cfp.Estacion=@Estacion AND cfp.Empresa=@Empresa)    
--  BEGIN    
--   DECLARE InsertFactoraje CURSOR LOCAL FOR    
--    SELECT cfp.ModuloFactorajeID,cfp.Modulo,cfp.ModuloID,cd.Aplica,cd.AplicaID,cfp.ModuloFactoraje,C.Mov,C.MovID,cfp.Mov,cfp.MovID    
--      FROM CFDICobroFactorajePaso AS cfp    
--      JOIN CxcD AS cd ON cd.ID=cfp.ModuloFactorajeID    
--      JOIN  Cxc AS c ON C.ID=CD.ID    
--    WHERE cfp.ModuloID=@ID    
--     AND NULLIF (cd.Aplicaid,'') IS NOT  NULL    
--     AND NULLIF (cd.Aplica,'') IS NOT  NULL    
--     AND cfp.Estacion=@Estacion    
--     AND cfp.Empresa=@Empresa    
--   OPEN InsertFactoraje    
--   FETCH NEXT FROM InsertFactoraje INTO  @FcID,@FModulo,@FModuloID,@FMov,@FMovID,@FModuloFactoraje,@FAplica,@FAplicaID,@FDMov,@FDMovID    
--   WHILE @@FETCH_STATUS = 0    
--   BEGIN    
--    DELETE FROM @Movimientos    
--    ;WITH Movimientos    
--    AS (    
--     SELECT OID, OModulo, OMov, OMovID, DID, DModulo, DMov, DMovID,  1 AS Nivel    
--     FROM dbo.movflujo    
--     WHERE DID = @FcID AND DModulo = 'CXC' AND OMov = @FMov AND OMovID = @FMovID AND Empresa = @Empresa AND Cancelado = 0    
--     UNION ALL    
--     SELECT e.OID, e.OModulo, e.OMov, e.OMovID, e.DID, e.DModulo, e.DMov, e.DMovID, 1 + Movimientos.Nivel    
--     FROM dbo.movflujo AS e    
--      INNER JOIN Movimientos ON e.DID = Movimientos.OID AND e.DModulo = Movimientos.OModulo AND e.Cancelado = 0    
--    )    
--    INSERT @Movimientos    
--    SELECT OID, OModulo, OMov, OMovID, DID, DModulo, DMov, DMovID, Nivel, mt.Clave    
--    FROM Movimientos AS m    
--     INNER JOIN MovTipo AS mt ON m.OModulo = mt.Modulo AND m.OMov = mt.Mov    
--    ORDER BY Nivel DESC    
--    SELECT TOP 1 @FVentaID = OID, @MovFactorajeD = OMov, @MovFactorajeIDD = OMovID, @ClaveOFactoraje = Clave    
--     FROM   @Movimientos    
--    WHERE Clave IN ('VTAS.F','CXC.F')    
--    ORDER BY NIVEL DESC    
--    IF @ClaveOFactoraje = 'CXC.F'    
--     SET @SaldoInicialFactoraje = 1    
--    ELSE    
--     SET @SaldoInicialFactoraje = 0    
--    SELECT @AplicaFactor=1,@MontoFactor = cd.Importe    
--     FROM Cxc AS c    
--    JOIN CxcD as cd on c.ID=cd.ID    
--    WHERE c.ID=@FcID    
--     and cd.Aplica=@FMov    
--     and cd.AplicaID=@FMovID    
--    INSERT  CFDICobroVenta (Estacion, Empresa, IDMovimiento,IDCobro,IDVenta,AplicaFactor,MontoFactor,Factoraje, EsSaldoInicial)    
--    SELECT     @Estacion,@Empresa,@ID,   @FcID, @FVentaID,@AplicaFactor,@MontoFactor,1, @SaldoInicialFactoraje    
--    INSERT @DatosFactoraje(Modulo, ModuloID,   Mov,   MovID,   ModuloFactoraje,   ModuloFactorajeID, MovFactoraje,MovFactorajeID,Empresa, Cliente,MovFactorajeD, MovFactorajeIDD)    
--    SELECT       @FModulo,@FModuloID,@FDMov,@FDMovID, @FModuloFactoraje, @FcID    ,@FAplica   ,@FAplicaID  ,@Empresa, @Cliente,@MovFactorajeD,@MovFactorajeIDD    
--    FETCH NEXT FROM InsertFactoraje INTO  @FcID,@FModulo,@FModuloID,@FMov,@FMovID,@FModuloFactoraje,@FAplica,@FAplicaID,@FDMov,@FDMovID    
-- END    
--   CLOSE InsertFactoraje    
--   DEALLOCATE InsertFactoraje    
--  END     
--  DECLARE cCxc CURSOR FOR    
--   SELECT DISTINCT CASE WHEN @Modulo ='DIN' AND IDAplicaCobro IS NOT NULL  THEN IDAplicaCobro ELSE IDCobro  END ,IDCobro, IDMovimiento    
--   FROM CFDICobroVenta    
--   WHERE IDMovimiento = @ID AND Estacion = @Estacion AND Empresa = @Empresa    
--  OPEN cCxc    
--  FETCH NEXT FROM cCxc INTO @IdCxc, @IdCxcDIN, @IDMov    
--  WHILE @@FETCH_STATUS = 0    
--  BEGIN    
--      DELETE FROM @TrasladoP    
--      DELETE FROM @RetencionP    
--   IF @Modulo='DIN' AND EXISTS (SELECT DISTINCT  IDCobro FROM CFDICobroVenta WHERE IDAplicaCobro = @IDcxc AND Estacion = @Estacion AND Empresa = @Empresa)    
--   BEGIN    
--    SELECT @IdCxcAntes= IDCobro    
--     FROM CFDICobroVenta    
--    WHERE IDAplicaCobro = @IDcxc AND Estacion = @Estacion AND Empresa = @Empresa    
--   END    
--    SELECT @AlmacenarCFD= cc.Almacenar    
--   FROM CteCFD AS cc    
--    WHERE cc.Cliente=@Cliente     
--    IF @AlmacenarCFD = 1    
--     BEGIN    
--      SELECT  @AlmacenarRuta= cc.AlmacenarRuta,    
--      @NomArchivo=cc.Nombre    
--        FROM CteCFD AS cc    
--       WHERE cc.Cliente=@Cliente    
--     END    
--    ELSE    
--   BEGIN    
--     SELECT @AlmacenarRuta = AlmacenarRuta,    
--           @NomArchivo = Nombre    
--       FROM EmpresaCFD    
--      WHERE Empresa = @Empresa     
--   END     
--    SELECT @RutaAnsiUTF = RutaANSIToUTF,    
--         @noCertificado = noCertificado,    
--         @MontoMovREP = MontoMovREP    
--      FROM EmpresaCFD    
--      WHERE Empresa = @Empresa    
--   SET @DocRelacionado = ''    
--   SET @FormaPagoCobro = NULL    
--   SET @Bancarizado = NULL    
--   SET @Redondeo = 0    
--   SET @MovClave = NULL    
--   SET @PagadoTotal = 0    
--   SET @FactorajeE = 0    
--   DELETE FROM @FacturasRelacionadas    
--   SELECT @MovClaveEsNeteo= mt.Clave    
--   FROM Cxc AS c    
--    INNER JOIN MovTipo AS mt ON mt.Mov = c.Mov AND mt.Modulo = 'CXC'    
--   WHERE id = @IdCxc    
--   IF EXISTS(SELECT * FROM VersionLista WHERE Nombre = 'FlujoEspecialDocumentos' AND Valor = 'Si')    
--    SELECT TOP 1 @MovClave=Clave    
--    FROM MovTipo AS mt    
--    JOIN MovFlujo AS mf on mt.Mov=mf.OMov    
--    WHERE mf.OID=@IdCxc    
--    AND mt.Modulo='CXC'    
--    AND mf.DModulo='CXC'    
--    AND mf.Cancelado=0    
--    AND mf.OModulo='CXC'    
--   ELSE    
--    SELECT TOP 1 @MovClave=Clave    
--    FROM MovTipo AS mt    
--    JOIN MovFlujo AS mf on mt.Mov=mf.OMov    
--    WHERE mf.OID=@IdCxc    
--    AND mt.Modulo='CXC'    
--    AND mf.DModulo='CXC'    
--    AND mf.Cancelado=0    
--   IF @MovClave NOT IN ('CXC.DP')    
--    SELECT TOP 1 @MovClave=Clave    
--    FROM MovTipo AS mt    
--     JOIN MovFlujo AS mf on mt.Mov=mf.OMov    
--    WHERE mf.DID=@IdCxc    
--     AND mt.Modulo='CXC'    
--     AND mf.DModulo='CXC'    
--     AND mf.Cancelado=0    
--  IF EXISTS (SELECT * FROM CFDICobroFactorajePaso AS cfp WHERE cfp.ModuloFactorajeID=@IdCxc AND cfp.Estacion=@Estacion AND cfp.Empresa=@Empresa)    
--   SELECT @FormaPagoCobro = '17', @Bancarizado = 0    
--   IF @MovClaveEsNeteo = 'CXC.NET'    
--   SELECT @FormaPagoCobro = '17', @Bancarizado = 0    
--  ELSE    
--   SELECT @FormaPagoCobro = FP.ClaveSAT, @Bancarizado = SFP.Bancarizado    
--     FROM CFDICobroVenta AS cv    
--    JOIN FormaPago AS FP ON FP.FormaPago = cv.FormaPago     
--    LEFT JOIN SATFormaPago AS SFP ON SFP.Clave = FP.ClaveSAT    
--    WHERE cv.IDCobro = @IdCxc    
--  DECLARE CDoctoRelacionado CURSOR FOR    
--   SELECT IDVenta,  EsSaldoInicial,Factoraje, MontoFactor    
--    FROM CFDICobroVenta    
--   WHERE IDMovimiento = @ID AND    
--    CASE WHEN @Modulo='DIN' AND IDAplicaCobro IS NOT NULL THEN  IDAplicaCobro ELSE IDCobro END = @IdCxc    
--    AND Estacion = @Estacion AND Empresa = @Empresa    
--      ORDER BY Factoraje    
--  OPEN CDoctoRelacionado    
--  FETCH NEXT FROM CDoctoRelacionado INTO @IDVenta, @EsSaldoinicial, @FactorajeE, @MontoFactor    
--  WHILE @@FETCH_STATUS = 0    
--  BEGIN    
--   SET @MontoTotal = NULL    
--   SET @MontoPagado = NULL    
--   SET @SaldoAnterior = NULL    
--   SET @SaldoInsoluto = NULL    
--   SET @SaldoPendiente = NULL    
--   SET @NumParcialidad = 0    
--   SET @MetodoDePagoDR = NULL    
--   SET @MonedaDocto = NULL    
--   SET @UUIDDR = NULL    
--   SET @SerieDR = NULL    
--   SET @FolioDR  = NULL    
--   SET @TipoCambioDR  = NULL    
--   DELETE FROM @PagosFactura    
--   DELETE FROM @PagosAplica    
--   IF EXISTS (SELECT * FROM CFDICobroVenta WHERE IDMovimiento = @ID AND Factoraje=1 AND Empresa = @Empresa AND Estacion = @Estacion)    
--   BEGIN    
--    SELECT @MonedaP = m.Clave, @TipoCambioP = c.TipoCambio    
--     FROM   CXC      AS c    
--       INNER JOIN Mon  AS m ON c.Moneda = m.Moneda    
--       INNER JOIN SATMoneda AS s ON m.Clave = s.Clave    
--    WHERE ID = @IdCxc    
--   END    
--   IF  @EsSaldoinicial = 0    
--   BEGIN    
--    SET @ModuloRelacionado = 'VTAS'    
--    SELECT @MontoTotal = (v.Importe - (v.Importe * (isnull(v.DescuentoGlobal, 0)/100)) - ISNULL(v.Retencion, 0) + ISNULL(v.Impuestos, 0)) - ISNULL(AnticiposFacturados, 0),    
--          @MetodoDePagoDR = mp.IDClave, @MonedaDocto = ISNULL(E.Clave, 'MXN'), @DecimalesDR = ISNULL(s.Decimales, 2)    
--    FROM Venta AS v    
--     LEFT JOIN Condicion AS c ON c.Condicion = v.Condicion    
--     LEFT JOIN SATMetodoPago AS mp ON mp.Clave = C.CFD_metodoDePago    
--     LEFT JOIN Mon E ON v.Moneda = E.Moneda    
--     LEFT JOIN SATMoneda AS s ON s.Clave = E.Clave    
--    WHERE v.ID = @IDVenta    
--    SELECT @UUIDDR = UUID, @SerieDR = Serie, @FolioDR = Folio    
--    FROM CFD    
--    WHERE Modulo = 'VTAS' AND ModuloID = @IDVenta AND Empresa = @Empresa AND UUID IS NOT NULL AND ISNULL(Cancelado, 0) = 0    
--   END -- IF  @EsSaldoinicial = 0    
--      ELSE    
--   BEGIN    
--    SET @ModuloRelacionado = 'CXC'    
--    SELECT @ClaveDetalle=mt.Clave, @MontoTotal = (Cxc.Importe + ISNULL(Cxc.Impuestos, 0) - ISNULL(Cxc.Retencion, 0) - ISNULL(Cxc.Retencion2, 0) - ISNULL(Cxc.Retencion3, 0)), @MetodoDePagoDR = mp.IDClave, @MonedaDocto = ISNULL(E.Clave, 'MXN'), @DecimalesDR = ISNULL(s.Decimales, 2), @MovDRCxc = Cxc.Mov, @FolioDRCXC = Cxc.MovID    
--    FROM Cxc    
--     LEFT JOIN Condicion AS c ON c.Condicion = Cxc.Condicion    
--     LEFT JOIN SATMetodoPago AS mp ON mp.Clave = c.CFD_metodoDePago    
--     LEFT JOIN Mon E ON CXC.Moneda = E.Moneda    
--     LEFT JOIN SATMoneda AS s ON s.Clave = E.Clave    
--     LEFT JOIN MovTipo AS mt ON mt.Mov=cxc.Mov AND mt.Modulo='CXC'    
--    WHERE Cxc.ID = @IDVenta AND Cxc.Empresa = @Empresa    
--    SELECT @UUIDDR = cdr.UUID, @SerieDR = cdr.Serie, @FolioDR = cdr.Folio, @NumParcialidad = ISNULL(cdr.NumParcialidad, 0)    
--    FROM CFDICxcDocRelacionado AS cdr    
--    WHERE cdr.ID = @IDVenta AND cdr.Empresa = @Empresa    
--    IF (@UUIDDR IS NULL AND @FolioDR IS NULL)          
--      SELECT @UUIDDR = cdr.UUID, @SerieDR = cdr.Serie, @FolioDR = cdr.Folio, @NumParcialidad = 0    
--      FROM CFD AS cdr    
--      WHERE cdr.Modulo='CXC' AND cdr.ModuloID = @IDVenta AND cdr.Empresa = @Empresa    
--    IF NULLIF(@UUIDDR,'') IS NULL    
--    BEGIN    
--     SELECT @Ok=55270,@OkRef= 'No Existe el UUID correspondiente al movimiento '+CONVERT(VARCHAR(20),RTRIM(@MovDRCXC))+' '+CONVERT(VARCHAR(20),RTRIM(@FolioDRCXC))    
--    END    
--        ELSE        
--    IF  EXISTS (SELECT * FROM @FacturasRelacionadas WHERE UUID = @UUIDDR AND Factoraje = @FactorajeE)    
--    BEGIN    
--     SELECT @Ok=ml.Mensaje,@OkRef= 'UUID'+CHAR(10)+ml.Descripcion    
--      FROM MensajeLista AS ml    
--     WHERE ml.Mensaje =55270    
--    END    
--   END -- IF  @EsSaldoinicial = 1    
--   IF NOT EXISTS (SELECT * FROM @FacturasRelacionadas WHERE UUID = @UUIDDR AND Factoraje = @FactorajeE)    
--   BEGIN    
--    SELECT @MontoTotal = ROUND(@MontoTotal, @DecimalesDR, 0)    
--    SELECT @TipoCambioDR = ROUND(c.ClienteTipoCambio, 6, 0)    
--    FROM Cxc AS c    
--    WHERE ID = CASE WHEN @Modulo='CXC' THEN @IDMov ELSE @IdCxc END    
--    EXEC spCFDICobroParcialMovimientosCxcMontos @Estacion,@Empresa,@ID,@IdCxc,@IDVenta,@UUIDDR,@ModuloRelacionado,@MontoTotal,@MonedaDocto,@DecimalesDR,@Modulo,@TipoCambioDR,@TipoCambioP,@MonedaP,@TipoCFD,@NumParcialidad, @EsSaldoinicial    
--    SELECT @NumParcialidad = NumParcialidad, @MontoPagado = ImpPagado, @SaldoAnterior = ImpSaldoAnt, @SaldoPendiente =  ImpSaldoInsoluto , @Factoraje = Factoraje, @TieneAjusteNegativo = TieneAjusteNegativo    
--     FROM MontosXMLFactura    
--    WHERE IDVenta=@IDVenta    
--    AND Estacion = @Estacion    
--    AND Empresa = @Empresa    
--     IF EXISTS (SELECT  * FROM @PagosFacturaCobro WHERE UUID=@UUIDDR )    
--    BEGIN    
--     IF EXISTS( SELECT  * FROM CFDICobroVenta AS cv WHERE cv.IDMovimiento = @ID AND cv.Factoraje = 0 AND cv.Estacion = @Estacion AND cv.Empresa = @Empresa AND cv.IDVenta= @IDVenta AND Doc = 1  )    
--     BEGIN    
--      SELECT @MontoPagado  =  ImpPagado,    
--          @SaldoAnterior  = @SaldoAnterior - SUM ( pfc.MontoPagado),    
--          @SaldoPendiente = ROUND (@SaldoAnterior,2)- ROUND( @MontoPagado,2)    
--       FROM MontosXMLFactura AS  mxf    
--       JOIN @PagosFacturaCobro AS pfc ON mxf.IDVenta=pfc.IDVenta    
--        WHERE mxf.IDVenta = @IDVenta    
--        AND Estacion = @Estacion    
--        AND Empresa = @Empresa    
--       GROUP BY mxf.ImpSaldoInsoluto, mxf.ImpPagado    
--     END    
--     IF    EXISTS( SELECT  * FROM CFDICobroVenta AS cv WHERE cv.IDMovimiento = @ID AND cv.Factoraje = 1 AND cv.Estacion = @Estacion AND cv.Empresa = @Empresa AND cv.IDVenta= @IDVenta )    
--     BEGIN    
--      SELECT @MontoPagado  = @MontoFactor,--ImpPagado,    
--         @SaldoAnterior  = @SaldoAnterior - SUM ( pfc.MontoPagado),    
--         @SaldoPendiente = ROUND (@SaldoAnterior,2)- ROUND( @MontoPagado,2),    
--         @NumParcialidad = COUNT(mxf.NumParcialidad) + 1    
--       FROM MontosXMLFactura AS  mxf    
--       JOIN @PagosFacturaCobro AS pfc ON mxf.IDVenta=pfc.IDVenta    
--      WHERE mxf.IDVenta = @IDVenta    
--       AND Estacion = @Estacion    
--       AND Empresa = @Empresa    
--      GROUP BY mxf.ImpSaldoInsoluto, mxf.ImpPagado    
--     END     
--    END      
--        IF @Modulo = 'DIN' AND @FactorajeE = 1    
--          SELECT @ModuloTR = 'CXC', @IDTR = @IdCxc    
--        ELSE    
--          SELECT @ModuloTR = @Modulo, @IDTR = @ID    
--        DELETE FROM #TempImpuestoDR    
--        DECLARE crTempImpuesto CURSOR FOR    
--        SELECT IDVenta, MontoFactor, Factoraje    
--          FROM CFDICobroVenta    
--         WHERE IDMovimiento = @ID    
--           AND CASE WHEN @Modulo='DIN' AND IDAplicaCobro IS NOT NULL THEN IDAplicaCobro ELSE IDCobro END = @IdCxc    
--           AND Estacion = @Estacion AND Empresa = @Empresa    
--        OPEN crTempImpuesto    
--        FETCH NEXT FROM crTempImpuesto INTO @IDVenta2, @MontoFactor2, @FactorajeE2    
--        WHILE @@FETCH_STATUS = 0    
--        BEGIN    
--          SELECT @SumaMonto = 0    
--          IF @Modulo = 'DIN' OR @FactorajeE2 = 1    
--            SELECT @SumaMonto = @MontoFactor2    
--          ELSE    
--            SELECT @SumaMonto = SUM(MontoFactor)    
--              FROM CFDICobroVenta    
--             WHERE IDMovimiento = @ID    
--             AND Estacion = @Estacion AND Empresa = @Empresa AND IDVenta = @IDVenta2    
--          INSERT INTO #TempImpuestoDR(    
--                 Modulo, ModuloID,  IDCobro,  IDVenta, Impuesto1, Impuesto2, Impuesto3, Impuesto5, Importe1,    
--                 Importe2,                           Importe3,                           Importe5,                           SubTotal,                           Retencion1, Retencion2, Retencion3, Excento1)    
--          SELECT Modulo, ModuloID, @IdCxc, @IDVenta2, Impuesto1, Impuesto2, Impuesto3, Impuesto5, Importe1*(@MontoFactor2/@SumaMonto),    
--                 Importe2*(@MontoFactor2/@SumaMonto), Importe3*(@MontoFactor2/@SumaMonto), Importe5*(@MontoFactor2/@SumaMonto), SubTotal*(@MontoFactor2/@SumaMonto), Retencion1, Retencion2, Retencion3, Excento1    
--            FROM MovImpuesto    
--           WHERE Modulo = @ModuloTR    
--             AND ModuloID = @IDTR    
--             AND OrigenModulo = @ModuloRelacionado    
--             AND OrigenModuloID = @IDVenta2    
  
  
  
--    DELETE FROM #TempImpuestoDR    
--   WHERE (Impuesto1 <> 0 OR Impuesto1 <> 2 OR Impuesto3 <> 0  )    
--   AND Importe1 = 0    
--   AND Importe3 = 0    
--   AND Importe1 = 0    
--   AND Excento1 = 0    
--   AND SubTotal = 0    
--          FETCH NEXT FROM crTempImpuesto INTO @IDVenta2, @MontoFactor2, @FactorajeE2    
--        END    
--        CLOSE crTempImpuesto    
--        DEALLOCATE crTempImpuesto    
    
    
--  --INSERT INTO MALALADOS  
--  --  SELECT * FROM #TempImpuestoDR  
    
--  --- PRUEBA   SELECT * FROM AVENGER  
  
-- --- SELECT * FROM MALALADOS  
--  --- SELECT   
  
--  IF @MonedaP = @MonedaDocto    
--   SELECT @DecimalesTrasladoP = 2    
--  ELSE    
--   SELECT @DecimalesTrasladoP = 2--4    
--        SELECT @EquivalenciaDR = CASE WHEN @MonedaP = @MonedaDocto THEN '1' ELSE ROUND(@TipoCambioP/@TipoCambioDR, 10) END    
--  DELETE FROM @TrasladoDR    
--        INSERT INTO @TrasladoDR(    
--                UUID,   TipoFactorDR, TasaOCuotaDR,    ImpuestoDR, ImporteDR,     BaseDR,                                                 NumParcialidad)    
--        SELECT @UUIDDR, 'Tasa',       Impuesto1/100.0, '002',     Round( ROUND(SUM(SubTotal+ISNULL(Importe2, 0)+ISNULL(Importe3, 0)),@DecimalesTrasladoP)*(Impuesto1/100.0)* @EquivalenciaDR ,@DecimalesTrasladoP), ROUND ( ROUND(SUM(SubTotal+ISNULL(Importe2,0)+ISNULL(Importe3, 0)),@DecimalesTrasladoP)* @EquivalenciaDR, @DecimalesTrasladoP), @NumParcialidad    
--          FROM #TempImpuestoDR    
--         WHERE Modulo = @ModuloTR    
--           AND ModuloID = @IDTR    
--           AND IDCobro = @IdCxc    
--           AND IDVenta = @IDVenta    
--           AND Impuesto1 >= 0    
--        AND Excento1 = 0    
--         GROUP BY Impuesto1/100.0    
--         UNION    
--          SELECT @UUIDDR, 'Tasa', Impuesto2/100.0, '003', ROUND(ROUND(SUM(ISNULL(Importe2, 0)), 4) *@EquivalenciaDR, @DecimalesTrasladoP), ROUND(ROUND(SUM(SubTotal), 4)*@EquivalenciaDR, @DecimalesTrasladoP), @NumParcialidad    
--          FROM #TempImpuestoDR    
--         WHERE Modulo = @ModuloTR    
--           AND ModuloID = @IDTR    
--           AND IDCobro = @IdCxc    
--           AND IDVenta = @IDVenta    
--           AND Impuesto2 > 0    
--     AND Importe2  > 0    
--         GROUP BY Impuesto2/100.0    
--         UNION    
--        SELECT @UUIDDR, 'Cuota', Impuesto3, '003', ROUND(ROUND(ROUND(SUM(Importe3/Impuesto3), @DecimalesTrasladoP)*@EquivalenciaDR, @DecimalesTrasladoP) * Impuesto3, @DecimalesTrasladoP) , ROUND(ROUND(SUM(Importe3/Impuesto3), @DecimalesTrasladoP)*@EquivalenciaDR, @DecimalesTrasladoP), @NumParcialidad    
--          FROM #TempImpuestoDR    
--         WHERE Modulo = @ModuloTR    
--           AND ModuloID = @IDTR    
--           AND IDCobro = @IdCxc    
--           AND IDVenta = @IDVenta    
--           AND Impuesto3 > 0    
--     AND Importe3  > 0    
--         GROUP BY Impuesto3    
--         UNION    
--        SELECT @UUIDDR, 'Exento', NULL, '002', NULL, ROUND(ROUND(SUM(ISNULL(SubTotal, 0)), 6)*@EquivalenciaDR, @DecimalesTrasladoP), @NumParcialidad    
--          FROM #TempImpuestoDR    
--         WHERE Modulo = @ModuloTR    
--           AND ModuloID = @IDTR    
--           AND IDCobro = @IdCxc    
--           AND IDVenta = @IDVenta    
--           AND Impuesto1 = 0    
--           AND Excento1 = 1    
--        DELETE FROM @RetencionDR    
--        INSERT INTO @RetencionDR(UUID, TipoFactorDR, TasaOCuotaDR, ImpuestoDR, ImporteDR, BaseDR, NumParcialidad) -- ISR    
--        SELECT @UUIDDR, 'Tasa', Retencion1/100.0, '001', ROUND(ROUND(SUM(SubTotal*Retencion1/100.0), 4)*@EquivalenciaDR, @DecimalesTrasladoP), ROUND(ROUND(SUM(SubTotal), 4)*@EquivalenciaDR, @DecimalesTrasladoP), @NumParcialidad    
--          FROM #TempImpuestoDR    
--          WHERE Modulo = @ModuloTR    
--            AND ModuloID = @IDTR    
--            AND IDCobro = @IdCxc    
--            AND IDVenta = @IDVenta    
--            AND SubTotal*Retencion1> 0    
--          GROUP BY Retencion1/100.0    
--          UNION    
--        SELECT @UUIDDR, 'Tasa', Retencion2/100.0, '002', ROUND(ROUND(SUM(SubTotal*Retencion2/100.0), 4)*@EquivalenciaDR, @DecimalesTrasladoP), ROUND(ROUND(SUM(SubTotal), 4)*@EquivalenciaDR, @DecimalesTrasladoP), @NumParcialidad -- IVA    
--          FROM #TempImpuestoDR    
--          WHERE Modulo = @ModuloTR    
--           AND ModuloID = @IDTR    
--            AND IDCobro = @IdCxc    
--            AND IDVenta = @IDVenta    
--            AND SubTotal*Retencion2 > 0    
--          GROUP BY Retencion2/100.0    
--  SELECT @ObjetoImpDR  = dbo.fnCobroParcialObjetoImp(@IDVenta, @EsSaldoinicial)    
  
--  --INSERT INTO AVENGER  
--  --SELECT * FROM @TrasladoDR  
  
--        INSERT INTO @TrasladoP(Modulo, ModuloID, UUID, TipoFactorP, TasaOCuotaP, ImpuestoP, ImporteP, BaseP, NumParcialidad, ImportePMN, BasePMN, ObjetoImpDR)    
--        SELECT @ModuloTR, @IDTR, @UUIDDR, TipoFactorDR, TasaOCuotaDR, ImpuestoDR, ImporteDR/@EquivalenciaDR, BaseDR/@EquivalenciaDR, @NumParcialidad,    
    
--               ROUND(ImporteDR/@EquivalenciaDR,2),--*CASE WHEN @MonedaP = @MonedaDocto THEN @TipoCambioP ELSE 1 END,    
--               ROUND(BaseDR/@EquivalenciaDR, 2),--*CASE WHEN @MonedaP = @MonedaDocto THEN @TipoCambioP ELSE 1 END    
--               @ObjetoImpDR    
--          FROM @TrasladoDR    
--         WHERE (TasaOCuotaDR IS NOT NULL OR BaseDR IS NOT NULL)    
--        INSERT INTO @RetencionP(Modulo, ModuloID, UUID, TipoFactorP, TasaOCuotaP, ImpuestoP, ImporteP, BaseP, NumParcialidad, ImportePMN, BasePMN)    
--        SELECT @ModuloTR, @IDTR, @UUIDDR, TipoFactorDR, TasaOCuotaDR, ImpuestoDR, ImporteDR/@EquivalenciaDR, BaseDR/@EquivalenciaDR, @NumParcialidad,    
--               ROUND(ImporteDR/@EquivalenciaDR,2),--*CASE WHEN @MonedaP = @MonedaDocto THEN @TipoCambioP ELSE 1 END,    
--               ROUND(BaseDR/@EquivalenciaDR, 2)--*CASE WHEN @MonedaP = @MonedaDocto THEN @TipoCambioP ELSE 1 END    
--          FROM @RetencionDR    
--         WHERE TasaOCuotaDR IS NOT NULL    
--   INSERT INTO INFINITY   
--   SELECT * FROM @TrasladoP  
--  -- SELECT * INTO INFINITY FROM @TrasladoP  
  
--  IF @MonedaDocto = 'MXN' AND @monedaP <> 'MXN'    
--  BEGIN    
--          INSERT INTO @TrasladoTotal(Modulo, ModuloID, UUID, TipoFactorP, TasaOCuotaP, ImpuestoP, ImporteP, BaseP, NumParcialidad, ImportePMN, BasePMN, IDCobro, ObjetoImpDR)    
--          SELECT @ModuloTR, @IDTR, @UUIDDR, TipoFactorDR, TasaOCuotaDR, ImpuestoDR, ImporteDR, BaseDR, @NumParcialidad,    
--                 (ImporteDR/@EquivalenciaDR)*CASE WHEN @MonedaP = @MonedaDocto THEN @TipoCambioP ELSE 1 END,    
--                 (BaseDR/@EquivalenciaDR)*CASE WHEN @MonedaP = @MonedaDocto THEN @TipoCambioP ELSE 1 END,    
--                 @IdCxc, @ObjetoImpDR    
--            FROM @TrasladoDR    
--           WHERE (TasaOCuotaDR IS NOT NULL OR BaseDR IS NOT NULL)    
--          INSERT INTO @RetencionTotal(Modulo, ModuloID, UUID, TipoFactorP, TasaOCuotaP, ImpuestoP, ImporteP, BaseP, NumParcialidad, ImportePMN, BasePMN, IDCobro)    
--          SELECT @ModuloTR, @IDTR, @UUIDDR, TipoFactorDR, TasaOCuotaDR, ImpuestoDR, ImporteDR, BaseDR, @NumParcialidad,    
--                 (ImporteDR/@EquivalenciaDR)*CASE WHEN @MonedaP = @MonedaDocto THEN @TipoCambioP ELSE 1 END,    
--                 (BaseDR/@EquivalenciaDR)*CASE WHEN @MonedaP = @MonedaDocto THEN @TipoCambioP ELSE 1 END,    
--                 @IdCxc    
--            FROM @RetencionDR    
--           WHERE TasaOCuotaDR IS NOT NULL    
    
  
--     END ELSE    
--  IF @MonedaDocto <> 'MXN' AND @monedaP <> 'MXN'    
--  BEGIN    
--   INSERT INTO @TrasladoTotal(Modulo, ModuloID, UUID, TipoFactorP, TasaOCuotaP, ImpuestoP, ImporteP, BaseP, NumParcialidad, ImportePMN, BasePMN, IDCobro, ObjetoImpDR)    
--   SELECT @ModuloTR, @IDTR, @UUIDDR, TipoFactorDR, TasaOCuotaDR, ImpuestoDR, ROUND((ImporteDR / @EquivalenciaDR), 6) * @TipoCambioP, ROUND((BaseDR / @EquivalenciaDR), 6) * @TipoCambioP, @NumParcialidad,    
--                 (ImporteDR/@EquivalenciaDR)*CASE WHEN @MonedaP = @MonedaDocto THEN @TipoCambioP ELSE 1 END,    
--                 (BaseDR/@EquivalenciaDR)*CASE WHEN @MonedaP = @MonedaDocto THEN @TipoCambioP ELSE 1 END,    
--                 @IdCxc, @ObjetoImpDR    
--             FROM @TrasladoDR    
--   WHERE (TasaOCuotaDR IS NOT NULL OR BaseDR IS NOT NULL)    
--   INSERT INTO @RetencionTotal(Modulo, ModuloID, UUID, TipoFactorP, TasaOCuotaP, ImpuestoP, ImporteP, BaseP, NumParcialidad, ImportePMN, BasePMN, IDCobro)    
--   SELECT @ModuloTR, @IDTR, @UUIDDR, TipoFactorDR, TasaOCuotaDR, ImpuestoDR, ImporteDR*@TipoCambioP, BaseDR*@TipoCambioP, @NumParcialidad,    
--                 (ImporteDR/@EquivalenciaDR)*CASE WHEN @MonedaP = @MonedaDocto THEN @TipoCambioP ELSE 1 END,    
--                 (BaseDR/@EquivalenciaDR)*CASE WHEN @MonedaP = @MonedaDocto THEN @TipoCambioP ELSE 1 END,    
--                 @IdCxc    
--             FROM @RetencionDR    
--   WHERE TasaOCuotaDR IS NOT NULL    
--     END ELSE    
--  BEGIN    
--          INSERT INTO @TrasladoTotal(Modulo, ModuloID, UUID, TipoFactorP, TasaOCuotaP, ImpuestoP, ImporteP, BaseP, NumParcialidad, ImportePMN, BasePMN, IDCobro, ObjetoImpDR)    
--          SELECT @ModuloTR, @IDTR, @UUIDDR, TipoFactorDR, TasaOCuotaDR, ImpuestoDR, ImporteDR/@EquivalenciaDR, BaseDR/@EquivalenciaDR, @NumParcialidad,    
--                 (ImporteDR/@EquivalenciaDR),--*CASE WHEN @MonedaP = @MonedaDocto THEN @TipoCambioP ELSE 1 END,    
--                 (BaseDR/@EquivalenciaDR),--*CASE WHEN @MonedaP = @MonedaDocto THEN @TipoCambioP ELSE 1 END,    
--                 @IdCxc, @ObjetoImpDR    
--            FROM @TrasladoDR    
--           WHERE (TasaOCuotaDR IS NOT NULL OR BaseDR IS NOT NULL)    
--          INSERT INTO @RetencionTotal(Modulo, ModuloID, UUID, TipoFactorP, TasaOCuotaP, ImpuestoP, ImporteP, BaseP, NumParcialidad, ImportePMN, BasePMN, IDCobro)    
--          SELECT @ModuloTR, @IDTR, @UUIDDR, TipoFactorDR, TasaOCuotaDR, ImpuestoDR, ImporteDR/@EquivalenciaDR, BaseDR/@EquivalenciaDR, @NumParcialidad,    
--                 ImporteDR/@EquivalenciaDR,--*CASE WHEN @MonedaP = @MonedaDocto THEN @TipoCambioP ELSE 1 END,    
--                 BaseDR/@EquivalenciaDR,--*CASE WHEN @MonedaP = @MonedaDocto THEN @TipoCambioP ELSE 1 END    
--                 @IdCxc    
--            FROM @RetencionDR    
--           WHERE TasaOCuotaDR IS NOT NULL    
--  END    
--        SELECT @XMLTrasladoDR = '', @XMLRetencionDR = ''    
--        ;WITH XMLNAMESPACES ('http://www.sat.gob.mx/Pagos20' AS pago20)    
--        SELECT @XMLTrasladoDR = @XMLTrasladoDR + (    
--        SELECT TipoFactorDR                                  AS [@TipoFactorDR],    
--                CASE TasaOCuotaDR WHEN NULL THEN NULL ELSE LTRIM(REPLACE(REPLACE(dbo.fnXMLDecimal('', TasaOCuotaDR, 6), '=', ''),'"',''))       END   AS [@TasaOCuotaDR],    
--                ImpuestoDR                                  AS [@ImpuestoDR],    
    
--                CASE ImporteDR WHEN NULL THEN NULL ELSE LTRIM(REPLACE(REPLACE(dbo.fnXMLDecimal('', ImporteDR, @DecimalesTrasladoP), '=', ''),'"','')) END  AS [@ImporteDR],    
--                LTRIM(REPLACE(REPLACE(dbo.fnXMLDecimal('', BaseDR, @DecimalesTrasladoP), '=', ''),'"',''))              AS [@BaseDR]    
--          FROM @TrasladoDR    
--          WHERE ISNULL(TasaOCuotaDR, 0) > 0 OR ISNULL(BaseDR, 0) > 0    
--          FOR XML PATH ('pago20:TrasladoDR'))    
--        ;WITH XMLNAMESPACES ('http://www.sat.gob.mx/Pagos20' AS pago20)    
--        SELECT @XMLRetencionDR = @XMLRetencionDR + (    
--        SELECT TipoFactorDR                                                                             AS [@TipoFactorDR],    
--                LTRIM(REPLACE(REPLACE(dbo.fnXMLDecimal('', TasaOCuotaDR, 6), '=', ''),'"',''))         AS [@TasaOCuotaDR],    
--                ImpuestoDR                                                                              AS [@ImpuestoDR],    
--                LTRIM(REPLACE(REPLACE(dbo.fnXMLDecimal('', ImporteDR, @DecimalesTrasladoP), '=', ''),'"','')) AS [@ImporteDR],    
--                LTRIM(REPLACE(REPLACE(dbo.fnXMLDecimal('', BaseDR, @DecimalesTrasladoP), '=', ''),'"',''))     AS [@BaseDR]    
--          FROM @RetencionDR    
--          FOR XML PATH ('pago20:RetencionDR'))    
--        IF ISNULL(@XMLTrasladoDR, '') <> '' OR ISNULL(@XMLRetencionDR, '') <> ''    
--        BEGIN    
--          IF @XMLRetencionDR <> ''    
--          BEGIN    
--            SELECT @XMLRetencionDR = REPLACE(@XMLRetencionDR, 'xmlns:pago20="http://www.sat.gob.mx/Pagos20" ', '')    
--            SELECT @XMLRetencionDR = '<pago20:RetencionesDR>' + @XMLRetencionDR + '</pago20:RetencionesDR>'    
--          END    
--          IF @XMLTrasladoDR <> ''    
--          BEGIN    
--            SELECT @XMLTrasladoDR = REPLACE(@XMLTrasladoDR, 'xmlns:pago20="http://www.sat.gob.mx/Pagos20" ', '')    
--            SELECT @XMLTrasladoDR = '<pago20:TrasladosDR>' + @XMLTrasladoDR + '</pago20:TrasladosDR>'    
--          END    
--          SELECT @XMLImpuestosDR = '<pago20:ImpuestosDR xmlns:pago20="http://www.sat.gob.mx/Pagos20">' + ISNULL(@XMLRetencionDR, '') + ISNULL(@XMLTrasladoDR, '') + '</pago20:ImpuestosDR>'    
--        END    
--        SELECT @XMLImpuestosDR2 = @XMLImpuestosDR    
--        IF @ObjetoImpDR <> '02'    
--          SELECT @XMLImpuestosDR2 = ''    
--        INSERT @PagosFacturaCobro (IDVenta, IDCobro, UUID, MontoPagado,Parcialidad, Factoraje)    
--        SELECT       @IDVenta, @IdCxc, @UUIDDR,@MontoPagado,@NumParcialidad,@Factoraje        
--        IF @MovClave IN ('CXC.D')     
--        BEGIN    
--         IF EXISTS(SELECT * FROM VersionLista WHERE Nombre = 'FlujoEspecialDocumentos' AND Valor = 'Si')    
--          SELECT @IdCxc = DID FROM   MovFlujo AS mf    
--           JOIN   Cxc AS c ON mf.dID=c.ID    
--           WHERE  OID = @IdCxc    
--            AND mf.DModulo = 'CXC'    
--            AND c.Estatus<>'CANCELADO'    
--            AND mf.Cancelado=0    
--            AND mf.OModulo='CXC'    
--         ELSE    
--          SELECT @IdCxc = DID FROM   MovFlujo AS mf    
--          JOIN   Cxc AS c ON mf.dID=c.ID    
--          WHERE  OID = @IdCxc    
--          AND mf.DModulo = 'CXC'    
--          AND c.Estatus<>'CANCELADO'    
--          AND mf.Cancelado=0    
--        END    
--        IF @MovClave IN ('CXC.DP')     
--        BEGIN    
--         SELECT @IdCxcAntes = DID FROM   MovFlujo AS mf    
--         JOIN   Cxc AS c ON mf.dID=c.ID    
--         WHERE  OID = @IdCxc    
--         AND mf.DModulo = 'CXC'    
--         AND c.Estatus<>'CANCELADO'    
--         AND mf.Cancelado=0          
--        END    
--    ;WITH XMLNAMESPACES ('http://www.sat.gob.mx/Pagos20' AS pago20)    
--    SELECT @DocRelacionado  = @DocRelacionado + (    
--          SELECT @UUIDDR                                                  AS [@IdDocumento],    
--            NULLIF (@SerieDR,'')                                              AS [@Serie],    
--            NULLIF (@FolioDR,'')                                              AS [@Folio],    
--            @MonedaDocto                                                AS [@MonedaDR],    
--      CASE @EquivalenciaDR WHEN 1 THEN '1' ELSE LTRIM(REPLACE(REPLACE(dbo.fnXMLEquivalenciaDecimal('', @EquivalenciaDR, 10), '=', ''),'"','')) END    AS [@EquivalenciaDR],    
                
--            @NumParcialidad                                                AS [@NumParcialidad],    
--            LTRIM(REPLACE(REPLACE(dbo.fnXMLDecimal('', @SaldoAnterior, @DecimalesDR), '=', ''),'"',''))                             AS [@ImpSaldoAnt],    
--            LTRIM(REPLACE(REPLACE(dbo.fnXMLDecimal('', @MontoPagado, @DecimalesDR), '=', ''),'"',''))                             AS [@ImpPagado],    
--            LTRIM(REPLACE(REPLACE(dbo.fnXMLDecimal('', @SaldoPendiente, @DecimalesDR), '=', ''),'"',''))                            AS [@ImpSaldoInsoluto],    
--                        @ObjetoImpDR                                                                          AS [@ObjetoImpDR],    
--                        @XMLImpuestosDR2    
--          FOR XML PATH ('pago20:DoctoRelacionado'))    
--    IF @Modulo='CXC'    
--    BEGIN    
--     INSERT @DocRelacionadoTimbrado (Modulo, ModuloID, UUID, Serie, Folio, ImpPagado, ImpSaldoAnt, ImpSaldoInsoluto, Moneda, TipoCambio, NumParcialidad, MetodoPago, IDCobro, ObjetoImpDR, EquivalenciaDR, IDD, TieneAjusteNegativo)    
--     VALUES (@ModuloTR, @IDTR, @UUIDDR, @SerieDR, @FolioDR, @MontoPagado, @SaldoAnterior, @SaldoPendiente, @MonedaDocto, @TipoCambioDR, @NumParcialidad, @MetodoDePagoDR, @ID, @ObjetoImpDR, ROUND(@EquivalenciaDR, 10), @IDCxc, @TieneAjusteNegativo)    
--  END    
--    ELSE    
--     INSERT @DocRelacionadoTimbrado (Modulo, ModuloID, UUID, Serie, Folio, ImpPagado, ImpSaldoAnt, ImpSaldoInsoluto, Moneda, TipoCambio, NumParcialidad, MetodoPago, IDCobro, ObjetoImpDR, EquivalenciaDR, IDD, TieneAjusteNegativo)    
--     VALUES (@ModuloTR, @IDTR, @UUIDDR, @SerieDR, @FolioDR, @MontoPagado, @SaldoAnterior, @SaldoPendiente, @MonedaDocto, @TipoCambioDR, @NumParcialidad, @MetodoDePagoDR, @IdCxcDIN, @ObjetoImpDR, ROUND(@EquivalenciaDR, 10), @IDCxc, @TieneAjusteNegativo)  
  
--    SELECT @PagadoTotal =  @PagadoTotal, @MontoPagado = ROUND (@MontoPagado , @DecimalesP)    
--    IF @MonedaDocto = @MonedaP    
--     SET @PagadoTotal = ISNULL(@PagadoTotal, 0) + @MontoPagado    
--    ELSE IF @MonedaP <> 'MXN' AND @MonedaDocto = 'MXN'    
--    BEGIN    
--     SET @PagadoTotal = ISNULL(@PagadoTotal, 0) + (ROUND(@MontoPagado / @TipoCambioP, @DecimalesP))    
--     SET @Redondeo = 1     
--    END    
--    ELSE IF @MonedaP = 'MXN' AND @MonedaDocto <> 'MXN'    
--    BEGIN    
--     SET @PagadoTotal = ISNULL(@PagadoTotal, 0) + (@MontoPagado / ROUND( @TipoCambioP/@TipoCambioDR, 10))    
--     SET @Redondeo = 1    
--    END    
--    ELSE    
--    BEGIN    
--     SET @PagadoTotal = @PagadoTotal + (ROUND(@MontoPagado / @EquivalenciaDR, @DecimalesP, 0))    
--    END    
--    INSERT @FacturasRelacionadas (UUID, Factoraje)    
--    VALUES (@UUIDDR, @FactorajeE)    
--   END    
--  FETCH NEXT FROM CDoctoRelacionado INTO @IDVenta, @EsSaldoinicial, @FactorajeE, @MontoFactor    
--  END    
--  CLOSE CDoctoRelacionado    
--  DEALLOCATE CDoctoRelacionado    
--    SELECT @XMLTrasladoP = '', @XMLRetencionP = ''    
-- SELECT @PagadoTotal =  CASE WHEN @DecimalesP = 0 THEN CONVERT(INT, @PagadoTotal) ELSE @PagadoTotal END    
--    ;WITH XMLNAMESPACES ('http://www.sat.gob.mx/Pagos20' AS pago20)    
--    SELECT @XMLTrasladoP = @XMLTrasladoP + (    
--    SELECT TipoFactorP                              AS [@TipoFactorP],    
--            CASE TasaOCuotaP WHEN NULL THEN NULL ELSE LTRIM(REPLACE(REPLACE(dbo.fnXMLDecimal('', TasaOCuotaP, 6), '=', ''),'"','')) END  AS [@TasaOCuotaP],    
--            ImpuestoP                              AS [@ImpuestoP],    
       
--            CASE SUM(ImporteP) WHEN NULL THEN NULL ELSE LTRIM(REPLACE(REPLACE(dbo.fnXMLDecimal('', SUM(ImporteP), 6), '=', ''),'"','')) END AS [@ImporteP],    
--            LTRIM(REPLACE(REPLACE(dbo.fnXMLDecimal('', SUM(BaseP), 6), '=', ''),'"',''))             AS [@BaseP]    
--      FROM @TrasladoP        WHERE ISNULL(TasaOCuotaP, 0) > 0 OR ISNULL(BaseP, 0) > 0    
--     GROUP BY TipoFactorP, TasaOCuotaP, ImpuestoP    
--      FOR XML PATH ('pago20:TrasladoP'))    
--    ;WITH XMLNAMESPACES ('http://www.sat.gob.mx/Pagos20' AS pago20)    
--    SELECT @XMLRetencionP = @XMLRetencionP + (    
--    SELECT --TipoFactorP                                                                            AS [@TipoFactorP],    
--            ImpuestoP                                                                             AS [@ImpuestoP],    
--            LTRIM(REPLACE(REPLACE(dbo.fnXMLDecimal('', SUM(ImporteP), 6), '=', ''),'"','')) AS [@ImporteP]    
--      FROM @RetencionP    
--      GROUP BY ImpuestoP    
--      FOR XML PATH ('pago20:RetencionP'))    
--    IF ISNULL(@XMLTrasladoP, '') <> '' OR ISNULL(@XMLRetencionP, '') <> ''    
--    BEGIN    
--      IF @XMLRetencionP <> ''    
--      BEGIN    
--        SELECT @XMLRetencionP = REPLACE(@XMLRetencionP, 'xmlns:pago20="http://www.sat.gob.mx/Pagos20 " ', '')    
--        SELECT @XMLRetencionP = '<pago20:RetencionesP>' + @XMLRetencionP + '</pago20:RetencionesP>'    
--      END    
--      IF @XMLTrasladoP <> ''    
--      BEGIN    
--        SELECT @XMLTrasladoP = REPLACE(@XMLTrasladoP, 'xmlns:pago20="http://www.sat.gob.mx/Pagos20 " ', '')    
--        SELECT @XMLTrasladoP = '<pago20:TrasladosP>' + @XMLTrasladoP + '</pago20:TrasladosP>'    
--      END    
--      SELECT @XMLImpuestosP = '<pago20:ImpuestosP xmlns:pago20="http://www.sat.gob.mx/Pagos20">' + ISNULL(@XMLRetencionP, '') + ISNULL(@XMLTrasladoP, '') + '</pago20:ImpuestosP>'    
--    END    
--    SELECT @XMLImpuestosP2 = @XMLImpuestosP    
--    IF ISNULL(@XMLImpuestosP, '') <> '' --AND (@Modulo <> 'DIN' OR @LlevaTotales = 0)    
--       AND EXISTS(SELECT * FROM @TrasladoTotal WHERE ObjetoImpDR = '02')    
--    BEGIN    
--      SELECT @DocRelacionado = @DocRelacionado+ @XMLImpuestosP    
--    END    
--    SELECT @DocRelacionado2 = @DocRelacionado    
--  SELECT @FormaDePagoDR= fp.ClaveSAT    
--   FROM CFDICobroParcial AS cp    
--    JOIN FormaPago AS fp ON fp.FormaPago=cp.FormaPago    
--   JOIN SATFormaPago AS sfp ON sfp.Clave = fp.ClaveSAT    
--   WHERE cp.Empresa=@Empresa    
--    AND cp.Estacion= @Estacion    
--    AND cp.ID=@ID    
--    AND cp.Modulo=@Modulo    
--    AND cp.Sucursal=@Sucursal    
--  SELECT @FechaEmision=A.FechaEmision, @FechaOriginal =A.FechaOriginal    
--    FROM CFDICobroParcial A    
--   JOIN Empresa C ON A.Empresa = C.Empresa       
--   WHERE A.ID = @ID AND A.Estacion = @Estacion    
--  IF (SELECT DATEPART (hh, ISNULL(@FechaOriginal,@FechaEmision)))= 0    
--  BEGIN    
--   SELECT @FechaOriginal = CONVERT(VARCHAR(19), DATEADD(HH, 12, @FechaOriginal),126)    
--   SELECT @FechaEmision = CONVERT(VARCHAR(19), DATEADD(HH, 12, @FechaEmision),126)    
--  END    
--  IF @MontoMovREP = 1 AND (SELECT cv.Doc FROM CFDICobroVenta AS cv WHERE cv.Estacion = @Estacion AND cv.Empresa = @Empresa AND IDCobro = @IdCxc AND cv.IDVenta = @IDVenta) = 1 AND @Modulo = 'CXC'    
--  BEGIN    
--   SELECT @MontoMov = cv.MontoFactor    
--    FROM CFDICobroVenta AS cv    
--   WHERE cv.Estacion = @Estacion    
--    AND cv.Empresa = @Empresa    
--    AND IDCobro = @IdCxc    
--    AND cv.IDVenta = @IDVenta    
--  END    
--  ELSE IF @MontoMovREP = 1 AND (SELECT cv.Doc FROM CFDICobroVenta AS cv WHERE cv.Estacion = @Estacion AND cv.Empresa = @Empresa AND IDCobro = @IdCxc AND cv.IDVenta = @IDVenta) <> 1 AND @Modulo = 'CXC'    
--  BEGIN    
--   SELECT @MontoMov = SUM (cv.MontoFactor)    
--    FROM CFDICobroVenta AS cv    
--   WHERE cv.Estacion = @Estacion    
--    AND cv.Empresa = @Empresa    
--    AND IDCobro = @IdCxc    
--  END    
--  ELSE IF @MontoMovREP = 1 AND (SELECT cv.Doc FROM CFDICobroVenta AS cv WHERE cv.Estacion = @Estacion AND cv.Empresa = @Empresa AND IDCobro = @IdCxcDIN AND cv.IDVenta = @IDVenta) = 1 AND @Modulo = 'DIN'    
--  BEGIN    
--   SELECT @MontoMov = cv.MontoFactor    
--    FROM CFDICobroVenta AS cv    
--   WHERE cv.Estacion = @Estacion    
--    AND cv.Empresa = @Empresa    
--    AND IDCobro = @IdCxcDIN    
--    AND cv.IDVenta = @IDVenta    
--    AND cv.IDAplicaCobro = @IdCxc    
--  END    
--  ELSE IF @MontoMovREP = 1 AND (SELECT cv.Doc FROM CFDICobroVenta AS cv WHERE cv.Estacion = @Estacion AND cv.Empresa = @Empresa AND IDCobro = @IdCxc AND cv.IDVenta = @IDVenta) <> 1 AND @Modulo = 'DIN'    
--  BEGIN    
--   SELECT @MontoMov = SUM (cv.MontoFactor)    
--    FROM CFDICobroVenta AS cv    
--   WHERE cv.Estacion = @Estacion    
--    AND cv.Empresa = @Empresa    
--    AND IDCobro = @IdCxc    
--  END    
-- IF @MonedaDocto <> 'MXN'AND @MonedaP <> 'MXN' AND (@MonedaDocto <> @MonedaP)    
--  SELECT @MontoTotalPagos = ISNULL(@MontoTotalPagos, 0) + (ROUND(@PagadoTotal,6)* ROUND(@TipoCambioP, 6)+.001)  --AJUSTE POR REDONDEOS    
--    ELSE    
--  SELECT @MontoTotalPagos = ISNULL(@MontoTotalPagos, 0) + (ROUND(@PagadoTotal,6)* ROUND(@TipoCambioP, 6))    
-- IF NULLIF(@AjustarMontoTotalPagos,'') IS NOT NULL    
--  SELECT @MontoTotalPagos = @MontoTotalPagos  + (@AjustarMontoTotalPagos)    
--    IF @LlevaTotales = 1    
--    BEGIN    
--      IF EXISTS(SELECT * FROM @DocRelacionadoTimbrado WHERE ObjetoImpDR = '02')    
--      BEGIN    
--        ;WITH XMLNAMESPACES ('http://www.sat.gob.mx/Pagos20' AS pago20)    
--      SELECT @XMLPago = @XMLPago + (    
--                 SELECT '_TotalRetencionesIVA_'          AS [@TotalRetencionesIVA],    
--                        '_TotalRetencionesISR_'          AS [@TotalRetencionesISR],    
--                        '_TotalRetencionesIEPS_'         AS [@TotalRetencionesIEPS],    
--                        '_TotalTrasladosBaseIVA16_'      AS [@TotalTrasladosBaseIVA16],    
--                        '_TotalTrasladosImpuestoIVA16_'  AS [@TotalTrasladosImpuestoIVA16],    
--                        '_TotalTrasladosBaseIVA8_'       AS [@TotalTrasladosBaseIVA8],    
--                        '_TotalTrasladosImpuestoIVA8_'   AS [@TotalTrasladosImpuestoIVA8],    
--                        '_TotalTrasladosBaseIVA0_'       AS [@TotalTrasladosBaseIVA0],    
--                   '_TotalTrasladosImpuestoIVA0_'   AS [@TotalTrasladosImpuestoIVA0],    
--                        '_TotalTrasladosBaseIVAExento_'  AS [@TotalTrasladosBaseIVAExento],    
--                        '_MontoTotalPagos_'              AS [@MontoTotalPagos]    
--            FOR XML PATH ('pago20:Totales'))    
--      END    
--      ELSE    
--      BEGIN    
--        ;WITH XMLNAMESPACES ('http://www.sat.gob.mx/Pagos20' AS pago20)    
--        SELECT @XMLPago = @XMLPago + (    
--                 SELECT '_MontoTotalPagos_'              AS [@MontoTotalPagos]    
--            FOR XML PATH ('pago20:Totales'))    
--      END    
--    END    
--    BEGIN    
--    ;WITH XMLNAMESPACES ('http://www.sat.gob.mx/Pagos20' AS pago20)    
--    SELECT @XMLPago = @XMLPago + (SELECT CONVERT(VARCHAR(19), ISNULL(@FechaOriginal, @FechaEmision),126)             AS [@FechaPago],    
--           ISNULL(@FormaPagoCobro,FP.ClaveSAT)                      AS [@FormaDePagoP],    
--           @MonedaP                             AS [@MonedaP],    
--           CASE WHEN @MonedaP IN ('MXN', 'XXX') THEN '1'    
--            ELSE LTRIM(REPLACE(REPLACE(dbo.fnXMLDecimal('', @TipoCambioP, 6), '=', ''),'"','')) END        AS [@TipoCambioP],    
--           LTRIM(REPLACE(REPLACE(dbo.fnXMLDecimalREP('',CASE WHEN @MontoMovREP = 1 THEN @MontoMov    
--            ELSE @PagadoTotal END, @DecimalesP), '=', ''),'"',''))    
--                                        AS [@Monto],    
--           NULLIF(A.NumOperacion, '')                        AS [@NumOperacion],    
--           CASE WHEN ISNULL(@Bancarizado, SFP.Bancarizado) = 1 THEN E.RFC ELSE NULL END            AS [@RfcEmisorCtaOrd],    
--           CASE WHEN ISNULL(@Bancarizado, SFP.Bancarizado)  = 1 AND E.EsExtranjero = 1 THEN E.Nombre ELSE NULL END     AS [@NomBancoOrdExt],    
--           CASE WHEN ISNULL(@Bancarizado, SFP.Bancarizado)  = 1 THEN    
--            (CASE WHEN @FormaDePagoDR IN ('02','03') THEN A.ClabeCuenta    
--             WHEN  @FormaDePagoDR IN ('05','06') THEN A.CuentaBancariaCte    
--             WHEN  @FormaDePagoDR IN ('04','28','29') THEN A.Tarjeta ELSE A.CuentaBancariaCte    
--            END)    
--           ELSE NULL END                            AS [@CtaOrdenante],    
--           CASE WHEN ISNULL(@Bancarizado, SFP.Bancarizado)  = 1 THEN D.RFC ELSE NULL END            AS [@RfcEmisorCtaBen],    
--           CASE WHEN ISNULL(@Bancarizado, SFP.Bancarizado)  = 1 THEN    
--            (CASE WHEN @FormaDePagoDR IN ('02','03') THEN cd.CLABE ELSE CuentaBancaria END)    
--           ELSE  NULL END                           AS [@CtaBeneficiario],    
--           NULLIF(A.TipoCadenaPago, '')                        AS [@TipoCadPago],    
--           NULLIF(A.CertificadoPago, '')                        AS [@CertPago],    
--           NULLIF(REPLACE( A.CadenaPago,'|','&#124;'), '')                   AS [@CadPago],    
--           NULLIF(A.SelloPago, '')                         AS [@SelloPago],    
--           @DocRelacionado2    
--          FROM CFDICobroParcial A    
--           JOIN Empresa C ON A.Empresa = C.Empresa    
--           LEFT JOIN CFDINominaSATInstitucionFin E ON A.ClaveBancoEmisor = E.Clave    
--           LEFT JOIN CFDINominaSATInstitucionFin D ON A.ClaveBanco = D.Clave    
--           LEFT JOIN FormaPago AS FP ON FP.FormaPago = A.FormaPago     
--           LEFT JOIN SATFormaPago AS SFP ON SFP.Clave = FP.ClaveSAT    
--           LEFT JOIN CtaDinero AS cd ON ISNULL(NULLIF(cd.NumeroCta,''),cd.CLABE)=a.CuentaBancaria        
--          WHERE A.ID = @ID AND A.Estacion = @Estacion    
--          FOR XML PATH ('pago20:Pago'))    
--    END    
--      SELECT @LlevaTotales = 0    
--  FETCH NEXT FROM cCxc INTO @IdCxc, @IdCxcDIN, @IDMov    
--  SELECT @MontoTP= LTRIM(REPLACE(REPLACE(dbo.fnXMLDecimal('', @PagadoTotal, @DecimalesP), '=', ''),'"',''))    
--  SELECT @CuentaBeneficiaria= CASE WHEN ISNULL(@Bancarizado, SFP.Bancarizado)  = 1 THEN    
--          (CASE WHEN @FormaDePagoDR IN ('02','03') THEN cd.CLABE ELSE CuentaBancaria END)    
--          ELSE  NULL END    
--          FROM CFDICobroParcial A    
--          JOIN Empresa C ON A.Empresa = C.Empresa    
--          LEFT JOIN CFDINominaSATInstitucionFin E ON A.ClaveBancoEmisor = E.Clave    
--          LEFT JOIN CFDINominaSATInstitucionFin D ON A.ClaveBanco = D.Clave    
--          LEFT JOIN FormaPago AS FP ON FP.FormaPago = A.FormaPago     
--          LEFT JOIN SATFormaPago AS SFP ON SFP.Clave = FP.ClaveSAT    
--          LEFT JOIN CtaDinero AS cd ON ISNULL(NULLIF(cd.NumeroCta,''),cd.CLABE)=a.CuentaBancaria        
--          WHERE A.ID = @ID AND A.Estacion = @Estacion    
--  SELECT @MontoTotalPago= ISNULL (@MontoTotalPago,0) + @MontoTP    
-- END    
-- CLOSE cCxc    
-- DEALLOCATE cCxc   
-- -- SELECT * INTO MALALADOS    FROM #TempImpuestoDR   SELECT * FROM MALALADOS    FROM #TempImpuestoDR  
---- SELECT * INTO AVENGER FROM @TrasladoDR   SELECT *  FROM AVENGER FROM @TrasladoDR  
-- IF EXISTS (SELECT * FROM CFDIMovRelacionados WHERE Modulo = @Modulo AND IDModulo = @ID)    
-- BEGIN    
--  SET @Relacionado = 1    
--  ;WITH XMLNAMESPACES ('http://www.sat.gob.mx/cfd/4' AS cfdi)    
--  SELECT @CFDIRelacionados = '<cfdi:CfdiRelacionados xmlns:cfdi="http://www.sat.gob.mx/cfd/4" TipoRelacion="04"> ' +    
--      (SELECT UUID                                                                          AS [@UUID]    
--                      FROM CFDIMovRelacionados    
--       WHERE Modulo = @Modulo AND IDModulo = @ID    
--       FOR XML PATH ('cfdi:CfdiRelacionado')) + '</cfdi:CfdiRelacionados>'    
-- END    
--      SELECT @TotalRetencionesISR         = SUM(CASE ImpuestoP WHEN '001' THEN ROUND(ImporteP, 6) ELSE 0 END),    
--             @TotalRetencionesIVA         = SUM(CASE ImpuestoP WHEN '002' THEN ROUND(ImporteP, 6) ELSE 0 END),    
--             @TotalRetencionesIEPS        = SUM(CASE ImpuestoP WHEN '003' THEN ROUND(ImporteP, 6) ELSE 0 END)    
--        FROM @RetencionTotal    
--      SELECT @TotalTrasladosBaseIVA16     = ROUND(SUM(CONVERT(DECIMAL(20,6),BaseP)), 2),    
--             @TotalTrasladosImpuestoIVA16 = ROUND(SUM(CONVERT(DECIMAL(20,6),ImporteP)), 2)--ROUND(CONVERT(DECIMAL(20,2), SUM(ImporteP)), 2)    
--        FROM @TrasladoTotal    
--       WHERE TasaOCuotaP = 0.16    
--      SELECT @TotalTrasladosBaseIVA8     = ROUND(SUM(CONVERT(DECIMAL(20,6),BaseP)), 2),    
--             @TotalTrasladosImpuestoIVA8 = ROUND(SUM(CONVERT(DECIMAL(20,6),ImporteP)), 2)    
--        FROM @TrasladoTotal    
--       WHERE TasaOCuotaP = 0.08    
--         AND ImpuestoP = '002'    
--      SELECT @TotalTrasladosBaseIVA0     = NULLIF(SUM(ROUND(CONVERT(DECIMAL(20,6), BaseP), 2)), 0),    
--             @TotalTrasladosImpuestoIVA0 = ROUND(CONVERT(DECIMAL(20,6), SUM(ImporteP)), 2)    
--        FROM @TrasladoTotal    
--       WHERE TasaOCuotaP = 0    
--         AND ImpuestoP = '002'    
--      SELECT @TotalTrasladosBaseIVAExento     = NULLIF(SUM(ROUND(BaseP, 2)), 0)    
--        FROM @TrasladoTotal    
--       WHERE TipoFactorP = 'Exento'    
--         AND ImpuestoP = '002'    
--         AND ISNULL(BaseP, 0) > 0    
--   SELECT @MontoTotalPagos   = NULLIF(SUM(ROUND(CONVERT(DECIMAL(20,6), @MontoTotalPagos), 2)), 0)    
        
--  SELECT @XMLPago = REPLACE(@XMLPago, '_TotalRetencionesIVA_', LTRIM(REPLACE(REPLACE(dbo.fnXMLDecimal('', @TotalRetencionesIVA, @DecimalesDR), '=', ''),'"','')))    
--  SELECT @XMLPago = REPLACE(@XMLPago, '_TotalRetencionesISR_', LTRIM(REPLACE(REPLACE(dbo.fnXMLDecimal('', @TotalRetencionesISR, @DecimalesDR), '=', ''),'"','')))    
--  SELECT @XMLPago = REPLACE(@XMLPago, '_TotalRetencionesIEPS_', LTRIM(REPLACE(REPLACE(dbo.fnXMLDecimal('', @TotalRetencionesIEPS, @DecimalesDR), '=', ''),'"','')))    
--  SELECT @XMLPago = REPLACE(@XMLPago, '_TotalTrasladosBaseIVA16_', LTRIM(REPLACE(REPLACE(dbo.fnXMLDecimal('', @TotalTrasladosBaseIVA16, @DecimalesDR), '=', ''),'"','')))    
--  SELECT @XMLPago = REPLACE(@XMLPago, '_TotalTrasladosImpuestoIVA16_', LTRIM(REPLACE(REPLACE(dbo.fnXMLDecimal('', @TotalTrasladosImpuestoIVA16, @DecimalesDR), '=', ''),'"','')))    
--  SELECT @XMLPago = REPLACE(@XMLPago, '_TotalTrasladosBaseIVA8_', LTRIM(REPLACE(REPLACE(dbo.fnXMLDecimal('', @TotalTrasladosBaseIVA8, @DecimalesDR), '=', ''),'"','')))    
--  SELECT @XMLPago = REPLACE(@XMLPago, '_TotalTrasladosImpuestoIVA8_', LTRIM(REPLACE(REPLACE(dbo.fnXMLDecimal('', @TotalTrasladosImpuestoIVA8, @DecimalesDR), '=', ''),'"','')))    
--  SELECT @XMLPago = REPLACE(@XMLPago, '_TotalTrasladosBaseIVA0_', LTRIM(REPLACE(REPLACE(dbo.fnXMLDecimal('', @TotalTrasladosBaseIVA0, @DecimalesDR), '=', ''),'"','')))    
--  SELECT @XMLPago = REPLACE(@XMLPago, '_TotalTrasladosImpuestoIVA0_', LTRIM(REPLACE(REPLACE(dbo.fnXMLDecimal('', @TotalTrasladosImpuestoIVA0, @DecimalesDR), '=', ''),'"','')))    
--  SELECT @XMLPago = REPLACE(@XMLPago, '_TotalTrasladosBaseIVAExento_', LTRIM(REPLACE(REPLACE(dbo.fnXMLDecimal('', @TotalTrasladosBaseIVAExento, @DecimalesDR), '=', ''),'"','')))    
--  SELECT @XMLPago = REPLACE(@XMLPago, '_MontoTotalPagos_', LTRIM(REPLACE(REPLACE(dbo.fnXMLDecimal('', @MontoTotalPagos, @DecimalesDR), '=', ''),'"','')))    
--  SELECT @XMLPago = REPLACE(@XMLPago, 'TotalRetencionesIVA=""', '')    
--  SELECT @XMLPago = REPLACE(@XMLPago, 'TotalRetencionesISR=""', '')    
--  SELECT @XMLPago = REPLACE(@XMLPago, 'TotalRetencionesIEPS=""', '')    
--  SELECT @XMLPago = REPLACE(@XMLPago, 'TotalTrasladosBaseIVA16=""', '')    
--  SELECT @XMLPago = REPLACE(@XMLPago, 'TotalTrasladosImpuestoIVA16=""', '')    
--  SELECT @XMLPago = REPLACE(@XMLPago, 'TotalTrasladosBaseIVA8=""', '')    
--  SELECT @XMLPago = REPLACE(@XMLPago, 'TotalTrasladosImpuestoIVA8=""', '')    
--  SELECT @XMLPago = REPLACE(@XMLPago, 'TotalTrasladosBaseIVA0=""', '')    
--  SELECT @XMLPago = REPLACE(@XMLPago, 'TotalTrasladosImpuestoIVA0=""', '')    
--  SELECT @XMLPago = REPLACE(@XMLPago, 'TotalTrasladosBaseIVAExento=""', '')    
--  SELECT @XMLPago = REPLACE(@XMLPago, 'TotalRetencionesIVA="0.00"', '')    
--  SELECT @XMLPago = REPLACE(@XMLPago, 'TotalRetencionesISR="0.00"', '')    
--  SELECT @XMLPago = REPLACE(@XMLPago, 'TotalRetencionesIEPS="0.00"', '')    
--  SELECT @XMLPago = REPLACE(@XMLPago, 'TotalTrasladosBaseIVA16="0.00"', '')    
--  SELECT @XMLPago = REPLACE(@XMLPago, 'TotalTrasladosImpuestoIVA16="0.00"', '')    
--  SELECT @XMLPago = REPLACE(@XMLPago, 'TotalTrasladosBaseIVA8="0.00"', '')    
--  SELECT @XMLPago = REPLACE(@XMLPago, 'TotalTrasladosImpuestoIVA8="0.00"', '')    
--  SELECT @XMLPago = REPLACE(@XMLPago, 'TotalTrasladosBaseIVA0="0.00"', '')    
--  IF @TotalTrasladosBaseIVA0 = 0    
-- SELECT @XMLPago = REPLACE(@XMLPago, 'TotalTrasladosImpuestoIVA0="0.00"', '')    
--  SELECT @XMLPago = REPLACE(@XMLPago, 'TotalTrasladosBaseIVAExento="0.00"', '')    
-- ;WITH XMLNAMESPACES ('http://www.sat.gob.mx/Pagos20' AS pago20)    
-- SELECT @XMLPagos = (SELECT @VersionPago       AS [@Version],    
--        CAST(@XMLPago as xml)    
--      FOR XML PATH ('pago20:Pagos'))    
-- ;WITH XMLNAMESPACES ('http://www.sat.gob.mx/cfd/4' AS cfdi)    
-- SELECT @XMLEmisor = (SELECT @RFCEmisor             AS [@Rfc],    
--        @NombreEmisor            AS [@Nombre],    
--        @RegimenFiscal            AS [@RegimenFiscal]    
--      FOR XML PATH ('cfdi:Emisor'))    
-- ;WITH XMLNAMESPACES ('http://www.sat.gob.mx/cfd/4'  AS cfdi)    
-- SELECT @XMLReceptor = (SELECT @RFCReceptor            AS [@Rfc],    
--         @NombreReceptor      AS [@Nombre],    
--         @DomicilioFiscalReceptor   AS [@DomicilioFiscalReceptor],    
--         @ResidenciaFiscal           AS [@ResidenciaFiscal],    
--         @NumRegIdTrib            AS [@NumRegIdTrib],    
--         @RegimenFiscalReceptor    AS [@RegimenFiscalReceptor],    
--         'CP01'              AS [@UsoCFDI]    
--       FOR XML PATH ('cfdi:Receptor'))    
--  SELECT @XMLConceptos = '<cfdi:Conceptos xmlns:cfdi="http://www.sat.gob.mx/cfd/4"> <cfdi:Concepto ClaveProdServ="84111506" Cantidad="1" ClaveUnidad="ACT" Descripcion="Pago" ValorUnitario="0" Importe="0" ObjetoImp="01">'    
--  IF @AgenteACuentaTerceros <> '' --AND @RfcACuentaTerceros <> '' AND @NombreACuentaTerceros <> '' AND @RegimenFiscalACuentaTerceros <> '' AND  @DomicilioFiscalACuentaTerceros <> ''    
--      SELECT @XMLConceptos = @XMLConceptos + '<cfdi:ACuentaTerceros RfcACuentaTerceros="' + RTRIM(@RfcACuentaTerceros) + '" NombreACuentaTerceros="' + RTRIM(@NombreACuentaTerceros) + '" RegimenFiscalACuentaTerceros="' + RTRIM(@RegimenFiscalACuentaTerceros) + '" DomicilioFiscalACuentaTerceros="' + RTRIM(@DomicilioFiscalACuentaTerceros) + '"/>'    
--  SELECT @XMLConceptos = @XMLConceptos + '</cfdi:Concepto></cfdi:Conceptos>'    
-- SET @XMLComplemento = '<cfdi:Complemento xmlns:cfdi="http://www.sat.gob.mx/cfd/4">' + @XMLPagos + '</cfdi:Complemento>'      
-- ;WITH XMLNAMESPACES ('http://www.sat.gob.mx/cfd/4' AS cfdi,    
--        'http://www.sat.gob.mx/Pagos20' AS pago20)    
-- SELECT @XMLComprobante = (SELECT @VersionCFDI                              AS [@Version],    
--          cp.Folio                              AS [@Folio],    
--          cp.Serie                              AS [@Serie],          
--          CONVERT(VARCHAR(19), dbo.fnFechaConDiferenciaHoraria( GETDATE(), ISNULL(@Verano, 0), ISNULL(@Invierno, 0)), 126)    AS [@Fecha],    
--          '0'                                AS [@SubTotal],    
--          @Moneda                               AS [@Moneda],    
--          '0'                                AS [@Total],    
--          @FormaDePago                             AS [@formaDePago],    
--          @MetodoDePago                             AS [@metodoDePago],    
--          @TipoDeComprobante                            AS [@TipoDeComprobante],    
--          @Exportacion                             AS [@Exportacion],    
--          cp.LugarExpedicion                            AS [@LugarExpedicion],    
--          NULLIF(cp.ConfirmacionPAC, '')                         AS [@Confirmacion],    
--          '_NOCERTIFICADO_'                             AS [@NoCertificado],    
--          '_CERTIFICADO_'                             AS [@Certificado],    
--          '_SELLO_'                              AS [@Sello],    
--          CAST(@CFDIRelacionados AS XML),    
--          CAST(@XMLEmisor AS XML),    
--          CAST(@XMLReceptor AS XML),     
--          CAST(@XMLConceptos AS XML),    
--          CAST(@XMLImpuestosFacturas AS XML),    
--          CAST(@XMLComplemento AS XML)    
--                           FROM  CFDICobroParcial AS cp    
--                           WHERE ID = @ID AND Estacion = @Estacion    
--        FOR XML PATH ('cfdi:Comprobante'))    
-- SET @AlmacenarRutaNueva = @AlmacenarRuta    
-- SET @NomArchivoNuevo = @NomArchivo    
-- SELECT @AlmacenarRutaNueva = REPLACE(@AlmacenarRutaNueva,'<Cliente>', @Cliente)    
-- SELECT @AlmacenarRutaNueva = REPLACE(@AlmacenarRutaNueva,'<Ejercicio>', @Ejercicio)    
-- SELECT @AlmacenarRutaNueva = REPLACE(@AlmacenarRutaNueva,'<Periodo>', @Periodo)     
-- SELECT @AlmacenarRutaNueva = REPLACE(@AlmacenarRutaNueva,'<Empresa>', @Empresa)    
-- SELECT @AlmacenarRutaNueva = REPLACE(@AlmacenarRutaNueva,'<Sucursal>', @Sucursal)    
-- SELECT @NomArchivoNuevo = REPLACE(@NomArchivoNuevo,'<Cliente>', @Cliente)    
-- SELECT @NomArchivoNuevo = REPLACE(@NomArchivoNuevo,'<Periodo>', @Periodo)    
-- SELECT @NomArchivoNuevo = REPLACE(@NomArchivoNuevo,'<Ejercicio>', @Ejercicio)    
-- SELECT @NomArchivoNuevo = REPLACE(@NomArchivoNuevo,'<Empresa>', @Empresa)    
-- SELECT @NomArchivoNuevo = REPLACE(@NomArchivoNuevo,'<Sucursal>', @Sucursal)    
-- SELECT @NomArchivoNuevo = REPLACE(@NomArchivoNuevo,'<Movimiento>', @Movimiento)    
-- SELECT @NomArchivoNuevo = REPLACE(@NomArchivoNuevo,'<Serie>', @Serie)    
-- SELECT @NomArchivoNuevo = REPLACE(@NomArchivoNuevo,'<Folio>', @Folio)    
-- EXEC spNombrePagoSustitucion @ID, @Modulo, 0 , @NumeroPago OUTPUT    
-- SELECT @NomArchivoNuevo = @NomArchivoNuevo + @NumeroPago    
-- SELECT @XMLComprobante = REPLACE(@XMLComprobante, ' xmlns:pago20="http://www.sat.gob.mx/Pagos20"', '')    
-- SELECT @XMLComprobante = REPLACE(@XMLComprobante, ' xmlns:cfdi="http://www.sat.gob.mx/cfd/4"', '')    
-- SELECT @XMLComprobante = REPLACE(@XMLComprobante, '<cfdi:Comprobante', '<cfdi:Comprobante xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:pago20="http://www.sat.gob.mx/Pagos20" xmlns:cfdi="http://www.sat.gob.mx/cfd/4" ' + @SchemaLocation)    
-- SELECT @XMLComprobante = '<?xml version="1.0" encoding="UTF-8"?>' + @XMLComprobante    
-- BEGIN TRY     
--  EXEC spCrearRuta @AlmacenarRutaNueva, @Ok OUTPUT, @OkRef OUTPUT    
--  IF @Ok IS NULL    
--  BEGIN    
--   SELECT @AlmacenarRutaNueva = @AlmacenarRutaNueva + '\' + @NomArchivoNuevo + '.tmp'    
--   EXEC spRegenerarArchivo @AlmacenarRutaNueva, @XMLComprobante, @Ok OUTPUT, @OkRef OUTPUT    
--   IF @Ok IS NULL    
--   BEGIN    
--    SET @SQL = CHAR(34) + CHAR(34) + RTRIM(LTRIM(@RutaAnsiUTF)) + CHAR(34) + ' A2U ' + CHAR(34) + LTRIM(RTRIM(@AlmacenarRutaNueva)) + CHAR(34) + CHAR(34)    
--    EXEC xp_cmdshell @SQL, no_output    
--    EXEC spCFDITimbrarPago @Modulo, @ID, @Empresa, @AlmacenarRutaNueva, @XMLComprobante, @CFDITimbrado OUTPUT, @CadenaOriginal OUTPUT, @Ok OUTPUT, @OkRef OUTPUT, @TipoCFD    
--    IF @Ok IS NULL    
--    BEGIN    
--     SELECT @Cont = @Cont + 1, @AlmacenarRutaNueva = REPLACE(@AlmacenarRutaNueva, '.tmp','')    
--     EXEC spCFDIPagoObtenerTimbre @CFDITimbrado, @SelloSAT OUTPUT, @SelloCFD OUTPUT, @FechaTimbrado OUTPUT, @UUID OUTPUT, @TFDVersion OUTPUT, @noCertificadoSAT OUTPUT, @TFDCadenaOriginal OUTPUT, @Ok OUTPUT, @OkRef OUTPUT    
--     SET @newID =  NEWID()    
--     INSERT INTO AnexoMov(Rama, ID, Nombre, Direccion, Icono, Tipo, Orden, Sucursal, FechaEmision, Alta, UltimoCambio, CFD,FS)    
--     VALUES(@Modulo, @ID, @NomArchivoNuevo + '.xml', @AlmacenarRutaNueva + '.xml', 17, 'Archivo', NULL, @Sucursal, @FechaTimbrado, @FechaTimbrado, @FechaTimbrado, 1,@newID)    
--     IF @CadenaOriginal IS NULL OR @CadenaOriginal = ''    
--     BEGIN    
--      SELECT @RutaFirmaSAT= RutaFirmaSAT    
--       FROM EmpresaCFD    
--        WHERE Empresa = @Empresa    
--      DELETE @Datos    
--      SET @Shell = CHAR(34) + CHAR(34) + @RutaFirmaSAT + CHAR(34) + ' PIPESTRING ' + CHAR(34) +@AlmacenarRutaNueva + '.xml' + CHAR(34) + CHAR(34)    
--      INSERT @Datos EXEC @r = xp_cmdshell @Shell    
--      SELECT @CadenaOriginal= COALESCE(@CadenaOriginal + ISNULL(Datos, ''), '') FROM @Datos ORDER BY ID    
--     END    
--     IF (SELECT v.UsarAnexosSQL FROM Version AS v)=1    
--     BEGIN    
--      SELECT @RutaFS=Direccion FROM AnexoMov AS am WHERE ID = @ID AND Rama = @Modulo      
--      EXEC spGuardarAnexoFS @TablaD='AnexoMovFS',@ID = @newID , @Direccion = @RutaFS, @Formato = null, @Tamano = null, @VB = null     
--     END    
--     INSERT CFDICobroParcialTimbrado(Modulo, Movimiento, IDModulo, FechaEmision, Ejercicio, Periodo, Empresa, MovID, Serie, Folio, Cliente, RFC, Importe, TipoCambio, noCertificado,    
--             Sello, CadenaOriginal, Documento, UUID, GeneraPDF, Timbrado, FechaTimbrado, SelloSAT, TFDVersion, noCertificadoSAT, TFDCadenaOriginal,    
--          ClaveBancoCte, CuentaBancariaCte, ClabeCuentaCte, TarjetaCte, MontoTP, FormaPago, CtaBeneficiaria,  AjusteMontoTotal)    
--     SELECT @Modulo, @Movimiento, @ID, A.FechaEmision, @Ejercicio, @Periodo, @Empresa, A.MovID, A.Serie, A.Folio, @Cliente, @RFCReceptor, @MontoTotalPago, A.TipoCambio, @noCertificado,    
--          @SelloCFD, @CadenaOriginal, @CFDITimbrado, @UUID, 1, 1, @FechaTimbrado, @SelloSAT, @TFDVersion, @noCertificadoSAT, @TFDCadenaOriginal,    
--          A.ClaveBancoEmisor, A.CuentaBancariaCte, A.ClabeCuenta, A.Tarjeta, @MontoTP, A.FormaPago, @CuentaBeneficiaria, @AjustarMontoTotalPagos         
--      FROM CFDICobroParcial A    
--      WHERE A.ID = @ID AND A.Estacion = @Estacion    
--     IF EXISTS (SELECT * FROM @DatosFactoraje)    
--     BEGIN    
--      INSERT CFDICobroFactoraje (Modulo,ModuloID,Mov,MovID,ModuloFactoraje,ModuloFactorajeID,MovFactoraje,MovFactorajeID,Empresa,Cliente,MovFactorajeD,MovFactorajeIDD)    
--      SELECT        Modulo,ModuloID,Mov,MovID,ModuloFactoraje,ModuloFactorajeID,MovFactoraje,MovFactorajeID,Empresa,Cliente,MovFactorajeD,MovFactorajeIDD    
--       FROM @DatosFactoraje     
--      DELETE FROM CFDICobroFactorajePaso WHERE Estacion=@Estacion AND ModuloID=@ID    
--     END    
--     IF EXISTS (SELECT * FROM CFD WHERE Modulo = @Modulo AND ModuloID = @ID AND Cancelado = 0)    
--      DELETE FROM CFD WHERE Modulo = @Modulo AND ModuloID = @ID AND Cancelado = 0    
--     INSERT CFD (Modulo, ModuloID, Fecha, Ejercicio, Periodo, Empresa, MovID, Serie, Folio, RFC, Importe, noCertificado, Sello,    
--       CadenaOriginal, Documento, GenerarPDF, Timbrado, UUID, FechaTimbrado, TipoCambio, SelloSAT, TFDVersion, noCertificadoSAT, TFDCadenaOriginal, Retencion1, Retencion2, Impuesto1, Impuesto2)    
--     SELECT @Modulo, @ID, A.FechaEmision, @Ejercicio, @Periodo, @Empresa, A.MovID, A.Serie, dbo.fnSoloNumero(A.Folio) , @RFCReceptor, (A.Monto - ISNULL(@TotalTrasladosImpuestoIVA16, 0) - ISNULL(@TotalTrasladosBaseIVA8, 0))  , @noCertificado, @SelloCFD,   
 
--       @CadenaOriginal, @CFDITimbrado, 1, 1, @UUID, @FechaTimbrado, A.TipoCambio, @SelloSAT, @TFDVersion, @noCertificadoSAT, @TFDCadenaOriginal, @TotalRetencionesISR ,@TotalRetencionesIVA,   (ISNULL(@TotalTrasladosImpuestoIVA16, 0) + ISNULL(@TotalTrasladosBaseIVA8, 0)), @TotalRetencionesIEPS    
--      FROM CFDICobroParcial A    
--      WHERE A.ID = @ID AND A.Estacion = @Estacion    
--     INSERT CFDTipoComprobante (UUID,     Cancelado, EmitidasRecibidas, Formapago,  TipoDeComprobante,  MetodoPago,  Moneda,  Ejercicio,       Periodo,          Empresa,  Importe,     TipoCambio,  Mov,  MovID,  Sucursal,  FechaEmision,  FechaCancelacion, Total)    
--                   SELECT      @UUID,  0,         'Emitidas',     @FormaPagoCobro,  @TipoDeComprobante, NULL , @Moneda, YEAR(@FechaTimbrado), MONTH(@FechaTimbrado), @Empresa, A.Monto,  @TipoCambioP, A.Mov, A.MovID, A.Sucursal, A.FechaEmision, NULL, @MontoTotalPago    
--      FROM CFDICobroParcial A    
--      WHERE A.ID = @ID AND A.Estacion = @Estacion    
--     INSERT CFDIDocRelacionadoTimbrado (Modulo, IDModulo, UUID, Serie, Folio, ImpPagado, ImpSaldoAnt, ImpSaldoInsoluto, Moneda, TipoCambio, NumParcialidad, MetodoPago, IDCobro, ObjetoImpDR, EquivalenciaDR, IDD, TieneAjusteNegativo)    
--     SELECT @Modulo, @ID, UUID, Serie, Folio, ImpPagado, ImpSaldoAnt, ImpSaldoInsoluto, Moneda, TipoCambio, NumParcialidad, MetodoPago, IDCobro, ObjetoImpDR, EquivalenciaDR, IDD, TieneAjusteNegativo    
--      FROM @DocRelacionadoTimbrado    
--          INSERT CFDIDocRelacionadoImpuestos(    
--                  Modulo, IDModulo, UUID, Tipo,          TipoFactor, TasaOCuota, Impuesto, Importe, Base, NumParcialidad, IDCobro)    
--          SELECT @Modulo, @ID,      UUID, 'RetencionDR', TipoFactorP, TasaOCuotaP, ImpuestoP, CASE WHEN @MonedaP = @MonedaDocto THEN ImporteP ELSE ImportePMN END, CASE WHEN @MonedaP = @MonedaDocto THEN BaseP ELSE BasePMN END, NumParcialidad, IDCobro    
--            FROM @RetencionTotal    
--           ORDER BY UUID, TipoFactorP, TasaOCuotaP    
--          INSERT CFDIDocRelacionadoImpuestos(    
--                  Modulo, IDModulo, UUID, Tipo,          TipoFactor, TasaOCuota, Impuesto, Importe, Base, NumParcialidad, IDCobro)    
--          SELECT @Modulo, @ID,      UUID, 'TrasladoDR', TipoFactorP, TasaOCuotaP, ImpuestoP, CASE WHEN @MonedaP = @MonedaDocto THEN ImporteP ELSE ImportePMN END, CASE WHEN @MonedaP = @MonedaDocto THEN BaseP ELSE BasePMN END, NumParcialidad, IDCobro    
--            FROM @TrasladoTotal    
--           ORDER BY UUID, TipoFactorP, TasaOCuotaP    
--     IF @Modulo='CXC'    
--     BEGIN    
--      UPDATE CXC SET CFDTimbrado = 1 WHERE ID=@ID    
--     END    
--     INSERT CFDICobroParcialPDF (Estacion, ID, Modulo, IDModulo, Ruta)    
--     SELECT @Estacion, @Cont, @Modulo, @ID, @AlmacenarRutaNueva    
--     SET @newID =  NEWID()    
--     INSERT INTO AnexoMov(Rama, ID, Nombre, Direccion, Icono, Tipo, Orden, Sucursal, FechaEmision, Alta, UltimoCambio, CFD,FS)    
--     VALUES(@Modulo, @ID, @NomArchivoNuevo + '.pdf', @AlmacenarRutaNueva + '.pdf', 745, 'Archivo', NULL, @Sucursal, @FechaTimbrado, @FechaTimbrado, @FechaTimbrado, 1, @newID)    
--     EXEC spInformacionAdicional @ID, @Modulo, @Empresa, @Estacion    
--     IF NOT EXISTS (SELECT * FROM @LimpiarClientes WHERE Cliente = @Cliente)    
--      INSERT @LimpiarClientes (Cliente)    
--      VALUES (@Cliente)    
--     IF @Relacionado = 1    
--     BEGIN    
--      UPDATE CFDICobroParcialTimbrado    
--        SET Relacionado = 1    
--       FROM CFDICobroParcialTimbrado AS cpt    
--       INNER JOIN CFDIMovRelacionados AS mr ON cpt.Modulo = mr.OrigenModulo AND cpt.IDModulo = mr.OrigenIDModulo    
--       WHERE mr.Modulo = @Modulo AND mr.IDModulo = @ID    
--      DELETE FROM CFDIMovRelacionados WHERE IDModulo = @ID AND Modulo = @Modulo    
--     END     
--    END ELSE    
--     IF EXISTS (SELECT * FROM @LimpiarClientes WHERE Cliente = @Cliente)    
--      DELETE FROM @LimpiarClientes    
--      WHERE Cliente = @Cliente    
--   END    
--  END      
--   SELECT @OkRef    
--  END TRY    
--    BEGIN CATCH    
--   INSERT CFDICobroParcialLog(Estacion, IDCobro, Mov, MovID, Error )    
--   SELECT @Estacion, ID, Mov, MovID, ISNULL(ERROR_MESSAGE(), '')    
--   FROM CFDICobroParcial    
--   WHERE ID = @ID    
--   IF EXISTS (SELECT * FROM @LimpiarClientes WHERE Cliente = @Cliente)    
--    DELETE FROM @LimpiarClientes    
--    WHERE Cliente = @Cliente    
--  END CATCH    
--  FETCH NEXT FROM CPagos INTO @ID        
-- END    
-- CLOSE CPagos    
-- DEALLOCATE CPagos    
-- IF EXISTS (SELECT * FROM @LimpiarClientes)    
--  UPDATE Cte    
--  SET Cte.CtaBanco = NULL, Cte.ClaveBanco = NULL, cte.ClabeCuenta=NULL ,cte.tarjeta=NULL    
--  FROM Cte    
--   INNER JOIN @LimpiarClientes AS lp ON lp.Cliente = Cte.Cliente    
--END
--GO
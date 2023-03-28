view: personalizada {
  dimension: clase {
    type: string
    sql: CASE
          WHEN ${catalogo_cuentas.comercio.idComercio} IS NOT NULL AND ${movimientos.TipReg} = 'C' THEN ${catalogo_categoria_comercio.categoria}
          ELSE ${movimientos.Cat}
        END ;;
  }
}

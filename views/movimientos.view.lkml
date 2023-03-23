view: movimientos {
  sql_table_name:
    (
      SELECT --TOP(1000)
      id, NroRuc Cuenta, CONVERT(DATE,Fclear) Fecha,SUM(ImpTotal) Importe,CodPtoCuota Producto,DenMov Categoria,COUNT(1) Operaciones,SUM(case when CodMont!='484' then (TasaIntercambio*(importe_pesos/ImpTotal)) else TasaIntercambio end) Intercambio
      ,TipReg as TipReg
      FROM broxelco_rdg.ind_movimientos (NoLock)
      WHERE Fclear > EOMONTH(DATEADD(MONTH, -6, GETDATE()))
      GROUP BY id,NroRuc,CONVERT(DATE,Fclear),CodPtoCuota,DenMov,TipReg
      UNION ALL
      SELECT --TOP(1000)
      id, NumCuenta Cuenta, CONVERT(DATE,Fecha) Fecha,SUM(ImpTotalDEC) Importe,Producto,DenMov Categoria,COUNT(1) Operaciones,SUM(ExchangeRateDEC) Intercambio
      ,TipoReg AS TipReg
      FROM broxelpaymentsws.PrePayStudioMovements_v (NoLock)
      WHERE Fecha > EOMONTH(DATEADD(MONTH, -6, GETDATE()))
      GROUP BY id,NumCuenta,CONVERT(DATE,Fecha),Producto,DenMov,TipoReg
    ) ;;
  drill_fields: [Producto]

  dimension: id {
    primary_key: yes
    type: string
    sql: ${TABLE}.id ;;
}

dimension: Cuenta {
  type: string
  sql: ${TABLE}.Cuenta ;;
}

dimension_group: Fecha {
  type: time
  timeframes: [
    raw,
    time,
    date,
    week,
    month,
    quarter,
    year
  ]
  sql: ${TABLE}.Fecha ;;
}
dimension: Importe {
  type: number
  sql: ${TABLE}.Importe ;;
}
dimension: Producto {
  type: string
  sql: ${TABLE}.Producto ;;
}
dimension: Categoria {
  type: string
  sql: COALESCE(${TABLE}.Categoria, 'Otros') ;;
}
dimension: Operaciones {
  type: number
  sql: ${TABLE}.Operaciones ;;
}
dimension: Intercambio {
  type: number
  sql: ${TABLE}.Intercambio ;;
}
  dimension: TipReg {
    type: string
    sql: ${TABLE}.TipReg ;;
  }
  dimension: tipo_movimiento {
    type: string
    sql: CASE
         WHEN ${TABLE}.TipoReg = 'C' THEN 'POS'
         ELSE CASE ${TABLE}.TipoReg
                WHEN 'D' THEN 'Devoluciones'
                WHEN 'R' THEN 'ATM'
                WHEN 'Z' THEN 'Comisiones'
                WHEN 'S' THEN 'Comisiones'
                WHEN 'X' THEN 'Devoluciones'
                WHEN 'Y' THEN 'Otros'
                WHEN 'I' THEN 'Comisiones'
                WHEN 'K' THEN 'Devoluciones'
                WHEN 'L' THEN 'Comisiones'
                WHEN 'J' THEN 'Devoluciones'
                WHEN 'M' THEN 'Comisiones'
                WHEN 'N' THEN 'Comisiones'
                WHEN 'H' THEN 'Otros'
                WHEN 'T' THEN 'Otros'
                WHEN 'O' THEN 'Otros'
                WHEN 'A' THEN 'Otros'
                WHEN 'B' THEN 'Comisiones'
                WHEN 'G' THEN 'Otros'
                WHEN 'F' THEN 'Devoluciones'
                WHEN 'Q' THEN 'Comisiones'
                WHEN 'P' THEN 'No Aplica'
                WHEN 'U' THEN 'Devoluciones'
                WHEN 'V' THEN 'No Aplica'
                WHEN 'W' THEN 'No Aplica'
              END
       END ;;
  }

}

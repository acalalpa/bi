view: personalizada {
    sql_table_name: maquila_default_datagroup.movimientos ;;
    dimension: clase {
      type: string
      sql: CASE
              WHEN ${comercio.id_Comercio} IS NOT NULL AND ${TABLE.TipReg} = 'C' THEN ${catalogo_categoria_comercio.categoria}
              ELSE ${TABLE}.Cat}
            END ;;
    }
    dimension: TipReg {
      type: string
      sql: ${TABLE}.TipReg ;;
    }
    dimension: Cat {
      type: string
      sql: ${TABLE}.Cat ;;
    }
}

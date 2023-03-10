connection: "azuresqlbi"

# include all the views
include: "/views/**/*.view"

datagroup: maquila_default_datagroup {
  # sql_trigger: SELECT MAX(id) FROM etl_log;;
  max_cache_age: "1 hour"
}

persist_with: maquila_default_datagroup

explore: catalogo_cuentas  {
  join: movimientos {
    type: left_outer
    sql_on: ${catalogo_cuentas.cuenta} = ${movimientos.Cuenta} ;;
    relationship: one_to_many
  }
 join: comercio {
   type: left_outer
  sql_on: ${movimientos.Categoria} = ${comercio.comercio} ;;
  relationship: many_to_one
 }
}
